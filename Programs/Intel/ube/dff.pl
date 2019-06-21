
my $File = "1A";
my $Temperature = "";
my ($Visual, $CurSSID, $ULT, $LD1, $LD2, $CurDlgPkg, $PKG) = ();
my %SSID = ();

open (DATALOG, $File) || die "Can't open datalog $File : $!\n";
while (<DATALOG>)
{
	chomp;		
	my $SoftBin = "";
	my $Flag = 0;

	$Temperature = $1 if (/4_tempr_(\S+)/);

	if (/_visualid_(\S+)/)
	{
		$Visual = $1;
	}
	elsif (/_tssid_(\S+)/)
	{
		$CurSSID = $1;
		if (/_strgalt_nsv_(\S+)/)
		{
			$ULT = $1;
			$SSID{$CurSSID} = $ULT;
		}
	}
	elsif (/_comnt_DFF_Data_LD1_(\S+)/)
	{
		$LD1 = "LD1,PBIC_S1,$1,";
	}
	elsif (/_comnt_DFF_Data_LD2_(\S+)/)
	{
		$LD2 = "LD2,PBIC_S1,$1,";
	}
	elsif (/_comnt_DFF_Data_PKG_(\S+)/)
	{
		$CurDlgPkg = $1;
	}
	elsif (/_curfbin_(\S+)/)
	{
		$SoftBin = $1;
		$PKG = "PKG,PBIC_S1,BIN=$SoftBin,HTEMP=$Temperature,$CurDlgPkg,";
		$Flag = 1;
	}

	if ($Flag)
	{
		if ($SoftBin =~ /[1-6]\d\d/)
		{
			print "${SSID{'LD1'}}:";
			#print "$PKG\n";
			#print "$LD1\n";
			#print "${SSID{"LD2"}}:\n";
			#print "$LD2\n";

		}
		else 
		{
			print "# Not ok\n";
		}
	}	
	%SSID = ();

		

#UNIT,35642369B0456
#F6519970_056_+04_+08:
#PKG,PBIC_S1,BIN=300,HTEMP=82.7,TIME=20070217130850,SSPEC=NN4AAH_2400_266_AVID,DEVICE=4AAHEV,FLWD=1,ST_BINARY=00001,TCon_Binary=001000,#AVID=1.2375,AVID_BINARY=100001,AVID_Cdyn=19.05472,AVID_Sicc=26.98095,AVID_Vmax=1.15410,AVID_Vmin=1.11339,AVID_Vnom=1.13650,AVID_Isb=24.84059,AVID_CdynVnom=18.93678,AVID_TDC=68.80084,
#LD1,PBIC_S1,SBF_DATA=0_0,SBF_CNT=0,Thermal_Sensor_Cat_String=100100101100,Thermal_Sensor_String=0110000010101001101000101101,
#F6519970_289_-12_+00:
#LD2,PBIC_S1,SBF_DATA=0_0,SBF_CNT=0,Thermal_Sensor_Cat_String=100011100101,Thermal_Sensor_String=0101001010001101010110101101,
#PBIC_S1,20070217142950,PBIC_S2,-,FC_S1,-,FC_S2,-,OPTYPE,PBIC_S1,SBF_OPTYPE,PBIC_S1

#2_comnt_DFF_Data_LD1_Thermal_Sensor_Cat_String=100011100100,Thermal_Sensor_String=0110001010101101101000101000
#2_lsep
#2_comnt_DFF_Data_LD2_Thermal_Sensor_Cat_String=100011100011,Thermal_Sensor_String=0101110010101001100100100111
#2_lsep
#2_comnt_DFF_Data_PKG_AVID=1.35000,AVID_BINARY=101010,AVID_Cdyn=22.65903,AVID_CdynVnom=23.21582,AVID_Isb=18.71201,AVID_Sicc=15.21540,AVID_TDC=82.04664,AVID_Vmax=1.25004,AVID_Vmin=1.20451,AVID_Vnom=1.23244,DEVICE=4KGHFV,FLWD=1,SSPEC=BZ4KGH_2667_266_AVID,ST_BINARY=00001,TIME=20060712213116

}
close DATALOG;
