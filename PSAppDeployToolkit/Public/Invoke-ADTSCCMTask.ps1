#-----------------------------------------------------------------------------
#
# MARK: Invoke-ADTSCCMTask
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: not supported on Linux (throws PlatformNotSupportedException).
#
#-----------------------------------------------------------------------------
function Invoke-ADTSCCMTask
{
    <#
    .SYNOPSIS
        Triggers Configuration Manager/SCCM to invoke the requested schedule task ID.

    .DESCRIPTION
        The `Invoke-ADTSCCMTask` function triggers Configuration Manager/SCCM to invoke the requested schedule task ID. This function supports a variety of Schedule Id values as defined via https://learn.microsoft.com/en-us/intune/configmgr/develop/reference/core/clients/client-classes/triggerschedule-method-in-class-sms_client.

    .PARAMETER ScheduleId
        Name of the Schedule Id to trigger.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        None

        This function does not return any objects.

    .EXAMPLE
        Invoke-ADTSCCMTask -ScheduleId 'SoftwareUpdatesScan'

        Triggers the 'SoftwareUpdatesScan' schedule task in Configuration Manager/SCCM.

    .EXAMPLE
        Invoke-ADTSCCMTask -ScheduleId 'HardwareInventory'

        Triggers the 'HardwareInventory' schedule task in Configuration Manager/SCCM.

    .NOTES
        An active ADT session is NOT required to use this function.

        This function supports the `-WhatIf` and `-Confirm` parameters for testing changes before applying them.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Invoke-ADTSCCMTask

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Invoke-ADTSCCMTask.ps1
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [PSADT.ConfigMgr.TriggerScheduleId]$ScheduleId
    )

    begin
    {
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process
    {
        try
        {
            Invoke-ADTLinuxNotSupported -Cmdlet $PSCmdlet
        }
        catch
        {
            Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
        }
    }

    end
    {
        Complete-ADTFunction -Cmdlet $PSCmdlet
    }
}
