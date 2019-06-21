
use Cwd;
my $Dir = getcwd;
my $FlowDir = $Dir . "/source/Flow/";
my $InstanceDir = $Dir . "/source/Instances/";
my $ExcludedTestFile = "./excludetest.txt";

my $HDBin = 4; # Digital
my $Firstdigit = 1 ; # Digital


my $Header = "DTTestInstancesSheet,version=2.4:platform=Jaguar:toprow=-1:leftcol=-1:rightcol=-1	Test Instances																																																																																																																																																
																																																																																																																																																	
		Test Procedure			DC Specs		AC Specs		Sheet Parameters					Other Parameters																																																																																																																																			
	Test Name	Type	Name	Called As	Category	Selector	Category	Selector	Time Sets	Edge Sets	Pin Levels	Mixed Signal Timing	Overlay	Arg0	Arg1	Arg2	Arg3	Arg4	Arg5	Arg6	Arg7	Arg8	Arg9	Arg10	Arg11	Arg12	Arg13	Arg14	Arg15	Arg16	Arg17	Arg18	Arg19	Arg20	Arg21	Arg22	Arg23	Arg24	Arg25	Arg26	Arg27	Arg28	Arg29	Arg30	Arg31	Arg32	Arg33	Arg34	Arg35	Arg36	Arg37	Arg38	Arg39	Arg40	Arg41	Arg42	Arg43	Arg44	Arg45	Arg46	Arg47	Arg48	Arg49	Arg50	Arg51	Arg52	Arg53	Arg54	Arg55	Arg56	Arg57	Arg58	Arg59	Arg60	Arg61	Arg62	Arg63	Arg64	Arg65	Arg66	Arg67	Arg68	Arg69	Arg70	Arg71	Arg72	Arg73	Arg74	Arg75	Arg76	Arg77	Arg78	Arg79	Arg80	Arg81	Arg82	Arg83	Arg84	Arg85	Arg86	Arg87	Arg88	Arg89	Arg90	Arg91	Arg92	Arg93	Arg94	Arg95	Arg96	Arg97	Arg98	Arg99	Arg100	Arg101	Arg102	Arg103	Arg104	Arg105	Arg106	Arg107	Arg108	Arg109	Arg110	Arg111	Arg112	Arg113	Arg114	Arg115	Arg116	Arg117	Arg118	Arg119	Arg120	Arg121	Arg122	Arg123	Arg124	Arg125	Arg126	Arg127	Arg128	Arg129	Comment	\n";

my @ExcludedTests = ();
open (EXCLUDEDTEST, $ExcludedTestFile) || die "Cant open $ExcludedTestFile : $!\n";
while (<EXCLUDEDTEST>)
{
	chomp;
	push (@ExcludedTests, $_);
}
close EXCLUDEDTEST;

my @RawTests = ();
foreach my $File (<$FlowDir*>)
{
	#print "$File\n";	
	open (FILE, $File) || die "Can't open $File : $!\n";
	while (<FILE>)
	{	
		chomp;
		if (/\t+Test\t(\S+)\t+/ig)
		{
			#print "$1\n";
			push (@RawTests, $1);
		}
	}
	close FILE;
}

my @RawTestInstances = ();
foreach my $File (<$InstanceDir*>)
{
	#print "$File\n";
	my $bFoundFlag = 0;	
	open (FILE, $File) || die "Can't open $File : $!\n";
	while (<FILE>)
	{
		if (!$bFoundFlag)
		{
			if (/\s+Test\s+Name.*/ig)
			{
				$bFoundFlag = 1;
			}
			next;
		}

		#print "$_";
		push (@RawTestInstances, $_);
		#if (/\s+(\S+)\s+VBT/ig)
		#{
		#	print "$1\n";
		#	push (@RawTestInstances, $_);
		#}
	}
	close FILE;
}

my %UniqueTests = ();
my $FoundFlag = 0;
foreach my $RawTest (@RawTests)
{
	$FoundFlag = 0;
	foreach my $ExcludedTest (@ExcludedTests)
	{
		if ($RawTest =~ /$ExcludedTest/i)
		{
			$FoundFlag = 1;
			#print "$RawTest\n";
			last;
		}
	}

	if (!$FoundFlag)
	{
		chomp($RawTest);
		#print "$RawTest\n";
		$UniqueTests{$RawTest} = $RawTest;
	}
}


my $HighCond = "	Set_VDD_COND_CHAR_VHIGH	VBT	Set_VDD_COND_DIG		CHAR_VHIGH	Nom					Levels_DIG			vcond_lvl	VHIGH																																																																																																																																		
";
my $LowCond = "	Set_VDD_COND_CHAR_VLOW	VBT	Set_VDD_COND_DIG		CHAR_VLOW	Nom					Levels_DIG			vcond_lvl	VLOW																																																																																																																																		
";
my $NomCond = "	Set_VDD_COND_CHAR_VNOM	VBT	Set_VDD_COND_DIG		CHAR_VNOM	Nom					Levels_DIG			vcond_lvl	VNOM																																																																																																																																		
";
my $MinCond = "	Set_VDD_COND_CHAR_VMIN	VBT	Set_VDD_COND_DIG		CHAR_VMIN	Nom					Levels_DIG			vcond_lvl	VMIN																																																																																																																																		
";
my $MaxCond = "	Set_VDD_COND_CHAR_VMAX	VBT	Set_VDD_COND_DIG		CHAR_VMAX	Nom					Levels_DIG			vcond_lvl	VMAX																																																																																																																																		
";

my $P10_Tests = "";
my $M10_Tests = "";
my $P7_Tests = "";
my $M7_Tests = "";
my $MIN_Tests = "";
my $MAX_Tests = "";
my $NOM_Tests = "";

foreach my $Test (sort {$a cmp $b} keys %UniqueTests)
{
	#print "### $UniqueTests{$Test}\n";
	foreach my $Item (@RawTestInstances)
	{
		my $Temp = $Item;
		$Temp =~ s/\\/\//ig;
		
		if ($Temp =~ /\s+$UniqueTests{$Test}\s+/ig)
		{
			#print "$Item";
			my $Min = $Item;
			$Min =~ s/$UniqueTests{$Test}\t/$UniqueTests{$Test}_VMIN\t/g;
			$MIN_Tests .= $Min;
			#print "$Min";

			my $Max = $Item;
			$Max =~ s/$UniqueTests{$Test}\t/$UniqueTests{$Test}_VMAX\t/g;
			$MAX_Tests .= $Max;
			#print "$Max";

			my $Nom = $Item;
			$Nom =~ s/$UniqueTests{$Test}\t/$UniqueTests{$Test}_VNOM\t/g;
			$NOM_Tests .= $Nom;
			#print "$Nom";
			
			my $High = $Item;
			my $Low = $Item;

			#if ($Temp =~ /membist/ig)
			#{
				$High =~ s/$UniqueTests{$Test}\t/$UniqueTests{$Test}_VHIGH\t/g;
				$P10_Tests .= $High;
				#print "$High";

				$Low =~ s/$UniqueTests{$Test}\t/$UniqueTests{$Test}_VLOW\t/g;
				$M10_Tests .= $Low;
				#print "$Low";
			#}
			#else
			#{
			#	$High =~ s/$UniqueTests{$Test}/$UniqueTests{$Test}_HIGH_P7/g;
			#	$P7_Tests .= $High;
			#	#print "$High";

			#	$Low =~ s/$UniqueTests{$Test}/$UniqueTests{$Test}_LOW_M7/g;
			#	$M7_Tests .= $Low;
				#print "$Low";
			#}

			last;
		}
	}
}

my $CharTIFile = "TI_CHAR.txt";
open (CHARFILE, ">$CharTIFile") || die "Cant open $CharTIFile : $! \n";
print CHARFILE $Header;
#print CHARFILE $MinCond;
#print CHARFILE $MaxCond;
#print CHARFILE $NomCond;
#print CHARFILE $HighCond;
#print CHARFILE $LowCond;
print CHARFILE $MIN_Tests;
print CHARFILE $MAX_Tests;
print CHARFILE $NOM_Tests;
print CHARFILE $P7_Tests;
print CHARFILE $M7_Tests;
print CHARFILE $P10_Tests;
print CHARFILE $M10_Tests;
close CHARFILE;



################################################ Below are seldom change ################################################################################################
my $CharFlowHeader = "DTFlowtableSheet,version=2.3:platform=Jaguar:toprow=-1:leftcol=-1:rightcol=-1	Flow Table																																							
						Flow Domain:																																		
			Gate			Command				Limits		Datalog Display Results			Bin Number		Sort Number			Action			Group				Device			Debug		CT Profile Data								
	Label	Enable	Job	Part	Env	Opcode	Parameter	TName	TNum	LoLim	HiLim	Scale	Units	Format	Pass	Fail	Pass	Fail	Result	Pass	Fail	State	Specifier	Sense	Condition	Name	Sense	Condition	Name	Assume	Sites	Elapsed Time (s)	Background Type	Serialize	Resource Lock	Flow Step Locked	Comment	Bin Name	Sort Name	";

my $NomFlowCond = "		CHAR				Test	Set_VDD_COND_CHAR_VNOM																																	";
my $MinFlowCond = "		CHAR				Test	Set_VDD_COND_CHAR_VMIN																																	";
my $MaxFlowCond = "		CHAR				Test	Set_VDD_COND_CHAR_VMAX																																	";
my $HighFlowCond = "		CHAR				Test	Set_VDD_COND_CHAR_VHIGH																																	";
my $LowFlowCond = "		CHAR				Test	Set_VDD_COND_CHAR_VLOW																																	";
my $Template = "		CHAR				Test	YYYYY									$HDBin		ZZZZZ	fail															FALSE		FALSE";

my $Return = "						return																														";

my $Count = $Firstdigit . "600";
print "$CharFlowHeader\n";
print "$MaxFlowCond\n";
foreach my $Test (sort {$a cmp $b} keys %UniqueTests)
{
	my $SoftBin = sprintf("%04d", $Count); 
	my $Temp =  $Template;
	$Temp =~ s/YYYYY/$UniqueTests{$Test}/ig;
	#$Temp =~ s/YYYYY/$UniqueTests{$Test}_VMAX/ig;
	$Temp =~ s/ZZZZZ/$SoftBin/ig;
	print "$Temp\n";
	$Count += 1;
	#print "$UniqueTests{$Test}";
}

$Count = $Firstdigit . "650";
print "$HighFlowCond\n";
foreach my $Test (sort {$a cmp $b} keys %UniqueTests)
{
	my $SoftBin = sprintf("%04d", $Count); 
	my $Temp =  $Template;
	$Temp =~ s/YYYYY/$UniqueTests{$Test}/ig;
	#$Temp =~ s/YYYYY/$UniqueTests{$Test}_VHIGH/ig;
	$Temp =~ s/ZZZZZ/$SoftBin/ig;
	print "$Temp\n";
	$Count += 1;
	#print "$UniqueTests{$Test}";
}

$Count = $Firstdigit . "700";
print "$NomFlowCond\n";
foreach my $Test (sort {$a cmp $b} keys %UniqueTests)
{
	my $SoftBin = sprintf("%04d", $Count); 
	my $Temp =  $Template;
	$Temp =~ s/YYYYY/$UniqueTests{$Test}/ig;
	#$Temp =~ s/YYYYY/$UniqueTests{$Test}_VNOM/ig;
	$Temp =~ s/ZZZZZ/$SoftBin/ig;
	print "$Temp\n";
	$Count += 1;
	#print "$UniqueTests{$Test}";
}

$Count = $Firstdigit . "750";
print "$LowFlowCond\n";
foreach my $Test (sort {$a cmp $b} keys %UniqueTests)
{
	my $SoftBin = sprintf("%04d", $Count); 
	my $Temp =  $Template;
	$Temp =~ s/YYYYY/$UniqueTests{$Test}/ig;
	#$Temp =~ s/YYYYY/$UniqueTests{$Test}_VLOW/ig;
	$Temp =~ s/ZZZZZ/$SoftBin/ig;
	print "$Temp\n";
	$Count += 1;
	#print "$UniqueTests{$Test}";
}

$Count = $Firstdigit . "800";
print "$MinFlowCond\n";
foreach my $Test (sort {$a cmp $b} keys %UniqueTests)
{
	my $SoftBin = sprintf("%04d", $Count); 
	my $Temp =  $Template;
	$Temp =~ s/YYYYY/$UniqueTests{$Test}/ig;
	#$Temp =~ s/YYYYY/$UniqueTests{$Test}_VMIN/ig;
	$Temp =~ s/ZZZZZ/$SoftBin/ig;
	print "$Temp\n";
	$Count += 1;
	#print "$UniqueTests{$Test}";
}

print "$Return\n";


