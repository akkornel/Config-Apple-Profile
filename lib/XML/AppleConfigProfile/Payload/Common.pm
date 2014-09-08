# This is the code for XML::AppleConfigProfile::Payload::Common.
# For Copyright, please see the bottom of the file.

package XML::AppleConfigProfile::Payload::Common;

use 5.14.4;
use strict;
use warnings FATAL => 'all';

use XML::AppleConfigProfile;
our $VERSION = $XML::AppleConfigProfile::VERSION;

use Data::GUID;
use Encode;
use Mac::PropertyList;
use Readonly;
use Regexp::Common;
use Scalar::Util;
use Tie::Hash; # Also gives us Tie::StdHash
use Try::Tiny;
use XML::AppleConfigProfile::Payload::Tie::Root;
use XML::AppleConfigProfile::Payload::Types qw(:all);
use XML::AppleConfigProfile::Targets qw(:all);


=head1 NAME

XML::AppleConfigProfile::Payload::Common - Base class for almost all payload
types, with common payload keys.

=head1 DESCRIPTION

This module serves two purposes.

First, this module contains code to store payload data, to validate
client-provided data, and to export payload data as a plist.

Second, this module defines the payload keys that are common to almost all
payload types.  Specific payload types (classes) will include these common
payload types in their own payload type-specific list.

Ideally, each payload type will be implemented as a class that subclasses this
one, using this class to do all of the work, leaving the subclass to
define the payload keys specific to that subclass.

=head1 CLASS METHODS

=head2 new()

Returns a new object.

=cut

sub new {
    my ($self) = @_;
    my $class = ref($self) || $self;
    
    # The list of payload keys is defined in the class.  Let's make it easy
    # to reference for the instance.
    ## no critic (ProhibitNoStrict)
    no strict 'refs';
    ## use critic
    my $keys = \%{"${class}::payloadKeys"};
    use strict 'refs';
    
    # We're going to leverage Perl's hash-handling code to make payload keys
    # easy for the Perl programmer to access.
    my %payload;
    
    # Prepare out object
    my $object = bless {
        'keys' => $keys,
        'payload' => \%payload,
    }, $class;
    
    # Now that have the object, we can tie up the hash.  YES, this will create
    # a circular reference, which TIEHASH will deal with.
    tie %payload, 'XML::AppleConfigProfile::Payload::Tie::Root', $object;
    
    # Return the prepared object!
    return $object;    
}


=head1 INSTANCE METHODS

=head2 keys()

Returns a hashref that contains the list of payload keys recognized by this
instance.

B<NOTE:>  The hashref points to a hash that is read-only.  Any attempts to
modify will cause your code to die.  You probably want to look at C<payload()>.

=cut

sub keys {
    my ($self) = @_;
    return $self->{keys};
}


=head2 payload()

Returns a hashref that can be used to access the contents of the payload.  This
is a reference to a tied hash, so you can not use it as liberally as a normal
hash.  The only keys that will be accepted are those listed under
L<PAYLOAD KEYS>.

The following exception may be thrown when accessing a hash key:

=over 4

=item XML::AppleConfigProfile::Payload::Common::KeyInvalid

Thrown when attempting to access a payload key that is not valid for this
payload.

=back

If a payload key is valid, but has not been set, then C<undef> is returned.

The following exceptions may be thrown when setting a hash key:

=over 4

=item XML::AppleConfigProfile::Payload::Common::KeyInvalid

Thrown when attempting to access a payload key that is not valid for this
payload.

=item XML::AppleConfigProfile::Payload::Common::ValueInvalid

Thrown when attempting to set an invalid value for this payload key.

=back

You can use C<exists> to test if a particular key is valid for this payload, and
you can use C<defined> to test if a particular key actually has a value defined.
Take note that calling C<defined> with an invalid key name will always return
false.

You can use C<delete> to delete a key, even if that key is required.  Setting
the key's value to C<undef> will do the same thing.

=cut

sub payload {
    my ($self) = @_;
    return $self->{payload};
}


=head2 plist([C<option1_name> => C<option1_value>, ...])

Return a copy of this payload, represented as a L<Mac::Propertylist> object.
All strings will be in UTF-8, and all Data entries will be Base64-encoded.
This method is used when assembling payloads into a profile.

There are two ways to get string output from the plist object:

    # First, get your plist object from the payload
    my $plist = $payload->plist();
    
    # If you just want the <dict> XML element and its contents, do this...
    my $dict_element = $plist->write;
    
    # If you want the complete XML plist, with headers, do this...
    use Mac::PropertyList;
    my $complete_plist = Mac::PropertyList::plist_as_string($plist);

Several options can be provided, which will influence how this method runs.

=over 4

=item target

If C<target> (a value from L<XML::AppleConfigProfile::Targets>) is provided,
then this will be taken into account when exporting.  Only payload keys that
are used on the specified target will be included in the output.

The C<completeness> option controls what happens if keys are excluded.

=item version

If C<version> (a version string) is provided, then only payload keys that work
on the specified version will be included in the output.  

The C<completeness> option controls what happens if keys are excluded.

=item completeness

If C<completeness> is set to a true value, and keys are excluded because of
C<target> or C<version>, then C<plist> will throw an exception.  If set to a
false value, or if not set at all, then no exceptions will be thrown, and a
less-than-complete (but still valid) plist will be returned.

=back

The following exceptions may be thrown:

=over 4

=item XML::AppleConfigProfile::Exception::KeyRequired

Thrown if a required key has not been set.

=item XML::AppleConfigProfile::Exception::Incomplete

Thrown if payload keys are being excluded from the output because of C<target>
or C<version>.

=back

=cut

sub plist {
    my ($self) = @_;
    
    # Prepare a hash that will be turned into the dictionary
    my %dict;
    
    # Go through each key that could exist, and skip the ones that are undef.
    Readonly my $keys => $self->keys();
    Readonly my $payload => $self->payload();
    foreach my $key (CORE::keys($keys)) {
        next unless defined($payload->{$key});
        
        # Look up the key type, and act based on that
        # Also, grab the raw value, and replace it with its plist element
        Readonly my $type => $keys->{$key}->{type};
        my $value = $payload->{$key};
        
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
        
        # Now that we have a $value object, add it to the dictionary hash
        $dict{$key} = $value;
    } # Done going through each payload key
    
    # Now that we have a populated $dict, make our final plist object!
    my $plist = Mac::PropertyList::dict->new(\%dict);
    return $plist;
}

=head2 exportable([C<target>])

Returns true if the payload is complete enough to be exported.  In other words,
all required keys must have values provided.

If C<target> (a value from L<XML::AppleConfigProfile::Targets>) is provided,
then this will be taken into account.  For example, a I<FileVault> payload
will never be exportable to iOS.

=cut

sub exportable {
    ...
}

=head2 _validate($key, $value)

Confirm the value provided is valid for the given payload key, and return a
de-tained copy of C<$value>, or C<undef> if the provided value is invalid. 

C<$key> is the name of the payload key being set, and C<$value> is the proposed
new value.  This class will perform checking for all payload types except for
Data payloads.  The checks performed will be very basic.

Subclasses should override this method to check their keys, and then call
SUPER::_validate($self, $key, $value) to check the remaining keys.

The following exceptions may be thrown:

=over 4

=item XML::AppleConfigProfile::Payload::Common::KeyUnknown

Thrown if the payload key referenced is unknown.

=back

B<NOTE:>  An exception will B<not> be thrown if the value is found to be
invalid.  This is intentional!

B<NOTE:>  To test the result of this method, you should use C<defined>,
because it's possible for a valid value to be false (for example, 0)!

=cut

sub _validate {
    my ($self, $key, $value) = @_;
    
    # Does our payload key exist?
    if (!exists $self->keys()->{$key}) {
        die "Payload key $key is unknown";
    }
    
    # At this point, we would have checks for specific payload keys,
    # but our common keys don't need any special checking.
    
    # Get our payload key's value type
    my $type = $self->keys()->{$key}->{type};
    
    # We recognize String types
    if ($type == $ProfileString) {
        # References aren't allowed here
        ## no critic (ProhibitExplicitReturnUndef)
        return undef if ref($value);
        ##use critic
        
        # Empty strings aren't allowed, either.
        if ($value =~ m/^(.+)$/s) {
            $value = $1;
            
        }
        else {
            ## no critic (ProhibitExplicitReturnUndef)
            return undef;
            ##use critic
        }
        
        # Try to encode as UTF-8, to make sure it's safe
        try {
            encode('UTF-8', $value, Encode::FB_CROAK | Encode::LEAVE_SRC);
        }
        catch {
            $value = undef;
        };
        
        return $value;
    }
    
    # We recognize Number types
    elsif ($type == $ProfileNumber) {
        # References aren't allowed here
        ## no critic (ProhibitExplicitReturnUndef)
        return undef if ref($value);
        ##use critic
        
        # Numbers must be integers, positive or negative (or zero).
        if ($value =~ /^$RE{num}{int}{-keep}$/) {
            return $1;
        }
    }
    
    # We recognize Boolean types
    elsif ($type == $ProfileBool) {
        # References aren't allowed here
        ## no critic (ProhibitExplicitReturnUndef)
        return undef if ref($value);
        ##use critic
        
        # A simple evaluation!
        if ($value) {
            return 1;
        }
        if (!$value) {
            return 0;
        }
    }
    
    # We recognize Data types
    elsif (   ($type == $ProfileData)
           || ($type == $ProfileNSDataBlob)
    ) {
        # How we act here depends if we have a string or a filehandle
        # Let's first check if we were given an open filehandle
        if (Scalar::Util::openhandle($value)) {
            # We've got an open file, so we're good!
            return $value;
        }
        
        # If we don't have an open handle, then make sure it's not an object
        unless (ref($value)) {
            # We have a string.  Let's make sure it's binary, and non-empty.
            if (   (!utf8::is_utf8($value))
                && (length($value) > 0)
            ) {
                # Pull the string into an in-memory file, and return that.
                my ($memory, $file);
                $file = IO::File::new(\$memory, 'w+');
                binmode($file);
                $file->print($value);
                $file->seek(0, 0);
                return $file;
            }
        }
    }
    
    # We recognize Dictionaries
    elsif ($type == $ProfileDict) {
        # As a simple check, look for a hashref
        return $value if ref($value) eq 'HASH';
    }
    
    # We recognize Arrays
    elsif ($type == $ProfileArray) {
        # As a simple check, look for an arrayref
        return $value if ref($value) eq 'ARRAY';
    }
    
    # We recognize arrays of dictionaries
    elsif ($type == $ProfileArrayOfDicts) {
        # First, make sure the outer container is an arrayref
        if (ref($value) eq 'ARRAY') {
            # Make sure each array item is a hashref
            my $all_are_hashrefs = 1;
            foreach my $i (@$value) {
                $all_are_hashrefs = 0 if ref($i) ne 'HASH';
            }
            return $value if $all_are_hashrefs;
        }
    }
    
    # We recognize Identifier types
    elsif ($type == $ProfileIdentifier) {
        # References aren't allowed here
        ## no critic (ProhibitExplicitReturnUndef)
        return undef if ref($value);
        ##use critic
        
        # Empty strings aren't allowed, either.
        if ($value =~ m/^(.+)$/s) {
            my $matched_string = $1;
            # Identifiers are one-line strings
            if (   ($matched_string !~ m/\n/s)
                && ($matched_string =~ m/^$RE{net}{domain}{-nospace}$/)
            ) {
                return $matched_string;
            }
        }
    }
    
    # We recognize UUID types
    elsif ($type == $ProfileUUID) {
        my $class = ref($value);
        my $uuid;
        
        # We accept Data::UUID objects
        if ($class eq 'Data::UUID') {
            $uuid = Data::GUID::from_data_uuid($value);
            return $uuid;
        }
        
        # We accept Data::GUID objects
        if ($class eq 'Data::GUID') {
            return $value;
        }
        
        # We don't accept other kinds of objects
        if ($class ne '') {
            ## no critic (ProhibitExplicitReturnUndef)
            return undef;
            ## use critic
        }
        
        # Have Data::GUID try to parse the input
        # If from_any_string doesn't die, then it wored OK
        eval {
            $uuid = Data::GUID->from_any_string($value);
        };
        return $uuid;
        
        # If we're here, the parsing failed, so just fall through to the end.
    } # Done checking the UUID type
    
    # If we're still here, then something's wrong, so fail.
    ## no critic (ProhibitExplicitReturnUndef)
    return undef;
    ## use critic
} 


=head1 PAYLOAD KEYS

Every payload type has a certain number of common keys.  Those common keys are
defined (not stored) in C<%payloadKeys>.

For general information on payload types, see
L<XML::AppleConfigProfile::Payload::Types>.

=head2 C<PayloadIdentifier>

A C<Identifier> for this specific payload.  It must be unique.

=head2 C<PayloadUUID>

A C<UUID> for this specific payload.  It must be unique.

=head2 C<PayloadDisplayName>

I<Optional>

A C<String> that the user will be able to see when looking at the details of the
profile that is about to be installed.

=head2 C<PayloadDescription>

I<Optional>

A C<String> that the user will be able to see when looking at the details of the
profile that is about to be installed.

=head2 C<PayloadOrganization>

I<Optional>

A C<String> that the user will be able to see when looking at the details of the
profile that is about to be installed.

=head2 C<PayloadType>

A C<Identifier> that identifies which type of payload this is.  This value may
not be set by the client.  Instead, the value is automatically determined based
on which C<XML::AppleConfigProfile::Payload::Types::> class is being used.

=head2 C<PayloadVersion>

A C<Number> that identifies the version of the payload type.  This specifies the
version of the standard, not the client's own revision number.  Right now, all
payload types have a version number of C<1>.

=cut

Readonly our %payloadKeys => (
    'PayloadIdentifier' => {
            type => $ProfileIdentifier,
            description => ('A Java-style reversed-domain-name identifier for'
            . 'this payload.'),
            targets => {
                $TargetIOS => '5.0',
                $TargetMACOSX => '10.7', 
            },
            unique => 1,
        },
    'PayloadUUID' => {
            type => $ProfileUUID,
            description => 'A GUID for this payload.',
            targets => {
                $TargetIOS => '5.0',
                $TargetMACOSX => '10.7', 
            },
            unique => 1,
        },
    'PayloadDisplayName' => {
            type => $ProfileString,
            description => ('A short string that the user will see when '
            . 'installing the profile.'),
            targets => {
                $TargetIOS => '5.0',
                $TargetMACOSX => '10.7', 
            },
            optional => 1,
        },
    'PayloadDescription' => {
            type => $ProfileString,
            description => "A longer description of the payload's purpose.",
            targets => {
                $TargetIOS => '5.0',
                $TargetMACOSX => '10.7', 
            },
            optional => 1,
        },
    'PayloadOrganization' => {
            type => $ProfileString,
            description => "The name of the payload's creator.",
            targets => {
                $TargetIOS => '5.0',
                $TargetMACOSX => '10.7', 
            },
            optional => 1,
        },
);  # End of %payloadKeys


=head1 DEVELOPER NOTES

The following sections have information that will be useful to people working
on the code that makes up this release.

=head2 C<%payloadKeys> contents

The C<%payloadKeys> hash is critical, so it is important to know how it is
constructed.  To start, each key in the hash is a key that appears in a payload.
The value corresponding to the key is a hashref, which can contain the following
keys:

=over 4

=item C<type>

This key's value is a value from L<XML::AppleConfigProfile::Payload::Types>.
It is used to specify the type of data the profile key contains.

The type is used when creating L<Mac::PropertyList> objects, and when doing
value-checking.

=item C<description>

This key's value contains a human-readable description of the profile key.  The
purpose of this is so that client software can easily enumerate profile keys,
such as when making a web application.

=item C<optional>

If this key is present, then this payload key does not have to be present.
This might mean that a key is completely optional (like C<PayloadDescription>),
or it might mean that the value will be auto-generated (like C<PayloadUUID>).

It doesn't matter what this key is set to, its presence is what's important.

Optional checks are done when L<exportable> is run, at the very least.

=item C<unique>

If this key is present, then this payload key's value needs to be unique across
all payloads in the profile.  This is normally used for things like the UUID and
the payload identifier, which need to be unique.

It doesn't matter what this key is set to, its presence is what's important.

Uniqueness checks are done during profile creation time only.

=item C<private>

If this key is present, then this payload key's value is something that should
only be transmitted when the profile is encrypted.  This is meant for things
like passwords, which should not be sent in the clear.

Right now, none of the code in this release does anything with this key.  It is
provided solely for future use.

=item C<value>

If this key is present, then the corresponding value will be used as the value
for the payload key.  Any attempts by the user to change the payload key's value
will throw an exception.

This is used for things like PayloadVersion and PayloadType, which are fixed.

=back

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
