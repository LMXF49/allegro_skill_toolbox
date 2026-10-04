/* ============================================================================
 * File        : AstbBridgeClient.java
 * Author      : ASTB Team
 * Created     : 2026-10-03
 * Version     : 2.0
 * Description : App-side client for bridge protocol v1 (see the header of
 *               modules/utilities/util_bridge.il). Talks to any running
 *               Allegro session that has util_bridge.il loaded, via the
 *               file queue at <TEMP>/astb_bridge.
 *               取代 skill_src/python/astb_bridge_client.py v1.1.3（本仓已移除）。
 * Usage:
 *   java skill_src\tools\AstbBridgeClient.java sessions
 *   java skill_src\tools\AstbBridgeClient.java run "1+1" "axlVersion('version)"
 *   java skill_src\tools\AstbBridgeClient.java run --target 12345 --wait 20 "RVIA_Main()"
 *   (skill_src\tools\bridge.bat 已包好, 自动找 JDK 21)
 *
 * Encoding contract (unchanged from the Python client):
 *   - Job files stay ASCII; non-ASCII payload is octal-escaped GBK bytes
 *     on ALL supported versions (16.6/17.4/24.1): Allegro runtime strings
 *     are GBK byte strings on Chinese Windows. The 16.6 reader additionally
 *     rejects raw high bytes in strings, hence the octal escaping.
 *   - Result/session files are JSON text but GBK-encoded; always decode GBK.
 *   - Interactive commands (canvas picking) report ok=true the moment the
 *     command activates; that means "triggered", not "finished".
 * Revision history:
 *   2026-08-22 v1.0-v1.1.3 Python 版演进(见旧文件头, 存档于旧仓)
 *   2026-10-03 v2.0 首版 Java 工具链: 移植 v1.1.3 全部行为(sessions/submit/
 *               wait_result/gc_queue/skill_escape), 协议字节不变
 * ============================================================================
 */
import java.io.IOException;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.nio.file.AtomicMoveNotSupportedException;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.NoSuchFileException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.nio.file.StandardOpenOption;
import java.time.Instant;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

public class AstbBridgeClient {

    static final Charset GBK = Charset.forName("GBK");
    static final DateTimeFormatter JOB_TS =
            DateTimeFormatter.ofPattern("yyyyMMdd-HHmmss").withZone(ZoneOffset.systemDefault());

    public static void main(String[] argv) throws Exception {
        if (argv.length < 1 || argv[0].equals("-h") || argv[0].equals("--help")) {
            printUsage();
            System.exit(0);
        }
        switch (argv[0]) {
            case "sessions": System.exit(cmdSessions()); break;
            case "run":      System.exit(cmdRun(argv)); break;
            default:
                System.out.println("unknown action: " + argv[0]);
                System.exit(2);
        }
    }

    static void printUsage() {
        System.out.print(
            "App-side client for bridge protocol v1 (util_bridge.il); file queue at <TEMP>/astb_bridge.\n"
            + "\n"
            + "Usage:\n"
            + "  java AstbBridgeClient.java sessions\n"
            + "  java AstbBridgeClient.java run \"1+1\" \"axlVersion('version)\"\n"
            + "  java AstbBridgeClient.java run --target 12345 --wait 20 \"RVIA_Main()\"\n"
            + "\n"
            + "Actions:\n"
            + "  sessions        list alive bridge sessions (heartbeat fresher than 10s = ALIVE)\n"
            + "  run [opts] expr submit one or more SKILL expressions and wait for the result;\n"
            + "                  opts: --target <pid> (default broadcast), --wait <seconds> (default 15)\n"
            + "Exit codes: 0 ok; 1 no session / timeout / result ok=false; 2 usage error.\n");
    }

    // ----------------------------------------------------------------- queue

    static Path bridgeRoot() {
        String tmp = System.getenv("TMPDIR");
        if (tmp == null || tmp.isEmpty()) tmp = System.getenv("TEMP");
        if (tmp == null || tmp.isEmpty()) tmp = System.getenv("TMP");
        if (tmp == null || tmp.isEmpty()) tmp = System.getProperty("java.io.tmpdir");
        return Paths.get(tmp, "astb_bridge");
    }

    /** GBK-encoded JSON reader for bridge files; null on any failure. */
    @SuppressWarnings("unchecked")
    static Map<String, Object> readJsonMap(Path path) {
        try {
            Object v = Json.parse(new String(Files.readAllBytes(path), GBK));
            return (Map<String, Object>) v;
        } catch (Exception e) {
            return null;
        }
    }

    /** Best-effort stale-file GC; called on submit(); safe any time. */
    static void gcQueue(double jobMaxAge, double sessionMaxAge) {
        double now = System.currentTimeMillis() / 1000.0;
        gcSubdir("jobs", n -> n.contains(".job"), jobMaxAge, now);
        gcSubdir("results", n -> n.endsWith(".result.json"), jobMaxAge, now);
        gcSubdir("sessions", n -> n.endsWith(".session"), sessionMaxAge, now);
    }

    interface NamePred { boolean ok(String n); }

    static void gcSubdir(String sub, NamePred pred, double maxAge, double now) {
        Path d = bridgeRoot().resolve(sub);
        try (DirectoryStream<Path> ds = Files.newDirectoryStream(d)) {
            for (Path p : ds) {
                String name = p.getFileName().toString();
                if (!pred.ok(name)) continue;
                try {
                    double mtime = Files.getLastModifiedTime(p).toMillis() / 1000.0;
                    if (now - mtime > maxAge) Files.deleteIfExists(p);
                } catch (IOException ignore) {}
            }
        } catch (IOException ignore) {}
    }

    /** Alive bridge sessions; heartbeat file mtime fresher than maxAge (10s: 16.6 tick lags). */
    static List<Map<String, Object>> sessions(double maxAge) {
        List<Map<String, Object>> out = new ArrayList<>();
        Path sdir = bridgeRoot().resolve("sessions");
        if (!Files.isDirectory(sdir)) return out;
        double now = System.currentTimeMillis() / 1000.0;
        List<String> names = new ArrayList<>();
        try (DirectoryStream<Path> ds = Files.newDirectoryStream(sdir)) {
            for (Path p : ds) names.add(p.getFileName().toString());
        } catch (NoSuchFileException e) {
            return out;
        } catch (IOException e) {
            return out;
        }
        names.sort(String::compareTo);
        for (String name : names) {
            if (!(name.startsWith("s_") && name.endsWith(".session"))) continue;
            Path path = sdir.resolve(name);
            double age;
            try {
                age = now - Files.getLastModifiedTime(path).toMillis() / 1000.0;
            } catch (IOException e) {
                continue;
            }
            Map<String, Object> info = readJsonMap(path);
            if (info == null) info = new LinkedHashMap<>();
            info.put("age", round1(age));
            info.put("alive", age <= maxAge);
            out.add(info);
        }
        return out;
    }

    static double round1(double v) { return Math.round(v * 10.0) / 10.0; }

    /** Escape a String for a SKILL string literal (ASCII output, GBK octal for high bytes). */
    static String skillEscape(String text) {
        StringBuilder sb = new StringBuilder();
        text.codePoints().forEach(cp -> {
            if (cp == '\\') sb.append("\\\\");
            else if (cp == '"') sb.append("\\\"");
            else if (cp == '\n') sb.append("\\n");
            else if (cp < 128) sb.append((char) cp);
            else {
                String s = new String(Character.toChars(cp));
                for (byte b : s.getBytes(GBK)) sb.append(String.format(Locale.ROOT, "\\%03o", b & 0xFF));
            }
        });
        return sb.toString();
    }

    /** Write a job file atomically; returns [jobId, jobPath]. */
    static Object[] submit(List<String> cmds, String target) throws IOException {
        String jobId = JOB_TS.format(Instant.now()) + "-"
                + UUID.randomUUID().toString().replace("-", "").substring(0, 6);
        StringBuilder sb = new StringBuilder();
        sb.append(";;; ASTB job v1 (generated by AstbBridgeClient.java)\n");
        sb.append("ASTB_JOB_ID = \"").append(jobId).append("\"\n");
        sb.append("ASTB_JOB_TARGET = \"").append(skillEscape(target)).append("\"\n");
        sb.append("ASTB_JOB_CMDS = list(");
        for (int i = 0; i < cmds.size(); i++) {
            if (i > 0) sb.append(", ");
            sb.append('"').append(skillEscape(cmds.get(i))).append('"');
        }
        sb.append(")\n");
        Path jdir = bridgeRoot().resolve("jobs");
        Files.createDirectories(jdir);
        gcQueue(3600.0, 86400.0);                 // cheap hygiene sweep on every submission
        Path path = jdir.resolve(jobId + ".job");
        Path tmp = jdir.resolve(jobId + ".job.tmp." + ProcessHandle.current().pid());
        Files.write(tmp, sb.toString().getBytes(StandardCharsets.US_ASCII),
                StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING,
                StandardOpenOption.WRITE);
        try {                                     // atomic publish: bridge never sees a partial file
            Files.move(tmp, path, StandardCopyOption.ATOMIC_MOVE);
        } catch (AtomicMoveNotSupportedException e) {
            Files.move(tmp, path, StandardCopyOption.REPLACE_EXISTING);
        }
        return new Object[]{jobId, path};
    }

    /** Poll for results/<jobId>.result.json; delete after a successful read.
     *  A partial/corrupt read does NOT end the wait (bridge write is not atomic). */
    static Map<String, Object> waitResult(String jobId, double timeout, double poll) throws InterruptedException {
        Path path = bridgeRoot().resolve("results").resolve(jobId + ".result.json");
        double deadline = System.currentTimeMillis() / 1000.0 + timeout;
        while (System.currentTimeMillis() / 1000.0 < deadline) {
            if (Files.isRegularFile(path)) {
                Thread.sleep(50);                 // brief settle before reading
                Map<String, Object> data = readJsonMap(path);
                if (data != null) {
                    try { Files.deleteIfExists(path); } catch (IOException ignore) {}
                    return data;
                }
            }
            Thread.sleep((long) (poll * 1000));
        }
        return null;
    }

    // ------------------------------------------------------------------- CLI

    static int cmdSessions() {
        List<Map<String, Object>> ss = sessions(10.0);
        if (ss.isEmpty()) {
            System.out.println("no bridge sessions found (is Allegro running with util_bridge loaded?)");
            return 1;
        }
        for (Map<String, Object> s : ss) {
            String flag = (Boolean.TRUE.equals(s.get("alive"))) ? "ALIVE" : "stale";
            System.out.printf("%s pid=%s version=%s design=%s age=%ss%n",
                    flag, show(s.get("pid")), show(s.get("version")),
                    show(s.get("design")), show(s.get("age")));
        }
        return 0;
    }

    /** Python str(None)="None" 对齐。 */
    static String show(Object o) { return o == null ? "None" : String.valueOf(o); }

    static int cmdRun(String[] argv) throws Exception {
        List<String> args = new ArrayList<>(List.of(argv).subList(1, argv.length));
        String target = "";
        double waitS = 15.0;
        for (int i = 0; i < args.size() - 1; ) {
            if (args.get(i).equals("--target")) { target = args.get(i + 1); args.subList(i, i + 2).clear(); }
            else if (args.get(i).equals("--wait")) {
                waitS = Double.parseDouble(args.get(i + 1));
                args.subList(i, i + 2).clear();
            } else i++;
        }
        if (args.isEmpty()) {
            System.out.println("run: need at least one SKILL expression");
            return 2;
        }
        Object[] job = submit(args, target);
        String jobId = (String) job[0];
        System.out.println("job " + jobId + " submitted -> " + job[1]);
        Map<String, Object> res = waitResult(jobId, waitS, 0.1);
        if (res == null) {
            boolean alive = false;
            for (Map<String, Object> s : sessions(10.0)) alive |= Boolean.TRUE.equals(s.get("alive"));
            if (alive)
                System.out.printf(Locale.ROOT, "no result within %.1fs (session alive but busy - "
                        + "Allegro modal dialog or interactive command active? finish it and retry)%n", waitS);
            else
                System.out.printf(Locale.ROOT, "no result within %.1fs (bridge offline)%n", waitS);
            return 1;
        }
        System.out.println(Json.dumps(res, 2));
        return Boolean.TRUE.equals(res.get("ok")) ? 0 : 1;
    }

    // ------------------------------------------------- minimal JSON (ordered)

    /** 迷你 JSON：LinkedHashMap/ArrayList 保序，足够桥接 session/result 文件。 */
    static final class Json {
        static Object parse(String s) {
            P p = new P(s);
            p.ws();
            Object v = p.value();
            return v;
        }

        static final class P {
            final String s;
            int i = 0;
            P(String s) { this.s = s; }
            void ws() { while (i < s.length() && Character.isWhitespace(s.charAt(i))) i++; }
            char peek() { ws(); return s.charAt(i); }

            Object value() {
                char c = peek();
                switch (c) {
                    case '{': return obj();
                    case '[': return arr();
                    case '"': return str();
                    case 't': i += 4; return Boolean.TRUE;
                    case 'f': i += 5; return Boolean.FALSE;
                    case 'n': i += 4; return null;
                    default:  return num();
                }
            }
            Map<String, Object> obj() {
                LinkedHashMap<String, Object> m = new LinkedHashMap<>();
                i++; ws();
                if (s.charAt(i) == '}') { i++; return m; }
                while (true) {
                    ws();                            // 跳过 ',' 之后的缩进空白
                    String k = str();
                    ws(); i++;                       // ':'
                    m.put(k, value());
                    char c = peek(); i++;
                    if (c == '}') return m;
                }
            }
            List<Object> arr() {
                ArrayList<Object> a = new ArrayList<>();
                i++; ws();
                if (s.charAt(i) == ']') { i++; return a; }
                while (true) {
                    a.add(value());
                    char c = peek(); i++;
                    if (c == ']') return a;
                }
            }
            String str() {
                StringBuilder sb = new StringBuilder();
                i++;                                 // opening quote
                while (true) {
                    char c = s.charAt(i++);
                    if (c == '"') return sb.toString();
                    if (c == '\\') {
                        char e = s.charAt(i++);
                        switch (e) {
                            case '"': case '\\': case '/': sb.append(e); break;
                            case 'b': sb.append('\b'); break;
                            case 'f': sb.append('\f'); break;
                            case 'n': sb.append('\n'); break;
                            case 'r': sb.append('\r'); break;
                            case 't': sb.append('\t'); break;
                            case 'u': sb.append((char) Integer.parseInt(s.substring(i, i + 4), 16)); i += 4; break;
                        }
                    } else sb.append(c);
                }
            }
            Object num() {
                int st = i;
                while (i < s.length() && "+-0123456789.eE".indexOf(s.charAt(i)) >= 0) i++;
                String t = s.substring(st, i);
                if (t.indexOf('.') < 0 && t.indexOf('e') < 0 && t.indexOf('E') < 0)
                    return Long.parseLong(t);
                return Double.parseDouble(t);
            }
        }

        /** Python json.dumps(v, indent=2, ensure_ascii=False) 等价输出。 */
        static String dumps(Object v, int indent) {
            StringBuilder sb = new StringBuilder();
            write(sb, v, indent, 0);
            return sb.toString();
        }

        static void write(StringBuilder sb, Object v, int indent, int depth) {
            if (v == null) { sb.append("null"); return; }
            if (v instanceof String) { writeStr(sb, (String) v); return; }
            if (v instanceof Boolean || v instanceof Long) { sb.append(v); return; }
            if (v instanceof Double) { sb.append(fmtNum((Double) v)); return; }
            if (v instanceof Map) {
                Map<?, ?> m = (Map<?, ?>) v;
                if (m.isEmpty()) { sb.append("{}"); return; }
                sb.append("{\n");
                int k = 0;
                String pad = " ".repeat(indent * (depth + 1));
                for (Map.Entry<?, ?> e : m.entrySet()) {
                    if (k++ > 0) sb.append(",\n");
                    sb.append(pad);
                    writeStr(sb, String.valueOf(e.getKey()));
                    sb.append(": ");
                    write(sb, e.getValue(), indent, depth + 1);
                }
                sb.append("\n").append(" ".repeat(indent * depth)).append("}");
                return;
            }
            if (v instanceof List) {
                List<?> a = (List<?>) v;
                if (a.isEmpty()) { sb.append("[]"); return; }
                sb.append("[\n");
                int k = 0;
                String pad = " ".repeat(indent * (depth + 1));
                for (Object x : a) {
                    if (k++ > 0) sb.append(",\n");
                    sb.append(pad);
                    write(sb, x, indent, depth + 1);
                }
                sb.append("\n").append(" ".repeat(indent * depth)).append("]");
            }
        }

        static void writeStr(StringBuilder sb, String s) {
            sb.append('"');
            for (int i = 0; i < s.length(); i++) {
                char c = s.charAt(i);
                switch (c) {
                    case '"':  sb.append("\\\""); break;
                    case '\\': sb.append("\\\\"); break;
                    case '\n': sb.append("\\n"); break;
                    case '\r': sb.append("\\r"); break;
                    case '\t': sb.append("\\t"); break;
                    case '\b': sb.append("\\b"); break;
                    case '\f': sb.append("\\f"); break;
                    default:
                        if (c < 0x20) sb.append(String.format(Locale.ROOT, "\\u%04x", (int) c));
                        else sb.append(c);
                }
            }
            sb.append('"');
        }

        /** Python repr 风格: 整数值浮点保留 .0。 */
        static String fmtNum(double d) {
            if (d == Math.rint(d) && !Double.isInfinite(d) && Math.abs(d) < 1e15)
                return String.format(Locale.ROOT, "%.1f", d);
            return Double.toString(d);
        }
    }
}
