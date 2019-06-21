
my $Dir = 'C:\eistorm\log';
chdir $Dir || die "Cannt open $Dir :$!\n";
my $File = 'log3.txt';
my $DatalogTP;
my $count = 0;
my $StartFlag = 0;

open (EILOG, ">C:\\eistorm\\eilog3.txt");
#foreach my $File (<*>)
#{
	open (LOG, $File) || die "Cannt open $File : $!\n";

	while (<LOG>)
	{
		chomp;
		if (/Received\s+from\s+SC:\s+MACHINE_COMM\s+GX41\s+C\s+1030\s+START_DLOG.*NAME=DLOG_OUTPUT_FILE\s+FORMAT=A\s+VALUE=(\S+).*NAME=TEST_PROGRAM_NAME\s+FORMAT=A\s+VALUE=(\w+).*/)
		{
			$DatalogTP = "$1 $2";
			print "$DatalogTP\n";
			print EILOG "$DatalogTP\n";
		}
		if (/Running\s+S9K_INIT/)
		{
			$StartFlag = 1;
		}

		if ($StartFlag)
		{
			if (/^(.*)5\s+Sent\s+to\s+SC.*START_OF_TEST/)
			{
				print "Unit# $count at $1\n";
				print EILOG "Unit# $count at $1";
				do 
				{
					chomp;
					my $tmp = $1 if (/\s+Sent\s+to\s+SC.*FORMAT=A\s+VALUE="(.*)"/);
					$_ = <LOG>;
					print "$tmp \n";;
					print EILOG "$tmp\n";;
				} while ($_ !~ /END_OF_TEST/);
				$count++;
			}
		}
	}
	close LOG;
#}

close EILOG;
#Now Sat Jul 24 01:56:26 2004  5 Received from SC: MACHINE_COMM GX41 C 1030 START_DLOG NAME=DLOG_TYPE FORMAT=U2 VALUE=0 NAME=DLOG_FAIL_COUNTS FORMAT=I4 VALUE=1 NAME=DLOG_FORMAT_FILE FORMAT=A VALUE=/engr/verde/s9kprogs/b1/rev10a/gx/main/b1_t3_cvrdb1r0.asap.df NAME=DLOG_OUTPUT_FILE FORMAT=A VALUE=/db1/s9k/prod/L4270364_6152/3A NAME=OPERATOR FORMAT=A VALUE=KAMARIAH NAME=TEST_OBJECT_ID FORMAT=A VALUE=L4270364-3A NAME=SPLIT FORMAT=A VALUE=A NAME=TEMPERATURE FORMAT=A VALUE=115.0 NAME=LOT_ID FORMAT=A VALUE=L4270364 NAME=TESTER_ID FORMAT=A VALUE=GX4 NAME=LOADBOARD_ID FORMAT=A VALUE=empty NAME=LOCATION FORMAT=A VALUE=6152 NAME=PART_NUMBER FORMAT=A VALUE=FW8VD32VAB NAME=TEST_PROGRAM_NAME FORMAT=A VALUE=8VD321ABC10 NAME=PROBER_HANDLER_ID FORMAT=A VALUE=2HND205 NAME=FLOW_STEP FORMAT=A VALUE=6152

