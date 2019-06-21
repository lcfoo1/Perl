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
my $SummaryWorkstation = 'C:\WINNT\WSMonitor\SummaryWS.txt';

my $Head = "<HTML><HEAD><title>Workstation Monitoring System</title><LINK REL='stylesheet' TYPE='text/css' HREF='workstation.CSS'></HEAD>" .
	   "<TABLE border=1 cellpadding=1 width = \"100%\" cellspacing=0 bgcolor=\"powderblue\" bordercolor=black>" .
	   "<FONT FACE=\"Tahoma\" SIZE=2></TABLE>" .
	   "<HR><TABLE BORDER=1 BORDERCOLOR=#0066CC WIDTH=950><TR><TD COLSPAN=6 BGCOLOR=#D9FF80 ALIGN=left><P ALIGN=left><B>" .
	   "<FONT SIZE=5>Workstation Monitoring System</FONT></B></TD></TR><BR>\n" .
	   "<TR><TD BGCOLOR=#ADD8E6><B><FONT SIZE=2>Workstation Name</FONT></B></TD>\n" .
	   "<TD BGCOLOR=#ADD8E6><B><FONT SIZE=2>Team</FONT></B></TD>\n" .
	   "<TD BGCOLOR=#ADD8E6><B><FONT SIZE=2>User IDSID</FONT></B></TD>\n" .
	   "<TD BGCOLOR=#ADD8E6><B><FONT SIZE=2>Logon</FONT></B></TD>\n" .
	   "<TD BGCOLOR=#ADD8E6><B><FONT SIZE=2>Last Active</FONT></B></TD>\n" .
	   "<TD BGCOLOR=#ADD8E6><B><FONT SIZE=2>Active</FONT></B></TD></TR>\n";
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
		elsif ($Status eq "Down")
		{
			$StatusFlag = 2;	
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
		elsif (/Team=(.*)/)
		{
			my $Team = $1;
			chomp ($Team);
			if ($Team =~ /^TP$/i)
			{
				$Response->Write("<TD BGCOLOR=#F9CCFF><B><FONT SIZE=2>$Team</FONT></B></TD>\n");
			}
			elsif ($Team =~ /TP\(XP\)/i)
			{
				$Response->Write("<TD BGCOLOR=#FF99CC><B><FONT SIZE=2>$Team</FONT></B></TD>\n");
			}
			elsif ($Team =~ /TM/i)
			{
				$Response->Write("<TD BGCOLOR=#CC99FF><B><FONT SIZE=2>$Team</FONT></B></TD>\n");
			}
			elsif ($Team =~ /PS/i)
			{
				$Response->Write("<TD BGCOLOR=#FFFFC3><B><FONT SIZE=2>$Team</FONT></B></TD>\n");
			}
			elsif ($Team =~ /TV/i)
			{
				$Response->Write("<TD BGCOLOR=#CCFFCC><B><FONT SIZE=2>$Team</FONT></B></TD>\n");
			}
			elsif ($Team =~ /NH/i)
			{
				$Response->Write("<TD BGCOLOR=#C9FC9F><B><FONT SIZE=2>$Team</FONT></B></TD>\n");
			}
		}
		elsif (/User=(.*)/)
		{
			$Response->Write("<TD BGCOLOR=#FFFFC3><B><FONT SIZE=2>$1</FONT></B></TD>\n");
		}
		elsif (/^Active=(.*)/)
		{
			$Response->Write("<TD BGCOLOR=#FFFFC3><B><FONT SIZE=2>$1</FONT></B></TD></TR>\n");
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
		}
		elsif (/Team=(.*)/)
		{
			my $Team = $1;
			chomp ($Team);
			if ($Team =~ /^TP$/i)
			{
				$Response->Write("<TD BGCOLOR=#F9CCFF><B><FONT SIZE=2>$Team</FONT></B></TD>\n");
			}
			elsif ($Team =~ /TP\(XP\)/i)
			{
				$Response->Write("<TD BGCOLOR=#FF99CC><B><FONT SIZE=2>$Team</FONT></B></TD>\n");
			}
			elsif ($Team =~ /TM/i)
			{
				$Response->Write("<TD BGCOLOR=#CC99FF><B><FONT SIZE=2>$Team</FONT></B></TD>\n");
			}
			elsif ($Team =~ /PS/i)
			{
				$Response->Write("<TD BGCOLOR=#FFFFC3><B><FONT SIZE=2>$Team</FONT></B></TD>\n");
			}
			elsif ($Team =~ /TV/i)
			{
				$Response->Write("<TD BGCOLOR=#CCFFCC><B><FONT SIZE=2>$Team</FONT></B></TD>\n");
			}
			elsif ($Team =~ /NH/i)
			{
				$Response->Write("<TD BGCOLOR=#C9FC9F><B><FONT SIZE=2>$Team</FONT></B></TD>\n");
			}

			if ($StatusFlag == 1)
			{
				$Response->Write("<TD BGCOLOR=lightgreen><B><FONT SIZE=2>No User</FONT></B></TD>\n");
				$Response->Write("<TD BGCOLOR=lightgreen><B><FONT SIZE=2>-</FONT></B></TD>\n");
				$Response->Write("<TD BGCOLOR=lightgreen><B><FONT SIZE=2>-</FONT></B></TD>\n");
				$Response->Write("<TD BGCOLOR=lightgreen><B><FONT SIZE=2>-</FONT></B></TD></TR>\n");
			}
			elsif ($StatusFlag == 2)
			{				
				$Response->Write("<TD BGCOLOR=red><B><FONT SIZE=2>Down</FONT></B></TD>\n");		
				$Response->Write("<TD BGCOLOR=red><B><FONT SIZE=2>-</FONT></B></TD>\n");
				$Response->Write("<TD BGCOLOR=red><B><FONT SIZE=2>-</FONT></B></TD>\n");
				$Response->Write("<TD BGCOLOR=red><B><FONT SIZE=2>-</FONT></B></TD></TR>\n");
			}
		}
	}
}
close SUM;

$Response->Write("</TABLE><BR><HR></CENTER><BR>");
my $Footer = "<blockquote dir=\"ltr\" style=\"MARGIN-LEFT: 0px\">" .
	     "<font size=\"1\" face=\"Tahoma\" align=\"left\">" .
	     "<b>All Feedback to be directed to Foo, Lye Cheung" .
	     "<br>Copyright � Intel Corporation, 2005. All rights reserved. </font></p></blockquote>";
$Response->Write($Footer);

%>
</BODY>
</HTML>
