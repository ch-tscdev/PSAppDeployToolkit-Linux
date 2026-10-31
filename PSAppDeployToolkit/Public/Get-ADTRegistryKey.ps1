#-----------------------------------------------------------------------------
#
# MARK: Get-ADTRegistryKey
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: not supported on Linux (throws PlatformNotSupportedException).
#
#-----------------------------------------------------------------------------
function Get-ADTRegistryKey
{
    <#
    .SYNOPSIS
        Retrieves value names and value data for a specified registry key or optionally, a specific value.

    .DESCRIPTION
        The `Get-ADTRegistryKey` function retrieves value names and value data for a specified registry key or optionally, a specific value. If the registry key does not exist or contain any values, the function will return `$null`.

        To test for the existence of a registry key path, use the built-in `Test-Path` cmdlet. To test for the existence of a registry key value, use the `Test-ADTRegistryValue` function.

    .PARAMETER Path
        Path of the registry key, wildcards permitted.

    .PARAMETER LiteralPath
        Literal path of the registry key.

    .PARAMETER Name
        Value name to retrieve (optional).

    .PARAMETER Wow6432Node
        Specify this switch to read the 32-bit registry (WOW6432Node) on 64-bit systems.

    .PARAMETER SID
        The security identifier (SID) for a user. Specifying this parameter will convert a HKEY_CURRENT_USER registry key to the HKEY_USERS\$SID format.

        Specify this parameter from the `Invoke-ADTAllUsersRegistryAction` function to read/edit HKCU registry settings for all users on the system.

    .PARAMETER ReturnEmptyKeyIfExists
        Return the registry key if it exists but it has no property/value pairs underneath it.

    .PARAMETER DoNotExpandEnvironmentNames
        Return unexpanded REG_EXPAND_SZ values.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        System.Int32

    .OUTPUTS
        System.Int64

    .OUTPUTS
        System.String

    .OUTPUTS
        System.Object

    .OUTPUTS
        PSCustomObject

        Returns the value of the registry key or value.

    .EXAMPLE
        Get-ADTRegistryKey -LiteralPath 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\VLC media player'

        This example retrieves all value names and data for the specified registry key.

    .EXAMPLE
        Get-ADTRegistryKey -LiteralPath 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\iexplore.exe'

        This example retrieves all value names and data for the specified registry key.

    .EXAMPLE
        Get-ADTRegistryKey -LiteralPath 'HKLM:Software\Wow6432Node\Microsoft\Microsoft SQL Server Compact Edition\v3.5' -Name 'Version'

        This example retrieves the 'Version' value data for the specified registry key.

    .EXAMPLE
        Get-ADTRegistryKey -LiteralPath 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -Name 'Path' -DoNotExpandEnvironmentNames

        This example retrieves the 'Path' value data without expanding environment variables.

    .EXAMPLE
        Get-ADTRegistryKey -LiteralPath 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Example' -Name '(Default)'

        This example retrieves the default value data for the specified registry key.

    .NOTES
        An active ADT session is NOT required to use this function.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Get-ADTRegistryKey

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Get-ADTRegistryKey.ps1
    #>

    [CmdletBinding()]
    [OutputType([System.Int32])]
    [OutputType([System.Int64])]
    [OutputType([System.String])]
    [OutputType([System.Object])]
    [OutputType([PSCustomObject])]
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
        [ValidateNotNullOrEmpty()]
        [PSADT.AccountManagement.UnixIdentity]$SID,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$ReturnEmptyKeyIfExists,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$DoNotExpandEnvironmentNames
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
