#-----------------------------------------------------------------------------
#
# MARK: Show-ADTInstallationPrompt
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: Linux implementation.
#
#-----------------------------------------------------------------------------
function Show-ADTInstallationPrompt
{
    <#
    .SYNOPSIS
        Displays a custom installation prompt with the toolkit branding and optional buttons.

    .DESCRIPTION
        The `Show-ADTInstallationPrompt` function displays a custom installation prompt with the toolkit branding and optional buttons. Any combination of Left, Middle, or Right buttons can be displayed. The return value of the button clicked by the user is the button text specified. The prompt can also display a system icon and be configured to persist, minimize other windows, or timeout after a specified period.

    .PARAMETER RequestInput
        Show a text box for the user to provide an answer.

    .PARAMETER DefaultValue
        The default value to show in the text box.

    .PARAMETER SecureInput
        Indicates input should be masked (i.e. for password use).

        Changes the returned type to `SecureInputDialogResult`, whose `Text` property is a `System.Security.SecureString` rather than a string. The value is protected across the client/server boundary by the encrypted channel the two processes negotiate; it cannot be carried as a `SecureString` itself, because that type's memory protection is scoped to the process that created it.

        Requires the Fluent dialog style, as `-RequestInput` does on its own. Under `DialogStyle = Classic` the dialog throws at runtime, since an input dialog is only implemented for Fluent.

    .PARAMETER Message
        The message text to be displayed on the prompt.

    .PARAMETER MessageAlignment
        Alignment of the message text.

    .PARAMETER ButtonLeftText
        Show a button on the left of the prompt with the specified text.

    .PARAMETER ButtonRightText
        Show a button on the right of the prompt with the specified text.

    .PARAMETER ButtonMiddleText
        Show a button in the middle of the prompt with the specified text.

    .PARAMETER DefaultButton
        Specifies the default button to accent within the user interface.

    .PARAMETER Icon
        Show a system icon in the prompt.

    .PARAMETER WindowLocation
        The location of the dialog on the screen.

    .PARAMETER NoWait
        Presents the dialog in a separate, independent thread so that the main process isn't stalled waiting for a response.

    .PARAMETER PersistPrompt
        Specify whether to make the prompt persist, reappearing in the specified `-WindowLocation` at the interval specified in the `config.psd1` file. The user will have no option but to respond to the prompt.

    .PARAMETER MinimizeWindows
        Specifies whether to minimize other windows when displaying prompt.

    .PARAMETER ListItems
        An array of strings to display as a dropdown list for user selection. When specified, a ListSelectionDialog is shown with a ComboBox containing these items. The selected item is included in the returned ListSelectionDialogResult object.

    .PARAMETER DefaultIndex
        The default selected item index for the dropdown list. This value must be equal or greater than zero, and less than the count of ListItems.

    .PARAMETER NoExitOnTimeout
        Specifies whether to not exit the script if the UI times out.

    .PARAMETER NotTopMost
        Specifies whether the prompt shouldn't be topmost, above all other windows.

    .PARAMETER AllowMove
        Specifies that the user can move the dialog on the screen.

    .PARAMETER Force
        Specifies whether the message box should appear irrespective of an ongoing DeploymentSession's DeployMode.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        PSADT.UserInterface.DialogResults.CustomDialogResult

    .OUTPUTS
        PSADT.UserInterface.DialogResults.InputDialogResult

    .OUTPUTS
        PSADT.UserInterface.DialogResults.ListSelectionDialogResult

    .OUTPUTS
        PSADT.UserInterface.DialogResults.SecureInputDialogResult

        Returns the dialog's result unless `-NoWait` is specified, in which case nothing is returned. The concrete type depends on the parameter set: `InputDialogResult` for `-RequestInput`, `SecureInputDialogResult` when `-SecureInput` is added to it, `ListSelectionDialogResult` for `-ListItems`, and `CustomDialogResult` otherwise. Each exposes a `Result` property holding the text of the button the user clicked.

    .EXAMPLE
        ```powershell
        $result = Show-ADTInstallationPrompt -Message 'Do you want to proceed with the installation?' -ButtonLeftText Yes -ButtonRightText No
        switch ($result)
        {
            Yes {
                Write-ADTLogEntry "User clicked the [Yes] button."
            }
            No {
                Write-ADTLogEntry "User clicked the [No] button."
            }
        }
        ```

    .EXAMPLE
        Show-ADTInstallationPrompt -Title 'Funny Prompt' -Message 'How are you feeling today?' -ButtonLeftText 'Good' -ButtonRightText 'Bad' -ButtonMiddleText 'Indifferent'

    .EXAMPLE
        Show-ADTInstallationPrompt -Message 'You can customize text to appear at the end of an install, or remove it completely for unattended installations.' -ButtonLeftText 'OK' -Icon Information -NoWait -Timeout (New-TimeSpan -Hours 1)

    .EXAMPLE
        Show-ADTInstallationPrompt -RequestInput -Message 'Tell us why you think PSADT is the best thing since sliced bread.' -ButtonRightText 'Submit'

    .EXAMPLE
        Show-ADTInstallationPrompt -RequestInput -DefaultValue 'XXXX' -Message 'Please type in your favourite beer.' -ButtonRightText 'Submit'

    .EXAMPLE
        ```powershell
        $result = Show-ADTInstallationPrompt -Message 'Select your preferred configuration:' -ListItems @('Default', 'Minimal', 'Full', 'Custom') -DefaultIndex 0 -ButtonRightText 'OK'
        Write-ADTLogEntry "User selected: $($result.SelectedItem)"
        ```

    .NOTES
        An active ADT session is NOT required to use this function.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Show-ADTInstallationPrompt

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Show-ADTInstallationPrompt.ps1
    #>

    [CmdletBinding(DefaultParameterSetName = 'ShowCustomDialog')]
    [OutputType([PSADT.UserInterface.DialogResults.CustomDialogResult])]
    [OutputType([PSADT.UserInterface.DialogResults.InputDialogResult])]
    [OutputType([PSADT.UserInterface.DialogResults.ListSelectionDialogResult])]
    [OutputType([PSADT.UserInterface.DialogResults.SecureInputDialogResult])]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'ShowInputDialog')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ShowInputDialog_DefaultValue')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ShowSecureInputDialog')]
        [System.Management.Automation.SwitchParameter]$RequestInput,

        [Parameter(Mandatory = $true, ParameterSetName = 'ShowInputDialog_DefaultValue')]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$DefaultValue,

        [Parameter(Mandatory = $true, ParameterSetName = 'ShowSecureInputDialog')]
        [System.Management.Automation.SwitchParameter]$SecureInput,

        [Parameter(Mandatory = $true)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [PSADT.UserInterface.DialogMessageAlignment]$MessageAlignment = [PSADT.UserInterface.DialogMessageAlignment]::Center,

        [Parameter(Mandatory = $false)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$ButtonRightText,

        [Parameter(Mandatory = $false)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$ButtonLeftText,

        [Parameter(Mandatory = $false)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$ButtonMiddleText,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [PSADT.UserInterface.DialogDefaultButton]$DefaultButton,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [PSADT.UserInterface.DialogSystemIcon]$Icon,

        [Parameter(Mandatory = $true, ParameterSetName = 'ShowListSelectionDialog')]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [PSAppDeployToolkit.Attributes.ValidateUnique()]
        [System.String[]]$ListItems,

        [Parameter(Mandatory = $false, ParameterSetName = 'ShowListSelectionDialog')]
        [ValidateNotNullOrEmpty()]
        [System.Nullable[System.UInt32]]$DefaultIndex,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [PSADT.UserInterface.DialogPosition]$WindowLocation,

        [Parameter(Mandatory = $false, ParameterSetName = 'ShowCustomDialog')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ShowListSelectionDialog')]
        [System.Management.Automation.SwitchParameter]$NoWait,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$PersistPrompt,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$MinimizeWindows,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$NoExitOnTimeout,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$NotTopMost,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$AllowMove,

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
        $paramDictionary.Add('Timeout', [System.Management.Automation.RuntimeDefinedParameter]::new(
                'Timeout', [System.TimeSpan], $(
                    [System.Management.Automation.ParameterAttribute]@{ Mandatory = $false; HelpMessage = 'Specifies how long to show the message prompt before aborting.' }
                    [PSAppDeployToolkit.Attributes.TimeSpanTransformationAttribute]::new()
                    [PSAppDeployToolkit.Attributes.ValidateGreaterThanZeroAttribute]::new()
                    [System.Management.Automation.ValidateScriptAttribute]::new({
                            if (!($PSBoundParameters.ContainsKey('NoWait') -and $PSBoundParameters.NoWait) -and ($_.TotalSeconds -gt $adtConfig.UI.DefaultTimeout))
                            {
                                $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName Timeout -ProvidedValue $_ -ExceptionMessage 'The installation UI dialog timeout cannot be longer than the timeout specified in the config.psd1 file.'))
                            }
                            return !!$_
                        })
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
            # Same behaviour as the original in NonInteractive/Silent mode: log the message and return nothing.
            Write-ADTHeadlessBypass -Cmdlet $PSCmdlet -Detail "Message: $Message"
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
