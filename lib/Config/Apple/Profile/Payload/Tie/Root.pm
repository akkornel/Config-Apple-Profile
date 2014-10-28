# This is the code for Config::Apple::Profile::Payload::Tie::Root.
# For Copyright, please see the bottom of the file.

package Config::Apple::Profile::Payload::Tie::Root;

use 5.10.1;
use strict;
use warnings FATAL => 'all';

our $VERSION = '0.87.1';

use Tie::Hash; # Also gives us Tie::StdHash
use Config::Apple::Profile::Payload::Tie::Array;
use Config::Apple::Profile::Payload::Tie::Dict;
use Config::Apple::Profile::Payload::Types qw(:all);
use Config::Apple::Profile::Payload::Types::Validation qw(:types);
use Scalar::Util qw(blessed);


=encoding utf8

=head1 NAME

Config::Apple::Profile::Payload::Tie::Root - Tying class for payload storage.

=head1 DESCRIPTION

This class is used to store the payload keys, and their values, for each of the
payload classes under C<Config::Apple::Profile::Payload::>.

In the configuration profile XML, each payload is represented by a series of
keys and their values.  This matches up fairly well with a Perl hash, so that
is the mechanism that was chosen for actually getting (and messing with) the
data in a payload class!

This class is used directly only by L<Config::Apple::Profile::Payload::Common>,
and acts as storage for the payload keys.  Subclasses are involved indirectly,
by providing their own list of payload keys, either replacing or supplementing
the list from C<Config::Apple::Profile::Payload::Common>.

=cut

=head2 "CLASS" METHODS

=head3 tie %hash, 'Config::Apple::Profile::Payload::Tie::Root', $self

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
L<Config::Apple::Profile::Payload::Common>.  No attempts will be made to modify
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


=head3 FETCH

Works as one would expect with a Perl hash.  Either the value is returned, or
C<undef> is returned.  Exactly I<what> you get depends on the payload class and
the key you are accessing.  For more details, check the payload class
documentation, as well as L<Config::Apple::Profile::Payload::Types>.

=cut

sub FETCH {
    my ($self, $key) = @_;
    
    # Grab the information on our requested key
    if (!exists $self->{object}->keys()->{$key}) {
        die "Payload key $key not defined in class "
            . blessed($self->{object}) . "\n";
    }
    my $key_info = $self->{object}->keys()->{$key};
    
    # If the payload key has a fixed value, return that
    if (exists $key_info->{value}) {
        return $key_info->{value};
    }
    
    # Our EXISTS check returns true if the key is a valid payload key name.
    # Therefore, we need to do our own exists check, and possible return undef.
    if (exists $self->{payload}->{$key}) {
        return $self->{payload}->{$key};
    }
    
    # At this point, our key doesn't exist right now, but we need to check for
    # some complex types.
    my $type = $key_info->{type};
    
    # If the key is an array or a dict, get the validator and make the tie
    if (   ($type == $ProfileArray)
        || ($type == $ProfileDict)
    ) {
        # Set up the appropriate validator, based on array/dict content type
        my $validator_ref = sub {
            my ($value) = @_;
            return $self->{object}->validate_key($key, $value);
        };
        
        # If the key is an array, set up a new Array tie
        if ($type == $ProfileArray) {
            tie my @array, 'Config::Apple::Profile::Payload::Tie::Array',
                           $validator_ref;
            $self->{payload}->{$key} = \@array;        
            return $self->{payload}->{$key};
        }
    
        # If the key is a dictionary, set up a new Hash tie
        elsif ($type == $ProfileDict) {
            tie my %hash, 'Config::Apple::Profile::Payload::Tie::Dict',
                           $validator_ref;
            $self->{payload}->{$key} = \%hash;
            return $self->{payload}->{$key};
        }
    }
    
    # If the key is a class, instantiate it, add it to the payload, and return
    elsif ($type == $ProfileClass) {
        my $object = $self->{object}->construct($key);
        $self->{payload}->{$key} = $object;
        return $object;
    }
    
    # The catch-all:  The key doesn't exist, and isn't special, so return undef.
    else {
        ## no critic (ProhibitExplicitReturnUndef)
        return undef;
        ## use critic
    }
}


=head3 STORE

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
documentation, as well as L<Config::Apple::Profile::Payload::Types>.

If the validation fails, the program dies.

=cut

sub STORE {
    my ($self, $key, $value) = @_;
    
    # Check if the proposed value is valid, and store if it is.
    # (Validating also de-taints the value, if it's valid)
    $value = $self->{object}->validate_key($key, $value);
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


=head3 keys

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


=head3 scalar

C<scalar> returns the number of payload keys that have values set.

To get the total number of keys that exist for this payload class, don't look
at the payload.  Instead, use C<scalar> on the hash returned by C<keys()>.

=cut

sub SCALAR {
    my ($self) = @_;
    return scalar %{$self->{payload}};
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