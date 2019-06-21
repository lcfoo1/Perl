=head1 NAME

Archive::Zip::Tree - methods for adding/extracting trees using Archive::Zip

=head1 SYNOPSIS

=head1 DESCRIPTION

This module is deprecated, because all its methods were moved into the main
Archive::Zip module.

It is included in the distribution merely to avoid breaking old code.

See L<Archive::Zip>.

=head1 AUTHOR

Foo Lye Cheung

=head1 COPYRIGHT

Copyright (c) 2006. All rights reserved. 

=head1 SEE ALSO

L<Archive::Zip>

=cut

use Archive::Zip;

warn("Archive::Zip::Tree is deprecated; its methods have been moved into Archive::Zip.") if $^W;

1;
