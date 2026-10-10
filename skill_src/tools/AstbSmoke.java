/* ============================================================================
 * File        : AstbSmoke.java
 * Author      : ASTB Team
 * Created     : 2026-10-03
 * Version     : 2.1
 * Description : ASTB_Reload 前一键冒烟检查（只读，不修改任何文件）。
 *               取代 tools/astb_smoke.py（Python 原版, 本仓已移除）。
 * Usage:
 *   java tools\AstbSmoke.java [项目根目录]
 *   缺省项目根目录 = 依次尝试: 参数 / 当前目录 / 当前目录下 skill_payload\
 *   / skill_src\ (以 core/menu.il 是否存在判定)。
 *   (skill_src\tools\smoke.bat 已包好: 对 bat 所在目录的上一级做检查,
 *    同一文件被 sync 拷贝到 skill_payload\tools\ 后依旧指向 payload 根)
 *
 * 检查项:
 *   1. 括号平衡    main.il + core 全部 .il + modules 全目录递归 .il，
 *                  字符串/注释感知（; 注释到行尾，" 字符串，反斜杠转义）。
 *                  深度不归零或中途为负 → FAIL。
 *   2. return 无 prog 审计  每个 procedure( 体内出现 return( 而没有
 *                  prog( → WARN（简化静态扫描，允许误报，人工确认）。
 *   3. 内嵌标签    core/menu.il 菜单结构行（v4.3 起内嵌双语）：命令行
 *                  (英文 中文 命令)、popup 行 (popup 英文 中文)；中文
 *                  标签缺失/为空/与英文相同 → FAIL。
 *   4. astb.cfg    config/astb.cfg 同一 key 出现多次 → WARN。
 *   5. C 臆造语法  break/continue/getenv → FAIL（SKILL 无这些关键字）。
 *
 * 退出码: 有任何 FAIL → 1；否则 0（WARN 不影响退出码）。
 * Encoding: 所有 .il/.dat/.cfg 按 GBK 读取（非法字节替换为 U+FFFD,
 *           同 Python errors=replace）；本文件 UTF-8。
 * Revision history:
 *   2026-10-11 v2.1 menu.il v4.3 内嵌双语标签适配: 检查 3 由
 *                  labels_map.dat 格式改为结构行 (英文 中文 命令)
 *                  完整性校验; 项目根判定标记改 core/menu.il
 *   2026-10-03 v2.0 首版 Java 工具链: 移植 astb_smoke.py, 输出逐字对齐
 * ============================================================================
 */
import java.io.IOException;
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;

public class AstbSmoke {

    static final Charset GBK = Charset.forName("GBK");

    /** 关键字 token：procedure(/return(/prog( 各自带一个左括号。 */
    static final Pattern TOKEN_RE = Pattern.compile(
            "procedure\\s*\\(\\s*([A-Za-z0-9_!?]+)?"   // 1: 函数名（可缺）
            + "|return\\s*\\("
            + "|prog\\s*\\("
            + "|\\(|\\)");

    /** C 臆造语法：(?U) 使 \b 与 Python 的 unicode 语义一致。 */
    static final Pattern CISM_RE =
            Pattern.compile("(?U)\\b(?:break|continue)\\b|getenv\\s*\\(");

    public static void main(String[] argv) throws Exception {
        Path root;
        if (argv.length > 0) {
            root = Paths.get(argv[0]).toAbsolutePath();
        } else {
            root = defaultRoot();
        }
        String rootS = root.toString();
        System.out.println("=".repeat(64));
        System.out.printf("ASTB 冒烟检查 (astb_smoke)  项目根目录: %s%n", rootS);
        System.out.println("=".repeat(64));

        boolean anyFail = false;

        // ---- 检查 1 + 2：括号平衡 / return 无 prog ----
        List<Path> files = collectIlFiles(root);
        List<String> fails12 = new ArrayList<>(), warns2 = new ArrayList<>();
        for (Path p : files) {
            String rel = root.relativize(p).toString();
            String[] parenIssues = scanParens(p);
            String[] procWarnings = scanReturnNoProg(p);
            for (String m : parenIssues) fails12.add(rel + ": " + m);
            for (String m : procWarnings) warns2.add(rel + ": " + m);
        }
        System.out.printf("%n[1] 括号平衡（%d 个 .il 文件）%n", files.size());
        if (!fails12.isEmpty()) {
            anyFail = true;
            System.out.println("  FAIL:");
            for (String msg : fails12) System.out.println("    - " + msg);
        } else {
            System.out.println("  PASS  全部文件括号深度归零");
        }

        System.out.printf("%n[2] return 无 prog 审计（警告项需人工确认，允许误报）%n");
        if (!warns2.isEmpty()) {
            System.out.printf("  WARN (%d 项):%n", warns2.size());
            for (String msg : warns2) System.out.println("    - " + msg);
        } else {
            System.out.println("  PASS  未发现 return 无 prog 的 procedure");
        }

        // ---- 检查 3：菜单内嵌双语标签完整性 ----
        List<String> fails3 = checkInlineLabels(root);
        System.out.printf("%n[3] 菜单内嵌双语标签完整性（menu.il v4.3 起）%n");
        if (!fails3.isEmpty()) {
            anyFail = true;
            System.out.println("  FAIL:");
            for (String msg : fails3) System.out.println("    - " + msg);
        } else {
            System.out.printf("  PASS  menu.il 内嵌双语标签行 = %d%n", inlineLabelRows);
        }

        // ---- 检查 4：astb.cfg 重复键 ----
        List<String> warns4 = checkCfgDupkeys(root);
        System.out.printf("%n[4] astb.cfg 重复键%n");
        if (!warns4.isEmpty()) {
            System.out.printf("  WARN (%d 项):%n", warns4.size());
            for (String msg : warns4) System.out.println("    - " + msg);
        } else {
            System.out.println("  PASS  无重复键");
        }

        // ---- 检查 5：C 臆造语法 ----
        List<String> fails5 = checkCIsms(root, files);
        System.out.printf("%n[5] C 臆造语法扫描（break/continue/getenv）%n");
        if (!fails5.isEmpty()) {
            anyFail = true;
            System.out.println("  FAIL:");
            for (String msg : fails5) System.out.println("    - " + msg);
        } else {
            System.out.println("  PASS  未发现 C 臆造语法");
        }

        // ---- 汇总 ----
        System.out.printf("%n" + "=".repeat(64) + "%n");
        System.out.printf("汇总: [1]括号平衡=%s  [2]return无prog=%s  [3]内嵌标签=%s  [4]cfg重复键=%s  [5]C语法=%s%n",
                fails12.isEmpty() ? "PASS" : "FAIL",
                warns2.isEmpty() ? "PASS" : "WARN(" + warns2.size() + ")",
                fails3.isEmpty() ? "PASS" : "FAIL",
                warns4.isEmpty() ? "PASS" : "WARN(" + warns4.size() + ")",
                fails5.isEmpty() ? "PASS" : "FAIL");
        if (anyFail) {
            System.out.println("结果: FAIL（存在失败项，退出码 1）");
            System.exit(1);
        }
        System.out.println("结果: PASS（退出码 0）");
    }

    static Path defaultRoot() {
        Path cwd = Paths.get("").toAbsolutePath();
        if (Files.isRegularFile(cwd.resolve("core").resolve("menu.il"))) return cwd;
        for (String sub : new String[]{"skill_payload", "skill_src"}) {
            Path cand = cwd.resolve(sub);
            if (Files.isRegularFile(cand.resolve("core").resolve("menu.il"))) return cand;
        }
        System.err.println("usage: java tools\\AstbSmoke.java <项目根目录>(含 core/menu.il)");
        System.exit(2);
        return null;
    }

    /** 按 GBK 读取文件，无法解码的字节替换为 U+FFFD（同 Python errors=replace）。 */
    static String readGbk(Path p) throws IOException {
        return new String(Files.readAllBytes(p), GBK);
    }

    /**
     * 全文扫描，把字符串与注释内容替换为空格（换行保留，位置不变）。
     * SKILL 字符串可以跨行，因此必须整文件扫描而不能逐行处理；
     * 字符串内 \ 转义生效（含 \" 与行尾 \<换行>）。
     */
    static String maskCode(String text) {
        char[] out = text.toCharArray();
        int i = 0, n = text.length();
        boolean inStr = false, inComment = false;
        while (i < n) {
            char c = text.charAt(i);
            if (inComment) {
                if (c == '\n') inComment = false;
                else out[i] = ' ';
            } else if (inStr) {
                if (c == '\\') {
                    out[i] = ' ';
                    if (i + 1 < n) {
                        out[i + 1] = (text.charAt(i + 1) != '\n') ? ' ' : '\n';
                        i += 2;
                        continue;
                    }
                } else if (c == '"') {
                    inStr = false;
                    out[i] = ' ';
                } else if (c != '\n') {
                    out[i] = ' ';
                }
            } else {
                if (c == ';') {
                    inComment = true;
                    out[i] = ' ';
                } else if (c == '"') {
                    inStr = true;
                    out[i] = ' ';
                }
            }
            i += 1;
        }
        return new String(out);
    }

    /** 一次扫描同时产出检查 1 与检查 2（括号问题 / return 无 prog 警告）。 */
    static String[][] scanIl(Path path) throws IOException {
        String codeText = maskCode(readGbk(path));
        int depth = 0;
        int minNegLine = -1;
        List<int[]> frames = new ArrayList<>();          // {nameIdx 略, 起始行, openDepth, hasProg}
        List<List<Integer>> frameRets = new ArrayList<>();
        List<String> frameNames = new ArrayList<>();
        List<String> parenIssues = new ArrayList<>();
        List<String> procWarnings = new ArrayList<>();

        String[] lines = codeText.split("\n", -1);
        for (int lineno = 1; lineno <= lines.length; lineno++) {
            Matcher m = TOKEN_RE.matcher(lines[lineno - 1]);
            while (m.find()) {
                String tok = m.group();
                if (tok.startsWith("procedure")) {
                    depth += 1;
                    String name = m.group(1) != null ? m.group(1) : "<匿名>";
                    frames.add(new int[]{lineno, depth, 0});
                    frameRets.add(new ArrayList<>());
                    frameNames.add(name);
                } else if (tok.startsWith("return")) {
                    depth += 1;
                    if (!frames.isEmpty()) frameRets.get(frameRets.size() - 1).add(lineno);
                } else if (tok.startsWith("prog")) {
                    depth += 1;
                    if (!frames.isEmpty()) frames.get(frames.size() - 1)[2] = 1;
                } else if (tok.equals("(")) {
                    depth += 1;
                } else {                              // ")"
                    depth -= 1;
                    if (depth < 0 && minNegLine < 0) minNegLine = lineno;
                    while (!frames.isEmpty() && frames.get(frames.size() - 1)[1] > depth) {
                        int[] fr = frames.remove(frames.size() - 1);
                        List<Integer> rets = frameRets.remove(frameRets.size() - 1);
                        String name = frameNames.remove(frameNames.size() - 1);
                        if (!rets.isEmpty() && fr[2] == 0)
                            procWarnings.add(String.format(
                                "procedure %s (第%d行起): return( 出现于行 %s，体内无 prog(",
                                name, fr[0], joinLines(rets)));
                    }
                }
            }
        }
        if (minNegLine > 0)
            parenIssues.add(String.format("第%d行: 右括号多于左括号（深度变负）", minNegLine));
        if (depth != 0)
            parenIssues.add(String.format("文件结束: 括号深度 = %d（未归零）", depth));
        for (int k = 0; k < frames.size(); k++) {     // 文件结束仍未闭合的帧
            int[] fr = frames.get(k);
            List<Integer> rets = frameRets.get(k);
            if (!rets.isEmpty() && fr[2] == 0)
                procWarnings.add(String.format(
                    "procedure %s (第%d行起，未闭合): return( 出现于行 %s，体内无 prog(",
                    frameNames.get(k), fr[0], joinLines(rets)));
        }
        return new String[][]{parenIssues.toArray(new String[0]), procWarnings.toArray(new String[0])};
    }

    static String joinLines(List<Integer> v) {
        StringBuilder sb = new StringBuilder();
        for (Integer x : v) { if (sb.length() > 0) sb.append(','); sb.append(x); }
        return sb.toString();
    }

    /** 拆开 scanIl 的两个返回值分别取用（保持 Python 版两函数接口形状）。 */
    static String[] scanParens(Path p) throws IOException { return scanIl(p)[0]; }
    static String[] scanReturnNoProg(Path p) throws IOException { return scanIl(p)[1]; }

    /** main.il + core/*.il + modules/ 递归全部 .il（目录按名排序，确定性）。 */
    static List<Path> collectIlFiles(Path root) {
        List<Path> files = new ArrayList<>();
        Path mainIl = root.resolve("main.il");
        if (Files.isRegularFile(mainIl)) files.add(mainIl);
        Path coreDir = root.resolve("core");
        if (Files.isDirectory(coreDir)) {
            try (Stream<Path> s = Files.list(coreDir)) {
                s.filter(Files::isRegularFile)
                 .filter(p -> p.getFileName().toString().toLowerCase().endsWith(".il"))
                 .map(Path::getFileName).map(Path::toString).sorted()
                 .forEach(n -> files.add(coreDir.resolve(n)));
            } catch (IOException ignore) {}
        }
        Path modDir = root.resolve("modules");
        if (Files.isDirectory(modDir)) {
            try (Stream<Path> s = Files.walk(modDir)) {
                s.filter(Files::isRegularFile)
                 .filter(p -> p.getFileName().toString().toLowerCase().endsWith(".il"))
                 .sorted((a, b) -> a.toString().compareTo(b.toString()))
                 .forEach(files::add);
            } catch (IOException ignore) {}
        }
        return files;
    }

    static int inlineLabelRows = 0;

    /** 检查 3：menu.il 菜单结构行内嵌双语标签完整性（v4.3 起，取代 labels_map.dat 格式检查）。 */
    static List<String> checkInlineLabels(Path root) throws IOException {
        Path menuPath = root.resolve("core").resolve("menu.il");
        if (!Files.isRegularFile(menuPath))
            return new ArrayList<>(List.of("core/menu.il: 文件不存在"));
        List<String> fails = new ArrayList<>();
        Pattern popup = Pattern.compile("^\\s+list\\('popup \"([^\"]+)\" \"([^\"]*)\"\\)\\s*$");
        Pattern cmd = Pattern.compile("^\\s+list\\(\"([^\"]+)\" +\"([^\"]*)\" +\"[A-Za-z_0-9]+\"\\)\\s*$");
        String[] lines = readGbk(menuPath).split("\n", -1);
        inlineLabelRows = 0;
        for (int no = 1; no <= lines.length; no++) {
            String line = lines[no - 1];
            Matcher m = popup.matcher(line);
            Matcher c = cmd.matcher(line);
            String en = null, zh = null;
            if (m.matches()) { en = m.group(1); zh = m.group(2); }
            else if (c.matches()) { en = c.group(1); zh = c.group(2); }
            if (en == null) continue;
            inlineLabelRows++;
            if (zh.isBlank()) {
                fails.add(String.format("menu.il:%d 中文标签为空: %s", no, en));
            } else if (zh.equals(en)) {
                fails.add(String.format("menu.il:%d 中文标签与英文键相同: %s", no, en));
            }
        }
        if (inlineLabelRows == 0)
            fails.add("menu.il: 未解析到任何内嵌双语菜单行（结构格式是否被改动？）");
        return fails;
    }

    static List<String> checkCfgDupkeys(Path root) throws IOException {
        Path cfgPath = root.resolve("config").resolve("astb.cfg");
        if (!Files.isRegularFile(cfgPath))
            return new ArrayList<>(List.of("config/astb.cfg: 文件不存在（跳过重复键检查）"));
        var seen = new java.util.LinkedHashMap<String, Integer>();
        List<String> warns = new ArrayList<>();
        String[] lines = readGbk(cfgPath).split("\n", -1);
        for (int lineno = 1; lineno <= lines.length; lineno++) {
            String line = lines[lineno - 1].strip();
            if (line.isEmpty() || line.startsWith("#") || line.startsWith(";")) continue;
            if (!line.contains("=")) continue;
            String key = line.substring(0, line.indexOf('=')).strip();
            if (seen.containsKey(key)) {
                warns.add(String.format("config/astb.cfg: 键 '%s' 重复（第%d行与第%d行）",
                        key, seen.get(key), lineno));
            } else {
                seen.put(key, lineno);
            }
        }
        return warns;
    }

    /** 检查 5：C 臆造语法扫描（break/continue/getenv），基于 mask_code 屏蔽后扫描。 */
    static List<String> checkCIsms(Path root, List<Path> files) throws IOException {
        List<String> fails = new ArrayList<>();
        for (Path path : files) {
            String rel = root.relativize(path).toString();
            String codeText = maskCode(readGbk(path));
            String[] lines = codeText.split("\n", -1);
            for (int lineno = 1; lineno <= lines.length; lineno++) {
                Matcher m = CISM_RE.matcher(lines[lineno - 1]);
                if (m.find())
                    fails.add(String.format("%s: 第%d行: 疑似 C 臆造语法 %s", rel, lineno, m.group()));
            }
        }
        return fails;
    }

    static String trunc(String s, int n) { return s.length() <= n ? s : s.substring(0, n); }
}
