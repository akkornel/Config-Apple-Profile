#!perl -T

# Test suite 01-load: Test that modules actually load.
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
use Test::More;

# List all modules, and make sure they `use` OK.
BEGIN {
    my @modules = qw(
        Config::Apple::Profile
        Config::Apple::Profile::Config
        Config::Apple::Profile::Targets
        Config::Apple::Profile::Payload::Common
        Config::Apple::Profile::Payload::Tie::Array
        Config::Apple::Profile::Payload::Tie::Dict
        Config::Apple::Profile::Payload::Tie::Root
        Config::Apple::Profile::Payload::Types
        Config::Apple::Profile::Payload::Types::Serialize
        Config::Apple::Profile::Payload::Types::Validation
        Config::Apple::Profile::Payload::Certificate
        Config::Apple::Profile::Payload::Certificate::PEM
        Config::Apple::Profile::Payload::Certificate::PKCS1
        Config::Apple::Profile::Payload::Certificate::PKCS12
        Config::Apple::Profile::Payload::Certificate::Root
        Config::Apple::Profile::Payload::Email
        Config::Apple::Profile::Payload::Font
        Config::Apple::Profile::Payload::WiFi
        Config::Apple::Profile::Payload::WiFi::EAPClientConfiguration
    );

    plan tests => scalar(@modules);
    
    foreach my $module (@modules) {
        use_ok($module) || BAIL_OUT("Unable to use $module");
    }
}

done_testing();