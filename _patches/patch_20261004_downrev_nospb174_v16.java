/* ============================================================================
 * File        : patch_20261004_downrev_nospb174_v16.java
 * Author      : ASTB Team
 * Created     : 2026-10-04
 * Version     : 1.0
 * Description : util_downrev166.il v1.5 -> v1.6：解除 SPB_17.4 安装依赖。
 *               实证(D:\Temp\dr_test, 2026-10-04): adl_patched 仅以
 *               downrev166_rt 自带 DLL 目录为 PATH(完全不沾 SPB_17.4)
 *               转换 24.x 新修订文件, total converted 1, exit 0——
 *               工具箱自包含, 免装 17.4。
 *               - adl_patched.exe 迁入 tools/downrev166_rt/tools/bin/
 *                 (与 DLL 同目录, exe 目录优先解析, 抗 PATH 污染);
 *                 payload 旧副本 tools/adl_patched.exe 已删; iss 单独的
 *                 adl Source 行移除(rt 通配行已覆盖)
 *               - _DR166_FindADLPatched 改指 rt bin; 删
 *                 _DR166_FindSPB174Bin(SPB_17.4 不再是任何前置);
 *                 RunExeSmart 主升段直接用 rt bin 作 pathPrepend
 *               - 版本 1.6 + 修订记录 + 实机待验证更新
 * Usage       : "C:\Program Files\Amazon Corretto\jdk21.0.10_7\bin\java.exe" ^
 *                 _patches\patch_20261004_downrev_nospb174_v16.java
 * Encoding    : 本文件 UTF-8；GBK 文件显式 Charset.forName("GBK") 往返。
 * ============================================================================
 */
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;

public class patch_20261004_downrev_nospb174_v16 {

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

    static String deleteBlock(String tag, String s, String bannerKey, String nextBannerKey) {
        int k1 = s.indexOf("; 函数名  : " + bannerKey);
        int k2 = s.indexOf("; 函数名  : " + nextBannerKey);
        if (k1 < 0 || k2 < 0 || k2 <= k1) throw new RuntimeException(tag + " block keys not found, ABORT");
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
        List<Edit> me = new ArrayList<>();

        // 1) 版本 1.5 -> 1.6
        me.add(new Edit("; 版本      : 1.5\n", "; 版本      : 1.6\n"));

        // 2) 依赖模块说明更新
        me.add(new Edit(
            ";             tools/adl_patched.exe（可选, 32000016 自动回落兜底）\n",
            ";             tools/downrev166_rt/tools/bin/adl_patched.exe（主升转换器,\n" +
            ";             与该目录 DLL 自包含, 免装 SPB_17.4）\n"));

        // 3) 功能描述双转换器段更新
        me.add(new Edit(
            ";             v1.5 起双转换器（主备互换）：主转换器为官方 17.4 adl\n" +
            ";             补丁版 adl_patched（11 字节补丁可复现, 配方见\n" +
            ";             _DR166_FindADLPatched 注释；24.x 新修订可读, 底面焊盘\n" +
            ";             层已实证正确）；adl 失败自动回落电路精灵/阿狸狗免补丁\n" +
            ";             构建。ASTB_DOWNREV_EXE 环境变量指定仍最优先。\n",
            ";             v1.5 起双转换器（主备互换）：主转换器为官方 17.4 adl\n" +
            ";             补丁版 adl_patched（11 字节补丁可复现, 配方见\n" +
            ";             _DR166_FindADLPatched 注释；24.x 新修订可读, 底面焊盘\n" +
            ";             层已实证正确）；adl 失败自动回落电路精灵/阿狸狗免补丁\n" +
            ";             构建。ASTB_DOWNREV_EXE 环境变量指定仍最优先。\n" +
            ";             v1.6: adl_patched 迁入 rt bin 与自带 DLL 同目录,\n" +
            ";             解除 SPB_17.4 安装依赖(免装 17.4 的机器可用, 已实证)。\n"));

        // 4) 修改记录加 v1.6
        me.add(new Edit(
            ";             最优先；adl 每次会话首用命令行提示抽查底面焊盘\n",
            ";             最优先；adl 每次会话首用命令行提示抽查底面焊盘\n" +
            ";   2026-10-04 v1.6 ASTB Team 解除 SPB_17.4 依赖：实证 adl_patched\n" +
            ";             只吃 downrev166_rt 自带 DLL 即可转换新修订文件\n" +
            ";             (D:\\Temp\\dr_test, total converted 1); adl 迁入\n" +
            ";             tools/downrev166_rt/tools/bin/ 同目录解析抗 PATH 污染;\n" +
            ";             删 _DR166_FindSPB174Bin(SPB_17.4 不再是任何前置)\n"));

        // 5) FindADLPatched 改指 rt bin
        me.add(new Edit(
            "        cand = strcat(ASTB_GLOBAL->ToolboxPath \"/tools/adl_patched.exe\")\n",
            "        cand = strcat(ASTB_GLOBAL->ToolboxPath\n" +
            "                \"/tools/downrev166_rt/tools/bin/adl_patched.exe\")\n"));

        // 6) 删 FindSPB174Bin(ADLPatched 之后、OutputPath 之前)
        m = apply("mod", m, me);
        m = deleteBlock("mod", m, "_DR166_FindSPB174Bin", "_DR166_OutputPath");
        System.out.println("OK: _DR166_FindSPB174Bin removed");

        // 7) RunExeSmart 主升段：去 bin 查找, 直接用 rt bin
        m = apply("mod", m, List.of(
            new Edit(
                "    prog((r adl bin env)\n",
                "    prog((r adl rtbin env)\n"),
            new Edit(
                "        ;; 2) 主转换器: 官方 17.4 adl 补丁版(需 SPB_17.4 DLL 环境)\n" +
                "        adl = _DR166_FindADLPatched()\n" +
                "        bin = _DR166_FindSPB174Bin()\n" +
                "        if( and(adl bin) then\n",
                "        ;; 2) 主转换器: 官方 17.4 adl 补丁版(配自带 rt DLL, 免装 SPB_17.4)\n" +
                "        adl = _DR166_FindADLPatched()\n" +
                "        if( adl then\n"),
            new Edit(
                "            r = _DR166_RunExe(adl dir name brd bin)\n",
                "            rtbin = strcat(ASTB_GLOBAL->ToolboxPath\n" +
                "                    \"/tools/downrev166_rt/tools/bin\")\n" +
                "            r = _DR166_RunExe(adl dir name brd rtbin)\n"),
            new Edit(
                "        else\n" +
                "            when( null(adl)\n" +
                "                axlMsgPut(\"Downrev166: 未找到 tools/adl_patched.exe, 直接用免补丁运行时\") )\n" +
                "            when( and(adl null(bin))\n" +
                "                axlMsgPut(\"Downrev166: 未找到 SPB_17.4(DLL 环境), adl 无法运行, 直接用免补丁运行时\") )\n" +
                "        )\n",
                "        else\n" +
                "            axlMsgPut(\"Downrev166: 未找到 adl_patched.exe, 直接用免补丁运行时\")\n" +
                "        )\n")));

        checkParen("util_downrev166.il", m);
        if (m.contains("bin = _DR166_FindSPB174Bin")) throw new RuntimeException("FindSPB174Bin call site remains, ABORT");
        if (m.contains("/tools/adl_patched.exe\"")) throw new RuntimeException("stale adl path remains, ABORT");
        if (m.indexOf('\r') >= 0) throw new RuntimeException("residue \\r");
        save(mod, GBK, m, mCrLf);
        System.out.println("OK: util_downrev166.il v1.6, SPB_17.4 dependency removed");

        // astb_setup.iss：移除单独的 adl 行(rt 通配已覆盖)
        Path iss = ROOT.resolve("tools/installer/astb_setup.iss");
        boolean iCrLf = read(iss, LATIN1).contains("\r\n");
        String im = load(iss, LATIN1);
        im = apply("astb_setup.iss", im, List.of(new Edit(
            "Source: \"{#SkillSrc}\\tools\\downrev166_rt\\*\"; DestDir: \"{app}\\skill\\tools\\downrev166_rt\"; Flags: ignoreversion recursesubdirs skipifsourcedoesntexist\n" +
            "Source: \"{#SkillSrc}\\tools\\adl_patched.exe\"; DestDir: \"{app}\\skill\\tools\"; Flags: ignoreversion skipifsourcedoesntexist\n",
            "Source: \"{#SkillSrc}\\tools\\downrev166_rt\\*\"; DestDir: \"{app}\\skill\\tools\\downrev166_rt\"; Flags: ignoreversion recursesubdirs skipifsourcedoesntexist\n")));
        save(iss, LATIN1, im, iCrLf);
        System.out.println("OK: astb_setup.iss standalone adl line removed (covered by rt wildcard)");

        System.out.println("ALL OK");
    }
}
