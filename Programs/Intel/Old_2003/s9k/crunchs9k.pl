#################################################################################
#                                                                               #
#        Foo Lye Cheung                             NCO PDQRE Automation        #
#        inet 253 6452                              Penang                      #
#                                                                               #
#        DESCRIPTION                                 				#
#        FTP the iTUFF for the lot that is intended to crunch the data		#
#        to local windows environment.						#
#	 On command prompt, let's put the script at C:\s9k			#
#	 C:\s9k>crunchs9k.pl C:\s9k\L4280387_6152 				#
#	 where the iTUFF are FTPped at C:\s9k\<lot>_<location>			#
#	 Generated 3 files at C:\s9k\<lot>_<locaition>\<lot>\ :-		#
#	 i. L4280387_6152All.xls (all complete crunched iTUFF datalog		#
#	 ii. L4280387_6152Bin12.xls (contains retest Bin 1/2 and total good)	#
#	 iii. L4280387_6152BinR.xls (contains all rejects do not go to Last Sum	#
#                                                                               #
#        NOTES                                                                  # 
#        Runs manually							        #
#										#
#        DEPENDENCIES								#
#                                                                               #
#        RELEASES                                                               #
#        08/16/2004  rev1.0 - Main code release                                 #
#                                                                               #
#################################################################################

use strict;
use warnings;

# Global variables are declared here
my $Dir = $ARGV[0];
my ($Lot, $Locn) = ($1, $2) if ($Dir =~/(\w+)_(\d+)$/);
my $AnalyDir = $Dir."\\".$Lot;
mkdir $AnalyDir, 0777;
my $AnalyzeFile = $Dir."\\".$Lot."\\".$Lot."_".$Locn."Bin12.xls";
my $ARFile = $Dir."\\".$Lot."\\".$Lot."_".$Locn."BinR.xls";
my $CompleteSum = $Dir."\\".$Lot."\\".$Lot."_".$Locn."All.xls";
my (%Summary, @Sum) = ();
my ($TotalBin1, $TotalBin2) = (0, 0);

# Main program start here
&GetAllSum();
&Analyse();

# Get all ULT information for analyze
sub GetAllSum
{
	my %SameKey = ();
	my ($PrtName, $Fablot, $WaferID, $xloc, $yloc, $Bin) = ("", "", "", "", "", "", "", "");
	my ($CountNoULT) = (0);

	chdir $Dir || die "Cant change dir $Dir : $!\n";

	foreach my $File (<*>)
	{
		my ($TempKey, $Key) = ("", "");
		my $TempPrtName;
		next unless ($File =~ /^\d[A-E]$/);
		push (@Sum, $File);

		open (FILE, $File) || die "Cannt open $File : $! \n"; 
		while (<FILE>)
		{
			s/ //g;
			$PrtName = $1 if (/3_prtnm_(\w+)/);
			$Fablot = $1 if(/2_trlot_(\S+)/);
			$WaferID = $1 if (/2_trwafer_(\S+)/); 
			$xloc = $1 if (/2_trxloc_(\S+)/);	
			$yloc = $1 if (/2_tryloc_(\S+)/);
			$Bin = $1 if (/2_curibin_(\S+)/);

			if (/4_ibinctr_(\d)_(\d+)/)
			{
				my $Binning = $1;
				my $BinCount = $2;

				if ($Binning == 1)
				{
					$TotalBin1 += $BinCount;
				}
				elsif ($Binning == 2)
				{
					$TotalBin2 += $BinCount;
				}
			}
		
			# Organize the reference key to ensure that ULT as the reference
			if (/2_lend/)
			{
				$Key = "";
				if (($Fablot eq "") && ($WaferID eq "") && ($xloc eq "") && ($yloc eq ""))
				{
					$Key = "NO ULT $CountNoULT";
				$CountNoULT++;
				}
				else 
				{
					$Key = "$Fablot $WaferID $xloc $yloc";
				}

				no warnings;
				next if (($PrtName eq "") || ($TempPrtName eq $PrtName));

				# There no such ULT exist in the memory, insert the ULT
				if ($Summary{$File}{$Key} eq "")
				{
					$Summary{$File}{$Key} = "File: $File, PrtName: $PrtName, Bin: $Bin";
				}

				else
				{
					$SameKey{$File}{$Key}++;
					$Key .= " Same $SameKey{$File}{$Key}";
					$Summary{$File}{$Key} = "File: $File, PrtName: $PrtName, Bin: $Bin";
					#print "$SameKey{$File}{$Key} :: $Summary{$File}{$Key} = File: $File, PrtName: $PrtName, Bin: $Bin";
				}
				$TempPrtName = $PrtName;
				($Fablot, $WaferID, $xloc, $yloc, $Key) = ("", "", "", "", "", "");
		
			}
		}
		close FILE;
	}
}

# Analyse all the ULT information
sub Analyse
{
	my ($SameFlag, $DiffFileName, $SameFileName, $Already, $Count, $Count12) = (0, 0, 0, 0, 0, 0);
	my (%SortSum, @ArraySum) = ();
	my $ArrangeLine = "";

	open (AFILE, ">$AnalyzeFile") || die "Can't open $AnalyzeFile : $!";
	open (RFILE, ">$ARFile") || die "Can't open the file $ARFile : $!";
	foreach my $MFile (sort keys %Summary)
	{
		print "Processing $MFile ...\n";
		foreach my $Key (keys %{$Summary{$MFile}}) 	
		{
			my ($tSum, $tUnit, $tBin) = ($1, $2, $3) if  $Summary{$MFile}{$Key} =~ /File:\s+(\w{2})\S\s+PrtName:\s+(\d+)\S\s+Bin:\s+(\d+)/;
			$ArrangeLine = "$tSum\t$tUnit\t$Key\t$tSum\t$tUnit\t$tBin";
		
			foreach my $StoreSum (@Sum)
			{
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
							my ($tSum, $tUnit, $tBin) = ($1, $2, $3) if  $Summary{$StoreSum}{$FabInfo} =~ /File:\s+(\w{2})\S\s+PrtName:\s+(\d+)\S\s+Bin:\s+(\d+)/;
							$ArrangeLine .= "\t$tSum\t$tUnit\t$tBin";
						}
					}
				}
			}

			if ($SameFlag)
			{
				push (@ArraySum, $ArrangeLine);
				if ($tBin =~ /^[12]$/)
				{
					$Count12++;
					#print "$Count12 $ArrangeLine\n";
					print AFILE "$Count12\t$ArrangeLine\n";
				}
				$ArrangeLine = "";
				$SameFlag = 0;
			}
			else 
			{
				chomp($tBin);
				push (@ArraySum, $ArrangeLine);
				if ($tBin !~ /^[12]$/)
				{
					if ($ArrangeLine !~ /$Sum[$#Sum]/)
					{
						print RFILE "$Count\t$ArrangeLine\n";
						$Count++;
					}
				}
				$ArrangeLine = "";
				$SameFlag = 0;
			}
			$Already = 0;
		}
		$Count = 0;
	}

	my $TotalGood = $TotalBin1 + $TotalBin2;
	print "Total Bin 1: $TotalBin1 and Total Bin 2: $TotalBin2\n";
	print AFILE "\tFrom Datalog Bin 1: $TotalBin1 and Total Bin 2: $TotalBin2\n";
	print AFILE "\tTotal good bin (datalog B1 & B2) = $TotalGood\n";
	close RFILE;
	close AFILE;

	foreach my $LineSum (sort @ArraySum)
	{
		#print "$LineSum\n";
		my ($SSum, $SPrtName, @SOther) = split (/\t/, $LineSum);
		$SortSum{$SSum}{$SPrtName} = $LineSum;
	}

	# Rearrange the spreadsheet for all the sum
	open (FILE, ">$CompleteSum") || die "Can't open $CompleteSum : $!";	
	print FILE "\n\n\n";
	foreach my $KeySum (sort keys %SortSum)
	{
		foreach my $KeyPrtName (sort {$a <=> $b} keys %{$SortSum{$KeySum}})
		{
			print FILE "\t$SortSum{$KeySum}{$KeyPrtName}\n";
		}
		print FILE "\n\n\n";
	}
	close FILE;
}
