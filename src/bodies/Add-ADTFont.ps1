
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
