#-----------------------------------------------------------------------------
#
# MARK: Set-ADTServiceStartMode
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: Linux implementation.
#
#-----------------------------------------------------------------------------
function Set-ADTServiceStartMode
{
    <#
    .SYNOPSIS
        Set the service startup mode.

    .DESCRIPTION
        The `Set-ADTServiceStartMode` function sets the service startup mode. This function allows you to configure the startup mode of a specified service. The startup modes available are: Automatic, Automatic (Delayed Start), Manual, Disabled, Boot, and System.

    .PARAMETER Name
        Specifies the service name(s) of the services to set the start mode for. Wildcards are permitted.

    .PARAMETER DisplayName
        Specifies the display name(s) of services to set the start mode for. Wildcards are permitted.

    .PARAMETER InputObject
        Specifies `ServiceController` object(s) representing the services to be started.

    .PARAMETER StartMode
        Specify startup mode for the service. Valid values for this parameter are: `Automatic`, `Automatic (Delayed Start)`, `Manual`, `Disabled`, `Boot`, `System`

    .PARAMETER PassThru
        Returns the `ServiceController` service object.

    .INPUTS
        System.ServiceProcess.ServiceController

        You can pipe `ServiceController` objects to this function.

    .OUTPUTS
        None

        By default, this function does not return any output.

    .OUTPUTS
        System.ServiceProcess.ServiceController

        When the `-PassThru` parameter is provided, this function returns a `ServiceController` object representing the service that was started.

    .EXAMPLE
        Set-ADTServiceStartMode -Name 'wuauserv' -StartMode 'Automatic (Delayed Start)'

        Sets the 'wuauserv' service to start automatically with a delayed start.

    .EXAMPLE
        Set-ADTServiceStartMode -DisplayName 'Windows Update' -StartMode 'Manual'

        Sets the Windows Update service to start manually.

    .EXAMPLE
        ```PowerShell
        if ((($service = Test-ADTServiceExists -Name 'ScreenConnect*' -PassThru) | Get-ADTServiceStartMode) -ne 'Automatic')
        {
            Set-ADTServiceStartMode -InputObject $service -StartMode 'Automatic'
        }
        ```

        Sets the ScreenConnect service start mode to automatic, if it exists and has its start mode is not automatic.

    .NOTES
        An active ADT session is NOT required to use this function.

        This function supports the `-WhatIf` and `-Confirm` parameters for testing changes before applying them.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Set-ADTServiceStartMode

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Set-ADTServiceStartMode.ps1
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSADT.ServiceManagement.SystemdService])]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'Name')]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [PSAppDeployToolkit.Attributes.ValidateUnique()]
        [SupportsWildcards()]
        [System.String[]]$Name,

        [Parameter(Mandatory = $true, ParameterSetName = 'DisplayName')]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [PSAppDeployToolkit.Attributes.ValidateUnique()]
        [SupportsWildcards()]
        [System.String[]]$DisplayName,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'InputObject')]
        [ValidateScript({
                if ($null -eq $_)
                {
                    $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName InputObject -ProvidedValue $_ -ExceptionMessage 'The provided input cannot be null.'))
                }
                if (!$_.ServiceName)
                {
                    $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName InputObject -ProvidedValue $_ -ExceptionMessage 'The specified service does not exist.'))
                }
                return !!$_
            })]
        [Alias('Service')]
        [PSADT.ServiceManagement.SystemdService[]]$InputObject,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Automatic', 'Automatic (Delayed Start)', 'Manual', 'Disabled', 'Boot', 'System')]
        [System.String]$StartMode,

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
                $services = Get-ADTSystemdServices -ParameterSetName $PSCmdlet.ParameterSetName -BoundParameters $PSBoundParameters
                foreach ($service in $services)
                {
                    # Automatic* -> enable (and unmask); Manual -> disable (and unmask); Disabled -> mask. Boot/System have no equivalent.
                    $actions = switch -Wildcard ($StartMode)
                    {
                        'Automatic*' { 'unmask', 'enable' }
                        'Manual' { 'unmask', 'disable' }
                        'Disabled' { 'mask' }
                        default { throw [System.NotSupportedException]::new("The startup mode [$StartMode] has no systemd equivalent.") }
                    }
                    if ($StartMode -eq 'Automatic (Delayed Start)')
                    {
                        Write-ADTLogEntry -Message "systemd has no delayed start; [$StartMode] is applied as [Automatic]."
                    }
                    Write-ADTLogEntry -Message "Setting service [$($service.ServiceName)] with display name [$($service.DisplayName)] startup mode to [$StartMode]."
                    if (!$PSCmdlet.ShouldProcess($service.ServiceName, "Set service startup mode to [$StartMode]"))
                    {
                        continue
                    }
                    foreach ($action in $actions)
                    {
                        $null = [PSADT.ServiceManagement.SystemdService]::Systemctl([System.String[]]@($action, $service.Unit))
                    }
                    $service.Refresh()
                    Write-ADTLogEntry -Message "Successfully set service [$($service.ServiceName)] with display name [$($service.DisplayName)] startup mode to [$StartMode]."
                    if ($PassThru)
                    {
                        $PSCmdlet.WriteObject($service)
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
