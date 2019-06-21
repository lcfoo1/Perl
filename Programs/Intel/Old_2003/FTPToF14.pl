#########################################################################
#									#
#	Foo Lye Cheung		NCO PDQRE Automation			#
#	06/24/2004							#
#									#
#	This script runs under scheduler task and ftp wafermap files	#
#	to F14. Upon successful uploading the wafermap, the original 	#
#	files will renamed as .old					#
#									#
#	NOTES:								#
#	Requries Perl 5							#
#									#
#########################################################################

use strict;
use warnings;
use Net::FTP;
use Net::SMTP;

# FTP  signal file to DataBroker
&FTPS03ToF14();

sub FTPS03ToF14
{
        my $Server = 'lfoo1-mobl'; 
        my $FTPLog = ">>C:\\Perl\\Programs\\FTPS03ToF14.log";
	my ($ID, $PWD) = ("lcfoo", "intel%123");
	my $Dir = "C:\\FTP_HOME\\WaferMap\\WTU";

        my $FTP = Net::FTP->new($Server) or die "Can't connect to $Server\n";
        $FTP->login($ID,$PWD) or die "Sorry can't connect as user $ID\n";
	#$FTP->cwd($RemoteDir);
        open(LOG, $FTPLog) or die "$FTPLog:- $!\n";
        my $Now = localtime(time);
	
	chdir $Dir or die "Cant open $Dir: $!\n";	
	
	foreach my $File (<*.1>)
	{
        	if($FTP->put($File))
		{
			print LOG "Loaded $File at $Now\n";
			my $OldFile = $File.".old";
			print "Successful ftp Data Broker: $File, renamed $OldFile\n";
			rename($File, $OldFile);
        	}
        	else
        	{
                	print LOG "Couldnt put $File at $Now\n";

			# Send Mail to IT because unable to put
			my @To = ('lye.cheung.foo@intel.com');
			my $Subject = "Unable to ftp wafermap from S03 to F14 at $Now";
			my $Body = "\nUnable to ftp wafermap from S03 to F14 at $Now\n\n
				*** Don't reply this email ***\n";

			&SendMail();
			exit;
        	}
	}
        $FTP->quit;
        undef $FTP;
        close LOG;
}

# Send Mail to Storm/DataBroker owner
sub SendMail 
{
	my($Subject, $Body, @To) = @_;
	my $MailHost = 'mail.intel.com';
	my $From = 'SCDataBroker@intel.com';
	my $Tos = join('; ', @To);
	my $smtp = Net::SMTP->new($MailHost);
	$smtp->mail($From);
	$smtp->to(@To);
	$smtp->data();
	$smtp->datasend("To: $Tos\n");
	$smtp->datasend("Subject: $Subject\n");
	$smtp->datasend("$Body\n");
	$smtp->dataend();
	$smtp->quit();
}
