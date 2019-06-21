# Title: Traceability Analysis & Reporting
# Author: CY Gan (i-Net: 8-253-6573)
# Last update: 12/29/2003
# Perl on Win32 with GUI
#
# 5/26/2004
#	include 9996 & 9997 for shipping locations
#
# 12/16/2003
#       TAR access MARS StoredProc directly, bypass WLTT
#
# WIP Lot Tracking Traceability Criteria:
#               CW lot := FPO with Qty = 0 and Operation = 1
#               X-ship lot := ATPO with Qty = 0 and Operation = 1 
#                       ie: ATPO Lot with Prev.Location = 1209, shipped to other site after Die Prep
#               WIP := ATPO or FPO with Qty > 0
#

#system(cls);
use Win32;
use Win32::GUI;
use Win32::OLE qw(in with);
use Win32::OLE::Const 'Microsoft Excel';
$Win32::OLE::Warn = 3;
$user = Win32::LoginName;
$system = Win32::NodeName;
$curdir = Win32::GetCwd;
$curdir = 'C:\Program Files\tar';
$domain = Win32::DomainName;
$thisversion = "3.01";
&checkToolStatus;

$I = new Win32::GUI::Icon("TAR.ico");

$WC = new Win32::GUI::Class(
    -name => "Window_Class", 
    -icon => $I,
);

$F = new Win32::GUI::Font(
	-name => "Arial",
	-size => 8,
	-bold => 0,
);

$M = new Win32::GUI::Menu(
    "&File"   => "mnuFile",
    " > Load List For &Traceability" => "mnuLoadList",
    " > -" => "mnuSeparator1",
    " > &Save Setup" => "mnuSaveSetup",
    " > &Load Setup" => "mnuLoadSetup",
    " > &View TAR Log" => "mnuViewLog",
    " > -" => "mnuSeparator2",
    " > E&xit TAR" => "mnuExit",
    "&Autorun" => "mnuAutorun",
    " > Autorun WIP Lot Tracking (&Single Site)" => "mnuAutorunHublean",
    " > Autorun WIP Lot Tracking (&Multiple Sites)" => "mnuAutorunCycle",
    "&Tools" => "mnuTools",
    " > Tracking Crawl &Backward" => "mnuCrawlBackwardToLoc",
    #" > Trac&king Crawl Backward" => "mnuTrackCrawlBackwardToLoc",
    "&Help" => "mnuHelp",
    " > &Support Contact" => "mnuSupport",
    "$system: $domain\\$user" =>  "mnuDummy",
);

$Window = new Win32::GUI::Window(
    -name   => "Window",
    -minsize => [623,640],
    -left   => 200, 
    -top    => 80,
    -width  => 623,
    -height => 640,
    -text   => "Traceability Analysis & Reporting $thisversion",
    -font   => $F,
    -menu     => $M,
    -class => $WC,
);
$Window->{-dialogui} = 1;

################ Window Pop Up #############
$Winpopup1 = new Win32::GUI::Window(
    -name   => "Winpopup1",
    -minsize => [260,60],
    -maxsize => [260,60],
    -left   => 350, 
    -top    => 300,
    -width  => 260,
    -height => 60,
    -text   => "Enter Operation Code",
    -font   => $F,
    -class => $WC,
    -topmost => 1,
);
$Winpopup1->{-dialogui} = 1;

$lblOperCode = $Winpopup1->AddLabel(
    -text   => "To ",
    -left   => 5,
    -top    => 7,
);

$txtOperCode = $Winpopup1->AddTextfield(
    -name     => "txtOperCode",
    -left     => 25,
    -top      => 5,
    -width    => 95,
    -height   => 22,
    -tabstop => 1,
);

$btnSubmitOperCode = $Winpopup1->AddButton(
        -name => "btnSubmitOperCode",
        -text => "Submit",
        -left => 130,
        -top => 5,
        -width    => 50,
        -height   => 22,
        -tabstop => 1,
);

$btnCancelOperCode = $Winpopup1->AddButton(
        -name => "btnCancelOperCode",
        -text => "Cancel",
        -left => 190,
        -top => 5,
        -width    => 50,
        -height   => 22,
        -tabstop => 1,
);

################

$tabStrip = $Window->AddTabStrip(
    -name   => "Tab",
    -left   => 0,   
    -top    => 0, 
    -width  => $Window->ScaleWidth, 
    -height => $Window->ScaleHeight - 20,
);

$Window->Tab->InsertItem(
    -name => "tabMain",
    -text => "Traceability And Risk Assessment",
);
$Window->Tab->InsertItem(
    -name => "tabDataTransform",
    -text => "Data Transformation", 
);

# WIP Lot Tracking setup
$grpHubleanSetup = $Window->AddGroupbox(
	-name   => "grpHubleanSetup",
	-left   => 5,
	-top    => 25,
	-width  => 605,
	-height => 45,
	-text   => "WIP Lot Tracking Setup",
);

$lblHubleanSite = $Window->AddLabel(
    -text   => "SITE:",
    -left   => 10,
    -top    => 45,
);

$cmbSite = $Window->AddCombobox( 
    -name   => "cmbSite",
    -left   => 39, 
    -top    => 42,
    -width  => 42, 
    -height => 100,
    -style  => WS_VSCROLL | WS_VISIBLE | 2 | WS_NOTIFY,
    -tabstop => 1,
    -visible => 1,
);
$cmbSite->InsertItem("PG");
$cmbSite->InsertItem("KM");
# $cmbSite->InsertItem("CH");
$cmbSite->InsertItem("CR");
$cmbSite->InsertItem("CV");
$cmbSite->InsertItem("PD");
$cmbSite->Select(0);
#$hubleansite = "MARSPROD"; # default is PG
$hubleansite = "PG_MARSPROD"; # default is PG
$hubleansitecode = "PG";

$lblHubleanReport = $Window->AddLabel(
    -text   => "REPORT:",
    -left   => 90,
    -top    => 45,
);
$lblHubleanReport->Enable(0);

$cmbRptOption = $Window->AddCombobox( 
    -name   => "cmbRptOption",
    -left   => 140, 
    -top    => 42,
    -width  => 77, 
    -height => 100,
    -style  => WS_VISIBLE | 2 | WS_NOTIFY,
    -tabstop => 1,
    -visible => 1,
);
$cmbRptOption->InsertItem("Forward");
$cmbRptOption->InsertItem("Backward");
$cmbRptOption->Select(0);
$rptoption = "T"; # default is forward
$cmbRptOption->Enable(0);

$cmbReport = $Window->AddCombobox( 
    -name   => "cmbReport",
    -left   => 217, 
    -top    => 42,
    -width  => 85, 
    -height => 100,
    -style  => WS_VISIBLE | 2 | WS_NOTIFY,
    -tabstop => 1,
    -visible => 1,
);
$cmbReport->InsertItem("Traceability");
$cmbReport->InsertItem("Tracking");
$cmbReport->Select(0);
$report = "TRACE"; # default is trace
$cmbReport->Enable(0);

$lblRptDesc = $Window->AddLabel(
    -text   => "(Tree Format)",
    -left   => 312,
    -top    => 45,
    -width => 95,
);
$lblRptDesc->Enable(0);

$lblLotOwner = $Window->AddLabel(
    -text   => "OWNER:",
    -left   => 412,
    -top    => 45,
);
$lblLotOwner->Enable(0);

$cmbLotOwner = $Window->AddCombobox( 
    -name   => "cmbLotOwner",
    -left   => 459, 
    -top    => 42,
    -width  => 60, 
    -height => 100,
    -style  => WS_VISIBLE | 2 | WS_NOTIFY,
    -tabstop => 1,
    -visible => 1,
);
$cmbLotOwner->InsertItem("BOTH");
$cmbLotOwner->InsertItem("PROD");
$cmbLotOwner->InsertItem("ENG");
$cmbLotOwner->Select(0);
$lotowner = "BOTH";
$cmbLotOwner->Enable(0);

$lblMaxLot = $Window->AddLabel(
    -text   => "Max:",
    -left   => 527,
    -top    => 45,
);

$cmbMaxLot = $Window->AddCombobox( 
    -name   => "cmbMaxLot",
    -left   => 555, 
    -top    => 42,
    -width  => 38, 
    -height => 100,
    -style  => WS_VSCROLL | WS_VISIBLE | 2 | WS_NOTIFY,
    -tabstop => 1,
    -visible => 1,
);
for ($i = 1; $i <= 10; $i++) {
        $cmbMaxLot->InsertItem("$i");
}
# change to 1 lot/run for data extraction
# $cmbMaxLot->InsertItem("1");
$cmbMaxLot->Select(0);
$maxlot = 1;
# end of hublean setup group

# start of other setup group
$grpPathSetup = $Window->AddGroupbox(
	-name   => "grpPathSetup",
	-left   => 5,
	-top    => 70,
	-width  => 603,
	-height => 130,
	-text   => "Path Setup",
);

$btnHubleanPath = $Window->AddButton(
        -name => "btnHubleanPath",
        -text => "WIP LOT Storage",
        -left => 12,
        -top => 90,
        -width    => 110,
        -tabstop => 1,
        -disabled => 1,
        -visible => 0,
);

$txtHubleanPath = $Window->AddTextfield(
    -name     => "txtHubleanPath",
    -left     => 130,
    -top      => 92,
    -width    => 465,
    -height   => 20,
    -readonly => 1,
    -text     => "$server{'WLTTStorage'}",
    -tabstop => 1,
    -disabled => 1,
    -visible => 0,
);
$hubleanpath = "$server{'WLTTStorage'}";

$btnPHQFormPath = $Window->AddButton(
        -name => "btnPHQFormPath",
        -text => "PHQ Form",
        -left => 12,
        -top => 90,
        -width    => 110,
        -tabstop => 1,
);

$txtPHQFormPath = $Window->AddTextfield(
    -name     => "txtPHQFormPath",
    -left     => 130,
    -top      => 92,
    -width    => 465,
    -height   => 20,
    -readonly => 1,
    -tabstop => 1,
);
if (-e "$curdir\\PHQForm.xls") {
        $phqformpath = $curdir;
        $phqform = 'PHQForm.xls';
        $txtPHQFormPath->Text("$phqformpath\\$phqform");
}

$btnCentralPath = $Window->AddButton(
        -name => "btnCentralPath",
        -text => "SSPECvsMM File",
        -left => 12,
        -top => 115,
        -width    => 110,
        -tabstop => 1,
);

$txtCentralPath = $Window->AddTextfield(
    -name     => "txtCentralPath",
    -text     => "$server{'TARServer'}",
    -left     => 130,
    -top      => 117,
    -width    => 465,
    -height   => 20,
    -tabstop => 1,
);
$centralpath = $server{'TARServer'};

$btnTracePath = $Window->AddButton(
        -name => "btnTracePath",
        -text => "Data Storage",
        -left => 12,
        -top => 140,
        -width    => 110,
        -tabstop => 1,
);

$txtTracePath = $Window->AddTextfield(
    -name     => "txtTracePath",
    -left     => 130,
    -top      => 142,
    -width    => 465,
    -height   => 20,
    -tabstop => 1,
);

$btnSaveSetup = $Window->AddButton(
        -name => "btnSaveSetup",
        -text => "Save Setup",
        -left => 180,
        -top => 170,
        -width    => 100,
        -tabstop => 1,
);

$btnLoadSetup = $Window->AddButton(
        -name => "btnLoadSetup",
        -text => "Load Setup",
        -left => 320,
        -top => 170,
        -width    => 100,
        -tabstop => 1,
);
# end of other setup group

# start of option checkboxes
$chkWIPTracking = $Window->AddCheckbox(
        -name => "chkWIPTracking",
        -text => "Customize Trace/Track",
        -left => 10,
        -top => 210,
        -check => 0,
        -tabstop => 1,
);

# end of option checkboxes

# start of TAR
$grpTools = $Window->AddGroupbox(
        -name => "grpTools",
        -left => 5,
        -top => 230,
        -width => 365,
        -height => 205,
        -tabstop => 1,
);

$btnTraceHublean = $Window->AddButton(
        -name => "btnTraceHublean",
        -text => "Go",
        -left => $grpTools->Left + 5,
        -top => $grpTools->Top + 13,
        -disabled => 1,
        -tabstop => 1,
);

$lblTraceHublean = $Window->AddLabel(
    -text   => "Launch WIP LOT Traceability For",
    -left   => $grpTools->Left + 45,
    -top    => $grpTools->Top + 17,
);

$dirtylot = "\<Click Here To Load File\>";
$btnDirtyLot = $Window->AddButton(
        -name => "btnDirtyLot",
        -text => "$dirtylot",
        -left => $grpTools->Left + 210,
        -top => $grpTools->Top + 13,
        -tabstop => 1,
);

$btnCrawlForward = $Window->AddButton(
        -name => "btnCrawlForward",
        -text => "Go",
        -left => $grpTools->Left + 5,
        -top => $grpTools->Top + 38,
        -tabstop => 1,
);

$lblCrawlForward = $Window->AddLabel(
    -text   => "Traceability Post Process - Crawl Forward",
    -left   => $grpTools->Left + 45,
    -top    => $grpTools->Top + 42,
);

$btnSaveCrawlForward = $Window->AddButton(
        -name => "btnSaveCrawlForward",
        -text => "Go",
        -left => $grpTools->Left + 5,
        -top => $grpTools->Top + 63,
        -disabled => 1,
        -tabstop => 1,
);

$lblSaveCrawlForward = $Window->AddLabel(
    -text   => "Save Traceability Post Process Result",
    -left   => $grpTools->Left + 45,
    -top    => $grpTools->Top + 67,
);

$btnTrackHublean = $Window->AddButton(
        -name => "btnTrackHublean",
        -text => "Go",
        -left => $grpTools->Left + 5,
        -top => $grpTools->Top + 88,
        -disabled => 1,
        -tabstop => 1,
);

$lblTrackHublean = $Window->AddLabel(
    -text   => "Launch WIP LOT Detail Tracking for CW and X-ship lots",
    -left   => $grpTools->Left + 45,
    -top    => $grpTools->Top + 92,
);

$btnMatchMM = $Window->AddButton(
        -name => "btnMatchMM",
        -text => "Go",
        -left => $grpTools->Left + 5,
        -top => $grpTools->Top + 113,
        -disabled => 1,
        -tabstop => 1,
);

$lblMatchMM = $Window->AddLabel(
    -text   => "Match Lot Details and MM Numbers",
    -left   => $grpTools->Left + 45,
    -top    => $grpTools->Top + 117,
);

$btnSaveDatasheet = $Window->AddButton(
        -name => "btnSaveDatasheet",
        -text => "Go",
        -left => $grpTools->Left + 5,
        -top => $grpTools->Top + 138,
        -disabled => 1,
        -tabstop => 1,
);

$lblSaveDatasheet = $Window->AddLabel(
    -text   => "Save Datasheets With Speed # :",
    -left   => $grpTools->Left + 45,
    -top    => $grpTools->Top + 142,
);

$txtSpeedNumber = $Window->AddTextfield(
        -name => "txtSpeedNumber",
        -width => 60,
        -height => 20,
        -left => $grpTools->Left + 205,
        -top => $grpTools->Top + 140,
        -tabstop => 1,
);

$btnPrintSummary = $Window->AddButton(
        -name => "btnPrintSummary",
        -text => "Summary",
        -left => $grpTools->Left + 280,
        -top => $grpTools->Top + 138,
        -disabled => 1,
        -tabstop => 1,
);

$btnClearArray = $Window->AddButton(
        -name => "btnClearArray",
        -text => "Clear Memory",
        -left => $grpTools->Left + 40,
        -top => $grpTools->Top + 170,
        -tabstop => 1,
);

$btnGeneratePHQForm = $Window->AddButton(
        -name => "btnGeneratePHQForm",
        -text => "Generate PHQ Form",
        -left => $grpTools->Left + 210,
        -top => $grpTools->Top + 170,
        -tabstop => 1,
);
# end of TAR

# Start of DPM assessment
$grpDPMAssess = $Window->AddGroupbox(
        -name => "grpDPMAssess",
        -text => "Fabrun/Wafer/Unit Level Risk Assessment",
        -left => 5,
        -top => 445,
        -width => 365,
        -height => 105,
);

$chkExtractCB = $Window->AddCheckbox(
        -name => "chkExtractCB",
        -text => "Extract CrystalBall Data \@ Location",
        -left => $grpDPMAssess->Left + 10,
        -top => $grpDPMAssess->Top + 20,
        -check => 0,
        -tabstop => 1,
);

$CBOperation = "7310";
$txtCBOperation = $Window->AddTextfield(
    -name     => "txtCBOperation",
    -text     => "$CBOperation",
    -left     => $grpDPMAssess->Left + 207,
    -top      => $grpDPMAssess->Top + 20,
    -width    => 40,
    -height   => 20,
    -disabled => 1,
    -tabstop => 1,
);

$lblAffectedList = $Window->AddLabel(
    -text   => "Excursion Lot List :",
    -left   => $grpDPMAssess->Left + 15,
    -top    => $grpDPMAssess->Top + 48,
);

$dirtylot2 = "\<Click Here To Load File\>";
$btnAffectedList = $Window->AddButton(
        -name => "btnAffectedList",
        -text => "$dirtylot2",
        -left => $grpDPMAssess->Left + 110,
        -top => $grpDPMAssess->Top + 45,
        -tabstop => 1,
);

$btnDPMAssessPath = $Window->AddButton(
        -name => "btnDPMAssessPath",
        -text => "Containment Lot List",
        -left => $grpDPMAssess->Left + 7,
        -top => $grpDPMAssess->Top + 75,
        -disabled => 1,
        -tabstop => 1,
);

$txtDPMAssessPath = $Window->AddTextfield(
    -name     => "txtDPMAssessPath",
    -left     => $grpDPMAssess->Left + 125,
    -top      => $grpDPMAssess->Top + 75,
    -width    => 233,
    -height   => 22,
    -foreground => "#ffffff",
    -background => "#ff0000",
    -disabled => 1,
    -tabstop => 1,
);

$btnDPMAssess = $Window->AddButton(
        -name => "btnDPMAssess",
        -text => "DPM Assessment",
        -left => $grpDPMAssess->Left + 255,
        -top => $grpDPMAssess->Top + 20,
        -height => 47,
        -disabled => 1,
        -tabstop => 1,
);
# end of DPM assessment

# Start of Search group
$grpSearch = $Window->AddGroupbox(
        -name => "grpSearch",
        -left => 375,
        -top => 210,
        -width => 233,
        -height => 340,
        -title => "Search CSV-TXT File\/Content",
);

$btnSearchPath = $Window->AddButton(
        -name => "btnSearchPath",
        -text => "Look In",
        -left => $grpSearch->Left + 5,
        -top => $grpSearch->Top + 20,
        -width    => 50,
        -tabstop => 1,
);

$txtSearchPath = $Window->AddTextfield(
    -name     => "txtSearchPath",
    -left     => $grpSearch->Left + 60,
    -top      => $grpSearch->Top + 22,
    -width    => 165,
    -height   => 20,
    -tabstop => 1,
);

$lblSearchStr = $Window->AddLabel(
    -text   => "Keyword:",
    -left   => $grpSearch->Left + 5,
    -top    => $grpSearch->Top + 54,
);

$txtSearchStr = $Window->AddTextfield(
    -name     => "txtSearchStr",
    -left     => $grpSearch->Left + 60,
    -top      => $grpSearch->Top + 50,
    -width    => 115,
    -height   => 20,
    -foreground => "#ffffff",
    -background => "#0000ff",
    -tabstop => 1,
);

$btnImportSearch = $Window->AddButton(
        -name => "btnImportSearch",
        -text => "Import",
        -left => $Window->Width - 70,
        -top => $grpSearch->Top + 48,
        -tabstop => 1,
);

$btnSearch = $Window->AddButton(
        -name => "btnSearch",
        -text => "Search",
        -left => $grpSearch->Left + ($grpSearch->Width / 2) - 25,
        -top => $grpSearch->Top + 75,
        -height   => 25,
        -tabstop => 1,
);

$lvwSearchResult = $Window->AddListView(
        -name => "lvwSearchResult",
        -left      => $grpSearch->Left + 5,
        -top       => $grpSearch->Top + 102,
        -width     => 220,
        -height    => 227,
        -style     => WS_CHILD | WS_VISIBLE | 1,
        -fullrowselect => 1,
        -gridlines => 1,
        -visible => 1,
);
$lvwSearchResult->View(1);
$width = $lvwSearchResult->ScaleWidth;
$lvwSearchResult->InsertColumn(
    -index => 0,
    -width => $width / 2,
    -text  => "Filename",
);
$lvwSearchResult->InsertColumn(
    -index => 1,
    -width => $width / 2,
    -text  => "Keyword(s)",
);
# End of Datasheet Management group

########### Data Transform begin ############
$btnDataPath = $Window->AddButton(
        -name => "btnDataPath",
        -text => "Directory / File",
        -left => 5,
        -top => 30,
        -width => 100,
        -visible => 0,
        -tabstop => 1,
);

$txtDataPath = $Window->AddTextfield(
    -name     => "txtDataPath",
    -left     => 110,
    -top      => 32,
    -width    => 500,
    -height   => 20,
    -readonly => 1,
    -visible => 0,
    -tabstop => 1,
);

$btnFileFilter = $Window->AddButton(
        -name => "btnFileFilter",
        -text => "Apply Filter",
        -left => 110,
        -top => 54,
        -height => 20,
        -width => 70,
        -visible => 0,
        -tabstop => 1,
);

$txtFileFilter = $Window->AddTextfield(
    -name     => "txtFileFilter",
    -left     => 185,
    -top      => 54,
    -width    => 50,
    -height   => 20,
    -visible => 0,
    -tabstop => 1,
);

$cmbDataFiles = $Window->AddCombobox(
    -name     => "cmbDataFiles",
    -left     => 250,
    -top      => 53,
    -width    => 355,
    -height   => 120,
    -style  => WS_VSCROLL | WS_HSCROLL | WS_VISIBLE | 2 | WS_NOTIFY,
    -visible => 0,
    -tabstop => 1,
);

$lblDelimiter = $Window->AddLabel(
        -name => "lblDelimiter",
        -text => "Delimiters : ",
        -left => 110,
        -top => 80,
        -height => 20,
        -visible => 0,
);

$chkDelimiterSpace = $Window->AddCheckbox(
        -name => "chkDelimiterSpace",
        -text => "Space",
        -left => $lblDelimiter->Left + 65,
        -top => $lblDelimiter->Top - 3,
        -check => 0,
        -visible => 0,
        -tabstop => 1,
);

$chkDelimiterComma = $Window->AddCheckbox(
        -name => "chkDelimiterComma",
        -text => "Comma",
        -left => $lblDelimiter->Left + 65,
        -top => $lblDelimiter->Top + 17,
        -check => 0,
        -visible => 0,
        -tabstop => 1,
);

$chkDelimiterSemiCol = $Window->AddCheckbox(
        -name => "chkDelimiterSemiCol",
        -text => "Semicolon",
        -left => $lblDelimiter->Left + 165,
        -top => $lblDelimiter->Top - 3,
        -check => 0,
        -visible => 0,
        -tabstop => 1,
);

$chkDelimiterTab = $Window->AddCheckbox(
        -name => "chkDelimiterTab",
        -text => "Tab",
        -left => $lblDelimiter->Left + 165,
        -top => $lblDelimiter->Top + 17,
        -check => 0,
        -visible => 0,
        -tabstop => 1,
);

$chkDelimiterDash = $Window->AddCheckbox(
        -name => "chkDelimiterDash",
        -text => "Dash",
        -left => $lblDelimiter->Left + 265,
        -top => $lblDelimiter->Top - 3,
        -check => 0,
        -visible => 0,
        -tabstop => 1,
);

$chkDelimiterOther = $Window->AddCheckbox(
        -name => "chkDelimiterOther",
        -text => "Other :",
        -left => $lblDelimiter->Left + 265,
        -top => $lblDelimiter->Top + 17,
        -width =>55,
        -check => 0,
        -visible => 0,
        -tabstop => 1,
);

$txtDelimiterOther = $Window->AddTextfield(
    -name     => "txtDelimiterOther",
    -left     => $lblDelimiter->Left + 320,
    -top      => $lblDelimiter->Top + 18,
    -width    => 30,
    -height   => 20,
    -visible => 0,
    -foreground => "#ffffff",
    -background => "#0000ff",
    -tabstop => 1,
    -disabled => 1,
);

$chkFirstRowHeader = $Window->AddCheckbox(
        -name => "chkFirstRowHeader",
        -text => "1st Row Header",
        -left => $lblDelimiter->Left + 365,
        -top => $lblDelimiter->Top - 3,
        -check => 0,
        -visible => 0,
        -tabstop => 1,
);

$chkEmptyColumn = $Window->AddCheckbox(
        -name => "chkEmptyColumn",
        -text => "Empty Column",
        -left => $lblDelimiter->Left + 365,
        -top => $lblDelimiter->Top + 17,
        -check => 0,
        -visible => 0,
        -tabstop => 1,
);

$btnExampleData = $Window->AddButton(
        -name => "btnExampleData",
        -text => "Preview",
        -left => 12,
        -top => 115,
        -width => 50,
        -height => 20,
        -visible => 0,
        -tabstop => 1,
        -disabled => 1,
);

$txtLineCnt = $Window->AddTextfield(
        -name => "txtLineCnt",
        -left => $btnExampleData->Left + 53,
        -top => $btnExampleData->Top,
        -width => 40,
        -height => 20,
        -visible => 0,
        -tabstop => 1,
);

$lblLineCnt = $Window->AddLabel(
        -name => "lblLineCnt",
        -text => "Line(s)",
        -left => $btnExampleData->Left + 98,
        -top => $btnExampleData->Top + 2,
        -height => 20,
        -visible => 0,
);

$lvwDataContent = $Window->AddListView(
        -name => "lvwDataContent",
        -left      => $btnExampleData->Left - 5,
        -top       => $btnExampleData->Top + 20,
        -width     => 600,
        -height    => 165,
        -style     => WS_CHILD | WS_VISIBLE | 1,
        -fullrowselect => 1,
        -gridlines => 1,
        -visible => 0,
);
$lvwDataContent->View(1);

######### Additional Conditions ##########

$grpConditions = $Window->AddGroupbox(
        -name => "grpConditions",
        -text => "Additional Conditions",
        -left => 10,
        -top => 305,
        -height => 247,
        -width => 250,
        -visible => 0,
);

$lblStartRow = $Window->AddLabel(
        -name => "lblStartRow",
        -text => "Select Start/Stop Row #",
        -left => $grpConditions->Left + 10,
        -top => $grpConditions->Top + 20,
        -height => 20,
        -visible => 0,
);

$txtStartRow = $Window->AddTextfield(
        -name => "txtStartRow",
        -left => $grpConditions->Left + 135,
        -top => $grpConditions->Top + 18,
        -width => 48,
        -height => 20,
        -visible => 0,
        -tabstop => 1,
);

$txtStopRow = $Window->AddTextfield(
        -name => "txtStopRow",
        -left => $grpConditions->Left + 187,
        -top => $grpConditions->Top + 18,
        -width => 48,
        -height => 20,
        -visible => 0,
        -tabstop => 1,
);

$lblSelectColumn = $Window->AddLabel(
        -name => "lblSelectColumn",
        -text => "Select Column(s) #",
        -left => $grpConditions->Left + 10,
        -top => $grpConditions->Top + 40,
        -height => 20,
        -visible => 0,
);

$txtSelectColumn = $Window->AddTextfield(
        -name => "txtSelectColumn",
        -left => $grpConditions->Left + 135,
        -top => $grpConditions->Top + 38,
        -width => 100,
        -height => 20,
        -visible => 0,
        -tabstop => 1,
);

$lblRemoveRowColEmpty = $Window->AddLabel(
        -name => "lblRemoveRowColEmpty",
        -text => "Remove Row If Empty Column(s) #",
        -left => $grpConditions->Left + 10,
        -top => $grpConditions->Top + 60,
        -height => 20,
        -visible => 0,
);

$txtRemoveRowColEmpty = $Window->AddTextfield(
        -name => "txtRemoveRowColEmpty",
        -left => $grpConditions->Left + 187,
        -top => $grpConditions->Top + 58,
        -width => 48,
        -height => 20,
        -visible => 0,
        -tabstop => 1,
);

$lblRemoveRowIfColumn = $Window->AddLabel(
        -name => "lblRemoveRowIfColumn",
        -text => "Remove Row If Column",
        -left => $grpConditions->Left + 10,
        -top => $grpConditions->Top + 80,
        -height => 20,
        -visible => 0,
);

$txtRemoveRowColumnNum = $Window->AddTextfield(
        -name => "txtRemoveRowColumnNum",
        -left => $grpConditions->Left + 135,
        -top => $grpConditions->Top + 78,
        -width => 25,
        -height => 20,
        -visible => 0,
        -tabstop => 1,
);

$btnRemoveRowColumnEqual = $Window->AddButton(
        -name => "btnRemoveRowColumnEqual",
        -text => "=",
        -left => $grpConditions->Left + 161,
        -top => $grpConditions->Top + 79,
        -width => 24,
        -height => 17,
        -visible => 0,
        -tabstop => 1,
);
$removerowifcolbutton = "=";

$txtRemoveRowColumnTxt = $Window->AddTextfield(
        -name => "txtRemoveRowColumnTxt",
        -left => $grpConditions->Left + 187,
        -top => $grpConditions->Top + 78,
        -width => 48,
        -height => 20,
        -visible => 0,
        -tabstop => 1,
);

$lblRemoveRowBegin = $Window->AddLabel(
        -name => "lblRemoveRowBegin",
        -text => "Remove Row Begin With",
        -left => $grpConditions->Left + 10,
        -top => $grpConditions->Top + 100,
        -height => 20,
        -visible => 0,
);

$txtRemoveRowBegin = $Window->AddTextfield(
        -name => "txtRemoveRowBegin",
        -left => $grpConditions->Left + 135,
        -top => $grpConditions->Top + 98,
        -width => 100,
        -height => 20,
        -visible => 0,
        -tabstop => 1,
);

$lblRemoveRowContain = $Window->AddLabel(
        -name => "lblRemoveRowContain",
        -text => "Remove Row Contains",
        -left => $grpConditions->Left + 10,
        -top => $grpConditions->Top + 120,
        -height => 20,
        -visible => 0,
);

$txtRemoveRowContain = $Window->AddTextfield(
        -name => "txtRemoveRowContain",
        -left => $grpConditions->Left + 135,
        -top => $grpConditions->Top + 118,
        -width => 100,
        -height => 20,
        -visible => 0,
        -tabstop => 1,
);

$lblRemoveRowEnd = $Window->AddLabel(
        -name => "lblRemoveRowEnd",
        -text => "Remove Row End With",
        -left => $grpConditions->Left + 10,
        -top => $grpConditions->Top + 140,
        -height => 20,
        -visible => 0,
);

$txtRemoveRowEnd = $Window->AddTextfield(
        -name => "txtRemoveRowEnd",
        -left => $grpConditions->Left + 135,
        -top => $grpConditions->Top + 138,
        -width => 100,
        -height => 20,
        -visible => 0,
        -tabstop => 1,
);

$lblRemoveRow = $Window->AddLabel(
        -name => "lblRemoveRow",
        -text => "Remove Row(s)/Coln(s)",
        -left => $grpConditions->Left + 10,
        -top => $grpConditions->Top + 160,
        -height => 20,
        -visible => 0,
);

$txtRemoveRow = $Window->AddTextfield(
        -name => "txtRemoveRow",
        -left => $grpConditions->Left + 135,
        -top => $grpConditions->Top + 158,
        -width => 48,
        -height => 20,
        -visible => 0,
        -tabstop => 1,
);

$txtRemoveColumn = $Window->AddTextfield(
        -name => "txtRemoveColumn",
        -left => $grpConditions->Left + 187,
        -top => $grpConditions->Top + 158,
        -width => 48,
        -height => 20,
        -visible => 0,
        -tabstop => 1,
);

$lblInsertRowCol = $Window->AddLabel(
        -name => "lblInsertRowCol",
        -text => "Insert Row(s)/Coln(s)",
        -left => $grpConditions->Left + 10,
        -top => $grpConditions->Top + 180,
        -height => 20,
        -visible => 0,
);

$txtInsertRow = $Window->AddTextfield(
        -name => "txtInsertRow",
        -left => $grpConditions->Left + 135,
        -top => $grpConditions->Top + 178,
        -width => 48,
        -height => 20,
        -visible => 0,
        -tabstop => 1,
);

$txtInsertColumn = $Window->AddTextfield(
        -name => "txtInsertColumn",
        -left => $grpConditions->Left + 187,
        -top => $grpConditions->Top + 178,
        -width => 48,
        -height => 20,
        -visible => 0,
        -tabstop => 1,
);

$lblSwapColumn = $Window->AddLabel(
        -name => "lblSwapColumn",
        -text => "Swap Column(s) #",
        -left => $grpConditions->Left + 10,
        -top => $grpConditions->Top + 200,
        -height => 20,
        -visible => 0,
);

$txtSwapColumn = $Window->AddTextfield(
        -name => "txtSwapColumn",
        -left => $grpConditions->Left + 135,
        -top => $grpConditions->Top + 198,
        -width => 100,
        -height => 20,
        -visible => 0,
        -tabstop => 1,
);

$chkRemoveRowEmpty = $Window->AddCheckbox(
        -name => "chkRemoveRowEmpty",
        -text => "Remove Empty Row",
        -left => $grpConditions->Left + 10,
        -top => $grpConditions->Top + 220,
        -check => 0,
        -visible => 0,
        -tabstop => 1,
);

$chkUniqueRecord = $Window->AddCheckbox(
        -name => "chkUniqueRecord",
        -text => "Unique Record",
        -left => $grpConditions->Left + 145,
        -top => $grpConditions->Top + 220,
        -check => 0,
        -visible => 0,
        -tabstop => 1,
);

######### Transformation #############

$grpTransform = $Window->AddGroupbox(
        -name => "grpTransform",
        -text => "File Conversion Output Setup",
        -left => 264,
        -top => 305,
        -height => 247,
        -width => 342,
        -visible => 0,
);

$btnTransformSavePath = $Window->AddButton(
        -name => "btnTransformSavePath",
        -text => "Conversion Storage",
        -left => $grpTransform->Left + 10,
        -top => $grpTransform->Top + 20,
        -width    => 110,
        -tabstop => 1,
        -visible => 0,
);

$txtTransformSavePath = $Window->AddTextfield(
    -name     => "txtTransformSavePath",
    -left     => $grpTransform->Left + 128,
    -top      => $grpTransform->Top + 22,
    -width    => 205,
    -height   => 20,
    -tabstop => 1,
    -visible => 0,
);

$lblHeader = $Window->AddLabel(
        -name => "lblHeader",
        -text => "Header Row",
        -left => $grpTransform->Left + 15,
        -top => $grpTransform->Top + 50,
        -height => 20,
        -visible => 0,
        -disabled => 1,
);

$radPreserveHeader = $Window->AddRadioButton(
        -name => "radPreserveHeader",
        -text => "Include",
        -left => $grpTransform->Left + 90,
        -top => $grpTransform->Top + 47,
        -visible => 0,
        -tabstop => 1,
        -disabled => 1,
);

$radRemoveHeader = $Window->AddRadioButton(
        -name => "radRemoveHeader",
        -text => "Exclude",
        -left => $grpTransform->Left + 215,
        -top => $grpTransform->Top + 47,
        -visible => 0,
        -tabstop => 1,
        -disabled => 1,
);

$lblConvertFile = $Window->AddLabel(
        -name => "lblConvertFile",
        -text => "Convert File",
        -left => $grpTransform->Left + 15,
        -top => $grpTransform->Top + 80,
        -height => 20,
        -visible => 0,
        -disabled => 1,
);

$radCurrentFile = $Window->AddRadioButton(
        -name => "radCurrentFile",
        -text => "This File Only",
        -left => $grpTransform->Left + 90,
        -top => $grpTransform->Top + 77,
        -visible => 0,
        -tabstop => 1,
        -disabled => 1,
);

$radFilteredFile = $Window->AddRadioButton(
        -name => "radFilteredFile",
        -text => "Filtered Files",
        -left => $grpTransform->Left + 90,
        -top => $grpTransform->Top + 97,
        -visible => 0,
        -tabstop => 1,
        -disabled => 1,
);

$radAllFile = $Window->AddRadioButton(
        -name => "radAllFile",
        -text => "All Files In The Directory",
        -left => $grpTransform->Left + 90,
        -top => $grpTransform->Top + 117,
        -visible => 0,
        -tabstop => 1,
        -disabled => 1,
);

$lblOutputDelimiter = $Window->AddLabel(
        -name => "lblOutputDelimiter",
        -text => "Delimiter",
        -left => $grpTransform->Left + 15,
        -top => $grpTransform->Top + 150,
        -height => 20,
        -visible => 0,
);

$radOutputComma = $Window->AddRadioButton(
        -name => "radOutputComma",
        -text => "Comma (csv)",
        -left => $grpTransform->Left + 90,
        -top => $grpTransform->Top + 147,
        -visible => 0,
        -tabstop => 1,
);

$radOutputTab = $Window->AddRadioButton(
        -name => "radOutputTab",
        -text => "Tab (txt)",
        -left => $grpTransform->Left + 215,
        -top => $grpTransform->Top + 147,
        -visible => 0,
        -tabstop => 1,
);

$radOutputOther = $Window->AddRadioButton(
        -name => "radOutputOther",
        -text => "Other :",
        -left => $grpTransform->Left + 90,
        -top => $grpTransform->Top + 167,
        -visible => 0,
        -tabstop => 1,
);

$txtOutputOther = $Window->AddTextfield(
    -name     => "txtOutputOther",
    -left     => $grpTransform->Left + 150,
    -top      => $grpTransform->Top + 167,
    -width    => 30,
    -height   => 20,
    -tabstop => 1,
    -visible => 0,
    -disabled => 1,
);

$lblFileExt = $Window->AddLabel(
        -name => "lblFileExt",
        -text => "File Extension :",
        -left => $grpTransform->Left + 200,
        -top => $grpTransform->Top + 170,
        -height => 20,
        -visible => 0,
        -disabled => 1,
);

$txtFileExt = $Window->AddTextfield(
    -name     => "txtFileExt",
    -left     => $grpTransform->Left + 290,
    -top      => $grpTransform->Top + 167,
    -width    => 35,
    -height   => 20,
    -tabstop => 1,
    -visible => 0,
    -disabled => 1,
);

$chkCombineOutput = $Window->AddCheckbox(
        -name => "chkCombineOutput",
        -text => "Combine all into one file (optional)",
        -left => $grpTransform->Left + 90,
        -top => $grpTransform->Top + 190,
        -check => 0,
        -visible => 0,
        -tabstop => 1,
);

$btnStartConvert = $Window->AddButton(
        -name => "btnStartConvert",
        -text => "Start Conversion",
        -left => $grpTransform->Left + 100,
        -top => $grpTransform->Top + 215,
        -width    => 110,
        -tabstop => 1,
        -visible => 0,
        -disabled => 1,
);

########### Data Transform end ##############

$ProgressBar = $Window->AddProgressBar(
    -name   => "pb",
    -left   => 5,
    -top    => $Window->Height - 87,
    -width  => $Window->Width - 20,
    -height => 10,
    -smooth => 1,
);

# Create a status bar
$Status = $Window->AddStatusBar(
    -name => "Status",
    -text => "Traceability Analysis & Reporting",
);

# Initialization
$atpo = '[MT469]';
$fpo = '[LQ357]';
$extractflag = 0;

$Window->Show();
Win32::GUI::Dialog();

sub mnuViewLog_Click {
        my $file = "$curdir\\TAR.log";
        system("start notepad.exe $file");
}

sub chkExtractCB_Click {
        $datetime = localtime;
        open (TARLOG,">>$curdir\\TAR.log") || die "Cannot open TAR.log\n";
        if ($chkExtractCB->Checked()) {
                $extractflag = 1;
                $txtCBOperation->Enable(1);
                print TARLOG "$datetime : CrystalBall Extraction Enabled\n";
        }
        else {
                $extractflag = 0;
                $txtCBOperation->Enable(0);
                print TARLOG "$datetime : CrystalBall Extraction Disabled\n";
        }
        close(TARLOG);
}

sub txtCBOperation_Change {
        $CBOperation = $txtCBOperation->Text;
}

sub chkWIPTracking_Click {
        $datetime = localtime;
        open (TARLOG,">>$curdir\\TAR.log") || die "Cannot open TAR.log\n";
        if ($chkWIPTracking->Checked()) {
                $lblHubleanReport->Enable(1);
                $cmbReport->Enable(1);
                $cmbRptOption->Enable(1);
                $lblLotOwner->Enable(1);
                $cmbLotOwner->Enable(1);
                $lblRptDesc->Enable(1);
                $lblTraceHublean->Text("Customize WIP LOT Trace\/Track");
                print TARLOG "$datetime : Customize Trace/Track Enabled\n";
        }
        else {
                $report = "TRACE";
                $reportindex = $cmbReport->FindStringExact("Traceability");
                $cmbReport->Select($reportindex);
                $rptoption = "T";
                $rptoptionindex = $cmbRptOption->FindStringExact("Forward");
                $cmbRptOption->Select($rptoptionindex);
                $lotowner = "BOTH";
                $lotownertemp = $lotowner;
                $lotownerindex = $cmbLotOwner->FindStringExact("BOTH");
                $cmbLotOwner->Select($lotownerindex);
                $lblHubleanReport->Enable(0);
                $cmbReport->Enable(0);
                $cmbRptOption->Enable(0);
                $lblLotOwner->Enable(0);
                $cmbLotOwner->Enable(0);
                $lblRptDesc->Text("(Tree Format)");
                $lblRptDesc->Enable(0);
                $lblTraceHublean->Text("Launch WIP LOT Traceability For");
                $Status->Text("");
                print TARLOG "$datetime : Customize Trace/Track Disabled\n";
        }
        close(TARLOG);
}

sub mnuSupport_Click {
        $confirm = MsgBox("Traceability Analysis & Reporting - Support", "Contact: CY Gan (chee.yong.gan\@intel.com) i-Net: 8-253-6573.", 0);
}

sub Window_Resize {
        $tmp = $Window->ScaleWidth;
        $tmptxt = $tmp - 140;
        $Status->Width($tmp);
        $grpHubleanSetup->Width($tmp-10);
        $grpPathSetup->Width($tmp-10);
        $txtHubleanPath->Width($tmptxt);
        $txtPHQFormPath->Width($tmptxt);
        $txtCentralPath->Width($tmptxt);
        $txtTracePath->Width($tmptxt);
        $btnSaveSetup->Left($tmp / 2 - 120);
        $btnLoadSetup->Left($tmp / 2 + 20);
        $grpSearch->Width($tmp-380);
        $txtSearchStr->Width($tmp-503);
        $btnSearch->Left($grpSearch->Left + ($grpSearch->Width / 2) - 25);
        $lvwSearchResult->Width($tmp-395);
        $txtSearchPath->Width($tmp-450);
        $btnImportSearch->Left($tmp-62);
        $ProgressBar->Width($tmp-10);
        $ProgressBar->Top($Window->Height - 87);
        $Window->Tab->Resize($Window->ScaleWidth, $Window->ScaleHeight - 20);
        $txtDataPath->Width($tmp-120);
        $lvwDataContent->Width($tmp-15);
        $Status->Top($Window->Height-75);
}

sub btnSaveSetup_Click {
        $datetime = localtime;
        open (TARLOG,">>$curdir\\TAR.log") || die "Cannot open TAR.log\n";
        print TARLOG "$datetime : Save Setup\n";
        print STDERR "\nSave Setup File - Running\n";
        $Status->Text("Saving Setup ......");
        ($savesetuppath,$savesetupfile) = &GetFileName($btnSaveSetup,"Save Setup File","Text Document (*.txt)","*.txt",$curdir);
        chdir "$savesetuppath";
        if ($savesetupfile ne "") {
                if ($savesetupfile !~ /\.txt$/i) {
                        $savesetupfile = $savesetupfile . "\.txt";
                }
                open(SAVE,">$savesetupfile") || die "Cannot open $savesetupfile\n";
                print SAVE "hubleansite=$hubleansite\n";
                print SAVE "hubleansitecode=$hubleansitecode\n";
                print SAVE "report=$report\n";
                print SAVE "rptoption=$rptoption\n";
                print SAVE "lotowner=$lotowner\n";
                print SAVE "maxlot=$maxlot\n";
                print SAVE "phqformpath=$phqformpath\n";
                print SAVE "phqform=$phqform\n";
                print SAVE "centralpath=$centralpath\n";
                print SAVE "tracepath=$tracepath\n";
                close(SAVE);
                print STDERR "\nSave Setup File - Done\n";
                chdir "$curdir";
                $Status->Text("Setup Saved - $savesetupfile");
                print TARLOG "\tSave Setup to $savesetuppath\\$savesetupfile\n";
        }
        else {
                $Status->Text("");
                print TARLOG "\tSave Setup Cancelled\n";
        }
        close(TARLOG);
}

sub btnLoadSetup_Click {
        $datetime = localtime;
        open (TARLOG,">>$curdir\\TAR.log") || die "Cannot open TAR.log\n";
        print TARLOG "$datetime : Load Setup\n";
        print STDERR "\nLoad Setup File - Running\n";
        $Status->Text("Loading Setup ......");
        ($loadsetuppath,$loadsetupfile) = &GetFileName($btnLoadSetup,"Load Setup File","Text Document (*.txt)","*.txt",$curdir);
        if ($loadsetupfile ne "") {
                open(LOAD,"<$loadsetuppath\\$loadsetupfile") || die "Cannot open $loadsetupfile.\n";
                while(<LOAD>) {
                        chomp;
                        ($key,$val) = split('=');
                        $setup{$key} = $val;
                }
                close(LOAD);
                $hubleansite = $setup{'hubleansite'};
                @data = split('_',$hubleansite);
                $hubleansiteindex = $cmbSite->FindStringExact("$data[0]");
                $cmbSite->Select($hubleansiteindex);
                $hubleansitecode = $setup{'hubleansitecode'};
                $report = $setup{'report'};
                $reportindex = $cmbReport->FindStringExact("Traceability") if ($report =~ /TRACE/i);
                $reportindex = $cmbReport->FindStringExact("Tracking") if ($report =~ /TRACK/i);
                $cmbReport->Select($reportindex);
                $rptoption = $setup{'rptoption'};
                $rptoptionindex = $cmbRptOption->FindStringExact("Forward") if ($rptoption =~ /T/i);
                $rptoptionindex = $cmbRptOption->FindStringExact("Backward") if ($rptoption =~ /F/i);
                $cmbRptOption->Select($rptoptionindex);
                $lotowner = $setup{'lotowner'};
                $lotownertemp = $lotowner;
                $lotownerindex = $cmbLotOwner->FindStringExact("$lotownertemp");
                $cmbLotOwner->Select($lotownerindex);
                $maxlot = $setup{'maxlot'};
                $maxlotindex = $cmbMaxLot->FindStringExact("$maxlot");
                $cmbMaxLot->Select($maxlotindex);
                $phqformpath = $setup{'phqformpath'};
                $phqform = $setup{'phqform'};
                $txtPHQFormPath->Text("$phqformpath\\$phqform");
                $centralpath = $setup{'centralpath'};
                $txtCentralPath->Text($centralpath);
                $tracepath = $setup{'tracepath'};
                $txtTracePath->Text($tracepath);
                undef %setup;
                $Status->Text("Setup Loaded - $loadsetupfile");
                print TARLOG "\tSetup Loaded Successfully from $loadsetuppath\\$loadsetupfile\n";
        }
        else {
                $Status->Text("");
                print TARLOG "\tLoad Setup Cancelled\n";
        }
        close(TARLOG);
}

sub btnDPMAssessPath_Click {
        $datetime = localtime;
        open (TARLOG,">>$curdir\\TAR.log") || die "Cannot open TAR.log\n";
        print TARLOG "$datetime : Load lot list for DPM Assessment\n";
        if ($dpmassesspath eq "") {
               $dpmassesspath = $tracepath;
        }
        ($dpmassesspath,$dpmassess) = &GetFileName($btnDPMAssessPath,"Load File for DPM Assessment","Comma Separated Values (*.csv)","*.csv",$dpmassesspath,$dpmassessfile);
        if (-e "$dpmassesspath" . "\\" . "$dpmassess" && $dpmassess ne "") {
                $dpmassessfile = $dpmassesspath . "\\" . $dpmassess;
                print STDERR "Loaded $dpmassessfile for DPM Assessment\n";
                $txtDPMAssessPath->Text($dpmassessfile);
                $Status->Text("Loaded $dpmassessfile for DPM Assessment");
                $btnDPMAssess->Enable(1);
                print TARLOG "\tLoaded $dpmassessfile for DPM Assessment\n";
        }
        else {
                $txtDPMAssessPath->Text("");
                $dpmassessfile = "";
                $btnDPMAssess->Enable(0);
                $Status->Text("No file loaded for DPM Assessment");
                print TARLOG "\tLoad lot list cancelled\n";
        }
        close(TARLOG);
}

sub txtDPMAssessPath_Change {
        $dpmassessfile = $txtDPMAssessPath->Text;
        if ($dpmassessfile ne "") {
                $btnDPMAssess->Enable(1);
                $Status->Text("Load $dpmassessfile for DPM Assessment");
        }
        else {
                $btnDPMAssess->Enable(0);
                $Status->Text("");
        }
}

sub btnDPMAssess_Click {
        $datetime = localtime;
        open (TARLOG,">>$curdir\\TAR.log") || die "Cannot open TAR.log\n";
        print TARLOG "$datetime : DPM Assessment Starts\n";
        if (-e "$dpmassessfile" && $extractflag == 1 && $CBOperation =~ /^\s*[0-9]{4}\s*$/) {
                print TARLOG "\tDPM Assessment File : $dpmassessfile\n";
                print TARLOG "\tExtract CrystalBall Data at Location $CBOperation\n";
                $CBOperation =~ s/^\s*(\d{4})\s*$/$1/;
                $txtCBOperation->Text("$CBOperation");
                $cnt{'PG'} = 0;
                $cnt{'KM'} = 0;
                $cnt{'CV'} = 0;
                $cnt{'CR'} = 0;
                $cnt{'PD'} = 0;
                # $cnt{'CH'} = 0;
                $lotlist{'PG'} = "";
                $lotlist{'KM'} = "";
                $lotlist{'CR'} = "";
                $lotlist{'CV'} = "";
                $lotlist{'PD'} = "";
                # $lotlist{'CH'} = "";
                $max = 5;
                $totallot = 0;
                print TARLOG "\tRead $dpmassessfile\n";
                open(IN,"<$dpmassessfile") || die "Cannot open $dpmassessfile\n";
                $header = <IN>;
                while(<IN>) {
                	chomp;
                        @data = split(',');
                        $lots{$data[0]} = 1;
                        $totallot += 1;
                }
                close(IN);
                $ProgressBar->SetRange(0,$totallot);
                $PBcurpos = 0;
                print TARLOG "\tExtracting CrystalBall Data\n";
                foreach $lot (sort keys %lots) {
                        if ($lot =~ /^L/ || $lot =~ /^M/) {
                                $cnt{'PG'} += 1;
                                if ($cnt{'PG'} <= $max) {
                                        $lotlist{'PG'} .= $lot . ",";
                                }
                        }
                        if ($lot =~ /^Q/ || $lot =~ /^T/) {
                                $cnt{'KM'} += 1;
                                if ($cnt{'KM'} <= $max) {
                                        $lotlist{'KM'} .= $lot . ",";
                                }
                        }
                        if ($lot =~ /^3/ || $lot =~ /^4/) {
                                $cnt{'CR'} += 1;
                                if ($cnt{'CR'} <= $max) {
                                        $lotlist{'CR'} .= $lot . ",";
                                }
                        }
                        if ($lot =~ /^5/ || $lot =~ /^9/) {
                                $cnt{'PD'} += 1;
                                if ($cnt{'PD'} <= $max) {
                                        $lotlist{'PD'} .= $lot . ",";
                                }
                        }
                        if ($lot =~ /^7/ || $lot =~ /^6/) {
                                $cnt{'CV'} += 1;
                                if ($cnt{'CV'} <= $max) {
                                        $lotlist{'CV'} .= $lot . ",";
                                }
                        }
                        foreach $sitelotcnt (keys %cnt) {
                                if ($cnt{$sitelotcnt} == $max) {
                                        # launch CrystalBall for site
                                        $Status->Text("Extracting Data For $sitelotcnt Lots");
                                        LaunchCBCLI($lotlist{$sitelotcnt});
                                        $PBcurpos += $cnt{$sitelotcnt};
                                        $ProgressBar->SetPos($PBcurpos);
                                        $cnt{$sitelotcnt} = 0;
                                        $lotlist{$sitelotcnt} = "";
                                }
                        }
                }
                foreach $sitelotcnt (keys %cnt) {
                        if ($cnt{$sitelotcnt} != 0) {
                                # launch CrystalBall for site
                                $Status->Text("Extracting Data For $sitelotcnt Lots");
                                LaunchCBCLI($lotlist{$sitelotcnt});
                                $PBcurpos += $cnt{$sitelotcnt};
                                $ProgressBar->SetPos($PBcurpos);
                                $cnt{$sitelotcnt} = 0;
                                $lotlist{$sitelotcnt} = "";
                         }
                }
                undef %cnt;
                undef %lotlist;
                $ProgressBar->SetPos(0);
        }
        elsif (-e "$dpmassessfile" && $extractflag == 1 && $CBOperation !~ /^\s*[0-9]{4}\s*$/) {
                print STDERR "Invalid Operation Code: $CBOperation\n";
                print STDERR "DPM assessment will be based on existing file in $tracepath, if any.\n";
                $Status->Text("Invalid Operation Code: $CBOperation");
                print TARLOG "\tInvalid Operation Code : $CBOperation\n";
                print TARLOG "\tDPM assessment will be based on existing file in $tracepath, if any.\n";
        }
        undef @files;
        chdir "$tracepath";
        print TARLOG "\tRead CrystalBall Output from $tracepath\n";
        opendir(DIR, '.') || die "Cann't open Directory\n";
        local(@files) = readdir(DIR);
        closedir(DIR);
        $gotfile = 0;
        $totalfiles = @files;
        $ProgressBar->SetRange(0,$totalfiles);
        $PBcurpos = 0;
        foreach $file (@files) {
                $PBcurpos += 1;
                $ProgressBar->SetPos($PBcurpos);
                next if ($file !~ /CB[0-9]{4}.+\.txt$/i); # && $file !~ /\.txt$/i);
                print STDERR "\tReading file: $file\n";
                $Status->Text("Reading file: $file");
                open(IN,"<$file") || die "Cannot open $file for analysis.\n";
                chomp ($header = <IN>);
                while(<IN>) {
                        if ($_ !~ /^\-/) {
                                ($fabrun,$wafer,$xloc,$yloc,$bin,$fponum) = split(/\s+/);
                                if (!defined($binunit{$fponum}{$fabrun}{$wafer}{$xloc}{$yloc}) && $bin <= 6) {
                                        $qtyfpo{$fponum} += 1;
                                        $qtyfpofabrun{$fponum}{$fabrun} += 1;
                                        $qtyfpofabrunwafer{$fponum}{$fabrun}{$wafer} += 1;
                                        $binunit{$fponum}{$fabrun}{$wafer}{$xloc}{$yloc} = $bin;
                                        $gotfile = 1;
                                }
                        }
                }
                close(IN);
        }
        $ProgressBar->SetPos(0);
        # read bad fabrun
        print TARLOG "\tRead Affected Fabrun/Wafer/ULT\n";
        open(BADFABRUN,"<$dirtylot2path\\$dirtylot2") || die "Cannot open $dirtylot2.\n";
        chomp ($header = <BADFABRUN>);
        @data = split(',',$header);
        $ultlevel = 0;
        $waferlevel = 0;
        if ($data[1] =~ /Wafer/i && $data[2] =~ /X/i && $data[3] =~ /Y/i) {
                $ultlevel = 1;
                print STDERR "Input file indicates ULT Level DPM Assessment\n";
                print TARLOG "\tInput file indicates ULT Level DPM Assessment\n";
        }
        elsif ($data[1] =~ /Wafer/i && !($data[2] =~ /X/i && $data[3] =~ /Y/i)) {
                $waferlevel = 1;
                print STDERR "Input file indicates Wafer Level DPM Assessment\n";
                print TARLOG "\tInput file indicates Wafer Level DPM Assessment\n";
        }
        else {
                print STDERR "Input file indicates Fabrun Level DPM Assessment\n";
                print TARLOG "\tInput file indicates Fabrun Level DPM Assessment\n";
        }
        while(<BADFABRUN>) {
                chomp;
                @data = split(',');
                $badfabrun{$data[0]} = 1;
                $badwafer{$data[0]}{$data[1]} = 1 if ($waferlevel);
                $badult{$data[0]}{$data[1]}{$data[2]}{$data[3]} = 1 if ($ultlevel);
        }
        close(BADFABRUN);
        $totaldpm = 0;
        $fabrundpm = 0;
        $waferdpm = 0;
        print TARLOG "\tPrinting DPM Report\n";
        # print report by fabrun
        if (!$ultlevel && !$waferlevel && $gotfile) {
                print STDERR "Performing Fabrun Level DPM Assessment\n";
                $Status->Text("Printing Report: Report_FPO_Fabrun.csv");
                open(FPO1,">$tracepath\\Report_FPO_Fabrun.csv") || die "Cannot open Report_FPO_Fabrun.csv for editing.\n";
                print FPO1 "FPO,Fabrun,Qty,DPM\n";
                foreach $fponum (sort keys  %qtyfpofabrun) {
                        next if ($fponum eq "");
                        foreach $fabrun (sort keys (%{qtyfpofabrun->{$fponum}})) {
                                if (defined($badfabrun{$fabrun})) {
                                        $fabrundpm = $qtyfpofabrun{$fponum}{$fabrun} / $qtyfpo{$fponum} * 1000000;
                                        $totaldpm += $fabrundpm;
                                        print FPO1 ",$fabrun,$qtyfpofabrun{$fponum}{$fabrun},";
                                        printf FPO1 "%d\n",$fabrundpm;
                                }
                                else {
                                        print FPO1 ",$fabrun,$qtyfpofabrun{$fponum}{$fabrun},\n";
                                }
                        }
                        print FPO1 "$fponum,,$qtyfpo{$fponum},";
                        printf FPO1 "%d\n",$totaldpm;
                        $fabrundpm = 0;
                        $totaldpm = 0;
                }
                close(FPO1);
                $Status->Text("Printing Report: Report_FPO_Fabrun.csv ... Done");
                print STDERR "Printed Report: Report_FPO_Fabrun.csv\n";
        }
        # print report by fabrun and wafer
        elsif ($waferlevel && $gotfile) {
                print STDERR "Performing Wafer Level DPM Assessment\n";
                $Status->Text("Printing Report: Report_FPO_FabrunWafer.csv");
                open(FPO2,">$tracepath\\Report_FPO_FabrunWafer.csv") || die "Cannot open Report_FPO_FabrunWafer.csv for editing.\n";
                print FPO2 "FPO,Fabrun,Wafer,Qty,DPM\n";
                foreach $fponum (sort keys  %qtyfpofabrunwafer) {
                        next if ($fponum eq "");
                        foreach $fabrun (sort keys (%{qtyfpofabrunwafer->{$fponum}})) {
                                foreach $wafer (sort keys (%{qtyfpofabrunwafer->{$fponum}{$fabrun}})) {
                                        if (defined($badwafer{$fabrun}{$wafer})) {
                                                $waferdpm = $qtyfpofabrunwafer{$fponum}{$fabrun}{$wafer} / $qtyfpo{$fponum} * 1000000;
                                                $totaldpm += $waferdpm;
                                                print FPO2 ",$fabrun,$wafer,$qtyfpofabrunwafer{$fponum}{$fabrun}{$wafer},";
                                                printf FPO2 "%d\n",$waferdpm;
                                        }
                                        else {
                                                print FPO2 ",$fabrun,$wafer,$qtyfpofabrunwafer{$fponum}{$fabrun}{$wafer},\n";
                                        }
                                }
                        }
                        print FPO2 "$fponum,,,$qtyfpo{$fponum},";
                        printf FPO2 "%d\n",$totaldpm;
                        $waferdpm = 0;
                        $totaldpm = 0;
                }
                close(FPO2);
                $Status->Text("Printing Report: Report_FPO_FabrunWafer.csv ... Done");
                print STDERR "Printed Report: Report_FPO_FabrunWafer.csv\n";
        }
        # print report by fabrun, wafer, x, and y
        elsif ($ultlevel && $gotfile) {
                print STDERR "Performing ULT Level DPM Assessment\n";
                print STDERR "Printing ULT Level DPM Assessment Detail\n";
                $Status->Text("Printing Report: Report_FabrunWaferXY.csv");
                open(FPO3,">$tracepath\\Report_FabrunWaferXY.csv") || die "Cannot open Report_FabrunWaferXY.csv for editing.\n";
                print FPO3 "Input Lot,Fabrun,Wafer,X,Y\n";
                foreach $fponum (sort keys %binunit) {
                        next if ($fponum eq "");
                        foreach $fabrun (sort keys (%{binunit->{$fponum}})) {
                                foreach $wafer (sort keys (%{binunit->{$fponum}{$fabrun}})) {
                                        foreach $x (sort keys (%{binunit->{$fponum}{$fabrun}{$wafer}})) {
                                                foreach $y (sort keys (%{binunit->{$fponum}{$fabrun}{$wafer}{$x}})) {
                                                        if (defined($badult{$fabrun}{$wafer}{$x}{$y}) && $binunit{$fponum}{$fabrun}{$wafer}{$x}{$y} <= 6) {
                                                                $badinfpo{$fponum} += 1;
                                                                print FPO3 "$fponum,$fabrun,$wafer,$x,$y\n";
                                                        }
                                                        elsif (!defined($badult{$fabrun}{$wafer}{$x}{$y}) && $binunit{$fponum}{$fabrun}{$wafer}{$x}{$y} <= 6) {
                                                                $goodinfpo{$fponum} += 1;
                                                        }
                                                        else {
                                                                print STDERR "Reject: $fabrun\t$wafer\t$x\t$y\tBin: $binunit{$fponum}{$fabrun}{$wafer}{$x}{$y}\n";
                                                        }
                                                }
                                        }
                                }
                        }
                }
                close(FPO3);
                print STDERR "Printing ULT assessment summary: Report_FabrunWaferXY_summary.csv\n";
                $Status->Text("Printing Summary: Report_FabrunWaferXY_summary.csv");
                open(FPO4,">$tracepath\\Report_FabrunWaferXY_summary.csv") || die "Cannot open Report_FabrunWaferXY_summary.csv for editing.\n";                
                print FPO4 "Input Lot,Total Qty,Good ULT,Bad ULT,Lot DPM\n";
                foreach $fponum (sort keys %qtyfpo) {
                        next if ($fponum eq "");
                        print FPO4 "$fponum,$qtyfpo{$fponum},$goodinfpo{$fponum},$badinfpo{$fponum},",$badinfpo{$fponum} / $qtyfpo{$fponum} * 1000000,"\n";
                }
                close(FPO4);
                print STDERR "ULT Level DPM Assessment Done\n";
                undef %goodinfpo;
                undef %badinfpo;
        }
        else {
                print STDERR "\tNo data for DPM Assessment\n";
                print TARLOG "\tNo data for DPM Assessment\n";
        }
        chdir "$curdir";
        undef %lots;
        undef %qtyfpo;
        undef %qtyfpofabrun;
        undef %qtyfpofabrunwafer;
        undef %binunit;
        undef %badfabrun;
        undef %badwafer;
        undef %badult;
        $Status->Text("");
        close(TARLOG);
}

# CB script is pointing to SITE=T3 in the Parameters section - need to change this
sub LaunchCBCLI {
        $datetime = localtime;
        my $lotnumber = $_[0];
	chop $lotnumber;
        print TARLOG "\t\t$datetime : Extract For Lot - $lotnumber\n";
	print STDERR "\nCreating CrystalBall Script for $lotnumber\n";
        $Status->Text("Creating CrystalBall Script for $lotnumber");
        $createtime = localtime();
	open(ACS,">$tracepath\\CBCLI_tmp.acs") || die "Cannot open $tracepath\\CBCLI_tmp.acs for editing.\n";
        print ACS "<!--\n";
        print ACS " User: $user\n";
        print ACS " Date: $createtime\n";
        print ACS " CB: CrystalBall_3.0.15\n";
        print ACS " BUILD: WED, 07 MAY 2003 22:01:18 GMT\n";
        print ACS "-->\n\n";
	print ACS "<!-- %%%%%%%%%%%%%%%%%%%%%%% Collection %%%%%%%%%%%%%%%%%%%%%%% #TAG -->\n\n";
	print ACS "<collection type=material >\n";
	print ACS "  <group >\n";
	@data = split(',',$lotnumber);
	foreach $lot (@data) {
		next if ($lot eq "");
		$site = "T3" if ($lot =~ /^L/ || $lot =~ /^M/);
		$site = "KM" if ($lot =~ /^Q/ || $lot =~ /^T/);
		$site = "CR" if ($lot =~ /^3/ || $lot =~ /^4/);
		$site = "CV" if ($lot =~ /^7/ || $lot =~ /^6/);
		$site = "T5" if ($lot =~ /^5/ || $lot =~ /^9/);
		print ACS "    $lot  SITE=$site DOMAIN=CLASS \n";
	}
	print ACS "  </group >\n";
	print ACS "</collection >\n\n";
	print ACS "<!-- %%%%%%%%%%%%%%%%%%%%%%% Parameters %%%%%%%%%%%%%%%%%%%%%%% #TAG -->\n\n";
	print ACS "<parameters  >\n";
	print ACS "  <param DATATYPE=DIEBIN DOMAIN=CLASS OPERATION=$CBOperation AKA=BIN SITE=$site TESTNAME=IB />\n";
	print ACS "  <param DATATYPE=FIELD DOMAIN=CLASS OPERATION=$CBOperation AKA=CLASSLOT SITE=$site FIELD=LOT TABLE=SCRUNS />\n";
	print ACS "</parameters>\n\n";
	print ACS "<!-- %%%%%%%%%%%%%%%%%%%%%%% Analysis %%%%%%%%%%%%%%%%%%%%%%% #TAG -->\n\n";
	print ACS "<analysis app=cb  >\n";
	print ACS "  TOOL='GiveMeData'\n";
        print ACS "  /NOTABLEHEADER\n";
        print ACS "  /norowheader\n";
        print ACS "  /AUTOAKA\n";
        print ACS "  /columns\=lot,wafer,x,y,BIN,CLASSLOT\n";
	print ACS "  /FLCHAR\n";
	print ACS "</analysis>\n";
	close(ACS);
	($day,$mon,$mday,$hour,$year) = split(' ',localtime());
	$curtime = "$mday" . "$mon" . "$year" . "$hour";
	$curtime =~ s/\://g;
	$tofile = $user . "_CB" . $CBOperation . "_" . $curtime . ".txt";
        $CBpath = "c:\\users\\$user\\CrystalBall\\Production";
        chdir "$CBpath";
        $Status->Text("Extracting data from CrystalBall");
	`CBCLI.exe tool\=runscript script\="$tracepath"\\CBCLI_tmp.acs \/output\="$tracepath"\\$tofile`;
        $Status->Text("Extracting data from CrystalBall ... Done");
        `del "$tracepath\\CBCLI_tmp.acs"`;
        chdir $curdir;
	print STDERR "Created output filename: $tracepath\\$tofile\n" if (-e "$tracepath\\$tofile") ;
}

sub btnHubleanPath_Click {
        $hubleanpath = &GetFolderName($btnHubleanPath,"Setup WIP LOT Tracking Storage","1",$hubleanpath);
        print STDERR "WIP LOT Tracking Storage Path: $hubleanpath\n";
        $txtHubleanPath->Text($hubleanpath);
        $Status->Text("WIP Lot Tracking Storage Path - $hubleanpath");
}

sub btnPHQFormPath_Click {
        $datetime = localtime;
        open (TARLOG, ">>$curdir\\TAR.log") || die "Cannot open TAR.log\n";
        print TARLOG "$datetime : Change PHQ Form Path\n";
        ($phqformpath,$phqform) = &GetFileName($btnPHQFormPath,"Setup PHQ Form Path","Excel (*.xls)","*.xls",$phqformpath,$phqform);
        print TARLOG "\tPHQ Form Path: $phqformpath\n";
        print STDERR "PHQ Form Path: $phqformpath\n";
        print TARLOG "\tPHQ Form: $phqform\n";
        print STDERR "PHQ Form: $phqform\n";
        $txtPHQFormPath->Text("$phqformpath\\$phqform");
        $Status->Text("PHQ Form Path - $phqformpath\\$phqform");
        close(TARLOG);
}

# sub txtPHQFormPath_Change {
#         $phqformpath = $txtPHQFormPath->Text;
#         $Status->Text("PHQ Form Path - $phqformpath");
# }

sub btnImportSearch_Click {
        $txtSearchStr->Enable(0);
        $Status->Text("Importing file for search ...");
        ($importsearchpath,$importsearchfile) = &GetFileName($btnImportSearch,"Import File For Search","Comma Separated Values (*.csv)","*.csv",$importsearchpath,$importsearchfile);
        if (-e "$importsearchpath\\$importsearchfile" && $importsearchfile ne "") {
                open(IMPORT,"<$importsearchpath\\$importsearchfile") || die "Cannot open file $!";
                while(<IMPORT>) {
                        chomp;
                        $importstr .= $_ . ",";
                }
                close(IMPORT);
                chop($importstr);
                $txtSearchStr->Enable(1);
                $txtSearchStr->Text("$importstr");
                $importstr = "";
                $Status->Text("Search keywords in file - $importsearchfile");
        }
        else {
                $Status->Text("");
        }
}

sub btnCentralPath_Click {
        $datetime = localtime;
        open (TARLOG, ">>$curdir\\TAR.log") || die "Cannot open TAR.log\n";
        print TARLOG "$datetime : Change SSPECvsMM.csv Path\n";
        $centralpath = &GetFolderName($btnCentralPath,"Setup SSPECvsMM Path","0",$centralpath);
        print TARLOG "\tSSPECvsMM Path: $centralpath\n";
        print STDERR "SSPECvsMM Path: $centralpath\n";
        $txtCentralPath->Text($centralpath);
        $Status->Text("SSPECvsMM Path - $centralpath");
        close(TARLOG);
}

sub txtCentralPath_Change {
        $centralpath = $txtCentralPath->Text;
        $Status->Text("Central Depository Path - $centralpath");
}

sub btnTracePath_Click {
        $datetime = localtime;
        open (TARLOG, ">>$curdir\\TAR.log") || die "Cannot open TAR.log\n";
        print TARLOG "$datetime : Change Data Storage Path\n";
        $tracepath = &GetFolderName($btnTracePath,"Setup Data Storage","0",$tracepath);
        print TARLOG "\tData Storage Path: $tracepath\n";
        print STDERR "Data Storage Path: $tracepath\n";
        $txtTracePath->Text($tracepath);
        $Status->Text("Data Storage Path - $tracepath");
        close(TARLOG);
}

sub txtTracePath_Change {
        $tracepath = $txtTracePath->Text;
        $Status->Text("Data Storage Path - $tracepath");
}

sub btnSearchPath_Click {
        $searchpath = &GetFolderName($btnSearchPath,"Setup Path For Search","0",$searchpath);
        print STDERR "Search Path: $searchpath\n";
        $txtSearchPath->Text($searchpath);
        $Status->Text("Search Path - $searchpath");
}

sub txtSearchPath_Change {
        $searchpath = $txtSearchPath->Text;
        $Status->Text("Search Path - $searchpath");
}

sub btnDirtyLot_Click {
        $datetime = localtime;
        open (TARLOG, ">>$curdir\\TAR.log") || die "Cannot open TAR.log\n";
        print TARLOG "$datetime : Load Contaminated Lot List\n";
        $Status->Text("Locating Contaminated Lot List ...");
        if ($dirtylot =~ /Click Here To Load File/i) {
                $dirtylotpath = $tracepath;
        }
        ($dirtylotpath,$dirtylot) = &GetFileName($btnDirtyLot,"Open Contaminated List For Tracing or DPM Assessment","Comma Separated Values (*.csv)","*.csv",$dirtylotpath);
        if ($dirtylot eq "") {
                $dirtylotpath = $tracepath;
                $dirtylot = "\<Click Here To Load File\>";
                $btnTraceHublean->Enable(0);
                $btnDPMAssess->Enable(0);
                $txtDPMAssessPath->Enable(0);
                $btnDPMAssessPath->Enable(0);
                $Status->Text("");
                print TARLOG "\tLoad Contaminated Lot List Cancelled\n";
        }
        else {
                $btnTraceHublean->Enable(1);
                $btnDPMAssess->Enable(1) if ($txtDPMAssessPath->Text ne "");
                $txtDPMAssessPath->Enable(1);
                $btnDPMAssessPath->Enable(1);
                $Status->Text("Contaminated Lot List - $dirtylotpath\\$dirtylot");
                print TARLOG "\tLoaded $dirtylotpath\\$dirtylot\n";
        }
        print STDERR "Dirty Lot Path: $dirtylotpath\n";
        print STDERR "Dirty Lot List: $dirtylot\n";
        $btnDirtyLot->Text($dirtylot);
        close (TARLOG);
}

sub btnAffectedList_Click {
        $datetime = localtime;
        open (TARLOG, ">>$curdir\\TAR.log") || die "Cannot open TAR.log\n";
        print TARLOG "$datetime : Load Excursion Lot List For DPM Assessment\n";
        $Status->Text("Locating Excursion Lot List ...");
        if ($dirtylot2 =~ /Click Here To Load File/i) {
                $dirtylot2path = $tracepath;
        }
        ($dirtylot2path,$dirtylot2) = &GetFileName($btnAffectedList,"Open Excursion List For DPM Assessment","Comma Separated Values (*.csv)","*.csv",$dirtylot2path);
        if ($dirtylot2 eq "") {
                $dirtylot2path = $tracepath;
                $dirtylot2 = "\<Click Here To Load File\>";
                $btnDPMAssess->Enable(0);
                $txtDPMAssessPath->Enable(0);
                $btnDPMAssessPath->Enable(0);
                $Status->Text("");
                print TARLOG "\tLoad Excursion Lot List for DPM Assessment Cancelled\n";
        }
        else {
                $btnDPMAssess->Enable(1) if ($txtDPMAssessPath->Text ne "");
                $txtDPMAssessPath->Enable(1);
                $btnDPMAssessPath->Enable(1);
                $Status->Text("Excursion Lot List - $dirtylot2path\\$dirtylot2");
                print TARLOG "\tLoaded Excursion Lot List - $dirtylot2path\\$dirtylot2\n";
        }
        print STDERR "Excursion Lot List Path : $dirtylot2path\n";
        print STDERR "Excursion Lot List : $dirtylot2\n";
        $btnAffectedList->Text($dirtylot2);
        close(TARLOG);
}

sub cmbMaxLot_Change {
        $datetime = localtime;
        open (TARLOG, ">>$curdir\\TAR.log") || die "Cannot open TAR.log\n";
        my $maxlotindex = $cmbMaxLot->SelectedItem;
        $maxlot = $cmbMaxLot->GetString($maxlotindex);
        print STDERR "\nMaximum Tracking\/Tracing: $maxlot\n";
        $Status->Text("Maximum Lot Trace/Track is set to $maxlot");
        print TARLOG "$datetime : Maximum Lot/Run Changed to $maxlot\n";
        close (TARLOG);
}

sub GetFolderName() {
        ($button,$title,$editmode,$origfolder) = @_;
        $button->Enable(0);
        $ret = GUI::BrowseForFolder(
                -title  => $title,
                -folderonly => 1,
                -editbox => $editmode,
        );
        $button->Enable(1);
        if ($ret) {
                $origfolder = $ret;
        }
        print STDERR "\n$title: $origfolder\n";
        return $origfolder;
}

sub GetFileName() {
        ($button,$title,$filterdesc,$filter,$setuppath,$application) = @_;
        $button->Enable(0);
        $ret = GUI::GetOpenFileName(
                -title  => $title,
                -file   => "\0" . " " x 256,
                -directory => $setuppath,
                -file => $application,
                -filter => [
                $filterdesc => $filter,
                "All files", "*.*",
                ],
        );
        $button->Enable(1);
        if($ret) {
                @data = split(/\\/,$ret);
                print STDERR "\n$title: '$ret'\n";
                $setuppath = "";
                for ($i = 0; $i < $#data; $i++) {
                         $setuppath .= $data[$i] . "\\";
                }
                chop($setuppath);
                $application = $data[$#data];
        }
        else {
                if(GUI::CommDlgExtendedError()) {
                        $err = GUI::CommDlgExtendedError();
                        print STDERR "\tError - $err\n";
                        $confirm = MsgBox("TAR - $title", "$err", 48);
                } 
                else {
                        print STDERR "\t$title Cancelled.\n";
                }
        }
        return ($setuppath, $application);
}

sub cmbSite_Change {
        $datetime = localtime;
        open (TARLOG, ">>$curdir\\TAR.log") || die "Cannot open TAR.log\n";
        my $siteindex = $cmbSite->SelectedItem;
        $hubleansite = $cmbSite->GetString($siteindex);
        $Status->Text("Selected $hubleansite MARS Server");
        $hubleansitecode = $hubleansite;
        $hubleansite = $hubleansite . "_MARSPROD";
        print STDERR "\nSelected site: $hubleansite\n";
        print TARLOG "$datetime : Change DB Pointer to $hubleansite\n";
        close(TARLOG);
}

sub cmbReport_Change {
        $datetime = localtime;
        open (TARLOG, ">>$curdir\\TAR.log") || die "Cannot open TAR.log\n";
        my $reportindex = $cmbReport->SelectedItem;
        $report = $cmbReport->GetString($reportindex);
        if ($report =~ /trace/i) {
                $Status->Text("Selected Traceability Report");
                $report = "TRACE";
                $lblRptDesc->Text("(Tree Format)");
        }
        else {
                $Status->Text("Selected Detail Tracking Report");
                $report = "TRACK";
                $lblRptDesc->Text("(Detail Format)");
        }
        print STDERR "\nSelected report: $report\n";
        print TARLOG "$datetime : Change Report Format to $report\n";
        close(TARLOG);
}

sub cmbRptOption_Change {
        $datetime = localtime;
        open (TARLOG, ">>$curdir\\TAR.log") || die "Cannot open TAR.log\n";
        my $rptoptionindex = $cmbRptOption->SelectedItem;
        $rptoption = $cmbRptOption->GetString($rptoptionindex);
        if ($rptoption =~ /forward/i) {
                $Status->Text("Selected Report Option: Forward $report");
                $rptoption = "T";
        }
        else {
                $Status->Text("Selected Report Option: Backward $report");
                $rptoption = "F";
        }
        print STDERR "\nSelected report option: $rptoption\n";
        print TARLOG "$datetime : Change Report Option to $rptoption\n";
        close(TARLOG);
}

sub cmbLotOwner_Change {
        $datetime = localtime;
        open (TARLOG, ">>$curdir\\TAR.log") || die "Cannot open TAR.log\n";
        my $lotownerindex = $cmbLotOwner->SelectedItem;
        $lotowner = $cmbLotOwner->GetString($lotownerindex);
        $Status->Text("Selected Lot Owner: $lotowner");
        print STDERR "\nSelected lot owner: $lotowner\n";
        print TARLOG "$datetime : Change Lot Owner to $lotowner\n";
        close(TARLOG);
}

sub btnCrawlForward_Click {
        $datetime = localtime;
        open (TARLOG, ">>$curdir\\TAR.log") || die "Cannot open TAR.log\n";
        print TARLOG "$datetime : Crawl Forward Starts\n";
        print STDERR "\nCrawlForward - Running\n";
        $Status->Text("Crawl Forwarding ...");
        # initialization
        undef %quantity;
        $detected = 0;
        # read all csv files from directory
        if ($tracepath ne "" && -e "$tracepath") {
                chdir "$tracepath";
                opendir(DIR, '.') || die "Cann't open Directory\n";
                local(@files) = readdir(DIR);
                closedir(DIR);
                $format = "";
                $totalfiles = @files;
                $totalpo{'cw'} = 0;
                $totalpo{'wip'} = 0;
                $totalpo{'xship'} = 0;
                $ProgressBar->SetRange(0,$totalfiles);
                $PBcurpos = 0;
                print TARLOG "\tReading Files From $tracepath\n";
                foreach $file (@files) {
                        $PBcurpos += 1;
                        $ProgressBar->SetPos($PBcurpos);
                        #next if ($file eq "$dirtylot");
                        next if ($file !~ /TRACE\_FORWARD.*\.csv$/i);
                        print STDERR "\tTraceability: $file ";
                        print TARLOG "\t\tReading $file\n";
                        open(IN,"<$file") || die "Cannot open $file\n";
                        while(<IN>) {
        	               chomp;
                                # check for input file format
                                if ($_ =~ /\[\d+\]/ && $format eq "") {
                                        $format = "WIP LOT Tracking";
                                        $detected = 1;
                                        print STDERR "is in $format format... ";
                                }
                                elsif ($format eq "") {
                                        $format = "UNDEFINED";
                                        print STDERR "is in $format format... File Ignored.\n";
                                }
                                # Hublean format tracking
                                if ($format eq "WIP LOT Tracking") {
                                        # pattern matching for level, lot, location, qty
                                        $_ =~ /\[(\d+)\][ ](\w+)\((\d+)\/(\d+)/;
                                        $level = $1;
                                        $lot = $2;
                                        $location = $3;
                                        $qty = $4;
                                        # check for MIW lot
                                        if (!defined($defmiwlot{$location}{$lot}) && !defined($defmiwlot{'7399'}{$lot}) && !defined($defmiwlot{'9996'}{$lot}) && $lot =~ /^$fpo/o && $qty == 0 && ($location eq "0001" || $location eq "9996")) {
                                                $defmiwlot{$location}{$lot} = $qty;
                                                # $quantity{'miw'} += $qty;
                                                $totalpo{'cw'} += 1;
                                        }
                                        # check for X-ship lot
                                        if (!defined($defxshiplot{$location}{$lot}) && $lot =~ /^$atpo/o && $qty == 0 && $location eq "0001") {
                        			$defxshiplot{$location}{$lot} = $qty;
                                                # $quantity{'xship'} += $qty;
                                                $totalpo{'xship'} += 1;
                                        }
                                        if ($level == 0) {
                                                $parentlot = $lot;
                                                $tracedlot{$parentlot} = 1;
                                        }
                                        # make a list of parent lots that merge into the child lot, separate by comma
                                        if ($defplot{$lot} !~ /$parentlot/o) {
                                                $defplot{$lot} = $defplot{$lot} . "$parentlot,";
                                        }
                                        # check for WIP lot
                                        if (!defined($defwiplot{$location}{$lot}) && $qty != 0) {
                                                $quantity{'wip'} += $qty;
                                                $defwiplot{$location}{$lot} = $qty;
                                                $totalpo{'wip'} += 1;
                                        }
                                        # $prevloc = $location;
                                }
                        }
                        close(IN);
                        print STDERR "Done.\n" if ($format ne "UNDEFINED");
                        $format = "";
                }
                $ProgressBar->SetPos(0);
                # eliminate additional comma for parent lot list and print result
                if ($status1 ne "(Done)") {
                        foreach $key (keys %defplot) {
                                chop($defplot{$key});
                        }
                }
        }
        # reflect tracedlot
        if ($dirtylot !~ /Click Here To Load File/i && ($detected == 1 || $autocycling)) {
                $Status->Text("Update traced lot status in $dirtylot");
                if (!$autorun) {
                        $confirm = MsgBox("TAR - Update Lot List", "Do you want to update lot status in $dirtylot?", 36);
                }
                else {
                        $confirm = "Yes";
                }
                if ($confirm =~ /yes/i) {
                        print TARLOG "\tUpdate contaminated lot list status\n";
                        print STDERR "\n\tUpdating contaminated lot list ......";
                        open(TMP,">$dirtylotpath\\dirtylot.tmp") || die "Cannot open dirtylot.tmp.\n";
                        open(DIRTY,"<$dirtylotpath\\$dirtylot") || die "Cannot open $dirtylot.\n";
                        chomp($header = <DIRTY>);
                        print TMP "$header\n";
                        $stilldirty = 0;
                        while (<DIRTY>) {
                                chomp;
                                @data = split(',');
                                if ($data[1] =~ /Done/i || defined($tracedlot{$data[0]})) {
                                        print TMP "$data[0],Done\n";
                                }
                                else {
                                        print TMP "$data[0],\n";
                                        $stilldirty = 1;
                                }
                        }
                        close(DIRTY);
                        close(TMP);
                        `copy "$dirtylotpath\\dirtylot.tmp" "$dirtylotpath\\$dirtylot"`;
                        `del "$dirtylotpath\\dirtylot.tmp"`;
                        print STDERR "Done.\n";
                }
        }
        if ($detected != 1) {
                print TARLOG "\tNo file matching traceability format\n";
                print STDERR "\tNo file matching traceability format.\n";
                $confirm = MsgBox("TAR - CrawlForward", "No file matching traceability format.", 48) if ($autocycling != 1);
                $Status->Text("");
        }
        else {
                $btnSaveCrawlForward->Enable(1);
                $btnMatchMM->Enable(1);
                $btnTrackHublean->Enable(1) if (defined(%defmiwlot));
                $status1 = "(Done)";
                $Status->Text("Crawl Forward Completed.");
        }
        chdir "$curdir";
        print STDERR "CrawlForward - Done\n";
        close(TARLOG);
}

sub btnSubmitOperCode_Click {
        $datetime = localtime;
        open (TARLOG, ">>$curdir\\TAR.log") || die "Cannot open TAR.log\n";
        Win32::GUI::Hide($Winpopup1);
        $Window->Show();
        $cblocation = $txtOperCode->Text;
        $txtOperCode->Text("");
        if ($cblocation =~ /^\d{4}$/) {
                &TrackCrawlBackward_Click();
        }
        elsif ($cblocation =~ /^\d{4}\sTRACE/i) {
                &TraceCrawlBackward_Click();
        }
        else {
                print STDERR "\tInvalid operation code. Action Cancelled\n";
        }
        close(TARLOG);
}

sub btnCancelOperCode_Click {
        Win32::GUI::Hide($Winpopup1);
        $Window->Show();
        $cblocation = "";
        $txtOperCode->Text("");
        print STDERR "\tAction Cancelled\n";
        print TARLOG "\tOperation Code Entry Cancelled\n";
}

sub mnuCrawlBackwardToLoc_Click {
        #$chosenopt = "trace";
        $Winpopup1->Show();
        Win32::GUI::Hide($Window);
}

sub mnuTrackCrawlBackwardToLoc_Click {
        #$chosenopt = "track";
        $Winpopup1->Show();
        Win32::GUI::Hide($Window);
}

sub TraceCrawlBackward_Click {
        #$cblocation = $_[0];
        print TARLOG "\tCrawl Backward Tracing to $cblocation\n";
        print STDERR "\nCrawl Backward Tracing to $cblocation - Running\n";
        $Status->Text("Crawling Backward Tracing File to $cblocation ...");
        $detected = 0;
        undef %tracedbacklot;
        undef %defbackplot;
        # read all csv files from directory
        if ($tracepath ne "" && -e "$tracepath") {
                chdir "$tracepath";
                opendir(DIR, '.') || die "Cann't open Directory\n";
                local(@files) = readdir(DIR);
                closedir(DIR);
                $totalfiles = @files;
                $ProgressBar->SetRange(0,$totalfiles);
                $PBcurpos = 0;
                foreach $file (@files) {
                        $PBcurpos += 1;
                        $ProgressBar->SetPos($PBcurpos);
                        next if ($file !~ /TRACE\_BACKWARD.*\.csv$/i);
                        print TARLOG "\t\tReading $file\n";
                        print STDERR "\tTraceability: $file ";
                        open(IN,"<$file") || die "Cannot open $file\n";
                        while(<IN>) {
        	               chomp;
                                # pattern matching for level, lot, location, qty
                                $_ =~ /\[(\d+)\][ ](\w+)\((\d+)\/(\d+)/;
                                $level = $1;
                                $lot = $2;
                                $location = $3;
                                $qty = $4;
                                if ($level == 0) {
                                        $childlot = $lot;
                                        $tracedbacklot{$childlot} = 1;
                                        $detected = 1;
                                }
                                if ($location == $cblocation) {
                                        $defbackplot{$childlot}{$lot} = 1;
                                }
                        }
                        close(IN);
                        print STDERR "Done.\n";
                }
                $ProgressBar->SetPos(0);
        }
        # reflect tracedlot
        if ($dirtylot !~ /Click Here To Load File/i && ($detected == 1 || $autocycling)) {
                $Status->Text("Update traced lot status in $dirtylot");
                if (!$autorun) {
                        $confirm = MsgBox("TAR - Update Lot List", "Do you want to update lot status in $dirtylot?", 36);
                }
                else {
                        $confirm = "Yes";
                }
                if ($confirm =~ /yes/i) {
                        print TARLOG "\tUpdate Backward Traceability Lot List\n";
                        print STDERR "\n\tUpdating backward traceability lot list ......";
                        open(TMP,">$dirtylotpath\\dirtylot.tmp") || die "Cannot open dirtylot.tmp.\n";
                        open(DIRTY,"<$dirtylotpath\\$dirtylot") || die "Cannot open $dirtylot.\n";
                        chomp($header = <DIRTY>);
                        print TMP "$header\n";
                        $stilldirty = 0;
                        while (<DIRTY>) {
                                chomp;
                                @data = split(',');
                                if ($data[1] =~ /Done/i || defined($tracedbacklot{$data[0]})) {
                                        print TMP "$data[0],Done\n";
                                }
                                else {
                                        print TMP "$data[0],\n";
                                        $stilldirty = 1;
                                }
                        }
                        close(DIRTY);
                        close(TMP);
                        `copy "$dirtylotpath\\dirtylot.tmp" "$dirtylotpath\\$dirtylot"`;
                        `del "$dirtylotpath\\dirtylot.tmp"`;
                        print STDERR "Done.\n";
                }
        }
        if ($detected != 1) {
                print TARLOG "\tNo file matching traceability format\n";
                print STDERR "\tNo file matching traceability format.\n";
                $confirm = MsgBox("TAR - CrawlBackward", "No file matching traceability format.", 48) if ($autocycling != 1);
                $Status->Text("");
        }
        else {
                # prompt user for filename to save as
                $savepath = $tracepath;
                ($savepath,$outfile) = &GetFileName($btnDirtyLot,"Save Crawl Backward To Operation $cblocation Result","Comma Separated Values (*.csv)","*.csv",$savepath);
                if ($outfile ne "") {
                        if ($outfile !~ /\.csv$/) {
                                $outfile = $outfile . "\.csv";
                        }
                        $Status->Text("Saving Crawl Backward Results ...");
                        open(OUTX,">$savepath\\$outfile") || die "Cannot open $savepath\\$outfile.\n";
                        print OUTX "Input Lot,Parent Lot at $cblocation\n";
                        foreach $clot (sort keys %defbackplot) {
                                foreach $plot (sort keys (%{defbackplot->{$clot}})) {
                                        print OUTX "$clot,$plot\n";
                                }
                        }
                        close(OUTX);
                        print STDERR "\tExported lot lists to $outfile\n";
                        $Status->Text("Crawl Backward Results Saved.");
                        print TARLOG "\tSave Crawl Backward Results to $outfile\n";
                }
                print STDERR "\tNo Filename: Lot list not exported.\n" if ($outfile eq "");
        }
        chdir "$curdir";
        print STDERR "Crawl Backward To $cboperation - Done\n";
        close(TARLOG);
}

################################# TrackCrawlBackward ######### Need Editing Here ##########
sub TrackCrawlBackward_Click {
        #$cblocation = $_[0];
        print TARLOG "\tCrawl Backward Tracking to $cblocation\n";
        print STDERR "\nCrawl Backward Tracking to $cblocation - Running\n";
        $Status->Text("Crawling Backward Tracking File to $cblocation ...");
        $detected = 0;
        undef %tracedbacklot;
        undef %defbackplot;
        # read all csv files from directory
        if ($tracepath ne "" && -e "$tracepath") {
                chdir "$tracepath";
                opendir(DIR, '.') || die "Cann't open Directory\n";
                local(@files) = readdir(DIR);
                closedir(DIR);
                $totalfiles = @files;
                $ProgressBar->SetRange(0,$totalfiles);
                $PBcurpos = 0;
                foreach $file (@files) {
                        $PBcurpos += 1;
                        $ProgressBar->SetPos($PBcurpos);
                        next if ($file !~ /TRACK\_BACKWARD.*\.csv$/i);
                        print TARLOG "\t\tReading $file\n";
                        print STDERR "\tTraceability: $file ";
                        open(IN,"<$file") || die "Cannot open $file\n";
                        while(<IN>) {
                                chomp;
                                next if (/^lot/i);
                                @data = split(',');
                                $lot = $data[0];
                                $location = $data[6];
                                #$qty = $data[11];
                                if ($lot eq "") {
                                        $lot = $prevlot;
                                }
                                else {
                                        $prevlot = $lot;
                                }
                                if ($. == 2) {
                                        $childlot = $lot;
                                        $tracedbacklot{$childlot} = 1;
                                        $detected = 1;
                                }
                                if ($location == $cblocation) {
                                        $defbackplot{$childlot}{$lot} = 1;
                                }
                        }
                        close(IN);
                        print STDERR "Done.\n";
                }
                $ProgressBar->SetPos(0);
        }
        # reflect tracedlot
        if ($dirtylot !~ /Click Here To Load File/i && ($detected == 1 || $autocycling)) {
                $Status->Text("Update tracked lot status in $dirtylot");
                if (!$autorun) {
                        $confirm = MsgBox("TAR - Update Lot List", "Do you want to update lot status in $dirtylot?", 36);
                }
                else {
                        $confirm = "Yes";
                }
                if ($confirm =~ /yes/i) {
                        print TARLOG "\tUpdate Backward Tracking Lot List\n";
                        print STDERR "\n\tUpdating backward tracking lot list ......";
                        open(TMP,">$dirtylotpath\\dirtylot.tmp") || die "Cannot open dirtylot.tmp.\n";
                        open(DIRTY,"<$dirtylotpath\\$dirtylot") || die "Cannot open $dirtylot.\n";
                        chomp($header = <DIRTY>);
                        print TMP "$header\n";
                        $stilldirty = 0;
                        while (<DIRTY>) {
                                chomp;
                                @data = split(',');
                                if ($data[1] =~ /Done/i || defined($tracedbacklot{$data[0]})) {
                                        print TMP "$data[0],Done\n";
                                }
                                else {
                                        print TMP "$data[0],\n";
                                        $stilldirty = 1;
                                }
                        }
                        close(DIRTY);
                        close(TMP);
                        `copy "$dirtylotpath\\dirtylot.tmp" "$dirtylotpath\\$dirtylot"`;
                        `del "$dirtylotpath\\dirtylot.tmp"`;
                        print STDERR "Done.\n";
                }
        }
        if ($detected != 1) {
                print TARLOG "\tNo file matching tracking format\n";
                print STDERR "\tNo file matching backward tracking format.\n";
                $confirm = MsgBox("TAR - CrawlBackward", "No file matching tracking format.", 48) if ($autocycling != 1);
                $Status->Text("");
        }
        else {
                # prompt user for filename to save as
                $savepath = $tracepath;
                ($savepath,$outfile) = &GetFileName($btnDirtyLot,"Save Crawl Backward To Operation $cblocation Result","Comma Separated Values (*.csv)","*.csv",$savepath);
                if ($outfile ne "") {
                        if ($outfile !~ /\.csv$/) {
                                $outfile = $outfile . "\.csv";
                        }
                        $Status->Text("Saving Crawl Backward Results ...");
                        open(OUTX,">$savepath\\$outfile") || die "Cannot open $savepath\\$outfile.\n";
                        print OUTX "Input Lot,Parent Lot at $cblocation\n";
                        foreach $clot (sort keys %defbackplot) {
                                foreach $plot (sort keys (%{defbackplot->{$clot}})) {
                                        print OUTX "$clot,$plot\n";
                                }
                        }
                        close(OUTX);
                        print STDERR "\tExported lot lists to $outfile\n";
                        $Status->Text("Crawl Backward Results Saved.");
                        print TARLOG "\tSave Crawl Backward Results to $outfile\n";
                }
                print STDERR "\tNo Filename: Lot list not exported.\n" if ($outfile eq "");
        }
        chdir "$curdir";
        print STDERR "Crawl Backward To $cboperation - Done\n";
        close(TARLOG);
}

sub Window_Terminate {
        open(TARLOG, ">>$curdir\\TAR.log") || die "Cannot open TAR.log\n";
        print TARLOG "##### Traceability Analysis & Reporting #####\n\n";
        $datetime = localtime;
        print TARLOG "Traceability Analysis \& Reporting $thisversion Exited : $datetime\n";
        close(TARLOG);
        Win32::GUI::Hide($Window);
        return -1;
}

sub mnuLoadList_Click {
        &btnDirtyLot_Click;
}

sub mnuSaveSetup_Click {
        &btnSaveSetup_Click;
}

sub mnuLoadSetup_Click {
        &btnLoadSetup_Click;
}

sub mnuExit_Click {
        &Window_Terminate;
}

sub mnuAutorunHublean_Click {
        $datetime = localtime;
        open(TARLOG, ">>$curdir\\TAR.log") || die "Cannot open TAR.log\n";
        print TARLOG "$datetime : Autorun Single Site Launch\n";
        close(TARLOG);
        if ($chkWIPTracking->Checked()) {
                $confirm = MsgBox("TAR - Autorun Error", "No Autorun for \"Customize Trace/Track\".", 64);
        }
        else {
                $autorun = 1;
                $Status->Text("Autorun WIP LOT Traceability & Tracking");
                $confirm = MsgBox("TAR - Autorun", "Do you have all necessary path setup done?", 36);
                if ($confirm =~ /yes/i) {
                        print STDERR "\nAutorun WIP LOT Trace/Track Begin\n";
                        &btnDirtyLot_Click;
                        $cmbMaxLot->Select(0);
                        $maxlot = 1;
                        &btnTraceHublean_Click;
                        &btnCrawlForward_Click;
                        $cmbMaxLot->Select(9);
                        $maxlot = 10;
                        &btnTrackHublean_Click;
                        &btnMatchMM_Click;
                        if ($speednumber ne "" && $status12 eq "(Done)") {
                                &btnSaveDatasheet_Click;
                        }
                        else {
                                $confirm = MsgBox("TAR - Autorun Complete", "Please type in Speed # and save datasheets.", 64);
                        }
                        print STDERR "\nAutorun WIP LOT Trace/Track Completed.\n";
                }
                $autorun = 0;
                $cmbMaxLot->Select(0);
                $maxlot = 1;
                $Status->Text("");
        }
}

sub mnuAutorunCycle_Click() {
        $datetime = localtime;
        open(TARLOG, ">>$curdir\\TAR.log") || die "Cannot open TAR.log\n";
        print TARLOG "$datetime : Autorun Multiple Site Launch\n";
        close(TARLOG);
        if ($chkWIPTracking->Checked()) {
                $confirm = MsgBox("TAR - Autorun Error", "No Autorun for \"Customize Trace/Track\".", 64);
        }
        else {
                $autorun = 1;
                $autocycling = 1;
                $Status->Text("Auto Cycle-Site For WIP LOT Traceability");
                $confirm = MsgBox("TAR - Autorun", "Do you have all necessary path setup done?", 36);
                if ($confirm =~ /yes/i) {
                        print STDERR "\nAuto Cycle-Site For WIP LOT Trace/Track Begin\n";
                        &btnDirtyLot_Click;
                        $cmbMaxLot->Select(0);
                        $maxlot = 1;
                        &btnTraceHublean_Click;
                        &btnCrawlForward_Click;
                        $tracedhubleansite = $hubleansite;
                        $tracedhubleansitecode = $hubleansitecode;
                        @allhubleansite = ('PG_MARSPROD','KM_MARSPROD','CR_MARSPROD','CV_MARSPROD','PD_MARSPROD');
                        foreach $s (@allhubleansite) {
                                if ($stilldirty) {
                                        next if ($tracedhubleansite eq $s);
                                        @data = split('_',$s);
                                        $hubleansitecode = $data[0];
                                        $hubleansite = $s;
                                        &btnTraceHublean_Click;
                                        &btnCrawlForward_Click;
                                }
                        }
                        $cmbMaxLot->Select(9);
                        $maxlot = 10;
                        $hubleansite = $tracedhubleansite;
                        $hubleansitecode = $tracedhubleansitecode;
                        &btnTrackHublean_Click;
                        &btnMatchMM_Click;
                        if ($speednumber ne "" && $status12 eq "(Done)") {
                                &btnSaveDatasheet_Click;
                        }
                        else {
                                $confirm = MsgBox("TAR - Autorun Complete", "Please type in Speed # and save datasheets.", 64);
                        }
                        print STDERR "\nAutorun WIP LOT Trace/Track Completed.\n";
                        
                }
                $cmbMaxLot->Select(0);
                $maxlot = 1;
                $autorun = 0;
                $autocycling = 0;
                $Status->Text("");
        }
}

sub btnTrackHublean_Click() {
        $datetime = localtime;
        open(TARLOG, ">>$curdir\\TAR.log") || die "Cannot open TAR.log\n";
        $customize = 0;
        $Window->Text("Traceability Analysis & Reporting $thisversion");
        #if ($validuser) {
                print TARLOG "$datetime : WIP Lot Tracking Starts\n";
                print STDERR "\nWIP LOT Tracking - Running\n";
                $tracepath = $txtTracePath->Text;
                if ($status1 eq "(Done)" && $tracepath ne "") {
                        if (!-e "$tracepath") {
                                $Status->Text("Creating Data Storage - $tracepath");
                                print TARLOG "\tCreate Storage : $tracepath\n";
                                `mkdir "$tracepath"`;
                        }
                        $tmpmax = $maxlot;
                        $maxlot = 10 if (!$chkWIPTracking->Checked());
                        print TARLOG "\tMax Lot per Run : $maxlot\n";
                        $cnt{'PG'} = 0;
                        $cnt{'KM'} = 0;
                        $cnt{'CV'} = 0;
                        $cnt{'CR'} = 0;
                        $cnt{'PD'} = 0;
                        # $cnt{'CH'} = 0;
                        $lotlist{'PG'} = "";
                        $lotlist{'KM'} = "";
                        $lotlist{'CR'} = "";
                        $lotlist{'CV'} = "";
                        $lotlist{'PD'} = "";
                        # $lotlist{'CH'} = "";
                        undef %miw;
                        $Status->Text("Start Detail Tracking For CW Lots");
                        print TARLOG "\tStart Detail Tracking for CW Lots\n";
                        $ProgressBar->SetRange(0,$totalpo{'cw'});
                        $PBcurpos = 0;
                        foreach $loc (keys %defmiwlot) {
                                foreach $lot (keys (%{defmiwlot->{$loc}})) {
                                        next if (defined($miw{$lot}));
                                        if ($lot =~ /^L/) {
                                                $cnt{'PG'} += 1;
                                                if ($cnt{'PG'} <= $maxlot) {
                                                        $lotlist{'PG'} .= $lot . "+";
                                                }
                                        }
                                        if ($lot =~ /^Q/) {
                                                $cnt{'KM'} += 1;
                                                if ($cnt{'KM'} <= $maxlot) {
                                                        $lotlist{'KM'} .= $lot . "+";
                                                }
                                        }
                                        if ($lot =~ /^3/) {
                                                $cnt{'CR'} += 1;
                                                if ($cnt{'CR'} <= $maxlot) {
                                                        $lotlist{'CR'} .= $lot . "+";
                                                }
                                        }
                                        if ($lot =~ /^5/) {
                                                $cnt{'PD'} += 1;
                                                if ($cnt{'PD'} <= $maxlot) {
                                                        $lotlist{'PD'} .= $lot . "+";
                                                }
                                        }
                                        if ($lot =~ /^7/) {
                                                $cnt{'CV'} += 1;
                                                if ($cnt{'CV'} <= $maxlot) {
                                                        $lotlist{'CV'} .= $lot . "+";
                                                }
                                        }
                                        $miw{$lot} = 1;
                                        foreach $sitelotcnt (keys %cnt) {
                                                if ($cnt{$sitelotcnt} == $maxlot) {
                                                        # launch hublean tracking and reset $i
                                                        $Status->Text("Tracking $sitelotcnt Lots");
                                                        #if ($sitelotcnt =~ /PG/) {
                                                        #        $hubleansite = "MARSPROD";
                                                        #}
                                                        #else {
                                                                $hubleansite = $sitelotcnt . "_MARSPROD";
                                                        #}
                                                        $hubleansitecode = $sitelotcnt;
                                                        LaunchHublean($lotlist{$sitelotcnt},"TRACK",$customize,$lotowner,$rptoption,$hubleansite,$tracepath);
                                                        $PBcurpos += $cnt{$sitelotcnt};
                                                        $ProgressBar->SetPos($PBcurpos);
                                                        $cnt{$sitelotcnt} = 0;
                                                        $lotlist{$sitelotcnt} = "";
                                                }
                                        }
                                }
                        }
                        # track remaining lots
                        foreach $sitelotcnt (keys %cnt) {
                                if ($cnt{$sitelotcnt} != 0) {
                                        $Status->Text("Tracking $sitelotcnt Lots");
                                        #if ($sitelotcnt =~ /PG/) {
                                        #        $hubleansite = "MARSPROD";
                                        #}
                                        #else {
                                                $hubleansite = $sitelotcnt . "_MARSPROD";
                                        #}
                                        $hubleansitecode = $sitelotcnt;
                                        LaunchHublean($lotlist{$sitelotcnt},"TRACK",$customize,$lotowner,$rptoption,$hubleansite,$tracepath);
                                        $PBcurpos += $cnt{$sitelotcnt};
                                        $ProgressBar->SetPos($PBcurpos);
                                        $cnt{$sitelotcnt} = 0;
                                        $lotlist{$sitelotcnt} = "";
                                }
                        }
        # changes ends here
        # changes starts here
                        undef %xship;
                        print TARLOG "\tStart Detail Tracking for Xship Lots\n";
                        $Status->Text("Start Detail Tracking For Xship Lots");
                        $ProgressBar->SetRange(0,$totalpo{'xship'});
                        $PBcurpos = 0;
                        foreach $loc (keys %defxshiplot) {
                                foreach $lot (keys (%{defxshiplot->{$loc}})) {
                                        next if (defined($xship{$lot}));
                                        if ($lot =~ /^M/) {
                                                $cnt{'PG'} += 1;
                                                if ($cnt{'PG'} <= $maxlot) {
                                                        $lotlist{'PG'} .= $lot . "+";
                                                }
                                        }
                                        if ($lot =~ /^T/) {
                                                $cnt{'KM'} += 1;
                                                if ($cnt{'KM'} <= $maxlot) {
                                                        $lotlist{'KM'} .= $lot . "+";
                                                }
                                        }
                                        if ($lot =~ /^4/) {
                                                $cnt{'CR'} += 1;
                                                if ($cnt{'CR'} <= $maxlot) {
                                                        $lotlist{'CR'} .= $lot . "+";
                                                }
                                        }
                                        if ($lot =~ /^9/) {
                                                $cnt{'PD'} += 1;
                                                if ($cnt{'PD'} <= $maxlot) {
                                                        $lotlist{'PD'} .= $lot . "+";
                                                }
                                        }
                                        if ($lot =~ /^6/) {
                                                $cnt{'CV'} += 1;
                                                if ($cnt{'CV'} <= $maxlot) {
                                                        $lotlist{'CV'} .= $lot . "+";
                                                }
                                        }
                                        $xship{$lot} = 1;
                                        foreach $sitelotcnt (keys %cnt) {
                                                if ($cnt{$sitelotcnt} == $maxlot) {
                                                        # launch hublean tracking and reset $i
                                                        $Status->Text("Tracking $sitelotcnt Lots");
                                                        #if ($sitelotcnt =~ /PG/) {
                                                        #        $hubleansite = "MARSPROD";
                                                        #}
                                                        #else {
                                                                $hubleansite = $sitelotcnt . "_MARSPROD";
                                                        #}
                                                        $hubleansitecode = $sitelotcnt;
                                                        LaunchHublean($lotlist{$sitelotcnt},"TRACK",$customize,$lotowner,$rptoption,$hubleansite,$tracepath);
                                                        $PBcurpos += $cnt{$sitelotcnt};
                                                        $ProgressBar->SetPos($PBcurpos);
                                                        $cnt{$sitelotcnt} = 0;
                                                        $lotlist{$sitelotcnt} = "";
                                                }
                                        }
                                }
                        }
                        # track remaining lots
                        foreach $sitelotcnt (keys %cnt) {
                                if ($cnt{$sitelotcnt} != 0) {
                                        $Status->Text("Tracking $sitelotcnt Lots");
                                        #if ($sitelotcnt =~ /PG/) {
                                        #        $hubleansite = "MARSPROD";
                                        #}
                                        #else {
                                                $hubleansite = $sitelotcnt . "_MARSPROD";
                                        #}
                                        $hubleansitecode = $sitelotcnt;
                                        LaunchHublean($lotlist{$sitelotcnt},"TRACK",$customize,$lotowner,$rptoption,$hubleansite,$tracepath);
                                        $PBcurpos += $cnt{$sitelotcnt};
                                        $ProgressBar->SetPos($PBcurpos);
                                        $cnt{$sitelotcnt} = 0;
                                        $lotlist{$sitelotcnt} = "";
                                }
                        }
        # changes ends here for xship lot detail tracking
                        $ProgressBar->SetPos(0);
                        $status11 = "(Done)";
                        $Status->Text("Detail Tracking Done");
                        $maxlot = $tmpmax;
                }
                else {
                        $Status->Text("");
                        print STDERR "\n\tNo data in memory for tracking.\n";
                        print TARLOG "\tNo data in memory for tracking\n";
                        print STDERR "\n\tStorage path missing.\n" if ($tracepath eq "");
                        print TARLOG "\tStorage path missing\n" if ($tracepath eq "");
                        $confirm = MsgBox("TAR - Tracking Error", "No data in memory for tracking or storage path missing.", 48) if ($autocycling != 1);
                }
                print STDERR "WIP LOT Tracking - Done\n";
                undef %cnt;
                undef %lotlist;
                undef %miw;     # added 5/7/2003 - free up memory
                undef %xship;   # added 5/7/2003 - free up memory
                close(TARLOG);
        #}
} # end sub HubleanTrack

sub btnTraceHublean_Click {
        $datetime = localtime;
        open(TARLOG, ">>$curdir\\TAR.log") || die "Cannot open TAR.log\n";
        $Window->Text("Traceability Analysis & Reporting $thisversion");
        #if ($validuser) {
                print TARLOG "$datetime : WIP Lot Tracking Starts\n";
                $customize = 1 if ($chkWIPTracking->Checked());
                $customize = 0 if (!$chkWIPTracking->Checked());
                print STDERR "\nWIP LOT Traceablility - Running\n";
                $tracepath = $txtTracePath->Text;
                if ($dirtylot !~ /Click Here To Load File/i && $tracepath ne "") {
                        if (!-e "$tracepath") {
                                $Status->Text("Creating Data Storage - $tracepath");
                                print TARLOG "\tCreate Storage : $tracepath\n";
                                `mkdir "$tracepath"`;
                        }
                        # read input file
                        $gotdirty = 0;
                        $totaldirtylot = 0;
                        undef %dirty;
                        open(DIRTY,"<$dirtylotpath\\$dirtylot") || die "Cannot open file $dirtylotpath\\$dirtylot.\n";
                        chomp($header = <DIRTY>);
                        while(<DIRTY>) {
                                chomp;
                                ($lot,$tracestatus) = split(',');
                                if ($tracestatus !~ /Done/i) {
                                        $dirty{$lot} = 1;
                                        $totaldirtylot += 1;
                                        $gotdirty = 1;
                                }
                        }
                        close(DIRTY);
                        $i = 0;
                        $lotlist = "";
                        $Status->Text("Start Traceability");
                        print TARLOG "\tStart Traceability\n";
                        $ProgressBar->SetRange(0,$totaldirtylot);
                        $PBcurpos = 0;
                        foreach $lot (sort keys %dirty) {
                                $i += 1;
                                if ($i <= $maxlot) {
                                        $lotlist = $lotlist . "$lot" . "+";
                                }
                                if ($i == $maxlot) {
                                        # launch hublean traceability and reset $i
                                        if ($customize == 1) {
                                                LaunchHublean($lotlist,$report,$customize,$lotowner,$rptoption,$hubleansite,$tracepath);
                                        }
                                        else {
                                                LaunchHublean($lotlist,"TRACE",$customize,$lotowner,$rptoption,$hubleansite,$tracepath);
                                        }
                                        $PBcurpos += $i;
                                        $ProgressBar->SetPos($PBcurpos);
                                        $i = 0;
                                        $lotlist = "";
                                }
                        }
                        if ($i != 0) {
                                # trace remaining lots
                                if ($customize == 1) {
                                        LaunchHublean($lotlist,$report,$customize,$lotowner,$rptoption,$hubleansite,$tracepath);
                                }
                                else {
                                        LaunchHublean($lotlist,"TRACE",$customize,$lotowner,$rptoption,$hubleansite,$tracepath);
                                }
                                $PBcurpos += $i;
                                $ProgressBar->SetPos($PBcurpos);
                                $i = 0;
                                $lotlist = "";
                        }
                        $ProgressBar->SetPos(0);
                        $Status->Text("Traceability Done");
                        $status10 = "(Done)";
                        if ($gotdirty == 0 && $autocycling != 1) {
                                print STDERR "\n\tNo lot to be traced.\n";
                                $Status->Text("");
                                $confirm = MsgBox("TAR - Traceability Error", "No lot to be traced", 48);
                        }
                }
                if ($tracepath eq "") {
                        print TARLOG "\tStorage path missing\n";
                        print STDERR "\n\tStorage path missing.\n";
                        $confirm = MsgBox("TAR - Traceability Error", "Storage path missing", 48);
                }
                print STDERR "WIP LOT Traceability - Done\n";
                undef %dirty;   # added 5/7/2003 - free up memory
                close(TARLOG);
        #}
}

sub btnMatchMM_Click {
        $datetime = localtime;
        open(TARLOG, ">>$curdir\\TAR.log") || die "Cannot open TAR.log\n";
        print TARLOG "$datetime : Matching S-spec vs MM#\n";
        print STDERR "S-spec vs MM# Matching - Running\n";
        if (!-e "$centralpath\\SSPECvsMM.csv" || !-e "$tracepath") {
                print STDERR "\tCannot find required file in Central Storage\/Data Storage.";
                print STDERR "\n\tOR Central Storage\/Data Storage path not defined.\n";
                print TARLOG "\tCannot find SSPECvsMM.csv or Data Storage missing\n";
                $confirm = MsgBox("TAR - SSpec vs MM# Matching Error", "Required file not found or path missing.", 48);
        }
        else {
                # open MM files and do matching...
                print TARLOG "\tReading SSPECvsMM.csv\n";
                $Status->Text("Matching MM numbers and S-spec");
                open(MM,"<$centralpath\\SSPECvsMM.csv") || die "Cannot open $centralpath\\SSPECvsMM.csv\n";
                chomp($header = <MM>);
                while(<MM>) {
                        chomp;
                        @data = split(',');
                        $mmnumber{$data[2]} = $data[3];
                }
                close(MM);
        } # file read
                # read all csv files from directory
                chdir "$tracepath";
                opendir(DIR, '.') || die "Cann't open Directory\n";
                local(@files) = readdir(DIR);
                closedir(DIR);
                $matchingflag = 0;
                $totalfiles = @files;
                $ProgressBar->SetRange(0,$totalfiles);
                $PBcurpos = 0;
                foreach $file (@files) {
                        $PBcurpos += 1;
                        $ProgressBar->SetPos($PBcurpos);
                        #next if ($file !~ /\.csv$/i);
                        next if ($file !~ /TRACK\_FORWARD.*\.csv$/i);
                        print TARLOG "\tReading: $file\n";
                        print STDERR "\tReading: $file\n";
                        $Status->Text("Reading file: $file");
                        open(IN,"<$file") || die "Cannot open file $file.\n";
                        chomp($header = <IN>);
                        while (<IN>) {
                                chomp;
                                @data = split(',');
                                if ($data[0] =~ /^$fpo/o || $data[0] =~ /^$atpo/o) {
                                        $xlot = $data[0];
                                }
                                # watch out for s-spec change
                                if ($data[1] ne "" && $xlot =~ /^$fpo/o) {
                                        $product = $data[1];
                                        $sspec = substr($product,16,4);
                                        $partname{$xlot} = $product;
                                }
                                if ($data[0] eq "" && ($data[6] == 1 || $data[6] == 9996) && $xlot =~ /^$fpo/o) {
                                        $miwqty{$xlot} = $data[10];
                                        $miwmm{$xlot} = $mmnumber{$sspec};
                                        $matchingflag = 1;
                                        $xlot = "";

                                }
                                if ($data[0] eq "" && ($data[6] == 1 || $data[6] == 9996) && $xlot =~ /^$atpo/o) {
                                        $xshipqty{$xlot} = $data[10];
                                        $matchingflag = 1;
                                        $xlot = "";
                                }
                        }
                        close(IN);
                }
                $ProgressBar->SetPos(0);
                foreach $loc (keys %defmiwlot) {
                        foreach $lot (keys (%{defmiwlot->{$loc}})) {
                                $quantity{'miw'} += $miwqty{$lot};
                                # print OUT2 "$lot,$miwmm{$lot},$miwqty{$lot}\n";
                        }
                }
                foreach $loc (keys %defxshiplot) {
                        foreach $lot (keys (%{defxshiplot->{$loc}})) {
                                $quantity{'xship'} += $xshipqty{$lot};
                        }
                }
                if ($matchingflag == 1) {
                        print STDERR "\n\tMatching done.  Remember to save your data.\n";
                        $status12 = "(Done)";
                        $btnSaveDatasheet->Enable(1) if ($speednumber ne "");
                        $btnPrintSummary->Enable(1);
                        $Status->Text("Matching MM number and S-spec completed.");
                }
                else {
                        $Status->Text("No MM number vs S-spec matching found");
                }
        #}
        chdir "$curdir";
        print STDERR "S-spec vs MM# Matching - Done\n";
        close(TARLOG);
}

sub txtSpeedNumber_Change {
        $speednumber = $txtSpeedNumber->Text;
        if ($speednumber ne "" && $status12 eq "(Done)") {
                $btnSaveDatasheet->Enable(1);
        }
        else {
                $btnSaveDatasheet->Enable(0);
        }
}

sub btnSaveDatasheet_Click {
        $datetime = localtime;
        open(TARLOG, ">>$curdir\\TAR.log") || die "Cannot open TAR.log\n";
        print TARLOG "$datetime : Save Datasheet\n";
        print STDERR "\nSave Datasheet - Running\n";
        $saveoption = $_[0];
        if ($status1 eq "(Done)") {
                chdir "$tracepath";
                if ($totalpo{'wip'} != 0) {
                        $Status->Text("Saving WIP lots into DS_wip.csv");
                        print TARLOG "\tSaving WIP Datasheet\n";
                        open(OUT1,">DS_wip.csv") || die "Cannot open DS_wip.csv\n";
                        print OUT1 "WIPLot,Operation,LotQty,ParentLot(s),TotalQty:,$quantity{'wip'},$system,$user,$speednumber\n";
                        foreach $loc (sort keys %defwiplot) {
                                foreach $clot (sort keys (%{defwiplot->{$loc}})) {
                                        print OUT1 "$clot,$loc,$defwiplot{$loc}{$clot},$defplot{$clot}\n";
                                }
                        }
                        close(OUT1);
                        print STDERR "\tDS_wip.csv saved.\n";
                }
                else {
                        print TARLOG "\tNo lot in WIP\n";
                        print STDERR "\tNo lot in WIP.\n";
                }
                
                # print output for X-ship
                if ($totalpo{'xship'} != 0) {
                        $Status->Text("Saving XSHIP lots into DS_xship.csv");
                        print TARLOG "\tSaving X-ship Datasheet\n";
                        open(OUT3,">DS_xship.csv") || die "Cannot open DS_xship.csv\n";
                        print OUT3 "X-ShipLots,Operation,LotQty,ParentLot(s),TotalQty:,$quantity{'xship'},$system,$user,$speednumber\n";
                        foreach $loc (sort keys %defxshiplot) {
                                foreach $clot (sort keys (%{defxshiplot->{$loc}})) {
                                        print OUT3 "$clot,$loc,$xshipqty{$clot},$defplot{$clot}\n";
                                }
                        }
                        close(OUT3);
                        print STDERR "\tDS_xship.csv saved.\n";
                }
                else {
                        print TARLOG "\tNo lot xship\n";
                        print STDERR "\tNo lot xship\n";
                }
                if ($totalpo{'cw'} != 0) {
                        $Status->Text("Saving CW lots into DS_cw.csv");
                        print TARLOG "\tSaving CW Datasheet\n";
                        open(OUT2,">DS_cw.csv") || die "Cannot open DS_cw.csv\n";
                        print OUT2 "CW Lots,MM#,LotQty,Partname,Parent Lot(s),TotalQty,$quantity{'miw'},$system,$user,$speednumber\n";
                        foreach $loc (keys %defmiwlot) {
                                foreach $lot (keys (%{defmiwlot->{$loc}})) {
                                        print OUT2 "$lot,$miwmm{$lot},$miwqty{$lot},$partname{$lot},$defplot{$lot}\n";
                                }
                        }
                        close(OUT2);
                        print STDERR "\tDS_cw.csv saved.\n";
                }
                else {
                        print TARLOG "\tNo lot in warehouse\n";
                        print STDERR "\tNo lot in warehouse.\n";
                }
                $status7 = "(Done)";
                chdir "$curdir";
                #print STDERR "Save Datasheet - Done\n";
                $Status->Text("");
        }
        else {
                print TARLOG "\tNo WIP, CW or X-ship data in memory to be saved\n";
                print STDERR "\tNo WIP, CW or X-ship data in memory to be saved.\n";
                $Status->Text("");
                $confirm = MsgBox("TAR - Save Datasheet Error", "No data in memory to be saved.", 48);
        }
        close(TARLOG);
}

sub btnClearArray_Click {
        $datetime = localtime;
        open(TARLOG, ">>$curdir\\TAR.log") || die "Cannot open TAR.log\n";
        print TARLOG "$datetime : Clear Memory\n";
        print STDERR "\nClear Memory - Running\n";
        $forceclear = $_[0];
        if ($status1 eq "(Done)" && $status7 ne "(Done)" && $forceclear != 1) {
                $confirm = MsgBox("TAR - Clear Memory", "Data in memory not save. Proceed anyway?", 33);
        }
        if ($confirm =~ /Ok/i || $status1 ne "(Done)" || $status7 eq "(Done)") {
                $Status->Text("Purging memory ...");
                print TARLOG "\tPurged memory array\n";
                print STDERR "\tPurging memory array... \n";
                undef %partname;
                undef %defplot;
                undef %defwiplot;
                undef %defmiwlot;
                undef %defxshiplot;
                undef @files;
                undef %datasheet;
                undef %quantity;
                undef @data;
                undef %miw;
                undef %dirty;
                undef %tracedlot;
                undef %lots;
                undef %qtyfpo;
                undef %qtyfpofabrun;
                undef %qtyfpofabrunwafer;
                undef %binunit;
                undef %badfabrun;
                undef %badwafer;
                undef %miwqty;
                undef %xshipqty;
                undef %miwmm;
                undef %mmnumber;
                undef %totalpo;
                undef %locqty;
                undef @parent_data;
                $status1 = "";
                $status3 = "";
                $status7 = "";
                $status10 = "";
                $status11 = "";
                $status12 = "";
                $list = "";
                # $phqgotinfo = 0;
                $btnSaveCrawlForward->Enable(0);
                $btnTrackHublean->Enable(0);
                $btnMatchMM->Enable(0);
                $btnSaveDatasheet->Enable(0);
                $btnPrintSummary->Enable(0);
                print STDERR "Clear Memory - Done\n";
                $Status->Text("Memory purged.");
        }
        else {
                print TARLOG "\tMemory not cleared\n";
                print STDERR "Memory not cleared.\n";
        }
        close(TARLOG);
}

sub MsgBox {
    my ($caption, $message, $icon_buttons) = @_;
    my @return = qw/- Ok Cancel Abort Retry Ignore Yes No/;
    my $result = Win32::MsgBox($message, $icon_buttons, $caption);
    return $return[$result];
} # end sub MsgBox

sub btnSaveCrawlForward_Click {
        $datetime = localtime;
        open(TARLOG, ">>$curdir\\TAR.log") || die "Cannot open TAR.log\n";
        print TARLOG "$datetime : Save CrawlForward Result\n";
        print STDERR "\nSave CrawlForward Result - Running\n";
        if ($status1 eq "(Done)") {
                $savepath = $tracepath;
                ($savepath,$outfile) = &GetFileName($btnSaveCrawlForward,"Save CrawlForward Result","Comma Separated Values (*.csv)","*.csv",$savepath);
                if ($outfile ne "") {
                        if ($outfile !~ /\.csv$/) {
                                $outfile = $outfile . "\.csv";
                        }
                        $Status->Text("Saving Crawl Forward Results ...");
                        open(OUTX,">$savepath\\$outfile") || die "Cannot open $savepath\\$outfile.\n";
                        print TARLOG "\tPrinting CrawlForward Result for WIP lots\n";
                        print OUTX "WIPLot,Operation,LotQty,ParentLot(s)\n";
                        foreach $loc (sort keys %defwiplot) {
                                foreach $clot (sort keys (%{defwiplot->{$loc}})) {
                                        print OUTX "$clot,$loc,$defwiplot{$loc}{$clot},$defplot{$clot}\n";
                                }
                        }
                        print TARLOG "\tPrinting CrawlForward Result for CW lots\n";
                        print OUTX "\nCWLot,Operation,LotQty,ParentLot(s)\n";
                        foreach $loc (sort keys %defmiwlot) {
                                foreach $clot (sort keys (%{defmiwlot->{$loc}})) {
                                        print OUTX "$clot,$loc,$defmiwlot{$loc}{$clot},$defplot{$clot}\n";
                                }
                        }
                        print TARLOG "\tPrinting CrawlForward Result for X-ship lots\n";
                        print OUTX "\nX-ShipLot,Operation,LotQty,ParentLot(s)\n";
                        foreach $loc (sort keys %defxshiplot) {
                                foreach $clot (sort keys (%{defxshiplot->{$loc}})) {
                                        print OUTX "$clot,$loc,$defxshiplot{$loc}{$clot},$defplot{$clot}\n";
                                }
                        }
                        close(OUTX);
                        print STDERR "\tExported lot lists to $outfile\n";
                        $Status->Text("Crawl Forward Results Saved.");
                        $status3 = "(Done)";
                }
                print TARLOG "\tNo Filename: Lot list not exported\n" if ($outfile eq "");
                print STDERR "\tNo Filename: Lot list not exported.\n" if ($outfile eq "");
        }
        else { 
                $Status->Text("No data to generate result file");
                print TARLOG "\tNo data to generate list\n";
                print STDERR "\tNo data to generate list.\n";
                $confirm = MsgBox("TAR - Save Result Error", "No data to generate result file.", 48);
        }
        print STDERR "Save CrawlForward Result - Done\n";
        close(TARLOG);
}

sub btnSearch_Click {
        $keywordstr = $txtSearchStr->Text;
        if ($keywordstr ne "" && -e "$searchpath") {
                print STDERR "\n\tStart Searching....\n";
                $Status->Text("Searching...");
                @keyword = split(',',$keywordstr);
                $lvwSearchResult->Clear();
                undef @files;
                undef @data;
                undef %searchfile;
                chdir "$searchpath";
                opendir(DIR, '.') || die "Cann't open Directory\n";
                local(@files) = readdir(DIR);
                closedir(DIR);
                $format = "";
                $totalfiles = @files;
                $ProgressBar->SetRange(0,$totalfiles);
                $PBcurpos = 0;
                foreach $file (@files) {
                        $PBcurpos += 1;
                        $ProgressBar->SetPos($PBcurpos);
                        next if ($file !~ /\.csv$/ && $file !~ /\.txt$/);
                        foreach  $tempstr (@keyword) {
                                next if ($tempstr eq "");
                                $str = $tempstr;
                                $str =~ s/^\s+//; # delete beginning space
                                $str =~ s/\s+$//; # delete trailing space
                                $printstr = $str;
                                $findstr = $printstr;
                                $findstr =~ s/\?/\\\?/g;
                                $findstr =~ s/\*/\\\*/g;
                                $str =~ s/\*/\.*/g; # replace wildcard *
                                $str =~ s/\?/\./g; # replace wildcard ?
                                if ($file =~ /$str/io && $found{$file} !~ /$findstr/io) {
                                        $found{$file} .= "$printstr" . ",";
                                }
                        }
                        open(INS,"<$file") || die "Cannot open $file for search.\n";
                        while(<INS>) {
                                chomp;
                                foreach $tempstr (@keyword) {
                                        next if ($tempstr eq "");
                                        $str = $tempstr;
                                        $str =~ s/^\s+//; # delete beginning space
                                        $str =~ s/\s+$//; # delete trailing space
                                        $printstr = $str; # L2?4
                                        $findstr = $printstr;
                                        $findstr =~ s/\?/\\\?/g;
                                        $findstr =~ s/\*/\\\*/g;
                                        $str =~ s/\*/\.*/g; # replace wildcard *
                                        $str =~ s/\?/\./g; # replace wildcard ?
                                        if (/$str/io && $found{$file} !~ /$findstr/io) {
                                                $found{$file} .= "$printstr" . ",";
                                        }
                                }
                        }
                        close(INS);
                        chop($found{$file}) if (defined($found{$file}));
                }
                $ProgressBar->SetPos(0);
                $i = 0;
                foreach $key (sort keys %found) {
                        $i++;
                        $lvwSearchResult->InsertItem(-text => ["$i - $key",$found{$key}]);
                        $searchfile{$i} = $key;
                }
                $lvwSearchResult->View(1);
                $lvwSearchResult->Show();
                Win32::GUI::Show($Window);
                print STDERR "\n\tSearch completed.\n";
                $Status->Text("Search completed");
                undef %found;
                chdir "$curdir";
        }
        elsif ($keyword eq "") {
                $lvwSearchResult->Clear;
                $Status->Text("");
        }
        else {
                $Status->Text("");
                print STDERR "\n\tCannot locate search directory.\n";
                print STDERR "\tPlease check network connection.\n";
                $confirm = MsgBox("TAR - Search Error", "Cannot locate search directory. Please check network connection.", 48);
        }
}

sub LaunchHublean() {
        $list = $_[0];
        $trackORtrace = $_[1];
        $custom = $_[2];
        $own = $_[3];
        $reportoption = $_[4];
        $marssite = $_[5] | $hubleansite;
        $topath = $_[6];
        $hlsite = $marssite;
        ($hlsite,$dummy) = split('_',$hlsite);
        $marssite .= "\.WORLD";
        chop($list);
        #($day,$mon,$mday,$hour,$year) = split(' ',localtime());
        #$curtime = "$mday" . "$mon" . "$year" . "$hour";
        #$curtime =~ s/\://g;
        $forbackward = "FORWARD" if ($rptoption eq "T");
        $forbackward = "BACKWARD" if ($rptoption eq "F");
        $fileindex++;
        $outputfile = $user . "_" . $hlsite . "_" . $trackORtrace . "_" . $forbackward . "_" . &ymd . &hms . "_" . $fileindex . "\.csv";
        $tofile = $topath . "\\" . $outputfile;
        $session = $domain . "_" . $user;
        print STDERR "1 $list\n";
        print STDERR "2 $session\n";
        print STDERR "3 $own $rptoption $trackORtrace $marssite\n";
        print STDERR "Output Filename: $outputfile\n";
        print TARLOG "\t\tRun wltt_sp.bat $list $session $rptoption $trackORtrace $own $outputfile $marssite\n";
        print "wltt_sp.bat $list $session $rptoption $trackORtrace $own $outputfile $marssite";
        system("wltt_sp.bat $list $session $rptoption $trackORtrace $own $outputfile $marssite");
        if (!-z "$curdir\\$outputfile") {
                $Status->Text("Copying $outputfile result to $tofile ...");
                `copy "$curdir\\$outputfile" "$tofile"`;
                if (-e "$tofile") {
                        print STDERR "\tCopied result to $tofile\n";
                        $Status->Text("Copying $outputfile result to $tofile ... Done");
                        unlink "$curdir\\$outputfile";
                }
                else {
                        print STDERR "\tFile not copied.\n";
                        $Status->Text("Copying $outputfile result to $tofile ... Fail");
                }
        }
        else { 
                        print STDERR "\tNo data found from $marssite\n";
                        $Status->Text("No data found from $marssite");
        }
        Win32::GUI::Show($Window); # refresh window
}

sub lvwSearchResult_ItemClick {
        $str = $lvwSearchResult->SelectedItems();
        $index = $str + 1;
        $filename = $searchpath . "\\" . $searchfile{$index};
        if (-e "$searchpath") {        
                my $Excel = Win32::OLE->GetActiveObject('Excel.Application') || Win32::OLE->new('Excel.Application');
                my $Book = $Excel->Workbooks->Open("$filename"); 
                $Excel->{'Visible'} = 1;
        }
        else {
                print STDERR "\tCannot access $searchpath.\n";
                $confirm = MsgBox("TAR - Search Error", "Cannot access $searchpath.", 48);
        }
        chdir "$curdir";
}

sub lvwSearchResult_ColumnClick {
        foreach $key (sort {$a <=> $b} keys %searchfile) {
                print STDERR "$searchfile{$key}\n";
        }
}

sub btnGeneratePHQForm_Click {
        $datetime = localtime;
        open(TARLOG, ">>$curdir\\TAR.log") || die "Cannot open TAR.log\n";
        print TARLOG "$datetime : Generate PHQ Forms\n";
        $Status->Text("Generating PHQ Form For CW And WIP Lots ...");
        if ($phqformpath ne "") {
                my $Excel = Win32::OLE->new('Excel.Application');
                my $MacroBook = $Excel->Workbooks->Open("$phqformpath\\PHQFormMacro.xls");
                if (-e "$tracepath\\DS_cw.csv") {
                        # launch Excel and display list for PHQ form
                        $filename = $tracepath . "\\" . "DS_cw.csv";
                        my $DataBook = $Excel->Workbooks->Open("$filename");
                        my $PHQFormBook = $Excel->Workbooks->Open("$phqformpath\\$phqform");
                        # $Excel->{'Visible'} = 1;
                        $Excel->Run("PHQFormMacro.xls!CW");
                        $PHQFormBook->SaveAs("$tracepath\\PHQ_cw.xls");
                        $PHQFormBook->Close();
                        $DataBook->Close();
                        print TARLOG "\tSuccessfully Generated PHQ Form For CW Lots\n";
                        $Status->Text("Sucessfully Generated PHQ Request Form For CW Lots");
                        print STDERR "\n\tSucessfully Generated PHQ Request Form For CW Lots\n";
                }
                else {
                        print TARLOG "\tNo DS_cw.csv file to generate list\n";
                        print STDERR "\n\tNo DS_cw.csv file to generate list.\n";
                        $Status->Text("Failed To Generate PHQ Request Form For CW Lots");
                }
                if (-e "$tracepath\\DS_wip.csv") {
                        # launch Excel and display list for PHQ form
                        $filename = $tracepath . "\\" . "DS_wip.csv";
                        my $DataBook = $Excel->Workbooks->Open("$filename");
                        my $PHQFormBook = $Excel->Workbooks->Open("$phqformpath\\$phqform");
                        # $Excel->{'Visible'} = 1;
                        $Excel->Run("PHQFormMacro.xls!WIP");
                        $PHQFormBook->SaveAs("$tracepath\\PHQ_wip.xls");
                        $PHQFormBook->Close();
                        $DataBook->Close();
                        print TARLOG "\tSuccessfully Generated PHQ Form For WIP Lots\n";
                        $Status->Text("Sucessfully Generated PHQ Request Form For WIP Lots");
                        print STDERR "\n\tSucessfully Generated PHQ Request Form For WIP Lots\n";
                }
                else {
                        print TARLOG "\tNo DS_wip.csv file to generate list\n";
                        print STDERR "\n\tNo DS_wip.csv file to generate list.\n";
                        $Status->Text("Failed To Generate PHQ Request Form For WIP Lots");
                }
                $MacroBook->Close();
                $Excel->Quit();
        }
        else {
                print TARLOG "\tPHQ path not defined\n";
                print STDERR "\n\tPHQ path not defined.\n";
                $Status->Text("PHQ Form Path Not Defined");
        }
        close(TARLOG);
}

sub btnPrintSummary_Click {
        $datetime = localtime;
        open(TARLOG, ">>$curdir\\TAR.log") || die "Cannot open TAR.log\n";
        print TARLOG "$datetime : Generate Summary Report\n";
        # CrawlForward Qty               MMMatch Qty     Overall Qty
        # $defmiwlot{$loc}{$lot}=0      $miwqty{$lot}   quantity{'miw'}
        # $defwiplot{$loc}{$lot}=qty                    quantity{'wip'}
        # $defxshiplot{$loc}{$lot}=0    $xshipqty{$lot} quantity{'xship'}
        $Status->Text("Creating report ...");
        undef %locqty;
        foreach $loc (sort keys %defwiplot) {
                foreach $lot (sort keys (%{defwiplot->{$loc}})) {
                        $locqty{$loc} += $defwiplot{$loc}{$lot};
                }
        }
#        $locqty{'CW'} = $quantity{'miw'};
#        $locqty{'X-ship'} = $quantity{'xship'};
        
        my $Excel = Win32::OLE->new('Excel.Application');
#        $Excel->{'Visible'} = 0;
        my $SummRpt = $Excel->Workbooks->Add();
        $SummRpt->Worksheets->Add();
        $Sheet1 = $SummRpt->Worksheets(1);
        print STDERR "Creating Summary Worksheet ... ";
        $Sheet1->{Name} = "Summary";
        $Sheet1->Range("A1")->{'Value'} = "Location";
        $Sheet1->Range("B1")->{'Value'} = "Quantity";
        with($Sheet1->Rows(1), HorizontalAlignment => xlCenter);
        with($Sheet1->Cells(1, 1)->Font, Italic => TRUE, Bold => TRUE, ColorIndex => 6);
        with($Sheet1->Cells(1, 1)->Interior, ColorIndex => 5, Pattern => xlSolid);
        with($Sheet1->Cells(1, 2)->Font, Italic => TRUE, Bold => TRUE, ColorIndex => 6);
        with($Sheet1->Cells(1, 2)->Interior, ColorIndex => 5, Pattern => xlSolid);
        with($Sheet1->Columns(1), HorizontalAlignment => xlCenter);
        with($Sheet1->Columns(2), HorizontalAlignment => xlCenter);
        $i = 1;
        foreach $loc (sort keys %locqty) {
                $i++;
                $Sheet1->Range("A$i")->{'Value'} = $loc;
                with($Sheet1->Cells($i, 1)->Font, Italic => TRUE, Bold => TRUE, ColorIndex => 5);
                with($Sheet1->Cells($i, 1)->Interior, ColorIndex => 44, Pattern => xlSolid);
                $Sheet1->Range("B$i")->{'Value'} = $locqty{$loc};
        }
        $i++;
        $startcell = $i;
        $Sheet1->Range("A$i")->{'Value'} = "WIP";
        $Sheet1->Range("B$i")->{'Value'} = $quantity{'wip'};
        $i++;
        $Sheet1->Range("A$i")->{'Value'} = "X-SHIP";
        $Sheet1->Range("B$i")->{'Value'} = $quantity{'xship'};
        $i++;
        $Sheet1->Range("A$i")->{'Value'} = "CW";
        $Sheet1->Range("B$i")->{'Value'} = $quantity{'miw'};
        $i++;
        $Sheet1->Range("A$i")->{'Value'} = "Overall";
        $Sheet1->Range("B$i")->{'Value'} = $quantity{'wip'} + $quantity{'xship'} + $quantity{'miw'};
        $endcell = $i;
        with($Sheet1->Range("A$startcell:B$endcell")->Font, Italic => TRUE, Bold => TRUE, ColorIndex => 6);
        with($Sheet1->Range("A$startcell:B$endcell")->Interior, ColorIndex => 5, Pattern => xlSolid);
        print STDERR "Done\n";
        print STDERR "Creating WIP Worksheet ... ";
        $Sheet2 = $SummRpt->Worksheets(2);
        $Sheet2->{Name} = "WIP";
        $Sheet2->Range("A1")->{'Value'} = "WIP Lot";
        $Sheet2->Range("B1")->{'Value'} = "Operation";
        $Sheet2->Range("C1")->{'Value'} = "Lot Qty";
        $Sheet2->Range("D1")->{'Value'} = "Parent Lot(s)";
        $Sheet2->Range("E1")->{'Value'} = "Total Qty";
        $Sheet2->Range("F1")->{'Value'} = $quantity{'wip'};
        $Sheet2->Range("G1")->{'Value'} = $system;
        $Sheet2->Range("H1")->{'Value'} = $user;
        $Sheet2->Range("I1")->{'Value'} = $speednumber;
        with($Sheet2->Rows(1), HorizontalAlignment => xlCenter);
        with($Sheet2->Range("A1:I1")->Font, Italic => TRUE, Bold => TRUE, ColorIndex => 6);
        with($Sheet2->Range("A1:I1")->Interior, ColorIndex => 5, Pattern => xlSolid);
        $i = 1;
        foreach $loc (sort keys %defwiplot) {
                foreach $clot (sort keys (%{defwiplot->{$loc}})) {
                        $i++;
                        $j = 3;
                        $Sheet2->Range("A$i")->{'Value'} = $clot;
                        $Sheet2->Range("B$i")->{'Value'} = $loc;
                        $Sheet2->Range("C$i")->{'Value'} = $defwiplot{$loc}{$clot};
                        @parent_data = split(',',$defplot{$clot});
                        foreach $parentlot (@parent_data) {
                                $j++;
                                $Sheet2->Cells($i, $j)->{'Value'} = $parentlot;
                        }
                }
        }
        $Sheet2->Range("A:IV")->Columns->AutoFit;
        print STDERR "Done\n";
        print STDERR "Creating X-ship Worksheet ... ";
        $Sheet3 = $SummRpt->Worksheets(3);
        $Sheet3->{Name} = "X-SHIP";
        $Sheet3->Range("A1")->{'Value'} = "X-Ship Lots";
        $Sheet3->Range("B1")->{'Value'} = "Operation";
        $Sheet3->Range("C1")->{'Value'} = "Lot Qty";
        $Sheet3->Range("D1")->{'Value'} = "Parent Lot(s)";
        $Sheet3->Range("E1")->{'Value'} = "Total Qty";
        $Sheet3->Range("F1")->{'Value'} = $quantity{'xship'};
        $Sheet3->Range("G1")->{'Value'} = $system;
        $Sheet3->Range("H1")->{'Value'} = $user;
        $Sheet3->Range("I1")->{'Value'} = $speednumber;
        with($Sheet3->Rows(1), HorizontalAlignment => xlCenter);
        with($Sheet3->Range("A1:I1")->Font, Italic => TRUE, Bold => TRUE, ColorIndex => 6);
        with($Sheet3->Range("A1:I1")->Interior, ColorIndex => 5, Pattern => xlSolid);
        $i = 1;
        foreach $loc (sort keys %defxshiplot) {
                foreach $clot (sort keys (%{defxshiplot->{$loc}})) {
                        $i++;
                        $j = 3;
                        $Sheet3->Range("A$i")->{'Value'} = $clot;
                        $Sheet3->Range("B$i")->{'Value'} = $loc;
                        $Sheet3->Range("C$i")->{'Value'} = $xshipqty{$clot};
                        @parent_data = split(',',$defplot{$clot});
                        foreach $parentlot (@parent_data) {
                                $j++;
                                $Sheet3->Cells($i, $j)->{'Value'} = $parentlot;
                        }
                }
        }
        $Sheet3->Range("A:IV")->Columns->AutoFit;
        print STDERR "Done\n";
        print STDERR "Creating CW Worksheet ... ";
        $Sheet4 = $SummRpt->Worksheets(4);
        $Sheet4->{Name} = "CW";
        $Sheet4->Range("A1")->{'Value'} = "CW Lots";
        $Sheet4->Range("B1")->{'Value'} = "MM#";
        $Sheet4->Range("C1")->{'Value'} = "Lot Qty";
        $Sheet4->Range("D1")->{'Value'} = "Partname";
        $Sheet4->Range("E1")->{'Value'} = "Parent Lot(s)";
        $Sheet4->Range("F1")->{'Value'} = "Total Qty";
        $Sheet4->Range("G1")->{'Value'} = $quantity{'miw'};
        $Sheet4->Range("H1")->{'Value'} = $system;
        $Sheet4->Range("I1")->{'Value'} = $user;
        $Sheet4->Range("J1")->{'Value'} = $speednumber;
        with($Sheet4->Rows(1), HorizontalAlignment => xlCenter);
        with($Sheet4->Range("A1:J1")->Font, Italic => TRUE, Bold => TRUE, ColorIndex => 6);
        with($Sheet4->Range("A1:J1")->Interior, ColorIndex => 5, Pattern => xlSolid);
        $i = 1;
        foreach $loc (sort keys %defmiwlot) {
                foreach $lot (sort keys (%{defmiwlot->{$loc}})) {
                        $i++;
                        $j = 4;
                        $Sheet4->Range("A$i")->{'Value'} = $lot;
                        $Sheet4->Range("B$i")->{'Value'} = $miwmm{$lot};
                        $Sheet4->Range("C$i")->{'Value'} = $miwqty{$lot};
                        $Sheet4->Range("D$i")->{'Value'} = $partname{$lot};
                        @parent_data = split(',',$defplot{$lot});
                        foreach $parentlot (@parent_data) {
                                $j++;
                                if ($j >= 256) {
                                        $Sheet4->Cells($i, 256)->{'Value'} = "Too Many To Print";
                                        next;
                                }
                                else {
                                        $Sheet4->Cells($i, $j)->{'Value'} = $parentlot;
                                }
                        }
                }
        }
        $Sheet4->Range("A:IV")->Columns->AutoFit;
        print STDERR "Done\n";
        $Status->Text("Saving summary report ...");
        $SummRpt->SaveAs("$tracepath\\Summary.xls");
        $SummRpt->Close();
        $Excel->Quit();
        $Status->Text("");
        close(TARLOG);
}

sub checkToolStatus() {
        $datetime = localtime;
        open(TARLOG, ">$curdir\\TAR.log") || die "Cannot open TAR.log\n";
        print TARLOG "Traceability Analysis \& Reporting $thisversion Started : $datetime\n";
        print TARLOG "Domain\\User\=$domain\\$user \($domain\_$user\) on $system\n";
        print TARLOG "CWD\=$curdir\n";
        print TARLOG "Read TAR_WLTTServer.txt\n";

        open(SERVER, "<$curdir\\TAR_WLTTServer.txt") || die "Cannot open TAR_WLTTServer.txt\n";
        while(<SERVER>) {
                chomp;
                my ($wltt,$wlttpath) = split(/\=/);
                print TARLOG "\t$wltt\=$wlttpath\n";
                $server{$wltt} = $wlttpath;
        }
        close(SERVER);
        print TARLOG "\n##### Traceability Analysis & Reporting #####\n";
        close(TARLOG);
}

sub btnDataPath_Click {
        my $applyfilterflag = $_[0];
        $datapath = &GetFolderName($btnDataPath,"Select Folder For Data Transformation","1",$datapath) if (!$applyfilterflag);
        $txtDataPath->Text("$datapath");
        $cmbDataFiles->Reset;
        print STDERR "$datapath\n";
        if ($datapath ne "") {
                chdir "$datapath";
                opendir(DIR, '.') || die "Cann't open Directory\n";
                local(@files) = readdir(DIR);
                closedir(DIR);
                # apply filter
                if ($txtFileFilter->Text eq "") {
                        $filter = "\.";
                }
                else {
                        $filter = $txtFileFilter->Text;
                        $filter =~ s/([\`\~\!\@\#\$\%\^\&\*\(\)\-\_\=\+\[\{\]\}\\\|\;\:\'\"\,\<\.\>\/\?])/\\$1/og;
                }
                $filteredfilecnt = 0;
                undef @filteredfile;
                undef @allfile;
                foreach $file (@files) {
                        if (-f "$file" && $file =~ /$filter/io) {
                                $filteredfilecnt += 1;
                                $cmbDataFiles->InsertItem("$file");
                                @filteredfile = (@filteredfile,$file);
                                @allfile = (@allfile,$file);
                        }
                        elsif (-f "$file") {
                                @allfile = (@allfile,$file);
                        }
                }
                if ($filteredfilecnt) {
                        $radCurrentFile->Enable(1);
                        $radFilteredFile->Enable(1);
                        $radAllFile->Enable(1);
                        &radFilteredFile_Click;
                        $lblConvertFile->Enable(1);
                }
                else {
                        $radCurrentFile->Enable(0);
                        $radFilteredFile->Enable(0);
                        $radAllFile->Enable(0);
                        $radCurrentFile->Checked(0);
                        $radFilteredFile->Checked(0);
                        $radAllFile->Checked(0);
                        $lblConvertFile->Enable(0);
                        $tmpFilteredFile = 0;
                        $tmpCurrentFile = 0;
                        $tmpAllFile = 0;
                }
                $cmbDataFiles->Select($cmbDataFiles->FirstVisibleItem);
                &cmbDataFiles_Change;
                $btnStartConvert->Enable(1);
        }
}

sub btnFileFilter_Click {
        my $applyfilterflag = 1;
        &btnDataPath_Click($applyfilterflag);
}

sub cmbDataFiles_Change {
        undef $xformpath;
        undef $xformfile;
        $txtLineCnt->Text("100");
        $xformpath = $datapath;
        $xformfile = $cmbDataFiles->GetString($cmbDataFiles->SelectedItem);
        if ($xformfile ne "") {
                &btnExampleData_Click;
                $btnExampleData->Enable(1);
        }
        else {
                # $txtDataPath->Text("");
                $btnExampleData->Enable(0);
                $lvwDataContent->Clear();
                for (0..$columncnt - 1) {
                        $lvwDataContent->DeleteColumn(0);
                }
                $columncnt = 0;
                #$btnExampleData->Text("Preview");
        }
}

sub DelimitingData {
        my $delimitername = shift(@_);
        my $delimiter = shift(@_);
        my @thisline = @_;
        undef @newline;
        if ($delimitername =~ /other/ && length($delimiter) != 0) {
                $delimiter =~ s/([\`\~\!\@\#\$\%\^\&\*\(\)\-\_\=\+\[\{\]\}\\\|\;\:\'\"\,\<\.\>\/\?])/\\$1/og;
                for ($i = 0; $i <= $#thisline; $i++) {
                        if ($thisline[$i] eq "" && !$chkEmptyColumn->Checked()) {
                                @newline = (@newline, "$thisline[$i]");
                        }
                        elsif ($thisline[$i] eq "" && $chkEmptyColumn->Checked()) {
                                # do nothing
                        }
                        else {
                                @data = split(/$delimiter/o,$thisline[$i]);
                                for ($j = 0; $j <= $#data; $j++) {
                                        @newline = (@newline, "$data[$j]") if ($data[$j] ne "" || ($data[$j] eq "" && !$chkEmptyColumn->Checked()));
                                }
                        }
                }
                @thisline = @newline;
        }
        elsif ($delimitername =~ /other/ && length($delimiter) == 0) {
                # do nothing
        }
        else {
                for ($i = 0; $i <= $#thisline; $i++) {
                        if ($thisline[$i] eq "" && !$chkEmptyColumn->Checked()) {
                                @newline = (@newline, "$thisline[$i]");
                        }
                        elsif ($thisline[$i] eq "" && $chkEmptyColumn->Checked()) {
                                # do nothing
                        }
                        else {
                                @data = split(/$delimiter/o,$thisline[$i]);
                                #print STDERR "Split by $delimiter : \n";
                                for ($j = 0; $j <= $#data; $j++) {
                                        @newline = (@newline, "$data[$j]") if ($data[$j] ne "" || ($data[$j] eq "" && !$chkEmptyColumn->Checked()));
                                        if ($data[$j] ne "" || ($data[$j] eq "" && !$chkEmptyColumn->Checked())) {
                                                #print STDERR "added to array ";
                                        }
                                        #print STDERR "\t$data[$j]\n";
                                }
                        }
                }
                @thisline = @newline;
                #print STDERR "Printing : ";
                #foreach $item (@thisline) { print STDERR "$item , "; }
                #print STDERR "\n";
        }
        return @thisline;
}

sub ApplyAddCondition {
        undef @retdata;
        undef $displayDec;
        my $myline = shift(@_);
        my @mydata = @_;
        my $startrow = $txtStartRow->Text;
        my $stoprow = $txtStopRow->Text;
        $startrow = 1 if ($startrow !~ /^\d+$/);
        $stoprow = 1000000000 if ($stoprow !~ /^\d+$/);
        if (($myline >= $startrow) && ($myline <= $stoprow)) {
                $displayDec = 1;
                @retdata = @mydata;
        }
        else {
                $displayDec = 0;
                @retdata = "";
        }             
        my $removerowcolempty = $txtRemoveRowColEmpty->Text;
        if ($removerowcolempty ne "") {
                my @tmparray = split(',',$removerowcolempty);
                foreach $tmparrayindex (0 .. $#tmparray) {
                        if ($tmparray[$tmparrayindex] =~ /\d+/ && $retdata[$tmparray[$tmparrayindex] - 1] eq "") {
                                $displayDec = 0;
                                @retdata = "";
                        }
                }
        }
        my $removerowifcolequal = $txtRemoveRowColumnNum->Text;
        my $removerowifcolequaltxt = $txtRemoveRowColumnTxt->Text;
        if (($removerowifcolbutton eq "=" && $removerowifcolequal =~ /\d+/ && $retdata[$removerowifcolequal - 1] eq $removerowifcolequaltxt) ||
            ($removerowifcolbutton eq "<>" && $removerowifcolequal =~ /\d+/ && $retdata[$removerowifcolequal - 1] ne $removerowifcolequaltxt) ||
            ($removerowifcolbutton eq ">" && $removerowifcolequal =~ /\d+/ && $retdata[$removerowifcolequal - 1] > $removerowifcolequaltxt) ||
            ($removerowifcolbutton eq ">=" && $removerowifcolequal =~ /\d+/ && $retdata[$removerowifcolequal - 1] >= $removerowifcolequaltxt) ||
            ($removerowifcolbutton eq "<" && $removerowifcolequal =~ /\d+/ && $retdata[$removerowifcolequal - 1] < $removerowifcolequaltxt) ||
            ($removerowifcolbutton eq "<=" && $removerowifcolequal =~ /\d+/ && $retdata[$removerowifcolequal - 1] <= $removerowifcolequaltxt) ||
            ($removerowifcolbutton eq "c" && $removerowifcolequal =~ /\d+/ && $retdata[$removerowifcolequal - 1] =~ /$removerowifcolequaltxt/io) ||
            ($removerowifcolbutton eq "!c" && $removerowifcolequal =~ /\d+/ && $retdata[$removerowifcolequal - 1] !~ /$removerowifcolequaltxt/io) ||
            ($removerowifcolbutton eq "b" && $removerowifcolequal =~ /\d+/ && $retdata[$removerowifcolequal - 1] =~ /^$removerowifcolequaltxt/io) ||
            ($removerowifcolbutton eq "!b" && $removerowifcolequal =~ /\d+/ && $retdata[$removerowifcolequal - 1] !~ /^$removerowifcolequaltxt/io) ||
            ($removerowifcolbutton eq "e" && $removerowifcolequal =~ /\d+/ && $retdata[$removerowifcolequal - 1] =~ /$removerowifcolequaltxt$/io) ||
            ($removerowifcolbutton eq "!e" && $removerowifcolequal =~ /\d+/ && $retdata[$removerowifcolequal - 1] !~ /$removerowifcolequaltxt$/io)) {
                        $displayDec = 0;
                        @retdata = "";
        }
        my $removerow = $txtRemoveRow->Text;
        if ($removerow ne "") {
                my @tmparray = split(',',$removerow);
                foreach $tmparrayindex (0 .. $#tmparray) {
                        if ($tmparray[$tmparrayindex] =~ /\d+/ && $myline == $tmparray[$tmparrayindex]) {
                                $displayDec = 0;
                                @retdata = "";
                        }
                }
        }
        my $removerowbegin = $txtRemoveRowBegin->Text;
        if ($removerowbegin ne "") {
                my @tmparray = split(',',$removerowbegin);
                foreach $tmparrayindex (0 .. $#tmparray) {
                        $pattern = $tmparray[$tmparrayindex];
                        $pattern =~ s/([\`\~\!\@\#\$\%\^\&\*\(\)\-\_\=\+\[\{\]\}\\\|\;\:\'\"\,\<\.\>\/\?])/\\$1/og;
                        if ($retdata[0] =~ /^$pattern/io) {
                                $displayDec = 0;
                                @retdata = "";
                        }
                }
        }
        my $removerowcontain = $txtRemoveRowContain->Text;
        if ($removerowcontain ne "") {
                my @tmparray = split(',',$removerowcontain);
                foreach $tmparrayindex (0 .. $#tmparray) {
                        $pattern = $tmparray[$tmparrayindex];
                        $pattern =~ s/([\`\~\!\@\#\$\%\^\&\*\(\)\-\_\=\+\[\{\]\}\\\|\;\:\'\"\,\<\.\>\/\?])/\\$1/og;
                        my $tmpstr = join(',',@retdata);
                        if ($tmpstr =~ /$pattern/io) {
                                $displayDec = 0;
                                @retdata = "";
                        }
                }
        }
        my $removerowend = $txtRemoveRowEnd->Text;
        if ($removerowend ne "") {
                my @tmparray = split(',',$removerowend);
                foreach $tmparrayindex (0 .. $#tmparray) {
                        $pattern = $tmparray[$tmparrayindex];
                        $pattern =~ s/([\`\~\!\@\#\$\%\^\&\*\(\)\-\_\=\+\[\{\]\}\\\|\;\:\'\"\,\<\.\>\/\?])/\\$1/og;
                        if ($retdata[$#retdata] =~ /$pattern$/io) {
                                $displayDec = 0;
                                @retdata = "";
                        }
                }
        }
        my $insertrow = $txtInsertRow->Text;
        if ($insertrow ne "") {
                my @tmparray = split(',',$insertrow);
                foreach $tmparrayindex (0 .. $#tmparray) {
                        if ($tmparray[$tmparrayindex] =~ /\d+/ && $myline == $tmparray[$tmparrayindex]) {
                                $displayDec = 2;
                        }
                }
        }
        if ($chkRemoveRowEmpty->Checked()) {
                my $tmpstr = join(/\s/,@retdata);
                if (length($tmpstr) == 0 || $tmpstr =~ /^\s+$/) {
                        $displayDec = 0;
                        @retdata = "";
                }
        }
        if ($myline == 1 && $chkFirstRowHeader->Checked()) {
                $displayDec = 1;
                @retdata = @mydata;
        }
        my $selectcolumn = $txtSelectColumn->Text;
        if ($selectcolumn ne "") {
                undef @newtmp;
                my @tmparray = split(',',$selectcolumn);
                foreach $tmparrayitem (sort {$b <=> $a} @tmparray) {
                        @newtmp = ($retdata[$tmparrayitem - 1],@newtmp) if ($tmparrayitem =~ /\d+/);
                }
                @retdata = @newtmp;
        }
        my $removecolumn = $txtRemoveColumn->Text;
        if ($removecolumn ne "") {
                my @tmparray = split(',',$removecolumn);
                foreach $tmparrayitem (sort {$b <=> $a} @tmparray) {
                        if ($tmparrayitem =~ /\d+/ && exists($retdata[$tmparrayitem - 1])) {
                                #print STDERR "Deleting column $tmparrayitem : $retdata[$tmparrayitem - 1]\n";
                                splice(@retdata,$tmparrayitem - 1,1);
                        }
                }
        }
        my $insertcolumn = $txtInsertColumn->Text;
        if ($insertcolumn ne "") {
                my @tmparray = split(',',$insertcolumn);
                foreach $tmparrayitem (sort {$b <=> $a} @tmparray) {
                        if ($tmparrayitem =~ /\d+/ && exists($retdata[$tmparrayitem - 1])) {
                                #print STDERR "Inserting column $tmparrayitem : $retdata[$tmparrayitem - 1]\n";
                                @tmparray2 = splice(@retdata,0,$tmparrayitem - 1);
                                @retdata = (@tmparray2,"",@retdata);
                        }
                }
        }
        my $swapcolumn = $txtSwapColumn->Text;
        if ($swapcolumn ne "") {
                my @tmparray = split(',',$swapcolumn);
                foreach $swappair (@tmparray) {
                        ($index1,$index2) = split(':',$swappair);
                        if ($index1 =~ /\d+/ && $index2 =~ /\d+/ && $index1 != $index2) {
                                $upperindex = $index1 if ($index1 > $index2);
                                $upperindex = $index2 if ($index2 > $index1);
                                # built up empty array if upperindex > swappable
                                if ($#retdata < $upperindex - 1) {
                                        for($i = $#test + 1; $i <= $x2 - 1; $i++) {
                                                $test[$i] = "";
                                        }
                                }
                                $temp = $retdata[$index1 - 1];
                                $retdata[$index1 - 1] = $retdata[$index2 - 1];
                                $retdata[$index2 - 1] = $temp;
                        }
                }
        }
        if ($chkUniqueRecord->Checked()) {
                my $uniqline = join(',',@retdata);
                if (defined($uniq{$uniqline})) {
                        $displayDec = 0;
                        @retdata = "";
                }
                else {
                        $uniq{$uniqline} = 1;
                }
        }
        return $displayDec,@retdata;
}

sub btnExampleData_Click {
        undef $totalline;
        # empty listview display
        $lvwDataContent->Clear();
        for (0..$columncnt - 1) {
                $lvwDataContent->DeleteColumn(0);
        }
        $columncnt = 0;
        $newlinecnt = $txtLineCnt->Text;
        if (length($newlinecnt) == 0 || $newlinecnt !~ /^\d+$/ || $newlinecnt == 0) {
                $previewlinecnt = 100;
        }
        else {
                $previewlinecnt = $txtLineCnt->Text;
        }
        # $txtDataPath->Text("$xformpath\\$xformfile");
        $Status->Text("Data Transformation - $xformpath\\$xformfile");
        # $filename = $txtDataPath->Text;
        $filename = "$xformpath\\$xformfile";
        if (-f "$filename") {
                undef %uniq;
                open(IN,"<$filename") || die "Cannot read $filename\n";
                $continueread = 1;
                $ProgressBar->SetRange(0,$previewlinecnt);
                $PBcurpos = 0;
                while(($_ = <IN>) && $totalline <= $previewlinecnt && $continueread) {
                        chop;
                        # print STDERR "Line: $.\n";
                        @inprogress = ($_);
                        @inprogress = DelimitingData("comma",'\,',@inprogress) if ($chkDelimiterComma->Checked());
                        @inprogress = DelimitingData("tab",'\t',@inprogress) if ($chkDelimiterTab->Checked());
                        @inprogress = DelimitingData("space",'\s+',@inprogress) if ($chkDelimiterSpace->Checked());
                        @inprogress = DelimitingData("semicolon",'\:',@inprogress) if ($chkDelimiterSemiCol->Checked());
                        @inprogress = DelimitingData("dash",'\-',@inprogress) if ($chkDelimiterDash->Checked());
                        if ($chkDelimiterOther->Checked()) {
                                $txtdelimiter = $txtDelimiterOther->Text;
                                @inprogress = DelimitingData("other","$txtdelimiter",@inprogress);
                        }
                        ($displayflag,@inprogress) = ApplyAddCondition($.,@inprogress);
                        
                        if ($chkFirstRowHeader->Checked() && $. == 1 && $. <= $previewlinecnt) {
                                if ($displayflag) {
                                        $headercnt = @inprogress;
                                        $width = $lvwDataContent->ScaleWidth;
                                        $lvwDataContent->InsertColumn( -index => 0, -width => 65, -text => "Record - 1",);
                                        $columncnt = 1;
                                        for ($i = 0; $i <= $#inprogress; $i++) {
                                                $lvwDataContent->InsertColumn( -index => $i + 1, -width => ($width - 65) / $headercnt, -text => "$inprogress[$i]",);
                                                $lvwDataContent->ColumnWidth($i, -2);
                                                $columncnt += 1;
                                        }
                                        $lvwDataContent->ColumnWidth($i, -2);
                                        $totalline += 1;
                                }
                        }
                        elsif (!($chkFirstRowHeader->Checked()) && $. == 1 && $. <= $previewlinecnt) {
                                if ($displayflag) {
                                        $datacnt = @inprogress;
                                        $width = $lvwDataContent->ScaleWidth;
                                        $lvwDataContent->InsertColumn( -index => 0, -width => 60, -text => "Record",);
                                        $columncnt = 1;
                                        for ($i = 0; $i <= $#inprogress; $i++) {
                                                #$columncnt += 1;
                                                $lvwDataContent->InsertColumn( -index => $i + 1, -width => ($width - 60) / $datacnt, -text => "Column $columncnt",);
                                                $lvwDataContent->ColumnWidth($i, -2);
                                                $columncnt += 1;
                                        }
                                        $lvwDataContent->ColumnWidth($i, -2);
                                        if ($displayflag == 2) {
                                                $totalline += 1;
                                                $lvwDataContent->InsertItem(-text => [$totalline,""]);
                                        }
                                        $totalline += 1;
                                        $lvwDataContent->InsertItem(-text => [$totalline,@inprogress]);
                                }
                        }
                        elsif ($. > 1 && $. <= $previewlinecnt) {
                                if ($displayflag) {
                                        $addcolumncnt = @inprogress;
                                        #print STDERR "New Column Count: $addcolumncnt [element in record after split]\n";
                                        #print STDERR "Comparing $addcolumncnt \> $columncnt\n";
                                        if ($addcolumncnt > ($columncnt - 1)) {
                                                $width = $lvwDataContent->ScaleWidth;
                                                for ($i = $columncnt; $i <= $addcolumncnt; $i++) {
                                                        #print STDERR "Adding column \$i\n";
                                                        $iPlusOne = $i + 1;
                                                        $lvwDataContent->InsertColumn( -index => $i, -width => 60, -text => "Record",) if ($i == 0);
                                                        $lvwDataContent->InsertColumn( -index => $i, -width => $width / $addcolumncnt, -text => "Column $i",) if ($i != 0);
                                                        #$lvwDataContent->ColumnWidth($i, -2);
                                                }
                                                $columncnt = $addcolumncnt + 1;
                                        }
                                        if ($displayflag == 2) {
                                                $totalline += 1;
                                                $lvwDataContent->InsertItem(-text => [$totalline,""]);
                                        }
                                        $totalline += 1;
                                        $lvwDataContent->InsertItem(-text => [$totalline,@inprogress]);
                                }
                        }
                        else {
                                $continueread = 0;
                                #$totalline += 1;
                        }
                        $PBcurpos += 1;
                        $ProgressBar->SetPos($PBcurpos);
                        $Window->Update();
                }
                close(IN);
                $ProgressBar->SetPos(0);
                $txtLineCnt->Text("$totalline");
        }
        else {
                #$btnExampleData->Text("Preview");
        }
        $Window->Update();
        Win32::GUI::Show($lvwDataContent);
}

sub chkDelimiterOther_Click {
        if ($chkDelimiterOther->Checked()) {
                $txtDelimiterOther->Enable(1);
                &btnExampleData_Click if (-f "$filename");
        }
        else {
                $txtDelimiterOther->Enable(0);
                &btnExampleData_Click if (-f "$filename");
        }
}

sub txtDelimiterOther_Change { &btnExampleData_Click if (-f "$filename"); }
sub chkDelimiterComma_Click { &btnExampleData_Click if (-f "$filename"); }
sub chkDelimiterSpace_Click { &btnExampleData_Click if (-f "$filename"); }
sub chkDelimiterTab_Click { &btnExampleData_Click if (-f "$filename"); }
sub chkDelimiterSemiCol_Click { &btnExampleData_Click if (-f "$filename"); }
sub chkDelimiterDash_Click { &btnExampleData_Click if (-f "$filename"); }
sub chkFirstRowHeader_Click { 
        if ($chkFirstRowHeader->Checked()) {
                $lblHeader->Enable(1);
                $radPreserveHeader->Enable(1);
                $radRemoveHeader->Enable(1);
                $tmpPreserveHeader = 1;
        }
        else {
                $lblHeader->Enable(0);
                $radPreserveHeader->Enable(0);
                $radRemoveHeader->Enable(0);
                $tmpPreserveHeader = 0;
                $tmpRemoveHeader = 0;
        }
        &OutputSetup_radButton();
        &btnExampleData_Click if (-f "$filename");
}
sub chkEmptyColumn_Click { &btnExampleData_Click if (-f "$filename"); }

sub txtDataPath_Change {
        $filename = $txtDataPath->Text;
        $filename =~ /(.*)\\(.*)$/;
        $xformpath = $1;
        $xformfile = $2;
        if ($filename ne "") {
                $btnExampleData->Enable(1);
        }
        else {
                $btnExampleData->Enable(0);
        }
}

sub OutputSetup_radButton {
        $radRemoveHeader->Checked(1) if $tmpRemoveHeader;
        $radRemoveHeader->Checked(0) if !$tmpRemoveHeader;
        $radPreserveHeader->Checked(1) if $tmpPreserveHeader;
        $radPreserveHeader->Checked(0) if !$tmpPreserveHeader;
        $radCurrentFile->Checked(1) if $tmpCurrentFile;
        $radCurrentFile->Checked(0) if !$tmpCurrentFile;
        $radFilteredFile->Checked(1) if $tmpFilteredFile;
        $radFilteredFile->Checked(0) if !$tmpFilteredFile;
        $radAllFile->Checked(1) if $tmpAllFile;
        $radAllFile->Checked(0) if !$tmpAllFile;
        $radOutputComma->Checked(1) if $tmpOutputComma;
        $radOutputComma->Checked(0) if !$tmpOutputComma;
        $radOutputTab->Checked(1) if $tmpOutputTab;
        $radOutputTab->Checked(0) if !$tmpOutputTab;
        $radOutputOther->Checked(1) if $tmpOutputOther;
        $radOutputOther->Checked(0) if !$tmpOutputOther;
}

sub radRemoveHeader_Click {
        $tmpRemoveHeader = 1;
        $tmpPreserveHeader = 0;
        &OutputSetup_radButton();
}

sub radPreserveHeader_Click {
        $tmpRemoveHeader = 0;
        $tmpPreserveHeader = 1;
        &OutputSetup_radButton();
}

sub radCurrentFile_Click {
        $tmpCurrentFile = 1;
        $tmpFilteredFile = 0;
        $tmpAllFile = 0;
        &OutputSetup_radButton();
}

sub radFilteredFile_Click {
        $tmpCurrentFile = 0;
        $tmpFilteredFile = 1;
        $tmpAllFile = 0;
        &OutputSetup_radButton();
}

sub radAllFile_Click {
        $tmpCurrentFile = 0;
        $tmpFilteredFile = 0;
        $tmpAllFile = 1;
        &OutputSetup_radButton();
}

sub radOutputComma_Click {
        $tmpOutputComma = 1;
        $tmpOutputTab = 0;
        $tmpOutputOther = 0;
        $txtOutputOther->Enable(0);
        $lblFileExt->Enable(0);
        $txtFileExt->Enable(0);
        &OutputSetup_radButton();
}

sub radOutputTab_Click {
        $tmpOutputComma = 0;
        $tmpOutputTab = 1;
        $tmpOutputOther = 0;
        $txtOutputOther->Enable(0);
        $lblFileExt->Enable(0);
        $txtFileExt->Enable(0);
        &OutputSetup_radButton();
}

sub radOutputOther_Click {
        $tmpOutputComma = 0;
        $tmpOutputTab = 0;
        $tmpOutputOther = 1;
        $txtOutputOther->Enable(1);
        $lblFileExt->Enable(1);
        $txtFileExt->Enable(1);
        &OutputSetup_radButton();
}

sub btnTransformSavePath_Click {
        $xformsavepath = &GetFolderName($btnTransformSavePath,"Transformation Storage","1",$xformsavepath);
        #print STDERR "Transformation Storage Path: $xformsavepath\n";
        $txtTransformSavePath->Text($xformsavepath);
        $Status->Text("Transformation Storage Path - $xformsavepath");
}

sub txtTransformSavePath_Change {
        $xformsavepath = $txtTransformSavePath->Text;
        $Status->Text("Transformation Storage Path - $xformsavepath");
}

sub btnStartConvert_Click {
        undef $stage1;
        undef $stage2;
        undef $stage3;
        # check for storage location
        if (!-e "$xformsavepath" && $xformsavepath ne "") {
                $Status->Text("Creating Storage Path : $xformsavepath");
                `mkdir "$xformsavepath"`;
                $stage1 = 1;
        }
        elsif (-e "$xformsavepath") {
                $Status->Text("Set Storage Path : $xformsavepath");
                $stage1 = 1;
        }
        else {
                $stage1 = 0;
                $confirm = MsgBox("TAR - Data Transformation", "Storage path not defined.", 48);
        }
                
        @filenames = ($xformfile) if ($tmpCurrentFile);
        @filenames = @filteredfile if ($tmpFilteredFile);
        @filenames = @allfile if ($tmpAllFile);
        $filecnt = @filenames;
        if (@filenames) {
                $stage2 = 1;
        }
        else {
                $stage2 = 0;
                $confirm = MsgBox("TAR - Data Transformation", "No file to transform.", 48);
        }
        
        if ($tmpOutputComma) {
                $fileext = "\.csv";
                $outputdelimiter = ",";
                $stage3 = 1;
        }
        if ($tmpOutputTab) {
                $fileext = "\.txt";
                $outputdelimiter = "\t";
                $stage3 = 1;
        }
        if ($tmpOutputOther) {
                if ($txtFileExt->Text =~ /^[\.\s\W]+$/ || $txtFileExt->Text eq "") {
                        $fileext = "";
                }
                elsif ($txtFileExt->Text =~ /^\./) {
                        $fileext = $txtFileExt->Text;
                }
                else {
                        $fileext = "\." . $txtFileExt->Text;
                }
                $outputdelimiter = $txtOutputOther->Text;
                #$outputdelimiter =~ s/([\`\~\!\@\#\$\%\^\&\*\(\)\-\_\=\+\[\{\]\}\\\|\;\:\'\"\,\<\.\>\/\?])/\\$1/og;
                $stage3 = 1;
        }
        if (!$stage3) {
                $confirm = MsgBox("TAR - Data Transformation", "Delimiter undefine.", 48);
        }
        if ($stage1 && $stage2 && $stage3) {
                $ProgressBar->SetRange(0,$filecnt);
                $PBcurpos = 0;
                my $outputfileopen = 0;
                my $printedheader = 0;
                foreach $file (@filenames) {
                        print STDERR "$datapath\\$file\n";
                        $Status->Text("Transforming - $datapath\\$file");
                        # Creating output file
                        $file =~ /^(.*)\.(.*)$/;
                        $convertedfile = $1 . "_conv" . $fileext;
                        print STDERR "Converted : $xformsavepath\\$convertedfile\n";
                        # output delimiter $outputdelimiter
                        undef $c_totalline;
                        if (-f "$datapath\\$file") {
                                undef %uniq;
                                if ($outputfileopen != 1 && $chkCombineOutput->Checked()) {
                                        open(OUT,">$xformsavepath\\$convertedfile") || die "Cannot open $xformsavepath\\$convertedfile\n";
                                        $outputfileopen = 1;
                                }
                                elsif (!$chkCombineOutput->Checked()) {
                                        open(OUT,">$xformsavepath\\$convertedfile") || die "Cannot open $xformsavepath\\$convertedfile\n";
                                }
                                open(IN,"<$datapath\\$file") || die "Cannot read $datapath\\$file\n";
                                while(<IN>) {
                                        chop;
                                        @inprogress = ($_);
                                        @inprogress = DelimitingData("comma",'\,',@inprogress) if ($chkDelimiterComma->Checked());
                                        @inprogress = DelimitingData("tab",'\t',@inprogress) if ($chkDelimiterTab->Checked());
                                        @inprogress = DelimitingData("space",'\s+',@inprogress) if ($chkDelimiterSpace->Checked());
                                        @inprogress = DelimitingData("semicolon",'\:',@inprogress) if ($chkDelimiterSemiCol->Checked());
                                        @inprogress = DelimitingData("dash",'\-',@inprogress) if ($chkDelimiterDash->Checked());
                                        if ($chkDelimiterOther->Checked()) {
                                                $txtdelimiter = $txtDelimiterOther->Text;
                                                @inprogress = DelimitingData("other","$txtdelimiter",@inprogress);
                                        }
                                        ($displayflag,@inprogress) = ApplyAddCondition($.,@inprogress);
                                        if (($chkFirstRowHeader->Checked() && $tmpPreserveHeader == 1 && $. == 1 && $printedheader != 1 && $chkCombineOutput->Checked()) || (!$chkFirstRowHeader->Checked() && $. == 1)) {
                                                if ($displayflag) {
                                                        $outputstr = join($outputdelimiter,@inprogress);
                                                        print OUT "$outputstr\n";
                                                        $c_totalline += 1;
                                                        $printedheader = 1;
                                                }
                                        }
                                        elsif (($chkFirstRowHeader->Checked() && $tmpPreserveHeader == 1 && $. == 1 && !$chkCombineOutput->Checked()) || (!$chkFirstRowHeader->Checked() && $. == 1)) {
                                                if ($displayflag) {
                                                        $outputstr = join($outputdelimiter,@inprogress);
                                                        print OUT "$outputstr\n";
                                                        $c_totalline += 1;
                                                }
                                        }
                                        elsif ($. != 1) {
                                                if ($displayflag) {
                                                        if ($displayflag == 2) {
                                                                print OUT "\n";
                                                                $c_totalline += 1;
                                                        }
                                                        $outputstr = join($outputdelimiter,@inprogress);
                                                        print OUT "$outputstr\n";
                                                        $c_totalline += 1;
                                                }
                                        }
                                }
                                close(IN);
                                close(OUT) if (!$chkCombineOutput->Checked());
                        }
                        $PBcurpos += 1;
                        $ProgressBar->SetPos($PBcurpos);
                }
                close(OUT) if ($chkCombineOutput->Checked());
                $ProgressBar->SetPos(0);
        }
        $Status->Text("");
}

sub btnRemoveRowColumnEqual_Click {
        if ($removerowifcolbutton eq "=") { $btnRemoveRowColumnEqual->Text("<>"); }
        elsif ($removerowifcolbutton eq "<>") { $btnRemoveRowColumnEqual->Text(">"); }
        elsif ($removerowifcolbutton eq ">") { $btnRemoveRowColumnEqual->Text(">="); }
        elsif ($removerowifcolbutton eq ">=") { $btnRemoveRowColumnEqual->Text("<"); }
        elsif ($removerowifcolbutton eq "<") { $btnRemoveRowColumnEqual->Text("<="); }
        elsif ($removerowifcolbutton eq "<=") { $btnRemoveRowColumnEqual->Text("b"); }
        elsif ($removerowifcolbutton eq "b") { $btnRemoveRowColumnEqual->Text("!b"); }
        elsif ($removerowifcolbutton eq "!b") { $btnRemoveRowColumnEqual->Text("e"); }
        elsif ($removerowifcolbutton eq "e") { $btnRemoveRowColumnEqual->Text("!e"); }
        elsif ($removerowifcolbutton eq "!e") { $btnRemoveRowColumnEqual->Text("c"); }
        elsif ($removerowifcolbutton eq "c") { $btnRemoveRowColumnEqual->Text("!c"); }
        elsif ($removerowifcolbutton eq "!c") { $btnRemoveRowColumnEqual->Text("="); }
        $removerowifcolbutton = $btnRemoveRowColumnEqual->Text;
}

sub txtSelectColumn_Change {
        if ($txtSelectColumn->Text ne "") {
                $txtRemoveColumn->Text("");
                $txtRemoveColumn->Enable(0);
        }
        else {
                $txtRemoveColumn->Enable(1);
        }
}

sub txtRemoveColumn_Change {
        if ($txtRemoveColumn->Text ne "") {
                $txtSelectColumn->Text("");
                $txtSelectColumn->Enable(0);
        }
        else {
                $txtSelectColumn->Enable(1);
        }
}

sub ymd {
        my %month = (
                Jan => '01',
                Feb => '02',
                Mar => '03',
                Apr => '04',
                May => '05',
                Jun => '06',
                Jul => '07',
                Aug => '08',
                Sep => '09',
                Oct => '10',
                Nov => '11',
                Dec => '12',
        );
        my ($weekday,$mon,$mday,$hms,$year) = split(' ',localtime());
        if (length($mday) == 1) {
                $mday = '0' . $mday;
        }
        my $r_ymd = $year . $month{$mon} . $mday;
        #return ($year,$month{$mon},$mday) if wantarray;
        return $r_ymd;
}

# hms returns array of (hh,mm,ss) or string of hhmmss
sub hms {
        my ($weekday,$mon,$mday,$time,$year) = split(' ',localtime());
        my ($hour,$minute,$second) = split(/\:/,$time);
        my $r_hms = $hour . $minute . $second;
        #return ($hour,$minute,$second) if wantarray;
        return $r_hms;
}

sub Tab_Click {
        my @mainctrl = ($grpHubleanSetup,$lblHubleanSite,$cmbSite,$lblHubleanReport,$cmbRptOption,
                        $cmbReport,$lblLotOwner,$cmbLotOwner,$lblMaxLot,$cmbMaxLot,
                        $grpPathSetup,$btnPHQFormPath,$txtPHQFormPath,
                        $btnCentralPath,$txtCentralPath,$btnTracePath,$txtTracePath,
                        $btnSaveSetup,$btnLoadSetup,$chkWIPTracking,$chkExtractCB,
                        $txtCBOperation,$grpTools,$btnTraceHublean,$lblTraceHublean,$btnDirtyLot,
                        $btnCrawlForward,$lblCrawlForward,$btnSaveCrawlForward,$lblSaveCrawlForward,$btnTrackHublean,
                        $lblTrackHublean,$btnMatchMM,$lblMatchMM,$btnSaveDatasheet,$lblSaveDatasheet,
                        $txtSpeedNumber,$btnPrintSummary,$btnClearArray,$btnGeneratePHQForm,$grpDPMAssess,
                        $btnDPMAssess,$txtDPMAssessPath,$btnDPMAssessPath,$grpSearch,$btnSearchPath,
                        $txtSearchPath,$lblSearchStr,$txtSearchStr,$btnImportSearch,$btnSearch,
                        $lvwSearchResult,$lblRptDesc,$lblAffectedList,$btnAffectedList);
        my @dataxformctrl = ($btnDataPath,$txtDataPath,$cmbDataFiles,$lvwDataContent,$btnExampleData,
                             $lblDelimiter,$chkDelimiterSpace,$chkDelimiterComma,$chkDelimiterSemiCol,$chkDelimiterTab,
                             $chkDelimiterDash,$chkDelimiterOther,$txtDelimiterOther,$chkFirstRowHeader,$chkEmptyColumn,
                             $grpConditions,$txtLineCnt,$lblLineCnt,$btnFileFilter,$txtFileFilter,
                             $txtRemoveColumn,$lblRemoveRow,$txtRemoveRow,$grpTransform,$txtSelectColumn,
                             $lblSelectColumn,$lblStartRow,$txtStartRow,$txtStopRow,$btnTransformSavePath,
                             $txtTransformSavePath,$txtInsertRow,$lblInsertRowCol,$txtInsertColumn,$lblSwapColumn,$txtSwapColumn,
                             $lblRemoveRowBegin,$txtRemoveRowBegin,$lblRemoveRowContain,$txtRemoveRowContain,$lblRemoveRowEnd,
                             $txtRemoveRowEnd,$chkRemoveRowEmpty,$lblHeader,$radPreserveHeader,$chkUniqueRecord,
                             $radRemoveHeader,$lblConvertFile,$radCurrentFile,$radFilteredFile,$radAllFile,
                             $lblOutputDelimiter,$radOutputComma,$radOutputTab,$radOutputOther,$txtOutputOther,
                             $btnStartConvert,$lblFileExt,$txtFileExt,$txtRemoveRowColEmpty,$lblRemoveRowColEmpty,
                             $lblRemoveRowIfColumn,$txtRemoveRowColumnNum,$btnRemoveRowColumnEqual,$txtRemoveRowColumnTxt,$chkCombineOutput);
        if ($Window->Tab->SelectedItem() == 0) {
                foreach $control (@mainctrl) {
                        Win32::GUI::Show($control);
                }
                foreach $control (@dataxformctrl) {
                        Win32::GUI::Hide($control);
                }
                $Status->Text("Traceability \& Risk Assessment");
        }
        elsif ($Window->Tab->SelectedItem() == 1) {
                foreach $control (@mainctrl) {
                        Win32::GUI::Hide($control);
                }
                foreach $control (@dataxformctrl) {
                        Win32::GUI::Show($control);
                }
                $Status->Text("Data Transformation");
        }
}

