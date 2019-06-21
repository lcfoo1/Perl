#################################################################################################
#                                                                                               #
#     Justin Devanandan Allegakoen                          NCO PDQRE Automation                #
#     inet 253 7392                                         Penang                              #
#                                                                                               #
#     DESCRIPTION                                                                               #
#     This code checks WS for all ICH6 lots at bake, and then grabs the iTUFF at test to check  #
#     what the tester quantity out is versus the WS quantity out. For tester qty out < WS qty   #
#     out it will send a trigger email to those listed. It also tracks missing sumamries        #
#     based on the ssq files found in mvsn1.                                                    #
#                                                                                               #
#     NOTES                                                                                     #
#     Originally wrote to notify list to put lots on hold, now its treated as FYI because       #
#     the fuses may toggle at Sort, which yields invalid data.                                  #
#                                                                                               #
#     RELEASES                                                                                  #
#     08/03/2004 rev1.0 - Main code release                                                     #
#                                                                                               #
#################################################################################################
use strict;
use warnings;
use File::Find;
use Win32::OLE;
use Win32::FileOp;

require 'C:\Perl\Programs\Common.pl';

# Variable declaration
my $Copyright = chr 169;
my (%PkgDevices, %Lots);
my $ProdDir = '//mvsn1.png.intel.com/C$/Intel/adis/t3db/bak_data';
my $SequenceDir = '//mvsn1.png.intel.com/C$/Intel/adis/t3db/ssq';
my $BackupDir = '//mvsn1.png.intel.com/C$/Intel/ITUFF_PG6/Pre';
my $From = 'ICH6QtyChecker@intel.com';
my $MainTo = 'mohd.zulkhairi.bin.bahari@intel.com; nicole.yin.er.choong@intel.com; inafariza.ibrahim@intel.com; ' .
				'habibah.ismail@intel.com; irene.bee.khim.low@intel.com; raja.kamar.raja.siffudin@intel.com; ' . 
				'shamsolbahri.yusoff@intel.com; kim.im.ooi@intel.com; ' . 
				'choung.shyang.kang@intel.com; soon.huat.pua@intel.com; boon.kooi.lee@intel.com; shu.chin.lim@intel.com; ' .
				'horng.sing.lim@intel.com;';
my $iTUFFTo = 'kim.im.ooi@intel.com; choung.shyang.kang@intel.com; shu.chin.lim@intel.com; horng.sing.lim@intel.com; ' .
				'ching.tatt.teoh@intel.com';

#sub STOP{
my $dbMARS = &OpenMARS();

# Build a hash of all devices
my $sql = "SELECT DISTINCT SUBSTR(PRODUCT, 0, 8) PKGDEVICE FROM A11_PROD_5.F_PRODUCT WHERE PRODGROUP4 = '6-PBGA0609'";

if($dbMARS->Sql($sql))
{
	&ifSQL($dbMARS, $sql);
}
else
{
	while($dbMARS->FetchRow())
	{
		my %Temp = $dbMARS->DataHash();
		$PkgDevices{$Temp{'PKGDEVICE'}}++;
		print "Found PkgDevice $Temp{'PKGDEVICE'}\n";
	}
}

# Find all lots currently at Bake for each device found
foreach my $PkgDevice(keys %PkgDevices)
{
	my $sql = "SELECT LOT FROM A11_PROD_5.F_LOT WHERE PRODUCT LIKE '$PkgDevice%' AND OPERATION = 6620";

	if($dbMARS->Sql($sql))
	{
		&ifSQL($dbMARS, $sql);
	}
	else
	{
		while($dbMARS->FetchRow())
		{
			my %Temp = $dbMARS->DataHash();
			next unless $Temp{'LOT'} =~ /^L/;
			push @{$Lots{$Temp{'LOT'}}}, "$PkgDevice";
			print "Found Lot $Temp{'LOT'}\n";
		}
	}
}

# Find QtyOut from RC or PBIC
foreach my $Lot(keys %Lots)
{
	my $sql = "SELECT OPERATION, NEWQTY1 FROM A11_PROD_5.F_LOTHIST WHERE LOT = '$Lot' AND (OPERATION = 6102 OR OPERATION = 6152)";

	if($dbMARS->Sql($sql))
	{
		&ifSQL($dbMARS, $sql);
	}
	else
	{
		while($dbMARS->FetchRow())
		{
			my %Temp = $dbMARS->DataHash();
			push @{$Lots{$Lot}}, $Temp{'OPERATION'}, $Temp{'NEWQTY1'};
			print "Found $Lot at $Temp{'OPERATION'} with $Temp{'NEWQTY1'} units\n";
		}
	}
}
$dbMARS->Close();
#} # DELETE THIS

# FOR TESTING WITHOUT MARS
#%Lots = (
#	'L4310025' => ['8I6DTVAB', '6102', '750'],
#	'L4310223' => ['8I6DTVAB', '6102', '750'],
#);

# Now we're done with MARS, lets ensure we have connectivity to mvsn1.png.intel.com
if(-e $SequenceDir)
{
	print "Connection to $SequenceDir already exists - proceeding with program . . .\n";
}
else
{
	my $P = 'B)1HY^B'^'7GX0hlq';
	Connect $SequenceDir, {user => 'trillium\trillprod', passwd => $P} or die "Cant connect to $SequenceDir:- $!";
	print "Just made a connection to $SequenceDir - proceeding with program . . .\n";
}

foreach my $Lot(keys %Lots)
{
	my $Locn = ${$Lots{$Lot}}[1];
	&FindSummarySequence(lc $Lot, $Locn);
}

sub FindSummarySequence
{
	my ($Lot, $Locn) = @_;
	my $SubDir = substr $Lot, 0, 4;
	my $File = "$SequenceDir/$SubDir/$Lot" . "_$Locn.ssq";
	my @SummarySequence;

	if(-e $File)
	{
		open(FILE, $File) or die "Cant open $File:- $!";
		while(<FILE>)
		{
			if(/^(\w{2,6});/)
			{
				next if $1 =~ /(std|eol|rls)/;
				push @SummarySequence, $1;
			}
		}
		close FILE;

		opendir DIR, $BackupDir;
		my @Files = grep (/$Lot\_$Locn/i, readdir DIR);
		rewinddir DIR;
		closedir DIR;
		@Files ? &ProcessiTUFF('Main', $Lot, $Locn, \@Files, \@SummarySequence) : &SearchForiTUFFElsewhere(uc $Lot, \@SummarySequence);
	}
	else
	{
		&AlertMissingiTUFF("ICH6 lot $Lot at $Locn has missing sequence file!");
	}
}

sub ProcessiTUFF
{
	my ($Caller, $Lot, $Locn, $Files, $SummarySequence) = @_;
	my ($Dir, %UnitCount, %iTUFFSummaries);
	$Lot = uc $Lot;

	if($Caller eq 'Main')
	{
		$Dir = $BackupDir;
	}
	elsif($Caller eq 'Elsewhere')
	{
		$Dir = $ProdDir;
	}
	
	# Open each file found for the same lot/locn to check if all summaries are found and in order, otherwise there's no point processing
	foreach my $File(@$Files)
	{
		open(FILE, "$Dir/$File") or die "Cant open $Dir/$File:- $!";
		while(<FILE>)
		{
			if(/^4_smrynam_(\w+)/o)
			{
				if($1 =~ /std/o)
				{
					$_ = <FILE> until /^4_lend/o;
				}
				else
				{
					if(exists $iTUFFSummaries{$1})
					{
						&AlertMissingiTUFF("ICH6 lot $Lot at $Locn has duplicate $1 summaries!");
						goto DUPLICATE;
					}
					$iTUFFSummaries{$1}++;
				}
			}

			# Slurp it all in to one variable, and perform a regexp to sum all the bin 1's
			if(/^3_binn_1$/o)
			{
				local $/ = '2_lend';
				local $_ = <FILE>;
				$UnitCount{"$1$2"}++ if /2_tname_ituff_value_1\n2_mrslt_0+(\d+)\.0+\n2_lsep\n2_tname_ituff_value_2\n2_mrslt_0+(\d+)\.0+/;
			}
		}
		close FILE;
	}

	my @iTUFFSummaries = sort keys %iTUFFSummaries;
	my $AllInOrder = &CheckForMissingSummaries($Lot, $Locn, $Dir, \@$Files, \@iTUFFSummaries, \@$SummarySequence);
	
	# Heres where we check the tester qty vs WS
	if($AllInOrder)
	{
		my @TesterQtyOut = keys %UnitCount;
		my $GoodBins = scalar @TesterQtyOut;
		&AlertQtyMismatch($Lot, $GoodBins, \@{$Lots{$Lot}}, \@$Files, $Dir) if $GoodBins < ${$Lots{$Lot}}[2];
	}
DUPLICATE:
}

sub CheckForMissingSummaries
{
	my ($Lot, $Locn, $Dir, $Files, $iTUFFSummaries, $SummarySequence) = @_;
	my ($InOrder, %MissingSummaries) = (1, ());

	@MissingSummaries{@$SummarySequence} = (0..$#{$SummarySequence});
	delete @MissingSummaries{@$iTUFFSummaries};
	my @MissingSummaries = sort{$MissingSummaries{$a} <=> $MissingSummaries{$b}} keys %MissingSummaries;
	
	if(@MissingSummaries)
	{
		&AlertMissingiTUFF("ICH6 lot $Lot at $Locn has missing summaries for @MissingSummaries!");
		$InOrder = 0;
	}

	return $InOrder;
}

sub SearchForiTUFFElsewhere
{
	my ($Lot, $SummarySequence) = @_;
	
	opendir DIR, $ProdDir;
	my $Locn = ${$Lots{$Lot}}[1];
	my @Files = grep (/$Lot\_$Locn/i, readdir DIR);
	rewinddir DIR;
	@Files ? &ProcessiTUFF('Elsewhere', $Lot, $Locn, \@Files, \@$SummarySequence) : &AlertMissingiTUFF("ICH6 iTUFF file not found for $Lot!");
	closedir DIR;
}

sub AlertMissingiTUFF
{
	my $Subject = shift;
	my $Body = 'NULL';
	my @Files = ();
	print "$Subject\n";

	&SendEmail($iTUFFTo, $Subject, \$Body, \@Files, '');
}

sub AlertQtyMismatch
{
	my ($Lot, $TesterGood, $Details, $Files, $Dir) = @_;
	my $Subject = "ICH6 quantity mismatch for $Lot!";
	my $Body = <<"MAILBODY";
<HTML><HEAD>
<BODY>
<BLOCKQUOTE DIR=ltr STYLE="MARGIN-RIGHT: 0px">
<FONT FACE=Tahoma SIZE=2>
<FONT COLOR=#FF0000><B>* * * This e-mail contains confidential information! Do not forward, or reply to this e-mail. * * *</B></FONT>
<BR><BR>

<B><FONT SIZE=2>
<TABLE BORDER=1 BORDERCOLOR=#0066CC WIDTH=500>
<TR>
	<TD COLSPAN=6 BGCOLOR=#D9FF80>
	<P ALIGN="left"><FONT SIZE=2 FACE=Tahoma><B>Quantity mismatch between between tester and Workstream for ICH6!</B></FONT></TD>
</TR>
<TR>
	<TD BGCOLOR=#ADD8E6 ALIGN=left><FONT SIZE=2 FACE=Tahoma><B>Lot</B></FONT></TD>
	<TD BGCOLOR=#ADD8E6 ALIGN=left><FONT SIZE=2 FACE=Tahoma><B>Locn</B></FONT></TD>
	<TD BGCOLOR=#ADD8E6 ALIGN=left><B><FONT SIZE=2 FACE=Tahoma>Device</FONT></B></TD>
	<TD BGCOLOR=#ADD8E6 ALIGN=left><B><FONT SIZE=2 FACE=Tahoma>Tester QtyOut</FONT></B></TD>
	<TD BGCOLOR=#ADD8E6 ALIGN=left><B><FONT SIZE=2 FACE=Tahoma>Workstream QtyOut</FONT></B></TD>
</TR>
<TR>
	<TD BGCOLOR=#FFFFC3 ALIGN=left><B><FONT SIZE=2 FACE=Tahoma>$Lot</FONT></B></TD>
	<TD BGCOLOR=#FFFFC3 ALIGN=left><B><FONT SIZE=2 FACE=Tahoma>$$Details[1]</FONT></B></TD>
	<TD BGCOLOR=#FFFFC3 ALIGN=left><B><FONT SIZE=2 FACE=Tahoma>$$Details[0]</FONT></B></TD>
	<TD BGCOLOR=#FFFFC3 ALIGN=left><B><FONT SIZE=2 FACE=Tahoma>$TesterGood</FONT></B></TD>
	<TD BGCOLOR=#FFFFC3 ALIGN=left><B><FONT SIZE=2 FACE=Tahoma>$$Details[2]</FONT></B></TD>
</TR>
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

	print "$Subject\n";
	&SendEmail($MainTo, $Subject, \$Body, \@$Files, $Dir);
}

sub SendEmail
{
	my ($To, $Subject, $Body, $Files, $Dir) = @_;
	my $Mail = Win32::OLE->new('CDONTS.NewMail'); 
	$Mail->{From} = $From;
	$Mail->{To} = $To;
	$Mail->{Subject} = $Subject;
	$Mail->{BodyFormat} = 0;
	$Mail->{MailFormat} = 0;
	$Mail->{Importance} = 2;
	$Mail->{Body} = $$Body if $$Body ne 'NULL';

	#if(@$Files)
	#{
	#	foreach my $File(@$Files)
	#	{
	#		$Mail->AttachFile("$Dir/$File");
	#	}
	#}
	$Mail->Send();
	undef $Mail;
}
