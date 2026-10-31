#nullable enable
// -----------------------------------------------------------------------------
// PSAppDeployToolkit for Linux - .NET type surface.
//
// The original PSAppDeployToolkit ships these types in its Windows-only
// PSADT.dll / PSAppDeployToolkit.dll assemblies. To keep every public
// function's parameter block byte-for-byte identical to the original, this
// file re-creates the same type names (namespaces, enum values, property
// names) with Linux implementations behind them.
//
// Licensed under the GNU Lesser General Public License v3.0, as is the
// original PSAppDeployToolkit project.
// -----------------------------------------------------------------------------
using System;
using System.Collections;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Runtime.CompilerServices;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using PSAppDeployToolkit.Foundation;
using PSAppDeployToolkit.Logging;

namespace PSADT.AccountManagement
{
    /// <summary>
    /// Linux stand-in for System.Security.Principal.NTAccount / SecurityIdentifier,
    /// which throw PlatformNotSupportedException on Linux. Exposes the same
    /// <c>Value</c> property and string rendering. SIDs use the well-known
    /// Unix mapping S-1-22-1-&lt;uid&gt; (users) / S-1-22-2-&lt;gid&gt; (groups).
    /// </summary>
    public sealed class UnixIdentity : IEquatable<UnixIdentity>
    {
        /// <summary>Accepts a user name ("bob", "DOMAIN\bob" -> "bob"), a Unix SID (S-1-22-1-1000) or a numeric uid.</summary>
        public UnixIdentity(string value)
        {
            ArgumentException.ThrowIfNullOrWhiteSpace(value);
            if (value.Contains('\\', StringComparison.Ordinal))
            {
                value = value[(value.LastIndexOf('\\') + 1)..];
            }
            Match sid = Regex.Match(value, @"^S-1-22-[12]-(\d+)$");
            if (sid.Success)
            {
                Value = value;
                Id = uint.Parse(sid.Groups[1].Value, CultureInfo.InvariantCulture);
                return;
            }
            if (uint.TryParse(value, NumberStyles.None, CultureInfo.InvariantCulture, out uint uid))
            {
                Value = PSADT.ProcessManagement.LinuxUtilities.GetUserName(uid) ?? value;
                Id = uid;
                return;
            }
            Value = value;
            Id = PSADT.ProcessManagement.LinuxUtilities.GetUid(value);
        }
        public UnixIdentity(string value, uint? id)
        {
            ArgumentException.ThrowIfNullOrWhiteSpace(value);
            Value = value;
            Id = id;
        }
        public bool IsSid => Value.StartsWith("S-1-22-", StringComparison.Ordinal);
        public string Value { get; }
        public uint? Id { get; }
        public override string ToString() => Value;
        public bool Equals(UnixIdentity? other) => other is not null && string.Equals(Value, other.Value, StringComparison.Ordinal);
        public override bool Equals(object? obj) => obj switch
        {
            UnixIdentity u => Equals(u),
            string s => string.Equals(Value, s, StringComparison.Ordinal),
            _ => false,
        };
        public override int GetHashCode() => StringComparer.Ordinal.GetHashCode(Value);
        public static UnixIdentity ForUser(string userName, uint uid) => new(userName, uid);
        public static UnixIdentity SidForUser(uint uid) => new($"S-1-22-1-{uid}", uid);
    }

    public static class AccountUtilities
    {
        [System.Runtime.InteropServices.DllImport("libc")] private static extern uint geteuid();
        [System.Runtime.InteropServices.DllImport("libc")] private static extern uint getuid();

        public static uint CallerUid
        {
            get { try { return geteuid(); } catch { return uint.MaxValue; } }
        }
        public static bool CallerIsAdmin => CallerUid == 0;
        public static bool CallerIsLocalSystem => CallerUid == 0;
        public static string CallerUsername => Environment.UserName;
        public static int CallerProcessId => Environment.ProcessId;
        public static UnixIdentity CallerNTAccount => new(Environment.UserName, CallerUid);
        public static UnixIdentity CallerSID => UnixIdentity.SidForUser(CallerUid);
    }

    public sealed record class UserProfileInfo
    {
        public UserProfileInfo(UnixIdentity nTAccount, UnixIdentity sID, DirectoryInfo profilePath, CultureInfo? userLocale = null)
        {
            NTAccount = nTAccount;
            SID = sID;
            ProfilePath = profilePath;
            UserLocale = userLocale;
            DesktopPath = Probe(profilePath, "Desktop");
            DocumentsPath = Probe(profilePath, "Documents");
            AppDataPath = new DirectoryInfo(Path.Join(profilePath.FullName, ".config"));
            LocalAppDataPath = new DirectoryInfo(Path.Join(profilePath.FullName, ".local", "share"));
            StartMenuPath = new DirectoryInfo(Path.Join(profilePath.FullName, ".local", "share", "applications"));
            TempPath = new DirectoryInfo(Path.Join(profilePath.FullName, ".cache"));
        }
        private static DirectoryInfo? Probe(DirectoryInfo root, string name)
        {
            DirectoryInfo dir = new(Path.Join(root.FullName, name));
            return dir.Exists ? dir : null;
        }
        public UnixIdentity NTAccount { get; }
        public UnixIdentity SID { get; }
        public DirectoryInfo ProfilePath { get; }
        public DirectoryInfo? AppDataPath { get; }
        public DirectoryInfo? LocalAppDataPath { get; }
        public DirectoryInfo? DesktopPath { get; }
        public DirectoryInfo? DocumentsPath { get; }
        public DirectoryInfo? StartMenuPath { get; }
        public DirectoryInfo? TempPath { get; }
        public DirectoryInfo? OneDrivePath => null;
        public DirectoryInfo? OneDriveCommercialPath => null;
        public CultureInfo? UserLocale { get; }
    }
}

namespace PSADT.TerminalServices
{
    using PSADT.AccountManagement;

    public sealed record class SessionInfo
    {
        public SessionInfo(string userName, uint uid, uint sessionId, string? sessionName, string? seat, string? tty, string? display, string? type, string? state, string? remoteHost, DateTime logonTime, bool isLocalAdmin, bool isCurrentSession)
        {
            UserName = userName;
            DomainName = Environment.MachineName;
            NTAccount = UnixIdentity.ForUser(userName, uid);
            SID = UnixIdentity.SidForUser(uid);
            SessionId = sessionId;
            SessionName = sessionName;
            Seat = seat;
            TTY = tty;
            Display = display;
            Type = type;
            State = state;
            ClientName = remoteHost;
            LogonTime = logonTime;
            IsLocalAdmin = isLocalAdmin;
            IsCurrentSession = isCurrentSession;
            IsConsoleSession = seat is not null && seat.Length > 0;
            IsRdpSession = !string.IsNullOrWhiteSpace(remoteHost);
            IsActiveUserSession = string.Equals(state, "active", StringComparison.OrdinalIgnoreCase) || string.Equals(state, "online", StringComparison.OrdinalIgnoreCase);
            IsUserSession = uid >= 1000 || uid == 0;
            IsValidUserSession = IsUserSession && !string.Equals(state, "closing", StringComparison.OrdinalIgnoreCase);
            Uid = uid;
        }
        public UnixIdentity NTAccount { get; }
        public UnixIdentity SID { get; }
        public string UserName { get; }
        public string DomainName { get; }
        public uint SessionId { get; }
        public string? SessionName { get; }
        public string? State { get; }
        public bool IsCurrentSession { get; }
        public bool IsConsoleSession { get; }
        public bool IsActiveUserSession { get; }
        public bool IsValidUserSession { get; }
        public bool IsUserSession { get; }
        public bool IsRdpSession { get; }
        public bool? IsLocalAdmin { get; }
        public DateTime LogonTime { get; }
        public TimeSpan? IdleTime => null;
        public DateTime? DisconnectTime => null;
        public string? ClientName { get; }
        // Linux-specific extras.
        public uint Uid { get; }
        public string? Seat { get; }
        public string? TTY { get; }
        public string? Display { get; }
        public string? Type { get; }
        public override string ToString() => string.Join(Environment.NewLine,
            $"NTAccount           : {NTAccount}", $"SID                 : {SID}", $"UserName            : {UserName}",
            $"SessionId           : {SessionId}", $"SessionName         : {SessionName}", $"State               : {State}",
            $"Seat                : {Seat}", $"Type                : {Type}", $"Display             : {Display}",
            $"IsConsoleSession    : {IsConsoleSession}", $"IsActiveUserSession : {IsActiveUserSession}",
            $"IsLocalAdmin        : {IsLocalAdmin}", $"LogonTime           : {LogonTime:O}", $"ClientName          : {ClientName}");
    }
}

namespace PSADT.Foundation
{
    using PSADT.AccountManagement;
    using PSADT.TerminalServices;

    public sealed record class RunAsActiveUser
    {
        public RunAsActiveUser(string userName, uint uid, uint sessionId, bool? isLocalAdmin)
        {
            UserName = userName;
            Uid = uid;
            DomainName = Environment.MachineName;
            SessionId = sessionId;
            IsLocalAdmin = isLocalAdmin;
        }
        public RunAsActiveUser(SessionInfo session) : this((session ?? throw new ArgumentNullException(nameof(session))).UserName, session.Uid, session.SessionId, session.IsLocalAdmin)
        {
            Display = session.Display;
        }
        public UnixIdentity NTAccount => UnixIdentity.ForUser(UserName, Uid);
        public UnixIdentity SID => UnixIdentity.SidForUser(Uid);
        public readonly string UserName;
        public readonly string? DomainName;
        public readonly uint SessionId;
        public readonly bool? IsLocalAdmin;
        public readonly uint Uid;
        public string? Display { get; init; }
    }
}

namespace PSADT.ProcessManagement
{
    using PSADT.AccountManagement;
    using PSADT.Foundation;

    public sealed record class ProcessDefinition
    {
        public ProcessDefinition(string name)
        {
            ArgumentException.ThrowIfNullOrWhiteSpace(name);
            if (Regex.IsMatch(name, @"^\*+$"))
            {
                throw new ArgumentException("The process name cannot be only wildcard characters.", nameof(name));
            }
            Name = name;
            _processName = Path.IsPathFullyQualified(name) ? Path.GetFileName(name) : null;
            _nameRegex = name.Contains('*', StringComparison.Ordinal) ? new Regex($"^{Regex.Escape(name).Replace("\\*", ".*", StringComparison.Ordinal)}$", RegexOptions.IgnoreCase) : null;
            _processNameRegex = name.Contains('*', StringComparison.Ordinal) && Path.IsPathFullyQualified(name) ? new Regex($"^{Regex.Escape(Path.GetFileName(name)).Replace("\\*", ".*", StringComparison.Ordinal)}$", RegexOptions.IgnoreCase) : null;
        }
        public ProcessDefinition(string name, string? description) : this(name)
        {
            if (description?.Length > 0)
            {
                ArgumentException.ThrowIfNullOrWhiteSpace(description);
            }
            if (!string.IsNullOrWhiteSpace(description))
            {
                Description = description;
            }
        }
        public ProcessDefinition(IDictionary properties) : this((string?)(properties ?? throw new ArgumentNullException(nameof(properties)))["Name"] ?? throw new ArgumentNullException(nameof(properties), "The specified key 'Name' is missing."), (string?)properties["Description"])
        {
        }
        public bool NameIsFullyQualifiedPath() => Path.IsPathFullyQualified(Name);
        public bool IsNameMatch(string input)
        {
            ArgumentException.ThrowIfNullOrWhiteSpace(input);
            return _nameRegex is null ? Name.Equals(input, StringComparison.Ordinal) : _nameRegex.IsMatch(input);
        }
        public bool ProcessNameIsMatch(string processName)
        {
            ArgumentNullException.ThrowIfNull(processName);
            return _processNameRegex?.IsMatch(processName)
                ?? _nameRegex?.IsMatch(processName)
                ?? _processName?.Equals(processName, StringComparison.Ordinal)
                ?? Name.Equals(processName, StringComparison.Ordinal);
        }
        public override string ToString() => Name;
        public readonly string Name;
        public readonly string? Description;
        private readonly string? _processName;
        private readonly Regex? _nameRegex;
        private readonly Regex? _processNameRegex;
        public bool Equals(ProcessDefinition? other) => other is not null && string.Equals(Name, other.Name, StringComparison.Ordinal) && string.Equals(Description, other.Description, StringComparison.Ordinal);
        public override int GetHashCode() => HashCode.Combine(StringComparer.Ordinal.GetHashCode(Name), Description is null ? 0 : StringComparer.Ordinal.GetHashCode(Description));
    }

    public sealed record class RunningProcessInfo
    {
        public RunningProcessInfo(Process process, string description, string fileName, IReadOnlyList<string> argumentList, UnixIdentity? owner)
        {
            Process = process;
            Description = description;
            FileName = new FileInfo(fileName);
            ArgumentList = argumentList;
            User = owner;
            SID = owner?.Id is uint uid ? UnixIdentity.SidForUser(uid) : null;
        }
        public Process Process { get; }
        public string Description { get; }
        public FileInfo FileName { get; }
        public IReadOnlyList<string> ArgumentList { get; }
        public UnixIdentity? SID { get; }
        public UnixIdentity? User { get; }

        /// <summary>Enumerates /proc and returns every running process that matches one of the definitions.</summary>
        public static IReadOnlyList<RunningProcessInfo> Get(IReadOnlyList<ProcessDefinition> processDefinitions)
        {
            ArgumentNullException.ThrowIfNull(processDefinitions);
            List<RunningProcessInfo> results = [];
            foreach (Process process in Process.GetProcesses())
            {
                string? exePath = null;
                string[] argv = [];
                try { exePath = new FileInfo($"/proc/{process.Id}/exe").LinkTarget; } catch { }
                try { argv = File.ReadAllText($"/proc/{process.Id}/cmdline").Split('\0', StringSplitOptions.RemoveEmptyEntries); } catch { }
                if (exePath is not null && exePath.EndsWith(" (deleted)", StringComparison.Ordinal))
                {
                    exePath = exePath[..^10];
                }
                string comm = string.Empty;
                try { comm = process.ProcessName; } catch { }
                string exeName = exePath is not null ? Path.GetFileName(exePath) : comm;
                string argv0Name = argv.Length > 0 ? Path.GetFileName(argv[0]) : comm;
                foreach (ProcessDefinition definition in processDefinitions)
                {
                    bool match = definition.NameIsFullyQualifiedPath()
                        ? (exePath is not null && definition.IsNameMatch(exePath)) || (argv.Length > 0 && definition.IsNameMatch(argv[0]))
                        : definition.ProcessNameIsMatch(exeName) || definition.ProcessNameIsMatch(argv0Name) || (comm.Length > 0 && definition.ProcessNameIsMatch(comm));
                    if (!match)
                    {
                        continue;
                    }
                    UnixIdentity? owner = null;
                    try
                    {
                        foreach (string line in File.ReadLines($"/proc/{process.Id}/status"))
                        {
                            if (line.StartsWith("Uid:", StringComparison.Ordinal))
                            {
                                uint uid = uint.Parse(line.Split('\t', StringSplitOptions.RemoveEmptyEntries)[1], CultureInfo.InvariantCulture);
                                owner = new UnixIdentity(LinuxUtilities.GetUserName(uid) ?? uid.ToString(CultureInfo.InvariantCulture), uid);
                                break;
                            }
                        }
                    }
                    catch { }
                    results.Add(new RunningProcessInfo(process, definition.Description ?? exeName, exePath ?? (argv.Length > 0 ? argv[0] : comm), argv.Skip(1).ToList().AsReadOnly(), owner));
                    break;
                }
            }
            return results.AsReadOnly();
        }
    }

    public sealed class ProcessResult : IDisposable
    {
        public ProcessResult(int exitCode)
        {
            ExitCode = exitCode;
        }
        public ProcessResult(int exitCode, IReadOnlyCollection<string>? stdOut, IReadOnlyCollection<string>? stdErr, IReadOnlyCollection<string>? interleaved) : this(exitCode)
        {
            StdOut = new ReadOnlyCollection<string>(stdOut?.ToList() ?? []);
            StdErr = new ReadOnlyCollection<string>(stdErr?.ToList() ?? []);
            Interleaved = new ReadOnlyCollection<string>(interleaved?.ToList() ?? []);
        }
        public ProcessResult(Process? process, string commandLine, int exitCode, IReadOnlyCollection<string>? stdOut, IReadOnlyCollection<string>? stdErr, IReadOnlyCollection<string>? interleaved) : this(exitCode, stdOut, stdErr, interleaved)
        {
            Process = process;
            CommandLine = commandLine;
        }
        public void Dispose()
        {
            Process?.Dispose();
        }
        public readonly Process? Process;
        public readonly object? LaunchInfo;
        public readonly string? CommandLine;
        public readonly int ExitCode;
        public readonly IReadOnlyList<string> StdOut = new ReadOnlyCollection<string>([]);
        public readonly IReadOnlyList<string> StdErr = new ReadOnlyCollection<string>([]);
        public readonly IReadOnlyList<string> Interleaved = new ReadOnlyCollection<string>([]);
    }

    public sealed class ProcessException : System.Runtime.InteropServices.ExternalException
    {
        public ProcessException(string message, ProcessResult result) : base(message, result?.ExitCode ?? -1)
        {
            Result = result ?? throw new ArgumentNullException(nameof(result));
        }
        public ProcessResult Result { get; }
    }

    public sealed class ProcessHandle
    {
        internal ProcessHandle(Process process, string commandLine, Task<ProcessResult> task)
        {
            Process = process;
            CommandLine = commandLine;
            Task = task;
        }
        public Process Process { get; }
        public object? LaunchInfo => null;
        public string CommandLine { get; }
        public Task<ProcessResult> Task { get; }
        public TaskStatus Status => Task.Status;
        public bool IsCanceled => Task.IsCanceled;
        public bool IsCompleted => Task.IsCompleted;
        public bool IsFaulted => Task.IsFaulted;
        public TaskAwaiter<ProcessResult> GetAwaiter() => Task.GetAwaiter();
        public ConfiguredTaskAwaitable<ProcessResult> ConfigureAwait(bool continueOnCapturedContext) => Task.ConfigureAwait(continueOnCapturedContext);
        public ProcessResult GetResult() => Task.GetAwaiter().GetResult();
    }

    /// <summary>Launch options for <see cref="ProcessManager.LaunchAsync"/>.</summary>
    public sealed class LinuxLaunchInfo
    {
        public string FilePath { get; set; } = string.Empty;
        public string[]? ArgumentList { get; set; }
        public string? WorkingDirectory { get; set; }
        public RunAsActiveUser? RunAsActiveUser { get; set; }
        public bool InheritEnvironmentVariables { get; set; }
        public bool ExpandEnvironmentVariables { get; set; }
        public string[]? StandardInput { get; set; }
        public bool CaptureOutput { get; set; } = true;
        public bool WaitForChildProcesses { get; set; }
        public bool KillChildProcessesWithParent { get; set; }
        public Encoding? StreamEncoding { get; set; }
        public ProcessPriorityClass? PriorityClass { get; set; }
        public CancellationToken CancellationToken { get; set; }
        public bool NoTerminateOnTimeout { get; set; }
    }

    public static class ProcessManager
    {
        /// <summary>The exit code returned when a process is aborted because its timeout elapsed.</summary>
        public const int TimeoutExitCode = 258;

        public static ProcessHandle LaunchAsync(LinuxLaunchInfo info)
        {
            ArgumentNullException.ThrowIfNull(info);
            string filePath = info.ExpandEnvironmentVariables ? LinuxUtilities.ExpandEnvironmentVariables(info.FilePath) : info.FilePath;
            List<string> args = (info.ArgumentList ?? []).Select(a => info.ExpandEnvironmentVariables ? LinuxUtilities.ExpandEnvironmentVariables(a) : a).ToList();
            string commandLine = CommandLineUtilities.ArgumentListToCommandLine([filePath, .. args]);

            ProcessStartInfo psi = new()
            {
                UseShellExecute = false,
                RedirectStandardOutput = info.CaptureOutput,
                RedirectStandardError = info.CaptureOutput,
                RedirectStandardInput = info.StandardInput is { Length: > 0 },
                WorkingDirectory = info.WorkingDirectory ?? string.Empty,
                CreateNoWindow = true,
            };
            if (info.StreamEncoding is not null && info.CaptureOutput)
            {
                psi.StandardOutputEncoding = info.StreamEncoding;
                psi.StandardErrorEncoding = info.StreamEncoding;
            }

            if (info.RunAsActiveUser is RunAsActiveUser user && user.Uid != AccountUtilities.CallerUid)
            {
                // Run as the logged-on user. runuser needs root; sudo is the fallback for non-root callers.
                bool useRunuser = AccountUtilities.CallerIsAdmin && File.Exists("/usr/sbin/runuser") || File.Exists("/sbin/runuser") && AccountUtilities.CallerIsAdmin;
                psi.FileName = useRunuser ? "runuser" : "sudo";
                if (useRunuser) { psi.ArgumentList.Add("-u"); psi.ArgumentList.Add(user.UserName); }
                else { psi.ArgumentList.Add("-n"); psi.ArgumentList.Add("-u"); psi.ArgumentList.Add(user.UserName); }
                psi.ArgumentList.Add("--");
                psi.ArgumentList.Add("env");
                if (!info.InheritEnvironmentVariables)
                {
                    psi.ArgumentList.Add("-i");
                    string home = LinuxUtilities.GetHomeDirectory(user.Uid) ?? $"/home/{user.UserName}";
                    psi.ArgumentList.Add($"HOME={home}");
                    psi.ArgumentList.Add($"USER={user.UserName}");
                    psi.ArgumentList.Add($"LOGNAME={user.UserName}");
                    psi.ArgumentList.Add($"PATH={Environment.GetEnvironmentVariable("PATH") ?? "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"}");
                    psi.ArgumentList.Add($"LANG={Environment.GetEnvironmentVariable("LANG") ?? "C.UTF-8"}");
                }
                string runtimeDir = $"/run/user/{user.Uid}";
                if (Directory.Exists(runtimeDir))
                {
                    psi.ArgumentList.Add($"XDG_RUNTIME_DIR={runtimeDir}");
                    if (File.Exists($"{runtimeDir}/bus")) { psi.ArgumentList.Add($"DBUS_SESSION_BUS_ADDRESS=unix:path={runtimeDir}/bus"); }
                }
                if (!string.IsNullOrWhiteSpace(user.Display)) { psi.ArgumentList.Add($"DISPLAY={user.Display}"); }
                psi.ArgumentList.Add(filePath);
                foreach (string a in args) { psi.ArgumentList.Add(a); }
            }
            else
            {
                psi.FileName = filePath;
                foreach (string a in args) { psi.ArgumentList.Add(a); }
            }

            Process process = new() { StartInfo = psi, EnableRaisingEvents = true };
            List<string> stdOut = [], stdErr = [], interleaved = [];
            object sync = new();
            if (info.CaptureOutput)
            {
                process.OutputDataReceived += (_, e) => { if (e.Data is not null) { lock (sync) { stdOut.Add(e.Data); interleaved.Add(e.Data); } } };
                process.ErrorDataReceived += (_, e) => { if (e.Data is not null) { lock (sync) { stdErr.Add(e.Data); interleaved.Add(e.Data); } } };
            }
            if (!process.Start())
            {
                throw new InvalidOperationException($"Failed to start process [{filePath}].");
            }
            if (info.PriorityClass is ProcessPriorityClass priority)
            {
                try { process.PriorityClass = priority; } catch { }
            }
            if (info.CaptureOutput)
            {
                process.BeginOutputReadLine();
                process.BeginErrorReadLine();
            }
            if (psi.RedirectStandardInput)
            {
                foreach (string line in info.StandardInput!) { process.StandardInput.WriteLine(line); }
                process.StandardInput.Close();
            }

            int pid = process.Id;
            Task<ProcessResult> task = Task.Run(async () =>
            {
                HashSet<int> descendants = [];
                bool timedOut = false;
                using (CancellationTokenSource poll = new())
                {
                    Task tracker = info.WaitForChildProcesses || info.KillChildProcessesWithParent
                        ? Task.Run(async () =>
                        {
                            while (!poll.IsCancellationRequested)
                            {
                                foreach (int d in LinuxUtilities.GetDescendantProcessIds(pid)) { lock (descendants) { descendants.Add(d); } }
                                try { await Task.Delay(250, poll.Token).ConfigureAwait(false); } catch (OperationCanceledException) { }
                            }
                        })
                        : Task.CompletedTask;
                    try
                    {
                        await process.WaitForExitAsync(info.CancellationToken).ConfigureAwait(false);
                    }
                    catch (OperationCanceledException)
                    {
                        timedOut = true;
                        if (!info.NoTerminateOnTimeout)
                        {
                            try { process.Kill(entireProcessTree: true); } catch { }
                            try { process.WaitForExit(5000); } catch { }
                        }
                    }
                    poll.Cancel();
                    await tracker.ConfigureAwait(false);
                }
                if (!timedOut)
                {
                    int[] children;
                    lock (descendants) { children = [.. descendants]; }
                    if (info.KillChildProcessesWithParent)
                    {
                        foreach (int child in children) { try { using Process c = Process.GetProcessById(child); c.Kill(true); } catch { } }
                    }
                    else if (info.WaitForChildProcesses)
                    {
                        foreach (int child in children)
                        {
                            try
                            {
                                using Process c = Process.GetProcessById(child);
                                await c.WaitForExitAsync(info.CancellationToken).ConfigureAwait(false);
                            }
                            catch (OperationCanceledException) { timedOut = true; break; }
                            catch { }
                        }
                    }
                }
                int exitCode = timedOut ? TimeoutExitCode : process.ExitCode;
                List<string> o, e, i;
                lock (sync) { o = [.. stdOut]; e = [.. stdErr]; i = [.. interleaved]; }
                return new ProcessResult(process, commandLine, exitCode, o, e, i);
            });
            return new ProcessHandle(process, commandLine, task);
        }
    }

    public static class CommandLineUtilities
    {
        public static string ArgumentListToCommandLine(IEnumerable<string> argv)
        {
            return string.Join(' ', argv.Select(Quote));
        }
        public static IReadOnlyList<string> CommandLineToArgumentList(string commandLine)
        {
            List<string> result = [];
            StringBuilder current = new();
            bool inSingle = false, inDouble = false, hasToken = false;
            for (int i = 0; i < commandLine.Length; i++)
            {
                char c = commandLine[i];
                if (inSingle)
                {
                    if (c == '\'') { inSingle = false; } else { current.Append(c); }
                }
                else if (inDouble)
                {
                    if (c == '"') { inDouble = false; }
                    else if (c == '\\' && i + 1 < commandLine.Length && "\"\\$`".Contains(commandLine[i + 1], StringComparison.Ordinal)) { current.Append(commandLine[++i]); }
                    else { current.Append(c); }
                }
                else if (char.IsWhiteSpace(c))
                {
                    if (hasToken) { result.Add(current.ToString()); current.Clear(); hasToken = false; }
                }
                else
                {
                    hasToken = true;
                    if (c == '\'') { inSingle = true; }
                    else if (c == '"') { inDouble = true; }
                    else if (c == '\\' && i + 1 < commandLine.Length) { current.Append(commandLine[++i]); }
                    else { current.Append(c); }
                }
            }
            if (hasToken) { result.Add(current.ToString()); }
            return result.AsReadOnly();
        }
        private static string Quote(string arg)
        {
            if (arg.Length == 0) { return "''"; }
            return Regex.IsMatch(arg, @"^[A-Za-z0-9_@%+=:,./-]+$") ? arg : "'" + arg.Replace("'", "'\\''", StringComparison.Ordinal) + "'";
        }
    }

    public static class LinuxUtilities
    {
        private static Dictionary<uint, (string Name, string Home)>? _passwd;
        private static Dictionary<uint, (string Name, string Home)> Passwd
        {
            get
            {
                if (_passwd is null)
                {
                    Dictionary<uint, (string, string)> map = [];
                    try
                    {
                        foreach (string line in File.ReadLines("/etc/passwd"))
                        {
                            string[] f = line.Split(':');
                            if (f.Length >= 7 && uint.TryParse(f[2], NumberStyles.None, CultureInfo.InvariantCulture, out uint uid))
                            {
                                map.TryAdd(uid, (f[0], f[5]));
                            }
                        }
                    }
                    catch { }
                    _passwd = map;
                }
                return _passwd;
            }
        }
        public static string? GetUserName(uint uid) => Passwd.TryGetValue(uid, out var e) ? e.Name : null;
        public static string? GetHomeDirectory(uint uid) => Passwd.TryGetValue(uid, out var e) ? e.Home : null;
        public static uint? GetUid(string userName)
        {
            foreach (var kv in Passwd) { if (string.Equals(kv.Value.Name, userName, StringComparison.Ordinal)) { return kv.Key; } }
            return null;
        }
        public static IReadOnlyList<(uint Uid, string Name, string Home)> GetPasswdEntries() => Passwd.Select(static kv => (kv.Key, kv.Value.Name, kv.Value.Home)).OrderBy(static e => e.Key).ToList().AsReadOnly();
        public static void ResetCache() => _passwd = null;

        public static string ExpandEnvironmentVariables(string input)
        {
            // Support both Windows-style %VAR% and POSIX-style $VAR / ${VAR}.
            string result = Regex.Replace(input, @"%([A-Za-z_][A-Za-z0-9_]*)%", m => Environment.GetEnvironmentVariable(m.Groups[1].Value) ?? m.Value);
            return Regex.Replace(result, @"\$\{([A-Za-z_][A-Za-z0-9_]*)\}|\$([A-Za-z_][A-Za-z0-9_]*)", m => Environment.GetEnvironmentVariable(m.Groups[1].Success ? m.Groups[1].Value : m.Groups[2].Value) ?? m.Value);
        }

        public static IReadOnlyList<int> GetDescendantProcessIds(int rootPid)
        {
            Dictionary<int, List<int>> children = [];
            foreach (string dir in Directory.EnumerateDirectories("/proc"))
            {
                if (!int.TryParse(Path.GetFileName(dir), NumberStyles.None, CultureInfo.InvariantCulture, out int pid)) { continue; }
                try
                {
                    string stat = File.ReadAllText(Path.Join(dir, "stat"));
                    int close = stat.LastIndexOf(')');
                    string[] fields = stat[(close + 2)..].Split(' ');
                    int ppid = int.Parse(fields[1], CultureInfo.InvariantCulture);
                    if (!children.TryGetValue(ppid, out List<int>? list)) { children[ppid] = list = []; }
                    list.Add(pid);
                }
                catch { }
            }
            List<int> result = [];
            Queue<int> queue = new([rootPid]);
            while (queue.Count > 0)
            {
                int current = queue.Dequeue();
                if (!children.TryGetValue(current, out List<int>? list)) { continue; }
                foreach (int child in list) { result.Add(child); queue.Enqueue(child); }
            }
            return result.AsReadOnly();
        }
    }
}

namespace PSADT.ServiceManagement
{
    using System.ServiceProcess;

    /// <summary>
    /// A systemd unit presented with the same members as System.ServiceProcess.ServiceController
    /// (ServiceName, DisplayName, Status, StartType, DependentServices, ServicesDependedOn, Refresh()).
    /// </summary>
    public sealed class SystemdService
    {
        public SystemdService(string name)
        {
            ArgumentException.ThrowIfNullOrWhiteSpace(name);
            Unit = name.Contains('.', StringComparison.Ordinal) ? name : $"{name}.service";
            ServiceName = Unit.EndsWith(".service", StringComparison.Ordinal) ? Unit[..^8] : Unit;
            Refresh();
        }
        public string Unit { get; }
        public string ServiceName { get; }
        public string Name => ServiceName;
        public string DisplayName { get; private set; } = string.Empty;
        public string MachineName => ".";
        public bool Exists { get; private set; }
        public string LoadState { get; private set; } = string.Empty;
        public string ActiveState { get; private set; } = string.Empty;
        public string SubState { get; private set; } = string.Empty;
        public string UnitFileState { get; private set; } = string.Empty;
        public ServiceControllerStatus Status { get; private set; }
        public ServiceStartMode StartType { get; private set; }
        public bool CanStop => Status == ServiceControllerStatus.Running;
        public SystemdService[] DependentServices => Related("RequiredBy", "WantedBy");
        public SystemdService[] ServicesDependedOn => Related("Requires");
        private Dictionary<string, string> _props = new(StringComparer.Ordinal);

        public void Refresh()
        {
            _props = Show(Unit, "Id,Description,LoadState,ActiveState,SubState,UnitFileState,Requires,RequiredBy,WantedBy");
            LoadState = _props.GetValueOrDefault("LoadState", "not-found");
            Exists = LoadState is not "not-found" and not "";
            DisplayName = _props.GetValueOrDefault("Description", ServiceName);
            ActiveState = _props.GetValueOrDefault("ActiveState", string.Empty);
            SubState = _props.GetValueOrDefault("SubState", string.Empty);
            UnitFileState = _props.GetValueOrDefault("UnitFileState", string.Empty);
            Status = ActiveState switch
            {
                "active" or "reloading" => ServiceControllerStatus.Running,
                "activating" => ServiceControllerStatus.StartPending,
                "deactivating" => ServiceControllerStatus.StopPending,
                _ => ServiceControllerStatus.Stopped,
            };
            StartType = UnitFileState switch
            {
                "enabled" or "enabled-runtime" or "static" or "alias" or "indirect" or "generated" => ServiceStartMode.Automatic,
                "disabled" => ServiceStartMode.Manual,
                "masked" or "masked-runtime" => ServiceStartMode.Disabled,
                _ => ServiceStartMode.Manual,
            };
        }
        public void Start() => Systemctl("start", Unit);
        public void Stop() => Systemctl("stop", Unit);
        public void WaitForStatus(ServiceControllerStatus desiredStatus, TimeSpan timeout)
        {
            DateTime end = DateTime.UtcNow + timeout;
            while (true)
            {
                Refresh();
                if (Status == desiredStatus) { return; }
                if (DateTime.UtcNow > end) { throw new System.ServiceProcess.TimeoutException($"Timed out waiting for service [{ServiceName}] to reach status [{desiredStatus}]."); }
                System.Threading.Thread.Sleep(500);
            }
        }
        public override string ToString() => ServiceName;

        private SystemdService[] Related(params string[] keys)
        {
            return keys.SelectMany(k => _props.GetValueOrDefault(k, string.Empty).Split(' ', StringSplitOptions.RemoveEmptyEntries))
                .Where(static u => u.EndsWith(".service", StringComparison.Ordinal))
                .Distinct(StringComparer.Ordinal)
                .Select(static u => new SystemdService(u))
                .ToArray();
        }
        public static string Systemctl(params string[] arguments)
        {
            ProcessStartInfo psi = new("systemctl") { RedirectStandardOutput = true, RedirectStandardError = true, UseShellExecute = false };
            foreach (string a in arguments) { psi.ArgumentList.Add(a); }
            using Process p = Process.Start(psi) ?? throw new InvalidOperationException("Failed to start systemctl.");
            string stdout = p.StandardOutput.ReadToEnd();
            string stderr = p.StandardError.ReadToEnd();
            p.WaitForExit();
            if (p.ExitCode != 0 && arguments.Length > 0 && arguments[0] is not "show" and not "is-active" and not "is-enabled" and not "list-units" and not "list-unit-files")
            {
                throw new InvalidOperationException($"systemctl {string.Join(' ', arguments)} failed with exit code [{p.ExitCode}]: {stderr.Trim()}");
            }
            return stdout;
        }
        private static Dictionary<string, string> Show(string unit, string properties)
        {
            Dictionary<string, string> result = new(StringComparer.Ordinal);
            string output;
            try { output = Systemctl("show", unit, "--no-pager", $"--property={properties}"); }
            catch { return result; }
            foreach (string line in output.Split('\n'))
            {
                int idx = line.IndexOf('=', StringComparison.Ordinal);
                if (idx > 0) { result[line[..idx]] = line[(idx + 1)..].Trim(); }
            }
            return result;
        }
    }
}

namespace PSADT.AppManagement
{
    public sealed record class InstalledApplication
    {
        public InstalledApplication(string packageManager, string packageName, string displayName, string? displayVersion, string? publisher, string? architecture, DateTime? installDate, uint? estimatedSize, string? description, string? uninstallString)
        {
            PackageManager = packageManager;
            PackageName = packageName;
            DisplayName = displayName;
            DisplayVersion = displayVersion;
            Publisher = publisher;
            Architecture = architecture;
            InstallDate = installDate;
            EstimatedSize = estimatedSize;
            Description = description;
            UninstallString = uninstallString;
            QuietUninstallString = uninstallString;
            PSPath = $"{packageManager}::{packageName}";
            PSParentPath = packageManager;
            PSChildName = packageName;
            Is64BitApplication = architecture is null ? null : Regex.IsMatch(architecture, "64|all|noarch", RegexOptions.IgnoreCase);
        }
        public string PSPath { get; }
        public string PSParentPath { get; }
        public string PSChildName { get; }
        public Guid? ProductCode => null;
        public Guid? UpgradeCode => null;
        public string DisplayName { get; }
        public string? DisplayVersion { get; }
        public string? UninstallString { get; }
        public string? UninstallStringFilePath => null;
        public string? QuietUninstallString { get; }
        public string? QuietUninstallStringFilePath => null;
        public DateTime? InstallDate { get; }
        public string? Publisher { get; }
        public Uri? HelpLink => null;
        public uint? EstimatedSize { get; }
        public bool SystemComponent => false;
        public bool WindowsInstaller => false;
        public bool NoRemove => false;
        public bool? Is64BitApplication { get; }
        // Linux-specific extras.
        public string PackageManager { get; }
        public string PackageName { get; }
        public string? Architecture { get; }
        public string? Description { get; }
    }
}

namespace PSADT.DeviceManagement
{
    public enum PowerLineStatus
    {
        Offline = 0,
        Online = 1,
        Unknown = 255,
    }

    public sealed class BatteryInfo
    {
        public BatteryInfo(PowerLineStatus acPowerLineStatus, bool isBatteryPresent, bool isLaptop, double? batteryChargeLevel)
        {
            ACPowerLineStatus = acPowerLineStatus;
            IsBatteryPresent = isBatteryPresent;
            IsLaptop = isLaptop;
            IsUsingACPower = acPowerLineStatus != PowerLineStatus.Offline;
            BatteryChargeLevel = batteryChargeLevel;
        }
        public PowerLineStatus ACPowerLineStatus { get; }
        public bool IsBatteryPresent { get; }
        public bool IsLaptop { get; }
        public bool IsUsingACPower { get; }
        public double? BatteryChargeLevel { get; }
        public TimeSpan? BatteryLifeRemaining => null;
        public TimeSpan? BatteryFullLifetime => null;
    }

    public sealed record class RebootInfo
    {
        public RebootInfo(string computerName, DateTime lastBootUpTime, bool isSystemRebootPending, IReadOnlyList<string> pendingRebootPackages, string? pendingRebootReason)
        {
            ComputerName = computerName;
            LastBootUpTime = lastBootUpTime;
            IsSystemRebootPending = isSystemRebootPending;
            PendingRebootPackages = pendingRebootPackages;
            PendingRebootReason = pendingRebootReason;
        }
        public string ComputerName { get; }
        public DateTime LastBootUpTime { get; }
        public bool IsSystemRebootPending { get; }
        public bool IsCBServicingRebootPending => false;
        public bool IsWindowsUpdateRebootPending => false;
        public bool? IsSCCMClientRebootPending => null;
        public bool? IsIntuneClientRebootPending => null;
        public bool IsAppVRebootPending => false;
        public bool? IsFileRenameRebootPending => null;
        public IReadOnlyList<string> PendingFileRenameOperations => new ReadOnlyCollection<string>([]);
        public IReadOnlyList<string> ErrorMsg => new ReadOnlyCollection<string>([]);
        // Linux-specific extras.
        public IReadOnlyList<string> PendingRebootPackages { get; }
        public string? PendingRebootReason { get; }
    }

    public sealed record class OperatingSystemInfo
    {
        public OperatingSystemInfo(string name, string id, string? idLike, Version version, string? versionId, string? prettyName, string kernelVersion, string architecture, bool is64Bit)
        {
            Name = name; Id = id; IdLike = idLike; Version = version; VersionId = versionId; PrettyName = prettyName; KernelVersion = kernelVersion; Architecture = architecture; Is64BitOperatingSystem = is64Bit;
        }
        public string Name { get; }
        public string Id { get; }
        public string? IdLike { get; }
        public Version Version { get; }
        public string? VersionId { get; }
        public string? PrettyName { get; }
        public string KernelVersion { get; }
        public string Architecture { get; }
        public bool Is64BitOperatingSystem { get; }
        public string? Edition => Id;
        public string ProductTypeName => "Workstation";
        public override string ToString() => PrettyName ?? $"{Name} {Version}";
    }
}

namespace PSADT.FileSystem
{
    public sealed record class ExecutableInfo
    {
        public ExecutableInfo(PSADT.Interop.IMAGE_FILE_MACHINE machine, PSADT.Interop.IMAGE_SUBSYSTEM subsystem, bool isDotNetExecutable, uint entryPoint, ulong imageBase, string format)
        {
            Machine = machine; Subsystem = subsystem; IsDotNetExecutable = isDotNetExecutable; EntryPoint = entryPoint; ImageBase = imageBase; Format = format;
        }
        public PSADT.Interop.IMAGE_FILE_MACHINE Machine { get; }
        public PSADT.Interop.IMAGE_SUBSYSTEM Subsystem { get; }
        public bool IsDotNetExecutable { get; }
        public uint EntryPoint { get; }
        public ulong ImageBase { get; }
        /// <summary>Linux extra: "PE" or "ELF".</summary>
        public string Format { get; }

        /// <summary>Reads the header of a Windows PE or a Linux ELF executable.</summary>
        public static ExecutableInfo Get(string filePath)
        {
            ArgumentException.ThrowIfNullOrWhiteSpace(filePath);
            using FileStream fs = new(filePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite);
            using BinaryReader br = new(fs);
            if (fs.Length < 64) { throw new BadImageFormatException($"The file [{filePath}] is not a valid executable image.", filePath); }
            byte[] magic = br.ReadBytes(4);
            if (magic[0] == 0x7F && magic[1] == (byte)'E' && magic[2] == (byte)'L' && magic[3] == (byte)'F')
            {
                bool is64 = br.ReadByte() == 2;
                bool little = br.ReadByte() == 1;
                if (!little) { throw new BadImageFormatException("Big-endian ELF images are not supported.", filePath); }
                fs.Position = 0x12;
                ushort eMachine = br.ReadUInt16();
                fs.Position = 0x18;
                ulong entry = is64 ? br.ReadUInt64() : br.ReadUInt32();
                PSADT.Interop.IMAGE_FILE_MACHINE machine = eMachine switch
                {
                    3 => PSADT.Interop.IMAGE_FILE_MACHINE.IMAGE_FILE_MACHINE_I386,
                    40 => PSADT.Interop.IMAGE_FILE_MACHINE.IMAGE_FILE_MACHINE_ARMNT,
                    62 => PSADT.Interop.IMAGE_FILE_MACHINE.IMAGE_FILE_MACHINE_AMD64,
                    183 => PSADT.Interop.IMAGE_FILE_MACHINE.IMAGE_FILE_MACHINE_ARM64,
                    _ => PSADT.Interop.IMAGE_FILE_MACHINE.IMAGE_FILE_MACHINE_UNKNOWN,
                };
                return new ExecutableInfo(machine, PSADT.Interop.IMAGE_SUBSYSTEM.IMAGE_SUBSYSTEM_UNKNOWN, false, unchecked((uint)entry), 0, "ELF");
            }
            if (magic[0] != (byte)'M' || magic[1] != (byte)'Z') { throw new BadImageFormatException($"The file [{filePath}] is not a valid executable image.", filePath); }
            fs.Position = 0x3C;
            int peOffset = br.ReadInt32();
            fs.Position = peOffset;
            if (br.ReadUInt32() != 0x00004550) { throw new BadImageFormatException($"The file [{filePath}] is not a valid portable executable image.", filePath); }
            ushort peMachine = br.ReadUInt16();
            fs.Position = peOffset + 24;
            ushort optMagic = br.ReadUInt16();
            bool pe32Plus = optMagic == 0x20B;
            fs.Position = peOffset + 24 + 16;
            uint entryPoint = br.ReadUInt32();
            fs.Position = peOffset + 24 + (pe32Plus ? 24 : 28);
            ulong imageBase = pe32Plus ? br.ReadUInt64() : br.ReadUInt32();
            fs.Position = peOffset + 24 + 68;
            ushort subsystem = br.ReadUInt16();
            fs.Position = peOffset + 24 + (pe32Plus ? 112 : 96) + (14 * 8);
            uint clrRva = br.ReadUInt32();
            return new ExecutableInfo((PSADT.Interop.IMAGE_FILE_MACHINE)peMachine, (PSADT.Interop.IMAGE_SUBSYSTEM)subsystem, clrRva != 0, entryPoint, imageBase, "PE");
        }
    }
}

namespace PSADT.Interop
{
    public enum IMAGE_SUBSYSTEM : ushort
    {
        IMAGE_SUBSYSTEM_UNKNOWN = 0,
        IMAGE_SUBSYSTEM_NATIVE = 1,
        IMAGE_SUBSYSTEM_WINDOWS_GUI = 2,
        IMAGE_SUBSYSTEM_WINDOWS_CUI = 3,
        IMAGE_SUBSYSTEM_OS2_CUI = 5,
        IMAGE_SUBSYSTEM_POSIX_CUI = 7,
        IMAGE_SUBSYSTEM_NATIVE_WINDOWS = 8,
        IMAGE_SUBSYSTEM_WINDOWS_CE_GUI = 9,
        IMAGE_SUBSYSTEM_EFI_APPLICATION = 10,
        IMAGE_SUBSYSTEM_EFI_BOOT_SERVICE_DRIVER = 11,
        IMAGE_SUBSYSTEM_EFI_RUNTIME_DRIVER = 12,
        IMAGE_SUBSYSTEM_EFI_ROM = 13,
        IMAGE_SUBSYSTEM_XBOX = 14,
        IMAGE_SUBSYSTEM_WINDOWS_BOOT_APPLICATION = 16,
    }
}

namespace PSADT.WindowManagement
{
    public sealed record class WindowInfo
    {
        public WindowInfo(string windowTitle, nint windowHandle, string parentProcess, int parentProcessId)
        {
            WindowTitle = windowTitle; WindowHandle = windowHandle; ParentProcess = parentProcess; ParentProcessId = parentProcessId;
        }
        public string WindowTitle { get; }
        public nint WindowHandle { get; }
        public string ParentProcess { get; }
        public int ParentProcessId { get; }
    }
}

namespace PSADT.WindowsInstaller
{
    public sealed record class MsiSummaryInfo
    {
        public Encoding? CodePage { get; init; }
        public string? Title { get; init; }
        public string? Subject { get; init; }
        public string? Author { get; init; }
        public string? Keywords { get; init; }
        public string? Comments { get; init; }
        public string? Template { get; init; }
        public string? LastSavedBy { get; init; }
        public string? RevisionNumber { get; init; }
        public DateTime? LastPrinted { get; init; }
        public DateTime? CreateTimeDate { get; init; }
        public DateTime? LastSaveTimeDate { get; init; }
        public int? PageCount { get; init; }
        public int? WordCount { get; init; }
        public int? CharacterCount { get; init; }
        public string? CreatingApplication { get; init; }
        public int? Security { get; init; }
    }
}

namespace PSADT.ShortcutManagement
{
    public interface IShortcutLinkInfo
    {
        string Path { get; }
        string? TargetPath { get; }
        string? Arguments { get; }
        string? Description { get; }
        string? WorkingDirectory { get; }
        string? IconLocation { get; }
        int IconIndex { get; }
        ShortcutWindowStyle WindowStyle { get; }
        string? Hotkey { get; }
        bool RunAsAdmin { get; }
    }

    /// <summary>A freedesktop.org .desktop launcher, presented through the same interface as a Windows .lnk.</summary>
    public sealed record class DesktopEntryInfo : IShortcutLinkInfo
    {
        public string Path { get; init; } = string.Empty;
        public string? TargetPath { get; init; }
        public string? Arguments { get; init; }
        public string? Description { get; init; }
        public string? WorkingDirectory { get; init; }
        public string? IconLocation { get; init; }
        public int IconIndex { get; init; }
        public ShortcutWindowStyle WindowStyle { get; init; } = ShortcutWindowStyle.Normal;
        public string? Hotkey { get; init; }
        public bool RunAsAdmin { get; init; }
        public string? Name { get; init; }
        public string? Type { get; init; }
        public bool Terminal { get; init; }
        public string? Categories { get; init; }
    }
}

namespace PSADT.UserInterface.DialogResults
{
    public interface IDialogResult { }

    public sealed class CloseAppsDialogResult : IDialogResult, IEquatable<CloseAppsDialogResult>
    {
        private CloseAppsDialogResult(int value, string name) { Value = value; Name = name; }
        public static readonly CloseAppsDialogResult Timeout = new(0, nameof(Timeout));
        public static readonly CloseAppsDialogResult Close = new(1, nameof(Close));
        public static readonly CloseAppsDialogResult Continue = new(2, nameof(Continue));
        public static readonly CloseAppsDialogResult Defer = new(3, nameof(Defer));
        public int Value { get; }
        public string Name { get; }
        public override string ToString() => Name;
        public bool Equals(CloseAppsDialogResult? other) => other is not null && other.Value == Value;
        public override bool Equals(object? obj) => obj is string s ? string.Equals(s, Name, StringComparison.OrdinalIgnoreCase) : Equals(obj as CloseAppsDialogResult);
        public override int GetHashCode() => Value;
        public static implicit operator string(CloseAppsDialogResult r) => r.Name;
    }

    public sealed class DialogBoxResult : IDialogResult, IEquatable<DialogBoxResult>
    {
        private DialogBoxResult(int value, string name) { Value = value; Name = name; }
        public static readonly DialogBoxResult OK = new(1, nameof(OK));
        public static readonly DialogBoxResult Cancel = new(2, nameof(Cancel));
        public static readonly DialogBoxResult Abort = new(3, nameof(Abort));
        public static readonly DialogBoxResult Retry = new(4, nameof(Retry));
        public static readonly DialogBoxResult Ignore = new(5, nameof(Ignore));
        public static readonly DialogBoxResult Yes = new(6, nameof(Yes));
        public static readonly DialogBoxResult No = new(7, nameof(No));
        public static readonly DialogBoxResult Close = new(8, nameof(Close));
        public static readonly DialogBoxResult TryAgain = new(10, nameof(TryAgain));
        public static readonly DialogBoxResult Continue = new(11, nameof(Continue));
        public static readonly DialogBoxResult Timeout = new(32000, nameof(Timeout));
        public int Value { get; }
        public string Name { get; }
        public override string ToString() => Name;
        public bool Equals(DialogBoxResult? other) => other is not null && other.Value == Value;
        public override bool Equals(object? obj) => obj is string s ? string.Equals(s, Name, StringComparison.OrdinalIgnoreCase) : Equals(obj as DialogBoxResult);
        public override int GetHashCode() => Value;
        public static implicit operator string(DialogBoxResult r) => r.Name;
    }

    public class CustomDialogResult : IDialogResult
    {
        public static readonly CustomDialogResult DefaultResult = new("Timeout");
        public CustomDialogResult(string result) { Result = result; }
        public string Result { get; }
        public override string ToString() => Result;
        public override bool Equals(object? obj) => obj switch
        {
            string s => string.Equals(s, Result, StringComparison.Ordinal),
            CustomDialogResult c => string.Equals(c.Result, Result, StringComparison.Ordinal),
            _ => false,
        };
        public override int GetHashCode() => StringComparer.Ordinal.GetHashCode(Result);
        public static implicit operator string(CustomDialogResult r) => r.Result;
    }

    public sealed class InputDialogResult : CustomDialogResult
    {
        public static new readonly InputDialogResult DefaultResult = new("Timeout", null);
        public InputDialogResult(string result, string? text) : base(result) { Text = text; }
        public readonly string? Text;
    }

    public sealed class SecureInputDialogResult : CustomDialogResult
    {
        public static new readonly SecureInputDialogResult DefaultResult = new("Timeout", null);
        public SecureInputDialogResult(string result, System.Security.SecureString? text) : base(result) { Text = text; }
        public System.Security.SecureString? Text { get; }
    }

    public sealed class ListSelectionDialogResult : CustomDialogResult
    {
        public static new readonly ListSelectionDialogResult DefaultResult = new("Timeout", null);
        public ListSelectionDialogResult(string result, string? selectedItem) : base(result) { SelectedItem = selectedItem; }
        public readonly string? SelectedItem;
    }
}

namespace PSAppDeployToolkit.Foundation
{
    using PSADT.ProcessManagement;

    /// <summary>Case-insensitive dictionary of the toolkit's environment variables ($envOS, $IsAdmin, ...).</summary>
    public sealed class EnvironmentTable : Dictionary<string, object?>
    {
        public EnvironmentTable() : base(StringComparer.OrdinalIgnoreCase) { }
        public EnvironmentTable(IDictionary source) : this()
        {
            foreach (DictionaryEntry entry in source) { this[(string)entry.Key] = entry.Value; }
        }
    }

    public sealed record class RestartOnExitOptions
    {
        public RestartOnExitOptions(TimeSpan countdown, string? reason, bool noForceCloseApps)
        {
            Countdown = countdown; Reason = reason; NoForceCloseApps = noForceCloseApps;
        }
        public TimeSpan Countdown { get; }
        public string? Reason { get; }
        public bool NoForceCloseApps { get; }
    }

    /// <summary>Holds the module-wide state that the original keeps in its ModuleDatabase.</summary>
    public static class ModuleDatabase
    {
        public static IDictionary? Config { get; set; }
        public static IDictionary? DefaultConfig { get; set; }
        public static IDictionary? Strings { get; set; }
        public static EnvironmentTable? Environment { get; set; }
        public static ScriptBlock? HostWriter { get; set; }
        public static ScriptBlock? CallerResolver { get; set; }
        public static int? LastExitCode { get; set; }
        public static bool IsInitialized() => Config is not null;
        public static IDictionary GetConfig() => Config ?? throw new InvalidOperationException("The PSAppDeployToolkit module has not been initialized.");
        public static IDictionary GetDefaultConfig() => DefaultConfig ?? throw new InvalidOperationException("The default config has not been loaded.");
        public static T GetConfigValue<T>(string section, string key)
        {
            IDictionary config = Config ?? GetDefaultConfig();
            object? value = (config[section] as IDictionary)?[key];
            if (value is PSObject pso) { value = pso.BaseObject; }
            return value is null ? default! : (T)LanguagePrimitives.ConvertTo(value, typeof(T), CultureInfo.InvariantCulture);
        }
    }

    /// <summary>
    /// Linux implementation of the toolkit's deployment session object. Property names, method names and
    /// exit code semantics follow the original <c>PSAppDeployToolkit.Foundation.DeploymentSession</c>.
    /// </summary>
    public class DeploymentSession
    {
        private const string SubstitutionPlaceholder = "%%DISCRIMINATOR%%";

        public DeploymentSession(IDictionary values)
        {
            ArgumentNullException.ThrowIfNull(values);
            T? Get<T>(string key)
            {
                if (!values.Contains(key) || values[key] is null) { return default; }
                object v = values[key]!;
                if (v is PSObject p) { v = p.BaseObject; }
                return (T)LanguagePrimitives.ConvertTo(v, typeof(T), CultureInfo.InvariantCulture);
            }
            DeploymentType = Get<DeploymentType?>(nameof(DeploymentType)) ?? DeploymentType.Install;
            DeployMode = Get<DeployMode?>(nameof(DeployMode)) ?? DeployMode.Auto;
            RequestedDeployMode = Get<DeployMode?>(nameof(RequestedDeployMode)) ?? DeployMode;
            SuppressRebootPassThru = Get<bool>(nameof(SuppressRebootPassThru));
            TerminalServerMode = Get<bool>(nameof(TerminalServerMode));
            DisableLogging = Get<bool>(nameof(DisableLogging));
            RequireAdmin = Get<bool>(nameof(RequireAdmin));
            ExitWithMsiCodes = Get<bool>(nameof(ExitWithMsiCodes));
            AppVendor = Get<string>(nameof(AppVendor));
            AppName = Get<string>(nameof(AppName));
            AppVersion = Get<string>(nameof(AppVersion));
            AppArch = Get<string>(nameof(AppArch));
            AppLang = Get<string>(nameof(AppLang));
            AppRevision = Get<string>(nameof(AppRevision));
            AppSuccessExitCodes = new ReadOnlyCollection<int>(Get<int[]>(nameof(AppSuccessExitCodes)) ?? [0]);
            AppRebootExitCodes = new ReadOnlyCollection<int>(Get<int[]>(nameof(AppRebootExitCodes)) ?? [1641, 3010]);
            AppProcessesToClose = new ReadOnlyCollection<ProcessDefinition>(Get<ProcessDefinition[]>(nameof(AppProcessesToClose)) ?? []);
            AppScriptVersion = Get<Version>(nameof(AppScriptVersion));
            AppScriptDate = Get<DateTime?>(nameof(AppScriptDate));
            AppScriptAuthor = Get<string>(nameof(AppScriptAuthor));
            DeployAppScriptFriendlyName = Get<string>(nameof(DeployAppScriptFriendlyName));
            DeployAppScriptVersion = Get<Version>(nameof(DeployAppScriptVersion));
            DeployAppScriptSessionState = Get<SessionState>(nameof(DeployAppScriptSessionState));
            Dictionary<string, object> parameters = new(StringComparer.OrdinalIgnoreCase);
            if (values[nameof(DeployAppScriptParameters)] is object rawParams)
            {
                if (rawParams is PSObject pp) { rawParams = pp.BaseObject; }
                if (rawParams is IDictionary dict) { foreach (DictionaryEntry e in dict) { parameters[e.Key.ToString()!] = e.Value!; } }
                else if (rawParams is IEnumerable<KeyValuePair<string, object>> kvps) { foreach (var kv in kvps) { parameters[kv.Key] = kv.Value; } }
            }
            DeployAppScriptParameters = new ReadOnlyDictionary<string, object>(parameters);
            CurrentDateTime = Get<DateTime?>(nameof(CurrentDateTime)) ?? DateTime.Now;
            CurrentDate = CurrentDateTime.ToString("dd-MM-yyyy", CultureInfo.InvariantCulture);
            CurrentTime = CurrentDateTime.ToString("HH:mm:ss", CultureInfo.InvariantCulture);
            ScriptDirectory = new ReadOnlyCollection<DirectoryInfo>((Get<string[]>(nameof(ScriptDirectory)) ?? []).Select(d => new DirectoryInfo(d)).ToList());
            DirFiles = Get<string>(nameof(DirFiles)) is string df ? new DirectoryInfo(df) : null;
            DirSupportFiles = Get<string>(nameof(DirSupportFiles)) is string dsf ? new DirectoryInfo(dsf) : null;
            InstallTitle = Get<string>(nameof(InstallTitle)) ?? string.Empty;
            InstallName = Get<string>(nameof(InstallName)) ?? string.Empty;
            LogPath = new DirectoryInfo(Get<string>(nameof(LogPath)) ?? System.IO.Path.GetTempPath());
            LogName = Get<string>(nameof(LogName)) ?? string.Empty;
            DefaultLogName = Get<string>(nameof(DefaultLogName)) ?? LogName;
            LogStyle = Get<LogStyle?>(nameof(LogStyle)) ?? LogStyle.CMTrace;
            LogWriteToHost = Get<bool?>(nameof(LogWriteToHost)) ?? true;
            LogHostOutputToStdStreams = Get<bool>(nameof(LogHostOutputToStdStreams));
            CompressLogs = Get<bool>(nameof(CompressLogs));
            ConfigLogPath = new DirectoryInfo(Get<string>(nameof(ConfigLogPath)) ?? LogPath.FullName);
            LogMaxHistory = Get<int?>(nameof(LogMaxHistory)) ?? 10;
            DeferHistoryPath = Get<string>(nameof(DeferHistoryPath));
            NoExitOnClose = Get<bool>(nameof(NoExitOnClose));
            DefaultExitCode = Get<int?>(nameof(DefaultExitCode)) ?? 1618;
            DeferExitCode = Get<int?>(nameof(DeferExitCode)) ?? 1602;
            InstallPhase = "Initialization";
        }

        #region Public properties (same names as the original).
        public DeploymentType DeploymentType { get; }
        public DeployMode DeployMode { get; }
        public bool SuppressRebootPassThru { get; }
        public bool TerminalServerMode { get; }
        public bool DisableLogging { get; }
        public bool RequireAdmin { get; }
        public string? AppVendor { get; }
        public string? AppName { get; }
        public string? AppVersion { get; }
        public string? AppArch { get; }
        public string? AppLang { get; }
        public string? AppRevision { get; }
        public IReadOnlyList<int> AppSuccessExitCodes { get; }
        public IReadOnlyList<int> AppRebootExitCodes { get; }
        public IReadOnlyList<ProcessDefinition> AppProcessesToClose { get; }
        public Version? AppScriptVersion { get; }
        public DateTime? AppScriptDate { get; }
        public string? AppScriptAuthor { get; }
        public string? DeployAppScriptFriendlyName { get; }
        public Version? DeployAppScriptVersion { get; }
        public IReadOnlyDictionary<string, object> DeployAppScriptParameters { get; }
        public SessionState? DeployAppScriptSessionState { get; }
        public DateTime CurrentDateTime { get; }
        public string CurrentDate { get; }
        public string CurrentTime { get; }
        public TimeSpan CurrentTimeZoneBias { get; } = TimeZoneInfo.Local.BaseUtcOffset;
        public IReadOnlyList<DirectoryInfo> ScriptDirectory { get; }
        public DirectoryInfo? DirFiles { get; set; }
        public DirectoryInfo? DirSupportFiles { get; set; }
        public DirectoryInfo? DirWimMountPath => null;
        public string InstallTitle { get; }
        public string InstallName { get; }
        public DirectoryInfo LogPath { get; }
        public string LogName { get; }
        public FileInfo? DefaultMsiFile => null;
        public FileInfo? DefaultMstFile => null;
        public IReadOnlyList<FileInfo> DefaultMspFiles { get; } = new ReadOnlyCollection<FileInfo>([]);
        public bool UseDefaultMsi => false;
        public string InstallPhase { get; set; }
        #endregion

        #region Internal state.
        private int ExitCode;
        private bool Disposed;
        private readonly string DefaultLogName;
        private readonly DeployMode RequestedDeployMode;
        private readonly bool ExitWithMsiCodes;
        private readonly bool NoExitOnClose;
        private readonly bool LogWriteToHost;
        private readonly bool LogHostOutputToStdStreams;
        private readonly bool CompressLogs;
        private readonly DirectoryInfo ConfigLogPath;
        private readonly int LogMaxHistory;
        private readonly string? DeferHistoryPath;
        private readonly int DefaultExitCode;
        private readonly int DeferExitCode;
        private readonly List<LogEntry> LogBuffer = [];
        public LogStyle LogStyle { get; }
        #endregion

        #region Exit code handling (identical semantics to the original).
        public int GetExitCode() => ExitCode;
        public void SetExitCode(int exitCode) => ExitCode = exitCode;
        public bool TrySetExitCode(int exitCode) => TrySetExitCode(exitCode, GetDeploymentStatus(exitCode));
        public bool TrySetExitCode(int exitCode, IReadOnlyList<int> successExitCodes, IReadOnlyList<int> rebootExitCodes)
        {
            ArgumentNullException.ThrowIfNull(successExitCodes);
            ArgumentNullException.ThrowIfNull(rebootExitCodes);
            return TrySetExitCode(exitCode, rebootExitCodes.Contains(exitCode)
                ? DeploymentStatus.RestartRequired
                : successExitCodes.Contains(exitCode)
                ? DeploymentStatus.Complete
                : DeploymentStatus.Error);
        }
        private bool TrySetExitCode(int exitCode, DeploymentStatus exitCodeStatus)
        {
            if (GetDeploymentStatus() > exitCodeStatus)
            {
                return false;
            }
            SetExitCode(exitCode);
            return true;
        }
        public DeploymentStatus GetDeploymentStatus() => GetDeploymentStatus(ExitCode);
        private DeploymentStatus GetDeploymentStatus(int exitCode)
        {
            return (exitCode == DefaultExitCode) || (exitCode == DeferExitCode)
                ? DeploymentStatus.FastRetry
                : AppRebootExitCodes.Contains(exitCode)
                ? DeploymentStatus.RestartRequired
                : AppSuccessExitCodes.Contains(exitCode)
                ? DeploymentStatus.Complete
                : DeploymentStatus.Error;
        }
        public bool IsClosed() => Disposed;
        public bool CanExitOnClose() => !NoExitOnClose;
        public bool IsNonInteractive() => DeployMode is DeployMode.NonInteractive or DeployMode.Silent;
        public bool IsSilent() => DeployMode is DeployMode.Silent;
        #endregion

        public int Close(string? exitMessage = null)
        {
            if (Disposed)
            {
                throw new ObjectDisposedException(nameof(DeploymentSession), "This object has already been disposed.");
            }
            DeploymentStatus deploymentStatus = GetDeploymentStatus();
            bool restartPassThru = deploymentStatus is DeploymentStatus.RestartRequired && !SuppressRebootPassThru;
            if (deploymentStatus is not DeploymentStatus.FastRetry and not DeploymentStatus.Error)
            {
                if (!restartPassThru)
                {
                    ExitCode = 0;
                }
                else if (ExitWithMsiCodes)
                {
                    ExitCode = 3010;
                }
            }
            string toolkitName = "PSAppDeployToolkit";
            string deployString = string.Create(CultureInfo.InvariantCulture, $"{(!string.IsNullOrWhiteSpace(InstallName) ? $"[{InstallName}] {DeploymentType.ToString().ToLowerInvariant()}" : $"{toolkitName} deployment")} {SubstitutionPlaceholder} in [{(DateTime.Now - CurrentDateTime).TotalSeconds}] seconds with exit code [{ExitCode}]{(!string.IsNullOrWhiteSpace(exitMessage) ? $": {exitMessage!.TrimEnd('.')}" : null)}.");
            switch (deploymentStatus)
            {
                case DeploymentStatus.FastRetry:
                    WriteLogEntry(deployString.Replace(SubstitutionPlaceholder, "was deferred", StringComparison.Ordinal), LogSeverity.Warning);
                    break;
                case DeploymentStatus.Error:
                    WriteLogEntry(deployString.Replace(SubstitutionPlaceholder, "failed", StringComparison.Ordinal), LogSeverity.Error);
                    break;
                default:
                    WriteLogEntry(deployString.Replace(SubstitutionPlaceholder, "completed", StringComparison.Ordinal), LogSeverity.Success);
                    if (restartPassThru)
                    {
                        WriteLogEntry("A restart has been flagged as required.", LogSeverity.Warning);
                    }
                    ResetDeferHistory();
                    break;
            }
            if (ModuleDatabase.LastExitCode is null || ExitCode is not 0)
            {
                ModuleDatabase.LastExitCode = ExitCode;
            }
            WriteLogEntry(LogUtilities.LogDivider);
            Disposed = true;
            if (CompressLogs && !DisableLogging)
            {
                string destArchiveFileName = $"{InstallName}_{DeploymentType}_{SubstitutionPlaceholder}.zip";
                DirectoryInfo destArchiveFilePath = Directory.CreateDirectory(ConfigLogPath.FullName);
                try
                {
                    FileInfo[] archiveFiles = [.. destArchiveFilePath.GetFiles(destArchiveFileName.Replace(SubstitutionPlaceholder, "*", StringComparison.Ordinal)).OrderBy(static f => f.LastWriteTime)];
                    destArchiveFileName = destArchiveFileName.Replace(SubstitutionPlaceholder, CurrentDateTime.ToString("O", CultureInfo.InvariantCulture).Split('.')[0].Replace(":", null, StringComparison.Ordinal), StringComparison.Ordinal);
                    int count = archiveFiles.Length + 1;
                    if (count > LogMaxHistory)
                    {
                        foreach (FileInfo file in archiveFiles.Take(count - LogMaxHistory)) { file.Delete(); }
                    }
                    System.IO.Compression.ZipFile.CreateFromDirectory(LogPath.FullName, System.IO.Path.Join(destArchiveFilePath.FullName, destArchiveFileName), System.IO.Compression.CompressionLevel.Optimal, includeBaseDirectory: false);
                    LogPath.Delete(recursive: true);
                }
                catch (Exception ex)
                {
                    WriteLogEntry($"Failed to manage archive file [{destArchiveFileName}]: {ex}", LogSeverity.Error);
                }
            }
            return ModuleDatabase.LastExitCode ?? ExitCode;
        }

        #region Logging.
        public IReadOnlyList<LogEntry> WriteLogEntry(IReadOnlyList<string> message, bool debugMessage, LogSeverity? severity = null, string? source = null, string? scriptSection = null, string? logFileDirectory = null, string? logFileName = null, LogStyle? logStyle = null, HostLogStreamType? hostLogStreamType = null)
        {
            IReadOnlyList<LogEntry> entries = LogUtilities.WriteLogEntry(message, hostLogStreamType ?? GetHostLogStreamTypeMode(), debugMessage, severity, source, scriptSection ?? InstallPhase, logFileDirectory ?? (!DisableLogging ? LogPath.FullName : null), logFileName ?? (!DisableLogging ? LogName : null), logStyle ?? LogStyle);
            LogBuffer.AddRange(entries);
            return entries;
        }
        public void WriteLogEntry(IReadOnlyList<string> message) => WriteLogEntry(message, false);
        public void WriteLogEntry(IReadOnlyList<string> message, LogSeverity severity) => WriteLogEntry(message, false, severity);
        public void WriteLogEntry(string message) => WriteLogEntry([message], false);
        public void WriteLogEntry(string message, LogSeverity severity) => WriteLogEntry([message], false, severity);
        public void WriteLogEntry(string message, LogSeverity severity, string source) => WriteLogEntry([message], false, severity, source);
        public void WriteLogEntry(string message, bool writeHost) => WriteLogEntry([message], false, null, null, null, null, null, null, writeHost ? GetHostLogStreamTypeMode() : HostLogStreamType.None);
        public IReadOnlyList<LogEntry> GetLogBuffer() => LogBuffer.AsReadOnly();
        private HostLogStreamType GetHostLogStreamTypeMode()
        {
            return !LogWriteToHost ? HostLogStreamType.None : LogHostOutputToStdStreams ? HostLogStreamType.Console : HostLogStreamType.Host;
        }
        public string NewLogFileName(string discriminator, bool fileNameOnly)
        {
            string logFileName = DefaultLogName.Replace(SubstitutionPlaceholder, discriminator, StringComparison.Ordinal);
            return fileNameOnly ? logFileName : System.IO.Path.Join(LogPath.FullName, logFileName);
        }
        #endregion

        #region Deferral history (JSON file instead of the registry).
        private string? DeferHistoryFile => DeferHistoryPath is null || string.IsNullOrWhiteSpace(InstallName) ? null : System.IO.Path.Join(DeferHistoryPath, $"{InstallName}.json");
        public DeferHistory? GetDeferHistory()
        {
            if (DeferHistoryFile is not string file || !File.Exists(file))
            {
                return null;
            }
            WriteLogEntry("Getting deferral history...");
            using JsonDocument doc = JsonDocument.Parse(File.ReadAllText(file));
            JsonElement root = doc.RootElement;
            uint? times = root.TryGetProperty("DeferTimesRemaining", out JsonElement t) && t.ValueKind is JsonValueKind.Number ? t.GetUInt32() : null;
            DateTime? deadline = root.TryGetProperty("DeferDeadline", out JsonElement d) && d.ValueKind is JsonValueKind.String ? DateTime.Parse(d.GetString()!, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind) : null;
            DateTime? last = root.TryGetProperty("DeferRunIntervalLastTime", out JsonElement l) && l.ValueKind is JsonValueKind.String ? DateTime.Parse(l.GetString()!, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind) : null;
            TimeSpan? interval = root.TryGetProperty("DeferRunInterval", out JsonElement i) && i.ValueKind is JsonValueKind.String ? TimeSpan.Parse(i.GetString()!, CultureInfo.InvariantCulture) : null;
            return times is null && deadline is null && last is null ? null : new DeferHistory(times, deadline, last, interval);
        }
        public void SetDeferHistory(uint? deferTimesRemaining, DateTime? deferDeadline, TimeSpan? deferRunInterval, DateTime? deferRunIntervalLastTime)
        {
            if (DeferHistoryFile is not string file)
            {
                return;
            }
            Dictionary<string, object?> data = [];
            DeferHistory? existing = null;
            try { existing = GetDeferHistory(); } catch { }
            uint? times = deferTimesRemaining ?? existing?.DeferTimesRemaining;
            DateTime? deadline = deferDeadline ?? existing?.DeferDeadline;
            TimeSpan? interval = deferRunInterval ?? existing?.DeferRunInterval;
            DateTime? last = deferRunIntervalLastTime ?? existing?.DeferRunIntervalLastTime;
            if (deferTimesRemaining is not null) { WriteLogEntry($"Setting deferral history: [DeferTimesRemaining = {deferTimesRemaining}]."); }
            if (deferDeadline is not null) { WriteLogEntry($"Setting deferral history: [DeferDeadline = {deferDeadline.Value.ToString("O", CultureInfo.InvariantCulture)}]."); }
            if (deferRunInterval is not null) { WriteLogEntry($"Setting deferral history: [DeferRunInterval = {deferRunInterval}]."); }
            if (deferRunIntervalLastTime is not null) { WriteLogEntry($"Setting deferral history: [DeferRunIntervalLastTime = {deferRunIntervalLastTime.Value.ToString("O", CultureInfo.InvariantCulture)}]."); }
            data["DeferTimesRemaining"] = times;
            data["DeferDeadline"] = deadline?.ToString("O", CultureInfo.InvariantCulture);
            data["DeferRunInterval"] = interval?.ToString("c", CultureInfo.InvariantCulture);
            data["DeferRunIntervalLastTime"] = last?.ToString("O", CultureInfo.InvariantCulture);
            Directory.CreateDirectory(DeferHistoryPath!);
            File.WriteAllText(file, JsonSerializer.Serialize(data, new JsonSerializerOptions { WriteIndented = true }));
        }
        public void ResetDeferHistory()
        {
            if (DeferHistoryFile is string file && File.Exists(file))
            {
                WriteLogEntry("Removing deferral history...");
                File.Delete(file);
            }
        }
        #endregion

        public void AddMountedWimFile(FileInfo wimFile) => throw new PlatformNotSupportedException("WIM files are not supported on Linux.");
    }
}

namespace PSAppDeployToolkit.Logging
{
    using PSAppDeployToolkit.Foundation;

    public static class LogUtilities
    {
        public static IReadOnlyList<LogEntry> WriteLogEntry(IReadOnlyList<string> message, HostLogStreamType hostLogStreamType, bool debugMessage, LogSeverity? severity = null, string? source = null, string? scriptSection = null, string? logFileDirectory = null, string? logFileName = null, LogStyle? logStyle = null)
        {
            if (source is not null) { ArgumentException.ThrowIfNullOrWhiteSpace(source); }
            if (scriptSection is not null) { ArgumentException.ThrowIfNullOrWhiteSpace(scriptSection); }
            DateTime dateNow = DateTime.Now;
            bool canLogToDisk = !string.IsNullOrWhiteSpace(logFileDirectory) && !string.IsNullOrWhiteSpace(logFileName);
            IDictionary configToolkit = (ModuleDatabase.Config ?? ModuleDatabase.DefaultConfig)?["Toolkit"] as IDictionary ?? new Hashtable { { "LogDebugMessage", false }, { "LogStyle", "CMTrace" } };
            if (debugMessage && !LanguagePrimitives.IsTrue(configToolkit["LogDebugMessage"]))
            {
                return new ReadOnlyCollection<LogEntry>([]);
            }

            // Determine the caller via PowerShell's call stack (delegated to the module).
            string callerFileName = "<Unavailable>", callerSource = "<Unavailable>";
            try
            {
                if (ModuleDatabase.CallerResolver is ScriptBlock resolver && resolver.Invoke() is { Count: > 0 } r && r[0]?.BaseObject is object[] pair && pair.Length == 2)
                {
                    callerFileName = pair[0]?.ToString() is { Length: > 0 } f ? f : callerFileName;
                    callerSource = pair[1]?.ToString() is { Length: > 0 } s ? s : callerSource;
                }
            }
            catch { }
            if (source is null || string.IsNullOrWhiteSpace(source))
            {
                source = callerSource;
            }
            if (canLogToDisk && !Directory.Exists(logFileDirectory))
            {
                Directory.CreateDirectory(logFileDirectory!);
            }
            logStyle ??= Enum.Parse<LogStyle>(configToolkit["LogStyle"]?.ToString() ?? "CMTrace", ignoreCase: true);
            severity ??= LogSeverity.Info;
            ReadOnlyCollection<LogEntry> logEntries = new([.. message.Where(static m => !string.IsNullOrWhiteSpace(m)).Select(m => new LogEntry(dateNow, m, severity.Value, source, scriptSection, debugMessage, callerFileName, callerSource))]);
            if (logEntries.Count is 0)
            {
                throw new InvalidOperationException("No valid log messages were provided to log.");
            }
            if (canLogToDisk)
            {
                lock (FileLock)
                {
                    using StreamWriter writer = new(Path.Join(logFileDirectory, logFileName), append: true, LogEncoding);
                    foreach (LogEntry entry in logEntries)
                    {
                        writer.WriteLine(logStyle.Value is LogStyle.CMTrace ? entry.CMTraceLogLine : entry.LegacyLogLine);
                    }
                }
            }
            if (hostLogStreamType is not HostLogStreamType.None)
            {
                if (hostLogStreamType is HostLogStreamType.Console || ModuleDatabase.HostWriter is null)
                {
                    bool coloured = severity is not LogSeverity.Info;
                    if (coloured)
                    {
                        Console.ForegroundColor = severity switch { LogSeverity.Success => ConsoleColor.Green, LogSeverity.Warning => ConsoleColor.Yellow, _ => ConsoleColor.Red };
                    }
                    TextWriter stream = severity is LogSeverity.Error ? Console.Error : Console.Out;
                    foreach (LogEntry entry in logEntries) { stream.WriteLine(entry.LegacyLogLine); }
                    if (coloured) { Console.ResetColor(); }
                }
                else
                {
                    string[] lines = (hostLogStreamType == HostLogStreamType.Verbose) ? [.. logEntries.Select(static e => e.Message)] : [.. logEntries.Select(static e => e.LegacyLogLine)];
                    ModuleDatabase.HostWriter.Invoke(lines, (int)severity.Value, (int)hostLogStreamType);
                }
            }
            return logEntries;
        }

        public static readonly Regex LogFileNameRegex = new(@"\.(log|logx|txt|out)$", RegexOptions.Compiled | RegexOptions.ExplicitCapture | RegexOptions.IgnoreCase);
        internal static readonly UTF8Encoding LogEncoding = new(encoderShouldEmitUTF8Identifier: false, throwOnInvalidBytes: false);
        internal const string LogDivider = "-------------------------------------------------------------------------------";
        private static readonly object FileLock = new();
    }
}

namespace PSADT.Utilities
{
    public static class MiscUtilities
    {
        public static IReadOnlyList<string> TrimLeadingTrailingLines(IReadOnlyList<string>? lines)
        {
            if (lines is null || lines.Count == 0) { return new ReadOnlyCollection<string>([]); }
            int start = 0, end = lines.Count - 1;
            while (start <= end && string.IsNullOrWhiteSpace(lines[start])) { start++; }
            while (end >= start && string.IsNullOrWhiteSpace(lines[end])) { end--; }
            return lines.Skip(start).Take(end - start + 1).ToList().AsReadOnly();
        }
    }

    public static class EnvironmentUtilities
    {
        public static string? GetEnvironmentVariable(string variable) => Environment.GetEnvironmentVariable(variable);
        public static void SetEnvironmentVariable(string variable, object? value) => Environment.SetEnvironmentVariable(variable, value?.ToString());
        public static void RemoveEnvironmentVariable(string variable) => Environment.SetEnvironmentVariable(variable, null);
    }
}

namespace PSADT.Interop.Utilities
{
    public static class ExceptionUtilities
    {
        public static string CollapseInnerExceptionTraceMarkers(object? exception)
        {
            string text = exception?.ToString() ?? string.Empty;
            return Regex.Replace(text, @"(\s*--- End of inner exception stack trace ---)+", Environment.NewLine + "   --- End of inner exception stack trace ---");
        }
    }
}
