// ============================================================================
// 文件名    : patch_20261011_uninstall_v11.java
// 作者      : ASTB Team
// 创建日期  : 2026-10-11
// 功能描述  : util_uninstall v1.1 实机修复补丁（卸载后重启菜单仍在）：
//               1) 整文件覆盖 modules/utilities/util_uninstall.il
//                  （payload 为本目录 patch_20261011_uninstall_v11_
//                  util_uninstall.il，UTF-8 留档，落盘转 GBK）：
//                  手工无标记 ilinit 加载段括号配平提取删除 +
//                  site ilinit 发现（CDS_SITE/CDSROOT/PATH 反推/
//                  盘符扫描 Cadence\SPB_*，对齐安装器探测）；
//               2) core/help_map.dat 的 ASTB_Uninstall 行整体替换为
//                  v1.1 描述。
//             另：ASTB功能说明.md（UTF-8）的 Uninstall 行由编辑器
//             直改，不走本脚本。GBK 显式往返；锚点缺失即抛错中止。
// 运行      : java -Dfile.encoding=UTF-8 patch_20261011_uninstall_v11.java
// ============================================================================
import java.io.IOException;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

public class patch_20261011_uninstall_v11 {
    static final Charset GBK = Charset.forName("GBK");
    static final Path SRC = Paths.get("G:/ASTB/skill_src");
    static final Path PATCH_DIR = Paths.get("G:/ASTB/_patches");

    public static void main(String[] args) throws Exception {
        installModule();
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

    // ---- 1) 整文件覆盖模块（v1.0 -> v1.1），GBK 往返校验 ----
    static void installModule() throws IOException {
        Path payload = PATCH_DIR.resolve("patch_20261011_uninstall_v11_util_uninstall.il");
        String text = new String(Files.readAllBytes(payload), StandardCharsets.UTF_8);
        Path dst = SRC.resolve("modules/utilities/util_uninstall.il");
        if (!Files.exists(dst)) throw new RuntimeException("target missing (v1.0 expected): " + dst);
        String old = readGbk(dst);
        if (!old.contains("; 版本      : 1."))
            throw new RuntimeException("unexpected existing version in " + dst);
        writeGbk(dst, text);
        String back = readGbk(dst);
        if (!back.equals(text)) throw new RuntimeException("GBK round-trip mismatch: " + dst);
        System.out.println("[1] upgraded " + dst + " -> v1.1");
    }

    // ---- 2) help_map.dat：整行替换 ASTB_Uninstall 条目 ----
    static void patchHelpMap() throws IOException {
        Path f = SRC.resolve("core/help_map.dat");
        String c = readGbk(f);
        String key = "ASTB_Uninstall|";
        int i = c.indexOf(key);
        if (i < 0) throw new RuntimeException("ANCHOR NOT FOUND: help_map ASTB_Uninstall");
        int eol = c.indexOf("\n", i);
        if (eol < 0) eol = c.length();
        String line = "ASTB_Uninstall|从 Allegro 卸载 ASTB 工具箱（移除启动加载与当前菜单）"
            + "|①菜单 System -> Uninstall ②确认框选“是”后开始：剥离 %HOME%/pcbenv/allegro.ilinit"
            + " 与全部可发现 Cadence site allegro.ilinit 中的 ASTB 加载块（安装器标记块直接剥离；"
            + "手工编写的无标记加载段弹行号二次确认后删除；原件均备份 .astb_bak），从"
            + " FORMPATH/BITMAPPATH/BMPPATH 摘除 forms 路径，移除当前会话菜单并禁止本会话自愈"
            + "重注入 ③重启 Allegro 后彻底不加载；程序文件保留在安装目录，安装版可运行根目录"
            + " unins000.exe 彻底删除"
            + "|util_uninstall.il 的 ASTB_Uninstall：_UNI_StripIlinit 按 BEGIN/END 标记剥离，"
            + "_UNI_StripLegacy 括号配平语句提取删除手工块（掩码算深度、原文做匹配），"
            + "_UNI_SiteIlinits 经 CDS_SITE/CDSROOT/PATH 反推/盘符扫描 Cadence\\SPB_* 发现"
            + " site 副本（对齐安装器 ScanAllegroVersions），_UNI_CleanEnvPaths 清理 env"
            + " 路径，ASTB_PurgeToolboxMenu 清场删菜单并置 ASTB_UNINSTALLED 防自愈"
            + "（modules/utilities/util_uninstall.il）";
        c = c.substring(0, i) + line + c.substring(eol);
        writeGbk(f, c);
        System.out.println("[2] patched " + f);
    }
}
