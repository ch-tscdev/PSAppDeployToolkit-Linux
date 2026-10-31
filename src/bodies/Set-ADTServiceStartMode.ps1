
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
                $services = Get-ADTSystemdServices -ParameterSetName $PSCmdlet.ParameterSetName -BoundParameters $PSBoundParameters
                foreach ($service in $services)
                {
                    # Automatic* -> enable (and unmask); Manual -> disable (and unmask); Disabled -> mask. Boot/System have no equivalent.
                    $actions = switch -Wildcard ($StartMode)
                    {
                        'Automatic*' { 'unmask', 'enable' }
                        'Manual' { 'unmask', 'disable' }
                        'Disabled' { 'mask' }
                        default { throw [System.NotSupportedException]::new("The startup mode [$StartMode] has no systemd equivalent.") }
                    }
                    if ($StartMode -eq 'Automatic (Delayed Start)')
                    {
                        Write-ADTLogEntry -Message "systemd has no delayed start; [$StartMode] is applied as [Automatic]."
                    }
                    Write-ADTLogEntry -Message "Setting service [$($service.ServiceName)] with display name [$($service.DisplayName)] startup mode to [$StartMode]."
                    if (!$PSCmdlet.ShouldProcess($service.ServiceName, "Set service startup mode to [$StartMode]"))
                    {
                        continue
                    }
                    foreach ($action in $actions)
                    {
                        $null = [PSADT.ServiceManagement.SystemdService]::Systemctl([System.String[]]@($action, $service.Unit))
                    }
                    $service.Refresh()
                    Write-ADTLogEntry -Message "Successfully set service [$($service.ServiceName)] with display name [$($service.DisplayName)] startup mode to [$StartMode]."
                    if ($PassThru)
                    {
                        $PSCmdlet.WriteObject($service)
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
