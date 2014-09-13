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
use XML::AppleConfigProfile::Payload::Common;
use XML::AppleConfigProfile::Payload::Types qw($ProfileArray $ProfileNumber);

use base qw(XML::AppleConfigProfile::Payload::Common);

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

# TODO: Test STORESIZE, CLEAR, and SPLICE

# We will be testing the following
#  * Storing into an array should fail
#  * Deleting from an array should fail
#  * Exporting as a plist should work
#  * Clearing an array shoud work
#  * Putting items into a cleared array should work
#  * All forms of splicing should work:
#    * Splicing to clear an array
#    * 

plan tests => 2 + 4 + (1 + 20 + 1);

# Create an array to use for testing
my $object = new Local::Array;
my $array = $object->payload->{arrayField};

# First, put the numbers 1 to 20 into the array
lives_ok { push @$array, (11..20); } 'Push numbers onto array';
lives_ok { unshift @$array, (1..10); } 'Unshift numbers onto array';


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


# Clear the array, and make sure it's now empty

# Add 5 items to the array

# Splice 5 items onto the beginning

# Splice 3 items onto the end

# Splice 7 items in near the middle

# Remove 3 items from near the middle

# Remove 5 items off the end

# Check that the array has 12 items, in expected order

# Splice the array into emptiness

# Check that the array is empty

# Done!
done_testing();