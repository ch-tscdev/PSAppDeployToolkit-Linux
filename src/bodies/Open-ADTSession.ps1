
    begin
    {
        # Make this function stop on any error and ensure the caller doesn't override ErrorAction.
        $PSBoundParameters.ErrorAction = [System.Management.Automation.ActionPreference]::Stop
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        # Determine whether we're being called from a script file (exit on close) or interactively/nested (no exit).
        $callerInvocation = Get-PSCallStack | Select-Object -Skip 1 | Select-Object -First 1 | & { process { $_.InvocationInfo } }
        $noExitOnClose = $callerInvocation -and !$callerInvocation.MyCommand.CommandType.Equals([System.Management.Automation.CommandTypes]::ExternalScript) -and !([System.Environment]::GetCommandLineArgs() -eq '-NonInteractive')

        # Set up the SessionState if one wasn't provided.
        if (!$PSBoundParameters.ContainsKey('DeployAppScriptSessionState'))
        {
            $PSBoundParameters.DeployAppScriptSessionState = $DeployAppScriptSessionState = $PSCmdlet.SessionState
        }

        # Set up the ScriptDirectory if one wasn't provided.
        if (!$PSBoundParameters.ContainsKey('ScriptDirectory'))
        {
            [System.String[]]$PSBoundParameters.ScriptDirectory = $ScriptDirectory = if (!(Test-ADTModuleInitialized))
            {
                if (![System.String]::IsNullOrWhiteSpace(($scriptRoot = $DeployAppScriptSessionState.PSVariable.GetValue('PSScriptRoot', $null))))
                {
                    $scriptRoot
                }
                else
                {
                    $ExecutionContext.SessionState.Path.CurrentLocation.Path
                }
            }
            else
            {
                (Get-ADTModuleDirectories).Script
            }
        }

        # Set up DirFiles/DirSupportFiles if one wasn't specified.
        if (!$PSBoundParameters.ContainsKey('DirFiles'))
        {
            foreach ($directory in $PSBoundParameters.ScriptDirectory)
            {
                if ([System.IO.Directory]::Exists(($directory = Join-Path -Path $directory -ChildPath Files)))
                {
                    $PSBoundParameters.DirFiles = $DirFiles = $directory
                }
            }
        }
        if (!$PSBoundParameters.ContainsKey('DirSupportFiles'))
        {
            foreach ($directory in $PSBoundParameters.ScriptDirectory)
            {
                if ([System.IO.Directory]::Exists(($directory = Join-Path -Path $directory -ChildPath SupportFiles)))
                {
                    $PSBoundParameters.DirSupportFiles = $DirSupportFiles = $directory
                }
            }
        }

        # Remove any values from $PSBoundParameters that are null (empty strings, mostly).
        $null = ($PSBoundParameters.GetEnumerator().Where({ !(Out-ADTString -InputObject $_.Value) })).ForEach({ $PSBoundParameters.Remove($_.Key) })
    }

    process
    {
        # If this function is being called from the console, clear all previous sessions and go for full re-initialization.
        if ($callerInvocation -and [System.String]::IsNullOrWhiteSpace($callerInvocation.InvocationName) -and [System.String]::IsNullOrWhiteSpace($callerInvocation.Line))
        {
            Reset-ADTModuleState -Force
        }
        $firstSession = !(Test-ADTSessionActive)

        # Perform pre-opening tasks.
        $initialized = $false
        $errRecord = $null
        try
        {
            if ($firstSession)
            {
                if (($initialized = !(Test-ADTModuleInitialized)))
                {
                    $iamParams = @{ ScriptDirectory = $PSBoundParameters.ScriptDirectory }
                    if ($PSBoundParameters.ContainsKey('AdditionalEnvironmentVariables'))
                    {
                        $iamParams.Add('AdditionalEnvironmentVariables', $AdditionalEnvironmentVariables)
                    }
                    Initialize-ADTModule @iamParams
                }
                foreach ($callback in (Get-ADTModuleCallback -Hookpoint OnStart | & { process { return $_ } }))
                {
                    & $callback
                }
            }
            foreach ($callback in (Get-ADTModuleCallback -Hookpoint PreOpen | & { process { return $_ } }))
            {
                & $callback
            }
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError(($errRecord = $_))
        }
        finally
        {
            if ($errRecord -and $initialized)
            {
                Reset-ADTModuleState
            }
        }

        # Instantiate the new session.
        try
        {
            try
            {
                $adtSession = New-ADTDeploymentSession -Parameters $PSBoundParameters -NoExitOnClose:$noExitOnClose -SessionClass $SessionClass
                (Get-ADTDeploymentSessions).Add($adtSession)
                Initialize-ADTDeploymentSession -Session $adtSession -Parameters $PSBoundParameters
            }
            catch
            {
                Write-Error -ErrorRecord $_
            }
        }
        catch
        {
            Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord ($errRecord = $_) -LogMessage "Failure occurred while instantiating a new deployment session."
        }
        finally
        {
            if ($errRecord)
            {
                if ((Test-ADTSessionActive) -and !(Get-ADTSession).IsClosed())
                {
                    Close-ADTSession -ExitCode $(if ($errRecord.Exception -is [System.NotSupportedException]) { (Get-ADTConfig).UI.DeferExitCode } else { 60008 }) -NoShellExit:$noExitOnClose
                }
                else
                {
                    Exit-ADTInvocation -ExitCode 60008 -NoShellExit:$noExitOnClose
                }
            }
        }

        # Perform post-opening tasks.
        try
        {
            try
            {
                if ($PSBoundParameters.ContainsKey('UnboundArguments') -and $SessionClass.Equals([PSAppDeployToolkit.Foundation.DeploymentSession]))
                {
                    (Convert-ADTValuesFromRemainingArguments -RemainingArguments $UnboundArguments).GetEnumerator() | & {
                        begin
                        {
                            $adtSessionProps = $adtSession.PSObject.Properties
                        }
                        process
                        {
                            $adtSessionProps.Add([System.Management.Automation.PSNoteProperty]::new($_.Key, $_.Value))
                        }
                    }
                }
                foreach ($callback in (Get-ADTModuleCallback -Hookpoint PostOpen | & { process { return $_ } }))
                {
                    & $callback
                }
                if ($firstSession)
                {
                    Export-ADTEnvironmentTableToSessionState -SessionState $DeployAppScriptSessionState
                }
                $adtSession.InstallPhase = 'Execution'
                if ($PassThru)
                {
                    return $adtSession
                }
            }
            catch
            {
                Write-Error -ErrorRecord $_ -CategoryTargetName 60008 -CategoryTargetType ([System.Int32].Name)
            }
        }
        catch
        {
            Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord ($errRecord = $_) -LogMessage "Failure occurred following new deployment session instantiation."
        }
        finally
        {
            if ($errRecord)
            {
                Close-ADTSession -ExitCode 60008
            }
        }
    }

    end
    {
        Complete-ADTFunction -Cmdlet $PSCmdlet
    }
