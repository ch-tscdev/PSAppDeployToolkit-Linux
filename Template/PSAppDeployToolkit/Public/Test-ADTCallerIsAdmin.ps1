#-----------------------------------------------------------------------------
#
# MARK: Test-ADTCallerIsAdmin
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: Linux implementation.
#
#-----------------------------------------------------------------------------
function Test-ADTCallerIsAdmin
{
    <#
    .SYNOPSIS
        Checks if the current user has administrative privileges.

    .DESCRIPTION
        The `Test-ADTCallerIsAdmin` function checks if the current user is a member of the Administrators group. It returns a boolean value indicating whether the user has administrative privileges.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        System.Boolean

        Returns `$true` if the current user is an administrator, otherwise `$false`.

    .EXAMPLE
        Test-ADTCallerIsAdmin

        Checks if the current user has administrative privileges and returns `$true` or `$false`.

    .NOTES
        An active ADT session is NOT required to use this function.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Test-ADTCallerIsAdmin

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Test-ADTCallerIsAdmin.ps1
    #>

    # On Linux, "admin" means the effective user id is 0 (root, e.g. via sudo).
    return [PSADT.AccountManagement.AccountUtilities]::CallerIsAdmin
}
