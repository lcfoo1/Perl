#!/usr/local/bin/perl -w

#################################################################################
#										#
#	Foo Lye Cheung					NCO Automation PDQRE	#
#	29 June 2004								#
#										#
#	Auto Fusing Check System						#
#										#
#################################################################################

use File::Find;

my (%LotLocnDev, %DevicePEList) = ();
my ($Bin2BadNNoFuse, $Bin1BadNNoFuse) = (); 
###my @LotDir = ();
#my $ProdDir = '/db1/s9k/prod';
###my $ProdDir = '/engr/restore/Database.2004_22';
#my @LotDir = ('/db1/s9k/prod/L4240312_6102');
my @LotDir = ('/db1/s9k/prod/L4LCFOO1_6152');
#my @LotDir = ('/db1/s9k/prod/L4240312_6102');
#my @LotDir = ('/engr/restore/Database.2004_22/L4120448T_6102');

&GetProdTable();
###finddepth(\&GetiTUFFDir, $ProdDir);
&iTUFFDir(@LotDir);

# Get the device and PEs emails list from lookup table
sub GetProdTable
{
	my $LookupTable = "/user/home1/prodeng/lfoo1/fuse/prod.tbl";
	open (PRODDEV, $LookupTable) or die "Cann't open $LookupTable : $!\n";
	while (<PRODDEV>)
	{
		my ($Device, $PEEmails) = split (/\,/, $_, 2);
		$DevicePEList{$Device} = $PEEmails;
	}
	close PRODDEV;

}

# Get all iTUFF Y summary from directory /db1/s9k/prod
sub GetiTUFFDir
{
	local ($^W) = 0;
	next unless $File::Find::name =~ /(\S+)\/\dY$/o;
	push (@LotDir, $1);
}

# Screening the lot directory
sub iTUFFDir
{
	foreach my $iTUFFDir (@LotDir)
	{
		&CheckiTUFF($iTUFFDir);
		($Bin2BadNNoFuse, $Bin1BadNNoFuse) = ('', '', '', '');
	}
}

# Check the ituff summary from the lookup table before processing
sub CheckiTUFF
{
	my $iTUFFDir = shift;
	my ($LastiTUFFFlag, $DevFoundFlag) = (0, 0);
	my ($Lot, $Locn, $Summary, $Device, $TmpTo) = ();

	chdir $iTUFFDir or die "Cann't open $iTUFFDir : $!\n";

	foreach my $iTUFF (<*>)
	{
		$LastiTUFFFlag = 1 if $iTUFF =~ /^\dY$/o;
		next unless $iTUFF =~ /^\d[ABCDE]$/;
		print "Directory: $iTUFFDir with ituff: $iTUFF\n";
		open (ITUFF, $iTUFF) or die "Cann't open $iTUFF : $!\n";
		while (<ITUFF>)
		{
			$Lot = $1  if /^6_lotid_(\w+)/o;
			$Device = $1 if /^6_prdct_(\w+)/o;
			$Locn = $1 if /^5_lcode_(\d+)/o;	
			
			if (/^4_smrynam_(\w+)/o)	 
			{
				$Summary = $1;

				foreach my $Dev (keys %DevicePEList)
				{
					if ($Dev eq $Device)
					{
						chomp($TmpTo = $DevicePEList{$Dev});
						$DeviceFoundFlag = 1; 
						last;
					}
				}
			}
		}
		close ITUFF;

		if ($DeviceFoundFlag)
		{
			$Bin2BadNNoFuse .= "Summary: $Summary\n";
			$Bin1BadNNoFuse .= "Summary: $Summary\n";
			&CheckFuse($Summary);
		}
	}

	# Ensure to send email at the last summary of the lot
	if ($LastiTUFFFlag)
	{
  		if (($Bin2BadNNoFuse !~ /^Summary:\s[12345][ABCDE]$/) || ($Bin1BadNNoFuse !~ /^Summary:\s[12345][ABCDE]$/))
        	{
                	my $Subject = "Auto Checking Fuse System for $Lot and $Locn\n";
                  	my $Body = "Lot#: $Lot\nLocation: $Locn\nBin 2:\n${Bin2BadNNoFuse}\nBin 1:\n${Bin1BadNNoFuse}\n";
                       	&SendMail($Subject, $Body, $TmpTo);
			print "$Body\n";
               	}
	}

}

# Check bin 1 and bin 2 fusing and bad faildata units
sub CheckFuse
{
	my ($Summary) = shift;
	my ($WrongBin1Fuse, $WrongBin2Fuse, $PrtName, $ComntToken, $FailDataToken, $CountBin2NoFuse, $CountBin1NoFuse, $CountBadBin2, $CountBadBin1) = ("\n", "\n", '', '', '', 0, 0, 0, 0);
	
	open (ITUFF, $Summary) or die "Cann't open $Summary : $!\n";
	while (<ITUFF>)
	{
		s/ //g;
		$PrtName = $1 if /^3_prtnm_(\d+)/;

		if (/^2_pttrn_FUSE_DATA$/o)
		{
			$_ = <ITUFF>;
			$ComntToken = $1 if (/^2_comnt_\w{4}(\w{4})/o);  		
			$FailDataToken = $1 if (/^2_faildata_\w{4}(\w{4})/o);
		}

		# Checking hard bin 2 for error at comnt and faildata token
		if (/^2_curibin_2$/o)
		{ 
			if (($ComntToken eq "UUUU") && ($FailDataToken eq ""))
			{
				$Bin2BadNNoFuse .= "Unit $PrtName: Not Fuse (Comnt=UUUU and no Faildata)\n";
				$CountBin2NoFuse++;
			}
			# Tester shown bin 2 fusing but being fuse as bin 1
			if ($FailDataToken eq "U11U")
			{
				$WrongBin2Fuse .= "Unit $PrtName: Pass Bin 2 but fuse Bin 1 (Faildata = U11U)\n";
				$CountBadBin2++;
			}
			$ComntToken = '';
                        $FailDataToken = '';
		}

		# Checking hard bin 1 for error at comnt and faildata token
		if (/^2_curibin_1$/o)
		{ 
			if (($ComntToken eq "UUUU") && ($FailDataToken eq ""))
			{
				$Bin1BadNNoFuse .= "Unit $PrtName: $FailDataToken :: Not Fuse (Comnt=UUUU and no Faildata)\n";
				$CountBin1NoFuse++;
			}
			# Tester shown bin 1 fusing but being fuse as bin 2
			if ($FailDataToken eq "1UU1")
			{
				$WrongBin1Fuse .= "Unit $PrtName: Pass Bin 1 but fuse Bin 2 (Faildata = 1UU1)\n";
				$CountBadBin1++;
			}
			$ComntToken = '';
                        $FailDataToken = '';
		}

	}
	close ITUFF;

	$Bin2BadNNoFuse .= "Total Bin 2 (UUUU): ${CountBin2NoFuse}${WrongBin2Fuse}Total Bin 2 (U11U): $CountBadBin2\n";
	$Bin1BadNNoFuse .= "Total Bin 1 (UUUU): ${CountBin1NoFuse}${WrongBin1Fuse}Total Bin 1 (1UU1): $CountBadBin1\n";

}


# Send mail to the PEs from the email list
sub SendMail
{
        my ($TmpSubject, $Body, $TmpTo) = @_; 
        my $To = "To: $TmpTo\n";
        my $From = "From: t3admin6\@png.intel.com\n";
        my $Subject = "Subject: $TmpSubject\n";
        my $Content = <<"MAILBODY";
$Body

        --- Please do not reply this email ---
                Thank you...

MAILBODY

        open(SENDMAIL, "|/usr/lib/sendmail -oi -t") or die "$!\n";
        print SENDMAIL $From;
        print SENDMAIL $To;
        print SENDMAIL $Subject;
        print SENDMAIL $Content;
        close SENDMAIL or warn "Didnt close as expected:- $!\n";
}

