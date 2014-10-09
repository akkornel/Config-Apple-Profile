#!perl -T

# Test suite 14-dict: Tests against common dictionary stuff.
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


package Local::Dict;

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

use Readonly;
use Test::Exception;
use Test::More;


# Most dict functionality is tested as part of the tests that are done on the
# basic data types.  However, there are some dict-specific tests that are
# here.

# We will be testing the following
#  * Inserting a range of entries works
#  * Plist conversion works
#  * All iterator methods work
#  * (scalar tests will be included in the above)
#  * Deletion works
#  * Clear works

plan tests =>   (20 + 1)          # Value insertion
              + 2 + (2 * 20)      # Plist tests
              + (1 * 20) + 1      # keys() tests
              + (1 * 20) + 1      # values() tests
              + (2 * 20) + 1      # each() tests
              + 4 + 1 + (2 * 16)  # delete tests
              + 3                 # Clear tests
;


# Create a dictionary to use for testing, along with a reference
my $object = new Local::Dict;
my $dict = $object->payload->{dictField};
my $reference = {};


# First, insert some numbers into the dictionaries
map {
    lives_ok { $dict->{"test$_"} = $_; } "Test insertion #$_";
    $reference->{"test$_"} = $_;
} (1..20);

# Check the number of elements inserted
cmp_ok(scalar keys %$dict, '==', scalar keys %$reference,
       'Check size after insert'
);


# See if we got a 20-entry dictionary plist
my $plist;
lives_ok { $plist = $object->plist; } 'Convert to plist';
my $plist_hash = $plist->value->{dictField};
cmp_ok(scalar keys %{$plist_hash->value}, '==', scalar keys %$dict,
       'Check plist element count'
);

# In the generated plist, check for key presence, and for proper value
foreach my $i (1..20) {
    ok(exists $plist_hash->value->{"test$i"}, "Check entry $i exists");
    cmp_ok($i, 'eq', $plist_hash->value->{"test$i"}->value,
           "Check entry $i value"
    );
}


# Test all of the iterators
my %expected_values;

# Make sure "keys" works
%expected_values = ();
foreach my $key (keys %$dict) {
    ok(!exists $expected_values{$key}, "Key $key is new");
    $expected_values{$key} = $key;
}
cmp_ok(scalar keys %expected_values, '==', scalar keys %$dict,
       'Confirm all keys returned'
);

# Make sure "values" works
%expected_values = ();
foreach my $value (values %$dict) {
    ok(!exists $expected_values{$value}, "Value $value is new");
    $expected_values{$value} = $value;
}
cmp_ok(scalar keys %expected_values, '==', scalar keys %$dict,
       'Confirm all values returned'
);

# Make sure "each" works:  Each key should be new to us, and the value should
# be correct for the key.
%expected_values = ();
for (my ($key, $value) = each %$dict;
     defined $key;
     ($key, $value) = each %$dict
) {
    ok(!exists $expected_values{$key}, "Key $key is new");
    cmp_ok($key, 'eq', "test$value", 'Value matches key');
    $expected_values{$key} = $value;
}
cmp_ok(scalar keys %expected_values, '==', scalar keys %$dict,
       'Confirm all key/value pairs returned'
);


# Delete 4 random keys
my @keys_to_delete = (keys %$dict)[0..3];
foreach my $key_to_delete (@keys_to_delete) {
    lives_ok { delete $dict->{$key_to_delete}; } "Delete key $key_to_delete";
    delete $reference->{$key_to_delete};
}
cmp_ok(scalar keys %$dict, '==', scalar keys %$reference,
       'Check size after delete'
);

# Make sure all remaining keys are unharmed
foreach my $remaining_key (keys %$reference) {
    ok(exists $dict->{$remaining_key}, "Key $remaining_key remains");
    cmp_ok('test' . $dict->{$remaining_key}, 'eq', $remaining_key,
           "Key $remaining_key unharmed"
    );
}


# Clear the hash, and make sure it's now empty
lives_ok { %$dict = (); } 'Clear dictionary';
cmp_ok(scalar keys %$dict, '==', 0, 'Confirm dict is empty');
ok(!scalar %$dict, 'Confirm scalar returns false');


# Done!
done_testing();