#-----------------------------------------------------------------------------
#
# MARK: Deployment session construction (Linux port of DeploymentSession's constructor)
#
#-----------------------------------------------------------------------------

function New-ADTDeploymentSession
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$Parameters,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$NoExitOnClose,

        [Parameter(Mandatory = $false)]
        [System.Type]$SessionClass = [PSAppDeployToolkit.Foundation.DeploymentSession]
    )

    $adtEnv = Get-ADTEnvironmentTable
    $adtConfig = Get-ADTConfig
    $toolkitName = $adtEnv.appDeployToolkitName
    $values = @{}
    foreach ($kvp in $Parameters.GetEnumerator())
    {
        $values[$kvp.Key] = $kvp.Value
    }
    if ($values.ContainsKey('DeployAppScriptParameters') -and ($values['DeployAppScriptParameters'] -is [System.Collections.IDictionary]))
    {
        $copy = [System.Collections.Generic.Dictionary[System.String, System.Object]]::new([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($kvp in $values['DeployAppScriptParameters'].GetEnumerator()) { $copy[$kvp.Key] = $kvp.Value }
        $values['DeployAppScriptParameters'] = $copy
    }
    $values['CurrentDateTime'] = [System.DateTime]::Now
    $values['DeploymentType'] = if ($Parameters.ContainsKey('DeploymentType')) { $Parameters.DeploymentType } else { [PSAppDeployToolkit.Foundation.DeploymentType]::Install }
    $values['RequestedDeployMode'] = if ($Parameters.ContainsKey('DeployMode')) { $Parameters.DeployMode } else { [PSAppDeployToolkit.Foundation.DeployMode]::Auto }

    # Application properties. Without an AppName (and no MSI zero-config on Linux), fall back like the original does.
    if ([System.String]::IsNullOrWhiteSpace($values['AppName']))
    {
        $values['AppName'] = $toolkitName
        $values.Remove('AppVendor')
        if ([System.String]::IsNullOrWhiteSpace($values['AppVersion'])) { $values['AppVersion'] = $adtEnv.appDeployMainScriptVersion.ToString() }
        if ([System.String]::IsNullOrWhiteSpace($values['AppLang'])) { $values['AppLang'] = $adtEnv.currentLanguage }
        if ([System.String]::IsNullOrWhiteSpace($values['AppRevision'])) { $values['AppRevision'] = '01' }
    }

    # Install title/name.
    $invalidChars = "[$([System.Text.RegularExpressions.Regex]::Escape([System.String]::new(([System.IO.Path]::GetInvalidFileNameChars() + [System.Char[]]'\/:*?"<>|'))))]"
    if ([System.String]::IsNullOrWhiteSpace($values['InstallTitle']))
    {
        $values['InstallTitle'] = "$($values['AppVendor']) $($values['AppName']) $($values['AppVersion'])".Trim()
    }
    $values['InstallTitle'] = $values['InstallTitle'] -replace '\s{2,}', ' '
    if ([System.String]::IsNullOrWhiteSpace($values['InstallName']))
    {
        $values['InstallName'] = "$($values['AppVendor'])_$($values['AppName'])_$($values['AppVersion'])_$($values['AppArch'])_$($values['AppLang'])_$($values['AppRevision'])"
    }
    $values['InstallName'] = (($values['InstallName'].Trim('_').Replace(' ', $null)) -replace '_{2,}', '_') -replace $invalidChars, ''

    # Logging setup.
    $configLogPath = $adtConfig.Toolkit.LogPath
    $values['ConfigLogPath'] = $configLogPath
    $values['CompressLogs'] = [System.Boolean]$adtConfig.Toolkit.CompressLogs
    $logPath = if ($values['CompressLogs'])
    {
        $tempLogs = Join-Path -Path $adtEnv.envTemp -ChildPath "$($values['InstallName'])_$($values['DeploymentType'])"
        if (Test-Path -LiteralPath $tempLogs) { Remove-Item -LiteralPath $tempLogs -Recurse -Force }
        [System.IO.Directory]::CreateDirectory($tempLogs).FullName
    }
    else
    {
        [System.IO.Directory]::CreateDirectory($configLogPath).FullName
    }
    if ($adtConfig.Toolkit.LogToHierarchy)
    {
        $logPath = [System.IO.Directory]::CreateDirectory((Join-Path -Path $logPath -ChildPath ((@($values['AppVendor'], $values['AppName'], $values['AppVersion']) | & { process { if ($_) { $_ } } }) -join '/'))).FullName
        $siblings = @([System.IO.DirectoryInfo]::new($logPath).Parent.GetDirectories() | & { process { if ($_.FullName -ne $logPath) { $_ } } } | Sort-Object -Property CreationTime)
        if ($siblings.Count -gt $adtConfig.Toolkit.LogMaxHierarchy)
        {
            $siblings | Select-Object -First ($siblings.Count - $adtConfig.Toolkit.LogMaxHierarchy) | Remove-Item -Recurse -Force
        }
    }
    elseif ($adtConfig.Toolkit.LogToSubfolder)
    {
        $logPath = [System.IO.Directory]::CreateDirectory((Join-Path -Path $logPath -ChildPath "$($values['InstallName'])_$($values['DeploymentType'])")).FullName
    }
    $callerOwnsLogPath = [PSADT.AccountManagement.AccountUtilities]::CallerIsAdmin
    $values['LogPath'] = $logPath
    $values['DefaultLogName'] = "$($values['InstallName'])_%%DISCRIMINATOR%%_$($values['DeploymentType'])$(if (!$callerOwnsLogPath) { "_$($adtEnv.envUserName)" }).log" -replace $invalidChars, ''
    $values['LogName'] = if (![System.String]::IsNullOrWhiteSpace($values['LogName'])) { $values['LogName'] -replace $invalidChars, '' } else { $values['DefaultLogName'].Replace('%%DISCRIMINATOR%%', $toolkitName) }
    $values['LogStyle'] = $adtConfig.Toolkit.LogStyle
    $values['LogWriteToHost'] = [System.Boolean]$adtConfig.Toolkit.LogWriteToHost
    $values['LogHostOutputToStdStreams'] = [System.Boolean]$adtConfig.Toolkit.LogHostOutputToStdStreams
    $values['LogMaxHistory'] = $adtConfig.Toolkit.LogMaxHistory
    $values['DeferHistoryPath'] = Join-Path -Path $adtConfig.Toolkit.RegPath -ChildPath "$toolkitName/DeferHistory"
    $values['DefaultExitCode'] = $adtConfig.UI.DefaultExitCode
    $values['DeferExitCode'] = $adtConfig.UI.DeferExitCode
    $values['NoExitOnClose'] = [System.Boolean]$NoExitOnClose

    # Log rotation (LogAppend / LogMaxSize), as the original does before the first write.
    $script:ADTPendingLogMessages = [System.Collections.Generic.List[System.Object[]]]::new()
    $logFile = [System.IO.FileInfo]::new((Join-Path -Path $logPath -ChildPath $values['LogName']))
    $logMaxSize = [System.Int32]$adtConfig.Toolkit.LogMaxSize
    $sizeExceeded = $logFile.Exists -and ($logMaxSize -gt 0) -and (($logFile.Length / 1MB) -gt $logMaxSize)
    if (($logFile.Exists -and !$adtConfig.Toolkit.LogAppend) -or $sizeExceeded)
    {
        try
        {
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($values['LogName'])
            $extension = [PSAppDeployToolkit.Logging.LogUtilities]::LogFileNameRegex.Match($values['LogName']).Value
            $archiveName = "$($baseName)_$([System.DateTime]::Now.ToString('O').Split('.')[0].Replace(':', ''))$extension"
            if ($sizeExceeded)
            {
                $script:ADTPendingLogMessages.Add(@("Maximum log file size [$logMaxSize MB] reached. Rename log file to [$archiveName].", 2))
            }
            $logFile.MoveTo((Join-Path -Path $logPath -ChildPath $archiveName))
            $logFiles = @(Get-ChildItem -LiteralPath $logPath -Filter "$baseName*$extension" -File | Sort-Object -Property LastWriteTime)
            if ($logFiles.Count -gt $values['LogMaxHistory'])
            {
                $logFiles | Select-Object -First ($logFiles.Count - $values['LogMaxHistory']) | Remove-Item -Force
            }
        }
        catch
        {
            $script:ADTPendingLogMessages.Add(@("Failed to rotate the log file [$logFile]: $_", 3))
        }
    }

    # Determine the deployment mode. There is no user interface on Linux, so 'Auto' always resolves to 'Silent'.
    $requested = $values['RequestedDeployMode']
    if ($requested -eq [PSAppDeployToolkit.Foundation.DeployMode]::Auto)
    {
        $values['DeployMode'] = [PSAppDeployToolkit.Foundation.DeployMode]::Silent
        $script:ADTPendingLogMessages.Add(@("No graphical user interface is available on Linux, changing deployment mode to [Silent].", 1))
    }
    else
    {
        $values['DeployMode'] = $requested
        if ($requested -ne [PSAppDeployToolkit.Foundation.DeployMode]::Silent)
        {
            $script:ADTPendingLogMessages.Add(@("Deployment mode was explicitly set to [$requested]. No dialogs can be shown on Linux; UI functions will run headless.", 2))
        }
    }

    # Instantiate the session object.
    return $SessionClass::new($values)
}

function Initialize-ADTDeploymentSession
{
    # Writes the session start-up information to the log, mirroring the original's constructor output.
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [PSAppDeployToolkit.Foundation.DeploymentSession]$Session,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$Parameters
    )

    $adtEnv = Get-ADTEnvironmentTable
    $toolkitName = $adtEnv.appDeployToolkitName
    $divider = '-------------------------------------------------------------------------------'
    $Session.WriteLogEntry($divider)
    $Session.WriteLogEntry($divider)
    foreach ($pending in $script:ADTPendingLogMessages)
    {
        if ($pending[1] -ne 1) { $Session.WriteLogEntry($pending[0], [PSAppDeployToolkit.Logging.LogSeverity]$pending[1]) }
    }
    $Session.WriteLogEntry("[$($Session.InstallName)] $($Session.DeploymentType.ToString().ToLowerInvariant()) started.")

    # Script information.
    if ($Session.AppScriptVersion)
    {
        $Session.WriteLogEntry("[$($Session.InstallName)] script version is [$($Session.AppScriptVersion)].")
    }
    if ($Session.AppScriptDate -and ($Session.AppScriptDate.ToString('yyyy-MM-dd') -ne '2000-12-31'))
    {
        $Session.WriteLogEntry("[$($Session.InstallName)] script date is [$($Session.AppScriptDate.ToString('yyyy-MM-dd'))].")
    }
    if ($Session.AppScriptAuthor -and ($Session.AppScriptAuthor -ne '<author name>'))
    {
        $Session.WriteLogEntry("[$($Session.InstallName)] script author is [$($Session.AppScriptAuthor)].")
    }
    if ($Session.DeployAppScriptFriendlyName)
    {
        if ($Session.DeployAppScriptVersion)
        {
            $Session.WriteLogEntry("[$($Session.DeployAppScriptFriendlyName)] script version is [$($Session.DeployAppScriptVersion)].")
        }
        if ($Session.DeployAppScriptParameters.Count)
        {
            $argList = [PSAppDeployToolkit.Utilities.PowerShellUtilities]::ConvertBoundParametersToArgumentList($Session.DeployAppScriptParameters)
            $Session.WriteLogEntry("The following parameters were passed to [$($Session.DeployAppScriptFriendlyName)]: [$([PSADT.ProcessManagement.CommandLineUtilities]::ArgumentListToCommandLine($argList))].")
        }
    }
    $Session.WriteLogEntry("[$toolkitName] module version is [$($adtEnv.appDeployMainScriptVersion)] (Linux port).")
    $Session.WriteLogEntry("[$toolkitName] module imported in [$($Script:ADT.ImportDuration.TotalSeconds)] seconds.")
    $Session.WriteLogEntry("[$toolkitName] module initialized in [$($Script:ADT.InitDuration.TotalSeconds)] seconds.")
    $Session.WriteLogEntry("[$toolkitName] module path is ['$($adtEnv.appDeployToolkitPath)'].")
    if ($Script:ADT.Directories.Config)
    {
        $Session.WriteLogEntry("[$toolkitName] config path is ['$([System.String]::Join("', '", $Script:ADT.Directories.Config))'].")
    }
    if ($Script:ADT.Directories.Strings)
    {
        $Session.WriteLogEntry("[$toolkitName] string path is ['$([System.String]::Join("', '", $Script:ADT.Directories.Strings))'].")
    }
    $Session.WriteLogEntry("[$toolkitName] session mode is [Native].")

    # System information.
    $Session.WriteLogEntry("Computer Name is [$($adtEnv.envComputerNameFQDN)].")
    $Session.WriteLogEntry("Current User is [$($adtEnv.ProcessNTAccount)].")
    $Session.WriteLogEntry("OS Version is [$($adtEnv.envOSName) $($adtEnv.envOSArchitecture) $($adtEnv.envOSVersion)] (kernel $($adtEnv.envKernelVersion)).")
    $Session.WriteLogEntry("OS Type is [$($adtEnv.envOSProductTypeName)].")
    if ($adtEnv.envHardwareType)
    {
        $Session.WriteLogEntry("Hardware Platform is [$($adtEnv.envHardwareType)].")
    }
    $Session.WriteLogEntry("Current Culture is [$($adtEnv.culture)], language is [$($adtEnv.currentLanguage)] and UI language is [$($adtEnv.currentUILanguage)].")
    $Session.WriteLogEntry("PowerShell Host is [$($adtEnv.envHost.Name)] with version [$($adtEnv.envHostVersion)].")
    $Session.WriteLogEntry("PowerShell Version is [$($adtEnv.envPSVersion) $($adtEnv.psArchitecture)].")
    $Session.WriteLogEntry("PowerShell Process Path is [$($adtEnv.envPSProcessPath)].")
    $Session.WriteLogEntry("PowerShell CLR (.NET) version is [$($adtEnv.envCLRVersion)].")

    # User information.
    if ($adtEnv.usersLoggedOn)
    {
        $Session.WriteLogEntry("The following users are logged on to the system: [$([System.String]::Join(', ', $adtEnv.usersLoggedOn))].")
        $Session.WriteLogEntry("Session information for all logged on users:`n`n$([System.String]::Join("`n`n", $adtEnv.LoggedOnUserSessions))", $false)
        if ($adtEnv.CurrentLoggedOnUserSession)
        {
            $Session.WriteLogEntry("Current process is running with user account [$($adtEnv.ProcessNTAccount)] under logged on user session for [$($adtEnv.CurrentLoggedOnUserSession.NTAccount)].")
        }
        else
        {
            $Session.WriteLogEntry("Current process is running under a system account [$($adtEnv.ProcessNTAccount)].")
        }
        if ($adtEnv.CurrentConsoleUserSession)
        {
            $Session.WriteLogEntry("The following user is the console user [$($adtEnv.CurrentConsoleUserSession.NTAccount)] (user with control of physical monitor, keyboard, and mouse).")
        }
        else
        {
            $Session.WriteLogEntry('There is no console user logged on (user with control of physical monitor, keyboard, and mouse).')
        }
    }
    else
    {
        $Session.WriteLogEntry('No users are logged on to the system.')
    }
    $Session.WriteLogEntry("The current execution context has a primary UI language of [$($adtEnv.uiculture)].")
    if ((Get-ADTConfig).UI.LanguageOverride)
    {
        $Session.WriteLogEntry("The config file was configured to override the detected primary UI language with the following UI language: [$((Get-ADTConfig).UI.LanguageOverride)].")
    }
    $Session.WriteLogEntry("The following locale was used to import UI messages from the strings.psd1 files: [$($Script:ADT.Language)].")

    # Deployment properties.
    foreach ($pending in $script:ADTPendingLogMessages)
    {
        if ($pending[1] -eq 1) { $Session.WriteLogEntry($pending[0]) }
    }
    if ($Session.AppProcessesToClose.Count)
    {
        $running = [PSADT.ProcessManagement.RunningProcessInfo]::Get($Session.AppProcessesToClose)
        if ($running.Count)
        {
            $Session.WriteLogEntry("The processes ['$([System.String]::Join("', '", ($running | & { process { $_.FileName.Name } } | Select-Object -Unique)))'] were found to be running and will require closure.")
        }
        else
        {
            $Session.WriteLogEntry("The processes ['$([System.String]::Join("', '", $Session.AppProcessesToClose.Name))'] were specified as requiring closure but none were running.")
        }
    }
    $Session.WriteLogEntry("Deployment is running in [$($Session.DeployMode)] mode.")
    $Session.WriteLogEntry("Deployment type is [$($Session.DeploymentType)].")

    # Session viability.
    if ($Session.RequireAdmin -and !$adtEnv.IsAdmin)
    {
        throw [System.UnauthorizedAccessException]::new("This deployment requires administrative permissions and the current user is not root. Please re-run the deployment script as root (e.g. via sudo) and try again.")
    }
    if ($Session.TerminalServerMode)
    {
        $Session.WriteLogEntry('The [-TerminalServerMode] parameter was specified but system is not a terminal server.', [PSAppDeployToolkit.Logging.LogSeverity]::Warning)
    }
}
