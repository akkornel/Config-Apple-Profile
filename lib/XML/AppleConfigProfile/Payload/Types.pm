package XML::AppleConfigProfile::Payload::Types;

use 5.14.4;
use strict;
use warnings FATAL => 'all';

use Exporter::Easy (
    OK => [qw(
        ProfileString ProfileNumber ProfileData ProfileBool
        ProfileDict ProfileArray ProfileArrayOfDicts
        ProfileNSDataBlob ProfileGUID ProfileIdentifier
    )],
    TAGS => [
        'all' => [qw(
          ProfileString ProfileNumber ProfileData ProfileBool
          ProfileDict ProfileArray ProfileArrayOfDicts
          ProfileNSDataBlob ProfileGUID ProfileIdentifier
        )],
    ],
);
use Readonly;


=head1 NAME

C<XML::AppleConfigProfile::Payload::Types> - Data types for payload keys

=head1 DESCRIPTION

Apple Configuration Profiles contain one or more I<payloads>.  Each payload
contains a dictionary, which can be thought of like a Perl hash.  Within a
payload's dictionary, each key's value is restricted to a specific type.
One key might require a number; a different key might require a string, or some
binary data.

Provided in this module are a number of Readonly scalars that will be used
(instead of strings) to identify the data types for configuration profile keys.
The scalars are all OK for import into your local namespace, or you can simply
import C<:all> to get all of them at once. 

=head1 TYPES

Apple Configuration Profile payloads use the following data types:

=head2 C<ProfileString>

A UTF-8 string.  The client should simply provide a Perl string (NOT a binary
string).

=cut

Readonly our $ProfileString => 1;

=head2 C<ProfileNumber>

A real number or an integer.

=cut

Readonly our $ProfileNumber => 2;

=head2 C<ProfileData>

Binary data.  The client should always expect (and provide) data in binary form,
and the module will do the work of converting to Base64 when necessary.

=cut

Readonly our $ProfileData => 3;

=head2 C<ProfileBool>

Either True for False.  When reading a boolean from a payload's contents, a 1
is used to represent true, and 0 is returned for false.  When setting a boolean,
the value provided is filtered using the code C<($value) ? 1 : 0>.

=cut

Readonly our $ProfileBool => 4;

=head2 C<ProfileDict> (Dictionary)

A dictionary is the plist equivalent to a Perl hash, and that is what will be
made available.  The client should expect the hash to only accept certain types
of C<XML::AppleConfigProfile::Payload::> modules.  For more information, see the
documentation for the specific key.

=cut

Readonly our $ProfileDict => 10;

=head2 C<ProfileArray>

An array, similar to a Perl array.  The client should expect the array to only
accept certain data types.  For more information, see the documentation for the
specific key.

=cut

Readonly our $ProfileArray => 11;

=head2 C<ProfileArrayOfDicts> (Array of Dictionaries)

An array of dictionaries, equivalent to a Perl array of hashes (or, more
realisticly, an array of hashrefs).  The client should expect the array to only
accept certain types of C<XML::AppleConfigProfile::Payload::> modules.
For more information, see the documentation for the specific key.

=cut

Readonly our $ProfileArrayOfDicts => 12;

=head2 NSData Blob

This is a weird type.  The only place it appears in the I<Configuration Profile
Reference> (the edition dated 2014-03-20) is in the C<Certificate> key in the
Exchange payload.  I don't really understand this, though I'm guessing it's
really a Data type, and the I<NSData Blob> is referring to the contents.

Until I get more information on what exactly this is, this type will likely go
unimplemnented.

=cut

Readonly our $ProfileNSDataBlob => 20;

=head2 C<ProfileUUID>

I<Also known as a GUID>

Although the plist format does not have a special type for UUIDs (a simple
String is used), these modules designate a special type for UUIDs, as a
convenience to the client:  All payloads have a UUID as one of the required
keys.  If the client does not specify a UUID when creating a payload, then
one will be lazily auto-generated.

=cut

Readonly our $ProfileUUID => 21;

=head2 C<ProfileIdentifier>

This is another convenience type.  All payloads require an identifier,
which is a reverse-DNS-style (Java-style) string.  If the client does not
specify an identifier, then one will be lazily auto-generated.  If the client
specifies an identifier starting with a dot (such as 'C<.VPNconfig>'), the
parent's identifier will be lazily prepended.

=cut

Readonly our $ProfileIdentifier => 22;


=head1 ACKNOWLEDGEMENTS

Refer to the L<XML::AppleConfigProfile> for acknowledgements.

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