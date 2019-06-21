#########################################################################################
#											#
#	Foo Lye Cheung									#
#	03/24/2003									#
#	This script is going to check for the files that are 1 day old from		#
#	Production directory (/lopte/data/summary/t3) with Aries directory		#
#	(/lopte/intel/hp94k/sort/aries/data/ituff). If a lot with certain quantity 	#
#	wafers at both directory are different, PE will be triggered by email.		#
#	If the lots at both directory are different, then PE will be triggered by email.#
#											#
#	Notes:										#
#	The script required common.pl, findprod.pl, findaries.pl and error.pl		#
#											#
#########################################################################################


use warnings;
use strict;
use Win32::OLE;
use Net::Telnet;

require "C:/Perl/Programs/Common.pl";

my %Product;
my %Aries;
my $RemoteDir = "/lopte/home1/slow/Datamation";
my $Prompt = "slow";
my $Pwd = '8@X$IBr'^'K,7SxpA';
       
# Get connection to t3hp94k5
my $telnet = new Net::Telnet (Timeout => 3600, Prompt=> '/[%#>:)] $/');
$telnet->open('t3hp94k5.png.intel.com');
$telnet->login('slow', $Pwd);
print "Connected to t3hp94k5\n"; 
my $Now = localtime(time);

# Clear out the prompt that prints itself 
$telnet->cmd("xterm");
$telnet->prompt("/[%#>:)] $/");
$telnet->prompt("/$Prompt\$/");
$telnet->cmd("set prompt = '$Prompt'");

# Run the program to get the files from production directory
$telnet->cmd("cd $RemoteDir") || die "Cannot cd to $RemoteDir\n";
my @ProductionFiles = $telnet->cmd("perl findprod.pl"); 
$ProductionFiles[0] =~ s/^\s+//;

# To group the same lot with different wafer for the production directory	       	
foreach my $File (@ProductionFiles)
{
	chomp $File;
	push (@{$Product{$1}}, $2) if $File =~ s/^\/\w+\/\w+\/\w+\/\w+\/(\w+_\d+)\/(W\w+)/$1$2/;
}	

# Run the program to get the files from aries directory
my @ARIESFiles = $telnet->cmd("perl findaries.pl"); 
$ARIESFiles[0] =~ s/^\s+//;

# To group the same lot with different wafer for the aries directory	       	
foreach my $File (@ARIESFiles)
{
	chomp $File;
	push (@{$Aries{$1}}, $2) if $File =~ s/^\/\w+\/\w+\/\w+\/\w+\/\w+\/\w+\/\w+\/(\w+[A..Z]_\d+)\/(W\w+)/$1$2/;
}

# Check if the quantity wafers at the Production and Aries directory for a lot is different amount, trigger the PE with email
foreach my $Key (keys %Aries)
{
    	my @LotProduct = keys %Product;
    	for my $i (0..$#LotProduct)
    	{	
		if ($LotProduct[$i] eq $Key)
		{
			my $aries=join('; ',@{$Aries{$Key}}[0..$#{$Aries{$Key}}]);
			my $prod=join('; ',@{$Product{$Key}}[0..$#{$Product{$Key}}]);

			if (($aries cmp $prod) == 0)
			{
				print "Same quantity for lot $Key\n";
	  		}
	    		else
	    		{
				print "Wafers mismatch - Lot#: ${Key}\n";
								
				#my $To = 'sook.leng.low@intel.com; kok.wai.lai@intel.com; lye.cheung.foo@intel.com; lee.pin.see@intel.com; kai.hiong.lee@intel.com; bee.lean.neoh@intel.com';
				my $To = 'lye.cheung.foo@intel.com; tong.ho.tee@intel.com; chun.hou.loo@intel.com; yuen.wah.lim@intel.com ';  
				#my $To = 'lye.cheung.foo@intel.com';
				my $Subject = "Wafer mismatch at Production directory and Aries directory at Lot#: ${Key}"; 
	        		my $Body = 
					"
WAFERS PRODUCTION DIRECTORY at Lot#: ${Key}
---------------------------------------------------------
$prod
	

WAFERS ARIES DIRECTORY at Lot#     : ${Key}
---------------------------------------------------------
$aries
		

				
		                  	 * * * PLEASE DO NOT REPLY TO THIS MAIL * * *";
					 
				&SendMail($To, '', $Subject, $Body);
				print "Mail sent for wafer mismatch\n";

				# Create a log file at /lopte/home1/slow/Datamation/ERROR.log
				$telnet->cmd("perl error.pl $Key");
	 		}
		}
	}
}

no warnings;
my @LotProduct = sort (keys %Product);
my @LotAries = sort (keys %Aries);
my $ChkLot = "FALSE";

# Check if the quantity lots at the Production and Aries directory are different, trigger the PE with email
for my $i (0..$#LotProduct)
{
	if ($LotProduct[$i] ne $LotAries[$i])
	{	
		$ChkLot = "TRUE";
		
	}
}    

if ($ChkLot eq "TRUE")
{
		#my $To = 'sook.leng.low@intel.com; kok.wai.lai@intel.com; lye.cheung.foo@intel.com; lee.pin.see@intel.com; kai.hiong.lee@intel.com; bee.lean.neoh@intel.com';
		my $To = 'lye.cheung.foo@intel.com; tong.ho.tee@intel.com; chun.hou.loo@intel.com; yuen.wah.lim@intel.com ';  
		#my $To = 'lye.cheung.foo@intel.com';
		my $Subject = "Checklist number of Lots at Production directory and Aries directory for 1 day old from $Now"; 
	        my $Body = 
			"
Checklist number of Lots at Production directory and Aries directory for 1 day old from $Now
		
			PRODUCTION DIRECTORY
			---------------------------------------------------------
			Lot at Production directory: 
			$LotProduct[0]
			$LotProduct[1]
			$LotProduct[2]
			$LotProduct[3]
			$LotProduct[4]
			$LotProduct[5]
			$LotProduct[6]
			$LotProduct[7]
			$LotProduct[8]
			$LotProduct[9]
			$LotProduct[10]
			$LotProduct[11]
			$LotProduct[12]
			$LotProduct[13]


			ARIES DIRECTORY
			---------------------------------------------------------
			Lot at Aries directory:
			$LotAries[0]
			$LotAries[1]
			$LotAries[2]
			$LotAries[3]
			$LotAries[4]
			$LotAries[5]
			$LotAries[6]
			$LotAries[7]
			$LotAries[8]
			$LotAries[9]
			$LotAries[10]
			$LotAries[11]

*** NOTE: There are more lots in the Production directory due to some of the lots are still sorting
	                  	
						 * * * PLEASE DO NOT REPLY TO THIS MAIL * * *";
				 
			&SendMail($To, '', $Subject, $Body);
			print "Checklist for yesterday lots on Production and Aries directory\n";
}

