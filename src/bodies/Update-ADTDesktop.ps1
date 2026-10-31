
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
                # Refresh desktop/menu caches so new launchers and icons appear.
                Write-ADTLogEntry -Message 'Refreshing the desktop and application menu caches.'
                foreach ($dir in '/usr/share/applications', '/usr/local/share/applications')
                {
                    if ((Test-Path -LiteralPath $dir -PathType Container) -and (Get-Command -Name update-desktop-database -CommandType Application -ErrorAction Ignore))
                    {
                        $null = Invoke-ADTNativeCommand -FilePath update-desktop-database -ArgumentList '-q', $dir
                    }
                }
                foreach ($theme in Get-ChildItem -LiteralPath /usr/share/icons -Directory -ErrorAction Ignore)
                {
                    if ((Test-Path -LiteralPath (Join-Path $theme.FullName 'index.theme')) -and (Get-Command -Name gtk-update-icon-cache -CommandType Application -ErrorAction Ignore))
                    {
                        $null = Invoke-ADTNativeCommand -FilePath gtk-update-icon-cache -ArgumentList '-q', '-t', '-f', $theme.FullName
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
            Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
        }
    }

    end
    {
        Complete-ADTFunction -Cmdlet $PSCmdlet
    }
