package Config::Apple::Profile;

use 5.10.1;
use strict;
use warnings FATAL => 'all';
use base qw(Config::Apple::Profile::Payload::Common);

use Exporter::Easiest q(OK => $VERSION);
use Mac::PropertyList;
use Readonly;
use Config::Apple::Profile::Payload::Common;
use Config::Apple::Profile::Payload::Types qw(:all);
use Config::Apple::Profile::Targets qw(:all);

our $VERSION = '0.87.1';


=encoding utf8

=head1 NAME

Config::Apple::Profile - An OO interface to Apple Configuration Profiles.


=head1 SYNOPSIS

    use File::Temp;
    use Config::Apple::Profile;
    use Config::Apple::Profile::Payload::Certificate::PEM;
    use Config::Apple::Profile::Payload::Wireless;

    my $cert = new Config::Apple::Profile::Payload::Certificate::PEM;
    my $cert_payload = $cert->payload;
    $cert_payload->{PayloadIdentifier} = 'com.example.group15.payload.cert';
    $cert_payload->{PayloadCertificateFileName} = 'myCA.pem';
    $cert_payload->{PayloadContent} = <<END;
    ----- BEGIN CERTIFICATE -----
    dsfkldfsbnjksjkgnndbfjkdgnjdfkgjkndfg
    # snip
    dgkdfgldmklbgklmd==
    ----- END CERTIFICATE -----
    ENDCERT

    my $wifi = new Config::Apple::Profile::Payload::Wireless;
    my $wifi_payload = $wifi->payload;
    $wifi_payload->{PayloadIdentifier} = 'com.example.group15.payload.wireless';
    $wifi_payload->{SSID_STR} = 'CorpNet Public';
    $wifi_payload->{EncryptionType} = 'None';

    my $profile = new Config::Apple::Profile;
    my $profile_payload = $profile->payload;
    $profile_payload->{PayloadIdentifier} = 'com.example.group15.payload';
    $profile_payload->{PayloadDisplayName} = "My Group's Profile";
    push @{$profile_payload->{PayloadContent}}, $cert_payload, $wireless_payload;

    my ($fh, $file) = tempfile('CorpConfig',
                               SUFFIX => '.mobileconfig', UNLINK => 0);
    print $fh $profile->export;
    close $fh;
    print "Configuration Profile written to $file\n";


=head1 DESCRIPTION

Apple provides users with a way to configure Apple devices (running iOS or Mac
OS X) using ready-made configuration files, which Apple calls
B<Configuration Profiles>.  This suite of Perl modules is intended to aid
people who would like to generate their own configuration profiles, without
having to mess around with the XML themselves.

Configuration profiles can be used by iOS and Mac OS X to set a number of
general and user-specific items.  Examples include:

=over 4

=item *

Configuring an LDAP server, for directory search in Mail and Contacts.

=item *

Specifying password requirements to match company policy (and common sense).

=item *

Configuring an email account, with or without a user's credentials.

=item *

Adding new certificate authorities.

=back

Configuration profiles can be pre-made static files, or they can be
dynamically-generated with configurations (such as usernames and passwords)
that are specific to a user.  Configuration profiles may be encrypted (so they
may only be read on a specific device) and signed (to verify that they have not
been modified by anyone other than the profile's creator).

A configuration profile contains one or more B<Payloads>, in addition to some
header information.  In Perl terms, a payload can be thought of as a Hash.
There are some keys of the "hash" that are common to all types of payloads,
and of course other keys that are payload-specific.  Some keys are optinal,
and some keys are only optional on one platform or the other (iOS or Mac OS X).
In addition, there are some payloads that are only valid on one platform.  For
example, the C<Config::Apple::Profile::Payload::FileVault> payload can only be
used with a Mac OS X configuration profile.

For a list of all payloads that Apple currently recognizes, refer to the
I<Configuration Profile Reference> linked below.  Not all payloads are
implemented in this release.  If you are interested in seeing more payloads
supported, please contribute!  See the L<SOURCE> section below for more info.  


=head1 CLASS HIERARCHY

Classes are laid out in the following hierarchy:

 Config::Apple::
   Profile                  <-- This file
   Profile::
     Payload::              <-- All payload-related classes are in here
       Common.pm            <-- Common payload elements are here
       Certificate.pm       <-- The Certificate payload type
       Certificate::        <-- Certificate sub-types are here
       Email.pm             <-- The Email payload type
       Tie::                <-- Internal support code
     Encryption.pm          <-- Profile encryption (TBI)
     Signing.pm             <-- Profile signing (TBI)

Clients need only C<use> the modules that directly provide the functionality
they are looking for.

As an example, if you want to create a configuration profile that configures an
IMAP email account, an LDAP server, and a passcode policy, you would need the
following modules:

=over 4

=item * L<Config::Apple::Profile::Payload::Email> would configure the email account.

=item * L<Config::Apple::Profile::Payload::LDAP> would configure the LDAP server.

=item * L<Config::Apple::Profile::Payload::Passcode> would configure the passcode
policy.

=item * This module would put everything together, and give you the final profile.

=back

=cut


=head1 CLASS METHODS

=head2 new()

Returns a new object.

=cut

# This call automatically goes up to Config::Apple::Profile::Payload::Common


=head1 INSTANCE METHODS

=head2 INHERITED METHODS

Most of the methods, including critical ones such as C<keys> and C<payload>,
are implemented in the module C<Config::Apple::Profile::Payload::Common>,
and are not reimplemented here.  See L<Config::Apple::Profile::Payload::Common>.


=head2 export()

    export([C<option1_name> => C<option1_value>, ...])

Return a string containing the profile, serialized as XML.  The entire string
will already be encoded as UTF-8.  If any UUID or Identifier keys have not been
filled in, they are filled in with random values.

This method is used when it is time to output a profile.

Several parameters can be provided, which will influence how this method runs.

=over 4

=item target

If C<target> (a value from L<Config::Apple::Profile::Targets>) is provided,
then this will be taken into account when exporting.  Only payload keys that
are used on the specified target will be included in the output.

The C<completeness> option controls what happens if keys are excluded.

=item version

If C<version> (a version string) is provided, then only payload keys that work
on the specified version will be included in the output.

If C<version> is provided, then C<target> must also be set, but C<target> can
be set without setting C<version>.

The C<completeness> option controls what happens if keys are excluded.

=item completeness

If C<completeness> is set to a true value, and keys are excluded because of
C<target> or C<version>, then C<plist> will throw an exception.  If set to a
false value, or if not set at all, then no exceptions will be thrown, and a
less-than-complete (but still valid) plist will be returned.

=back

The following exceptions may be thrown:

=over 4

=item Config::Apple::Profile::Exception::KeyRequired

Thrown if a required key has not been set.

=item Config::Apple::Profile::Exception::Incomplete

Thrown if payload keys are being excluded from the output because of C<target>
or C<version>.

=back

=cut

sub export {
    my $self = shift @_;
    
    # Fill in identifiers/UUIDs, then convert to plist, and export
    $self->populate_id;
    my $plist = $self->plist(@_);
    return Mac::PropertyList::plist_as_string($plist);
}


=head1 PAYLOAD KEYS

Payload keys are the keys that you can use when manipulating the hash returned
by C<payload>.

All of the payload keys defined in L<Config::Apple::Profile::Payload::Common>
are used by this payload.

This payload has the following additional keys:

=head2 C<PayloadContent>

I<Optional, but not really>

An array of C<Config::Apple::Profile::Payload::> objects.

=head2 C<EncryptedPayloadContent>

I<Optional>

Payload contents that are encrypted, such that only a single device may decrypt
and read it.  This is a Data type, which is formed by first taking the contents
of C<PayloadContent>, and serializing them as a plist with an array as the root
element.  Next, the contents are CMS-encrypted as enveloped data, then finally
DER-encoded.

Until C<Config::Apple::Profile::Encryption> is implemented, the following
OpenSSL command can be used to encrypt the plist.

    openssl cms -encrypt -in your.mobileconfig_fragment 
    -out your.mobileconfig_fragment.encrypted -outform der -cmsout
    your_recipients_cert.pem

OpenSSL 1 or later is required for the C<cms> command.

=head2 C<PayloadScope>

I<Optional>

Applies to Mac OS X only.

Can be set to "System", in which case the profile will apply system-wide,
or "User", in which case the profile will only apply to the user installing
the profile.

If not set, the default is "User". 

=head2 C<ConsentText>

I<Optional>

A dictionary of strings.  The keys are locale identifiers, specifically
canonicalized IETF BCP 47 locale strings.  Each value is a localized text string
containing a message that the user will see when installing the profile.  This
is a place to put warnings, agreements, etc..

An extra pair, with the key "default", may be included to provide a default
consent message.  If no default is set, the "en" localization will be used as a
last resort.

=head2 C<PayloadRemovalDisallowed>

I<Optional>

A boolean.  If set to C<true>, then the profile may only be removed if a
profile removal password is provided.  To set such a password, include an object
from L<Config::Apple::Profile::Payload::ProfileRemovalPassword> as part of
C<PayloadContents>.

=head2 C<DurationUntilRemoval>

I<Optional>

A floating-point number, the number of seconds that the profile will remain on
the device before it is automatically removed.

If C<RemovalDate> is set, this value will be ignored.

=head2 C<RemovalDate>

I<Optional>

A date.  Once past, the profile will be automatically removed from the device.

This value overrides C<DurationUntilRemoval>.

=head2 C<PayloadExpirationDate>

I<Optional>

A date.  This only applies to payloads delivered over-the-air, using a mobile
device management (MDM) solution.  Once past, this profile will be marked as
"expired", and will be eligible for updating over-the-air.

=cut

Readonly our %payloadKeys => (
    # Bring in the common keys...
    %Config::Apple::Profile::Payload::Common::payloadKeys,
    
    #... and define our own!
    'PayloadContent' => {
        type => $ProfileArray,
        subtype => $ProfileClass,
        description => 'The payloads to be delivered in this profile.',
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7',
        },
        optional => 1,
    },
    'EncryptedPayloadContent' => {
        type => $ProfileData,
        description => 'Payload content that has been encrypted to a specific '
            . 'user.  The contents of "PayloadContent" must be serialized as '
            . 'an array plist, then CMS-encrypted (as enveloped data), and '
            . 'finally serialized in DER format.',
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7',
        },
        optional => 1,
    },
    'PayloadExpirationDate' => {
        type => $ProfileDate,
        description => 'For profiles delivered via OTA, the date when the '
            . 'profile has expired and can be updated (again via OTA).',
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7',
        },
        optional => 1,
    },
    'PayloadRemovalDisallowed' => {
        type => $ProfileBool,
        description => 'If true, the profile may only be removed if a profile-'
            . 'removal password has been set, and the password is provided '
            . 'by the user.',
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7',
        },
        optional => 1,
    },
    'PayloadScope' => {
        type => $ProfileString,
        description => 'Controls if the profile applies to the entire "System",'
            . ' or if just to the specific "User".  If one of those two values '
            . 'is not provided, "User" will be used as the default.',
        targets => {
            # Desktop only, not for iOS
            $TargetMACOSX => '10.7',
        },
        optional => 1,
    },
    'RemovalDate' => {
        type => $ProfileDate,
        description => 'The date when the profile will be automatically removed'
            . ' from the device.  Overrides DurationUntilRemoval.',
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7',
        },
        optional => 1,
    },
    'DurationUntilRemoval' => {
        type => $ProfileReal,
        description => 'The number of seconds until the profile is '
            . 'automatically removed from the device.  The RemovalDate profile '
            . 'key overrides this one.',
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7',
        },
        optional => 1,
    },
    'ConsentText' => {
        type => $ProfileDict,
        subtype => $ProfileString,
        description => 'A dictionary where the keys are canonicalized IETF BCP '
            . '47 locale strings.  The key "default" may be used as the '
            . 'default entry.  The values are localized messages that the user '
            . 'must accept before the profile is installed.',
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
        optional => 1,
    },
    'PayloadType' => {
        type => $ProfileString,
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
        value => 'Configuration',
    },
    'PayloadVersion' => {
        type => $ProfileNumber,
        value => 1,
    },
);  # End of %payloadKeys


=head1 SEE ALSO

=over 4

=item * Apple's "Configuration Profile Reference".

L<https://developer.apple.com/library/ios/featuredarticles/iphoneconfigurationprofileref/Introduction/Introduction.html>

=item * Apple's "Over-the-Air Profile Delivery and Configuration" document.

L<https://developer.apple.com/library/iOs/documentation/NetworkingInternet/Conceptual/iPhoneOTAConfiguration/Introduction/Introduction.html>.

=back


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Config::Apple::Profile

All modules have some POD inside them.  If you're not interested in using the
command-line, your IDE may have PerlDoc support, or you can go here:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/Config-Apple-Profile>

=item * search.cpan.org

L<http://search.cpan.org/perldoc?Config::Apple::Profile>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Config-Apple-Profile>

=back

If you have found a bug, or want to request an enhancement of some sort, you
may do so here:

=over 4

=item * Github's issue section

https://github.com/akkornel/Config-Apple-Profile/issues

=item * RT: CPAN's request tracker (for people who don't use Github)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Config-Apple-Profile>

=back

Finally, feel free to rate the release!

=over 4

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Config-Apple-Profile>

=back


=head1 SOURCE

This project is on GitHub:

L<https://github.com/akkornel/Config-Apple-Profile>

The web site linked above has the most recently-pushed code, along with
information on how to get a copy to your computer.

If you are interested in making a contribution, please make it in the form
of a GitHub pull request.


=head1 ACKNOWLEDGEMENTS

Thanks are due to B<Brian D Foy> (C<BDFOY>) for the L<Mac::PropertyList>
module, which is relied on heavily by this code!


=head1 AUTHOR

A. Karl Kornel, C<< <karl at kornel.us> >>


=head1 COPYRIGHT AND LICENSE

Copyright 2014 A. Karl Kornel.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
