#################################################################
# 								#
# 	Foo Lye Cheung				05 July 2005	#
# 	PDE DPG CPU Penang Malaysia				#
# 								#
# 	Crunch data for TTR based on Crystal Ball result	#
# 								#
#################################################################
use strict;
use warnings;
my %TestNames = ();

my $SourceDir = 'C:/Intel/Perl/Programs/CrystalBall/csv/';
my $Now = &FormatNow();
my $OutputDir = 'C:/Intel/Perl/Programs/CrystalBall/csv/output_' . $Now . '/';
#my $OutputDir = 'C:/Intel/Perl/Programs/CrystalBall/csv/output/';

&ProcessCSV();
&ComputePat();
&SumResult();

sub ProcessCSV
{
	mkdir $OutputDir || die "Can't create dir $OutputDir : $!\n";
	chdir $SourceDir || die "Can't change dir $SourceDir : $!\n";

	foreach my $DataFile (<*.csv>)
	{
		my @TNames = ();
		print "Processing $DataFile ...\n";
		open (DATAFILE, $DataFile) || die "Cant open data file $DataFile :$!\n";
		while (<DATAFILE>)
		{
			chomp;
			s/"//g;
			if ($. == 1)
			{
				print;
				@TNames = split (/\,/, $_);
			}
			else
			{
				my @Line = split (/\,/, $_);
				my $i = 0;
				for ($i = 0; $i <= $#TNames; $i++)
				{
					my $OutputFile = $OutputDir . $TNames[$i] . ".txt";
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

	foreach my $PatTestFile (<*.txt>)
	{
		print "Processing $PatTestFile ...\n";
		my $Test = $1 if ($PatTestFile =~ /(\w+).txt$/);
		open (PATTESTFILE, $PatTestFile) || die "Cant open $PatTestFile : $!\n";
		while (<PATTESTFILE>)
		{
			chomp;
			$TestNames{$Test}{$_}++;
		}
		close PATTESTFILE;
	}
}

sub SumResult
{
	my $ResultDir = $OutputDir . "/Result/";
	mkdir $ResultDir || die "Cant create result dir $ResultDir : $!\n";

	my $Result = $ResultDir . "Summary.log";
	open (RESULT, ">$Result") || die "Cant open $Result :$!\n";
	foreach my $Test (keys %TestNames)
	{
		my $SingleTest = $ResultDir . $Test . ".txt";
		print "Printing $Test ...\n";

		open (SINGLETEST, ">$SingleTest") || die "Cant open $SingleTest : $!\n";
		print RESULT "Testname: $Test\n";
		foreach my $Pat (sort keys %{$TestNames{$Test}})
		{
			print RESULT "$TestNames{$Test}{$Pat}\t$Pat\n";
			print SINGLETEST "$TestNames{$Test}{$Pat}\t$Pat\n";
		}
		print RESULT "\n";
		close SINGLETEST;

		print "Finish printing $Test ...\n";
	}
	close RESULT;
}
