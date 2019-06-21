
use strict;
use warnings;

my @Temp = split (/[-,]/, "1-10,20");

foreach my $List (@Temp)
{
	print "$List ";
}

foreach my $Key (keys %ENV)
{
	#print "$Key :: $ENV{$Key}\n";
}

foreach my $Key (keys %INC)
{
	#print "$Key :: $INC{$Key}\n";
}

