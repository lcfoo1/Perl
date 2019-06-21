
my $File = 'nsbftsigon.txt.csv';
my (%Lstep, %Hstep) = ();
open (IN, $File) || die "Cant open $File : $!\n";
while (<IN>)
{
	chomp;
	#s/\s+//g;
	$_ = "\U$_\E";
	my ($Lsteptn, $Lstepplist, $Hsteptn, $Hstepplist) = split (/\,/, $_);
	$Lstep{$Lsteptn} = $Lstepplist if $Lsteptn ne "";
       	$Hstep{$Hsteptn} = $Hstepplist if $Hsteptn ne "";
	
}
close IN;

open (OUTLHS, ">samepat.csv");
open (OUTLHD, ">diffpat.csv");
open (OUTL, ">lpatonly.csv");
foreach my $Lplist (keys %Lstep)
{
	my $LFlag = 0;
	foreach my $Hplist (keys %Hstep)
	{
		if ($Lplist eq $Hplist)
		{
			$LFlag = 1;
			if ($Lstep{$Lplist} eq $Hstep{$Hplist})
			{
				print OUTLHS "$Lplist,$Lstep{$Lplist},$Hplist,$Hstep{$Hplist}\n";
			}
			else
			{
				print OUTLHD "$Lplist,$Lstep{$Lplist},$Hplist,$Hstep{$Hplist}\n";

			}
			last;
		}
	}

	if (!$LFlag)
	{
		print OUTL "$Lplist,$Lstep{$Lplist}\n";
	}

}
close OUTLHD;
close OUTLHS;
close OUTL;



open (OUTH, ">rpatonly.csv");
foreach my $Hplist (keys %Hstep)
{
	my $HFlag = 0;
	foreach my $Lplist (keys %Lstep)
	{
		if ($Lplist eq $Hplist)
		{
			$HFlag = 1;
			last;
			#print "$Lplist,$Lstep{$Lplist},$Hplist,$Hstep{$Hplist}\n";
		}
	}

	if (!$HFlag)
	{
		print OUTH "$Hplist,$Hstep{$Hplist}\n";
	}
}
close OUTH;
