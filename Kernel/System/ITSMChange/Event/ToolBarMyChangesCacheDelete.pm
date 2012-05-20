# --
# Kernel/System/ITSMChange/Event/ToolBarMyChangesCacheDelete.pm - ToolBarMyChangesCacheDelete event module for ITSMChange
# Copyright (C) 2001-2012 OTRS AG, http://otrs.org/
# --
# $Id: ToolBarMyChangesCacheDelete.pm,v 1.2 2012-05-14 15:04:10 ub Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::ITSMChange::Event::ToolBarMyChangesCacheDelete;

use strict;
use warnings;

use Kernel::System::Cache;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.2 $) [1];

=head1 NAME

Kernel::System::ITSMChange::Event::ToolBarMyChangesCacheDelete - cache cleanup lib

=head1 SYNOPSIS

Event handler module for the toolbar cache delete in change management.

=head1 PUBLIC INTERFACE

=over 4

=item new()

create an object

    use Kernel::Config;
    use Kernel::System::Encode;
    use Kernel::System::Log;
    use Kernel::System::DB;
    use Kernel::System::Main;
    use Kernel::System::Time;
    use Kernel::System::ITSMChange::Event::ToolBarMyChangesCacheDelete;

    my $ConfigObject = Kernel::Config->new();
    my $EncodeObject = Kernel::System::Encode->new(
        ConfigObject => $ConfigObject,
    );
    my $LogObject = Kernel::System::Log->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
    );
    my $MainObject = Kernel::System::Main->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
        LogObject    => $LogObject,
    );
    my $TimeObject = Kernel::System::Time->new(
        ConfigObject => $ConfigObject,
        LogObject    => $LogObject,
    );
    my $DBObject = Kernel::System::DB->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
        LogObject    => $LogObject,
        MainObject   => $MainObject,
    );
    my $EventObject = Kernel::System::ITSMChange::Event::ToolBarMyChangesCacheDelete->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
        LogObject    => $LogObject,
        DBObject     => $DBObject,
        TimeObject   => $TimeObject,
        MainObject   => $MainObject,
    );

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get needed objects
    for my $Object (
        qw(DBObject ConfigObject EncodeObject LogObject UserObject GroupObject MainObject TimeObject)
        )
    {
        $Self->{$Object} = $Param{$Object} || die "Got no $Object!";
    }

    # create additional objects
    $Self->{CacheObject} = Kernel::System::Cache->new( %{$Self} );

    return $Self;
}

=item Run()

The C<Run()> method handles the events and deletes the caches for the toolbar.

It returns 1 on success, C<undef> otherwise.

    my $Success = $EventObject->Run(
        Event => 'ChangeUpdatePost',
        Data => {
            ChangeID        => 123,
            ChangeBuilderID => 5,
        },
        Config => {
            Event       => '(ChangeAddPost|ChangeUpdatePost||ChangeDeletePost)',
            Module      => 'Kernel::System::ITSMChange::Event::ToolBarMyChangesCacheDelete',
            Transaction => 0,
        },
        UserID => 1,
    );

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(Data Event Config UserID)) {
        if ( !$Param{$Argument} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # set the cache type prefix
    my $CacheTypePrefix = 'ITSMChangeManagementToolBarMyChanges';

    # handle adding of a change
    if ( $Param{Event} eq 'ChangeAddPost' ) {

        # do nothing if the ChangeBuilderID was not set
        return 1 if !$Param{Data}->{ChangeBuilderID};

        # set the cache type
        my $CacheType = $CacheTypePrefix . $Param{Data}->{ChangeBuilderID};

        # delete the cache
        $Self->{CacheObject}->CleanUp(
            Type => $CacheType,
        );

        return 1;
    }

    # handle update of a change
    elsif ( $Param{Event} eq 'ChangeUpdatePost' ) {

        # make sure the data is initialized
        $Param{Data}->{ChangeBuilderID} ||= '';
        $Param{Data}->{OldChangeData}->{ChangeBuilderID} ||= '';

        # do nothing if the ChangeBuilderID did not change
        return 1
            if $Param{Data}->{ChangeBuilderID} eq $Param{Data}->{OldChangeData}->{ChangeBuilderID};

        # set the cache type postfix
        my @CacheTypePostfixes = (
            $Param{Data}->{ChangeBuilderID},
            $Param{Data}->{OldChangeData}->{ChangeBuilderID},
        );

        # delete the cache for the old and the current change builder
        CACHETYPEPOSTFIX:
        for my $CacheTypePostfix (@CacheTypePostfixes) {

            # do nothing if the ChangeBuilderID was not set
            next CACHETYPEPOSTFIX if !$CacheTypePostfix;

            # set the cache type
            my $CacheType = $CacheTypePrefix . $CacheTypePostfix;

            # delete the cache
            $Self->{CacheObject}->CleanUp(
                Type => $CacheType,
            );
        }

        return 1;
    }

    # handle deleting a change
    elsif ( $Param{Event} eq 'ChangeDeletePost' ) {

        # do nothing if the ChangeBuilderID was not set
        return 1 if !$Param{Data}->{OldChangeData}->{ChangeBuilderID};

        # set the cache type
        my $CacheType = $CacheTypePrefix . $Param{Data}->{OldChangeData}->{ChangeBuilderID};

        # delete the cache
        $Self->{CacheObject}->CleanUp(
            Type => $CacheType,
        );

        return 1;
    }

    return 1;
}

=begin Internal:

=cut

1;

=end Internal:

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut

=head1 VERSION

$Revision: 1.2 $ $Date: 2012-05-14 15:04:10 $

=cut