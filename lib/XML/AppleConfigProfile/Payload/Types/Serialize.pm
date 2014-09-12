# This is the code for XML::AppleConfigProfile::Payload::Types::Serialize.
# For Copyright, please see the bottom of the file.

package XML::AppleConfigProfile::Payload::Types::Serialize;

use 5.14.4;
use strict;
use warnings FATAL => 'all';

our $VERSION = '0.00_001';

use Encode qw(encode);
use Exporter::Easy (
    OK => [qw(
        serialize
    )],
    TAGS => [
        'all' => [qw(
            serialize
        )],
    ],
);
use Mac::PropertyList;
use XML::AppleConfigProfile::Payload::Types qw(:all);


=head1 NAME

XML::AppleConfigProfile::Payload::Types::Serialize - Convert common payload
types to plist form


=head1 DESCRIPTION

This module contains code that is used to convert common payload types into
plist form.


=head1 FUNCTIONS

=head2 serialize

    my $plist_fragment = serialize($type, $value);

Given C<$value>, returns a C<Mac::PropertyList> object containing the contents
of C<$value>.  C<$type> must be one of the types listed in
L<XML::AppleConfigProfile::Payload::Types>, and is used to identify which type
of plist item to create (string, number, array, etc.).

If C<$type> is C<$ProfileArray> or C<$ProfileDict>, C<serialize> will recurse
into the structure, serialize it, and then put everything into the appropriate
plist array or dict, which will be returned.

If C<$type> is C<$ProfileClass>, then C<< $value->plist >> will be called,
and the 

An exception will be thrown if C<$type> is not recognized.

=cut

sub serialize {
    my ($type, $value) = @_;
    
        # Strings need to be encoded as UTF-8 before export
        if (   ($type == $ProfileString)
            || ($type == $ProfileIdentifier)
        ) {
            $value = Mac::PropertyList::string->new(
                Encode::encode('UTF-8', $value)
            );
        }
        
        # Numbers are easy
        elsif ($type == $ProfileNumber) {
            $value = Mac::PropertyList::integer->new($value);
        }
        
        # All data is Base64-encoded for us by Mac::PropertyList
        elsif ($type == $ProfileData) {
            $value = Mac::PropertyList::data->new($value);
        }
        
        # There are separate objects for true/false booleans
        elsif ($type == $ProfileBool) {
            if ($value) {
                $value = Mac::PropertyList::true->new;
            }
            else {
                $value = Mac::PropertyList::false->new;
            }
        }
        
        # UUIDs are converted to strings, then processed as such
        elsif ($type == $ProfileUUID) {
            $value = Mac::PropertyList::string->new(
                Encode::encode('UTF-8', $value->as_string())
            );
        }
        
        return $value;
}




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
