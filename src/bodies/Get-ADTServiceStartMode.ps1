
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
                $service = Get-ADTSystemdServices -ParameterSetName $PSCmdlet.ParameterSetName -BoundParameters $(if ($PSCmdlet.ParameterSetName -eq 'InputObject') { @{ InputObject = @($InputObject) } } elseif ($PSCmdlet.ParameterSetName -eq 'DisplayName') { @{ DisplayName = @($DisplayName) } } else { @{ Name = @($Name) } }) | Select-Object -First 1
                Write-ADTLogEntry -Message "Getting the service [$($service.ServiceName)] startup mode."
                # enabled -> Automatic, disabled -> Manual (can still be started), masked -> Disabled.
                $serviceStartMode = $service.StartType.ToString()
                Write-ADTLogEntry -Message "Service [$($service.ServiceName)] startup mode is set to [$serviceStartMode] (systemd: $($service.UnitFileState))."
                return $serviceStartMode
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
