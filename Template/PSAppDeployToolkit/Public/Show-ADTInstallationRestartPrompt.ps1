#-----------------------------------------------------------------------------
#
# MARK: Show-ADTInstallationRestartPrompt
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: Linux implementation.
#
#-----------------------------------------------------------------------------
function Show-ADTInstallationRestartPrompt
{
    <#
    .SYNOPSIS
        Displays a restart prompt with a countdown to a forced restart.

    .DESCRIPTION
        The `Show-ADTInstallationRestartPrompt` function displays a restart prompt with a countdown to a forced restart. The prompt can be customized with a title, countdown duration, and whether it should be topmost. Restarting without showing the prompt at all only ever happens when `-AllowSilentRestart` is specified.

    .PARAMETER InteractiveCountdown
        Specifies how long to display the restart prompt. Accepts TimeSpan objects, but also interprets numerical values as seconds.

    .PARAMETER InteractiveCountdownNoHide
        Specifies how long to display the restart prompt without allowing the window to be hidden. Accepts TimeSpan objects, but also interprets numerical values as seconds.

    .PARAMETER NoInteractiveCountdown
        Specifies whether the user should receive a prompt to immediately restart their workstation.

    .PARAMETER AllowSilentRestart
        Specifies whether an automatic silent restart should be triggered when DeployMode is silent or non-interactive. Note that if a user is logged on and `-Force` is specified, a silent restart will not take place.

    .PARAMETER SilentCountdown
        Specifies how long to countdown before triggering a silent restart. Note that if a session is open, restart is triggered when the session closes. Accepts TimeSpan objects, but also interprets numerical values as seconds.

    .PARAMETER ShutdownReasonText
        Specifies the shutdown comment to provide to the underlying `shutdown.exe` call when triggering the restart.

    .PARAMETER NoForceCloseApps
        Specifies that the underlying `shutdown.exe` call should omit its `/f` switch, which is otherwise passed to force running applications closed without forewarning users. Note that an application with unsaved work can then block the restart entirely.

    .PARAMETER AllowMove
        Specifies that the user can move the dialog on the screen.

    .PARAMETER AllowCancel
        Specifies that a Cancel button is displayed alongside the restart options, allowing the user to dismiss the prompt without restarting.

    .PARAMETER CustomMessage
        Displays an additional custom message after the standard dialog text. Custom message must be populated for each language section in the `strings.psd1` file.

    .PARAMETER CustomMessageText
        Displays an additional custom message after the standard dialog text, using the supplied text. This overrides any custom message set in the `strings.psd1` file.

    .PARAMETER NotTopMost
        Specifies whether the prompt shouldn't be topmost, above all other windows.

    .PARAMETER PersistPrompt
        Specify whether to make the prompt persist, reappearing in the specified `-WindowLocation` at the `RestartPromptPersistInterval` specified in the `config.psd1` file.

    .PARAMETER WindowLocation
        The location of the dialog on the screen.

    .PARAMETER Force
        Specifies whether the restart prompt should appear irrespective of an ongoing DeploymentSession's DeployMode.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        None

        This function does not generate any output.

    .EXAMPLE
        Show-ADTInstallationRestartPrompt -NoInteractiveCountdown

        Displays a restart prompt without a countdown.

    .EXAMPLE
        Show-ADTInstallationRestartPrompt -InteractiveCountdown 300

        Displays a restart prompt with a 300-second countdown.

    .EXAMPLE
        Show-ADTInstallationRestartPrompt -InteractiveCountdown 600 -InteractiveCountdownNoHide 60

        Displays a restart prompt with a 600-second countdown, removing the ability to hide/minimise the dialog for the last 60 seconds.

    .EXAMPLE
        Show-ADTInstallationRestartPrompt -AllowSilentRestart -Force

        Displays a restart prompt that allows silent restart if nobody is logged on, otherwise will force the prompt to appear regardless of the deployment session's deploy mode.

    .NOTES
        Be mindful of the countdown you specify for the reboot as code directly after this function might NOT be able to execute - that includes logging.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Show-ADTInstallationRestartPrompt

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Show-ADTInstallationRestartPrompt.ps1
    #>

    [CmdletBinding(DefaultParameterSetName = 'InteractiveCountdown')]
    param
    (
        [Parameter(Mandatory = $false, ParameterSetName = 'InteractiveCountdown')]
        [Parameter(Mandatory = $false, ParameterSetName = 'InteractiveCountdownAllowSilentRestart')]
        [Alias('Countdown', 'CountdownSeconds')]
        [PSAppDeployToolkit.Attributes.TimeSpanTransformation()]
        [PSAppDeployToolkit.Attributes.ValidateGreaterThanZero()]
        [ValidateScript({
                if ($_.TotalSeconds -gt 86400)
                {
                    $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName InteractiveCountdown -ProvidedValue $_ -ExceptionMessage 'The specified InteractiveCountdown interval cannot exceed 86,400 seconds.'))
                }
                return !!$_
            })]
        [System.TimeSpan]$InteractiveCountdown = [System.TimeSpan]::FromSeconds($(if (!(Test-ADTModuleInitialized)) { Get-ADTDefaultConfig } else { Get-ADTConfig }).UI.RestartPromptInteractiveCountdown),

        [Parameter(Mandatory = $false, ParameterSetName = 'InteractiveCountdown')]
        [Parameter(Mandatory = $false, ParameterSetName = 'InteractiveCountdownAllowSilentRestart')]
        [Alias('CountdownNoHide', 'CountdownNoHideSeconds')]
        [PSAppDeployToolkit.Attributes.TimeSpanTransformation()]
        [PSAppDeployToolkit.Attributes.ValidateGreaterThanZero()]
        [ValidateScript({
                if ($_.TotalSeconds -gt 86400)
                {
                    $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName InteractiveCountdownNoHide -ProvidedValue $_ -ExceptionMessage 'The specified InteractiveCountdownNoHide interval cannot exceed 86,400 seconds.'))
                }
                return !!$_
            })]
        [System.TimeSpan]$InteractiveCountdownNoHide = [System.TimeSpan]::FromSeconds($(if (!(Test-ADTModuleInitialized)) { Get-ADTDefaultConfig } else { Get-ADTConfig }).UI.RestartPromptInteractiveCountdownNoHide),

        [Parameter(Mandatory = $true, ParameterSetName = 'NoInteractiveCountdown')]
        [Parameter(Mandatory = $true, ParameterSetName = 'NoInteractiveCountdownAllowSilentRestart')]
        [Alias('NoCountdown')]
        [System.Management.Automation.SwitchParameter]$NoInteractiveCountdown,

        [Parameter(Mandatory = $true, ParameterSetName = 'InteractiveCountdownAllowSilentRestart')]
        [Parameter(Mandatory = $true, ParameterSetName = 'NoInteractiveCountdownAllowSilentRestart')]
        [Alias('SilentRestart')]
        [System.Management.Automation.SwitchParameter]$AllowSilentRestart,

        [Parameter(Mandatory = $false, ParameterSetName = 'InteractiveCountdownAllowSilentRestart')]
        [Parameter(Mandatory = $false, ParameterSetName = 'NoInteractiveCountdownAllowSilentRestart')]
        [Alias('SilentCountdownSeconds')]
        [PSAppDeployToolkit.Attributes.TimeSpanTransformation()]
        [PSAppDeployToolkit.Attributes.ValidateGreaterThanZero()]
        [ValidateScript({
                if ($_.TotalSeconds -gt 86400)
                {
                    $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName SilentCountdown -ProvidedValue $_ -ExceptionMessage 'The specified SilentCountdown interval cannot exceed 86,400 seconds.'))
                }
                return !!$_
            })]
        [System.TimeSpan]$SilentCountdown = [System.TimeSpan]::FromSeconds($(if (!(Test-ADTModuleInitialized)) { Get-ADTDefaultConfig } else { Get-ADTConfig }).UI.RestartPromptSilentCountdown),

        [Parameter(Mandatory = $false)]
        [ValidateScript({
                if ([System.String]::IsNullOrWhiteSpace($_))
                {
                    $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName ShutdownReasonText -ProvidedValue $_ -ExceptionMessage 'The specified ShutdownReasonText cannot be null or whitespace.'))
                }
                if ($_.Length -gt 512)
                {
                    $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName ShutdownReasonText -ProvidedValue $_ -ExceptionMessage 'The specified ShutdownReasonText cannot exceed 512 characters in length.'))
                }
                return !!$_
            })]
        [System.String]$ShutdownReasonText,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$NoForceCloseApps,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$AllowMove,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$AllowCancel,

        [Parameter(Mandatory = $false)]
        [Alias('CustomText')]
        [System.Management.Automation.SwitchParameter]$CustomMessage,

        [Parameter(Mandatory = $false)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$CustomMessageText,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$NotTopMost,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$PersistPrompt,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [PSADT.UserInterface.DialogPosition]$WindowLocation,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$Force
    )

    dynamicparam
    {
        # Initialize variables.
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
                    [System.Management.Automation.ParameterAttribute]@{ Mandatory = !$adtSession; HelpMessage = "Title of the prompt. Optionally used to override the active DeploymentSession's `InstallTitle` value." }
                    [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpaceAttribute]::new()
                )
            ))
        $paramDictionary.Add('Subtitle', [System.Management.Automation.RuntimeDefinedParameter]::new(
                'Subtitle', [System.String], $(
                    [System.Management.Automation.ParameterAttribute]@{ Mandatory = !$adtSession; HelpMessage = "Subtitle of the prompt. Optionally used to override the subtitle defined in the `strings.psd1` file." }
                    [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpaceAttribute]::new()
                )
            ))

        # Return the populated dictionary.
        return $paramDictionary
    }

    begin
    {
        $adtSession = if (Test-ADTSessionActive) { Get-ADTSession }
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process
    {
        try
        {
            try
            {
                # There is no restart dialog on Linux; follow the original's silent path.
                $restartReason = if ($PSBoundParameters.ContainsKey('ShutdownReasonText')) { $ShutdownReasonText } else { [System.Management.Automation.Language.NullString]::Value }
                if (!$AllowSilentRestart)
                {
                    Write-ADTLogEntry -Message "Skipping restart because no restart prompt can be shown on Linux and [-AllowSilentRestart] was not specified."
                    return
                }
                $restartOnExitData = [PSAppDeployToolkit.Foundation.RestartOnExitOptions]::new($SilentCountdown, $restartReason, !!$NoForceCloseApps)
                if ($adtSession)
                {
                    Write-ADTLogEntry -Message "Triggering restart silently because no restart prompt can be shown on Linux and [-AllowSilentRestart] has been specified. Timeout is set to [$($SilentCountdown.TotalSeconds)] seconds."
                    $Script:ADT.RestartOnExitOptions = $restartOnExitData
                }
                else
                {
                    Write-ADTLogEntry -Message "Triggering restart silently in [$($SilentCountdown.TotalSeconds)] seconds."
                    Invoke-ADTSystemRestart -Options $restartOnExitData
                }
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
