;   2026-08-20 v1.10 ASTB Team 撤销命令注册补 ?undo nil（防系统撤销把
;                   撤销命令本身入栈，17.4+）
;========================================================================
;   2026-08-24 v1.11 ASTB 修复移动放置后文本不可见: axlTransformObject 不会
;                   重画被 axlEraseObject 擦除的对象(17.4 实锤 axlDrawObject 返回 t),
;                   变换成功后必须 axlDrawObject 显式重画; 失败/放弃放置时在
;                   拾取点恢复显示并命令行告警, 不再攒"隐形文本"
;   2026-08-29 v1.12 ASTB 修复 axlDrawObject 警告: 文本 dbid 在
;                   axlTransformObject 失败/用户取消后可能已失效
;                   (dbid:removed), 三处 axlDrawObject 调用前统一
;                   用 errset 捕获并检查返回值, 失败仅告警不中断
;========================================================================
; 文件名    : text_addnetname.il
; 作者      : FYNN（原作）；ASTB（工具箱集成整改）
; 创建日期  : [未知]
; 版本      : 1.11
; 功能描述  : 在指定位置添加网络名称文本，支持交互式拾取管脚/过孔/图形并拖动放置
; 依赖模块  : core（ASTB_RegisterCommand）
; 修改记录  :
;   [原始日期] v1.0 FYNN 初始创建（原中文注释已不可逆损毁，按代码语义重写）
;   2026-07-16 v1.1 ASTB 添加规范文件头
;   2026-07-18 v1.2 ASTB 整改：重写简体中文注释；全局变量加 boundp 保护；
;             临时 form 改写临时目录；axlDBCreateText 失败判空；
;             ?cmdType 改字符串；文件转 GBK 编码
;   2026-07-18 v1.3 ASTB 界面汉化：表单标题/标签/弹窗及放置提示译为中文
;   2026-07-19 v1.4 ASTB 修复: axlDBAltOrigin('center) 对文本返回 nil 导致移动失败,
;             改用文本自身原点 ret->xy, 并替换未文档化的 axlMXYSub
;   2026-07-19 v1.5 ASTB 修复: 实机 ret->xy 返回 nil 致 difference 报错,
;             文本创建点即为原点, 改为直接取入参 pt, 不再回读 ret->xy
;   2026-07-19 v1.6 ASTB 修复: 实机右键 Done/Cancel/Oops 退不出命令——
;             interactive 内建菜单默认 finish/cancelEnterFun 不设退出
;             标志, 注册补 ?doneCmd/?cancelCmd(框架同步支持), ?undo 改 nil;
;             事务提交/回滚包 errset; axlEnterPoint 返回加 listp 防御
;   2026-07-19 v1.7 ASTB 修复: 右键完成报 Invalid character——GBK 中文
;             popup 标签触发 Allegro reader 错误, 标签改英文 Done/Oops/
;             Cancel(对齐 place_align 实证模式, symbol 回调不变)
;   2026-08-20 v1.8 ASTB 新增: Done 完成后可撤销——批次栈
;             _TANN_placedBatches 记录定位信息(层+放置点+文本内容,
;             不存 dbid, 跨命令失效), 新增撤销命令 ASTB_Text_AddNetNameu
;             现场查找新鲜 dbid 并逐批删除; Done 打印撤销提示;
;             Cancel 清空当批记录(对齐 rvia v1.9/achu v4.0 实证模式)
;   2026-08-20 v1.9 ASTB 接入统一撤销中枢 astbundo（core/trans.il
;             v1.4）：ASTB_RegisterUndo 注册 ASTB_Text_AddNetName_Undo，
;             批次入栈同步 ASTB_UndoJournalPush；Done 提示改指 astbundo
;             （ASTB_Text_AddNetNameu 保留为别名）
;========================================================================

;; ============================================================
;; File: text_addnetname.il
;; Purpose: Add net name
;; Encoding: GBK
;; ============================================================

;;---------------------------------------------------------
;; 原文件名: create_net_silk.il
;; 作者    : FYNN
;; 功能    : 拾取对象所属网络，生成网络名丝印文本并交互放置
;; 版本    : v1.0
;;---------------------------------------------------------

;--- 全局变量保护（命令句柄/表单句柄/事务标记/放置状态） ---
unless(boundp('_dbCreateNetSilkFinish) _dbCreateNetSilkFinish = nil)
unless(boundp('fm_crtn)                fm_crtn = nil)
unless(boundp('mk_crtn)                mk_crtn = nil)
unless(boundp('_dbCreateNetSilkStage)  _dbCreateNetSilkStage = nil)
unless(boundp('_dbCreateNetSilkBatch)  _dbCreateNetSilkBatch = nil)    ;--- v1.8: 当次会话放置记录 ---
unless(boundp('_TANN_placedBatches)    _TANN_placedBatches = nil)      ;--- v1.8: Done 撤销批次栈 ---

;------------------------------------------------------------------------
; 函数名  : ASTB_Text_AddNetName
; 功能    : 命令入口：生成选项表单，进入拾取-放置循环
; 副作用  : 修改数据库（全程事务包裹，Done 提交 / Cancel 回滚 / Oops 单步撤销）
;------------------------------------------------------------------------
procedure( ASTB_Text_AddNetName()
(let (addr)
    _dbCreateNetSilkFinish = nil
    _dbCreateNetSilkBatch = nil    ;--- v1.8: 清空本次会话放置记录(供 Done 后撤销) ---

    ;--- 在临时目录动态生成 FORM 文件 ---
    addr = strcat(axlTempFile() ".form")
    _dbCreatCreateNetSilkForm(addr)
    fm_crtn = axlMiniStatusLoad((gensym) addr `_dbCreateNetSilkCallback t)
    when(isFile(addr) errset(deleteFile(addr)))

    axlSetActiveLayer("BOARD GEOMETRY/SILKSCREEN_TOP")
    axlFormSetField(fm_crtn "mirror" nil)
    axlFormSetField(fm_crtn "angle" "0")
    axlFormSetField(fm_crtn "text_block" "2")
    axlFormSetField(fm_crtn "text_justification" "left")

    ;--- v1.7: popup 标签改英文(GBK 中文标签触发 reader "Invalid character") ---
    axlUIPopupSet(axlUIPopupDefine(nil
            (list
                (list "Done"   '_dbCreateNetSilkDone)
                (list "Oops"   '_dbCreateNetSilkOops)
                (list "Cancel" '_dbCreateNetSilkCancel)
            )))
    axlControlRaise('options)    ;--- 弹出 options 选项面板 ---
    axlClearSelSet()
    axlSetFindFilter(?enabled `("NOALL" "PINS" "VIAS" "SHAPES" "CLINESEGS") ?onButtons `("PINS" "VIAS" "SHAPES" "CLINESEGS"))
    mk_crtn = axlDBTransactionStart()
    while( !_dbCreateNetSilkFinish
        when(axlSingleSelectPoint()
            axlDBTransactionMark(mk_crtn)
            _dbCreateNetSilk(axlLastPick(nil) axlGetSelSet())
        )
    )
    axlUIPopupSet(nil)
))

;------------------------------------------------------------------------
; 函数名  : _dbCreateNetSilk
; 功能    : 对拾取到的对象取其网络名，按表单参数创建文本并让用户拖动放置
; 参数    : pt - 拾取点；item - 选择集
;------------------------------------------------------------------------
procedure(_dbCreateNetSilk(pt item)
(let (id layer mir ang blk jst myorient ret ptStrOri ptPlace )

    axlClearSelSet()
    id = car(item)
    layer = axlGetActiveLayer()
    mir = case(axlFormGetField(fm_crtn "mirror")  ("1" t) ("0" nil))
    ang = atof(axlFormGetField(fm_crtn "angle"))
    blk = axlFormGetField(fm_crtn "text_block")
    jst = axlFormGetField(fm_crtn "text_justification")
    myorient = make_axlTextOrientation(?textBlock blk ?rotation ang ?mirrored mir ?justify jst)
    if(id->net->name != "" && id->net->name != nil then
        ret = car(axlDBCreateText(id->net->name pt myorient layer nil))
        if( ret then
            axlVisibleLayer(layer t)    ;--- 确保目标层可见 ---
            axlVisibleUpdate(nil)       ;--- 刷新显示 ---

            axlEraseObject(ret)    ;--- 将静态文本转入动态拖拽状态 ---
            ptStrOri = pt    ;--- v1.5 fix: 文本原点取 pt(实锤 ret->xy 为 nil) ---
            axlDynamicsObject(ret ptStrOri)    ;--- 文本随鼠标动态拖拽 ---
            _dbCreateNetSilkStage = nil
            ptPlace = axlEnterPoint(?prompts `("\307\353\265\343\273\367\321\241\324\361\316\304\261\276\267\305\326\303\265\343"))    ;--- 等待用户点击放置点 ---
            if( listp(ptPlace) then
                if( axlTransformObject(ret ?move
                        list(car(ptPlace) - car(ptStrOri)
                             cadr(ptPlace) - cadr(ptStrOri))) then    ;--- 将文本移动到放置点 ---
                    ;--- v1.11: 被擦除对象变换后 Allegro 不重画, 必须显式重画否则文本隐形(17.4 实锤) ---
                    ;--- v1.12: 检查 dbid 有效性, 防 axlDrawObject 警告 ---
                    if( errset(axlDrawObject(ret) t) then
                        _dbCreateNetSilkStage = t
                    else
                        axlUIWPrint(nil "警告: 文本对象已失效, 无法重画")
                    )
                    ;--- v1.8: 记录放置信息(层+放置点+文本内容), Done 后提示 ---
                    ;--- 不存 dbid: 事务会失效, dbid:removed(参照 rvia v1.9 实锤) ---
                    _dbCreateNetSilkBatch = cons(list(layer ptPlace id->net->name) _dbCreateNetSilkBatch)
                else
                    ;--- v1.11: 移动失败(目标点非法), 在拾取点恢复显示并命令行告警 ---
                    ;--- v1.12: 检查 dbid 有效性, 防 axlDrawObject 警告 ---
                    if( null(errset(axlDrawObject(ret) t)) then
                        axlUIWPrint(nil "警告: 文本对象已失效, 无法恢复显示")
                    )
                    axlUIWPrint(nil sprintf(nil "\276\257\270\346: \267\305\326\303\265\343 %L \267\307\267\250, \316\304\261\276\261\243\301\364\324\332\312\260\310\241\265\343" ptPlace))
                )
            else
                ;--- v1.11: 未放置(右键取消等), 对象若仍在库则恢复显示 ---
                ;--- v1.12: 检查 dbid 有效性, 防 axlDrawObject 警告 ---
                if( null(errset(axlDrawObject(ret) t)) then
                    axlUIWPrint(nil "警告: 文本对象已失效, 无法恢复显示")
                )
            )
            axlClearDynamics()    ;--- 清除动态显示 ---
            axlUIWRedraw(nil)
        else
            printf("\264\264\275\250\315\370\302\347\303\373\316\304\261\276\312\247\260\334\243\241\n")
        )
    else
        printf("\315\370\302\347\303\373\316\252\277\325\243\241\n")
    )
))


;------------------------------------------------------------------------
; 函数名  : _dbCreateNetSilkCallback
; 功能    : 表单字段回调（当前仅占位，无实际处理）
;------------------------------------------------------------------------
(defun _dbCreateNetSilkCallback (fm_crtn)
(prog ()
    case(fm_crtn->curField
        ("subclass"
            t
        )
    )
    return()
))


;------------------------------------------------------------------------
; 函数名  : _dbCreatCreateNetSilkForm
; 功能    : 动态生成表单定义文件（层选择/镜像/角度/字高/对齐方式）
; 参数    : addr - 表单文件输出路径
;------------------------------------------------------------------------
defun(_dbCreatCreateNetSilkForm (addr)
(let (file)
    file = outfile(addr)
    unless( file
        axlUIConfirm(strcat("\316\336\267\250\264\264\275\250\301\331\312\261\261\355\265\245\316\304\274\376: " addr))
        return(nil)
    )

    fprintf(file "FILE_TYPE=FORM_DEFN VERSION=2\n")
    fprintf(file "FORM AUTOGREYTEXT\n")
    fprintf(file "FIXED\n")
    fprintf(file "PORT 55 20\n")            ;--- 表单窗口尺寸 ---
    fprintf(file "HEADER \"\314\355\274\323\315\370\302\347\303\373\"\n")
    fprintf(file "\n")

    fprintf(file "POPUP <rotate>\"0\"\"0.000\",\"45\"\"45.000\",\"90\"\"90.000\",\"135\"\"135.000\",
\"180\"\"180.000\",\"225\"\"225.000\",\"270\"\"270.000\",\"315\"\"315.000\".\n")
    fprintf(file "POPUP <justification>\"\327\363\"\"left\",\"\323\322\"\"right\",\"\276\323\326\320\"\"center\".\n")

    fprintf(file "TILE\n")
    fprintf(file "\n")

    fprintf(file "TEXT \"\273\356\266\257\300\340\272\315\327\323\300\340\243\272\"\n")
    fprintf(file "TLOC 1 1\n")
    fprintf(file "ENDTEXT\n")

    fprintf(file "FIELD class\n")
    fprintf(file "FLOC 5 3\n")
    fprintf(file "ENUMSET 19\n")
    fprintf(file "OPTIONS prettyprint\n")
    fprintf(file "POP \"class\"\n")
    fprintf(file "ENDFIELD\n")

    fprintf(file "FIELD subcolor\n")
    fprintf(file "FLOC 2 6\n")
    fprintf(file "COLOR 2 1\n")
    fprintf(file "OPTIONS colorchooser\n")
    fprintf(file "ENDFIELD\n")

    fprintf(file "FIELD subclass\n")
    fprintf(file "FLOC 5 6\n")
    fprintf(file "ENUMSET 19\n")
    fprintf(file "OPTIONS prettyprint ownerdrawn\n")
    fprintf(file "POP \"subclass\"\n")
    fprintf(file "ENDFIELD\n")

    fprintf(file "FIELD mirror\n")
    fprintf(file "FLOC 2 9\n")
    fprintf(file "CHECKLIST \"\276\265\317\361\"\n")
    fprintf(file "ENDFIELD\n")

    /* fprintf(file "TEXT \"Marker size:\"\n")
    fprintf(file "TLOC 5 11\n")
    fprintf(file "ENDTEXT\n")

    fprintf(file "FIELD text_marker_size\n")
    fprintf(file "FLOC 18 11\n")
    fprintf(file "REALFILLIN 9 9\n")
    fprintf(file "DECIMAL 5\n")
    fprintf(file "ENDFIELD\n") */

    fprintf(file "TEXT \"\320\375\327\252\243\272\"\n")
    fprintf(file "TLOC 5 11\n")
    fprintf(file "ENDTEXT\n")

    fprintf(file "FIELD angle\n")
    fprintf(file "FLOC 18 11\n")
    fprintf(file "REALFILLIN 6 7\n")
    fprintf(file "POP \"rotate\"\n")
    fprintf(file "DECIMAL 3\n")
    fprintf(file "ENDFIELD\n")

    fprintf(file "TEXT \"\316\304\261\276\277\351\243\272\"\n")
    fprintf(file "TLOC 5 13\n")
    fprintf(file "ENDTEXT\n")

    fprintf(file "FIELD text_block\n")
    fprintf(file "FLOC 18 13\n")
    fprintf(file "INTSLIDEBAR 7 7\n")
    fprintf(file "MIN 1\n")
    fprintf(file "MAX 64\n")
    fprintf(file "ENDFIELD\n")

/*     fprintf(file "TEXT \"Text name:\"\n")
    fprintf(file "TLOC 5 17\n")
    fprintf(file "ENDTEXT\n")

    fprintf(file "FIELD text_name\n")
    fprintf(file "FLOC 18 17\n")
    fprintf(file "STRFILLIN 6 14\n")
    fprintf(file "POP \"text_names\"\n")
    fprintf(file "ENDFIELD\n") */

    fprintf(file "TEXT \"\266\324\306\353\267\275\312\275\243\272\"\n")
    fprintf(file "TLOC 5 15\n")
    fprintf(file "ENDTEXT\n")

    fprintf(file "FIELD text_justification\n")
    fprintf(file "FLOC 18 15\n")
    fprintf(file "ENUMSET 8\n")
    fprintf(file "POP \"justification\"\n")
    fprintf(file "ENDFIELD \n")

    fprintf(file "\n")

    fprintf(file "ENDTILE\n")
    fprintf(file "\n")

    fprintf(file "ENDFORM\n")

    close(file)
))

;------------------------------------------------------------------------
; 函数名  : _dbCreateNetSilkDone
; 功能    : Done：提交事务并结束命令；当批放置记录压入撤销栈(v1.8)
;------------------------------------------------------------------------
procedure( _dbCreateNetSilkDone()
    _dbCreateNetSilkFinish = t
    errset(axlDBTransactionCommit(mk_crtn) t)
    ;--- v1.8: 当批记录压栈(多次 Done 形成多批, ASTB_Text_AddNetNameu 逐批撤销) ---
    when( _dbCreateNetSilkBatch
        _TANN_placedBatches = cons(reverse(_dbCreateNetSilkBatch) _TANN_placedBatches)
        _dbCreateNetSilkBatch = nil
        ASTB_UndoJournalPush("text_addnetname")
        printf("\315\352\263\311\241\243\312\344\310\353 astbundo \277\311\263\267\317\372\261\276\264\316\320\336\270\304\n")
    )
    axlFinishEnterFun()
)

;------------------------------------------------------------------------
; 函数名  : _dbCreateNetSilkCancel
; 功能    : Cancel：回滚事务并取消命令；丢弃当批撤销记录(v1.8)
;------------------------------------------------------------------------
procedure( _dbCreateNetSilkCancel()
    _dbCreateNetSilkFinish = t
    errset(axlDBTransactionRollback(mk_crtn) t)
    _dbCreateNetSilkBatch = nil    ;--- v1.8: 已回滚, 当批记录作废 ---
    axlCancelEnterFun()
)

;------------------------------------------------------------------------
; 函数名  : _dbCreateNetSilkOops
; 功能    : Oops：撤销上一次放置（未放置时先取消动态拖动）
;------------------------------------------------------------------------
procedure( _dbCreateNetSilkOops()
    when(!_dbCreateNetSilkStage
        axlClearDynamics()    ;--- 清除动态显示 ---
        axlCancelEnterFun()
    )
    axlDBTransactionOops(mk_crtn)
)

;------------------------------------------------------------------------
; 函数名  : ASTB_Text_AddNetName_Undo
; 功能    : 撤销最近一次 Done 放置的那批网络名文本(命令
;           ASTB_Text_AddNetNameu)：按批次记录的 层+放置点+文本内容
;           现场查找文本并删除
; 备注    : 本机 Ctrl+Z 不覆盖 AXL 创建的对象, 撤销由模块自维护;
;           批次栈只存定位信息不存 dbid(跨命令失效成 dbid:removed),
;           选择集返回新鲜 dbid(对齐 rvia v1.9/achu v4.0 实证模式);
;           找不到视为已被手动删除/Oops 回滚, 不报错
;------------------------------------------------------------------------
procedure( ASTB_Text_AddNetName_Undo()
(prog (batch rec lay pt txt hit obj n m rr)
    unless( _TANN_placedBatches
        axlUIWPrint(nil "\303\273\323\320\277\311\263\267\317\372\265\304\274\307\302\274")
        return(nil)
    )
    batch = car(_TANN_placedBatches)
    _TANN_placedBatches = cdr(_TANN_placedBatches)
    axlSetFindFilter(?enabled `("noall" "text") ?onButtons `("noall" "text"))
    n = 0
    m = 0
    foreach( rec batch
        lay = car(rec)
        pt  = cadr(rec)
        txt = caddr(rec)
        ;--- 目标层必须可见才可被选中 ---
        errset(axlVisibleLayer(lay t) t)
        axlVisibleUpdate(nil)
        axlClearSelSet()
        hit = nil
        when( axlSingleSelectPoint(pt)
            foreach( obj axlGetSelSet()
                when( and(null(hit)
                          equal(obj->layer lay)
                          equal(obj->text txt)
                          abs(car(obj->xy) - car(pt)) < 0.01
                          abs(cadr(obj->xy) - cadr(pt)) < 0.01)
                    hit = obj
                )
            )
        )
        if( hit then
            rr = errset( axlDeleteObject(hit) t )
            if( and(rr car(rr)) then
                n = n + 1
            else
                m = m + 1
                axlUIWPrint(nil "  \276\257\270\346: %L \264\246\316\304\261\276(%s)\311\276\263\375\312\247\260\334" pt txt)
            )
        else
            ;--- 文本已不在(可能已被手动删除或 Oops 回滚), 视为已达删除目标 ---
            axlUIWPrint(nil "  \314\341\312\276: %L \264\246\316\264\325\322\265\275\316\304\261\276(%s), \277\311\304\334\322\321\261\273\311\276\263\375" pt txt)
        )
    )
    axlClearSelSet()
    axlFlushDisplay()
    axlUIWPrint(nil "\263\267\317\372\315\352\263\311: \311\276\263\375 %d \270\366\315\370\302\347\303\373\316\304\261\276, %d \270\366\312\247\260\334(\312\243\323\340\277\311\263\267\317\372 %d \305\372)"
        n m length(_TANN_placedBatches))
    return(t)
))

ASTB_RegisterCommand("ASTB_Text_AddNetName" "ASTB_Text_AddNetName"
    ?cmdType "interactive" ?undo nil
    ?doneCmd '_dbCreateNetSilkDone ?cancelCmd '_dbCreateNetSilkCancel)

;--- v1.8: Done 后撤销命令(模块自维护批次栈; general 类型, 不加 ?undo) ---
ASTB_RegisterCommand("ASTB_Text_AddNetNameu" "ASTB_Text_AddNetName_Undo"
    ?cmdType "general" ?undo nil)
; 统一撤销中枢注册（core/trans.il v1.4）：astbundo 按 LIFO 分发到本函数
ASTB_RegisterUndo("text_addnetname" 'ASTB_Text_AddNetName_Undo)

printf("[ASTB] text_addnetname.il loaded.\n")
