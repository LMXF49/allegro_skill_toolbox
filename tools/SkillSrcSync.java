/* ============================================================================
 * File        : SkillSrcSync.java
 * Author      : ASTB Team
 * Created     : 2026-10-03
 * Version     : 2.0
 * Description : skill_src(可读副本) <-> skill_payload(部署形态) 双向同步。
 *               取代 tools/skill_src_sync.py（Python 原版, 本仓已移除）。
 *               payload 里的 .il 字符串是 \ooo 八进制转义形态(16.6 reader
 *               要求), 直接改中文很别扭; 因此在 skill_src/ 里维护 GBK 原文
 *               可读副本, 编辑后一条命令回写 payload。
 * Usage       : (JDK 11+ 单文件源码直跑, 需在仓库内任意目录执行)
 *   java tools\SkillSrcSync.java export   # payload -> skill_src(反转义, 重建可读副本)
 *   java tools\SkillSrcSync.java sync     # skill_src -> payload(转义回写, 平时改完用这个)
 *   java tools\SkillSrcSync.java check    # 往返一致性自检(export+sync 到临时目录逐字节比对)
 *   (tools\sync.bat 已包好上述命令, 自动找 JDK 21)
 * Rules       :
 *   - .il 双向转换; 其它文件(.form/.dat/.java/.bat/.md/...) 原样拷贝
 *   - sync 只覆盖/新增, 绝不删除 payload 里多出的文件(config/astb.cfg 等
 *     运行产物; 删除模块后需手动删 payload 对应文件)
 *   - sync 不覆盖 SYNC_SKIP_FILES 里的运行产物(Allegro 运行时写 payload,
 *     如 config/hotkeys_user.dat——2026-09-29 sync 曾把 src 旧副本覆盖回
 *     payload 冲掉用户键位, 此口必须堵上)
 *   - payload 的 .il 由本工具生成, 不要手工改(改了下次 export 会被覆盖)
 * Encoding    : .il 一律 GBK(逐字节处理, 与编码无关); 本文件 UTF-8。
 * Semantics   : 字符串状态机为转义感知(\ 吞下一字符, 同 astb_smoke 的
 *               mask_code 约定):
 *   - ascillize: 字符串内 >=0x80 字节 -> \ooo, 注释/字符串外不动
 *     (经 skill_src 77 个 .il 与 payload 全量对照验证, 与旧仓 _patches
 *     fix_166_strings_20260904.ascillize 逐字节一致; strip_undo 在现有
 *     语料上为恒等, 不再保留)
 *   - deascillize: ascillize 的逆; \\ooo(>=0x80) 还原为字节, \" \\" 等
 *     转义对原样保留。注意: src 字符串里手写的高位八进制字面量(\313 这类
 *     ASCII 文本)会被 export 还原为 GBK 原字节——这是设计行为(与旧版一致)。
 * Revision history:
 *   2026-10-03 v2.0 首版 Java 工具链: 移植 sync.py 并修正字符串状态机为
 *               转义感知(旧 deascillize 在 \" 场景与 ascillize 不对称,
 *               check 闸门对 3 个文件本会误报; 现全仓 77 个 .il 往返全绿)
 * ============================================================================
 */
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.Charset;
import java.nio.file.FileVisitResult;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.SimpleFileVisitor;
import java.nio.file.StandardCopyOption;
import java.nio.file.attribute.BasicFileAttributes;
import java.nio.file.attribute.FileTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.stream.Stream;

public class SkillSrcSync {

    static final Charset GBK = Charset.forName("GBK");
    static final Set<String> SKIP_DIRS = new HashSet<>(Arrays.asList("__pycache__", ".vscode", ".git"));
    static final Set<String> SYNC_SKIP_FILES = new HashSet<>(Arrays.asList("config/hotkeys_user.dat"));

    static Path ROOT, PAYLOAD, SRC;

    public static void main(String[] args) throws Exception {
        String cmd = args.length > 0 ? args[0] : "";
        ROOT = findRepoRoot();
        PAYLOAD = ROOT.resolve("skill_payload");
        SRC = ROOT.resolve("skill_src");
        switch (cmd) {
            case "export": doExport(); break;
            case "sync":   doSync(PAYLOAD, false); break;
            case "check":  System.exit(doCheck()); break;
            default:
                System.out.println("usage: java tools\\SkillSrcSync.java export|sync|check");
                System.exit(2);
        }
    }

    /** 从当前目录逐级向上找同时含 skill_src/ 与 skill_payload/ 的目录。 */
    static Path findRepoRoot() {
        Path dir = Paths.get("").toAbsolutePath();
        while (dir != null) {
            if (Files.isDirectory(dir.resolve("skill_src")) && Files.isDirectory(dir.resolve("skill_payload")))
                return dir;
            dir = dir.getParent();
        }
        System.err.println("error: 未找到仓库根(需存在 skill_src/ 与 skill_payload/), 请在仓库内运行");
        System.exit(2);
        return null;
    }

    // ------------------------------------------------------------------ walk

    static final class Rel {
        final String rel;   // 相对路径, '/' 分隔
        final Path full;
        Rel(String rel, Path full) { this.rel = rel; this.full = full; }
    }

    static List<Rel> walkFiles(Path root) throws IOException {
        List<Rel> out = new ArrayList<>();
        try (Stream<Path> stream = Files.walk(root)) {
            stream.filter(p -> {
                for (Path part : p) if (SKIP_DIRS.contains(part.toString())) return false;
                String n = p.getFileName().toString().toLowerCase(Locale.ROOT);
                return !(n.endsWith(".log") || n.endsWith(".tmp"));
            }).filter(Files::isRegularFile).forEach(p ->
                out.add(new Rel(root.relativize(p).toString().replace('\\', '/'), p)));
        }
        out.sort(Comparator.comparing(r -> r.rel));
        return out;
    }

    static boolean isIl(Rel f) { return f.rel.toLowerCase(Locale.ROOT).endsWith(".il"); }

    // --------------------------------------------------- 字符串状态机(转义感知)

    /** 字符串内 >=0x80 字节 -> \ooo; 注释/字符串外不动; \ 吞下一字符(转义对原样)。 */
    static byte[] ascillize(byte[] d) {
        Buf out = new Buf();
        boolean inStr = false, inComment = false;
        int i = 0, L = d.length;
        while (i < L) {
            int b = d[i] & 0xFF;
            if (inComment) {
                out.w(b);
                if (b == 0x0A) inComment = false;
                i += 1;
                continue;
            }
            if (inStr) {
                if (b == 0x5C) {              // 反斜杠吞下一字符: \\" \\\\ \\+换行 原样成对输出
                    out.w(b);
                    if (i + 1 < L) out.w(d[i + 1]);
                    i += 2;
                    continue;
                }
                if (b >= 0x80) {
                    out.w(String.format("\\%03o", b).getBytes(Charset.forName("ISO-8859-1")));
                    i += 1;
                    continue;
                }
                out.w(b);
                if (b == 0x22) inStr = false;
                i += 1;
                continue;
            }
            if (b == 0x3B) { inComment = true; out.w(b); }
            else { if (b == 0x22) inStr = true; out.w(b); }
            i += 1;
        }
        return out.bytes();
    }

    /** ascillize 的逆: 字符串内 \ooo(>=0x80) 还原为字节, 其余转义对原样保留。 */
    static byte[] deascillize(byte[] d) {
        Buf out = new Buf();
        boolean inStr = false, inComment = false;
        int i = 0, L = d.length;
        while (i < L) {
            int b = d[i] & 0xFF;
            if (inComment) {
                out.w(b);
                if (b == 0x0A) inComment = false;
                i += 1;
                continue;
            }
            if (inStr) {
                if (b == 0x5C) {
                    if (i + 3 < L) {
                        int c1 = d[i + 1] & 0xFF, c2 = d[i + 2] & 0xFF, c3 = d[i + 3] & 0xFF;
                        if (c1 >= 0x30 && c1 <= 0x37 && c2 >= 0x30 && c2 <= 0x37 && c3 >= 0x30 && c3 <= 0x37) {
                            int val = (c1 - 0x30) * 64 + (c2 - 0x30) * 8 + (c3 - 0x30);
                            if (val >= 0x80) {
                                out.w(val);           // \ooo -> 原字节
                                i += 4;
                                continue;
                            }
                        }
                    }
                    out.w(b);                          // 非高位八进制: 成对原样保留
                    if (i + 1 < L) out.w(d[i + 1]);
                    i += 2;
                    continue;
                }
                out.w(b);
                if (b == 0x22) inStr = false;
                i += 1;
                continue;
            }
            if (b == 0x3B) { inComment = true; out.w(b); }
            else { if (b == 0x22) inStr = true; out.w(b); }
            i += 1;
        }
        return out.bytes();
    }

    /** 手写可增长字节缓冲(deascillize 需要成对回退, 不便用 ByteArrayOutputStream)。 */
    static final class Buf {
        byte[] a = new byte[1024];
        int n = 0;
        void w(int b) {
            if (n == a.length) a = Arrays.copyOf(a, n * 2);
            a[n++] = (byte) b;
        }
        void w(byte[] bs) { for (byte b : bs) w(b); }
        byte[] bytes() { return Arrays.copyOf(a, n); }
    }

    // ---------------------------------------------------------------- 命令体

    static void doExport() throws IOException {
        int nIl = 0, nCp = 0, nEsc = 0;
        for (Rel f : walkFiles(PAYLOAD)) {
            Path dst = SRC.resolve(f.rel);
            Files.createDirectories(dst.getParent());
            byte[] raw = Files.readAllBytes(f.full);
            if (isIl(f)) {
                byte[] neu = deascillize(raw);
                Files.write(dst, neu);
                nIl += 1;
            } else {
                copyPreserveMtime(f.full, dst);
                nCp += 1;
            }
        }
        System.out.printf("export: %d .il 反转义(%d 处) + %d 个文件原样拷贝 -> %s%n", nIl, nEsc, nCp, SRC);
    }

    static int doSync(Path dstRoot, boolean quiet) throws IOException {
        int nIl = 0, nCp = 0, nSkip = 0;
        for (Rel f : walkFiles(SRC)) {
            if (SYNC_SKIP_FILES.contains(f.rel)) { nSkip += 1; continue; }
            Path dst = dstRoot.resolve(f.rel);
            byte[] raw = Files.readAllBytes(f.full);
            byte[] neu;
            if (isIl(f)) neu = ascillize(raw);
            else neu = raw;
            if (Files.exists(dst) && Arrays.equals(Files.readAllBytes(dst), neu)) { nSkip += 1; continue; }
            Files.createDirectories(dst.getParent());
            Files.write(dst, neu);
            if (isIl(f)) nIl += 1; else nCp += 1;
            if (!quiet) System.out.println("  wrote " + f.rel);
        }
        if (!quiet)
            System.out.printf("sync: %d .il 转义回写 + %d 个文件拷贝, %d 个未变跳过 -> %s%n",
                    nIl, nCp, nSkip, dstRoot);
        return nIl + nCp;
    }

    static int doCheck() throws Exception {
        Path tmp = Files.createTempDirectory("srcsync_");
        try {
            Path savedSrc = SRC;
            SRC = tmp.resolve("src");
            doExport();
            Path out = tmp.resolve("out");
            doSync(out, true);
            SRC = savedSrc;
            List<String> bad = new ArrayList<>();
            for (Rel f : walkFiles(PAYLOAD)) {
                if (SYNC_SKIP_FILES.contains(f.rel)) continue;   // 运行产物不参与往返比对
                Path other = out.resolve(f.rel);
                if (!Files.exists(other)) { bad.add(f.rel + " (missing after roundtrip)"); continue; }
                if (!Arrays.equals(Files.readAllBytes(f.full), Files.readAllBytes(other))) bad.add(f.rel);
            }
            if (!bad.isEmpty()) {
                System.out.printf("check FAILED, %d 个文件往返不一致:%n", bad.size());
                for (String b : bad.subList(0, Math.min(20, bad.size()))) System.out.println("   " + b);
                return 1;
            }
            System.out.println("check PASS: 全部文件往返逐字节一致");
            return 0;
        } finally {
            rmtree(tmp);
        }
    }

    static void copyPreserveMtime(Path src, Path dst) throws IOException {
        Files.copy(src, dst, StandardCopyOption.REPLACE_EXISTING);
        Files.setLastModifiedTime(dst, Files.getLastModifiedTime(src));
    }

    static void rmtree(Path root) throws IOException {
        if (!Files.exists(root)) return;
        try (Stream<Path> stream = Files.walk(root)) {
            stream.sorted(Comparator.reverseOrder()).forEach(p -> {
                try { Files.deleteIfExists(p); } catch (IOException ignore) {}
            });
        }
    }
}
