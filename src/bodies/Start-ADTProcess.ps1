
    begin
    {
        # Internal worker function to set the session exit code.
        function Set-ADTSessionExitCode
        {
            [CmdletBinding()]
            param
            (
                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [System.Nullable[System.Int32]]$ExitCode
            )

            if (!$adtSession)
            {
                $naerParams = @{
                    Exception = [System.InvalidProgramException]::new("The function [Start-ADTProcess] attempted to set a session exit code, but no deployment session is active.")
                    Category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                    ErrorId = 'NoActiveAdtDeploymentSession'
                    TargetObject = $ExitCode
                }
                $PSCmdlet.ThrowTerminatingError((New-ADTErrorRecord @naerParams))
            }
            if (!$canSetExitCode)
            {
                return
            }
            $null = $adtSession.TrySetExitCode($ExitCode, $SuccessExitCodes, $RebootExitCodes)
        }

        # Initalize function and get required objects.
        $adtSession = if (Test-ADTSessionActive)
        {
            Get-ADTSession
        }
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $canSetExitCode = $true

        # Log the deprecation of -IgnoreExitCodes to the log.
        if ($PSBoundParameters.ContainsKey('IgnoreExitCodes'))
        {
            Write-ADTLogEntry -Message "The parameter [-IgnoreExitCodes] is obsolete and will be removed in PSAppDeployToolkit 4.3.0. Please use [-SuccessExitCodes]/[-RebootExitCodes] for known exit codes, or [-ErrorAction SilentlyContinue] for ignoring any exit code instead." -Severity Warning
        }

        # Set up defaults if not specified.
        if (!$PSBoundParameters.ContainsKey('SuccessExitCodes'))
        {
            $SuccessExitCodes = if ($adtSession) { $adtSession.AppSuccessExitCodes } else { 0 }
        }
        else
        {
            $canSetExitCode = $false
        }
        if (!$PSBoundParameters.ContainsKey('RebootExitCodes'))
        {
            $RebootExitCodes = if ($adtSession) { $adtSession.AppRebootExitCodes } else { 1641, 3010 }
        }
        else
        {
            $canSetExitCode = $false
        }

        # Determine whether the caller is external to the module (or one of our wrappers).
        $funcCaller = Get-PSCallStack | Select-Object -Skip 1 | Select-Object -First 1 | & { process { $_.InvocationInfo.MyCommand } }
        $extInvoker = !$funcCaller -or !$funcCaller.Source -or !$funcCaller.Source.StartsWith($MyInvocation.MyCommand.Module.Name) -or $funcCaller.Name.Equals('Start-ADTProcessAsUser') -or $funcCaller.Name.Equals('Uninstall-ADTApplication')

        # Set up the timeout.
        $cancellationTokenSource = if ($PSBoundParameters.ContainsKey('Timeout') -and $Timeout)
        {
            [System.Threading.CancellationTokenSource]::new($Timeout)
        }
        $cancellationToken = if ($cancellationTokenSource) { $cancellationTokenSource.Token } else { [System.Threading.CancellationToken]::None }
    }

    process
    {
        Write-ADTLogEntry -Message "Preparing to execute process [$FilePath]$(if ($RunAsActiveUser) {" for user [$($RunAsActiveUser.NTAccount)]"})..."
        if ($PSBoundParameters.ContainsKey('IgnoreExitCodes') -and !$($IgnoreExitCodes).Equals('*'))
        {
            Write-ADTLogEntry -Message "Please use [-SuccessExitCodes] and/or [-RebootExitCodes] to specify your process's exit codes."
        }

        # Windows-only options have no meaning on Linux; tell the caller once rather than failing.
        foreach ($winOnly in 'UseLinkedAdminToken', 'UseHighestAvailableToken', 'DenyUserTermination', 'UseUnelevatedToken', 'WaitForMsiExec')
        {
            if ($PSBoundParameters.ContainsKey($winOnly) -and $PSBoundParameters.$winOnly)
            {
                Write-ADTLogEntry -Message "The parameter [-$winOnly] has no effect on Linux and will be ignored." -Severity Warning
            }
        }

        $result = $null
        try
        {
            try
            {
                # Resolve a non-fully qualified path (relative to Files/SupportFiles/working directory, then $PATH).
                $FilePath = $FilePath -replace '\\', '/'
                if ((!$FilePath.Contains('%') -or !$ExpandEnvironmentVariables) -and ![System.IO.Path]::IsPathFullyQualified($FilePath))
                {
                    $rafspParams = @{ LiteralPath = $FilePath; File = $true }
                    if ($PSBoundParameters.ContainsKey('WorkingDirectory'))
                    {
                        $rafspParams.Add('ExtraPaths', $WorkingDirectory)
                    }
                    if (($fqPath = Resolve-ADTFileSystemPath @rafspParams))
                    {
                        Write-ADTLogEntry -Message "File path [$FilePath] successfully resolved to fully qualified path [$fqPath]."
                        $FilePath = $fqPath
                    }
                }

                # Set the working directory if not specified, as the original does.
                $workingDir = $null
                if (!$PSBoundParameters.ContainsKey('WorkingDirectory'))
                {
                    $workingDir = if ($adtSession -and [System.IO.Path]::IsPathFullyQualified($FilePath) -and $FilePath.StartsWith('/') -and [System.IO.Path]::HasExtension($FilePath))
                    {
                        [System.IO.Path]::GetDirectoryName($FilePath)
                    }
                    elseif ($adtSession -and $adtSession.DirFiles)
                    {
                        $adtSession.DirFiles.FullName
                    }
                }
                else
                {
                    $workingDir = $WorkingDirectory -replace '\\', '/'
                }

                # Shell-executed processes have no stdout/stderr, everything else is captured (no windows on Linux).
                if ($UseShellExecute)
                {
                    Write-ADTLogEntry -Message 'UseShellExecute is set to true, StdOut/StdErr streams will not be available.'
                    if (!$FilePath.StartsWith('/') -and ($opener = Get-Command -Name xdg-open -CommandType Application -ErrorAction Ignore))
                    {
                        $ArgumentList = @($FilePath) + @($ArgumentList | & { process { if ($_) { $_ } } })
                        $FilePath = $opener.Source
                    }
                }
                if (![System.String]::IsNullOrWhiteSpace($workingDir))
                {
                    Write-ADTLogEntry -Message "Working Directory is [$workingDir]."
                }

                # Build the launch information.
                $launchInfo = [PSADT.ProcessManagement.LinuxLaunchInfo]::new()
                $launchInfo.FilePath = $FilePath
                $launchInfo.ArgumentList = [System.String[]]@($ArgumentList | & { process { if ($null -ne $_) { $_ } } })
                $launchInfo.WorkingDirectory = $workingDir
                $launchInfo.RunAsActiveUser = $RunAsActiveUser
                $launchInfo.InheritEnvironmentVariables = $InheritEnvironmentVariables
                $launchInfo.ExpandEnvironmentVariables = $ExpandEnvironmentVariables
                $launchInfo.StandardInput = $StandardInput
                $launchInfo.CaptureOutput = !$UseShellExecute
                $launchInfo.WaitForChildProcesses = $WaitForChildProcesses
                $launchInfo.KillChildProcessesWithParent = $KillChildProcessesWithParent
                $launchInfo.StreamEncoding = $StreamEncoding
                if ($PSBoundParameters.ContainsKey('PriorityClass')) { $launchInfo.PriorityClass = $PriorityClass }
                $launchInfo.CancellationToken = $cancellationToken
                $launchInfo.NoTerminateOnTimeout = $NoTerminateOnTimeout

                # Log the command line we're about to run.
                $userText = if ($RunAsActiveUser) { " for user [$($RunAsActiveUser.NTAccount)]" }
                $waitText = if ($NoWait) { ' without waiting' }
                if ($ArgumentList)
                {
                    if ($SecureArgumentList)
                    {
                        Write-ADTLogEntry -Message "Executing [`"$FilePath`" (Parameters Hidden)]$userText$waitText..."
                    }
                    else
                    {
                        Write-ADTLogEntry -Message "Executing [`"$FilePath`" $([PSADT.ProcessManagement.CommandLineUtilities]::ArgumentListToCommandLine([System.String[]]$launchInfo.ArgumentList))]$userText$waitText..."
                    }
                }
                else
                {
                    Write-ADTLogEntry -Message "Executing [`"$FilePath`"]$userText$waitText..."
                }
                if (!$PSCmdlet.ShouldProcess("Process [$FilePath]", 'Execute'))
                {
                    return
                }

                # Launch the process.
                $execution = [PSADT.ProcessManagement.ProcessManager]::LaunchAsync($launchInfo)
                if ($NoWait)
                {
                    if ($PassThru)
                    {
                        Write-ADTLogEntry -Message 'PassThru parameter specified, returning task for external tracking.'
                        return $execution
                    }
                    return
                }
                $result = $execution.GetResult()
                $commandLineText = if ($SecureArgumentList) { "`"$FilePath`" (Parameters Hidden)" } else { $execution.CommandLine }

                # Handle timeouts.
                if ($result.ExitCode -eq [PSADT.ProcessManagement.ProcessManager]::TimeoutExitCode -and $cancellationToken.IsCancellationRequested)
                {
                    $naerParams = if ($NoTerminateOnTimeout)
                    {
                        @{
                            Exception = [System.TimeoutException]::new("Timed out waiting for process execution to complete.")
                            Category = [System.Management.Automation.ErrorCategory]::LimitsExceeded
                            ErrorId = 'ProcessExecutionTimedOut'
                            TargetObject = $(if (!$SecureArgumentList) { $result })
                        }
                    }
                    else
                    {
                        @{
                            Exception = [System.OperationCanceledException]::new("Process terminated because execution took too long to complete.", $cancellationToken)
                            Category = [System.Management.Automation.ErrorCategory]::OperationStopped
                            ErrorId = 'ProcessExecutionCancelled'
                            TargetObject = $(if (!$SecureArgumentList) { $result })
                        }
                    }
                    throw (New-ADTErrorRecord @naerParams)
                }
                Write-ADTLogEntry -Message "Finished execution of [$commandLineText]."

                # Evaluate the exit code exactly like the original does.
                $waleParams = if (($ignoreExitCode = $IgnoreExitCodes -and ($($IgnoreExitCodes).Equals('*') -or ([System.Int32[]]$IgnoreExitCodes).Contains($result.ExitCode))))
                {
                    @{ Message = "Execution completed and the exit code [$($result.ExitCode)] is being ignored."; Severity = [PSAppDeployToolkit.Logging.LogSeverity]::Info }
                }
                elseif ($SuccessExitCodes -contains $result.ExitCode)
                {
                    @{ Message = "Execution completed successfully with exit code [$($result.ExitCode)]."; Severity = [PSAppDeployToolkit.Logging.LogSeverity]::Success }
                }
                elseif ($RebootExitCodes -contains $result.ExitCode)
                {
                    @{ Message = "Execution completed successfully with exit code [$($result.ExitCode)]. A reboot is required."; Severity = [PSAppDeployToolkit.Logging.LogSeverity]::Warning }
                }
                else
                {
                    @{ Message = "Execution failed with exit code [$($result.ExitCode)].$(if (!$UseShellExecute -and !$NoStreamLogging) { " Please check the log file for any available stdout/stderr information." })"; Severity = [PSAppDeployToolkit.Logging.LogSeverity]::Error }
                }
                Write-ADTLogEntry @waleParams

                # Log the captured streams.
                if (!$NoStreamLogging)
                {
                    foreach ($property in ('StdOut', 'StdErr', 'Interleaved'))
                    {
                        $streamMessage = if ($result.$property.Count -gt 1)
                        {
                            "`n`n$([System.String]::Join([System.Environment]::NewLine, $result.$property))"
                        }
                        elseif ($result.$property.Count -eq 1)
                        {
                            $result.$property[0]
                        }
                        else
                        {
                            'N/A'
                        }
                        Write-ADTLogEntry -Message "$property Output from Execution: $streamMessage" -HostLogStreamType ([PSAppDeployToolkit.Logging.HostLogStreamType]::None)
                    }
                }

                # Throw if the execution failed.
                if ($waleParams.Message.StartsWith('Execution failed'))
                {
                    $naerParams = @{
                        Exception = [PSADT.ProcessManagement.ProcessException]::new($waleParams.Message, $result)
                        Category = [System.Management.Automation.ErrorCategory]::InvalidResult
                        ErrorId = 'ProcessExitCodeError'
                        TargetObject = $(if (!$SecureArgumentList) { $result })
                        RecommendedAction = "Please review the exit code with the vendor's documentation and try again."
                    }
                    throw (New-ADTErrorRecord @naerParams)
                }

                # Update the session's exit code.
                if ($adtSession -and $extInvoker -and !$ignoreExitCode -and $canSetExitCode)
                {
                    Set-ADTSessionExitCode -ExitCode $result.ExitCode
                }

                if ($PassThru)
                {
                    Write-ADTLogEntry -Message 'PassThru parameter specified, returning execution results object.'
                    return $result
                }
            }
            catch
            {
                Write-Error -ErrorRecord $_
            }
        }
        catch
        {
            $iafehParams = @{
                Cmdlet = $PSCmdlet
                SessionState = $ExecutionContext.SessionState
                ErrorRecord = $_
            }
            $sessionClosed = if (($_.Exception -is [System.Runtime.InteropServices.ExternalException]) -and ($null -ne $result))
            {
                if ($adtSession -and $extInvoker)
                {
                    if (($OriginalErrorAction -notmatch '^(SilentlyContinue|Ignore)$') -and $canSetExitCode)
                    {
                        Set-ADTSessionExitCode -ExitCode $result.ExitCode
                    }
                    if ($ExitOnProcessFailure -and !$PSBoundParameters.ContainsKey('ErrorAction'))
                    {
                        $iafehParams.ErrorAction = [System.Management.Automation.ActionPreference]::SilentlyContinue
                    }
                }
                Invoke-ADTFunctionErrorHandler @iafehParams -Silent
                if ($ExitOnProcessFailure)
                {
                    Close-ADTSession -PassThru
                }
            }
            elseif (($_.Exception -is [System.TimeoutException]) -or ($_.Exception -is [System.OperationCanceledException]))
            {
                if ($PSBoundParameters.ContainsKey('TimeoutAction'))
                {
                    $iafehParams.ErrorAction = $TimeoutAction
                }
                Invoke-ADTFunctionErrorHandler @iafehParams -DisableErrorResolving
            }
            else
            {
                Invoke-ADTFunctionErrorHandler @iafehParams -LogMessage "Error occurred while attempting to start the specified process." -ErrorAction Stop
            }
            if ($null -ne $sessionClosed)
            {
                break
            }
            if ($PassThru)
            {
                if ($result)
                {
                    Write-ADTLogEntry -Message 'PassThru parameter specified, returning execution results object.'
                    return $result
                }
                Write-ADTLogEntry -Message 'PassThru parameter specified, however no result was available.'
            }
        }
        finally
        {
            if ($cancellationTokenSource)
            {
                $cancellationTokenSource.Dispose()
            }
            if ($result -and !$PassThru)
            {
                $result.Dispose()
            }
        }
    }

    end
    {
        Complete-ADTFunction -Cmdlet $PSCmdlet
    }
