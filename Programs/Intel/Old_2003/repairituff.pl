open (REPAIR, ">repair.txt");
open (FILE, "0401A07A.system10.W002.waferdata") or die "Cannt open: $!\n";
while (<FILE>)
{
	chomp;
	@data = split (/\,/,$_);
	print REPAIR "3_xloc_$data[3]\n3_yloc_$data[4]\n2_lbeg\n2_lsep\n2_tname_testtime\n2_mrslt_$data[7] s\n";
	print REPAIR "2_lend\n3_curibin_$data[5]\n3_lsep\n";
}
close FILE;
close REPAIR;

=pod
3_xloc_26
3_yloc_5
2_lbeg
2_lsep
2_tname_testtime
2_mrslt_0.076 s
2_lend
3_curibin_6
3_lsep
=cut