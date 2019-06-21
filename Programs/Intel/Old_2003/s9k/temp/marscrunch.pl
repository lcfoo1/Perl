#################################################################################################
#												#
#	Foo Lye Cheung					NCO PDQRE Automation			#
#	3 August 2004										#
#												#
#	This script is going to screen and crunch the lot and compare the ituff data		#
#	with the physical (MARS database) - bin 1, bin 2 and total good.			#
#	It will also check that 1A reject do go to next or summary for retest and ensure that	#
#	there is no bin 1 retested again and again.						#
#												#
#	Rev 0.0											#
#												#
#################################################################################################

use Net::SMTP;
use Win32::ODBC;
use Win32::OLE;
use strict;
use warnings;

my %Summary = ();
my @Sum =();
my $RetestBin12 = "";
my $RejectNotToLastSum = "";
my @To = ();

&EmailTo();
my $dbMARS = &OpenMARS;
&CheckLotBin();
$dbMARS->Close();

sub EmailTo
{
	my $EmailList = "Email.tbl";
	open (EMAIL, $EmailList) || die "Cannt open $EmailList : $!\n";
	while (<EMAIL>)
	{
		push (@To, $_);
	}
	close EMAIL;
}

# Connect to MARS database
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

# If error, trigger the email list on the error
sub ifSQL
{
	my ($db, $sql) = @_;
	#my @To = ('lye.cheung.foo@intel.com');
	&SendMail('SQL loading errors!', $sql, @To);
	print "Error, SQL failed: " . $db->Error() . "\n";
	print "$sql\n";
	$db->Close();
	exit;
}

# Checking starts here
sub CheckLotBin
{
	my $iTUFFDir = $ARGV[0];
	my ($B1, $B2, $TotalGood) = (0, 0, 0);
	#print "$iTUFFDir \n";
	my ($Lot, $iTUFFB1, $iTUFFB2, $iTUFFTotalGood) = &CheckAllULTSummary($iTUFFDir);

	($B1, $B2, $TotalGood) = &GetQtyMARS($Lot);
	my $Body = "Physical B1: $B1, B2: $B2 and Total good: $TotalGood\n" .
		   "Datalog B1: $iTUFFB1, B2: $iTUFFB2 and Total good: $iTUFFTotalGood\n";

	$Body .= "\nRetest Bin 1 and Bin 2\n$RetestBin12\n" if ($RetestBin12 ne "");
	$Body .= "Reject found not go to Last Summary\n$RejectNotToLastSum\n" if ($RejectNotToLastSum ne "");

	if (($B1 > $iTUFFB1) || ($B2 > $iTUFFB2))
	{
		my $Subject = "Warning to All: Physical less than datalog - Lot: $Lot !!!\n";
		$Body = $Subject.$Body;
		print "$Body\n";
		&SendMail($Subject, $Body, @To);
		print "Warning email is send to the list!!!\n";
	}
	else
	{
		my $Subject = "Summarize Lot# $Lot ...\n";
		$Body = $Subject.$Body;
		print "$Body\n";
		&SendMail($Subject, $Body, @To);
		print "Email is send to the list!!!\n";
	}
}

sub CheckAllULTSummary
{
	my $iTUFFDir = shift;
	my @iTUFFSum =();

	my ($Lot, $Fablot, $WaferID, $xloc, $yloc, $PrtName, $Bin, $Key) = ("", "", "", "", "", "", "");
	my ($DiffFileName, $SameFileName, $Already) = (0, 0, 0);
	my ($Count, $CountNoULT, $SameKeyCount) = (0, 0, 0);
	my ($TotalBin1, $TotalBin2) = (0, 0);
	my ($Bin1Sum, $Bin2Sum) = (0, 0);
	my $SameFlag = 0;
	my $Count12 =0;
	my $ArrangeLine = "";

	opendir (ITUFFDIR, $iTUFFDir) || die "Cannt open $iTUFFDir : $!\n";
	@Sum = grep { /^\d[A-E]$/o && -f "$iTUFFDir\\$_" } readdir(ITUFFDIR);
	closedir ITUFFDIR;

	# Rearrange the ituff file format
	foreach my $File (@Sum)
	{
		my ($TempKey, $TempPrtName) = ("", "");
		my $FileSum = "$iTUFFDir\\$File";
	
		open (FILE, $FileSum) || die "Cannt open $File : $! \n"; 
		while (<FILE>)
		{
			s/ //g;
			$Lot = $1 if (/^6_lotid_(\w+)$/o);
			$PrtName = $1 if (/^3_prtnm_(\w+)$/o);
			$Fablot = $1 if(/^2_trlot_(\S+)$/o);
			$WaferID = $1 if (/^2_trwafer_(\d+)$/o); 
			$xloc = $1 if (/^2_trxloc_(\S+)$/o);
			$yloc = $1 if (/^2_tryloc_(\S+)$/o);
			$Bin = $1 if (/^2_curibin_(\S+)$/o);

			if (/4_ibinctr_(\d)_(\d+)/o)
			{
				my $Binning = $1;
				my $BinCount = $2;
			

				if ($Binning == 1)
				{
					$TotalBin1 += $BinCount;

				}
				elsif ($Binning == 2)
				{
					$TotalBin2 += $BinCount;
				}
			}
		
			if (/2_lend/o)
			{
				if (($Fablot eq "") && ($WaferID eq "") && ($xloc eq "") && ($yloc eq ""))
				{
					#$Key = "NO ULT $CountNoULT";
					$Key = "NO ULT";
					$CountNoULT++;
				}
				else 
				{
					$Key = "$Fablot $WaferID $xloc $yloc";
				}

				next if (($PrtName eq "") || ($TempPrtName eq $PrtName));
				
				no warnings;
				if ($Summary{$File}{$Key} eq "")
				{
					$Summary{$File}{$Key} = "File: $File, PrtName: $PrtName, Bin: $Bin";
					#print "$Summary{$File}{$Key}\n";
				}
				else
				{
					# As team agreed ignore these checking same ULT in same summary as variant too small and undefined pattern
					#if ($Key eq $TempKey)
					#{
					#	$SameKeyCount++;
					#}
					#else 
					#{
					#	$SameKeyCount=0;
					#}
					#$TempKey = $Key;
					#$Key .= " Same $SameKeyCount";
					#$Summary{$File}{$Key} = "File: $File, PrtName: $PrtName, Bin: $Bin";
				}
				$TempPrtName = $PrtName;
				($Fablot, $WaferID, $xloc, $yloc, $Key) = ("", "", "", "", "", "");
			}
		}
		close FILE;
	}

	# Screening all iTUFF data to check for the retest Bin 1, 2 and rejects
	foreach my $MFile (sort keys %Summary)
	{
		foreach $Key (keys %{$Summary{$MFile}}) 	
		{
			my ($tSum, $tUnit, $tBin) = ($1, $2, $3) if  $Summary{$MFile}{$Key} =~ /^File:\s+(\w{2})\S\s+PrtName:\s+(\d+)\S\s+Bin:\s+(\d+)$/o;
			$ArrangeLine = "$tSum $tUnit $Key\t$tSum $tUnit $tBin";
			#$ArrangeLine = "$tSum\t$tUnit\t$Key\t$tSum\t$tUnit\t$tBin";
		
			foreach my $StoreSum (@Sum)
			{
				# These flag to ensure that the checking in on the next sum and not same sum
				if ($StoreSum ne $MFile)
				{
					$DiffFileName = 1;
					$SameFileName = 0;
				}
			
				if ($StoreSum eq $MFile)
				{
					$Already = 1;
					$DiffFileName = 0;
					$SameFileName = 1;
					next;
				}

				if (($DiffFileName == 1) && ($SameFileName == 0) && ($Already == 1))
				{
					foreach my $FabInfo (keys %{$Summary{$StoreSum}})
					{
						if ($Key eq $FabInfo)
						{
							$SameFlag = 1;
							my ($tSum, $tUnit, $tBin) = ($1, $2, $3) if  $Summary{$StoreSum}{$FabInfo} =~ /^File:\s+(\w{2})\S\s+PrtName:\s+(\d+)\S\s+Bin:\s+(\d+)$/o;
							#$ArrangeLine .= "\t$tSum\t$tUnit\t$tBin";
							$ArrangeLine .= "\t$tSum $tUnit $tBin";
						}
					}
				}
			}
			$Already = 0;
			
			# Ensure that 1A good or reject found in next sum
			if ($SameFlag)
			{
				# Filter out bin 1 and 2 to check how many times it retest
				if ($tBin =~ /^[12]$/o)
				{
					$Count12++;
					#print "$Count12\t$ArrangeLine\n";
					$RetestBin12 .= "$Count12\t$ArrangeLine\n";
				}
				$ArrangeLine = "";
				$SameFlag = 0;
			
			}

			# Only 1A/1B/2A reject do not go till it become good bin
			else 
			{
				chomp($tBin);
				if ($tBin !~ /^[012]$/o)
				{
					# Ensure that it do not display last summary rejects
					if ($ArrangeLine !~ /$Sum[$#Sum]/o)
					{
						#print "Reject $ArrangeLine\n";
						$RejectNotToLastSum .= "$ArrangeLine\n";
						$Count++;
					}
				}
				$ArrangeLine = "";
				$SameFlag = 0;
			}
		}
		#print "$MFile = $Count\n";
		$Count = 0;
	}
	
	return ($Lot, $TotalBin1, $TotalBin2, ($TotalBin1+$TotalBin2));
}

# Get B1, B2 and total good bin from MARS at test location - 6102 or 6152
sub GetQtyMARS
{
	my $Lot = shift;
	my %Temp;
	my $sql = "SELECT LOTHIST.NEWQTY1 AS B1, LOTSUBHIST.TOQTY AS B2, LOTHIST.INQTY As TOTALGOOD ". 
		  "FROM A11_PROD_5.F_LOTSUBPRODUCTHIST LOTSUBHIST, A11_PROD_5.F_LOTHIST LOTHIST " .
		  "WHERE LOTHIST.LOT = '" . $Lot . "' AND LOTHIST.LOT=LOTSUBHIST.LOT ".
		  "AND (LOTSUBHIST.PRODUCT like 'FW8VD32V A B __KS2H KS2H' AND LOTHIST.PRODUCT LIKE 'FW8VD32V A B __KL6R3K')" .
		  "AND LOTSUBHIST.OPERATION LIKE '61_2' AND LOTHIST.PREV_OPERATION = LOTSUBHIST.OPERATION";

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

		if(! $dbMARS->FetchRow())
		{
			# There is some funny lot only have Bin 2 (no Bin 1)
			$sql = "SELECT NEWQTY1 AS B2, NEWQTY1 AS TOTALGOOD from A11_PROD_5.F_LOTHIST WHERE LOT LIKE '" . $Lot . "' AND OPERATION LIKE '61_2' AND ROUTE = 'A330' AND PRODUCT LIKE 'FW8VD32V A B __KL6R2K'";
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
				$Temp{'B1'} = 0;
			}			
		}
	}
	return ($Temp{'B1'}, $Temp{'B2'}, $Temp{'TOTALGOOD'});
}

# Send email to PEs for triggering
sub SendMail 
{
	my($Subject, $Body, @To) = @_;
	my $MailHost = 'mail.intel.com';
	my $From = 't3admin6@intel.com';
	my $Tos = join('; ', @To);
	my $smtp = Net::SMTP->new($MailHost);
	#print $smtp->domain,"\n";
	$smtp->mail($From);
	$smtp->to(@To);
	$smtp->data();
	$smtp->datasend("To: $Tos");
	$smtp->datasend("Subject: $Subject\n");
	$smtp->datasend("$Body\n");
	$smtp->dataend();
	$smtp->quit();
}
