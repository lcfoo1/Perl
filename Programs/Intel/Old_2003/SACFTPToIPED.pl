#########################################################################################
#											#
#	Justin Devanandan Allegakoen		PCO PDQRE Datamation Group		#
#	08/10/2002				Penang					#
#											#
#	Program to insert a lot's fablot attribute from Mars db to ituff file, 		#
#	FTP amended ituff files from /lopte/intel/hp94k/sort/aries/data/ituff        	#
#       to IPED server (fmskla001/klarity_ace/ORG_RAWDATA/CP_Intel/IMPORT) 		#
#											#
#	Modified 8/10/2002 by Sook Leng							#
#	To FTP amended ituff file one by one after updatefile.pl instead of batch to    #
#       avoid timeout of FTP process.                 				 	#
#								                        #
#	Modified 02/17/2003 by Lye Cheung						#
#	Send mail to notify PE if there is any duplication for x and y coordinate on the#
#	ITUFF summary. Require a chkerror.pl to create a log file at 			#
#	/lopte/home1/slow/Datamation/ERROR.log if duplication exist			#
#											#
#	Modified 02/18/2003 Lye Cheung							#
#	Send mail to notify PE if Fabrun not found from Mars				#
#	Require a chkerror.pl to create a log file at 					#
#	/lopte/home1/slow/Datamation/ERROR.log if no Fabrun				#
#											#
#	Modified 03/05/2003 by Lye Cheung						#
#	Send mail to notify PE if Fabrun wrongly inserted; and wrong x-y min and max	#
#	Require a chkerror.pl to create a log file at 					#
#	/lopte/home1/slow/Datamation/ERROR.log if no Fabrun				#
#	Require Lookup_Table								#
#											#
#	Modified 05/28/2003 by Lye Cheung						#
#	Send mail to notify PE if test program name loaded mismatch			#
#	Require a chkerror.pl to create a log file at 					#
#	/lopte/home1/slow/Datamation/ERROR.log if no Fabrun				#
#	Require Lookup_Table								#
#											#
#	NOTES										#
#	Requires Perl5 and Net::FTP, Win32::OLE and Net::Telnet to run.			#
#	Requires filefind.pl, updatefile.pl, ftp.pl from /lopte/home/slow/Datamation.	#
#	SACFTPToIPED.pl requires an Oracle ODBC and there is Oracle ODBC install on    	#
#       t3hp94k5, so SACFTPToIPED.pl is run from PDQRE4 as scheduler at 3am in the	#
#       morning daily.								        #
#       This program was written for Sook Leng	      					#
#											#
#########################################################################################

use warnings;
use strict;
use Win32::OLE;
use Net::FTP;
use Net::Telnet;

require "C:/Perl/Programs/Common.pl";

my @tFiles;
my @Update;
my $Fabrun;
my @Updatefiles;
my $Chkstatus=0;

# Open MARS once
my $dbMARS = &OpenMARS;

# Get Lot number from file to obtain fablot attribute from Mars db
sub GetLots
{
	my $PrevLot = "Null";
	my $RemoteDir = "/lopte/home1/slow/Datamation";
	my $Prompt = "slow";
	my $Pwd = '8@X$IBr'^'K,7SxpA';
        
	# Get connection to t3hp94k5
	my $telnet = new Net::Telnet (Timeout => 7200, Prompt=> '/[%#>:)] $/');
	$telnet->open('t3hp94k5.png.intel.com');
	$telnet->login('slow', $Pwd);
	print "Connected to t3hp94k5\n"; 

	# Clear out the prompt that prints itself 
	$telnet->cmd("xterm");
	$telnet->prompt("/[%#>:)] $/");
	$telnet->prompt("/$Prompt\$/");
	$telnet->cmd("set prompt = '$Prompt'");

	# Run the program to get the files
	$telnet->cmd("cd $RemoteDir") || die "Cannot cd to $RemoteDir\n";
	my @Files = $telnet->cmd("perl filefind.pl"); 
	$Files[0] =~ s/^\s+//;
       	
	foreach my $File(@Files)
	{
		chomp $File;
		print "File=$File\n";
		my $Lot =$File;
		$Lot =~ s/^.*ituff\/(\w{8})_+.*/$1/;

		print "Lot=$Lot\n";
		$Fabrun = &GetFabrun($Lot);

		# Substitute to taking care special character
		print "Fabrun=$Fabrun\n";
		chomp ($Fabrun);

		#if Fabrun = null then send mail notify PE else update remote file with fabrun
		if (($Fabrun eq "NULL") && ($Lot ne ""))
		{
			print "PreviousLot =$PrevLot\n";

			if($Lot ne $PrevLot)
			{	
				my $To = 'lye.cheung.foo@intel.com; kai.hiong.lee@intel.com; bee.lean.neoh@intel.com ';
				#my $To = 'lye.cheung.foo@intel.com';  
				my $Subject = "Fabrun not found for $Lot"; 
	               		my $Body = 
				"Fabrun not found for $Lot, Please rerun the Lot manually once the Fabrun found from Mars


 	                  	 * * * PLEASE DO NOT REPLY TO THIS MAIL * * *";
				 
				&SendMail($To, '', $Subject, $Body);
				print "Mail sent for error reporting\n";
	                					
				#Create a no Fabrun log file at /lopte/home1/slow/Datamation/ERROR.log
				$telnet->cmd("perl chkerror.pl $File $Lot $Chkstatus");

	                        # Capture the lot which no fabrun found from mars to rerun lot daily for fabrun 
				my $Rerun = ">>c:/Temp/LotRerun.txt";
				open(Lotrerun, "$Rerun") || die "$Rerun:- $!\n";		
				print Lotrerun "$File\n";
			}
		}
		else
		{
			# Update the remote file with the fabrun
			@Update = $telnet->cmd("perl updatefile.pl $File $Fabrun");
			$Update[0] =~ s/\s+//;
			push (@Updatefiles,"$Update[1]") if ($Update[1] !~ /UploadScript$/);
			print "UPDATE = @Update\n";
		}
		$PrevLot = $Lot;
	}
	close(Lotrerun);

	# FTP amended ituff files one by one to IPED server
	foreach my $File(@Updatefiles)
	{	
		chomp $File;
		my @chkdup = split(/ /,$File);
		my $Lot = $chkdup[0];
		print "my lot $Lot\n";
		$Lot =~ s/^.*ituff\/(\w{8})_+.*/$1/;
		$Fabrun = &GetFabrun($Lot);

		no warnings;	
		
		# Checking duplication occurence	
		if ($chkdup[6] eq "DUP")
		{
			$Chkstatus = 1;
			my $To = 'soo.ling.chuah@intel.com; lye.cheung.foo@intel.com; kai.hiong.lee@intel.com; tiing.tsong.soo@intel.com; daniel.chan.seong.chang@intel.com; tong.ho.tee@intel.com; chun.hou.loo@intel.com; yuen.wah.lim@intel.com; kiang.hock.lim@intel.com; mun.sum.wong@intel.com; ';
			#my $To = 'lye.cheung.foo@intel.com';   
	
			# On the subject line it will print the real file name
		       	my $Subject = "Duplicate occured on $chkdup[0]"; 
	               	my $Body = 
			"Duplication occured on the ITUFF summary - $chkdup[0] with Fabrun=$Fabrun 
Device: $chkdup[12], WWID: $chkdup[8], Start Date: $chkdup[9], End Date: $chkdup[11], Time: $chkdup[10]

At coordinate:	$chkdup[7] 

 	                  	 * * * PLEASE DO NOT REPLY TO THIS MAIL * * *";
				 
			&SendMail($To, '', $Subject, $Body);

			# Create a duplicate log file at /lopte/home1/slow/Datamation/ERROR.log
			$telnet->cmd("perl chkerror.pl $chkdup[0] $Fabrun $Chkstatus");
			
			# Display on the screen the duplication information
			print "Duplicate at $chkdup[0] with Fabrun=$Fabrun\n";
			print "Mail sent for error reporting\n";
			$Chkstatus = 0;
		}

		# Checking for mismatch x-min, x-max, y-min, y-max		
		if (($chkdup[2] eq "NOT_MATCH") && ($chkdup[6] eq "NODUP"))
		{
			$Chkstatus = 2;
			my $To = 'soo.ling.chuah@intel.com; lye.cheung.foo@intel.com; tiing.tsong.soo@intel.com; tong.ho.tee@intel.com; chun.hou.loo@intel.com; yuen.wah.lim@intel.com; kiang.hock.lim@intel.com; mun.sum.wong@intel.com; ';
			#my $To = 'lye.cheung.foo@intel.com';   
                    
			# On the subject line it will print the real file name
		       	my $Subject = "Coordinate x-min, x-max, y-min and y-max NOT MATCH occured on $chkdup[0]"; 
	               	my $Body = 
			"Coordinate x-min, x-max, y-min and y-max NOT MATCH on the ITUFF summary - $chkdup[0] with Fabrun=$Fabrun
Minimum and maximum x-y coordinate from Lookup Table: 
$chkdup[4]

Minimum and maximum x-y coordinate from $chkdup[0]: 
$chkdup[5]

               	 * * * PLEASE DO NOT REPLY TO THIS MAIL * * *";
				 
			&SendMail($To, '', $Subject, $Body);

			# Create a duplicate log file at /lopte/home1/slow/Datamation/ERROR.log
			$telnet->cmd("perl chkerror.pl $chkdup[0] $Fabrun $Chkstatus");
			
			# Display on the screen the duplication information
			print "Coordinate x-min, x-max, y-min and y-max NOT MATCH at $chkdup[0] with Fabrun=$Fabrun\n";
			print "Mail sent for error reporting\n";
			$Chkstatus = 0;
		}

		# Checking for wrongly inserted Fabrun		
		if ($chkdup[3] eq "WRONG_FABRUN")		
		{
			$Chkstatus = 3;
			my $To = 'soo.ling.chuah@intel.com; lye.cheung.foo@intel.com; kai.hiong.lee@intel.com; tong.ho.tee@intel.com; chun.hou.loo@intel.com; yuen.wah.lim@intel.com; kiang.hock.lim@intel.com; mun.sum.wong@intel.com; ';               
			#my $To = 'lye.cheung.foo@intel.com';

			# On the subject line it will print the real file name
		       	my $Subject = "Wrong Fabrun Inserted occured on $chkdup[0]"; 
	               	my $Body = 
			"Wrong Fabrun Inserted occured on the ITUFF summary - $chkdup[0] with Fabrun=$Fabrun

 	                  	 * * * PLEASE DO NOT REPLY TO THIS MAIL * * *";
				 
			&SendMail($To, '', $Subject, $Body);

			# Create a duplicate log file at /lopte/home1/slow/Datamation/ERROR.log
			$telnet->cmd("perl chkerror.pl $chkdup[0] $Fabrun $Chkstatus");
			
			# Display on the screen the duplication information
			print "Wrong Fabrun Inserted at $chkdup[0] with Fabrun=$Fabrun\n";
			print "Mail sent for error reporting\n";
			$Chkstatus = 0;
		}		

		# Checking for test program name is standardized	
		if ($chkdup[1] eq "ProgNotMatch")
		{
			$Chkstatus = 4;
			my $To = 'soo.ling.chuah@intel.com; lye.cheung.foo@intel.com; tiing.tsong.soo@intel.com; tong.ho.tee@intel.com; chun.hou.loo@intel.com; yuen.wah.lim@intel.com;  kiang.hock.lim@intel.com; mun.sum.wong@intel.com; ';
			#my $To = 'lye.cheung.foo@intel.com';   
	
			# On the subject line it will print the real file name
		       	my $Subject = "Test Program Loaded Not Match on $chkdup[0]"; 
	               	my $Body = 
			"Test Program Loaded Not Match - $chkdup[0] with Fabrun=$Fabrun

 	                  	 * * * PLEASE DO NOT REPLY TO THIS MAIL * * *";
				 
			&SendMail($To, '', $Subject, $Body);

			# Create a duplicate log file at /lopte/home1/slow/Datamation/ERROR.log
			$telnet->cmd("perl chkerror.pl $chkdup[0] $Fabrun $Chkstatus");
			
			# Display on the screen the duplication information
			print "Test Program Loaded Not Match on $chkdup[0] with Fabrun=$Fabrun\n";
			print "Mail sent for error reporting\n";
			$Chkstatus = 0;
		}

		# Check for good ITUFF summary and ftp to IPED if it is a good ITUFF summary
		if (($chkdup[1] eq "ProgMatch") && ($chkdup[2] eq "MATCH") && ($chkdup[3] eq "FABRUN") && ($chkdup[6] eq "NODUP"))
		{
			# FTP the files to IPED
			print "FTPFile=$chkdup[0]\n";
			$telnet->cmd("perl ftp.pl $chkdup[0]");
		}

	}

	$telnet->close();
	undef $telnet;
}

# Get lot's Fabrun attribute from mars db
sub GetFabrun
{
	# Fire off a query to MARS for each lot even if there are duplicates
	my %Temp;
	my $Lot = shift;
	my $sql = "SELECT DiSTINCT ATTRIBUTE_VALUE FROM S03_PROD_3.F_LOTATTRIBUTE WHERE LOT = '$Lot' " .
		"AND ATTRIBUTE_NUMBER = 711";
	print "$sql\n";

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
	}

	no warnings;
	# if Fabrun attribute not found then set attribute value to NULL 
	# else return the fabrun attribute to call sub
	$Temp{ATTRIBUTE_VALUE} =~ s/^$/NULL/;
	return $Temp{ATTRIBUTE_VALUE};
}

&GetLots;

$dbMARS->Close();
