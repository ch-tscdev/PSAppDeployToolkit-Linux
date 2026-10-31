
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
                Write-ADTLogEntry -Message 'Checking if system is using AC power or if it is running on battery...'
                $supplies = @(Get-ChildItem -LiteralPath /sys/class/power_supply -ErrorAction Ignore)
                $read = { param($dir, $name) try { [System.IO.File]::ReadAllText((Join-Path $dir $name)).Trim() } catch { $null } }
                $batteries = @($supplies | & { process { if ((& $read $_.FullName 'type') -eq 'Battery') { $_ } } })
                $mains = @($supplies | & { process { if ((& $read $_.FullName 'type') -in 'Mains', 'USB', 'USB_C') { $_ } } })
                $status = if ($mains | & { process { if ((& $read $_.FullName 'online') -eq '1') { $_ } } })
                {
                    [PSADT.DeviceManagement.PowerLineStatus]::Online
                }
                elseif ($mains.Count)
                {
                    [PSADT.DeviceManagement.PowerLineStatus]::Offline
                }
                elseif ($batteries | & { process { if ((& $read $_.FullName 'status') -eq 'Discharging') { $_ } } })
                {
                    [PSADT.DeviceManagement.PowerLineStatus]::Offline
                }
                elseif ($batteries.Count)
                {
                    [PSADT.DeviceManagement.PowerLineStatus]::Unknown
                }
                else
                {
                    [PSADT.DeviceManagement.PowerLineStatus]::Online
                }
                $charge = $batteries | & { process { & $read $_.FullName 'capacity' } } | Select-Object -First 1
                $chassis = try { [System.IO.File]::ReadAllText('/sys/class/dmi/id/chassis_type').Trim() } catch { $null }
                $batteryInfo = [PSADT.DeviceManagement.BatteryInfo]::new($status, [System.Boolean]$batteries.Count, ($batteries.Count -gt 0) -or ($chassis -in '8', '9', '10', '14', '31', '32'), $(if ($charge) { [System.Double]$charge }))
                switch ($status)
                {
                    ([PSADT.DeviceManagement.PowerLineStatus]::Online) { Write-ADTLogEntry -Message 'System is using AC power.'; break }
                    ([PSADT.DeviceManagement.PowerLineStatus]::Offline) { Write-ADTLogEntry -Message 'System is using battery power.'; break }
                    default { Write-ADTLogEntry -Message "System power status is [$_]. Therefore, we will report system is using AC power." }
                }
                if ($PassThru)
                {
                    return $batteryInfo
                }
                return $batteryInfo.IsUsingACPower
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
