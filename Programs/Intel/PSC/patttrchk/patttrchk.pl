
my $File = 'nft_maxvcc.txt.csv';
my (%Left, %Right) = ();
open (IN, $File) || die "Cant open $File : $!\n";
while (<IN>)
{
	chomp;
	#s/\s+//g;
	$_ = "\U$_\E";
	my ($Lefttn, $Leftplist, $Righttn, $Rightplist) = split (/\,/, $_);
	$Left{$Lefttn} = $Leftplist if $Lefttn ne "";
       	$Right{$Righttn} = $Rightplist if $Righttn ne "";
	
}
close IN;

open (OUTLHS, ">samepat.csv");
open (OUTLHD, ">diffpat.csv");
open (OUTL, ">lpatonly.csv");
foreach my $Lplist (keys %Left)
{
	my $LFlag = 0;
	foreach my $Hplist (keys %Right)
	{
		if ($Lplist eq $Hplist)
		{
			$LFlag = 1;
			if ($Left{$Lplist} eq $Right{$Hplist})
			{
				print OUTLHS "$Lplist,$Left{$Lplist},$Hplist,$Right{$Hplist}\n";
			}
			else
			{
				print OUTLHD "$Lplist,$Left{$Lplist},$Hplist,$Right{$Hplist}\n";

			}
			last;
		}
	}

	if (!$LFlag)
	{
		print OUTL "$Lplist,$Left{$Lplist}\n";
	}

}
close OUTLHD;
close OUTLHS;
close OUTL;



open (OUTR, ">rpatonly.csv");
foreach my $Hplist (keys %Right)
{
	my $HFlag = 0;
	foreach my $Lplist (keys %Left)
	{
		if ($Lplist eq $Hplist)
		{
			$HFlag = 1;
			last;
			#print "$Lplist,$Left{$Lplist},$Hplist,$Right{$Hplist}\n";
		}
	}

	if (!$HFlag)
	{
		print OUTR "$Hplist,$Right{$Hplist}\n";
	}
}
close OUTR;
