# This is the code for Config::Apple::Profile::Payload::Types::Serialize.
# For Copyright, please see the bottom of the file.

package Config::Apple::Profile::Payload::Types::Serialize;

use 5.10.1;
use strict;
use warnings FATAL => 'all';

our $VERSION = '0.87';

use DateTime;
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
use Config::Apple::Profile::Payload::Types qw(:all);


=encoding utf8

=head1 NAME

Config::Apple::Profile::Payload::Types::Serialize - Convert common payload
types to plist form.


=head1 DESCRIPTION

This module contains code that is used to convert common payload types into
plist form.


=head1 FUNCTIONS

=head2 serialize

    my $plist_fragment = serialize($type, $value, [$subtype]);

Given C<$value>, returns a C<Mac::PropertyList> object containing the contents
of C<$value>.  C<$type> must be one of the types listed in
L<Config::Apple::Profile::Payload::Types>, and is used to identify which type
of plist item to create (string, number, array, etc.).

If C<$type> is C<$ProfileArray> or C<$ProfileDict>, then C<$subtype> must be
defined.  C<serialize> will recurse into the structure, serialize it, and then
put everything into the appropriate plist array or dictionary, which will be
returned.  C<$subtype> is used to tell C<serialize> what type of data is being
used within the array or dictionary.

If C<$type> is C<$ProfileClass>, then C<< $value->plist >> will be called,
and the result will be returned.

An exception will be thrown if C<$type> or C<$subtype> are not recognized.

=cut

sub serialize {
    my ($type, $value, $subtype) = @_;
    
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
    
    # Reals are similarly easy, but use an uppercase E
    elsif ($type == $ProfileReal) {
        $value = Mac::PropertyList::real->new(uc($value));
    }
    
    # All data is Base64-encoded for us by Mac::PropertyList
    elsif (   ($type == $ProfileData)
           || ($type == $ProfileNSDataBlob)
    ) {
        # Slurp the file, and then hand it over
        local $/ = undef;
        $value = <$value>;
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
    
    # Date
    elsif ($type == $ProfileDate) {
        # Set the time zone to UTC, make a string, and plist that
        $value->set_time_zone('UTC');
        my $string = $value->ymd . 'T' . $value->hms . 'Z';
        $value = Mac::PropertyList::date->new($string);
    }
    
    # UUIDs are converted to strings, then processed as such
    elsif ($type == $ProfileUUID) {
        $value = Mac::PropertyList::string->new(
            Encode::encode('UTF-8', $value->as_string())
        );
    }
    
    # For arrays, make a Perl array of fragments, then plist that
    elsif ($type == $ProfileArray) {
        my @array;
        
        # Go through each array item, serialize it, and add it to our array
        foreach my $item (@$value) {
            push @array, serialize($subtype, $item, undef);
        }
        
        $value = Mac::PropertyList::array->new(\@array);
    }
    
    # For dictionaries, make a Perl hash of fragments, then plist that
    elsif ($type == $ProfileDict) {
        my %hash;
        
        # Go through each hash key, serialize it, and add it to our array
        foreach my $key (keys %$value) {
            $hash{$key} = serialize($subtype, $value->{$key}, undef);
        }
        
        $value = Mac::PropertyList::dict->new(\%hash);
    }
    
    # For classes, let the object plist itself
    elsif ($type == $ProfileClass) {
        $value = $value->plist;
    }
    
    # We've checked all the types we know about
    else {
        die "Unknown type $type";
    }
    
    return $value;
}




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
