#########################################################################################
#											#
#	Foo Lye Cheung					NCO PDQRE Automation		#
#	17 June 2004									#
#	04-2536452									#
#											#
#	This script is to automated the AC Sort process					#
#	1. Upload the .dat file to /lopte/production/Inkless/ScribeUpload/ to upload	#
#	   to upload vendor scribe id to SOD and Maverick via data broker		#
#	2. Ftp the ituff summary at C:\test_data_sort\ituff\<Lot_locn>_temp to NETAPP	#
#	   server (/db1/s9k/sort/s9kaccess/sort/datalogs) and create Aries signal file 	#
#	   at /db1/s9k/sort/aries/signal/ituff						#
#	3. Rename the C:\test_data_sort\ituff\<Lot_Locn>_temp to 			#
#	   C:\test_data_sort\ituff\<Lot_Locn>						#
#	   										#
#	   Rev 0.0									#
#											#
#########################################################################################

use strict;
use warnings;
use Net::FTP;

# Declare the global variable
my $TempFile = "C:\\test_data_sort\\ACSortGIGATemp.tmp";
my $ItuffDir = "C:\\test_data_sort\\ituff\\";
&MainProgram();

# Main subroutine
sub MainProgram
{
	my @NewItuffDir = glob("$ItuffDir*_temp");
	my @NewItuff = glob("$ItuffDir*_temp\\*");
	&FTPACSortToS9K(@NewItuff);
	&RenameTmpLotDir(@NewItuffDir);
}

# Rename from <lot_locn>_temp to <lot_locn> at AC Sort ituff directory
sub RenameTmpLotDir
{
	my @NewItuffDir = @_;

	foreach my $TmpDir (@NewItuffDir)
	{
		my $RenItuffDir = $1 if ($TmpDir =~ /^(\S+_A)_(temp|TEMP)$/);
		my $OldTempDir = $RenItuffDir."_TEMP";
		rename($OldTempDir, $RenItuffDir);
		print "Rename from $OldTempDir to $RenItuffDir\n";
	}
}

# Format date and time
sub DateTime
{
	my ($SS, $MI, $HH, $DD, $MM, $YYYY) = localtime(time);
	$YYYY += 1900;
	$MM++;
	$MM =~ s/^(\d)$/0$1/;
	$HH =~ s/^(\d)$/0$1/;
	$MI =~ s/^(\d)$/0$1/;
	$SS =~ s/^(\d)$/0$1/;
	my $Now = $MM.$DD.$YYYY.$HH.$MI.$SS;
	return ($Now);
}

# Create temperorary Aries signal file
sub CreateAriesTmpFile
{
	open (TEMP, ">>$TempFile") || die "Cannt open $TempFile : $!\n";
	close TEMP;
}

# Ftp .dat file, ituff summary and Aries signal file to S9K environment
sub FTPACSortToS9K
{
	my @NewItuff = @_;
	my $RemoteDir =  '/db1/s9k/sort/s9kaccess/sort/datalogs';
	my $AriesSigDir = '/db1/s9k/sort/aries/signal/ituff';
	my $WvtOutDir = '/lopte/production/Inkless/ScribeUpload';
	my $LocalWvtOutDir = 'C:\AC Sort\wvt_out';
	my $DatLogFile = 'C:\AC Sort\WVT_OUT.log';
	my $FTPITUFFToNETAPPLog = "C:\\test_data_sort\\FTPITuffToNETAPP.log";
	my $Server = 't3admin6.png.intel.com';	
	my ($ID, $PWD) = ("s3strm5", "s3strm5");
	my $FTP = Net::FTP->new($Server);
	&CreateAriesTmpFile();

	$FTP->login($ID, $PWD);

	chdir $LocalWvtOutDir || die "Cannt open $LocalWvtOutDir : $!\n";
	open (DATLOG, ">>$DatLogFile") || die "Cannt open $DatLogFile : $!\n";

	foreach my $DatFile (<*>)
	{
		next unless ($DatFile =~ /dat$/);
		my $DatThere = $WvtOutDir."/".$DatFile;
		my $Now = &DateTime();
		my $NewDatFile = $Now.".dat.old";
		if($FTP->put($DatFile, $DatThere))
		{
			rename($DatFile, $NewDatFile);
		        print DATLOG "Loaded $DatFile at $Now\n";
		        print "Loaded $DatFile at $Now\n";
		}
		else
		{
		        print DATLOG "Couldnt load $DatFile at $Now\n";
		}
	}
	close DATLOG;
	
	foreach my $File (@NewItuff)
	{
		my ($Lot_Locn, $Ituff) = ($1, $3) if ($File =~ /^\S+\\(0.*__A)_(temp|TEMP)\\(W\w+)$/);
		my $ItuffThere = $RemoteDir."/".$Lot_Locn."/".$Ituff;
		my $WaferID = substr($Ituff, 1);
		my $AriesSigFile = $AriesSigDir."/".$Lot_Locn."_".$WaferID.".sig";
		my $Now = &DateTime();
		
		$FTP->cwd($RemoteDir) || die "Cant change directory $RemoteDir : $!\n";
		$FTP->mkdir($Lot_Locn);
		
		open (LOG, ">>$FTPITUFFToNETAPPLog") || die "Cannt open $FTPITUFFToNETAPPLog : $!\n";
		if($FTP->put($File, $ItuffThere))
		{
		        print LOG "Loaded $File at $Now\n";
			print "Successful ftp ituff to NETAPP: $File\n";
		}
		else
		{
		        print LOG "Couldnt put $File at $Now\n";
		}
		
		if($FTP->put($TempFile, $AriesSigFile))
		{
		        print LOG "Touch $AriesSigFile at $Now\n";
			print "Successful ftp $AriesSigFile to NETAPP\n";
		}
		else
		{
		        print LOG "Couldnt touch $AriesSigFile at $Now\n";
		}
        }
        $FTP->quit;
        undef $FTP;
	close LOG;
}
