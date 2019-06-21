# Written by Lye Cheung Foo
# Simple script to generate reference CTV for Ldat raster
my $Data = "0";
for (my $i  = 0; $i < 24; $i++)
{
	if ($i & 1)
	{
		if ("0" == $Data)
		{
			$Data = "1";
		}
		else
		{
			$Data = "0";
		}
	}

	if ($i == 0)
	{
		$Data = "0";
	}

	for (my $j = 0; $j < 32; $j++)
	{
		print "$Data";	
	}
}
