// ============================================================================
// File        : Util.java
// Description : Shared helpers: GBK/UTF-8 file IO, paths, time, string utils.
//               Internal text is UTF-16 (Java String); GBK files go through
//               Charset "GBK" (same bytes as the C++/Python versions).
// ============================================================================
package astb.studio.core;

import java.io.IOException;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Random;

public final class Util {
    private Util() {}

    public static final Charset GBK = Charset.forName("GBK");
    public static final Charset UTF8 = StandardCharsets.UTF_8;

    // ---- paths --------------------------------------------------------------
    public static Path bridgeRoot() {
        return Path.of(System.getProperty("java.io.tmpdir"), "astb_bridge");
    }

    public static Path appDir() {
        return Path.of(System.getProperty("user.home"), ".astb_studio");
    }

    public static Path configPath() { return appDir().resolve("config.json"); }

    public static Path join(Path a, String b) { return a.resolve(b); }

    // ---- file IO --------------------------------------------------------------
    public static byte[] readBytes(Path p) {
        try { return Files.readAllBytes(p); } catch (IOException e) { return null; }
    }

    public static String readText(Path p, Charset cs) {
        byte[] b = readBytes(p);
        return b == null ? null : new String(b, cs);
    }

    public static boolean writeBytes(Path p, byte[] data) {
        try {
            if (p.getParent() != null) Files.createDirectories(p.getParent());
            Files.write(p, data);
            return true;
        } catch (IOException e) { return false; }
    }

    public static boolean writeText(Path p, String text, Charset cs) {
        return writeBytes(p, text.getBytes(cs));
    }

    /** tmp file + atomic-ish replace (same publish discipline as the bridge). */
    public static boolean writeTextAtomic(Path p, String text, Charset cs) {
        Path tmp = p.resolveSibling(p.getFileName() + ".tmp");
        if (!writeText(tmp, text, cs)) return false;
        try {
            Files.move(tmp, p, StandardCopyOption.REPLACE_EXISTING,
                       StandardCopyOption.ATOMIC_MOVE);
            return true;
        } catch (IOException e) {
            try {
                Files.move(tmp, p, StandardCopyOption.REPLACE_EXISTING);
                return true;
            } catch (IOException e2) {
                delete(tmp);   // 两个 move 都失败：不留 .tmp 垃圾
                return false;
            }
        }
    }

    public static boolean exists(Path p) { return Files.isRegularFile(p); }
    public static boolean isDir(Path p) { return Files.isDirectory(p); }
    public static void mkdirs(Path p) {
        try { Files.createDirectories(p); } catch (IOException ignored) {}
    }
    public static boolean delete(Path p) {
        try { return Files.deleteIfExists(p); } catch (IOException e) { return false; }
    }

    /** age of last-write in seconds; negative when the stat failed (queue race). */
    public static double ageSec(Path p) {
        try {
            long ms = Files.getLastModifiedTime(p).toMillis();
            double age = (System.currentTimeMillis() - ms) / 1000.0;
            return Math.max(age, 0.0);
        } catch (IOException e) { return -1.0; }
    }

    public static long ctimeMs(Path p) {
        try {
            return ((java.nio.file.attribute.FileTime) Files
                    .getAttribute(p, "basic:creationTime")).toMillis();
        } catch (Exception e) { return 0L; }
    }

    public static List<Path> listDir(Path p) {
        List<Path> out = new ArrayList<>();
        if (!isDir(p)) return out;
        try (DirectoryStream<Path> ds = Files.newDirectoryStream(p)) {
            for (Path x : ds) out.add(x);
        } catch (IOException ignored) {}
        return out;
    }

    // ---- time / random ---------------------------------------------------------
    private static final DateTimeFormatter F_HMS = DateTimeFormatter.ofPattern("HH:mm:ss");
    private static final DateTimeFormatter F_STAMP =
            DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    private static final DateTimeFormatter F_JOB = DateTimeFormatter.ofPattern("yyyyMMdd-HHmmss");
    private static final DateTimeFormatter F_ID = DateTimeFormatter.ofPattern("yyyyMMddHHmmss");

    public static String nowHms() { return LocalDateTime.now().format(F_HMS); }
    public static String nowStamp() { return LocalDateTime.now().format(F_STAMP); }
    public static String nowJobId() { return LocalDateTime.now().format(F_JOB); }
    public static String nowId() { return LocalDateTime.now().format(F_ID); }

    private static final Random RNG = new Random();
    public static String randHex24() { return String.format("%06x", RNG.nextInt(0x1000000)); }

    // ---- strings -----------------------------------------------------------------
    public static String trim(String s) {
        if (s == null) return "";
        int a = 0, b = s.length();
        while (a < b && (s.charAt(a) == ' ' || s.charAt(a) == '\t' ||
                         s.charAt(a) == '\r' || s.charAt(a) == '\n')) a++;
        while (b > a && (s.charAt(b - 1) == ' ' || s.charAt(b - 1) == '\t' ||
                         s.charAt(b - 1) == '\r' || s.charAt(b - 1) == '\n')) b--;
        return s.substring(a, b);
    }

    /** split keeping empty fields ("a|" -> ["a",""], "|" -> ["",""]) */
    public static String[] split(String s, char sep) {
        List<String> out = new ArrayList<>();
        int pos = 0;
        while (true) {
            int p = s.indexOf(sep, pos);
            if (p < 0) { out.add(s.substring(pos)); break; }
            out.add(s.substring(pos, p));
            pos = p + 1;
        }
        return out.toArray(new String[0]);
    }

    public static boolean endsWith(String s, String suf) { return s != null && s.endsWith(suf); }
    public static boolean startsWith(String s, String pre) { return s != null && s.startsWith(pre); }
    public static String lower(String s) { return s == null ? "" : s.toLowerCase(Locale.ROOT); }

    public static String baseName(String path) {
        int p = Math.max(path.lastIndexOf('\\'), path.lastIndexOf('/'));
        return p < 0 ? path : path.substring(p + 1);
    }

    public static String stem(String path) {
        String b = baseName(path);
        int p = b.lastIndexOf('.');
        return p < 0 ? b : b.substring(0, p);
    }

    public static String slashes(String p) { return p.replace('\\', '/'); }
}
