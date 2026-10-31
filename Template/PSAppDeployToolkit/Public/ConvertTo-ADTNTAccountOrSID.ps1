#-----------------------------------------------------------------------------
#
# MARK: ConvertTo-ADTNTAccountOrSID
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: not supported on Linux (throws PlatformNotSupportedException).
#
#-----------------------------------------------------------------------------
function ConvertTo-ADTNTAccountOrSID
{
    <#

    .SYNOPSIS
        Convert between NT Account names and their security identifiers (SIDs).

    .DESCRIPTION
        Specify either the NT Account name or the SID and get the other. Can also convert well known sid types.

    .PARAMETER AccountName
        The Windows NT Account name specified in <domain>\<username> format.

        Use fully qualified account names (e.g., <domain>\<username>) instead of isolated names (e.g, <username>) because they are unambiguous and provide better performance.

    .PARAMETER SID
        The Windows NT Account SID.

    .PARAMETER WellKnownSIDName
        Specify the Well Known SID name to translate to the actual SID (e.g., LocalServiceSid).

        To get all well known SIDs available on system: `[Enum]::GetNames([Security.Principal.WellKnownSidType])`

    .PARAMETER WellKnownToNTAccount
        Convert the Well Known SID to an NTAccount name.

    .PARAMETER LocalHost
        Avoids a costly domain check when only converting local accounts.

    .PARAMETER LdapUri
        Allows specification of the LDAP URI to use, either `LDAP://` or `LDAPS://`.

    .INPUTS
        System.String

        Accepts a string containing the NT Account name or SID.

    .OUTPUTS
        System.Security.Principal.NTAccount

        When the input is a SID or a Well Known SID name and the `-WellKnownToNTAccount` parameter is specified, this function returns an NTAccount object representing the account name of the SID specified.

    .OUTPUTS
        System.Security.Principal.SecurityIdentifier

        When the input is an NTAccount or a Well Known SID name and the `-WellKnownToNTAccount` parameter is not specified, this function returns a SecurityIdentifier object representing the SID of the specified account.

    .EXAMPLE
        ConvertTo-ADTNTAccountOrSID -AccountName 'CONTOSO\User1'

        Converts a Windows NT Account name to the corresponding SID.

    .EXAMPLE
        ConvertTo-ADTNTAccountOrSID -SID 'S-1-5-21-1220945662-2111687655-725345543-14012660'

        Converts a Windows NT Account SID to the corresponding NT Account Name.

    .EXAMPLE
        ConvertTo-ADTNTAccountOrSID -WellKnownSIDName 'NetworkServiceSid'

        Converts a Well Known SID name to a SID.

    .NOTES
        An active ADT session is NOT required to use this function.

        The conversion can return an empty result if the user account does not exist anymore or if translation fails Refer to: https://learn.microsoft.com/en-us/archive/blogs/askds/troubleshooting-sid-translation-failures-from-the-obvious-to-the-not-so-obvious

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/ConvertTo-ADTNTAccountOrSID

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/ConvertTo-ADTNTAccountOrSID.ps1

    .LINK
        https://learn.microsoft.com/en-us/dotnet/api/system.security.principal.wellknownsidtype

    #>

    [CmdletBinding()]
    [OutputType([PSADT.AccountManagement.UnixIdentity])]
    [OutputType([PSADT.AccountManagement.UnixIdentity])]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'NTAccountToSID', ValueFromPipelineByPropertyName = $true)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [PSADT.AccountManagement.UnixIdentity]$AccountName,

        [Parameter(Mandatory = $true, ParameterSetName = 'SIDToNTAccount', ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [PSADT.AccountManagement.UnixIdentity]$SID,

        [Parameter(Mandatory = $true, ParameterSetName = 'WellKnownName', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'WellKnownNameLocalHost', ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Security.Principal.WellKnownSidType]$WellKnownSIDName,

        [Parameter(Mandatory = $false, ParameterSetName = 'WellKnownName')]
        [Parameter(Mandatory = $false, ParameterSetName = 'WellKnownNameLocalHost')]
        [System.Management.Automation.SwitchParameter]$WellKnownToNTAccount,

        [Parameter(Mandatory = $true, ParameterSetName = 'WellKnownNameLocalHost')]
        [System.Management.Automation.SwitchParameter]$LocalHost,

        [Parameter(Mandatory = $false, ParameterSetName = 'WellKnownName')]
        [ValidateSet('LDAP://', 'LDAPS://')]
        [System.String]$LdapUri = 'LDAP://'
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
