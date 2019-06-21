# Simple script to mask line in TP - Foo Lye Cheung
use strict;
use warnings;
use File::Find;
use File::Copy;

use Cwd;
my $CurDir = getcwd;

#my $TPPath = 'C:\intel\cmtprogs\lrbdtefc0mc004w30a0\CMTP_Outputs\OTPL_loadables\lrb_Cx_class';
my $TPPath = 'C:\intel\cmtprogs\lrb\enhance_dtsminmax\CMTP_Outputs\OTPL_loadables\lrb_Cx_class_dtsminmax_profiling1';
my $MaskParamFile = $CurDir . "/Mask_parameters.txt";
my @MaskParams = ();
my @AllFiles = ();

&ReadMaskParamFile();
&Main();

# Main script starts here
sub Main
{
	finddepth(\&GetFiles, $TPPath);
	&Process();
}

# Get all .tpl
sub GetFiles
{
	if ((-f $File::Find::name) && ($File::Find::name =~ /\.tpl$/i))
	{
		my $File = $File::Find::name;
		$File =~ s/\\/\//g;
		push (@AllFiles, $File);
	}
}

# Process the file
sub Process
{
	foreach my $File (@AllFiles)
	{
		print "Processing $File\n";
		my $TmpFile = $File . "_tmp";

		open (TMP, ">$TmpFile") || die "Cant open $TmpFile : $!\n";
		open (ORG, $File) || die "Cant open $File : $!\n";
		while(<ORG>)
		{
			chomp;
			if ((/#/) || (/^$/))
			{
				# Do not substitute
			}
			else
			{
				foreach my $Param (@MaskParams)
				{
			       		s/^(.+$Param.+)$/#$1/g;
				}
			}
			print TMP "$_\n";
		}
		close ORG;
		close TMP;

		move ($TmpFile, $File) or die "Cant copy from $TmpFile to $File - failed: $!";
	}
}

# Read mask parameters from file
sub ReadMaskParamFile
{
	open (FILE, $MaskParamFile) || die "Cant open $MaskParamFile : $!\n";
	{
		while (<FILE>)
		{
			chomp;
			next if ((/#/) || (/^$/));
			#print "$_\n";
			push (@MaskParams, $_);
		}
	}
	close FILE;
}

	
