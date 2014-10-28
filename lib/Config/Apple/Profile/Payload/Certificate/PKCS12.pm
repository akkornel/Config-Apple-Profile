# This is the code for Config::Apple::Profile::Payload::Certificate::PKCS12.
# For Copyright, please see the bottom of the file.

package Config::Apple::Profile::Payload::Certificate::PKCS12;

use 5.10.1;
use strict;
use warnings FATAL => 'all';
use base qw(Config::Apple::Profile::Payload::Certificate);

our $VERSION = '0.87.1';

use Readonly;
use Config::Apple::Profile::Targets qw(:all);
use Config::Apple::Profile::Payload::Certificate;
use Config::Apple::Profile::Payload::Types qw($ProfileNumber $ProfileString);


=encoding utf8

=head1 NAME

Config::Apple::Profile::Payload::Certificate::PKCS12 - Bundle containing
one certificate and its matching private key.

=head1 SYNOPSIS

    use Config::Apple::Profile;
    use Config::Apple::Profile::Payload::Certificate::PKCS12;
    
    my $cert = new Config::Apple::Profile::Payload::Certificate::PKCS12;
    $cert->payload->{PayloadIdentifier} = 'local.acme.key.user10';
    $cert->payload->{PayloadDisplayName} = 'Private key & cert';
    $cert->payload->{PayloadDescription} = 'The private key and certificate for employee #10';
    $cert->payload->{PayloadOrganization} = 'Acme, Inc.';
    $cert->payload->{PayloadCertificateFileName} = 'user10.p12'; 
    $cert->payload->{Password} = 'Monkey123'; # DON'T DO THIS IN REAL LIFE!!!
    $cert->payload->{PayloadContent} = '.................'; # Binary data here
    
    my $profile = new Config::Apple::Profile;
    push @{$profile->content}, $cert;
    
    print $profile->export;
    
    
=head1 DESCRIPTION

This class implements the PKCS12 type of Certificate payload.

This payload contains a single certificate, and the certificate's private key,
in a PKCS#12 container.  The container is encrypted with a password.

This payload is used to hold B<only one> certificate.  If you have any
intermediate certificates, you will need to use a second Certificate payload
(either a PEM or a PKCS1) to hold each intermediate certificate.


=head1 PAYLOAD KEYS

All of the payload keys defined in 
L<Config::Apple::Profile::Payload::Common::Certificate> are used by this
payload.

This payload has the following additional keys:

=head2 C<Password>

This is the password needed to decrypt the PKCS#12 file.  If no password is
provided, the user will be prompted to enter the password when installing the
profile.

B<WARNING:> iOS 7 and 8 seem to have problems with identity certificates that do
not have the C<Password> key in the payload.  More information, and status,
are in L<https://github.com/akkornel/Config-Apple-Profile/issues/7>.

=head2 C<PayloadType>

This is fixed to the string C<com.apple.security.pkcs12>.

=head2 C<PayloadVersion>

This is fixed to the value C<1>.

=cut

Readonly our %payloadKeys => (
    # Bring in the certificate keys...
    %Config::Apple::Profile::Payload::Certificate::payloadKeys,
    
    # ... and define our own!
    'Password' => {
        type => $ProfileString,
        description => 'The password used to decrypt the file.',
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
        optional => 1,
        private => 1,
    },
    
    # Since we can't go any deeper, define the type and version!
    'PayloadType' => {
        type => $ProfileString,
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
        value => 'com.apple.security.pkcs12',
    },
    'PayloadVersion' => {
        type => $ProfileNumber,
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
        value => 1,
    },
);  # End of %payloadKeys



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