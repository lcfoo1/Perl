
my $i = 1;
my $j = 0;
my @datas = ("1p4", "1p5", "1p6", "1p7", "1p8", "1p9");
open (FILE, "Test.txt") or die "Cant open";
while (<FILE>)
{
	$Index = 45400 + ($i * 100000);
	foreach my $data (@datas)
	{
		chomp;
		#print $_ . $data . "V" . "\n";
		$Index += 10;
		print $Index . "\n";
		
	}

	#$j++;
	#if ($j % 3)
	{
		$i++;
	}
}
close FILE;



