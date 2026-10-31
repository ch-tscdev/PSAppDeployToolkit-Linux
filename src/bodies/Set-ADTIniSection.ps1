
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
                Write-ADTLogEntry -Message "$(if ($Overwrite) { 'Overwriting' } else { 'Writing' }) INI section: [FilePath = $FilePath] [Section = $Section]."
                if (!$PSCmdlet.ShouldProcess("$FilePath [$Section]", 'Set INI section'))
                {
                    return
                }
                $ini = Read-ADTIniFile -LiteralPath $FilePath
                if ($Overwrite -or !$ini.Contains($Section)) { $ini[$Section] = [ordered]@{} }
                foreach ($kvp in $Content.GetEnumerator())
                {
                    if ($null -eq $kvp.Value) { $ini[$Section].Remove([System.String]$kvp.Key) } else { $ini[$Section][[System.String]$kvp.Key] = [System.String]$kvp.Value }
                }
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
