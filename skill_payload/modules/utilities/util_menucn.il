;========================================================================
; 文件名    : modules/utilities/util_menucn.il
; 作者      : ASTB Team
; 创建日期  : 2026-10-11
; 版本      : 1.7
; 功能描述  : Allegro 菜单栏运行期汉化（主要面向 16.6——其 .men 读取器
;             拒绝 GBK 高位字节、也不认八进制转义，文件级汉化实机
;             两连证实不可行；机制与网上 ConvertMenuToCn.il 同类）：
;             axlUIMenuDump 解析当前菜单树，命令项按命令名
;             axlUIMenuFind 定位后 axlUIMenuChange 'display 改中文，
;             popup 按 dump 位置逐层定位改标签；改动只在内存，
;             重启 Allegro 即还原，ASTB_MenuEN 也可即时恢复英文
;             （恢复靠应用时记录的 id->英文原标签表）。
;             已知局限：动态重建的菜单项会回弹英文（重新执行命令
;             即可）；右键 popup 不涉及（axlUIPopupDefine 禁 GBK）。
; 依赖模块  : core/utils.il（日志）、core/menu.il（ASTB_DumpLeadingSpaces）
; 编码      : GBK（含中文字符串）
; 修改记录  :
;   2026-10-11 v1.7 ASTB Team 根因修复：16.6 哈希缺键读返回未绑定
;                标记且经赋值传染（zh/mcnZh/v 三连报错同因，
;                menu.il v2.1 早有同款记录），_MCN_MapZh 改
;                boundp+stringp 双重防御
;   2026-10-11 v1.6 ASTB Team 回归 v1.2 结构：删 mcnZh 承接变量
;                （v1.5 报错跟名走，实锤承接写法问题），哨兵防御
;                收进单变量 helper _MCN_MapZh，prog 变量降回 19 个
;   2026-10-11 v1.5 ASTB Team 判别实验：模块内 zh 全改名 mcnZh，
;                区分 unbound 报错来自本模块还是外部回调
;   2026-10-11 v1.4 ASTB Team 实机报错修复：prog 变量初始未绑定，
;                循环每轮显式 mcnZh=nil 重置（unbound variable - mcnZh）
;   2026-10-11 v1.3 ASTB Team 实机异常修复：SKILL 哈希缺键读得
;                'unbound 哨兵（真值），v1.0 守卫失效致全部无映射
;                项被改名 unbound；mcnZh 承接 + neq/stringp 双重校验
;   2026-10-11 v1.2 ASTB Team 实机异常修复：整棵跳过 ASTB 自身
;                菜单子树（顶层 popup 标签匹配即 'dead），并跳过
;                ASTB_ 前缀命令项（&Help 与 Cadence 撞名被误改）
;   2026-10-11 v1.1 ASTB Team 实机报错修复：SKILL cons 第二参数
;                必须是 list（type template "gl"），原标签记录
;                改存二元 list，恢复端 cdr 改 cadr
;   2026-10-11 v1.0 ASTB Team 初始创建（翻译数据 config/menucn_zh.dat：
;                473 条官方中文按命令对齐自 17.4 中文 dump，98 条手工
;                翻译补齐；共 571 条 英文标签|中文标签）
;========================================================================

;------------------------------------------------------------------------
; 函数名  : _MCN_Prefix / _MCN_NthQuoted
; 功能    : 行解析小工具：安全取前 n 字符 / 取第 n 对引号内容
;------------------------------------------------------------------------
procedure( _MCN_Prefix(body n)
    if( strlen(body) >= n then substring(body 1 n) else body )
)

procedure( _MCN_NthQuoted(line n)
    prog((i len start count ch)
        len = strlen(line)
        i = 1
        count = 0
        start = 0
        while( i <= len
            ch = substring(line i 1)
            when( equal(ch "\"")
                if( start == 0 then
                    start = i
                else
                    count = count + 1
                    if( count == n then
                        return( substring(line start+1 i-start-1) )
                    )
                    start = 0
                )
            )
            i = i+1
        )
        return(nil)
    )
)

;------------------------------------------------------------------------
; 函数名  : _MCN_LoadMap
; 功能    : 读 config/menucn_zh.dat（GBK，每行 英文标签|中文标签）
;           到哈希表 ASTB_MENUCN_MAP；已加载则直接复用
; 返回值  : 表 / nil（文件打不开）
;------------------------------------------------------------------------
procedure( _MCN_LoadMap()
    prog((path port line p eng mcnZh)
        when( and(boundp('ASTB_MENUCN_MAP) ASTB_MENUCN_MAP)
            return(ASTB_MENUCN_MAP)
        )
        path = strcat(ASTB_GLOBAL->ConfigPath "/menucn_zh.dat")
        port = infile(path)
        unless( port
            ASTB_LogError(strcat("menucn: cannot open " path))
            return(nil)
        )
        ASTB_MENUCN_MAP = makeTable('ASTB_MENUCN_MAP)
        while( gets(line port)
            unless( or(equal(line "") equal(_MCN_Prefix(line 1) "#"))
                p = 1
                eng = nil
                mcnZh = nil
                while( and( p <= strlen(line) null(eng) )
                    when( equal(substring(line p 1) "|") eng = substring(line 1 p-1) )
                    p = p+1
                )
                when( eng
                    mcnZh = substring(line p)
                    ;; gets 保留的行尾 \n / \r 剥掉
                    while( and( strlen(mcnZh) > 0
                                or( equal(substring(mcnZh strlen(mcnZh) 1) "\n")
                                    equal(substring(mcnZh strlen(mcnZh) 1) "\r") ))
                        mcnZh = substring(mcnZh 1 strlen(mcnZh)-1)
                    )
                    when( strlen(mcnZh) > 0
                        ASTB_MENUCN_MAP[eng] = mcnZh
                    )
                )
            )
        )
        close(port)
        ASTB_LogInfo(sprintf(nil "menucn: map loaded from %s" path))
        return(ASTB_MENUCN_MAP)
    )
)

;------------------------------------------------------------------------
; 函数名  : _MCN_MapZh
; 功能    : 查映射：命中返回中文标签；缺键/'unbound/非字符串返回 nil
; 备注    : 16.6 缺键读返回未绑定标记且经赋值传染（v1.3~v1.6
;           连环报错根因），先 boundp 再读值，双重防御
;------------------------------------------------------------------------
procedure( _MCN_MapZh(lab)
    prog((v)
        ;; 16.6 缺键读返回未绑定标记且经赋值传染，先 boundp 再读值
        v = and( lab ASTB_MENUCN_MAP[lab] )
        if( and( boundp('v) stringp(v) ) then
            return( v )
        else
            return( nil )
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_MenuCNApply
; 功能    : dump 当前菜单树并逐项改中文标签（仅内存，重启即还原）
; 返回值  : (changed total)；失败 nil
; 备注    : 命令项按命令名定位（位置无关，最稳）；popup 按 dump 缩进
;           层级逐层 axlUIMenuFind(parent pos) 定位；定位失败的 popup
;           标 'dead 切断其子树，防误改；原标签存 ASTB_MENUCN_ORIG
;------------------------------------------------------------------------
procedure( ASTB_MenuCNApply()
    prog((tmp r port line ind body typ lab cmd frames frame pos parent
          pending q id r2 changed total)
        unless( _MCN_LoadMap()
            axlUIConfirm("\262\313\265\245\272\272\273\257\312\375\276\335\310\261\312\247: config/menucn_zh.dat")
            return(nil)
        )
        tmp = strcat(getShellEnvVar("TEMP") "\\astb_menudump.txt")
        r = errset(axlUIMenuDump(tmp) t)
        unless( and(r car(r) isFile(tmp))
            axlUIConfirm("\262\313\265\245 dump \312\247\260\334\243\254\316\336\267\250\272\272\273\257")
            return(nil)
        )
        ASTB_MENUCN_ORIG = nil
        changed = 0
        total = 0
        frames = list(list(-1 nil 0))   ;; (缩进 父id 子计数)，根帧父=nil
        pending = nil                   ;; 刚处理的 popup (缩进 id)
        port = infile(tmp)
        while( gets(line port)
            ind = ASTB_DumpLeadingSpaces(line)
            body = substring(line ind+1)
            typ = nil
            lab = nil
            cmd = nil
            if( equal(_MCN_Prefix(body 5) "POPUP") then
                typ = 'popup
                lab = _MCN_NthQuoted(body 1)
            else
                when( equal(_MCN_Prefix(body 8) "MENUITEM")
                    if( rexMatchp("SEPARATOR" body) then
                        typ = 'sep
                    else
                        typ = 'item
                        lab = _MCN_NthQuoted(body 1)
                        cmd = _MCN_NthQuoted(body 2)
                    )
                )
            )
            when( typ
                ;; 层级维护：进入子级 / 退回上级
                when( and(pending ind > car(pending))
                    frames = cons(list(ind cadr(pending) 0) frames)
                    pending = nil
                )
                while( and(cdr(frames) ind < caar(frames))
                    frames = cdr(frames)
                )
                frame = car(frames)
                pos = caddr(frame)
                rplaca(cddr(frame) pos+1)
                parent = cadr(frame)
                if( equal(typ 'popup) then
                    ;; popup 按位置定位（父帧为 'dead 则继承，不查不改；
                    ;; ASTB 自身顶层 popup 整棵跳过）
                    if( or( equal(parent 'dead)
                            equal(lab "allegro_s&kill_toolbox")
                            equal(lab "Allegro Skill\271\244\276\337\317\344(&K)") ) then
                        id = 'dead
                    else
                        q = errset(axlUIMenuFind(parent pos) t)
                        id = and(q car(q))
                        unless( id id = 'dead )
                    )
                    when( and( id neq(id 'dead) _MCN_MapZh(lab) )
                        total = total + 1
                        r2 = errset(axlUIMenuChange(id 'display _MCN_MapZh(lab)) t)
                        when( and(r2 car(r2))
                            changed = changed + 1
                            ASTB_MENUCN_ORIG = cons(list(id lab) ASTB_MENUCN_ORIG)
                        )
                    )
                    pending = list(ind id)
                )
                if( equal(typ 'item) then
                    ;; 命令项按命令名定位（位置无关）
                    when( and( _MCN_MapZh(lab)
                               neq(_MCN_Prefix(cmd 5) "ASTB_") )
                        total = total + 1
                        q = errset(axlUIMenuFind(nil cmd) t)
                        id = and(q car(q))
                        when( id
                            r2 = errset(axlUIMenuChange(id 'display _MCN_MapZh(lab)) t)
                            when( and(r2 car(r2))
                                changed = changed + 1
                                ASTB_MENUCN_ORIG = cons(list(id lab) ASTB_MENUCN_ORIG)
                            )
                        )
                    )
                )
            )
        )
        close(port)
        ASTB_LogInfo(sprintf(nil "menucn: applied %d/%d" changed total))
        return( list(changed total) )
    )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_MenuCNRestore
; 功能    : 按 ASTB_MENUCN_ORIG 记录把标签改回英文
; 返回值  : 恢复条数
;------------------------------------------------------------------------
procedure( ASTB_MenuCNRestore()
    prog((pair r n)
        n = 0
        when( and(boundp('ASTB_MENUCN_ORIG) ASTB_MENUCN_ORIG)
            foreach( pair ASTB_MENUCN_ORIG
                r = errset(axlUIMenuChange(car(pair) 'display cadr(pair)) t)
                when( and(r car(r)) n = n+1 )
            )
            ASTB_MENUCN_ORIG = nil
        )
        ASTB_LogInfo(sprintf(nil "menucn: restored %d" n))
        return(n)
    )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_MenuCN / ASTB_MenuEN
; 功能    : 菜单汉化 / 恢复英文 命令入口（System 菜单）
; 返回值  : t
;------------------------------------------------------------------------
procedure( ASTB_MenuCN()
    prog((r)
        r = ASTB_MenuCNApply()
        if( r then
            axlUIConfirm(sprintf(nil
                "\262\313\265\245\272\272\273\257\315\352\263\311: \322\321\270\304 %d/%d \317\356\316\252\326\320\316\304\241\243\n\270\304\266\257\275\366\311\372\320\247\323\332\261\276\264\316\273\341\273\260\243\250\262\273\320\264\316\304\274\376\243\251\243\254\326\330\306\364 Allegro \274\264\273\271\324\255\243\273\nSystem -> Menu EN \277\311\274\264\312\261\273\326\270\264\323\242\316\304\241\243\n\266\257\314\254\326\330\275\250\265\304\262\313\265\245\310\364\273\330\265\257\323\242\316\304\243\254\324\331\326\264\320\320\322\273\264\316\261\276\303\374\301\356\274\264\277\311\241\243"
                car(r) cadr(r)))
        )
        return(t)
    )
)

procedure( ASTB_MenuEN()
    prog((n)
        n = ASTB_MenuCNRestore()
        if( n > 0 then
            axlUIConfirm(sprintf(nil "\322\321\273\326\270\264 %d \270\366\262\313\265\245\317\356\316\252\323\242\316\304\241\243\n\310\347\323\320\262\320\301\364\243\254\326\330\306\364 Allegro \274\264\310\253\262\277\270\264\324\255\241\243" n))
        else
            axlUIConfirm("\265\261\307\260\303\273\323\320\322\321\323\246\323\303\265\304\262\313\265\245\272\272\273\257\274\307\302\274\241\243\n\326\330\306\364 Allegro \277\311\270\264\324\255\313\371\323\320\324\313\320\320\306\332\270\304\266\257\241\243")
        )
        return(t)
    )
)

printf("[ASTB] util_menucn.il v1.7 loaded\n")
