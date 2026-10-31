#-----------------------------------------------------------------------------
#
# MARK: Set-ADTEnvironmentVariable
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: Linux implementation.
#
#-----------------------------------------------------------------------------
function Set-ADTEnvironmentVariable
{
    <#
    .SYNOPSIS
        Sets the value for the specified environment variable.

    .DESCRIPTION
        The `Set-ADTEnvironmentVariable` function sets the value for the specified environment variable.

    .PARAMETER Variable
        The variable to set.

    .PARAMETER Value
        The value to set to variable to.

    .PARAMETER Target
        The target of the variable to set. This can be the machine, user, or process.

    .PARAMETER Append
        Specifies the value should be appended to an existing value if present.

    .PARAMETER Remove
        Specifies the value should be removed from an existing value if present.

    .PARAMETER Expandable
        Indicates that the environment variable should be written to the registry using a REG_EXPAND_SZ type to support environment variables.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        None

        This function does not return any output.

    .EXAMPLE
        Set-ADTEnvironmentVariable -Variable Path -Value C:\Windows

        Sets the value of the Path environment variable to C:\Windows.

    .EXAMPLE
        Set-ADTEnvironmentVariable -Variable Path -Value C:\Windows -Target Machine

        Sets the value of the Path environment variable to C:\Windows for the machine.

    .NOTES
        An active ADT session is NOT required to use this function.

        This function supports the `-WhatIf` and `-Confirm` parameters for testing changes before applying them.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Set-ADTEnvironmentVariable

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Set-ADTEnvironmentVariable.ps1
    #>

    [CmdletBinding(DefaultParameterSetName = 'None', SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$Variable,

        [Parameter(Mandatory = $true)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$Value,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.EnvironmentVariableTarget]$Target,

        [Parameter(Mandatory = $true, ParameterSetName = 'Append')]
        [System.Management.Automation.SwitchParameter]$Append,

        [Parameter(Mandatory = $true, ParameterSetName = 'Remove')]
        [System.Management.Automation.SwitchParameter]$Remove,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$Expandable
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
                if ($Expandable)
                {
                    Write-ADTLogEntry -Message 'The parameter [-Expandable] (REG_EXPAND_SZ) has no Linux equivalent; the value is stored as-is.'
                }
                $current = switch ($target)
                {
                    ([System.EnvironmentVariableTarget]::Process) { [System.Environment]::GetEnvironmentVariable($Variable) }
                    ([System.EnvironmentVariableTarget]::Machine) { (Read-ADTEnvironmentFile -LiteralPath '/etc/environment')[$Variable] }
                    ([System.EnvironmentVariableTarget]::User) { (Read-ADTEnvironmentFile -LiteralPath (Get-ADTUserEnvironmentFile))[$Variable] }
                }
                # Append/Remove treat the value as a list using the platform path separator (':').
                $newValue = if ($Append -or $Remove)
                {
                    $items = [System.Collections.Generic.List[System.String]]@(([System.String]$current).Split([System.IO.Path]::PathSeparator, [System.StringSplitOptions]::RemoveEmptyEntries))
                    foreach ($item in $Value.Split([System.IO.Path]::PathSeparator, [System.StringSplitOptions]::RemoveEmptyEntries))
                    {
                        if ($Append -and !$items.Contains($item)) { $items.Add($item) }
                        if ($Remove) { $null = $items.Remove($item) }
                    }
                    $items -join [System.IO.Path]::PathSeparator
                }
                else
                {
                    $Value
                }
                Write-ADTLogEntry -Message "Setting $(if ($PSBoundParameters.ContainsKey('Target')) { "$Target " })environment variable [$Variable] to [$newValue]."
                switch ($target)
                {
                    ([System.EnvironmentVariableTarget]::Process) { [System.Environment]::SetEnvironmentVariable($Variable, $newValue) }
                    ([System.EnvironmentVariableTarget]::Machine) { Write-ADTEnvironmentFile -LiteralPath '/etc/environment' -Variable $Variable -Value $newValue }
                    ([System.EnvironmentVariableTarget]::User) { Write-ADTEnvironmentFile -LiteralPath (Get-ADTUserEnvironmentFile) -Variable $Variable -Value $newValue }
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
