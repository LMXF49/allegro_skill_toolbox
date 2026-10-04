// ============================================================================
// File        : HelpMap.java
// Description : Offline help reader: <toolbox_root>\core\help_map.dat
//               (GBK, pipe-separated 命令|功能|步骤|实现).
// ============================================================================
package astb.studio.core;

import java.util.ArrayList;
import java.util.List;

public final class HelpMap {

    public static final class Item {
        public String command;
        public String function;
        public String steps;
        public String impl;
    }

    private HelpMap() {}

    /** Skip blank lines and ';' comments; need >= 4 fields; fields trimmed
     *  (matching python/studio/features.py load_help_map). */
    public static List<Item> load(String toolboxRoot) {
        List<Item> items = new ArrayList<>();
        String text = Util.readText(
                Util.join(Util.join(java.nio.file.Path.of(toolboxRoot), "core"),
                          "help_map.dat"), Util.GBK);
        if (text == null) return items;
        for (String line : text.split("\n", -1)) {
            line = Util.trim(line);
            if (line.isEmpty() || line.charAt(0) == ';') continue;
            String[] parts = Util.split(line, '|');
            if (parts.length < 4) continue;
            Item it = new Item();
            it.command = Util.trim(parts[0]);
            it.function = Util.trim(parts[1]);
            it.steps = Util.trim(parts[2]);
            it.impl = Util.trim(parts[3]);
            items.add(it);
        }
        return items;
    }

    public static Item find(List<Item> items, String command) {
        for (Item it : items)
            if (it.command.equals(command)) return it;
        return null;
    }

    /** 帮助页搜索过滤：命令名/功能/步骤/实现 四段包含匹配（不区分大小写，
     *  内部统一转小写；空串返回全表）。 */
    public static List<Item> filter(List<Item> items, String needle) {
        String nd = Util.lower(needle == null ? "" : needle);
        List<Item> out = new ArrayList<>();
        for (Item it : items) {
            if (nd.isEmpty() ||
                Util.lower(it.command).contains(nd) ||
                Util.lower(it.function).contains(nd) ||
                Util.lower(it.steps).contains(nd) ||
                Util.lower(it.impl).contains(nd)) {
                out.add(it);
            }
        }
        return out;
    }
}
