#!/usr/local/bin/perl

#my $Dir = '/user/home1/prodeng/lfoo1/L3480328_6102';
#my $Dir = "C:\\s9k\\L4220420_6152";
my $Dir = $ARGV[0];
my ($Lot, $Locn) = ($1, $2) if ($Dir =~/(\w+)_(\d+)$/);
my $AnalyDir = $Dir."\\".$Lot;
mkdir $AnalyDir, 0777;
my $AnalyzeFile = $Dir."\\".$Lot."\\".$Lot."_".$Locn."Bin12.xls";
my $ARFile = $Dir."\\".$Lot."\\".$Lot."_".$Locn."BinR.xls";
my $CompleteSum = $Dir."\\".$Lot."\\".$Lot."_".$Locn."All.xls";

my %Summary = ();
my @Sum =();
my ($DiffFileName, $SameFileName, $Already) = (0, 0, 0);
my ($Count, $CountNoULT, $SameKeyCount) = (0, 0, 0);
my ($TotalBin1, $TotalBin2) = (0, 0);
my ($Bin1Sum, $Bin2Sum) = (0, 0);

chdir $Dir || die "Cant change dir $Dir : $!\n";
open (NEW, ">C:\\s9k\\DATA1.txt");
foreach my $File (<*>)
{
	my $TempKey;
	my $TempPrtName;
	my $FailData;
	next unless ($File =~ /^\d[A-E]$/);
	push (@Sum, $File);

	open (FILE, $File) || die "Cannt open $File : $! \n"; 
	while (<FILE>)
	{
		s/ //g;
		$PrtName = $1 if (/3_prtnm_(\w+)/);
		$Fablot = $1 if(/2_trlot_(\w+)/);
		$WaferID = $1 if (/2_trwafer_(\d+)/); 
		$xloc = $1 if (/2_trxloc_(\S+)/);
		$yloc = $1 if (/2_tryloc_(\S+)/);
		$Bin = $1 if (/2_curibin_(\S+)/);
		
		if (/2_pttrn_FUSE_DATA/)
		{
			$_ = <FILE>;
			if (/2_faildata_(.*)/)
			{
				#$FailData = $1;
			}
		}
		$FailData = $1 if (/2_comnt_(.*)/);
		
		#print "$FailData\n";

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
		
		if (/2_lend/)
		{
			my $Key = "";
			if (($Fablot eq "") && ($WaferID eq "") && ($xloc eq "") && ($yloc eq ""))
			{
				$Key = "NO ULT $CountNoULT";
				$CountNoULT++;
			}
			else 
			{
				$Key = "$Fablot $WaferID $xloc $yloc";
			}

			next if (($PrtName eq "") || ($TempPrtName eq $PrtName));

			if ($Summary{$File}{$Key} eq "")
			{
				$Summary{$File}{$Key} = "File: $File, PrtName: $PrtName, Bin: $Bin";
				if (($Bin != 2)  && ($FailData =~ /^U1UUU11U/))
				{
					print NEW "$File\t$PrtName\t$Key\t$FailData\t$Bin\n";
				}
				
			}
			else
			{
				
				if ($Key eq $TempKey)
				{
					$SameKeyCount++;
				}
				else 
				{
					$SameKeyCount=0;
				}
				$TempKey = $Key;
				$Key .= " Same $SameKeyCount";
				$Summary{$File}{$Key} = "File: $File, PrtName: $PrtName, Bin: $Bin";
			}
			#print "$Summary{$File}{$Key}\n";
			$TempPrtName = $PrtName;
			($Fablot, $WaferID, $xloc, $yloc, $Key) = ("", "", "", "", "", "");
	
		}
	}
	close FILE;
}
close NEW;

my $SameFlag = 0;
my $Count12 =0;
my $ArrangeLine = "";
my @ArraySum = ();

open (AFILE, ">$AnalyzeFile");
open (RFILE, ">$ARFile");
foreach my $MFile (sort keys %Summary)
{
	print "My Mfile $MFile\n";
	foreach $Key (keys %{$Summary{$MFile}}) 	
	{
		my ($tSum, $tUnit, $tBin) = ($1, $2, $3) if  $Summary{$MFile}{$Key} =~ /File:\s+(\w{2})\S\s+PrtName:\s+(\d+)\S\s+Bin:\s+(\d+)/;
		#$ArrangeLine = "$tSum $tUnit $Key $tSum $tUnit $tBin";
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
						#print "$ArrangeLine\n";
					}
				}
			}
		}
		$Already = 0;

		if ($SameFlag)
		{
			push (@ArraySum, $ArrangeLine);
			if ($tBin =~ /^[12]$/)
			{
				$Count12++;
				print "$Count12 $ArrangeLine\n";
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
			else
			{

				#print "$ArrangeLine\n";
			}
			$ArrangeLine = "";
			$SameFlag = 0;
		}
	}
	print "My $MFile = $Count\n";
	$Count = 0;
}
my $TotalGood = $TotalBin1 + $TotalBin2;
print "Total Bin 1: $TotalBin1 and Total Bin 2: $TotalBin2\n";
print AFILE "\tFrom Datalog Bin 1: $TotalBin1 and Total Bin 2: $TotalBin2\n";
print AFILE "\tTotal good bin (datalog B1 & B2) = $TotalGood\n";
close RFILE;
close AFILE;


%SortSum = ();
foreach my $LineSum (@ArraySum)
{
	
	my ($SSum, $SPrtName, @SOther) = split (/\t/, $LineSum);
	#@SOther = ("1A", "733", "1", "2A", "733", "1");
	#for($i=0; $i<=$#SOther; $i++)
	#{
	#	print "$SOther[$i]\n";
	#	foreach my $CSum (sort @Sum)
	#	{
	#		if 
	#	}
	#	$i +=3;
	#	print "$SOther[$i]\n";
	#}
	#print "$SSum :: $SPrtName :: @SOther :: $LineSum\n";
	$SortSum{$SSum}{$SPrtName} = $LineSum;
}


open (FILE, ">$CompleteSum");	
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
