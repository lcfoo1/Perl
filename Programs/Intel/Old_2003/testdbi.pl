use strict;
use DBI;
use HTML::Bargraph;

my $dbh = DBI->connect( 'dbi:Oracle:sod','sod','sod',) || die "Database connection not made: $DBI::errstr";
#my $dbh = DBI->connect( 'dbi:ODBC:sod','sod','sod',) || die "Database connection not made: $DBI::errstr";

$dbh->{RaiseError} = 1;

my $sth = $dbh->prepare("SELECT * from scribe");
$sth->execute( );

while (my @row = $sth->fetchrow_array()) 
{
	print "Row: @row\n";
}
$dbh->disconnect();

#Row: 0423A21A 025 PF426281.25 25 16-JUN-04
#Row: 0423A21A 016 PF426281.16 16 16-JUN-04
#Row: 0423A21A 017 PF426281.17 17 16-JUN-04
#Row: 0423A21A 008 PF426281.08 08 16-JUN-04
#Row: 0423A21A 018 PF426281.18 18 16-JUN-04
#Row: 0423A21A 009 PF426281.09 09 16-JUN-04
#Row: 0423A21A 019 PF426281.19 19 16-JUN-04
#Row: 0423A21A 001 PF426281.01 01 16-JUN-04
#Row: 0423A21B 010 PF426281.10 10 16-JUN-04
#Row: 0423A21A 020 PF426281.20 20 16-JUN-04
#Row: 0423A21A 011 PF426281.11 11 16-JUN-04
#Row: 0423A21A 021 PF426281.21 21 16-JUN-04
#Row: 0423A21A 012 PF426281.12 12 16-JUN-04
#Row: 0423A21A 022 PF426281.22 22 16-JUN-04
#Row: 0423A21A 013 PF426281.13 13 16-JUN-04
#Row: 0455A01B 011 D63743-11F2 11 30-JUN-04
#Row: INKFOO11 002 FF1133-02D2 02 21-JUN-04