# This is the code for Config::Apple::Profile::Payload::Common.
# For Copyright, please see the bottom of the file.

package Config::Apple::Profile::Payload::Common;

use 5.10.1;
use strict;
use warnings FATAL => 'all';

our $VERSION = '0.87';

use Data::GUID;
use Encode;
use Mac::PropertyList;
use Readonly;
use Scalar::Util;
use Tie::Hash; # Also gives us Tie::StdHash
use Try::Tiny;
use version 0.77; 
use Config::Apple::Profile::Payload::Tie::Root;
use Config::Apple::Profile::Payload::Types qw(:all);
use Config::Apple::Profile::Payload::Types::Serialize qw(serialize);
use Config::Apple::Profile::Payload::Types::Validation;
use Config::Apple::Profile::Targets qw(:all);


=encoding utf8

=head1 NAME

Config::Apple::Profile::Payload::Common - Base class for almost all payload
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
    tie %payload, 'Config::Apple::Profile::Payload::Tie::Root', $object;
    
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

=item Config::Apple::Profile::Payload::Common::KeyInvalid

Thrown when attempting to access a payload key that is not valid for this
payload.

=back

If a payload key is valid, but has not been set, then C<undef> is returned.

The following exceptions may be thrown when setting a hash key:

=over 4

=item Config::Apple::Profile::Payload::Common::KeyInvalid

Thrown when attempting to access a payload key that is not valid for this
payload.

=item Config::Apple::Profile::Payload::Common::ValueInvalid

Thrown when attempting to set an invalid value for this payload key.

=back

You can use C<exists> to test if a particular key is valid for this payload, and
you can use C<defined> to test if a particular key actually has a value defined.
Take note that calling C<defined> with an invalid key name will always return
false.

You can use C<delete> to delete a key.

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

Several parameters can be provided, which will influence how this method runs.

=over 4

=item target

If C<target> (a value from L<Config::Apple::Profile::Targets>) is provided,
then this will be taken into account when exporting.  Only payload keys that
are used on the specified target will be included in the output.

The C<completeness> option controls what happens if keys are excluded.

=item version

If C<version> (a version string) is provided, then only payload keys that work
on the specified version will be included in the output.

If C<version> is provided, then C<target> must also be set, but C<target> can
be set without setting C<version>.

The C<completeness> option controls what happens if keys are excluded.

=item completeness

If C<completeness> is set to a true value, and keys are excluded because of
C<target> or C<version>, then C<plist> will throw an exception.  If set to a
false value, or if not set at all, then no exceptions will be thrown, and a
less-than-complete (but still valid) plist will be returned.

=back

The following exceptions may be thrown:

=over 4

=item Config::Apple::Profile::Exception::KeyRequired

Thrown if a required key has not been set.

=item Config::Apple::Profile::Exception::Incomplete

Thrown if payload keys are being excluded from the output because of C<target>
or C<version>.

=back

=cut

sub plist {
    my $self = $_[0];
    
    # Process parameters
    my %params;
    for (my $i = 1; $i < scalar(@_); $i += 2) {
        my ($name, $value) = @_[$i,$i+1];
        
        # We have three parameters possible.  Process each one
        if ($name eq 'target') {
            unless (   ($value == $TargetIOS)
                    || ($value == $TargetMACOSX)
            ) {
                die "Invalid target $value";
            }
            $params{target} = $value;
        }
        
        elsif ($name eq 'version') {
            try {
                $params{version} = version->parse($value);
            }
            catch {
                die "Failed to parse version $value";
            }
        }
        
        elsif ($name eq 'completeness') {
            $params{completeness} = ($value ? 1 : 0);
        }
    } # Done inputting parameters
    
    # Catch someone setting version without setting target
    if (   (exists $params{version})
        && (!exists $params{target})
    ) {
        die "Version has been set, but no target was provided";
    }
    
    # We're done with parameter processing and validation; do some work!
    
    # Prepare a hash that will be turned into the dictionary
    my %dict;
    
    # Go through each key that could exist, and skip the ones that are undef.
    Readonly my $keys => $self->keys();
    Readonly my $payload => $self->payload();
    foreach my $key (CORE::keys(%$keys)) {
        # If the key isn't set, then skip it
        next unless defined($payload->{$key});
        
        # If target has been set, check it against the key's target
        if (exists $params{target}) {
            if (!exists($keys->{$key}->{targets}->{$params{target}})) {
                # This key isn't used on this target, should we die?
                if (   (exists($params{completeness}))
                    && ($params{completeness})
                ) {
                    die "Key $key has been set, but isn't supported on this target";
                }
                
                # If we're here, this key isn't used on this target, but we
                # shouldn't die, so just skip the key.
                next;
            }
            
            # If we're here, this key is used on this target; check the version!
            my $key_version = $keys->{$key}->{targets}->{$params{target}};
            if (   (exists($params{version}))
                && ($params{version} < version->parse($key_version))
            ) {
                # This key is too new for us, should we die?
                if (   (exists($params{completeness}))
                    && ($params{completeness})
                ) {
                    die "Key $key is only supported in newer OS versions";
                }
                
                # If we're here, this key is too new for us, but we shouldn't
                # die, so just skip the key.
                next;
            }
            
            # If we're here, then the version isn't set, or we're new enough!
        } # Done checking target & version
        
        # Serialize the payload contents as a plist fragment, and store
        $dict{$key} = serialize($keys->{$key}->{type}, 
                                $payload->{$key},
                                $keys->{$key}->{subtype} || undef
        );
    } # Done going through each payload key
    
    # Now that we have a populated $dict, make our final plist object!
    my $plist = Mac::PropertyList::dict->new(\%dict);
    return $plist;
}


=head2 populate_id()

Populates the C<PayloadIdentifier> and C<PayloadUUID> fields, if they are not
already set.  In addition, if the payload has any keys of type
C<$PayloadClass>, then C<populate_id> will also be called on them.

Sub-classes may decide to override this, so as to add extra functionality.

=cut

sub populate_id {
    my ($self) = @_;
    
    my $keys = $self->keys;
    my $payload = $self->payload;
    
    # Go through each key, and check the type
    foreach my $key (CORE::keys %$keys) {
        my $type = $keys->{$key}->{type};
        
        # We can call this method on other classes
        if (   ($type !~ m/^\d+$/)
            || ($type == $ProfileClass)
        ) {
            # Only populate IDs on objects that exist
            if (defined $payload->{$key}) {
                my $object = $payload->{$key};
                $object->populate_id();
            }
        }

        # We can fill in UUIDs
        elsif ($type == $ProfileUUID) {
            if (!defined $payload->{$key}) {
                # Make a new (random) GUID
                $payload->{$key} = new Data::GUID;
            }
        }
        
        # We can fill in identifiers
        elsif ($type == $ProfileIdentifier) {
            if (!defined $payload->{$key}) {
                # Just make some simple random identifier
                $payload->{$key} = 'payload' . int(rand(2**30));
            }
        }
        
        # If we have an array of objects, we can do them, too!
        elsif (   ($type == $ProfileArray)
               && (   $keys->{$key}->{subtype} !~ m/^\d+$/
                   || $keys->{$key}->{subtype} == $ProfileClass
                  )
        ) {
            foreach my $item (@{$payload->{$key}}) {
                $item->populate_id();
            }
        }
        
        # If we have an dictionary of objects, we can do them, also!
        elsif (   ($type == $ProfileDict)
               && (   $keys->{$key}->{subtype} !~ m/^\d+$/
                   || $keys->{$key}->{subtype} == $ProfileClass
                  )
        ) {
            foreach my $item (CORE::keys %{$payload->{$key}}) {
                $payload->{$key}->{$item}->populate_id();
            }
        }
        
        # That's it!  Move on to the next key
    }
}


=head2 exportable([C<target>])

Returns true if the payload is complete enough to be exported.  In other words,
all required keys must have values provided.

C<exportable()> will return false if all UUID and Identifier fields are not
filled in, so it is suggested that you call C<populate_id()> before calling
C<exportable()>.

=cut

sub exportable {
    my ($self, $target) = @_;
    
    my $keys = $self->keys;
    my $payload = $self->payload;
    
    # Let's look for all keys that are required
    foreach my $key (CORE::keys %$keys) {
        next if exists $keys->{$key}->{optional};
        
        my $type = $keys->{$key}->{type};
        
        # If the key is a class and has been set, call ->exportable() on it.
        # If the call returns 0, then we are not exportable.
        return 0 if (   ($type == $ProfileClass)
                     && (defined $payload->{$key})
                     && ($payload->{$key}->exportable() == 0)
        );
        
        # Special handling is needed for a required array
        if ($type == $ProfileArray) {
            return 0 if scalar(@{$payload->{$key}}) == 0;
            
            # If we have an array of classes, make sure each entry is exportable
            if ($keys->{$key}->{subtype} == $ProfileClass) {
                foreach my $entry (@{$payload->{$key}}) {
                    return 0 if ($entry->exportable == 0);
                }
            }
        }
        
        # Special handling is needed for a required dictionary
        if ($type == $ProfileDict) {
            return 0 if scalar(CORE::keys %{$payload->{$key}}) == 0;
            
            # If we have a dict of classes, make sure each entry is exportable
            if ($keys->{$key}->{subtype} == $ProfileClass) {
                foreach my $entry (CORE::keys %{$payload->{$key}}) {
                    return 0 if ($entry->exportable == 0);
                }
            }
        }
        
        # For every other key, return 0 if we are required but not set
        return 0 unless defined $payload->{$key};
        
        # At this point, the key is required, and is defined, so we're good!
    } # Done checking this key
    
    # If we've checked all the keys, and they're OK, then we're good!
    return 1;
}


=head2 validate_key($key, $value)

Confirm the value provided is valid for the given payload key, and return a
de-tained copy of C<$value>, or C<undef> if the provided value is invalid. 

C<$key> is the name of the payload key being set, and C<$value> is the proposed
new value.  This class will perform checking for all payload types except for
Data payloads.  The checks performed will be very basic.

Subclasses should override this method to check their keys, and then call
SUPER::validate_key($self, $key, $value) to check the remaining keys.

The following exceptions may be thrown:

=over 4

=item Config::Apple::Profile::Payload::Common::KeyUnknown

Thrown if the payload key referenced is unknown.

=back

B<NOTE:>  An exception will B<not> be thrown if the value is found to be
invalid.  This is intentional!

B<NOTE:>  To test the result of this method, you should use C<defined>,
because it's possible for a valid value to be false (for example, 0)!

=cut

sub validate_key {
    my ($self, $key, $value) = @_;
    
    # Does our payload key exist?
    if (!exists $self->keys()->{$key}) {
        die "Payload key $key is unknown";
    }
    
    # At this point, we would have checks for specific payload keys,
    # but our common keys don't need any special checking.
    
    # Get our payload key's value type
    my $type = $self->keys()->{$key}->{type};
    
    # If the payload key is an Array or a Dict, then we're actually checking
    # the subtype of the key, not the type.
    if (   ($type == $ProfileArray)
        || ($type == $ProfileDict)
    ) {
        $type = $self->keys()->{$key}->{subtype};
    }
    
    # If we are working with a basic type, then call the basic validator!
    if (   ($type == $ProfileString)
        || ($type == $ProfileNumber)
        || ($type == $ProfileReal)
        || ($type == $ProfileBool)
        || ($type == $ProfileData)
        || ($type == $ProfileDate)
        || ($type == $ProfileNSDataBlob)
        || ($type == $ProfileDict)
        || ($type == $ProfileArray)
        || ($type == $ProfileIdentifier)
        || ($type == $ProfileUUID)
    ) {
        return Config::Apple::Profile::Payload::Types::Validation::validate($type, $value);
    }
    
    # If we're still here, then something's wrong, so fail.
    ## no critic (ProhibitExplicitReturnUndef)
    return undef;
    ## use critic
} 


=head1 PAYLOAD KEYS

Every payload type has a certain number of common keys.  Those common keys are
defined (not stored) in C<%payloadKeys>.

For general information on payload types, see
L<Config::Apple::Profile::Payload::Types>.

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
on which C<Config::Apple::Profile::Payload::Types::> class is being used.

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

This key's value is a value from L<Config::Apple::Profile::Payload::Types>.
It is used to specify the type of data the profile key contains.

The type is used when creating L<Mac::PropertyList> objects, and when doing
value-checking.

If a payload class uses <$ProfileClass> as a type, then the payload class is
responsible for providing an instance method named C<construct>, which takes
the payload key name as its only parameter, and returns a new object.

This key must be present.

=item C<subtype>

This key is required when C<type> is set to C<$ProfileDict> or C<$ProfileArray>.

If C<type> is set to C<$ProfileDict>, then C<subtype> contains the type of
data stored as values.  That data type will be used for validation, when
entries are added to the Perl hash representing the dictionary.

If C<type> is set to C<$ProfileArray>, then C<subtype> contains the type of
data stored in the array.  That data type will be used for validation, when
entries are added to the Perl array.

If a payload class uses <$ProfileClass> as a subtype, then the payload class is
responsible for providing an instance method named C<construct>, which takes
the payload key name as its only parameter, and returns a new object.

For other values of the C<type> key, this key must I<not> be present.

=item C<description>

This key's value contains a human-readable description of the profile key.  The
purpose of this is so that client software can easily enumerate profile keys,
such as when making a web application.

This key must be present.

=item C<targets>

This key's value is a hashref.  Within the hashref, the keys are platform
identifiers, scalars taken from C<Config::Apple::Profile::Targets>.  The value
for each key is a version object representing the earliest version of the
named platform's OS which supports this payload key.

If a platform does not support a particular key at all, that platform should not
be included in the hashref.

This key must be present, and the hashref must contain at least one entry.

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
