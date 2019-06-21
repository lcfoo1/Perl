#!/usr/intel/pkgs/perl/5.8.5/bin/perl -w

# Global variables declare here
my $CfgFile = 'Configuration.txt';
#my $Pattern = 'd0066186N3999256_10101010a2x_GA10xxL_2xxcxxx_4x0xxxs0xx0xxxxxxx_fuse_read_NORM.pat.data';
my $Pattern = 'temp.data';

my @AllPinsPos = ();
my @FoundPins = ();
my $Pins = "";
my @PLabel = ();
my $Vector = 0;
my $tck = 0;
my $InputFile = "";
my $SetupFile = 'SigCtlSetup.txt';






#open (PATTERN, $Pattern) || die "Can't open $Pattern : $!\n";
#while (<PATTERN>)
#{
#        chomp;

#        if ($Pattern =~ /.data$/)
#        {
#                my @Lines = split ('', $_);
#                $LineLen = $#Lines;
#               
#                for (0 .. $#Lines)
#                {
#                        push (@Pins, $Lines[$_]); 
#                        print "$#Lines\n";
#                }
#                #print "$_\n";
#        }
#}
#close PATTERN;


&ReadSetupFile($SetupFile);
#&CompareLabel($InputFile);


sub CompareLabel
{
	my $File = shift;
	my @Headers = ();
	my $HeaderFlag = 0;
	my $StrLenMax = 0;

	print "Pattern File: $File\n";

	# Get the header of the pattern file
	my $start_header=0;
	open (IN, $File) || die "Cant open $File : $!\n";
        while (<IN>)
	{	
		chomp;
		  if ((/#\s+AA\s+DDDDDDDD/) || ($start_header==1))	#first line of pins header
		  {
		      my $TmpLen = length ($_);
		      $StrLenMax = $TmpLen if ($StrLenMax < $TmpLen);
		      push (@Headers, $_);
		      $start_header=1;
		  }
		  if (($_ !~ /#/) && ($start_header==1))
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
				#print "StartLbl=$StartLbl\n";
				$i++;
				#print "PLabel=$PLabel[$i]\n";
				until (/$PLabel[$i]/)
				{
					chomp;
					#print "Content : $_\n";
					my @Bits = split (//, $_);
					#print "After Content : $Bits[$bclk_col-1]\n";
					if ($Bits[$bclk_col-1] eq "=") 
					{
						$col_offset=0;
						#print "Col offset = 0\n";
					}
					else
					{
						$col_offset=1;
						#print "Col offset = 1\n";
					}
					foreach $Pos (@AllPinsPos)
					{
						#print "Pos=$Pos\n";
						#print "Bits=$Bits[$Pos]\n";
						$BitArray [$Pos][$cnt] = $Bits[$Pos-$col_offset];
						$cnt++;
					}
					$_ = <IN>;
				}
				$EndLbl = $_;
				#print "$#AllPinsPos\n";
				# Offset for end label data
				#for ($j = 0; $j <= $Vector*2; $j++)
				for($j = 0; $j < $tck*2; $j++)
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
				for ($PinCnt = 0; $PinCnt <= $#AllPinsPos; $PinCnt++)
				{
					my $Pos = $AllPinsPos[$PinCnt];
					print "Pin:$FoundPins[$PinCnt], Column:$AllPinsPos[$PinCnt]\n";
					my $binarybits = "";
					for ($j = 0; $j <= $cnt; $j++)
					{
						$binarybits .= $BitArray[$Pos][$j];
						$binarybits =~ s/\s//g;
						#print "$Pos $j $BitArray[$Pos][$j] $binarybits\n";
					}
					$tap_str=reverse($binarybits);
					#print "Final Bits_!!!=$tap_str\n";
					@Split_bits = split(//,$tap_str);
					$Databits_tck_align="";
					for($k=$tck;$k<=($#Split_bits+1);$k+=$tck)
					{	
						$Databits_tck_align .= $Split_bits[$k-1];
					}
					print "0b$Databits_tck_align";
					$hex=&binary2hex($Databits_tck_align);
					print " [0x$hex]"." [".length($Databits_tck_align)." bits]\n"; 
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
		#print "@Headers\n";
		my @Data = split(//, $Line);
		if($cnt==0) {$max_length =$#Data;}
		for ($i = 0; $i <= $#Data; $i++)
		{
			#print "Count : $cnt, $i :$Data[$i]\n";
			$Tables[$i][$cnt] = $Data[$i];
			#print "Tables : $i:$cnt:$Tables[$i][$cnt], Data : $Data[$i]\n";
		}
		$cnt++;
		if($i <$max_length) {pop(@Tables);$cnt=$cnt-1;last; }
	}

	for ($Pos = 0; $Pos <= $StrLenMax; $Pos++)
	{
		my $Pin = "";
		#for ($j = 0; $j <=$cnt; $j++)
		for ($j = 0; $j <$cnt; $j++)
		{
		  #print "Tables : $Pos:$j:$Tables[$Pos][$j]\n";
		  #if ( ($Tables[$Pos][$j] =~ m/\s/)  && ($j != 0) ) 
		  #{ 
		  #  print "SPACE\n";
		  #  if ($Tables[$Pos][$j-1] =~ m/\w/) {last;}
			#$Pin =~ s/\s//g;
		  #}
		  #else 
		  #{
		    $Pin .= $Tables[$Pos][$j];
		  #}
		}
		#if ($Pos==33) { print "$Pin\n" }
		#print "Pre: Pin : $Pin\n";
		$Pin =~ m/(\w+)/;
		$Pin = $1;
		#print "Pin : $Pin\n";
		#print "Pins : $Pins\n";
		if ($Pin =~ /^($Pins)$/)
		{
			#print "Found pin :$Pin, $Pos\n";
			push (@FoundPins, $Pin);
			push (@AllPinsPos, $Pos);
		}
		elsif ($Pin =~BCLK1t0_1)
		{
			$bclk_col=$Pos;
			#print "BCLK_COL = $Pos\n";
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
		elsif (/TCK=(\S+)/)
		{
			$tck=$1;
		}
	}
	close SETUP;

	if ($tck==0) 
	{
		print "Error, missing tck value. Either TCK=2 or TCK=4\n";
		exit 0;
	}
}

