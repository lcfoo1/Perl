#!perl -w 
use File::Copy;
use XML::Simple qw(:strict);

#### CONSTANTS ######
$flexBOMUservar = "SCVars.TP_FLEXBOMRECIPE";
$queryModeUservar = "_UserVars.QUERY_MODE";
$lotAttrNumber = 1473;
#######################

#### CONFIGURATION ######
$TP_RECIPE_BASENAME_KEY = "KNC";
$PATH_TO_CORRELATION_DIR = 'C:\Perl\Programs\AddLotAttributes\kncdt0ab0mcb009w26a1\ASTRA\NEMO_Input_Files\CMT\Samples\correlation';
$PATH_TO_RECIPE_DIR = 'C:\Perl\Programs\AddLotAttributes\kncdt0ab0mcb009w26a1\ASTRA\NEMO_Input_Files\CMT\Samples\recipe\knc';
$PRODUCTRECIPEDIR = 'knc';
##########################################

%SACRIFICE_RECIPE_PER_BOM = ();
#BOM NAME  => ["HRI,MRV",...] (can be multiple HRI,MRV pairs)

&GetBinMatrixXMLForHRIAndMRV();

#foreach $Flexbom (sort { @{$SACRIFICE_RECIPE_PER_BOM{$b}} <=> @{$SACRIFICE_RECIPE_PER_BOM{$a}} } keys %SACRIFICE_RECIPE_PER_BOM ) 
#{
#     print "$Flexbom: @{$SACRIFICE_RECIPE_PER_BOM{$Flexbom}}\n"
#}
############################

my $filepath;
my $backupfilepath;
my $backupfilename;
my $file;
my $tempArray;

$timestamp = time;

$backupfilepathCorr = $PATH_TO_CORRELATION_DIR . "/_corr_backup_" . $timestamp;
$backupfilepathRecipe = $PATH_TO_RECIPE_DIR . "/_rec_backup_" . $timestamp;


mkdir($backupfilepathCorr) || die "Cannot create backup path for correlation files\n";
mkdir($backupfilepathRecipe) || die "Cannot create backup path for recipe files\n";

foreach $file (keys(%SACRIFICE_RECIPE_PER_BOM))
{
   $filepath = $PATH_TO_CORRELATION_DIR . "/" . $file . ".xml";
   
   if (-e $filepath)
   {
      $backupfilenameCorr = $backupfilepathCorr . "/$file" . ".xml";
   
      #making backup copy
      move($filepath, $backupfilenameCorr);
      print "Made backup of $file" . ".xml\n";
      
      open(INFILE,$backupfilenameCorr) || die "Cannot open $backupfilename\n";
      open(OUTFILE,">$filepath") || die "Cannot open $filepath\n";
      
      my @array = ();
      my $token;
      my $temp;
      my $MRV;
      my $HRI;
      my $MRV_HRI_PAIR;
      
      print "Processing BOM: $file. . .";
     
      
      while (<INFILE>)
      {
         #$orig_line = $_;
      
         if (/(.+Recipe=\"$PRODUCTRECIPEDIR\\)(.+$TP_RECIPE_BASENAME_KEY.*)\"\s*\//)
         #if (/$TP_RECIPE_BASENAME_KEY/)
         {
            $begOfLine = $1;
            $recipename = $2;  
            
            if (exists $RecipesToMod{$recipename})
            {
               $tempBOMArray = $RecipesToMod{$recipename};
               
               push(@$tempBOMArray, $file);
            }
            else
            {
               $RecipesToMod{$recipename} = [$file];
            }

	    $tempArray = $SACRIFICE_RECIPE_PER_BOM{$file};

            #print OUTFILE $orig_line; 

            foreach $MRV_HRI_PAIR (@$tempArray)
            {
		undef $HRI;
                undef $MRV;
		($HRI,$MRV) = split(/,/,$MRV_HRI_PAIR);
		
		if (!(defined $HRI) || !(defined $MRV))
		{
		   die "ERROR: HRI = $HRI or MRV = $MRV undefined for BOM = $BOM\n";
                }
		
		@tokens = split(/_/,$recipename);
		
		if (scalar(@tokens) == 0)
		{
		   print "ERROR: recipe name is blank?\n";
		   die;
		}
		
		print OUTFILE $begOfLine;
		
		print OUTFILE $tokens[0];
		print OUTFILE "_" . $HRI;
		
		for ($i = 1; $i < scalar(@tokens); $i++)
		{
		   print OUTFILE "_" . $tokens[$i];
		}
		
		print OUTFILE "\" />\n";
		
            }
         }
         else
         {
            print OUTFILE $_;
         }
         
         
      }
      
      
      close(OUTFILE);
      close(INFILE);
      
      print "done\n";
      
   }
   else
   {
      print "Warning: Could not find $file in $PATH_TO_CORRELATION_DIR\n";
   }
}


foreach $recipe (keys(%RecipesToMod))
{
   $recipe_path = $PATH_TO_RECIPE_DIR . "/" . $recipe . ".xml";
  
   if (-e $recipe_path)
   {
      $tempBOMArray = $RecipesToMod{$recipe};
      
      foreach $BOM (@$tempBOMArray)
      {
         $tempArray = $SACRIFICE_RECIPE_PER_BOM{$BOM};
         
         @tokens = split(/_/,$recipe);
		
         if (scalar(@tokens) == 0)
         {
            print "ERROR: recipe name is blank?\n";
            die;
         }
		

         foreach $MRV_HRI_PAIR (@$tempArray)
         {
            undef $HRI;
            undef $MRV;
            ($HRI,$MRV) = split(/,/,$MRV_HRI_PAIR);
            
            if (!(defined $HRI) || !(defined $MRV))
            {
               die "ERROR: HRI = $HRI or MRV = $MRV undefined for BOM = $BOM\n";
            }
            
            $newrecipename = $tokens[0] . "_" . $HRI;
            
            for ($i = 1; $i < scalar(@tokens); $i++)
            {
              $newrecipename .= "_" . $tokens[$i];
            }
            
            $newrecipepath = $PATH_TO_RECIPE_DIR . "/" . $newrecipename . ".xml";
	    
            if (!(-e $newrecipepath))
            {
                     
               open(INFILE, "$recipe_path") || die "Cannot open $recipe_path\n";
               open(OUTFILE, ">$newrecipepath") || die "Cannot open $newrecipepath\n";
               
               
               print "Processing Recipe: $recipe\n";
               while (<INFILE>)
               {
               
                  if (/<\/TestPrograms>/)
                  {
                      print OUTFILE $_;
                      
                      print OUTFILE "\n\n";
                      print OUTFILE "\t<LotAttributeGlobals>\n";
				print OUTFILE "\t\t<LotAttributeGlobal WSAttribute=\"$lotAttrNumber\" Name=\"$flexBOMUservar\" Type=\"STRING\" ENGValue=\"" . $MRV . "\" \/>\n";
  			        print OUTFILE "\t<\/LotAttributeGlobals>\n";
                      print OUTFILE "\n\n";
                  }
                  elsif (/<Globals>/)
                  {
                      print OUTFILE $_;
		      print OUTFILE "    <Global Name=\"$queryModeUservar\" Value=\"ENG\" Type=\"STRING\">\n";
		      print OUTFILE "    <\/Global>\n";                      
                  }
                  else
                  {
                      print OUTFILE $_;            
                  }
               }   
               
               close (INFILE);
               close (OUTFILE);
               

            }
            
         }
      
       }
      
   }
   else
   {
      print "Warning: Could not find $recipe in $PATH_TO_RECIPE_DIR\n";
   }
}

##Move all the original recipes to the backup folder since they are not needed anymore
foreach $recipe (keys(%RecipesToMod))
{
    $backupfilenameRecipe = $backupfilepathRecipe . "/" . $recipe . ".xml";
    $recipe_path = $PATH_TO_RECIPE_DIR . "/" . $recipe . ".xml";
    
    print "Moving $recipe to backup dir.\n";
    move($recipe_path, $backupfilenameRecipe);
}


print "Done Processing\n";


# Written by Lye Cheung Foo (PG TMM) on 10/07/2012
# Subroutine to automatically get HRI and MRV value and generate the recipe
sub GetBinMatrixXMLForHRIAndMRV
{
	my %HRI = ();
	my %MRV = ();
	my @BOMs = ();

	my $xs = XML::Simple->new(ForceArray => 1, KeyAttr => { }, KeepRoot   => 1, );
	my $BinMatrixRef  = $xs->XMLin("BinMatrix.xml");
	my $BOMGroups = $BinMatrixRef->{BinMatrix}->[0]->{BOMGroupTable}->[0]->{BOMGroup};
	foreach my $BOMGroup (@{$BOMGroups})
	{
		# To get BOMGroup name attributes
		#print "BOMGroup = $BOMGroup->{name}\n";

		# To get BOM values
		my $BOMListRef = $BOMGroup->{BOMList};
		foreach my $BOMList (@{$BOMListRef})
		{
			foreach my $BOM (@{$BOMList->{BOM}})
			{
				$BOM =~ s/^(\w+)\w\w$/$1/;
				#print "\tBOM = $BOM\n";
				push (@BOMs, $BOM); 
			}
		}
	
		# To get Attributes for flow 1 to optimize
		my $AttributeFlow1Ref = $BOMGroup->{ActiveFlowList}->[0]->{Flow}->[0]->{Attribute};
		foreach my $Attribute (@{$AttributeFlow1Ref})
		{
			if ($Attribute->{name} =~ /^HRI(\d+)/i)
			{
				my $Index = $1;
				$HRI{$Index} = $Attribute->{content};
				#print $xs->XMLout($Attribute);
				#print "\t\tAttribute $Attribute->{name} = $Attribute->{content}\n";
			}
			elsif  ($Attribute->{name} =~ /^MRV(\d+)/i)
			{
				my $Index = $1;
				$MRV{$Index} = $Attribute->{content};
			}
		}

		# Use to build more hash
		foreach my $BOM (@BOMs)
		{
			foreach my $Index (keys %HRI)
			{
				my $Item = "$HRI{$Index},$MRV{$Index}";
				push @{$SACRIFICE_RECIPE_PER_BOM{$BOM}}, $Item;
			}
		}

		%HRI = ();
		%MRV = ();
		@BOMs = ();
	}
}
