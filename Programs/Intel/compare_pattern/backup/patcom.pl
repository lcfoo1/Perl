#!/usr/intel/bin/perl
#########################################################################################################
#													#
#	Foo Lye Cheung					PDE CPU OAP (TMM)				#
#	18 Jan 2006											#
#	604-2536452											#
#													#
#	This script is to compare reference and compare file (pattern or preamble)			#
#	(use for CWA and CKT)										#
#													#
#	Usage: $0 [-h] [-p mode] [-r Reference_File] [-c Compare_File] 					#
#	-h        	: this (help) message								#
#	-p mode			: input mode - pat (pattern) / pre (preamble)				#
#	-r Reference_File	: reference file containing vectors					#
#	-c Compare_File		: compare file containing vectors					#
#													#
#	Example: $0 -p pat -r Reference_File -c Compare_File						#
#	   												#
#	Rev 0.0												#
#													#
#########################################################################################################

use Getopt::Std;

#my $File1 = 'd0750863H003045_010604c_MB0548aj_0fxxxx0xhhcx0xxxxxPfrxM5_dft_idcode_OBR1.pat.data';
#my $File2 = 'd0651829H003045_010604c_MB0548aj_0fxxxx0xhhcx0xxxxxFfrxI5_dft_idcode_OBR1.pat.data';
my %Data1 = ();
my %Data2 = ();

getopts("c:hp:r:", \%opt ) or Usage();
&Usage() if defined ($opt_h || $opt{h});

my $File1 = $opt_r || $opt{r};
my $File2 = $opt_c || $opt{c};
my $Mode = $opt_p || $opt{p};

if (defined $File1)
{
	if (defined $File2)
	{
		if (($Mode eq "pat") && (-e $File1) && (-e $File2))
		{
			&Main(0);
			&Compare();
		}
		elsif (($Mode eq "pre") && (-e $File1) && (-e $File2))
		{
			&Main(1);
			&Compare();
		}
		else
		{
			print "Please check you input filename ($File1 or $File2)\n";
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

sub Compare
{
	my $PinFlag = 0;
	foreach $Pin (keys %Data1) 
	{
		foreach $Cycle (0 .. $#{$Data1{$Pin}})
		{
			my $DataFile1 = $Data1{$Pin}[$Cycle];
			my $DataFile2 = $Data2{$Pin}[$Cycle];
			
			if ($DataFile1 eq $DataFile2)
			{
				#print "Same $Data1{$Pin}[$Cycle] ";
			}
			else
			{
				my ($Bit1, $Addr1) = split (/\_/, $DataFile1);
				my ($Bit2, $Addr2) = split (/\_/, $DataFile2);

				unless ((($Bit1 eq "") && ($Addr1 eq "")) || (($Bit2 eq "") && ($Addr2 eq "")))
				{
					if (!$PinFlag)
					{
						print "$Pin have different bits\n";
						print "File 1: $File1\nFile 2: $File2\n";
						$PinFlag = 1;
					}
					print "$Bit1 - address $Addr1 : $Bit2 - address $Addr2\n";
				}
			}
		}
		$PinFlag = 0;
	}
}

sub Main
{
	my $PatOrPre = shift;
	my $Pattern_Start = 0;
	my @HozHeaders = ();
	my $PinMatch = "";
	
	if (!$PatOrPre)
	{
		$PinMatch = "ALLPINs=";
	}
	else
	{
		$PinMatch = "ALLPINs=c";
	}

	if (!$PatOrPre)
	{
		open (IN, $File1) || die "Cant open $File1 : $!\n";
		while (<IN>)
		{
			chomp;
			if (/#(.*)/)
			{
				chomp;
				my $VerticalPins = $1;
				my $TmpLen = length ($VerticalPins);
				$StrLenMax = $TmpLen if ($StrLenMax < $TmpLen);
				next if ((/VCF/) || (/VMLI/));
				push (@Headers, $VerticalPins);
			}
		
			if (($_ !~ /#/) && ($. >10))
			{
				print "Start line $File1 data $.\n";
				$Pattern_Start = $.;
				@HozHeaders = &GetHeader($StrLenMax,@Headers);		
				last;
			}
		}
		close IN;
	}
	else
	{
		my $PxrNum = -1;
		my $HeaderNum = -1;
		open (IN, $File1) || die "Cant open $File1 : $!\n";
		while (<IN>)
		{
			chomp;
			$PxrNum = $. if (/pxr/);
			if ((/#(.*)/) && ($PxrNum > 0))
			{
				chomp;
				my $VerticalPins = $1;
				my $TmpLen = length ($VerticalPins);
				$StrLenMax = $TmpLen if ($StrLenMax < $TmpLen);
				$HeaderNum = $.;
				next if ((/VCF/) || (/VMLI/));
				push (@Headers, $VerticalPins);
			}
		
			if (($_ !~ /#/) && ($. >10) && ($HeaderNum > 0))
			{
				print "Start line $File1 data $.\n";
				$Pattern_Start = $.;
				@HozHeaders = &GetHeader($StrLenMax,@Headers);		
				last;
			}
		}
		close IN;
	}


	open (IN, $File1) || die "Cant open $File1 : $!\n";
	while (<IN>)
	{
		chomp;
		next if ($_ =~ /#/);
		
		if (($. > $Pattern_Start) && (/(\S+)\s+\{(.*)\}/))
		{
			
			if (/$PinMatch(.*)/i)
			{	
				my $Bits = $1;
				my $count = 0;
				my @DataCol = split(//, $Bits);
				$Bits = <IN>;
				chomp ($Bits);
				my @Addr = split(/#/,$Bits);
				$Addr[3] =~ s/\s+//g;
				foreach $Column (@DataCol)
				{
					push @{$Data1{$HozHeaders[$count]}}, "${Column}_${Addr[3]}";
					$count++;
				}
			}				
		}
	}
	close IN;

	# Flush the pin data
	@Headers = ();
	@HozHeaders = ();
	$StrLenMax = 0;

	if (!$PatOrPre)
	{
		open (IN2, $File2) || die "Cant open $File2 : $!\n";
		while (<IN2>)
		{
			chomp;
			if (/#(.*)/)
			{
				chomp;
				my $VerticalPins = $1;
				my $TmpLen = length ($VerticalPins);
				$StrLenMax = $TmpLen if ($StrLenMax < $TmpLen);
				next if ((/VCF/) || (/VMLI/));
				push (@Headers, $VerticalPins);
			}
	
			if (($_ !~ /#/) && ($. >10))
			{
				print "Start line $File2 data $.\n";
				$Pattern_Start = $.;
				@HozHeaders = &GetHeader($StrLenMax,@Headers);		
				last;
			}
		}
		close IN2;
	}
	else
	{
		my $PxrNum = -1;
		my $HeaderNum = -1;
		open (IN2, $File2) || die "Cant open $File2 : $!\n";
		while (<IN2>)
		{
			chomp;
			$PxrNum = $. if (/pxr/);
			if ((/#(.*)/) && ($PxrNum > 0))
			{
				chomp;
				my $VerticalPins = $1;
				my $TmpLen = length ($VerticalPins);
				$StrLenMax = $TmpLen if ($StrLenMax < $TmpLen);
				$HeaderNum = $.;
				next if ((/VCF/) || (/VMLI/));
				push (@Headers, $VerticalPins);
			}
		
			if (($_ !~ /#/) && ($. >10) && ($HeaderNum > 0))
			{
				print "Start line $File2 data $.\n";
				$Pattern_Start = $.;
				@HozHeaders = &GetHeader($StrLenMax,@Headers);		
				last;
			}
		}
		close IN2;
	}

	open (IN2, $File2) || die "Cant open $File2 : $!\n";
	while (<IN2>)
	{
		chomp;
		next if ($_ =~ /#/);
		
		if (($. > $Pattern_Start) && (/(\S+)\s+\{(.*)\}/))
		{
			if (/$PinMatch(.*)/i)
			{	
				my $Bits = $1;
				my $count = 0;
				my @DataCol = split(//, $Bits);
				$Bits = <IN2>;
				chomp ($Bits);
				my @Addr = split(/#/,$Bits);
				$Addr[3] =~ s/\s+//g;
				foreach $Column (@DataCol)
				{
					push @{$Data2{$HozHeaders[$count]}}, "${Column}_${Addr[3]}";
					$count++;
				}
				
			}
		}
	}
	close IN2;
}
 

# Subroutine to change the pin header from vertical to horizontal
sub GetHeader
{
	my ($StrLenMax, @Headers) = @_;
	my @FoundPins = ();
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
		next if ($Pin eq "");
		push (@FoundPins, $Pin);
	}

	return (@FoundPins);
}


# Help message of the usage
sub Usage
{
	my $Help = "\nHelp:\n=====
Usage: $0 [-h] [-p mode] [-r Reference_File] [-c Compare_File] 

-h        		: this (help) message
-p mode			: input mode - pat (pattern) / pre (preamble)
-r Reference_File	: reference file containing vectors
-c Compare_File		: compare file containing vectors

Example: $0 -p pat -r Reference_File -c Compare_File\n";

	print "$Help\n";
	exit 0;
}

