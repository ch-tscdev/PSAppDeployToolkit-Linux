
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
                $FilePath = Resolve-ADTIniFilePath -FilePath $FilePath -AllowMissing:$Force
                Write-ADTLogEntry -Message "$(if ($PSBoundParameters.ContainsKey('Value')) { 'Writing' } else { 'Removing' }) INI Key: [Section = $Section] [Key = $Key] [Value = $Value]."
                if (!$PSCmdlet.ShouldProcess("$FilePath [$Section] $Key", 'Set INI value'))
                {
                    return
                }
                $ini = Read-ADTIniFile -LiteralPath $FilePath
                if (!$ini.Contains($Section)) { $ini[$Section] = [ordered]@{} }
                if ($null -eq $Value) { $ini[$Section].Remove($Key) } else { $ini[$Section][$Key] = $Value }
                Write-ADTIniFile -LiteralPath $FilePath -Ini $ini
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
