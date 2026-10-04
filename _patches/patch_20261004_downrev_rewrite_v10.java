/* ============================================================================
 * File        : patch_20261004_downrev_rewrite_v10.java
 * Author      : ASTB Team
 * Created     : 2026-10-04
 * Version     : 1.0
 * Description : 降版本功能重新上线——模块全新重写 + 引用恢复。
 *               背景: 用户决策 git 版 util_downrev17（v3.x 系列）有实机
 *               问题，不用 git 版；网上亦无可用现成 SKILL 源码（社区
 *               方案均为 exe 批处理/数据桥，本仓内置运行时即阿狸狗
 *               同款免补丁构建）。故按社区通行做法全新重写：
 *               1) skill_src/modules/utilities/util_downrev166.il v1.0
 *                  由本补丁同目录 payload(UTF-8) 显式转 GBK 生成,
 *                  删除旧模块 util_downrev17.il（src+payload）
 *               2) core/menu.il v4.0 -> v4.1：恢复 Downrev 菜单项
 *               3) core/labels_map.dat：恢复 Downrev to 1&6.6 标签行
 *               4) core/help_map.dat：恢复 ASTB_Util_Downrev166 帮助行
 *               5) tools/installer/astb_setup.iss：恢复 downrev166_rt 打包行
 *               6) README.md / ASTB功能说明.md：恢复降版本功能引用
 * Usage       : "C:\Program Files\Amazon Corretto\jdk21.0.10_7\bin\java.exe" ^
 *                 _patches\patch_20261004_downrev_rewrite_v10.java
 * Encoding    : 本文件 UTF-8；GBK 文件显式 Charset.forName("GBK") 往返。
 * ============================================================================
 */
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;

public class patch_20261004_downrev_rewrite_v10 {

    static final Charset GBK = Charset.forName("GBK");
    static final Charset UTF8 = Charset.forName("UTF-8");
    static final Charset LATIN1 = Charset.forName("ISO-8859-1");
    static final Path ROOT = Paths.get("G:/ASTB");

    static class Edit {
        final String oldS, newS;
        Edit(String o, String n) { oldS = o; newS = n; }
    }

    static String read(Path p, Charset cs) throws Exception {
        return new String(Files.readAllBytes(p), cs);
    }

    static void write(Path p, Charset cs, String s) throws Exception {
        Files.write(p, s.getBytes(cs));
    }

    /** crlf 感知读改写：内部一律 \n 编辑，写盘恢复原行尾风格。 */
    static String load(Path p, Charset cs) throws Exception {
        String t = read(p, cs);
        return t.replace("\r\n", "\n");
    }

    static void save(Path p, Charset cs, String t, boolean crlf) throws Exception {
        if (crlf) t = t.replace("\n", "\r\n");
        write(p, cs, t);
        String back = read(p, cs);
        if (!back.equals(crlf ? t.replace("\n", "\r\n") : t)) {
            // back 读回带原始行尾，直接比 Unicode 内容
            if (!back.replace("\r\n", "\n").equals(t.replace("\r\n", "\n"))) {
                throw new RuntimeException("roundtrip mismatch: " + p);
            }
        }
    }

    static void applyEdits(String tag, String srcText, List<Edit> edits) {
        for (int i = 0; i < edits.size(); i++) {
            Edit e = edits.get(i);
            int n = countOccur(srcText, e.oldS);
            if (n != 1) {
                throw new RuntimeException(tag + " EDIT " + (i + 1) + ": anchor found " + n + " times, ABORT");
            }
            srcText = srcText.replaceFirst(java.util.regex.Pattern.quote(e.oldS), java.util.regex.Matcher.quoteReplacement(e.newS));
        }
    }

    static String applyEditsRet(String tag, String srcText, List<Edit> edits) {
        String s = srcText;
        for (int i = 0; i < edits.size(); i++) {
            Edit e = edits.get(i);
            int n = countOccur(s, e.oldS);
            if (n != 1) {
                throw new RuntimeException(tag + " EDIT " + (i + 1) + ": anchor found " + n + " times, ABORT");
            }
            s = s.replaceFirst(java.util.regex.Pattern.quote(e.oldS), java.util.regex.Matcher.quoteReplacement(e.newS));
        }
        return s;
    }

    static int countOccur(String hay, String needle) {
        int c = 0, i = 0;
        while ((i = hay.indexOf(needle, i)) >= 0) { c++; i += needle.length(); }
        return c;
    }

    /** SKILL 括号平衡（字符串/注释状态机，转义感知），与 astb_smoke mask_code 同约定。 */
    static void checkParen(String tag, String srcText) {
        int depth = 0;
        boolean inStr = false, inComment = false, esc = false;
        for (int i = 0; i < srcText.length(); i++) {
            char ch = srcText.charAt(i);
            if (inComment) {
                if (ch == '\n') inComment = false;
                continue;
            }
            if (inStr) {
                if (esc) esc = false;
                else if (ch == '\\') esc = true;
                else if (ch == '"') inStr = false;
                continue;
            }
            if (ch == '"') inStr = true;
            else if (ch == ';') inComment = true;
            else if (ch == '(') depth++;
            else if (ch == ')') {
                depth--;
                if (depth < 0) throw new RuntimeException(tag + " paren NEGATIVE, ABORT");
            }
        }
        if (depth != 0 || inStr) throw new RuntimeException(tag + " UNBALANCED (depth=" + depth + " inStr=" + inStr + "), ABORT");
    }

    static void checkNoCR(String tag, String srcText) {
        if (srcText.indexOf('\r') >= 0) throw new RuntimeException(tag + " residue \\r found, ABORT");
    }

    public static void main(String[] args) throws Exception {

        // ---------------------------------------------------------------- 1
        // 新模块 util_downrev166.il：payload(UTF-8) -> GBK 落盘
        Path payload = ROOT.resolve("_patches/patch_20261004_downrev_rewrite_v10_payload.il");
        Path modDst = ROOT.resolve("skill_src/modules/utilities/util_downrev166.il");
        String mod = read(payload, UTF8);
        checkNoCR("module", mod);
        checkParen("module", mod);
        // GBK 可逆抽查：全部内容必须可 GBK 往返（含中文注释/字符串）
        byte[] gbkBytes = mod.getBytes(GBK);
        String back = new String(gbkBytes, GBK);
        if (!back.equals(mod)) throw new RuntimeException("module GBK roundtrip mismatch, ABORT");
        Files.write(modDst, gbkBytes);
        System.out.println("OK: util_downrev166.il written (GBK, " + gbkBytes.length + " bytes)");

        // 删除旧模块（src + payload）
        for (String rel : new String[]{
                "skill_src/modules/utilities/util_downrev17.il",
                "skill_payload/modules/utilities/util_downrev17.il"}) {
            Path p = ROOT.resolve(rel);
            if (Files.deleteIfExists(p)) System.out.println("OK: deleted " + rel);
        }

        // ---------------------------------------------------------------- 2
        // menu.il v4.0 -> v4.1，恢复 Downrev 菜单项
        Path menu = ROOT.resolve("skill_src/core/menu.il");
        boolean menuCrLf = read(menu, GBK).contains("\r\n");
        String m = load(menu, GBK);
        List<Edit> me = new ArrayList<>();
        me.add(new Edit("; 版本      : 4.0\n", "; 版本      : 4.1\n"));
        me.add(new Edit(
            ";   2026-10-04 v4.0 ASTB Team 删除 Downrev to 16.6 菜单项\n",
            ";   2026-10-04 v4.1 ASTB Team 恢复 Downrev to 16.6 菜单项\n" +
            ";                     （用户要求重新上线；模块全新重写为\n" +
            ";                     util_downrev166.il v1.0 取代 util_downrev17，\n" +
            ";                     同步恢复标签/帮助/安装包/文档引用）\n" +
            ";   2026-10-04 v4.0 ASTB Team 删除 Downrev to 16.6 菜单项\n"));
        me.add(new Edit(
            "    list(\"H&otkey Editor\"      \"H&otkey Editor\"       \"ASTB_Util_HotkeyEditor\")\n",
            "    list(\"H&otkey Editor\"      \"H&otkey Editor\"       \"ASTB_Util_HotkeyEditor\")\n" +
            "    list(\"Downrev to 1&6.6\"    \"Downrev to 1&6.6\"     \"ASTB_Util_Downrev166\")\n"));
        m = applyEditsRet("menu.il", m, me);
        checkParen("menu.il", m);
        checkNoCR("menu.il", m);
        save(menu, GBK, m, menuCrLf);
        System.out.println("OK: menu.il v4.1, downrev menu line restored");

        // ---------------------------------------------------------------- 3
        // labels_map.dat 恢复标签行
        Path labels = ROOT.resolve("skill_src/core/labels_map.dat");
        boolean labelsCrLf = read(labels, GBK).contains("\r\n");
        String lm = load(labels, GBK);
        lm = applyEditsRet("labels_map.dat", lm, List.of(new Edit(
            "Arro&w Copy=方向键等距复制(&w)\n",
            "Arro&w Copy=方向键等距复制(&w)\n" +
            "Downrev to 1&6.6=降版本到16.6(&6)\n")));
        checkNoCR("labels_map.dat", lm);
        save(labels, GBK, lm, labelsCrLf);
        System.out.println("OK: labels_map.dat downrev entry restored");

        // ---------------------------------------------------------------- 4
        // help_map.dat 恢复帮助行
        Path help = ROOT.resolve("skill_src/core/help_map.dat");
        boolean helpCrLf = read(help, GBK).contains("\r\n");
        String hm = load(help, GBK);
        String helpAnchor = "ASTB_Util_HotkeyHelp|在命令窗口打印快捷键配置表|①直接运行 ②命令窗口列出全部键位、对应命令、说明及当前绑定状态|HotkeySetup_PrintHelp：printf 遍历 g_hotkeyConfig 打印配置表与 hotkey_bind/reset/help 用法（modules/utilities/util_hotkeysetup.il）\n";
        String helpNew = "ASTB_Util_Downrev166|把当前 PCB 降版本保存为 16.6|①直接运行 ②自动保存当前设计，复制 <板名>_166.brd 副本后用自带免补丁运行时原地转 16.6，原文件不动（24.x/25.x 会话先新实例批处理驱动原生 Downrev 对话框存出 17.4 中间文件再转）③转换会丢失 17.x 新特性数据；失败仅命令行留痕，原因见输出目录同名 .log|_DR166_Main 定位 tools/downrev166_rt/tools/bin/allegro_downrev_library.exe（DOWNREV_17_TO_16=1 放开 brd/dra，自有 DLL 目录置顶 PATH），axlOSFileCopy 副本后经临时 bat 调 exe（modules/utilities/util_downrev166.il）\n";
        hm = applyEditsRet("help_map.dat", hm, List.of(new Edit(helpAnchor, helpAnchor + helpNew)));
        checkNoCR("help_map.dat", hm);
        save(help, GBK, hm, helpCrLf);
        System.out.println("OK: help_map.dat downrev entry restored");

        // ---------------------------------------------------------------- 5
        // astb_setup.iss 恢复 downrev166_rt 打包行（ISO-8859-1 字节安全）
        Path iss = ROOT.resolve("tools/installer/astb_setup.iss");
        boolean issCrLf = read(iss, LATIN1).contains("\r\n");
        String im = load(iss, LATIN1);
        im = applyEditsRet("astb_setup.iss", im, List.of(new Edit(
            "Source: \"{#SkillSrc}\\tools\\*.bat\"; DestDir: \"{app}\\skill\\tools\"; Flags: ignoreversion skipifsourcedoesntexist\n",
            "Source: \"{#SkillSrc}\\tools\\*.bat\"; DestDir: \"{app}\\skill\\tools\"; Flags: ignoreversion skipifsourcedoesntexist\n" +
            "Source: \"{#SkillSrc}\\tools\\downrev166_rt\\*\"; DestDir: \"{app}\\skill\\tools\\downrev166_rt\"; Flags: ignoreversion recursesubdirs skipifsourcedoesntexist\n")));
        save(iss, LATIN1, im, issCrLf);
        System.out.println("OK: astb_setup.iss downrev166_rt source line restored");

        // ---------------------------------------------------------------- 6
        // README.md 恢复降版本功能枚举（UTF-8）
        Path readme = ROOT.resolve("README.md");
        boolean rdCrLf = read(readme, UTF8).contains("\r\n");
        String rd = load(readme, UTF8);
        rd = applyEditsRet("README.md", rd, List.of(new Edit(
            "  项目/最近文件、快捷键表、帮助、体检、热键等）\n",
            "  项目/最近文件、快捷键表、帮助、体检、降版本、热键等）\n")));
        save(readme, UTF8, rd, rdCrLf);
        System.out.println("OK: README.md feature enumeration restored");

        // ---------------------------------------------------------------- 7
        // ASTB功能说明.md 恢复 Utilities 表行（UTF-8）
        Path doc = ROOT.resolve("ASTB功能说明.md");
        boolean docCrLf = read(doc, UTF8).contains("\r\n");
        String dc = load(doc, UTF8);
        dc = applyEditsRet("ASTB功能说明.md", dc, List.of(new Edit(
            "| 配色方案 | FYCOL/FYCOL1/FYCOL2 三套整层颜色一键切换 |\n",
            "| 配色方案 | FYCOL/FYCOL1/FYCOL2 三套整层颜色一键切换 |\n" +
            "| PCB 降版本 16.6 | 自带免补丁运行时 downrev166_rt 原地转 16.6；24.x 新实例批处理两跳（先存 17.4 中间文件再转）；失败原因见输出目录同名 .log |\n")));
        save(doc, UTF8, dc, docCrLf);
        System.out.println("OK: ASTB功能说明.md downrev row restored");

        System.out.println("ALL OK");
    }
}
