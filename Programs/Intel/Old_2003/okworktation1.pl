
use Time::Local;

print "Welcome to Workstation checker\n";
print "\n+++++++++++++++++++++++++++++++++++++++++++++++++++\n";

my $ConfigFile = 'C:\Perl\Programs\workstation.cfg';
my $LogFile = 'C:\Perl\Programs\TEMPworkstation.txt';	
open (TEMP, ">$LogFile") or die "Cant open $LogFile : $!\n";
open (CONFIG, $ConfigFile) or die "Cant open $ConfigFile : $!\n";
while (<CONFIG>)
{
	chomp;
	my $Server = $_;
	my ($Header1, $QuserDat) = qx(quser /server:$Server);
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
		print TEMP "Active=$LogonTime\n";
		
		foreach my $qprocess (@QProcess)
		{
			my ($PID, $Image) = ($1, $2) if ($qprocess =~ /\s+0\s+(\d+)\s+(\S+)/);
			print TEMP "Program=$PID\t$Image\n";
		}
	
		#my ($mm, $dd, $yyyy, $hh, $mi, $APM) = split (/[\s+\/:]/, $LogonTime);
		#$hh += 12 if $APM =~ /PM/i;
		#my $ELogonTime = timelocal(00, $mi, $hh, $dd, ($mm - 1), ($yyyy - 1900));

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
				chomp(my $Serverlog = <SERVERLOG>);
				($EActiveTime, $ActiveTime) = split(/\t/, $Serverlog);
			}
			close SERVERLOG;
			
			print "Active=$LogonTime\n";
			print TEMP "Active=$LogonTime\n";
		}
		
		my $DiffTime = $ENow - $EActiveTime;
	
		# If the time different in seconds more than 24 hours
		if ($DiffTime > 86400)
		{
			print "Usage=NotActive\t$Now :: $DiffTime\n";
		}
		else
		{
			print "Usage=Active\t$Now :: $DiffTime\n";
		}
		
		print "$Server :: $EActiveTime and $LogonTime, $ENow - $Now, $DiffTime :: $IDSID\n";
	}
}
close CONFIG;
close TEMP;

print "\n+++++++++++++++++++++++++++++++++++++++++++++++++++\n";
