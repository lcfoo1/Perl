
# Copy files from FM to PM - TP

my @AllFiles = ();
my ($SS, $MI, $HH, $DD, $MM, $YYYY) = &GetCurrentTime();

print "Getting files from FM TP directory\n";
system ("GetFiles.bat");
&ReadFiles();

if ($AllFiles[0] eq "")
{
	exit 0;
}

print "Creating copy_fm_to_pg.bat\n";
&CreateBatch();
print "Copying files from FM TP directory\n";
system ("copy_fm_to_pg.bat");

sub CreateBatch
{
	my $BatchFile = 'copy_fm_to_pg.bat';
	open (BATCH, ">$BatchFile") || die "Cant open $BatchFile : $!\n";
	foreach $TPFile (@AllFiles)
	{
		print BATCH "copy M:\\${TPFile} N:\\${TPFile}\n";
	}
	close BATCH;
}

# Read files timestamp
sub ReadFiles
{
	my $ListFile = 'FM_zip_tp_list_file.txt';
	my $count = 0;
	open (LISTFILE, $ListFile) || die "Can't open $ListFile : $!\n";
	while (<LISTFILE>)
	{
		chomp;
		if (/\.zip/)
		{
			my ($F_MM, $F_DD, $F_YYYY, $F_HH, $F_MI, $AM_PM, $Filename) = ($1, $2, $3, $4, $5, $6, $7) if ($_ =~ /(\d+)\/(\d+)\/(\d+)\s+(\d+)\S(\d+)\s+(\w+)\s+.*\s+(\S+\.zip)/);
		 	if ($AM_PM eq "PM")
			{
				$F_HH = $F_HH + 12;
			}

			my $Days = $DD - $F_DD;
			my $Months = $MM - $F_MM;
			my $Years = $YYYY - $F_YYYY;
			#print "$Days\n";
			if (($Days <= 1) && ($Months == 0) && ($Years == 0))
			{
				print "$Filename is created less than 24 hour\n";
				push (@AllFiles, $Filename);
			}
			elsif (($Days <= -28) && ($Months == 1) && ($Years == 0))
			{
				print "$Filename is created less than 24 hour last month\n";
				push (@AllFiles, $Filename);
			}
			elsif (($Days <= -28) && ($Months <= -11) && ($Years == 0))
			{
				print "$Filename is created less than 24 hour last month of previous year\n";
				push (@AllFiles, $Filename);
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

