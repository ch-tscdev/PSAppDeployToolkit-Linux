#-----------------------------------------------------------------------------
#
# MARK: Show-ADTDialogBox
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: Linux implementation.
#
#-----------------------------------------------------------------------------
function Show-ADTDialogBox
{
    <#
    .SYNOPSIS
        Display a custom dialog box with optional title, buttons, icon, and timeout.

    .DESCRIPTION
        The `Show-ADTDialogBox` function displays a custom dialog box with optional title, buttons, icon, and timeout. The default button is "OK", the default Icon is "None", and the default Timeout is None.

        `Show-ADTInstallationPrompt` is recommended over this function as it provides more customization and uses consistent branding with the other UI components.

    .PARAMETER Text
        Text in the message dialog box.

    .PARAMETER Buttons
        The button(s) to display on the dialog box.

    .PARAMETER DefaultButton
        The Default button that is selected. Valid values for this parameter are: `First`, `Second`, `Third`.

    .PARAMETER Icon
        Icon to display on the dialog box. Valid values for this parameter are: `None`, `Stop`, `Question`, `Exclamation`, `Information`.

    .PARAMETER NoWait
        Presents the dialog in a separate, independent thread so that the main process isn't stalled waiting for a response.

    .PARAMETER ExitOnTimeout
        Specifies whether the script should continue running when the UI times out.

    .PARAMETER NotTopMost
        Specifies whether the message box shouldn't be a system modal message box that appears in a topmost window.

    .PARAMETER Force
        Specifies whether the message box should appear irrespective of an ongoing DeploymentSession's DeployMode.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        PSADT.UserInterface.DialogResults.DialogBoxResult

        Returns the text of the button that was clicked.

    .EXAMPLE
        Show-ADTDialogBox -Title 'Installation Notice' -Text 'Installation will take approximately 30 minutes. Do you wish to proceed?' -Buttons 'OKCancel' -DefaultButton 'Second' -Icon 'Exclamation' -Timeout 600 -NotTopMost

    .NOTES
        An active ADT session is NOT required to use this function.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Show-ADTDialogBox

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Show-ADTDialogBox.ps1
    #>

    [CmdletBinding()]
    [OutputType([PSADT.UserInterface.DialogResults.DialogBoxResult])]
    param
    (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'Enter a message for the dialog box.')]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$Text,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [PSADT.UserInterface.DialogBoxButtons]$Buttons = [PSADT.UserInterface.DialogBoxButtons]::Ok,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [PSADT.UserInterface.DialogBoxDefaultButton]$DefaultButton = [PSADT.UserInterface.DialogBoxDefaultButton]::First,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [PSADT.UserInterface.DialogBoxIcon]$Icon,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$NoWait,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$ExitOnTimeout,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$NotTopMost,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$Force
    )

    dynamicparam
    {
        # Get the config, and the active session if we have one.
        $adtConfig = if (!(Test-ADTModuleInitialized)) { Get-ADTDefaultConfig } else { Get-ADTConfig }
        $adtSession = if (Test-ADTSessionActive)
        {
            Get-ADTSession
        }

        # Define parameter dictionary for returning at the end.
        $paramDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()

        # Add in parameters we need as mandatory when there's no active ADTSession.
        $paramDictionary.Add('Title', [System.Management.Automation.RuntimeDefinedParameter]::new(
                'Title', [System.String], $(
                    [System.Management.Automation.ParameterAttribute]@{ Mandatory = !$adtSession; HelpMessage = 'Title of the message dialog box.' }
                    [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpaceAttribute]::new()
                )
            ))
        $paramDictionary.Add('Timeout', [System.Management.Automation.RuntimeDefinedParameter]::new(
                'Timeout', [System.TimeSpan], $(
                    [System.Management.Automation.ParameterAttribute]@{ Mandatory = $false; HelpMessage = 'Specifies how long to show the message prompt before aborting. Accepts TimeSpan objects, but also interprets numerical values as seconds.' }
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
            # Same behaviour as the original in NonInteractive/Silent mode: log the text and return nothing.
            Write-ADTHeadlessBypass -Cmdlet $PSCmdlet -Detail "Text: $Text"
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
