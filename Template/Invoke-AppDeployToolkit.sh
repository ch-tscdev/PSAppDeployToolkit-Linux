#!/bin/sh
# -----------------------------------------------------------------------------
# Invoke-AppDeployToolkit.sh - Linux launcher (counterpart of Invoke-AppDeployToolkit.exe)
#
# Accepts exactly the same parameters as Invoke-AppDeployToolkit.ps1 and returns
# its exit code, e.g.:
#
#   sudo ./Invoke-AppDeployToolkit.sh -DeploymentType Install -DeployMode Silent
#
# Prerequisite: PowerShell 7.4 or newer ("pwsh") must be installed.
# -----------------------------------------------------------------------------
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

PWSH=$(command -v pwsh || command -v pwsh-preview || true)
if [ -z "$PWSH" ]; then
    for candidate in /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh /snap/bin/pwsh /opt/pwsh/pwsh; do
        if [ -x "$candidate" ]; then PWSH=$candidate; break; fi
    done
fi
if [ -z "$PWSH" ]; then
    echo "PSAppDeployToolkit: PowerShell 7.4+ (pwsh) is required but was not found." >&2
    echo "See https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-linux" >&2
    exit 1
fi

if ! "$PWSH" -NoLogo -NoProfile -NonInteractive -Command 'if ($PSVersionTable.PSVersion -lt [version]"7.4") { exit 1 }'; then
    echo "PSAppDeployToolkit: PowerShell 7.4 or newer is required ($("$PWSH" -NoLogo -NoProfile -Command '$PSVersionTable.PSVersion.ToString()') found)." >&2
    exit 1
fi

exec "$PWSH" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "$SCRIPT_DIR/Invoke-AppDeployToolkit.ps1" "$@"
