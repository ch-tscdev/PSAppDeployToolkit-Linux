
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
