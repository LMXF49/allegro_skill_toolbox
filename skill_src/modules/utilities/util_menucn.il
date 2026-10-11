;========================================================================
; 文件名    : modules/utilities/util_menucn.il
; 作者      : ASTB Team
; 创建日期  : 2026-10-11
; 版本      : 1.4
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
;   2026-10-11 v1.4 ASTB Team 实机报错修复：prog 变量初始未绑定，
;                循环每轮显式 zh=nil 重置（unbound variable - zh）
;   2026-10-11 v1.3 ASTB Team 实机异常修复：SKILL 哈希缺键读得
;                'unbound 哨兵（真值），v1.0 守卫失效致全部无映射
;                项被改名 unbound；zh 承接 + neq/stringp 双重校验
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
    prog((path port line p eng zh)
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
                zh = nil
                while( and( p <= strlen(line) null(eng) )
                    when( equal(substring(line p 1) "|") eng = substring(line 1 p-1) )
                    p = p+1
                )
                when( eng
                    zh = substring(line p)
                    ;; gets 保留的行尾 \n / \r 剥掉
                    while( and( strlen(zh) > 0
                                or( equal(substring(zh strlen(zh) 1) "\n")
                                    equal(substring(zh strlen(zh) 1) "\r") ))
                        zh = substring(zh 1 strlen(zh)-1)
                    )
                    when( strlen(zh) > 0
                        ASTB_MENUCN_MAP[eng] = zh
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
; 函数名  : ASTB_MenuCNApply
; 功能    : dump 当前菜单树并逐项改中文标签（仅内存，重启即还原）
; 返回值  : (changed total)；失败 nil
; 备注    : 命令项按命令名定位（位置无关，最稳）；popup 按 dump 缩进
;           层级逐层 axlUIMenuFind(parent pos) 定位；定位失败的 popup
;           标 'dead 切断其子树，防误改；原标签存 ASTB_MENUCN_ORIG
;------------------------------------------------------------------------
procedure( ASTB_MenuCNApply()
    prog((tmp r port line ind body typ lab cmd zh frames frame pos parent
          pending q id r2 changed total)
        unless( _MCN_LoadMap()
            axlUIConfirm("菜单汉化数据缺失: config/menucn_zh.dat")
            return(nil)
        )
        tmp = strcat(getShellEnvVar("TEMP") "\\astb_menudump.txt")
        r = errset(axlUIMenuDump(tmp) t)
        unless( and(r car(r) isFile(tmp))
            axlUIConfirm("菜单 dump 失败，无法汉化")
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
            zh = nil
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
                            equal(lab "Allegro Skill工具箱(&K)") ) then
                        id = 'dead
                    else
                        q = errset(axlUIMenuFind(parent pos) t)
                        id = and(q car(q))
                        unless( id id = 'dead )
                    )
                    zh = and( lab ASTB_MENUCN_MAP[lab] )
                    when( and( id neq(id 'dead) zh neq(zh 'unbound) stringp(zh) )
                        total = total + 1
                        r2 = errset(axlUIMenuChange(id 'display zh) t)
                        when( and(r2 car(r2))
                            changed = changed + 1
                            ASTB_MENUCN_ORIG = cons(list(id lab) ASTB_MENUCN_ORIG)
                        )
                    )
                    pending = list(ind id)
                )
                if( equal(typ 'item) then
                    ;; 命令项按命令名定位（位置无关）
                    zh = and( lab cmd ASTB_MENUCN_MAP[lab] )
                    when( and( zh neq(zh 'unbound) stringp(zh)
                               neq(_MCN_Prefix(cmd 5) "ASTB_") )
                        total = total + 1
                        q = errset(axlUIMenuFind(nil cmd) t)
                        id = and(q car(q))
                        when( id
                            r2 = errset(axlUIMenuChange(id 'display zh) t)
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
                "菜单汉化完成: 已改 %d/%d 项为中文。\n改动仅生效于本次会话（不写文件），重启 Allegro 即还原；\nSystem -> Menu EN 可即时恢复英文。\n动态重建的菜单若回弹英文，再执行一次本命令即可。"
                car(r) cadr(r)))
        )
        return(t)
    )
)

procedure( ASTB_MenuEN()
    prog((n)
        n = ASTB_MenuCNRestore()
        if( n > 0 then
            axlUIConfirm(sprintf(nil "已恢复 %d 个菜单项为英文。\n如有残留，重启 Allegro 即全部复原。" n))
        else
            axlUIConfirm("当前没有已应用的菜单汉化记录。\n重启 Allegro 可复原所有运行期改动。")
        )
        return(t)
    )
)

printf("[ASTB] util_menucn.il v1.4 loaded\n")
