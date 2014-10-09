#!perl -T

# Test suite 11-number: Test for proper handling of Number-related types.
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


package Local::Number;

use Readonly;
use Config::Apple::Profile::Payload::Common;
use Config::Apple::Profile::Payload::Types qw($ProfileNumber $ProfileArray
                                              $ProfileDict);

use base qw(Config::Apple::Profile::Payload::Common);

Readonly our %payloadKeys => (
    'numberField' => {
        type => $ProfileNumber,
        description => 'A field containing a number.',
    },
    'numberArrayField' => {
        type => $ProfileArray,
        subtype => $ProfileNumber,
        description => 'An array of numbers.',
    },
    'numberDictField' => {
        type => $ProfileDict,
        subtype => $ProfileNumber,
        description => 'A dictionary of numbers.',
    }
);


package main;

use Config;
use File::Temp;
use Readonly;
use Test::Exception;
use Test::More;

diag('This Perl uses ', (defined $Config{d_quad}) ? 64 : 32,
     '-bit numbers.',
);

# @numbers is a list of numbers to be used for testing
Readonly my @numbers => (
    # Let's start with some simple numbers:
    0,
    10,
    1561584,
    
    # Next, add some negative numbers:
    -1,
    -145688405,
    -12,
    
    # Also include each end of the native integer range
    # 32-bit number range is -2**31 to (2**32)-1, and similar for 64-bit
    (defined $Config{d_quad}) ? 18446744073709551615 : 4294967295,
    (defined $Config{d_quad}) ? -9223372036854775808 : -2147483648,
    
    # The + symbol is OK, so let's put in some strings
    '+1',
    '+15',
    '+1500351783',
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
    
    # How about a few real numbers?
    1.314159265,
    1.5663,
    0.2992,
);

# We'll do 3 tests for each number:
#  * Write the number into the field without errors.
#  * Read the number from the field without errors.
#  * Have the read number equal what was written.
plan tests => 10*scalar(@numbers) + 3*scalar(@baddies);

# Test all of the numbers that should be good.
my $i = 0;
foreach my $number (@numbers) {
    
    # Make sure the object works properly
    my $object = new Local::Number;
    my $payload = $object->payload;
    lives_ok {$payload->{numberField} = $number} "Write number $number (#$i)";
    my $read_number = $payload->{numberField};
    ok(defined($read_number), 'Read number back');
    cmp_ok($read_number, '==', $number, 'Compare numbers');
    lives_ok { push @{$payload->{numberArrayField}}, $number; }
             'Push number onto array';
    lives_ok { $payload->{numberDictField}->{"test$i"} = $number; }
             'Insert number into dictionary';
    
    # Make sure we get a correct plist out
    my $plist;
    lives_ok {$plist = $object->plist} 'Convert to plist';
    cmp_ok($plist->value->{numberField}->value, '==', $number, 'plist number matches');
    cmp_ok($plist->value->{numberArrayField}->value->[-1]->value,
           'eq', $payload->{numberField}, 'test number at the end of array'
    );
    ok(exists $plist->value->{numberDictField}->value->{"test$i"},
       'Test number is in dictionary'
    );
    cmp_ok($plist->value->{numberDictField}->value->{"test$i"}->value,
           '==', $payload->{numberField}, 'Number in dictionary matches'
    );
    
    $i++;
}

# Make sure all of the not-numbers fail
$i = 0;
foreach my $not_number (@baddies) {
    my $object = new Local::Number;
    my $payload = $object->payload;
    dies_ok { $payload->{numberField} = $not_number; } "A non-number (#$i)";
    dies_ok { push @{$payload->{numberArrayField}}, $not_number; }
            '... pushing also fails';
    dies_ok { $payload->{numberDictField}->{"test$i"} = $not_number; }
            '... dict also fails';
    $i++;
}

# Done!
done_testing();