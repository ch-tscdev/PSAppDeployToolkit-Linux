#-----------------------------------------------------------------------------
#
# MARK: Get-ADTUserProfiles
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: Linux implementation.
#
#-----------------------------------------------------------------------------
function Get-ADTUserProfiles
{
    <#
    .SYNOPSIS
        Get the User Profile Path, User Account SID, and the User Account Name for all users that log onto the machine and also the Default User.

    .DESCRIPTION
        The `Get-ADTUserProfiles` function gets the User Profile Path, User Account SID, and the User Account Name for all users that log onto the machine and also the Default User (which does not log on).

        Please note that the NTAccount property may be empty for some user profiles but the SID and ProfilePath properties will always be populated.

    .PARAMETER FilterScript
        Allows filtration of the returned result by any property in a UserProfileInfo object.

    .PARAMETER SID
        Specifies the SID to get rather than returning all user profiles.

    .PARAMETER ExcludeNTAccount
        Specify NT account names in DOMAIN\username format to exclude from the list of user profiles.

    .PARAMETER IncludeSystemProfiles
        Include system profiles: SYSTEM, LOCAL SERVICE, NETWORK SERVICE.

    .PARAMETER IncludeServiceProfiles
        Include service (NT SERVICE) profiles.

    .PARAMETER IncludeIISAppPoolProfiles
        Include IIS AppPool profiles. Excluded by default as they don't parse well.

    .PARAMETER IncludeEpmProfiles
        Include Endpoint Privilege Management (EPM) profiles. Excluded by default as they don't parse well.

    .PARAMETER ExcludeDefaultUser
        Exclude the Default User.

    .PARAMETER LoadProfilePaths
        Load additional profile paths for each user profile.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        PSADT.AccountManagement.UserProfileInfo

        Returns a UserProfileInfo object with the following properties:
        - NTAccount
        - SID
        - ProfilePath
        - AppDataPath
        - LocalAppDataPath
        - DesktopPath
        - DocumentsPath
        - StartMenuPath
        - TempPath
        - OneDrivePath
        - OneDriveCommercialPath
        - UserLocale

    .EXAMPLE
        Get-ADTUserProfiles

        Return a UserProfileInfo object for each user profile on the system.

    .EXAMPLE
        Get-ADTUserProfiles -ExcludeNTAccount CONTOSO\Robot,CONTOSO\ntadmin

        Return a UserProfileInfo object for each user profile on the system, except for 'Robot' and 'ntadmin'.

    .EXAMPLE
        [string[]]$ProfilePaths = Get-ADTUserProfiles | Select-Object -ExpandProperty ProfilePath

        Return the user profile path for each user on the system. This information can then be used to make modifications under the user profile on the filesystem.

    .NOTES
        An active ADT session is NOT required to use this function.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Get-ADTUserProfiles

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Get-ADTUserProfiles.ps1
    #>

    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'ExcludeNTAccount', Justification = "This parameter is used within delegates that PSScriptAnalyzer has no visibility of. See https://github.com/PowerShell/PSScriptAnalyzer/issues/1472 for more details.")]
    [CmdletBinding(DefaultParameterSetName = 'All')]
    [OutputType([PSADT.AccountManagement.UserProfileInfo])]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'FilterScript', Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.ScriptBlock]$FilterScript,

        [Parameter(Mandatory = $true, ParameterSetName = 'Specific')]
        [ValidateNotNullOrEmpty()]
        [PSAppDeployToolkit.Attributes.ValidateUnique()]
        [PSADT.AccountManagement.UnixIdentity[]]$SID,

        [Parameter(Mandatory = $false, ParameterSetName = 'All')]
        [ValidateNotNullOrEmpty()]
        [PSADT.AccountManagement.UnixIdentity[]]$ExcludeNTAccount,

        [Parameter(Mandatory = $false, ParameterSetName = 'All')]
        [System.Management.Automation.SwitchParameter]$IncludeSystemProfiles,

        [Parameter(Mandatory = $false, ParameterSetName = 'All')]
        [System.Management.Automation.SwitchParameter]$IncludeServiceProfiles,

        [Parameter(Mandatory = $false, ParameterSetName = 'All')]
        [System.Management.Automation.SwitchParameter]$IncludeIISAppPoolProfiles,

        [Parameter(Mandatory = $false, ParameterSetName = 'All')]
        [System.Management.Automation.SwitchParameter]$IncludeEpmProfiles,

        [Parameter(Mandatory = $false, ParameterSetName = 'All')]
        [System.Management.Automation.SwitchParameter]$ExcludeDefaultUser,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$LoadProfilePaths
    )

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
}
