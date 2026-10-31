#-----------------------------------------------------------------------------
#
# MARK: Install-ADTSCCMSoftwareUpdates
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: not supported on Linux (throws PlatformNotSupportedException).
#
#-----------------------------------------------------------------------------
function Install-ADTSCCMSoftwareUpdates
{
    <#
    .SYNOPSIS
        Scans for outstanding Configuration Manager/SCCM software updates to be installed and installs the pending updates.

    .DESCRIPTION
        The `Install-ADTSCCMSoftwareUpdates` function scans for outstanding Configuration Manager/SCCM software updates to be installed and installs the pending updates.

        This function can take several minutes to run.

        Note: This function is not compatible with versions of the Configuration Manager/SCCM Client older than 2012.

    .PARAMETER SoftwareUpdatesScanWait
        The amount of time to wait for the software updates scan to complete. Accepts TimeSpan objects, but also interprets numerical values as seconds.

    .PARAMETER WaitForPendingUpdatesTimeout
        The amount of time to wait for missing and pending updates to install before exiting the function. Accepts TimeSpan objects, but also interprets numerical values as seconds.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        None

        This function does not return any objects.

    .EXAMPLE
        Install-ADTSCCMSoftwareUpdates

        Scans for outstanding Configuration Manager/SCCM updates and installs the pending updates with default wait times.

    .EXAMPLE
        Install-ADTSCCMSoftwareUpdates -WaitForPendingUpdatesTimeout 00:30:00

        Scans for outstanding Configuration Manager/SCCM updates and installs the pending updates with a 30 minute timeout.

    .EXAMPLE
        Install-ADTSCCMSoftwareUpdates -WaitForPendingUpdatesTimeout (New-TimeSpan -Minutes 30)

        Scans for outstanding Configuration Manager/SCCM updates and installs the pending updates with a 30 minute timeout.

    .NOTES
        An active ADT session is NOT required to use this function.

        This function supports the `-WhatIf` and `-Confirm` parameters for testing changes before applying them.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Install-ADTSCCMSoftwareUpdates

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Install-ADTSCCMSoftwareUpdates.ps1
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $false)]
        [Alias('SoftwareUpdatesScanWaitInSeconds')]
        [PSAppDeployToolkit.Attributes.TimeSpanTransformation()]
        [PSAppDeployToolkit.Attributes.ValidateGreaterThanZero()]
        [System.TimeSpan]$SoftwareUpdatesScanWait = [System.TimeSpan]::FromSeconds(180),

        [Parameter(Mandatory = $false)]
        [PSAppDeployToolkit.Attributes.TimeSpanTransformation()]
        [ValidateNotNullOrEmpty()]
        [System.TimeSpan]$WaitForPendingUpdatesTimeout = [System.TimeSpan]::FromMinutes(45)
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
