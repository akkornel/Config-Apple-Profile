# This is the code for Config::Apple::Profile::Payload::WiFi::EAPClientConfiguration.
# For Copyright, please see the bottom of the file.

package Config::Apple::Profile::Payload::WiFi::EAPClientConfiguration;

use 5.10.1;
use strict;
use warnings FATAL => 'all';
use base qw(Config::Apple::Profile::Payload::Common);

our $VERSION = '0.87.1';

use Config::Apple::Profile::Config;
use Config::Apple::Profile::Payload::Common;
use Config::Apple::Profile::Payload::Types qw(:all);
use Config::Apple::Profile::Targets qw(:all);
use Readonly;


=encoding utf8

=head1 NAME

Config::Apple::Profile::Payload::Wi-Fi::EAPClientConfiguration - Class for the
EAPClientConfiguration payload key in the Wi-Fi payload.

=head1 DESCRIPTION

This class implements part of the Wi-Fi payload.  Specifically, this class
implements the C<EAPClientConfiguration> dictionary.  This contains all of the
EAP configuration when WPA-Enterprise or WPA2-Enterprise is being used on a
Wi-Fi network.

Even though this class is not a payload in its own right, it can be treated as
a payload.


=head1 INSTANCE METHODS

The following instance methods are provided by this class.


=head2 validate_key($key, $value)

Performs additional validation for certain payload keys in this class:

=over 4

=item * C<AcceptEAPTypes>

This must be C<13>, C<17>, C<18>, C<21>, C<23>, C<25>, or C<43>.

=item * C<TLSTrustedServerNames>

Only valid host and domain names are allowed, although the asterisk (C<*>) is
acceptable as a wildcard.

=item * C<EAPSIMNumberOfRANDs>

This must be either C<2> or C<3>.

=item * C<TTLSInnerAuthentication>

This must be C<PAP>, C<CHAP>, C<MSCHAP>, or C<MSCHAPv2>.

=back

All other payload keys will be checked as usual by the parent class.

See also the documentation in L<Config::Apple::Profile::Payload::Common>.

=cut

# $TLSTrustedServerNames_regex matches hostnames, but allows * as a wildcard
# character.  It is based on $RE{net}{domain}{-keep}{-nospace} from
# Regexp::Common by Damien Conway and Abigail, but rewritten because that
# module's code is not available under the GPL2, which we are.
Readonly my $TLSTrustedServerNames_hostname => qr/
[A-Z0-9*]             # First character can be a letter or a digit
(?:                   # We don't have to have more than 1 character, but...
   [-A-Z0-9*]{0,253}  # Middle characters allow hyphens
   [A-Z0-9*]          # End character is a letter or a digit
)?
/ix;
Readonly my $TLSTrustedServerNames_regex => qr/
^(                                 # Match the whole string; capture the match
$TLSTrustedServerNames_hostname    # We need at least 1 hostname
(?:
 \.                                # Domains require a dot before subsequent
 $TLSTrustedServerNames_hostname   # hostnames, but…
)*                                 # We don't have to have a domain name.
)$
/isx;

sub validate_key {
    my ($self, $key, $value) = @_;
    
    # Let's start by letting the parent do the generic validation.
    my $parent_value = $self->SUPER::validate_key($key, $value);
    return $parent_value if !defined $parent_value;
    
    # Let's check over some of our keys
    # Only allow EAP-type values for AcceptEAPTypes
    if ($key eq 'AcceptEAPTypes') {
        unless (   ($value == 13)
                || ($value == 17)
                || ($value == 18)
                || ($value == 21)
                || ($value == 23)
                || ($value == 25)
                || ($value == 43)
        ) {
            ## no critic (ProhibitExplicitReturnUndef)
            return undef;
            ## use critic
        }
    }
    
    # TLSTrustedServerNames allows hostnames and domains, but also allows * as
    # a wildcard character.
    elsif ($key eq 'TLSTrustedServerNames') {
        if ($value =~ $TLSTrustedServerNames_regex) {
            return $1;
        }
        else {
            ## no critic (ProhibitExplicitReturnUndef)
            return undef;
            ## use critic
        }
    }
    
    # Only allow certain values for TTLSInnerAuthentication
    elsif ($key eq 'TTLSInnerAuthentication') {
        unless (   ($value eq 'PAP')
                || ($value eq 'CHAP')
                || ($value eq 'MSCHAP')
                || ($value eq 'MSCHAPv2')
        ) {
            ## no critic (ProhibitExplicitReturnUndef)
            return undef;
            ## use critic
        }
    }
    
    # EAPSIMNumberOfRANDs must be 2 or 3
    elsif ($key eq 'EAPSIMNumberOfRANDs') {
        ## no critic (ProhibitExplicitReturnUndef)
        return undef unless (($value == 2) || ($value == 3));
        ## use critic
    }
    
    # At this point, we've checked all of our special keys and we're good!
    return $value;
}


=head1 PAYLOAD KEYS

This payload has the following keys:


=head2 C<AcceptEAPTypes>

This is an I<array of numbers>, where each number represents one type of EAP
method to use.

At least one EAP method must be specified.  The following EAP methods are
supported:

=over 4

=item C<13> = EAP-TLS

As defined in RFC 5216, available at L<http://tools.ietf.org/html/rfc5216>.
The client is authenticated using an identity certificate.

=item C<17> = LEAP

The Cisco-developed protocol.  This should not be used for new environments.

=item C<18> = EAP-SIM

As defined in RFC 4186, available at L<http://tools.ietf.org/html/rfc4186>.
The client is authenticated using their phone's SIM, using challenge-response.

=item C<21> = EAP-TTLS

As defined in RFC 5281, available at L<http://tools.ietf.org/html/rfc5281>.
The client is authenticated using a username & password, but that authentication
takes place inside of a TLS connection.

=item C<23> = EAP-AKA

As defined in RFC 5448, available at L<http://tools.ietf.org/html/rfc5448>.
The client is authenticated using their phone's USIM, using challenge-response.

=item C<25> = PEAP

=item C<43> = EAP-FAST

As defined in RFC 4581, available at L<http://tools.ietf.org/html/rfc4851>.
The client is authenticated using a pre-shared credential, or (if none is
available) some other EAP method, embedded in a TLS connection.

=back

If multiple EAP types are listed, Apple's documentataion does not specify the
order that they will be used.


=head2 Basic Authentication Parameters

=head3 C<UserName>

I<Optional>

A I<string>.  This is the exact username to use.  If not provided, the user will
be asked to enter this information during authentication.


=head3 C<OuterIdentity>

I<Optional>, relevent only to TTLS, PEAP, and FAST.

A I<string>.  If present, the value of this string will be used as the username
outside of the encrypted tunnel; the real username will only be passed inside
the encrypted tunnel.


=head3 C<UserPassword>

I<Optional>

A I<string>.  If a password is used during authentication, it will be taken from
here.  If a password is needed, but not already provided, then the user will
be prompted.


=head3 C<OneTimePassword>

I<Optional>

A I<boolean>.  If C<true>, then the user will be asked for a password every time
the device connects to the wireless network.  If C<false>, the password will be
saved for future connections to the wireless network.

Default is C<false>.


=head2 TLS Configuration

=head3 C<PayloadCertificateAnchorUUID>

I<Optional>, used by authentication methods that provide a TLS certificate.

An I<array of UUIDs>.  The UUIDs point to I<Certificate> payloads that have
been loaded onto the device, either as part of this profile or via an already-
installed profile.

When the EAP server provides their TLS certificate, the
device must confirm that the server's certificate is trusted.  If this array is
provided, the device will use it as the list of trusted certificates, for the
purposes of certificate verification and trust.

The EAP server's certificate must pass this test, as well as the test defined in
L</C<TLSTrustedServerNames>>, before the certificate will be trusted.

See L<Config::Apple::Profile::Payload::Certificate> for more information on the
certificate payload types.  See also L</C<TLSAllowTrustExceptions>>.


=head3 C<TLSTrustedServerNames>

I<Optional>, used by authentication methods that provide a TLS certificate.

An I<array of strings>.  Each string is a domain name, with the C<*> wildcard
allowed.  When the EAP server presents its certificate, the certificate's
common name will be checked against this list; if the common name does not
match any of the patterns in the list, the certificate will not be trusted.

The EAP server's certificate must pass this test, as well as the test defined in
L</C<PayloadCertificateAnchorUUID>>, before the certificate will be trusted.

See also L</C<TLSAllowTrustExceptions>>.


=head3 C<TLSAllowTrustExceptions>

I<Optional>, used by authentication methods that provide a TLS certificate.

A I<boolean>.

Certificate trust is automatically determined using the payload keys
C<PayloadCertificateAnchorUUID> and C<TLSTrustedServerNames>.  If both keys are
undefined, then automatic validation fails.  If both keys are defined, and
either test failed, the automatic validation fails.  If only one key is defined,
then automatic validation fails if that one test fails.

If this key is true, and automatic validation had failed, then the user will be
given the option to explicitly trust the certificate, or to cancel the
connection attempt.  If this key is false, then the user will not be given any
option; if automatic validation fails, then the connection fails.

The default value is not fixed:  If either C<PayloadCertificateAnchorUUID> or
C<TLSTrustedServerNames> is defined, then the default value is C<false>.  If
both C<PayloadCertificateAnchorUUID> and C<TLSTrustedServerNames> are undefined,
then the default value is C<true>.


=head3 C<TLSCertificateIsRequired>

I<Optional>, relevent only to PEAP, EAP-TTLS, EAP-FAST, and EAP-TLS.
I<Available in iOS 7.0 and later>.

If C<true>, allows for two-factor authentication for PEAP, EAP-TTLS, and
EAP-FAST.  If C<false>, allowes for zero-factor authentication for EAP-TLS.

The default value is not fixed.  If EAP-TLS is being used, then the default is
C<true>.  For all other EAP types, the default is C<false>. 


=head2 EAP-TTLS Configruation

The key in this section is only used with EAP-TTLS.


=head3 C<TTLSInnerAuthentication>

I<Optional>

A I<string>.  This the the authentication method used inside the tunnel.  Valid
values are:

=over 4

=item C<PAP>

=item C<CHAP>

=item C<MSCHAP>

=item C<MSCHAPv2>

=back

The default is C<MSCHAPv2>.


=head2 EAP-FAST Configuration

The keys in this section are only used with EAP-FAST.


=head3 C<EAPFASTUsePAC>

I<Optional>

A I<boolean>.  If an existing PAC is present, and this key is C<true>, then
use the existing PAC.  Otherwise, the server must use a certificate to prove
its identity.

Default is C<false>.


=head3 C<EAPFASTProvisionPAC>

I<Optional>

A I<boolean>.  If C<true>, allow PAC provisioning.  This key has no effect
unless C<EAPFASTUsePAC> is C<true>.

Default is C<false>.


=head3 C<EAPFASTProvisionPACAnonymously>

I<Optional>

A I<boolean>.  If C<true>, the PAC may be provisioned anonymously.

B<NOTE:>  Anonymous PAC provisioning has known man-in-the-middle attacks.  If
PAC provisioning is used, this key shoudl be set to C<false>.

Default is C<false>.


=head3 C<EAPSIMNumberOfRANDs>

I<Optional>

A I<number>, either C<2> or C<3>.  This is the number of RANDs expected for
EAP-SIM.

Default is C<3>.

=cut

Readonly our %payloadKeys => (
    # We are NOT using the common keys.  We are just defining our own.
    # Since we are not a separate payload, we will not be defining basic keys.
    
    # Basic configuration
    'AcceptEAPTypes' => {
        type => $ProfileArray,
        subtype => $ProfileNumber,
        description => 'The list of EAP types to accept.',
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    
    # Authentication information
    'UserName' => {
        type => $ProfileString,
        description =>   'The exact user name.  If not present, the user is '
                       . 'prompted when they authenticate.',
        optional => 1,
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'OuterIdentity' => {
        type => $ProfileString,
        description => 'The outer identity to use in TTLS, PEAP, and EAP-FAST.',
        optional => 1,
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'UserPassword' => {
        type => $ProfileString,
        description =>   'The password.  If not present, the user is prompted '
                       . 'when they authenticate.',
        optional => 1,
        private => 1,
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'OneTimePassword' => {
        type => $ProfileBool,
        description =>   'Prompt for password whenever connecting to the '
                       . 'wireless network.  Default is false.',
        optional => 1,
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    
    # TLS configuration
    'PayloadCertificateAnchorUUID' => {
        type => $ProfileArray,
        subtype => $ProfileUUID,
        description => 'A list of server certificate UUIDs to trust.',
        optional => 1,
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'TLSTrustedServerNames' => {
        type => $ProfileArray,
        subtype => $ProfileString,
        description => 'A list of common names to explicitly trust.',
        optional => 1,
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'TLSAllowTrustExceptions' => {
        type => $ProfileBool,
        description => 'Allow the user to choose to trust the server cert.',
        optional => 1,
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'TLSCertificateIsRequired' => {
        type => $ProfileBool,
        description => 'Varies depending on the EAP type used.',
        optional => 1,
        targets => {
            $TargetIOS => '7.0',
            $TargetMACOSX => '10.7', 
        },
    },
    
    # TTLS Configuration
    'TTLSInnerAuthentication' => {
        type => $ProfileString,
        description => 'The inner authentication method to use with TTLS.',
        optional => 1,
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    
    # EAP-FAST Configuration
    'EAPFASTUsePAC' => {
        type => $ProfileBool,
        description => 'If trust, use a PAC if available.  Default is false.',
        optional => 1,
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'EAPFASTProvisionPAC' => {
        type => $ProfileBool,
        description => 'Allow PAC provisioning.',
        optional => 1,
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'EAPFASTProvisionPACAnonymously' => {
        type => $ProfileBool,
        description => '[UNSAFE] Provision PAC anonymously. Defaults to false.',
        optional => 1,
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'EAPSIMNumberOfRANDs' => {
        type => $ProfileNumber,
        description => 'The number of expected RANDs for EAP-SIM.  Default is 3.',
        optional => 1,
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
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