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
#	Modified 01/28/2003 by Sook Leng and Lye Cheung					#
#	Check if there is any duplication for x and y coordinate.                       #
#	If exist duplication, return "$File TRUE" statement , else return		#
#	"$File FALSE" statement to SACFTPToIPED.pl					#
#											#
#	NOTES										#
#       This program was written for Sook Leng	      					#
#											#
#########################################################################################

my ($File, $Fabrun) = @ARGV;
my $Dir = $File;
my $count = 0;
my $dup = "FALSE";
my @xloc=0;
my @yloc=0;
my $productid;
my $dataxy;
my @data;
my @KeyProd;
my @cdup;
my $fab = "FABRUN";
my $match ="MATCH";
my $Table = "<Lookup_Table";
my $devrv;

# Substitute each \ from dir with /
#$Dir =~ s/^(\/\w+\/\w+\/\w+\/\w+\/\w+\/\w+\/\w+\/\w+_\w+)\/\w+/$1/;

# Open a temp file for writing
#open(TEMP, ">$Dir/Temp") || die "Cant open temp file:- $!\n";
open (TEMP, ">$Fabrun");

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
			print "The File Already Inserted Previously\n";
			exit;
		}
		else
		{
			s/^(6_prdct_)(\w+)/6_comnt_origfabid_$Fabrun\n$1$2/;
			$productid = $2;
			print "6_comnt_origfabid_$Fabrun Successfully Inserted\n";
		}
	}
	
	if (/^6_devrv_(\w+)/)
	{
		$devrv = $1;
	}

	s/^(3_xloc_)(\S+)/$2 < 100 ? $1 . ($2 + 256) : $1 . $2/e;
	print TEMP $_;
	
	#Checking for the sequence duplicate
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

# To check the duplicate x-y coordinate
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
			    push(@cdup,$dataxy);
			}
				
		}
	}
}

# To combine all the duplicate coordinate into a line of string
$dataxy=join (';',@cdup);
chomp ($dataxy);

#To clear all the duplicate coordinate array
for (0..$#cdup)
{
	pop (@cdup);
}

# To get the manimum and maximum x-coordinate
my @xsort = sort {$a <=> $b} @xloc;
my $xmin = $xsort[1]; 
my $xmax = $xsort[$#xsort];

# To get the minimum and maximum y-coordinate
my @ysort = sort {$a <=> $b} @yloc;
my $ymin = $ysort[1]; 
my $ymax = $ysort[$#ysort];
my $total1 = $#ysort + 1;

#To clear all the arrays
for (0..$#yloc)
{
    pop (@yloc);
    pop (@xloc);
}

# Check the Fabrun validate
my @cFabrun = split(/\./,$Fabrun);
my $lenFabrun = length ($cFabrun[0]);

#To get the truth table from file name Truth_Table.txt and put into hash
open(TABLE, $Table);
while (<TABLE>)
{
	chomp;
	@data = split (/\s+/,$_);
    	$Product{$data[0]} = [$data[1], $data[2], $data[3], $data[4], $data[5]];
}
close TABLE;

print "$productid, $xmin, $xmax, $ymin, $ymax\n";

# Check the xmin, xmax, ymin, ymax, Fabrun
foreach $Key (keys %Product)
{	
	my $newproductid = $productid."_".$devrv;
	if ($newproductid eq $Key)
	{
		# To check for xmin, xmax, ymin, ymax
		if (($xmin != $Product{$Key}[0]) || ($xmax != $Product{$Key}[1]) || ($ymin != $Product{$Key}[2]) || ($ymax != $Product{$Key}[3]))
		{
			$match = "NOT_MATCH";		
		}
		
		# To check for Fabrun correctly been key-in
		if ($lenFabrun ne $Product{$Key}[4])
		{
			$fab = "WRONG_FABRUN";
		}
	}
}

#To check for duplicate
	if (($dup eq "TRUE") && ($match eq "MATCH") && ($fab eq "FABRUN") && ($File ne "$Dir\/Temp"))
	{
		print "$File MATCH FABRUN TRUE $dataxy\n";
		&RemoveTemp;
	}
	elsif (($dup eq "FALSE") && ($match eq "NOT_MATCH") && ($fab eq  "FABRUN") && ($File ne "$Dir\/Temp"))
	{
		print "$File NOT_MATCH FABRUN FALSE\n";
		&RemoveTemp;
	}
	elsif (($dup eq "FALSE") && ($match eq "MATCH") && ($fab eq "WRONG_FABRUN") && ($File ne "$Dir\/Temp"))
	{
		print "$File MATCH WRONG_FABRUN FALSE\n";
		&RemoveTemp;
	}
	elsif (($dup eq "TRUE") && ($match eq "NOT_MATCH") && ($fab eq "FABRUN") && ($File ne "$Dir\/Temp"))
	{
		print "$File NOT_MATCH FABRUN TRUE $dataxy\n";
		&RemoveTemp;
	}
	elsif (($dup eq "TRUE") && ($match eq "MATCH") && ($fab eq "WRONG_FABRUN") && ($File ne "$Dir\/Temp"))
	{
		print "$File MATCH WRONG_FABRUN TRUE $dataxy\n";
		&RemoveTemp;
	}
	elsif (($dup eq "FALSE") && ($match eq "NOT_MATCH") && ($fab eq "WRONG_FABRUN") && ($File ne "$Dir\/Temp"))
	{
		print "$File NOT_MATCH WRONG_FABRUN FALSE\n";
		&RemoveTemp;
	}
	elsif (($dup eq "TRUE") && ($match eq "NOT_MATCH") && ($fab eq "WRONG_FABRUN") && ($File ne "$Dir\/Temp"))
	{
		print "$File NOT_MATCH WRONG_FABRUN TRUE $dataxy\n";
		&RemoveTemp;
	}
	elsif ($File eq "$Dir\/Temp")
	{
		print "$File TEMP TEMP TEMP\n";
	}
	else
	{
		print "$File MATCH FABRUN FALSE\n";    
		&RemoveTemp;
	}

# Now rename the temp file to original ituff file
sub RemoveTemp 
{
#	qx/mv -f $Dir\/Temp $File/;
	print "$total1 units\n";
}
