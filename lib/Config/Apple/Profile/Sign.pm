# This is the code for Config::Apple::Profile::Sign.
# For Copyright, please see the bottom of the file.

package Config::Apple::Profile::Sign;

use 5.14.4;
use strict;
use warnings FATAL => 'all';

our $VERSION = '0.87';

use Config::Apple::Profile::Config qw($ACP_OPENSSL_PATH);
use Fcntl qw(:seek F_GETFD F_SETFD FD_CLOEXEC);
use File::Temp;
use IPC::Open3;
use Symbol qw(gensym);
use Try::Tiny;


=encoding utf8

=head1 NAME

Config::Apple::Profile::Sign - Digitally sign configuration profiles


=head1 SYNOPSIS

    use Config::Apple::Profile;
    use Config::Apple::Profile::Payload::...;
    use Config::Apple::Profile::Sign;
    
    my $profile = new Config::Apple::Profile;
    
    # ... create your payloads and add to $profile ...
    
    my $signer = new Config::Apple::Profile::Sign;
    
    $signer->set_signer($signing_cert, $signing_key, $password);
    # Or $signer->set_signer_path($cert_path, $key_path, $password)
    
    my $signed_profile = $signer->sign($profile);

    
=head1 DESCRIPTION

This module is used to digitally-sign configuration profiles.  This is the last
step in the profile-creation process.  A signed configuration profile is binary
data that may not be modified.  The binary data is a DER-encoded PKCS#7 data
structure, containing the configuration profile, the signature, and the
certificate associated with the private key used to make the signature.

The signed configuration profile should be given the extension C<.mobileconfig>,
the same extension for unsigned configuration profiles.  The MIME type is
C<application/x-apple-aspen-config> (again, this is the same MIME type for
unsigned configuration profiles).  The configuration profile I<must not be
modified or further encoded>.  For example, do not Base64-encode the profile.

The build script must have detected a usable version of OpenSSL (version 0.9.8
or later) in order for this module to be usable.  To confirm that OpenSSL is
available, check the variable
C<$Config::Apple::Profile::Config::ACP_OPENSSL_PATH>.  If it is defined, it
will contain the path to a usable C<openssl> binary.

To sign a configuration profile manually using OpenSSL, you must first
create the .mobileconfig file, which can then be signed using the following
command:

    openssl smime -sign -in your.mobileconfig -out your_signed.mobileconfig
    -outform der -signer your_signing_cert.pem -inkey your_signing_key.key
    -nodetach

All of the parameters above are required.  If your signing key is encrypted,
you will be prompted for the passphrase to decrypt the key.


=head1 CLASS METHODS

=head2 new()

Returns a new object.  If C<$Config::Apple::Profile::Config::ACP_OPENSSL_PATH>
is not defined, this dies immediately.

=cut

sub new {
    my ($self) = @_;
    my $class = ref($self) || $self;
    
    # Check that OpenSSL was found during installation
    if (!defined $ACP_OPENSSL_PATH) {
        die "Unable to load $class: OpenSSL not found during installation\n";
    };
    
    # Open temporary files
    my $key_file = new File::Temp;
    my $cert_file = new File::Temp;
    
    # Unlink the temporary files
    # We use /dev/fd/X as the path to the temporary files, as a security
    # measure, so we don't need to keep the files around anywhere else.
    File::Temp::unlink0($key_file, "$key_file");
    File::Temp::unlink0($cert_file, "$cert_file");
    
    # Open a pipe that will be used to send the key password to OpenSSL
    my ($password_read, $password_write);
    pipe $password_read, $password_write;
    
    # Clear the close-on-exec bit on our handles.
    # We need this so that the file descriptors remain open when we fork
    # and exec the OpenSSL binary.  Even though we don't pass 
    my $fcntl_flags;
    
    # Work on the key file handle
    $fcntl_flags = fcntl($key_file, F_GETFD, 0)
        or die "Unable to F_GETFD for $key_file: $!";
    $fcntl_flags &= ~FD_CLOEXEC;
    fcntl($key_file, F_SETFD, $fcntl_flags)
        or die "Unable to F_SETFD for $key_file: $!";
    
    # Work on the cert file handle
    $fcntl_flags = fcntl($cert_file, F_GETFD, 0)
        or die "Unable to F_GETFD for $cert_file: $!";
    $fcntl_flags &= ~FD_CLOEXEC;
    fcntl($cert_file, F_SETFD, $fcntl_flags)
        or die "Unable to F_SETFD for $cert_file: $!";
    
    # Work on the password reading handle (OpenSSL needs this to read stuff!)
    $fcntl_flags = fcntl($password_read, F_GETFD, 0)
        or die "Unable to F_GETFD for password_read: $!";
    $fcntl_flags &= ~FD_CLOEXEC;
    fcntl($password_read, F_SETFD, $fcntl_flags)
        or die "Unable to F_SETFD for password_read: $!";
    
    # Prepare out object
    my $object = bless {
        key_file => $key_file,
        key_password => undef,
        password_reader => $password_read,
        password_writer => $password_write,
        cert_file => $cert_file,
    }, $class;
    
    # Return the prepared object!
    return $object;    
}


=head1 INSTANCE METHODS


=head2 set_signer($signing_cert, $signing_key, $password)

Set the private key and certificate to be used for signing.

C<$signing_cert> is the X.509 certificate, in DER or PEM form, provided as a
string.  C<$signing_key> is the corresponding RSA private key, either in DER or
PEM form, also provided as a string.  C<$password> is the password used to
decrypt the private key.  If the private key is not encrypted, C<$password>
should be an empty string.

B<NOTE:> Storing the private key unencrypted is unsafe.
 
This method (or C<set_signer_path>) must be called before the C<sign>
method is called.  This method only needs to be called once, and then C<sign>
can be called multiple times.

Exceptions will be thrown if the certificate or key can not be read, or if the
password provided can not be used to decrypt the key.  If exceptions are caught,
but the program continues running, the instance which threw
the exception will be in an inconsistent state, and should not be used for
signing until C<set_signer> returns without errors.

=cut

sub set_signer {
    my ($self, $signing_cert, $signing_key, $password) = @_;
    
    ...
}


=head2 set_signer_path($cert_path, $key_path, $password)

This works the same as C<set_signer>, except the signing certificate and key
are stored in files.

The two files (C<$cert_path> and C<$key_path>) must both be readable.  They
will not be modified.

This method can die for the same reasons as C<set_signer>, and can also die if
the files can not be read.

=cut

sub set_signer_path {
    my ($self, $cert_path, $key_path, $password) = @_;
    
    ...
}


=head2 sign($profile)

Sign a configuration profile.

C<$profile> must be an instance of C<Config::Apple::Profile> which is ready for
exporting.  A serialized configuration profile is obtained from C<$profile>,
which is then signed.  The configuration profile, the signature, and a copy of
the signing certificate are kept together in a DER-encoded PKCS#7 structure,
which is returned to the client.

Either C<set_signer()> or C<set_signer_path()> must be called before C<sign()>.

The return value can be either an array or a scalar.  If a single scalar is
returned, that will be the path to the signed data.  If an array is returned,
the first entry in the array will be an open file handle, pointing to the start
of the signed data, and the second entry will be the path to the file.  The file
will be opened in C<binmode>.

The signed profile is binary data, and must be treated as such.  The file's
contents must not be modified in any way.  The client is responsible for
unlinking the file.

C<< $profile->export() >> will be called as part of the signing process, which
means C<$profile> may be modified by C<sign()>.

Exceptions will be thrown if signing credentials have not been provided, or if
signing fails.  The call to C<< $profile->export() >> may also cause exceptions
to be thrown.

=cut

sub sign {
    my ($self, $profile) = @_;
    
    ...
}


=head2 DESTROY()

Called automatically when an object is not being used anymore.  This closes
our OpenSSL password-communication pipe, and cleans up our temporary files.

=cut

sub DESTROY {
    my ($self) = @_;
    
    # Close our pipe
    close $self->{password_writer};
    close $self->{password_reader};
    
    # Let File::Temp clean itself up
    undef $self->{key_file};
    undef $self->{cert_file};
    
    # Good night!
    return 1;
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