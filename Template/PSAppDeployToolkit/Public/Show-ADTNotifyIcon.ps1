#-----------------------------------------------------------------------------
#
# MARK: Show-ADTNotifyIcon
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: Linux implementation.
#
#-----------------------------------------------------------------------------
function Show-ADTNotifyIcon
{
    <#
    .SYNOPSIS
        Displays a notification icon in the system tray.

    .DESCRIPTION
        The `Show-ADTNotifyIcon` function displays a notification icon in the system tray.

        For Windows 10 and above, balloon tips from notification icons automatically get translated by the system into toast notifications.

    .PARAMETER Force
        Creates the notification icon irrespective of whether running silently or not.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        None

        This function does not return any output.

    .EXAMPLE
        Show-ADTNotifyIcon

        Creates a notification icon with the configured icon and session title.

    .NOTES
        An active ADT session is NOT required to use this function.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Show-ADTNotifyIcon

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Show-ADTNotifyIcon.ps1
    #>

    [CmdletBinding()]
    param
    (
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
        $paramDictionary.Add('ToolTipText', [System.Management.Automation.RuntimeDefinedParameter]::new(
                'ToolTipText', [System.String], $(
                    [System.Management.Automation.ParameterAttribute]@{ Mandatory = !$adtSession; HelpMessage = 'Tool tip text for the notification icon.' }
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
            Write-ADTHeadlessBypass -Cmdlet $PSCmdlet -Detail $null
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
