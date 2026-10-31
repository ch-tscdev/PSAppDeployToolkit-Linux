#-----------------------------------------------------------------------------
#
# MARK: PSAppDeployToolkit for Linux - module bootstrap
#
# A headless Linux port of PSAppDeployToolkit 4.2. All public functions keep
# the original names, parameters and output types. Requires PowerShell 7.4+.
#
#-----------------------------------------------------------------------------

$ModuleImportStart = [System.DateTime]::Now

try
{
    if (!$IsLinux)
    {
        throw [System.PlatformNotSupportedException]::new("This build of PSAppDeployToolkit targets Linux. On Windows, please use the official PSAppDeployToolkit release.")
    }

    # Build out lookup table for all cmdlets used within the module (same approach as the original).
    $CommandTable = [System.Collections.Generic.Dictionary[System.String, System.Management.Automation.CommandInfo]]::new()
    $ExecutionContext.SessionState.InvokeCommand.GetCmdlets() | & { process { if ($_.PSSnapIn -and $_.PSSnapIn.Name.Equals('Microsoft.PowerShell.Core') -and $_.PSSnapIn.IsDefault) { $CommandTable.Add($_.Name, $_) } } }
    $ImportedModules = Import-Module -Global -Force -PassThru -ErrorAction Stop -Name Microsoft.PowerShell.Archive, Microsoft.PowerShell.Management, Microsoft.PowerShell.Security, Microsoft.PowerShell.Utility
    $ImportedModules.ExportedCommands.Values | & { process { if (!$_.CommandType.Equals([System.Management.Automation.CommandTypes]::Alias) -and !$CommandTable.ContainsKey($_.Name)) { $CommandTable.Add($_.Name, $_) } } }

    # Set required variables to ensure module functionality.
    New-Variable -Name ErrorActionPreference -Value ([System.Management.Automation.ActionPreference]::Stop) -Option Constant -Force
    New-Variable -Name InformationPreference -Value ([System.Management.Automation.ActionPreference]::Continue) -Option Constant -Force
    New-Variable -Name ProgressPreference -Value ([System.Management.Automation.ActionPreference]::SilentlyContinue) -Option Constant -Force
    Set-StrictMode -Version 3

    # Load the .NET type surface (PSADT.* / PSAppDeployToolkit.* types re-implemented for Linux).
    $assemblyPath = "$PSScriptRoot/lib/PSAppDeployToolkit.Linux.dll"
    if (!('PSAppDeployToolkit.Foundation.DeploymentSession' -as [System.Type]))
    {
        if ([System.Environment]::Version.Major -ge 9)
        {
            # The precompiled assembly targets the .NET 9 runtime of PowerShell 7.5+.
            Add-Type -LiteralPath $assemblyPath
        }
        else
        {
            # Older runtimes (PowerShell 7.4/.NET 8): compile the same sources in memory instead.
            $refs = @([psobject].Assembly.Location) + @(
                'System.Collections', 'System.Collections.Concurrent', 'System.Collections.NonGeneric', 'System.Collections.Specialized', 'System.ComponentModel', 'System.ComponentModel.Primitives',
                'System.Console', 'System.Diagnostics.Process', 'System.Diagnostics.StackTrace', 'System.Diagnostics.TraceSource', 'System.IO.Compression', 'System.IO.Compression.ZipFile',
                'System.Linq', 'System.Linq.Expressions', 'System.Memory', 'System.ObjectModel', 'System.Private.CoreLib', 'System.Runtime', 'System.Runtime.InteropServices',
                'System.Runtime.Serialization.Primitives', 'System.Security.Principal', 'System.Security.Principal.Windows', 'System.ServiceProcess.ServiceController', 'System.Text.Encoding.Extensions',
                'System.Text.Encodings.Web', 'System.Text.Json', 'System.Text.RegularExpressions', 'System.Threading', 'System.Threading.Tasks', 'System.Threading.Thread'
            )
            Add-Type -Path (Get-ChildItem -LiteralPath "$PSScriptRoot/lib/src" -Filter *.cs).FullName -ReferencedAssemblies $refs -IgnoreWarnings
        }
    }

    # Dot-source our private and public functions.
    foreach ($file in (Get-ChildItem -LiteralPath "$PSScriptRoot/Private", "$PSScriptRoot/Public" -Filter *.ps1 -File))
    {
        . $file.FullName
    }

    # Module-wide constants used by functions taken verbatim from the original.
    New-Variable -Name PowerShellCommonParameters -Option Constant -Value ([System.Collections.Generic.HashSet[System.String]]::new([System.String[]]$([System.Management.Automation.PSCmdlet]::CommonParameters; [System.Management.Automation.PSCmdlet]::OptionalCommonParameters), [System.StringComparer]::Ordinal))
    New-Variable -Name PreferenceVariableTable -Option Constant -Value ([ordered]@{
            InformationAction = 'InformationPreference'
            ProgressAction = 'ProgressPreference'
            WarningAction = 'WarningPreference'
            Confirm = 'ConfirmPreference'
            Verbose = 'VerbosePreference'
            WhatIf = 'WhatIfPreference'
            Debug = 'DebugPreference'
        }).AsReadOnly()

    # Module state (the original keeps this in its C# ModuleDatabase).
    $callbacks = [ordered]@{}
    foreach ($hookpoint in [System.Enum]::GetNames([PSAppDeployToolkit.Foundation.CallbackType]))
    {
        $callbacks.Add($hookpoint, [System.Collections.Generic.List[System.Management.Automation.CommandInfo]]::new())
    }
    New-Variable -Name ADT -Option Constant -Value ([PSCustomObject]@{
            Initialized = $false
            Sessions = [System.Collections.Generic.List[PSAppDeployToolkit.Foundation.DeploymentSession]]::new()
            Callbacks = [PSCustomObject]$callbacks
            Config = $null
            Strings = $null
            Language = $null
            Environment = $null
            Directories = [ordered]@{ Script = $null; Config = $null; Strings = $null }
            RestartOnExitOptions = $null
            ImportStart = $ModuleImportStart
            ImportDuration = [System.TimeSpan]::Zero
            InitDuration = [System.TimeSpan]::Zero
        })

    # Host output and caller resolution for the C# logging engine.
    [PSAppDeployToolkit.Foundation.ModuleDatabase]::DefaultConfig = Get-ADTDefaultConfig
    [PSAppDeployToolkit.Foundation.ModuleDatabase]::HostWriter = {
        param ([System.String[]]$Lines, [System.Int32]$Severity, [System.Int32]$StreamType)
        if ($StreamType -eq 3)
        {
            if ($Severity -ge 2) { $Lines | & $Script:CommandTable.'Write-Warning' } else { $Lines | & $Script:CommandTable.'Write-Verbose' }
            return
        }
        $colours = switch ($Severity) { 0 { @{ ForegroundColor = 'Green' } } 2 { @{ ForegroundColor = 'Yellow' } } 3 { @{ ForegroundColor = 'Red' } } default { @{} } }
        $Lines | & $Script:CommandTable.'Write-Host' @colours
    }
    [PSAppDeployToolkit.Foundation.ModuleDatabase]::CallerResolver = {
        $frame = Get-PSCallStack | Select-Object -Skip 1 | & {
            process
            {
                $command = $_.Command
                if (![System.String]::IsNullOrWhiteSpace($command) -and (($command -notmatch '^(Write-(Log|ADTLogEntry)|New-ADTDeploymentSession|Initialize-ADTDeploymentSession|Write-ADTHeadlessBypass|<ScriptBlock>(<\w+>)?)$') -or (($command -match '^(<ScriptBlock>(<\w+>)?)$') -and ($_.Location -match '^<.+>$'))))
                {
                    return $_
                }
            }
        } | Select-Object -First 1
        if ($frame)
        {
            , @($(if ($frame.ScriptName) { $frame.ScriptName } else { $frame.Location }), $frame.Command)
        }
    }

    # Add our own functions to the command table.
    Get-ChildItem -LiteralPath Function: | & { process { if ($_.Name -like '*-ADT*') { $CommandTable[$_.Name] = $_ } } }
    $ADT.ImportDuration = [System.DateTime]::Now - $ModuleImportStart

    # Export the public functions.
    Export-ModuleMember -Function (Get-ChildItem -LiteralPath "$PSScriptRoot/Public" -Filter *.ps1 -File).BaseName
}
catch
{
    throw
}
