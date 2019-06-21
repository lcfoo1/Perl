# To convert GLN PG1.23.0
use Cwd;
my $Dir = getcwd;

my $Org = $Dir . "/original/";
my $Mod = $Dir . "/modified/";

my $MapReplaceFile = 'Replace_parameter.txt';
my %Map = ();
open (REPLACEFILE, $MapReplaceFile) || die "Cant open $MapReplaceFile : $!\n";
{
	while (<REPLACEFILE>)
	{
		chomp;
		next if (/#/);
		my @Lines = split (/\s+/, $_);
		$Map{$Lines[0]} = $Lines[1];
	}
}
close REPLACEFILE;

chdir $Org || die "Can't open $Org : $!\n";
foreach my $TP (<*>)
{
	my $OrgFile = $Org . $TP;
	my $ModFile = $Mod . $TP;
	open (MOD, ">$ModFile") || die "Cant open $ModFile : $!\n";
	open (ORG, $OrgFile) || die "Cant open $OrgFile : $!\n";
	while(<ORG>)
	{
		chomp;
		foreach my $Reference (keys %Map)
		{

			s/$Reference/$Map{$Reference}/g;
		}
		print MOD "$_\n";
	}
	close ORG;
	close MOD;
}
