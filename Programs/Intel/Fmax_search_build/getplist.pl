
my $File = 'CKT_search_fmax_config_input_rev0.txt';
my $OutFile = 'CKT_search.csv';
my ($Search, $Common, $Plist, $Setup) = ();

open (OUT, ">$OutFile") || die "Cant open $OutFile : $!\n";
open (FILE, $File) || die "Cant open $File : $!\n";
while (<FILE>)
{
	if (/IND_SEARCH_SET\s+(\S+)/)
	{
		$Search = $1;	
	}
	if (/patlist\s+\"(\S+)\"/)
	{
		$Plist = $1;
	}
	if (/common_set_name\s+\"(\S+)\"/)
	{
		$Common = $1;
	}
	if (/pre_searchset_userfunc\s+\"(\S+)\"/)
	{
		$Setup = $1;
	}
	if (/END_IND_SEARCH_SET/)
	{
		print OUT "$Search,$Plist,$Common,$Setup\n";
		($Search,$Plist,$Common,$Setup) = ();

	}
}
close FILE;
close OUT;
