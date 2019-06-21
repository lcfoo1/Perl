
my %ass = ();
open (FILE, "assembly.dat") || die "Cant open\n";
while (<FILE>)
{
	chomp;
	my $Site =  $_;
	$ass{$Site} = $Site;
}
close FILE;

foreach my $Dat (keys %ass)
{
	print "$Dat\n";
}
