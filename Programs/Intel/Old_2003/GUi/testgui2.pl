    # Assume we have the main window size in ($w, $h) as before
    $desk = Win32::GUI::GetDesktopWindow();
    $dw = Win32::GUI::Width($desk);
    $dh = Win32::GUI::Height($desk);
    $x = ($dw - $w) / 2;
    $y = ($dh - $h) / 2;
    $main->Move($x, $y);

