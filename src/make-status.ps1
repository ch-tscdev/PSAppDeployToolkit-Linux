param($Csv, $Out)
$notes = @{
    'Open-ADTSession' = 'DeployMode Auto -> Silent (kein UI); Logs nach /var/log/Software'
    'Start-ADTProcess' = 'stdout/stderr werden erfasst; Token-/Fenster-Optionen werden ignoriert (Warnung)'
    'Start-ADTProcessAsUser' = 'via runuser/sudo in die aktive loginctl-Sitzung (XDG_RUNTIME_DIR, DBUS, DISPLAY)'
    'Get-ADTApplication' = 'dpkg/rpm/pacman/apk + flatpak/snap; -ApplicationType MSI = Distributionspakete, EXE = flatpak/snap'
    'Uninstall-ADTApplication' = 'apt-get/dnf/yum/zypper/rpm/pacman/apk/flatpak/snap remove'
    'Show-ADTInstallationWelcome' = 'Verhalten wie Silent: Prozesse schliessen (SIGTERM, dann SIGKILL), Speicherplatzprüfung; kein Defer'
    'Show-ADTInstallationPrompt' = 'nur Logeintrag, keine Rückgabe (wie Original im Silent-Modus)'
    'Show-ADTDialogBox' = 'nur Logeintrag, keine Rückgabe (wie Original im Silent-Modus)'
    'Show-ADTInstallationProgress' = 'nur Logeintrag'
    'Show-ADTBalloonTip' = 'nur Logeintrag'
    'Show-ADTNotifyIcon' = 'nur Logeintrag'
    'Show-ADTInstallationRestartPrompt' = 'mit -AllowSilentRestart: Neustart nach Ende (systemd-run/shutdown), sonst übersprungen'
    'Get-ADTLoggedOnUser' = 'systemd-logind (loginctl), Fallback who'
    'Get-ADTUserProfiles' = '/etc/passwd (UID >= UID_MIN), Default = /etc/skel, SID = S-1-22-1-<uid>'
    'Copy-ADTFileToUserProfiles' = 'zusätzlich chown auf den Profilbesitzer'
    'Get-ADTEnvironmentVariable' = 'Process / Machine = /etc/environment / User = ~/.config/environment.d'
    'Set-ADTEnvironmentVariable' = 'Process / Machine = /etc/environment / User = ~/.config/environment.d'
    'Remove-ADTEnvironmentVariable' = 'Process / Machine = /etc/environment / User = ~/.config/environment.d'
    'Test-ADTServiceExists' = 'systemd'
    'Get-ADTServiceStartMode' = 'systemd: enabled=Automatic, disabled=Manual, masked=Disabled'
    'Set-ADTServiceStartMode' = 'systemctl enable/disable/mask'
    'Start-ADTServiceAndDependencies' = 'systemctl start'
    'Stop-ADTServiceAndDependencies' = 'systemctl stop'
    'Get-ADTPendingReboot' = '/run/reboot-required, needs-restarting, zypper needs-rebooting, Kernel-Check'
    'Test-ADTBattery' = '/sys/class/power_supply'
    'Get-ADTOperatingSystemInfo' = '/etc/os-release'
    'Add-ADTFont' = '/usr/local/share/fonts bzw. ~/.local/share/fonts + fc-cache'
    'Remove-ADTFont' = '/usr/local/share/fonts bzw. ~/.local/share/fonts + fc-cache'
    'Remove-ADTDesktopShortcut' = '*.desktop-Dateien auf den Desktops der Benutzer'
    'Get-ADTExecutableInfo' = 'liest PE- und ELF-Header'
    'Copy-ADTContentToCache' = 'Cache unter /var/cache/SoftwareCache'
    'New-ADTTemplate' = 'erzeugt Paket inkl. Invoke-AppDeployToolkit.sh; -Version 3 nicht unterstützt'
    'Update-ADTDesktop' = 'update-desktop-database / gtk-update-icon-cache'
    'Update-ADTEnvironmentPsProvider' = 'lädt /etc/environment in die laufende Sitzung'
    'Test-ADTMicrophoneInUse' = 'ALSA-Capture-Status'
    'Test-ADTOobeCompleted' = 'immer $true'
    'Test-ADTEspActive' = 'immer $false'
    'Test-ADTPowerPoint' = 'immer $false'
    'Test-ADTUserInFocusMode' = 'immer $false'
    'Get-ADTIniValue' = 'eigener INI-Parser'; 'Set-ADTIniValue' = 'eigener INI-Parser'; 'Remove-ADTIniValue' = 'eigener INI-Parser'
    'Get-ADTIniSection' = 'eigener INI-Parser'; 'Set-ADTIniSection' = 'eigener INI-Parser'; 'Remove-ADTIniSection' = 'eigener INI-Parser'
    'Copy-ADTFile' = 'Robocopy-Modus fällt automatisch auf Native zurück'
}
$label = @{ Linux = 'Linux-Implementierung'; Verbatim = 'Original-Code'; NotSupported = '**nicht unterstützt**' }
$rows = Import-Csv $Csv
$lines = @('# Funktionsstatus', '', 'Alle 141 öffentlichen Funktionen existieren mit identischer Signatur. Spalte *Umsetzung*:', '',
  '- **Linux-Implementierung** – Parameterblock original, Logik für Linux neu geschrieben',
  '- **Original-Code** – plattformneutraler Original-Code (teils mit minimalen Pfad-Anpassungen)',
  '- **nicht unterstützt** – Windows-spezifisch; wirft `PlatformNotSupportedException` (mit `-ErrorAction SilentlyContinue` unterdrückbar)', '',
  "Stand: $(($rows | ? Implementation -eq Linux).Count) Linux-Implementierungen, $(($rows | ? Implementation -eq Verbatim).Count) Original-Code, $(($rows | ? Implementation -eq NotSupported).Count) nicht unterstützt.", '',
  '| Funktion | Umsetzung | Linux-Verhalten |', '|---|---|---|')
foreach ($r in $rows) { $lines += "| ``$($r.Function)`` | $($label[$r.Implementation]) | $($notes[$r.Function]) |" }
Set-Content -LiteralPath $Out -Value $lines -Encoding utf8
