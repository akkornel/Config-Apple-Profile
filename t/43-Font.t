#!perl -T

# Test suite 43-Font: Tests against the Font payload type.
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


use Config::Apple::Profile::Payload::Font;
use Config::Apple::Profile::Payload::Types qw(:all);
use Cwd qw(abs_path);
use File::Spec;
use Readonly;
use Test::Exception;
use Test::More;



# This is the list of keys we expect to have in this payload
my @keys_expected = (
    [Name => $ProfileString],
    [Font => $ProfileData],
);

# This is the list of font files to test with
my @font_files = (qw(
    Acknowledgement.otf
    Acknowledgement.ttf
));

# This is a list of non-font files to test with
my @bad_files = (qw(
    cert.pem
    key.key
));


# First, make sure payload->keys returns all expected Font payload keys.
# Next, make sure we can load fonts into the Font payload key.
# Finally, make sure non-Fonts can not be loaded.

plan tests =>   2*scalar(@keys_expected) + 2
              + 2*scalar(@font_files)
              + 2*scalar(@bad_files)
;


# Work out the location of the files we'll be using for our tests
my ($volume, $test_path, $test_file) = File::Spec->splitpath(abs_path(__FILE__));
$test_path = File::Spec->catdir(($test_path, 'files'));
diag   "Running tests with files in "
     . File::Spec->catpath($volume, $test_path, '');


# Create our object
my $object = new Config::Apple::Profile::Payload::Font;
my $keys = $object->keys;
my $payload = $object->payload;


# Check for our payload keys
foreach my $key (@keys_expected) {
    my ($expected_name, $expected_type) = @$key;
    
    # Make sure the key exists
    ok(exists $keys->{$expected_name}, "Check key $expected_name exists");
    cmp_ok($keys->{$expected_name}->{type}, '==',
           $expected_type, "Check key type matches"
    );
}

# Make sure PayloadType and PayloadVersion are set correctly
cmp_ok($keys->{PayloadType}->{value}, 'eq', 'com.apple.font',
       'Check PayloadType has correct value'
);
cmp_ok($keys->{PayloadVersion}->{value}, '==', 1,
       'Check PayloadVersion has correct value'
);


# Try loading valid font files
foreach my $font_file (@font_files) {
    my $handle;
    my $font_path = File::Spec->catpath($volume, $test_path, $font_file);
    lives_ok { open $handle, '<', $font_path; } "Open font file $font_file";
    lives_ok { $payload->{Font} = $handle; } "Give font file to payload";
    delete $payload->{Font};
    close $handle;
}


# Try loading invalid font files
SKIP: {
skip 'No support for checking OTF fonts' => 2*scalar(@bad_files);

foreach my $bad_file (@bad_files) {
    my $handle;
    my $bad_path = File::Spec->catpath($volume, $test_path, $bad_file);
    lives_ok { open $handle, '<', $bad_path; } "Open bad file $bad_file";
    dies_ok { $payload->{Font} = $handle; } "Give bad file to payload";
    delete $payload->{Font};
    close $handle;
}
};


# Done!
done_testing();