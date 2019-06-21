#!/usr/local/apps/perl/bin/perl
#######################################################################
#                                                                     #
#  WHO:    John L. Moreland                                           #
#                                                                     #
#  WHAT:   mktalk                                                     #
#                                                                     #
#  WHY:    Make Talk                                                  #
#                                                                     #
#          Looks for special HTML tags in a template file,            #
#          copies the segments between comments, and                  #
#          generates new files linked together with                   #
#          navigation controls.                                       #
#                                                                     #
#  WHERE:  Opus Software                                              #
#                                                                     #
#          Copyright (c) 1996, 1997, 1998 by Opus Software.           #
#          Users and possessors of this source code are hereby        #
#          granted a nonexclusive, royalty-free copyright and         #
#          design patent license to use this code in individual       #
#          software.  License is not granted for commercial use,      #
#          in whole or in part, without prior written permission      #
#          from Opus Software.  This source is provided "AS IS"       #
#          without express or implied warranty of any kind.           #
#                                                                     #
#          For more information, contact:                             #
#             E-Mail:  info@opus-software.com                         #
#             Web:     http://www.opus-software.com                   #
#                                                                     #
#  WHEN:   Sat Feb  3 17:41:08 PST 1996  (v1.0 JLM)                   #
#             Wrote first version to split html files into            #
#             slides with forward and backward html links.            #
#                                                                     #
#          Wed May  1 17:33:14 PDT 1996  (v2.0 JLM)                   #
#             Added multi-level table of contents generation.         #
#                                                                     #
#          Fri Apr 25 19:02:28 PDT 1997  (v3.0 JLM)                   #
#             Hacked in some simple format replacement filters        #
#             to enable color and font pattern munging.               #
#                                                                     #
#          Fri Mar  6 18:47:11 PST 1998  (v4.0 JLM)                   #
#             Rewrote to clean up and enable support for:             #
#             * Automatic slide file naming and numbering             #
#             * Better menu bar (buttons can be text or images)       #
#             * Multi-column chapter indexes                          #
#             * Optional slide background image (or color)            #
#             * GoTo links (ref. by slide name, optional TARGET)      #
#             * Section/chapter/slide timing report                   #
#             * External file links for long code examples            #
#             * Macro definitions file (Holds key/value pairs)        #
#             * Macro dump/report                                     #
#             * Tag dump/report                                       #
#             * Include files                                         #
#             Extensible parser (tag handler callback functions)      #
#                                                                     #
#  HOW:    Perl 5                                                     #
#                                                                     #
#######################################################################


#######################################################################
############################  SUBROUTINES  ############################
#######################################################################


#######################################################################
#                                                                     #
#  Intialize internal state variables                                 #
#                                                                     #
#######################################################################
sub init_state
{
	# THE NAME OF THIS SCRIPT FILE
	$cmd = $0;
	$cmd =~ s%.*/%%;  # Strip the path off the name

	# THE DATE AND TIME THIS SCRIPT WAS RUN
	@lt = localtime( time );
	$date = sprintf( "%s/%s/%s", $lt[4]+1, $lt[3], $lt[5] );
	$ampm = "AM";  if ( $lt[2] > 12 ) { $lt[2]-=12; $ampm = "PM"; }
	$time = sprintf( "%s:%s:%s $ampm", $lt[2], $lt[1], $lt[0] );


	#######################################################################

	#
	# CONTROL TAGS
	#

	%tags = ();

	$tags{"MT_TALK"}    = { LEVEL => 1, TITLE => "My Talk", NAME  => "" };
	$tags{"MT_PART"}    = { LEVEL => 2, TITLE => "My Part" };
	$tags{"MT_SECTION"} = { LEVEL => 3, TITLE => "My Section",
							START => "10:15pm", STOP => "23:05" };
	$tags{"MT_CHAPTER"} = { LEVEL => 4, TITLE => "My Chapter", NAME => "",
							INDLIMIT => 8 };
	$tags{"MT_SLIDE"}   = { LEVEL => 5, TITLE => "My Slide", NAME => "",
							INDLEVEL => 0 };
	$tags{"MT_GOTO"}    = { NAME => "", TARGET => "" };
	$tags{'/MT_GOTO'}   = { };
	$tags{"MT_REFCODE"} = { INFILE => "", OUTFILE => "", COLOR => "",
							SIZE => "", NAME => "" };
	$tags{"MT_INCLUDE"} = { FILE => "" };

	#######################################################################

	#
	# DEFAULTS (USED ONCE INTERNALLY TO INITIALIZE DEFAULT MACRO VALUES)
	#

	%def = ();

	$def{"bg"}    = "#000000";  # Background Color
	$def{"title"} = "#FFFF00";  # Title Color
	$def{"link"}  = "#FFFFFF";  # Unvisited (unused) Link Color
	$def{"alink"} = "#00FF00";  # Active (mouse down)Link Color
	$def{"vlink"} = "#888888";  # Visited (used) Link Color
	$def{"text"}  = "#FFFFFF";  # Text Color
	$def{"menu"}  = "#400000";  # Menu Color
	$def{"rule"}  = "<CENTER><HR WIDTH=50%></CENTER>";  # Title/Page separator

	#######################################################################

	#
	# MACRO TAGS
	#

	%macros = ();

	# TOC MACROS
		# TOC BODY
		$macros{"MT_TOC_BGIMAGE_FIELD"}  = "";
		$macros{"MT_TOC_BG_COLOR"}       = $def{"bg"};
		# TOC LINKS
		$macros{"MT_TOC_LINK_COLOR"}     = $def{"link"};
		$macros{"MT_TOC_ALINK_COLOR"}    = $def{"alink"};
		$macros{"MT_TOC_VLINK_COLOR"}    = $def{"vlink"};
		# TOC ELEMENTS
		$macros{"MT_TOC_HEADER_HTML"}    = "";
		$macros{"MT_TOC_TITLE1_COLOR"}   = $def{"title"};
		$macros{"MT_TOC_TITLE1_SIZE"}    = "+0";
		$macros{"MT_TOC_TITLE2_COLOR"}   = $def{"title"};
		$macros{"MT_TOC_TITLE2_SIZE"}    = "+3";
		$macros{"MT_TOC_RULE_HTML"}      = $def{"rule"};
		$macros{"MT_TOC_PART_COLOR"}     = $def{"title"};
		$macros{"MT_TOC_PART_SIZE"}      = "+1";
		$macros{"MT_TOC_SECTION_COLOR"}  = $def{"title"};
		$macros{"MT_TOC_SECTION_SIZE"}   = "+0";
		$macros{"MT_TOC_CHAPTER_COLOR"}  = $def{"title"};
		$macros{"MT_TOC_CHAPTER_SIZE"}   = "+0";

	# MENU BAR MACROS
		# MENU BAR BODY
			# defined by page body menu appears on
		# MENU BAR LINKS
			# defined by page body menu appears on
		# MENU BAR TABLE
		$macros{"MT_MENU_SPC_SIZE"}      = 0;
		$macros{"MT_MENU_BDR_SIZE"}      = 0;
		$macros{"MT_MENU_PAD_SIZE"}      = 0;
		$macros{"MT_MENU_BGCOLOR_FIELD"} = "bgcolor=" . $def{"menu"};
		$macros{"MT_MENU_TXT_COLOR"}     = $def{"link"};
		# MENU BAR ELEMENTS
		$macros{"MT_MENU_TOCBTN_HTML"}   = "Table Of Contents";
		$macros{"MT_MENU_TOCCEL_SIZE"}   = "24%";
		$macros{"MT_MENU_TOCTXT_SIZE"}   = "-1";
		$macros{"MT_MENU_INDBTN_HTML"}   = "Chapter Index";
		$macros{"MT_MENU_INDCEL_SIZE"}   = "24%";
		$macros{"MT_MENU_INDTXT_SIZE"}   = "-1";
		$macros{"MT_MENU_PREBTN_HTML"}   = "Previous Slide";
		$macros{"MT_MENU_PRECEL_SIZE"}   = "24%";
		$macros{"MT_MENU_PRETXT_SIZE"}   = "-1";
		$macros{"MT_MENU_NXTBTN_HTML"}   = "Next Slide";
		$macros{"MT_MENU_NXTCEL_SIZE"}   = "24%";
		$macros{"MT_MENU_NXTTXT_SIZE"}   = "-1";
		$macros{"MT_MENU_PAGCEL_SIZE"}   = "4%";
		$macros{"MT_MENU_PAGTXT_SIZE"}   = "-1";

	# CHAPTER INDEX MACROS
		# CHAPTER INDEX BODY
		$macros{"MT_IND_BGIMAGE_FIELD"}  = "";
		$macros{"MT_IND_BG_COLOR"}       = $def{"bg"};
		# CHAPTER INDEX LINKS
		$macros{"MT_IND_LINK_COLOR"}     = $def{"link"};
		$macros{"MT_IND_ALINK_COLOR"}    = $def{"alink"};
		$macros{"MT_IND_VLINK_COLOR"}    = $def{"vlink"};
		# CHAPTER INDEX ELEMENTS
		$macros{"MT_IND_TITLE1_COLOR"}   = $def{"title"};
		$macros{"MT_IND_TITLE1_SIZE"}    = "+2";
		$macros{"MT_IND_RULE_HTML"}      = $def{"rule"};
		$macros{"MT_IND_ITEM_COLOR"}     = $def{"text"};
		$macros{"MT_IND_ITEM_SIZE"}      = "+0";

	# SLIDE MACROS
		# SLIDE BODY
		$macros{"MT_SLIDE_BGIMAGE_FIELD"}  = "";
		$macros{"MT_SLIDE_BG_COLOR"}       = $def{"bg"};
		# SLIDE LINKS
		$macros{"MT_SLIDE_LINK_COLOR"}     = $def{"link"};
		$macros{"MT_SLIDE_ALINK_COLOR"}    = $def{"alink"};
		$macros{"MT_SLIDE_VLINK_COLOR"}    = $def{"vlink"};
		# SLIDE ELEMENTS
		$macros{"MT_SLIDE_TITLE1_COLOR"}   = $def{"title"};
		$macros{"MT_SLIDE_TITLE1_SIZE"}    = "+0";
		$macros{"MT_SLIDE_TITLE2_COLOR"}   = $def{"title"};
		$macros{"MT_SLIDE_TITLE2_SIZE"}    = "+3";
		$macros{"MT_SLIDE_RULE_HTML"}      = $def{"rule"};
		$macros{"MT_SLIDE_TXT_COLOR"}      = $def{"text"};
		$macros{"MT_SLIDE_TXT_SIZE"}       = "+2";

	# REFCODE MACROS
		# REFCODE BODY
		$macros{"MT_REF_BGIMAGE_FIELD"}  = "";
		$macros{"MT_REF_BG_COLOR"}       = $def{"bg"};
		# REFCODE LINKS
		$macros{"MT_REF_LINK_COLOR"}     = $def{"link"};
		$macros{"MT_REF_ALINK_COLOR"}    = $def{"alink"};
		$macros{"MT_REF_VLINK_COLOR"}    = $def{"vlink"};
		# REFCODE ELEMENTS
		$macros{"MT_REF_TITLE1_COLOR"}   = $def{"title"};
		$macros{"MT_REF_TITLE1_SIZE"}    = "+0";
		$macros{"MT_REF_TITLE2_COLOR"}   = $def{"title"};
		$macros{"MT_REF_TITLE2_SIZE"}    = "+3";
		$macros{"MT_REF_RULE_HTML"}      = $def{"rule"};
		$macros{"MT_REF_TXT_COLOR"}      = $def{"text"};
		$macros{"MT_REF_TXT_SIZE"}       = "-1";


	#######################################################################

	#
	# HTML FORMAT TEMPLATES
	#

	%formats = ();

	# EDIT TAG FORMATS

		$formats{"GOTO"} = "
			<A HREF=\"%s\" TARGET=%s>
			";

		$formats{'/GOTO'} = "
			</A>
			";

		$formats{"REFCODE_BODY"} = "
			<BODY
				<MT_REF_BGIMAGE_FIELD>
				BGCOLOR=<MT_REF_BG_COLOR>
				TEXT=<MT_REF_TXT_COLOR>
				LINK=<MT_REF_LINK_COLOR>
				ALINK=<MT_REF_ALINK_COLOR>
				VLINK=<MT_REF_VLINK_COLOR>
			>";

		$formats{"REFCODE_PRE"} = "
			<FONT COLOR=<MT_REF_TITLE1_COLOR> SIZE=<MT_REF_TITLE1_SIZE>>
			<CENTER>%s</CENTER></FONT>
			<FONT COLOR=<MT_REF_TITLE2_COLOR> SIZE=<MT_REF_TITLE2_SIZE>>
			<CENTER><B><I>%s</I></B></CENTER></FONT>
			<MT_REF_RULE_HTML>
			<P>
			<PRE>";

		$formats{"REFCODE_FONT"} = "	
			<FONT COLOR=%s SIZE=%s>
			";

		$formats{"REFCODE_POST"} = "</FONT></PRE>\n";

	# GENERAL FORMATS

		# FILE HEADER
		$formats{"HEADER"} = "
			<HTML>
			<HEAD>
			<!-- Created by $cmd on $date at $time -->
			<TITLE>%s</TITLE>
			</HEAD>
			";

		# FILE TRAILER
		$formats{"TRAILER"} = "
			</BODY>
			</HTML>
			";

	# TOC ELEMENT FORMATS

		# TOC TITLE
		$formats{"TOC_MT_TALK"} = "
			<BODY
				<MT_TOC_BGIMAGE_FIELD>
				BGCOLOR=<MT_TOC_BG_COLOR>
				TEXT=<MT_TOC_TITLE1_COLOR>
				LINK=<MT_TOC_LINK_COLOR>
				ALINK=<MT_TOC_ALINK_COLOR>
				VLINK=<MT_TOC_VLINK_COLOR>
			>
			<MT_TOC_HEADER_HTML>
			<FONT COLOR=<MT_TOC_TITLE1_COLOR> SIZE=<MT_TOC_TITLE1_SIZE>>
			<CENTER>%s</CENTER>
			<FONT COLOR=<MT_TOC_TITLE2_COLOR> SIZE=<MT_TOC_TITLE2_SIZE>>
			<CENTER><B><I>Table of contents</I></B></CENTER>
			<MT_TOC_RULE_HTML>
			<P>
			";

		# TOC PART
		$formats{"TOC_MT_PART"} = "
			<FONT COLOR=<MT_TOC_PART_COLOR> SIZE=<MT_TOC_PART_SIZE>><B>%s</B>
			";

		# TOC SECTION
		$formats{"TOC_MT_SECTION"} = "
			<UL>
				<FONT COLOR=<MT_TOC_SECTION_COLOR>
					SIZE=<MT_TOC_SECTION_SIZE>><B>%s</B>
			</UL>
			";

		# TOC CHAPTER START
		$formats{"TOC_MT_CHAPTER_START"} = "
			<UL>
				<UL>
			";

		# TOC CHAPTER
		$formats{"TOC_MT_CHAPTER"} = "
					<TABLE WIDTH=85%% CELLPADDING=0 CELLSPACING=0>
						<TR>
						<TD NOWRAP>
							<FONT COLOR=<MT_TOC_LINK_COLOR>
								SIZE=<MT_TOC_CHAPTER_SIZE>>
							<A HREF=%s><B>%s</B></A>&nbsp;
						</TD>
						<TD WIDTH=100%%>
							<FONT COLOR=<MT_TOC_LINK_COLOR>
								SIZE=<MT_TOC_CHAPTER_SIZE>>
							<HR SIZE=1>
						</TD>
						<TD NOWRAP ALIGN=right>
							<FONT COLOR=<MT_TOC_LINK_COLOR>
								SIZE=<MT_TOC_CHAPTER_SIZE>>
							&nbsp;<B>%s</B>
						</TD>
						</TR>
					</TABLE>
			";

		# TOC CHAPTER END
		$formats{"TOC_MT_CHAPTER_END"} = "
				</UL>
			</UL>
			";

	# CHAPTER INDEX ELEMENT FORMATS

		$formats{"IND_BODY"} = "
			<BODY
				<MT_IND_BGIMAGE_FIELD>
				BGCOLOR=<MT_IND_BG_COLOR>
				TEXT=<MT_IND_ITEM_COLOR>
				LINK=<MT_IND_LINK_COLOR>
				ALINK=<MT_IND_ALINK_COLOR>
				VLINK=<MT_IND_VLINK_COLOR>
			>";

		# CHAPTER INDEX TITLE
		$formats{"CHAPTER_IND_TITLE"} = "
			<FONT COLOR=<MT_IND_TITLE1_COLOR> SIZE=<MT_IND_TITLE1_SIZE>>
			<CENTER>%s</CENTER>
			<MT_IND_RULE_HTML>
			<P>
			";

		# CHAPTER INDEX LIST HEADER
		$formats{"CHAPTER_IND_LIST_HEAD"} = "
			<CENTER>
			<TABLE WIDTH=100% CELLSPACING=8 CELLPADDING=8>
			";

		# CHAPTER INDEX LIST COLUMNS
		$formats{"CHAPTER_IND_LIST_START"} = "<TD VALIGN=TOP WIDTH=%s>\n";
		$formats{"CHAPTER_IND_LIST_END"} = "</TD>\n";

		# CHAPTER INDEX LIST TAIL
		$formats{"CHAPTER_IND_LIST_TAIL"} = "
			</TD>
			</TABLE>
			</CENTER>
			";

		# CHAPTER INDEX ENTRY
		$formats{"CHAPTER_IND_ITEM"} = "
			<TABLE WIDTH=100%% CELLSPACING=0 CELLPADDING=0>
			<TR>
			<TD WIDTH=%s%%>&nbsp;</TD>
			<TD NOWRAP>
				<FONT COLOR=<MT_IND_ITEM_COLOR> SIZE=<MT_IND_ITEM_SIZE>>
				<A HREF=%s>%s</A>&nbsp;
			</TD>
			<TD VALIGN=top WIDTH=%s%%>
				<HR SIZE=1>
			</TD>
			<TD VALIGN=top ALIGN=right>
				<FONT COLOR=<MT_IND_ITEM_COLOR> SIZE=<MT_IND_ITEM_SIZE>>
				&nbsp;%s
			</TD>
			</TR>
			</TABLE>
			";

	# SLIDE ELEMENT FORMATS

		$formats{"SLIDE_BODY"} = "
			<BODY
				<MT_SLIDE_BGIMAGE_FIELD>
				BGCOLOR=<MT_SLIDE_BG_COLOR>
				TEXT=<MT_SLIDE_TXT_COLOR>
				LINK=<MT_SLIDE_LINK_COLOR>
				ALINK=<MT_SLIDE_ALINK_COLOR>
				VLINK=<MT_SLIDE_VLINK_COLOR>
			>";

		# SLIDE TITLE
		$formats{"SLIDE_TITLE"} = "
			<FONT COLOR=<MT_SLIDE_TITLE1_COLOR> SIZE=<MT_SLIDE_TITLE1_SIZE>>
			<CENTER>%s</CENTER>
			<FONT COLOR=<MT_SLIDE_TITLE2_COLOR> SIZE=<MT_SLIDE_TITLE2_SIZE>>
			<CENTER><B><I>%s</I></B></CENTER>
			<MT_SLIDE_RULE_HTML>
			<P>
			<FONT COLOR=<MT_SLIDE_TXT_COLOR> SIZE=<MT_SLIDE_TXT_SIZE>>
			";

	# MENU BAR ELEMENT FORMATS

		# MENU BAR (STANDARD)
		$formats{"MENU_BAR"} = "
			<TABLE WIDTH=100%%
				BORDER=<MT_MENU_BDR_SIZE>
				CELLSPACING=<MT_MENU_SPC_SIZE>
				CELLPADDING=<MT_MENU_PAD_SIZE>
			>
			<TR <MT_MENU_BGCOLOR_FIELD>>
			<TD ALIGN=CENTER WIDTH=<MT_MENU_TOCCEL_SIZE>>
				<FONT
					COLOR=<MT_MENU_TXT_COLOR>
					SIZE=<MT_MENU_TOCTXT_SIZE>
				>
				<A HREF=%s><B><MT_MENU_TOCBTN_HTML></B></A>
			</TD>
			<TD ALIGN=CENTER WIDTH=<MT_MENU_INDCEL_SIZE>>
				<FONT
					COLOR=<MT_MENU_TXT_COLOR>
					SIZE=<MT_MENU_INDTXT_SIZE>
				>
				<A HREF=%s><B><MT_MENU_INDBTN_HTML></B></A>
			</TD>
			<TD ALIGN=CENTER WIDTH=<MT_MENU_PRECEL_SIZE>>
				<FONT
					COLOR=<MT_MENU_TXT_COLOR>
					SIZE=<MT_MENU_PRETXT_SIZE>
				>
				<A HREF=%s><B><MT_MENU_PREBTN_HTML></B></A>
			</TD>
			<TD ALIGN=CENTER WIDTH=<MT_MENU_NXTCEL_SIZE>>
				<FONT
					COLOR=<MT_MENU_TXT_COLOR>
					SIZE=<MT_MENU_NXTTXT_SIZE>
				>
				<A HREF=%s><B><MT_MENU_NXTBTN_HTML></B></A>
			</TD>
			<TD ALIGN=CENTER WIDTH=<MT_MENU_PAGCEL_SIZE>>
				<FONT
					COLOR=<MT_MENU_TXT_COLOR>
					SIZE=<MT_MENU_PAGTXT_SIZE>
				>
				%s
			</TD>
			</TR>
			</TABLE>
			<P>
			";

		# MENU BAR (USED FOR PRINTED PAGES)
		$formats{"MENU_BAR_P"} = "
			<!-- IGNORED MENU_BAR ARGS: %s %s %s -->
			<CENTER><A HREF=%s><B>%s</B></A></CENTER><BR>
			<P>
			";

	# TIMING REPORT FORMATS

		$formats{"TIMING_HEAD"} = "
			<HTML>
			<HEAD>
			<TITLE>MkTalk Timing Report</TITLE>
			<CENTER><FONT SIZE=+3><B>MkTalk Timing Report</B></FONT><CENTER>
			<CENTER><FONT SIZE=+1><B>%s</B></FONT><CENTER>
			<CENTER><HR WIDTH=50%%></H2><CENTER>
			<P>
			</HEAD>
			<BODY>
			<TABLE WIDTH=100% BORDER=0>
				<TH ALIGN=RIGHT>Start</TH>
				<TH ALIGN=RIGHT>Stop</TH>
				<TH>&nbsp;</TH>
				<TH ALIGN=LEFT>Title</TH>
				<TH ALIGN=CENTER>Slides</TH>
				<TH ALIGN=CENTER>Mins</TH>
				<TH ALIGN=CENTER>Mins/Slide</TH>
			";

		$formats{"TIMING_SECT"} = "
			<TR><TD COLSPAN=7><HR SIZE=1></TD></TR>
			";

		$formats{"TIMING_LINE"} = "
			<TR>
				<TD ALIGN=RIGHT>%s</TD>
				<TD ALIGN=RIGHT>%s</TD>
				<TD>&nbsp;</TD>
				<TD>%s</TD>
				<TD><CENTER>%s</CENTER></TD>
				<TD><CENTER>%s</CENTER></TD>
				<TD><CENTER>%s</CENTER></TD>
			</TR>
			";

		$formats{"TIMING_TAIL"} = "
			</TABLE>
			</BODY>
			</HTML>
			";

	# TOSS SOME LEADING TABS (TO MAKE THE OUTPUT PRETTIER)
	foreach $fKey ( keys %formats )
	{
		@lines = split( /\n/, $formats{$fKey} );
		foreach $line ( @lines )
		{
			$line =~ s/^\t\t\t//;
		}
		$formats{$fKey} = join( "\n", @lines );
	}
}


#######################################################################
#                                                                     #
#  Print command usage help text                                      #
#                                                                     #
#######################################################################
sub Usage
{
	print STDERR "Usage: $cmd [options] template(s)\n";
	print STDERR "   Options: \n";
	foreach $opt ( sort keys %help )
	{
		print STDERR "      $opt $help{$opt}\n";
	}
}


#######################################################################
#                                                                     #
#  Process command line arguments                                     #
#                                                                     #
#######################################################################
sub process_cmdline
{
	# ARGUMENT DEFAULTS

	%option = ();
	%help   = ();
	%alias  = ();

	$option{"-H"}    = 0;
	$help{"-H"}      = "      Print the $cmd usage HELP";
	$alias{"-h"}     = "-H";
	$alias{"-help"}  = "-H";
	$alias{"-HELP"}  = "-H";

	$option{"-V"} = "v4.0";
	$help{"-V"}   = "      Print the $cmd VERSION number";
	$alias{"-version"} = "-V";

	$option{"-D"} = 0;
	$help{"-D"}   = "      Print a DUMP of all $cmd tag names and fields";
	$alias{"-DUMP"} = "-D";

	$option{"-M"} = 0;
	$help{"-M"}   = "      Print the list of currently defined MACROS";
	$alias{"-MACROS"} = "-M";

	$option{"-S"} = 0;
	$help{"-S"}   = "      SUPRESS slide output";
	$alias{"-SUPPRESS"} = "-S";

	$option{"-b"} = "mt";
	$help{"-b"}   = "name  Set BASE name for slides ($option{'-b'})";
	$alias{"-base"} = "-b";

	$option{"-d"} = "";
	$help{"-d"}   = "file  Output a DUMP of all the input template tags";
	$alias{"-dump"} = "-d";

	$option{"-f"} = 0;
	$help{"-f"}   = "      FORCE existing output files to be overwritten";
	$alias{"-force"} = "-f";

	$option{"-l"} = 8;
	$help{"-l"}   = "#     Set chapter index column LIMIT ($option{'-l'})";
	$alias{"-length"} = "-l";

	$option{"-m"} = "";
	$help{"-m"}   = "file  Load MACROS from the named file";
	$alias{"-macros"} = "-m";

	$option{"-o"} = "";
	$help{"-o"}   = "file  Output an indented text OUTLINE";
	$alias{"-outline"} = "-o";

	$option{"-p"} = 0;
	$help{"-p"}   = "      Output pages in a PRINTABLE form";
	$alias{"-print"} = "-p";

	$option{"-r"} = "";
	$help{"-r"}   = "file  Output RAW HTML";
	$alias{"-raw"} = "-r";

	$option{"-s"} = 0;
	$help{"-s"}   = "#     Set START page number ($option{'-s'})";
	$alias{"-start"} = "-s";

	$option{"-t"} = "";
	$help{"-t"}   = "file  Output a TIMING report for the talk";
	$alias{"-timing"} = "-t";

	$option{"-v"} = 0;
	$help{"-v"}   = "      Run $cmd with VERBOSE output";
	@infiles      = ();

	# PROCESSING

	@CMDLINE = @ARGV;
	while ( @CMDLINE )
	{
		$arg = shift( @CMDLINE );

		$arg = $alias{$arg}  if ( $alias{$arg} );
	
		if ( $arg =~ /^-/ )
		{
			if ( $arg eq "-D" )
			{
				$option{"-D"} = 1;
				foreach $tag ( sort keys %tags )
				{
					print "<$tag";
					foreach $field ( sort keys %{$tags{$tag}} )
					{
						$val = $tags{$tag}->{$field};
						if ( $val eq "" ) { $val = '"' . $val . '"'; }
						if ( $val =~ / / ) { $val = '"' . $val . '"'; }
						if ( $val =~ /:/ ) { $val = '"' . $val . '"'; }
						print " $field=$val";
					}
					print ">\n";
				}
				exit( 0 );
			}
			elsif ( $arg eq "-H" )
			{
				&Usage;
				exit( 0 );
			}
			elsif ( $arg eq "-M" )
			{
				$option{"-M"} = 1;
				print "# $cmd macros\n\n";
				foreach $mac ( sort keys %macros )
				{
					print "start $mac\n";
					print "$macros{$mac}\n";
					print "stop $mac\n";
					print "\n";
				}
				exit( 0 );
			}
			elsif ( $arg eq "-S" )
			{
				$option{"-S"} = 1;
			}
			elsif ( $arg eq "-V" )
			{
				print "$option{$arg}\n";
				exit( 0 );
			}
			elsif ( $arg eq "-b" )
			{
				$option{"-b"} = shift( @CMDLINE );
			}
			elsif ( $arg eq "-d" )
			{
				$option{"-d"} = shift( @CMDLINE );
			}
			elsif ( $arg eq "-f" )
			{
				$option{"-f"} = 1;
			}
			elsif ( $arg eq "-l" )
			{
				$option{"-l"} = shift( @CMDLINE );
			}
			elsif ( $arg eq "-m" )
			{
				$option{"-m"} = shift( @CMDLINE );
				if ( ! -f $option{"-m"} )
				{
					print STDERR "Can not find macros file $option{'-m'}\n";
					&Usage;
					exit( 1 );
				}
				else
				{
					&load_macros( $option{"-m"} );
				}
			}
			elsif ( $arg eq "-o" )
			{
				$option{"-o"} = shift( @CMDLINE );
			}
			elsif ( $arg eq "-p" )
			{
				$option{"-p"} = 1;
				$formats{"MENU_BAR"} = $formats{"MENU_BAR_P"};
			}
			elsif ( $arg eq "-r" )
			{
				$option{"-r"} = shift( @CMDLINE );
			}
			elsif ( $arg eq "-s" )
			{
				$option{"-s"} = shift( @CMDLINE );
			}
			elsif ( $arg eq "-t" )
			{
				$option{"-t"} = shift( @CMDLINE );
			}
			elsif ( $arg eq "-v" )
			{
				$option{"-v"} = 1;
			}
			else
			{
				print STDERR "Unknown option $arg\n";
				&Usage;
				exit( 2 );
			}
		}
		else
		{
			if ( -f $arg )
			{
				@infiles = ( @infiles, $arg );
			}
			else
			{
				print STDERR "Can not find template file $arg\n";
				&Usage;
				exit( 3 );
			}
		}
	
	}
	
	if ( $#infiles < 0 )
	{
		print STDERR "No template files specified\n";
		&Usage;
		exit( 4 );
	}
}


#######################################################################
#                                                                     #
#  If the verbose option is set, print the arguments to STDERR.       #
#                                                                     #
#######################################################################
sub verbose
{
	if ( $option{"-v"} == 1 )
	{
		print STDERR @_;
	}
}


#######################################################################
#                                                                     #
#  Load a text file and return the lines as a list (not chop-ed !)    #
#                                                                     #
#######################################################################
sub load_file
{
	local( $fileName ) = $_[0];

	local( @data ) = ();

	if ( $fileName eq "" )
	{
		return @data;
	}

	if ( ! -f $fileName )
	{
		print STDERR "load_file: Could not find file: $fileName\n";
		exit( 5 );
	}

	if ( ! open( FILE, "<$fileName" ) )
	{
		print STDERR "load_file: Could not open file: $fileName\n";
		exit( 6 );
	}

	@data = <FILE>;

	close( FILE );

	return @data;
}


#######################################################################
#                                                                     #
#  Write the contents of a list to a text file (no CRs added!)        #
#                                                                     #
#######################################################################
sub store_file
{
	local( $file ) = $_[0];
	local( *text ) = $_[1];

	return  if ( $file eq "" );

	if ( $option{"-f"} != 1 )
	{
		if ( -f $file )
		{
			print STDERR "store_file: file exists: $file\n";
			exit( 5 );
		}
	}

	if ( ! open( FILE, ">$file" ) )
	{
		print STDERR "store_file: Could not open file: $file\n";
		exit( 6 );
	}

	print FILE @text;

	close( FILE );
}


#######################################################################
#                                                                     #
#  Load macros into internal state from the named file                #
#                                                                     #
#######################################################################
sub load_macros
{
	local( $macrosFile ) = $_[0];

	local( @mData ) = ();
	local( $key )   = "";
	local( $val )   = "";
	local( $mLine ) = "";
	local( $count ) = 0;
	local( $lineNum ) = 0;

	return 0  if ( $macrosFile eq "" );

	&verbose( "Loading macro file $macrosFile...\n" );

	@mData = &load_file( $macrosFile );

	chop( @mData );

	$inMacro = 0;
	foreach $mLine ( @mData )
	{
		$lineNum++;
		next if ( ($mLine =~ /^#/) && ($inMacro == 0) );
		next if ( ($mLine =~ /^$/) && ($inMacro == 0) );

		if ( $mLine =~ /^start /i )
		{
			$key = $mLine;
			$key =~ s/^start //i;
			$val = "";
			$inMacro = 1;
		}
		elsif ( $mLine =~ /^stop /i )
		{
			$key =~ tr/a-z/A-Z/;  # Macros internally are upper case
			$macros{$key} = $val;
			# print STDERR "load_macros: macros{$key} = $val\n";
			$key = "";
			$val = "";
			$count++;
			$inMacro = 0;
		}
		else
		{
			if ( $inMacro == 1 )
			{
				if ( $mLine =~ /<$key>/ )
				{
					print STDERR "load_macros: recursive macro detected\n";
					print STDERR "   file = $macrosFile\n";
					print STDERR "   line = $lineNum\n";
					print STDERR "   name = $key\n";
					print STDERR "   data = $mLine\n";
					exit( 1 );
				}

				$val .= $mLine;
			}
		}
	}

	return( $count );
}


#######################################################################
#                                                                     #
#                                                                     #
#                                                                     #
#######################################################################
sub OutOfDate
{
	local( $infile, $outfile, @junk ) = @_;
	local( $infile_time, $outfile_time );

	if ( ! -f $infile )
	{
		print STDERR "OutOfDate: $infile not found\n";
		exit( 1 );
	}

	if ( $infile eq $outfile )
	{
		print STDERR "OutOfDate: $infile == $outfile\n";
		return( 0 )
	}

	if ( ! -f $outfile )
	{
		# If outfiles does not exist, then out of date
		return( 1 );
	}

	$infile_time = (stat( $infile ))[9];
	$outfile_time = (stat( $outfile ))[9];

	if ( $infile_time > $outfile_time )
	{
		# Out of date
		return( 1 );
	}

	return( 0 );
}


#######################################################################
#                                                                     #
#  Takes a tag, eg: <MT_FOO title = "Help Me" file=Ronda foo= 3>      #
#  parses out the tag name, key/value pairs, and stores the result    #
#  into the global "tags" stucture. The function returns the name     #
#  of the tag that was parsed.                                        #
#                                                                     #
#######################################################################
sub parse_tag
{
	local( $rawTag ) = $_[0];   # <MT_FOO title = "Help Me" file=Ronda foo= 3>

	local( $tagName )    = "";
	local( $fieldName )  = "";
	local( $fieldValue ) = "";

	$rawTag =~ s/.*<//;           # MT_FOO title="Help Me" file=Ronda foo= 3>
	$rawTag =~ s/>.*//;           # MT_FOO title="Help Me" file=Ronda foo= 3

	$tagName = $rawTag;           # MT_FOO title = "Help Me" file=Ronda foo= 3
	$tagName =~ s/\s+.*//;        # MT_FOO

	$rawTag =~ s/$tagName\s+//;   # title = "Help Me" file=Ronda foo= 3
	$rawTag =~ s/\s+=/=/g;        # title= "Help Me" file=Ronda foo= 3
	$rawTag =~ s/=\s+/=/g;        # title="Help Me" file=Ronda foo=3

	$tagName =~ tr/a-z/A-Z/;      # Tags internally are upper case

	$tags{$tagName} = {};         # Blow away all the old fields/values

	while ( $rawTag ne "" )
	{
		$fieldName = $rawTag;         # title="Help Me" file=Ronda foo=3
		$fieldName =~ s/=.*//;        # title

		$rawTag =~ s/^$fieldName=//;  # "Help Me" file=Ronda foo=3

		$fieldValue = $rawTag;        # "Help Me" file=Ronda foo=3

		if ( $fieldValue =~ /^"/ )
		{
			$fieldValue =~ s/^"//;
			$fieldValue =~ s/".*//;

			$rawTag =~ s/\Q"$fieldValue"//;  # \Q Auto-quote meta chars
			$rawTag =~ s/^\s+//;
		}
		else
		{
			$fieldValue =~ s/\s+.*//;
			if ( $fieldValue =~ /\+/ )
			{
				$tmp = $fieldValue;
				$tmp =~ s/\+/\\+/g;
				$rawTag =~ s/^$tmp//;
			}
			else
			{
				$rawTag =~ s/^$fieldValue//;
			}
			$rawTag =~ s/^\s+//;
		}

		$fieldName =~ tr/a-z/A-Z/;  # Fields internally are upper case
		$tags{$tagName}->{$fieldName} = $fieldValue;
	}

	return( $tagName );
}


#######################################################################
#                                                                     #
#  Similar to perl index function, but takes a regular expression.    #
#                                                                     #
#######################################################################
sub eindex
{
	local( $str ) = $_[0];
	local( $exp ) = $_[1];
	local( $pos ) = $_[2];
	local( $ind ) = -1;

	substr( $str, 0, $pos ) = "";

	if ( $str =~ /$exp/m )
	{
		$str =~ s/\n/ /g;
		$str =~ s/$exp.*//;
		$ind = length( $str ) + $pos;
	}

	return( $ind );
}


#######################################################################
#                                                                     #
#  Scan the raw input lines and parse out each of the custom tags.    #
#  For each custom tag, call the tag handler function.                #
#                                                                     #
#######################################################################
sub parse_data
{
	local( $handler ) = $_[0];  # tag handler
	local( *data )    = $_[1];  # input data (pass by ref to enable modify)

	local( $l )     = 0;   # line of input
	local( $i )     = 0;   # index of input
	local( $ll )    = 0;   # line of tag
	local( $ii )    = 0;   # index of tag
	local( $td )    = "";  # extracted tag data
	local( $t )     = "";  # extracted tag name
	local( $ch )    = "";  # input character
	local( @nest )  = ();  # tag/macro nest (line & index pairs)
	local( $inTag ) = 0;   # parser is inside a tag

	if ( ! defined &$handler ) {
		print STDERR "ERROR: Tag handler $handler not defined.\n";
		return;
	}

	while ( $l <= $#data )
	{
		$ch = substr( $data[$l], $i, 1 );
#		if ( $inTag == 1 )
#		{
#			if ( $ch eq "\n" )
#			{
#				chomp( $data[$l] );
#				$data[$l] .= " " . $data[$l+1];
#				splice( @data, $l+1, 1 );
#				$ch = " ";
#			}
#			if ( $ch eq "\t" )
#			{
#				substr( $data[$l], $i, 1 ) = " ";
#				$ch = " ";
#			}
#		}
		$td .= $ch;

		if ( $ch eq "<" )
		{
			$inTag = 1  if ( substr( $data[$l], $i+1, 1 ) =~ /\w/ );
			$td = $ch;
			@nest = ( @nest, $l, $i );
		}
		elsif ( $ch eq ">" )
		{
			$inTag = 0;
			$t = $td;
			$t =~ s/>.*//m;
			$t =~ s/.*<//m;
			$t =~ s/\s.*//m;
			$t =~ tr/a-z/A-Z/;  # Tags internally are upper case
			if ( (defined $tags{$t}) || (defined $macros{$t}) )
			{
				if ( $#nest <= 1 )
				{
					# Not Nested
					$ii = pop( @nest );
					$ll = pop( @nest );
					( $l, $i ) = &$handler( $td, $ll, $ii, $l, $i, \@data );
					@nest = ();
					$td = "";
					next;
				}
				else
				{
					# Is Nested
					$ii = pop( @nest );
					$ll = pop( @nest );
					&$handler( $td, $ll, $ii, $l, $i, \@data );
					$i = $nest[1];
					$l = $nest[0];
					@nest = ();
					$td = "";
					next;
				}
			}
			else
			{
				@nest = ();
			}
			$td = "";
		}

		$i++;
		if ( $i >= length($data[$l]) )
		{
			# new array-element/line
			$l++;
			$i=0;
		}
	}

	# Call tag handler at the end of file (with tag "" as an EOF flag)
	( $li, $si ) = &$handler( "", $ll, $ii, $l, $i, \@data );
}


#######################################################################
#                                                                     #
#  Takes a time in the form "14:15" (24 hr) or "2:15pm" (12 hr)       #
#  and converts it to a scalar in minutes.                            #
#                                                                     #
#######################################################################
sub time2mins
{
	local( $time ) = $_[0];

	local( $base ) = 24;
	local( $tod ) = "am";

	local( $mins ) = 0;
	local( $hr )   = 0;
	local( $mn )   = 0;

	if ( $time =~ /am/i )
	{
		$time =~ s/am//i;
		$tod = "am";
		$base = 12;
	}
	elsif ( $time =~ /pm/i )
	{
		$time =~ s/pm//i;
		$tod = "pm";
		$base = 12;
	}
	else
	{
		$base = 24;
	}

	$time =~ s/\s+//gi;

	( $hr, $mn ) = split( ":", $time );
	$hr += 12  if ( ($tod eq "pm") && ($base == 12) && ($hr < 12) );
	$mins = $hr * 60 + $mn;

	return( $mins );
}


#######################################################################
#                                                                     #
#  Takes a scalar in minutes and converts it to a time in the         #
#  form "14:15" (24 hr) or "2:15pm" (12 hr).                          #
#                                                                     #
#######################################################################
sub mins2time
{
	local( $mins ) = $_[0];
	local( $base ) = $_[1];

	local( $hr )   = int( $mins / 60 );
	local( $mn )   = int( $mins - ($hr * 60) );

	local( $tod )  = "";

	if ( $base == 12 )
	{
		if ( $hr > 12 )
		{
			$hr -= 12;
			$tod = "pm";
		}
		else
		{
			$tod = "am";
		}
	}

	$mn = "0" . $mn  if ( $mn <= 9 );

	$time = $hr . ":" . $mn . $tod;

	return( $time );
}


#######################################################################
#                                                                     #
#  Replaces a region within the input data with new data.             #
#  Returns the new end line and index values of the new data region.  #
#                                                                     #
#######################################################################
sub edit
{
	local( $rep )  = $_[0];  # replacement data
	local( $tsl )  = $_[1];  # tag start line
	local( $tsi )  = $_[2];  # tag start index
	local( $tel )  = $_[3];  # tag end line
	local( $tei )  = $_[4];  # tag end index
	local( *data ) = $_[5];  # the template data

	if ( $tsl == $tel )
	{
		# Delete and insert within the same line
		# ###---###
		substr( $data[$tsl], $tsi, ($tei-$tsi+1) ) = $rep;
	}
	elsif ( $tsl == ($tel-1) )
	{
		# Delete from end line and insert into start line
		# ######---
		# ---######
		substr( $data[$tel], 0, $tei+1 ) = "";
		substr( $data[$tsl], $tsi ) = $rep;
	}
	else
	{
		# Delete part of end line, delete in-bewteen lines,
		# and insert into start line
		# ######---
		# ---------
		# ---######
		substr( $data[$tel], 0, $tei+1 ) = "";
		splice( @data, ($tsl+1), ($tel-$tsl-1) );
		substr( $data[$tsl], $tsi ) = $rep;
	}

	local( $rel )  = $tsl;                   # replacement-data end line
	local( $rei )  = $tsi + length( $rep );  # replacement-data end index

	return( $rel, $rei );
}


#######################################################################
#                                                                     #
#  Given an integer argument, this returns the output file name.      #
#                                                                     #
#######################################################################
sub numFile
{
	return( $option{"-b"} . sprintf( "%04d", $_[0] ) . ".htm" );
}


#######################################################################
#                                                                     #
#  Build the TOC page and dump it to a file.                          #
#                                                                     #
#######################################################################
sub dump_toc
{
	local( *hTags ) = $_[0];  # the hierarchy tags

	local( $tag_name ) = "";
	local( $tocData )  = "";
	local( @toc )      = ();
	local( $chapBlock ) = 0;

	$fileNum = 0;
	foreach $rawTag ( @hTags )
	{
		$tag_name = &parse_tag( $rawTag );

		if ( $tag_name eq "MT_TALK" )
		{
			$tocData = sprintf(
				$formats{"HEADER"},        # Format
				$tags{$tag_name}->{TITLE}    # WINDOW TITLE
			);
			@toc = ( @toc, $tocData );

			$tocData = sprintf(
				$formats{"TOC_MT_TALK"},    # Format
				$tags{$tag_name}->{TITLE}     # PAGE TITLE
			);
			@toc = ( @toc, $tocData );

			$fileNum++;
		}
		elsif ( $tag_name eq "MT_PART" )
		{
			if ( $chapBlock == 1 )
			{
				$chapBlock = 0;
				@toc = ( @toc, $formats{"TOC_MT_CHAPTER_END"} );
			}

			$tocData = sprintf(
				$formats{"TOC_MT_PART"},   # Format
				$tags{$tag_name}->{TITLE}    # TITLE
			);
			@toc = ( @toc, $tocData );
		}
		elsif ( $tag_name eq "MT_SECTION" )
		{
			if ( $chapBlock == 1 )
			{
				$chapBlock = 0;
				@toc = ( @toc, $formats{"TOC_MT_CHAPTER_END"} );
			}

			$tocData = sprintf(
				$formats{"TOC_MT_SECTION"},  # Format
				$tags{$tag_name}->{TITLE}      # TITLE
			);
			@toc = ( @toc, $tocData );
		}
		elsif ( $tag_name eq "MT_CHAPTER" )
		{
			if ( $chapBlock == 0 )
			{
				$chapBlock = 1;
				@toc = ( @toc, $formats{"TOC_MT_CHAPTER_START"} );
			}

			$tocData = sprintf(
				$formats{"TOC_MT_CHAPTER"},  # Format
				&numFile( $fileNum ),          # URL
				$tags{$tag_name}->{TITLE},     # TITLE
				($fileNum + $option{"-s"})     # Page Number
			);
			@toc = ( @toc, $tocData );

			$fileNum++;
		}
		elsif ( $tag_name eq "MT_SLIDE" )
		{
			$fileNum++;
		}
	}

	@toc = ( @toc, $formats{"TRAILER"} );

	&parse_data( "edit_tags", \@toc );  # Apply macros

	&store_file( &numFile( 0 ), \@toc );
}


#######################################################################
#                                                                     #
#  Build chapter index pages and dump them to files.                  #
#                                                                     #
#######################################################################
sub dump_ind
{
	local( *hTags ) = $_[0];  # the hierarchy tags

	local( $tag_name )  = "";
	local( $indData )   = "";
	local( @ind )       = ();
	local( $indCount )  = 0;
	local( $indLimit )  = $option{'-l'};
	local( $indLevel )  = 0;
	local( $indRemain ) = 0;
	local( $col_width )  = 0;
	local( $chap_name ) = 0;
	local( $cachedChapNum ) = 0;

	&verbose( "         page ----" );

	$fileNum = 0;
	foreach $rawTag ( @hTags )
	{
		$tag_name = &parse_tag( $rawTag );

		if ( $tag_name eq "MT_TALK" )
		{
			$indCount = 0;
			$fileNum++;
		}
		elsif ( $tag_name eq "MT_CHAPTER" )
		{
			$indCount = 0;

			if ( @ind )
			{
				@ind = ( @ind, $formats{"CHAPTER_IND_LIST_TAIL"} );
				@ind = ( @ind, $formats{"TRAILER"} );
				&parse_data( "edit_tags", \@ind );     # Apply macros
				&store_file( &numFile( $cachedChapNum ), \@ind );
				@ind = ();

				&verbose( sprintf( "\b\b\b\b%04d", $cachedChapNum ) );
			}

			$indData = sprintf(
				$formats{"HEADER"},        # Format
				$tags{$tag_name}->{TITLE}    # TITLE
			);
			@ind = ( @ind, $indData );

			@ind = ( @ind, $formats{"IND_BODY"} );

			$indData = sprintf(
				$formats{"MENU_BAR"},   # Format
				&numFile( 0 ),            # TOC URL
				&numFile( $fileNum ),     # INDX URL
				&numFile( $fileNum-1 ),   # PREV URL
				&numFile( $fileNum+1 ),   # NEXT URL
				$fileNum + $option{"-s"}  # PAGE NUMBER
			);
			@ind = ( @ind, $indData );

			$indData = sprintf(
				$formats{"CHAPTER_IND_TITLE"},  # Format
				$tags{$tag_name}->{TITLE},        # TITLE
			);
			@ind = ( @ind, $indData );

			@ind = ( @ind, $formats{"CHAPTER_IND_LIST_HEAD"} );

			$indLimit = $tags{$tag_name}->{INDLIMIT}  ||  $option{'-l'};

			$chap_name = $tags{MT_CHAPTER}->{TITLE};
			$col_width =
				100 / int ( ( $g_sliPerChap{$chap_name} / $indLimit ) + 0.999 );
			$col_width .= "%";

			$indData = sprintf(
				$formats{"CHAPTER_IND_LIST_START"},  # Format
				$col_width                             # COLUMN WIDTH
			);
			@ind = ( @ind, $indData );

			$cachedChapNum = $fileNum;
			$fileNum++;
		}
		elsif ( $tag_name eq "MT_SLIDE" )
		{
			$indLevel = $tags{$tag_name}->{INDLEVEL} || 0;
			$indLevel =~ s/%//g;  # indLevel must be % to compute indRemain
			if ( ($indLevel < 0) || ($indLevel > 100) )
			{
				print STDERR "Warning: indLevel $indLevel out of bounds, ";
				$indLevel = 0    if ( $indLevel < 0 );
				$indLevel = 100  if ( $indLevel > 100 );
				print STDERR "substituting $indLevel\n";
			}
			$indRemain = 100 - $indLevel;

			$indData = sprintf(
				$formats{"CHAPTER_IND_ITEM"},  # Format
				$indLevel,                       # Index Indentation Level
				&numFile( $fileNum ),            # URL
				$tags{$tag_name}->{TITLE},       # TITLE
				$indRemain,                      # Left over after indLevel
				$fileNum + $option{"-s"}         # Page Number
			);
			@ind = ( @ind, $indData );

			$indCount++;

			if ( $indCount >= $indLimit )
			{
				@ind = ( @ind, $formats{"CHAPTER_IND_LIST_END"} );
				$indData = sprintf(
					$formats{"CHAPTER_IND_LIST_START"},  # Format
					$col_width                             # COLUMN WIDTH
				);
				@ind = ( @ind, $indData );

				$indCount = 0;
			}

			$fileNum++;
		}
	}

	@ind = ( @ind, $formats{"CHAPTER_IND_LIST_TAIL"} );
	@ind = ( @ind, $formats{"TRAILER"} );
	&parse_data( "edit_tags", \@ind );     # Apply macros
	&store_file( &numFile( $cachedChapNum ), \@ind );

	&verbose( sprintf( "\b\b\b\b%04d", $cachedChapNum ) );

	&verbose( "\n" );
}


#######################################################################
#                                                                     #
#  Dump slides to files.                                              #
#                                                                     #
#######################################################################
sub dump_sli
{
	local( *data ) = $_[0];  # input data

	local( $rawLine )  = "";
	local( $theTag )   = "";
	local( $tag_name ) = "";
	local( $sliData )  = "";
	local( @sli )      = ();
	local( $inSlide )  = 0;
	local( $fileNum )  = 0;
	local( $nextPage ) = 0;
	local( $indPage )  = 0;
	local( $cachedSlideNum ) = 0;

	&verbose( "         page ----" );

	foreach $rawLine ( @data )
	{
		if ( $rawLine =~ /MT_TALK|MT_CHAPTER|MT_SLIDE/i )
		{
			$rawLine =~ s/.*</</;
			$rawLine =~ s/>.*/>/;

			$inSlide = 0;

			chomp( $theTag = $rawLine );

			$tag_name = &parse_tag( $theTag );

			if ( $tag_name eq "MT_TALK" )
			{
				$fileNum++;
			}
			elsif ( $tag_name eq "MT_CHAPTER" )
			{
				$indPage = $fileNum;
				$fileNum++;
			}
			elsif ( $tag_name eq "MT_SLIDE" )
			{
				&verbose( sprintf( "\b\b\b\b%04d", $fileNum ) );

				$inSlide = 1;
				if ( @sli )
				{
					@sli = ( @sli, $formats{"TRAILER"} );
					&parse_data( "edit_tags", \@sli );     # Apply macros
					&store_file( &numFile( $cachedSlideNum ), \@sli );
					@sli = ();
				}

				$sliData = sprintf(
					$formats{"HEADER"},        # Format
					$tags{$tag_name}->{TITLE}    # TITLE
				);
				@sli = ( @sli, $sliData );

				@sli = ( @sli, $formats{"SLIDE_BODY"} );

				if ( $fileNum >= ($g_pageNum-1) ) {
					$nextPage = 0;  # Wrap around to the TOC
				} else {
					$nextPage = $fileNum+1;
				}
				$sliData = sprintf(
					$formats{"MENU_BAR"},   # Format
					&numFile( 0 ),            # TOC URL
					&numFile( $indPage ),     # INDX URL
					&numFile( $fileNum-1 ),   # PREV URL
					&numFile( $nextPage ),    # NEXT URL
					$fileNum + $option{"-s"}  # PAGE NUMBER
				);
				@sli = ( @sli, $sliData );

				$sliData = sprintf(
					$formats{"SLIDE_TITLE"},     # Format
					$tags{MT_CHAPTER}->{TITLE},    # TITLE (CHAPTER NAME)
					$tags{$tag_name}->{TITLE}      # SUBTITLE (SLIDE NAME)
				);
				@sli = ( @sli, $sliData );

				$cachedSlideNum = $fileNum;
				$fileNum++;
			}
		}
		else
		{
			if ( $inSlide == 1 )
			{
				@sli = ( @sli, $rawLine );
			}
		}
	}

	@sli = ( @sli, $rawLine );
	@sli = ( @sli, $formats{"TRAILER"} );
	&parse_data( "edit_tags", \@sli );     # Apply macros
	&store_file( &numFile( $cachedSlideNum ), \@sli );

	&verbose( "\n" );
}


#######################################################################
###########################  TAG HANDLERS  ############################
#######################################################################


#######################################################################
#                                                                     #
#  This is a tag handler function that can be called by the           #
#  parse_data function for each tag it encounters and extracts.       #
#                                                                     #
#  This tag handler generates and prints out a timing report.         #
#                                                                     #
#######################################################################
sub time_rep
{
	local( $rawTag ) = $_[0];  # raw tag eg: <MT_FOO bar="eep">
	local( $tsl )    = $_[1];  # tag start line
	local( $tsi )    = $_[2];  # tag start index
	local( $tel )    = $_[3];  # tag end line
	local( $tei )    = $_[4];  # tag end index
	local( *data )   = $_[5];  # the template data

	local( $tag_name ) = "";

	# if the tag is "", it means EOF (end of file)
	if ( $rawTag ne "" )
	{
		$tag_name = &parse_tag( $rawTag );
	}

	if ( ( $tag_name eq "MT_SECTION" ) || ($tag_name eq "") )
	{
		# PRINT REPORT FOR LAST SECTION
		if ( $chapSlideCount > 0 )
		{
			$chapSlides{$tags{"MT_CHAPTER"}->{TITLE}} = $chapSlideCount;

			$mins = &time2mins( $sectStop ) - &time2mins( $sectStart );
			$minsPerSlide = $mins / $sectSlideCount;
			$minsPerSlide = sprintf( "%.2f", $minsPerSlide );

			if ( $mins < 0 )
			{
				print STDERR "ERROR, did you specify am/pm or use 24 time ?\n";
			}

			printf( OUTPUT $formats{"TIMING_SECT"} );
			printf( OUTPUT
				$formats{"TIMING_LINE"},
				$sectStart,
				$sectStop,
				"<B>$sectName</B>",      # Kind of a format hack :^P
				$sectSlideCount,
				$mins,
				$minsPerSlide
			);

			$firstChapt = 1;
			foreach $key ( @chapNames )
			{
				if ( $firstChapt == 1 )
				{
					$firstChapt = 0;
					$time = $sectStart;
				}
				else
				{
					$time = &time2mins( $time )
						+ $minsPerSlide * $chapSlides{$lastKey};
					if ( $sectStart =~ /m/i ) {
						$base = 12;
					} else {
						$base = 24;
					}
					$time = &mins2time( $time, $base );
				}
				$lastKey = $key;

				printf( OUTPUT
					$formats{"TIMING_LINE"},
					$time,
					"&nbsp;",
					$key,
					$chapSlides{$key},
					"&nbsp;",
					"&nbsp;"
				);
			}
		}
		if ( $tag_name eq "" )
		{
			return( $tel, $tei );
		}

		# START NEW SECTION
		$sectName  = $tags{$tag_name}->{TITLE};
		$sectStart = $tags{$tag_name}->{START};
		$sectStop  = $tags{$tag_name}->{STOP};

		$sectSlideCount = 0;
		$chapSlideCount = 0;
		%chapSlides = ();
		@chapNames = ();
	}
	elsif ( $tag_name eq "MT_CHAPTER" )
	{
		$chapSlideCount = 0;
		@chapNames = ( @chapNames, $tags{"MT_CHAPTER"}->{TITLE} );
	}
	elsif ( $tag_name eq "MT_SLIDE" )
	{
		$sectSlideCount++;
		$chapSlideCount++;
		$chapSlides{$tags{MT_CHAPTER}->{TITLE}} = $chapSlideCount;
	}

	return( $tel, $tei );
}


#######################################################################
#                                                                     #
#  This is a tag handler function that can be called by the           #
#  parse_data function for each tag it encounters and extracts.       #
#                                                                     #
#  This tag handler:                                                  #
#     1) processes MT_INCLUDE tags                                    #
#     2) gathers linkage and filename symbols/info used by            #
#        subsequent MT_GOTO processing and navigation HREFs/links:    #
#                                                                     #
#           %g_name2file    Name-to-file name mapping for MT_GOTOs    #
#           @g_hierTags     Raw tags used to generate TOC indexes     #
#           $g_pageNum      Number of pages (TOC, INDs, SLIDEs)       #
#           %g_sliPerChap   Number of slides per chapter name         #
#                                                                     #
#######################################################################
sub inc_sym
{
	local( $rawTag ) = $_[0];  # raw tag eg: <MT_FOO bar="eep">
	local( $tsl )    = $_[1];  # tag start line
	local( $tsi )    = $_[2];  # tag start index
	local( $tel )    = $_[3];  # tag end line
	local( $tei )    = $_[4];  # tag end index
	local( *data )   = $_[5];  # the template data

	local( $tag_name ) = "";
	local( $chap_name ) = "";

	# if the tag is "", it means EOF (end of file)
	if ( $rawTag ne "" )
	{
		$tag_name = &parse_tag( $rawTag );
	}

	if ( $tag_name eq "MT_INCLUDE" )
	{
		if ( defined $tags{$tag_name}->{FILE} )
		{
			# print STDERR "MT_INCLUDE $tags{$tag_name}->{FILE}\n";
			$newData = join( "", &load_file( $tags{$tag_name}->{FILE} ) );
			# Apply edits (ignore return values cuz' we want to reparse)
			&edit( $newData, $tsl, $tsi, $tel, $tei, \@data );
			# Instruct the parser to parse the new included material
			$tel = $tsl;
			$tei = $tsi;
		}
	}
	elsif (
		($tag_name eq "MT_TALK" ) ||
		($tag_name eq "MT_PART" ) ||
		($tag_name eq "MT_SECTION" ) ||
		($tag_name eq "MT_CHAPTER" ) ||
		($tag_name eq "MT_SLIDE" ) )
	{
		if (($tag_name eq "MT_TALK") ||
			($tag_name eq "MT_CHAPTER") ||
			($tag_name eq "MT_SLIDE") )
		{
			# Name-to-file mapping for MT_GOTO tags
			if ( defined $tags{$tag_name}->{NAME} )
			{
				$g_name2file{$tags{$tag_name}->{NAME}} = &numFile( $g_pageNum );
			}

			&verbose( sprintf( "\b\b\b\b%04d", $g_pageNum ) );
			$g_pageNum++;

			if ( $tag_name eq "MT_SLIDE" )
			{
				$chap_name = $tags{MT_CHAPTER}->{TITLE};
				$g_sliPerChap{$chap_name}++;
			}
		}

		# Tags needed to generate TOC and chapter indexes
		@g_hierTags = ( @g_hierTags, $rawTag );

		# For one of our tags that we don't do an EDIT,
		# tell the parser to continue AFTER the ">"
		$tei++;
	}
	elsif ( $tag_name eq "MT_REFCODE" )
	{
		# Name-to-file mapping for MT_GOTO tags
		if ( defined $tags{$tag_name}->{NAME} )
		{
			$g_name2file{$tags{$tag_name}->{NAME}} =
				$tags{$tag_name}->{OUTFILE};
		}

		# For one of our tags that we don't do an EDIT,
		# tell the parser to continue AFTER the ">"
		$tei++;
	}
	elsif ( defined $macros{$tag_name} )
	{
		&edit( $macros{$tag_name}, $tsl, $tsi, $tel, $tei, \@data );
		# Instruct the parser to parse the new included material
		# (this enables us to support nested macros!)
		$tel = $tsl;
		$tei = $tsi;
	}

	return( $tel, $tei );
}


#######################################################################
#                                                                     #
#  This is a tag handler function that can be called by the           #
#  parse_data function for each tag it encounters and extracts.       #
#                                                                     #
#  This tag handler:                                                  #
#     1) processes MT_GOTO tags (uses %g_name2file)                   #
#     2) processes MT_REFCODE tags                                    #
#     3) performs macro subsitutions                                  #
#                                                                     #
#######################################################################
sub edit_tags
{
	local( $rawTag ) = $_[0];  # raw tag eg: <MT_FOO bar="eep">
	local( $tsl )    = $_[1];  # tag start line
	local( $tsi )    = $_[2];  # tag start index
	local( $tel )    = $_[3];  # tag end line
	local( $tei )    = $_[4];  # tag end index
	local( *data )   = $_[5];  # the template data

	local( $tag_name ) = "";
	local( @refcode )  = ();
	local( @refdata )  = ();
	local( $refData )  = "";
	local( $shrtIn )   = "";

	# if the tag is "", it means EOF (end of file)
	if ( $rawTag ne "" )
	{
		$tag_name = &parse_tag( $rawTag );
	}

	if ( $tag_name eq "MT_GOTO" )
	{
		$name = $tags{$tag_name}->{NAME};
		if ( $name )
		{
			$file = $g_name2file{$name};
			if ( $file )
			{
				$target = $tags{$tag_name}->{TARGET} || "_self";
				$goto = sprintf( $formats{"GOTO"}, $file, $target );
				# Apply edits (tell parser to skip the new GOTO material)
				( $tel, $tei ) = &edit( $goto, $tsl, $tsi, $tel, $tei, \@data );
			}
			else
			{
				print STDERR "ERROR: MT_GOTO refers to non-existant name:\n";
				print STDERR "$rawTag\n";
				exit;
			}
		}
		else
		{
			print STDERR "ERROR: MT_GOTO tag has no name field:\n";
			print STDERR "$rawTag\n";
			exit;
		}
	}
	elsif ( $tag_name eq '/MT_GOTO' )
	{
		$dt = $formats{'/GOTO'};
		# Apply edits
		( $tel, $tei ) = &edit( $dt, $tsl, $tsi, $tel, $tei, \@data );
	}
	elsif ( $tag_name eq "MT_REFCODE" )
	{
		$inFile  = $tags{$tag_name}->{INFILE};
		$outFile = $tags{$tag_name}->{OUTFILE};

		if ( $inFile && $outFile )
		{
			# REFCODE LINK

			# Apply edits (toss the refcode tag)
			( $tel, $tei ) = &edit( "", $tsl, $tsi, $tel, $tei, \@data );

			# REFCODE FILE

			if ( &OutOfDate( $inFile, $outFile ) )
			{
				@refcode = ();

				$shrtIn = $inFile;    # Short (no path) inFile name
				$shrtIn =~ s%.*/%%;;

				# HEADER

				@refcode = ( @refcode, sprintf( $formats{"HEADER"}, $shrtIn ) );
				@refcode = ( @refcode, $formats{"REFCODE_BODY"} );

				# TITLES

				$refData = sprintf(
					$formats{"REFCODE_PRE"},     # Format
					$tags{MT_CHAPTER}->{TITLE},    # TITLE
					$shrtIn                        # SUBTITLE
				);
				@refcode = ( @refcode, $refData );

				$color = $tags{$tag_name}->{COLOR}
						|| $macros{"MT_REF_TXT_COLOR"};
				$size  = $tags{$tag_name}->{SIZE}
						|| $macros{"MT_REF_TXT_SIZE"};
				$font  = sprintf( $formats{"REFCODE_FONT"}, $color, $size );
				@refcode = ( @refcode, $font );

				&parse_data( "edit_tags", \@refcode );  # Apply macros

				# DATA

				@refdata = &load_file( $inFile );
				grep( s/</&lt;/g, @refdata );
				grep( s/>/&gt;/g, @refdata );
				@refcode = ( @refcode, @refdata );

				# TRAILER

				@refdata = ( $formats{"REFCODE_POST"} );
				@refdata = ( @refdata, $formats{"TRAILER"} );
				&parse_data( "edit_tags", \@refdata );  # Apply macros
				@refcode = ( @refcode, @refdata );

				&store_file( $outFile, \@refcode );
			}
		}
		else
		{
			# For one of our tags that we don't do an EDIT,
			# tell the parser to continue AFTER the ">"
			$tei++;
		}
	}
	elsif ( defined $macros{$tag_name} )
	{
		&edit( $macros{$tag_name}, $tsl, $tsi, $tel, $tei, \@data );
		# Instruct the parser to parse the new included material
		# (this enables us to support nested macros!)
		$tel = $tsl;
		$tei = $tsi;
	}
	else
	{
		# For one of our tags that we don't do an EDIT,
		# tell the parser to continue AFTER the ">"
		$tei++;
	}

	return( $tel, $tei );
}


#######################################################################
#                                                                     #
#  This is a tag handler function that can be called by the           #
#  parse_data function for each tag it encounters and extracts.       #
#                                                                     #
#  This tag handler simply prints the hierarchy tags as an outline.   #
#                                                                     #
#######################################################################
sub dump_outline
{
	local( $rawTag ) = $_[0];  # raw tag eg: <MT_FOO bar="eep">
	local( $tsl )    = $_[1];  # tag start line
	local( $tsi )    = $_[2];  # tag start index
	local( $tel )    = $_[3];  # tag end line
	local( $tei )    = $_[4];  # tag end index
	local( *data )   = $_[5];  # the template data

	local( $tag_name ) = "";
	local( $title )    = "";
	local( $indent )   = 0;

	# if the tag is "", it means EOF (end of file)
	if ( $rawTag ne "" )
	{
		$tag_name = &parse_tag( $rawTag );
	}

	$title = $tags{$tag_name}->{TITLE};
	if ( $title )
	{
		$indent = 0  if ( $tag_name eq "MT_TALK" );
		$indent = 1  if ( $tag_name eq "MT_PART" );
		$indent = 2  if ( $tag_name eq "MT_SECTION" );
		$indent = 3  if ( $tag_name eq "MT_CHAPTER" );
		$indent = 4  if ( $tag_name eq "MT_SLIDE" );

		print OUTPUT "\t" x $indent . $title . "\n";
	}

	return( $tel, $tei+1 );
}


#######################################################################
#                                                                     #
#  This is a tag handler function that can be called by the           #
#  parse_data function for each tag it encounters and extracts.       #
#                                                                     #
#  This tag handler simply prints the tag out.                        #
#                                                                     #
#######################################################################
sub dump_tag
{
	local( $rawTag ) = $_[0];  # raw tag eg: <MT_FOO bar="eep">
	local( $tsl )    = $_[1];  # tag start line
	local( $tsi )    = $_[2];  # tag start index
	local( $tel )    = $_[3];  # tag end line
	local( $tei )    = $_[4];  # tag end index
	local( *data )   = $_[5];  # the template data

	local( $tag_name ) = "";

	# if the tag is "", it means EOF (end of file)
	if ( $rawTag ne "" )
	{
		$tag_name = &parse_tag( $rawTag );
		print OUTPUT "$tsl: $rawTag\n";
	}

	return( $tel, $tei+1 );
}


#######################################################################
##############################  MAIN  #################################
#######################################################################


&init_state;
&process_cmdline;

foreach $template ( @infiles )
{
	&verbose( "Loading template file $template...\n" );
	@input = &load_file( $template );

	&verbose( "Processing template file $template...\n" );

	# PASS 1 - Preprocess (MT_INCLUDE tags and do symbol gathering)
	&verbose( "   Symbol pass...\n" );
	&verbose( "      page ----" );
	&parse_data( "inc_sym", \@input );
	&verbose( "\n" );

	# PASS 2 - Edits (MT_GOTO, MT_REFCODE, Macro subsitution)
	&verbose( "   Edit pass...\n" );
	&parse_data( "edit_tags", \@input );  # Use %g_name2file for MT_GOTOs

	# PASS 3 - Output
	&verbose( "   Output pass(es)...\n" );

	if ( $option{"-d"} ne "" )
	{
		&verbose( "      Tag dump...\n" );
		open( OUTPUT, ">$option{'-d'}" ) || die "Could not open $option{'-d'}";
		&parse_data( "dump_tag", \@input );
		close( OUTPUT );
	}

	if ( $option{"-o"} ne "" )
	{
		&verbose( "      Outline...\n" );
		open( OUTPUT, ">$option{'-o'}" ) || die "Could not open $option{'-o'}";
		&parse_data( "dump_outline", \@input );
		close( OUTPUT );
	}

	if ( $option{"-r"} ne "" )
	{
		&verbose( "      Raw HTML...\n" );
		open( OUTPUT, ">$option{'-r'}" ) || die "Could not open $option{'-r'}";
		print OUTPUT @input;
		close( OUTPUT );
	}

	if ( $option{"-t"} ne "" )
	{
		&verbose( "      Timing report...\n" );
		open( OUTPUT, ">$option{'-t'}" ) || die "Could not open $option{'-t'}";
		printf( OUTPUT $formats{"TIMING_HEAD"}, $tags{"MT_TALK"}->{TITLE} );
		&parse_data( "time_rep", \@input );
		printf( OUTPUT $formats{"TIMING_TAIL"} );
		close( OUTPUT );
	}

	if ( $option{"-S"} == 0 )
	{
		&verbose( "      TOC...\n" );
		&dump_toc( \@g_hierTags );  # Output TOC
		&verbose( "      Indexes...\n" );
		&dump_ind( \@g_hierTags );  # Output Chapter Indexes
		&verbose( "      Slides...\n" );
		&dump_sli( \@input );       # Output Slides
	}
}


