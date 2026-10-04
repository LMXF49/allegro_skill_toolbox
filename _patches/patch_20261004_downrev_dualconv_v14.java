/* ============================================================================
 * File        : patch_20261004_downrev_dualconv_v14.java
 * Author      : ASTB Team
 * Created     : 2026-10-04
 * Version     : 1.0
 * Description : util_downrev166.il v1.3 -> v1.4：双转换器接线。
 *               对比实证(2026-10-04, D:\Temp\dr_test)：
 *               - 电路精灵/阿狸狗构建(md5 8876705d, 2022-01, 底座旧)：
 *                 S019 修订直通、数据干净，但 24.x 新修订 32000016 拒转
 *               - 官方 17.4 adl + 11 字节补丁(=adl_patched,
 *                 md5 90867801, 已复现： file offset 315270x5 + 315278x6
 *                 改 0x90, NOP 掉 SYExit 闸门调用)：24.x 新修订可读,
 *                 total converted 1 实证；已知风险： 底面贴片引脚层
 *                 搬家顶部(旧版 v3.1 RK3588 实测)
 *               策略： 主转换器仍是电路精灵构建；第二跳 32000016 时
 *               自动回落 adl_patched 重转(SPB_17.4 DLL 环境)并警告
 *               底面焊盘风险；无 adl/无 SPB_17.4 时给手工指引。
 *               新增 _DR166_FindADLPatched/_DR166_FindSPB174Bin/
 *               _DR166_RunExeSmart; _DR166_RunExe 加 pathPrepend 可选参,
 *               失败返回 'revfail 由 Smart 层决策。
 *               tools/adl_patched.exe 已入仓 skill_src/tools/(随安装包
 *               部署), astb_setup.iss 加对应 Source 行。
 * Usage       : "C:\Program Files\Amazon Corretto\jdk21.0.10_7\bin\java.exe" ^
 *                 _patches\patch_20261004_downrev_dualconv_v14.java
 * Encoding    : 本文件 UTF-8；GBK 文件显式 Charset.forName("GBK") 往返。
 * ============================================================================
 */
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;

public class patch_20261004_downrev_dualconv_v14 {

    static final Charset GBK = Charset.forName("GBK");
    static final Charset UTF8 = Charset.forName("UTF-8");
    static final Charset LATIN1 = Charset.forName("ISO-8859-1");
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
        List<Edit> me = new ArrayList<>();

        // 1) 版本 1.3 -> 1.4
        me.add(new Edit("; 版本      : 1.3\n", "; 版本      : 1.4\n"));

        // 2) 依赖模块补 adl_patched
        me.add(new Edit(
            "; 依赖模块  : core/utils.il、core/trans.il；\n" +
            ";             tools/downrev166_rt/（免补丁转换运行时 exe+DLL）\n",
            "; 依赖模块  : core/utils.il、core/trans.il；\n" +
            ";             tools/downrev166_rt/（免补丁转换运行时 exe+DLL）\n" +
            ";             tools/adl_patched.exe（可选, 32000016 自动回落兜底）\n"));

        // 3) 功能描述加双转换器段（在 v1.3 失败提示句之后）
        me.add(new Edit(
            ";             开（32000016, 实测），失败时命令行自动识别并给手工重存指引。\n",
            ";             开（32000016, 实测）。\n" +
            ";             v1.4 起双转换器：主转换器为电路精灵/阿狸狗免补丁构\n" +
            ";             建（S019 直通、数据干净）；第二跳报 32000016 时自动\n" +
            ";             回落官方 17.4 adl 补丁版 adl_patched（11 字节补丁可\n" +
            ";             复现, 配方见 _DR166_FindADLPatched 注释）重转，并警告\n" +
            ";             其底面贴片引脚层搬家顶部的已知风险，转完需在 16.6\n" +
            ";             核对底面焊盘。\n"));

        // 4) 修改记录加 v1.4
        me.add(new Edit(
            ";             给手工重存指引，其余失败保持通用提示\n",
            ";             给手工重存指引，其余失败保持通用提示\n" +
            ";   2026-10-04 v1.4 ASTB Team 双转换器接线：主转换器 32000016 拒转\n" +
            ";             时自动回落 tools/adl_patched.exe 重转（需 SPB_17.4\n" +
            ";             DLL 环境, 警告底面焊盘风险）；破解配方实证可复现：\n" +
            ";             官方 17.4 allegro_downrev_library.exe 的 file offset\n" +
            ";             315270 起 5 字节 + 315278 起 6 字节改 0x90(NOP 掉\n" +
            ";             SYExit 闸门), 产物 md5=90867801dcefb88cdc1de7bf73a1e07e\n"));

        // 5) 实机待验证加第 3 条
        me.add(new Edit(
            ";   2) 17.4-2019 实例中间跳（save6 重存 S019）：旧版 v3.2 实测过,\n" +
            ";      本重写版未回归\n",
            ";   2) 17.4-2019 实例中间跳（save6 重存 S019）：旧版 v3.2 实测过,\n" +
            ";      本重写版未回归（v1.3 起中间跳已撤, 此条仅存档）\n" +
            ";   3) adl_patched 回落路径：仅验证过 total converted=1 与日志,\n" +
            ";      底面焊盘是否翻转须在 16.6 实机核对（RK3588 旧版实测翻过）\n"));

        // 6) _DR166_FindExe 之后插 FindADLPatched + FindSPB174Bin
        me.add(new Edit(
            ";------------------------------------------------------------------------\n" +
            "; 函数名  : _DR166_OutputPath\n",
            ";------------------------------------------------------------------------\n" +
            "; 函数名  : _DR166_FindADLPatched\n" +
            "; 功能    : 定位官方 17.4 adl 补丁版（tools/adl_patched.exe, 兜底\n" +
            ";           转换器）\n" +
            "; 返回值  : exe 路径 / nil\n" +
            "; 备注    : 主转换器（电路精灵/阿狸狗构建）认不得 24.x 新修订\n" +
            ";           (32000016) 时回落用；已知风险：底面贴片引脚层可能搬到\n" +
            ";           顶部（旧版 v3.1 RK3588 实测）, 故只作兜底并强制警告。\n" +
            ";           破解配方可复现：官方 17.4 allegro_downrev_library.exe\n" +
            ";           的 file offset 315270 起 5 字节与 315278 起 6 字节改\n" +
            ";           0x90（NOP 掉 SYExit 闸门调用）, 产物 md5=\n" +
            ";           90867801dcefb88cdc1de7bf73a1e07e\n" +
            ";------------------------------------------------------------------------\n" +
            "procedure( _DR166_FindADLPatched()\n" +
            "    prog((cand)\n" +
            "        cand = strcat(ASTB_GLOBAL->ToolboxPath \"/tools/adl_patched.exe\")\n" +
            "        when( isFile(cand)\n" +
            "            ASTB_DebugLog(strcat(\"Downrev166: adl_patched from toolbox \" cand))\n" +
            "            return(cand)\n" +
            "        )\n" +
            "        ASTB_DebugLog(\"Downrev166: adl_patched NOT found\")\n" +
            "        return(nil)\n" +
            "    )\n" +
            ")\n" +
            "\n" +
            ";------------------------------------------------------------------------\n" +
            "; 函数名  : _DR166_FindSPB174Bin\n" +
            "; 功能    : 定位 SPB_17.4 的 tools/bin（adl_patched 运行所需 DLL 环境）\n" +
            "; 返回值  : bin 目录 / nil\n" +
            ";------------------------------------------------------------------------\n" +
            "procedure( _DR166_FindSPB174Bin()\n" +
            "    prog((roots r)\n" +
            "        roots = nil\n" +
            "        foreach( d '(\"D:/Cadence\" \"C:/Cadence\" \"E:/Cadence\" \"F:/Cadence\" \"G:/Cadence\")\n" +
            "            roots = append1(roots strcat(d \"/SPB_17.4/tools/bin\"))\n" +
            "        )\n" +
            "        foreach( r roots\n" +
            "            when( isDir(r)\n" +
            "                return(r)\n" +
            "            )\n" +
            "        )\n" +
            "        return(nil)\n" +
            "    )\n" +
            ")\n" +
            "\n" +
            ";------------------------------------------------------------------------\n" +
            "; 函数名  : _DR166_OutputPath\n"));

        // 7) RunExe 签名加 pathPrepend + prog 加 pp
        me.add(new Edit(
            "procedure( _DR166_RunExe(exe dir name brd)\n" +
            "    prog((outPath batPath logPath port ok sideLog)\n",
            "procedure( _DR166_RunExe(exe dir name brd @optional (pathPrepend nil))\n" +
            "    prog((outPath batPath logPath port ok sideLog pp)\n"));

        // 8) PATH 逻辑： pathPrepend 优先
        me.add(new Edit(
            "        ;; 自带运行时必须配自有 DLL 目录置顶 PATH(实测混用 17.4 会话\n" +
            "        ;; DLL 时 exe 静默退出, 零日志); 外部 exe 环境自管\n" +
            "        when( rexMatchp(\"downrev166_rt\" exe)\n" +
            "          fprintf(port \"set \\\"PATH=%s;%%PATH%%\\\"\\r\\n\"\n" +
            "                   strcat(ASTB_GLOBAL->ToolboxPath\n" +
            "                           \"/tools/downrev166_rt/tools/bin\"))\n" +
            "        )\n",
            "        ;; 自带运行时必须配自有 DLL 目录置顶 PATH(实测混用 17.4 会话\n" +
            "        ;; DLL 时 exe 静默退出, 零日志); pathPrepend 显式指定优先\n" +
            "        pp = pathPrepend\n" +
            "        unless( pp\n" +
            "          when( rexMatchp(\"downrev166_rt\" exe)\n" +
            "            pp = strcat(ASTB_GLOBAL->ToolboxPath\n" +
            "                         \"/tools/downrev166_rt/tools/bin\")\n" +
            "          )\n" +
            "        )\n" +
            "        when( pp\n" +
            "          fprintf(port \"set \\\"PATH=%s;%%PATH%%\\\"\\r\\n\" pp)\n" +
            "        )\n"));

        // 9) 失败分支: 副本删除提前, 32000016 返回 'revfail 交给 Smart 层
        me.add(new Edit(
            "            ;; 具体原因在输出同名 .log，失败只命令行留痕不弹窗\n" +
            "            sideLog = strcat(substring(outPath 1 strlen(outPath)-4) \".log\")\n" +
            "            if( and(isFile(sideLog) _DR166_LogHasCode(sideLog \"32000016\")) then\n" +
            "                axlMsgPut(\"降版本失败: 该 17.4 是 24.x 写入的新修订, 本转换器(17.4-2019) 打不开(32000016)\")\n" +
            "                axlMsgPut(strcat(\"手工处理: 用 17.4 打开 \" brd \" 经 File>Export>Downrev design 选 17.4(17.4-2019) 重存, 再于 17.4 会话重跑本命令\"))\n" +
            "            else\n" +
            "                axlMsgPut(strcat(\"降版本失败: 设计含 16.6 不支持的特性, 详见 \" sideLog))\n" +
            "            )\n" +
            "            ;; 删除未转换的副本（它只是源文件的复制品，非转换产物）\n" +
            "            when( isFile(outPath)\n" +
            "                errset(deleteFile(outPath) t)\n" +
            "            )\n" +
            "            return(nil)\n" +
            "        )\n",
            "            ;; 具体原因在输出同名 .log，失败只命令行留痕不弹窗\n" +
            "            sideLog = strcat(substring(outPath 1 strlen(outPath)-4) \".log\")\n" +
            "            ;; 删除未转换的副本（它只是源文件的复制品，非转换产物）\n" +
            "            when( isFile(outPath)\n" +
            "                errset(deleteFile(outPath) t)\n" +
            "            )\n" +
            "            if( and(isFile(sideLog) _DR166_LogHasCode(sideLog \"32000016\")) then\n" +
            "                ;; 24.x 新修订拒转: 交由 _DR166_RunExeSmart 决定回落重转\n" +
            "                return('revfail)\n" +
            "            else\n" +
            "                axlMsgPut(strcat(\"降版本失败: 设计含 16.6 不支持的特性, 详见 \" sideLog))\n" +
            "                return(nil)\n" +
            "            )\n" +
            "        )\n"));

        // 10) 插 _DR166_RunExeSmart(Main 横幅前)
        me.add(new Edit(
            ";------------------------------------------------------------------------\n" +
            "; 函数名  : _DR166_Main\n",
            ";------------------------------------------------------------------------\n" +
            "; 函数名  : _DR166_RunExeSmart\n" +
            "; 功能    : RunExe 智能包装：主转换器 32000016 拒转(24.x 新修订)\n" +
            ";           时自动回落官方 17.4 adl 补丁版重转(SPB_17.4 DLL 环境),\n" +
            ";           并警告其底面焊盘翻转风险; 兜底不可用时给手工指引\n" +
            "; 参数    : 同 _DR166_RunExe\n" +
            "; 返回值  : t 成功 / nil 失败\n" +
            ";------------------------------------------------------------------------\n" +
            "procedure( _DR166_RunExeSmart(exe dir name brd)\n" +
            "    prog((r adl bin)\n" +
            "        r = _DR166_RunExe(exe dir name brd)\n" +
            "        when( equal(r t) return(t) )\n" +
            "        unless( r == 'revfail\n" +
            "            return(nil) )\n" +
            "        ;; 主转换器认不得 24.x 新修订, 回落 adl 补丁版\n" +
            "        axlMsgPut(\"主转换器拒转(32000016, 24.x 新修订), 尝试官方 17.4 adl 补丁版重转...\")\n" +
            "        adl = _DR166_FindADLPatched()\n" +
            "        unless( adl\n" +
            "            axlMsgPut(\"Downrev166: 未找到 tools/adl_patched.exe, 无法自动重转\")\n" +
            "            axlMsgPut(strcat(\"手工处理: 用 17.4 打开 \" brd \" 经 File>Export>Downrev design 选 17.4(17.4-2019) 重存, 再于 17.4 会话重跑本命令\"))\n" +
            "            return(nil) )\n" +
            "        axlMsgPut(\"注意: adl 补丁版已知风险——底面贴片引脚层可能搬到顶层(实测), 转完请在 16.6 核对底面焊盘\")\n" +
            "        bin = _DR166_FindSPB174Bin()\n" +
            "        unless( bin\n" +
            "            axlMsgPut(\"Downrev166: 未找到 SPB_17.4 安装(DLL 环境), 无法用 adl 补丁版重转\")\n" +
            "            return(nil) )\n" +
            "        return( _DR166_RunExe(adl dir name brd bin) )\n" +
            "    )\n" +
            ")\n" +
            "\n" +
            ";------------------------------------------------------------------------\n" +
            "; 函数名  : _DR166_Main\n"));

        // 11) Main 两处调用改走 Smart
        me.add(new Edit(
            "            return( _DR166_RunExe(exe dir name brd) )\n",
            "            return( _DR166_RunExeSmart(exe dir name brd) )\n"));
        me.add(new Edit(
            "            return( _DR166_RunExe(exe dir name path174) )\n",
            "            return( _DR166_RunExeSmart(exe dir name path174) )\n"));

        m = apply("util_downrev166.il", m, me);
        checkParen("util_downrev166.il", m);
        if (m.indexOf('\r') >= 0) throw new RuntimeException("residue \\r");
        save(mod, GBK, m, mCrLf);
        System.out.println("OK: util_downrev166.il v1.4, dual converter wired");

        // help_map.dat：回落说明
        Path help = ROOT.resolve("skill_src/core/help_map.dat");
        boolean hCrLf = read(help, GBK).contains("\r\n");
        String hm = load(help, GBK);
        hm = apply("help_map.dat", hm, List.of(new Edit(
            "（24.x/25.x 会话：新实例批处理驱动原生对话框存出 17.4 中间文件再转(两跳)；24.x 新修订可能 32000016, 命令行给手工重存指引）",
            "（24.x/25.x 会话：新实例批处理驱动原生对话框存出 17.4 中间文件再转(两跳)；主转换器遇 24.x 新修订报 32000016 时自动回落官方 adl 补丁版重转, 底面焊盘需在 16.6 核对）")));
        save(help, GBK, hm, hCrLf);
        System.out.println("OK: help_map.dat fallback wording");

        // ASTB功能说明.md
        Path doc = ROOT.resolve("ASTB功能说明.md");
        boolean dCrLf = read(doc, UTF8).contains("\r\n");
        String dc = load(doc, UTF8);
        dc = apply("ASTB功能说明.md", dc, List.of(new Edit(
            "| PCB 降版本 16.6 | 自带免补丁运行时 downrev166_rt 原地转 16.6；24.x 两跳（存 17.4 中间文件再转，24.x 新修订可能 32000016 需手工重存）；失败原因见输出目录同名 .log |",
            "| PCB 降版本 16.6 | 自带免补丁运行时 downrev166_rt 原地转 16.6；24.x 两跳（存 17.4 中间文件再转）；主转换器遇 24.x 新修订自动回落 adl 补丁版重转（底面焊盘需核对）；失败原因见输出目录同名 .log |")));
        save(doc, UTF8, dc, dCrLf);
        System.out.println("OK: ASTB功能说明.md fallback wording");

        // astb_setup.iss：adl_patched 打包行
        Path iss = ROOT.resolve("tools/installer/astb_setup.iss");
        boolean iCrLf = read(iss, LATIN1).contains("\r\n");
        String im = load(iss, LATIN1);
        im = apply("astb_setup.iss", im, List.of(new Edit(
            "Source: \"{#SkillSrc}\\tools\\downrev166_rt\\*\"; DestDir: \"{app}\\skill\\tools\\downrev166_rt\"; Flags: ignoreversion recursesubdirs skipifsourcedoesntexist\n",
            "Source: \"{#SkillSrc}\\tools\\downrev166_rt\\*\"; DestDir: \"{app}\\skill\\tools\\downrev166_rt\"; Flags: ignoreversion recursesubdirs skipifsourcedoesntexist\n" +
            "Source: \"{#SkillSrc}\\tools\\adl_patched.exe\"; DestDir: \"{app}\\skill\\tools\"; Flags: ignoreversion skipifsourcedoesntexist\n")));
        save(iss, LATIN1, im, iCrLf);
        System.out.println("OK: astb_setup.iss adl_patched source line");

        System.out.println("ALL OK");
    }
}
