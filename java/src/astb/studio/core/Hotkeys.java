// ============================================================================
// File        : Hotkeys.java
// Description : Hotkey table IO, sharing config/hotkeys_user.dat with the
//               Allegro-side hotkey editor. GBK, pipe-separated
//               "键|命令|说明" per line; fields are NEVER trimmed (a single
//               space is a valid key). Port of features.py hotkey part +
//               the four bridge expressions (verbatim).
// ============================================================================
package astb.studio.core;

import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

public final class Hotkeys {

    public static final class Row {
        public String key;
        public String cmd;
        public String desc;
        public Row(String k, String c, String d) { key = k; cmd = c; desc = d; }
    }

    private Hotkeys() {}

    // Bridge expressions (features.py: hotkeys_flush_live / hotkeys_push_live /
    // hotkeys_reset_live / hotkeys_restore_defaults_live).
    public static final String EXPR_FLUSH = "car(errset(_HotkeyEditor_SaveUser() 'e))";
    public static final String EXPR_PUSH =
            "when(car(errset(_HotkeyEditor_LoadUser() nil)) errset(_HotkeyEditor_Apply() t))";
    public static final String EXPR_RESET = "errset(HotkeySetup_ResetAll() t)";
    public static final String EXPR_RESTORE =
            "progn(_HotkeyEditor_RestoreDefaults() car(errset(_HotkeyEditor_SaveUser() 'e)))";

    public static Path userPath(String toolboxRoot) {
        return Util.join(Util.join(Path.of(toolboxRoot), "config"), "hotkeys_user.dat");
    }

    public static Path factoryPath(String toolboxRoot) {
        return Util.join(Util.join(Path.of(toolboxRoot), "config"), "hotkeys_factory.dat");
    }

    /** The parsing core on already-decoded text (edit->serialize->parse tests). */
    public static List<Row> parseText(String text) {
        List<Row> rows = new ArrayList<>();
        if (text == null) return rows;
        for (String line : text.split("\n", -1)) {
            if (line.endsWith("\r")) line = line.substring(0, line.length() - 1);
            if (line.isEmpty() || line.charAt(0) == ';') continue;
            String[] parts = Util.split(line, '|');
            if (parts.length < 2) continue;
            // 键或命令为空的行跳过；不做 trim——空格键是有效键
            if (parts[0].isEmpty() || parts[1].isEmpty()) continue;
            rows.add(new Row(parts[0], parts[1], parts.length >= 3 ? parts[2] : ""));
        }
        return rows;
    }

    public static List<Row> readDat(Path path) {
        return parseText(Util.readText(path, Util.GBK));
    }

    /** Effective grid table: user dat when it exists, else factory. */
    public static List<Row> load(String toolboxRoot, boolean[] fromUser) {
        Path user = userPath(toolboxRoot);
        if (Util.exists(user)) {
            if (fromUser != null) fromUser[0] = true;
            return readDat(user);
        }
        if (fromUser != null) fromUser[0] = false;
        return loadFactory(toolboxRoot);
    }

    public static List<Row> loadFactory(String toolboxRoot) {
        return readDat(factoryPath(toolboxRoot));
    }

    public static String serialize(List<Row> rows) {
        StringBuilder sb = new StringBuilder();
        for (Row r : rows)
            sb.append(r.key).append('|').append(r.cmd).append('|').append(r.desc).append('\n');
        return sb.toString();
    }

    /** Write hotkeys_user.dat as GBK "键|命令|说明\n" (LF endings, like Python).
     *  原子写：Allegro 侧共享读取不会读到半截文件。 */
    public static boolean save(String toolboxRoot, List<Row> rows) {
        return Util.writeTextAtomic(userPath(toolboxRoot), serialize(rows), Util.GBK);
    }
}
