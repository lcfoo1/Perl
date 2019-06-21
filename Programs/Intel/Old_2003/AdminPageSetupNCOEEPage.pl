#################################################################################
#                                                                               #
#        Foo Lye Cheung                             NCO PDQRE Automation        #
#        inet 253 6452                              Penang                      #
#                                                                               #
#        DESCRIPTION                                                            #
#        Adminstration page to change the vote start date and vote end date.    #
#                                                                               #
#        RELEASES                                                               #
#        08/17/2004  rev1.0 - Main code release                                 #
#                                                                               #
#################################################################################

use strict;
use warnings;
use CGI qw(:standard :cgi-lib);
use CGI::Carp qw(fatalsToBrowser);
require 'D:\Perl\Programs\Common.pl';

# Flush the page as the data comes out
$|++;

&AdminCheck();

sub AdminCheck
{
	# Print the header
	my $query = CGI::new();
	print header, start_html(-title => 'ADMINISTRATION WEBPAGE', -style => {-src => '../datamation.css'}, '-font' => 'Tahoma'), h1({-style => 'color:red;font-family=Tahoma'}, 'ADMINISTRATION WEBPAGE');

	my $dbEEVote = &OpenEEVote();
	my %DateStamp = ();
	my $sql = "SELECT VOTESTART, VOTEEND from SETVOTEDATE";
	if($dbEEVote->Sql($sql))
	{
		&ifSQL($dbEEVote, $sql);
	}
	else
	{
		while($dbEEVote->FetchRow())
		{
			my %DateStamp = $dbEEVote->DataHash();
			print "CURRENT VOTE DATE $DateStamp{'VOTESTART'}, END DATE $DateStamp{'VOTEEND'}\n", p;
		}
	}
	$dbEEVote->Close();

	&AdminSetDate();
	print end_form;
}

sub AdminSetDate
{
	my $query = CGI::new();

	# Display data
	print start_form;
	print "<STRONG>START VOTE DATE</STRONG><BR>MONTH (MM): ",textfield(-name =>'SMonth', -default => '', -maxlength => '2', -size => '2'), " DAY (DD) ", textfield(-name =>'SDay', -default => '', -maxlength => '2', -size => '2'), " YEAR (YYYY) " ,textfield(-name =>'SYear', -default => '', -maxlength => '4', -size => '4'), p;

	no warnings;
	my $SYear = param('SYear'); 
	my $SMonth = param('SMonth');
	my $SDay = param('SDay');
	my $StartDate = $SMonth . "/" . $SDay . "/" . $SYear;
	
	print "<STRONG>END VOTE DATE</STRONG><BR>MONTH (MM): ",textfield(-name =>'EMonth', -default => '', -maxlength => '2', -size => '2'), " DAY (DD) ", textfield(-name =>'EDay', -default => '', -maxlength => '2', -size => '2'), " YEAR (YYYY) " ,textfield(-name =>'EYear', -default => '', -maxlength => '4', -size => '4'), p;

	no warnings;
	my $EYear = param('EYear'); 
	my $EMonth = param('EMonth');
	my $EDay = param('EDay');
	my $EndDate =  $EMonth . "/" . $EDay . "/" . $EYear;
	print "NEW START DATE: $StartDate, NEW END DATE: $EndDate\n";
	print submit("Submit"), hr, end_form;
	print " <input type=button value=\"HOME\" onclick=\"location.href='http://datamation.png.intel.com/NCOEEVote/Default.asp'\">";

	print "<BR><BR><font size=\"1\" face=\"Tahoma\" align=\"left\"><b>All Feedback to be directed to Foo, Lye Cheung<br>Powered by <a href=\"http://datamation.png.intel.com\" target=\"New\">NCO PDQRE Automation Group</a></b><br>Copyright © Intel Corporation, 2004. All rights reserved. </font></p>\n";

	if (($EndDate =~ /\d{2}\/\d{2}\/\d{4}/ ) && ($StartDate =~ /\d{2}\/\d{2}\/\d{4}/))
	{
		# Add time as midnight
		my $dbEEVote = &OpenEEVote();
		my $sql = "DELETE from SETVOTEDATE";
		if($dbEEVote->Sql($sql))
		{
			&ifSQL($dbEEVote, $sql);
		}
		else
		{
			$sql = "INSERT INTO SETVOTEDATE (VOTESTART, VOTEEND) VALUES ('". $StartDate . "', '" . $EndDate . "')";
			if($dbEEVote->Sql($sql))
			{
				&ifSQL($dbEEVote, $sql);
			}
			else
			{
				while($dbEEVote->FetchRow())
				{
					my %Temp = $dbEEVote->DataHash();
					print "CURRENT VOTE DATE $Temp{'VOTESTART'}, END DATE $Temp{'VOTEEND'}\n", p;
				}
			}
		}
		$StartDate = "";
		$EndDate = "";
		print "<meta http-equiv='Refresh' content='0'>";
	}
}
