
my $File = 'ref.txt';
my $input = 'input.txt';
my $Out = ">output.txt";
my @Names;

open (IN, $input) || die "Cant open $input : $!\n";
while (<IN>)
{
	chomp;
	if (/DIE=(\w+)/)
	{
		push (@Names, $1);
	}
}
close IN;

open (OUT, $Out);
foreach my $Name (@Names)
{
	open (FILE, $File);
	while (<FILE>)
	{
		chomp;
		if (/(IND_SEARCH_SET\s+\w+_bf_)(.*)/)
		{
			print OUT "#DIE=$Name\n";
			my $tmp = "\L$Name\E";
			$_ = $1 . $tmp . "_" . $2;
			print OUT "$_\n";
		}
		elsif (/(pre_searchset_userfunc\s+\"CKT_PatModify.dll!SetPlistDieCore:)\w+(,.*)/)
		{
			$_ = $1 . $Name . $2;
			print OUT "$_\n";
		}
		else
		{
			print OUT "$_\n";
		}
		
	}
	close FILE;
}
close OUT;
