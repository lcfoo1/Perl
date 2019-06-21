


use strict;
use warnings;

use Cwd;
use File::Find;

my $Dir = getcwd . '/dap';
my $SBF_pgm_rules = getcwd . '/sbf_pgm.txt';
my @BinFiles = ();

finddepth(\&GetFiles, $Dir);
&Main();


sub Main
{
	open (OUT, ">$SBF_pgm_rules") || die "Can't open $SBF_pgm_rules : $!\n";
	foreach my $BinFile (@BinFiles)
	{
		my $BOM = $1 if ($BinFile =~ /(\w+)\.bins$/);
		my @BOMS = split (//, $BOM);
	
		print "$BOM\n";
		print OUT "#$BOM\n";
		#BZ4KEHBVBB.bins
		#BZ,4,K,E/T/U,H,B,V,B,B,*,*,*,*
		# Field1 : Package
		# Field2 : SampleType
		# Field3 : ProcessorFamily
		# Field4 : MarketSegment
		# Field5 : CacheSize
		# Field6 : BinMatrix
		# Field7 : VirtualFactory
		# Field8 : Revision
		# Field9 : Stepping
		# Field10: EngID
		# Field11: Fab
		# Field12: SSpec
		# FieldLocn :
		#
		# Programming Format :
		# VarName = VarValue/paramvalue,  Global/Template/Levels/Timing,  Instance/usrvcollection/TestCondition :  Fld1, Fld2, Fld3, Fld4, Fld5, Fld6, Fld7, Fld8, Fld9, Fld10, Fld11, Fld12, FldLocn

		my %TestInstances = ();

		my ($Package, $SampleType, $ProcessorFamily, $MarketSegment, $CacheSize, $BinMatrix, $VirtualFactory, $Revision, $Stepping) = "";
		$Package =  $BOMS[0] . $BOMS[1];
		$SampleType = $BOMS[2];
		$ProcessorFamily = $BOMS[3];
		$MarketSegment = $BOMS[4]; 
		$CacheSize = $BOMS[5];
		$BinMatrix = $BOMS[6];
		$VirtualFactory = $BOMS[7];
		$Revision = $BOMS[8];
		$Stepping = $BOMS[9];

		open (BINFILE, $BinFile) || die "Can't open $BinFile : $!\n";
		while (<BINFILE>)
		{
			chomp;
			if (/S\d\_\S+\s*(\w+_SBF_\w+)(\s*|,)/ig)
			{
				my $Tmp = $1;
				$TestInstances{$Tmp} = 1;
			}
		}
		close BINFILE;

		foreach my $TestInstance (keys %TestInstances)
		{
	
			my $DefaultStr = "use_previous_empty_history = \"EMPTY\",\ttemplate,\t$TestInstance\t:\t$Package,$SampleType,$ProcessorFamily,$MarketSegment,$CacheSize,$BinMatrix,$VirtualFactory,$Revision,$Stepping,*,*,*,*/-773?/-774?/-775?/-7764/-7765/-7766/-7780/-7783/-7784/-7787/-7788/-779?";
			my $HistoryStr = "use_previous_empty_history = \"HISTORY\",\ttemplate,\t$TestInstance\t:\t$Package,$SampleType,$ProcessorFamily,$MarketSegment,$CacheSize,$BinMatrix,$VirtualFactory,$Revision,$Stepping,*,*,*,773?/774?/775?/7764/7765/7766/7780/7783/7784/7787/7788/779?";
			print OUT "$DefaultStr\n$HistoryStr\n";
		}
		%TestInstances = ();

	}
	close OUT;
}

# Get all the dap files
sub GetFiles
{
	if ((-f $File::Find::name) && ($File::Find::name =~ /\.bins$/g))
	{
		my $File = $File::Find::name;
		$File =~ s/\\/\//g;
		push (@BinFiles, $File) unless ($File::Find::name =~ /dapmap.bins/);
	}
}
