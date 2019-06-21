
use File::Copy;
use Win32::OLE qw(in with);
use Win32::OLE::Const;
use Win32::OLE::Const 'Microsoft PowerPoint';
#$Win32::OLE::Warn = 3;

my $OrigFile = 'C:\Perl\programs\Print.ppt';
my $OutFile = 'C:\Perl\programs\temp.ppt';
copy ($OrigFile, $OutFile) or die "Cannt copy $OrigFile to $OutFile : $!\n";

&Powerpoint();

sub Powerpoint
{
	my $Powerpoint = Win32::OLE->new('Powerpoint.Application', \&OleQuit) or die "Cann't open the Powerpint: $!\n";
	my $Powerpoint = Win32::OLE->GetActiveObject('Powerpoint.Application') || Win32::OLE->new('Powerpoint.Application', 'Quit');
	$Powerpoint->{Visible} = 1;
	#$Powerpoint -> Presentation->Add();
	$Powerpoint->Presentations->Open({FileName => $OutFile});	

	#my $Powerpoint2 = $Powerpoint->Presentations->Open({FileName => $OutFile});
	my $Slide = $Powerpoint->Slides(1);
	#my $TextBox=$Slide->Shapes->AddTextBox({Orientation=>1, Left=> 24, Top=> 48, Width=> 192,Height=> 28.875,});
	                                      

	#my $Text = $Slide->Shapes("Rectangle 3");

	#foreach my $Shape(in $Slide->Shapes)
	#{
	#	$Shape->Delete if $Shape->{Height} <= 20;
	#}
		  

	$Powerpoint->SaveAs($OutFile);
	$Powerpoint->Close;
}

sub OleQuit 
{
	my $self = shift;
	$self->Quit;
}