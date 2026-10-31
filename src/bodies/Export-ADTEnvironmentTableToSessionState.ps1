
    begin
    {
        try
        {
            $adtEnv = Get-ADTEnvironmentTable
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError($_)
        }
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process
    {
        try
        {
            try
            {
                foreach ($kvp in $adtEnv.GetEnumerator())
                {
                    $SessionState.PSVariable.Set([System.Management.Automation.PSVariable]::new($kvp.Key, $kvp.Value, [System.Management.Automation.ScopedItemOptions]::ReadOnly))
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
