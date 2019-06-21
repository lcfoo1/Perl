#!/usr/local/bin/perl -w ########################################################
#                                                                               #
#        Foo Lye Cheung                             NCO PDQRE Automation        #
#        inet 253 6452                              Penang                      #
#                                                                               #
#        DESCRIPTION                                                            #
#        Runs through all production iTUFF's and detects mix and retest bin 1   # 
#        and bin 2 and save the file as .dat file.                              #
#                                                                               #
#        NOTES                                                                  # 
#        Runs as a cronjob every day at 4pm on t3admin6.png.intel.com           #
#                                                                               #
#        RELEASES                                                               #
#        08/09/2004  rev1.0 - Main code release                                 #
#                                                                               #
#################################################################################

use strict;
use File::Find;

# Variable declarations
my (%Summary, @Sum) = ();
my (@LotDir, @DeviceList) = ();
my $FoundLotFlag = 0;

my ($TotalBin1, $TotalBin2) = (0, 0);
my $ProdDir = '/db1/s9k/prod';
#@LotDir = ('/db1/s9k/prod/LCFOO123_6152', '/db1/s9k/prod/LCFOO123_6102');
#@LotDir = ('/db1/s9k/prod/LCFOO123_6152');

# Main code
&GetProdTable();
finddepth(\&GetiTUFFDir, $ProdDir);
&iTUFFDir(@LotDir);

# Get the device and PE email list from the lookup table
sub GetProdTable
{
	my $LookupTable = "/user/home1/prodeng/lfoo1/mixdevice/devicelist.tbl";
	open(PRODDEV, $LookupTable) or die "Can't open $LookupTable : $!";
	while(<PRODDEV>)
	{
		s/ //g;
		push (@DeviceList, $_);
	}
	close PRODDEV;
}

# Get all iTUFF Y summaries from directory /db1/s9k/prod
sub GetiTUFFDir
{
	local ($^W) = 0;
	next unless (($File::Find::name =~ /(\S+\/L\w+_(6102|6152))\/\dY$/o) && (-M $File::Find::name <= 1));
	#next unless (($File::Find::name =~ /(\S+\/L\w+_(6102|6152))\/\dY$/o));
	push (@LotDir, $1);
}

# Screen the lot directory
sub iTUFFDir
{
	foreach my $iTUFFDir (@LotDir)
	{
		&CheckiTUFF($iTUFFDir);
	}
}

# Check the iTUFF summary from the lookup table before processing
sub CheckiTUFF
{
	my $iTUFFDir = shift;
	my $InvalidiTUFF = 0;
	my ($LastiTUFFFlag, $DeviceFoundFlag) = (0, 0);
	my ($Lot, $Locn, $Summary, $Device, $TestProgram, $TmpTo) = ();

	chdir $iTUFFDir or die "Cann't open $iTUFFDir : $!\n";

	foreach my $iTUFF (<*>)
	{
		$LastiTUFFFlag = 1 if $iTUFF =~ /^\dY$/o;
		next unless $iTUFF =~ /^\d[ABCDE]$/;
		$InvalidiTUFF = 0;
		
	    	print "Directory: $iTUFFDir with iTUFF: $iTUFF\n";
		open (ITUFF, $iTUFF) or die "Cann't open $iTUFF : $!\n";
		while (<ITUFF>)
		{
			# End the checking as the wrong iTUFF format, /engr/restore/Database.2004_22/L4170422_6152/1A
			if (($. == 1) && ($_ !~ /^7_lbeg/o))
			{
				$InvalidiTUFF = 1;
				last;
			}

			$Lot = $1 if /^6_lotid_(\w+)/o;
			$Device = $1 if /^6_prdct_(\w+)/o;
			$TestProgram = $1 if /^6_prgnm_(\w+)/o;
			$Locn = $1 if /^5_lcode_(\d+)/o;	
			
			if (/^4_smrynam_(\w+)/o)	 
			{
				$Summary = $1;

				foreach my $Dev (@DeviceList)
				{
					chomp ($Dev);
					if ($Dev eq $Device)
					{
						$DeviceFoundFlag = 1; 
						last;
					}
				}
			}
		}
		close ITUFF;

		if (($DeviceFoundFlag) && (! $InvalidiTUFF))
		{
			&CheckiTUFFSum($iTUFFDir, $iTUFF);
		}
	}

	if (($DeviceFoundFlag) && (! $InvalidiTUFF) && ($LastiTUFFFlag))
	{
		&CheckAllSum($Lot, $Locn, $Device, $TestProgram);
		(%Summary, @Sum) = ();
		$FoundLotFlag = 1;
		$DeviceFoundFlag = 0;
	}
}

sub CheckiTUFFSum
{
	my ($iTUFFDir, $iTUFF) = @_;
	my $File = $iTUFFDir."/".$iTUFF;
	push (@Sum, $File);
	my ($Lot, $PrtName, $Fablot, $WaferID, $xloc, $yloc, $Bin, $Key) = ("", "", "", "", "", "", "", "");
	
	open (FILE, $File) || die "Cannt open $File : $! \n"; 
	while (<FILE>)
	{
		s/ //g;
		$Lot = $1 if (/^6_lotid_(\w+)$/o);
		$PrtName = $1 if (/^3_prtnm_(\w+)$/o);
		$Fablot = $1 if(/^2_trlot_(\S+)$/o);
		$WaferID = $1 if (/^2_trwafer_(\d+)$/o); 
		$xloc = $1 if (/^2_trxloc_(\S+)$/o);
		$yloc = $1 if (/^2_tryloc_(\S+)$/o);
		$Bin = $1 if (/^2_curibin_(\S+)$/o);

		if (/4_ibinctr_(\d)_(\d+)/o)
		{
			my ($Binning, $BinCount) = ($1, $2);
			$TotalBin1 += $BinCount if ($Binning == 1);
			$TotalBin2 += $BinCount if ($Binning == 2);
		}
		
		if (/2_lend/o)
		{
			if (($Fablot eq "") && ($WaferID eq "") && ($xloc eq "") && ($yloc eq ""))
			{
				$Key = "NO ULT";
			}
			else 
			{
				$Key = "$Fablot $WaferID $xloc $yloc";
			}
				
			($^W) = 0;
			if ($Summary{$File}{$Key} eq "")
			{
				$Summary{$File}{$Key} = "File: $File, PrtName: $PrtName, Bin: $Bin";
				#print "$Summary{$File}{$Key}\n";
			}
			($Fablot, $WaferID, $xloc, $yloc, $Key) = ("", "", "", "", "", "");
		}
	}
	close FILE;
}

sub CheckAllSum
{
	my ($Lot, $Locn, $Device, $TestProgram) = @_;
	my ($RetestBin12, $RejectNotToLastSum) = ("<RETEST>\n", "<REJECT>\n");
	my ($DiffFileName, $SameFileName, $Already, $Count12) = (0, 0, 0, 0, 0);
	my $SameFlag = 0;
	my $ArrangeLine = "";

	# Screening all iTUFF data to check for the retest Bin 1, 2 and rejects
	foreach my $MFile (sort keys %Summary)
	{
		foreach my $Key (keys %{$Summary{$MFile}}) 	
		{
			my ($tSum, $tUnit, $tBin) = ($1, $2, $3) if  $Summary{$MFile}{$Key} =~ /^File:\s+(\S+)\s+PrtName:\s+(\d+)\S\s+Bin:\s+(\d+)$/o;
			$ArrangeLine = "$tSum\t$tUnit\t$Key\t$tSum\t$tUnit\t$tBin";
		
			foreach my $StoreSum (sort @Sum)
			{
				# These flag to ensure that the checking in on the next sum and not same sum
				if ($StoreSum ne $MFile)
				{
					$DiffFileName = 1;
					$SameFileName = 0;
				}
			
				if ($StoreSum eq $MFile)
				{
					$Already = 1;
					$DiffFileName = 0;
					$SameFileName = 1;
					next;
				}

				if (($DiffFileName == 1) && ($SameFileName == 0) && ($Already == 1))
				{
					foreach my $FabInfo (keys %{$Summary{$StoreSum}})
					{
						if ($Key eq $FabInfo)
						{
							$SameFlag = 1;
							my ($tSum, $tUnit, $tBin) = ($1, $2, $3) if  $Summary{$StoreSum}{$FabInfo} =~ /^File:\s+(\w{2})\S\s+PrtName:\s+(\d+)\S\s+Bin:\s+(\d+)$/o;
							$ArrangeLine .= "\t$tSum $tUnit $tBin";
						}
					}
				}
			}
			$Already = 0;
			
			# Ensure that 1A good or reject found in next sum
			if ($SameFlag)
			{
				# Filter out bin 1 and 2 to check how many times it retest
				if ($tBin =~ /^[12]$/o)
				{
					$Count12++;
					#print "$Count12\t$ArrangeLine\n";
					$RetestBin12 .= "$Count12\t$ArrangeLine\n";
				}
				$ArrangeLine = "";
				$SameFlag = 0;
			
			}

			# Only 1A/1B/2A reject do not go till it become good bin
			else 
			{
				chomp($tBin);
				chomp($ArrangeLine);
				chomp($Sum[$#Sum]); 
				
				if ($tBin !~ /^[012]$/o)
				{
					# Ensure that it do not display last summary rejects
					if ($ArrangeLine !~ /$Sum[$#Sum]/o)
					{
						print "$ArrangeLine :: $Sum[$#Sum]\n";
						$RejectNotToLastSum .= "$ArrangeLine\n";
					}
				}
				$ArrangeLine = "";
				$SameFlag = 0;
			}
		}
	}

	my $Now = localtime(time);
	my $Time = time();
	my $DataFile = "/user/home1/prodeng/lfoo1/mixdevice/ftpdata/".$Lot."_".$Locn."_".$Time.".txt";

	open (DAT, ">$DataFile") || die "Can't open $DataFile : $!\n";
	print DAT "Time\t$Now\n";
	print DAT "LotNum\t${Lot}_$Locn\n";
	print DAT "Device\t$Device\n";
	print DAT "TestProgram\t$TestProgram\n";
	print DAT "Bin1\t$TotalBin1\n";
	print DAT "Bin2\t$TotalBin2\n";
	print DAT "$RetestBin12";
	print DAT "<\\RETEST>\n"; 
	print DAT "$RejectNotToLastSum";
	print DAT "<\\REJECT>\n"; 
	close DAT;

	($TotalBin1, $TotalBin2, $RetestBin12, $RejectNotToLastSum, $ArrangeLine) = (0, 0, "", "", "");
}

