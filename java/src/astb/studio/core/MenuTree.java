// ============================================================================
// File        : MenuTree.java
// Description : Menu tree for the command panel: <bridge>\menu_tree.json
//               (GBK) live first (a successful live read refreshes the cache
//               copy under .astb_studio), cache as fallback.
// ============================================================================
package astb.studio.core;

import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

public final class MenuTree {
    public static final int SRC_NONE = 0, SRC_LIVE = 1, SRC_CACHE = 2;

    private MenuTree() {}

    public static Path cachePath() { return Util.join(Util.appDir(), "menu_tree.json"); }

    private static Map<String, Object> parseTree(String text) {
        Map<String, Object> o = MiniJson.obj(MiniJson.parse(text));
        if (o == null || MiniJson.arr(o.get("tree")) == null) return null;
        return o;
    }

    /** Testable core: live file at an explicit path (fallback = the cache).
     *  字节直通：live 原文直接写缓存（GBK 原文不经 UTF-16 往返）。 */
    public static int getFrom(Path livePath, Map<String, Object>[] out) {
        byte[] raw = Util.readBytes(livePath);
        Map<String, Object> o = raw == null ? null : parseTree(new String(raw, Util.GBK));
        if (o != null) {
            Util.writeBytes(cachePath(), raw);   // refresh cache (byte-for-byte)
            out[0] = o;
            return SRC_LIVE;
        }
        String text = Util.readText(cachePath(), Util.GBK);
        o = text == null ? null : parseTree(text);
        if (o != null) {
            out[0] = o;
            return SRC_CACHE;
        }
        out[0] = MiniJson.newObj();
        return SRC_NONE;
    }

    @SuppressWarnings("unchecked")
    public static int get(Map<String, Object>[] out) {
        return getFrom(Util.join(Util.bridgeRoot(), "menu_tree.json"), out);
    }

    // ---- model helpers ---------------------------------------------------------------
    public static String nodeType(Map<String, Object> n) { return MiniJson.getStr(n, "type", ""); }

    public static String nodeLabel(Map<String, Object> n) {
        String s = MiniJson.getStr(n, "label_zh", "");
        if (s.isEmpty()) s = MiniJson.getStr(n, "label", "");
        if (s.isEmpty()) s = MiniJson.getStr(n, "command", "");
        return s;
    }

    public static List<Object> children(Map<String, Object> n) {
        return MiniJson.arr(n.get("children"));
    }

    /** (label, command) pairs from popup children recursively (Python _collect). */
    public static void collectCommands(List<Object> nodes,
                                       List<String[]> acc) {
        if (nodes == null) return;
        for (Object o : nodes) {
            Map<String, Object> n = MiniJson.obj(o);
            if (n == null) continue;
            String type = nodeType(n);
            if ("command".equals(type)) {
                acc.add(new String[] { nodeLabel(n), MiniJson.getStr(n, "command", "") });
            } else if ("popup".equals(type)) {
                collectCommands(children(n), acc);
            }
        }
    }

    /** Category roots: tree[] (single root popup -> its children). */
    public static List<Object> categoryRoots(Map<String, Object> menuTree) {
        List<Object> tree = MiniJson.arr(menuTree.get("tree"));
        if (tree == null) return List.of();
        if (tree.size() == 1) {
            Map<String, Object> r = MiniJson.obj(tree.get(0));
            if (r != null && "popup".equals(nodeType(r))) {
                List<Object> ch = children(r);
                if (ch != null) return ch;
            }
        }
        return tree;
    }

    public static int countCommands(Map<String, Object> menuTree) {
        List<String[]> acc = new ArrayList<>();
        for (Object o : categoryRoots(menuTree)) {
            Map<String, Object> n = MiniJson.obj(o);
            if (n == null) continue;
            if ("command".equals(nodeType(n)))
                acc.add(new String[] { nodeLabel(n), MiniJson.getStr(n, "command", "") });
            else
                collectCommands(children(n), acc);
        }
        return acc.size();
    }

    /** Button-grid match (Python CommandPanel._matches). */
    public static boolean cmdMatches(String needleLower, String label, String cmd) {
        if (needleLower == null || needleLower.isEmpty()) return true;
        return Util.lower(label).contains(needleLower) || Util.lower(cmd).contains(needleLower);
    }
}
