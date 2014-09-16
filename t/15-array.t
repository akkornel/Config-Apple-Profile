#!perl -T

# Test suite 15-array: Tests against common array stuff.
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


package Local::Array;

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


use Config;
use Data::GUID;
use Readonly;
use Test::Exception;
use Test::More;


# Most array functionality is tested as part of the tests that are done on the
# basic data types.  However, there are some array-specific tests that are
# here.

# We will be testing the following
#  * Storing into an array should fail
#  * Deleting from an array should fail
#  * Exporting as a plist should work
#  * Clearing an array shoud work
#  * Putting items into a cleared array should work
#  * All forms of splicing should work:
#    * Splice into the start
#    * Splice into the end
#    * Splice into the middle
#    * Remove some from the middle
#    * Remove some from the end
#    * Splice the entire array

plan tests => 4 + 4 + (1 + 20 + 1) + 4 + 2 + (4 * 2) + (5 + 7) + 13 + 15;

# Create an array to use for testing
my $object = new Local::Array;
my $array = $object->payload->{arrayField};

# First, put the numbers 1 to 20 into the array
lives_ok { push @$array, (11..20); } 'Push numbers onto array';
lives_ok { unshift @$array, (1..10); } 'Unshift numbers onto array';
cmp_ok(exists $array->[19], '==', 1, 'Confirm index 19 exists');
cmp_ok(exists $array->[20], '==', 0, 'Confirm index 20 does not exist');


# Storing into indexes should fail (weather they exist or not)
# Deleting should also fail
dies_ok { $array->[0] = 0; } 'Overwrite existing number';
dies_ok { $array->[20] = 21; } 'Store new number';
dies_ok { delete $array->[0]; } 'Delete index';
dies_ok { delete $array->[20]; } 'Delete invalid index';


# See if we got a 20-entry plist
my $plist;
lives_ok { $plist = $object->plist } 'Convert to plist';
my $plist_array = $plist->value->{arrayField};

# Go through the plist; make sure the array is there and ordered correctly
my $i = 1;
foreach my $item (@$plist_array) {
    cmp_ok($item->value, '==', $i, 'Check plist array index ' . ($i-1));
    $i++;
}
cmp_ok($i, '==', 21, 'Confirm 20 items were read');


# Make sure expanding the array by STORESIZE does nothing
lives_ok { $#{$array} = 30; } 'Try to grow array';
cmp_ok(scalar @$array, '==', 20, 'Confirm array did not grow');

# Try to use STORESIZE to shrink the array by 4 items
# We're subtracing 5 because we're changing the max index, which is offset by 1
lives_ok { $#{$array} = scalar(@$array) - 5; } 'Try to shrink array';
cmp_ok(scalar @$array, '==', 16, 'Confirm array is now smaller by 4');


# Clear the array, and make sure it's now empty
lives_ok { @$array = (); } 'Clear array';
cmp_ok(scalar @$array, '==', 0, 'Confirm array is empty');


# A helper sub for the next section
sub compare_arrays {
    my ($array1, $array2) = @_;
    
    # Confirm lenghts are identical
    cmp_ok(scalar @$array1, '==', scalar @$array2, 'Check array lengths');
    
    # Compare arrays
    for (my $i = 0; $i < scalar @$array1; $i++) {
        cmp_ok($array1->[$i], '==', $array2->[$i], "Compare index $i");
    }
}

# Use a few arrays for tracking
my @reference_array = ();
my @items_returned = ();


# Add 5 items to the array
lives_ok { push @$array, (6..10); } 'Add 5 items to array';
push @reference_array, (6..10);
cmp_ok(scalar @$array, '==', 5, 'Confirm array has 5 items');

# Splice 5 items onto the beginning
lives_ok { @items_returned = splice @$array, 0, 0, (1..5); }
         'Splice 5 items at start of array';
splice @reference_array, 0, 0, (1..5);
cmp_ok(scalar @items_returned, '==', 0, '... nothing returned');

# Splice 3 items onto the end
lives_ok { @items_returned = splice @$array, (scalar @$array), 0, (997..999); }
         'Splice 3 items at end of array';
splice @reference_array, (scalar @reference_array), 0, (997..999);
cmp_ok(scalar @items_returned, '==', 0, '... nothing returned');

# Splice 7 items in near the middle
lives_ok { @items_returned = splice @$array, 6, 0, (100..106); }
         'Splice 7 items in middle of array';
splice @reference_array, 6, 0, (100..106);
cmp_ok(scalar @items_returned, '==', 0, '... nothing returned');


# Remove 3 items from near the middle
lives_ok { @items_returned = splice @$array, 4, 3; }
         'Remove 3 items from near the middle';
splice @reference_array, 4, 3;
compare_arrays(\@items_returned, [5,6,100]);

# Remove 5 items off the end
lives_ok { @items_returned = splice @$array, -5, 5; }
         'Remove 5 items from the end';
splice @reference_array, -5, 5;
compare_arrays(\@items_returned, [9,10,997,998,999]);


# Check that the array has 12 items, in expected order
compare_arrays($array, \@reference_array);


# Splice the array into emptiness
lives_ok { @items_returned = splice @$array; }
         'Splice array into nothingness';
compare_arrays(\@items_returned, \@reference_array);

# Check that the array is empty
cmp_ok(scalar @$array, '==', 0, 'Confirm array is empty');


# Done!
done_testing();