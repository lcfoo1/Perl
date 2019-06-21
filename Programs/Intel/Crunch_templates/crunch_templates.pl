

my $File = 'evergreen_gen_tt_templates_release_result.txt';
#5>------ Rebuild All started: Project: OASIS_cmemDecode_tt, Configuration: Release Win32 ------
my @Files = ();
open (FILE, $File) || die "Cant open $File : $!\n";
while (<FILE>)
{
	chomp;
	if (/Rebuild.*Project:\s*(\w+)\s*\,\s*Configuration.*/io)
	{
		push (@Files, $1);
	}
}
close FILE;


foreach my $List (sort @Files)
{
	print "$List\n";
}
