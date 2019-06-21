 use Net::SSH::Perl;
$host = 'pgsw4017.png.intel.com';
$cmd = 'ls -l';
    my $ssh = Net::SSH::Perl->new($host);
    $ssh->login;
    my($READ, $WRITE) = $ssh->open2($cmd);
    print $WRITE "foo\n";
    sysread $READ, my($data), 0, 8192;
    print "Got $data\n";
