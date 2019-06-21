my $File = "switchsignature_cmp.txt";
my $Die1 = ">switchsignature_cmp_die1.txt";
my $Die2 = ">switchsignature_cmp_die2.txt";

open (DIE1, $Die1);
open (DIE2, $Die2);
open (IN, $File);
while (<IN>)
{
	chomp;
	if (/_0_/)
	{
		print DIE1 "$_\n";

	}
	elsif (/_1_/)
	{
		print DIE2 "$_\n";
	}
	else
	{
		print DIE1 "$_\n";
		print DIE2 "$_\n";
	}
}
close IN;
close DIE1;
close DIE2;
