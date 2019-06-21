#!/usr/intel/bin/perl
#########################################################################################################
#													#
#	Foo Lye Cheung					PDE CPU OAP (TMM)				#
#	17 Jan 2006											#
#	604-2536452											#
#													#
#	This script is to read SigCtl setup file and decode the pattern for switch signature from	#
#	pattern file											#
#													#
#	Usage: $0 [-h] [-p pattern] [-s Setup_File] [-f Pattern_File] 					#
#	-h        	: this (help) message								#
#	-p pattern	: input file must be pattern mode						#
#	-f Pattern_File	: file containing vectors (pattern file)					#
#	-s Setup_File	: SigCtl decode setup file (pins, vector cycles, pattern labels start & stop)	#
#	Example: $0 -p pattern -s Setup_File -f Pattern_File						#
#	   												#
#	Rev 0.0												#
#													#
#########################################################################################################

# Global variables declare here
my @AllPinsPos = ();
my @AllPinsPos2 = ();
my @FoundPins = ();
my $Pins = "TMS";
my $Vector = 1;
my $InputFile1 = 'd0750863H003045_010604c_MB0548aj_0fxxxx0xhhcx0xxxxxPfrxM5_dft_idcode_OBR1.pat.data';
my $InputFile2 = 'd0651829H003045_010604c_MB0548aj_0fxxxx0xhhcx0xxxxxFfrxI5_dft_idcode_OBR1.pat.data';
my $Pattern_Start = 0;

#my ($Pins, $InputFile1, $InputFile2) = @ARGV;

my ($File1,$Bits1s2,$File2,$Bits2s2) = &ComPat($InputFile1, $InputFile2);
&Compare($File1,$Bits1s2,$File2,$Bits2s2);

sub Compare 
{
	my ($File1,$Bits1s2,$File2,$Bits2s2) = @_;

	my @Bits1s2s = split (/,/, $Bits1s2);
	my @Bits2s2s = split (/,/, $Bits2s2);

	for ($i=0; $i<=$#Bits2s2s; $i++)
	{
		my @Bit1 = split (/_/, $Bits1s2s[$i]);
		my @Bit2 = split (/_/, $Bits2s2s[$i]);

		if ($Bit1[0] eq $Bit2[0])
		{
			print "Same $Bit1[0] at $Bit1[1], $Bit2[0] at $Bit2[1]\n";
		}
		else
		{
			print "Diff $Bit1[0] at $Bit1[1], $Bit2[0] at $Bit2[1]\n";
		}
	}
}

# Signature search from pattern file
sub ComPat
{
	my ($File, $File2) = @_;
	my @Headers = ();
	my @Headers2 = ();
	my $HeaderFlag = 0;
	my $StrLenMax = 0;
	my @BitArray = ();
	my @BitArray2 = ();

	# Get the header of the pattern file
	open (IN, $File) || die "Cant open $File : $!\n";
	while (<IN>)
	{
		chomp;
		if (/#/)
		{
			my $TmpLen = length ($_);
			$StrLenMax = $TmpLen if ($StrLenMax < $TmpLen);
			if (($_ =~ /VMLI/) || ($_ =~ /VCF/))
			{
				#push (@Headers, $_);
				#print "$_\n";
			}
			else
			{
				push (@Headers, $_);
				print "$_\n";
			}
		}
	
		if (($_ !~ /#/) && ($. >10))
		{
			#exit;
			print "Start line $File data $.\n";
			$Pattern_Start = $.;
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
			
		if ($. > $Pattern_Start)
		{
			until (/^EXIT/)
			{
				chomp;

				my $Tmp1 = $_;
				$_ = <IN>;
				my @Addr1s = split(/#/, $_);
				my $Addr1 = $Addr1s[3];
				
				my @Bits = split (//, $Tmp1);
				foreach $Pos (@AllPinsPos)
				{
					next if (($Bits[$Pos] eq "") && ($Addr1 eq ""));
					$BitArray[$Pos][$cnt] = $Bits[$Pos] . "_" . $Addr1 . ",";
					$cnt++;
				}
							
			}


			for ($j = 0; $j <= $Vector*2; $j++)
			{
				chomp;
				my $Tmp1 = $_;

				$_ = <IN>;
				my @Addr1s = split(/#/, $_);
				my $Addr1 = $Addr1s[3];

				my @Bits = split (//, $Tmp1);
				foreach $Pos (@AllPinsPos)
				{
					next if (($Bits[$Pos] eq "") && ($Addr1 eq ""));
					$BitArray[$Pos][$cnt] = $Bits[$Pos] . "_" . $Addr1 ;

					$Okcnt = $cnt++;
				}
			}

			my $PinCnt = 0; 	
			for ($PinCnt = 0; $PinCnt <= $#AllPinsPos; $PinCnt++)
			{
				my $Pos = $AllPinsPos[$PinCnt];
				my $Bits1 = "";
				for ($j = 0; $j <= $Okcnt; $j++)
				{
					$Bits1 .= $BitArray[$Pos][$j];
					$Bits1 =~ s/\s//g;
				}
				$Bits1s1 = $Bits1;	
			}
		}
	}
	close IN;

	#exit;

	print "In $File2\n";
	open (IN, $File2) || die "Cant open $File2 : $!\n";
	while (<IN>)
	{
		chomp;
		if (/#/)
		{
			my $TmpLen = length ($_);
			$StrLenMax = $TmpLen if ($StrLenMax < $TmpLen);
			push (@Headers2, $_);
		}
	
		if (($_ !~ /#/) && ($. >10))
		{
			print "Start line $File2 data $.\n";
			$Pattern_Start = $.;
			&GetPin2($StrLenMax, @Headers2);		
			last;
		}
	}
	close IN;


	# Process the pattern file and get the bits	
	open (IN, $File2) || die "Cant open $File2 : $!\n";
	while (<IN>)
	{
		chomp;
		my $cnt = 0;
			
		if ($. > $Pattern_Start)
		{
			until (/^EXIT/)
			{
				chomp;

				my $Tmp2 = $_;
				$_ = <IN>;
				my @Addr2s = split(/#/, $_);
				my $Addr2 = $Addr2s[3];
				
				my @Bits = split (//, $Tmp2);
				foreach $Pos (@AllPinsPos2)
				{
					next if (($Bits[$Pos] eq "") && ($Addr2 eq ""));
					$BitArray2[$Pos][$cnt] = $Bits[$Pos] . "_" . $Addr2 . ",";
					$cnt++;
				}

			}

			for ($j = 0; $j < $Vector*2; $j++)
			{
				my $Tmp2 = $_;

				$_ = <IN>;
				my @Addr2s = split(/#/, $_);
				my $Addr2 = $Addr2s[3];

				my @Bits = split (//, $Tmp2);
				foreach $Pos (@AllPinsPos2)
				{
					next if (($Bits[$Pos] eq "") && ($Addr2 eq ""));
					$BitArray2[$Pos][$cnt] = $Bits[$Pos] . "_" . $Addr2 ;

					$Okcnt = $cnt++;
				}
			}
			for ($PinCnt = 0; $PinCnt <= $#AllPinsPos2; $PinCnt++)
			{
				my $Pos = $AllPinsPos2[$PinCnt];
				my $Bits2 = "";
				for ($j = 0; $j <= $Okcnt; $j++)
				{
					$Bits2 .= $BitArray2[$Pos][$j];
					$Bits2 =~ s/\s//g;
				}
				$Bits2s1 = $Bits2;
			}
		}
	}
	
	return ($File1,$Bits1s1,$File2,$Bits2s1);
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

		$Pin =~ s/\s+//;
		print "$Pin\n";
		
		if ($Pin =~ /^($Pins)$/i)
		{
			push (@FoundPins, $Pin);
			push (@AllPinsPos, $Pos);
			my $TmpPos1 = $Pos;
		}
	}
	print "Detected at column $TmpPos1\n" if ($TmpPos1 ne "");
}

# Subroutine to get the pin position from pattern file
sub GetPin2
{
	my ($StrLenMax, @Headers2) = @_;
	my @Tables2 = ();
	my $cnt = 0, $Pos2 = 0, $i = 0; $j = 0;

	foreach $Line (@Headers2)
	{
		chomp ($Line);
		my @Data = split(//, $Line);
		for ($i = 0; $i <= $#Data; $i++)
		{
			chomp ($Data[$i]);
			next if ($Data[$i] eq "");
			$Tables2[$i][$cnt] = $Data[$i];
		}
		$cnt++;
	}

	for ($Pos2 = 0; $Pos2 <= $StrLenMax; $Pos2++)
	{
		my $Pin2 = "";
		for ($j = 0; $j <=$cnt; $j++)
		{
			$Pin2 .= $Tables2[$Pos2][$j];
			$Pin2 =~ s/\s//g;
		}

		$Pin2 =~ s/\s+//;
		if ($Pin2 =~ /^($Pins)$/i)
		{
			push (@FoundPins2, $Pin2);
			push (@AllPinsPos2, $Pos2);
			my $TmpPos2 = $Pos2;
		}
	}
	print "Detected at column $TmpPos2\n" if ($TmpPos2 ne "");
}

