// ============================================================================
// 文件名    : patch_20261011_menu_inline_i18n.java
// 作者      : ASTB Team
// 创建日期  : 2026-10-11
// 功能描述  : 菜单 i18n 改内嵌双语（menu.il v4.3）：
//               1) core/menu.il：结构行 (英文 英文 命令) 改 (英文 中文
//                  命令)（中文取自 labels_map.dat 映射合并）；popup 行
//                  同理；标签取值函数改直接取字段；删除
//                  ASTB_LoadChineseLabels/ASTB_ZH_GET/ASTB_ZH_LABELS
//                  与启动加载块；版本 4.2 -> 4.3。
//               2) modules/utilities/util_bridge.il v1.5：菜单树导出
//                  直接取内嵌中文字段，删 ASTB_BridgeZhOrSelf。
//               3) core/zz_smoke.il v1.1：标签检查改内嵌完整性校验。
//               4) 删除 core/labels_map.dat 与 core/labels_raw.dat。
//             AstbSmoke.java / AGENTS.md / README / 功能说明 为 UTF-8，
//             由编辑器直改不走本脚本。GBK 显式往返；锚点缺失即中止。
// 运行      : java -Dfile.encoding=UTF-8 patch_20261011_menu_inline_i18n.java
// ============================================================================
import java.io.IOException;
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.LinkedHashMap;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class patch_20261011_menu_inline_i18n {
    static final Charset GBK = Charset.forName("GBK");
    static final Path SRC = Paths.get("G:/ASTB/skill_src");

    public static void main(String[] args) throws Exception {
        LinkedHashMap<String, String> zh = null;
        Path datMap = SRC.resolve("core/labels_map.dat");
        if (Files.isRegularFile(datMap)) zh = loadLabels();
        patchMenuIl(zh);
        patchBridge();
        patchZzSmoke();
        Files.deleteIfExists(SRC.resolve("core/labels_map.dat"));
        Files.deleteIfExists(SRC.resolve("core/labels_raw.dat"));
        System.out.println("ALL PATCHES APPLIED");
    }

    static String readGbk(Path p) throws IOException {
        return new String(Files.readAllBytes(p), GBK);
    }

    static void writeGbk(Path p, String s) throws IOException {
        if (s.contains("\r")) throw new RuntimeException("CR not allowed: " + p);
        Files.write(p, s.getBytes(GBK));
    }

    static String replaceOnce(String content, String anchor, String replacement, String what) {
        int i = content.indexOf(anchor);
        if (i < 0) throw new RuntimeException("ANCHOR NOT FOUND: " + what);
        if (content.indexOf(anchor, i + anchor.length()) >= 0)
            throw new RuntimeException("ANCHOR NOT UNIQUE: " + what);
        return content.substring(0, i) + replacement + content.substring(i + anchor.length());
    }

    // 删除 [startMark 所在注释块的 ;--- 行, endMark 所在注释块的 ;--- 行) 区间
    static String deleteBlockRange(String c, String startMark, String endMark, String what) {
        int si = c.indexOf(startMark);
        if (si < 0) throw new RuntimeException("BLOCK START NOT FOUND: " + what);
        int ei = c.indexOf(endMark, si);
        if (ei < 0) throw new RuntimeException("BLOCK END NOT FOUND: " + what);
        // 各自回溯到上一行（;---- 分隔行）的行首
        int s = lineStart(c, lineStart(c, si) - 1);
        int e = lineStart(c, lineStart(c, ei) - 1);
        String head = c.substring(s, s + 4);
        String tail = c.substring(e, e + 4);
        if (!head.startsWith(";--") || !tail.startsWith(";--"))
            throw new RuntimeException("BLOCK BOUNDARY NOT A SEPARATOR: " + what);
        return c.substring(0, s) + c.substring(e);
    }

    static int lineStart(String c, int idx) {
        return c.lastIndexOf('\n', idx - 1) + 1;
    }

    static LinkedHashMap<String, String> loadLabels() throws IOException {
        var map = new LinkedHashMap<String, String>();
        for (String ln : readGbk(SRC.resolve("core/labels_map.dat")).split("\n", -1)) {
            String t = ln.strip();
            if (t.isEmpty() || t.startsWith(";") || t.startsWith("#")) continue;
            int eq = t.indexOf('=');
            if (eq > 0) map.put(t.substring(0, eq).strip(), t.substring(eq + 1).strip());
        }
        System.out.println("[0] labels loaded: " + map.size());
        return map;
    }

    // ---- 1) core/menu.il ----
    static void patchMenuIl(LinkedHashMap<String, String> zh) throws IOException {
        Path f = SRC.resolve("core/menu.il");
        String c = readGbk(f);
        if (c.contains("内嵌双语")) {
            System.out.println("[1] menu.il already patched, skip");
            return;
        }
        if (zh == null) throw new RuntimeException("labels_map.dat missing; cannot merge rows");

        // 1a 头：版本 + 修订记录 + 依赖
        c = replaceOnce(c, "; 版本      : 4.2", "; 版本      : 4.3", "menu.il version");
        c = replaceOnce(c,
            "; 修改记录  :\n;   2026-10-11 v4.2",
            "; 修改记录  :\n"
                + ";   2026-10-11 v4.3 ASTB Team 菜单标签改内嵌双语（结构行\n"
                + ";                     （英文标签 中文标签 命令名），popup 行\n"
                + ";                     （popup 英文 中文））；中文由 sync 八进制\n"
                + ";                     转义兜底 16.6 reader，运行时字节与原\n"
                + ";                     labels_map.dat 路径一致，显示效果不变；\n"
                + ";                     删除 ASTB_LoadChineseLabels/ASTB_ZH_GET/\n"
                + ";                     ASTB_ZH_LABELS 与 labels_map.dat 外置数据源\n"
                + ";   2026-10-11 v4.2",
            "menu.il revision");
        c = replaceOnce(c,
            "; 依赖模块  : core/utils.il、core/config.il、core/version_adapter.il、\n"
                + ";             core/trans.il、core/labels_map.dat（GBK 中文标签数据，键=标签同行）",
            "; 依赖模块  : core/utils.il、core/config.il、core/version_adapter.il、\n"
                + ";             core/trans.il",
            "menu.il deps");

        // 1b 结构行合并（逐行正则，保留原列距）
        StringBuilder sb = new StringBuilder();
        int nPopup = 0, nCmd = 0;
        Pattern pop = Pattern.compile("^(\\s+)list\\('popup \"([^\"]+)\" \"\\2\"\\)(\\s*)$");
        Pattern cmd = Pattern.compile("^(\\s+)list\\(\"([^\"]+)\" +\"\\2\"( +)\"([A-Za-z_0-9]+)\"\\)(\\s*)$");
        for (String line : c.split("\n", -1)) {
            Matcher m = pop.matcher(line);
            Matcher mc = cmd.matcher(line);
            if (m.matches()) {
                String z = zh.get(m.group(2));
                if (z == null) throw new RuntimeException("no zh label for popup: " + m.group(2));
                line = m.group(1) + "list('popup \"" + m.group(2) + "\" \"" + z + "\")" + m.group(3);
                nPopup++;
            } else if (mc.matches()) {
                String z = zh.get(mc.group(2));
                if (z == null) throw new RuntimeException("no zh label for cmd: " + mc.group(2));
                line = mc.group(1) + "list(\"" + mc.group(2) + "\" \"" + z + "\"" + mc.group(3)
                    + "\"" + mc.group(4) + "\")" + mc.group(5);
                nCmd++;
            }
            sb.append(line).append('\n');
        }
        sb.setLength(sb.length() - 1); // split 保留的尾换行还原
        c = sb.toString();
        System.out.println("[1] rows merged: popup=" + nPopup + " cmd=" + nCmd);
        if (nPopup + nCmd != 83) throw new RuntimeException("expect 83 rows, got " + (nPopup + nCmd));

        // 1c 结构备注
        c = replaceOnce(c,
            "; 备注    : 命令项格式 (英文标签 英文标签 命令名)；本结构与 i18n keys\n"
                + ";           列表是两份手工同步的数据，修改时注意同步",
            "; 备注    : 命令项格式 (英文标签 中文标签 命令名)，popup 项\n"
                + ";           (popup 英文标签 中文标签)；v4.3 起中文标签内嵌\n"
                + ";           本结构（取代 labels_map.dat 外置数据源）",
            "menu.il structure remark");

        // 1d 删 ZH_LABELS defvar 行
        c = replaceOnce(c,
            "defvar(ASTB_ZH_LABELS makeTable('ASTB_ZH_LABELS nil))\n", "",
            "menu.il ZH_LABELS defvar");

        // 1e 删 LoadChineseLabels + ZH_GET 两个相邻函数块（含注释头）
        c = deleteBlockRange(c,
            "; 函数名  : ASTB_LoadChineseLabels",
            "; 函数名  : ASTB_IsLanguageEnglish",
            "menu.il label loaders");

        // 1f 标签取值函数改直接取字段
        c = replaceOnce(c,
            "procedure( ASTB_MenuGetPopupLabel(item)\n"
                + "  if( ASTB_IsLanguageEnglish() then cadr(item) else ASTB_ZH_GET(cadr(item)) )\n"
                + ")",
            "procedure( ASTB_MenuGetPopupLabel(item)\n"
                + "  if( ASTB_IsLanguageEnglish() then cadr(item) else caddr(item) )\n"
                + ")",
            "menu.il popup getter");
        c = replaceOnce(c,
            "procedure( ASTB_MenuGetCommandLabel(item)\n"
                + "  if( ASTB_IsLanguageEnglish() then car(item) else ASTB_ZH_GET(car(item)) )\n"
                + ")",
            "procedure( ASTB_MenuGetCommandLabel(item)\n"
                + "  if( ASTB_IsLanguageEnglish() then car(item) else cadr(item) )\n"
                + ")",
            "menu.il cmd getter");

        // 1g 注入查重的中文标签改取内嵌结构顶层 popup
        c = replaceOnce(c,
            "    zhLabel = ASTB_ZH_GET(\"allegro_s&kill_toolbox\")",
            "    ;; v4.3：中文标签取自内嵌结构顶层 popup 第三字段\n"
                + "    zhLabel = caddr(car(ASTB_GetMenuStructure()))",
            "menu.il injected-check zhLabel");

        // 1h 删启动加载块
        String mark = ";; Load Chinese labels at startup";
        int mi = c.indexOf(mark);
        if (mi < 0) throw new RuntimeException("ANCHOR NOT FOUND: menu.il bottom loader");
        int s = lineStart(c, lineStart(c, mi) - 1);
        if (!c.substring(s, s + 4).startsWith(";;="))
            throw new RuntimeException("bottom loader boundary bad");
        int e = c.indexOf("errset(ASTB_SetupMenuTriggers() t)", mi);
        if (e < 0) throw new RuntimeException("bottom loader end not found");
        c = c.substring(0, s) + c.substring(e);

        writeGbk(f, c);
        System.out.println("[1] patched " + f);
    }

    // ---- 2) util_bridge.il（纯 ASCII 文件，禁入中文） ----
    static void patchBridge() throws IOException {
        Path f = SRC.resolve("modules/utilities/util_bridge.il");
        String c = readGbk(f);
        if (!c.contains("ASTB_BridgeZhOrSelf")) {
            System.out.println("[2] bridge already patched, skip");
            return;
        }

        c = replaceOnce(c, "; Version     : 1.4", "; Version     : 1.5", "bridge version");
        c = replaceOnce(c,
            ";               axlUIWTimer; cleared by the next normal heartbeat)\n;",
            ";               axlUIWTimer; cleared by the next normal heartbeat)\n"
                + ";   2026-10-11 v1.5 menu.il v4.3 inline dual labels: menu tree\n"
                + ";               export reads zh straight from structure fields;\n"
                + ";               zh resolver wrapper (ASTB_ZH_GET based) removed\n;",
            "bridge revision");
        c = replaceOnce(c,
            ";               (ASTB_GetMenuStructure / ASTB_MenuIs* / ASTB_ZH_GET)",
            ";               (ASTB_GetMenuStructure / ASTB_MenuIs*)",
            "bridge deps");

        // 删 ASTB_BridgeZhOrSelf 函数
        c = replaceOnce(c,
            "procedure( ASTB_BridgeZhOrSelf(en)\n"
                + "  prog((r zh)\n"
                + "    zh = en\n"
                + "    r = errset(zh = ASTB_ZH_GET(en))\n"
                + "    unless( and( r stringp(zh) ) zh = en )\n"
                + "    return(zh)\n"
                + "  ))\n\n",
            "",
            "bridge ZhOrSelf proc");

        // 菜单树导出直接取字段
        c = replaceOnce(c,
            "list(\"popup\" cadr(item) ASTB_BridgeZhOrSelf(cadr(item)))",
            "list(\"popup\" cadr(item) caddr(item))",
            "bridge popup node");
        c = c.replaceAll(
            "list\\(\"command\" car\\(item\\) ASTB_BridgeZhOrSelf\\(car\\(item\\)\\)\\s+caddr\\(item\\)\\)",
            "list(\"command\" car(item) cadr(item) caddr(item))");
        if (c.contains("ASTB_BridgeZhOrSelf"))
            throw new RuntimeException("bridge ZhOrSelf residue");
        writeGbk(f, c);
        System.out.println("[2] patched " + f);
    }

    // ---- 3) zz_smoke.il ----
    static void patchZzSmoke() throws IOException {
        Path f = SRC.resolve("core/zz_smoke.il");
        String c = readGbk(f);
        if (!c.contains("ASTB_ZH_LABELS")) {
            System.out.println("[3] zz_smoke already patched, skip");
            return;
        }

        c = replaceOnce(c, "; 版本      : 1.0", "; 版本      : 1.1", "zz_smoke version");
        c = replaceOnce(c,
            ";             2) labels_map.dat 与菜单结构命令键对齐检查",
            ";             2) 菜单结构内嵌中文标签完整性检查（v4.3 起标签内嵌）",
            "zz_smoke desc");
        c = replaceOnce(c,
            ";             ASTB_MenuGetCommand / ASTB_ZH_LABELS)、core/trans.il",
            ";             ASTB_MenuGetCommand)、core/trans.il",
            "zz_smoke deps");
        c = replaceOnce(c,
            "; 修改记录  :\n;   2026-08-01 v1.0 ASTB Team 初始创建",
            "; 修改记录  :\n"
                + ";   2026-10-11 v1.1 ASTB Team 标签检查适配 menu.il v4.3 内嵌双语\n"
                + ";   2026-08-01 v1.0 ASTB Team 初始创建",
            "zz_smoke revision");

        String newFn =
            ";------------------------------------------------------------------------\n"
            + "; 函数    : ASTB_SmokeCheckLabels\n"
            + "; 功能    : 菜单结构内嵌中文标签完整性检查（v4.3 起标签内嵌结构行，\n"
            + ";           cadr 即中文标签）；标签非空且不同于英文键才算有效\n"
            + "; 返回    : 标签异常的英文键列表（nil = 全部通过）\n"
            + ";------------------------------------------------------------------------\n"
            + "procedure( ASTB_SmokeCheckLabels()\n"
            + "    prog( (menuList item key zh missing total)\n"
            + "        missing = nil\n"
            + "        total = 0\n"
            + "        menuList = ASTB_GetMenuStructure()\n"
            + "        foreach( item menuList\n"
            + "            when( ASTB_MenuIsCommand(item)\n"
            + "                total = total + 1\n"
            + "                key = car(item)\n"
            + "                zh = cadr(item)\n"
            + "                when( or(null(zh) not(stringp(zh)) equal(zh \"\") equal(zh key))\n"
            + "                    missing = cons(key missing)\n"
            + "                    axlUIWPrint(nil \"  [WARN] 菜单项中文标签缺失/无效: %s\" key)\n"
            + "                )\n"
            + "            )\n"
            + "        )\n"
            + "        if( missing then\n"
            + "            axlUIWPrint(nil \"  [WARN] 内嵌标签: %d / %d 个命令项标签异常\"\n"
            + "                length(missing) total)\n"
            + "        else\n"
            + "            axlUIWPrint(nil \"  [OK] 内嵌标签: %d 个命令项全部带中文标签\" total)\n"
            + "        )\n"
            + "        return( reverse(missing) )\n"
            + "    )\n"
            + ")\n\n";
        c = deleteBlockRange(c,
            "; 函数    : ASTB_SmokeCheckLabels",
            "; 函数    : ASTB_SmokeCheckForms",
            "zz_smoke CheckLabels");
        // deleteBlockRange 删掉了旧块，把新块插到 CheckForms 注释块前
        int at = c.indexOf("; 函数    : ASTB_SmokeCheckForms");
        int s = lineStart(c, at - 1); // ;---- 行
        c = c.substring(0, s) + newFn + c.substring(s);
        if (c.contains("ASTB_ZH_LABELS")) throw new RuntimeException("zz_smoke ZH_LABELS residue");
        writeGbk(f, c);
        System.out.println("[3] patched " + f);
    }
}
