
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
                # Process: this process. Machine: /etc/environment. User: ~/.config/environment.d/90-psadt.conf of the active user.
                $target = if ($PSBoundParameters.ContainsKey('Target')) { $Target } else { [System.EnvironmentVariableTarget]::Process }
                Write-ADTLogEntry -Message "Getting $(if ($PSBoundParameters.ContainsKey('Target')) { "$Target " })environment variable [$Variable]."
                switch ($target)
                {
                    ([System.EnvironmentVariableTarget]::Process) { return [System.Environment]::GetEnvironmentVariable($Variable) }
                    ([System.EnvironmentVariableTarget]::Machine) { return (Read-ADTEnvironmentFile -LiteralPath '/etc/environment')[$Variable] }
                    ([System.EnvironmentVariableTarget]::User) { return (Read-ADTEnvironmentFile -LiteralPath (Get-ADTUserEnvironmentFile))[$Variable] }
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
