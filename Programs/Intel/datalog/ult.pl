#!/usr/intel/pkgs/perl/5.8.5/bin/perl

my $Datalog = $ARGV[0];
$Datalog =~ s/\\/\//;
print "$Datalog\n";
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
		if (/_tssid_LD1/)
		{
			#$SSID = $1;	
			$_ = <DLG>;
			if(/_strgalt_nsv_(\S+)/)
			{
				$ULT1 = $1;
			}
		}
		if (/_tssid_LD2/)
		{
			#$SSID = $1;	
			$_ = <DLG>;
			if(/_strgalt_nsv_(\S+)/)
			{
				$ULT2 = $1;
				$Flag = 1;
			}
		}
	}
	
	if ($Flag)
	{
		print "$VisualID,$ULT1,$ULT2\n";
		$Flag = 0;
	}
}
close DLG; 
