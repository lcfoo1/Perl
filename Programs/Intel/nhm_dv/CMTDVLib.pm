package CMTDVLib;
##
##  Author: Stephan Rotter  mailto:stephan.rotter@intel.com
##      CMTDVLib Perl Module - a perl interface for the CMT tester
##         A collection of utility functions that enable dynamic test program configuration
##         for quick data collection.
##
##      Any changes,additions, or bug fixes, please inform author.  Thanks!
##
##################################################################################################

use strict;
use Win32::OLE::Variant;
use Win32::Process;
use File::Path;
use File::Copy;
use File::Stat;
use Sys::Hostname;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use vars qw($oSysC $oTPS $oTPL $oFLW $oSBC);
use vars qw($processObj);
use Win32::OLE::Const ("STDProxy");
my $dvlib_function = "";
Win32::OLE->Option(Warn => 
	sub { 
		my $error = Win32::OLE->LastError;
		$error =~ s/\n//g; $error =~ s/  / /g;
		print "-E- CMTDVLib ERROR: $dvlib_function : $error\n"; 
	}
	);


require Exporter;

@ISA = qw(Exporter AutoLoader);
@EXPORT = qw(
	     $oSysC $oTPS $oTPL $oFLW $oSBC
	     convBase conv_ms conv_us conv_ns conv_ps
	     initCMT
	     executeTest createTest deleteTest  verifyTest
	     executeTestInstance clearExecMode suspendExecMode createTestInstance deleteTestInstance
	     executeFlowItem executeMainFlowItem executecontinueFlowItem executecontinueMainFlowItem executeInitFlow
	     returnTestparam setTestparam getTestparams
	     setLevels setLevelBlockValue getLevelBlockValue setLevelValue getLevelValue 
	     setTimings setTimingBlockValue getTimingBlockValue setTimingValue getTimingValue
	     setPatlist burstPatlist skipPattern getPatternTree printPatternTree removePattern insertPattern
	     countPatterns getPatternnames getPatternListnames loadPatlist getPreamble setPreamble getPostamble setPostamble
	     createFlowItem deleteFlowItem removeConnection addReturnPort removeReturnPort connectFlowItems
             setUserVar getUserVar createUserVar
             getSignalsbyType
             startLog stopLog print2Console print2Ituff printData
	     maskPins maskPinsbyTestinstance maskPinsbyPatlist
);



$VERSION = '0.32';

my $debug  = 0;
my $initialized = 0;
my $starttime   = time;
my $state  = Variant( VT_I2 | VT_BYREF, 0 );
my $status = Variant( VT_I2 | VT_BYREF, 0 );

## Datalogging Globals Initialization
my $logPath = "";
my $logOption = "";
my $prefix = "Unknown";

## Utility Function
######################################################################
sub convBase { # value
  my $value = shift;
  if ($value =~ /mv|ms|m/i) { $value =~ s/[mv|ms|m]//gi; $value = $value*10**-3;  }
  if ($value =~ /uv|us|u/i) { $value =~ s/[uv|us|u]//gi; $value = $value*10**-6;  }
  if ($value =~ /nv|ns|n/i) { $value =~ s/[nv|ns|n]//gi; $value = $value*10**-9;  }
  if ($value =~ /pv|ps|p/i) { $value =~ s/[pv|ps|p]//gi; $value = $value*10**-12; }
  if ($value =~ /v|s/i)     { $value =~ s/[v|s]//gi;     $value = $value;         }
  return ($value);
}
sub conv_ms { # value
  my $value = shift;
  $value = $value*10**3; $value .= "mS";
  return($value);
}
sub conv_us { # value
  my $value = shift;
  $value = $value*10**6; $value .= "uS";
  return($value);
}
sub conv_ns { # value
  my $value = shift;
  $value = $value*10**9; $value .= "nS";
  return($value);
}
sub conv_ps { # value
  my $value = shift;
  $value = $value*10**12; $value .= "pS";
  return($value);
}

## Setup Tester
######################################################################
sub initCMT { # site
  my $site = shift;
 $dvlib_function = "CMTDVLib initCMT(site:$site)";

  ## Connect Tester
  $oSysC = Win32::OLE->new("OASIS.STDProxy.SystemControllerProxy") || die "Cannot start OASIS Service";
  $oSysC->initialize('localhost');
  if ( $oSysC->isInitialized() == 0 ) {
    $oSysC->initializeSysC();
  }	
  if ($oSysC==0) { return(0); }

  foreach my $enabled_site ( @{ $oSysC->getEnabledSiteCs() } ) {
    #push @oTPSs, $oSysC->getTPS($enabled_site); 
  }

  ## Parallel or Single Site
  if ($site =~ /\d/) {
    $oTPS = $oSysC->getTPS($site); 
  } else {
    print "-w- Not validated: Parallel Test\n";
    $oTPS = $oSysC->getParallelTPS();
  }
  $oTPL = $oTPS->getTestPlan();
  if ($oSysC->isTestPlanModular()) {
    print "-W- Modular Test Program detected - CMTDVLib not validated with modular TP\n";
    ##$oSysC->getTestPlanName();
  }
    
  $oFLW = $oTPL->getMainFlow(); #getFlow("FlowMain");

  ## Setup sbcmd interface
  $oTPS->loadHelperDLL("OAI_SearchHelperClass.dll");
  $oTPS->loadHelperDLL("AT_ScriptBasedCommand.dll"); 
  $oSBC = $oTPS->getHelperClass ("SbcmdClass");
  clearExecMode();
  if ($debug) { 
    $oSBC->execute("outconsole on"); 
  } else {
    $oSBC->execute("outconsole off"); 
  }
  $oSBC->execute("outscript");
  $initialized=1;
  return(1);
}

## UserSDK OASIS Direct Functions
######################################################################
sub createTest { # test_type testname parameter_array
  my ($testtype,$testname, @params) = @_;
  createTestInstance($testtype,$testname, @params);
  createFlowItem($testname,$testname."_eos");
}

sub executeTest { #test_instance
  my $testname = shift;
  return(executeMainFlowItem($testname."_eos"));
}

sub deleteTest { # test_instance
  my ($testname) = shift;
  deleteFlowItem($testname."_eos");
  deleteTestInstance($testname);
}

sub executeMainFlowItem { # flowitem
  my $flowitem = shift;
  $dvlib_function = "CMTDVLib executeMainFlowItem(flowitem:$flowitem)";

  my $result = executeFlowItem("FlowMain",$flowitem);
  return ($result);
}
sub executeFlowItem { # flow flowitem
  my $flowname = shift;
  my $flowitem = shift;
  my $oFlow;
 $dvlib_function = "CMTDVLib executeFlowItem(flowname:$flowname,flowitem:$flowitem)";

  if ($flowname eq "FlowMain") {
    $oFlow   = $oTPL->getMainFlow();
  } else {
    $oFlow   = $oTPL->getFlow($flowname);
  }
  my $oFlowitem = $oFlow->getFlowItem ($flowitem);
  if ($debug) { print "-i- Execute $flowname / $flowitem\n"; }
  $oTPS->executeFlowItem($oFlowitem);

  do {     #Wait while not ready
    $oTPS->getState( $state, $status );
  } while  ( $state != Proxy_SYS_STATE_READY );

  #print $oFlow->interpretStatus();
  my $result = $oFlowitem->getResult();
  return ($result);
}
sub executecontinueMainFlowItem { # flowitem
  my $flowitem = shift;
 $dvlib_function = "CMTDVLib executecontinueMainFlowItem(flowitem:$flowitem)";

  my $result = executecontinueFlowItem("FlowMain",$flowitem);
  return ($result);
}
sub executecontinueFlowItem { # flow flowitem
  my $flowname = shift;
  my $flowitem = shift;
  my $oFlow="";
 $dvlib_function = "CMTDVLib executecontinueFlowItem(flowname:$flowname,flowitem:$flowitem)";

  if ($flowname eq "FlowMain") {
    $oFlow   = $oTPL->getMainFlow();
  } else {
    $oFlow   = $oTPL->getFlow($flowname);
  }
  my $oFlowitem = $oFlow->getFlowItem ($flowitem);
  if ($debug) { print "-i- Execute & Continue $flowname / $flowitem\n"; }
  $oTPS->executeFlowFromFlowItem($oFlow,$oFlowitem);

  do {     #Wait while not ready
    $oTPS->getState( $state, $status );
  } while  ( $state != Proxy_SYS_STATE_READY );

  #print $oFlow->interpretStatus();
  my $result = $oFlowitem->getResult();
  return ($result);
}

sub executeInitFlow {
  $dvlib_function = "CMTDVLib executeInitFlow()";

  $oTPS->executeFlow( $oTPL->getInitFlow() );
  do {     #Wait while not ready
    $oTPS->getState( $state, $status );
  } while  ( $state != Proxy_SYS_STATE_READY );
  print "-i- FlowInit returned: ".$oTPL->getInitFlow()->interpretStatus()."\n";
  return($oTPL->getInitFlow()->interpretStatus());
}

sub clearExecMode { # 
  $dvlib_function = "CMTDVLib clearExecMode()";

  if ($debug) { print "-i- Clear Execution\n"; }
  my $oExCtrl       = $oTPL->getExeControl();
  my $oExCtrlBuffer = $oExCtrl->createExeControlBuffer();
  $oExCtrlBuffer->setAllFlagsEnable(0);
  $oExCtrl->setExecuteControl ($oExCtrlBuffer);

  $oTPS->getState($state, $status);	
  if ($state == Proxy_SYS_STATE_TESTING) { $oTPS->retest(); }
  while ( $state != Proxy_SYS_STATE_READY ) {
    $oTPS->getState($state, $status);
  } 
}
sub suspendExecMode { # test_instance
# Set Suspend 'ON' AND Execute Test
  my $testname = shift;
  $dvlib_function = "CMTDVLib suspendExecMode(testname:$testname)";

  clearExecMode();
  if ($debug) { print "-i- Suspend Execution $testname\n"; }

  my $oTest = $oTPL->getTest ($testname);
  my $oExCtrl       = $oTPL->getExeControl();
  my $oExCtrlBuffer = $oExCtrl->createExeControlBuffer();
  $oExCtrlBuffer->setMode(1);
  $oExCtrlBuffer->setEnable(-1);
  $oExCtrl->setFlagEnable($testname,-1);
  $oExCtrl->setExecuteControl ($oExCtrlBuffer);

  $oTPS->executeTest($oTest);
  do {
    $oTPS->getState($state, $status);
  } while ( $state != Proxy_SYS_STATE_TESTING || $status !=Proxy_SYS_STATUS_SUSPENDED);
}


sub executeTestInstance { # test instance
  my $testname = shift;
 $dvlib_function = "CMTDVLib executeTest(testname:$testname)";

  my $oTest = $oTPL->getTest ($testname);
  if ($debug) { print "-i- Execute $testname\n"; }

  ## use retest() for suspend
  $oTPS->executeTest($oTest);
  do {     #Wait while not ready
    $oTPS->getState( $state, $status );
  } while  ( $state != Proxy_SYS_STATE_READY );   
  my $result = $oTPL->getTest($testname)->getPassFailStatus();
  return ($result);
}

sub createTestInstance { # test_type testname parameter_array
  my ($testtype,$testname, @params) = @_;
  $dvlib_function = "CMTDVLib createTestInstance(template:$testtype,testname:$testname, ParamArray:".join(" ",@params).")";

  foreach my $test ( @ { $oTPL->getTestNames()}) {
    if ($test eq $testname) { 
      print "-w- $test already exists - over-writing\n";  deleteTestInstance($testname);
    }
  }
  my $dll = $testtype.".dll";  #loads the DLL just in case 
  $oTPL->createTestInstanceEx($testtype,$testname,0,"new_DV_test",\@params,$dll);
}

sub deleteTestInstance { # test_instance
  my ($testname) = shift;
  $dvlib_function = "CMTDVLib deleteTest(testname:$testname)";

  foreach my $test ( @ { $oTPL->getTestNames()}) {
    if ($test eq $testname) { 
      $oTPL->deleteTest($testname);
    }
  }
}

sub verifyTest { # test_instance
  my ($testname) = shift;
  $dvlib_function = "CMTDVLib verifyTest(testname:$testname)";

  $oTPL->getTest($testname)->postInit();
}

sub returnTestparam { # test_instance array|hash
  my $testname = shift;
  my $return_type = shift;
  $dvlib_function = "CMTDVLib returnTestparam(testname:$testname,array\|hash:$return_type)";

  if ($return_type =~ /^h|hash/i) {
    my %oTestparams = split(/[=|]/,$oTPL->getTest($testname)->getValues());
    return (%oTestparams);
  } else {
    my @oTestparams = @{$oTPL->getTestValues($testname)};
    return (@oTestparams);
  }
}

sub setTestparam { # test_instance parameter value
  my ($testname,$newparam,$value) = @_;
  $dvlib_function = "CMTDVLib setTestparam(testname:$testname,param:$newparam,value:$value)";

  my @Testparams = @{$oTPL->getTestValues($testname)};
  my $newtestparams="";
  
  foreach my $param (@Testparams) {  
    if ($param =~ /$newparam\=/) { $param = $newparam."=".$value; }
    $newtestparams .= "$param\|";
  }
  $newtestparams =~ s/\|$//g;
  $oTPL->getTest($testname)->setValues($newtestparams);
}

sub getTestparams { # test_instance parameter
  my ($testname,$param) = @_;
  $dvlib_function = "CMTDVLib getTestparams(testname:$testname,param:$param)";

  my %Testparams = split(/[=|]/,$oTPL->getTest($testname)->getValues());
  return($Testparams{$param});
}

sub setLevels { # test_instance level_parameter_name
  my ($testname,$value) = @_;
  $dvlib_function = "CMTDVLib setLevels(testname:$testname,levelblock:$value)";

  setTestparam($testname,"level",$value);
}

sub setTimings { # test_instance timing_parameter_name
  my ($testname,$value) = @_;
  $dvlib_function = "CMTDVLib setTimings(testname:$testname,timingblock:$value)";

  setTestparam($testname,"timings",$value);
}

sub setPatlist { # test_instance patlist_parameter_name
  my ($testname,$value) = @_;
  $dvlib_function = "CMTDVLib setPatlist(testname:$testname,plist:$value)";

  setTestparam($testname,"patlist",$value);
}

sub setLevelValue { # test_instance spec_set_name value
    my ($testname, $param,$value) = @_; 
   $dvlib_function = "CMTDVLib setLevelValue(testname:$testname,param:$param,specname:$value)";

    my %Testparams = split(/[=|]/,$oTPL->getTest($testname)->getValues());
    setLevelBlockValue($Testparams{"level"},$param,$value);
}
sub setLevelBlockValue { # levels_block spec_set_name value
    my ($levelblockname, $param,$value) = @_; 
   $dvlib_function = "CMTDVLib setLevelBlockValue(levelblock:$levelblockname,param:$param,specname:$value)";

    my $condition  = $oTPL->getTestCondition($levelblockname);
    my $selectorID = $condition->getSelectorID();
    my $specSet    = $condition->getTestConditionGroup()->getSpecificationSet();
    my $varType    = $specSet->getVarDataType($param); #am_i double,int,time,freq
    $specSet->setExpression($param,$selectorID,$varType,$value);
    $specSet->evaluateAll;
    $condition->apply();
    $condition->select();
}
sub getLevelValue { # test_instance spec_set_name
    my ($testname, $param) = @_;  
   $dvlib_function = "CMTDVLib getLevelValue(testname:$testname,specname:$param)";

    my $value;
    my %Testparams = split(/[=|]/,$oTPL->getTest($testname)->getValues());
    $value         = getLevelBlockValue($Testparams{"level"},$param);
    return $value;
}        
sub getLevelBlockValue { # levels_block spec_set_name value
    my ($levelblockname, $param) = @_;  
   $dvlib_function = "CMTDVLib getLevelBlockValue(levelblock:$levelblockname,specname:$param)";

    my $value;
    my $condition  = $oTPL->getTestCondition($levelblockname);
    my $selectorID = $condition->getSelectorID(); 
    my $specSet    = $condition->getTestConditionGroup()->getSpecificationSet();
    $value         = $specSet->getExpressionString($param,$selectorID);
    return $value;
}

sub setTimingValue { # test_instance spec_set_name value
    my ($testname, $param,$value) = @_; 
   $dvlib_function = "CMTDVLib setTimingValue(testname:$testname,specname:$param,value:$value)";

    my %Testparams = split(/[=|]/,$oTPL->getTest($testname)->getValues());
    setTimingBlockValue($Testparams{"timings"},$param,$value);
}
sub setTimingBlockValue { # timing_block spec_set_name value
    my ($timingblockname, $param,$value) = @_; 
   $dvlib_function = "CMTDVLib setTimingBlockValue(timingblock:$timingblockname,specname:$param,value:$value)";

    my $condition  = $oTPL->getTestCondition($timingblockname);
    my $selectorID = $condition->getSelectorID();
    my $specSet    = $condition->getTestConditionGroup()->getSpecificationSet();
    my $varType    = $specSet->getVarDataType($param); #am_i double,int,time,freq
    $specSet->setExpression($param,$selectorID,$varType,$value);
    $specSet->evaluateAll;
    $condition->apply();
    $condition->select();
}
sub getTimingValue { # test_instance value
    my ($testname,$param) = @_;  
   $dvlib_function = "CMTDVLib getTimingValue(testname:$testname,specname:$param)";

    my $value;
    my %Testparams = split(/[=|]/,$oTPL->getTest($testname)->getValues());
    $value         = getTimingBlockValue($Testparams{"timings"},$param);
    return $value;
}        
sub getTimingBlockValue { # timing_block spec_set_name
    my ($timingblockname,$param) = @_;  
   $dvlib_function = "CMTDVLib getTimingBlockValue(timingblockname:$timingblockname,specname:$param)";

    my $value;
    my $condition  = $oTPL->getTestCondition($timingblockname);
    my $selectorID = $condition->getSelectorID(); 
    my $specSet    = $condition->getTestConditionGroup()->getSpecificationSet();
    $value         = $specSet->getExpressionString($param,$selectorID);
    return $value;
}        

sub burstPatlist { # pattern_list 0|1=burst
  my ($plist,$mode) = @_;
  $dvlib_function = "CMTDVLib burstPatlits(plist:$plist,mode:$mode)";

  my $oPtreemgr  = $oTPS->getPatternTreeMgr();
  my $oPtree     = $oPtreemgr->getPatternTree($plist);
  my $oPnode     = $oPtree->getRootPatternList();

  print "-i- Patlist $plist - set burst = $mode (0=burston; 1=burstoff)\n";
  $oPnode->setBurstOffDeep($mode);
  $oPnode->setBurstOff($mode);
  $oPtreemgr->reloadModifiedPatternTrees();
}

sub skipPattern { # pattern_list pattern 0|1=skip
  my ($pattern,$mode) = @_;
  $dvlib_function = "CMTDVLib skipPattern(pattern:$pattern,mode:$mode)";

  my @plbs = getPatternListnames();

  my $oPtreemgr  = $oTPS->getPatternTreeMgr();
  foreach my $plb (@plbs) {
    my $oPtree     = $oPtreemgr->getPatternTree($plb);
    my $oPnode     = $oPtree->getRootPatternList();

    for (my $i=0;$i<$oPnode->getChildCount();$i++) { 
  	my $oPn= $oPnode->getChildAt($i);
	my $child = $oPn->getName();
	$child =~  s[^.+:][];  #if referencing a plist from a plist
	if (($child =~ /$pattern/i)||($pattern eq "all")) {
	  if ($debug) { print "-i-  set skipped=$mode : ".$child."\n"; }
	  $oPn->setSkipped($mode);
	  if ($debug) { print "-d- $child skip = ".$oPn->getSkipped()."\n"; }
        }
    }
  }
  $oPtreemgr->reloadModifiedPatternTrees();
}

sub getPatternTree {  # mode=flat|nested|skipflat|skipnested
  my $mode = shift;
  my ($plb,$pat);
  my %patterntree;
  my %type;
  $dvlib_function = "CMTDVLib getPatternTree(mode=flat\|nested:$mode)";

  if (!($mode =~ /flat|nest/i)) { print "-e- Unknown option. Select \"flat\" or \"nested\"\n"; return(""); }

  my @plbs = getPatternListnames();
  my @pats = getPatternnames();

  foreach $plb (@plbs) { $type{$plb} = "PLIST"; }
  foreach $pat (@pats) { $type{$pat} = "PATTERN"; }

  foreach my $plb (@plbs) {
     my $oPtreemgr  = $oTPS->getPatternTreeMgr();
     my $oPtree     = $oPtreemgr->getPatternTree($plb);
     my $oPnode     = $oPtree->getRootPatternList();

     for (my $i=0;$i<$oPnode->getChildCount();$i++) {
  	my $oPn= $oPnode->getChildAt($i);
	my $child = $oPn->getName();
	$child =~  s[^.+:][];  #if referencing a plist from a plist
	if ($mode =~ /skip/i) { $child = $oPn->getSkipped()." ".$child;}
	$patterntree{$plb}[$i] = $child;
     }
  }
  if ($mode !~ /flat/i) { return(%patterntree); }
 
  my $done=0;
  my $skip=0;
  while (!($done)) {
    $done=1;
    foreach $plb (keys %patterntree){
    for(my $i=$#{$patterntree{$plb}};$i>=0;$i--) {
	if ($mode =~ /skip/i) { $patterntree{$plb}[$i] =~ s/(\d) //g; $skip=$1; }
	if ($type{$patterntree{$plb}[$i]} =~ /PLIST/) { 
	    $done=0;
	    my @tmparray = ();
            if ($#{$patterntree{$patterntree{$plb}[$i]}} > -1) {
	        @tmparray = @{$patterntree{$patterntree{$plb}[$i]}};
            }
            if (($skip)&&($mode =~ /skip/i)) { 
		for (my $j=0;$j<= $#tmparray;$j++) {
		    $tmparray[$j] =~ s/\d /$skip /g;
                } 
            }
	    splice(@{$patterntree{$plb}},$i,1,@tmparray); 
 	} elsif ($mode =~ /skip/i) {
	     $patterntree{$plb}[$i] = $skip." ". $patterntree{$plb}[$i];
	}
      }
    }
  }
  return(%patterntree);
}

sub printPatternTree {  # mode=flat|nested
 my $mode = shift;
 my %ptree = getPatternTree($mode);
 $dvlib_function = "CMTDVLib getPatternTree(mode=flat\|nested:$mode)";

 foreach my $plb (keys %ptree){
    print "-i- PLIST: $plb \n";

    for(my $i=0;$i<=$#{$ptree{$plb}};$i++) {
	printf "-i-  \|--- PATTERN: %-5d  $ptree{$plb}[$i] \n",$i;
    }
 }
}

sub insertPattern {  # pattern_list, pattern, indexnumber
  my ($plb,$pat,$index) = @_;
  my $valid=0;
  my $ami_pat=0;
  my $ami_plb=0;
  $dvlib_function = "CMTDVLib insertPattern(plb:$plb pattern:$pat index:$index)";

  my @plbs = getPatternListnames();
  my @pats = getPatternnames();

  foreach my $plist   (@plbs) { 
	if ($plb=~/$plist/)   { $valid=1;   $plb=$plist;    } 
	if ($pat=~/$plist/)   { $ami_plb=1; $pat=$plist;    }
  }
  foreach my $pattern (@pats) { 
	if ($pat=~/$pattern/) { $ami_pat=1; $pat=$pattern;}
  }
  
  if (!(($valid)&&(($ami_plb)||($ami_pat)))) { print "-e- $plb and-or $pat wasn't found $valid $ami_plb $ami_pat\n"; return(); }

  my $oPtreemgr  = $oTPS->getPatternTreeMgr();
  my $oPtree     = $oPtreemgr->getPatternTree($plb);
  my $oPnode     = $oPtree->getRootPatternList();

  if (($index >=-1)&&($index < $oPnode->getChildCount())) {
     print "-i- Inserting $plb : $index $pat\n";
     if ($ami_pat) { $oPnode->insertPattern($index,$pat); }
     if ($ami_plb) { $oPnode->insertReference($index,$pat); }
  } else {
    print "-e- Pattern index requested $index is not valid\n";
  }
  $oPtreemgr->reloadModifiedPatternTrees();
}

sub removePattern {  # patternlist pattern_or_indexnumber
  # proxy cannot remove a child from pattern list if it is a global patternlist that has children....
  my ($plb,$pat) = @_;
  my $valid=0;
  my @plbs = getPatternListnames();
  my $warn = $Win32::OLE::Warn;

  $dvlib_function = "CMTDVLib removePattern(plb:$plb pattern_indexnumber:$pat)";

  foreach my $plist   (@plbs) { if ($plb=~/$plist/)   { $valid=1; $plb=$plist;    } }
  
  if (!($valid)) { print "-e- $plb wasn't found \n"; return(); }

  my $oPtreemgr  = $oTPS->getPatternTreeMgr();
  my $oPtree     = $oPtreemgr->getPatternTree($plb);
  my $oPnode     = $oPtree->getRootPatternList();

  if ($pat =~ /^\d+$/) {
     if (($pat >=0)&&($pat < $oPnode->getChildCount())) {
        my $oPn= $oPnode->getChildAt($pat);
        my $child = $oPn->getName();
        $child =~  s[^.+:][];  #if referencing a plist from a plist

        $Win32::OLE::Warn = 1; # not clean, srotter
        my $global = $oPn->isGlobal();
        $Win32::OLE::Warn = $warn;
	if ($global) {
          print "-i- Cannot remove $plb : $pat $child - Global\n";
        } else {
          print "-i- Removing $plb : $pat $child\n";
	  $oPnode->deleteChildAt($pat);
        }
     } else {
	print "-e- Pattern index requested $pat is not valid\n";
     }
  } else {
     for (my $i=$oPnode->getChildCount()-1;$i>=0;$i--) {
       my $oPn= $oPnode->getChildAt($i);
       my $child = $oPn->getName();
       $child =~  s[^.+:][];  #if referencing a plist from a plist
       if (($child =~ /$pat/i)||($pat eq "all")) {
           $Win32::OLE::Warn = 1;  # not clean, srotter
           my $global = $oPn->isGlobal();
           $Win32::OLE::Warn = $warn;
    	  if ($global) {
            print "-i- Cannot remove $plb : $i $child - Global\n";
          } else {
            print "-i- Removing $plb : $i $child\n";
	    $oPnode->deleteChildAt($i);
          }
       }
     }
  }

  $oPtreemgr->reloadModifiedPatternTrees();
}

sub countPatterns { #
  $dvlib_function = "CMTDVLib countPatterns()";
  my $result  = $oTPS->getPatternMgr()->getPatternCount();
  return ($result);
}
sub getPatternListnames { # 
  $dvlib_function = "CMTDVLib countPatternListNames()";
  my @result  = @{ $oTPL->getPatternListNames() };
  return (@result);
}

sub getPatternnames { #
  $dvlib_function = "CMTDVLib getPatternnames()";
  my @result  = @{ $oTPS->getPatternMgr()->getPatternNames()};
  return (@result);
}
sub getPreamble {  # patternlist
  my ($plb,$pat) = @_;
  $dvlib_function = "CMTDVLib getPreamble(plb:$plb)";

  my $oPtreemgr  = $oTPS->getPatternTreeMgr();
  my $oPtree     = $oPtreemgr->getPatternTree($plb);
  my $oPnode     = $oPtree->getRootPatternList();

  return($oPnode->getPreBurst()->getName());
}
sub setPreamble {  # patternlist
  my ($plb,$pat) = @_;
  $dvlib_function = "CMTDVLib setPreamble(plb:$plb preamble_pattern:$pat)";

  my $oPtreemgr  = $oTPS->getPatternTreeMgr();
  my $oPtree     = $oPtreemgr->getPatternTree($plb);
  my $oPnode     = $oPtree->getRootPatternList();

  foreach my $pattern ( getPatternnames() ) {
    if ($pattern eq $pat) {
      $oPnode->setPreBurst($pat);
      return();
    }
  }
  print "-E- Pattern $pat is not loaded \n";
}
sub getPostamble {  # patternlist
  my ($plb,$pat) = @_;
  $dvlib_function = "CMTDVLib getPostamble(plb:$plb)";

  my $oPtreemgr  = $oTPS->getPatternTreeMgr();
  my $oPtree     = $oPtreemgr->getPatternTree($plb);
  my $oPnode     = $oPtree->getRootPatternList();

  return($oPnode->getPostBurst()->getName());
}
sub setPostamble {  # patternlist
  my ($plb,$pat) = @_;
  $dvlib_function = "CMTDVLib setPostamble(plb:$plb preamble_pattern:$pat)";

  my $oPtreemgr  = $oTPS->getPatternTreeMgr();
  my $oPtree     = $oPtreemgr->getPatternTree($plb);
  my $oPnode     = $oPtree->getRootPatternList();

  foreach my $pattern ( getPatternnames() ) {
    if ($pattern eq $pat) {
      $oPnode->setPostBurst($pat);
      return();
    }
  }
  print "-E- Pattern $pat is not loaded \n";
}

sub loadPatlist { # patternlist_file
  my $plblist = shift;
  $dvlib_function = "CMTDVLib loadPatlist(plist:$plblist)";

  $oSysC->getSysCUserVars()->setExpression( "PAL_PAT_LOADER", 4, 0, "\"$plblist\"" );
  $oSysC->executeCfgPLLoadFlow();
  $oSysC->getSysCUserVars()->deleteVar("PAL_PAT_LOADER");
}

sub createFlowItem { # test_instance flowitem
  my ($testname, $flowitemname) = @_;
  $dvlib_function = "CMTDVLib createFlowItem(testname:$testname, flowitemname:$flowitemname)";

  my $oTest = $oTPL->getTest ($testname);
  for(my $i=0;$i<$oFLW->getNumberOfItems();$i++) {
    if ($flowitemname eq $oFLW->getFlowItemByIndex($i)->getName()) {
	print "-w- $flowitemname already exists - over-writing\n";
	$oFLW->removeFlowItem($flowitemname);		
    }
  }	
  $oFLW->createFlowItem($flowitemname,$oTest);
}

sub deleteFlowItem { # flowitem
  my ($flowitemname) = @_;
  $dvlib_function = "CMTDVLib deleteFlowItem(flowitemname:$flowitemname)";

  for(my $i=0;$i<$oFLW->getNumberOfItems();$i++) {
    if ($flowitemname eq $oFLW->getFlowItemByIndex($i)->getName()) {
	$oFLW->removeFlowItem($flowitemname);		
    }
  }
}

sub removeConnection { # flowitem port
  my ($flowitemname, $port) = @_;
  $dvlib_function = "CMTDVLib removeConnection(flowitemname:$flowitemname, port:$port)";

  for(my $i=0;$i<$oFLW->getNumberOfItems();$i++) {
    if ($flowitemname eq $oFLW->getFlowItemByIndex($i)->getName()) {
	$oFLW->removeTransition($port, $flowitemname);		
    }
  }
}
  
sub addReturnPort { # flowitem port
  my ($flowitemname, $port) = @_;
  $dvlib_function = "CMTDVLib addReturnPort(flowitemname:$flowitemname, port:$port)";

  for(my $i=0;$i<$oFLW->getNumberOfItems();$i++) {
    if ($flowitemname eq $oFLW->getFlowItemByIndex($i)->getName()) {
    	$oFLW->getFlowItemByIndex($i)->addReturnResult($port, $port);
    }
  }
}

sub removeReturnPort { # flowitem port
  my ($flowitemname, $port) = @_;
  $dvlib_function = "CMTDVLib removeReturnResult(flowitemname:$flowitemname, port:$port)";

  for(my $i=0;$i<$oFLW->getNumberOfItems();$i++) {
    if ($flowitemname eq $oFLW->getFlowItemByIndex($i)->getName()) {
    	$oFLW->getFlowItemByIndex($i)->removeReturnResult($port, $port);
    }
  }
}

sub connectFlowItems { # port flowitem_from flowitem_to
  my ($port,$flowitem_from, $flowitem_to) = @_;
  $dvlib_function = "CMTDVLib connectFlowItems(port:$port,flowitem_from:$flowitem_from, flowitem_to:$flowitem_to)";

  $oFLW->addTransition($port,$flowitem_from,$flowitem_to);
}

sub getUserVar { # user_var_collection variable
  my ($UVCollection,$var) = @_; 
  $dvlib_function = "CMTDVLib getUserVar (UserVar_Collection:$UVCollection,variable:$var)";

  foreach my $uservar ( @ { $oTPL->getUserVars($UVCollection)->getVarNames() }) { 
    if ($uservar eq $var) { 
    	my $value = $oTPL->getUserVars($UVCollection)->getExpressionString($var);
    	$value =~ s/\"//g; # TSS Insists on these annoying quotes for strings
    	return $value;
    }
  }
  print "-e- GetUser $UVCollection $var does not exist\n";
  return("cmtdvlib-error");
}

sub setUserVar { # user_var_collection variable value
  my ($UVCollection,$var,$value) = @_;  
  $dvlib_function = "CMTDVLib setUserVar (UserVar_Collection:$UVCollection,variable:$var,value:$value)";

  my $UVCollectionProxy = $oTPL->getUserVars($UVCollection);
  foreach my $uservar ( @ { $oTPL->getUserVars($UVCollection)->getVarNames() }) {
    if ($uservar eq $var) { 
      my $type = $UVCollectionProxy->getVarDataType($var);
      if ($type==Proxy_StringT)
      {
        $value = "\"$value\"";
      }
      my $isConst = $UVCollectionProxy->getIsConst($var);   
      $UVCollectionProxy->setExpression($var,$type,$isConst,$value) ;
      $UVCollectionProxy->evaluateAll();
      return();
    }
  }
  print "-e- SetUser $UVCollection $var does not exist\n";
}

sub createUserVar { # user_var_collection String|Int|Boolean variable value
    my ($UVCollection,$exp_type,$var,$value) = @_;
    $dvlib_function = "CMTDVLib getUserVar (UserVar_Collection:$UVCollection,type:$exp_type,variable:$var,value:$value)";

    my $UVCollectionProxy = $oTPL->getUserVars($UVCollection);
    $exp_type = "Proxy_".$exp_type."T";  #ex. exp_type = Int,   Double,   String,   Boolean,   Time, 
    my $type = eval($exp_type); 
    if ($type==Proxy_StringT)
    {
        $value = "\"$value\"";
    }
    my $isConst = 0; 
    $UVCollectionProxy->setExpression($var,$type,$isConst,$value) ;
    $UVCollectionProxy->evaluateAll();
}

sub getSignalsbyType { # return array ins|outs|inouts|bus|signal
  my $select = shift;
  $dvlib_function = "CMTDVLib getSignalsbyType(type:$select)";

  my (@pins,@buses,@ins,@outs,@inouts);
  my $warn = $Win32::OLE::Warn;
  $Win32::OLE::Warn = 1;

  foreach my $signal ( @{$oTPL->getSignalNames()} ) {
    if (!(defined $oTPL->getSignalType($signal))) {
	push @buses, $signal;
    } elsif ($oTPL->getSignalType($signal) == Proxy_SignalTypeIn) {
	push @ins,$signal; 
    } elsif ($oTPL->getSignalType($signal) == Proxy_SignalTypeInOut) {
	push @inouts,$signal;
    } elsif ($oTPL->getSignalType($signal) == Proxy_SignalTypeOut) {
	push @outs,$signal;
    } elsif ($oTPL->getSignalType($signal) == Proxy_SignalTypeUndefined) {
    } else {
    }
  }
  $Win32::OLE::Warn = $warn;
  if (($select =~ /^in$/i)||($select =~ /^ins$/i)) { 
	return (@ins); 
  } elsif (($select =~ /^out$/i)||($select =~ /^outs$/i)) {
	return (@outs);
  } elsif (($select =~ /bidir/i)||($select =~ /inout/i)) {
	return (@inouts);
  } elsif ($select =~ /bus/i) {
	return(@buses);
  } elsif ($select =~ /signal/i) {
	return((@ins,@outs,@inouts));
  }
  return(@{$oTPL->getSignalNames()});
}

sub maskPins { # test instance array_pins
  my ($testname,@pins) = @_;
  $dvlib_function = "CMTDVLib maskPins(testname:$testname,PinArray:".join(" ",@pins).")";

  maskPinsbyTestinstance($testname,@pins);
  my $patlist = getTestparams($testname,"patlist");
  maskPinsbyPatlist($patlist,@pins);
}

sub maskPinsbyTestinstance { # test instance array_pins
  my ($testname,@pins) = @_;
  $dvlib_function = "CMTDVLib maskpinsTestinstance(testname:$testname,PinArray:".join(" ",@pins).")";

  print "-i- Old Test Mask: ".getTestparams($testname,"mask_pins")."\n";
  setTestparam($testname,"mask_pins",join(" ",@pins));
  print "-i- New Test Mask: ".getTestparams($testname,"mask_pins")."\n";
}

sub maskPinsbyPatlist { # pattern_list array_pins
  my ($plist,@pins) = @_;
  $dvlib_function = "CMTDVLib maskpinsPatlist(plist:$plist,PinArray:".join(" ",@pins).")";

  my $oPtreemgr  = $oTPS->getPatternTreeMgr();
  my $oPtree     = $oPtreemgr->getPatternTree($plist);
  my $oPnode     = $oPtree->getRootPatternList();
  if ($#pins==-1) { @pins = (""); }
  print "-i- Old Pat Mask: ".join(" ",@{$oPnode->getMask()})."\n";
  $oPnode->setMask(\@pins);
  print "-i- New Pat Mask: ".join(" ",@{$oPnode->getMask()})."\n";
  $oPtreemgr->reloadModifiedPatternTrees();
}

## SBCMD Functions
######################################################################
sub tsearch #(test_name, tparam, mode, start, stop, step)
{
	#Return(scalar context):  Fmax
	#or
	#Return(array context): Fmax, failing pattern, fail vector, fail pins

    my ($test_name, $BaseClock, $mode, $StartClock, $EndClock,$StepClock) =@_;
  
    my $origValue =getTimingValue($test_name,$BaseClock);
    
    $oSBC->execute ("outscript");
    $oSBC->execute ("exec $test_name");
    suspendExecMode($test_name);
    sleep 2;  #No better method for now

    my @answer = split('\n',$oSBC->execute ("tsearch $BaseClock $mode $StartClock $EndClock $StepClock norestore"));
    my @results =split(' ',$answer[7]);
    my $fmax = $results[3]; #convert to number       

    if (not wantarray()) #Just return Fmax if thats all thats needed
    {
        setTimingValue($test_name,$BaseClock,$origValue);
        clearExecMode();
        return $fmax;  
    }        
    
    #Get Fail data
    $oSBC->execute ("patexec display FailOnly 1");
    $oSBC->execute ("patexec simple_form result pattern ffaddr ffpins");
    @answer = split('\n',$oSBC->execute ("patexec"));
    my $patinfo = $answer[5];
    $patinfo =~ /[\w]*\s*([\w]*)\s*([\d]*)\s*(.*)/; #FAIL   PATTERN_NAME   FAILVECTOR    FailPins...
    my $pattern =$1;
    my $vector =int($2); 
    my $pins = $3;
   
    setTimingValue($test_name,$BaseClock,$origValue);
    clearExecMode();
       
    return $fmax ,$pattern,$vector,$pins;
}

## Datalogging Functions
######################################################################

sub startLog { #(ALL | CONSOLE | SBCMD | ITUFF, Path, Prefix - Should be unique like ULT)
   $logOption = shift;
   $logPath = shift;
   $prefix = shift;
   if (!(-e $logPath)) {
      mkdir "$logPath"; 
   }
   print "$logPath exists\n";
   if (($logOption ne "ALL") && ($logOption ne "SBCMD") && ($logOption ne "CONSOLE") && ($logOption ne "ITUFF")) {
       print "Unknown Log Option \n";
       print "Defaulting to ALL\n";
       $logOption = "ALL";
   }
 
   if (($logOption eq "ALL") || ($logOption eq "ITUFF")) {
      setTestparam("Ituff_start","datalog_add_stream_type","OVERWRITE");
      executeTestInstance("Ituff_start");
   }
   if (($logOption eq "ALL") || ($logOption eq "CONSOLE")) {
   print "Console Log Option Selected.\n";
      logConsole();
   }
   if (($logOption eq "ALL") || ($logOption eq "SBCMD")) {
      logSBCMD();
   }
}

sub logSBCMD {
   my $tempsbcmdfile; 
   $tempsbcmdfile = $ENV{SystemDrive}."\\temp\\".$prefix."_sbcmd.log";
   $oSBC->execute("outfile $tempsbcmdfile overwrite");
}

sub logConsole {
    my $tempconsolefile;
    my $cscriptExe;
    $tempconsolefile = $ENV{SystemDrive}."\\Temp\\".$prefix."_console.log";
    $cscriptExe = $ENV{SystemDrive}."\\Windows\\System32\\cscript.exe";
   
    my $Arguments = "cscript". " ".$ENV{DV_ROOT}."\\ToolBox\\Misc\\ConsoleApp.vbs"."  "."-site1"." ".$tempconsolefile;
    Win32::Process::Create($processObj,$cscriptExe, $Arguments, 1, CREATE_NEW_PROCESS_GROUP,$ENV{SystemDrive}."\\Windows\\System32\\");
    sleep(5);
}

sub print2Console {
    my $data = shift;
    $oSBC->execute("outconsole on"); 
    $oSBC->execute("print $data");
}

sub print2Ituff {
    my $data = shift;
    my @parameters=("function_name=Print2Ituff.dll!Print2Ituff","function_parameter=$data");
    createTestInstance("iCUserFuncTest","Print2ItuffUF",@parameters);
    #verifyTest("Print2ItuffUF");
    executeTestInstance("Print2ItuffUF");
}

sub printData {
    my $data = shift;
    print2Console($data);
    print2Ituff($data);
}

sub stopLog { #()
   ($logOption, $logPath, $prefix) = @_ if ( $#_==2 ); #optional argument
   my $tempituff;
   my $tempconsole;
   my $tempsbc;
   
   my $sbcfile;
   my $itufffile;
   my $consolefile;

   if (($logOption eq "ALL") || ($logOption eq "ITUFF")) {
      setTestparam("Ituff_end","datalog_add_stream_type","OVERWRITE");
      executeTestInstance("Ituff_end");
      $itufffile = $logPath."\\".$prefix."_ituff.log";
      
      if ($oSysC->getMode() == Proxy_SYSC_MODE_ONLINE) {
	  $tempituff = $ENV{SystemDrive}."\\T2000Install\\tmp\\SiteC_1\\.1";
      }
      else {
      	  $tempituff = "C:\\T2000\\root\\tmp\\SiteC_1\\.1";
      }
      $oSysC->downloadFile(1,$tempituff,"$itufffile");
   }
   if (($logOption eq "ALL") || ($logOption eq "CONSOLE")) {
      $tempconsole = $ENV{SystemDrive}."\\Temp\\".$prefix."_console.log";
      my $prev = -1;
      my @fileData = ();    
      while($prev ne $fileData[7]) {
      	$prev = $fileData[7];
    	sleep(3);
        @fileData =  stat($tempconsole);
      }
      $consolefile =  $logPath.$prefix."_console.log";
      $processObj->Kill(0);
      copy($tempconsole, $consolefile) or die "File cannot be copied. $tempconsole, $consolefile";
   }
   
   if (($logOption eq "ALL") || ($logOption eq "SBCMD")) {
      $oSBC->execute("outfile off");
      $tempsbc = $ENV{SystemDrive}."\\temp\\".$prefix."_sbcmd.log";  
      $sbcfile = $logPath."\\".$prefix."_sbcmd.log";
      $oSysC->downloadFile(1,$tempsbc,$sbcfile);
   }
}

## Clean Functions
######################################################################
sub TimeStamp {
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
  $year += 1900;  $mon  += 1;
  if ($sec  !~ /\d\d/) { $sec  = "0".$sec;  }
  if ($min  !~ /\d\d/) { $min  = "0".$min;  }
  if ($hour !~ /\d\d/) { $hour = "0".$hour; }
  if ($mday !~ /\d\d/) { $mday = "0".$mday; }
  if ($mon  !~ /\d\d/) { $mon  = "0".$mon;  }

  return($year."-".$mon."-".$mday.", ".$hour.".".$min.".".$sec.", ".time);
}
sub Update_Log {
  my $comment  = shift;
  my $product  = $oSysC->getEnv("DV_PROD");;
  my $stepping = $oSysC->getEnv("DV_STEP");
  my $IDSID    = $oSysC->getEnv("DV_NAME");
  my $stoptime = time;
  my $tp_dir = $oSysC->getTestPlanDLLName();
  my $tester = hostname .", ".$oSysC->getSystemCName().", ".$oSysC->getTesterName();
  my $buffer = TimeStamp().", ".(time-$starttime);
  $buffer   .= ", $product, $stepping, $IDSID, $tester, $tp_dir, $comment";

  open (OUT,">>$ENV{DV_TOOL}\\Log\\logger.dat");
  if (!(-e "$ENV{DV_TOOL}\\Log\\logger.dat")) { 
    print "-i- Cannot Log Usages \n"; 
    close (OUT); return();
  }
  unless (flock(OUT,2 | 4)) {
    print "-I- Waiting for logger.dat\n";
    flock(OUT,2);
  }
  print OUT "$buffer\n"; close(OUT);
}

END {
  
  # dereference OLE interface variables.
  if ($initialized) {
    if ($oSysC->getMode() == Proxy_SYSC_MODE_ONLINE) {
      Update_Log("DVLIB $0");
    }
    print "-i- Exiting CMTDVLib \n";
    undef $oSBC;
    undef $oFLW;
    undef $oTPL;
    undef $oTPS;
    undef $oSysC;
  }
}

1;

__END__
= CMTDVLib =
== Summary ==
This is a DVLib perl module to enable perl modifications to the CMT testprogram

== Functions ==
{|border="1" cellpadding="3" cellspacing="0" 
|- style="font-weight:bold"  valign="bottom"
| width="150.5" Height="12.75" | FUNCTION
| width="250.25" | DESCRIPTION
| width="100.5" | INPUTS/OUTPUTS
|- 
| convBase ()
| convert values to base numbers
| 
  i: value_with_units
  o: value
  ex: convBase("1mV");    convBase("1ns");
|- 
|  conv_ms ()
| convert values
| 
  i: value
  o: value_with_units
  ex: conv_ms("10");
|- 
|  conv_us ()
| convert values
| 
  i: value
  o: value_with_units
  ex: conv_us("10");
|- 
|  conv_ns ()
| convert values
| 
  i: value
  o: value_with_units
  ex: conv_ns("10");
|- 
|  conv_ps ()
| convert values
| 
  i: value
  o: value_with_units
  ex: conv_ps("10");
|- 
|  initCMT ()
| initializes the perl connection to tester
| 
  i: site
  o: 
  ex: initCMT(1);
|-
|executeMainFlowItem ()
| executes a main flow flowitem and returns pass/fail
|
  i: flowitem
  o: results
  ex: 
|-
|executeFlowItem ()
|
|
  i: flow flowitem
  o: results
|-
|executecontinueMainFlowItem ()
|
|
  i: flowitem
  o: results
|-
|executecontinueFlowItem ()
|
|
  i: flow flowitem
  o: results
|- 

| executeInitFlow()
| executes the Init Flow within the testprogram and returns "PASS" or "FAIL"
| 
  i:
  o: PASS_or_FAIL
  ex:  $result = executeInitFlow();
|- 
| clearExecMode ()
| clears the ExecMode flags on Test Instance
| 
  i:
  o:
  ex:  clearExecMode();
|- 
| suspendExecMode ()
| puts test into suspend for Shmoo
| 
  i: test_instance
  o: 
  ex:  suspendExecMode ("myftestname")
|- 
| executeTest ()
| executes the flowitem corresponding to the test instance given.  corresponding flow item is the testinstance name with eos appended
| 
  i: test_instance
  o: resulting port
  ex: executeTest("myftestname");
|- 
| createTest ()
| creates a new test instance and flowitem.  The Params may be an empty array or can be the full list of paramters from the test instance. corresponding flow item which is testinstance name with eos appende
| 
  i:  test_type testname parameter_array
  o:
  ex:
  @params = (""level=bfloose_Rtten_xxt_edc_1_2V"",""timings=f1_br44_2000"",""patlist=ft_wcsp_psmi_014444_list""); #can be all or none of template parameters
  createTest(""iCFuncTest"",""myftestname"",@params);
  @params = ();
  createTest(""iCShmooTest"",""mynewshmoo"",@params);
  createTest(""iCIPOTest"",""mynewIPO"",@params);"
|- 
| deleteTest ()
| delete test instance and its corresponding flow item which is testinstance name with eos appended
| 
  i: test_instance
  o:
  ex: deleteTest ("myftestname")
|- 
| executeTestInstance ()
| executes any test instance
| 
  i: test_instance
  o: results (The valid values are: 1: Pass, 2: Fail, 3: failed to run, 4: not tested, 5: Other)
  ex: executeTestInstance("myftestname");
|- 
| createTestInstance ()
| creates a new test instance.  The Params may be an empty array or can be the full list of paramters from the test instance.
| 
  i:  test_type testname parameter_array
  o:
  ex:
  @params = (""level=bfloose_Rtten_xxt_edc_1_2V"",""timings=f1_br44_2000"",""patlist=ft_wcsp_psmi_014444_list""); #can be all or none of template parameters
  createTestInstance(""iCFuncTest"",""myftestname"",@params);
  @params = ();
  createTestInstance(""iCShmooTest"",""mynewshmoo"",@params);
  createTestInstance(""iCIPOTest"",""mynewIPO"",@params);"
|- 
| deleteTestInstance ()
| delete test instance
| 
  i: test_instance
  o:
  ex: deleteTestInstance ("myftestname")
|- 
| verifyTest ()
| verifies
| 
  i: test_instance
  o: 
  ex: verifyTest ("myftestname")
|- 
| returnTestparam ()
| Returns the full list of test instance parameters either as a "hash" or "array"
| 
  i: test_instance array|hash
  o: array|hash
  ex:  %a = returnTestparam ("myftestname","hash"); @a = returnTestparam ("myftestname","array")
|- 
| setTestparam ()
| Set test instance param
| 
  i: test_instance, paramter, value
  o: 
  ex:  setTestparam ("myftestname","patlist","ft_wcsp_list")
|- 
| getTestparams ()
| returns param value
| 
  i: test_instance paramter
  o: value
  ex: $myplist = getTestparams ("myftestname","patlist")
|- 
| setLevels ()
| wrapper around setTestparam
| 
  i: test_instance value
  o:
  ex: setLevels ("myftestname","bfloose_Rtten_xxt_edc_1_2V")
|- 
| setTimings ()
| wrapper around setTestparam
| 
  i: test_instance value
  o: 
  ex: setTimings ("myftestname","f1_br44_2000")
|- 
| setPatlist ()
| wrapper around setTestparam
| 
  i: test_instance value
  o:
  ex: setPatlist ("myftestname","ft_wcsp_list")
|- 
| setLevelValue ()
| sets a spec set value from Level
| 
  i: test_instance spec_set_var value
  o:
  ex:  setLevelValue ("myftestname","vid_spec","1.1V")
|- 
| getLevelValue ()
| gets a spec set value from Level
| 
  i: test_instance spec_set_var
  o: value
  ex: $vid = getLevelValue ("myftestname","vid_spec")
|- 
| setLevelBlockValue ()
| sets a spec set value from Level
| 
  i: levels_block spec_set_var value
  o:
  ex:
|- 
| getLevelBlockValue ()
| gets a spec set value from Level
| 
  i: levels_block spec_set_var
  o: value
  ex: 
|- 
| setTimingValue ()
| sets a spec set value from Timing
| 
  i: test_instance spec_set_var value
  o: 
  ex:  setTimingValue ("myftestname","TCK_su","1nS")
|- 
| getTimingValue ()
| gets a spec set value from timing
| 
  i: test_instance spec_set
  o: value
  ex:  $period= getTimingValue ("myftestname","FSBper_spec")
|- 
| setTimingBlockValue ()
| sets a spec set value from Timing
| 
  i: timing_block spec_set_var value
  o: 
  ex:
|- 
| getTimingBlockValue ()
| gets a spec set value from timing
| 
  i: timing_block spec_set_var
  o: value
  ex:
|- 
| burstPatlist ()
| This function will set the Burst and BurstOff flags in the patternlist template
| 
  i: plb, mode 0=bursted 1=no bursted
  o:
  ex: burstPatlist("myfavoritelist",1);
|- 
|  skipPattern ()
| Sets the skip function for an element in the patternlist
| 
  i: plb, pattern, mode 0=not skip 1=skipped
  o: 
  ex: skipPattern("myfavoritelist","mypattern",1);
|- 
|  getPatternTree ()
|  returns the hash of arrays for the pattern tree.  This can take the form of 'flat' which recursively returns the patterns in sub-plists so the returned hash lists only patterns for each element in the array.  The use of 'nested' will return the hash as seen through the GUI with sub-plist listed.  The addition of skip will return the skipflag set for each element in the hash of array.
| 
 i: nested|flat|skipflat|skipnested
 o: hash{plb}[#]   This is a hash of arrays.  each hash is plist and each array element is a child pattern|plist.  if skip is selected each element in the array will display skip flat followed by name ie "1 test_pattern" is a skipped pattern.
 ex: %tree = getPatternTree("flat");  print $tree{myfavoritelist}[0];
     %tree = getPatternTree("skipflat");  if ($tree{myfavoritelist}[0] =~ /^1 (.+)/) { print "The pattern $2 is skipped\n"; }
|- 
|  printPatternTree ()
|  Displays the whole pattern tree loaded into memory to screen.  See getPatternTree() for options.
| 
  i: nested|flat|skipflat|nestedflat
  o: screen display of pattern tree

|- 
|  insertPattern ()
|  This function inserts a pattern into a patternlist. This needs the user to identify where in the patternlist to do the insertion.  index=-1 will insert
| 
  i: patternlist, pattern, index location within patternlist
  o: 
   ex: insertPattern("basic_func_list","basic_func_pattern",0);
|- 
|  removePattern ()
|  This function removes a pattern from a patternlist.  This 
| 
  i: patternlist, patternname_or_indexnumber
  o: 
   ex: removePattern("basic_func_list","basic_func_pattern");  
       removePattern("basic_func_list",1);
|- 
|  countPatterns ()
| 
| 
  i:
  o: result
  ex: $totalpatternsloaded = countPatterns ()
|- 
| getPatternListnames ()
| returns all plb loaded
| 
  i: 
  o: array
  ex: @plb = getPatternListnames ()
|- 
| getPatternnames ()
| returns all pattern names
| 
  i:
  o: array
  ex: @patterns = getPatternnames ()
|- 
| getPreamble ()
| returns preBurst pattern name
| 
  i: patlist
  o: preamble_pattern_name
  ex: $preamble = getPreamble ("ft_list")
|- 
| setPreamble ()
| sets the preBurst pattern name
| 
  i: patlist, preamble_pattern_name
  o: 
  ex: setPreamble ("ft_list","pre_014444_xxxxxx")
|- 
| getPostamble ()
| returns postBurst pattern name
| 
  i: patlist
  o: postamble_pattern_name
  ex: $postamble = getPostamble ("ft_list")
|- 
| setPostamble ()
| sets the postBurst pattern name
| 
  i: patlist, postamble_pattern_name
  o: 
  ex: setPostamble ("ft_list","pre_014444_xxxxxx")
|- 
| loadPatlist ()
| loads a patternlist
| 
  i: plist_name
  o:
  ex: loadPatlist("cat_pats.plist");
|- 
| createFlowItem () 
| 
| 
  i: test_instance flowitem
  o:
  ex: createFlowItem ("myftestname","myflowname")
|- 
|  deleteFlowItem ()
| 
| 
  i: flowitem
  o:
  ex: deleteFlowItem ("myflowname")
|- 
| connectFlowItems () 
| 
| 
  i: port flowitem_from flowitem_to
  o:
  ex: connectFlowItems ($portnumber,"myflowname","Powerdown")
|- 
| getUserVar () 
| 
| 
  i: user_var_collection variable
  o: value
  ex: $ituffpath = getUserVar("CTSCVars","SC_ITUFF_PATH")
|- 
| setUserVar { 
| 
| 
  i: user_var_collection variable value
  o:
  ex: setUserVar("_UserVars","GL_FuseConfig_Enable_site0","111001010001010101")
|- 
| createUserVar ()
| 
| 
  i: user_var_collection String|Int|Boolean variable value
  o:
  ex: setUserVar("_UserVars","Boolean","Am_I_DV_Ready","1")

|-
| getSignalsbyType ()
| 
| 
  i: "ins"|"outs"|"inouts"|"bus"|"signal"
  o: array
  ex: @inputs = getSignalsbyType("ins");
  ex: @allpins = getSignalsbyType("signal");
  
|-
| removeConnection ()
| 
| 
  i: flowitem_from port
  o: 
  ex: removeConnection("EnableCORE0", "-1");

|-
| addReturnPort ()
| 
| 
  i: flowitem port
  o: 
  ex: addReturnPort("addReturnPort", "-1");

|-
| removeReturnPort ()
| 
| 
  i: flowitem port
  o: 
  ex: removeReturnPort("addReturnPort", "-1");
 
|-
|  
| 
| 

|-
| SPECIAL VARIABLES
| DESCRIPTION
| EXAMPLE

|- 
| $oSysC
| pointer to TSS System
| 

|- 
| $oTPS
| pointer to Site Controller
| 

|- 
| $oTPL
| pointer to TestPlan on Site Controller
| 

|- 
| $oFLW
| pointer to Flow Tool
| 

|- 
| $oSBC
| pointer to SBCMD or Helperclass
| 
  $testresult = $oSBC->execute(""exec $test"");
  suspendExecMode($test);
  $oSBC->execute(""shmoo clear"");
  $oSBC->execute(""shmoo mode all_fails"");
  $oSBC->execute(""shmoo setup x tcparam FSBper_spec 8nS 20nS 1nS"");
  $oSBC->execute(""shmoo setup y tcparam vid_spec 0.8 1.2 0.1""); 
  $result = $oSBC->execute(""shmoo run"");
  clearExecMode();
  print $result;" 
|}

== Examples ==
<pre>
use lib "$ENV{DV_TOOL}/DVLib/";
use CMTDVLib;

initCMT(1);

my $test = "Stephans_Demo_Test1";
my @params = ("level=bfloose_Rtten_xxt_edc_1_2V","timings=f1_br44_2000","patlist=ft_wcsp_psmi_014444_list");
createTest("iCFuncTest",$test,@params);

print "Simple Shmoo\n";
print "Results : 1=P, 2=F, 3=Err, 4=? ; ";
for(my $level=0.9;$level<=1.3;$level+=0.1) {
  setLevelValue($test,"vid_spec",$level);
  for(my $timing=convBase("8nS");$timing<=convBase("12nS");$timing+=convBase("1nS")) {
    setTimingValue($test,"FSBper_spec",conv_ns($timing));
    $result = executeTest($test);
    printf "%3.2f %5s = $result \n",$level, conv_ns($timing);
  }
}
print "Simple Shmoo - done\n";

print "Simple Flow in FlowMain\n";
createFlowItem($test,"demo_flowitem_A");
createFlowItem($test,"demo_flowitem_B");
createFlowItem($test,"demo_flowitem_C");
$oFLW->setStartItem("demo_flowitem_A");
connectFlowItems(0,"demo_flowitem_A","demo_flowitem_B");
connectFlowItems(1,"demo_flowitem_A","demo_flowitem_C");
connectFlowItems(0,"demo_flowitem_B","Pwrdwn_comp_eos0");
connectFlowItems(1,"demo_flowitem_B","Pwrdwn_comp_eos0");
connectFlowItems(0,"demo_flowitem_C","Pwrdwn_comp_eos0");
connectFlowItems(1,"demo_flowitem_C","Pwrdwn_comp_eos0");
print "Simple Flow in FlowMain - done\n";

print "Simple SBCMD script\n";
setTestparam($test,"EOT_power_down","TRUE");
setLevels($test,"bfloose_Rtten_xxt_DV_nomnom");  ## same as setTestParam($test,"level","bfloose_Rtten_xxt_DV_nomnom");
suspendExecMode($test);
$oSBC->execute("shmoo clear");
$oSBC->execute("shmoo mode all_fails");
$oSBC->execute("shmoo setup x tcparam FSBper_spec 8nS 20nS 1nS");
$oSBC->execute("shmoo setup y tcparam vid_spec 0.8 1.2 0.1");
$result = $oSBC->execute("shmoo run");
clearExecMode();
print "Simple SBCMD script - done\n";

open (OUT, ">$ENV{DV_DATA}\\Demo_Results.txt");
print OUT $result;
close OUT;

</pre>

