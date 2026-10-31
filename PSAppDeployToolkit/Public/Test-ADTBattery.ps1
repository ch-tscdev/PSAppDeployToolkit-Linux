#-----------------------------------------------------------------------------
#
# MARK: Test-ADTBattery
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: Linux implementation.
#
#-----------------------------------------------------------------------------
function Test-ADTBattery
{
    <#
    .SYNOPSIS
        Tests whether the local machine is running on AC power or not.

    .DESCRIPTION
        The `Test-ADTBattery` function tests whether the local machine is running on AC power and returns true/false. For detailed information, use the `-PassThru` parameter to get a hashtable containing various battery and power status properties.

    .PARAMETER PassThru
        Outputs an object containing the following properties:

        - ACPowerLineStatus
        - BatteryChargeStatus
        - BatteryLifePercent
        - BatterySaverEnabled
        - BatteryLifeRemaining
        - BatteryFullLifetime
        - IsUsingACPower
        - IsLaptop

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        System.Boolean

        By default, this function returns a Boolean where `$true` represents that the computer is running on AC power and `$false` represents that the computer is running on DC/battery power.

    .OUTPUTS
        PSADT.DeviceManagement.BatteryInfo

        Returns an object containing the following properties:

        - ACPowerLineStatus
        - BatteryChargeStatus
        - BatteryLifePercent
        - BatterySaverEnabled
        - BatteryLifeRemaining
        - BatteryFullLifetime
        - IsUsingACPower
        - IsLaptop

    .EXAMPLE
        Test-ADTBattery

        Checks if the local machine is running on AC power and returns true or false.

    .EXAMPLE
        (Test-ADTBattery -PassThru).IsLaptop

        Returns true if the current system is a laptop, otherwise false.

    .NOTES
        An active ADT session is NOT required to use this function.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Test-ADTBattery

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Test-ADTBattery.ps1
    #>

    [CmdletBinding()]
    [OutputType([System.Boolean])]
    [OutputType([PSADT.DeviceManagement.BatteryInfo])]
    param
    (
        [Parameter(Mandatory = $false)]
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
            try
            {
                Write-ADTLogEntry -Message 'Checking if system is using AC power or if it is running on battery...'
                $supplies = @(Get-ChildItem -LiteralPath /sys/class/power_supply -ErrorAction Ignore)
                $read = { param($dir, $name) try { [System.IO.File]::ReadAllText((Join-Path $dir $name)).Trim() } catch { $null } }
                $batteries = @($supplies | & { process { if ((& $read $_.FullName 'type') -eq 'Battery') { $_ } } })
                $mains = @($supplies | & { process { if ((& $read $_.FullName 'type') -in 'Mains', 'USB', 'USB_C') { $_ } } })
                $status = if ($mains | & { process { if ((& $read $_.FullName 'online') -eq '1') { $_ } } })
                {
                    [PSADT.DeviceManagement.PowerLineStatus]::Online
                }
                elseif ($mains.Count)
                {
                    [PSADT.DeviceManagement.PowerLineStatus]::Offline
                }
                elseif ($batteries | & { process { if ((& $read $_.FullName 'status') -eq 'Discharging') { $_ } } })
                {
                    [PSADT.DeviceManagement.PowerLineStatus]::Offline
                }
                elseif ($batteries.Count)
                {
                    [PSADT.DeviceManagement.PowerLineStatus]::Unknown
                }
                else
                {
                    [PSADT.DeviceManagement.PowerLineStatus]::Online
                }
                $charge = $batteries | & { process { & $read $_.FullName 'capacity' } } | Select-Object -First 1
                $chassis = try { [System.IO.File]::ReadAllText('/sys/class/dmi/id/chassis_type').Trim() } catch { $null }
                $batteryInfo = [PSADT.DeviceManagement.BatteryInfo]::new($status, [System.Boolean]$batteries.Count, ($batteries.Count -gt 0) -or ($chassis -in '8', '9', '10', '14', '31', '32'), $(if ($charge) { [System.Double]$charge }))
                switch ($status)
                {
                    ([PSADT.DeviceManagement.PowerLineStatus]::Online) { Write-ADTLogEntry -Message 'System is using AC power.'; break }
                    ([PSADT.DeviceManagement.PowerLineStatus]::Offline) { Write-ADTLogEntry -Message 'System is using battery power.'; break }
                    default { Write-ADTLogEntry -Message "System power status is [$_]. Therefore, we will report system is using AC power." }
                }
                if ($PassThru)
                {
                    return $batteryInfo
                }
                return $batteryInfo.IsUsingACPower
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
