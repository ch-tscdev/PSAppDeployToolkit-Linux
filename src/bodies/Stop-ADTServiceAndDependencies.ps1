
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
                foreach ($service in (Get-ADTSystemdServices -ParameterSetName $PSCmdlet.ParameterSetName -BoundParameters $PSBoundParameters))
                {
                    if (!$SkipDependentServices)
                    {
                        # systemd resolves dependencies itself; log them for parity with the original.
                        if (($deps = @($service.DependentServices)).Count)
                        {
                            Write-ADTLogEntry -Message "Service [$($service.ServiceName)] has related services: ['$([System.String]::Join("', '", $deps.ServiceName))'], which systemd will handle as part of the operation."
                        }
                    }
                    if ($service.Status -eq [System.ServiceProcess.ServiceControllerStatus]::Stopped)
                    {
                        Write-ADTLogEntry -Message "Service [$($service.ServiceName)] with display name [$($service.DisplayName)] is already in the [Stopped] state."
                    }
                    else
                    {
                        Write-ADTLogEntry -Message "Stopping service [$($service.ServiceName)] with display name [$($service.DisplayName)]."
                        if (!$PSCmdlet.ShouldProcess($service.ServiceName, 'Stop'))
                        {
                            continue
                        }
                        $null = [PSADT.ServiceManagement.SystemdService]::Systemctl($(if ($SkipDependentServices -and ('Stop' -eq 'Stop')) { @('stop', '--job-mode=ignore-dependencies', $service.Unit) } else { @('stop', $service.Unit) }))
                        $service.WaitForStatus([System.ServiceProcess.ServiceControllerStatus]::Stopped, $PendingStatusWait)
                    }
                    Write-ADTLogEntry -Message "Service [$($service.ServiceName)] with display name [$($service.DisplayName)] has a status of [$($service.Status)]."
                    if ($PassThru)
                    {
                        $service
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
