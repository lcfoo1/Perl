
my @Plists = "";
my $File = 'cat_pats.plist';
#my $File = 'CC_pats.plist';
my $Out = '>' . $File . '.txt';
my $FRC = '>' . $File . '_frc.txt';
my $CMP = '>' . $File . '_cmp.txt';
open (FILE, $File) || die "Cant open $File : $!\n";
while (<FILE>)
{
	chomp;
	if (/GlobalPList\s+(\S+)\s+/)
	{
		push (@Plists, $1);
	}
}
close FILE;

open (FRCOUT, $FRC) || die "Cant open $FRC : $!\n";
open (CMPOUT, $CMP) || die "Cant open $CMP : $!\n";
open (OUT, $Out) || die "Cant open $Out : $!\n";
foreach my $Plist (sort @Plists)
{
	print OUT "$Plist\n";
	if ($Plist =~ /(frc|FRC)/)
	{
		print FRCOUT "PLIST $Plist\n";
	}
	elsif ($Plist =~ /(full|bf|xship|gv|sym)/)
	{
		print CMPOUT "PLIST $Plist\n";
	}
}
close OUT;
close CMPOUT;
close FRCOUT;
