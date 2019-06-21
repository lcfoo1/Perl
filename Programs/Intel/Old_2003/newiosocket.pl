#########################################################################
#									#
#	Foo Lye Cheung							#
#									#
#	This script will listen to the network and read the port 	#
#	through TCP protocol						#
#									#
#########################################################################

use IO::Socket;
use IO::Select;
use Socket;
use strict;
use warnings;

&ListenSocket();

sub ListenSocket
{
	my $Port = 6000;
	my $LocalAddr = '172.30.69.202';
	my $Protocol = 'udp';
	my $Socket = IO::Socket::INET->new (LocalAddr => $LocalAddr, LocalPort => $Port, Proto => $Protocol);
	#my $Socket = IO::Socket::INET->new (LocalAddr => $LocalAddr, LocalPort => $Port, Proto => $Protocol, Listen => 5);
	my $InputLine;
	die "Can't create server socket: $!" unless $Socket;
	print "Listening for connections on port $Port\n";

	my $Readable = IO::Select->new;
	$Readable->add($Socket);

	while (1)
	{
		my ($Ready) = IO::Select->select($Readable, undef, undef, undef);
		foreach my $LSocket (@$Ready)
		{
			if($LSocket == $Socket)
			{
				my $NewSocket = $Socket->accept;
				$Readable->add($NewSocket) if $NewSocket;
				#print STDERR ("Accepted connection from: ", join('.', (unpack('C*', $NewSocket->peername))[4..7]), "\n");
			}
			else
			{
				no warnings;
				my $Buffer = <$LSocket>;
				if ($Buffer ne "")
				{
					chomp($Buffer);
					if ($Buffer == 1)
					{
					print "u r 1\n";
					}
					elsif ($Buffer == 2)
					{
						print "u r 2\n";
					}
					print "Data: $Buffer\n";
				}
				else
				{
					$Readable->remove($LSocket);
					$LSocket->close;
					print STDERR "Client Connection closed\n";
				}
			}
		}
	}
}

