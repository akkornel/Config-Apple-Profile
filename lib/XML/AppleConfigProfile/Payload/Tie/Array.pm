# This is the code for XML::AppleConfigProfile::Payload::Tie::Array.
# For Copyright, please see the bottom of the file.

package XML::AppleConfigProfile::Payload::Tie::Array;

use 5.14.4;
use strict;
use warnings FATAL => 'all';

our $VERSION = '0.00_001';

use Scalar::Util qw(blessed);
use Tie::Array; # Also gives us Tie::StdArray
use XML::AppleConfigProfile::Payload::Types qw(:all);
use XML::AppleConfigProfile::Payload::Types::Validation qw(:types);


=encoding utf8

=head1 NAME

XML::AppleConfigProfile::Payload::Tie::Array - Tying class for arrays of things.

=head1 DESCRIPTION

This class is used to store an array of I<things>.  Exactly what I<things> are
being stored is specified at the time the tie is made.

There are several payload types that contain arrays of things.  For example,
the root profile has the all-important key C<PayloadContents>, which is an
array of payloads.

This class is used by payload classes to represent an array.

=cut

=head2 "CLASS" METHODS

=head3 tie @array, 'XML::AppleConfigProfile::Payload::Tie::Array', $value_type

When this class is tied to an array, C<TIEARRAY> will be called, with the class
name as the first argument.

C<$value_type> can be a scalar or a ref.  If C<$value_type> is a reference, it
must be blessed.  We keep a record of C<$value_type>'s class, and all values
placed into the array must be of the same class.  We let the class take
responsibility for validating its contents.

If C<$value_type> is a scalar, then C<$value_type> must
match one of the types from L<XML::AppleConfigProfile::Payload::Types>,
except for C<$ProfileClass>.  The standard type validation function from
L<XML::AppleConfigProfile::Payload::Types::Validation> will be used.

If C<$value_type> is not a valid scalar or a valid reference, then an exception
will be thrown.

=cut

sub TIEARRAY {
    my ($class, $value_type, $validator_ref) = @_;
    
    # This is what we'll eventually return
    my %object;
    
    # We'll still have an array, for convenience
    $object{array} = [];
    
    # If we have a ref, it must be a class
    if (ref $value_type) {
        my $value_class = blessed $value_type;
        if (!defined $value_class) {
            die "Attempting to pass a non-blessed ref";
        }
        $object{is_class} = 1;
        $object{validator} = $value_class;
    }
    
    # If we don't have a ref, then it needs to be a specific scalar
    else {
        $object{is_class} = 0;
        
        # Set up the appropriate validator, based on the type
        if ($value_type == $ProfileString) {
            $object{validator} = \&validate_string;
        }
        elsif ($value_type == $ProfileNumber) {
            $object{validator} = \&validate_number;
        }
        elsif ($value_type == $ProfileReal) {
            $object{validator} = \&validate_real;
        }
        elsif (   ($value_type == $ProfileData)
               || ($value_type == $ProfileNSDataBlob)
        ) {
            $object{validator} = \&validate_data;
        }
        elsif ($value_type == $ProfileBool) {
            $object{validator} = \&validate_bool;
        }
        elsif ($value_type == $ProfileDate) {
            $object{validator} = \&validate_date;
        }
        elsif ($value_type == $ProfileUUID) {
            $object{validator} = \&validate_uuid;
        }
        elsif ($value_type == $ProfileIdentifier) {
            $object{validator} = \&validate_identifier;
        }
        else {
            die "Value type is unknown";
        }
    } # Done checking for ref vs. scalar

    return bless \%object, $class;
}


=head3 FETCH

Works as one would expect with a Perl array.  Returns the entry at the specified
index.  Since methods are in place to prevent storing C<undef>, as long as the
index is valid at the time of the call, you will get something back.

=cut

sub FETCH {
    my ($self, $index) = @_;
    
    return $self->{array}->[$index];
}


=head3 STORE

Storing items at a specific index is not allowed.  This is to help prevent
C<undef> from appearing in the array.  Instead, use C<push> or C<unshift>.

=cut

sub STORE {
    my ($self, $index, $value) = @_;
    die "Storing items at specific indexes is not allowed";
}


=head3 delete

Deleting items at a specific index is not allowed.  Perl has deprecated this.
Instead, use C<splice>, C<pop>, or C<shift>.

=cut

sub DELETE {
    my ($self, $index) = @_;
    die "Deleting items at specific indexes is not allowed";
}


=head3 scalar

Works as expected, returning the number of items in the array.

=cut

sub FETCHSIZE {
    my ($self) = @_;

    return scalar @{$self->{array}};
}


=head3 STORESIZE

Works almost as expected.  Making an array smaller will delete items off of the
end of the array.  Making the array bigger (that is, presizing) has no effect.

=cut

sub STORESIZE {
    my ($self, $count) = @_;
    
    return if ($count >= $self->FETCHSIZE);
    $#{$self->{array}} = $count - 1; 
}


=head3 EXTEND

If Perl attempts to pre-extend the array, nothing happens.

=cut

sub EXTEND {
    my ($self, $count) = @_;
}


=head3 exists

Works as expected for a Perl array: Returns true if the specified index is
still valid for the array.

=cut

sub EXISTS {
    my ($self, $index) = @_;
    
    # We can use the code from Tie::StdArray, instead of rewriting it.
    return Tie::StdArray::EXISTS($self->{array}, $index);
}


=head3 CLEAR

Replacing the array with an empty list works to remove all of the entries from
the array.

=cut

sub CLEAR {
    my ($self) = @_;

    $self->{array} = [];
}


=head3 push

Works as expected for a Perl array, with two exceptions:

=over 4

=item *

C<undef> is not a valid array item.

=item *

If this is not an array of objects, then the value will be validated before
being added to the array.

=back

An exception will be thrown if either of the two points above fails.

=cut

sub PUSH {
    my $self = CORE::shift @_;
    
    # Run the validation
    @_ = $self->_validate(@_);
    
    # Let Tie::StdArray do the rest!
    return Tie::StdArray::PUSH($self->{array}, @_);
}


=head3 pop

Works as expected for a Perl array.

=cut

sub POP {
    my ($self) = @_;
    return Tie::StdArray::POP($self->{array});
}


=head3 shift

Works as expected for a Perl array.

=cut

sub SHIFT {
    my ($self) = @_;
    return Tie::StdArray::SHIFT($self->{array});
}


=head3 unshift

Works as expected for a Perl array, with two exceptions:

=over 4

=item *

C<undef> is not a valid array item.

=item *

If this is not an array of objects, then the value will be validated before
being added to the array.

=back

An exception will be thrown if either of the two points above fails.
=cut

sub UNSHIFT {
    my $self = CORE::shift @_;
    
    # Run the validation
    @_ = $self->_validate(@_);
    
    # Let Tie::StdArray do the rest!
    return Tie::StdArray::UNSHIFT($self->{array}, @_);
}


=head3 splice

Works as expected for a Perl array, but if you are using C<splice> to add
entries to the array, take note of these two exceptions:

=over 4

=item *

C<undef> is not a valid array item.

=item *

If this is not an array of objects, then the value will be validated before
being added to the array.

=back

An exception will be thrown if either of the two points above fails.

=cut

sub SPLICE {
    # We can't use Tie::Array or Tie::StdArray for this, because it expects
    # something we can't easily give.  We'll have to do it ourselves.
    my $self = CORE::shift @_;
    
    # We'll need the current array size for reference
    my $size = $self->FETCHSIZE;
    
    # Get the offset from the parameters, or default to 0
    # If offset is negative, make it relative to the array end
    my $offset = scalar @_ ? shift @_ : 0;
    $offset += $size if $offset < 0;
    
    # Get the length from the parameters.  If length wasn't provided, then
    # we're grabbing all of the array starting at $offset
    my $length = scalar @_ ? shift @_ : $size - $offset;
    
    # If there are any parameters left, then they are items to insert.
    # Validate them before continuing.
    if (scalar @_ >= 0) {
        @_ = $self->_validate(@_);
    }
    
    # Do the splice and return.
    return splice($self->{array}, $offset , $length, @_);
}


=head3 _validate

Given a list of items, each one will be validated, and the validated list will
be returned.

An exception will be thrown if any of the list items is undef, or if any of
the list items fails validation, or if the caller is not expecting an array.

=cut

sub _validate {
    my $self = CORE::shift @_;
    
    # If we are not returning an array, then die now
    if (!wantarray) {
        die "_validate expects to return an array";
    }
    
    # We can't use a foreach loop, because our items might be Readonly,
    # and the way Perl does aliasing means assigning to the foreach $item
    # triggers a "modification of a read-only value" error.
    my @validated_array;
    
    # Go through each item, making sure it is valid
    for (my $i = 0; $i < scalar @_; $i++) {
        my $item = $_[$i];
        
        # Undef is not a valid value
        if (!defined $item) {
            die "Adding undef items is not allowed";
        }
        
        # If we are an array of objects, check the class name
        if ($self->{is_class}) {
            my $item_class = blessed $item;
            if ($item_class ne $self->{validator}) {
                die "Attempting to add item of a different class";
            }
            $validated_array[$i] = $item;
        }
        
        # If we are not objects, then use the validation routine
        else {
            # Call the validation routine
            my $validated_item = $self->{validator}->($item);
        
            # If $item suddenly became undef, it was invalid
            if (!defined $validated_item) {
                die "Attempting to insert invalid item";
            }
            
            $validated_array[$i] = $validated_item;
        } # Done checking class or not-class
    } # Done checking each item
    
    return @validated_array;
}


=head1 ACKNOWLEDGEMENTS

Refer to L<XML::AppleConfigProfile> for acknowledgements.

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