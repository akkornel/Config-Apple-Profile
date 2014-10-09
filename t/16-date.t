#!perl -T

# Test suite 16-date: Test for proper handling of Date-related types.
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


package Local::Date;

use Readonly;
use Config::Apple::Profile::Payload::Common;
use Config::Apple::Profile::Payload::Types qw($ProfileDate);

use base qw(Config::Apple::Profile::Payload::Common);

Readonly our %payloadKeys => (
    'dateField' => {
        type => $ProfileDate,
        description => 'A field containing a number.',
    },
);


package main;

use DateTime;
use DateTime::Infinite;
use Readonly;
use Test::Exception;
use Test::More;


# @objects is a list of DateTime objects that are good
Readonly my $good_year => 1583 + int(rand(2000));
Readonly my $good_month => 1 + int(rand(12));
Readonly my $good_day => 1 + int(rand(28));
Readonly my $good_hour => int(rand(24));
Readonly my $good_minute => int(rand(60));
Readonly my $good_second => int(rand(60));
Readonly my $good_string =>   "$good_year-$good_month-$good_day "
                            . "$good_hour:$good_minute:$good_second UTC";
diag "Test dateTime: $good_string";

# @strings are strings that can be parsed
Readonly my @strings => (
    $good_string,
    
    # Date-time strings can be parsed
    '2011-08-02 15:00:34',
    '2011-08-02 15:00:34 GMT',
    
    # Dates without times can also be parsed
    '2014-10-08',
    'Thursday, September 18, 2014',
    
    # Some relative dates can also be parsed!
    'Tomorrow',
    'Yesterday',
    '2 days ago',
);

# @baddies is a list of strings or objects that will fail
Readonly my @baddies => (
    "Karl's birthday",
    'The first day of Spring in 2066',
    'Last year',
);


# First, make sure we can construct a date from pieces, and set as payload
# Next, send over several strings that should parse OK.
# Next, send over several strings that should NOT parse OK.
# Finally, make sure an infinite date/time fails.

plan tests =>   3                   # DateTime objects
              + scalar(@strings)    # Parseable strings
              + scalar(@baddies)    # Unparseable strings
              + 2                   # Infinite dates
;


# Create the objects we'll be working with
my $object = new Local::Date;
my $payload = $object->payload;


# Make a DateTime object from our good string
my $good_object = DateTime->new(
    year      => $good_year,
    month     => $good_month,
    day       => $good_day,
    hour      => $good_hour,
    minute    => $good_minute,
    second    => $good_second,
    time_zone => 'UTC',
);
ok(defined $good_object, 'Create good DateTime object');
lives_ok { $payload->{dateField} = $good_object; }
         'Give DateTime object to payload';
dies_ok { $payload->{dateField} = new Local::Date; }
        'Give non-DateTime object to payload';


# Test with our strings
foreach my $string (@strings) {
    lives_ok { $payload->{dateField} = $string; }
             "Give good string '$string' to payload";
}
foreach my $string (@baddies) {
    dies_ok { $payload->{dateField} = $string; }
            "Give bad string '$string' to payload";
}


# Make sure infinite dates fail
dies_ok { $payload->{dateField} = new DateTime::Infinite::Past; }
        'Give ∞ past date to payload';
dies_ok { $payload->{dateField} = new DateTime::Infinite::Future; }
        'Give ∞ future date to payload';


# Done!
done_testing();