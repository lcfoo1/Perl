
%refpat = ();
%refpat2 = ();
my $File = 'scanatpg.txt';
my $refLstep = 'fnalpg.txt.csv';
open (FILE, $File);
while (<FILE>)
{
	chomp;
	my ($count, $pat) = split (/\s+/,$_);
	$refpat{$pat} = $count;
}
close FILE;

open (FILE2, $refLstep);
while (<FILE2>)
{
	chomp;
	my $pat = "\U$_\E";
	$refpat2{$pat} = 0;
}
close FILE2;




my $LstepMain = 'lpatonly.csv';
my $LstepMain1 = 'nlpatonly.csv';
my $TTRFlow = 'rpatonly.csv';
my $TTRFlow1 = 'nrpatonly.csv';
my $LstepSame = 'samepat.csv';
my $LstepSame1 = 'nsamepat.csv';


open (OUT3, ">$LstepMain1") || die "cant\n";
open (IN3, $LstepMain) || die "cant\n";
while (<IN3>)
{
	chomp;
	s/(\w+)(,1)$/$1/;
	my $tmp = $_;
	
	foreach my $pat1 (keys %refpat2)
	{
		if ($pat1 =~ /$tmp/)
		{
			print OUT3 "$tmp,$pat1,$refpat2{$pat1}\n";
			#print  "$pat1,$refpat{$pat1}\n";

		}
	}

}
close IN3;
close OUT3;





open (OUT1, ">$TTRFlow1") || die "cant\n";
open (IN1, $TTRFlow) || die "cant\n";
while (<IN1>)
{
	chomp;
	s/(\w+)(,1)$/$1/;
	my $tmp = $_;
	
	foreach my $pat1 (keys %refpat)
	{
		if ($pat1 =~ /$tmp/)
		{
			print OUT1 "$tmp,$pat1,$refpat{$pat1}\n";
			#print  "$pat1,$refpat{$pat1}\n";
		}
	}

}
close IN1;
close OUT1;

open (OUT2, ">$LstepSame1") || die "cant\n";
open (IN2, $LstepSame) || die "cant\n";
while (<IN2>)
{
	chomp;
	s/(\w+)(,1,\w+,1)$/$1/;
	my $tmp = $_;
	
	foreach my $pat1 (keys %refpat)
	{
		if ($pat1 =~ /$tmp/)
		{
			print OUT2 "$tmp,$pat1,$refpat{$pat1}\n";

		}
	}

}
close IN2;
close OUT2;

