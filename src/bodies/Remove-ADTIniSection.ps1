
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
                Write-ADTLogEntry -Message "Removing INI section: [FilePath = $FilePath] [Section = $Section]."
                $ini = Read-ADTIniFile -LiteralPath $FilePath
                if ($ini.Contains($Section) -and $PSCmdlet.ShouldProcess("$FilePath [$Section]", 'Remove INI section'))
                {
                    $ini.Remove($Section)
                    Write-ADTIniFile -LiteralPath $FilePath -Ini $ini
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
