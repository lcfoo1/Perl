
%Line =();
open (FILE, "lcfoook.txt");
while (<FILE>)
{
	s/ //g;
	#s/\t\t/\t/;
	my $temp = "$1\t$2" if (/^\S+\t\S+\t\S+\t\S+\t\t(\w+)\t(\d+)/);
	#my $temp = "$1\t$2" if (/^\S+\t\S+\t\S+\t\S+\t(\w+)\t(\d+)/);
	$Line{$temp} = $_;
	#print "My Temp $temp :: $_ ok";
}
close FILE;

open (FILE1, ">>lcfoo1.txt");
foreach my $LineNow (sort {$a cmp $b} keys %Line)
{
	print "$Line{$LineNow}";
	print FILE1 "$Line{$LineNow}";
}
close FILE1;
