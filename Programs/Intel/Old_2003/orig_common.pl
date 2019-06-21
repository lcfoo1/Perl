use strict;
use warnings;
use Win32::ODBC;
use Win32::OLE;

sub OpenServer
{
	my $db;

	unless($db = new Win32::ODBC("dsn=FLEX; UID=pdqre; PWD=pdqre"))
	{
		print "Error: " . Win32::ODBC::Error() . "\n";
		exit;
	}

	return $db;
}

sub OpenMARS
{
	my $dbMARS;

	unless($dbMARS = new Win32::ODBC("dsn=MARS; UID=comm_eng; PWD=comm_eng"))
	{
		print "Error: " . Win32::ODBC::Error() . "\n";
		exit;
	}

	return $dbMARS;
}

sub OpenILTS
{
	my $dbILTS;
	my $UID = 'valpvait';
	my $PWD = 'vick1234567*';

	unless($dbILTS = new Win32::ODBC("dsn=COLOMA; DATABASE=dcib01; UID=$UID; PWD=$PWD"))
	{
		print "Error: " . Win32::ODBC::Error() . "\n";
		exit;
	}

	return $dbILTS;
}

sub ifSQL
{
	my ($db, $sql) = @_;
	&SendMail('lye.cheung.foo@intel.com', '', 'SQL loading errors!', $sql);
	print "Error, SQL failed: " . $db->Error() . "\n";
	print "$sql\n";
	$db->Close();
	exit;
}

sub D2YYYYWW
{
	my %Temp;
	my ($db, $Input) = @_;
	my $sql = "exec sp_period_y2k '$Input', 'INTEL', 'doww', NULL, 1";

	if($db->Sql($sql))
	{
		&ifSQL($db, $sql);
	}
	else
	{
		while($db->FetchRow())
		{
			%Temp = $db->DataHash();
		}
	}

	return $Temp{ww};
}

sub YYYYWW2D
{
	my %Temp;
	my ($db, $Input) = @_;
	my $sql = "exec sp_period_y2k NULL, 'INTEL', 'ww', '$Input', 1";

	if($db->Sql($sql))
	{
		&ifSQL($db, $sql);
	}
	else
	{
		while($db->FetchRow())
		{
			%Temp = $db->DataHash();
		}
	}

	return $Temp{date};
}

sub Dec2Bin
{
	my $val = shift;
	my $result;
	my @bytes = ();

	if ($val =~ /^[\d\s]+$/)
	{
		@bytes = split(/ /, $val);

		foreach my $byte(@bytes)
		{
			$result = join('', unpack("B*", pack('N', $byte)));
			$result =~ s/^0{24}//;
		}
	}
	return ($result);
}

sub Bin2Dec
{
	my $val = shift;
	my @bits = ();
	my $pos = 1;
	my $result;

	if ($val =~ /^[01\s]+$/)
	{
		$val =~ s/\s//g;

		while(length($val) < 32)
		{
			$val = '0' . $val;
		}

		@bits = split(//, $val);

		foreach my $bit(reverse(@bits))
		{
			($result += $pos) if($bit);
			$pos *= 2;
		}
	}
	return ($result);
}

sub DateTime
{
	my($Operator, $Offset) = @_;
	my ($SS, $MI, $HH, $DD, $MM, $YYYY);

	no warnings;
	$Offset =~ s/^$/0/;
	
	if($Operator eq "-")
	{
		($SS, $MI, $HH, $DD, $MM, $YYYY) = localtime(time - $Offset);
	}
	elsif($Operator eq "+")
	{
		($SS, $MI, $HH, $DD, $MM, $YYYY) = localtime(time + $Offset);
	}
	else
	{
		($SS, $MI, $HH, $DD, $MM, $YYYY) = localtime(time);
	}

	$YYYY += 1900;
	$MM++;
	$MM =~ s/^(\d)$/0$1/;
	$DD =~ s/^(\d)$/0$1/;
	$HH =~ s/^(\d)$/0$1/;
	$MI =~ s/^(\d)$/0$1/;
	$SS =~ s/^(\d)$/0$1/;

	my $Now = "$MM/$DD/$YYYY $HH:$MI:$SS";
	return ($Now);
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
