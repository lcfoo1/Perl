use XML::Parser;



package Elinfo;

sub new
{
    my $class = shift;
    my $self = [0, undef, 0, 0, 1, {}, {}, {}];

    bless $self, $class;
}

package main;

# These should be above. But I can't seem to import
# them reliably without
# Elinfo being in a separate file.

sub COUNT () {0;}
sub MINLEV () {1;}
sub SEEN  () {2;}
sub CHARS () {3;}
sub EMPTY () {4;}
sub PTAB  () {5;}
sub KTAB  () {6;}
sub ATAB  () {7;}

my $count = 0;
my $parser = new XML::Parser(ErrorContext => 2);
$parser->setHandlers(Start => \&start_handler,
		     Char  => \&char_handler);
$parser->parsefile('sample.xml');


sub start_handler
{
    my $p = shift;
    my $el = shift;

    my $elinf = $elements{$el};

    if (not defined($elinf))
    {
	$elements{$el} = $elinf = new Elinfo;
	$elinf->[SEEN] = $seen++;
    }

    $elinf->[COUNT]++;

    my $partab = $elinf->[PTAB];

    my $parent = $p->current_element;
    if (defined($parent))
    {
	$partab->{$parent}++;
	my $pinf = $elements{$parent};

	# Increment our slot in parent's child table
	$pinf->[KTAB]->{$el}++;
	$pinf->[EMPTY] = 0;
    }
    else
    {
	$root = $el;
    }

    # Deal with attributes
    my $atab = $elinf->[ATAB];
    while (@_)
    {
	my $att = shift;
	$atab->{$att}++;
	shift;	# Throw away value
    }
}  # End start_handler

     Print  Add to Project 
 Email 

--------------------------------------------------------------------------------
Tags: perl xml se 
--------------------------------------------------------------------------------
Bookmark with del.icio.us 
Using The Perl XML::Parser Module
by Clark Cooper
September 12, 1998

XML::Parser is a Perl module which acts as an interface to expat, James Clark's XML parser. A prototype was originally created by Larry Wall, and Clark Cooper has continued the development of this useful tool. In this article Clark presents two Perl programs which demonstrate some of XML::Parser's capabilities.

 
Most Perl applications in need of an XML parser will likely fall into one of two types. The first type of application will process specific applications of XML, for example RDF or MathML. For these, a subclass of XML::parser will need to be written in order to provide a tool conceptually closer to the job at hand. The second type of application will operate on any conforming XML document in order to find or filter out pieces of the document, or to discover things about its structure. This article will discuss two examples of the second type of application, utilities that do useful things with generic XML documents.

Overview of XML::Parser
First, let's go over the current XML::Parser interface. Like James Clark's expat library, upon which it's built, XML::Parser is an event-based parser. Prior to parsing the document, an application registers various event handlers with the parser. Then, as the document is parsed, the handlers are called when the relevant parts are recognized. 

Most utilities need only register 3 handlers: start, end, and character handlers. The start handler is called when an XML start tag is recognized; the end handler is called on recognition of an end tag; and the character handler is called for non-markup content inside an element. The first example below uses a default handler. I'll explain it during the discussion of the example. 

xmlcomments
The xmlcomments utility prints out all the comments in a given document with the line numbers on which the comment started. At conclusion, it prints out the total number of comments found.

The main part of the program, after checking for the existence of the file given as the first argument, creates the parser object with the ErrorContext option set to 2. This requests that errors in the document be reported with 2 lines of context on either side of an occurrence of an error. Two handlers are registered, the character handler, and the default handler. Then the file is parsed. All the action is in the default_handler function.

#!/usr/local/bin/perl -w

use XML::Parser;

my $file = shift;

die "Can't find file \"$file\""
  unless -f $file;
    
my $count = 0;

my $parser = new XML::Parser(ErrorContext => 2);

$parser->setHandlers(Char => \&char_handler,
		     Default => \&default_handler);

$parser->parsefile($file);

print "Found $count comments.\n";

################
## End of main
################

A registered default handler is called when the parser recognizes a portion of the document for which no handler has been registered (excepting start and end tags). You can't currently register handlers for things like comments and markup declarations. But a registered default handler will be called when these things are recognized. The default handler is also called (other than start and end tags) when there is no other handler registered for the particular event. 

sub char_handler
{
    # This is just here to reduce the noise seen by
    # the default handler
}  # End of char_handler


We're going to find comments by looking for things that are sent to the default handler beginning with "<!--". This isn't reliable if we're also seeing character data. After all, somebody could have a cdata section that begins like that. So to make sure that character data doesn't get sent to the default handler, we register an empty character handler.

sub default_handler
{
    my ($p, $data) = @_;

    if ($data =~ /^<!--/)
    {
	my $line = $p->current_line;
	$data =~ s/\n/\n\t/g;
	print "$line:\t$data\n";
	$count++;
    }

}  # End of default_handler


In the default handler, when we get data that looks like the beginning of a comment, we get the current line number, replace newlines with a newline followed by a tab. We then print the comment along with the line number and increment the global comment count. 

My first cut at writing this example was more complicated, since I didn't know whether or not comments were always delivered with a single call to the handler. After I ran some experiments and looked at the expat code, I found out they were. If expat ever broke up a comment into multiple calls to the handler, we would have had to check whether or not the comment ended in the current call; then we'd have to set a flag indicating that we're inside an open comment; and whether we were looking for the beginning or the end of a comment would depend on the flag.

xmlstats
The second example program, xmlstats, prints out statistics about the structure of an XML document. For each type of element seen in the document, it prints out: 

the number times the element occurred 
the number of times it had a particular element as a parent 
the number of times it had a particular element as a child 
the number of times it had a particular attribute 
the amount of character data that had at least some non-whitespace characters 
whether the element was always empty 

The order of the listing is top down, so no element should be listed until at least one of its parents has been listed. 

The initial part of the program deals with establishing a lightweight object to hold element information. There will be one of these Elinfo objects created for each element type. 

#!/usr/local/bin/perl -w

package Elinfo;

sub new
{
    my $class = shift;
    my $self = [0, undef, 0, 0, 1, {}, {}, {}];

    bless $self, $class;
}

package main;

# These should be above. But I can't seem to import
# them reliably without
# Elinfo being in a separate file.

sub COUNT () {0;}
sub MINLEV () {1;}
sub SEEN  () {2;}
sub CHARS () {3;}
sub EMPTY () {4;}
sub PTAB  () {5;}
sub KTAB  () {6;}
sub ATAB  () {7;}

After declaring and setting some variables we'll need later, the main part of the program starts out very similar to our last example. We create a parser object and set some handlers. This time, though, the start handler does most of the heavy lifting and the character handler actually does a little bit of work.

use English;
use XML::Parser;

my %elements;
my $seen = 0;
my $root;

my $file = shift;

my $subform =
    '      @<<<<<<<<<<<<<<<      @>>>>';
die "Can't find file \"$file\""
  unless -f $file;
    
my $parser = new XML::Parser(ErrorContext => 2);
$parser->setHandlers(Start => \&start_handler,
		     Char  => \&char_handler);

$parser->parsefile($file);


However, after the parse, there's some work to do stepping through the objects that were created. Let's take a look at the handlers first so that we can see how the objects are generated. 

sub start_handler
{
    my $p = shift;
    my $el = shift;

    my $elinf = $elements{$el};

    if (not defined($elinf))
    {
	$elements{$el} = $elinf = new Elinfo;
	$elinf->[SEEN] = $seen++;
    }

    $elinf->[COUNT]++;

    my $partab = $elinf->[PTAB];

    my $parent = $p->current_element;
    if (defined($parent))
    {
	$partab->{$parent}++;
	my $pinf = $elements{$parent};

	# Increment our slot in parent's child table
	$pinf->[KTAB]->{$el}++;
	$pinf->[EMPTY] = 0;
    }
    else
    {
	$root = $el;
    }

    # Deal with attributes

    my $atab = $elinf->[ATAB];

    while (@_)
    {
	my $att = shift;
	
	$atab->{$att}++;
	shift;	# Throw away value
    }

}  # End start_handler


sub char_handler
{
    my ($p, $data) = @_;
    my $inf = $elements{$p->current_element};

    $inf->[EMPTY] = 0;
    if ($data =~ /\S/)
    {
	$inf->[CHARS] += length($data);
    }
}  # End char_handler


set_minlev($root, 0);

my $el;

foreach $el (sort bystruct keys %elements)
{
    my $ref = $elements{$el};
    print "\n================\n$el: ", $ref->[COUNT], "\n";
    print "Had ", $ref->[CHARS], " bytes of character data\n"
	if $ref->[CHARS];
    print "Always empty\n"
	if $ref->[EMPTY];

    showtab('Parents', $ref->[PTAB], 0);
    showtab('Children', $ref->[KTAB], 1);
    showtab('Attributes', $ref->[ATAB], 0);
}



