
my @SC1 = ();
my @SC2 = ();
my @SC3 = ();
my @SC4 = ();
my $Cnt = 0;
for (my $i=64; $i <320; $i++)
{
	if ($Cnt == 4)
	{
		$Cnt = 0;
	}
	push (@SC1, $i) if (0 == $Cnt);
	push (@SC2, $i) if (1 == $Cnt);
	push (@SC3, $i) if (2 == $Cnt);
	push (@SC4, $i) if (3 == $Cnt);
	$Cnt++;
}

print join (',', @SC1) . "\n";
print join (',', @SC2) . "\n";
print join (',', @SC3) . "\n";
print join (',', @SC4) . "\n";

