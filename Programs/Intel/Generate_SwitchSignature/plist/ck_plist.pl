
my $File = "ck_plist.txt";
my $OFile = "out_ck_plist.txt";

open (OUT, ">$OFile") || die "Cant $OFile : $!\n";
open (IN, $File) || die "Cant $File : $!\n";
while(<IN>)
{
	chomp;
	s/GlobalPList\s+(\S+)/$1/g;
	s/\s+//g;
	print OUT "$_\n";
}
close IN;
close OUT;




