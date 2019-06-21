#################################################################################################################
#														#
#	Foo Lye Cheung					PG PDE CPU (TMM)					#
#	03 Jan 2008												#
#	604-2536452												#
#														#
#	This script is to change CorTeX revision before compile in .vcproj, .rc and _h_make			#
#	(Only for NHM Evergreen)										#
#														#
#	   													#
#	Rev 1.4													#
#														#
#	Changes:												#
#	09/08/2007												#
#	1. Added new mode TSS identified for TSS2.07 as it require library _USE_32BIT_TIME_T in the OASIS link	#
#	2. Added to support new NHM directory user function structure						#
#														#
#	10/26/2007												#
#	1. Added new mode TSS identified for TSS2.07B as it require library _USE_32BIT_TIME_T in the GEN link	#
#														#
#	11/16/2007												#
#	1. Added Supercede code directory structure								#
#														#
#	01/03/2008												#
#	1. Added handling .rc and _h_make file for revision naming						#
#														#
#################################################################################################################
use strict;
use warnings;

use Cwd;
use Getopt::Std;
use File::Find;
use File::Copy;

# Globals
my $Debug = 0;
my @Files = ();
my $CurrentDirectory =  getcwd;
my $ConfigFile = $CurrentDirectory . '/../configuration.txt';
my ($RootDir, $Revision, $TSS) = &ReadConfiguration();

die "Root directory and Revision token can't found in configuration.txt\n" if (($RootDir eq "") || ($Revision eq ""));

my $GENDir = $RootDir . '/GEN/' . $Revision . '/nhm/src/';
my $OASISDir = $RootDir . '/OASIS/' . $Revision . '/nhm/src/';
my $UFsDir = $RootDir . '/UFs/' . $Revision . '/nhm/';
$GENDir =~ s/\/\//\//g;
$OASISDir =~ s/\/\//\//g;
$UFsDir =~ s/\/\//\//g;

# Added to make modified the .rc file
my ($Major, $Minor, $Patch) =();
my ($GLN, $VTS, $GLNRev) = split ('_', $Revision);
if ($VTS =~ /^Rev(\d+)\.(\d+)\.(\d+)/)
{
	($Major, $Minor, $Patch) = ($1, $2, $3);
	#print "$Major, $Minor, $Patch";
}
else
{
	print "Greenlane format doesn't match - eg. GLN_Rev4.12.0_PG1.1\n";
	exit 0;
}

&Main();

# Main subroutine 
sub Main
{
	finddepth(\&GetVvprojFiles, $GENDir, $OASISDir, $UFsDir);

	die "No .vcproj file found, check your revision setup!\n" if (($#Files == -1) || ($#Files == 0));

	open (LOG, ">..\\logs\\PG_Evergreen_CorTeX_Rev.log") || die "Cant log : $!\n";
	foreach my $VcProjFile (@Files)
	{
		&ProcessVcProj($VcProjFile);
		print LOG "Overwrite $VcProjFile\n";
		#print "Overwrite $VcProjFile\n";
	}
	close LOG;
}

# Process all .vcproj file, change revision and environment
sub ProcessVcProj
{
	my $VcProjFile = shift;
	my $TmpVcProjFile = $VcProjFile . "_tmp";
	open (TMPVCPROJ, ">$TmpVcProjFile") || die "Cant open $TmpVcProjFile : $!\n";
	open (VCPROJ, $VcProjFile) || die "Cant open $VcProjFile : $!\n";
	while (<VCPROJ>)
	{
		if ($VcProjFile =~ /\/GEN\/\S+\.vcproj/)
		{
			if (/AdditionalIncludeDirectories=/ig)
			{
				$_ = '				AdditionalIncludeDirectories=".\;..\..\..\Supercede_code;..\..\..\code;..\code"';
				print TMPVCPROJ "$_\n";
			}
			elsif (/AdditionalLibraryDirectories=\S*lib_debug;/ig)
			{
				$_ = '				AdditionalLibraryDirectories=".\;..\..\..\Supercede_lib_debug;..\..\..\lib_debug;..\..\lib_debug"';
				print TMPVCPROJ "$_\n";
			}
			elsif (/AdditionalLibraryDirectories=\S*lib;/ig)
			{
				$_ = '				AdditionalLibraryDirectories=".\;..\..\..\Supercede_lib;..\..\..\lib;..\..\lib"';
				print TMPVCPROJ "$_\n";
			}
			elsif ((/OutputFile=\"..\\..\\..\\lib_debug\\/ig) ||(/ImportLibrary=\"..\\..\\..\\lib_debug\\/ig))
			{
				s/..\\..\\..\\lib_debug\\/..\\..\\lib_debug\\/i;
				print TMPVCPROJ "$_";
			}
			elsif ((/OutputFile=\"..\\..\\..\\lib\\/ig) ||(/ImportLibrary=\"..\\..\\..\\lib\\/ig))
			{
				s/..\\..\\..\\lib\\/..\\..\\lib\\/i;
				print TMPVCPROJ "$_";
			}
			# Reverse slash directory
			elsif ((/OutputFile=\"..\/..\/..\/lib_debug\//ig) ||(/ImportLibrary=\"..\/..\/..\/lib_debug\//ig))
			{
				s/..\/..\/..\/lib_debug\//..\/..\/lib_debug\//i;
				print TMPVCPROJ "$_";
			}
			elsif ((/OutputFile=\"..\/..\/..\/lib\//ig) ||(/ImportLibrary=\"..\/..\/..\/lib\//ig))
			{
				s/..\/..\/..\/lib\//..\/..\/lib\//i;
				print TMPVCPROJ "$_";
			}
			elsif (/ProgramDataBaseFileName=\S*\\(\w+elease\\\w+_int.pdb)/ig) 
			{
				$_ = '				ProgramDataBaseFileName="' . $1 . '"';
				print TMPVCPROJ "$_\n";
			}
			elsif (/ProgramDatabaseFile=\S*\\(\w+elease\\\w+.pdb)/ig)
			{
				$_ = '				ProgramDatabaseFile="'  . $1 . '"';
				print TMPVCPROJ "$_\n";
			}
			elsif (/ProgramDataBaseFileName=\S*\\(\w+ebug\\\w+_int.pdb)/ig) 
			{
				$_ = '				ProgramDataBaseFileName="' . $1 . '"';
				print TMPVCPROJ "$_\n";
			}
			elsif (/ProgramDatabaseFile=\S*\\(\w+ebug\\\w+.pdb)/ig)
			{
				$_ = '				ProgramDatabaseFile="'  . $1 . '"';
				print TMPVCPROJ "$_\n";
			}
			elsif (/ProgramDataBaseFileName=\S*\/(\w+elease\/\w+_int.pdb)/ig) 
			{

				$_ = '				ProgramDataBaseFileName="' . $1 . '"';
				print TMPVCPROJ "$_\n";
			}
			elsif (/ProgramDatabaseFile=\S*\/(\w+elease\/\w+.pdb)/ig)
			{
				$_ = '				ProgramDatabaseFile="'  . $1 . '"';
				print TMPVCPROJ "$_\n";
			}
			elsif (/ProgramDataBaseFileName=\S*\/(\w+ebug\/\w+_int.pdb)/ig) 
			{
				$_ = '				ProgramDataBaseFileName="' . $1 . '"';
				print TMPVCPROJ "$_\n";
			}
			elsif (/ProgramDatabaseFile=\S*\/(\w+ebug\/\w+.pdb)/ig)
			{
				$_ = '				ProgramDatabaseFile="'  . $1 . '"';
				print TMPVCPROJ "$_\n";
			}			
			elsif (/(PreprocessorDefinitions=\"\S+)\"/ig)
			{
				my $Tmp = $1;
				if ($Tmp !~ /_USE_32BIT_TIME_T/ig)
				{
					$_ = '				' . $Tmp . ';_USE_32BIT_TIME_T"' . "\n";
					#print "Found $_\n";
				}

				print TMPVCPROJ "$_";
				#print "Found $_\n";
			}
			else
			{
				print TMPVCPROJ "$_";
			}
		}
		elsif ($VcProjFile =~ /\/OASIS\/\S+\.vcproj/)
		{

			if (/AdditionalIncludeDirectories=/ig)
			{
				my $Tmp = '				AdditionalIncludeDirectories=".;';
				$Tmp .= "..\\..\\..\\..\\..\\GEN\\" . $Revision . "\\Supercede_code;..\\..\\..\\..\\..\\OASIS\\" . $Revision . "\\Supercede_code;";
				$Tmp .= "..\\..\\..\\..\\..\\GEN\\" . $Revision . "\\code;..\\..\\..\\..\\..\\OASIS\\" . $Revision . "\\code;";
				$Tmp .= "..\\..\\..\\..\\..\\GEN\\" . $Revision ."\\nhm\\src\\code;..\\code;";
				$Tmp .= '$(OASIS_INSTALLATION_ROOT)\UserSDK\src\OAI\ToolsSDK\FrameWork\STDProxy;$(OASIS_INSTALLATION_ROOT)\UserSDK\inc;$(OASIS_INSTALLATION_ROOT)\VendorSDK\inc;$(OASIS_INSTALLATION_ROOT)\UserSDK\inc\OAI;$(OASIS_INSTALLATION_ROOT)\UserSDK\inc\OAI\OFC;..\..\..\..\..\third_party\boost\boost_1_34_1"';

				$_ = $Tmp;
				print TMPVCPROJ "$_\n";
			}
			elsif (/AdditionalLibraryDirectories=\S*lib_debug;/ig)
			{
				my $Tmp = '				AdditionalLibraryDirectories=".\;';
				$Tmp .= "..\\..\\..\\..\\..\\GEN\\" . $Revision . "\\Supercede_lib_debug;..\\..\\..\\..\\..\\OASIS\\" . $Revision . "\\Supercede_lib_debug;";
				$Tmp .= "..\\..\\..\\..\\..\\GEN\\" . $Revision . "\\lib_debug;..\\..\\..\\..\\..\\OASIS\\" . $Revision . "\\lib_debug;";
				$Tmp .= "..\\..\\..\\..\\..\\GEN\\" . $Revision ."\\nhm\\lib_debug;..\\..\\lib_debug;";
				$Tmp .= '$(OASIS_INSTALLATION_ROOT)/UserSDK/lib/OAI;$(OASIS_INSTALLATION_ROOT)/VendorSDK/lib/OAI;$(OASIS_INSTALLATION_ROOT)/UserSDK/lib/AT;';
				$Tmp .= '..\..\..\..\..\third_party\boost\boost_1_34_1\lib"';
				$_ = $Tmp;

				print TMPVCPROJ "$_\n";
			}
			elsif (/AdditionalLibraryDirectories=\S*lib;/ig)
			{
				my $Tmp = '				AdditionalLibraryDirectories=".\;';
				$Tmp .= "..\\..\\..\\..\\..\\GEN\\" . $Revision . "\\Supercede_lib;..\\..\\..\\..\\..\\OASIS\\" . $Revision . "\\Supercede_lib;";
				$Tmp .= "..\\..\\..\\..\\..\\GEN\\" . $Revision . "\\lib;..\\..\\..\\..\\..\\OASIS\\" . $Revision . "\\lib;";
				$Tmp .= "..\\..\\..\\..\\..\\GEN\\" . $Revision ."\\nhm\\lib;..\\..\\lib;";
				$Tmp .= '$(OASIS_INSTALLATION_ROOT)/UserSDK/lib/OAI;$(OASIS_INSTALLATION_ROOT)/VendorSDK/lib/OAI;$(OASIS_INSTALLATION_ROOT)/UserSDK/lib/AT;';
				$Tmp .= '..\..\..\..\..\third_party\boost\boost_1_34_1\lib"';
				$_ = $Tmp;
				print TMPVCPROJ "$_\n";
			}
			elsif ((/OutputFile=\"..\\..\\..\\lib_debug\\/ig) ||(/ImportLibrary=\"..\\..\\..\\lib_debug\\/ig))
			{
				s/..\\..\\..\\lib_debug\\/..\\..\\lib_debug\\/i;
				print TMPVCPROJ "$_";
			}
			elsif ((/OutputFile=\"..\\..\\..\\lib\\/ig) ||(/ImportLibrary=\"..\\..\\..\\lib\\/ig))
			{
				s/..\\..\\..\\lib\\/..\\..\\lib\\/i;
				print TMPVCPROJ "$_";
			}
			# Reverse slash directory
			elsif ((/OutputFile=\"..\/..\/..\/lib_debug\//ig) ||(/ImportLibrary=\"..\/..\/..\/lib_debug\//ig))
			{
				s/..\/..\/..\/lib_debug\//..\/..\/lib_debug\//i;
				print TMPVCPROJ "$_";
			}
			elsif ((/OutputFile=\"..\/..\/..\/lib\//ig) ||(/ImportLibrary=\"..\/..\/..\/lib\//ig))
			{
				s/..\/..\/..\/lib\//..\/..\/lib\//i;
				print TMPVCPROJ "$_";
			}			
			elsif (/ProgramDataBaseFileName=\S*\\(\w+elease\\\w+_int.pdb)/ig) 
			{
				$_ = '				ProgramDataBaseFileName="' . $1 . '"';
				print TMPVCPROJ "$_\n";
			}
			elsif (/ProgramDatabaseFile=\S*\\(\w+elease\\\w+.pdb)/ig)
			{
				$_ = '				ProgramDatabaseFile="'  . $1 . '"';
				print TMPVCPROJ "$_\n";
			}
			elsif (/ProgramDataBaseFileName=\S*\\(\w+ebug\\\w+_int.pdb)/ig) 
			{
				$_ = '				ProgramDataBaseFileName="' . $1 . '"';
				print TMPVCPROJ "$_\n";
			}
			elsif (/ProgramDatabaseFile=\S*\\(\w+ebug\\\w+.pdb)/ig)
			{
				$_ = '				ProgramDatabaseFile="'  . $1 . '"';
				print TMPVCPROJ "$_\n";
			}
			elsif (/ProgramDataBaseFileName=\S*\/(\w+elease\/\w+_int.pdb)/ig) 
			{

				$_ = '				ProgramDataBaseFileName="' . $1 . '"';
				print TMPVCPROJ "$_\n";
			}
			elsif (/ProgramDatabaseFile=\S*\/(\w+elease\/\w+.pdb)/ig)
			{
				$_ = '				ProgramDatabaseFile="'  . $1 . '"';
				print TMPVCPROJ "$_\n";
			}
			elsif (/ProgramDataBaseFileName=\S*\/(\w+ebug\/\w+_int.pdb)/ig) 
			{
				$_ = '				ProgramDataBaseFileName="' . $1 . '"';
				print TMPVCPROJ "$_\n";
			}
			elsif (/ProgramDatabaseFile=\S*\/(\w+ebug\/\w+.pdb)/ig)
			{
				$_ = '				ProgramDatabaseFile="'  . $1 . '"';
				print TMPVCPROJ "$_\n";
			}
			elsif (/(PreprocessorDefinitions=\"\S+)\"/ig)
			{
				my $Tmp = $1;
				if ($Tmp !~ /_USE_32BIT_TIME_T/ig)
				{
					$_ = '				' . $Tmp . ';_USE_32BIT_TIME_T"' . "\n";
					#print "Found $_\n";
				}

				print TMPVCPROJ "$_";
				#print "Found $_\n";
			}
			else
			{
				print TMPVCPROJ "$_";
			}
		}
		# Added to change to correct revision for makefile
		elsif ($VcProjFile =~ /\/OASIS\/\S+_h_make/)
		{
			chomp;
			if (/OASIS_INSTALLATION_ROOT/ig)
			{
				$_ = '    "$(OASIS_INSTALLATION_ROOT)\bin\OAI_occ.exe" -t ..\..\..\..\..\OASIS\\' . $Revision . '\templates -i ..\..\..\..\..\OASIS\\' . $Revision . '\templates -np $**  -o .';
			}
			print TMPVCPROJ "$_\n";
		}
		# Added to change to correct revision for .rc file
		elsif (($VcProjFile =~ /\/GEN\/\S+\.rc/) || ($VcProjFile =~ /\/OASIS\/\S+\.rc/))
		{
			#FILEVERSION 4,10,0
			#PRODUCTVERSION 4,10,0
			#VALUE "Comments", "OASIS Release Rev4.10.0"    
			#VALUE "FileVersion", "4,10,0"
			#VALUE "ProductVersion", "Rev4.10.0"
			chomp;
			if (/FILEVERSION/g)
			{
				$_ = " FILEVERSION ${Major},${Minor},${Patch}";
			}
			elsif (/PRODUCTVERSION/g)
			{
				$_ = " PRODUCTVERSION ${Major},${Minor},${Patch}";
			}
			elsif (/OASIS\s*Release/ig)
			{
				$_ = "            VALUE \"Comments\", \"OASIS Release Rev${Major}.${Minor}.${Patch}\"";
			}
			elsif (/FileVersion/g)
			{
				$_ = "            VALUE \"FileVersion\", \"${Major},${Minor},${Patch}\"";
			}
			elsif (/ProductVersion/g)
			{
				$_ = "            VALUE \"ProductVersion\", \"Rev${Major}.${Minor}.${Patch}\"";
			}

			print TMPVCPROJ "$_\n";
		}
		elsif ($VcProjFile =~ /\/UFs\//)
		{

			if (/AdditionalIncludeDirectories=/ig)
			{
				my $Tmp = '				AdditionalIncludeDirectories=".;';
				$Tmp .= "..\\..\\GEN\\Code;..\\..\\..\\..\\GEN\\" . $Revision . "\\Supercede_code;..\\..\\..\\..\\OASIS\\" . $Revision . "\\Supercede_code;";
				$Tmp .= "..\\..\\..\\..\\GEN\\" . $Revision . "\\nhm\\src\\code;..\\..\\..\\..\\OASIS\\" . $Revision . "\\nhm\\src\\code;";
				$Tmp .= "..\\..\\GEN\\Code;..\\..\\..\\..\\GEN\\" . $Revision . "\\code;..\\..\\..\\..\\OASIS\\" . $Revision . "\\code;";
				$Tmp .= '$(OASIS_INSTALLATION_ROOT)\UserSDK\inc\OAI\proxy;$(OASIS_INSTALLATION_ROOT)\UserSDK\inc;$(OASIS_INSTALLATION_ROOT)\UserSDK\inc\OAI;$(OASIS_INSTALLATION_ROOT)\UserSDK\inc\OAI\OFC;$(OASIS_INSTALLATION_ROOT)\UserSDK\inc\OAI\core;$(OASIS_INSTALLATION_ROOT)\VendorSDK\inc"';

				$_ = $Tmp;
				print TMPVCPROJ "$_\n";
			}
			elsif (/AdditionalLibraryDirectories=\S*lib_debug;/ig)
			{
				my $Tmp = '				AdditionalLibraryDirectories=".\;';
				$Tmp .=	"..\\..\\..\\lib_debug;..\\..\\..\\..\\GEN\\" .  $Revision . "\\Supercede_lib_debug;..\\..\\..\\..\\OASIS\\" .  $Revision . "\\Supercede_lib_debug;";
				$Tmp .= "..\\..\\..\\..\\GEN\\" . $Revision . "\\nhm\\lib_debug;..\\..\\..\\..\\OASIS\\" . $Revision . "\\nhm\\lib_debug;";
				$Tmp .=	"..\\..\\..\\lib_debug;..\\..\\..\\..\\GEN\\" .  $Revision . "\\lib_debug;..\\..\\..\\..\\OASIS\\" .  $Revision . "\\lib_debug;";
				$Tmp .= '$(OASIS_INSTALLATION_ROOT)/UserSDK/lib/OAI;$(OASIS_INSTALLATION_ROOT)/VendorSDK/lib/OAI;$(OASIS_INSTALLATION_ROOT)/UserSDK/lib/AT"';
				$_ = $Tmp;

				print TMPVCPROJ "$_\n";
			}
			elsif (/AdditionalLibraryDirectories=\S*lib;/ig)
			{
				my $Tmp = '				AdditionalLibraryDirectories=".\;';
				$Tmp .=	"..\\..\\..\\Supercede_lib;..\\..\\..\\..\\GEN\\" .  $Revision . "\\Supercede_lib;..\\..\\..\\..\\OASIS\\" .  $Revision . "\\Supercede_lib;";
				$Tmp .= "..\\..\\..\\..\\GEN\\" . $Revision . "\\nhm\\lib;..\\..\\..\\..\\OASIS\\" . $Revision . "\\nhm\\lib;";
				$Tmp .=	"..\\..\\..\\lib;..\\..\\..\\..\\GEN\\" .  $Revision . "\\lib;..\\..\\..\\..\\OASIS\\" .  $Revision . "\\lib;";
				$Tmp .= '$(OASIS_INSTALLATION_ROOT)/UserSDK/lib/OAI;$(OASIS_INSTALLATION_ROOT)/VendorSDK/lib/OAI;$(OASIS_INSTALLATION_ROOT)/UserSDK/lib/AT"';
				$_ = $Tmp;
				
				print TMPVCPROJ "$_\n";
			}
			elsif ((/OutputFile=\"..\\..\\lib_debug\\/ig) ||(/ImportLibrary=\"..\\..\\lib_debug\\/ig))
			{
				s/..\\..\\lib_debug\\/..\\lib_debug\\/i;
				print TMPVCPROJ "$_";
			}
			elsif ((/OutputFile=\"..\\..\\lib\\/ig) ||(/ImportLibrary=\"..\\..\\lib\\/ig))
			{
				s/..\\..\\lib\\/..\\lib\\/i;
				print TMPVCPROJ "$_";
			}
			# Reverse slash directory
			elsif ((/OutputFile=\"..\/..\/lib_debug\//ig) ||(/ImportLibrary=\"..\/..\/lib_debug\//ig))
			{
				s/..\/..\/lib_debug\//..\/lib_debug\//i;
				print TMPVCPROJ "$_";
			}
			elsif ((/OutputFile=\"..\/..\/lib\//ig) ||(/ImportLibrary=\"..\/..\/lib\//ig))
			{
				s/..\/..\/lib\//..\/lib\//i;
				print TMPVCPROJ "$_";
			}
			elsif (/ProgramDataBaseFileName=\S*\\(\w+elease\\\w+_int.pdb)/ig) 
			{
				$_ = '				ProgramDataBaseFileName="' . $1 . '"';
				print TMPVCPROJ "$_\n";
			}
			elsif (/ProgramDatabaseFile=\S*\\(\w+elease\\\w+.pdb)/ig)
			{
				$_ = '				ProgramDatabaseFile="'  . $1 . '"';
				print TMPVCPROJ "$_\n";
			}
			elsif (/ProgramDataBaseFileName=\S*\\(\w+ebug\\\w+_int.pdb)/ig) 
			{
				$_ = '				ProgramDataBaseFileName="' . $1 . '"';
				print TMPVCPROJ "$_\n";
			}
			elsif (/ProgramDatabaseFile=\S*\\(\w+ebug\\\w+.pdb)/ig)
			{
				$_ = '				ProgramDatabaseFile="'  . $1 . '"';
				print TMPVCPROJ "$_\n";
			}
			elsif (/ProgramDataBaseFileName=\S*\/(\w+elease\/\w+_int.pdb)/ig) 
			{

				$_ = '				ProgramDataBaseFileName="' . $1 . '"';
				print TMPVCPROJ "$_\n";
			}
			elsif (/ProgramDatabaseFile=\S*\/(\w+elease\/\w+.pdb)/ig)
			{
				$_ = '				ProgramDatabaseFile="'  . $1 . '"';
				print TMPVCPROJ "$_\n";
			}
			elsif (/ProgramDataBaseFileName=\S*\/(\w+ebug\/\w+_int.pdb)/ig) 
			{
				$_ = '				ProgramDataBaseFileName="' . $1 . '"';
				print TMPVCPROJ "$_\n";
			}
			elsif (/ProgramDatabaseFile=\S*\/(\w+ebug\/\w+.pdb)/ig)
			{
				$_ = '				ProgramDatabaseFile="'  . $1 . '"';
				print TMPVCPROJ "$_\n";
			}
			else
			{
				print TMPVCPROJ "$_";
			}
		}
	}
	close VCPROJ;	
	close TMPVCPROJ;

	#copy ($TmpVcProjFile, $VcProjFile) or die "Cant copy from $TmpVcProjFile to $VcProjFile - failed: $!";
	move ($TmpVcProjFile, $VcProjFile) or die "Cant copy from $TmpVcProjFile to $VcProjFile - failed: $!";
}

# Get all the .vcproj, _h_make and .rc files
sub GetVvprojFiles
{
	if ((-f $File::Find::name) && (($File::Find::name =~ /\.vcproj$/i) || ($File::Find::name =~ /_h_make$/i) || ($File::Find::name =~ /\.rc$/i)))
	{
		my $File = $File::Find::name;
		$File =~ s/\\/\//g;
		print "Found $File\n" if ($Debug == 1);
		push (@Files, $File);
	}
}

# Read configuration file
sub ReadConfiguration
{
	my ($RootDir, $Revision, $TSS) = ("", "", "");

	open (CONFIG, $ConfigFile) || die "Can't open $ConfigFile : $!\n";
	while (<CONFIG>)
	{
		chomp;
		s/\s*//g;
		next if (/#/);

		if (/Root=(\S+)/i)
		{
			$RootDir = $1;
			$RootDir =~ s/\\/\//g;
		}
		elsif (/Revision=(\S+)/i)
		{
			$Revision = $1;
		}
		elsif (/TSS=(\S+)/i)
		{
			$TSS = $1;
		}

	}
	close CONFIG;

	return ($RootDir, $Revision, $TSS);
}
