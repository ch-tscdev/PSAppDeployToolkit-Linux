param($ModulePath)
$funcs = (Get-ChildItem "$ModulePath/Public" -Filter *.ps1).BaseName | Sort-Object
$list = ($funcs | % { "        '$_'" }) -join "`n"
@"
#
# Module manifest for module 'PSAppDeployToolkit' (Linux port)
#
@{
    RootModule = 'PSAppDeployToolkit.psm1'
    ModuleVersion = '4.2.0'
    Guid = '8c3c366b-8606-4576-9f2d-4051144f7ca2'
    Author = 'PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough); Linux port'
    CompanyName = 'PSAppDeployToolkit Team'
    Copyright = 'Copyright © 2026 PSAppDeployToolkit Team. Linux port licensed under LGPL-3.0, as the original.'
    Description = 'Enterprise App Deployment, Simplified. Headless Linux port with an identical function interface.'
    PowerShellVersion = '7.4'
    CompatiblePSEditions = @('Core')
    FunctionsToExport = @(
$list
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('psadt', 'linux', 'deployment', 'packaging')
            LicenseUri = 'https://opensource.org/license/lgpl-3-0'
            ProjectUri = 'https://psappdeploytoolkit.com'
        }
    }
}
"@ | Set-Content -LiteralPath "$ModulePath/PSAppDeployToolkit.psd1" -Encoding utf8
