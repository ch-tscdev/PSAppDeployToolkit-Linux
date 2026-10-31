#-----------------------------------------------------------------------------
#
# MARK: Set-ADTRegistryKey
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: not supported on Linux (throws PlatformNotSupportedException).
#
#-----------------------------------------------------------------------------
function Set-ADTRegistryKey
{
    <#
    .SYNOPSIS
        Creates or sets a registry key name, value, and value data.

    .DESCRIPTION
        The `Set-ADTRegistryKey` function creates a registry key name, value, and value data; it sets the same if it already exists. This function can also handle registry keys for specific user SIDs and 32-bit registry on 64-bit systems.

    .PARAMETER LiteralPath
        The registry key path.

    .PARAMETER Name
        The value name.

    .PARAMETER Value
        The value data.

    .PARAMETER Type
        The type of registry value to create or set.

        DWord should be specified as a decimal.

    .PARAMETER MultiStringValueMode
        The mode to operate when working with MultiString objects. The default value for this parameter is `Replace`.

        Valid values for this parameter are:
        - `Replace`: Replaces the current value with the one(s) specified in `-Value`.
        - `Add`: Appends the values from `-Value` to the current registry value.
        - `Remove`: Removes the values from `-Value`.

    .PARAMETER Wow6432Node
        Specify this switch to write to the 32-bit registry (WOW6432Node) on 64-bit systems.

    .PARAMETER RegistryOptions
        Extra options to use while creating the key. This is useful for creating volatile keys that do not survive a reboot.

    .PARAMETER SID
        The security identifier (SID) for a user. Specifying this parameter will convert a HKEY_CURRENT_USER registry key to the HKEY_USERS\$SID format.

        Specify this parameter from the `Invoke-ADTAllUsersRegistryAction` function to read/edit HKCU registry settings for all users on the system.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        None

        This function does not return any output.

    .EXAMPLE
        Set-ADTRegistryKey -LiteralPath $blockedAppPath -Name 'Debugger' -Value $blockedAppDebuggerValue

        Creates or sets the 'Debugger' value in the specified registry key.

    .EXAMPLE
        Set-ADTRegistryKey -LiteralPath 'HKEY_LOCAL_MACHINE\SOFTWARE' -Name 'Application' -Type 'DWord' -Value '1'

        Creates or sets a DWord value in the specified registry key.

    .EXAMPLE
        Set-ADTRegistryKey -LiteralPath 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' -Name 'Debugger' -Value $blockedAppDebuggerValue -Type String

        Creates or sets a String value in the specified registry key.

    .EXAMPLE
        Set-ADTRegistryKey -LiteralPath 'HKCU\Software\Microsoft\Example' -Name 'Data' -Value (0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x02,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x02,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x00,0x01,0x01,0x01,0x02,0x02,0x02) -Type 'Binary'

        Creates or sets a Binary value in the specified registry key.

    .EXAMPLE
        Set-ADTRegistryKey -LiteralPath 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Example' -Name '(Default)' -Value "Text"

        Creates or sets the default value in the specified registry key.

    .NOTES
        An active ADT session is NOT required to use this function.

        This function supports the `-WhatIf` and `-Confirm` parameters for testing changes before applying them.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Set-ADTRegistryKey

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Set-ADTRegistryKey.ps1
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true, HelpMessage = 'New/Set-ItemProperty parameter')]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [Alias('Key')]
        [System.String]$LiteralPath,

        [Parameter(Mandatory = $false, HelpMessage = 'New/Set-ItemProperty parameter')]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$Name,

        [Parameter(Mandatory = $false, HelpMessage = 'New/Set-ItemProperty parameter')]
        [System.Object]$Value,

        [Parameter(Mandatory = $false, HelpMessage = 'New/Set-ItemProperty parameter')]
        [ValidateNotNullOrEmpty()]
        [Microsoft.Win32.RegistryValueKind]$Type,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Replace', 'Add', 'Remove')]
        [System.String]$MultiStringValueMode = 'Replace',

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$Wow6432Node,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.Win32.RegistryOptions]$RegistryOptions,

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
