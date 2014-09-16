# This is the code for Config::Apple::Profile::Payload::Certificate.
# For Copyright, please see the bottom of the file.

package Config::Apple::Profile::Payload::Certificate;

use 5.14.4;
use strict;
use warnings FATAL => 'all';
use base qw(Config::Apple::Profile::Payload::Common);

our $VERSION = '0.55';

use Readonly;
use Config::Apple::Profile::Payload::Common;
use Config::Apple::Profile::Payload::Types qw(:all);

=encoding utf8

=head1 NAME

Config::Apple::Profile::Payload::Certificate - Base class for the four
different Certificate payload types.

=head1 DESCRIPTION

This class I<partially> implements the Certificate payload.  This payload
is used to send certificates, and certificate-key pairs, to a device.

This payload is typically used early in the provisioning process, in order to
load a non-standard certificate authority (or intermediate certificate) onto the
device.  In addition, this payload can be used to load a user's private key and
public certificate onto the phone, so that it can be used for email (using
S/MIME) and web (client certificate) authentication.

This payload may be used to hold root certificates or intermediate certificates.
The OS will examine the certificate when you try to install it, in order to
determine what type of certificate is being installed.

B<NOTE:>  Installing a certificate does not automatically make it trusted!  In
order for the OS to trust a certificate, the entire chain (from a root cert
down) must be present.  Eveb if the root already exists on the device, you may
still need to install an intermediate certificate.

B<NOTE:>  As per L<http://support.apple.com/kb/TS4133>, starting with iOS 5,
if a certificate chain includes a cert that uses MD5 hashing, then that cert,
I<along with every cert below it>, will be untrusted.  You should only ever use
certificates with SHA signatures, and preferably SHA-256 or better.

B<NOTE:> Typically, you will B<not> use this module directly!  Apple defines
four different types of certificate payloads, each with a different identifier.
Please use one of the L<Config::Apple::Profile::Payload::Certificate::>
subclasses.


=head1 PAYLOAD KEYS

All of the payload keys defined in L<Config::Apple::Profile::Payload::Common>
are used by this payload.

This payload has the following additional keys:

=head2 C<PayloadCertificateFileName>

I<Optional>

The name of the certificate file.  As far as the author knows, this isn't really
used for anything, but you never know!

=head2 C<PayloadContent>

This is where the actual certificate goes.  The contents may be text (as in a
PEM-format certificate), or binary (as in a DER-format certificate).

As a reminder, this key takes binary data, even if that data happens to be
text.  You do not need to worry about the encoding.

B<WARNING: > iOS does not trust certificates that use MD5 as the signature
method.  Such certificates can be installed, but they will not be trusted, and
will cause the user to see warnings.

B<WARNING: > Certificates with 1024-bit RSA keys are rapidly becoming untrusted
by browsers.  Such certificates can be installed, but they are quickly going the
way of MD5 certificates (see the warning above).

B<WARNING: > Certificates with SHA-1 signatures are going to start losing trust
in many browsers starting in 2016.  Plan ahead by minting new certificates with
SHA-256 signatures!

=cut

Readonly our %payloadKeys => (
    # Bring in the common keys...
    %Config::Apple::Profile::Payload::Common::payloadKeys,
    
    # ... and define our own!
    'PayloadCertificateFileName' => {
            type => $ProfileString,
            description => "The certificate's filename.",
            optional => 1,
        },
    'PayloadContent' => {
            type => $ProfileData,
            description => "The certificate's contents, in binary form.",
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