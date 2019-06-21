
my %TestNames = ();
my $SourceDir = 'C:/test/';
my $Now = &FormatNow();
#my $OutputDir = 'C:/test/output_' . $Now . '/';
my $OutputDir = 'C:/test/output/';

#&ProcessCSV();
&ComputePat();
&DisplayLog();

sub ProcessCSV
{
	mkdir $OutputDir || die "Cant create dir $OutputDir : $!\n";

	chdir $SourceDir || die "Cant change dir $SourceDir : $!\n";

	foreach my $DataFile (<*.csv>)
	{
		my $TestNames = ();
		print "Processing $DataFile ...\n";
		open (DATAFILE, $DataFile) || die "Cant open data file $DataFile :$!\n";
		while (<DATAFILE>)
		{
			chomp;
			s/"//g;
			if ($. == 1)
			{
				print;
				@TestNames = split (/\,/, $_);
			}
			else
			{
				@Line = split (/\,/, $_);
				for ($i = 0; $i <= $#TestNames; $i++)
				{
					my $OutputFile = $OutputDir . $TestNames[$i] . ".txt";
					open (OUTPUT, ">>$OutputFile") || die "Cant open $OutputFile :$!\n";
					print OUTPUT "$Line[$i]\n" if ($Line[$i] ne "");
					close OUTPUT;		
				}
			}
		}
		close DATAFILE;
		print "Finish processing $DataFile ...\n";
	}
}


sub FormatNow
{
	my $Now = time();
	my ($ss, $mi, $hh, $dd, $mm, $yyyy) = localtime($Now);
	
	$yyyy += 1900;
	$mm++;
	$mm =~ s/^(\d)$/0$1/;
	$dd =~ s/^(\d)$/0$1/;
	$hh =~ s/^(\d)$/0$1/;
	$mi =~ s/^(\d)$/0$1/;
	$ss =~ s/^(\d)$/0$1/;

	return("${mm}${dd}${yyyy}_${hh}${mi}${ss}");
}

sub ComputePat
{
	chdir $OutputDir || die "Cant change $OutputDir : $!\n";

	foreach my $File (<*.txt>)
	{
		print "Processing $File ...\n";
		my $Test = $1 if ($File =~ /(\w+).txt$/);
		open (OUT, $File) || die "Cant open $File : $!\n";
		while (<OUT>)
		{
			chomp;
			$TestNames{$Test}{$_}++;
		}
		close OUT;
	}
}


sub DisplayLog
{
	my $ResultDir = $OutputDir . "/Log/";
	mkdir $ResultDir || die "Cant create log dir $ResultDir : $!\n";

	my $ResultLog = $ResultDir . "Summary.log";
	open (RESULTLOG, ">$ResultLog") || die "Cant open $ResultLog :$!\n";
	foreach my $Test (keys %TestNames)
	{
		my $SingleTest = $ResultDir . $Test . ".txt";
		print "Printing $Test ...\n";

		open (SINGLETEST, ">$SingleTest") || die "Cant open $SingleTest : $!\n";
		print RESULTLOG "Testname: $Test\n";
		foreach my $Pat (sort keys %{$TestNames{$Test}})
		{
			print RESULTLOG "$TestNames{$Test}{$Pat}\t$Pat\n";
			print SINGLETEST "$TestNames{$Test}{$Pat}\t$Pat\n";
		}
		print RESULTLOG "\n";
		close SINGLETEST;

		print "Finish printing $Test ...\n";
	}
	close RESULTLOG;
}
