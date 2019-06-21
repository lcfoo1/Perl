

use Win32::ODBC;
use Win32::OLE;

my %MARSDBProduct = ():
my $dbMARS = &OpenMARS;
&GetMARSDBProduct();
$dbMARS->Close();

# Subroutine to open connection to MARS database
sub OpenMARS
{
	my $DNS = "MARS";
	unless($dbMARS = new Win32::ODBC("dsn=$DNS; UID=asblds; PWD=asblds"))
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


sub GetMARSDBProduct
{
	my %Temp;
	my $sql = "SELECT F_LOTSPLITHIST_V.LOT, F_LOTSPLITHIST_V.TXN_DATE, F_LOTSPLITHIST_V. FROM_TO_LOT AS LOT, F_LOTSPLITHIST_V.FROM_TO_PRODUCT AS PRODUCT " .
		  "FROM A11_PROD_5.F_LOTSPLITHIST_V " .
		  "WHERE F_LOTSPLITHIST_V.TXN_DATE >= TO_DATE('01/27/2005 10:00:00', 'MM/DD/YYYY HH24:MI :SS') AND " .
		  "F_LOTSPLITHIST_V.TXN_DATE < TO_DATE('01/27/2005 10:30:00', 'MM/DD/YYYY HH24:MI: SS') AND " .
		  "F_LOTSPLITHIST_V.OPERATION = '0011' AND F_LOTSPLITHIST_V.TRANSACTION = 'SPLT' " .
		  "AND (F_LOTSPLITHIST_V.LOT LIKE 'Z%' OR F_LOTSPLITHIST_V.LOT LIKE 'M%') " .
		  "ORDER BY F_LOTSPLITHIST_V.TXN_DATE";

	if($dbMARS->Sql($sql))
	{
		&ifSQL($dbMARS, $sql);
	}
	else
	{
		while($dbMARS->FetchRow())
		{
			%Temp = $dbMARS->DataHash();
			my $Lot = $Temp{LOT}
			my $PRODUCT = $Temp{PRODUCT};
			my $PKG = substr($PRODUCT, 0, 2);
			my $DEVICE = substr($PRODUCT, 2, 6); 
			my $REV = substr($PRODUCT, 9, 1);
			my $STEP = substr($PRODUCT, 11, 1); 
			my $ROM = substr($PRODUCT, 12, 1);
			my $ENGID = substr($PRODUCT, 13, 2); 
			my $ASSM = substr($PRODUCT, 15, 1); 
			my $SPEC = substr($PRODUCT, 16, 4); 
			my $FAB = substr($PRODUCT, 20, 1);
			$MARSDBProduct{$Lot} = [ $PRODUCT, $PKG, $DEVICE, $REV, $STEP, $ROM, $ENGID, $ASSM, $SPEC, $FAB]
			#print "MY data: $Lot, $PRODUCT, $PKG, $DEVICE, $REV, $STEP, $ROM, $ENGID, $ASSM, $SPEC, $FAB\n";
		}
	}
}


