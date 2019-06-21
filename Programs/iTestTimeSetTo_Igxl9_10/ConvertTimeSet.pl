#####################################################################################################################
#																													#
#	Rev0.0																											#
#	Script: ConvertTimeSet.pl																						#
#																													#
#	Description: 																									#
#		Igxl9.10 has additional timeset compare to igxl8.x and different header on Windows.							#
#		This script is written to convert timeset download from iTest (compatible to igxl8.x) to igxl9.10 format.	#
#																													#
#	Written by Lye Cheung Foo																						#
#	Date: 26 February 2019																							#
#																													#
#####################################################################################################################
use strict;
use warnings;
use Cwd;
my $Dir = getcwd;
my $SourceDir = $Dir . "/input"; 
my $OutputDir = $Dir . "/output";
foreach my $File (<"$SourceDir/*">)
{
	print "Processing $File ...\n";
	my $FoundFlag = 0;
	
	# Header
	my $Header = "";
	
	# To create output file
	my $OutFile = $File;
	$OutFile =~ s{.*/}{};
	$OutFile = $OutputDir . "/" . $OutFile;
	
	open (OUT, ">$OutFile") || die "Cant open $OutFile : $!\n";
	open (FILE, $File) || die "Can't open $File : $!\n";
	while (<FILE>)
	{
		chomp();
		if (/Timing\s+Mode.*Single/ig)
		{
			$Header = "DTTimesetBasicSheet,version=2.3:platform=Jaguar:toprow=-1:leftcol=-1:rightcol=-1	Time Sets (Basic)																	
																		
	Timing Mode:	Single		Master Timeset Name:														
	Time Domain:			Strobe Ref Setup Name:														
																		
		Cycle	Pin/Group			Data		Drive				Compare				Edge Resolution		
	Time Set	Period	Name	Clock Period	Setup	Src	Fmt	On	Data	Return	Off	Mode	Open	Close	Ref Offset	Mode	Comment	\n";

		}
		elsif (/Timing\s+Mode.*Dual/ig)
		{
			$Header = "DTTimesetBasicSheet,version=2.3:platform=Jaguar:toprow=-1:leftcol=-1:rightcol=-1	Time Sets (Basic)																	
																		
	Timing Mode:	Dual		Master Timeset Name:														
	Time Domain:			Strobe Ref Setup Name:														
																		
		Cycle	Pin/Group			Data		Drive				Compare				Edge Resolution		
	Time Set	Period	Name	Clock Period	Setup	Src	Fmt	On	Data	Return	Off	Mode	Open	Close	Ref Offset	Mode	Comment	\n";

		}

		if (/\s+Time\s+Set\s+Period\s+Name\s+Clock\s+Period/)
		{
			$FoundFlag = 1;
			print OUT $Header;
			next;
		}
		
		if ($FoundFlag)
		{		
			$_ =~ s/(.*\t\S+)\tAuto/$1\t\tAuto/g;
			$_ =~ s/(.*\t\S+)\t\t\tAuto/$1\t\t\t\tAuto/g;
			print OUT "$_\n";			
		}
	}
	close FILE;
	close OUT;
	
	print "Generated $OutFile\n";
	print " ***** Done! *****\n";
}