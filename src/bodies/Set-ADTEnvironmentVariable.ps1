
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
                if ($Expandable)
                {
                    Write-ADTLogEntry -Message 'The parameter [-Expandable] (REG_EXPAND_SZ) has no Linux equivalent; the value is stored as-is.'
                }
                $current = switch ($target)
                {
                    ([System.EnvironmentVariableTarget]::Process) { [System.Environment]::GetEnvironmentVariable($Variable) }
                    ([System.EnvironmentVariableTarget]::Machine) { (Read-ADTEnvironmentFile -LiteralPath '/etc/environment')[$Variable] }
                    ([System.EnvironmentVariableTarget]::User) { (Read-ADTEnvironmentFile -LiteralPath (Get-ADTUserEnvironmentFile))[$Variable] }
                }
                # Append/Remove treat the value as a list using the platform path separator (':').
                $newValue = if ($Append -or $Remove)
                {
                    $items = [System.Collections.Generic.List[System.String]]@(([System.String]$current).Split([System.IO.Path]::PathSeparator, [System.StringSplitOptions]::RemoveEmptyEntries))
                    foreach ($item in $Value.Split([System.IO.Path]::PathSeparator, [System.StringSplitOptions]::RemoveEmptyEntries))
                    {
                        if ($Append -and !$items.Contains($item)) { $items.Add($item) }
                        if ($Remove) { $null = $items.Remove($item) }
                    }
                    $items -join [System.IO.Path]::PathSeparator
                }
                else
                {
                    $Value
                }
                Write-ADTLogEntry -Message "Setting $(if ($PSBoundParameters.ContainsKey('Target')) { "$Target " })environment variable [$Variable] to [$newValue]."
                switch ($target)
                {
                    ([System.EnvironmentVariableTarget]::Process) { [System.Environment]::SetEnvironmentVariable($Variable, $newValue) }
                    ([System.EnvironmentVariableTarget]::Machine) { Write-ADTEnvironmentFile -LiteralPath '/etc/environment' -Variable $Variable -Value $newValue }
                    ([System.EnvironmentVariableTarget]::User) { Write-ADTEnvironmentFile -LiteralPath (Get-ADTUserEnvironmentFile) -Variable $Variable -Value $newValue }
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
