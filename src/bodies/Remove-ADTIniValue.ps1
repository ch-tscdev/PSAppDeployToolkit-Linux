
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
                $ini = Read-ADTIniFile -LiteralPath $FilePath
                if (!$ini.Contains($Section))
                {
                    Write-ADTLogEntry -Message "INI section [$Section] does not exist in [$FilePath]."
                    return
                }
                if ($PSBoundParameters.ContainsKey('Key'))
                {
                    Write-ADTLogEntry -Message "Removing INI Key: [Section = $Section] [Key = $Key]."
                    $ini[$Section].Remove($Key)
                }
                else
                {
                    Write-ADTLogEntry -Message "Removing all keys from INI section [$Section]."
                    $ini[$Section].Clear()
                }
                if ($PSCmdlet.ShouldProcess("$FilePath [$Section]", 'Remove INI value'))
                {
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
