#################################################################################
#                                                                               #
#        Foo Lye Cheung                             NCO PDQRE Automation        #
#        inet 253 6452                              Penang                      #
#                                                                               #
#        DESCRIPTION                                 				#
#        Telnet to S9K, get the list of files at Unix directory before get	#
#        the files via FTP to windows for further processing.			#
#        The files at Windows are processed bin 1, bin 2 and total good bin,	#
#        and compared with MARS DB.						#
#                                                                               #
#        NOTES                                                                  # 
#        Runs as a cronjob every day at 4pm on t3admin6.png.intel.com           #
#										#
#        DEPENDENCIES								#
#        Requires File::Copy, Net::Telnet, Net::FTP, Common.pl			#
#                                                                               #
#        RELEASES                                                               #
#        08/16/2004  rev1.0 - Main code release                                 #
#                                                                               #
#################################################################################

use strict;
use warnings;
use File::Copy;
use Net::Telnet;
use Net::FTP;
require "C:/Perl/Programs/Common.pl";

my $Now = &DateTime;
my %LotSum = ();
my $TmpHTML = "";
my $Copyright = chr 169;
my $ArchiveDir = "C:\\mixcheck\\archive\\";

# Main code starts here
print "S9k Check ULT loader\n";
&GetFilesFromUnix();

my $dbMARS = &OpenMARSCon;
&AnalyseData();
$dbMARS->Close();

# Connect to MARS database
sub OpenMARSCon
{
	my $DNS = "MARS";
	unless($dbMARS = new Win32::ODBC("dsn=$DNS; UID=asblds; PWD=asblds"))
	{
		print "Error: " . Win32::ODBC::Error() . "\n";
		exit;
	}
	return $dbMARS;
}

# Get files information from Unix
sub GetFilesFromUnix
{
	# Variable declaration
	my $Server = "t3admin6.png.intel.com";
	my $LocalDir = 'C:\mixcheck\s9k';
	my $RemoteDir = '/user/home1/prodeng/lfoo1/mixdevice/ftpdata/';
	my $Prompt = "lfoo1";
	my ($User, $Pwd) = ('lfoo1', ',L&OKTOu'^'@*I zf|A');
	my $Now = &DateTime;
	my @LotList = ();

	# Get connectivity to Unix port
	my $Unix = new Net::Telnet (Timeout => 30, Prompt => '/[%#>] $/'); 
	$Unix->open($Server);
	$Unix->login($User, $Pwd);
	print "Connected to $Server\n";

	# Clear out the prompt
	$Unix->prompt("/$Prompt\$/");
	$Unix->cmd("set prompt = '$Prompt'");

	# Get a list of the files
	$Unix->cmd("cd $RemoteDir");
	my @List = $Unix->cmd("ls -l *.txt");

	undef my %LotSize;

	# Rescreen the list of files from Unix directory
	foreach my $Line(@List)
	{
		chomp $Line;
		my $Temp = $1 if ($Line =~ /\s+(\S+txt)$/);
		push (@LotList, $Temp);
		print "$Temp\n";
	}
	
	# Open ftp connection to get the data from Unix server
	my $FTP = Net::FTP->new($Server) || die "Can't connect to $Server : $!\n";
	$FTP->login($User, $Pwd) || die "Can't connect as $User : $!\n";
	$FTP->cwd($RemoteDir) || die "Can't change $RemoteDir : $!\n";
	chdir $LocalDir;
	print "$Server:- FTP starting\n";
	
	foreach my $Lot (@LotList)
	{
		&GetNDeleteFileViaFTP($FTP, $Lot);
	}
	$Unix->close;
	$FTP->quit;
}

# Get the ftp file from t3admin6.png.intel.com and delete file at there
sub GetNDeleteFileViaFTP
{
	no warnings;
	my ($FTP, $Lot) = @_;
	my $Now = &DateTime;

	if($FTP->get($Lot,$Lot))
	{
		print "Got $Lot\n";
		qx/echo "Downloaded $Lot at $Now" >> C:\\mixcheck\\logs\\S9kFTPLog.txt/;
		$FTP->delete($Lot);
	}
	else
	{
		print "Couldnt get $Lot\n";
		qx/echo "Couldnt get $Lot at $Now" >> C:\\mixcheck\\logs\\S9kFTPLog.txt/;
	}
}



# Get B1, B2 and total good bin from MARS at test location - 6102 or 6152
sub GetQtyMARS
{
	#my $LotLocn = "L4300453_6102";
	my $LotLocn = shift;
	my ($Lot, $Locn) = split (/_/, $LotLocn);
	my $Bin2 = 0;
	my (%GoodBin, %Bin1) = ();
	($GoodBin{'TOTALGOOD'}, $Bin1{'B1'}) = (0, 0);

	# Get total good unit - Bin 1 + Bin 2 
	my $sql = "SELECT INQTY AS TOTALGOOD FROM A11_PROD_5.F_LOTHIST " .
		  "WHERE LOT = '" . $Lot . "'AND PREV_OPERATION LIKE '61_2'";

	if($dbMARS->Sql($sql))
	{
		&ifSQL($dbMARS, $sql);
	}
	else
	{
		while($dbMARS->FetchRow())
		{
			%GoodBin = $dbMARS->DataHash();
		}
	}

	# Get next location binning - Bin 1
	$sql = "SELECT INQTY AS B1 FROM A11_PROD_5.F_LOTHIST " .
	       "WHERE LOT = '" . $Lot . "'AND PREV_OPERATION LIKE '61_3'";

	if($dbMARS->Sql($sql))
	{
		&ifSQL($dbMARS, $sql);
	}
	else
	{
		while($dbMARS->FetchRow())
		{
			%Bin1 = $dbMARS->DataHash();
		}
	}
	
	$Bin2 = $GoodBin{'TOTALGOOD'} - $Bin1{'B1'};
	return ($Bin1{'B1'}, $Bin2, $GoodBin{'TOTALGOOD'});
}

# Analyze the data on the temperorary file
sub AnalyseData
{
	my $LocalDir = 'C:\mixcheck\s9k';
	my ($LotLocn, $Device, $TestProgram, $TBin1, $TBin2, $RetestBin12, $Reject, $Result) = ("", "", "", "", "", "", "", "");
	my $ValidData = 0;
	
	chdir $LocalDir || die "Can't change $LocalDir : $!\n";

	foreach my $File(<*>)
	{
		next unless(-f $File);
		print $File."\n";
		
		my ($PhyB1, $PhyB2, $PhyTotal) = (0, 0, 0);
		($PhyB1, $PhyB2, $PhyTotal) = &GetQtyMARS($File);

		$ValidData = 1 if (($PhyB1 != 0) || ($PhyB2 != 0) || ($PhyTotal != 0));
		print "File: $File has physical B1:$PhyB1, B2:$PhyB2, Total:$PhyTotal\n";
		
		open (FILE, $File) || die "Can't open $File : $!";
		while (<FILE>)
		{
			$LotLocn = $1 if(/^LotNum\t(\w+)$/o);
			$Device = $1 if (/^Device\t(\w+)$/o);
			$TestProgram = $1 if (/^TestProgram\t(\w+)$/o);
			$TBin1 = $1 if (/^Bin1\t(\w+)$/o);
			$TBin2 = $1 if (/^Bin2\t(\w+)$/o);
		}
		close FILE;

		my $TotalGood = $TBin1 + $TBin2;
		if ($ValidData == 1) 
		{
			if (($TBin1 < $PhyB1) || ($TBin2 < $PhyB2))
			{
				$Result = "BAD";
				print "The $LotLocn is $Device, $TestProgram, Datalog B1:$TBin1,B2:$TBin2,Total(B1+B2):$TotalGood, Workstream B1:$PhyB1,B2:$PhyB2,Total(B1+B2):$PhyTotal, $Result\n";
			}
			else 
			{
				$Result = "OK";
				print "The $LotLocn is $Device, $TestProgram, Datalog B1:$TBin1,B2:$TBin2,Total(B1+B2):$TotalGood, Workstream B1:$PhyB1,B2:$PhyB2,Total(B1+B2):$PhyTotal, $Result\n";
			}
			
			$LotSum{$LotLocn} = [$Device, $TestProgram, "B1:$TBin1,\nB2:$TBin2,\nTotal:$TotalGood", "B1:$PhyB1,\nB2:$PhyB2,\nTotal:$PhyTotal", $Result];
			$ValidData = 0;
			#&SummarizeLotMail($LotLocn, $RetestBin12, $Reject);
		}
		else
		{
			# This is because, there is possible the lot is not move and on hold at test location (6102/6152)
			$Result = "WS not found";
			$LotSum{$LotLocn} = [$Device, $TestProgram, "B1:$TBin1,\nB2:$TBin2,\nTotal:$TotalGood", "B1:$PhyB1,\nB2:$PhyB2,\nTotal:$PhyTotal", $Result];
		}
		#my $ArchiveFile = $ArchiveDir.$File;
		#move ($File, $ArchiveFile);
	}

	&SummarizeFormatMail();
}


# Summarize processing lots
sub SummarizeFormatMail
{
	my $To = "lye.cheung.foo\@intel.com";
	my $Now = localtime (time);
	my $Subject = "Veder daily check for mix device at $Now!";

	foreach my $LotLocn (keys %LotSum)
	{
		$TmpHTML .= "<TR>" .
			"<TD BGCOLOR=#FFFFC3 ALIGN=left><FONT SIZE=2 FACE=Tahoma><B>$LotLocn</B></FONT></TD>" .
			"<TD BGCOLOR=#FFFFC3 ALIGN=left><B><FONT SIZE=2 FACE=Tahoma><B>$LotSum{$LotLocn}[0]</FONT></B></TD>" .
			"<TD BGCOLOR=#FFFFC3 ALIGN=left><FONT SIZE=2 FACE=Tahoma><B>$LotSum{$LotLocn}[1]</B></FONT></TD>" .
			"<TD BGCOLOR=#FFFFC3 ALIGN=left><B><FONT SIZE=2 FACE=Tahoma><B>$LotSum{$LotLocn}[2]</FONT></B></TD>" .
			"<TD BGCOLOR=#FFFFC3 ALIGN=left><B><FONT SIZE=2 FACE=Tahoma><B>$LotSum{$LotLocn}[3]</FONT></B></TD>" .
			"<TD BGCOLOR=#FFFFC3 ALIGN=left><B><FONT SIZE=2 FACE=Tahoma><B>$LotSum{$LotLocn}[4]</FONT></B></TD></TR>";
	}

	my $Body = <<"MAILBODY";
<HTML><HEAD>
<BODY>
<BLOCKQUOTE DIR=ltr STYLE="MARGIN-RIGHT: 0px">
<FONT FACE=Tahoma SIZE=2>
<FONT COLOR=#FF0000><B>* * * This e-mail contains confidential information! Do not forward, or reply to this e-mail. * * *</B></FONT>
<BR><BR>

<B><FONT SIZE=2>
<TABLE BORDER=1 BORDERCOLOR=#0066CC WIDTH=600>
<TR>
	<TD COLSPAN=8 BGCOLOR=#D9FF80 ALIGN=right><P ALIGN=left><B><FONT SIZE=4>Veder daily check for mix device at $Now!</FONT></B></TD>
</TR>
<TR>
	<TD BGCOLOR=#ADD8E6 ALIGN=left><FONT SIZE=2 FACE=Tahoma><B>Lot & Location</B></FONT></TD>
	<TD BGCOLOR=#ADD8E6 ALIGN=left><B><FONT SIZE=2 FACE=Tahoma>Device</FONT></B></TD>
	<TD BGCOLOR=#ADD8E6 ALIGN=left><FONT SIZE=2 FACE=Tahoma><B>TestProgram</B></FONT></TD>
	<TD BGCOLOR=#ADD8E6 ALIGN=left><B><FONT SIZE=2 FACE=Tahoma>Tester QtyOut</FONT></B></TD>
	<TD BGCOLOR=#ADD8E6 ALIGN=left><B><FONT SIZE=2 FACE=Tahoma>Workstream QtyOut</FONT></B></TD>
	<TD BGCOLOR=#ADD8E6 ALIGN=left><B><FONT SIZE=2 FACE=Tahoma>COMMENT</FONT></B></TD>
</TR>
$TmpHTML
</TABLE>

<FONT FACE=Tahoma>
<BR><BR><BR><BR>
<FONT SIZE=1 COLOR=#0066cc>Powered by <A HREF="http://datamation.png.intel.com">
	NCO PDQRE Automation</A><BR>
	Copyright $Copyright Intel Corporation, 2004. All rights reserved.
</FONT>
</BLOCKQUOTE>
</BODY>
</HTML>
MAILBODY

	&SendSummarizeEmail($To, $Subject, $Body);
}

sub SendSummarizeEmail
{
	my ($To, $Subject, $Body) = @_;
	my $From = "asblds\@intel.com";
	my $Mail = Win32::OLE->new('CDONTS.NewMail'); 
	$Mail->{From} = $From;
	$Mail->{To} = $To;
	$Mail->{Subject} = $Subject;
	$Mail->{BodyFormat} = 0;
	$Mail->{MailFormat} = 0;
	$Mail->{Importance} = 2;
	$Mail->{Body} = $Body if $Body ne 'NULL';
	$Mail->Send();
	undef $Mail;
}
