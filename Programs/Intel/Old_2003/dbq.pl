
use DBI;
my $dbh = DBI->connect('dbi:Chart:') or die "Cannot connect\n";
#
#    example: create a pie chart
#
$dbh->do('CREATE TABLE pie (region CHAR(20), sales FLOAT)');
$sth = $dbh->prepare('INSERT INTO pie VALUES( ?, ?)');
$sth->execute('East', 2756.34);
$sth->execute('Southeast', 3456.78);
$sth->execute('Midwest', 1234.56);
$sth->execute('Southwest', 4569.78);
$sth->execute('Northwest', 33456.78);

$rsth = $dbh->prepare("SELECT PIECHART FROM pie WHERE WIDTH=400 AND HEIGHT=400 AND TITLE = 'Sales By Region' AND COLOR IN ('red', 'green', 'blue', 'lyellow', 'lpurple') AND BACKGROUND='lgray' AND SIGNATURE='Copyright(C) 2001, GOWI Systems, Inc.'");
$rsth->execute;
$rsth->bind_col(1, \$buf);
$rsth->fetch;

