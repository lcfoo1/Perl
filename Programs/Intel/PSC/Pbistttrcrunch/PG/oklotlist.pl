#################################################################
# 								#
# 	Foo Lye Cheung				01 August 2005	#
# 	PDE DPG CPU Penang Malaysia				#
# 								#
# 	Connect to ARIES DB and do sql query for crunching	#
# 	test pattern						#
# 								#
#################################################################
use strict;
use warnings;
use Win32::ODBC;
use Cwd;

my ($User, $PWD) = ('lfoo1', 'Tukugawa04!!!!');
my $Dir = getcwd;
my $DirCfg = $Dir . '/configuration'; 
chdir $DirCfg || die "Cant change $DirCfg : $!\n";	
my ($DNS, $ProgName, $Part, $Locn, $Test, $WW, $Fab, $File) = ('ARIESPRD_A01', "", "", "", "", "", "", "");
my $dbARIES = "";

foreach my $CfgFile (<*.txt>)
{
	my $Cfg	= $DirCfg . '/' . $CfgFile;	
	print "File: $Cfg\n";
	open (CFG, $Cfg) || die "Cant open $Cfg : $!\n";
	while (<CFG>)
	{
		chomp;
		s/\s+//g;
		if (/DNS=(\S+)/)
		{
			$DNS = $1;
		}
		elsif (/PROGNAME=(\S+)/)
		{
			my $LProgName = $1;
			my $i = 0;
			$ProgName = "(";
			my @ProgNames = split(/\,/, $LProgName);
			for ($i = 0; $i <= $#ProgNames; $i++)
			{
				if ($i != 0) 
				{
					$ProgName .= " OR ";
				}
				$ProgName .= "BOTR.PROGRAM_NAME LIKE '$ProgNames[$i]%'";
			}
			$ProgName .= ")"
		}
		elsif (/PART=(\S+)/)
		{
			my $LPart = $1;
			my $i = 0;
			$Part = "(";
			my @Parts = split(/\,/, $LPart);
			for ($i = 0; $i <= $#Parts; $i++)
			{
				if ($i != 0) 
				{
					$Part .= " OR ";
				}
				$Part .= "BOTR.DEVREVSTEP LIKE '$Parts[$i]%'";
			}
			$Part .= ")";
		}
		elsif (/LOCN=(\S+)/)
		{
			my $LLocn = $1;
			my $i = 0;
			$Locn = "(";
			my @Locns = split(/\,/, $LLocn);
			for ($i = 0; $i <= $#Locns; $i++)
			{
				if ($i != 0) 
				{
					$Locn .= " OR ";
				}
				$Locn .= "BOTR.OPERATION = '$Locns[$i]'";
			}
			$Locn .= ")";
		}
		elsif (/TestName=(\S+)/)
		{
			my $LTest = $1;
			my $i = 0;
			$Test = "(";
			my @Tests = split(/\,/, $LTest);
			for ($i = 0; $i <= $#Tests; $i++)
			{
				if ($i != 0) 
				{
					$Test .= " OR ";
				}
				$Test .= "T.TEST_NAME LIKE '$Tests[$i]'";
			}
			$Test .= ")";
		}
		elsif (/WW=(\S+)/)
		{
			$WW = $1;
		}
		elsif (/FAB=(\S+)/)
		{
			$Fab = $1;
		}
		elsif (/FileName=(\S+)/)
		{
			$File = $Dir . '/' . $1 . ".csv";
		}
	}
	close CFG;


	print "Start connecting to ARIES DB - $DNS (${CfgFile}) ...\n";	
	$dbARIES = &OpenARIES;
	if ($CfgFile =~ /cfg.txt/i)
	{
		#$File = $Dir . '/' . "Totallot" . ".csv";
		&GetLotList();
	}
	else
	{
		&GetTestTime();
	}
}

$dbARIES->Close();
print "Finish processing...\n";

# Subroutine to open connection to ARIES DB
sub OpenARIES
{
	unless($dbARIES = new Win32::ODBC("dsn=$DNS; UID=$User; PWD=$PWD"))
	{
		print "Error: " . Win32::ODBC::Error() . "\n";
		exit;
	}

	return $dbARIES;
}

# Subroutine to lot list pattern from ARIES DB
sub GetLotList
{
	my %Temp;
	#my $Sql = "SELECT DISTINCT BOTR.LOT LOT, BOTR.OPERATION OPER, BOTR.DEVREVSTEP DEVREVSTEP, BOTR.PROGRAM_NAME TP, " .
	my $Sql = "SELECT DISTINCT BOTR.LOT LOT, BOTR.OPERATION OPER, BOTR.DEVREVSTEP DEVREVSTEP, " .
		  "substr ((ALO.TOTAL_GOOD + ALO.TOTAL_BAD),1,6) TTEST " .
		  #"substr ((ALO.TOTAL_GOOD + ALO.TOTAL_BAD),1,6) TTEST, " .
		  #"substr (ALO.TOTAL_GOOD,1,6) TGOOD, " .
		  #"substr (sum(decode(interface_bin, 1, 1, null)),1,5) B1, " .
		  #"substr (sum(decode(interface_bin, 2, 1, null)),1,5) B2, " .
		  #"substr (sum(decode(interface_bin, 3, 1, null)),1,5) B3, " .
		  #"substr (sum(decode(interface_bin, 4, 1, null)),1,5) B4, " .
		  #"substr (sum(decode(interface_bin, 5, 1, null)),1,5) B5, " .
		  #"substr (sum(decode(interface_bin, 6, 1, null)),1,5) B6 " .
		  "FROM A_BUNCH_OF_TEST_RESULTS BOTR, " .
		  "A_DEVICE_TESTING DT, A_TEST T, A_FUNCTIONAL_PATTERN_FAILURE PF, A_PATTERN_NAME PN, " .
		  "A_LOT_AT_OPERATION ALO " .
		  "WHERE BOTR.LOT LIKE '${Fab}%' " .
		  "AND $Locn " .
		  "AND $ProgName " .
		  "AND $Part " .
		  'AND a_pg$intel_ww.calculate_ww(BOTR.rollup_end_date_time) >= a_pg$intel_ww.calculate_ww(sysdate) - ' . $WW . " " .
		  "AND PF.CONTINUATION_SEQUENCE = 0 " .
		  "AND BOTR.VALID_FLAG = 'Y' ".
		  "AND (DT.lao_start_ww=BOTR.lao_start_ww and DT.btr_sequence_in_ww=BOTR.btr_sequence_in_ww) " .
	 	  "AND (DT.lao_start_ww=PF.lao_start_ww and DT.btr_sequence_in_ww=PF.btr_sequence_in_ww and DT.ts_id=PF.ts_id and DT.dt_id=PF.dt_id) " .
		  "AND (BOTR.lao_start_ww=PF.lao_start_ww and BOTR.btr_sequence_in_ww=PF.btr_sequence_in_ww ) " .
		  "AND (BOTR.PROGRAM_NAME = T.PROGRAM_NAME) " .
		  "AND (PF.PATTERN_NAME_ID = PN.PATTERN_NAME_ID) " .
		  "AND (PF.T_ID = T.T_ID) " . 
		  "AND ALO.LOT = BOTR.LOT AND ALO.OPERATION = BOTR.OPERATION " .
		  "GROUP BY BOTR.LOT, BOTR.OPERATION, BOTR.DEVREVSTEP, ALO.TOTAL_GOOD, ALO.TOTAL_BAD " .
		  #"GROUP BY BOTR.LOT, BOTR.OPERATION, BOTR.DEVREVSTEP, BOTR.PROGRAM_NAME, ALO.TOTAL_GOOD, ALO.TOTAL_BAD " .
		  "ORDER BY BOTR.OPERATION";
	  
		  #print "$Sql\n";
	no warnings;
	if($dbARIES->Sql($Sql))
	{
		$dbARIES->Close();
		print "Sql statement error\n";
		exit;
	}
	else
	{
		open (CSV, ">$File") || die "Cant open $File : $!\n";
		#print CSV "LOT,OPER,DEVREVSTEP,TP,TTEST,TGOOD,B1,B2,B3,B4,B5,B6\n";
		print CSV "LOT,OPER,DEVREVSTEP,TTEST\n";
		while($dbARIES->FetchRow())
		{
			%Temp = $dbARIES->DataHash();
			print "$Temp{'LOT'}\n";
			#print CSV "$Temp{'LOT'},$Temp{'OPER'},$Temp{'DEVREVSTEP'},$Temp{'TP'},$Temp{'TTEST'},$Temp{'TGOOD'},$Temp{'B1'},$Temp{'B2'},$Temp{'B3'},$Temp{'B4'},$Temp{'B5'},$Temp{'B6'}\n";
			print CSV "$Temp{'LOT'},$Temp{'OPER'},$Temp{'DEVREVSTEP'},$Temp{'TTEST'}\n";
		}
		close CSV;
	}
}

# Subroutine to get pattern from ARIES DB
sub GetTestTime
{
	my %Temp;
	my $Sql = "SELECT PN.PATTERN_NAME PATTERN, COUNT(PN.PATTERN_NAME) COUNT FROM A_BUNCH_OF_TEST_RESULTS BOTR, " .
		  "A_DEVICE_TESTING DT, A_TEST T, A_FUNCTIONAL_PATTERN_FAILURE PF, A_PATTERN_NAME PN " .
		  "WHERE BOTR.LOT LIKE '${Fab}%' " .
		  "AND $Locn " .
		  "AND $ProgName " .
		  "AND $Part " .
	          "AND $Test " .
		  'AND a_pg$intel_ww.calculate_ww(BOTR.rollup_end_date_time) >= a_pg$intel_ww.calculate_ww(sysdate) - ' . $WW . " " .
		  "AND PF.CONTINUATION_SEQUENCE = 0 " .
		  "AND BOTR.VALID_FLAG = 'Y' ".
		  "AND (DT.lao_start_ww=BOTR.lao_start_ww and DT.btr_sequence_in_ww=BOTR.btr_sequence_in_ww) " .
	 	  "AND (DT.lao_start_ww=PF.lao_start_ww and DT.btr_sequence_in_ww=PF.btr_sequence_in_ww and DT.ts_id=PF.ts_id and DT.dt_id=PF.dt_id) " .
		  "AND (BOTR.lao_start_ww=PF.lao_start_ww and BOTR.btr_sequence_in_ww=PF.btr_sequence_in_ww ) " .
		  "AND (BOTR.PROGRAM_NAME = T.PROGRAM_NAME) " .
		  "AND (PF.PATTERN_NAME_ID = PN.PATTERN_NAME_ID) " .
		  "AND (PF.T_ID = T.T_ID) " .
  		  "GROUP BY PN.PATTERN_NAME";
	  
		  #print "$Sql\n";
	no warnings;
	if($dbARIES->Sql($Sql))
	{
		$dbARIES->Close();
		print "Sql statement error\n";
		exit;
	}
	else
	{
		open (CSV, ">$File") || die "Cant open $File : $!\n";
		print CSV "PATTERN,COUNT\n";
		while($dbARIES->FetchRow())
		{
			%Temp = $dbARIES->DataHash();
			print "$Temp{'PATTERN'},$Temp{'COUNT'}\n";
			print CSV "$Temp{'PATTERN'},$Temp{'COUNT'}\n";
		}
		close CSV;
	}
}
