
my $File = "Lsspecmod.txt";
my $new = "Ldata.txt";

open (NEW, ">$new");
open (FILE, $File) || die "cant open $File :$!\n";
my $Line = "";
while (<FILE>)
{
	chomp;
	if(/^\S+\s+(\w+)\s+/)
	{
		$Line .= "-" . $1 . "/";	
	}

}
close FILE;
print NEW "$Line\n";
close NEW;
