
use Date::Calc qw(:all);

my @LocalTime = localtime;
my $MM = $LocalTime[4]+1;
my $YY = 1900 + $LocalTime[5];

($week,$YY) = Week_of_Year($YY,$MM,  $LocalTime[3]);
print "$YY,$MM,  $LocalTime[3], $week\n";

