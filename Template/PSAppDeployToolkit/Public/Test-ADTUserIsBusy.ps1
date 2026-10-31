#-----------------------------------------------------------------------------
#
# MARK: Test-ADTUserIsBusy
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: Linux implementation.
#
#-----------------------------------------------------------------------------
function Test-ADTUserIsBusy
{
    <#
    .SYNOPSIS
        Tests whether the device is considered to be in a busy state, such as when a user is using the microphone, device is in focus mode, presenting a PowerPoint slide deck, and more.

    .DESCRIPTION
        The `Test-ADTUserIsBusy` function tests whether the device is considered to be in a busy state using the following metrics in the following order:
        * Device's microphone is in use.
        * User has entered "focus mode".
        * User has enabled "do not disturb" mode.
        * User's notification state indicates their busy, presenting, etc.
        * Whether PowerPoint is open and they're presenting in full screen.

        If any of these tests return true, then all other tests thereafter are not ran as they're not necessary.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        System.Boolean

        Returns `$true` if the device is considered to be in a busy state, such as when a user is using the microphone, device is in focus mode, presenting a PowerPoint slide deck, and more.

    .EXAMPLE
        Test-ADTUserIsBusy

        Tests whether the device is considered to be in a busy state, such as when a user is using the microphone, device is in focus mode, presenting a PowerPoint slide deck, and more.

    .NOTES
        An active ADT session is NOT required to use this function.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Test-ADTUserIsBusy

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Test-ADTUserIsBusy.ps1
    #>

    [CmdletBinding()]
    [OutputType([System.Boolean])]
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
                # Only the microphone check has a Linux equivalent; presentation/focus/full-screen checks are Windows-only.
                return (Test-ADTMicrophoneInUse)
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
