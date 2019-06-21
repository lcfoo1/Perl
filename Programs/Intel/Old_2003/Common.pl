use strict;
use warnings;
use Win32::OLE;
use Win32::ODBC;
use Time::Local;

sub OpenServer
{
	my $db;
	my $Pwd = ',PLFW'^'\\4=42';
	
	unless($db = new Win32::ODBC("dsn=FLEX; UID=pdqre; PWD=$Pwd"))
	{
		print "Error: " . Win32::ODBC::Error() . "\n";
		exit;
	}

	return $db;
}

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

sub OpenILTS
{
	my $dbILTS;
	my $UID = 'lfoo1';
	my $PWD = 'Tukugawa04!';

	unless($dbILTS = new Win32::ODBC("dsn=COLOMA; UID=$UID; PWD=$PWD"))
	{
		print "Error: " . Win32::ODBC::Error() . "\n";
		exit;
	}

	return $dbILTS;
}

sub OpenCDIS
{
	my $dbCDIS;
	my $UID = 'AutoSBL';
	my $PWD = 'oREF99!c4'^'.\'1)j{mWA';
	
	unless($dbCDIS = new Win32::ODBC("dsn=CDIS; DATABASE=x500; UID=$UID; PWD=$PWD"))
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
	my ($result, @bytes);

	if($val =~ /^[\d\s]+$/)
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
	my ($result, @bits);
	my $pos = 1;

	if($val =~ /^[01\s]+$/)
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

sub FormatNow
{
	# Formats the current time into a date we recognise at Intel
	my $Now = time();
	$Now = $_[0] if @_;
	my ($ss, $mi, $hh, $dd, $mm, $yyyy) = localtime($Now);
	
	$yyyy += 1900;
	$mm++;
	$mm =~ s/^(\d)$/0$1/;
	$dd =~ s/^(\d)$/0$1/;
	$hh =~ s/^(\d)$/0$1/;
	$mi =~ s/^(\d)$/0$1/;
	$ss =~ s/^(\d)$/0$1/;

	return("$mm/$dd/$yyyy $hh:$mi:$ss");
}

sub DateAdd
{
	#################################################################################################
	#																								#
	# 	My interpretation of VB's function. 														#
	#																								#
	#	Format:- DateAdd(Interval, Number, Operation, Date)											#
	#																								#
	#	The interval argument has these settings:													#
	#																								#
	#	Setting	| Description																		#
	#	--------+------------																		#
	#		dd	| Day																				#
	#		hh	| Hour																				#
	#		mi	| Minute																			#
	#		ss	| Second																			# 
	#																								#
	#	I never liked trying to figure out what VB would do to the date, so I added in the			#
	#	operator where you can add(+), or subtract(-).												#
	#																								#
	#	The date format needs to be of type: mm/dd/yyyy hh24:mi:ss. If date is not specified		#
	#	it will default to seconds since epoch (now).												#
	#																								#
	#################################################################################################

	my ($Interval, $Number, $Operation, $Date) = @_;

	if($Date eq "")
	{
		$Date = time;
	}
	else
	{
		no warnings;
		my ($mm, $dd, $yyyy, $hh, $mi, $ss, $APM) = split /\D/, $Date;
		$hh += 12 if $APM =~ /PM/i;
		$Date = timelocal($ss, $mi, $hh, $dd, ($mm - 1), ($yyyy - 1900));
	}

	# Okay we have the date in seconds, now do what was requested
	if($Interval eq "dd")
	{
		$Number = $Number * 24 * 60 * 60;
	}
	elsif($Interval eq "hh")
	{
		$Number = $Number * 60 * 60;
	}
	elsif($Interval eq "mi")
	{
		$Number = $Number * 60;
	}
	elsif($Interval eq "ss")
	{
		$Number = $Number;
	}
	else{}

	if($Operation eq "-")
	{
		$Date -= $Number;
	}
	else
	{
		$Date += $Number;
	}

	# Thats what we want in seconds, so lets convert it to a date we recognise at Intel
	return &FormatNow($Date);
}

sub DateDiff
{
	#################################################################################################
	#																								#
	# 	My interpretation of VB's function. 														#
	#																								#
	#	Format:- DateDiff(Interval, Date1, Date2)													#
	#																								#
	#	The DateDiff syntax has these settings:														#
	#																								#
	#	Part		| Description																	#
	#	------------+---------------------------------------------------------------------			#
	#	Interval	| String expression that is the interval of time used to calculate the			#
	#				| difference. Format described above in DateAdd.								#
	#	Date1/Date2	| The two dates you want to use in the calculation. Format must be of			#
	#				| type: mm/dd/yyyy hh:mi:ss. If Date2 is not specified it will 					#
	#				| default to seconds since epoch (now). It's assumed that the user is			#
	#				| methodical, so Date1 and Date2 are in chronological order.					#
	#																								#
	#################################################################################################

	my($Interval, $Date1, $Date2) = @_;
	my ($Denominator, $Date);

	no warnings;
	my ($mm1, $dd1, $yyyy1, $hh1, $mi1, $ss1, $APM1) = split /\D/, $Date1;
	$hh1 += 12 if $APM1 =~ /PM/i;
	$Date1 = timelocal($ss1, $mi1, $hh1, $dd1, ($mm1 - 1), ($yyyy1 - 1900));

	if($Date2 eq "")
	{
		$Date2 = time;
	}
	else
	{
		my ($mm2, $dd2, $yyyy2, $hh2, $mi2, $ss2, $APM2) = split /\D/, $Date2;
		$hh2 += 12 if $APM2 =~ /PM/i;
		$Date2 = timelocal($ss2, $mi2, $hh2, $dd2, ($mm2 - 1), ($yyyy2 - 1900));
	}
	
	if($Interval eq "dd")
	{
		$Denominator = 24 * 60 * 60;
	}
	elsif($Interval eq "hh")
	{
		$Denominator = 60 * 60;
	}
	elsif($Interval eq "mi")
	{
		$Denominator = 60;
	}
	elsif($Interval eq "ss")
	{
		$Denominator = 1;
	}
	else{}

	$Date = sprintf "%.1f", ($Date2 - $Date1) / $Denominator;
	return($Date);
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
