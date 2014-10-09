# This is the code for Config::Apple::Profile::Payload::Font.
# For Copyright, please see the bottom of the file.

package Config::Apple::Profile::Payload::Font;

use 5.10.1;
use strict;
use warnings FATAL => 'all';
use base qw(Config::Apple::Profile::Payload::Common);

our $VERSION = '0.87';

use Email::Valid;
use Readonly;
use Regexp::Common;
use Config::Apple::Profile::Targets qw(:all);
use Config::Apple::Profile::Payload::Common;
use Config::Apple::Profile::Payload::Types qw(:all);


=encoding utf8

=head1 NAME

Config::Apple::Profile::Payload::Font - The Font payload type.

=head1 SYNOPSIS

    use Config::Apple::Profile;
    use Config::Apple::Profile::Payload::Font;
    use File::Spec;
    
    my $font_file_path = '/path/to/font.otf';
    
    my $font = new Config::Apple::Profile::Payload::Font;
    my $payload = $email->payload;
    
    open my $font_file, '<', $font_file_path
        or die "Unable to open font $font_file_path: $!";
    $payload->{Font} = $font_file;

    my $profile = new Config::Apple::Profile::Profile;
    push @{$profile->content}, $font;
    
    print $profile->export;


=head1 DESCRIPTION

This class implements the Font payload, which is used to install new fonts
on a device running iOS.  This profile is not used by Mac OS X.

B<NOTE:> No testing is performed of the Font data provided.  The author is not
aware of any Perl modules that can be used to test opening OpenType (.otf)
files, except for C<Font::FreeType>, which does not seem to be working.


=head1 PAYLOAD KEYS

All of the payload keys defined in L<Config::Apple::Profile::Payload::Common>
are used by this payload.

This payload has the following additional keys:

=head2 C<Name>

I<Optional>

A string.  This is the name the user sees at the time the Font is installed.
Once installed, the font's embedded PostScript name is what the user will see.

=head2 C<Font>

Data.  This is the TrueType (.ttf) or OpenType (.otf) font file.

B<NOTE:> Font collections (.ttc or .otc) are not supported.  Use separate
payloads for each font.

B<NOTE:> Each font installed must have a unique embedded PostScript name.  If
multiple fonts with the same embedded PostScript name are installed, only one
will be displayed to the user; which one is actually used is undefined.

=cut

Readonly our %payloadKeys => (
    # Bring in the common keys...
    %Config::Apple::Profile::Payload::Common::payloadKeys,
    
    # ... and define our own!
    'Name' => {
        type => $ProfileString,
        description => 'Font name shown during installation.',
        optional => 1,
        targets => {
            $TargetIOS => '5.0',
        },
    },
    'Font' => {
        type => $ProfileData,
        description => 'The TrueType (.ttf) or OpenType (.otf) font file.',
        targets => {
            $TargetIOS => '5.0',
        },
    },
    
    # Finish with basic payload information
    'PayloadType' => {
        type => $ProfileString,
        value => 'com.apple.font',
        targets => {
            $TargetIOS => '5.0',
        },
    },
    'PayloadVersion' => {
        type => $ProfileNumber,
        value => 1,
        targets => {
            $TargetIOS => '5.0',
        },
    },
);  # End of %payloadKeys


=head1 ACKNOWLEDGEMENTS

Refer to L<Config::Apple::Profile> for acknowledgements.

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