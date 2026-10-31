
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
                Write-ADTLogEntry -Message 'Checking whether the microphone is in use...'
                # A capture device is in use when any ALSA capture substream reports a RUNNING state.
                $inUse = [System.Boolean](Get-ChildItem -Path '/proc/asound/card*/pcm*c/sub*/status' -ErrorAction Ignore | & { process { if ([System.IO.File]::ReadAllText($_.FullName) -match 'state:\s*RUNNING') { $_ } } } | Select-Object -First 1)
                Write-ADTLogEntry -Message "The microphone is$(if (!$inUse) { ' not' }) in use."
                return $inUse
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
