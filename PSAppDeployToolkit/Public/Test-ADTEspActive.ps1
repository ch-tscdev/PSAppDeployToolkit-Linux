#-----------------------------------------------------------------------------
#
# MARK: Test-ADTEspActive
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: Linux implementation.
#
#-----------------------------------------------------------------------------
function Test-ADTEspActive
{
    <#
    .SYNOPSIS
        Checks if the device is currently within a device or user Enrollment Status Page (ESP) phase.

    .DESCRIPTION
        The `Test-ADTEspActive` function checks if the device is currently within a device or user Enrollment Status Page (ESP) phase.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        System.Boolean

        Returns `$true` if the device is actively within a device or user ESP phase, otherwise `$false`.

    .EXAMPLE
        Test-ADTEspActive

        Checks if the device is actively within a device or user ESP phase or not and returns `$true` or `$false`.

    .NOTES
        An active ADT session is NOT required to use this function.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Test-ADTEspActive

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Test-ADTEspActive.ps1
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
