#!/usr/contrib/bin/perl -w
#########################################################################
#									#
#	Foo Lye Cheung				NCO PDQRE Automation	#
#	inet 253-6452							#
#	Penang								#
#									#
#	DESCRIPTION							#
#	The script will convert the temperorary waferdata file to iTUFF	#
#	format. 							#
#									#
#	08/19/2004							#
#									#
#########################################################################

$WaferDataFile = $ARGV[0];
#($Lot, $Locn) = ($1, $2) if ($WaferDataFile =~ / /);
#$TmpWaferDir = "/lopte/data/tmp/";
#$ProdDir = "/lopte/data/summary/t3/". $Lot . "_" . $Locn . "/";

#qx{mkdir $ProdDir} unless (-e $ProdDir);
%TotalBinQty = ();
&ProcessToiTUFF();

sub ProcessToiTUFF
{
	open (WAFERDATA, $WaferDataFile) || die "Can't open $WaferDataFile : $!\n";
	do 
	{	$_ = <WAFERDATA>;
		s/ //g;

		# !!require to have stepping information
		$LotSum = $1 if (/^LOT=(\w+)$/o);
		$Device = $1 if (/^DEVICE=(\w+)$/o);
		$Workstream = $1 if (/^WORKSTREAM=(\d+)$/o);
		$Summary = $1 if (/^SUMMARY=(\w+)$/o);
		$TestProgram = $1 if (/^PROGRAM=(\w+)$/o);
		$Equipment = $1 if (/^EQUIPMENT=(\S+)$/o);
		$Operator = $1 if (/^OPERATOR=(\S+)$/o);
		$Tester = $1 if (/^TESTER=(\S+)$/o);
		$EpochStartTime = $1 if (/^STARTTIME=(\w+)$/o);
	} while ($_ !~ /HEADERSTOP/o);
	
	$StartTime = &iTUFFDateTime();
	$iTUFFHeader = 	"7_filcret_" . $StartTime ."\n" .
			"7_dsrcprg_HP94K\n" .
			"6_lotid_" . $LotSum . "\n" .
			"6_prdct_" . $Device . "\n" .
			"6_devrv_D0\n" .
			"6_prgnm_" . $TestProgram . "\n" .
			"5_lbeg\n5_flstpid_SORT\n" .
			"5_lcode_" . $Workstream . "\n" .
			"4_lbeg\n".
			"4_wafid_" . $Summary . "\n" .
			"4_sysid_" . $Tester . "\n" .
			"4_prbcd_NA\n" .
			"4_prber_" . $Equipment . "\n" .
			"4_oprtr_" . $Operator . "\n" .
			"4_facid_T3\n4_tempr_25\n" .
			"4_begindt_" . $StartTime ."\n" .
			"4_limsfil_orca2\n3_lbeg\n3_lsep\n";

	while(<WAFERDATA>)
	{
		
		($TestName, $Result, $Units, $FDPMV, $Vcont, $FailingPattern, $Faildata, $xloc, $yloc, $Bin, $TestTime) = ();
		do 
		{
			$_ = <WAFERDATA>;

			# The format of the parametric line is standard on a window
			($^W) = 0;
			if (/TESTNAME=(\S+),\sRESULTS=(\S+),\sUPPER=\S+,\sLOWER=\S+,\sUNITS=(\d+),\sFAILINGPIN=\S+,\sFDPMV=(.*),\sVCONT=(.*),\sFAILINGPATTERN=(.*),\sFAILINGDATA=(.*),\sCOMMENT/)
			{
				($TestName, $Result, $Units, $FDPMV, $Vcont, $FailingPattern, $Faildata) = ($1, $2, $3, $4, $5, $6, $7);

				$TmpiTUFFBody .= "2_tname_" . $TestName . "\n" if ($TestName ne "");
				$TmpiTUFFBody .= "2_dpmv_" . $FDPMV . "\n" if ($FDPMV ne "");
	 			$TmpiTUFFBody .= "2_pttrn_" . $FailingPattern . "\n" if ($FailingPattern ne "");
				$TmpiTUFFBody .= "2_vcont_" . $Vcont . "\n" if ($Vcont ne "");
				$TmpiTUFFBody .= "2_mrslt_" . $Result . "\n" if ($Result ne "");
				$TmpiTUFFBody .= "2_faildata_" . $Faildata . "\n" if ($Faildata ne "");
				$TmpiTUFFBody .= "2_lsep\n";
			}

			
			if (/WAFER=\w+,DIENO=\d+,X=(\S+),Y=(\S+),BIN=(\d+),SITE=\d+,TIME=(\d+\.\d{3})/o)
			{
				($xloc, $yloc, $Bin, $TestTime) = ($1, $2, $3, $4);
				($^W) = 0;
				$FoundUnitFlag = 1;
				($TestName, $Result, $Units, $FDPMV, $Vcont, $FailingPattern, $Faildata) = ();
			}
		} while ($FoundUnitFlag == 0);

		print $TmpiTUFFBody;
		exit;

		if ($FoundUnitFlag)
		{
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
			print $iTUFFBody;
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

	# !! No end date
	$iTUFFFooter .= "3_lend\n" . $iBinCtr .
			"4_total_" . $TotalUnit . "\n" .
			"4_enddate_" . $StartTime . "\n" .
			"4_lend\n5_lend\n6_lend\n7_lend\n";

=pod
	open (NEWiTUFF, ">$NewiTUFFName") || die "Can't open new $NewiTUFFName : $!\n";
	print NEWiTUFF $iTUFFHeader;
	print NEWiTUFF $iTUFFBody;
	print NEWiTUFF $iTUFFFooter;
	close NEWiTUFF;
=cut
	print $iTUFFHeader;
	print $iTUFFBody;
	print $iTUFFFooter;
	
	($LotSum, $Device, $Summary, $TestProgram, $Equipment, $Operator, $Tester, $EpochStartTime, $StartTime) = ();
}


sub iTUFFDateTime
{
	# Formats the current time into a date recognise by ARIES DB
	($ss, $mi, $hh, $dd, $mm, $yyyy) = localtime($EpochStartTime);
	
	$yyyy += 1900;
	$mm++;
	$mm =~ s/^(\d)$/0$1/;
	$dd =~ s/^(\d)$/0$1/;
	$hh =~ s/^(\d)$/0$1/;
	$mi =~ s/^(\d)$/0$1/;
	$ss =~ s/^(\d)$/0$1/;

	return("$yyyy$mm$dd$hh$mi$ss");
}
