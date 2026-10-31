#-----------------------------------------------------------------------------
#
# MARK: Test-ADTUserInFocusMode
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: Linux implementation.
#
#-----------------------------------------------------------------------------
function Test-ADTUserInFocusMode
{
    <#
    .SYNOPSIS
        Tests whether the user is in focus mode.

    .DESCRIPTION
        The `Test-ADTUserInFocusMode` function tests whether the user is in focus mode, returning `$true`/`$false`, or `$null` if the API is unavailable (older OS, etc).

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        None

        Returns `$null` if there is no active user or the API is unavailable.

    .OUTPUTS
        System.Boolean

        Returns `$true` if the active user is in focus mode and `$false` when they aren't.

    .EXAMPLE
        Test-ADTUserInFocusMode

        Returns whether the logged on user is in focus mode or not, or `$null` if the API is unavailable.

    .NOTES
        An active ADT session is NOT required to use this function.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Test-ADTUserInFocusMode

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Test-ADTUserInFocusMode.ps1
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
                # Not applicable on Linux (Windows-only concept).
                return $false
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
