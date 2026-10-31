#-----------------------------------------------------------------------------
#
# MARK: Remove-ADTFont
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: Linux implementation.
#
#-----------------------------------------------------------------------------
function Remove-ADTFont
{
    <#
    .SYNOPSIS
        Removes a font from the system.

    .DESCRIPTION
        The `Remove-ADTFont` removes a font from the system by removing the font resource, deleting the registry entry, and removing the file from the Windows Fonts directory.

    .PARAMETER Name
        The name of the font file (e.g., 'arial.ttf') or the font name as it appears in the registry.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        None

        This function does not generate any output.

    .EXAMPLE
        Remove-ADTFont -Name 'MyFont.ttf'

        Removes the MyFont.ttf font.

    .NOTES
        An active ADT session is NOT required to use this function.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Remove-ADTFont

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Remove-ADTFont.ps1
    #>

    [CmdletBinding(SupportsShouldProcess = $false)]
    param
    (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [PSAppDeployToolkit.Attributes.ValidateUnique()]
        [System.String[]]$Name
    )

    begin
    {
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $fontsDir = if ([PSADT.AccountManagement.AccountUtilities]::CallerIsAdmin) { '/usr/local/share/fonts' } else { "$env:HOME/.local/share/fonts" }
        $removed = $false
    }

    process
    {
        foreach ($fontName in $Name)
        {
            try
            {
                try
                {
                    $fontPath = Join-Path -Path $fontsDir -ChildPath ([System.IO.Path]::GetFileName($fontName))
                    if (!(Test-Path -LiteralPath $fontPath -PathType Leaf))
                    {
                        Write-ADTLogEntry -Message "Font [$fontName] is not installed in [$fontsDir]." -Severity Warning
                        continue
                    }
                    Write-ADTLogEntry -Message "Removing font [$fontName]..."
                    Remove-Item -LiteralPath $fontPath -Force
                    $removed = $true
                    Write-ADTLogEntry -Message "Successfully removed font [$fontName]."
                }
                catch
                {
                    Write-Error -ErrorRecord $_
                }
            }
            catch
            {
                Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_ -LogMessage "Failed to remove font [$fontName]."
            }
        }
    }

    end
    {
        if ($removed -and (Get-Command -Name fc-cache -CommandType Application -ErrorAction Ignore))
        {
            $null = Invoke-ADTNativeCommand -FilePath fc-cache -ArgumentList '-f', $fontsDir
        }
        Complete-ADTFunction -Cmdlet $PSCmdlet
    }
}
