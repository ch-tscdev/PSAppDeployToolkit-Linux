#-----------------------------------------------------------------------------
#
# MARK: Get-ADTStringTable
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: Linux implementation.
#
#-----------------------------------------------------------------------------
function Get-ADTStringTable
{
    <#
    .SYNOPSIS
        Gets the string database from the PSAppDeployToolkit module.

    .DESCRIPTION
        The `Get-ADTStringTable` function gets the module's string database, if it has been initialized. If the string database is not initialized, it throws an error indicating that `Initialize-ADTModule` should be called before using this function.

    .PARAMETER SessionState
        The SessionState in which to expand variables from if specified.

    .INPUTS
        None

        This function does not take any pipeline input.

    .OUTPUTS
        System.Collections.Hashtable

        Returns a hashtable containing the string database.

    .EXAMPLE
        Get-ADTStringTable

        This example retrieves the string database from the PSAppDeployToolkit module.

    .NOTES
        An active ADT session is NOT required to use this function.

        Requires: The module should be initialized using `Initialize-ADTModule`

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Get-ADTStringTable

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Get-ADTStringTable.ps1
    #>

    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.SessionState]$SessionState
    )

    $stringTable = try
    {
        (Get-ADTModuleState).Strings
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
    if ($PSBoundParameters.ContainsKey('SessionState'))
    {
        # Deep-clone the table, then expand any variables within the caller's session state.
        $clone = { param($t) $c = @{}; foreach ($k in $t.Keys) { $c[$k] = if ($t[$k] -is [System.Collections.Hashtable]) { & $clone $t[$k] } else { $t[$k] } }; $c }
        $stringTable = & $clone $stringTable
        Expand-ADTVariablesInHashtable -Hashtable $stringTable -SessionState $SessionState
    }
    return $stringTable
}
