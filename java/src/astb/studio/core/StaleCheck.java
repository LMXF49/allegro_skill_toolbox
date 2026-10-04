// ============================================================================
// File        : StaleCheck.java
// Description : Toolbox-stale detection (port of features.py): a session is
//               stale when its bridge start time (session file creation time)
//               predates the newest toolbox change on disk
//               (.il/.form/.dat/.cfg under the toolbox root).
// ============================================================================
package astb.studio.core;

import java.nio.file.Path;

public final class StaleCheck {
    private StaleCheck() {}

    private static boolean toolboxExt(String name) {
        String n = Util.lower(name);
        return n.endsWith(".il") || n.endsWith(".form") || n.endsWith(".dat") ||
               n.endsWith(".cfg");
    }

    private static void walkNewest(Path dir, long[] newest) {
        for (Path p : Util.listDir(dir)) {
            String name = p.getFileName().toString();
            if (Util.isDir(p)) {
                if (name.equals(".git") || name.equals("__pycache__")) continue;
                walkNewest(p, newest);
                continue;
            }
            if (!toolboxExt(name)) continue;
            try {
                long ms = java.nio.file.Files.getLastModifiedTime(p).toMillis();
                if (ms > newest[0]) newest[0] = ms;
            } catch (Exception ignored) {}
        }
    }

    /** Newest toolbox mtime (ms epoch); 0 when nothing found. */
    public static long toolboxFreshMs(String toolboxRoot) {
        long[] newest = { 0L };
        walkNewest(Path.of(toolboxRoot), newest);
        return newest[0];
    }

    // 60s 缓存，避免 1s 定时器全树遍历
    private static long cachedFresh = 0;
    private static long cachedAt = 0;
    private static String cachedRoot = "";

    public static long toolboxFreshMsCached(String toolboxRoot) {
        long now = System.currentTimeMillis();
        if (cachedRoot.equals(toolboxRoot) && cachedAt != 0 && now - cachedAt < 60000)
            return cachedFresh;
        cachedFresh = toolboxFreshMs(toolboxRoot);
        cachedAt = now;
        cachedRoot = toolboxRoot;
        return cachedFresh;
    }

    /** Session bridge start time ~= heartbeat file creation time (ms). */
    public static long sessionStartMs(String pid) {
        return Util.ctimeMs(Util.join(Util.join(Util.bridgeRoot(), "sessions"),
                                      "s_" + pid + ".session"));
    }

    /** stale = session started before the newest toolbox change. */
    public static boolean isStale(String pid, long freshMs) {
        if (freshMs == 0) return false;
        long start = sessionStartMs(pid);
        return start != 0 && start < freshMs;
    }
}
