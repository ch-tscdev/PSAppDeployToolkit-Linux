
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
                if ($UseCIM)
                {
                    Write-ADTLogEntry -Message 'The parameter [-UseCIM] has no effect on Linux; systemd is queried directly.'
                }
                $service = if ($PSCmdlet.ParameterSetName -eq 'DisplayName')
                {
                    Get-ADTSystemdServices -ParameterSetName DisplayName -BoundParameters @{ DisplayName = @($DisplayName) } | Select-Object -First 1
                }
                else
                {
                    [PSADT.ServiceManagement.SystemdService]::new($Name)
                }
                $label = if ($PSCmdlet.ParameterSetName -eq 'DisplayName') { "display name [$DisplayName]" } else { "name [$Name]" }
                if (!$service -or !$service.Exists)
                {
                    Write-ADTLogEntry -Message "Service with $label does not exist."
                    return $false
                }
                Write-ADTLogEntry -Message "Service with $label exists."
                if ($PassThru)
                {
                    return $service
                }
                return $true
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
