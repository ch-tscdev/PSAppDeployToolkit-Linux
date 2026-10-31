
    begin
    {
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        if ($PSCmdlet.ParameterSetName -ne 'InstalledApplication')
        {
            if (!($PSBoundParameters.Keys -match '^(Name|ProductCode|FilterScript)$'))
            {
                $naerParams = @{
                    Exception = [System.InvalidOperationException]::new('Either Name, ProductCode or FilterScript are required if not using pipeline.')
                    Category = [System.Management.Automation.ErrorCategory]::InvalidArgument
                    ErrorId = 'NullParameterValue'
                    RecommendedAction = "Review the supplied parameter values and try again."
                }
                $PSCmdlet.ThrowTerminatingError((New-ADTErrorRecord @naerParams))
            }
            $gaiaParams = Get-ADTBoundParametersAndDefaultValues -Invocation $MyInvocation -Exclude ForceUninstallString, ArgumentList, AdditionalArgumentList, LoggingOptions, LogFileName, PassThru, SecureArgumentList, SuccessExitCodes, RebootExitCodes, IgnoreExitCodes, WaitForChildProcesses, KillChildProcessesWithParent, ExitOnProcessFailure
            if (($installedApps = Get-ADTApplication @gaiaParams))
            {
                $InstalledApplication = $installedApps
            }
        }

        # Parameters passed through to Start-ADTProcess.
        $sapParams = @{
            SecureArgumentList = $SecureArgumentList
            WaitForChildProcesses = $WaitForChildProcesses
            KillChildProcessesWithParent = $KillChildProcessesWithParent
            ExitOnProcessFailure = $ExitOnProcessFailure
            CreateNoWindow = $true
        }
        foreach ($param in 'SuccessExitCodes', 'RebootExitCodes', 'IgnoreExitCodes', 'PassThru')
        {
            if ($PSBoundParameters.ContainsKey($param))
            {
                $sapParams.Add($param, $PSBoundParameters.$param)
            }
        }
        if ($PSBoundParameters.ContainsKey('LoggingOptions') -or $PSBoundParameters.ContainsKey('LogFileName'))
        {
            Write-ADTLogEntry -Message 'The parameters [-LoggingOptions]/[-LogFileName] are MSI-specific and have no effect on Linux; package manager output is written to the toolkit log.'
        }
    }

    process
    {
        if (!$InstalledApplication)
        {
            Write-ADTLogEntry -Message 'No applications found for removal.'
            return
        }
        foreach ($removeApplication in $InstalledApplication)
        {
            try
            {
                if (!($command = Get-ADTLinuxUninstallCommand -Application $removeApplication))
                {
                    Write-ADTLogEntry -Message "No uninstall method found for application [$($removeApplication.DisplayName)] ($($removeApplication.PackageManager)). Skipping removal." -Severity Warning
                    continue
                }
                $arguments = if ($PSBoundParameters.ContainsKey('ArgumentList')) { $ArgumentList } else { $command[1] }
                if ($AdditionalArgumentList)
                {
                    $arguments = @($arguments) + @($AdditionalArgumentList)
                }
                Write-ADTLogEntry -Message "Removing $($removeApplication.PackageManager) package [$($removeApplication.DisplayName)$(if ($removeApplication.DisplayVersion) { " $($removeApplication.DisplayVersion)" })]..."
                if (!$PSCmdlet.ShouldProcess("Application [$($removeApplication.DisplayName)]", 'Uninstall'))
                {
                    continue
                }
                $previousFrontend = $env:DEBIAN_FRONTEND
                $env:DEBIAN_FRONTEND = 'noninteractive'
                try
                {
                    if (($result = Start-ADTProcess @sapParams -FilePath $command[0] -ArgumentList $arguments -ErrorAction $OriginalErrorAction) -and $PassThru)
                    {
                        $result
                    }
                }
                catch
                {
                    Write-Error -ErrorRecord $_
                }
                finally
                {
                    $env:DEBIAN_FRONTEND = $previousFrontend
                }
            }
            catch
            {
                Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
            }
        }
    }

    end
    {
        Complete-ADTFunction -Cmdlet $PSCmdlet
    }
