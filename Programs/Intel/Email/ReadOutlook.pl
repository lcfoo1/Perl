# Script written by Lye Cheung Foo
use strict;
use Win32::OLE;
use Win32::OLE::Const 'Microsoft Outlook';
use Win32::OLE::Variant;
use Win32::ODBC;



#########################################################################################################################
#															#
#	Main code start here												#
#															#
#########################################################################################################################
my $Outlook;
eval {$Outlook = Win32::OLE->GetActiveObject('Outlook.Application')};
die "Outlook not installed" if $@;
unless (defined $Outlook)
{
      $Outlook = Win32::OLE->new('Outlook.Application', sub {$_[0]->Quit;}) or die "Fail to start Outlook!\n";
}

#&ChkSEATJob();
my $UserName = "FOO, LYE CHEUNG";
my $Email = &QueryEmail($UserName);
print "$Email\n";
undef $Outlook;


sub QueryEmail
{
	my $UserName = shift;
	my $Email = "";
	my $SqlQuery = "SELECT LongID, DomainAddress FROM WorkerPublicExtended where LongID like '$UserName'";
	my $dbCDIS = &OpenCDIS();
	if($dbCDIS->Sql($SqlQuery))
	{
		my $sql = "Unable to query from CDIS\n";
		&ifSQL($dbCDIS, $sql);
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
	print "Item Count = $UnReadMailCount\n";

	# Start filtering the unread mails
	my $Tmp = "";
	my $Filter = '[UnRead] = True';
	my $MailItems = $Folder->Items;
	my $UnReadMailItems = $MailItems->Find($Filter);

	while ($UnReadMailItems)
	{
		# Skip non email (meeting requests, etc)
		if ($UnReadMailItems->Class == olMail)
		{
			print "################################################################################################\n";
			print $UnReadMailItems->ReceivedTime()->Date() . ' ' . $UnReadMailItems->ReceivedTime()->Time() . "\n";
			$Tmp = $UnReadMailItems->SenderName;
			chomp ($Tmp);	
		      	print "Sender: $Tmp\n";
			$Tmp = $UnReadMailItems->SenderEmailAddress;
			chomp ($Tmp);
			if ($Tmp =~ /\/O=INTEL/ig)
			{

			}
			print "Sender email: $Tmp\n";

			$Tmp = $UnReadMailItems->Subject;
			chomp ($Tmp);
		     	print "Subject: $Tmp\n";
			$Tmp = $UnReadMailItems->Body;
			chomp ($Tmp);	
			$Tmp =~ s/\r/\n/;
			print "$Tmp\n";
			if ($UnReadMailItems->{'Unread'})
			{
				#$UnReadMailItems->{'Unread'} = 0;
			}		
		}
		$UnReadMailItems = $MailItems->FindNext;
	}
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

# Exit if sql query fail
sub ifSQL
{
	my ($dbCDIS, $sql) = @_;
	print "Error, SQL failed: " . $dbCDIS->Error() . "\n";
	print "$sql\n";
	$dbCDIS->Close();
	exit;
}


