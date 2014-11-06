#!perl -T

# Test suite 17-uuid: Test for proper handling of UUIDs.
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


package Local::UUID;

use File::Temp;
use Readonly;
use Config::Apple::Profile::Payload::Common;
use Config::Apple::Profile::Payload::Types qw($ProfileArray $ProfileUUID);

use base qw(Config::Apple::Profile::Payload::Common);

Readonly our %payloadKeys => (
    'uniqueField' => {
        type => $ProfileUUID,
        description => 'A field containing a number.',
    },
    'arrayField' => {
        type => $ProfileArray,
        subtype => $ProfileUUID,
        description => 'An array of UUIDs',
    }
);


package main;

use Config;
use Data::GUID;
use Readonly;
use Test::Exception;
use Test::More;


# @tests has the set of test GUIDs.  Each GUID is listed in two forms:
# * As a regular GUID string
# * As a hex string
# The 50 GUIDs below were generated by the `uuidgen` program on Mac OS X 10.8.5.
Readonly my @tests => (
    [qw(6A93E3E9-85DA-4A73-B064-8DFF3EA243CC
        0x6A93E3E985DA4A73B0648DFF3EA243CC 
    )],
    [qw(A2B3B6A7-5DCF-4B3C-97F8-4CC27491A829
        0xA2B3B6A75DCF4B3C97F84CC27491A829 
    )],
    [qw(28138BE1-D8AA-4772-9A36-6B668FBF4146
        0x28138BE1D8AA47729A366B668FBF4146 
    )],
    [qw(4F46C108-CDE1-4338-A80E-EC134BFEF215
        0x4F46C108CDE14338A80EEC134BFEF215 
    )],
    [qw(7EC197CB-99DF-45B0-AA44-14ACEC08F1F5
        0x7EC197CB99DF45B0AA4414ACEC08F1F5 
    )],
    [qw(C3E48023-AB1A-4DBD-ACD6-AEC66B5A1966
        0xC3E48023AB1A4DBDACD6AEC66B5A1966 
    )],
    [qw(E1C26A6A-65AF-4BFF-A543-E31C74BB0198
        0xE1C26A6A65AF4BFFA543E31C74BB0198 
    )],
    [qw(3C5CDA84-8DA2-413F-9DF8-011397FE1A8C
        0x3C5CDA848DA2413F9DF8011397FE1A8C 
    )],
    [qw(D4A9414A-B8F0-469B-A280-DC544C53D635
        0xD4A9414AB8F0469BA280DC544C53D635 
    )],
    [qw(5121361D-B87E-4D5C-A757-E4A9A4E67633
        0x5121361DB87E4D5CA757E4A9A4E67633 
    )],
    [qw(D41DD955-427D-4EE5-8AEA-09C48175C1B9
        0xD41DD955427D4EE58AEA09C48175C1B9 
    )],
    [qw(7C7ABF90-EF73-4553-AB61-F97A5CE80A71
        0x7C7ABF90EF734553AB61F97A5CE80A71 
    )],
    [qw(7C8ED89B-ED40-4C31-BB65-809D235147EA
        0x7C8ED89BED404C31BB65809D235147EA 
    )],
    [qw(84B93B0F-ACBE-45BD-ADC1-4C12C4FBAE35
        0x84B93B0FACBE45BDADC14C12C4FBAE35 
    )],
    [qw(2DB0B929-6B64-4F66-B5CC-5468DA8F9A8E
        0x2DB0B9296B644F66B5CC5468DA8F9A8E 
    )],
    [qw(B566FF45-A67C-4A38-974A-CDEEAB05949F
        0xB566FF45A67C4A38974ACDEEAB05949F 
    )],
    [qw(F5B9D007-E460-4990-9BFE-5F5A2F6BBA14
        0xF5B9D007E46049909BFE5F5A2F6BBA14 
    )],
    [qw(9B5215D5-0B6D-40CA-812B-5254443F1D42
        0x9B5215D50B6D40CA812B5254443F1D42 
    )],
    [qw(B992639B-7E73-4B55-BFCF-BCF3848D2562
        0xB992639B7E734B55BFCFBCF3848D2562 
    )],
    [qw(772B5BC5-6A36-40E5-A2DC-917D286F61E0
        0x772B5BC56A3640E5A2DC917D286F61E0 
    )],
    [qw(E82C5090-FFE3-43A8-8627-13ED7F19D695
        0xE82C5090FFE343A8862713ED7F19D695 
    )],
    [qw(0E863150-FE2C-4EF8-8BB7-71C28BA5D4C5
        0x0E863150FE2C4EF88BB771C28BA5D4C5 
    )],
    [qw(2FE137E9-EE95-4D20-BF5D-171BB4FA2AD5
        0x2FE137E9EE954D20BF5D171BB4FA2AD5 
    )],
    [qw(7CFD23AF-C27B-497D-AF47-AC110B92622F
        0x7CFD23AFC27B497DAF47AC110B92622F 
    )],
    [qw(57FEB5B3-1411-44F2-B5FC-67162758DB88
        0x57FEB5B3141144F2B5FC67162758DB88 
    )],
    [qw(490D7BBC-94FF-449C-A16D-392E93058086
        0x490D7BBC94FF449CA16D392E93058086 
    )],
    [qw(83866343-A184-4630-978D-116CC2053488
        0x83866343A1844630978D116CC2053488 
    )],
    [qw(7DFF5833-7590-4970-8030-8D510267C669
        0x7DFF58337590497080308D510267C669 
    )],
    [qw(04253CA0-ABA1-4790-8180-D5472579DF04
        0x04253CA0ABA147908180D5472579DF04 
    )],
    [qw(39A89775-7C1D-4C20-B232-A85ECDFC4A17
        0x39A897757C1D4C20B232A85ECDFC4A17 
    )],
    [qw(A621A4C4-B680-48A8-A80F-6F6351307D86
        0xA621A4C4B68048A8A80F6F6351307D86 
    )],
    [qw(DB600BD8-43B5-42F6-887A-3B714A039A22
        0xDB600BD843B542F6887A3B714A039A22 
    )],
    [qw(BA075FD0-B049-491D-B28F-A306672113DE
        0xBA075FD0B049491DB28FA306672113DE 
    )],
    [qw(C89EA724-726F-45A1-95A9-F5013F9E02D5
        0xC89EA724726F45A195A9F5013F9E02D5 
    )],
    [qw(12B00B34-05CD-4719-B156-8367FBDC09A2
        0x12B00B3405CD4719B1568367FBDC09A2 
    )],
    [qw(1685A977-4EFC-4AA0-A506-A2521717EE62
        0x1685A9774EFC4AA0A506A2521717EE62 
    )],
    [qw(FA150B6D-115F-474B-9398-3BCB9C8E101F
        0xFA150B6D115F474B93983BCB9C8E101F 
    )],
    [qw(A67B8B3E-4F44-4DD4-931C-252DD9B24C7C
        0xA67B8B3E4F444DD4931C252DD9B24C7C 
    )],
    [qw(52ECDF01-738D-46DE-AA7E-D81F4AAD7E4F
        0x52ECDF01738D46DEAA7ED81F4AAD7E4F 
    )],
    [qw(2511766D-18D5-43F2-843D-64BD1BAF215D
        0x2511766D18D543F2843D64BD1BAF215D 
    )],
    [qw(4FA6ADED-5402-4CF5-AF47-21863728888E
        0x4FA6ADED54024CF5AF4721863728888E 
    )],
    [qw(26316F2F-D5A1-44E4-9EC0-BE682121352D
        0x26316F2FD5A144E49EC0BE682121352D 
    )],
    [qw(A3A6FA98-CA6B-46FD-8BAD-852F95C984BE
        0xA3A6FA98CA6B46FD8BAD852F95C984BE 
    )],
    [qw(CC6949B0-20B5-4A9C-B2FD-3CC3C4A79DE7
        0xCC6949B020B54A9CB2FD3CC3C4A79DE7 
    )],
    [qw(0DB06915-BEBE-4918-9C95-0EAC20FB2AAC
        0x0DB06915BEBE49189C950EAC20FB2AAC 
    )],
    [qw(59C84FD1-2DD8-45F8-9E71-301A8506E9EF
        0x59C84FD12DD845F89E71301A8506E9EF 
    )],
    [qw(1E7D225A-1129-4821-847E-0893D895E24B
        0x1E7D225A11294821847E0893D895E24B 
    )],
    [qw(2A62A35E-BE24-4426-882D-9CC1CBAEC0CF
        0x2A62A35EBE244426882D9CC1CBAEC0CF 
    )],
    [qw(BE4D4BC0-8BF5-444E-9CD4-142425668136
        0xBE4D4BC08BF5444E9CD4142425668136 
    )],
    [qw(0553443E-D355-47B1-800D-E741204B4CEF
        0x0553443ED35547B1800DE741204B4CEF 
    )],
);


# Here are some things that are definitely not UUIDs (or even GUIDs!)
Readonly my @baddies => (
    # Undef is wrong
    undef,
    
    # Numbers are wrong
    1,
    -1,
    3.14159265,
    
    # Almost all strings are wrong
    '',
    'Karl is awesome!',
    
    # Almost all objects are wrong!
    new File::Temp,
);


# For each GUID, 
#  * Make 2 Data::GUID objects, one from each string (normal and hex)
#  * Compare the two objects for equality.
#  * Make a copy, and hand the copy off to the payload
#  * Read the payload back, and make sure nothing was changed.
#  * Push or unshift the payload onto the array.
#  * Check the array length
#  * Write in a string to the payload; make sure it reads & compares OK.
#  * Write in hex to the payload; make sure it reads & compares OK.
plan tests => (1+3+3+3+3+1+2)*scalar(@tests) + 1 + (3+6)*scalar(@tests) + 3*scalar(@baddies);

# Make an object that we'll use for array testing
my $uuid_array_object = new Local::UUID;
my $uuid_array = $uuid_array_object->payload->{arrayField};
my @reference_array = ();

# Test all of the numbers that should be good.
my $i = 1;
foreach my $guid_group (@tests) {
    Readonly my $guid_as_string => $guid_group->[0];
    Readonly my $guid_as_hex => $guid_group->[1];
    
    # Make sure we're reading GUIDs properly
    # (Keep $guid1 and $guid2 for array test)
    my $guid1 = Data::GUID->from_string($guid_as_string);
    my $guid2 = Data::GUID->from_hex($guid_as_hex);
    cmp_ok($guid1, '==', $guid2,
           'Comparing ' . $guid_as_string . ' and ' . $guid_as_hex);
#    undef $guid1;
#    undef $guid2;
    
    # Keep a GUID copy for reference
    my $guid_reference = Data::GUID->from_string($guid_as_string);
    
    # See if our payload can accept the Data::GUID object
    # (Keep $guid1a for array test)
    my $guid1a = Data::GUID->from_string($guid_as_string);
    my $object = new Local::UUID;
    my $payload = $object->payload;
    lives_ok {$payload->{uniqueField} = $guid1a} 'Write object';
    my $read_guid = $payload->{uniqueField};
    ok(defined($read_guid), 'Read object back');
    cmp_ok($read_guid, '==', $guid_reference, 'Compare objects');
#    undef $guid1a;
    undef $object;
    undef $payload;
    undef $read_guid;
    
    # Now, let's try again, but with a string as the payload input
    $object = new Local::UUID;
    $payload = $object->payload;
    lives_ok {$payload->{uniqueField} = $guid_as_string} 'Write string';
    $read_guid = $payload->{uniqueField};
    ok(defined($read_guid), 'Read was-string-now-object back');
    cmp_ok($read_guid, '==', $guid_reference, 'Compare string');
    undef $object;
    undef $payload;
    undef $read_guid;
    
    # And now, once again, but with the hex value as the payload input
    # (This is our last payload class test, so keep $object and $payload
    # around for plist testing)
    $object = new Local::UUID;
    $payload = $object->payload;
    lives_ok {$payload->{uniqueField} = $guid_as_hex} 'Write hex';
    $read_guid = $payload->{uniqueField};
    ok(defined($read_guid), 'Read was-hex-now-object back');
    cmp_ok($read_guid, '==', $guid_reference, 'Compare hex');
#    undef $object;
#    undef $payload;
    undef $read_guid;
    
    # TODO: Create Data::UUID object and use that for testing
    
    # TODO: Create base64-encoded version and use that for testing
    
    # Put all forms (object, string, hex) of the UUID onto the array.
    # If even, push; if odd, unshift
    # The reference array does not convert, so only add objects there
    my $orig_array_len = scalar @$uuid_array;
    if ($i % 2 == 0) {
        lives_ok {push @$uuid_array, $guid1a} 'Pushing object onto array';
        push @reference_array, $guid1a;
        lives_ok {push @$uuid_array, $guid_as_string} 'Pushing string onto array';
        push @reference_array, $guid1;
        lives_ok {push @$uuid_array, $guid_as_hex} 'Pushing hex onto array';
        push @reference_array, $guid2;
    }
    else {
        lives_ok {unshift @$uuid_array, $guid1a} 'Pushing object onto array';
        unshift @reference_array, $guid1a;
        lives_ok {unshift @$uuid_array, $guid_as_string} 'Pushing string onto array';
        unshift @reference_array, $guid1;
        lives_ok {unshift @$uuid_array, $guid_as_hex} 'Pushing hex onto array';
        unshift @reference_array, $guid2;
    }
    
    # Make sure the array count is updated
    cmp_ok(scalar @$uuid_array, '==', $orig_array_len + 3,
           "Confirm array's new size"
    );
    
    # Make sure we get a correct plist out
    # (We'll check the array at the end)
    my $plist;
    lives_ok {$plist = $object->plist} 'Convert to plist';
    cmp_ok($plist->value->{uniqueField}->value, 'eq',
           $payload->{uniqueField}->as_string, 'plist uuid matches'
    );
    
    $i++;
}


# Compare our regular array to our array of objects
cmp_ok(scalar @$uuid_array, '==', scalar @reference_array, 
       'Confirm expected array size'
);

# Go through each array item, and compare
# (FYI: `my $i` is OK here because we're making a new lexical layer!)
for (my $i = 0; $i < scalar @reference_array; $i++) {
    my $string = $uuid_array->[$i];
    $string = "$string";
    
    my $reference_string = $reference_array[$i];
    $reference_string = "$reference_string";
    
    cmp_ok($string, 'eq', $reference_string,
           "Confirm array index $i matches"
    );
}

# Alternate pop and shift, make sure the array drains
$i = 0;
while (scalar @reference_array > 0) {
    my ($string, $reference_string);
    
    if ($i % 2 == 0) {
        lives_ok {$string = shift @$uuid_array} 'Shift string from array';
        $reference_string = shift @reference_array;
    }
    else {
        lives_ok {$string = pop @$uuid_array} 'Pop string from array';
        $reference_string = pop @reference_array;
    }
    
    $string = "$string";
    $reference_string = "$reference_string";
    
    cmp_ok($string, 'eq', $reference_string, 'Compare');
    
    $i++;
}


# Make sure each of the baddies fails to process
$i = 1;
foreach my $baddie (@baddies) {
    my $object = new Local::UUID;
    my $payload = $object->payload;
    
    # Make sure every method of reading fails
    throws_ok {$payload->{uniqueField} = $baddie}
              'Config::Apple::Profile::Exception::Validation',
              "Non-UUID $i";
    throws_ok {push @{$payload->{arrayField}}, $baddie}
            'Config::Apple::Profile::Exception::Validation',
            'Pushing onto array';
    throws_ok {unshift @{$payload->{arrayField}}, $baddie}
            'Config::Apple::Profile::Exception::Validation',
            'Unshifting onto array';
    
    $i++;
}


# Done!
done_testing();