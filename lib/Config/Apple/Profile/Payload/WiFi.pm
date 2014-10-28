# This is the code for Config::Apple::Profile::Payload::WiFi.
# For Copyright, please see the bottom of the file.

package Config::Apple::Profile::Payload::WiFi;

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

Config::Apple::Profile::Payload::Wi-Fi - Class for the Wi-Fi payload type.

=head1 DESCRIPTION

This class implements the Wi-Fi payload.


=head1 INSTANCE METHODS

The following instance methods are provided by this class.

=head2 validate_key($key, $value)

Performs additional validation for certain payload keys in this class:

=over 4

=item * C<EncryptionType>

Only C<WEP>, C<WPA>, C<Any>, and C<None> are accepted as values.

=item * C<MCCAndMNCs>

Only six-digit numbers are accepted.

=item * C<ProxyPort>

This must be a number within the range 1 to 65,535, inclusive.

=back

This is done in addition to the validation performed by the parent class.

See also the documentation in L<Config::Apple::Profile::Payload::Common>.

=cut

sub validate_key {
    my ($self, $key, $value) = @_;
    
    # Let the parent run the basic checks
    my $validated_value = $self->SUPER::validate_key($key, $value);
    return $validated_value if !defined $validated_value;
    
    # Let's check over some of our keys
    # EncryptionType only accepts specific strings
    if ($key eq 'EncryptionType') {
        $validated_value =~ m/^(WEP|WPA|Any|None)$/s;
        
        unless (   ($validated_value eq 'WEP')
                || ($validated_value eq 'WPA')
                || ($validated_value eq 'Any')
                || ($validated_value eq 'None')
        ) {
            ## no critic (ProhibitExplicitReturnUndef)
            return undef;
            ## use critic
        }
    }
    
    # MCCAndMNCs only accepts six-digit numbers
    elsif ($key eq 'MCCAndMNCs') {
        unless ($validated_value =~ m/^\d{6}$/s) {
            ## no critic (ProhibitExplicitReturnUndef)
            return undef;
            ## use critic
        }
    }
    
    # Ports must be numbers from 1 to 65,534 inclusive.
    elsif ($key eq 'ProxyPort') {
        if (   ($validated_value < 1)
            || ($validated_value > 65534)
        ) {
            ## no critic (ProhibitExplicitReturnUndef)
            return undef;
            ## use critic
        }
    }
    
    # At this point, we've checked all of our special keys.  Over to the parent!
    return $validated_value;
}


=head1 PAYLOAD KEYS

All of the payload keys defined in L<Config::Apple::Profile::Payload::Common>
are used by this payload.

This payload has the following additional keys:

=head2 General Configuration


=head3 C<SSID_STR>

A I<string>, this is the SSID (the name) of the Wi-Fi network.


=head3 C<HIDDEN_NETWORK>

I<Optional>

If C<true>, this Wi-Fi network does not broadcast itself, meaning that the SSID
and encryption information must be specified in this configuration.

Defaults to C<false>.


=head3 C<AutoJoin>

I<Optional>

If C<true>, the device will automatically join the Wi-Fi network if it is
detected.  If the device sees multiple Wi-Fi networks that have auto-join
enabled, only one Wi-Fi network will be joined.

Defaults to C<true>.


=head3 C<EncryptionType>

A I<string>.  The type of encryption to support.  Valid values are C<Any>,
C<None>, C<WEP>, and C<WPA>.  C<WPA> includes WPA and WPA2, the -Personal and
-Enterprise versions.

The encryption type specified must exactly match what is configured on the
access point.  For maximum flexibility, with the higher possibility of
connecting to an unexpected access point, use the value C<Any>.


=head2 Encryption Configuration


=head3 C<EAPClientConfiguration>

I<Optional>, for use with WPA- and WPA2-Enterprise encryption.

An object of the class
C<Config::Apple::Profile::Payload::WiFi::EAPClientConfiguration>.  This object
becomes a I<dict> containing the list of supported EAP types and all other
EAP-related configuration, except for a password or identity certificate.

See L<Config::Apple::Profile::Payload::WiFi::EAPClientConfiguration>.

=head3 C<Password>

I<Optional>

A I<string>.  If password-based authentication is used (such as WEP,
WPA-Personal, WPA2-Personal, or -Enterprise with a password-based EAP), this is
the password to use.  If no other authentication methods are available, the user
may be prompted for a password.


=head3 C<PayloadCertificateUUID>

I<Optional>, for use with WPA- and WPA2-Enterprise encryption and EAP-TLS.

A I<UUID>.  This is the UUID of an identity certificate that has already been
loaded onto the device, using a payload class of type
C<Config::Apple::Profile::Payload::Certificate::PKCS12>.  The identity
certificate may be included in the same configuration profile, or in a
previously-installed profile.

See L<Config::Apple::Profile::Payload::Certificate::PKCS12>.


=head2 Hotspot Configuration

The payload keys in this section refer to Hotspot 2.0, also known as Wi-Fi
CERTIFIED Passpoint.  More information on Hotspot 2.0 is available here:

=over 4

=item http://www.wi-fi.org/discover-wi-fi/wi-fi-certified-passpoint

=item http://en.wikipedia.org/wiki/Hotspot_(Wi-Fi)#Hotspot_2.0

=back


=head3 C<IsHotspot>

I<Optional>.  Available in iOS starting with iOS 7.0.

A I<boolean>.  If C<true>, this Wi-Fi network is treated as a hotspot.

Default is C<false>.


=head3 C<DomainName>

I<Optional>.  Available in iOS starting with iOS 7.0.

A I<string>.  The domain name used in Hotspot 2.0 negotiation.

If this payload key is present, the C<SSID_STR> payload key may be omitted.


=head3 C<ServiceProviderRoamingEnabled>

I<Optional>.  Available in iOS starting with iOS 7.0.

A I<boolean>.  Used in Hotspot 2.0 negotation.  If C<true>, connection is
allowed to roaming service providers.

The default value is not specified in the documentation (see issue #13).


=head3 C<RoamingConsortiumOIs>

I<Optional>.  Available in iOS starting with iOS 7.0.

An I<array> of I<strings>.  Used in Hotspot 2.0 negotation, this is a list of
Roaming Consortium Organization Identifiers.


=head3 C<NAIRealmNames>

I<Optional>.  Available in iOS starting with iOS 7.0.

An I<array> of I<strings>.  Used in Hotspot 2.0 negotiation, this is a list of
Network Access Identifier Realm names.


=head3 C<MCCAndMNCs>

I<Optional>.  Available in iOS starting with iOS 7.0.

An I<array> of I<strings>, where each string must be a six-digit number.  Used
in Hotspot 2.0 negotiation, the first three digits of the string are the Mobile
Country Code (MCC) and the last three digits of the string are the Mobile
Network Code (MNC).

B<NOTE:> This is B<not> an array of numbers, this is an array of strings.  That
being said, thanks to the way Perl handles scalars, and how the pushed values
are validated, you can provide a six-digit number and it I<may> be accepted.
If your MCC has any leading zeroes, though, treating it as a number will cause
a validation failure.


=head3 C<DisplayedOperatorName>

Presumed I<Optional>.  Available in iOS starting with iOS 7.0.

A I<string>.  No description is available (see issue #11).


=head2 Proxy Configuration


=head3 C<ProxyType>

I<Optional>.

A I<string>.  Valid values are C<None>, C<Manual>, and C<Auto>.


=head3 C<ProxyServer>

A I<string>.  The proxy server's network address.


=head3 C<ProxyPort>

A I<number>.  The proxy server's port.


=head3 C<ProxyUsername>

I<Optional>.

A I<string>.  The username to use when authenticating to the proxy server.


=head3 C<ProxyPassword>

I<Optional>.

A I<string>.  The password to use when authenticating to the proxy server.


=head3 C<ProxyPACURL>

I<Optional>.

A I<string>.  The URL of the PAC file containing the proxy configuration.


=head3 C<ProxyPACFallbackAllowed>

I<Optional>.

A I<boolean>.  If the PAC file can not be loaded, and this payload key is
C<false>, then this Wi-Fi connection will not be used.  If C<true>, the device
will attempt to connect directly to the destination.

Defaults to C<true>.

=cut

Readonly our %payloadKeys => (
    # Bring in the common keys...
    %Config::Apple::Profile::Payload::Common::payloadKeys,
    
    # ... and define our own!
    # Start with basic network information
    'SSID_STR' => {
        type => $ProfileString,
        description => 'The SSID of the Wi-Fi network.',
        optional => 1,
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'HIDDEN_NETWORK' => {
        type => $ProfileBool,
        description =>    'If false, the device expects the network to be '
                       .  'broadcasting.  Default is false.',
        optional => 1,
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'AutoJoin' => {
        type => $ProfileBool,
        description => 'If false, do not auto-join the network.  Default true.',
        optional => 1,
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'EncryptionType' => {
        type => $ProfileString,
        description => 'The encryption type for the Wi-Fi network.',
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    
    # Encryption Configuration
    'Password' => {
        type => $ProfileString,
        description =>   'If using password-based authentication, this is '
                       . "the user's password.",
        optional => 1,
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'EAPClientConfiguration' => {
        type => $ProfileClass,
        description =>   'If using EAP-based authentication, this provides '
                       . 'the EAP parameters for the connection.',
        optional => 1,
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'PayloadCertificateUUID' => {
        type => $ProfileUUID,
        description =>   'If using certificate-based authentication, this is '
                       . "the UUID of the user's identity certificate",
        optional => 1,
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    
    # HotSpot Configuration
    'IsHotspot' => {
        type => $ProfileBool,
        description =>    'If true, treat the network as a hotspot.  '
                       .  'Default false.',
        optional => 1,
        targets => {
            $TargetIOS => '7.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'DomainName' => {
        type => $ProfileString,
        description => 'Domain name to use for Hotspot 2.0 negotiation.',
        optional => 1,
        targets => {
            $TargetIOS => '7.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'ServiceProviderRoamingEnabled' => {
        type => $ProfileBool,
        description => 'Allow connection to roaming service providers.',
        optional => 1,
        targets => {
            $TargetIOS => '7.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'RoamingConsortiumOIs' => {
        type => $ProfileArray,
        subtype => $ProfileString,
        description =>   'Array of Roaming Consortium OIs, used for '
                       . 'Hotspot 2.0 negotiation.',
        optional => 1,
        targets => {
            $TargetIOS => '7.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'NAIRealmNames' => {
        type => $ProfileArray,
        subtype => $ProfileString,
        description =>   'List of Network Access Identifier realm names, used '
                       . 'for Hotspot 2.0 negotation.',
        optional => 1,
        targets => {
            $TargetIOS => '7.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'MCCAndMNCs' => {
        type => $ProfileArray,
        subtype => $ProfileString,
        description =>   'List of Mobile Country Code (MCC) and Network '
                       . 'Country Code (NCC) pairs, used for Hotspot 2.0 '
                       . 'negotation.',
        optional => 1,
        targets => {
            $TargetIOS => '7.0',
        },
    },
    'DisplayedOperatorName' => {
        type => $ProfileString,
        optional => 1,
        targets => {
            $TargetIOS => '7.0',
            $TargetMACOSX => '10.7', 
        },
    },
    
    # Proxy configuration
    'ProxyType' => {
        type => $ProfileString,
        description => 'The type of proxy to configure.  Default is "None".',
        optional => 1,
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'ProxyServer' => {
        type => $ProfileString,
        description => "The proxy server's network address",
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'ProxyPort' => {
        type => $ProfileNumber,
        description => "The proxy server's port number.",
        optional => 1,
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'ProxyUsername' => {
        type => $ProfileString,
        description => 'An optional username to authenticate to the proxy.',
        optional => 1,
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'ProxyPassword' => {
        type => $ProfileString,
        description => 'An optional password to authenticate to the proxy.',
        optional => 1,
        private => 1,
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'ProxyPACURL' => {
        type => $ProfileString,
        description => 'Optional proxy configuration PAC file URL.',
        optional => 1,
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'ProxyPACFallbackAllowed' => {
        type => $ProfileBool,
        description =>   'If false, device may not connect if PAC file can not '
                       . 'be downloaded.  Default is true.',
        optional => 1,
        targets => {
            $TargetIOS => '7.0',
            $TargetMACOSX => '10.7', 
        },
    },
    
    # Finish with basic payload information
    'PayloadType' => {
        type => $ProfileString,
        value => 'com.apple.wifi.managed',
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'PayloadVersion' => {
        type => $ProfileNumber,
        value => 1,
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