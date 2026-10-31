#requires -Version 7.4
<#
    Generates the Public/*.ps1 files of the Linux port.

    For every public function of the original PSAppDeployToolkit, the comment-based help,
    [CmdletBinding()]/[OutputType()] attributes, the complete param() block and any
    dynamicparam{} block are copied verbatim from the original source. Only the body is
    replaced:
      * bodies/<Name>.ps1 exists      -> Linux implementation (begin/process/end text)
      * name listed in $Verbatim      -> original body (platform-neutral PowerShell)
      * otherwise                     -> standard "not supported on Linux" body
#>
param
(
    [Parameter(Mandatory = $true)][string]$OriginalModule,
    [Parameter(Mandatory = $true)][string]$BodiesPath,
    [Parameter(Mandatory = $true)][string]$OutputPath,
    [Parameter(Mandatory = $false)][string]$StatusCsvPath = "$PSScriptRoot/FUNCTION-STATUS.csv"
)
$ErrorActionPreference = 'Stop'

# Original bodies that are pure, platform-neutral PowerShell.
$Verbatim = @(
    'Add-ADTModuleCallback', 'Clear-ADTModuleCallback', 'Close-ADTSession', 'Complete-ADTFunction',
    'Convert-ADTValuesFromRemainingArguments', 'Get-ADTBoundParametersAndDefaultValues', 'Get-ADTConfig',
    'Get-ADTDeferHistory', 'Get-ADTEnvironmentTable', 'Get-ADTModuleCallback', 'Get-ADTObjectProperty',
    'Get-ADTSession', 'Initialize-ADTFunction', 'Invoke-ADTCommandWithRetries', 'Invoke-ADTFunctionErrorHandler',
    'Invoke-ADTObjectMethod', 'New-ADTErrorRecord', 'New-ADTLogFileName', 'New-ADTValidateScriptErrorRecord',
    'Out-ADTPowerShellEncodedCommand', 'Remove-ADTHashtableNullOrEmptyValues', 'Remove-ADTInvalidFileNameChars',
    'Remove-ADTModuleCallback', 'Reset-ADTDeferHistory', 'Select-ADTUniqueObject', 'Set-ADTDeferHistory',
    'Set-ADTPowerShellCulture', 'Test-ADTSessionActive', 'Write-ADTLogEntry', 'Get-ADTFreeDiskSpace',
    'Test-ADTNetworkConnection', 'Test-ADTMutexAvailability', 'Resolve-ADTErrorRecord', 'Get-ADTFileVersion', 'Start-ADTProcessAsUser', 'Get-ADTRunningProcesses',
    'Convert-ADTValueType', 'Remove-ADTFileFromUserProfiles', 'Remove-ADTContentFromCache', 'Copy-ADTFile', 'New-ADTFolder',
    'Remove-ADTFile', 'Remove-ADTFolder', 'Get-ADTPEFileArchitecture', 'Get-ADTExecutableInfo'
)

# Types that cannot be constructed on Linux are swapped for Linux equivalents (parameter names are unchanged).
$TypeMap = [ordered]@{
    'System.Security.Principal.NTAccount'      = 'PSADT.AccountManagement.UnixIdentity'
    'System.Security.Principal.SecurityIdentifier' = 'PSADT.AccountManagement.UnixIdentity'
    'System.ServiceProcess.ServiceController'  = 'PSADT.ServiceManagement.SystemdService'
    'Microsoft.Dism.Commands.ImageObject'      = 'System.Object'
    'System.__ComObject'                       = 'System.Object'
    'Windows.UI.Notifications.ToastNotificationMode' = 'System.String'
}

# Default values that reference Windows-only locations or commands.
$HeaderPatches = @{
    'Get-ADTFreeDiskSpace' = @(, @('[System.IO.Path]::GetPathRoot([System.Environment]::SystemDirectory)', "'/'"))
    'Unblock-ADTAppExecution' = @(, @('(Get-ScheduledTask -TaskName "$($MyInvocation.MyCommand.Module.Name)_*_BlockedApps" -ErrorAction Ignore)', '$null'))
    'Copy-ADTContentToCache' = @(, @('"$((Get-ADTConfig).Toolkit.CachePath)\$((Get-ADTSession).InstallName)"', '"$((Get-ADTConfig).Toolkit.CachePath)/$((Get-ADTSession).InstallName)"'))
    'Remove-ADTContentFromCache' = @(, @('"$((Get-ADTConfig).Toolkit.CachePath)\$((Get-ADTSession).InstallName)"', '"$((Get-ADTConfig).Toolkit.CachePath)/$((Get-ADTSession).InstallName)"'))
}

# Original bodies that only need small Linux adjustments (applied as exact text replacements).
$BodyPatches = @{
    'Copy-ADTContentToCache' = @(
        @(".TrimEnd('\')", ".TrimEnd('/')"),
        @('.StartsWith("$cachePath\",', '.StartsWith("$cachePath/",'),
        @('$builtinAdministratorsSid = [System.Security.Principal.SecurityIdentifier]::new([System.Security.Principal.WellKnownSidType]::BuiltinAdministratorsSid, $null).Value', '# Linux: the root cache folder is owned by root and not writable by other users.'),
        @('Set-ADTItemPermission -LiteralPath $cachePath -Owner "*$builtinAdministratorsSid" -EnableInheritance -RemoveExplicitRules -InformationAction SilentlyContinue', '$null = Invoke-ADTNativeCommand -FilePath chown -ArgumentList ''root:root'', $cachePath; $null = Invoke-ADTNativeCommand -FilePath chmod -ArgumentList ''0755'', $cachePath')
    )
    'New-ADTZipFile' = @(
        , @('Set-Acl -LiteralPath $DestinationPath -AclObject (Get-Acl -LiteralPath $parentPath)', '$null = Invoke-ADTNativeCommand -FilePath chmod -ArgumentList ''--reference'', $parentPath, ''--'', $DestinationPath')
    )
    'Remove-ADTDesktopShortcut' = @(
        @('Path = $adtEnv.envCommonDesktop', 'Path = @((Get-ADTUserProfiles -ExcludeDefaultUser -InformationAction SilentlyContinue).DesktopPath | & { process { if ($_) { $_.FullName } } })'),
        @('$contents = Get-ChildItem -LiteralPath ($desktopPath = $scopeTable.$desktop.Path) -Filter *.lnk', '$contents = if (($desktopPath = $scopeTable.$desktop.Path)) { Get-ChildItem -LiteralPath $desktopPath -Filter *.desktop -ErrorAction Ignore }')
    )
    'Copy-ADTFileToUserProfiles' = @(
        , @('Copy-ADTFile -Path $sourcePaths -Destination $dest @CopyFileSplat', 'Copy-ADTFile -Path $sourcePaths -Destination $dest @CopyFileSplat
                # Linux: hand ownership of the copied content to the profile owner when running as root.
                if ([PSADT.AccountManagement.AccountUtilities]::CallerIsAdmin -and ($null -ne $UserProfile.NTAccount.Id) -and ($UserProfile.NTAccount.Id -ne 0))
                {
                    foreach ($sourcePath in $sourcePaths)
                    {
                        foreach ($item in (Get-Item -Path $sourcePath -Force -ErrorAction Ignore))
                        {
                            $copied = if ($Flatten -or !(Test-Path -LiteralPath $dest -PathType Container)) { $dest } else { Join-Path -Path $dest -ChildPath $item.Name }
                            if (Test-Path -LiteralPath $copied)
                            {
                                $null = Invoke-ADTNativeCommand -FilePath chown -ArgumentList ''-R'', "$($UserProfile.NTAccount.Value):", ''--'', $copied
                            }
                        }
                    }
                }')
    )
}

$NotSupportedBody = @'

    begin
    {
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process
    {
        try
        {
            Invoke-ADTLinuxNotSupported -Cmdlet $PSCmdlet
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
'@

$banner = @'
#-----------------------------------------------------------------------------
#
# MARK: {0}
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: {1}.
#
#-----------------------------------------------------------------------------

'@

$null = New-Item -Path $OutputPath -ItemType Directory -Force
$stats = @{ Linux = 0; Verbatim = 0; NotSupported = 0 }
$report = foreach ($file in Get-ChildItem -LiteralPath "$OriginalModule/Public" -Filter *.ps1 | Sort-Object Name)
{
    $text = [System.IO.File]::ReadAllText($file.FullName).TrimStart([char]0xFEFF)
    $tokens = $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($text, [ref]$tokens, [ref]$errors)
    $fn = $ast.Find({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false)
    $name = $fn.Name
    $paramBlock = $fn.Body.ParamBlock
    $dynBlock = $fn.Body.DynamicParamBlock

    # Header: "function Name { <help> [attributes] param(...)"
    $headerEnd = if ($paramBlock) { $paramBlock.Extent.EndOffset } else { $text.IndexOf('#>', $fn.Extent.StartOffset) + 2 }
    $header = $text.Substring($fn.Extent.StartOffset, $headerEnd - $fn.Extent.StartOffset)
    foreach ($kvp in $TypeMap.GetEnumerator())
    {
        $header = $header.Replace("[$($kvp.Key)]", "[$($kvp.Value)]").Replace("[$($kvp.Key)[]]", "[$($kvp.Value)[]]")
    }
    foreach ($patch in $HeaderPatches[$name])
    {
        if (!$header.Contains($patch[0])) { throw "Header patch for [$name] did not match." }
        $header = $header.Replace($patch[0], $patch[1])
    }
    $dynText = if ($dynBlock) { "`n`n    " + $dynBlock.Extent.Text } else { '' }

    $bodyFile = Join-Path $BodiesPath "$name.ps1"
    if (Test-Path -LiteralPath $bodyFile)
    {
        $kind = 'Linux'
        $body = $dynText + "`n" + [System.IO.File]::ReadAllText($bodyFile).TrimEnd() + "`n}"
    }
    elseif (($Verbatim -contains $name) -or $BodyPatches.ContainsKey($name))
    {
        $kind = 'Verbatim'
        $body = $text.Substring($headerEnd, $fn.Extent.EndOffset - $headerEnd)
        foreach ($patch in $BodyPatches[$name])
        {
            if (!$body.Contains($patch[0])) { throw "Body patch for [$name] did not match: $($patch[0])" }
            $body = $body.Replace($patch[0], $patch[1])
        }
    }
    else
    {
        $kind = 'NotSupported'
        $body = $dynText + "`n" + $NotSupportedBody.TrimEnd() + "`n}"
    }
    $stats[$kind]++
    $label = @{ Linux = 'Linux implementation'; Verbatim = 'original (platform-neutral) code'; NotSupported = 'not supported on Linux (throws PlatformNotSupportedException)' }[$kind]
    $content = ($banner -f $name, $label) + $header + $body + "`n"
    [System.IO.File]::WriteAllText((Join-Path $OutputPath "$name.ps1"), ($content -replace "`r`n", "`n"), [System.Text.UTF8Encoding]::new($false))
    [PSCustomObject]@{ Function = $name; Implementation = $kind }
}
$report | Export-Csv -LiteralPath $StatusCsvPath -NoTypeInformation
"Linux: $($stats.Linux)  Verbatim: $($stats.Verbatim)  NotSupported: $($stats.NotSupported)"
