#-----------------------------------------------------------------------------
#
# MARK: Initialize-ADTModule
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: Linux implementation.
#
#-----------------------------------------------------------------------------
function Initialize-ADTModule
{
    <#
    .SYNOPSIS
        Initializes the PSAppDeployToolkit module by setting up necessary configurations and environment.

    .DESCRIPTION
        The `Initialize-ADTModule` function sets up the environment for the PSAppDeployToolkit module by initializing necessary variables, configurations, and string tables. It ensures that the module is not initialized while there is an active ADT session in progress. This function prepares the module for use by clearing callbacks, sessions, and setting up the environment table.

    .PARAMETER ScriptDirectory
        An override directory to use for config and string loading.

    .PARAMETER AdditionalEnvironmentVariables
        A dictionary of key/value pairs to inject into the generated environment table.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        None

        This function does not return any output.

    .EXAMPLE
        Initialize-ADTModule

        Initializes the PSAppDeployToolkit module with the default settings and configurations.

    .NOTES
        An active ADT session is NOT required to use this function.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Initialize-ADTModule

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Initialize-ADTModule.ps1
    #>

    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $false)]
        [ValidateScript({
                if ([System.String]::IsNullOrWhiteSpace($_))
                {
                    $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName ScriptDirectory -ProvidedValue $_ -ExceptionMessage 'The specified input is null or empty.'))
                }
                if (!(Test-Path -LiteralPath $_ -PathType Container))
                {
                    $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName ScriptDirectory -ProvidedValue $_ -ExceptionMessage 'The specified directory does not exist.'))
                }
                return $_
            })]
        [PSAppDeployToolkit.Attributes.ValidateUnique()]
        [System.String[]]$ScriptDirectory = (Get-ADTModuleDirectory),

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.Collections.IDictionary]$AdditionalEnvironmentVariables
    )

    begin
    {
        # Log our start time to clock the module init duration.
        $moduleInitStart = [System.DateTime]::Now
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -InformationAction SilentlyContinue
        $null = $PSBoundParameters.Remove('ScriptDirectory')

        # Throw if this function is called while a session is active.
        if (Test-ADTSessionActive)
        {
            $naerParams = @{
                Exception = [System.InvalidOperationException]::new("This function cannot be called while there is an active ADTSession in progress.")
                Category = [System.Management.Automation.ErrorCategory]::InvalidOperation
                ErrorId = 'InitWithActiveSessionError'
                TargetObject = Get-ADTSession
                RecommendedAction = "Please attempt module re-initialization once the active ADTSession(s) have been closed."
            }
            $PSCmdlet.ThrowTerminatingError((New-ADTErrorRecord @naerParams))
        }

        # Returns the Config/Strings subdirectories of the script directories that contain a data file.
        function Get-ADTScriptSubdirectory
        {
            param ([System.String]$Subdirectory)
            foreach ($directory in $ScriptDirectory)
            {
                if (Test-Path -LiteralPath (Join-Path -Path $directory -ChildPath "$Subdirectory/$($Subdirectory.ToLowerInvariant()).psd1") -PathType Leaf)
                {
                    [System.IO.DirectoryInfo](Join-Path -Path $directory -ChildPath $Subdirectory)
                }
            }
        }
    }

    process
    {
        try
        {
            try
            {
                $configDirectories = @(Get-ADTScriptSubdirectory -Subdirectory Config)
                $stringsDirectories = @(Get-ADTScriptSubdirectory -Subdirectory Strings)
                if (Test-ADTModuleInitialized)
                {
                    Reset-ADTModuleState
                }
                foreach ($callback in (Get-ADTModuleCallback -Hookpoint OnInit | & { process { return $_ } }))
                {
                    & $callback
                }
                $environment = New-ADTEnvironmentTable @PSBoundParameters
                $config = Import-ADTConfig -BaseDirectory $configDirectories -Environment $environment
                $language = Get-ADTStringLanguage -Environment $environment -Config $config
                $stringTable = Import-ADTStringTable -BaseDirectory $stringsDirectories -Config $config -UICulture $language

                $Script:ADT.Directories = [ordered]@{
                    Script = [System.String[]]$ScriptDirectory
                    Config = $(if ($configDirectories) { [System.String[]]$configDirectories.FullName })
                    Strings = $(if ($stringsDirectories) { [System.String[]]$stringsDirectories.FullName })
                }
                $Script:ADT.Environment = $environment
                $Script:ADT.Config = $config
                $Script:ADT.Strings = $stringTable
                $Script:ADT.Language = $language
                $Script:ADT.Initialized = $true
                $Script:ADT.InitDuration = [System.DateTime]::Now - $moduleInitStart
                [PSAppDeployToolkit.Foundation.ModuleDatabase]::Config = $config
                [PSAppDeployToolkit.Foundation.ModuleDatabase]::Strings = $stringTable
                [PSAppDeployToolkit.Foundation.ModuleDatabase]::Environment = $environment
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
        Complete-ADTFunction -Cmdlet $PSCmdlet -InformationAction SilentlyContinue
    }
}
