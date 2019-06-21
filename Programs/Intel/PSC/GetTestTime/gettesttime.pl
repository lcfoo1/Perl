#################################################################
# 								#
# 	Foo Lye Cheung				13 July 2005	#
# 	PDE DPG CPU Penang Malaysia				#
# 								#
# 	Connect to ARIES DB and do sql query for crunching	#
# 	test time						#
# 								#
#################################################################
use strict;
use warnings;
use Win32::ODBC;

#my ($User, $PWD) = @ARGV;
my ($User, $PWD) = ('lfoo1', 'Tukugawa04!!!!');
unless (@ARGV == 2)
{
	#print "\nUSAGE: testtime.pl <idsid> <password>\n";
	#exit -1;
}

my $Cfg = "Configuration.txt";
my ($DNS, $ProgName, $Part, $Locn, $Day, $Fab) = ();
open (CFG, $Cfg) || die "Cant open $Cfg : $!\n";
while (<CFG>)
{
	chomp;
	s/\s+//g;
	if (/^DNS=(\S+)/)
	{
		$DNS = $1;
	}	
	elsif (/^PROGNAME=(\S+)/)
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
			$ProgName .= "TS.PROGRAM_NAME LIKE '$ProgNames[$i]%'";
		}
		$ProgName .= ")";
	}
	elsif (/^PART=(\S+)/)
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
			$Part .= "TS.DEVREVSTEP LIKE '$Parts[$i]%'";
		}
		$Part .= ")";
	}
	elsif (/^LOCN=(\S+)/)
	{
		$Locn = $1;
	}
	elsif (/^DAY=(\S+)/)
	{
		$Day = $1;
	}
	elsif (/^FAB=(\S+)/)
	{
		$Fab = $1;
	}
}
close CFG;

print "Start connecting to ARIES DB...\n";	
my $dbARIES = &OpenARIES;
&GetTestTime();
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

# Subroutine to get test time from ARIES DB
sub GetTestTime
{
	my %Temp;
	my $Sql = "SELECT TS.OPERATION AS OPERATION, TS.PROGRAM_NAME AS PROGRAM, " .
      		  "DT.INTERFACE_BIN AS IB, COUNT(DT.TEST_TIME) AS QUANTITY, SUM(DT.TEST_TIME) AS TT_SUM, " .
		  "AVG(DT.TEST_TIME) AS TT_AVG, TS.DEVREVSTEP AS PART FROM A_TESTING_SESSION TS, A_DEVICE_TESTING DT " .
		  "WHERE TS.TEST_END_DATE_TIME >= sysdate - $Day AND TS.LOT LIKE '${Fab}%' AND TS.OPERATION LIKE '$Locn' " .
		  "AND $ProgName AND TS.VALID_FLAG='Y' AND (TS.LATEST_FLAG='Y' AND DT.LATEST_FLAG='Y') " .
		  "AND (TS.LAO_START_WW=DT.LAO_START_WW AND TS.TS_ID=DT.TS_ID) AND $Part " .
		  "GROUP BY TS.OPERATION, TS.PROGRAM_NAME, TS.LOT, DT.GOODBAD_FLAG, TS.DEVREVSTEP, DT.INTERFACE_BIN ".    
		  "ORDER BY OPERATION, PROGRAM, IB, PART";

		  print "$Sql\n";


	if($dbARIES->Sql($Sql))
	{
		$dbARIES->Close();
		print "sql wrong\n";
		exit;
	}
	else
	{
		my $OUT = $DNS . ".csv";
		my $HFlag = 0;
		open (OUT, ">$OUT") || die "Cant open $OUT : $!\n";
		while($dbARIES->FetchRow())
		{
			%Temp = $dbARIES->DataHash();
			my $Header =join(',',keys %Temp);
			print OUT "$Header\n" if ($HFlag == 0);
			if ($Temp{'IB'} >=1 && $Temp{'IB'} <= 6)
			{
				foreach my $Line (keys %Temp)
				{
					print OUT "$Temp{$Line},";
					print "$Line = $Temp{$Line}\n";
				}
				print OUT "\n";
			}
			$HFlag++;
		}
		close OUT;
	}
}
