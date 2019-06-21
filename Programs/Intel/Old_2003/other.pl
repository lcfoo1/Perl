
use strict;
use warnings;
my @Dirs= ('C:/pattern/bfmax',
'C:/pattern/bfmin',
'C:/pattern/bfnom',
'C:/pattern/bfsigen',
'C:/pattern/gvhot',
'C:/pattern/sbft_sigon',
'C:/pattern/sbftfmax',
'C:/pattern/sbftgv',
'C:/pattern/sbftmax',
'C:/pattern/sbftmin',
'C:/pattern/scanatpg',
'C:/pattern/xshipgv',
'C:/pattern/xshipmin');

foreach my $Dir (@Dirs)
{

my $File1 = $Dir . ".txt";
my $File2 = $Dir . ".csv";
my %Pats = ();
chdir $Dir;

foreach my $File (<*.txt>)
{
	open (FILE, $File);

	while (<FILE>)
	{
		chomp;
		my ($Count, $Pat) = split (/\s+/, $_);
		$Pats{$Pat} += $Count;
		#print "$Pat :: $Pats{$Pat} = $Count\n";;
	}
	close FILE;
}

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
