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

use 5.14.4;
use strict;
use warnings FATAL => 'all';


package Local::Number;

use Readonly;
use XML::AppleConfigProfile::Payload::Common;
use XML::AppleConfigProfile::Payload::Types qw($ProfileNumber);

use base qw(XML::AppleConfigProfile::Payload::Common);

Readonly our %payloadKeys => (
    'numberField' => {
        type => $ProfileNumber,
        description => 'A field containing a number.',
    },
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
    
    # Also include each end of the range
    (defined $Config{d_quad}) ? 2**64 : 2**32,
    (defined $Config{d_quad}) ? (2**64)*-1 : (2**32)*-1,
    
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
);

# We'll do 3 tests for each number:
#  * Write the number into the field without errors.
#  * Read the number from the field without errors.
#  * Have the read number equal what was written.
plan tests => scalar(@baddies) + 3*scalar(@numbers);

# Test all of the numbers that should be good.
foreach my $number (@numbers) {
    my $object = new Local::Number;
    my $payload = $object->payload;
    lives_ok {$payload->{numberField} = $number} "Write number $number";
    my $read_number = $payload->{numberField};
    ok(defined($read_number), 'Read number back');
    cmp_ok($read_number, '==', $number, 'Compare numbers');
}

# Make sure all of the not-numbers fail
foreach my $not_number (@baddies) {
    my $object = new Local::Number;
    my $payload = $object->payload;
    dies_ok { $payload->{numberField} = $not_number; } 'A non-number';
}

# Done!
done_testing();