param($Src, $Out)
$files = (Get-ChildItem $Src -Filter *.cs -Recurse).FullName
$refs = @([psobject].Assembly.Location,'System.Collections','System.Linq','System.Text.RegularExpressions','System.Security.Principal','System.Security.Principal.Windows','System.Collections.Concurrent','System.Diagnostics.Process','System.ComponentModel.Primitives','System.Runtime','System.IO.Compression','System.IO.Compression.ZipFile','System.Console','System.Text.Encoding.Extensions','System.Collections.Specialized','System.Linq.Expressions','System.Private.CoreLib','System.Threading','System.Runtime.InteropServices','System.Memory','System.ComponentModel','System.ObjectModel','System.Text.Json','System.Runtime.Serialization.Primitives','System.Text.Encodings.Web','System.IO.Compression.ZipFile','System.Collections.NonGeneric','System.Diagnostics.StackTrace','System.Console','System.Threading.Tasks','System.Runtime.InteropServices','System.Diagnostics.TraceSource','System.ServiceProcess.ServiceController','System.Threading.Thread')
if (Test-Path $Out) { Remove-Item $Out }
Add-Type -Path $files -OutputAssembly $Out -ReferencedAssemblies $refs -IgnoreWarnings 
"Built $Out"
