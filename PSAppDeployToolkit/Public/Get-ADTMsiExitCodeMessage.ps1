#-----------------------------------------------------------------------------
#
# MARK: Get-ADTMsiExitCodeMessage
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: not supported on Linux (throws PlatformNotSupportedException).
#
#-----------------------------------------------------------------------------
function Get-ADTMsiExitCodeMessage
{
    <#
    .SYNOPSIS
        Get message for MSI exit code.

    .DESCRIPTION
        Get message for MSI exit code by reading it from msimsg.dll.

    .PARAMETER MsiExitCode
        MSI exit code.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        System.String

        Returns the message for the MSI exit code.

    .EXAMPLE
        Get-ADTMsiExitCodeMessage -MsiExitCode 1618

    .NOTES
        An active ADT session is NOT required to use this function.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        http://msdn.microsoft.com/en-us/library/aa368542(v=vs.85).aspx

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Get-ADTMsiExitCodeMessage

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Get-ADTMsiExitCodeMessage.ps1
    #>

    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Nullable[System.UInt32]]$MsiExitCode
    )

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
