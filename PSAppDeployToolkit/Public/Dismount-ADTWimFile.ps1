#-----------------------------------------------------------------------------
#
# MARK: Dismount-ADTWimFile
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: not supported on Linux (throws PlatformNotSupportedException).
#
#-----------------------------------------------------------------------------
function Dismount-ADTWimFile
{
    <#
    .SYNOPSIS
        Dismounts a WIM file from the specified mount point.

    .DESCRIPTION
        The `Dismount-ADTWimFile` function dismounts a WIM file from the specified mount point and discards all changes. This function ensures that the specified path is a valid WIM mount point before attempting to dismount.

    .PARAMETER ImagePath
        The path to the WIM file.

    .PARAMETER Path
        The path to the WIM mount point.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        None

        This function does not return any objects.

    .EXAMPLE
        Dismount-ADTWimFile -ImagePath 'C:\Path\To\File.wim'

        This example dismounts the WIM file from all its mount points and discards all changes.

    .EXAMPLE
        Dismount-ADTWimFile -Path 'C:\Mount\WIM'

        This example dismounts the WIM file from the specified mount point and discards all changes.

    .NOTES
        An active ADT session is NOT required to use this function.

        This function supports the `-WhatIf` and `-Confirm` parameters for testing changes before applying them.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Dismount-ADTWimFile

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Dismount-ADTWimFile.ps1
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'ImagePath')]
        [PSAppDeployToolkit.Attributes.ValidateUnique()]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo[]]$ImagePath,

        [Parameter(Mandatory = $true, ParameterSetName = 'Path')]
        [PSAppDeployToolkit.Attributes.ValidateUnique()]
        [ValidateNotNullOrEmpty()]
        [System.IO.DirectoryInfo[]]$Path
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
