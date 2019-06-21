use strict;
use warnings;
use Win32::OLE;
use Win32::Perms;
use Win32::Lanman;
use GD::Graph::bars;
use CGI qw(:standard :cgi-lib);
use CGI::Carp qw(fatalsToBrowser);

my @data = (	['Fall 01', 'Spr 01', 'Fall 02', 'Spr 02' ], 
		[80, 90, 85, 75],
            	[76, 55, 75, 95],
            	[66, 58, 92, 83]);

require 'D:\Perl\Programs\Common.pl';

# Variable settings
my %QueryString = Vars();
my $Dir = $QueryString{'Dir'};

# Flush the page as the data comes out
$|++;

# Print the header
#print header, start_html(-title => ' NCO EE VOTING GRAPH ', -style => {-src => '../datamation.css'}, '-font' => 'Tahoma');
#print h1({-style => 'color:red;font-family=Tahoma'},' NCO EE VOTING GRAPH ');

my $mygraph = GD::Graph::bars->new(500, 300);
$mygraph->set(
    x_label     => 'Semester',
    y_label     => 'Marks',
    title       => 'Grade report for a student',
    # Draw bars with width 3 pixels
    bar_width   => 3,
    # Sepearte the bars with 4 pixels
    bar_spacing => 4,
    # Show the grid
    long_ticks  => 1,
    # Show values on top of each bar
    show_values => 1,
) or warn $mygraph->error;

$mygraph->set_legend_font(GD::gdMediumBoldFont);
$mygraph->set_legend('Exam 1', 'Exam 2', 'Exam 3');
my $myimage = $mygraph->plot(\@data) or die $mygraph->error;

print "Content-type: image/jpg\n\n";
print $myimage->png;




print "<BR><BR><FONT COLOR=Red><B> Finish Processing Page!</B></FONT>";
print end_html;
