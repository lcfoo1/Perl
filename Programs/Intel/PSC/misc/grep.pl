
my $Dir = "C:\\Documents and Settings\\lfoo1\\Desktop\\revl0a5b_cclass_dt_PatchA\\main\\avator\\";
my $File = $Dir . "convention.pln";

open (FILE, $File) || die "Cant open the file $File : $!\n";
while (<FILE>)
{
	chomp;
	if (/Import/)
	{
		print "$_\n";
		while(<FILE>)
		{
			chomp;
			if (/INST/)
			{
				chomp;
				print "$_\n";
				while(<FILE>)
				{
					chomp;
					if (/TEMPLATE/)
					{
						print "$_\n";
						goto ENDL;
					}
				}
					
			}
		}
	}
	ENDL:
}
close FILE;
