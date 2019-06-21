
my $File = "min_pats.plist";

open (IN, $File) || die "cant open SFile : $!\n";
while (<IN>)
{
	chomp;
#GlobalPList IBIST_ACIOLB_ddr_5555_mode0_0106b_list [Mask ALL_MASK_PINs_CWA]  [BurstOff]  [PreBurst cwma_pre_vrevN4_P_010606_b_N_B1_607d_j_f_x_0_h_0_f2_reg_0_x]
	if (/GlobalPList\s+(\w+)\s+.*(cwma_pre\w+)(\s+|\]).*/)
	{
		print "$1,$2\n";
	}
}
close IN;
