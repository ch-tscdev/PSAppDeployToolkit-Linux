
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
