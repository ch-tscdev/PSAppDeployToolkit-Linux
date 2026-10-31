#-----------------------------------------------------------------------------
#
# MARK: Show-ADTHelpConsole
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: not supported on Linux (throws PlatformNotSupportedException).
#
#-----------------------------------------------------------------------------
function Show-ADTHelpConsole
{
    <#
    .SYNOPSIS
        Displays a help console for the PSAppDeployToolkit module.

    .DESCRIPTION
        The `Show-ADTHelpConsole` function displays a help console for the PSAppDeployToolkit module in a new PowerShell window. The console provides a graphical interface to browse and view detailed help information for all commands exported by the PSAppDeployToolkit module. The help console includes a list box to select commands and a text box to display the full help content for the selected command.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        None

        This function does not return any output.

    .EXAMPLE
        Show-ADTHelpConsole

        Opens a new PowerShell window displaying the help console for the PSAppDeployToolkit module.

    .NOTES
        An active ADT session is NOT required to use this function.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Show-ADTHelpConsole

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Show-ADTHelpConsole.ps1
    #>

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
