# This is the code for XML::AppleConfigProfile::Payload::Tie::Root.
# For Copyright, please see the bottom of the file.

package XML::AppleConfigProfile::Payload::Tie::Root;

use 5.14.4;
use strict;
use warnings FATAL => 'all';

our $VERSION = '0.00_001';

use Tie::Hash; # Also gives us Tie::StdHash


=head1 NAME

XML::AppleConfigProfile::Payload::Tie::Root - Tying class for payload storage.

=head1 DESCRIPTION

This class is used to store the payload keys, and their values, for each of the
payload classes under C<XML::AppleConfigProfile::Payload::>.

In the configuration profile XML, each payload is represented by a series of
keys and their values.  This matches up fairly well with a Perl hash, so that
is the mechanism that was chosen for actually getting (and messing with) the
data in a payload class!

This class is used directly only by L<XML::AppleConfigProfile::Payload::Common>,
and acts as storage for the payload keys.  Subclasses are involved indirectly,
by providing their own list of payload keys, either replacing or supplementing
the list from C<XML::AppleConfigProfile::Payload::Common>.

=cut

=head2 "CLASS" METHODS

=head2 tie %hash, 'XML::AppleConfigProfile::Payload::Tie::Root', $self

This method is not useful in client code, but it is documented for future
developers of this software.

When this class is used to tie a hash, C<TIEHASH> will be called, with the class
name as the first argument.  The second argument is expected to be a reference
to the object that will be containing this tied hash.  The containing object
needs to implement two methods:

=over 4

=item _validate($key, $value)

C<_validate> needs to return, if the value is valid, the de-tainted value.  If
the value is not valid, then C<undef> must be returned.

=item keys()

C<keys> needs to return a reference to the hash of payload keys, as defined in
L<XML::AppleConfigProfile::Payload::Common>.  No attempts will be made to modify
the hash, so it can (and should) be read-only.

=back

Since the second argument is a reference pointing back to the object which
contains us, we are introducing a circular reference.  We take responsibility
for "weakening" the reference provided to us.

=cut

sub TIEHASH {
    my ($class, $object_ref) = @_;
    
    # $object_ref points to our containing object.  In other words, $object_ref,
    # if de-referenced, would give us our instance of this class.
    # Using $object_ref around like this does, I believe, create a circular
    # reference, which we need to break.
    Scalar::Util::weaken($object_ref);
    
    # Construct our object.  We need a hash for the payload, and we'll also
    # bring along the reference to our containing instance.
    # Our class name is made-up, to keep clients from doing weird stuff.
    return bless {
        payload => {},
        object => $object_ref,
    }, "$class";
}


=head2 FETCH

Works as one would expect with a Perl hash.  Either the value is returned, or
C<undef> is returned.  Exactly I<what> you get depends on the payload class and
the key you are accessing.  For more details, check the payload class
documentation, as well as L<XML::AppleConfigProfile::Payload::Types>.

=cut

sub FETCH {
    my ($self, $key) = @_;
    
    # Our EXISTS check returns true if the key is a valid payload key name.
    # Therefore, we need to do our own exists check, and possible return undef.
    if (exists $self->{payload}->{$key}) {
        return $self->{payload}->{$key};
    }
    else {
        ## no critic (ProhibitExplicitReturnUndef)
        return undef;
        ## use critic
    }
}


=head2 STORE

Works I<almost> as one would expect with a Perl hash.  When setting a value to
a key, two checks are performed:

=over 4

=item *

The key must be a valid payload key name for this payload class.

=item *

The value must be a valid value for the given payload key.

=back

Exactly what validation is performed depends first on the type of value (be it
a string, a boolean, data, etc.), and next on any special validation performed
by the payload class itself.  For more details, check the payload class
documentation, as well as L<XML::AppleConfigProfile::Payload::Types>.

If the validation fails, the program dies.

=cut

sub STORE {
    my ($self, $key, $value) = @_;
    
    # If we are setting to undef, then just drop the key.
#    if (!defined $value) {
#        $self->DELETE($key);
#        return;
#    }
    
    # Check if the proposed value is valid, and store if it is.
    # (Validating also de-taints the value, if it's valid)
    $value = $self->{object}->_validate($key, $value);
    if (defined($value)) {
        $self->{payload}->{$key} = $value;
    }
    else {
        die('Invalid value for key');
    }
}


=head3 delete

Deleting a key works as one would expect with a Perl hash.  Once deleted,
unless a new value is set, attempts to access the key will return C<undef>.

=cut

sub DELETE {
    my ($self, $key) = @_;
    delete $self->{payload}->{$key};
}


=head3 clear

Clearing a hash works as one would expect with a Perl hash.  Unless new values
are set, attempts to access keys will return C<undef>.

=cut

sub CLEAR {
    my ($self) = @_;
    # The CLEAR method implemented in Tie::Hash uses calls to $self
    # (specifically, calls to FIRSTKEY, NEXTKEY, and DELETE), so let's just
    # call that code instead of reimplementing it!
    Tie::Hash::CLEAR($self);
}


=head3 exists

The operation of C<exists> is a little different from what is normally expected.

C<exists> will return true iff the key provided is a valid payload key for this
payload class.

To check if a payload key actually has a value, use C<defined>.  Of course, you
should continue to use C<exists> if you do not know if a payload has a
particular key.

=cut

sub EXISTS {
    my ($self, $key) = @_;
    return 1 if exists($self->{object}->keys()->{$key});
    return 0;
}


=head2 keys

C<keys> returns a list of keys I<only for payload keys that have been set>.

To get the a list of all keys that exist for this payload class, don't look
at the payload.  Instead, use C<keys> on the hash returned by C<keys()>.

=head2 each

C<each> returns the key/value pairs I<only for payload keys that have been set>.

=cut

sub FIRSTKEY {
    my ($self) = @_;
    # We can use the code from Tie::StdHash::FIRSTKEY, instead of rewriting it.
    return Tie::StdHash::FIRSTKEY($self->{payload});
}


sub NEXTKEY {
    my ($self, $previous) = @_;
    # We can use the code from Tie::StdHash::NEXTKEY, instead of rewriting it.
    return Tie::StdHash::NEXTKEY($self->{payload});
}


=head2 scalar

C<scalar> returns the number of payload keys that have values set.

To get the total number of keys that exist for this payload class, don't look
at the payload.  Instead, use C<scalar> on the hash returned by C<keys()>.

=cut

sub SCALAR {
    my ($self) = @_;
    return scalar %{$self->{payload}};
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