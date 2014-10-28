# This is the code for Config::Apple::Profile::Payload::Tie::Dict.
# For Copyright, please see the bottom of the file.

package Config::Apple::Profile::Payload::Tie::Dict;

use 5.10.1;
use strict;
use warnings FATAL => 'all';

our $VERSION = '0.87.1';

use Scalar::Util qw(blessed);
use Tie::Hash; # Also gives us Tie::StdHash


=encoding utf8

=head1 NAME

Config::Apple::Profile::Payload::Tie::Dict - Tying class for dictionaries
of things.

=head1 DESCRIPTION

This class is used to store a dictionary (a I<dict>) of I<things>.  Exactly
what I<things> are being stored is specified at the time the tie is made.

There are several payload types that contain dicts of things.  For example,
if you have a Wi-Fi network that uses WPA- or WPA2-Enterprise, then some form
of EAP will be used, and the EAP parameters are stored in a dictionary.

This class is used by payload classes to represent a dictionary.

=cut

=head2 "CLASS" METHODS

=head3 tie %hash, 'Config::Apple::Profile::Payload::Tie::Dict', $validator

When this class is tied to an hash, C<TIEHASH> will be called, with the class
name as the first argument.

C<$validator> is a reference to a function that will be able to validate
values that are stored in the dict.  The validator will be passed the value as
the only parameter, and an untained value is expected as the return value.
If C<undef> is returned by the validator, then the value was invalid, and the
store attempt will fail.

It is suggested that the functions from
L<Config::Apple::Profile::Payload::Types::Validation> be used.

If C<$validator> is not a valid coderef then an exception will be thrown.

=cut

sub TIEHASH {
    my ($class, $validator) = @_;
    
    # This is what we'll eventually return
    my %object;
    
    # We'll still have an array, for convenience
    $object{dict} = {};
    
    # We don't accept refs, only scalars
    if (ref $validator ne 'CODE') {
        die "Validator must be a function reference";
    }
    $object{validator} = $validator;

    return bless \%object, $class;
}


=head3 FETCH

Works as one would expect with a Perl hash.  Returns the entry matching the
specified key.

=cut

sub FETCH {
    my ($self, $key) = @_;
    
    return $self->{hash}->{$key};
}


=head3 STORE

Works almost as one would expect with a Perl hash.  Stores a value at the
specified key.  The value will only be stored if it is valid; otherwise an
exception will be thrown.  C<undef> is not a valid value to store.

=cut

sub STORE {
    my ($self, $key, $value) = @_;
    
    # Call the validation routine
    # If the validated value is undef, it was invalid
    my $validated_value = $self->{validator}->($value);
    if (!defined $validated_value) {
        die "Attempting to insert invalid value";
    }
    
    $self->{hash}->{$key} = $self->{validator}->($validated_value);
}


=head3 delete

Works as one would expect with a Perl hash.  Deletes the specified key from
the hash.

=cut

sub DELETE {
    my ($self, $key) = @_;
    delete $self->{hash}->{$key};
}


=head3 clear

Works as one would expect with a Perl hash.  Deletes all keys from the hash.

=cut

sub CLEAR {
    my ($self) = @_;
    $self->{hash} = {};
}


=head3 exists

Works as expected for a Perl hash.  Returns true if the specified key exists
in the hash.

=cut

sub EXISTS {
    my ($self, $key) = @_;
    return exists $self->{hash}->{$key};
}


=head3 FIRSTKEY

Used as part of C<keys()> and C<each()>.  Works as expected for a Perl hash.
Returns the first key in the hash.

=cut

sub FIRSTKEY {
    my ($self) = @_;
    # Let's defer to Tie::StdHash for this.
    return Tie::StdHash::FIRSTKEY($self->{hash});
}


=head3 NEXTKEY

Used as part of C<keys()> and C<each()>.  Works as expected for a Perl hash.
Returns the next key in the hash.

=cut

sub NEXTKEY {
    my ($self, $lastkey) = @_;
    # Let's defer to Tie::StdHash for this.
    return Tie::StdHash::NEXTKEY($self->{hash});
}


=head3 scalar

Works as expected, returning the number of keys in the hash.

=cut

sub SCALAR {
    my ($self) = @_;
    return scalar %{$self->{hash}};
}


=head1 ACKNOWLEDGEMENTS

Refer to L<Config::Apple::Profile> for acknowledgements.

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