# Script written by Foo Lye Cheung to convert line text to tab text

my $OrgFile = $ARGV[0];
my @temp;
open(FILE, $OrgFile) or die "Cannt open the file $OrgFile : $!\n";
while(<FILE>)
{
	@temp = split(/;/, $_);
}
close FILE;

my $NewFile = "Converted.txt";
open(NEW, ">$NewFile") or die "Cannt open the file $NewFile : $!\n";
foreach my $Line (@temp)
{
	my ($occur, $name) = split (/\,/,$Line);
	print "$occur\t$name\n";
	print NEW "$occur\t$name\n";
}
close NEW;