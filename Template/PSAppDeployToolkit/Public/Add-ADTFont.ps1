#-----------------------------------------------------------------------------
#
# MARK: Add-ADTFont
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: Linux implementation.
#
#-----------------------------------------------------------------------------
function Add-ADTFont
{
    <#
    .SYNOPSIS
        Installs font files to the system.

    .DESCRIPTION
        The `Add-ADTFont` function installs font files to the system by copying them to the Windows Fonts directory, registering them with the system, and creating the appropriate registry entry(s).

        Supports .ttf, .ttc, and .otf file types.

    .PARAMETER Path
        The path to the font file or directory containing font files.

    .PARAMETER Recurse
        Recursively search for font files in subdirectories.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        None

        This function does not generate any output.

    .EXAMPLE
        Add-ADTFont -Path "$($adtSession.DirFiles)\MyFont.ttf"

        Installs the MyFont.ttf font file.

    .EXAMPLE
        Add-ADTFont -Path "$($adtSession.DirFiles)\Fonts" -Recurse

        Installs all font files in the Fonts directory and its subdirectories.

    .NOTES
        An active ADT session is NOT required to use this function.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Add-ADTFont

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Add-ADTFont.ps1
    #>

    [CmdletBinding(SupportsShouldProcess = $false)]
    param
    (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [PSAppDeployToolkit.Attributes.ValidateUnique()]
        [SupportsWildcards()]
        [System.String[]]$Path,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$Recurse
    )

    begin
    {
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        # System-wide fonts go to /usr/local/share/fonts (root), per-user fonts to ~/.local/share/fonts.
        $fontsDir = if ([PSADT.AccountManagement.AccountUtilities]::CallerIsAdmin) { '/usr/local/share/fonts' } else { "$env:HOME/.local/share/fonts" }
        $fontTypes = @('.ttf', '.ttc', '.otf', '.otc', '.pfb', '.pfa', '.pcf', '.woff', '.woff2')
        $installed = $false
    }

    process
    {
        foreach ($item in $Path)
        {
            try
            {
                try
                {
                    foreach ($resolvedPath in (Resolve-Path -Path ($item -replace '\\', '/')))
                    {
                        $files = if (Test-Path -LiteralPath $resolvedPath -PathType Container)
                        {
                            Get-ChildItem -LiteralPath $resolvedPath -File -Recurse:$Recurse | & { process { if ($fontTypes -contains $_.Extension.ToLowerInvariant()) { $_ } } }
                        }
                        else
                        {
                            Get-Item -LiteralPath $resolvedPath -Force
                        }
                        foreach ($fileItem in $files)
                        {
                            if ($fontTypes -notcontains $fileItem.Extension.ToLowerInvariant())
                            {
                                $naerParams = @{
                                    Exception = [System.ArgumentException]::new("File [$($fileItem.Name)] is not a supported font type.")
                                    Category = [System.Management.Automation.ErrorCategory]::InvalidArgument
                                    ErrorId = 'FontFileUnsupportedExtensionError'
                                    TargetObject = $fileItem
                                    RecommendedAction = "Please confirm the supplied value is correct and try again."
                                }
                                throw (New-ADTErrorRecord @naerParams)
                            }
                            Write-ADTLogEntry -Message "Installing font [$($fileItem.Name)]..."
                            $null = New-Item -Path $fontsDir -ItemType Directory -Force
                            Copy-Item -LiteralPath $fileItem.FullName -Destination (Join-Path $fontsDir $fileItem.Name) -Force
                            $installed = $true
                            Write-ADTLogEntry -Message "Successfully installed font [$($fileItem.Name)] to [$fontsDir]."
                        }
                    }
                }
                catch
                {
                    Write-Error -ErrorRecord $_
                }
            }
            catch
            {
                Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_ -LogMessage "Failed to install font(s) from [$item]."
            }
        }
    }

    end
    {
        if ($installed -and (Get-Command -Name fc-cache -CommandType Application -ErrorAction Ignore))
        {
            Write-ADTLogEntry -Message 'Refreshing the font cache (fc-cache).'
            $null = Invoke-ADTNativeCommand -FilePath fc-cache -ArgumentList '-f', $fontsDir
        }
        Complete-ADTFunction -Cmdlet $PSCmdlet
    }
}
