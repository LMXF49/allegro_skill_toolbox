;========================================================================
; 文件名    : place_gatherplace.il
; 作者      : ASTB Team
; 创建日期  : 2026-09-10
; 版本      : 1.8
; 功能描述  : 聚拢摆放（无表单简版）：框选/点选要摆放的元件 → 右键 Done →
;             元件按方形聚拢跟随光标（总面积开方定边长）→ 拖框将元件
;             从左到右排入区域内
;             （放满换行，参考"放置到内部"）；同位置点按则聚拢块放该点
; 依赖模块  : core/trans.il（ASTB_RegisterCommand / ASTB_RegisterUndo /
;             ASTB_UndoJournalPush / ASTB_DBTransactionMark）
; 修改记录  :
;   2026-09-10 v1.0 ASTB Team 初始创建（参考 place_gathercomps 三列聚拢；
;                17.4 S039 跨轮 dbid 必死：选完立即提取 (refdes xy bBox)
;                纯数据，放置时按 refdes 现场重解析、即用即弃；撤销存
;                (refdes 旧原点) 纯数据——cvia v1.6/PGC v1.7 实证模式）
;   2026-09-10 v1.1 ASTB Team 连续作业：摆放完回到选元件阶段循环，
;                空手 Done 或 Cancel 退出命令；目标点 Esc 仅跳过本次
;   2026-09-29 v1.2 ASTB Team 第二阶段拖框改为参考"放置到内部"
;                (place_placeinside FPI_Move): 元件在区域内从左到右
;                排列、放满换行(间距5 边距1, 新增 _GP2_LayoutInside),
;                不再把三列聚拢块整体居中放入; 同位置点按仍放聚拢块
;   2026-09-29 v1.3 ASTB Team 跟随光标的聚拢块由固定三列改为面积近似
;                方形: _GP2_Layout 按总面积开方得目标边长, 从左到右
;                放满换行; 点按放置的兜底块同为方形
;   2026-09-29 v1.4 ASTB Team 方形聚拢块器件间距 50 -> 5: 器件贴着
;                排放但不重叠(与"放置到内部"间距一致)
;   2026-09-29 v1.5 ASTB Team 方形聚拢块器件间距 5 -> 0: 轮廓外沿
;                相切(贴着不重叠); 区域内排列(LayoutInside)间距 5 不变
;   2026-09-29 v1.6 ASTB Team 方形聚拢块器件间距 0 -> 5 mil
;                (0 相切实测不合适, 回退 v1.4 的贴着不重叠)
;   2026-09-29 v1.7 ASTB Team 方形聚拢块间距恒定 5 mil 不随单位变:
;                按当前设计单位换算(mm*0.0254/um*25.4/in*0.001/
;                cm*0.00254, mils 原值)
;   2026-09-29 v1.8 ASTB Team LayoutInside 间距 5/边距 1 恒定 mil:
;                与 _GP2_Layout 同款按设计单位换算, 不随单位变
;========================================================================

; --- 跨命令共享状态 ---
unless( boundp('_GP2_undoStack) _GP2_undoStack = nil) ; 撤销批次栈: 每批 ((refdes 旧xy) ...)
unless( boundp('_GP2_cancel)    _GP2_cancel = nil)    ; 选取阶段 Cancel 标志

;------------------------------------------------------------------------
; 选取阶段右键回调（axlSelect groupMode 实证模式；标签必须英文——
; GBK 中文标签触发 reader Invalid character）
;------------------------------------------------------------------------
procedure( _GP2_PickDone()
    axlUIPopupSet(nil)
    axlFinishEnterFun()
)

procedure( _GP2_PickCancel()
    _GP2_cancel = t
    axlClearSelSet()
    axlUIPopupSet(nil)
    axlCancelEnterFun()
)

;------------------------------------------------------------------------
; 函数名  : _GP2_CompBBox
; 功能    : 取元件 PLACE_BOUND 轮廓 bBox；无 PLACE_BOUND 用 symbol bBox 兜底
; 参数    : sym - symbol dbid（当轮有效，即用即弃）
; 返回值  : ((llx lly) (urx ury)) 或 nil
;------------------------------------------------------------------------
procedure( _GP2_CompBBox(sym)
    prog((ch layer bb r)
        bb = nil
        foreach( ch sym->children
            when( ch->layer
                layer = cadr(parseString(ch->layer "/"))
                when( layer == "PLACE_BOUND_TOP" || layer == "PLACE_BOUND_BOTTOM"
                    bb = ch->bBox
                )
            )
        )
        unless( bb
            r = errset(sym->bBox t)
            when( and(r car(r)) bb = car(r) )
        )
        return(bb)
    )
)

;------------------------------------------------------------------------
; 函数名  : _GP2_Layout
; 功能    : 方形聚拢排列（纯数据计算，不碰 dbid）：v1.3 起按总面积
;           开方得目标边长，从左到右放满换行
; 参数    : specs - ((refdes symXy bBox) ...)
; 返回值  : ((refdes w h cellX cellY blx bly) ...)
;           cellX/cellY = 相对块左上角的偏移（cellY 向下累积）；
;           blx/bly = 该件当前轮廓左下角（放置时算位移用）
;------------------------------------------------------------------------
procedure( _GP2_Layout(specs)
    prog((GAP items totalArea targetW curX curY rowH sp rd bb w h blx bly it out
          units factor)
        ; v1.7 恒定 5 mil 不随单位变: 按当前设计单位换算间距
        units = car(axlDBGetDesignUnits())
        cond(
            ( equal(units "millimeters") factor = 0.0254 )
            ( equal(units "microns")     factor = 25.4 )
            ( equal(units "inches")      factor = 0.001 )
            ( equal(units "centimeters") factor = 0.00254 )
            ( t                          factor = 1.0 )
        )
        GAP = 5 * factor
        ; 量尺寸（纯数据）, 累加总面积
        totalArea = 0.0
        items = nil
        foreach( sp specs
            rd = car(sp)
            bb = caddr(sp)
            if( bb then
                w = xCoord(cadr(bb)) - xCoord(car(bb))
                h = yCoord(cadr(bb)) - yCoord(car(bb))
                blx = xCoord(car(bb))
                bly = yCoord(car(bb))
            else
                ; 无轮廓兜底: 100x100, 以 symbol 原点当左下角
                w = 100
                h = 100
                blx = car(cadr(sp))
                bly = cadr(cadr(sp))
            )
            items = cons(list(rd w h blx bly) items)
            totalArea = totalArea + (w + GAP) * (h + GAP)
        )
        items = reverse(items)
        ; v1.3 方形: 目标边长 = 总面积开方, 从左到右放满换行
        targetW = sqrt(totalArea)
        curX = 0
        curY = 0
        rowH = 0
        out = nil
        foreach( it items
            w = cadr(it)
            h = caddr(it)
            when( and(curX > 0 curX + w > targetW)
                curX = 0
                curY = curY + rowH + GAP
                rowH = 0
            )
            out = cons(list(car(it) w h curX curY nth(3 it) nth(4 it)) out)
            curX = curX + w + GAP
            rowH = max(rowH h)
        )
        return(reverse(out))
    )
)

;------------------------------------------------------------------------
; 函数名  : _GP2_DoPlace
; 功能    : 执行摆放：逐件按 refdes 现场重解析 dbid（即用即弃）移到目标
; 参数    : layout - _GP2_Layout 结果；orgX/orgY - 聚拢块左上角设计坐标
; 返回值  : 成功移动数
;------------------------------------------------------------------------
; 函数名  : _GP2_LayoutInside
; 功能    : v1.2 参考"放置到内部"(place_placeinside FPI_Move): 元件在
;           指定矩形内从左到右排列, 放满换行; 间距 5, 左/上边距 1
; 参数    : specs - ((refdes symXy bBox) ...);
;           boxLlx/boxUry/boxUrx - 区域左下x / 左上y / 右下x
; 返回值  : 同 _GP2_Layout: ((refdes w h cellX cellY blx bly) ...)
;           cellX/cellY = 相对区域左上角的偏移(cellY 向下累积)
;------------------------------------------------------------------------
procedure( _GP2_LayoutInside(specs boxLlx boxUry boxUrx)
    prog((GAP MARGIN sp rd bb w h blx bly plsX plsY rowH boxW out
          units factor)
        ; v1.8 间距 5 mil / 边距 1 mil 恒定不随单位变: 按设计单位换算
        units = car(axlDBGetDesignUnits())
        cond(
            ( equal(units "millimeters") factor = 0.0254 )
            ( equal(units "microns")     factor = 25.4 )
            ( equal(units "inches")      factor = 0.001 )
            ( equal(units "centimeters") factor = 0.00254 )
            ( t                          factor = 1.0 )
        )
        GAP = 5 * factor
        MARGIN = 1 * factor
        boxW = boxUrx - boxLlx
        plsX = MARGIN
        plsY = MARGIN
        rowH = 0
        out = nil
        foreach( sp specs
            rd = car(sp)
            bb = caddr(sp)
            if( bb then
                w = xCoord(cadr(bb)) - xCoord(car(bb))
                h = yCoord(cadr(bb)) - yCoord(car(bb))
                blx = xCoord(car(bb))
                bly = yCoord(car(bb))
            else
                ; 无轮廓兜底: 100x100, 以 symbol 原点当左下角
                w = 100
                h = 100
                blx = car(cadr(sp))
                bly = cadr(cadr(sp))
            )
            ; 本行放不下整件且非行首 → 换行(与 FPI_Move 同思路: 先判后放)
            when( and(plsX > MARGIN plsX + w > boxW)
                plsX = MARGIN
                plsY = plsY + rowH + GAP
                rowH = 0
            )
            out = cons(list(rd w h plsX plsY blx bly) out)
            plsX = plsX + w + GAP
            rowH = max(rowH h)
        )
        return(reverse(out))
    )
)

;------------------------------------------------------------------------
procedure( _GP2_DoPlace(layout orgX orgY)
    prog((it rd w h cx cy blx bly dbid dx dy batch moved tr)
        moved = 0
        batch = nil
        axlSetFindFilter(?enabled '("noall" "symbols") ?onButtons '("noall" "symbols"))
        foreach( it layout
            rd  = nth(0 it)
            w   = nth(1 it)
            h   = nth(2 it)
            cx  = nth(3 it)
            cy  = nth(4 it)
            blx = nth(5 it)
            bly = nth(6 it)
            ; 17.4 S039：跨轮 dbid 必死，现场重解析、即用即弃
            axlClearSelSet()
            dbid = car(axlSelectByName("REFDES" rd))
            cond(
                ( null(dbid)
                    axlUIWPrint(nil "  \276\257\270\346: \325\322\262\273\265\275\324\252\274\376 %s, \314\370\271\375" rd)
                )
                ( axlDBIsFixed(dbid nil)
                    axlUIWPrint(nil "  \276\257\270\346: %s \312\307 FIXED, \314\370\271\375" rd)
                )
                ( t
                    ; 目标轮廓左下角 = (orgX+cx, orgY-cy-h)（cellY 向下=设计 -y）
                    dx = orgX + cx - blx
                    dy = orgY - cy - h - bly
                    batch = cons(list(rd dbid->xy) batch) ; 撤销存 (refdes 旧原点)
                    tr = errset( axlTransformObject(dbid ?move dx:dy) t )
                    if( and(tr car(tr)) then
                        moved++
                    else
                        axlUIWPrint(nil "  \276\257\270\346: %s \322\306\266\257\312\247\260\334" rd)
                    )
                )
            )
        )
        axlClearSelSet()
        when( batch
            _GP2_undoStack = cons(reverse(batch) _GP2_undoStack)
            if( fboundp('ASTB_UndoJournalPush) then
                ASTB_UndoJournalPush("place_gatherplace")
            )
        )
        return(moved)
    )
)

;------------------------------------------------------------------------
; 函数名  : _GP2_Undo
; 功能    : 撤销上一批聚拢摆放（gpu / astbundo）；按 refdes 现场重解析
;------------------------------------------------------------------------
procedure( _GP2_Undo()
    prog((batch item rd oldXy dbid dx dy n m tr)
        unless( _GP2_undoStack
            axlUIWPrint(nil "\303\273\323\320\277\311\263\267\317\372\265\304\276\333\302\243\260\332\267\305\274\307\302\274")
            return(nil)
        )
        batch = car(_GP2_undoStack)
        _GP2_undoStack = cdr(_GP2_undoStack)
        axlSetFindFilter(?enabled '("noall" "symbols") ?onButtons '("noall" "symbols"))
        n = 0
        m = 0
        foreach( item batch
            rd = car(item)
            oldXy = cadr(item)
            axlClearSelSet()
            dbid = car(axlSelectByName("REFDES" rd))
            if( and(dbid dbid->xy null(axlDBIsFixed(dbid nil))) then
                dx = car(oldXy) - car(dbid->xy)
                dy = cadr(oldXy) - cadr(dbid->xy)
                tr = errset( axlTransformObject(dbid ?move dx:dy) t )
                if( and(tr car(tr)) then n++ else m++ )
            else
                m++
            )
        )
        axlClearSelSet()
        axlFlushDisplay()
        axlUIWPrint(nil "\263\267\317\372\315\352\263\311: \322\306\273\330 %d \270\366\324\252\274\376, %d \270\366\312\247\260\334" n m)
        return(t)
    )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_Place_GatherPlace
; 功能    : 命令入口（菜单 / gp）：框选元件 → 跟随光标 → 拖框/点两下放置
;------------------------------------------------------------------------
procedure( ASTB_Place_GatherPlace()
    prog((popup comps sp specs layout it blockW blockH boxres ll ur orgX orgY
          placed errBox w h cx cy ol inLlx inUry inUrx)
        unless( axlOKToProceed()
            axlUIWPrint(nil "ERROR: \265\261\307\260\273\267\276\263\262\273\324\312\320\355\326\264\320\320\270\303\262\331\327\367")
            return(nil)
        )
        axlUIWPrint(nil "\276\333\302\243\260\332\267\305: \277\362\321\241/\265\343\321\241\324\252\274\376 \241\372 \315\317\277\362\260\321\324\252\274\376\305\305\310\353\307\370\323\362\304\332(\267\305\302\372\273\273\320\320); \277\325\312\326 Done / Cancel \315\313\263\366")
        ; v1.1: 连续作业循环——摆放完回到选元件, 空手 Done / Cancel 退出
        while( t
            ; --- 第一阶段: 选元件（axlSelect 家族，右键 Done/Cancel 有效）---
            axlClearSelSet()
            axlSetFindFilter(?enabled '("noall" "symbols") ?onButtons '("noall" "symbols"))
            _GP2_cancel = nil
            popup = axlUIPopupDefine(nil list(
                    list("Done"   "_GP2_PickDone()")
                    list("Cancel" "_GP2_PickCancel()")))
            when( popup axlUIPopupSet(popup) )
            axlSelect(?groupMode t ?prompt "\265\343\321\241/\277\362\321\241\322\252\276\333\302\243\260\332\267\305\265\304\324\252\274\376, \323\322\274\374 Done \260\332\267\305 / Cancel \315\313\263\366")
            axlUIPopupSet(nil)
            comps = axlGetSelSet()
            when( or(_GP2_cancel null(comps))
                axlUIWPrint(nil "\276\333\302\243\260\332\267\305\275\341\312\370")
                return(t)
            )
            ; --- 趁本轮 dbid 活着立即提取身份纯数据（17.4 跨轮必死）---
            specs = nil
            foreach( sp comps
                when( and(sp->refdes sp->xy)
                    specs = cons(list(sp->refdes sp->xy _GP2_CompBBox(sp)) specs)
                )
            )
            specs = reverse(specs)
            axlClearSelSet()
            unless( specs
                axlUIWPrint(nil "\313\371\321\241\266\324\317\363\316\336\323\320\320\247\324\252\274\376, \307\353\326\330\320\302\321\241\324\361")
                ; 继续循环重新选择
            )
            when( specs
                layout = _GP2_Layout(specs)
                ; 块尺寸
                blockW = 0
                blockH = 0
                foreach( it layout
                    blockW = max(blockW nth(3 it) + nth(1 it))
                    blockH = max(blockH nth(4 it) + nth(2 it))
                )
                axlUIWPrint(nil "\271\262 %d \270\366\324\252\274\376; \315\317\277\362\310\267\266\250\267\305\326\303\307\370\323\362: \264\323\327\363\265\275\323\322\305\305\310\353, \267\305\302\372\273\273\320\320"
                    length(layout))
                ; --- 动态预览（纯数据轮廓，不碰 dbid）---
                foreach( it layout
                    w  = nth(1 it)
                    h  = nth(2 it)
                    cx = nth(3 it)
                    cy = nth(4 it)
                    ol = axlPathStart(list(0:0 w:0 w:h 0:h 0:0))
                    axlAddSimpleMoveDynamics(cx:(0 - cy - h) ol "path" ?ref_point 0:0)
                )
                ; --- 第二阶段: 目标区域/点（enter 家族无自定义右键, Esc 跳过本次）---
                boxres = axlEnterBox(?prompts list(
                    "\315\317\277\362\310\267\266\250\267\305\326\303\307\370\323\362: \324\252\274\376\264\323\327\363\265\275\323\322\305\305\310\353, \267\305\302\372\273\273\320\320 (Esc \314\370\271\375)"
                    "\327\363\274\374\310\267\266\250\307\370\323\362\301\355\322\273\275\307\265\343"))
                axlClearDynamics()
                if( and(boxres listp(boxres) car(boxres) cadr(boxres)) then
                    ll = car(boxres)
                    ur = cadr(boxres)
                    if( and( abs(car(ur) - car(ll)) > 1 abs(cadr(ur) - cadr(ll)) > 1 ) then
                        ; v1.2: 拖了真实框 → 参考"放置到内部": 元件在区域内
                        ; 从左到右排列、放满换行(间距5 边距1), 布局随框走
                        inLlx = min(car(ll) car(ur))
                        inUry = max(cadr(ll) cadr(ur))
                        inUrx = max(car(ll) car(ur))
                        layout = _GP2_LayoutInside(specs inLlx inUry inUrx)
                        orgX = inLlx
                        orgY = inUry
                    else
                        ; 点按：块左上角对齐点击点
                        orgX = car(ll)
                        orgY = cadr(ll)
                    )
                    errBox = ncons(nil)
                    placed = ASTB_DBTransactionMark('_GP2_DoPlace list(layout orgX orgY) errBox)
                    when( errBox->value
                        axlUIWPrint(nil "ERROR: \260\332\267\305\312\247\260\334: %s" errBox->value)
                    )
                    axlUIWPrint(nil "\276\333\302\243\260\332\267\305\315\352\263\311: %d \270\366\324\252\274\376; \263\267\317\372: gpu / astbundo" placed)
                else
                    axlUIWPrint(nil "\261\276\264\316\316\264\260\332\267\305")
                )
            )
        )
        return(t)
    )
)

; 命令注册（函数定义之后；ASTB_RegisterCommand 检查 fboundp）
ASTB_RegisterCommand("ASTB_Place_GatherPlace" "ASTB_Place_GatherPlace" ?cmdType "interactive")
ASTB_RegisterCommand("gp" "ASTB_Place_GatherPlace" ?cmdType "interactive")
ASTB_RegisterCommand("ASTB_Place_GatherPlaceU" "_GP2_Undo" ?cmdType "general" ?undo nil)
ASTB_RegisterCommand("gpu" "_GP2_Undo" ?cmdType "general" ?undo nil)
; 统一撤销中枢（core/trans.il v1.4）：astbundo 按 LIFO 分发
ASTB_RegisterUndo("place_gatherplace" '_GP2_Undo)

printf("[ASTB] place_gatherplace.il v1.8 loaded, command: gp / gpu(\263\267\317\372)\n")
