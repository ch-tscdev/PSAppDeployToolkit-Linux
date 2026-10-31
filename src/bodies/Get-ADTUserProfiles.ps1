
    begin
    {
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $excludedNames = @($ExcludeNTAccount | & { process { if ($_) { ([System.String]$_) -replace '^.*\\' } } })
        $wantedSids = @($SID | & { process { if ($_) { [System.String]$_ } } })
        if ($IncludeIISAppPoolProfiles -or $IncludeEpmProfiles)
        {
            Write-ADTLogEntry -Message 'The parameters [-IncludeIISAppPoolProfiles]/[-IncludeEpmProfiles] are Windows-specific and have no effect on Linux.'
        }
    }

    process
    {
        Write-ADTLogEntry -Message 'Getting the User Profile Path, User Account Name, and the User Account SID for each user profile.'
        try
        {
            try
            {
                # Regular users: uid >= UID_MIN (usually 1000). "System" profile: root. "Service" profiles: system accounts with a real home directory.
                $uidMin = 1000
                if ((Test-Path -LiteralPath /etc/login.defs) -and ([System.IO.File]::ReadAllText('/etc/login.defs') -match '(?m)^\s*UID_MIN\s+(\d+)')) { $uidMin = [System.Int32]$Matches[1] }
                $nologin = '/(nologin|false)$'
                $shells = @{}
                foreach ($line in [System.IO.File]::ReadAllLines('/etc/passwd')) { $f = $line.Split(':'); if ($f.Count -ge 7) { $shells[$f[0]] = $f[6] } }
                $userProfiles = foreach ($entry in [PSADT.ProcessManagement.LinuxUtilities]::GetPasswdEntries())
                {
                    $uid = $entry.Item1; $name = $entry.Item2; $homeDir = $entry.Item3
                    $isRegular = ($uid -ge $uidMin) -and ($uid -lt 65534)
                    $isSystem = $uid -eq 0
                    $isService = !$isRegular -and !$isSystem -and ($shells[$name] -notmatch $nologin) -and ($homeDir -match '^/home/')
                    if (!($isRegular -or ($isSystem -and $IncludeSystemProfiles) -or ($isService -and $IncludeServiceProfiles))) { continue }
                    if (!$homeDir -or !(Test-Path -LiteralPath $homeDir -PathType Container)) { continue }
                    if ($excludedNames -contains $name) { continue }
                    $userProfile = [PSADT.AccountManagement.UserProfileInfo]::new([PSADT.AccountManagement.UnixIdentity]::ForUser($name, $uid), [PSADT.AccountManagement.UnixIdentity]::SidForUser($uid), [System.IO.DirectoryInfo]$homeDir, $null)
                    if ($wantedSids.Count -and ($wantedSids -notcontains $userProfile.SID.Value) -and ($wantedSids -notcontains $name)) { continue }
                    $userProfile
                }

                # The "Default" user profile maps to /etc/skel (the template for new users).
                if (!$ExcludeDefaultUser -and !$wantedSids.Count -and (Test-Path -LiteralPath /etc/skel -PathType Container))
                {
                    $userProfiles = @($userProfiles) + [PSADT.AccountManagement.UserProfileInfo]::new([PSADT.AccountManagement.UnixIdentity]::new('Default', $null), [PSADT.AccountManagement.UnixIdentity]::new('S-1-0-0', $null), [System.IO.DirectoryInfo]'/etc/skel', $null)
                }
                foreach ($userProfile in $userProfiles)
                {
                    if (!$userProfile) { continue }
                    if ($FilterScript -and !($userProfile | Where-Object -FilterScript $FilterScript)) { continue }
                    $userProfile
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
