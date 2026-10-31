#-----------------------------------------------------------------------------
#
# MARK: Get-ADTPendingReboot
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: Linux implementation.
#
#-----------------------------------------------------------------------------
function Get-ADTPendingReboot
{
    <#
    .SYNOPSIS
        Get the pending reboot status on a local computer.

    .DESCRIPTION
        The `Get-ADTPendingReboot` function checks WMI and various registry keys to determine if the system has a pending reboot operation from any of the following:

        - Component Based Servicing (Vista, Windows 2008)
        - Windows Update / Auto Update (XP, Windows 2003 / 2008)
        - SCCM 2012 Clients (DetermineIfRebootPending WMI method)
        - App-V Pending Tasks (global based Appv 5.0 SP2)
        - Intune Management Extension
        - Pending File Rename Operations (XP, Windows 2003 / 2008)

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        PSADT.DeviceManagement.RebootInfo

        Returns a RebootInfo object with the following properties:

        - ComputerName
        - LastBootUpTime
        - IsSystemRebootPending
        - IsCBServicingRebootPending
        - IsWindowsUpdateRebootPending
        - IsSCCMClientRebootPending
        - IsIntuneClientRebootPending
        - IsFileRenameRebootPending
        - PendingFileRenameOperations
        - ErrorMsg

    .EXAMPLE
        Get-ADTPendingReboot

        This example retrieves the pending reboot status on the local computer and returns a custom object with detailed information.

    .EXAMPLE
        (Get-ADTPendingReboot).IsSystemRebootPending

        This example returns a boolean value determining whether or not there is a pending reboot operation.

    .NOTES
        An active ADT session is NOT required to use this function.

        ErrorMsg only contains something if an error occurred.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Get-ADTPendingReboot

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Get-ADTPendingReboot.ps1
    #>

    [CmdletBinding()]
    [OutputType([PSADT.DeviceManagement.RebootInfo])]
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
                Write-ADTLogEntry -Message "Getting the pending reboot status on the local computer [$([System.Environment]::MachineName)]."
                $lastBoot = [System.DateTime]::Now - [System.TimeSpan]::FromSeconds([System.Double]([System.IO.File]::ReadAllText('/proc/uptime').Split(' ')[0]))
                $packages = [System.Collections.Generic.List[System.String]]::new()
                $reason = $null
                # Debian/Ubuntu: /run/reboot-required(.pkgs).
                if (Test-Path -LiteralPath /run/reboot-required -PathType Leaf)
                {
                    $reason = 'File [/run/reboot-required] exists.'
                    if (Test-Path -LiteralPath /run/reboot-required.pkgs -PathType Leaf)
                    {
                        [System.IO.File]::ReadAllLines('/run/reboot-required.pkgs') | & { process { if ($_) { $packages.Add($_) } } }
                    }
                }
                # RHEL/Fedora: needs-restarting -r returns 1 when a reboot is required.
                elseif (Get-Command -Name needs-restarting -CommandType Application -ErrorAction Ignore)
                {
                    $ec = 0
                    $null = Invoke-ADTNativeCommand -FilePath needs-restarting -ArgumentList '-r' -ExitCode ([ref]$ec)
                    if ($ec -eq 1) { $reason = 'needs-restarting -r reported that a reboot is required.' }
                }
                # SUSE: zypper needs-rebooting returns 102 when a reboot is required.
                elseif (Get-Command -Name zypper -CommandType Application -ErrorAction Ignore)
                {
                    $ec = 0
                    $null = Invoke-ADTNativeCommand -FilePath zypper -ArgumentList 'needs-rebooting' -ExitCode ([ref]$ec)
                    if ($ec -eq 102) { $reason = 'zypper needs-rebooting reported that a reboot is required.' }
                }
                # Generic: the running kernel's modules have been removed (kernel was updated).
                if (!$reason -and !(Test-Path -LiteralPath "/lib/modules/$([System.IO.File]::ReadAllText('/proc/sys/kernel/osrelease').Trim())" -PathType Container) -and (Test-Path -LiteralPath /lib/modules -PathType Container))
                {
                    $reason = 'The modules of the running kernel are no longer installed (kernel update).'
                }
                $info = [PSADT.DeviceManagement.RebootInfo]::new([System.Environment]::MachineName, $lastBoot, [System.Boolean]$reason, $packages.AsReadOnly(), $reason)
                Write-ADTLogEntry -Message "Pending reboot status on the local computer [$($info.ComputerName)]:`n$($info | Format-List | Out-ADTString)"
                return $info
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
