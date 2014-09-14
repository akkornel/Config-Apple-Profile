# This is the code for XML::AppleConfigProfile::Payload::Certificate::PEM.
# For Copyright, please see the bottom of the file.

package XML::AppleConfigProfile::Payload::Certificate::PEM;

use 5.14.4;
use strict;
use warnings FATAL => 'all';
use base qw(XML::AppleConfigProfile::Payload::Certificate);

our $VERSION = '0.00_001';

use Readonly;
use XML::AppleConfigProfile::Targets qw(:all);
use XML::AppleConfigProfile::Payload::Certificate;
use XML::AppleConfigProfile::Payload::Types qw($ProfileNumber $ProfileString);


=encoding utf8

=head1 NAME

XML::AppleConfigProfile::Payload::Certificate::PEM - Certificate payload with
a PEM-format certificate.

=head1 SYNOPSIS

    use XML::AppleConfigProfile;
    use XML::AppleConfigProfile::Payload::Certificate::PEM;
    
    my $cert = new XML::AppleConfigProfile::Payload::Certificate::PEM;
    $cert->payload->{PayloadIdentifier} = 'local.acme.CAcert';
    $cert->payload->{PayloadDisplayName} = 'AcmeCorp internal CA';
    $cert->payload->{PayloadDescription} = 'The certificate authority used for internal web sites.';
    $cert->payload->{PayloadOrganization} = 'Acme, Inc.';
    $cert->payload->{PayloadCertificateFileName} = 'acme.crt'; 
    $cert->payload->{PayloadContent} = '.................'; # Long string here
    
    my $profile = new XML::AppleConfigProfile;
    push @{$profile->content}, $cert;
    
    print $profile->string;
    
=head1 DESCRIPTION

This class implements the PEM type of Certificate payload.

This payload contains a single certificate, in a PKCS#1 container,
PEM-encoded.  If you have a file that has "BEGIN CERTIFICATE"
in it, you've probably got this type of certificate.

This payload is used to hold B<only one> certificate.  If you have multiple
certificates, use multiple payloads.


=head1 PAYLOAD KEYS

All of the payload keys defined in 
L<XML::AppleConfigProfile::Payload::Common::Certificate> are used by this
payload.

This payload has the following additional keys:

=head2 C<PayloadType>

This is fixed to the string C<com.apple.security.pem>.

=head2 C<PayloadVersion>

This is fixed to the value C<1>.

=cut

Readonly our %payloadKeys => (
    # Bring in the certificate keys...
    %XML::AppleConfigProfile::Payload::Certificate::payloadKeys,
    
    # Since we can't go any deeper, define the type and version!
    'PayloadType' => {
        type => $ProfileString,
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
        value => 'com.apple.security.pem',
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