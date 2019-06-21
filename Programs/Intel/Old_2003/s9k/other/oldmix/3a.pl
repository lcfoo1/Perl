
open (FILE, "3A");
open (FILEOUT, ">>gila.txt");
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
		#print "$File $PrtName $Fablot $WaferID $xloc $yloc $Bin\n";
		my $Key = "$Fablot\t$WaferID\t$xloc\t$yloc\t$File\t$PrtName\t$Bin";
		print "$Key\n";
		#print FILEOUT "$Key\n";
		
	}
}
close FILEOUT;
close FILE;
