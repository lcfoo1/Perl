# Check from table
# get Fab from Oracle
#
my %MarketAndL3;
open (L3TABLE, "Lcfoo_table.txt") || die "Cannt open : $!\n";
while (<L3TABLE>)
{
	my ($MName, $L3Name) = split (/\,/, $_);
	$MarketAndL3{$MName} = $L3Name;
}
close L3TABLE;


