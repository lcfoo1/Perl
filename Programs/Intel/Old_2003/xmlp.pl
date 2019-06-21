use English;
use XML::Parser;

package ElementInfo;
sub new
{
    my $class = shift;
    my $self = [0, undef, 0, 0, 1, {}, {}, {}];
    bless $self, $class;
}

package main;
sub COUNT () {0;}
sub MINLEV () {1;}
sub SEEN  () {2;}
sub CHARS () {3;}
sub EMPTY () {4;}
sub PTAB  () {5;}
sub KTAB  () {6;}
sub ATAB  () {7;}


my %elements;
my $seen = 0;
my $root;

my $file = shift;
my $subform =
    '      @<<<<<<<<<<<<<<<      @>>>>';
die "Can't find file \"$file\"" unless -f $file;
    
my $parser = new XML::Parser(ErrorContext => 2);
$parser->setHandlers(Start => \&start_handler,
		     Char  => \&char_handler);
$parser->parsefile($file);

sub start_handler
{
    my $p = shift;
    my $el = shift;

    my $elinf = $elements{$el};
    if (not defined($elinf))
    {
	$elements{$el} = $elinf = new ElementInfo;
	$elinf->[SEEN] = $seen++;
    }

    $elinf->[COUNT]++;
    my $partab = $elinf->[PTAB];
    my $parent = $p->current_element;
    if (defined($parent))
    {
	$partab->{$parent}++;
	my $pinf = $elements{$parent};
	$pinf->[KTAB]->{$el}++;
	$pinf->[EMPTY] = 0;
    }
    else
    {
	$root = $el;
    }
    my $atab = $elinf->[ATAB];
    while (@_)
    {
	my $att = shift;
	$atab->{$att}++;
	shift;
    }
}


sub char_handler
{
    my ($p, $data) = @_;
    my $Element = $p->current_element;
    chomp ($Element);
    chomp ($data);

    print "$Element $data\n";
} 

