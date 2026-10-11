// patch_20261011_menucn_v13.java
// util_menucn.il v1.2 -> v1.3
//   实机异常修复：SKILL 哈希表缺键读取返回 'unbound 哨兵且为真值，
//   v1.0 的 and(... MAP[lab]) 守卫形同虚设，全部无映射项被改名为
//   "unbound"（含 ASTB 子菜单）。改 zh 变量承接 + neq 'unbound +
//   stringp 双重校验（沿用 menu.il v2.1 同款防御）。
// GBK 显式往返；锚点缺失即中止；幂等可重入。
// 运行：java -Dfile.encoding=UTF-8 _patches/patch_20261011_menucn_v13.java
import java.nio.charset.Charset;
import java.nio.file.*;

public class patch_20261011_menucn_v13 {
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

        src = rep(src, "; 版本      : 1.2\n", "; 版本      : 1.3\n", "version bump");

        src = rep(src,
            "; 修改记录  :\n" +
            ";   2026-10-11 v1.2 ASTB Team 实机异常修复：整棵跳过 ASTB 自身\n",
            "; 修改记录  :\n" +
            ";   2026-10-11 v1.3 ASTB Team 实机异常修复：SKILL 哈希缺键读得\n" +
            ";                'unbound 哨兵（真值），v1.0 守卫失效致全部无映射\n" +
            ";                项被改名 unbound；zh 承接 + neq/stringp 双重校验\n" +
            ";   2026-10-11 v1.2 ASTB Team 实机异常修复：整棵跳过 ASTB 自身\n",
            "revision record");

        src = rep(src,
            "    prog((tmp r port line ind body typ lab cmd frames frame pos parent\n" +
            "          pending q id r2 changed total)\n",
            "    prog((tmp r port line ind body typ lab cmd zh frames frame pos parent\n" +
            "          pending q id r2 changed total)\n",
            "prog vars");

        src = rep(src,
            "                    when( and( id neq(id 'dead) lab ASTB_MENUCN_MAP[lab] )\n" +
            "                        total = total + 1\n" +
            "                        r2 = errset(axlUIMenuChange(id 'display ASTB_MENUCN_MAP[lab]) t)\n",
            "                    zh = and( lab ASTB_MENUCN_MAP[lab] )\n" +
            "                    when( and( id neq(id 'dead) zh neq(zh 'unbound) stringp(zh) )\n" +
            "                        total = total + 1\n" +
            "                        r2 = errset(axlUIMenuChange(id 'display zh) t)\n",
            "popup guard");

        src = rep(src,
            "                    when( and( lab cmd ASTB_MENUCN_MAP[lab]\n" +
            "                               neq(_MCN_Prefix(cmd 5) \"ASTB_\") )\n" +
            "                        total = total + 1\n" +
            "                        q = errset(axlUIMenuFind(nil cmd) t)\n" +
            "                        id = and(q car(q))\n" +
            "                        when( id\n" +
            "                            r2 = errset(axlUIMenuChange(id 'display ASTB_MENUCN_MAP[lab]) t)\n",
            "                    zh = and( lab cmd ASTB_MENUCN_MAP[lab] )\n" +
            "                    when( and( zh neq(zh 'unbound) stringp(zh)\n" +
            "                               neq(_MCN_Prefix(cmd 5) \"ASTB_\") )\n" +
            "                        total = total + 1\n" +
            "                        q = errset(axlUIMenuFind(nil cmd) t)\n" +
            "                        id = and(q car(q))\n" +
            "                        when( id\n" +
            "                            r2 = errset(axlUIMenuChange(id 'display zh) t)\n",
            "item guard");

        src = rep(src,
            "printf(\"[ASTB] util_menucn.il v1.2 loaded\\n\")\n",
            "printf(\"[ASTB] util_menucn.il v1.3 loaded\\n\")\n",
            "printf bump");

        checkParens(src, f);
        Files.write(f, src.getBytes(GBK));
        System.out.println("written: " + f);
        System.out.println("DONE applied=" + applied + " skipped=" + skipped);
    }
}
