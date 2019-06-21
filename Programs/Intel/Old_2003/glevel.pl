#################################################################
#								#
# Foo Lye Cheung			22 June 2005		#
# This script to get create the excel sheet for the level	#
#								#
#################################################################
use strict;
use warnings;
my $InFile = "Psc.lvl";
my $OutFile = "Level.csv";


open (OUT, ">$OutFile") || die "Cant open outfile $OutFile : $!\n";
open (IN, $InFile) || die "Cant open infile $InFile : $!\n";
while (<IN>)
{
START:
	my $Count = 0;
	my $Flag = 0;

	if (/Levels\s+(\S+)/i)
	{
		my $Level = $1;
		my $Line = "";
		my $Data = "";
		$Count++;
		while (<IN>)
		{
			s/(\s+|;)//g;
			$Data = $_ if (($_ !~ /\{/) && $Count == 2);
			if (/\{/)
			{
				$Line = $Level . "," . $Data ;
				$Flag = 0;
				$Count++;
				next;
			}					
			if (/\}/)
			{
				$Flag = 1;
				$Count--;
				print OUT "$Line\n" if ($Count != 1);
			}
			
			if ((!$Flag) && ($Count != 2))
			{
				$Line .= "," . $_;
			}

			if ($Count == 1)
			{
				goto START;
			}
		}
	}
}
close IN;
close OUT;
