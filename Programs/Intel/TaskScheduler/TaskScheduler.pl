#################################################################################
#                                                                               #
#        Foo Lye Cheung                             PDE DPG 		        #
#        inet 253 6452                              Penang                      #
#                                                                               #
#        DESCRIPTION                                                            #
#        Change username and password for Task Scheduler			#
#                                                                               #
#        RELEASES                                                               #
#        11/28/2006  rev0.0 - Server main code release                          #
#                                                                               #
#################################################################################
use lib './lib';
use warnings;
use strict;
use Cwd;
use Win32::TaskScheduler;

my ($Domain, $Idsid, $Login, $Password, $Server, $CurTask) = ("", "", "", "");
my $CurrentPath = getcwd;
my $SetupFile = $CurrentPath . "\\" . 'setup.cfg';
my $FoundChange = 0;

#Main program start here
&SetupVars();
&ActiveTask();

# Subroutine to change username and password for task Scheduler
sub ActiveTask
{	
	my $Scheduler = Win32::TaskScheduler->New();
	$Scheduler->SetTargetComputer("\\\\$Server");

	foreach my $Task ($Scheduler->Enum()) 
	{
		$Scheduler->Activate($Task);
		if ($Task =~ /^${CurTask}.job$/i)
		{
			$FoundChange = 1;
			my $RunAsUser = $Scheduler->GetAccountInformation();
			die "Cannot set username\n" if (! $Scheduler->SetAccountInformation($Login, $Password));
			if (! $Scheduler->Save())
			{
				print "Cannot save $Task\n";
			}
			else
			{
				print "Successful $Task is changed\n";
			}
		}
	}
	$Scheduler->End();

	if (!$FoundChange)
	{
		print "Do not match any task defined in config file...\n";
	}
}

# Get variables from input file
sub SetupVars
{
	open (SETUP, $SetupFile) || die "Cant open setup file $SetupFile :$!\n";
	while (<SETUP>)
	{
		chomp;
		next if (/#/ig);
		s/\s*//g;
	
		if (/Domain\=(\w+)/i)
		{
			$Domain = $1;
		}
		elsif (/IDSID\=(\w+)/i)
		{
			$Idsid = $1;
		}
		elsif (/Password\=(\S+)/i)
		{
			$Password = $1;
		}
		elsif (/Server\=(\S+)/i)
		{
			$Server = $1;
		}
		elsif (/Task\=(\S+)/i)
		{
			$CurTask = $1;
		}
		else
		{			
			print "Invalid setup format - $SetupFile\n";
		}	
	}
	$Login = $Domain . '\\' . $Idsid;
	close SETUP;
}
