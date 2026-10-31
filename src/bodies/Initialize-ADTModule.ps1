
    begin
    {
        # Log our start time to clock the module init duration.
        $moduleInitStart = [System.DateTime]::Now
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -InformationAction SilentlyContinue
        $null = $PSBoundParameters.Remove('ScriptDirectory')

        # Throw if this function is called while a session is active.
        if (Test-ADTSessionActive)
        {
            $naerParams = @{
                Exception = [System.InvalidOperationException]::new("This function cannot be called while there is an active ADTSession in progress.")
                Category = [System.Management.Automation.ErrorCategory]::InvalidOperation
                ErrorId = 'InitWithActiveSessionError'
                TargetObject = Get-ADTSession
                RecommendedAction = "Please attempt module re-initialization once the active ADTSession(s) have been closed."
            }
            $PSCmdlet.ThrowTerminatingError((New-ADTErrorRecord @naerParams))
        }

        # Returns the Config/Strings subdirectories of the script directories that contain a data file.
        function Get-ADTScriptSubdirectory
        {
            param ([System.String]$Subdirectory)
            foreach ($directory in $ScriptDirectory)
            {
                if (Test-Path -LiteralPath (Join-Path -Path $directory -ChildPath "$Subdirectory/$($Subdirectory.ToLowerInvariant()).psd1") -PathType Leaf)
                {
                    [System.IO.DirectoryInfo](Join-Path -Path $directory -ChildPath $Subdirectory)
                }
            }
        }
    }

    process
    {
        try
        {
            try
            {
                $configDirectories = @(Get-ADTScriptSubdirectory -Subdirectory Config)
                $stringsDirectories = @(Get-ADTScriptSubdirectory -Subdirectory Strings)
                if (Test-ADTModuleInitialized)
                {
                    Reset-ADTModuleState
                }
                foreach ($callback in (Get-ADTModuleCallback -Hookpoint OnInit | & { process { return $_ } }))
                {
                    & $callback
                }
                $environment = New-ADTEnvironmentTable @PSBoundParameters
                $config = Import-ADTConfig -BaseDirectory $configDirectories -Environment $environment
                $language = Get-ADTStringLanguage -Environment $environment -Config $config
                $stringTable = Import-ADTStringTable -BaseDirectory $stringsDirectories -Config $config -UICulture $language

                $Script:ADT.Directories = [ordered]@{
                    Script = [System.String[]]$ScriptDirectory
                    Config = $(if ($configDirectories) { [System.String[]]$configDirectories.FullName })
                    Strings = $(if ($stringsDirectories) { [System.String[]]$stringsDirectories.FullName })
                }
                $Script:ADT.Environment = $environment
                $Script:ADT.Config = $config
                $Script:ADT.Strings = $stringTable
                $Script:ADT.Language = $language
                $Script:ADT.Initialized = $true
                $Script:ADT.InitDuration = [System.DateTime]::Now - $moduleInitStart
                [PSAppDeployToolkit.Foundation.ModuleDatabase]::Config = $config
                [PSAppDeployToolkit.Foundation.ModuleDatabase]::Strings = $stringTable
                [PSAppDeployToolkit.Foundation.ModuleDatabase]::Environment = $environment
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
        Complete-ADTFunction -Cmdlet $PSCmdlet -InformationAction SilentlyContinue
    }
