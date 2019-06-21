#!/usr/local/bin/perl

#my $Dir = '/user/home1/prodeng/lfoo1/L3480328_6102';
my $Dir = 'C:\mix\L3480328_6102';
#my $Dir = 'C:\mix\L3480268_6102';

my %Summary = ();
my %Data1 = ();
my %Data2 = ();
my @Sum =();
my $DiffFileName = 0;
my $SameFileName = 0;
my $Already = 0;
my $Count = 0;

chdir $Dir || die "Cant change dir $Dir : $!\n";

foreach my $File (<*>)
{

	next unless ($File =~ /^\d[A-E]$/);
	push (@Sum, $File);

	open (FILE, $File) || die "Cannt open $File : $! \n"; 
	while (<FILE>)
	{
		$PrtName = $1 if (/3_prtnm_(\w+)/);
		$Fablot = $1 if(/2_trlot_(\w+)/);
		$WaferID = $1 if (/2_trwafer_(\d+)/); 
		$xloc = $1 if (/2_trxloc_(\S+)/);
		$yloc = $1 if (/2_tryloc_(\S+)/);
		$Bin = $1 if (/2_curibin_(\S+)/);
		
		if (/3_lsep/)
		{
			my $Key = "$Fablot $WaferID $xloc $yloc";
			$Summary{$File}{$Key} = "File: $File, PrtName: $PrtName, Bin: $Bin";
		}
	}
	close FILE;
}

my $SameFlag = 0;
my $Count12 =0;
my $ArrangeLine = "";
my @ArraySum = ();
my $Bin12File = 'C:\mix\Bin12.txt';
open (BIN12, ">$Bin12File");
open (DUMMY, ">C:\\mix\\TL3480268.txt") || die "Cannt open Dummy : $!\n";
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
			print DUMMY "$ArrangeLine\n";
			push (@ArraySum, $ArrangeLine);
			if ($tBin =~ /^[12]$/)
			{
				$Count12++;
				print "$Count12 $ArrangeLine\n";
				print BIN12 "$Count12\t$ArrangeLine\n";
			}
			$ArrangeLine = "";
			$SameFlag = 0;
			
		}
		else 
		{
			print DUMMY "$ArrangeLine\n";
			chomp($tBin);
			push (@ArraySum, $ArrangeLine);
			if ($tBin !~ /^[12]$/)
			{
				#print "$Count $ArrangeLine\n";
				$Count++;
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
close DUMMY;
close BIN12;

open (FILE, ">C:\\mix\\TL3480268A.txt");
foreach my $LineSum (sort {$a cmp $b} @ArraySum)
{
	print FILE "$LineSum\n";
}
close FILE;
