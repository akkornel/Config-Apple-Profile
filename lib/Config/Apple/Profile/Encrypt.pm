# This is the code for Config::Apple::Profile::Encrypt.
# For Copyright, please see the bottom of the file.

package Config::Apple::Profile::Encrypt;

use 5.14.4;
use strict;
use warnings FATAL => 'all';

=head1 NAME

Config::Apple::Profile::Encrypt - Digitally encrypt configuration profiles

=head1 SYNOPSIS

    # Stuff Goes Here
    
    
=head1 DESCRIPTION

# Stuff goes here

To sign a configuration profile manually using OpenSSL, you must first
create the .mobileconfig file, which can then be signed using the following
command:

To encrypt a configuration profile, you must output the C<PayloadContent> key
as its own plist (with the top-level element being C<< <array> >>, not
C<< <plist> >>), and then encrypt the content using the following commands:

    openssl cms -encrypt -in your.mobileconfig_fragment 
    -out your.mobileconfig_fragment.encrypted -outform der -cmsout
    your_recipients_cert.pem
    
    base64 -i your.mobileconfig_fragment.encrypted
    -o your.mobileconfig_fragment.encrypted.base64

Encrypting works with any version of OpenSSL starting with version 1.0.1.
All of the parameters above are required.

Once encrypted and Base64-encoded, the content should be added to the
configuration profile's top-level dictionary, as a data element with the key
C<EncryptedPayloadContent>.  At this point, the configuration profile can be
exported and, if you want, signed.

=cut



# Stuff goes here



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