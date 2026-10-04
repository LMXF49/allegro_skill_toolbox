;   2026-08-20 v1.5 ASTB Team 撤销命令注册补 ?undo nil（防系统撤销把
;                   撤销命令本身入栈，17.4+）
;========================================================================
; 文件名    : route_linetoshape.il
; 作者      : Allegro SKILL Toolbox
; 创建日期  : 2026-07-16
; 版本      : 1.5
; 功能描述  : 将走线(cline/line)转换为同层 shape，原走线被删除；
;             交互弹窗支持 Done 提交 / Undo 分批撤销 / Cancel 全部回滚；
;             Done 提交后可用撤销命令 ASTB_Route_LineToShapeu 逐批撤销
; 依赖模块  : core/menu.il, core/utils.il
; 修改记录  :
;   2026-07-16 v1.0 Allegro SKILL Toolbox 初始创建（改编自 Cadence cline2shape.il）
;   2026-07-16 v1.1 Allegro SKILL Toolbox 修复三处改编回退：
;                   1) 恢复转换后删除原走线 axlDeleteObject（原被注释，shape/cline 重叠）
;                   2) 恢复 Cancel 分支事务回滚，删除循环外重复 Commit（Cancel 不再变提交）
;                   3) layer 改回逐条取 clinedbid->layer（多选跨层时不再建错层）
;                   另：补全 let 绑定，入口加 axlOKToProceed 检查
;   2026-08-20 v1.2 Allegro SKILL Toolbox 新增 Done 后可撤销（pitfalls 2.6：
;                   本机 Ctrl+Z 不覆盖 AXL 建/删对象，撤销模块自维护）：
;                   a) 转换时逐条记录定位信息（类型/层/网络/线宽/路径点/
;                      新 shape 的 bBox，绝不存 dbid——跨命令失效成
;                      dbid:removed）压入 _RLTS_pending，Done 时整批压入
;                      _RLTS_undoStack；
;                   b) 新增撤销命令 ASTB_Route_LineToShapeu（RLTS_Undo）：
;                      按路径点现场查找 shape（层+bBox 匹配）删除，再按
;                      记录重建原走线（cline 显式挂网络 / line 无网络）；
;                   c) 弹窗内 Undo(Oops) 成功时同步修剪 _RLTS_pending，
;                      Cancel 回滚时清空，保证 Done 批次与库内实际转换一致
;   2026-08-20 v1.3 Allegro SKILL Toolbox 接入统一撤销中枢 astbundo
;                   （core/trans.il v1.4）：ASTB_RegisterUndo 注册
;                   RLTS_Undo，批次入栈同步 ASTB_UndoJournalPush；Done
;                   提示改指 astbundo（ASTB_Route_LineToShapeu 保留为别名）
;   2026-08-20 v1.4 ASTB Team 撤销线宽未恢复修复：挂网络建 cline 时
;                   约束管理器覆盖线宽——重建后 axlChangeWidth 显式压回
;                   记录的原宽；记录端 ->width 直读失败退到首段线宽
;========================================================================

;------------------------------------------------------------------------
; 弹窗回调跨函数共享变量（有意全局，加载期保护初始化）
;   LCB_mark/LCBpopup/notdone  弹窗事务与循环控制（沿用上游命名）
;   _RLTS_undoStack   Done 批次栈：每批为记录列表（定位信息，无 dbid）
;   _RLTS_pending     本次运行待提交记录（最新在前）
;   _RLTS_pendingSegs 每个选择批次的记录数栈（弹窗 Undo 修剪用）
;------------------------------------------------------------------------
unless( boundp('LCB_mark)
    LCB_mark = nil
)
unless( boundp('LCBpopup)
    LCBpopup = nil
)
unless( boundp('notdone)
    notdone = nil
)
unless( boundp('_RLTS_undoStack)
    _RLTS_undoStack = nil
)
unless( boundp('_RLTS_pending)
    _RLTS_pending = nil
)
unless( boundp('_RLTS_pendingSegs)
    _RLTS_pendingSegs = nil
)

;------------------------------------------------------------------------
; 函数名  : RLTS_FirstDbid
; 功能    : 从 axlDBCreate* 返回值取首个新建对象 dbid，兼容三种返回
;           形态：裸 dbid / (dbid ...) / ((dbid ...) drc)；失败返回 nil
;------------------------------------------------------------------------
procedure( RLTS_FirstDbid(ret)
    cond(
        ( null(ret) nil )
        ( listp(ret)
            if( listp(car(ret)) then caar(ret) else car(ret) )
        )
        ( t ret )
    )
)

;------------------------------------------------------------------------
; 函数名  : RLTS_BBoxEq / RLTS_BBoxIn
; 功能    : bBox 近似相等（容差 0.01，防尾数抖动）与成员判断；撤销时
;           按 bBox 匹配转换生成的 shape，避免误删同层既有 shape
;------------------------------------------------------------------------
procedure( RLTS_BBoxEq(bb1 bb2)
    prog( (tol)
        tol = 0.01
        return( and( bb1 bb2
            abs(caar(bb1)   - caar(bb2))   < tol
            abs(cadar(bb1)  - cadar(bb2))  < tol
            abs(caadr(bb1)  - caadr(bb2))  < tol
            abs(cadadr(bb1) - cadadr(bb2)) < tol
        ))
    )
)

procedure( RLTS_BBoxIn(bb bbList)
    prog( (hit b)
        hit = nil
        foreach( b bbList
            when( RLTS_BBoxEq(bb b)
                hit = t
            )
        )
        return(hit)
    )
)

;------------------------------------------------------------------------
; 函数名  : RLTS_ConvertOne
; 功能    : 转换单条走线：删除前先采集重建所需定位信息（类型/层/网络名/
;           线宽/路径点/是否含弧），删除原走线并创建同层 shape，创建后
;           立即记录新 shape 的 bBox（dbid 仅本命令内新鲜可读），整条
;           记录压入 _RLTS_pending，供 Done 成批入栈 / RLTS_Undo 撤销
; 参数    : clinedbid - 原走线 dbid（本命令内新鲜有效）
;           layer     - 所在层；polydbid - axlPolyFromDB 返回的多边形列表
; 返回值  : t - 已处理（即使 shape 创建失败，原走线已删也须记录在案）
;------------------------------------------------------------------------
procedure( RLTS_ConvertOne(clinedbid layer polydbid)
    prog( (objType er netName width pts segs seg se hasArc bBoxes sres sdb)
        ; ---- 删除前采集定位/重建信息（绝不存 dbid：跨命令失效）----
        objType = clinedbid->objType
        er = errset( clinedbid->net->name nil )
        netName = and(er car(er))
        er = errset( clinedbid->width nil )
        width = and(er car(er))
        pts = nil
        hasArc = nil
        er = errset( clinedbid->segments nil )
        segs = and(er car(er))
        ;; 直读 ->width 失败时退到首段线宽（cline/lineseg 属性差异兜底）
        unless( width
            when( and(segs car(segs))
                er = errset( car(segs)->width nil )
                width = and(er car(er))
            )
        )
        if( segs then
            foreach( seg segs
                er = errset( seg->startEnd nil )
                se = and(er car(er))
                when( and(se car(se) cadr(se))
                    if( pts then
                        pts = append1(pts cadr(se))
                    else
                        pts = list(car(se) cadr(se))
                    )
                )
                er = errset( seg->isArc nil )
                when( and(er car(er))
                    hasArc = t
                )
            )
        else
            ; 无 segments 属性时退化为单段：直接取 startEnd
            er = errset( clinedbid->startEnd nil )
            se = and(er car(er))
            when( and(se car(se) cadr(se))
                pts = list(car(se) cadr(se))
            )
        )
        unless( and(pts cdr(pts))
            axlUIWPrint(nil "** Warning. 层 %s 走线路径点采集失败，撤销时将无法重建。 **" layer)
        )
        axlDeleteObject(clinedbid)
        ; ---- 创建同层 shape 并立即记录 bBox（新鲜 dbid 仅此刻可读）----
        bBoxes = nil
        sres = axlDBCreateShape(car(polydbid) t layer)
        if( !sres then
            axlUIWPrint(nil "** Error. Failed to create Shape from Cline. **")
        else
            sdb = RLTS_FirstDbid(sres)
            er = errset( sdb->bBox nil )
            if( and(er car(er)) then
                bBoxes = cons(car(er) bBoxes)
            else
                axlUIWPrint(nil "** Warning. 新 shape bBox 读取失败，撤销时无法定位删除它。 **")
            )
        )
        when( cadr(polydbid)
            sres = axlDBCreateShape(cadr(polydbid) t layer)
            sdb = RLTS_FirstDbid(sres)
            er = errset( sdb->bBox nil )
            when( and(er car(er))
                bBoxes = cons(car(er) bBoxes)
            )
        )
        ; ---- 记录入待提交列表：(类型 层 网络 线宽 路径点 含弧 shape-bBox列表) ----
        _RLTS_pending = cons(list(objType layer netName width pts hasArc reverse(bBoxes))
            _RLTS_pending)
        return(t)
    )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_Route_LineToShape
; 功能    : 交互式将选中的 cline/line 转换为同层 shape（原走线被删除）
; 参数    : 无
; 返回值  : t - 正常结束
; 副作用  : 修改当前设计数据库；事务由弹窗 Done/Cancel 管理；
;           Done 后批次入 _RLTS_undoStack，可用 ASTB_Route_LineToShapeu 撤销
;------------------------------------------------------------------------
procedure( ASTB_Route_LineToShape()
    prog( (lclines layer polydbid nRec)
        unless( axlOKToProceed()
            axlUIConfirm("当前环境不允许执行该操作")
            return(nil)
        )
        axlSetFindFilter(?enabled   list("noall" "clines" "lines")
                         ?onButtons list("noall" "clines" "lines"))
        LCBpopup = axlUIPopupDefine( nil (list
            (list "Done"   'LCB_Done)
            (list "Undo"   'LCB_unDo)
            (list "Cancel" 'LCB_Cancel)
        ))
        axlUIPopupSet(LCBpopup)

        LCB_mark = axlDBTransactionStart()
        notdone  = t
        ; 本次运行待提交记录清零（_RLTS_undoStack 跨命令保留，勿清）
        _RLTS_pending     = nil
        _RLTS_pendingSegs = nil
        while( notdone
            lclines = axlGetSelSet(axlSelect(?prompt "Select Clines to convert to a shape."))
            if( lclines then
                nRec = 0
                foreach( clinedbid lclines
                    ; 逐条取原走线所在层，多选跨层时各自建到正确的层
                    layer = clinedbid->layer
                    polydbid = axlPolyFromDB(clinedbid ?endCapType "ROUND")
                    if( polydbid then
                        RLTS_ConvertOne(clinedbid layer polydbid)
                        nRec = nRec + 1
                    else
                        axlUIWPrint(nil "** Error. Failed to create Polydbid from Cline. **")
                    )
                )
                ; 记录本选择批次的条数，供弹窗 Undo(Oops) 成功时同步修剪
                when( nRec > 0
                    _RLTS_pendingSegs = cons(nRec _RLTS_pendingSegs)
                )
            )
        )
        t
    )
)

;------------------------------------------------------------------------
; 函数名  : LCB_unDo
; 功能    : 弹窗回调：撤销上一批转换（事务内 Oops），并同步修剪
;           _RLTS_pending 中对应记录，防止 Done 批次混入已回滚条目
;------------------------------------------------------------------------
procedure( LCB_unDo()
    let( (n)
        if( !axlDBTransactionOops(LCB_mark) then
            axlUIWPrint(nil "-- Nothing Left To Undo. --")
        else
            axlUIWPrint(nil "-- Replacing Clines. --")
            n = car(_RLTS_pendingSegs)
            when( n
                _RLTS_pendingSegs = cdr(_RLTS_pendingSegs)
                _RLTS_pending = nthcdr(n _RLTS_pending)
            )
        )
        axlClearSelSet()
    )
)

;------------------------------------------------------------------------
; 函数名  : LCB_Cancel
; 功能    : 弹窗回调：回滚全部转换并退出（待提交记录一并清空）
;------------------------------------------------------------------------
procedure( LCB_Cancel()
    let( ()
        axlUIWPrint(nil "** Cancelled Program. **")
        axlDBTransactionRollback(LCB_mark)
        LCB_mark = nil
        notdone  = nil
        _RLTS_pending     = nil
        _RLTS_pendingSegs = nil
        axlClearSelSet()
        axlCancelEnterFun()
    )
)

;------------------------------------------------------------------------
; 函数名  : LCB_Done
; 功能    : 弹窗回调：提交全部转换并退出；本次运行的转换记录作为一批
;           压入 _RLTS_undoStack，提示可用 ASTB_Route_LineToShapeu 撤销
;------------------------------------------------------------------------
procedure( LCB_Done()
    let( ()
        axlUIWPrint(nil "- Done -")
        axlDBTransactionCommit(LCB_mark)
        LCB_mark = nil
        notdone  = nil
        when( _RLTS_pending
            _RLTS_undoStack = cons(reverse(_RLTS_pending) _RLTS_undoStack)
            ASTB_UndoJournalPush("route_linetoshape")
            axlUIWPrint(nil "完成。输入 astbundo 可撤销本次修改（共 %d 条走线）"
                length(_RLTS_pending))
        )
        _RLTS_pending     = nil
        _RLTS_pendingSegs = nil
        axlCancelEnterFun()
    )
)

;------------------------------------------------------------------------
; 函数名  : RLTS_Undo
; 功能    : 撤销最近一次 Done 提交的转换批次（命令 ASTB_Route_LineToShapeu）。
;           按记录的路径点现场查找转换生成的 shape（同层 + bBox 匹配，
;           新鲜 dbid 来自选择集，绝不使用存储 dbid）并删除，再按记录
;           重建原走线（cline 显式挂网络，line 无网络）。
; 备注    : 找不到 shape 时仍重建（同 rvia 语义：视为已被手动删除）；
;           原走线含弧线段时按直线段近似重建并提示；多次 Done 形成多批，
;           逐批撤销；栈空时提示"没有可撤销的记录"。
;------------------------------------------------------------------------
procedure( RLTS_Undo()
    prog( (batch item objType layer netName width pts hasArc bBoxes
           remaining pt s sb er nDel nRest nFail newId)
        unless( _RLTS_undoStack
            axlUIWPrint(nil "没有可撤销的记录")
            return(nil)
        )
        batch = car(_RLTS_undoStack)
        _RLTS_undoStack = cdr(_RLTS_undoStack)
        axlSetFindFilter(?enabled '("noall" "shapes") ?onButtons '("noall" "shapes"))
        nDel  = 0
        nRest = 0
        nFail = 0
        foreach( item batch
            objType = nth(0 item)
            layer   = nth(1 item)
            netName = nth(2 item)
            width   = nth(3 item)
            pts     = nth(4 item)
            hasArc  = nth(5 item)
            bBoxes  = nth(6 item)
            ; ---- 1) 删除本条目生成的 shape：逐路径点现场查找 ----
            remaining = length(bBoxes)
            foreach( pt pts
                when( remaining > 0
                    axlClearSelSet()
                    when( axlSingleSelectPoint(pt)
                        foreach( s axlGetSelSet()
                            when( and(remaining > 0 equal(s->layer layer))
                                er = errset( s->bBox nil )
                                sb = and(er car(er))
                                when( and(sb RLTS_BBoxIn(sb bBoxes))
                                    er = errset( axlDeleteObject(s) t )
                                    if( and(er car(er)) then
                                        nDel = nDel + 1
                                        remaining = remaining - 1
                                    else
                                        axlUIWPrint(nil "  警告: %L 处 shape 删除失败" pt)
                                    )
                                )
                            )
                        )
                    )
                )
            )
            when( remaining > 0
                axlUIWPrint(nil "  提示: 层 %s 有 %d 个生成的 shape 未找到(可能已被删除)，仍按记录重建"
                    layer remaining)
            )
            ; ---- 2) 按记录重建原走线 ----
            if( and(pts cdr(pts)) then
                if( equal(objType "line") then
                    er = errset( axlDBCreateLine(pts width layer) t )
                else
                    er = errset( axlDBCreateLine(pts width layer netName) t )
                )
                newId = RLTS_FirstDbid(and(er car(er)))
                if( newId then
                    nRest = nRest + 1
                    ;; 挂网络的 cline 建线时约束管理器可能覆盖线宽——
                    ;; 显式压回记录的原始线宽（16.6 实机：线宽没回来）
                    when( and(width numberp(width))
                        errset( axlChangeWidth(list(newId) width) t )
                    )
                    when( hasArc
                        axlUIWPrint(nil "  提示: 层 %s 原走线含弧线段，已按直线段近似重建" layer)
                    )
                else
                    nFail = nFail + 1
                    axlUIWPrint(nil "  警告: 层 %s 走线重建失败(起点 %L)" layer car(pts))
                )
            else
                nFail = nFail + 1
                axlUIWPrint(nil "  警告: 层 %s 记录缺少路径点，无法重建原走线" layer)
            )
        )
        axlClearSelSet()
        axlFlushDisplay()
        axlUIWPrint(nil "撤销完成: 删除 shape %d 个，重建走线 %d 条，失败 %d 条" nDel nRest nFail)
        return(t)
    )
)

ASTB_RegisterCommand("ASTB_Route_LineToShape" "ASTB_Route_LineToShape" ?cmdType "interactive")
ASTB_RegisterCommand("ASTB_Route_LineToShapeu" 'RLTS_Undo ?cmdType "general" ?undo nil)
; 统一撤销中枢注册（core/trans.il v1.4）：astbundo 按 LIFO 分发到本函数
ASTB_RegisterUndo("route_linetoshape" 'RLTS_Undo)

printf("[ASTB] route_linetoshape.il loaded.\n")
