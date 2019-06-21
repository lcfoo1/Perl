
use strict;
use warnings;
use Win32::OLE;
use Win32::ODBC;
use Time::Local;


#my $cdo = Win32::OLE->new('CDO.Message') or die "NOT SUPPORTED";
#$cdo->{From} = "lye.cheung.foo\@intel.com";
#$cdo->{To} = "lye.cheung.foo\@intel.com";
#$cdo->{Subject} = "TESTING PERL CDO";
#$cdo->{TextBody} = "TEST";
#$cdo->Send();
#
#
#

my $Message = Win32::OLE->new("CDO.Message");
#francobollo means stamp...
my $francobollo=  Win32::OLE->new ("CDO.Configuration") ;
$francobollo->{Fields}->{"http://schemas.microsoft.com/cdo/configuration/sendusing"}=2;#means with no local SMTP srv
$francobollo->{Fields}->{"http://schemas.microsoft.com/cdo/configuration/smtpserver"}="mail.intel.com";
$francobollo->{Fields}->{"http://schemas.microsoft.com/cdo/configuration/smtpserverport"}=25;
$francobollo->{Fields}->Update();
$Message->{Configuration} = $francobollo;


$Message->{From}="lye.cheung.foo\@intel.com";
$Message->{To}="lye.cheung.foo\@intel.com";
$Message->{Bcc}="";
$Message->{Subject}="I told you, myDeamon, to run on a Linux machine.";
$Message->{TextBody}="ah ah";



$Message->Send();
print Win32::OLE-> LastError();

