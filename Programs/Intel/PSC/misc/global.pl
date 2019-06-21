
my $File = 'global.txt';

open (OUT, ">globals.keepme") || die "cant open global.keepme : $!\n";
open (IN, $File) || die "Cant open $File : $!\n";
while(<IN>)
{
	chomp;
	print OUT "FLOAT $_ = 0.0;\n";

}
close IN;
close OUT;
