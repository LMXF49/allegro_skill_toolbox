// ============================================================================
// File        : Health.java
// Description : Board health probes (port of features.py board_health):
//               one bridge command returning "key=value;..." which is parsed
//               and rendered as a report card. Probes verbatim from
//               features._HEALTH_PAIRS / _build_health_cmd.
// ============================================================================
package astb.studio.core;

import java.util.ArrayList;
import java.util.List;

public final class Health {
    private Health() {}

    // _sel_count(flt): count database objects by select-all under a find filter.
    private static String selCount(String flt) {
        return "progn(axlClearSelSet() axlSetFindFilter(?enabled '(\"NOALL\" \"" + flt +
               "\") ?onButtons '(\"" + flt +
               "\")) n = length(axlGetSelSet(axlAddSelectAll())) axlClearSelSet() n)";
    }

    public static String buildCmd() {
        String[][] pairs = {
            { "version", "sprintf(nil \"%L\" axlVersion('version))" },
            { "design", "axlCurrentDesign()" },
            { "units", "car(errset(sprintf(nil \"%L\" car(axlDBGetDesignUnits())) 'e))" },
            { "nets", "car(errset(sprintf(nil \"%d\" length(axlDBGetDesign()->nets)) 'e))" },
            { "symbols", "car(errset(sprintf(nil \"%d\" length(axlDBGetDesign()->symbols)) 'e))" },
            { "pins", "sprintf(nil \"%d\" " + selCount("PINS") + ")" },
            { "vias", "sprintf(nil \"%d\" " + selCount("VIAS") + ")" },
            { "clines", "sprintf(nil \"%d\" " + selCount("CLINES") + ")" },
            { "shapes", "sprintf(nil \"%d\" " + selCount("SHAPES") + ")" },
            { "drcs",
              "sprintf(nil \"%d\" progn(axlClearSelSet() " +
              "errset(axlSelectByProperty(\"DRC\" \"EXTERNAL_VIOLATION_DESCRIPTION\") nil) " +
              "n = length(axlGetSelSet()) axlClearSelSet() n))" },
            { "via_hist",
              "progn(axlClearSelSet() " +
              "axlSetFindFilter(?enabled '(\"NOALL\" \"VIAS\") ?onButtons '(\"VIAS\")) " +
              "vs = axlGetSelSet(axlAddSelectAll()) n = length(vs) " +
              // inner accumulator must be hs (not s) -- s would clobber
              // the outer key=value accumulator (live-proven 2026-09-30)
              "hs = \"skip(>30000 or none)\" " +
              "when( and(n > 0 n <= 30000) " +
              "  tbl = makeTable('vh 0) " +
              "  foreach(v vs ps = car(errset(v->name nil)) " +
              "    unless(ps ps = car(errset(v->definition->name nil))) " +
              "    when(ps tbl[ps] = tbl[ps] + 1)) " +
              "  ks = nil foreach(k tbl ks = cons(k ks)) " +
              "  ks = sort(ks 'alphalessp) " +
              "  hs = \"\" foreach(k ks hs = strcat(hs k \":\" " +
              "    sprintf(nil \"%d\" tbl[k]) \"  \"))) " +
              "axlClearSelSet() hs)" },
        };
        StringBuilder body = new StringBuilder();
        for (String[] kv : pairs) {
            body.append("r = errset(v = ").append(kv[1])
                .append(") when( and(r boundp('v) v) s = strcat(s \"")
                .append(kv[0]).append("=\" sprintf(nil \"%L\" v) \";\") ) ");
        }
        return "progn(s = \"\" " + body + "s)";
    }

    public static String unquote(String v) {
        String t = Util.trim(v);
        if (t.length() >= 2 && t.charAt(0) == '"' && t.charAt(t.length() - 1) == '"')
            return t.substring(1, t.length() - 1);
        return t;
    }

    /** SKILL 字符串反转义：反斜杠吃掉后跟的任意一个字符（\" -> "、\\ -> \、
     *  \x -> x）。桥侧 %L 打印会把内层引号转成 \"，JSON 转义后客户端收到的
     *  值里带反斜杠，需要逐字符扫描反转。 */
    public static String unescape(String s) {
        if (s == null) return "";
        StringBuilder out = new StringBuilder();
        int i = 0, n = s.length();
        while (i < n) {
            char c = s.charAt(i);
            if (c == '\\' && i + 1 < n) {
                out.append(s.charAt(i + 1));
                i += 2;
            } else {
                out.append(c);
                i += 1;
            }
        }
        return out.toString();
    }

    /** 值清洗：循环 unquote(unescape(trim(v))) 直到稳定（上限 5 次防死循环）。
     *  \"17.4\" -> 17.4；\"\\\"mils\\\"\" -> mils；普通值不变。 */
    public static String clean(String v) {
        String prev = v == null ? "" : v;
        for (int i = 0; i < 5; ++i) {
            String next = unquote(unescape(Util.trim(prev)));
            if (next.equals(prev)) return next;
            prev = next;
        }
        return prev;
    }

    /** "k1=v1;k2=v2;" -> [key, value] pairs; values cleaned of bridge %L escapes. */
    public static List<String[]> parse(String s) {
        List<String[]> out = new ArrayList<>();
        if (s == null) return out;
        for (String pair : s.split(";", -1)) {
            int eq = pair.indexOf('=');
            if (eq < 0) continue;
            out.add(new String[] { Util.trim(pair.substring(0, eq)),
                                   clean(pair.substring(eq + 1)) });
        }
        return out;
    }

    private static String valOf(List<String[]> vals, String key) {
        for (String[] kv : vals)
            if (kv[0].equals(key)) return kv[1];
        return "";
    }

    private static String dash(String v) { return v == null || v.isEmpty() ? "-" : v; }

    public static String format(List<String[]> vals) {
        String units = valOf(vals, "units");
        int sp = units.indexOf(' ');
        if (sp >= 0) units = units.substring(0, sp);
        String version = dash(valOf(vals, "version"));
        if ("-".equals(version)) version = "?";
        String design = dash(valOf(vals, "design"));
        if ("-".equals(design)) design = "?";
        if (units.isEmpty()) units = "?";
        StringBuilder t = new StringBuilder();
        t.append("版本    : ").append(version).append("\n");
        t.append("设计    : ").append(design).append("\n");
        t.append("单位    : ").append(units).append("\n");
        t.append("网络    : ").append(dash(valOf(vals, "nets"))).append("\n");
        t.append("过孔    : ").append(dash(valOf(vals, "vias"))).append("\n");
        t.append("元件    : ").append(dash(valOf(vals, "symbols"))).append("\n");
        t.append("引脚    : ").append(dash(valOf(vals, "pins"))).append("\n");
        t.append("走线    : ").append(dash(valOf(vals, "clines"))).append("\n");
        t.append("铜皮    : ").append(dash(valOf(vals, "shapes"))).append("\n");
        t.append("DRC     : ").append(dash(valOf(vals, "drcs"))).append("\n");
        t.append("过孔分布: ").append(dash(valOf(vals, "via_hist")));
        return t.toString();
    }

    public static String formatError(String err) { return "体检失败: " + err; }
}
