package XML::AppleConfigProfile::Payload::Common;

use 5.14.4;
use strict;
use warnings FATAL => 'all';

use Readonly;
use XML::AppleConfigProfile::Payload::Types qw(:all);
use XML::AppleConfigProfile::Targets qw(:all);



=head1 NAME

C<XML::AppleConfigProfile::Payload::Common> - Methods and keys common to all
payloads

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use XML::Apple::ConfigProfile;

    my $foo = XML::Apple::ConfigProfile->new();
    ...
    
=head1 DESCRIPTION

This module defines keys that are present in all Apple Configuration Profile payloads.

=head1 CLASS METHODS

DSAASADS

=cut

sub new {
    my ($class) = @_;
    
    # We now need to build the list of 
    
    # We're going to leverage Perl's hash-handling code to deal with payload
    # data storage and validation.
    tie %payload, $class;
    
    # Put the payload into an anonymous hash, bless it, and return!
    return bless {
        'payload' => \%payload,
    }, $class;
}


=head1 INSTANCE METHODS

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


=head2 plist([C<target>])

Return a copy of this payload, represented as a L<Mac::Propertylist> object.
All strings will be in UTF-8, and all Data entries will be Base64-encoded.

This method is used when assembling payloads into a profile.  Most clients will
want to use L<string> instead.

If C<target> (a value from L<XML::AppleConfigProfile::Targets>) is provided,
then this will be taken into account.  If a target is not specified, then all
set keys will be exported. 

The following exceptions may be thrown:

=over 4

=item XML::AppleConfigProfile::Payload::Common::PayloadIncomplete

Thrown if a required key has not been set.

=item XML::AppleConfigProfile::Payload::Common::PayloadTarget

Thrown if a payload is being exported to a target that simply does not support
it.  For example, this would be thrown if attempting to export a I<FileVault>
payload for an iOS profile.

=back

=cut

sub plist {
    my ($self) = @_;
    ...
}


=head2 string([C<target>])

Return a copy of this payload, represented as a UTF-8 string.

This method may be of most interest to clients that are putting together their
own profile.

If C<target> (a value from L<XML::AppleConfigProfile::Targets>) is provided,
then this will be taken into account.  If a target is not specified, then all
set keys will be exported. 

The following exceptions may be thrown:

=over 4

=item XML::AppleConfigProfile::Payload::Common::PayloadIncomplete

Thrown if a required key has not been set.

=item XML::AppleConfigProfile::Payload::Common::PayloadTarget

Thrown if a payload is being exported to a target that simply does not support
it.  For example, this would be thrown if attempting to export a I<FileVault>
payload for an iOS profile.

=back

=cut

sub string {
    my ($self) = @_;
    
    # Mac::PropertyList can give us a string, so we'll just defer to that!
    # All of our exceptions will be thrown by the call to plist().
    return $self->plist()->write();
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


=head1 PAYLOAD KEYS

Every payload type has a certain number of common keys.  Those common keys are
defined (not stored) in C<%payloadKeys>.

For general information on payload types, see
L<XML::AppleConfigProfile::Payload::Types>.

=cut

Readonly our %payloadKeys => (

=head2 C<PayloadIdentifier>

A C<Identifier> for this specific payload.

=cut

    'PayloadIdentifier' => {
            type => $ProfileIdentifier,
        },

=head2 C<PayloadUUID>

A C<UUID> for this specific payload.

=cut

    'PayloadUUID' => {
            type => $ProfileUUID,
        },
        
=head2 C<PayloadDisplayName>

A C<String> that the user will be able to see when looking at the details of the
profile that is about to be installed.

=cut

    'PayloadDisplayName' => {
            type => $ProfileString,
            optional => 1,
        },
        
=head2 C<PayloadDescription>

A C<String> that the user will be able to see when looking at the details of the
profile that is about to be installed.

=cut

    'PayloadDescription' => {
            type => $ProfileString,
            optional => 1,
        },
        
=head2 C<PayloadOrganization>

A C<String> that the user will be able to see when looking at the details of the
profile that is about to be installed.

=cut

    'PayloadOrganization' => {
            type => $ProfileString,
            optional => 1,
        },

=head2 C<PayloadType>

A C<Identifier> that identifies which type of payload this is.  This value may
not be set by the client.  Instead, the value is automatically determined based
on which C<XML::AppleConfigProfile::Payload::Types::> class is being used.

=head2 C<PayloadVersion>

A C<Number> that identifies the version of the payload type.  This specifies the
version of the standard, not the client's own revision number.  Right now, all
payload types have a version number of C<1>.

=cut

);  # End of %payloadKeys


# All internal stuff goes here

sub TIEHASH {
    my ($class) = @_;
    return bless {}, $class;
}


sub FETCH {
    my ($self, $key) = @_;
    ...
}


sub STORE {
    my ($self, $key, $value) = @_;
    ...
}


sub DELETE {
    my ($self, $key) = @_;
    delete $self->{payload}->{$key};
}


sub CLEAR {
    my ($self) = @_;
    ...
}


sub EXISTS {
    my ($self, $key) = @_;
    ...
}


sub FIRSTKEY {
    my ($self) = @_;
    ...
}


sub NEXTKEY {
    my ($self, $previous) = @_;
    ...
}


sub SCALAR {
    my ($self) = @_;
    ...
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