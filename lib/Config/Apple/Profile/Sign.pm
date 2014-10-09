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


=head1 NAME

Config::Apple::Profile::Sign - Digitally sign configuration profiles


=head1 SYNOPSIS

    use Config::Apple::Profile;
    use Config::Apple::Profile::Payload::...;
    use Config::Apple::Profile::Sign;
    
    my $profile = new Config::Apple::Profile;
    
    # ... create your payloads and add to $profile ...
    
    my $signer = new Config::Apple::Profile::Sign;
    
    $signer->set_key($signing_key, $password);
    # Or $signer->set_key_path($signing_key_path, $password)
    
    $signer->set_cert($signing_cert);
    # Or $signer->set_cert_path($signing_cert_path)
    
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