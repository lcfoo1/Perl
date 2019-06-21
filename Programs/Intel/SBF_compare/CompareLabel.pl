#!/usr/intel/bin/perl

# Global variables declare here
my @AllPinsPos = ();
my @FoundPins = ();
my $Pins = "";
my @PLabel = ();
my $Vector = 0;
my $InputFile = "";
my $SetupFile = 'SigCtlSetup.txt';
&ReadSetupFile($SetupFile);
&CompareLabel($InputFile);

# Read input setup file
sub ReadSetupFile
{
	my $SetupFile = shift;
	open (SETUP, $SetupFile) || die "Cant open setup file $SetupFile : $!\n";
	while (<SETUP>)
	{
		if (/PIN=(\S+)/)
		{
			$Pins = $1;
		}
		elsif (/PATTERN=(\S+)/)
		{
			$InputFile = $1;
		}
		elsif (/PLABEL=(\S+)/)
		{
			my ($StartPlabel, $EndPlabel) = split (',', $1);
			push @PLabel, $StartPlabel, $EndPlabel;
		}
	}
}

sub CompareLabel
{
	my $File = shift;
	my @Headers = ();
	my $HeaderFlag = 0;
	my $StrLenMax = 0;

	print "Pattern File: $File\n";

	# Get the header of the pattern file
	open (IN, $File) || die "Cant open $File : $!\n";
	while (<IN>)
	{
		chomp;
		if (/#/)
		{
			my $TmpLen = length ($_);
			$StrLenMax = $TmpLen if ($StrLenMax < $TmpLen);
			push (@Headers, $_);
		}
	
		if (($_ !~ /#/) && ($. >10))
		{
			&GetPin ($StrLenMax, @Headers);		
			last;
		}
	}
	close IN;
	
	# Process the pattern file and get the bits	
	open (IN, $File) || die "Cant open $File : $!\n";
	while (<IN>)
	{
		chomp;
		my $cnt = 0;
		my @BitArray = ();
		my ($StartLbl, $EndLbl) = ("","");
			
		for ($i = 0; $i < $#PLabel; $i++)
		{
			if (/$PLabel[$i]/)
			{
				$StartLbl = $_;
				$i++;
				until (/$PLabel[$i]/)
				{
					chomp;
					my @Bits = split (//, $_);
					foreach $Pos (@AllPinsPos)
					{
						$BitArray [$Pos][$cnt] = $Bits[$Pos];
						$cnt++;
					}
					$_ = <IN>;
				}
				$EndLbl = $_;

				# Offset for end label data
				for ($j = 0; $j <= $Vector*2; $j++)
				{
					chomp;
					my @Bits = split (//, $_);
					foreach $Pos (@AllPinsPos)
					{
						$BitArray [$Pos][$cnt] = $Bits[$Pos];
						$cnt++;
					}
					$_ = <IN>;
				}
					
				my $PinCnt = 0; 	
				print "Start label: $StartLbl\nEnd label: $EndLbl\n";
				for ($PinCnt = 0; $PinCnt <= $#AllPinsPos; $PinCnt++)
				{
					my $Pos = $AllPinsPos[$PinCnt];
					print "$FoundPins[$PinCnt] $AllPinsPos[$PinCnt]\n";
					my $Bits = "";
					for ($j = 0; $j <= $cnt; $j++)
					{
						$Bits .= $BitArray[$Pos][$j];
						$Bits =~ s/\s//g;
					}

					print "$Bits\n";
				}
			}
		}
	}
	close IN;
}

# Subroutine to get the pin position from pattern file
sub GetPin
{
	my ($StrLenMax, @Headers) = @_;
	my @Tables = ();
	my $cnt = 0, $Pos = 0, $i = 0; $j = 0;

	foreach $Line (@Headers)
	{
		my @Data = split(//, $Line);
		for ($i = 0; $i <= $#Data; $i++)
		{
			$Tables[$i][$cnt] = $Data[$i];
		}
		$cnt++;
	}

	for ($Pos = 0; $Pos <= $StrLenMax; $Pos++)
	{
		my $Pin = "";
		for ($j = 0; $j <=$cnt; $j++)
		{
			$Pin .= $Tables[$Pos][$j];
			$Pin =~ s/\s//g;
		}

		if ($Pin =~ /^($Pins)$/)
		{
			push (@FoundPins, $Pin);
			push (@AllPinsPos, $Pos);
		}
	}
}
