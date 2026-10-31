#-----------------------------------------------------------------------------
#
# MARK: Set-ADTItemPermission
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: not supported on Linux (throws PlatformNotSupportedException).
#
#-----------------------------------------------------------------------------
function Set-ADTItemPermission
{
    <#
    .SYNOPSIS
        Changes permissions on files or folders.

    .DESCRIPTION
        The `Set-ADTItemPermission` function allows you to easily change permissions on files or folders for a given user or group. You can add, remove or replace permissions, set inheritance and propagation.

    .PARAMETER LiteralPath
        Path to the folder or file you want to modify (ex: C:\Temp)

    .PARAMETER AccessControlList
        The ACL object to apply to the given path.

    .PARAMETER User
        One or more user names (ex: BUILTIN\Users, DOMAIN\Admin) to assign the permissions to. If you want to use a SID, prefix it with an asterisk (`*`), i.e., '*S-1-5-18'

    .PARAMETER Permission
        Permission or list of permissions to be set/added/removed/replaced. Permission DeleteSubdirectoriesAndFiles does not apply to files.

    .PARAMETER PermissionType
        Sets Access Control Type of the permissions.

    .PARAMETER Inheritance
        Sets permission inheritance. Does not apply to files. Multiple options can be specified.

        Valid values for this parameter are:
        * `None`: The permission entry is not inherited by child objects.
        * `ObjectInherit`: The permission entry is inherited by child leaf objects.
        * `ContainerInherit`: The permission entry is inherited by child container objects.

    .PARAMETER Propagation
        Sets how to propagate inheritance. Does not apply to files.

        Valid values for this parameter are:
        * `None`: Specifies that no inheritance flags are set.
        * `NoPropagateInherit`: Specifies that the permission entry is not propagated to child objects.
        * `InheritOnly`: Specifies that the permission entry is propagated only to child objects. This includes both container and leaf child objects.

    .PARAMETER Method
        Specifies which method will be used to apply the permissions.

        Valid values for this parameter are:
        * `AddAccessRule`: Adds permission rules but it does not remove previous permissions.
        * `SetAccessRule`: Overwrites matching permission rules with new ones.
        * `ResetAccessRule`: Removes matching permission rules and then adds permission rules.
        * `RemoveAccessRule`: Removes matching permission rules.
        * `RemoveAccessRuleAll`: Removes all permission rules for specified users.
        * `RemoveAccessRuleSpecific`: Removes specific permissions.

    .PARAMETER EnableInheritance
        Enables inheritance on the files/folders.

    .PARAMETER DisableInheritance
        Disables inheritance, preserving permissions before doing so.

    .PARAMETER RemoveExplicitRules
        Removes non-inherited permissions from the object when enabling inheritance.

    .PARAMETER Owner
        The user or group to set as the owner of the item (ex: BUILTIN\Administrators, DOMAIN\Admin). If you want to use a SID, prefix it with an asterisk (`*`), i.e., '*S-1-5-18'. The owner is changed before any permissions are modified.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        None

        This function does not return any output.

    .EXAMPLE
        Set-ADTItemPermission -LiteralPath 'C:\Temp' -User 'DOMAIN\John', 'BUILTIN\Users' -Permission FullControl -Inheritance ObjectInherit,ContainerInherit

        Will grant FullControl permissions to 'John' and 'Users' on 'C:\Temp' and its files and folders children.

    .EXAMPLE
        Set-ADTItemPermission -LiteralPath 'C:\Temp\pic.png' -User 'DOMAIN\John' -Permission 'Read'

        Will grant Read permissions to 'John' on 'C:\Temp\pic.png'.

    .EXAMPLE
        Set-ADTItemPermission -LiteralPath 'C:\Temp\Private' -User 'DOMAIN\John' -Permission 'None' -Method 'RemoveAccessRuleAll'

        Will remove all permissions to 'John' on 'C:\Temp\Private'.

    .EXAMPLE
        Set-ADTItemPermission -LiteralPath 'C:\Temp' -Owner 'BUILTIN\Administrators'

        Will set 'BUILTIN\Administrators' as the owner of 'C:\Temp' without modifying its access rules.

    .NOTES
        An active ADT session is NOT required to use this function.

        Original Author: Julian DA CUNHA - dacunha.julian@gmail.com, used with permission.

        This function supports the `-WhatIf` and `-Confirm` parameters for testing changes before applying them.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Set-ADTItemPermission

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Set-ADTItemPermission.ps1
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true, HelpMessage = 'Path to the folder or file you want to modify (ex: C:\Temp)', ParameterSetName = 'DisableInheritance')]
        [Parameter(Mandatory = $true, HelpMessage = 'Path to the folder or file you want to modify (ex: C:\Temp)', ParameterSetName = 'EnableInheritance')]
        [Parameter(Mandatory = $true, HelpMessage = 'Path to the folder or file you want to modify (ex: C:\Temp)', ParameterSetName = 'AccessControlList')]
        [Parameter(Mandatory = $true, HelpMessage = 'Path to the folder or file you want to modify (ex: C:\Temp)', ParameterSetName = 'OwnerOnly')]
        [ValidateScript({
                if (!(Test-Path -LiteralPath $_))
                {
                    $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName LiteralPath -ProvidedValue $_ -ExceptionMessage 'The specified path does not exist.'))
                }
                return ![System.String]::IsNullOrWhiteSpace($_)
            })]
        [Alias('Path', 'PSPath', 'File', 'Folder')]
        [System.String]$LiteralPath,

        [Parameter(Mandatory = $true, HelpMessage = 'The ACL object to apply to the given path.', ParameterSetName = 'AccessControlList')]
        [ValidateNotNullOrEmpty()]
        [System.Security.AccessControl.FileSystemSecurity]$AccessControlList,

        [Parameter(Mandatory = $true, HelpMessage = 'One or more user names (ex: BUILTIN\Users, DOMAIN\Admin). If you want to use SID, prefix it with an asterisk * (ex: ''*S-1-5-18'')', ParameterSetName = 'DisableInheritance')]
        [Alias('Username', 'Users', 'SID', 'Usernames')]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [PSAppDeployToolkit.Attributes.ValidateUnique()]
        [System.String[]]$User,

        [Parameter(Mandatory = $true, HelpMessage = "Permission or list of permissions to be set/added/removed/replaced. To see all the possible permissions go to 'http://technet.microsoft.com/fr-fr/library/ff730951.aspx'", ParameterSetName = 'DisableInheritance')]
        [Alias('Grant', 'Permissions', 'Deny')]
        [ValidateNotNullOrEmpty()]
        [System.Security.AccessControl.FileSystemRights]$Permission,

        [Parameter(Mandatory = $false, HelpMessage = 'Whether you want to set Allow or Deny permissions', ParameterSetName = 'DisableInheritance')]
        [Alias('AccessControlType')]
        [ValidateNotNullOrEmpty()]
        [System.Security.AccessControl.AccessControlType]$PermissionType = [System.Security.AccessControl.AccessControlType]::Allow,

        [Parameter(Mandatory = $false, HelpMessage = 'Sets how permissions are inherited', ParameterSetName = 'DisableInheritance')]
        [ValidateNotNullOrEmpty()]
        [System.Security.AccessControl.InheritanceFlags]$Inheritance = [System.Security.AccessControl.InheritanceFlags]::None,

        [Parameter(Mandatory = $false, HelpMessage = 'Sets how to propagate inheritance flags', ParameterSetName = 'DisableInheritance')]
        [ValidateNotNullOrEmpty()]
        [System.Security.AccessControl.PropagationFlags]$Propagation = [System.Security.AccessControl.PropagationFlags]::None,

        [Parameter(Mandatory = $false, HelpMessage = 'Specifies which method will be used to add/remove/replace permissions.', ParameterSetName = 'DisableInheritance')]
        [ValidateSet('AddAccessRule', 'SetAccessRule', 'ResetAccessRule', 'RemoveAccessRule', 'RemoveAccessRuleAll', 'RemoveAccessRuleSpecific')]
        [Alias('ApplyMethod', 'ApplicationMethod')]
        [System.String]$Method = 'AddAccessRule',

        [Parameter(Mandatory = $false, HelpMessage = 'Disables inheritance, preserving permissions before doing so.', ParameterSetName = 'DisableInheritance')]
        [System.Management.Automation.SwitchParameter]$DisableInheritance,

        [Parameter(Mandatory = $true, HelpMessage = 'Enables inheritance on the files/folders.', ParameterSetName = 'EnableInheritance')]
        [System.Management.Automation.SwitchParameter]$EnableInheritance,

        [Parameter(Mandatory = $false, HelpMessage = 'Removes non-inherited permissions from the object when enabling inheritance.', ParameterSetName = 'EnableInheritance')]
        [System.Management.Automation.SwitchParameter]$RemoveExplicitRules,

        [Parameter(Mandatory = $false, HelpMessage = 'The user or group to set as the owner of the item (ex: BUILTIN\Administrators). If you want to use a SID, prefix it with an asterisk * (ex: ''*S-1-5-18''). The owner is changed before any permissions are modified.', ParameterSetName = 'DisableInheritance')]
        [Parameter(Mandatory = $false, HelpMessage = 'The user or group to set as the owner of the item (ex: BUILTIN\Administrators). If you want to use a SID, prefix it with an asterisk * (ex: ''*S-1-5-18''). The owner is changed before any permissions are modified.', ParameterSetName = 'EnableInheritance')]
        [Parameter(Mandatory = $false, HelpMessage = 'The user or group to set as the owner of the item (ex: BUILTIN\Administrators). If you want to use a SID, prefix it with an asterisk * (ex: ''*S-1-5-18''). The owner is changed before any permissions are modified.', ParameterSetName = 'AccessControlList')]
        [Parameter(Mandatory = $true, HelpMessage = 'The user or group to set as the owner of the item (ex: BUILTIN\Administrators). If you want to use a SID, prefix it with an asterisk * (ex: ''*S-1-5-18'').', ParameterSetName = 'OwnerOnly')]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$Owner
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
