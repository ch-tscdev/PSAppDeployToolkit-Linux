#-----------------------------------------------------------------------------
#
# MARK: Uninstall-ADTApplication
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: Linux implementation.
#
#-----------------------------------------------------------------------------
function Uninstall-ADTApplication
{
    <#
    .SYNOPSIS
        Removes one or more applications specified by name, filter script, or InstalledApplication object from `Get-ADTApplication`.

    .DESCRIPTION
        The `Uninstall-ADTApplication` function removes one or more applications specified by name, filter script, or InstalledApplication object from `Get-ADTApplication`.

        Enumerates the registry for installed applications via `Get-ADTApplication`, matching the specified application name and uninstalls that application using its uninstall string, with the ability to specify additional uninstall parameters also.

        The application will be uninstalled using its QuietUninstallString where possible. If it doesn't exist, is null, is invalid, or `-ForceUninstallString` is specified, the UninstallString will be used.

    .PARAMETER InstalledApplication
        Specifies the [PSADT.AppManagement.InstalledApplication] object to remove. This parameter is typically used when piping the output of `Get-ADTApplication` to this function.

    .PARAMETER Name
        The name of the application to retrieve information for. Performs a contains match on the application display name by default.

    .PARAMETER NameMatch
        Specifies the type of match to perform on the application name.

        Valid values for this parameter are:
        - `Contains` (default): Equivalent to `$appDisplayName -like "*$Name*"`.
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

    .PARAMETER ForceUninstallString
        Forcibly uses the UninstallString instead of QuietUninstallString.

    .PARAMETER ArgumentList
        Overrides the default MSI arguments specified in the `config.psd1` file, or the arguments found in QuietUninstallString/UninstallString for EXE applications.

    .PARAMETER AdditionalArgumentList
        Adds to the default MSI arguments specified in the `config.psd1` file, or the arguments found in QuietUninstallString/UninstallString for EXE applications.

    .PARAMETER SecureArgumentList
        Hides all arguments passed to the executable from the Toolkit log file.

    .PARAMETER LoggingOptions
        Overrides the default MSI logging options specified in the `config.psd1` file. Default options are: "/L*v".

    .PARAMETER LogFileName
        Overrides the default log file name. The default log file name is generated from the MSI file name. If the value of `-LogFileName` does not end in a common log file extension (.log, .logx, .txt, or .out), '.log' will be automatically appended.

        For uninstallations, by default the product code is resolved to the DisplayName and version of the application.

    .PARAMETER WaitForChildProcesses
        Specifies whether the started process should be considered finished only when any child processes it spawns have finished also.

    .PARAMETER KillChildProcessesWithParent
        Specifies whether any child processes started by the provided executable should be closed when the provided executable closes. This is handy for application installs that open web browsers and other programs that cannot be suppressed.

    .PARAMETER SuccessExitCodes
        List of exit codes to be considered successful. Defaults to values set during ADTSession initialization, otherwise: 0

    .PARAMETER RebootExitCodes
        List of exit codes to indicate a reboot is required. Defaults to values set during ADTSession initialization, otherwise: 1641, 3010

    .PARAMETER IgnoreExitCodes
        List the exit codes to ignore or `*` to ignore all exit codes. Where possible, please use `-SuccessExitCodes` and/or `-RebootExitCodes` instead, or `-ErrorAction SilentlyContinue` as this parameter is deprecated and will be removed in PSAppDeployToolkit 4.3.0.

    .PARAMETER ExitOnProcessFailure
        Automatically closes the active deployment session via `Close-ADTSession` in the event the process exits with a non-success or non-ignored exit code.

    .PARAMETER PassThru
        Returns an object with ExitCode, StdOut, and StdErr output from the process. Note that a failed execution will only return an object if either `-ErrorAction` is set to `SilentlyContinue`/`Ignore`, or if `-SuccessExitCodes` is used.

    .PARAMETER Force
        Allows the retrieval and/or removal of uninstall entries flagged as NoRemove or SystemComponent.

    .INPUTS
        PSADT.AppManagement.InstalledApplication

        This function can receive one or more InstalledApplication objects for uninstallation.

    .OUTPUTS
        None

        By default, this function returns no output.

    .OUTPUTS
        PSADT.ProcessManagement.ProcessResult

        Returns an object with the results of the installation if `-PassThru` is specified.
        - Process
        - LaunchInfo
        - CommandLine
        - ExitCode
        - StdOut
        - StdErr
        - Interleaved

    .EXAMPLE
        Uninstall-ADTApplication -Name 'Acrobat' -ApplicationType 'MSI' -FilterScript { $_.Publisher -match 'Adobe' }

        Removes all MSI applications that contain the name 'Acrobat' in the DisplayName and 'Adobe' in the Publisher name.

    .EXAMPLE
        Uninstall-ADTApplication -Name 'Java' -FilterScript {$_.Publisher -eq 'Oracle Corporation' -and $_.Is64BitApplication -eq $true -and $_.DisplayVersion -notlike '8.*'}

        Removes all MSI applications that contain the name 'Java' in the DisplayName, with Publisher as 'Oracle Corporation', are 64-bit, and not version 8.x.

    .EXAMPLE
        Uninstall-ADTApplication -FilterScript {$_.DisplayName -match '^Vim\s'} -Verbose -ApplicationType EXE -ArgumentList '/S'

        Remove all EXE applications starting with the name 'Vim' followed by a space, using the '/S' parameter.

    .NOTES
        An active ADT session is NOT required to use this function.

        More reading on how to create filterscripts https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/where-object?view=powershell-5.1#description

        This function supports the `-WhatIf` and `-Confirm` parameters for testing changes before applying them.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Uninstall-ADTApplication

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Uninstall-ADTApplication.ps1
    #>

    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'NameMatch', Justification = "This parameter is used within delegates that PSScriptAnalyzer has no visibility of. See https://github.com/PowerShell/PSScriptAnalyzer/issues/1472 for more details.")]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'ApplicationType', Justification = "This parameter is used within delegates that PSScriptAnalyzer has no visibility of. See https://github.com/PowerShell/PSScriptAnalyzer/issues/1472 for more details.")]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'IncludeUpdatesAndHotfixes', Justification = "This parameter is used within delegates that PSScriptAnalyzer has no visibility of. See https://github.com/PowerShell/PSScriptAnalyzer/issues/1472 for more details.")]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'LoggingOptions', Justification = "This parameter is used/retrieved via Get-ADTBoundParametersAndDefaultValues, which is too advanced for PSScriptAnalyzer to comprehend.")]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'LogFileName', Justification = "This parameter is used/retrieved via Get-ADTBoundParametersAndDefaultValues, which is too advanced for PSScriptAnalyzer to comprehend.")]
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSADT.ProcessManagement.ProcessResult])]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'InstalledApplication', ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [PSAppDeployToolkit.Attributes.ValidateUnique()]
        [PSADT.AppManagement.InstalledApplication[]]$InstalledApplication,

        [Parameter(Mandatory = $false, ParameterSetName = 'Search')]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String[]]$Name,

        [Parameter(Mandatory = $false, ParameterSetName = 'Search')]
        [ValidateSet('Contains', 'Exact', 'Wildcard', 'Regex')]
        [System.String]$NameMatch = 'Contains',

        [Parameter(Mandatory = $false, ParameterSetName = 'Search')]
        [ValidateNotNullOrEmpty()]
        [System.Guid[]]$ProductCode,

        [Parameter(Mandatory = $false, ParameterSetName = 'Search')]
        [ValidateSet('All', 'MSI', 'EXE')]
        [System.String]$ApplicationType = 'All',

        [Parameter(Mandatory = $false, ParameterSetName = 'Search')]
        [System.Management.Automation.SwitchParameter]$IncludeUpdatesAndHotfixes,

        [Parameter(Mandatory = $false, ParameterSetName = 'Search', Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.ScriptBlock]$FilterScript,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$ForceUninstallString,

        [Parameter(Mandatory = $false)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String[]]$ArgumentList,

        [Parameter(Mandatory = $false)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String[]]$AdditionalArgumentList,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$SecureArgumentList,

        [Parameter(Mandatory = $false)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$LoggingOptions,

        [Parameter(Mandatory = $false)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$LogFileName,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.SwitchParameter]$WaitForChildProcesses,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.SwitchParameter]$KillChildProcessesWithParent,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.Int32[]]$SuccessExitCodes,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.Int32[]]$RebootExitCodes,

        [Parameter(Mandatory = $false)]
        [System.Obsolete("Please use '-ErrorAction SilentlyContinue' instead as this will be removed in PSAppDeployToolkit 4.3.0.")]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [SupportsWildcards()]
        [System.String[]]$IgnoreExitCodes,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$ExitOnProcessFailure,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$PassThru,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$Force
    )

    begin
    {
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        if ($PSCmdlet.ParameterSetName -ne 'InstalledApplication')
        {
            if (!($PSBoundParameters.Keys -match '^(Name|ProductCode|FilterScript)$'))
            {
                $naerParams = @{
                    Exception = [System.InvalidOperationException]::new('Either Name, ProductCode or FilterScript are required if not using pipeline.')
                    Category = [System.Management.Automation.ErrorCategory]::InvalidArgument
                    ErrorId = 'NullParameterValue'
                    RecommendedAction = "Review the supplied parameter values and try again."
                }
                $PSCmdlet.ThrowTerminatingError((New-ADTErrorRecord @naerParams))
            }
            $gaiaParams = Get-ADTBoundParametersAndDefaultValues -Invocation $MyInvocation -Exclude ForceUninstallString, ArgumentList, AdditionalArgumentList, LoggingOptions, LogFileName, PassThru, SecureArgumentList, SuccessExitCodes, RebootExitCodes, IgnoreExitCodes, WaitForChildProcesses, KillChildProcessesWithParent, ExitOnProcessFailure
            if (($installedApps = Get-ADTApplication @gaiaParams))
            {
                $InstalledApplication = $installedApps
            }
        }

        # Parameters passed through to Start-ADTProcess.
        $sapParams = @{
            SecureArgumentList = $SecureArgumentList
            WaitForChildProcesses = $WaitForChildProcesses
            KillChildProcessesWithParent = $KillChildProcessesWithParent
            ExitOnProcessFailure = $ExitOnProcessFailure
            CreateNoWindow = $true
        }
        foreach ($param in 'SuccessExitCodes', 'RebootExitCodes', 'IgnoreExitCodes', 'PassThru')
        {
            if ($PSBoundParameters.ContainsKey($param))
            {
                $sapParams.Add($param, $PSBoundParameters.$param)
            }
        }
        if ($PSBoundParameters.ContainsKey('LoggingOptions') -or $PSBoundParameters.ContainsKey('LogFileName'))
        {
            Write-ADTLogEntry -Message 'The parameters [-LoggingOptions]/[-LogFileName] are MSI-specific and have no effect on Linux; package manager output is written to the toolkit log.'
        }
    }

    process
    {
        if (!$InstalledApplication)
        {
            Write-ADTLogEntry -Message 'No applications found for removal.'
            return
        }
        foreach ($removeApplication in $InstalledApplication)
        {
            try
            {
                if (!($command = Get-ADTLinuxUninstallCommand -Application $removeApplication))
                {
                    Write-ADTLogEntry -Message "No uninstall method found for application [$($removeApplication.DisplayName)] ($($removeApplication.PackageManager)). Skipping removal." -Severity Warning
                    continue
                }
                $arguments = if ($PSBoundParameters.ContainsKey('ArgumentList')) { $ArgumentList } else { $command[1] }
                if ($AdditionalArgumentList)
                {
                    $arguments = @($arguments) + @($AdditionalArgumentList)
                }
                Write-ADTLogEntry -Message "Removing $($removeApplication.PackageManager) package [$($removeApplication.DisplayName)$(if ($removeApplication.DisplayVersion) { " $($removeApplication.DisplayVersion)" })]..."
                if (!$PSCmdlet.ShouldProcess("Application [$($removeApplication.DisplayName)]", 'Uninstall'))
                {
                    continue
                }
                $previousFrontend = $env:DEBIAN_FRONTEND
                $env:DEBIAN_FRONTEND = 'noninteractive'
                try
                {
                    if (($result = Start-ADTProcess @sapParams -FilePath $command[0] -ArgumentList $arguments -ErrorAction $OriginalErrorAction) -and $PassThru)
                    {
                        $result
                    }
                }
                catch
                {
                    Write-Error -ErrorRecord $_
                }
                finally
                {
                    $env:DEBIAN_FRONTEND = $previousFrontend
                }
            }
            catch
            {
                Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
            }
        }
    }

    end
    {
        Complete-ADTFunction -Cmdlet $PSCmdlet
    }
}
