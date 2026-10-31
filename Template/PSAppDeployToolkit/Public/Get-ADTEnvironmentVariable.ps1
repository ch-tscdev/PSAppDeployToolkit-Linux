#-----------------------------------------------------------------------------
#
# MARK: Get-ADTEnvironmentVariable
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: Linux implementation.
#
#-----------------------------------------------------------------------------
function Get-ADTEnvironmentVariable
{
    <#
    .SYNOPSIS
        Gets the value of the specified environment variable.

    .DESCRIPTION
        The `Get-ADTEnvironmentVariable` function gets the value of the specified environment variable.

    .PARAMETER Variable
        The variable to get.

    .PARAMETER Target
        The target of the variable to get. This can be the machine, user, or process.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        System.String

        This function returns the value of the specified environment variable.

    .EXAMPLE
        Get-ADTEnvironmentVariable -Variable Path

        Returns the value of the Path environment variable.

    .EXAMPLE
        Get-ADTEnvironmentVariable -Variable Path -Target Machine

        Returns the value of the Path environment variable for the machine.

    .NOTES
        An active ADT session is NOT required to use this function.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Get-ADTEnvironmentVariable

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Get-ADTEnvironmentVariable.ps1
    #>

    [CmdletBinding()]
    [OutputType([System.String])]
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
                # Process: this process. Machine: /etc/environment. User: ~/.config/environment.d/90-psadt.conf of the active user.
                $target = if ($PSBoundParameters.ContainsKey('Target')) { $Target } else { [System.EnvironmentVariableTarget]::Process }
                Write-ADTLogEntry -Message "Getting $(if ($PSBoundParameters.ContainsKey('Target')) { "$Target " })environment variable [$Variable]."
                switch ($target)
                {
                    ([System.EnvironmentVariableTarget]::Process) { return [System.Environment]::GetEnvironmentVariable($Variable) }
                    ([System.EnvironmentVariableTarget]::Machine) { return (Read-ADTEnvironmentFile -LiteralPath '/etc/environment')[$Variable] }
                    ([System.EnvironmentVariableTarget]::User) { return (Read-ADTEnvironmentFile -LiteralPath (Get-ADTUserEnvironmentFile))[$Variable] }
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
