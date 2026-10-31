#-----------------------------------------------------------------------------
#
# MARK: New-ADTTemplate
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: Linux implementation.
#
#-----------------------------------------------------------------------------
function New-ADTTemplate
{
    <#
    .SYNOPSIS
        Creates a new folder containing a template front end and module folder, ready to customise.

    .DESCRIPTION
        Specify a destination path where a new folder will be created. You also have the option of creating a template for v3 compatibility mode.

    .PARAMETER Destination
        Path where the new folder should be created. Default is the current working directory.

    .PARAMETER Name
        Name of the newly created folder. Default is PSAppDeployToolkit_Version.

    .PARAMETER Version
        Defaults to 4 for the standard v4 template. Use 3 for the v3 compatibility mode template.

    .PARAMETER LauncherName
        The base name to use for the generated launcher files, without a file extension.

    .PARAMETER ExcludeContent
        Specifies one or more optional content categories to omit from the generated template. Valid values are Assets, Config, Extensions, Files, Module, Strings and SupportFiles. All content is included by default. You cannot exclude Files, SupportFiles, Config or Strings if specifying those items as separate parameters. You can exclude Assets while specifying -Assets to omit the default assets. Excluding Module omits the bundled PSAppDeployToolkit module for deployments that provide it externally.

    .PARAMETER SessionProperties
        A dictionary of key-value pairs to inject into the $adtSession hashtable of the generated Invoke-AppDeployToolkit.ps1. Accepts [hashtable], [ordered], or any [System.Collections.IDictionary] type. Only supported when -Version is 4.

    .PARAMETER Config
        A dictionary of key-value pairs to override or add to the generated Config\config.psd1. The dictionary structure must mirror the config file's nested hashtable layout (e.g. @\{ MSI = @\{ InstallParams = 'REBOOT=ReallySuppress /QB-!' \} \}). Existing keys are overridden in place. New keys or sections that do not exist in the default config are appended at the end of the relevant hashtable level.

    .PARAMETER Strings
        A dictionary of language codes to key-value pairs to override or add to the generated strings.psd1 files. Each top-level key must be a language code (e.g. en, fr, pt-BR), where en targets Strings\strings.psd1 and every other language targets Strings\<language>\strings.psd1. A language that the module does not ship is created from a copy of the English string table with the supplied values applied on top. The value for each language must mirror the string table's nested hashtable layout (e.g. @\{ en = @\{ BalloonTip = @\{ Start = @\{ Install = 'Install has started.' \} \} \} \}). Language codes and keys are matched case-insensitively; specifying the same language or key more than once with differing case is an error. Existing keys are overridden in place. New keys that do not exist in the default string table are appended at the end of the relevant hashtable level.

    .PARAMETER PreInstallScriptBlock
        A ScriptBlock whose content will replace the Pre-Install phase of the Install-ADTDeployment function in the generated Invoke-AppDeployToolkit.ps1. Only supported when -Version is 4.

    .PARAMETER InstallScriptBlock
        A ScriptBlock whose content will replace the Install phase of the Install-ADTDeployment function in the generated Invoke-AppDeployToolkit.ps1. Only supported when -Version is 4.

    .PARAMETER PostInstallScriptBlock
        A ScriptBlock whose content will replace the Post-Install phase of the Install-ADTDeployment function in the generated Invoke-AppDeployToolkit.ps1. Only supported when -Version is 4.

    .PARAMETER PreUninstallScriptBlock
        A ScriptBlock whose content will replace the Pre-Uninstall phase of the Uninstall-ADTDeployment function in the generated Invoke-AppDeployToolkit.ps1. Only supported when -Version is 4.

    .PARAMETER UninstallScriptBlock
        A ScriptBlock whose content will replace the Uninstall phase of the Uninstall-ADTDeployment function in the generated Invoke-AppDeployToolkit.ps1. Only supported when -Version is 4.

    .PARAMETER PostUninstallScriptBlock
        A ScriptBlock whose content will replace the Post-Uninstall phase of the Uninstall-ADTDeployment function in the generated Invoke-AppDeployToolkit.ps1. Only supported when -Version is 4.

    .PARAMETER PreRepairScriptBlock
        A ScriptBlock whose content will replace the Pre-Repair phase of the Repair-ADTDeployment function in the generated Invoke-AppDeployToolkit.ps1. Only supported when -Version is 4.

    .PARAMETER RepairScriptBlock
        A ScriptBlock whose content will replace the Repair phase of the Repair-ADTDeployment function in the generated Invoke-AppDeployToolkit.ps1. Only supported when -Version is 4.

    .PARAMETER PostRepairScriptBlock
        A ScriptBlock whose content will replace the Post-Repair phase of the Repair-ADTDeployment function in the generated Invoke-AppDeployToolkit.ps1. Only supported when -Version is 4.

    .PARAMETER Assets
        An array of file or folder paths to copy into the Assets folder of the generated template. Paths are passed to Copy-Item with -Recurse. Custom assets are copied even when Assets is specified in -ExcludeContent, allowing the default assets to be replaced entirely.

    .PARAMETER Files
        An array of file or folder paths to copy into the Files folder of the generated template. Paths are passed to Copy-Item with -Recurse.

    .PARAMETER SupportFiles
        An array of file or folder paths to copy into the SupportFiles folder of the generated template. Paths are passed to Copy-Item with -Recurse.

    .PARAMETER Show
        Opens the newly created folder in Windows Explorer.

    .PARAMETER Force
        If the destination folder already exists, this switch will force the creation of the new folder.

    .PARAMETER PassThru
        Returns the newly created folder object.

    .PARAMETER ZeroConfig
        When specified, injects a default MSI scriptblock into the Install, Uninstall, and Repair phases that executes the detected default MSI. If InstallScriptBlock, UninstallScriptBlock, or RepairScriptBlock are also provided, the zero-config content is prepended to the user-supplied scriptblock. Only supported when -Version is 4.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        None

        By default, this function returns no output.

    .OUTPUTS
        System.IO.DirectoryInfo

        When the `-PassThru` parameter is specified, this function returns a DirectoryInfo object representing the directory containing the new PSADT template.

    .EXAMPLE
        New-ADTTemplate -Destination 'C:\Temp' -Name 'PSAppDeployToolkitv4'

        Creates a new v4 template named PSAppDeployToolkitv4 under C:\Temp.

    .EXAMPLE
        New-ADTTemplate -Destination 'C:\Temp' -Name 'PSAppDeployToolkitv3' -Version 3

        Creates a new v3 compatibility mode template named PSAppDeployToolkitv3 under C:\Temp.

    .EXAMPLE
        New-ADTTemplate -Destination 'C:\Temp' -LauncherName 'Deploy-ContosoApp'

        Creates a new v4 template whose launcher files are named Deploy-ContosoApp.exe and Deploy-ContosoApp.ps1.

    .EXAMPLE
        New-ADTTemplate -Destination 'C:\Temp' -ExcludeContent Extensions, Strings, SupportFiles

        Creates a new v4 template without the PSAppDeployToolkit.Extensions, Strings, or SupportFiles folders.

    .EXAMPLE
        New-ADTTemplate -Destination 'C:\Temp' -SessionProperties @{ AppVendor = 'Contoso'; AppName = 'MyApp'; AppVersion = '6.7'; RequireAdmin = $false; AppProcessesToClose = @('notepad', @{ Name = 'calc'; Description = 'Calculator' }) }

        Creates a new v4 template with the specified session properties pre-populated in the $adtSession hashtable.

    .EXAMPLE
        New-ADTTemplate -Destination 'C:\Temp' -Config @{ Toolkit = @{ LogPath = '$env:ProgramData\Microsoft\IntuneManagementExtension\Logs' } }

        Creates a new v4 template with a custom log folder.

    .EXAMPLE
        New-ADTTemplate -Destination 'C:\Temp' -Assets 'C:\Assets\AppIconLight.png', 'C:\Assets\AppIconDark.png' -Config @{ Assets = @{ Logo = '..\Assets\AppIconLight.png'; LogoDark = '..\Assets\AppIconDark.png' } }

        Creates a new v4 template with custom icons copied to Assets, with config.psd1 updated and configured to use them.

    .EXAMPLE
        New-ADTTemplate -Destination 'C:\Temp' -Strings @{ en = @{ BalloonTip = @{ Start = @{ Install = 'Contoso App installation started.' } } }; fr = @{ BalloonTip = @{ Start = @{ Install = 'Contoso App : installation en cours.' } } } }

        Creates a new v4 template with the English and French balloon tip text for the start of an installation overridden.

    .EXAMPLE
        New-ADTTemplate -Destination 'C:\Temp' -SessionProperties @{ AppVendor = 'Contoso'; AppName = 'MyApp'; AppVersion = '6.7' } -Files 'C:\Installers\Setup.msi' -InstallScriptBlock { Start-ADTMsiProcess -Action Install -FilePath 'Setup.msi' } -UninstallScriptBlock { Start-ADTMsiProcess -Action Uninstall -FilePath 'Setup.msi' }

        Creates a new v4 template with session properties defined, an MSI copied to Files and install/uninstall commands added.

    .NOTES
        An active ADT session is NOT required to use this function.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/New-ADTTemplate

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/New-ADTTemplate.ps1
    #>

    [CmdletBinding(SupportsShouldProcess = $false)]
    [OutputType([System.IO.DirectoryInfo])]
    param
    (
        [Parameter(Mandatory = $false)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$Destination = $ExecutionContext.SessionState.Path.CurrentLocation.Path,

        [Parameter(Mandatory = $false)]
        [ValidateScript({
                if ($_.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -ge 0)
                {
                    $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName Name -ProvidedValue $_ -ExceptionMessage 'The specified template folder name contains invalid file name characters.'))
                }
                if ($_ -in '.', '..')
                {
                    $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName Name -ProvidedValue $_ -ExceptionMessage 'The specified template folder name is a relative directory alias.'))
                }
                return $true
            })]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [PSDefaultValue(Help = "PSAppDeployToolkit_<ModuleVersion>")]
        [System.String]$Name = "$($MyInvocation.MyCommand.Module.Name)_$($MyInvocation.MyCommand.Module.Version)",

        [Parameter(Mandatory = $false)]
        [ValidateRange(3, 4)]
        [System.Int32]$Version = 4,

        [Parameter(Mandatory = $false)]
        [ValidateScript({
                if ($_.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -ge 0)
                {
                    $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName LauncherName -ProvidedValue $_ -ExceptionMessage 'The specified launcher base name contains invalid file name characters.'))
                }
                if ($_ -match '\.(?:exe|ps1|pdb)$')
                {
                    $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName LauncherName -ProvidedValue $_ -ExceptionMessage "The specified launcher base name should not contain a file extension."))
                }
                return $true
            })]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$LauncherName,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Assets', 'Config', 'Extensions', 'Files', 'Module', 'Strings', 'SupportFiles')]
        [PSAppDeployToolkit.Attributes.ValidateUnique()]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String[]]$ExcludeContent = @(),

        [Parameter(Mandatory = $false)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.Collections.IDictionary]$SessionProperties,

        [Parameter(Mandatory = $false)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.Collections.IDictionary]$Config,

        [Parameter(Mandatory = $false)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.Collections.IDictionary]$Strings,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.ScriptBlock]$PreInstallScriptBlock,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.ScriptBlock]$InstallScriptBlock,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.ScriptBlock]$PostInstallScriptBlock,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.ScriptBlock]$PreUninstallScriptBlock,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.ScriptBlock]$UninstallScriptBlock,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.ScriptBlock]$PostUninstallScriptBlock,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.ScriptBlock]$PreRepairScriptBlock,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.ScriptBlock]$RepairScriptBlock,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.ScriptBlock]$PostRepairScriptBlock,

        [Parameter(Mandatory = $false)]
        [SupportsWildcards()]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String[]]$Assets,

        [Parameter(Mandatory = $false)]
        [SupportsWildcards()]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String[]]$Files,

        [Parameter(Mandatory = $false)]
        [SupportsWildcards()]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String[]]$SupportFiles,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$Show,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$ZeroConfig,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$Force,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$PassThru
    )

    begin
    {
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $Destination = $PSCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Destination)
        $templatePath = Join-Path -Path $Destination -ChildPath $Name
        $moduleDir = Get-ADTModuleDirectory
        $frontendDir = Join-Path -Path $moduleDir -ChildPath "opt/Frontend/v4"

        # Returns the text of a script block's body without its outer braces, re-indented for the template.
        function Get-ADTScriptBlockBody
        {
            param ([System.Management.Automation.ScriptBlock]$ScriptBlock)
            $text = $ScriptBlock.Ast.Extent.Text
            if ($text.StartsWith('{')) { $text = $text.Substring(1, $text.Length - 2) }
            $lines = $text.Trim("`r", "`n").Split("`n") | & { process { $_.TrimEnd("`r") } }
            $indent = ($lines | & { process { if ($_.Trim()) { $_.Length - $_.TrimStart().Length } } } | Measure-Object -Minimum).Minimum
            return [System.String]::Join("`n", ($lines | & { process { '    ' + $(if ($_.Length -ge $indent) { $_.Substring($indent) } else { $_.TrimStart() }) } }))
        }

        # Converts a value into PowerShell source text for the generated script/data files.
        function ConvertTo-ADTSourceText
        {
            param ($Value, [System.Int32]$Depth = 0)
            $pad = '    ' * ($Depth + 1)
            if ($null -eq $Value) { return '$null' }
            if ($Value -is [System.Boolean] -or $Value -is [System.Management.Automation.SwitchParameter]) { return "`$$(([System.Boolean]$Value).ToString().ToLowerInvariant())" }
            if ($Value -is [System.Int32] -or $Value -is [System.Int64] -or $Value -is [System.Double] -or $Value -is [System.UInt32]) { return [System.String]$Value }
            if ($Value -is [System.Management.Automation.ScriptBlock]) { return "{$($Value.ToString())}" }
            if ($Value -is [System.Collections.IDictionary])
            {
                $entries = foreach ($kvp in $Value.GetEnumerator()) { "$pad$($kvp.Key) = $(ConvertTo-ADTSourceText -Value $kvp.Value -Depth ($Depth + 1))" }
                return "@{`n$([System.String]::Join("`n", $entries))`n$('    ' * $Depth)}"
            }
            if (($Value -is [System.Collections.IEnumerable]) -and ($Value -isnot [System.String]))
            {
                return "@($([System.String]::Join(', ', ($Value | & { process { ConvertTo-ADTSourceText -Value $_ -Depth $Depth } }))))"
            }
            return "'$(([System.String]$Value).Replace("'", "''"))'"
        }
    }

    process
    {
        try
        {
            try
            {
                if ($Version -eq 3)
                {
                    $naerParams = @{
                        Exception = [System.NotSupportedException]::new("The v3 compatibility template is not supported by the Linux port of PSAppDeployToolkit.")
                        Category = [System.Management.Automation.ErrorCategory]::InvalidArgument
                        ErrorId = 'V3TemplateNotSupported'
                        TargetObject = $Version
                        RecommendedAction = 'Please use the default v4 template.'
                    }
                    throw (New-ADTErrorRecord @naerParams)
                }
                foreach ($winOnly in 'LauncherName', 'ZeroConfig', 'Show')
                {
                    if ($PSBoundParameters.ContainsKey($winOnly))
                    {
                        Write-ADTLogEntry -Message "The parameter [-$winOnly] is not applicable on Linux and has been ignored."
                    }
                }

                # Prepare the destination.
                if (Test-Path -LiteralPath $templatePath)
                {
                    if (!$Force)
                    {
                        $naerParams = @{
                            Exception = [System.IO.IOException]::new("Folders [$templatePath] already exists. Please use the -Force parameter to overwrite.")
                            Category = [System.Management.Automation.ErrorCategory]::InvalidOperation
                            ErrorId = 'NonEmptyTemplatePath'
                            TargetObject = $templatePath
                            RecommendedAction = "Please use the -Force parameter to overwrite."
                        }
                        throw (New-ADTErrorRecord @naerParams)
                    }
                    Write-ADTLogEntry -Message "Removing existing template folder [$templatePath]."
                    Remove-Item -LiteralPath $templatePath -Recurse -Force
                }
                if (!$PSCmdlet.ShouldProcess($templatePath, 'Create PSAppDeployToolkit template'))
                {
                    return
                }
                Write-ADTLogEntry -Message "Creating template folder [$templatePath]."
                $null = New-Item -Path $templatePath -ItemType Directory -Force
                foreach ($folder in 'Files', 'SupportFiles')
                {
                    if ($ExcludeContent -notcontains $folder)
                    {
                        $null = New-Item -Path (Join-Path $templatePath $folder) -ItemType Directory -Force
                    }
                }

                # Extensions module.
                if ($ExcludeContent -notcontains 'Extensions')
                {
                    Copy-Item -LiteralPath (Join-Path $frontendDir 'PSAppDeployToolkit.Extensions') -Destination $templatePath -Recurse -Force
                }

                # The module itself.
                if ($ExcludeContent -notcontains 'Module')
                {
                    $templateModulePath = Join-Path $templatePath 'PSAppDeployToolkit'
                    $null = New-Item -Path $templateModulePath -ItemType Directory -Force
                    Get-ChildItem -LiteralPath $moduleDir -Force | & { process { if ($_.Name -ne 'opt') { Copy-Item -LiteralPath $_.FullName -Destination $templateModulePath -Recurse -Force } } }
                    $null = New-Item -Path (Join-Path $templateModulePath 'opt/Frontend') -ItemType Directory -Force
                    Copy-Item -LiteralPath $frontendDir -Destination (Join-Path $templateModulePath 'opt/Frontend') -Recurse -Force
                }

                # Config/Strings overrides: only the supplied keys are written, the module defaults supply the rest.
                if ($Config -and ($ExcludeContent -notcontains 'Config'))
                {
                    $null = New-Item -Path (Join-Path $templatePath 'Config') -ItemType Directory -Force
                    Set-Content -LiteralPath (Join-Path $templatePath 'Config/config.psd1') -Value (ConvertTo-ADTSourceText -Value $Config) -Encoding utf8
                }
                if ($Strings -and ($ExcludeContent -notcontains 'Strings'))
                {
                    $null = New-Item -Path (Join-Path $templatePath 'Strings') -ItemType Directory -Force
                    Set-Content -LiteralPath (Join-Path $templatePath 'Strings/strings.psd1') -Value (ConvertTo-ADTSourceText -Value $Strings) -Encoding utf8
                }

                # Copy any provided Assets/Files/SupportFiles.
                foreach ($folder in 'Assets', 'Files', 'SupportFiles')
                {
                    if ($PSBoundParameters.ContainsKey($folder))
                    {
                        $null = New-Item -Path (Join-Path $templatePath $folder) -ItemType Directory -Force
                        Copy-Item -Path $PSBoundParameters[$folder] -Destination (Join-Path $templatePath $folder) -Recurse -Force
                    }
                }

                # Generate Invoke-AppDeployToolkit.ps1.
                $scriptPath = Join-Path $templatePath 'Invoke-AppDeployToolkit.ps1'
                $scriptContent = [System.IO.File]::ReadAllText((Join-Path $frontendDir 'Invoke-AppDeployToolkit.ps1')).Replace('..\..\..\..\', $null).Replace('2000-12-31', [System.DateTime]::Now.ToString('yyyy-MM-dd'))
                if ($SessionProperties)
                {
                    foreach ($kvp in $SessionProperties.GetEnumerator())
                    {
                        $valueText = ConvertTo-ADTSourceText -Value $kvp.Value -Depth 1
                        $pattern = "(?m)^(    $([System.Text.RegularExpressions.Regex]::Escape($kvp.Key)) = ).*$"
                        $scriptContent = if ([System.Text.RegularExpressions.Regex]::IsMatch($scriptContent, $pattern))
                        {
                            [System.Text.RegularExpressions.Regex]::Replace($scriptContent, $pattern, { param($m) $m.Groups[1].Value + $valueText }, [System.Text.RegularExpressions.RegexOptions]::None)
                        }
                        else
                        {
                            $scriptContent.Replace("`n`n    DeployAppScriptFriendlyName", "`n    $($kvp.Key) = $valueText`n`n    DeployAppScriptFriendlyName")
                        }
                    }
                }
                foreach ($section in 'Pre-Install', 'Install', 'Post-Install', 'Pre-Uninstall', 'Uninstall', 'Post-Uninstall', 'Pre-Repair', 'Repair', 'Post-Repair')
                {
                    if (!($sb = $PSBoundParameters["$($section.Replace('-', ''))ScriptBlock"]))
                    {
                        continue
                    }
                    $ast = [System.Management.Automation.Language.Parser]::ParseInput($scriptContent, [ref]$null, [ref]$null)
                    $cmd = $ast.Find({ ($args[0] -is [System.Management.Automation.Language.CommandAst]) -and ($args[0].GetCommandName() -eq 'New-Variable') -and ($args[0].CommandElements.Extent.Text -contains $section) }, $true)
                    $sbAst = $cmd.CommandElements | & { process { if ($_ -is [System.Management.Automation.Language.ScriptBlockExpressionAst]) { $_ } } } | Select-Object -Last 1
                    $scriptContent = $scriptContent.Substring(0, $sbAst.Extent.StartOffset) + "{`n$(Get-ADTScriptBlockBody -ScriptBlock $sb)`n}" + $scriptContent.Substring($sbAst.Extent.EndOffset)
                }
                [System.IO.File]::WriteAllText($scriptPath, $scriptContent, [System.Text.UTF8Encoding]::new($true))
                $null = Invoke-ADTNativeCommand -FilePath chmod -ArgumentList '+x', $scriptPath

                # The shell launcher is the Linux counterpart of Invoke-AppDeployToolkit.exe.
                $launcherPath = Join-Path $templatePath 'Invoke-AppDeployToolkit.sh'
                Copy-Item -LiteralPath (Join-Path $frontendDir 'Invoke-AppDeployToolkit.sh') -Destination $launcherPath -Force
                $null = Invoke-ADTNativeCommand -FilePath chmod -ArgumentList '+x', $launcherPath
                Write-ADTLogEntry -Message "Template successfully created at [$templatePath]."
                if ($PassThru)
                {
                    return (Get-Item -LiteralPath $templatePath)
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
