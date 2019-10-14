package credsman;
use 5.018000;
use strict;
use warnings;
use Types::Standard qw( Int Str CodeRef );
use Params::ValidationCompiler qw( validation_for );
use Data::Dumper;
use Exporter qw(import);
our @EXPORT_OK = qw(login);

our $VERSION = '1.00';

require XSLoader;
XSLoader::load('credsman', $VERSION);

# There are 4 XS internal functions that interact with Credential Manager
# RemoveCredentials  - Remove Credentials
# SaveCredentials    - Store Credentials
# GuiCredentials     - Open Prompt USER and PASSWORD gui
# work_name          - Creates Credentials Name String 

#------------------------------------------------------------#
my $validator = validation_for(
    params => {
        Program   => { type => Str },
        Target    => { type => Str },
        SubRef    => { type => CodeRef },
        Limit     => { type => Int, optional => 1, default => 3 },
        Debug     => { type => Int, optional => 1, default => 0 }
    }
);

sub login{
    my %arg = $validator->(@_);
    say  "*** Arguments ****\n".Dumper \%arg if $arg{Debug};
    my %wrkCred = (
        status   => 5,
        attempt  => 0,
        limit    => $arg{Limit},
        password => undef,
        user     => undef,
        target   => $arg{Target},
    );
    # Concat Target Name - This is the name to be stored 
    my $TargetName = work_name($arg{Program},$arg{Target});
    say "TargetName : ".$TargetName if $arg{Debug};
    # Load Passwords ad runs the function passed with the argument
    while ($wrkCred{status} != 0 and $wrkCred{attempt} < $wrkCred{limit}){
        say "in loop" if $arg{Debug};
        # load Credentials from Windows Credential Manager
        ($wrkCred{user}, $wrkCred{password}) = @{LoadCredentials($TargetName)};
        say "*** Load Credentials ****\n".Dumper \%wrkCred if $arg{Debug};
        # Check if the Credentials was found
        if( !defined $wrkCred{user}){
            # Request User and Password GUI
            say "Not Defined" if $arg{Debug};
            ($wrkCred{user}, $wrkCred{password}) = @{
                GuiCredentials(
                    $arg{Program}, 
                    $arg{Target}, 
                    $TargetName, 
                    $wrkCred{attempt})
            };
            # No user or password passed, or cancel
            unless(defined $wrkCred{user} and defined $wrkCred{password}){
                die "Cancel" ;
            }

            say "After GUI \n".Dumper \%wrkCred if $arg{Debug};
            # Store Credentials in Windoes Credential Manager
            if( SaveCredentials($TargetName, $wrkCred{user}, $wrkCred{password}) ){
                die "Error to Save Credentials";
            };
        }
        else {
            # Call Function passed in Argument
            $wrkCred{status} = $arg{SubRef}->(\%wrkCred);
            # Expeciting RC 0 to pass
            if ($wrkCred{status}){
                $wrkCred{attempt}++;
                RemoveCredentials($TargetName);
            }
        }
    }
    # Clear Credentials for Security
    $wrkCred{user}     =~ s/.*/ /g;
    $wrkCred{password} =~ s/.*/ /g;
    say "END" if $arg{Debug};
    # Return Status
    return $wrkCred{status};
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

credsman - Perl extension for blah blah blah

=head1 SYNOPSIS

  use credsman;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for credsman, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

    # Windows Credential Manager - Generic Credentials
    # format:
    # *['program name']~['Server name or Addres']*


Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

A. U. Thor, E<lt>a.u.thor@a.galaxy.far.far.awayE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by A. U. Thor

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.30.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
