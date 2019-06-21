
%Sum1;
open (FILE, "C:\\s9k\\L4220421.txt");
while (<FILE>)
{
	chomp;
	my ($Sum, $PrtName, $Fablot) = split (/\t/,$_);
	$Sum1{$Fablot} = $_;
	#print "$Sum1{$Fablot}\n";
}
close FILE;

open (NOFOUND, ">C:\\s9k\\notfound.txt");
open (FOUND, ">C:\\s9k\\found.txt");
open (NEW, "C:\\s9k\\L4220454T1.txt");
while (<NEW>)
{
	chomp;
	my ($PrtName, $Fablot) = split (/\t/,$_);
	my $Temp = $_;
	
	if ($Sum1{$Fablot} eq "")
	{
		print NOFOUND "$Temp\n";
		print "$Sum1{$Fablot}\n";
	}
	else
	{
		print FOUND "$Sum1{$Fablot}\t$Temp\n";
		print "$Sum1{$Fablot}\t$Temp\n";
	}

}
close NEW;
close NOFOUND;
close FOUND;

