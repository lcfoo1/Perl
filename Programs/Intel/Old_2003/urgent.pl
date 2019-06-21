use Win32::ODBC;
use Win32::OLE;
use Net::FTP;
use File::Copy;
#use Term::ReadKey;

#ReadMode('noecho');
#$password = ReadLine(0);

my $Time = localtime;
$uid = "discovery";
$pwd = "discovery";
#$uid = &promptUser("USERID");
#$pwd = &promptUser("PASSWD");
$database = "dsn=Aries; UID=".$uid."; PWD=".$pwd;
my $dbARIES = &OpenARIES;

$lot = '';
$fablot = '';
$date = '20040614';
$operation = '6102';
$start_ww = '200425';

$table = "urgent.out";

# Search lots between WW
##### TOTAL LOTS TESTED IN WW
# Store for later use	
open (INFILE1, "<c:\\urgent.in") || die("Couldn't open file : $operation : $!\n");
@data=();
while(<INFILE1>){
	chomp($_);
	@data=split(/\t/,$_);	
	push(@t_lot, $data[0]);
}
close (INFILE1);

open (OUTFILE1,">c:\\$table") || die("Couldn't open file : $table : $!\n");
print OUTFILE1 "LOT LIST\tB9\tB9\%\tB28\tB28\%\tRETEST\tTESTER\tHANDLER";
print OUTFILE1 "\n";
close OUTFILE1;
$t_i=0;
for $each (@t_lot){
	@sum = ();
	@sum2 = ();
	@t_in = ();
	@operation = ();

	$t_b9pct = 0;
	$t_b9 = 0;
	$t_b28pct = 0;
	$t_b28 = 0;
	$retest = 0;
	$t_retest = 0;
	$t_in = 0;
	$handler = "";
	$tester = "";
	$retest_rate = 0;

	$lot = $each;
	open (OUTFILE1,">>c:\\$table") || die("Couldn't open file : $table : $!\n");	
	&GetFabrun();
	$t_i++;
}
print OUTFILE1 ",,,,END OF REPORT,,,,\n";
close OUTFILE1;
$dbARIES->Close();

# Subroutine to open connection to ARIES database
sub OpenARIES
{
	my $dbARIES;

	unless($dbARIES = new Win32::ODBC($database))
	{
		print "Error: " . Win32::ODBC::Error() . "\n";
		exit;
	}
	return $dbARIES;
}

sub ifSQL
{
	my ($db, $sql) = @_;
	print "Error, SQL failed: " . $db->Error() . "\n";
	print "$sql\n";
	$db->Close();
	exit;
}


# Subroutine to get lot's Fabrun attribute from ARIES database
sub GetFabrun
{
	# Fire off a query to ARIES for each lot even if there are duplicates
	my %Temp;
	my $date1 = "select TEST_START_DATE_TIME from (select ts.*, bc_type_or_name, bin_counter_id, loaded_rollup_value from a_testing_session_rollup tsr, (select ts.* from a_testing_session ts where ts.latest_flag = 'Y' and ts.valid_flag = 'Y' and ts.lot = '$lot' and summary_number is not null and facility ='A01') ts where tsr.lao_start_ww = ts.lao_start_ww and tsr.ts_id = ts.ts_id and bc_type_or_name in ('IB')) s, a_test_program_bin tpb, a_generic_bin gb where tpb.program_name(+) = s.program_name and tpb.bin_number(+) = decode(substr(bc_type_or_name,2,1), 'B',s.bin_counter_id) and tpb.bin_letter(+) = substr(bc_type_or_name,1,1) and gb.bin_number(+) = decode(substr(bc_type_or_name,2,1),'B',s.bin_counter_id) and gb.bin_letter(+) = substr(bc_type_or_name,1,1) and gb.bin_number(+) = decode(substr(bc_type_or_name,2,1),'B',s.bin_counter_id) and s.bin_counter_id = '1'";
	
	$file = $lot;
############# 6488 ###############
	my $sum11 = "select summary_number from (select ts.*, bc_type_or_name, bin_counter_id, loaded_rollup_value from a_testing_session_rollup tsr, (select ts.* from a_testing_session ts where ts.latest_flag = 'Y' and ts.valid_flag = 'Y' and summary_number is not null and facility ='A01') ts where tsr.lao_start_ww = ts.lao_start_ww and tsr.ts_id = ts.ts_id and bc_type_or_name in ('IB')) s, a_test_program_bin tpb, a_generic_bin gb where tpb.program_name(+) = s.program_name and tpb.bin_number(+) = decode(substr(bc_type_or_name,2,1), 'B',s.bin_counter_id) and tpb.bin_letter(+) = substr(bc_type_or_name,1,1) and gb.bin_number(+) = decode(substr(bc_type_or_name,2,1),'B',s.bin_counter_id) and gb.bin_letter(+) = substr(bc_type_or_name,1,1) and gb.bin_number(+) = decode(substr(bc_type_or_name,2,1),'B',s.bin_counter_id) and s.bin_counter_id = '1' and lot = '$file' and operation = '6488'";
	if($dbARIES->Sql($sum11))
	{
		&ifSQL($dbARIES, $sql);
	}
	else ##### SUMMARY
	{
		while($dbARIES->FetchRow())
		{
			# Store for later use
			if (exists($sum{'$dbARIES->Data'})){}
			else
			{
				push(@sum, $dbARIES->Data);
			}				
		}		
	}

	for ($i=1; $i<=$sum[$#sum]; $i++){
		my $t_in1 = "select LOADED_TOTAL_TESTED loadedtotal from (select ts.*, bc_type_or_name, bin_counter_id, loaded_rollup_value from a_testing_session_rollup tsr, (select ts.* from a_testing_session ts where ts.latest_flag = 'Y' and ts.valid_flag = 'Y' and ts.lot = '$lot' and summary_number is not null and facility ='A01') ts where tsr.lao_start_ww = ts.lao_start_ww and tsr.ts_id = ts.ts_id and bc_type_or_name in ('IB')) s, a_test_program_bin tpb, a_generic_bin gb where tpb.program_name(+) = s.program_name and tpb.bin_number(+) = decode(substr(bc_type_or_name,2,1), 'B',s.bin_counter_id) and tpb.bin_letter(+) = substr(bc_type_or_name,1,1) and gb.bin_number(+) = decode(substr(bc_type_or_name,2,1),'B',s.bin_counter_id) and gb.bin_letter(+) = substr(bc_type_or_name,1,1) and gb.bin_number(+) = decode(substr(bc_type_or_name,2,1),'B',s.bin_counter_id) and s.bin_counter_id = '1' and summary_number = '$i' and operation = '6488'";
		if($dbARIES->Sql($t_in1))
		{
			&ifSQL($dbARIES, $sql);
		}
		else ##### EVERY LOAD IN
		{
			while($dbARIES->FetchRow())
			{
				# Store for later use				
				$t_in[$i] = $t_in[$i] + $dbARIES->Data;
			}			
		}
	}

	for ($i=2; $i<=$sum[$#sum]; $i++){
		##### RETEST RATE
		# Store for later use			
		$retest = $retest + $t_in[$i];
	}

	#print OUTFILE1 "$lot,$t_b9,$t_b9pct\%,$t_b28,$t_b28pct\%,$retest\%,$tester,$handler,6488,\n";
	#print OUTFILE1 "0,    1,       2,       3 ,	4,		5,	  6	,7,	      8,     9,    10,   11\n";	
	print OUTFILE1 "$lot,$t_b9,$t_b9pct\%,$t_b28,$t_b28pct\%,$retest,$tester,$handler,6488,,,\n";
##################################
	@sum2 = ();
	my $sum22 = "select summary_number from (select ts.*, bc_type_or_name, bin_counter_id, loaded_rollup_value from a_testing_session_rollup tsr, (select ts.* from a_testing_session ts where ts.latest_flag = 'Y' and ts.valid_flag = 'Y' and summary_number is not null and facility ='A01') ts where tsr.lao_start_ww = ts.lao_start_ww and tsr.ts_id = ts.ts_id and bc_type_or_name in ('IB')) s, a_test_program_bin tpb, a_generic_bin gb where tpb.program_name(+) = s.program_name and tpb.bin_number(+) = decode(substr(bc_type_or_name,2,1), 'B',s.bin_counter_id) and tpb.bin_letter(+) = substr(bc_type_or_name,1,1) and gb.bin_number(+) = decode(substr(bc_type_or_name,2,1),'B',s.bin_counter_id) and gb.bin_letter(+) = substr(bc_type_or_name,1,1) and gb.bin_number(+) = decode(substr(bc_type_or_name,2,1),'B',s.bin_counter_id) and s.bin_counter_id = '1' and lot = '$file' and (operation = '6102' or operation = '6152')";
	if($dbARIES->Sql($sum22))
	{
		&ifSQL($dbARIES, $sql);
	}
	else ##### SUMMARY
	{
		while($dbARIES->FetchRow())
		{
			# Store for later use
			if (exists($sum2{'$dbARIES->Data'})){}
			else
			{
				push(@sum2, $dbARIES->Data);
			}				
		}		
	}

	my $operation2 = "select operation from (select ts.*, bc_type_or_name, bin_counter_id, loaded_rollup_value from a_testing_session_rollup tsr, (select ts.* from a_testing_session ts where ts.latest_flag = 'Y' and ts.valid_flag = 'Y' and summary_number is not null and facility ='A01') ts where tsr.lao_start_ww = ts.lao_start_ww and tsr.ts_id = ts.ts_id and bc_type_or_name in ('IB')) s, a_test_program_bin tpb, a_generic_bin gb where tpb.program_name(+) = s.program_name and tpb.bin_number(+) = decode(substr(bc_type_or_name,2,1), 'B',s.bin_counter_id) and tpb.bin_letter(+) = substr(bc_type_or_name,1,1) and gb.bin_number(+) = decode(substr(bc_type_or_name,2,1),'B',s.bin_counter_id) and gb.bin_letter(+) = substr(bc_type_or_name,1,1) and gb.bin_number(+) = decode(substr(bc_type_or_name,2,1),'B',s.bin_counter_id) and s.bin_counter_id = '1' and lot = '$file' and (operation = '6102' or operation = '6152') and summary_number = '$sum2[$#sum2]'";
	if($dbARIES->Sql($operation2))
	{
		&ifSQL($dbARIES, $sql);
	}
	else ##### OPERATION
	{
		while($dbARIES->FetchRow())
		{
			# Store for later use			
			# push(@operation, $dbARIES->Data);
			$operation = $dbARIES->Data;
		}	
	}	
#############################	
### A_rev4.pl	
######################
### B_rev4.pl
#	elsif ($#sum2 < 0){
		@sum2 = ();
		@str4 = ();
		@str3 = ();
		$letter = "z";
		$rev="";
		$home = '/adis/t3db/summary/';
		$dir = substr($file, 0, 4);
		$dir = "/".$dir;
		$hostname = 'mvsn1.png.intel.com';
		$username = 'trillprod';
		$password = 'unix123';
		$home = $home.$dir;
		# Open the connection to the host
		$ftp = Net::FTP->new($hostname);        # Construct object
		$ftp->login($username, $password);      # Log in	
		$ftp->cwd($home),"\n";                  # Change directory		
		for ($sum2_letter = 97;$sum2_letter<=ord($letter);$sum2_letter++){
			$tOperation = $operation;
			$operation = "reb1";
			$file1 = $file."_".$operation."_*.smy*";
			$file1 = lc($file1);
			#$ftp->get($file1);
			@str4 = $ftp->get($file1);
			@str3 = $ftp->ls($file1);			
			if ($#str3 < 0){
				$operation = $tOperation;
				$file1 = $file."_".$operation."_*.smy*";
				$file1 = lc($file1);
			}
			@str4 = $ftp->get($file1);
			@str3 = $ftp->ls($file1);			
			@str5 = ();#download all files but choose only wanted
			foreach $keys (@str3){
				$keys = lc($keys); # FILTERED counter/std summary
				if ($keys =~ /std/ || $keys =~ /counter/ || $keys =~ /6622/){
				#	print $keys;
				}
				else{
					push (@str5, $keys);
				}
			}
			#print "STR: @str3\nSTR2: @str5\n";
			$total = substr($str5[$#str5], 14, 1);
			#print "TOTAL: $total\n";
			if ($str4[0] eq ""){ #the one with .0/.1/.2
				$sum2_letter = ord($letter) + 1;
			}			
		}		
		for ($key2 = 0;$key2 <$total;$key2++){
			push (@sum2, ($key2 +1));
		}
		
		for ($str = 0; $str<=$#str5; $str++){
			$file1 = $str5[$str];			
			open (OUTFILE2, ">$file1") || die("Couldn't open file : $file1 : $!\n");
			print OUTFILE2 "#### THIS IS A BLANK FILE! ####";
			close OUTFILE2;
			$s = substr($file1, 14, 1);
			$s = ord($s) - 48;
			$sum2_letter = substr($file1, 15, 1);
			$sum2_letter = ord($sum2_letter);
			if ($str2[0] eq ""){				
			}
			else {
				$file1 = $str2[$#str2]."";
			}			
			if (not(-e ".\\backup\\$file1")){				
				$ftp->get($file1);
				move($file1, ".\\backup\\$file1") or die "move failed: $!";
			}			
			
			if ((-e ".\\$file1")){				
				unlink($file1) or die "Can't delete $FILENAME: $!\n";
			}			
			
			manipulateData(".\\backup\\$file1");
			#########
			#### manipulate data
			#########			
		}
		$ftp->quit;
		calNprint ();		
#	}	
######################
}

sub calNprint {
	if ($t_in == 0){}# DEVICE BY ZERO #
	else{	
		$retest_rate = ($t_retest/$t_in)*100;			

		$t_b9pct = sprintf "%.2f", $t_b9/$t_in*100;
		$t_b28pct = sprintf "%.2f", $t_b28/$t_in*100;
	}	

	if ($s == $sum2[$#sum2]){
		#print OUTFILE1 "0,    1,       2,       3 ,	4,		5,	  6	,7,	      8,     9,    10,   11\n";
		print OUTFILE1 "$lot,$t_b9,$t_b9pct\%,$t_b28,$t_b28pct\%,$retest_rate\%,$tester,$handler,$operation,$rev,$t_in,$t_fail\n";
	}
}

sub manipulateData {	
	open (INFILE1, "<$_[0]") || die("Couldn't open file : $_[0] : $!\n");
	@data=();
	$start = 0;
	while(<INFILE1>){
		chomp($_);				
		if ($s > 1){
			if ($_ =~ /LOT QTY/){
				@data1=split(/ +/,$_);						
				$t_retest = $t_retest + $data1[4];
			}
		}
		elsif ($s == 1 && $sum2_letter == 97) {
			if ($_ =~ /LOT QTY/){
				@data1=split(/ +/,$_);						
				$t_in = $data1[4];						
			}				
		}

		if ($_ =~ /PROGRAM NAME/){
			@data1=split(/ +/,$_);
			if ($rev eq ""){
				$rev = uc(substr($data1[4], 8, 2));
			}			
		}

		
		if ($s == $sum2[$#sum2]){
			if ($_ =~ /HARDWARE/){
				$start++;
			}
			if ($_ =~ /ENGINEERING/){
				$start = 0;
			}
			if ($_ =~ /SYSTEM NUMBER/){
				@data1=split(/ +/,$_);						
				$data1[4] = uc($data1[4]);
				@data1=split(/-/,$data1[4]);						
				$tester = $data1[1];				
			}
			if ($_ =~ /HANDLER NUMBER/){	
				@data1=split(/ +/,$_);
				$handler = $data1[3];
			}
			if ($_ =~ /LOCATION CODE/){
				@data1=split(/ +/,$_);
				$operation = $data1[8];
			}
			if ($_ =~ /TOTAL UNITS FAILED/){
				@data1=split(/ +/,$_);
				$t_fail = $data1[5];				
			}
			if ($_ =~ /PROGRAM NAME/){
				if ($rev eq ""){
					@data1=split(/ +/,$_);
					$rev = uc($data1[4]);
				}
				else {
					$tempRev = uc(substr($data1[4], 8, 2));
					if (not($rev eq $tempRev)){
						$rev = $tempRev;
					}
				}
			}

			if ($start>0){
				@data=split(/ +/,$_);
				#print @data;
				#print "".$_."\n";
			}
			if ($data[2] eq "9"){
				$t_b9 = $t_b9 + $data[3];
			}
			elsif ($data[2] eq "28"){
				$t_b28 = $t_b28 + $data[3];
			}					
		}
		@data=();
		@data1=();
	}
	close (INFILE1);
}

sub promptUser {

   #-------------------------------------------------------------------#
   #  two possible input arguments - $promptString, and $defaultValue  #
   #  make the input arguments local variables.                        #
   #-------------------------------------------------------------------#

   local($promptString,$defaultValue) = @_;

   #-------------------------------------------------------------------#
   #  if there is a default value, use the first print statement; if   #
   #  no default is provided, print the second string.                 #
   #-------------------------------------------------------------------#

   if ($defaultValue) {
      print $promptString, "[", $defaultValue, "]: ";
   } else {
      print $promptString, ": ";
   }

   $| = 1;               # force a flush after our print
   $_ = <STDIN>;         # get the input from STDIN (presumably the keyboard)


   #------------------------------------------------------------------#
   # remove the newline character from the end of the input the user  #
   # gave us.                                                         #
   #------------------------------------------------------------------#

   chomp;

   #-----------------------------------------------------------------#
   #  if we had a $default value, and the user gave us input, then   #
   #  return the input; if we had a default, and they gave us no     #
   #  no input, return the $defaultValue.                            #
   #                                                                 # 
   #  if we did not have a default value, then just return whatever  #
   #  the user gave us.  if they just hit the <enter> key,           #
   #  the calling routine will have to deal with that.               #
   #-----------------------------------------------------------------#

   if ("$defaultValue") {
      return $_ ? $_ : $defaultValue;    # return $_ if it has a value
   } else {
      return $_;
   }
}