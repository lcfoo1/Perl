
use Win32::OLE;
my @Tos = ('huey.miin.lee@intel.com', 'lye.cheung.foo@intel.com', 'swee.tak.yap@intel.com', 'jen.seng.hong@intel.com', 'khang.lid.ooi@intel.com', 'yen.lee.eng@intel.com', 'yuree.kong.chau.tchong@intel.com', 'johnny.kee.hui.wong@intel.com', 'eric.soon.chwee.oh@intel.com');
	my $To = join('; ', @Tos);
	my($Subject, $Body) = ("I MISS YEN LEE & HUEY MIIN", "I MISS YEN LEE & HUEY MIIN!!!\nI will steal Huey Miin from Swee Tak...\nI will see Huey Miin in Oregon... :)\nDon't jealous, ar Swee Tak...\n\nWith love,\nKit Seong");

	&SendMail($To, '', $Subject, $Body);# || die "Cant send mail: $!\n";;

sub SendMail
{
	my($To, $Cc, $Subject, $Body) = @_;

	my $Mail = Win32::OLE->new('CDO.Message'); 
	$Mail->{From} = 'kit.seong.wong@intel.com'; 
	$Mail->{To} = $To;
	$Mail->{Cc} = $Cc if($Cc ne "");
	$Mail->{Subject} = $Subject;
	$Mail->{BodyFormat} = "CdoBodyFormatHTML";
	$Mail->{TextBody} = $Body;
	$Mail->Send();
	undef $Mail; 
}
