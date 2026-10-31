#-----------------------------------------------------------------------------
#
# MARK: Close-ADTNotifyIcon
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: Linux implementation.
#
#-----------------------------------------------------------------------------
function Close-ADTNotifyIcon
{
    <#
    .SYNOPSIS
        Closes the notification icon created by `Show-ADTNotifyIcon`.

    .DESCRIPTION
        The `Close-ADTNotifyIcon` function closes the notification icon created by `Show-ADTNotifyIcon`. This function is called by the `Close-ADTSession` function to close an open notification icon if found.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        None

        This function does not generate any output.

    .EXAMPLE
        Close-ADTNotifyIcon

        This example closes the dialog created by `Show-ADTNotifyIcon`.

    .NOTES
        An active ADT session is NOT required to use this function.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Close-ADTNotifyIcon

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Close-ADTNotifyIcon.ps1
    #>

    [CmdletBinding()]
    param
    (
    )

    begin
    {
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process
    {
        # Headless: there is never a dialog to close on Linux.
        Write-ADTLogEntry -Message "Bypassing $($MyInvocation.MyCommand.Name) as no dialog is open (Linux: no UI available)." -DebugMessage
    }

    end
    {
        Complete-ADTFunction -Cmdlet $PSCmdlet
    }
}
