
use Win32::OLE;


	$To = 'lye.cheung.foo@intel.com;';   
	$Subject = "Stop emailing to me!!!"; 
	$Body = "";
	&SendMail($To, '', $Subject, $Body);# || die "Cant send mail: $!\n";;

sub SendMail
{
	my($To, $Cc, $Subject, $Body) = @_;

	my $Mail = Win32::OLE->new('CDO.Message'); 
	$Mail->{From} = 'shite@yahoo.com'; 
	$Mail->{To} = $To;
	$Mail->{Cc} = $Cc if($Cc ne "");
	$Mail->{Subject} = $Subject;
	$Mail->{BodyFormat} = "CdoBodyFormatHTML";
	$Mail->{TextBody} = $Body;
	$Mail->Send();
	undef $Mail; 
}
