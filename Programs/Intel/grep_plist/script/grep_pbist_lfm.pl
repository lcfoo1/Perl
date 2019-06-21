#########################################################################
# 									#
# 	Foo Lye Cheung				06 December 2006	#
# 	PDE DPG CPU Penang Malaysia					#
# 									#
# 	Script to crunch pbist lfm from dap files			#
#									#
#	Notes:								#
#	1. Original dap files are placed at dap folder			#
#	2. Execute the scripts 						#
#	   								#
#########################################################################
use warnings;
use strict;
use Cwd;

# Main global and main code start here
my $Dir = getcwd;
my $DAPDir = $Dir . '/../dap/';
my (%OtherTestNames, %CacheLFMs, %CacheTimings) = ();

opendir(DIR, $DAPDir) || die "Cant opendir $DAPDir: $!";
my @DAPs = grep { $_ !~ /dapmap\.bins/ && $_ !~ /output/ && /\.bins/ && -f "$DAPDir/$_" } readdir(DIR);
closedir DIR;

foreach my $DAP (@DAPs)
{
	my $DAPFile = $DAPDir . $DAP;
	&Main($DAPFile);
	(%OtherTestNames, %CacheLFMs, %CacheTimings) = ();
}

# Main program starts here
sub Main
{
	my $DAPFile = shift;
	my $DAPOut = $DAPFile . "_output.csv";
	my $Flag = 0;
	
	open (IN, $DAPFile) || die "Cant open $DAPFile : $!\n";
	while (<IN>)
	{
		chomp;
		#S1_Flow1_23, pbistl1_0118c_min1482667_0103, -1, b9803_test_Class_error, n9803_test_Class_error, itmh_bin_map, NOCHANGE
		if (/S\w+_Flow\w*_\d+\s*\,\s*(\w+_\d{4})\s*\,\s*.*/)
		{		
			my $TestName = $1;
			if ($TestName =~ /.*pbist.*lfm.*\_(\d{2})(\d{2})$/ig)
			{				
				$CacheLFMs {$TestName} = "$1 $2" ;
			}
			else
			{
				$OtherTestNames{$TestName} = "1";
			}
		}
	}
	close IN;

	# Uniquely store the cache lfm timing
	foreach my $CacheLFM (keys %CacheLFMs)
	{
		my ($Timing, $Level) = split (/\s+/, $CacheLFMs{$CacheLFM});
		$CacheTimings{$Timing} .= "," . $CacheLFM;
		$Flag = 1;
	}

	if ($Flag)
	{
		open (OUT, ">$DAPOut") || die "Cant open $DAPOut : $!\n";
	
		# Search cache lfm timing in other test segements
		foreach my $CacheTiming (keys %CacheTimings)
		{
			print OUT "Timing cat${CacheTiming}${CacheTimings{$CacheTiming}}";
			foreach my $OtherTestName (keys %OtherTestNames)
			{
				if ($OtherTestName =~ /.*\_${CacheTiming}\d{2}$/ig)
				{
					print OUT "$OtherTestName\n";			
				}		
			}
		}
		close OUT;
	}
}
