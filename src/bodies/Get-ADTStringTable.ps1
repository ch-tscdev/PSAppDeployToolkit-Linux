
    $stringTable = try
    {
        (Get-ADTModuleState).Strings
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
    if ($PSBoundParameters.ContainsKey('SessionState'))
    {
        # Deep-clone the table, then expand any variables within the caller's session state.
        $clone = { param($t) $c = @{}; foreach ($k in $t.Keys) { $c[$k] = if ($t[$k] -is [System.Collections.Hashtable]) { & $clone $t[$k] } else { $t[$k] } }; $c }
        $stringTable = & $clone $stringTable
        Expand-ADTVariablesInHashtable -Hashtable $stringTable -SessionState $SessionState
    }
    return $stringTable
