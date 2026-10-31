
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
                Write-ADTLogEntry -Message "Reading INI Key: [Section = $Section] [Key = $Key]."
                $value = (Read-ADTIniFile -LiteralPath $FilePath)[$Section] | & { process { if ($_) { $_[$Key] } } }
                Write-ADTLogEntry -Message "INI Key Value: [Section = $Section] [Key = $Key] [Value = $value]."
                return $value
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
