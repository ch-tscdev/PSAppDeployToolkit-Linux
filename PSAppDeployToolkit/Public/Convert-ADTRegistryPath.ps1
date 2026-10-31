#-----------------------------------------------------------------------------
#
# MARK: Convert-ADTRegistryPath
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: not supported on Linux (throws PlatformNotSupportedException).
#
#-----------------------------------------------------------------------------
function Convert-ADTRegistryPath
{
    <#
    .SYNOPSIS
        Converts the specified registry key path to a format that is compatible with built-in PowerShell cmdlets.

    .DESCRIPTION
        The `Convert-ADTRegistryPath` function converts the specified registry key path to a format that is compatible with built-in PowerShell cmdlets.

        Converts registry key hives to their full paths. Example: HKLM is converted to "Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE".

    .PARAMETER Key
        Path to the registry key to convert (can be a registry hive or fully qualified path)

    .PARAMETER Wow6432Node
        Specifies that the 32-bit registry view (WOW6432Node) should be used on a 64-bit system.

    .PARAMETER SID
        The security identifier (SID) for a user. Specifying this parameter will convert a HKEY_CURRENT_USER registry key to the HKEY_USERS\$SID format.

        Specify this parameter from the `Invoke-ADTAllUsersRegistryAction` function to read/edit HKCU registry settings for all users on the system.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        System.String

        Returns the converted registry key path.

    .EXAMPLE
        Convert-ADTRegistryPath -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\TreeSize Free_is1'

        Converts the specified registry key path to a format compatible with PowerShell cmdlets.

    .EXAMPLE
        Convert-ADTRegistryPath -Key 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\VLC media player'

        Converts the specified registry key path to a format compatible with PowerShell cmdlets.

    .NOTES
        An active ADT session is NOT required to use this function.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Convert-ADTRegistryPath

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Convert-ADTRegistryPath.ps1
    #>

    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$Key,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [PSADT.AccountManagement.UnixIdentity]$SID,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$Wow6432Node
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
