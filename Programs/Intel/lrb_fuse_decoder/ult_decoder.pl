#!/usr/intel/pkgs/perl/5.8.5/bin/perl 
#################################################################################################
# 												#
# 	Foo Lye Cheung								19 May 2009	#
# 	PDE DPG CPU Penang Malaysia								#
# 												#
# 	Script to decode 56 bit ULT for LRB							#
#												#
#	Rev 0.0											#
#												#
#	   											#
# Sample: D8388030 797 +02 +04 = 11001000100110110010001100000011000111010000001000000100	#
# Standard decoding 56 bits ULT method								#
# ====================================								#
# [4] FAB ID											#
# [4] Year											#
# [6] WW											#
# [16] Sequential Lot Serial									#
# [10] Wafer											#
# [8] X Die location										#
# [8] Y Die Location										#
# Standard FabID decoding									#
# =======================									#
# '2' = 0 (D2)											#
# 'E' = 1 (F11)											#
# 'F' = 2 (F12)											#
# 'Y' = 3 (D1B/20)										#
# 'G' = 4 (F14)											#
# '1' = 5 (D1/F15)										#
# 'H' = 6 (F24)											#
# 'X' = 7 (F17)											#
# 'K' = 8 (F18)											#
# 'A' = 9 (F22)											#
# 'Z' = 10 (D1C)										#
# 'W' = 11 (F11X/F21)										#
# 'D' = 12 (D1D)										#
# 'N' = 13 (F28)   										#
# 'L' = 14 (F32)										#
#################################################################################################
use Getopt::Std;

getopts("s:", \%opt ) or Usage();
&Usage() if defined ($opt_h || $opt{h});

my $FuseStr = $opt_s || $opt{s};
#my $FuseStr = '11001000100110110010001100000011000111010000001000000100';

if (defined $FuseStr)
{
	&Main();
}
else
{
	&Usage();
}

# Main script start below here
sub Main
{
	my %FabID = (   0 => "2",
                1 => "E",
                2 => "F",
                3 => "Y",
                4 => "G",
                5 => "1",
                6 => "H",
                7 => "X",
                8 => "K",
                9 => "A",
                10 => "Z",
                11 => "W",
                12 => "D",
                13 => "N",
                13 => "L"
	);

	if (length($FuseStr) == 56)
	{
		my @Bits = split ('', $FuseStr);

		foreach my $Bit (@Bits)
		{
			if (!(($Bit eq "0") || ($Bit eq "1")))
			{
				print "Invalid fuse string, contain characters besides 0 and 1\n";
				exit 0;
			}
		}

		my $FabIDDec = &bin2dec($Bits[0] . $Bits[1] . $Bits[2] . $Bits[3]);
		my $FabID = $FabID{$FabIDDec};
		my $Year =  &bin2dec($Bits[4] . $Bits[5] . $Bits[6] . $Bits[7]);
		my $WW = &bin2dec($Bits[8] . $Bits[9] . $Bits[10] . $Bits[11] . $Bits[12] . $Bits[13]);
		my $LotID = &bin2dec($Bits[14] . $Bits[15] . $Bits[16] . $Bits[17] . $Bits[18] . $Bits[19] . $Bits[20] . $Bits[21] . $Bits[22] . $Bits[23]);
		my $EngLotID = &bin2dec($Bits[24] . $Bits[25] . $Bits[26] . $Bits[27] . $Bits[28] . $Bits[29]);
		my $WaferID = &bin2dec($Bits[30] . $Bits[31] . $Bits[32] . $Bits[33] . $Bits[34] . $Bits[35] . $Bits[36] . $Bits[37] . $Bits[38] . $Bits[39]);
		my $xloc = &ConvertLoc($Bits[40], &bin2dec($Bits[41] . $Bits[42] . $Bits[43] . $Bits[44] . $Bits[45] . $Bits[46] . $Bits[47]));
		my $yloc = &ConvertLoc($Bits[48], &bin2dec($Bits[49] . $Bits[50] . $Bits[51] . $Bits[52] . $Bits[53] . $Bits[54] . $Bits[55]));

		my $Fablot = $FabID . $Year . $WW . $LotID . $EngLotID;

		print "ULT: ${Fablot}_${WaferID}_${xloc}_${yloc}\n";

	}
	else
	{
		print "Invalid fuse string length less than 56 bits! Your string " . length ($FuseStr) . "!\n";
		exit 0;
	}

}

# Convert a binary number to a decimal number
sub bin2dec 
{
	unpack("N", pack("B32", substr("0" x 32 . shift, -32)));
}

# Mapping the xloc and yloc to iTUFF format
sub ConvertLoc
{
	my ($Sign, $Coordinate) = @_;

	if ($Sign eq "0")
	{
		$Sign = "+";
	}
	else
	{
		$Sign = "-";
	}

	if ((length($Coordinate)) == 1)
	{
		$Coordinate = $Sign . "0" . $Coordinate;
	}	
	else
	{
		$Coordinate = $Sign . $Coordinate;
	}

	return $Coordinate;
}

# Help message of the usage
sub Usage
{
	my $Help = "\nHelp:\n=====
Usage: $0 [-h] [-s fuse string]

-h        		: this (help) message
-s fuse string		: 56 bits ULT fuse string

Example: $0 -s 11001000100110110010001100000011000111010000001000000100\n";

	print "$Help\n";
	exit 0;
}
