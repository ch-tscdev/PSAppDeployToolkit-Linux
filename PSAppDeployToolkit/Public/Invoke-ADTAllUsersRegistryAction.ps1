#-----------------------------------------------------------------------------
#
# MARK: Invoke-ADTAllUsersRegistryAction
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: not supported on Linux (throws PlatformNotSupportedException).
#
#-----------------------------------------------------------------------------
function Invoke-ADTAllUsersRegistryAction
{
    <#
    .SYNOPSIS
        Set current user registry settings for all current users and any new users in the future.

    .DESCRIPTION
        Set HKCU registry settings for all current and future users by loading their NTUSER.dat registry hive file, and making the modifications.

        This function will modify HKCU settings for all users even when executed under the SYSTEM account and can be used as an alternative to using ActiveSetup for registry settings.

        To ensure new users in the future get the registry edits, the Default User registry hive used to provision the registry for new users is modified.

        The advantage of using this function over ActiveSetup is that a user does not have to log off and log back on before the changes take effect.

    .PARAMETER ScriptBlock
        Script block which contains HKCU registry actions to be run for all users on the system.

    .PARAMETER UserProfiles
        Specify the user profiles to modify HKCU registry settings for. Default is all user profiles except for system profiles.

    .PARAMETER SkipUnloadedProfiles
        Specifies that unloaded registry hives should be skipped and not be loaded by the function.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        None

        This function does not generate any output.

    .EXAMPLE
        Invoke-ADTAllUsersRegistryAction -ScriptBlock {
            Set-ADTRegistryKey -SID $_.SID -LiteralPath 'HKCU\Software\Microsoft\Office\14.0\Common' -Name 'qmenable' -Value 0 -Type DWord
            Set-ADTRegistryKey -SID $_.SID -LiteralPath 'HKCU\Software\Microsoft\Office\14.0\Common' -Name 'updatereliabilitydata' -Value 1 -Type DWord
        }

        Example demonstrating the setting of two values within each user's HKEY_CURRENT_USER hive.

    .EXAMPLE
        Invoke-ADTAllUsersRegistryAction {
            Set-ADTRegistryKey -SID $_.SID -LiteralPath 'HKCU\Software\Microsoft\Office\14.0\Common' -Name 'qmenable' -Value 0 -Type DWord
            Set-ADTRegistryKey -SID $_.SID -LiteralPath 'HKCU\Software\Microsoft\Office\14.0\Common' -Name 'updatereliabilitydata' -Value 1 -Type DWord
        }

        As the previous example, but showing how to use ScriptBlock as a positional parameter with no name specified.

    .EXAMPLE
        Invoke-ADTAllUsersRegistryAction -UserProfiles (Get-ADTUserProfiles -ExcludeDefaultUser) -ScriptBlock {
            Set-ADTRegistryKey -SID $_.SID -LiteralPath 'HKCU\Software\Microsoft\Office\14.0\Common' -Name 'qmenable' -Value 0 -Type DWord
            Set-ADTRegistryKey -SID $_.SID -LiteralPath 'HKCU\Software\Microsoft\Office\14.0\Common' -Name 'updatereliabilitydata' -Value 1 -Type DWord
        }

        As the previous example, but sending specific user profiles through to exclude the Default profile.

    .NOTES
        An active ADT session is NOT required to use this function.

        This function supports the `-WhatIf` and `-Confirm` parameters for testing changes before applying them.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Invoke-ADTAllUsersRegistryAction

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Invoke-ADTAllUsersRegistryAction.ps1
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [PSAppDeployToolkit.Attributes.ValidateUnique()]
        [System.Management.Automation.ScriptBlock[]]$ScriptBlock,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [PSAppDeployToolkit.Attributes.ValidateUnique()]
        [PSADT.AccountManagement.UserProfileInfo[]]$UserProfiles,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$SkipUnloadedProfiles
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
