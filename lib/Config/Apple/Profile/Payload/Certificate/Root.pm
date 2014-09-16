# This is the code for Config::Apple::Profile::Payload::Certificate::Root.
# For Copyright, please see the bottom of the file.

package Config::Apple::Profile::Payload::Certificate::Root;

use 5.14.4;
use strict;
use warnings FATAL => 'all';
use base qw(Config::Apple::Profile::Payload::Certificate);

our $VERSION = '0.55';

use Readonly;
use Config::Apple::Profile::Targets qw(:all);
use Config::Apple::Profile::Payload::Certificate;
use Config::Apple::Profile::Payload::Types qw($ProfileNumber $ProfileString);


=encoding utf8

=head1 NAME

Config::Apple::Profile::Payload::Certificate::Root - Certificate payload with
a DER-format certificate.

=head1 SYNOPSIS

    use Config::Apple::Profile;
    use Config::Apple::Profile::Payload::Certificate::Root;
    
    my $cert = new Config::Apple::Profile::Payload::Certificate::Root;
    $cert->payload->{PayloadIdentifier} = 'local.acme.CAcert';
    $cert->payload->{PayloadDisplayName} = 'AcmeCorp internal CA';
    $cert->payload->{PayloadDescription} = 'The certificate authority used for internal web sites.';
    $cert->payload->{PayloadOrganization} = 'Acme, Inc.';
    $cert->payload->{PayloadCertificateFileName} = 'acme.crt'; 
    $cert->payload->{PayloadContent} = '.............'; # Long binary data here
    
    my $profile = new Config::Apple::Profile::Profile;
    push @{$profile->content}, $cert;
    
    print $profile->export;
    
=head1 DESCRIPTION

This class implements the root type of Certificate payload.

This payload contains a single certificate, in a PKCS#1 container,
DER-encoded.  For reference, pretty much any certificate you get, when you are
just getting a certificate, will be in a PKCS#1 container.  DER encoding is a
binary encoding, it's not the "BEGIN CERTIFICATE" type of encoding (that's PEM).

This payload is used to hold B<only one> certificate.  If you have multiple
certificates, use multiple payloads.

B<NOTE:>  This type is exactly the same as the C<pkcs1> type of Certificate
payload.


=head1 PAYLOAD KEYS

All of the payload keys defined in 
L<Config::Apple::Profile::Payload::Common::Certificate> are used by this
payload.

This payload has the following additional keys:

=head2 C<PayloadType>

This is fixed to the string C<com.apple.security.root>.

=head2 C<PayloadVersion>

This is fixed to the value C<1>.

=cut

Readonly our %payloadKeys => (
    # Bring in the certificate keys...
    %Config::Apple::Profile::Payload::Certificate::payloadKeys,
    
    # Since we can't go any deeper, define the type and version!
    'PayloadType' => {
        type => $ProfileString,
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
        value => 'com.apple.security.root',
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