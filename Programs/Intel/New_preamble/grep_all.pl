
use File::Find;

my $Debug = 1;
my $Dir = '/nfs/png/disks/png_pdcpde_n16355/proj/nhm/tvpv01/eng/tvpv/pattern_releases/cmtpats/lyn/RevA0CD/RevA0.0';
my @TPLFiles = ();
my %TestTemplates = ();
finddepth(\&GetTPLFiles, $Dir);
	
# Get all .plist files
sub GetTPLFiles
{
	if ((-f $File::Find::name) && ($File::Find::name =~ /Mscan\/plb/i) && (($File::Find::name =~ /\.plist$/i)))
	{
		my $File = $File::Find::name;
		$File =~ s/\\/\//g;
		print "Found $File\n" if ($Debug == 1);
		#print "Found $File\n" if ($File::Find::name =~ /\.txt$/i);
		push (@TPLFiles, $File);
	}
}

sub test
{
foreach my $File (<*.plist>)
{
	print "File: $File\n";
	my $Out = "out_" . $File . ".csv";
	open (OUT, ">$Out") || die "Cant open $Out : $!\n";
	open (FILE, $File) || die "Cant open $File : $!\n"; 
	while (<FILE>)
	{
		chomp;
		#if (/GlobalPList\s+(\w+)\s+.*(cwma_pre\w+)\s+.*/)
		if (/GlobalPList\s+(\w+)\s+.*(cwma_pre\w+)(\s+|\]).*/)
		{
			print "$1,$2\n";
			print OUT "$1,$2\n";
		}
	}
	close FILE;
	close OUT;
}
}
