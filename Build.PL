#!perl -w

# Build.PL: Build script leveraging Module::Build.
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

use Module::Build;

my $builder = Module::Build->new(
    # Basic release information
    module_name         => 'Config::Apple::Profile',
    dist_author         => q{A. Karl Kornel <karl@kornel.us>},
    keywords            => [qw(iOS mobileconfig plist)],
    dist_version_from   => 'lib/Config/Apple/Profile.pm',
    release_status      => 'testing',
    
    # Software license
    license             => 'perl',
    create_license      => 0,
        
    # Our prerequisites
    dynamic_config     => 0,
    configure_requires => {
        'Module::Build'          => '0.4210',
    },
    build_requires => {
        'DateTime::Infinite'     => 0,
        'Test::Exception'        => 0,
        'Test::More'             => 0,
        'Module::Signature'      => 0,
    },
    requires => {
        'Data::GUID'             => 0,
        'DateTime'               => 0,
        'DateTime::Format::Flexible' => 0,
        'Email::Valid'           => 0,
        'Exporter::Easy'         => 0,
        'File::Temp'             => 0,
        'IO::Dir'                => 0,
        'IO::File'               => 0,
        'Mac::PropertyList'      => 1.40,
        'Readonly'               => 0,
        'Regexp::Common'         => 0,
        'Scalar::Util'           => 0,
        'Try::Tiny'              => 0,
    },
    
    # Project-related resources on the web
    meta_merge => {
        resources => {
#            bugtracker => [
#                'https://github.com/akkornel/Config-Apple-Profile/issues'
#            ],
            bugtracker => 'https://github.com/akkornel/Config-Apple-Profile/issues',
#            repository => {
#                url  => 'git://github.com/akkornel/Config-Apple-Profile.git',
#                web  => 'https://github.com/akkornel/Config-Apple-Profile',
#                type => 'git',
#            },
            repository => 'https://github.com/akkornel/Config-Apple-Profile',
        },
    },
    
    # Misc. stuff
    add_to_cleanup     => [ 'Config-Apple-Profile-*' ],
    create_makefile_pl => 'traditional',
    sign                => 1,
    
    # Additional executables and modules
    get_options => {
        'skip-openssl' => {
            default => 0,
        },
        'with-openssl' => {
            type => '=s',
        },
    },
    
    # 
    PL_files => {
        'lib/Config/Apple/Profile/Config.pl'
        => 'lib/Config/Apple/Profile/Config.pm',
    }
);

# Let Mobule::Build take things from here!
$builder->create_build_script();
