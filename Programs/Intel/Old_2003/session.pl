use Win32::Net::Session;

my $server = $ARGV[0];
my $level = 3;
my $SESS = Win32::Net::Session->new($server, $level);
my $ret = $SESS->GetSessionInfo();
my $numsessions = $SESS->NumberofSessions();

if($numsessions == 0) 
{
	print "No Clients connected\n"; 
	exit; 
}

print "Number of Sessions: " . $numsessions . "\n";
my %hash = %$ret;
my $key;
my $count=0;


while($count < $numsessions)
{
	my %h = %{$hash{$count}};
	print "The key: $count\n";
	foreach $key (keys %h)
	{
		print "$key=" . $h{$key} . "\n";
	}
	print "\n";
	$count++;
}
