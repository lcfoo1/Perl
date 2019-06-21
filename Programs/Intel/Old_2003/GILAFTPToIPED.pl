#########################################################################################
#											#
#	Foo Lye Cheung		PE Sort Automation					#
#	08/22/2003									#
#											#
#	Program to insert a lot's fablot attribute from Mars db to ituff file,		#
# 	Copy the ituff files from /db1/s9k/sort/s9kaccess/sort/datalogs/ to		#
#	directory /tmp/FTPToIPED/ with filename format <lot>_8012_<wafer>       	#
#	Ituff at /tmp/FTPToIPED/ are ammended with Fab lot id before is send		#
#       to IPED server (fmskla001/klarity_ace/ORG_RAWDATA/CP_ituff/IMPORT) 		#
#											#
#	Modified 09/19/2003								#
#	Insert some checking for end of ituff summary. This is required as S9k append	#
#	the summary on real time. Only a complete summary is ftpped to IPED.		#
#	Inserted a deltemp.pl to delete the temperorary files at /tmp/FTPToIPED after 	#
#	the temperorary files have been ftpped to IPED.					#
#											#
#	NOTES										#
#	Requires Perl5 and Net::FTP, Win32::OLE and Net::Telnet to run.			#
#	Requires gilafilefind.pl, gilaupdatefile.pl, gilaftp.pl from 			#
#	/user/home1/prodeng/lfoo1/datamation.						#
#	GILAFTPToIPED.pl requires an Oracle ODBC and runs from PDQRE4 as scheduler at 	#
#	3.03am in the morning daily.							#
#											#
#	Send mail to notify PE if Fabrun not found from Mars                    	#
#											#
#########################################################################################

use warnings;
use strict;
use Win32::OLE;
use Net::FTP;
use Net::Telnet;
use Win32::ODBC;

sub OpenMARS
{
	my $dbMARS;
	my $PWD = ']KH%C:5'^'0$&V,U[';

	unless($dbMARS = new Win32::ODBC("dsn=MARS; UID=monsoon; PWD=$PWD"))
	{
		print "Error: " . Win32::ODBC::Error() . "\n";
		exit;
	}

	return $dbMARS;
}

sub FormatNow
{
	# Formats the current time into a date we recognise at Intel
	my ($ss, $mi, $hh, $dd, $mm, $yyyy) = localtime(time);
	
	$yyyy += 1900;
	$mm++;
	$mm =~ s/^(\d)$/0$1/;
	$dd =~ s/^(\d)$/0$1/;
	$hh =~ s/^(\d)$/0$1/;
	$mi =~ s/^(\d)$/0$1/;
	$ss =~ s/^(\d)$/0$1/;

	return("$mm/$dd/$yyyy $hh:$mi:$ss");
}


# Open MARS once
my $dbMARS = &OpenMARS;

# Get Lot number from file to obtain fablot attribute from Mars db
sub GetLots
{
	my $PrevLot = "Null";
	my $RemoteDir = "/tmp_mnt/user/home1/prodeng/lfoo1/datamation";
	my $Prompt = "lfoo1";
	my @NewFiles;
        
	# Get connection to t3admin6
	my $telnet = new Net::Telnet (Timeout => 60, Prompt=> '/[%#>:)] $/');
	$telnet->open('t3admin6.png.intel.com');
	$telnet->login('lfoo1', ',L&OKTOu'^'@*I zf|A');
	print "Connected to t3admin6\n"; 

	# Clear out the prompt that prints itself 
	$telnet->cmd("xterm");
	$telnet->prompt("/[%#>:)] $/");
	$telnet->prompt("/$Prompt\$/");
	$telnet->cmd("set prompt = '$Prompt'");

	# Run the program to get the files
	$telnet->cmd("cd $RemoteDir") || die "Cannot cd to $RemoteDir\n";
	my @Files = $telnet->cmd("perl gilafilefind.pl"); 
	$Files[0] =~ s/^\s+//;
       	
	foreach my $File(@Files)
	{
		chomp $File;
		print "File=$File\n";
		my $Lot =$File;

		# Example $File = /tmp/FTPToIPED/0308A18A_8012_WLcfoo
		$Lot =~ s/^\/tmp\/FTPToIPED\/(\w{8})_+.*/$1/;

		print "Lot=$Lot\n";
		my $Fabrun = &GetFabrun($Lot);

		# Substitute to taking care special character
		$Fabrun =~ s/(\W)/\\$1/g; 
		print "Fabrun=$Fabrun\n";
		
		#if Fabrun = null then send mail notify PE else update remote file with fabrun
		if (($Fabrun eq "NULL") && ($Lot ne ""))
		{
			print "PreviousLot =$PrevLot\n";

			if($Lot ne $PrevLot)
			{
				my $To = 'lye.cheung.foo@intel.com';
		       		my $Subject = "Fabrun not found for $Lot"; 
	              		my $Body = 
				"Fabrun not found for $Lot, Please rerun the Lot manually once the Fabrun found from Mars


 	                  	 * * * PLEASE DO NOT REPLY TO THIS MAIL * * *";
				 
				&SendMail($To, '', $Subject, $Body);
				print "Mail sent for error reporting\n";
	                	
	                        #Capture the lot which no fabrun found from mars to rerun lot daily for fabrun 
				my $Rerun = ">>c:/Temp/LotRerun.txt";
				open(Lotrerun, "$Rerun") || die "$Rerun:- $!\n";		
				print Lotrerun "$File\n";
			}
		}
		else
		{
			# Update the remote file with the fabrun
			my @Update = $telnet->cmd("perl gilaupdatefile.pl $File $Fabrun");
			$Update[0] =~ s/\s+//;
			print "UPDATE = $Update[0]\n";
			if ($Update[1] =~ /(\S+)\s1$/)
			{
				push (@NewFiles, $1); 
			}
		}
		$PrevLot = $Lot;
	}
	close(Lotrerun);

	# FTP amended ituff files one by one to IPED server
	foreach my $File(@NewFiles)
	{	
		chomp $File;
		# FTP the files to IPED
		print "FTPFile=$File\n";
		$telnet->cmd("perl gilaftp.pl $File");
	}

	$telnet->cmd("perl deltemp.pl");

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
