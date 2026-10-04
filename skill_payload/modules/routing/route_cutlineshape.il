;========================================================================
; 文件名    : route_cutlineshape.il
; 作者      : Allegro SKILL Toolbox
; 创建日期  : 2026-07-16
; 版本      : 1.3
; 功能描述  : 切割走线和shape，用框选区域切割cline/line/shape/via
; 依赖模块  : core/menu.il, core/utils.il, core/trans.il
; 修改记录  :
;   2026-07-16 v1.0 Allegro SKILL Toolbox 初始创建
;   2026-07-16 v1.1 Allegro SKILL Toolbox 整改：
;                   1) 入口接入 ASTB_DBTransactionMark 错误保护包装
;                   2) let 绑定表补 shapeid；case 分支改标准多键写法
;                   3) onButtons 补 LINESEGS（普通 line 可被选中）
;                   4) via 分支跳过测试点/封装内/固定 via，删除/新建检查返回值
;   2026-08-20 v1.2 Allegro SKILL Toolbox 新增撤销（rviau 实证模式）：
;                   1) 批次栈 _RCUT_undoStack 只存定位信息，不存 dbid
;                      （dbid 跨命令失效成 dbid:removed，pitfalls 2.6）
;                   2) 新增撤销命令 ASTB_Route_CutLineShapeu：撤销最近
;                      一次 Done 的整批切割——line/arc 按起讫点+宽度+层+
;                      网络重建原段并删切割残段（arc 无创建 API，按弦线
;                      重建并告警）；via 按焊盘名+坐标+网络重建；shape
;                      按外边界顶点重建并删切割块
;                   3) Done 结束提示撤销命令名
;   2026-08-20 v1.3 Allegro SKILL Toolbox 接入统一撤销中枢 astbundo
;                   （core/trans.il v1.4）：ASTB_RegisterUndo 注册
;                   RCUT_Undo，批次入栈同步 ASTB_UndoJournalPush；Done
;                   提示改指 astbundo（ASTB_Route_CutLineShapeu 保留为别名）
;========================================================================

/*
#################################################################################################
#                      Command: FYCUT                                                             #
#                      Skill File: FanySkill_CutClines_Lines_Shapes.il                            #
#                      How To Load: Command> (load("FanySkill_CutClines_Lines_Shapes.il"))        #
#                   How To Execute: Command> FYCUT                                                #
#                       Write by: Wanghh Download Addr:https://github.com/whh5118/GTOpen          #
#################################################################################################
*/

;------------------------------------------------------------------------
; 全局状态（惰性初始化，防 redef 警告）
;   _RCUT_undoStack  切割批次栈：每次 Done（或 Cancel）结束压一批，
;                    批内逐对象记录定位信息（不存 dbid——跨命令失效成
;                    dbid:removed，pitfalls 2.6，rviau 实证模式）：
;                      ("line"  objType startEnd width layer netname
;                               残段端点对列表)
;                      ("via"   焊盘名 坐标 网络名)
;                      ("shape" 外边界顶点 fill layer netname 块顶点列表)
;------------------------------------------------------------------------
unless( boundp('_RCUT_undoStack) _RCUT_undoStack = nil )

;------------------------------------------------------------------------
; 函数名  : ASTB_Route_CutLineShape
; 功能    : 命令入口，经 ASTB_DBTransactionMark 包装（errset 错误捕获，
;           保留 Allegro 原生 Ctrl+Z 撤销历史）
;------------------------------------------------------------------------
procedure( ASTB_Route_CutLineShape()
    ASTB_DBTransactionMark('_ASTB_Route_CutLineShape_Exec nil)
)

;------------------------------------------------------------------------
; 函数名  : _ASTB_Route_CutLineShape_Exec
; 功能    : 框选切割 cline/line/shape/via 的具体实现
; 副作用  : 修改当前设计数据库；切割批次记录压 _RCUT_undoStack
;------------------------------------------------------------------------
procedure( _ASTB_Route_CutLineShape_Exec()
prog((tt tt0 minleng mypopup sels mypath poly0 linesets poly1 selbox
        lineleng linexy0 linexy1 shapeid
        batch oType oSE stubs pieceVerts sVerts vNm vXy vNet)
    unless( axlOKToProceed()
        axlUIConfirm("\265\261\307\260\273\267\276\263\262\273\324\312\320\355\326\264\320\320\270\303\262\331\327\367")
        return(nil)
    )
    minleng = expt(0.1 cadr(axlDBGetDesignUnits()))
    batch = nil
    mypopup = axlUIPopupDefine(nil;axlUIGetUserData()->popupId
        list(
            list("Done" "axlUIPopupSet(nil) axlFinishEnterFun()")
            list("Undo" "ASTB_SystemUndo()")
        list("Cancel" "axlUIPopupSet(nil) axlCancelEnterFun()")
        )
    )
    axlSetFindFilter(?enabled '("NOALL" "vias" "CLINESEGS" "shapes" "LINESEGS") ?onButtons '("noall" "vias" "CLINESEGS" "shapes" "LINESEGS"))
    axlClearSelSet()
    axlUIPopupSet(mypopup)
    while(selbox = axlEnterBox(?prompts list(">>\307\353\312\344\310\353\265\332\322\273\270\366\265\343" ">>\307\353\312\344\310\353\265\332\266\376\270\366\265\343")) ;
        axlUIPopupSet(mypopup)
      axlSingleSelectBox(selbox)
      sels = axlGetSelSet()
        axlClearSelSet()
        foreach(n0 sels
            case(n0->objType
                (("line" "arc")
                    mypath = axlMakeDynamicsPath(list(
                        list(xCoord(selbox) list(xCoord(xCoord(selbox)) yCoord(yCoord(selbox))) 0.)
                        list(list(xCoord(xCoord(selbox)) yCoord(yCoord(selbox))) yCoord(selbox) 0.)
                        list(yCoord(selbox) list(xCoord(yCoord(selbox)) yCoord(xCoord(selbox))) 0.)
                        list(list(xCoord(yCoord(selbox)) yCoord(xCoord(selbox))) xCoord(selbox) 0.)
                    ))
                    poly0 = axlPolyFromDB(mypath)
                    linesets = nil
                    poly1 = axlPolyFromDB(n0)
                    foreach(n1 axlPolyOperation(poly1 poly0 'ANDNOT)
                        tt = setof(x0 n1->vertices (member(x0 car(poly1)->vertices) == nil))
                        tt0 = setof(x0 n1->vertices (member(x0 car(poly1)->vertices) != nil))
                        when(tt0
                            lineleng = axlDistance(caar(tt) caar(tt0)) - n0->width
                            tt = axlMXYSub(car(n0->startEnd) caar(tt0))
                            when(abs(car(tt)) + abs(cadr(tt)) <= minleng*2 + n0->width
                                linexy0 = car(n0->startEnd)
                                linexy1 = axlMUniVector(linexy0 cadr(n0->startEnd) lineleng)
                                linesets = cons(list(linexy0 linexy1) linesets)
                            )
                            tt = axlMXYSub(cadr(n0->startEnd) caar(tt0))
                            when(abs(car(tt)) + abs(cadr(tt)) <= minleng*2 + n0->width
                                linexy0 = cadr(n0->startEnd)
                                linexy1 = axlMUniVector(linexy0 car(n0->startEnd) lineleng)
                                linesets = cons(list(linexy0 linexy1) linesets)
                            )
                        )
                    )
                    tt = ncons(nil)
                    tt->width = n0->width
                    tt->layer = n0->layer
                    tt->netname = n0->net->name
                    ; 撤销记录：删除前取原段定位信息（类型/起讫点）
                    oType = n0->objType
                    oSE   = n0->startEnd
                    if( axlDeleteObject(n0) then
                        stubs = nil
                        foreach(n1 linesets
                            ; axlDBCreateLine 返回 ((dbid) drc)，caar 取新建线段 dbid
                            tt0 = axlDBCreateLine(n1 tt->width tt->layer tt->netname)
                            if( and(caar(tt0) tt->netname nequal(caar(tt0)->net->name tt->netname)) then
                                axlDeleteObject(caar(tt0))
                            else
                                ; 存活残段计入撤销批次（定位：两端点）
                                when( caar(tt0)
                                    stubs = cons(n1 stubs)
                                )
                            )
                        )
                        batch = cons(list("line" oType oSE tt->width tt->layer
                            tt->netname reverse(stubs)) batch)
                    else
                        axlUIWPrint(nil "** Error. Failed to delete line/arc (maybe fixed). **")
                    )
                )
                ("via"
                    ; 跳过测试点、封装内(symbolEtch)及固定的 via，避免误删
                    if( n0->testPoint || n0->symbolEtch || axlDBIsFixed(n0 nil) then
                        axlUIWPrint(nil "-- Skip testpoint/symbol/fixed via --")
                    else
                        ; 撤销记录：删除前取定位信息（焊盘名 坐标 网络）
                        vNm  = n0->name
                        vXy  = n0->xy
                        vNet = errset(n0->net->name nil)
                        vNet = and(vNet car(vNet))
                        if( axlDeleteObject(n0) then
                            batch = cons(list("via" vNm vXy vNet) batch)
                        else
                            axlUIWPrint(nil "** Error. Failed to delete via. **")
                        )
                    )
                )
                ("shape"
                    when(n0->net
                        mypath = axlMakeDynamicsPath(list(
                            list(xCoord(selbox) list(xCoord(xCoord(selbox)) yCoord(yCoord(selbox))) 0.)
                            list(list(xCoord(xCoord(selbox)) yCoord(yCoord(selbox))) yCoord(selbox) 0.)
                            list(yCoord(selbox) list(xCoord(yCoord(selbox)) yCoord(xCoord(selbox))) 0.)
                            list(list(xCoord(yCoord(selbox)) yCoord(xCoord(selbox))) xCoord(selbox) 0.)
                        ))
                        poly0 = axlPolyFromDB(mypath)

                        shapeid = n0
                        when(n0->shapeBoundary
                            shapeid = n0->shapeBoundary
                        )
                        poly1 = axlPolyFromDB(shapeid)
                        tt = ncons(nil)
                        tt->fill = shapeid->fill
                        tt->layer = shapeid->layer
                        tt->netname = shapeid->net->name
                        ; 撤销记录：删除前取原 shape 外边界顶点列表
                        sVerts = poly1->vertices
                        if( axlDeleteObject(shapeid) then
                            pieceVerts = nil
                            foreach(n1 axlPolyOperation(poly1 poly0 'ANDNOT)
                                ; axlDBCreateShape 返回 (dbid drc)，car 为新建铜皮 dbid
                                tt0 = axlDBCreateShape(n1 tt->fill tt->layer tt->netname)
                                if( car(tt0) then
                                    ; 存活切割块计入撤销批次（定位：顶点集）
                                    pieceVerts = cons(n1->vertices pieceVerts)
                                else
                                    axlUIWPrint(nil "** Error. Failed to create Shape. **")
                                )
                            )
                            batch = cons(list("shape" sVerts tt->fill tt->layer
                                tt->netname reverse(pieceVerts)) batch)
                        else
                            axlUIWPrint(nil "** Error. Failed to delete shape (maybe fixed). **")
                        )
                    )
                )
            )
        )
    )
    ; 注：原 axlDBRefreshId(nil) 为非文档用法，已移除

    axlUIPopupSet(nil)
    ; 撤销批次入栈并提示（pitfalls 2.6：本机系统撤销不覆盖 AXL 建/删
    ; 对象，撤销由模块自维护）
    when( batch
        _RCUT_undoStack = cons(reverse(batch) _RCUT_undoStack)
        ASTB_UndoJournalPush("route_cutlineshape")
        axlUIWPrint(nil "\315\352\263\311\241\243\312\344\310\353 astbundo \277\311\263\267\317\372\261\276\264\316\320\336\270\304")
    )
)
)

ASTB_RegisterCommand("ASTB_Route_CutLineShape" "ASTB_Route_CutLineShape" ?cmdType "interactive")

;------------------------------------------------------------------------
; 函数    : RCUT_PtEq
; 功能    : 两点近似判等（曼哈顿距离 <= tol，与本文件既有容差风格一致）
;------------------------------------------------------------------------
procedure( RCUT_PtEq(p1 p2 tol)
    and( p1 p2 abs(car(p1) - car(p2)) + abs(cadr(p1) - cadr(p2)) <= tol )
)

;------------------------------------------------------------------------
; 函数    : RCUT_EndsEq
; 功能    : 两线段端点集判等（不分方向）
;------------------------------------------------------------------------
procedure( RCUT_EndsEq(se1 se2 tol)
    or( and(RCUT_PtEq(car(se1) car(se2) tol) RCUT_PtEq(cadr(se1) cadr(se2) tol))
        and(RCUT_PtEq(car(se1) cadr(se2) tol) RCUT_PtEq(cadr(se1) car(se2) tol))
    )
)

;------------------------------------------------------------------------
; 函数    : RCUT_PolyOf
; 功能    : axlPolyFromDB 归一化取值（errset 保护；个别调用形式返回
;           单元素列表——clinevoid 实证 car 解包，listp 判断兼容两种）
; 返回    : r_poly / nil
;------------------------------------------------------------------------
procedure( RCUT_PolyOf(obj)
    prog( (rr v)
        rr = errset( axlPolyFromDB(obj) nil )
        v  = and(rr car(rr))
        when( and(v listp(v))
            v = car(v)
        )
        return(v)
    )
)

;------------------------------------------------------------------------
; 函数    : RCUT_VertsToPoly
; 功能    : 顶点列表重建闭合 r_poly（动态路径法，与本文件框选多边形
;           同款通路：axlMakeDynamicsPath + axlPolyFromDB）
; 参数    : verts  顶点列表（>= 3 个）
; 返回    : r_poly / nil
;------------------------------------------------------------------------
procedure( RCUT_VertsToPoly(verts)
    prog( (segs i n path)
        n = length(verts)
        if( or(null(verts) n < 3) then
            return(nil)
        )
        segs = nil
        for( i 1 n - 1
            segs = cons(list(nth(i - 1 verts) nth(i verts) 0.) segs)
        )
        segs = cons(list(nth(n - 1 verts) car(verts) 0.) segs)
        path = errset( axlMakeDynamicsPath(reverse(segs)) nil )
        path = and(path car(path))
        unless( path
            return(nil)
        )
        return( RCUT_PolyOf(path) )
    )
)

;------------------------------------------------------------------------
; 函数    : RCUT_VertsMatch
; 功能    : 顶点集判等（数量相同且每个记录顶点都有候选顶点在 tol 内）
;------------------------------------------------------------------------
procedure( RCUT_VertsMatch(v1 v2 tol)
    prog( (ok p found q)
        if( nequal(length(v1) length(v2)) then
            return(nil)
        )
        ok = t
        foreach( p v1
            found = nil
            foreach( q v2
                when( and(null(found) RCUT_PtEq(p q tol))
                    found = t
                )
            )
            unless( found
                ok = nil
            )
        )
        return(ok)
    )
)

;------------------------------------------------------------------------
; 函数    : RCUT_FindLineByEnds
; 功能    : 按 中点点选 + 层 + 端点集 现场查找新鲜 line/arc dbid
;           （选择集返回新鲜 dbid，不依赖存储 dbid；调用方已设好
;           find filter。找不到返回 nil）
;------------------------------------------------------------------------
procedure( RCUT_FindLineByEnds(sp1 sp2 layer tol)
    prog( (mid cand hit)
        mid = list((car(sp1) + car(sp2)) / 2.0 (cadr(sp1) + cadr(sp2)) / 2.0)
        hit = nil
        axlClearSelSet()
        when( axlSingleSelectPoint(mid)
            foreach( cand axlGetSelSet()
                when( and(null(hit)
                          member(cand->objType '("line" "arc"))
                          equal(cand->layer layer)
                          RCUT_EndsEq(cand->startEnd list(sp1 sp2) tol))
                    hit = cand
                )
            )
        )
        axlClearSelSet()
        return(hit)
    )
)

;------------------------------------------------------------------------
; 函数    : RCUT_FindShapeByVerts
; 功能    : 按 顶点包围盒框选 + 层 + 顶点集 现场查找新鲜 shape dbid
;           （框到多个时逐顶点比对，防误删同区域其他铜皮）
;------------------------------------------------------------------------
procedure( RCUT_FindShapeByVerts(verts layer tol)
    prog( (xs ys x0 y0 x1 y1 cand hit bnd cpoly)
        xs = mapcar('car verts)
        ys = mapcar('cadr verts)
        x0 = apply('min xs) - tol
        x1 = apply('max xs) + tol
        y0 = apply('min ys) - tol
        y1 = apply('max ys) + tol
        hit = nil
        axlClearSelSet()
        when( axlSingleSelectBox(list(list(x0 y0) list(x1 y1)))
            foreach( cand axlGetSelSet()
                when( and(null(hit)
                          equal(cand->objType "shape")
                          equal(cand->layer layer))
                    bnd = cand
                    when( cand->shapeBoundary
                        bnd = cand->shapeBoundary
                    )
                    cpoly = RCUT_PolyOf(bnd)
                    when( and(cpoly RCUT_VertsMatch(verts cpoly->vertices tol))
                        hit = cand
                    )
                )
            )
        )
        axlClearSelSet()
        return(hit)
    )
)

;------------------------------------------------------------------------
; 函数    : _RCUT_UndoExec
; 功能    : 撤销执行体（由 RCUT_Undo 经 ASTB_DBTransactionMark 包裹）：
;           弹出栈顶批次逐条恢复——
;           "line"  先按 startEnd/宽度/层/网络重建原段（建成才动残段，
;                   防数据丢失；arc 无创建 API，按弦线重建并告警），
;                   再按 端点对+层 现场查找删除切割残段
;           "via"   按 焊盘名+坐标+网络 重建（axlDBCreateVia）
;           "shape" 先按外边界顶点重建原 shape，再按 顶点集+层 现场
;                   查找删除切割块
;------------------------------------------------------------------------
procedure( _RCUT_UndoExec()
    prog( (batch item tol kind n m
            oType oSE oW oLay oNet stubs stub
            vNm vXy sVerts sFill pieces pv
            rr hit poly newObj)
        unless( _RCUT_undoStack
            axlUIWPrint(nil "\303\273\323\320\277\311\263\267\317\372\265\304\307\320\270\356\274\307\302\274")
            return(nil)
        )
        batch = car(_RCUT_undoStack)
        _RCUT_undoStack = cdr(_RCUT_undoStack)
        tol = expt(0.1 cadr(axlDBGetDesignUnits())) * 4
        n = 0
        m = 0
        foreach( item batch
            kind = car(item)
            case( kind
                ("line"
                    oType = nth(1 item)
                    oSE   = nth(2 item)
                    oW    = nth(3 item)
                    oLay  = nth(4 item)
                    oNet  = nth(5 item)
                    stubs = nth(6 item)
                    when( equal(oType "arc")
                        axlUIWPrint(nil "  \276\257\270\346: %L \264\246\324\255\316\252\273\241\317\337, \316\336\273\241\317\337\264\264\275\250 API, \322\321\260\264\317\322\317\337\326\330\275\250, \307\353\274\354\262\351" oSE)
                    )
                    rr = errset( axlDBCreateLine(oSE oW oLay oNet) t )
                    newObj = and(rr car(rr) caar(rr))
                    if( newObj then
                        n = n + 1
                        axlSetFindFilter(?enabled '("noall" "CLINESEGS" "LINESEGS")
                            ?onButtons '("noall" "CLINESEGS" "LINESEGS"))
                        foreach( stub stubs
                            hit = RCUT_FindLineByEnds(car(stub) cadr(stub) oLay tol)
                            if( and(hit errset( axlDeleteObject(hit) t )) then
                                n = n + 1
                            else
                                axlUIWPrint(nil "  \276\257\270\346: \262\320\266\316 %L \316\264\325\322\265\275\273\362\311\276\263\375\312\247\260\334(\277\311\304\334\322\321\261\273\312\326\266\257\270\304\266\257)" stub)
                            )
                        )
                    else
                        m = m + 1
                        axlUIWPrint(nil "  \276\257\270\346: \324\255\266\316 %L \326\330\275\250\312\247\260\334, \266\324\323\246\262\320\266\316\316\264\266\257" oSE)
                    )
                )
                ("via"
                    vNm  = nth(1 item)
                    vXy  = nth(2 item)
                    oNet = nth(3 item)
                    rr = errset( axlDBCreateVia(vNm vXy oNet) t )
                    if( and(rr car(rr) car(car(rr))) then
                        n = n + 1
                    else
                        m = m + 1
                        axlUIWPrint(nil "  \276\257\270\346: \271\375\277\327 %s \324\332 %L \326\330\275\250\312\247\260\334" vNm vXy)
                    )
                )
                ("shape"
                    sVerts = nth(1 item)
                    sFill  = nth(2 item)
                    oLay   = nth(3 item)
                    oNet   = nth(4 item)
                    pieces = nth(5 item)
                    poly = RCUT_VertsToPoly(sVerts)
                    newObj = nil
                    when( poly
                        rr = errset( axlDBCreateShape(poly sFill oLay oNet) t )
                        newObj = and(rr car(rr) car(car(rr)))
                    )
                    if( newObj then
                        n = n + 1
                        axlSetFindFilter(?enabled '("noall" "shapes")
                            ?onButtons '("noall" "shapes"))
                        foreach( pv pieces
                            hit = RCUT_FindShapeByVerts(pv oLay tol)
                            if( and(hit errset( axlDeleteObject(hit) t )) then
                                n = n + 1
                            else
                                axlUIWPrint(nil "  \276\257\270\346: \307\320\270\356\277\351(\266\245\265\343%d\270\366)\316\264\325\322\265\275\273\362\311\276\263\375\312\247\260\334(\277\311\304\334\322\321\261\273\312\326\266\257\270\304\266\257)"
                                    length(pv))
                            )
                        )
                    else
                        m = m + 1
                        axlUIWPrint(nil "  \276\257\270\346: shape(%s) \326\330\275\250\312\247\260\334, \266\324\323\246\307\320\270\356\277\351\316\264\266\257" oLay)
                    )
                )
                (t nil)
            )
        )
        axlClearSelSet()
        axlFlushDisplay()
        axlUIWPrint(nil "\263\267\317\372\315\352\263\311: \273\326\270\264/\307\345\300\355 %d \264\246, %d \264\246\312\247\260\334" n m)
        return(t)
    )
)

;------------------------------------------------------------------------
; 函数    : RCUT_Undo
; 功能    : 撤销命令入口（ASTB_Route_CutLineShapeu）：撤销最近一次
;           Done 的整批切割；栈空时提示。errset 包装防中途出错。
;------------------------------------------------------------------------
procedure( RCUT_Undo()
    ASTB_DBTransactionMark('_RCUT_UndoExec nil)
)

; 注册须在函数定义之后（ASTB_RegisterCommand 检查 fboundp）
ASTB_RegisterCommand("ASTB_Route_CutLineShapeu" 'RCUT_Undo ?cmdType "general" ?undo nil)
; 统一撤销中枢注册（core/trans.il v1.4）：astbundo 按 LIFO 分发到本函数
ASTB_RegisterUndo("route_cutlineshape" 'RCUT_Undo)

printf("[ASTB] route_cutlineshape.il loaded.\n")
