
&MyExcel();

sub MyExcel
{
	use Win32::OLE;
	use Win32::OLE::Variant;
	$ex = Win32::OLE->new('Excel.Application', \&OleQuit) or die "oops\n";
	$ex->{Visible} = 1;
	$ex->Workbooks->Add;

	# should generate a warning under -w
	$ovR8 = Variant(VT_R8, "3 is a good number");
	$ex->Range("A1")->{Value} = "LC Foo";
	$ex->Range("A2")->{Value} = Variant(VT_DATE, 'Jan 1,1970');
}

sub OleQuit 
{
	my $self = shift;
	$self->Quit;
}