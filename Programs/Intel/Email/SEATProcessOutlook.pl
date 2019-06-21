#################################################################################################################
#														#
#	Foo Lye Cheung					PG PDE CPU (TMM)					#
#	12 September 2012											#
#	604-2536452												#
#														#
#	This script is to read email from Outlook and generate the XML for SEAT					#
#														#
#	Rev 0.0													#
#	   													#
#	Changes:												#
#	09/12/2012												#
#	1. script is to read email from Outlook and generate the XML for SEAT					#
#														#
#														#
#################################################################################################################
use strict;
use warnings;

use Cwd;
use Getopt::Std;
use File::Find;
use File::Copy;
use Win32::OLE;
use Win32::OLE::Const 'Microsoft Outlook';
use Win32::OLE::Variant;
use Win32::ODBC;

# Mode to set debug
my $Debug = 0;

# Job creation path
#my $Path = "C:\\temp\\SEAT\\jobs\\";
#my $Path = "C:\\temp\\SEAT\\jobs\\";
my $Path = "C:\\temp\\";
#################################################################################################################
#														#
#	Main code start here											#
#														#
#################################################################################################################
my %Data = ();
my $Outlook;
eval {$Outlook = Win32::OLE->GetActiveObject('Outlook.Application')};
die "Outlook not installed" if $@;
unless (defined $Outlook)
{
      $Outlook = Win32::OLE->new('Outlook.Application', sub {$_[0]->Quit;}) or die "Fail to start Outlook!\n";
}

# Executing to check SEAT job via email
&ChkSEATJob();
undef $Outlook;

# Processing the data
foreach my $Idx (keys %Data)
{
	my $FormattedDate = "";
	if ($Debug)
	{
		$FormattedDate = &FormatDate($Data{$Idx}{'RECEIVED'});
		print "Get receive $FormattedDate\n";
	}
	else
	{
		$FormattedDate = $Data{$Idx}{'TIMETORUN'};
		print "Get time to run $FormattedDate\n";
	}

	#print "######################################################\n";
	#print "$Data{$Idx}{'RECEIVED'}\n";
	#print "$Data{$Idx}{'FROM'}\n";
	#print "$Data{$Idx}{'SUBJECT'}\n";
	#print "$Data{$Idx}{'TESTPLAN'}\n";
	#print "$Data{$Idx}{'SUBTESTPLAN'}\n";
	#print "$Data{$Idx}{'ENVFILE'}\n";
	#print "$Data{$Idx}{'SOCFILE'}\n";
	#print "$Data{$Idx}{'TESTER'}\n";
	#print "$Data{$Idx}{'TIMETORUN'}\n";
	#print "######################################################\n";

	my $OutFile = $Path . $Data{$Idx}{'TESTER'} . "_" . $FormattedDate. "_0.xml";
	open (OUT, ">$OutFile") || die "Can't open $OutFile : $!\n";
	print OUT "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n";
	print OUT "<jobs>\n";
	print OUT "<TestPlan>$Data{$Idx}{'TESTPLAN'}</TestPlan>\n";
	print OUT "<SubTestPlan></SubTestPlan>\n";
	print OUT "<EnvFile>$Data{$Idx}{'ENVFILE'}</EnvFile>\n";
	print OUT "<SocFile>$Data{$Idx}{'SOCFILE'}</SocFile>\n";
	print OUT "<Tester>$Data{$Idx}{'TESTER'}</Tester>\n";
	print OUT "<Status>0</Status>\n";
	print OUT "<Submitter>$Data{$Idx}{'FROM'}</Submitter>\n";
	print OUT "<TimeToRun>$FormattedDate</TimeToRun>\n";
	print OUT "</jobs>\n";
	close OUT;
}

#########################################################################################################################
#															#
#	Main code ends here												#
#															#
#########################################################################################################################
# Subroutine check for SEAT job submission at Outlook
sub ChkSEATJob
{
	# Setting up mail connection
	my $Namespace = $Outlook->GetNamespace("MAPI");
	my $OutlookLoad = Win32::OLE::Const->Load($Outlook);
	my $Inbox = $Namespace->GetDefaultFolder(olFolderInbox);
	my $Folder = SeekInboxFolder($Inbox, 'SEAT');
	my $UnReadMailCount = $Folder->UnReadItemCount;
	#print "Item Count = $UnReadMailCount\n";

	# Start filtering the unread mails
	my $Tmp = "";
	my $Filter = '[UnRead] = True';
	my $MailItems = $Folder->Items;
	my $UnReadMailItems = $MailItems->Find($Filter);

	my $Idx = 0;
	while ($UnReadMailItems)
	{
		# Skip non email (meeting requests, etc)
		if ($UnReadMailItems->Class == olMail)
		{
			my $Tmp = "";
			
			# Get receive time
			$Tmp = $UnReadMailItems->ReceivedTime()->Date() . ' ' . $UnReadMailItems->ReceivedTime()->Time();
			chomp ($Tmp);	
			$Data{$Idx}{'RECEIVED'} = $Tmp;

			my $Sender = $UnReadMailItems->SenderName;
			chomp ($Sender);	
			$Data{$Idx}{'SENDER'} = $Sender;

			# Using cdis if sender using intel email
			if ($UnReadMailItems->SenderEmailAddress =~ /\/O=INTEL/ig)
			{
				my $UCSender = uc($Sender);
				$Tmp = &QueryEmail($UCSender);
			}
			else
			{
				$Tmp = $UnReadMailItems->SenderEmailAddress;
			}
			chomp($Tmp);
			$Data{$Idx}{'FROM'} = $Tmp;

			# Get subject
			$Tmp = $UnReadMailItems->Subject;
			chomp($Tmp);
			$Data{$Idx}{'SUBJECT'} = $Tmp;
			
			# Get body
			$Tmp = $UnReadMailItems->Body;
			chomp($Tmp);
			#$Data{$Idx}{'TESTPLAN'}
			#$Data{$Idx}{'SUBTESTPLAN'}
			#$Data{$Idx}{'ENVFILE'}
			#$Data{$Idx}{'SOCFILE'}
			#$Data{$Idx}{'TESTER'}
			#$Data{$Idx}{'TIMETORUN'}
			($Data{$Idx}{'TESTPLAN'}, $Data{$Idx}{'SUBTESTPLAN'}, $Data{$Idx}{'ENVFILE'}, $Data{$Idx}{'SOCFILE'}, $Data{$Idx}{'TESTER'}, $Data{$Idx}{'TIMETORUN'}) = &ProcessBody($Tmp);

			# Mark as read once done processing
			if ($UnReadMailItems->{'Unread'})
			{
				#$UnReadMailItems->{'Unread'} = 0;
			}
			$Idx++;
		}
		$UnReadMailItems = $MailItems->FindNext;
	}
}

# Subroutine to process body to get the information
sub ProcessBody
{
	my $Body = shift;
	my ($TestPlan, $SubTestPlan, $EnvFile, $SocFile, $Tester, $TimeToRun)= ("", "NA", "", "", "", "");
	my @Lines = split("\n", $Body);

	foreach my $Line (@Lines)
	{
		chomp ($Line);		
		if ($Line =~/^\s*TestPlan\s*=\s*(\S+)/i)
		{
			$TestPlan = $1;
		}
		elsif ($Line =~ /SubTestPlan\s*=\s*(\S+)/i)
		{
			$SubTestPlan = $1;
		}
		elsif ($Line =~ /EnvFile\s*=\s*(\S+)/i)
		{
			$EnvFile = $1;
		}
		elsif ($Line =~ /SocFile\s*=\s*(\S+)/i)
		{
			$SocFile = $1;
		}
		elsif ($Line =~ /Tester\s*=\s*(\S+)/i)
		{
			$Tester = $1;
		}
		elsif ($Line =~ /TimeToRun\s*=\s*(\S+)/i)
		{
			$TimeToRun = $1;
		}
	}
	return ($TestPlan, $SubTestPlan, $EnvFile, $SocFile, $Tester, $TimeToRun);
}

# Subroutine to search the folder in Inbox
sub SeekInboxFolder 
{
	my $obj = shift;
	my $target = shift;
	for (my $i = 1; $i <= $obj->Folders->Count; $i++) 
	{
	    	if ( $obj->Folders->Item($i)->Name eq $target ) 
		{
		  	return $obj->Folders->Item($i);
	    	}
      	}
}

# Subroutine to format date from "9/12/2012 11:35:59 AM" to "20121209113559"
sub FormatDate
{
	my $ParseDate = shift;
	my @ArrayDates = split (/\s+/, $ParseDate);

	# Formatting the date format
	my @Dates = split (/\//, $ArrayDates[0]);
	my $Date = "";
	if (2 != length($Dates[0]))
	{
		$Date = $Dates[2] . $Dates[1] . "0" . $Dates[0];
	}
	else
	{
		$Date = $Dates[2] . $Dates[1] . $Dates[0];
	}

	# Convert to 24 hour system
	my $Time = $ArrayDates[1];
	$Time =~ s/://ig;
	if ("PM" eq $ArrayDates[2])
	{
		$Time = $Time + 120000;
	}
	
	return ($Date . $Time);
}

#################################################################################################################
#														#
#	CDIS subroutines											#
#														#
#################################################################################################################
# Open cdis connection
sub OpenCDIS
{
	my $dbCDIS;
	my $UID = 'PDEkudos';
	my $PWD = 'j6ipvx0W';
	
	unless($dbCDIS = new Win32::ODBC("dsn=CDIS; DATABASE=x500; UID=$UID; PWD=$PWD"))
	{
		print "Error: " . Win32::ODBC::Error() . "\n";
		exit;
	}

	return $dbCDIS;
}

# Subroutine to query email address base on sender name
sub QueryEmail
{
	my $UserName = shift;
	my $Email = "";
	my $SqlQuery = "SELECT LongID, DomainAddress FROM WorkerPublicExtended where LongID like '$UserName'";
	my $dbCDIS = &OpenCDIS();
	if($dbCDIS->Sql($SqlQuery))
	{
		print "Error, SQL failed: " . $dbCDIS->Error() . "\n";
		print "Unable to query from CDIS\n";
		$dbCDIS->Close();
		exit;
	}
	else 
	{
		while($dbCDIS->FetchRow())
		{
			my %Temp = $dbCDIS->DataHash();
			$Email = $Temp{'DomainAddress'};
		}		
	}
	$dbCDIS->Close();
	return ($Email);
}

