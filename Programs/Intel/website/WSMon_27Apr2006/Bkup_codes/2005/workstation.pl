#################################################################################
#                                                                               #
#        Foo Lye Cheung                             PDE DPG 		        #
#        inet 253 6452                              Penang                      #
#                                                                               #
#        DESCRIPTION                                                            #
#        Check the workstation usage and status.				#
#                                                                               #
#        RELEASES                                                               #
#        03/25/2005  rev1.0 - Main code release                                 #
#                                                                               #
#################################################################################
use NET::SMTP;
use Win32::OLE;
use strict;
use warnings;

&MainProgram();

sub MainProgram
{
	my $ConfigFile = 'workstation.cfg';
	my $LogFile = 'C:\Intel\Perl\Programs\SummaryWS.tmp';	
	my $OkLogFile = 'C:\Intel\Perl\Programs\SummaryWS.txt';
	my ($Header1, $QuserDat) = ("", "");

	open (TEMP, ">$LogFile") or die "Cant open $LogFile : $!\n";
	open (CONFIG, $ConfigFile) or die "Cant open $ConfigFile : $!\n";
	while (<CONFIG>)
	{
		chomp;
		my ($Server, $Team) = split (/\s+/, $_);
	
		($Header1, $QuserDat) = qx(quser /server:$Server);
		no warnings;
		chomp ($QuserDat);

		my $IDSID = substr($QuserDat, 0, 15);
		my $SessionName = substr($QuserDat, 23, 15);
		my $SessionID = substr($QuserDat, 43, 1);
		my $State = substr($QuserDat, 46, 8);
		my $IdleTime = substr($QuserDat, 53, 11);
		my $LogonTime = substr($QuserDat, 65);

		if ($QuserDat eq "")
		{
			print TEMP "Status=No User Logon\n";
			print TEMP "Server=$Server\n";
			print TEMP "Team=$Team\n";
		}
		else	
		{
			my ($Header2, @QProcess) = qx(qprocess $IDSID /server:$Server);
			$IDSID =~ s/\s+//g;
			$State =~ s/\s+//g;
			$LogonTime =~ s/(\S+\s+\S+M)\s+/$1/g;
			$SessionName =~ s/\s+//g;
			print TEMP "Status=$State\n";
			print TEMP "Server=$Server\n";
			print TEMP "Team=$Team\n";
			print TEMP "User=$IDSID\n";
			print TEMP "Logon=$LogonTime\n";
		
			foreach my $qprocess (@QProcess)
			{
				my ($PID, $Image) = ($1, $2) if ($qprocess =~ /\s+0\s+(\d+)\s+(\S+)/);
				print TEMP "Program=$PID\t$Image\n";
			}
	
			my $ENow = time();
			my $Now = localtime ($ENow);
			my ($EActiveTime, $ActiveTime) = ($ENow, $Now);
			my $ServerlogFile = "$Server.log";
	
			if ($State eq "Active")
			{
				open (SERVERLOG, ">$ServerlogFile") or die "Can't open $ServerlogFile : $!\n";
				print SERVERLOG "$ENow\t$Now\n";
				close SERVERLOG;
			}
			else
			{
				if (! -e $ServerlogFile)
				{
					open (SERVERLOG, ">$ServerlogFile") or die "Can't open $ServerlogFile : $!\n";
					print SERVERLOG "$ENow\t$Now\n";
				}
				else
				{
					open (SERVERLOG, "$ServerlogFile") or die "Can't open $ServerlogFile : $!\n";
					my $Serverlog = <SERVERLOG>;
					($EActiveTime, $ActiveTime) = split(/\t/, $Serverlog);
				}
				close SERVERLOG;
			}
	
			chomp($ActiveTime);
			print TEMP "LastActive=$ActiveTime\n";

			my $DiffTime = $ENow - $EActiveTime;
			my $TimeDDHHMMSS = &ConvertTime($DiffTime);

			# If the time different in seconds more than 24 hours
			if ($DiffTime > 86400)
			{
				my $Email = "";

				print TEMP "Active=No(IDLE=$TimeDDHHMMSS)\n";
				open (EMAIL, "email.cfg") or die "Cant open email.cfg : $!\n";
				while (<EMAIL>)
				{
					if (/$IDSID\s+(\S+)/)
					{
						$Email = $1;
					}
				}
				close EMAIL;
				#&SendMail($Email, "Warning: $Server - IDLE= $TimeDDHHMMSS !!!");
			}
			else
			{
				if ($SessionName eq "console")
				{
					print TEMP "Active=Yes(Console IDLE=$TimeDDHHMMSS)\n";
				}
				else
				{
					print TEMP "Active=Yes(IDLE=$TimeDDHHMMSS)\n";
				}
				
			}
		}
	}
	close CONFIG;
	close TEMP;

	rename($LogFile, $OkLogFile);
}

sub SendMail 
{
	my ($To, $Subject) = @_;
	#my $Cc = 'lye.cheung.foo@intel.com';
	my $Cc = "";
	my $From = 'CMTWSAdmin@intel.com';
	my $Body = "\n\n$Subject\n" .
		   "==========================================\n\n" .
		   "If you still require to use the workstation,\n" .
                   "please remote login again to reactivate the system...\n" .
		   "Else please logout, thank you....\n" . 
		   "\n\n*** PLEASE DO NOT REPLY THIS EMAIL ***\n";
	

	my $Mail = Win32::OLE->new('CDONTS.NewMail'); 
	$Mail->{From} = $From;
	$Mail->{To} = $To;
	$Mail->{Cc} = $Cc if($Cc ne "");
	$Mail->{Subject} = $Subject;
	$Mail->{Body} = $Body;
	$Mail->{Importance} = 2;
	$Mail->Send();
	undef $Mail; 
	
	print "Mail send to $To ...\n";
}

# Convert from seconds to Day, Hour, Minute and Second
sub ConvertTime
{
	my $Time = shift;
	my $Day = eval{$Time / 86400};
	$Day =~ s/^(\d+)\.\d+$/$1/;
	my $Hour = eval{($Time - ($Day * 86400)) / 3600};
	$Hour =~ s/^(\d+)\.\d+$/$1/;
	my $Minute = eval{($Time - (($Day * 86400) + ($Hour * 3600))) / 60};
	$Minute =~ s/^(\d+)\.\d+$/$1/;
	my $Second = eval{$Time - (($Day * 86400) + ($Hour * 3600) + ($Minute * 60))};
	#return "Day:$Day, HH:$Hour, MM:$Minute, Sec:$Second";
	return "${Day}days, ${Hour}hours, ${Minute}mins";
}
