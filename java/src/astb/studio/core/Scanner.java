// ============================================================================
// File        : Scanner.java
// Description : Recent .brd scanner (port of features.scan_recent_boards):
//               walk config["scan_dirs"] recursively for *.brd (90 days,
//               cap 100, mtime desc), and merge with the mru list for the
//               最近文件 tab (mru first, dedupe by path).
// ============================================================================
package astb.studio.core;

import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;

public final class Scanner {

    public static final class RecentRow {
        public String path;
        public String source;   // "最近" (mru) or "扫描"
        public boolean isBrd;
        public boolean exists;
    }

    private Scanner() {}

    // ---- config scan_dirs ---------------------------------------------------------
    public static List<String> getScanDirs(Map<String, Object> cfg) {
        List<String> out = new ArrayList<>();
        List<Object> a = MiniJson.arr(cfg.get("scan_dirs"));
        if (a != null)
            for (Object v : a) {
                String s = MiniJson.str(v);
                if (s != null && !s.isEmpty()) out.add(s);
            }
        return out;
    }

    public static void setScanDirs(Map<String, Object> cfg, List<String> dirs) {
        List<Object> a = MiniJson.newArr();
        for (String d : dirs)
            if (d != null && !d.isEmpty()) a.add(Util.slashes(d));
        cfg.put("scan_dirs", a);
    }

    // ---- walk -------------------------------------------------------------------------
    private static void walk(Path dir, double cutoffAgeSec, List<String[]> out) {
        for (Path p : Util.listDir(dir)) {
            String name = p.getFileName().toString();
            if (Util.isDir(p)) {
                if (name.equals(".git") || name.equals("__pycache__") ||
                    name.equals("node_modules"))
                    continue;
                walk(p, cutoffAgeSec, out);
                continue;
            }
            if (!name.toLowerCase(java.util.Locale.ROOT).endsWith(".brd")) continue;
            double age = Util.ageSec(p);
            if (age < 0 || age > cutoffAgeSec) continue;
            out.add(new String[] { Util.slashes(p.toString()), String.valueOf(age) });
        }
    }

    /** Walk dirs for *.brd newer than `days`, mtime desc, cap `limit`.
     *  Returns [path, ageSec] pairs. */
    public static List<String[]> scanRecentBoards(List<String> dirs, int days, int limit) {
        List<String[]> found = new ArrayList<>();
        double cutoff = days * 86400.0;
        for (String d : dirs) {
            if (d == null || d.isEmpty()) continue;
            Path p = Path.of(d);
            if (!Util.isDir(p)) continue;
            walk(p, cutoff, found);
        }
        found.sort(Comparator.comparingDouble(a -> Double.parseDouble(a[1])));
        if (found.size() > limit) return new ArrayList<>(found.subList(0, limit));
        return found;
    }

    /** mru 优先：mru 项按原序在前（含非 .brd 的命令名），扫描结果只补不重复的。 */
    public static List<RecentRow> mergeRecent(List<String> mru, List<String[]> scanned) {
        List<RecentRow> rows = new ArrayList<>();
        List<String> seenBrd = new ArrayList<>();
        for (String s : mru) {
            RecentRow r = new RecentRow();
            r.path = s;
            r.source = "最近";
            r.isBrd = Util.lower(s).endsWith(".brd");
            r.exists = r.isBrd && Util.exists(Path.of(s));
            rows.add(r);
            if (r.isBrd) seenBrd.add(s);
        }
        for (String[] sp : scanned) {
            if (seenBrd.contains(sp[0])) continue;
            RecentRow r = new RecentRow();
            r.path = sp[0];
            r.source = "扫描";
            r.isBrd = true;
            r.exists = true;
            rows.add(r);
            seenBrd.add(sp[0]);
        }
        return rows;
    }
}
