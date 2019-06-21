use strict;
use warnings;
use Cwd;
use File::Find;
use Spreadsheet::XLSX;

my @ExcelFiles = ();
my %DataTables = ();
#my $Path = 'C:\Perl\Programs\CompareTPADTP\ZeroBin_Detection';
my $Path = 'C:\intel\hdmtprogs\vlv\staging\VLVTA3PB0HM004B3\Modules';
&Main();

# Main script
sub Main
{
	# Find from the path
	finddepth(\&GetXLSXFiles, $Path);

	# Loop though the files
	foreach my $ExcelFile (@ExcelFiles)
	{
		&ReadExcel($ExcelFile);
	}

	# Dump all the data
	foreach my $DataTable (keys %DataTables)
	{
		#print "$DataTable\n";
		no warnings;
		my $Line = join (',', @{$DataTables{$DataTable}});
		print "$Line\n";
	}
}

# Function to read Excel
sub ReadExcel
{
	my $File = shift;
	my $Excel = Spreadsheet::XLSX -> new ($File,);
	foreach my $sheet (@{$Excel -> {Worksheet}}) 
	{ 
		#State	Action	Condition	TRUE	FALSE	Bin_Status	Bin_Output_Type	Hard_Bin	Soft_Bin	Counter	Bypass
		#printf("Sheet: %s\n", $sheet->{Name});
		$sheet -> {MaxRow} ||= $sheet -> {MinRow};
		my $RowTest = "";
	        foreach my $row ($sheet -> {MinRow} .. $sheet -> {MaxRow}) 
		{
			$sheet -> {MaxCol} ||= $sheet -> {MinCol};	
			my $cell = $sheet -> {Cells} [$row] [2];
			if ($cell)
			{
				my ($Module, $FileName) = ($1, $2) if ($File =~/\/(\w+)\/Input_Files\/(\w+.xlsx)/ig);

				no warnings;
				my ($Condition, $True, $False, $BinStatus, $BinOutput, $HardBin, $SoftBin) = ("","","","","","","");
				$Condition = $sheet -> {Cells} [$row] [2] -> {Val};
				$True = $sheet -> {Cells} [$row] [3] -> {Val};
				$False = $sheet -> {Cells} [$row] [4] -> {Val};
				$BinStatus = $sheet -> {Cells} [$row] [5] -> {Val};
				$BinOutput = $sheet -> {Cells} [$row] [6] -> {Val};
				$HardBin = $sheet -> {Cells} [$row] [7] -> {Val};
				$SoftBin = $sheet -> {Cells} [$row] [8] -> {Val};

				if ($BinStatus =~ /F/i)
				{
					#print "$Module, $FileName, $sheet->{Name}, $Condition, $True, $False, $BinStatus, $BinOutput, $HardBin, $SoftBin\n";
					my $Key = $File . "_ROW" . $row;
					$DataTables {$Key} = [$Module, $FileName, $RowTest, $sheet->{Name}, $Condition, $True, $False, $BinStatus, $BinOutput, $HardBin, $SoftBin];
				}
			}
			$RowTest =  $sheet -> {Cells} [$row] [0] -> {Val}
	        } 
	}
}

# Get Excel files
sub GetXLSXFiles
{
	if ((-f $File::Find::name) && (($File::Find::name =~ /Input_Files\/R_.*\.xlsx/i)))
	{
		my $File = $File::Find::name;
		$File =~ s/\\/\//g;
		#print "Found $File\n";
		push (@ExcelFiles, $File);
	}
}

