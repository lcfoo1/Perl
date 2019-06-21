#!/bin/perl -w

#########################################################################################
#											#
#	Justin Devanandan Allegakoen		PCO PDQRE Datamation Group		#
#	08/10/2002				Penang					#
#											#
#	Program to insert fabrun attribute to ituff files which is 1 day old from       #
#       /lopte/intel/hp94k/sort/aries/data/ituff.  					#
#											#
#	Modified 10/02/2002 by Sook Leng and Justin					#
#	Check if 6_comnt_origfabid_$Fabrun found from current ituff Summary then exist  #
#	the updatefile.pl else insert the 6_comnt_origfabid_$Fabrun before 6_prdct_\w+  #
#	Validate Ituff summary data to avoid duplicate Fabrun insertion to Ituff        #
#	Summary file. 									#			
#											#
#	Modified 01/28/2003 Lye Cheung							#
#	Check if there is any duplication for x and y coordinate.                       #
#	If exist duplication, return boolean TRUE, else return boolean FALSE		#
# 	to SACFTPToIPED.pl								#
#											#
#	Modified 04/10/2003 by Lye Cheung						#
#	Check if there is any mismatch coordinate x-y min and max coordinate based on 	#
#	the data at Lookup_Table. If exist mismatch coordinate, return boolean NOT_MATCH#
#	else return MATCH to SACFTPToIPED.pl						#
#											#
#	Modified 04/11/2003 by Lye Cheung						#
#	Check if there is any wrongly inserted Fabrun # based on the data at 		#
#	Lookup_Table and must end with 1 or 2 integer if there is dot or no integer if 	#
#	there is no dot. If exist wrongly inserted Fabrun #, return boolean FabrunBad	#		
#	else return FabrunOK to SACFTPToIPED.pl						#
#											#
#	Modified 05/27/2003 by Lye Cheung						#
#	Check test program loaded to test the wafer is correct test program name	#
#	It will get the information from the Lookup_Table and trigger PE if the test	#
#	program name is wrong or different where it will return boolean ProgNotMatch	#
#	else return ProgMatch to SACFTPToIPED.pl					#
#											#
#											#
#	NOTES										#
#       This program was written for Sook Leng	      					#
#											#
#########################################################################################

my ($File, $Fabrun) = @ARGV;
my $Dir = $File;
my $count = 0;
my $dup = "FALSE";
my $fab = "FABRUN";
my $match ="MATCH";
my $ProgramMatch = "ProgMatch";
my $Table = "<Lookup_Table";
my ($productid, $dataxy, $WWID, $StartDate, $Time, $EndDate, $devrv, $progname);
my @xloc=0;
my @yloc=0;
my @data;
my @KeyProd;
my @cdup;

# Substitute each \ from dir with /
$Dir =~ s/^(\/\w+\/\w+\/\w+\/\w+\/\w+\/\w+\/\w+\/\w+_\w+)\/\w+/$1/;

# Open a temp file for writing
open(TEMP, ">$Dir/Temp") || die "Cant open temp file:- $!\n";

# Open the original file for reading
open(FILE, $File) || die "$File:- $!\n";
while(<FILE>)
{
	if(/^6_lotid_\w+/)
	{
		print TEMP $_;
		$_ = <FILE>;

		if(/^6_comnt_origfabid/)
		{
			print "6_comnt_origfabid_$Fabrun Have Been Inserted Before\n";
			print "$File Already Inserted Previuosly By The UploadScript\n";
			close FILE;
			close TEMP;
			unlink "$Dir/Temp";
			exit;
		}
		else
		{
			s/^(6_prdct_)(\w+)/6_comnt_origfabid_$Fabrun\n$1$2/;
			$productid = $2;
			print "6_comnt_origfabid_$Fabrun Successfully Inserted\n";
		}
	}

	# Get the device stepping	
	$devrv = $1 if (/^6_devrv_(\w+)/);
	
	# Get the program name
	$progname = $1 if (/^6_prgnm_(\S+)/);

	# Get the operator WWID
	$WWID = $1 if (/^4_oprtr_(\d+)/);

	# Get start date and time
	if (/^4_begindt_(\d{8})(\d{6})/)
	{
		$StartDate = $1;
		$Time = $2;
	}
		
	# Get the end date
	$EndDate = $1 if (/^4_enddate_(\d{8})\d{6}/);
	

	# To add 256 to x-coordinate if x less than 256
	s/^(3_xloc_)(\S+)/$2 < 100 ? $1 . ($2 + 256) : $1 . $2/e;
	print TEMP $_;
	
	# Checking for the sequence duplicate
	if (/^3_xloc_(\w+)/g)
    	{       
		push (@xloc, $1);
	}

	if (/^3_yloc_(\w+)/g)
	{  
		push (@yloc, $1);
	}
	
}

close FILE;
close TEMP;

#####################################################################
##### This part is to check the validation of the ITUFF summary #####
#####################################################################

# Check for the duplication x-y coordinate
for (my $i=1; $i<=$#xloc; $i++)
{
	for (my $j=1; $j<=$#xloc; $j++)
	{
		if ($i!=$j)
		{
			if (($yloc[$i] == $yloc[$j]) && ($xloc[$i] == $xloc[$j]))
			{	
			    $dup = "TRUE";
			    $dataxy = "$xloc[$j],$yloc[$j]";
			    chomp ($dataxy);
			    push(@cdup,$dataxy);
			}
				
		}
	}
}

# Store 600 x-y duplication coordinate
my @newcdup;
if ($#cdup <600)
{
	@newcdup = @cdup;
}
else
{
	@newcdup = @cdup [0..599];
}

# Combine all the duplicate coordinate into a line of string
$dataxy=join (';',@newcdup);
chomp ($dataxy);

#To clear all the duplicate coordinate array
for (0..$#newcdup)
{
	pop (@newcdup);
}

# To get the manimum and maximum x-coordinate
my @xsort = sort {$a <=> $b} @xloc;
my $xmin = $xsort[1]; 
my $xmax = $xsort[$#xsort];

# To get the minimum and maximum y-coordinate
my @ysort = sort {$a <=> $b} @yloc;
my $ymin = $ysort[1]; 
my $ymax = $ysort[$#ysort];

# To combine the display the data x-y min and max
my $ITUFF_minmax = "x-min:${xmin},x-max:${xmax},y-min:${ymin},y-max:${ymax}";

# To clear all the arrays
for (0..$#yloc)
{
    pop (@yloc);
    pop (@xloc);
}

# Check the Fabrun validation
my $InsFabrun = "FabrunOK";
my ($LengthFabrun, $intnumber) = split(/\./,$Fabrun);
my $lenFabrun = length ($LengthFabrun);
if ($Fabrun =~ /\./)
{
	$InsFabrun = "FabrunBad" if ($intnumber !~ /^\d{1,2}$/);
}

#To get the truth table from file name Lookup_Table and put into hash
open(TABLE, $Table);
while (<TABLE>)
{
	chomp;
	@data = split (/\s+/,$_);
    	$Product{$data[0]} = [$data[1], $data[2], $data[3], $data[4], $data[5], $data[6]];
}
close TABLE;


# Check the xmin, xmax, ymin, ymax, Fabrun
foreach $Key (keys %Product)
{	
	my $newproductid = $productid."_".$devrv;
	if ($newproductid eq $Key)
	{
		
		# To check for xmin, xmax, ymin, ymax
		if (($xmin != $Product{$Key}[0]) || ($xmax != $Product{$Key}[1]) || ($ymin != $Product{$Key}[2]) || ($ymax != $Product{$Key}[3]))
		{
			$actual_minmax = "x-min:${Product{$Key}[0]},x-max:${Product{$Key}[1]},y-min:${Product{$Key}[2]},y-max:${Product{$Key}[3]}";
			$match = "NOT_MATCH";		
		}
		
		# To check for Fabrun correctly been key-in
		if (($lenFabrun ne $Product{$Key}[4]) || ($InsFabrun eq "FabrunBad"))
		{
			$fab = "WRONG_FABRUN";
		}
	
		# To check for correct program being loaded for sorting
		if ($progname ne $Product{$Key}[5])
		{
			$ProgramMatch = "ProgNotMatch";
		}

	}
}

#To check for duplicate, mismatch x-y min and max coordinate, wrongly inserted Fabrun
	if (($dup eq "TRUE") && ($match eq "MATCH") && ($fab eq "FABRUN") && ($ProgramMatch eq "ProgMatch"))
	{
		print "$File ProgMatch MATCH FABRUN Temp Temp TRUE $dataxy $WWID $StartDate $Time $EndDate\n";
		&RemoveTemp;
	}
	elsif (($dup eq "FALSE") && ($match eq "NOT_MATCH") && ($fab eq  "FABRUN") && ($ProgramMatch eq "ProgMatch"))
	{
		print "$File ProgMatch NOT_MATCH FABRUN $actual_minmax $ITUFF_minmax FALSE\n";
		&RemoveTemp;
	}
	elsif (($dup eq "FALSE") && ($match eq "MATCH") && ($fab eq "WRONG_FABRUN") && ($ProgramMatch eq "ProgMatch"))
	{
		print "$File ProgMatch MATCH WRONG_FABRUN Temp Temp FALSE\n";
		&RemoveTemp;
	}
	elsif (($dup eq "TRUE") && ($match eq "NOT_MATCH") && ($fab eq "FABRUN") && ($ProgramMatch eq "ProgMatch"))
	{
		print "$File ProgMatch NOT_MATCH FABRUN $actual_minmax $ITUFF_minmax TRUE $dataxy $WWID $StartDate $Time $EndDate\n";
		&RemoveTemp;
	} 
	elsif (($dup eq "TRUE") && ($match eq "MATCH") && ($fab eq "WRONG_FABRUN") && ($ProgramMatch eq "ProgMatch"))
	{
		print "$File ProgMatch MATCH WRONG_FABRUN Temp Temp TRUE $dataxy $WWID $StartDate $Time $EndDate\n";
		&RemoveTemp;
	}
	elsif (($dup eq "FALSE") && ($match eq "NOT_MATCH") && ($fab eq "WRONG_FABRUN") && ($ProgramMatch eq "ProgMatch"))
	{
		print "$File ProgMatch NOT_MATCH WRONG_FABRUN $actual_minmax $ITUFF_minmax FALSE\n";
		&RemoveTemp;
	}
	elsif (($dup eq "TRUE") && ($match eq "NOT_MATCH") && ($fab eq "WRONG_FABRUN") && ($ProgramMatch eq "ProgMatch"))
	{
		print "$File ProgMatch NOT_MATCH WRONG_FABRUN $actual_minmax $ITUFF_minmax TRUE $dataxy $WWID $StartDate $Time $EndDate\n";
		&RemoveTemp;
	}
	elsif (($dup eq "TRUE") && ($match eq "MATCH") && ($fab eq "FABRUN") && ($ProgramMatch eq "ProgNotMatch"))
	{
		print "$File ProgNotMatch MATCH FABRUN Temp Temp TRUE $dataxy $WWID $StartDate $Time $EndDate\n";
		&RemoveTemp;
	}
	elsif (($dup eq "FALSE") && ($match eq "NOT_MATCH") && ($fab eq  "FABRUN") && ($ProgramMatch eq "ProgNotMatch"))
	{
		print "$File ProgNotMatch NOT_MATCH FABRUN $actual_minmax $ITUFF_minmax FALSE\n";
		&RemoveTemp;
	}
	elsif (($dup eq "FALSE") && ($match eq "MATCH") && ($fab eq "WRONG_FABRUN") && ($ProgramMatch eq "ProgNotMatch"))
	{
		print "$File ProgNotMatch MATCH WRONG_FABRUN Temp Temp FALSE\n";
		&RemoveTemp;
	}
	elsif (($dup eq "TRUE") && ($match eq "NOT_MATCH") && ($fab eq "FABRUN") && ($ProgramMatch eq "ProgNotMatch"))
	{
		print "$File ProgNotMatch NOT_MATCH FABRUN $actual_minmax $ITUFF_minmax TRUE $dataxy $WWID $StartDate $Time $EndDate\n";
		&RemoveTemp;
	}
	elsif (($dup eq "TRUE") && ($match eq "MATCH") && ($fab eq "WRONG_FABRUN") && ($ProgramMatch eq "ProgNotMatch"))
	{
		print "$File ProgNotMatch MATCH WRONG_FABRUN Temp Temp TRUE $dataxy $WWID $StartDate $Time $EndDate\n";
		&RemoveTemp;
	}
	elsif (($dup eq "FALSE") && ($match eq "NOT_MATCH") && ($fab eq "WRONG_FABRUN") && ($ProgramMatch eq "ProgNotMatch"))
	{
		print "$File ProgNotMatch NOT_MATCH WRONG_FABRUN $actual_minmax $ITUFF_minmax FALSE\n";
		&RemoveTemp;
	}
	elsif (($dup eq "TRUE") && ($match eq "NOT_MATCH") && ($fab eq "WRONG_FABRUN") && ($ProgramMatch eq "ProgNotMatch"))
	{
		print "$File ProgNotMatch NOT_MATCH WRONG_FABRUN $actual_minmax $ITUFF_minmax TRUE $dataxy $WWID $StartDate $Time $EndDate\n";
		&RemoveTemp;
	}
	
	elsif (($dup eq "FALSE") && ($match eq "MATCH") && ($fab eq "FABRUN") && ($ProgramMatch eq "ProgNotMatch"))
	{
		print "$File ProgNotMatch MATCH FABRUN Temp Temp FALSE\n";
		&RemoveTemp;
	}
	else
	{
		print "$File ProgMatch MATCH FABRUN Temp Temp FALSE\n";    
		&RemoveTemp;
	}

# Now rename the temp file to original ituff file
sub RemoveTemp 
{
	qx/mv -f $Dir\/Temp $File/;
}
