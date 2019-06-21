#################################################################################
#                                                                               #
#        Foo Lye Cheung                             PDE DPG 		        #
#        inet 253 6452                              Penang                      #
#                                                                               #
#        DESCRIPTION                                                            #
#        Rewrite check the workstation usage and status due to WinXP SP2	#
#        Bug fix for ping and wmi unreachable which will kill the script	#
#                                                                               #
#        RELEASES                                                               #
#        04/27/2006  rev3.0 - Main code release                                 #
#                                                                               #
#################################################################################
use Win32::OLE;
use Data::Dumper;
use Win32::Process::Info;
use strict;
use warnings;
$| = 1;

&MainProgram();

sub MainProgram
{
	my $CurrentPath = 'C:/Intel/Perl/Programs/';
	my $ErrorLog = $CurrentPath . 'Error.log';
	my $ConfigFile = $CurrentPath . 'All_workstation.cfg';
	my $LogFile = $CurrentPath . 'SummaryWS.tmp';	
	my $OkLogFile = $CurrentPath . 'SummaryWS.txt';
	my $FailPingFlag = 0;

	my $hostname = qx/hostname/;
	chomp ($hostname);
	print "Running at: $hostname\n";
	open (ERROR, ">$ErrorLog") or die "Cant open $$ErrorLog : $!\n";
	open (TEMP, ">$LogFile") or die "Cant open $LogFile : $!\n";
	open (CONFIG, $ConfigFile) or die "Cant open $ConfigFile : $!\n";
	while (<CONFIG>)
	{
		chomp;
		my ($Server, $Team) = split (/\s+/, $_);
		
		print "Server: $Server\n";
		$FailPingFlag = 0;
		my $qwinsta = 0;
		my @Pings = qx/ping -n 1 $Server/;
		foreach my $Ping (@Pings)
		{
			chomp($Ping);
			if (($Ping =~ /Request\s*timed\s*out\./ig) || ($Ping =~ /could\s*not\s*find\s*host/ig))
			{
				print ERROR "ERROR: Fail ping server - $Server\n";
				$FailPingFlag = 1;
			}
			else
			{
				my $LineCmd = 'qwinsta /SERVER:' . $Server;
				open (CMD, "$LineCmd|") || die "Can't pipe $LineCmd : $!\n";
				while (<CMD>)
				{
					chomp;
					$qwinsta = 1;
					#print ERROR "Line: " . $_ ."\n";
					last;
				}
				close CMD;

				if ((!$qwinsta) && ($Server =~ /pgw/ig))
				{
					$qwinsta = 0;
					print ERROR "ERROR: Fail wmi server - $Server\n";
					$FailPingFlag = 1;
					last;
				}
			}
		}

		if ($FailPingFlag)
		{
			print TEMP "Status=No User Logon\n";
			print TEMP "Server=$Server\n";
			print TEMP "Team=$Team\n";
			next;			
		}

		my $FlagSvc = 0;			
		if ($Server !~ /$hostname/iog)
		{
			my $ProcessInfo = Win32::Process::Info->new ($Server);
			my %AllLogon = ();
			my @LastActiveTimes = ();
			my ($Apps, $LogonTimes, $IDSIDs, $LastActives, $LogonFlag) = ("", "", "", 0, 0);
			foreach my $Process ($ProcessInfo->ListPids()) 
			{
				$Process = ${$ProcessInfo->GetProcInfo ($Process)}[0] unless ref $Process;
				foreach my $Line (sort keys %$Process)
				{
					chomp ($Line);
					$Apps = $Process->{$Line} if ($Line eq "Caption");
					chomp ($Apps);

					if (($Apps =~ /2000Svc/ig) || ($Apps =~ /nvsvc/ig) || ($Apps =~ /locator/ig))
					{
						$FlagSvc = 1;
					}
					else
					{
						$FlagSvc = 0;
					}

					if ($Line eq "CreationDate")
					{
						if ($Apps =~ /winlogon/iog)
						{
							$LogonFlag = 1;
							$LogonTimes = $Process->{$Line};
						}
					}
					elsif ($Line eq "Owner")
					{
						if (($Process->{'Owner'} =~ /^\w{3}\\(\w+)/) && ($LogonFlag) && (!$FlagSvc))
						{
							$IDSIDs = $1;
							$AllLogon{$IDSIDs} = $LogonTimes;
							$LogonFlag = 0;
						}
					}

					if ($Line eq "CreationDate")
					{
						my $Time = ($Process->{$Line});
						no warnings;
						if ($LastActives < $Time)
						{
							$LastActives = $Time;
							push (@LastActiveTimes, $Time);
						}
					}
				}
				my $FlagSvc = 0;
			}

			# Remove the process done by this script to go in as worm
			my $LastActive = $LastActiveTimes[$#LastActiveTimes - 1];

			#print "$Server " . localtime($LastActive) . "\n";
			@LastActiveTimes = ();
		
			my $ActiveFlag = 0;
			my $State = "In Active"; 
			my $ENow = time();
			foreach my $IDSID (keys %AllLogon)
			{
				$ActiveFlag = 1;
				if (($ENow - $LastActive) < 1800)
				{
					$State = "Active";
				}

				my $Time = localtime ($LastActive);
				my $LogonTime = &TimeFormat($AllLogon{$IDSID});
				print TEMP "Status=$State\n";
				print TEMP "Server=$Server\n";
				print TEMP "Team=$Team\n";
				print TEMP "User=$IDSID\n";
				print TEMP "Logon=$LogonTime\n";	
				print TEMP "LastActive=$Time\n";

				#print "($LastActive - $AllLogon{$IDSID})\n";
				my $DiffTime = ($ENow - $LastActive);
			
				my $TimeDDHHMMSS = &ConvertTime($DiffTime);

				# If the time different in seconds more than 24 hours
				if ($DiffTime > 86400)
				{
					print TEMP "Active=No(IDLE=$TimeDDHHMMSS)\n";
				}
				else
				{
					print TEMP "Active=Yes(IDLE=$TimeDDHHMMSS)\n";
				}
			}


			if (!$ActiveFlag)
			{
				print TEMP "Status=No User Logon\n";
				print TEMP "Server=$Server\n";
				print TEMP "Team=$Team\n";
			}
		}
		else
		{
			#For host workstation only due to it unable to detect its own process
			#print "IN $Server\n";
			#my @HostProcesses = qx/qprocess */;
			#foreach my $HostProcess (@HostProcesses)
			#{
			#	
			#}
			my $WSHostname = $CurrentPath . "SummaryWS_${hostname}.txt";
			open (WSHOSTNAME,$WSHostname) || die "Cant open $hostname : $!\n";
			while (<WSHOSTNAME>)
			{
				chomp;
				print TEMP "$_\n";
			}
			close WSHOSTNAME;
		}
	}
	close CONFIG;
	close TEMP;
	close ERROR;

	rename($LogFile, $OkLogFile);
}

# Convert from seconds to Day, Hour, Minute and Second
sub ConvertTime
{
	my $Time = shift;
	if ($Time > 60)
	{
		my $Day = eval{$Time / 86400};
		$Day =~ s/^(\d+)\.\d+$/$1/;
		my $Hour = eval{($Time - ($Day * 86400)) / 3600};
		$Hour =~ s/^(\d+)\.\d+$/$1/;
		my $Minute = eval{($Time - (($Day * 86400) + ($Hour * 3600))) / 60};
		$Minute =~ s/^(\d+)\.\d+$/$1/;
		my $Second = eval{$Time - (($Day * 86400) + ($Hour * 3600) + ($Minute * 60))};
		return "${Day}days, ${Hour}hours, ${Minute}mins";
	}
	else
	{
		return "0days, 0hours, 0mins";
	}
}

# Format the date
sub TimeFormat
{
	my $Time = shift;
	my ($SS, $MI, $HH, $DD, $MM, $YYYY) = localtime($Time);
	$YYYY += 1900;
	$MM++;
	$MM =~ s/^(\d)$/0$1/;
	$DD =~ s/^(\d)$/0$1/;
	$HH =~ s/^(\d)$/0$1/;
	$MI =~ s/^(\d)$/0$1/;
	$SS =~ s/^(\d)$/0$1/;
	my $Now = "$MM/$DD/$YYYY $HH:$MI:$SS";
	return ($Now);
}

