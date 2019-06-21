#########################################################################################################
#													#
#	Foo Lye Cheung					PDE CPU OAP (TMM)				#
#	30 July 2008											#
#	604-2536452											#
#													#
#	Rev 0.0												#
#													#
#########################################################################################################

use strict;
use warnings;

# Global variables declare here
my $Debug = 0;
my $HeaderFlag = 0;
my @HeaderPin = ();
my @Headers = ();
my @AllPinsPos = ();
my @FoundPins = ();
my $Pins = "";
my $PatternFile = "";
my $SetupPatternFile = 'SigCtlSetup.txt';
my $TotalCount = 0;

&ReadSetupPatternFile($SetupPatternFile);
&Main();

# Main program start over here
sub Main
{
	print "Pattern file: $PatternFile\n";
	open (FILE, $PatternFile) || die "Cant open $PatternFile : $!\n";
	while (<FILE>)
	{
		chomp;

		if (!$HeaderFlag)
		{
			do
			{
				my @Chars = split (//, $_);
				no warnings;
				my $Space = join ('', $Chars[3], $Chars[4], $Chars[5], $Chars[6], $Chars[7], $Chars[8], $Chars[9], $Chars[10], $Chars[11], $Chars[12], $Chars[13]);
			
				# Ensuring that is header pins before proceeding decoding the pins
				if ($Space =~ /^\s+$/)
				{
					# Getting the max length
					if ($TotalCount < $#Chars)
					{
						$TotalCount = $#Chars;
					}
	  				push (@Headers, $_);
				}

				$_ = <FILE>;
				$HeaderFlag = 1;
			} while ($_ =~ /^#/);
		}

		if ($HeaderFlag)
		{
  			&GetPin ($TotalCount, @Headers);
			last;
		}
	}
	close FILE;


	my (@Tmp, @PostTmp) = ();
	open (FILE, $PatternFile) || die "Cant open $PatternFile : $!\n";
	while (<FILE>)
	{
		chomp;
		if (/(.*\s*vrg\d+\s+)([^;]+)(.*)(V\:\d+)/i)
		{
			chomp;
			#print "In loop $2 $4\n";
			my ($AllPinsParam, $Bits, $Vector) = ($1, $2, $4);
			my @DataCol = split(//, $_);
			for (my $i = 0; $i <= $#FoundPins; $i++)
			{
				$Tmp[$i] = $DataCol[$AllPinsPos[$i]];
				no warnings;
				if ($PostTmp[$i] eq $Tmp[$i])
				{

				}
				else
				{
					print "$FoundPins[$i] - $DataCol[$AllPinsPos[$i]] $Vector\n";
				}

				$PostTmp[$i] = $Tmp[$i];
				#exit 0;
			}
		}
	}
	close FILE;
}

# Subroutine to get the pin position from pattern file
sub GetPin
{
	my @Tables = ();
	my ($Count, $Pos, $i, $j) = (0, 0, 0, 0);

	foreach my $Line (@Headers)
	{
		my @Datas = split(//, $Line);
		for ($i = 0; $i <= $#Datas; $i++)
		{
			$Tables[$i][$Count] = $Datas[$i];
			print "Tables : $i:$Count:$Tables[$i][$Count], Data : $Datas[$i]\n" if ($Debug == 2);
		}
		$Count++;
	}

	no warnings;
	for ($Pos = 0; $Pos <= $TotalCount; $Pos++)
	{
		my $Pin = "";
		for ($j = 0; $j < $Count; $j++)
		{
		    $Pin .= $Tables[$Pos][$j];
		}

		$Pin =~ m/(\w+)/;
		$Pin = $1;

		if ($Pin =~ /^($Pins)$/)
		{
			print "Found pin :$Pin, $Pos\n" if ($Debug);
			push (@FoundPins, $Pin);
			push (@AllPinsPos, $Pos);
		}
	}	

	print "Foundpins : @FoundPins\n" if ($Debug == 2);
	print "AllPinsPos : @AllPinsPos\n" if ($Debug == 2);
}

# Read input setup file
sub ReadSetupPatternFile
{
	my $SetupPatternFile = shift;
	open (SETUP, $SetupPatternFile) || die "Cant open setup file $SetupPatternFile : $!\n";
	while (<SETUP>)
	{
		next if (/#/);
		if (/PIN=(\S+)/)
		{
			$Pins = $1;
		}
		elsif (/PATTERN=(\S+)/)
		{
			$PatternFile = $1;
		}
	}
	close SETUP;
}

# Convert binary to integer
sub binary2int 
{
    my ($bin) = @_;
    my ($int) = 0;
    my ($mul) = 1;
    while ($bin ne '') 
    {
        $int += chop($bin) * $mul;
        $mul *= 2;
    }
    $int;
}

# Convert binary to hex
sub binary2hex 
{
    my ($bin) = @_;
    my ($hex) = '';
    my ($l);
    my (@hexdigits) = ( 0,1,2,3,4,5,6,7,8,9,'A','B','C','D','E','F' );

    while ($bin ne '') 
    {
        $l = length($bin);
        if ($l > 4) 
	{ 
		$l = 4; 
	}
        $hex = $hexdigits[&binary2int(substr($bin,-$l))] . $hex;
        $bin = substr($bin,0,length($bin)-$l);
    }
    $hex;
}

# Convert hex to binary
sub hex2binary 
{
    my ($value,$width) = @_;
    my ($b,$r);
    my (%hb) = (  '0','0000','1','0001','2','0010','3','0011',
                    '4','0100','5','0101','6','0110','7','0111',
                    '8','1000','9','1001','a','1010','b','1011',
                    'c','1100','d','1101','e','1110','f','1111');

    $value =~ tr/A-F/a-f/;
    if (!defined($width) || ($width eq '')) 
    { 
	    $width = length($value) * 4; 
    }

    $r = '';
    while ($value ne '') 
    {
        $b = chop($value);
        $r = $hb{$b} . $r;
    }

    if ($width > length($r)) 
    { 
	    $r = 0 x ($width - length($r)) . $r; 
    }

    substr($r,-$width);
}
