

%MySum;
open (FILE, "tdata.txt") || die "Cannt open file : $!\n";
while (<FILE>)
{
	s/"//g;
	($Data1, $Data2, $Data3) = split (/File:/, $_);
	($Data4, $Fablot) = ($1, $2) if ($Data3 =~ /(.*)(F.*)/);
	my ($Sum, $PrtName, $Bin) = split (/\,/, $Data2);
	$MySum{$PrtName} = "File: $Sum $PrtName $Bin\tFile: $Data4\t$Fablot\n";
	
}
close FILE;

foreach $Line (sort keys %MySum)
{
	open (LCFOO, ">>lcfoo1.txt");
	print LCFOO "$MySum{$Line}\n";
	close LCFOO;
	
}
