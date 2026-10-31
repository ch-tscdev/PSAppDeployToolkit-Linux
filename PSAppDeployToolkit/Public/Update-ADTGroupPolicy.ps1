#-----------------------------------------------------------------------------
#
# MARK: Update-ADTGroupPolicy
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: not supported on Linux (throws PlatformNotSupportedException).
#
#-----------------------------------------------------------------------------
function Update-ADTGroupPolicy
{
    <#
    .SYNOPSIS
        Performs a gpupdate command to refresh Group Policies on the local machine.

    .DESCRIPTION
        The `Update-ADTGroupPolicy` function performs a gpupdate command to refresh Group Policies on the local machine.

    .PARAMETER Target
        Specifies that only User or only Computer policy settings are updated. By default, both User and Computer policy settings are updated.

    .PARAMETER Force
        Reapplies all policy settings. By default, only policy settings that have changed are applied.

    .PARAMETER NoWait
        Starts the underlying gpupdate.exe call without waiting for it to finish.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        None

        This function does not return any objects.

    .EXAMPLE
        Update-ADTGroupPolicy

        Performs a gpupdate command to refresh Group Policies on the local machine.

    .NOTES
        An active ADT session is NOT required to use this function.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Update-ADTGroupPolicy

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Update-ADTGroupPolicy.ps1
    #>

    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $false)]
        [ValidateSet('Computer', 'User')]
        [PSAppDeployToolkit.Attributes.ValidateUnique()]
        [System.String[]]$Target = ('Computer', 'User'),

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.SwitchParameter]$Force,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.SwitchParameter]$NoWait
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
