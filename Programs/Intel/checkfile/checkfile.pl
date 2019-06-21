
use File::Find;
my @Files = ();

my @Dir = ('C:\Perl\Programs\checkfile\test1');
my $LogFile = 'C:\Perl\Programs\checkfile\test1\LogFiles.log';

# Reference date to compare
my $SetPointDate = '2008-05-09 00:00';

finddepth(\&GetFiles, @Dir);

open (LOG, ">$LogFile") || die "Cant open $LogFile : $!\n";
print LOG "New file found since $SetPointDate\n";
foreach my $File (@Files)
{
	print LOG "$File\n";
}
close LOG;

sub GetFiles
{
	if ((-f $File::Find::name))
	{
		my $File = $File::Find::name;
		$File =~ s/\\/\//g;

		# Setting current time format
		my ($y, $m, $d, $hh, $mm, $ss) = (localtime ((stat($File))[9]))[5,4,3,2,1,0];
		$y += 1900; 
		$m++;
		my $Now = sprintf("%d-%02d-%02d %02d:%02d:%02d", $y, $m, $d, $hh, $mm, $ss);

		# Total different Days
		my ($Days, $Diff) = &TimeDiff( Date1 => $SetPointDate, Date2 => $Now );

                if ($Days >= 0.000)
                {
			print "Found $File - $Diff\n";
			push (@Files, $File);
                }
		else
		{
			#print "Old $File - $Diff\n";
		}
	}
}

# Subroutine to compare time
sub TimeDiff (%) 
{
	my %args = @_;

	my @offset_days = qw(0 31 59 90 120 151 181 212 243 273 304 334);

	my $year1  = substr($args{'Date1'}, 0, 4);
	my $month1 = substr($args{'Date1'}, 5, 2);
	my $day1   = substr($args{'Date1'}, 8, 2);
	my $hh1    = substr($args{'Date1'},11, 2) || 0;
	my $mm1    = substr($args{'Date1'},14, 2) || 0;
	my $ss1    = substr($args{'Date1'},17, 2) if (length($args{'Date1'}) > 16);
	   $ss1  ||= 0;

	my $year2  = substr($args{'Date2'}, 0, 4);
	my $month2 = substr($args{'Date2'}, 5, 2);
	my $day2   = substr($args{'Date2'}, 8, 2);
	my $hh2    = substr($args{'Date2'},11, 2) || 0;
	my $mm2    = substr($args{'Date2'},14, 2) || 0;
	my $ss2    = substr($args{'Date2'},17, 2) if (length($args{'Date2'}) > 16);
	   $ss2  ||= 0;

	my $total_days1 = $offset_days[$month1 - 1] + $day1 + 365 * $year1;
	my $total_days2 = $offset_days[$month2 - 1] + $day2 + 365 * $year2;
	my $days_diff   = $total_days2 - $total_days1;

	my $seconds1 = $total_days1 * 86400 + $hh1 * 3600 + $mm1 * 60 + $ss1;
	my $seconds2 = $total_days2 * 86400 + $hh2 * 3600 + $mm2 * 60 + $ss2;
	my $ssDiff = $seconds2 - $seconds1;

	my $dd     = int($ssDiff / 86400);
	my $hh     = int($ssDiff /  3600) - $dd *    24;
	my $mm     = int($ssDiff /    60) - $dd *  1440 - $hh *   60;
	my $ss     = int($ssDiff /     1) - $dd * 86400 - $hh * 3600 - $mm * 60;

	return ($dd, "$dd Days $hh Hour $mm Min");
}
