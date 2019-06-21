#Based on CMake_Win.pl written for Gift-VT 

use lib "$ENV{DV_TOOL}\\GiftVT\\Gift-VT_601_CTX4.9.1\\Run_files\\scripts\\modules";
use lib "$ENV{DV_TOOL}\\GiftVT\\Gift-VT_601_CTX4.9.1\\src\\build";
use Cwd;
use File::Find;
use Win32::Console;
use Getopt::Long;
use WIN32_CmakeUtils;
use BuildUtils;

#allocate new console object based on the standard ouput 
my $STDOUT =  new Win32::Console(STD_OUTPUT_HANDLE);
my $solName;
my $solDir;
my $solFullPath;
my @files = ();

my $build_type;

################################# Start of main script #########################################################


&GetOptions('ctx_lib=s' =>\$ctx_lib, 'ctx_ver=s' =>\$ctx_ver);
system("cls");
if ((!defined($ctx_lib)) || (!defined($ctx_ver))) {
	print "Use script with -ctx_lib={Dir where dv lib src dir is} -ctx_ver={RevX.X.X}\n\n" ;
	exit(0);
}
#system("$ENV{VS80COMNTOOLS}\\vsvars32.bat");
$ctx_tos_dir = "I:\\tpapps\\CorTex\\OASIS\\".$ctx_ver."\\";
$ctx_gen_dir = "I:\\tpapps\\CorTex\\GEN\\".$ctx_ver."\\";
$ENV{'CORTEX_GEN_DIR'} = $ctx_gen_dir;
$ENV{'CORTEX_TOS_DIR'} = $ctx_tos_dir;

print "Cortex GEN is $ENV{'CORTEX_GEN_DIR'}\n" ;
print "Cortex OASIS is $ENV{'CORTEX_TOS_DIR'}\n" ;
###### STEP 1 - clean all DLLs
print "Cleaning DLL files under lib and lib_debug\n";	
@files = ();
$lib_dir = $ENV{DV_TOOL}."\\DVLib\\".$ctx_lib."\\lib\\";
find(\&edits_dll, $lib_dir);
for ($i = 0 ; $i < @files ; $i++)  {    
    unlink($files[$i]);
}   
$lib_debug_dir = $ENV{DV_TOOL}."\\DVLib\\".$ctx_lib."\\lib_debug\\";
find(\&edits_dll, $lib_debug_dir);
for ($i = 0 ; $i < @files ; $i++)  {    
    unlink($files[$i]);
}   

$solDir = $ENV{DV_TOOL}."\\DVLib\\".$ctx_lib."\\src\\";
$solFullPath = $solDir . $solName;
$build_type = "Rebuild";

################################# SysCInstall #########################################################

print "Compiling SysCInstall\n";
$solName = "OASIS_sysCInstall_tt.sln";
$solFullPath = $solDir . $solName;
print "Compiling solution file $solFullPath ... \n";
compile($solFullPath,"Debug",1,$build_type,$logfile);
compile($solFullPath,"Release",1,$build_type,$logfile);
print "Build of SysCInstall was successful\n";

################################# PatternRead #########################################################

print "Compiling PatternRead\n";
$solName = "PatternRead.sln";
$solFullPath = $solDir . $solName;
print "Compiling solution file $solFullPath ... \n";
compile($solFullPath,"Debug",1,$build_type,$logfile);
compile($solFullPath,"Release",1,$build_type,$logfile);
print "Build of PatternRead was successful\n";

################################# Print2Ituff #########################################################

print "Compiling Print2Ituff\n";
$solName = "Print2Ituff.sln";
$solFullPath = $solDir . $solName;
print "Compiling solution file $solFullPath ... \n";
compile($solFullPath,"Debug",1,$build_type,$logfile);
compile($solFullPath,"Release",1,$build_type,$logfile);
print "Build of Print2Ituff was successful\n";

################################# ULTDecoder #########################################################

print "Compiling ULTDecoder\n";
$solName = "ULTDecoder.sln";
$solFullPath = $solDir . $solName;
print "Compiling solution file $solFullPath ... \n";
compile($solFullPath,"Debug",1,$build_type,$logfile);
compile($solFullPath,"Release",1,$build_type,$logfile);
print "Build of ULTDecoder was successful\n";

################################# End of main script #########################################################

########################################################################
############# Auxilary functions  ######################################
########################################################################

sub edits_dll() {
    my $file;
    if (m/\.dll$/ || m/\.exp$/ || m/\.lib$/ || m/\.help$/ || m/\.map$/)
    {     
       $file = $File::Find::name;
       push (@files,$file);
    }	
}