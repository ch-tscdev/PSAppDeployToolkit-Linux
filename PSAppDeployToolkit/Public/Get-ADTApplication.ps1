#-----------------------------------------------------------------------------
#
# MARK: Get-ADTApplication
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: Linux implementation.
#
#-----------------------------------------------------------------------------
function Get-ADTApplication
{
    <#
    .SYNOPSIS
        Retrieves information about installed applications.

    .DESCRIPTION
        The `Get-ADTApplication` function retrieves information about installed applications by querying the registry. You can specify an application name, a product code, or both. Returns information about application publisher, name & version, product code, uninstall string, install source, location, date, and application architecture.

    .PARAMETER Name
        The name of the application to retrieve information for. Performs a contains match on the application display name by default.

    .PARAMETER NameMatch
        Specifies the type of match to perform on the application name. The default value for this parameter is `Contains`.

        Valid values for this parameter are:
        - `Contains`: Equivalent to `$appDisplayName -like "*$Name*"`.
        - `Exact`: Equivalent to `$appDisplayName -eq $Name`.
        - `Wildcard`: Equivalent to `$appDisplayName -like $Name`.
        - `Regex`: Equivalent to `$appDisplayName -match $Name`.

    .PARAMETER ProductCode
        The product code of the application to retrieve information for.

    .PARAMETER ApplicationType
        Specifies the type of application to remove. Valid values are `All`, `MSI`, and `EXE`. The default value is `All`.

    .PARAMETER IncludeUpdatesAndHotfixes
        Include matches against updates and hotfixes in results.

    .PARAMETER FilterScript
        A script used to filter the results as they're processed.

    .PARAMETER Force
        Returns all found applications, even if marked as a system component.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        PSADT.AppManagement.InstalledApplication

        Returns an InstalledApplication object with information about an installed application:
        - PSPath
        - PSParentPath
        - PSChildName
        - ProductCode
        - DisplayName
        - DisplayVersion
        - UninstallString
        - QuietUninstallString
        - InstallSource
        - InstallLocation
        - InstallDate
        - Publisher
        - HelpLink
        - EstimatedSize
        - SystemComponent
        - WindowsInstaller
        - NoRemove
        - Is64BitApplication

    .EXAMPLE
        Get-ADTApplication

        This example retrieves information about all installed applications.

    .EXAMPLE
        Get-ADTApplication -Name 'Acrobat'

        Returns all applications that contain the name 'Acrobat' in the DisplayName.

    .EXAMPLE
        Get-ADTApplication -Name 'Adobe Acrobat Reader' -NameMatch 'Exact'

        Returns all applications that match the name 'Adobe Acrobat Reader' exactly.

    .EXAMPLE
        Get-ADTApplication -ProductCode '{AC76BA86-7AD7-1033-7B44-AC0F074E4100}'

        Returns the application with the specified ProductCode.

    .EXAMPLE
        Get-ADTApplication -Name 'Acrobat' -ApplicationType 'MSI' -FilterScript { $_.Publisher -match 'Adobe' }

        Returns all MSI applications that contain the name 'Acrobat' in the DisplayName and 'Adobe' in the Publisher name.

    .NOTES
        An active ADT session is NOT required to use this function.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Get-ADTApplication

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Get-ADTApplication.ps1
    #>

    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'ProductCode', Justification = "This parameter is used within delegates that PSScriptAnalyzer has no visibility of. See https://github.com/PowerShell/PSScriptAnalyzer/issues/1472 for more details.")]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'ApplicationType', Justification = "This parameter is used within delegates that PSScriptAnalyzer has no visibility of. See https://github.com/PowerShell/PSScriptAnalyzer/issues/1472 for more details.")]
    [CmdletBinding()]
    [OutputType([PSADT.AppManagement.InstalledApplication])]
    param
    (
        [Parameter(Mandatory = $false)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String[]]$Name,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Contains', 'Exact', 'Wildcard', 'Regex')]
        [System.String]$NameMatch = 'Contains',

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.Guid[]]$ProductCode,

        [Parameter(Mandatory = $false)]
        [ValidateSet('All', 'MSI', 'EXE')]
        [System.String]$ApplicationType = 'All',

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$IncludeUpdatesAndHotfixes,

        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.ScriptBlock]$FilterScript,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$Force
    )

    begin
    {
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        # Set up the name filter, as the original does.
        $nameFilterScript = if ($Name)
        {
            switch ($NameMatch)
            {
                Contains { { foreach ($eachName in $Name) { if ($appDisplayName -like "*$eachName*") { $true; break } } }; break }
                Exact { { foreach ($eachName in $Name) { if ($appDisplayName -eq $eachName) { $true; break } } }; break }
                Wildcard { { foreach ($eachName in $Name) { if ($appDisplayName -like $eachName) { $true; break } } }; break }
                Regex { { foreach ($eachName in $Name) { if ($appDisplayName -match $eachName) { $true; break } } }; break }
            }
        }
        if ($ProductCode)
        {
            Write-ADTLogEntry -Message 'The parameter [-ProductCode] refers to Windows Installer product codes; no Linux package has one, so nothing will match.' -Severity Warning
        }
    }

    process
    {
        Write-ADTLogEntry -Message "Getting information for installed applications$(if ($FilterScript) {' matching the provided FilterScript'})..."
        try
        {
            try
            {
                # ApplicationType 'MSI' maps to native distribution packages (dpkg/rpm/...), 'EXE' to flatpak/snap.
                $installedApplication = foreach ($app in (Get-ADTLinuxInstalledPackages))
                {
                    $isNative = $app.PackageManager -in 'dpkg', 'rpm', 'pacman', 'apk'
                    if ((($ApplicationType -eq 'MSI') -and !$isNative) -or (($ApplicationType -eq 'EXE') -and $isNative) -or $ProductCode)
                    {
                        continue
                    }
                    $appDisplayName = $app.DisplayName
                    if ($nameFilterScript -and !(& $nameFilterScript))
                    {
                        continue
                    }
                    if ($FilterScript -and !($app | Where-Object -FilterScript $FilterScript))
                    {
                        continue
                    }
                    $app
                }
                if ($installedApplication)
                {
                    foreach ($app in $installedApplication)
                    {
                        Write-ADTLogEntry -Message "Found installed application [$($app.DisplayName)$(if ($app.DisplayVersion) { " $($app.DisplayVersion)" })] ($($app.PackageManager))."
                    }
                    return $installedApplication
                }
                Write-ADTLogEntry -Message 'Found no application based on the supplied filters.'
            }
            catch
            {
                Write-Error -ErrorRecord $_
            }
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
}
