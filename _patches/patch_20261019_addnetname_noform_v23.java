import java.io.IOException;
import java.nio.charset.Charset;
import java.nio.charset.CharsetEncoder;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

public class patch_20261019_addnetname_noform_v23 {
    private static final Charset GBK = Charset.forName("GBK");
    private static final Path IL = Paths.get("G:/ASTB/skill_src/modules/text/text_addnetname.il");
    private static final Path HELP = Paths.get("G:/ASTB/skill_src/core/help_map.dat");

    private static String ilText;
    private static String helpText;

    private static void replaceIlOnce(String oldText, String newText, String name) {
        int first = ilText.indexOf(oldText);
        if (first >= 0) {
            int last = ilText.lastIndexOf(oldText);
            if (first != last) {
                throw new IllegalStateException(name + ": anchor is not unique");
            }
            ilText = ilText.substring(0, first) + newText + ilText.substring(first + oldText.length());
            System.out.println("[ok] " + name);
            return;
        }
        if (!newText.isEmpty() && ilText.contains(newText)) {
            System.out.println("[skip] " + name + " already applied");
            return;
        }
        throw new IllegalStateException(name + ": anchor not found");
    }

    private static void removeIlOnce(String oldText, String name) {
        int first = ilText.indexOf(oldText);
        if (first < 0) {
            System.out.println("[skip] " + name + " already removed");
            return;
        }
        int last = ilText.lastIndexOf(oldText);
        if (first != last) {
            throw new IllegalStateException(name + ": anchor is not unique");
        }
        ilText = ilText.substring(0, first) + ilText.substring(first + oldText.length());
        System.out.println("[ok] " + name);
    }

    private static void removeIlRange(String startMarker, String endMarker, String name) {
        int start = ilText.indexOf(startMarker);
        if (start < 0) {
            System.out.println("[skip] " + name + " already removed");
            return;
        }
        int end = ilText.indexOf(endMarker, start);
        if (end < 0) {
            throw new IllegalStateException(name + ": end anchor not found");
        }
        ilText = ilText.substring(0, start) + ilText.substring(end);
        System.out.println("[ok] " + name);
    }

    private static void replaceHelpOnce(String oldText, String newText, String name) {
        int first = helpText.indexOf(oldText);
        if (first >= 0) {
            int last = helpText.lastIndexOf(oldText);
            if (first != last) {
                throw new IllegalStateException(name + ": anchor is not unique");
            }
            helpText = helpText.substring(0, first) + newText + helpText.substring(first + oldText.length());
            System.out.println("[ok] " + name);
            return;
        }
        if (helpText.contains(newText)) {
            System.out.println("[skip] " + name + " already applied");
            return;
        }
        throw new IllegalStateException(name + ": anchor not found");
    }

    private static void requireAbsent(String text, String token, String fileName) {
        if (text.contains(token)) {
            throw new IllegalStateException(fileName + ": stale token remains: " + token);
        }
    }

    private static void writeGbk(Path path, String text) throws IOException {
        CharsetEncoder encoder = GBK.newEncoder();
        if (!encoder.canEncode(text)) {
            throw new IllegalStateException(path + ": text is not GBK-encodable");
        }
        Files.write(path, text.getBytes(GBK));
    }

    public static void main(String[] args) throws Exception {
        ilText = new String(Files.readAllBytes(IL), GBK);
        helpText = new String(Files.readAllBytes(HELP), GBK);

        replaceIlOnce(
            ";                   撤销栈仍只存(层 放置点 文本内容)纯数据, 兼容既有 undo\n" +
            ";========================================================================\n",
            ";                   撤销栈仍只存(层 放置点 文本内容)纯数据, 兼容既有 undo\n" +
            ";   2026-10-19 v1.23 ASTB 按用户要求移除临时选项表单：命令不再生成/加载\n" +
            ";                   D:/Temp 下 .form，固定原默认参数(不镜像/0度/Block 2/左对齐)，\n" +
            ";                   避免选项表单加载失败后字段初始化报错\n" +
            ";========================================================================\n",
            "addnetname v1.23 header history");

        replaceIlOnce(
            "; 版本      : 1.22\n",
            "; 版本      : 1.23\n",
            "addnetname version");

        replaceIlOnce(
            "; 功能    : 命令入口：生成选项表单，进入拾取-放置循环\n",
            "; 功能    : 命令入口：固定默认文本参数，进入拾取-放置循环\n",
            "addnetname entry comment");

        removeIlOnce(
            "unless(boundp('fm_crtn)                fm_crtn = nil)\n",
            "remove stale form handle global");

        replaceIlOnce(
            "(let (addr)\n",
            "(let ()\n",
            "entry no longer needs temp path local");

        replaceIlOnce(
            "    ;--- 在临时目录动态生成 FORM 文件 ---\n" +
            "    addr = strcat(axlTempFile() \".form\")\n" +
            "    _dbCreatCreateNetSilkForm(addr)\n" +
            "    fm_crtn = axlMiniStatusLoad((gensym) addr `_dbCreateNetSilkCallback t)\n" +
            "    when(isFile(addr) errset(deleteFile(addr)))\n" +
            "\n" +
            "    axlSetActiveLayer(\"BOARD GEOMETRY/SILKSCREEN_TOP\")\n" +
            "    axlFormSetField(fm_crtn \"mirror\" nil)\n" +
            "    axlFormSetField(fm_crtn \"angle\" \"0\")\n" +
            "    axlFormSetField(fm_crtn \"text_block\" \"2\")\n" +
            "    axlFormSetField(fm_crtn \"text_justification\" \"left\")\n",
            "    ;--- v1.23: 不加载选项表单；使用固定默认参数 ---\n" +
            "    axlSetActiveLayer(\"BOARD GEOMETRY/SILKSCREEN_TOP\")\n",
            "remove temp form creation and initialization");

        replaceIlOnce(
            "    mir = case(axlFormGetField(fm_crtn \"mirror\")  (\"1\" t) (\"0\" nil))\n" +
            "    ang = atof(axlFormGetField(fm_crtn \"angle\"))\n" +
            "    blk = axlFormGetField(fm_crtn \"text_block\")\n" +
            "    jst = axlFormGetField(fm_crtn \"text_justification\")\n",
            "    ;--- v1.23: 原表单默认值固定：不镜像/0度/Block 2/左对齐 ---\n" +
            "    mir = nil\n" +
            "    ang = 0.0\n" +
            "    blk = \"2\"\n" +
            "    jst = \"left\"\n",
            "fixed text defaults");

        replaceIlOnce(
            ";--- 全局变量保护（命令句柄/表单句柄/事务标记/放置状态） ---\n",
            ";--- 全局变量保护（事务标记/放置状态/撤销批次） ---\n",
            "global comment no form handle");

        removeIlOnce(
            "    axlControlRaise('options)    ;--- 弹出 options 选项面板 ---\n",
            "remove obsolete options panel raise");

        replaceIlOnce(
            "; 参数    : blk - block 号字符串(表单 \"text_block\" 字段值)\n",
            "; 参数    : blk - block 号字符串（固定默认值 \"2\"）\n",
            "text block comment no form");

        replaceIlOnce(
            "; 功能    : 对拾取到的对象取其网络名，按表单参数创建文本并让用户拖动放置\n",
            "; 功能    : 对拾取到的对象取其网络名，按固定默认参数创建文本并让用户拖动放置\n",
            "create function comment no form");

        removeIlRange(
            ";------------------------------------------------------------------------\n" +
            "; 函数名  : _dbCreateNetSilkCallback\n",
            ";------------------------------------------------------------------------\n" +
            "; 函数名  : _dbCreateNetSilkDone\n",
            "remove obsolete form callback and generator");

        String oldHelp =
            "ASTB_Text_AddNetName|在版图上添加网络名称文本（点哪个对象就放哪个网名）|①命令弹出选项小表单（层固定丝印顶，可设镜像/角度/字块/对齐）②点选管脚/过孔/铜皮/线段 ③该对象的网络名文本随光标拖动，点击放置 ④可连续放多个，右键 Done 提交/Cancel 回滚/Oops 单步撤销|axlMiniStatusLoad 选项表单加 axlDBTransactionStart 事务，拾取对象取 net->name 后 axlDBCreateText 加 axlDynamicsObject 拖动放置，批次（层/放置点/文本）入 _TANN_placedBatches（modules/text/text_addnetname.il）";
        String newHelp =
            "ASTB_Text_AddNetName|在版图上添加网络名称文本（点哪个对象就放哪个网名）|①命令直接进入拾取（层固定丝印顶；默认不镜像/0度/字块2/左对齐）②点选管脚/过孔/铜皮/线段 ③该对象的网络名文本随光标拖动，点击放置 ④可连续放多个，右键 Done 提交/Cancel 回滚/Oops 单步撤销|axlDBTransactionStart 事务，拾取对象取 net->name 后 axlDBCreateText 加 axlDynamicsObject 拖动放置，批次（层/放置点/文本）入 _TANN_placedBatches（modules/text/text_addnetname.il）";
        replaceHelpOnce(oldHelp, newHelp, "help map addnetname no-form description");

        requireAbsent(ilText, "fm_crtn", "text_addnetname.il");
        requireAbsent(ilText, "_dbCreatCreateNetSilkForm", "text_addnetname.il");
        requireAbsent(ilText, "_dbCreateNetSilkCallback", "text_addnetname.il");
        requireAbsent(ilText, "axlMiniStatusLoad", "text_addnetname.il");
        if (!ilText.contains("; 版本      : 1.23\n")) {
            throw new IllegalStateException("text_addnetname.il: v1.23 header missing");
        }

        writeGbk(IL, ilText);
        writeGbk(HELP, helpText);
        System.out.println("[done] addnetname no-form patch applied");
    }
}
