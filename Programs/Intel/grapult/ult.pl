#!/usr/intel/pkgs/perl/5.8.5/bin/perl

my $Datalog = '3A';
my $SSID = "";
my $VisualID = "";
my $ULT = "";
my $Flag = 0;
open (DLG, $Datalog) || die "Cant open $Datalog : $!\n";
while (<DLG>)
{
	chomp;

	if (/2_visualid_(\w+)/)
	{
		$VisualID = $1;
	}

	if (/2_tname_FuseRead/)
	{
		$_ = <DLG>;
		if (/_tssid_(\w+)/)
		{
			$SSID = $1;	
			$_ = <DLG>;
			if(/_strgalt_nsv_(\S+)/)
			{
				$ULT = $1;
				$Flag = 1;
			}
		}
	}
	
	if ($Flag)
	{
		print "$VisualID - $SSID - $ULT\n";
		$Flag = 0;

	}
}
close DLG; 
