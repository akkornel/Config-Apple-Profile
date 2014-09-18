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

use 5.10.1;
use strict;
use warnings FATAL => 'all';


package Local::StringID;

use Readonly;
use Config::Apple::Profile::Payload::Common;
use Config::Apple::Profile::Payload::Types qw($ProfileString $ProfileIdentifier
                                               $ProfileArray
);

use base qw(Config::Apple::Profile::Payload::Common);

Readonly our %payloadKeys => (
    'stringField' => {
        type => $ProfileString,
        description => 'A field containing a string.',
    },
    'stringArrayField' => {
        type => $ProfileArray,
        subtype => $ProfileString,
        description => 'An array of strings.',
    },
    'IDField' => {
        type => $ProfileIdentifier,
        description => 'A field containing an identifier.',
    },
    'IDArrayField' => {
        type => $ProfileArray,
        subtype => $ProfileIdentifier,
        description => 'An array of identifiers.',
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
# NOTE: UTF-8 warnings need to be disabled for perl 5.12 and lower 
# (See "Any unsigned value can be encoded as a character" at       )
# (http://perldoc.perl.org/5.14.0/perldelta.html#Core-Enhancements )
no warnings 'utf8';
Readonly my @baddies => (
    # Yes, undef is an entry here:
    undef,
    
    # An empty string should fail
    '',
    
    # Refs and objects should also fail
    [qw(1 2 3)],
    {qw(1 hello 2 goodbye)},
    new File::Temp,
    
    # Bad UTF-8 code points should fail
    "This string is \N{U+DC85} NOT valid UTF-8",
);
use warnings 'utf8';

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
#    The best we can do is include some strings which we know will not encode
#    properly as UTF-8.
#  * We can make sure that all IDs are acceptable as strings.
#  * Make sure obvious non-strings/non-IDs fail.
#  * We can also test for strings that aren't IDs.
#  * Pushing onto a list should be OK, and they should come out OK
#    (More detailed testing is in 17-uuid.t and 15-array.t)
plan tests => 11*scalar(@IDs) + 4*scalar(@baddies) + 5*scalar(@bad_IDs);


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
    
    # Push the identifier into the string and ID array
    lives_ok { push @{$payload->{stringArrayField}}, $ID; } 'Push string onto array';
    lives_ok { push @{$payload->{IDArrayField}}, $ID; } 'Push ID onto array';
    
    # Make sure we get a correct plist out
    my $plist;
    lives_ok {$plist = $object->plist} 'Convert to plist';
    cmp_ok($plist->value->{stringField}->value, 'eq',
           $payload->{stringField}, 'test string field'
    );
    cmp_ok($plist->value->{stringArrayField}->value->[-1]->value,
           'eq', $payload->{stringField}, 'test string at the end of array'
    );
    cmp_ok($plist->value->{IDField}->value, 'eq',
           $payload->{IDField}, 'test ID field'
    );
    cmp_ok($plist->value->{IDArrayField}->value->[-1]->value,
           'eq', $payload->{IDField}, 'test ID at the end of array'
    );
}

# Make sure all of the not-strings not-identifiers fail
my $i = 1;
foreach my $not_string (@baddies) {
    my $object = new Local::StringID;
    my $payload = $object->payload;
    dies_ok { $payload->{stringField} = $not_string; }
        "Testing non-string non-ID $i";
    dies_ok { $payload->{IDField} = $not_string; }
        '... and as an ID';
    dies_ok { push @{$payload->{stringArrayField}}, $not_string; }
        "... can't push to string array";
    dies_ok { push @{$payload->{IDArrayField}}, $not_string; }
        "... can't push to ID array";
    $i++;
}

# Make sure all of the not-identifiers fail
foreach my $not_ID (@bad_IDs) {
    my $object = new Local::StringID;
    my $payload = $object->payload;
    lives_ok { $payload->{stringField} = $not_ID; } "A string non-ID $not_ID";
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