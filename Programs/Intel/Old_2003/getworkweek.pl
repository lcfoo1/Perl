
my $File = 'subject.txt';

open (FILE, $File) || die "Cant open $File\n";
while(<FILE>)
{
	print "$_\n";
	my $Title = $_;
	if ($Title =~ (/(WW\S*\s*(\-|)\s*\S*)/i))
        {
                my $WorkWeekSubmited = $1;
		my $Count = 0;		
		my $FormatedWW = "";
                $WorkWeekSubmited =~ s/\s+//og;
                my @WorkWeeks = split('-', $WorkWeekSubmited);
                print "Count: $#WorkWeeks\n";

                foreach my $WW (@WorkWeeks)
                {
			# There is no dot in between
                        if ($WW =~ /(\d*(\.|)\d+)/i)
                        {
				my @NumCheck = split (/\./, $1);
				if ($#NumCheck == 0)
				{
					if (length ($NumCheck[0]) == 1)
                                	{
						$FormatedWW = "WW0" . $NumCheck[0];
					}
					else
					{
						$FormatedWW = "WW" . $NumCheck[0];
					}
						
					if ($Count == 0)
					{
						$FormatedWW = $FormatedWW . '.0';
						print "First count $FormatedWW :: $#NumCheck\n";
					}
					else
					{
						$FormatedWW = $FormatedWW . '.6';
						print "Second count $FormatedWW :: $#NumCheck\n";
					}
				}
				else
				{
					# There is dot in between
					if (length ($NumCheck[0]) == 1)
                                	{
						$FormatedWW = "WW0" . $NumCheck[0] . '.' . $NumCheck[1];
					}
					else
					{
						$FormatedWW = "WW" . $NumCheck[0] . '.' . $NumCheck[1];
					}
				}
				print "$WW now $FormatedWW\n";
                        }
			$Count++;
		}
	}
	
}
close FILE;
