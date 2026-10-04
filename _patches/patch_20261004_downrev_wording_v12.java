/* ============================================================================
 * File        : patch_20261004_downrev_wording_v12.java
 * Author      : ASTB Team
 * Created     : 2026-10-04
 * Version     : 1.0
 * Description : util_downrev166.il v1.1 -> v1.2：术语与实证修正。
 *               用户指正: 24.x 对话框选项 "17.4 (22.1)" 的含义是
 *               "22.1 可以打开的 17.4", 不是 22.1 版本。本机实证:
 *               dbstat 对对话框产物显示 17.4; 免补丁 exe 日志抬头
 *               "Downrev rev 17.4 to rev 16.6" 亦认其为 17.4; 失败
 *               日志 error in open drawing = 32000016。即 32000016 的
 *               真因是 24.x(22.1 代码线)写入的数据库修订新于
 *               17.4-2019(S019 修订), 2019 时代的 exe 打不开, 而非
 *               "版本不符"。全文 "22.1 血统" 等用语改述为 "24.x 新
 *               修订 / S019 修订"; 功能逻辑不变(中间跳仍是正解:
 *               17.4-2019 对话框 save6 重存即降修订, 19:11 成功实证)。
 * Usage       : "C:\Program Files\Amazon Corretto\jdk21.0.10_7\bin\java.exe" ^
 *                 _patches\patch_20261004_downrev_wording_v12.java
 * Encoding    : 本文件 UTF-8；GBK 文件显式 Charset.forName("GBK") 往返。
 * ============================================================================
 */
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;

public class patch_20261004_downrev_wording_v12 {

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

        // 1) 版本号 1.1 -> 1.2
        me.add(new Edit("; 版本      : 1.1\n", "; 版本      : 1.2\n"));

        // 2) 功能描述 24.x 段改述
        me.add(new Edit(
            ";             对话框选 \"Save design to 17.4\" 存 22.1 血统中间文件）\n" +
            ";             -> 17.4-2019 实例对话框 save6 重存 S019 血统（免补丁\n" +
            ";             exe 只认 S019, 22.1 血统报 32000016 实测）-> 主路转。\n",
            ";             对话框选 \"Save design to 17.4\" 存中间文件（dbstat\n" +
            ";             显示 17.4，实为 24.x/22.1 代码线写入的新修订，\n" +
            ";             17.4-2019 时代的免补丁 exe 打不开，32000016 实测）\n" +
            ";             -> 17.4-2019 实例对话框 save6 重存 S019 修订 -> 主路。\n"));

        // 3) v1.1 记录用语修正 + 追加 v1.2 记录
        me.add(new Edit(
            ";             为 22.1 血统, 免补丁 exe 拒转 32000016, 实测仅认 17.4\n" +
            ";             对话框 save6 的 S019 血统）；未装 SPB_17.4 时降级\n" +
            ";             为直转并命令行告警\n",
            ";             为 24.x 写出的 17.4 新修订, 免补丁 exe 拒转 32000016,\n" +
            ";             实测仅认 17.4 对话框 save6 的 S019 修订）；未装\n" +
            ";             SPB_17.4 时降级为直转并命令行告警\n" +
            ";   2026-10-04 v1.2 ASTB Team 术语与实证修正：用户指出 \"17.4 (22.1)\"\n" +
            ";             指 22.1 可打开的 17.4、不是 22.1 版本——dbstat 实测\n" +
            ";             对话框产物确为 17.4, 与 exe 日志抬头 \"Downrev rev\n" +
            ";             17.4 to rev 16.6\" 一致；32000016 真因是 24.x 写入\n" +
            ";             修订新于 17.4-2019(S019), 非版本不符。全文用语同步\n" +
            ";             改述, 功能逻辑不变\n"));

        // 4) FindMid174Allegro 备注
        me.add(new Edit(
            "; 备注    : 24.x 原生对话框存出的 17.4 是 22.1 血统，免补丁 exe 不认\n" +
            ";           (32000016, 实测)；必须经 17.4-2019 对话框 save6 重存为\n" +
            ";           S019 血统后才转得动\n",
            "; 备注    : 24.x 原生对话框存出的 17.4 为 24.x 写入的新修订（dbstat\n" +
            ";           仍显示 17.4）, 17.4-2019 时代的免补丁 exe 打不开\n" +
            ";           (32000016, 实测)；必须经 17.4-2019 对话框 save6 重存为\n" +
            ";           S019 修订后才转得动\n"));

        // 5) MidHop 横幅 + 返回值
        me.add(new Edit(
            ";           (\"Save design to 17.4 (17.4-2019)\"), 把 22.1 血统的\n" +
            ";           17.4 中间文件重存为 S019 血统，免补丁 exe 才认\n",
            ";           (\"Save design to 17.4 (17.4-2019)\"), 把 24.x 新修订的\n" +
            ";           17.4 中间文件重存为 S019 修订，免补丁 exe 才认\n"));
        me.add(new Edit(
            "; 返回值  : S019 血统 17.4 文件路径 / nil(失败)\n",
            "; 返回值  : S019 修订 17.4 文件路径 / nil(失败)\n"));

        // 6) 中间跳两条消息
        me.add(new Edit(
            "    axlMsgPut(\"中间跳: 17.4 实例重存 S019 血统(约 1 分钟, 请稍候)...\")\n",
            "    axlMsgPut(\"中间跳: 17.4 实例重存 S019 修订(约 1 分钟, 请稍候)...\")\n"));
        me.add(new Edit(
            "    axlMsgPut(\"中间跳完成(S019 血统)。\")\n",
            "    axlMsgPut(\"中间跳完成(S019 修订)。\")\n"));

        // 7) Main 分支注释
        me.add(new Edit(
            "            ;; 23.1/24.1/25.1 等会话：hop1 存 17.4(22.1 血统)\n" +
            "            ;; -> 装了 17.4-2019 时中间跳重存 S019 血统\n",
            "            ;; 23.1/24.1/25.1 等会话：hop1 存 17.4(24.x 新修订)\n" +
            "            ;; -> 装了 17.4-2019 时中间跳重存 S019 修订\n"));

        // 8) 未装 17.4 的告警措辞
        me.add(new Edit(
            "                axlMsgPut(\"Downrev166: 22.1 血统的 17.4 可能转换失败(32000016), 失败请改用 17.4 会话执行\")\n",
            "                axlMsgPut(\"Downrev166: 24.x 存出的 17.4(新修订)可能转换失败(32000016), 失败请改用 17.4 会话执行\")\n"));

        m = apply("util_downrev166.il", m, me);
        checkParen("util_downrev166.il", m);
        if (m.indexOf('\r') >= 0) throw new RuntimeException("residue \\r");
        save(mod, GBK, m, mCrLf);
        System.out.println("OK: util_downrev166.il v1.2, wording fixed");

        // help_map.dat
        Path help = ROOT.resolve("skill_src/core/help_map.dat");
        boolean hCrLf = read(help, GBK).contains("\r\n");
        String hm = load(help, GBK);
        hm = apply("help_map.dat", hm, List.of(new Edit(
            "（24.x/25.x 会话：新实例批处理存 17.4(22.1 血统)中间文件→17.4-2019 实例对话框 save6 重存 S019 血统→再转）",
            "（24.x/25.x 会话：新实例批处理存 17.4 中间文件(24.x 新修订)→17.4-2019 实例对话框 save6 重存 S019 修订→再转）")));
        save(help, GBK, hm, hCrLf);
        System.out.println("OK: help_map.dat wording fixed");

        // ASTB功能说明.md
        Path doc = ROOT.resolve("ASTB功能说明.md");
        boolean dCrLf = read(doc, UTF8).contains("\r\n");
        String dc = load(doc, UTF8);
        dc = apply("ASTB功能说明.md", dc, List.of(new Edit(
            "| PCB 降版本 16.6 | 自带免补丁运行时 downrev166_rt 原地转 16.6；24.x 三跳（17.4 中间文件→17.4-2019 重存 S019 血统→转 16.6）；失败原因见输出目录同名 .log |",
            "| PCB 降版本 16.6 | 自带免补丁运行时 downrev166_rt 原地转 16.6；24.x 三跳（17.4 中间文件→17.4-2019 重存 S019 修订→转 16.6）；失败原因见输出目录同名 .log |")));
        save(doc, UTF8, dc, dCrLf);
        System.out.println("OK: ASTB功能说明.md wording fixed");

        System.out.println("ALL OK");
    }
}
