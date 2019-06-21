#################################################################################################################
#														#
#	Foo Lye Cheung					PG PDE CPU (TMM)					#
#	16 Nov 2007												#
#	604-2536452												#
#														#
#	This script is to change CorTeX revision before compile in .vcproj					#
#														#
#	   													#
#	Rev 1.2													#
#	   													#
#	Changes:												#
#	10/26/2007												#
#	1. Added nhm code directory structure									#
#														#
#	11/16/2007												#
#	1. Added Supercede code directory structure for GEN code						#
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

my $GENCodeDir = $RootDir . '/GEN/' . $Revision . '/code';
my $GENTemplatesDir = $RootDir . '/GEN/' . $Revision . '/templates';
my $OASISDir = $RootDir . '/OASIS/' . $Revision;
my $UFsDir = $RootDir . '/UFs/' . $Revision . '/cktm';
$GENCodeDir =~ s/\/\//\//g;
$GENTemplatesDir =~ s/\/\//\//g;
$OASISDir =~ s/\/\//\//g;
$UFsDir =~ s/\/\//\//g;

&Main();

# Main subroutine 
sub Main
{
	finddepth(\&GetVvprojFiles, $GENCodeDir, $GENTemplatesDir, $OASISDir, $UFsDir);

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
		if ($VcProjFile =~ /\/UFs\//)
		{
			if (/AdditionalIncludeDirectories=/ig)
			{
				my $Tmp = '				AdditionalIncludeDirectories=".;';
				$Tmp .= "..\\..\\..\\..\\GEN\\" . $Revision . "\\Supercede_code;..\\..\\..\\..\\OASIS\\" . $Revision . "\\Supercede_code;";
				$Tmp .= "..\\..\\..\\..\\GEN\\" . $Revision . "\\nhm\\src\\code;..\\..\\..\\..\\OASIS\\" . $Revision . "\\nhm\\src\\code;";
				$Tmp .= "..\\GEN\\Code;..\\..\\..\\..\\GEN\\" . $Revision . "\\code;..\\..\\..\\..\\OASIS\\" . $Revision . "\\code;";
				$Tmp .= '$(OASIS_INSTALLATION_ROOT)\UserSDK\inc\OAI\proxy;$(OASIS_INSTALLATION_ROOT)\UserSDK\inc;$(OASIS_INSTALLATION_ROOT)\UserSDK\inc\OAI;$(OASIS_INSTALLATION_ROOT)\UserSDK\inc\OAI\OFC;$(OASIS_INSTALLATION_ROOT)\UserSDK\inc\OAI\core;$(OASIS_INSTALLATION_ROOT)\VendorSDK\inc"';

				$_ = $Tmp;
				print TMPVCPROJ "$_\n";
			}
			elsif (/AdditionalLibraryDirectories=\S*lib_debug;/ig)
			{
				my $Tmp = '				AdditionalLibraryDirectories=".\;';
				$Tmp .= "..\\..\\..\\..\\GEN\\" . $Revision . "\\Supercede_lib_debug;..\\..\\..\\..\\OASIS\\" . $Revision . "\\Supercede_lib_debug;";
				$Tmp .= "..\\..\\..\\..\\GEN\\" . $Revision . "\\nhm\\lib_debug;..\\..\\..\\..\\OASIS\\" . $Revision . "\\nhm\\lib_debug;";
				$Tmp .=	"..\\..\\lib_debug;..\\..\\..\\..\\GEN\\" .  $Revision . "\\lib_debug;..\\..\\..\\..\\OASIS\\" .  $Revision . "\\lib_debug;";
				$Tmp .= '$(OASIS_INSTALLATION_ROOT)/UserSDK/lib/OAI;$(OASIS_INSTALLATION_ROOT)/VendorSDK/lib/OAI;$(OASIS_INSTALLATION_ROOT)/UserSDK/lib/AT"';

				$_ = $Tmp;
				print TMPVCPROJ "$_\n";
			}
			elsif (/AdditionalLibraryDirectories=\S*lib;/ig)
			{
				my $Tmp = '				AdditionalLibraryDirectories=".\;';
				$Tmp .= "..\\..\\..\\..\\GEN\\" . $Revision . "\\Supercede_lib;..\\..\\..\\..\\OASIS\\" . $Revision . "\\Supercede_lib;";
				$Tmp .= "..\\..\\..\\..\\GEN\\" . $Revision . "\\nhm\\lib;..\\..\\..\\..\\OASIS\\" . $Revision . "\\nhm\\lib;";
				$Tmp .=	"..\\..\\lib;..\\..\\..\\..\\GEN\\" .  $Revision . "\\lib;..\\..\\..\\..\\OASIS\\" .  $Revision . "\\lib;";
				$Tmp .= '$(OASIS_INSTALLATION_ROOT)/UserSDK/lib/OAI;$(OASIS_INSTALLATION_ROOT)/VendorSDK/lib/OAI;$(OASIS_INSTALLATION_ROOT)/UserSDK/lib/AT"';

				$_ = $Tmp;
				print TMPVCPROJ "$_\n";
			}
			else
			{
				print TMPVCPROJ "$_";
			}
		}
		elsif ($VcProjFile =~ /\/GEN\/\S+\/code\/\S+\.vcproj/)
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
			else
			{
				print TMPVCPROJ "$_";
			}
		}
		elsif ($VcProjFile =~ /\/GEN\/\S+\/templates\/\S+\.vcproj/)
		{
			my $Code = "";
			if (/AdditionalIncludeDirectories=/ig)
			{
				if ($_ !~ /Supercede_code/)
				{
					my $Code = "";
					$Code = $1 if (/=\s*\"(\S+)\"$/);
				
					my $Tmp = '				AdditionalIncludeDirectories="';
					$Tmp .= "..\\Supercede_code;";
					$Tmp .= $Code;
					$Tmp .= "\"\n";
				
					$_ = $Tmp;
				}
				print TMPVCPROJ "$_";
			}
			elsif (/AdditionalLibraryDirectories=\S*lib_debug;/ig)
			{
				if ($_ !~ /Supercede_lib_debug/)
				{
					my $Code = "";
					$Code = $1 if (/=\s*\"(\S+)\"$/);

					my $Tmp = '				AdditionalLibraryDirectories="';
					$Tmp .= "..\\Supercede_lib_debug;";
					$Tmp .= $Code;
					$Tmp .= "\"\n";

					$_ = $Tmp;
				}
				print TMPVCPROJ "$_";
			}
			elsif (/AdditionalLibraryDirectories=\S*lib;/ig)
			{
				if ($_ !~ /Supercede_lib/)
				{
					my $Code = "";
					$Code = $1 if (/=\s*\"(\S+)\"$/);

					my $Tmp = '				AdditionalLibraryDirectories="';
					$Tmp .= "..\\Supercede_lib;";
					$Tmp .= $Code;
					$Tmp .= "\"\n";

					$_ = $Tmp;
				}
				print TMPVCPROJ "$_";
			}
			else
			{
				print TMPVCPROJ "$_";
			}
		}
		else
		{
			if ((/\\GEN\\Rev\S*\\code;/i) || (/\\GEN\\Rev\S*\\lib;/i) || (/\\GEN\\Rev\S*\\lib_debug;/i))
			{
				if ((/\\GEN\\Rev\S*\\Supercede_code;/i) || (/\\GEN\\Rev\S*\\Supercede_lib;/i) || (/\\GEN\\Rev\S*\\Supercede_lib_debug;/i))
				{
					s/;..\\..\\..\\GEN\\Rev\S*\\Supercede_code;..\\..\\..\\GEN\\Rev\S*\\code;/;..\\..\\..\\GEN\\$Revision\\Supercede_code;..\\..\\..\\GEN\\$Revision\\code;/ig;
					s/;..\\..\\..\\GEN\\Rev\S*\\Supercede_lib;..\\..\\..\\GEN\\Rev\S*\\lib;/;..\\..\\..\\GEN\\$Revision\\Supercede_lib;..\\..\\..\\GEN\\$Revision\\lib;/ig;
					s/;..\\..\\..\\GEN\\Rev\S*\\Supercede_lib_debug;..\\..\\..\\GEN\\Rev\S*\\lib_debug;/;..\\..\\..\\GEN\\$Revision\\Supercede_lib_debug;..\\..\\..\\GEN\\$Revision\\lib_debug;/ig;
				}
				else
				{
					s/;..\\..\\..\\GEN\\Rev\S*\\code;/;..\\..\\..\\GEN\\$Revision\\Supercede_code;..\\..\\..\\GEN\\$Revision\\code;/ig;
					s/;..\\..\\..\\GEN\\Rev\S*\\lib;/;..\\..\\..\\GEN\\$Revision\\Supercede_lib;..\\..\\..\\GEN\\$Revision\\lib;/ig;
					s/;..\\..\\..\\GEN\\Rev\S*\\lib_debug;/;..\\..\\..\\GEN\\$Revision\\Supercede_lib_debug;..\\..\\..\\GEN\\$Revision\\lib_debug;/ig;
				}
				print TMPVCPROJ "$_";
				print "$_" if ($Debug == 1);
			}
			elsif ((/\\OASIS\\Rev\S*\\code;/i) || (/\\OASIS\\Rev\S*\\lib;/i) || (/\\OASIS\\Rev\S*\\lib_debug;/i))
			{
				if ((/\\OASIS\\Rev\S*\\Supercede_code;/i) || (/\\OASIS\\Rev\S*\\Supercede_lib;/i) || (/\\OASIS\\Rev\S*\\Supercede_lib_debug;/i))
				{
					s/;..\\..\\..\\OASIS\\Rev\S*\\Supercede_code;..\\..\\..\\OASIS\\Rev\S*\\code;/;..\\..\\..\\OASIS\\$Revision\\Supercede_code;..\\..\\..\\OASIS\\$Revision\\code;/ig;
					s/;..\\..\\..\\OASIS\\Rev\S*\\Supercede_lib;..\\..\\..\\OASIS\\Rev\S*\\lib;/;..\\..\\..\\OASIS\\$Revision\\Supercede_lib;..\\..\\..\\OASIS\\$Revision\\lib;/ig;
					s/;..\\..\\..\\OASIS\\Rev\S*\\Supercede_lib_debug;..\\..\\..\\OASIS\\Rev\S*\\lib_debug;/;..\\..\\..\\OASIS\\$Revision\\Supercede_lib_debug;..\\..\\..\\OASIS\\$Revision\\lib_debug;/ig;
				}
				else
				{
					s/;..\\..\\..\\OASIS\\Rev\S*\\code;/;..\\..\\..\\OASIS\\$Revision\\Supercede_code;..\\..\\..\\OASIS\\$Revision\\code;/ig;
					s/;..\\..\\..\\OASIS\\Rev\S*\\lib;/;..\\..\\..\\OASIS\\$Revision\\Supercede_lib;..\\..\\..\\OASIS\\$Revision\\lib;/ig;
					s/;..\\..\\..\\OASIS\\Rev\S*\\lib_debug;/;..\\..\\..\\OASIS\\$Revision\\Supercede_lib_debug;..\\..\\..\\OASIS\\$Revision\\lib_debug;/ig;
				}
				print TMPVCPROJ "$_";
				print "$_" if ($Debug == 1);
			}
			# The directory slash is reverse
			elsif ((/\/GEN\/Rev\S*\/code;/i) || (/\/GEN\/Rev\S*\/lib;/i) || (/\/GEN\/Rev\S*\/lib_debug;/i))
			{
				if ((/\/GEN\/Rev\S*\/Supercede_code;/i) || (/\/GEN\/Rev\S*\/Supercede_lib;/i) || (/\/GEN\/Rev\S*\/Supercede_lib_debug;/i))
				{
					s/;..\/..\/..\/GEN\/Rev\S*\/Supercede_code;..\/..\/..\/GEN\/Rev\S*\/code;/;..\/..\/..\/GEN\/$Revision\/Supercede_code;..\/..\/..\/GEN\/$Revision\/code;/ig;
					s/;..\/..\/..\/GEN\/Rev\S*\/Supercede_lib;..\/..\/..\/GEN\/Rev\S*\/lib;/;..\/..\/..\/GEN\/$Revision\/Supercede_lib;..\/..\/..\/GEN\/$Revision\/lib;/ig;
					s/;..\/..\/..\/GEN\/Rev\S*\/Supercede_lib_debug;..\/..\/..\/GEN\/Rev\S*\/lib_debug;/;..\/..\/..\/GEN\/$Revision\/Supercede_lib_debug;..\/..\/..\/GEN\/$Revision\/lib_debug;/ig;
				}
				else
				{
					s/;..\/..\/..\/GEN\/Rev\S*\/code;/;..\/..\/..\/GEN\/$Revision\/Supercede_code;..\/..\/..\/GEN\/$Revision\/code;/ig;
					s/;..\/..\/..\/GEN\/Rev\S*\/lib;/;..\/..\/..\/GEN\/$Revision\/Supercede_lib;..\/..\/..\/GEN\/$Revision\/lib;/ig;
					s/;..\/..\/..\/GEN\/Rev\S*\/lib_debug;/;..\/..\/..\/GEN\/$Revision\/Supercede_lib_debug;..\/..\/..\/GEN\/$Revision\/lib_debug;/ig;
				}
				print TMPVCPROJ "$_";
				print "$_" if ($Debug == 1);
			}
			elsif ((/\/OASIS\/Rev\S*\/code;/i) || (/\/OASIS\/Rev\S*\/lib;/i) || (/\/OASIS\/Rev\S*\/lib_debug;/i))
			{
				if ((/\/OASIS\/Rev\S*\/Supercede_code;/i) || (/\/OASIS\/Rev\S*\/Supercede_lib;/i) || (/\/OASIS\/Rev\S*\/Supercede_lib_debug;/i))
				{
					s/;..\/..\/..\/OASIS\/Rev\S*\/Supercede_code;..\/..\/..\/OASIS\/Rev\S*\/code;/;..\/..\/..\/OASIS\/$Revision\/Supercede_code;..\/..\/..\/OASIS\/$Revision\/code;/ig;
					s/;..\/..\/..\/OASIS\/Rev\S*\/Supercede_lib;..\/..\/..\/OASIS\/Rev\S*\/lib;/;..\/..\/..\/OASIS\/$Revision\/Supercede_lib;..\/..\/..\/OASIS\/$Revision\/lib;/ig;
					s/;..\/..\/..\/OASIS\/Rev\S*\/Supercede_lib_debug;..\/..\/..\/OASIS\/Rev\S*\/lib_debug;/;..\/..\/..\/OASIS\/$Revision\/Supercede_lib_debug;..\/..\/..\/OASIS\/$Revision\/lib_debug;/ig;
				}
				else
				{
					s/;..\/..\/..\/OASIS\/Rev\S*\/code;/;..\/..\/..\/OASIS\/$Revision\/Supercede_code;..\/..\/..\/OASIS\/$Revision\/code;/ig;
					s/;..\/..\/..\/OASIS\/Rev\S*\/lib;/;..\/..\/..\/OASIS\/$Revision\/Supercede_lib;..\/..\/..\/OASIS\/$Revision\/lib;/ig;
					s/;..\/..\/..\/OASIS\/Rev\S*\/lib_debug;/;..\/..\/..\/OASIS\/$Revision\/Supercede_lib_debug;..\/..\/..\/OASIS\/$Revision\/lib_debug;/ig;
				}
				print TMPVCPROJ "$_";
				print "$_" if ($Debug == 1);
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

# Get all the .vcproj files
sub GetVvprojFiles
{
	if ((-f $File::Find::name) && ($File::Find::name =~ /\.vcproj$/i) && (($File::Find::name =~ /$Revision\/\w*templates\//i) || ($File::Find::name =~ /$Revision\/\w*code\//i) || ($File::Find::name =~ /$Revision\/\w*src\//i) || ($File::Find::name =~ /$Revision\/cktm\/\w*src\//i)))
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
