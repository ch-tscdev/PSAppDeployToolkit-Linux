#-----------------------------------------------------------------------------
#
# MARK: Start-ADTProcess
#
# Linux port of PSAppDeployToolkit. The help, attributes and parameter block
# are taken verbatim from the original module; implementation: Linux implementation.
#
#-----------------------------------------------------------------------------
function Start-ADTProcess
{
    <#
    .SYNOPSIS
        Execute a process with optional arguments, working directory, window style.

    .DESCRIPTION
        The `Start-ADTProcess` function executes a process, e.g. a file included in the Files directory of the App Deploy Toolkit, or a file on the local machine. Provides various options for handling the return codes (see Parameters).

    .PARAMETER FilePath
        Path to the file to be executed. If the file is located directly in the "Files" directory of the App Deploy Toolkit, only the file name needs to be specified.

        Otherwise, the full path of the file must be specified. If the file is in a subdirectory of "Files", use the `$($adtSession.DirFiles)` variable, as shown in the example.

    .PARAMETER ArgumentList
        Arguments to be passed to the executable.

        Passing an array says where each argument ends, so one element always reaches the executable as one argument however it is punctuated. What it does not do is sanitise: an element is quoted where it has to be and otherwise left in the form an installer expects, so interpolating a value you did not author into one leaves that value able to say anything an argument can say.

    .PARAMETER SecureArgumentList
        Hides all arguments passed to the executable from the Toolkit log file.

    .PARAMETER WorkingDirectory
        The working directory used for executing the process. Defaults to DirFiles if there is an active DeploymentSession. The use of `-UseShellExecute` affects this parameter.

    .PARAMETER RunAsActiveUser
        A RunAsActiveUser object to invoke the process as.

    .PARAMETER UseLinkedAdminToken
        Use a user's linked administrative token while running the process under their context.

    .PARAMETER UseHighestAvailableToken
        Use a user's linked administrative token if it's available while running the process under their context.

    .PARAMETER DenyUserTermination
        Specifies that users cannot terminate the process started in their context.

        Note: This will not prevent the user from terminating the process if they are a member of the built-in Administrators group.

    .PARAMETER InheritEnvironmentVariables
        Specifies whether the process running as a user should inherit the SYSTEM account's environment variables.

    .PARAMETER UseUnelevatedToken
        If the current process is elevated, starts the new process unelevated using the user's unelevated linked token.

    .PARAMETER ExpandEnvironmentVariables
        Specifies whether to expand any Windows/DOS-style environment variables in the specified `-FilePath` and `-ArgumentList` parameters.

    .PARAMETER UseShellExecute
        Specifies whether to use the operating system shell to start the process. `$true` if the shell should be used when starting the process; `$false` if the process should be created directly from the executable file.

        The word "Shell" in this context refers to a graphical shell (similar to the Windows shell) rather than command shells (for example, bash or sh) and lets users launch graphical applications or open documents. It lets you open a file or a URL and the Shell will figure out the program to open it with.

        The WorkingDirectory property behaves differently depending on the value of the `-UseShellExecute` parameter. When `-UseShellExecute` is `$true`, the `-WorkingDirectory` parameter specifies the location of the executable. When `-UseShellExecute` is `$false`, the `-WorkingDirectory` parameter is not used to find the executable. Instead, it is used only by the process that is started and has meaning only within the context of the new process.

        If you set `-UseShellExecute` to `$true`, there will be no available output from the process.

    .PARAMETER Verb
        The verb to use when doing a ShellExecute invocation. Common usages are "runas" to trigger a UAC elevation of the process.

    .PARAMETER WindowStyle
        Style of the window of the process executed. Options: Normal, Hidden, Maximized, Minimized. Only works for native Windows GUI applications. If the WindowStyle is set to Hidden, `-UseShellExecute` should be set to `$true`.

        Note: Not all processes honor WindowStyle. WindowStyle is a recommendation passed to the process. They can choose to ignore it.

    .PARAMETER CreateNoWindow
        Specifies whether the process should be started with a new window to contain it.

    .PARAMETER StreamEncoding
        Specifies the encoding type to use when reading stdin/stdout/stderr. Some apps like WinGet encode using UTF8, which will corrupt if incorrectly set.

    .PARAMETER StandardInput
        Specifies a string to write to the process's stdin stream. This is handy for answering known prompts, etc.

    .PARAMETER NoStreamLogging
        Don't log any available stdout/stderr data to the log file.

    .PARAMETER WaitForMsiExec
        Sometimes an EXE bootstrapper will launch an MSI install. In such cases, this variable will ensure that this function waits for the msiexec engine to become available before starting the install.

    .PARAMETER MsiExecWaitTime
        Specify the length of time to wait for the msiexec engine to become available. Accepts TimeSpan objects, but also interprets numerical values as seconds.

    .PARAMETER WaitForChildProcesses
        Specifies whether the started process should be considered finished only when any child processes it spawns have finished also.

    .PARAMETER KillChildProcessesWithParent
        Specifies whether any child processes started by the provided executable should be closed when the provided executable closes. This is handy for application installs that open web browsers and other programs that cannot be suppressed.

    .PARAMETER Timeout
        How long to wait for the process before timing out. Accepts TimeSpan objects, but also interprets numerical values as seconds.

    .PARAMETER TimeoutAction
        What action to take on timeout. Follows ErrorAction if not specified.

    .PARAMETER NoTerminateOnTimeout
        Indicates that the process should not be terminated on timeout. Only supported for GUI-based applications.

    .PARAMETER SuccessExitCodes
        List of exit codes to be considered successful. Defaults to values set during ADTSession initialization, otherwise: 0

    .PARAMETER RebootExitCodes
        List of exit codes to indicate a reboot is required. Defaults to values set during ADTSession initialization, otherwise: 1641, 3010

    .PARAMETER IgnoreExitCodes
        List the exit codes to ignore or `*` to ignore all exit codes. Where possible, please use `-SuccessExitCodes` and/or `-RebootExitCodes` instead, or `-ErrorAction SilentlyContinue` as this parameter is deprecated and will be removed in PSAppDeployToolkit 4.3.0.

    .PARAMETER PriorityClass
        Specifies priority class for the process. Options: `Idle`, `Normal`, `High`, `AboveNormal`, `BelowNormal`, `RealTime`.

    .PARAMETER ExitOnProcessFailure
        Automatically closes the active deployment session via `Close-ADTSession` in the event the process exits with a non-success or non-ignored exit code.

    .PARAMETER NoWait
        Immediately continue after executing the process.

    .PARAMETER PassThru
        If `-NoWait` is not specified, returns an object with ExitCode, StdOut, and StdErr output from the process. If `-NoWait` is specified, returns a task that can be awaited. Note that a failed execution will only return an object if either `-ErrorAction` is set to `SilentlyContinue`/`Ignore`, or if `-SuccessExitCodes` is used.

    .EXAMPLE
        Start-ADTProcess -FilePath 'setup.exe' -ArgumentList '/S' -SuccessExitCodes 1,2

        Launch InstallShield "setup.exe" from the ".\Files" sub-directory.

    .EXAMPLE
        Start-ADTProcess -FilePath "$($adtSession.DirFiles)\Bin\setup.exe" -ArgumentList '/S' -WindowStyle 'Hidden'

        Launch InstallShield "setup.exe" from the ".\Files\Bin" sub-directory.

    .EXAMPLE
        Start-ADTProcess -FilePath 'uninstall_flash_player_64bit.exe' -ArgumentList '/uninstall' -WindowStyle 'Hidden'

        If the file is in the "Files" directory of the AppDeployToolkit, only the file name needs to be specified.

    .EXAMPLE
        Start-ADTProcess -FilePath 'setup.exe' -ArgumentList "-s -f2`"$((Get-ADTConfig).Toolkit.LogPath)\$($adtSession.InstallName).log`""

        Launch InstallShield "setup.exe" from the ".\Files" sub-directory and force log files to the logging folder.

    .EXAMPLE
        Start-ADTProcess -FilePath 'setup.exe' -ArgumentList "/s /v`"ALLUSERS=1 /qn /L* `"$((Get-ADTConfig).Toolkit.LogPath)\$($adtSession.InstallName).log`"`""

        Launch InstallShield "setup.exe" with embedded MSI and force log files to the logging folder.

    .EXAMPLE
        Start-ADTProcess -FilePath 'setup.exe' -ArgumentList "/s /v`"ALLUSERS=1 /qn /L* `"$((Get-ADTConfig).Toolkit.LogPath)\$($adtSession.InstallName).log`"`"" -Timeout 00:10:00

        Launch InstallShield "setup.exe" with embedded MSI and force log files to the logging folder, terminating the process if it takes longer than 10 minutes to complete.

    .EXAMPLE
        Start-ADTProcess -FilePath 'setup.exe' -ArgumentList "/s /v`"ALLUSERS=1 /qn /L* `"$((Get-ADTConfig).Toolkit.LogPath)\$($adtSession.InstallName).log`"`"" -Timeout (New-TimeSpan -Minutes 10)

        Launch InstallShield "setup.exe" with embedded MSI and force log files to the logging folder, terminating the process if it takes longer than 10 minutes to complete.

    .EXAMPLE
        $result = Start-ADTProcess -FilePath "setup.exe" -ArgumentList "-i -f `"$($adtSession.DirFiles)\licenseFile.lic`"" -CreateNoWindow -ErrorAction SilentlyContinue -PassThru

        Launch "setup.exe" with -PassThru so we can capture the exit code and stdout/stderr from the executable if it's a console application.

    .EXAMPLE
        $result = Start-ADTProcess -FilePath cmd.exe -ArgumentList '/c', 'echo Testing stdout capture. & exit 0' -CreateNoWindow -PassThru

        Launch cmd.exe to echo out a message to stdout, specifically taking advantage of our `-ArgumentList` array support to avoid escaped quote issues.

    .INPUTS
        None

        You cannot pipe objects to this function.

    .OUTPUTS
        None

        By default, this function returns no output.

    .OUTPUTS
        PSADT.ProcessManagement.ProcessResult

        Returns an object with the results of the installation if `-PassThru` is specified.
        - Process
        - LaunchInfo
        - CommandLine
        - ExitCode
        - StdOut
        - StdErr
        - Interleaved

    .OUTPUTS
        PSADT.ProcessManagement.ProcessHandle

        Returns an object with the handle of the installation process if `-PassThru` and `-NoWait` are specified.
        - Process
        - LaunchInfo
        - CommandLine
        - Task

    .NOTES
        An active ADT session is NOT required to use this function.

        This function supports the `-WhatIf` and `-Confirm` parameters for testing changes before applying them.

        Tags: psadt<br />
        Website: https://psappdeploytoolkit.com<br />
        Copyright: (C) 2026 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).<br />
        License: https://opensource.org/license/lgpl-3-0

    .LINK
        https://psappdeploytoolkit.com/docs/reference/functions/Start-ADTProcess

    .LINK
        https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/main/modules/PSAppDeployToolkit/Public/Start-ADTProcess.ps1
    #>

    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Default_CreateWindow_Wait')]
    [OutputType([PSADT.ProcessManagement.ProcessResult])]
    [OutputType([PSADT.ProcessManagement.ProcessHandle])]
    param
    (
        [Parameter(Mandatory = $true)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$FilePath,

        [Parameter(Mandatory = $false)]
        [PSAppDeployToolkit.Attributes.AllowEmptyButNotNullOrWhiteSpace()]
        [System.String[]]$ArgumentList,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$SecureArgumentList,

        [Parameter(Mandatory = $false)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$WorkingDirectory,

        # Identity: RunAsActiveUser (only present in sets where identity is "RunAsActiveUser")
        [Parameter(Mandatory = $true, ParameterSetName = 'RunAsActiveUser_CreateWindow_Wait')]
        [Parameter(Mandatory = $true, ParameterSetName = 'RunAsActiveUser_CreateWindow_NoWait')]
        [Parameter(Mandatory = $true, ParameterSetName = 'RunAsActiveUser_CreateWindow_Timeout')]
        [Parameter(Mandatory = $true, ParameterSetName = 'RunAsActiveUser_WindowStyle_Wait')]
        [Parameter(Mandatory = $true, ParameterSetName = 'RunAsActiveUser_WindowStyle_NoWait')]
        [Parameter(Mandatory = $true, ParameterSetName = 'RunAsActiveUser_WindowStyle_Timeout')]
        [Parameter(Mandatory = $true, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_Wait')]
        [Parameter(Mandatory = $true, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_NoWait')]
        [Parameter(Mandatory = $true, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_Timeout')]
        [ValidateNotNullOrEmpty()]
        [PSADT.Foundation.RunAsActiveUser]$RunAsActiveUser,

        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateWindow_NoWait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_WindowStyle_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_WindowStyle_NoWait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_WindowStyle_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_NoWait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_Timeout')]
        [System.Management.Automation.SwitchParameter]$UseLinkedAdminToken,

        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateWindow_NoWait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_WindowStyle_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_WindowStyle_NoWait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_WindowStyle_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_NoWait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_Timeout')]
        [System.Management.Automation.SwitchParameter]$UseHighestAvailableToken,

        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateWindow_NoWait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_WindowStyle_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_WindowStyle_NoWait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_WindowStyle_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_NoWait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_Timeout')]
        [System.Management.Automation.SwitchParameter]$DenyUserTermination,

        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateWindow_NoWait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_WindowStyle_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_WindowStyle_NoWait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_WindowStyle_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_NoWait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_Timeout')]
        [System.Management.Automation.SwitchParameter]$InheritEnvironmentVariables,

        [Parameter(Mandatory = $false, ParameterSetName = 'Default_CreateWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Default_CreateWindow_NoWait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Default_CreateWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Default_WindowStyle_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Default_WindowStyle_NoWait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Default_WindowStyle_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Default_CreateNoWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Default_CreateNoWindow_NoWait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Default_CreateNoWindow_Timeout')]
        [System.Management.Automation.SwitchParameter]$UseUnelevatedToken,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$ExpandEnvironmentVariables,

        # Identity: UseShellExecute (available in UseShellExecute and RunAsActiveUser sets)
        [Parameter(Mandatory = $true, ParameterSetName = 'UseShellExecute_CreateWindow_Wait')]
        [Parameter(Mandatory = $true, ParameterSetName = 'UseShellExecute_CreateWindow_NoWait')]
        [Parameter(Mandatory = $true, ParameterSetName = 'UseShellExecute_CreateWindow_Timeout')]
        [Parameter(Mandatory = $true, ParameterSetName = 'UseShellExecute_WindowStyle_Wait')]
        [Parameter(Mandatory = $true, ParameterSetName = 'UseShellExecute_WindowStyle_NoWait')]
        [Parameter(Mandatory = $true, ParameterSetName = 'UseShellExecute_WindowStyle_Timeout')]
        [Parameter(Mandatory = $true, ParameterSetName = 'UseShellExecute_CreateNoWindow_Wait')]
        [Parameter(Mandatory = $true, ParameterSetName = 'UseShellExecute_CreateNoWindow_NoWait')]
        [Parameter(Mandatory = $true, ParameterSetName = 'UseShellExecute_CreateNoWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateWindow_NoWait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_WindowStyle_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_WindowStyle_NoWait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_WindowStyle_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_NoWait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_Timeout')]
        [System.Management.Automation.SwitchParameter]$UseShellExecute,

        [Parameter(Mandatory = $false, ParameterSetName = 'UseShellExecute_CreateWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseShellExecute_CreateWindow_NoWait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseShellExecute_CreateWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseShellExecute_WindowStyle_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseShellExecute_WindowStyle_NoWait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseShellExecute_WindowStyle_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseShellExecute_CreateNoWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseShellExecute_CreateNoWindow_NoWait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseShellExecute_CreateNoWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateWindow_NoWait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_WindowStyle_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_WindowStyle_NoWait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_WindowStyle_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_NoWait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_Timeout')]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String]$Verb,

        # Window Option: WindowStyle (only in sets where window is "WindowStyle")
        [Parameter(Mandatory = $true, ParameterSetName = 'Default_WindowStyle_Wait')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Default_WindowStyle_NoWait')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Default_WindowStyle_Timeout')]
        [Parameter(Mandatory = $true, ParameterSetName = 'RunAsActiveUser_WindowStyle_Wait')]
        [Parameter(Mandatory = $true, ParameterSetName = 'RunAsActiveUser_WindowStyle_NoWait')]
        [Parameter(Mandatory = $true, ParameterSetName = 'RunAsActiveUser_WindowStyle_Timeout')]
        [Parameter(Mandatory = $true, ParameterSetName = 'UseShellExecute_WindowStyle_Wait')]
        [Parameter(Mandatory = $true, ParameterSetName = 'UseShellExecute_WindowStyle_NoWait')]
        [Parameter(Mandatory = $true, ParameterSetName = 'UseShellExecute_WindowStyle_Timeout')]
        [ValidateNotNullOrEmpty()]
        [System.Diagnostics.ProcessWindowStyle]$WindowStyle,

        # Window Option: CreateNoWindow (only in sets where window is "CreateNoWindow")
        [Parameter(Mandatory = $true, ParameterSetName = 'Default_CreateNoWindow_Wait')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Default_CreateNoWindow_NoWait')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Default_CreateNoWindow_Timeout')]
        [Parameter(Mandatory = $true, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_Wait')]
        [Parameter(Mandatory = $true, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_NoWait')]
        [Parameter(Mandatory = $true, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_Timeout')]
        [Parameter(Mandatory = $true, ParameterSetName = 'UseShellExecute_CreateNoWindow_Wait')]
        [Parameter(Mandatory = $true, ParameterSetName = 'UseShellExecute_CreateNoWindow_NoWait')]
        [Parameter(Mandatory = $true, ParameterSetName = 'UseShellExecute_CreateNoWindow_Timeout')]
        [System.Management.Automation.SwitchParameter]$CreateNoWindow,

        [Parameter(Mandatory = $false, ParameterSetName = 'Default_CreateNoWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Default_CreateNoWindow_NoWait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Default_CreateNoWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_NoWait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_Timeout')]
        [ValidateNotNullOrEmpty()]
        [System.Text.Encoding]$StreamEncoding,

        [Parameter(Mandatory = $false, ParameterSetName = 'Default_CreateNoWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Default_CreateNoWindow_NoWait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Default_CreateNoWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_NoWait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_Timeout')]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.String[]]$StandardInput,

        [Parameter(Mandatory = $false, ParameterSetName = 'Default_CreateNoWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Default_CreateNoWindow_NoWait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Default_CreateNoWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_NoWait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_Timeout')]
        [System.Management.Automation.SwitchParameter]$NoStreamLogging,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$WaitForMsiExec,

        [Parameter(Mandatory = $false)]
        [PSAppDeployToolkit.Attributes.TimeSpanTransformation()]
        [PSAppDeployToolkit.Attributes.ValidateGreaterThanZero()]
        [System.TimeSpan]$MsiExecWaitTime = [System.TimeSpan]::FromSeconds($(if (!(Test-ADTModuleInitialized)) { Get-ADTDefaultConfig } else { Get-ADTConfig }).MSI.MutexWaitTime),

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.SwitchParameter]$WaitForChildProcesses,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.SwitchParameter]$KillChildProcessesWithParent,

        # Wait Option: Timeout (only in sets where wait is "Timeout")
        [Parameter(Mandatory = $true, ParameterSetName = 'Default_CreateWindow_Timeout')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Default_WindowStyle_Timeout')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Default_CreateNoWindow_Timeout')]
        [Parameter(Mandatory = $true, ParameterSetName = 'RunAsActiveUser_CreateWindow_Timeout')]
        [Parameter(Mandatory = $true, ParameterSetName = 'RunAsActiveUser_WindowStyle_Timeout')]
        [Parameter(Mandatory = $true, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_Timeout')]
        [Parameter(Mandatory = $true, ParameterSetName = 'UseShellExecute_CreateWindow_Timeout')]
        [Parameter(Mandatory = $true, ParameterSetName = 'UseShellExecute_WindowStyle_Timeout')]
        [Parameter(Mandatory = $true, ParameterSetName = 'UseShellExecute_CreateNoWindow_Timeout')]
        [PSAppDeployToolkit.Attributes.TimeSpanTransformation()]
        [PSAppDeployToolkit.Attributes.ValidateGreaterThanZero()]
        [System.TimeSpan]$Timeout,

        [Parameter(Mandatory = $false, ParameterSetName = 'Default_CreateWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Default_WindowStyle_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Default_CreateNoWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_WindowStyle_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseShellExecute_CreateWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseShellExecute_WindowStyle_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseShellExecute_CreateNoWindow_Timeout')]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.ActionPreference]$TimeoutAction,

        [Parameter(Mandatory = $false, ParameterSetName = 'Default_CreateWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Default_WindowStyle_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Default_CreateNoWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_WindowStyle_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseShellExecute_CreateWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseShellExecute_WindowStyle_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseShellExecute_CreateNoWindow_Timeout')]
        [System.Management.Automation.SwitchParameter]$NoTerminateOnTimeout,

        [Parameter(Mandatory = $false, ParameterSetName = 'Default_CreateNoWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Default_CreateNoWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Default_CreateWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Default_CreateWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Default_WindowStyle_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Default_WindowStyle_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_WindowStyle_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_WindowStyle_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseShellExecute_CreateNoWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseShellExecute_CreateNoWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseShellExecute_CreateWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseShellExecute_CreateWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseShellExecute_WindowStyle_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseShellExecute_WindowStyle_Wait')]
        [ValidateNotNullOrEmpty()]
        [System.Int32[]]$SuccessExitCodes,

        [Parameter(Mandatory = $false, ParameterSetName = 'Default_CreateNoWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Default_CreateNoWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Default_CreateWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Default_CreateWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Default_WindowStyle_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Default_WindowStyle_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_WindowStyle_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_WindowStyle_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseShellExecute_CreateNoWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseShellExecute_CreateNoWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseShellExecute_CreateWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseShellExecute_CreateWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseShellExecute_WindowStyle_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseShellExecute_WindowStyle_Wait')]
        [ValidateNotNullOrEmpty()]
        [System.Int32[]]$RebootExitCodes,

        [Parameter(Mandatory = $false, ParameterSetName = 'Default_CreateNoWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Default_CreateNoWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Default_CreateWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Default_CreateWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Default_WindowStyle_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Default_WindowStyle_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_WindowStyle_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_WindowStyle_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseShellExecute_CreateNoWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseShellExecute_CreateNoWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseShellExecute_CreateWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseShellExecute_CreateWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseShellExecute_WindowStyle_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseShellExecute_WindowStyle_Wait')]
        [System.Obsolete("Please use '-ErrorAction SilentlyContinue' instead as this will be removed in PSAppDeployToolkit 4.3.0.")]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [SupportsWildcards()]
        [System.String[]]$IgnoreExitCodes,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.Diagnostics.ProcessPriorityClass]$PriorityClass,

        [Parameter(Mandatory = $false, ParameterSetName = 'Default_CreateNoWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Default_CreateNoWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Default_CreateWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Default_CreateWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Default_WindowStyle_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Default_WindowStyle_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_CreateWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_WindowStyle_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'RunAsActiveUser_WindowStyle_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseShellExecute_CreateNoWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseShellExecute_CreateNoWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseShellExecute_CreateWindow_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseShellExecute_CreateWindow_Wait')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseShellExecute_WindowStyle_Timeout')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseShellExecute_WindowStyle_Wait')]
        [System.Management.Automation.SwitchParameter]$ExitOnProcessFailure,

        # Wait Option: NoWait (only in sets where wait is "NoWait")
        [Parameter(Mandatory = $true, ParameterSetName = 'Default_CreateWindow_NoWait')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Default_WindowStyle_NoWait')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Default_CreateNoWindow_NoWait')]
        [Parameter(Mandatory = $true, ParameterSetName = 'RunAsActiveUser_CreateWindow_NoWait')]
        [Parameter(Mandatory = $true, ParameterSetName = 'RunAsActiveUser_WindowStyle_NoWait')]
        [Parameter(Mandatory = $true, ParameterSetName = 'RunAsActiveUser_CreateNoWindow_NoWait')]
        [Parameter(Mandatory = $true, ParameterSetName = 'UseShellExecute_CreateWindow_NoWait')]
        [Parameter(Mandatory = $true, ParameterSetName = 'UseShellExecute_WindowStyle_NoWait')]
        [Parameter(Mandatory = $true, ParameterSetName = 'UseShellExecute_CreateNoWindow_NoWait')]
        [System.Management.Automation.SwitchParameter]$NoWait,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$PassThru
    )

    begin
    {
        # Internal worker function to set the session exit code.
        function Set-ADTSessionExitCode
        {
            [CmdletBinding()]
            param
            (
                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [System.Nullable[System.Int32]]$ExitCode
            )

            if (!$adtSession)
            {
                $naerParams = @{
                    Exception = [System.InvalidProgramException]::new("The function [Start-ADTProcess] attempted to set a session exit code, but no deployment session is active.")
                    Category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                    ErrorId = 'NoActiveAdtDeploymentSession'
                    TargetObject = $ExitCode
                }
                $PSCmdlet.ThrowTerminatingError((New-ADTErrorRecord @naerParams))
            }
            if (!$canSetExitCode)
            {
                return
            }
            $null = $adtSession.TrySetExitCode($ExitCode, $SuccessExitCodes, $RebootExitCodes)
        }

        # Initalize function and get required objects.
        $adtSession = if (Test-ADTSessionActive)
        {
            Get-ADTSession
        }
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $canSetExitCode = $true

        # Log the deprecation of -IgnoreExitCodes to the log.
        if ($PSBoundParameters.ContainsKey('IgnoreExitCodes'))
        {
            Write-ADTLogEntry -Message "The parameter [-IgnoreExitCodes] is obsolete and will be removed in PSAppDeployToolkit 4.3.0. Please use [-SuccessExitCodes]/[-RebootExitCodes] for known exit codes, or [-ErrorAction SilentlyContinue] for ignoring any exit code instead." -Severity Warning
        }

        # Set up defaults if not specified.
        if (!$PSBoundParameters.ContainsKey('SuccessExitCodes'))
        {
            $SuccessExitCodes = if ($adtSession) { $adtSession.AppSuccessExitCodes } else { 0 }
        }
        else
        {
            $canSetExitCode = $false
        }
        if (!$PSBoundParameters.ContainsKey('RebootExitCodes'))
        {
            $RebootExitCodes = if ($adtSession) { $adtSession.AppRebootExitCodes } else { 1641, 3010 }
        }
        else
        {
            $canSetExitCode = $false
        }

        # Determine whether the caller is external to the module (or one of our wrappers).
        $funcCaller = Get-PSCallStack | Select-Object -Skip 1 | Select-Object -First 1 | & { process { $_.InvocationInfo.MyCommand } }
        $extInvoker = !$funcCaller -or !$funcCaller.Source -or !$funcCaller.Source.StartsWith($MyInvocation.MyCommand.Module.Name) -or $funcCaller.Name.Equals('Start-ADTProcessAsUser') -or $funcCaller.Name.Equals('Uninstall-ADTApplication')

        # Set up the timeout.
        $cancellationTokenSource = if ($PSBoundParameters.ContainsKey('Timeout') -and $Timeout)
        {
            [System.Threading.CancellationTokenSource]::new($Timeout)
        }
        $cancellationToken = if ($cancellationTokenSource) { $cancellationTokenSource.Token } else { [System.Threading.CancellationToken]::None }
    }

    process
    {
        Write-ADTLogEntry -Message "Preparing to execute process [$FilePath]$(if ($RunAsActiveUser) {" for user [$($RunAsActiveUser.NTAccount)]"})..."
        if ($PSBoundParameters.ContainsKey('IgnoreExitCodes') -and !$($IgnoreExitCodes).Equals('*'))
        {
            Write-ADTLogEntry -Message "Please use [-SuccessExitCodes] and/or [-RebootExitCodes] to specify your process's exit codes."
        }

        # Windows-only options have no meaning on Linux; tell the caller once rather than failing.
        foreach ($winOnly in 'UseLinkedAdminToken', 'UseHighestAvailableToken', 'DenyUserTermination', 'UseUnelevatedToken', 'WaitForMsiExec')
        {
            if ($PSBoundParameters.ContainsKey($winOnly) -and $PSBoundParameters.$winOnly)
            {
                Write-ADTLogEntry -Message "The parameter [-$winOnly] has no effect on Linux and will be ignored." -Severity Warning
            }
        }

        $result = $null
        try
        {
            try
            {
                # Resolve a non-fully qualified path (relative to Files/SupportFiles/working directory, then $PATH).
                $FilePath = $FilePath -replace '\\', '/'
                if ((!$FilePath.Contains('%') -or !$ExpandEnvironmentVariables) -and ![System.IO.Path]::IsPathFullyQualified($FilePath))
                {
                    $rafspParams = @{ LiteralPath = $FilePath; File = $true }
                    if ($PSBoundParameters.ContainsKey('WorkingDirectory'))
                    {
                        $rafspParams.Add('ExtraPaths', $WorkingDirectory)
                    }
                    if (($fqPath = Resolve-ADTFileSystemPath @rafspParams))
                    {
                        Write-ADTLogEntry -Message "File path [$FilePath] successfully resolved to fully qualified path [$fqPath]."
                        $FilePath = $fqPath
                    }
                }

                # Set the working directory if not specified, as the original does.
                $workingDir = $null
                if (!$PSBoundParameters.ContainsKey('WorkingDirectory'))
                {
                    $workingDir = if ($adtSession -and [System.IO.Path]::IsPathFullyQualified($FilePath) -and $FilePath.StartsWith('/') -and [System.IO.Path]::HasExtension($FilePath))
                    {
                        [System.IO.Path]::GetDirectoryName($FilePath)
                    }
                    elseif ($adtSession -and $adtSession.DirFiles)
                    {
                        $adtSession.DirFiles.FullName
                    }
                }
                else
                {
                    $workingDir = $WorkingDirectory -replace '\\', '/'
                }

                # Shell-executed processes have no stdout/stderr, everything else is captured (no windows on Linux).
                if ($UseShellExecute)
                {
                    Write-ADTLogEntry -Message 'UseShellExecute is set to true, StdOut/StdErr streams will not be available.'
                    if (!$FilePath.StartsWith('/') -and ($opener = Get-Command -Name xdg-open -CommandType Application -ErrorAction Ignore))
                    {
                        $ArgumentList = @($FilePath) + @($ArgumentList | & { process { if ($_) { $_ } } })
                        $FilePath = $opener.Source
                    }
                }
                if (![System.String]::IsNullOrWhiteSpace($workingDir))
                {
                    Write-ADTLogEntry -Message "Working Directory is [$workingDir]."
                }

                # Build the launch information.
                $launchInfo = [PSADT.ProcessManagement.LinuxLaunchInfo]::new()
                $launchInfo.FilePath = $FilePath
                $launchInfo.ArgumentList = [System.String[]]@($ArgumentList | & { process { if ($null -ne $_) { $_ } } })
                $launchInfo.WorkingDirectory = $workingDir
                $launchInfo.RunAsActiveUser = $RunAsActiveUser
                $launchInfo.InheritEnvironmentVariables = $InheritEnvironmentVariables
                $launchInfo.ExpandEnvironmentVariables = $ExpandEnvironmentVariables
                $launchInfo.StandardInput = $StandardInput
                $launchInfo.CaptureOutput = !$UseShellExecute
                $launchInfo.WaitForChildProcesses = $WaitForChildProcesses
                $launchInfo.KillChildProcessesWithParent = $KillChildProcessesWithParent
                $launchInfo.StreamEncoding = $StreamEncoding
                if ($PSBoundParameters.ContainsKey('PriorityClass')) { $launchInfo.PriorityClass = $PriorityClass }
                $launchInfo.CancellationToken = $cancellationToken
                $launchInfo.NoTerminateOnTimeout = $NoTerminateOnTimeout

                # Log the command line we're about to run.
                $userText = if ($RunAsActiveUser) { " for user [$($RunAsActiveUser.NTAccount)]" }
                $waitText = if ($NoWait) { ' without waiting' }
                if ($ArgumentList)
                {
                    if ($SecureArgumentList)
                    {
                        Write-ADTLogEntry -Message "Executing [`"$FilePath`" (Parameters Hidden)]$userText$waitText..."
                    }
                    else
                    {
                        Write-ADTLogEntry -Message "Executing [`"$FilePath`" $([PSADT.ProcessManagement.CommandLineUtilities]::ArgumentListToCommandLine([System.String[]]$launchInfo.ArgumentList))]$userText$waitText..."
                    }
                }
                else
                {
                    Write-ADTLogEntry -Message "Executing [`"$FilePath`"]$userText$waitText..."
                }
                if (!$PSCmdlet.ShouldProcess("Process [$FilePath]", 'Execute'))
                {
                    return
                }

                # Launch the process.
                $execution = [PSADT.ProcessManagement.ProcessManager]::LaunchAsync($launchInfo)
                if ($NoWait)
                {
                    if ($PassThru)
                    {
                        Write-ADTLogEntry -Message 'PassThru parameter specified, returning task for external tracking.'
                        return $execution
                    }
                    return
                }
                $result = $execution.GetResult()
                $commandLineText = if ($SecureArgumentList) { "`"$FilePath`" (Parameters Hidden)" } else { $execution.CommandLine }

                # Handle timeouts.
                if ($result.ExitCode -eq [PSADT.ProcessManagement.ProcessManager]::TimeoutExitCode -and $cancellationToken.IsCancellationRequested)
                {
                    $naerParams = if ($NoTerminateOnTimeout)
                    {
                        @{
                            Exception = [System.TimeoutException]::new("Timed out waiting for process execution to complete.")
                            Category = [System.Management.Automation.ErrorCategory]::LimitsExceeded
                            ErrorId = 'ProcessExecutionTimedOut'
                            TargetObject = $(if (!$SecureArgumentList) { $result })
                        }
                    }
                    else
                    {
                        @{
                            Exception = [System.OperationCanceledException]::new("Process terminated because execution took too long to complete.", $cancellationToken)
                            Category = [System.Management.Automation.ErrorCategory]::OperationStopped
                            ErrorId = 'ProcessExecutionCancelled'
                            TargetObject = $(if (!$SecureArgumentList) { $result })
                        }
                    }
                    throw (New-ADTErrorRecord @naerParams)
                }
                Write-ADTLogEntry -Message "Finished execution of [$commandLineText]."

                # Evaluate the exit code exactly like the original does.
                $waleParams = if (($ignoreExitCode = $IgnoreExitCodes -and ($($IgnoreExitCodes).Equals('*') -or ([System.Int32[]]$IgnoreExitCodes).Contains($result.ExitCode))))
                {
                    @{ Message = "Execution completed and the exit code [$($result.ExitCode)] is being ignored."; Severity = [PSAppDeployToolkit.Logging.LogSeverity]::Info }
                }
                elseif ($SuccessExitCodes -contains $result.ExitCode)
                {
                    @{ Message = "Execution completed successfully with exit code [$($result.ExitCode)]."; Severity = [PSAppDeployToolkit.Logging.LogSeverity]::Success }
                }
                elseif ($RebootExitCodes -contains $result.ExitCode)
                {
                    @{ Message = "Execution completed successfully with exit code [$($result.ExitCode)]. A reboot is required."; Severity = [PSAppDeployToolkit.Logging.LogSeverity]::Warning }
                }
                else
                {
                    @{ Message = "Execution failed with exit code [$($result.ExitCode)].$(if (!$UseShellExecute -and !$NoStreamLogging) { " Please check the log file for any available stdout/stderr information." })"; Severity = [PSAppDeployToolkit.Logging.LogSeverity]::Error }
                }
                Write-ADTLogEntry @waleParams

                # Log the captured streams.
                if (!$NoStreamLogging)
                {
                    foreach ($property in ('StdOut', 'StdErr', 'Interleaved'))
                    {
                        $streamMessage = if ($result.$property.Count -gt 1)
                        {
                            "`n`n$([System.String]::Join([System.Environment]::NewLine, $result.$property))"
                        }
                        elseif ($result.$property.Count -eq 1)
                        {
                            $result.$property[0]
                        }
                        else
                        {
                            'N/A'
                        }
                        Write-ADTLogEntry -Message "$property Output from Execution: $streamMessage" -HostLogStreamType ([PSAppDeployToolkit.Logging.HostLogStreamType]::None)
                    }
                }

                # Throw if the execution failed.
                if ($waleParams.Message.StartsWith('Execution failed'))
                {
                    $naerParams = @{
                        Exception = [PSADT.ProcessManagement.ProcessException]::new($waleParams.Message, $result)
                        Category = [System.Management.Automation.ErrorCategory]::InvalidResult
                        ErrorId = 'ProcessExitCodeError'
                        TargetObject = $(if (!$SecureArgumentList) { $result })
                        RecommendedAction = "Please review the exit code with the vendor's documentation and try again."
                    }
                    throw (New-ADTErrorRecord @naerParams)
                }

                # Update the session's exit code.
                if ($adtSession -and $extInvoker -and !$ignoreExitCode -and $canSetExitCode)
                {
                    Set-ADTSessionExitCode -ExitCode $result.ExitCode
                }

                if ($PassThru)
                {
                    Write-ADTLogEntry -Message 'PassThru parameter specified, returning execution results object.'
                    return $result
                }
            }
            catch
            {
                Write-Error -ErrorRecord $_
            }
        }
        catch
        {
            $iafehParams = @{
                Cmdlet = $PSCmdlet
                SessionState = $ExecutionContext.SessionState
                ErrorRecord = $_
            }
            $sessionClosed = if (($_.Exception -is [System.Runtime.InteropServices.ExternalException]) -and ($null -ne $result))
            {
                if ($adtSession -and $extInvoker)
                {
                    if (($OriginalErrorAction -notmatch '^(SilentlyContinue|Ignore)$') -and $canSetExitCode)
                    {
                        Set-ADTSessionExitCode -ExitCode $result.ExitCode
                    }
                    if ($ExitOnProcessFailure -and !$PSBoundParameters.ContainsKey('ErrorAction'))
                    {
                        $iafehParams.ErrorAction = [System.Management.Automation.ActionPreference]::SilentlyContinue
                    }
                }
                Invoke-ADTFunctionErrorHandler @iafehParams -Silent
                if ($ExitOnProcessFailure)
                {
                    Close-ADTSession -PassThru
                }
            }
            elseif (($_.Exception -is [System.TimeoutException]) -or ($_.Exception -is [System.OperationCanceledException]))
            {
                if ($PSBoundParameters.ContainsKey('TimeoutAction'))
                {
                    $iafehParams.ErrorAction = $TimeoutAction
                }
                Invoke-ADTFunctionErrorHandler @iafehParams -DisableErrorResolving
            }
            else
            {
                Invoke-ADTFunctionErrorHandler @iafehParams -LogMessage "Error occurred while attempting to start the specified process." -ErrorAction Stop
            }
            if ($null -ne $sessionClosed)
            {
                break
            }
            if ($PassThru)
            {
                if ($result)
                {
                    Write-ADTLogEntry -Message 'PassThru parameter specified, returning execution results object.'
                    return $result
                }
                Write-ADTLogEntry -Message 'PassThru parameter specified, however no result was available.'
            }
        }
        finally
        {
            if ($cancellationTokenSource)
            {
                $cancellationTokenSource.Dispose()
            }
            if ($result -and !$PassThru)
            {
                $result.Dispose()
            }
        }
    }

    end
    {
        Complete-ADTFunction -Cmdlet $PSCmdlet
    }
}
