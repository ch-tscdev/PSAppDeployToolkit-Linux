#-----------------------------------------------------------------------------
#
# MARK: Test-ADTMSUpdates
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: not supported on Linux (throws PlatformNotSupportedException).
#
#-----------------------------------------------------------------------------
function Test-ADTMSUpdates
{
    <#
    .SYNOPSIS
        Test whether a Microsoft Windows update is installed.

    .DESCRIPTION
        The `Test-ADTMSUpdates` function checks if a specified Microsoft Windows update, identified by its KB number, is installed on the local machine. It first attempts to find the update using the `Get-HotFix` cmdlet and, if unsuccessful, uses a COM object to search the update history.

    .PARAMETER KbNumber
        KBNumber of the update.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        System.Boolean

        Returns `$true` if the update is installed, otherwise returns `$false`.

    .EXAMPLE
        Test-ADTMSUpdates -KBNumber 'KB2549864'

        Checks if the Microsoft Update 'KB2549864' is installed and returns `$true` or `$false`.

    .NOTES
        An active ADT session is NOT required to use this function.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Test-ADTMSUpdates

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Test-ADTMSUpdates.ps1
    #>

    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'Enter the KB Number for the Microsoft Update')]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$KbNumber
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
