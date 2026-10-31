#-----------------------------------------------------------------------------
#
# MARK: Set-ADTActiveSetup
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: not supported on Linux (throws PlatformNotSupportedException).
#
#-----------------------------------------------------------------------------
function Set-ADTActiveSetup
{
    <#
    .SYNOPSIS
        Creates an Active Setup entry in the registry to execute a file for each user upon login.

    .DESCRIPTION
        Active Setup allows handling of per-user registry/file changes upon login.

        A registry key is created in the HKLM registry hive which gets replicated to the HKCU hive when a user logs in.

        If the "Version" value of the Active Setup entry in HKLM is higher than the version value in HKCU, the file referenced in "StubPath" is executed.

        This function:

        - Creates registry entries in: `HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\$($adtSession.InstallName)`.
        - Creates StubPath value depending on the file extension of the `-StubExePath` parameter.
        - Handles Version value with YYYYMMDDHHMMSS granularity to permit re-installs on the same day and still trigger Active Setup after Version increase.
        - Copies/overwrites the StubPath file to `-StubExePath` destination path if file exists in 'Files' subdirectory of script directory.
        - Executes the StubPath file for the current user based on the value of the `-NoExecuteForCurrentUser` parameter (no need to logout/login to trigger Active Setup).

    .PARAMETER StubExePath
        Use this parameter to specify the destination path of the file that will be executed upon user login.

        Note: Place the file you want users to execute in the '\Files' subdirectory of the script directory and the toolkit will install it to the path specified in this parameter.

    .PARAMETER ArgumentList
        Arguments to pass to the file being executed.

    .PARAMETER Wow6432Node
        Specify this switch to use Active Setup entry under WOW6432Node on a 64-bit OS.

    .PARAMETER ExecutionPolicy
        Specifies the ExecutionPolicy to set when `-StubExePath` is a PowerShell script.

    .PARAMETER Version
        Optional. Specify version for Active setup entry. Due to a Windows Active Setup/registry limitation, the entry is not triggered if the Version value contains a sequence of more than 8 digits without separators. Use separators such as commas in the version string (for example, `1,0,20240101`) to break up long digit sequences and work around this limitation.

        Note: Do not use this parameter if it is not necessary. PSADT will handle this parameter automatically using the time of the installation as the version number.

    .PARAMETER Locale
        Optional. Arbitrary string used to specify the installation language of the file being executed. Not replicated to HKCU.

    .PARAMETER PurgeActiveSetupKey
        Remove Active Setup entry from HKLM registry hive. Will also load each logon user's HKCU registry hive to remove Active Setup entry. Function returns after purging.

    .PARAMETER DisableActiveSetup
        Disables the Active Setup entry so that the StubPath file will not be executed. This also enables `-NoExecuteForCurrentUser`.

    .PARAMETER NoExecuteForCurrentUser
        Specifies whether the `-StubExePath` value should be executed for the current user. Since this user is already logged in, the user won't have the application started without logging out and logging back in.

    .PARAMETER PassThru
        Returns a ProcessResult from the execution of the ActiveSetup configuration for the current user if `-PassThru` is provided.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        None

        By default, this function returns no output.

    .OUTPUTS
        PSADT.ProcessManagement.ProcessResult

        This function returns a ProcessResult from the execution of the ActiveSetup configuration for the current user if `-PassThru` is provided.

    .EXAMPLE
        Set-ADTActiveSetup -StubExePath 'C:\Users\Public\Company\ProgramUserConfig.vbs' -ArgumentList '/Silent' -Description 'Program User Config' -Key 'ProgramUserConfig' -Locale 'en'

    .EXAMPLE
        Set-ADTActiveSetup -StubExePath "$envWinDir\regedit.exe" -ArgumentList "/S", "%SystemDrive%\Program Files (x86)\PS App Deploy\PSAppDeployHKCUSettings.reg" -Description 'PS App Deploy Config' -Key 'PS_App_Deploy_Config'

    .EXAMPLE
        Set-ADTActiveSetup -Key 'ProgramUserConfig' -PurgeActiveSetupKey

        Delete "ProgramUserConfig" active setup entry from all registry hives.

    .NOTES
        An active ADT session is NOT required to use this function.

        Original code borrowed from: Denis St-Pierre (Ottawa, Canada), Todd MacNaught (Ottawa, Canada)

        This function supports the `-WhatIf` and `-Confirm` parameters for testing changes before applying them.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Set-ADTActiveSetup

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Set-ADTActiveSetup.ps1
    #>

    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Create')]
    [OutputType([PSADT.ProcessManagement.ProcessResult])]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'Create')]
        [Parameter(Mandatory = $true, ParameterSetName = 'CreateNoExecute')]
        [PSAppDeployToolkit.Attributes.ValidateExtension('.exe', '.vbs', '.cmd', '.bat', '.ps1', '.js')]
        [System.String]$StubExePath,

        [Parameter(Mandatory = $false, ParameterSetName = 'Create')]
        [Parameter(Mandatory = $false, ParameterSetName = 'CreateNoExecute')]
        [Alias('Arguments')]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String[]]$ArgumentList,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$Wow6432Node,

        [Parameter(Mandatory = $false, ParameterSetName = 'Create')]
        [Parameter(Mandatory = $false, ParameterSetName = 'CreateNoExecute')]
        [ValidateNotNullOrEmpty()]
        [PSDefaultValue(Help = '(Get-ExecutionPolicy)')]
        [Microsoft.PowerShell.ExecutionPolicy]$ExecutionPolicy,

        [Parameter(Mandatory = $false, ParameterSetName = 'Create')]
        [Parameter(Mandatory = $false, ParameterSetName = 'CreateNoExecute')]
        [ValidateScript({
                if ([System.String]::IsNullOrWhiteSpace($_))
                {
                    $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName Version -ProvidedValue $_ -ExceptionMessage 'The specified input was null or an empty string.'))
                }
                if ($_ -notmatch '^\d+(?:(?:([.,])\d+)(?:\1\d+)*)?$')
                {
                    $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName Version -ProvidedValue $_ -ExceptionMessage 'The specified input should consist of numbers and dots/commas to separate version segments.'))
                }
                if ([System.Text.RegularExpressions.Regex]::Matches($_, '\.|,').Count -gt 3)
                {
                    $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName Version -ProvidedValue $_ -ExceptionMessage 'The specified input can only have a maximum of four octets.'))
                }
                return !!$_
            })]
        [System.String]$Version,

        [Parameter(Mandatory = $false, ParameterSetName = 'Create')]
        [Parameter(Mandatory = $false, ParameterSetName = 'CreateNoExecute')]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$Locale,

        [Parameter(Mandatory = $false, ParameterSetName = 'Create')]
        [Parameter(Mandatory = $false, ParameterSetName = 'CreateNoExecute')]
        [System.Management.Automation.SwitchParameter]$DisableActiveSetup,

        [Parameter(Mandatory = $true, ParameterSetName = 'Purge')]
        [System.Management.Automation.SwitchParameter]$PurgeActiveSetupKey,

        [Parameter(Mandatory = $true, ParameterSetName = 'CreateNoExecute')]
        [System.Management.Automation.SwitchParameter]$NoExecuteForCurrentUser,

        [Parameter(Mandatory = $false, ParameterSetName = 'Create')]
        [System.Management.Automation.SwitchParameter]$PassThru
    )

    dynamicparam
    {
        # Attempt to get the most recent ADTSession object.
        $adtSession = if (Test-ADTSessionActive)
        {
            Get-ADTSession
        }

        # Define parameter dictionary for returning at the end.
        $paramDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()

        # Add in parameters we need as mandatory when there's no active ADTSession.
        $paramDictionary.Add('Key', [System.Management.Automation.RuntimeDefinedParameter]::new(
                'Key', [System.String], $(
                    [System.Management.Automation.ParameterAttribute]@{ Mandatory = !$adtSession; HelpMessage = 'Name of the registry key for the Active Setup entry. Defaults to active session InstallName.' }
                    [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpaceAttribute]::new()
                )
            ))
        $paramDictionary.Add('Description', [System.Management.Automation.RuntimeDefinedParameter]::new(
                'Description', [System.String], $(
                    [System.Management.Automation.ParameterAttribute]@{ Mandatory = !$adtSession; HelpMessage = 'Description for the Active Setup. Users will see "Setting up personalized settings for: $Description" at logon. Defaults to active session InstallName.'; ParameterSetName = 'Create' }
                    [System.Management.Automation.ParameterAttribute]@{ Mandatory = !$adtSession; HelpMessage = 'Description for the Active Setup. Users will see "Setting up personalized settings for: $Description" at logon. Defaults to active session InstallName.'; ParameterSetName = 'CreateNoExecute' }
                    [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpaceAttribute]::new()
                )
            ))

        # Return the populated dictionary.
        return $paramDictionary
    }

    begin
    {
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process
    {
        try
        {
            Invoke-ADTLinuxNotSupported -Cmdlet $PSCmdlet
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
