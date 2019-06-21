#########################################################################
#									#
#	Foo Lye Cheung		NCO PDQRE Automation			#
#	06/24/2004							#
#									#
#	This script runs under scheduler task and ftp wafermap files	#
#	to F14. Upon successful uploading the wafermap, the original 	#
#	files will renamed as .old					#
#									#
#	NOTES:								#
#	Requries Perl 5							#
#									#
#########################################################################

use strict;
use warnings;
use Net::FTP;

# FTP  signal file to DataBroker
&GetFiles();

sub GetFiles
{
        my $Server = '172.30.208.142'; 
	my ($ID, $PWD) = ("lfoo1", "abc123");

        my $FTP = Net::FTP->new($Server) or die "Can't connect to $Server\n";
        $FTP->login($ID,$PWD) or die "Sorry can't connect as user $ID\n";
	#$FTP->cwd($RemoteDir);

        my @Files = $FTP->ls();
        $FTP->quit;
        undef $FTP;

	&DisplayFiles(@Files);
}

sub DisplayFiles
{
	my @Files = @_;
	
	foreach my $File (@Files)
	{
		print "File:: $File\n";
	}

}
