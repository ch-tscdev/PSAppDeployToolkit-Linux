
    begin
    {
        # Initialize function.
        $adtSession = if (Test-ADTSessionActive) { Get-ADTSession }
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process
    {
        try
        {
            try
            {
                # There is no user interface on Linux: the function always behaves like the original's silent path.
                if (!$PSBoundParameters.ContainsKey('Silent'))
                {
                    Write-ADTLogEntry -Message "Running $($MyInvocation.MyCommand.Name) silently as no user interface is available on Linux."
                }
                foreach ($uiOnly in 'AllowDefer', 'AllowDeferCloseProcesses', 'PersistPrompt', 'PromptToSave', 'MinimizeWindows', 'CustomMessage', 'ForceCountdown', 'CloseProcessesCountdown', 'ForceCloseProcessesCountdown')
                {
                    if ($PSBoundParameters.ContainsKey($uiOnly))
                    {
                        Write-ADTLogEntry -Message "The parameter [-$uiOnly] requires user interaction and has no effect in a headless (Linux) deployment."
                    }
                }

                # Check disk space requirements if specified.
                if ($CheckDiskSpace -or $PSBoundParameters.ContainsKey('RequiredDiskSpace'))
                {
                    $RequiredDiskSpace = if ($PSBoundParameters.ContainsKey('RequiredDiskSpace'))
                    {
                        $PSBoundParameters.RequiredDiskSpace
                    }
                    elseif (($scriptDir = try { Get-ADTSessionCacheScriptDirectory } catch { $null = $null }) -and (Get-ChildItem -LiteralPath $scriptDir -Force -ErrorAction Ignore))
                    {
                        [System.Math]::Max((Get-ChildItem -LiteralPath $scriptDir -Recurse -File -Force -ErrorAction Ignore | Measure-Object -Property Length -Sum).Sum / 1MB, 1)
                    }
                    else
                    {
                        0
                    }
                    if ($RequiredDiskSpace -gt 0)
                    {
                        Write-ADTLogEntry -Message 'Evaluating disk space requirements.'
                        if (($freeDiskSpace = Get-ADTFreeDiskSpace) -lt $RequiredDiskSpace)
                        {
                            Write-ADTLogEntry -Message "Failed to meet minimum disk space requirement. Space Required [$RequiredDiskSpace MB], Space Available [$freeDiskSpace MB]." -Severity Error
                            if ($adtSession)
                            {
                                Close-ADTSession -ExitCode (Get-ADTConfig).UI.DefaultExitCode
                            }
                            break
                        }
                        Write-ADTLogEntry -Message 'Successfully passed minimum disk space requirement check.'
                    }
                }

                # Close any running processes, without prompting the user (SIGTERM first, then SIGKILL).
                if ($CloseProcesses -and ($runningApps = Get-ADTRunningProcesses -ProcessDefinition $CloseProcesses))
                {
                    Write-ADTLogEntry -Message "Force closing application(s) ['$([System.String]::Join("', '", ($runningApps.Description | Select-ADTUniqueObject)))'] without prompting user."
                    foreach ($runningApp in $runningApps)
                    {
                        Write-ADTLogEntry -Message "Stopping process [$($runningApp.FileName.Name)] with PID [$($runningApp.Process.Id)]..."
                        $null = Invoke-ADTNativeCommand -FilePath kill -ArgumentList '-TERM', $runningApp.Process.Id
                    }
                    $deadline = [System.DateTime]::Now.AddSeconds(5)
                    while (($remaining = @($runningApps | & { process { $_.Process.Refresh(); if (!$_.Process.HasExited) { $_ } } })) -and ([System.DateTime]::Now -lt $deadline))
                    {
                        [System.Threading.Thread]::Sleep(250)
                    }
                    if ($remaining)
                    {
                        Write-ADTLogEntry -Message "Process(es) ['$([System.String]::Join("', '", ($remaining.FileName.Name | Select-ADTUniqueObject)))'] did not exit gracefully, killing them."
                        Stop-Process -InputObject $remaining.Process -Force -ErrorAction Ignore
                        [System.Threading.Thread]::Sleep(1000)
                    }
                }

                # Blocking of applications relies on Windows IFEO registry keys.
                if ($adtSession -and $BlockExecution -and $CloseProcesses)
                {
                    Write-ADTLogEntry -Message 'The parameter [-BlockExecution] is not supported on Linux and has been ignored.' -Severity Warning
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
