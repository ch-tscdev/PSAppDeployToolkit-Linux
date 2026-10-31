
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
                $FilePath = Resolve-ADTIniFilePath -FilePath $FilePath
                Write-ADTLogEntry -Message "Reading INI section: [FilePath = $FilePath] [Section = $Section]."
                $ini = Read-ADTIniFile -LiteralPath $FilePath
                if (!$ini.Contains($Section))
                {
                    Write-ADTLogEntry -Message "INI section [$Section] does not exist in [$FilePath]."
                    return
                }
                $content = [ordered]@{}
                foreach ($kvp in $ini[$Section].GetEnumerator()) { $content[$kvp.Key] = $kvp.Value }
                return $content
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
