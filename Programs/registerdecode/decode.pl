use warnings;
use strict;
##########################################################################
# This script develop to reverse value from UserDR to input value.
# Developer: Lye Cheung Foo
# Rev 0.0
# 16 July 2018
##########################################################################
print "Please enter UserDR value: ";
my $JtagHex = <STDIN>;
print "UserDR entered: $JtagHex\n";
chomp($JtagHex);

#$JtagHex = "641836000000000000000000";
#$JtagHex = "3FFFFFFF80000000";
my $PadJtagHex = sprintf("%032s", $JtagHex);
for (my $i=0; $i < length($PadJtagHex); $i++)
{
	my $Str = substr ($PadJtagHex, $i, 8);
	#print "$i == Str: $Str\n";
	print "UserDR (" . $i/8 . ") [" . (($i+8) * 4 - 1) . "-" . $i * 4 . "] = $Str\n";
	$i=$i+7; 
}