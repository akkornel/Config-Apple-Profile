#!perl -T

# Test suite 65-WiFi: Tests against the WiFi payload type.
# 
# Copyright © 2014 A. Karl Kornel.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of either: the GNU General Public License as published
# by the Free Software Foundation; or the Artistic License.
# 
# See http://dev.perl.org/licenses/ for more information.

use 5.10.1;
use strict;
use warnings FATAL => 'all';

use Config::Apple::Profile::Payload::WiFi;
use Config::Apple::Profile::Payload::WiFi::EAPClientConfiguration;
use Config::Apple::Profile::Payload::Types qw(:all);
use Readonly;
use Test::Exception;
use Test::More;


# This is the list of keys we expect to have in this payload
my @keys_expected = (
    [SSID_STR => $ProfileString],
    [HIDDEN_NETWORK => $ProfileBool],
    [AutoJoin => $ProfileBool],
    [EncryptionType => $ProfileString],
    [IsHotspot => $ProfileBool],
    [DomainName => $ProfileString],
    [ServiceProviderRoamingEnabled => $ProfileBool],
    [RoamingConsortiumOIs => $ProfileArray],
    [NAIRealmNames => $ProfileArray],
    [MCCAndMNCs => $ProfileArray],
    [DisplayedOperatorName => $ProfileString],
    [ProxyType => $ProfileString],
    [Password => $ProfileString],
    [EAPClientConfiguration => $ProfileClass],
    [PayloadCertificateUUID => $ProfileUUID],
    [ProxyServer => $ProfileString],
    [ProxyPort => $ProfileNumber],
    [ProxyUsername => $ProfileString],
    [ProxyPassword => $ProfileString],
    [ProxyPACURL => $ProfileString],
    [ProxyPACFallbackAllowed => $ProfileBool],
);


# First, make sure all our payload keys are accounted for.
# Next, check that validation is happening properly:
#  * EncryptionType must be 'Any', 'WEP', 'WPA', or 'None'
#  * MCCAndMNCs must be a string with a 6-digit number
#  * ProxyPort must be a valid port number

plan tests =>   2*scalar(@keys_expected) + 2 # Key name, type, subtype checks
              + 8                            # EncryptionType checks
              + 8                            # MCCAndMNCs checks
              + 8                            # ProxyPort checks
;


# Create our object
my $object = new Config::Apple::Profile::Payload::WiFi;
my $keys = $object->keys;
my $payload = $object->payload;


# Check for our payload keys
foreach my $key (@keys_expected) {
    my ($expected_name, $expected_type) = @$key;
    
    # Make sure the key exists
    ok(exists $keys->{$expected_name}, "Check key $expected_name exists");
    cmp_ok($keys->{$expected_name}->{type}, '==',
           $expected_type, "Check key type matches"
    );
}

# Make sure PayloadType and PayloadVersion are set correctly
cmp_ok($keys->{PayloadType}->{value}, 'eq', 'com.apple.wifi.managed',
       'Check PayloadType has correct value'
);
cmp_ok($keys->{PayloadVersion}->{value}, '==', 1,
       'Check PayloadVersion has correct value'
);


# Check EncryptionType
lives_ok { $payload->{EncryptionType} = 'WEP'; }
         'Push WEP to EncryptionType';
lives_ok { $payload->{EncryptionType} = 'WPA'; }
         'Push WPA to EncryptionType';
dies_ok { $payload->{EncryptionType} = 'WPA2'; }
        'Push WPA2 to EncryptionType';
lives_ok { $payload->{EncryptionType} = 'Any'; }
         'Push Any to EncryptionType';
dies_ok { $payload->{EncryptionType} = 'All'; }
        'Push All to EncryptionType';
lives_ok { $payload->{EncryptionType} = 'None'; }
         'Push None to EncryptionType';
dies_ok { $payload->{EncryptionType} = ''; }
        'Push empty string to EncryptionType';
dies_ok { $payload->{EncryptionType} = "Karl\n"; }
        'Push Karl\n to EncryptionType';


# Check MCCAndMNCs
lives_ok { push @{$payload->{MCCAndMNCs}}, '000000'; }
         'Push 000000 to MCCAndMNCs';
lives_ok { push @{$payload->{MCCAndMNCs}}, '159862'; }
         'Push 159862 to MCCAndMNCs';
dies_ok { push @{$payload->{MCCAndMNCs}}, '021ATT'; }
         'Push 021ATT to MCCAndMNCs';
dies_ok { push @{$payload->{MCCAndMNCs}}, 'Karl'; }
         'Push Karl to MCCAndMNCs';
dies_ok { push @{$payload->{MCCAndMNCs}}, ''; }
         'Push empty string to MCCAndMNCs';
dies_ok { push @{$payload->{MCCAndMNCs}}, "152\n366"; }
         'Push 152\n366 to MCCAndMNCs';
dies_ok { push @{$payload->{MCCAndMNCs}}, 000000; }
         'Push 000000 (as int) to MCCAndMNCs';
lives_ok { push @{$payload->{MCCAndMNCs}}, 159862; }
         'Push 159862 (as int) to MCCAndMNCs';


# Check ProxyPort
dies_ok { $payload->{ProxyPort} = -1; } 'Set ProxyPort to -1';
dies_ok { $payload->{ProxyPort} = 0; } 'Set ProxyPort to 0';
lives_ok { $payload->{ProxyPort} = 1; } 'Set ProxyPort to 1';
lives_ok { $payload->{ProxyPort} = 250; } 'Set ProxyPort to 250';
lives_ok { $payload->{ProxyPort} = 32768; } 'Set ProxyPort to 32768';
lives_ok { $payload->{ProxyPort} = 65534; } 'Set ProxyPort to 65534';
dies_ok { $payload->{ProxyPort} = 65535; } 'Set ProxyPort to 65535';
dies_ok { $payload->{ProxyPort} = 65536; } 'Set ProxyPort to 65536';


# Done!
done_testing();