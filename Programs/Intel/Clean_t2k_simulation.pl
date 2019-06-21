#################################################################################################################
#														#
#	Foo Lye Cheung					PG PDE CPU (TMM)					#
#	14 January 2010												#
#	604-2536452												#
#														#
#	This script is to clean all hang simulation files from previous t2k files				#
#														#
#	Rev0.0													#
#														#
#################################################################################################################
use strict;
use warnings;
use File::Find;

# Globals
my $Root = 'C:\T2000\InstallSets';
&Main();

# Main subroutine 
sub Main
{
	finddepth(\&DeleteOldT2kSimFiles, $Root);
}

# Get t2k offline temperorary simulation files
sub DeleteOldT2kSimFiles
{
	if ((-f $File::Find::name) && ($File::Find::name =~ /\/CMT_\S+\/tmp\//i))
	{
		my $File = $File::Find::name;
		$File =~ s/\\/\//g;
		unlink $File || die "Can't delete file $File : $!\n";
		print "Deleting $File\n";
	}
}

