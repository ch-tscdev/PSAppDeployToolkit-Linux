#-----------------------------------------------------------------------------
#
# MARK: Mount-ADTWimFile
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: not supported on Linux (throws PlatformNotSupportedException).
#
#-----------------------------------------------------------------------------
function Mount-ADTWimFile
{
    <#
    .SYNOPSIS
        Mounts a WIM file to a specified directory.

    .DESCRIPTION
        The `Mount-ADTWimFile` function mounts a WIM file to a specified directory. The function supports mounting by image index or image name. It also provides options to forcefully remove existing directories and return the mounted image details.

    .PARAMETER ImagePath
        Path to the WIM file to be mounted.

    .PARAMETER Path
        Directory where the WIM file will be mounted. The directory either must not exist, or must be empty and not have a pre-existing WIM mounted. A reparse point is refused.

        Site the mount path under a directory that standard users cannot write to. A user who can create the mount point ahead of the deployment decides where the mount actually lands, and a location off `C:\` inherits Modify for all authenticated users by default.

    .PARAMETER Index
        Index of the image within the WIM file to be mounted.

    .PARAMETER Name
        Name of the image within the WIM file to be mounted.

    .PARAMETER Force
        Forces the removal of the existing directory if it is not empty.

    .PARAMETER PassThru
        If specified, the function will return the results from `Mount-WindowsImage`.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        None

        By default, this function returns no output.

    .OUTPUTS
        Microsoft.Dism.Commands.ImageObject

        When the `-PassThru` parameter is provided, this function returns an ImageObject object representing the mounted WIM file.

    .EXAMPLE
        Mount-ADTWimFile -ImagePath 'C:\Images\install.wim' -Path 'C:\Mount' -Index 1

        Mounts the first image in the 'install.wim' file to the 'C:\Mount' directory, creating the directory if it does not exist.

    .EXAMPLE
        Mount-ADTWimFile -ImagePath 'C:\Images\install.wim' -Path 'C:\Mount' -Name 'Windows 10 Pro'

        Mounts the image named 'Windows 10 Pro' in the 'install.wim' file to the 'C:\Mount' directory, creating the directory if it does not exist.

    .EXAMPLE
        Mount-ADTWimFile -ImagePath 'C:\Images\install.wim' -Path 'C:\Mount' -Index 1 -Force

        Mounts the first image in the 'install.wim' file to the 'C:\Mount' directory, forcefully removing the existing directory if it is not empty.

    .NOTES
        An active ADT session is NOT required to use this function.

        This function supports the `-WhatIf` and `-Confirm` parameters for testing changes before applying them.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Mount-ADTWimFile

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Mount-ADTWimFile.ps1
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'Index')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Name')]
        [ValidateScript({
                if ($null -eq $_)
                {
                    $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName ImagePath -ProvidedValue $_ -ExceptionMessage 'The specified input is null.'))
                }
                $_.Refresh()
                if (!$_.Exists)
                {
                    $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName ImagePath -ProvidedValue $_ -ExceptionMessage 'The specified image path cannot be found.'))
                }
                if ([System.Uri]::new($_.FullName).IsUnc)
                {
                    $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName ImagePath -ProvidedValue $_ -ExceptionMessage 'The specified image path cannot be a network share.'))
                }
                return !!$_
            })]
        [System.IO.FileInfo]$ImagePath,

        [Parameter(Mandatory = $true, ParameterSetName = 'Index')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Name')]
        [ValidateScript({
                if ($null -eq $_)
                {
                    $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName Path -ProvidedValue $_ -ExceptionMessage 'The specified input is null.'))
                }
                if ([System.Uri]::new($_.FullName).IsUnc)
                {
                    $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName Path -ProvidedValue $_ -ExceptionMessage 'The specified mount path cannot be a network share.'))
                }
                if (Test-ADTPathIsReparsePoint -LiteralPath $_.FullName)
                {
                    $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName Path -ProvidedValue $_ -ExceptionMessage 'The specified mount path is a reparse point.'))
                }
                if (Get-ADTMountedWimFile -Path $_)
                {
                    $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName Path -ProvidedValue $_ -ExceptionMessage 'The specified mount path has a pre-existing WIM mounted.'))
                }
                return !!$_
            })]
        [System.IO.DirectoryInfo]$Path,

        [Parameter(Mandatory = $true, ParameterSetName = 'Index')]
        [ValidateNotNullOrEmpty()]
        [System.Nullable[System.UInt32]]$Index,

        [Parameter(Mandatory = $true, ParameterSetName = 'Name')]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$Name,

        [Parameter(Mandatory = $false, ParameterSetName = 'Index')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Name')]
        [System.Management.Automation.SwitchParameter]$Force,

        [Parameter(Mandatory = $false, ParameterSetName = 'Index')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Name')]
        [System.Management.Automation.SwitchParameter]$PassThru
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
