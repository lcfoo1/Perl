#################################################################################################################
#														#
#	Foo Lye Cheung					PG PDE CPU (TMM)					#
#	24 December 2009											#
#	604-2536452												#
#														#
#	This script is to clean all Greenlane archive directory							#
#														#
#	Rev0.0													#
#														#
#################################################################################################################
use strict;
use warnings;

use Getopt::Std;
use File::Find;
use File::Copy;

# Globals
my $Debug = 0;
my @ReleaseFiles = ();
my @ReleaseDirectories = ();
my $Root = 'C:\intel\tpapps\Archive';

no warnings;
if ($ARGV[0] eq "")
{
	$Root = 'C:\intel\tpapps\Archive';
	print "Default Greenlane Archive = $Root\n";

}
else
{
	$Root = $ARGV[0];
	chomp ($Root);
	if (-e $Root)
	{
		print "Archive directory = $Root\n";
	}
	else
	{
		print "Invalid archive directory = $Root\n";
	}
}

if (-e $Root)
{
	&Main();
}
else
{
	print "$Root is removed when cleaning.\n";
}

# Main subroutine 
sub Main
{
	finddepth(\&GetReleaseDirAndFiles, $Root);
	foreach my $ReleaseFile (@ReleaseFiles)
	{
		if (-e $ReleaseFile)
		{
			#print "Deleting $ReleaseFile\n";
			unlink $ReleaseFile || die "Cant delete file $ReleaseFile : $!\n";
		}
	}
	
	foreach my $ReleaseDirectory (@ReleaseDirectories)
	{
		if (-e $ReleaseDirectory)
		{
			#print "Removing $ReleaseDirectory\n";
			rmdir $ReleaseDirectory || die "Cant delete directory $ReleaseDirectory : $!\n";
		}
	}

	#print "Create $Root...\n";
	mkdir $Root || die "Cant create directory $Root : $!\n";

	print "Finish clean $Root...\n";

}

# Get all the release files and directories
sub GetReleaseDirAndFiles
{
	if (-f $File::Find::name)
	{
		my $File = $File::Find::name;
		$File =~ s/\\/\//g;
		print "Found $File\n" if ($Debug == 1);
		push (@ReleaseFiles, $File);
	}

	if (-d $File::Find::name)
	{
		my $Dir = $File::Find::name;
		$Dir =~ s/\\/\//g;
		print "Found $Dir\n" if ($Debug == 1);

		push (@ReleaseDirectories, $Dir);
	}
}

