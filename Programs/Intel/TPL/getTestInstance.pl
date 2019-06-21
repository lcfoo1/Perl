
my $File = 'ktfdtbzb0mc11xbx.tpl';
my $OutFile = '>ktfdtbzb0mc11xbx.tpl.csv';
my %TestTemplate = ();
open (OUT, $OutFile) || die "Cant open $OutFile : $!\n";
open (FILE, $File) || die "Cant open $File : $!\n";
while (<FILE>)
{
	chomp;
	if (/Test\s+(iC\w+)\s+(\w+)/)
	{
		#Test iCBkgndTest StartTime
		$TestTemplate{$2} = $1;
	}
	
	if(/Flow\s+/)
	{
		my $String = "";
		my $Flag = 0;
		my $i = 0;
		while (<FILE>)
		{
			#FlowItem StartTime_eos0 StartTime	# File:convention.pln Line:46
			if (/FlowItem\s+(\w+)\s+(\w+)/)
			{
				my $TTemplate = $2;
				my $TestInstance = $1;
				$String = "$TestTemplate{$TTemplate},$TTemplate,$TestInstance,";
			}
			if (/Result\s+(\S+)/)
			{
				$i = 0;
				my $Port = $1;
				$String .= "$Port,";
			}

			if (/\}/)
			{
				$i++;
				print OUT "$String\n" if ($i == 2);

			}
		}
	}

}
close FILE;
close OUT;

