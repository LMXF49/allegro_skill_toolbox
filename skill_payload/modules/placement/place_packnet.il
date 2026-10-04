;   2026-09-09 v3.7 ASTB Team 修 17.4 S039 跨轮 dbid 失效：第一步选中
;                   元件的 dbid 在 axlEnterBox 后全部 dbid:removed；选择
;                   阶段只存 refdes/网络名纯数据，_PKN_DoPack 循环内按
;                   refdes 现场 axlSelectByName 重取新鲜 dbid、当轮即用
;                   即弃（place_gathercomps v1.7 实证模式），transform 查返回值
;   2026-08-20 v3.6 ASTB Team 撤销命令注册补 ?undo nil（防系统撤销把
;                   撤销命令本身入栈，17.4+）
;========================================================================
; 文件名    : modules/placement/place_packnet.il
; 作者      : allegro_skill 项目组
; 创建日期  : 2026-07-26
; 版本      : 3.7（修 17.4 跨轮 dbid 失效：只存 refdes 纯数据，用时现场重取）
; 功能描述  : 按网络聚拢摆放（Pack by Net）：第一步框选多个元件，
;             第二步框选目标区域；按"共享网络"把选中元件并成连通组
;             （全部网络参与并组，不屏蔽电源/地），连通组按大小降序
;             后逐组紧凑整齐地摆放到目标区域：组内元件按外框紧密
;             相邻密排、组间换行，FIXED 元件自动跳过并计数；
;             撤销命令 ASTB_Place_PackNetu 逐批移回最近一次聚拢
; 依赖模块  : core/utils.il、core/trans.il
; 编码      : GBK（含中文注释）
; 修改记录  :
;   2026-07-25 v1.0 allegro_skill 项目组 初始创建
;   2026-07-26 v3.0 allegro_skill 项目组 回退到第一版简洁流程；
;                     保留三个客观修复：sym->pins 取网（component
;                     无 pins 属性）、移动参数改 (x y) 列表点（本机
;                     拒 cons 点对）、if 显式 then（防分支错配）
;   2026-08-17 v3.3 ASTB Team 选择阶段右键菜单补 Done/Oops/Cancel：
;                     原裸 axlSelect() 默认右键只有 snap pick to，无法
;                     Done 结束选择；改 rvia 实证模式（groupMode t +
;                     popup 命名函数串回调），Oops=清空重选
;   2026-08-20 v3.4 ASTB Team 新增撤销命令 ASTB_Place_PackNetu：
;                     _PKN_DoPack 批次记录 (refdes 旧原点) 压
;                     _PKN_undoStack（不存 dbid，跨命令失效），撤销
;                     按 refdes 现场 axlSelectByName 拿新鲜 dbid 移回
;   2026-08-20 v3.5 ASTB Team 接入统一撤销中枢 astbundo（core/trans.il
;                     v1.4）：ASTB_RegisterUndo 注册 PKN_Undo，批次入栈
;                     同步 ASTB_UndoJournalPush；Done 提示改指 astbundo
;                     （ASTB_Place_PackNetu 保留为别名）
;========================================================================

;------------------------------------------------------------------------
; 函数名  : _PKN_GapForUnits
; 功能    : 按当前设计单位取密排间距
;------------------------------------------------------------------------
procedure( _PKN_GapForUnits()
    prog((u)
        u = car(axlDBGetDesignUnits())
        cond(
            ( equal(u "mils")        return(20.0) )
            ( equal(u "millimeters") return(0.5) )
            ( equal(u "microns")     return(500.0) )
            ( equal(u "inches")      return(0.02) )
            ( equal(u "centimeters") return(0.05) )
            ( t                      return(20.0) )
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : _PKN_CompNets
; 功能    : 取元件的网络名集合（全部网络参与，不屏蔽）
;------------------------------------------------------------------------
procedure( _PKN_CompNets(sym)
    prog((pins nets p n)
        nets = nil
        when( listp(sym->pins)
            pins = sym->pins
            foreach( p pins
                n = p->net
                when( and(n n->name)
                    unless( ASTB_StrListHas(nets n->name)
                        nets = cons(n->name nets)
                    )
                )
            )
        )
        return(nets)
    )
)

;; 字符串键 assoc（本环境内建 assoc 的 equal 对字符串可能按同一性判假）
procedure( _PKN_AssocStr(key alist)
    prog((r e)
        r = nil
        foreach( e alist
            when( and(listp(e) stringp(car(e)) strcmp(car(e) key) == 0)
                r = e
            )
        )
        return(r)
    )
)

;------------------------------------------------------------------------
; 函数名  : _PKN_GroupByNet
; 功能    : 并集-find 按共享网络并成连通组，按组大小降序
;------------------------------------------------------------------------
procedure( _PKN_GroupByNet(comps netLists)
    prog((n parent i j netOwner groups g nl)
        n = length(comps)
        parent = nil
        for( i 0 (n-1)
            parent = append1(parent i)
        )
        netOwner = nil
        for( i 0 (n-1)
            nl = nth(i netLists)
            when( listp(nl)
                foreach( net nl
                    j = _PKN_AssocStr(net netOwner)
                    if( j then
                        _PKN_Union(parent i cadr(j) n)
                    else
                        netOwner = cons( list(net i) netOwner )
                    )
                )
            )
        )
        groups = nil
        for( i 0 (n-1)
            g = _PKN_Find(parent i n)
            j = assoc(g groups)
            if( j then
                rplacd(j append(cdr(j) list(i)))
            else
                groups = cons( list(g i) groups )
            )
        )
        groups = _PKN_SortGroups(groups)
        return(groups)
    )
)

;; 手写插入排序：按组成员数降序
procedure( _PKN_SortGroups(groups)
    prog((out g)
        out = nil
        foreach( g groups
            out = _PKN_InsertDesc(out g)
        )
        return(out)
    )
)

procedure( _PKN_InsertDesc(l g)
    cond(
        ( null(l)
            list(g)
        )
        ( and(listp(g) listp(car(l)) length(cdr(g)) >= length(cdr(car(l))))
            cons(g l)
        )
        ( t
            cons(car(l) _PKN_InsertDesc(cdr(l) g))
        )
    )
)

procedure( _PKN_Find(parent i n)
    prog((r)
        r = i
        while( nth(r parent) != r
            r = nth(r parent)
        )
        return(r)
    )
)

procedure( _PKN_Union(parent a b n)
    prog((ra rb)
        ra = _PKN_Find(parent a n)
        rb = _PKN_Find(parent b n)
        when( ra != rb
            _PKN_SetNth(parent ra rb)
        )
        return(parent)
    )
)

procedure( _PKN_SetNth(parent idx val)
    prog((cell)
        cell = nthcdr(idx parent)
        when( cell
            rplaca(cell val)
        )
        return(parent)
    )
)

;------------------------------------------------------------------------
; 撤销批次栈：每元素为一批 ( (refdes 旧原点)... )，不存 dbid（跨命令
; 失效成 dbid:removed）；撤销按 refdes 现场查找移回（rvia 实证模式）
;------------------------------------------------------------------------
unless( boundp('_PKN_undoStack) defvar(_PKN_undoStack nil))

;------------------------------------------------------------------------
; 函数名  : _PKN_FreshByRefdes
; 功能    : 按 refdes 现场重取新鲜 dbid（17.4 S039：新一轮交互后旧 dbid
;           全部失效成 dbid:removed，dbid 不跨轮存，用时现场解析、即用
;           即弃——place_gathercomps v1.7 / cvia v1.6 实证模式）；先清
;           选择集再按名查找，找不到或出错返回 nil
;------------------------------------------------------------------------
procedure( _PKN_FreshByRefdes(rd)
    prog((fl)
        axlClearSelSet()
        fl = errset(axlSelectByName("REFDES" rd) t)
        fl = and(fl car(fl))
        return( and(fl car(fl)) )
    )
)

;------------------------------------------------------------------------
; 函数名  : _PKN_DoPack
; 功能    : 布局与移动执行（第一版流程：组按大小降序、组内密排换行）
; 返回值  : (movedCount fixedSkip groupCount)
;------------------------------------------------------------------------
procedure( _PKN_DoPack(comps netLists groups box)
    prog((gap ox oy rowW x y rowH moved fixedSkip ci sym bb w h dx dy ll ur gw firstW batch rd tr)
        gap = _PKN_GapForUnits()
        ll = car(box)
        ur = cadr(box)
        ox = min(xCoord(ll) xCoord(ur))
        oy = min(yCoord(ll) yCoord(ur))
        rowW = abs(xCoord(ur) - xCoord(ll))
        firstW = 0.0
        ; v3.7: comps 只存 refdes 纯数据，逐个现场重取新鲜 dbid 读外框
        foreach( rd comps
            sym = _PKN_FreshByRefdes(rd)
            when( sym
                bb = sym->bBox
                when( bb
                    w = abs(xCoord(cadr(bb)) - xCoord(car(bb)))
                    when( w > firstW firstW = w )
                )
            )
        )
        when( rowW < 5*(firstW+gap)
            rowW = 5*(firstW+gap)
        )
        x = ox
        y = oy
        rowH = 0.0
        moved = 0
        fixedSkip = 0
        foreach( g groups
            ci = cdr(g)
            when( listp(ci)
                gw = 0.0
                foreach( sym ci
                    sym = _PKN_FreshByRefdes(nth(sym comps))
                    when( sym
                        bb = sym->bBox
                        when( bb
                            gw = gw + abs(xCoord(cadr(bb)) - xCoord(car(bb))) + gap
                        )
                    )
                )
                when( and(x > ox x+gw > ox+rowW)
                    y = y + rowH + gap
                    x = ox
                    rowH = 0.0
                )
                foreach( sym ci
                    ; v3.7: comps 存 refdes 纯数据；现场重取新鲜 dbid，当次
                    ; 迭代立刻读 fixed/bBox/xy 并 transform，即用即弃
                    rd = nth(sym comps)
                    sym = _PKN_FreshByRefdes(rd)
                    cond(
                        ( null(sym)
                            axlUIWPrint(nil "  \276\257\270\346: \316\264\325\322\265\275\324\252\274\376 %s, \314\370\271\375" rd)
                        )
                        ( sym->fixed
                            fixedSkip = fixedSkip + 1
                        )
                        ( t
                            bb = sym->bBox
                            when( bb
                                w = abs(xCoord(cadr(bb)) - xCoord(car(bb)))
                                h = abs(yCoord(cadr(bb)) - yCoord(car(bb)))
                                dx = x - xCoord(car(bb))
                                dy = y - yCoord(car(bb))
                                if( or(dx != 0.0 dy != 0.0) then
                                    ; 撤销记录 (refdes 旧原点)：移动前采样，不存 dbid
                                    batch = cons(list(rd sym->xy) batch)
                                    tr = errset(axlTransformObject(sym ?move list(dx dy)) t)
                                    if( and(tr car(tr)) then
                                        moved = moved + 1
                                    else
                                        axlUIWPrint(nil "  \276\257\270\346: %s \322\306\266\257\312\247\260\334, \314\370\271\375" rd)
                                    )
                                )
                                x = x + w + gap
                                when( h > rowH rowH = h )
                            )
                        )
                    )
                )
            )
        )
        ; 撤销批次入栈（移动前记录的 (refdes 旧原点) 列表）
        when( batch
            _PKN_undoStack = cons(reverse(batch) _PKN_undoStack)
            ASTB_UndoJournalPush("place_packnet")
        )
        axlMsgPut(sprintf(nil "\262\274\276\326\275\341\312\370: \322\306\266\257 %d, \314\370\271\375FIXED %d" moved fixedSkip))
        return( list(moved fixedSkip length(groups)) )
    )
)

;------------------------------------------------------------------------
; 函数名  : PKN_Undo
; 功能    : 撤销最近一次 Done 的聚拢摆放（命令 ASTB_Place_PackNetu）：
;           弹出批次栈顶，按记录的 refdes 现场 axlSelectByName 拿新鲜
;           dbid（不存 dbid，跨命令失效成 dbid:removed），按当前原点
;           与记录旧原点的差值移回原位；栈空时提示"没有可撤销的记录"
;------------------------------------------------------------------------
procedure( PKN_Undo()
    prog((batch item rd oldXy foundList sym cur dx dy rr n m)
        unless( _PKN_undoStack
            axlMsgPut("\303\273\323\320\277\311\263\267\317\372\265\304\274\307\302\274")
            return(nil)
        )
        batch = car(_PKN_undoStack)
        _PKN_undoStack = cdr(_PKN_undoStack)
        axlSetFindFilter(?enabled list("noall" "symbols")
                         ?onButtons list("noall" "symbols"))
        n = 0
        m = 0
        foreach( item batch
            rd = car(item)
            oldXy = cadr(item)
            ; 按 refdes 现场查找元件（util_search 实证模式，返回新鲜 dbid）
            axlClearSelSet()
            foundList = errset(axlSelectByName("REFDES" rd) t)
            foundList = and(foundList car(foundList))
            sym = and(foundList car(foundList))
            if( sym then
                cur = sym->xy
                dx = xCoord(oldXy) - xCoord(cur)
                dy = yCoord(oldXy) - yCoord(cur)
                if( or(dx != 0.0 dy != 0.0) then
                    rr = errset(axlTransformObject(sym ?move list(dx dy)) t)
                    if( and(rr car(rr)) then
                        n = n + 1
                    else
                        m = m + 1
                        axlMsgPut(sprintf(nil "  \276\257\270\346: %s \322\306\273\330\324\255\316\273\312\247\260\334" rd))
                    )
                else
                    n = n + 1
                )
            else
                m = m + 1
                axlMsgPut(sprintf(nil "  \276\257\270\346: \316\264\325\322\265\275\324\252\274\376 %s, \314\370\271\375" rd))
            )
        )
        axlClearSelSet()
        axlMsgPut(sprintf(nil "\263\267\317\372\315\352\263\311: \322\306\273\330 %d \270\366\324\252\274\376, %d \270\366\312\247\260\334" n m))
        return(t)
    )
)

;------------------------------------------------------------------------
; 函数名  : _PKN_PickDone / _PKN_PickOops / _PKN_PickCancel
; 功能    : 拾取右键菜单回调（rvia 实证命名函数串模式）：Done 结束
;           选择；Oops 清空当前选择重新框选；Cancel 置标志退出
;------------------------------------------------------------------------
unless( boundp('_PKN_pickCancel) defvar(_PKN_pickCancel nil))

procedure( _PKN_PickDone()
    axlUIPopupSet(nil)
    axlFinishEnterFun()
)

procedure( _PKN_PickOops()
    axlClearSelSet()
    axlMsgPut("\322\321\307\345\277\325\321\241\324\361, \307\353\326\330\320\302\277\362\321\241")
)

procedure( _PKN_PickCancel()
    _PKN_pickCancel = t
    axlClearSelSet()
    axlUIPopupSet(nil)
    axlCancelEnterFun()
)

;------------------------------------------------------------------------
; 函数名  : ASTB_Place_PackNet
; 功能    : 菜单入口：框选元件 -> 框选目标区域 -> 按网络聚拢密排
;------------------------------------------------------------------------
procedure( ASTB_Place_PackNet()
    prog((sel comps netLists sym box res msg groups)
        axlClearSelSet()
        ;; 过滤模式对齐本项目实证写法（place_inside/gathercomps 同款）
        axlSetFindFilter(?enabled list("noall" "symbols")
                         ?onButtons list("noall" "symbols"))
        ;; v3.3: 右键菜单补 Done/Oops/Cancel（原默认右键只有 snap pick to）
        _PKN_pickCancel = nil
        axlUIPopupSet(axlUIPopupDefine(nil
            list(
                list("Done"   "_PKN_PickDone()")
                list("Oops"   "_PKN_PickOops()")
                list("Cancel" "_PKN_PickCancel()")
            )))
        ;; groupMode t：点选/框选直接生效并累积，Done/Cancel 才返回
        axlSelect(?groupMode t
                  ?prompt "\265\332\322\273\262\275: \265\343\321\241\273\362\277\362\321\241\322\252\276\333\302\243\265\304\324\252\274\376, \315\352\263\311\272\363\323\322\274\374 Done")
        axlUIPopupSet(nil)
        when( _PKN_pickCancel
            axlMsgPut("\322\321\310\241\317\373")
            return(nil)
        )
        sel = axlGetSelSet()
        unless( and(sel listp(sel))
            axlMsgPut("\316\264\321\241\324\361\310\316\272\316\324\252\274\376, \307\353\326\330\320\302\277\362\321\241")
            return(nil)
        )
        ;; v3.7: dbid 不跨轮（17.4 S039 新一轮交互后旧 dbid 全失效）——
        ;; 选择阶段只存 refdes 字符串与网络名纯数据，新鲜 dbid 用完即弃
        comps = nil
        netLists = nil
        foreach( sym sel
            when( sym->refdes
                comps = append1(comps sym->refdes)
                netLists = append1(netLists _PKN_CompNets(sym))
            )
        )
        axlMsgPut("\265\332\266\376\262\275: \307\353\324\332\304\277\261\352\316\273\326\303\277\362\322\273\270\366\307\370\323\362(\327\363\311\317\275\307\277\252\312\274\260\332\267\305)")
        box = axlEnterBox(?prompts list("\277\362\321\241\304\277\261\352\307\370\323\362"))
        unless( and(box listp(box) car(box) cadr(box))
            axlMsgPut("\322\321\310\241\317\373")
            return(nil)
        )
        groups = _PKN_GroupByNet(comps netLists)
        res = ASTB_DBTransactionMark(
            '_PKN_DoPack
            list(comps netLists groups box)
        )
        if( res then
            msg = sprintf(nil "\276\333\302\243\315\352\263\311: %d \270\366\301\254\315\250\327\351, \322\306\266\257 %d \270\366\324\252\274\376, \314\370\271\375 FIXED %d \270\366"
                caddr(res) car(res) cadr(res))
            axlMsgPut(msg)
            when( car(res) > 0
                axlMsgPut("\315\352\263\311\241\243\312\344\310\353 astbundo \277\311\263\267\317\372\261\276\264\316\320\336\270\304")
            )
            return(t)
        else
            axlMsgPut("\276\333\302\243\260\332\267\305\312\247\260\334(\317\352\274\373\303\374\301\356\320\320\314\341\312\276)")
            return(nil)
        )
    )
)

ASTB_RegisterCommand("ASTB_Place_PackNet" "ASTB_Place_PackNet" ?cmdType "interactive")
; 撤销命令（PKN_Undo 定义之后注册）
ASTB_RegisterCommand("ASTB_Place_PackNetu" "PKN_Undo" ?cmdType "general" ?undo nil)
; 统一撤销中枢注册（core/trans.il v1.4）：astbundo 按 LIFO 分发到本函数
ASTB_RegisterUndo("place_packnet" 'PKN_Undo)

printf("[ASTB] place_packnet.il v3.7 loaded (cmdline-msgs).\n")
