use strict;
use warnings;

require "C:/Perl/Programs/Common.pl";

my $dbILTS = &OpenILTS;
&test();
$dbILTS->Close();


sub test
{
	my %Temp;
	my $sql = "SELECT * FROM vb_cib_lsp_genealogy";	
	
	if($dbILTS->Sql($sql))
	{
		&ifSQL($dbILTS, $sql);
	}
	else
	{
		open (FILE, ">ILTS.txt");
		while($dbILTS->FetchRow())
		{
			#print FILE "Start Now\n";
			my %Temp = $dbILTS->DataHash();
			foreach my $Key(keys %Temp)
			{
				print FILE "$Key = $Temp{$Key}\t";
			}
			print FILE "\n";
		}
		close FILE;
	}
}
