// patch_20261011_menucn_v10.java
// 菜单汉化模块接入：menu.il v4.5 -> v4.6（System 菜单加 Menu CN/Menu EN），
// help_map.dat 加两条目；配套新模块 util_menucn.il v1.0 + config/menucn_zh.dat
// （后两者已就位，本脚本只管 menu.il 与 help_map）。
// GBK 显式往返；锚点缺失即中止；幂等可重入。
// 运行：java -Dfile.encoding=UTF-8 _patches/patch_20261011_menucn_v10.java
import java.nio.charset.Charset;
import java.nio.file.*;

public class patch_20261011_menucn_v10 {
    static final Charset GBK = Charset.forName("GBK");
    static int applied = 0, skipped = 0;

    static String rep(String src, String oldS, String newS, String tag) {
        int idx = src.indexOf(oldS);
        if (idx < 0) {
            if (src.contains(newS.length() > 60 ? newS.substring(0, 60) : newS)) {
                System.out.println("[skip] " + tag + " (already applied)");
                skipped++;
                return src;
            }
            throw new RuntimeException("ANCHOR MISSING: " + tag);
        }
        if (src.indexOf(oldS, idx + oldS.length()) >= 0)
            throw new RuntimeException("ANCHOR NOT UNIQUE: " + tag);
        applied++;
        System.out.println("[ ok ] " + tag);
        return src.substring(0, idx) + newS + src.substring(idx + oldS.length());
    }

    static void checkParens(String s, Path p) {
        int depth = 0; boolean inStr = false, inCmt = false;
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            if (inCmt) { if (c == '\n') inCmt = false; continue; }
            if (inStr) { if (c == '\\') i++; else if (c == '"') inStr = false; continue; }
            if (c == ';') inCmt = true;
            else if (c == '"') inStr = true;
            else if (c == '(') depth++;
            else if (c == ')') depth--;
            if (depth < 0) throw new RuntimeException("paren underflow in " + p);
        }
        if (depth != 0 || inStr)
            throw new RuntimeException("paren/string imbalance in " + p + " depth=" + depth);
    }

    public static void main(String[] a) throws Exception {
        Path root = Paths.get("G:\\ASTB\\skill_src");

        Path f = root.resolve("core\\menu.il");
        String src = new String(Files.readAllBytes(f), GBK);
        src = rep(src, "; 版本      : 4.5\n", "; 版本      : 4.6\n", "version bump");
        src = rep(src,
            ";   2026-10-11 v4.5 ASTB Team 语言切换拆分：工具箱菜单语言与\n",
            ";   2026-10-11 v4.6 ASTB Team System 新增 Menu CN/Menu EN（配套\n" +
            ";                     modules/utilities/util_menucn.il：Allegro\n" +
            ";                     菜单栏运行期汉化/恢复，主要面向 16.6）\n" +
            ";   2026-10-11 v4.5 ASTB Team 语言切换拆分：工具箱菜单语言与\n",
            "revision record");
        src = rep(src,
            "    list('popup \"Alle&gro UI\" \"Allegro界面(&G)\")\n" +
            "    list(\"&English\" \"English(&E)\"  \"ASTB_SetAllegroLangEnglish\")\n" +
            "    list(\"&Chinese\" \"中文(&C)\"  \"ASTB_SetAllegroLangChinese\")\n" +
            "    '(end)\n" +
            "    '(end)\n" +
            "    '(end)\n",
            "    list('popup \"Alle&gro UI\" \"Allegro界面(&G)\")\n" +
            "    list(\"&English\" \"English(&E)\"  \"ASTB_SetAllegroLangEnglish\")\n" +
            "    list(\"&Chinese\" \"中文(&C)\"  \"ASTB_SetAllegroLangChinese\")\n" +
            "    '(end)\n" +
            "    '(separator)\n" +
            "    list(\"&Menu CN\" \"菜单汉化(&M)\"  \"ASTB_MenuCN\")\n" +
            "    list(\"Menu E&N\" \"恢复英文菜单(&N)\"  \"ASTB_MenuEN\")\n" +
            "    '(end)\n" +
            "    '(end)\n",
            "menu structure");
        checkParens(src, f);
        Files.write(f, src.getBytes(GBK));
        System.out.println("written: " + f);

        Path h = root.resolve("core\\help_map.dat");
        String hs = new String(Files.readAllBytes(h), GBK);
        hs = rep(hs,
            "ASTB_Uninstall|从 Allegro 卸载 ASTB 工具箱",
            "ASTB_MenuCN|把 Allegro 菜单栏运行期汉化为中文（16.6 专用，其他版本用官方机制）|①菜单 System -> Menu CN ②axlUIMenuDump 解析当前菜单树，逐项 axlUIMenuChange 改中文标签 ③弹成功数量提示|modules/utilities/util_menucn.il：命令项按命令名 axlUIMenuFind 定位，popup 按 dump 位置逐层定位；标签映射 config/menucn_zh.dat（官方中文 473 条+手工 98 条）；仅改内存不写文件，重启 Allegro 即还原；动态重建的菜单会回弹英文，再执行一次即可（modules/utilities/util_menucn.il）\n" +
            "ASTB_MenuEN|恢复 Allegro 菜单栏为英文|①菜单 System -> Menu EN ②按汉化时记录的 id->原标签表逐项改回 ③弹恢复数量提示|modules/utilities/util_menucn.il 的 ASTB_MenuCNRestore；动态重建残留的菜单项重启 Allegro 即复原（modules/utilities/util_menucn.il）\n" +
            "ASTB_Uninstall|从 Allegro 卸载 ASTB 工具箱",
            "help entries");
        Files.write(h, hs.getBytes(GBK));
        System.out.println("written: " + h);

        System.out.println("DONE applied=" + applied + " skipped=" + skipped);
    }
}
