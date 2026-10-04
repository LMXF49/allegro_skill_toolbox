// ============================================================================
// File        : Bridge.java
// Description : Bridge protocol v1 client (file queue at <TEMP>/astb_bridge),
//               a port of python/astb_bridge_client.py (same wire format as
//               the C++ version): GBK session/result JSON, pure-ASCII job
//               files with GBK octal escapes, atomic publish, corrupt-result
//               tolerant polling, queue GC, listdir/stat race skip.
// ============================================================================
package astb.studio.core;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;

public final class Bridge {

    public static final class Session {
        public String pid = "";
        public String version = "";
        public String design = "";
        public String fname = "";
        public double age;
        public boolean alive;
        // 桥 v1.4 busy 标记：认领 job 后心跳文件带 "busy":true,"cmd","since"；
        // tick 恢复后的正常心跳不再带 busy 即自动清除
        public boolean busy;
        public String cmd = "";
        public String since = "";

        /** 有效在线：心跳新鲜（alive）或 busy 未卡死（<1800s）。
         *  busy 会话 job 挂队等 tick 恢复，符合桥语义，可选中/可投送。 */
        public boolean effectiveAlive() { return alive || (busy && age < BUSY_TIMEOUT_SEC); }

        /** busy 超过 1800s：疑似卡死 */
        public boolean busyTimeout() { return busy && age >= BUSY_TIMEOUT_SEC; }
    }

    private Bridge() {}

    /** busy 疑似卡死阈值（秒）：心跳饿过它才算超时（数值属桥语义，勿改）。 */
    public static final double BUSY_TIMEOUT_SEC = 1800.0;

    // ---- sessions ---------------------------------------------------------------
    // 按 (文件名, mtime, size) 缓存 Session 解析结果；age/alive 每次用当前时间重算。
    // 缓存键含 mtime——文件被重写（心跳 tick）即自然失效，无需额外 TTL。
    private static final class CacheEntry {
        long mtimeMs;
        long size;
        Session parsed;
    }

    private static final Map<String, CacheEntry> SESSION_CACHE = new java.util.HashMap<>();

    public static List<Session> sessionsFrom(Path dir, double maxAgeSec) {
        List<Session> out = new ArrayList<>();
        List<Path> files = Util.listDir(dir);
        files.sort(Comparator.comparing(p -> p.getFileName().toString()));
        for (Path p : files) {
            String name = p.getFileName().toString();
            if (!name.startsWith("s_") || !name.endsWith(".session")) continue;
            long mtimeMs, size;
            try {
                mtimeMs = java.nio.file.Files.getLastModifiedTime(p).toMillis();
                size = java.nio.file.Files.size(p);
            } catch (java.io.IOException e) {
                continue;   // 竞态：listdir 后被 Allegro 侧清扫，跳过
            }
            double age = Math.max((System.currentTimeMillis() - mtimeMs) / 1000.0, 0.0);

            String key = p.toString();
            CacheEntry ce = SESSION_CACHE.get(key);
            Session s;
            if (ce != null && ce.mtimeMs == mtimeMs && ce.size == size) {
                s = ce.parsed;   // 命中：复用解析结果（字段对象本包内只读使用）
            } else {
                s = new Session();
                Object j = MiniJson.parse(Util.readText(p, Util.GBK));
                Map<String, Object> o = MiniJson.obj(j);
                if (o != null) {
                    s.pid = MiniJson.getStr(o, "pid", "");
                    s.version = MiniJson.getStr(o, "version", "");
                    s.design = MiniJson.getStr(o, "design", "");
                    s.busy = MiniJson.bool(o.get("busy"), false);
                    s.cmd = MiniJson.getStr(o, "cmd", "");
                    s.since = MiniJson.getStr(o, "since", "");
                }
                if (s.pid.isEmpty())   // 文件名兜底 s_<pid>.session
                    s.pid = name.substring(2, name.length() - 8);
                ce = new CacheEntry();
                ce.mtimeMs = mtimeMs;
                ce.size = size;
                ce.parsed = s;
                SESSION_CACHE.put(key, ce);
            }
            // age/alive 永远按当前时间重算，不进缓存
            Session view = new Session();
            view.pid = s.pid;
            view.version = s.version;
            view.design = s.design;
            view.busy = s.busy;
            view.cmd = s.cmd;
            view.since = s.since;
            view.fname = name;
            view.age = age;
            view.alive = age <= maxAgeSec;
            out.add(view);
        }
        return out;
    }

    /** Alive + stale sessions, sorted by file name (10 s default like Python). */
    public static List<Session> sessions() {
        return sessionsFrom(Util.join(Util.bridgeRoot(), "sessions"), 10.0);
    }

    // ---- gc -----------------------------------------------------------------------
    private static void gcDir(Path dir, NamePred pred, double maxAge) {
        for (Path p : Util.listDir(dir)) {
            String n = p.getFileName().toString();
            if (!pred.test(n)) continue;
            double age = Util.ageSec(p);
            if (age > maxAge) Util.delete(p);
        }
    }

    private interface NamePred { boolean test(String n); }

    /** Best-effort stale-file GC, called on every submit (same policy as Python). */
    public static void gcQueue() {
        gcDir(Util.join(Util.bridgeRoot(), "jobs"), n -> n.contains(".job"), 3600.0);
        gcDir(Util.join(Util.bridgeRoot(), "results"), n -> n.endsWith(".result.json"), 3600.0);
        gcDir(Util.join(Util.bridgeRoot(), "sessions"), n -> n.endsWith(".session"), 86400.0);
    }

    // ---- submit ---------------------------------------------------------------------

    /** Escape a string for a SKILL string literal -> pure ASCII output. */
    public static String skillEscape(String text) {
        StringBuilder out = new StringBuilder();
        for (int k = 0; k < text.length(); ++k) {
            char ch = text.charAt(k);
            if (ch == '\\') out.append("\\\\");
            else if (ch == '"') out.append("\\\"");
            else if (ch == '\n') out.append("\\n");
            else if (ch < 128) out.append(ch);
            else {
                byte[] gbk = String.valueOf(ch).getBytes(Util.GBK);
                for (byte b : gbk) appendOctal(out, b & 0xFF);
            }
        }
        return out.toString();
    }

    /** "\\%03o" 手写八进制拼接（hot path 上不走 String.format） */
    private static void appendOctal(StringBuilder out, int v) {
        out.append('\\');
        out.append((char) ('0' + ((v >> 6) & 7)));
        out.append((char) ('0' + ((v >> 3) & 7)));
        out.append((char) ('0' + (v & 7)));
    }

    public static String makeJobId() { return Util.nowJobId() + "-" + Util.randHex24(); }

    /** Job file content (pure ASCII; the bridge load()s this as SKILL source). */
    public static String jobContent(String jobId, String target, List<String> cmds) {
        StringBuilder c = new StringBuilder();
        c.append(";;; ASTB job v1 (generated by ASTBStudio-java)\n");
        c.append("ASTB_JOB_ID = \"").append(jobId).append("\"\n");
        c.append("ASTB_JOB_TARGET = \"").append(skillEscape(target)).append("\"\n");
        c.append("ASTB_JOB_CMDS = list(");
        for (int i = 0; i < cmds.size(); ++i) {
            if (i > 0) c.append(", ");
            c.append("\"").append(skillEscape(cmds.get(i))).append("\"");
        }
        c.append(")\n");
        return c.toString();
    }

    /**
     * Write jobs/<id>.job (via <id>.job.tmp.<pid> + atomic rename) after a GC
     * sweep. Returns the job id, or "" on failure.
     */
    public static String submitJob(List<String> cmds, String target, String jobId) {
        if (jobId == null) jobId = makeJobId();
        Path jdir = Util.join(Util.bridgeRoot(), "jobs");
        Util.mkdirs(jdir);
        gcQueue();   // cheap hygiene sweep on every submission
        Path path = Util.join(jdir, jobId + ".job");
        long pid = ProcessHandle.current().pid();
        Path tmp = path.resolveSibling(path.getFileName() + ".tmp." + pid);
        if (!Util.writeText(tmp, jobContent(jobId, target, cmds), Util.GBK)) return "";
        try {
            Files.move(tmp, path, StandardCopyOption.REPLACE_EXISTING,
                       StandardCopyOption.ATOMIC_MOVE);
        } catch (IOException e) {
            try {
                Files.move(tmp, path, StandardCopyOption.REPLACE_EXISTING);
            } catch (IOException e2) {
                Util.delete(tmp);
                return "";
            }
        }
        return jobId;
    }

    // ---- result ------------------------------------------------------------------------

    /**
     * Poll results/<id>.result.json (GBK JSON) until timeout; a partial/corrupt
     * read does NOT end the wait. On success the file is deleted and the parsed
     * object returned; null on timeout.
     */
    public static Object waitResult(String jobId, double timeoutSec) {
        Path path = Util.join(Util.join(Util.bridgeRoot(), "results"),
                              jobId + ".result.json");
        long deadline = System.currentTimeMillis() + (long) (timeoutSec * 1000.0);
        while (System.currentTimeMillis() < deadline) {
            if (Util.exists(path)) {
                try { Thread.sleep(50); } catch (InterruptedException ignored) {}
                Object j = MiniJson.parse(Util.readText(path, Util.GBK));
                if (MiniJson.obj(j) != null) {
                    Util.delete(path);
                    return j;
                }
                // 半截/坏 JSON：不算失败，继续轮询到超时
            }
            try { Thread.sleep(100); } catch (InterruptedException ignored) {}
        }
        return null;
    }

    // ---- convenience -------------------------------------------------------------------

    public static boolean anyAlive(List<Session> ss) {
        // busy 会话（job 挂队等 tick 恢复）同样算在线
        for (Session s : ss) if (s.effectiveAlive()) return true;
        return false;
    }

    /** 显示层过滤（纯函数）：只保留"有用"会话——ALIVE / ALIVE·过期 / busy
     *  执行中（含卡死超时）。stale（心跳断了且非 busy）不进入卡片列表。
     *  底层扫描/迁移/watchdog 不受影响。 */
    public static List<Session> visibleSessions(List<Session> ss) {
        List<Session> out = new ArrayList<>();
        for (Session s : ss) if (s.effectiveAlive()) out.add(s);
        return out;
    }

    /** 指定 pid 是否"有效在线"（含 busy 执行中）。体检/运行前的目标闸门（可测）。 */
    public static boolean pidOnline(String pid, List<Session> ss) {
        if (pid == null || pid.isEmpty()) return false;
        for (Session s : ss)
            if (s.pid.equals(pid) && s.effectiveAlive()) return true;
        return false;
    }

    /** 状态列文本：busy（执行中/执行中·超时）> ALIVE·过期 > ALIVE > stale。
     *  staleFlag 仅对非 busy 会话生效（busy 会话不算 stale）。 */
    public static String statusLabel(Session s, boolean staleFlag) {
        if (s.busy) {
            if (s.busyTimeout()) return "执行中·超时";
            String c = s.cmd.length() > 12 ? s.cmd.substring(0, 12) : s.cmd;
            return c.isEmpty() ? "执行中" : "执行中: " + c;
        }
        if (s.alive) return staleFlag ? "ALIVE·过期" : "ALIVE";
        return "stale";
    }

    /**
     * 超时归因（对齐 astb_bridge_client.py main 的两种文案语义）：
     * 等待超时但会话心跳仍 ALIVE -> 会话忙（模态对话框/交互命令未结束，job 挂队）；
     * 心跳也没有 -> 桥离线。调用方在 waitResult 返回 null 时用 sessions() 现查。
     */
    public static String timeoutDiagnosis(boolean anyAlive) {
        return anyAlive ? "会话忙：Allegro 可能有对话框或交互命令未结束，完成后重试"
                        : "桥离线/无结果（Allegro 未启动或 util_bridge 未加载）";
    }

    /** 16.6 的 tick 在负载下会滞后（Python 注释）：目标版本含 16.6 时等待加倍。 */
    public static double waitScaleForVersion(String version) {
        return version != null && version.contains("16.6") ? 2.0 : 1.0;
    }

    public static boolean resultOk(Object res) {
        return MiniJson.bool(MiniJson.obj(res) == null ? null : MiniJson.obj(res).get("ok"), false);
    }

    /** results[0] 的 [ok("true"/"false"), error, value]（无则 ["false","",""]）。
     *  桥侧机制：单条 cmd eval 失败时 results[i].ok=false、value=""、
     *  error="eval error (see Allegro command window)"，但顶层 ok 仍为 true。 */
    public static String[] firstItem(Object res) {
        Map<String, Object> o = MiniJson.obj(res);
        List<Object> rs = o == null ? null : MiniJson.arr(o.get("results"));
        if (rs != null && !rs.isEmpty()) {
            Map<String, Object> r0 = MiniJson.obj(rs.get(0));
            if (r0 != null)
                return new String[] { String.valueOf(MiniJson.bool(r0.get("ok"), false)),
                                      MiniJson.getStr(r0, "error", ""),
                                      MiniJson.getStr(r0, "value", "") };
        }
        return new String[] { "false", "", "" };
    }

    /** 条级错误摘要："cmd#0: <error>; cmd#2: <error>"（ok=false 或 error 非空的条目），
     *  全部正常返回 ""。只读诊断，不改交互。 */
    public static String itemErrors(Object res) {
        Map<String, Object> o = MiniJson.obj(res);
        List<Object> rs = o == null ? null : MiniJson.arr(o.get("results"));
        if (rs == null) return "";
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < rs.size(); ++i) {
            Map<String, Object> r = MiniJson.obj(rs.get(i));
            if (r == null) continue;
            boolean ok = MiniJson.bool(r.get("ok"), false);
            String err = MiniJson.getStr(r, "error", "");
            if (!ok || !err.isEmpty()) {
                if (sb.length() > 0) sb.append("; ");
                sb.append("cmd#").append(i).append(": ")
                  .append(err.isEmpty() ? "(eval 失败)" : err);
            }
        }
        return sb.toString();
    }

    /** results[i] 摘要行（value/error，截断 120，与 C++ 版同式） */
    public static String resultsSummary(Object res) {
        Map<String, Object> o = MiniJson.obj(res);
        if (o == null) return "";
        List<Object> rs = MiniJson.arr(o.get("results"));
        if (rs == null) return "";
        StringBuilder vals = new StringBuilder();
        for (Object r : rs) {
            Map<String, Object> ro = MiniJson.obj(r);
            if (ro == null) continue;
            boolean ok = MiniJson.bool(ro.get("ok"), false);
            String v = MiniJson.str(ro.get(ok ? "value" : "error"), "");
            if (v.length() > 120) v = v.substring(0, 120);
            if (vals.length() > 0) vals.append(" | ");
            if (!ok) vals.append("ERR:");
            vals.append(v);
        }
        return vals.toString();
    }
}
