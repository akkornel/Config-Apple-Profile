# This is the code to build Config::Apple::Profile::Config.
# For Copyright, please see the bottom of the file.

use 5.10.1;
use strict;
use warnings FATAL => 'all';

our $VERSION = '0.87.1';

use IPC::Open2;
use Module::Build;
use Readonly;
use Try::Tiny;
use version 0.77;


# This script is used to build the module Config::Apple::Profile::Config (CAPC).
# CAPC is used to store information on external executables that might not be
# used very much, and may be changed after installation.

# For example, when a Web Clip payload is being created, the client can provide
# a PNG image, which needs to be a certain size.  It would be nice if we could
# check this, but we don't want to make a dependency.  Instead, we check at
# install time for a module that can handle PNGs, and make a note of it for
# later.  


my $builder = Module::Build->current;

my $output_file = shift;
open my $output_handle, '>:encoding(UTF-8)', $output_file
    or die "Unable to open $output_file for writing: $!\n";


# Print the start of the module
print $output_handle <<ENDPRINTA;
package Config::Apple::Profile::Config;

use 5.10.1;
use strict;
use warnings FATAL => 'all';

ENDPRINTA

print $output_handle "our \$VERSION = '$VERSION';\n\n";

print $output_handle <<'ENDPRINTB';
use Exporter::Easy (
    OK => [qw(
        $ACP_OPENSSL_PATH $ACP_OPENSSL_CAN_CMS
    )],
    TAGS => [
        'all' => [qw(
          $ACP_OPENSSL_PATH $ACP_OPENSSL_CAN_CMS
        )],
        'openssl' => [qw($ACP_OPENSSL_PATH $ACP_OPENSSL_CAN_CMS)],
    ],
);


=encoding utf8

=head1 NAME

Config::Apple::Profile::Config - External programs and modules only used
occasionally (or even less).

=head1 SYNOPSIS

use Config::Apple::Profile::Config;

if (defined $Config::Apple::Profile::Config::ACP_OPENSSL_PATH) {
    # Do something with OpenSSL...
}

# ... or ...

use Config::Apple::Profile::Config qw($ACP_OPENSSL_PATH);

if (defined $ACP_OPENSSL_PATH) {
    # Do something with OpenSSL...
}

=head1 DESCRIPTION

From time to time, the C<Config::Apple::Profile::> classes would like to use an
executable or a module that is not absolutely required.  For example, if you
are creating a certificate payload, it would be nice to verify that you are
actually providing a certificate.

Although such functionality is nice to have, it is not required.  Also, there
may be more than one way to do certain things (for example, there may be more
than one way to examine a PNG file).  This package is created when the software
is installed, and the variables in this package are not read-only.  If you like,
your code can change the variables at runtime.

All of the package variables can be exported to the local namespace
individually, or in groups.  The C<:all> group can be used to import all
package variables, and additional packages are defined below.

=head1 PACKAGE VARIABLES

=head2 OpenSSL (group C<:openssl>)

=head3 C<$ACP_OPENSSL_PATH>

The path to the OpenSSL binary.  This may be undefined.

=head3 C<$ACP_OPENSSL_CAN_CMS>

If true, the OpenSSL executable at C<$ACP_OPENSSL_PATH> supports the `cms`
command.

=cut

ENDPRINTB


# Let's check for OpenSSL

if ($builder->args('skip-openssl') == 1) {
    print "Skipping OpenSSL\n";
    print $output_handle "our \$ACP_OPENSSL_PATH = undef;\n";
    print $output_handle "our \$ACP_OPENSSL_CAN_CMS = 0;\n";
    goto SKIPSSL;
}

print "Looking for OpenSSL\n";

# Start with a list of candidate paths
my @openssl_paths = (
    '/usr/bin/openssl',
    '/usr/sbin/openssl',
    '/usr/local/bin/openssl',
    '/usr/local/sbin/openssl',
);
if (defined $builder->args('with-openssl')) {
    unshift @openssl_paths, $builder->args('with-openssl');
}

# Keep a list of candidates
my @openssl_candidates;

foreach my $candidate (@openssl_paths) {
    print "\tLooking at path $candidate\n";
    
    # Check executable
    next unless (-x $candidate);

    # Run `openssl version` and look for a version number
    my ($openssl_in, $openssl_out, $openssl_pid);
    try {
        $openssl_pid = open2($openssl_out, $openssl_in, $candidate, 'version');
    };
    next unless defined($openssl_pid);
    close $openssl_in;

    # Look for an OpenSSL version in the first line
    my $openssl_version = <$openssl_out>;
    if ($openssl_version =~ m/^OpenSSL (\d+\.\d+\.\d+)([a-z-]*) /) {
        push @openssl_candidates, [
            $candidate,
            version->parse($1),
            $2 || '',
        ];
        print "\t\tFound version "  . version->parse($1) . ($2 || '') . "\n";
    }

    # Clean up the child
    waitpid($openssl_pid, 0);
    close $openssl_in;
}

# Sort the candidates to get the highest version
my @openssl_sorted = sort {
    my $version_cmp = $b->[1] cmp $a->[1];
    return $version_cmp unless ($version_cmp == 0);
    
    my $letter_cmp = $b->[2] cmp $a->[2];
    return $letter_cmp;
} @openssl_candidates;

# Grab the first entry as the one we'll use!
my $openssl_selected = shift @openssl_sorted;
print 'Using OpenSSL at ' . $openssl_selected->[0] . "\n";
print $output_handle "our \$ACP_OPENSSL_PATH = '" . $openssl_selected->[0] . "';\n";
print $output_handle   "our \$ACP_OPENSSL_CAN_CMS = "
                     . ($openssl_selected->[1] > 1 ? '1' : '0')
                     . ";\n";

# Clean up from the OpenSSL test
undef @openssl_sorted;
undef @openssl_candidates;

SKIPSSL:


# Output the end of the module
print $output_handle <<ENDPRINTZZZ;


=head1 ACKNOWLEDGEMENTS

Refer to the L<Config::Apple::Profile> for acknowledgements.

=head1 AUTHOR

A. Karl Kornel, C<< <karl at kornel.us> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2014 A. Karl Kornel.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
ENDPRINTZZZ
