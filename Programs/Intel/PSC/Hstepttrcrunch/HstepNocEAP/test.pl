
my $File = 'gv_noc_minvcc2';
my $Out = 'gv_noc_minvcc2.csv';
open (OUT, ">$Out") || die "Cant open $Out : $!\n";
open (IN, $File) || die "Cant open $File : $!\n";
while (<IN>)
{
	if (/\s+(\w\d{7}P\d{7}\S+)/)
	{
		print OUT "$1\n";
	}
}
close IN;
close OUT;
