#-----------------------------------------------------------------------------
#
# MARK: Set-ADTIniSection
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: Linux implementation.
#
#-----------------------------------------------------------------------------
function Set-ADTIniSection
{
    <#
    .SYNOPSIS
        Opens an INI file and sets the values of the specified section.

    .DESCRIPTION
        The `Set-ADTIniSection` function opens an INI file and sets the values of the specified section.

        Please note that the INI file provided cannot have a byte order mark (BOM) present as the underlying Win32 API cannot process it correctly.

    .PARAMETER FilePath
        Path to the INI file.

    .PARAMETER Section
        Section within the INI file.

    .PARAMETER Content
        A hashtable or dictionary object containing the key-value pairs to set in the specified section.
        Supply an ordered hashtable to preserve the order of supplied entries. Values can be strings, numbers, booleans, enums, or null.
        Supply `$null` or an empty hashtable in combination with `-Overwrite` to empty an entire section.

    .PARAMETER Overwrite
        Specifies whether the provided INI content should overwrite all existing section content.

    .PARAMETER Force
        Specifies whether the INI file should be created if it does not already exist.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        None

        This function does not return any output.

    .EXAMPLE
        Set-ADTIniSection -FilePath "$env:ProgramFilesX86\IBM\Notes\notes.ini" -Section 'Notes' -Content ([ordered]@{'KeyFileName' = 'MyFile.ID'; 'KeyFileType' = 'ID'})

        Adds the provided content to the 'Notes' section, preserving input order

    .EXAMPLE
        Set-ADTIniSection -FilePath "$env:ProgramFilesX86\IBM\Notes\notes.ini" -Section 'Notes' -Content @{'KeyFileName' = 'MyFile.ID'} -Overwrite

        Overwrites the 'Notes' section to only contain the content specified.

    .EXAMPLE
        Set-ADTIniSection -FilePath "$env:ProgramFilesX86\IBM\Notes\notes.ini" -Section 'Notes' -Content $null -Overwrite

        Sets the 'Notes' section to be empty by sending null content in combination with the `-Overwrite` switch.

    .NOTES
        An active ADT session is NOT required to use this function.

        This function supports the `-WhatIf` and `-Confirm` parameters for testing changes before applying them.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Set-ADTIniSection

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Set-ADTIniSection.ps1
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$FilePath,

        [Parameter(Mandatory = $true)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$Section,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [System.Collections.IDictionary]$Content,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$Overwrite,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$Force
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
                $FilePath = Resolve-ADTIniFilePath -FilePath $FilePath -AllowMissing:$Force
                Write-ADTLogEntry -Message "$(if ($Overwrite) { 'Overwriting' } else { 'Writing' }) INI section: [FilePath = $FilePath] [Section = $Section]."
                if (!$PSCmdlet.ShouldProcess("$FilePath [$Section]", 'Set INI section'))
                {
                    return
                }
                $ini = Read-ADTIniFile -LiteralPath $FilePath
                if ($Overwrite -or !$ini.Contains($Section)) { $ini[$Section] = [ordered]@{} }
                foreach ($kvp in $Content.GetEnumerator())
                {
                    if ($null -eq $kvp.Value) { $ini[$Section].Remove([System.String]$kvp.Key) } else { $ini[$Section][[System.String]$kvp.Key] = [System.String]$kvp.Value }
                }
                Write-ADTIniFile -LiteralPath $FilePath -Ini $ini
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
