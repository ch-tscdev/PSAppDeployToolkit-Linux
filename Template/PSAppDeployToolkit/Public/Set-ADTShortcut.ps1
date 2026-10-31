#-----------------------------------------------------------------------------
#
# MARK: Set-ADTShortcut
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: not supported on Linux (throws PlatformNotSupportedException).
#
#-----------------------------------------------------------------------------
function Set-ADTShortcut
{
    <#
    .SYNOPSIS
        Modifies a .lnk or .url type shortcut.

    .DESCRIPTION
        The `Set-ADTShortcut` function modifies a .lnk or .url shortcut file, with the configured options. Only specify the parameters that you want to change.

    .PARAMETER LiteralPath
        Path to the shortcut to be changed.

    .PARAMETER InputObject
        An existing IShortcutLinkInfo object to modify.

    .PARAMETER TargetPath
        Sets target path or URL that the shortcut launches.

    .PARAMETER Arguments
        Sets the arguments used against the target path.

    .PARAMETER IconLocation
        Sets location of the icon used for the shortcut.

    .PARAMETER IconIndex
        Sets the index of the icon. Executables, DLLs, ICO files with multiple icons need the icon index to be specified. This parameter is an Integer. The first index is 0.

    .PARAMETER Description
        Sets the description of the shortcut as can be seen in the shortcut's properties.

    .PARAMETER WorkingDirectory
        Sets working directory to be used for the target path.

    .PARAMETER WindowStyle
        Sets the shortcut's window style to be minimised, maximised, etc.

    .PARAMETER RunAsAdmin
        Specifies that the command executed by the shortcut should be done so with elevated permissions. Setting this option will prompt the user to elevate when the shortcut is executed.

    .PARAMETER Hotkey
        Sets the hotkey to launch the shortcut, e.g. "CTRL+SHIFT+F".

    .PARAMETER Clear
        Clears one or more shortcut properties. Only clears if the corresponding parameter isn't specified.

    .PARAMETER Force
        Forces creation of the shortcut if one doesn't already exist at the `-LiteralPath` provided.

    .PARAMETER PassThru
        Returns an IShortcutLinkInfo snapshot of the shortcut.

    .INPUTS
        PSADT.ShortcutManagement.IShortcutLinkInfo

        You can pipe an IShortcutLinkInfo object into this function to specify the shortcut to modify.

        When piping an IShortcutLinkInfo object into this function, the only properties modified are the ones explicitly specified via this function's parameters.

    .OUTPUTS
        None

        By default, this function does not return any output.

    .OUTPUTS
        PSADT.ShortcutManagement.IShortcutLinkInfo

        When the `-PassThru` parameter is provided, this function returns an IShortcutLinkInfo object representing the modified shortcut.

    .EXAMPLE
        Set-ADTShortcut -LiteralPath "$envCommonDesktop\Application.lnk" -TargetPath "$envProgramFiles\Application\application.exe"

        Modifies the existing shortcut on the All Users desktop named 'Application' so it targets '$envProgramFiles\Application\application.exe'.

    .EXAMPLE
        Get-ADTShortcut -LiteralPath "$envCommonDesktop\Application.lnk" | Set-ADTShortcut -WindowStyle Maximized

        Modifies the shortcut on the All Users desktop named 'Application' to launch maximized.

    .NOTES
        An active ADT session is NOT required to use this function.

        Url shortcuts support TargetPath, IconLocation, IconIndex, Description and Hotkey. Other parameters are ignored: an internet shortcut has nowhere to keep them.

        This function supports the `-WhatIf` and `-Confirm` parameters for testing changes before applying them.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Set-ADTShortcut

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Set-ADTShortcut.ps1
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSADT.ShortcutManagement.IShortcutLinkInfo])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 0, ParameterSetName = 'LiteralPath')]
        [PSAppDeployToolkit.Attributes.ValidateExtension('.lnk', '.url')]
        [Alias('Path')]
        [System.String]$LiteralPath,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'InputObject')]
        [ValidateNotNull()]
        [PSADT.ShortcutManagement.IShortcutLinkInfo]$InputObject,

        [Parameter(Mandatory = $false)]
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
        [PSADT.ShortcutManagement.ShortcutWindowStyle]$WindowStyle,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$RunAsAdmin,

        [Parameter(Mandatory = $false)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$Hotkey,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Arguments', 'IconLocation', 'IconIndex', 'Description', 'WorkingDirectory', 'WindowStyle', 'RunAsAdmin', 'Hotkey')]
        [System.String[]]$Clear,

        [Parameter(Mandatory = $false, ParameterSetName = 'LiteralPath')]
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
