#!perl -T

# Test suite 71-Sign: Tests of profile signing.
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

use Config::Apple::Profile::Sign;
use Test::Exception;
use Test::More;


# We haven't created any tests yet, so there's nothing to do.

plan skip_all => 'No tests created yet';


# Create our objects

my $signer = new Config::Apple::Profile::Sign;


# Done!
done_testing();