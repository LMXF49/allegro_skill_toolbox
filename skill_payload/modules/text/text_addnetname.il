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
;   2026-08-29 v1.13 ASTB 根治 axlDrawObject *WARNING*: v1.12 的
;                   errset 挡不住 WARNING(Allegro 内部打印非异常),
;                   改调用前用 errset(ret->xy) 探测 dbid 有效性,
;                   失效则跳过调用, 不再产生 WARNING
;   2026-08-29 v1.14 ASTB 修复放置失败: axlDynamicsObject 后对象被
;                   动态引用锁定, axlTransformObject 前必须先
;                   axlClearDynamics() 清除引用, 否则移动返回 nil
;   2026-08-29 v1.15 ASTB 修复单击放置失败: axlTransformObject 要求
;                   对象在选择集里才生效(refdescenter v2.4 实锤),
;                   移动前 axlSetSelSet 选中、移动后 axlClearSelSet
;   2026-08-29 v1.16 ASTB 回归原版逻辑: 位移基准用 axlDBAltOrigin
;                   ('center ret) 文本中心点(非创建点 pt), 位移量用
;                   axlMXYSub 计算; 去掉 v1.14/v1.15 加的
;                   axlClearDynamics 前置和 axlSetSelSet(原版无此
;                   要求, 加后反而破坏动态拖拽状态)
;   2026-08-29 v1.17 ASTB 修复 axlMXYSub nil 报错: axlDBAltOrigin 对
;                   erased 对象返回 nil(ret->xy 为 nil 导致), 改用
;                   ret->bBox 中心作为位移基准
;   2026-08-29 v1.18 ASTB 根治放置失败: 17.4 对 erased 对象
;                   axlTransformObject 返回 nil, 弃用 erase+transform
;                   流程, 改动态拖拽后删除旧文本、在目标点重建新文本
;   2026-08-29 v1.19 ASTB 回归官方示例: 不 erase 文本, 直接
;                   dynamics + transform; dynamics 锚点用 bBox 左下角
;                   (car(bBox), 官方 dyntest.il 用法), 非中心点
;   2026-08-29 v1.20 ASTB 按用户要求 erase 文本, 但 ptStrOri 必须在
;                   erase 前从 bBox 取好(erased 后 bBox 返回 nil 导致
;                   axlMXYSub 报错)
;   2026-08-29 v1.21 ASTB 修复 transform 失败: axlClearDynamics 提前
;                   到 transform 之前会清除 dynamics 引用导致 ret 失效,
;                   按原版顺序放回 transform 之后
;   2026-09-09 v1.22 ASTB 修复 17.4 S039 跨轮 dbid 失效: axlEnterPoint
;                   后 ret/id 全部失效(dbid:removed), 弃用预创建文本+
;                   erase+transform 旧流程; 进 enter 前把网络名提取成纯
;                   数据, 预览改 axlPathStart+axlAddSimpleMoveDynamics
;                   矩形框(place_gathercomps v1.7 实证), 拿到放置点后
;                   现场 axlDBCreateText 新建文本(全新 dbid 当轮存活);
;                   撤销栈仍只存(层 放置点 文本内容)纯数据, 兼容既有 undo
;========================================================================
; 文件名    : text_addnetname.il
; 作者      : FYNN（原作）；ASTB（工具箱集成整改）
; 创建日期  : [未知]
; 版本      : 1.22
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
;------------------------------------------------------------------------
; 函数    : _NNDbidValid
; 功能    : 判断 dbid 是否仍然有效(未被删除)。失效 dbid 访问属性会抛
;           *Error*, errset 捕获返回 nil; 有效则返回 t。v1.13 新增。
;------------------------------------------------------------------------
procedure( _NNDbidValid(d)
    and( d errset(d->xy t) )
)

;------------------------------------------------------------------------
; 函数    : _NNTextBlockHeight
; 功能    : 取指定 text block 的高度(供放置预览矩形估算大小); 取不到
;           返回 25。v1.22 新增(照 text_refdescenter _RC_TextBlockHeight
;           实证写法, axlGetParam 包 errset)
; 参数    : blk - block 号字符串(表单 "text_block" 字段值)
;------------------------------------------------------------------------
procedure( _NNTextBlockHeight(blk)
(let (param h)
    param = errset(axlGetParam(sprintf(nil "paramTextBlock:%s" blk)) t)
    h = if( param && car(param) then car(param)->height else 25.0 )
    if( h && h > 0.0 then h else 25.0 )
))
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
(let (id layer mir ang blk jst myorient netname theight twidth rect outline ptPlace ret )

    axlClearSelSet()
    id = car(item)
    layer = axlGetActiveLayer()
    mir = case(axlFormGetField(fm_crtn "mirror")  ("1" t) ("0" nil))
    ang = atof(axlFormGetField(fm_crtn "angle"))
    blk = axlFormGetField(fm_crtn "text_block")
    jst = axlFormGetField(fm_crtn "text_justification")
    myorient = make_axlTextOrientation(?textBlock blk ?rotation ang ?mirrored mir ?justify jst)

    ;--- v1.22: 17.4 S039 跨轮 dbid 失效——网络名在进 axlEnterPoint 前提取
    ;    成纯数据(字符串); id 只在 axlSingleSelectPoint 当轮读取, enter 之后
    ;    绝不再访问任何旧 dbid ---
    netname = id->net->name
    if( netname != "" && netname != nil then
        axlVisibleLayer(layer t)    ;--- 确保目标层可见 ---
        axlVisibleUpdate(nil)       ;--- 刷新显示 ---

        ;--- v1.22: 预览只用矩形框(axlPathStart+axlAddSimpleMoveDynamics,
        ;    place_gathercomps v1.7 outline 实证模式), 不预创建文本再 erase;
        ;    尺寸按 text block 高度 x 字符数估算, 仅示意大小, 失败仅无预览 ---
        theight = _NNTextBlockHeight(blk)
        twidth = theight * strlen(netname) * 0.6
        if( twidth < theight then twidth = theight )
        rect = list(0:0 twidth:0 twidth:theight 0:theight 0:0)
        outline = errset(axlPathStart(rect) t)
        when( and(outline car(outline))
            errset(axlAddSimpleMoveDynamics(0:0 car(outline) "path" ?ref_point 0:0) nil)
        )
        _dbCreateNetSilkStage = nil
        ptPlace = axlEnterPoint(?prompts `("\307\353\265\343\273\367\321\241\324\361\316\304\261\276\267\305\326\303\265\343"))    ;--- 等待用户点击放置点 ---
        axlClearDynamics()    ;--- 放置点已定(或已取消), 清除矩形框预览 ---
        if( listp(ptPlace) then
            ;--- v1.22: 拿到放置点后现场新建文本(全新 dbid 当轮存活),
            ;    放弃对旧 dbid 的任何操作 ---
            ret = car(axlDBCreateText(netname ptPlace myorient layer nil))
            if( ret then
                _dbCreateNetSilkStage = t
                _dbCreateNetSilkBatch = cons(list(layer ptPlace netname) _dbCreateNetSilkBatch)
            else
                printf("\264\264\275\250\315\370\302\347\303\373\316\304\261\276\312\247\260\334\243\241\n")
            )
        )
        axlUIWRedraw(nil)
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

    fprintf(file "POPUP <rotate>\"0\"\"0.000\",\"45\"\"45.000\",\"90\"\"90.000\",\"135\"\"135.000\",\n\"180\"\"180.000\",\"225\"\"225.000\",\"270\"\"270.000\",\"315\"\"315.000\".\n")
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
