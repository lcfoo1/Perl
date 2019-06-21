
use Win32::ODBC;
use Win32::OLE;

my $dbMARS = &OpenMARS;
&GetFabrun();
$dbMARS->Close();

# Subroutine to open connection to MARS database
sub OpenMARS
{
	my $DNS = "ARIESPRD_A01";
	unless($dbMARS = new Win32::ODBC("dsn=$DNS; UID=discovery; PWD=discovery"))
	{
		print "Error: " . Win32::ODBC::Error() . "\n";
		exit;
	}

	return $dbMARS;
}

sub ifSQL
{
	my ($db, $sql) = @_;
	my @To = ('lye.cheung.foo@intel.com');
	#&SendMail('SQL loading errors!', $sql, @To);
	print "Error, SQL failed: " . $db->Error() . "\n";
	print "$sql\n";
	$db->Close();
	exit;
}


# Subroutine to get lot's Fabrun attribute from MARS database
sub GetFabrun
{
	my %Temp;
	my $sql = "select * from A_Lot_at_operation where lot = 'L4220091'";

	if($dbMARS->Sql($sql))
	{
		&ifSQL($dbMARS, $sql);
	}
	else
	{
		while($dbMARS->FetchRow())
		{
			%Temp = $dbMARS->DataHash();
		}
	}

	foreach my $Line (keys %Temp)
	{
		print "$Temp{$Line}\n";
	}
}
