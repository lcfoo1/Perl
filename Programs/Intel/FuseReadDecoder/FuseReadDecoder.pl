#!/usr/intel/pkgs/perl/5.8.5/bin/perl -w
#########################################################################
# 									#
# 	Foo Lye Cheung				22 November 2006	#
# 	PDE DPG CPU Penang Malaysia					#
# 									#
# 	Script to decode fuseread data versus FuseSspec.txt		#
#									#
#	Notes:								#
#	1. PIROM use Hex in FuseSspec, but when run the FuseRead test	#
#	   the output will be in binary data.				#
#	2. Only run in Microsoft Window					#
#	   								#
#	Rev 1.0								#
#	   								#
#########################################################################
use warnings;
use strict;

my $ConfigFile = 'configuration.txt';
my $Debug = 0;
my $Reference = "";
my %HexBin = (
                "0" => "0000",
                "1" => "0001",
                "2" => "0010",
                "3" => "0011",
                "4" => "0100",
                "5" => "0101",
                "6" => "0110",
                "7" => "0111",
                "8" => "1000",
                "9" => "1001",
                "A" => "1010",
                "B" => "1011",
                "C" => "1100",
                "D" => "1101",
                "E" => "1110",
                "F" => "1111",
                "m" => "MMMM",
                "p" => "PPPP",
                "s" => "SSSS",
                "u" => "UUUU",
                "x" => "XXXX",
                "M" => "mmmm",
                "P" => "pppp",
                "S" => "ssss",
                "U" => "uuuu",
                "X" => "xxxx"
        );

my %BinHex = (
                "0000" => "0",
                "0001" => "1",
                "0010" => "2",
                "0011" => "3",
                "0100" => "4",
                "0101" => "5",
                "0110" => "6",
                "0111" => "7",
                "1000" => "8",
                "1001" => "9",
                "1010" => "A",
                "1011" => "B",
                "1100" => "C",
                "1101" => "D",
                "1110" => "E",
                "1111" => "F",
                "MMMM" => "m",
                "PPPP" => "p",
                "SSSS" => "s",
                "UUUU" => "u",
                "XXXX" => "x",
                "mmmm" => "m",
                "pppp" => "p",
                "ssss" => "s",
                "uuuu" => "u",
                "xxxx" => "x"
        );

# Main program starts here
&Main();

# Main subroutine
sub Main
{
	my ($Mode, $Conversion, $Bits, $Ref) = &ReadConfigFile($ConfigFile);
	$Reference = $Ref;

	# Mode whether the string in reverse order or not
	if ($Mode =~ /yes/i)
	{
		if ($Conversion =~ /hex/i)
		{
			&RevBinToHex($Bits);
		}
		elsif ($Conversion =~ /bin/i)
		{
			&RevBin($Bits);
		}
		else
		{
			print "Invalid Conversion reverse mode\n";
		}
	}
	elsif ($Mode =~ /no/i)
	{
		if ($Conversion =~ /hex/i)
		{
			&BinToHex($Bits);
		}
		elsif ($Conversion =~ /bin/i)
		{
			print "$Bits\n";
		}
		else
		{
			print "Invalid Conversion mode\n";
		}
	}
	else
	{
		print "Config file set invalid Mode\n";
	}
}

# Process Binary to Binary reverse
sub RevBin
{
	my $StrBinaries = shift;
	my @RevBits = ();

	my @AllBits = split (//, $StrBinaries);
	for (my $i=$#AllBits; $i>=0; $i--)
	{
		push (@RevBits, $AllBits[$i]);
	}
	$StrBinaries = join('', @RevBits);
	print "$StrBinaries\n";
}

# Process Binary to Hex in reverse order
sub RevBinToHex
{
	my $StrBinaries = shift;	
	my $TotalBinary = length ($StrBinaries);
	my @RevBits = ();
	
	if (0 == ($TotalBinary % 4))
	{
		my $Binary = "";                                          
		my $StrHex = "";
		
		my @AllBits = split (//, $StrBinaries);
		for (my $i=$#AllBits; $i>=0; $i--)
		{
			push (@RevBits, $AllBits[$i]);
		}

		my $Cnt = 1;
	
		foreach my $Bit (@RevBits)
		{
			if ($Cnt % 4 == 0)
			{
				$Binary .= $Bit;
				$StrHex .= $BinHex{$Binary};
				print "$Binary :: $BinHex{$Binary} :: $Cnt\n" if ($Debug == 1);
				$Binary = "";
			}
			else
			{			
				$Binary .= $Bit;
			}
			$Cnt++;
		}

		if ($Reference ne "")
		{
			my @RefBits = split (//, $Reference);
			my @ComBits = split (//, $StrHex);
			
		       	for (my $i=0; $i <= $#RefBits; $i++)
			{
				if ($RefBits[$i] ne $ComBits[$i])
				{
					print "$RefBits[$i] : $ComBits[$i] - $i\n";
				}
			}
		}
	
		if ((($#RevBits + 1)/4) != length ($StrHex))
		{
			print "ERROR: Binary conversion doesn't match, pls check $#AllBits\n";
		}
		
		print "$StrHex\n" . length ($StrHex) . "\n" if ($Debug == 1);
		print "$StrHex\n";
	}
	else
	{
		print "ERROR: Parse binary doen't match length conversion - $TotalBinary\n";
	}
}

# Process Binary to Hex
sub BinToHex
{
	my $StrBinaries = shift;	
	my $TotalBinary = length ($StrBinaries);
	
	if (0 == ($TotalBinary % 4))
	{
		my $Binary = "";                                          
		my $StrHex = "";
		
		my @AllBits = split (//, $StrBinaries);
		my $Cnt = 1;
	
		foreach my $Bit (@AllBits)
		{
			if ($Cnt % 4 == 0)
			{
				$Binary .= $Bit;
				$StrHex .= $BinHex{$Binary};
				print "$Binary :: $BinHex{$Binary} :: $Cnt\n" if ($Debug == 1);
				$Binary = "";
			}
			else
			{			
				$Binary .= $Bit;
			}
			$Cnt++;
		}
	
		if ((($#AllBits + 1)/4) != length ($StrHex))
		{
			print "ERROR: Binary conversion doesn't match, pls check $#AllBits\n";
		}
		
		print "$StrHex\n" . length ($StrHex) . "\n" if ($Debug == 1);
		print "$StrHex\n";
	}
	else
	{
		print "ERROR: Parse binary doen't match length conversion - $TotalBinary\n";
	}
}

# Process config file
sub ReadConfigFile
{
	my $File = shift;
	my ($Mode, $Conversion, $Bits, $Ref) = ();
	open (FILE, $File) || die "Cant open $File : $!\n";
	while (<FILE>)
	{
		s/\s+//g;
		next if (/#/ig);
		
		if (/Mode=(\w+)/i)
		{
			$Mode = $1;			
		}
		elsif (/Conversion=(\w+)/i)
		{
			$Conversion = $1;			
		}
		elsif (/Bits=(\w+)/i)
		{
			$Bits = $1;			
		}
		elsif (/Ref=(\w+)/i)
		{
			$Ref = $1;			
		}
	}
	close FILE;	

	return ($Mode, $Conversion, $Bits, $Ref);
}

