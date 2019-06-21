#########################################################################################
use Net::Telnet;

my @Servers = ("t3admin6.png.intel.com");

foreach my $Server(@Servers)
{
	&GetFilesFromUnix($Server);
}

sub GetFilesFromUnix
{
	# Variable declaration
	my $Server = shift;
	my $RemoteDir = '/intel';
	my $User = 't3strm0';
	my $Pwd = 't3strm0';
	my $Prompt = 'lcfoo';

	# Get connectivity to Unix port
	my $Unix = new Net::Telnet (Timeout => 60, Prompt => '/[%#>] $/'); 
	$Unix->open($Server);
	$Unix->login($User, $Pwd);
	print "Connected to $Server\n";

	# Clear out the prompt the prints itself 
	$Unix->prompt("/$Prompt\$/");
	$Unix->cmd("set prompt = '$Prompt'");

	# Get a list of the files
	$Unix->cmd("cd $RemoteDir");
	my @List = $Unix->cmd("ls -l");
	
	foreach my $Line(@List)
	{
		chomp $Line;
		print "$Line\n";
	}
	$Unix->close;
}
