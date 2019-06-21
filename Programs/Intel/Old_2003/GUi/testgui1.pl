    use Win32::GUI;


    $text = defined($ARGV[0]) ? $ARGV[0] : "Hello, world";


    $main = Win32::GUI::Window->new(-name => 'Main', -text => 'Perl');
    $label = $main->AddLabel(-text => $text);


    $ncw = $main->Width()  - $main->ScaleWidth();
    $nch = $main->Height() - $main->ScaleHeight();
    $w = $label->Width()  + $ncw;
    $h = $label->Height() + $nch;


    $main->Resize($w, $h);
    $main->Show();
    Win32::GUI::Dialog();


    sub Main_Terminate {
        -1;
    }


