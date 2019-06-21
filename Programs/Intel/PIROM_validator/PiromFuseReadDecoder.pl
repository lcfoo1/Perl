#!/usr/intel/pkgs/perl/5.8.5/bin/perl -w
#########################################################################
# 									#
# 	Foo Lye Cheung					3 May 2007	#
# 	PDE DPG CPU Penang Malaysia					#
# 									#
# 	Script to decode fuseread data versus FuseSspec.txt for PIROM	#
#									#
#	Notes:								#
#	1. PIROM use Hex in FuseSspec, but when run the FuseRead test	#
#	   the output will be in binary data.				#
#	2. Only run in Microsoft Window					#
#	3. Only validated for PIROM - mode (yes) and Conversion (hex)	#
#	   								#
#	Rev 2.0								#
#									#
#	No time to enhance the script for universal usage		#
#	   								#
#########################################################################
use warnings;
use strict;

my $ConfigFile = 'configuration.txt';
my $Debug = 0;
my $Verbose = 0;
my $Reference = "";
my $CurFuseData = "";
my $CurQDF = "";
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
	my ($Mode, $Conversion, $Bits, $Datalog, $Console, $SourceFlag, $FuseSspec) = &ReadConfigFile($ConfigFile);

	if ($SourceFlag == 1)
	{
		&FuseSspecMapping($FuseSspec);
		$Reference = $CurFuseData;	
	}
	elsif ($SourceFlag == 2)
	{
		&FuseSspecMapping($FuseSspec);
		$Reference = $CurFuseData;	

		# Only allow 1 units on console to decode
		open (CONSOLE, $Console) || die "Cant open console $Console : $!\n";
		while(<CONSOLE>)
		{
			if (/2_tname\w+PIROM/i)
			{
				while (<CONSOLE>)
				{
					if (/2_rawbinary_msbF_(\w+)/)
					{
						$Bits = $1;
						last;
					}
				}
				last;			
			}
		}
		close CONSOLE;
	}
	elsif ($SourceFlag == 3)
	{
		# Only allow 1 units on datalog to decode
		open (DATALOG, $Datalog) || die "Cant open datalog $Datalog : $!\n";
		while(<DATALOG>)
		{
			chomp;
			if (/6_sspec_(\w+)/i)
			{
				$CurQDF = $1;
			}

			if (/2_tname\w+PIROM/i)
			{
				while (<DATALOG>)
				{
					if ((/2_rawbinary_msbF_(\w+)/) || (/2_strgalt_fus_msbF_(\w+)/))
					{
						$Bits = $1;
						last;
					}
				}
				last;			
			}
		}
		close DATALOG;

		&FuseSspecMapping($FuseSspec);
		$Reference = $CurFuseData;
	}

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
				print "$Binary :: $BinHex{$Binary} :: $Cnt\n" if ($Verbose);
				$Binary = "";
			}
			else
			{			
				$Binary .= $Bit;
			}
			$Cnt++;
		}

		if ((($#RevBits + 1)/4) != length ($StrHex))
		{
			print "ERROR: Binary conversion doesn't match, pls check $#AllBits\n";
		}
		
		print "$StrHex\n" . length ($StrHex) . "\n" if ($Verbose);
		print "SSPEC/QDF: $CurQDF\n";
		print "Actual: $StrHex\n";
		print "Sspec : $CurFuseData\n";

		if ($Reference ne "")
		{
			$Cnt = 0;
			my @RefBits = split (//, $Reference);
			my @ComBits = split (//, $StrHex);
			
			print "Sspec : Actual - Hex location (start from bit 0)\n";
		       	for (my $i=0; $i <= $#RefBits; $i++)
			{
				if ($RefBits[$i] ne $ComBits[$i])
				{
					$Cnt = $1 if (($i/2) =~ /^(\d+)/);
					print "$RefBits[$i] : $ComBits[$i] - $Cnt\n";
				}
			}
		}
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
				print "$Binary :: $BinHex{$Binary} :: $Cnt\n" if ($Verbose);
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
		
		print "$StrHex\n" . length ($StrHex) . "\n" if ($Verbose);
		print "$StrHex\n";
	}
	else
	{
		print "ERROR: Parse binary doesn't match length conversion - $TotalBinary\n";
	}
}

# Process config file
sub ReadConfigFile
{
	my $File = shift;
	my $SourceFlag = 1;
	my ($Mode, $Conversion, $Bits, $Datalog, $Console, $FuseSspec) = ();
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
		elsif (/QDF=(\w+)/i)
		{
			$CurQDF = $1;			
		}
		elsif ((/Bits=(\w+)/i) && ($SourceFlag == 1))
		{
			$Bits = $1;			
		}
		elsif ((/Console=(\S+)/i) && ($SourceFlag == 2))
		{
			$Console = $1;			
			$Console =~ s/\\/\//g;
		}
		elsif ((/Datalog=(\S+)/i) && ($SourceFlag == 3))
		{
			$Datalog = $1;			
			$Datalog =~ s/\\/\//g;
		}
		elsif (/FuseSspec=(\S+)/i)
		{
			$FuseSspec = $1;			
			$FuseSspec =~ s/\\/\//g;
		}
		elsif (/Source=(\S+)/i)
		{
			my $Source = $1;
			if ($Source =~ /Input/i)
			{
				$SourceFlag = 1;
			}
			elsif ($Source =~ /Console/i)
			{
				$SourceFlag = 2;
			}
			elsif ($Source =~ /Datalog/i)
			{
				$SourceFlag = 3;
			}
			else
			{
				print "Set Source=Input/Datalog/Console mode\n";
				exit 0;
			}
		}
	}
	close FILE;	

	return ($Mode, $Conversion, $Bits, $Datalog, $Console, $SourceFlag, $FuseSspec);
}

# Mapping all SSPEC/QDF with FuseData
sub FuseSspecMapping
{
	my $QDFFound = 0;
	my $FuseSspec = shift;
	my %SspecFuseDatas = ();
	my (%LineItems, %SspecLineItems) = ();

	open (FUSESSPEC, $FuseSspec) || die "Cant open $FuseSspec : $!\n";
	while (<FUSESSPEC>)
	{
		chomp;
		if (/FUSEDATA\s*:\s*PIROM\s*:\s*\S*\s*:\s*(\w+)\s*:\s*\w*\s*:\s*(\w+)/)
		{
			my $LineItem = $1;
			my $FuseData = $2;
			$LineItems{$LineItem} = $FuseData;
		}

		if (/QDF_SSPEC_DEF\s*:\s*(\w+)\s*:\s*(\w+)\s*:\s*/)
		{
			my $SspecLineItem = $1;
			my $LineItem = $2;
			$SspecLineItems{$SspecLineItem} = $LineItem;
		}
	}
	close FUSESSPEC;

	foreach my $SspecLineItem (keys %SspecLineItems)
	{
		foreach my $LineItem (keys %LineItems)
		{
			if ($LineItem eq $SspecLineItems{$SspecLineItem})
			{
				$SspecFuseDatas{$SspecLineItem} = $LineItems{$LineItem};
				last;
			}
		}
	}

	(%LineItems, %SspecLineItems) = ();

	# Map current SSPEC/QDF with correct FuseData
	foreach my $Sspec (keys %SspecFuseDatas)
	{
		print "$Sspec : $SspecFuseDatas{$Sspec}\n" if ($Verbose);

		if ($CurQDF eq $Sspec)
		{
			$QDFFound = 1;
			$CurFuseData = $SspecFuseDatas{$Sspec};
			print "$CurQDF = $SspecFuseDatas{$Sspec}\n" if ($Debug);
			last;
		}
	}

	if (!$QDFFound)
	{
		print "Can't find QDF: $CurQDF in fuse file\n";
		exit 0;
	}
}

