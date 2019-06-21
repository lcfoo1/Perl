use strict;
use warnings;
use Win32::OLE;
use Win32::ODBC;

my (%Lot, $LineValid, $LineInvalid);
my $ScribeDir = "C:\\FTP_Home\\ftpuser\\";
my $Now = &DateFormat();
my $Time = localtime(time);
my $MavNow = time();

&GetDatFile();
my $dbSOD = &OpenSOD();
&UploadScribeSOD();
$dbSOD->Close();

sub GetDatFile
{
	chdir $ScribeDir or die "Cannt change to directory $ScribeDir: $!\n";
	foreach my $DatFile (<*.dat>)
	{
		open (FILE, $DatFile) or die "Cannt open $DatFile: $!\n";
		while (<FILE>)
		{
			chomp;
			
			# This is for .dat upload scribe id (<lot#> <scribe id> <wafer id>)
			my ($LotNum, $Scribe, $WaferID) = ($1, $2, $3) if ($_ =~ /^([0-9a-zA-Z]+)\s+(.*)\s+([0-9a-zA-Z]{3})$/);

			# Allow maxmimum scribe id 1 time of spaces in between the scribe <data> <data>
			my @ChkScribeID = split (/\s+/, $Scribe);
			$Scribe = $1 if $Scribe =~ /(\S+\s+\S+)/;
			my $Slot = $1 if ($WaferID =~ /(\w{2})$/);

			if (($LotNum ne "") && ($Scribe ne "") && ($WaferID ne "") && ($#ChkScribeID <= 1) && (length($LotNum) == 8) && (length($WaferID) == 3) && (length($Scribe) <= 12))
			{
				push (@{$Lot{$Scribe}}, $LotNum, $WaferID, $Scribe, $Slot);
				$LineValid .= "Lot = $LotNum, Vendor Scribe = $Scribe, WaferID = $WaferID\t: PASS\n";
			}
			else 
			{
				if (($LotNum eq "") && ($Scribe eq "") && ($WaferID eq ""))
				{
					# Don't do anything, ignore empty line.
				}
				else
				{
					$LineInvalid .= "Lot = $LotNum, Vendor Scribe = $Scribe, WaferID = $WaferID\t: FAIL\n";
				}
			}
		}
		close FILE;
	}

}

# SOD primary key - vendor scribe id
sub UploadScribeSOD
{
	foreach my $CurLot (keys %Lot)
	{
		my $LotWaferDelFlag = 0;
		my $sql = "SELECT * FROM SCRIBE WHERE LOT = '$Lot{$CurLot}[0]' AND WAFER = '$Lot{$CurLot}[1]'";

		if($dbSOD->Sql($sql))
		{
			# If sql statment fail to load to SOD, trigger the developer
			print "Fail to connect to SOD\n";
		}
		else
		{
			while($dbSOD->FetchRow())
			{
				my @CheckDB = $dbSOD->Data();

				# Delete the scribe base on lot and wafer# same
				$sql = "DELETE FROM SCRIBE WHERE SCRIBE = '$CheckDB[2]'";

				if($dbSOD->Sql($sql))
				{
					&ifSQLSOD($Lot{$CurLot}[0], $sql);
					print "Fail to delete\n";
				}
				else
				{
					$LotWaferDelFlag = 1;
					print "Successful $sql on $Now\n";
				}
			}

			if (!$LotWaferDelFlag)
			{
				# Delete the scribe base on scribe id same
				$sql = "DELETE FROM SCRIBE WHERE SCRIBE = '$Lot{$CurLot}[2]'";

				if($dbSOD->Sql($sql))
				{
					print "Fail to delete base on scribe id\n";
				}
				else 
				{
					print "Delete base on scribe id\n";
				}
				$LotWaferDelFlag = 0;
			}

			

			$sql = "INSERT INTO SCRIBE (LOT, WAFER, SCRIBE, SLOT, LOADDATE) VALUES('$Lot{$CurLot}[0]', '$Lot{$CurLot}[1]', '$Lot{$CurLot}[2]', '$Lot{$CurLot}[3]', '$Now')";

			if($dbSOD->Sql($sql))
			{
				print "Fail to insert\n";
			}
			else
			{
				print "Inserted $sql on $Now\n";
			}

			
		}
	}

}




sub ifSQLSOD
{
	my ($sql) = shift;
	my $FailUploadFile = "C:\\FTP_Home\\ScribeFailToUploadToSOD\\".;
	my @To = ('lye.cheung.foo@intel.com');
	&SendMail("SOD: SQL loading errors from $File at $Time!", $sql, @To);
	print "Error, SQL failed: " . $dbSOD->Error() . "\n";
	print "$sql\n";
	move ($ScribeDirFile, $FailUploadFile);

	my $FailLog = "C:\\databroker\\logs\\ScribeUploadSOD\\ErrorLog\\FailUpload_".$Now.".log";
	open (FAIL, ">>$FailLog") or die "Cannt open $FailLog: $!\n";
	print FAIL "Error: " . Win32::ODBC::Error() . "\n";
	print FAIL "Statement fail: $sql\n";
	close FAIL;
}

sub SendMail 
{
	my($Subject, $Body, @To) = @_;
	my $MailHost = 'mail.intel.com';
	my $From = 'SCDataBroker@intel.com';
	my $Tos = join('; ', @To);
	my $smtp = Net::SMTP->new($MailHost);
	$smtp->mail($From);
	$smtp->to(@To);
	$smtp->data();
	$smtp->datasend("To: $Tos\n");
	$smtp->datasend("Subject: $Subject\n");
	$smtp->datasend("$Body\n");
	$smtp->dataend();
	$smtp->quit();
}










sub OpenSOD
{
	my $dbSOD;
	my $UID = 'sa';
	my $PWD = 'sa';
	
	unless($dbSOD = new Win32::ODBC("dsn=Scribe; DATABASE=Scribe; UID=$UID; PWD=$PWD"))
	{
		print "Error: " . Win32::ODBC::Error() . "\n";
		exit;
	}

	return $dbSOD;
}


sub DateFormat
{
	no warnings;
	my ($day, $month, $day, $time, $year) = split(/\s+/, localtime (time));
	my $Format = $day."-".$month."-".$year;
	return $Format;
}
