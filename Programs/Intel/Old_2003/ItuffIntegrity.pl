#################################################################################################
#																								#	
#	Foo Lye Cheung		PE Sort Automation														#
#	10/31/2003																					#
#																								#
#	This script is part of SC SOD DataBroker.													#
#	This script is called when it detects sort signal file at directory							#
#	Upon detecting the signal file, the script check the ituff summary							#
#	from the temperorary ituff directory. 														#
#																								#
#	NOTES																						#
#	Requires Perl5 and File::Copy, Win32::OLE and Net::SMTP to run.								#
#	ItuffIntegrity.pl requires an Oracle ODBC													#
#																								#
#	Send mail to notify PE if error found on ituff summary and Fabrun not found from Mars		#
#																								#
#	Rev 1.0																						#
#																								#
#	Modified 12/1/2003 by Lye Cheung															#
#	Modified so that the data integrity script only for S9K & HP94K tester						#
#	Also modified the script able to identified different NETAPPS path for S9K and HP94K		#
#	tester.																						#
#																								#
#	Modified 04/07/2004 by Lye Cheung															#
#	Modified so that the data broker able to upload all ituff summary as data broker			#
#	itself unable to handle big process e.g. more than 25 ituff summary from NETAPP server		#
#	although I already include copy to local drive before processing the ituff.					#
#	Requires Copy.pl to bind with data broker to remove the missing loading ituff summary		#
#	as separate script to copy all the ituff files by data broker								#
#																								#	
#	Modified 04/08/2004 by Lye Cheung															#
#	Modified to limit that only 600 x-y coordinate displayed on the duplicate ituff for			#
#	HP94K tester. Enhance the codes, where all the processing is done at the temperorary		#
#	data directory before routing to be upload to SOD											#
#																								#
#	Modified 04/27/2004 by Lye Cheung															#
#	Get Sort Name (Level3 Name) from MARS db and change the token from 6_prdct_<marketing name>	#
#	to 6_prdct_<Sort Name> for BLS linkage														#
#																								#
#################################################################################################

use Win32::OLE;
use Net::SMTP;
use Win32::ODBC;
use File::Copy;

#################################################################################################
#	Main program and global variables for processing the ituff summary							#	
#################################################################################################

my $databroker_configfile = $ARGV[0];
my $databroker_xmltag = $ARGV[1];
my $databroker_signalfile = $ARGV[2];

#################################################################################################
#																								#
#	This part is reading from the file Executive_config.xml										#
#																								#
#################################################################################################

my $OrgItuffFile;
my ($Basename, $Datalog, $Lot_Locn, $Wafer) = split(/\=\=/,$databroker_signalfile);
($Wafer, $ext) = split (/\./,$Wafer);

my ($Signal,$InputStaging,$OutputStaging,$Converter) = &parse_xml($databroker_xmltag,$databroker_configfile);
my ($Lot, $Locn_8012, $Locn__A) = split (/\_/, $Lot_Locn);

# Mapping to NetApps Ituff summary for S9K
# The S9K tester ituff summary located at /db1/s9k/sort/s9kaccess/sort/datalogs/
if (($Locn__A eq "A") and ($Locn_8012 eq ""))
{
	$OrgItuffFile =  "e:\\datadirectory\\sort\\iTUFF\\temp\\${Lot_Locn}\\${Wafer}";
	print "S9K Tester: $OrgItuffFile\n";
}
# Mapping to NetApps Ituff summary for HP94K
# The HP94K tester ituff summary located at /lopte/intel/hp94k/sort/aries/data/ituff/
elsif ((($Locn__A eq "") and ($Locn_8012 eq "8012")) || (($Locn__A eq "") and ($Locn_8012 eq "8112")))
{
	$OrgItuffFile =  "${InputStaging}\\${Lot_Locn}\\${Wafer}";
	print "HP94K Tester: $OrgItuffFile\n";
}
else
{
	#Others tester, eg. Tiger, etc.
	die "Dont know which tester and the ituff path\n";
}

#	open (FILE1, ">>C:\\lcfoo1.txt");
#	print FILE1 "0 $Lot, $Lot_Locn, $Wafer or $databroker_signalfile :: $OrgItuffFile\n";
#	close FILE1;
#	exit;

# Output staging directory
my $OutputStagingDir = $OutputStaging; 

#################################################################################################
#																								#
#	Main program for processing the ituff summary												#
#																								#
#################################################################################################

my $SortName ="";
my $Now = localtime(time);
my $dbMARS = &OpenMARS;

&GetLots();
$dbMARS->Close();

#################################################################################################
#																								#
#	End of main program																			#
#																								#
#################################################################################################

# Subroutine to parse the databroker executive_config.xml
sub parse_xml 
{
	my ($databroker_xmltag,$databroker_configfile) = @_;
	my ($ConversionNode,$Number_Of_Items,$num,$attr,$item,$itemtext,$Signal,$InputStaging,$OutputStaging,$Converter);
	my $DOM_document = Win32::OLE->new('MSXML2.DOMDocument') or die "couldn't create";
	$DOM_document->{async} = "False";           # disable asynchrous
	$DOM_document->{validateOnParse} = "True";  # validate
	my $boolean_Load = $DOM_document->Load("$databroker_configfile");
	if (!$boolean_Load) 
	{
		die "$databroker_configfile did not load";
	}

	#############################################################################################
	#																							#
	#	Pull Information for the specific XML TypeName passed by the Executive.					#
	#																							#
	#############################################################################################

	$ConversionNode = $DOM_document->selectSingleNode("//Conversion");
	$Number_Of_Items = $ConversionNode->childNodes->{length};

	for ($num = 0; $num < $Number_Of_Items; $num++) 
	{
		$attr = $ConversionNode->childNodes()->item($num)->{attributes};
		foreach my $item (in $attr) # make sure you include the 'in'
		{
			$itemtext = $item->{Text};
			if ($itemtext eq $databroker_xmltag) 
			{
				$Signal = $ConversionNode->childNodes()->item($num)->selectSingleNode("Signal");
				$InputStaging = $ConversionNode->childNodes()->item($num)->selectSingleNode("InputStaging");
				$OutputStaging = $ConversionNode->childNodes()->item($num)->selectSingleNode("OutputStaging");			
				$Converter = $ConversionNode->childNodes()->item($num)->selectSingleNode("Converter");
			} 
		} 
	}
	return($Signal->{Text},$InputStaging->{Text},$OutputStaging->{Text},$Converter->{Text});
}

# Subroutine to open connection to MARS database
sub OpenMARS
{
	my $dbMARS;
	my $PWD = ']KH%C:5'^'0$&V,U[';

	unless($dbMARS = new Win32::ODBC("dsn=MARS; UID=monsoon; PWD=$PWD"))
	{
		print "Error: " . Win32::ODBC::Error() . "\n";
		exit;
	}
	return $dbMARS;
}

# Subroutine to get lot number from file to obtain fablot attribute from MARS database
sub GetLots
{
	my $PrevLot = "Null";
	
	chomp $OrgItuffFile;
	my $Fabrun = &GetFabrun($Lot);

	$SortName = &GetSortName($Lot);
	chomp ($SortName);

	# Remove the S and package name, and spaces in between
	$SortName = $1 if ($SortName =~ /^S\s+(.*)\s+\w+$/);
	my @tmp = split (/\s+/, $SortName);
	$SortName = join ('', @tmp);
	
	chomp($Fabrun);
	
	# If Fabrun = null then send mail notify PE else update remote file with fabrun
	if (($Fabrun eq "NULL") && ($Lot ne ""))
	{
		print "PreviousLot = $PrevLot\n";
		if($Lot ne $PrevLot)
		{
			#my @To = ('lye.cheung.foo@intel.com');
			my @To = ('lye.cheung.foo@intel.com', 'ching.tatt.teoh@intel.com');
			#my @To = ('lye.cheung.foo@intel.com', "david.ch'ng\@intel.com", 'ching.tatt.teoh@intel.com', 'seong.ngok.koo@intel.com', 'shi.ling.tan@intel.com', 'ee.chuangx.choong@intel.com', 'kai.jiunnx.loi@intel.com');
			my $Subject = "Fabrun not found for $Lot"; 
			my $Body = 
				"Fabrun not found for $Lot, Please rerun the Lot manually once the Fabrun found from Mars


	                  	 * * * PLEASE DO NOT REPLY TO THIS MAIL * * *";
			 
			&SendMail($Subject, $Body, @To);
			print "Mail sent for error reporting\n";

			# Capture the lot which no fabrun found from MARS to rerun lot daily for fabrun 
			my $Rerun = ">>E:\\databroker\\logs\\DataIntegrity\\LotRerun.txt";
			open(Lotrerun, "$Rerun") || die "$Rerun:- $!\n";		
			print Lotrerun "Rerun Lot: No Fabrun: $OrgItuffFile at $Now\n";
			close(Lotrerun);
		}
	}
	else
	{
		my $UpdatedFile = &CheckTester ($Lot, $Fabrun, $OrgItuffFile);
		$PrevLot = $Lot;

		my @chkerror = split(/\s+/,$UpdatedFile);
		my $Fabrun = &GetFabrun($Lot);
		my $Chkstatus = 0;
		my $FailFile =	"/lopte/intel/hp94k/sort/aries/data/ituff/${Lot}_8012/$Wafer";

		# Checking duplication occurence	
		if ($chkerror[6] eq "DUP")
		{
			$Chkstatus = 1;
			my @To = ('lye.cheung.foo@intel.com', 'ching.tatt.teoh@intel.com');
			#my @To = ('lye.cheung.foo@intel.com', "david.ch'ng\@intel.com", 'ching.tatt.teoh@intel.com', 'seong.ngok.koo@intel.com', 'shi.ling.tan@intel.com', 'ee.chuangx.choong@intel.com', 'kai.jiunnx.loi@intel.com');
			#my @To = ('lye.cheung.foo@intel.com');  

			# On the subject line it will print the real file name
			my $Subject = "Duplicate occured on $FailFile"; 
			my $Body = 
				"Duplication occured on the ITUFF summary - $FailFile with Fabrun=$Fabrun 
Device: $chkerror[12], WWID: $chkerror[8], Start Date: $chkerror[9], End Date: $chkerror[11], Time: $chkerror[10]

At coordinate:	$chkerror[7] 

 	                  	 * * * PLEASE DO NOT REPLY TO THIS MAIL * * *";
				 
			&SendMail($Subject, $Body, @To);
			
			# Create a duplicate log file ERROR.log
			&ErrorLog($chkerror[0], $Fabrun, $Chkstatus, $Lot);
			
			# Display on the screen the duplication information
			print "Duplicate at $chkerror[0] with Fabrun=$Fabrun\n";
			print "Mail sent for error reporting\n";
			$Chkstatus = 0;
		}

		# Checking for mismatch x-min, x-max, y-min, y-max		
		if (($chkerror[2] eq "NOT_MATCH") && ($chkerror[6] eq "NODUP"))
		{
			$Chkstatus = 2;
			#my @To = ('sook.leng.low@intel.com', 'soon.ee.chung@intel.com', 'soo.ling.chuah@intel.com', 'chee.juan.tan@intel.com', 'lye.cheung.foo@intel.com', 'tiing.tsong.soo@intel.com', 'tong.ho.tee@intel.com');    
			#my @To = ('lye.cheung.foo@intel.com', "david.ch'ng\@intel.com", 'ching.tatt.teoh@intel.com', 'seong.ngok.koo@intel.com', 'shi.ling.tan@intel.com', 'ee.chuangx.choong@intel.com', 'kai.jiunnx.loi@intel.com');
			my @To = ('lye.cheung.foo@intel.com', 'ching.tatt.teoh@intel.com');
			#my @To = ('lye.cheung.foo@intel.com');   
                    
			# On the subject line it will print the real file name
			my $Subject = "Coordinate x-min, x-max, y-min and y-max NOT MATCH occured on $FailFile"; 
			my $Body = 
			"Coordinate x-min, x-max, y-min and y-max NOT MATCH on the ITUFF summary - $FailFile with Fabrun=$Fabrun
Minimum and maximum x-y coordinate from Lookup Table: 
$chkerror[4]

Minimum and maximum x-y coordinate from $FailFile: 
$chkerror[5]

               	 * * * PLEASE DO NOT REPLY TO THIS MAIL * * *";
				 
			&SendMail($Subject, $Body, @To);

			# Create a duplicate log file ERROR.log
			&ErrorLog($chkerror[0], $Fabrun, $Chkstatus, $Lot);
			
			# Display on the screen the duplication information
			print "Coordinate x-min, x-max, y-min and y-max NOT MATCH at $FailFile with Fabrun=$Fabrun\n";
			print "Mail sent for error reporting\n";
			$Chkstatus = 0;
		}

		# Checking for wrongly inserted Fabrun		
		if ($chkerror[3] eq "WRONG_FABRUN")		
		{
			$Chkstatus = 3;
			#my @To = ('sook.leng.low@intel.com', 'soon.ee.chung@intel.com', 'soo.ling.chuah@intel.com', 'chee.juan.tan@intel.com', 'lye.cheung.foo@intel.com', 'kai.hiong.lee@intel.com', 'tong.ho.tee@intel.com');    
			#my @To = ('lye.cheung.foo@intel.com', "david.ch'ng\@intel.com", 'ching.tatt.teoh@intel.com', 'seong.ngok.koo@intel.com', 'shi.ling.tan@intel.com', 'ee.chuangx.choong@intel.com', 'kai.jiunnx.loi@intel.com');
			#my @To = ('lye.cheung.foo@intel.com');
			my @To = ('lye.cheung.foo@intel.com', 'ching.tatt.teoh@intel.com');

			# On the subject line it will print the real file name
			my $Subject = "Wrong Fabrun Inserted occured on $FailFile"; 
			my $Body = 
			"Wrong Fabrun Inserted occured on the ITUFF summary - $FailFile with Fabrun=$Fabrun

 	                  	 * * * PLEASE DO NOT REPLY TO THIS MAIL * * *";
				 
			&SendMail($Subject, $Body, @To);

			# Create a duplicate log file ERROR.log
			&ErrorLog($chkerror[0], $Fabrun, $Chkstatus, $Lot);
			
			# Display on the screen the duplication information
			print "Wrong Fabrun Inserted at $FailFile with Fabrun=$Fabrun\n";
			print "Mail sent for error reporting\n";
			$Chkstatus = 0;
		}		

		# Checking for test program name is standardized	
		if ($chkerror[1] eq "ProgNotMatch")
		{
			$Chkstatus = 4;
			#my @To = ('sook.leng.low@intel.com', 'soon.ee.chung@intel.com', 'soo.ling.chuah@intel.com', 'chee.juan.tan@intel.com', 'lye.cheung.foo@intel.com', 'tiing.tsong.soo@intel.com', 'tong.ho.tee@intel.com');    
			#my @To = ('lye.cheung.foo@intel.com', "david.ch'ng\@intel.com", 'ching.tatt.teoh@intel.com', 'seong.ngok.koo@intel.com', 'shi.ling.tan@intel.com', 'ee.chuangx.choong@intel.com', 'kai.jiunnx.loi@intel.com');
			#my @To = ('lye.cheung.foo@intel.com');   
			my @To = ('lye.cheung.foo@intel.com', 'ching.tatt.teoh@intel.com');
	
			# On the subject line it will print the real file name
			my $Subject = "Test Program Loaded Not Match on $FailFile"; 
			my $Body = 
			"Test Program Loaded Not Match - $FailFile with Fabrun=$Fabrun

 	                  	 * * * PLEASE DO NOT REPLY TO THIS MAIL * * *";
				 
			&SendMail($Subject, $Body, @To);

			# Create a duplicate log file ERROR.log
			&ErrorLog($chkerror[0], $Fabrun, $Chkstatus, $Lot);
			
			# Display on the screen the duplication information
			print "Test Program Loaded Not Match on $FailFile with Fabrun=$Fabrun\n";
			print "Mail sent for error reporting\n";
			$Chkstatus = 0;
		}

		# Check for good ITUFF summary and ftp to IPED if it is a good ITUFF summary
		if (($chkerror[1] eq "ProgMatch") && ($chkerror[2] eq "MATCH") && ($chkerror[3] eq "FABRUN") && ($chkerror[6] eq "NODUP"))
		{
			# Copy the good ituff summary to the good ituff directory before uploading to SOD	
			my $LotDir = $OutputStagingDir."\\".$Lot_Locn; 
			mkdir $LotDir, 0777;
			my $NewItuffFile = $LotDir."\\".$Wafer; 
			move ($OrgItuffFile, $NewItuffFile);
			
			# Log all good ituff at E:\databroker\logs\DataIntegrity\GoodITUFF.log			
			my $GoodITUFFLog = "E:\\databroker\\logs\\DataIntegrity\\GoodITUFF.log";
			open (GOODITUFF, ">>$GoodITUFFLog") || die "Cann't open $FTPLogFile: $!\n"; 
			print GOODITUFF "$chkerror[0] at $Now\n";
			close GOODITUFF;
			&CreateITUFFParserANDAriesSignalFile();
			print "Logging $chkerror[0] to $GoodITUFFLog\n";
		}
	}
}

# Subroutine to create signal file for Ituff Parser and Aries database
sub CreateITUFFParserANDAriesSignalFile
{
	# Touch Ituff Parser signal file for good ituff
	my $ITUFFParserSigFile = "E:\\signals\\ituff\\good_ituff_files\\".$Lot_Locn."==".$Wafer.".sig";
	open(ITUFFPARSER,">>$ITUFFParserSigFile"); 
	close(ITUFFPARSER);

	# Touch Aries signal file - currently not linked
	my $ARIESSigFile = "E:\\datadirectory\\sort\\iTUFF\\aries_signaldir\\".$Lot_Locn."_".$Wafer.".sig";
	open(ARIESSIG,">>$ARIESSigFile"); 
	close(ARIESSIG);

	print "Signal File: Ituff Parser=$ITUFFParserSigFile, Aries=$ARIESSigFile\n";
}

# Subroutine to get lot's Fabrun attribute from MARS database
sub GetFabrun
{
	# Fire off a query to MARS for each lot even if there are duplicates
	my %Temp;
	my $Lot = shift;
	my $sql = "SELECT DiSTINCT ATTRIBUTE_VALUE FROM S03_PROD_3.F_LOTATTRIBUTE WHERE LOT = '$Lot' " .
		"AND ATTRIBUTE_NUMBER = 711";

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

	# if Fabrun attribute not found then set attribute value to NULL 
	# else return the fabrun attribute to call sub
	$Temp{ATTRIBUTE_VALUE} =~ s/^$/NULL/;    
	return $Temp{ATTRIBUTE_VALUE};
}

# Subroutine to get lot's Sort Name from MARS database
sub GetSortName
{
	# Fire off a query to MARS for each lot even if there are duplicates
	my %SortNameTemp;
	my $Lot = shift;
	my $sql = "SELECT DiSTINCT PRODUCT FROM S03_PROD_3.F_LOT WHERE LOT = '$Lot'";
	
	if($dbMARS->Sql($sql))
	{
		&ifSQL($dbMARS, $sql);
	}
	else
	{
		while($dbMARS->FetchRow())
		{
			%SortNameTemp = $dbMARS->DataHash();
		}
	}

	# if sort name not found then set attribute value to NULL 
	# else return the fabrun attribute to call sub
	$SortNameTemp{PRODUCT} =~ s/^$/NULL/;    
	return $SortNameTemp{PRODUCT};
}

sub ifSQL
{
	my ($db, $sql) = @_;
	#my @To = ('lye.cheung.foo@intel.com', "david.ch'ng\@intel.com", 'ching.tatt.teoh@intel.com', 'seong.ngok.koo@intel.com', 'shi.ling.tan@intel.com', 'ee.chuangx.choong@intel.com', 'kai.jiunnx.loi@intel.com');
	my @To = ('lye.cheung.foo@intel.com', 'ching.tatt.teoh@intel.com', "david.ch'ng\@intel.com");
	&SendMail('SQL loading errors from Ituff Integrity script', $sql, @To);
	print "Error, SQL failed: " . $db->Error() . "\n";
	print "$sql\n";
	$db->Close();
	exit;
}

sub SendMail 
{
	my($Subject, $Body, @To) = @_;
	my $MailHost = 'mail.intel.com';
	my $From = 'SCDataBroker@intel.com';
	my $Tos = join('; ', @To);
	my $smtp = Net::SMTP->new($MailHost);
	#print $smtp->domain,"\n";
	$smtp->mail($From);
	$smtp->to(@To);
	$smtp->data();
	$smtp->datasend("To: $Tos\n");
	$smtp->datasend("Subject: $Subject\n");
	$smtp->datasend("$Body\n");
	$smtp->dataend();
	$smtp->quit();
}

# Subroutine for checking tester type S9K, HP94K, etc.
sub CheckTester 
{
	my ($Lot, $Fabrun, $OrgItuffFile) = @_;

	# Open the new file for reading
	open(FILE, $OrgItuffFile) || die "$OrgItuffFile:- $!\n";
	while(<FILE>)
	{
		# HP94K Tester data integrity check
		if (/^7_dsrcprg_(\w+)/)
		{
			my $Tester = $1;

			# For S9K tester, no data integrity check required
			my $result ="$OrgItuffFile ProgMatch MATCH FABRUN 0 0 NODUP";

			# For HP94K tester, x split coordinate required by adding 256
			if ($Tester eq "HP94K") 
			{
				$result = &UpdateItuffFileHP94K($Lot, $Fabrun, $OrgItuffFile);
				print "$result\n";
			}
			close FILE;
			return "$result";
		}
	}
}

sub UpdateItuffFileHP94K
{
	my ($Lot, $Fabrun, $OrgItuffFile) = @_;
	my $TempFile =  "${InputStaging}\\${Lot_Locn}\\Temp";
	my ($DuplicateFlag, $FabFlag, $XYMinMaxFlag, $ProgramMatchFlag) = ("NODUP", "FABRUN", "MATCH", "ProgMatch");
	my $Table = "E:\\databroker\\bin\\Lookup_Table";
	my ($productid, $dataxy, $WWID, $StartDate, $Time, $EndDate, $devrv, $progname, $productid_devrv, $actual_minmax);
	my (@xloc, @yloc, @newcdup, @data, @cdup, %Product) = ();


	# Open a access file for writing
	open(TEMP, ">$TempFile") || die "Cant open $TempFile:- $!\n";

	# Open the original file for reading
	open(FILE, $OrgItuffFile) || die "Cannt open $OrgItuffFile:- $!\n";
	while(<FILE>)
	{
		if (/6_prdct_(\w+)/)
		{
			#$productid = $2;	
			$_ = "6_comnt_origfabid_".$Fabrun."\n6_prdct_".$SortName."\n";
			$productid = $SortName;	
		}


		# Get the device stepping	
		$devrv = $1 if (/^6_devrv_(\w+)/);

		# Get the program name
		$progname = $1 if (/^6_prgnm_(\S+)/);

		# Get the operator WWID
		$WWID = $1 if (/^4_oprtr_(\d+)/);

		# Get start date and time
		if (/^4_begindt_(\d{8})(\d{6})/)
		{
			$StartDate = $1;
			$Time = $2;
		}
		
		# Get the end date
		$EndDate = $1 if (/^4_enddate_(\d{8})\d{6}/);
	
		# To add 256 to x-coordinate if x less than 256
		s/^(3_xloc_)(\S+)/$2 < 100 ? $1 . ($2 + 256) : $1 . $2/e;
		print TEMP $_;
	
		# Checking for the sequence duplicate
		if (/^3_xloc_(\w+)/g)
    		{       
			push (@xloc, $1);
		}

		if (/^3_yloc_(\w+)/g)
		{  
			push (@yloc, $1);
		}
	}

	close FILE;
	close TEMP;

	# Log file to trace the chnages of the product name

	# Rename temp file to the wafer file
	move ($TempFile, $OrgItuffFile); 

	#########################################################################
	##### This part is to check the data integrity of the ITUFF summary #####
	#########################################################################

	#print "My total : $#xloc and $#yloc # $xloc[0] and $yloc[0] # $xloc[$#xloc] and $yloc[$#yloc]\n";

	my $count = 0;
	# Check for the duplication x-y coordinate
	for (my $i=0; $i<=$#xloc; $i++)
	{
		for (my $j=0; $j<=$#xloc; $j++)
		{
			if ($i!=$j)
			{
				if (($yloc[$i] == $yloc[$j]) && ($xloc[$i] == $xloc[$j]))
				{
					$DuplicateFlag = "DUP";
					$count ++;
					if ($count <= 600) 
					{
						$dataxy .= "$xloc[$j],$yloc[$j];";
					}
				}
			}
		}
	}

	# Get the manimum and maximum x-coordinate
	my @xsort = sort {$a <=> $b} @xloc;
	my $xmin = $xsort[1]; 
	my $xmax = $xsort[$#xsort];

	# Get the minimum and maximum y-coordinate
	my @ysort = sort {$a <=> $b} @yloc;
	my $ymin = $ysort[1]; 
	my $ymax = $ysort[$#ysort];

	# Combine the display the data x-y min and max
	my $ITUFF_minmax = "x-min:${xmin},x-max:${xmax},y-min:${ymin},y-max:${ymax}";

	# Validate the Fabrun for the dot in the Fabrun
	my $InsFabrun = "FabrunOK";
	my ($LengthFabrun, $DotNumber) = split(/\./,$Fabrun);
	my $LenFabrun = length ($LengthFabrun);
	if ($Fabrun =~ /\./)
	{
		$InsFabrun = "FabrunBad" if ($DotNumber !~ /^\d{1,2}$/);
	}

	# Read truth table from filename Lookup_Table and put into memory
	open(TABLE, $Table);
	while (<TABLE>)
	{
		chomp;
		@data = split (/\s+/,$_);
    		$Product{$data[0]} = [$data[1], $data[2], $data[3], $data[4], $data[5], $data[6]];
	}
	close TABLE;

	$productid_devrv = $productid."_".$devrv;

	# Validate correct xmin, xmax, ymin, ymax, Fabrun Inserted
	foreach my $Key (keys %Product)
	{	
		if ($productid_devrv eq $Key)
		{
			# To check for xmin, xmax, ymin, ymax
			if (($xmin != $Product{$Key}[0]) || ($xmax != $Product{$Key}[1]) || ($ymin != $Product{$Key}[2]) || ($ymax != $Product{$Key}[3]))
			{
				$actual_minmax = "x-min:${Product{$Key}[0]},x-max:${Product{$Key}[1]},y-min:${Product{$Key}[2]},y-max:${Product{$Key}[3]}";
				$XYMinMaxFlag = "NOT_MATCH";		
			}
		
			# To check for Fabrun correctly been key-in
			if (($LenFabrun ne $Product{$Key}[4]) || ($InsFabrun eq "FabrunBad"))
			{
				$FabFlag = "WRONG_FABRUN";
			}
	
			# To check for correct program being loaded for sorting
			if ($progname ne $Product{$Key}[5])
			{
				$ProgramMatchFlag = "ProgNotMatch";
			}
		}
	}

	# Returning duplicate, mismatch x-y min and max coordinate, wrongly inserted Fabrun Boolean 
	if (($DuplicateFlag eq "DUP") && ($XYMinMaxFlag eq "MATCH") && ($FabFlag eq "FABRUN") && ($ProgramMatchFlag eq "ProgMatch"))
	{
		return "$OrgItuffFile ProgMatch MATCH FABRUN 0 0 DUP $dataxy $WWID $StartDate $Time $EndDate $productid_devrv";
	}
	elsif (($DuplicateFlag eq "NODUP") && ($XYMinMaxFlag eq "NOT_MATCH") && ($FabFlag eq  "FABRUN") && ($ProgramMatchFlag eq "ProgMatch"))
	{
		return "$OrgItuffFile ProgMatch NOT_MATCH FABRUN $actual_minmax $ITUFF_minmax NODUP";
	}
	elsif (($DuplicateFlag eq "NODUP") && ($XYMinMaxFlag eq "MATCH") && ($FabFlag eq "WRONG_FABRUN") && ($ProgramMatchFlag eq "ProgMatch"))
	{
		return "$OrgItuffFile ProgMatch MATCH WRONG_FABRUN 0 0 NODUP";
	}
	elsif (($DuplicateFlag eq "DUP") && ($XYMinMaxFlag eq "NOT_MATCH") && ($FabFlag eq "FABRUN") && ($ProgramMatchFlag eq "ProgMatch"))
	{
		return "$OrgItuffFile ProgMatch NOT_MATCH FABRUN $actual_minmax $ITUFF_minmax DUP $dataxy $WWID $StartDate $Time $EndDate $productid_devrv";
	} 
	elsif (($DuplicateFlag eq "DUP") && ($XYMinMaxFlag eq "MATCH") && ($FabFlag eq "WRONG_FABRUN") && ($ProgramMatchFlag eq "ProgMatch"))
	{
		return "$OrgItuffFile ProgMatch MATCH WRONG_FABRUN 0 0 DUP $dataxy $WWID $StartDate $Time $EndDate $productid_devrv";
	}
	elsif (($DuplicateFlag eq "NODUP") && ($XYMinMaxFlag eq "NOT_MATCH") && ($FabFlag eq "WRONG_FABRUN") && ($ProgramMatchFlag eq "ProgMatch"))
	{
		return "$OrgItuffFile ProgMatch NOT_MATCH WRONG_FABRUN $actual_minmax $ITUFF_minmax NODUP";
	}
	elsif (($DuplicateFlag eq "DUP") && ($XYMinMaxFlag eq "NOT_MATCH") && ($FabFlag eq "WRONG_FABRUN") && ($ProgramMatchFlag eq "ProgMatch"))
	{
		return "$OrgItuffFile ProgMatch NOT_MATCH WRONG_FABRUN $actual_minmax $ITUFF_minmax DUP $dataxy $WWID $StartDate $Time $EndDate $productid_devrv";
	}
	elsif (($DuplicateFlag eq "DUP") && ($XYMinMaxFlag eq "MATCH") && ($FabFlag eq "FABRUN") && ($ProgramMatchFlag eq "ProgNotMatch"))
	{
		return "$OrgItuffFile ProgNotMatch MATCH FABRUN 0 0 DUP $dataxy $WWID $StartDate $Time $EndDate $productid_devrv";
	}
	elsif (($DuplicateFlag eq "NODUP") && ($XYMinMaxFlag eq "NOT_MATCH") && ($FabFlag eq  "FABRUN") && ($ProgramMatchFlag eq "ProgNotMatch"))
	{
		return "$OrgItuffFile ProgNotMatch NOT_MATCH FABRUN $actual_minmax $ITUFF_minmax NODUP";
	}
	elsif (($DuplicateFlag eq "NODUP") && ($XYMinMaxFlag eq "MATCH") && ($FabFlag eq "WRONG_FABRUN") && ($ProgramMatchFlag eq "ProgNotMatch"))
	{
		return "$OrgItuffFile ProgNotMatch MATCH WRONG_FABRUN 0 0 NODUP";
	}
	elsif (($DuplicateFlag eq "DUP") && ($XYMinMaxFlag eq "NOT_MATCH") && ($FabFlag eq "FABRUN") && ($ProgramMatchFlag eq "ProgNotMatch"))
	{
		return "$OrgItuffFile ProgNotMatch NOT_MATCH FABRUN $actual_minmax $ITUFF_minmax DUP $dataxy $WWID $StartDate $Time $EndDate $productid_devrv";
	}
	elsif (($DuplicateFlag eq "DUP") && ($XYMinMaxFlag eq "MATCH") && ($FabFlag eq "WRONG_FABRUN") && ($ProgramMatchFlag eq "ProgNotMatch"))
	{
		return "$OrgItuffFile ProgNotMatch MATCH WRONG_FABRUN 0 0 DUP $dataxy $WWID $StartDate $Time $EndDate $productid_devrv";
	}
	elsif (($DuplicateFlag eq "NODUP") && ($XYMinMaxFlag eq "NOT_MATCH") && ($FabFlag eq "WRONG_FABRUN") && ($ProgramMatchFlag eq "ProgNotMatch"))
	{
		return "$OrgItuffFile ProgNotMatch NOT_MATCH WRONG_FABRUN $actual_minmax $ITUFF_minmax NODUP";
	}
	elsif (($DuplicateFlag eq "DUP") && ($XYMinMaxFlag eq "NOT_MATCH") && ($FabFlag eq "WRONG_FABRUN") && ($ProgramMatchFlag eq "ProgNotMatch"))
	{
		return "$OrgItuffFile ProgNotMatch NOT_MATCH WRONG_FABRUN $actual_minmax $ITUFF_minmax DUP $dataxy $WWID $StartDate $Time $EndDate $productid_devrv";
	}
	
	elsif (($DuplicateFlag eq "NODUP") && ($XYMinMaxFlag eq "MATCH") && ($FabFlag eq "FABRUN") && ($ProgramMatchFlag eq "ProgNotMatch"))
	{
		return "$OrgItuffFile ProgNotMatch MATCH FABRUN 0 0 NODUP";
	}
	else
	{
		return "$OrgItuffFile ProgMatch MATCH FABRUN 0 0 NODUP";    
	}
}

# Log all error detected on data integrity check at E:\databroker\logs\DataIntegrity\ERROR.log
sub ErrorLog
{
	my ($ErrorFile, $Fab, $Chkstatus, $Lot) = @_;
	my $ErrorLog = "E:\\databroker\\logs\\DataIntegrity\\ERROR.log";
	open(LOG, ">>$ErrorLog") || die "$ErrorLog:- $!\n";

	if ($Chkstatus == 1)
	{
		print LOG "Duplication $ErrorFile with Fabrun=$Fab at $Now\n";
	}
	elsif ($Chkstatus == 2) 
	{
		print LOG "Mismatch x-y minimum and maximum coordinate for $Fab - $ErrorFile at $Now\n";
	}
	elsif ($Chkstatus == 3)
	{
		print LOG "Wrong Fabrun Inserted $ErrorFile with Fabrun=$Fab at $Now\n";
	}
	elsif ($Chkstatus == 4)
	{
		print LOG "Test Program Loaded Not Match $ErrorFile with Fabrun=$Fab at $Now\n";
	}
	else
	{
		print LOG "No Fabrun for $Fab - $ErrorFile at $Now\n";
	}
	close LOG;
	&MoveBadItuff($ErrorFile, $Lot);
}

# Subroutine to move bad ituff file to directory E:\datadirectory\sort\iTUFF\bad_ituff_files
sub MoveBadItuff
{
	my ($ErrorFile, $Lot) = @_;
	my $BadDir = "E:\\datadirectory\\sort\\iTUFF\\bad_ituff_files\\".$Lot_Locn."\\"; 
	my $BadItuffFile = $BadDir.$Wafer;
	
	mkdir $BadDir,0777;
	move($ErrorFile, $BadItuffFile); 
}
