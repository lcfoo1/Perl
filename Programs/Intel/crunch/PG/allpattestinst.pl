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

my ($User, $PWD) = ('', '');
my $Dir = getcwd;

my $SetupFile = $Dir . '/../maincfg/setup.txt';
open (ACC, $SetupFile) || die "Can't open $SetupFile : $!\n";
while (<ACC>)
{
	chomp;
	s/\s+//g;
	if (/^User=(\S+)/)
	{
		$User = $1;
	}
	elsif (/^Passwd=(\S+)/)
	{
		$PWD = $1;
		last;
	}

}
close ACC;

my $DirCfg = $Dir . '/configuration'; 
chdir $DirCfg || die "Cant change $DirCfg : $!\n";	
my ($DNS, $ProgName, $Part, $Locn, $Test, $WW, $Fab, $File) = ('ARIESPRD_A01', "", "", "", "", "", "", "");
my $dbARIES = "";

foreach my $CfgFile (<*.txt>)
{
	my $Cfg	= $DirCfg . '/' .$CfgFile;	
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


	print "Start connecting to ARIES DB - $DNS ...\n";	
	$dbARIES = &OpenARIES;
	&GetPattern();
	$dbARIES->Close();
	print "Finish processing...\n";
}

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

# Subroutine to get pattern from ARIES DB
sub GetPattern
{
	my %Temp;
	my $Sql = "SELECT DISTINCT PN.PATTERN_NAME PATTERN, COUNT(PN.PATTERN_NAME) COUNT, T.TEST_NAME TNAME FROM A_BUNCH_OF_TEST_RESULTS BOTR, " .
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
		  "GROUP BY PN.PATTERN_NAME, T.TEST_NAME";
	  
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
		print CSV "PATTERN,COUNT,TESTNAME\n";
		while($dbARIES->FetchRow())
		{
			%Temp = $dbARIES->DataHash();
			print "$Temp{'PATTERN'},$Temp{'COUNT'},$Temp{'TNAME'}\n";
			print CSV "$Temp{'PATTERN'},$Temp{'COUNT'},$Temp{'TNAME'}\n";
		}
		close CSV;
	}
}
