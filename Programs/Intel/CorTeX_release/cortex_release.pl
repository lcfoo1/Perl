
my $Dir = 'C:\intel\Perl\Programs\CorTeX_release';
my $Org = $Dir . "\\original\\";
my $Mod = $Dir . "\\modified\\";

chdir $Org || die "Cant open $Org : $!\n";
foreach my $vcprog (<*.vcproj>)
{
	my $OrgFile = $Org . $vcprog;
	my $ModFile = $Mod . $vcprog;
	open (MOD, ">$ModFile") || die "Cant open $ModFile : $!\n";
	open (ORG, $OrgFile) || die "Cant open $OrgFile : $!\n";
	while(<ORG>)
	{
		chomp;
		#s/Rev3.7.0v8p0e1p4/Rev3.7.0v11e1/g;
		#s/Rev3.7.0v8p0e1p4/Rev3.7.0v8p0e1p5/g;
		s/Rev3.7.0v11p0e2p1/Rev3.7.0v11p0e3/g;
		print MOD "$_\n";
	}
	close ORG;
	close MOD;
}
