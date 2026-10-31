#-----------------------------------------------------------------------------
#
# MARK: Get-ADTIniSection
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: Linux implementation.
#
#-----------------------------------------------------------------------------
function Get-ADTIniSection
{
    <#
    .SYNOPSIS
        Parses an INI file and returns the specified section as an ordered hashtable of key value pairs.

    .DESCRIPTION
        The `Get-ADTIniSection` function parses an INI file and returns the specified section as an ordered hashtable of key value pairs.

        Please note that the INI file provided cannot have a byte order mark (BOM) present as the underlying Win32 API cannot process it correctly.

    .PARAMETER FilePath
        Path to the INI file.

    .PARAMETER Section
        Section within the INI file.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        Collections.Specialized.OrderedDictionary

        Returns the specified section as an ordered dictionary of key-value pairs.

    .EXAMPLE
        Get-ADTIniSection -FilePath "$env:ProgramFilesX86\IBM\Notes\notes.ini" -Section 'Notes'

        This example retrieves the 'Notes' section from the specified INI file.

    .NOTES
        An active ADT session is NOT required to use this function.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Get-ADTIniSection

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Get-ADTIniSection.ps1
    #>

    [CmdletBinding()]
    [OutputType([Collections.Specialized.OrderedDictionary])]
    param
    (
        [Parameter(Mandatory = $true)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$FilePath,

        [Parameter(Mandatory = $true)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$Section
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
                $FilePath = Resolve-ADTIniFilePath -FilePath $FilePath
                Write-ADTLogEntry -Message "Reading INI section: [FilePath = $FilePath] [Section = $Section]."
                $ini = Read-ADTIniFile -LiteralPath $FilePath
                if (!$ini.Contains($Section))
                {
                    Write-ADTLogEntry -Message "INI section [$Section] does not exist in [$FilePath]."
                    return
                }
                $content = [ordered]@{}
                foreach ($kvp in $ini[$Section].GetEnumerator()) { $content[$kvp.Key] = $kvp.Value }
                return $content
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
