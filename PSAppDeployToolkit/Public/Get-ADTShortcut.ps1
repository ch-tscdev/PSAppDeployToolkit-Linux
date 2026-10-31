#-----------------------------------------------------------------------------
#
# MARK: Get-ADTShortcut
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: not supported on Linux (throws PlatformNotSupportedException).
#
#-----------------------------------------------------------------------------
function Get-ADTShortcut
{
    <#
    .SYNOPSIS
        Get information from a .lnk or .url type shortcut.

    .DESCRIPTION
        The `Get-ADTShortcut` function gets information from a .lnk or .url type shortcut. Returns an IShortcutLinkInfo object with details about the shortcut such as TargetPath, Arguments, Description, and more.

    .PARAMETER LiteralPath
        Path to the shortcut to get information from.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        PSADT.ShortcutManagement.IShortcutLinkInfo

        Returns an object with the following properties:
        - TargetPath
        - Arguments
        - Description
        - WorkingDirectory
        - WindowStyle
        - Hotkey
        - IconLocation
        - IconIndex
        - RunAsAdmin

    .EXAMPLE
        Get-ADTShortcut -LiteralPath "$envProgramData\Microsoft\Windows\Start Menu\My Shortcut.lnk"

        Retrieves information from the specified .lnk shortcut.

    .NOTES
        An active ADT session is NOT required to use this function.

        Url shortcuts support TargetPath, IconLocation, IconIndex, Description and Hotkey. Other parameters are ignored: an internet shortcut has nowhere to keep them.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Get-ADTShortcut

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Get-ADTShortcut.ps1
    #>

    [CmdletBinding()]
    [OutputType([PSADT.ShortcutManagement.IShortcutLinkInfo])]
    param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [PSAppDeployToolkit.Attributes.ValidateExtension('.lnk', '.url')]
        [Alias('Path', 'PSPath')]
        [System.String]$LiteralPath
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
