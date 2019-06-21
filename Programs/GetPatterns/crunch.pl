
use File::Find;
my @Dirs = ('C:\Development\Teradyne\Programming\Perl\Programs\GetPatterns');
my @Patterns = ();
my $TI = 'TI_Functional_mod.txt';
open (TI, $TI) || die "Can't open $TI : $!\n";
while (<TI>)
{
	chomp;
	#print "$_\n";
	if (/ExportedFiles.*\\(\w+)\.pat/ig)
	{
		print "$1\n";
		push (@Patterns, $1);
	}
}
close TI;


find(\&wanted, @Dirs);
sub wanted 
{
	
}

