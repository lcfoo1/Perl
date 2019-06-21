#!/usr/local/bin/perl5 -w

use strict;

my %Data;
my $Ctr;
my $BinFlag = 0;
my $FailFlag = 0;
my $File = '/engr/cudjoe/s9kprogs/applegate/s9kprogs/b0/rev7a/main/Applegate/OKI/L3290531/Database.2003_38/L3290531_6195/1A';

open(FILE, $File) or die "Cant open $File:- $!";
print "$File\n";
while(<FILE>)
{
	$Ctr = $1 if /^(3_prtnm_\d+)/;
	$FailFlag = 1 if /^2_faildata_00000011/;
	$BinFlag = 1 if /^2_binn_200/;
	$Data{$Ctr} = 1 if $BinFlag and $FailFlag;
	($BinFlag, $FailFlag) = (0, 0) if /^3_lsep/;
}
close FILE;

foreach my $Key(keys %Data)
{
	print "$Key = $Data{$Key}\n";
}
$File = '/engr/cudjoe/s9kprogs/applegate/s9kprogs/b0/rev7a/main/Applegate//OKI/L3290531/Database.2003_38/L3290531_6195/2A';
print "$File\n";
open(FILE, $File) or die "Cant open $File:- $!";
while(<FILE>)
{
        $Ctr = $1 if /^(3_prtnm_\d+)/;
        $FailFlag = 1 if /^2_faildata_00000011/;
        $BinFlag = 1 if /^2_binn_200/;
        $Data{$Ctr} = 1 if $BinFlag and $FailFlag;
        ($BinFlag, $FailFlag) = (0, 0) if /^3_lsep/;
}
close FILE;

foreach my $Key(keys %Data)
{
        print "$Key = $Data{$Key}\n";
}
$File = '/engr/cudjoe/s9kprogs/applegate/s9kprogs/b0/rev7a/main/Applegate//OKI/L3290531/Database.2003_38/L3290531_6195/3A';
print "$File\n";
open(FILE, $File) or die "Cant open $File:- $!";
while(<FILE>)
{
        $Ctr = $1 if /^(3_prtnm_\d+)/;
        $FailFlag = 1 if /^2_faildata_00000011/;
        $BinFlag = 1 if /^2_binn_200/;
        $Data{$Ctr} = 1 if $BinFlag and $FailFlag;
        ($BinFlag, $FailFlag) = (0, 0) if /^3_lsep/;
}
close FILE;

foreach my $Key(keys %Data)
{
        print "$Key = $Data{$Key}\n";
}


$File = '/engr/cudjoe/s9kprogs/applegate/s9kprogs/b0/rev7a/main/Applegate//OKI/L3290531/Database.2003_38/L3290531_6195/4A';
print "$File\n";
open(FILE, $File) or die "Cant open $File:- $!";
while(<FILE>)
{
        $Ctr = $1 if /^(3_prtnm_\d+)/;
        $FailFlag = 1 if /^2_faildata_00000011/;
        $BinFlag = 1 if /^2_binn_200/;
        $Data{$Ctr} = 1 if $BinFlag and $FailFlag;
        ($BinFlag, $FailFlag) = (0, 0) if /^3_lsep/;
}
close FILE;

foreach my $Key(keys %Data)
{
        print "$Key = $Data{$Key}\n";
}

