
use NET::SMTP;
use strict;
use warnings;

&MainProgram();

sub MainProgram
{
	print "Welcome to workstation usage checker\n";
	my $ConfigFile = 'C:\Perl\Programs\workstation.cfg';
	my $LogFile = 'C:\Perl\Programs\SummaryWS.txt';	
	my ($Header1, $QuserDat) = ("", "");

	open (TEMP, ">$LogFile") or die "Cant open $LogFile : $!\n";
	open (CONFIG, $ConfigFile) or die "Cant open $ConfigFile : $!\n";
	while (<CONFIG>)
	{
		chomp;
		my $Server = $_;
	
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
			print TEMP "Server=$Server\n";
			print TEMP "Status=No User Logon\n";
			print "$Server :: No user logon\n";
		}
		else	
		{
			my ($Header2, @QProcess) = qx(qprocess $IDSID /server:$Server);
			$IDSID =~ s/\s+//g;
			$State =~ s/\s+//g;
			$LogonTime =~ s/(\S+\s+\S+M)\s+/$1/g;
			print TEMP "Server=$Server\n";
			print TEMP "Status=$State\n";
			print TEMP "User=$IDSID\n";
			print TEMP "Logon=$LogonTime\n";
		
			foreach my $qprocess (@QProcess)
			{
				my ($PID, $Image) = ($1, $2) if ($qprocess =~ /\s+0\s+(\d+)\s+(\S+)/);
				print TEMP "Program=$PID\t$Image\n";
			}
	
			my $ENow = time();
			my $Now = gmtime ($ENow);
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
	
			my $DiffTime = $ENow - $EActiveTime;
			print "LastActive=$ActiveTime\n";
			print TEMP "LastActive=$ActiveTime\n";
			print "$Server :: $EActiveTime and $LogonTime, $ENow - $Now, $DiffTime :: $IDSID\n";
	
			# If the time different in seconds more than 24 hours
			#if ($DiffTime > 86400)
			if ($DiffTime > 400)
			{
				my $Email = "";

				print "Active=No(IDLE=$DiffTime)\n";
				print TEMP "Active=No(IDLE=$DiffTime)\n";
				open (EMAIL, "email.cfg") or die "Cant open email.cfg : $!\n";
				while (<EMAIL>)
				{
					if (/$IDSID\s+(\S+)/)
					{
						$Email = $1;
					}
				}
				close EMAIL;
				&SendMail($Email, "Warning: $Server - IDLE=$DiffTime secs !!!");
			}
			else
			{
				print "Active=Yes(IDLE=$DiffTime)\n";
				print TEMP "Active=Yes(IDLE=$DiffTime)\n";
			}
		
			print "$Server :: $EActiveTime and $LogonTime, $ENow - $Now, $DiffTime :: $IDSID\n";
		}
	}
	close CONFIG;
	close TEMP;
}

sub SendMail 
{
	my ($To, $Subject) = @_;
	my $MailHost = 'mail.intel.com';
	my $From = 'wsadmin@intel.com';
	my $Body = "\n\n$Subject\n" .
		   "==========================================\n\n" .
		   "If you still require to use the wortstation,\n" .
                   "please remote login again to reactivate the system...\n" .
		   "Else please logout, thank you....\n" . 
		   "\n\n*** PLEASE DO NOT REPLY THIS EMAIL ***\n";

	my $smtp = Net::SMTP->new($MailHost);
	$smtp->mail($From);
	$smtp->to($To);
	$smtp->data();
	$smtp->datasend("To: $To\n");
	$smtp->datasend("Subject: $Subject\n");
	$smtp->datasend("$Body");
	$smtp->dataend();
	$smtp->quit();
}
