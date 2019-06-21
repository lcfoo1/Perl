
my $line = "";
open (OUT, ">outpgm.txt");
open (FILE, "4pgm.txt");
while(<FILE>)
{
	chomp;
	$line .= $_ . "/";
}
close FILE;

print OUT "$line\n";
close OUT;


