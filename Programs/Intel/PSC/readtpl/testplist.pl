
open (OUT, ">>Test_plist.csv") || die "Cant open test_plist.txt : $!\n";
open (IN, "Psc.tpl") || die "Cant open psc.tpl : $!\n";
while (<IN>)
{
	if (/Test\s+\w+\s+(\w+)/)
	{
		my $Test = $1;
		do
		{
			$_ = <IN>;
			chomp;
			if (/patlist.*\"(\S+)\"\;$/)
			{
				my $patlist = $1;
				print "$Test,$patlist\n";
				print OUT "$Test,$patlist\n";
			}

		} while ( $_ !~ /\}/);
	}
}
close IN;
close OUT;
