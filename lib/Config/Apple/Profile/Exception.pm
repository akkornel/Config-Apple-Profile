# This is the code for Config::Apple::Profile::Payload::Common.
# For Copyright, please see the bottom of the file.

# We're going to let Exception::Class define our package for us.
#package Config::Apple::Profile::Exception;

use 5.10.1;
use strict;
use warnings FATAL => 'all';

use Exception::Class;


=encoding utf8

=head1 NAME

Config::Apple::Profile::Exception - Exceptions that may be thrown by these
modules

=head1 DESCRIPTION

This package defines all of the exceptions that may be thrown when using
C<Config::Apple::Profile>.  These exceptions are created using
L<Exception::Class>, and clients should refer to that package's documentation
for more information on how to recognize exceptions being thrown, and what
can be done with them.

=head1 EXCEPTION CLASSES

The following exception classes are defined:

=cut

my @exception_params = ();


=head2 C<Config::Apple::Profile::Exception>

This is the base class for exceptions thrown by C<Config::Apple::Profile>.

=cut

push @exception_params, (
    'Config::Apple::Profile::Exception' => {
        description => 'Generic Config::Apple::Profile error',
    },
);


# Since we're building the array at compile time, I have to call ->import
# explicitly.  Simply doing `use` wouldn't work, because that happens at the
# start of compilation.  I could've used BEGIN blocks, though….
Exception::Class->import(@exception_params);


=head1 ACKNOWLEDGEMENTS

Refer to the L<Config::Apple::Profile> for acknowledgements.

=head1 AUTHOR

A. Karl Kornel, C<< <karl at kornel.us> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2014 A. Karl Kornel.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;