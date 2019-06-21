
$File = "I:\\cmtdata\\engr\\V532P021_7721\\1A";
open (IN, $File);
while (<IN>)
{
	chomp;
	$Visual = $1 if (/2_visualid_(.*)/);
	$Fab = $1 if (/trlot_(\S+)/);
	$Wafer = $1 if (/trwafer_(\S+)/);
	$x = $1 if (/trxloc_(\S+)/);
	$y = $1 if (/tryloc_(\S+)/);

	if (/curibin/)
	{
		$Visual = $1 if (/2_visualid_(\w+)/);
		$ULT = "$Fab $Wafer $x $y";
		print "$ULT $Visual\n";
	}
}
close IN;