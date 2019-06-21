#!/usr/local/bin/perl5 -w 

#################################################################################
#										#
#	Property of NCO PDQRE Sort Automation/Datamation Penang Malaysia.	#
#	Do not delete or modify in any way without prior authorisation.		#
#										#
#	AUTHORS									#
#	Foo Lye Cheung                  inet 253 6452				#
#	Justin Devanandan Allegakoen    inet 253 7392				#
#										#
#	DESCRIPTION								#
#	Part of the code for OCR reader through prober for GILA Sort to SOD.	#
#										#
#	NOTES                                                                   #
#										#
#	REV 1.1		09/17/2003						#
#										#
#################################################################################

use lib "/oper/iuser5/p6_eng/jdallega/lib/perl/";

use strict;
use Net::Telnet;
use Net::FTP;

# Global variable declared over here
my $WvtOutFile = "";
my $WVTDir = '/user/home1/prodeng/lfoo1/PerlOcr/scribeupload/';

sub StartInitAndRead
{
	my $Lot = shift;
	my @ReadScribeID = qw(G70291-04B4 G70291-06A2 G70291-08G3 G70291-09F6 G70291-07H0 G70291-11F6 G70291-10G3  G70291-12F1);
	my $WVTFormat = "03123456 G70291-04B4 004";
	print "$Lot\n";
	&WriteToWvtFile($Lot, $WVTFormat);
	&DisplayScribeID(@ReadScribeID);
}

sub GetTelnetPWD
{
	chomp($_ = qx/grep "s3strm5" \/user\/home1\/prodeng\/lfoo1\/PerlOcr\/.pwd/);
	my @UTelnetIDPWD = split /=/;
	return($UTelnetIDPWD[0], $UTelnetIDPWD[1]);
}

# Start initialize the prober, gpib bus and read vendor scribe id 
sub StartInitAndRead1
{
	my $Lot = shift;
	my (@ibrd, @CMAP, @VendorScribeIDs, @WVT, $VendorScribeID, $WVTFormat, $WaferCnt);
	my $Tester = 't3fx31-t.png.intel.com';
 	my ($User, $Pwd) = &GetTelnetPWD;
	my $Prompt = 'coolie';

	my $Ibic = new Net::Telnet(Timeout => 300, prompt => '/[%#>:)] *$/');
	$Ibic->open($Tester);
	$Ibic->login($User, $Pwd);

	# Clear the bus on the gpib board
	$Ibic->cmd("ibic");
	$Ibic->cmd("ibfind gpib0");
	$Ibic->cmd("ibsic");
	$Ibic->cmd("quit");

	# Open communication from station controller with prober
	print "Prober checking and initializing...\n";
	$Ibic->cmd("ibic");
	$Ibic->cmd("ibfind dev1");
	$Ibic->cmd("ibclr");
	$Ibic->cmd("ibtmo 16");
	$Ibic->cmd("ibwrt \"EIC,COM\\r\\n\"");
	$Ibic->cmd("ibwait 0x4800");
	$Ibic->cmd("ibrsp");
	$Ibic->cmd("ibrd 180");

	# Display what prober name and version
	#$Ibic->cmd("ibwrt \"EDQ,PIDSR\\r\\n\"");
	#$Ibic->cmd("ibwait 0x4800");
	#$Ibic->cmd("ibrsp");
	#$Ibic->cmd("ibrd 180");
	#$Ibic->cmd("ibwrt \"EDQ,PRBNM\\r\\n\"");
	#$Ibic->cmd("ibwait 0x4800");
	#$Ibic->cmd("ibrsp");
	#$Ibic->cmd("ibrd 180");

	# Prober online from station controller
	$Ibic->cmd("ibwrt \"ECC,IHOST\\r\\n\"");
	$Ibic->cmd("ibwait 0x4800");
	$Ibic->cmd("ibrsp");
	$Ibic->cmd("ibrd 180");

	# MDQ,CMAP,1 - check how many wafers at cassette 1
	$Ibic->print("ibwrt \"MDQ,CMAP,1\\r\\n\"");
	$Ibic->waitfor('/dev1: $/i');
	$Ibic->print('ibwait 0x4800');
	$Ibic->waitfor('/dev1: $/i');
	$Ibic->print('ibrsp');
	$Ibic->waitfor('/dev1: $/i');
	$Ibic->print('ibrd 180');
	@CMAP = $Ibic->waitfor('/dev1: $/i');
	$WaferCnt = &CountWafer($CMAP[0]);
	print "Wafers loaded to prober: $WaferCnt\n";

	# Start batch lot test
	$Ibic->cmd("ibwrt \"MCC,BLP\\r\\n\"");
	$Ibic->cmd("ibwait 0x4800");
	$Ibic->cmd("ibrsp");
	$Ibic->cmd("ibrd 180");

	for my $WaferNum (1..$WaferCnt) 
	{
		# Start testing wafer 
		$Ibic->cmd("ibwrt \"MCC,PCWPM\\r\\n\"");
		$Ibic->cmd("ibwait 0x4800");
		$Ibic->cmd("ibrsp");
		$Ibic->cmd("ibrd 180");

		# Pause wafer
		$Ibic->cmd("ibwrt \"MCC,PAS\\r\\n\"");
		$Ibic->cmd("ibwait 0x4800");
		$Ibic->cmd("ibrsp");
		$Ibic->cmd("ibrd 180");

		# Ensure the vendor scribe id able to be read from the prober
		ReadGPIB:

		# Read vendor scribe id
		$Ibic->cmd("ibwrt \"MDQ,WID\\r\\n\"");
		$Ibic->cmd("ibwait 0x4800");
		$Ibic->cmd("ibrsp");
		@ibrd = $Ibic->cmd("ibrd 180");
		($VendorScribeID, $WVTFormat) = &ReadScribeID($Lot, @ibrd);
		if ($WVTFormat eq "")
		{
			goto ReadGPIB;
		}
		push (@VendorScribeIDs, $VendorScribeID);

		# Write .dat file every time it read WVT
		&WriteToWvtFile($Lot, $WVTFormat);
		print "Lot #: $Lot with vendor scribe: $VendorScribeID\n";

		# Abort and unload the wafer
		$Ibic->cmd("ibwrt \"MCC,ABRTW\\r\\n\"");
		$Ibic->cmd("ibwait 0x4800");
		$Ibic->cmd("ibrsp");
		$Ibic->cmd("ibrd 180");
	}

	# Prober offline
	$Ibic->cmd("ibwrt \"ECC,ABHOST\\r\\n\"");
	$Ibic->cmd("ibwait 0x4800");
	$Ibic->cmd("ibrsp");
	$Ibic->cmd("ibrd 180");
	print "Prober finish reading. Disconnect communication...\n";

	# Quit from ibic
	$Ibic->cmd("quit");

	$Ibic->close;

	&FTPToSOD($WvtOutFile);
	&DisplayScribeID(@VendorScribeIDs);
}

# Convert Ibic CMAP to check how many wafers are loaded into the prober
sub CountWafer
{
	my $IbicCMAP = shift;
	my $count = 0;

	# $IbicCMAP = contain CMAP info
	if ($IbicCMAP =~ /,\s+(\d\s+.*\d)\s+\w{2}.*\w{2}\s+(\d\s+.*\d)\s+\w{2}.*\w{2}\s+(\d\s+.*\d)\s+\w{2}.*\w{2}\s+(\d\s+.*\d)/)
	{
		#print "1: $1, 2: $2, 3: $3, 4: $4\n";
		$_ = $1.$2.$3.$4;
		$count += tr/1//;
	}
	return $count;
}

# Translate the vendor scribe ID from Ibic to readable format
sub ReadScribeID
{
	my ($Lot, @Ibicibrd) = @_;
	my ($tmp, $WVTFormat, $VendorScribeID);

	foreach my $Line (@Ibicibrd)
	{
		if ($Line =~ /\s+(([A-Z0-9]|,|\.)\s+.*)/)
		{
			$_ = $1;
			s/ //g;
			$tmp .=$_;
			if ($tmp =~ /^MDR,WID,\d,\d{3},(.*-(\d{2}).*)\.\.$/)
			{
				# Format wvt_out, <Lot> <scribeID> <0><character 8,9> for GILA Sort
				# eg. 0335A00A G70288-03F0 003
				$VendorScribeID = $1;
				$WVTFormat = $Lot." ".$1." 0".$2;
				$tmp = "";
			}
		}
	}

	return ($VendorScribeID, $WVTFormat);
}

# Write all vendor scribe id to <lot>_<epoah time>.dat
sub WriteToWvtFile
{
	my ($Lot, $WVTFormat) = @_;
	my $Count = 0;
	
	if ($Count == 0)
	{
		my $FileName = &GetWvtFileNameFormat($Lot);
		$WvtOutFile = $WVTDir.$FileName;
		$Count++;
	}

	open (WVT, ">>$WvtOutFile") or die "Cann't open $WvtOutFile: $!\n";
	print WVT "$WvtLine\n";
	close WVT;
}

# Format the filename to <lot>_<epoah time>.dat
sub GetWvtFileNameFormat
{
	my $Lot = shift;
	my ($second, $minute, $hour, $date, $month, $year) = localtime(time);
	$year += 1900;
	$month =~ s/^(\d)$/0$1/;
	$date =~ s/^(\d)$/0$1/; 
	$hour =~ s/^(\d)$/0$1/;
	$minute =~ s/^(\d)$/0$1/;
	$second =~ s/^(\d)$/0$1/;
	my $NewFileName = "$Lot"."_"."$month$date$year$hour$minute$second".".dat";
}

sub GetFTPPWD
{
	chomp($_ = qx/grep "ftpuser" \/user\/home1\/prodeng\/lfoo1\/PerlOcr\/.pwd/);
	my @UFTPIDPWD = split /=/;
	return($UFTPIDPWD[0], $UFTPIDPWD[1]);
}

# Ftp the data file to SOD
sub FTPToSOD
{
	my $File = shift;
	my $Server = '172.30.32.31'; # Databroker cluster node
	my ($ID, $PWD) = &GetFTPPWD;
	my $FTPLog = ">>/user/home1/prodeng/lfoo1/PerlOcr/log/FTPOCRToSOD.log";

	my $FTP = Net::FTP->new($Server) or die "Can't connect to $Server\n";
	$FTP->login($ID,$PWD) or die "Sorry can't connect as user $ID\n";
	open(LOG, $FTPLog) or die "$FTPLog:- $!\n";
	my $Now = localtime(time);
	chomp $File;

	if($FTP->put($File))
	{
		print LOG "Loaded $File at $Now\n";
	}
	else
	{
		print LOG "Couldnt put $File at $Now\n";
	}
	$FTP->quit;
	undef $FTP;
	close LOG;

	print "Ftp $File to SOD\n";
}

# Convert vendor scribe id from array to text
sub DisplayScribeID
{
	my @VendorScribeIDs = @_;
	my $txtScribeID;

	for (0..$#VendorScribeIDs)
	{
		(my $Num = $_ + 1) =~ s/^(\d)$/ $1/;
		$txtScribeID .= $Num.". ".$VendorScribeIDs[$_]."\n";
	}

	print "Finishing processing...\n";

	&DoneReadScribeID($txtScribeID);
}

1
