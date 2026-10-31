#-----------------------------------------------------------------------------
#
# MARK: Test-ADTServiceExists
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: Linux implementation.
#
#-----------------------------------------------------------------------------
function Test-ADTServiceExists
{
    <#
    .SYNOPSIS
        Check to see if a service exists.

    .DESCRIPTION
        The `Test-ADTServiceExists` function checks to see if a service exists.

    .PARAMETER Name
        Specify the name of the service. When `-UseCIM` is not specified, this parameter supports wildcards.

        Note: Service name can be found by executing `Get-Service | Format-Table -AutoSize -Wrap` or by using the properties screen of a service in services.msc.

    .PARAMETER DisplayName
        Specifies the display name of the service to test the existence of. This parameter supports wildcards. This parameter is not compatible with `-UseCIM`.

    .PARAMETER UseCIM
        Use CIM/WMI to check for the service. This parameter is deprecated and will be removed in PSAppDeployToolkit 4.3.0.

    .PARAMETER PassThru
        Returns the service object, if one exists. By default, the service object returned is a `ServiceController`. When the `-UseCIM` parameter is provided, a Win32_Service or Win32_BaseService `CimInstance` is returned.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        System.Boolean

        By default, this function returns `$true` if the service exists, otherwise returns `$false`.

    .OUTPUTS
        System.ServiceProcess.ServiceController

        When the `-PassThru` parameter is provided and the service specified exists, a `ServiceController` object representing the service is returned, otherwise `$null`.

    .OUTPUTS
        Microsoft.Management.Infrastructure.CimInstance

        When the `-PassThru` and `-UseCIM` parameters are provided and the service specified exists, a Win32_Service or Win32_BaseService `CimInstance` object representing the service is returned, otherwise `$null`.

    .EXAMPLE
        Test-ADTServiceExists -Name 'wuauserv'

        Checks if the service 'wuauserv' exists.

    .EXAMPLE
        Test-ADTServiceExists -DisplayName 'Windows Update'

        Checks if the Windows Update service exists.

    .EXAMPLE
        Test-ADTServiceExists -Name testservice -UseCIM -PassThru | Invoke-CimMethod -MethodName Delete

        Checks if a service exists and then deletes it by using the `-PassThru` parameter.

    .EXAMPLE
        ```PowerShell
        if ((($service = Test-ADTServiceExists -Name 'ScreenConnect*' -PassThru) | Get-ADTServiceStartMode) -ne 'Automatic')
        {
            Set-ADTServiceStartMode -InputObject $service -StartMode 'Automatic'
        }
        ```

        Sets the ScreenConnect service start mode to automatic, if it exists and its start mode is not automatic.

    .NOTES
        An active ADT session is NOT required to use this function.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Test-ADTServiceExists

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Test-ADTServiceExists.ps1
    #>

    [CmdletBinding()]
    [OutputType([System.Boolean])]
    [OutputType([PSADT.ServiceManagement.SystemdService])]
    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'Name')]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [PSAppDeployToolkit.Attributes.ValidateUnique()]
        [SupportsWildcards()]
        [System.String]$Name,

        [Parameter(Mandatory = $true, ParameterSetName = 'DisplayName')]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [PSAppDeployToolkit.Attributes.ValidateUnique()]
        [SupportsWildcards()]
        [System.String]$DisplayName,

        [Parameter(Mandatory = $false, ParameterSetName = 'Name')]
        [System.Obsolete('This parameter will be removed in PSAppDeployToolkit 4.3.0.')]
        [Alias('UseWMI')]
        [System.Management.Automation.SwitchParameter]$UseCIM,

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
                if ($UseCIM)
                {
                    Write-ADTLogEntry -Message 'The parameter [-UseCIM] has no effect on Linux; systemd is queried directly.'
                }
                $service = if ($PSCmdlet.ParameterSetName -eq 'DisplayName')
                {
                    Get-ADTSystemdServices -ParameterSetName DisplayName -BoundParameters @{ DisplayName = @($DisplayName) } | Select-Object -First 1
                }
                else
                {
                    [PSADT.ServiceManagement.SystemdService]::new($Name)
                }
                $label = if ($PSCmdlet.ParameterSetName -eq 'DisplayName') { "display name [$DisplayName]" } else { "name [$Name]" }
                if (!$service -or !$service.Exists)
                {
                    Write-ADTLogEntry -Message "Service with $label does not exist."
                    return $false
                }
                Write-ADTLogEntry -Message "Service with $label exists."
                if ($PassThru)
                {
                    return $service
                }
                return $true
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
