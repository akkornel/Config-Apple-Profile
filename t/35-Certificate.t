#!perl -T

# Test suite 35-Certificate: Test for proper handling of Certificate payload.
# 
# Copyright © 2014 A. Karl Kornel.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of either: the GNU General Public License as published
# by the Free Software Foundation; or the Artistic License.
# 
# See http://dev.perl.org/licenses/ for more information.

use strict;
use warnings FATAL => 'all';


use Config::Apple::Profile::Config qw($ACP_OPENSSL_PATH);
use Config::Apple::Profile::Payload::Certificate::PEM;
use Config::Apple::Profile::Payload::Certificate::PKCS1;
use Config::Apple::Profile::Payload::Certificate::PKCS12;
use Config::Apple::Profile::Payload::Certificate::Root;
use Config::Apple::Profile::Payload::Types qw(:all);
use Cwd qw(abs_path);
use File::Spec;
use Readonly;
use Test::Exception;
use Test::More;

# Since we want taint mode, we must get rid of PATH for our test suite to run
my $old_PATH;
if (exists $ENV{PATH}) {
    $old_PATH = $ENV{PATH};
    delete $ENV{PATH};
}


# This is the list of keys we expect to have in this payload
Readonly my %keys_expected => (
    'PEM' => [
        [PayloadCertificateFileName => $ProfileString],
        [PayloadContent => $ProfileData],
    ],
    'PKCS1' => [
        [PayloadCertificateFileName => $ProfileString],
        [PayloadContent => $ProfileData],
    ],
    'PKCS12' => [
        [Password => $ProfileString],
        [PayloadCertificateFileName => $ProfileString],
        [PayloadContent => $ProfileData],
    ],
    'Root' => [
        [PayloadCertificateFileName => $ProfileString],
        [PayloadContent => $ProfileData],
    ],
);


# First, make sure that all payload keys exist as expected.
# Then, make sure our four test files can be opened.
# Next, make sure the PEM type loads a PEM file, but not a DER file.
# Do the same type of test with the Root and PKCS1 types (which take DER files).
# Finally, try loading a PKCS12 file.

plan tests =>   2*scalar(@{$keys_expected{'PEM'}}) + 2
              + 2*scalar(@{$keys_expected{'PKCS1'}}) + 2
              + 2*scalar(@{$keys_expected{'PKCS12'}}) + 2
              + 2*scalar(@{$keys_expected{'Root'}}) + 2
              + 4
              + 3 * 2
              + 3
;


# Work out the location of the files we'll be using for our tests
my ($volume, $test_path, $test_file) = File::Spec->splitpath(abs_path(__FILE__));
$test_path = File::Spec->catdir(($test_path, 'files'));
diag   "Running tests with files in "
     . File::Spec->catpath($volume, $test_path, '');


# Create lots of objects!
my $object_pem = new Config::Apple::Profile::Payload::Certificate::PEM;
my $object_pkcs1 = new Config::Apple::Profile::Payload::Certificate::PKCS1;
my $object_pkcs12 = new Config::Apple::Profile::Payload::Certificate::PKCS12;
my $object_root = new Config::Apple::Profile::Payload::Certificate::Root;


# Check for our payload keys
foreach my $subtype (qw(PEM PKCS1 PKCS12 Root)) {
    # Load the keys for the subtype
    my $keys;
    if ($subtype eq 'PEM') {
        $keys = $object_pem->keys;
    }
    elsif ($subtype eq 'PKCS1') {
        $keys = $object_pkcs1->keys;
    }
    elsif ($subtype eq 'PKCS12') {
        $keys = $object_pkcs12->keys;
    }
    elsif ($subtype eq 'Root') {
        $keys = $object_root->keys;
    }
    
    # Check each key in the subtype
    foreach my $key (@{$keys_expected{$subtype}}) {
        my ($expected_name, $expected_type) = @$key;
        
        # Make sure the key exists
        ok(exists $keys->{$expected_name},
           "Check key $expected_name exists (subtype $subtype)");
        cmp_ok($keys->{$expected_name}->{type}, '==',
               $expected_type, "Check key type matches"
        );
    }
    
    # Make sure PayloadType and PayloadVersion are set correctly
    cmp_ok($keys->{PayloadType}->{value}, 'eq',
           'com.apple.security.' . lc($subtype),
           "Check PayloadType has correct value (subtype $subtype)"
    );
    cmp_ok($keys->{PayloadVersion}->{value}, '==', 1,
           "Check PayloadVersion has correct value (subtype $subtype)"
    );
} # Done checking each subtype for the correct keys


# Define and open our support files
Readonly my $pem_file =>
         File::Spec->catpath($volume, $test_path, 'certificate.pem');
my $pem_handle;
if (open $pem_handle, '<', $pem_file) {
    pass('Open file certificate.pem');
}
else {
    diag "OS error: $!";
    pass('Open file certificate.pem');
}

Readonly my $der_file =>
         File::Spec->catpath($volume, $test_path, 'certificate.der');
my $der_handle;
if (open $der_handle, '<', $der_file) {
    pass('Open file certificate.der');
}
else {
    diag "OS error: $!";
    pass('Open file certificate.der');
}
     
Readonly my $pkcs12_file1 =>
        File::Spec->catpath($volume, $test_path, 'identity-empty-password.p12');
my $pkcs12_handle1;
if (open $pkcs12_handle1, '<', $pkcs12_file1) {
    pass('Open file identity-empty-password.p12');
}
else {
    diag "OS error: $!";
    pass('Open file identity-empty-password.p12');
}

Readonly my $pkcs12_file2 =>
       File::Spec->catpath($volume, $test_path, 'identity-password-123456.p12');
my $pkcs12_handle2;
if (open $pkcs12_handle2, '<', $pkcs12_file2) {
    pass('Open file identity-empty-password.p12');
}
else {
    diag "OS error: $!";
    pass('Open file identity-empty-password.p12');
}


# Have our PEM object try to read a PEM, then a non-PEM, file
SKIP: {
    my $payload_pem = $object_pem->payload;
    lives_ok { $payload_pem->{PayloadContent} = $pem_handle; }
             'Load PEM content into PEM object';
    skip 'OpenSSL not found during configuration'
        unless defined($ACP_OPENSSL_PATH);
    dies_ok { $payload_pem->{PayloadContent} = $der_handle; }
           'Load non-PEM content into PEM object';
};
undef $object_pem;


# Have our Root object try to read a DER, then a non-DER, file
SKIP: {
    my $payload_root = $object_root->payload;
    lives_ok { $payload_root->{PayloadContent} = $der_handle; }
             'Load DER content into DER object (Root subtype)';
    skip 'OpenSSL not found during configuration'
        unless defined($ACP_OPENSSL_PATH);
    dies_ok { $payload_root->{PayloadContent} = $pem_handle; }
           'Load non-DER content into DER object (Root subtype)';
};
undef $object_root;


# Have our PKCS1 object try to read a DER, then a non-DER, file
SKIP: {
    my $payload_pkcs1 = $object_pkcs1->payload;
    lives_ok { $payload_pkcs1->{PayloadContent} = $der_handle; }
             'Load DER content into DER object (PKCS1 subtype)';
    skip 'OpenSSL not found during configuration'
        unless defined($ACP_OPENSSL_PATH);
    dies_ok { $payload_pkcs1->{PayloadContent} = $pem_handle; }
           'Load non-DER content into DER object (PKCS1 subtype)';
};
undef $object_pkcs1;


# Have our PKCS12 object load the identity cert with a password
SKIP: {
    my $payload_pkcs12 = $object_pkcs12->payload;
    lives_ok { $payload_pkcs12->{Password} = '123456'; }
             'Set PKCS12 password to 123456';
    lives_ok { $payload_pkcs12->{PayloadContent} = $pkcs12_file2; }
             'Set PKCS12 content';
    skip 'Certificate checking not supported' => 1;
    dies_ok { $payload_pkcs12->{Password} = ''; }
            'Set PKCS12 password to invalid password';
};


# Clean up, restore PATH, and we're done!
close $der_handle;
close $pem_handle;
close $pkcs12_handle1;
close $pkcs12_handle2;

$ENV{PATH} = $old_PATH if defined($old_PATH);

done_testing();