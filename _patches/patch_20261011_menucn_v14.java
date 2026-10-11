// patch_20261011_menucn_v14.java
// util_menucn.il v1.3 -> v1.4
//   实机报错修复：*Error* eval: unbound variable - zh（prog 变量初始
//   未绑定）。每轮循环显式 zh=nil 重置，LoadMap 进循环前同样初始化，
//   杜绝一切未绑定读取路径。
// GBK 显式往返；锚点缺失即中止；幂等可重入。
// 运行：java -Dfile.encoding=UTF-8 _patches/patch_20261011_menucn_v14.java
import java.nio.charset.Charset;
import java.nio.file.*;

public class patch_20261011_menucn_v14 {
    static final Charset GBK = Charset.forName("GBK");
    static int applied = 0, skipped = 0;

    static String rep(String src, String oldS, String newS, String tag) {
        int idx = src.indexOf(oldS);
        if (idx < 0) {
            if (src.contains(newS.length() > 60 ? newS.substring(0, 60) : newS)) {
                System.out.println("[skip] " + tag + " (already applied)");
                skipped++;
                return src;
            }
            throw new RuntimeException("ANCHOR MISSING: " + tag);
        }
        if (src.indexOf(oldS, idx + oldS.length()) >= 0)
            throw new RuntimeException("ANCHOR NOT UNIQUE: " + tag);
        applied++;
        System.out.println("[ ok ] " + tag);
        return src.substring(0, idx) + newS + src.substring(idx + oldS.length());
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

        src = rep(src, "; 版本      : 1.3\n", "; 版本      : 1.4\n", "version bump");

        src = rep(src,
            "; 修改记录  :\n" +
            ";   2026-10-11 v1.3 ASTB Team 实机异常修复：SKILL 哈希缺键读得\n",
            "; 修改记录  :\n" +
            ";   2026-10-11 v1.4 ASTB Team 实机报错修复：prog 变量初始未绑定，\n" +
            ";                循环每轮显式 zh=nil 重置（unbound variable - zh）\n" +
            ";   2026-10-11 v1.3 ASTB Team 实机异常修复：SKILL 哈希缺键读得\n",
            "revision record");

        // LoadMap：进 while 前初始化 eng/zh
        src = rep(src,
            "        ASTB_MENUCN_MAP = makeTable('ASTB_MENUCN_MAP)\n" +
            "        while( gets(line port)\n" +
            "            unless( or(equal(line \"\") equal(_MCN_Prefix(line 1) \"#\"))\n" +
            "                p = 1\n" +
            "                eng = nil\n",
            "        ASTB_MENUCN_MAP = makeTable('ASTB_MENUCN_MAP)\n" +
            "        while( gets(line port)\n" +
            "            unless( or(equal(line \"\") equal(_MCN_Prefix(line 1) \"#\"))\n" +
            "                p = 1\n" +
            "                eng = nil\n" +
            "                zh = nil\n",
            "loadmap init");

        // Apply：每轮 typ/lab/cmd 重置处补 zh = nil
        src = rep(src,
            "            typ = nil\n" +
            "            lab = nil\n" +
            "            cmd = nil\n",
            "            typ = nil\n" +
            "            lab = nil\n" +
            "            cmd = nil\n" +
            "            zh = nil\n",
            "apply reset");

        src = rep(src,
            "printf(\"[ASTB] util_menucn.il v1.3 loaded\\n\")\n",
            "printf(\"[ASTB] util_menucn.il v1.4 loaded\\n\")\n",
            "printf bump");

        checkParens(src, f);
        Files.write(f, src.getBytes(GBK));
        System.out.println("written: " + f);
        System.out.println("DONE applied=" + applied + " skipped=" + skipped);
    }
}
