# Funktionsstatus

Alle 141 öffentlichen Funktionen existieren mit identischer Signatur. Spalte *Umsetzung*:

- **Linux-Implementierung** – Parameterblock original, Logik für Linux neu geschrieben
- **Original-Code** – plattformneutraler Original-Code (teils mit minimalen Pfad-Anpassungen)
- **nicht unterstützt** – Windows-spezifisch; wirft `PlatformNotSupportedException` (mit `-ErrorAction SilentlyContinue` unterdrückbar)

Stand: 52 Linux-Implementierungen, 49 Original-Code, 40 nicht unterstützt.

| Funktion | Umsetzung | Linux-Verhalten |
|---|---|---|
| `Add-ADTEdgeExtension` | **nicht unterstützt** |  |
| `Add-ADTFont` | Linux-Implementierung | /usr/local/share/fonts bzw. ~/.local/share/fonts + fc-cache |
| `Add-ADTModuleCallback` | Original-Code |  |
| `Block-ADTAppExecution` | **nicht unterstützt** |  |
| `Clear-ADTModuleCallback` | Original-Code |  |
| `Close-ADTInstallationProgress` | Linux-Implementierung |  |
| `Close-ADTNotifyIcon` | Linux-Implementierung |  |
| `Close-ADTSession` | Original-Code |  |
| `Complete-ADTFunction` | Original-Code |  |
| `Convert-ADTRegistryPath` | **nicht unterstützt** |  |
| `Convert-ADTValuesFromRemainingArguments` | Original-Code |  |
| `Convert-ADTValueType` | Original-Code |  |
| `ConvertTo-ADTNTAccountOrSID` | **nicht unterstützt** |  |
| `Copy-ADTContentToCache` | Original-Code | Cache unter /var/cache/SoftwareCache |
| `Copy-ADTFile` | Original-Code | Robocopy-Modus fällt automatisch auf Native zurück |
| `Copy-ADTFileToUserProfiles` | Original-Code | zusätzlich chown auf den Profilbesitzer |
| `Disable-ADTTerminalServerInstallMode` | **nicht unterstützt** |  |
| `Dismount-ADTWimFile` | **nicht unterstützt** |  |
| `Enable-ADTTerminalServerInstallMode` | **nicht unterstützt** |  |
| `Export-ADTEnvironmentTableToSessionState` | Linux-Implementierung |  |
| `Get-ADTApplication` | Linux-Implementierung | dpkg/rpm/pacman/apk + flatpak/snap; -ApplicationType MSI = Distributionspakete, EXE = flatpak/snap |
| `Get-ADTBoundParametersAndDefaultValues` | Original-Code |  |
| `Get-ADTCommandTable` | Linux-Implementierung |  |
| `Get-ADTConfig` | Original-Code |  |
| `Get-ADTDeferHistory` | Original-Code |  |
| `Get-ADTEnvironmentTable` | Original-Code |  |
| `Get-ADTEnvironmentVariable` | Linux-Implementierung | Process / Machine = /etc/environment / User = ~/.config/environment.d |
| `Get-ADTExecutableInfo` | Original-Code | liest PE- und ELF-Header |
| `Get-ADTFileVersion` | Original-Code |  |
| `Get-ADTFreeDiskSpace` | Original-Code |  |
| `Get-ADTIniSection` | Linux-Implementierung | eigener INI-Parser |
| `Get-ADTIniValue` | Linux-Implementierung | eigener INI-Parser |
| `Get-ADTLoggedOnUser` | Linux-Implementierung | systemd-logind (loginctl), Fallback who |
| `Get-ADTModuleCallback` | Original-Code |  |
| `Get-ADTMsiExitCodeMessage` | **nicht unterstützt** |  |
| `Get-ADTMsiTableProperty` | **nicht unterstützt** |  |
| `Get-ADTObjectProperty` | Original-Code |  |
| `Get-ADTOperatingSystemInfo` | Linux-Implementierung | /etc/os-release |
| `Get-ADTPEFileArchitecture` | Original-Code |  |
| `Get-ADTPendingReboot` | Linux-Implementierung | /run/reboot-required, needs-restarting, zypper needs-rebooting, Kernel-Check |
| `Get-ADTPowerShellProcessPath` | Linux-Implementierung |  |
| `Get-ADTPresentationSettingsEnabledUsers` | Linux-Implementierung |  |
| `Get-ADTRegistryKey` | **nicht unterstützt** |  |
| `Get-ADTRunningProcesses` | Original-Code |  |
| `Get-ADTServiceStartMode` | Linux-Implementierung | systemd: enabled=Automatic, disabled=Manual, masked=Disabled |
| `Get-ADTSession` | Original-Code |  |
| `Get-ADTShortcut` | **nicht unterstützt** |  |
| `Get-ADTStringTable` | Linux-Implementierung |  |
| `Get-ADTUserNotificationState` | Linux-Implementierung |  |
| `Get-ADTUserProfiles` | Linux-Implementierung | /etc/passwd (UID >= UID_MIN), Default = /etc/skel, SID = S-1-22-1-<uid> |
| `Get-ADTUserToastNotificationMode` | **nicht unterstützt** |  |
| `Get-ADTWindowTitle` | **nicht unterstützt** |  |
| `Initialize-ADTFunction` | Original-Code |  |
| `Initialize-ADTModule` | Linux-Implementierung |  |
| `Install-ADTMSUpdates` | **nicht unterstützt** |  |
| `Install-ADTSCCMSoftwareUpdates` | **nicht unterstützt** |  |
| `Invoke-ADTAllUsersRegistryAction` | **nicht unterstützt** |  |
| `Invoke-ADTCommandWithRetries` | Original-Code |  |
| `Invoke-ADTFunctionErrorHandler` | Original-Code |  |
| `Invoke-ADTObjectMethod` | Original-Code |  |
| `Invoke-ADTRegSvr32` | **nicht unterstützt** |  |
| `Invoke-ADTSCCMTask` | **nicht unterstützt** |  |
| `Mount-ADTWimFile` | **nicht unterstützt** |  |
| `New-ADTErrorRecord` | Original-Code |  |
| `New-ADTFolder` | Original-Code |  |
| `New-ADTLogFileName` | Original-Code |  |
| `New-ADTMsiTransform` | **nicht unterstützt** |  |
| `New-ADTShortcut` | **nicht unterstützt** |  |
| `New-ADTTemplate` | Linux-Implementierung | erzeugt Paket inkl. Invoke-AppDeployToolkit.sh; -Version 3 nicht unterstützt |
| `New-ADTValidateScriptErrorRecord` | Original-Code |  |
| `New-ADTZipFile` | Original-Code |  |
| `Open-ADTSession` | Linux-Implementierung | DeployMode Auto -> Silent (kein UI); Logs nach /var/log/Software |
| `Out-ADTPowerShellEncodedCommand` | Original-Code |  |
| `Register-ADTDll` | **nicht unterstützt** |  |
| `Remove-ADTContentFromCache` | Original-Code |  |
| `Remove-ADTDesktopShortcut` | Original-Code | *.desktop-Dateien auf den Desktops der Benutzer |
| `Remove-ADTEdgeExtension` | **nicht unterstützt** |  |
| `Remove-ADTEnvironmentVariable` | Linux-Implementierung | Process / Machine = /etc/environment / User = ~/.config/environment.d |
| `Remove-ADTFile` | Original-Code |  |
| `Remove-ADTFileFromUserProfiles` | Original-Code |  |
| `Remove-ADTFolder` | Original-Code |  |
| `Remove-ADTFont` | Linux-Implementierung | /usr/local/share/fonts bzw. ~/.local/share/fonts + fc-cache |
| `Remove-ADTHashtableNullOrEmptyValues` | Original-Code |  |
| `Remove-ADTIniSection` | Linux-Implementierung | eigener INI-Parser |
| `Remove-ADTIniValue` | Linux-Implementierung | eigener INI-Parser |
| `Remove-ADTInvalidFileNameChars` | Original-Code |  |
| `Remove-ADTModuleCallback` | Original-Code |  |
| `Remove-ADTRegistryKey` | **nicht unterstützt** |  |
| `Reset-ADTDeferHistory` | Original-Code |  |
| `Resolve-ADTErrorRecord` | Original-Code |  |
| `Select-ADTUniqueObject` | Original-Code |  |
| `Send-ADTKeys` | **nicht unterstützt** |  |
| `Set-ADTActiveSetup` | **nicht unterstützt** |  |
| `Set-ADTDeferHistory` | Original-Code |  |
| `Set-ADTEnvironmentVariable` | Linux-Implementierung | Process / Machine = /etc/environment / User = ~/.config/environment.d |
| `Set-ADTIniSection` | Linux-Implementierung | eigener INI-Parser |
| `Set-ADTIniValue` | Linux-Implementierung | eigener INI-Parser |
| `Set-ADTItemPermission` | **nicht unterstützt** |  |
| `Set-ADTMsiProperty` | **nicht unterstützt** |  |
| `Set-ADTPowerShellCulture` | Original-Code |  |
| `Set-ADTRegistryKey` | **nicht unterstützt** |  |
| `Set-ADTServiceStartMode` | Linux-Implementierung | systemctl enable/disable/mask |
| `Set-ADTShortcut` | **nicht unterstützt** |  |
| `Show-ADTBalloonTip` | Linux-Implementierung | nur Logeintrag |
| `Show-ADTDialogBox` | Linux-Implementierung | nur Logeintrag, keine Rückgabe (wie Original im Silent-Modus) |
| `Show-ADTHelpConsole` | **nicht unterstützt** |  |
| `Show-ADTInstallationProgress` | Linux-Implementierung | nur Logeintrag |
| `Show-ADTInstallationPrompt` | Linux-Implementierung | nur Logeintrag, keine Rückgabe (wie Original im Silent-Modus) |
| `Show-ADTInstallationRestartPrompt` | Linux-Implementierung | mit -AllowSilentRestart: Neustart nach Ende (systemd-run/shutdown), sonst übersprungen |
| `Show-ADTInstallationWelcome` | Linux-Implementierung | Verhalten wie Silent: Prozesse schliessen (SIGTERM, dann SIGKILL), Speicherplatzprüfung; kein Defer |
| `Show-ADTNotifyIcon` | Linux-Implementierung | nur Logeintrag |
| `Start-ADTMsiProcess` | **nicht unterstützt** |  |
| `Start-ADTMsiProcessAsUser` | **nicht unterstützt** |  |
| `Start-ADTMspProcess` | **nicht unterstützt** |  |
| `Start-ADTMspProcessAsUser` | **nicht unterstützt** |  |
| `Start-ADTProcess` | Linux-Implementierung | stdout/stderr werden erfasst; Token-/Fenster-Optionen werden ignoriert (Warnung) |
| `Start-ADTProcessAsUser` | Original-Code | via runuser/sudo in die aktive loginctl-Sitzung (XDG_RUNTIME_DIR, DBUS, DISPLAY) |
| `Start-ADTServiceAndDependencies` | Linux-Implementierung | systemctl start |
| `Stop-ADTServiceAndDependencies` | Linux-Implementierung | systemctl stop |
| `Test-ADTBattery` | Linux-Implementierung | /sys/class/power_supply |
| `Test-ADTCallerIsAdmin` | Linux-Implementierung |  |
| `Test-ADTEspActive` | Linux-Implementierung | immer $false |
| `Test-ADTMicrophoneInUse` | Linux-Implementierung | ALSA-Capture-Status |
| `Test-ADTModuleInitialized` | Linux-Implementierung |  |
| `Test-ADTMSUpdates` | **nicht unterstützt** |  |
| `Test-ADTMutexAvailability` | Original-Code |  |
| `Test-ADTNetworkConnection` | Original-Code |  |
| `Test-ADTOobeCompleted` | Linux-Implementierung | immer $true |
| `Test-ADTPowerPoint` | Linux-Implementierung | immer $false |
| `Test-ADTRegistryValue` | **nicht unterstützt** |  |
| `Test-ADTServiceExists` | Linux-Implementierung | systemd |
| `Test-ADTSessionActive` | Original-Code |  |
| `Test-ADTUserInFocusMode` | Linux-Implementierung | immer $false |
| `Test-ADTUserIsBusy` | Linux-Implementierung |  |
| `Unblock-ADTAppExecution` | **nicht unterstützt** |  |
| `Uninstall-ADTApplication` | Linux-Implementierung | apt-get/dnf/yum/zypper/rpm/pacman/apk/flatpak/snap remove |
| `Unregister-ADTDll` | **nicht unterstützt** |  |
| `Update-ADTDesktop` | Linux-Implementierung | update-desktop-database / gtk-update-icon-cache |
| `Update-ADTEnvironmentPsProvider` | Linux-Implementierung | lädt /etc/environment in die laufende Sitzung |
| `Update-ADTGroupPolicy` | **nicht unterstützt** |  |
| `Write-ADTLogEntry` | Original-Code |  |
