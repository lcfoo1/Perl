use Win32::GUI;


    $text = defined($ARGV[0]) ? $ARGV[0] : "Hello, world";


    $main = Win32::GUI::Window->new(
                -name => 'Main',
                -text => 'Perl',
        );
    $font = Win32::GUI::Font->new(
                -name => "Comic Sans MS", 
                -size => 24,
        );
    $label = $main->AddLabel(
                -text => $text,
                -name => 'label',
                -font => $font,
                -foreground => [255, 0, 0],
        );

    $ncw = $main->Width() -  $main->ScaleWidth();
    $NCH = $main->Height() - $main->ScaleHeight();
    $w = $label->Width()  + $ncw;
    $h = $label->Height() + $NCH;


    $desk = Win32::GUI::GetDesktopWindow();
    $dw = Win32::GUI::Width($desk);
    $dh = Win32::GUI::Height($desk);
    $x = ($dw - $w) / 2;
    $y = ($dh - $h) / 2;


    $main->Change(-minsize => [$w, $h]);
    $main->Move($x, $y);
    $main->Show();



    Win32::GUI::Dialog();


    sub Main_Terminate {
        -1;
    }


    sub Main_Resize {
        my $w = $main->Width();
        my $h = $main->Height();
        my $lw = $label->Width();
        my $lh = $label->Height();
        if ($lw > ($w - $ncw)) {
            $main->Width($lw + $ncw); # Remember the non-client width!
        }
        else {
            $label->Left(($w - $ncw - $lw) / 2);
        }
        if ($lh > ($h - $NCH)) {
            $main->Height($lh + $NCH); # Remember the non-client height!
        }
        else {
            $label->Top(($h - $NCH - $lh) / 2);
        }
    }


