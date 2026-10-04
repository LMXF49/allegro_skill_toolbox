/* ============================================================================
 * File        : patch_20261004_downrev_adlprimary_v15.java
 * Author      : ASTB Team
 * Created     : 2026-10-04
 * Version     : 1.0
 * Description : util_downrev166.il v1.4 -> v1.5：双转换器主备互换
 *               （用户决策：不用电路精灵的做主转换器）。
 *               - 主转换器: 官方 17.4 adl 补丁版 adl_patched（需
 *                 SPB_17.4 DLL 环境; 24.x 新修订可读, 底面焊盘层已
 *                 实证正确 d975a64）；每次会话首次使用命令行提示
 *                 抽查底面（ASTB_DOWNREV166_ADLWARN 防重）
 *               - 兜底: adl 失败自动回落电路精灵/阿狸狗免补丁构建
 *                 (S019 数据干净, 可救 adl 内容性失败的场)
 *               - ASTB_DOWNREV_EXE 环境变量指定仍最优先(只用指定)
 *               - RunExeSmart 整体重写; _DR166_FindExe/RunExe 不变
 *               - help_map.dat / ASTB功能说明.md 措辞同步
 * Usage       : "C:\Program Files\Amazon Corretto\jdk21.0.10_7\bin\java.exe" ^
 *                 _patches\patch_20261004_downrev_adlprimary_v15.java
 * Encoding    : 本文件 UTF-8；GBK 文件显式 Charset.forName("GBK") 往返。
 * ============================================================================
 */
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;

public class patch_20261004_downrev_adlprimary_v15 {

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

        // 1) 版本 1.4 -> 1.5
        me.add(new Edit("; 版本      : 1.4\n", "; 版本      : 1.5\n"));

        // 2) 功能描述双转换器段改主备互换
        me.add(new Edit(
            ";             v1.4 起双转换器：主转换器为电路精灵/阿狸狗免补丁构\n" +
            ";             建（S019 直通、数据干净）；第二跳报 32000016 时自动\n" +
            ";             回落官方 17.4 adl 补丁版 adl_patched（11 字节补丁可\n" +
            ";             复现, 配方见 _DR166_FindADLPatched 注释）重转，并警告\n" +
            ";             其底面贴片引脚层搬家顶部的已知风险，转完需在 16.6\n" +
            ";             核对底面焊盘。\n",
            ";             v1.5 起双转换器（主备互换）：主转换器为官方 17.4 adl\n" +
            ";             补丁版 adl_patched（11 字节补丁可复现, 配方见\n" +
            ";             _DR166_FindADLPatched 注释；24.x 新修订可读, 底面焊盘\n" +
            ";             层已实证正确）；adl 失败自动回落电路精灵/阿狸狗免补丁\n" +
            ";             构建。ASTB_DOWNREV_EXE 环境变量指定仍最优先。\n"));

        // 3) 修改记录加 v1.5
        me.add(new Edit(
            ";             +adl 回落重转成功出 _166.brd, 底面贴片焊盘层核对正确）\n",
            ";             +adl 回落重转成功出 _166.brd, 底面贴片焊盘层核对正确）\n" +
            ";   2026-10-04 v1.5 ASTB Team 按用户决策主备互换：主转换器改为官方\n" +
            ";             17.4 adl 补丁版（读写面宽），电路精灵/阿狸狗免补丁构\n" +
            ";             建降为 adl 失败兜底；ASTB_DOWNREV_EXE 环境变量指定仍\n" +
            ";             最优先；adl 每次会话首用命令行提示抽查底面焊盘\n"));

        // 4) 实机待验证加第 4 条
        me.add(new Edit(
            ";      用户已于 16.6 核对正确（RK3588 旧版曾实测翻转, 转后抽查\n" +
            ";      底面保留为建议习惯）\n",
            ";      用户已于 16.6 核对正确（RK3588 旧版曾实测翻转, 转后抽查\n" +
            ";      底面保留为建议习惯）\n" +
            ";   4) v1.5 主备互换（adl 主升 + rt 兜底）: 2026-10-04 起待实机,\n" +
            ";      重点看 adl 直接跑 17.x 原生板与 rt 兜底触发场景\n"));

        // 5) RunExeSmart 整体重写
        me.add(new Edit(
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
            ")\n",
            "procedure( _DR166_RunExeSmart(exe dir name brd)\n" +
            "    prog((r adl bin env)\n" +
            "        ;; 1) 环境变量显式指定: 最优先, 只用它\n" +
            "        env = getShellEnvVar(\"ASTB_DOWNREV_EXE\")\n" +
            "        when( and(env isFile(env))\n" +
            "            return( _DR166_RunExe(exe dir name brd) )\n" +
            "        )\n" +
            "        ;; 2) 主转换器: 官方 17.4 adl 补丁版(需 SPB_17.4 DLL 环境)\n" +
            "        adl = _DR166_FindADLPatched()\n" +
            "        bin = _DR166_FindSPB174Bin()\n" +
            "        if( and(adl bin) then\n" +
            "            unless( boundp('ASTB_DOWNREV166_ADLWARN) defvar(ASTB_DOWNREV166_ADLWARN nil) )\n" +
            "            unless( ASTB_DOWNREV166_ADLWARN\n" +
            "                axlMsgPut(\"提示: 主转换器为官方 17.4 adl 补丁版, 底面贴片焊盘层转后建议在 16.6 抽查\")\n" +
            "                ASTB_DOWNREV166_ADLWARN = t\n" +
            "            )\n" +
            "            r = _DR166_RunExe(adl dir name brd bin)\n" +
            "            when( equal(r t) return(t) )\n" +
            "            axlMsgPut(\"Downrev166: adl 补丁版转换失败, 尝试免补丁运行时兜底...\")\n" +
            "        else\n" +
            "            when( null(adl)\n" +
            "                axlMsgPut(\"Downrev166: 未找到 tools/adl_patched.exe, 直接用免补丁运行时\") )\n" +
            "            when( and(adl null(bin))\n" +
            "                axlMsgPut(\"Downrev166: 未找到 SPB_17.4(DLL 环境), adl 无法运行, 直接用免补丁运行时\") )\n" +
            "        )\n" +
            "        ;; 3) 兜底: 电路精灵/阿狸狗免补丁构建\n" +
            "        r = _DR166_RunExe(exe dir name brd)\n" +
            "        when( equal(r t) return(t) )\n" +
            "        when( r == 'revfail\n" +
            "            axlMsgPut(strcat(\"手工处理: 用 17.4 打开 \" brd \" 经 File>Export>Downrev design 选 17.4(17.4-2019) 重存, 再于 17.4 会话重跑本命令\")) )\n" +
            "        nil\n" +
            "    )\n" +
            ")\n"));

        m = apply("util_downrev166.il", m, me);
        checkParen("util_downrev166.il", m);
        if (m.indexOf('\r') >= 0) throw new RuntimeException("residue \\r");
        save(mod, GBK, m, mCrLf);
        System.out.println("OK: util_downrev166.il v1.5, adl primary");

        // help_map.dat
        Path help = ROOT.resolve("skill_src/core/help_map.dat");
        boolean hCrLf = read(help, GBK).contains("\r\n");
        String hm = load(help, GBK);
        hm = apply("help_map.dat", hm, List.of(new Edit(
            "（24.x/25.x 会话：新实例批处理驱动原生对话框存出 17.4 中间文件再转(两跳)；主转换器遇 24.x 新修订报 32000016 时自动回落官方 adl 补丁版重转, 底面焊盘需在 16.6 核对）",
            "（24.x/25.x 会话：新实例批处理驱动原生对话框存出 17.4 中间文件再转(两跳)；主转换器为官方 adl 补丁版, 失败自动回落免补丁运行时；底面焊盘建议转后 16.6 抽查）")));
        save(help, GBK, hm, hCrLf);
        System.out.println("OK: help_map.dat adl-primary wording");

        // ASTB功能说明.md
        Path doc = ROOT.resolve("ASTB功能说明.md");
        boolean dCrLf = read(doc, UTF8).contains("\r\n");
        String dc = load(doc, UTF8);
        dc = apply("ASTB功能说明.md", dc, List.of(new Edit(
            "| PCB 降版本 16.6 | 自带免补丁运行时 downrev166_rt 原地转 16.6；24.x 两跳（存 17.4 中间文件再转）；主转换器遇 24.x 新修订自动回落 adl 补丁版重转（底面焊盘需核对）；失败原因见输出目录同名 .log |",
            "| PCB 降版本 16.6 | 主转换器 adl_patched（官方 17.4 adl 补丁版）原地转 16.6，失败回落免补丁运行时；24.x 两跳（存 17.4 中间文件再转）；失败原因见输出目录同名 .log |")));
        save(doc, UTF8, dc, dCrLf);
        System.out.println("OK: ASTB功能说明.md adl-primary wording");

        System.out.println("ALL OK");
    }
}
