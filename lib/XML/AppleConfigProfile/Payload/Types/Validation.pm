package XML::AppleConfigProfile::Payload::Types::Validation;

use 5.14.4;
use strict;
use warnings FATAL => 'all';

our $VERSION = '0.00_001';

use Encode qw(encode);
use Exporter::Easy (
    OK => [qw(
        validate 
        validate_string validate_number
        validate_boolean validate_data validate_identifier validate_uuid
    )],
    TAGS => [
        'all' => [qw(
            validate
            validate_string validate_number
            validate_boolean validate_data validate_identifier validate_uuid
        )],
        'types' => [qw(
            validate_string validate_number
            validate_boolean validate_data validate_identifier validate_uuid
        )],
    ],
);
use Regexp::Common;
use Scalar::Util qw(openhandle);
use Try::Tiny;
use XML::AppleConfigProfile::Payload::Types qw(:all);


=head1 NAME

XML::AppleConfigProfile::Payload::Types::Validation - Validation of common
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


=head1 METHODS

=head2 validate

    my $validated_value = validate($type, $value);
    
Validates C<$value> as a valid C<$type>.  If valid, returns the de-tainted
C<$value>.  If invalid, returns C<undef>.

C<$type> is one of the values from L<XML::AppleConfigProfile::Payload::Types>.
C<$value> is the value to be validated.

IF C<$type> is not valid, or C<$value> is C<undef>, then C<undef> is returned.

This is a convenience method for when you can specify the type of data as a
parameter.

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
    
    # We recognize Identifier types
    elsif ($type == $ProfileIdentifier) {
        return validate_identifier($value);
    }
    
    # We recognize UUID types
    elsif ($type == $ProfileUUID) {
        return validate_uuid($value);
    } # Done checking the UUID type
}


=head2 validate_string

    my $valid_string = validate_string($value);

Returns a de-tained C<$value> if it is a defined, non-empty scalar, and can be
UTF-8 encoded.

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

Returns a de-tained C<$value> if it is an integer.  A leading C<+> is OK.
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


=head2 validate_boolean

    my $boolean = validate_boolean($value);

If C<$value> can be evaluated as true or false, returns a C<1> or a C<0>.  Will
return C<undef> if a reference is passed.

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

=head2 validate_data

    # With a file handle
    my $handle = validate_data($handle);

    # With binary data
    my $handle = validate_data($bytes);

If passed an already-open file handle, or any object that represents a file
(such as an C<IO::> object), will return what was passed.

If passed a scalar, it will be checked to make sure it is not empty, and that
is not a utf8 string (which it would be if it was a string).  The contents of
the string will be placed into an in-memory file, and an IO::File object will
be returned.

=cut

sub validate_data {
    my ($value) = @_;
    
    # How we act here depends if we have a string or a filehandle
    # Let's first check if we were given an open filehandle
    if (openhandle($value)) {
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
    
    # If we're here, then we are dealing with something unknown to us.
    ## no critic (ProhibitExplicitReturnUndef)
    return undef if ref($value);
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

Returns a Data::GUID object if C<$value> can be parsed as a UUID.

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