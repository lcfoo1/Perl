package WikiDVLib;

##
## author: Stephan Rotter
##    Method to upload email messages to OAP wiki
##
##

use strict;
use lib "$ENV{DV_TOOL}/DVLib";
use WWW::Mechanize;
use HTTP::Cookies;
#use LWP::Debug qw(+);    ## srotter: gives troubleshooting messages
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter AutoLoader);
@EXPORT = qw( initWiki uploadWikiSite editWikiSite editWikiSiteBySection readWikiSite );
$VERSION = '0.10';

## GLOBAL VARS
my $oapwiki = 'https://degwiki.intel.com/wiki/oap/index.php';
my $mech    = WWW::Mechanize->new();
my $debug   = 0;

sub initWiki {
  print "-i- Logging on to OAP Wiki\n";
  my $url = 'https://degwiki.intel.com/cgi-bin/common/auth/nph-login/wiki/oap/index.php/Main_Page';
  my $username = "AMR\\\\ecsys_pdelctsc";
  my $password = "exAltlim\$1";
  if (!($debug )) {   $mech->quiet(1);  }
  $mech->cookie_jar(HTTP::Cookies->new());
  $mech->get($url);
  die "-E- Can't even get the home page: ", $mech->response->status_line
     unless $mech->success;
  $mech->field(login => $username);
  $mech->field(password => $password);
  $mech->click();
  if ($debug) {  print $mech->content(format => "text"); }
}

sub editWikiSite {
  my ($appendmode,$wikisite,$text) = @_;
  my $url = $oapwiki.'?title='.$wikisite.'&action=edit';

  print "-i- Edit on to Wiki - $wikisite\n";
  $mech->get($url);
  die "-E- Can't even get the home page: ", $mech->response->status_line
     unless $mech->success;
  $mech->form_name("editform");

  if ($appendmode =~ /append/i) {
     $text = $mech->value('wpTextbox1')."\n".$text;
  }
  $mech->field(wpTextbox1 => $text);
  $mech->click("wpSave");  
  if ($mech->title() =~ /^Editing/) {  ## double submit if 1st time didn't stick
	  $mech->click("wpSave");
  }
  if ($debug) {  print $mech->content(format => "text")."\n"; }
}

sub editWikiSiteBySection {
  my ($appendmode,$wikisite,$section,$text) = @_;
  my $url = $oapwiki.'?title='.$wikisite.'&action=edit';
  my $curtext;
  my $section_number=0;
  my $section_valid=0;
  my $section_head="";
  my @section_path;
  my @request_path = split("=",$section);
  my %wiki_hash_path;
  my $content ="";
  my $level;
  my $title;
  my $match;
  my $line_number;
  my $line_number_insert;
  my $text_header="";
  my $tmp;

  $mech->get($url);
  die "-E- Can't even get the home page: ", $mech->response->status_line
     unless $mech->success;
  $mech->form_name("editform");
  $curtext = $mech->value('wpTextbox1');

  # parse wikipage and create table of contents in hash table
  $line_number = 0;
  for my $line (split(/\n/,$curtext)) {
    $line_number++;
    if ($line =~ /^(\=+)/) {
      $level = $1;
      $title = $line;
      $title =~ s/^$level\s*//g;
      $title =~ s/\s*$level$//g;
    
      while ($#section_path > length($level)-1) { pop(@section_path);      }
      while ($#section_path < length($level)-1) { push(@section_path,""); }
      $section_path[length($level)-1] = $title;

      for(my $i = 0; $i<=$#section_path;$i++) {
	if ($i == 0) {
	  $tmp = $section_path[$i];
	} else {
	  $tmp = $tmp."=".$section_path[$i]
	}
	if (!(exists $wiki_hash_path{$tmp})) {
	  if ($debug) {  print "-i- wiki page chapter: $tmp\n"; }
	  $wiki_hash_path{$tmp} = $line_number;
	} 
      }
    }
  }

  # find nearest section in table of content for user request  
  $line_number_insert = 0;
  for(my $i = 0; $i<=$#request_path;$i++) {
    if ($i == 0) {
      $tmp = $request_path[$i];
    } else {
      $tmp = $tmp."=".$request_path[$i];
    }
    if (exists $wiki_hash_path{$tmp}) {
      if ($debug) {  print "-i- found a match               : $tmp\n"; }
      $line_number_insert = $wiki_hash_path{$tmp};
    } else {
      if ($debug) {  print "-i- no match and need to create : $tmp\n"; }
      $text_header = $text_header. "="x($i+1). $request_path[$i] . "="x($i+1)."\n";
    }
  }
  $text = $text_header.$text;
  # if no match was found, just add user request to end of wikipage
  if ($line_number_insert == 0) { $line_number_insert = $line_number; }
  
  # insert user request into page content at right location
  $line_number=0;
  $match = 0;
  for my $line (split(/\n/,$curtext)) {
    $line_number++;
    if (($line =~ /^(\=+)/)&&($match)) {
      $content .= "$text\n";
      $match=0;
    }
    if (($match)&&($appendmode !~ /append/i)) { next; }
    $content .= "$line\n";
    if ($line_number_insert == $line_number) { $match = 1; }
  }
  if ($match) {
    $content .= "$text\n"; $match=0;
  }

  # update wikisite
  $mech->field(wpTextbox1 => $content);
  $mech->click("wpSave");  
  if ($mech->title() =~ /^Editing/) {  ## double submit if 1st time didn't stick
	  $mech->click("wpSave");
  }
  if ($debug) {  print $mech->content(format => "text")."\n"; }
}

#  Do I need to rename posted file with timestamp (currently it overwrites) - srotter
sub uploadWikiSite {
  my ($path,$filename,$description) = @_;
  my $uploadfile = $path."\\".$filename;

  print "-i- Uploading on to Wiki - $uploadfile\n";
  $filename =~ s/\s/_/g;

  if ($filename =~ /png$|jpg$|bmp$|gif$|xls$|ppt$|doc$|txt$/i) {
	print "-i- file extentions : passes \n";
  } else {
	print "-i- file extentions modified for wiki - appending \.txt\n";
	$filename =~ s/\.\w+/.txt/g;
  }

  my $url = $oapwiki.'/Special:Upload';
  $mech->get($url);
  die "-E- Can't even get the home page: ", $mech->response->status_line
     unless $mech->success;
  $mech->form_name("upload");

  $mech->field(wpUploadFile => $uploadfile);
  $mech->field(wpDestFile => $filename);
  $mech->field(wpUploadDescription => $description);

  $mech->click("wpUpload");

  if ($debug) {  print $mech->content(format => "text"); }
  if ($filename =~ /jpg$|png$|gif$|bmp$/i) { 
	return ("[[Image:$filename|thumb|none|$description]]");
  } else {
    	return ("[[Media:$filename|$description]]");
  }
}

sub readWikiSite {
  my ($style,$wikisite) = @_;
  my $url;
  my $output_page;
  if ($style =~ /wiki/) {
	$url = $oapwiki.'?title='.$wikisite.'&action=edit';
  } else {
	$url = $oapwiki.'?title='.$wikisite;
  }
  print "-i- Reading Wiki - $wikisite\n";
  $mech->get($url);
  die "-E- Can't even get the home page: ", $mech->response->status_line
     unless $mech->success;
  if ($style =~ /html/) { 
    $output_page = $mech->content();
  } elsif ($style =~ /wiki/) {
    $mech->form_name("editform");
    $output_page = $mech->value('wpTextbox1');
  } else {
     $output_page = $mech->content(format => "text");
  }
  return($output_page)
}

sub stampTime {
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
  $year += 1900;
  $mon  += 1;
  if ($sec  !~ /\d\d/) { $sec  = "0".$sec;  }
  if ($min  !~ /\d\d/) { $min  = "0".$min;  }
  if ($hour !~ /\d\d/) { $hour = "0".$hour; }
  if ($mday !~ /\d\d/) { $mday = "0".$mday; }
  if ($mon  !~ /\d\d/) { $mon  = "0".$mon;  }

  return($year."-".$mon."-".$mday.", ".$hour.".".$min.".".$sec);
}

1;

__END__

= WikiDVLib =
== Summary ==
This is a DVLib perl module to enable perl updates to the OAP Wiki site
https://degwiki.intel.com/wiki/oap/index.php

== Functions ==
initWiki()
: Initializes Intranet connection and Logs into OAP wiki site
:* i: N/A
:* o: N/A
uploadWikiSite ()
: Uploads a file onto the wiki site.  If the file is not of type /png$|jpg$|bmp$|gif$|xls$|ppt$|doc$|txt$/i, the function will append ".txt" onto the file when posting.  The output of this function is a wiki link that one can use to paste into a subsequent wiki page text
:* i: <path> <filename> <description>
:* o: <link>
editWikiSite ()
: Allows for editing a wiki site.  The write mode kills existing wiki content on site whereas append just adds to site.
:* i: <"append"|"overwrite"> <wikipath> <text>
:* o: N/A
editWikiSiteBySection ()
: Allows for editing a wiki site.  The write mode kills existing wiki content on site whereas append just adds to site.  The sectiontitle specifies which = subsection = to modify.  If given a unique section it will append at end of wikisite.  The section name uses '=' to traverse heirarchy (eg "DV=Gainestown=A0" is DV chapter, Gainestown section, A0 subsection -or- =DV=, ==Gainestown==, ===A0===
:* i: <"append"|"overwrite"> <wikipath> <sectiontitlepath> <text>
:* o: N/A
readWikiSite()
:* This function returns the results on the page as full page html, full page visible text, or just wiki section in wiki format
:* i: <"wiki"|"html"|"text"> <wikipath>
:* o: <results>

== Examples ==
<pre>
use lib "$ENV{DV_TOOL}/DVLib";
use WikiDVLib;
initWiki();
$link = uploadWikiSite("C:\Temp","mypresentation.ppt","My Presentation Description");
editWikiSite("append","Team/FxnDV/Demo","Hello World\n See my presentation here: $link ");
editWikiSiteBySection("append","Team/FxnDV/Demo","Demo=Section1","Hello World\n See my presentation here: $link ");
print readWikiWite("text", "Team/FxnDV/Demo");
</pre>
