#################################################################################################################
#                                                                                       			#
#	Foo Lye Cheung					PG PDE CPU (TMM)					#
#	04 September 2011											#
#	604-2536452												#
#                                                                                       			#
#	DESCRIPTION                                                                    				#
#       Script written to automate generate report from gVal run						#
#       													#
#	NOTES													#
#	- Require to interact Perl, DOS command execution and Windows						#
#                                                                                       			#
#	RELEASES												#
#	Rev 0.0	                                                        	               			#
#	CHANGES													#
#	1. First release generation report when gVal finish regression						#
#                                                                                       			#
#	Rev 1.0	                                                        	               			#
#	CHANGES													#
#	1. Added main website regression report. Only report lastest 15 regression status			#
#                                                                                       			#
#	Rev 2.0	                                                        	               			#
#	CHANGES													#
#	1. Filter duplicate test names due to gVal will attemp to t2kctrl restart when fail for 1st time	#
#	   and this will cause the test pass/fail incorrect as second time testing might pass the test		#
#	2. Enhance the report structure to alphabetical test template name (standard top down sequence)		#
#                                                                                       			#
#	Rev 3.0	                                                        	               			#
#	CHANGES													#
#	1. Added copy webpage feature to other server so that gVal report send to other central server		#
#                                                                                       			#
#	Rev 4.0	                                                        	               			#
#	CHANGES													#
#	1. Added servername in the report to know which server run the regression				#
#                                                                                       			#
#	Rev 5.0	                                                        	               			#
#	CHANGES													#
#	1. Change to use window environment to read configuration instead of input file				#
#                                                                                       			#
#	Copyright reserved 2009 by Foo Lye Cheung	                                      			#
#                                                                                       			#
#################################################################################################################
use strict;
use warnings;
use Cwd;
use Getopt::Std;
use Win32::OLE;
use Env;

my $To = "lye.cheung.foo\@intel.com";
my $HTMLFile = 'C:\Perl\Programs\Result\ResultSumm.html';
my $HTMLText = "";
my $Subject = "Test result";
&GenerateEmailReport();

sub GenerateEmailReport
{
	my $Cmd = "type $HTMLFile";
	my @HTMLTexts = qx/$Cmd/;
	
	$HTMLText = join("", @HTMLTexts);
	print "$HTMLText\n";
	#open (HTML, "$HTMLFile") || die "Cant open $HTMLFile : $!\n";
	#while (<HTML>)
	#{
	#	$HTMLText .= <HTML>;
	#	print "$HTMLText";
	#}
	#close HTML;
	&SendMail($Subject, $HTMLText);

}

# Format date
sub FormatNow
{
	my $DateTime = shift;
	my ($SS, $MI, $HH, $DD, $MM, $YYYY) = localtime(time);
	my $Now = "";
	$YYYY += 1900;
	$MM++;
	$MM =~ s/^(\d)$/0$1/;
	$DD =~ s/^(\d)$/0$1/;
	$HH =~ s/^(\d)$/0$1/;
	$MI =~ s/^(\d)$/0$1/;
	$SS =~ s/^(\d)$/0$1/;

	if ($DateTime eq "Date")
	{
		$Now = "${MM}${DD}${YYYY}";
	}
	elsif ($DateTime eq "Format")
	{
		$Now = "${MM}/${DD}/${YYYY} ${HH}:${MI}:${SS}";
	}
	else
	{
		$Now = "${YYYY}${MM}${DD}${HH}${MI}${SS}";
	}
	return ($Now);
}

# Send mail to email list from setup
sub SendMail
{
	my($Subject, $Body) = @_;
	my $Mail = Win32::OLE->new("CDO.Message"); 
	my $MailConfiguration = Win32::OLE->new ("CDO.Configuration");
	$MailConfiguration->{Fields}->{"http://schemas.microsoft.com/cdo/configuration/sendusing"} = 2;
	$MailConfiguration->{Fields}->{"http://schemas.microsoft.com/cdo/configuration/smtpserver"} = "mail.intel.com";
	$MailConfiguration->{Fields}->{"http://schemas.microsoft.com/cdo/configuration/smtpserverport"} = 25;
	$MailConfiguration->{Fields}->Update();
	$Mail->{Configuration} = $MailConfiguration;

	my $Cc = "";
	$Mail->{From} = 'greenlaneteam@intel.com'; 
	$Mail->{To} = $To;
	$Mail->{BCc} = $Cc if($Cc ne "");
	$Mail->{Subject} = $Subject;
	$Mail->{HTMLBody} = $Body;
	$Mail->{BodyFormat} = 0;
	$Mail->{MailFormat} = 0;
	$Mail->{Importance} = 1;
	$Mail->Send();
	#print Win32::OLE->LastError();
	undef $Mail; 
}


