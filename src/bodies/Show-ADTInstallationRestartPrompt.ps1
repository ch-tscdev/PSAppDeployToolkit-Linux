
    begin
    {
        $adtSession = if (Test-ADTSessionActive) { Get-ADTSession }
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process
    {
        try
        {
            try
            {
                # There is no restart dialog on Linux; follow the original's silent path.
                $restartReason = if ($PSBoundParameters.ContainsKey('ShutdownReasonText')) { $ShutdownReasonText } else { [System.Management.Automation.Language.NullString]::Value }
                if (!$AllowSilentRestart)
                {
                    Write-ADTLogEntry -Message "Skipping restart because no restart prompt can be shown on Linux and [-AllowSilentRestart] was not specified."
                    return
                }
                $restartOnExitData = [PSAppDeployToolkit.Foundation.RestartOnExitOptions]::new($SilentCountdown, $restartReason, !!$NoForceCloseApps)
                if ($adtSession)
                {
                    Write-ADTLogEntry -Message "Triggering restart silently because no restart prompt can be shown on Linux and [-AllowSilentRestart] has been specified. Timeout is set to [$($SilentCountdown.TotalSeconds)] seconds."
                    $Script:ADT.RestartOnExitOptions = $restartOnExitData
                }
                else
                {
                    Write-ADTLogEntry -Message "Triggering restart silently in [$($SilentCountdown.TotalSeconds)] seconds."
                    Invoke-ADTSystemRestart -Options $restartOnExitData
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
