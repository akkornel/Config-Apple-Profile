#!perl -T

# Test suite 13-real: Test for proper handling of floating-point types.
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


package Local::Real;

use Readonly;
use Config::Apple::Profile::Payload::Common;
use Config::Apple::Profile::Payload::Types qw($ProfileReal $ProfileArray);

use base qw(Config::Apple::Profile::Payload::Common);

Readonly our %payloadKeys => (
    'realField' => {
        type => $ProfileReal,
        description => 'A field containing a real number.',
    },
    'realArrayField' => {
        type => $ProfileArray,
        subtype => $ProfileReal,
        description => 'An array of real numbers.',
    },
);


package main;

use Config;
use File::Temp;
use Readonly;
use Test::Exception;
use Test::More;


# @numbers is a list of numbers to be used for testing
Readonly my @numbers => (
    # All integers should be OK
    # Let's start with some simple numbers:
    0,
    10,
    1561584,
    
    # Next, add some negative numbers:
    -1,
    -145688405,
    -12,
    
    # The + symbol is OK, so let's put in some strings
    '+1',
    '+15',
    '+1500351783',
    
    # Now, let's do some floating-point numbers
    0.2315051532887,
    151244.221057,
    -545.778901565413,
    
    # Now, let's do some exponents
    1.0e1,
    5.3230884e5,
    2.2158105E8,
    -2.355610e15,
    -3.51017e-3,
    1.56615013510784e10,
);

# @baddies is a list of things that are not numbers, and should fail
Readonly my @baddies => (
    # Yes, undef is an entry here:
    undef,
    
    # Various strings
    '',
    'Hello',
    'Booga blargh!',
    
    # Try refs and objects:
    [qw(1 2 3)],
    {qw(1 hello 2 goodbye)},
    new File::Temp,
);

# We'll do 3 tests for each number:
#  * Write the number into the field without errors.
#  * Read the number from the field without errors.
#  * Have the read number equal what was written.
plan tests => 7*scalar(@numbers) + 2*scalar(@baddies);

# Test all of the numbers that should be good.
foreach my $number (@numbers) {
    
    # Make sure the object works properly
    my $object = new Local::Real;
    my $payload = $object->payload;
    lives_ok {$payload->{realField} = $number} "Write number $number";
    my $read_number = $payload->{realField};
    ok(defined($read_number), 'Read number back');
    cmp_ok($read_number, '==', $number, 'Compare numbers');
    lives_ok { push @{$payload->{realArrayField}}, $number; }
             'Push number onto array';
    
    # Make sure we get a correct plist out
    my $plist;
    lives_ok {$plist = $object->plist} 'Convert to plist';
    cmp_ok($plist->value->{realField}->value, '==', $number, 'plist number matches');
    cmp_ok($plist->value->{realArrayField}->value->[-1]->value,
           '==', $payload->{realField}, 'test number at the end of array'
    );
}

# Make sure all of the not-numbers fail
foreach my $not_number (@baddies) {
    my $object = new Local::Real;
    my $payload = $object->payload;
    dies_ok { $payload->{realField} = $not_number; } 'A non-number';
    dies_ok { push @{$payload->{realArrayField}}, $not_number; }
            '... pushing also fails';
}

# Done!
done_testing();