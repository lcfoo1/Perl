use Tk;
use strict;
use warnings;
my $AddInt=0;
my $MinusInt=0;
my $MultiInt=0;
my $DivInt=0;
my $stuff;

my $main = MainWindow ->new ();
$main -> minsize (qw(250 250));
$main -> title ("LC Foo's First Perl Tk Script");
$main -> configure (-background =>'cyan');
my $Top = $main -> Frame (-background => 'cyan') -> pack (-side => 'top', -fill => 'x');
my $Title = $Top -> Frame (-background =>'cyan') -> pack (-side => 'top', -pady=>20, -padx=>8);
my $DisplayTitle = $Title -> Label (-text => "Welcome to LC Foo's Simple Calculator", -font=>20, -background=>'cyan')->pack();

my $Picture = $Top ->Frame (-background =>'cyan') -> pack(-side=>'left',-pady=>2, -padx=>15);
$Picture -> Photo ('lcfoo1', -file =>"lcfoo1.gif");
my $DisplayImage = $Picture ->Label('image'=>'lcfoo1')->pack;

my $MenuBar = $main -> Menu (-tearoff => 1, -type => 'menubar');
$main -> configure(-menu=>$MenuBar);
my $mnuFile = $MenuBar -> cascade(-label=>'~File');
$mnuFile -> command(-label => 'E~xit', -command => sub{exit});

my $Column1 = $Top -> Frame (-background =>'cyan') ->pack(-side=>'left',pady=>15,padx=>8);
my $LblInt1 = $Column1 -> Label (-text => 'Enter First Integer', -background =>'cyan')->pack;

my $Int1 = $Column1 -> Entry(-width=>10, -validate => 'focusout' , -vcmd => sub{&IsNumber})->pack;
$Int1->insert('end',0);

my $Item = $Column1 -> Label (-text=>'', -background=>'cyan')->pack();
my $Item0 = $Column1 -> Label (-text=>'Mathematical Operation', -background=>'cyan')->pack();
my $Item1 = $Column1 -> Label (-text=>'Add', -background=>'cyan')->pack();
my $Item2 = $Column1 -> Label (-text=>'Minus', -background=>'cyan')->pack();
my $Item3 = $Column1 -> Label (-text=>'Multiple', -background=>'cyan')->pack();
my $Item4 = $Column1 -> Label (-text=>'Divide', -background=>'cyan')->pack();
$Item = $Column1 -> Label (-text=>'', -background=>'cyan')->pack();

my $Column2 = $Top ->Frame (-background =>'cyan') -> pack(-side=>'left',-pady=>15, -padx=>15);
my $LblInt2 =$Column2 -> Label (-text=>'Enter Second Integer', -background =>'cyan')->pack;
my $Int2 = $Column2 -> Entry(-width=>10, -validate => 'focusout' , -vcmd => sub{&IsNumber})->pack;
$Int2->insert('end',0);

my $Answer = $Column2 -> Label (-text=>'', -background=>'cyan')->pack();
my $Answer0 = $Column2 -> Label (-text=>'Answer', -background=>'cyan')->pack();
my $Answer1 = $Column2 -> Label (-textvariable=>\$AddInt,-background=>'green', -width=>12, -borderwidth=>2, -relief=>'sunken')->pack();
my $Answer2 = $Column2 -> Label (-textvariable=>\$MinusInt,-background=>'green', -width=>12, -borderwidth=>2, -relief=>'sunken')->pack();
my $Answer3 = $Column2 -> Label (-textvariable=>\$MultiInt,-background=>'green', -width=>12, -borderwidth=>2, -relief=>'sunken')->pack();
my $Answer4 = $Column2 -> Label (-textvariable=>\$DivInt,-background=>'green', -width=>12, -borderwidth=>2, -relief=>'sunken')->pack();

$Answer = $Column2 -> Label (-text=>'', -background=>'cyan')->pack();
$Column1->Button(-text=>'OK', -command=> sub{Calculate($Int1,$Int2)})->pack;
$Column2->Button(-text=>'Exit', -command=> sub{$main->destroy})->pack;

MainLoop();

sub IsNumber
{
	my ($Int) = shift;
	if (($Int <=352) && ($Int >=0) && ($Int =~ /^\d+$/))
	{
		print "Is number entered: $Int is valid\n";
	}
	else 
	{
		print "Not valid data entered\n";
		&Invalid ($Int);
	}

}


sub Calculate
{
	my ($Int1, $Int2) = @_;
	my $Integer1 =$Int1->get;
	my $Integer2 =$Int2->get;

	if (($Integer1 <=352) && ($Integer1 >=0) && ($Integer1 =~ /^\d{1,3}$/) && ($Integer2 <=352) && ($Integer2 >=0) && ($Integer2 =~ /^\d{1,3}$/))
	{
		$AddInt = $Integer1 + $Integer2;
		$MinusInt = $Integer1 - $Integer2;
		$MultiInt = $Integer1 * $Integer2;
		$DivInt = $Integer1/$Integer2;

		print "Add: $AddInt, Minus: $MinusInt, Multiple: $MultiInt, Divide: $DivInt\n";
	}
	
	else
	{
		&Invalid ("Integer1:".$Integer1."and Integer2:".$Integer2);
	}
	
	
}

sub Invalid
{
	my ($Int)= shift;
	$AddInt = "-";
	$MinusInt = "-";
	$MultiInt = "-";
	$DivInt = "-";
	my $Msg = MainWindow ->new ();
	$Msg ->Toplevel (-title=>'Warning');
	$Msg->Label (-font=>30, -background=>'green',-text=>"Data Entered:".$Int." invalid")->pack;
	MainLoop();
	
}

