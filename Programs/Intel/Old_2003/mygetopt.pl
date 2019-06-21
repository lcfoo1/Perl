use Getopt::Std;
%option=();

getopts("Ab:Do:", \%option);
if ($option{D}) {
    print "Writing output to $option{D}";
}

#if ($opt_A) {
#    print "Writing output to $opt_A";
#}

#if ($opt_b) {
#    print "Writing output to $opt_b";
#}

#if ($opt_D) {
#    print "Writing output to $opt_D";
#}