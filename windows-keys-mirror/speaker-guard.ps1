param(
    [ValidateSet('watch', 'status', 'mute')][string]$Mode = 'watch',
    [string]$Speaker = 'Realtek'
)

# Mutes the laptop speaker when the default output (headphones) disconnects, so audio that was
# playing in the headphones does not come out of the speaker. Started hidden by watchers.ahk
# with -MTA: the endpoint callbacks arrive on COM worker threads.
# Modes: watch (default, runs forever) | status (list outputs, change nothing) | mute (mute the speaker now).
# The laptop speaker is the speakers-type output whose friendly name matches -Speaker (regex).
# Monitor speakers (display audio) are never touched.

$src = @'
using System;
using System.IO;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;

namespace SpeakerGuard
{
    [StructLayout(LayoutKind.Sequential)]
    public struct PROPERTYKEY { public Guid fmtid; public uint pid; }

    [StructLayout(LayoutKind.Sequential)]
    public struct PROPVARIANT { public ushort vt; public ushort r1; public ushort r2; public ushort r3; public IntPtr p; public IntPtr p2; }

    [ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")]
    public class MMDeviceEnumeratorCom { }

    [ComImport, Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IMMDeviceEnumerator
    {
        [PreserveSig] int EnumAudioEndpoints(int dataFlow, int stateMask, out IMMDeviceCollection devices);
        [PreserveSig] int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice device);
        [PreserveSig] int GetDevice([MarshalAs(UnmanagedType.LPWStr)] string id, out IMMDevice device);
        [PreserveSig] int RegisterEndpointNotificationCallback(IMMNotificationClient client);
        [PreserveSig] int UnregisterEndpointNotificationCallback(IMMNotificationClient client);
    }

    [ComImport, Guid("0BD7A1BE-7A1A-44DB-8397-CC5392387B5E"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IMMDeviceCollection
    {
        [PreserveSig] int GetCount(out int count);
        [PreserveSig] int Item(int index, out IMMDevice device);
    }

    [ComImport, Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IMMDevice
    {
        [PreserveSig] int Activate(ref Guid iid, int clsCtx, IntPtr activationParams, [MarshalAs(UnmanagedType.IUnknown)] out object iface);
        [PreserveSig] int OpenPropertyStore(int access, out IPropertyStore props);
        [PreserveSig] int GetId([MarshalAs(UnmanagedType.LPWStr)] out string id);
        [PreserveSig] int GetState(out int state);
    }

    [ComImport, Guid("886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IPropertyStore
    {
        [PreserveSig] int GetCount(out uint count);
        [PreserveSig] int GetAt(uint index, out PROPERTYKEY key);
        [PreserveSig] int GetValue(ref PROPERTYKEY key, out PROPVARIANT value);
        [PreserveSig] int SetValue(ref PROPERTYKEY key, ref PROPVARIANT value);
        [PreserveSig] int Commit();
    }

    [ComImport, Guid("5CDF2C82-841E-4546-9722-0CF74078229A"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IAudioEndpointVolume
    {
        [PreserveSig] int RegisterControlChangeNotify(IntPtr notify);
        [PreserveSig] int UnregisterControlChangeNotify(IntPtr notify);
        [PreserveSig] int GetChannelCount(out uint count);
        [PreserveSig] int SetMasterVolumeLevel(float level, ref Guid context);
        [PreserveSig] int SetMasterVolumeLevelScalar(float level, ref Guid context);
        [PreserveSig] int GetMasterVolumeLevel(out float level);
        [PreserveSig] int GetMasterVolumeLevelScalar(out float level);
        [PreserveSig] int SetChannelVolumeLevel(uint channel, float level, ref Guid context);
        [PreserveSig] int SetChannelVolumeLevelScalar(uint channel, float level, ref Guid context);
        [PreserveSig] int GetChannelVolumeLevel(uint channel, out float level);
        [PreserveSig] int GetChannelVolumeLevelScalar(uint channel, out float level);
        [PreserveSig] int SetMute([MarshalAs(UnmanagedType.Bool)] bool mute, ref Guid context);
        [PreserveSig] int GetMute([MarshalAs(UnmanagedType.Bool)] out bool mute);
    }

    [ComImport, Guid("7991EEC9-7E89-4D85-8390-6C703CEC60C0"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IMMNotificationClient
    {
        [PreserveSig] int OnDeviceStateChanged([MarshalAs(UnmanagedType.LPWStr)] string deviceId, int newState);
        [PreserveSig] int OnDeviceAdded([MarshalAs(UnmanagedType.LPWStr)] string deviceId);
        [PreserveSig] int OnDeviceRemoved([MarshalAs(UnmanagedType.LPWStr)] string deviceId);
        [PreserveSig] int OnDefaultDeviceChanged(int flow, int role, [MarshalAs(UnmanagedType.LPWStr)] string defaultDeviceId);
        [PreserveSig] int OnPropertyValueChanged([MarshalAs(UnmanagedType.LPWStr)] string deviceId, PROPERTYKEY key);
    }

    public class Guard : IMMNotificationClient
    {
        const int Render = 0, Console = 0, Active = 1;

        [DllImport("ole32.dll")] static extern int PropVariantClear(ref PROPVARIANT pv);

        readonly IMMDeviceEnumerator en = (IMMDeviceEnumerator)(new MMDeviceEnumeratorCom());
        readonly Regex speaker;
        readonly string logFile;
        readonly object gate = new object();
        string lastDefault;
        bool lastDefaultIsSpeaker;

        public Guard(string speakerPattern, string logPath)
        {
            speaker = new Regex(speakerPattern, RegexOptions.IgnoreCase);
            logFile = logPath;
        }

        void Log(string msg)
        {
            try { lock (gate) File.AppendAllText(logFile, DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + "  " + msg + "\n"); }
            catch { }
        }

        static PROPVARIANT GetProp(IMMDevice d, string fmt, uint pid)
        {
            IPropertyStore ps;
            d.OpenPropertyStore(0, out ps);
            PROPERTYKEY k = new PROPERTYKEY();
            k.fmtid = new Guid(fmt);
            k.pid = pid;
            PROPVARIANT v;
            ps.GetValue(ref k, out v);
            Marshal.ReleaseComObject(ps);
            return v;
        }

        static string NameOf(IMMDevice d)
        {
            PROPVARIANT v = GetProp(d, "a45c254e-df1c-4efd-8020-67d146a850e0", 14);
            string s = v.vt == 31 ? Marshal.PtrToStringUni(v.p) : "?";
            PropVariantClear(ref v);
            return s;
        }

        static int FormOf(IMMDevice d)
        {
            PROPVARIANT v = GetProp(d, "1da5d803-d492-4edd-8c23-e0c0ffee7f0e", 0);
            int f = v.vt == 19 ? unchecked((int)(v.p.ToInt64() & 0xFFFFFFFF)) : -1;
            PropVariantClear(ref v);
            return f;
        }

        // Form factor 1 = speakers; the name alone also matches the same chip's headphone jack, and it is localised (Swedish here), so it cannot be matched by word.
        bool IsSpeaker(IMMDevice d) { return FormOf(d) == 1 && speaker.IsMatch(NameOf(d)); }

        static string IdOf(IMMDevice d) { string id; d.GetId(out id); return id; }

        static int StateOf(IMMDevice d) { int s; d.GetState(out s); return s; }

        static bool MuteOf(IMMDevice d)
        {
            Guid iid = new Guid("5CDF2C82-841E-4546-9722-0CF74078229A");
            object o;
            d.Activate(ref iid, 23, IntPtr.Zero, out o);
            bool m;
            ((IAudioEndpointVolume)o).GetMute(out m);
            return m;
        }

        static void SetMute(IMMDevice d, bool mute)
        {
            Guid iid = new Guid("5CDF2C82-841E-4546-9722-0CF74078229A");
            object o;
            d.Activate(ref iid, 23, IntPtr.Zero, out o);
            Guid ctx = Guid.Empty;
            ((IAudioEndpointVolume)o).SetMute(mute, ref ctx);
        }

        List<IMMDevice> Outputs(int stateMask)
        {
            List<IMMDevice> list = new List<IMMDevice>();
            IMMDeviceCollection col;
            en.EnumAudioEndpoints(Render, stateMask, out col);
            int n;
            col.GetCount(out n);
            for (int i = 0; i < n; i++) { IMMDevice d; col.Item(i, out d); list.Add(d); }
            return list;
        }

        IMMDevice DefaultOutput()
        {
            IMMDevice d;
            return en.GetDefaultAudioEndpoint(Render, Console, out d) == 0 ? d : null;
        }

        public string[] Status()
        {
            List<string> lines = new List<string>();
            IMMDevice def = DefaultOutput();
            string defId = def == null ? null : IdOf(def);
            foreach (IMMDevice d in Outputs(0xF))
            {
                string id = IdOf(d);
                int state = StateOf(d);
                string mute = state == Active ? MuteOf(d).ToString() : "-";
                lines.Add((id == defId ? "[default] " : "          ") + NameOf(d) + "  form=" + FormOf(d) + " state=" + state + " muted=" + mute
                    + (IsSpeaker(d) ? "  <- speaker" : ""));
            }
            return lines.ToArray();
        }

        public void MuteSpeakers(string reason)
        {
            foreach (IMMDevice d in Outputs(Active))
            {
                if (!IsSpeaker(d)) continue;
                string name = NameOf(d);
                try
                {
                    bool was = MuteOf(d);
                    SetMute(d, true);
                    Log("muted '" + name + "' (" + reason + (was ? ", was already muted" : "") + ")");
                }
                catch (Exception e) { Log("mute of '" + name + "' failed: " + e.Message); }
            }
        }

        void RememberDefault()
        {
            IMMDevice d = DefaultOutput();
            lastDefault = d == null ? null : IdOf(d);
            lastDefaultIsSpeaker = d != null && IsSpeaker(d);
        }

        public void Start()
        {
            RememberDefault();
            Log("watching; default output speaker=" + lastDefaultIsSpeaker);
            en.RegisterEndpointNotificationCallback(this);
        }

        void Async(Action a)
        {
            Task.Run(delegate { try { a(); } catch (Exception e) { Log("handler failed: " + e.Message); } });
        }

        void Gone(string id, string why)
        {
            if (id == null || id != lastDefault || lastDefaultIsSpeaker) return;
            Async(delegate { MuteSpeakers(why); });
        }

        public int OnDeviceStateChanged(string deviceId, int newState)
        {
            if (newState != Active) Gone(deviceId, "default output left, state " + newState);
            return 0;
        }

        public int OnDeviceAdded(string deviceId) { return 0; }

        public int OnDeviceRemoved(string deviceId)
        {
            Gone(deviceId, "default output removed");
            return 0;
        }

        public int OnDefaultDeviceChanged(int flow, int role, string defaultDeviceId)
        {
            if (flow != Render || role != Console) return 0;
            Async(delegate
            {
                string oldId = lastDefault;
                bool wasSpeaker = lastDefaultIsSpeaker;
                RememberDefault();
                if (!lastDefaultIsSpeaker || wasSpeaker || oldId == null) return;
                // A deliberate switch to the speaker leaves the headphones connected; a disconnect does not.
                for (int i = 0; i < 6; i++)
                {
                    IMMDevice old;
                    if (en.GetDevice(oldId, out old) != 0 || StateOf(old) != Active)
                    {
                        MuteSpeakers("default output changed to the speaker, headphones gone");
                        return;
                    }
                    Thread.Sleep(250);
                }
                Log("default output changed to the speaker, headphones still connected: not muted");
            });
            return 0;
        }

        public int OnPropertyValueChanged(string deviceId, PROPERTYKEY key) { return 0; }
    }
}
'@

Add-Type -TypeDefinition $src -Language CSharp

$log = Join-Path $env:LOCALAPPDATA 'speaker-guard.log'
$guard = New-Object SpeakerGuard.Guard($Speaker, $log)

switch ($Mode) {
    'status' { $guard.Status() }
    'mute' { $guard.MuteSpeakers('manual'); $guard.Status() }
    'watch' {
        $created = $false
        $mutex = New-Object System.Threading.Mutex($true, 'Local\SpeakerGuard', [ref]$created)
        if (-not $created) { return }
        $guard.Start()
        [System.Threading.Thread]::Sleep([System.Threading.Timeout]::Infinite)
    }
}
