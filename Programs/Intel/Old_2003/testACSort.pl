#use strict;
#use warnings;
use Net::FTP;
use Net::Telnet;

&ChkTmpItuff();
&FTPToS9K();

sub ChkTmpItuff()
{
	my $ItuffDir = "C:\\test_data_sort\\ituff\\";
	chdir $ItuffDir || die "Cannt open $ItuffDir : $!\n";

	

	

}

sub FTPToS9K
{
	#my $Server = 't3admin6.png.intel.com';	
	#my $ID = 's3strm5';
	#my $PWD = 's3strm5';
	
	my $Server = 'lfoo1-mobl';	
	my ($ID, $PWD) = ("lcfoo", "secureftP!!");
	my $FTP = Net::FTP->new($Server);
	$FTP->login($ID, $PWD);
	$FTP->cwd($RemoteDir);
	$FTP->quit;
}

my $RemoteDir =  '/db1/s9k/sort/s9kaccess/sort/datalogs';
my $SignalDir = '/db1/s9k/sort/s9kaccess/sort/signal';
my $AriesSig = '/db1/s9k/sort/aries/signal/ituff';
my $LocalDir = 'C:\test_data_sort\ituff';
my $FTPLog = '>>C:\test_data_sort\FTP.log';
