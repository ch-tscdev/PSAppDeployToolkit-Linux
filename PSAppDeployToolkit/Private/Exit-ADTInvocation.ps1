#-----------------------------------------------------------------------------
#
# MARK: Exit-ADTInvocation (Linux port)
#
#-----------------------------------------------------------------------------

function Exit-ADTInvocation
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Nullable[System.Int32]]$ExitCode,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$NoShellExit,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$Force
    )

    # Invoke on-exit callbacks.
    $callbackErrors = foreach ($callback in (Get-ADTModuleCallback -Hookpoint OnExit | & { process { return $_ } }))
    {
        try
        {
            & $callback
        }
        catch
        {
            $_
        }
    }

    # Trigger a pending restart (set by Show-ADTInstallationRestartPrompt -AllowSilentRestart).
    if ((Test-ADTModuleInitialized) -and ($null -ne ($restartOnExitData = $Script:ADT.RestartOnExitOptions)))
    {
        Invoke-ADTSystemRestart -Options $restartOnExitData
    }

    # Linux only passes the low 8 bits of an exit code to the parent process; make that visible in the console.
    if (($ExitCode -lt 0) -or ($ExitCode -gt 255))
    {
        Write-Verbose -Message "Linux limits process exit codes to 0-255; exit code [$ExitCode] will be seen by the calling process as [$($ExitCode -band 0xFF)]. Use `$LASTEXITCODE inside PowerShell or the log file for the full value."
    }

    # Reset the module state and exit with the deployment's exit code.
    Reset-ADTModuleState
    if ($Force -or ($Host.Name.Equals('ConsoleHost') -and $callbackErrors))
    {
        [System.Environment]::Exit($ExitCode)
    }
    [System.Environment]::ExitCode = $ExitCode
    $Global:LASTEXITCODE = $ExitCode
    if ($NoShellExit)
    {
        break
    }
    exit $ExitCode
}

function Invoke-ADTSystemRestart
{
    # Schedules a reboot in the background so the deployment can return its exit code first.
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [PSAppDeployToolkit.Foundation.RestartOnExitOptions]$Options
    )

    $seconds = [System.Math]::Max([System.Math]::Ceiling($Options.Countdown.TotalSeconds), 0)
    $message = if ($Options.Reason) { $Options.Reason } else { 'Restart initiated by PSAppDeployToolkit.' }
    $script = "sleep $seconds; command -v systemctl >/dev/null 2>&1 && systemctl reboot || shutdown -r now"
    if (Get-Command -Name systemd-run -CommandType Application -ErrorAction Ignore)
    {
        # A transient timer unit survives the termination of this process tree.
        $null = Invoke-ADTNativeCommand -FilePath systemd-run -ArgumentList "--on-active=$([System.Math]::Max($seconds, 1))", '--timer-property=AccuracySec=1s', '--description', $message, 'systemctl', 'reboot'
    }
    else
    {
        $psi = [System.Diagnostics.ProcessStartInfo]::new('setsid')
        foreach ($a in @('-f', 'sh', '-c', $script)) { $psi.ArgumentList.Add($a) }
        $psi.UseShellExecute = $false
        $null = [System.Diagnostics.Process]::Start($psi)
    }
    if (Get-Command -Name wall -CommandType Application -ErrorAction Ignore)
    {
        $null = Invoke-ADTNativeCommand -FilePath wall -ArgumentList "$message The system will restart in $seconds seconds."
    }
}
