#################################################################################################################
#														#
#	Foo Lye Cheung					PG PDE CPU (TMM)					#
#	03 Jan 2008												#
#	604-2536452												#
#														#
#	This script is to change CorTeX revision before compile in .vcproj, _h_make and .rc			#
#	for Greenlane GEN, OASIS and UFs									#
#														#
#	Rev 1.4													#
#	   													#
#	Changes:												#
#	11/16/2007												#
#	1. Created to build the supercede code									#
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
my ($RootDir, $Revision) = &ReadConfiguration();

die "Root directory and Revision token can't found in configuration.txt\n" if (($RootDir eq "") || ($Revision eq ""));

my $GENCodeDir = $RootDir . '/GEN/' . $Revision . '/Supercede_code';
my $GENTemplatesDir = $RootDir . '/GEN/' . $Revision . '/Supercede_templates';
my $OASISCodeDir = $RootDir . '/OASIS/' . $Revision . '/Supercede_code';
my $OASISTemplatesDir = $RootDir . '/OASIS/' . $Revision . '/Supercede_templates';
my $UFsDir = $RootDir . '/UFs/' . $Revision . '/src';
$GENCodeDir =~ s/\/\//\//g;
$GENTemplatesDir =~ s/\/\//\//g;
$OASISCodeDir =~ s/\/\//\//g;
$OASISTemplatesDir =~ s/\/\//\//g;
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
	finddepth(\&GetVvprojFiles, $GENCodeDir, $GENTemplatesDir, $OASISCodeDir, $OASISTemplatesDir, $UFsDir);

	die "No .vcproj file found, check your revision setup!\n" if (($#Files == -1) || ($#Files == 0));

	open (LOG, ">..\\logs\\PG_CorTeX_Rev.log") || die "Cant log : $!\n";
	foreach my $VcProjFile (@Files)
	{
		&ProcessVcProj($VcProjFile);
		print LOG "Overwrite $VcProjFile\n";
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
		if ($VcProjFile =~ /\/UFs\/\S+\/src\//)
		{
			if (/AdditionalIncludeDirectories=/ig)
			{
				my $Tmp = '				AdditionalIncludeDirectories=".\;';
				$Tmp .= "..\\..\\..\\GEN\\" . $Revision . "\\Supercede_code;..\\..\\..\\OASIS\\" . $Revision . "\\Supercede_code;";
				$Tmp .= "..\\GEN\\Code;..\\..\\..\\GEN\\" . $Revision . "\\code;..\\..\\..\\OASIS\\" . $Revision . "\\code;";				
				$Tmp .= "..\\..\\..\\GEN\\" . $Revision . "\\nhm\\src\\code;..\\..\\..\\OASIS\\" . $Revision . "\\nhm\\src\\code;";
				$Tmp .= '$(OASIS_INSTALLATION_ROOT)\UserSDK\src\OAI\ToolsSDK\FrameWork\STDProxy;$(OASIS_INSTALLATION_ROOT)\UserSDK\inc\OAI\proxy;$(OASIS_INSTALLATION_ROOT)\UserSDK\inc;$(OASIS_INSTALLATION_ROOT)\UserSDK\inc\OAI;$(OASIS_INSTALLATION_ROOT)\UserSDK\inc\OAI\OFC;$(OASIS_INSTALLATION_ROOT)\UserSDK\inc\OAI\core;$(OASIS_INSTALLATION_ROOT)\VendorSDK\inc"';

				$_ = $Tmp;
				print TMPVCPROJ "$_\n";
			}
			elsif (/AdditionalLibraryDirectories=\S*lib_debug;/ig)
			{
				my $Tmp = '				AdditionalLibraryDirectories=".\;';
				$Tmp .= "..\\..\\..\\GEN\\" . $Revision . "\\Supercede_lib_debug;..\\..\\..\\OASIS\\" . $Revision . "\\Supercede_lib_debug;";
				$Tmp .=	"..\\..\\lib_debug;..\\..\\..\\GEN\\" .  $Revision . "\\lib_debug;..\\..\\..\\OASIS\\" .  $Revision . "\\lib_debug;";
				$Tmp .= "..\\..\\..\\GEN\\" . $Revision . "\\nhm\\lib_debug;..\\..\\OASIS\\" . $Revision . "\\nhm\\lib_debug;";
				$Tmp .= '$(OASIS_INSTALLATION_ROOT)/UserSDK/lib/OAI;$(OASIS_INSTALLATION_ROOT)/VendorSDK/lib/OAI;$(OASIS_INSTALLATION_ROOT)/UserSDK/lib/AT"';

				$_ = $Tmp;
				print TMPVCPROJ "$_\n";
			}
			elsif (/AdditionalLibraryDirectories=\S*lib;/ig)
			{
				my $Tmp = '				AdditionalLibraryDirectories=".\;';
				$Tmp .= "..\\..\\..\\GEN\\" . $Revision . "\\Supercede_lib;..\\..\\..\\OASIS\\" . $Revision . "\\Supercede_lib;";
				$Tmp .=	"..\\..\\lib;..\\..\\..\\GEN\\" .  $Revision . "\\lib;..\\..\\..\\OASIS\\" .  $Revision . "\\lib;";
				$Tmp .= "..\\..\\..\\GEN\\" . $Revision . "\\nhm\\lib;..\\..\\..\\OASIS\\" . $Revision . "\\nhm\\lib;";
				$Tmp .= '$(OASIS_INSTALLATION_ROOT)/UserSDK/lib/OAI;$(OASIS_INSTALLATION_ROOT)/VendorSDK/lib/OAI;$(OASIS_INSTALLATION_ROOT)/UserSDK/lib/AT"';

				$_ = $Tmp;
				print TMPVCPROJ "$_\n";
			}
			elsif (/PreprocessorDefinitions=\S+;(\w+_DLL__)/ig)
			{
				my $UFDLL = $1;
                                my $Tmp = "				PreprocessorDefinitions=\"WIN32;NDEBUG;_LIB;_WINDOWS;_USRDLL;CODE_EXPORTS;_CRT_SECURE_NO_DEPRECATE;";
				$Tmp .= "_SECURE_SCL;_SECURE_SCL_THROWS;HAVE_STRING_H;REGEX_MALLOC;__STDC__;STDC_HEADERS;";
				$Tmp .= "_USE_32BIT_TIME_T;_DMEM_VER=41100;_DFF_VER=41100;_FUSE_PNUMCIPHER=41100;_TSS_VER=20700;_VER_CTX=41100;";
				$Tmp .= "$UFDLL";
			       	$Tmp .= "\"";
				
				$_ = $Tmp;
				print TMPVCPROJ "$_\n";
			}
			else
			{
				print TMPVCPROJ "$_";
			}			
		}
		elsif ($VcProjFile =~ /\/GEN\/\S+\/Supercede_code\/\S+\.vcproj/)
		{
			if (/AdditionalIncludeDirectories=/ig)
			{
				my $Tmp = '				AdditionalIncludeDirectories="';
				$Tmp .= "..\\Supercede_code;";
				$Tmp .= '.\;';
				$Tmp .= "..\\nhm\\src\\code;";
				$Tmp .= "..\\third_party\\xmlParser;..\\third_party\\xerces-c\\include;..\\third_party\\RSA_DataSecurity_MD5;\"";

				$_ = $Tmp;
				print TMPVCPROJ "$_\n";
			}
			elsif (/AdditionalLibraryDirectories=\S*lib_debug;/ig)
			{
				my $Tmp = '				AdditionalLibraryDirectories="';
				$Tmp .= "..\\Supercede_lib_debug;";
				$Tmp .= '.\;';
				$Tmp .= "..\\lib_debug;";
				$Tmp .= "..\\nhm\\lib_debug;";
				$Tmp .= "..\\third_party\\xerces-c\\lib;\"";

				$_ = $Tmp;
				print TMPVCPROJ "$_\n";
			}
			elsif (/AdditionalLibraryDirectories=\S*lib;/ig)
			{
				my $Tmp = '				AdditionalLibraryDirectories="';
				$Tmp .= "..\\Supercede_lib;";
				$Tmp .= '.\;';
				$Tmp .= "..\\lib;";
				$Tmp .= "..\\nhm\\lib;";
				$Tmp .= "..\\third_party\\xerces-c\\lib;\"";

				$_ = $Tmp;
				print TMPVCPROJ "$_\n";
			}
			elsif ((/OutputFile=\"\S+\\lib_debug\\/ig) ||(/ImportLibrary=\"\S+\\lib_debug\\/ig))
			{
				s/..\\..\\..\\lib_debug\\/..\\Supercede_lib_debug\\/i;
				s/..\\..\\lib_debug\\/..\\Supercede_lib_debug\\/i;
				s/..\\lib_debug\\/..\\Supercede_lib_debug\\/i;
				print TMPVCPROJ "$_";
			}
			elsif ((/OutputFile=\"\S+\\lib\\/ig) ||(/ImportLibrary=\"\S+\\lib\\/ig))
			{
				s/..\\..\\..\\lib\\/..\\Supercede_lib\\/i;
				s/..\\..\\lib\\/..\\Supercede_lib\\/i;
				s/..\\lib\\/..\\Supercede_lib\\/i;
				print TMPVCPROJ "$_";
			}
			elsif ((/OutputFile=\"\S+\/lib_debug\//ig) || (/ImportLibrary=\"\S+\/lib_debug\//ig))
			{
				s/..\\..\\..\\lib_debug\\/..\\Supercede_lib_debug\\/i;
				s/..\\..\\lib_debug\\/..\\Supercede_lib_debug\\/i;
				s/..\\lib_debug\\/..\\Supercede_lib_debug\\/i;
				print TMPVCPROJ "$_";
			}
			elsif ((/OutputFile=\"\S+\/lib\//ig) || (/ImportLibrary=\"\S+\/lib\//ig))
			{
				s/..\\..\\..\\lib\\/..\\Supercede_lib\\/i;
				s/..\\..\\lib\\/..\\Supercede_lib\\/i;
				s/..\\lib\\/..\\Supercede_lib\\/i;
				print TMPVCPROJ "$_";
			}
			else
			{
				print TMPVCPROJ "$_";
			}
		}
		elsif ($VcProjFile =~ /\/GEN\/\S+\/Supercede_templates\/\S+\.vcproj/)
		{
			if (/AdditionalIncludeDirectories=/ig)
			{
				my $Tmp = '				AdditionalIncludeDirectories=".\;';
				$Tmp .= "..\\Supercede_code;";
				$Tmp .= "..\\code;";
				$Tmp .= "..\\nhm\\src\\code;";
				$Tmp .= '..\\..\\code"';

				$_ = $Tmp;
				print TMPVCPROJ "$_\n";
			}
			elsif (/AdditionalLibraryDirectories=\S*lib_debug;/ig)
			{
				my $Tmp = '				AdditionalLibraryDirectories=".\;';
				$Tmp .= "..\\Supercede_lib_debug;";
				$Tmp .= "..\\lib_debug;";
				$Tmp .= "..\\nhm\\lib_debug;\"";

				$_ = $Tmp;
				print TMPVCPROJ "$_\n";
			}
			elsif (/AdditionalLibraryDirectories=\S*lib;/ig)
			{
				my $Tmp = '				AdditionalLibraryDirectories=".\;';
				$Tmp .= "..\\Supercede_lib;";
				$Tmp .= "..\\lib;";
				$Tmp .= "..\\nhm\\lib;\"";
			
				$_ = $Tmp;
				print TMPVCPROJ "$_\n";
			}
			elsif ((/OutputFile=\"\S+\\lib_debug\\/ig) ||(/ImportLibrary=\"\S+\\lib_debug\\/ig))
			{
				s/..\\..\\..\\lib_debug\\/..\\Supercede_lib_debug\\/i;
				s/..\\..\\lib_debug\\/..\\Supercede_lib_debug\\/i;
				s/..\\lib_debug\\/..\\Supercede_lib_debug\\/i;
				print TMPVCPROJ "$_";
			}
			elsif ((/OutputFile=\"\S+\\lib\\/ig) ||(/ImportLibrary=\"\S+\\lib\\/ig))
			{
				s/..\\..\\..\\lib\\/..\\Supercede_lib\\/i;
				s/..\\..\\lib\\/..\\Supercede_lib\\/i;
				s/..\\lib\\/..\\Supercede_lib\\/i;
				print TMPVCPROJ "$_";
			}
			elsif ((/OutputFile=\"\S+\/lib_debug\//ig) || (/ImportLibrary=\"\S+\/lib_debug\//ig))
			{
				s/..\\..\\..\\lib_debug\\/..\\Supercede_lib_debug\\/i;
				s/..\\..\\lib_debug\\/..\\Supercede_lib_debug\\/i;
				s/..\\lib_debug\\/..\\Supercede_lib_debug\\/i;
				print TMPVCPROJ "$_";
			}
			elsif ((/OutputFile=\"\S+\/lib\//ig) || (/ImportLibrary=\"\S+\/lib\//ig))
			{
				s/..\\..\\..\\lib\\/..\\Supercede_lib\\/i;
				s/..\\..\\lib\\/..\\Supercede_lib\\/i;
				s/..\\lib\\/..\\Supercede_lib\\/i;
				print TMPVCPROJ "$_";
			}
			else
			{
				print TMPVCPROJ "$_";
			}
		}
		elsif ($VcProjFile =~ /\/OASIS\/\S+\/Supercede_code\/\S+\.vcproj/)
		{
			if (/AdditionalIncludeDirectories=/ig)
			{
				my $Tmp = '				AdditionalIncludeDirectories=".\;';
				$Tmp .= "..\\..\\..\\GEN\\" . $Revision . "\\Supercede_code;..\\..\\..\\OASIS\\" . $Revision . "\\Supercede_code;";
				$Tmp .= "..\\GEN\\Code;..\\..\\..\\GEN\\" . $Revision . "\\code;..\\..\\..\\OASIS\\" . $Revision . "\\code;";				
				$Tmp .= "..\\..\\..\\GEN\\" . $Revision . "\\nhm\\src\\code;..\\..\\..\\OASIS\\" . $Revision . "\\nhm\\src\\code;";
				$Tmp .= '$(OASIS_INSTALLATION_ROOT)\UserSDK\src\OAI\ToolsSDK\FrameWork\STDProxy;$(OASIS_INSTALLATION_ROOT)\UserSDK\inc\OAI\proxy;$(OASIS_INSTALLATION_ROOT)\UserSDK\inc;$(OASIS_INSTALLATION_ROOT)\UserSDK\inc\OAI;$(OASIS_INSTALLATION_ROOT)\UserSDK\inc\OAI\OFC;$(OASIS_INSTALLATION_ROOT)\UserSDK\inc\OAI\core;$(OASIS_INSTALLATION_ROOT)\VendorSDK\inc"';

				$_ = $Tmp;
				print TMPVCPROJ "$_\n";
			}
			elsif (/AdditionalLibraryDirectories=\S*lib_debug;/ig)
			{
				my $Tmp = '				AdditionalLibraryDirectories=".\;';
				$Tmp .= "..\\..\\..\\GEN\\" . $Revision . "\\Supercede_lib_debug;..\\..\\..\\OASIS\\" . $Revision . "\\Supercede_lib_debug;";
				$Tmp .=	"..\\..\\lib_debug;..\\..\\..\\GEN\\" .  $Revision . "\\lib_debug;..\\..\\..\\OASIS\\" .  $Revision . "\\lib_debug;";
				$Tmp .= "..\\..\\..\\GEN\\" . $Revision . "\\nhm\\lib_debug;..\\..\\OASIS\\" . $Revision . "\\nhm\\lib_debug;";
				$Tmp .= '$(OASIS_INSTALLATION_ROOT)/UserSDK/lib/OAI;$(OASIS_INSTALLATION_ROOT)/VendorSDK/lib/OAI;$(OASIS_INSTALLATION_ROOT)/UserSDK/lib/AT"';

				$_ = $Tmp;
				print TMPVCPROJ "$_\n";
			}
			elsif (/AdditionalLibraryDirectories=\S*lib;/ig)
			{
				my $Tmp = '				AdditionalLibraryDirectories=".\;';
				$Tmp .= "..\\..\\..\\GEN\\" . $Revision . "\\Supercede_lib;..\\..\\..\\OASIS\\" . $Revision . "\\Supercede_lib;";
				$Tmp .=	"..\\..\\lib;..\\..\\..\\GEN\\" .  $Revision . "\\lib;..\\..\\..\\OASIS\\" .  $Revision . "\\lib;";
				$Tmp .= "..\\..\\..\\GEN\\" . $Revision . "\\nhm\\lib;..\\..\\..\\OASIS\\" . $Revision . "\\nhm\\lib;";
				$Tmp .= '$(OASIS_INSTALLATION_ROOT)/UserSDK/lib/OAI;$(OASIS_INSTALLATION_ROOT)/VendorSDK/lib/OAI;$(OASIS_INSTALLATION_ROOT)/UserSDK/lib/AT"';

				$_ = $Tmp;
				
				print TMPVCPROJ "$_\n";
			}
			elsif ((/OutputFile=\"\S+\\lib_debug\\/ig) ||(/ImportLibrary=\"\S+\\lib_debug\\/ig))
			{
				s/..\\..\\..\\lib_debug\\/..\\Supercede_lib_debug\\/i;
				s/..\\..\\lib_debug\\/..\\Supercede_lib_debug\\/i;
				s/..\\lib_debug\\/..\\Supercede_lib_debug\\/i;
				print TMPVCPROJ "$_";
			}
			elsif ((/OutputFile=\"\S+\\lib\\/ig) ||(/ImportLibrary=\"\S+\\lib\\/ig))
			{
				s/..\\..\\..\\lib\\/..\\Supercede_lib\\/i;
				s/..\\..\\lib\\/..\\Supercede_lib\\/i;
				s/..\\lib\\/..\\Supercede_lib\\/i;
				print TMPVCPROJ "$_";
			}
			elsif ((/OutputFile=\"\S+\/lib_debug\//ig) || (/ImportLibrary=\"\S+\/lib_debug\//ig))
			{
				s/..\\..\\..\\lib_debug\\/..\\Supercede_lib_debug\\/i;
				s/..\\..\\lib_debug\\/..\\Supercede_lib_debug\\/i;
				s/..\\lib_debug\\/..\\Supercede_lib_debug\\/i;
				print TMPVCPROJ "$_";
			}
			elsif ((/OutputFile=\"\S+\/lib\//ig) || (/ImportLibrary=\"\S+\/lib\//ig))
			{
				s/..\\..\\..\\lib\\/..\\Supercede_lib\\/i;
				s/..\\..\\lib\\/..\\Supercede_lib\\/i;
				s/..\\lib\\/..\\Supercede_lib\\/i;
				print TMPVCPROJ "$_";
			}
			else
			{
				print TMPVCPROJ "$_";
			}
		}
		elsif ($VcProjFile =~ /\/OASIS\/\S+\/Supercede_templates\/\S+\.vcproj/)
		{
			if (/AdditionalIncludeDirectories=/ig)
			{
				my $Tmp = '				AdditionalIncludeDirectories=".;';
				$Tmp .= "..\\..\\..\\GEN\\" . $Revision . "\\Supercede_code;..\\..\\..\\OASIS\\" . $Revision . "\\Supercede_code;";
				$Tmp .= "..\\GEN\\Code;..\\..\\..\\GEN\\" . $Revision . "\\code;..\\..\\..\\OASIS\\" . $Revision . "\\code;";
				$Tmp .= "..\\..\\..\\GEN\\" . $Revision . "\\nhm\\src\\code;..\\..\\..\\OASIS\\" . $Revision . "\\nhm\\src\\code;";
				$Tmp .= '$(OASIS_INSTALLATION_ROOT)\UserSDK\src\OAI\ToolsSDK\FrameWork\STDProxy;$(OASIS_INSTALLATION_ROOT)\UserSDK\inc\OAI\proxy;$(OASIS_INSTALLATION_ROOT)\UserSDK\inc;$(OASIS_INSTALLATION_ROOT)\UserSDK\inc\OAI;$(OASIS_INSTALLATION_ROOT)\UserSDK\inc\OAI\OFC;$(OASIS_INSTALLATION_ROOT)\UserSDK\inc\OAI\core;$(OASIS_INSTALLATION_ROOT)\VendorSDK\inc"';

				$_ = $Tmp;
				print TMPVCPROJ "$_\n";
			}
			elsif (/AdditionalLibraryDirectories=\S*lib_debug;/ig)
			{
				my $Tmp = '				AdditionalLibraryDirectories=".\;';
				$Tmp .= "..\\..\\..\\GEN\\" . $Revision . "\\Supercede_lib_debug;..\\..\\..\\OASIS\\" . $Revision . "\\Supercede_lib_debug;";
				$Tmp .=	"..\\..\\lib_debug;..\\..\\..\\GEN\\" .  $Revision . "\\lib_debug;..\\..\\..\\OASIS\\" .  $Revision . "\\lib_debug;";
				$Tmp .= "..\\..\\..\\GEN\\" . $Revision . "\\nhm\\lib_debug;..\\..\\OASIS\\" . $Revision . "\\nhm\\lib_debug;";
				$Tmp .= '$(OASIS_INSTALLATION_ROOT)/UserSDK/lib/OAI;$(OASIS_INSTALLATION_ROOT)/VendorSDK/lib/OAI;$(OASIS_INSTALLATION_ROOT)/UserSDK/lib/AT"';

				$_ = $Tmp;
				print TMPVCPROJ "$_\n";
			}
			elsif (/AdditionalLibraryDirectories=\S*lib;/ig)
			{
				my $Tmp = '				AdditionalLibraryDirectories=".\;';
				$Tmp .= "..\\..\\..\\GEN\\" . $Revision . "\\Supercede_lib;..\\..\\..\\OASIS\\" . $Revision . "\\Supercede_lib;";
				$Tmp .=	"..\\..\\lib;..\\..\\..\\GEN\\" .  $Revision . "\\lib;..\\..\\..\\OASIS\\" .  $Revision . "\\lib;";
				$Tmp .= "..\\..\\..\\GEN\\" . $Revision . "\\nhm\\lib;..\\..\\..\\OASIS\\" . $Revision . "\\nhm\\lib;";
				$Tmp .= '$(OASIS_INSTALLATION_ROOT)/UserSDK/lib/OAI;$(OASIS_INSTALLATION_ROOT)/VendorSDK/lib/OAI;$(OASIS_INSTALLATION_ROOT)/UserSDK/lib/AT"';

				$_ = $Tmp;
				
				print TMPVCPROJ "$_\n";
			}
			elsif ((/OutputFile=\"\S+\\lib_debug\\/ig) ||(/ImportLibrary=\"\S+\\lib_debug\\/ig))
			{
				s/..\\..\\..\\lib_debug\\/..\\Supercede_lib_debug\\/i;
				s/..\\..\\lib_debug\\/..\\Supercede_lib_debug\\/i;
				s/..\\lib_debug\\/..\\Supercede_lib_debug\\/i;
				print TMPVCPROJ "$_";
			}
			elsif ((/OutputFile=\"\S+\\lib\\/ig) ||(/ImportLibrary=\"\S+\\lib\\/ig))
			{
				s/..\\..\\..\\lib\\/..\\Supercede_lib\\/i;
				s/..\\..\\lib\\/..\\Supercede_lib\\/i;
				s/..\\lib\\/..\\Supercede_lib\\/i;
				print TMPVCPROJ "$_";
			}
			elsif ((/OutputFile=\"\S+\/lib_debug\//ig) || (/ImportLibrary=\"\S+\/lib_debug\//ig))
			{
				s/..\\..\\..\\lib_debug\\/..\\Supercede_lib_debug\\/i;
				s/..\\..\\lib_debug\\/..\\Supercede_lib_debug\\/i;
				s/..\\lib_debug\\/..\\Supercede_lib_debug\\/i;
				print TMPVCPROJ "$_";
			}
			elsif ((/OutputFile=\"\S+\/lib\//ig) || (/ImportLibrary=\"\S+\/lib\//ig))
			{
				s/..\\..\\..\\lib\\/..\\Supercede_lib\\/i;
				s/..\\..\\lib\\/..\\Supercede_lib\\/i;
				s/..\\lib\\/..\\Supercede_lib\\/i;
				print TMPVCPROJ "$_";
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
				$_ = '    "$(OASIS_INSTALLATION_ROOT)\bin\OAI_occ.exe" -t ..\..\..\OASIS\\' . $Revision . '\templates -i ..\..\..\OASIS\\' . $Revision . '\templates -np $**  -o .';
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


		
		print "$_" if ($Debug == 1);

	}
	close VCPROJ;	
	close TMPVCPROJ;

	#copy ($TmpVcProjFile, $VcProjFile) or die "Cant copy from $TmpVcProjFile to $VcProjFile - failed: $!";
	move ($TmpVcProjFile, $VcProjFile) or die "Cant copy from $TmpVcProjFile to $VcProjFile - failed: $!";

}

# Get all the .vcproj, _h_make and .rc files
sub GetVvprojFiles
{
	if ((-f $File::Find::name) && (($File::Find::name =~ /\.vcproj$/i) ||($File::Find::name =~ /_h_make$/i) || ($File::Find::name =~ /\.rc$/i)) && (($File::Find::name =~ /$Revision\/\w*templates\//i) || ($File::Find::name =~ /$Revision\/\w*code\//i) || ($File::Find::name =~ /$Revision\/\w*src\//i) || ($File::Find::name =~ /$Revision\/cktm\/\w*src\//i)))
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
	my ($RootDir, $Revision) = ("", "");

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
	}
	close CONFIG;

	return ($RootDir, $Revision);
}
