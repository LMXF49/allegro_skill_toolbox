/* ============================================================================
 * File        : patch_20261004_downrev_twohop_v13.java
 * Author      : ASTB Team
 * Created     : 2026-10-04
 * Version     : 1.0
 * Description : util_downrev166.il v1.2 -> v1.3：按用户决策撤掉 S019
 *               中间跳，24.x/25.x 恢复两跳直通。
 *               - 删 _DR166_FindMid174Allegro / _DR166_MidHop174 两函数
 *               - _DR166_Main 24.x 分支恢复两跳(path174 -> RunExe)
 *               - _DR166_RunExe 失败分支自动识别日志 32000016(24.x 新
 *                 修订拒转), 给手工重存指引; 其余失败保持通用提示
 *               - 新增 _DR166_LogHasCode 日志错误码扫描
 *               - help_map.dat / ASTB功能说明.md 恢复两跳措辞
 *               背景: 24.x 写出的 17.4 是 dbstat 仍显示 17.4 的新修订,
 *               2019 时代免补丁 exe 打不开(32000016 实测), 两跳在该场景
 *               第二跳必失败——按用户决策不自动绕, 失败时给清晰手工路。
 * Usage       : "C:\Program Files\Amazon Corretto\jdk21.0.10_7\bin\java.exe" ^
 *                 _patches\patch_20261004_downrev_twohop_v13.java
 * Encoding    : 本文件 UTF-8；GBK 文件显式 Charset.forName("GBK") 往返。
 * ============================================================================
 */
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;

public class patch_20261004_downrev_twohop_v13 {

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
            int c = 0, idx = 0;
            while ((idx = s.indexOf(e.oldS, idx)) >= 0) { c++; idx += e.oldS.length(); }
            if (c != 1) throw new RuntimeException(tag + " EDIT " + (i + 1) + ": anchor found " + c + " times, ABORT");
            s = s.replaceFirst(java.util.regex.Pattern.quote(e.oldS), java.util.regex.Matcher.quoteReplacement(e.newS));
        }
        return s;
    }

    /** 删除从 banner(含) 到 nextBanner(不含) 之间的整段文本。 */
    static String deleteBlock(String tag, String s, String bannerKey, String nextBannerKey) {
        int k1 = s.indexOf("; 函数名  : " + bannerKey);
        int k2 = s.indexOf("; 函数名  : " + nextBannerKey);
        if (k1 < 0 || k2 < 0 || k2 <= k1) throw new RuntimeException(tag + " block keys not found, ABORT");
        // 各自向前回退到行首的 ;---- 横幅
        int start = s.lastIndexOf(";------------------------------------------------------------------------\n", k1);
        int end   = s.lastIndexOf(";------------------------------------------------------------------------\n", k2);
        if (start < 0 || end <= start) throw new RuntimeException(tag + " banner backtrack failed, ABORT");
        return s.substring(0, start) + s.substring(end);
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

        Path mod = ROOT.resolve("skill_src/modules/utilities/util_downrev166.il");
        boolean mCrLf = read(mod, GBK).contains("\r\n");
        String m = load(mod, GBK);

        // 1) 版本号 1.2 -> 1.3
        m = apply("mod", m, List.of(new Edit("; 版本      : 1.2\n", "; 版本      : 1.3\n")));

        // 2) 功能描述 24.x 段: 三跳 -> 两跳
        m = apply("mod", m, List.of(new Edit(
            ";             24.x/25.x 会话：三跳——新实例批处理（当前版本\n" +
            ";             allegro.exe -s 回放脚本开临时副本，原生 Downrev\n" +
            ";             对话框选 \"Save design to 17.4\" 存中间文件（dbstat\n" +
            ";             显示 17.4，实为 24.x/22.1 代码线写入的新修订，\n" +
            ";             17.4-2019 时代的免补丁 exe 打不开，32000016 实测）\n" +
            ";             -> 17.4-2019 实例对话框 save6 重存 S019 修订 -> 主路。\n",
            ";             24.x/25.x 会话：两跳——新实例批处理（当前版本\n" +
            ";             allegro.exe -s 回放脚本开临时副本，原生 Downrev\n" +
            ";             对话框选 \"Save design to 17.4\" 存中间文件，再由主路\n" +
            ";             exe 直转 16.6。注意：24.x 写出的 17.4 是 dbstat 仍\n" +
            ";             显示 17.4 的新修订，2019 时代的免补丁 exe 可能打不\n" +
            ";             开（32000016, 实测），失败时命令行自动识别并给手工重存指引。\n")));

        // 3) 修改记录追加 v1.3
        m = apply("mod", m, List.of(new Edit(
            ";             改述, 功能逻辑不变\n",
            ";             改述, 功能逻辑不变\n" +
            ";   2026-10-04 v1.3 ASTB Team 按用户决策撤掉 S019 中间跳，24.x 恢复\n" +
            ";             两跳直通；删 _DR166_FindMid174Allegro/_DR166_MidHop174;\n" +
            ";             第二跳失败时自动识别日志 32000016(24.x 新修订拒转)并\n" +
            ";             给手工重存指引，其余失败保持通用提示\n")));

        // 4) _DR166_LogConverted 之后插 _DR166_LogHasCode(在 RunExe 横幅前)
        m = apply("mod", m, List.of(new Edit(
            ";------------------------------------------------------------------------\n" +
            "; 函数名  : _DR166_RunExe\n",
            ";------------------------------------------------------------------------\n" +
            "; 函数名  : _DR166_LogHasCode\n" +
            "; 功能    : 扫描日志文件是否含指定错误码子串\n" +
            "; 参数    : logPath - 日志路径; code - 错误码子串(如 \"32000016\")\n" +
            "; 返回值  : t / nil\n" +
            ";------------------------------------------------------------------------\n" +
            "procedure( _DR166_LogHasCode(logPath code)\n" +
            "    prog((port line hit)\n" +
            "        hit = nil\n" +
            "        port = infile(logPath)\n" +
            "        when( port\n" +
            "            while( gets(line port)\n" +
            "                when( rexMatchp(code line)\n" +
            "                    hit = t\n" +
            "                )\n" +
            "            )\n" +
            "            close(port)\n" +
            "        )\n" +
            "        return(hit)\n" +
            "    )\n" +
            ")\n" +
            "\n" +
            ";------------------------------------------------------------------------\n" +
            "; 函数名  : _DR166_RunExe\n")));

        // 5) RunExe 失败分支: 识别 32000016 给手工指引
        m = apply("mod", m, List.of(new Edit(
            "            ;; 具体原因在输出同名 .log，失败只命令行留痕不弹窗\n" +
            "            sideLog = strcat(substring(outPath 1 strlen(outPath)-4) \".log\")\n" +
            "            axlMsgPut(strcat(\"降版本失败: 设计含 16.6 不支持的特性, 详见 \" sideLog))\n",
            "            ;; 具体原因在输出同名 .log，失败只命令行留痕不弹窗\n" +
            "            sideLog = strcat(substring(outPath 1 strlen(outPath)-4) \".log\")\n" +
            "            if( and(isFile(sideLog) _DR166_LogHasCode(sideLog \"32000016\")) then\n" +
            "                axlMsgPut(\"降版本失败: 该 17.4 是 24.x 写入的新修订, 本转换器(17.4-2019) 打不开(32000016)\")\n" +
            "                axlMsgPut(strcat(\"手工处理: 用 17.4 打开 \" brd \" 经 File>Export>Downrev design 选 17.4(17.4-2019) 重存, 再于 17.4 会话重跑本命令\"))\n" +
            "            else\n" +
            "                axlMsgPut(strcat(\"降版本失败: 设计含 16.6 不支持的特性, 详见 \" sideLog))\n" +
            "            )\n")));

        // 6) 整段删 FindMid174Allegro + MidHop174(HopTo174 之后、Main 之前)
        m = deleteBlock("mod", m, "_DR166_FindMid174Allegro", "_DR166_Main");
        System.out.println("OK: midhop functions removed");

        // 7) Main prog 局部变量去 a174/pathS
        m = apply("mod", m, List.of(new Edit(
            "    prog((dir name brd exe ver path174 a174 pathS)\n",
            "    prog((dir name brd exe ver path174)\n")));

        // 8) Main 24.x 分支恢复两跳
        m = apply("mod", m, List.of(new Edit(
            "        else\n" +
            "            ;; 23.1/24.1/25.1 等会话：hop1 存 17.4(24.x 新修订)\n" +
            "            ;; -> 装了 17.4-2019 时中间跳重存 S019 修订\n" +
            "            ;; -> 免补丁 exe 转 16.6（全程三跳）\n" +
            "            path174 = _DR166_HopTo174(dir name brd)\n" +
            "            unless( path174 return(nil) )\n" +
            "            a174 = _DR166_FindMid174Allegro()\n" +
            "            if( a174 then\n" +
            "                pathS = _DR166_MidHop174(dir name path174 a174)\n" +
            "                unless( pathS return(nil) )\n" +
            "            else\n" +
            "                axlMsgPut(\"Downrev166: 未找到 SPB_17.4 安装, 跳过 S019 中间跳\")\n" +
            "                axlMsgPut(\"Downrev166: 24.x 存出的 17.4(新修订)可能转换失败(32000016), 失败请改用 17.4 会话执行\")\n" +
            "                pathS = path174\n" +
            "            )\n" +
            "            axlMsgPut(\"最后一跳: 17.4 -> 16.6 转换中...\")\n" +
            "            return( _DR166_RunExe(exe dir name pathS) )\n" +
            "        )\n",
            "        else\n" +
            "            ;; 23.1/24.1/25.1 等会话：新实例批处理存 17.4 中间文件再转（两跳）\n" +
            "            ;; 24.x 写出的 17.4 是新修订, 第二跳可能 32000016, 失败按命令行指引手工处理\n" +
            "            path174 = _DR166_HopTo174(dir name brd)\n" +
            "            unless( path174 return(nil) )\n" +
            "            axlMsgPut(\"第二跳: 17.4 -> 16.6 转换中...\")\n" +
            "            return( _DR166_RunExe(exe dir name path174) )\n" +
            "        )\n")));

        checkParen("util_downrev166.il", m);
        if (m.contains("_DR166_MidHop174(dir") || m.contains("_DR166_FindMid174Allegro()") || m.contains("a174 ="))
            throw new RuntimeException("midhop call sites remain, ABORT");
        if (m.indexOf('\r') >= 0) throw new RuntimeException("residue \\r");
        save(mod, GBK, m, mCrLf);
        System.out.println("OK: util_downrev166.il v1.3, two-hop restored");

        // help_map.dat
        Path help = ROOT.resolve("skill_src/core/help_map.dat");
        boolean hCrLf = read(help, GBK).contains("\r\n");
        String hm = load(help, GBK);
        hm = apply("help_map.dat", hm, List.of(new Edit(
            "（24.x/25.x 会话：新实例批处理存 17.4 中间文件(24.x 新修订)→17.4-2019 实例对话框 save6 重存 S019 修订→再转）",
            "（24.x/25.x 会话：新实例批处理驱动原生对话框存出 17.4 中间文件再转(两跳)；24.x 新修订可能 32000016, 命令行给手工重存指引）")));
        save(help, GBK, hm, hCrLf);
        System.out.println("OK: help_map.dat two-hop wording");

        // ASTB功能说明.md
        Path doc = ROOT.resolve("ASTB功能说明.md");
        boolean dCrLf = read(doc, UTF8).contains("\r\n");
        String dc = load(doc, UTF8);
        dc = apply("ASTB功能说明.md", dc, List.of(new Edit(
            "| PCB 降版本 16.6 | 自带免补丁运行时 downrev166_rt 原地转 16.6；24.x 三跳（17.4 中间文件→17.4-2019 重存 S019 修订→转 16.6）；失败原因见输出目录同名 .log |",
            "| PCB 降版本 16.6 | 自带免补丁运行时 downrev166_rt 原地转 16.6；24.x 两跳（存 17.4 中间文件再转，24.x 新修订可能 32000016 需手工重存）；失败原因见输出目录同名 .log |")));
        save(doc, UTF8, dc, dCrLf);
        System.out.println("OK: ASTB功能说明.md two-hop wording");

        System.out.println("ALL OK");
    }
}
