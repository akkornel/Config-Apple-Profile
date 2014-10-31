#!perl -T

# Test suite 09-pod-coverage: Test for POD coverage in code.
# 
# Copyright © 2014 A. Karl Kornel.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of either: the GNU General Public License as published
# by the Free Software Foundation; or the Artistic License.
# 
# See http://dev.perl.org/licenses/ for more information.

# This code originally created by Module::Starter, with modifications by Karl.

use 5.10.1;
use strict;
use warnings FATAL => 'all';
use Test::More;

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;


# Test all modules except for Config::Apple::Profile::Exception, which seems
# to confuse Pod::Coverage, due to all the symbols that Exception::Class makes.
my @modules = grep(!/Config::Apple::Profile::Exception/, all_modules());
plan tests => scalar(@modules);
foreach my $module (@modules) { pod_coverage_ok($module); }

done_testing();