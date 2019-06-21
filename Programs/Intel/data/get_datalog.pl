#!/usr/intel/pkgs/perl/5.8.5/bin/perl

my $InFile = $ARGV[0];
my $OutFile = $InFile . "_out.csv";
my $Flag = $ARGV[1];
my %Parameters = ();
&ReadParameters();
&Process($InFile, $OutFile);

sub ReadParameters
{
	my $ConfigParam = 'parameter.txt';
	open (CONFIG, $ConfigParam) || die "Cant open $ConfigParam : $!\n";
	while (<CONFIG>)
	{
		chomp;
		my ($MatchStr, $Value) = split (/:/, $_);
		my @Items = split (/\,/, $MatchStr);
		my $MatchStr = join ('\w*', @Items); 
		$Parameters{$MatchStr} = $Value;
	}
	close CONFIG;
}

sub Process
{
	my ($Datalog, $OutFile) = @_;
	my ($Cnt, $UnitFlag) = (0, 0);
	my ($Header, $Data) = ();
	my ($PrtName, $SoftBin, $VisualID) = ();

	open (OUT, ">$OutFile") || die "Cant open output $OutFile : $!\n";
	open (DATALOG, $Datalog) || die "Cant open datalog $Datalog : $!\n";
	while (<DATALOG>)
	{
		s/(\r|\n)//g;


		foreach my $Line (keys %Parameters)
		{
			if (/$Line/)
			{
				s/(\r|\n)//g;
				s/\S+tname_($Line)/$1/g;
				$Header .= $_ . ',';
				do
				{
					$_ = <DATALOG>;
					s/(\r|\n)//g;
				} while ($_ !~ /$Parameters{$Line}/);
				s/$Parameters{$Line}\_(\S+)$/$1/g;
				$Data .= $_ . ',';
			}
		}
	}
	close DATALOG;
	print "$Header\n";
	print OUT "$Header\n";
	print OUT "$Data\n";

	close OUT;
}
