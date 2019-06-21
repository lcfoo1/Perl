
my $File = 'CKT_search_fmax_config_input_Rev2.0.txt';
my $OFile = '>CKT_search_fmax_config_input_Rev2.0.output.txt';
open(OUT, $OFile);
open(FILE, $File);
while (<FILE>)
{
	chomp;
	if(/IND_SEARCH_SET\s+(\S+)/)
	{
		print OUT "$1\n";
	}
}
close FILE;
close OUT;
