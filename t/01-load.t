#!perl -T
use 5.14.4;
use strict;
use warnings FATAL => 'all';
use Test::More;

# Test 

BEGIN {
    my @modules = qw(
        XML::AppleConfigProfile
        XML::AppleConfigProfile::Targets
        XML::AppleConfigProfile::Payload::Common
        XML::AppleConfigProfile::Payload::Tie::Array
        XML::AppleConfigProfile::Payload::Tie::Root
        XML::AppleConfigProfile::Payload::Types
        XML::AppleConfigProfile::Payload::Types::Serialize
        XML::AppleConfigProfile::Payload::Types::Validation
        XML::AppleConfigProfile::Payload::Certificate
        XML::AppleConfigProfile::Payload::Certificate::PEM
        XML::AppleConfigProfile::Payload::Certificate::PKCS1
        XML::AppleConfigProfile::Payload::Certificate::PKCS12
        XML::AppleConfigProfile::Payload::Certificate::Root
        XML::AppleConfigProfile::Payload::Email
    );

    plan tests => scalar(@modules);
    
    foreach my $module (@modules) {
        use_ok($module) || BAIL_OUT("Unable to use $module");
    }
}

done_testing();