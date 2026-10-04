// ============================================================================
// File        : AppConfig.java
// Description : %USERPROFILE%\.astb_studio\config.json (UTF-8 JSON).
//               Missing keys fall back to defaults; saving preserves unknown
//               keys (parse -> edit -> serialize on a LinkedHashMap).
// ============================================================================
package astb.studio.core;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

public final class AppConfig {
    private AppConfig() {}

    /** Defaults mirror python/studio/backend.py load_config (setdefault). */
    public static Map<String, Object> load() {
        Map<String, Object> cfg = MiniJson.loadObj(Util.configPath(), Util.UTF8);
        cfg.putIfAbsent("versions", MiniJson.newObj());
        cfg.putIfAbsent("default_version", "17.4");
        cfg.putIfAbsent("toolbox_root", "D:/Cadence/allegro_skill");
        cfg.putIfAbsent("mru", MiniJson.newArr());
        cfg.putIfAbsent("scan_dirs", MiniJson.newArr());
        cfg.putIfAbsent("health_auto", Boolean.TRUE);
        return cfg;
    }

    public static boolean save(Map<String, Object> cfg) {
        return MiniJson.saveAtomic(Util.configPath(), cfg, Util.UTF8);
    }

    public static String toolboxRoot(Map<String, Object> cfg) {
        return MiniJson.getStr(cfg, "toolbox_root", "D:/Cadence/allegro_skill");
    }

    // ---- mru (config["mru"], cap 8) ---------------------------------------------
    public static List<String> getMru(Map<String, Object> cfg, int cap) {
        List<String> out = new ArrayList<>();
        List<Object> a = MiniJson.arr(cfg.get("mru"));
        if (a != null) {
            for (Object v : a) {
                String s = MiniJson.str(v);
                if (s != null && !s.isEmpty()) out.add(s);
                if (out.size() >= cap) break;
            }
        }
        return out;
    }

    public static void setMru(Map<String, Object> cfg, List<String> items) {
        List<Object> a = MiniJson.newArr();
        for (String s : items) a.add(s);
        cfg.put("mru", a);
    }

    public static void pushMru(Map<String, Object> cfg, String item) {
        if (item == null || item.isEmpty()) return;
        List<String> items = new ArrayList<>();
        for (String s : getMru(cfg, Integer.MAX_VALUE))
            if (!s.equals(item)) items.add(s);
        items.add(0, item);
        if (items.size() > 8) items = items.subList(0, 8);
        setMru(cfg, new ArrayList<>(items));
    }
}
