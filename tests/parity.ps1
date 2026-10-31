param($Original, $Port)
$map = @{ 'System.Security.Principal.NTAccount'='PSADT.AccountManagement.UnixIdentity'; 'System.Security.Principal.SecurityIdentifier'='PSADT.AccountManagement.UnixIdentity'; 'System.ServiceProcess.ServiceController'='PSADT.ServiceManagement.SystemdService'; 'Microsoft.Dism.Commands.ImageObject'='System.Object'; 'System.__ComObject'='System.Object'; 'Windows.UI.Notifications.ToastNotificationMode'='System.String' }
function Get-Sig($file) {
  $ast = [System.Management.Automation.Language.Parser]::ParseFile($file,[ref]$null,[ref]$null)
  $fn = $ast.Find({$args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]},$false)
  if (!$fn.Body.ParamBlock) { return '' }
  ($fn.Body.ParamBlock.Parameters | % {
    $t = ($_.Attributes | ? { $_ -is [System.Management.Automation.Language.TypeConstraintAst] } | % { $n = $_.TypeName.FullName -replace '\[\]$'; if ($map[$n]) { $map[$n] + $(if ($_.TypeName.FullName.EndsWith('[]')) {'[]'}) } else { $_.TypeName.FullName } }) -join ','
    $a = ($_.Attributes | ? { $_ -isnot [System.Management.Automation.Language.TypeConstraintAst] } | % { $_.Extent.Text -replace '\s+',' ' }) -join ' '
    "$($_.Name.VariablePath)|$t|$a|$($_.DefaultValue.Extent.Text)"
  }) -join "`n"
}
$diff = 0
foreach ($f in Get-ChildItem "$Original/Public/*.ps1") {
  $p = Join-Path "$Port/Public" $f.Name
  if (!(Test-Path $p)) { "MISSING: $($f.BaseName)"; $diff++; continue }
  $a = Get-Sig $f.FullName; $b = Get-Sig $p
  if ($a -ne $b) { "DIFF: $($f.BaseName)"; $diff++; Compare-Object ($a -split "`n") ($b -split "`n") | % { "   $($_.SideIndicator) $($_.InputObject.Substring(0, [Math]::Min(160, $_.InputObject.Length)))" } }
}
"Functions compared: $((Get-ChildItem "$Original/Public/*.ps1").Count); differing: $diff"
