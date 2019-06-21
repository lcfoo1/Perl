#########################################################################################################
#													#
#				Sort/Class Data Broker							#
#													#
#########################################################################################################
#													#
#	Foo Lye Cheung		PE Sort Automation							#
#	02/12/2004											#
#													#
#	UploadMavSOD.pl is to upload vendor scribe id to Maverick database and SOD.			#
#													#
#	NOTES												#
#	Requires CONNX 8, Perl5 and Win32::ODBC, Win32::OLE, File::Copy and Net::SMTP to run.		#
#													#
#													#
#	Send mail to notify IT if the Scribe ID unable to load to Maverick database and SOD DB.		#
#													#
#	The scripts copy the .dat file to E:\FTP_Home\ftpuser\MavScribeID\ before uploading scribe	#
#	id to Maverick database. Upon successful uploading the scribe id to Maverick, the file		#
#	will be move to E:\FTP_Home\ftpuser\SODScribeID\ to be upload to SOD.				#
#	If .dat file is bad when uploading it to Maverick, the bad .dat file will be move to		#
#	E:\FTP_Home\ScribeFailToUploadToSOD\ for further investigation and IT will be triggered by	#
#	email. Bad .dat file uploading to SOD will be move to E:\FTP_Home\ScribeFailToUploadToSOD\	#
#	and IT will also be triggered by email.								#
#													#
#	clean.pl and clean.ini are used to clean old log files						#
#													#
#	REV 3.0												#
#													#
#	Modified 03/07/2004 by Lye Cheung								#
#	Added more strict rules to check the scribe id, lot# - 8 characters(0-9, a-z and A-Z), 		#
#	wafer id - 3 characters(0-9, a-z and A-Z) and scribe id - 12 character or less (allow 1 time	#
#	spaces).											#
#													#
#########################################################################################################

use Win32::ODBC;
use Win32::OLE;
use Net::SMTP;
use File::Copy;

#########################################################################################################
#	Main variables and program start below here							#
#													#
#########################################################################################################

#my $MainScribeDir = "E:\\FTP_Home\\ftpuser\\";
#my $SODScribeDir = "E:\\FTP_Home\\ftpuser\\SODScribeID\\";
#my $MavScribeDir = "E:\\FTP_Home\\ftpuser\\MavScribeID\\";
my $MainScribeDir = "C:\\FTP_Home\\ftpuser\\";
my $SODScribeDir = "C:\\FTP_Home\\ftpuser\\SODScribeID\\";
#my $MavScribeDir = "C:\\FTP_Home\\ftpuser\\MavScribeID\\";
my $Now = &DateFormat();
my $Time = localtime(time);
my $MavNow = time(); 

print "Running script upload scribe ID to Maverick and SOD ...\n";
print "=======================================================\n\n";

chdir $MainScribeDir or die "Cannt change to directory $MainScribeDir: $!\n";
foreach my $File (<*.dat>) 
{
	print "$File\n";
	my $MainScribeFile = $MainScribeDir.$File;
	my $MavScribeFile = $MavScribeDir.$File;
	copy($MainScribeFile, $MavScribeFile);
	unlink "$MainScribeFile" or die "Cannt unlink $MainScribeFile: $!\n";
}

# Upload the vendor scribe ID to Maverick
#my $dbMav = &OpenMav;
#&UploadScribeToMav();
#$dbMav->Close();

# Upload the vendor scribe ID to SOD
my $dbSOD = &OpenSOD();
&UploadScribeToSOD();
$dbSOD->Close();

print "***Exiting script upload scribe ID to Maverick and SOD ...***\n";

#########################################################################################################
#													#
#	Main variables and program end here								#
#													#
#########################################################################################################

sub UploadScribeToMav
{
	my $ScribeFileFlag = 0;
	my $PassMavFlag = 0;
	my $LineData;
	chdir $MavScribeDir or die "Cannt change to directory $MavScribeDir: $!\n";

	foreach my $DatFile (<*.dat>) 
	{
		my %Lot;
		my $LogFile = $1.".log" if ($DatFile =~ /^(\w+)\.dat$/);

		print "Maverick upload vendor scribe id\n";

		open (FILE, $DatFile) or die "Cannt open $DatFile: $!\n";
		while (<FILE>)
		{
			chomp;
			
			# This is for Maverick upload scribe id (<lot#> <scribe id> <wafer id>)
			my ($LotNum, $Scribe, $WaferID) = ($1, $2, $3) if ($_ =~ /^([0-9a-zA-Z]\w+)\s+(.*)\s+([0-9a-zA-Z]{3})$/);

			# Allow maxmimum scribe id 1 time of spaces in between the scribe <data> <data>
			my @ChkScribeID = split (/\s+/, $Scribe);
			$Scribe = $1 if $Scribe =~ /(\S+\s+\S+)/;

			print "Maverick: Lot= $LotNum, Scribe = $Scribe, WaferID = $WaferID\n";
			if (($LotNum ne "") && ($Scribe ne "") && ($WaferID ne "") && ($#ChkScribeID <= 1) && (length($LotNum) == 8) && (length($WaferID) == 3) && (length($Scribe) <= 12))
			{
				push (@{$Lot{$Scribe}}, $LotNum, $WaferID, $Scribe, $Slot);
				$LineData .= "Lot = $LotNum, Vendor Scribe = $Scribe, WaferID = $WaferID\t: PASS\n";
			}
			else 
			{
				if (($LotNum eq "") && ($Scribe eq "") && ($WaferID eq ""))
				{
					# Don't do anything, ignore empty line.
				}
				else
				{
					$PassMavFlag = 1;
					$LineData .= "Lot = $LotNum, Vendor Scribe = $Scribe, WaferID = $WaferID\t: FAIL\n";
				}
			}
		}
		close FILE;

		if ($PassMavFlag) 
		{
			$sql = "File: $DatFile has invalid data\nFound corrupt data:\n$LineData\n";
			$LineData = "";
			$PassMavFlag = 0;
			my $ScribeDirFile = $MavScribeDir.$DatFile;
			my $SODFile = $SODScribeDir.$DatFile;
			copy($ScribeDirFile, $SODFile);

			&ifSQLMav($ScribeDirFile, $DatFile, $dbMav, $sql);	
		}
		else
		{
			#my $GoodScribeFile = "E:\\FTP_Home\\OldGoodScribe\\".$DatFile;
			my $GoodScribeFile = "C:\\FTP_Home\\OldGoodScribe\\".$DatFile;
			copy ($DatFile, $GoodScribeFile);
		}
		
		foreach my $Key(keys %Lot)
		{
			my $ScribeExistFlag = 0;
			my @CheckDB;
			my $ScribeDirFile = $MavScribeDir.$DatFile;

			# Check the scribe id table
			my $sql = "SELECT * FROM SCRIBE_TABLE WHERE vendorScribe = '$Lot{$Key}[2]' and lotNumber = '$Lot{$Key}[0]' and waferName = '$Lot{$Key}[1]'";
			if($dbMav->Sql($sql))
			{
				# If sql statment fail to load to Mav, trigger the developer
				&ifSQLMav($ScribeDirFile, $DatFile, $dbMav, $sql);
				$ScribeFileFlag = 1;
			}
			else
			{
				while($dbMav->FetchRow())
				{
					# If the vendor scribe id, Wafer ID and lot# exist in the Maverick database, SOD won't upload the .dat file
					# and trigger email to IT support. Bad .dat file is move to E:\FTP_Home\ScribeFailToUploadToMav\
					$ScribeFileFlag = 1;
					$ScribeExistFlag = 1;
					@CheckDB = $dbMav->Data();

					print "Maverick not allow to update: $ScribeDirFile\n";
					$sql = "File: $DatFile is bad\nFound lot#, wafer# and vendorscribe from scribe table\n$sql\n***These field cannot be change in Maverick***";
					&ifSQLMav($ScribeDirFile, $DatFile, $dbMav, $sql);
					print "Found @CheckDB - no update: $sql\n";
					#my $SODFile = $SODScribeDir.$DatFile;
					#unlink "$SODFile"; # or die "Cannt unlink $SODFile: $!\n";
					goto FailMav;
				}

				# Insert scribe id if did not exist on the table
				if (!$ScribeExistFlag) 
				{
					# Insert scribe id if did not exist on the table
					$sql = "INSERT INTO SCRIBE_TABLE (lotNumber, waferName, vendorScribe, intelWaferName, dateCreated) VALUES('$Lot{$Key}[0]', '$Lot{$Key}[1]', '$Lot{$Key}[2]', ' ', '$MavNow')";
					if($dbMav->Sql($sql))
					{
						&ifSQLMav($ScribeDirFile, $DatFile, $dbMav, $sql);
						$ScribeFileFlag = 1;
					}
					else
					{
						#my $InsertSqlLogFile = "E:\\databroker\\logs\\ScribeUploadMav\\InsertLog\\".$Now."_".$LogFile;
						my $InsertSqlLogFile = "C:\\databroker\\logs\\ScribeUploadMav\\InsertLog\\".$Now."_".$LogFile;
						open (INSERTSQL, ">>$InsertSqlLogFile") or die "Cannt log $InsertSqlLogFile: $!\n";
						print INSERTSQL "Inserted $sql on $Now\n";
						close INSERTSQL;
						print "Inserted $sql on $Now\n";
					}
				}
			}
		}

		FailMav:

		if (!$ScribeFileFlag) 
		{
			#print "Moving good .dat file to SOD $DatFile\n";
			my $SODScribeFile = $SODScribeDir.$DatFile;
			move($DatFile, $SODScribeFile);
		}
		$ScribeFileFlag = 0;
		undef %Lot;
	}
}

sub OpenMav
{
	my $dbMav;
	unless($dbMav = new Win32::ODBC("dsn=prodmav; UID=sortmav; PWD=donaldduck3"))
	{
		print "Error: " . Win32::ODBC::Error() . "\n";
		my $Body = "ODBC Error:\n".Win32::ODBC::Error();
		my @To = ('lye.cheung.foo@intel.com'); 
		&SendMail("Unable to connect to Maverick at $Time!", $Body, @To);
		my $FailLog = "E:\\databroker\\logs\\ScribeUploadMav\\ErrorLog\\FailMav_".$Now.".log";
		open (FAIL, ">>$FailLog") or die "Cannt open $FailLog: $!\n";
		print FAIL "Error: " . Win32::ODBC::Error() . "\n";
		close FAIL;
		exit;
	}
	return $dbMav;
}

sub ifSQLMav
{
	my ($ScribeDirFile, $File, $dbMav, $sql) = @_;
	my $FailUploadFile = "E:\\FTP_Home\\ScribeFailToUploadToMav\\".$File;
	my @To = ('lye.cheung.foo@intel.com'); 
	&SendMail("Maverick: SQL loading errors from $File at $Time!", $sql, @To);
	print "Error, SQL failed: " . $dbMav->Error() . "\n";
	#print "$sql\n";

	move ($ScribeDirFile, $FailUploadFile);

	#my $FailLog = "E:\\databroker\\logs\\ScribeUploadMav\\ErrorLog\\FailUpload_".$Now.".log";
	my $FailLog = "C:\\databroker\\logs\\ScribeUploadMav\\ErrorLog\\FailUpload_".$Now.".log";
	open (FAIL, ">>$FailLog") or die "Cannt open $FailLog: $!\n";
	print FAIL "Error: " . Win32::ODBC::Error() . "\n";
	print FAIL "Statement fail: $sql\n";
	close FAIL;
}






























sub UploadScribeToSOD
{
	my $ScribeFileFlag = 0;
	my $LineData;
	my $PassSODFlag = 0;
	chdir $SODScribeDir or die "Cannt change to directory $SODScribeDir: $!\n";

	foreach my $DatFile (<*.dat>) 
	{
		my %Lot;
		my $LogFile = $1.".log" if ($DatFile =~ /^(\w+)\.dat$/);

		print "SOD upload vendor scribe id\n";

		open (FILE, $DatFile) or die "Cannt open $DatFile: $!\n";
		while (<FILE>)
		{
			chomp;
			
			# This is for SOD upload scribe id (<lot#> <scribe id> <wafer id>)
			my ($LotNum, $Scribe, $WaferID) = ($1, $2, $3) if ($_ =~ /^([0-9a-zA-Z]\w+)\s+(.*)\s+([0-9a-zA-Z]{3})$/);
			
			# Allow maxmimum scribe id 1 time of spaces in between the scribe <data> <data>
			my @ChkScribeID = split (/\s+/, $Scribe);
			$Scribe = $1 if $Scribe =~ /(\S+\s+\S+)/;
			
			# This is for the SOD and Maverick upload scribe id <lot#> <scribe id><wafer id>
			my $Slot = $1 if ($WaferID =~ /(\w{2})$/);
			print "SOD: Lot= $LotNum, Scribe = $Scribe, WaferID = $WaferID, Slot=$Slot\n";

			if (($LotNum ne "") && ($Scribe ne "") && ($WaferID ne "") && ($#ChkScribeID <= 1) && (length($LotNum) == 8) && (length($WaferID) == 3) && (length($Scribe) <= 12))
			{
				push (@{$Lot{$Scribe}}, $LotNum, $WaferID, $Scribe, $Slot);
				$LineData .= "Lot = $LotNum, Vendor Scribe = $Scribe, WaferID = $WaferID\t: PASS\n";
			}
			else 
			{
				if (($LotNum eq "") && ($Scribe eq "") && ($WaferID eq ""))
				{
					# Don't do anything, ignore empty line.
				}
				else
				{
					$PassSODFlag = 1;
					$LineData .= "Lot = $LotNum, Vendor Scribe = $Scribe, WaferID = $WaferID\t: FAIL\n";
				}
			}
		}
		close FILE;

		if ($PassSODFlag) 
		{
			$sql = "File: $DatFile has invalid data\nFound corrupt data:\n$LineData\n";
			$LineData = "";
			$PassSODFlag = 0;
			my $ScribeDirFile = $SODScribeDir.$DatFile;
			&ifSQLSOD($ScribeDirFile, $DatFile, $dbSOD, $sql);	
		}
		else
		{
			#my $GoodScribeFile = "E:\\FTP_Home\\OldGoodScribe\\".$DatFile;
			my $GoodScribeFile = "C:\\FTP_Home\\OldGoodScribe\\".$DatFile;
			copy ($DatFile, $GoodScribeFile);
		}

		foreach my $Key(keys %Lot)
		{

			my @CheckDB;
			my $ScribeExistFlag = 0;
			my $ScribeDirFile = $SODScribeDir.$DatFile;
			
			# Check the scribe id table
			my $sql = "SELECT * FROM SCRIBE WHERE (SCRIBE = '$Lot{$Key}[2]')";
			if($dbSOD->Sql($sql))
			{
				# If sql statment fail to load to SOD, trigger the developer
				&ifSQLSOD($ScribeDirFile, $DatFile, $dbSOD, $sql);
				$ScribeFileFlag = 1;
			}
			else
			{
				while($dbSOD->FetchRow())
				{
					@CheckDB = $dbSOD->Data();
					$ScribeExistFlag = 1;

					# Update the scribe id table
					$sql = "UPDATE SCRIBE SET LOT = '$Lot{$Key}[0]', WAFER = '$Lot{$Key}[1]', SLOT = '$Lot{$Key}[3]', LOADDATE = '$Now' WHERE SCRIBE = '$Lot{$Key}[2]'";
					if($dbSOD->Sql($sql))
					{
						&ifSQLSOD($ScribeDirFile, $DatFile, $dbSOD, $sql);
						$ScribeFileFlag = 1;
					}
					else
					{
						#my $UpdateSqlLogFile = "E:\\databroker\\logs\\ScribeUploadSOD\\UpdateLog\\".$Now."_".$LogFile;
						my $UpdateSqlLogFile = "C:\\databroker\\logs\\ScribeUploadSOD\\UpdateLog\\".$Now."_".$LogFile;
						open (UPDATESQL, ">>$UpdateSqlLogFile") or die "Cannt log $UpdateSqlLogFile: $!\n";
						print UPDATESQL "Deleted @CheckDB on $Now\n";
						print UPDATESQL "$sql on $Now\n";
						close UPDATESQL;
						print "Found @CheckDB and being update with $sql\n";
					}
				}

				# Insert scribe id if did not exist on the table
				if (!$ScribeExistFlag) 
				{
					$sql = "INSERT INTO SCRIBE (LOT, WAFER, SCRIBE, SLOT, LOADDATE) VALUES('$Lot{$Key}[0]', '$Lot{$Key}[1]', '$Lot{$Key}[2]', '$Lot{$Key}[3]', '$Now')";
					if($dbSOD->Sql($sql))
					{
						&ifSQLSOD($ScribeDirFile, $DatFile, $dbSOD, $sql);
						$ScribeFileFlag = 1;
					}
					else
					{
						#my $InsertSqlLogFile = "E:\\databroker\\logs\\ScribeUploadSOD\\InsertLog\\".$Now."_".$LogFile;
						my $InsertSqlLogFile = "C:\\databroker\\logs\\ScribeUploadSOD\\InsertLog\\".$Now."_".$LogFile
						open (INSERTSQL, ">>$InsertSqlLogFile") or die "Cannt log $InsertSqlLogFile: $!\n";
						print INSERTSQL "Inserted $sql on $Now\n";
						close INSERTSQL;
						print "Inserted $sql on $Now\n";
					}
				}
			}
		}

		if ($ScribeFileFlag) 
		{
			# bad .dat file to be upload to SOD will be move to E:\FTP_Home\ScribeFailToUploadToSOD\ without unlink.
		}
		else
		{
			unlink "$DatFile"; # or die "Cannt unlink $DatFile: $!\n";
		}
		undef %Lot;
		$ScribeFileFlag = 0;
	}
}

sub OpenSOD
{
	my $dbSOD;
	unless($dbSOD = new Win32::ODBC("dsn=sod; UID=soddba; PWD=soddba"))
	{
		print "Error: " . Win32::ODBC::Error() . "\n";
		my $Body = "ODBC Error:\n".Win32::ODBC::Error();
		my @To = ('lye.cheung.foo@intel.com');
		&SendMail("Unable to connect to SOD at $Time!", $Body, @To);
		#my $FailLog = "E:\\databroker\\logs\\ScribeUploadSOD\\ErrorLog\\FailSOD_".$Now.".log";
		my $FailLog = "C:\\databroker\\logs\\ScribeUploadSOD\\ErrorLog\\FailSOD_".$Now.".log";
		open (FAIL, ">>$FailLog") or die "Cannt open $FailLog: $!\n";
		print FAIL "Error: " . Win32::ODBC::Error() . "\n";
		close FAIL;
		exit;
	}
	return $dbSOD;
}

sub ifSQLSOD
{
	my ($ScribeDirFile, $File, $dbSOD, $sql) = @_;
	#my $FailUploadFile = "E:\\FTP_Home\\ScribeFailToUploadToSOD\\".$File;
	my $FailUploadFile = "C:\\FTP_Home\\ScribeFailToUploadToSOD\\".$File;
	my @To = ('lye.cheung.foo@intel.com');
	&SendMail("SOD: SQL loading errors from $File at $Time!", $sql, @To);
	print "Error, SQL failed: " . $dbSOD->Error() . "\n";
	print "$sql\n";

	move ($ScribeDirFile, $FailUploadFile);

	#my $FailLog = "E:\\databroker\\logs\\ScribeUploadSOD\\ErrorLog\\FailUpload_".$Now.".log";
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

sub DateFormat
{
	my ($day, $month, $day, $time, $year) = split(/\s+/, localtime (time));
	my $Format = $day."-".$month."-".$year;
	return $Format;
}
