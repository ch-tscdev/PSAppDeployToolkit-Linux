#-----------------------------------------------------------------------------
#
# MARK: Remove-ADTEnvironmentVariable
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: Linux implementation.
#
#-----------------------------------------------------------------------------
function Remove-ADTEnvironmentVariable
{
    <#
    .SYNOPSIS
        Removes the specified environment variable.

    .DESCRIPTION
        The `Remove-ADTEnvironmentVariable` function removes the specified environment variable.

    .PARAMETER Variable
        The variable to remove.

    .PARAMETER Target
        The target of the variable to remove. This can be the machine, user, or process.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        None

        This function does not return any output.

    .EXAMPLE
        Remove-ADTEnvironmentVariable -Variable Path

        Removes the Path environment variable.

    .EXAMPLE
        Remove-ADTEnvironmentVariable -Variable Path -Target Machine

        Removes the Path environment variable for the machine.

    .NOTES
        An active ADT session is NOT required to use this function.

        This function supports the `-WhatIf` and `-Confirm` parameters for testing changes before applying them.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Remove-ADTEnvironmentVariable

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Remove-ADTEnvironmentVariable.ps1
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$Variable,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.EnvironmentVariableTarget]$Target
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
                $target = if ($PSBoundParameters.ContainsKey('Target')) { $Target } else { [System.EnvironmentVariableTarget]::Process }
                Write-ADTLogEntry -Message "Removing $(if ($PSBoundParameters.ContainsKey('Target')) { "$Target " })environment variable [$Variable]."
                switch ($target)
                {
                    ([System.EnvironmentVariableTarget]::Process) { [System.Environment]::SetEnvironmentVariable($Variable, $null) }
                    ([System.EnvironmentVariableTarget]::Machine) { Write-ADTEnvironmentFile -LiteralPath '/etc/environment' -Variable $Variable -Value $null }
                    ([System.EnvironmentVariableTarget]::User) { Write-ADTEnvironmentFile -LiteralPath (Get-ADTUserEnvironmentFile) -Variable $Variable -Value $null }
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
