
my $Dir = 'C:/perl/Programs/data/orig/';
my $Mod = 'C:/perl/Programs/data/mod/';

chdir $Dir || die "Cant change dir $Dir : $!\n";
foreach my $File (<*>)
{
	my $NewFile = $Mod . $File;
	open (OUT, ">$NewFile") || die "Can't open $NewFile : $!\n";
	open (FILE, $File) || die "Can't open $File : $!\n";
	while (<FILE>)
	{
		chomp;
		if (/^2_/)
		{
			#print "$_\n";
			print OUT "$_\n";
		}
	}
	close FILE;
	close OUT;
}
