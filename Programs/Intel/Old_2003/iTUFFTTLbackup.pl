#!/usr/local/bin/perl -w ########################################################
#                                                                               #
#        Foo Lye Cheung                             NCO PDQRE Automation        #
#        inet 253 6452                              Penang                      #
#                                                                               #
#        DESCRIPTION                                                            #
#        Runs through all production iTUFF's and detects (x,y)=(0,0). If        #
#        found, regenerate iTUFF from backup waferdata file.                    #
#                                                                               #
#        NOTES                                                                  # 
#        Runs as a cronjob every 15 minutes on t3admin6.png.intel.com           #
#                                                                               #
#        RELEASES                                                               #
#        01/24/2005  rev1.0 - Main code release                                 #
#                                                                               #
#################################################################################
use strict;
use File::Find;

# Global variable declared here
my $iTUFFDir = '/lopte/data/summary/t3/';
my %TmpWaferDataSize = ();
my @LotDirs = ();
my $SearchYY = ();

# Main program start here
&Main();

sub Main
{
	&CheckSearch();
	finddepth(\&GetiTUFFDir, $iTUFFDir);
	&CheckiTUFF();
}

# Added to increase the processing CPU speed to search for lot for wafer sort
sub CheckSearch
{
	my $Month = (localtime(time))[4] + 1;
	my $YYLot = $1 if ((localtime(time))[5] =~ /(\d)$/);

	# Define searching methodology for the lot to avoid transition from 1 year to another and increase the CPU speed
	if ($Month <= 3)
	{
		my $PrevYYLot = 0;
		if ($YYLot == 0)
		{
			$PrevYYLot = 9;
		}
		else
		{
			$PrevYYLot = $YYLot - 1;

		}
		$SearchYY = $PrevYYLot . "45|" . $PrevYYLot . "5|" . $YYLot;
	}
	elsif ($Month <= 6)
	{
		$SearchYY = $YYLot . "(0|1|2)";
	}
	elsif ($Month <= 9)
	{
		$SearchYY = $YYLot . "(2|3|4)";
	}
	elsif ($Month <= 12)
	{
		$SearchYY = $YYLot . "(3|4|5)";
	}
	else
	{
		# Do nothing over here
	}
}

# Check iTUFF for the (x,y) = (0,0), if found regenerate the iTUFF from backup
sub CheckiTUFF
{
	foreach my $LotDir (@LotDirs)
	{
		# Expect the 0,0 will be below 5 wafers continuous iTUFF testing
		my @iTUFFs = qx(ls -rt ${LotDir}/W* | tail -5);

		foreach my $iTUFF (@iTUFFs)
		{
			chomp ($iTUFF);

			# Filter the .Z files
			next unless(($iTUFF !~ /\.Z$/) || ($iTUFF eq ""));

			# Grep the files that have bin 0
			my $MatchCount = qx(grep -c 3_curibin_0 $iTUFF);
			next unless ($MatchCount > 0);

			print "iTUFF detected: $iTUFF\n";
			&ReGeniTUFF($iTUFF);
		}
	}
}

# Regenerate the iTUFF from backup waferdata file
sub ReGeniTUFF
{
	my $iTUFF = shift;
	my $BkupWaferDataDir = "/lopte/data/tmp/DEBUG/";
	my ($Lot, $Tester, $iTUFFFooter, $iBinCtr, $TotalUnit, $iTUFFFooter) = ();
	my (%Binn, %xy) = ();
	my $FirstLineFlag = 0;

	my $iTUFFName = $1 if ($iTUFF =~ /\/(W\w+)$/o);
	my $NewiTUFF = $iTUFF . ".txt";
	unlink $NewiTUFF || die "Cant delete $NewiTUFF : $!\n";

	open (NEW, ">$NewiTUFF") || die "Cannt open $NewiTUFF : $!\n";
	open (ITUFF, $iTUFF) || die "Cant open $iTUFF : $!\n";
	while(<ITUFF>)
	{
		chomp;
		print NEW "$_\n";
		$Lot = $1 if (/6_lotid_(\w+)/o);
		$Tester = $1 if (/4_sysid_(\w+)/o);
		last if (/3_lsep/o);

	}
	close ITUFF;

	my $BkupWaferDataFile = $BkupWaferDataDir . $Lot . "." .$Tester . "." . $iTUFFName . ".waferdata";
	print "Backup waferdata file: $BkupWaferDataFile\n";

	open (FILE, $BkupWaferDataFile) || die "Cant open $BkupWaferDataFile : $!\n";
	while (<FILE>)
	{
		chomp;
		s/ //g;
		my ($oifno, $Wafer, $devno, $x, $y, $curibin, $site, $testtime) = split(/\,/,$_);

		# Ensure the dummy start signal is removed at the begining of the waferdata file
		if (!$FirstLineFlag)
		{
			my $dummycount = qx(grep -c ',${x},${y},' $BkupWaferDataFile);
			$FirstLineFlag = 1;
			next if ($dummycount > 1);
		}

		$testtime = $1 if ($testtime =~ /^(.*\.\d{3})/);

		my $xykey = "_" . $x . "_" .$y . "_";
		local ($^W) = 0;
		if ($xy{$xykey} == 1)
		{
			#print "xy $x $y\n";
			next;
		}
		else
		{
			$xy{$xykey} = 1;
		}

		my $Line =	"3_xloc_" . $x . "\n" .
				"3_yloc_" . $y . "\n" .
				"2_tname_testtime\n" .
				"2_mrslt_" . $testtime . "\n" .
				"2_lend\n" .
				"3_curibin_" . $curibin . "\n" .
				"3_lsep\n";
		
		print NEW "$Line";
		$Binn{$curibin}++;
	}

	# Create the iTUFF footer format
	foreach my $TBin (keys %Binn)
	{
		$iTUFFFooter .= "3_comnt_autoltl_b". $TBin . "__" . $Binn{$TBin} . "\n";
		$iBinCtr .= "4_ibinctr_". $TBin . "__" . $Binn{$TBin} . "\n";
		$TotalUnit += $Binn{$TBin};
	}

	# End time is taken from the time the script finish processing
	my $EndTime = &iTUFFDateTime(time());
	$iTUFFFooter .= "3_lend\n" . $iBinCtr .
			"4_total_" . $TotalUnit . "\n" .
			"4_enddate_" . $EndTime . "\n" .
			"4_lend\n5_lend\n6_lend\n7_lend\n";

	print NEW "$iTUFFFooter";

	close FILE;
	close NEW;

	# Rename the iTUFF .txt to original iTUFF name
	#rename ($NewiTUFF, $iTUFF) || die "Cant rename $NewiTUFF to $iTUFF : $!\n";

	open(LOG, ">>/lopte/data/tmp/.TMPWAFERDATA/TTLError.txt") || die "Log file at /lopte/data/tmp/.TMPWAFERDATA : $!\n";
	print LOG "Found error $EndTime :: $iTUFF, new iTUFF $NewiTUFF\n";
	close LOG;
}

# Get the lot directory for last 3 days
sub GetiTUFFDir
{
	local ($^W) = 0;
	next unless (($File::Find::name =~ /(\S+\/0($SearchYY)\w+_(8012|8112))/o) && ((time() - (stat($File::Find::name))[9]) <= 260000));
	push (@LotDirs, $File::Find::name);
}

# Create second, minute, hour, day, month and year format
sub iTUFFDateTime
{
	my $TimeToProcess = shift;
	my ($ss, $mi, $hh, $dd, $mm, $yyyy) = localtime($TimeToProcess);
	
	$yyyy += 1900;
	$mm++;
	$mm =~ s/^(\d)$/0$1/;
	$dd =~ s/^(\d)$/0$1/;
	$hh =~ s/^(\d)$/0$1/;
	$mi =~ s/^(\d)$/0$1/;
	$ss =~ s/^(\d)$/0$1/;

	return("$yyyy$mm$dd$hh$mi$ss");
}
