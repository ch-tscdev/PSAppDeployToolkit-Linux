#-----------------------------------------------------------------------------
#
# MARK: Remove-ADTRegistryKey
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: not supported on Linux (throws PlatformNotSupportedException).
#
#-----------------------------------------------------------------------------
function Remove-ADTRegistryKey
{
    <#
    .SYNOPSIS
        Deletes the specified registry key or value.

    .DESCRIPTION
        The `Remove-ADTRegistryKey` function deletes the specified registry key or value. It can handle both registry keys and values, and it supports recursive deletion of registry keys via the `-Recurse` parameter. If the `-SID` parameter is specified, it converts HKEY_CURRENT_USER registry keys to the HKEY_USERS\$SID format, allowing for the manipulation of HKCU registry settings for all users on the system.

    .PARAMETER Path
        Path of the registry key to delete, wildcards permitted.

    .PARAMETER LiteralPath
        Literal path of the registry key to delete.

    .PARAMETER Name
        Name of the registry value to delete.

    .PARAMETER Wow6432Node
        Specify this switch to read the 32-bit registry (WOW6432Node) on 64-bit systems.

    .PARAMETER Recurse
        Delete registry key recursively.

    .PARAMETER SID
        The security identifier (SID) for a user. Specifying this parameter will convert a HKEY_CURRENT_USER registry key to the HKEY_USERS\$SID format.

        Specify this parameter from the `Invoke-ADTAllUsersRegistryAction` function to read/edit HKCU registry settings for all users on the system.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        None

        This function does not generate any output.

    .EXAMPLE
        Remove-ADTRegistryKey -LiteralPath 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\RunOnce'

        Deletes the specified registry key.

    .EXAMPLE
        Remove-ADTRegistryKey -LiteralPath 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Run' -Name 'RunAppInstall'

        Deletes the specified registry value.

    .EXAMPLE
        Remove-ADTRegistryKey -LiteralPath 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Example' -Name '(Default)'

        Deletes the default registry value in the specified key.

    .EXAMPLE
        Remove-ADTRegistryKey -Path 'HKEY_LOCAL_MACHINE\SOFTWARE\MyCustomKey\*' -Recurse

        Removes all subkeys from `HKEY_LOCAL_MACHINE\SOFTWARE\MyCustomKey` as requested.

    .EXAMPLE
        Remove-ADTRegistryKey -Path 'HKEY_LOCAL_MACHINE\SOFTWARE\MyCustomKey\*' -Name 'PropertyName'

        Removes `PropertyName` from all subkeys of `HKEY_LOCAL_MACHINE\SOFTWARE\MyCustomKey`.

    .NOTES
        An active ADT session is NOT required to use this function.

        This function supports the `-WhatIf` and `-Confirm` parameters for testing changes before applying them.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Remove-ADTRegistryKey

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Remove-ADTRegistryKey.ps1
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'Path')]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [SupportsWildcards()]
        [System.String]$Path,

        [Parameter(Mandatory = $true, ParameterSetName = 'LiteralPath')]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [Alias('Key')]
        [System.String]$LiteralPath,

        [Parameter(Mandatory = $false)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$Name,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$Wow6432Node,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$Recurse,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [PSADT.AccountManagement.UnixIdentity]$SID
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
