#-----------------------------------------------------------------------------
#
# MARK: Export-ADTEnvironmentTableToSessionState
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: Linux implementation.
#
#-----------------------------------------------------------------------------
function Export-ADTEnvironmentTableToSessionState
{
    <#
    .SYNOPSIS
        Exports the content of `Get-ADTEnvironmentTable` to the provided SessionState as variables.

    .DESCRIPTION
        The `Export-ADTEnvironmentTableToSessionState` function exports the content of `Get-ADTEnvironmentTable` to the provided SessionState as variables.

    .PARAMETER SessionState
        Defaults to `$PSCmdlet.SessionState` to get the caller's SessionState, so only required if you need to override this.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        None

        This function does not return any output.

    .EXAMPLE
        Export-ADTEnvironmentTableToSessionState -SessionState $ExecutionContext.SessionState

        Invokes the `Export-ADTEnvironmentTableToSessionState` function and exports the module's environment table to the provided SessionState.

    .EXAMPLE
        Export-ADTEnvironmentTableToSessionState -SessionState $PSCmdlet.SessionState

        Invokes the `Export-ADTEnvironmentTableToSessionState` function and exports the module's environment table to the provided SessionState.

    .NOTES
        An active ADT session is NOT required to use this function.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Export-ADTEnvironmentTableToSessionState

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Export-ADTEnvironmentTableToSessionState.ps1
    #>

    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.SessionState]$SessionState = $PSCmdlet.SessionState
    )

    begin
    {
        try
        {
            $adtEnv = Get-ADTEnvironmentTable
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError($_)
        }
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process
    {
        try
        {
            try
            {
                foreach ($kvp in $adtEnv.GetEnumerator())
                {
                    $SessionState.PSVariable.Set([System.Management.Automation.PSVariable]::new($kvp.Key, $kvp.Value, [System.Management.Automation.ScopedItemOptions]::ReadOnly))
                }
            }
            catch
            {
                Write-Error -ErrorRecord $_
            }
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
