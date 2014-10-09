# This is the code for Config::Apple::Profile::Payload::Email.
# For Copyright, please see the bottom of the file.

package Config::Apple::Profile::Payload::Email;

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

Config::Apple::Profile::Payload::Email - The Email payload type.

=head1 SYNOPSIS

    use Config::Apple::Profile;
    use Config::Apple::Profile::Payload::Email;
    
    my $email = new Config::Apple::Profile::Payload::Email;
    my $payload = $email->payload;
    
    $payload->{EmailAccountDescription} = 'Example Email';
    $payload->{EmailAccountName} = 'Simon Blarfingar';
    $payload->{EmailAddress} = 'user@example.com';
    $payload->{EmailAccountType} = 'EmailTypeIMAP';
    
    $payload->{IncomingMailServerHostName} = 'mail.example.com';
    $payload->{OutgoingMailServerHostName} = $payload->{IncomingMailServerHostName};
    
    $payload->{IncomingMailServerAuthentication} = 'EmailAuthPassword';
    $payload->{OutgoingMailServerAuthentication} = $payload->{IncomingMailServerAuthentication};
    
    $payload->{IncomingMailServerUsername} = $payload->{EmailAddress};
    $payload->{OutgoingMailServerUsername} = $payload->{IncomingMailServerUsername};
    
    $payload->{OutgoingPasswordSameAsIncomingPassword} = 1;
    $payload->{SMIMEEnabled} = 1;

    my $profile = new Config::Apple::Profile::Profile;
    push @{$profile->content}, $email;
    
    print $profile->export;

=head1 DESCRIPTION

This class implements the Email payload, which is used to configure POP
and IMAP accounts.  For Exchange accounts, refer to
L<Config::Apple::Profile::Payload::Exchange::iOS> or
L<Config::Apple::Profile::Payload::Exchange::OSX>.

Each email account has basic information, information about how to fetch mail,
information about how to send mail, S/MIME configuration, and interaction.

For fetching mail, either POP or IMAP can be used.  Authentication is with
a password, or it can be turned off.  SMTP is used for sending mail, either
with or without a username and password.  SSL is supported for both sending
and receiving, and is enabled by default.

B<NOTE:> If the server(s) are only accessible on an internal network, you may
want to include a VPN payload as part of the profile, so that the user will
be able to access the server(s) while not on the internal Wi-Fi network.

Passwords can be included in the payload, but then the payload should be
encrypted, or delivered in some secure manner.  If passwords are not specified,
the user will be prompted to enter the password when the profile is installed.

S/MIME can be configured for email signing and decryption.  For S/MIME to work,
a .p12 file (a private key and certificate in a PKCS#12 container, also known
as an "identity certificate") must be on the device.  The identity certificate
can be loaded using L<Config::Apple::Profile::Payload::Certificate::PKCS12>,
and may be part of the same profile, or a different profile.  If S/MIME is
enabled but no signing or decrypting certificates are specified in the payload,
the user will be able to choose which identity certificate to use.

=head1 INSTANCE METHODS

The following instance methods are provided, or overridden, by this class.

=head2 validate_key($key, $value)

Performs additional validation for certain payload keys in this class:

=over 4

=item * C<EmailAddress>

This must be a properly-formed email address.

=item * C<EmailAccountType>

This must be the string C<EmailTypePOP> or C<EmailTypeIMAP>.

=item * C<IncomingMailServerHostName> and C<OutgoingMailServerHostName>

These must be properly-formed hostnames or IP addresses (IPv4 or IPv6).

=item * C<IncomingMailServerPortNumber> and C<OutgoingMailServerPortNumber>

These must be positive numbers less than 65535.

=item * C<IncomingMailServerAuthentication> and
C<OutgoingMailServerAuthentication>

These must be the string C<EmailAuthPassword> or C<EmailAuthNone>.

All other payload keys will be checked as usual by the parent class.

=back

See also the documentation in L<Config::Apple::Profile::Payload::Common>.

=cut

sub validate_key {
    my ($self, $key, $value) = @_;
    
    # Let's check over some of our keys
    # Email addresses must match RFC822
    if ($key eq 'EmailAddress') {
        ## no critic (ProhibitExplicitReturnUndef)
        return undef if !defined($value);
        ## use critic
        
        $value = Email::Valid->address($value);
        return $value;
    }
    
    # Email accounts must be POP or IMAP
    elsif ($key eq 'EmailAccountType') {
        if ($value =~ m/^(EmailTypePOP|EmailTypeIMAP)$/s) {
            return $1;
        }
        ## no critic (ProhibitExplicitReturnUndef)
        return undef;
        ## use critic
    }
    
    # Hostnames must be hostnames, or IP addresses
    elsif (   ($key eq 'IncomingMailServerHostName')
           || ($key eq 'OutgoingMailServerHostName')
    ) {
        if ($value =~ m/^( $RE{net}{domain}{-nospace}
                          |$RE{net}{IPv4}
                          |$RE{net}{IPv6}
                        )$
                       /isx) {
            return $1;
        }
        ## no critic (ProhibitExplicitReturnUndef)
        return undef;
        ## use critic
    }
    
    # Port numbers must be port numbers
    elsif (   ($key eq 'IncomingMailServerPortNumber')
           || ($key eq 'OutgoingMailServerPortNumber')
    ) {
        if ($value =~ m/^(\d+)$/s) {
            my $number = $1;
            return $number if ($number > 0) && ($number < 65535);
        }
        ## no critic (ProhibitExplicitReturnUndef)
        return undef;
        ## use critic
    }
    
    # Authentication must be by password or not at all
    elsif (   ($key eq 'IncomingMailServerAuthentication')
           || ($key eq 'OutgoingMailServerAuthentication')
    ) {
        if ($value =~ m/^(EmailAuthPassword|EmailAuthNone)$/s) {
            return $1;
        }
        ## no critic (ProhibitExplicitReturnUndef)
        return undef;
        ## use critic
    }
    
    # At this point, we've checked all of our special keys.  Over to the parent!
    return $self->SUPER::validate_key($key, $value);
}


=head1 PAYLOAD KEYS

All of the payload keys defined in L<Config::Apple::Profile::Payload::Common>
are used by this payload.

This payload has the following additional keys:

=head2 Basic account information

=head3 C<EmailAccountDescription>

I<Optional>

A string.  This is the account description shown in the Mail and Settings apps.

=head3 C<EmailAccountName>

I<Optional>

The sender's name, shown in outgoing email addresses.

=head3 C<EmailAddress>

I<Optional>

The sender's full email address.  If not provided, the user will be asked for
it during installation.

=head2 Fetching mail

=head3 C<EmailAccountType>

The type of email account.  This is a string, either C<EmailTypePOP> or
C<EmailTypeIMAP>.

=head3 CI<ncomingMailServerHostName>

The host name or IP address used for fetching mail.

=head3 C<IncomingMailServerPortNumber>

I<Optional>

The port number used for fetching mail.  If not specified, the default port
will be used.

=head3 C<IncomingMailserverUseSSL>

I<Optional>

A Boolean, which defaults to true.  If true, use SSL when fetching mail.

=head3 C<IncomingMailServerAuthentication>

The authentication method for fetching mail.  Allowed strings are
C<EmailAuthPassword> and C<EmailAuthNone>.

=head3 C<IncomingMailServerUsername>

I<Optional>

The username to use when fetching mail.  If a string is not provided, but
authentication is used, the user will be asked for it during installation.

=head3 C<IncomingPassword>

I<Optional>

The password to use when fetching mail.  If a string is not provided, but
authentication is used, the user may be asked for it during installation.

B<WARNING:> This is private information.  If this payload key is set, then the
profile should be delivered to the user in a secure way.

=head2 Sending Mail

=head3 C<OutgoingMailServerHostName>

The host name or IP address used for sending mail.

=head3 C<OutgoingMailServerPortNumber>

I<Optional>

The port number used for sending mail.  If not specified, ports 25, 587, and
465, in that order, will be tried.

=head3 C<OutgoingMailserverUseSSL>

I<Optional>

A Boolean, which defaults to true.  If true, use SSL when fetching mail.

=head3 C<OutgoingMailServerAuthentication>

The authentication method for sending mail.  Allowed strings are
C<EmailAuthPassword> and C<EmailAuthNone>.

=head3 C<OutgoingMailServerUsername>

I<Optional>

The username to use when sending mail.  If a string is not provided, but
authentication is used, the user will be asked for it during installation.

=head3 C<OutgoingPassword>

I<Optional>

The password to use when sending mail.  If a string is not provided, but
authentication is used, the user may be asked for it during installation.

B<WARNING:> This is private information.  If this payload key is set, then the
profile should be delivered to the user in a secure way.

=head3 C<OutgoingPasswordSameAsIncomingPassword>

I<Optional>

A Boolean, defaults to false.  If no passwords have been set in the profile,
but passwords are in use, and this key is true, then the user will be asked
for a password once, and that one password will be used for fetching and
sending mail.

=head2 S/MIME

=head3 C<SMIMEEnabled>

I<Optional>

A Boolean.  If true, this account supports S/MIME.  Defaults to false.

=head3 C<SMIMESigningCertificateUUID>

I<Optional>

The UUID of the PKCS12 Certificate payload used to sign emails.

=head3 C<SMIMEEncryptionCertificateUUID>

I<Optional>

The UUID of the PKCS12 Certificate payload used to decrypt emails.

=head3 C<SMIMEEnablePerMessageSwitch>

I<Optional>

A Boolean.  If true, users will be able to disable S/MIME on emails they send.
If false, S/MIME signing will be used for all emails, and S/MIME encryption will
be used whenever possible.

Default is false.

I<Available in iOS 8.0 and later only.>

=head2 Application Interaction

=head3 C<PreventMove>

I<Optional>

A Boolean.  If true, messages may not be moved to other email accounts, and
forwarding/replying from other accounts is prohibited.  Defaults to false.

This payload key only applies to iOS 5.0 and later.

=head3 C<PreventAppSheet>

I<Optional>

A Boolean.  If true, 3rd-party applications may not use this account to send
mail.  Defaults to false.

This payload key only applies to iOS 5.0 and later.

=head3 C<disableMailRecentsSyncing>

I<Optional>

A Boolean.  If true, this account is excluded from syncing recently-used
addresses.  Defaults to false.

This payload key only applies to iOS 6.0 and later.

=head2 C<PayloadType>

This is fixed to the string C<com.apple.mail.managed>.

=head2 C<PayloadVersion>

This is fixed to the value C<1>.

=cut

Readonly our %payloadKeys => (
    # Bring in the common keys...
    %Config::Apple::Profile::Payload::Common::payloadKeys,
    
    # ... and define our own!
    # Start with information about the user
    'EmailAccountDescription' => {
        type => $ProfileString,
        description => 'Description shown in the Mail and Settings apps.',
        optional => 1,
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'EmailAccountName' => {
        type => $ProfileString,
        description => "The sender's name, used in outgoing messages.",
        optional => 1,
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'EmailAddress' => {
        type => $ProfileString,
        description => "The sender's full email address.  If not provided, the"
                       . 'user will be asked for it during installation.',
        optional => 1,
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    
    # Information on how to fetch mail
    'EmailAccountType' => {
        type => $ProfileString,
        description => 'Either EmailTypePOP or EmailTypeIMAP.',
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'IncomingMailServerHostName' => {
        type => $ProfileString,
        description => 'The host name or IP for fetching mail.',
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'IncomingMailServerPortNumber' => {
        type => $ProfileNumber,
        description => 'The port number used for fetching mail.',
        optional => 1,
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'IncomingMailserverUseSSL' => {
        type => $ProfileBool,
        description => 'If true, use SSL to fetch mail.  Defaults to true.',
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'IncomingMailServerAuthentication' => {
        type => $ProfileString,
        description => 'The authentication method for fetching mail.  Allowed '
                       . 'values are EmailAuthPassword and EmailAuthNone.',
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'IncomingMailServerUsername' => {
        type => $ProfileString,
        description => 'The username to use when fetching mail.  If not '
                       . 'provided, the user may be asked for it during '
                       . 'installation.',
        optional => 1,
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'IncomingPassword' => {
        type => $ProfileString,
        description => 'The password to use when fetching mail.  If not '
                       . 'provided, the user may be asked for it during '
                       . 'installation.',
        optional => 1,
        private => 1,
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    
    # Information on how to send mail
    'OutgoingMailServerHostName' => {
        type => $ProfileString,
        description => 'The host name or IP for sending mail.',
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'OutgoingMailServerPortNumber' => {
        type => $ProfileNumber,
        description => 'The port number used for sending mail.  If not '
                       . 'specified, ports 25, 587, and 465 are checked.',
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
        optional => 1,
    },
    'OutgoingMailserverUseSSL' => {
        type => $ProfileBool,
        description => 'If true, use SSL to send mail.  Defaults to true.',
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'OutgoingMailServerAuthentication' => {
        type => $ProfileString,
        description => 'The authentication method for sending mail.  Allowed '
                       . 'values are EmailAuthPassword and EmailAuthNone.',
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'OutgoingMailServerUsername' => {
        type => $ProfileString,
        description => 'The username to use when sending mail.  If not '
                       . 'provided, the user may be asked for it during '
                       . 'installation.',
        optional => 1,
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'OutgoingPassword' => {
        type => $ProfileString,
        description => 'The password to use when sending mail.  If not '
                       . 'provided, the user may be asked for it during '
                       . 'installation.',
        optional => 1,
        private => 1,
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'OutgoingPasswordSameAsIncomingPassword' => {
        type => $ProfileBool,
        description => 'If true, the user will be prompted for a password only '
                       . 'once, and it will be used for sending and '
                       . 'receiving mail.',
        optional => 1,
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    
    # S/MIME
    'SMIMEEnabled' => {
        type => $ProfileBool,
        description => 'If true, this account supports S/MIME.  Default false.',
        optional => 1,
        targets => {
            $TargetIOS => '5.0',
        },
    },
    'SMIMESigningCertificateUUID' => {
        type => $ProfileUUID,
        description => 'The UUID of the PKCS12 payload used to sign emails.',
        optional => 1,
        targets => {
            $TargetIOS => '5.0',
        },
    },
    'SMIMEEncryptionCertificateUUID' => {
        type => $ProfileUUID,
        description => 'The UUID of the PKCS12 payload used to decrypt emails.',
        optional => 1,
        targets => {
            $TargetIOS => '5.0',
        },
    },
    'SMIMEEnablePerMessageSwitch' => {
        type => $ProfileBool,
        description => 'Allow users to disable use of S/MIME when they want.',
        optional => 1,
        targets => {
            $TargetIOS => '8.0',
        },
    },
    
    # Application interaction
    'PreventMove' => {
        type => $ProfileBool,
        description => 'If true, messages may not be moved to other email '
                       . 'accounts, and forwarding/replying from other '
                       . 'accounts is prohibited.  Defaults to false.',
        optional => 1,
        targets => {
            $TargetIOS => '5.0',
        },
    },
    'PreventAppSheet' => {
        type => $ProfileBool,
        description => 'If true, 3rd-party applications may not use this '
                       . 'account to send mail.  Defaults to false.',
        optional => 1,
        targets => {
            $TargetIOS => '5.0',
        },
    },
    'disableMailRecentsSyncing' => {
        type => $ProfileBool,
        description => 'If true, this account is excluded from syncing '
                       . 'recently-used addresses.  Defaults to false.',
        optional => 1,
        targets => {
            $TargetIOS => '6.0',
        },
    },
    
    # Finish with basic payload information
    'PayloadType' => {
        type => $ProfileString,
        value => 'com.apple.mail.managed',
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
        },
    },
    'PayloadVersion' => {
        type => $ProfileNumber,
        value => 1,
        targets => {
            $TargetIOS => '5.0',
            $TargetMACOSX => '10.7', 
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