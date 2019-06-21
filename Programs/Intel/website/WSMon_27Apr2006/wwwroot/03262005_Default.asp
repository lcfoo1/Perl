<%@ Language=PerlScript %>
<% 
#################################################################################
#                                                                               #
#        Foo Lye Cheung                             PDE DPG 		        #
#        inet 253 6452                              Penang                      #
#                                                                               #
#        DESCRIPTION                                                            #
#        Webpage to display the workstation usage and status.			#
#                                                                               #
#        RELEASES                                                               #
#        03/25/2005  rev1.0 - Main code release                                 #
#                                                                               #
#################################################################################

$Response->{Buffer} = 0;
$Server->{ScriptTimeout} = 600;
use warnings;
use ASP qw(:strict);
my $StatusFlag = 0;
my $SummaryWorkstation = 'C:\Intel\Perl\Programs\SummaryWS.txt';

my $Head = "<HTML><HEAD><title>Workstation Monitoring System</title><LINK REL='stylesheet' TYPE='text/css' HREF='workstation.CSS'></HEAD>" .
	   "<TABLE border=1 cellpadding=1 width = \"100%\" cellspacing=0 bgcolor=\"powderblue\" bordercolor=black>" .
	   "<FONT FACE=\"Tahoma\" SIZE=2></TABLE>" .
	   "<HR><TABLE BORDER=1 BORDERCOLOR=#0066CC WIDTH=900><TR><TD COLSPAN=5 BGCOLOR=#D9FF80 ALIGN=left><P ALIGN=left><B>" .
	   "<FONT SIZE=5>Workstation Monitoring System</FONT></B></TD></TR><BR>\n" .
	   "<TR><TD BGCOLOR=#ADD8E6><B><FONT SIZE=2>Workstation Name</FONT></B></TD>\n" .
	   "<TD BGCOLOR=#ADD8E6><B><FONT SIZE=2>User IDSID</FONT></B></TD>\n" .
	   "<TD BGCOLOR=#ADD8E6><B><FONT SIZE=2>Logon</FONT></B></TD>\n" .
	   "<TD BGCOLOR=#ADD8E6><B><FONT SIZE=2>Last Active</FONT></B></TD>\n" .
	   "<TD BGCOLOR=#ADD8E6><B><FONT SIZE=2>Active (secs)</FONT></B></TD></TR>\n";
$Response->Write($Head);

open (SUM, $SummaryWorkstation) or die "Cant open $SummaryWorkstation : $!\n";
while (<SUM>)
{
	chomp;
	if (/^Status=(.*)$/)
	{
		$Status = $1;
		if ($Status eq "No User Logon")
		{
			$StatusFlag = 1;
		}
		else
		{
			$StatusFlag = 0;
		}
	}

	if (!$StatusFlag) 
	{
		if (/^Server=(\w+)$/)
		{
			$Response->Write("<TR><TD BGCOLOR=#ADD8E6><B><FONT SIZE=2>$1</FONT></B></TD>\n");
		}
		elsif (/User=(.*)/)
		{
			$Response->Write("<TD BGCOLOR=#FFFFC3><B><FONT SIZE=2>$1</FONT></B></TD>\n");
		}
		elsif (/^Active=(.*)(\(IDLE=)(\d+)(.*)$/)
		{
			my ($T1, $T2, $T3, $T4) = ($1, $2, $3, $4);
			my $Time = &ConvertTime($T3);
			$Response->Write("<TD BGCOLOR=#FFFFC3><B><FONT SIZE=2>$T1\n$T2$Time$T4</FONT></B></TD></TR>\n");
		}
		elsif (/^Logon=(.*)$/)
		{
			$Response->Write("<TD BGCOLOR=#FFFFC3><B><FONT SIZE=2>$1</FONT></B></TD>\n");
		}
		elsif (/^LastActive=(.*)$/)
		{
			$Response->Write("<TD BGCOLOR=#FFFFC3><B><FONT SIZE=2>$1</FONT></B></TD>\n");
		}
	}
	else
	{
		if (/^Server=(\w+)$/)
		{
			$Response->Write("<TR><TD BGCOLOR=#ADD8E6><B><FONT SIZE=2>$1</FONT></B></TD>\n");
			$Response->Write("<TD BGCOLOR=red><B><FONT SIZE=2>No User Logon</FONT></B></TD>\n");
			$Response->Write("<TD BGCOLOR=red><B><FONT SIZE=2>-</FONT></B></TD>\n");
			$Response->Write("<TD BGCOLOR=red><B><FONT SIZE=2>-</FONT></B></TD>\n");
			$Response->Write("<TD BGCOLOR=red><B><FONT SIZE=2>-</FONT></B></TD></TR>\n");
		}
	}
}
close SUM;

$Response->Write("</TABLE><BR><HR></CENTER><BR>");
my $Footer = "<blockquote dir=\"ltr\" style=\"MARGIN-LEFT: 0px\">" .
	     "<font size=\"1\" face=\"Tahoma\" align=\"left\">" .
	     "<b>All Feedback to be directed to Foo, Lye Cheung" .
	     "<br>Copyright © Intel Corporation, 2005. All rights reserved. </font></p></blockquote>";
$Response->Write($Footer);

# Calculation to get day, hour, minute and second
sub ConvertTime
{
	my $Time = shift;
	my $Day = eval{$Time / 86400};
	$Day =~ s/^(\d+)\.\d+$/$1/;
	my $Hour = eval{($Time - ($Day * 86400)) / 3600};
	$Hour =~ s/^(\d+)\.\d+$/$1/;
	my $Minute = eval{($Time - (($Day * 86400) + ($Hour * 3600))) / 60};
	$Minute =~ s/^(\d+)\.\d+$/$1/;
	my $Second = eval{$Time - (($Day * 86400) + ($Hour * 3600) + ($Minute * 60))};
	return "Day:$Day, HH:$Hour, MM:$Minute, Sec:$Second\n";
}
%>
</BODY>
</HTML>
