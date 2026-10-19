/* ============================================================================
 * File        : BuildAll.java
 * Author      : ASTB Team
 * Created     : 2026-10-03
 * Version     : 2.0
 * Description : One-shot installer build:
 *                 java\build.bat (javac + jar)
 *                 -> jlink minimal runtime (cached)
 *                 -> jpackage app-image (icon embedded)
 *                 -> Inno Setup ISCC compile
 *               取代 tools/installer/build_all.py（本仓已移除；Python 构建
 *               venv/PyInstaller 是 PySide6 时代的遗产，Java 版无需任何
 *               Python 环境）。
 * Usage:
 *   java tools\installer\BuildAll.java [skill_payload 目录]
 *   (tools\installer\build_all.bat 已包好, 自动找 JDK 21)
 *   缺省 skill payload = <仓库根>\skill_payload（不存在则用 iss 内置默认）。
 * Revision history:
 *   2026-10-03 v2.0 首版 Java 工具链: 移植 build_all.py 全部流程
 * ============================================================================
 */
import java.io.IOException;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.attribute.DosFileAttributeView;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.stream.Stream;

public class BuildAll {

    static final String JDK_BIN = "C:\\Program Files\\Amazon Corretto\\jdk21.0.10_7\\bin";
    // Minimal jlink runtime for the Swing app (jpackage's default binds ~70 modules
    // = ~150 MB; this set is ~45 MB). jdk.charsets = GBK bridge files,
    // jdk.localedata+zh = Chinese system dialogs.
    static final String JLINK_MODULES = "java.base,java.desktop,jdk.charsets,jdk.localedata";
    static final String APP_VERSION = "1.2.1";

    static Path ROOT, JAVA_DIR, RUNTIME_IMG, ISCC, ISS, OUT;

    public static void main(String[] args) throws Exception {
        ROOT = findRepoRoot();
        JAVA_DIR = ROOT.resolve("java");
        RUNTIME_IMG = ROOT.resolve("tools").resolve("runtime-min");
        ISCC = ROOT.resolve("tools").resolve("innosetup").resolve("{app}").resolve("ISCC.exe");
        ISS = ROOT.resolve("tools").resolve("installer").resolve("astb_setup.iss");
        OUT = ROOT.resolve("tools").resolve("installer").resolve("Output");
        Instant t0 = Instant.now();

        // 1) Java studio: build.bat (javac + jar) -> jpackage app-image
        String jpackage = JDK_BIN + "\\jpackage.exe";
        if (!Files.isRegularFile(Paths.get(jpackage))) die("jpackage missing: " + jpackage);
        run(List.of("cmd", "/c", "build.bat"), JAVA_DIR);
        Path jar = JAVA_DIR.resolve("dist").resolve("ASTBStudio.jar");
        if (!Files.isRegularFile(jar)) die("jar missing after build.bat: " + jar);
        Path img = ROOT.resolve("tools").resolve("dist").resolve("ASTBStudio");
        if (Files.isDirectory(img)) rmtreeForce(img);   // jpackage 要求目标目录不存在/为空
        // minimal runtime via jlink (cached; rebuild only if missing)
        if (!Files.isRegularFile(RUNTIME_IMG.resolve("bin").resolve("java.exe"))) {
            if (Files.isDirectory(RUNTIME_IMG)) rmtreeForce(RUNTIME_IMG);
            run(List.of(JDK_BIN + "\\jlink.exe",
                    "--add-modules", JLINK_MODULES,
                    "--include-locales=zh,en", "--strip-debug",
                    "--no-man-pages", "--no-header-files",
                    // NOTE: no --compress on purpose - a pre-zipped jimage makes
                    // Inno's LZMA LESS effective (50 MB vs 45 MB installer).
                    "--output", RUNTIME_IMG.toString()), ROOT);
        }
        List<String> jp = new ArrayList<>(List.of(jpackage,
                "--type", "app-image", "--name", "ASTBStudio",
                "--input", JAVA_DIR.resolve("dist").toString(),
                "--main-jar", "ASTBStudio.jar", "--main-class", "astb.studio.Main",
                // 安装后应用/快捷方式图标（exe 内嵌 -> 资源管理器/任务栏/快捷方式）
                "--icon", ROOT.resolve("tools").resolve("installer").resolve("astb.ico").toString(),
                "--dest", ROOT.resolve("tools").resolve("dist").toString(),
                "--runtime-image", RUNTIME_IMG.toString(),
                // Java2D D3D pipeline can wedge machine-wide (driver hiccup/sleep-resume)
                // leaving every Swing window blank; software rendering is immune and
                // plenty fast for this UI.
                "--java-options", "-Dsun.java2d.d3d=false",
                "--app-version", APP_VERSION, "--vendor", "ASTB Team"));
        run(jp, ROOT);
        Path dist = img.resolve("ASTBStudio.exe");
        if (!Files.isRegularFile(dist)) die("jpackage output missing: " + dist);
        System.out.println("studio app-image ok: " + dist);

        // 2) Inno compile
        if (!Files.isRegularFile(ISCC)) die("ISCC missing: " + ISCC);
        Files.createDirectories(OUT);
        List<String> iscc = new ArrayList<>(List.of(ISCC.toString(), "/Qp"));
        Path src = skillPayload(args);
        if (src != null) {
            if (!Files.isDirectory(src)) die("skill payload dir missing: " + src);
            iscc.add("/DSkillSrc=" + src);
            System.out.println("skill payload: " + src);
        } else {
            System.out.println("skill payload: iss default (D:\\Cadence\\allegro_skill)");
        }
        iscc.add(ISS.toString());
        run(iscc, ROOT);
        try (DirectoryStream<Path> ds = Files.newDirectoryStream(OUT, "*.exe")) {
            for (Path p : ds) {
                double mb = Files.size(p) / 1048576.0;
                System.out.printf(Locale.ROOT, "installer: %s (%.1f MB)%n", p, mb);
            }
        }
        System.out.printf("done in %.0fs%n", 0.001 * Duration.between(t0, Instant.now()).toMillis());
    }

    /** Skill payload dir packed into the installer. Priority:
     *  1) argv[0] (explicit path)  2) <ROOT>/skill_payload  3) iss default. */
    static Path skillPayload(String[] args) {
        if (args.length > 0) return Paths.get(args[0]).toAbsolutePath();
        Path cand = ROOT.resolve("skill_payload");
        return Files.isDirectory(cand) ? cand : null;
    }

    static Path findRepoRoot() {
        Path dir = Paths.get("").toAbsolutePath();
        while (dir != null) {
            if (Files.isRegularFile(dir.resolve("java").resolve("build.bat"))
                    && Files.isDirectory(dir.resolve("tools").resolve("innosetup")))
                return dir;
            dir = dir.getParent();
        }
        System.err.println("error: 未找到仓库根(需存在 java\\build.bat 与 tools\\innosetup), 请在仓库内运行");
        System.exit(2);
        return null;
    }

    static void run(List<String> cmd, Path cwd) throws IOException, InterruptedException {
        System.out.println(">> " + String.join(" ", cmd));
        Process p = new ProcessBuilder(cmd).directory(cwd.toFile()).inheritIO().start();
        if (p.waitFor() != 0) System.exit(p.exitValue());
    }

    /** jpackage marks its launcher exe read-only -> plain delete hits WinError 5. */
    static void rmtreeForce(Path root) throws IOException {
        try (Stream<Path> stream = Files.walk(root)) {
            stream.sorted(java.util.Comparator.reverseOrder()).forEach(p -> {
                try {
                    DosFileAttributeView dos = Files.getFileAttributeView(p, DosFileAttributeView.class);
                    if (dos != null) dos.setReadOnly(false);
                    Files.deleteIfExists(p);
                } catch (IOException ignore) {}
            });
        }
    }

    static void die(String msg) {
        System.err.println(msg);
        System.exit(1);
    }
}
