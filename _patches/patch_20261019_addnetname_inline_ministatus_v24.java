import java.io.IOException;
import java.nio.charset.Charset;
import java.nio.charset.CharsetEncoder;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

public class patch_20261019_addnetname_inline_ministatus_v24 {
    private static final Charset GBK = Charset.forName("GBK");
    private static final Path IL = Paths.get("G:/ASTB/skill_src/modules/text/text_addnetname.il");
    private static final Path HELP = Paths.get("G:/ASTB/skill_src/core/help_map.dat");

    private static String ilText;
    private static String helpText;

    private static void replaceIlOnce(String oldText, String newText, String name) {
        int first = ilText.indexOf(oldText);
        if (first >= 0) {
            int last = ilText.lastIndexOf(oldText);
            if (first != last) throw new IllegalStateException(name + ": anchor is not unique");
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

    private static void replaceHelpOnce(String oldText, String newText, String name) {
        int first = helpText.indexOf(oldText);
        if (first >= 0) {
            int last = helpText.lastIndexOf(oldText);
            if (first != last) throw new IllegalStateException(name + ": anchor is not unique");
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

    private static void requireAbsent(String token) {
        if (ilText.contains(token)) throw new IllegalStateException("text_addnetname.il: stale token remains: " + token);
    }

    private static void requirePresent(String token) {
        if (!ilText.contains(token)) throw new IllegalStateException("text_addnetname.il: required token missing: " + token);
    }

    private static void writeGbk(Path path, String text) throws IOException {
        CharsetEncoder encoder = GBK.newEncoder();
        if (!encoder.canEncode(text)) throw new IllegalStateException(path + ": text is not GBK-encodable");
        Files.write(path, text.getBytes(GBK));
    }

    public static void main(String[] args) throws Exception {
        ilText = new String(Files.readAllBytes(IL), GBK);
        helpText = new String(Files.readAllBytes(HELP), GBK);

        replaceIlOnce(
            ";                   避免选项表单加载失败后字段初始化报错\n" +
            ";========================================================================\n",
            ";                   避免选项表单加载失败后字段初始化报错\n" +
            ";   2026-10-19 v1.24 ASTB 修复退出：v1.23 删除 Ministatus 后右键 popup 失去宿主；\n" +
            ";                   改载内联最小状态表单(不落临时文件)，popup 回调改 ASCII 字符串\n" +
            ";                   并在每轮重设，恢复 Done/Oops/Cancel\n" +
            ";========================================================================\n",
            "addnetname v1.24 header history");

        replaceIlOnce(
            "; 版本      : 1.23\n",
            "; 版本      : 1.24\n",
            "addnetname version");

        replaceIlOnce(
            ";--- 全局变量保护（事务标记/放置状态/撤销批次） ---\n" +
            "unless(boundp('_dbCreateNetSilkFinish) _dbCreateNetSilkFinish = nil)\n" +
            "unless(boundp('mk_crtn)                mk_crtn = nil)\n" +
            "unless(boundp('_dbCreateNetSilkStage)  _dbCreateNetSilkStage = nil)\n" +
            "unless(boundp('_dbCreateNetSilkBatch)  _dbCreateNetSilkBatch = nil)    ;--- v1.8: 当次会话放置记录 ---\n" +
            "unless(boundp('_TANN_placedBatches)    _TANN_placedBatches = nil)      ;--- v1.8: Done 撤销批次栈 ---\n",
            ";--- 全局变量保护（事务标记/放置状态/撤销批次/右键菜单/状态表单） ---\n" +
            "unless(boundp('_dbCreateNetSilkFinish) _dbCreateNetSilkFinish = nil)\n" +
            "unless(boundp('mk_crtn)                mk_crtn = nil)\n" +
            "unless(boundp('_dbCreateNetSilkStage)  _dbCreateNetSilkStage = nil)\n" +
            "unless(boundp('_dbCreateNetSilkBatch)  _dbCreateNetSilkBatch = nil)    ;--- v1.8: 当次会话放置记录 ---\n" +
            "unless(boundp('_TANN_placedBatches)    _TANN_placedBatches = nil)      ;--- v1.8: Done 撤销批次栈 ---\n" +
            "unless(boundp('_TANN_popup)            _TANN_popup = nil)              ;--- v1.24: 右键 popup ---\n" +
            "unless(boundp('_TANN_miniForm)         _TANN_miniForm = nil)           ;--- v1.24: 内联状态表单 ---\n" +
            "\n" +
            ";--- v1.24: 内联 Ministatus（只作右键 popup 宿主，不写临时 .form） ---\n" +
            "_TANN_inlineForm = '(\"\n" +
            "\tFILE_TYPE=FORM_DEFN VERSION=2\n" +
            "\tFORM AUTOGREYTEXT\n" +
            "\tFIXED\n" +
            "\tPORT 34 4\n" +
            "\tHEADER \\\"Add Net Name\\\"\n" +
            "\t\n" +
            "\tTILE\n" +
            "\tTEXT \\\"Pick pin / via / shape / cline\\\"\n" +
            "\tTLOC 1 1\n" +
            "\tENDTEXT\n" +
            "\tENDTILE\n" +
            "\t\n" +
            "\tENDFORM\n" +
            "\t\")\n",
            "inline ministatus globals");

        replaceIlOnce(
            "procedure( ASTB_Text_AddNetName()\n" +
            "(let ()\n" +
            "    _dbCreateNetSilkFinish = nil\n" +
            "    _dbCreateNetSilkBatch = nil    ;--- v1.8: 清空本次会话放置记录(供 Done 后撤销) ---\n" +
            "\n" +
            "    ;--- v1.23: 不加载选项表单；使用固定默认参数 ---\n" +
            "    axlSetActiveLayer(\"BOARD GEOMETRY/SILKSCREEN_TOP\")\n" +
            "\n" +
            "    ;--- v1.7: popup 标签改英文(GBK 中文标签触发 reader \"Invalid character\") ---\n" +
            "    axlUIPopupSet(axlUIPopupDefine(nil\n" +
            "            (list\n" +
            "                (list \"Done\"   '_dbCreateNetSilkDone)\n" +
            "                (list \"Oops\"   '_dbCreateNetSilkOops)\n" +
            "                (list \"Cancel\" '_dbCreateNetSilkCancel)\n" +
            "            )))\n" +
            "    axlClearSelSet()\n" +
            "    axlSetFindFilter(?enabled `(\"NOALL\" \"PINS\" \"VIAS\" \"SHAPES\" \"CLINESEGS\") ?onButtons `(\"PINS\" \"VIAS\" \"SHAPES\" \"CLINESEGS\"))\n" +
            "    mk_crtn = axlDBTransactionStart()\n" +
            "    while( !_dbCreateNetSilkFinish\n" +
            "        when(axlSingleSelectPoint()\n" +
            "            axlDBTransactionMark(mk_crtn)\n" +
            "            _dbCreateNetSilk(axlLastPick(nil) axlGetSelSet())\n" +
            "        )\n" +
            "    )\n" +
            "    axlUIPopupSet(nil)\n" +
            "))\n",
            "procedure( ASTB_Text_AddNetName()\n" +
            "(let ()\n" +
            "    _dbCreateNetSilkFinish = nil\n" +
            "    _dbCreateNetSilkBatch = nil    ;--- v1.8: 清空本次会话放置记录(供 Done 后撤销) ---\n" +
            "    _TANN_popup = nil\n" +
            "\n" +
            "    ;--- v1.24: 内联状态表单只承接右键菜单；参数仍固定默认值 ---\n" +
            "    _TANN_miniForm = axlMiniStatusLoad((gensym)\n" +
            "        list(\"ASTB_AddNetName\" _TANN_inlineForm)\n" +
            "        '_dbCreateNetSilkCallback t)\n" +
            "    unless( _TANN_miniForm\n" +
            "        printf(\"WARNING: inline ministatus load failed; continue\\n\")\n" +
            "    )\n" +
            "    axlSetActiveLayer(\"BOARD GEOMETRY/SILKSCREEN_TOP\")\n" +
            "    axlControlRaise('options)\n" +
            "\n" +
            "    ;--- popup 标签/回调均用 ASCII；字符串回调在 Ministatus 上下文最稳 ---\n" +
            "    _TANN_popup = axlUIPopupDefine(nil\n" +
            "            (list\n" +
            "                (list \"Done\"   \"_dbCreateNetSilkDone()\")\n" +
            "                (list \"Oops\"   \"_dbCreateNetSilkOops()\")\n" +
            "                (list \"Cancel\" \"_dbCreateNetSilkCancel()\")\n" +
            "            ))\n" +
            "    axlUIPopupSet(_TANN_popup)\n" +
            "    axlClearSelSet()\n" +
            "    axlSetFindFilter(?enabled `(\"NOALL\" \"PINS\" \"VIAS\" \"SHAPES\" \"CLINESEGS\") ?onButtons `(\"PINS\" \"VIAS\" \"SHAPES\" \"CLINESEGS\"))\n" +
            "    mk_crtn = axlDBTransactionStart()\n" +
            "    while( !_dbCreateNetSilkFinish\n" +
            "        when(axlSingleSelectPoint()\n" +
            "            axlDBTransactionMark(mk_crtn)\n" +
            "            _dbCreateNetSilk(axlLastPick(nil) axlGetSelSet())\n" +
            "            axlUIPopupSet(_TANN_popup)    ;--- 每轮重设，防 popup 被吃掉 ---\n" +
            "        )\n" +
            "    )\n" +
            "    axlUIPopupSet(nil)\n" +
            "    _TANN_popup = nil\n" +
            "))\n",
            "entry inline ministatus and robust popup");

        replaceIlOnce(
            "        _dbCreateNetSilkStage = nil\n" +
            "        ptPlace = axlEnterPoint(?prompts `(\"请点击选择文本放置点\"))    ;--- 等待用户点击放置点 ---\n",
            "        _dbCreateNetSilkStage = nil\n" +
            "        when(_TANN_popup axlUIPopupSet(_TANN_popup))    ;--- 放置阶段也保持右键菜单 ---\n" +
            "        ptPlace = axlEnterPoint(?prompts `(\"请点击选择文本放置点\"))    ;--- 等待用户点击放置点 ---\n",
            "keep popup during placement");

        replaceIlOnce(
            ";------------------------------------------------------------------------\n" +
            "; 函数名  : _dbCreateNetSilkDone\n",
            ";------------------------------------------------------------------------\n" +
            "; 函数名  : _dbCreateNetSilkCallback\n" +
            "; 功能    : 内联 Ministatus 回调（无参数项，占位即可）\n" +
            ";------------------------------------------------------------------------\n" +
            "procedure( _dbCreateNetSilkCallback(fw)\n" +
            "    t\n" +
            ")\n" +
            "\n" +
            ";------------------------------------------------------------------------\n" +
            "; 函数名  : _dbCreateNetSilkDone\n",
            "insert inline ministatus callback");

        replaceIlOnce(
            "procedure( _dbCreateNetSilkDone()\n" +
            "    _dbCreateNetSilkFinish = t\n",
            "procedure( _dbCreateNetSilkDone()\n" +
            "    axlUIPopupSet(nil)\n" +
            "    _dbCreateNetSilkFinish = t\n",
            "done clears popup");

        replaceIlOnce(
            "procedure( _dbCreateNetSilkCancel()\n" +
            "    _dbCreateNetSilkFinish = t\n",
            "procedure( _dbCreateNetSilkCancel()\n" +
            "    axlUIPopupSet(nil)\n" +
            "    _dbCreateNetSilkFinish = t\n",
            "cancel clears popup");

        String oldHelp =
            "ASTB_Text_AddNetName|在版图上添加网络名称文本（点哪个对象就放哪个网名）|①命令直接进入拾取（层固定丝印顶；默认不镜像/0度/字块2/左对齐）②点选管脚/过孔/铜皮/线段 ③该对象的网络名文本随光标拖动，点击放置 ④可连续放多个，右键 Done 提交/Cancel 回滚/Oops 单步撤销|axlDBTransactionStart 事务，拾取对象取 net->name 后 axlDBCreateText 加 axlDynamicsObject 拖动放置，批次（层/放置点/文本）入 _TANN_placedBatches（modules/text/text_addnetname.il）";
        String newHelp =
            "ASTB_Text_AddNetName|在版图上添加网络名称文本（点哪个对象就放哪个网名）|①命令直接进入拾取（层固定丝印顶；默认不镜像/0度/字块2/左对齐）②点选管脚/过孔/铜皮/线段 ③该对象的网络名文本随光标拖动，点击放置 ④可连续放多个，右键 Done 提交/Cancel 回滚/Oops 单步撤销|内联 Ministatus 承接右键 Done/Oops/Cancel；axlDBTransactionStart 事务，拾取对象取 net->name 后 axlDBCreateText 加 axlDynamicsObject 拖动放置，批次（层/放置点/文本）入 _TANN_placedBatches（modules/text/text_addnetname.il）";
        replaceHelpOnce(oldHelp, newHelp, "help map addnetname inline ministatus");

        requireAbsent("_dbCreatCreateNetSilkForm");
        requireAbsent("axlFormSetField");
        requireAbsent("axlFormGetField");
        requirePresent("_TANN_inlineForm");
        requirePresent("axlMiniStatusLoad");
        requirePresent("\"_dbCreateNetSilkDone()\"");
        requirePresent("; 版本      : 1.24\n");

        writeGbk(IL, ilText);
        writeGbk(HELP, helpText);
        System.out.println("[done] addnetname inline ministatus patch applied");
    }
}
