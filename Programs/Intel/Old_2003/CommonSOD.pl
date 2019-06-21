use strict;
use warnings;
use Win32::OLE;
use Win32::ODBC;
use Time::Local;

sub OpenSOD
{
	my $dbSOD;
	my $UID = 'sa';
	my $PWD = 'sa';
	
	unless($dbCDIS = new Win32::ODBC("dsn=Scribe; DATABASE=Scribe; UID=$UID; PWD=$PWD"))
	{
		print "Error: " . Win32::ODBC::Error() . "\n";
		exit;
	}

	return $dbCDIS;
}

sub OpenARIES
{
	my $dbARIES;
	my $UID = 'discovery';
	my $PWD = '3WQL<)^I+'^'W>"/S_;;R';

	unless($dbARIES = new Win32::ODBC("dsn=ARIES; UID=$UID; PWD=$PWD"))
	{
		print "Error: " . Win32::ODBC::Error() . "\n";
		exit;
	}

	return $dbARIES;
}

sub ifSQL
{
	my ($db, $sql) = @_;
	&SendMail('soon.nyet.ho@intel.com;', '', 'SQL loading errors!', $sql);
	print "Error, SQL failed: " . $db->Error() . "\n";
	print "$sql\n";
	$db->Close();
	exit;
}


sub SendMail
{
	my($To, $Cc, $Subject, $Body) = @_;

	my $Mail = Win32::OLE->new('CDONTS.NewMail'); 
	$Mail->{From} = 'asblds@intel.com'; 
	$Mail->{To} = $To;
	$Mail->{Cc} = $Cc if($Cc ne "");
	$Mail->{Subject} = $Subject;
	$Mail->{Body} = $Body;
	$Mail->{Importance} = 2;
	$Mail->Send();
	undef $Mail; 
}


1
