
    begin
    {
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        # Set up the name filter, as the original does.
        $nameFilterScript = if ($Name)
        {
            switch ($NameMatch)
            {
                Contains { { foreach ($eachName in $Name) { if ($appDisplayName -like "*$eachName*") { $true; break } } }; break }
                Exact { { foreach ($eachName in $Name) { if ($appDisplayName -eq $eachName) { $true; break } } }; break }
                Wildcard { { foreach ($eachName in $Name) { if ($appDisplayName -like $eachName) { $true; break } } }; break }
                Regex { { foreach ($eachName in $Name) { if ($appDisplayName -match $eachName) { $true; break } } }; break }
            }
        }
        if ($ProductCode)
        {
            Write-ADTLogEntry -Message 'The parameter [-ProductCode] refers to Windows Installer product codes; no Linux package has one, so nothing will match.' -Severity Warning
        }
    }

    process
    {
        Write-ADTLogEntry -Message "Getting information for installed applications$(if ($FilterScript) {' matching the provided FilterScript'})..."
        try
        {
            try
            {
                # ApplicationType 'MSI' maps to native distribution packages (dpkg/rpm/...), 'EXE' to flatpak/snap.
                $installedApplication = foreach ($app in (Get-ADTLinuxInstalledPackages))
                {
                    $isNative = $app.PackageManager -in 'dpkg', 'rpm', 'pacman', 'apk'
                    if ((($ApplicationType -eq 'MSI') -and !$isNative) -or (($ApplicationType -eq 'EXE') -and $isNative) -or $ProductCode)
                    {
                        continue
                    }
                    $appDisplayName = $app.DisplayName
                    if ($nameFilterScript -and !(& $nameFilterScript))
                    {
                        continue
                    }
                    if ($FilterScript -and !($app | Where-Object -FilterScript $FilterScript))
                    {
                        continue
                    }
                    $app
                }
                if ($installedApplication)
                {
                    foreach ($app in $installedApplication)
                    {
                        Write-ADTLogEntry -Message "Found installed application [$($app.DisplayName)$(if ($app.DisplayVersion) { " $($app.DisplayVersion)" })] ($($app.PackageManager))."
                    }
                    return $installedApplication
                }
                Write-ADTLogEntry -Message 'Found no application based on the supplied filters.'
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
