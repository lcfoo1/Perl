

my @Array = ( 1,2,4,3,8);
&selection_sort(\@Array);

sub selection_sort 
{
	my $array = shift;
	my $i; # The starting index of a minimum-finding scan.
	my $j; # The running index of a minimum-finding scan.
	for ( $i = 0; $i < $#$array ; $i++ ) 
	{
		my $m = $i; # The index of the minimum element.
		my $x = $array->[ $m ], # The minimum value.
		for ($j=$i+1; $j<@$array; $j++) 
		{
			($m, $x) = ($j, $array->[$j]) # Update minimum.
			if $array->[$j] lt $x;
		}
		
		# Swap if needed.
		@$array[ $m, $i ] = @$array[ $i, $m ] unless $m == $i;
	}
}
