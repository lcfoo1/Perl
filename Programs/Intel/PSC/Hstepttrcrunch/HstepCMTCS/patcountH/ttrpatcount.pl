#################################################################
# 								#
# 	Foo Lye Cheung				06 July 2005	#
# 	PDE DPG CPU Penang Malaysia				#
# 								#
# 	Count pattern .txt in pattern directory	sql script	#
# 								#
#################################################################
use strict;
use warnings;
use Cwd;
my $DirPat = getcwd;
my %Tests = ();

opendir (DIR, $DirPat) || die "Cant open $DirPat : $!\n";
my @Files = grep { /\.csv$/ && -f "$DirPat/$_" } readdir DIR;
closedir DIR;

foreach my $File (sort @Files)
{
	my ($Test, $Site) = split (/\_/, $File);

	open (IN, $File);
	while (<IN>)
	{
		my ($Pattern, $Count) = ("", 0);
		next if (/PATTERN/);
		($Pattern, $Count) = split (/\,/, $_);
		$Tests{$Test}{$Pattern} += $Count;
	}
	close IN;
	
}

foreach my $Dat (sort keys %Tests)
{
	my $TxtFile = $DirPat . "/" . $Dat . ".txt";
	print "Processing $TxtFile ...\n";
	open (OUT, ">$TxtFile") || die "Cant open out $TxtFile : $!\n";
	foreach my $Pat (sort {$Tests{$Dat}{$b}<=>$Tests{$Dat}{$a}} keys %{$Tests{$Dat}})
	{
		my $TxtFile = $DirPat . ".txt";
		print "$Tests{$Dat}{$Pat}\t$Pat\n";
		print OUT "$Tests{$Dat}{$Pat}\t$Pat\n";
		
	}
	close OUT;
	print "Finish generating $TxtFile ...\n";
}
