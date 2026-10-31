#-----------------------------------------------------------------------------
#
# MARK: Remove-ADTIniValue
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: Linux implementation.
#
#-----------------------------------------------------------------------------
function Remove-ADTIniValue
{
    <#
    .SYNOPSIS
        Opens an INI file and removes the specified key or section.

    .DESCRIPTION
        The `Remove-ADTIniValue` function opens an INI file and removes the specified key or section.

        Please note that the INI file provided cannot have a byte order mark (BOM) present as the underlying Win32 API cannot process it correctly.

    .PARAMETER FilePath
        Path to the INI file.

    .PARAMETER Section
        Section within the INI file.

    .PARAMETER Key
        Key within the section of the INI file.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        None

        This function does not return any output.

    .EXAMPLE
        Remove-ADTIniValue -FilePath "$env:ProgramFilesX86\IBM\Notes\notes.ini" -Section 'Notes' -Key 'KeyFileName'

        Removes the 'KeyFileName' key from the 'Notes' section of the 'notes.ini' file.

    .EXAMPLE
        Remove-ADTIniValue -FilePath "$env:ProgramFilesX86\IBM\Notes\notes.ini" -Section 'Notes'

        Removes the entire 'Notes' section of the 'notes.ini' file.

    .NOTES
        An active ADT session is NOT required to use this function.

        This function supports the `-WhatIf` and `-Confirm` parameters for testing changes before applying them.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Remove-ADTIniValue

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Remove-ADTIniValue.ps1
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

        [Parameter(Mandatory = $false)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$Key
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
                $ini = Read-ADTIniFile -LiteralPath $FilePath
                if (!$ini.Contains($Section))
                {
                    Write-ADTLogEntry -Message "INI section [$Section] does not exist in [$FilePath]."
                    return
                }
                if ($PSBoundParameters.ContainsKey('Key'))
                {
                    Write-ADTLogEntry -Message "Removing INI Key: [Section = $Section] [Key = $Key]."
                    $ini[$Section].Remove($Key)
                }
                else
                {
                    Write-ADTLogEntry -Message "Removing all keys from INI section [$Section]."
                    $ini[$Section].Clear()
                }
                if ($PSCmdlet.ShouldProcess("$FilePath [$Section]", 'Remove INI value'))
                {
                    Write-ADTIniFile -LiteralPath $FilePath -Ini $ini
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
