
use Win32::GuiTest qw(FindWindowLike GetWindowText SetForegroundWindow SendKeys);

$Win32::GuiTest::debug = 0; # Set to "1" to enable verbose mode

my @windows = FindWindowLike(0, "^My Computer", "^XLMAIN\$");
for (@windows) 
{
	print "$_>\t'", GetWindowText($_), "'\n";
	SetForegroundWindow($_);
	SendKeys("%fn~{TAB}{TAB}{BS}{DOWN}");
}
      
