// patch_20261011_menucn_v17.java
// util_menucn.il v1.6 -> v1.7
//   根因修复（menu.il v2.1 同款）：16.6 哈希表缺键读取返回"未绑定标记"
//   且经赋值传染（接收变量随之未绑定，再读即 eval: unbound variable——
//   zh/mcnZh/v 三连报错同因），_MCN_MapZh 改 boundp+stringp 双重防御。
//   本补丁起执行新规矩：缺锚跳过（[MISS] 记名），其余继续，结尾汇总。
// GBK 显式往返；幂等可重入。
// 运行：java -Dfile.encoding=UTF-8 _patches/patch_20261011_menucn_v17.java
import java.nio.charset.Charset;
import java.nio.file.*;

public class patch_20261011_menucn_v17 {
    static final Charset GBK = Charset.forName("GBK");
    static int applied = 0, skipped = 0, missed = 0;

    static String rep(String src, String oldS, String newS, String tag) {
        int idx = src.indexOf(oldS);
        if (idx < 0) {
            if (src.contains(newS.length() > 60 ? newS.substring(0, 60) : newS)) {
                System.out.println("[skip] " + tag + " (already applied)");
                skipped++;
                return src;
            }
            System.out.println("[MISS] " + tag + " (anchor not found, skipped)");
            missed++;
            return src;
        }
        if (src.indexOf(oldS, idx + oldS.length()) >= 0) {
            System.out.println("[MISS] " + tag + " (anchor not unique, skipped)");
            missed++;
            return src;
        }
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

        src = rep(src, "; 版本      : 1.6\n", "; 版本      : 1.7\n", "version bump");

        src = rep(src,
            "; 修改记录  :\n" +
            ";   2026-10-11 v1.6 ASTB Team 回归 v1.2 结构：删 mcnZh 承接变量\n",
            "; 修改记录  :\n" +
            ";   2026-10-11 v1.7 ASTB Team 根因修复：16.6 哈希缺键读返回未绑定\n" +
            ";                标记且经赋值传染（zh/mcnZh/v 三连报错同因，\n" +
            ";                menu.il v2.1 早有同款记录），_MCN_MapZh 改\n" +
            ";                boundp+stringp 双重防御\n" +
            ";   2026-10-11 v1.6 ASTB Team 回归 v1.2 结构：删 mcnZh 承接变量\n",
            "revision record");

        src = rep(src,
            "; 备注    : v1.3 的 zh 承接变量在 16.6 触发 unbound variable 报错\n" +
            ";           （v1.2 无此变量可跑），改 helper 内部单变量 v 隔离\n",
            "; 备注    : 16.6 缺键读返回未绑定标记且经赋值传染（v1.3~v1.6\n" +
            ";           连环报错根因），先 boundp 再读值，双重防御\n",
            "helper comment");

        src = rep(src,
            "procedure( _MCN_MapZh(lab)\n" +
            "    prog((v)\n" +
            "        v = and( lab ASTB_MENUCN_MAP[lab] )\n" +
            "        if( and( v neq(v 'unbound) stringp(v) ) then\n" +
            "            return( v )\n" +
            "        else\n" +
            "            return( nil )\n" +
            "        )\n" +
            "    )\n" +
            ")\n",
            "procedure( _MCN_MapZh(lab)\n" +
            "    prog((v)\n" +
            "        ;; 16.6 缺键读返回未绑定标记且经赋值传染，先 boundp 再读值\n" +
            "        v = and( lab ASTB_MENUCN_MAP[lab] )\n" +
            "        if( and( boundp('v) stringp(v) ) then\n" +
            "            return( v )\n" +
            "        else\n" +
            "            return( nil )\n" +
            "        )\n" +
            "    )\n" +
            ")\n",
            "mapzh boundp");

        src = rep(src,
            "printf(\"[ASTB] util_menucn.il v1.6 loaded\\n\")\n",
            "printf(\"[ASTB] util_menucn.il v1.7 loaded\\n\")\n",
            "printf bump");

        checkParens(src, f);
        Files.write(f, src.getBytes(GBK));
        System.out.println("written: " + f);
        System.out.println("DONE applied=" + applied + " skipped=" + skipped + " missed=" + missed);
    }
}
