package Config::Apple::Profile::Targets;

use 5.10.1;
use strict;
use warnings FATAL => 'all';

our $VERSION = '0.87.1';

use Exporter::Easy (
    OK => [qw(
        $TargetIOS $TargetMACOSX
    )],
    TAGS => [
        'all' => [qw(
            $TargetIOS $TargetMACOSX
        )],
    ],
);
use Readonly;


=encoding utf8

=head1 NAME

Config::Apple::Profile::Targets - Constants for payload targets

=head1 DESCRIPTION

Apple Configuration Profiles can be used on different platforms.  Although some
payloads only work on specific platforms, most payloads can be at least
partially applied to all platforms that support Apple Configuration Profiles.

Provided in this module are a number of read-only scalars that will be used
(instead of strings) to identify the platforms supported by configuration
profiles.  The scalars are all OK for import into your local namespace, or you
can simply import C<:all> to get all of them at once. 

=head1 TYPES

Apple Configuration Profiles can be targeted to the following platforms:

=head2 iOS C<$TargetIOS>

Apple's iOS.  In general, at least iOS version 5.0 is required.

=cut

Readonly our $TargetIOS => 1;

=head2 Mac OS X C<$TargetOSX>

Apple's Mac OS X.  In general, at least OS X version 10.7 is required.

=cut

Readonly our $TargetMACOSX => 2;


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