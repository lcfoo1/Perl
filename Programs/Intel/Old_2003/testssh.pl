
use Net::SSH::Perl;
$host = '172.30.75.70';
my $ssh = Net::SSH::Perl->new($host);
$ssh->login;

my($READ, $WRITE) = $ssh->open2($cmd);
print $WRITE "foo\n";
sysread $READ, my($data), 0, 8192;
print "Got $data\n";
