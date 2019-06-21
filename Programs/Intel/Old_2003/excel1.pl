
# This script is to create the Excel sheet
use Win32::OLE;
use Win32::OLE::Variant;

&MyExcel();

sub MyExcel
{
	unless (defined $ex) 
	{
		$ex = Win32::OLE->new('Excel.Application', sub {$_[0]->Quit;}) or die "Oops, cannot start Excel";
		$ex = Win32::OLE->GetActiveObject('Excel.Application');
	}

	$book = $ex->Workbooks->Add;
	$sheet = $book->Worksheets(1);
	$sheet->Cells(1,1)->{Value} = "foo";        

	# write a 2 rows by 3 columns range
	$sheet->Range("A8:C9")->{Value} = [[ undef, 'Xyzzy', 'Plugh' ], [ 42, 'Perl',  3.1415  ]];
	$array = $sheet->Range("A8:C9")->{Value};

	for (@$array) 
	{
		for (@$_) 
		{
			print defined($_) ? "$_|" : "<undef>|";
		}
		print "\n";
	}        # save and exit

	$book->SaveAs( 'C:\Perl\Programs\test.xls' );
	$book->Close;
	undef $book;
	undef $ex;

}
