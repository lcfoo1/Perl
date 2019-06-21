#!/usr/local/bin/perl -w

#################################################################################
#										#
#	Foo Lye Cheung			Penang Sort Automation			#
#	03/28/2004								#
#	iNET - 36452								#
#										#
#										#
#	NOTE:									#
#										#
#	This script is going to run every month once for S9K tester.		#
#	The script is going to delete the temperorary Aries files		#
#	at /db1/s9k/sort/databroker/tmp/ and remain last 5 .found files and	#
#	.FIN files at /db1/s9k/sort/databroker/signal/				#
#										#
#	Rev 1.0									#
#										#
#################################################################################

my $TmpDirAries = "/db1/s9k/sort/databroker/tmp/";
my $FINDir = "/db1/s9k/sort/databroker/signal";

&CleanAriesTmp();
&CleanOldFIN();

sub CleanAriesTmp
{
	my %ListFile;
	my $count = 0;

	my @TmpFilesAries = glob ("$TmpDirAries*");

	foreach my $TmpFileAries (@TmpFilesAries)
	{
		$count++;
		$ListFile{(stat($TmpFileAries))[9]} = $TmpFileAries;
	}

	# Remain last 5 temperorary files at temperorary Aries directory
	my $Last5TmpCount = $count - 5;
	$count = 0;
	foreach my $TmpFileAries (sort keys %ListFile)
	{
		last if ($Last5TmpCount == $count);
		$count ++;
		print "Delete $ListFile{$TmpFileAries} ...\n";
		unlink "$ListFile{$TmpFileAries}" || die "Cannt delete $ListFile{$TmpFileAries} : $!\n";
	}

	print "Clean Aries tmp file finished: $TmpDirAries - The end\n";
}

sub CleanOldFIN
{
	chdir $FINDir || die "Cannt open $FINDir : $!\n";

	print "Deleting all .FIN files at $FINDir\n";
	unlink <*.FIN>; # || die "Cannt delete FIN files: $!\n";
}
