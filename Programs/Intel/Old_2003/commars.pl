use strict;
use warnings;
use Win32::OLE;
use Win32::ODBC;

sub OpenMARS
{
	my $dbMARS;
	my $Pwd = '%%B^(V[,'^'FJ/3w35K';

	unless($dbMARS = new Win32::ODBC("dsn=MARS; UID=comm_eng; PWD=$Pwd"))
	{
		print "Error: " . Win32::ODBC::Error() . "\n";
		exit;
	}

	return $dbMARS;
}

sub ifSQL
{
	my ($db, $sql) = @_;
	&SendMail('hou.wai.lai@intel.com;', '', 'SQL loading errors!', $sql);
	print "Error, SQL failed: " . $db->Error() . "\n";
	print "$sql\n";
	$db->Close();
	exit;
}

1
