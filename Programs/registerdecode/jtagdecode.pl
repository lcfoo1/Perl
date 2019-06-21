use warnings;
use strict;
##########################################################################
# This script develop to reverse value from UserDR to input value.
# Developer: Lye Cheung Foo
# Rev 0.0
# 16 July 2018
##########################################################################

my %AllRegisterMapping = ();
my @WriteReadAddressMap = ();
my $JTAGUserDR = -1;
&ProcessRegMap("wl_chip_jtag_regs_43014.htm");
&Main();
#print "$AllRegisterMapping{0}[0]\n";

# Main program
sub Main()
{
	print "Please enter JTAG User Data Register (0-3): ";
	$JTAGUserDR = <STDIN>;
	chomp($JTAGUserDR);
	print "Please enter UserDR value (hex) (32 hex): ";
	my $JtagHex = <STDIN>;
	print "UserDR entered: $JTAGUserDR with value $JtagHex\n";
	chomp($JtagHex);

	#$JtagHex = "641836000000000000000000";
	#my $JtagHex = "3FFFFFFF80000000";
	#my $JtagHex = "00000000000000000000000000000005";
	#$JTAGUserDR = 3;
	
	#userreg [Reg_number]  [bit 31:0] [bit 63:32] [bit 95:64] [bit 128:96]
	#hence the 5 that you mentioned in userreg 3 0x0 0x0 0x0 0x80005 is actually referring to bit 96 and bit 98 set to 1.
	my $PadJtagHex = sprintf("%032s", $JtagHex);
	my @Four32Binary = ();
	for (my $i=0; $i < length($PadJtagHex); $i++)
	{
		my $Str = substr ($PadJtagHex, $i, 8);
		my $Binary = sprintf( "%032b", hex( $Str));
		#print "$i == Str: $Str : $Binary\n";
		print "JTAG User DR $JTAGUserDR (" . $i/8 . ") [" . (($i+8) * 4 - 1) . "-" . $i * 4 . "] = $Str ($Binary)\n";
		push (@Four32Binary, $Str);
		$i=$i+7; 
	}

	for (my $i =0; $i <4; $i++)
	{
		&PrintReg32Hex($i, $Four32Binary[$i]);
	}
}

sub PrintReg32Hex()
{
	my ($Chunk, $JtagHex) = @_;
	my $Offset = 0;

	# Decode the chunk of 32 hex
	if ($Chunk == 1)
	{
		$Offset = 32;
	}
	elsif ($Chunk == 2)
	{
		$Offset = 64;
	}
	elsif ($Chunk == 3)
	{
		$Offset = 96;
	}

	#print "Chunk $Chunk: $JtagHex\n";
	my $PadJtagBinary = sprintf("%032b", hex($JtagHex));
	my @TmpBits = split(//, $PadJtagBinary);
	my @Bits = reverse @TmpBits;
	for (my $i=0; $i<32; $i++)
	{
		if($Bits[$i] eq "1")
		{
			my $RegBitPos = ($i) + $Offset;
			print "JTAG UserDR $JTAGUserDR : Bit#" . ($RegBitPos) . " : $AllRegisterMapping{$JTAGUserDR}[($RegBitPos)]\n";
		}
	}
}

# Process the htm register map
sub ProcessRegMap()
{
	my $RegMapFile = shift;
	my $BusReg = "";
	my $Cnt = 0;
	my @RegMap = ();
	open (REGMAPFILE, $RegMapFile) || die "Cant open $RegMapFile : $!\n";
	while (<REGMAPFILE>)
	{
		chomp();

		#<h2>JTAG User Register 0</h2>
		if (/h2\>(.*)\<\/h2/)
		{
			$BusReg = $1;
			if (0 != $Cnt)
			{
 				push @{$AllRegisterMapping{$Cnt-1}}, @RegMap;
			}
			@RegMap = ();
			$Cnt++;
		}
		#Write address: 0xff03ff3a;  Read Address 0xff0bff3a
		elsif (/\s+(Write.*)$/)
		{
			#print "$BusReg = $1\n";
			push (@WriteReadAddressMap, $1);
		}
		#<tr><td>0</td><td>audio_jtag_pmu_seq_byp_mask_0</td><td></td></tr>
		elsif (/<tr><td>(\d+)<\/td><td>(\w+)<\/td>/)
		{
			#print "$1 :: $2\n";
			push (@RegMap, $2);
			#exit;
		}
	}
	close REGMAPFILE;


	#foreach my $UDR (sort keys %AllRegisterMapping) 
	#{
	#	print "UDR : $UDR ";
	#	foreach my $i (0 .. $#{ $AllRegisterMapping{$UDR}}) 
	#	{
	# 		print " $i = $AllRegisterMapping{$UDR}[$i]";
	#	}
	#	print "\n";
	#	#exit;
	#}
}
