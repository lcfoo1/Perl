
use strict;
use warnings;

while (1)
{
	my ($sec, $min, $hour) = localtime((stat("dummy.txt"))[9]);
	my $Now = localtime(time);
	print "My Time $sec $min $hour\n";
	#if ($hour == 7)
	if ($min == 40)
	{
		print "Send email and log at TimeLog.txt\n";
		open(TIMELOG, ">>TimeLog.txt") or die "Cant open the time log file: $!\n";
		print TIMELOG "Time log now at $Now when $hour\n";
		close TIMELOG;
	}
	else
	{
		print "Don't send email at this time\n";
	}
	sleep(1);
}