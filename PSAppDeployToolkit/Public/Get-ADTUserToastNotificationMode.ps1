#-----------------------------------------------------------------------------
#
# MARK: Get-ADTUserToastNotificationMode
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: not supported on Linux (throws PlatformNotSupportedException).
#
#-----------------------------------------------------------------------------
function Get-ADTUserToastNotificationMode
{
    <#
    .SYNOPSIS
        Gets the user's toast notification mode.

    .DESCRIPTION
        The `Get-ADTUserToastNotificationMode` function gets the logged on user's toast notification mode, returning the mode, or `$null` if the API is unavailable (older OS, etc).

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        Windows.UI.Notifications.ToastNotificationMode

        Returns the determined mode.

    .EXAMPLE
        Get-ADTUserToastNotificationMode

        Returns the logged on user's toast notification state.

    .NOTES
        An active ADT session is NOT required to use this function.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Get-ADTUserToastNotificationMode

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Get-ADTUserToastNotificationMode.ps1
    #>

    [CmdletBinding()]
    [OutputType([System.String])]
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
