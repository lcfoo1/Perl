#----------------------------------------------------------------------;
#
#        FILENAME:      CorTeXPerlModule.pm
#        FILE REV:      $Revision: 1.3.54.1.4.5 $
#         S/W REV:      perl
#    COMPILER REV:      n/a
#     LAST UPDATE:      10-Jul-2004
#  LAST UPDATE BY:      Sundar (sundar.pathy@intel.com)
#      CREATED BY:      Sundar (sundar.pathy@intel.com)
#
#        ABSTRACT:      This perl script has all the common perl functions grouped
#                       together.  provides a common implementation for all other scripts
#----------------------------------------------------------------------;

package CorTeXPerlModule;
BEGIN
{
  use Exporter   ();
  our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

  # set the version for version checking
  $VERSION     = 1.00;

  @ISA         = qw(Exporter);
  @EXPORT      = qw(&func1 &func2 &func4);
  %EXPORT_TAGS = ( );     # None in this module....eg: TAG => [ qw!name1 name2! ],
  # your exported package globals go here,
  # as well as any optionally exported functions
  #None in this module.
  ##@EXPORT_OK   = qw($Var1 %Hashit &func3);
}
our @EXPORT_OK;

# exported package globals go here
#our $Var1;
#our %Hashit;

# non-exported package globals go here
##our @more;
##our $stuff;

# initialize package globals, first exported ones
##$Var1   = '';
##%Hashit = ();

# then the others (which are still accessible as $Some::Module::stuff)
##$stuff  = '';
##@more   = ();
# all file-scoped lexicals must be created before
# the functions below that use them.

# file-private lexicals go here
##my $priv_var    = '';
##my %secret_hash = ();

# here's a file-private function as a closure,
# callable as &$priv_func;  it cannot be prototyped.
##my $priv_func = sub
##  {
##    # stuff goes here.
##  };


# make all your functions, whether exported or not;
# remember to put something interesting in the {} stubs
sub stripWhiteSpace      {}    # no prototype
sub getLastModTime       {}
sub getFilesFromDir      {}
sub getTokens            {}
sub getOptions           {}
sub parsePHfile          {}
# module clean-up code here (global destructor)
END { }
## YOUR CODE GOES HERE

#
#----------------------------------------------------------------------
#  This subroutine operates on input string or on $_
#  strips out white space at the beginning and the end of string
#  When calling call as follows
#  $c = "   abcd my test  ";
#  &strip_white_space(\$c);
#----------------------------------------------------------------------
sub stripWhiteSpace {
  my($string) = @_;
  if ($string) {
    $$string =~ s/^\s+//; # strip leading white space;
    $$string =~ s/\s+$//; # strip trailing white space;
  }
  else {
    s/^\s+//; # strip leading white space;
    s/\s+$//; # strip trailing white space;
  }
}

#
#----------------------------------------------------------------------
#  This subroutine gets the last modified time of a input file $file
#  It returns the value as $last_mod...
#  When calling call as follows
#  $cpp = "mytestfile.txt"
#  &get_last_modtime($cpp,\$mtime);
#  printf("file %s got modified last at %s\n",$cpp,$mtime);
#----------------------------------------------------------------------
sub getLastModTime {
  my($file,$last_mod) = @_;
  my ($c,$day,$mon,$date,$hour,$min,$sec,$yr);
  $c = scalar localtime( (stat($file))[9]);
  stripWhiteSpace(\$c);
  if ($c =~ /^([a-zA-Z]+)\s+([a-zA-Z]+)\s+(\d+)\s+(\d+):(\d+):(\d+)\s+(\d+)$/) {
    $day = $1;
    $mon = $2;
    $date = $3;
    $hour = $4;
    $min = $5;
    $sec = $6;
    $yr = $7;
    $$last_mod = $date."_".$mon."_".$yr."_".$hour."_".$min."_".$sec;
  }
}

#----------------------------------------------------------------------
#  This subroutine gets all files in a directory matching the passed in
#  regular expression ($regexp) and the directory is ($dir)
#  Files are returned in an array @files.
#  &getfilesfromdir("\.ncb|\.suo|\.bak","./code",\@files);
#  retrieves all files with extensions .ncb, .suo and .bak from the directory ./code
#  files are returned in @files array
#----------------------------------------------------------------------
sub getFilesFromDir {
  my($regexp,$dir,$files) = @_;
  if(-e $dir) {
    opendir(DIR,$dir)||die "FATAL ERROR::Can't open the directory \"$dir\"\n\n\n"; ;
    @$files = grep(/$regexp/,readdir(DIR));
    closedir(DIR);
  }
}


#----------------------------------------------------------------------
#  This subroutine gets a UID for the visual studio environment
#  the UID is returned in the variable $uid
#  &genUID(\$uid);
#----------------------------------------------------------------------
sub genUID {
  my($uid) = @_;
  if ($ENV{"VSCOMNTOOLS"}) {
    ($uidgen = $ENV{"VSCOMNTOOLS"})=~ s/\"//g;
    $uidgen = $uidgen."uuidgen.exe";
    $uidgen = "\"".$uidgen."\" > tmpuid.txt";
    if (system($uidgen) == 0) {
      open (UIDFILE,"tmpuid.txt")||die "cannot open \"tmpuid.txt\"...exiting...\n";
      while (<UIDFILE>) {
        if (/^\w/) {
          ($$uid = $_) =~ s/\s+//g;
          $$uid =~ tr/a-z/A-Z/;
          last;
        }
      }
      close UIDFILE;
    }
    unlink "tmpuid.txt";
  }
}


#----------------------------------------------------------------------
#  This subroutine splits the input string $string into tokens based on
#  the input regular expression ($regexp)
#  tokens are returned in an array @tokens.
#  $tst = "my name is sundar"
#  &getTokens("\s+","./code",\@tokens);
#----------------------------------------------------------------------
sub getTokens {
  my($regexp,$string,$tokens) = @_;
  @$tokens = split(/$regexp/,$string);
}

#----------------------------------------------------------------------
#  CorTeX Get Options subroutine
#
#  This subroutine parses through an argument array looking for -ab.. like
#  entries.  It builds an associative array with each option passed.  The
#  user can check for specific options by simply $option{'a'}.  In addition,
#  options can have arguments (not starting with -)
#
#  e.g. given
#    script.pl -abc aleph -d bet -f file1 file2 file3 -t type1 type2 type3
#
#  &getOptions(\@ARGV,\%all_options,\%option,\@all_args);
#  will parse the arguments to script.pl into the following:
#
#  %all_options associative array indicates whether an option is present or not
#  In the above example, it translates to
#  all_options{abc} = 1
#  all_options{d}   = 1
#  all_options{f}   = 1
#  all_options{t}   = 1
#
#  %option associative array indicates for a given option what are its arguments
#  In the above example, it translates to
#  option{abc} = aleph
#  option{d}   = bet
#  option{f}   = file1 file2 file3
#  option{t}   = type1 type2 type3
#
#  @all_args array indicates for a given option what are its arguments
#  In the above example, it translates to
#  all_args[0]=aleph
#  all_args[1]=bet
#  all_args[2]=file1
#  all_args[3]=file2
#  all_args[4]=file3
#  all_args[5]=type1
#  all_args[6]=type2
#  all_args[7]=type3
#
#
#
#
#----------------------------------------------------------------------#
sub getOptions {
  my($args,$all_options,$option,$all_args) = @_;
  my ($arg,$previous_opt);
  my ($key,$str);
  $previous_opt = "";
  foreach $arg (@$args) {
    if ($arg =~ /^-([a-zA-Z0-9]+)/) {
      # if this is argument an option? (ie -ab or -c or -t etc...)
      $$all_options{$1}++;
      $previous_opt = $1;
    }
    else {
      $$option{$previous_opt} .= $arg." ";
      push(@$all_args,$arg);
    }
  }
  foreach $key(keys %$option) {
    ##Strip the leading and trailing white space from the arguments
    $str = $$option{$key};
    stripWhiteSpace(\$str);
    $$option{$key} = $str;
  }
}


sub parsePHfile {
  my ($phfile,$debug_print,$phtestclass,$public_bases, $ordered_param_list,$param_details,$port_details,$tc_vector,$plist_vector, $error_count,$ph_type) = @_;
  my ($line,$comment,$param_flag,$param_section_open_brace);
  my ($param_open_brace,$param_def_done);
  my ($param_type,$param_name,$avator_type,$cmtp_type,$param_cardinality,$param_function);
  my ($param_attribute,$param_cortex_type,$param_desc, $param_default,$param_options,$gui_type);
  my (@options,$tmp_option);
  my ($port_info_check,$default_error_list,$PH_TYPE,$TOS_file_type);
  ;# hsd#3700:error check Parameter <names> in .ph file for uniqueness
  my %error_param_name_h = ();
  #$param_default = "PARAM_DEFAULT_NOT_DEFINED";
  open (PHFILE, $phfile) or die "In parsePHfile routine..Cannot Open \"$phfile\" for reading. Exiting....\n";
  while (<PHFILE>) {
    undef $line;
    undef $comment;
    $line = $_;
    CorTeXPerlModule::stripWhiteSpace(\$line);
    ($line,$comment) = split(/\#/,$line,2);
    CorTeXPerlModule::stripWhiteSpace(\$line);
    CorTeXPerlModule::stripWhiteSpace(\$comment);

    if ($comment !~ /^AVATOR/ && $comment !~ /^CMTP/) {
      $comment = ""; ###Null out any comments which is not a AVATOR or CORTEX keyword
    }
    if (($line eq "") && ($comment eq "")) {
      next;
    }
    if (($line eq "") && ($comment ne "")) {
      $line = $comment;  ##copy it back to $line for ease of use.
      $comment = "";     ##null out comment
    }
    if ($line =~ /^AVATOR_PORT\s+(.+)/) {
      $rest = $1;
      if ($rest =~ /(.+)"(\w+)"\s+"(.+)"/) {
        $org_port = $1;
        $port_type = "\"".$2."\"";
        $port_desc = "\"".$3."\"";
        ($port = $org_port) =~ s/\s+//g;
        $port_info = $port."|".$port_type."|".$port_desc;
        push(@$port_details,$port_info);
        $port_info_check++;
      }
    }
    if ($line =~ /^CMTP_MODE\s+(.+)/) {
      $rest = $1;
      $port_info = "||".$1;
      push(@$port_details,$port_info);
    }
    if ($line =~ /^PublicBases\s*=\s*(.+);$/) {
      $$public_bases = $1;
      if ($debug_print eq "1") {
        printf("phfile \"%s\" base class \"%s\"\n",$phfile, $$public_bases);
      }
      if ($$public_bases =~ /GEN/) {
        $TOS_file_type = "GEN";
      }
      else {
        $TOS_file_type = "OASIS";
      }
      next;
    }
    if ($line =~ /^TestClass\s*=\s*(\w+)\s*;/) {
      $$phtestclass = $1;
      if ($debug_print eq "1") {
        printf("phfile \"%s\" class \"%s\"\n",$phfile, $$phtestclass);
      }
      next;
    }
    if ($line =~ /^Parameters/) {
      $param_flag = 1;
      next;
    }
    if ($param_flag == 1) {
      if (($param_section_open_brace == 0)&&($line =~ /\{/)) {
        $param_section_open_brace = 1;
        next;
      }
      if ($param_section_open_brace == 1) {
        if (($param_def_done != 1) &&($line =~ /^(\w+)\s+(\w+)/)) {
          #param definition line
          $param_def_done = 1;
          $param_type = $1;
          $param_name = $2;

          ;# hsd#3700:error check Parameter <names> in .ph file for uniqueness
          if (defined $error_param_name_h{$param_name}) {
            printf "ERROR::duplicate parameter name ($param_name): line %d of file %s\n", $., $phfile;
            printf "ERROR::", $error_param_name_h{$param_name}, "\n";
            $errorflag++;
          }
          else {
            ;# register the name
            $error_param_name_h{$param_name} = "parameter name ($param_name) encountered first at line: $.";
          }

          ##Added for CMTP
          if ($comment =~ /CMTP\s+(\w+)/) {
            $cmtp_type = $1;
          }
          if ($comment =~ /AVATOR\s+(\w+)/) {
            $avator_type = $1;
          }
          if ($avator_type eq "PLIST") {
            #Plist Param
            push(@$plist_vector,$param_name);
          }
          if ($avator_type =~ /TESTCONDITION/) {
            # timing or levels test condition parameter
            push(@$tc_vector,$param_name);
          }
          #print "Found Param Definition\n";
          next;
        }
        if ($param_def_done == 1) {
          if (($param_open_brace == 0)&&($line =~ /\{/)) {
            $param_open_brace = 1;
            next;
          }
          if ($param_open_brace == 1) {
            if ($line =~ /^AVATOR_OPTIONS\s*=\s*(.+);$/) {
              @options = split(/\,/,$1);
              undef $param_options;

              ;# hsd#3689: error check #AVATOR_OPTIONS in .ph
              my $b3689 = 0;
              if (($param_type =~ /String/i) && (scalar(@options) > 1)) {
                $b3689 = 1;
              }

              foreach $option (@options) {
                CorTeXPerlModule::stripWhiteSpace(\$option);
                $option =~ s/\"//g;

                ;# hsd#3689: error check #AVATOR_OPTIONS in .ph
                if (($b3689 == 1) && ($option !~ /^\w+$/)) {
                  printf("ERROR::illegal formatted AVATOR_OPTIONS keyword {$option} at line %d of file %s\n", $., $phfile);
                  printf("ERROR::enumerated string type checks are enabled and must consist of word characters only => [0-9a-zA-Z_]\n");
                  $errorflag++;
                }

                if ($param_options ne "") {
                  $param_options .= "&";
                  $param_options .= $option;
                }
                else {
                  $param_options = $option;
                }
              }
            }
            elsif ($line =~ /^AVATOR_DEFAULT\s*=\s*(.+);$/) {
              $param_default = $1;
              CorTeXPerlModule::stripWhiteSpace(\$param_default);
              $param_default =~ s/\"//g;
            }
            elsif ($line =~ /(\w+)\s*=\s*([\w-]+)\s*;$/) {
              if ($1 eq "Cardinality") {
                $param_cardinality = $2;
                ###Convert 1-N or 0-N to 1-n and 0-n for CMT compatibility
                $param_cardinality =~ s/N/n/g;
              }
              elsif ($1 eq "Attribute") {
                $param_attribute = $2;
                #if ($comment =~ /CORTEX_TYPE\s+(\w+)/)
                #  {
                #    $param_cortex_type = $1;
                #  }
              }
              elsif ($1 eq "SetFunction") {
                $param_function = $2;
              }
              elsif ($1 eq "Description") {
                $param_desc = $2;
              }
              elsif ($1 eq "GuiType") {
                # $gui_type  = $2;
              }
              elsif ($1 eq "Choices") {
                # $choices  = $2;
              }
              elsif ($1 eq "Default") {
                # $default  = $2;
              }
              else {
                printf("ERROR::illegal keyword within the parameter def in line %d of file %s\n", $.,$phfile);
                $errorflag++;
              }
            }
            elsif ($line =~ /(\w+)\s*=\s*\"(.+)\"\s*;$/) {
              #printf("line <<%s>><<%s>><<%s>>\n",$line,$1,$2);
              if ($1 eq "Description") {
                $param_desc = $2;
              }
              elsif ($1 eq "GuiType") {
                # $gui_type  = $2;
              }
              elsif ($1 eq "Choices") {
                # $choices  = $2;
              }
              elsif ($1 eq "Default") {
                # $default  = $2;
              }
              else {
                printf("ERROR::illegal keyword within the parameter def in line %d of file %s\n", $.,$phfile);
                $errorflag++;
              }
            }
            elsif ($line =~ /\}/) {
              $param_open_brace = 0;
              $param_def_done = 0;
              #print "Found Param Close Brace\n";

              ###Check if AVATOR_TYPE is a valid type.
              if (($avator_type ne "STRING")&&($avator_type ne "INTEGER")&&($avator_type ne "DOUBLE")&&
                    ($avator_type ne "TIMING_TESTCONDITION")&&($avator_type ne "LEVEL_TESTCONDITION")&&
                      ($avator_type ne "PLIST")&&($avator_type ne "PIN")&&($avator_type ne "FUNCTION")) {
                printf("ERROR::illegal AVATOR_TYPE %s used for parameter %s at line %d of file %s\n", $avator_type,$param_name,$.,$phfile);
                $errorflag++;
              }
              ##check to see if cmtp_type is valid
              if (($cmtp_type ne "STRING")&&($cmtp_type ne "INTEGER")&&($cmtp_type ne "DOUBLE")&&
                    ($cmtp_type ne "TIMING_TESTCONDITION")&&($cmtp_type ne "LEVEL_TESTCONDITION")&&
                      ($cmtp_type ne "PLIST")&&($cmtp_type ne "PIN")&&($cmtp_type ne "FUNCTION")&&
                        ($cmtp_type ne "FILE")&&($cmtp_type ne "PATH")&&($cmtp_type ne "MODE")&&
                          ($cmtp_type ne "GLOBAL")&&($cmtp_type ne "FLOWITEM")&&($cmtp_type ne "PORT")
                            &&($cmtp_type ne "PATTERN")&&($cmtp_type ne "COMMAND")
                              ##For now we have to live with CMTP_TYPE not defined here because some templates may choose not to use CMTP_TYPE
                              &&($cmtp_type ne "")) {
                printf("ERROR::illegal CMTP_TYPE %s used for parameter %s at line %d of file %s\n", $cmtp_type,$param_name,$.,$phfile);
                $errorflag++;
              }

              $PH_TYPE = uc($ph_type);
              if (($PH_TYPE eq "OASIS")&&($TOS_file_type eq "GEN")) {
                ## Based on CorTeX Coding Standards
                ## For OASIS side all parameters are iCGENTpParam
                ## All atributes begin with m_o and end with Param
                $param_attribute =~ s/^m_./m_o/;
                if ($param_attribute !~ /Param$/) {
                  $param_attribute = $param_attribute."Param";
                }
                $param_cortex_type = "iCGENTpParam";
                ($param_function = $param_attribute) =~ s/m_o/m_zSet/;
              }
              elsif (($PH_TYPE ne "OASIS")&&($TOS_file_type ne "OASIS")) {
                if ($avator_type eq "STRING") {
                  if ($param_options) {
                    ### Means it is an ENUM.  Create enum type name from param attribute.
                    if (($param_attribute !~ /^m_t/)&&($param_attribute !~ /^m_b/)) {
                      printf("ERROR::illegal attribute naming convention. Enum Parameter %s attribute must begin with m_t<..> or m_b<..> instead of %s at line %d of file %s\n",
                             $param_name,$param_attribute,$.,$phfile);
                      $errorflag++;
                    }
                    else {
                      if ($param_attribute =~ /^m_t/) {
                        ($param_cortex_type = $param_attribute) =~ s/^m_t/iT/;
                      }
                      elsif ($param_attribute =~ /^m_b/) {
                        if ($#options != 1) {
                          printf("ERROR::illegal attribute naming convention. Boolean Parameter %s attribute %s must have only two options instead %s at line %d of file %s\n",
                                 $param_name,$param_attribute,$param_options,$.,$phfile);
                          $errorflag++;
                        }
                        else {
                          ##ensure that the options are one of the following.
                          foreach $tmp_option(@options) {
                            if ($tmp_option !~ /YES|NO|TRUE|FALSE|ON|OFF|ENABLE|DISABLE/) {
                              printf("ERROR::Boolean parameter %s must be one of YES, NO, TRUE, FALSE, ON, OFF, ENABLE or DISABLE..Not \"%s\" at line %d of file %s\n",
                                     $param_name,$option,$.,$phfile);
                              $errorflag++;
                            }
                          }
                          $param_cortex_type = "bool";
                        }
                      }
                    }
                  }
                  else {
                    if ($param_attribute !~ /^m_s/) {
                      printf("ERROR::illegal attribute naming convention. AVATOR String Parameter %s attribute must begin with m_s<..> instead of %s at line %d of file %s\n",
                             $param_name,$param_attribute,$.,$phfile);
                      $errorflag++;
                    }
                    else {
                      $param_cortex_type = "iCString";
                    }
                  }
                }
                elsif ($avator_type eq "INTEGER") {
                  if ($param_attribute !~ /^m_n/) {
                    printf("ERROR::illegal attribute naming convention. AVATOR Integer Parameter %s attribute must begin with m_n<..> instead of %s at line %d of file %s\n",
                           $param_name,$param_attribute,$.,$phfile);
                    $errorflag++;
                  }
                  else {
                    $param_cortex_type = "int";
                  }
                }
                elsif ($avator_type eq "DOUBLE") {
                  if ($param_attribute !~ /^m_d/) {
                    printf("ERROR::illegal attribute naming convention. AVATOR Double Parameter %s attribute must begin with m_n<..> instead of %s at line %d of file %s\n",
                           $param_name,$param_attribute,$.,$phfile);
                    $errorflag++;
                  }
                  else {
                    $param_cortex_type = "double";
                  }
                }
                elsif ($avator_type =~ /(TESTCONDITION)|(PLIST)|(FUNCTION)/) {
                  if ($param_attribute !~ /^m_o/) {
                    printf("ERROR::illegal attribute naming convention. %s Parameter %s attribute must begin with m_o<..> instead of %s at line %d of file %s\n",
                           $avator_type, $param_name,$param_attribute,$.,$phfile);
                    $errorflag++;
                  }
                  else {
                    $param_cortex_type = "iCGENTpObject";
                  }
                }
                elsif ($avator_type =~ /PIN/) {
                  if ($param_attribute !~ /^m_s/) {
                    printf("ERROR::Avator type of PIN requires use of pointers & iCString on the GEN side.  \"m_s\" is the legal prefix. illegal attribute naming convention.\n%s Parameter %s attribute must begin with m_s<..> instead of %s at line %d of file %s\n",
                           $avator_type, $param_name,$param_attribute,$.,$phfile);
                    $errorflag++;
                  }
                  else {
                    $param_cortex_type = "iCString";
                  }
                }
                else {
                  printf("ERROR::illegal AVATOR_TYPE %s used for parameter %s at line %d of file %s\n", $avator_type,$param_name,$.,$phfile);
                  $errorflag++;
                }
              }

              #push everything into the map
              if($cmtp_type eq "") {
                $$param_details{$param_name} = $param_type."|".$avator_type."|".$param_cardinality;
                $$param_details{$param_name} .= "|".$param_attribute."|".$param_cortex_type."|".$param_function;
                $$param_details{$param_name} .= "|".$param_desc."|".$param_default."|".$param_options;
              }
              else {
                $$param_details{$param_name} = $param_type."|".$avator_type."|".$param_cardinality;
                $$param_details{$param_name} .= "|".$param_attribute."|".$param_cortex_type."|".$param_function;
                $$param_details{$param_name} .= "|".$param_desc."|".$param_default."|".$param_options."|".$cmtp_type;
              }

              if ((($param_cardinality eq "1")||($param_cardinality eq "1-n")) && ($param_default)) {
                if ($default_error_list) {
                  $default_error_list .= "|".$param_name;
                }
                else {
                  $default_error_list = $param_name;
                }
              }

              if ((($param_cardinality eq "0-1")||($param_cardinality eq "0-n")) && ($param_default eq "")) {
                #                                if (($avator_type eq "STRING")||($avator_type eq "INTEGER")||($avator_type eq "DOUBLE"))
                if (($avator_type eq "INTEGER")||($avator_type eq "DOUBLE")) {
                  if ($no_default_error_list) {
                    $no_default_error_list .= "|".$param_name;
                  }
                  else {
                    $no_default_error_list = $param_name;
                  }
                }
              }

              #printf("Param \"%s\"\n",$param_name);
              push(@$ordered_param_list,$param_name);
              #Clear all the variables for the next parameter
              undef $param_options;
              undef $option;
              undef $param_default;
              #$param_default = "PARAM_DEFAULT_NOT_DEFINED";
              undef $param_type;
              undef $param_cardinality;
              undef $avator_type;
              undef $param_attribute;
              undef $param_cortex_type;
              undef $param_function;
              undef $param_desc;
              undef $param_name;
            }
            else {
              printf("ERROR::Unknown syntax on line %d of file %s\n", $.,$phfile);
              $errorflag++;
            }
            next;
          }
        }
        elsif ($line =~ /\}/) {
          $param_section_open_brace = 0;
          $param_flag = 0;
          #print "Found Param Section Close Brace\n";
          next;
        }
        else {
          printf("ERROR::Unknown syntax on line %d of file %s\n", $.,$phfile);
          printf("Check if AVATOR keyword definition is on the Param Definition Line\n");
          $errorflag++;
          next;
        }
      }
    }
    else {
      next;
    }
    undef $line;
  }
  if ($default_error_list) {
    $default_error_list =~ s/\|/, /g;
    print "\nSTANDARDS ERROR!  STANDARDS ERROR! STANDARDS ERROR!\n";
    print "The following list of parameters have a CARDINALITY OF 1 or 1-n, but are specifying AVATOR_DEFAULT\n";
    print "$default_error_list\n\n";
    print "Defaults are NOT allowed only for cardinality of 1 or 1-n\n\n";
    $errorflag++;
  }
  if ($no_default_error_list) {
    $no_default_error_list =~ s/\|/, /g;
    print "\nSTANDARDS ERROR!  STANDARDS ERROR! STANDARDS ERROR!\n";
    print "The following list of parameters have a CARDINALITY OF 0-1, but are NOT specifying AVATOR_DEFAULT\n";
    print "$no_default_error_list\n\n";
    print "Defaults are REQUIRED  cardinality of 0-1 or 0-n\n\n";
    $errorflag++;
  }

  if (!($port_info_check)) {
    print "\nSTANDARDS ERROR!  STANDARDS ERROR! STANDARDS ERROR!\n";
    print "AVATOR Port Information NOT defined for the ph file \"$phfile\"\n\n";
    $errorflag++;
  }
  close PHFILE;

  $$error_count = $errorflag;

  if ($debug_print eq "1") {
    printf("Dumping all parsed information...\n\n\n");

    printf("PHfile <<%s>> PHTestclass <<%s>> PublicBases <<%s>>\n",$phfile,$$phtestclass,$$public_bases);
    $, = ",";
    print "TestCondition Parameters:- @$tc_vector\n";
    print "PList Parameters:- @$plist_vector\n\n";
    $, = "\n";
    print "Ordered List of Params\n";
    print @$ordered_param_list,"\n\n";
    print "Port Details\n";
    print @$port_details,"\n\n";

    foreach $param(@$ordered_param_list) {
      ($param_type,$avator_type,$param_cardinality,$param_attribute,$param_cortex_type,$param_function,$param_desc,$param_default,$param_options) = split(/\|/,$$param_details{$param});
      printf("Param:- %-15s Type:- %-10s AvatorType:- %-20s Desc:- %-s\n",$param,$param_type,$avator_type,$param_desc,);
      printf("      - Cardinality:- %-5s Attribute:- %-20s CorTeXType:- %-20s ParamFunction %-20s\n",$param_cardinality,$param_attribute, $param_cortex_type,$param_function);
      if ($param_default ne "") {
        printf("      - Default:- %-15s",$param_default);
      }
      if ($param_options) {
        $param_options =~ s/\&/  /g;
        printf("        Options:- %-s",$param_options);
      }
      print "\n";
    }
  }
}

1;  # don't forget to return a true value at the end of the file

#***********************************************************
 # NOTE: Please do not modify Revision History Directly via your editor.
 # Please only modify via CVS tools.

 # Revision History
 # $Log: CorTeXPerlModule.pm,v $
 # Revision 1.3.54.1.4.5  2007/09/19 20:57:23  svaidya
 # HSD_ID:3689
 #
 # CHANGE_DESCRIPTION: implementing the perl script change by Silvio.
 #
 # REG_TEST:
 #
 # Revision 1.3.54.1.4.2  2007/08/26 00:15:59  spicano
 # HSD_ID:3689
 #
 # CHANGE_DESCRIPTION:CorTeXPerlModule.pm / build_GEN_cpp_and_h.pl .ph error checks #AVATOR_OPTIONS & #AVATOR_DEFAULT
 #
 # REG_TEST:none
 #
 # Revision 1.3.54.1.4.1  2007/08/25 22:52:15  spicano
 # HSD_ID:3700
 #
 # CHANGE_DESCRIPTION:error check unique parameter names in .ph file
 #
 # REG_TEST:none
 #
 # Revision 1.3.54.1  2007/04/12 23:08:10  asharm7
 # HSD_ID:4004
 #
 # CHANGE_DESCRIPTION:Checkin of CortexPerlModule.pm in GEN\GEN_bin
 #
 # REG_TEST:
 #
 # Revision 1.3  2004/11/08 19:43:20  rflore2
 # CHANGE_ID: OVERRIDED by rflore2 - NO BUGID
 #  CHANGE_DESCRIPTION:(Type the desc on the next line)
 #  Fixed syntax error
 #  REG_TEST:(Type on the next line)
 #
 # Revision 1.2  2004/11/08 17:35:16  svpathy
 # CHANGE_ID: OVERRIDED by svpathy - NO BUGID
 #  CHANGE_DESCRIPTION:(Type the desc on the next line)
 #  Updated parsePH subroutine to support all AVATOR compatible port configuration information.
 #  Also updated the cortex types for the AVATOR TYPE PIN, which is supported
 #  by iCGENPinInfo* and strings  rather than iCGENTpObject
 #  REG_TEST:(Type on the next line)
 #
 # Revision 1.1  2004/09/25 00:23:35  dhchen
 # CHANGE_ID: OVERRIDED by dhchen - NO BUGID
 #  CHANGE_DESCRIPTION:(Type the desc on the next line)
 #
 #  Initial check in
 #  REG_TEST:(Type on the next line)
 #
 #***********************************************************
