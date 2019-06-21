use warnings;
use strict;
use File::Find;


my @AllEvergreenDirs = ();
my ($SS, $MI, $HH, $DD, $MM, $YYYY) = &GetCurrentTime();
my $JFDrive = "Z:\\";

print "Getting files from FM JF directory\n";
system ("Get_JF_Files.bat");
&ReadFiles();

if ($AllEvergreenDirs[0] eq "")
{
	exit 0;
}

print "Creating copy_jf_to_pg.bat\n";

finddepth(\&GetFiles,  @AllEvergreenDirs);

#&CreateBatch();
#print "Copying files from JF CorTeX directory\n";
#system ("copy_fm_to_pg.bat");

sub CreateBatch
{
	my $BatchFile = 'copy_jf_to_pg.bat';
	open (BATCH, ">$BatchFile") || die "Cant open $BatchFile : $!\n";
	foreach my $File (@AllEvergreenDirs)
	{
		print BATCH "copy Z:\\${File} C:\\Development\\intel\\tpapps\\nhm\\${File}\n";
	}
	close BATCH;
}

# GetFiles
sub GetFiles
{
	if ((-f $File::Find::name) )#&& ($File::Find::name =~ /\/$Rev\//g))
	{
		my $File = $File::Find::name;
		$File =~ s/\\/\//g;
		#$File =~ s/$SrcDir\///g;
		print "Found $File\n";
		#push (@Files, $File);
	}
}


# Read files timestamp
sub ReadFiles
{
	my $ListFile = 'JF_directory_cortex_list.txt';
	my $count = 0;
	open (LISTFILE, $ListFile) || die "Can't open $ListFile : $!\n";
	while (<LISTFILE>)
	{
		chomp;
		if (/evg.*tss.*/)
		{
			my ($F_MM, $F_DD, $F_YYYY, $F_HH, $F_MI, $AM_PM, $Filename) = ($1, $2, $3, $4, $5, $6, $7) if ($_ =~ /(\d+)\/(\d+)\/(\d+)\s+(\d+)\S(\d+)\s+(\w+)\s+.*\s+(evg\S+tss\S+)/);

			#print "$F_MM, $F_DD, $F_YYYY, $F_HH, $F_MI, $AM_PM, $Filename\n";
		 	if ($AM_PM eq "PM")
			{
				$F_HH = $F_HH + 12;
			}

			$Filename = $JFDrive . $Filename;

			my $Days = $DD - $F_DD;
			my $Months = $MM - $F_MM;
			my $Years = $YYYY - $F_YYYY;
			print "$Days days, $Months month and $Years years - $Filename\n";

			if (($Days <= 3) && ($Months == 0) && ($Years == 0))
			#if (($Days <= 1) && ($Months == 0) && ($Years == 0))
			{
				print "$Filename is created less than 24 hour\n";
				push (@AllEvergreenDirs, $Filename);
			}
			elsif (($Days <= -28) && ($Months == 1) && ($Years == 0))
			{
				print "$Filename is created less than 24 hour last month\n";
				push (@AllEvergreenDirs, $Filename);
			}
			elsif (($Days <= -28) && ($Months <= -11) && ($Years == 0))
			{
				print "$Filename is created less than 24 hour last month of previous year\n";
				push (@AllEvergreenDirs, $Filename);
			}
	
			$count++;
			last if ($count == 5);
		}
	}
	close LISTFILE;
}

# Get current timestamp
sub GetCurrentTime
{
	my ($SS, $MI, $HH, $DD, $MM, $YYYY) = localtime();
	$YYYY += 1900;
	$MM++;
	$MM =~ s/^(\d)$/0$1/;
	$DD =~ s/^(\d)$/0$1/;
	$HH =~ s/^(\d)$/0$1/;
	$MI =~ s/^(\d)$/0$1/;
	$SS =~ s/^(\d)$/0$1/;
	return ($SS, $MI, $HH, $DD, $MM, $YYYY);
}

