#################################################################################
#                                                                               #
#        Foo Lye Cheung                             PDE DPG 		        #
#        inet 253 6452                              Penang                      #
#                                                                               #
#        DESCRIPTION                                                            #
#        Change username and password for Task Scheduler			#
#                                                                               #
#        NOTES  	                                                        #
#        Run by WSMonitor.job                                           	#
#        	                                                               	#
#        RELEASES                                                               #
#        11/28/2006  rev0.0 - Server main code release                          #
#                                                                               #
#################################################################################
use warnings;
use strict;
use Cwd;
use Win32::TaskScheduler;

my @Files = ();
my ($Domain, $Idsid, $Login, $Password) = ("", "", "", "");
my $CurrentPath = getcwd;
my $ConfigFile = $CurrentPath . "\\" . 'workstation.cfg';
my $SetupFile = $CurrentPath . "\\" . 'config.cfg';
my $ErrorFile = $CurrentPath . "\\" . 'Error.log';


#Main program start here
open (ERROR, ">$ErrorFile") or die "Cant open error file $ErrorFile : $!\n";
&SetupVars();
&MainProgram();

sub MainProgram
{
	my $FailPingFlag = 0;
	
	open (CONFIG, $ConfigFile) || die "Cant open $ConfigFile : $!\n";
	while (<CONFIG>)
	{
		chomp;
		next if (/#/ig);		
		my ($Server, $Team, $Setup) = split (/\s+/, $_);		
	
		my $IP = $Server;	
		my @Pings = qx/ping -n 1 $Server/;
		
		foreach my $Ping (@Pings)
		{
			chomp($Ping);
			if (($Ping =~ /Request\s*timed\s*out\./ig) || ($Ping =~ /could\s*not\s*find\s*host/ig))
			{
				print ERROR "ERROR: Fail ping server - $Server\n";
				print "ERROR: Fail ping server - $Server\n";
				$FailPingFlag = 1;
			}
			else
			{
				#Reply from 172.30.129.220: bytes=32 time<1ms TTL=127
				if ($Ping =~ /(\d*\.\d*\.\d*\.\d*)/)
				{
					$IP = $1;
					last;
				}
			}
		}
		
		if ($FailPingFlag)
		{
			$FailPingFlag = 0;		
			next;
		}	
	
		my $ServerFile = "\\\\" . $IP . "\\c\$\\" . "WINNT\\Tasks\\WSMonitor.job";
		if (-e $ServerFile)
		{
			print "Getting $ServerFile\n";		
			push (@Files, $ServerFile);
		}
		else
		{	
			$ServerFile = "\\\\" . $IP . "\\c\$\\" . "WINDOWS\\Tasks\\WSMonitor_Window.job";
			if (-e $ServerFile)
			{						
				print "Getting $ServerFile\n";
				push (@Files, $ServerFile);
			}
			else
			{
				print ERROR "File not exist at $Server\n";
				print "File not exist at $Server\n";
			}
		}		
	}		
	close CONFIG;
	
	&ActiveTask();
}

# Subroutine to change username and password for task scheduler
sub ActiveTask
{	
	my $scheduler = Win32::TaskScheduler->New();
	foreach my $Task (@Files)
	{
		next unless $Task =~ /\.job$/;		
		$scheduler->Activate("$Task");		
		my $runasuser=$scheduler->GetAccountInformation();		
		die "Cannot set username\n" if (! $scheduler->SetAccountInformation($Login, $Password));
		die "Cannot save changes username\n" if (! $scheduler->Save());
		print "Successful $Task is changed\n";
	}
	$scheduler->End();
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
		else
		{			
			print "Invalid setup format - $SetupFile\n";
			print ERROR "Invalid setup format - $SetupFile\n";
		}	
	}
	$Login = $Domain . '\\' . $Idsid;
	close SETUP;
}

close ERROR;
