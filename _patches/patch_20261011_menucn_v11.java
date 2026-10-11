// patch_20261011_menucn_v11.java
// util_menucn.il v1.0 -> v1.1
//   实机报错修复：SKILL cons 第二参数必须是 list（"gl"），
//   cons(id lab) 字符串报错；原标签记录改存二元 list，
//   恢复端 cdr -> cadr。
// GBK 显式往返；锚点缺失即中止；幂等可重入。
// 运行：java -Dfile.encoding=UTF-8 _patches/patch_20261011_menucn_v11.java
import java.nio.charset.Charset;
import java.nio.file.*;

public class patch_20261011_menucn_v11 {
    static final Charset GBK = Charset.forName("GBK");
    static int applied = 0, skipped = 0;

    static String rep(String src, String oldS, String newS, String tag, boolean all) {
        int cnt = 0, i = 0;
        while ((i = src.indexOf(oldS, i)) >= 0) { cnt++; i += oldS.length(); }
        if (cnt == 0) {
            if (src.contains(newS.length() > 60 ? newS.substring(0, 60) : newS)) {
                System.out.println("[skip] " + tag + " (already applied)");
                skipped++;
                return src;
            }
            throw new RuntimeException("ANCHOR MISSING: " + tag);
        }
        if (!all && cnt != 1) throw new RuntimeException("ANCHOR NOT UNIQUE (" + cnt + "): " + tag);
        applied++;
        System.out.println("[ ok ] " + tag + (all ? " x" + cnt : ""));
        return all ? src.replace(oldS, newS)
                   : src.replaceFirst(java.util.regex.Pattern.quote(oldS),
                                      java.util.regex.Matcher.quoteReplacement(newS));
    }

    static void checkParens(String s, Path p) {
        int depth = 0; boolean inStr = false, inCmt = false;
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            if (inCmt) { if (c == '\n') inCmt = false; continue; }
            if (inStr) { if (c == '\\') i++; else if (c == '"') inStr = false; continue; }
            if (c == ';') inCmt = true;
            else if (c == '"') inStr = true;
            else if (c == '(') depth++;
            else if (c == ')') depth--;
            if (depth < 0) throw new RuntimeException("paren underflow in " + p);
        }
        if (depth != 0 || inStr)
            throw new RuntimeException("paren/string imbalance in " + p + " depth=" + depth);
    }

    public static void main(String[] a) throws Exception {
        Path f = Paths.get("G:\\ASTB\\skill_src\\modules\\utilities\\util_menucn.il");
        String src = new String(Files.readAllBytes(f), GBK);

        src = rep(src, "; 版本      : 1.0\n", "; 版本      : 1.1\n", "version bump", false);

        src = rep(src,
            "; 修改记录  :\n" +
            ";   2026-10-11 v1.0 ASTB Team 初始创建（翻译数据 config/menucn_zh.dat：\n",
            "; 修改记录  :\n" +
            ";   2026-10-11 v1.1 ASTB Team 实机报错修复：SKILL cons 第二参数\n" +
            ";                必须是 list（type template \"gl\"），原标签记录\n" +
            ";                改存二元 list，恢复端 cdr 改 cadr\n" +
            ";   2026-10-11 v1.0 ASTB Team 初始创建（翻译数据 config/menucn_zh.dat：\n",
            "revision record", false);

        src = rep(src,
            "ASTB_MENUCN_ORIG = cons(cons(id lab) ASTB_MENUCN_ORIG)",
            "ASTB_MENUCN_ORIG = cons(list(id lab) ASTB_MENUCN_ORIG)",
            "cons fix", true);

        src = rep(src,
            "                r = errset(axlUIMenuChange(car(pair) 'display cdr(pair)) t)\n",
            "                r = errset(axlUIMenuChange(car(pair) 'display cadr(pair)) t)\n",
            "restore cadr", false);

        src = rep(src,
            "printf(\"[ASTB] util_menucn.il v1.0 loaded\\n\")\n",
            "printf(\"[ASTB] util_menucn.il v1.1 loaded\\n\")\n",
            "printf bump", false);

        checkParens(src, f);
        Files.write(f, src.getBytes(GBK));
        System.out.println("written: " + f);
        System.out.println("DONE applied=" + applied + " skipped=" + skipped);
    }
}
