
$ItuffDir = "C:\\Perl\\programs\\";
opendir (DIR,$ItuffDir ) || die "Cannt open $!\n";
@ItuffFiles = readdir(DIR);
closedir DIR;

foreach $File (@ItuffFiles)
{
	print "$File\n";
}
