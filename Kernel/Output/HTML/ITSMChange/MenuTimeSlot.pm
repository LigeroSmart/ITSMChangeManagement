# Modified version of the work: Copyright (C) 2019 Ligero, https://www.complemento.net.br/
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, https://otrs.com/# --
# Copyright (C) 2001-2018 OTRS AG, https://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Output::HTML::ITSMChange::MenuTimeSlot;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::ITSMChange',
    'Kernel::System::Log',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get UserID param
    $Self->{UserID} = $Param{UserID} || die "Got no UserID!";

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{Change} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need Change!',
        );
        return;
    }

    # check whether there are any workorders yet
    return $Param{Counter} if !$Param{Change}->{WorkOrderCount};

    # The change can no longer be moved, when the change has already started.
    return $Param{Counter} if $Param{Change}->{ActualStartTime};

    # get config for the relevant action
    my $FrontendConfig = $Kernel::OM->Get('Kernel::Config')->Get("ITSMChange::Frontend::$Param{Config}->{Action}");

    # get the required privilege, 'ro' or 'rw'
    my $RequiredPriv;
    if ($FrontendConfig) {

        # get the required priv from the frontend configuration
        $RequiredPriv = $FrontendConfig->{Permission};
    }

    # Display the menu-link, when no privilege is required
    my $Access = 1;

    if ($RequiredPriv) {

        # check permissions, based on the required privilege
        $Access = $Kernel::OM->Get('Kernel::System::ITSMChange')->Permission(
            Type     => $RequiredPriv,
            Action   => $Param{Config}->{Action},
            ChangeID => $Param{Change}->{ChangeID},
            UserID   => $Self->{UserID},
            LogNo    => 1,
        );
    }

    return $Param{Counter} if !$Access;

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # output menu block
    $LayoutObject->Block( Name => 'Menu' );

    # output seperator, when this is not the first menu item
    if ( $Param{Counter} ) {
        $LayoutObject->Block( Name => 'MenuItemSplit' );
    }

    # output menu item
    $LayoutObject->Block(
        Name => 'MenuItem',
        Data => {
            %Param,
            %{ $Param{Change} },
            %{ $Param{Config} },
        },
    );
    $Param{Counter}++;

    return $Param{Counter};
}

1;
