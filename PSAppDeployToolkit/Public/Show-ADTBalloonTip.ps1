#-----------------------------------------------------------------------------
#
# MARK: Show-ADTBalloonTip
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: Linux implementation.
#
#-----------------------------------------------------------------------------
function Show-ADTBalloonTip
{
    <#
    .SYNOPSIS
        Displays a balloon tip notification in the system tray.

    .DESCRIPTION
        The `Show-ADTBalloonTip` function displays a balloon tip notification in the system tray. This function can be used to show notifications to the user with customizable text, title, icon, and display duration.

        For Windows 10 and above, balloon tips automatically get translated by the system into toast notifications.

    .PARAMETER Text
        Text of the balloon tip.

    .PARAMETER Icon
        Icon to be used. Valid values for this parameter are: `Error`, `Info`, `None`, `Warning`.

    .PARAMETER Timeout
        This parameter has had no effect since Windows Vista and will be removed in PSAppDeployToolkit 4.3.0.

    .PARAMETER NoWait
        This parameter has had no effect since Windows Vista and will be removed in PSAppDeployToolkit 4.3.0.

    .PARAMETER Force
        Creates the balloon tip irrespective of whether running silently or not.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        None

        This function does not return any output.

    .EXAMPLE
        Show-ADTBalloonTip -Text 'Installation Started' -Title 'Application Name'

        Displays a balloon tip with the text 'Installation Started' and the title 'Application Name'.

    .EXAMPLE
        Show-ADTBalloonTip -Icon 'Info' -Text 'Installation Started' -Title 'Application Name'

        Displays a balloon tip with the info icon, the text 'Installation Started', and the title 'Application Name'

    .NOTES
        An active ADT session is NOT required to use this function.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Show-ADTBalloonTip

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Show-ADTBalloonTip.ps1
    #>

    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Icon', Justification = "This parameter is used via the function's PSBoundParameters dictionary, which is not something PSScriptAnalyzer understands. See https://github.com/PowerShell/PSScriptAnalyzer/issues/1472 for more details.")]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [Alias('BalloonTipText')]
        [System.String]$Text,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Alias('BalloonTipIcon')]
        [PSADT.UserInterface.BalloonTipIcon]$Icon = [PSADT.UserInterface.BalloonTipIcon]::Info,

        [Parameter(Mandatory = $false)]
        [System.Obsolete('This parameter will be removed in PSAppDeployToolkit 4.3.0.')]
        [PSAppDeployToolkit.Attributes.ValidateGreaterThanZero()]
        [Alias('BalloonTipTime')]
        [System.UInt32]$Timeout,

        [Parameter(Mandatory = $false)]
        [System.Obsolete('This parameter will be removed in PSAppDeployToolkit 4.3.0.')]
        [System.Management.Automation.SwitchParameter]$NoWait,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$Force
    )

    dynamicparam
    {
        # Get the active session if we have one.
        $adtSession = if (Test-ADTSessionActive)
        {
            Get-ADTSession
        }

        # Define parameter dictionary for returning at the end.
        $paramDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()

        # Add in parameters we need as mandatory when there's no active ADTSession.
        $paramDictionary.Add('Title', [System.Management.Automation.RuntimeDefinedParameter]::new(
                'Title', [System.String], $(
                    [System.Management.Automation.ParameterAttribute]@{ Mandatory = !$adtSession; HelpMessage = 'Title of the balloon tip.' }
                    [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpaceAttribute]::new()
                    [System.Management.Automation.AliasAttribute]::new('BalloonTipTitle')
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
