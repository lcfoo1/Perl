#!/usr/intel/bin/perl

# @(#)$Id: phone,v 1.19 1998/10/15 18:33:25 twitham Exp $

# Client command-line interface to the remote httpd interface of the
# phonebook program.  Acts almost like the actual command-line
# phonebook program except for a new -V (verbose) option to show the
# httpget transfer and -n to pass cookies from a specified netscape
# cookie file or ~/.netscape/cookies.  Assumes httpget is on $PATH.

# See http://phonebook.fm.intel.com/howto.html for more info.

# By Tim Witham, <twitham@pcocd2.intel.com>, 1995/08/18

# The URL of the phonebook server to contact:
$0 =~ s!^.*/!!;			# use our name so we can contact different
$phonebook = $0;		# servers by simply having multiple names
$phonebook =~ s!^!http://phonebook.fm.intel.com/cgi-bin/!;

$httpget = '/usr/intel/97r1.3/bin/httpget'; # the httpget to use

$| = 1;				# unbuffer stdout for quick feedback

grep(s/^\s*--?help\s*$/-h/, @ARGV); # alternate GNU-like -h formats
grep(s/(\W)/sprintf("%%%02x", ord($1))/eg, @ARGV);
grep(s/%20/+/g, @ARGV);		# hex escape special chars, + for space
grep(s/^%2d/-/g, @ARGV);	# restore the option's leading -

while ($_ = shift @ARGV) {	# turn command-line args into http CGI args
    if (/^-V$/) {		# show Verbose httpget transfer
	$opt_v = ' -v';
    } elsif (/^-n$/) {		# netscape cookie file name
	$opt_n = ' -n' . ($ARGV[0] =~ /^-/ ? '' : (' ' . shift @ARGV));
	$opt_n =~ s/%(..)/chr(hex($1))/eg;
    } elsif (/^-e$/) {		# explicit expression; get it
	$expr = shift @ARGV;
    } elsif (/^-([pfwdckuU])$/) { # option needs an arg; get it
	$argv .= "&$1=" . ($arg = shift @ARGV);
    } elsif (/^-(.+)$/) {	# other option; assume it's a boolean for now
	$argv .= "&$1=y";
    } else {			# assume expression unless set previously
	$expr || ($expr = $_);
    }
}				# next arg...

$argv .= "&p=$0" unless $argv =~ /&p=[^&]/; # pass my basename to server
$argv .= "&e=$expr";		# always pass the -e expression
$argv =~ s/^&/\?/;		# fix syntax of first arg

open(PIPE, "$httpget$opt_v$opt_n -r '$phonebook$argv' -l - |")
    || die "$0: can't pipe from $httpget: $!\n";
print while (<PIPE>);
close PIPE;
exit 0;

