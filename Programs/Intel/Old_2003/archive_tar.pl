   use Archive::Tar;
    my $tar = Archive::Tar->new;

#    $tar->read('origin.tgz',1);
#    $tar->extract();

    $tar->add_files('Summary.txt');
#    $tar->add_data('file/baz.txt', 'This is the contents now');

#    $tar->rename('oldname', 'new_name');

    $tar->write('files.tar');

