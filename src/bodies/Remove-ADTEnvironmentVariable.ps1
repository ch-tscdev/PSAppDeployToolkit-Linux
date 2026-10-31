
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
                $target = if ($PSBoundParameters.ContainsKey('Target')) { $Target } else { [System.EnvironmentVariableTarget]::Process }
                Write-ADTLogEntry -Message "Removing $(if ($PSBoundParameters.ContainsKey('Target')) { "$Target " })environment variable [$Variable]."
                switch ($target)
                {
                    ([System.EnvironmentVariableTarget]::Process) { [System.Environment]::SetEnvironmentVariable($Variable, $null) }
                    ([System.EnvironmentVariableTarget]::Machine) { Write-ADTEnvironmentFile -LiteralPath '/etc/environment' -Variable $Variable -Value $null }
                    ([System.EnvironmentVariableTarget]::User) { Write-ADTEnvironmentFile -LiteralPath (Get-ADTUserEnvironmentFile) -Variable $Variable -Value $null }
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
