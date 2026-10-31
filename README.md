# PSAppDeployToolkit für Linux (headless)

Linux-Port des [PSAppDeployToolkit](https://psappdeploytoolkit.com) **4.2.0** ohne Benutzeroberfläche.
Ziel: bestehende Deployment-Skripte und das Wissen aus PSADT unverändert weiterverwenden.

- **Gleiche Schnittstelle:** Alle 141 öffentlichen Funktionen existieren mit **identischen Namen, Parametern,
  Parametersets, Aliasen, Validierungen und Ausgabetypen**. Hilfe-Text, `[CmdletBinding()]`, `[OutputType()]`,
  `param()`- und `dynamicparam`-Blöcke werden 1:1 aus dem Original-Quellcode übernommen (generiert, nicht abgetippt).
- **Gleiches Frontend:** `Invoke-AppDeployToolkit.ps1` hat dieselben Parameter (`-DeploymentType`, `-DeployMode`,
  `-SuppressRebootPassThru`), dieselben Phasen (`Pre-Install`, `Install`, …) und dasselbe `$adtSession`-Objekt.
- **Gleiche Ausgaben:** CMTrace-kompatible Logs, gleiche Logmeldungen, gleiche Exit-Code-Logik
  (Success/Reboot/Defer/60001/60008, `-SuppressRebootPassThru`, `ExitWithMsiCodes`).
- **Skriptsprache PowerShell**, Voraussetzung: **PowerShell 7.4 oder neuer** (`pwsh`).

## Voraussetzungen

| Komponente | Version |
|---|---|
| PowerShell (`pwsh`) | 7.4 oder neuer (7.5+ lädt die vorkompilierte DLL, 7.4 kompiliert die Typen beim Import, ca. 1–2 s) |
| Distribution | jede systemd-basierte Distribution (Debian/Ubuntu, RHEL/Fedora/Rocky/Alma, SUSE, Arch); ohne systemd laufen alle Funktionen ausser den Dienst-Funktionen |
| Rechte | wie unter Windows: für maschinenweite Installationen `root` (z.B. via `sudo`), sonst Benutzerkontext mit den `NoAdminRights`-Pfaden |

PowerShell installieren: <https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-linux>

## Inhalt

```
PSAppDeployToolkit/          Das Modul (Name, GUID 8c3c366b-…, Version 4.2.0 wie das Original)
  Public/                    141 Funktionen (Signaturen aus dem Original)
  Private/                   Linux-Hilfsfunktionen (Session, logind, Pakete, systemd, INI …)
  lib/                       PSAppDeployToolkit.Linux.dll + C#-Quellen der Typen (PSADT.*, PSAppDeployToolkit.*)
  Config/config.psd1         gleiches Schema wie das Original, Linux-Pfade
  Strings/                   alle 28 Sprachen aus dem Original
  opt/Frontend/v4/           Vorlage Invoke-AppDeployToolkit.ps1 / .sh + Extensions
Template/                    Fertiges, leeres Deployment-Paket (mit New-ADTTemplate erzeugt)
src/                         Build: Generator, Linux-Funktionsrümpfe, C#-Quellen
tests/                       Smoke-Tests (35) und Paritätsprüfung gegen das Original
FUNCTION-STATUS.md           Status und Linux-Verhalten jeder Funktion
```

## Schnellstart

```bash
# Paket erzeugen (oder den Ordner Template/ kopieren)
pwsh -c 'Import-Module ./PSAppDeployToolkit; New-ADTTemplate -Destination . -Name MyApp'

# Installieren – genau wie unter Windows
cd MyApp
sudo ./Invoke-AppDeployToolkit.sh -DeploymentType Install -DeployMode Silent
# oder direkt:
sudo pwsh -NoProfile -File ./Invoke-AppDeployToolkit.ps1 -DeploymentType Install
```

`Invoke-AppDeployToolkit.sh` ist das Gegenstück zur `Invoke-AppDeployToolkit.exe`: es prüft die Voraussetzung
(pwsh ≥ 7.4), reicht alle Parameter unverändert durch und gibt den Exit-Code zurück.

Beispiel für den Install-Abschnitt:

```powershell
New-Variable -Name Install -Force -Value {
    Start-ADTProcess -FilePath apt-get -ArgumentList 'install', '-y', "$($adtSession.DirFiles)/myapp_2.0.0_amd64.deb"
    Set-ADTServiceStartMode -Name myapp -StartMode Automatic
    Start-ADTServiceAndDependencies -Name myapp
}
New-Variable -Name Uninstall -Force -Value {
    Uninstall-ADTApplication -Name myapp -NameMatch Exact
}
```

## Was sich auf Linux anders verhält

**Kein UI.** `DeployMode Auto` wird immer zu `Silent` (unter Windows passiert das ebenfalls, wenn niemand angemeldet
ist). `Interactive`/`NonInteractive` können weiterhin explizit gesetzt werden (Skripte, die darauf verzweigen, laufen
unverändert), die UI-Funktionen verhalten sich aber immer wie im Silent-Modus des Originals:

- `Show-ADTInstallationWelcome` schliesst `-CloseProcesses` ohne Nachfrage (erst SIGTERM, nach 5 s SIGKILL),
  prüft den Speicherplatz und bricht bei zu wenig Platz mit `DefaultExitCode` (1618) ab. Deferral ist ohne
  Benutzer nicht möglich und wird protokolliert.
- `Show-ADTInstallationPrompt`, `Show-ADTDialogBox`, `Show-ADTInstallationProgress`, `Show-ADTBalloonTip`
  schreiben nur einen Logeintrag und geben nichts zurück – exakt wie das Original im Silent-Modus.
- `Show-ADTInstallationRestartPrompt -AllowSilentRestart` löst nach Sessionende einen Neustart aus
  (`systemd-run … systemctl reboot`), ohne den Schalter wird der Neustart übersprungen.

**Windows-Technologien** (Registry, MSI/MSP, WIM, SCCM/Intune, Active Setup, DLL-Registrierung, Edge-Erweiterungen,
`.lnk`-Verknüpfungen, NTFS-ACLs, Terminal Server, Group Policy, App-Blocking) sind als Funktionen vorhanden, werfen
aber eine `PlatformNotSupportedException` mit klarer Meldung. So fällt ein nicht portiertes Windows-Skript sofort auf.
Bewusst ignorieren: `-ErrorAction SilentlyContinue` oder `if ($IsWindows) { … }`.

**Ersatz-Typen für Windows-Klassen.** `NTAccount`/`SecurityIdentifier` können auf Linux nicht erzeugt werden; die
betroffenen Parameter (z.B. `Get-ADTUserProfiles -SID`, `Start-ADTProcessAsUser -Username`) verwenden
`PSADT.AccountManagement.UnixIdentity` (nimmt Benutzername, UID oder `S-1-22-1-<uid>`). `ServiceController`-Parameter
verwenden `PSADT.ServiceManagement.SystemdService` (gleiche Eigenschaften: `ServiceName`, `Status`, `StartType`, …).
Parameter**namen** bleiben überall gleich.

**Pfade in der Konfiguration** (gleiches Schema, andere Werte):

| Schlüssel | Windows | Linux (root) | Linux (Benutzer) |
|---|---|---|---|
| `Toolkit.LogPath` | `%SystemRoot%\Logs\Software` | `/var/log/Software` | `~/.local/state/Logs/Software` |
| `Toolkit.CachePath` | `%ProgramData%\SoftwareCache` | `/var/cache/SoftwareCache` | `~/.cache/SoftwareCache` |
| `Toolkit.RegPath` (Deferral-Historie) | `HKLM:\SOFTWARE` | `/var/lib` (JSON-Dateien) | `~/.local/share` |
| `Toolkit.TempPath` | `%Temp%` | `/tmp` | `/tmp` |

Eigene `Config/config.psd1` bzw. `Strings/strings.psd1` im Paket überschreiben – wie im Original – nur die
angegebenen Schlüssel.

**Exit-Codes > 255.** Linux übergibt dem aufrufenden Prozess nur die unteren 8 Bit eines Exit-Codes. Die Logik ist
identisch (das Log zeigt den vollen Wert, `$LASTEXITCODE` innerhalb von PowerShell ebenfalls), ein Management-Agent
sieht aber z.B.:

| PSADT | sichtbar unter Linux |
|---|---|
| 0 | 0 |
| 3010 / 1641 (Neustart) | 194 / 105 |
| 1602 (Defer) / 1618 (Timeout) | 66 / 82 |
| 60001 / 60008 | 97 / 104 |

Wer eindeutige Codes braucht, setzt `AppRebootExitCodes`/`DeferExitCode`/`DefaultExitCode` auf Werte ≤ 255.

**Pakete statt MSI.** `Get-ADTApplication` liefert die installierten Pakete aus dpkg/rpm/pacman/apk sowie
flatpak/snap (gleiche Eigenschaften wie das Original, plus `PackageManager`/`PackageName`). `-ApplicationType MSI`
bedeutet hier «Distributionspakete», `EXE` «flatpak/snap». `Uninstall-ADTApplication` entfernt über den passenden
Paketmanager. Installiert wird mit `Start-ADTProcess` (apt-get, dnf, zypper, rpm, flatpak …).

## Frontend

Die Vorlage `Invoke-AppDeployToolkit.ps1` ist bis auf eine Stelle identisch mit dem Original: `Unblock-File`
(Windows Zone.Identifier) wird nur noch unter Windows aufgerufen, weil das Cmdlet unter Linux einen Fehler wirft.
Die Vorlage läuft damit auf beiden Plattformen. Bestehende Windows-Pakete brauchen nur diese Anpassung im
Abschnitt `## MARK: Initialization` – plus Ersatz der Windows-spezifischen Aufrufe in den Phasen.

## Tests und Build

```bash
pwsh -NoProfile -File tests/Smoke.Tests.ps1 -ModulePath ./PSAppDeployToolkit
pwsh -NoProfile -File tests/parity.ps1 <Pfad zum Original>/modules/PSAppDeployToolkit ./PSAppDeployToolkit
```

`parity.ps1` vergleicht für alle 141 Funktionen Name, Typ, Attribute und Standardwert jedes Parameters mit dem
Original. Einzige Abweichungen sind vier Standardwerte mit Windows-Pfaden (z.B. `Get-ADTFreeDiskSpace -Drive`
`C:\` → `/`).

Für eine neue PSADT-Version: `src/build.sh <Pfad zum PSADT-Repo>` erzeugt die Public-Funktionen neu aus dem
Original-Quellcode und kompiliert die DLL. Neue Windows-only-Funktionen erscheinen automatisch als «nicht unterstützt».

## Lizenz

Wie das Original: GNU LGPL v3 (siehe `COPYING.Lesser`). Copyright der Originalteile beim PSAppDeployToolkit Team.
