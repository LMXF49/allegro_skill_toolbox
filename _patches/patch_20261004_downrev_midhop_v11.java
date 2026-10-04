/* ============================================================================
 * File        : patch_20261004_downrev_midhop_v11.java
 * Author      : ASTB Team
 * Created     : 2026-10-04
 * Version     : 1.0
 * Description : util_downrev166.il v1.0 -> v1.1：24.x/25.x 链路加 S019
 *               中间跳（三跳）。
 *               根因(用户实机反馈)：24.1 会话另存后降版本第二跳失败。
 *               24.x 原生 Downrev 对话框 "Save design to 17.4" 存出的是
 *               22.1 血统文件, 免补丁 allegro_downrev_library.exe 拒转
 *               (error 32000016, 旧版 v3.2 实测)；exe 只认 17.4-2019
 *               对话框 save6 ("Save design to 17.4 (17.4-2019)") 重存的
 *               S019 血统文件。旧版 v3.2 曾加中间跳解决, v3.3 按用户
 *               决策回退, 本次按实机失败恢复为三跳：
 *               hop1 当前版本实例存 17.4(22.1) -> midhop 17.4-2019 实例
 *               save6 重存 S019 -> hop2 exe 转 16.6。
 *               未装 SPB_17.4 时降级为直转(保持 v1.0 行为)并命令行告警。
 *               同步更新 help_map.dat / ASTB功能说明.md 的三跳措辞。
 * Usage       : "C:\Program Files\Amazon Corretto\jdk21.0.10_7\bin\java.exe" ^
 *                 _patches\patch_20261004_downrev_midhop_v11.java
 * Encoding    : 本文件 UTF-8；GBK 文件显式 Charset.forName("GBK") 往返。
 * ============================================================================
 */
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;

public class patch_20261004_downrev_midhop_v11 {

    static final Charset GBK = Charset.forName("GBK");
    static final Charset UTF8 = Charset.forName("UTF-8");
    static final Path ROOT = Paths.get("G:/ASTB");

    static class Edit { final String oldS, newS; Edit(String o, String n) { oldS = o; newS = n; } }

    static String read(Path p, Charset cs) throws Exception { return new String(Files.readAllBytes(p), cs); }

    static String load(Path p, Charset cs) throws Exception { return read(p, cs).replace("\r\n", "\n"); }

    static void save(Path p, Charset cs, String t, boolean crlf) throws Exception {
        if (crlf) t = t.replace("\n", "\r\n");
        Files.write(p, t.getBytes(cs));
        String back = read(p, cs).replace("\r\n", "\n");
        if (!back.equals(t.replace("\r\n", "\n"))) throw new RuntimeException("roundtrip mismatch: " + p);
    }

    static String apply(String tag, String s, List<Edit> edits) {
        for (int i = 0; i < edits.size(); i++) {
            Edit e = edits.get(i);
            int c = 0; int idx = 0;
            while ((idx = s.indexOf(e.oldS, idx)) >= 0) { c++; idx += e.oldS.length(); }
            if (c != 1) throw new RuntimeException(tag + " EDIT " + (i + 1) + ": anchor found " + c + " times, ABORT");
            s = s.replaceFirst(java.util.regex.Pattern.quote(e.oldS), java.util.regex.Matcher.quoteReplacement(e.newS));
        }
        return s;
    }

    static void checkParen(String tag, String s) {
        int depth = 0; boolean inStr = false, inComment = false, esc = false;
        for (int i = 0; i < s.length(); i++) {
            char ch = s.charAt(i);
            if (inComment) { if (ch == '\n') inComment = false; continue; }
            if (inStr) {
                if (esc) esc = false;
                else if (ch == '\\') esc = true;
                else if (ch == '"') inStr = false;
                continue;
            }
            if (ch == '"') inStr = true;
            else if (ch == ';') inComment = true;
            else if (ch == '(') depth++;
            else if (ch == ')') { depth--; if (depth < 0) throw new RuntimeException(tag + " paren NEGATIVE"); }
        }
        if (depth != 0 || inStr) throw new RuntimeException(tag + " UNBALANCED depth=" + depth);
    }

    public static void main(String[] args) throws Exception {

        // ---------------------------------------------------------- 模块 v1.1
        Path mod = ROOT.resolve("skill_src/modules/utilities/util_downrev166.il");
        boolean mCrLf = read(mod, GBK).contains("\r\n");
        String m = load(mod, GBK);
        List<Edit> me = new ArrayList<>();

        // 1) 版本号
        me.add(new Edit("; 版本      : 1.0\n", "; 版本      : 1.1\n"));

        // 2) 功能描述 24.x 段: 两跳 -> 三跳
        me.add(new Edit(
            ";             24.x/25.x 会话：两跳——新实例批处理（当前版本\n" +
            ";             allegro.exe -s 回放脚本开临时副本，原生 Downrev\n" +
            ";             对话框选 \"Save design to 17.4\" 存中间文件）再走主路。\n",
            ";             24.x/25.x 会话：三跳——新实例批处理（当前版本\n" +
            ";             allegro.exe -s 回放脚本开临时副本，原生 Downrev\n" +
            ";             对话框选 \"Save design to 17.4\" 存 22.1 血统中间文件）\n" +
            ";             -> 17.4-2019 实例对话框 save6 重存 S019 血统（免补丁\n" +
            ";             exe 只认 S019, 22.1 血统报 32000016 实测）-> 主路转。\n"));

        // 3) 修改记录加 v1.1
        me.add(new Edit(
            ";             桥死代码；失败路径全部改为命令行留痕不弹窗\n",
            ";             桥死代码；失败路径全部改为命令行留痕不弹窗\n" +
            ";   2026-10-04 v1.1 ASTB Team 24.x/25.x 链路加 S019 中间跳（用户\n" +
            ";             实机反馈 24.1 另存后第二跳失败：24.x 对话框存的 17.4\n" +
            ";             为 22.1 血统, 免补丁 exe 拒转 32000016, 实测仅认 17.4\n" +
            ";             对话框 save6 的 S019 血统）；未装 SPB_17.4 时降级\n" +
            ";             为直转并命令行告警\n"));

        // 4) 实机待验证加第 2 条
        me.add(new Edit(
            ";   1) 24.1/25.1 新实例批处理第一跳（downrev 对话框 save7 + fillin\n" +
            ";      喂路径）：旧版 24.1 S006 验证过，25.1 未回归\n",
            ";   1) 24.1/25.1 新实例批处理第一跳（downrev 对话框 save7 + fillin\n" +
            ";      喂路径）：旧版 24.1 S006 验证过，25.1 未回归\n" +
            ";   2) 17.4-2019 实例中间跳（save6 重存 S019）：旧版 v3.2 实测过,\n" +
            ";      本重写版未回归\n"));

        // 5) 新增 _DR166_FindMid174Allegro + _DR166_MidHop174, 插在 _DR166_Main 前
        String newFuncs =
            ";------------------------------------------------------------------------\n" +
            "; 函数名  : _DR166_FindMid174Allegro\n" +
            "; 功能    : 定位 17.4-2019 安装的 allegro.exe（24.x 三跳中间跳用）\n" +
            "; 返回值  : exe 路径 / nil\n" +
            "; 备注    : 24.x 原生对话框存出的 17.4 是 22.1 血统，免补丁 exe 不认\n" +
            ";           (32000016, 实测)；必须经 17.4-2019 对话框 save6 重存为\n" +
            ";           S019 血统后才转得动\n" +
            ";------------------------------------------------------------------------\n" +
            "procedure( _DR166_FindMid174Allegro()\n" +
            "  prog((roots r cand)\n" +
            "    roots = nil\n" +
            "    foreach( d '(\"D:/Cadence\" \"C:/Cadence\" \"E:/Cadence\" \"F:/Cadence\" \"G:/Cadence\")\n" +
            "      roots = append1(roots strcat(d \"/SPB_17.4\"))\n" +
            "    )\n" +
            "    foreach( r roots\n" +
            "      foreach( cand list(\n" +
            "          strcat(r \"/tools/bin/allegro.exe\")\n" +
            "          strcat(r \"/tools/pcb/bin/allegro.exe\"))\n" +
            "        when( isFile(cand)\n" +
            "          return(cand)\n" +
            "        )\n" +
            "      )\n" +
            "    )\n" +
            "    return(nil)\n" +
            "  )\n" +
            ")\n" +
            "\n" +
            ";------------------------------------------------------------------------\n" +
            "; 函数名  : _DR166_MidHop174\n" +
            "; 功能    : 中间跳：起 17.4-2019 实例回放其 Downrev 对话框 save6\n" +
            ";           (\"Save design to 17.4 (17.4-2019)\"), 把 22.1 血统的\n" +
            ";           17.4 中间文件重存为 S019 血统，免补丁 exe 才认\n" +
            "; 参数    : dir/name - 工作目录/设计名; brd174 - hop1 产出的 17.4 文件;\n" +
            ";           aexe - 17.4 实例 allegro.exe 路径\n" +
            "; 返回值  : S019 血统 17.4 文件路径 / nil(失败)\n" +
            "; 备注    : 与第一跳同纪律——临时副本避开锁与空格/中文路径, 非阻塞\n" +
            ";           启动 + 120s 轮询, 超时/失败清理临时件并命令行留痕;\n" +
            ";           bat 内把 CDSROOT 指到 17.4 根, 避免继承本会话 CDSROOT\n" +
            ";------------------------------------------------------------------------\n" +
            "procedure( _DR166_MidHop174(dir name brd174 aexe)\n" +
            "  prog((pathS tmpIn tmpS scrPath batPath port n ok r174)\n" +
            "    pathS = _DR166_OutputPath(dir name \"174s\")\n" +
            "    tmpIn = strcat(axlTempDirectory() \"/\" name \"_midin.brd\")\n" +
            "    tmpS   = strcat(axlTempDirectory() \"/\" name \"_mids.brd\")\n" +
            "    foreach( f list(tmpIn tmpS)\n" +
            "      when( isFile(f) errset(deleteFile(f) t) )\n" +
            "    )\n" +
            "    ok = errset(axlOSFileCopy(brd174 tmpIn nil) t)\n" +
            "    unless( and(ok car(ok))\n" +
            "      axlMsgPut(strcat(\"Downrev166: 中间跳输入复制失败: \" tmpIn))\n" +
            "      return(nil)\n" +
            "    )\n" +
            "    ;; 回放脚本: 17.4 对话框 save6 重存 S019, fillin 喂路径, exit 退出\n" +
            "    scrPath = strcat(axlTempDirectory() \"/dr174_mid.scr\")\n" +
            "    port = outfile(scrPath \"w\")\n" +
            "    unless( port\n" +
            "      axlMsgPut(\"Downrev166: 无法创建中间跳脚本文件\")\n" +
            "      return(nil)\n" +
            "    )\n" +
            "    fprintf(port \"scriptmode +i\\n\")\n" +
            "    fprintf(port \"downrev\\n\")\n" +
            "    fprintf(port \"setwindow form.downrev\\n\")\n" +
            "    fprintf(port \"FORM downrev save6\\n\")\n" +
            "    fprintf(port \"FORM downrev save\\n\")\n" +
            "    fprintf(port \"fillin \\\"%s\\\"\\n\" tmpS)\n" +
            "    fprintf(port \"exit\\n\")\n" +
            "    close(port)\n" +
            "    ;; 起 17.4 实例前把 CDSROOT 指到 17.4 根(会话 CDSROOT 可能指别版)\n" +
            "    r174 = aexe\n" +
            "    when( rexMatchp(\"/tools/bin/allegro.exe$\" r174)\n" +
            "      r174 = substring(r174 1 strlen(r174) - strlen(\"/tools/bin/allegro.exe\")) )\n" +
            "    when( rexMatchp(\"/tools/pcb/bin/allegro.exe$\" r174)\n" +
            "      r174 = substring(r174 1 strlen(r174) - strlen(\"/tools/pcb/bin/allegro.exe\")) )\n" +
            "    batPath = strcat(axlTempDirectory() \"/dr174_mid.bat\")\n" +
            "    port = outfile(batPath \"w\")\n" +
            "    unless( port\n" +
            "      axlMsgPut(\"Downrev166: 无法创建中间跳 bat 文件\")\n" +
            "      return(nil)\n" +
            "    )\n" +
            "    fprintf(port \"@echo off\\r\\n\")\n" +
            "    fprintf(port \"set \\\"CDSROOT=%s\\\"\\r\\n\" r174)\n" +
            "    fprintf(port \"\\\"%s\\\" -s \\\"%s\\\" \\\"%s\\\"\\r\\n\" aexe scrPath tmpIn)\n" +
            "    close(port)\n" +
            "    axlMsgPut(\"中间跳: 17.4 实例重存 S019 血统(约 1 分钟, 请稍候)...\")\n" +
            "    ASTB_DebugLog(strcat(\"Downrev166: midhop exe=\" aexe \" in=\" tmpIn))\n" +
            "    system(strcat(\"cmd /c start \\\"\\\" \\\"\" batPath \"\\\"\"))\n" +
            "    n = 0\n" +
            "    while( and(null(isFile(tmpS)) n < 120)\n" +
            "      sleep(1)\n" +
            "      n = n+1\n" +
            "    )\n" +
            "    unless( isFile(tmpS)\n" +
            "      axlMsgPut(\"Downrev166: 中间跳超时(120s 未出 S019 文件), 已清理临时件\")\n" +
            "      foreach( f list(tmpIn scrPath batPath)\n" +
            "        errset(deleteFile(f) t)\n" +
            "      )\n" +
            "      return(nil)\n" +
            "    )\n" +
            "    ok = errset(axlOSFileCopy(tmpS pathS nil) t)\n" +
            "    unless( and(ok car(ok))\n" +
            "      axlMsgPut(strcat(\"Downrev166: S019 文件拷回失败: \" pathS))\n" +
            "      return(nil)\n" +
            "    )\n" +
            "    foreach( f list(tmpIn tmpS scrPath batPath)\n" +
            "      errset(deleteFile(f) t)\n" +
            "    )\n" +
            "    axlMsgPut(\"中间跳完成(S019 血统)。\")\n" +
            "    return(pathS)\n" +
            "  )\n" +
            ")\n" +
            "\n" +
            ";------------------------------------------------------------------------\n" +
            "; 函数名  : _DR166_Main\n";
        me.add(new Edit(
            ";------------------------------------------------------------------------\n" +
            "; 函数名  : _DR166_Main\n",
            newFuncs));

        // 6) _DR166_Main prog 局部变量加 a174/pathS
        me.add(new Edit(
            "    prog((dir name brd exe ver path174)\n",
            "    prog((dir name brd exe ver path174 a174 pathS)\n"));

        // 7) 24.x 分支改三跳
        me.add(new Edit(
            "        else\n" +
            "            ;; 23.1/24.1/25.1 等会话：新实例批处理存 17.4 中间文件再转\n" +
            "            path174 = _DR166_HopTo174(dir name brd)\n" +
            "            unless( path174 return(nil) )\n" +
            "            axlMsgPut(\"第二跳: 17.4 -> 16.6 转换中...\")\n" +
            "            return( _DR166_RunExe(exe dir name path174) )\n" +
            "        )\n",
            "        else\n" +
            "            ;; 23.1/24.1/25.1 等会话：hop1 存 17.4(22.1 血统)\n" +
            "            ;; -> 装了 17.4-2019 时中间跳重存 S019 血统\n" +
            "            ;; -> 免补丁 exe 转 16.6（全程三跳）\n" +
            "            path174 = _DR166_HopTo174(dir name brd)\n" +
            "            unless( path174 return(nil) )\n" +
            "            a174 = _DR166_FindMid174Allegro()\n" +
            "            if( a174 then\n" +
            "                pathS = _DR166_MidHop174(dir name path174 a174)\n" +
            "                unless( pathS return(nil) )\n" +
            "            else\n" +
            "                axlMsgPut(\"Downrev166: 未找到 SPB_17.4 安装, 跳过 S019 中间跳\")\n" +
            "                axlMsgPut(\"Downrev166: 22.1 血统的 17.4 可能转换失败(32000016), 失败请改用 17.4 会话执行\")\n" +
            "                pathS = path174\n" +
            "            )\n" +
            "            axlMsgPut(\"最后一跳: 17.4 -> 16.6 转换中...\")\n" +
            "            return( _DR166_RunExe(exe dir name pathS) )\n" +
            "        )\n"));

        m = apply("util_downrev166.il", m, me);
        checkParen("util_downrev166.il", m);
        if (m.indexOf('\r') >= 0) throw new RuntimeException("residue \\r");
        save(mod, GBK, m, mCrLf);
        System.out.println("OK: util_downrev166.il v1.1, midhop added");

        // ---------------------------------------------------------- help_map
        Path help = ROOT.resolve("skill_src/core/help_map.dat");
        boolean hCrLf = read(help, GBK).contains("\r\n");
        String hm = load(help, GBK);
        hm = apply("help_map.dat", hm, List.of(new Edit(
            "（24.x/25.x 会话先新实例批处理驱动原生 Downrev 对话框存出 17.4 中间文件再转）",
            "（24.x/25.x 会话：新实例批处理存 17.4(22.1 血统)中间文件→17.4-2019 实例对话框 save6 重存 S019 血统→再转）")));
        save(help, GBK, hm, hCrLf);
        System.out.println("OK: help_map.dat 三跳措辞同步");

        // ---------------------------------------------------------- 功能说明
        Path doc = ROOT.resolve("ASTB功能说明.md");
        boolean dCrLf = read(doc, UTF8).contains("\r\n");
        String dc = load(doc, UTF8);
        dc = apply("ASTB功能说明.md", dc, List.of(new Edit(
            "| PCB 降版本 16.6 | 自带免补丁运行时 downrev166_rt 原地转 16.6；24.x 新实例批处理两跳（先存 17.4 中间文件再转）；失败原因见输出目录同名 .log |",
            "| PCB 降版本 16.6 | 自带免补丁运行时 downrev166_rt 原地转 16.6；24.x 三跳（17.4 中间文件→17.4-2019 重存 S019 血统→转 16.6）；失败原因见输出目录同名 .log |")));
        save(doc, UTF8, dc, dCrLf);
        System.out.println("OK: ASTB功能说明.md 三跳措辞同步");

        System.out.println("ALL OK");
    }
}
