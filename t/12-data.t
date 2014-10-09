#!perl -T

# Test suite 12-data: Tests against the Data payload type.
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


package Local::Data;

use Readonly;
use Config::Apple::Profile::Payload::Common;
use Config::Apple::Profile::Payload::Types qw($ProfileData);

use base qw(Config::Apple::Profile::Payload::Common);

Readonly our %payloadKeys => (
    'dataField' => {
        type => $ProfileData,
        description => 'A field containing data.',
    },
);


package main;

use Cwd qw(abs_path);
use Encode qw(decode encode);
use Fcntl qw(:seek);
use File::Spec;
use File::Temp qw(tempdir);
use IO::File;
use Readonly;
use Scalar::Util qw(openhandle);
use Test::Exception;
use Test::More;


# First, make sure we can read consistently from an on-disk file
#   * Read the file into memory ourselves
#   * Give the payload an open FH, and an open IO::File
#   * Get plain handles back from each payload
#   * Make sure data reads and compares OK
# Next, make sure that strings can be properly converted to filehandles
# Make sure that we fail on write-only and closed filehandles.
# Also, make sure that we fail on un-seekable filehandles.

# NOTE: We'll be `undef`-ing alot of things, in order to minimize memory use.

plan tests =>   (1 + 2 + 2 + 3 + 3)
              + 4
              + 7
              + 2
;


# Work out the location of the files we'll be using for our tests
my ($volume, $test_path, $test_file) = File::Spec->splitpath(abs_path(__FILE__));
Readonly my $key_file =>
    File::Spec->catpath($volume,
                        File::Spec->catdir(($test_path, 'files')),
                        'key.key'
);
diag "Running test with file $key_file";

# All of our testing will involve slurping files, so take care of that now.
local $/;


# First, read data into memory for comparison
my $reference_fh;
if (open $reference_fh, '<', $key_file) {
    pass('Open reference file');
}
else {
    fail('Open reference file');
    diag "OS error: $!";
}
binmode $reference_fh;
my $reference_data = <$reference_fh>;
diag 'Reference file size is ' . length($reference_data);
close $reference_fh;
undef $reference_fh;

# Reopen under a new handle for our data test
my $side1_object = new Local::Data;
my $side1_payload = $side1_object->payload;
my $side2_object = new Local::Data;
my $side2_payload = $side2_object->payload;

# Next, make an object using a plain filehandle
my $side1_fh;
if (open $side1_fh, '<', $key_file) {
    pass('Open file via open');
}
else {
    fail('Open file via open');
    diag "OS error: $!";
}
binmode $side1_fh;
lives_ok { $side1_payload->{dataField} = $side1_fh } 'Put basic FH into object';
undef $side1_fh;

# Next, make an object using a IO::File object
my $side2_IO;
if ($side2_IO = IO::File->new($key_file, '<')) {
    pass('Open file via IO::File');
}
else {
    fail('Open file via IO::File');
    diag "OS error: $!";
}
$side2_IO->binmode;
lives_ok { $side2_payload->{dataField} = $side2_IO } 'Put IO::File into object';
undef $side2_IO;

# Now we have $reference_data, $side1_payload, and $side2_payload

# Read in our data from the FH method, and compare
my $side1_handle = $side1_payload->{dataField};
my $side1_data = '';
my $side1_read = 0;
ok(openhandle $side1_handle, 'FH object is still open');
while (my $chars_read = read($side1_handle, my $data_read, 4096)) {
    $side1_read += $chars_read;
    $side1_data .= $data_read;
}
cmp_ok($side1_read, '==', length($reference_data),
       'FH method read correct # bytes'
);
ok($side1_data eq $reference_data, 'FH method read correct data');
undef $side1_data;
undef $side1_handle;

# Read in our data from the IO::File method, and compare
my $side2_handle = $side2_payload->{dataField};
my $side2_data = '';
my $side2_read = 0;
ok(openhandle $side2_handle, 'IO::File object is still open');
while (my $chars_read = read($side2_handle, my $data_read, 4096)) {
    $side2_read += $chars_read;
    $side2_data .= $data_read;
}
cmp_ok($side2_read, '==', length($reference_data),
       'IO::File method read correct # bytes'
);
cmp_ok($side2_data, 'eq', $reference_data, 'IO::File method read correct data');
undef $side2_data;
undef $side2_handle;

# Clean up from this phase of testing
undef $side1_payload;
undef $side2_payload;
undef $side1_object;
undef $side2_object;


# Next, let's make sure strings can be put into the payloads OK
# Be sure to use a Unicode string
my $string =   "Kohlens\N{U+00E4}ure ohne die "
             . "Rindfleischetikettierungs\N{U+00FC}berwachungsaufgabenu\N{U+0308}bertragungsgesetz!";
my $encoded_string = encode('UTF-8', $string, Encode::LEAVE_SRC);
my $string_object = new Local::Data;
my $string_payload = $string_object->payload;

# Make sure the string goes in OK
dies_ok { $string_payload->{dataField} = $string; } 'Put utf8 data into payload';
lives_ok { $string_payload->{dataField} = $encoded_string; }
         'Put encoded data into payload';

# Make sure the string comes out OK
my $encoded_handle = $string_payload->{dataField};
seek $encoded_handle, 0, SEEK_SET;
my $encoded_candidate = <$encoded_handle>;
cmp_ok(length($encoded_candidate), '==', length($encoded_string),
       'Check string length'
);
cmp_ok($encoded_candidate, 'eq', $encoded_string, 'Check string contents');

# Clean up from this phase of testing
undef $encoded_handle;
undef $string_payload;
undef $string_object;


# Next, try out a write-only filehandle, and a closed filehandle
# If our platform supports umask, lock things down to just us
my $orig_umask = umask;
if (defined $orig_umask) {
    umask 0077;
}

# Make a temporary directory for us to write stuff in
Readonly my $tempdir => tempdir('data_testXXXX', TMPDIR => 1);
Readonly my $filename => File::Spec->catfile(($tempdir), 'write_only.t');
Readonly my $closed_file => File::Spec->catfile(($tempdir), 'closed.t');
diag "Write-only file is at $filename\n";
diag "Closed file is at $closed_file\n";

# Open and close our "closed" file
my $closed_handle;
if (open $closed_handle, '>', $closed_file) {
    pass('Open temporary file')
}
else {
    diag "OS error: $!";
    fail('Open temporary file');
}

# Write something into it, and close
print $closed_handle "Karl is awesome?\n";
close $closed_handle;

# Give the closed handle to the object
my $closed_object = new Local::Data;
my $closed_payload = $closed_object->payload;
dies_ok { $closed_payload->{dataField} = $closed_handle; }
        'Put a closed filehandle into payload';

# Open our file for writing
my $write_handle;
if (open $write_handle, '>', $filename) {
    pass('Open temporary file')
}
else {
    diag "OS error: $!";
    fail('Open temporary file');
}

# Write somethign into it
print $write_handle "Karl is awesome!\n";

# See if we can give it to an object
my $write_only_object = new Local::Data;
my $write_only_payload = $write_only_object->payload;
dies_ok { $write_only_payload->{dataField} = $write_handle; }
        'Put a write-only object into payload';
undef $write_only_payload;
undef $write_only_object;

# Clean up our directory, files, and umask
close $write_handle;
if (unlink $closed_file) {
    pass('Delete temporary file');
}
else {
    diag "OS error: $!";
    fail('Delete temporary file');
}
if (unlink $filename) {
    pass('Delete temporary file');
}
else {
    diag "OS error: $!";
    fail('Delete temporary file');
}
if (rmdir $tempdir) {
    pass('Delete temporary directory');
}
else {
    diag "OS error: $!";
    fail('Delete temporary directory');
}
umask $orig_umask if defined $orig_umask;


# Finally, try out a filehandle that can not seek
my ($pipe_read, $pipe_write);
pipe $pipe_read, $pipe_write;
ok(!seek($pipe_write, 2, SEEK_CUR), "Make sure we can't seek");

my $seek_object = new Local::Data;
my $seek_payload = $seek_object->payload;
dies_ok { $seek_payload->{dataField} = $pipe_write; }
         'Set the pipe as the payload';
         
# Clean up from this phase
undef $seek_payload;
undef $seek_object;
close $pipe_write;
close $pipe_read;


# Done!
done_testing();