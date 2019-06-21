# Written by Lye Cheung Foo
# Script to pull pgm_rules from TP to check for the setup
# Date: 21 February 2012
# Rev0.1
use strict;
use warnings;

use Cwd;
use Getopt::Std;
use File::Find;
use File::Copy;

# Globals
my @Files = ();
my %Modules = ();
my $Module = "";
my $CurrentDirectory =  getcwd;
my $ConfigFile = $CurrentDirectory . '/configuration.txt';
my $OutCSV = $CurrentDirectory . '/All_pgm_rules.csv';
my ($TPPath) = &ReadConfiguration();
die "TP path token can't found in configuration.txt\n" if ($TPPath eq "");
&Main();

# Main subroutine 
sub Main
{
	finddepth(\&GetPGMRules, $TPPath);
	die "No pgm rules file found, check your tp path setup!\n" if (($#Files == -1) || ($#Files == 0));

	foreach my $PGMRuleFile (@Files)
	{
		#print "File: $PGMRuleFile\n";
		if ($PGMRuleFile =~ /Base\/Base_Input_Files\S+overwrite\S+/g)
		{
			$Module = "Base_overwrite";
		}
		elsif ($PGMRuleFile =~ /Base\/Base_Input_Files/g)
		{
			$Module = "Base";
		}
		elsif ($PGMRuleFile =~ /\/Modules\/(\w+)\//ig)
		{
			$Module = $1;
		}

		open (PGMRULES, $PGMRuleFile) || die "Cant open file $PGMRuleFile : $!\n";
		{
			while (<PGMRULES>)
			{
				chomp;
				next if ((/^\s*$/) || (/^\s*#/));
				if (/(Global)/)
				{
					#cold_loc = 0,         Global, _UserVars                :*,*,*,*,*,*,*,*,*,*,*,*,7721
					my $Temp = $1 if ((/\s*(.*)\s*#/) || (/\s*(.*)\s*/));
					my @Columns = split (/[=,:]/, $Temp, 5);
					$Columns[0] =~ s/\s*//ig;
					$Columns[1] =~ s/^\s*(.+)\s*$/$1/ig;
					$Columns[2] =~ s/\s*//ig;
					$Columns[3] =~ s/\s*//ig;
					$Columns[4] =~ s/\s*//ig;
					my $UserVarType = $Columns[2]; 
					my $Unique = "$Columns[0]_$Columns[1]_$Columns[2]_$Columns[3]";
					$Modules{$Module}{$UserVarType}{$Unique} = [$Columns[0], $Columns[1], $Columns[3], $Columns[4]];
				}
				elsif (/(Template|Levels|Timing)/)
				{
					#manual_measure_range = "2uA"         	,Template	,LEAKAGE::Leakage_HI_dvo	         :*,*,*,*,*,*,*,*,*,*,*,*,7731
					#postinstance = "IDT.dll!DFF_GSDS GET_DFF^CR_DI-PKG-PBIC_S1+TOGSDS_HEXTOBIN^GSDS_CR_DI_BINARY-UNT,SET_GSDS^GSDS_TD_DI_BINARY-0000000000000000000000000000000000000000000000000000000000000000-UNT",	Template, FUSE::DFFByULT		:*,*,*,*,*,*,*,*,*,*,*,*,7751/7757
					my $Temp = $1 if ((/\s*(.*)\s*#/) || (/\s*(.*)\s*/));
					my @Columns = split (/[=,]/, $Temp, 4);
					$Columns[0] =~ s/\s*//ig;
					$Columns[1] =~ s/^\s*(.+)\s*$/$1/ig;
					$Columns[2] =~ s/\s*//ig;
					$Columns[3] =~ s/\s*//ig;
					my $UserVarType = $Columns[2]; 
					my ($ModuleName, $Setting) = ($1, $2) if ($Columns[3] =~ /(\w+::\w+)\s*:\s*(.*)\s*/);
					my $Unique = "$Columns[0]_$Columns[1]_$Columns[2]_$Columns[3]";
					$Modules{$Module}{$UserVarType}{$Unique} = [$Columns[0], $Columns[1], $ModuleName, $Setting, $Columns[4]];
					print "$Columns[0], $Columns[1], $ModuleName, $Setting, $Columns[4]\n";
				}
			}
		}
		close PGMRULES;
		last;
	}

	open (OUTCSV, ">$OutCSV") || die "Cant open csv for writing $OutCSV : $!\n";
	print OUTCSV "Module,Parameters,Value,Type,Global/Template/Timing/Levels,Package,SampleType,ProcessorFamily,MarketSegment,CacheSize,BinMatrix,VirtualFactory,Revision,Stepping,EngID,Fab,SSpec,Location\n";
	# LEGEND:
	# Field1 : Package
	# Field2 : SampleType
	# Field3 : ProcessorFamily 
	# Field4 : MarketSegment 
	# Field5 : CacheSize
	# Field6 : BinMatrix (a.k.a. DLCP category)
	# Field7 : VirtualFactory
	# Field8 : Revision
	# Field9 : Stepping
	# Field10: EngID
	# Field11: Fab  
	# Field12: SSpec
	# FieldLocn :
	foreach my $Module (sort {$a cmp $b} keys %Modules)
	{
		my $FinalColumn = "";
		foreach my $UserVarType (sort {$a cmp $b} keys %{$Modules{$Module}})
		{
			foreach my $UserVarValue (sort {$a cmp $b} keys %{$Modules{$Module}{$UserVarType}})
			{
				$FinalColumn = join(",", @{$Modules{$Module}{$UserVarType}{$UserVarValue}}[0], @{$Modules{$Module}{$UserVarType}{$UserVarValue}}[1], $UserVarType, @{$Modules{$Module}{$UserVarType}{$UserVarValue}}[2]); 
				print OUTCSV "$Module,$FinalColumn, @{$Modules{$Module}{$UserVarType}{$UserVarValue}}[3]\n";
			}
		}
	}
	close OUTCSV;
}

# Get pgm rules files
sub GetPGMRules
{
	if ((-f $File::Find::name) && ($File::Find::name =~ /\S*pgm\S*rules\S*.txt$/i))
	{
		my $File = $File::Find::name;
		$File =~ s/\\/\//g;
		push (@Files, $File);
	}
}


# Read configuration file
sub ReadConfiguration
{
	my ($TPPath) = ("");
	open (CONFIG, $ConfigFile) || die "Can't open $ConfigFile : $!\n";
	while (<CONFIG>)
	{
		chomp;
		s/\s*//g;
		next if (/#/);

		if (/TPPath=(\S+)/i)
		{
			$TPPath = $1;
			$TPPath =~ s/\\/\//g;
		}
	}
	close CONFIG;
	return ($TPPath);
}


