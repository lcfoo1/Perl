#!/usr/contrib/bin/perl 

#################################################################################
#										#
#	Foo Lye Cheung			Penang Sort Automation			#
#	04/16/2004								#
#										#
#	OIF2endlot.pl is to integrate with the end lot function on the OIF	#
#	This script will check the waferid from the token 4_waferid_		#
#	rename the ituff name and copy the ituff to the ARIES directory,	#
#	create a ARIES signal file and Data Broker signal file.			#
#										#
#	Require Perl 4.0 as all HP94K tester is using this version		#
# 	Format: OIF2endlot.pl <lot#> <location>					#
#										#
#	Rev 2.0									#
#										#
#################################################################################

### Main program starts here ###
# Global variable
$count = 0;
($Lot, $Locn) = ($ARGV[0], $ARGV[1]);
%ItuffName;

$ProdLotDir = "C:\\hptestdir\\production\\".$Lot."_".$Locn."\\";
$ProdLocLog = $ProdLotDir."LOC\\".$Lot.".inkless.log";
$AriesLotDir = "C:\\hptestdir\\aries\\".$Lot."_".$Locn."\\";
$AriesSigDir = "C:\\hptestdir\\ariessig\\";
$DBrokerSigDir = "C:\\hptestdir\\databrokersig\\";
$ITDir = "C:\\hptestdir\\dbrokerlog\\";

#$ProdLotDir = "/lopte/data/summary/t3/".$Lot."_".$Locn."/";
#$ProdLocLog = $ProdLotDir."LOC/".$Lot.".inkless.log";
#$AriesLotDir = "/lopte/intel/hp94k/sort/aries/data/ituff/".$Lot."_".$Locn."/";
#$AriesSigDir = "/lopte/intel/hp94k/sort/aries/signal/ituff/";
#$DBrokerSigDir = "/lopte/intel/hp94k/sort/databroker/signal/";
#$ITDir = "/lopte/home1/lfoo1/DataBroker/Log/";

&Main();

# Main program
sub Main
{
	opendir (DIR,$ProdLotDir) || die "Cannt open $OrgDir : $!\n";
	@Files = readdir(DIR);
	closedir DIR;
	&ItuffConverter(@Files);

	# Make a copy of log file and store at NETAPP server
	$ITLog = $ITDir.$Lot.".inkless.log";
	qx/copy $ProdLocLog $ITLog/;
	#qx/cp $ProdLocLog $ITLog/;
}

# Check the wafer id from Ituff
sub ItuffConverter
{
	@Files = @_;
	foreach $File (@Files)
	{
		next if (-f $File);
		$File = $ProdLotDir.$File;
		next unless (-f $File);
	
		open (FILE, $File) || die "Cannt open $File : $!\n";
		while (<FILE>)
		{
			$DateTime = $1 if (/7_filcret_(\d+)$/);
	
			if (/4_wafid_(\w+)/)
			{
				$WaferID = $1;
				last;
			}

			#if (/4_begindt_(\d+)$/)
			#{
			#	$DateTime = $1;
			#	last;
			#}
		}
		close FILE;

		$WaferID_Time = $WaferID."_".$DateTime;
		$ItuffName{$WaferID_Time} = $File;
	}

	# Create Aries directory if it do not exist
	qx/mkdir $AriesLotDir/ unless (-e $AriesLotDir);

	# Sort the wafer ID read from OCR with date and time to rearrange the ituff summary
	foreach $KeyItuffName (sort keys %ItuffName)
	{
		($NewWaferID, $tmp) = split (/\_/, $KeyItuffName);

		# Check whether the ituff is for resort wafer
		if ($NewWaferID eq $PrevNewWaferID)
		{
			$count++;
			$NewItuffName = $NewWaferID."R".$count;
		}
		else
		{
			$count = 0;
			$NewItuffName = $NewWaferID;
		}
		$PrevNewWaferID = $NewWaferID;
		#print "## $ItuffName{$KeyItuffName} :: $KeyItuffName :: $NewItuffName ##\n";
	
		# Copy production ituff to Aries directory with wafer ID as filename
		$OldName = $ItuffName{$KeyItuffName};
		$AriesItuff = $AriesLotDir."W".$NewItuffName;
		print "File: $ItuffName{$KeyItuffName}, Aries: $AriesItuff :: $KeyItuffName\n";
		qx/copy $OldName $AriesItuff/;
		#qx/cp $OldName $AriesItuff/;
		
		# Rename the original ituff name to the correct name based on the wafer ID
		#$RenItuff = $ProdLotDir."W".$NewItuffName;
		#qx/move $OldName $RenItuff/;
		#qx/mv $OldName $RenItuff/;

		# Create Aries signal file
		$AriesSigFile = $AriesSigDir.$Lot."_".$Locn."_".$NewItuffName.".sig";
		open (ARIESSIG, ">$AriesSigFile") || die "Cannt open $AriesSigFile : $!\n";
		close ARIESSIG;

		# Create Data Broker signal file
		$DBrokerSigFile = $DBrokerSigDir."SORT==DATALOGS==".$Lot."_".$Locn."==W".$NewItuffName.".sig";
		open (DBROKERSIG, ">$DBrokerSigFile") || die "Cannt open $DBrokerSigFile : $!\n";
		close DBROKERSIG;	

		$Now = localtime(time);

		# Create log file at LOC production directory as record
		open (WLOG, ">>$ProdLocLog") || die "Cannt open $ProdLocLog : $!\n";
		print WLOG "File: $OldName, renamed to W$NewItuffName, and Aries: $AriesItuff at $Now\n";
		close WLOG;
	}
}
