# This is the code for Config::Apple::Profile::Sign.
# For Copyright, please see the bottom of the file.

package Config::Apple::Profile::Sign;

use 5.14.4;
use strict;
use warnings FATAL => 'all';

=head1 NAME

Config::Apple::Profile::Sign - Digitally sign configuration profiles

=head1 SYNOPSIS

    # Stuff Goes Here
    
    
=head1 DESCRIPTION

# Stuff goes here

To sign a configuration profile manually using OpenSSL, you must first
create the .mobileconfig file, which can then be signed using the following
command:

    openssl smime -sign -in your.mobileconfig -out your_signed.mobileconfig
    -outform der -signer your_signing_cert.pem -inkey your_signing_key.key
    -nodetach

Signing works with any version of OpenSSL starting with version 0.9.8.
All of the parameters above are required.  If your signing key is encrypted,
you will be prompted for the passphrase to decrypt the key.

Signing the configuration profile is the last step before distribution.  Once
the configuration profile has been signed, the output will be a binary file that
can not be modified, or else verification will fail.  If you wanted to encrypt
the configuration profile, then you needed to do that right before signing.

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