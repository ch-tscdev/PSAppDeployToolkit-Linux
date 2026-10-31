
    # Return a read-only copy of the module's command table (public functions plus the cmdlets it uses).
    $output = [System.Collections.Generic.Dictionary[System.String, System.Management.Automation.CommandInfo]]::new()
    foreach ($command in $Script:CommandTable.Values)
    {
        if (($command.CommandType -ne [System.Management.Automation.CommandTypes]::Function) -or ($command.Name -match '^\w+-ADT') -and (Test-Path -LiteralPath "$Script:PSScriptRoot/Public/$($command.Name).ps1"))
        {
            $output[$command.Name] = $command
        }
    }
    return [System.Collections.Generic.IReadOnlyDictionary[System.String, System.Management.Automation.CommandInfo]][System.Collections.ObjectModel.ReadOnlyDictionary[System.String, System.Management.Automation.CommandInfo]]::new($output)
