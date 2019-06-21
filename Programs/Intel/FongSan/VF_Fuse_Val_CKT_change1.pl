#!/usr/intel/bin/perl

#Read file

	open(READFILE, "IOData.txt")|| die "Cannot open file";
		
	$p = -1;
	$v = -1;
	$u = -1;
	
	while(<READFILE>){
	chomp($_);
	
		if($_=~m/QA Datalog/){
			@QADATALOG = split(/"/, $_);
			$Qadatalog = $QADATALOG[1];
			}
		
		if($_=~m/Class Datalog/){
			@DATALOG = split(/"/, $_);
			$Datalog = $DATALOG[1];
			}
			
		if($_=~m/OLF UBE/){
			@UBE = split(/"/, $_);
			$Ube = $UBE[1];
			}
		
		if($_=~m/QA UBE/){
			@QA = split(/"/, $_);
			$Qa = $QA[1];
			}
		
		if($_=~m/Custom File/){
			@CUSTOM = split(/"/, $_);
			$Custom = $CUSTOM[1];
			}
			
		if($_=~m/Sspec File/){
			@SPEC = split(/"/, $_);
			$Spec = $SPEC[1];
			}
		
		if($_=~m/Output Path/){
			@OUTPUT = split(/"/, $_);
			$Output = $OUTPUT[1];
			}
			
		if($_=~m/Tracelog \d+/){
			$p++;
			@PPV = split(/"/, $_);
			$PPVLOG[$p] = $PPV[1];
			}
		
		if($_=~m/Visual ID \d+/){
			$v++;
			@VISUALID = split(/"/, $_);
			$UNIT[$v] = $VISUALID[1];
			}
		
		if($_=~m/ULT \d+/){
			$u++;
			@TRACE = split(/"/, $_);
			$TRACES[$u] = $TRACE[1];
			}
		}
	
	for($dd = 0; $dd<=$#TRACES; $dd++){
		$Ppvlog = $PPVLOG[$dd];
		$Unit = $UNIT[$dd];
		$ThisULT = $TRACES[$dd];
		@LD1 = [];
		@LD2 = [];
		@PKG = [];
							
	if(($Unit eq " ") && ($ThisULT eq " ")){
	open(FILETRACELOG, "$Ppvlog")|| die "Cannot open file";
	
	while(<FILETRACELOG>){
	chomp($_);
	
	if($_=~m/ThisULT/){
		@THISULT = split(/ = /, $_);
		$ThisULT = $THISULT[1];
	}
	}
	close (FILETRACELOG);
	}
	
	if($ThisULT ne " "){
	@THISULT = split(/_/, $ThisULT);

	if($THISULT[1] < 10){
		$THISULT[1] = "00".$THISULT[1];
	}

	elsif($THISULT[1] < 100){
		$THISULT[1] = "0".$THISULT[1];
	}

	if(($THISULT[2] < 0) && ($THISULT[2] > -10)){
		@THISULT2 = split(//, $THISULT[2]);
		$THISULT[2] = "-0".$THISULT2[1];
	}

	if($THISULT[2] == 0){
		$THISULT[2] = "+00";
	}

	if(($THISULT[2] > 0) && ($THISULT[2] < 10)){
		@THISULT2 = split(//, $THISULT[2]);
		$THISULT[2] = "+0".$THISULT2[0];
	}
	
	if(($THISULT[2] > 0) && ($THISULT[2] >= 10)){
		$THISULT[2] = "+".$THISULT[2];
	}
	
	if(($THISULT[3] < 0) && ($THISULT[3] > -10)){
		@THISULT3 = split(//, $THISULT[3]);
		$THISULT[3] = "-0".$THISULT3[1];
	}

	if($THISULT[3] == 0){
		$THISULT[3] = "+00";
	}

	if(($THISULT[3] > 0) && ($THISULT[3] < 10)){
		@THISULT3 = split(//, $THISULT[3]);
		$THISULT[3] = "+0".$THISULT3[0];
	}
	
	if(($THISULT[3] > 0) && ($THISULT[3] >= 10)){
		$THISULT[3] = "+".$THISULT[2];
	}

	$ThisULT = $THISULT[0]."_".$THISULT[1]."_".$THISULT[2]."_".$THISULT[3];
	
#	print "$ThisULT\n";

	open (FILEOLF, "$Ube")|| die "Cannot open file";
	
	while(<FILEOLF>){
	chomp($_);
	
	if($_=~m/UNIT/){
		@VISUALID = split(/,/, $_);
		$Visualid = $VISUALID[1];
		
		$_ = <FILEOLF>;
		chomp($_);
		@T_ULT = split(/:/, $_);
		$T_Ult = $T_ULT[0];
	
	if($T_Ult eq $ThisULT){
		$Unit = $Visualid;
		$ThisUlt = $T_Ult;
		}
	}
}

	close (FILEOLF);
	}

#PPV Log Part
if($Ppvlog ne " "){
	open(FILETRACELOG, "$Ppvlog")|| die "Cannot open file";
	
	$i = 0;
	$j = 0;

while(<FILETRACELOG>){
	chomp($_);

		if($_=~m/The LongSpec:/){
			$FClass = $_;
			@FCLASS = split(/The LongSpec: /, $FClass);
			$FClass = $FCLASS[1];
			}
		
		if($_=~m/BOM_DLCP_ID/){
			$Dlcp_id = $_;
			@DLCP_ID = split(/= /, $Dlcp_id);
			$Dlcp_id = @DLCP_ID[1];
			}

		if($_=~m/BOM_CORE_STEP/){
			$Core_step = $_;
			@CORE_STEP = split(/= /, $Core_step);
			$Core_step = @CORE_STEP[1];
			}
		
		if($_=~m/Core 0 Fuses:/){
			$i++;
			$Fuse_C0[$i] = $_;
			@FUSE_C0 = split(/Core 0 Fuses: /, $Fuse_C0[$i]);
			$Fuse_C0[$i] = $FUSE_C0[1];
			}
			
		if($_=~m/Core 1 Fuses:/){
			$j++;
			$Fuse_C1[$j] = $_;
			@FUSE_C1 = split(/Core 1 Fuses: /, $Fuse_C1[$j]);
			$Fuse_C1[$j] = $FUSE_C1[1];
			}
		}

		$FuseA_C0 = $Fuse_C0[1];
		@FUSEA_C0 = split(//, $FuseA_C0);
		@REV_FUSEA_C0 = reverse(@FUSEA_C0);
		
		$FuseA_C1 = $Fuse_C1[1];
		@FUSEA_C1 = split(//, $FuseA_C1);
		@REV_FUSEA_C1 = reverse(@FUSEA_C1);
		
		$FuseB_C0 = $Fuse_C0[2];
		@FUSEB_C0 = split(//, $FuseB_C0);
		@REV_FUSEB_C0 = reverse(@FUSEB_C0);
		
		$FuseB_C1 = $Fuse_C1[2];
		@FUSEB_C1 = split(//, $FuseB_C1);
		@REV_FUSEB_C1 = reverse(@FUSEB_C1);
	}
	
#QA Datalog Part

if($Qadatalog ne " "){
	open(FILEQA1A, "$Qadatalog")|| die "Cannot open file";
	
	while(<FILEQA1A>){
		chomp($_);

#		if($_=~m/6_packg/){
#			$Package = substr($_, -2, 2);
#			}
			
		if($_=~m/6_prdct/){
			$Product = substr($_, 8, 8);
			}
		
		if($_=~m/6_sspec/){
			$Qdf = substr($_, -4, 4);
			}
		
		if($_=~m/$Unit/){
			while(<FILEQA1A>){
				chomp($_);
			
			if($_=~m/2_tname_FuseReadCheck_LD1_Composite/){
				$_ = <FILEQA1A>;
				$_ = <FILEQA1A>;
				chomp($_);
				$Fusereadcheck1 = substr($_, 19, 584);
				}
					
			if($_=~m/2_tname_FuseReadCheck_LD2_Composite/){
				$_ = <FILEQA1A>;
				$_ = <FILEQA1A>;
				chomp($_);
				$Fusereadcheck2 = substr($_, 19, 584);
				}
			
			if($_=~m/2_visualid/){
				last;
				}
				}
				}
	}
	
	@PRODUCT = split(//, $Product);
#	$Bkit_id = $PRODUCT[0];
#	$Product_id = $PRODUCT[1];
#	$Market_id = $PRODUCT[2];
#	$Cache_size = $PRODUCT[3];
	$Dlcp_id = $PRODUCT[4];
	$Core_step1 = $PRODUCT[6];
	$Core_step2 = $PRODUCT[7];
	
#	printf "Bkit_id = $Bkit_id\nProduct_id = $Product_id\nMarket_id = $Market_id\nCache_size = $Cache_size\nDlcp_id = $Dlcp_id\nCore_step1 = $Core_step1\nCore_step2 = $Core_step2\n";
	
	@FUSEREADCHECK1 = split(//, $Fusereadcheck1);
	@FUSEB_C0 = @FUSEREADCHECK1[0..285];
	@REV_FUSEB_C0 = reverse(@FUSEB_C0);
	
	@FUSEA_C0 = @FUSEREADCHECK1[286..583];
	@REV_FUSEA_C0 = reverse(@FUSEA_C0);
	
	@FUSEREADCHECK2 = split(//, $Fusereadcheck2);
	@FUSEB_C1 = @FUSEREADCHECK2[0..285];
	@REV_FUSEB_C1 = reverse(@FUSEB_C1);
	
	@FUSEA_C1 = @FUSEREADCHECK2[286..583];
	@REV_FUSEA_C1 = reverse(@FUSEA_C1);
	
	open(FILEFUSESSPEC, "$Spec")|| die "Cannot open file";
	
	while(<FILEFUSESSPEC>){
		chomp($_);

		if($_=~m/$Qdf/){
			@FCLASS = split(/: /, $_);
			$FClass = $FCLASS[2];
#		print "$Qdf\n$FClass\n";
		}
	}
}
		
#1A Part

	open(FILE1A, "$Datalog")|| die "Cannot open file";
	
	while(<FILE1A>){
		chomp($_);
		
		if($_=~m/lcode/){
			$Lcode = substr($_, -4, 4);
		}

		if($_=~m/$Unit/){
			while(<FILE1A>){
				chomp($_);
				
			if($_=~m/2_tname_TS1_trip_calib_res$/){
				while(<FILE1A>){
				chomp($_);
				if($_=~m/2_tssid_LD1/){
				$_ = <FILE1A>;
				chomp($_);
				$TS1_1[$n] = $_;
				last;
				}
				
				if($_=~m/2_tssid_LD2/){
				$_ = <FILE1A>;
				chomp($_);
				$TS1_2[$n] = $_;
				last;
				}
				last;
			}
			}
			
			if($_=~m/2_tname_TS2_trip_calib_res$/){
				while(<FILE1A>){
				chomp($_);
				if($_=~m/2_tssid_LD1/){
				$_ = <FILE1A>;
				chomp($_);
				$TS2_1[$n] = $_;
				last;
				}
				
				if($_=~m/2_tssid_LD2/){
				$_ = <FILE1A>;
				chomp($_);
				$TS2_2[$n] = $_;
				last;
				}
				last;
			}
			}
			
			if($_=~m/2_tname_TS3_trip_calib_res$/){
				while(<FILE1A>){
				chomp($_);
				if($_=~m/2_tssid_LD1/){
				$_ = <FILE1A>;
				chomp($_);
				$TS3_1[$n] = $_;
				last;
				}
				
				if($_=~m/2_tssid_LD2/){
				$_ = <FILE1A>;
				chomp($_);
				$TS3_2[$n] = $_;
				last;
				}
				last;
			}
			}
			
			if($_=~m/2_tname_TS4_trip_calib_res$/){
				while(<FILE1A>){
				chomp($_);
				if($_=~m/2_tssid_LD1/){
				$_ = <FILE1A>;
				chomp($_);
				$TS4_1[$n] = $_;
				last;
				}
				
				if($_=~m/2_tssid_LD2/){
				$_ = <FILE1A>;
				chomp($_);
				$TS4_2[$n] = $_;
				last;
				}
				last;
			}
			}
			
			if($_=~m/2_tname_TS1_trip_calib_res_recalc_offset/){
				while(<FILE1A>){
				chomp($_);
				if($_=~m/2_tssid_LD1/){
				$_ = <FILE1A>;
				chomp($_);
				$RTS1_1[$n] = $_;
				last;
				}
				
				if($_=~m/2_tssid_LD2/){
				$_ = <FILE1A>;
				chomp($_);
				$RTS1_2[$n] = $_;
				last;
				}
				last;
			}
			}
			
			if($_=~m/2_tname_TS2_trip_calib_res_recalc_offset/){
				while(<FILE1A>){
				chomp($_);
				if($_=~m/2_tssid_LD1/){
				$_ = <FILE1A>;
				chomp($_);
				$RTS2_1[$n] = $_;
				last;
				}
				
				if($_=~m/2_tssid_LD2/){
				$_ = <FILE1A>;
				chomp($_);
				$RTS2_2[$n] = $_;
				last;
				}
				last;
			}
			}
			
			if($_=~m/2_tname_TS3_trip_calib_res_recalc_offset/){
				while(<FILE1A>){
				chomp($_);
				if($_=~m/2_tssid_LD1/){
				$_ = <FILE1A>;
				chomp($_);
				$RTS3_1[$n] = $_;
				last;
				}
				
				if($_=~m/2_tssid_LD2/){
				$_ = <FILE1A>;
				chomp($_);
				$RTS3_2[$n] = $_;
				last;
				}
				last;
			}
			}
			
			if($_=~m/2_tname_TS4_trip_calib_res_recalc_offset/){
				while(<FILE1A>){
				chomp($_);
				if($_=~m/2_tssid_LD1/){
				$_ = <FILE1A>;
				chomp($_);
				$RTS4_1[$n] = $_;
				last;
				}
				
				if($_=~m/2_tssid_LD2/){
				$_ = <FILE1A>;
				chomp($_);
				$RTS4_2[$n] = $_;
				last;
				}
				last;
			}
			}
			
			if($_=~m/2_tname_FuseRead_Composite/){
			while(<FILE1A>){
				chomp($_);
				if($_=~m/2_tssid_LD1/){
				$_ = <FILE1A>;
				chomp($_);
				$ULT1[$n] = $_;
				last;
				}
				
				if($_=~m/2_tssid_LD2/){
				$_ = <FILE1A>;
				chomp($_);
				$ULT2[$n] = $_;
				last;
				}
				last;
			}
			}
				
			if($_=~m/2_comnt_DFF_Data_LD1/){
				$LD1[$n] = $_;
				}
				
			if($_=~m/2_comnt_DFF_Data_LD2/){
				$LD2[$n] = $_;
				}
				
			if($_=~m/2_comnt_DFF_Data_PKG/){
				$PKG[$n] = $_;
				}
				
			if($_=~m/3_curibin/){
				$CURIBIN[$n] = $_;
							
				last;
#				goto Start;
			}
		}
#		last;
	}
	}
	
	$Ult1 = $ULT1[$#ULT1];
	$Ult11 = substr($Ult1, 158, 50);
	@ULT11 = split(//, $Ult11);
	@REV_ULT11 = reverse(@ULT11);
	
	$Ult2 = $ULT2[$#ULT2];
	$Ult22 = substr($Ult2, 158, 50);
	@ULT22 = split(//, $Ult22);
	@REV_ULT22 = reverse(@ULT22);
				
	$Ld1 = $LD1[$#LD1];
	@LD1 = split(/,/, $Ld1);
	for($i = 0; $i<=$#LD1; $i++){
		if($LD1[$i]=~m/Thermal_Sensor_Cat_String/){
			$TCat1 = substr($LD1[$i], -12, 12);
			@TCAT1 = split(//, $TCat1);
			@REV_TCAT1 = reverse(@TCAT1);
			$TCat1_0 = $REV_TCAT1[11].$REV_TCAT1[10].$REV_TCAT1[9];
			$TCat1_1 = $REV_TCAT1[8].$REV_TCAT1[7].$REV_TCAT1[6];
			$TCat1_2 = $REV_TCAT1[5].$REV_TCAT1[4].$REV_TCAT1[3];
			$TCat1_3 = $REV_TCAT1[2].$REV_TCAT1[1].$REV_TCAT1[0];
		}
					
		if($LD1[$i]=~m/Thermal_Sensor_String/){
			$TSensor1 = substr($LD1[$i], -28, 28);
			@TSENSOR1 = split(//, $TSensor1);
			@REV_TSENSOR1 = reverse(@TSENSOR1);
			$TSensor1_0 = $REV_TSENSOR1[27].$REV_TSENSOR1[26].$REV_TSENSOR1[25].$REV_TSENSOR1[24].$REV_TSENSOR1[23].$REV_TSENSOR1[22].$REV_TSENSOR1[21];
			$Dec_TSensor1_0 = 64*$REV_TSENSOR1[27] + 32*$REV_TSENSOR1[26] + 16*$REV_TSENSOR1[25] + 8*$REV_TSENSOR1[24] + 4*$REV_TSENSOR1[23] + 2*$REV_TSENSOR1[22] + $REV_TSENSOR1[21];
			$TSensor1_1 = $REV_TSENSOR1[20].$REV_TSENSOR1[19].$REV_TSENSOR1[18].$REV_TSENSOR1[17].$REV_TSENSOR1[16].$REV_TSENSOR1[15].$REV_TSENSOR1[14];
			$Dec_TSensor1_1 = 64*$REV_TSENSOR1[20] + 32*$REV_TSENSOR1[19] + 16*$REV_TSENSOR1[18] + 8*$REV_TSENSOR1[17] + 4*$REV_TSENSOR1[16] + 2*$REV_TSENSOR1[15] + $REV_TSENSOR1[14];
			$TSensor1_2 = $REV_TSENSOR1[13].$REV_TSENSOR1[12].$REV_TSENSOR1[11].$REV_TSENSOR1[10].$REV_TSENSOR1[9].$REV_TSENSOR1[8].$REV_TSENSOR1[7];
			$Dec_TSensor1_2 = 64*$REV_TSENSOR1[13] + 32*$REV_TSENSOR1[12] + 16*$REV_TSENSOR1[11] + 8*$REV_TSENSOR1[10] + 4*$REV_TSENSOR1[9] + 2*$REV_TSENSOR1[8] + $REV_TSENSOR1[7];
			$TSensor1_3 = $REV_TSENSOR1[6].$REV_TSENSOR1[5].$REV_TSENSOR1[4].$REV_TSENSOR1[3].$REV_TSENSOR1[2].$REV_TSENSOR1[1].$REV_TSENSOR1[0];
			$Dec_TSensor1_3 = 64*$REV_TSENSOR1[6] + 32*$REV_TSENSOR1[5] + 16*$REV_TSENSOR1[4] + 8*$REV_TSENSOR1[3] + 4*$REV_TSENSOR1[2] + 2*$REV_TSENSOR1[1] + $REV_TSENSOR1[0];
		}
	}
	
	$Ld2 = $LD2[$#LD2];
	@LD2 = split(/,/, $Ld2);
	for($i = 0; $i<=$#LD2; $i++){
		if($LD2[$i]=~m/Thermal_Sensor_Cat_String/){
			$TCat2 = substr($LD2[$i], -12, 12);
			@TCAT2 = split(//, $TCat2);
			@REV_TCAT2 = reverse(@TCAT2);
			$TCat2_0 = $REV_TCAT2[11].$REV_TCAT2[10].$REV_TCAT2[9];
			$TCat2_1 = $REV_TCAT2[8].$REV_TCAT2[7].$REV_TCAT2[6];
			$TCat2_2 = $REV_TCAT2[5].$REV_TCAT2[4].$REV_TCAT2[3];
			$TCat2_3 = $REV_TCAT2[2].$REV_TCAT2[1].$REV_TCAT2[0];
		}
				
		if($LD2[$i]=~m/Thermal_Sensor_String/){
			$TSensor2 = substr($LD2[$i], -28, 28);
			@TSENSOR2 = split(//, $TSensor2);
			@REV_TSENSOR2 = reverse(@TSENSOR2);
			$TSensor2_0 = $REV_TSENSOR2[27].$REV_TSENSOR2[26].$REV_TSENSOR2[25].$REV_TSENSOR2[24].$REV_TSENSOR2[23].$REV_TSENSOR2[22].$REV_TSENSOR2[21];
			$Dec_TSensor2_0 = 64*$REV_TSENSOR2[27] + 32*$REV_TSENSOR2[26] + 16*$REV_TSENSOR2[25] + 8*$REV_TSENSOR2[24] + 4*$REV_TSENSOR2[23] + 2*$REV_TSENSOR2[22] + $REV_TSENSOR2[21];
			$TSensor2_1 = $REV_TSENSOR2[20].$REV_TSENSOR2[19].$REV_TSENSOR2[18].$REV_TSENSOR2[17].$REV_TSENSOR2[16].$REV_TSENSOR2[15].$REV_TSENSOR2[14];
			$Dec_TSensor2_1 = 64*$REV_TSENSOR2[20] + 32*$REV_TSENSOR2[19] + 16*$REV_TSENSOR2[18] + 8*$REV_TSENSOR2[17] + 4*$REV_TSENSOR2[16] + 2*$REV_TSENSOR2[15] + $REV_TSENSOR2[14];
			$TSensor2_2 = $REV_TSENSOR2[13].$REV_TSENSOR2[12].$REV_TSENSOR2[11].$REV_TSENSOR2[10].$REV_TSENSOR2[9].$REV_TSENSOR2[8].$REV_TSENSOR2[7];
			$Dec_TSensor2_2 = 64*$REV_TSENSOR2[13] + 32*$REV_TSENSOR2[12] + 16*$REV_TSENSOR2[11] + 8*$REV_TSENSOR2[10] + 4*$REV_TSENSOR2[9] + 2*$REV_TSENSOR2[8] + $REV_TSENSOR2[7];
			$TSensor2_3 = $REV_TSENSOR2[6].$REV_TSENSOR2[5].$REV_TSENSOR2[4].$REV_TSENSOR2[3].$REV_TSENSOR2[2].$REV_TSENSOR2[1].$REV_TSENSOR2[0];
			$Dec_TSensor2_3 = 64*$REV_TSENSOR2[6] + 32*$REV_TSENSOR2[5] + 16*$REV_TSENSOR2[4] + 8*$REV_TSENSOR2[3] + 4*$REV_TSENSOR2[2] + 2*$REV_TSENSOR2[1] + $REV_TSENSOR2[0];
		}
		}
		
	$Pkg = $PKG[$#PKG];
	@PKG = split(/,/, $Pkg);
	for($i = 0; $i<=$#PKG; $i++){
		if($PKG[$i]=~m/PKG_AVID/){
			$Dec_Avid = $PKG[$i];
			@DEC_AVID = split(/=/, $Dec_Avid);
			$Dec_Avid = $DEC_AVID[1];
			}
	
		if($PKG[$i]=~m/AVID_BINARY/){
			$Avid = substr($PKG[$i], -6, 6);
			@AVID = split(//, $Avid);
			@REV_AVID = reverse(@AVID);
			}
			
		if($PKG[$i]=~m/AVID_Cdyn/){
			$Avid_Cdyn = $PKG[$i];
			@AVID_CDYN = split(/=/, $Avid_Cdyn);
			$Avid_Cdyn = $AVID_CDYN[1];
			}
			
		if($PKG[$i]=~m/AVID_CdynVnom/){
			$Avid_CdynVnom = $PKG[$i];
			@AVID_CDYNVNOM = split(/=/, $Avid_CdynVnom);
			$Avid_CdynVnom = $AVID_CDYNVNOM[1];
			}
		
		if($PKG[$i]=~m/AVID_Isb/){
			$Avid_Isb = $PKG[$i];
			@AVID_ISB = split(/=/, $Avid_Isb);
			$Avid_Isb = $AVID_ISB[1];
			}
		
		if($PKG[$i]=~m/AVID_Sicc/){
			$Avid_Sicc = $PKG[$i];
			@AVID_SICC = split(/=/, $Avid_Sicc);
			$Avid_Sicc = $AVID_SICC[1];
			}
		
		if($PKG[$i]=~m/AVID_TDC/){
			$Avid_Tdc = $PKG[$i];
			@AVID_TDC = split(/=/, $Avid_Tdc);
			$Avid_Tdc = $AVID_TDC[1];
			}
		
		if($PKG[$i]=~m/AVID_Vmax/){
			$Avid_Vmax = $PKG[$i];
			@AVID_VMAX = split(/=/, $Avid_Vmax);
			$Avid_Vmax = $AVID_VMAX[1];
			}
		
		if($PKG[$i]=~m/AVID_Vmin/){
			$Avid_Vmin = $PKG[$i];
			@AVID_VMIN = split(/=/, $Avid_Vmin);
			$Avid_Vmin = $AVID_VMIN[1];
			}
		
		if($PKG[$i]=~m/AVID_Vnom/){
			$Avid_Vnom = $PKG[$i];
			@AVID_VNOM = split(/=/, $Avid_Vnom);
			$Avid_Vnom = $AVID_VNOM[1];
			}
		
		if($PKG[$i]=~m/ST_BINARY/){
			$St = substr($PKG[$i], -5, 5);
			@ST = split(//, $St);
			@REV_ST = reverse(@ST);
			}
		}

	if ($RTS1_1[$#RTS1_1] != " "){
	$RTs1_1 = $RTS1_1[$#RTS1_1];
	$Ts1_1 = substr($RTs1_1, -2, 2);
	
	$RTs2_1 = $RTS2_1[$#RTS2_1];
	$Ts2_1 = substr($RTs2_1, -2, 2);
	
	$RTs3_1 = $RTS3_1[$#RTS3_1];
	$Ts3_1 = substr($RTs3_1, -2, 2);
	
	$RTs4_1 = $RTS4_1[$#RTS4_1];
	$Ts4_1 = substr($RTs4_1, -2, 2);
	
	$RTs1_2 = $RTS1_2[$#RTS1_2];
	$Ts1_2 = substr($RTs1_2, -2, 2);
	
	$RTs2_2 = $RTS2_2[$#RTS2_2];
	$Ts2_2 = substr($RTs2_2, -2, 2);
	
	$RTs3_2 = $RTS3_2[$#RTS3_2];
	$Ts3_2 = substr($RTs3_2, -2, 2);
	
	$RTs4_2 = $RTS4_2[$#RTS4_2];
	$Ts4_2 = substr($RTs4_2, -2, 2);
	}
	
	if($RTS1_1[$#RTS1_1] == " "){
	$Ts1_1 = $TS1_1[$#TS1_1];
	$Ts1_1 = substr($Ts1_1, -2, 2);
	
	$Ts2_1 = $TS2_1[$#TS2_1];
	$Ts2_1 = substr($Ts2_1, -2, 2);
	
	$Ts3_1 = $TS3_1[$#TS3_1];
	$Ts3_1 = substr($Ts3_1, -2, 2);
	
	$Ts4_1 = $TS4_1[$#TS4_1];
	$Ts4_1 = substr($Ts4_1, -2, 2);
	
	$Ts1_2 = $TS1_2[$#TS1_2];
	$Ts1_2 = substr($Ts1_2, -2, 2);
	
	$Ts2_2 = $TS2_2[$#TS2_2];
	$Ts2_2 = substr($Ts2_2, -2, 2);
	
	$Ts3_2 = $TS3_2[$#TS3_2];
	$Ts3_2 = substr($Ts3_2, -2, 2);
	
	$Ts4_2 = $TS4_2[$#TS4_2];
	$Ts4_2 = substr($Ts4_2, -2, 2);
	}
	
	$Curibin = $CURIBIN[$#CURIBIN];
	$Curibin = substr($Curibin, 10, 2);
	
#OLF Part

	open(FILEUBE, "$Ube")|| die "Cannot open file";
	
	while(<FILEUBE>){
		chomp($_);

		if($_=~m/UNIT,$Unit/){
			while(<FILEUBE>){
				chomp($_);
				
			if($_=~m/PKG,PBIC_S1/){
				$Pkg_olf = $_;
				}
				
			if($_=~m/LD1,PBIC_S1/){
				$Ld1_olf = $_;
				}
			
			if($_=~m/LD2,PBIC_S1/){
				$Ld2_olf = $_;
				}
			
			if($_=~m/UNIT/){
				last;
			}
			}
			}
		}
		
	@PKG_OLF = split(/,/, $Pkg_olf);
	for($i = 0; $i<=$#PKG_OLF; $i++){
		if($PKG_OLF[$i]=~m/AVID=/){
			$Dec_Avid_olf = $PKG_OLF[$i];
			@DEC_AVID_OLF = split(/=/, $Dec_Avid_olf);
			$Dec_Avid_olf = $DEC_AVID_OLF[1];
			}
	
		if($PKG_OLF[$i]=~m/AVID_BINARY/){
			$Avid_olf = substr($PKG_OLF[$i], -6, 6);
			}
			
		if($PKG_OLF[$i]=~m/AVID_Cdyn/){
			$Avid_Cdyn_olf = $PKG_OLF[$i];
			@AVID_CDYN_OLF = split(/=/, $Avid_Cdyn_olf);
			$Avid_Cdyn_olf = $AVID_CDYN_OLF[1];
			}
			
		if($PKG_OLF[$i]=~m/AVID_CdynVnom/){
			$Avid_CdynVnom_olf = $PKG_OLF[$i];
			@AVID_CDYNVNOM_OLF = split(/=/, $Avid_CdynVnom_olf);
			$Avid_CdynVnom_olf = $AVID_CDYNVNOM_OLF[1];
			}
		
		if($PKG_OLF[$i]=~m/AVID_Isb/){
			$Avid_Isb_olf = $PKG_OLF[$i];
			@AVID_ISB_OLF = split(/=/, $Avid_Isb_olf);
			$Avid_Isb_olf = $AVID_ISB_OLF[1];
			}
		
		if($PKG_OLF[$i]=~m/AVID_Sicc/){
			$Avid_Sicc_olf = $PKG_OLF[$i];
			@AVID_SICC_OLF = split(/=/, $Avid_Sicc_olf);
			$Avid_Sicc_olf = $AVID_SICC_OLF[1];
			}
		
		if($PKG_OLF[$i]=~m/AVID_TDC/){
			$Avid_Tdc_olf = $PKG_OLF[$i];
			@AVID_TDC_OLF = split(/=/, $Avid_Tdc_olf);
			$Avid_Tdc_olf = $AVID_TDC_OLF[1];
			}
		
		if($PKG_OLF[$i]=~m/AVID_Vmax/){
			$Avid_Vmax_olf = $PKG_OLF[$i];
			@AVID_VMAX_OLF = split(/=/, $Avid_Vmax_olf);
			$Avid_Vmax_olf = $AVID_VMAX_OLF[1];
			}
		
		if($PKG_OLF[$i]=~m/AVID_Vmin/){
			$Avid_Vmin_olf = $PKG_OLF[$i];
			@AVID_VMIN_OLF = split(/=/, $Avid_Vmin_olf);
			$Avid_Vmin_olf = $AVID_VMIN_OLF[1];
			}
		
		if($PKG_OLF[$i]=~m/AVID_Vnom/){
			$Avid_Vnom_olf = $PKG_OLF[$i];
			@AVID_VNOM_OLF = split(/=/, $Avid_Vnom_olf);
			$Avid_Vnom_olf = $AVID_VNOM_OLF[1];
			}
		
		if($PKG_OLF[$i]=~m/ST_BINARY/){
			$St_olf = substr($PKG_OLF[$i], -5, 5);
			}
		}
		
	@LD1_OLF = split(/,/, $Ld1_olf);
	for($i = 0; $i<=$#LD1_OLF; $i++){
		if($LD1_OLF[$i]=~m/Thermal_Sensor_Cat_String/){
			$TCat1_olf = $LD1_OLF[$i];
			@TCAT1_OLF = split(/=/, $TCat1_olf);
			$TCat1_olf = $TCAT1_OLF[1];
		}
					
		if($LD1_OLF[$i]=~m/Thermal_Sensor_String/){
			$TSensor1_olf = $LD1_OLF[$i];
			@TSENSOR1_OLF = split(/=/, $TSensor1_olf);
			$TSensor1_olf = $TSENSOR1_OLF[1];
		}
	}
	
	@LD2_OLF = split(/,/, $Ld2_olf);
	for($i = 0; $i<=$#LD2_OLF; $i++){
		if($LD2_OLF[$i]=~m/Thermal_Sensor_Cat_String/){
			$TCat2_olf = $LD2_OLF[$i];
			@TCAT2_OLF = split(/=/, $TCat2_olf);
			$TCat2_olf = $TCAT2_OLF[1];
			}
		
		if($LD2_OLF[$i]=~m/Thermal_Sensor_String/){
			$TSensor2_olf = $LD2_OLF[$i];
			@TSENSOR2_OLF = split(/=/, $TSensor2_olf);
			$TSensor2_olf = $TSENSOR2_OLF[1];
		}
		}

#QA Part

	open(FILEQA, "$Qa")|| die "Cannot open file";
	
	while(<FILEQA>){
		chomp($_);

		if($_=~m/UNIT,$Unit/){
			while(<FILEQA>){
				chomp($_);
				
			if($_=~m/PKG,PBIC_S1/){
				$Pkg_qa = $_;
				}
				
			if($_=~m/LD1,PBIC_S1/){
				$Ld1_qa = $_;
				}
			
			if($_=~m/LD2,PBIC_S1/){
				$Ld2_qa = $_;
				}
			
			if($_=~m/UNIT/){
				last;
			}
			}
			}
		}
		
	@PKG_QA = split(/,/, $Pkg_qa);
	for($i = 0; $i<=$#PKG_QA; $i++){
		if($PKG_QA[$i]=~m/AVID=/){
			$Dec_Avid_qa = $PKG_QA[$i];
			@DEC_AVID_QA = split(/=/, $Dec_Avid_qa);
			$Dec_Avid_qa = $DEC_AVID_QA[1];
			}
	
		if($PKG_QA[$i]=~m/AVID_BINARY/){
			$Avid_qa = substr($PKG_QA[$i], -6, 6);
			}
			
		if($PKG_QA[$i]=~m/AVID_Cdyn/){
			$Avid_Cdyn_qa = $PKG_QA[$i];
			@AVID_CDYN_QA = split(/=/, $Avid_Cdyn_qa);
			$Avid_Cdyn_qa = $AVID_CDYN_QA[1];
			}
			
		if($PKG_QA[$i]=~m/AVID_CdynVnom/){
			$Avid_CdynVnom_qa = $PKG_QA[$i];
			@AVID_CDYNVNOM_QA = split(/=/, $Avid_CdynVnom_qa);
			$Avid_CdynVnom_qa = $AVID_CDYNVNOM_QA[1];
			}
		
		if($PKG_QA[$i]=~m/AVID_Isb/){
			$Avid_Isb_qa = $PKG_QA[$i];
			@AVID_ISB_QA = split(/=/, $Avid_Isb_qa);
			$Avid_Isb_qa = $AVID_ISB_QA[1];
			}
		
		if($PKG_QA[$i]=~m/AVID_Sicc/){
			$Avid_Sicc_qa = $PKG_QA[$i];
			@AVID_SICC_QA = split(/=/, $Avid_Sicc_qa);
			$Avid_Sicc_qa = $AVID_SICC_QA[1];
			}
		
		if($PKG_QA[$i]=~m/AVID_TDC/){
			$Avid_Tdc_qa = $PKG_QA[$i];
			@AVID_TDC_QA = split(/=/, $Avid_Tdc_qa);
			$Avid_Tdc_qa = $AVID_TDC_QA[1];
			}
		
		if($PKG_QA[$i]=~m/AVID_Vmax/){
			$Avid_Vmax_qa = $PKG_QA[$i];
			@AVID_VMAX_QA = split(/=/, $Avid_Vmax_qa);
			$Avid_Vmax_qa = $AVID_VMAX_QA[1];
			}
		
		if($PKG_QA[$i]=~m/AVID_Vmin/){
			$Avid_Vmin_qa = $PKG_QA[$i];
			@AVID_VMIN_QA = split(/=/, $Avid_Vmin_qa);
			$Avid_Vmin_qa = $AVID_VMIN_QA[1];
			}
		
		if($PKG_QA[$i]=~m/AVID_Vnom/){
			$Avid_Vnom_qa = $PKG_QA[$i];
			@AVID_VNOM_QA = split(/=/, $Avid_Vnom_qa);
			$Avid_Vnom_qa = $AVID_VNOM_QA[1];
			}
		
		if($PKG_QA[$i]=~m/ST_BINARY/){
			$St_qa = substr($PKG_QA[$i], -5, 5);
			}
		}
		
	@LD1_QA = split(/,/, $Ld1_qa);
	for($i = 0; $i<=$#LD1_QA; $i++){
		if($LD1_QA[$i]=~m/Thermal_Sensor_Cat_String/){
			$TCat1_qa = $LD1_QA[$i];
			@TCAT1_QA = split(/=/, $TCat1_qa);
			$TCat1_qa = $TCAT1_QA[1];
		}
					
		if($LD1_QA[$i]=~m/Thermal_Sensor_String/){
			$TSensor1_qa = $LD1_QA[$i];
			@TSENSOR1_QA = split(/=/, $TSensor1_qa);
			$TSensor1_qa = $TSENSOR1_QA[1];
		}
	}
	
	@LD2_QA = split(/,/, $Ld2_qa);
	for($i = 0; $i<=$#LD2_QA; $i++){
		if($LD2_QA[$i]=~m/Thermal_Sensor_Cat_String/){
			$TCat2_qa = $LD2_QA[$i];
			@TCAT2_QA = split(/=/, $TCat2_qa);
			$TCat2_qa = $TCAT2_QA[1];
			}
		
		if($LD2_QA[$i]=~m/Thermal_Sensor_String/){
			$TSensor2_qa = $LD2_QA[$i];
			@TSENSOR2_QA = split(/=/, $TSensor2_qa);
			$TSensor2_qa = $TSENSOR2_QA[1];
		}
		}
		
# Custom Part
	
#if($Qadatalog eq " "){	
	@DEVICE = split(/_/, $FClass);
	$Device = $DEVICE[0];
	$Cspeed = $DEVICE[1];
	$Fsb = $DEVICE[2];
	@DEVICE = split(//, $Device);
	$Package = $DEVICE[0].$DEVICE[1];
	$Bkit_id = $DEVICE[2];
	$Product_id = $DEVICE[3];
	$Market_id = $DEVICE[4];
	$Cache_size = $DEVICE[5];
	@CSPEED = split(//, $Cspeed);
	$Cspeed1 = $CSPEED[0];
	$Cspeed2 = $CSPEED[1];
	$Cspeed3 = $CSPEED[2];
	$Cspeed4 = $CSPEED[3];
	@FSB = split(//, $Fsb);
	$Fsb1 = $FSB[0];
	$Fsb2 = $FSB[1];
	$Fsb3 = $FSB[2];
		
if($Ppvlog ne " "){	
	@CORE_STEP = split(//, $Core_step);
	$Core_step1 = $CORE_STEP[0];
	$Core_step2 = $CORE_STEP[1];
	}
	
#	printf "Bkit_id = $Bkit_id\nProduct_id = $Product_id\nMarket_id = $Market_id\nCache_size = $Cache_size\nDlcp_id = $Dlcp_id\nCore_step1 = $Core_step1\nCore_step2 = $Core_step2\n";

	open(FILECUSTOM, "$Custom")|| die "Cannot open file";

while(<FILECUSTOM>){
	chomp($_);

#	if($_=~m/CUSTOM_PACKAGE =~ "$Package" && CUSTOM_DEVICE =~ "\[..\]\[$Product_id\]\[$Market_id\]\[$Cache_size\]\[$Dlcp_id\]\." && CUSTOM_REV =~ "$Core_step1" && CUSTOM_STEP =~ "$Core_step2"/){
	if($_=~m/define : DYNUF : STRING : CUSTOM_TCTRL_FINAL: LITERAL        : "......" : CUSTOM_L2SPEC =~ "\[$DEVICE[0]\]\[$DEVICE[1]\]\[..\]\[$Product_id\]\[$Market_id\]\[$Cache_size\]\.\+" && CUSTOM_PACKAGE =~ "$Package" && CUSTOM_DEVICE =~ "\[..\]...\[$Dlcp_id\]\." && CUSTOM_REV =~ "$Core_step1" && CUSTOM_STEP =~ "$Core_step2"/){
		@TCONTROL = split(/"/, $_);
		$TControl = $TCONTROL[1];
		@TCONTROL = split(//, $TControl);
		@REV_TCONTROL = reverse(@TCONTROL);
	}
	
	if($_=~m/define : DYNUF : STRING : CUSTOM_TCTRL_FINAL: LITERAL        : "......" : CUSTOM_L2SPEC =~ "\[$DEVICE[0]\]\[$DEVICE[1]\]\[..\]\[$Product_id\]\[$Market_id\]\[$Cache_size\]\.\[$Cspeed1\]\[$Cspeed2\]\[$Cspeed3\]\[$Cspeed4\]\.\[$Fsb1\]\[$Fsb2\]\[$Fsb3\]\.\+" && CUSTOM_PACKAGE =~ "$Package" && CUSTOM_DEVICE =~ "\[..\]...\[$Dlcp_id\]\." && CUSTOM_REV =~ "$Core_step1" && CUSTOM_STEP =~ "$Core_step2"/){
		@TCONTROL = split(/"/, $_);
		$TControl = $TCONTROL[1];
		@TCONTROL = split(//, $TControl);
		@REV_TCONTROL = reverse(@TCONTROL);
	}
}				
			
#FuseSSpec Part
			
	open(FILEFUSESSPEC, "$Spec")|| die "Cannot open file";
	
while(<FILEFUSESSPEC>){
	chomp($_);

	if($_=~m/LD1:   BankA:	$FClass/){
		@FUSEFILE1_A = split(/: /, $_);
		$Fusefile1_A = $FUSEFILE1_A[$#FUSEFILE1_A];
		@FUSEFILE1_A = split(//, $Fusefile1_A);
		@REV_FUSEFILE1_A = reverse(@FUSEFILE1_A);
		}
		
	if($_=~m/LD1:   BankB:	$FClass/){
		@FUSEFILE1_B = split(/: /, $_);
		$Fusefile1_B = $FUSEFILE1_B [$#FUSEFILE1_B];
		@FUSEFILE1_B = split(//, $Fusefile1_B);
		@REV_FUSEFILE1_B = reverse(@FUSEFILE1_B);
		}
		
	if($_=~m/LD2:   BankA:	$FClass/){
		@FUSEFILE2_A = split(/: /, $_);
		$Fusefile2_A = $FUSEFILE2_A[$#FUSEFILE2_A];
		@FUSEFILE2_A = split(//, $Fusefile2_A);
		@REV_FUSEFILE2_A = reverse(@FUSEFILE2_A);
		}
		
	if($_=~m/LD2:   BankB:	$FClass/){
		@FUSEFILE2_B = split(/: /, $_);
		$Fusefile2_B = $FUSEFILE2_B[$#FUSEFILE2_B];
		@FUSEFILE2_B = split(//, $Fusefile2_B);
		@REV_FUSEFILE2_B = reverse(@FUSEFILE2_B);
		}
}
	
#Replace the "m" strings with grabbed data from data log
	
	if(@REV_FUSEFILE1_A[289] eq "m"){splice(@REV_FUSEFILE1_A, 289, 7, @REV_TSENSOR1[0..6]);}
	if(@REV_FUSEFILE2_A[289] eq "m"){splice(@REV_FUSEFILE2_A, 289, 7, @REV_TSENSOR2[0..6]);}
	if(@REV_FUSEFILE1_A[235] eq "m"){splice(@REV_FUSEFILE1_A, 235, 6, @REV_TCONTROL);}
	if(@REV_FUSEFILE2_A[235] eq "m"){splice(@REV_FUSEFILE2_A, 235, 6, @REV_TCONTROL);}
	if(@REV_FUSEFILE1_A[184] eq "m"){splice(@REV_FUSEFILE1_A, 184, 7, @REV_TSENSOR1[21..27]);}
	if(@REV_FUSEFILE2_A[184] eq "m"){splice(@REV_FUSEFILE2_A, 184, 7, @REV_TSENSOR2[21..27]);}
	if(@REV_FUSEFILE1_A[176] eq "m"){splice(@REV_FUSEFILE1_A, 176, 7, @REV_TSENSOR1[14..20]);}
	if(@REV_FUSEFILE2_A[176] eq "m"){splice(@REV_FUSEFILE2_A, 176, 7, @REV_TSENSOR2[14..20]);}
	if(@REV_FUSEFILE1_A[167] eq "m"){splice(@REV_FUSEFILE1_A, 167, 7, @REV_TSENSOR1[7..13]);}
	if(@REV_FUSEFILE2_A[167] eq "m"){splice(@REV_FUSEFILE2_A, 167, 7, @REV_TSENSOR2[7..13]);}
	if(@REV_FUSEFILE1_A[139] eq "m"){splice(@REV_FUSEFILE1_A, 139, 3, @REV_TCAT1[9..11]);}
	if(@REV_FUSEFILE2_A[139] eq "m"){splice(@REV_FUSEFILE2_A, 139, 3, @REV_TCAT2[9..11]);}
	if(@REV_FUSEFILE1_A[30] eq "m"){splice(@REV_FUSEFILE1_A, 30, 6, @REV_AVID);}
	if(@REV_FUSEFILE2_A[30] eq "m"){splice(@REV_FUSEFILE2_A, 30, 6, @REV_AVID);}
	if(@REV_FUSEFILE1_A[36] eq "m"){splice(@REV_FUSEFILE1_A, 36, 6, @REV_AVID);}
	if(@REV_FUSEFILE2_A[36] eq "m"){splice(@REV_FUSEFILE2_A, 36, 6, @REV_AVID);}
	if(@REV_FUSEFILE1_B[79] eq "m"){splice(@REV_FUSEFILE1_B, 79, 3, @REV_TCAT1[0..2]);}
	if(@REV_FUSEFILE2_B[79] eq "m"){splice(@REV_FUSEFILE2_B, 79, 3, @REV_TCAT2[0..2]);}
	if(@REV_FUSEFILE1_B[82] eq "m"){splice(@REV_FUSEFILE1_B, 82, 3, @REV_TCAT1[3..5]);}
	if(@REV_FUSEFILE2_B[82] eq "m"){splice(@REV_FUSEFILE2_B, 82, 3, @REV_TCAT2[3..5]);}
	if(@REV_FUSEFILE1_B[85] eq "m"){splice(@REV_FUSEFILE1_B, 85, 3, @REV_TCAT1[6..8]);}
	if(@REV_FUSEFILE2_B[85] eq "m"){splice(@REV_FUSEFILE2_B, 85, 3, @REV_TCAT2[6..8]);}
	if(@REV_FUSEFILE1_B[88] eq "m"){splice(@REV_FUSEFILE1_B, 88, 5, @REV_ST);}
	if(@REV_FUSEFILE2_B[88] eq "m"){splice(@REV_FUSEFILE2_B, 88, 5, @REV_ST);}
	splice(@REV_FUSEFILE1_B, 97, 50, @REV_ULT11);
	splice(@REV_FUSEFILE2_B, 97, 50, @REV_ULT22);
	
# Compare
# @REV_FUSEFILE1_A with @REV_FUSEA_C0
		$MM1A = 0;
	for($b = 297; $b >= 0; $b--){
		if ($REV_FUSEFILE1_A[$b] eq "s"){
			@MISMATCH1A[$b] = " ";
		}
		
		if (($REV_FUSEFILE1_A[$b] ne "s") && ($REV_FUSEFILE1_A[$b] == $REV_FUSEA_C0[$b])){
			@MISMATCH1A[$b] = " ";
		}
		
		if (($REV_FUSEFILE1_A[$b] ne "s") && ($REV_FUSEFILE1_A[$b] != $REV_FUSEA_C0[$b])){
			@MISMATCH1A[$b] = X;
			$MM1A ++;
		}
	}
	
# @REV_FUSEFILE2_A with @REV_FUSEA_C1
		$MM2A = 0;
	for($b = 297; $b >= 0; $b--){
		if ($REV_FUSEFILE2_A[$b] eq "s"){
			@MISMATCH2A[$b] = " ";
		}
		
		if (($REV_FUSEFILE2_A[$b] ne "s") && ($REV_FUSEFILE2_A[$b] == $REV_FUSEA_C1[$b])){
			@MISMATCH2A[$b] = " ";
		}
		
		if (($REV_FUSEFILE2_A[$b] ne "s") && ($REV_FUSEFILE2_A[$b] != $REV_FUSEA_C1[$b])){
			@MISMATCH2A[$b] = X;
			$MM2A ++;
		}
	}

# @REV_FUSEFILE1_B with @REV_FUSEB_C0
		$MM1B = 0;
	for($b = 285; $b >= 0; $b--){
		if ($REV_FUSEFILE1_B[$b] eq "s"){
			@MISMATCH1B[$b] = " ";
		}
		
		if (($REV_FUSEFILE1_B[$b] ne "s") && ($REV_FUSEFILE1_B[$b] == $REV_FUSEB_C0[$b])){
			@MISMATCH1B[$b] = " ";
		}
		
		if (($REV_FUSEFILE1_B[$b] ne "s") && ($REV_FUSEFILE1_B[$b] != $REV_FUSEB_C0[$b])){
			@MISMATCH1B[$b] = X;
			$MM1B ++;
		}
	}

# @REV_FUSEFILE2_B with @REV_FUSEB_C1
		$MM2B = 0;
	for($b = 285; $b >= 0; $b--){
		if ($REV_FUSEFILE2_B[$b] eq "s"){
			@MISMATCH2B[$b] = " ";
		}
		
		if (($REV_FUSEFILE2_B[$b] ne "s") && ($REV_FUSEFILE2_B[$b] == $REV_FUSEB_C1[$b])){
			@MISMATCH2B[$b] = " ";
		}
		
		if (($REV_FUSEFILE2_B[$b] ne "s") && ($REV_FUSEFILE2_B[$b] != $REV_FUSEB_C1[$b])){
			@MISMATCH2B[$b] = X;
			$MM2B ++;
		}
	}
	
	open(PRINTFILE, ">>$Output");
	
	printf (PRINTFILE "Validation $dd\n");
	printf (PRINTFILE "~~~~~~~~~~~~~~~~~\n\n");
	
	if($Curibin > 6){
		printf (PRINTFILE "Bin $Curibin is a failing bin, please use the next summary datalog for validation.");
	}
	
	else{
	printf (PRINTFILE "Thermal Sensor String Summary for Class datalog ($Lcode): \n");
	printf (PRINTFILE "===========================================================\n");
	printf (PRINTFILE "%-40s %-35s %-35s %-34s %s\n", "Description", "Data from $Lcode datalog (Binary)", "Data from $Lcode datalog (Decimal)", "Data from Calculation", "Compare");
	printf (PRINTFILE "---------------------------------------------------------------------------------------------------------------------------------------------------------------------\n");
	printf (PRINTFILE "%-40s %-35s %-35d %-35d", "Thermal Sensor String 0 for die 1", "$TSensor1_0", "$Ts1_1", "$Dec_TSensor1_0");
		if ($Ts1_1 == $Dec_TSensor1_0) {printf (PRINTFILE "%s\n", "TRUE");} else {printf(PRINTFILE "%s\n", "FALSE");}
	printf (PRINTFILE "%-40s %-35s %-35d %-35d", "Thermal Sensor String 1 for die 1", "$TSensor1_1", "$Ts2_1", "$Dec_TSensor1_1");
		if ($Ts2_1 == $Dec_TSensor1_1) {printf (PRINTFILE "%s\n", "TRUE");} else {printf(PRINTFILE "%s\n", "FALSE");}
	printf (PRINTFILE "%-40s %-35s %-35d %-35d", "Thermal Sensor String 2 for die 1", "$TSensor1_2", "$Ts3_1", "$Dec_TSensor1_2");
		if ($Ts3_1 == $Dec_TSensor1_2) {printf (PRINTFILE "%s\n", "TRUE");} else {printf(PRINTFILE "%s\n", "FALSE");}
	printf (PRINTFILE "%-40s %-35s %-35d %-35d", "Thermal Sensor String 3 for die 1", "$TSensor1_3", "$Ts4_1", "$Dec_TSensor1_3");
		if ($Ts4_1 == $Dec_TSensor1_3) {printf (PRINTFILE "%s\n", "TRUE");} else {printf(PRINTFILE "%s\n", "FALSE");}
	printf (PRINTFILE "%-40s %-35s %-35d %-35d", "Thermal Sensor String 0 for die 2", "$TSensor2_0", "$Ts1_2", "$Dec_TSensor2_0");
		if ($Ts1_2 == $Dec_TSensor2_0) {printf (PRINTFILE "%s\n", "TRUE");} else {printf(PRINTFILE "%s\n", "FALSE");}
	printf (PRINTFILE "%-40s %-35s %-35d %-35d", "Thermal Sensor String 1 for die 2", "$TSensor2_1", "$Ts2_2", "$Dec_TSensor2_1");
		if ($Ts2_2 == $Dec_TSensor2_1) {printf (PRINTFILE "%s\n", "TRUE");} else {printf(PRINTFILE "%s\n", "FALSE");}
	printf (PRINTFILE "%-40s %-35s %-35d %-35d", "Thermal Sensor String 2 for die 2", "$TSensor2_2", "$Ts3_2", "$Dec_TSensor2_2");
		if ($Ts3_2 == $Dec_TSensor2_2) {printf (PRINTFILE "%s\n", "TRUE");} else {printf(PRINTFILE "%s\n", "FALSE");}
	printf (PRINTFILE "%-40s %-35s %-35d %-35d", "Thermal Sensor String 3 for die 2", "$TSensor2_3", "$Ts4_2", "$Dec_TSensor2_3");
		if ($Ts4_2 == $Dec_TSensor2_3) {printf (PRINTFILE "%s\n\n\n", "TRUE");} else {printf(PRINTFILE "%s\n\n\n", "FALSE");}
	
	printf (PRINTFILE "Comparison Summary for Class datalog and UBE Information: \n");
	printf (PRINTFILE "==========================================================\n");
	printf (PRINTFILE "%-40s %-35s %-35s %-34s %s\n", "Description", "Data from $Lcode Class Datalog", "UBE Information from OLF", "UBE Information from QA", "Compare");
	printf (PRINTFILE "----------------------------------------------------------------------------------------------------------------------------------------------------------------------\n");
	printf (PRINTFILE "%-40s %-35s %-35s %-35s", "Thermal Sensor Cat String for die 1", "$TCat1", "$TCat1_olf", "$TCat1_qa");
		if (($TCat1 == $TCat1_olf) && ($TCat1 == $TCat1_qa)) {printf (PRINTFILE "%s\n", "TRUE");} else {printf(PRINTFILE "%s\n", "FALSE");}
	printf (PRINTFILE "%-40s %-35s %-35s %-35s", "Thermal Sensor Cat String for die 2", "$TCat2", "$TCat2_olf", "$TCat2_qa");
		if (($TCat2 == $TCat2_olf) && ($TCat2 == $TCat2_qa)) {printf (PRINTFILE "%s\n", "TRUE");} else {printf(PRINTFILE "%s\n", "FALSE");}
	printf (PRINTFILE "%-40s %-35s %-35s %-35s", "Thermal Sensor String for die 1", "$TSensor1", "$TSensor1_olf", "$TSensor1_qa");
		if (($TSensor1 == $TSensor1_olf) && ($TSensor1 == $TSensor1_qa)) {printf (PRINTFILE "%s\n", "TRUE");} else {printf(PRINTFILE "%s\n", "FALSE");}
	printf (PRINTFILE "%-40s %-35s %-35s %-35s", "Thermal Sensor String for die 2", "$TSensor2", "$TSensor2_olf", "$TSensor2_qa");
		if (($TSensor2 == $TSensor2_olf) && ($TSensor2 == $TSensor2_qa)) {printf (PRINTFILE "%s\n", "TRUE");} else {printf(PRINTFILE "%s\n", "FALSE");}
	printf (PRINTFILE "%-40s %-35.4f %-35.4f %-35.4f", "AVID in Decimal", "$Dec_Avid", "$Dec_Avid_olf", "$Dec_Avid_qa");
		if (($Dec_Avid == $Dec_Avid_olf) && ($Dec_Avid == $Dec_Avid_qa)) {printf (PRINTFILE "%s\n", "TRUE");} else {printf(PRINTFILE "%s\n", "FALSE");}
	printf (PRINTFILE "%-40s %-35s %-35s %-35s", "AVID in Binary", "$Avid", "$Avid_olf", "$Avid_qa");
		if (($Avid == $Avid_olf) && ($Avid == $Avid_qa)) {printf (PRINTFILE "%s\n", "TRUE");} else {printf(PRINTFILE "%s\n", "FALSE");}
	printf (PRINTFILE "%-40s %-35.5f %-35.5f %-35.5f", "Avid Cdyn", "$Avid_Cdyn", "$Avid_Cdyn_olf", "$Avid_Cdyn_qa");
		if (($Avid_Cdyn == $Avid_Cdyn_olf) && ($Avid_Cdyn == $Avid_Cdyn_qa)) {printf (PRINTFILE "%s\n", "TRUE");} else {printf(PRINTFILE "%s\n", "FALSE");}
	printf (PRINTFILE "%-40s %-35.5f %-35.5f %-35.5f", "Avid CdynVnom", "$Avid_CdynVnom", "$Avid_CdynVnom_olf", "$Avid_CdynVnom_qa");
		if (($Avid_CdynVnom == $Avid_CdynVnom_olf) && ($Avid_CdynVnom == $Avid_CdynVnom_qa)) {printf (PRINTFILE "%s\n", "TRUE");} else {printf(PRINTFILE "%s\n", "FALSE");}
	printf (PRINTFILE "%-40s %-35.5f %-35.5f %-35.5f", "Avid Isb", "$Avid_Isb", "$Avid_Isb_olf", "$Avid_Isb_qa");
		if (($Avid_Isb == $Avid_Isb_olf) && ($Avid_Isb == $Avid_Isb_qa)) {printf (PRINTFILE "%s\n", "TRUE");} else {printf(PRINTFILE "%s\n", "FALSE");}
	printf (PRINTFILE "%-40s %-35.5f %-35.5f %-35.5f", "Avid Sicc", "$Avid_Sicc", "$Avid_Sicc_olf", "$Avid_Sicc_qa");
		if (($Avid_Sicc == $Avid_Sicc_olf) && ($Avid_Sicc == $Avid_Sicc_qa)) {printf (PRINTFILE "%s\n", "TRUE");} else {printf(PRINTFILE "%s\n", "FALSE");}
	printf (PRINTFILE "%-40s %-35.5f %-35.5f %-35.5f", "Avid TDC", "$Avid_Tdc", "$Avid_Tdc_olf", "$Avid_Tdc_qa");
		if (($Avid_Tdc == $Avid_Tdc_olf) && ($Avid_Tdc == $Avid_Tdc_qa)) {printf (PRINTFILE "%s\n", "TRUE");} else {printf(PRINTFILE "%s\n", "FALSE");}
	printf (PRINTFILE "%-40s %-35.5f %-35.5f %-35.5f", "Avid Vmax", "$Avid_Vmax", "$Avid_Vmax_olf", "$Avid_Vmax_qa");
		if (($Avid_Vmax == $Avid_Vmax_olf) && ($Avid_Vmax == $Avid_Vmax_qa)) {printf (PRINTFILE "%s\n", "TRUE");} else {printf(PRINTFILE "%s\n", "FALSE");}
	printf (PRINTFILE "%-40s %-35.5f %-35.5f %-35.5f", "Avid Vmin", "$Avid_Vmin", "$Avid_Vmin_olf", "$Avid_Vmin_qa");
		if (($Avid_Vmin == $Avid_Vmin_olf) && ($Avid_Vmin == $Avid_Vmin_qa)) {printf (PRINTFILE "%s\n", "TRUE");} else {printf(PRINTFILE "%s\n", "FALSE");}
	printf (PRINTFILE "%-40s %-35.5f %-35.5f %-35.5f", "Avid Vnom", "$Avid_Vnom", "$Avid_Vnom_olf", "$Avid_Vnom_qa");
		if (($Avid_Vnom ==$Avid_Vnom_olf) && ($Avid_Vnom ==$Avid_Vnom_qa)) {printf (PRINTFILE "%s\n", "TRUE");} else {printf(PRINTFILE "%s\n", "FALSE");}
	printf (PRINTFILE "%-40s %-35s %-35s %-35s", "ST in Binary", "$St", "$St_olf", "$St_qa");
		if (($St == $St_olf) && ($St == $St_qa)) {printf (PRINTFILE "%s\n\n\n", "TRUE");} else {printf(PRINTFILE "%s\n\n\n", "FALSE");}
	
	printf (PRINTFILE "Summary for Fuse Strings: \n");
	printf (PRINTFILE "======================================\n");
	printf (PRINTFILE "%-30s", "");
	printf (PRINTFILE "2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222211111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000\n");
	printf (PRINTFILE "%-30s", "");
	printf (PRINTFILE "9999999988888888887777777777666666666655555555554444444444333333333322222222221111111111000000000099999999998888888888777777777766666666665555555555444444444433333333332222222222111111111100000000009999999999888888888877777777776666666666555555555544444444443333333333222222222211111111110000000000\n");
	printf (PRINTFILE "%-30s", "");
	printf (PRINTFILE "7654321098765432109876543210987654321098765432109876543210987654321098765432109876543210987654321098765432109876543210987654321098765432109876543210987654321098765432109876543210987654321098765432109876543210987654321098765432109876543210987654321098765432109876543210987654321098765432109876543210\n");
	printf (PRINTFILE "%-30s", "");
	printf (PRINTFILE "__________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________\n");
	
	printf (PRINTFILE "%-30s", "Fuse File for BankA Die 1:");
	for($a = 297; $a >= 0; $a--){
	printf (PRINTFILE "$REV_FUSEFILE1_A[$a]");
	}
	
	printf (PRINTFILE "\n");
	printf (PRINTFILE "%-30s", "PPV Fuse for Bank A Core 0:");
	for($a = 297; $a >= 0; $a--){
	printf (PRINTFILE "$REV_FUSEA_C0[$a]");
	}
	
	printf (PRINTFILE "\n");
	printf (PRINTFILE "%-30s", "Mismatched:");
	for($a = 297; $a >= 0; $a--){
	printf (PRINTFILE "$MISMATCH1A[$a]");
	}
	
	printf (PRINTFILE "\n\n");
	printf (PRINTFILE "There are $MM1A mismatched in BankA Die 1 (Core 0)");
	
	printf (PRINTFILE "\n\n\n");
		
	printf (PRINTFILE "%-30s", "");
	printf (PRINTFILE "2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222211111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000\n");
	printf (PRINTFILE "%-30s", "");
	printf (PRINTFILE "9999999988888888887777777777666666666655555555554444444444333333333322222222221111111111000000000099999999998888888888777777777766666666665555555555444444444433333333332222222222111111111100000000009999999999888888888877777777776666666666555555555544444444443333333333222222222211111111110000000000\n");
	printf (PRINTFILE "%-30s", "");
	printf (PRINTFILE "7654321098765432109876543210987654321098765432109876543210987654321098765432109876543210987654321098765432109876543210987654321098765432109876543210987654321098765432109876543210987654321098765432109876543210987654321098765432109876543210987654321098765432109876543210987654321098765432109876543210\n");
	printf (PRINTFILE "%-30s", "");
	printf (PRINTFILE "__________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________\n");
	
	printf (PRINTFILE "%-30s", "Fuse File for BankA Die 2:");
	for($a = 297; $a >= 0; $a--){
	printf (PRINTFILE "$REV_FUSEFILE2_A[$a]");
	}
	
	printf (PRINTFILE "\n");
	printf (PRINTFILE "%-30s", "PPV Fuse for Bank A Core 1:");
	for($a = 297; $a >= 0; $a--){
	printf (PRINTFILE "$REV_FUSEA_C1[$a]");
	}
	
	printf (PRINTFILE "\n");
	printf (PRINTFILE "%-30s", "Mismatched:");
	for($a = 297; $a >= 0; $a--){
	printf (PRINTFILE "$MISMATCH2A[$a]");
	}
	
	printf (PRINTFILE "\n\n");
	printf (PRINTFILE "There are $MM2A mismatched in BankA Die 2 (Core 1)");
	
	printf (PRINTFILE "\n\n\n");

	printf (PRINTFILE "%-30s", "");
	printf (PRINTFILE "2222222222222222222222222222222222222222222222222222222222222222222222222222222222222211111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000\n");
	printf (PRINTFILE "%-30s", "");
	printf (PRINTFILE "8888887777777777666666666655555555554444444444333333333322222222221111111111000000000099999999998888888888777777777766666666665555555555444444444433333333332222222222111111111100000000009999999999888888888877777777776666666666555555555544444444443333333333222222222211111111110000000000\n");
	printf (PRINTFILE "%-30s", "");
	printf (PRINTFILE "5432109876543210987654321098765432109876543210987654321098765432109876543210987654321098765432109876543210987654321098765432109876543210987654321098765432109876543210987654321098765432109876543210987654321098765432109876543210987654321098765432109876543210987654321098765432109876543210\n");
	printf (PRINTFILE "%-30s", "");
	printf (PRINTFILE "______________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________\n");
	
	printf (PRINTFILE "%-30s", "Fuse File for BankB Die 1:");
	for($a = 285; $a >= 0; $a--){
	printf (PRINTFILE "$REV_FUSEFILE1_B[$a]");
	}
	
	printf (PRINTFILE "\n");
	printf (PRINTFILE "%-30s", "PPV Fuse for Bank B Core 0:");
	for($a = 285; $a >= 0; $a--){
	printf (PRINTFILE "$REV_FUSEB_C0[$a]");
	}
	
	printf (PRINTFILE "\n");
	printf (PRINTFILE "%-30s", "Mismatched:");
	for($a = 285; $a >= 0; $a--){
	printf (PRINTFILE "$MISMATCH1B[$a]");
	}
	
	printf (PRINTFILE "\n\n");
	printf (PRINTFILE "There are $MM1B mismatched in BankB Die 1 (Core 0)");
	
	printf (PRINTFILE "\n\n\n");
		
	printf (PRINTFILE "%-30s", "");
	printf (PRINTFILE "2222222222222222222222222222222222222222222222222222222222222222222222222222222222222211111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000\n");
	printf (PRINTFILE "%-30s", "");
	printf (PRINTFILE "8888887777777777666666666655555555554444444444333333333322222222221111111111000000000099999999998888888888777777777766666666665555555555444444444433333333332222222222111111111100000000009999999999888888888877777777776666666666555555555544444444443333333333222222222211111111110000000000\n");
	printf (PRINTFILE "%-30s", "");
	printf (PRINTFILE "5432109876543210987654321098765432109876543210987654321098765432109876543210987654321098765432109876543210987654321098765432109876543210987654321098765432109876543210987654321098765432109876543210987654321098765432109876543210987654321098765432109876543210987654321098765432109876543210\n");
	printf (PRINTFILE "%-30s", "");
	printf (PRINTFILE "______________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________\n");
	
	printf (PRINTFILE "%-30s", "Fuse File for BankB Die 2:");
	for($a = 285; $a >= 0; $a--){
	printf (PRINTFILE "$REV_FUSEFILE2_B[$a]");
	}
	
	printf (PRINTFILE "\n");
	printf (PRINTFILE "%-30s", "PPV Fuse for Bank B Core 1:");
	for($a = 285; $a >= 0; $a--){
	printf (PRINTFILE "$REV_FUSEB_C1[$a]");
	}	
	
	printf (PRINTFILE "\n");
	printf (PRINTFILE "%-30s", "Mismatched:");
	for($a = 285; $a >= 0; $a--){
	printf (PRINTFILE "$MISMATCH2B[$a]");
	}
	
	printf (PRINTFILE "\n\n");
	printf (PRINTFILE "There are $MM2B mismatched in BankB Die 2 (Core 1)");
	
	printf (PRINTFILE "\n\n\n");
	printf (PRINTFILE "**************************************************************************************\n");
	if(($MM1A == 0) && ($MM2A == 0) && ($MM1B == 0) && ($MM2B == 0)){
		printf (PRINTFILE "The $Unit PPV fuse log is validated without error.");
#		print "\nThe PPV fuse log is validated without error.\n";
	}
	
	else{
		$MM = $MM1A + $MM2A + $MM1B + $MM2B;
		printf (PRINTFILE "The PPV fuse log is defined with error. There are $MM Mismatch for unit $Unit");
#		printf ("\nThe PPV fuse log is defined with error. There are $MM Mismatch for unit $Unit\n");
	}
	
	printf (PRINTFILE "\n**************************************************************************************\n\n\n");
	}
	}
	
	close(READFILE, FILEFUSESSPEC, FILETRACELOG, FILECUSTOM, FILE1A)
