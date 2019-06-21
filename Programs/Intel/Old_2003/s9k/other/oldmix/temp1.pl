
my %Summary;

open (M2A, "2A");
open (M3A, "3A");
while (<M3A>)
{
	$PrtName = $1 if (/3_prtnm_(\w+)/);
	$Fablot = $1 if(/2_trlot_(\w+)/);
	$WaferID = $1 if (/2_trwafer_(\d+)/); 
	$xloc = $1 if (/2_trxloc_(\S+)/);
	$yloc = $1 if (/2_tryloc_(\S+)/);
	$Bin = $1 if (/2_curibin_(\S+)/);
		
	if (/3_lsep/)
	{
		my $Key = "$Fablot\t$WaferID\t$xloc\t$yloc\t";
		$Temp1 = "File: $File, PrtName: $PrtName";

		while (<M2A>)
		{
			#print $_;
			$PrtName1 = $1 if (/3_prtnm_(\w+)/);
			$Fablot1 = $1 if(/2_trlot_(\w+)/);
			$WaferID1 = $1 if (/2_trwafer_(\d+)/); 
			$xloc1 = $1 if (/2_trxloc_(\S+)/);
			$yloc1 = $1 if (/2_tryloc_(\S+)/);
			$Bin1 = $1 if (/2_curibin_(\S+)/);
			if (/3_lsep/)
			{
				my $Key1 = "$Fablot1\t$WaferID1\t$xloc1\t$yloc1\t";
				if ($Key eq $Key1)
				{
					$Temp2 = "File: 2A PrtName: $PrtName1";
					print "$Temp1 $Temp2\n";
				}
			}

		}
	}

}
close M3A;
close M2A;

