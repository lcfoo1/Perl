use Text::Wrap;

$Text::Wrap::columns = 20;
$pre1 = "> \t";
$pre2 = "> ";

print wrap( $pre1, $pre2, "Hello, world, it's a nice day, isn't it?\n" );

