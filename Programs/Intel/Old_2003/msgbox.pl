use Win32;

MsgBox("Test", "This is a test", 48);
# display a message box with an exclamation mark and an 'Ok' button

sub MsgBox {
    my ($caption, $message, $icon_buttons) = @_;
    my @return = qw/- Ok Cancel Abort Retry Ignore Yes No/;
    my $result = Win32::MsgBox($message, $icon_buttons, $caption);
    return $return[$result];
}

