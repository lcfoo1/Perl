#use strict;
#use warnings;
use Spreadsheet::XLSX;
use Data::Dumper;

my $ExcelFile = 'ACT_C_SCAN_INTEST_STKAT_FLOW.xlsx';
#my $excel = Spreadsheet::XLSX -> new ($ExcelFile,);
#my $excel = Spreadsheet::XLSX -> new ('A.xlsx',);
my $excel = Spreadsheet::XLSX -> new ('c:\Perl\Programs\CompareTPADTP\R_ACT_Extest_Clamp_flow.xlsx',);

foreach my $sheet (@{$excel -> {Worksheet}}) 
{ 
	#State	Action	Condition	TRUE	FALSE	Bin_Status	Bin_Output_Type	Hard_Bin	Soft_Bin	Counter	Bypass
        printf("Sheet: %s\n", $sheet->{Name});
	print $sheet -> {MinRow} . " and " . $sheet -> {MaxRow} . "\n".
	$sheet -> {MaxRow} ||= $sheet -> {MinRow};
        foreach my $row ($sheet -> {MinRow} .. $sheet -> {MaxRow}) 
	{
		$sheet -> {MaxCol} ||= $sheet -> {MinCol};	
                foreach my $col ($sheet -> {MinCol} ..  $sheet -> {MaxCol}) 
		{
			my $cell = $sheet -> {Cells} [$row] [$col]; 
			if ($cell) 
			{
                            printf("( %s , %s ) => %s\n", $row, $col, $cell -> {Val});
                        } 
                } 
        } 
}




