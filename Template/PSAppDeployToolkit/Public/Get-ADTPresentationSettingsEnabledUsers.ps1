#-----------------------------------------------------------------------------
#
# MARK: Get-ADTPresentationSettingsEnabledUsers
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: Linux implementation.
#
#-----------------------------------------------------------------------------
function Get-ADTPresentationSettingsEnabledUsers
{
    <#
    .SYNOPSIS
        Tests whether any users have presentation mode enabled on their device.

    .DESCRIPTION
        Tests whether any users have presentation mode enabled on their device. This can be enabled via the PC's Mobility Settings, or with PresentationSettings.exe.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        PSADT.AccountManagement.UserProfileInfo

        Returns one or more UserProfileInfo objects of the users with presentation mode enabled on their device.

    .EXAMPLE
        Get-ADTPresentationSettingsEnabledUsers

        Checks whether any users users have presentation settings enabled on their device and returns an associated UserProfileInfo object.

    .NOTES
        This function is deprecated and will be removed in PSAppDeployToolkit 4.3.0.

        An active ADT session is NOT required to use this function.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Get-ADTPresentationSettingsEnabledUsers

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Get-ADTPresentationSettingsEnabledUsers.ps1
    #>

    [CmdletBinding()]
    [OutputType([PSADT.AccountManagement.UserProfileInfo])]
    param
    (
    )

    begin
    {
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process
    {
        try
        {
            try
            {
                # Windows presentation settings do not exist on Linux; no users are ever in presentation mode.
                Write-ADTLogEntry -Message 'Checking whether any logged on users are in presentation mode (not applicable on Linux).'
            }
            catch
            {
                Write-Error -ErrorRecord $_
            }
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
