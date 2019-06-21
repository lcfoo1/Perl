
use IO::Socket;
use strict;
use warnings;

&SendSocket();

sub SendSocket
{
	my $PeerAddr = '1.0.0.1';
	my $PeerPort = 6000;
	my $Protocol = 'tcp';

	my $Socket = new IO::Socket::INET (PeerAddr => $PeerAddr, PeerPort => $PeerPort, Proto => $Protocol);
	die "Can't open socket: $!" unless $Socket;

	my $File = "C:\\Perl\\Programs\\Test.txt";
	my $Line ="";
	open (FILE, $File) || die "Can't open $File : $!";
	while (<FILE>)
	{
		$Line .= $_;
	}

	print "$Line\n";
	my $Bytes = send $Socket, $Line, 0;
	print "Characters: $Bytes\n";
}

