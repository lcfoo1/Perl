
use Win32::ODBC;
use Win32::OLE;

my $dbEEVote = &OpenEEVote();
&CheckEEVote();
$dbEEVote->Close();

sub OpenEEVote
{
	my $dbNCOEEVote;
	my $UID = 'pdqre';
	my $PWD = 'pdqre';
	
	unless($dbNCOEEVote = new Win32::ODBC("dsn=Vote; UID=$UID; PWD=$PWD"))
	{
		print "Error: " . Win32::ODBC::Error() . "\n";
		exit;
	}

	return $dbNCOEEVote;
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



sub CheckEEVote
{
	my %Temp;
	my $sql = "select * from EEVote";

	if($dbEEVote->Sql($sql))
	{
		&ifSQL($dbEEVote, $sql);
	}
	else
	{
		while($dbEEVote->FetchRow())
		{
			%Temp = $dbEEVote->DataHash();
		}
	}

	foreach my $Line (keys %Temp)
	{
		print "$Temp{$Line}\n";
	}
}
