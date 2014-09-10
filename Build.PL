use 5.14.4;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'XML::AppleConfigProfile',
    keywords            => [qw(iOS mobileconfig plist)],
    license             => 'perl',
    create_license      => 1,
    dist_author         => q{A. Karl Kornel <karl@kornel.us>},
    dist_version_from   => 'lib/XML/AppleConfigProfile.pm',
    release_status      => 'unstable',
    sign                => 1,
    configure_requires => {
        'Module::Build'          => 0,
    },
    build_requires => {
        'File::Temp'             => 0,
        'Test::Exception'        => 0,
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
        'Scalar::Util'           => 0,
        'Try::Tiny'              => 0,
    },
    add_to_cleanup     => [ 'XML-AppleConfigProfile-*' ],
    create_makefile_pl => 'traditional',
    meta_merge => {
        resources => {
            bugtracker => [
                'https://github.com/akkornel/XML-AppleConfigProfile/issues'
            ],
            repository => {
                url  => 'git://github.com/akkornel/XML-AppleConfigProfile.git',
                web  => 'https://github.com/akkornel/XML-AppleConfigProfile',
                type => 'git',
            },
            repository => 'https://github.com/akkornel/XML-AppleConfigProfile',
        },
    },
);

$builder->create_build_script();
