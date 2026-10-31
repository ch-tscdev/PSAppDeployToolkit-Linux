#-----------------------------------------------------------------------------
#
# MARK: Update-ADTEnvironmentPsProvider
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: Linux implementation.
#
#-----------------------------------------------------------------------------
function Update-ADTEnvironmentPsProvider
{
    <#
    .SYNOPSIS
        Updates the environment variables for the current PowerShell session with any environment variable changes that may have occurred during script execution.

    .DESCRIPTION
        Environment variable changes that take place during script execution are not visible to the current PowerShell session.

        Use this function to refresh the current PowerShell session with all environment variable settings.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        None

        This function does not return any objects.

    .EXAMPLE
        Update-ADTEnvironmentPsProvider

        Refreshes the current PowerShell session with all environment variable settings.

    .NOTES
        An active ADT session is NOT required to use this function.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Update-ADTEnvironmentPsProvider

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Update-ADTEnvironmentPsProvider.ps1
    #>

    [CmdletBinding()]
    param
    (
    )

    begin
    {
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process
    {
        try
        {
            try
            {
                # Refresh this process's environment from /etc/environment (system-wide variables set by Set-ADTEnvironmentVariable -Target Machine).
                Write-ADTLogEntry -Message 'Refreshing the environment variables for this PowerShell session.'
                foreach ($kvp in (Read-ADTEnvironmentFile -LiteralPath '/etc/environment').GetEnumerator())
                {
                    if ($kvp.Key -eq 'PATH')
                    {
                        $merged = @(($kvp.Value -split ':') + ($env:PATH -split ':')) | & { process { if ($_) { $_ } } } | Select-Object -Unique
                        [System.Environment]::SetEnvironmentVariable('PATH', ($merged -join ':'))
                        continue
                    }
                    [System.Environment]::SetEnvironmentVariable($kvp.Key, $kvp.Value)
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
