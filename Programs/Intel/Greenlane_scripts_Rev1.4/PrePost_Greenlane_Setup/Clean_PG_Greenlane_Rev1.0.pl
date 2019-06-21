#################################################################################################################
#														#
#	Foo Lye Cheung					PG PDE CPU (TMM)					#
#	31 June 2007												#
#	604-2536452												#
#														#
#	This script is to clean all CorTeX release directory							#
#														#
#	Rev 1.0													#
#														#
#	Changes:												#
#	09/08/2007												#
#	1. Added new nhm Evergreen UF directory to clean $EUFsDir2 and $EUFsDir3				#
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
my $ConfigFile = 'configuration.txt';
my ($RootDir, $Revision) = &ReadConfiguration();

die "Root directory and Revision token can't found in configuration.txt\n" if (($RootDir eq "") || ($Revision eq ""));

my $GENDir = $RootDir . '/GEN/' . $Revision;
my $OASISDir = $RootDir . '/OASIS/' . $Revision;
my $UFsDir = $RootDir . '/UFs/' . $Revision . '/src';
my $EGENDir = $RootDir . '/GEN/' . $Revision . '/nhm/src';
my $EOASISDir = $RootDir . '/OASIS/' . $Revision . '/nhm/src';
my $EUFsDir1 = $RootDir . '/UFs/' . $Revision . '/nhm/CPD-UF';
my $EUFsDir2 = $RootDir . '/UFs/' . $Revision . '/nhm/nhm-UF';
my $EUFsDir3 = $RootDir . '/UFs/' . $Revision . '/nhm/hwi-ext';
my $CKTMUFsDir = $RootDir . '/UFs/' . $Revision . '/cktm/src';

$GENDir =~ s/\/\//\//g;
$OASISDir =~ s/\/\//\//g;
$UFsDir =~ s/\/\//\//g;
$EGENDir =~ s/\/\//\//g;
$EOASISDir =~ s/\/\//\//g;
$EUFsDir1 =~ s/\/\//\//g;
$EUFsDir2 =~ s/\/\//\//g;
$EUFsDir3 =~ s/\/\//\//g;

&Main();

# Main subroutine 
sub Main
{
	finddepth(\&GetReleaseDirAndFiles, $GENDir, $OASISDir, $UFsDir, $EGENDir, $EOASISDir, $EUFsDir1, $EUFsDir2, $EUFsDir3, $CKTMUFsDir);

	open (LOG, ">logs\\Clean_PG_CorTeX.log") || die "Cant log Clean_PG_CorTeX.log : $!\n";
	foreach my $ReleaseFile (@ReleaseFiles)
	{
		print LOG "Deleting $ReleaseFile\n";
		unlink $ReleaseFile || die "Cant delete file $ReleaseFile : $!\n";
	}
	
	foreach my $ReleaseDirectory (@ReleaseDirectories)
	{
		print LOG "Removing $ReleaseDirectory\n";
		rmdir $ReleaseDirectory || die "Cant delete directory $ReleaseDirectory : $!\n";
	}
	close LOG;
}

# Get all the release files and directories
sub GetReleaseDirAndFiles
{
	if ((-f $File::Find::name) && (($File::Find::name =~ /$Revision\/\w*templates\/\w*release\//i) || ($File::Find::name =~ /$Revision\/\w*code\/\w*release\//i) || ($File::Find::name =~ /$Revision\/\w*src\/\w*release\//i) || ($File::Find::name =~ /$Revision\/nhm\/src\/\w*templates\/\w*release\//i) || ($File::Find::name =~ /$Revision\/nhm\/src\/\w*code\/\w*release\//i) || ($File::Find::name =~ /$Revision\/nhm\/\w*src\/\w*release\//i) || ($File::Find::name =~ /$Revision\/bin\/\w*DUTModel\/\w*release\//i) || ($File::Find::name =~ /$Revision\/bin\/\w*OASIS_BaseTest\/\w*release\//i) || ($File::Find::name =~ /$Revision\/nhm\/nhm-uf\/\w*release\//i) || ($File::Find::name =~ /$Revision\/nhm\/CPD-UF\/\w*release\//i) || ($File::Find::name =~ /$Revision\/nhm\/hwi-ext\/\w*release\//i) || ($File::Find::name =~ /$Revision\/cktm\/src\/\w*release\//i) || ($File::Find::name =~ /.vcproj.\S+user/i) || ($File::Find::name =~ /\S+.ncb/i)))
	{
		my $File = $File::Find::name;
		$File =~ s/\\/\//g;
		print "Found $File\n" if ($Debug == 1);
		push (@ReleaseFiles, $File);
	}

	if ((-d $File::Find::name) && (($File::Find::name =~ /$Revision\/\w*templates\/\w*release/i) || ($File::Find::name =~ /$Revision\/\w*code\/\w*release/i) || ($File::Find::name =~ /$Revision\/\w*src\/\w*release/i) || ($File::Find::name =~ /$Revision\/nhm\/src\/\w*templates\/\w*release/i) || ($File::Find::name =~ /$Revision\/nhm\/src\/\w*code\/\w*release/i) || ($File::Find::name =~ /$Revision\/nhm\/\w*src\/\w*release/i) || ($File::Find::name =~ /$Revision\/bin\/\w*DUTModel\/\w*release/i) || ($File::Find::name =~ /$Revision\/bin\/\w*OASIS_BaseTest\/\w*release/i) || ($File::Find::name =~ /$Revision\/nhm\/nhm-uf\/\w*release/i) || ($File::Find::name =~ /$Revision\/nhm\/CPD-UF\/\w*release/i) || ($File::Find::name =~ /$Revision\/nhm\/hwi-ext\/\w*release/i) || ($File::Find::name =~ /$Revision\/cktm\/src\/\w*release/i)))
	{
		my $Dir = $File::Find::name;
		$Dir =~ s/\\/\//g;
		print "Found $Dir\n" if ($Debug == 1);
		push (@ReleaseDirectories, $Dir);
	}
}


# Read configuration file
sub ReadConfiguration
{
	my ($RootDir, $Revision) = ("", "");

	open (CONFIG, $ConfigFile) || die "Can't open $ConfigFile : $!\n";
	while (<CONFIG>)
	{
		chomp;
		s/\s*//g;
		next if (/#/);

		if (/Root=(\S+)/i)
		{
			$RootDir = $1;
			$RootDir =~ s/\\/\//g;
		}
		elsif (/Revision=(\S+)/i)
		{
			$Revision = $1;
		}
	}
	close CONFIG;

	return ($RootDir, $Revision);
}
