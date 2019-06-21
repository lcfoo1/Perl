
my $File = "Psc.lvl";
my $Flag = 1;
my $FCurly = 0;
my $Count = 0;
my $Data = "";

open (FILE, $File) || die "Cant open $File : $!\n";
while (<FILE>)
{
	chomp;
	if (/Levels\s+(\S+)/i)
	{
		my $Level = $1;
		$Count++;
		while (<FILE>)
		{
			chomp;
			$Data = $_ if (($_ !~ /\{/) && $Count == 2);
			if (/\{/)
			{	
				$FCurly = 1;
				$Flag = 0;
				$Count++;
				next;
			}					
			if (/\}/)
			{
				$Flag = 1;
				$OpenCurly = 0;
				$Count--;
			}
			
			if ((!$Flag) && ($FCurly))
			{
				print "$Data :: $_\n";
			}

			if ($Count == 1)
			{
				#last;
			}
		}
	}
}
close FILE;
