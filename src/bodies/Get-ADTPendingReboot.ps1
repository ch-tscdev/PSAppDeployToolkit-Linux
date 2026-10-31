
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
                Write-ADTLogEntry -Message "Getting the pending reboot status on the local computer [$([System.Environment]::MachineName)]."
                $lastBoot = [System.DateTime]::Now - [System.TimeSpan]::FromSeconds([System.Double]([System.IO.File]::ReadAllText('/proc/uptime').Split(' ')[0]))
                $packages = [System.Collections.Generic.List[System.String]]::new()
                $reason = $null
                # Debian/Ubuntu: /run/reboot-required(.pkgs).
                if (Test-Path -LiteralPath /run/reboot-required -PathType Leaf)
                {
                    $reason = 'File [/run/reboot-required] exists.'
                    if (Test-Path -LiteralPath /run/reboot-required.pkgs -PathType Leaf)
                    {
                        [System.IO.File]::ReadAllLines('/run/reboot-required.pkgs') | & { process { if ($_) { $packages.Add($_) } } }
                    }
                }
                # RHEL/Fedora: needs-restarting -r returns 1 when a reboot is required.
                elseif (Get-Command -Name needs-restarting -CommandType Application -ErrorAction Ignore)
                {
                    $ec = 0
                    $null = Invoke-ADTNativeCommand -FilePath needs-restarting -ArgumentList '-r' -ExitCode ([ref]$ec)
                    if ($ec -eq 1) { $reason = 'needs-restarting -r reported that a reboot is required.' }
                }
                # SUSE: zypper needs-rebooting returns 102 when a reboot is required.
                elseif (Get-Command -Name zypper -CommandType Application -ErrorAction Ignore)
                {
                    $ec = 0
                    $null = Invoke-ADTNativeCommand -FilePath zypper -ArgumentList 'needs-rebooting' -ExitCode ([ref]$ec)
                    if ($ec -eq 102) { $reason = 'zypper needs-rebooting reported that a reboot is required.' }
                }
                # Generic: the running kernel's modules have been removed (kernel was updated).
                if (!$reason -and !(Test-Path -LiteralPath "/lib/modules/$([System.IO.File]::ReadAllText('/proc/sys/kernel/osrelease').Trim())" -PathType Container) -and (Test-Path -LiteralPath /lib/modules -PathType Container))
                {
                    $reason = 'The modules of the running kernel are no longer installed (kernel update).'
                }
                $info = [PSADT.DeviceManagement.RebootInfo]::new([System.Environment]::MachineName, $lastBoot, [System.Boolean]$reason, $packages.AsReadOnly(), $reason)
                Write-ADTLogEntry -Message "Pending reboot status on the local computer [$($info.ComputerName)]:`n$($info | Format-List | Out-ADTString)"
                return $info
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
