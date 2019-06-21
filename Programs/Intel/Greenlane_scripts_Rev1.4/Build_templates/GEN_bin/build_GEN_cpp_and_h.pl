#----------------------------------------------------------------------;
#
#        FILENAME:      build_GEN_cpp_and_h.pl
#        FILE REV:      $Revision: 2.5.52.1.2.1 $
#         S/W REV:      perl
#    COMPILER REV:      n/a
#     LAST UPDATE:      27-Feb-2004
#  LAST UPDATE BY:      Sundar (sundar.lakshmipathy@intel.com)
#      CREATED BY:      Sundar (sundar.lakshmipathy@intel.com)
#
#        ABSTRACT:      This perl script creates a test class cpp file from .ph
#
#----------------------------------------------------------------------;
#
#use strict;

# load modules
use Win32::OLE;
use Cwd;
use File::Copy;
use File::Compare;
use File::Temp qw/ tempfile tempdir /;
use File::Path;

# load modules
#use lib 'c:/intel/tpapps/CorTeX/GEN/GEN_bin';;
#use lib 'i:/tpapps/CorTeX/GEN/GEN_bin';
use CorTeXPerlModule;

my (@c, $l,$current_pgm, $pgm_offset,$pgm_dir,$frame_cpp, @testmethods,$testmethod,$phfile_prefix,$phtestclass,$tmp_string,$testname);
my ($force,$errorflag,@cpp_files,$cpp,%phtestclass_names,%param_details,$timestamp);


$c[++$l] = "build_GEN_cpp_and_h version: 1.0 ";
$c[++$l] = "build_GEN_cpp_and_h -t <testmethod>";
$c[++$l] = "    CorTeX Wizard for creating GEN_<testmethod>_tt.h & GEN_<testmethod>_tt.cpp ";
$c[++$l] = "    files from the input GEN_<testmethod>_tt.ph file                       ";
$c[++$l] = "                                                                          ";
$c[++$l] = "    -t <testmethod> is a required param which specifies the test method   ";
$c[++$l] = "       for which the OASIS ph and cpp files are generated.                ";
$c[++$l] = "       VERY VERY IMPORTANT....                                            ";
$c[++$l] = "       DO NOT specify GEN_<testmethod> or OASIS_<testmethod> against the  ";
$c[++$l] = "       -t option.  It must be just the <testmethod>, because file names   ";
$c[++$l] = "       are dervied automatically from the input <testmethod>. It is always";
$c[++$l] = "       GEN_<testmethod>_tt.ph , GEN_<testmethod>_tt.ph & .cpp ";
$c[++$l] = "                                                                          ";
$c[++$l] = "    The generated .h file has all the class details filled in based on    ";
$c[++$l] = "    test template interface parameters specified in the .ph file.         ";
$c[++$l] = "    It also creates ENUMs based on AVATOR_OPTIONS list...                 ";
$c[++$l] = "    The generated file is 100\% compatible with CorTeX 2.0 Framework.     ";
$c[++$l] = "                                                                          ";
$c[++$l] = "    The generated .cpp file has all the basic methods needed for being    ";
$c[++$l] = "    compliant with CorTeX 2.0 framework.                                  ";
$c[++$l] = "                                                                          ";
$c[++$l] = "                                                                          ";
$c[++$l] = "                                                                          ";

$current_pgm = $0;
$pgm_offset = index($current_pgm,"build_GEN_cpp_and_h.pl");
$pgm_dir = substr($current_pgm,0,$pgm_offset);
$frame_cpp = $pgm_dir."GEN_frame_tt.cpp";
$frame_h = $pgm_dir."GEN_frame_tt.h";

if (!(-e $frame_cpp))
{
  print STDERR"Cannot find \"GEN_frame_tt.cpp\" in the same directory \"$pgm_dir\" as the script....\n";
  exit;
}

if (!(-e $frame_h))
{
  print STDERR"Cannot find \"GEN_frame_tt.h\" in the same directory \"$pgm_dir\" as the script....\n";
  exit;
}


if ($#ARGV < 0)
{
    $, = "\n";
    print STDERR@c,"\n\n";
    print STDERR"Illegal command line options...\n";
    print STDERR"There must be only one argument specified...\n";
    exit;
}

my(%all_options, %option, @all_args);
CorTeXPerlModule::getOptions(\@ARGV,\%all_options, \%option, \@all_args);


if (!($all_options{t}))
  { ##If the -t option is not specified...
    $, = "\n";
    print STDERR@c,"\n\n";
    print STDERR"Illegal command line options...\n";
    print STDERR"There must be a testmethod specified using -t option...\n";
    exit;
  }
else
  { ## check if the argument begins with GEN or OASIS..if so error out...
    if (($option{t} =~ /^GEN|OASIS/)||($option{t} =~ /_tt/)||($option{t} =~ /\.ph$/))
      {
        $, = "\n";
        print STDERR@c,"\n\n";
        printf(STDERR"Illegal format for input argument -t \"%s\".\n",$option{t});
        printf(STDERR"Please specify just the testmethod, without GEN_ or OASIS or _tt.ph\n");
        exit;
      }
    ##check if more than one testmethod is specified.
    my(@tmparray);
    @tmparray = split(/\s+/,$option{t});
    if ($#tmparray > 0)
      {
        $, = "\n";
        print STDERR@c,"\n\n";
        printf(STDERR"Illegal format for input argument -t \"%s\".\n",$option{t});
        printf(STDERR"Please specify only one testmethod.\n");
        exit;
      }
    push(@testmethods,$option{t});
  }

$timestamp = localtime();
#multiple file option disabled
##@testmethods  = @ARGV[1..$#ARGV];

foreach $testmethod(@testmethods)
  {
    my ($phfile,$phtestclass,$public_bases);
    my ($cpp,@ordered_param_list,$param,$mtime,$print_string);
    my ($param_type,$avator_type,$param_cardinality,$param_function,$param_attribute,$param_cortex_type,$param_desc);
    my (%param_details,$testclass_suffix,$old_ph_file);
    my ($param_options,$param_default,@options);
    my ($prototype,$type,$member);
    my ($param_section);
    my ($old_ph_rev_history,$revhistoryline);
    my ($done,$hfile);
    my ($phtestclass_ordered_params,$plist_vector,$tc_vector,$error_count);
    $phfile = "GEN_".$testmethod."_tt.ph";
    $TESTMETHOD = uc($testmethod);
    $error_count = 0;
    CorTeXPerlModule::parsePHfile($phfile,"1",\$phtestclass,\$public_bases,\@ordered_param_list,\%param_details,\@port_details,\@tc_vector,\@plist_vector,\$error_count,"GEN");
    if ($error_count)
      {
	      print "$error_count\n";
        print "Errors detected while parsing \"$phfile\"...exiting...\n";
        exit;
      }

    ($hfile = $phfile) =~ s/\.ph/\.h/;
    if (-e $hfile)
      {
        CorTeXPerlModule::getLastModTime($hfile,\$mtime);
        $old_h_file = $hfile."_org_".$mtime;
        rename($hfile,$old_h_file);
        undef $mtime;
      }


    printf("Generating h file <<%s>> from phfile <<%s>> with <<%s>><<%s>><<%s>>\n",$hfile,$phfile,$phtestclass,$testmethod,$TESTMETHOD);

    open (FRAMEH, $frame_h) or die "Cannot Open \"$frame_h\" for reading. Exiting....\n";
    open (H, ">$hfile") or die "Cannot Open \"$hfile\" for writing. Exiting....\n";
##    printf(H"//File Created by %s on %s\n",$current_pgm,$timestamp);
    while (<FRAMEH>)
      {
        $tmp_string = $_;
        CorTeXPerlModule::stripWhiteSpace(\$tmp_string);

        ###Find the class defintiion of iCGENFrameTest...replace :public iCGENCore with public bases list.
        if (/^class\s+GEN_FRAME_EXPORT\s+iCGENFrameTest/)
          {
            if ($public_bases)
              {
                $public_bases =~  s/\,/\, public /g;
                $public_bases = ": public ".$public_bases."\n";
                $_ =~ s/:\s*public\s+iCGENCore\s*$/$public_bases/;
              }
          }

        if (/FRAME/)
          {
            ##replace with TESTMETHOD
            $_ =~ s/FRAME/$TESTMETHOD/g;
          }

        if (/iCGENFrameTest/)
          {
            $_ =~ s/iCGENFrameTest/$phtestclass/g;
          }


        printf(H"%s",$_);
        if (/Begin_Test_Class_Specific_Enums/)
          {
            ##Now generate Enums.
            &generateEnumData($phtestclass,\%param_details,\@ordered_param_list,\$enum_print_string,\$enum_func_string,\$enum_inline_string);
            printf(H"%s\n",$enum_print_string);
            printf(H"\n");
          }
        elsif (/Begin_Test_Class_Specific_Enum_Functions/)
          {
            ##Now generate Enum Functions.
            printf(H"%s\n",$enum_func_string);
            printf(H"\n");
          }
        elsif (/Begin_Test_Class_Interface_Attributes/)
          {
            ##Now generate Test template interface attributes
            &generateTestClassInterfaceAttributes($phtestclass,\%param_details,\@ordered_param_list,\$interface_attributes_string);
            printf(H"%s\n",$interface_attributes_string);
            printf(H"\n");
          }
        elsif (/Begin_Inline_Enum_Functions/)
          {
            ##Now generate Inline code for Enum Functions
            printf(H"%s\n",$enum_inline_string);
            printf(H"\n");
          }
      }
    close FRAMEH;
    close H;


    ($cppfile = $phfile) =~ s/\.ph/\.cpp/;
    if (-e $cppfile)
      {
        CorTeXPerlModule::getLastModTime($cppfile,\$mtime);
        $old_cpp_file = $cppfile."_org_".$mtime;
        rename($cppfile,$old_cpp_file);
        undef $mtime;
      }

    printf("Generating cpp file <<%s>> from phfile <<%s>> with <<%s>><<%s>><<%s>>\n",$cppfile,$phfile,$phtestclass,$testmethod,$TESTMETHOD);

    open (FRAMECPP, $frame_cpp) or die "Cannot Open \"$frame_cpp\" for reading. Exiting....\n";
    open (CPP, ">$cppfile") or die "Cannot Open \"$cppfile\" for writing. Exiting....\n";
##    printf(CPP"//File Created by %s on %s\n",$current_pgm,$timestamp);
    if($phtestclass !~ /^iCGEN.*Test$/)
    {
      print "\n<error> TestClass value in GEN ph file must have the format iCGEN<template>Test\n";
      $errorflag++;
    }
    ($factoryname = $phtestclass) =~ s/iC//;
    while (<FRAMECPP>)
      {
        $tmp_string = $_;
        CorTeXPerlModule::stripWhiteSpace(\$tmp_string);
        if (/frame/)
          {
            ##replace with testmethod
            $_ =~ s/frame/$testmethod/g;
          }
        if (/FRAME/)
          {
            ##replace with TESTMETHOD
            $_ =~ s/FRAME/$TESTMETHOD/g;
          }
        if (/iCGENFrameTest/)
          {
            $_ =~ s/iCGENFrameTest/$phtestclass/g;
          }
        if (/gCreateGENFrameTest/)
          {
            $_ =~ s/GENFrameTest/$factoryname/g;
          }

        printf(CPP"%s",$_);

        if (/Begin_test_template_intefrace_attribute_initialization/)
          {
            #Constructor Initialization
            &generateConstructorDefaults($phtestclass,\%param_details,\@ordered_param_list,\$param_default_print_string);
            printf(CPP"%s",$param_default_print_string);
          }
        elsif (/Begin_test_template_set_param/)
          {
            #iC_tSetTpParam content generation
            &generateSetParamString($phtestclass,\%param_details,\@ordered_param_list,\$SetParamString);
            printf(CPP"%s",$SetParamString);

          }
        elsif (/Begin_test_template_get_param/)
          {
            #iC_tGetTpParam content generation
            &generateGetParamString($phtestclass,\%param_details,\@ordered_param_list,\$GetParamString);
            printf(CPP"%s",$GetParamString);
          }
        elsif (/Begin_test_template_parameter_verification/)
          {
            #iC_tVerify content generation
            &generateVerifyString($phtestclass,\%param_details,\@ordered_param_list,\$VerifyString);
            printf(CPP"%s",$VerifyString);
          }
      }
    close CPP;
    close FRAMECPP;



  }

if ($errorflag)
  {
    print "Errors detected...exiting...\n";
    exit;
  }

exit;
sub generateEnumData
  {
    my($phtestclass,$param_details,$params,$enum_print_string,$enum_func_string,$enum_inline_string) = @_;
    my($param);
    my ($param_type,$avator_type,$param_cardinality,$param_function,$param_attribute,$param_cortex_type,$param_desc);
    my ($param_options,$param_default,@options);
    my ($CORTEX_TYPE);
    my ($tmpstr1,$tmpstr2);
    my (@enum_values,@avator_options,$undefined_enum,$inline_string,$enum_value,$stripped_attribute);

    $$enum_print_string = "";
    $$enum_func_string = "";
    $$enum_inline_string = "";

    foreach $param(@$params)
      {
        undef $param_default;
        undef $param_options;
        ($param_type,$avator_type,$param_cardinality,$param_attribute,$param_cortex_type,$param_function,$param_desc,$param_default,$param_options) = split(/\|/,$$param_details{$param});
        if ($param_options)
          {
            @options = split(/&/,$param_options);
            undef @enum_values;
            undef @avator_options;
            if ($param_cortex_type ne "bool")
              { ##then it is an enum
                ($CORTEX_TYPE = $param_cortex_type) =~ s/^iT/iT_/;
                $CORTEX_TYPE = uc($CORTEX_TYPE);
                $$enum_print_string .= sprintf("    enum %s\n",$param_cortex_type);
                $$enum_print_string .= sprintf("    {\n");
                for ($i = 0; $i <= ($#options); $i++) {
                  $tmpstr1 = sprintf("%s_%s,",$CORTEX_TYPE,uc($options[$i]));
                  $tmpstr2 = sprintf("//AVATOR_OPTION    %-20s  = %d",$options[$i],$i);
                  $$enum_print_string .= sprintf("       %-40s   %-s\n",$tmpstr1,$tmpstr2);
                  ($enum_value = $tmpstr1) =~ s/,$//;
                  push(@enum_values,$enum_value);
                  push(@avator_options,$options[$i]);
                }
                $undefined_enum = sprintf("%s_UNDEFINED,",$CORTEX_TYPE);
                $$enum_print_string .= sprintf("       %s_UNDEFINED = -1       \n", $CORTEX_TYPE);
                $$enum_print_string .= sprintf("    };\n\n");
                $undefined_enum =~ s/,$//;
                $enum_value = $undefined_enum;
                push(@enum_values,$enum_value);
                push(@avator_options,"UNDEFINED");
                $$enum_func_string .= sprintf("    static void m_zGet%sEnum(const iCString& sString, %s& tEnum);\n",$param_cortex_type,$param_cortex_type);
                $$enum_func_string .= sprintf("    static void m_zGet%sString(%s tEnum, iCString& sString, bool bGetAvatorString = true);\n\n",$param_cortex_type,$param_cortex_type);
                &generateInline($phtestclass,$param_cortex_type,\@enum_values,$undefined_enum,\@avator_options,\$inline_string);
                $$enum_inline_string .= $inline_string;
              }
            else
              {
                my($true,$false,$UCOPTION);
                for ($i = 0; $i <= ($#options); $i++)
                  {
                    $UCOPTION = uc($options[$i]);
                    if ($UCOPTION =~ /YES|TRUE|ON|ENABLE/)
                      {
                        $true = $options[$i];
                      }
                    else    ###($UCOPTION =~ /NO|FALSE|OFF|DISABLE/)  it will not reach here without the above match
                      {
                        $false = $options[$i];
                      }
                  }
                $tmpstr1 = sprintf("%s_%s,",$CORTEX_TYPE,uc($options[$i]));
                push(@enum_values,$optionsenum_value);
                push(@avator_options,$options[$i]);
                ($stripped_attribute = $param_attribute) =~ s/^m_.//;
                $stripped_attribute = ucfirst($stripped_attribute);
                $$enum_func_string .= sprintf("    static void m_zGet%sBool(const iCString& sString, bool& bBoolean);\n",$stripped_attribute);
                $$enum_func_string .= sprintf("    static void m_zGet%sString(bool bBoolean, iCString& sString, bool bGetAvatorString = true);\n\n",$stripped_attribute);
                &generateInlineForBool($phtestclass,$stripped_attribute,$true,$false,\$inline_string);
                $$enum_inline_string .= $inline_string;
              }

          }
      }
  }




sub generateInlineForBool
  {
    my($class,$stripped_attribute,$true,$false,$enum_inline_string) = @_;
    $$enum_inline_string = "";
    $$enum_inline_string .= sprintf("inline void %s::m_zGet%sBool(const iCString& sString, bool& bBoolean)\n",$class,$stripped_attribute);
    $$enum_inline_string .= sprintf("{\n");
    $$enum_inline_string .= sprintf("    if (\"%s\" == sString)\n",$true);
    $$enum_inline_string .= sprintf("    {\n");
    $$enum_inline_string .= sprintf("        bBoolean = true;\n");
    $$enum_inline_string .= sprintf("    }\n");
    $$enum_inline_string .= sprintf("    else \n");
    $$enum_inline_string .= sprintf("    {\n");
    $$enum_inline_string .= sprintf("        bBoolean = false;\n");
    $$enum_inline_string .= sprintf("    }\n");
    $$enum_inline_string .= sprintf("}\n\n");

    $$enum_inline_string .= sprintf("inline void %s::m_zGet%sString(bool bBoolean, iCString& sString, bool bGetAvatorString)\n",$class,$stripped_attribute);
    $$enum_inline_string .= sprintf("{\n");
    $$enum_inline_string .= sprintf("    if (true == bBoolean)\n");
    $$enum_inline_string .= sprintf("    {\n");
    $$enum_inline_string .= sprintf("        sString = \"%s\";\n",$true);
    $$enum_inline_string .= sprintf("    }\n");
    $$enum_inline_string .= sprintf("    else \n");
    $$enum_inline_string .= sprintf("    {\n");
    $$enum_inline_string .= sprintf("        sString = \"%s\";\n",$false);
    $$enum_inline_string .= sprintf("    }\n");
    $$enum_inline_string .= sprintf("}\n\n");
  }



sub generateInline
  {
    my($class,$enum,$enum_values,$undefined_enum,$avator_options,$enum_inline_string) = @_;
    my(@enum_values_array,@avator_options_array,$ifstring,$ENUM);
    @enum_values_array = @$enum_values;
    @avator_options_array = @$avator_options;
    $$enum_inline_string = "";
    $$enum_inline_string .= sprintf("inline void %s::m_zGet%sEnum(const iCString& sString, %s& tEnum)\n",$class,$enum,$enum);
    $$enum_inline_string .= sprintf("{\n");
    $ifstring = "if";
    for ($i = 0; $i <= $#enum_values_array; $i++)
      {
        if ($i > 0)
          {
            $ifstring = "else if";
          }
        $$enum_inline_string .= sprintf("   %s ((\"%s\" == sString)||(\"%s\" == sString))\n",$ifstring,$enum_values_array[$i],$avator_options_array[$i]);
        $$enum_inline_string .= sprintf("   {\n");
        $$enum_inline_string .= sprintf("       tEnum = %s;\n",$enum_values_array[$i]);
        $$enum_inline_string .= sprintf("   }\n");
      }
    $$enum_inline_string .= sprintf("   else\n");
    $$enum_inline_string .= sprintf("   {\n");
    $$enum_inline_string .= sprintf("       tEnum = %s;\n",$undefined_enum);
    $$enum_inline_string .= sprintf("   }\n");
    $$enum_inline_string .= sprintf("}\n\n");

    $$enum_inline_string .= sprintf("inline void %s::m_zGet%sString(%s tEnum, iCString& sString, bool bGetAvatorString)\n",$class,$enum,$enum);
    $$enum_inline_string .= sprintf("{\n");
    $$enum_inline_string .= sprintf("    switch (tEnum)\n");
    $$enum_inline_string .= sprintf("    {\n");
    $i = 0;
    foreach $key(@enum_values_array)
      {
        $$enum_inline_string .= sprintf("       case %s:\n",$key);
        $$enum_inline_string .= sprintf("       {\n");
        $$enum_inline_string .= sprintf("           if (bGetAvatorString)\n");
        $$enum_inline_string .= sprintf("           {\n");
        $$enum_inline_string .= sprintf("               sString = \"%s\";\n",$avator_options_array[$i]);
        $$enum_inline_string .= sprintf("           }\n");
        $$enum_inline_string .= sprintf("           else\n");
        $$enum_inline_string .= sprintf("           {\n");
        $$enum_inline_string .= sprintf("               sString = \"%s\";\n",$key);
        $$enum_inline_string .= sprintf("           }\n");
        $$enum_inline_string .= sprintf("           break;\n");
        $$enum_inline_string .= sprintf("       }\n");
        $i++;
      }
    $$enum_inline_string .= sprintf("       default:\n");
    $$enum_inline_string .= sprintf("       {\n");
    $ENUM = uc($enum);
    if ($ENUM !~ /^IT_/)
      {
        $ENUM =~ s/^IT/IT_/;
      }
    $$enum_inline_string .= sprintf("           sString = \"%s_UNKNOWN\";\n",$ENUM);
    $$enum_inline_string .= sprintf("           break;\n");
    $$enum_inline_string .= sprintf("       }\n");
    $$enum_inline_string .= sprintf("    }\n");
    $$enum_inline_string .= sprintf("}\n");
  }



sub generateTestClassInterfaceAttributes
  {
    my($phtestclass,$param_details,$params,$interface_attributes_string) = @_;
    my($param);
    my ($param_type,$avator_type,$param_cardinality,$param_function,$param_attribute,$param_cortex_type,$param_desc);
    my ($param_options,$param_default,@options);
    my ($CORTEX_TYPE);
    my ($tmpstr1,$tmpstr2,$pin_param_attribute);

    $$interface_attributes_string = "";

    foreach $param(@$params)
      {
        undef $param_default;
        undef $param_options;
        ($param_type,$avator_type,$param_cardinality,$param_attribute,$param_cortex_type,$param_function,$param_desc,$param_default,$param_options) = split(/\|/,$$param_details{$param});

        $tmpstr1 = sprintf("%s %s;",$param_cortex_type,$param_attribute);
        $tmpstr2 = sprintf("//Interface Param %s",$param);
        $$interface_attributes_string .= sprintf("    %-40s  %s\n",$tmpstr1,$tmpstr2);
        if ($avator_type eq "PIN")
          {
            ##Add additional member variable for iCGENPinInfo*
            ($pin_param_attribute = $param_attribute) =~ s/^m_s/m_p/;
            $tmpstr1 = sprintf("const iCGENPinInfo*  %s;",$pin_param_attribute);
            $tmpstr2 = sprintf("//PinInfo Pointer for Interface Param %s",$param);
            $$interface_attributes_string .= sprintf("    %-40s  %s\n",$tmpstr1,$tmpstr2);
          }
      }
  }



sub generateConstructorDefaults
  {
    my($phtestclass,$param_details,$params,$param_default_print_string) = @_;
    my($param);
    my ($param_type,$avator_type,$param_cardinality,$param_function,$param_attribute,$param_cortex_type,$param_desc);
    my ($param_options,$param_default,@options);
    my ($CORTEX_TYPE);
    my ($tmpstr1,$tmpstr2,$pin_param_attribute);
    my (@enum_values,@avator_options,$undefined_enum,$inline_string,$enum_value);

    foreach $param(@$params)
      {
        undef $param_default;
        undef $param_options;
        ($param_type,$avator_type,$param_cardinality,$param_attribute,$param_cortex_type,$param_function,$param_desc,$param_default,$param_options) = split(/\|/,$$param_details{$param});
        if ($param_options)
          { ##then it is an enum
            ($CORTEX_TYPE = $param_cortex_type) =~ s/^iT/iT_/;
            $CORTEX_TYPE = uc($CORTEX_TYPE);
            if (($param_cardinality eq "0-1")||($param_cardinality eq "0-n"))
              {
                if ($param_default ne "")
                  {
                    ###now ensure that param_default is available in options.
                    undef $found_param_default;
                    @options = split(/&/,$param_options);
                    for ($i = 0; $i <= ($#options); $i++)
                      {
                        if ($param_default eq $options[$i])
                          {
                            $found_param_default = 1;
                            last;
                          }
                      }
                    if (!($found_param_default))
                      {
                        printf("ERROR::Param %s has %s as default which is not found in the param options specified\n",
                               $param,$param_default);
                        next;  ##skip to next param
                      }
                  }
                else
                  {
                    printf("ERROR::Param %s has %s as cardinality but param_default is not specified...\n",
                           $param,$param_cardinality);
                    next;  ##skip to next param
                  }

                if ($param_cortex_type eq "bool")
                  {
                    $param_default = uc($param_default);
                    if ($param_default =~ /YES|TRUE|ON|ENABLE/)
                      {
                        $param_enum_default = "true";
                      }
                    else    ###($UCOPTION =~ /NO|FALSE|OFF|DISABLE/)  it will not reach here without the above match
                      {
                        $param_enum_default = "false";
                      }
                  }
                else
                  {
                    $param_enum_default = sprintf("%s_%s",$CORTEX_TYPE,$param_default);
                  }
                $print_string = sprintf("    %s = %s;\n",$param_attribute,$param_enum_default);
              }
            else
              {
                if ($param_cortex_type eq "bool")
                  {
                    $param_enum_default = "false";
                  }
                else
                  {
                    ### Put down undefined enum as the constructor initialization.
                    $param_enum_default = sprintf("%s_UNDEFINED",$CORTEX_TYPE,$param_default);
                  }
                $print_string = sprintf("    %s = %s;\n",$param_attribute,$param_enum_default);
              }
          }
        elsif ($avator_type eq "LEVEL_TESTCONDITION")
          {
            $print_string = sprintf("    %s.m_tType = IT_LEVELS;\n",$param_attribute);
          }
        elsif ($avator_type eq "TIMING_TESTCONDITION")
          {
            $print_string = sprintf("    %s.m_tType = IT_TIMING;\n",$param_attribute);
          }
        elsif ($avator_type eq "PLIST")
          {
            $print_string = sprintf("    %s.m_tType = IT_PLIST;\n",$param_attribute);
          }
        elsif ($avator_type eq "PIN")
          {
            ##Check the cortex type before initializing
            if ($param_cortex_type eq "iCString")
              {
                $print_string = sprintf("    %s = \"\";\n",$param_attribute);
                ($pin_param_attribute = $param_attribute) =~ s/^m_s/m_p/;
                $print_string .= sprintf("    %s = NULL;\n",$pin_param_attribute);
              }
            else
              {
                $print_string = sprintf("//Please insert attribute initialization for \"%s\" here..\n",$param_attribute);
              }
          }
        elsif ($avator_type eq "FUNCTION")
          {
            $print_string = sprintf("    %s.m_tType = IT_FUNCTION;\n",$param_attribute);
          }
        elsif ($avator_type eq "STRING")
          {
            if ($param_default)
              {
                $print_string = sprintf("    %s = \"%s\";\n",$param_attribute,$param_default);
              }
            else
              {
                $print_string = sprintf("    %s = \"\";\n",$param_attribute);
              }
          }
        elsif ($avator_type eq "INTEGER")
          {
            if ($param_default ne "")
#            if ($param_default)
              {
                $print_string = sprintf("    %s = %s;\n",$param_attribute,$param_default);
              }
            else
              {
                $print_string = sprintf("    %s = IT_UNDEFINED_INT;\n",$param_attribute);
              }
          }
        elsif ($avator_type eq "DOUBLE")
          {
            if ($param_default ne "")
#            if ($param_default)
              {
                $print_string = sprintf("    %s = %s;\n",$param_attribute,$param_default);
              }
            else
              {
                $print_string = sprintf("    %s = IT_UNDEFINED_DBL;\n",$param_attribute);
              }
          }
        $$param_default_print_string .= $print_string;
      }
  }


sub generateSetParamString
  {
    my($phtestclass,$param_details,$params,$SetParamString) = @_;
    my($param);
    my ($param_type,$avator_type,$param_cardinality,$param_function,$param_attribute,$param_cortex_type,$param_desc);
    my ($param_options,$param_default,@options);
    my ($CORTEX_TYPE);
    my ($tmpstr1,$tmpstr2,$ifstring,$i);
    my (@enum_values,@avator_options,$undefined_enum,$inline_string,$enum_value,$stripped_attribute,$tab_string);
    $i = 0;
    $ifstring = "if";
    foreach $param(@$params)
      {
        undef $param_default;
        undef $param_options;
        undef $tab_string;
        if ($i++ > 0)
          {
            $ifstring = "else if";
          }
        ($param_type,$avator_type,$param_cardinality,$param_attribute,$param_cortex_type,$param_function,$param_desc,$param_default,$param_options) = split(/\|/,$$param_details{$param});

        $print_string  = sprintf("        %s (\"%s\" == oTpParam.m_sName)\n",$ifstring, $param);
        $print_string .= sprintf("        {\n");
        if ($param_options)
          { ##then it is an enum
            if ($param_cortex_type eq "bool")
              {
                if ($param_cardinality eq "0-1")
                  { ##Optional Parameter... Set it to default value
                    if ($param_default =~ /YES|TRUE|ON|ENABLE/)
                      {
                        $param_enum_default = "true";
                      }
                    else    ###($UCOPTION =~ /NO|FALSE|OFF|DISABLE/)  it will not reach here without the above match
                      {
                        $param_enum_default = "false";
                      }
                    $print_string .= sprintf("            %s = %s;\n",$param_attribute,$param_enum_default);
                    $print_string .= sprintf("            if ((oTpParam.m_sStrValue != \"\") && (IT_UNDEFINED_STR != oTpParam.m_sStrValue))\n");
                    $print_string .= sprintf("            {\n");
                    $tab_string = "    ";
                  }
                ($stripped_attribute = $param_attribute) =~ s/^m_.//;
                $print_string .= sprintf("            %sm_zGet%sBool(oTpParam.m_sStrValue, %s);\n",$tab_string,$stripped_attribute,$param_attribute);
                if ($tab_string ne "")
                  {
                    $print_string .= sprintf("            }\n");
                    undef $tab_string;
                  }
              }
            else
              {
                if ($param_cardinality eq "0-1")
                  { ##Optional Parameter... Set it to default value
                    ($CORTEX_TYPE = $param_cortex_type) =~ s/^iT/iT_/;
                    $CORTEX_TYPE = uc($CORTEX_TYPE);
                    $param_enum_default = sprintf("%s_%s",$CORTEX_TYPE,$param_default);
                    $print_string .= sprintf("            %s = %s;\n",$param_attribute,$param_enum_default);
                    $print_string .= sprintf("            if ((oTpParam.m_sStrValue != \"\") && (IT_UNDEFINED_STR != oTpParam.m_sStrValue))\n");
                    $print_string .= sprintf("            {\n");
                    $tab_string = "    ";
                  }
                $print_string .= sprintf("            %sm_zGet%sEnum(oTpParam.m_sStrValue, %s);\n",$tab_string,$param_cortex_type,$param_attribute);
                if ($tab_string ne "")
                  {
                    $print_string .= sprintf("            }\n");
                    undef $tab_string;
                  }
              }
          }
        elsif (($avator_type eq "LEVEL_TESTCONDITION")||
               ($avator_type eq "TIMING_TESTCONDITION")||
               ($avator_type eq "PLIST")||
               ($avator_type eq "FUNCTION"))
          {
            $print_string .= sprintf("            %s.m_pObjectPtr = NULL;\n",$param_attribute);
            if ($param_cardinality eq "0-1")
              { ##Optional Parameter... Set it to default value
                $print_string .= sprintf("            %s.m_sName = \"\";\n",$param_attribute);
                $print_string .= sprintf("            if ((oTpParam.m_sStrValue != \"\") && (IT_UNDEFINED_STR != oTpParam.m_sStrValue))\n");
                $print_string .= sprintf("            {\n");
                $tab_string = "    ";
              }
            $print_string .= sprintf("            %s%s.m_sName = oTpParam.m_sStrValue.c_str();\n",$tab_string,$param_attribute);
            if ($tab_string ne "")
              {
                $print_string .= sprintf("            }\n");
                undef $tab_string;
              }
          }
        elsif ($avator_type eq "PIN")
          {
            $print_string .= sprintf("            %s = \"\";\n",$param_attribute);
            if ($param_cardinality eq "0-1")
              { ##Optional Parameter... Set it to default value
                $print_string .= sprintf("            if ((oTpParam.m_sStrValue != \"\") && (IT_UNDEFINED_STR != oTpParam.m_sStrValue))\n");
                $print_string .= sprintf("            {\n");
                $tab_string = "    ";
              }
            $print_string .= sprintf("            %s%s = oTpParam.m_sStrValue.c_str();\n",$tab_string,$param_attribute);
            if ($tab_string ne "")
              {
                $print_string .= sprintf("            }\n");
                undef $tab_string;
              }
          }
        elsif ($avator_type eq "STRING")
          {
            if ($param_cardinality eq "0-1")
              { ##Optional Parameter... Set it to default value
                if ($param_default)
                  {
                    $print_string .= sprintf("            %s = \"%s\";\n",$param_attribute,$param_default);
                  }
                else
                  {
                    $print_string .= sprintf("            %s = \"\";\n",$param_attribute);
                  }
                $print_string .= sprintf("            if ((oTpParam.m_sStrValue != \"\") && (IT_UNDEFINED_STR != oTpParam.m_sStrValue))\n");
                $print_string .= sprintf("            {\n");
                $tab_string = "    ";
              }
            $print_string .= sprintf("            %s%s = oTpParam.m_sStrValue.c_str();\n",$tab_string,$param_attribute);
            if ($tab_string ne "")
              {
                $print_string .= sprintf("            }\n");
                undef $tab_string;
              }
          }
        elsif ($avator_type eq "INTEGER")
          {
            if ($param_cardinality eq "0-1")
              { ##Optional Parameter... Set it to default value
                if ($param_default ne "")
                  {
                    $print_string .= sprintf("            %s = %s;\n",$param_attribute,$param_default);
                  }
                else
                  {
                    $print_string .= sprintf("            %s = IT_UNDEFINED_INT;\n",$param_attribute);
                  }
                $print_string .= sprintf("            if (IT_UNDEFINED_INT != oTpParam.m_nIntValue)\n");
                $print_string .= sprintf("            {\n");
                $tab_string = "    ";
              }
            $print_string .= sprintf("            %s%s = oTpParam.m_nIntValue;\n",$tab_string,$param_attribute);
            if ($tab_string ne "")
              {
                $print_string .= sprintf("            }\n");
                undef $tab_string;
              }
          }
        elsif ($avator_type eq "DOUBLE")
          {
            if ($param_cardinality eq "0-1")
              { ##Optional Parameter... Set it to default value
                if ($param_default ne "")
                  {
                    $print_string .= sprintf("            %s = %s;\n",$param_attribute,$param_default);
                  }
                else
                  {
                    $print_string .= sprintf("            %s = IT_UNDEFINED_DBL;\n",$param_attribute);
                  }
                $print_string .= sprintf("            if (IT_UNDEFINED_DBL != oTpParam.m_dDblValue)\n");
                $print_string .= sprintf("            {\n");
                $tab_string = "    ";
              }
            $print_string .= sprintf("            %s%s = oTpParam.m_dDblValue;\n",$tab_string,$param_attribute);
            if ($tab_string ne "")
              {
                $print_string .= sprintf("            }\n");
                undef $tab_string;
              }
          }
        $print_string .= sprintf("        }\n");
        $$SetParamString .= $print_string;
      }
  }



sub generateGetParamString
  {
    my($phtestclass,$param_details,$params,$GetParamString) = @_;
    my($param);
    my ($param_type,$avator_type,$param_cardinality,$param_function,$param_attribute,$param_cortex_type,$param_desc);
    my ($param_options,$param_default,@options);
    my ($CORTEX_TYPE);
    my ($tmpstr1,$tmpstr2,$ifstring,$i);
    my (@enum_values,@avator_options,$undefined_enum,$inline_string,$enum_value,$stripped_attribute);
    $i = 0;
    $$GetParamString = "";
    $ifstring = "if";
    foreach $param(@$params)
      {
        undef $param_default;
        undef $param_options;
        if ($i++ > 0)
          {
            $ifstring = "else if";
          }
        ($param_type,$avator_type,$param_cardinality,$param_attribute,$param_cortex_type,$param_function,$param_desc,$param_default,$param_options) = split(/\|/,$$param_details{$param});
        $print_string  = sprintf("        %s (\"%s\" == oTpParam.m_sName)\n",$ifstring, $param);
        $print_string .= sprintf("        {\n");
        if ($param_options)
          { ##then it is an enum
            if ($param_cortex_type eq "bool")
              {
                ($stripped_attribute = $param_attribute) =~ s/^m_.//;
                $print_string .= sprintf("            m_zGet%sString(%s, oTpParam.m_sStrValue);\n",$stripped_attribute,$param_attribute);
              }
            else
              {
                $print_string .= sprintf("            m_zGet%sString(%s, oTpParam.m_sStrValue);\n",$param_cortex_type,$param_attribute);
              }
          }
        elsif (($avator_type eq "LEVEL_TESTCONDITION")||
               ($avator_type eq "TIMING_TESTCONDITION")||
               ($avator_type eq "PLIST")||
               ($avator_type eq "FUNCTION"))
          {
            $print_string .= sprintf("            oTpParam.m_tType = %s.m_tType;\n",$param_attribute);
            $print_string .= sprintf("            oTpParam.m_pPtrValue  = %s.m_pObjectPtr;\n",$param_attribute);
            $print_string .= sprintf("            oTpParam.m_sStrValue  = %s.m_sName.c_str();\n",$param_attribute);
          }
        elsif ($avator_type eq "PIN")
          {
            $print_string .= sprintf("            oTpParam.m_tType = IT_PIN;\n");
            $print_string .= sprintf("            oTpParam.m_pPtrValue  = NULL;\n",$param_attribute);
            $print_string .= sprintf("            oTpParam.m_sStrValue  = %s.c_str();\n",$param_attribute);
          }
        elsif ($avator_type eq "STRING")
          {
            $print_string .= sprintf("            oTpParam.m_tType = IT_STRING;\n");
            $print_string .= sprintf("            oTpParam.m_sStrValue = %s.c_str();\n",$param_attribute);
          }
        elsif ($avator_type eq "INTEGER")
          {
            $print_string .= sprintf("            oTpParam.m_tType = IT_INTEGER;\n");
            $print_string .= sprintf("            oTpParam.m_nIntValue = %s;\n",$param_attribute);
          }
        elsif ($avator_type eq "DOUBLE")
          {
            $print_string .= sprintf("            oTpParam.m_tType = IT_DOUBLE;\n");
            $print_string .= sprintf("            oTpParam.m_dDblValue = %s;\n",$param_attribute);
          }
        $print_string .= sprintf("        }\n");
        $$GetParamString .= $print_string;
      }
  }





sub generateVerifyString
  {
    my($phtestclass,$param_details,$params,$VerifyString) = @_;
    my($param);
    my ($param_type,$avator_type,$param_cardinality,$param_function,$param_attribute,$param_cortex_type,$param_desc);
    my ($param_options,$param_default,@options);
    my ($CORTEX_TYPE);
    my ($tmpstr1,$tmpstr2,$ifstring,$i,$indent,$object_kind);
    my (@enum_values,@avator_options,$undefined_enum,$inline_string,$enum_value,$stripped_attribute);
    $i = 0;
    $$VerifyString = "";
    $ifstring = "if";
    foreach $param(@$params)
      {
        undef $param_default;
        undef $param_options;
        ($param_type,$avator_type,$param_cardinality,$param_attribute,$param_cortex_type,$param_function,$param_desc,$param_default,$param_options) = split(/\|/,$$param_details{$param});
        if ($param_options)
          { ##then it is an enum
            if ($param_cortex_type eq "bool")
              {
                ($stripped_attribute = $param_attribute) =~ s/^m_.//;
                $print_string  = sprintf("    ////Autogenerated verify code for parameter \"%s\" with attribute \"%s\";\n",$param,$param_attribute);
                $print_string .= sprintf("    ////is skipped because the parameter is of boolean type\n\n");
              }
            else
              {
                $print_string  = sprintf("    ////Autogenerated verify code for parameter \"%s\" with attribute \"%s\";\n",$param,$param_attribute);
                $print_string .= sprintf("    m_zGet%sString(%s, sEnumString);\n",$param_cortex_type,$param_attribute);
                $print_string .= sprintf("    nPosition1 = sEnumString.find(\"UNKNOWN\");\n");
                $print_string .= sprintf("    nPosition2 = sEnumString.find(\"UNDEFINED\");\n");
                ;# hsd#4652; typecast needed for auto-verify() code generation
                $print_string .= sprintf("    if ((iCString::npos != (size_t)nPosition1)||(iCString::npos != (size_t)nPosition2))\n");
                $print_string .= sprintf("    {\n");
                $param_options =~ s/&/,/g;
                $print_string .= sprintf("        m_sErrorMsg = \"%s must be one of %s\";\n",$param_attribute,$param_options);
                $print_string .= sprintf("        m_zPrint(IT_ERROR_MSG,\"iC_tVerify\",m_sErrorMsg, __FILE__, __LINE__);\n");
                $print_string .= sprintf("        nErrorFlag++;\n");
                $print_string .= sprintf("    }\n");
              }
          }
        elsif (($avator_type eq "STRING")||
               ($avator_type eq "INTEGER")||
               ($avator_type eq "DOUBLE"))
          {
            $print_string = sprintf("\n    ////Please insert verify code for the parameter \"%s\" with attribute \"%s\";\n",$param,$param_attribute);
          }
        elsif (($avator_type eq "LEVEL_TESTCONDITION")||
               ($avator_type eq "TIMING_TESTCONDITION")||
               ($avator_type eq "PLIST")||
               ($avator_type eq "FUNCTION"))
          {
            if ($avator_type eq "LEVEL_TESTCONDITION")
              {
                $object_kind = "Levels";
              }
            elsif ($avator_type eq "TIMING_TESTCONDITION")
              {
                $object_kind = "Timing";
              }
            elsif ($avator_type eq "PLIST")
              {
                $object_kind = "Plist";
              }
            elsif ($avator_type eq "PIN")
              {
                $object_kind = "Pin";
              }
            elsif ($avator_type eq "FUNCTION")
              {
                $object_kind = "Function";
              }
            $print_string  = sprintf("    ////Autogenerated verify code for parameter \"%s\" with attribute \"%s\";\n",$param,$param_attribute);
            $indent = "";
            if ($param_cardinality eq "0-1")
              {##Optional Parameter.  Add check for that...
                $print_string .= sprintf("    if ((false == %s.m_sName.empty()) && (IT_UNDEFINED_STR != %s.m_sName))\n",$param_attribute,$param_attribute);
                $print_string .= sprintf("    {\n");
                $indent = "    ";
              }
            $print_string .= sprintf("%s    tRetVal = m_pCoreIfcParent->iC_tGetTpObject(%s);\n",$indent,$param_attribute);
            $print_string .= sprintf("%s    if (IT_FAIL == tRetVal)\n",$indent);
            $print_string .= sprintf("%s    {\n%s",$indent,$indent);
            $print_string .= "        m_sErrorMsg = iCString::toString(\"$object_kind Object %s is NOT defined!\",";
            $print_string .= sprintf("%s.m_sName.c_str());\n",$param_attribute);
            $print_string .= sprintf("%s        m_zPrint(IT_ERROR_MSG,\"iC_tVerify\",m_sErrorMsg, __FILE__, __LINE__);\n",$indent);
            $print_string .= sprintf("%s        nErrorFlag++;\n",$indent);
            $print_string .= sprintf("%s    }\n",$indent);
            if ($param_cardinality eq "0-1")
              {##Optional Parameter.  End the brace...
                $print_string .= sprintf("    }\n");
              }
          }
        elsif ($avator_type eq "PIN")
          {
            ($pin_param_attribute = $param_attribute) =~ s/^m_s/m_p/;
            $print_string  = sprintf("    ////Autogenerated verify code for parameter \"%s\" with attributes \"%s\" & \"%s\";\n",
                                     $param,$param_attribute,$pin_param_attribute);
            $indent = "";
            if ($param_cardinality eq "0-1")
              {##Optional Parameter.  Add check for that...
                $print_string .= sprintf("    if ((false == %s.empty()) && (IT_UNDEFINED_STR != %s))\n",$param_attribute,$param_attribute);
                $print_string .= sprintf("    {\n");
                $indent = "    ";
              }
            $print_string .= sprintf("%s    %s = NULL;\n",$indent,$pin_param_attribute);
            $print_string .= sprintf("%s    %s = ms_pPlatformGlobal->iC_pGetPinInfo(%s);\n",$indent,$pin_param_attribute,$param_attribute);
            $print_string .= sprintf("%s    if (NULL == %s)\n",$indent,$pin_param_attribute);
            $print_string .= sprintf("%s    {\n%s",$indent,$indent);
            $print_string .= "        m_sErrorMsg = iCString::toString(\"PIN Object %s is NOT defined!\",";
            $print_string .= sprintf("%s.c_str());\n",$param_attribute);
            $print_string .= sprintf("%s        m_zPrint(IT_ERROR_MSG,\"iC_tVerify\",m_sErrorMsg, __FILE__, __LINE__);\n",$indent);
            $print_string .= sprintf("%s        nErrorFlag++;\n",$indent);
            $print_string .= sprintf("%s    }\n",$indent);
            if ($param_cardinality eq "0-1")
              {##Optional Parameter.  End the brace...
                $print_string .= sprintf("    }\n");
              }
          }
        $$VerifyString .= $print_string;
      }
  }


#********************************************************
#  NOTE: Please do not modify Revision History Directly via your editor.
#  Please only modify via CVS tools.
#
#  Revision History
#  $Log: build_GEN_cpp_and_h.pl,v $
#  Revision 2.5.52.1.2.1  2007/08/25 20:52:35  spicano
#  HSD_ID:4652
#
#  CHANGE_DESCRIPTION:build_GEN_cpp_and_h.pl: typecast needed for auto-verify() code generation
#
#  REG_TEST:none
#
#  Revision 2.5.52.1  2007/01/26 02:16:42  acasti3
#  HSD_ID:3682
#
#  CHANGE_DESCRIPTION:added check for TestClass value in ph file for format iCGEN<template>Test. For optional param of type PIN, removed an extra line that is printed to cpp file and fixed the print code for checking that the parameter string is not empty.
#
#  REG_TEST:
#
#  Revision 2.5  2004/11/08 17:37:29  svpathy
#  CHANGE_ID: OVERRIDED by svpathy - NO BUGID
#   CHANGE_DESCRIPTION:(Type the desc on the next line)
#   Updated the perl script to support IT_PIN using iCString and iCGENPinInfo*
#   A test template input parameter of type AVATOR_TYPE PIN would result in
#   two variables created one with iCString as type and the other with
#   const iCGENPinInfo* as type.
#   REG_TEST:(Type on the next line)
#
#  Revision 2.4  2004/09/02 22:03:55  dhchen
#  CHANGE_ID: OVERRIDED by dhchen - NO BUGID
#   CHANGE_DESCRIPTION:(Type the desc on the next line)
#   Bug fix
#   REG_TEST:(Type on the next line)
#
#  Revision 2.3  2004/09/02 21:17:14  dhchen
#  CHANGE_ID: TES00001682
#   CHANGE_DESCRIPTION:(Type the desc on the next line)
#   New Release
#   REG_TEST:(Type on the next line)
#
#
#********************************************************
