


use DBD::Chart ;


        $dbh = DBI->connect('dbi:Chart:')
            or die "Cannot connect: " . $DBI::errstr;
        #
        #       create file if it deosn't exist, otherwise, just open
        #
        $dbh->do('CREATE TABLE mychart (name CHAR(10), ID INTEGER, value FLOAT)')
                or die $dbh->errstr;
        #       add data to be plotted
        $sth = $dbh->prepare('INSERT INTO mychart VALUES (?, ?, ?)');
        $sth->bind_param(1, 'Values');
        $sth->bind_param(2, 45);
        $sth->bind_param(3, 12345.23);
        $sth->execute or die 'Cannot execute: ' . $sth->errstr;
        #       and render it
        $sth = $dbh->prepare('SELECT BARCHART FROM mychart');
        $sth->execute or die 'Cannot execute: ' . $sth->errstr;
        @row = $sth->fetchrow_array;
        print $row[0];
        # delete the chart
        $sth = $dbh->prepare('DROP TABLE mychart')
                or die "Cannot prepare: " . $dbh->errstr;
        $sth->execute or die 'Cannot execute: ' . $sth->errstr;
        $dbh->disconnect;
