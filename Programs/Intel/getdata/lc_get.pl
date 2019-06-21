!#/usr/intel/pkgs/perl/5.8.5/bin/perl
my $File = 'lots.txt';
open (FILE, $File) || die "Cant open $File : $!\n";
while (<FILE>)
{
	print "$_\n";
}
close FILE;
