#-----------------------------------------------------------------------------
#
# MARK: Invoke-ADTRegSvr32
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: not supported on Linux (throws PlatformNotSupportedException).
#
#-----------------------------------------------------------------------------
function Invoke-ADTRegSvr32
{
    <#
    .SYNOPSIS
        Register or unregister a DLL file.

    .DESCRIPTION
        The `Invoke-ADTRegSvr32` function registers or unregisters a DLL file using regsvr32.exe. This function determines the bitness of the DLL file and uses the appropriate version of regsvr32.exe to perform the action. It supports both 32-bit and 64-bit DLL files on corresponding operating systems.

    .PARAMETER FilePath
        Path to the DLL file.

    .PARAMETER Action
        Specify whether to register or unregister the DLL.

    .PARAMETER AsUser
        Specifies that the DLL should be registered for the current user only by calling its DllInstall entry point with the 'user' argument (regsvr32.exe /n /i:user). If this function is running under the SYSTEM account, regsvr32.exe is executed in the context of the currently logged on user. Note that the DLL must support per-user registration via a DllInstall export for this to work.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        None

        This function does not return objects.

    .EXAMPLE
        Invoke-ADTRegSvr32 -FilePath "C:\Test\DcTLSFileToDMSComp.dll" -Action 'Register'

        Registers the specified DLL file.

    .EXAMPLE
        Invoke-ADTRegSvr32 -FilePath "C:\Test\DcTLSFileToDMSComp.dll" -Action 'Unregister'

        Unregisters the specified DLL file.

    .EXAMPLE
        Invoke-ADTRegSvr32 -FilePath "C:\Test\DcTLSFileToDMSComp.dll" -Action 'Register' -AsUser

        Registers the specified DLL file for the currently logged on user only.

    .NOTES
        An active ADT session is NOT required to use this function.

        This function supports the `-WhatIf` and `-Confirm` parameters for testing changes before applying them.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Invoke-ADTRegSvr32

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Invoke-ADTRegSvr32.ps1
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true)]
        [PSAppDeployToolkit.Attributes.ValidateExtension('.dll')]
        [ValidateScript({
                if (!(Test-Path -LiteralPath $_ -PathType Leaf))
                {
                    $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName FilePath -ProvidedValue $_ -ExceptionMessage 'The specified file does not exist.'))
                }
                return ![System.String]::IsNullOrWhiteSpace($_)
            })]
        [System.String]$FilePath,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Register', 'Unregister')]
        [System.String]$Action,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$AsUser
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
