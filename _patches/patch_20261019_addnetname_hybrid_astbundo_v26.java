import java.io.IOException;
import java.nio.charset.Charset;
import java.nio.charset.CharsetEncoder;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

public class patch_20261019_addnetname_hybrid_astbundo_v26 {
    private static final Charset GBK = Charset.forName("GBK");
    private static final Path IL = Paths.get("G:/ASTB/skill_src/modules/text/text_addnetname.il");
    private static final Path HELP = Paths.get("G:/ASTB/skill_src/core/help_map.dat");

    private static String lines(String... values) {
        return String.join("\n", values) + "\n";
    }

    private static void require(boolean condition, String message) {
        if (!condition) throw new IllegalStateException(message);
    }

    private static void writeGbk(Path path, String text) throws IOException {
        CharsetEncoder encoder = GBK.newEncoder();
        if (!encoder.canEncode(text)) throw new IllegalStateException(path + ": text is not GBK-encodable");
        Files.write(path, text.getBytes(GBK));
    }

    public static void main(String[] args) throws Exception {
        String current = new String(Files.readAllBytes(IL), GBK);
        int formStart = current.indexOf(";;form响应函数");
        int formEnd = current.indexOf("procedure( _dbCreateNetSilkDone()", formStart);
        require(formStart >= 0, "form section start not found");
        require(formEnd > formStart, "form section end not found");
        String formSection = current.substring(formStart, formEnd);

        String header = lines(
            ";========================================================================",
            "; 文件名    : text_addnetname.il",
            "; 作者      : FYNN（原作）；ASTB（工具箱集成整改）",
            "; 创建日期  : [未知]",
            "; 版本      : 1.26",
            "; 功能描述  : 在指定位置添加网络名称文本，支持交互式拾取管脚/过孔/图形并拖动放置",
            "; 依赖模块  : core（ASTB_RegisterCommand / ASTB_RegisterUndo）",
            "; 修改记录  :",
            ";   [原始日期] v1.0 FYNN 初始创建（FanySkill_create_net_silk.il）",
            ";   2026-10-19 v1.25 ASTB 回退为 FanySkill 原版表单与右键交互流程",
            ";   2026-10-19 v1.26 ASTB 保留原版表单，修复原版中心锚点/放置失败：",
            ";             放置阶段不再 erase+transform 预创建文本，改矩形预览后现场创建；",
            ";             Text Just 按最终放置点生效；增加 astbundo 批次撤销",
            ";========================================================================",
            "",
            ";; ============================================================",
            ";; File: text_addnetname.il",
            ";; Purpose: Add net name",
            ";; Encoding: GBK",
            ";; Source: FanySkill_create_net_silk.il form flow + ASTB placement/undo",
            ";; ============================================================",
            ""
        );

        String globals = lines(
            ";--- 全局变量保护（表单句柄/事务标记/放置状态/撤销批次） ---",
            "unless(boundp('_dbCreateNetSilkFinish) _dbCreateNetSilkFinish = nil)",
            "unless(boundp('fm_crtn)                fm_crtn = nil)",
            "unless(boundp('mk_crtn)                mk_crtn = nil)",
            "unless(boundp('_dbCreateNetSilkStage)  _dbCreateNetSilkStage = nil)",
            "unless(boundp('_dbCreateNetSilkBatch)  _dbCreateNetSilkBatch = nil)    ;--- v1.26: 当次会话放置记录 ---",
            "unless(boundp('_TANN_placedBatches)    _TANN_placedBatches = nil)      ;--- v1.26: Done 撤销批次栈 ---",
            ""
        );

        String helpers = lines(
            ";------------------------------------------------------------------------",
            "; 函数    : _NNTextBlockHeight",
            "; 功能    : 取指定 text block 的高度(供放置预览矩形估算大小); 取不到返回 25",
            "; 参数    : blk - block 号字符串(表单 \"text_block\" 字段值)",
            ";------------------------------------------------------------------------",
            "procedure( _NNTextBlockHeight(blk)",
            "(let (param h)",
            "    param = errset(axlGetParam(sprintf(nil \"paramTextBlock:%s\" blk)) t)",
            "    h = if( param && car(param) then car(param)->height else 25.0 )",
            "    if( h && h > 0.0 then h else 25.0 )",
            "))",
            ""
        );

        String entry = lines(
            ";;主函数",
            "procedure( ASTB_Text_AddNetName()",
            "(let (addr)",
            "\t_dbCreateNetSilkFinish = nil",
            "    _dbCreateNetSilkBatch = nil    ;--- v1.26: 清空本次会话放置记录(供 Done 后撤销) ---",
            "",
            "    ;创建FORM（沿用 FanySkill 原版 Ministatus 表单，仅文件名加 ASTB 前缀）",
            "\taddr = \"./ASTB_CreateNetSilk.form\"",
            "\t_dbCreatCreateNetSilkForm(addr)",
            "    fm_crtn = axlMiniStatusLoad((gensym) addr `_dbCreateNetSilkCallback t)",
            "\twhen(isFile(addr) errset(deleteFile(addr)))",
            "",
            "    axlSetActiveLayer(\"BOARD GEOMETRY/SILKSCREEN_TOP\")",
            "    axlFormSetField(fm_crtn \"mirror\" nil)",
            "    axlFormSetField(fm_crtn \"angle\" \"0\")",
            "    axlFormSetField(fm_crtn \"text_block\" \"2\")",
            "    axlFormSetField(fm_crtn \"text_justification\" \"left\")",
            "",
            "\taxlUIPopupSet(axlUIPopupDefine(nil",
            "\t\t\t'((\"Done\" _dbCreateNetSilkDone)",
            "\t\t\t  (\"Oops\" _dbCreateNetSilkOops)",
            "\t\t\t  (\"Cancel\" _dbCreateNetSilkCancel)",
            "\t)))",
            "    axlControlRaise('options)\t;右侧显示options选项置顶",
            "    axlClearSelSet()",
            "    axlSetFindFilter(?enabled `(\"NOALL\" \"PINS\" \"VIAS\" \"SHAPES\" \"CLINESEGS\") ?onButtons `(\"PINS\" \"VIAS\" \"SHAPES\" \"CLINESEGS\"))",
            "\tmk_crtn = axlDBTransactionStart()",
            "    while( !_dbCreateNetSilkFinish",
            "        when(axlSingleSelectPoint()",
            "            axlDBTransactionMark(mk_crtn)",
            "            _dbCreateNetSilk(axlLastPick(nil) axlGetSelSet())",
            "        )",
            "\t)",
            "    axlUIPopupSet(nil)",
            "))",
            ""
        );

        String placement = lines(
            "procedure(_dbCreateNetSilk(pt item)",
            "(let (id layer mir ang blk jst myorient netname theight twidth x0 rect outline ptPlace ret )",
            "",
            "    axlClearSelSet()",
            "    id = car(item)",
            "    layer = axlGetActiveLayer()",
            "    mir = case(axlFormGetField(fm_crtn \"mirror\")  (\"1\" t) (\"0\" nil))",
            "    ang = atof(axlFormGetField(fm_crtn \"angle\"))",
            "    blk = axlFormGetField(fm_crtn \"text_block\")",
            "    jst = axlFormGetField(fm_crtn \"text_justification\")",
            "    myorient = make_axlTextOrientation(?textBlock blk ?rotation ang ?mirrored mir ?justify jst)",
            "",
            "    ;--- v1.26: 进 enter 前提取纯数据；enter 后绝不再访问旧 dbid ---",
            "    netname = id->net->name",
            "    if( netname != \"\" && netname != nil then",
            "        axlVisibleLayer(layer t)",
            "        axlVisibleUpdate(nil)",
            "",
            "        ;--- 预览只用矩形框，不预创建文本再 erase/transform ---",
            "        theight = _NNTextBlockHeight(blk)",
            "        twidth = theight * strlen(netname) * 0.6",
            "        if( twidth < theight then twidth = theight )",
            "        x0 = case(jst (\"center\" -twidth/2.0) (\"right\" -twidth) (t 0.0))",
            "        rect = list(x0:0 x0+twidth:0 x0+twidth:theight x0:theight x0:0)",
            "        outline = errset(axlPathStart(rect) t)",
            "        when( and(outline car(outline))",
            "            errset(axlAddSimpleMoveDynamics(0:0 car(outline) \"path\" ?ref_point 0:0) nil)",
            "        )",
            "        _dbCreateNetSilkStage = nil",
            "        ptPlace = axlEnterPoint(?prompts `(\"请点击选择文本放置点\"))",
            "        axlClearDynamics()",
            "        if( listp(ptPlace) then",
            "            ;--- Text Just/角度/镜像在最终创建时生效，抓取点不再固定中心 ---",
            "            ret = car(axlDBCreateText(netname ptPlace myorient layer nil))",
            "            if( ret then",
            "                _dbCreateNetSilkStage = t",
            "                _dbCreateNetSilkBatch = cons(list(layer ptPlace netname) _dbCreateNetSilkBatch)",
            "            else",
            "                printf(\"创建网络名文本失败！\\n\")",
            "            )",
            "        )",
            "        axlUIWRedraw(nil)",
            "    else",
            "        printf(\"网络名为空！\\n\")",
            "    )",
            "))",
            ""
        );

        String finishAndUndo = lines(
            "procedure( _dbCreateNetSilkDone()",
            "    _dbCreateNetSilkFinish = t",
            "    errset(axlDBTransactionCommit(mk_crtn) t)",
            "    ;--- v1.26: 当批记录压栈，astbundo 按 LIFO 撤销 ---",
            "    when( _dbCreateNetSilkBatch",
            "        _TANN_placedBatches = cons(reverse(_dbCreateNetSilkBatch) _TANN_placedBatches)",
            "        _dbCreateNetSilkBatch = nil",
            "        ASTB_UndoJournalPush(\"text_addnetname\")",
            "        printf(\"完成。输入 astbundo 可撤销本次修改\\n\")",
            "    )",
            "    axlFinishEnterFun()",
            ")",
            "",
            "procedure( _dbCreateNetSilkCancel()",
            "\t_dbCreateNetSilkFinish = t",
            "    errset(axlDBTransactionRollback(mk_crtn) t)",
            "    _dbCreateNetSilkBatch = nil    ;--- v1.26: 已回滚，当批记录作废 ---",
            "\taxlCancelEnterFun()",
            ")",
            "",
            "procedure( _dbCreateNetSilkOops()",
            "    when(!_dbCreateNetSilkStage",
            "        axlClearDynamics()\t;清除鼠标附着",
            "        axlCancelEnterFun()",
            "    )",
            "    axlDBTransactionOops(mk_crtn)",
            ")",
            "",
            ";------------------------------------------------------------------------",
            "; 函数名  : ASTB_Text_AddNetName_Undo",
            "; 功能    : 撤销最近一次 Done 放置的那批网络名文本(命令 ASTB_Text_AddNetNameu)",
            "; 备注    : 批次栈只存 层+放置点+文本内容，不存跨命令会失效的 dbid",
            ";------------------------------------------------------------------------",
            "procedure( ASTB_Text_AddNetName_Undo()",
            "(prog (batch rec lay pt txt hit obj n m rr)",
            "    unless( _TANN_placedBatches",
            "        axlUIWPrint(nil \"没有可撤销的记录\")",
            "        return(nil)",
            "    )",
            "    batch = car(_TANN_placedBatches)",
            "    _TANN_placedBatches = cdr(_TANN_placedBatches)",
            "    axlSetFindFilter(?enabled `(\"noall\" \"text\") ?onButtons `(\"noall\" \"text\"))",
            "    n = 0",
            "    m = 0",
            "    foreach( rec batch",
            "        lay = car(rec)",
            "        pt  = cadr(rec)",
            "        txt = caddr(rec)",
            "        errset(axlVisibleLayer(lay t) t)",
            "        axlVisibleUpdate(nil)",
            "        axlClearSelSet()",
            "        hit = nil",
            "        when( axlSingleSelectPoint(pt)",
            "            foreach( obj axlGetSelSet()",
            "                when( and(null(hit)",
            "                          equal(obj->layer lay)",
            "                          equal(obj->text txt)",
            "                          abs(car(obj->xy) - car(pt)) < 0.01",
            "                          abs(cadr(obj->xy) - cadr(pt)) < 0.01)",
            "                    hit = obj",
            "                )",
            "            )",
            "        )",
            "        if( hit then",
            "            rr = errset( axlDeleteObject(hit) t )",
            "            if( and(rr car(rr)) then",
            "                n = n + 1",
            "            else",
            "                m = m + 1",
            "                axlUIWPrint(nil \"  警告: %L 处文本(%s)删除失败\" pt txt)",
            "            )",
            "        else",
            "            axlUIWPrint(nil \"  提示: %L 处未找到文本(%s), 可能已被删除\" pt txt)",
            "        )",
            "    )",
            "    axlClearSelSet()",
            "    axlFlushDisplay()",
            "    axlUIWPrint(nil \"撤销完成: 删除 %d 个网络名文本, %d 个失败(剩余可撤销 %d 批)\"",
            "        n m length(_TANN_placedBatches))",
            "    return(t)",
            "))",
            ""
        );

        String registration = lines(
            ";--- ASTB 命令注册：保留 FanySkill 表单交互，接 ASTB 统一撤销 ---",
            "ASTB_RegisterCommand(\"ASTB_Text_AddNetName\" \"ASTB_Text_AddNetName\"",
            "    ?cmdType \"interactive\" ?undo nil",
            "    ?doneCmd '_dbCreateNetSilkDone ?cancelCmd '_dbCreateNetSilkCancel)",
            "",
            "ASTB_RegisterCommand(\"ASTB_Text_AddNetNameu\" \"ASTB_Text_AddNetName_Undo\"",
            "    ?cmdType \"general\" ?undo nil)",
            "ASTB_RegisterUndo(\"text_addnetname\" 'ASTB_Text_AddNetName_Undo)",
            "",
            "printf(\"[ASTB] text_addnetname.il v1.26 loaded (FanySkill form + ASTB placement/astbundo).\\n\")"
        );

        String updated = header + globals + helpers + entry + placement + formSection + finishAndUndo + registration;
        require(updated.contains("procedure( ASTB_Text_AddNetName()"), "entry missing");
        require(updated.contains("addr = \"./ASTB_CreateNetSilk.form\""), "form path missing");
        require(updated.contains("_dbCreatCreateNetSilkForm"), "original form generator missing");
        require(updated.contains("ret = car(axlDBCreateText(netname ptPlace myorient layer nil))"), "fixed placement missing");
        require(updated.contains("ASTB_RegisterUndo(\"text_addnetname\" 'ASTB_Text_AddNetName_Undo)"), "astbundo registration missing");
        require(!updated.contains("axlDBAltOrigin('center ret)"), "stale center anchor remains");
        require(!updated.contains("axlTransformObject(ret ?move"), "stale transform placement remains");
        require(!updated.contains("axlEraseObject(ret)"), "stale erase placement remains");
        require(updated.contains("; 版本      : 1.26\n"), "v1.26 header missing");
        writeGbk(IL, updated);
        System.out.println("[ok] FanySkill form + ASTB placement/astbundo v1.26 written");

        String helpText = new String(Files.readAllBytes(HELP), GBK);
        String prefix = "ASTB_Text_AddNetName|";
        int lineStart = helpText.indexOf(prefix);
        require(lineStart >= 0, "help map ASTB_Text_AddNetName line not found");
        int lineEnd = helpText.indexOf('\n', lineStart);
        if (lineEnd < 0) lineEnd = helpText.length();
        String newLine = "ASTB_Text_AddNetName|在版图上添加网络名称文本（点哪个对象就放哪个网名）|①命令弹出选项小表单（层固定丝印顶，可设镜像/角度/字块/对齐）②点选管脚/过孔/铜皮/线段 ③网络名预览框随光标移动，点击后按当前 Text Just 创建 ④可连续放多个，右键 Done 提交/Cancel 回滚/Oops 单步撤销；Done 后可用 astbundo 撤销整批|FanySkill 原版 Ministatus 表单 + ASTB 修正放置（预览后现场 axlDBCreateText，不用中心锚点 transform）；批次（层/放置点/文本）入 _TANN_placedBatches（modules/text/text_addnetname.il）";
        if (!helpText.substring(lineStart, lineEnd).equals(newLine)) {
            helpText = helpText.substring(0, lineStart) + newLine + helpText.substring(lineEnd);
            writeGbk(HELP, helpText);
            System.out.println("[ok] help map updated for hybrid placement");
        } else {
            System.out.println("[skip] help map already updated");
        }
    }
}
