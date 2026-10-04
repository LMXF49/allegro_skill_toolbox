;========================================================================
; 文件名    : modules/utilities/util_search.il
; 作者      : ASTB Team（v2.0 重写；原 Sky Liu 2005 search.il）
; 创建日期  : 2026-08-01
; 版本      : 2.4
; 功能描述  : 搜索定位（Search Star）：筛选框模糊过滤候选列表
;             （器件 refdes / 网络名），单击候选或回车直接
;             缩放定位并高亮；连续查找自动取消上一次高亮。
; 依赖模块  : forms/util_search.form、core/trans.il (ASTB_RegisterCommand)
; 启动命令  : SearchStar（或菜单 Utilities -> Search Star）
; 编码      : GBK（含中文，必须 GBK 保存）
; 修改记录  :
;   2026-08-01 v2.0 ASTB Team 全部重写（v1.x 动态临时表单在本机
;             创建失败不可用）：改静态表单 forms/util_search.form，
;             查找逻辑沿用实证组合 axlSelectByName(REFDES/NET) +
;             axlZoomToDbid + axlHighlightObject；消息全走命令行
;   2026-08-01 v2.1 ASTB Team 新增筛选框+模糊候选列表（子串/
;             尾部*前缀匹配，纯字符串比较无正则）；候选源
;             axlDBGetDesign()->components / ->nets
;   2026-08-01 v2.2 ASTB Team a) 绑定 Ctrl+F（axlSetAlias ~F）；
;             b) 筛选回车只过滤不定位（带 * 才直接定位），单击
;             候选回填输入框；c) 按钮移至候选框正下方并加提示
;   2026-08-01 v2.2.1 ASTB Team 诊断版（临时）：回调入口与 Refill
;             加 [SRCH] printf 探针，新增 SRCH_SLFTEST 无表单自测
;             命令，定位"筛选/单选不生效"根因后移除
;   2026-08-01 v2.3 ASTB Team 实机修复（诊断实证）：过滤/切源计算
;             均正确但屏幕列表不刷新——已填充 LIST 字段直接
;             SetField 不更新显示，必须先 axlFormListDeleteAll
;             （官方 axlform.il 示例模式）；移除诊断探针
;   2026-09-09 v2.4 ASTB Team 修 17.4 跨轮 dbid 失效（S039：新一轮
;             表单回调后旧 dbid 全部变 dbid:removed，去高亮失败
;             残留）：_srchLast 改存 (名字 是否net) 纯数据，
;             _SRCH_Dehighlight 现场 axlSelectByName 重解析后
;             当轮立即 dehighlight、即用即弃
;========================================================================

;------------------------------------------------------------------------
; 全局状态（boundp 保护）
;   _srchForm  表单句柄
;   _srchLast  上一次高亮的身份纯数据 (名字 是否net)（nil = 无）；
;              v2.4 起不存 dbid（17.4 S039 跨轮必失效 dbid:removed）
;------------------------------------------------------------------------
unless( boundp('_srchForm) _srchForm = nil )
unless( boundp('_srchLast) _srchLast = nil )

;------------------------------------------------------------------------
; 函数    : _SRCH_Dehighlight
; 功能    : 取消上一次高亮（如有）
;------------------------------------------------------------------------
procedure( _SRCH_Dehighlight()
    prog( (name isNet foundList)
        when( _srchLast
            ; v2.4: 17.4 S039 下旧 dbid 跨轮必失效（dbid:removed），
            ; _srchLast 存的是 (名字 是否net) 纯数据；现场 axlSelectByName
            ; 重解析出新鲜 dbid，当轮立即 dehighlight、即用即弃
            ; （cvia v1.6 / place_gathercomps v1.7 实证模式）
            name   = car(_srchLast)
            isNet  = cadr(_srchLast)
            axlClearSelSet()
            if( isNet then
                axlSetFindFilter(?enabled '("noall" "nets")
                                 ?onButtons '("noall" "nets"))
                foundList = axlSelectByName("NET" name)
            else
                axlSetFindFilter(?enabled '("noall" "symbols")
                                 ?onButtons '("noall" "symbols"))
                foundList = axlSelectByName("REFDES" name)
            )
            when( foundList
                errset( axlDehighlightObject(car(foundList)) nil )
            )
            axlClearSelSet()
            _srchLast = nil
        )
        return(t)
    )
)

;------------------------------------------------------------------------
; 函数    : _SRCH_Find
; 功能    : 读取表单输入执行一次查找（缩放 + 高亮）
; 参数    : fw  表单句柄
;------------------------------------------------------------------------
;------------------------------------------------------------------------
; 函数    : _SRCH_Match
; 功能    : 模糊匹配（不用正则）：尾部 * 前缀匹配，否则子串匹配；
;           大小写已在调用方统一
;------------------------------------------------------------------------
procedure( _SRCH_Match(name pat)
    prog( (plen nlen i pre hit)
        if( or(null(pat) equal(pat "") equal(pat "*")) then
            return(t)
        )
        plen = strlen(pat)
        if( equal(substring(pat plen 1) "*") then
            pre = substring(pat 1 plen - 1)
            if( equal(pre "") then
                return(t)
            )
            if( strlen(name) < strlen(pre) then
                return(nil)
            )
            return( equal(substring(name 1 strlen(pre)) pre) )
        )
        nlen = strlen(name)
        if( nlen < plen then
            return(nil)
        )
        hit = nil
        for( i 1 nlen - plen + 1
            when( equal(substring(name i plen) pat)
                hit = t
            )
        )
        return(hit)
    )
)

;------------------------------------------------------------------------
; 函数    : _SRCH_Candidates
; 功能    : 候选名全集：器件(refdes) 或 网络名
; 参数    : isNet  t=网络 nil=器件
; 返回    : 排序后的名字列表
;------------------------------------------------------------------------
procedure( _SRCH_Candidates(isNet)
    prog( (res c n)
        res = nil
        if( isNet then
            foreach( n axlDBGetDesign()->nets
                when( n->name
                    res = cons(n->name res)
                )
            )
        else
            foreach( c axlDBGetDesign()->components
                when( c->name
                    res = cons(c->name res)
                )
            )
        )
        return( sort(res 'alphalessp) )
    )
)

;------------------------------------------------------------------------
; 函数    : _SRCH_Refill
; 功能    : 按筛选串重建候选列表（一次性整体传入）
;------------------------------------------------------------------------
procedure( _SRCH_Refill(fw)
    prog( (pat isNet all shown n)
        pat = axlFormGetField(fw "name")
        if( null(pat) then
            pat = ""
        )
        pat = upperCase(pat)
        isNet = axlFormGetField(fw "f_net")
        all = _SRCH_Candidates(isNet)
        shown = nil
        foreach( n all
            when( _SRCH_Match(n pat)
                shown = cons(n shown)
            )
        )
        shown = reverse(shown)
        ; v2.3 关键修复：已填充的 LIST 字段直接 SetField 不刷新显示，
        ; 必须先 axlFormListDeleteAll（官方 axlform.il 示例模式）——
        ; 诊断实证：过滤计算正确(shown=15)但屏幕列表不变
        axlFormListDeleteAll(fw "candlist")
        axlFormSetField(fw "candlist" shown)
        axlFormTitle(fw sprintf(nil "\313\321\313\367\266\250\316\273 - \272\362\321\241 %d \270\366" length(shown)))
        return(t)
    )
)

;------------------------------------------------------------------------
; 函数    : _SRCH_Locate
; 功能    : 按确切名字定位（缩放 + 高亮）
; 参数    : fw  表单句柄 ; name  目标名（已大写）
;------------------------------------------------------------------------
procedure( _SRCH_Locate(fw name)
    prog( (isNet foundList)
        isNet = axlFormGetField(fw "f_net")
        _SRCH_Dehighlight()
        axlClearSelSet()
        if( isNet then
            axlSetFindFilter(?enabled '("noall" "nets")
                             ?onButtons '("noall" "nets"))
            foundList = axlSelectByName("NET" name)
        else
            axlSetFindFilter(?enabled '("noall" "symbols")
                             ?onButtons '("noall" "symbols"))
            foundList = axlSelectByName("REFDES" name)
        )
        if( foundList then
            ; v2.4: dbid 不跨轮——_srchLast 只存 (名字 是否net) 纯数据；
            ; car(foundList) 本轮缩放/高亮即用即弃
            _srchLast = list(name isNet)
            axlZoomToDbid(car(foundList) t)
            axlHighlightObject(car(foundList))
            axlUIWPrint(nil "\322\321\266\250\316\273\262\242\270\337\301\301: %s" name)
            return(t)
        else
            axlUIWPrint(nil "\316\264\325\322\265\275: %s" name)
            return(nil)
        )
    )
)

;------------------------------------------------------------------------
; 函数    : _SRCH_Find
; 功能    : 读取筛选框输入执行定位（精确名或带 * 通配）
;------------------------------------------------------------------------
procedure( _SRCH_Find(fw)
    prog( (name)
        name = axlFormGetField(fw "name")
        if( null(name) then
            name = ""
        )
        name = upperCase(name)
        if( equal(name "") then
            axlUIWPrint(nil "\307\353\312\344\310\353\322\252\262\351\325\322\265\304\306\367\274\376\316\273\272\305\273\362\315\370\302\347\303\373")
            return(nil)
        )
        return( _SRCH_Locate(fw name) )
    )
)

;------------------------------------------------------------------------
; 函数    : _SRCH_Close
; 功能    : 关闭表单并清理（高亮/选择集/shadow）
;------------------------------------------------------------------------
procedure( _SRCH_Close(fw)
    prog( (unused)
        unused = nil
        _SRCH_Dehighlight()
        axlShell("shadow off")
        axlClearSelSet()
        axlCloseFindFilter()
        axlFormClose(fw)
        return(t)
    )
)

;------------------------------------------------------------------------
; 函数    : _SRCH_Callback
; 功能    : 表单回调分发
;------------------------------------------------------------------------
procedure( _SRCH_Callback(fw)
    prog( (item)
        if( nequal(fw->doneState 0) then
            _SRCH_Close(fw)
            return(nil)
        )
        case( fw->curField
            ("name"
                ; 筛选框回车：先刷新候选；输入带 * 时直接定位
                _SRCH_Refill(fw)
                when( rexMatchp("\\*$" fw->curValue)
                    _SRCH_Find(fw)
                )
            )
            ("f_comp"
                _SRCH_Refill(fw)
            )
            ("f_net"
                _SRCH_Refill(fw)
            )
            ("candlist"
                item = fw->curValue
                when( item
                    axlFormSetField(fw "name" item)
                    _SRCH_Locate(fw item)
                )
            )
            ("find"
                _SRCH_Refill(fw)
                _SRCH_Find(fw)
            )
            ("exit"
                _SRCH_Close(fw)
            )
            (t nil)
        )
        return(t)
    )
)

;------------------------------------------------------------------------
; 函数    : SRCH_SLFTEST
; 功能    : 无表单自测（SLFTEST 模式）：打印候选源数量、字段读取、
;           匹配函数结果，用于定位"筛选不生效"根因
; 用法    : 命令行输入 SRCH_SLFTEST
;------------------------------------------------------------------------
procedure( SRCH_SLFTEST()
    prog( (comps nets r)
        printf("[SRCH] SLFTEST begin\n")
        comps = _SRCH_Candidates(nil)
        printf("[SRCH] components candidates: %d, first3: %L\n"
            length(comps) list(car(comps) cadr(comps) caddr(comps)))
        nets = _SRCH_Candidates(t)
        printf("[SRCH] nets candidates: %d, first3: %L\n"
            length(nets) list(car(nets) cadr(nets) caddr(nets)))
        printf("[SRCH] Match(U11 U)=%L Match(R1 U)=%L Match(GND G*)=%L\n"
            _SRCH_Match("U11" "U") _SRCH_Match("R1" "U") _SRCH_Match("GND" "G*"))
        printf("[SRCH] SLFTEST end\n")
        return(t)
    )
)

;------------------------------------------------------------------------
; 函数    : _SearchStar
; 功能    : 命令入口：打开搜索定位表单（单例，已存在则置前）
; 备注    : 入口名保持 _SearchStar，兼容 utilities/zz_wrappers.il
;           的 ASTB_Util_SearchStar 包装（无需改动）
;------------------------------------------------------------------------
procedure( _SearchStar()
    prog( (fw formFile)
        when( _srchForm
            axlUIWExpose(_srchForm)
            return(_srchForm)
        )
        axlClearSelSet()
        _srchLast = nil
        formFile = strcat(ASTB_GLOBAL->FormPath "/util_search.form")
        fw = axlFormCreate('_srchForm formFile '("NE" "msglines" 1)
                           '_SRCH_Callback t nil)
        unless( fw
            axlUIWPrint(nil "ERROR: \261\355\265\245\264\264\275\250\312\247\260\334, \307\353\274\354\262\351 forms/util_search.form")
            return(nil)
        )
        axlFormSetField(fw "name" "")
        axlFormSetField(fw "f_comp" t)
        axlFormSetField(fw "f_net" nil)
        _SRCH_Refill(fw)
        axlFormDisplay(fw)
        axlFormSetActiveField(fw "name")
        return(fw)
    )
)

ASTB_RegisterCommand("SearchStar" '_SearchStar ?cmdType "general" ?undo nil)
ASTB_RegisterCommand("SRCH_SLFTEST" 'SRCH_SLFTEST ?cmdType "general" ?undo nil)

; Ctrl+F 快捷键绑定（~ = Ctrl 字母数字键位指示符，手册 08 章实证）
errset( axlSetAlias("~F" "SearchStar") nil )

printf("[ASTB] utilities/util_search.il v2.4 loaded, command: SearchStar / Ctrl+F\n")
