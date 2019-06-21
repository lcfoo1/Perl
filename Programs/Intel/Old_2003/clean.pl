#########################################################################
#																		#
#	SC Data Broker 														#
#																		#
#########################################################################
#									#
#	Foo Lye Cheung		PDQRE Sort Automation			#
#	06/24/2004							#
#									#
#	Clean.pl is to clean old files at data broker server which	#
#	do not require the scheduler task to run daily.			#
#	This script is to set to run weekly to reduce CPU checking	#
#	power which will slow down the CPU.				#
#	DataBrokerMon.exe is used if data broker require clean files	#
#	daily.								#
#									#
#	NOTE:								#
#	Require clean.ini which contain the configuration information	#
#	- directory to clean and how many day old files to clean	#
#									#
#	Rev 1.0								#
#									#
#########################################################################

use strict;
use warnings;

#my $ConfigFile ="E:\\databroker\\bin\\Clean.ini";
my $ConfigFile ="C:\\Perl\\Programs\\Clean.ini";
my %DirToClean;
my @DayOldExt;

open (CONFIG, $ConfigFile) or die "Cannt open $ConfigFile: $!\n";
while(<CONFIG>)
{
	chomp;
	my ($Dir, $DayOld, $Ext) = split(/\,/, $_);
	push (@{$DirToClean{$Dir}}, $DayOld, $Ext);
}
close CONFIG;

foreach my $Dir (sort keys %DirToClean)
{
	print "Cleaning files $Dir ...\n";	
	my @Files = glob ("$Dir\\*");
	foreach my $File (@Files)
	{
		next if (-M $File <= $DirToClean{$Dir}[0]);
		next unless ($File =~ /$DirToClean{$Dir}[1]$/);
		unlink "$File" or die "Cannt delete $File: $!\n";
		print "File deleted: $File\n";
	}
}

