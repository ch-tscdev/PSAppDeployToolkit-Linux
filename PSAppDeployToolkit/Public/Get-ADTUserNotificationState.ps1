#-----------------------------------------------------------------------------
#
# MARK: Get-ADTUserNotificationState
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: Linux implementation.
#
#-----------------------------------------------------------------------------
function Get-ADTUserNotificationState
{
    <#
    .SYNOPSIS
        Gets the specified user's notification state.

    .DESCRIPTION
        The `Get-ADTUserNotificationState` function gets the active user's notification state.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        PSADT.Interop.QUERY_USER_NOTIFICATION_STATE

        Returns the user's QUERY_USER_NOTIFICATION_STATE value as an enum.

    .EXAMPLE
        Get-ADTUserNotificationState

        Returns the logged on user's notification state.

    .NOTES
        An active ADT session is NOT required to use this function.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Get-ADTUserNotificationState

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Get-ADTUserNotificationState.ps1
    #>

    [CmdletBinding()]
    [OutputType([PSADT.Interop.QUERY_USER_NOTIFICATION_STATE])]
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
                # Windows notification state (QUERY_USER_NOTIFICATION_STATE) has no Linux equivalent.
                return [PSADT.Interop.QUERY_USER_NOTIFICATION_STATE]::QUNS_ACCEPTS_NOTIFICATIONS
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
