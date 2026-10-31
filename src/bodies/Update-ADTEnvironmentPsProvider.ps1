
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
                # Refresh this process's environment from /etc/environment (system-wide variables set by Set-ADTEnvironmentVariable -Target Machine).
                Write-ADTLogEntry -Message 'Refreshing the environment variables for this PowerShell session.'
                foreach ($kvp in (Read-ADTEnvironmentFile -LiteralPath '/etc/environment').GetEnumerator())
                {
                    if ($kvp.Key -eq 'PATH')
                    {
                        $merged = @(($kvp.Value -split ':') + ($env:PATH -split ':')) | & { process { if ($_) { $_ } } } | Select-Object -Unique
                        [System.Environment]::SetEnvironmentVariable('PATH', ($merged -join ':'))
                        continue
                    }
                    [System.Environment]::SetEnvironmentVariable($kvp.Key, $kvp.Value)
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
