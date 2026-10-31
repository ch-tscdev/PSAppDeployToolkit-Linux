#-----------------------------------------------------------------------------
#
# MARK: Module state, config and string table handling (Linux port)
#
#-----------------------------------------------------------------------------

function Get-ADTModuleState
{
    if (!$Script:ADT.Initialized)
    {
        $naerParams = @{
            Exception = [System.InvalidOperationException]::new("Please ensure that [Initialize-ADTModule] is called before using any $($MyInvocation.MyCommand.Module.Name) functions.")
            Category = [System.Management.Automation.ErrorCategory]::InvalidOperation
            ErrorId = 'ADTModuleNotInitialized'
            TargetObject = $Script:ADT
            RecommendedAction = "Please ensure the module is initialized via [Initialize-ADTModule] and try again."
        }
        throw (New-ADTErrorRecord @naerParams)
    }
    return $Script:ADT
}

function Get-ADTDeploymentSessions
{
    return , $Script:ADT.Sessions
}

function Get-ADTModuleCallbacks
{
    return $Script:ADT.Callbacks
}

function Reset-ADTModuleState
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$Force
    )

    $Script:ADT.Sessions.Clear()
    $Script:ADT.Initialized = $false
    $Script:ADT.Config = $null
    $Script:ADT.Strings = $null
    $Script:ADT.Language = $null
    $Script:ADT.Environment = $null
    $Script:ADT.RestartOnExitOptions = $null
    $Script:ADT.Directories = [ordered]@{ Script = $null; Config = $null; Strings = $null }
    [PSAppDeployToolkit.Foundation.ModuleDatabase]::Config = $null
    [PSAppDeployToolkit.Foundation.ModuleDatabase]::Strings = $null
    [PSAppDeployToolkit.Foundation.ModuleDatabase]::Environment = $null
    if ($Force)
    {
        [PSAppDeployToolkit.Foundation.ModuleDatabase]::LastExitCode = $null
    }
}

function Get-ADTModuleDirectory
{
    return $Script:PSScriptRoot
}

function Get-ADTModuleDirectories
{
    return [PSCustomObject]$Script:ADT.Directories
}

function Out-ADTString
{
    [CmdletBinding()]
    [OutputType([System.String], [System.String[]])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowNull()][AllowEmptyString()][AllowEmptyCollection()]
        [System.Management.Automation.PSObject]$InputObject,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$Stream
    )

    end
    {
        $objects = if (!$PSCmdlet.MyInvocation.ExpectingInput) { $InputObject } else { $input }
        try
        {
            if ([System.String[]]$lines = $objects | Out-String -Width 16383 -Stream | & { process { $_.TrimEnd() } })
            {
                if ($Stream)
                {
                    return $lines
                }
                if (![System.String]::IsNullOrWhiteSpace(($res = [System.String]::Join([System.Environment]::NewLine, $lines))))
                {
                    return $res
                }
            }
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}

function Get-ADTCommand
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]$Name
    )

    if ($Script:CommandTable.ContainsKey($Name))
    {
        return $Script:CommandTable[$Name]
    }
    return Get-Command -Name $Name -ErrorAction Stop
}

function Set-ADTPreferenceVariables
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.SessionState]$SessionState,

        [Parameter(Mandatory = $false)]
        [System.UInt32]$Scope = 1
    )

    $stackParams = (Get-PSCallStack).InvocationInfo.BoundParameters.GetEnumerator().GetEnumerator()
    foreach ($pref in $Script:PreferenceVariableTable.GetEnumerator())
    {
        if (!($param = $stackParams | & { process { if ($_.Key.Equals($pref.Key)) { return @{ Name = $pref.Value; Value = $_.Value } } } } | Select-Object -First 1))
        {
            continue
        }
        if ($param.Value -is [System.Management.Automation.SwitchParameter])
        {
            if (!$param.Value)
            {
                continue
            }
            $param.Value = if ($pref.Key.Equals('WhatIf'))
            {
                $true
            }
            elseif ($pref.Key.Equals('Confirm'))
            {
                [System.Management.Automation.ConfirmImpact]::Low
            }
            else
            {
                [System.Management.Automation.ActionPreference]::Continue
            }
        }
        if ($SessionState.Equals($ExecutionContext.SessionState))
        {
            Set-Variable @param -Scope $Scope -Force -Confirm:$false -WhatIf:$false
        }
        else
        {
            $SessionState.PSVariable.Set($param.Name, $param.Value)
        }
    }
}

function Test-ADTNonNativeCaller
{
    # v3.x "AppDeployToolkitMain.ps1" compatibility mode is not part of the Linux port.
    return $false
}

function Import-ADTModuleDataFile
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]$LiteralPath
    )

    # The data files contain comments and literal hashtables only, so they're safe to evaluate in restricted language mode.
    $text = [System.IO.File]::ReadAllText($LiteralPath)
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($text, [ref]$null, [ref]$null)
    $hashAst = $ast.Find({ $args[0] -is [System.Management.Automation.Language.HashtableAst] }, $false)
    if (!$hashAst)
    {
        throw [System.IO.InvalidDataException]::new("The data file [$LiteralPath] does not contain a hashtable.")
    }
    return $hashAst.SafeGetValue()
}

function Merge-ADTHashtable
{
    param
    (
        [System.Collections.Hashtable]$Base,
        [System.Collections.Hashtable]$Overlay
    )

    foreach ($kvp in $Overlay.GetEnumerator())
    {
        if (($kvp.Value -is [System.Collections.Hashtable]) -and ($Base[$kvp.Key] -is [System.Collections.Hashtable]))
        {
            Merge-ADTHashtable -Base $Base[$kvp.Key] -Overlay $kvp.Value
        }
        else
        {
            $Base[$kvp.Key] = $kvp.Value
        }
    }
}

function Expand-ADTVariablesInHashtable
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]$Hashtable,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.SessionState]$SessionState
    )

    foreach ($section in @($Hashtable.GetEnumerator()))
    {
        if ($section.Value -is [System.Collections.Hashtable])
        {
            Expand-ADTVariablesInHashtable -Hashtable $section.Value -SessionState $SessionState
            continue
        }
        if (($section.Value -is [System.String]) -and $section.Value.Contains('$'))
        {
            if ($section.Value -match '\$\(|\$\{(?!env:)')
            {
                $naerParams = @{
                    Exception = [System.InvalidOperationException]::new("The value for [$($section.Key)] holds a subexpression or a braced provider path. A value may only name variables such as `$env:HOME.")
                    Category = [System.Management.Automation.ErrorCategory]::SecurityError
                    ErrorId = 'UnsafeStringExpansionValue'
                    TargetObject = $section.Value
                }
                throw (New-ADTErrorRecord @naerParams)
            }
            $Hashtable[$section.Key] = $SessionState.InvokeCommand.ExpandString($section.Value)
        }
    }
}

function Get-ADTDefaultConfig
{
    $config = Import-ADTModuleDataFile -LiteralPath "$Script:PSScriptRoot/Config/config.psd1"
    Expand-ADTVariablesInHashtable -Hashtable $config -SessionState $ExecutionContext.SessionState
    Update-ADTConfigAccessiblePaths -Config $config
    return $config
}

function Update-ADTConfigAccessiblePaths
{
    param
    (
        [System.Collections.Hashtable]$Config
    )

    # Mirror the original: callers without root rights use the "NoAdminRights" paths.
    if (![PSADT.AccountManagement.AccountUtilities]::CallerIsAdmin)
    {
        foreach ($section in 'Toolkit', 'MSI')
        {
            if (!$Config.ContainsKey($section)) { continue }
            foreach ($key in @($Config[$section].Keys))
            {
                if ($key.EndsWith('NoAdminRights') -and $Config[$section][$key])
                {
                    $Config[$section][$key.Replace('NoAdminRights', $null)] = $Config[$section][$key]
                }
            }
        }
    }
}

function Import-ADTConfig
{
    [CmdletBinding()]
    param
    (
        [AllowNull()][AllowEmptyCollection()]
        [System.IO.DirectoryInfo[]]$BaseDirectory,

        [System.Collections.IDictionary]$Environment
    )

    $config = Import-ADTModuleDataFile -LiteralPath "$Script:PSScriptRoot/Config/config.psd1"
    foreach ($directory in $BaseDirectory)
    {
        $file = Join-Path -Path $directory.FullName -ChildPath 'config.psd1'
        if (Test-Path -LiteralPath $file -PathType Leaf)
        {
            Merge-ADTHashtable -Base $config -Overlay (Import-ADTModuleDataFile -LiteralPath $file)
        }
    }

    # Expand variables in the context of the environment table, as the original does.
    $sb = {
        param($Environment, $Config, $Expander)
        foreach ($kvp in $Environment.GetEnumerator())
        {
            Set-Variable -Name $kvp.Key -Value $kvp.Value -Force
        }
        & $Expander -Hashtable $Config -SessionState $ExecutionContext.SessionState
    }
    & $sb -Environment $Environment -Config $config -Expander (Get-Command -Name Expand-ADTVariablesInHashtable)
    Update-ADTConfigAccessiblePaths -Config $config

    # Resolve base64/file assets relative to the config directory is a UI concern; nothing to do headless.
    return $config
}

function Get-ADTStringLanguage
{
    [CmdletBinding()]
    param
    (
        [System.Collections.IDictionary]$Environment,
        [System.Collections.IDictionary]$Config
    )

    if (!$Config)
    {
        $Config = if ($Script:ADT.Initialized) { $Script:ADT.Config } else { Get-ADTDefaultConfig }
    }
    if (!$PSBoundParameters.ContainsKey('Environment') -and $Script:ADT.Initialized -and $Script:ADT.Language)
    {
        return $Script:ADT.Language
    }
    if ($Config.UI.LanguageOverride)
    {
        return [System.Globalization.CultureInfo]::new($Config.UI.LanguageOverride)
    }
    $culture = [System.Globalization.CultureInfo]::CurrentUICulture
    if ([System.String]::IsNullOrWhiteSpace($culture.Name))
    {
        return [System.Globalization.CultureInfo]::new('en')
    }
    return $culture
}

function Import-ADTStringTable
{
    [CmdletBinding()]
    param
    (
        [AllowNull()][AllowEmptyCollection()]
        [System.IO.DirectoryInfo[]]$BaseDirectory,

        [System.Collections.IDictionary]$Config,

        [System.Globalization.CultureInfo]$UICulture
    )

    $root = "$Script:PSScriptRoot/Strings"
    $strings = Import-ADTModuleDataFile -LiteralPath "$root/strings.psd1"
    $candidates = @($UICulture.Name, $UICulture.TwoLetterISOLanguageName) | Select-Object -Unique
    foreach ($lang in $candidates)
    {
        if ($lang -and ($lang -ne 'en') -and (Test-Path -LiteralPath "$root/$lang/strings.psd1" -PathType Leaf))
        {
            Merge-ADTHashtable -Base $strings -Overlay (Import-ADTModuleDataFile -LiteralPath "$root/$lang/strings.psd1")
            break
        }
    }
    foreach ($directory in $BaseDirectory)
    {
        foreach ($file in @((Join-Path $directory.FullName 'strings.psd1')) + @($candidates | ? { $_ } | % { Join-Path $directory.FullName "$_/strings.psd1" }))
        {
            if (Test-Path -LiteralPath $file -PathType Leaf)
            {
                Merge-ADTHashtable -Base $strings -Overlay (Import-ADTModuleDataFile -LiteralPath $file)
            }
        }
    }

    # Replace {Section\Key} config placeholders, as the original's Expand-ADTConfigValuesInStringTable does.
    $expand = {
        param($Table)
        foreach ($kvp in @($Table.GetEnumerator()))
        {
            if ($kvp.Value -is [System.Collections.Hashtable])
            {
                & $expand $kvp.Value
            }
            elseif ($kvp.Value -is [System.String])
            {
                $Table[$kvp.Key] = [System.Text.RegularExpressions.Regex]::Replace($kvp.Value, '\{(\w+)\\(\w+)\}', {
                        param($m)
                        $value = $Config[$m.Groups[1].Value][$m.Groups[2].Value]
                        if ($null -ne $value) { [System.String]$value } else { $m.Value }
                    })
            }
        }
    }
    & $expand $strings
    return $strings
}

function Get-ADTDefaultStringTable
{
    [CmdletBinding()]
    param
    (
        [System.Globalization.CultureInfo]$UICulture,
        [System.Management.Automation.SessionState]$SessionState
    )

    if (!$UICulture)
    {
        $UICulture = Get-ADTStringLanguage
    }
    return Import-ADTStringTable -Config (Get-ADTDefaultConfig) -UICulture $UICulture
}

function Test-ADTCallerOwnsConfiguredPaths
{
    # On Linux the machine-wide paths are owned by root.
    return [PSADT.AccountManagement.AccountUtilities]::CallerIsAdmin
}
