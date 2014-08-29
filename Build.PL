use 5.14.4;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'XML::AppleConfigProfile',
    license             => 'perl',
    dist_author         => q{A. Karl Kornel <karl@kornel.us>},
    dist_version_from   => 'lib/XML/AppleConfigProfile.pm',
    release_status      => 'alpha',
    sign                => 1,
    configure_requires => {
        'Module::Build'          => 0,
    },
    build_requires => {
        'Test::More'             => 0,
        'Module::Signature'      => 0,
    },
    requires => {
        'Data::GUID'             => 0,
        'Exporter::Easy'         => 0,
        'Mac::PropertyList'      => 1.40,
#        'Moo'                    => 0,
#        'Moo::Role'              => 0,
#        'MooX::Types::MooseLike' => 0,
#        'namespace::autoclean'   => 0,
        'Readonly'               => 0,
        'Regexp::Common'         => 0,
    },
    add_to_cleanup     => [ 'XML-AppleConfigProfile-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
