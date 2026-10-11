// patch_20261011_menucn_v12.java
// util_menucn.il v1.1 -> v1.2
//   实机异常修复：汉化波及 ASTB 自身菜单（&Help 撞名被改 + 位置定位
//   可能踩进工具箱子树）。v1.2 整棵跳过 ASTB 顶层 popup 子树，
//   并跳过全部 ASTB_ 前缀命令项。
// GBK 显式往返；锚点缺失即中止；幂等可重入。
// 运行：java -Dfile.encoding=UTF-8 _patches/patch_20261011_menucn_v12.java
import java.nio.charset.Charset;
import java.nio.file.*;

public class patch_20261011_menucn_v12 {
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

        src = rep(src, "; 版本      : 1.1\n", "; 版本      : 1.2\n", "version bump");

        src = rep(src,
            "; 修改记录  :\n" +
            ";   2026-10-11 v1.1 ASTB Team 实机报错修复：SKILL cons 第二参数\n",
            "; 修改记录  :\n" +
            ";   2026-10-11 v1.2 ASTB Team 实机异常修复：整棵跳过 ASTB 自身\n" +
            ";                菜单子树（顶层 popup 标签匹配即 'dead），并跳过\n" +
            ";                ASTB_ 前缀命令项（&Help 与 Cadence 撞名被误改）\n" +
            ";   2026-10-11 v1.1 ASTB Team 实机报错修复：SKILL cons 第二参数\n",
            "revision record");

        src = rep(src,
            "                    ;; popup 按位置定位（父帧为 'dead 则继承，不查不改）\n" +
            "                    if( equal(parent 'dead) then\n" +
            "                        id = 'dead\n" +
            "                    else\n",
            "                    ;; popup 按位置定位（父帧为 'dead 则继承，不查不改；\n" +
            "                    ;; ASTB 自身顶层 popup 整棵跳过）\n" +
            "                    if( or( equal(parent 'dead)\n" +
            "                            equal(lab \"allegro_s&kill_toolbox\")\n" +
            "                            equal(lab \"Allegro Skill工具箱(&K)\") ) then\n" +
            "                        id = 'dead\n" +
            "                    else\n",
            "skip astb subtree");

        src = rep(src,
            "                    when( and( lab cmd ASTB_MENUCN_MAP[lab] )\n",
            "                    when( and( lab cmd ASTB_MENUCN_MAP[lab]\n" +
            "                               neq(_MCN_Prefix(cmd 5) \"ASTB_\") )\n",
            "skip astb commands");

        src = rep(src,
            "printf(\"[ASTB] util_menucn.il v1.1 loaded\\n\")\n",
            "printf(\"[ASTB] util_menucn.il v1.2 loaded\\n\")\n",
            "printf bump");

        checkParens(src, f);
        Files.write(f, src.getBytes(GBK));
        System.out.println("written: " + f);
        System.out.println("DONE applied=" + applied + " skipped=" + skipped);
    }
}
