
    use Win32::GUI;
    $main = Win32::GUI::Window->new(
                -name   => 'Main',
                -width  => 100,
                -height => 100,
        );
    $main->AddLabel(-text => "Hello, world");
    $main->Show();
    Win32::GUI::Dialog();


    sub Main_Terminate {
        -1;
    }


