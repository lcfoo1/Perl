  use XML::Parser;  
#  $p1 = new XML::Parser(Style => 'Debug');
  $p1 = new XML::Parser(Style => 'Tree');
  $p1->parsefile('sample.xml');

#  $p1->parse('<foo id="me">Hello World</foo>');  # Alternative
# $p2 = new XML::Parser(Handlers => {Start => \&handle_start,
#                                    End   => \&handle_end,
#                                    Char  => \&handle_char});
# $p2->parse($socket);  # Another alternative


# $p3 = new XML::Parser(ErrorContext => 2);  $p3->setHandlers(Char    => \&text,
#                  Default => \&other);  open(FOO, 'xmlgenerator |');

#  $p3->parse(*FOO, ProtocolEncoding => 'ISO-8859-1');
#  close(FOO);  
#
# $p3->parsefile('junk.xml', ErrorContext => 3);