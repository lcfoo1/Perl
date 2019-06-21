
my $XMLFile = 'LFD_ES2_AVID_LGA.xml';
my @Flows = (1, 2);
open (XML, $XMLFile) || die "Cant open $XMLFile : $!\n";
while (<XML>)
{
	if (/\<attribute\s+name\s*=\s*\"\S+_5\"\>\S*\<\/attribute\>/)
	{
		#print $_;
	}
	elsif (/\<attribute\s+name\s*=\s*\"\S+_6\"\>\S*\<\/attribute\>/)
	{
		#print "$_\n";
	}
	else
	{
		print $_;
	}


}
close XML;
