
my $HPLevel3Table = "c:\\Perl\\Programs\\HPLevel3.cfg";
my %ProductL3;
my $FoundL3Flag = 0;
open (L3TABLE, $HPLevel3Table) || die "Cannt open $HPLevel3Table : $!\n";
while (<L3TABLE>)
{
	my ($Prod, $Level3) = split(/\s+/, $_);
	$ProductL3{$Prod} = $Level3;
}
close L3TABLE;

open (FILE, "W002");
while (<FILE>)
{
	if(/7_dsrcprg_(\w+)/)
	{
		$Tester = $1;
	}
	if(/6_prdct_(\w+)/)
	{
		$MarketProd = $1;
		last;
	}
}
close FILE;

if ($Tester eq "HP94K")
{
	print "$MarketProd\n";
	foreach my $Prod (keys %ProductL3)
	{
		if ($MarketProd eq $Prod)
		{
			print "$MarketProd\n";
			$FoundL3Flag = 1;
		}

	}
}

if (!$FoundL3Flag)
{
	#get the lot from Mars database
	open (L3TABLE, ">>$HPLevel3Table") || die "Cannt open $HPLevel3Table : $!\n";
	print L3TABLE "LXT9785EC2\t567456\n";
	close L3TABLE;
}
