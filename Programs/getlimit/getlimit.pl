use Cwd;
my $Dir = getcwd;

foreach my $File (<"VB/*">)
{
	$File = $Dir . "/" . $File;
	$File =~ s/\//\\/ig;
	print "$File\n";

	#Call LimitsTool.TestLimit(measured_freq_ck500kHz_BeforeCal, PinToMeasure, "PMU_Freq_ck500kHz_BeforeCal")
	#Call LimitsTool.TestLimit(measured_freq_ck500kHz_AfterCal, PinToMeasure, "PMU_Freq_ck500kHz_AfterCal")
	#Call LimitsTool.TestLimit(measured_freq_3MHz_BeforeCal, PinToMeasure, "PMU_Freq_OscSwr3MHz_BeforeCal")
	#Call LimitsTool.TestLimit(measured_freq_3MHz_AfterCal, PinToMeasure, "PMU_Freq_OscSwr3MHz_AfterCal")
	open (FILE, $File) || die "Cant open $File : $!\n";
	while (<FILE>)
	{
		if (/LimitsTool/ig)
		{
			print "\t\t$_\n";
		}
	}
	close FILE;
	#exit;

}
