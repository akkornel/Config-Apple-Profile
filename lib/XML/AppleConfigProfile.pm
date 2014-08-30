package XML::AppleConfigProfile;

use 5.14.4;
use strict;
use warnings FATAL => 'all';

our $VERSION = '0.00_001';

=head1 NAME

XML::Apple::ConfigProfile - The great new XML::Apple::ConfigProfile!


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use XML::Apple::ConfigProfile;

    my $foo = XML::Apple::ConfigProfile->new();
    ...


=head1 DESCRIPTION

Apple provides organizations (be they enterprises or other) a way to configure
Apple devices, called B<Configuration Profiles>.  A configuration profile is
essentially a .plist file, which is XML but with a plist DOCTYPE.  The MIME
type for a configuration profile is C<application/x-apple-aspen-config>, and
typically use the C<.mobileconfig> file extension.

Configuration profiles can be used by iOS and Mac OS X to set a number of
general and user-specific items.  Examples include:

* Configuring an LDAP server, for directory search in Mail and Contacts.
* Specifying password requirements to match company policy (and common sense).
* Configuring an email account, with or without a user's credentials.
* Adding new certificate authorities.

A configuration profile contains one or more B<Payloads>, in addition to some
header information.  In Perl terms, a payload can be thought of as a Hash.
There are some keys of the "hash" that are common to all types of payloads,
and of course other keys that are payload-specific.  Some keys are optinal,
and some keys are only optional on one platform or the other (iOS or Mac OS X).
In addition, there are some payloads that are only valid on one platform.  For
example, the C<XML::AppleConfigProfile::Payload::FileVault> payload can only be
used with a Mac OS X configuration profile.

For a list of all payloads that Apple currently recognizes, refer to the
I<Configuration Profile Reference> linked below.  Not all payloads are
implemented in this release.  If you are interested in seeing more payloads
supported, please contribute!  See the L<SOURCE> section below for more info.  

Files in this release are arranged as follows:

 XML::
   AppleConfigProfile.pm:   <-- This file
   AppleConfigProfile::
     Profile.pm:            <-- The root of any configuration profile
     
     Payload::              <-- All payload-related classes are in here
       Common.pm            <-- Common payload elements are here
       Certificate.pm       <-- The Certificate payload type
       Email.pm             <-- The Email payload type

As an example, if you want to create a configuration profile that configures an
IMAP email account, an LDAP server, and a passcode policy, you would need the
following modules:

* L<XML::AppleConfigProfile::Payload::Email> would configure the email account.
* L<XML::AppleConfigProfile::Payload::LDAP> would configure the LDAP server.
* L<XML::AppleConfigProfile::Payload::Passcode> would configure the passcode
policy.
* L<XML::AppleConfigProfile::Profile> would put everything together, and give
you the final profile.


=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.


=head1 BUGS

Please report any bugs or feature requests to C<bug-xml-apple-configprofile at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Apple-ConfigProfile>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SEE ALSO

* "Configuration Profile Reference".  I<iOS Developer Library>.  L<https://developer.apple.com/library/ios/featuredarticles/iphoneconfigurationprofileref/Introduction/Introduction.html>
* "Over-the-Air Profile Delivery and Configuration".  I<iOS Developer Library>.  L<https://developer.apple.com/library/iOs/documentation/NetworkingInternet/Conceptual/iPhoneOTAConfiguration/Introduction/Introduction.html>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::Apple::ConfigProfile

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-Apple-ConfigProfile>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML-Apple-ConfigProfile>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XML-Apple-ConfigProfile>

=item * Search CPAN

L<http://search.cpan.org/dist/XML-Apple-ConfigProfile/>

=back


=head1 SOURCE

This project is on GitHub:

 L<https://github.com/akkornel/XML-AppleConfigProfile>
 
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
