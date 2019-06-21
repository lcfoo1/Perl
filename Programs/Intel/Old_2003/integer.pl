
use strict;
use warnings;

my %BadBin2 = ( A => [1]);
#my %BadBin2 = ( A => [1, 2, 4, 5, 6, 8, 10, 12, 17,18,19, 25, 30, 31,32, 35]);
#my %BadBin2 = ( B => [2,5,6, 7, 8, 10, 12, 18, 19, 25, 30,31, 35]);
my @TmpBadBin2 =('');
my ($StartPrtNameFlag, $IncPrtNameFlag, $DiffFlag, $InsertFlag) = (0, 0, 0, 0);

foreach my $SummaryError (keys %BadBin2)
{
	# Add dummy # to the list, to get last value
	push (@{$BadBin2{$SummaryError}}, 1000000);

	my ($StartPrtName, $SinglePrtName) = ();
	my ($AddPrtName, $PrevPrtName) = ('',0);
	my $Tmp = '';
	foreach my $PrtName (@{$BadBin2{$SummaryError}})
	{
		$AddPrtName = $PrevPrtName + 1;
		if (($PrtName ==1000000) && ($PrevPrtName == 1))
		{
			push (@TmpBadBin2, $PrevPrtName);			
			last;
		}
		$PrevPrtName = 1 if ($PrtName == 1);

		if ($PrtName eq $AddPrtName)
		{
			if (!$StartPrtNameFlag)
			{	
				print "torpedo $PrevPrtName\n";
				$StartPrtName = $PrevPrtName;
				$StartPrtNameFlag = 1;
			}
			else
			{
				$IncPrtNameFlag = 1;
				print "Same increase $StartPrtName to $PrtName\n";
				$InsertFlag = 1;
				$Tmp = "$StartPrtName-$PrtName";
		
			}
		}
		else
		{
			if (($IncPrtNameFlag) && (!$StartPrtNameFlag))
			{
				if ($DiffFlag >0)
				{		
					print "Different $PrtName\n";
					push (@TmpBadBin2, $PrtName);
				}
				$IncPrtNameFlag = 0;
			}
			elsif (($IncPrtNameFlag) && ($InsertFlag))
			{
				push (@TmpBadBin2, $Tmp);
				$StartPrtName = '';
				$InsertFlag = 0;
				$IncPrtNameFlag = 0;
			}
			elsif ($StartPrtNameFlag)
			{
				print "###My $StartPrtName-$PrevPrtName\n";
				push (@TmpBadBin2, "$StartPrtName-$PrevPrtName");
				$StartPrtNameFlag = 0;
				$StartPrtName = '';
			}
			else
			{
				if (($PrtName != $PrevPrtName) && ($PrevPrtName ne $TmpBadBin2[$#TmpBadBin2]))
				{
					print "Single prtname $PrevPrtName\n";
					#print "Bullshoit $PrtName ${$BadBin2{$SummaryError}}[$#{$BadBin2{$SummaryError}}]\n";
					push (@TmpBadBin2, $PrevPrtName);
				}
			}
			$StartPrtNameFlag = 0;			
			$SinglePrtName = $PrtName;
			$DiffFlag=1;
		}

		$PrevPrtName = $PrtName;
	}
	print "Original @{$BadBin2{$SummaryError}}\n";
	print "Modified @TmpBadBin2\n";
	@TmpBadBin2 =();
}