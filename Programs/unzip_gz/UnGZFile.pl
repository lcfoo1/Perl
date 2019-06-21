use strict;

BEGIN { @ARGV= map { glob($_) } @ARGV }

use Compress::Zlib;

die "Usage: $0 {file.gz|outfile=infile} ...\n"
    unless @ARGV ;

foreach my $infile (@ARGV) {
    my $outfile= $infile;
    if(  $infile =~ /=/  ) {
        ( $outfile, $infile )= split /=/, $infile;
    } elsif(  $outfile !~ s/[._]gz$//i  ) {
        $infile .= ".gz";
    }
    my $gz= gzopen( $infile, "rb" )
        or die "Cannot open $infile: $gzerrno\n";
    open( OUT, "> $outfile\0" )
        or die "Can't write $outfile: $!\n";
    binmode(OUT);

    my $buffer;
    print OUT $buffer
        while $gz->gzread($buffer) > 0;
    die "Error reading from $infile: $gzerrno\n"
        if $gzerrno != Z_STREAM_END;

    $gz->gzclose();
    close(OUT)
        or  warn "Error closing $outfile: $!\n";
}