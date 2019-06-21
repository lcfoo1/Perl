my $Path = 'I:\hdmtpats\chv\17x17\MSCAN\RevCHVA0\p';#4\pat\indv_pat';


#open (IN, "C:\\Perl\\Programs\\GENLC\\SCAN_GENLC.plist") || die "Cant open plist file : $!";
open (IN, "C:\\Perl\\Programs\\GENLC\\Test.txt") || die "Cant open plist file : $!";
while (<IN>)
{
	#if (/Pattern\s+(\w+)\;/)
	#{
	#	my $Pattern = $1 . "*.*";
	#	print "$1\n";

	#	for ($i=0; $i <4;$i++)
	#	{

	#		my $NewPattern = $Path . $i . '\pat\indv_pat'. "\\$Pattern";
	#		my $New = 'C:\Perl\Programs\GENLC\original' . "\\$Pattern";
	#		$New = 'C:\Perl\Programs\GENLC\original';
	#		system ("copy $NewPattern $New");
	#	}
	#}

	my $Pattern = $_;
	chomp ($Pattern);

	my $Cmd = "dir\/s\/w I:\\hdmtpats\\chv\\17x17\\MSCAN\\RevCHVA0\\p1\\pat\\" . $Pattern . "*.*";
	#print "$Cmd\n";
	@Files = qx/$Cmd/;
	foreach my $File (@Files)
	{
		#print $File . "\n";
		if (/d/)
		{
			push (@MyFiles,	$File);
		}
	}
	@Files = ();

	foreach my $File (@MyFiles)
	{
		print $File . "\n";
	}

	#for ($i=0; $i <4;$i++)
	#{

		#my $NewPattern = $Path . $i . '\pat\indv_pat'. "\\$Pattern*.*";
		#my $New = 'C:\Perl\Programs\GENLC\original';
		#print "copy $NewPattern $New";
		#	exit;
		#system ("copy $NewPattern $New");
		#}


}
close IN;

