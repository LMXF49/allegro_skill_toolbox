// patch_20261011_langsplit.java
// 语言切换拆分：工具箱菜单语言 与 Allegro 本体界面语言 解耦
//   menu.il v4.4 -> v4.5：移除 ASTB_SetLanguage 内的联动钩子，
//     System 菜单新增 "Allegro UI" 子菜单（ASTB_SetAllegroLangEnglish/Chinese）
//   util_allegrolang.il v1.0 -> v1.1：新增独立命令入口
//   help_map.dat：语言条目去掉联动描述，新增两条 Allegro UI 语言条目
// GBK 显式往返；锚点缺失即中止；幂等可重入。
// 运行：java -Dfile.encoding=UTF-8 _patches/patch_20261011_langsplit.java
import java.io.IOException;
import java.nio.charset.Charset;
import java.nio.file.*;

public class patch_20261011_langsplit {
    static final Charset GBK = Charset.forName("GBK");
    static int applied = 0, skipped = 0;

    static String rep(String src, String oldS, String newS, String tag, boolean all) {
        int oldCount = count(src, oldS);
        if (oldCount == 0) {
            if (src.contains(newS.length() > 60 ? newS.substring(0, 60) : newS)) {
                System.out.println("[skip] " + tag + " (already applied)");
                skipped++;
                return src;
            }
            throw new RuntimeException("ANCHOR MISSING: " + tag);
        }
        if (!all && oldCount != 1)
            throw new RuntimeException("ANCHOR NOT UNIQUE (" + oldCount + "): " + tag);
        applied++;
        System.out.println("[ ok ] " + tag);
        return all ? src.replace(oldS, newS)
                   : src.replaceFirst(java.util.regex.Pattern.quote(oldS),
                                      java.util.regex.Matcher.quoteReplacement(newS));
    }

    static int count(String s, String sub) {
        int n = 0, i = 0;
        while ((i = s.indexOf(sub, i)) >= 0) { n++; i += sub.length(); }
        return n;
    }

    static void patch(Path p, String[][] rules) throws IOException {
        String src = new String(Files.readAllBytes(p), GBK);
        String orig = src;
        for (String[] r : rules)
            src = rep(src, r[0], r[1], p.getFileName() + ": " + r[2], r.length > 3);
        if (!src.equals(orig)) {
            // 括号平衡粗检（字符串/注释感知）
            checkParens(src, p);
            Files.write(p, src.getBytes(GBK));
            System.out.println("written: " + p);
        }
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

        // ---- core/menu.il v4.4 -> v4.5 ----
        patch(root.resolve("core\\menu.il"), new String[][]{
            {"; 版本      : 4.4\n",
             "; 版本      : 4.5\n",
             "version bump"},
            {";                     环境变量，均需重启 Allegro 生效；16.6 无机制）\n",
             ";                     环境变量，均需重启 Allegro 生效；16.6 无机制）\n" +
             ";   2026-10-11 v4.5 ASTB Team 语言切换拆分：工具箱菜单语言与\n" +
             ";                     Allegro 本体界面语言解耦（移除 v4.4 联动钩子）；\n" +
             ";                     Allegro 界面语言改由 System->Allegro UI 子菜单\n" +
             ";                     独立设置（util_allegrolang.il v1.1 命令入口）\n",
             "revision record"},
            {"    list('popup \"&Language\" \"语言(&L)\")\n" +
             "    list(\"&English\" \"English(&E)\"  \"ASTB_SetLanguageEnglish\")\n" +
             "    list(\"&Chinese\" \"中文(&C)\"  \"ASTB_SetLanguageChinese\")\n" +
             "    '(end)\n" +
             "    '(end)\n" +
             "    '(end)\n",
             "    list('popup \"&Language\" \"语言(&L)\")\n" +
             "    list(\"&English\" \"English(&E)\"  \"ASTB_SetLanguageEnglish\")\n" +
             "    list(\"&Chinese\" \"中文(&C)\"  \"ASTB_SetLanguageChinese\")\n" +
             "    '(end)\n" +
             "    list('popup \"Alle&gro UI\" \"Allegro界面(&G)\")\n" +
             "    list(\"&English\" \"English(&E)\"  \"ASTB_SetAllegroLangEnglish\")\n" +
             "    list(\"&Chinese\" \"中文(&C)\"  \"ASTB_SetAllegroLangChinese\")\n" +
             "    '(end)\n" +
             "    '(end)\n" +
             "    '(end)\n",
             "menu structure"},
            {"  prog((oldLang cfgVal isEn ok msg linkRet)\n",
             "  prog((oldLang cfgVal isEn ok msg)\n",
             "SetLanguage prog vars"},
            {"    ;; v4.4: 联动 Allegro 本体界面语言（需重启 Allegro 生效）\n" +
             "    when( fboundp('ASTB_AllegroLangApply)\n" +
             "      linkRet = errset(ASTB_AllegroLangApply(lang) t)\n" +
             "      when( and(linkRet car(linkRet) stringp(car(linkRet)))\n" +
             "        msg = strcat(msg \"\\n\" car(linkRet))\n" +
             "      )\n" +
             "    )\n" +
             "    axlUIConfirm(msg)\n",
             "    axlUIConfirm(msg)\n",
             "remove link hook"},
        });

        // ---- modules/utilities/util_allegrolang.il v1.0 -> v1.1 ----
        patch(root.resolve("modules\\utilities\\util_allegrolang.il"), new String[][]{
            {"; 版本      : 1.0\n" +
             "; 功能描述  : 语言切换联动 Allegro 本体界面语言（System->Language\n" +
             ";             切工具箱语言时由 core/menu.il ASTB_SetLanguage 调用）：\n",
             "; 版本      : 1.1\n" +
             "; 功能描述  : Allegro 本体界面语言设置（System->Allegro UI 子菜单\n" +
             ";             独立入口，与工具箱菜单语言切换解耦）：\n",
             "header desc"},
            {"; 修改记录  :\n" +
             ";   2026-10-11 v1.0 ASTB Team 初始创建（用户要求：语言切换联动\n",
             "; 修改记录  :\n" +
             ";   2026-10-11 v1.1 ASTB Team 与工具箱菜单语言切换解耦：新增独立\n" +
             ";                命令入口 ASTB_SetAllegroLangEnglish/Chinese\n" +
             ";                （menu.il v4.5 起 ASTB_SetLanguage 不再调用本模块）\n" +
             ";   2026-10-11 v1.0 ASTB Team 初始创建（用户要求：语言切换联动\n",
             "revision record"},
            {"printf(\"[ASTB] util_allegrolang.il v1.0 loaded\\n\")\n",
             ";------------------------------------------------------------------------\n" +
             "; 函数名  : ASTB_SetAllegroLanguage\n" +
             "; 功能    : Allegro 界面语言设置命令入口（System->Allegro UI 子菜单）\n" +
             "; 参数    : lang - \"zh-CN\" / \"en\"\n" +
             "; 返回值  : t\n" +
             ";------------------------------------------------------------------------\n" +
             "procedure( ASTB_SetAllegroLanguage(lang)\n" +
             "    prog((msg)\n" +
             "        msg = ASTB_AllegroLangApply(lang)\n" +
             "        axlUIConfirm(msg)\n" +
             "        return(t)\n" +
             "    )\n" +
             ")\n" +
             "\n" +
             ";------------------------------------------------------------------------\n" +
             "; 函数名  : ASTB_SetAllegroLangEnglish / ASTB_SetAllegroLangChinese\n" +
             "; 功能    : Allegro 界面语言切换命令入口\n" +
             "; 返回值  : t\n" +
             ";------------------------------------------------------------------------\n" +
             "procedure( ASTB_SetAllegroLangEnglish()\n" +
             "    ASTB_SetAllegroLanguage(\"en\")\n" +
             ")\n" +
             "\n" +
             "procedure( ASTB_SetAllegroLangChinese()\n" +
             "    ASTB_SetAllegroLanguage(\"zh-CN\")\n" +
             ")\n" +
             "\n" +
             "printf(\"[ASTB] util_allegrolang.il v1.1 loaded\\n\")\n",
             "entry procs"},
        });

        // ---- core/help_map.dat ----
        patch(root.resolve("core\\help_map.dat"), new String[][]{
            {"ASTB_Uninstall|从 Allegro 卸载 ASTB 工具箱",
             "ASTB_SetAllegroLangEnglish|把 Allegro 本体界面语言切换为英文|①菜单 System -> Allegro UI -> English ②写持久化设置：Allegro X 摘除 env 本地化偏好，17.x 删除 intl_enabled 用户环境变量 ③弹结果提示，重启 Allegro 生效|modules/utilities/util_allegrolang.il 的 ASTB_AllegroLangApply(\"en\")：与工具箱菜单语言切换相互独立；16.6 无官方汉化机制（modules/utilities/util_allegrolang.il）\n" +
             "ASTB_SetAllegroLangChinese|把 Allegro 本体界面语言切换为中文|①菜单 System -> Allegro UI -> 中文 ②写持久化设置：Allegro X 写 env 偏好 allegro_enable_localization 并摘除 allegro_english_menu，17.x 写 intl_enabled=yes 用户环境变量 ③弹结果提示，重启 Allegro 生效|modules/utilities/util_allegrolang.il 的 ASTB_AllegroLangApply(\"zh-CN\")：与工具箱菜单语言切换相互独立；16.6 无官方汉化机制（modules/utilities/util_allegrolang.il）\n" +
             "ASTB_Uninstall|从 Allegro 卸载 ASTB 工具箱",
             "new entries"},
            {"ASTB_ApplyMenuLanguage 重置注入状态并重建菜单；v4.4 起联动 Allegro 本体界面语言（util_allegrolang.il 写本地化偏好/intl_enabled，重启生效）（core/menu.il）",
             "ASTB_ApplyMenuLanguage 重置注入状态并重建菜单（core/menu.il）",
             "strip link desc", "all"},
        });

        System.out.println("DONE applied=" + applied + " skipped=" + skipped);
    }
}
