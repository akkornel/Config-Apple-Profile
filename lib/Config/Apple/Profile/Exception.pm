# This is the code for Config::Apple::Profile::Exception.
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


=head2 Config::Apple::Profile::Exception

This is the base class for exceptions thrown by C<Config::Apple::Profile>.

=cut

push @exception_params, (
    'Config::Apple::Profile::Exception' => {
        description => 'Generic Config::Apple::Profile error',
    },
);


=head2 Config::Apple::Profile::Exception::ArrayOp

An invalid array operation has been attempted.  For example, attempting to
assign to or delete an array entry is not a valid operation with payload arrays.

=cut

push @exception_params, (
    'Config::Apple::Profile::Exception::ArrayOp' => {
        description => 'Invalid array operation',
    },
);


=head2 Config::Apple::Profile::Exception::Internal

An internal error has occurred.  If this exception is thrown, it is most likely
due to a bug in the code.

=cut

push @exception_params, (
    'Config::Apple::Profile::Exception::Internal' => {
        description => 'Internal Config::Apple::Profile error',
    },
);


=head2 Config::Apple::Profile::Exception::Key

Thrown when attempting to access a key or index that does not exist.

=cut

push @exception_params, (
    'Config::Apple::Profile::Exception::Key' => {
        description => 'Key or indef not found',
    }
);


=head2 Config::Apple::Profile::Exception::Undef

Thrown when attempting to set a profile key to C<undef>.  Also thrown when
trying to add C<undef> into an array or dict.

This is a subclass of C<Config::Apple::Profile::Exception::Validation>.

=cut

push @exception_params, (
    'Config::Apple::Profile::Exception::Undef' => {
        description => '',
        isa => 'Config::Apple::Profile::Exception::Validation',
    },
);


=head2 Config::Apple::Profile::Exception::Validation

Thrown when attempting to set a profile key to an invalid value.  Also thrown
when trying to add an invalid value to an array or dict.

=cut

push @exception_params, (
    'Config::Apple::Profile::Exception::Validation' => {
        description => 'Invalid value',
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