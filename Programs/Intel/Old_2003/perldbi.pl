
use DBD::Chart;
use DBI;

sub MakePie
{
	my ($Site, $Domain, $File) = @_;
	my $dbh = DBI->connect('dbi:Chart:', undef, undef, {PrintError => 1, RaiseError => 0}) or die "Can't connect";

	$dbh->do('CREATE TABLE Site (Msg varchar(5), Count integer)');
	my $sth = $dbh->prepare('INSERT INTO Site VALUES(?, ?)');

	foreach my $Key(sort keys %{$Data{$Domain}})
	{
		$sth->execute($Key, $Data{$Domain}{$Key});
	}
	$sth = $dbh->prepare("SELECT PIECHART, IMAGEMAP FROM Site " .
					"WHERE WIDTH=400 AND HEIGHT=200 " .
					"AND TITLE='KLA iTUFF loading breakdown for $Site' " .
					"AND COLORS=('green', 'white', 'dred', 'lred', 'red', 'lgreen') " .
					"AND 3-D=1 AND MAPNAME='Pie$Site' AND MAPURL='KLAFileTransferDetails.asp?ACTION=PieDetails$Domain&DETAIL=:X'" .
					"AND MAPTYPE='HTML'");
	$sth->execute;

	my $row = $sth->fetchrow_arrayref;

	# Write to png file
	open(PIE, ">$File") or die "Cant write to $File:- $!";
	binmode PIE;
	print PIE $$row[0];
	close PIE;

	$dbh->do('DROP TABLE Site');
	$dbh->disconnect;
	print"<img src=$File alt='Click to view lot details' usemap=#Pie$Site>$$row[1]";
}

sub MakeBar
{
	my ($Site, $Domain, $File) = @_;
	my @Details = qw(LBOI L NC NLBF T NT);

	my $dbh = DBI->connect('dbi:Chart:', undef, undef, {PrintError => 1, RaiseError => 0}) or die "Can't connect";
	$dbh->do('CREATE TABLE threedbar (Msg varchar(10), LBOI integer, L integer, NC integer, NLBF integer, T integer, NT integer)');
	my $sth = $dbh->prepare('INSERT INTO threedbar VALUES(?, ?, ?, ?, ?, ?, ?)');

	foreach my $WWD(sort keys %{$Data{$Domain}})
	{
		my @Values;

		foreach my $Detail(@Details)
		{
			exists $Data{$Domain}{$WWD}{$Detail} ? push @Values, $Data{$Domain}{$WWD}{$Detail} : push @Values, "0";
		}
		$sth->execute($WWD, $Values[0], $Values[1], $Values[2], $Values[3], $Values[4], $Values[5]);
	}
	$sth = $dbh->prepare("SELECT BARCHART, IMAGEMAP FROM threedbar " .
					"WHERE WIDTH=400 AND HEIGHT=300 " .
					"AND TITLE='KLA iTUFF loading for $Site ww$WW' AND " .
					"X-AXIS = '' AND Y-AXIS = 'File count' AND 3-D = 1 AND " .
					"SHOWGRID = 1 AND COLORS=('dred', 'green', 'white', 'lred', 'lgreen', 'red') AND " .
					"MAPNAME='Bar$Site' AND MAPURL='KLAFileTransferDetails.asp?ACTION=BarDetails$Domain&YYYYWWD=:X&COUNT=:Y'" .
					"AND MAPTYPE='HTML'");
	$sth->execute;
	my $row = $sth->fetchrow_arrayref;

	open(BAR, ">$File") or die "Cant write to $File:- $!";
	binmode BAR;
	print BAR $$row[0];
	close BAR;

	$dbh->do('DROP TABLE threedbar');
	$dbh->disconnect;
	print "<img src=$File usemap='#Bar$Site'>$$row[1]";
}
