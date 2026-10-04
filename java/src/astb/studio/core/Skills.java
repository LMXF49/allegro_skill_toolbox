// ============================================================================
// File        : Skills.java
// Description : Custom skill store, byte-compatible with the Python studio:
//               %USERPROFILE%\.astb_studio\custom_skills.json (UTF-8 array of
//               {id, name, path, cmd, added}).
// ============================================================================
package astb.studio.core;

import java.nio.file.Path;
import java.util.List;
import java.util.Map;

public final class Skills {
    private Skills() {}

    public static Path storePath() { return Util.join(Util.appDir(), "custom_skills.json"); }

    public static List<Object> load() {
        return MiniJson.loadArr(storePath(), Util.UTF8);
    }

    public static boolean save(List<Object> arr) {
        return MiniJson.saveAtomic(storePath(), arr, Util.UTF8);
    }

    /** Register a local .il for the custom panel (dedupes by path). */
    public static Map<String, Object> add(List<Object> arr, String pathRaw, String name,
                                          String cmd) {
        String path = Util.slashes(pathRaw);
        for (Object o : arr) {
            Map<String, Object> s = MiniJson.obj(o);
            if (s != null && path.equals(MiniJson.getStr(s, "path", ""))) return s;
        }
        Map<String, Object> s = MiniJson.newObj();
        s.put("id", "s" + Util.nowId() + String.format("%03d", arr.size() % 1000));
        s.put("name", name == null || name.isEmpty() ? Util.stem(path) : name);
        s.put("path", path);
        s.put("cmd", cmd == null ? "" : Util.trim(cmd));
        s.put("added", Util.nowStamp());
        arr.add(s);
        return s;
    }
}
