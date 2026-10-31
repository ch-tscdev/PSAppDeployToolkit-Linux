#-----------------------------------------------------------------------------
#
# MARK: Test-ADTPowerPoint
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: Linux implementation.
#
#-----------------------------------------------------------------------------
function Test-ADTPowerPoint
{
    <#
    .SYNOPSIS
        Tests whether PowerPoint is running in either fullscreen slideshow mode or presentation mode.

    .DESCRIPTION
        The `Test-ADTPowerPoint` function tests whether someone is presenting using PowerPoint in either fullscreen slideshow mode or presentation mode. This function checks if the PowerPoint process has a window with a title that begins with "PowerPoint Slide Show" or "PowerPoint-" for non-English language systems. There is a possibility of a false positive if the PowerPoint filename starts with "PowerPoint Slide Show". If the previous detection method does not detect PowerPoint in fullscreen mode, it checks if PowerPoint is in Presentation Mode (only works on Windows Vista or higher).

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        System.Boolean

        Returns `$true` if PowerPoint is running in either fullscreen slideshow mode or presentation mode, otherwise returns `$false`.

    .EXAMPLE
        Test-ADTPowerPoint

        Checks if PowerPoint is running in either fullscreen slideshow mode or presentation mode and returns `$true` or `$false`.

    .NOTES
        An active ADT session is NOT required to use this function.

        This function can only execute detection logic if the process is in interactive mode.

        There is a possibility of a false positive if the PowerPoint filename starts with "PowerPoint Slide Show".

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Test-ADTPowerPoint

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Test-ADTPowerPoint.ps1
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
