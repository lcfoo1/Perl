#!perl

use Win32::OLE;
use Cwd;
use strict;

sub Usage {
    my(@c, $l);
    $c[++$l] = "build_uf_frame.pl     version: 1.0 ";
    $c[++$l] = "Usage: ";
    $c[++$l] = "    build_uf_frame.pl -root [CorTeX_Root] -gen_rev [CorTeX_Rev_number]";
    $c[++$l] = "                      -oasis_rev [CorTeX_OASIS_Rev] -ufname [UF_filename]";
    $c[++$l] = "    Example,";
    $c[++$l] = "        build_uf_frame.pl -root c:\\intel\\tpapps\\CorTeX -gen_rev Rev1.5.1";
    $c[++$l] = "                          -oasis_rev Rev1.5.1 -ufname my_uf";
    $c[++$l] = "\n";
    $, = "\n";
    print STDERR@c,"\n";
    exit;
}

my($cortex_root, $cortex_gen_rev, $cortex_oasis_rev, $uf_name);
my($i, $cortex_gen_dir, $cortex_oasis_dir);

if(!@ARGV || @ARGV != 8) {
    &Usage();
}

for($i = 0; $i < @ARGV; $i++) {
    if($ARGV[$i] =~ /-root/) {
        $cortex_root = $ARGV[++$i];
    }
    elsif($ARGV[$i] =~ /-gen_rev/) {
        $cortex_gen_rev = $ARGV[++$i];
    }
    elsif($ARGV[$i] =~ /-oasis_rev/) {
        $cortex_oasis_rev = $ARGV[++$i];
    }
    elsif($ARGV[$i] =~ /-ufname/) {
        $uf_name = $ARGV[++$i];
    }
    else {
        &Usage();
    }
}

print STDOUT "cortex_root: $cortex_root\n";
print STDOUT "cortex_gen_rev: $cortex_gen_rev\n";
print STDOUT "cortex_oasis_rev: $cortex_oasis_rev\n";
print STDOUT "UF name: $uf_name\n";

die("CorTeX Root: \"$cortex_root\" does not exist!!!\n") if(!(-e $cortex_root));

$cortex_gen_dir = $cortex_root."\\GEN\\".$cortex_gen_rev;
$cortex_oasis_dir = $cortex_root."\\OASIS\\".$cortex_oasis_rev;

die("CorTeX GEN Directory: $cortex_gen_dir does not exist!!!\n") if(!(-e $cortex_gen_dir));
die("CorTeX OASIS Directory: $cortex_oasis_dir does not exist!!!\n") if(!(-e $cortex_oasis_dir));

&build_uf_cpp_and_h(\$uf_name);

#Determine if you want to build for 4.X or 3.X to make decision on VS 7.1 or VS 7.0
if( $cortex_gen_rev =~m "Rev4." ) {
	print STDOUT "\nDetected 4.X version - Building 8.0 project file (Visual Studio 2005)\n";
	&build_uf_vcproj_201_71(\$cortex_gen_dir, \$cortex_oasis_dir, \$uf_name);
}

sub build_uf_vcproj_201_71 {
    my($gen_dir, $oasis_dir, $uf_name) = @_;
    my($uf_vcproj_file,  $i, @uf_vcproj, $cap_uf_name);

    $i = 0;
    $cap_uf_name = $$uf_name;
    $cap_uf_name =~ tr/a-z/A-Z/;

    $uf_vcproj[$i++] = "<?xml version=\"1.0\" encoding = \"Windows-1252\"?>";
    $uf_vcproj[$i++] = "<VisualStudioProject";
    $uf_vcproj[$i++] = "	ProjectType=\"Visual C++\"";
    $uf_vcproj[$i++] = "	Version=\"8.00\"";
    $uf_vcproj[$i++] = "	Name=\"".$$uf_name."\"";
    $uf_vcproj[$i++] = "	ProjectGUID=\"{9F231EC1-DD33-4EDA-86D1-693E02DD588E}\"";
    $uf_vcproj[$i++] = "	Keyword=\"Win32Proj\">";
    $uf_vcproj[$i++] = "	<Platforms>";
    $uf_vcproj[$i++] = "		<Platform";
    $uf_vcproj[$i++] = "			Name=\"Win32\"/>";
    $uf_vcproj[$i++] = "	</Platforms>";
    $uf_vcproj[$i++] = "	<Configurations>";
    $uf_vcproj[$i++] = "		<Configuration";
    $uf_vcproj[$i++] = "			Name=\"Debug|Win32\"";
    $uf_vcproj[$i++] = "			OutputDirectory=\"Debug\"";
    $uf_vcproj[$i++] = "			IntermediateDirectory=\"Debug\"";
    $uf_vcproj[$i++] = "			ConfigurationType=\"2\"";
    $uf_vcproj[$i++] = "			CharacterSet=\"2\">";
    $uf_vcproj[$i++] = "			<Tool";
    $uf_vcproj[$i++] = "				Name=\"VCCLCompilerTool\"";
    $uf_vcproj[$i++] = "				AdditionalOptions=\"/Zm1000\"";
    $uf_vcproj[$i++] = "				Optimization=\"0\"";
    $uf_vcproj[$i++] = "				AdditionalIncludeDirectories=\".\;".$$gen_dir."\\code\;".$$oasis_dir."\\code\;\$(OASIS_INSTALLATION_ROOT)\\UserSDK\\inc\\OAI\\proxy\;\$(OASIS_INSTALLATION_ROOT)\\UserSDK\\inc\;\$(OASIS_INSTALLATION_ROOT)\\UserSDK\\inc\\OAI\;\$(OASIS_INSTALLATION_ROOT)\\UserSDK\\inc\\OAI\\OFC\;\$(OASIS_INSTALLATION_ROOT)\\UserSDK\\inc\\OAI\\core\;\$(OASIS_INSTALLATION_ROOT)\\VendorSDK\\inc\"";
    $uf_vcproj[$i++] = "				PreprocessorDefinitions=\"WIN32;_DEBUG;_LIB;_WINDOWS;_USRDLL;CODE_EXPORTS;_TSS201A;__".$cap_uf_name."_DLL__\"";
    $uf_vcproj[$i++] = "				MinimalRebuild=\"FALSE\"";
    $uf_vcproj[$i++] = "				BasicRuntimeChecks=\"0\"";
    $uf_vcproj[$i++] = "				RuntimeLibrary=\"3\"";
    $uf_vcproj[$i++] = "				BufferSecurityCheck=\"FALSE\"";
    $uf_vcproj[$i++] = "				RuntimeTypeInfo=\"TRUE\"";
    $uf_vcproj[$i++] = "				UsePrecompiledHeader=\"0\"";
    $uf_vcproj[$i++] = "				ProgramDataBaseFileName=\"\$(IntDir)\\".$$uf_name.".pdb\"";
    $uf_vcproj[$i++] = "				WarningLevel=\"3\"";
    $uf_vcproj[$i++] = "				Detect64BitPortabilityProblems=\"FALSE\"";
    $uf_vcproj[$i++] = "				DebugInformationFormat=\"3\"/>";
    $uf_vcproj[$i++] = "			<Tool";
    $uf_vcproj[$i++] = "				Name=\"VCCustomBuildTool\"/>";
    $uf_vcproj[$i++] = "			<Tool";
    $uf_vcproj[$i++] = "				Name=\"VCLinkerTool\"";
    $uf_vcproj[$i++] = "				AdditionalDependencies=\"OASIS_cortex_utility.lib OASIS_GEN_code.lib OASIS_code.lib\"";
    $uf_vcproj[$i++] = "				OutputFile=\"..\\lib_debug\\".$$uf_name.".dll\"";
    $uf_vcproj[$i++] = "				LinkIncremental=\"1\"";
    $uf_vcproj[$i++] = "				AdditionalLibraryDirectories=\"".$$gen_dir."\\lib_debug\;".$$oasis_dir."\\lib_debug\;\$(OASIS_INSTALLATION_ROOT)\\UserSDK\\lib\\OAI\;\$(OASIS_INSTALLATION_ROOT)\\VendorSDK\\lib\\OAI\"";
    $uf_vcproj[$i++] = "				GenerateDebugInformation=\"TRUE\"";
    $uf_vcproj[$i++] = "				ProgramDatabaseFile=\"..\\lib_debug\\".$$uf_name.".pdb\"";
    $uf_vcproj[$i++] = "				GenerateMapFile=\"TRUE\"";
    $uf_vcproj[$i++] = "				SubSystem=\"1\"";
    $uf_vcproj[$i++] = "				ImportLibrary=\"..\\lib_debug\\".$$uf_name.".lib\"";
    $uf_vcproj[$i++] = "				TargetMachine=\"1\"/>";
    $uf_vcproj[$i++] = "			<Tool";
    $uf_vcproj[$i++] = "				Name=\"VCMIDLTool\"/>";
    $uf_vcproj[$i++] = "			<Tool";
    $uf_vcproj[$i++] = "				Name=\"VCPostBuildEventTool\"";
    $uf_vcproj[$i++] = "				Description=\"Renaming BuildLog.htm ....\"/>";
    #$uf_vcproj[$i++] = "				CommandLine=\"copy  \$(OutDir)\\BuildLog.htm \$(OutDir)\\".$$uf_name."_BuildLog.htm\"/>";
    $uf_vcproj[$i++] = "			<Tool";
    $uf_vcproj[$i++] = "				Name=\"VCPreBuildEventTool\"/>";
    $uf_vcproj[$i++] = "			<Tool";
    $uf_vcproj[$i++] = "				Name=\"VCPreLinkEventTool\"/>";
    $uf_vcproj[$i++] = "			<Tool";
    $uf_vcproj[$i++] = "				Name=\"VCResourceCompilerTool\"/>";
    $uf_vcproj[$i++] = "			<Tool";
    $uf_vcproj[$i++] = "				Name=\"VCWebServiceProxyGeneratorTool\"/>";
    $uf_vcproj[$i++] = "			<Tool";
    $uf_vcproj[$i++] = "				Name=\"VCWebDeploymentTool\"/>";
    $uf_vcproj[$i++] = "		</Configuration>";
    $uf_vcproj[$i++] = "		<Configuration";
    $uf_vcproj[$i++] = "			Name=\"Release|Win32\"";
    $uf_vcproj[$i++] = "			OutputDirectory=\"Release\"";
    $uf_vcproj[$i++] = "			IntermediateDirectory=\"Release\"";
    $uf_vcproj[$i++] = "			ConfigurationType=\"2\"";
    $uf_vcproj[$i++] = "			CharacterSet=\"2\">";
    $uf_vcproj[$i++] = "			<Tool";
    $uf_vcproj[$i++] = "				Name=\"VCCLCompilerTool\"";
    $uf_vcproj[$i++] = "				AdditionalOptions=\"/Zm1000\"";
    $uf_vcproj[$i++] = "				Optimization=\"2\"";
    $uf_vcproj[$i++] = "				InlineFunctionExpansion=\"1\"";
    $uf_vcproj[$i++] = "				OmitFramePointers=\"TRUE\"";
    $uf_vcproj[$i++] = "				AdditionalIncludeDirectories=\".\;".$$gen_dir."\\code\;".$$oasis_dir."\\code\;\$(OASIS_INSTALLATION_ROOT)\\UserSDK\\inc\\OAI\\proxy\;\$(OASIS_INSTALLATION_ROOT)\\UserSDK\\inc\;\$(OASIS_INSTALLATION_ROOT)\\UserSDK\\inc\\OAI\;\$(OASIS_INSTALLATION_ROOT)\\UserSDK\\inc\\OAI\\OFC\;\$(OASIS_INSTALLATION_ROOT)\\VendorSDK\\inc\"";
    $uf_vcproj[$i++] = "				PreprocessorDefinitions=\"WIN32;NDEBUG;_LIB;_WINDOWS;_USRDLL;CODE_EXPORTS;_TSS201A;__".$cap_uf_name."_DLL__\"";
    $uf_vcproj[$i++] = "				StringPooling=\"FALSE\"";
    $uf_vcproj[$i++] = "				RuntimeLibrary=\"2\"";
    $uf_vcproj[$i++] = "				BufferSecurityCheck=\"FALSE\"";
    $uf_vcproj[$i++] = "				EnableFunctionLevelLinking=\"FALSE\"";
    $uf_vcproj[$i++] = "				RuntimeTypeInfo=\"TRUE\"";
    $uf_vcproj[$i++] = "				UsePrecompiledHeader=\"0\"";
    $uf_vcproj[$i++] = "				ProgramDataBaseFileName=\"\$(IntDir)\\".$$uf_name.".pdb\"";
    $uf_vcproj[$i++] = "				WarningLevel=\"3\"";
    $uf_vcproj[$i++] = "				Detect64BitPortabilityProblems=\"FALSE\"";
    $uf_vcproj[$i++] = "				DebugInformationFormat=\"3\"/>";
    $uf_vcproj[$i++] = "			<Tool";
    $uf_vcproj[$i++] = "				Name=\"VCCustomBuildTool\"/>";
    $uf_vcproj[$i++] = "			<Tool";
    $uf_vcproj[$i++] = "				Name=\"VCLinkerTool\"";
    $uf_vcproj[$i++] = "				AdditionalDependencies=\"OASIS_cortex_utility.lib OASIS_GEN_code.lib OASIS_code.lib\"";
    $uf_vcproj[$i++] = "				OutputFile=\"..\\lib\\".$$uf_name.".dll\"";
    $uf_vcproj[$i++] = "				LinkIncremental=\"1\"";
    $uf_vcproj[$i++] = "				AdditionalLibraryDirectories=\"".$$gen_dir."\\lib\;".$$oasis_dir."\\lib\;\$(OASIS_INSTALLATION_ROOT)\\UserSDK\\lib\\OAI\;\$(OASIS_INSTALLATION_ROOT)\\VendorSDK\\lib\\OAI\"";
    $uf_vcproj[$i++] = "				ImportLibrary=\"..\\lib\\".$$uf_name.".lib\"/>";
    $uf_vcproj[$i++] = "			<Tool";
    $uf_vcproj[$i++] = "				Name=\"VCMIDLTool\"/>";
    $uf_vcproj[$i++] = "			<Tool";
    $uf_vcproj[$i++] = "				Name=\"VCPostBuildEventTool\"";
    $uf_vcproj[$i++] = "				Description=\"Renaming BuildLog.htm....\"/>";
   # $uf_vcproj[$i++] = "				CommandLine=\"copy  \$(OutDir)\\BuildLog.htm \$(OutDir)\\".$$uf_name."_BuildLog.htm\"/>";
    $uf_vcproj[$i++] = "			<Tool";
    $uf_vcproj[$i++] = "				Name=\"VCPreBuildEventTool\"/>";
    $uf_vcproj[$i++] = "			<Tool";
    $uf_vcproj[$i++] = "				Name=\"VCPreLinkEventTool\"/>";
    $uf_vcproj[$i++] = "			<Tool";
    $uf_vcproj[$i++] = "				Name=\"VCResourceCompilerTool\"/>";
    $uf_vcproj[$i++] = "			<Tool";
    $uf_vcproj[$i++] = "				Name=\"VCWebServiceProxyGeneratorTool\"/>";
    $uf_vcproj[$i++] = "			<Tool";
    $uf_vcproj[$i++] = "				Name=\"VCWebDeploymentTool\"/>";
    $uf_vcproj[$i++] = "		</Configuration>";
    $uf_vcproj[$i++] = "	</Configurations>";
    $uf_vcproj[$i++] = "	<Files>";
    $uf_vcproj[$i++] = "		<Filter";
    $uf_vcproj[$i++] = "			Name=\"Source Files\"";
    $uf_vcproj[$i++] = "			Filter=\"cpp;c;cxx;def;odl;idl;hpj;bat;asm\">";
    $uf_vcproj[$i++] = "			<File";
    $uf_vcproj[$i++] = "				RelativePath=\"".$$uf_name.".cpp\">";
    $uf_vcproj[$i++] = "			</File>";
    $uf_vcproj[$i++] = "		</Filter>";
    $uf_vcproj[$i++] = "		<Filter";
    $uf_vcproj[$i++] = "			Name=\"Header Files\"";
    $uf_vcproj[$i++] = "			Filter=\"h;hpp;hxx;hm;inl;inc\">";
    $uf_vcproj[$i++] = "			<File";
    $uf_vcproj[$i++] = "				RelativePath=\"".$$uf_name.".h\">";
    $uf_vcproj[$i++] = "			</File>";
    $uf_vcproj[$i++] = "		</Filter>";
    $uf_vcproj[$i++] = "		<Filter";
    $uf_vcproj[$i++] = "			Name=\"Resource Files\"";
    $uf_vcproj[$i++] = "			Filter=\"rc;ico;cur;bmp;dlg;rc2;rct;bin;rgs;gif;jpg;jpeg;jpe\">";
    $uf_vcproj[$i++] = "		</Filter>";
    $uf_vcproj[$i++] = "		<File";
    $uf_vcproj[$i++] = "			RelativePath=\"ReadMe.txt\">";
    $uf_vcproj[$i++] = "		</File>";
    $uf_vcproj[$i++] = "	</Files>";
    $uf_vcproj[$i++] = "	<Globals>";
    $uf_vcproj[$i++] = "	</Globals>";
    $uf_vcproj[$i++] = "</VisualStudioProject>";
    $uf_vcproj[$i++] = "";

    $uf_vcproj_file = $$uf_name.".vcproj";

    open(VCPROJ, "> $uf_vcproj_file");
    $, = "\n";
    print VCPROJ @uf_vcproj, "\n";
    close(VCPROJ);
}

sub build_uf_cpp_and_h {
    my($uf_name) = @_;
    my(@cpp, @h, $i, $cap_uf_name, $h_file, $cpp_file);

    $cap_uf_name = $$uf_name;
    $cap_uf_name =~ tr/a-z/A-Z/;
    $h_file = $$uf_name.".h";
    $cpp_file = $$uf_name.".cpp";

    $i = 0;
    $h[$i++] = "#ifndef __".$cap_uf_name."_H__";
    $h[$i++] = "#define __".$cap_uf_name."_H__";
    $h[$i++] = "\n";

    $h[$i++] = "//This section is for OASIS Include File Declaration";
    $h[$i++] = "#ifndef CORE_H";
    $h[$i++] = "# include \"OAI/core/core.h\"";
    $h[$i++] = "#endif CORE_H";
    $h[$i++] = "\n";
    $h[$i++] = "#ifdef _TSS201A";
    $h[$i++] = "#ifndef TEST_H";
    $h[$i++] = "#include \"OAI/TestClasses/Test.h\"";
    $h[$i++] = "#endif //!TEST_H";
    $h[$i++] = "#else";
    $h[$i++] = "#ifndef TEST_H";
    $h[$i++] = "#include \"OAI/core/Test.h\"";
    $h[$i++] = "#endif //!TEST_H";
    $h[$i++] = "#endif";
    $h[$i++] = "\n";
    $h[$i++] = "#ifndef BURST_H";
    $h[$i++] = "#include \"OAI/core/Burst.h\"";
    $h[$i++] = "#endif //!BURST_H";
    $h[$i++] = "\n";
    $h[$i++] = "#ifndef TESTPLAN_H";
    $h[$i++] = "#include \"OAI/core/TestPlan.h\"";
    $h[$i++] = "#endif";
    $h[$i++] = "\n";
    $h[$i++] = "//Begin CorTeX Specific Includes";
    $h[$i++] = "//cortex.h defines all Fundamental CorTeX data structures";
    $h[$i++] = "#include <cortex.h>";
    $h[$i++] = "#include <GEN_core_ifc.h>";
    $h[$i++] = "#include <GEN_global.h>";
    $h[$i++] = "#include <GEN_global_ifc.h>";
    $h[$i++] = "#include <OASIS_core.h>";
    $h[$i++] = "//End CorTeX Specific Includes";
    $h[$i++] = "#ifdef __".$cap_uf_name."_DLL__";
    $h[$i++] = "#define ".$cap_uf_name."_EXPORT __declspec(dllexport)";
    $h[$i++] = "#else";
    $h[$i++] = "#define ".$cap_uf_name."_EXPORT __declspec(dllimport)";
    $h[$i++] = "#endif";
    $h[$i++] = "extern \"C\"";
    $h[$i++] = "{";
    $h[$i++] = "    //List all functions to be exported here";
    $h[$i++] = "    //For example,";
    $h[$i++] = "    //IAPP_USERFUNC_EXPORT int PrePlistUF()";
    $h[$i++] = "    ".$cap_uf_name."_EXPORT int ReplaceMeWithRealFunctionName()\;";
    $h[$i++] = "}";
    $h[$i++] = "#endif  //__".$cap_uf_name."_H__";

    open(HFILE, "> $h_file");
    $, = "\n";
    print HFILE @h, "\n";
    close(HFILE);

    $i = 0;
    $cpp[$i++] = "#include \"".$h_file."\"";
    $cpp[$i++] = "\n";
    $cpp[$i++] = "//Insert User Function name in the line below";
    $cpp[$i++] = "int ReplaceMeWithRealFunctionName()";
    $cpp[$i++] = "{";
    $cpp[$i++] = "\n";
    $cpp[$i++] = "    iCGENGlobal\* pCorTeXGenGlobal = NULL\;";
    $cpp[$i++] = "    iCGENGlobalIfc\* pCorTeXOasisGlobal = NULL\;";
    $cpp[$i++] = "    iCGENCoreIfc\* pCurrentPlatformCore = NULL\;";
    $cpp[$i++] = "    iCString sArgs, sTmp\;";
    $cpp[$i++] = "\n";
    $cpp[$i++] = "    if (NULL == pCorTeXGenGlobal)";
    $cpp[$i++] = "    {\n";
    $cpp[$i++] = "        gGetCorTeXGlobal(pCorTeXGenGlobal)\;";
    $cpp[$i++] = "    }";
    $cpp[$i++] = "    if (NULL == pCorTeXOasisGlobal)";
    $cpp[$i++] = "    {";
    $cpp[$i++] = "        pCorTeXOasisGlobal = pCorTeXGenGlobal->iC_pGetComplementGlobal()\;";
    $cpp[$i++] = "    }";
    $cpp[$i++] = "\n";
    $cpp[$i++] = "    if ((NULL != pCorTeXGenGlobal)&&(NULL != pCorTeXOasisGlobal))";
    $cpp[$i++] = "    {";
    $cpp[$i++] = "        pCorTeXOasisGlobal->iC_zGetCurrentGENCoreIfc(pCurrentPlatformCore)\;";
    $cpp[$i++] = "\n";
    $cpp[$i++] = "        if (pCurrentPlatformCore != NULL)";
    $cpp[$i++] = "        {";
    $cpp[$i++] = "            pCorTeXGenGlobal->m_zGetUserFuncParam(sArgs)\;";
    $cpp[$i++] = "            sTmp = \"PreInstance UF Arguments are << \"+sArgs\;";
    $cpp[$i++] = "            sTmp += \" >>\\n\"\;";
    $cpp[$i++] = "            pCurrentPlatformCore->iC_zPrint(sTmp)\;";
    $cpp[$i++] = "        }";
    $cpp[$i++] = "    }";
    $cpp[$i++] = "\n";
    $cpp[$i++] = "    //Insert user function code here";
    $cpp[$i++] = "\n\n\n";
    $cpp[$i++] = "    //End of user function code";
    $cpp[$i++] = "\n\n\n";
    $cpp[$i++] = "    return 1\;";
    $cpp[$i++] = "}";
    $cpp[$i++] = "\n";

    open(CPPFILE, "> $cpp_file");
    $, = "\n";
    print CPPFILE @cpp, "\n";
    close(CPPFILE);
}
exit;


#***********************************************************
 # NOTE: Please do not modify Revision History Directly via your editor.
 # Please only modify via CVS tools.

 # Revision History
 # $Log: build_uf_frame.pl,v $
 # Revision 2.1.24.1.12.2.6.1  2007/07/14 06:13:57  zrouf
 # HSD_ID:3602
 #
 # CHANGE_DESCRIPTION:Updated script so that it creates VS2005 compatible vcproj file. Also updated script so that it does not try to delete the buildlog.htm file after the build as these files are now locked by devenv
 #
 # REG_TEST:
 #
 # Revision 2.1.24.1.12.2  2007/01/11 21:16:27  pjkransd
 # HSD_ID:3602
 #
 # CHANGE_DESCRIPTION:Fixed "Rev4.0" to "Rev4." so that all 4.X releases would be recognized as needing the VS 7.1 vcproj frame.
 #
 # REG_TEST:
 #
 # Revision 2.1.24.1.12.1  2006/10/12 17:46:57  amathur1
 # HSD_ID:3238
 #
 # CHANGE_DESCRIPTION:
 # Removing Preprocessor _PRE_TSS201A_ code from cvs since building 4.8 only on TSS204 onwards TSS
 #
 # REG_TEST:
 #
 # Revision 2.1.24.1  2006/03/21 23:46:56  mmohan3
 # HSD_ID:1958
 #
 # CHANGE_DESCRIPTION:Updated for support for TSS1.04/3.10/Vs 2002 and TS 2.01/4.0/VS 2003 vcproject file generation
 #
 # REG_TEST:
 #
 # Revision 2.1.20.1  2006/03/16 21:23:56  mmohan3
 # HSD_ID:1958
 #
 # CHANGE_DESCRIPTION:updated script to generate 3x and 4x project files in VS 2002 and 2003 respectively
 #
 # REG_TEST:
 #
 # Revision 2.1  2004/10/28 21:01:34  rflore2
 # CHANGE_ID: TES00001756
 #  CHANGE_DESCRIPTION:
 #   Initial Revision
 #  REG_TEST:
 #   None
 #
 #***********************************************************
