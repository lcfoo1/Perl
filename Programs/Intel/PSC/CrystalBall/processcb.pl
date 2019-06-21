#################################################################
# 								#
# 	Foo Lye Cheung				05 July 2005	#
# 	PDE DPG CPU Penang Malaysia				#
# 								#
# 	Crunch data using Crystal Ball script			#
# 								#
#################################################################
use strict;
use warnings;
use File::Find;
my $CBProg = 'C:/users/lfoo1/CrystalBall/Production/cbcli.exe ';
my $DataDir = 'C:/Intel/Perl/Programs/CrystalBall/cbscript';
my @CBFiles = ();

find (\&GetFiles, $DataDir);
&CBNow();

sub GetFiles
{
	push (@CBFiles, $File::Find::name) if (-f $File::Find::name);
}

sub CBNow
{
	foreach my $CBFile (@CBFiles)
	{
		if ($CBFile =~ /\/(\w+).acs$/)
		{
			my $Filename = $1;
			my $ScriptArg = "script=${CBFile} ";
			my $OutputFile = $DataDir . "/" .$Filename . ".csv";
			my $OutputArg = "/output=${OutputFile} /format=csv";

			print "Processing $CBFile using Crystal Ball\n";
			qx/$CBProg $ScriptArg $OutputArg/;
			print "Finish processing $CBFile ...\n";

		}
		else
		{
			#Dont do anything here..:)
		}
	}
}
