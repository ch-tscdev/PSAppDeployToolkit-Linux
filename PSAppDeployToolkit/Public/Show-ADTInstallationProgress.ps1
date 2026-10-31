#-----------------------------------------------------------------------------
#
# MARK: Show-ADTInstallationProgress
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: Linux implementation.
#
#-----------------------------------------------------------------------------
function Show-ADTInstallationProgress
{
    <#
    .SYNOPSIS
        Displays a progress dialog in a separate thread with an updateable custom message.

    .DESCRIPTION
        The `Show-ADTInstallationProgress` function creates a UI window in a separate thread to display a progress bar with a custom message that can be updated. The status message supports line breaks.

        The first time this function is called in a script, it will display a balloon tip notification to indicate that the installation has started (provided balloon tips are enabled in the `config.psd1` file).

    .PARAMETER StatusMessage
        The status message to be displayed. The default status message is taken from the imported `strings.psd1` file.

    .PARAMETER StatusMessageDetail
        The status message detail to be displayed with a fluent progress window. The default status message is taken from the imported `strings.psd1` file.

    .PARAMETER StatusBarPercentage
        The percentage to display on the progress bar with a fluent progress window, between 0 and 100. If null or not supplied, an indeterminate progress bar is displayed.

    .PARAMETER MessageAlignment
        The text alignment to use for the status message.

    .PARAMETER WindowLocation
        The location of the dialog on the screen.

    .PARAMETER NotTopMost
        Specifies that the progress window will not be displayed as the topmost window.

    .PARAMETER AllowMove
        Specifies that the user can move the dialog on the screen.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        None

        This function does not generate any output.

    .EXAMPLE
        Show-ADTInstallationProgress

        Uses the default status message from the `strings.psd1` file.

    .EXAMPLE
        Show-ADTInstallationProgress -StatusMessage 'Installation in Progress...'

        Displays a progress dialog with the status message 'Installation in Progress...'.

    .EXAMPLE
        Show-ADTInstallationProgress -StatusMessage "Installation in Progress...`nThe installation may take 20 minutes to complete."

        Displays a progress dialog with a multiline status message.

    .EXAMPLE
        Show-ADTInstallationProgress -StatusMessage 'Installation in Progress...' -WindowLocation 'BottomRight' -NotTopMost

        Displays a progress dialog with the status message 'Installation in Progress...', positioned at the bottom right of the screen, and not set as topmost.

    .NOTES
        An active ADT session is NOT required to use this function.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Show-ADTInstallationProgress

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Show-ADTInstallationProgress.ps1
    #>

    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $false)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$StatusMessage,

        [Parameter(Mandatory = $false)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$StatusMessageDetail,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(0, 100)]
        [System.Nullable[System.Double]]$StatusBarPercentage,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [PSDefaultValue(Help = 'Center')]
        [PSADT.UserInterface.DialogMessageAlignment]$MessageAlignment,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [PSADT.UserInterface.DialogPosition]$WindowLocation,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$NotTopMost,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$AllowMove
    )

    dynamicparam
    {
        # Get the active session if we have one, and the session state to expand the string table against.
        $adtSession = if (Test-ADTSessionActive)
        {
            Get-ADTSession
        }
        $sessionState = if ($adtSession)
        {
            $adtSession.DeployAppScriptSessionState
        }
        if ($null -eq $sessionState)
        {
            $sessionState = $PSCmdlet.SessionState
        }

        # Get the config, language and string table in the one hit.
        if (!(Test-ADTModuleInitialized))
        {
            $adtConfig = Get-ADTDefaultConfig
            $adtLanguage = Get-ADTStringLanguage -Config $adtConfig
            $adtStrings = Get-ADTDefaultStringTable -UICulture $adtLanguage -SessionState $sessionState
        }
        else
        {
            $adtConfig = Get-ADTConfig
            $adtLanguage = Get-ADTStringLanguage
            $adtStrings = Get-ADTStringTable -SessionState $sessionState
        }

        # Define parameter dictionary for returning at the end.
        $paramDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()

        # Add in parameters we need as mandatory when there's no active ADTSession.
        $paramDictionary.Add('Title', [System.Management.Automation.RuntimeDefinedParameter]::new(
                'Title', [System.String], $(
                    [System.Management.Automation.ParameterAttribute]@{ Mandatory = !$adtSession; HelpMessage = "The title of the window to be displayed. Optionally used to override the active DeploymentSession's `InstallTitle` value." }
                    [System.Management.Automation.AliasAttribute]::new('WindowTitle')
                    [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpaceAttribute]::new()
                )
            ))
        $paramDictionary.Add('Subtitle', [System.Management.Automation.RuntimeDefinedParameter]::new(
                'Subtitle', [System.String], $(
                    [System.Management.Automation.ParameterAttribute]@{ Mandatory = !$adtSession -and ($adtConfig.UI.DialogStyle -eq 'Fluent'); HelpMessage = "The subtitle of the window to be displayed with a fluent progress window. Optionally used to override the subtitle defined in the `strings.psd1` file." }
                    [System.Management.Automation.AliasAttribute]::new('WindowSubtitle')
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
            # Headless: nothing can be displayed on Linux, so log what would have been shown.
            Write-ADTHeadlessBypass -Cmdlet $PSCmdlet -Detail $(if ($PSBoundParameters.ContainsKey("StatusMessage")) { "Status message: $StatusMessage" })
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
