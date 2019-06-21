
use Win32::ODBC;
use Win32::OLE;

my @DeviceSBL = ();

open (FILESBL, "sbllimit.txt");
while(<FILESBL>)
{
	push (@DeviceSBL, $_);
}
close FILESBL;


my $dbMARS = &OpenMARS;
&GetFabrun();
$dbMARS->Close();


# Subroutine to open connection to MARS database
sub OpenMARS
{
	my $DNS = "pgssql901";
	unless($dbMARS = new Win32::ODBC("dsn=$DNS; UID=pdqre; PWD=pdqre"))
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
	print "Error, SQL failed: " . $db->Error() . "\n";
	print "$sql\n";
	$db->Close();
	exit;
}


# Subroutine to get lot's Fabrun attribute from MARS database
sub GetFabrun
{
	open (TEMP,">>LCFOOTEMP.txt");
	my %Temp;
	#foreach my $Device (@DeviceSBL)
	#{
		my $sql = "SELECT * FROM SBLLimits WHERE (Device LIKE '87MH96')";

		if($dbMARS->Sql($sql))
		{
			&ifSQL($dbMARS, $sql);
		}
		else
		{
			print $Device;
			while($dbMARS->FetchRow())
			{
				%Temp = $dbMARS->DataHash();
				print TEMP "$Temp{'GenericName'}\t$Temp{'Pkg'}\t$Temp{'Device'}\t$Temp{'Rev'}\t$Temp{'Step'}\t$Temp{'Locn1'}\t$Temp{'Bin1'}\t$Temp{'BinCondition'}\t$Temp{'Qty1'}\t$Temp{'Qty2'}\t$Temp{'Limit1'}\t$Temp{'Limit2'}\t$Temp{'Limit3'}\n";
				print "$Temp{'GenericName'}\t$Temp{'Pkg'}\t$Temp{'Device'}\t$Temp{'Rev'}\t$Temp{'Step'}\t$Temp{'Locn1'}\t$Temp{'Bin1'}\t$Temp{'BinCondition'}\t$Temp{'Qty1'}\t$Temp{'Qty2'}\t$Temp{'Limit1'}\t$Temp{'Limit2'}\t$Temp{'Limit3'}\n";
			}
		}
		#}
	close TEMP;
}


