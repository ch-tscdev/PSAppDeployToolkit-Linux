
    # On Linux, "admin" means the effective user id is 0 (root, e.g. via sudo).
    return [PSADT.AccountManagement.AccountUtilities]::CallerIsAdmin
