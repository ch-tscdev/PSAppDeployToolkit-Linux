# Smoke tests for the Linux port. Run: pwsh -NoProfile -File tests/Smoke.Tests.ps1 -ModulePath ./PSAppDeployToolkit
param ([string]$ModulePath = "$PSScriptRoot/../PSAppDeployToolkit")
$ErrorActionPreference = 'Stop'
$script:failures = 0; $script:passes = 0
function Assert([string]$Name, [scriptblock]$Test)
{
    try { $r = & $Test; if ($r -eq $false) { throw 'returned false' }; $script:passes++; Write-Host "  [PASS] $Name" -ForegroundColor Green }
    catch { $script:failures++; Write-Host "  [FAIL] $Name :: $_" -ForegroundColor Red }
}

Import-Module "$ModulePath/PSAppDeployToolkit.psd1" -Force
$work = Join-Path ([System.IO.Path]::GetTempPath()) "psadt-smoke-$PID"
$null = New-Item -Path $work -ItemType Directory -Force

Write-Host 'Module surface'
Assert '141 public functions exported' { (Get-Command -Module PSAppDeployToolkit).Count -eq 141 }
Assert 'Every function resolves its parameters (incl. dynamic ones)' {
    foreach ($c in Get-Command -Module PSAppDeployToolkit) { $null = $c.Parameters.Keys }
    $true
}

Write-Host 'Session lifecycle'
Assert 'Open-ADTSession returns a DeploymentSession' {
    $s = Open-ADTSession -AppVendor Test -AppName 'Smoke App' -AppVersion 1.0 -DeploymentType Install -ScriptDirectory $work -PassThru
    $s -is [PSAppDeployToolkit.Foundation.DeploymentSession]
}
Assert 'Auto deploy mode resolves to Silent' { (Get-ADTSession).DeployMode -eq 'Silent' }
Assert 'InstallName is built like the original' { (Get-ADTSession).InstallName -eq 'Test_SmokeApp_1.0' }
Assert 'Log file is written' { Test-Path -LiteralPath (Join-Path (Get-ADTSession).LogPath.FullName (Get-ADTSession).LogName) }
Assert 'Environment variables are exported' { (Get-ADTEnvironmentTable).envOSName -and ((Get-ADTEnvironmentTable).appDeployToolkitName -eq 'PSAppDeployToolkit') }

Write-Host 'Processes'
Assert 'Start-ADTProcess captures output' { (Start-ADTProcess -FilePath sh -ArgumentList '-c', 'echo out; echo err >&2' -PassThru).StdOut[0] -eq 'out' }
Assert 'Start-ADTProcess honours SuccessExitCodes' { (Start-ADTProcess -FilePath sh -ArgumentList '-c', 'exit 7' -SuccessExitCodes 7 -PassThru).ExitCode -eq 7 }
Assert 'Start-ADTProcess throws on failure' { try { Start-ADTProcess -FilePath sh -ArgumentList '-c', 'exit 9'; $false } catch { $_.Exception.Message -match 'exit code \[9\]' } }
Assert 'Start-ADTProcess -NoWait returns a handle' { $h = Start-ADTProcess -FilePath sleep -ArgumentList 1 -NoWait -PassThru; $h.GetResult().ExitCode -eq 0 }
Assert 'Start-ADTProcess timeout terminates' { try { Start-ADTProcess -FilePath sleep -ArgumentList 10 -Timeout 1 -CreateNoWindow; $false } catch { $_.Exception -is [System.OperationCanceledException] } }
Assert 'Get-ADTRunningProcesses finds a process' { $p = Start-Process sleep 30 -PassThru; try { (Get-ADTRunningProcesses -ProcessDefinition 'sleep').Count -ge 1 } finally { $p.Kill() } }

Write-Host 'Files, INI, environment'
Assert 'Copy-ADTFile copies' { Set-Content "$work/a.txt" 'x'; Copy-ADTFile -Path "$work/a.txt" -Destination "$work/out/"; Test-Path "$work/out/a.txt" }
Assert 'INI round-trip' { Set-ADTIniValue -FilePath "$work/t.ini" -Section Main -Key Foo -Value Bar -Force; (Get-ADTIniValue -FilePath "$work/t.ini" -Section Main -Key Foo) -eq 'Bar' }
Assert 'INI section' { Set-ADTIniSection -FilePath "$work/t.ini" -Section S2 -Content @{ A = 1 }; (Get-ADTIniSection -FilePath "$work/t.ini" -Section S2).A -eq '1' }
Assert 'Process environment variable' { Set-ADTEnvironmentVariable -Variable PSADT_SMOKE -Value 1; (Get-ADTEnvironmentVariable -Variable PSADT_SMOKE) -eq '1' }
Assert 'New-ADTZipFile' { New-ADTZipFile -LiteralPath "$work/out" -DestinationPath "$work/out.zip"; Test-Path "$work/out.zip" }
Assert 'Get-ADTExecutableInfo reads ELF' { (Get-ADTExecutableInfo -LiteralPath (Get-Command sh).Source).Format -eq 'ELF' }
Assert 'Convert-ADTValueType' { (Convert-ADTValueType -Value 256 -To Byte) -eq 0 }
Assert 'Get-ADTFreeDiskSpace' { (Get-ADTFreeDiskSpace) -gt 0 }

Write-Host 'System information'
Assert 'Get-ADTOperatingSystemInfo' { (Get-ADTOperatingSystemInfo).Name }
Assert 'Get-ADTPendingReboot' { (Get-ADTPendingReboot) -is [PSADT.DeviceManagement.RebootInfo] }
Assert 'Test-ADTBattery' { (Test-ADTBattery) -is [bool] }
Assert 'Get-ADTUserProfiles' { $null -ne (Get-ADTUserProfiles) }
Assert 'Get-ADTApplication lists packages' { @(Get-ADTApplication -Name 'bash' -NameMatch Exact).Count -ge 1 }
Assert 'Test-ADTCallerIsAdmin' { (Test-ADTCallerIsAdmin) -is [bool] }

Write-Host 'Headless UI'
Assert 'Show-ADTInstallationWelcome closes processes' { $p = Start-Process sleep 60 -PassThru; Show-ADTInstallationWelcome -CloseProcesses sleep -Silent; Start-Sleep 1; $p.HasExited }
Assert 'Show-ADTInstallationPrompt returns nothing' { $null -eq (Show-ADTInstallationPrompt -Message 'hi' -ButtonRightText OK) }
Assert 'Show-ADTInstallationProgress logs' { Show-ADTInstallationProgress -StatusMessage 'Working'; $true }
Assert 'Show-ADTBalloonTip logs' { Show-ADTBalloonTip -BalloonTipText 'hi' -ErrorAction Stop; $true }

Write-Host 'Windows-only functions'
Assert 'Get-ADTRegistryKey throws PlatformNotSupported' { try { Get-ADTRegistryKey -LiteralPath 'HKLM:\SOFTWARE'; $false } catch { $_.Exception -is [System.PlatformNotSupportedException] } }
Assert 'Windows-only function can be silenced' { Set-ADTRegistryKey -LiteralPath 'HKLM:\SOFTWARE\X' -ErrorAction SilentlyContinue; $true }

Write-Host 'Exit code handling'
Assert 'Reboot exit code is passed through' { (Get-ADTSession).SetExitCode(3010); foreach ($i in 1) { Close-ADTSession -NoShellExit }; $LASTEXITCODE -eq 3010 }
Assert 'Session closed' { !(Test-ADTSessionActive) }

Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction Ignore
Write-Host "`nPassed: $script:passes  Failed: $script:failures"
exit $script:failures
