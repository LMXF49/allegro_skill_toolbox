;========================================================================
; 文件名    : modules/routing/route_automatchgroup.il
; 作者      : allegro_skill 项目组
; 创建日期  : 2026-07-26
; 版本      : 2.3
; 功能描述  : 表单自动创建等长组（仿凡亿布局）：Bus 下拉弹选 Net
;             Group/BUS；From/To 双列表**仅列所选组内网络关联的器件**
;             （组内网络 -> pins -> refdes）；Match Group Name 自动
;             取 组名_from_to（可手改）；Create 建组并把触两端器件
;             的网络加入 + 写 RPD 容差；Refresh/Help/Exit
; 依赖模块  : core/utils.il、core/trans.il
; 编码      : GBK（含中文注释）
; 修改记录  :
;   2026-07-26 v1.0 allegro_skill 项目组 命令行版
;   2026-07-26 v2.0 allegro_skill 项目组 动态表单版
;   2026-07-26 v2.1 allegro_skill 项目组 修复表单布局（Bus 下拉缺
;                     POPUP 声明致渲染错位）；From/To 改为仅列所选
;                     组内器件；组名自动 组名_from_to
;   2026-08-01 v2.2 ASTB Team 表单加高（PORT 30->33），Match Group
;                     Name 行 18->20、误差行 21->23、按钮行 25->28
;   2026-09-09 v2.3 ASTB Team 修 17.4 S039 跨交互轮 dbid 失效：组
;                     dbid 不再入 _amgGroups（只存 type/name 字符串），
;                     _AMG_BusDbid 按名现场 axlSelectByName 重解析、同
;                     回调即用即弃；_amgHilited 改存 refdes/网络名身份
;                     串，dehighlight 现场重解析
;========================================================================

unless(boundp('_amgForm)    _amgForm = nil)
unless(boundp('_amgGroups)  _amgGroups = nil)
unless(boundp('_amgBusSel)  _amgBusSel = nil)
unless(boundp('_amgFrom)    _amgFrom = nil)
unless(boundp('_amgTo)      _amgTo = nil)
unless(boundp('_amgLastTol) _amgLastTol = "50mil")

;------------------------------------------------------------------------
; 函数名  : _AMG_EnumGroups
; 功能    : 枚举设计中的 Net Group 与 BUS
;------------------------------------------------------------------------
procedure( _AMG_EnumGroups()
    prog((out gs typ g dsn members)
        out = nil
        ;; 路径一：axlSelectByName 通配
        foreach( typ '("NET_GROUP" "BUS")
            gs = errset(axlSelectByName(typ "*" t) t)
            when( and(gs car(gs))
                foreach( g car(gs)
                    when( g->name
                        out = cons( list(typ g->name) out )
                    )
                )
            )
        )
        ;; 路径二（兜底）：dsn->netgroup / dsn->bus 直接属性访问
        unless( out
            dsn = axlDBGetDesign()
            members = errset(dsn->netgroup t)
            when( and(members car(members) listp(car(members)))
                foreach( g car(members)
                    when( g->name
                        out = cons( list("NET_GROUP" g->name) out )
                    )
                )
            )
            members = errset(dsn->bus t)
            when( and(members car(members) listp(car(members)))
                foreach( g car(members)
                    when( g->name
                        out = cons( list("BUS" g->name) out )
                    )
                )
            )
        )
        return( reverse(out) )
    )
)

;------------------------------------------------------------------------
; 函数名  : _AMG_PinRefdes
; 功能    : pin -> 所属 refdes（parent->refdes / parent->name 兜底）
;------------------------------------------------------------------------
procedure( _AMG_PinRefdes(p)
    prog((r)
        ;; parent->refdes -> parent->name -> component->name 逐级兜底
        r = errset(p->parent->refdes t)
        when( and(r car(r) car(r) != "")
            return( car(r) )
        )
        r = errset(p->parent->name t)
        when( and(r car(r) car(r) != "")
            return( car(r) )
        )
        r = errset(p->component->name t)
        when( and(r car(r) car(r) != "")
            return( car(r) )
        )
        return(nil)
    )
)

;------------------------------------------------------------------------
; 函数名  : _AMG_GroupRefdes
; 功能    : 取组内全部网络关联的器件位号（去重排序）
;------------------------------------------------------------------------
;; 网络/Xnet 的 pin 枚举：axlPinsOfNet 优先，net->pins 兜底
procedure( _AMG_NetPins(net)
    prog((r)
        r = errset(axlPinsOfNet(net 'pin) t)
        if( and(r car(r) listp(car(r))) then
            return( car(r) )
        )
        r = net->pins
        if( listp(r) then
            return(r)
        else
            return(nil)
        )
    )
)

;; 内联去重：strcmp 逐比（不依赖外部函数，杜绝外部状态干扰）
procedure( _AMG_DedupPush(out ref)
    prog((dup e)
        dup = nil
        foreach( e out
            when( and(stringp(e) strcmp(e ref) == 0)
                dup = t
            )
        )
        if( dup then
            return(out)
        else
            return( cons(ref out) )
        )
    )
)

procedure( _AMG_GroupRefdes(gdbid)
    prog((members out net pins p ref rawCnt)
        out = nil
        rawCnt = 0
        members = gdbid->groupMembers
        foreach( net members
            pins = _AMG_NetPins(net)
            when( listp(pins)
                foreach( p pins
                    ref = _AMG_PinRefdes(p)
                    when( ref
                        ref = ASTB_StringTrim(ref)
                    )
                    when( and(ref stringp(ref) ref != "")
                        rawCnt = rawCnt + 1
                        out = _AMG_DedupPush(out ref)
                    )
                )
            )
        )
        return( sort(out 'alphalessp) )
    )
)

;------------------------------------------------------------------------
; 函数名  : _AMG_RefdesToPins
; 功能    : 位号 -> 元件 pins
;------------------------------------------------------------------------
procedure( _AMG_RefdesToPins(refdes)
    prog((comp sym)
        comp = errset(axlDBFindByName('refdes refdes) t)
        unless( and(comp car(comp))
            return(nil)
        )
        sym = car(comp)->symbol
        if( and(sym listp(sym->pins)) then
            return( sym->pins )
        else
            return(nil)
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : _AMG_NetTouches
; 功能    : 判断网络是否同时挂到两组 pins 上（nil 端不过滤）
;------------------------------------------------------------------------
;; dbid 列表成员判定（eq 同一性比较，strcmp 不适用 dbid）
procedure( _AMG_PinInList(pins p)
    prog((r e)
        r = nil
        foreach( e pins
            when( eq(e p)
                r = t
            )
        )
        return(r)
    )
)

procedure( _AMG_NetTouches(net pinsA pinsB)
    prog((pins hitA hitB p)
        pins = _AMG_NetPins(net)
        unless( listp(pins)
            return(nil)
        )
        hitA = null(pinsA)
        hitB = null(pinsB)
        foreach( p pins
            when( and(pinsA null(hitA) _AMG_PinInList(pinsA p))
                hitA = t
            )
            when( and(pinsB null(hitB) _AMG_PinInList(pinsB p))
                hitB = t
            )
        )
        return( and(hitA hitB) )
    )
)

;------------------------------------------------------------------------
; 函数名  : _AMG_BusName
; 功能    : 从 Bus 标签去掉 " (TYPE)" 后缀取纯组名
;------------------------------------------------------------------------
procedure( _AMG_BusName()
    if( null(_amgBusSel) then
        nil
    else
        substring(_amgBusSel 1 axlLastIndex(_amgBusSel " (")-1)
    )
)

;------------------------------------------------------------------------
; 函数名  : _AMG_AutoName
; 功能    : 自动组名：组名_from_to（两端空则 组名_MG）
;------------------------------------------------------------------------
procedure( _AMG_AutoName()
    prog((bus name)
        bus = _AMG_BusName()
        unless( bus
            return(nil)
        )
        name = bus
        when( and(_amgFrom _amgFrom != "")
            name = strcat(name "_" _amgFrom)
        )
        when( and(_amgTo _amgTo != "")
            name = strcat(name "_" _amgTo)
        )
        when( and(null(_amgFrom) null(_amgTo))
            name = strcat(name "_MG")
        )
        return(name)
    )
)

;------------------------------------------------------------------------
; 函数名  : _AMG_CreateFormFile
; 功能    : 动态生成 Match Group 表单（ENUMSET 带 POPUP 声明）
;------------------------------------------------------------------------
procedure( _AMG_CreateFormFile()
    prog((formFile p)
        formFile = axlTempFile()
        p = outfile(formFile "w")
        unless( p
            axlMsgPut("[AMG] 无法创建临时表单文件")
            return(nil)
        )
        fprintf(p "FILE_TYPE=FORM_DEFN VERSION=2\n")
        fprintf(p "FORM\n")
        fprintf(p "FIXED\n")
        fprintf(p "PORT 50 33\n")
        fprintf(p "HEADER \"\327\324\266\257\264\264\275\250 Match Group V2.2\"\n")
        fprintf(p "TILE\n")
        fprintf(p "TEXT \"Bus:\"\n")
        fprintf(p "TLOC 2 2\nENDTEXT\n")
        fprintf(p "POPUP <buspop> \"\" \"\"\n")
        fprintf(p "FIELD bus_sel\n")
        fprintf(p "FLOC 10 2\n")
        fprintf(p "ENUMSET 36\n")
        fprintf(p "POP \"buspop\"\n")
        fprintf(p "ENDFIELD\n")
        fprintf(p "TEXT \"From:\"\n")
        fprintf(p "TLOC 2 5\nENDTEXT\n")
        fprintf(p "FIELD from_list\n")
        fprintf(p "FLOC 2 7\n")
        fprintf(p "LIST \"\" 22 9\n")
        fprintf(p "ENDFIELD\n")
        fprintf(p "TEXT \"To:\"\n")
        fprintf(p "TLOC 27 5\nENDTEXT\n")
        fprintf(p "FIELD to_list\n")
        fprintf(p "FLOC 27 7\n")
        fprintf(p "LIST \"\" 22 9\n")
        fprintf(p "ENDFIELD\n")
        fprintf(p "TEXT \"Match Group Name:\"\n")
        fprintf(p "TLOC 2 20\nENDTEXT\n")
        fprintf(p "FIELD mg_name\n")
        fprintf(p "FLOC 20 20\n")
        fprintf(p "STRFILLIN 22 32\n")
        fprintf(p "ENDFIELD\n")
        fprintf(p "TEXT \"\316\363\262\356:\"\n")
        fprintf(p "TLOC 2 23\nENDTEXT\n")
        fprintf(p "FIELD tol\n")
        fprintf(p "FLOC 8 23\n")
        fprintf(p "STRFILLIN 8 16\n")
        fprintf(p "ENDFIELD\n")
        fprintf(p "TEXT \"(mil \273\362 %%)\"\n")
        fprintf(p "TLOC 20 23\nENDTEXT\n")
        fprintf(p "FIELD create_btn\n")
        fprintf(p "FLOC 4 28\n")
        fprintf(p "MENUBUTTON \"Create\" 9 4\n")
        fprintf(p "ENDFIELD\n")
        fprintf(p "FIELD refresh_btn\n")
        fprintf(p "FLOC 16 28\n")
        fprintf(p "MENUBUTTON \"Refresh\" 9 4\n")
        fprintf(p "ENDFIELD\n")
        fprintf(p "FIELD help_btn\n")
        fprintf(p "FLOC 28 28\n")
        fprintf(p "MENUBUTTON \"Help\" 9 4\n")
        fprintf(p "ENDFIELD\n")
        fprintf(p "FIELD exit_btn\n")
        fprintf(p "FLOC 40 28\n")
        fprintf(p "MENUBUTTON \"Exit\" 9 4\n")
        fprintf(p "ENDFIELD\n")
        fprintf(p "ENDTILE\n")
        fprintf(p "ENDFORM\n")
        close(p)
        return(formFile)
    )
)

;------------------------------------------------------------------------
; 函数名  : _AMG_FillBus
; 功能    : 仅填充 Bus 下拉（组列表有变时）
;------------------------------------------------------------------------
procedure( _AMG_FillBus(form)
    prog((labels)
        _amgGroups = _AMG_EnumGroups()
        labels = nil
        foreach( g _amgGroups
            labels = cons( strcat(cadr(g) " (" car(g) ")") labels )
        )
        if( labels then
            axlFormBuildPopup(form "bus_sel" reverse(labels))
            axlUIWPrint(form strcat("共 " sprintf(nil "%d" length(labels)) " 个组可选")
        )
        else
            axlUIWPrint(form "没有 Net Group/BUS: 请先在约束管理器创建后点 Refresh")
        )
        return(t)
    )
)

;------------------------------------------------------------------------
; 函数名  : _AMG_BusDbid
; 功能    : 按选中标签现场重解析组 dbid（17.4 S039: dbid 不跨轮，
;           _amgGroups 只存 (type name) 字符串，同一回调内即用即弃）
;------------------------------------------------------------------------
procedure( _AMG_BusDbid()
    prog((typ name gs it)
        typ = nil
        name = nil
        foreach( it _amgGroups
            when( and(_amgBusSel strcmp(strcat(cadr(it) " (" car(it) ")") _amgBusSel) == 0)
                typ = car(it)
                name = cadr(it)
            )
        )
        when( and(typ name)
            gs = errset(axlSelectByName(typ name t) t)
            when( and(gs car(gs) car(car(gs)))
                return( car(car(gs)) )
            )
        )
        return(nil)
    )
)

;------------------------------------------------------------------------
; 函数名  : _AMG_OnBusSel
; 功能    : 选中组后：From/To 列表改列组内器件 + 自动组名
;------------------------------------------------------------------------
procedure( _AMG_OnBusSel(form)
    prog((gdbid refs v)
        ;; 下拉框选中与关闭会各触发一次回调: 关闭时 curValue 变 nil/空,
        ;; 只允许非空字符串覆盖 _amgBusSel, 防止把已选组冲掉
        v = form->curValue
        when( and(v stringp(v) v != "")
            _amgBusSel = v
        )
        gdbid = _AMG_BusDbid()
        refs = if( gdbid then _AMG_GroupRefdes(gdbid) else nil )
        ;; 先清列再填充: axlFormSetField 对 LIST 字段是追加, 不先清会累积重复
        errset(axlFormListDeleteAll(form "from_list") t)
        errset(axlFormListDeleteAll(form "to_list") t)
        axlFormSetField(form "from_list" refs)
        axlFormSetField(form "to_list" refs)
        _amgFrom = nil
        _amgTo = nil
        axlFormSetField(form "mg_name" _AMG_AutoName())
        if( refs then
            axlUIWPrint(form strcat("组内器件 " sprintf(nil "%d" length(refs)) " 个, From/To 留空=不过滤")
        )
        else
            axlUIWPrint(form "该组没有可用器件")
        )
        return(t)
    )
)

;------------------------------------------------------------------------
; 函数名  : _AMG_DoCreate
; 功能    : Create 主逻辑
;------------------------------------------------------------------------
procedure( _AMG_DoCreate(form)
    prog((gdbid fromPins toPins mgName tolStr mg members net added skipped propStr addRet netPins fps tps fp tp pp)
        gdbid = _AMG_BusDbid()
        unless( gdbid
            axlUIWPrint(form "请先在下拉框选择一个 Net Group/BUS")
            return(nil)
        )
        fromPins = if( and(_amgFrom _amgFrom != "") then _AMG_RefdesToPins(_amgFrom) else nil )
        when( and(_amgFrom _amgFrom != "" null(fromPins))
            axlUIWPrint(form strcat("[AMG] 位号 " _amgFrom " 无 pins, 忽略该端过滤"))
            fromPins = nil
        )
        toPins = if( and(_amgTo _amgTo != "") then _AMG_RefdesToPins(_amgTo) else nil )
        when( and(_amgTo _amgTo != "" null(toPins))
            axlUIWPrint(form strcat("[AMG] 位号 " _amgTo " 无 pins, 忽略该端过滤"))
            toPins = nil
        )
        mgName = axlFormGetField(form "mg_name")
        if( or(null(mgName) strcmp(mgName "") == 0) then
            mgName = _AMG_AutoName()
        )
        unless( and(mgName mgName != "")
            axlUIWPrint(form "请填写 Match Group Name")
            return(nil)
        )
        tolStr = axlFormGetField(form "tol")
        unless( and(tolStr tolStr != "")
            tolStr = _amgLastTol
        )
        _amgLastTol = tolStr
        mg = errset(axlMatchGroupCreate(mgName) t)
        unless( and(mg car(mg))
            axlUIWPrint(form strcat("[AMG] 创建失败: " mgName " 已存在或产品级别不支持"))
            return(nil)
        )
        mg = car(mg)
        members = gdbid->groupMembers
        added = 0
        skipped = 0
        if( and(fromPins toPins) then
            ;; ===== Pin Pair 模式(两端均选): 每条网络/Xnet 按端点建引脚对
            foreach( net members
                netPins = _AMG_NetPins(net)
                when( listp(netPins)
                    fps = nil
                    tps = nil
                    foreach( p netPins
                        when( _AMG_PinInList(fromPins p)
                            fps = cons(p fps)
                        )
                        when( _AMG_PinInList(toPins p)
                            tps = cons(p tps)
                        )
                    )
                    if( and(fps tps) then
                        foreach( fp fps
                            foreach( tp tps
                                pp = errset(axlPinPair(fp tp) t)
                                if( and(pp car(pp)) then
                                    pp = car(pp)
                                    addRet = errset(axlMatchGroupAdd(mg pp) t)
                                    when( and(addRet car(addRet))
                                        added = added + 1
                                        propStr = sprintf(nil "%s:G:::0:%s" mgName tolStr)
                                        errset(axlMatchGroupProp(mg pp propStr) t)
                                    )
                                else
                                    skipped = skipped + 1
                                )
                            )
                        )
                    else
                        skipped = skipped + 1
                    )
                )
            )
            axlUIWPrint(form sprintf(nil "[AMG] %s: PinPair 加入 %d, 跳过 %d, 容差 0:%s"
                mgName added skipped tolStr ))
        else
            ;; ===== 整网模式(任一端留空): 原逻辑整网加入
            foreach( net members
                if( _AMG_NetTouches(net fromPins toPins) then
                    addRet = errset(axlMatchGroupAdd(mg net) t)
                    when( and(addRet car(addRet))
                        added = added + 1
                        propStr = sprintf(nil "%s:G:::0:%s" mgName tolStr)
                        errset(axlMatchGroupProp(mg net propStr) t)
                    )
                else
                    skipped = skipped + 1
                )
            )
            axlUIWPrint(form sprintf(nil "[AMG] %s: 加入 %d 网, 跳过 %d, 容差 0:%s"
                mgName added skipped tolStr ))
        )
        when( added == 0
            axlUIWPrint(form "[AMG] 组为空(保存会被删), 请检查 From/To 或换组")
        )
        return(t)
    )
)

;------------------------------------------------------------------------
; 函数名  : _AMG_ShowHelp
; 功能    : Help 按钮
;------------------------------------------------------------------------
procedure( _AMG_ShowHelp()
    prog((f p)
        f = axlTempFile()
        p = outfile(f "w")
        unless( p return(nil) )
        fprintf(p "自动创建 Match Group 用法\n")
        fprintf(p "====================================\n")
        fprintf(p "1. Bus 下拉: 选已建好的 Net Group/BUS(没有请先在 CM 创建, 回来点 Refresh)\n")
        fprintf(p "2. From/To 列表: 只列所选组内网络关联的器件; 不选=不过滤\n")
        fprintf(p "3. Match Group Name: 自动取 组名_from_to, 可手改\n")
        fprintf(p "4. 误差: 50mil 或 5%%\n")
        fprintf(p "5. Create: 只有同时挂到 From/To 两端的网络才会加入, 其余跳过\n")
        close(p)
        axlUIViewFileCreate(f "Match Group Help" t)
        deleteFile(f)
        return(t)
    )
)

;------------------------------------------------------------------------
; 函数名  : _AMG_HiliteRefdes
; 功能    : 选中位号时：取消上次高亮, 高亮新元件并缩放跳转过去
;------------------------------------------------------------------------
unless(boundp('_amgHilited) _amgHilited = nil)

;; 位号 -> symbol dbid
procedure( _AMG_RefSym(refdes)
    prog((comp)
        if( null(refdes) then
            return(nil)
        )
        comp = errset(axlDBFindByName('refdes refdes) t)
        if( and(comp car(comp)) then
            return( car(comp)->symbol )
        else
            return(nil)
        )
    )
)

;; 双端高亮: 两端齐选时高亮两个器件+其共连网络(连线); 单选时仅高亮该器件
;; 17.4 S039: 高亮缓存跨回调即死, _amgHilited 只存 (sym refdes)/(net 网络名)
;; 身份串, dehighlight 时现场重解析、即用即弃
procedure( _AMG_HiliteUpdate()
    prog((old sym netDb gdbid fromSym toSym net fromPins toPins zl hl)
        ;; 先清上次高亮
        foreach( old _amgHilited
            if( eq(car(old) 'sym) then
                sym = _AMG_RefSym(cadr(old))
                when( sym
                    errset(axlDehighlightObject(sym) t)
                )
            else
                netDb = errset(axlSelectByName("NET" cadr(old) t) t)
                when( and(netDb car(netDb) car(car(netDb)))
                    errset(axlDehighlightObject(car(car(netDb))) t)
                )
            )
        )
        _amgHilited = nil
        fromSym = _AMG_RefSym(_amgFrom)
        toSym = _AMG_RefSym(_amgTo)
        if( and(fromSym toSym) then
            ;; 双器件高亮
            errset(axlHighlightObject(fromSym) t)
            errset(axlHighlightObject(toSym) t)
            _amgHilited = list( list('sym _amgFrom) list('sym _amgTo) )
            hl = list(fromSym toSym)
            ;; 两端共连网络高亮(即两器件之间的连线)
            fromPins = _AMG_RefdesToPins(_amgFrom)
            toPins = _AMG_RefdesToPins(_amgTo)
            gdbid = _AMG_BusDbid()
            when( and(gdbid fromPins toPins)
                foreach( net gdbid->groupMembers
                    when( _AMG_NetTouches(net fromPins toPins)
                        errset(axlHighlightObject(net) t)
                        hl = cons(net hl)
                        when( net->name
                            _amgHilited = cons(list('net net->name) _amgHilited)
                        )
                    )
                )
            )
            ;; 缩放到双器件范围(失败退回 From 单点)
            zl = errset(axlZoomToDbid(hl t) t)
            unless( and(zl car(zl))
                errset(axlZoomToDbid(fromSym t) t)
            )
        else
            when( fromSym
                errset(axlHighlightObject(fromSym) t)
                errset(axlZoomToDbid(fromSym t) t)
                _amgHilited = list( list('sym _amgFrom) )
            )
            when( toSym
                errset(axlHighlightObject(toSym) t)
                errset(axlZoomToDbid(toSym t) t)
                _amgHilited = cons(list('sym _amgTo) _amgHilited)
            )
        )
        return(t)
    )
)

;------------------------------------------------------------------------
; 函数名  : _AMG_Callback
; 功能    : 表单回调分发
;------------------------------------------------------------------------
procedure( _AMG_Callback(form)
    prog((field v)
        field = form->curField
        case( field
            ("exit_btn"
                _amgForm = nil
                axlFormClose(form)
            )
            ("refresh_btn"
                _AMG_FillBus(form)
                when( _amgBusSel
                    _AMG_OnBusSel(form)
                )
            )
            ("create_btn"
                _AMG_DoCreate(form)
            )
            ("help_btn"
                _AMG_ShowHelp()
            )
            ("bus_sel"
                _AMG_OnBusSel(form)
            )
            ("from_list"
                ;; LIST 取值优先 axlFormGetField, curValue 兜底
                v = axlFormGetField(form "from_list")
                unless( and(v stringp(v) v != "")
                    v = form->curValue
                )
                _amgFrom = v
                _AMG_HiliteUpdate()
                axlFormSetField(form "mg_name" _AMG_AutoName())
            )
            ("to_list"
                v = axlFormGetField(form "to_list")
                unless( and(v stringp(v) v != "")
                    v = form->curValue
                )
                _amgTo = v
                _AMG_HiliteUpdate()
                axlFormSetField(form "mg_name" _AMG_AutoName())
            )
            (t t)
        )
        t
    )
)

;------------------------------------------------------------------------
; 函数名  : axlLastIndex
; 功能    : 找子串最后一次出现的位置（1 起始；无则返回全长）
;------------------------------------------------------------------------
procedure( axlLastIndex(str sub)
    prog((i hit)
        hit = strlen(str)
        for( i 1 strlen(str)-strlen(sub)+1
            when( strcmp(substring(str i strlen(sub)) sub) == 0
                hit = i
            )
        )
        return(hit)
    )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_Route_AutoMatchGroup
; 功能    : 菜单入口
;------------------------------------------------------------------------
procedure( ASTB_Route_AutoMatchGroup()
    prog((formFile)
        ;; 窗口 X 关闭后句柄失效但 axlIsFormType 可能仍判真，
        ;; 一律先尝试关闭旧句柄再重建，保证可重复打开
        when( _amgForm
            errset(axlFormClose(_amgForm) t)
            _amgForm = nil
        )
        formFile = _AMG_CreateFormFile()
        unless( formFile
            return(nil)
        )
        _amgForm = axlFormCreate((gensym) formFile '("NE" "msglines" 0) '_AMG_Callback t)
        unless( _amgForm
            axlMsgPut("[AMG] 表单创建失败")
            deleteFile(formFile)
            return(nil)
        )
        axlUIWPerm(_amgForm t)
        _AMG_FillBus(_amgForm)
        axlFormDisplay(_amgForm)
        deleteFile(formFile)
        return(t)
    )
)

ASTB_RegisterCommand("ASTB_Route_AutoMatchGroup" "ASTB_Route_AutoMatchGroup" ?cmdType "interactive")

printf("[ASTB] route_automatchgroup.il v2.3 loaded.\n")
