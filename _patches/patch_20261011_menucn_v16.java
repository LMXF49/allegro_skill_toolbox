// patch_20261011_menucn_v16.java
// util_menucn.il v1.5 -> v1.6
//   回归 v1.2 已验证结构：删除 apply 内的 mcnZh 承接变量（prog 变量
//   降回 19 个），哨兵防御收进单变量 helper _MCN_MapZh（命中返回
//   中文，缺键/'unbound/非字符串返回 nil）。
// GBK 显式往返；锚点缺失即中止；幂等可重入。
// 运行：java -Dfile.encoding=UTF-8 _patches/patch_20261011_menucn_v16.java
import java.nio.charset.Charset;
import java.nio.file.*;

public class patch_20261011_menucn_v16 {
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

        src = rep(src, "; 版本      : 1.5\n", "; 版本      : 1.6\n", "version bump");

        src = rep(src,
            "; 修改记录  :\n" +
            ";   2026-10-11 v1.5 ASTB Team 判别实验：模块内 zh 全改名 mcnZh，\n",
            "; 修改记录  :\n" +
            ";   2026-10-11 v1.6 ASTB Team 回归 v1.2 结构：删 mcnZh 承接变量\n" +
            ";                （v1.5 报错跟名走，实锤承接写法问题），哨兵防御\n" +
            ";                收进单变量 helper _MCN_MapZh，prog 变量降回 19 个\n" +
            ";   2026-10-11 v1.5 ASTB Team 判别实验：模块内 zh 全改名 mcnZh，\n",
            "revision record");

        // _MCN_MapZh helper：插在 ASTB_MenuCNApply 注释块之前
        src = rep(src,
            ";------------------------------------------------------------------------\n" +
            "; 函数名  : ASTB_MenuCNApply\n",
            ";------------------------------------------------------------------------\n" +
            "; 函数名  : _MCN_MapZh\n" +
            "; 功能    : 查映射：命中返回中文标签；缺键/'unbound/非字符串返回 nil\n" +
            "; 备注    : v1.3 的 zh 承接变量在 16.6 触发 unbound variable 报错\n" +
            ";           （v1.2 无此变量可跑），改 helper 内部单变量 v 隔离\n" +
            ";------------------------------------------------------------------------\n" +
            "procedure( _MCN_MapZh(lab)\n" +
            "    prog((v)\n" +
            "        v = and( lab ASTB_MENUCN_MAP[lab] )\n" +
            "        if( and( v neq(v 'unbound) stringp(v) ) then\n" +
            "            return( v )\n" +
            "        else\n" +
            "            return( nil )\n" +
            "        )\n" +
            "    )\n" +
            ")\n" +
            "\n" +
            ";------------------------------------------------------------------------\n" +
            "; 函数名  : ASTB_MenuCNApply\n",
            "mapzh helper");

        // prog 变量降回 19 个（去 mcnZh）
        src = rep(src,
            "    prog((tmp r port line ind body typ lab cmd mcnZh frames frame pos parent\n" +
            "          pending q id r2 changed total)\n",
            "    prog((tmp r port line ind body typ lab cmd frames frame pos parent\n" +
            "          pending q id r2 changed total)\n",
            "prog vars");

        // 循环重置去掉 mcnZh = nil
        src = rep(src,
            "            typ = nil\n" +
            "            lab = nil\n" +
            "            cmd = nil\n" +
            "            mcnZh = nil\n",
            "            typ = nil\n" +
            "            lab = nil\n" +
            "            cmd = nil\n",
            "loop reset");

        // popup 分支
        src = rep(src,
            "                    mcnZh = and( lab ASTB_MENUCN_MAP[lab] )\n" +
            "                    when( and( id neq(id 'dead) mcnZh neq(mcnZh 'unbound) stringp(mcnZh) )\n" +
            "                        total = total + 1\n" +
            "                        r2 = errset(axlUIMenuChange(id 'display mcnZh) t)\n",
            "                    when( and( id neq(id 'dead) _MCN_MapZh(lab) )\n" +
            "                        total = total + 1\n" +
            "                        r2 = errset(axlUIMenuChange(id 'display _MCN_MapZh(lab)) t)\n",
            "popup guard");

        // item 分支
        src = rep(src,
            "                    mcnZh = and( lab cmd ASTB_MENUCN_MAP[lab] )\n" +
            "                    when( and( mcnZh neq(mcnZh 'unbound) stringp(mcnZh)\n" +
            "                               neq(_MCN_Prefix(cmd 5) \"ASTB_\") )\n" +
            "                        total = total + 1\n" +
            "                        q = errset(axlUIMenuFind(nil cmd) t)\n" +
            "                        id = and(q car(q))\n" +
            "                        when( id\n" +
            "                            r2 = errset(axlUIMenuChange(id 'display mcnZh) t)\n",
            "                    when( and( _MCN_MapZh(lab)\n" +
            "                               neq(_MCN_Prefix(cmd 5) \"ASTB_\") )\n" +
            "                        total = total + 1\n" +
            "                        q = errset(axlUIMenuFind(nil cmd) t)\n" +
            "                        id = and(q car(q))\n" +
            "                        when( id\n" +
            "                            r2 = errset(axlUIMenuChange(id 'display _MCN_MapZh(lab)) t)\n",
            "item guard");

        src = rep(src,
            "printf(\"[ASTB] util_menucn.il v1.5 loaded\\n\")\n",
            "printf(\"[ASTB] util_menucn.il v1.6 loaded\\n\")\n",
            "printf bump");

        checkParens(src, f);
        Files.write(f, src.getBytes(GBK));
        System.out.println("written: " + f);
        System.out.println("DONE applied=" + applied + " skipped=" + skipped);
    }
}
