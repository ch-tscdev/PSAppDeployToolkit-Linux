#-----------------------------------------------------------------------------
#
# MARK: Update-ADTDesktop
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: Linux implementation.
#
#-----------------------------------------------------------------------------
function Update-ADTDesktop
{
    <#
    .SYNOPSIS
        Refresh the Windows Explorer Shell, which causes the desktop icons and the environment variables to be reloaded.

    .DESCRIPTION
        The `Update-ADTDesktop` function refreshes the Windows Explorer Shell, causing the desktop icons and environment variables to be reloaded. This can be useful after making changes that affect the desktop or environment variables, ensuring that the changes are reflected immediately.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        None

        This function does not return any objects.

    .EXAMPLE
        Update-ADTDesktop

        Refreshes the Windows Explorer Shell, reloading the desktop icons and environment variables.

    .NOTES
        An active ADT session is NOT required to use this function.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Update-ADTDesktop

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Update-ADTDesktop.ps1
    #>

    [CmdletBinding()]
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
                # Refresh desktop/menu caches so new launchers and icons appear.
                Write-ADTLogEntry -Message 'Refreshing the desktop and application menu caches.'
                foreach ($dir in '/usr/share/applications', '/usr/local/share/applications')
                {
                    if ((Test-Path -LiteralPath $dir -PathType Container) -and (Get-Command -Name update-desktop-database -CommandType Application -ErrorAction Ignore))
                    {
                        $null = Invoke-ADTNativeCommand -FilePath update-desktop-database -ArgumentList '-q', $dir
                    }
                }
                foreach ($theme in Get-ChildItem -LiteralPath /usr/share/icons -Directory -ErrorAction Ignore)
                {
                    if ((Test-Path -LiteralPath (Join-Path $theme.FullName 'index.theme')) -and (Get-Command -Name gtk-update-icon-cache -CommandType Application -ErrorAction Ignore))
                    {
                        $null = Invoke-ADTNativeCommand -FilePath gtk-update-icon-cache -ArgumentList '-q', '-t', '-f', $theme.FullName
                    }
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
