#################################################################################################################
#														#
#	Foo Lye Cheung					PG PDE CPU (TMM)					#
#	03 Jan 2008												#
#	604-2536452												#
#														#
#	This script is to create Greenlane Directory								#
#														#
#	   													#
#	Rev 1.2													#
#	   													#
#	Changes:												#
#														#
#	11/16/2007												#
#	1. Added Supercede code directory structure for GEN code						#
#														#
#################################################################################################################
use strict;
use warnings;

use Cwd;
use Getopt::Std;
use File::Find;
use File::Copy;

# Globals
my $Debug = 0;
my @Files = ();
my $CurrentDirectory =  getcwd;
my $ConfigFile = $CurrentDirectory . '/../configuration.txt';
my ($RootDir, $Revision) = &ReadConfiguration();

die "Root directory and Revision token can't found in configuration.txt\n" if (($RootDir eq "") || ($Revision eq ""));

my $GreenlaneDetails = $RootDir . '/GEN/' . $Revision . '/Greenlane_Details';
my $GENNHMDir = $RootDir . '/GEN/' . $Revision . '/nhm';
my $OASISNHMDir = $RootDir . '/OASIS/' . $Revision . '/nhm';
my $SupercedeGENCodeDir = $RootDir . '/GEN/' . $Revision . '/Supercede_code';
my $SupercedeGENTempDir = $RootDir . '/GEN/' . $Revision . '/Supercede_templates';
my $SupercedeOASISCodeDir = $RootDir . '/OASIS/' . $Revision . '/Supercede_code';
my $SupercedeOASISTempDir = $RootDir . '/OASIS/' . $Revision . '/Supercede_templates';
my $NHMUFsDir = $RootDir . '/UFs/' . $Revision . '/nhm/src';

&Main();

# Main subroutine 
sub Main
{
	mkdir $GreenlaneDetails;
	mkdir $GENNHMDir;
	mkdir $OASISNHMDir;
	mkdir $SupercedeGENCodeDir;
	mkdir $SupercedeGENTempDir;
	mkdir $SupercedeOASISCodeDir;
	mkdir $SupercedeOASISTempDir;
	mkdir $NHMUFsDir; 
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
