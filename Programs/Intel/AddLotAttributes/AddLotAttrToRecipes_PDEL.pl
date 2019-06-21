perl -w 
use File::Copy;

#generate lfd recipe
#### CONSTANTS ######
$flexBOMUservar = "CTSCVars.TP_FLEXBOMRECIPE";
$lotAttrNumber = 1473;
#######################

#### CONFIGURATION ######
$TP_RECIPE_BASENAME_KEY = "LFD";
$PATH_TO_CORRELATION_DIR = "Q:/nhm.pde.180/vchee/LFD_AVID/correlation";
$PATH_TO_RECIPE_DIR = "Q:/nhm.pde.180/vchee/LFD_AVID/recipe/lfd";
##########################################

#### FLEX-BOM CODES #####
my %SACRIFICE_RECIPE_PER_BOM = (

#BOM NAME   #SSPEC (can be multiple SSPEC numbers separated by commas)

#"EH4MDHAV" => ["0000", "0007"],  #HP
"EH4MDHBV" => ["0000", "0007"],  #MP
"EH4MDHCV" => ["0000", "0007"],  #MP
"EH4MDHEV" => ["0000", "0007"],  #LF
"EH4MDHFV" => ["0000", "0007"],  #LP
"EH4MDHQV" => ["0000", "0007"],  #LV



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
      my $sspec;
      
      print "Processing BOM: $file. . .";
      
      
      while (<INFILE>)
      {
         #$orig_line = $_;
      
         if (/(.+Recipe=\"lfd\\)(.+$TP_RECIPE_BASENAME_KEY.*)\"\s*\//)
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

            foreach $sspec (@$tempArray)
            {
		@tokens = split(/_/,$recipename);
		
		if (scalar(@tokens) == 0)
		{
		   print "ERROR: recipe name is blank?\n";
		   die;
		}
		
		print OUTFILE $begOfLine;
		
		print OUTFILE $tokens[0];
		print OUTFILE "_" . $sspec;
		
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
      $backupfilenameRecipe = $backupfilepathRecipe . "/" . $recipe . ".xml";
      
      move($recipe_path, $backupfilenameRecipe);
      
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
		

         foreach $sspec (@$tempArray)
         {
            $newrecipename = $tokens[0] . "_" . $sspec;
            
            for ($i = 1; $i < scalar(@tokens); $i++)
            {
              $newrecipename .= "_" . $tokens[$i];
            }
            
            $newrecipepath = $PATH_TO_RECIPE_DIR . "/" . $newrecipename . ".xml";
            
            if (!(-e $newrecipepath))
            {
                     
               open(INFILE, "$backupfilenameRecipe") || die "Cannot open $backupfilenameRecipe\n";
               open(OUTFILE, ">$newrecipepath") || die "Cannot open $newrecipepath\n";
               
               
               print "Processing Recipe: $recipe\n";
               while (<INFILE>)
               {
               
                  if (/<\/TestPrograms>/)
                  {
                      print OUTFILE $_;
                      
                      print OUTFILE "\n\n";
                      print OUTFILE "\t<LotAttributeGlobals>\n";
				print OUTFILE "\t\t<LotAttributeGlobal WSAttribute=\"$lotAttrNumber\" Name=\"$flexBOMUservar\" Type=\"STRING\" ENGValue=\"" . $sspec . "\" \/>\n";
  			        print OUTFILE "\t<\/LotAttributeGlobals>\n";
                      print OUTFILE "\n\n";
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
      
