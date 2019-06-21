#!/usr/intel/bin/perl
my $Dir = '/nfs/png/disks/wmtpe282/lfoo1/work/cktm/preamble';
my $ODir = '/nfs/png/disks/wmtpe282/lfoo1/work/cktm/analyse/output';
my $CDir = '/nfs/png/disks/wmtpe282/lfoo1/work/cktm/analyse/chk';
my @PLabel = ('JTAGDieCtrl_Start1:', 'JTAG_WRITE_FUSE_CFR_A:','JTAGDieCtrl_Start2:','JTAGsigCtl_Start1:');
my %PatLabel = ();
chdir $Dir || die "Cant change dir $Dir : $!\n";

foreach $File (<*_pre_*.pat>)
{
	#$File = $Dir . "/" .$File;
	my $OutFile = $ODir . "/" . $File;
	my $ChkFile = $CDir . "/" . $File;
	open (PAT, $File) || die "Cant open $File :$!\n";
	open (OUT, ">$OutFile") || die "Cant open $OutFile :$!\n";
	open (CHK, ">$ChkFile") || die "Cant open $ChkFile :$!\n";
	while (<PAT>)
	{
		chomp;
		if (/^$PLabel[0]$/)
		{
			print CHK "$PLabel[0]\n";
			print OUT "$PLabel[0]\n";
			print OUT "TDI\tTDI_2\n";
			until (/NOP/)
			{
				chomp;
				my $Bits = ();
				if (/V\s*{\s*ALLPINs=c(\w+)/)
				{
					my $Line = $1;
					print CHK "$Line\n";
					@Bits = split(//, $Line);
					print OUT "$Bits[154]\t$Bits[155]\n";
				}
				$_ = <PAT>;
			}
		}

		if (/^$PLabel[1]$/)
		{
			my $Count = 0;
			print CHK "$PLabel[1]\n";
			print OUT "$PLabel[1]\n";
			until (/NOP/)
			{
				chomp;
				if (/V\s*{\s*ALLPINs=c(\w+)/)
				{
					my $Line = $1;
					print CHK "Bit $Count: $Line\n";
					print OUT "Bit $Count: $Line\n";
					$Count++;
				}
				$_ = <PAT>;
			}
		}

		if (/^$PLabel[3]$/)
		{
			my $Count = 0;
			print CHK "$PLabel[3]\n";
			print OUT "$PLabel[3]\n";
			until (/NOP/)
			{
				chomp;
				if (/V\s*{\s*ALLPINs=c(\w+)/)
				{
					my $Line = $1;
					print CHK "Bit $Count: $Line\n";
					print OUT "Bit $Count: $Line\n";
					$Count++;
				}
				$_ = <PAT>;
			}
		}
		
		
		if (/^$PLabel[2]$/)
		{
			print CHK "$PLabel[2]\n";
			print OUT "$PLabel[2]\n";
			print OUT "TDI\tTDI_2\n";
			
			until (/NOP/)
			{
				chomp;
				my $Bits = ();
				if (/V\s*{\s*ALLPINs=c(\w+)/)
				{
					my $Line = $1;
					print CHK "$Line\n";
					@Bits = split(//, $Line);
					print OUT "$Bits[154]\t$Bits[155]\n";
				}
				$_ = <PAT>;
			}
		}
	}
	close PAT;
	close OUT;
	close CHK;
}
