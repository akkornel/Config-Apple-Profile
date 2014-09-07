#!perl -T

# Test suite 10-string: Test for proper handling of String and Identifier types.
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


package Local::StringID;

use Readonly;
use XML::AppleConfigProfile::Payload::Common;
use XML::AppleConfigProfile::Payload::Types qw($ProfileString $ProfileIdentifier);

use base qw(XML::AppleConfigProfile::Payload::Common);

Readonly our %payloadKeys => (
    'stringField' => {
        type => $ProfileString,
        description => 'A field containing a string.',
    },
    'IDField' => {
        type => $ProfileIdentifier,
        description => 'A field containing an identifier.',
    },
);


package main;

use Config;
use File::Temp;
use Readonly;
use Test::Exception;
use Test::More;


Readonly my @IDs => (
    'us.kornel.karl',
    'us.kornel',
    'us',
    'karl',
    'apple',
    'stuff',
    'ThisIsALongHostNameButItShouldBeOK.good',
);

# @baddies is a list of things that are not strings, and should fail
Readonly my @baddies => (
    # Yes, undef is an entry here:
    undef,
    
    # An empty string should fail
    '',
    
    # Refs and objects should also fail
    [qw(1 2 3)],
    {qw(1 hello 2 goodbye)},
    new File::Temp,
);

# @bad_IDs is a list of bad identifiers
Readonly my @bad_IDs => (
    # A multi-line string
    "Line1\nLine2",
    
    # A string with a space in it is bad
    'net.karl .hello1',
    
    # Starting with digits is bad, too.
    'net.1karl.forever',
);


# Because these types are so generic, they're difficult to test.
#  * NOTE:  I don't think we can test character encoding.  If the utf8 flag is
#    on for a string, great, but having the utf8 flag off might just mean we
#    have an ASCII string, so we can't really test that.
#  * We can make sure that all IDs are acceptable as strings.
#  * Make sure obvious non-strings/non-IDs fail.
#  * We can also test for strings that aren't IDs.
plan tests => 0 + 7*scalar(@IDs) + 2*scalar(@baddies) + 5*scalar(@bad_IDs);

# Test all of the numbers that should be good.
#foreach my $number (@numbers) {
#    my $object = new Local::Number;
#    my $payload = $object->payload;
#    lives_ok {$payload->{numberField} = $number} "Write number $number";
#    my $read_number = $payload->{numberField};
#    ok(defined($read_number), 'Read number back');
#    cmp_ok($read_number, '==', $number, 'Compare numbers');
#}

# Make sure all of the identifiers pass, as both strings and IDs
foreach my $ID (@IDs) {
    my $object = new Local::StringID;
    my $payload = $object->payload;
    lives_ok { $payload->{stringField} = $ID; } "String $ID";
    my $read_item = $payload->{stringField};
    cmp_ok($read_item, 'eq', $ID, 'Compare strings');
    lives_ok { $payload->{IDField} = $ID; } '... as an ID';
    $read_item = $payload->{IDField};
    cmp_ok($read_item, 'eq', $ID, 'Compare IDs');
    
    # Make sure we get a correct plist out
    my $plist;
    lives_ok {$plist = $object->plist} 'Convert to plist';
    cmp_ok($plist->value->{stringField}->value, 'eq',
           $payload->{stringField}, 'test string field'
    );
    cmp_ok($plist->value->{IDField}->value, 'eq',
           $payload->{IDField}, 'test ID field'
    );
}

# Make sure all of the not-strings not-identifiers fail
foreach my $not_string (@baddies) {
    my $object = new Local::StringID;
    my $payload = $object->payload;
    dies_ok { $payload->{stringField} = $not_string; } 'A non-string non-ID';
    dies_ok { $payload->{IDField} = $not_string; } 'A non-string non-ID';
}

# Make sure all of the not-identifiers fail
foreach my $not_ID (@bad_IDs) {
    my $object = new Local::StringID;
    my $payload = $object->payload;
    lives_ok { $payload->{stringField} = $not_ID; } 'A string non-ID';
    my $read_item = $payload->{stringField};
    cmp_ok($read_item, 'eq', $not_ID, '... works OK as a String');
    dies_ok { $payload->{IDField} = $not_ID; } '... but not as an ID';
    
    # Make sure we get a correct plist out
    my $plist;
    lives_ok {$plist = $object->plist} 'Convert to plist';
    cmp_ok($plist->value->{stringField}->value, 'eq',
           $payload->{stringField}, 'test string field'
    );
}

# Done!
done_testing();