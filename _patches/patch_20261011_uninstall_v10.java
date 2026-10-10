// ============================================================================
// 文件名    : patch_20261011_uninstall_v10.java
// 作者      : ASTB Team
// 创建日期  : 2026-10-11
// 功能描述  : 菜单新增 Uninstall（卸载）功能补丁：
//               1) 安装新模块 modules/utilities/util_uninstall.il
//                  （payload 为本目录 patch_20261011_uninstall_v10_
//                  util_uninstall.il，UTF-8 留档，落盘转 GBK）；
//               2) core/menu.il：System 菜单加 "&Uninstall" 行、版本
//                  4.1 -> 4.2 补修订记录、新增 ASTB_UNINSTALLED 标志、
//                  OnDesignOpen 加卸载会话自愈屏蔽；
//               3) core/labels_map.dat 追加 &Uninstall=卸载(&U)；
//               4) core/help_map.dat 追加 ASTB_Uninstall 帮助行。
//             全部 GBK 显式往返读写；锚点缺失/不唯一即抛错中止；
//             幂等防护：已打过的文件直接报错不重复打。
// 运行      : java -Dfile.encoding=UTF-8 patch_20261011_uninstall_v10.java
//             （JDK 11+；源文件 UTF-8，故需显式 UTF-8 读源码）
// ============================================================================
import java.io.IOException;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

public class patch_20261011_uninstall_v10 {
    static final Charset GBK = Charset.forName("GBK");
    static final Path SRC = Paths.get("G:/ASTB/skill_src");
    static final Path PATCH_DIR = Paths.get("G:/ASTB/_patches");

    public static void main(String[] args) throws Exception {
        installModule();
        patchMenuIl();
        patchLabels();
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

    // ---- 1) 新模块安装（payload UTF-8 -> GBK，往返校验） ----
    static void installModule() throws IOException {
        Path payload = PATCH_DIR.resolve("patch_20261011_uninstall_v10_util_uninstall.il");
        String text = new String(Files.readAllBytes(payload), StandardCharsets.UTF_8);
        Path dst = SRC.resolve("modules/utilities/util_uninstall.il");
        if (Files.exists(dst)) throw new RuntimeException("target already exists: " + dst);
        writeGbk(dst, text);
        String back = readGbk(dst);
        if (!back.equals(text)) throw new RuntimeException("GBK round-trip mismatch: " + dst);
        System.out.println("[1] installed " + dst);
    }

    // ---- 2) core/menu.il：5 处锚点替换 ----
    static void patchMenuIl() throws IOException {
        Path f = SRC.resolve("core/menu.il");
        String c = readGbk(f);
        if (c.contains("ASTB_UNINSTALLED"))
            throw new RuntimeException("menu.il already patched (ASTB_UNINSTALLED present)");

        c = replaceOnce(c,
            "; 版本      : 4.1",
            "; 版本      : 4.2",
            "menu.il version");

        c = replaceOnce(c,
            "; 修改记录  :\n;   2026-10-04 v4.1",
            "; 修改记录  :\n"
                + ";   2026-10-11 v4.2 ASTB Team System 新增 Uninstall 菜单项\n"
                + ";                     （配套 modules/utilities/util_uninstall.il 卸载\n"
                + ";                     命令）；新增 ASTB_UNINSTALLED 会话标志，卸载后\n"
                + ";                     OnDesignOpen 自愈不再重注入菜单\n"
                + ";   2026-10-04 v4.1",
            "menu.il revision");

        c = replaceOnce(c,
            "unless(boundp('ASTB_MENU_TIMER_ID) defvar(ASTB_MENU_TIMER_ID nil))",
            "unless(boundp('ASTB_MENU_TIMER_ID) defvar(ASTB_MENU_TIMER_ID nil))\n"
                + ";; 卸载会话标志：util_uninstall.il 置位后，本会话菜单自愈不再重注入\n"
                + "unless(boundp('ASTB_UNINSTALLED) defvar(ASTB_UNINSTALLED nil))",
            "menu.il defvar");

        c = replaceOnce(c,
            "    list(\"&Open Studio\" \"&Open Studio\" \"ASTB_OpenStudio\")\n    '(separator)",
            "    list(\"&Open Studio\" \"&Open Studio\" \"ASTB_OpenStudio\")\n"
                + "    list(\"&Uninstall\"   \"&Uninstall\"   \"ASTB_Uninstall\")\n"
                + "    '(separator)",
            "menu.il menu row");

        c = replaceOnce(c,
            "procedure( ASTB_OnDesignOpen(@rest args)\n  prog((tid)\n"
                + "    ASTB_LogInfo(\"Menu self-heal trigger fired, re-injecting in 500ms\")",
            "procedure( ASTB_OnDesignOpen(@rest args)\n  prog((tid)\n"
                + "    ;; 卸载会话内禁止自愈重注入（util_uninstall.il 置位 ASTB_UNINSTALLED）\n"
                + "    when( ASTB_UNINSTALLED\n"
                + "      ASTB_LogInfo(\"Menu self-heal skipped: uninstalled this session\")\n"
                + "      return(t)\n"
                + "    )\n"
                + "    ASTB_LogInfo(\"Menu self-heal trigger fired, re-injecting in 500ms\")",
            "menu.il OnDesignOpen guard");

        writeGbk(f, c);
        System.out.println("[2] patched " + f);
    }

    // ---- 3) core/labels_map.dat：&Uninstall 标签 ----
    static void patchLabels() throws IOException {
        Path f = SRC.resolve("core/labels_map.dat");
        String c = readGbk(f);
        if (c.contains("&Uninstall="))
            throw new RuntimeException("labels_map.dat already patched");
        c = replaceOnce(c,
            "&Open Studio=打开外置软件(&O)",
            "&Open Studio=打开外置软件(&O)\n&Uninstall=卸载(&U)",
            "labels_map.dat row");
        writeGbk(f, c);
        System.out.println("[3] patched " + f);
    }

    // ---- 4) core/help_map.dat：追加 ASTB_Uninstall 帮助行 ----
    static void patchHelpMap() throws IOException {
        Path f = SRC.resolve("core/help_map.dat");
        String c = readGbk(f);
        if (c.contains("ASTB_Uninstall|"))
            throw new RuntimeException("help_map.dat already patched");
        String line = "ASTB_Uninstall|从 Allegro 卸载 ASTB 工具箱（移除启动加载与当前菜单）"
            + "|①菜单 System -> Uninstall ②确认框选“是”后开始：剥离 %HOME%/pcbenv/allegro.ilinit"
            + " 与 Cadence site allegro.ilinit 中的 ASTB 加载块（原件备份 .astb_bak），从"
            + " FORMPATH/BITMAPPATH/BMPPATH 摘除 forms 路径，移除当前会话菜单并禁止本会话自愈"
            + "重注入 ③重启 Allegro 后彻底不加载；程序文件保留在安装目录，安装版可运行根目录"
            + " unins000.exe 彻底删除"
            + "|util_uninstall.il 的 ASTB_Uninstall：_UNI_StripIlinit 按 ilinit_block.il 同款"
            + " BEGIN/END 标记剥离（读全行->过滤->备份->LF 写回），_UNI_CleanEnvPaths 用"
            + " axlGetVariableList/axlSetVariable 归一化比较后摘除路径，ASTB_PurgeToolboxMenu"
            + " 清场删菜单并置 ASTB_UNINSTALLED 防自愈（modules/utilities/util_uninstall.il）";
        if (!c.endsWith("\n")) c += "\n";
        c += line + "\n";
        writeGbk(f, c);
        System.out.println("[4] patched " + f);
    }
}
