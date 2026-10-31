#!/bin/sh
# Rebuilds the Linux port from an original PSAppDeployToolkit source checkout.
#   ./build.sh /path/to/PSAppDeployToolkit-repo
# Regenerates PSAppDeployToolkit/Public/*.ps1 (signatures from the original, bodies from ./bodies),
# recompiles lib/PSAppDeployToolkit.Linux.dll and refreshes the manifest and FUNCTION-STATUS.md.
set -e
ORIG=${1:?Usage: build.sh <path to the PSAppDeployToolkit repository>}
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
MOD="$HERE/../PSAppDeployToolkit"
pwsh -NoProfile -File "$HERE/compile-types.ps1" "$HERE/cs" "$MOD/lib/PSAppDeployToolkit.Linux.dll"
rm -rf "$MOD/lib/src" && mkdir -p "$MOD/lib/src" && cp "$HERE"/cs/*.cs "$MOD/lib/src/"
rm -rf "$MOD/Public"
pwsh -NoProfile -File "$HERE/generate.ps1" -OriginalModule "$ORIG/modules/PSAppDeployToolkit" -BodiesPath "$HERE/bodies" -OutputPath "$MOD/Public" -StatusCsvPath "$HERE/FUNCTION-STATUS.csv"
pwsh -NoProfile -File "$HERE/make-psd1.ps1" "$MOD"
pwsh -NoProfile -File "$HERE/make-status.ps1" "$HERE/FUNCTION-STATUS.csv" "$HERE/../FUNCTION-STATUS.md"
echo "Build complete."
