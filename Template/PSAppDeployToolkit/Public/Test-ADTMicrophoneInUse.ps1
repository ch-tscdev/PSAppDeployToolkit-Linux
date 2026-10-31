#-----------------------------------------------------------------------------
#
# MARK: Test-ADTMicrophoneInUse
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: Linux implementation.
#
#-----------------------------------------------------------------------------
function Test-ADTMicrophoneInUse
{
    <#
    .SYNOPSIS
        Tests whether the device's microphone is in use.

    .DESCRIPTION
        The `Test-ADTMicrophoneInUse` function tests whether someone is using the the primary audio capture device (microphone) on the device. This could be within Teams, Zoom, a game, or any other app that uses a microphone.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        System.Boolean

        Returns `$true` if the microphone is in use, otherwise returns `$false`.

    .EXAMPLE
        Test-ADTMicrophoneInUse

        Checks if the microphone is in use and returns `$true` or `$false`.

    .NOTES
        An active ADT session is NOT required to use this function.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Test-ADTMicrophoneInUse

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Test-ADTMicrophoneInUse.ps1
    #>

    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
    )

    begin
    {
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process
    {
        try
        {
            try
            {
                Write-ADTLogEntry -Message 'Checking whether the microphone is in use...'
                # A capture device is in use when any ALSA capture substream reports a RUNNING state.
                $inUse = [System.Boolean](Get-ChildItem -Path '/proc/asound/card*/pcm*c/sub*/status' -ErrorAction Ignore | & { process { if ([System.IO.File]::ReadAllText($_.FullName) -match 'state:\s*RUNNING') { $_ } } } | Select-Object -First 1)
                Write-ADTLogEntry -Message "The microphone is$(if (!$inUse) { ' not' }) in use."
                return $inUse
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
