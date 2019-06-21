#################################################################################
#                                                                               #
#        Foo Lye Cheung                             PDE DPG 		        #
#        inet 253 6452                              Penang                      #
#                                                                               #
#        DESCRIPTION                                                            #
#        Rewrite check the workstation usage and status due to WinXP SP2	#
#        Bug fix for ping nreachable which will kill the script			#
#                                                                               #
#        NOTES  	                                                        #
#        Run by WSMonitor.exe                                           	#
#        	                                                               	#
#        RELEASES                                                               #
#        11/28/2006  rev0.0 - Server main code release                          #
#                                                                               #
#################################################################################
use Win32::OLE;
use Data::Dumper;
use Win32::Process::Info;
use File::Copy;
use Cwd;
use strict;
use warnings;
$| = 1;

my $Debug = 0;
my (@Files) = ();

my $CurrentPath = getcwd;
my $ConfigFile = $CurrentPath . "\\" . 'workstation.cfg';
my $TmpSummary = $CurrentPath . "\\" . "SummaryWS.tmp";
my $FinalSummary = $CurrentPath . "\\" . "SummaryWS.txt";
my $TempLogDir = $CurrentPath . "\\"  . "templog\\" ;

&MainProgram();

sub MainProgram
{
	my $FailPingFlag = 0;	
	
	open (CONFIG, $ConfigFile) or die "Cant open $ConfigFile : $!\n";
	while (<CONFIG>)
	{
		next if (/#/ig);
		chomp;
		my ($Server, $Team, $Setup) = split (/\s+/, $_);
		next if ($Setup =~ /NO/ig);
	
		my $IP = $Server;	
	
		my @Pings = qx/ping -n 1 $Server/;
		
		foreach my $Ping (@Pings)
		{
			chomp($Ping);
			if (($Ping =~ /Request\s*timed\s*out\./ig) || ($Ping =~ /could\s*not\s*find\s*host/ig))
			{
				print "ERROR: Fail ping server - $Server\n";
				my $TempLogFile = $TempLogDir . $Server . ".txt";
				open (DOWN, ">$TempLogFile") || die "Cant open $TempLogFile : $!\n";
				print DOWN "Status=Down\n";
				print DOWN "Server=$Server\n";
				print DOWN "Team=$Team\n";				
				close DOWN;
								
				push (@Files, $TempLogFile);
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
	
		#\\pgxpw4057\c$\WINNT\WSMonitor
		my $ServerFile = "\\\\" . $IP . "\\c\$\\" . "WINNT\\WSMonitor\\" . $Server . ".txt";
		
		if (-e $ServerFile)
		{
			my $TempLogFile = $TempLogDir . $Server . ".txt";
			print "Getting $ServerFile\n";	
			copy($ServerFile, $TempLogFile);
			push (@Files, $TempLogFile);
		}
		else
		{
			#\\pgxpvmup104\c$\WINDOWS\WSMonitor
			my $TempLogFile = $TempLogDir . $Server . ".txt";
			$ServerFile = "\\\\" . $IP . "\\c\$\\" . "WINDOWS\\WSMonitor\\" . $Server . ".txt";
			if (-e $ServerFile)
			{						
				print "Getting $ServerFile\n";	
				copy($ServerFile, $TempLogFile) || die "Cant copy $ServerFile to $TempLogFile : $!\n";
				push (@Files, $TempLogFile);
			}
			else
			{
				print "File not exist at $Server\n";
				
				my $TempLogFile = $TempLogDir . $Server . ".txt";
				open (DOWN, ">$TempLogFile") || die "Cant open $TempLogFile : $!\n";
				print DOWN "Status=Down\n";
				print DOWN "Server=$Server\n";
				print DOWN "Team=$Team\n";				
				close DOWN;
				push (@Files, $TempLogFile);
			}
		}		
	}		
	close CONFIG;

	open (TMP, ">$TmpSummary") || die "Cant open $TmpSummary  to write : $!";
	foreach my $File (@Files)
	{
		open (FILE, $File) || die "Cant open $File to read : $!\n";
		{
			while (<FILE>)
			{
				chomp;
				s/^(.*\w)\s*$/$1/;
				print TMP "$_\n";	
			}
		}	
		close FILE;		
	}
	close TMP;
	
	copy($TmpSummary, $FinalSummary) || die "Cant copy $TmpSummary to $FinalSummary : $!\n";
}