open (OUT, ">temp_output.txt");
open (FILE, "temp.txt") || die "Cant open file\n";
while (<FILE>)
{
	chomp();
	if (/(\w+)/ig)
	{
		my $Data = $1;
		chomp($Data);
		print  "$Data\n";
	}
}
close FILE;
close OUT;
