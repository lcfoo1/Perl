#!/usr/intel/pkgs/perl/5.8.5/bin/perl -w

# Global variables declare here
#my $Pattern = 'd0066186N3999256_10101010a2x_GA10xxL_2xxcxxx_4x0xxxs0xx0xxxxxxx_fuse_read_NORM.pat.data';
my $Pattern = 'temp.data';

my $DEBUG = 1;
my @AllPinsPos = ();
my @FoundPins = ();
my $Pins = "";
my @PLabel = ();
my $Vector = 0;
my $Tclk = 0;
my $Header = "";
my $InputFile = "";
my $SetupFile = 'SigCtlSetup.txt';

&ReadSetupFile($SetupFile);
&CompareLabel($InputFile);

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

                # Match the frist line pins header
                if ((/$Header/) || ($HeaderFlag))
		{
                        print "$_\n" if ($DEBUG == 2);
                        my $TmpLen = length ($_);
		        $StrLenMax = $TmpLen if ($StrLenMax < $TmpLen);
		        push (@Headers, $_);
		        $HeaderFlag = 1;
	        }
		if (($_ !~ /#/) && ($HeaderFlag))
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

                #print "$PLabel[0] $PLabel[1]\n";
			
		for ($i = 0; $i <= $#PLabel; $i++)
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
						#print "Pos=$Pos\n";
						#print "Bits=$Bits[$Pos]\n";
						$BitArray [$Pos][$cnt] = $Bits[$Pos];
						$cnt++;
					}
					$_ = <IN>;
				}


				#$EndLbl = $_;
				for($j = 0; $j < $Tclk*2; $j++)
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
				#print "$#AllPinsPos\n";
				#for ($PinCnt = 0; $PinCnt <= $#AllPinsPos; $PinCnt++)
				#{
				#	my $Pos = $AllPinsPos[$PinCnt];
				#	print "Pin:$FoundPins[$PinCnt], Column:$AllPinsPos[$PinCnt]\n";
				#	my $binarybits = "";
				#	for ($j = 0; $j <= $cnt; $j++)
				#	{
				#		$binarybits .= $BitArray[$Pos][$j];
				#		$binarybits =~ s/\s//g;
				#		#print "$Pos $j $BitArray[$Pos][$j] $binarybits\n";
				#	}
				#	$tap_str=reverse($binarybits);
				#	#print "Final Bits_!!!=$tap_str\n";
				#	@Split_bits = split(//,$tap_str);
				#	$Databits_Tclk_align="";
				#	for($k=$Tclk;$k<=($#Split_bits+1);$k+=$Tclk)
				#	{	
				#		$Databits_Tclk_align .= $Split_bits[$k-1];
				#	}
				#	print "0b$Databits_Tclk_align";
				#	$hex=&binary2hex($Databits_Tclk_align);
				#	print " [0x$hex]"." [".length($Databits_Tclk_align)." bits]\n"; 
				#}
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
	my $CNT = 0, $Pos = 0, $MaxLen = 0;
        my $i = 0; $j = 0;

	foreach my $Line (@Headers)
	{
		my @Data = split(//, $Line);
		if ($CNT == 0) 
                {
                        $MaxLen =$#Data;
                }
		for ($i = 0; $i <= $#Data; $i++)
		{
			$Tables[$i][$CNT] = $Data[$i];
		}
		$CNT++;

		if ($i < $MaxLen) 
                {
                        pop (@Tables);
                        $CNT = $CNT - 1;
                        last; 
                }
	}


        local $^W = 0;
	for ($Pos = 0; $Pos <= $StrLenMax; $Pos++)
	{
		my $Pin = "";
		for ($j = 0; $j < $CNT; $j++)
		{
		    $Pin .= $Tables[$Pos][$j];
		}

                chomp ($Pin);
		$Pin =~ s/\s+//g;

		if ($Pin =~ /^($Pins)$/)
		{
			print "Found pin :$Pin, $Pos\n" if ($DEBUG);
			push (@FoundPins, $Pin);
			push (@AllPinsPos, $Pos);
		}
	}	
	#print "Foundpins : @FoundPins\n";
	#print "AllPinsPos : @AllPinsPos\n";
}

# --------------------------------------------------------------------------
# Convert binary to integer
# --------------------------------------------------------------------------
sub binary2int {
    local($bin) = @_;
    local($int) = 0;
    local($mul) = 1;
    while ($bin ne '') {
        $int += chop($bin) * $mul;
        $mul *= 2;
    }
    $int;
}

sub binary2hex {
    local($bin) = @_;
    local($hex) = '';
    local($l);
    local(@hexdigits) = ( 0,1,2,3,4,5,6,7,8,9,'A','B','C','D','E','F' );

    while ($bin ne '') {
        $l = length($bin);
        if ($l > 4) { $l = 4; }
        $hex = $hexdigits[&binary2int(substr($bin,-$l))] . $hex;
        $bin = substr($bin,0,length($bin)-$l);
    }
    $hex;
}

sub hex2binary {
    local($value,$width) = @_;
    local($b,$r);
    local(%hb) = (  '0','0000','1','0001','2','0010','3','0011',
                    '4','0100','5','0101','6','0110','7','0111',
                    '8','1000','9','1001','a','1010','b','1011',
                    'c','1100','d','1101','e','1110','f','1111');

    $value =~ tr/A-F/a-f/;
    if (!defined($width) || ($width eq '')) { $width = length($value) * 4; }

    $r = '';
    while ($value ne '') {
        $b = chop($value);
        $r = $hb{$b} . $r;
    }

    if ($width > length($r)) { $r = 0 x ($width - length($r)) . $r; }

    substr($r,-$width);

}



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
		elsif (/TCLK=(\S+)/)
		{
			$Tclk=$1;
		}
		elsif (/HEADER=(\S+)/)
		{
			$Header=$1;
		}
	}
	close SETUP;

	if ($Tclk==0) 
	{
		print "Error, missing Tclk value. Either Tclk=2 or Tclk=4\n";
		exit 0;
	}
}

