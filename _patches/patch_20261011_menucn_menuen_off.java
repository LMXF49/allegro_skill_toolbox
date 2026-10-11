// patch_20261011_menucn_menuen_off.java
// menu.il v4.6 -> v4.7：System 菜单删除 "Menu EN/恢复英文菜单" 项（用户决策）；
// help_map.dat 删除 ASTB_MenuEN 条目。ASTB_MenuEN 函数保留在 util_menucn.il，
// 命令行仍可调用。
// GBK 显式往返；锚点缺失即中止；幂等可重入。
// 运行：java -Dfile.encoding=UTF-8 _patches/patch_20261011_menucn_menuen_off.java
import java.nio.charset.Charset;
import java.nio.file.*;

public class patch_20261011_menucn_menuen_off {
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
        Path root = Paths.get("G:\\ASTB\\skill_src");

        Path f = root.resolve("core\\menu.il");
        String src = new String(Files.readAllBytes(f), GBK);
        src = rep(src, "; 版本      : 4.6\n", "; 版本      : 4.7\n", "version bump");
        src = rep(src,
            ";   2026-10-11 v4.6 ASTB Team System 新增 Menu CN/Menu EN（配套\n",
            ";   2026-10-11 v4.7 ASTB Team System 删除 Menu EN 项（用户决策：\n" +
            ";                     恢复英文重启即可；ASTB_MenuEN 函数保留，\n" +
            ";                     命令行可调用）\n" +
            ";   2026-10-11 v4.6 ASTB Team System 新增 Menu CN/Menu EN（配套\n",
            "revision record");
        src = rep(src,
            "    list(\"&Menu CN\" \"菜单汉化(&M)\"  \"ASTB_MenuCN\")\n" +
            "    list(\"Menu E&N\" \"恢复英文菜单(&N)\"  \"ASTB_MenuEN\")\n",
            "    list(\"&Menu CN\" \"菜单汉化(&M)\"  \"ASTB_MenuCN\")\n",
            "remove Menu EN item");
        checkParens(src, f);
        Files.write(f, src.getBytes(GBK));
        System.out.println("written: " + f);

        Path h = root.resolve("core\\help_map.dat");
        String hs = new String(Files.readAllBytes(h), GBK);
        String enEntry = null;
        for (String line : hs.split("\n")) {
            if (line.startsWith("ASTB_MenuEN|")) { enEntry = line; break; }
        }
        if (enEntry == null) {
            System.out.println("[skip] help entry (absent)");
            skipped++;
        } else {
            hs = rep(hs, enEntry + "\n", "", "help entry removal");
        }
        Files.write(h, hs.getBytes(GBK));
        System.out.println("written: " + h);

        System.out.println("DONE applied=" + applied + " skipped=" + skipped);
    }
}
