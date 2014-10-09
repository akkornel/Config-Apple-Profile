package Config::Apple::Profile::Payload::Types::Validation;

use 5.10.1;
use strict;
use warnings FATAL => 'all';

our $VERSION = '0.87';

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

=head2 validate

    my $validated_value = validate($type, $value);

Validates C<$value> as a valid C<$type>.  If valid, returns the de-tainted
C<$value>.  If invalid, returns C<undef>.

C<$type> is one of the values from L<Config::Apple::Profile::Payload::Types>.
C<$value> is the value to be validated.

IF C<$type> is not valid, or C<$value> is C<undef>, then C<undef> is returned.

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
}


=head2 validate_string

    my $valid_string = validate_string($value);

Returns a de-tained C<$value> if it is a defined, non-empty scalar, and can be
encoded as UTF-8 by L<Encode>.

=cut

sub validate_string {
    my ($value) = @_;
    
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
        
        # If we're here, then we are valid!
        return $value;
}


=head2 validate_number

    my $number = validate_number($value)

Returns a de-tained C<$value> if it is an integer.  A leading + is OK.
Any other input returns C<undef>.

=cut

sub validate_number {
    my ($value) = @_;
    
    # References aren't allowed here
    ## no critic (ProhibitExplicitReturnUndef)
    return undef if ref($value);
    ##use critic
    
    # Numbers must be integers, positive or negative (or zero).
    if ($value =~ /^$RE{num}{int}{-keep}$/) {
        return $1;
    }
    
    # If we're here, the matching failed, so return undef
    ## no critic (ProhibitExplicitReturnUndef)
    return undef;
    ##use critic
}


=head2 validate_real

    my $number = validate_real($value)

Returns a de-tainted C<$value> if it is an integer or a floating-point number.
A loading C<+> is OK.  An exponent, positive or negative, is also OK.
Any other input returns C<undef>.

=cut

sub validate_real {
    my ($value) = @_;
    
    # References aren't allowed here
    ## no critic (ProhibitExplicitReturnUndef)
    return undef if ref($value);
    ##use critic
    
    # Numbers must be floating-point, positive or negative (or zero).
    if ($value =~ /^$RE{num}{real}{-keep}$/i) {
        return $1;
    }
    
    # If we're here, the matching failed, so return undef
    ## no critic (ProhibitExplicitReturnUndef)
    return undef;
    ##use critic
}


=head2 validate_boolean

    my $boolean = validate_boolean($value);

If C<$value> can be evaluated as true or false, returns a C<1> or a C<0>,
respectively.  Will return C<undef> if a reference is passed.

=cut

sub validate_boolean {
    my ($value) = @_;
    
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


=head2 validate_date

    my $date_object = validate_date($value);

If C<$value> is already a finite C<DateTime> object, it is returned immediately.
If C<$value> is a string, and can be parsed by L<DateTime::Format::Flexible>,
the resulting C<DateTime> object will be returned.

Unparseable strings, infinite C<DateTime> objects, and any other input will
return C<undef>.

=cut

sub validate_date {
    my ($value) = @_;
    
    # If we have a blessed ref, which is a DateTime object, and it represents
    # a finite time, then we're good!
    if (ref $value) {
        ## no critic (ProhibitExplicitReturnUndef)
        return undef unless blessed($value);
        return undef unless $value->isa('DateTime');
        return undef unless $value->is_finite;
        ##use critic
        
        return $value;
    }
    
    # At this point, we have a scalar, so let's see if it can be parsed
    try {
        $value = DateTime::Format::Flexible->parse_datetime($value);
    }
    # If the parse fails, it dies, so return undef
    catch {
        $value = undef;
    };
    
    # Return either our object, or undef
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
        #    die "Filehandle is not open for reading.";
        #}
        my $ignore;
        my $count ;
        try {
            $count = read $value, $ignore, 1;
        };
        unless (defined $count) {
            die "Unable to read from filehandle.  Is it open for reading?";
        }
        
        # If we can't seek, we're probably dealing with something bad
        unless (seek $value, -1, SEEK_CUR) {
            die "Unable to seek with filehandle.  Is it pointing to a file?";
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
    ## no critic (ProhibitExplicitReturnUndef)
    return undef;
    ##use critic
}


=head2 validate_identifier

    my $valid_identifier = validate_identifier($value);

Returns a de-tained C<$value> if it is a single-line string that matches the
format of a domain name (without spaces).  Otherwise, returns C<undef>.

=cut

sub validate_identifier {
    my ($value) = @_;
    
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
    
    # If we're here, the matching failed, so return undef
    ## no critic (ProhibitExplicitReturnUndef)
    return undef;
    ##use critic
}

=head2 validate_uuid

    my $guid = validate_uuid($value);

If C<$value> is a C<Data::GUID> object, it is returned immediately.
If C<$value> is a C<Data::UUID> object, an equivalent C<Data::GUID> object is
returned.  Objects of other types return C<undef>.

If C<$value> is a string that can be parsed as a GUID, an equivalent
C<Data::GUID> object is returned.  Otherwise, C<undef> is returned.

=cut

sub validate_uuid {
    my ($value) = @_;
    
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

    # If parsing went OK, then we have our object!  Otherwise, we have undef.
    return $uuid;
}


=head2 validate_class

    my $object = validate_class($value)

If C<$value> is an object, and is also an instance of
C<Config::Apple::Profile::Payload::Common> (or something that is a subclass),
then C<$value> is returned.  Otherwise, C<undef> is returned.

=cut

sub validate_class {
    my ($object) = @_;
    
    # We don't accept non-references
    if (!blessed($object)) {
        ## no critic (ProhibitExplicitReturnUndef)
        return undef;
        ## use critic
    }
    
    if ($object->isa('Config::Apple::Profile::Payload::Common')) {
        return $object;
    }
    
    # If we're here, then we have an object of the wrong class
    ## no critic (ProhibitExplicitReturnUndef)
    return undef;
    ## use critic
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