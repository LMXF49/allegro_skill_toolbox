// ============================================================================
// 文件名    : patch_20261011_allegro_langlink.java
// 作者      : ASTB Team
// 创建日期  : 2026-10-11
// 功能描述  : 语言切换联动 Allegro 本体界面语言补丁：
//               1) 安装新模块 modules/utilities/util_allegrolang.il
//                  （payload 为本目录 patch_20261011_allegro_langlink_
//                  util_allegrolang.il，UTF-8 留档，落盘转 GBK）；
//               2) core/menu.il v4.3 -> v4.4：ASTB_SetLanguage 调用
//                  联动函数并把结果并入确认框；
//               3) core/help_map.dat：两条 SetLanguage 帮助补联动说明。
//             ASTB功能说明.md（UTF-8）由编辑器直改。GBK 显式往返；
//             锚点缺失/不唯一即中止；可重入（已打则跳过）。
// 运行      : java -Dfile.encoding=UTF-8 patch_20261011_allegro_langlink.java
// ============================================================================
import java.io.IOException;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

public class patch_20261011_allegro_langlink {
    static final Charset GBK = Charset.forName("GBK");
    static final Path SRC = Paths.get("G:/ASTB/skill_src");
    static final Path PATCH_DIR = Paths.get("G:/ASTB/_patches");

    public static void main(String[] args) throws Exception {
        installModule();
        patchMenuIl();
        patchHelpMap();
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

    static void installModule() throws IOException {
        Path payload = PATCH_DIR.resolve("patch_20261011_allegro_langlink_util_allegrolang.il");
        String text = new String(Files.readAllBytes(payload), StandardCharsets.UTF_8);
        Path dst = SRC.resolve("modules/utilities/util_allegrolang.il");
        if (Files.exists(dst)) {
            System.out.println("[1] module already exists, skip");
            return;
        }
        writeGbk(dst, text);
        if (!readGbk(dst).equals(text)) throw new RuntimeException("GBK round-trip mismatch: " + dst);
        System.out.println("[1] installed " + dst);
    }

    static void patchMenuIl() throws IOException {
        Path f = SRC.resolve("core/menu.il");
        String c = readGbk(f);
        if (c.contains("util_allegrolang")) {
            System.out.println("[2] menu.il already patched, skip");
            return;
        }
        c = replaceOnce(c, "; 版本      : 4.3", "; 版本      : 4.4", "menu.il version");
        c = replaceOnce(c,
            "; 修改记录  :\n;   2026-10-11 v4.3",
            "; 修改记录  :\n"
                + ";   2026-10-11 v4.4 ASTB Team 语言切换联动 Allegro 本体界面语言\n"
                + ";                     （配套 modules/utilities/util_allegrolang.il：\n"
                + ";                     Allegro X 写 env 偏好 allegro_enable_localization/\n"
                + ";                     allegro_english_menu，17.x 写 intl_enabled 用户\n"
                + ";                     环境变量，均需重启 Allegro 生效；16.6 无机制）\n"
                + ";   2026-10-11 v4.3",
            "menu.il revision");
        // SetLanguage prog 局部变量加 linkRet
        c = replaceOnce(c,
            "  prog((oldLang cfgVal isEn ok msg)",
            "  prog((oldLang cfgVal isEn ok msg linkRet)",
            "menu.il SetLanguage prog vars");
        // 确认框前并入联动结果
        c = replaceOnce(c,
            "    axlUIConfirm(msg)\n    return(t)\n  )\n)\n\n;------------------------------------------------------------------------\n; 函数名  : ASTB_SetLanguageEnglish",
            "    ;; v4.4: 联动 Allegro 本体界面语言（需重启 Allegro 生效）\n"
                + "    when( fboundp('ASTB_AllegroLangApply)\n"
                + "      linkRet = errset(ASTB_AllegroLangApply(lang) t)\n"
                + "      when( and(linkRet car(linkRet) stringp(car(linkRet)))\n"
                + "        msg = strcat(msg \"\\n\" car(linkRet))\n"
                + "      )\n"
                + "    )\n"
                + "    axlUIConfirm(msg)\n    return(t)\n  )\n)\n\n;------------------------------------------------------------------------\n; 函数名  : ASTB_SetLanguageEnglish",
            "menu.il SetLanguage link");
        writeGbk(f, c);
        System.out.println("[2] patched " + f);
    }

    static void patchHelpMap() throws IOException {
        Path f = SRC.resolve("core/help_map.dat");
        String c = readGbk(f);
        String anchor = "重置注入状态并重建菜单（core/menu.il）";
        if (!c.contains(anchor)) {
            System.out.println("[3] help_map anchor absent or already patched, skip");
            return;
        }
        c = c.replace(anchor,
            "重置注入状态并重建菜单；v4.4 起联动 Allegro 本体界面语言"
                + "（util_allegrolang.il 写本地化偏好/intl_enabled，重启生效）（core/menu.il）");
        writeGbk(f, c);
        System.out.println("[3] patched " + f);
    }
}
