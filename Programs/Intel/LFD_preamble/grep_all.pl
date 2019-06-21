
foreach my $File (<*.plist>)
{
	print "File: $File\n";
	my $Out = "out_" . $File . ".csv";
	open (OUT, ">$Out") || die "Cant open $Out : $!\n";
	open (FILE, $File) || die "Cant open $File : $!\n"; 
	while (<FILE>)
	{
		chomp;
		#if (/GlobalPList\s+(\w+)\s+.*(cwma_pre\w+)\s+.*/)
		if (/GlobalPList\s+(\w+)\s+.*(cwma_pre\w+)(\s+|\]).*/)
		{
			print "$1,$2\n";
			print OUT "$1,$2\n";
		}
	}
	close FILE;
	close OUT;
}
