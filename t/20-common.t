#!perl -T

# Test suite 20-common: Tests against common payload stuff.
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


package Local::RequiredArray;

use Readonly;
use Config::Apple::Profile::Payload::Common;
use Config::Apple::Profile::Payload::Types qw($ProfileArray $ProfileNumber);

use base qw(Config::Apple::Profile::Payload::Common);

Readonly our %payloadKeys => (
    'arrayField' => {
        type => $ProfileArray,
        subtype => $ProfileNumber,
        description => 'An array of numbers',
    }
);


package Local::RequiredDict;

use Readonly;
use Config::Apple::Profile::Payload::Common;
use Config::Apple::Profile::Payload::Types qw($ProfileDict $ProfileNumber);

use base qw(Config::Apple::Profile::Payload::Common);

Readonly our %payloadKeys => (
    'dictField' => {
        type => $ProfileDict,
        subtype => $ProfileNumber,
        description => 'A dictionary of numbers',
    }
);


package main;

use Test::Exception;
use Test::More;
use Config::Apple::Profile::Payload::Common;
use Config::Apple::Profile::Payload::Types qw(:all);


# Much of the functionality of ::Common is covered by the test suites for the
# specific data types.  This suite covers the methods that aren't really
# involved in the prior test suites.

# First, go through our list of payload keys, to make sure we get the common
# keys that we expect.
# (Data type validation is tested elsewhere; we don't need to test that here.)

# Next, make sure ->exportable returns 0, because the ID and UUID aren't set.
# Set Identifier and UUID, and make sure ->exportable works now.

# Run ->populate_id, and make sure nothing changed.
# Clear our ID and UUID, run ->populate_id, and make sure they got set.

plan tests => (2 * 5) + (5 + 2 + 2) + (6 + 8);


my @keys_expected = (
    [PayloadIdentifier => $ProfileIdentifier],
    [PayloadUUID => $ProfileUUID],
    [PayloadDisplayName => $ProfileString],
    [PayloadDescription => $ProfileString],
    [PayloadOrganization => $ProfileString],
);


my $object = new Config::Apple::Profile::Payload::Common;
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


# Test exportable is testing correctly
cmp_ok($object->exportable, '==', 0, 'Exportable should return 0');
$payload->{PayloadUUID} = '08A8C53B-749E-4DBF-9848-7CB38600EBF0';
$payload->{PayloadIdentifier} = 'test';
cmp_ok($object->exportable, '==', 1, '... now it should return 1');
delete $payload->{PayloadUUID};
cmp_ok($object->exportable, '==', 0, '... now it should return 0');
$payload->{PayloadUUID} = '08A8C53B-749E-4DBF-9848-7CB38600EBF0';
delete $payload->{PayloadIdentifier};
cmp_ok($object->exportable, '==', 0, '... it should still return 0');
$payload->{PayloadIdentifier} = 'test';
cmp_ok($object->exportable, '==', 1, '... and now it should return 1');

# Test exportable with an array
my $array_object = new Local::RequiredArray;
my $array_payload = $array_object->payload;
cmp_ok($array_object->exportable, '==', 0,
       'With the array, exportable should return 0'
);
push @{$array_payload->{arrayField}}, 1;
cmp_ok($array_object->exportable, '==', 1,
       '... becomes 1 after inserting into array'
);
undef $array_payload;
undef $array_object;

# Test exportable with a dictionary
SKIP: {
skip 'Waiting for hash ties to be implemented', 2;
my $dict_object = new Local::RequiredDict;
my $dict_payload = $dict_object->payload;
cmp_ok($dict_object->exportable, '==', 0,
       'With the dict, exportable should return 0'
);
$dict_payload->{dictField}->{some_key} = 1;
cmp_ok($dict_object->exportable, '==', 1,
       '... becomes 1 after inserting into dict'
);
undef $dict_payload;
undef $dict_object;
};


# Make sure populate_id doesn't change existing fields
my $original_uuid = $payload->{PayloadUUID};
my $original_identifier = $payload->{PayloadIdentifier};
lives_ok { $object->populate_id; } 'populate_id with filled-in values';
cmp_ok($payload->{PayloadUUID}, '==', $original_uuid,
       'UUID should be unchanged'
);
cmp_ok($payload->{PayloadIdentifier}, 'eq', $original_identifier,
       'Identifier should be unchanged'
);
cmp_ok(defined($payload->{PayloadDisplayName}), '==', 0,
       'PayloadDisplayName should be unchanged'
);
cmp_ok(defined($payload->{PayloadDescription}), '==', 0,
       'PayloadDescription should be unchanged'
);
cmp_ok(defined($payload->{PayloadOrganization}), '==', 0,
       'PayloadOrganization should be unchanged'
);

# Clear our UUID and Identifier, and let them auto-generate
lives_ok { delete $payload->{PayloadUUID}; } 'Delete UUID';
lives_ok { delete $payload->{PayloadIdentifier}; } 'Delete Identifier';
lives_ok { $object->populate_id; } 'populate_id with empty values';
cmp_ok($payload->{PayloadUUID}, '!=', $original_uuid,
       'UUID should be CHANGED'
);
cmp_ok($payload->{PayloadIdentifier}, 'ne', $original_identifier,
       'Identifier should be CHANGED'
);
cmp_ok(defined($payload->{PayloadDisplayName}), '==', 0,
       'PayloadDisplayName should be unchanged'
);
cmp_ok(defined($payload->{PayloadDescription}), '==', 0,
       'PayloadDescription should be unchanged'
);
cmp_ok(defined($payload->{PayloadOrganization}), '==', 0,
       'PayloadOrganization should be unchanged'
);


# Done!
done_testing();