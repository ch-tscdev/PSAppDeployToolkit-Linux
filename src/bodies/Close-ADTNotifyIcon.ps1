
    begin
    {
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process
    {
        # Headless: there is never a dialog to close on Linux.
        Write-ADTLogEntry -Message "Bypassing $($MyInvocation.MyCommand.Name) as no dialog is open (Linux: no UI available)." -DebugMessage
    }

    end
    {
        Complete-ADTFunction -Cmdlet $PSCmdlet
    }
