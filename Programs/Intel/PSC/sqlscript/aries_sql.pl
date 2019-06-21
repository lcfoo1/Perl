#!/usr/intel/bin/perl5.00404 -w
###########################################################################
# Name:         $RCSfile: aries_sql.pl,v $
#
# Date:         $Date: 2002/07/24 22:53:11 $
#
# Author:       Sean P. Collins, spcollin@eng.fm.intel.com
#
# License:      Copyright (c) 2002, Intel Corporation, INTEL CONFIDENTIAL
#
# Description:  
#
# Options:      
#
# $Id: aries_sql.pl,v 1.3 2002/07/24 22:53:11 spcollin Exp spcollin $
#
# Changelog:    
#		$Log: aries_sql.pl,v $
#		Revision 1.3  2002/07/24 22:53:11  spcollin
#		Output is now formated based on max column size; improved env. check; minor tweaks.
#
#		Revision 1.2  2002/07/23 00:21:34  spcollin
#		Added printing of column headers, minor output formatting.
#
#		Revision 1.1  2002/07/22 23:39:24  spcollin
#		Initial revision
#
#
###########################################################################

package main;

####### Libraries & Modules ########

require 5.004;    # demand current version of perl
use Getopt::Long; # POSIX compatible options parsing
$| = 1; # do not buffer output

# database libraries, module
require "site_config_aries.pl";
use lib "/usr/intel/pkgs/perl-modules/5.004/DBD/Oracle/1.03";
use lib "/usr/intel/pkgs/perl-modules/5.004/DBI/1.13";
use DBI;

#use strict var;   # enforce variable declaration

####### Begin main execution #######

&::Parse_command_line();
&::Check_database_env();
&::Initialize_variables();

&::Setup_query();
&::Execute_query();

####### End main execution #######


###########################################################################
# Name:         Check_environment()
#
# Date:         
#
# Author:       spcollin
#
# Description:  
#
# Options:      none
###########################################################################
sub Check_database_env {

   # set up ORACLE_HOME environment variable
   print "Setting Oracle Home to $Aries::Home{oracle}\n\n" if ( $::Opt{'verbose'} );
   if ( -e $Aries::Home{oracle} ) {
      $ENV{ORACLE_HOME} = $Aries::Home{oracle};
   }
   else {
      die "ERROR: Oracle Home directory does not exist [$Aries::Home{oracle}]";
   }
 
   print "Checking for available databases...\n" if ( $::Opt{'verbose'} );

   @drivers = DBI->available_drivers();
   foreach $driver ( @drivers ) {
      print "Driver: $driver\n" if ( $::Opt{'verbose'} );
      unless ( $driver eq "Proxy" ) { # current Proxy install is broken
         @dataSources = DBI->data_sources( $driver );
         foreach $dataSource ( @dataSources ) {
            print "\tData Source: $dataSource\n" if ( $::Opt{'verbose'} );
         }
      }
   }
   print "\n" if ( $::Opt{'verbose'} );

} # end of sub Check_environment
 
 
###########################################################################
# Name:         Parse_command_line()
#
# Date:         09/15/00
#
# Author:       spcollin
#
# Description:  Parse the command line options using the GetOptions::Long module.
#               Only slight nuisance is that the " characters for the reason flag 
#               won't be diplayed during the "Command line:" printout, so you can't
#               cut and paste it verbatim. 
#
# Options:      none
###########################################################################
sub Parse_command_line {
 
   # if no cmd line args given, print short usage msg and exit
   if ($#ARGV < 0) {
      &::Usage_short();
      exit(1);
   }
 
   $0 =~ s!.*/!!; # strip any path off of the name of this tool
   print "\nCommand line: $0 @ARGV\n\n" if ( $::Opt{'verbose'} );
 
   %::Opt = (); # linkage for all the options.
   &::GetOptions( \%::Opt,
			  "sql=s",
			  "site=s",
			  "output=s",
			  "var=s",
			  "html",
			  "comma",
			  "help",
                          "verbose",  
            	) or die "ERROR: GetOptions() failed\n\n";

   foreach $key ( sort keys(%Opt) ) {
      if ( $::Opt{ $key } ) {
         print "  $0: found option: -$key \t <$::Opt{ $key }>\n" if ( $::Opt{'verbose'} );
      }
   }
   print "\n";

   # -help option?
   if ( $::Opt{"help"} ) {
      &::Usage_long(); 
      exit (1);
   }
 
   # -verbose option?
   if ( $::Opt{'verbose'} ) {
      if ( -e 'dbitrace.log') { unlink 'dbitrace.log' }
      DBI->trace( 3, 'dbitrace.log' ); # trace DBI execution
   }

   # -site option?
   if ( $::Opt{'site'} ) {
      if ( ! defined $Aries::Site{ $::Opt{'site'} } ) {
         die "ERROR: Unsupported site given [$::Opt{'site'}]\n";
      }
   }
   else {
      print "ERROR: No -site option given\n";
      exit (1);
   }

   # -sql option?
   if ( $::Opt{'sql'} ) {
      if ( ! -e $::Opt{'sql'} ) {
         die "ERROR: File does not exist [$::Opt{'sql'}]\n";
      }
   }
   else {
      print "ERROR: No -sql option given\n";
      exit (1);
   }

} # end of sub Parse_command_line


#############################################################################################
# Name:         Initialize_variables()
#
# Author:       spcollin
#
# Description:  Initialize all of the global variables. 
#
# Options:      none
#############################################################################################
sub Initialize_variables {

   $main::site = $::Opt{'site'};
   $main::tnsname = $Aries::Site{ $main::site };
   $main::sql = $::Opt{'sql'};
   $main::var = $::Opt{'var'};
   $main::output = $::Opt{'output'};

   $main::db_name = 'dbi:Oracle:' . $main::tnsname; 
   $main::db_username = '';
   $main::db_userpassword = '';

   # attributes to pass to DBI->connect(...)
   %main::attr = (
      PrintError => 0, # don't warn() upon errors
      RaiseError => 0, # don't die() upon errors
      AutoCommit => 0, # don't save changes ('commit') upon exit
   );

} # end of sub Initialize_variables
 

#############################################################################################
# Name:         
#
# Author:     
#
# Description:  
#
# Options:     
#############################################################################################
sub Setup_query() {
    open ( SQL, "$main::sql" ) or die "ERROR: Unable to open SQL file [$main::sql]";
    @query_line = <SQL>;

    if ( $main::output ) {
       open ( OUTPUT, ">$main::output" ) or die "ERROR: Unable to open output file [$main::output]";
       $main::OUTPUT = $main::OUTPUT; # make perl -w happy
       $main::output = OUTPUT;
    }
    else {
       $main::output = STDOUT;
    }
}


#############################################################################################
# Name:         
#
# Author:     
#
# Description:  
#
# Options:     
#############################################################################################
sub Execute_query() {

   $rcfile = "$ENV{HOME}/.ariessqlrc";

   if ( -e $rcfile ) {
      print "Reading username and password from: $rcfile\n" if ( $::Opt{'verbose'} );
      open ( RCFILE, "$rcfile" ) or die "unable to open $rcfile";
      chomp( $main::db_username = <RCFILE> );
      chomp( $main::db_userpassword = <RCFILE> );
   }
   else {  
      print "Reading username and password from STDIN: $rcfile not found\n\n";
      print "Enter username: ";
      chomp( $main::db_username = <STDIN> );

      system "stty -echo"; # turn echo off
      print "Enter password: ";
      chomp( $main::db_userpassword = <STDIN> );
      print "\n\n";
      system "stty echo";
   }

   # connect to the database
   print "Connecting to database...\n" if ( $::Opt{'verbose'} );
   my $dbh = DBI->connect( $main::db_name, $main::db_username, $main::db_userpassword, \%main::attr ) 
                  or die "ERROR: Couldn't connect to database: " . DBI->errstr;

   # prepare query
   my $sth = $dbh->prepare( "@query_line" ) or die "ERROR: Couldn't prepare query: " . $dbh->errstr;
   
   # execute query
   if ( defined $var ) {
      @vars = split ( /,/, $var );
      #@clean_vars = $dbh->quote( @vars );
      print "Executing Query...\n" if ( $::Opt{'verbose'} );
      $sth->execute( @vars ) or die "ERROR: Couldn't execute query: " . $sth->errstr;
   }
   else {
      print "Executing Query...\n" if ( $::Opt{'verbose'} );
      $sth->execute() or die "ERROR: Couldn't execute query: " . $sth->errstr;
   }

   # print out the data
   if ( $::Opt{'html'} ) {  
      &::Print_data_html( $sth, $main::output );
   }
   elsif ( $::Opt{'comma'} ) {  
      &::Print_data_comma( $sth, $main::output );
   }
   else {  
      &::Print_data_text( $sth, $main::output );
   }
   
   # disconnect from the database
   $sth->finish();
   $dbh->disconnect();
 
   close ( SQL);
   close ( $main::output );
}


#############################################################################################
# Name: 
#
# Author: 
#
# Description:
#
# Options:
#############################################################################################
sub Print_data_text() {
   my( $sth, $output ) = @_; 

   print "Printing data...\n\n" if ( $::Opt{'verbose'} );

   for ( $i = 0; $i < $sth->{NUM_OF_FIELDS}; $i++ ) {
      # set up data size for columns (number of chars etc)
      my $col_name = $sth->{NAME_uc}->[$i];
      my $col_width = $sth->{PRECISION}->[$i];
      if ( $col_width < length( $col_name ) ) { $col_width = length( $col_name ) };

      printf ( $main::output "%-${col_width}s  ", $sth->{NAME_uc}->[$i] );
   }
   print $main::output "\n";
   
   while ( @data = $sth->fetchrow_array() ) {
      for ( $i = 0; $i < $sth->{NUM_OF_FIELDS}; $i++ ) {
         # set up data size for columns (number of chars etc)
         my $col_name = $sth->{NAME_uc}->[$i];
         my $col_width = $sth->{PRECISION}->[$i];
         if ( $col_width < length( $col_name ) ) { $col_width = length( $col_name ) };

	 if ( defined $data[$i] ) {
            printf ( $main::output "%-${col_width}s  ", $data[$i] );
	 }
	 else {
	    printf ( $main::output "%-${col_width}s  ", " " );
	 }
      }
      print $main::output "\n";
   }

   print $main::output "Fetched " . $sth->{NUM_OF_FIELDS} . " columns, " . $sth->rows . " rows of data\n\n";
}


#############################################################################################
# Name: 
# 
# Author:
# 
# Description:
# 
# Options:
#############################################################################################
sub Print_data_comma() {
   my( $sth, $output ) = @_;                 
 
   print "Printing data...\n\n" if ( $::Opt{'verbose'} );
   
   for ( $i = 0; $i < $sth->{NUM_OF_FIELDS}; $i++ ) {
      # set up data size for columns (number of chars etc)
      my $col_name = $sth->{NAME_uc}->[$i];
      my $col_width = $sth->{PRECISION}->[$i];
      if ( $col_width < length( $col_name ) ) { $col_width = length( $col_name ) };
      
      print $main::output "$sth->{NAME_uc}->[$i],";
   }
   print $main::output "\n";
 
   while ( @data = $sth->fetchrow_array() ) {
      for ( $i = 0; $i < $sth->{NUM_OF_FIELDS}; $i++ ) { 
         # set up data size for columns (number of chars etc)
         my $col_name = $sth->{NAME_uc}->[$i];
         my $col_width = $sth->{PRECISION}->[$i];
         if ( $col_width < length( $col_name ) ) { $col_width = length( $col_name ) };
         
         if ( defined $data[$i] ) {
            print $main::output "$data[$i],";
         }
         else {
            print $main::output " ,";
         }
      }
      print $main::output "\n";
   }
   
   print $main::output "Fetched " . $sth->{NUM_OF_FIELDS} . " columns, " . $sth->rows . " rows of data\n\n";
}


#############################################################################################
# Name: 
#
# Author: 
#
# Description:
#
# Options:
#############################################################################################
sub Print_data_html() {
   my( $sth, $output, $title, $header ) = @_; 
 
   if ( !defined $sth ) {
      print "ERROR: Missing required parameter [\$sth] in call to Print_results() subroutine\n";
      return( 1 );
   }
   if ( !defined $output ) {
      $output = \*STDOUT;
   }
 
print $output <<END;
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN">
 
<HTML>
<HEAD><TITLE> $title </TITLE></HEAD>
 
<BODY>
<TABLE BORDER="3" CELLPADDING=5>
<CAPTION> $header </CAPTION>
END
 
   ### print out the columns ###
   print $output "<TR> ";
   for ( my $i = 0; $i < $sth->{NUM_OF_FIELDS}; $i++ ) {
      print $output "<TH> $sth->{NAME_uc}->[$i] </TH>"; 
   }
   print $output "</TR>\n";
 
   ### print out the rows ###
   my $prev_bom = " ";
   my $bgcolor = "#00ff99";
   while ( my @data = $sth->fetchrow_array() ) {
      print $output "<TR> ";
      for ( my $i = 0; $i < $sth->{NUM_OF_FIELDS}; $i++ ) {
         if ( defined $data[$i] ) {
            unless ( $prev_bom eq $data[0] ) {
               $prev_bom = $data[0];
               $bgcolor = $bgcolor eq "white" ? "#00ff99" : "white"; 
            }
            print $output "<TD BGCOLOR=\"$bgcolor\"> $data[$i] </TD>"; 
         }
         else {
            print $output "<TD BGCOLOR=\"$bgcolor\"> &nbsp </TD>"; 
         }
      }
      print $output " </TR>\n";
   }
   print $output "</TABLE>\n";
 
   print $output "<P> " . $sth->{NUM_OF_FIELDS} . " columns, " . $sth->rows . " rows of data </P>\n\n";
 
print $output <<END;
</BODY> 
</HTML> 
END
 
   $sth->finish();
}


#############################################################################################
# Name:         
#
# Author:     
#
# Description:  
#
# Options:     
#############################################################################################
sub Usage_short() {
   print "Usage: $0 -site <sitename> -sql <file.sql>\n";
}


#############################################################################################
# Name:         
#
# Author:     
#
# Description:  
#
# Options:     
#############################################################################################
sub Usage_long() {
   print "Usage: $0 -site <sitename> -sql <file.sql>\n";
}
