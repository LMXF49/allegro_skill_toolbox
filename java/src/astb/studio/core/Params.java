// ============================================================================
// File        : Params.java
// Description : Param specs for parameterized command runs, byte-compatible
//               with the Python studio: %USERPROFILE%\.astb_studio\params.json
//               {command: {"template": "...", "fields": [{"key","label",
//               "default"}]}}. Port of features.py load/save/render.
// ============================================================================
package astb.studio.core;

import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

public final class Params {
    private Params() {}

    public static Path storePath() { return Util.join(Util.appDir(), "params.json"); }

    public static Map<String, Object> load() {
        return loadFrom(storePath());
    }

    public static Map<String, Object> loadFrom(Path path) {
        return MiniJson.loadObj(path, Util.UTF8);
    }

    public static boolean save(Map<String, Object> obj) { return saveTo(storePath(), obj); }

    public static boolean saveTo(Path path, Map<String, Object> obj) {
        return MiniJson.saveAtomic(path, obj, Util.UTF8);
    }

    // ---- spec accessors -------------------------------------------------------------
    public static List<Object> fieldsOf(Map<String, Object> spec) {
        return spec == null ? null : MiniJson.arr(spec.get("fields"));
    }

    /** spec fields as [key, label] pairs; empty when no spec. */
    public static List<String[]> fieldLabels(Map<String, Object> spec) {
        List<String[]> out = new ArrayList<>();
        List<Object> fs = fieldsOf(spec);
        if (fs == null) return out;
        for (Object o : fs) {
            Map<String, Object> f = MiniJson.obj(o);
            if (f == null) continue;
            String key = MiniJson.getStr(f, "key", "");
            String label = MiniJson.getStr(f, "label", "");
            out.add(new String[] { key, label.isEmpty() ? key : label });
        }
        return out;
    }

    public static String fieldDefault(Map<String, Object> spec, String key) {
        List<Object> fs = fieldsOf(spec);
        if (fs == null) return "";
        for (Object o : fs) {
            Map<String, Object> f = MiniJson.obj(o);
            if (f != null && key.equals(MiniJson.getStr(f, "key", "")))
                return MiniJson.getStr(f, "default", "");
        }
        return "";
    }

    /** Build one command's spec from dialog fields (Python _save_spec: label=key,
     *  default=current text; template kept or default). */
    public static Map<String, Object> buildSpec(List<String[]> fieldsWithValues,
                                                String existingTemplate) {
        Map<String, Object> spec = MiniJson.newObj();
        List<Object> fs = MiniJson.newArr();
        for (String[] kv : fieldsWithValues) {
            Map<String, Object> f = MiniJson.newObj();
            f.put("key", kv[0]);
            f.put("label", kv[0]);
            f.put("default", kv[1]);
            fs.add(f);
        }
        spec.put("fields", fs);
        spec.put("template",
                 existingTemplate == null || existingTemplate.isEmpty() ? "{cmd} {args}"
                                                                        : existingTemplate);
        return spec;
    }

    /** features.render_param_command port. values = [key, value] pairs. */
    public static String render(String cmd, Map<String, Object> spec,
                                List<String[]> values) {
        String tpl = "{cmd} {args}";
        if (spec != null) {
            String t = MiniJson.getStr(spec, "template", "");
            if (!t.isEmpty()) tpl = t;
        }
        List<Object> fs = fieldsOf(spec);
        StringBuilder args = new StringBuilder();
        if (fs != null) {
            for (Object o : fs) {
                Map<String, Object> f = MiniJson.obj(o);
                if (f == null) continue;
                String v = valueOf(values, MiniJson.getStr(f, "key", ""));
                if (args.length() > 0) args.append(' ');
                args.append(v);
            }
        }
        String line = tpl.replace("{cmd}", cmd)
                         .replace("{args}", Util.trim(args.toString()));
        if (fs != null)
            for (Object o : fs) {
                Map<String, Object> f = MiniJson.obj(o);
                if (f == null) continue;
                String key = MiniJson.getStr(f, "key", "");
                line = line.replace("{" + key + "}", valueOf(values, key));
            }
        // " ".join(line.split()) 等价：折叠空白
        StringBuilder out = new StringBuilder();
        boolean sp = false;
        for (char c : Util.trim(line).toCharArray()) {
            if (c == ' ' || c == '\t') {
                if (!sp) out.append(' ');
                sp = true;
            } else {
                out.append(c);
                sp = false;
            }
        }
        return out.toString();
    }

    private static String valueOf(List<String[]> values, String key) {
        for (String[] kv : values)
            if (kv[0].equals(key)) return kv[1];
        return "";
    }
}
