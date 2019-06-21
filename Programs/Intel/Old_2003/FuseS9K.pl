#!/usr/local/bin/perl -w

#################################################################################
#										#
#	Foo Lye Cheung					NCO Automation PDQRE	#
#	29 June 2004								#
#										#
#	Auto Fusing Check System						#
#										#
#################################################################################

use File::Find;

my (%DevicePEList, %ListLotError, %BadBin2, %BadBin1) = ();
my $TmpReportHTML = "";
my ($ErrorBinFlag, $FoundLotFlag) = (0, 0); 
my @TmpBadBin =();

my @LotDir = ();
my $ProdDir = '/db1/s9k/prod';
#my $ProdDir = '/engr/restore/Database.2004_20';
#my $ProdDir = '/prod/pg6_archive/database/Database_Archive/Database.2004_23';

#my @LotDir = ('/db1/s9k/prod/L4LCFOO1_6152');
#my @LotDir = ('/engr/restore/Database.2004_22/L4160518_6102');
#my @LotDir = ('/engr/restore/Database.2004_22/L4120448T_6102');

&GetProdTable();
finddepth(\&GetiTUFFDir, $ProdDir);
&iTUFFDir(@LotDir);

# Check to make sure the log file is append once per day
sub CheckTime
{
	my $LogFile = "/user/home1/prodeng/lfoo1/fuse/fuseS9K.log";
	my ($sec, $min, $hour) = localtime(time);
	#print "$sec1, $min1, $hour1\n";
	my $Now = localtime(time);
	#if ((($hour%5) == 0) && ($FoundLotFlag))
	if ($FoundLotFlag)
	{
		$TmpReportHTML = "";
		$TmpReportHTML = "<TABLE BORDER=1 BORDERCOLOR=#0066CC WIDTH=600>\n<TR>\n<TD COLSPAN=2 BGCOLOR=#D9FF80 ALIGN=right><P ALIGN=left><B><FONT SIZE=4>Lot details</FONT></B></TD>\n";

		foreach my $iTUFFDirChecked (keys %ListLotError)
		{
			$TmpReportHTML .= "<TR> <TD BGCOLOR=#ADD8E6 ALIGN=left><B><FONT SIZE=2>$iTUFFDirChecked</FONT></B></TD><TD BGCOLOR=#FFFFC3 ALIGN=center><B><FONT SIZE=2>$ListLotError{$iTUFFDirChecked}</FONT></B></TD>\n";
		}
		$TmpReportHTML .="</TR>\n</TABLE>\n";

		print "There is lot tested at $LogFile on $Now\n";
		&SendReportMailDaily();
	}
	#elsif ((($hour%5) == 0) && (!$FoundLotFlag))
	elsif (!$FoundLotFlag)
	{
		$TmpReportHTML = "";
		$TmpReportHTML = "<TABLE><TR><TD BGCOLOR=#ADD8E6 ALIGN=left><B><FONT SIZE=4>NO LOT TESTED LAST 4 HOURS!!!</FONT></B></TD></TR></TABLE>\n";
		&SendReportMailDaily();
		open(LOG, ">>$LogFile") or die "Cannt open $LogFile : $!\n";
		print LOG "No Lot tested today - $Now\n";
		close LOG;
		print "There is no lot tested at $LogFile on $Now\n";
	}
	else 
	{
		print "You are running the script at $Now and not at 5am\n";
	}
}

# Get the device and PEs emails list from lookup table
sub GetProdTable
{
	my $LookupTable = "/user/home1/prodeng/lfoo1/fuse/prod.tbl";
	open (PRODDEV, $LookupTable) or die "Cann't open $LookupTable : $!\n";
	while (<PRODDEV>)
	{
		my ($Device, $PEEmails) = split (/\,/, $_, 2);
		$DevicePEList{$Device} = $PEEmails;
	}
	close PRODDEV;
}

# Get all iTUFF Y summary from directory /db1/s9k/prod
sub GetiTUFFDir
{
	local ($^W) = 0;
	next unless (($File::Find::name =~ /(\S+\/L\w+_(6102|6152))\/\dY$/o) && (-M $File::Find::name <= 1/4));
	push (@LotDir, $1);
}

# Screening the lot directory
sub iTUFFDir
{
	foreach my $iTUFFDir (@LotDir)
	{
		&CheckiTUFF($iTUFFDir);
	}
	&CheckTime();
}

# Check the ituff summary from the lookup table before processing
sub CheckiTUFF
{
	my $iTUFFDir = shift;
	my $InvalidiTUFF = 0;
	my ($LastiTUFFFlag, $DevFoundFlag) = (0, 0);
	my ($Lot, $Locn, $Summary, $Device, $TestProgram, $TmpTo) = ();

	chdir $iTUFFDir or die "Cann't open $iTUFFDir : $!\n";

	foreach my $iTUFF (<*>)
	{
		$LastiTUFFFlag = 1 if $iTUFF =~ /^\dY$/o;
		next unless $iTUFF =~ /^\d[ABCDE]$/;
		$InvalidiTUFF = 0;
		
		print "Directory: $iTUFFDir with ituff: $iTUFF\n";
		open (ITUFF, $iTUFF) or die "Cann't open $iTUFF : $!\n";
		while (<ITUFF>)
		{
			# End the checking as the wrong ituff format, eg. /engr/restore/Database.2004_22/L4170422_6152/1A
			if (($. == 1) && ($_ !~ /^7_lbeg/o))
			{
				$InvalidiTUFF = 1;
				last;
			}

			$Lot = $1  if /^6_lotid_(\w+)/o;
			$Device = $1 if /^6_prdct_(\w+)/o;
			$TestProgram = $1 if /^6_prgnm_(\w+)/o;
			$Locn = $1 if /^5_lcode_(\d+)/o;	
			
			if (/^4_smrynam_(\w+)/o)	 
			{
				$Summary = $1;

				foreach my $Dev (keys %DevicePEList)
				{
					if ($Dev eq $Device)
					{
						chomp($TmpTo = $DevicePEList{$Dev});
						$DeviceFoundFlag = 1; 
						last;
					}
				}
			}
		}
		close ITUFF;

		if (($DeviceFoundFlag) && (!$InvalidiTUFF))
		{
			&CheckFuse($Summary);
		}
	}

	my $Now = localtime (time);

	# Ensure to send email at the last summary of the lot
	if (($LastiTUFFFlag) && ($ErrorBinFlag))
	{
		$ListLotError{$iTUFFDir} = "Found Error on $Now\n"; 
		&SendMail($TmpTo, $Lot, $Locn, $Device, $TestProgram, $iTUFFDir);
		(%BadBin1, %BadBin2) = ();
		$FoundLotFlag = 1;
		$ErrorBinFlag = 0;
	}
	elsif (($DeviceFoundFlag) && (!$InvalidiTUFF) && (!$ErrorBinFlag) && ($LastiTUFFFlag))
	{
		print "Found no error fusing or binning for Bin 1 and Bin 2\n";
		$ListLotError{$iTUFFDir} = "Found no error fusing or binning for Bin 1 and Bin 2\n";
		my $LogFile = "/user/home1/prodeng/lfoo1/fuse/fuseS9K.log";
		my $Now = localtime (time);
		$FoundLotFlag = 1;
		open(LOG, ">>$LogFile") or die "Cannt open $LogFile : $!\n";
		print LOG "Found no error at $iTUFFDir - $Now\n";
		close LOG;
	}
}

# Check bin 1 and bin 2 fusing and bad faildata units
sub CheckFuse
{
	my $Summary = shift;
	my ($PrtName, $ComntToken, $FailDataToken) = ('', '', '');

	open (ITUFF, $Summary) or die "Cann't open $Summary : $!\n";
	while (<ITUFF>)
	{
		s/ //g;
		$PrtName = $1 if /^3_prtnm_(\d+)/;

		if (/^2_pttrn_FUSE_DATA$/o)
		{
			$_ = <ITUFF>;
			$ComntToken = $1 if (/^2_comnt_\w{4}(\w{4})/o);  		
			$FailDataToken = $1 if (/^2_faildata_\w{4}(\w{4})/o);
		}

		# Checking hard bin 2 for error at comnt and faildata token
		if (/^2_curibin_2$/o)
		{ 
			if (($ComntToken eq "UUUU") && ($FailDataToken eq ""))
			{
				my $Bin2Key = "$Summary (No Fuse - UUUU)";
				push @{$BadBin2{$Bin2Key}}, $PrtName; 
				$ErrorBinFlag = 1;
			}
			# Tester shown bin 2 fusing but being fuse as bin 1
			if ($FailDataToken eq "U11U")
			{
				my $Bin2Key = "$Summary (Faildata - U11U)";
				push @{$BadBin2{$Bin2Key}}, $PrtName; 
				$ErrorBinFlag = 1;
			}
			$ComntToken = '';
                        $FailDataToken = '';
		}

		# Checking hard bin 1 for error at comnt and faildata token
		if (/^2_curibin_1$/o)
		{ 
			if (($ComntToken eq "UUUU") && ($FailDataToken eq ""))
			{
				my $Bin1Key = "$Summary (No Fuse - UUUU)";
				push @{$BadBin1{$Bin1Key}}, $PrtName; 
				$ErrorBinFlag = 1;
			}
			# Tester shown bin 1 fusing but being fuse as bin 2
			if ($FailDataToken eq "1UU1")
			{
				my $Bin1Key = "$Summary (Faildata - 1UU1)";
				push @{$BadBin1{$Bin1Key}}, $PrtName; 
				$ErrorBinFlag = 1;
			}
			$ComntToken = '';
                        $FailDataToken = '';
		}

	}
	close ITUFF;
}


# Send mail to the PEs from the email list
sub SendMail
{
	my ($TmpTo, $Lot, $Locn, $Device, $TestProgram, $iTUFFDir) = @_;
	my $Copyright = chr(169);
	my $Now = localtime (time);
	my $To = "To: $TmpTo";
	my $From = "From: t3admin6\@png.intel.com";
	my $Subject = "Subject: Auto Checking Fuse System for $iTUFFDir at $Now";
	my $TmpHTML;

	foreach my $SummaryError (keys %BadBin1)
	{
		my $UnitCount = $#{$BadBin1{$SummaryError}} + 1;
		&ReOrganizePrtName(@{$BadBin1{$SummaryError}});
		my $PrtName = join (' ', @TmpBadBin);

		$TmpHTML .= "<TR> <TD BGCOLOR=#FFFFC3 ALIGN=left><B><FONT SIZE=2>Bin 1</FONT></B></TD><TD BGCOLOR=#FFFFC3 ALIGN=center><B><FONT SIZE=2>$SummaryError</FONT></B></TD><TD BGCOLOR=#FFFFC3 ALIGN=left><B><FONT SIZE=2>$UnitCount</FONT></B></TD><TD BGCOLOR=#FFFFC3 ALIGN=left><B><FONT SIZE=2>$PrtName</FONT></B></TD>";
		print "Bin 1: $SummaryError $PrtName\n";
		@TmpBadBin =();
	}

	foreach my $SummaryError (keys %BadBin2)
	{
		my $UnitCount = $#{$BadBin2{$SummaryError}} + 1;
		&ReOrganizePrtName(@{$BadBin2{$SummaryError}});
		my $PrtName = join (' ', @TmpBadBin);

		$TmpHTML .= "<TR> <TD BGCOLOR=#FFFFC3 ALIGN=left><B><FONT SIZE=2>Bin 2</FONT></B></TD><TD BGCOLOR=#FFFFC3 ALIGN=center><B><FONT SIZE=2>$SummaryError</FONT></B></TD><TD BGCOLOR=#FFFFC3 ALIGN=left><B><FONT SIZE=2>$UnitCount</FONT></B></TD><TD BGCOLOR=#FFFFC3 ALIGN=left><B><FONT SIZE=2>$PrtName</FONT></B></TD>\n";
		print "Bin 2: $SummaryError $PrtName\n";
		@TmpBadBin =();
	}

	my $Content = <<"MAILBODY";
Content-Type: text/html;
<HTML><HEAD><TITLE>Message</TITLE>
<META http-equiv=Content-Type content="text/html; charset=us-ascii">
<BODY>
<BLOCKQUOTE DIR=ltr STYLE="MARGIN-RIGHT: 0px">
<FONT FACE="Tahoma" SIZE=2>
<FONT COLOR=#FF0000><B>* * * This e-mail contains confidential information! Do not forward, or reply to this e-mail. * * *</B></FONT>
<BR><BR>
<B>Auto Fuse Checking System, the details are as follows:</B>

<BR><BR>
<TABLE BORDER=1 BORDERCOLOR=#0066CC WIDTH=600>
<TR>
	<TD COLSPAN=2 BGCOLOR=#D9FF80 ALIGN=right><P ALIGN=left><B><FONT SIZE=4>Lot details</FONT></B></TD>
</TR>
<TR>
	<TD BGCOLOR=#ADD8E6><B><FONT SIZE=2>Lot</FONT></B></TD>
	<TD BGCOLOR=#FFFFC3><B><FONT SIZE=2>$Lot</FONT></B></TD>
</TR>
<TR>
	<TD BGCOLOR=#ADD8E6><B><FONT SIZE=2>Location</FONT></B></TD>
	<TD BGCOLOR=#FFFFC3><B><FONT SIZE=2>$Locn</FONT></B></TD>
</TR>
<TR>
	<TD BGCOLOR=#ADD8E6><B><FONT SIZE=2>Test program</FONT></B></TD>
	<TD BGCOLOR=#FFFFC3><B><FONT SIZE=2>$TestProgram</FONT></B></TD>
</TR>
<TR>
	<TD BGCOLOR=#ADD8E6><B><FONT SIZE=2>Device</FONT></B></TD>
	<TD BGCOLOR=#FFFFC3><B><FONT SIZE=2>$Device</FONT></B></TD>
</TR>
<!--
<TR>
	<TD BGCOLOR=#ADD8E6><B><FONT SIZE=2>Total quantity in</FONT></B></TD>
	<TD BGCOLOR=#FFFFC3><B><FONT SIZE=2>1989</FONT></B></TD>
</TR>
-->
</TABLE>
<BR><BR>

<TABLE BORDER=1 BORDERCOLOR=#0066CC WIDTH=600>
<TR>
	<TD COLSPAN=4 BGCOLOR=#D9FF80><P ALIGN=left><B><FONT SIZE=4>Summaries for lot affected</FONT></B></TD>
</TR>
<TR>
	<TD BGCOLOR=#ADD8E6 ALIGN=left><B><FONT SIZE=2>Bin Information</FONT></B></TD>
	<TD BGCOLOR=#ADD8E6 ALIGN=left><B><FONT SIZE=2>Summary and Error</FONT></B></TD>
	<TD BGCOLOR=#ADD8E6 ALIGN=left><B><FONT SIZE=2>Total affected</FONT></B></TD>
	<TD BGCOLOR=#ADD8E6 ALIGN=left><B><FONT SIZE=2>Unit or Part Name</FONT></B></TD>
</TR>

$TmpHTML
</TABLE>
<BR><BR><BR><BR>
	<FONT SIZE=1 COLOR=#0066cc><B>Powered by <A HREF="http://datamation.png.intel.com">
                NCO PDQRE Datamation</A><BR>
                Copyright $Copyright Intel Corporation, 2004. All rights reserved.</B>
	</FONT>
</BLOCKQUOTE>
</FONT>
</BODY>
</HTML>
MAILBODY

        open(SENDMAIL, "|/usr/lib/sendmail -oi -t") or die "$!\n";
	print SENDMAIL "$From\n$To\n$Subject\n$Content";
	close SENDMAIL or warn "Didnt close as expected:- $!\n";

	my $LogFile = "/user/home1/prodeng/lfoo1/fuse/fuseS9K.log";
	open(LOG, ">>$LogFile") or die "Cannt open $LogFile : $!\n";
	print LOG "Error binning and fusing at $iTUFFDir - $Now\n";
	close LOG;
}

# Rearrange the list from 1,2,3 to 1-3
sub ReOrganizePrtName
{
	my @TmpList = @_;
	#@TmpList =();
	#@TmpList = (4);

	# Add dummy # to the list, to get last unit value
	push (@TmpList, 1000000);

	my ($StartPrtNameFlag, $IncPrtNameFlag, $DiffFlag, $InsertFlag) = (0, 0, 0, 0);
	my ($StartPrtName, $Tmp, $AddPrtName, $PrevPrtName) = ('', '', '',0);

	foreach my $PrtName (@TmpList)
	{
		$AddPrtName = $PrevPrtName + 1;
		if (($PrtName == 1000000) && ($PrevPrtName == 1))
		{
			push (@TmpBadBin, $PrevPrtName);			
			last;
		}
		$PrevPrtName = 1 if ($PrtName == 1);

		if ($PrtName eq $AddPrtName)
		{
			if (!$StartPrtNameFlag)
			{	
				$StartPrtName = $PrevPrtName;
				$StartPrtNameFlag = 1;
			}
			else
			{
				$IncPrtNameFlag = 1;
				$InsertFlag = 1;
				$Tmp = "$StartPrtName-$PrtName";		
			}
		}
		else
		{	
			# Case 1, 2, 5, 7, 8 (where have single or more integer in between)
			if (($IncPrtNameFlag) && (!$StartPrtNameFlag))
			{
				if ($DiffFlag >0)
				{		
					push (@TmpBadBin, $PrtName);
				}
			}
			elsif (($IncPrtNameFlag) && ($InsertFlag))
			{
				# Insert for 1,2,3 condition
				push (@TmpBadBin, $Tmp);
				$InsertFlag = 0;
			}
			elsif ($StartPrtNameFlag)
			{
				# Insert for condition 1, 3, 4
				push (@TmpBadBin, "$StartPrtName-$PrevPrtName");
			}
			else
			{
				local ($^W) = 0;
				if ($PrevPrtName == 0)
				{
					# Ignore the $PrevPrtName variable at the beginning
				}
				elsif (($PrtName ne $PrevPrtName) && ($PrevPrtName ne $TmpBadBin[$#TmpBadBin]))
				{
					push (@TmpBadBin, $PrevPrtName);
				}
			}
			$StartPrtName = '';
			$IncPrtNameFlag = 0;
			$StartPrtNameFlag = 0;			
			$DiffFlag=1;
		}
		$PrevPrtName = $PrtName;
	}
	print "Modified @TmpBadBin\n";
}

# Send mail to the PEs from the email list
sub SendReportMailDaily
{

	my $TTo = 'lye.cheung.foo@intel.com,donovan.a.chin@intel.com,hou.wai.lai@intel.com,kwang.yee.chin@intel.com';
	#my $TTo = 'lye.cheung.foo@intel.com';
	my $Copyright = chr(169);
	my $Now = localtime (time);
	my $To = "To: $TTo";
	my $From = "From: t3admin6\@png.intel.com";
	my $Subject = "Subject: Daily report for Auto Checking Fuse System at $Now";


	my $Content = <<"MAILBODY";
Content-Type: text/html;
<HTML><HEAD><TITLE>Message</TITLE>
<META http-equiv=Content-Type content="text/html; charset=us-ascii">
<BODY>
<BLOCKQUOTE DIR=ltr STYLE="MARGIN-RIGHT: 0px">
<FONT FACE="Tahoma" SIZE=2>
<FONT COLOR=#FF0000><B>* * * This e-mail contains confidential information! Do not forward, or reply to this e-mail. * * *</B></FONT>
<BR><BR>
<B>Auto Fuse Checking System Report, the details are as follows:</B>

<BR><BR>

$TmpReportHTML

<BR><BR>

<BR><BR><BR><BR>
	<FONT SIZE=1 COLOR=#0066cc><B>Powered by <A HREF="http://datamation.png.intel.com">
                NCO PDQRE Datamation</A><BR>
                Copyright $Copyright Intel Corporation, 2004. All rights reserved.</B>
	</FONT>
</BLOCKQUOTE>
</FONT>
</BODY>
</HTML>
MAILBODY

        open(SENDMAIL, "|/usr/lib/sendmail -oi -t") or die "$!\n";
	print SENDMAIL "$From\n$To\n$Subject\n$Content";
	close SENDMAIL or warn "Didnt close as expected:- $!\n";
}
