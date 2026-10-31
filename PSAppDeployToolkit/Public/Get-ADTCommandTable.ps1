#-----------------------------------------------------------------------------
#
# MARK: Get-ADTCommandTable
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: Linux implementation.
#
#-----------------------------------------------------------------------------
function Get-ADTCommandTable
{
    <#
    .SYNOPSIS
        Returns PSAppDeployToolkit's safe command lookup table.

    .DESCRIPTION
        The `Get-ADTCommandTable` function returns PSAppDeployToolkit's safe command lookup table, which can be used for command lookups within extending modules.

        Please note that PSAppDeployToolkit's safe command table only has commands in it that are used within this module, and not necessarily all commands offered by PowerShell and its built-in modules out of the box.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        System.Collections.Generic.IReadOnlyDictionary[System.String, System.Management.Automation.CommandInfo]

        Returns PSAppDeployToolkit's safe command lookup table as a ReadOnlyDictionary.

    .EXAMPLE
        Get-ADTCommandTable

        Returns PSAppDeployToolkit's safe command lookup table.

    .NOTES
        An active ADT session is NOT required to use this function.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Get-ADTCommandTable

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Get-ADTCommandTable.ps1
    #>

    # Return a read-only copy of the module's command table (public functions plus the cmdlets it uses).
    $output = [System.Collections.Generic.Dictionary[System.String, System.Management.Automation.CommandInfo]]::new()
    foreach ($command in $Script:CommandTable.Values)
    {
        if (($command.CommandType -ne [System.Management.Automation.CommandTypes]::Function) -or ($command.Name -match '^\w+-ADT') -and (Test-Path -LiteralPath "$Script:PSScriptRoot/Public/$($command.Name).ps1"))
        {
            $output[$command.Name] = $command
        }
    }
    return [System.Collections.Generic.IReadOnlyDictionary[System.String, System.Management.Automation.CommandInfo]][System.Collections.ObjectModel.ReadOnlyDictionary[System.String, System.Management.Automation.CommandInfo]]::new($output)
}
