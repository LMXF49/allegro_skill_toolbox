/* ============================================================================
 * File        : patch_20261004_downrev_v14_verified.java
 * Author      : ASTB Team
 * Created     : 2026-10-04
 * Version     : 1.0
 * Description : util_downrev166.il v1.4 实机验证记录补登（AGENTS.md
 *               2.4: 实机验证通过须补修订记录）。用户 2026-10-04 实机
 *               确认: 24.1 板两跳 + adl_patched 自动回落重转成功出
 *               _166.brd。底面焊盘翻转风险条目改为使用提示。
 * Usage       : 同前补丁。
 * ============================================================================
 */
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;

public class patch_20261004_downrev_v14_verified {

    static final Charset GBK = Charset.forName("GBK");
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
        m = apply("mod", m, List.of(
            new Edit(
                ";             SYExit 闸门), 产物 md5=90867801dcefb88cdc1de7bf73a1e07e\n",
                ";             SYExit 闸门), 产物 md5=90867801dcefb88cdc1de7bf73a1e07e\n" +
                ";             ——2026-10-04 实机验证通过（用户确认：24.1 板两跳\n" +
                ";             +adl 回落重转成功出 _166.brd）\n"),
            new Edit(
                ";   3) adl_patched 回落路径：仅验证过 total converted=1 与日志,\n" +
                ";      底面焊盘是否翻转须在 16.6 实机核对（RK3588 旧版实测翻过）\n",
                ";   3) adl_patched 回落路径：2026-10-04 实机转换通过；底面焊盘\n" +
                ";      翻转风险仍在, 转后使用者需在 16.6 抽查底面（RK3588 旧版\n" +
                ";      实测翻过）\n")));
        checkParen("util_downrev166.il", m);
        if (m.indexOf('\r') >= 0) throw new RuntimeException("residue \\r");
        save(mod, GBK, m, mCrLf);
        System.out.println("ALL OK");
    }
}
