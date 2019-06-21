#!/usr/contrib/bin/perl -w
#################################################################################
#										#
#	Foo Lye Cheung					NCO PDQRE Automation	#
#	inet 253-6452					Penang			#
#										#
#	DESCRIPTION								#
#	The script will convert the temperorary waferdata file to iTUFF		#
#	format and executed at end of wafer.					#
#										#
#	09/30/2004								#
#										#
#################################################################################

# Global variable
%TotalBinQty = ();

# Takes filename argument which is pass from OIF 
$WaferDataFile = $ARGV[0];

# Main program starts here
&ProcessToiTUFF();


sub ProcessToiTUFF
{
	$WaferIDTokenFlag = 0;

	open (WAFERDATA, $WaferDataFile) || die "Can't open $WaferDataFile : $!\n";
	do 
	{	$_ = <WAFERDATA>;
		s/ //g;

		$LotSum = $1 if (/^LOT=(\w+)$/o);
		$Device = $1 if (/^DEVICE=(\w+)$/o);
		$DevRevStep = $1 if (/^DEVICE_REV=(\w+)$/o);
		$Locn = $1 if (/^WORKSTREAM=(\d+)$/o);
		$iTUFFName = $1 if (/^SUMMARY=(W\w+)$/o);
		$TestProgram = $1 if (/^PROGRAM=(\w+)$/o);
		$Equipment = $1 if (/^EQUIPMENT=(\S+)$/o);
		$Operator = $1 if (/^OPERATOR=(\S+)$/o);
		$Tester = $1 if (/^TESTER=(\S+)$/o);
		$EpochStartTime = $1 if (/^STARTTIME=(\w+)$/o);
	} while ($_ !~ /HEADERSTOP/o);
	
	$StartTime = &iTUFFDateTime($EpochStartTime);
	$iTUFFHeader = 	"7_filcret_" . $StartTime ."\n" .
			"7_dsrcprg_HP94K\n" .
			"6_lotid_" . $LotSum . "\n" .
			"6_prdct_" . $Device . "\n" .
			"6_devrv_" . $DevRevStep . "\n" .
			"6_prgnm_" . $TestProgram . "\n" .
			"5_lbeg\n5_flstpid_SORT\n" .
			"5_lcode_" . $Locn . "\n" .
			"4_lbeg\n";

	while(<WAFERDATA>)
	{
		($TestName, $Result, $FDPMV, $Vcont, $FailingPattern, $Faildata, $xloc, $yloc, $Bin, $TestTime) = ();
		# The format of the parametric line is standard on a window
		($^W) = 0;
		if (/TESTNAME=(\S+),\sRESULTS=(\S+),\sUPPER=\S+,\sLOWER=\S+,\sUNITS=.*,\sFAILINGPIN=\S+,\sFDPMV=(.*),\sVCONT=(.*),\sFAILINGPATTERN=(.*),\sFAILINGDATA=(.*),\sCOMMENT/)
		{
			($TestName, $Result, $FDPMV, $Vcont, $FailingPattern, $Faildata) = ($1, $2, $3, $4, $5, $6);

			$TmpiTUFFBody .= "2_tname_" . $TestName . "\n" if ($TestName ne "");
			$TmpiTUFFBody .= "2_dpmv_" . $FDPMV . "\n" if ($FDPMV ne "");
 			$TmpiTUFFBody .= "2_pttrn_" . $FailingPattern . "\n" if ($FailingPattern ne "");
			$TmpiTUFFBody .= "2_vcont_" . $Vcont . "\n" if ($Vcont ne "");
			$TmpiTUFFBody .= "2_faildata_" . $Faildata . "\n" if ($Faildata ne "");
			$TmpiTUFFBody .= "2_mrslt_" . $Result . "\n" if ($Result ne "");
			$TmpiTUFFBody .= "2_lsep\n";
			#print "$TmpiTUFFBody\n";
			($TestName, $Result, $FDPMV, $Vcont, $FailingPattern, $Faildata) = ();
		}
			
		if (/WAFER=(\w+),RUN_NUMBER=\w+,DIENO=\d+,X=(\S+),Y=(\S+),BIN=(\d+),SITE=\d+,TIME=(\d+\.\d{3})/)
		{
			($Summary, $xloc, $yloc, $Bin, $TestTime) = ($1, $2, $3, $4, $5);
			($^W) = 0;
			$FoundUnitFlag = 1;
		}

		if ($FoundUnitFlag)
		{
			if (!$WaferIDTokenFlag)
			{
				$WaferIDTokenFlag = 1;
				$iTUFFHeader .= "4_wafid_" . $Summary . "\n" .
						"4_sysid_" . $Tester . "\n" .
						"4_prbcd_NA\n" .
						"4_prber_" . $Equipment . "\n" .
						"4_oprtr_" . $Operator . "\n" .
						"4_facid_T3\n4_tempr_25\n" .
						"4_begindt_" . $StartTime ."\n" .
						"4_limsfil_orca2\n3_lbeg\n3_lsep\n";
			}

			$TotalBinQty{$Bin}++;
			$iTUFFBody .= 	"3_xloc_" . $xloc . "\n" .
					"3_yloc_" . $yloc . "\n" .
					"2_lsep\n" .
					$TmpiTUFFBody .
					"2_tname_testtime\n" .
					"2_mrslt_" . $TestTime . "\n" .
					"2_lend\n" .
					"3_curibin_" . $Bin . "\n" .
					"3_lsep\n";
			$TmpiTUFFBody = "";
			$FoundUnitFlag = 0;
		}
	}

	close WAFERDATA;

	($iTUFFFooter, $iBinCtr, $TotalUnit) = ("", "");
	foreach $TBin (keys %TotalBinQty)
	{
		$iTUFFFooter .= "3_comnt_autoltl_b". $TBin . "__" . $TotalBinQty{$TBin} . "\n";
		$iBinCtr .= "4_ibinctr_". $TBin . "__" . $TotalBinQty{$TBin} . "\n";
		$TotalUnit += $TotalBinQty{$TBin};
	}

	# End time is taken from the time the script finish processing
	$EndTime = &iTUFFDateTime(time());

	$iTUFFFooter .= "3_lend\n" . $iBinCtr .
			"4_total_" . $TotalUnit . "\n" .
			"4_enddate_" . $EndTime . "\n" .
			"4_lend\n5_lend\n6_lend\n7_lend\n";

	# Create prepare the production directory
	$ProdDir = "/lopte/data/summary/t3/". $LotSum . "_" . $Locn . "/";
	qx{mkdir $ProdDir} unless (-e $ProdDir);
	$NewiTUFFName = $ProdDir . $iTUFFName;

	open (NEWiTUFF, ">$NewiTUFFName") || die "Can't open new $NewiTUFFName : $!\n";
	print NEWiTUFF $iTUFFHeader;
	print NEWiTUFF $iTUFFBody;
	print NEWiTUFF $iTUFFFooter;
	close NEWiTUFF;

	#print $iTUFFHeader;
	#print $iTUFFBody;
	#print $iTUFFFooter;
	
	($LotSum, $Device, $DevRevStep, $iTUFFName, $Summary, $TestProgram, $Equipment, $Operator, $Tester, $EpochStartTime, $StartTime, $EndTime) = ();
	print "Finish processing the $WaferDataFile...\n";
}


# Formats the current time into a date recognise by ARIES DB
sub iTUFFDateTime
{
	$TimeToProcess = shift;
	($ss, $mi, $hh, $dd, $mm, $yyyy) = localtime($TimeToProcess);
	
	$yyyy += 1900;
	$mm++;
	$mm =~ s/^(\d)$/0$1/;
	$dd =~ s/^(\d)$/0$1/;
	$hh =~ s/^(\d)$/0$1/;
	$mi =~ s/^(\d)$/0$1/;
	$ss =~ s/^(\d)$/0$1/;

	return("$yyyy$mm$dd$hh$mi$ss");
}
