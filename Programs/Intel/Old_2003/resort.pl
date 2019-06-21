
use strict;
use warnings;

#my %BadBin2 = ( A => [1, 2, 4, 5, 6, 8, 10, 12, 17,18,19, 25, 30, 31,32, 35]);
my %BadBin2 = ( B => [2,5,6, 7, 8, 10, 12, 18, 19, 25, 30,31, 35]);

my @TmpBadBin2 =('');

foreach my $SummaryError (keys %BadBin2)
{
	# Add dummy # to the list, to get last unit value
	push (@{$BadBin2{$SummaryError}}, 1000000);

	my ($StartPrtNameFlag, $IncPrtNameFlag, $DiffFlag, $InsertFlag) = (0, 0, 0, 0);
	my ($StartPrtName, $Tmp, $AddPrtName, $PrevPrtName) = ('', '', '',0);

	foreach my $PrtName (@{$BadBin2{$SummaryError}})
	{
		$AddPrtName = $PrevPrtName + 1;
		$PrevPrtName = 1 if ($PrtName == 1);

		if ($PrtName eq $AddPrtName)
		{
			if (!$StartPrtNameFlag)
			{	
				$StartPrtName = $PrevPrtName;
				$StartPrtNameFlag = 1;
			}
			else
			{
				$IncPrtNameFlag = 1;
				$InsertFlag = 1;
				$Tmp = "$StartPrtName-$PrtName";		
			}
		}
		else
		{	
			# Case 1, 2, 5, 7, 8 (where have single or more integer in between)
			if (($IncPrtNameFlag) && (!$StartPrtNameFlag))
			{
				if ($DiffFlag >0)
				{		
					push (@TmpBadBin2, $PrtName);
				}
			}
			elsif (($IncPrtNameFlag) && ($InsertFlag))
			{
				# Insert for 1,2,3 condition
				push (@TmpBadBin2, $Tmp);
				$InsertFlag = 0;
			}
			elsif ($StartPrtNameFlag)
			{
				# Insert for condition 1, 3, 4
				push (@TmpBadBin2, "$StartPrtName-$PrevPrtName");
			}
			else
			{
				if ($PrevPrtName == 0)
				{
					# Ignore the $PrevPrtName variable at the beginning
				}
				elsif (($PrtName ne $PrevPrtName) && ($PrevPrtName ne $TmpBadBin2[$#TmpBadBin2]))
				{
					push (@TmpBadBin2, $PrevPrtName);
				}
			}
			$StartPrtName = '';
			$IncPrtNameFlag = 0;
			$StartPrtNameFlag = 0;			
			$DiffFlag=1;
		}
		$PrevPrtName = $PrtName;
	}
	print "Original @{$BadBin2{$SummaryError}}\n";
	print "Modified @TmpBadBin2\n";
	@TmpBadBin2 =();
}