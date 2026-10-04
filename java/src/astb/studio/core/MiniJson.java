// ============================================================================
// File        : MiniJson.java
// Description : Minimal JSON: tolerant recursive-descent parser + serializer.
//               Objects are LinkedHashMap (insertion order kept) and numbers
//               keep their raw token text, so a parse->edit->save round trip
//               preserves unknown keys and number formatting (config.json
//               contract). Pretty serializer uses 2-space indent like Python.
// ============================================================================
package astb.studio.core;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public final class MiniJson {

    /** Number value: raw token preserved for byte-fidelity. */
    public static final class Num {
        public final String raw;
        public Num(String raw) { this.raw = raw; }
        public double asDouble(double def) {
            try { return Double.parseDouble(raw); } catch (NumberFormatException e) { return def; }
        }
        @Override public String toString() { return raw; }
    }

    public static final Object NULL = new Object() {
        @Override public String toString() { return "null"; }
    };

    private MiniJson() {}

    // ---- type helpers ---------------------------------------------------------
    @SuppressWarnings("unchecked")
    public static Map<String, Object> obj(Object v) {
        return v instanceof Map ? (Map<String, Object>) v : null;
    }
    @SuppressWarnings("unchecked")
    public static List<Object> arr(Object v) {
        return v instanceof List ? (List<Object>) v : null;
    }
    public static String str(Object v) { return v instanceof String ? (String) v : null; }
    public static String str(Object v, String def) { String s = str(v); return s == null ? def : s; }
    public static boolean bool(Object v, boolean def) {
        return v instanceof Boolean ? (Boolean) v : def;
    }
    public static Map<String, Object> newObj() { return new LinkedHashMap<>(); }
    public static List<Object> newArr() { return new ArrayList<>(); }
    public static String getStr(Map<String, Object> o, String key, String def) {
        if (o == null) return def;
        return str(o.get(key), def);
    }

    // ---- parser ---------------------------------------------------------------
    private static final class P {
        static final int MAX_DEPTH = 200;   // 递归解析深度上限（超限解析失败返回 null）
        final String s;
        final int n;
        int i;
        int depth;

        P(String s) { this.s = s; this.n = s.length(); }

        void ws() {
            while (i < n && (s.charAt(i) == ' ' || s.charAt(i) == '\t' ||
                             s.charAt(i) == '\n' || s.charAt(i) == '\r')) i++;
        }

        boolean match(String lit) {
            if (i + lit.length() > n || !s.startsWith(lit, i)) return false;
            i += lit.length();
            return true;
        }

        boolean hex4(StringBuilder out) {
            if (i + 4 > n) return false;
            int v = 0;
            for (int k = 0; k < 4; ++k) {
                char c = s.charAt(i + k);
                v <<= 4;
                if (c >= '0' && c <= '9') v |= c - '0';
                else if (c >= 'a' && c <= 'f') v |= c - 'a' + 10;
                else if (c >= 'A' && c <= 'F') v |= c - 'A' + 10;
                else return false;
            }
            i += 4;
            out.append((char) v);
            return true;
        }

        boolean strLit(StringBuilder out) {
            // s[i] == '"'
            ++i;
            out.setLength(0);
            while (i < n) {
                char c = s.charAt(i++);
                if (c == '"') return true;
                if (c != '\\') { out.append(c); continue; }
                if (i >= n) return false;
                char e = s.charAt(i++);
                switch (e) {
                    case '"': out.append('"'); break;
                    case '\\': out.append('\\'); break;
                    case '/': out.append('/'); break;
                    case 'b': out.append('\b'); break;
                    case 'f': out.append('\f'); break;
                    case 'n': out.append('\n'); break;
                    case 'r': out.append('\r'); break;
                    case 't': out.append('\t'); break;
                    case 'u': if (!hex4(out)) return false; break;
                    default: return false;
                }
            }
            return false;
        }

        boolean number(StringBuilder out) {
            int st = i;
            if (i < n && s.charAt(i) == '-') ++i;
            int d0 = i;
            while (i < n && Character.isDigit(s.charAt(i))) ++i;
            if (i == d0) return false;                 // '-' 后必须至少一位数字（挡裸 '-'）
            if (i < n && s.charAt(i) == '.') {
                ++i;
                int d1 = i;
                while (i < n && Character.isDigit(s.charAt(i))) ++i;
                if (i == d1) return false;             // '.' 后必须至少一位数字（挡 '-.'）
            }
            if (i < n && (s.charAt(i) == 'e' || s.charAt(i) == 'E')) {
                ++i;
                if (i < n && (s.charAt(i) == '+' || s.charAt(i) == '-')) ++i;
                int d2 = i;
                while (i < n && Character.isDigit(s.charAt(i))) ++i;
                if (i == d2) return false;             // e/E 后必须至少一位数字（挡 '1e'）
            }
            out.append(s, st, i);
            return true;
        }

        Object value() {
            ws();
            if (i >= n) return null;
            char c = s.charAt(i);
            if (c == '{') {
                if (++depth > MAX_DEPTH) return null;   // 防畸形文件递归爆栈
                Map<String, Object> r = object();
                --depth;
                return r;
            }
            if (c == '[') {
                if (++depth > MAX_DEPTH) return null;
                List<Object> r = array();
                --depth;
                return r;
            }
            if (c == '"') {
                StringBuilder sb = new StringBuilder();
                return strLit(sb) ? sb.toString() : null;
            }
            if (c == 't') { if (!match("true")) return null; return Boolean.TRUE; }
            if (c == 'f') { if (!match("false")) return null; return Boolean.FALSE; }
            if (c == 'n') { if (!match("null")) return null; return NULL; }
            if (c == '-' || Character.isDigit(c)) {
                StringBuilder sb = new StringBuilder();
                return number(sb) ? new Num(sb.toString()) : null;
            }
            return null;
        }

        Map<String, Object> object() {
            ++i;   // '{'
            Map<String, Object> out = new LinkedHashMap<>();
            ws();
            if (i < n && s.charAt(i) == '}') { ++i; return out; }
            StringBuilder key = new StringBuilder();
            while (true) {
                ws();
                if (i >= n || s.charAt(i) != '"') return null;
                if (!strLit(key)) return null;
                ws();
                if (i >= n || s.charAt(i) != ':') return null;
                ++i;
                Object v = value();
                if (v == null) return null;
                out.put(key.toString(), v);
                ws();
                if (i < n && s.charAt(i) == ',') { ++i; continue; }
                if (i < n && s.charAt(i) == '}') { ++i; return out; }
                return null;
            }
        }

        List<Object> array() {
            ++i;   // '['
            List<Object> out = new ArrayList<>();
            ws();
            if (i < n && s.charAt(i) == ']') { ++i; return out; }
            while (true) {
                Object v = value();
                if (v == null) return null;
                out.add(v);
                ws();
                if (i < n && s.charAt(i) == ',') { ++i; continue; }
                if (i < n && s.charAt(i) == ']') { ++i; return out; }
                return null;
            }
        }
    }

    /** Tolerant parse: trailing garbage ignored (queue files are not atomic). */
    public static Object parse(String text) {
        if (text == null) return null;
        return new P(text).value();
    }

    // ---- 四个 store 的公共读写助手（兜底：解析失败给空容器；保存走原子写） -------------------

    public static Map<String, Object> loadObj(java.nio.file.Path path,
                                              java.nio.charset.Charset cs) {
        Map<String, Object> o = obj(parse(astb.studio.core.Util.readText(path, cs)));
        return o == null ? newObj() : o;
    }

    public static List<Object> loadArr(java.nio.file.Path path,
                                       java.nio.charset.Charset cs) {
        List<Object> a = arr(parse(astb.studio.core.Util.readText(path, cs)));
        return a == null ? newArr() : a;
    }

    public static boolean saveAtomic(java.nio.file.Path path, Object v,
                                     java.nio.charset.Charset cs) {
        return astb.studio.core.Util.writeTextAtomic(path, stringify(v, true) + "\n", cs);
    }

    // ---- serializer -------------------------------------------------------------
    private static void escStr(StringBuilder out, String s) {
        out.append('"');
        for (int k = 0; k < s.length(); ++k) {
            char c = s.charAt(k);
            switch (c) {
                case '"': out.append("\\\""); break;
                case '\\': out.append("\\\\"); break;
                case '\n': out.append("\\n"); break;
                case '\r': out.append("\\r"); break;
                case '\t': out.append("\\t"); break;
                default:
                    if (c < 0x20) out.append(String.format("\\u%04x", (int) c));
                    else out.append(c);   // ensure_ascii=false style
            }
        }
        out.append('"');
    }

    private static void write(StringBuilder out, Object v, boolean pretty, int ind) {
        if (v == null || v == NULL) { out.append("null"); return; }
        if (v instanceof Boolean) { out.append(v); return; }
        if (v instanceof Num) { out.append(((Num) v).raw); return; }
        if (v instanceof Number) { out.append(v); return; }
        if (v instanceof String) { escStr(out, (String) v); return; }
        List<Object> a = arr(v);
        if (a != null) {
            if (a.isEmpty()) { out.append("[]"); return; }
            out.append('[');
            for (int k = 0; k < a.size(); ++k) {
                if (k > 0) out.append(',');
                if (pretty) { out.append('\n'); out.append("  ".repeat(ind + 1)); }
                write(out, a.get(k), pretty, ind + 1);
            }
            if (pretty) { out.append('\n'); out.append("  ".repeat(ind)); }
            out.append(']');
            return;
        }
        Map<String, Object> o = obj(v);
        if (o != null) {
            if (o.isEmpty()) { out.append("{}"); return; }
            out.append('{');
            boolean first = true;
            for (Map.Entry<String, Object> e : o.entrySet()) {
                if (!first) out.append(',');
                first = false;
                if (pretty) { out.append('\n'); out.append("  ".repeat(ind + 1)); }
                escStr(out, e.getKey());
                out.append(':');
                if (pretty) out.append(' ');
                write(out, e.getValue(), pretty, ind + 1);
            }
            if (pretty) { out.append('\n'); out.append("  ".repeat(ind)); }
            out.append('}');
            return;
        }
        out.append("null");
    }

    public static String stringify(Object v, boolean pretty) {
        StringBuilder sb = new StringBuilder();
        write(sb, v, pretty, 0);
        return sb.toString();
    }
}
