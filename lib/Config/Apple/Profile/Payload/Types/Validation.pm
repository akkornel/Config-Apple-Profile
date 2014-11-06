package Config::Apple::Profile::Payload::Types::Validation;

use 5.10.1;
use strict;
use warnings FATAL => 'all';

our $VERSION = '0.87.1';

use DateTime;
use DateTime::Format::Flexible;
use Encode qw(encode);
use Exporter::Easy (
    OK => [qw(
        validate 
        validate_string validate_number validate_real validate_date
        validate_boolean validate_data validate_identifier validate_uuid
        validate_class
    )],
    TAGS => [
        'all' => [qw(
            validate
            validate_string validate_number validate_real validate_date
            validate_boolean validate_data validate_identifier validate_uuid
            validate_class
        )],
        'types' => [qw(
            validate_string validate_number validate_real validate_date
            validate_boolean validate_data validate_identifier validate_uuid
            validate_class
        )],
    ],
);
use Fcntl qw(F_GETFL O_RDONLY O_RDWR :seek);
use Regexp::Common;
use Scalar::Util qw(openhandle blessed);
use Try::Tiny;
use Config::Apple::Profile::Payload::Types qw(:all);


=encoding utf8

=head1 NAME

Config::Apple::Profile::Payload::Types::Validation - Validation of common
payload types.

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


=head1 FUNCTIONS

=head2 A note on exceptions

All of the validations throw exceptions (that is, they die) when presented
with an invalid value.  One of three exceptions may be thrown:

=over 4

=item Config::Apple::Profile::Exception::Validation

This exception is thrown when an invalid value is passed as the value to be
validated.  The exception class includes one attribute, C<error>, which contains
more information on what went wrong.

Refer to the below functions for more details on what error strings might be
thrown.

=item Config::Apple::Profile::Exception::Undef

This exception is thrown when C<undef> is passed as the value to be validated.
This exception is a subclass of
C<Config::Apple::Profile::Exception::Validation>.

=back

=head2 validate

    my $validated_value = validate($type, $value);

Validates C<$value> as a valid C<$type>.  If valid, returns the de-tainted
C<$value>.  If invalid, an exception is thrown.

C<$type> is one of the values from L<Config::Apple::Profile::Payload::Types>.
C<$value> is the value to be validated.

If C<$value> is C<undef>, then a 
C<Config::Apple::Profile::Exception::Undef> exception is thrown.

If C<$type> is not a known value, then an
C<Config::Apple::Profile::Exception::Internal> exception is thrown.

=cut

sub validate {
    my ($type, $value) = @_;
    
    # We recognize String types
    if ($type == $ProfileString) {
        return validate_string($value);
    }
    
    # We recognize Number types
    elsif ($type == $ProfileNumber) {
        return validate_number($value);
    }
    
    # We recognize Real (floating-point number) types
    elsif ($type == $ProfileReal) {
        return validate_real($value);
    }
    
    # We recognize Boolean types
    elsif ($type == $ProfileBool) {
        return validate_boolean($value);
    }
    
    # We recognize Data types
    elsif (   ($type == $ProfileData)
           || ($type == $ProfileNSDataBlob)
    ) {
        return validate_data($value);
    }
    
    # We recognize Date types
    elsif ($type == $ProfileDate) {
        return validate_date($value);
    }
    
    # We recognize Identifier types
    elsif ($type == $ProfileIdentifier) {
        return validate_identifier($value);
    }
    
    # We recognize UUID types
    elsif ($type == $ProfileUUID) {
        return validate_uuid($value);
    }
    
    # We recognize classes
    elsif ($type == $ProfileClass) {
        return validate_class($value);
    }
    
    # If we're here, something is wrong
    else {
        Config::Apple::Profile::Exception::Internal->throw(
            error => "Attempting to validate unknown type $type"
        );
    }
}


=head2 validate_string

    my $valid_string = validate_string($value);

Returns a de-tained C<$value> if it is a defined, non-empty scalar, and can be
encoded as UTF-8 by L<Encode>.

The following error strings are used in exceptions thrown by this function:

=over 4

=item Passing reference to validate_string

Thrown when passing a ref (blessed or not).

=item Passing undef to validate_string

Thrown when passing C<undef>.

=item Passing empty or invalid string to validate_string

Thrown when passing a string that doesn't match the regex C</^(.+)$/s>.

=item validate_string unable to encode string as UTF-8

Thrown when passing a string that can not be encoded into UTF-8 (that is,
strict UTF-8) by the C<Encode> module.

=back

=cut

sub validate_string {
    my ($value) = @_;
    
        # References aren't allowed here
        if (ref($value)) {
            Config::Apple::Profile::Exception::Validation->throw(
                error => 'Passing reference to validate_string'
            );
        }
        
        # Undefined values aren't allowed, either
        if (!defined($value)) {
            Config::Apple::Profile::Exception::Undef->throw(
                error => 'Passing undef to validate_string'
            );
        }
        
        # Empty strings aren't allowed, either.
        if ($value =~ m/^(.+)$/s) {
            $value = $1;
        }
        else {
            Config::Apple::Profile::Exception::Validation->throw(
                error => 'Passing empty or invalid string to validate_string'
            );
        }
        
        # Try to encode as UTF-8, to make sure it's safe
        try {
            encode('UTF-8', $value, Encode::FB_CROAK | Encode::LEAVE_SRC);
        }
        catch {
            Config::Apple::Profile::Exception::Validation->throw(
                error => 'validate_string unable to encode string as UTF-8'
            );
        };
        
        # If we're here, then we are valid!
        return $value;
}


=head2 validate_number

    my $number = validate_number($value)

Returns a de-tained C<$value> if it is an integer.  A leading + is OK.

The following error strings are used in exceptions thrown by this function:

=over 4

=item Passing reference to validate_number

Thrown when a reference (blessed or not) is passed.

=item Passing undef to validate_number

Thrown when C<undef> is passed.

=item Passing invalid number to validate_number

Thrown when an unparseable integer is passed, as determined by
C<Regexp::Common>.

=back

=cut

sub validate_number {
    my ($value) = @_;
    
    # References aren't allowed here
    if (ref($value)) {
        Config::Apple::Profile::Exception::Validation->throw(
                error => 'Passing reference to validate_number'
        );
    }
    
    # Undef isn't allowed here, either
    if (!defined($value)) {
        Config::Apple::Profile::Exception::Undef->throw(
                error => 'Passing undef to validate_number'
        );
    }
    
    # Numbers must be integers, positive or negative (or zero).
    if ($value =~ /^$RE{num}{int}{-keep}$/) {
        return $1;
    }
    
    # If we're here, the matching failed, so throw an exception
    Config::Apple::Profile::Exception::Validation->throw(
        error => 'Passing invalid number to validate_number'
    );
}


=head2 validate_real

    my $number = validate_real($value)

Returns a de-tainted C<$value> if it is an integer or a floating-point number.
A loading C<+> is OK.  An exponent, positive or negative, is also OK.

The following error strings are used in exceptions thrown by this function:

=over 4

=item Passing reference to validate_real

Thrown when a reference (blessed or not) is passed.

=item Passing undef to validate_real

Thrown when C<undef> is passed.

=item Passing invalid real to validate_real

Thrown when the value passed could not be parsed as a real number, as defined
by C<Regexp::Common>.

=back

=cut

sub validate_real {
    my ($value) = @_;
    
    # References aren't allowed here
    if (ref($value)) {
        Config::Apple::Profile::Exception::Validation->throw(
            error => 'Passing reference to validate_real'
        );
    }
    
    # Undef values aren't allowed either
    if (!defined($value)) {
        Config::Apple::Profile::Exception::Undef->throw(
                error => 'Passing undef to validate_real'
        );
    }
    
    # Numbers must be floating-point, positive or negative (or zero).
    if ($value =~ /^$RE{num}{real}{-keep}$/i) {
        return $1;
    }
    
    # If we're here, the matching failed, so return undef
    Config::Apple::Profile::Exception::Validation->throw(
        error => 'Passing invalid real to validate_real'
    );
}


=head2 validate_boolean

    my $boolean = validate_boolean($value);

If C<$value> can be evaluated as true or false, returns a C<1> or a C<0>,
respectively.

The following error strings are used in exceptions thrown by this function:

=over 4

=item Passing reference to validate_boolean

Thrown when passing a reference (blessed or not).

=item Passing undef to validate_boolean

Thrown when passing C<undef>.

=back

=cut

sub validate_boolean {
    my ($value) = @_;
    
    # References aren't allowed here
    if (ref($value)) {
        Config::Apple::Profile::Exception::Validation->throw(
            error => 'Passing reference to validate_boolean'
        );
    }
    
    # Undef values aren't allowed either
    if (!defined($value)) {
        Config::Apple::Profile::Exception::Undef->throw(
                error => 'Passing undef to validate_boolean'
        );
    }
    
    # A simple evaluation!
    if ($value) {
        return 1;
    }
    if (!$value) {
        return 0;
    }
}


=head2 validate_date

    my $date_object = validate_date($value);

If C<$value> is already a finite C<DateTime> object, it is returned immediately.
If C<$value> is a string, and can be parsed by L<DateTime::Format::Flexible>,
the resulting C<DateTime> object will be returned.

Unparseable strings, infinite C<DateTime> objects, and any other input will
throw an exception.

The following error strings are used in exceptions thrown by this function:

=over 4

=item Passing non-blessed reference to validate_date

Thrown when passing a ref that is not blessed (is not an object).

=item Passing non-DateTime object to validate_date

Thrown when passing an object that is not an instance of C<DateTime> (or one
of its subclasses).

=item Passing infinite DateTime to validate_date

Thrown when passing an infinite C<DateTime> object.

=item Passing undef to validate_date

Thrown when passing C<undef>.

=item Passing unparseable string to validate_date

Thrown when passing a value that could not be parsed by
C<DateTime::Format::Flexible>.

=back

=cut

sub validate_date {
    my ($value) = @_;
    
    # If we have a blessed ref, which is a DateTime object, and it represents
    # a finite time, then we're good!
    if (ref $value) {
        if (!blessed($value)) {
            Config::Apple::Profile::Exception::Validation->throw(
                error => 'Passing non-blessed reference to validate_date'
            );
        }
        if (!$value->isa('DateTime')) {
            Config::Apple::Profile::Exception::Validation->throw(
                error => 'Passing non-DateTime object to validate_date'
            );
        }
        if ($value->is_infinite) {
            Config::Apple::Profile::Exception::Validation->throw(
                error => 'Passing infinite DateTime to validate_date'
            );
        }
        
        return $value;
    }
    
    # Undef isn't allowed
    if (!defined($value)) {
        Config::Apple::Profile::Exception::Undef->throw(
            error => 'Passing undef to validate_date'
        );
    }
    
    # At this point, we have a scalar, so let's see if it can be parsed
    try {
        $value = DateTime::Format::Flexible->parse_datetime($value);
    }
    # If the parse fails, it dies, so die as well!
    catch {
        Config::Apple::Profile::Exception::Validation->throw(
            error => 'Passing unparseable string to validate_date'
        );
    };
    
    # Return our object
    return $value;
}


=head2 validate_data

    # With a file handle
    my $handle = validate_data($handle);

    # With binary data
    my $handle = validate_data($bytes);

If passed an already-open file handle, or any object that represents a file
(such as an C<IO::> object), the handle (without the object tie) will be
returned.

If passed a scalar, it will be checked to make sure it is not empty, and that
is not a utf8 string.  The contents of the string will be placed into an
anonymous in-memory file, and the filehandle will be returned.

The following error strings are used in exceptions thrown by this function:

=over 4

=item Unable to read from handle passed to validate_data

Thrown when passing a filehandle that does not allow reads (such as a file
opened for writes only, or the write-only end of a pipe).

=item Unable to seek on handle passed to validate_data

Thrown when passing a filehandle that does not allow seeking (such as a pipe).

=item Passing unknown item to validate_data

Thrown when passing something that is not an open handle, and is also not a
binary string. 

=back

=cut

sub validate_data {
    my ($value) = @_;
    
    # How we act here depends if we have a string or a filehandle
    # Let's first check if we were given an open filehandle
    if (openhandle($value)) {
        # First, get just the plain filehandle
        my $value = openhandle($value);
        
        # Check if the file is open for reading
        # I would like to use the solution from
        # <http://stackoverflow.com/questions/672214>, but that doesn't work on
        # all filehandles, unfortunately.
        # We'll have to do it the hard way.
        
        #my $modes = fcntl($value, F_GETFL, 0);
        #my $mask = 2**O_RDONLY + 2**O_RDWR;
        #unless (($modes & $mask) > 0) {
        #    Config::Apple::Profile::Exception::Validation->throw(
        #        error => 'Filehandle given to validate_data not open for reading'
        #        );
        #}
        my $ignore;
        my $count ;
        try {
            $count = read $value, $ignore, 1;
        };
        unless (defined $count) {
            Config::Apple::Profile::Exception::Validation->throw(
                error => 'Unable to read from handle passed to validate_data'
            );
        }
        
        # If we can't seek, we're probably dealing with something bad
        unless (seek $value, -1, SEEK_CUR) {
            Config::Apple::Profile::Exception::Validation->throw(
                error => 'Unable to seek on handle passed to validate_data'
            );
        }
        
        return $value;
    }
    
    # If we don't have an open handle, then make sure it's not an object
    unless (ref($value)) {
        # We have a string.  Let's make sure it's binary, and non-empty.
        if (   (!utf8::is_utf8($value))
            && (length($value) > 0)
        ) {
            # Pull the string into an anonymous in-memory file, and return that.
            open(my $file, '+>', undef);
            binmode $file;
            print $file $value;
            seek $file, 0, 0;
            return $file;
        }
    }
    
    # If we're here, then we are dealing with something unknown to us.
    Config::Apple::Profile::Exception::Validation->throw(
            error => 'Passing unknown item to validate_data'
    );
}


=head2 validate_identifier

    my $valid_identifier = validate_identifier($value);

Returns a de-tained C<$value> if it is a single-line string that matches the
format of a domain name (without spaces).

The following error strings are used in exceptions thrown by this function:

=over 4

=item Pass reference to validate_identifier

Thrown when passing a reference (blessed or not).

=item Passing undef to validate_identifier

Thrown when passing C<undef>.

=item Passing empty or invalid value to validate_identifier

Thrown when passing an empty or multiline string.  Also thrown when passing a
string that does not parse as a host or domain name according to
C<Regexp::Common>.

=back

=cut

sub validate_identifier {
    my ($value) = @_;
    
    # References aren't allowed here
    if (ref($value)) {
        Config::Apple::Profile::Exception::Validation->throw(
            error => 'Passing reference to validate_identifier'
        );
    }
    
    if (!defined($value)) {
        Config::Apple::Profile::Exception::Undef->throw(
            error => 'Passing undef to validate_identifier'
        );
    }
    
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
    
    # If we're here, the matching failed, so throw an exception
    Config::Apple::Profile::Exception::Validation->throw(
        error => 'Passing empty or invalid value to validate_identifier'
    );
}

=head2 validate_uuid

    my $guid = validate_uuid($value);

If C<$value> is a C<Data::GUID> object, it is returned immediately.
If C<$value> is a C<Data::UUID> object, an equivalent C<Data::GUID> object is
returned.  Objects of other types throw an exception.

If C<$value> is a string that can be parsed as a GUID, an equivalent
C<Data::GUID> object is returned.

The following error strings are used in exceptions thrown by this function:

=over 4

=item Passing undef to validate_uuid

Thrown when C<undef> is passed.

=item Passing unknown ref to validate_uuid

Thrown when a reference is passed, but the reference is not to a C<Data::UUID>
or C<Data::GUID> object.

=item Passing unknown value to validate_uuid

Thrown when the value passed could not be parsed by C<Data::GUID>.

=back

=cut

sub validate_uuid {
    my ($value) = @_;
    
    my $class = ref($value);
    my $uuid;
    
    # We don't accept undef
    if (!defined($value)) {
        Config::Apple::Profile::Exception::Undef->throw(
            error => 'Passing undef to validate_uuid'
        );
    }
    
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
        Config::Apple::Profile::Exception::Validation->throw(
            error => 'Passing unknown ref to validate_uuid'
        );
    }
        
    # Have Data::GUID try to parse the input
    # If from_any_string doesn't die, then it wored OK
    eval {
        $uuid = Data::GUID->from_any_string($value);
    };
    
    # If we got a UUID back, return it!
    if (defined($uuid)) {
        return $uuid;
    }
    else {
        Config::Apple::Profile::Exception::Validation->throw(
            error => 'Passing unknown value to validate_uuid'
        );
    }
}


=head2 validate_class

    my $object = validate_class($value)

If C<$value> is an object, and is also an instance of
C<Config::Apple::Profile::Payload::Common> (or something that is a subclass),
then C<$value> is returned.

The following error strings are used in exceptions thrown by this function:

=over 4

=item Passing undef to validate_class

Thrown when C<undef> is passed.

=item Passing non-object to validate_uuid

Thrown when an unblessed ref (that is, a ref that is not an object) is passed.

=item Passing unknown object to validate_uuid

Thrown when an object is passed that is not an instance of
C<Config::Apple::Profile::Payload::Common> (or a subclass).

=back

=cut

sub validate_class {
    my ($object) = @_;
    
    # We don't accept undef
    if (!defined($object)) {
        Config::Apple::Profile::Exception::Undef->throw(
            error => 'Passing undef to validate_class'
        );
    }
    
    # We don't accept non-references
    if (!blessed($object)) {
        Config::Apple::Profile::Exception::Validation->throw(
            error => 'Passing non-object to validate_uuid'
        );
    }
    
    # Make sure the class is correct
    if ($object->isa('Config::Apple::Profile::Payload::Common')) {
        return $object;
    }
    else {
        Config::Apple::Profile::Exception::Validation->throw(
            error => 'Passing unknown object to validate_uuid'
        );
    }
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