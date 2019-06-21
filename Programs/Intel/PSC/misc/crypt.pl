use strict;
use SECRET::Crypt;
my $crypt = LCFOO::Crypt->new( debug => 0, encoding => 'hex8' );
my $encrypted = $crypt->encrypt('plain text to encrypt', 'your_secret_string');
#$decrypted = $crypt->decrypt($encrypted, 'your_secret_string');

print "$encrypted\n";

