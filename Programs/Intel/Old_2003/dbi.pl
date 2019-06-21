#!/bin/perl -w
use lib "/lopte/home1/lfoo1/lib/perl/";
use strict;
use DBI;
use Data::Dumper;

my $dbh = DBI->connect('dbi:Proxy:hostname=172.30.139.115;port=1234;dsn=dbi:ODBC:MARS', 'asblds', 'asblds', {RaiseError => 1, PrintError => 1}) 
	  or die $DBI::errstr;
my $sth = $dbh->prepare("SELECT DiSTINCT ATTRIBUTE_VALUE FROM S03_PROD_3.F_LOTATTRIBUTE WHERE LOT = '0424A00A' AND ATTRIBUTE_NUMBER = 711");
$sth->execute;

while(my $row = $sth->fetchrow_hashref) 
{
	print Dumper($row);
}

$sth->finish;
$dbh->disconnect; 
