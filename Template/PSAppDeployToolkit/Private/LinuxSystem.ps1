#-----------------------------------------------------------------------------
#
# MARK: Linux system helpers (sessions, users, OS, packages)
#
#-----------------------------------------------------------------------------

function Invoke-ADTNativeCommand
{
    # Runs a native command and returns its stdout lines. Never throws on a non-zero exit code;
    # the exit code is available via the -ExitCode reference parameter.
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]$FilePath,

        [Parameter(Mandatory = $false, Position = 1)]
        [System.String[]]$ArgumentList = @(),

        [Parameter(Mandatory = $false)]
        [ref]$ExitCode
    )

    if (!(Get-Command -Name $FilePath -CommandType Application -ErrorAction Ignore))
    {
        if ($ExitCode) { $ExitCode.Value = 127 }
        return
    }
    $psi = [System.Diagnostics.ProcessStartInfo]::new($FilePath)
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.Environment['LC_ALL'] = 'C'
    foreach ($arg in $ArgumentList) { $psi.ArgumentList.Add($arg) }
    $proc = [System.Diagnostics.Process]::Start($psi)
    try
    {
        $stderrTask = $proc.StandardError.ReadToEndAsync()
        $stdout = $proc.StandardOutput.ReadToEnd()
        $proc.WaitForExit()
        $null = $stderrTask.GetAwaiter().GetResult()
        if ($ExitCode) { $ExitCode.Value = $proc.ExitCode }
        if ($stdout) { return $stdout.TrimEnd("`n").Split("`n") }
    }
    finally
    {
        $proc.Dispose()
    }
}

function Get-ADTOsRelease
{
    $result = @{}
    foreach ($file in '/etc/os-release', '/usr/lib/os-release')
    {
        if (Test-Path -LiteralPath $file -PathType Leaf)
        {
            foreach ($line in [System.IO.File]::ReadAllLines($file))
            {
                if ($line -match '^([A-Z0-9_]+)=(.*)$')
                {
                    $result[$Matches[1]] = $Matches[2].Trim('"', "'")
                }
            }
            break
        }
    }
    return $result
}

function Get-ADTLinuxOperatingSystemInfo
{
    $osr = Get-ADTOsRelease
    $versionText = if ($osr['VERSION_ID']) { $osr['VERSION_ID'] } else { '0' }
    $parts = @(($versionText -replace '[^0-9.]', '').Split('.', [System.StringSplitOptions]::RemoveEmptyEntries) | Select-Object -First 4)
    while ($parts.Count -lt 2) { $parts += '0' }
    $version = [System.Version]::new(($parts -join '.'))
    $kernel = try { [System.IO.File]::ReadAllText('/proc/sys/kernel/osrelease').Trim() } catch { [System.Environment]::OSVersion.Version.ToString() }
    $arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
    return [PSADT.DeviceManagement.OperatingSystemInfo]::new(
        $(if ($osr['NAME']) { $osr['NAME'] } else { 'Linux' }),
        $(if ($osr['ID']) { $osr['ID'] } else { 'linux' }),
        $osr['ID_LIKE'],
        $version,
        $osr['VERSION_ID'],
        $osr['PRETTY_NAME'],
        $kernel,
        $arch,
        [System.Environment]::Is64BitOperatingSystem
    )
}

function Get-ADTLinuxSessions
{
    # Enumerates logged-on user sessions via systemd-logind, falling back to utmp (who).
    $sessions = [System.Collections.Generic.List[PSADT.TerminalServices.SessionInfo]]::new()
    $currentSessionId = $env:XDG_SESSION_ID
    $adminGroupMembers = Get-ADTLinuxAdminUsers
    $loginctl = Get-Command -Name loginctl -CommandType Application -ErrorAction Ignore
    if ($loginctl)
    {
        $ec = 0
        $ids = Invoke-ADTNativeCommand -FilePath loginctl -ArgumentList 'list-sessions', '--no-legend', '--no-pager' -ExitCode ([ref]$ec) | & { process { if ($_ -match '^\s*(\S+)\s') { $Matches[1] } } }
        foreach ($id in $ids)
        {
            $props = @{}
            Invoke-ADTNativeCommand -FilePath loginctl -ArgumentList 'show-session', $id, '--no-pager' | & { process { if ($_ -match '^([^=]+)=(.*)$') { $props[$Matches[1]] = $Matches[2] } } }
            if (!$props['Name'] -or ($props['Class'] -and ($props['Class'] -notmatch '^user'))) { continue }
            $uid = [System.UInt32]$props['User']
            $logon = if ($props['TimestampMonotonic'] -and $props['Timestamp']) { try { [System.DateTime]::Parse(($props['Timestamp'] -replace '^\w{3}\s', '' -replace '\s[A-Z]{2,5}$', ''), [System.Globalization.CultureInfo]::InvariantCulture) } catch { [System.DateTime]::MinValue } } else { [System.DateTime]::MinValue }
            $sessionNum = 0
            $null = [System.UInt32]::TryParse(($id -replace '\D', ''), [ref]$sessionNum)
            $sessions.Add([PSADT.TerminalServices.SessionInfo]::new(
                    $props['Name'], $uid, $sessionNum, $id, $props['Seat'], $props['TTY'], $props['Display'], $props['Type'], $props['State'], $props['RemoteHost'],
                    $logon, ($adminGroupMembers -contains $props['Name'] -or $uid -eq 0), ($id -eq $currentSessionId)))
        }
    }
    if (!$sessions.Count -and (Get-Command -Name who -CommandType Application -ErrorAction Ignore))
    {
        $i = 0
        foreach ($line in (Invoke-ADTNativeCommand -FilePath who))
        {
            if ($line -notmatch '^(\S+)\s+(\S+)\s+(\d{4}-\d{2}-\d{2} \d{2}:\d{2})(?:\s+\((.*)\))?') { continue }
            $name = $Matches[1]; $tty = $Matches[2]; $remote = $Matches[4]
            $uid = [PSADT.ProcessManagement.LinuxUtilities]::GetUid($name)
            if ($null -eq $uid) { continue }
            $display = if ($remote -match '^:\d') { $remote; $remote = $null }
            $sessions.Add([PSADT.TerminalServices.SessionInfo]::new(
                    $name, $uid, ++$i, $tty, $(if ($tty -match '^(tty|:)') { 'seat0' }), $tty, $display, 'tty', 'active', $remote,
                    [System.DateTime]::ParseExact($Matches[3], 'yyyy-MM-dd HH:mm', [System.Globalization.CultureInfo]::InvariantCulture), ($adminGroupMembers -contains $name -or $uid -eq 0), $false))
        }
    }
    return , $sessions.AsReadOnly()
}

function Get-ADTLinuxAdminUsers
{
    # Members of the sudo/wheel/admin groups are treated as local administrators.
    $members = [System.Collections.Generic.HashSet[System.String]]::new()
    if (Test-Path -LiteralPath /etc/group -PathType Leaf)
    {
        foreach ($line in [System.IO.File]::ReadAllLines('/etc/group'))
        {
            $f = $line.Split(':')
            if (($f.Count -ge 4) -and ($f[0] -in 'sudo', 'wheel', 'admin') -and $f[3])
            {
                $f[3].Split(',') | & { process { $null = $members.Add($_) } }
            }
        }
    }
    return , $members
}

function Get-ADTClientServerUser
{
    # Returns the user who would receive UI on Windows: the active console (seat) session, else any active session.
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$AllowSystemFallback,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$AllowAnyValidSession,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [System.Object]$Username
    )

    $sessions = if ($Script:ADT.Initialized -and $Script:ADT.Environment) { $Script:ADT.Environment['LoggedOnUserSessions'] } else { Get-ADTLinuxSessions }
    if ($Username)
    {
        $name = ([System.String]$Username) -replace '^.*\\'
        $session = $sessions | & { process { if (($_.UserName -eq $name) -and $_.IsValidUserSession) { return $_ } } } | Sort-Object -Property { !$_.IsActiveUserSession } | Select-Object -First 1
        if ($session)
        {
            return [PSADT.Foundation.RunAsActiveUser]::new($session)
        }
        return
    }
    $session = $sessions | & { process { if ($_.IsActiveUserSession -and $_.IsConsoleSession -and ($_.Uid -ne 0)) { return $_ } } } | Select-Object -First 1
    if (!$session -and $AllowAnyValidSession)
    {
        $session = $sessions | & { process { if ($_.IsValidUserSession -and ($_.Uid -ne 0)) { return $_ } } } | Select-Object -First 1
    }
    if ($session)
    {
        return [PSADT.Foundation.RunAsActiveUser]::new($session)
    }
}

function New-ADTEnvironmentTable
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $false)]
        [System.Collections.IDictionary]$AdditionalEnvironmentVariables
    )

    $os = Get-ADTLinuxOperatingSystemInfo
    $osr = Get-ADTOsRelease
    $moduleInfo = $MyInvocation.MyCommand.Module
    $isAdmin = [PSADT.AccountManagement.AccountUtilities]::CallerIsAdmin
    $sessions = Get-ADTLinuxSessions
    $runAsActiveUser = $sessions | & { process { if ($_.IsActiveUserSession -and $_.IsConsoleSession -and ($_.Uid -ne 0)) { return $_ } } } | Select-Object -First 1
    $fqdn = try { [System.Net.Dns]::GetHostEntry([System.Net.Dns]::GetHostName()).HostName } catch { [System.Environment]::MachineName }
    $domain = try { [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().DomainName } catch { $null }
    $chassis = try { [System.IO.File]::ReadAllText('/sys/class/dmi/id/chassis_type').Trim() } catch { $null }
    $virt = Invoke-ADTNativeCommand -FilePath systemd-detect-virt -ErrorAction Ignore | Select-Object -First 1
    $culture = [System.Globalization.CultureInfo]::CurrentCulture
    $uiCulture = [System.Globalization.CultureInfo]::CurrentUICulture
    if ([System.String]::IsNullOrWhiteSpace($culture.Name)) { $culture = [System.Globalization.CultureInfo]::new('en-US') }
    if ([System.String]::IsNullOrWhiteSpace($uiCulture.Name)) { $uiCulture = [System.Globalization.CultureInfo]::new('en-US') }
    $psVersion = $PSVersionTable.PSVersion
    $clrVersion = [System.Environment]::Version
    $hostVersion = $Host.Version
    $invalidChars = [System.IO.Path]::GetInvalidFileNameChars() + [System.Char[]]'\:*?"<>|'
    $packageManager = foreach ($pm in 'apt-get', 'dnf', 'yum', 'zypper', 'pacman', 'apk')
    {
        if (Get-Command -Name $pm -CommandType Application -ErrorAction Ignore) { $pm -replace '-get$'; break }
    }

    $variables = [ordered]@{
        # Toolkit information.
        appDeployToolkitName = $moduleInfo.Name
        appDeployToolkitPath = $moduleInfo.ModuleBase
        appDeployMainScriptVersion = $moduleInfo.Version

        # Culture.
        culture = $culture
        uiculture = $uiCulture
        currentLanguage = $culture.TwoLetterISOLanguageName.ToUpperInvariant()
        currentUILanguage = $uiCulture.TwoLetterISOLanguageName.ToUpperInvariant()

        # PowerShell host.
        envHost = $Host
        envHostVersion = $hostVersion
        envHostVersionMajor = $hostVersion.Major
        envHostVersionMinor = $hostVersion.Minor
        envHostVersionBuild = $(if ($hostVersion.Build -ge 0) { $hostVersion.Build })
        envHostVersionRevision = $(if ($hostVersion.Revision -ge 0) { $hostVersion.Revision })

        # System / identity.
        envSystemDrive = '/'
        envSystemRoot = '/'
        envUserName = [System.Environment]::UserName
        envComputerName = [System.Environment]::MachineName
        envComputerNameFQDN = $fqdn
        IsMachinePartOfDomain = ![System.String]::IsNullOrWhiteSpace($domain) -and ($domain -ne '(none)')
        envMachineWorkgroup = $null
        envMachineADDomain = $(if ($domain -and ($domain -ne '(none)')) { $domain })
        envLogonServer = $null
        envTemp = [System.IO.Path]::GetTempPath().TrimEnd('/')
        envHome = $env:HOME

        # Architecture.
        Is64Bit = [System.Environment]::Is64BitOperatingSystem
        envOSArchitecture = $os.Architecture
        Is64BitProcess = [System.Environment]::Is64BitProcess
        psArchitecture = [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture.ToString()

        # Windows folders have no Linux equivalent; nearest equivalents are provided where sensible.
        envProgramFiles = '/opt'
        envProgramFilesX86 = $null
        envCommonProgramFiles = '/usr/share'
        envCommonProgramFilesX86 = $null
        envSysNativeDirectory = '/usr/bin'
        envSysWow64Directory = $null
        envSystemProfile = '/root'
        envSystemProfileX86 = $null

        # Operating system.
        envOS = $os
        envOSName = $os.Name
        envOSVersion = $os.Version
        envOSVersionMajor = $os.Version.Major
        envOSVersionMinor = $os.Version.Minor
        envOSVersionBuild = $(if ($os.Version.Build -ge 0) { $os.Version.Build })
        envOSVersionRevision = $(if ($os.Version.Revision -ge 0) { $os.Version.Revision })
        envOSId = $os.Id
        envOSIdLike = $os.IdLike
        envOSPrettyName = $os.PrettyName
        envKernelVersion = $os.KernelVersion
        envPackageManager = $packageManager
        IsServerOS = $osr['VARIANT_ID'] -match 'server'
        IsDomainControllerOS = $false
        IsWorkstationOS = $osr['VARIANT_ID'] -notmatch 'server'
        IsTerminalServer = $false
        IsMultiSessionOS = $false
        envOSProductTypeName = $(if ($osr['VARIANT_ID'] -match 'server') { 'Server' } else { 'Workstation' })

        # Office (n/a).
        envOfficeVersion = $null
        envOfficeBitness = $null
        envOfficeChannel = $null

        # Hardware.
        envHardwareType = $(if ($virt -and ($virt -ne 'none')) { 'Virtual' } elseif ($chassis -in '8', '9', '10', '14', '31', '32') { 'Laptop' } else { 'Physical' })

        # PowerShell.
        envPSVersionTable = $PSVersionTable
        envPSProcessPath = [System.Environment]::ProcessPath
        envPSVersion = $psVersion
        envPSVersionMajor = $psVersion.Major
        envPSVersionMinor = $psVersion.Minor
        envPSVersionBuild = $psVersion.Patch
        envPSVersionRevision = $null
        envCLRVersion = $clrVersion
        envCLRVersionMajor = $clrVersion.Major
        envCLRVersionMinor = $clrVersion.Minor
        envCLRVersionBuild = $clrVersion.Build
        envCLRVersionRevision = $clrVersion.Revision

        # Process identity.
        CurrentProcessSID = [PSADT.AccountManagement.AccountUtilities]::CallerSID
        ProcessNTAccount = [PSADT.AccountManagement.AccountUtilities]::CallerNTAccount
        ProcessNTAccountSID = [PSADT.AccountManagement.AccountUtilities]::CallerSID.Value
        IsAdmin = $isAdmin
        IsLocalSystemAccount = $isAdmin
        IsLocalServiceAccount = $false
        IsNetworkServiceAccount = $false
        IsServiceAccount = $isAdmin
        IsProcessUserInteractive = [System.Environment]::UserInteractive -and !$env:INVOCATION_ID -and [System.Console]::IsInputRedirected -eq $false
        SessionZero = $isAdmin -and !$env:XDG_SESSION_ID

        # Logged on users.
        LoggedOnUserSessions = $sessions
        usersLoggedOn = @($sessions | & { process { $_.NTAccount } } | Select-Object -Unique)
        CurrentLoggedOnUserSession = $sessions | & { process { if ($_.IsCurrentSession) { return $_ } } } | Select-Object -First 1
        CurrentConsoleUserSession = $sessions | & { process { if ($_.IsConsoleSession -and $_.IsActiveUserSession) { return $_ } } } | Select-Object -First 1
        RunAsActiveUser = $(if ($runAsActiveUser) { [PSADT.Foundation.RunAsActiveUser]::new($runAsActiveUser) })
        RunAsActiveUserLocale = $null
        RunAsUserProfile = $(if ($runAsActiveUser) { [PSADT.ProcessManagement.LinuxUtilities]::GetHomeDirectory($runAsActiveUser.Uid) })
        UserProfileName = $(if ($runAsActiveUser) { $runAsActiveUser.UserName })

        # Regex patterns.
        invalidFileNameChars = $invalidChars
        invalidFileNameCharsRegExPattern = "[$([System.Text.RegularExpressions.Regex]::Escape([System.String]::Join([System.String]::Empty, $invalidChars)))]"
        MSIProductCodeRegExPattern = '^(\{{0,1}([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}\}{0,1})$'
        InvalidScheduledTaskNameCharsRegExPattern = "[$([System.Text.RegularExpressions.Regex]::Escape('\/:*?"<>|'))]"
    }
    if ($AdditionalEnvironmentVariables)
    {
        foreach ($kvp in $AdditionalEnvironmentVariables.GetEnumerator())
        {
            $variables[$kvp.Key] = $kvp.Value
        }
    }
    return [PSAppDeployToolkit.Foundation.EnvironmentTable]::new($variables)
}

function Resolve-ADTFileSystemPath
{
    # Resolves a relative executable/file path the way the original does, using Linux semantics:
    # current location, the session's Files/SupportFiles directories, any extra paths, then $PATH.
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]$LiteralPath,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$File,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$Directory,

        [Parameter(Mandatory = $false)]
        [System.String]$DefaultExtension,

        [Parameter(Mandatory = $false)]
        [System.String[]]$ExtraPaths
    )

    $LiteralPath = $LiteralPath -replace '\\', '/'
    if ([System.IO.Path]::IsPathFullyQualified($LiteralPath))
    {
        return $LiteralPath
    }
    $searchPaths = [System.Collections.Generic.List[System.String]]::new()
    $searchPaths.Add($ExecutionContext.SessionState.Path.CurrentFileSystemLocation.ProviderPath)
    if (Test-ADTSessionActive)
    {
        $adtSession = Get-ADTSession
        if ($adtSession.DirFiles) { $searchPaths.Add($adtSession.DirFiles.FullName) }
        if ($adtSession.DirSupportFiles) { $searchPaths.Add($adtSession.DirSupportFiles.FullName) }
        foreach ($dir in $adtSession.ScriptDirectory) { $searchPaths.Add($dir.FullName) }
    }
    foreach ($extra in $ExtraPaths) { if ($extra) { $searchPaths.Add($extra) } }
    foreach ($base in $searchPaths)
    {
        $candidate = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($base, $LiteralPath))
        if (($File -and [System.IO.File]::Exists($candidate)) -or ($Directory -and [System.IO.Directory]::Exists($candidate)) -or (!$File -and !$Directory -and (Test-Path -LiteralPath $candidate)))
        {
            return $candidate
        }
    }
    if ($File -and !$LiteralPath.Contains('/') -and ($cmd = Get-Command -Name $LiteralPath -CommandType Application -ErrorAction Ignore | Select-Object -First 1))
    {
        return $cmd.Source
    }
    $naerParams = @{
        Exception = [System.IO.FileNotFoundException]::new("The specified path [$LiteralPath] could not be resolved.")
        Category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
        ErrorId = 'PathNotFound'
        TargetObject = $LiteralPath
        RecommendedAction = "Please confirm the path is correct and try again."
    }
    throw (New-ADTErrorRecord @naerParams)
}

function Test-ADTPathIsReparsePoint
{
    param ([System.String]$LiteralPath)
    return ([System.IO.File]::GetAttributes($LiteralPath) -band [System.IO.FileAttributes]::ReparsePoint) -ne 0
}

function Get-ADTMountedWimFile
{
    # WIM files are a Windows-only concept; nothing is ever mounted on Linux.
}

function Get-ADTSessionCacheScriptDirectory
{
    $scriptDir = if ($adtSession = Get-ADTSession)
    {
        if ($adtSession.ScriptDirectory.Count)
        {
            $adtSession.ScriptDirectory | & { process { if (Test-Path -LiteralPath (Join-Path -Path $_ -ChildPath Files) -PathType Container) { return $_ } } } | Select-Object -Last 1
        }
        elseif ($adtSession.DirFiles -and (Test-Path -LiteralPath $adtSession.DirFiles -PathType Container))
        {
            [System.IO.DirectoryInfo]::new($adtSession.DirFiles).Parent.FullName
        }
    }
    if (!$scriptDir)
    {
        $naerParams = @{
            Exception = [System.IO.DirectoryNotFoundException]::new("None of the current session's ScriptDirectory paths contain any Files/SupportFiles directories.")
            Category = [System.Management.Automation.ErrorCategory]::InvalidResult
            ErrorId = 'ScriptDirectoryInvalid'
            TargetObject = $adtSession.ScriptDirectory
            RecommendedAction = "Please review the session's ScriptDirectory listing, then try again."
        }
        throw (New-ADTErrorRecord @naerParams)
    }
    return $scriptDir
}

function Invoke-ADTLinuxNotSupported
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCmdlet]$Cmdlet
    )

    $name = $Cmdlet.MyInvocation.MyCommand.Name
    $naerParams = @{
        Exception = [System.PlatformNotSupportedException]::new("The function [$name] relies on Windows-only technology and is not supported by the Linux port of PSAppDeployToolkit.")
        Category = [System.Management.Automation.ErrorCategory]::NotImplemented
        ErrorId = 'ADTFunctionNotSupportedOnLinux'
        TargetObject = $name
        RecommendedAction = "Remove the call from your Linux deployment, guard it with 'if (`$IsWindows) { ... }', or use '-ErrorAction SilentlyContinue'."
    }
    throw (New-ADTErrorRecord @naerParams)
}

function Write-ADTHeadlessBypass
{
    # Common log line for UI functions, which can never display anything on Linux.
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCmdlet]$Cmdlet,

        [Parameter(Mandatory = $false)]
        [AllowNull()][AllowEmptyString()]
        [System.String]$Detail
    )

    $adtSession = if (Test-ADTSessionActive) { Get-ADTSession }
    $mode = if ($adtSession) { $adtSession.DeployMode } else { 'Silent' }
    Write-ADTLogEntry -Message "Bypassing $($Cmdlet.MyInvocation.MyCommand.Name) [Mode: $mode, Linux: no UI available].$(if ($Detail) { " $Detail" })" -Source $Cmdlet.MyInvocation.MyCommand.Name
}

function Update-ADTProcessAsUserBoundParameters
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCmdlet]$Cmdlet,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Generic.Dictionary[System.String, System.Object]]$BoundParameters
    )

    $gacsuParams = @{}; if ($BoundParameters.ContainsKey('Username'))
    {
        $gacsuParams.Add('Username', $BoundParameters.Username)
        $gacsuParams.Add('AllowAnyValidSession', $true)
    }
    if (!($BoundParameters.RunAsActiveUser = Get-ADTClientServerUser @gacsuParams))
    {
        if (!$BoundParameters.ContainsKey('ContinueWhenNoUserLoggedOn') -or !$BoundParameters.ContinueWhenNoUserLoggedOn)
        {
            try
            {
                $naerParams = @{
                    Exception = [System.InvalidOperationException]::new("Could not find a valid logged on user session$(if ($BoundParameters.ContainsKey('Username')) { " for [$($BoundParameters.Username)]" }).")
                    Category = [System.Management.Automation.ErrorCategory]::InvalidArgument
                    ErrorId = 'NoActiveUserError'
                    TargetObject = $(if ($BoundParameters.ContainsKey('Username')) { $BoundParameters.Username })
                    RecommendedAction = "Please re-run this command while a user is logged onto the device and try again."
                }
                Write-Error -ErrorRecord (New-ADTErrorRecord @naerParams)
            }
            catch
            {
                Invoke-ADTFunctionErrorHandler -Cmdlet $Cmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
                return $false
            }
        }
        else
        {
            Write-ADTLogEntry -Message "Could not find a valid logged on user session and [-ContinueWhenNoUserLoggedOn] specified, returning early." -Severity Warning
            return $false
        }
    }
    $null = $BoundParameters.Remove('ContinueWhenNoUserLoggedOn')
    $null = $BoundParameters.Remove('Username')
    return $true
}

function Get-ADTLinuxInstalledPackages
{
    # Enumerates installed software from the native package manager (dpkg/rpm/pacman/apk) and from flatpak/snap.
    $apps = [System.Collections.Generic.List[PSADT.AppManagement.InstalledApplication]]::new()
    $epoch = [System.DateTime]::new(1970, 1, 1, 0, 0, 0, [System.DateTimeKind]::Utc)
    if (Get-Command -Name dpkg-query -CommandType Application -ErrorAction Ignore)
    {
        $fmt = '${Status}\t${Package}\t${Version}\t${Architecture}\t${Installed-Size}\t${Maintainer}\t${binary:Summary}\n'
        foreach ($line in (Invoke-ADTNativeCommand -FilePath dpkg-query -ArgumentList '-W', "-f=$fmt"))
        {
            $f = $line.Split("`t")
            if (($f.Count -lt 7) -or ($f[0] -notmatch 'install ok installed')) { continue }
            $date = $null
            if (Test-Path -LiteralPath "/var/lib/dpkg/info/$($f[1]).list") { $date = [System.IO.File]::GetLastWriteTime("/var/lib/dpkg/info/$($f[1]).list").Date }
            elseif (Test-Path -LiteralPath "/var/lib/dpkg/info/$($f[1]):$($f[3]).list") { $date = [System.IO.File]::GetLastWriteTime("/var/lib/dpkg/info/$($f[1]):$($f[3]).list").Date }
            $size = $null; $null = [System.UInt32]::TryParse($f[4], [ref]$size)
            $apps.Add([PSADT.AppManagement.InstalledApplication]::new('dpkg', $f[1], $f[1], $f[2], $f[5], $f[3], $date, $size, $f[6], "apt-get remove -y $($f[1])"))
        }
    }
    elseif (Get-Command -Name rpm -CommandType Application -ErrorAction Ignore)
    {
        $fmt = '%{NAME}\t%{EPOCHNUM}:%{VERSION}-%{RELEASE}\t%{ARCH}\t%{INSTALLTIME}\t%{SIZE}\t%{VENDOR}\t%{SUMMARY}\n'
        foreach ($line in (Invoke-ADTNativeCommand -FilePath rpm -ArgumentList '-qa', '--qf', $fmt))
        {
            $f = $line.Split("`t")
            if ($f.Count -lt 7 -or $f[0] -like 'gpg-pubkey*') { continue }
            $version = $f[1] -replace '^0:'
            $date = $null; $t = 0L; if ([System.Int64]::TryParse($f[3], [ref]$t)) { $date = $epoch.AddSeconds($t).ToLocalTime().Date }
            $size = $null; $s = 0L; if ([System.Int64]::TryParse($f[4], [ref]$s)) { $size = [System.UInt32][System.Math]::Min([System.Math]::Ceiling($s / 1KB), [System.UInt32]::MaxValue) }
            $apps.Add([PSADT.AppManagement.InstalledApplication]::new('rpm', $f[0], $f[0], $version, $(if ($f[5] -ne '(none)') { $f[5] }), $f[2], $date, $size, $f[6], "rpm -e $($f[0])"))
        }
    }
    elseif (Get-Command -Name pacman -CommandType Application -ErrorAction Ignore)
    {
        foreach ($line in (Invoke-ADTNativeCommand -FilePath pacman -ArgumentList '-Q'))
        {
            $f = $line.Split(' ')
            if ($f.Count -ge 2) { $apps.Add([PSADT.AppManagement.InstalledApplication]::new('pacman', $f[0], $f[0], $f[1], $null, $null, $null, $null, $null, "pacman -R --noconfirm $($f[0])")) }
        }
    }
    elseif (Get-Command -Name apk -CommandType Application -ErrorAction Ignore)
    {
        foreach ($line in (Invoke-ADTNativeCommand -FilePath apk -ArgumentList 'info', '-v'))
        {
            if ($line -match '^(.+)-([^-]+-r\d+)$') { $apps.Add([PSADT.AppManagement.InstalledApplication]::new('apk', $Matches[1], $Matches[1], $Matches[2], $null, $null, $null, $null, $null, "apk del $($Matches[1])")) }
        }
    }
    if (Get-Command -Name flatpak -CommandType Application -ErrorAction Ignore)
    {
        foreach ($line in (Invoke-ADTNativeCommand -FilePath flatpak -ArgumentList 'list', '--app', '--columns=application,name,version,arch,origin'))
        {
            $f = $line.Split("`t")
            if ($f.Count -ge 2) { $apps.Add([PSADT.AppManagement.InstalledApplication]::new('flatpak', $f[0], $f[1], $(if ($f.Count -gt 2 -and $f[2]) { $f[2] }), $(if ($f.Count -gt 4) { $f[4] }), $(if ($f.Count -gt 3) { $f[3] }), $null, $null, $null, "flatpak uninstall -y --noninteractive $($f[0])")) }
        }
    }
    if (Get-Command -Name snap -CommandType Application -ErrorAction Ignore)
    {
        foreach ($line in (Invoke-ADTNativeCommand -FilePath snap -ArgumentList 'list', '--unicode=never', '--color=never' | Select-Object -Skip 1))
        {
            $f = $line -split '\s+'
            if ($f.Count -ge 5) { $apps.Add([PSADT.AppManagement.InstalledApplication]::new('snap', $f[0], $f[0], $f[1], $f[4], $null, $null, $null, $null, "snap remove $($f[0])")) }
        }
    }
    return , $apps
}

function Get-ADTLinuxUninstallCommand
{
    # Returns @(FilePath, Arguments[]) to remove a package with the most appropriate front end.
    param ([PSADT.AppManagement.InstalledApplication]$Application)

    $pkg = $Application.PackageName
    switch ($Application.PackageManager)
    {
        'dpkg'
        {
            if (Get-Command -Name apt-get -CommandType Application -ErrorAction Ignore) { return , @('apt-get', @('remove', '-y', '-q', $pkg)) }
            return , @('dpkg', @('--remove', $pkg))
        }
        'rpm'
        {
            foreach ($pm in 'dnf', 'yum') { if (Get-Command -Name $pm -CommandType Application -ErrorAction Ignore) { return , @($pm, @('remove', '-y', $pkg)) } }
            if (Get-Command -Name zypper -CommandType Application -ErrorAction Ignore) { return , @('zypper', @('--non-interactive', 'remove', $pkg)) }
            return , @('rpm', @('-e', $pkg))
        }
        'pacman' { return , @('pacman', @('-R', '--noconfirm', $pkg)) }
        'apk' { return , @('apk', @('del', $pkg)) }
        'flatpak' { return , @('flatpak', @('uninstall', '-y', '--noninteractive', $pkg)) }
        'snap' { return , @('snap', @('remove', $pkg)) }
    }
}

function Read-ADTEnvironmentFile
{
    # Parses a KEY=VALUE file such as /etc/environment.
    param ([System.String]$LiteralPath)

    $result = [ordered]@{}
    if (Test-Path -LiteralPath $LiteralPath -PathType Leaf)
    {
        foreach ($line in [System.IO.File]::ReadAllLines($LiteralPath))
        {
            if ($line -match '^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)=(.*)$')
            {
                $result[$Matches[1]] = $Matches[2].Trim().Trim('"', "'")
            }
        }
    }
    return $result
}

function Write-ADTEnvironmentFile
{
    # Sets or removes a variable in a KEY=VALUE file, preserving comments and other lines.
    param ([System.String]$LiteralPath, [System.String]$Variable, [AllowNull()][System.Object]$Value)

    $lines = [System.Collections.Generic.List[System.String]]::new()
    if (Test-Path -LiteralPath $LiteralPath -PathType Leaf)
    {
        $lines.AddRange([System.String[]][System.IO.File]::ReadAllLines($LiteralPath))
    }
    $pattern = "^\s*(?:export\s+)?$([System.Text.RegularExpressions.Regex]::Escape($Variable))="
    $index = -1
    for ($i = $lines.Count - 1; $i -ge 0; $i--)
    {
        if ($lines[$i] -match $pattern)
        {
            if ($index -lt 0) { $index = $i } else { $lines.RemoveAt($i); $index-- }
        }
    }
    $newLine = if ($null -ne $Value) { "$Variable=`"$(([System.String]$Value).Replace('"', '\"'))`"" }
    if ($index -ge 0)
    {
        if ($newLine) { $lines[$index] = $newLine } else { $lines.RemoveAt($index) }
    }
    elseif ($newLine)
    {
        $lines.Add($newLine)
    }
    $null = [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($LiteralPath))
    [System.IO.File]::WriteAllLines($LiteralPath, $lines)
}

function Get-ADTUserEnvironmentFile
{
    # The "User" environment target maps to systemd's per-user environment.d for the active (or current) user.
    $userHome = if (($user = Get-ADTClientServerUser) -and [PSADT.AccountManagement.AccountUtilities]::CallerIsAdmin)
    {
        [PSADT.ProcessManagement.LinuxUtilities]::GetHomeDirectory($user.Uid)
    }
    else
    {
        $env:HOME
    }
    return "$userHome/.config/environment.d/90-psappdeploytoolkit.conf"
}

function Resolve-ADTIniFilePath
{
    param ([System.String]$FilePath, [System.Management.Automation.SwitchParameter]$AllowMissing)

    $FilePath = $FilePath -replace '\\', '/'
    if (![System.IO.Path]::IsPathFullyQualified($FilePath))
    {
        try { $FilePath = Resolve-ADTFileSystemPath -LiteralPath $FilePath -File } catch { if (!$AllowMissing) { throw } ; $FilePath = [System.IO.Path]::GetFullPath($FilePath) }
    }
    if (!$AllowMissing -and ![System.IO.File]::Exists($FilePath))
    {
        $naerParams = @{
            Exception = [System.IO.FileNotFoundException]::new("The specified INI file [$FilePath] does not exist.", $FilePath)
            Category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
            ErrorId = 'IniFileNotFound'
            TargetObject = $FilePath
            RecommendedAction = "Please confirm the path of the specified file and try again, or add -Force to create a new file."
        }
        throw (New-ADTErrorRecord @naerParams)
    }
    return $FilePath
}

function Read-ADTIniFile
{
    # Ordered, case-insensitive parse of an INI file: @{ Section = @{ Key = Value } }. Keys before any section go to ''.
    param ([System.String]$LiteralPath)

    $ini = [System.Collections.Specialized.OrderedDictionary]::new([System.StringComparer]::OrdinalIgnoreCase)
    if (![System.IO.File]::Exists($LiteralPath))
    {
        return , $ini
    }
    $section = ''
    foreach ($line in [System.IO.File]::ReadAllLines($LiteralPath))
    {
        $trimmed = $line.Trim()
        if (!$trimmed -or $trimmed.StartsWith(';') -or $trimmed.StartsWith('#'))
        {
            continue
        }
        if ($trimmed -match '^\[(.+)\]$')
        {
            $section = $Matches[1].Trim()
            if (!$ini.Contains($section)) { $ini[$section] = [System.Collections.Specialized.OrderedDictionary]::new([System.StringComparer]::OrdinalIgnoreCase) }
            continue
        }
        if (!$ini.Contains($section)) { $ini[$section] = [System.Collections.Specialized.OrderedDictionary]::new([System.StringComparer]::OrdinalIgnoreCase) }
        $idx = $trimmed.IndexOf('=')
        if ($idx -gt 0) { $ini[$section][$trimmed.Substring(0, $idx).Trim()] = $trimmed.Substring($idx + 1).Trim() } else { $ini[$section][$trimmed] = $null }
    }
    return , $ini
}

function Write-ADTIniFile
{
    param ([System.String]$LiteralPath, [System.Collections.IDictionary]$Ini)

    $sb = [System.Text.StringBuilder]::new()
    foreach ($section in $Ini.GetEnumerator())
    {
        if ($section.Key) { $null = $sb.AppendLine("[$($section.Key)]") }
        foreach ($kvp in $section.Value.GetEnumerator())
        {
            $null = if ($null -ne $kvp.Value) { $sb.AppendLine("$($kvp.Key)=$($kvp.Value)") } else { $sb.AppendLine($kvp.Key) }
        }
        $null = $sb.AppendLine()
    }
    $null = [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($LiteralPath))
    [System.IO.File]::WriteAllText($LiteralPath, $sb.ToString().TrimEnd() + [System.Environment]::NewLine)
}

function Get-ADTSystemdServices
{
    # Resolves -Name/-DisplayName/-InputObject (as used by the service functions) to SystemdService objects.
    param ([System.String]$ParameterSetName, [System.Collections.IDictionary]$BoundParameters)

    switch ($ParameterSetName)
    {
        'InputObject'
        {
            foreach ($svc in $BoundParameters.InputObject) { $svc.Refresh(); $svc }
            break
        }
        'DisplayName'
        {
            $units = [PSADT.ServiceManagement.SystemdService]::Systemctl('list-units', '--type=service', '--all', '--no-legend', '--plain', '--no-pager')
            foreach ($line in $units.Split("`n"))
            {
                if ($line -notmatch '^\s*(\S+\.service)\s+\S+\s+\S+\s+\S+\s+(.*)$') { continue }
                foreach ($pattern in $BoundParameters.DisplayName)
                {
                    if ($Matches[2].Trim() -like $pattern) { [PSADT.ServiceManagement.SystemdService]::new($Matches[1]); break }
                }
            }
            break
        }
        default
        {
            foreach ($name in $BoundParameters.Name)
            {
                if ($name.Contains('*'))
                {
                    $files = [PSADT.ServiceManagement.SystemdService]::Systemctl('list-unit-files', '--type=service', '--no-legend', '--no-pager', $(if ($name.EndsWith('.service')) { $name } else { "$name.service" }))
                    foreach ($line in $files.Split("`n")) { if ($line -match '^\s*(\S+\.service)\s') { [PSADT.ServiceManagement.SystemdService]::new($Matches[1]) } }
                    continue
                }
                $svc = [PSADT.ServiceManagement.SystemdService]::new($name)
                if (!$svc.Exists)
                {
                    $naerParams = @{
                        Exception = [System.InvalidOperationException]::new("Cannot find any service with service name '$name'.")
                        Category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                        ErrorId = 'NoServiceFoundForGivenName'
                        TargetObject = $name
                        RecommendedAction = "Please confirm the service name and try again."
                    }
                    throw (New-ADTErrorRecord @naerParams)
                }
                $svc
            }
        }
    }
}
