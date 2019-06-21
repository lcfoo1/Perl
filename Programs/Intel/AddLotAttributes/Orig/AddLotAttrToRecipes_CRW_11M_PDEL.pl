#!perl -w 
use File::Copy;


#### CONSTANTS ######
$flexBOMUservar = "SCVars.TP_FLEXBOMRECIPE";
$queryModeUservar = "_UserVars.QUERY_MODE";
$lotAttrNumber = 1473;
#######################

#### CONFIGURATION ######
$TP_RECIPE_BASENAME_KEY = "11M01";
$PATH_TO_CORRELATION_DIR = 'V:\hungle\Astra\CRW\11M01\Released\ASTRA\correlation\CSCMT\engr';
$PATH_TO_RECIPE_DIR = 'V:\hungle\Astra\CRW\11M01\Released\ASTRA\AstraSC\engr\CRW';
##########################################

#### FLEX-BOM CODES #####
my %SACRIFICE_RECIPE_PER_BOM = (

#Format:
#BOM NAME  => ["HRI,MRV",...] (can be multiple HRI,MRV pairs)

#CRW BGA 4+3+E CRW_DT_BGA
"YM4CRFFV" => ["CRW_BDT_1M,030003007FFF"],
"YM4CRFHV" => ["CRW_BDT_1M,030003007FFF"],
"YM4CRFJV" => ["CRW_BDT_1M,030003007FFF"],
"YM4CRFLV" => ["CRW_BDT_1M,030003007FFF"],
"YM4CRFNV" => ["CRW_BDT_1M,030003007FFF"],
"YM4CRFQV" => ["CRW_BDT_1M,030003007FFF"],
"YM4CRFSV" => ["CRW_BDT_1M,030003007FFF"],
"YM4CRFUV" => ["CRW_BDT_1M,030003007FFF"],
"YM4CRFVV" => ["CRW_BDT_1M,030003007FFF","CRW_BDT_42DM,00FF00FF7FFF"],
"YM4CRFYV" => ["CRW_BDT_1M,030003007FFF"],
"YM4CRFCV" => ["CRW_BDT_1M,030003007FFF"],

#CRW BGA 4+3+E CRW_MB1_BGA
"YM4CMFFV" => ["CRW_BMB_E11M,0B000B007FFF"],
"YM4CMFHV" => ["CRW_BMB_E11M,0B000B007FFF"],
"YM4CMFJV" => ["CRW_BMB_E11M,0B000B007FFF"],
"YM4CMFLV" => ["CRW_BMB_E11M,0B000B007FFF"],
"YM4CMFNV" => ["CRW_BMB_E11M,0B000B007FFF"],
"YM4CMFQV" => ["CRW_BMB_E11M,0B000B007FFF","CRW_BMB_23BM,1BFF1BFF7FFF"],
"YM4CMFSV" => ["CRW_BMB_E11M,0B000B007FFF"],
"YM4CMFUV" => ["CRW_BMB_E11M,0B000B007FFF"],
"YM4CMFVV" => ["CRW_BMB_E11M,0B000B007FFF","CRW_BMB_42DM,07FF07FF7FFF"],
"YM4CMFYV" => ["CRW_BMB_E11M,0B000B007FFF"],
"YM4CMFCV" => ["CRW_BMB_E11M,0B000B007FFF"],

#CRW PGA 4+3+E CRW_DT_PGA
"YH4CRFFV" => ["CRW_PDT_1M,030003007FFF"],
"YH4CRFHV" => ["CRW_PDT_1M,030003007FFF"],
"YH4CRFJV" => ["CRW_PDT_1M,030003007FFF"],
"YH4CRFLV" => ["CRW_PDT_1M,030003007FFF"],
"YH4CRFNV" => ["CRW_PDT_1M,030003007FFF"],
"YH4CRFQV" => ["CRW_PDT_1M,030003007FFF"],
"YH4CRFSV" => ["CRW_PDT_1M,030003007FFF"],
"YH4CRFUV" => ["CRW_PDT_1M,030003007FFF"],
"YH4CRFVV" => ["CRW_PDT_1M,030003007FFF","CRW_PDT_42DM,00FF00FF7FFF"],
"YH4CRFYV" => ["CRW_PDT_1M,030003007FFF"],
"YH4CRFCV" => ["CRW_PDT_1M,030003007FFF"],

#CRW PGA 4+3+E CRW_MB1_PGA
"YH4CMFFV" => ["CRW_PMB_E11M,0B000B007FFF"],
"YH4CMFHV" => ["CRW_PMB_E11M,0B000B007FFF"],
"YH4CMFJV" => ["CRW_PMB_E11M,0B000B007FFF"],
"YH4CMFLV" => ["CRW_PMB_E11M,0B000B007FFF"],
"YH4CMFNV" => ["CRW_PMB_E11M,0B000B007FFF"],
"YH4CMFQV" => ["CRW_PMB_E11M,0B000B007FFF","CRW_PMB_23BM,1BFF1BFF7FFF"],
"YH4CMFSV" => ["CRW_PMB_E11M,0B000B007FFF"],
"YH4CMFUV" => ["CRW_PMB_E11M,0B000B007FFF"],
"YH4CMFVV" => ["CRW_PMB_E11M,0B000B007FFF","CRW_PMB_42DM,07FF07FF7FFF"],
"YH4CMFYV" => ["CRW_PMB_E11M,0B000B007FFF"],
"YH4CMFCV" => ["CRW_PMB_E11M,0B000B007FFF"]



);
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
      
         if (/(.+Recipe=\"CRW\\)(.+$TP_RECIPE_BASENAME_KEY.*)\"\s*\//)
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