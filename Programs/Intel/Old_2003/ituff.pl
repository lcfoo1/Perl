

my $Dir = "c:\\perl\\programs\\0503A05A\\";

chdir $Dir;

foreach my $File (<*>)
{
	print "$File\n";
	my $waf = $1  if ($File =~ /(W\w+)$/);
	my $LotFile = "c:\\perl\\programs\\0503A05Aok\\". $waf;
	print "$LotFile\n";
	my %Binn =();
	my %xy = ();
	my $FirstFlag = 0;
	
	open (NEW, ">$LotFile");
	open (FILE, $File);
	while (<FILE>)
	{
		chomp;
		s/ //g;
		my ($a, $Wafer, $b, $x, $y, $bin, $site, $testtime) = split(/\,/,$_);
		$Wafer = $1 if ($Wafer =~ /^W(\d{3})/);
		$testtime = $1 if ($testtime =~ /^(.*\.\d{3})/);
		my $temp1 = $x.$y;
		#if (($xy{$temp1} == 0) && ($temp1 ne ""))
		#{
		#	$xy{$temp1} = 1;
		#}
		#else
		#{
		#	next;
		#}

		$Header = "7_lbeg\n7_filcret_20041208095908\n7_dsrcprg_HP94K\n6_lbeg\n6_lotid_0452A00A\n6_prdct_LXT971WAFER\n6_devrv_A4\n6_prgnm_HP_971WQ_02\n5_lbeg\n" .
		"5_flstpid_SORT\n5_lcode_8012\n4_lbeg\n4_wafid_". $Wafer. "\n" .
		"4_sysid_t3hp16\n4_prbcd_NA\n4_prber_6PRB-201\n4_oprtr_10531966\n4_facid_T3\n4_tempr_25\n4_begindt_20041130174715\n4_limsfil_971_WR\n3_lbeg\n3_lsep\n";

		if ($FirstFlag == 0)
		{
			print NEW "$Header";
			$FirstFlag = 1;
		}
		
		my $line =	"3_xloc_" . $x . "\n" .
					"3_yloc_" . $y . "\n" .
					"2_tname_testtime\n" .
					"2_mrslt_" . $testtime . "\n" .
					"2_lend\n" .
					"3_curibin_" . $bin . "\n" .
					"3_lsep\n";
		
		print NEW "$line";
		
		$Binn{$bin}++;
	}

	my ($iTUFFFooter, $iBinCtr, $TotalUnit, $iTUFFFooter) = ();
	foreach $TBin (keys %Binn)
	{
		$iTUFFFooter .= "3_comnt_autoltl_b". $TBin . "__" . $Binn{$TBin} . "\n";
		$iBinCtr .= "4_ibinctr_". $TBin . "__" . $Binn{$TBin} . "\n";
		#print "$TBin :: $iTUFFFooter\n";
		$TotalUnit += $Binn{$TBin};
	}

	# End time is taken from the time the script finish processing
	$EndTime = &iTUFFDateTime(time());

	$iTUFFFooter .= "3_lend\n" . $iBinCtr .
			"4_total_" . $TotalUnit . "\n" .
			"4_enddate_" . $EndTime . "\n" .
			"4_lend\n5_lend\n6_lend\n7_lend\n";

			#print "$iTUFFFooter";
	print NEW "$iTUFFFooter";

	close FILE;
	close NEW;
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
