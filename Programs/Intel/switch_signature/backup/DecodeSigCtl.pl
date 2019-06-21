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
use Getopt::Std;

# Global variables declare here
my @AllPinsPos = ();
my @FoundPins = ();
my $Pins = "";
my @PLabel = ();
my $Vector = 0;
my ($sig_now, $sig_ads, $sig_bp3, $sig_maskbp3, $X1mux, $X2mux, $sec_chain, $master_checker,$A1mux,$A2mux, $A3mux, $A4mux, $A5mux,	$A6mux,	$A7mux,	$A8mux,	$B1mux,	$B2mux,	$B3mux,	$B4mux,	$B5mux,	$B6mux,	$B7mux,	$B8mux,	$C1mux,	$C2mux,	$C3mux,	$C4mux,	$C5mux,	$C6mux,	$C7mux,	$C8mux,	$T1_0mux,$T1_1mux, $T2_0mux, $T2_1mux) = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
my %opt=();

# Program starts here
getopts("f:hp:s:", \%opt ) or Usage();
&Usage() if defined ($opt_h || $opt{h});

my $InputFile = $opt_f || $opt{f};
my $SetupFile = $opt_s || $opt{s};
my $Mode = $opt_p || $opt{p};

print "Please check you input filename ($InputFile or $SetupFile)\n";

if (defined $InputFile)
{
	if (defined $SetupFile)
	{
		if (($Mode eq "pattern") && (-e $InputFile) && (-e $SetupFile))
		{
			&ReadSetupFile($SetupFile);
			&SignatureSearch($InputFile);
		}
		else
		{
			print "Please check you input filename ($InputFile or $SetupFile)\n";
		}
	}
	else
	{
		&Usage();
	}
}
else
{
	&Usage();
}

# Read input setup file
sub ReadSetupFile
{
	my $SetupFile = shift;
	print "Setup file: $SetupFile\n";

	open (SETUP, $SetupFile) || die "Cant open setup file $SetupFile : $!\n";
	while (<SETUP>)
	{
		if (/PIN=(\S+)/)
		{
			$Pins = $1;
		}
		elsif (/VECTOR=(\d+)/)
		{
			$Vector = $1;
		}
		elsif (/PLABEL=(\S+)/)
		{
			my ($StartPlabel, $EndPlabel) = split (',', $1);
			push @PLabel, $StartPlabel, $EndPlabel;
		}
	}
	
}
 
# Help message of the usage
sub Usage
{
	my $Help = "\nHelp:\n=====
Usage: $0 [-h] [-p pattern] [-s Setup_File] [-f Pattern_File] 

-h        	: this (help) message
-p pattern	: input file must be pattern mode
-f Pattern_File	: file containing vectors (pattern file)
-s Setup_File	: SigCtl decode setup file (pins, vector cycles, pattern labels start & stop)

Example: $0 -p pattern -s Setup_File -f Pattern_File\n";


	print "$Help\n";
	exit 0;
}

# Signature search from pattern file
sub SignatureSearch
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
			
		for ($i = 0; $i < $#PLabel; $i++)
		{
			if (/$PLabel[$i]/)
			{
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
				for ($PinCnt = 0; $PinCnt <= $#AllPinsPos; $PinCnt++)
				{
					my $Pos = $AllPinsPos[$PinCnt];
					my $Bits = "";
					for ($j = 0; $j <= $cnt; $j++)
					{
						$Bits .= $BitArray[$Pos][$j];
						$Bits =~ s/\s//g;
					}

					# Bit  LSB..MSB
					my $ReversePatBit = &ComputeBits($Bits);
					my $PatSigCtlBit = &ConvertSigCtlBit($ReversePatBit);
					my $CMTPatSigCtl = &CMTSigCtl($ReversePatBit);

					my $PatSigCtlBitLen = length ($ReversePatBit);
					&ProcessSigBits($PatSigCtlBit);	
					print "$FoundPins[$PinCnt]\t$PatSigCtlBit ($PatSigCtlBitLen)\n";
					print "CMT tester SigCtl: $CMTPatSigCtl\n";

					#Calculate Scanout Connectivity. 
					my $Chain1 = &ConnectChain("B7mux");	#Chain1 ends on B7mux
					&validate_sub_chain_order($Chain1);
					my $Chain2 = &ConnectChain("C7mux");	#Chain2 ends on C7mux
					&validate_sub_chain_order($Chain2);

					if ($PatSigCtlBit !~ /000000000000000000000000000000000000/)
					{
						print "Chain1 is: $Chain1 \t Chain2 is: $Chain2\n\n";
					}
					else
					{
						print "Not valid chain!!!\n\n";
					}
				}
			}
		}
	}
	close IN;
}

# Convert from MSB to LSB and LSB to MSB
sub ConvertSigCtlBit
{
	my $ReverseSigCtlBit = shift;
	my @OrgSigCtlBits = ();
	my @SigCtlBits = split (//, $ReverseSigCtlBit);
	my $Len = length($ReverseSigCtlBit);

	for ($i = 0; $i <= $Len; $i++)
	{
		my $Bit = pop (@SigCtlBits);
		push (@OrgSigCtlBits, $Bit);
	}
	my $OrgSigCtlBit = join ('', @OrgSigCtlBits);
	return $OrgSigCtlBit;
}

# Convert Pattern Bit to Switch Signature configuration
sub CMTSigCtl
{
	my $ReverseSigCtlBit = shift;
	my @CMTPatSigCtlBits = ();
	my @CMTSigCtlBits = split (//, $ReverseSigCtlBit);
	my $Len = length($ReverseSigCtlBit);

	for ($i = 0; $i <= $Len; $i++)
	{
		my $Bit = shift (@CMTSigCtlBits);
		$Bit += 1;
		push (@CMTPatSigCtlBits, $Bit);
	}
	my $CMTPatSigCtlBit = join ('', @CMTPatSigCtlBits);
	return $CMTPatSigCtlBit;
}

# Convert 144 bits to 36 bits data
sub ComputeBits
{
	my $OrgBits = shift;
	my $ModBits = "";

	my @Bits = split (//, $OrgBits);
	for ($i=0; $i<=$#Bits; $i++)
	{
		$ModBits .= $Bits[$i];
		$i +=3;
	}
	return "$ModBits";
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

		if ($Pin =~ /($Pins)/)
		{
			push (@FoundPins, $Pin);
			push (@AllPinsPos, $Pos);
		}
	}
}

# Process the bits
sub ProcessSigBits
{
	my $Binaries_sigctl = shift;
	my @muxes = split(//,$Binaries_sigctl);
	$sig_now = pop(@muxes);
	$sig_ads = pop(@muxes);
	$sig_bp3 = pop(@muxes);
	$sig_maskbp3 = pop(@muxes);
	$X1mux = pop(@muxes);
	$X2mux = pop(@muxes);
	$sec_chain = pop(@muxes);
	$master_checker = pop(@muxes);
	
	$A1mux = pop(@muxes);
	$A2mux = pop(@muxes);
	$A3mux = pop(@muxes);
	$A4mux = pop(@muxes);
	$A5mux = pop(@muxes);
	$A6mux = pop(@muxes);
	$A7mux = pop(@muxes);
	$A8mux = pop(@muxes);

	$B1mux = pop(@muxes);
	$B2mux = pop(@muxes);
	$B3mux = pop(@muxes);
	$B4mux = pop(@muxes);
	$B5mux = pop(@muxes);
	$B6mux = pop(@muxes);
	$B7mux = pop(@muxes);
	$B8mux = pop(@muxes);

	$C1mux = pop(@muxes);
	$C2mux = pop(@muxes);
	$C3mux = pop(@muxes);
	$C4mux = pop(@muxes);
	$C5mux = pop(@muxes);
	$C6mux = pop(@muxes);
	$C7mux = pop(@muxes);
	$C8mux = pop(@muxes);

	$T1_0mux = pop(@muxes);
	$T1_1mux = pop(@muxes);
	$T2_0mux = pop(@muxes);
	$T2_1mux = pop(@muxes);

}

sub ConnectChain
{
	local ($end_mux_name) = @_;
	local ($CurrentChain, $prev_mux, $prev_mux_name, $end_mux_value);

	#Calculate Scanout Connectivity. 
	$CurrentChain = "";

	if($end_mux_name eq "B7mux")
	{
		$end_mux_value = $B7mux;
	}
	else
	{
		$end_mux_value = $C7mux;
	}

	if($end_mux_value == 0) 
	{
		$CurrentChain = "core1_" . $CurrentChain;
		if($A7mux) 
		{
			$prev_mux = $B6mux;
			$prev_mux_name = "B6mux";
		}
		else 
		{
			$prev_mux = $C6mux;
			$prev_mux_name = "C6mux";
		}
	}
	else 
	{
		if($end_mux_name eq "B7mux")
		{
			$prev_mux = $B6mux;
			$prev_mux_name = "B6mux";
		}
		else
		{
			$prev_mux = $C6mux;
			$prev_mux_name = "C6mux";
		}
	}
	if($prev_mux == 0) 
	{
		$CurrentChain = "core0_" . $CurrentChain;
		if($A6mux) 
		{
			$prev_mux = $B5mux;
			$prev_mux_name = "B5mux";
		}
		else 
		{
			$prev_mux = $C5mux;
			$prev_mux_name = "C5mux";
		}
	}
	else {
		if($prev_mux_name eq "B6mux")
		{
			$prev_mux = $B5mux;
			$prev_mux_name = "B5mux";
		}
		else
		{
			$prev_mux = $C5mux;
			$prev_mux_name = "C5mux";
		}
	}
	if($prev_mux == 0) 
	{
		$CurrentChain = "frc1_" . $CurrentChain;
		if($A5mux) {
			$prev_mux = $B4mux;
			$prev_mux_name = "B4mux";
		}
		else {
			$prev_mux = $C4mux;
			$prev_mux_name = "C4mux";
		}
	}
	else 
	{
		if($prev_mux_name eq "B5mux")
		{
			$prev_mux = $B4mux;
			$prev_mux_name = "B4mux";
		}
		else
		{
			$prev_mux = $C4mux;
			$prev_mux_name = "C4mux";
		}
	}
	if($prev_mux == 0) 
	{
		$CurrentChain = "frc0_" . $CurrentChain;
		if($A4mux) 
		{
			$prev_mux = $B3mux;
			$prev_mux_name = "B3mux";
		}
		else 
		{
			$prev_mux = $C3mux;
			$prev_mux_name = "C3mux";
		}
	}
	else {
		if($prev_mux_name eq "B4mux")
		{
			$prev_mux = $B3mux;
			$prev_mux_name = "B3mux";
		}
		else
		{
			$prev_mux = $C3mux;
			$prev_mux_name = "C3mux";
		}
	}
	if($prev_mux == 0) 
	{
		$CurrentChain = "l2_" . $CurrentChain;
		if($A3mux) 
		{
			$prev_mux = $B2mux;
			$prev_mux_name = "B2mux";
		}
		else 
		{
			$prev_mux = $C2mux;
			$prev_mux_name = "C2mux";
		}
	}
	else {
		if($prev_mux_name eq "B3mux")
		{
			$prev_mux = $B2mux;
			$prev_mux_name = "B2mux";
		}
		else
		{
			$prev_mux = $C2mux;
			$prev_mux_name = "C2mux";
		}
	}
	if($prev_mux == 0) 
	{
		$CurrentChain = "bls_" . $CurrentChain;
		if($A2mux) 
		{
			$prev_mux = $B1mux;
			$prev_mux_name = "B1mux";
		}
		else {
			$prev_mux = $C1mux;
			$prev_mux_name = "C1mux";
		}
	}
	else 
	{
		if($prev_mux_name eq "B2mux")
		{
			$prev_mux = $B1mux;
			$prev_mux_name = "B1mux";
		}
		else
		{
			$prev_mux = $C1mux;
			$prev_mux_name = "C1mux";
		}
	}
	if($prev_mux == 0) 
	{
		$CurrentChain = "bus_" . $CurrentChain;
	}

	$CurrentChain =~ s/_$//;

	return($CurrentChain);
}

sub validate_sub_chain_order 
{
	#validate if chain is defined correctly
	local ($sub_chain_name)=@_;
	@chain_order=split(/_/,$sub_chain_name);        #divide string to sub_chains;
	$prev_sub_chain = "";
	foreach $sub_chain (@chain_order)
	{
		$found_chain = 0;
		foreach $exist_chains ("bus", "bls", "l2", "frc0", "frc1", "core0", "core1")
		{
			if($sub_chain eq $exist_chains)
			{
				#verify a correct order of sub-chains
				if($prev_sub_chain ne "")
				{
					foreach $exist_chains_ordered ("core1", "core0", "frc1", "frc0", "l2", "bls", "bus")
					{
						if($prev_sub_chain eq $exist_chains_ordered)
						{
							print "Incorrect sub-chain order: sub-chain $sub_chain is after sub-chain $prev_sub_chain in SO_CHAIN: $sub_chain_name\n";
						}
						if($sub_chain eq $exist_chains_ordered)
						{
							last;   #correct order
						}
					}
				}
				$found = 1;
				last;
			}
		}
		if(!$found)
		{
			print "Incorrect sub-chain name $sub_chain in SO_CHAIN: $sub_chain_name\n";
		}
		$prev_sub_chain = $sub_chain;
	}
}
