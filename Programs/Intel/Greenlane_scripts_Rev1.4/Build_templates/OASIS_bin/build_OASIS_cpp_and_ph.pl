#----------------------------------------------------------------------;
#
#        FILENAME:      build_OASIS_cpp_and_ph.pl
#        FILE REV:      $Revision: 2.8.2.1.6.4.2.1.12.1.12.3.2.1.2.1 $
#         S/W REV:      perl
#    COMPILER REV:      n/a
#     LAST UPDATE:      01-Aug-2004
#  LAST UPDATE BY:      Sundar (sundar.v.pathy@intel.com)
#      CREATED BY:      Sundar (sundar.v.pathy@intel.com)
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


$c[++$l] = "build_OASIS_cpp_and_ph version: 1.0 ";
$c[++$l] = "build_OASIS_cpp_and_ph -g <RevX.Y.Z> -f <templatesfolder> -t <testmethod>";
$c[++$l] = "    CorTeX Wizard for creating OASIS_<testmethod>_tt.ph & OASIS_<testmethod>_tt.cpp ";
$c[++$l] = "    files from the input GEN_<testmethod>_tt.ph file                      ";
$c[++$l] = "                                                                          ";
$c[++$l] = "    -g <RevX.Y.Z> is an optional param and specifies the GEN version from  ";
$c[++$l] = "       which to lookup the GEN_<testmethod>_tt.ph files and then generate ";
$c[++$l] = "       OASIS_<testmethod>_tt.ph & OASIS_<testmethod>_tt.cpp               ";
$c[++$l] = "       Either -g or -f must be used. -g takes precedence if both are used ";
$c[++$l] = "                                                                          ";
$c[++$l] = "    -f <templatesfolder> is an optional param and specifies the absolute  ";
$c[++$l] = "       location which to lookup the GEN_<testmethod>_tt.ph files and then ";
$c[++$l] = "       generate OASIS_<testmethod>_tt.ph & OASIS_<testmethod>_tt.cpp.     ";
$c[++$l] = "       Either -g or -f must be used. -g takes precedence if both are used ";
$c[++$l] = "                                                                          ";
$c[++$l] = "    -t <testmethod> is a required param which specifies the test method   ";
$c[++$l] = "       for which the OASIS ph and cpp files are generated.                ";
$c[++$l] = "       VERY VERY IMPORTANT....                                            ";
$c[++$l] = "       DO NOT specify GEN_<testmethod> or OASIS_<testmethod> against the  ";
$c[++$l] = "       -t option.  It must be just the <testmethod>, because file names   ";
$c[++$l] = "       are dervied automatically from the input <testmethod>. It is always";
$c[++$l] = "       GEN_<testmethod>_tt.ph , OASIS_<testmethod>_tt.ph & .cpp ";
$c[++$l] = "                                                                          ";
$c[++$l] = "    The generated .ph file has all the class details filled in based on   ";
$c[++$l] = "    test template interface parameters specified in the GEN .ph file.     ";
$c[++$l] = "    It also creates ENUMs based on AVATOR_OPTIONS list...                 ";
$c[++$l] = "    The generated file is 100\% compatible with CorTeX 2.0 Framework.     ";
$c[++$l] = "                                                                          ";
$c[++$l] = "    The generated .cpp file has all the basic methods needed for being    ";
$c[++$l] = "    compliant with CorTeX 2.0 framework.                                  ";
$c[++$l] = "                                                                          ";
$c[++$l] = "    Examples";
$c[++$l] = "    build_OASIS_cpp_and_ph.pl -g Rev2.0.0 -t func                         ";
$c[++$l] = "        Creates OASIS_func_tt.cpp & OASIS_func_tt.ph from GEN version 2.0 ";
$c[++$l] = "                                                                          ";
$c[++$l] = "    build_OASIS_cpp_and_ph.pl -g Rev2.0.0 -t flowFork                     ";
$c[++$l] = "        Creates OASIS_flowFork_tt.cpp & OASIS_flowFork_tt.ph from GEN 2.0 ";
$c[++$l] = "                                                                          ";
$c[++$l] = "                                                                          ";

$current_pgm = $0;
$pgm_offset = index($current_pgm,"build_OASIS_cpp_and_ph.pl");
$pgm_dir = substr($current_pgm,0,$pgm_offset);
$frame_cpp = $pgm_dir."OASIS_frame_tt.cpp";
$frame_ph = $pgm_dir."OASIS_frame_tt.ph";

if (!(-e $frame_cpp))
{
  print STDERR"Cannot find \"OASIS_frame_tt.cpp\" in the same directory \"$pgm_dir\" as the script....\n";
  exit;
}

if (!(-e $frame_ph))
{
  print STDERR"Cannot find \"OASIS_frame_tt.ph\" in the same directory \"$pgm_dir\" as the script....\n";
  exit;
}


if ($#ARGV < 0)
{
    $, = "\n";
    print STDERR@c,"\n\n";
    print STDERR"Illegal command line options...\n";
    print STDERR"There must be a GEN version and testmethod specified...\n";
    exit;
}

my(%all_options, %option, @all_args);
CorTeXPerlModule::getOptions(\@ARGV,\%all_options, \%option, \@all_args);


if (!($all_options{g}) && !($all_options{f}))
  { ##If the -g option is not specified...
    $, = "\n";
    print STDERR@c,"\n\n";
    print STDERR"Illegal command line options...\n";
    print STDERR"There must be a GEN version specified using -g option...\n";
    print STDERR"Or an absolute path to templates folder specified using -f option...\n";
    exit;
  }
else
  { ## check if the argument begins with Rev
    if($all_options{g})
    {
        if ($option{g} !~ /^Rev/)
          {
        $, = "\n";
        print STDERR@c,"\n\n";
        print STDERR"Illegal command line options...\n";
        print STDERR"-g <GEN Version> must begin with Rev...\n";
        exit;
          }
          $gen_ph_dir = "c:/intel/tpapps/CorTeX/GEN/".$option{g}."/templates";
    }
    else
    {
        $gen_ph_dir = $option{f};
    }
  }

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
    my ($phfile,$phtestclass,$public_bases,$GENphfile);
    my ($cpp,@ordered_param_list,$param,$mtime,$print_string);
    my ($param_type,$avator_type,$param_cardinality,$param_function,$param_attribute,$shadow_param_attribute,$param_cortex_type,$param_desc);
    my (%param_details,$testclass_suffix,$old_ph_file);
    my ($param_options,$param_default,@param_opts,$opt,$print_str);
    my ($port, $port_status,$port_desc,$port_info);
    my ($prototype,$type,$member);
    my ($param_section);
    my ($old_ph_rev_history,$revhistoryline);
    my ($done,$hfile);
    my ($phtestclass_ordered_params,$plist_vector,$tc_vector,$error_count);
    my (@rev_history,$rev_history_flag,$rev_history_line);
    $GENphfile = $gen_ph_dir."/GEN_".$testmethod."_tt.ph";
    $phfile = "OASIS_".$testmethod."_tt.ph";
    $TESTMETHOD = uc($testmethod);
    $Testmethod = ucfirst($testmethod);
    $error_count = 0;
    CorTeXPerlModule::parsePHfile($GENphfile,"1",\$phtestclass,\$public_bases,\@ordered_param_list,\%param_details,\@port_details,\@tc_vector,\@plist_vector,\$error_count,"OASIS");
    if ($error_count)
      {
        print "Errors detected while parsing \"$phfile\"...exiting...\n";
        exit;
      }

    if (-e $phfile)
      {
        CorTeXPerlModule::getLastModTime($phfile,\$mtime);
        $old_ph_file = $phfile."_org_".$mtime;
        rename($phfile,$old_ph_file);
        undef $mtime;
        ###Extract the comment section out from the bottom of the original file
        open (ORGPH, "$old_ph_file") or die "Cannot Open \"$old_ph_file\" for reading. Exiting....\n";
        while (<ORGPH>)
          {
            if (/^#\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*/)
              {
                push(@rev_history,$_);
                if (!($rev_history_flag))
                  {
                    $rev_history_flag++;
                  }
                else
                  {
                    undef $rev_history_flag;
                  }
                next;
              }
            if ($rev_history_flag)
              {
                push(@rev_history,$_);
                next;
              }
          }
      }





    $phtestclass =~ s/GEN//;

    printf("Generating ph file <<%s>> from phfile <<%s>> with <<%s>><<%s>><<%s>>\n",$phfile,$GENphfile,$phtestclass,$testmethod,$TESTMETHOD);

    open (FRAMEPH, $frame_ph) or die "Cannot Open \"$frame_ph\" for reading. Exiting....\n";
    open (PH, ">$phfile") or die "Cannot Open \"$phfile\" for writing. Exiting....\n";
##    printf(PH"//File Created by %s on %s\n",$current_pgm,$timestamp);

    printf(PH"Version 1.0;\n");
    printf(PH"Import OASIS_tt.ph;\n");
    printf(PH"TestClass = %s;\n",$phtestclass);
    $public_bases =~ s/GEN/OASIS/;
    printf(PH"PublicBases = %s;\n",$public_bases);
    printf(PH"Parameters\n");
    printf(PH"{\n");
    foreach $param(@ordered_param_list)
      {
        ($param_type,$avator_type,$param_cardinality,$param_attribute,$param_cortex_type,$param_function,$param_desc,$param_default,$param_options,$cmtp_type) = split(/\|/,$param_details{$param});
        
        if ($cmtp_type ne "")
        {        
          printf(PH"    %s %s #AVATOR %s; #CMTP %s;\n",$param_type,$param,$avator_type,$cmtp_type);
          printf(PH"    {\n");
          printf(PH"        Cardinality = %s;\n",$param_cardinality);
        }
        else
        {
          printf(PH"    %s %s #AVATOR %s;\n",$param_type,$param,$avator_type);
          printf(PH"    {\n");
          printf(PH"        Cardinality = %s;\n",$param_cardinality);
        }

        ###param_attribute comming from the parser is always m_o (because all OASIS side params are meant to be iCGENTpParam)
        ###With TSS 1.04, We will be using native Choices and Default and autoXML features of the TSS.
        ###Hence param attribute becomes shadow param attribute, used only for data transfer between OASIS and GEN sides.
        ###param attribute itself will be m_s or m_d or m_n based on String, Integer or Double
        $shadow_param_attribute = $param_attribute;

        if ($param_cardinality =~ /[nN]/)
          {
            $param_attribute =~ s/^m_o/m_v/;
          }
        else
          {
            if ($param_type eq "String")
              {
                $param_attribute =~ s/^m_o/m_s/;
              }
            elsif ($param_type eq "Double")
              {
                $param_attribute =~ s/^m_o/m_d/;
              }
            elsif ($param_type eq "Integer")
              {
                $param_attribute =~ s/^m_o/m_n/;
              }
          }
        printf(PH"        Attribute   = %s;\n",$param_attribute);
        ($param_function = $shadow_param_attribute) =~ s/m_o/m_zSet/;
        printf(PH"        SetFunction = %s;\n",$param_function);
        printf(PH"        Description = \"%s\";\n",$param_desc);
        if ($param_options)
          {
##            printf(PH"        #AVATOR_OPTIONS = ");
            @param_opts = split(/&/,$param_options);
            undef $print_str;
            foreach $opt(@param_opts)
              {
#                $print_str .= sprintf("\"%s\",",$opt);
              }
#            $print_str =~ s/,$/;/;
#            printf(PH"%s\n",$print_str);


            printf(PH"        Choices         = ");
            @param_opts = split(/&/,$param_options);
            undef $print_str;
            foreach $opt(@param_opts)
              {
                if ($param_type eq "String")
                  {
                    $print_str .= sprintf("\"%s\",",$opt);
                  }
                else
                  {
                    $print_str .= sprintf("%s,",$opt);
                  }
              }
            $print_str =~ s/,$/;/;
            printf(PH"%s\n",$print_str);
          }
        if (($param_default)||($param_default eq "0"))
          {
#            printf(PH"        #AVATOR_DEFAULT = \"%s\";\n",$param_default);

            if ($param_type eq "String")
              {
                printf(PH"        Default         = \"%s\";\n",$param_default);
              }
            else
              {
                printf(PH"        Default         = %s;\n",$param_default);
              }
          }
        printf(PH"    }\n");
      }
    printf(PH"}\n\n\n");

    printf(PH"#BEGIN_AVATOR_PORT_DESCRIPTIONS;\n");
    printf(PH"#\n");

    foreach $port_info(@port_details)
      {
        ($port,$port_status,$port_desc) = split(/\|/,$port_info);
       
       if($port_status ne "")
        {
          printf(PH"#AVATOR_PORT %4s %-10s %s;\n",$port,$port_status,$port_desc);
        }
        else
        {
          printf(PH"\t#CMTP_MODE %s\n",$port_desc);	
        }
        
      }
    printf(PH"#\n");
    printf(PH"#END_AVATOR_PORT_DESCRIPTIONS;\n\n\n");

    undef $cpp_flag;
    while (<FRAMEPH>)
      {
        $tmp_string = $_;
        CorTeXPerlModule::stripWhiteSpace(\$tmp_string);
        if ($tmp_string =~ /#Begin\s+of\s+C\+\+\s+Section/)
          {
            $cpp_flag = 1;
            printf(PH"%s",$_);
            next;
          }
        if ($tmp_string =~ /^CPlusPlusEnd/)
          {
            undef $cpp_flag;
            printf(PH"%s",$_);
            next;
          }
        if ($tmp_string =~ /\/\/\/\/Begin_CorTeX_Test_Class_Param_Set_Function_Declaration/)
          {
            printf(PH"%s",$_);
            foreach $param(@ordered_param_list)
              {
                ($param_type,$avator_type,$param_cardinality,$param_attribute,$param_cortex_type,$param_function,$param_desc,$param_default,$param_options) = split(/\|/,$param_details{$param});
                ###param_attribute comming from the parser is always m_o (because all OASIS side params are meant to be iCGENTpParam)
                ###With TSS 1.04, We will be using native Choices and Default and autoXML features of the TSS.
                ###Hence param attribute becomes shadow param attribute, used only for data transfer between OASIS and GEN sides.
                ###param attribute itself will be m_s or m_d or m_n based on String, Integer or Double
                $shadow_param_attribute = $param_attribute;
                if ($param_type eq "String")
                  {
                    $param_attribute =~ s/^m_o/m_s/;
                  }
                elsif ($param_type eq "Double")
                  {
                    $param_attribute =~ s/^m_o/m_d/;
                  }
                elsif ($param_type eq "Integer")
                  {
                    $param_attribute =~ s/^m_o/m_n/;
                  }
                ($param_function = $shadow_param_attribute) =~ s/m_o/m_zSet/;
                $print_string = sprintf("        virtual void %s(",$param_function);
                if ($param_type eq "String")
                  {
                    $print_string .= "const OFCString& x);";
                  }
                elsif ($param_type eq "Integer")
                  {
                    $print_string .= "int x);";
                  }
                elsif ($param_type eq "Double")
                  {
                    $print_string .= "double x);";
                  }
                printf(PH"%s\n",$print_string);
              }
            next;
          }
        if ($tmp_string =~ /\/\/\/\/Begin_Attribute_declaration_for_all_the_test_class_parameters/)
          {
            printf(PH"%s",$_);
            foreach $param(@ordered_param_list)
              {
                ($param_type,$avator_type,$param_cardinality,$param_attribute,$param_cortex_type,$param_function,$param_desc,$param_default,$param_options) = split(/\|/,$param_details{$param});

                ###param_attribute comming from the parser is always m_o (because all OASIS side params are meant to be iCGENTpParam)
                ###With TSS 1.04, We will be using native Choices and Default and autoXML features of the TSS.
                ###Hence param attribute becomes shadow param attribute, used only for data transfer between OASIS and GEN sides.
                ###param attribute itself will be m_s or m_d or m_n based on String, Integer or Double
                $shadow_param_attribute = $param_attribute;
                undef $print_str;
                if ($param_type eq "String")
                  {
                    if ($param_cardinality =~ /[nN]/)
                      {
                        ##If the cardinality is N
                        $param_attribute =~ s/^m_o/m_v/;
                        $print_str = sprintf("StringArray    %s;",$param_attribute);
                        printf(PH"        %-50s //Param Attribute for testclass parameter \"%s\"\n",$print_str,$param);
                      }
                    else
                      {
                        $param_attribute =~ s/^m_o/m_s/;
                        $print_str = sprintf("OFCString    %s;",$param_attribute);
                        printf(PH"        %-50s //Param Attribute for testclass parameter \"%s\"\n",$print_str,$param);
                      }
                  }
                elsif ($param_type eq "Double")
                  {
                    if ($param_cardinality =~ /[nN]/)
                      {
                        ##If the cardinality is N
                        $param_attribute =~ s/^m_o/m_v/;
                        $print_str = sprintf("DoubleArray    %s;",$param_attribute);
                        printf(PH"        %-50s //Param Attribute for testclass parameter \"%s\"\n",$print_str,$param);
                      }
                    else
                      {
                        $param_attribute =~ s/^m_o/m_d/;
                        $print_str = sprintf("double       %s;",$param_attribute);
                        printf(PH"        %-50s //Param Attribute for testclass parameter \"%s\"\n",$print_str,$param);
                      }
                  }
                elsif ($param_type eq "Integer")
                  {
                    if ($param_cardinality =~ /[nN]/)
                      {
                        ##If the cardinality is N
                        $param_attribute =~ s/^m_o/m_v/;
                        $print_str = sprintf("IntegerArray    %s;",$param_attribute);
                        printf(PH"        %-50s //Param Attribute for testclass parameter \"%s\"\n",$print_str,$param);
                      }
                    else
                      {
                        $param_attribute =~ s/^m_o/m_n/;
                        $print_str = sprintf("int          %s;",$param_attribute);
                        printf(PH"        %-50s //Param Attribute for testclass parameter \"%s\"\n",$print_str,$param);
                      }
                  }
                $print_str = sprintf("iCGENTpParam %s;",$shadow_param_attribute);
                printf(PH"        %-50s //Shadow Param Attribute for testclass parameter \"%s\"\n",$print_str,$param);
              }
            next;
          }
        if (!($cpp_flag))
          {
            next;
          }
        printf(PH"%s",$_);
      }

    printf(PH"\n");
    foreach $rev_history_line(@rev_history)
      {
        printf(PH"%s",$rev_history_line);
      }
    undef @rev_history;

    close FRAMEPH;
    close PH;

    ($cppfile = $phfile) =~ s/\.ph/\.cpp/;
    if (-e $cppfile)
      {
        CorTeXPerlModule::getLastModTime($cppfile,\$mtime);
        $old_cpp_file = $cppfile."_org_".$mtime;
        rename($cppfile,$old_cpp_file);
        undef $mtime;
        undef $rev_history_flag;
        undef @rev_history;
        ###Extract the comment section out from the bottom of the original file
        open (ORGCPP, "$old_cpp_file") or die "Cannot Open \"$old_cpp_file\" for reading. Exiting....\n";
        while (<ORGCPP>)
          {
            if ((/^\/\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*/) && (!($rev_history_flag)))
              {
                push(@rev_history,$_);
                $rev_history_flag++;
                next;
              }
            if ((/^\*\*\*\*\*\*\*\*\*\*\*\*\*\*/) && ($rev_history_flag))
              {
                push(@rev_history,$_);
                undef $rev_history_flag;
                next;
              }
            if ($rev_history_flag)
              {
                push(@rev_history,$_);
                next;
              }
          }
      }


    printf("Generating cpp file <<%s>> from phfile <<%s>> with <<%s>><<%s>><<%s>><<%s>>\n",$cppfile,$phfile,$phtestclass,$testmethod,$TESTMETHOD,$Testmethod);

    open (FRAMECPP, $frame_cpp) or die "Cannot Open \"$frame_cpp\" for reading. Exiting....\n";
    open (CPP, ">$cppfile") or die "Cannot Open \"$cppfile\" for writing. Exiting....\n";
##    printf(CPP"//File Created by %s on %s\n",$current_pgm,$timestamp);
    ($factoryname = $phtestclass) =~ s/iC//;
    $factoryname = "GEN".$factoryname;
    while (<FRAMECPP>)
      {
        $tmp_string = $_;
        CorTeXPerlModule::stripWhiteSpace(\$tmp_string);

        if (/CFrameDLLInfo/)
          {
            $_ =~ s/Frame/$Testmethod/g;
          }
        if (/gFrameDLLInfo/)
          {
            $_ =~ s/Frame/$Testmethod/g;
          }
        if (/gCreateGENFrameTest/)
          {
            $_ =~ s/GENFrameTest/$factoryname/g;
          }
        if (/iCFrameTest/)
          {
            $_ =~ s/iCFrameTest/$phtestclass/g;
          }
        if (/Frame/)
          {
            $_ =~ s/Frame/$testmethod/g;
          }
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

        if ($tmp_string =~ /^\/\/\/\/Start_of_AllTestClassParams_Vector_Population/)
          {
            printf(CPP"%s",$_);
            ##Insert Vector Population...
            $print_string = "";
            &get_alltestclass_params_vector(\%param_details,\@ordered_param_list,\$print_string);
            printf(CPP"%s",$print_string);
            next;
          }

         if ($tmp_string =~ /^\/\/\/\/Start_of_TestClass_Interface_Params_Constructor_Initialization$/)
          {
            #insert Test Class Interface Parameter variable intialization in Test Class Constructor
            #print_string contains the generated initialization code
            printf(CPP"%s",$_);
            &get_constructor_params(\%param_details,\$print_string,\@ordered_param_list,$phtestclass);
            printf(CPP"%s",$print_string);
            next;
          }

        if ($tmp_string =~ /Start_of_Test_Class_Specific_Port_and_Status_Setting$/)
          {
            printf(CPP"%s",$_);
            ##insert exit port and status setting based on the port details.
            $print_string = "";
            &get_port_settings(\@port_details,\$print_string);
            printf(CPP"%s",$print_string);
            next;
          }

        if ($tmp_string =~ /Start_of_Test_Class_Specific_Instance_Parameter_XML_initialization$/)
          {
            #insert xml init for each test class parameter
            #print_string contains the generated xml init code from the subroutine
            printf(CPP"%s",$_);
            $print_string = "";
            &get_xml_init(\%param_details,\@ordered_param_list,\$print_string);
            printf(CPP"%s",$print_string);
            next;
          }
        if ($tmp_string =~ /^\/\/\/\/Start_of_Test_Class_Specific_Instance_Parameter_Set_Functions$/)
          {
            #insert set functions for each test class parameter
            #print_string contains the generated set function code from the subroutine
            printf(CPP"%s",$_);
            &get_set_functions(\%param_details,\@ordered_param_list,\$print_string,$phtestclass);
            printf(CPP"%s",$print_string);
            next;
          }
        if ($tmp_string =~ /^\/\/\/\/Start_of_PopulatePListMap$/)
          {
            #insert code for m_zPopulatePListMap
            printf(CPP"%s",$_);
            $print_string  = "void ".$phtestclass."::m_zPopulatePListMap()\n";
            $print_string .= "{\n";
            if (@plist_vector)
              {
                $print_string .= "    //Note this is needed for OASIS TO MANAGE TIMING MAP ALLOCATION \n";
                $print_string .= "    //AND FOR THE GUI TOOLS TO BE HAPPY. \n";
                $print_string .= "    PatternTree* pPlistPtr = NULL;\n";
		        $print_string .= "    clearPatternLists();\n";
                foreach $param(@plist_vector)
                  {
                    ($param_type,$avator_type,$param_cardinality,$param_attribute,$param_cortex_type,$param_function,$param_desc,$param_default,$param_options) = split(/\|/,$param_details{$param});
                    $print_string .= "    if ((!".$param_attribute.".m_sStrValue.empty()) && (IT_UNDEFINED_STR != ";
                    $print_string .= $param_attribute.".m_sStrValue))";
                    $print_string .= "    {\n";
                    $print_string .= "        pPlistPtr = Test::m_pTestPlan->getPatternList(".$param_attribute.".m_sStrValue.c_str(),false);\n";
                    $print_string .= "        if (NULL != pPlistPtr)\n";
                    $print_string .= "        {\n";
                    $print_string .= "            Test::addPatternList(pPlistPtr);\n";
                    $print_string .= "        }\n";
                    $print_string .= "    }\n\n";
                  }
              }
            $print_string .= "}\n";
            printf(CPP"%s",$print_string);
            $print_string = "";
            next;
          }
        if ($tmp_string =~ /^\/\/\/\/Start_of_PopulateTCMap$/)
          {#insert code for m_zPopulateTCMap

            printf(CPP"%s",$_);
            $print_string  = "void ".$phtestclass."::m_zPopulateTCMap()\n";
            $print_string .= "{\n";
            if (@tc_vector)
              {
                $print_string .= "    //Note this is needed for OASIS TO MANAGE TIMING MAP ALLOCATION \n";
                $print_string .= "    //AND FOR THE GUI TOOLS TO BE HAPPY. \n";
                $print_string .= "    TestCondition* pTCPtr = NULL;\n";
                $print_string .= "    TestConditionGroup* pTCGPtr = NULL;\n";
                $print_string .= "    Timing* pTimingPtr = NULL;\n";
                $print_string .= "    AttributeSetBlockVec_t vAttrSetBlocks;\n";
                $print_string .= "    TimingsBlock* pTimingBlock;\n";
                $print_string .= "    int i = 0;\n";
                $print_string .= "    clearConditions();\n";
                foreach $param(@tc_vector)
                  {
                    ($param_type,$avator_type,$param_cardinality,$param_attribute,$param_cortex_type,$param_function,$param_desc,$param_default,$param_options) = split(/\|/,$param_details{$param});
                    $print_string .= "    if ((!".$param_attribute.".m_sStrValue.empty()) && (IT_UNDEFINED_STR != ";
                    $print_string .= $param_attribute.".m_sStrValue))";
                    $print_string .= "    {\n";
                    $print_string .= "        pTCPtr = Test::m_pTestPlan->getTestCondition(".$param_attribute.".m_sStrValue.c_str(),false);\n";
                    $print_string .= "        if (NULL != pTCPtr)\n";
                    $print_string .= "        {\n";
                    $print_string .= "            Test::addCondition(pTCPtr);\n";
                    $print_string .= "            if (IT_TIMING == $param_attribute.m_tType)\n";
                    $print_string .= "            {\n";
                    $print_string .= "                pTCGPtr =  dynamic_cast<TestConditionGroup*>(pTCPtr->getTestConditionGroup());\n";
                    $print_string .= "                pTCGPtr->getAllAttributeSetBlocks(vAttrSetBlocks);\n";
                    $print_string .= "                for(i = 0; i < (int) vAttrSetBlocks.size(); i++)\n";
                    $print_string .= "                {\n";
                    $print_string .= "                   pTimingBlock = dynamic_cast<TimingsBlock*> (vAttrSetBlocks[i]);\n";
                    $print_string .= "                   pTimingPtr = pTimingBlock->getTiming();\n";
                    $print_string .= "                   if (NULL != pTimingPtr)\n";
                    $print_string .= "                   {\n";
                    $print_string .= "                       m_pTestPlan->updateTMapTestCondition((Timing *) pTimingPtr);\n";
                    $print_string .= "                   }\n";
                    $print_string .= "                }\n";
                    $print_string .= "            }\n";
                    $print_string .= "        }\n";
                    $print_string .= "    }\n\n";
                    $print_string .= "    pTCPtr = NULL;\n";
                    $print_string .= "    pTCGPtr = NULL;\n";
                    $print_string .= "    pTimingPtr = NULL;\n";
                  }
              }
            $print_string .= "}\n";
            printf(CPP"%s",$print_string);
            $print_string = "";
            next;
          }

        if ($tmp_string =~ /^\/\/\/\/Start_of_Test_Class_Specific_Instance_Parameter_Allowed_Values$/)
          {
            #insert per parameter getAllowedValues code
            #print_string contains the generated code from the subroutine
            printf(CPP"%s",$_);
            &get_code_for_Allowed_Values(\%param_details,\@ordered_param_list,\$print_string,$phtestclass);
            printf(CPP"%s",$print_string);
            next;
          }
        if ($tmp_string =~ /^\/\/\/\/Start_of_Test_Class_Specific_Instance_Parameter_GUI_Type$/)
          {
            #insert per parameter getGUIType code
            #print_string contains the generated code from the subroutine
            printf(CPP"%s",$_);
            &get_code_for_GUI_Type(\%param_details,\@ordered_param_list,\$print_string,$phtestclass);
            printf(CPP"%s",$print_string);
            next;
          }
        if ($tmp_string =~ /^\/\/\/\/Start_of_Test_Class_Specific_Instance_Parameter_Param_Type$/)
          {
            #insert per parameter getParamType code
            #print_string contains the generated code from the subroutine
            printf(CPP"%s",$_);
            &get_code_for_Param_Type(\%param_details,\@ordered_param_list,\$print_string,$phtestclass);
            printf(CPP"%s",$print_string);
            next;
          }
        if ($tmp_string =~ /^\/\/\/\/Start_of_Test_Class_Specific_Instance_Parameter_Param_Value$/)
          {
            #insert per parameter getParamValue code
            #print_string contains the generated code from the subroutine
            printf(CPP"%s",$_);
            &get_code_for_Param_Value(\%param_details,\@ordered_param_list,\$print_string,$phtestclass);
            printf(CPP"%s",$print_string);
            next;
          }
        if ($tmp_string =~ /^\/\/\/\/Start_of_Two_Param_Test_Class_Specific_Generic_Set$/)
          {
            #insert two param GenericSet Function calls for each test class parameter
            #print_string contains the generated code from the subroutine
            printf(CPP"%s",$_);
            &get_2Param_GenericSet(\%param_details,\@ordered_param_list,\$print_string,$phtestclass);
            printf(CPP"%s",$print_string);
            next;
          }
        if ($tmp_string =~ /^\/\/\/\/Start_of_One_Param_Test_Class_Specific_Generic_Set$/)
          {
            #insert one param GenericSet Function calls for each test class parameter
            #print_string contains the generated code from the subroutine
            printf(CPP"%s",$_);
            &get_1Param_GenericSet(\%param_details,\@ordered_param_list,\$print_string,$phtestclass);
            printf(CPP"%s",$print_string);
            next;
          }
        if ($tmp_string =~ /^\/\/\/\/Start_of_Two_Param_Test_Class_Specific_Generic_Get$/)
          {
            #insert two param GenericGet Function calls for each test class parameter
            #print_string contains the generated code from the subroutine
            printf(CPP"%s",$_);
            &get_2Param_GenericGet(\%param_details,\@ordered_param_list,\$print_string,$phtestclass);
            printf(CPP"%s",$print_string);
            next;
          }
        if ($tmp_string =~ /^\/\/\/\/Start_of_One_Param_Test_Class_Specific_Generic_Get$/)
          {
            #insert one param GenericGet Function calls for each test class parameter
            #print_string contains the generated code from the subroutine
            printf(CPP"%s",$_);
            &get_1Param_GenericGet(\%param_details,\@ordered_param_list,\$print_string,$phtestclass);
            printf(CPP"%s",$print_string);
            next;
          }
        if ($tmp_string =~ /^\/\/\/\/Start_of_Test_Class_Specific_getValues$/)
          {
            #insert getValues  for each test class parameter
            #print_string contains the generated code from the subroutine
            printf(CPP"%s",$_);
            &get_getValues(\%param_details,\@ordered_param_list,\$print_string,$phtestclass);
            printf(CPP"%s",$print_string);
            next;
          }

        if ($tmp_string =~ /^\/\/\/\/Start_of_Test_Class_Specific_Instance_Param_get_XML_Description$/)
          {
            #insert getValues  for each test class parameter
            #print_string contains the generated code from the subroutine
            printf(CPP"%s",$_);
            &get_getXMLDesc(\%param_details,\@ordered_param_list,\$print_string,$phtestclass);
            printf(CPP"%s",$print_string);
            next;
          }
        if($tmp_string =~ /\/\*\*\*\*\*\*\*\*\*/)
          {
            last;
          }
        printf(CPP"%s",$_);
      }

    printf(CPP"\n");
    foreach $rev_history_line(@rev_history)
      {
        printf(CPP"%s",$rev_history_line);
      }
    undef @rev_history;
    close CPP;
    close FRAMECPP;
  }

if ($errorflag)
  {
    print "Errors detected...exiting...\n";
    exit;
  }

exit;

sub get_alltestclass_params_vector
  {
    my($param_details,$ordered_param_list,$print_string) = @_;
    my (@params, $param,$param_type,$avator_type,$param_cardinality,$param_function,$param_attribute,$param_desc);
    my ($param_cortex_type,$param_options,$param_default,@options,%param_details);
    my ($guitype,$datatype,$mincard,$maxcard,$paramtype,@tmp);
    my ($shadow_param_attribute);
    @params = @$ordered_param_list;
    $$print_string = "";
    foreach $param(@params)
      {
        ($param_type,$avator_type,$param_cardinality,$param_attribute,$param_cortex_type,$param_function,$param_desc,$param_default,$param_options) = split(/\|/,$$param_details{$param});
        $$print_string .= sprintf("    m_vAllTemplateParams.push_back(&%s);\n",$param_attribute);
      }
  }

sub get_port_settings
{
  my($port_details,$print_string) = @_;
  my ($port_info,$port,$sign,$status,$desc,$tmp);
  my (@tokens, $token,$start_port, $stop_port,$ifstring);
  my ($shadow_param_attribute);
  $$print_string = "";
  undef $ifstring;
  foreach $port_info(@$port_details)
    {
      ($tmp,$status,$desc) = split(/\|/,$port_info);
      CorTeXPerlModule::stripWhiteSpace(\$tmp);
      CorTeXPerlModule::stripWhiteSpace(\$status);
      CorTeXPerlModule::stripWhiteSpace(\$desc);
      
      ##Changed for CMTP support
      if($tmp eq "" || $status eq "")
      {
      	next;
      }

      $desc =~ s/"//g;
      $status =~ s/"//g;
      $STATUS = uc($status);
      if ($STATUS !~ /PASS/)
        {
          $STATUS = "FAIL";
        }
      if ($tmp =~ /^\[(.+)\]$/)
        {
          @tokens = split(/,/,$1);
          foreach $token(@tokens)
            {
              if ($token =~ /(\d+)\-(\d+)/)
                {
                  $start_port = $1;
                  $stop_port = $2;

                  if (!($ifstring))
                    {
                      $ifstring = "if";
                    }
                  else
                    {
                      $ifstring = "else if";
                    }
                  $$print_string .= sprintf("        %s ((tPort >= %s) && (tPort <= %s))\n",$ifstring,$start_port,$stop_port);
                  $$print_string .= "        {\n";
                  $$print_string .= sprintf("            m_zTSSWrapperSetPassFailStatus(ITest::%s);\n",$STATUS);
                  $$print_string .= sprintf("            sPortStatus = \"%s\";\n",$status);
                  $$print_string .= sprintf("            sPortInfo = \"%s\";\n",$desc);
                  $$print_string .= "        }\n";
                  undef $start_port;
                  undef $stop_port;
                }
              else
                {
                  $sign = "==";

                  if (!($ifstring))
                    {
                      $ifstring = "if";
                    }
                  else
                    {
                      $ifstring = "else if";
                    }

                  $port = $token;
                  $$print_string .= sprintf("        %s (tPort %s %s)\n",$ifstring,$sign,$port);
                  $$print_string .= "        {\n";
                  $$print_string .= sprintf("            m_zTSSWrapperSetPassFailStatus(ITest::%s);\n",$STATUS);
                  $$print_string .= sprintf("            sPortStatus = \"%s\";\n",$status);
                  $$print_string .= sprintf("            sPortInfo = \"%s\";\n",$desc);
                  $$print_string .= "        }\n";
                }
        }
          undef @tokens;
          undef $token;
          next;
        }
      elsif ($tmp =~ /^(<=)([-\d]+)$/)
        {
          $sign = $1;
          $port = $2;
        }
      elsif ($tmp =~ /^(<)([-\d]+)$/)
        {
          $sign = $1;
          $port = $2;
        }
      elsif ($tmp =~ /^(>=)([-\d]+)$/)
        {
          $sign = $1;
          $port = $2;
        }
      elsif ($tmp =~ /^(>)([-\d]+)$/)
        {
          $sign = $1;
          $port = $2;
        }
      else
        {
          $sign = "==";
          $port = $tmp;
        }

      if (!($ifstring))
        {
          $ifstring = "if";
        }
      else
        {
          $ifstring = "else if";
        }
      $$print_string .= sprintf("        %s (tPort %s %s)\n",$ifstring,$sign,$port);
      $$print_string .= "            {\n";
      $$print_string .= sprintf("            m_zTSSWrapperSetPassFailStatus(ITest::%s);\n",$STATUS);
      $$print_string .= sprintf("            sPortStatus = \"%s\";\n",$status);
      $$print_string .= sprintf("            sPortInfo = \"%s\";\n",$desc);
      $$print_string .= "            }\n";
    }
  $$print_string .= "        else\n";
  $$print_string .= "            {\n";
  $$print_string .= "            m_zTSSWrapperSetPassFailStatus(ITest::FAIL);\n";
  $$print_string .= "            sPortStatus = \"FAIL\";\n";
  $$print_string .= "            sPortInfo = \"UNDEFINED PORT\";\n";
  $$print_string .= "            }\n";
  $$print_string .= "\n";
}

sub get_xml_init
{
  my($param_details,$ordered_params,$print_string) = @_;
  my (@params, $param,$param_type,$avator_type,$param_cardinality,$param_function,$param_attribute,$param_desc);
  my ($param_cortex_type,$param_options,$param_default,@options,%param_details);
  my ($guitype,$datatype,$mincard,$maxcard,$paramtype,@tmp);
  my ($shadow_param_attribute);
  @params = @$ordered_params;
  $$print_string = "";

  foreach $param(@params)
    {

      ($param_type,$avator_type,$param_cardinality,$param_attribute,$param_cortex_type,$param_function,$param_desc,$param_default,$param_options) = split(/\|/,$$param_details{$param});
        ###param_attribute comming from the parser is always m_o (because all OASIS side params are meant to be iCGENTpParam)
        ###With TSS 1.04, We will be using native Choices and Default and autoXML features of the TSS.
        ###Hence param attribute becomes shadow param attribute, used only for data transfer between OASIS and GEN sides.
        ###param attribute itself will be m_s or m_d or m_n based on String, Integer or Double
        $shadow_param_attribute = $param_attribute;
        if ($param_type eq "String")
          {
            $param_attribute =~ s/^m_o/m_s/;
          }
        elsif ($param_type eq "Double")
          {
            $param_attribute =~ s/^m_o/m_d/;
          }
        elsif ($param_type eq "Integer")
          {
            $param_attribute =~ s/^m_o/m_n/;
          }
        ($param_function = $shadow_param_attribute) =~ s/m_o/m_zSet/;

      if ((($param_cardinality eq "0-1")||($param_cardinality eq "1"))&&($param_options))
        {
          $guitype = "tGUITypeGList";
        }
      elsif (($param_type eq "String")&&
             (($avator_type eq "LEVEL_TESTCONDITION") ||
              ($avator_type eq "TIMING_TESTCONDITION") ||
              ($avator_type eq "PLIST") ||
              ($avator_type eq "PIN")))
        {
          $guitype = "tGUITypeGExtList";
        }
      else
        {
          $guitype = "tGUITypeGValue";
        }

      if ($param_type eq "String")
        {
          $datatype = "tDataTypeString";
          if (($avator_type eq "LEVEL_TESTCONDITION")||($avator_type eq "TIMING_TESTCONDITION"))
            {
              $paramtype = "tParamTypeTestCondition";
            }
          elsif ($avator_type eq "PLIST")
            {
              $paramtype = "tParamTypePList";
            }
          else
            {
              $paramtype = "tParamTypePString";
            }
        }
      elsif (($param_type eq "Integer")||($param_type eq "Long"))
        {
          $datatype = "tDataTypeInteger";
          $paramtype = "tParamTypePInteger";
        }
      elsif (($param_type eq "Float")||($param_type eq "Double"))
        {
          $datatype = "tDataTypeDouble";
          $paramtype = "tParamTypePDouble";
        }

      if ($param_cardinality eq "0-1")
        {
          $mincard = "tCardTypeCOpt";
          $maxcard = "tCardTypeC1";
        }
      elsif ($param_cardinality eq "1")
        {
          $mincard = "tCardTypeC1";
          $maxcard = "tCardTypeC1";
        }
      elsif (($param_cardinality eq "0-n")||($param_cardinality eq "0-N"))
        {
          $mincard = "tCardTypeCOpt";
          $maxcard = "tCardTypeCn";
        }
      elsif (($param_cardinality eq "1-n")||($param_cardinality eq "1-N"))
        {
          $mincard = "tCardTypeC1";
          $maxcard = "tCardTypeCn";
        }

      $$print_string .= "    m_oXMLParamDescriptor.addParam(OFCString(\"$param\"),\n";
      $$print_string .= "                                   $guitype,\n";
      $$print_string .= "                                   $datatype,\n";
      $$print_string .= "                                   $mincard,\n";
      $$print_string .= "                                   $maxcard,\n";
      $$print_string .= "                                   $paramtype,\n";
      $$print_string .= "                                   OFCString(\"$param_desc\"));\n\n";
    }
}

sub get_set_functions
{
  my($param_details,$ordered_params,$print_string,$phtestclass) = @_;
  my (@params, $param,$param_type,$avator_type,$param_cardinality,$param_function,$param_attribute,$param_desc);
  my ($param_cortex_type,$param_options,$param_default,@options,%param_details);
  my ($prototype,$type,$member);
  my ($additional_code1, $addtional_code2);
  my ($shadow_param_attribute);
  my ($member2);
  @params = @$ordered_params;
  $$print_string = "";

  foreach $param(@params)
    {
      ($param_type,$avator_type,$param_cardinality,$param_attribute,$param_cortex_type,$param_function,$param_desc,$param_default,$param_options) = split(/\|/,$$param_details{$param});
        ###param_attribute comming from the parser is always m_o (because all OASIS side params are meant to be iCGENTpParam)
        ###With TSS 1.04, We will be using native Choices and Default and autoXML features of the TSS.
        ###Hence param attribute becomes shadow param attribute, used only for data transfer between OASIS and GEN sides.
        ###param attribute itself will be m_s or m_d or m_n based on String, Integer or Double
        $shadow_param_attribute = $param_attribute;

      if ($param_cardinality =~ /[nN]/)
        {
          $param_attribute =~ s/^m_o/m_v/;
        }
      else
        {
          if ($param_type eq "String")
            {
              $param_attribute =~ s/^m_o/m_s/;
            }
          elsif ($param_type eq "Double")
            {
              $param_attribute =~ s/^m_o/m_d/;
            }
          elsif ($param_type eq "Integer")
            {
              $param_attribute =~ s/^m_o/m_n/;
            }
        }
      ($param_function = $shadow_param_attribute) =~ s/m_o/m_zSet/;


      #reset the additional code lines for each param
      $additional_code1 = "";
      $additional_code2 = "";

      if ($param_cardinality =~ /[nN]/)
        {
          if ($param_type eq "String")
            {
              $prototype = "(const OFCString& x)";
              $member = ".m_sStrValue = x.c_str();";
              $member2 = sprintf("%s.push_back(x.c_str());",$param_attribute);
            }
          elsif ($param_type eq "Integer")
            {
              $prototype = "(int x)";
              $member = ".m_nIntValue = x;";
              $member2 = sprintf("%s.push_back(x);",$param_attribute);
            }
          elsif ($param_type eq "Double")
            {
              $prototype = "(double x)";
              $member = ".m_dDblValue = x;";
              $member2 = sprintf("%s.push_back(x);",$param_attribute);
            }
        }
      else
        {
          if ($param_type eq "String")
            {
              $prototype = "(const OFCString& x)";
              $member = ".m_sStrValue = x.c_str();";
              $member2 = "$param_attribute = x.c_str();";
            }
          elsif ($param_type eq "Integer")
            {
              $prototype = "(int x)";
              $member = ".m_nIntValue = x;";
              $member2 = "$param_attribute = x;";
            }
          elsif ($param_type eq "Double")
            {
              $prototype = "(double x)";
              $member = ".m_dDblValue = x;";
              $member2 = "$param_attribute = x;";
            }
        }
      if ($avator_type eq "TIMING_TESTCONDITION")
        {
          $type = "IT_TIMING";
          $additional_code1  = "";
          $additional_code2  = "    m_zPopulateTCMap();\n";
        }
      if ($avator_type eq "LEVEL_TESTCONDITION")
        {
          $type = "IT_LEVELS";
          $additional_code1  = "";
          $additional_code2  = "    m_zPopulateTCMap();\n";
        }
      elsif ($avator_type eq "PLIST")
        {
          $type = "IT_PLIST";
          $additional_code1  = "";
          $additional_code2  = "    m_zPopulatePListMap();\n";
        }
      elsif ($avator_type eq "TESTCLASS")
        {
          $type = "IT_TESTCLASS";
        }
      elsif ($avator_type eq "PIN")
        {
          $type = "IT_SIGNAL";
        }
      elsif ($avator_type eq "PATTERN")
        {
          $type = "IT_PATTERN";
        }
      elsif ($avator_type eq "GLOBAL")
        {
          $type = "IT_GLOBAL";
        }
      elsif ($avator_type eq "FUNCTION")
        {
          $type = "IT_FUNCTION";
        }
      elsif ($avator_type eq "LABEL")
        {
          $type = "IT_LABEL";
        }
      elsif ($avator_type eq "INTEGER")
        {
          $type = "IT_INTEGER";
        }
      elsif ($avator_type eq "DOUBLE")
        {
          $type = "IT_DOUBLE";
        }
      elsif ($avator_type eq "STRING")
        {
          $type = "IT_STRING";
        }
      $$print_string .= "void ".$phtestclass."::".$param_function.$prototype."\n";
      $$print_string .= "{\n";
      if ($additional_code1 ne "")
        {
          $$print_string .= $additional_code1;
        }
      $$print_string .= "    $shadow_param_attribute.m_sName = \"$param\";\n";
      $$print_string .= "    $shadow_param_attribute.m_tType = $type;\n";
      $$print_string .= "    $shadow_param_attribute".$member."\n";
      $$print_string .= "    if (NULL != m_pCoreIfcTIObject)\n";
      $$print_string .= "    {\n";
      $$print_string .= "        m_pCoreIfcTIObject->iC_tSetTpParam($shadow_param_attribute);\n";
      $$print_string .= "    }\n";
      $$print_string .= "    $member2\n";
      $$print_string .= "    m_tDirtyBit = IT_DIRTYBIT_TRUE;\n";
      if ($additional_code2 ne "")
        {
          $$print_string .= $additional_code2;
        }
      $$print_string .= "}\n\n";
    }
}



sub get_code_for_Allowed_Values
{
  my($param_details,$ordered_params,$print_string,$phtestclass) = @_;
  my (@params, $param,$param_type,$avator_type,$param_cardinality,$param_function,$param_attribute,$param_desc);
  my ($param_cortex_type,$param_options,$param_default,@options,%param_details);
  my ($flag);
  my ($shadow_param_attribute);
  my ($member2);
  @params = @$ordered_params;
  $$print_string = "";
  if ($#params > -1)
    {
      $$print_string = "";
      undef $flag;
      foreach $param(@params)
        {
          ($param_type,$avator_type,$param_cardinality,$param_attribute,$param_cortex_type,$param_function,$param_desc,$param_default,$param_options) = split(/\|/,$$param_details{$param});
          ###param_attribute comming from the parser is always m_o (because all OASIS side params are meant to be iCGENTpParam)
          ###With TSS 1.04, We will be using native Choices and Default and autoXML features of the TSS.
          ###Hence param attribute becomes shadow param attribute, used only for data transfer between OASIS and GEN sides.
          ###param attribute itself will be m_s or m_d or m_n based on String, Integer or Double
          $shadow_param_attribute = $param_attribute;
          if ($param_type eq "String")
            {
              $param_attribute =~ s/^m_o/m_s/;
            }
          elsif ($param_type eq "Double")
            {
              $param_attribute =~ s/^m_o/m_d/;
            }
          elsif ($param_type eq "Integer")
            {
              $param_attribute =~ s/^m_o/m_n/;
            }
          ($param_function = $shadow_param_attribute) =~ s/m_o/m_zSet/;

          if (($avator_type eq "TIMING_TESTCONDITION") ||
              ($avator_type eq "LEVEL_TESTCONDITION") ||
              ($avator_type eq "PLIST") ||
              ($avator_type eq "PIN"))
            {
              ##Need to modify allowed values only for these avator types.
              ##rest return a false, meaning no change.
              if (!($flag))
                {
                  ##Means first param of the list...
                  $$print_string .= "        if (\"$param\" == sParam)\n";
                  $flag++;
                }
              else
                {
                  $$print_string .= "        else if (\"$param\" == sParam)\n";
                }
              $$print_string .= "        {\n";
              if ($avator_type eq "TIMING_TESTCONDITION")
                {
                  $$print_string .= "            pBasePtr->m_zGetTimingTC(vListItems);\n";
                  $$print_string .= "            return true;\n";
                }
              elsif ($avator_type eq "LEVEL_TESTCONDITION")
                {
                  $$print_string .= "            pBasePtr->m_zGetLevelsTC(vListItems);\n";
                  $$print_string .= "            return true;\n";
                }
              elsif ($avator_type eq "PLIST")
                {
                  $$print_string .= "            pBasePtr->m_zGetPlists(vListItems);\n";
                  $$print_string .= "            return true;\n";
                }
              elsif ($avator_type eq "PIN")
                {
                  $$print_string .= "            pBasePtr->m_zGetSignalPins(vListItems);\n";
                  $$print_string .= "            pBasePtr->m_zGetPSPins(vListItems);\n";
                  $$print_string .= "            return true;\n";
                }
              $$print_string .= "        }\n";
            }
        }
    }
}






sub get_code_for_GUI_Type
{
  my($param_details,$ordered_params,$print_string,$phtestclass) = @_;
  my (@params, $param,$param_type,$avator_type,$param_cardinality,$param_function,$param_attribute,$param_desc);
  my ($param_cortex_type,$param_options,$param_default,@options,%param_details);
  my ($flag);
  my ($shadow_param_attribute);
  my ($guitype);
  @params = @$ordered_params;
  $$print_string = "";
  if ($#params > -1)
    {
      $$print_string = "";
      undef $flag;
      foreach $param(@params)
        {
          ($param_type,$avator_type,$param_cardinality,$param_attribute,$param_cortex_type,$param_function,$param_desc,$param_default,$param_options) = split(/\|/,$$param_details{$param});
          ###param_attribute comming from the parser is always m_o (because all OASIS side params are meant to be iCGENTpParam)
          ###With TSS 1.04, We will be using native Choices and Default and autoXML features of the TSS.
          ###Hence param attribute becomes shadow param attribute, used only for data transfer between OASIS and GEN sides.
          ###param attribute itself will be m_s or m_d or m_n based on String, Integer or Double
          $shadow_param_attribute = $param_attribute;
          if ($param_type eq "String")
            {
              $param_attribute =~ s/^m_o/m_s/;
            }
          elsif ($param_type eq "Double")
            {
              $param_attribute =~ s/^m_o/m_d/;
            }
          elsif ($param_type eq "Integer")
            {
              $param_attribute =~ s/^m_o/m_n/;
            }
          ($param_function = $shadow_param_attribute) =~ s/m_o/m_zSet/;

          if ((($param_cardinality eq "0-1")||($param_cardinality eq "1"))&&($param_options))
            {
              $guitype = "list";
            }
          elsif (($param_type eq "String")&&
              (($avator_type eq "LEVEL_TESTCONDITION") ||
              ($avator_type eq "TIMING_TESTCONDITION") ||
              ($avator_type eq "PLIST") ||
              ($avator_type eq "PIN")))

            {
              $guitype  = "extlist";
            }
          else
            {
              $guitype   = "value";
            }

          if (!($flag))
            {
              ##Means first param of the list...
              $$print_string .= "        if (\"$param\" == sParam)\n";
              $flag++;
            }
          else
            {
              $$print_string .= "        else if (\"$param\" == sParam)\n";
            }
          $$print_string .= "        {\n";
          $$print_string .= "            sGuiType = \"$guitype\";\n";
          $$print_string .= "            return true;\n";
          $$print_string .= "        }\n";
        }
    }
}



sub get_code_for_Param_Type
{
  my($param_details,$ordered_params,$print_string,$phtestclass) = @_;
  my (@params, $param,$param_type,$avator_type,$param_cardinality,$param_function,$param_attribute,$param_desc);
  my ($param_cortex_type,$param_options,$param_default,@options,%param_details);
  my ($flag);
  my ($shadow_param_attribute);
  my ($paramtype);
  @params = @$ordered_params;
  $$print_string = "";
  if ($#params > -1)
    {
      $$print_string = "";
      undef $flag;
      foreach $param(@params)
        {
          ($param_type,$avator_type,$param_cardinality,$param_attribute,$param_cortex_type,$param_function,$param_desc,$param_default,$param_options) = split(/\|/,$$param_details{$param});
          ###param_attribute comming from the parser is always m_o (because all OASIS side params are meant to be iCGENTpParam)
          ###With TSS 1.04, We will be using native Choices and Default and autoXML features of the TSS.
          ###Hence param attribute becomes shadow param attribute, used only for data transfer between OASIS and GEN sides.
          ###param attribute itself will be m_s or m_d or m_n based on String, Integer or Double
          $shadow_param_attribute = $param_attribute;
          if ($param_type eq "String")
            {
              $param_attribute =~ s/^m_o/m_s/;
            }
          elsif ($param_type eq "Double")
            {
              $param_attribute =~ s/^m_o/m_d/;
            }
          elsif ($param_type eq "Integer")
            {
              $param_attribute =~ s/^m_o/m_n/;
            }
          ($param_function = $shadow_param_attribute) =~ s/m_o/m_zSet/;

          if ($param_type eq "String")
            {
              if (($avator_type eq "LEVEL_TESTCONDITION")||($avator_type eq "TIMING_TESTCONDITION"))
                {
                  $paramtype = "TestCondition";
                }
              elsif ($avator_type eq "PLIST")
                {
                  $paramtype = "PList";
                }
              else
                {
                  $paramtype = "String";
                }
            }
          elsif (($param_type eq "Integer")||($param_type eq "Long"))
            {
              $paramtype = "Integer";
            }
          elsif (($param_type eq "Float")||($param_type eq "Double"))
            {
              $paramtype = "Double";
            }
          if (!($flag))
            {
              ##Means first param of the list...
              $$print_string .= "        if (\"$param\" == sParam)\n";
              $flag++;
            }
          else
            {
              $$print_string .= "        else if (\"$param\" == sParam)\n";
            }
          $$print_string .= "        {\n";
          $$print_string .= "            sParamType = \"$paramtype\";\n";
          $$print_string .= "            return true;\n";
          $$print_string .= "        }\n";
        }
    }
}


sub get_code_for_Param_Value
 {
  my($param_details,$ordered_params,$print_string,$phtestclass) = @_;
  my (@params, $param,$param_type,$avator_type,$param_cardinality,$param_function,$param_attribute,$param_desc);
  my ($param_cortex_type,$param_options,$param_default,@options,%param_details);
  my ($flag);
  my ($shadow_param_attribute);
  my ($paramtype);
  @params = @$ordered_params;
  $$print_string = "";
  if ($#params > -1)
    {
      $$print_string = "";
      undef $flag;
      foreach $param(@params)
        {
          ($param_type,$avator_type,$param_cardinality,$param_attribute,$param_cortex_type,$param_function,$param_desc,$param_default,$param_options) = split(/\|/,$$param_details{$param});
          ###param_attribute comming from the parser is always m_o (because all OASIS side params are meant to be iCGENTpParam)
          ###With TSS 1.04, We will be using native Choices and Default and autoXML features of the TSS.
          ###Hence param attribute becomes shadow param attribute, used only for data transfer between OASIS and GEN sides.
          ###param attribute itself will be m_s or m_d or m_n based on String, Integer or Double
          $shadow_param_attribute = $param_attribute;
          if ($param_type eq "String")
            {
              $param_attribute =~ s/^m_o/m_s/;
            }
          elsif ($param_type eq "Double")
            {
              $param_attribute =~ s/^m_o/m_d/;
            }
          elsif ($param_type eq "Integer")
            {
              $param_attribute =~ s/^m_o/m_n/;
            }
          ($param_function = $shadow_param_attribute) =~ s/m_o/m_zSet/;

          if ($param_type eq "String")
            {
              if (($avator_type eq "LEVEL_TESTCONDITION")||($avator_type eq "TIMING_TESTCONDITION"))
                {
                  $paramtype = "TestCondition";
                }
              elsif ($avator_type eq "PLIST")
                {
                  $paramtype = "PList";
                }
              else
                {
                  $paramtype = "String";
                }
            }
          elsif (($param_type eq "Integer")||($param_type eq "Long"))
            {
              $paramtype = "Integer";
            }
          elsif (($param_type eq "Float")||($param_type eq "Double"))
            {
              $paramtype = "Double";
            }
          if (!($flag))
            {
              ##Means first param of the list...
              $$print_string .= "        if (\"$param\" == sParam)\n";
              $flag++;
            }
          else
            {
              $$print_string .= "        else if (\"$param\" == sParam)\n";
            }
          $$print_string .= "        {\n";
          if ($param_type eq "String")
            {
              $$print_string .= sprintf("            if (%s.m_sStrValue != IT_UNDEFINED_STR)\n",$shadow_param_attribute);
              $$print_string .= sprintf("            {\n");
              $$print_string .= sprintf("                sParamValue = stringToXML(%s.m_sStrValue.c_str());\n",$shadow_param_attribute);
              $$print_string .= sprintf("            }\n");
            }
          elsif ($param_type eq "Integer")
            {
              $$print_string .= sprintf("            if (%s.m_nIntValue != IT_UNDEFINED_INT)\n",$shadow_param_attribute);
              $$print_string .= sprintf("            {\n");
              $$print_string .= sprintf("                sParamValue = OFCString::toString(%s.m_nIntValue).c_str();\n",$shadow_param_attribute);
              $$print_string .= sprintf("            }\n");
            }
          elsif ($param_type eq "Double")
            {
              $$print_string .= sprintf("            if (%s.m_dDblValue != IT_UNDEFINED_DBL)\n",$shadow_param_attribute);
              $$print_string .= sprintf("            {\n");
              $$print_string .= sprintf("                sParamValue = OFCString::toString(%s.m_dDblValue).c_str();\n",$shadow_param_attribute);
              $$print_string .= sprintf("            }\n");
            }
          $$print_string .= sprintf("            return true;\n");
          $$print_string .= "        }\n";
        }
    }
}




sub get_2Param_GenericSet
{
  my($param_details,$ordered_params,$print_string,$phtestclass) = @_;
  my (@params, $param,$param_type,$avator_type,$param_cardinality,$param_function,$param_attribute,$param_desc);
  my ($param_cortex_type,$param_options,$param_default,@options,%param_details);
  my ($flag);
  my ($shadow_param_attribute);
  my ($member2);
###  // 04/07/2007; sp; hsd#3975; in several test classes, these 3 variables are not used, and thus,
###  // cannot enable level 4 compiler (local variable is initialized but not referenced).
###  // int nIntValue = 0;
###  // double dDblValue = 0.0;
###  // bool bFlag = false;
###  // Instead of hard-coding these 3 here, the perl auto-generation program (build_OASIS_cpp_and_ph.pl)
###  // will auto-insert the 3 variables (nIntValue, dDblValue, bFlag) as needed.
  my $var_bi_include_bFlag     = 0;
  my $var_bi_include_nIntValue = 0;
  my $var_bi_include_dDblValue = 0;
  @params = @$ordered_params;
  $$print_string = "";
  if ($#params > -1)
    {
      $$print_string = "";
      undef $flag;
      foreach $param(@params)
        {
      ($param_type,$avator_type,$param_cardinality,$param_attribute,$param_cortex_type,$param_function,$param_desc,$param_default,$param_options) = split(/\|/,$$param_details{$param});
        ###param_attribute comming from the parser is always m_o (because all OASIS side params are meant to be iCGENTpParam)
        ###With TSS 1.04, We will be using native Choices and Default and autoXML features of the TSS.
        ###Hence param attribute becomes shadow param attribute, used only for data transfer between OASIS and GEN sides.
        ###param attribute itself will be m_s or m_d or m_n based on String, Integer or Double
        $shadow_param_attribute = $param_attribute;
        if ($param_type eq "String")
          {
            $param_attribute =~ s/^m_o/m_s/;
          }
        elsif ($param_type eq "Double")
          {
            $param_attribute =~ s/^m_o/m_d/;
          }
        elsif ($param_type eq "Integer")
          {
            $param_attribute =~ s/^m_o/m_n/;
          }
        ($param_function = $shadow_param_attribute) =~ s/m_o/m_zSet/;
          if (!$flag)
            {
              $$print_string .= "        if (sParamName == _T(\"$param\"))\n";
              $flag = 1;
            }
          else
            {
              $$print_string .= "        else if (sParamName == _T(\"$param\"))\n";
            }
          $$print_string .= "        {\n";
          if ($param_type eq "String")
            {
              $var_bi_include_bFlag = 1;
              $$print_string .= "            bFlag = sValue.empty();\n";
              $$print_string .= "            if (true == bFlag)\n";
              $$print_string .= "            {\n";
              if ($param_default)
                {
                  $param_default =~ s/\;//g;
                  $$print_string .= "                $param_function(_T(\"$param_default\"));\n";
                }
              else
                {
                  $$print_string .= "                $param_function(IT_UNDEFINED_STR);\n";
                }
              $$print_string .= "            }\n";
              $$print_string .= "            else\n";
              $$print_string .= "            {\n";
              $$print_string .= "                $param_function(sValue.c_str());\n";
              $$print_string .= "            }\n";
            }
          elsif ($param_type eq "Integer")
            {
              $var_bi_include_bFlag = 1;
              $var_bi_include_nIntValue = 1;
              $$print_string .= "            bFlag = sValue.empty();\n";
              $$print_string .= "            if (true == bFlag)\n";
              $$print_string .= "            {\n";
              if (($param_default)||($param_default eq "0"))
                {
                  $$print_string .= "                tStatus = xC_tStrToInt(\"$param_default\",&nIntValue);\n";
                  $$print_string .= "                if (IT_FAIL == tStatus)\n";
                  $$print_string .= "                {\n";
                  $$print_string .= "                    return tStatus;\n";
                  $$print_string .= "                }\n";
                  $$print_string .= "                $param_function(nIntValue);\n";
                }
              else
                {
                  $$print_string .= "                $param_function(IT_UNDEFINED_INT);\n";
                }
              $$print_string .= "            }\n";
              $$print_string .= "            else\n";
              $$print_string .= "            {\n";
              $$print_string .= "                tStatus = xC_tStrToInt(sValue.c_str(),&nIntValue);\n";
              $$print_string .= "                if (IT_FAIL == tStatus)\n";
              $$print_string .= "                {\n";
              $$print_string .= "                    return tStatus;\n";
              $$print_string .= "                }\n";
              $$print_string .= "                $param_function(nIntValue);\n";
              $$print_string .= "            }\n";
            }
          elsif ($param_type eq "Double")
            {
              $var_bi_include_bFlag = 1;
              $var_bi_include_dDblValue = 1;
              $$print_string .= "            bFlag = sValue.empty();\n";
              $$print_string .= "            if (true == bFlag)\n";
              $$print_string .= "            {\n";
              if ($param_default)
                {
                  $$print_string .= "                tStatus = xC_tStrToDouble(\"$param_default\",&dDblValue);\n";
                  $$print_string .= "                if (IT_FAIL == tStatus)\n";
                  $$print_string .= "                {\n";
                  $$print_string .= "                    return tStatus;\n";
                  $$print_string .= "                }\n";
                  $$print_string .= "                $param_function(dDblValue);\n";
                }
              else
                {
                  $$print_string .= "                $param_function(IT_UNDEFINED_DBL);\n";
                }
              $$print_string .= "            }\n";
              $$print_string .= "            else\n";
              $$print_string .= "            {\n";
              $$print_string .= "                tStatus = xC_tStrToDouble(sValue.c_str(),&dDblValue);\n";
              $$print_string .= "                if (IT_FAIL == tStatus)\n";
              $$print_string .= "                {\n";
              $$print_string .= "                    return tStatus;\n";
              $$print_string .= "                }\n";
              $$print_string .= "                $param_function(dDblValue);\n";
              $$print_string .= "            }\n";
            }
          $$print_string .= "        }\n";
        }
      $$print_string .= "        else\n";
      $$print_string .= "        {\n";
      $$print_string .= "            return IT_FAIL;\n";
      $$print_string .= "        }\n";
    }
###  // 04/07/2007; sp; hsd#3975; in several test classes, these 3 variables are not used, and thus,
###  // cannot enable level 4 compiler (local variable is initialized but not referenced).
###  // int nIntValue = 0;
###  // double dDblValue = 0.0;
###  // bool bFlag = false;
###  // Instead of hard-coding these 3 here, the perl auto-generation program (build_OASIS_cpp_and_ph.pl)
###  // will auto-insert the 3 variables (nIntValue, dDblValue, bFlag) as needed.
  if ($var_bi_include_bFlag) {
    $$print_string = "        bool bFlag = false;\n" . $$print_string;
  }
  if ($var_bi_include_nIntValue) {
    $$print_string = "        int nIntValue = 0;\n" . $$print_string;
  }
  if ($var_bi_include_dDblValue) {
    $$print_string = "        double dDblValue = 0.0;\n" . $$print_string;
  }
}

sub get_1Param_GenericSet
{
  my($param_details,$ordered_params,$print_string,$phtestclass) = @_;
  my (@params, $param,$param_type,$avator_type,$param_cardinality,$param_function,$param_attribute,$param_desc);
  my ($param_cortex_type,$param_options,$param_default,@options,%param_details);
  my ($flag);
  my ($shadow_param_attribute);
  my ($member2);
  @params = @$ordered_params;
  $$print_string = "";
  undef $flag;
  if ($#params > -1)
    {
      foreach $param(@params)
        {
          ($param_type,$avator_type,$param_cardinality,$param_attribute,$param_cortex_type,$param_function,$param_desc,$param_default,$param_options) = split(/\|/,$$param_details{$param});
        ###param_attribute comming from the parser is always m_o (because all OASIS side params are meant to be iCGENTpParam)
        ###With TSS 1.04, We will be using native Choices and Default and autoXML features of the TSS.
        ###Hence param attribute becomes shadow param attribute, used only for data transfer between OASIS and GEN sides.
        ###param attribute itself will be m_s or m_d or m_n based on String, Integer or Double
        $shadow_param_attribute = $param_attribute;
        if ($param_type eq "String")
          {
            $param_attribute =~ s/^m_o/m_s/;
          }
        elsif ($param_type eq "Double")
          {
            $param_attribute =~ s/^m_o/m_d/;
          }
        elsif ($param_type eq "Integer")
          {
            $param_attribute =~ s/^m_o/m_n/;
          }
        ($param_function = $shadow_param_attribute) =~ s/m_o/m_zSet/;
          if (!$flag)
            {
              $$print_string .= "        if (sParamName == _T(\"$param\"))\n";
              $flag = 1;
            }
          else
            {
              $$print_string .= "        else if (sParamName == _T(\"$param\"))\n";
            }
          $$print_string .= "        {\n";
          $$print_string .= "            $shadow_param_attribute = oParamValue;\n";
          $$print_string .= "        }\n";
        }
      $$print_string .= "        else\n";
      $$print_string .= "        {\n";
      $$print_string .= "            return IT_FAIL;\n";
      $$print_string .= "        }\n";
    }
}

sub get_constructor_params
{
  my($param_details,$print_string,$ordered_param_list,$phtestclass) = @_;
  my (@params, $param,$param_type,$avator_type,$param_cardinality,$param_function,$param_attribute,$param_desc);
  my ($param_cortex_type,$param_options,$param_default,@options,%param_details);
  my ($prototype,$type,$member);
  my ($additional_code1, $addtional_code2);
  my ($phtestclass_ordered_params);
  my ($shadow_param_attribute);
  my ($member2);
  $phtestclass_ordered_params = $phtestclass."_ordered_params";
  @params = @$ordered_param_list;
  $$print_string = "";

  foreach $param(@params)
    {
      ($param_type,$avator_type,$param_cardinality,$param_attribute,$param_cortex_type,$param_function,$param_desc,$param_default,$param_options) = split(/\|/,$$param_details{$param});

        ###param_attribute comming from the parser is always m_o (because all OASIS side params are meant to be iCGENTpParam)
        ###With TSS 1.04, We will be using native Choices and Default and autoXML features of the TSS.
        ###Hence param attribute becomes shadow param attribute, used only for data transfer between OASIS and GEN sides.
        ###param attribute itself will be m_s or m_d or m_n based on String, Integer or Double
        $shadow_param_attribute = $param_attribute;
        if ($param_cardinality =~ /[nN]/)
          {
            $param_attribute =~ s/^m_o/m_v/;
          }
        else
          {
            if ($param_type eq "String")
              {
                $param_attribute =~ s/^m_o/m_s/;
              }
            elsif ($param_type eq "Double")
              {
                $param_attribute =~ s/^m_o/m_d/;
              }
            elsif ($param_type eq "Integer")
              {
                $param_attribute =~ s/^m_o/m_n/;
              }
          }


      if ($avator_type eq "TIMING_TESTCONDITION")
        {
          $type = "IT_TIMING";
        }
      if ($avator_type eq "LEVEL_TESTCONDITION")
        {
          $type = "IT_LEVELS";
        }
      elsif ($avator_type eq "PLIST")
        {
          $type = "IT_PLIST";
        }
      elsif ($avator_type eq "TESTCLASS")
        {
          $type = "IT_TESTCLASS";
        }
      elsif ($avator_type eq "PIN")
        {
          $type = "IT_SIGNAL";
        }
      elsif ($avator_type eq "PATTERN")
        {
          $type = "IT_PATTERN";
        }
      elsif ($avator_type eq "GLOBAL")
        {
          $type = "IT_GLOBAL";
        }
      elsif ($avator_type eq "FUNCTION")
        {
          $type = "IT_FUNCTION";
        }
      elsif ($avator_type eq "LABEL")
        {
          $type = "IT_LABEL";
        }
      elsif ($avator_type eq "INTEGER")
        {
          $type = "IT_INTEGER";
        }
      elsif ($avator_type eq "DOUBLE")
        {
          $type = "IT_DOUBLE";
        }
      elsif ($avator_type eq "STRING")
        {
          $type = "IT_STRING";
        }
      $$print_string .= "    //Intialization for parameter $param\n";
      $$print_string .= "    $shadow_param_attribute.m_sName = \"$param\";\n";
      $$print_string .= "    $shadow_param_attribute.m_tType = $type;\n";

      ###Do Not Intialize Param Cardinality 0-N or 1-N parameters
      if (!($param_cardinality =~ /[nN]/))
        {
          if ((($param_cardinality eq "0-1")) && ($param_options ne ""))
            {
              if ($type eq "IT_INTEGER")
                {
                  $$print_string .= sprintf("    $shadow_param_attribute.m_nIntValue = %s;\n",$param_default);
                  $$print_string .= sprintf("    $param_attribute = %s;\n",$param_default);
                }
              elsif ($type eq "IT_DOUBLE")
                {
                  $$print_string .= sprintf("    $shadow_param_attribute.m_dDblValue = %s;\n",$param_default);
                  $$print_string .= sprintf("    $param_attribute = %s;\n",$param_default);
                }
              else
                {
                  $$print_string .= sprintf("    $shadow_param_attribute.m_sStrValue = \"%s\";\n",$param_default);
                  $$print_string .= sprintf("    $param_attribute = \"%s\";\n",$param_default);
                }
            }
          else
            {
              if ($type eq "IT_INTEGER")
                {
                  $$print_string .= sprintf("    $param_attribute = IT_UNDEFINED_INT;\n");
                }
              elsif ($type eq "IT_DOUBLE")
                {
                  $$print_string .= sprintf("    $param_attribute = IT_UNDEFINED_DBL;\n");
                }
              else
                {
                  $$print_string .= sprintf("    $param_attribute = \"\";\n");
                }
            }
        }
      $$print_string .= "\n";
    }
}

sub get_2Param_GenericGet
{
  my($param_details,$ordered_params,$print_string,$phtestclass) = @_;
  my (@params, $param,$param_type,$avator_type,$param_cardinality,$param_function,$param_attribute,$param_desc);
  my ($param_cortex_type,$param_options,$param_default,@options,%param_details);
  my ($flag);
  my ($shadow_param_attribute);
  my ($member2);
  @params = @$ordered_params;
  $$print_string = "";
  undef $flag;
  if ($#params > -1)
      {
        foreach $param(@params)
          {
      ($param_type,$avator_type,$param_cardinality,$param_attribute,$param_cortex_type,$param_function,$param_desc,$param_default,$param_options) = split(/\|/,$$param_details{$param});
        ###param_attribute comming from the parser is always m_o (because all OASIS side params are meant to be iCGENTpParam)
        ###With TSS 1.04, We will be using native Choices and Default and autoXML features of the TSS.
        ###Hence param attribute becomes shadow param attribute, used only for data transfer between OASIS and GEN sides.
        ###param attribute itself will be m_s or m_d or m_n based on String, Integer or Double
        $shadow_param_attribute = $param_attribute;
        if ($param_type eq "String")
          {
            $param_attribute =~ s/^m_o/m_s/;
          }
        elsif ($param_type eq "Double")
          {
            $param_attribute =~ s/^m_o/m_d/;
          }
        elsif ($param_type eq "Integer")
          {
            $param_attribute =~ s/^m_o/m_n/;
          }
        ($param_function = $shadow_param_attribute) =~ s/m_o/m_zSet/;
            if (!$flag)
              {
                $$print_string .= "        if (sParamName == _T(\"$param\"))\n";
                $flag = 1;
              }
            else
              {
                $$print_string .= "        else if (sParamName == _T(\"$param\"))\n";
              }
            $$print_string .= "        {\n";
            if ($param_type eq "String")
              {
                $$print_string .= "            if ($shadow_param_attribute.m_sStrValue != IT_UNDEFINED_STR)\n";
                $$print_string .= "            {\n";
                $$print_string .= "                sValue =  $shadow_param_attribute.m_sStrValue.c_str();\n";
                $$print_string .= "            }\n";
              }
            elsif ($param_type eq "Integer")
              {
                $$print_string .= "            if ($shadow_param_attribute.m_nIntValue != IT_UNDEFINED_INT)\n";
                $$print_string .= "            {\n";
                $$print_string .= "                sValue =  OFCString::toString($shadow_param_attribute.m_nIntValue).c_str();\n";
                $$print_string .= "            }\n";
              }
            elsif ($param_type eq "Double")
              {
                $$print_string .= "            if (!((IT_UNDEFINED_DBL - 1 < $shadow_param_attribute.m_dDblValue) && ($shadow_param_attribute.m_dDblValue < IT_UNDEFINED_DBL + 1)))\n";
                $$print_string .= "            {\n";
                $$print_string .= "                sValue =  OFCString::toString($shadow_param_attribute.m_dDblValue).c_str();\n";
                $$print_string .= "            }\n";
              }
            $$print_string .= "        }\n";
          }
        $$print_string .= "        else\n";
        $$print_string .= "        {\n";
        $$print_string .= "            return IT_FAIL;\n";
        $$print_string .= "        }\n";
      }

}

sub get_1Param_GenericGet
{
  my($param_details,$ordered_params,$print_string,$phtestclass) = @_;
  my (@params, $param,$param_type,$avator_type,$param_cardinality,$param_function,$param_attribute,$param_desc);
  my ($param_cortex_type,$param_options,$param_default,@options,%param_details);
  my ($flag);
  my ($shadow_param_attribute);
  my ($member2);
  @params = @$ordered_params;
  $$print_string = "";
  undef $flag;
   if ($#params > -1)
    {
      foreach $param(@params)
        {
      ($param_type,$avator_type,$param_cardinality,$param_attribute,$param_cortex_type,$param_function,$param_desc,$param_default,$param_options) = split(/\|/,$$param_details{$param});
        ###param_attribute comming from the parser is always m_o (because all OASIS side params are meant to be iCGENTpParam)
        ###With TSS 1.04, We will be using native Choices and Default and autoXML features of the TSS.
        ###Hence param attribute becomes shadow param attribute, used only for data transfer between OASIS and GEN sides.
        ###param attribute itself will be m_s or m_d or m_n based on String, Integer or Double
        $shadow_param_attribute = $param_attribute;
        if ($param_type eq "String")
          {
            $param_attribute =~ s/^m_o/m_s/;
          }
        elsif ($param_type eq "Double")
          {
            $param_attribute =~ s/^m_o/m_d/;
          }
        elsif ($param_type eq "Integer")
          {
            $param_attribute =~ s/^m_o/m_n/;
          }
        ($param_function = $shadow_param_attribute) =~ s/m_o/m_zSet/;
          if (!$flag)
            {
              $$print_string .= "        if (sParamName == _T(\"$param\"))\n";
              $flag = 1;
            }
          else
            {
              $$print_string .= "        else if (sParamName == _T(\"$param\"))\n";
            }
          $$print_string .= "        {\n";
          $$print_string .= "            oParamValue = $shadow_param_attribute;\n";
          $$print_string .= "        }\n";
        }
      $$print_string .= "        else\n";
      $$print_string .= "        {\n";
      $$print_string .= "            return IT_FAIL;\n";
      $$print_string .= "        }\n";
    }
}

sub get_getValues
{
  my($param_details,$ordered_params,$print_string,$phtestclass) = @_;
  my (@params, $param,$param_type,$avator_type,$param_cardinality,$param_function,$param_attribute,$param_desc);
  my ($param_cortex_type,$param_options,$param_default,@options,%param_details);
  my ($flag);
  my ($shadow_param_attribute);
  my ($member2);
  @params = @$ordered_params;
  $$print_string = "";
  foreach $param(@params)
    {
      ($param_type,$avator_type,$param_cardinality,$param_attribute,$param_cortex_type,$param_function,$param_desc,$param_default,$param_options) = split(/\|/,$$param_details{$param});
        ###param_attribute comming from the parser is always m_o (because all OASIS side params are meant to be iCGENTpParam)
        ###With TSS 1.04, We will be using native Choices and Default and autoXML features of the TSS.
        ###Hence param attribute becomes shadow param attribute, used only for data transfer between OASIS and GEN sides.
        ###param attribute itself will be m_s or m_d or m_n based on String, Integer or Double
        $shadow_param_attribute = $param_attribute;
        if ($param_type eq "String")
          {
            $param_attribute =~ s/^m_o/m_s/;
          }
        elsif ($param_type eq "Double")
          {
            $param_attribute =~ s/^m_o/m_d/;
          }
        elsif ($param_type eq "Integer")
          {
            $param_attribute =~ s/^m_o/m_n/;
          }
        ($param_function = $shadow_param_attribute) =~ s/m_o/m_zSet/;

      $$print_string .= "    sParam = \"$param\";\n";
      $$print_string .= "    m_tGenericGet(sParam,sValue);\n";
      $$print_string .= "    pPackager = new TestParamPackager();\n";
      $$print_string .= "    pPackager->setParameter(sParam.c_str());\n";
      $$print_string .= "    pPackager->addValue(sValue.c_str());\n";

;      $$print_string .= "    sStr  = sParam;\n";
;      $$print_string .= "    sStr += \"=\";\n";
;      $$print_string .= "    sStr += sValue;   //Note if the parameter is an array then values are \",\" separated and concatenated.\n";
      $$print_string .= "    values.push_back(pPackager->getString());\n";
      $$print_string .= "    delete pPackager;\n\n";
    }
}


sub get_getXMLDesc
{
  my($param_details,$ordered_params,$print_string,$phtestclass) = @_;
  my (@params, $param,$param_type,$avator_type,$param_cardinality,$param_function,$param_attribute,$param_desc);
  my ($param_cortex_type,$param_options,$param_default,@options,%param_details);
  my ($shadow_param_attribute);
  my ($member2);
  @params = @$ordered_params;
  $$print_string = "";
  foreach $param(@params)
    {
      ($param_type,$avator_type,$param_cardinality,$param_attribute,$param_cortex_type,$param_function,$param_desc,$param_default,$param_options) = split(/\|/,$$param_details{$param});
        ###param_attribute comming from the parser is always m_o (because all OASIS side params are meant to be iCGENTpParam)
        ###With TSS 1.04, We will be using native Choices and Default and autoXML features of the TSS.
        ###Hence param attribute becomes shadow param attribute, used only for data transfer between OASIS and GEN sides.
        ###param attribute itself will be m_s or m_d or m_n based on String, Integer or Double
        $shadow_param_attribute = $param_attribute;
        if ($param_type eq "String")
          {
            $param_attribute =~ s/^m_o/m_s/;
          }
        elsif ($param_type eq "Double")
          {
            $param_attribute =~ s/^m_o/m_d/;
          }
        elsif ($param_type eq "Integer")
          {
            $param_attribute =~ s/^m_o/m_n/;
          }
        ($param_function = $shadow_param_attribute) =~ s/m_o/m_zSet/;
      if ($param_type eq "String")
        {
          $$print_string .= "    if ($param_attribute.m_sStrValue != IT_UNDEFINED_STR)\n";
          $$print_string .= "    {\n";
          $$print_string .= "        m_oXMLParamDescriptor.setValue(OFCString(\"$param\"),(OFCString)$param_attribute.m_sStrValue);\n";
          $$print_string .= "    }\n\n";
          $$print_string .= "    else\n";
          $$print_string .= "    {\n";
          $$print_string .= "        m_oXMLParamDescriptor.setValue(OFCString(\"$param\"),(OFCString)(\"\"));\n";
          $$print_string .= "    }\n\n";
        }
      elsif ($param_type eq "Integer")
        {
          $$print_string .= "    if ($param_attribute.m_nIntValue != IT_UNDEFINED_INT)\n";
          $$print_string .= "    {\n";
          $$print_string .= "        m_oXMLParamDescriptor.setValue(OFCString(\"$param\"),OFCString::toString($param_attribute.m_nIntValue));\n";
          $$print_string .= "    }\n\n";
          $$print_string .= "    else\n";
          $$print_string .= "    {\n";
          $$print_string .= "        m_oXMLParamDescriptor.setValue(OFCString(\"$param\"),(OFCString)(\"\"));\n";
          $$print_string .= "    }\n\n";
        }
      elsif ($param_type eq "Double")
        {
          $$print_string .= "    if (!((IT_UNDEFINED_DBL - 1 < $param_attribute.m_dDblValue) && ($param_attribute.m_dDblValue < IT_UNDEFINED_DBL + 1)))\n";
          $$print_string .= "    {\n";
          $$print_string .= "        m_oXMLParamDescriptor.setValue(OFCString(\"$param\"),OFCString::toString($param_attribute.m_dDblValue));\n";
          $$print_string .= "    }\n\n";
          $$print_string .= "    else\n";
          $$print_string .= "    {\n";
          $$print_string .= "        m_oXMLParamDescriptor.setValue(OFCString(\"$param\"),(OFCString)(\"\"));\n";
          $$print_string .= "    }\n\n";
        }

      if ($avator_type eq "TIMING_TESTCONDITION")
        {
          $$print_string .= "    ListItems.clear();\n";
          $$print_string .= "    m_zGetTimingTC(ListItems);\n";
          $$print_string .= "    m_oXMLParamDescriptor.setListItems(OFCString(\"$param\"),ListItems);\n\n";
        }
      elsif ($avator_type eq "LEVEL_TESTCONDITION")
        {
          $$print_string .= "    ListItems.clear();\n";
          $$print_string .= "    m_zGetLevelsTC(ListItems);\n";
          $$print_string .= "    m_oXMLParamDescriptor.setListItems(OFCString(\"$param\"),ListItems);\n\n";
        }
      elsif ($avator_type eq "PLIST")
        {
          $$print_string .= "    ListItems.clear();\n";
          $$print_string .= "    m_zGetPlists(ListItems);\n";
          $$print_string .= "    m_oXMLParamDescriptor.setListItems(OFCString(\"$param\"),ListItems);\n\n";
        }
      elsif ($avator_type eq "PIN")
        {
          $$print_string .= "    ListItems.clear();\n";
          $$print_string .= "    m_zGetSignalPins(ListItems);\n";
          $$print_string .= "    m_zGetPSPins(ListItems);\n";
          $$print_string .= "    m_oXMLParamDescriptor.setListItems(OFCString(\"$param\"),ListItems);\n\n";
        }
      elsif ((($param_cardinality eq "0-1")||($param_cardinality eq "1"))&&($param_options))
        {
          @options = split(/\&/,$param_options);
          $$print_string .= "    ListItems.clear();\n";
          foreach $option(@options)
            {
              $$print_string .= "    ListItems.push_back(\"".$option."\");\n";
            }
          $$print_string .= "    m_oXMLParamDescriptor.setListItems(OFCString(\"$param\"),ListItems);\n\n";
         }
    }
}




#***********************************************************
 # NOTE: Please do not modify Revision History Directly via your editor.
 # Please only modify via CVS tools.

 # Revision History
 # $Log: build_OASIS_cpp_and_ph.pl,v $
 # Revision 2.8.2.1.6.4.2.1.12.1.12.3.2.1.2.1  2007/09/16 07:08:41  pjkransd
 # HSD_ID:4881
 #
 # CHANGE_DESCRIPTION:parameters of type Pin should now create iCGENTpObjects with m_tType of IT_SIGNAL
 #
 # REG_TEST:
 #
 # Revision 2.8.2.1.6.4.2.1.12.1.12.3.2.1  2007/05/18 05:39:28  amathur1
 # HSD_ID:4211
 #
 # CHANGE_DESCRIPTION:
 # checking for Not Null TimingPtr instead of NULL pointer. This was preventing call to updateTMapTestCondition()
 #
 # REG_TEST:
 #
 # Revision 2.8.2.1.6.4.2.1.12.1.12.3  2007/04/17 15:47:49  asharm7
 # HSD_ID:3975
 #
 # CHANGE_DESCRIPTION:Update from lcasti2 to resolve level4 warnings with CorTex 4.9
 #
 # REG_TEST:
 #
 # Revision 2.8.2.1.6.4.2.1.12.1.12.2  2007/04/12 23:11:33  asharm7
 # HSD_ID:4004
 #
 # CHANGE_DESCRIPTION:Added support to parse CMTP tokens
 #
 # REG_TEST:
 #
 # Revision 2.8.2.1.6.4.2.1.12.1  2006/10/12 17:47:23  amathur1
 # HSD_ID:3238
 #
 # CHANGE_DESCRIPTION:
 # Removing Preprocessor _PRE_TSS201A_ code from cvs since building 4.8 only on TSS204 onwards TSS
 #
 # REG_TEST:
 #
 # Revision 2.8.2.1.6.4.2.1  2006/04/03 22:32:31  rflore2
 # HSD_ID:908
 #
 # CHANGE_DESCRIPTION:
 # templates can now be built from any arbitrary location not just from GEN\RevX.Y.Z\templates
 #
 # REG_TEST:
 #
 # Revision 2.8.2.1.6.4  2006/01/26 17:17:54  amr\kpalli
 # HSD_ID:1672
 #
 # CHANGE_DESCRIPTION:Updated code to handle default value of 0 only for integer data types
 #
 # REG_TEST:
 #
 # Revision 2.8.2.1.6.3  2006/01/26 16:17:25  amr\kpalli
 # HSD_ID:1672
 #
 # CHANGE_DESCRIPTION:Updated code to handle default value of 0 only for integer data types
 #
 # REG_TEST:
 #
 # Revision 2.8.2.1.6.2  2006/01/26 00:03:09  amr\kpalli
 # HSD_ID:1672
 #
 # CHANGE_DESCRIPTION: Updated code to handle a default value of 0 for integer data types.
 #
 # REG_TEST:
 #
 # Revision 2.8.2.1.6.1  2005/12/13 19:56:31  mmohan3
 # HSD_ID:1048
 #
 # CHANGE_DESCRIPTION:TSS 201B support
 #
 # REG_TEST:
 #
 # Revision 2.8.2.1  2005/08/26 01:02:40  svpathy
 # HSD_ID:921
 #
 # CHANGE_DESCRIPTION:
 # Updated the get_getValues() function to use TestParamPackager.
 # Updated get_code_for_Param_Value() to use stringToXML for strings.
 #
 # REG_TEST:
 # Test iCRRLTest RRL_PBIST_DRIVE_BACKSLASH
 # {
 #     debug_mode = "VERBOSE";
 #     patlist = "PBIST_CTV_Plist";
 #     timings = "iAppTimings50MHz";
 #     level  = "iAppLevelMin";
 #     raster_setup = "RRL.cfg!UL1";
 #     rrl_mode  = "RASTER_ONLY";
 #     rrl_access  = "PBIST_TRIGGER_CAPTURE";
 #     eng_destinations = "STDIO_ONLY";
 #     eng_outfile = "c:\\temp\\abc.txt";
 #     base_number = 0;
 #     topo_mapper_func = "iAPP_userfunc!RRLTopoFuncForPBIST";
 #     lya_cellselect_func = "iAPP_userfunc!RRLLYACellSelectFunc";
 #     capture_limit = 34000;
 #     max_lya_count = 34000;
 # }
 #
 #
 # Test iCRRLTest RRL_PBIST_UNC_BACKSLASH
 # {
 #     debug_mode = "VERBOSE";
 #     patlist = "PBIST_CTV_Plist";
 #     timings = "iAppTimings50MHz";
 #     level  = "iAppLevelMin";
 #     raster_setup = "RRL.cfg!UL1";
 #     rrl_mode  = "RASTER_ONLY";
 #     rrl_access  = "PBIST_TRIGGER_CAPTURE";
 #     eng_destinations = "STDIO_ONLY";
 #     eng_outfile = "\\\\azea1pub04\\temp\\abc.txt";
 #     base_number = 0;
 #     topo_mapper_func = "iAPP_userfunc!RRLTopoFuncForPBIST";
 #     lya_cellselect_func = "iAPP_userfunc!RRLLYACellSelectFunc";
 #     capture_limit = 34000;
 #     max_lya_count = 34000;
 # }
 #
 # Revision 2.8  2005/06/03 00:35:57  rflore2
 # HSD_ID: N/A
 #
 # CHANGE_DESCRIPTION:
 # Merge 3.3.0 branch
 #
 # REG_TEST:
 #
 # Revision 2.6.4.3  2005/05/31 18:21:25  rflore2
 # HSD_ID: N/A
 #
 # CHANGE_DESCRIPTION:
 # Support development and build scripts properly
 #
 # REG_TEST:
 #
 # Revision 2.6.4.2  2005/05/31 18:14:46  rflore2
 # HSD_ID: N/A
 #
 # CHANGE_DESCRIPTION:
 # Support development and build scripts properly
 #
 # REG_TEST:
 #
 # Revision 2.6.4.1  2005/05/27 00:03:08  pjkransd
 # HSD_ID:N/A
 #
 # DESCRIPTION:
 # Build Script to create development environment directly from CVS
 #
 # Revision 2.6  2005/03/07 23:09:40  rflore2
 # HSD_ID: N/A
 #
 # CHANGE_DESCRIPTION:
 # Merge 3.1.0 Branch
 #
 # REG_TEST:
 #
 # Revision 2.4.2.1  2005/01/20 23:15:33  rflore2
 # Add else statement to handle the case where ph file does not specify behavior for undefined ports. The default behavior is now to fail with an "UNDEFINED PORT" error message
 #
 # Revision 2.4  2005/01/18 23:34:55  rflore2
 # Merge 3.0.0 branch in main trunk
 #
 # Revision 2.2.4.2  2005/01/05 16:41:59  svpathy
 # CHANGE_ID: OVERRIDED by svpathy - NO BUGID
 #  CHANGE_DESCRIPTION:(Type the desc on the next line)
 #  Updated to match phsyntaxchecker requirement Not to have both TSS keywords Options and Default and AVATOR_DEFAULTS and AVATOR_OPTIONS.
 #  REG_TEST:(Type on the next line)
 #
 # Revision 2.2.4.1  2005/01/03 05:12:47  svpathy
 # CHANGE_ID: OVERRIDED by svpathy - NO BUGID
 #  CHANGE_DESCRIPTION:(Type the desc on the next line)
 #  Update to the scripts to enable autoXML feature from TSS
 #  REG_TEST:(Type on the next line)
 #
 # Revision 2.2  2004/11/08 18:00:37  svpathy
 # CHANGE_ID: OVERRIDED by svpathy - NO BUGID
 #  CHANGE_DESCRIPTION:(Type the desc on the next line)
 #  Updated code to provide proper exit port handling based on ph file avator port settings.
 #  updated code to provide constructor initialization of test tempalte interface parameters
 #  REG_TEST:(Type on the next line)
 #
 # Revision 2.1  2004/09/07 22:56:47  dhchen
 # CHANGE_ID: OVERRIDED by dhchen - NO BUGID
 #  CHANGE_DESCRIPTION:(Type the desc on the next line)
 #
 #  Initial check in
 #  REG_TEST:(Type on the next line)
 #
 #***********************************************************
