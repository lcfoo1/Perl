
use strict;
use warnings;
require 'commars.pl';

my @LotList = ();
&GetLotList();
my $dbMARS = &OpenMARS();
&GetFabrun();
$dbMARS->Close();

sub GetLotList
{
	my $File = 'lot.txt';

	open (LOTLIST, $File) || die "Cannt open $File : $!";
	while (<LOTLIST>)
	{
		push (@LotList, $_);
	}
	close LOTLIST;

}

sub GetFabrun
{
	my %Temp;
	my $OutputFile = "FabLotList.xls";

	# Print out all the Fabrun for lots to a file
	open (FABRUN, ">$OutputFile") || die "Cann't open $OutputFile : $!\n";
	foreach my $Lot (@LotList)
	{
		chomp($Lot);
		my $sql = "SELECT DiSTINCT ATTRIBUTE_VALUE FROM A11_PROD_5.F_LOTATTRIBUTE WHERE LOT = '$Lot' " .
		"AND ATTRIBUTE_NUMBER = 711";
		#print "$sql\n";

		if($dbMARS->Sql($sql))
		{
			&ifSQL($dbMARS, $sql);
		}
		else
		{
			while($dbMARS->FetchRow())
			{
				%Temp = $dbMARS->DataHash();
			}
		}
		
		no warnings;
		$Temp{ATTRIBUTE_VALUE} =~ s/^$/NULL/;
		print FABRUN "$Temp{'ATTRIBUTE_VALUE'}\t$Lot\n";
		print "$Lot :: $Temp{'ATTRIBUTE_VALUE'}\n";
	}
	close FABRUN;
}


