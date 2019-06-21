
my $TotalBits = 5; # Total number of binary bit max
my $CustomVar = "tt_dcs2_trim";
my $CustomConfig = "DDR";
my $Offset = 0; # Offset mapper
my $StaticBit = "1"; # Static bit to append to MSB

&Main();

# Pack has limitation to max 32 bits conversion
sub Main
{
	my $AllZeroRef = "0" x  (32-$TotalBits);

	for (my $Cnt=0; $Cnt < 2**$TotalBits; $Cnt++)
	{	
		$Str = dec2bin($Cnt);
		$CheckMSB = substr ($Str, 0, (32-$TotalBits));

		# Create mapper to add/chop for leading zero's
		if ($AllZeroRef eq $CheckMSB)
		{
			my $Bits = substr ($Str, (32-$TotalBits), 32);
			my $FinalCnt = $Offset + $Cnt;
			print "define:         ". $CustomConfig .":                 STRING:     " . $CustomVar . "_binary" .":    LITERAL:        \"". $StaticBit . $Bits . "\"          : " . $CustomVar ." == $FinalCnt\n";

		}
		else
		{
			last;
		}
	}
}

# Subroutine to convert from decimal to binary
sub dec2bin {
    my $BinaryStr = unpack("B32", pack("N", shift));
    return $BinaryStr;
}






























