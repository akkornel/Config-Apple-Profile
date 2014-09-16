#!perl -T

# Test suite 37-Email: Tests against the Email payload type.
# 
# Copyright © 2014 A. Karl Kornel.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of either: the GNU General Public License as published
# by the Free Software Foundation; or the Artistic License.
# 
# See http://dev.perl.org/licenses/ for more information.

use 5.14.4;
use strict;
use warnings FATAL => 'all';


use Config;
use Data::GUID;
use Readonly;
use Test::Exception;
use Test::More;
use Config::Apple::Profile::Payload::Email;
use Config::Apple::Profile::Payload::Types qw(:all);



# This is the list of keys we expect to have in this payload
my @keys_expected = (
    [EmailAccountDescription => $ProfileString],
    [EmailAccountName => $ProfileString],
    [EmailAddress => $ProfileString],
    [EmailAccountType => $ProfileString],
    [IncomingMailServerHostName => $ProfileString],
    [IncomingMailServerPortNumber => $ProfileNumber],
    [IncomingMailserverUseSSL => $ProfileBool],
    [IncomingMailServerAuthentication => $ProfileString],
    [IncomingMailServerUsername => $ProfileString],
    [IncomingPassword => $ProfileString],
    [OutgoingMailServerHostName => $ProfileString],
    [OutgoingMailServerPortNumber => $ProfileNumber],
    [OutgoingMailserverUseSSL=> $ProfileBool],
    [OutgoingMailServerAuthentication => $ProfileString],
    [OutgoingMailServerUsername => $ProfileString],
    [OutgoingPassword => $ProfileString],
    [OutgoingPasswordSameAsIncomingPassword => $ProfileBool],
    [SMIMEEnabled => $ProfileBool],
    [SMIMESigningCertificateUUID => $ProfileUUID],
    [SMIMEEncryptionCertificateUUID => $ProfileUUID],
    [PreventMove => $ProfileBool],
    [PreventAppSheet => $ProfileBool],
    [disableMailRecentsSyncing => $ProfileBool],
    [PayloadType => $ProfileString],
    [PayloadVersion => $ProfileNumber],
);


# First, make sure payload->keys returns all expected Email payload keys
# Also, check for the correct PayloadType and PayloadVersion
# Finally, check the value-checking for:
#   * [Incoming/Outgoing]MailServerAuthentication
#   * [Incoming/Outgoing]MailServerPortNumber
#   * [Incoming/Outgoing]MailServerHostName
#   * EmailAccountType
#   * EmailAddress

plan tests =>   2*scalar(@keys_expected) + 2
              + 4 + 4
              + (7 * 2)
              + 2 * (47 + 3 + 3)
              + (2 * 4) + 4
;


# Create our object
my $object = new Config::Apple::Profile::Payload::Email;
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
cmp_ok($keys->{PayloadType}->{value}, 'eq', 'com.apple.mail.managed',
       'Check PayloadType has correct value'
);
cmp_ok($keys->{PayloadVersion}->{value}, '==', 1,
       'Check PayloadVersion has correct value'
);


# Check email addresses
foreach my $email (qw(karl@kornel.us
                      karl+cpan@kornel.name
                      some!yo@google.com
                      user12@corpnet.local
)) {
    lives_ok { $payload->{EmailAddress} = $email } "Try valid email $email";
}

foreach my $email ('!karl', 'karl@', '', undef) {
    dies_ok { $payload->{EmailAddress} = $email }
            ("Try bad email" . defined($email) ? $email : 'undef');
}


# Check port number
foreach my $name (qw(IncomingMailServerPortNumber
                     OutgoingMailServerPortNumber
)) {
    dies_ok { $payload->{$name} = 0; } "$name Try port 0";
    lives_ok { $payload->{$name} = 1; } "$name Try port 1";
    lives_ok { $payload->{$name} = 65534; } "$name Try port 65,534";
    dies_ok { $payload->{$name} = 65_535; } "$name Try port 65,535";
    dies_ok { $payload->{$name} = -1; } "$name Try port -1";
    dies_ok { $payload->{$name} = 'Karl'; } "$name Try a string";
    dies_ok { $payload->{$name} = undef; } "$name Try undef";
}


# Check hostname
foreach my $name (qw(IncomingMailServerHostName
                     OutgoingMailServerHostName
)) {
    dies_ok { $payload->{$name} = 0; } "$name Try IP 0";
    
    lives_ok { $payload->{$name} = '0.0.0.0'; } "$name Try IP 0.0.0.0";
    lives_ok { $payload->{$name} = '0.0.0.255'; } "$name Try IP 0.0.0.255";
    dies_ok { $payload->{$name} = '0.0.0.256'; } "$name Try IP 0.0.0.256";
    
    lives_ok { $payload->{$name} = '0.0.255.0'; } "$name Try IP 0.0.255.0";
    dies_ok { $payload->{$name} = '0.0.256.0'; } "$name Try IP 0.0.256.0";
    lives_ok { $payload->{$name} = '0.0.255.255'; } "$name Try IP 0.0.255.255";
    dies_ok { $payload->{$name} = '0.0.255.256'; } "$name Try IP 0.0.255.256";
    
    lives_ok { $payload->{$name} = '0.255.0.0'; } "$name Try IP 0.255.0.0";
    dies_ok { $payload->{$name} = '0.256.0.0'; } "$name Try IP 0.256.0.0";
    lives_ok { $payload->{$name} = '0.255.255.0'; } "$name Try IP 0.255.255.0";
    dies_ok { $payload->{$name} = '0.255.256.0'; } "$name Try IP 0.255.256.0";
    dies_ok { $payload->{$name} = '0.256.255.0'; } "$name Try IP 0.256.255.0";
    dies_ok { $payload->{$name} = '0.256.256.0'; } "$name Try IP 0.256.256.0";
    lives_ok { $payload->{$name} = '0.255.255.255'; } "$name Try IP 0.255.255.255";
    dies_ok { $payload->{$name} = '0.255.255.256'; } "$name Try IP 0.255.255.256";
    dies_ok { $payload->{$name} = '0.255.256.255'; } "$name Try IP 0.255.256.255";
    dies_ok { $payload->{$name} = '0.255.256.256'; } "$name Try IP 0.255.256.256";
    dies_ok { $payload->{$name} = '0.256.255.255'; } "$name Try IP 0.256.255.255";
    dies_ok { $payload->{$name} = '0.256.256.255'; } "$name Try IP 0.256.256.255";
    dies_ok { $payload->{$name} = '0.256.256.256'; } "$name Try IP 0.256.256.256";
    
    lives_ok { $payload->{$name} = '255.255.0.0'; } "$name Try IP 255.255.0.0";
    dies_ok { $payload->{$name} = '255.256.0.0'; } "$name Try IP 255.256.0.0";
    lives_ok { $payload->{$name} = '255.255.255.0'; } "$name Try IP 255.255.255.0";
    dies_ok { $payload->{$name} = '255.255.256.0'; } "$name Try IP 255.255.256.0";
    dies_ok { $payload->{$name} = '255.256.255.0'; } "$name Try IP 255.256.255.0";
    dies_ok { $payload->{$name} = '255.256.256.0'; } "$name Try IP 255.256.256.0";
    lives_ok { $payload->{$name} = '255.255.255.255'; } "$name Try IP 255.255.255.255";
    dies_ok { $payload->{$name} = '255.255.255.256'; } "$name Try IP 255.255.255.256";
    dies_ok { $payload->{$name} = '255.255.256.255'; } "$name Try IP 255.255.256.255";
    dies_ok { $payload->{$name} = '255.255.256.256'; } "$name Try IP 255.255.256.256";
    dies_ok { $payload->{$name} = '255.256.255.255'; } "$name Try IP 255.256.255.255";
    dies_ok { $payload->{$name} = '255.256.256.255'; } "$name Try IP 255.256.256.255";
    dies_ok { $payload->{$name} = '255.256.256.256'; } "$name Try IP 255.256.256.256";
    dies_ok { $payload->{$name} = '256.255.0.0'; } "$name Try IP 256.255.0.0";
    dies_ok { $payload->{$name} = '256.256.0.0'; } "$name Try IP 256.256.0.0";
    dies_ok { $payload->{$name} = '256.255.255.0'; } "$name Try IP 256.255.255.0";
    dies_ok { $payload->{$name} = '256.255.256.0'; } "$name Try IP 256.255.256.0";
    dies_ok { $payload->{$name} = '256.256.255.0'; } "$name Try IP 256.256.255.0";
    dies_ok { $payload->{$name} = '256.256.256.0'; } "$name Try IP 256.256.256.0";
    dies_ok { $payload->{$name} = '256.255.255.255'; } "$name Try IP 256.255.255.255";
    dies_ok { $payload->{$name} = '256.255.255.256'; } "$name Try IP 256.255.255.256";
    dies_ok { $payload->{$name} = '256.255.256.255'; } "$name Try IP 256.255.256.255";
    dies_ok { $payload->{$name} = '256.255.256.256'; } "$name Try IP 256.255.256.256";
    dies_ok { $payload->{$name} = '256.256.255.255'; } "$name Try IP 256.256.255.255";
    dies_ok { $payload->{$name} = '256.256.256.255'; } "$name Try IP 256.256.256.255";
    dies_ok { $payload->{$name} = '256.256.256.256'; } "$name Try IP 256.256.256.256";
    
    foreach my $hostname (qw(hostname hostname-1 longerHostName
    )) {
        lives_ok { $payload->{$name} = $hostname } "$name Try hostname $hostname";
    }

    foreach my $domainname (qw(hostname.domain
                               something.local
                               host.domaine1.domainy2.net
    )) {
        lives_ok { $payload->{$name} = $domainname } "$name Try domain $domainname";
    }
}


# Check fixed strings
lives_ok { $payload->{EmailAccountType} = 'EmailTypePOP'; }
         'Try type EmailTypePOP';
lives_ok { $payload->{EmailAccountType} = 'EmailTypeIMAP'; }
         'Try type EmailTypeIMAP';
dies_ok { $payload->{EmailAccountType} = ''; }
         'Try empty EmailAccountType';
dies_ok { $payload->{EmailAccountType} = 'Karl!'; }
         'Try invalid EmailAccountType';

foreach my $name (qw(IncomingMailServerAuthentication
                     OutgoingMailServerAuthentication
)) {
    lives_ok { $payload->{$name} = 'EmailAuthPassword'; }
             'Try authentication EmailAuthPassword';
    lives_ok { $payload->{$name} = 'EmailAuthNone'; }
             'Try authentication EmailAuthNone';
    dies_ok { $payload->{$name} = ''; }
             "Try empty $name";
    dies_ok { $payload->{$name} = 'Karl!'; }
             "Try invalid $name";
}


# Done!
done_testing();