// ============================================================================
// File        : Projects.java
// Description : Project store (%USERPROFILE%\.astb_studio\projects.json,
//               UTF-8 array), .brd version sniffing, Allegro launcher and
//               SPB version autodetect. Port of backend.py's project part.
// ============================================================================
package astb.studio.core;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

public final class Projects {
    private Projects() {}

    public static Path storePath() { return Util.join(Util.appDir(), "projects.json"); }

    // ---- store --------------------------------------------------------------------
    public static List<Object> load() {
        return MiniJson.loadArr(storePath(), Util.UTF8);
    }

    public static boolean save(List<Object> arr) {
        return MiniJson.saveAtomic(storePath(), arr, Util.UTF8);
    }

    /** Add (or return the existing entry with the same brd path). version "" ->
     *  sniff the .brd, else config default_version. */
    public static Map<String, Object> add(List<Object> arr, String brd, String version,
                                          Map<String, Object> cfg) {
        String path = Util.slashes(brd);
        for (Object o : arr) {
            Map<String, Object> p = MiniJson.obj(o);
            if (p != null && path.equals(MiniJson.getStr(p, "brd", ""))) return p;
        }
        String ver = version;
        if (ver == null || ver.isEmpty()) {
            ver = sniffVersion(path);
            if (ver.isEmpty()) ver = MiniJson.getStr(cfg, "default_version", "17.4");
        }
        Map<String, Object> p = MiniJson.newObj();
        p.put("id", "p" + Util.nowId() + String.format("%03d", arr.size() % 1000));
        p.put("name", Util.stem(path));
        p.put("brd", path);
        p.put("version", ver);
        p.put("note", "");
        p.put("added", Util.nowStamp());
        p.put("last_opened", "");
        p.put("history", MiniJson.newArr());
        arr.add(p);
        return p;
    }

    /** Append {ts, action, detail} to the project's history (capped at 50). */
    @SuppressWarnings("unchecked")
    public static void logHistory(Map<String, Object> proj, String action, String detail) {
        List<Object> hist = MiniJson.arr(proj.get("history"));
        if (hist == null) {
            hist = MiniJson.newArr();
            proj.put("history", hist);
        }
        Map<String, Object> e = MiniJson.newObj();
        e.put("ts", Util.nowStamp());
        e.put("action", action);
        e.put("detail", detail == null ? "" : detail.substring(0, Math.min(500, detail.length())));
        hist.add(e);
        while (hist.size() > 50) hist.remove(0);
    }

    // ---- version detection ----------------------------------------------------------
    private static final String[] KNOWN = { "16.6", "17.4", "24.1" };

    /** Scan first AND last 64 KB; rightmost known version stamp wins. */
    public static String sniffVersion(String brdPath) {
        byte[] head;
        try {
            Path p = Path.of(brdPath);
            long size = Files.size(p);
            try (var fis = Files.newInputStream(p)) {
                byte[] a = fis.readNBytes(65536);
                byte[] b = new byte[0];
                if (size > 65536) {
                    fis.skipNBytes(size - 65536 - a.length > 0 ? size - 65536 - a.length : 0);
                    b = fis.readNBytes(65536);
                }
                head = new byte[a.length + b.length];
                System.arraycopy(a, 0, head, 0, a.length);
                System.arraycopy(b, 0, head, a.length, b.length);
            }
        } catch (IOException e) { return ""; }
        String hay = new String(head, java.nio.charset.StandardCharsets.ISO_8859_1);
        String best = "";
        int bestPos = -1;
        for (String ver : KNOWN) {
            int pos = hay.lastIndexOf(ver);
            if (pos > bestPos) { bestPos = pos; best = ver; }
        }
        return best;
    }

    /** Scan <drive>:\Cadence\SPB_*\(tools\bin|tools\pcb\bin)\allegro.exe, C/D/E/F/G. */
    public static Map<String, String> autodetectVersions() {
        Map<String, String> found = new TreeMap<>();
        for (char d : "CDEFG".toCharArray()) {
            Path root = Path.of(d + ":\\Cadence");
            if (!Util.isDir(root)) continue;
            for (Path sub : Util.listDir(root)) {
                if (!Util.isDir(sub)) continue;
                String name = sub.getFileName().toString();
                // ^SPB_(\d+)[._]?(\d+)
                if (name.length() < 6 || !name.regionMatches(true, 0, "SPB_", 0, 4)) continue;
                int i = 4;
                StringBuilder maj = new StringBuilder();
                while (i < name.length() && Character.isDigit(name.charAt(i))) maj.append(name.charAt(i++));
                if (maj.length() == 0) continue;
                if (i < name.length() && (name.charAt(i) == '_' || name.charAt(i) == '.')) ++i;
                StringBuilder min = new StringBuilder();
                while (i < name.length() && Character.isDigit(name.charAt(i))) min.append(name.charAt(i++));
                if (min.length() == 0) continue;
                String ver = maj + "." + min;
                if (found.containsKey(ver)) continue;
                for (String cand : new String[] { "tools\\bin\\allegro.exe",
                                                  "tools\\pcb\\bin\\allegro.exe" }) {
                    Path exe = sub.resolve(cand);
                    if (Util.exists(exe)) {
                        found.put(ver, Util.slashes(exe.toString()));
                        break;
                    }
                }
            }
        }
        return found;
    }

    @SuppressWarnings("unchecked")
    public static Map<String, Object> versionsMap(Map<String, Object> cfg) {
        Map<String, Object> vers = MiniJson.obj(cfg.get("versions"));
        if (vers == null) {
            vers = MiniJson.newObj();
            cfg.put("versions", vers);
        }
        if (vers.isEmpty()) {   // get_versions(): autodetect only when empty
            for (Map.Entry<String, String> e : autodetectVersions().entrySet())
                vers.putIfAbsent(e.getKey(), e.getValue());
            AppConfig.save(cfg);
        }
        return vers;
    }

    public static String versionsKnownList(Map<String, Object> cfg) {
        Map<String, Object> vers = MiniJson.obj(cfg.get("versions"));
        if (vers == null || vers.isEmpty()) return "（无）";
        return String.join(", ", new java.util.TreeMap<>(vers).keySet());
    }

    public static List<String> versionsKeys(Map<String, Object> cfg) {
        Map<String, Object> vers = MiniJson.obj(cfg.get("versions"));
        if (vers == null) return List.of();
        return new ArrayList<>(new java.util.TreeMap<>(vers).keySet());
    }

    /** Default selection for the add-project version picker. */
    public static String pickVersionDefault(Map<String, Object> cfg, String brd) {
        List<String> keys = versionsKeys(cfg);
        String sn = sniffVersion(brd);
        if (keys.contains(sn)) return sn;
        String def = MiniJson.getStr(cfg, "default_version", "17.4");
        if (keys.contains(def)) return def;
        return keys.isEmpty() ? "" : keys.get(0);
    }

    // ---- launcher ---------------------------------------------------------------------
    /** Launch Allegro with the board. version "" -> sniff -> default_version. */
    public static String[] launchAllegro(Map<String, Object> cfg, String brd, String version) {
        Map<String, Object> vers = versionsMap(cfg);
        if (version == null || version.isEmpty()) {
            version = sniffVersion(brd);
            if (version.isEmpty()) version = MiniJson.getStr(cfg, "default_version", "17.4");
        }
        String exe = MiniJson.getStr(vers, version, "");
        if (exe.isEmpty() || !Util.exists(Path.of(exe)))
            return new String[] { "false",
                    "版本 " + version + " 未注册 allegro.exe（已知版本：" +
                    versionsKnownList(cfg) + "）" };
        if (!Util.exists(Path.of(brd)))
            return new String[] { "false", "板子不存在：" + brd };
        try {
            new ProcessBuilder(exe, brd).start();
        } catch (IOException e) {
            return new String[] { "false", "启动失败：" + e.getMessage() };
        }
        return new String[] { "true", "已启动 " + Util.baseName(brd) + "（" + exe + "）" };
    }
}
