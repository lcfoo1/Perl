
use strict;
use warnings;
my $DirPat = 'C:/pattern'; 
chdir $DirPat || die "Cant change $DirPat : $!\n";

foreach my $Dir (<*>)
{
	next unless (-d $Dir);
	my $File1 = $Dir . ".txt";
	my $File2 = $Dir . ".csv";
	my %Pats = ();
	chdir $Dir || die "Cant change $Dir : $!\n";;

	foreach my $File (<*.txt>)
	{
		open (FILE, $File);
	
		while (<FILE>)
		{
			chomp;
			my ($Count, $Pat) = split (/\s+/, $_);
			$Pats{$Pat} += $Count;
		}
		close FILE;
	}

	chdir $DirPat || die "Cant change $DirPat : $!\n";
	open (OUT, ">$File1");
	open (OUT2, ">$File2");
	print OUT2 "Total,Pattern,Pareto(DPM)\n";
	foreach my $Key (sort {$Pats{$b}<=>$Pats{$a}} keys %Pats)
	{
		my $Pareto = $Pats{$Key} * 7;
		print OUT "$Pats{$Key}\t$Key\n";
		print OUT2 "$Pats{$Key},$Key,$Pareto\n";
	}
	close OUT;
	close OUT2;
}
