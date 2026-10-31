#-----------------------------------------------------------------------------
#
# MARK: Get-ADTWindowTitle
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: not supported on Linux (throws PlatformNotSupportedException).
#
#-----------------------------------------------------------------------------
function Get-ADTWindowTitle
{
    <#
    .SYNOPSIS
        Search for an open window title and return details about the window.

    .DESCRIPTION
        Search for a window title. If window title searched for returns more than one result, then details for each window will be displayed.

        Returns the following properties for each window:

        - WindowTitle
        - WindowHandle
        - ParentProcess
        - ParentProcessId
        - ParentProcessMainWindowHandle

    .PARAMETER WindowTitle
        The title of the application window to search for using regex matching.

    .PARAMETER WindowHandle
        One or more window handles of the application window to search for.

    .PARAMETER ParentProcess
        One or more process names of the application window to search for.

    .PARAMETER ParentProcessId
        One or more process ids of the application window to search for.

    .PARAMETER ParentProcessMainWindowHandle
        One or more process main window handles of the application window to search for.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        PSADT.WindowManagement.WindowInfo

        Returns a WindowInfo object with the following properties:

        - WindowTitle
        - WindowHandle
        - ParentProcess
        - ParentProcessId
        - ParentProcessMainWindowHandle

    .EXAMPLE
        Get-ADTWindowTitle

        Gets details for all windows with a title.

    .EXAMPLE
        Get-ADTWindowTitle -WindowTitle 'Microsoft Word'

        Gets details for each window that has the words "Microsoft Word" in the title.

    .EXAMPLE
        Get-ADTWindowTitle | Where-Object { $_.ParentProcess -eq 'WINWORD' }

        Get details for all windows belonging to Microsoft Word process with name "WINWORD".

    .NOTES
        An active ADT session is NOT required to use this function.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Get-ADTWindowTitle

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Get-ADTWindowTitle.ps1
    #>

    [CmdletBinding()]
    [OutputType([PSADT.WindowManagement.WindowInfo])]
    param
    (
        [Parameter(Mandatory = $false)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$WindowTitle,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.IntPtr[]]$WindowHandle,

        [Parameter(Mandatory = $false)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String[]]$ParentProcess,

        [Parameter(Mandatory = $false)]
        [PSAppDeployToolkit.Attributes.ValidateGreaterThanZero()]
        [System.UInt32[]]$ParentProcessId,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.IntPtr[]]$ParentProcessMainWindowHandle
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
