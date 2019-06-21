

my $tmp;
open (FILE, 'vmin.txt');
while(<FILE>)
{
	chomp;
	if(/d(sym|spt).*(0116)/)
	{
		push (@dspthfm, $_);
	}
	elsif (/(d0|d1).*(0116)/)
	{
		push (@diehfm, $_);
	}
	elsif(/d(sym|spt).*(0110)/)
	{
		push (@dsptlfm, $_);
	}
	elsif (/(d0|d1).*(0110)/)
	{
		push (@dielfm, $_);
	}
	else
	{
		print "$_\n";
	}
}
close FILE;


my $dspt_dsym_hfm = join(' ', @dspthfm);
my $dspt_dsym_lfm = join(' ', @dsptlfm);
my $d0_d1_hfm = join(' ', @diehfm);
my $d0_d1_lfm = join(' ', @dielfm);

open (OUT, ">vmin_test_out.txt");
print OUT "$dspt_dsym_hfm\n\n$dspt_dsym_lfm\n\n$d0_d1_hfm\n\n$d0_d1_lfm\n";
close OUT;
