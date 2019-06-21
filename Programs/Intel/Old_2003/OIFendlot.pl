#!/usr/contrib/bin/perl 

#################################################################################
#										#
#	Foo Lye Cheung			Sort Automation				#
#	02/16/2004								#
#										#
#	OIFendlot.pl is to integrate with the end lot function on the OIF	#
#	This script will check the waferid from the token 4_waferid_		#
#	rename the ituff name and copy the ituff to the ARIES directory,	#
#	create a ARIES signal file and Data Broker signal file.			#
#										#
#	Require Perl 5.0	 						#
#										#
#	Rev 1.0									#
#										#
#################################################################################

### Main program starts here ###
# Format: wafer.pl <lot#> <location>

($Lot, $Locn) = ($ARGV[0], $ARGV[1]);
$OrgDir = "/lopte/data/summary/t3/".$Lot."_".$Locn."/";
$OrgLogFile = $OrgDir."LOC/".$Lot.".inkless.log";
&Main($Lot);

sub Main
{
	print "End Lot at $OrgDir\n";

	opendir (DIR,$OrgDir) || die "Cannt open $OrgDir : $!\n";
	@Files = readdir(DIR);
	closedir DIR;

	&Ituff_Copy_Ren(@Files);

	$ITLog = "/lopte/home1/lfoo1/DataBroker/Log/".$Lot.".inkless.log";
	qx/cp $OrgLogFile $ITLog/;	
}

sub Ituff_Copy_Ren
{
	@Files = @_;
	$count = 0;
	foreach $File (@Files)
	{
		next if (-f $File);
		$File = $OrgDir.$File;
		next unless (-f $File);
		next if ($File =~ (/^W/));

		print "$File\n";
		open (FILE, $File) || die "Cannt open $File: $!\n";
		while (<FILE>)
		{
			if (/4_wafid_(\w+)/)
			{
				$WaferID = $1;
				$WaferID = $WaferID.$1 if ($File =~ /(R[1-9])$/);
				$AriesDir = "/lopte/intel/hp94k/sort/aries/data/ituff/".$Lot."_".$Locn."/";
				#if ($count == 0)
				#{
				#	qx/mkdir $AriesDir/;
				#	$count = 1;
				#}
				$AriesFile = $AriesDir."W".$WaferID;
	
				print "File: $File and waferid: $WaferID and $AriesFile\n";
				last;
			}
		}
		close FILE;
		qx/cp $File $AriesFile/;
		$ModFile = $OrgDir."W".$WaferID;
		#qx/mv $File $ModFile/;
		&LogFile($File, $ModFile, $AriesFile);
		&AriesSig($WaferID);
		&DataBrokerSig($WaferID);
	}
}

# Create log file compared to real ituff name to wafer id read 
# vendor scribe id
sub LogFile
{
	($File, $ModFile, $AriesFile) = @_;
	$Now = localtime(time);

	$OrgFile = $1 if $File =~ /(W\w+)$/;
	$ModFile = $1 if $ModFile =~ /(W\w+)$/;

	open (WLOG, ">>$OrgLogFile") || die "Cannt open $OrgLogFile : $!\n";
	print WLOG "File: $OrgFile, renamed to $ModFile, and Aries: $AriesFile at $Now $OrgLogFile\n";
	close WLOG;
}

# Create signal file for Aries
sub AriesSig
{
	$WaferID = shift;	
	$AriesSigFile = "/lopte/intel/hp94k/sort/aries/signal/ituff/".$Lot."_".$Locn."_".$WaferID.".sig";
	open (ARIES, ">$AriesSigFile") || die "Cannt open $AriesSigFile : $!\n";
	close ARIES;
}

# Create signal file for Databroker
sub DataBrokerSig
{
	$WaferID = shift;	
	#$DataBrokerSigFile = "/lopte/home1/lfoo1/DataBroker/signal/SORT==DATALOGS==".$Lot."_8012==W".$WaferID.".sig";
	$DataBrokerSigFile = "/lopte/intel/hp94k/sort/databroker/signal/SORT==DATALOGS==".$Lot."_".$Locn."==W".$WaferID.".sig";
	open (DBROKER, ">$DataBrokerSigFile") || die "Cannt open $DataBrokerSigFile : $!\n";
	close DBROKER;
}
