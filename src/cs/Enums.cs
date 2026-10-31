#nullable enable
namespace PSADT.Interop {
public enum IMAGE_FILE_MACHINE : ushort
    {
        IMAGE_FILE_MACHINE_UNKNOWN = 0,
        IMAGE_FILE_MACHINE_TARGET_HOST = 1,
        IMAGE_FILE_MACHINE_I386 = 332,
        IMAGE_FILE_MACHINE_R3000 = 354,
        IMAGE_FILE_MACHINE_R4000 = 358,
        IMAGE_FILE_MACHINE_R10000 = 360,
        IMAGE_FILE_MACHINE_WCEMIPSV2 = 361,
        IMAGE_FILE_MACHINE_ALPHA = 388,
        IMAGE_FILE_MACHINE_SH3 = 418,
        IMAGE_FILE_MACHINE_SH3DSP = 419,
        IMAGE_FILE_MACHINE_SH3E = 420,
        IMAGE_FILE_MACHINE_SH4 = 422,
        IMAGE_FILE_MACHINE_SH5 = 424,
        IMAGE_FILE_MACHINE_ARM = 448,
        IMAGE_FILE_MACHINE_THUMB = 450,
        IMAGE_FILE_MACHINE_ARMNT = 452,
        IMAGE_FILE_MACHINE_AM33 = 467,
        IMAGE_FILE_MACHINE_POWERPC = 496,
        IMAGE_FILE_MACHINE_POWERPCFP = 497,
        IMAGE_FILE_MACHINE_IA64 = 512,
        IMAGE_FILE_MACHINE_MIPS16 = 614,
        IMAGE_FILE_MACHINE_AXP64 = 644,
        IMAGE_FILE_MACHINE_ALPHA64 = 644,
        IMAGE_FILE_MACHINE_MIPSFPU = 870,
        IMAGE_FILE_MACHINE_MIPSFPU16 = 1126,
        IMAGE_FILE_MACHINE_TRICORE = 1312,
        IMAGE_FILE_MACHINE_CEF = 3311,
        IMAGE_FILE_MACHINE_EBC = 3772,
        IMAGE_FILE_MACHINE_AMD64 = 34404,
        IMAGE_FILE_MACHINE_M32R = 36929,
        IMAGE_FILE_MACHINE_ARM64 = 43620,
        IMAGE_FILE_MACHINE_CEE = 49390,
    }
public enum QUERY_USER_NOTIFICATION_STATE
    {
        QUNS_NOT_PRESENT = 1,
        QUNS_BUSY = 2,
        QUNS_RUNNING_D3D_FULL_SCREEN = 3,
        QUNS_PRESENTATION_MODE = 4,
        QUNS_ACCEPTS_NOTIFICATIONS = 5,
        QUNS_QUIET_TIME = 6,
        QUNS_APP = 7,
    }
}
namespace PSADT.ShortcutManagement {
public enum ShortcutWindowStyle
    {
        Hidden = 0,
        Normal = 1,
        Minimized = 2,
        Maximized = 3,
        NormalNoActivate = 4,
        NormalNoRestore = 5,
        MinimizedActivateRecent = 6,
        MinimizedNoActivate = 7,
        NormalNoRestoreNoActivate = 8,
        Restore = 9,
        ProcessDefault = 10,
        ForceMinimized = 11,
    }
}
namespace PSADT.UserInterface {
public enum BalloonTipIcon
    {
        None = 0,
        Info = 1,
        Warning = 2,
        Error = 3,
    }
public enum DialogBoxButtons : uint
    {
        Ok = 0,
        OkCancel = 1,
        AbortRetryIgnore = 2,
        YesNoCancel = 3,
        YesNo = 4,
        RetryCancel = 5,
        CancelTryContinue = 6,
    }
public enum DialogBoxDefaultButton : uint
    {
        First = 0,
        Second = 256,
        Third = 512,
    }
public enum DialogBoxIcon : uint
    {
        Stop = 16,
        Question = 32,
        Exclamation = 48,
        Information = 64,
    }
public enum DialogDefaultButton
    {
        None = 0,
        Left = 1,
        Middle = 2,
        Right = 3,
    }
public enum DialogMessageAlignment
    {
        Left = 0,
        Center = 1,
        Right = 2,
    }
public enum DialogPosition
    {
        Default = 0,
        TopLeft = 1,
        Top = 2,
        TopRight = 3,
        TopCenter = 4,
        Center = 5,
        BottomLeft = 6,
        Bottom = 7,
        BottomRight = 8,
        BottomCenter = 9,
        Oobe = 10,
    }
public enum DialogSystemIcon
    {
        Application = 0,
        Asterisk = 1,
        Error = 2,
        Exclamation = 3,
        Hand = 4,
        Information = 5,
        Question = 6,
        Shield = 7,
        Warning = 8,
        WinLogo = 9,
    }
}
namespace PSADT.ConfigMgr {
public enum TriggerScheduleId : ushort
    {
        HardwareInventory = (0x0 << 8) | (0x01 << 0),
        SoftwareInventory = (0x0 << 8) | (0x02 << 0),
        HeartbeatDiscovery = (0x0 << 8) | (0x03 << 0),
        SoftwareInventoryFileCollection = (0x0 << 8) | (0x10 << 0),
        IDMIFCollection = (0x0 << 8) | (0x11 << 0),
        ClientMachineAuthentication = (0x0 << 8) | (0x12 << 0),
        RequestMachinePolicy = (0x0 << 8) | (0x21 << 0),
        EvaluateMachinePolicy = (0x0 << 8) | (0x22 << 0),
        RefreshDefaultMp = (0x0 << 8) | (0x23 << 0),
        RefreshLocationServices = (0x0 << 8) | (0x24 << 0),
        LocationServicesCleanup = (0x0 << 8) | (0x25 << 0),
        PolicyAgentRequestAssignment = (0x0 << 8) | (0x26 << 0),
        PolicyAgentEvaluateAssignment = (0x0 << 8) | (0x27 << 0),
        SoftwareMeteringReport = (0x0 << 8) | (0x31 << 0),
        SourceUpdate = (0x0 << 8) | (0x32 << 0),
        ClearProxySettingsCache = (0x0 << 8) | (0x37 << 0),
        PolicyAgentCleanup = (0x0 << 8) | (0x40 << 0),
        UserPolicyAgentCleanup = (0x0 << 8) | (0x41 << 0),
        PolicyAgentValidateMachinePolicy = (0x0 << 8) | (0x42 << 0),
        PolicyAgentValidateUserPolicy = (0x0 << 8) | (0x43 << 0),
        CertificateMaintenance = (0x0 << 8) | (0x51 << 0),
        PeerDistributionPointStatus = (0x0 << 8) | (0x61 << 0),
        PeerDistributionPointProvisioning = (0x0 << 8) | (0x62 << 0),
        SUMUpdatesInstallSchedule = (0x0 << 8) | (0x63 << 0),
        HardwareInventoryCollectionCycle = (0x1 << 8) | (0x01 << 0),
        SoftwareInventoryCollectionCycle = (0x1 << 8) | (0x02 << 0),
        DiscoveryDataCollectionCycle = (0x1 << 8) | (0x03 << 0),
        FileCollectionCycle = (0x1 << 8) | (0x04 << 0),
        IDMIFCollectionCycle = (0x1 << 8) | (0x05 << 0),
        SoftwareMeteringUsageReportCycle = (0x1 << 8) | (0x06 << 0),
        WindowsInstallerSourceListUpdateCycle = (0x1 << 8) | (0x07 << 0),
        SoftwareUpdatesAgentAssignmentEvaluation = (0x1 << 8) | (0x08 << 0),
        BranchDistributionPointMaintenanceTask = (0x1 << 8) | (0x09 << 0),
        UploadStateMessage = (0x1 << 8) | (0x11 << 0),
        StateMessageManager = (0x1 << 8) | (0x12 << 0),
        SoftwareUpdatesScan = (0x1 << 8) | (0x13 << 0),
        UpdateStorePolicy = (0x1 << 8) | (0x14 << 0),
        StateSystemPolicyBulkSendHigh = (0x1 << 8) | (0x15 << 0),
        StateSystemPolicyBulkSendLow = (0x1 << 8) | (0x16 << 0),
        ApplicationManagerPolicyAction = (0x1 << 8) | (0x21 << 0),
        ApplicationManagerUserPolicyAction = (0x1 << 8) | (0x22 << 0),
        ApplicationManagerGlobalEvaluationAction = (0x1 << 8) | (0x23 << 0),
        PowerManagementStartSummarizer = (0x1 << 8) | (0x31 << 0),
        EndpointDeploymentReevaluate = (0x2 << 8) | (0x21 << 0),
        EndpointAMPolicyReevaluate = (0x2 << 8) | (0x22 << 0),
        ExternalEventDetection = (0x2 << 8) | (0x23 << 0),
    }
}
namespace PSAppDeployToolkit.Foundation {
public enum CallbackType
    {
        OnInit = 0,
        OnStart = 1,
        PreOpen = 2,
        PostOpen = 3,
        OnLogEntry = 4,
        OnDefer = 5,
        PreClose = 6,
        PostClose = 7,
        OnFinish = 8,
        OnExit = 9,
    }
public enum DeployMode
    {
        Auto = 0,
        Interactive = 1,
        NonInteractive = 2,
        Silent = 3,
    }
public enum DeploymentType
    {
        Install = 0,
        Uninstall = 1,
        Repair = 2,
    }
public enum DeploymentStatus
    {
        Complete = 0,
        RestartRequired = 1,
        FastRetry = 2,
        Error = 3,
    }
}
namespace PSAppDeployToolkit.Logging {
public enum HostLogStreamType
    {
        None = 0,
        Host = 1,
        Console = 2,
        Verbose = 3,
    }
public enum LogSeverity
    {
        Success = 0,
        Info = 1,
        Warning = 2,
        Error = 3,
    }
public enum LogStyle
    {
        Legacy = 0,
        CMTrace = 1,
    }
}
namespace PSADT.Utilities {
public static class ValueTypeConverter { 
        public static sbyte ToSByte(long val) => unchecked((sbyte)val);
        public static byte ToByte(long val) => unchecked((byte)val);
        public static short ToShort(long val) => unchecked((short)val);
        public static ushort ToUShort(long val) => unchecked((ushort)val);
        public static int ToInt(long val) => unchecked((int)val);
        public static uint ToUInt(long val) => unchecked((uint)val);
        public static ulong ToULong(long val) => unchecked((ulong)val);
        public static short ToInt16(long val) => unchecked((short)val);
        public static ushort ToUInt16(long val) => unchecked((ushort)val);
        public static int ToInt32(long val) => unchecked((int)val);
        public static uint ToUInt32(long val) => unchecked((uint)val);
        public static ulong ToUInt64(long val) => unchecked((ulong)val);
public enum ValueTypes
        {
            SByte = 0,
            Byte = 1,
            Short = 2,
            Int16 = 3,
            UShort = 4,
            UInt16 = 5,
            Int = 6,
            Int32 = 7,
            UInt = 8,
            UInt32 = 9,
            ULong = 10,
            UInt64 = 11,
        } }
}
