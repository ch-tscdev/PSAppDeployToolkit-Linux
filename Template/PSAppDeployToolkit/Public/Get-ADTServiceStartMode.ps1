#-----------------------------------------------------------------------------
#
# MARK: Get-ADTServiceStartMode
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: Linux implementation.
#
#-----------------------------------------------------------------------------
function Get-ADTServiceStartMode
{
    <#
    .SYNOPSIS
        Retrieves the startup mode of a specified service.

    .DESCRIPTION
        The `Get-ADTServiceStartMode` function retrieves the startup mode of a specified service. This function checks the service's start type and adjusts the result if the service is set to 'Automatic (Delayed Start)'.

    .PARAMETER Name
        Specifies the service name of the service to retrieve the start mode for.

    .PARAMETER DisplayName
        Specifies the display name of the service to retrieve the start mode for.

    .PARAMETER InputObject
        Specify the `ServiceController` object to retrieve the start mode for.

    .INPUTS
        System.ServiceProcess.ServiceController

        You can pipe `ServiceController` objects to this function.

    .OUTPUTS
        System.String

        Returns the startup mode of the specified service.

    .EXAMPLE
        Get-ADTServiceStartMode -Name 'wuauserv'

        Retrieves the startup mode of the 'wuauserv' service.

    .EXAMPLE
        Get-ADTServiceStartMode -DisplayName 'Windows Update'

        Retrieves the startup mode of the Windows Update service.

    .EXAMPLE
        Get-ADTServiceStartMode -InputObject (Get-Service -Name 'wuauserv')

        Retrieves the startup mode of the 'wuauserv' service.

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

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Get-ADTServiceStartMode

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Get-ADTServiceStartMode.ps1
    #>

    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Name', Justification = "This parameter is accessed programmatically via the ParameterSet it's within, which PSScriptAnalyzer doesn't understand.")]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'DisplayName', Justification = "This parameter is accessed programmatically via the ParameterSet it's within, which PSScriptAnalyzer doesn't understand.")]
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'Name')]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$Name,

        [Parameter(Mandatory = $true, ParameterSetName = 'DisplayName')]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$DisplayName,

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
        [PSADT.ServiceManagement.SystemdService]$InputObject
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
                $service = Get-ADTSystemdServices -ParameterSetName $PSCmdlet.ParameterSetName -BoundParameters $(if ($PSCmdlet.ParameterSetName -eq 'InputObject') { @{ InputObject = @($InputObject) } } elseif ($PSCmdlet.ParameterSetName -eq 'DisplayName') { @{ DisplayName = @($DisplayName) } } else { @{ Name = @($Name) } }) | Select-Object -First 1
                Write-ADTLogEntry -Message "Getting the service [$($service.ServiceName)] startup mode."
                # enabled -> Automatic, disabled -> Manual (can still be started), masked -> Disabled.
                $serviceStartMode = $service.StartType.ToString()
                Write-ADTLogEntry -Message "Service [$($service.ServiceName)] startup mode is set to [$serviceStartMode] (systemd: $($service.UnitFileState))."
                return $serviceStartMode
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
