# --
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::DBUpdate::MigrateZoomExpandConfig;    ## no critic

use strict;
use warnings;

use parent qw(scripts::DBUpdate::Base);

our @ObjectDependencies = (
    'Kernel::System::SysConfig',
    'Kernel::System::SysConfig::DB',
);

=head1 NAME

scripts::DBUpdate::MigrateZoomExpandConfig - Migrate modified ZoomExpand config value to AgentZoomExpand and
CustomerZoomExpand configs.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $Verbose = $Param{CommandlineOptions}->{Verbose} || 0;

    # Check for modified ZoomExpand value prior to OTRS 6.0.5.
    my $SysConfigDBObject  = $Kernel::OM->Get('Kernel::System::SysConfig::DB');
    my %ZoomExpandModified = $SysConfigDBObject->ModifiedSettingGet(
        Name => 'Ticket::Frontend::ZoomExpand',
    );

    my $ZoomExpandValue = $ZoomExpandModified{EffectiveValue};

    # If original ZoomExpand config is not modified there is nothing to migrate.
    if ( !$ZoomExpandValue ) {
        print "\n    There is no modified ZoomExpand config value, skipping migration... \n" if $Verbose;
        return 1;
    }

    # Migrate modified ZoomExpand config value to AgentZoomExpand and CustomerZoomExpand configs.
    for my $Config ( 'AgentZoomExpand', 'CustomerTicketZoom###CustomerZoomExpand' ) {

        my $Result = $Self->SettingUpdate(
            Name               => 'Ticket::Frontend::' . $Config,
            EffectiveValue     => $ZoomExpandValue,
            ContinueOnModified => 1,
            IsValid            => 1,
            UserID             => 1,
        );

        if ( !$Result ) {
            print
                "\n    Could not migrate config 'Ticket::Frontend::ZoomExpand' value to 'Ticket::Frontend::$Config'.. \n"
                if $Verbose;
        }
    }

    # Delete old ZoomExpand config modification from the DB.
    if ( $ZoomExpandModified{ModifiedID} ) {
        my $Success = $SysConfigDBObject->ModifiedSettingDelete(
            ModifiedID => $ZoomExpandModified{ModifiedID},
        );

        if ($Success) {
            print "\n    Deleted obsolete modified config 'Ticket::Frontend::ZoomExpand' from the DB. \n" if $Verbose;
        }
    }

    return 1;
}

1;
