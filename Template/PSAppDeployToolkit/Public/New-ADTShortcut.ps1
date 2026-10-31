#-----------------------------------------------------------------------------
#
# MARK: New-ADTShortcut
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: not supported on Linux (throws PlatformNotSupportedException).
#
#-----------------------------------------------------------------------------
function New-ADTShortcut
{
    <#
    .SYNOPSIS
        Creates a new .lnk or .url type shortcut.

    .DESCRIPTION
        The `New-ADTShortcut` function creates a new .lnk or .url shortcut file, with the configured options. This function allows you to specify various parameters such as the target path, arguments, icon location, description, working directory, window style, run as administrator, and hotkey.

    .PARAMETER LiteralPath
        Path to save the shortcut.

    .PARAMETER TargetPath
        Target path or URL that the shortcut launches.

    .PARAMETER Arguments
        Arguments to be passed to the target path.

    .PARAMETER IconLocation
        Location of the icon used for the shortcut.

    .PARAMETER IconIndex
        The index of the icon. Executables, DLLs, ICO files with multiple icons need the icon index to be specified. This parameter is an Integer. The first index is 0.

    .PARAMETER Description
        Description of the shortcut.

    .PARAMETER WorkingDirectory
        Working Directory to be used for the target path.

    .PARAMETER WindowStyle
        Windows style of the application.

    .PARAMETER RunAsAdmin
        Specifies that the command executed by the shortcut should be done so with elevated permissions. Setting this option will prompt the user to elevate when the shortcut is executed.

    .PARAMETER Hotkey
        Create a Hotkey to launch the shortcut, e.g. "CTRL+SHIFT+F".

    .PARAMETER Force
        Specifies that an existing shortcut should be overwritten.

    .PARAMETER PassThru
        Returns an IShortcutLinkInfo object representing the new shortcut.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        None

        By default, this function does not return any output.

    .OUTPUTS
        PSADT.ShortcutManagement.IShortcutLinkInfo

        When the `-PassThru` parameter is provided, this function returns an IShortcutLinkInfo object representing the new shortcut.

    .EXAMPLE
        New-ADTShortcut -LiteralPath "$envCommonStartMenuPrograms\My Shortcut.lnk" -TargetPath "$envWinDir\notepad.exe" -IconLocation "$envWinDir\notepad.exe" -Description 'Notepad' -WorkingDirectory '%HOMEDRIVE%\%HOMEPATH%'

        Creates a new shortcut for Notepad with the specified parameters.

    .NOTES
        An active ADT session is NOT required to use this function.

        Url shortcuts support TargetPath, IconLocation, IconIndex, Description and Hotkey. Other parameters are ignored: an internet shortcut has nowhere to keep them.

        This function supports the `-WhatIf` and `-Confirm` parameters for testing changes before applying them.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/New-ADTShortcut

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/New-ADTShortcut.ps1
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSADT.ShortcutManagement.IShortcutLinkInfo])]
    param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [PSAppDeployToolkit.Attributes.ValidateExtension('.lnk', '.url')]
        [Alias('Path', 'PSPath')]
        [System.String]$LiteralPath,

        [Parameter(Mandatory = $true)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$TargetPath,

        [Parameter(Mandatory = $false)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$Arguments,

        [Parameter(Mandatory = $false)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$IconLocation,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.Nullable[System.UInt32]]$IconIndex,

        [Parameter(Mandatory = $false)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$Description,

        [Parameter(Mandatory = $false)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$WorkingDirectory,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [PSADT.ShortcutManagement.ShortcutWindowStyle]$WindowStyle = [PSADT.ShortcutManagement.ShortcutWindowStyle]::Normal,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$RunAsAdmin,

        [Parameter(Mandatory = $false)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$Hotkey,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$Force,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$PassThru
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
