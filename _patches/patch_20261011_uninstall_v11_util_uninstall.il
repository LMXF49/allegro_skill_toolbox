;========================================================================
; 文件名    : modules/utilities/util_uninstall.il
; 作者      : ASTB Team
; 创建日期  : 2026-10-11
; 版本      : 1.1
; 功能描述  : 从 Allegro 内卸载 ASTB 工具箱：剥离全部可发现的
;             allegro.ilinit 中的 ASTB 加载块（%HOME%\pcbenv 用户级 +
;             Cadence site 级；安装器标记块直接剥离，手工编写的无
;             标记加载段经括号配平提取并弹行号二次确认后删除，原件
;             均备份 .astb_bak）、从 FORMPATH/BITMAPPATH/BMPPATH
;             摘除本工具箱 forms 路径、移除当前会话已注入的菜单并
;             禁止本会话自愈重注入。重启 Allegro 后彻底不加载；
;             程序文件保留在安装目录，需删文件时运行安装版
;             unins000.exe 或手动删除目录
; 依赖模块  : core/trans.il（ASTB_RegisterCommand）、
;             core/utils.il（ASTB_StringTrim/ASTB_StringInList）、
;             core/menu.il（ASTB_PurgeToolboxMenu / ASTB_UNINSTALLED）
; 编码      : GBK（含中文字符串）
; 修改记录  :
;   2026-10-11 v1.0 ASTB Team 初始创建（用户要求：菜单加卸载功能）
;   2026-10-11 v1.1 ASTB Team 实机反馈修复（卸载后重启菜单仍在）：
;                手工编写的 ilinit 加载段无安装器标记，旧版报
;                "无加载块"跳过等于没卸；新增 _UNI_StripLegacy
;                括号配平语句提取（掩码字符串/注释算深度，原文行
;                做内容匹配防 main.il 字符串被掩掉）；site ilinit
;                发现从仅 CDSROOT 扩为 CDS_SITE / CDSROOT / PATH
;                反推 tools 根 / 盘符扫描 Cadence\SPB_*（对齐
;                安装器 ScanAllegroVersions）
;========================================================================

;------------------------------------------------------------------------
; 函数名  : _UNI_GetEnv
; 功能    : getShellEnvVar 的 errset 包装（未设置/异常/空串返回 nil）
; 参数    : name - 环境变量名
; 返回值  : 变量值字符串 / nil
;------------------------------------------------------------------------
procedure( _UNI_GetEnv(name)
    prog((r)
        r = errset(getShellEnvVar(name) t)
        if( and(r car(r) stringp(car(r)) strlen(car(r)) > 0)
        then
            return(car(r))
        else
            return(nil)
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : _UNI_ParentDir
; 功能    : 取路径的上一级目录（"/" 分隔；无上一级返回 ""）
;------------------------------------------------------------------------
procedure( _UNI_ParentDir(p)
    prog((parts out)
        parts = parseString(p "/")
        unless( and(parts cdr(parts)) return("") )
        out = car(parts)
        parts = cdr(parts)
        while( cdr(parts)
            out = strcat(out "/" car(parts))
            parts = cdr(parts)
        )
        return(out)
    )
)

;------------------------------------------------------------------------
; 函数名  : _UNI_NormPath
; 功能    : 路径归一化用于比较：反斜杠归一为 /、去尾部 /、转小写
;------------------------------------------------------------------------
procedure( _UNI_NormPath(p)
    prog((parts out x)
        parts = parseString(p "\\")
        out = ""
        foreach( x parts
            if( equal(out "")
            then out = x
            else out = strcat(out "/" x)
            )
        )
        while( and(strlen(out) > 0 equal(substring(out strlen(out) 1) "/"))
            out = substring(out 1 strlen(out) - 1)
        )
        return(lowerCase(out))
    )
)

;------------------------------------------------------------------------
; 函数名  : _UNI_StrFind
; 功能    : 子串查找（不依赖正则）
; 返回值  : 位置（1 起始）；未找到返回 nil
;------------------------------------------------------------------------
procedure( _UNI_StrFind(str sub)
    prog((n m i)
        n = strlen(str)
        m = strlen(sub)
        if( or(m == 0 m > n) then return(nil) )
        for( i 1 n - m + 1
            when( equal(substring(str i m) sub)
                return(i)
            )
        )
        return(nil)
    )
)

;------------------------------------------------------------------------
; 函数名  : _UNI_MaskCode
; 功能    : 掩码一行代码：字符串内容整体丢弃（转义感知，\" 不终止
;           字符串），分号注释截断；只保留结构字符供括号配平
; 参数    : line - 原始行
; 返回值  : 掩码后的行
; 备注    : 内容匹配（ASTB_INSTALL_DIR/main.il）必须走原文行——
;           "/main.il" 在字符串里，掩码行上查不到
;------------------------------------------------------------------------
procedure( _UNI_MaskCode(line)
    prog((n i ch out inStr)
        n = strlen(line)
        out = ""
        inStr = nil
        i = 1
        while( i <= n
            ch = substring(line i 1)
            cond(
                ( inStr
                    ;; 转义吞下一字符；串内字符一律不进结果
                    when( equal(ch "\\")
                        i = i + 1
                    )
                    when( equal(ch "\"")
                        inStr = nil
                    )
                )
                ( equal(ch ";")
                    return(out)
                )
                ( equal(ch "\"")
                    inStr = t
                )
                ( t
                    out = strcat(out ch)
                )
            )
            i = i + 1
        )
        return(out)
    )
)

;------------------------------------------------------------------------
; 函数名  : _UNI_FindLegacyBlock
; 功能    : 在 ilinit 行列表中定位手工编写的 ASTB 加载段：
;           触发行（含 ASTB_INSTALL_DIR，或 main.il + allegro_skill/
;           skill_payload/ASTB 标识，纯注释行不触发）-> 按行首括号
;           深度向上走到语句起点、向下走到配平闭合 -> 校验块内同时
;           出现 ASTB 标识与 main.il -> 向上吃掉直接相邻的注释块头
; 返回值  : (起点行 终点行)（0 起下标）；未找到/无法界定返回 nil
; 备注    : 宁可返回 nil（调用方提示手工处理）也不误删他人代码
;------------------------------------------------------------------------
procedure( _UNI_FindLegacyBlock(lines)
    prog((masked depths d i k n hit j e line ch raw hasMain hasAstb)
        n = length(lines)
        ;; 1) 逐行掩码 + 记录行首括号深度
        masked = nil
        depths = nil
        d = 0
        foreach( line lines
            masked = cons(_UNI_MaskCode(line) masked)
            depths = cons(d depths)
            for( k 1 strlen(car(masked))
                ch = substring(car(masked) k 1)
                when( equal(ch "(") d = d + 1 )
                when( equal(ch ")") d = d - 1 )
            )
        )
        masked = reverse(masked)
        depths = reverse(depths)
        ;; 2) 找触发行（原文匹配，纯注释行跳过）
        hit = nil
        for( i 0 n - 1
            when( null(hit)
                raw = nth(i lines)
                line = nth(i masked)
                raw = ASTB_StringTrim(raw)
                when( and(strlen(raw) > 0 not(equal(substring(raw 1 1) ";")))
                    when( or( _UNI_StrFind(nth(i lines) "ASTB_INSTALL_DIR")
                              and( _UNI_StrFind(nth(i lines) "main.il")
                                   or( _UNI_StrFind(nth(i lines) "allegro_skill")
                                       _UNI_StrFind(nth(i lines) "skill_payload") ) ))
                        hit = i
                    )
                )
            )
        )
        unless( hit return(nil) )
        ;; 3) 向上走到语句起点（行首深度 0）
        j = hit
        while( and(j > 0 nth(j depths) > 0)
            j = j - 1
        )
        ;; 4) 向下走到语句配平闭合
        d = 0
        e = nil
        for( k j n - 1
            when( null(e)
                line = nth(k masked)
                for( i 1 strlen(line)
                    ch = substring(line i 1)
                    when( equal(ch "(") d = d + 1 )
                    when( equal(ch ")") d = d - 1 )
                )
                when( d <= 0 e = k )
            )
        )
        unless( e return(nil) )
        ;; 5) 校验块内同时出现 ASTB 标识与 main.il 加载（原文行）
        hasMain = nil
        hasAstb = nil
        for( k j e
            raw = nth(k lines)
            when( _UNI_StrFind(raw "main.il") hasMain = t )
            when( or( _UNI_StrFind(raw "ASTB_INSTALL_DIR")
                      _UNI_StrFind(raw "allegro_skill")
                      _UNI_StrFind(raw "skill_payload") )
                hasAstb = t
            )
        )
        unless( and(hasMain hasAstb) return(nil) )
        ;; 6) 向上吃掉直接相邻的注释行（块头说明），空行/代码行即止
        while( and( j > 0
                    let((t) t = ASTB_StringTrim(nth(j - 1 lines))
                        and(strlen(t) > 0 equal(substring(t 1 1) ";")) ))
            j = j - 1
        )
        return( list(j e) )
    )
)

;------------------------------------------------------------------------
; 函数名  : _UNI_ReadLines / _UNI_WriteLines
; 功能    : 读/写文本文件行列表；写盘行尾统一 LF（SKILL reader
;           兼容，项目纪律禁止残留 \r）
; 返回值  : ReadLines 返回行列表（空文件返回 nil，与读取异常的
;           'readerror 符号区分）；WriteLines 返回 t/nil
;------------------------------------------------------------------------
procedure( _UNI_ReadLines(path)
    prog((port line lines)
        port = errset(infile(path) t)
        unless( and(port car(port)) return('readerror) )
        port = car(port)
        lines = nil
        while( gets(line port)
            lines = cons(line lines)
        )
        close(port)
        return( reverse(lines) )
    )
)

procedure( _UNI_WriteLines(path lines)
    prog((wr)
        wr = errset(
            prog((wp l2)
                wp = outfile(path "w")
                unless( wp return(nil) )
                foreach( l2 lines
                    fprintf(wp "%s\n" l2)
                )
                close(wp)
                return(t)
            )
            t
        )
        return( and(wr car(wr)) )
    )
)

;------------------------------------------------------------------------
; 函数名  : _UNI_Backup
; 功能    : 备份 ilinit 原件为 <file>.astb_bak；备份已存在时保留
;           最早原件不覆盖；失败仅命令行告警不阻断
;------------------------------------------------------------------------
procedure( _UNI_Backup(path lines)
    prog((bak)
        bak = strcat(path ".astb_bak")
        unless( isFile(bak)
            unless( _UNI_WriteLines(bak lines)
                axlUIWPrint(nil strcat("[ASTB] WARN: ilinit 备份失败: " bak))
            )
        )
        nil
    )
)

;------------------------------------------------------------------------
; 函数名  : _UNI_StripIlinit
; 功能    : 剥离指定 allegro.ilinit 中的安装器标记块
;           （;; >>> ASTB TOOLBOX BEGIN >>> 至
;             ;; <<< ASTB TOOLBOX END <<< 整段，与安装器同款标记）
; 参数    : path - ilinit 全路径
; 返回值  : stripped - 已剥离写回；noblock - 无标记块未改动；
;           nofile - 文件不存在；error - 读写异常
; 备注    : 缺 END 标记时丢弃 BEGIN 之后全部内容（损坏块按整块处理）
;------------------------------------------------------------------------
procedure( _UNI_StripIlinit(path)
    prog((lines out line inBlock n)
        unless( isFile(path)
            return('nofile)
        )
        lines = _UNI_ReadLines(path)
        when( eq(lines 'readerror)
            return('error)
        )
        inBlock = nil
        out = nil
        n = 0
        foreach( line lines
            cond(
                ( rexMatchp(".*>>> ASTB TOOLBOX BEGIN >>>" line)
                    inBlock = t
                    n = n + 1
                )
                ( rexMatchp(".*<<< ASTB TOOLBOX END <<<" line)
                    inBlock = nil
                    n = n + 1
                    ;; 安装器合成时块前补的空行一并去掉
                    when( and(out equal(car(out) ""))
                        out = cdr(out)
                    )
                )
                ( inBlock
                    n = n + 1
                )
                ( t
                    out = cons(line out)
                )
            )
        )
        unless( n > 0
            return('noblock)
        )
        out = reverse(out)
        _UNI_Backup(path lines)
        if( _UNI_WriteLines(path out)
        then
            return('stripped)
        else
            return('error)
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : _UNI_StripLegacy
; 功能    : 处理手工编写的无标记 ASTB 加载段：定位后弹确认框
;           （显示文件与行号范围），用户同意才删除并备份
; 返回值  : stripped / skipped(用户保留) / nolegacy / nofile / error
;------------------------------------------------------------------------
procedure( _UNI_StripLegacy(path)
    prog((lines blk j e yes idx out)
        unless( isFile(path)
            return('nofile)
        )
        lines = _UNI_ReadLines(path)
        when( eq(lines 'readerror)
            return('error)
        )
        blk = _UNI_FindLegacyBlock(lines)
        unless( blk
            return('nolegacy)
        )
        j = car(blk)
        e = cadr(blk)
        yes = axlUIYesNo(
            sprintf(nil "%s\n\n发现手工编写的 ASTB 加载段（第 %d ~ %d 行）：\n  %s\n  ...\n\n删除该段？"
                path j + 1 e + 1 nth(j lines))
            "ASTB Uninstall" 'no)
        unless( yes
            return('skipped)
        )
        out = nil
        for( idx 0 length(lines) - 1
            unless( and(idx >= j idx <= e)
                out = cons(nth(idx lines) out)
            )
        )
        out = reverse(out)
        _UNI_Backup(path lines)
        if( _UNI_WriteLines(path out)
        then
            return('stripped)
        else
            return('error)
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : _UNI_StripOne
; 功能    : 对单个 ilinit 依次尝试安装器标记块剥离与手工段处理，
;           返回中文结果摘要（汇总提示用）
;------------------------------------------------------------------------
procedure( _UNI_StripOne(path)
    prog((st st2 txt)
        st = _UNI_StripIlinit(path)
        st2 = nil
        ;; 标记块处理完（或本无标记块）后，再扫一遍手工段：
        ;; 同一文件可能两种块并存
        when( or(eq(st 'stripped) eq(st 'noblock))
            st2 = _UNI_StripLegacy(path)
        )
        txt = cond(
            ( and(eq(st 'stripped) eq(st2 'stripped))
                "已剥离安装器标记块，并删除手工加载段（备份 .astb_bak）" )
            ( and(eq(st 'stripped) eq(st2 'skipped))
                "已剥离安装器标记块；另有手工加载段，用户选择保留" )
            ( eq(st 'stripped)
                "已剥离安装器标记块（备份 .astb_bak）" )
            ( eq(st2 'stripped)
                "已删除手工加载段（备份 .astb_bak）" )
            ( eq(st2 'skipped)
                "存在手工加载段，用户选择保留" )
            ( eq(st 'noblock)
                "无 ASTB 加载块，未改动" )
            ( eq(st 'nofile)
                "文件不存在，跳过" )
            ( t
                "处理失败（详见命令行）" )
        )
        return(txt)
    )
)

;------------------------------------------------------------------------
; 函数名  : _UNI_SiteIlinits
; 功能    : 发现全部 Cadence site 级 allegro.ilinit 候选：
;           CDS_SITE 直指 / CDSROOT / PATH 中 tools 目录反推根 /
;           盘符 C..Z 扫描 Cadence\SPB_*（对齐安装器
;           ScanAllegroVersions，要求 tools 下有 allegro.exe 才采信）
; 返回值  : 存在的 site ilinit 路径列表（去重）；取不到返回 nil
;------------------------------------------------------------------------
procedure( _UNI_SiteIlinits()
    prog((cands csite cds pth entry e2 pos root drvStr di base names nm
          exe1 exe2 out seen cand)
        cands = nil
        ;; 1) CDS_SITE 直指 site skill 目录
        csite = _UNI_GetEnv("CDS_SITE")
        when( csite
            cands = cons(strcat(csite "/allegro.ilinit") cands)
        )
        ;; 2) CDSROOT
        cds = _UNI_GetEnv("CDSROOT")
        when( cds
            cands = cons(strcat(cds "/share/local/pcb/skill/allegro.ilinit") cands)
        )
        ;; 3) PATH 反推：含 /tools/ 的条目取其前缀为 Cadence 根
        pth = _UNI_GetEnv("PATH")
        when( pth
            foreach( entry parseString(pth ";")
                e2 = _UNI_NormPath(entry)
                pos = _UNI_StrFind(e2 "/tools/")
                when( pos
                    root = substring(e2 1 pos - 1)
                    cands = cons(strcat(root "/share/local/pcb/skill/allegro.ilinit") cands)
                )
            )
        )
        ;; 4) 盘符扫描 <盘>:/Cadence/SPB_*（对齐安装器探测逻辑）
        drvStr = "CDEFGHIJKLMNOPQRSTUVWXYZ"
        for( di 1 24
            base = strcat(substring(drvStr di 1) ":/Cadence")
            when( isDir(base)
                names = errset(getDirFiles(base) t)
                when( and(names car(names) listp(car(names)))
                    foreach( nm car(names)
                        when( and(stringp(nm) strlen(nm) >= 4
                                  equal(lowerCase(substring(nm 1 4)) "spb_"))
                            exe1 = strcat(base "/" nm "/tools/bin/allegro.exe")
                            exe2 = strcat(base "/" nm "/tools/pcb/bin/allegro.exe")
                            when( or(isFile(exe1) isFile(exe2))
                                cands = cons(strcat(base "/" nm
                                    "/share/local/pcb/skill/allegro.ilinit") cands)
                            )
                        )
                    )
                )
            )
        )
        ;; 去重（归一化比较）+ 只留真实存在的文件
        out = nil
        seen = nil
        foreach( cand cands
            when( and(isFile(cand)
                      null(ASTB_StringInList(_UNI_NormPath(cand) seen)))
                seen = cons(_UNI_NormPath(cand) seen)
                out = cons(cand out)
            )
        )
        return( reverse(out) )
    )
)

;------------------------------------------------------------------------
; 函数名  : _UNI_CleanEnvPaths
; 功能    : 从 FORMPATH/BITMAPPATH/BMPPATH 摘除本工具箱 forms 路径
;           （axlSetVariable 会持久化进 Allegro env，须显式摘除，
;           否则卸载后 env 仍残留失效路径）
; 返回值  : 实际清理的变量个数（best-effort，单项异常不中断）
;------------------------------------------------------------------------
procedure( _UNI_CleanEnvPaths()
    prog((target v cur kept item changed cnt)
        target = _UNI_NormPath(strcat(ASTB_GLOBAL->InstallPath "/forms"))
        cnt = 0
        foreach( v list("FORMPATH" "BITMAPPATH" "BMPPATH")
            changed = nil
            kept = nil
            errset(
                prog(()
                    cur = axlGetVariableList(v)
                    ;; 16.6 可能返回裸字符串而非列表，归一化后再处理
                    when( stringp(cur)
                        cur = list(cur)
                    )
                    when( listp(cur)
                        foreach( item cur
                            if( and(stringp(item)
                                    equal(_UNI_NormPath(item) target))
                            then
                                changed = t
                            else
                                kept = cons(item kept)
                            )
                        )
                        when( changed
                            axlSetVariable(v reverse(kept))
                        )
                    )
                )
                t
            )
            when( changed
                cnt = cnt + 1
            )
        )
        return(cnt)
    )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_Uninstall
; 功能    : System -> Uninstall 菜单命令：从 Allegro 卸载 ASTB 工具箱
; 返回值  : t
; 备注    : 仅移除 启动加载块 / env 路径 / 当前菜单，不删程序文件
;           （运行中的 Allegro 占用文件也删不掉）；重启后彻底卸载
;------------------------------------------------------------------------
procedure( ASTB_Uninstall()
    prog((home files sites f txt cleaned msg root unins)
        ;; 1) 二次确认（默认按钮=否，防误点）
        unless( axlUIYesNo(
            "确定卸载 ASTB 工具箱？\n\n将从全部 allegro.ilinit 移除启动加载块（手工编写的加载段会再次单独确认）、\n清理 env 路径并移除当前菜单。程序文件保留在磁盘上，重启 Allegro 后彻底卸载。"
            "ASTB Uninstall" 'no)
            axlUIWPrint(nil "[ASTB] 卸载已取消")
            return(t)
        )

        ;; 2) 剥离 ilinit 加载块：%HOME%\pcbenv 用户级 + 全部 site 副本
        files = nil
        home = _UNI_GetEnv("HOME")
        unless( home
            home = _UNI_GetEnv("USERPROFILE")
        )
        when( home
            files = list(strcat(home "/pcbenv/allegro.ilinit"))
        )
        sites = _UNI_SiteIlinits()
        foreach( f sites
            files = append(files list(f))
        )
        msg = "卸载结果：\n"
        if( files
        then
            foreach( f files
                txt = _UNI_StripOne(f)
                axlUIWPrint(nil strcat("[ASTB] " f " : " txt))
                msg = strcat(msg "  " f "\n     " txt "\n")
            )
        else
            msg = strcat(msg "  未找到任何 allegro.ilinit（HOME 未设置且无 site 副本）\n")
        )

        ;; 3) 清理 env 中的 forms 路径（best-effort）
        cleaned = _UNI_CleanEnvPaths()
        msg = strcat(msg sprintf(nil "  env 路径清理: %d 处\n" cleaned))

        ;; 4) 移除当前会话菜单，置卸载标志禁止本会话自愈重注入
        unless( errset(ASTB_PurgeToolboxMenu() t)
            ASTB_LogWarn("ASTB_Uninstall: menu purge failed, restart to clear")
        )
        when( boundp('ASTB_MENU_INJECTED)
            ASTB_MENU_INJECTED = nil
        )
        when( boundp('ASTB_MENU_TIMER_ID)
            when( ASTB_MENU_TIMER_ID
                errset(axlUIWTimerRemove(ASTB_MENU_TIMER_ID) t)
            )
            ASTB_MENU_TIMER_ID = nil
        )
        ASTB_UNINSTALLED = t

        ;; 5) 汇总提示
        msg = strcat(msg "\n重启 Allegro 后工具箱不再加载。")
        msg = strcat(msg "\n程序文件保留在: " ASTB_GLOBAL->InstallPath)
        ;; 安装版根目录下有 unins000.exe 时提示可彻底删除
        root = _UNI_ParentDir(ASTB_GLOBAL->InstallPath)
        unins = strcat(root "/unins000.exe")
        when( isFile(unins)
            msg = strcat(msg "\n如需彻底删除程序文件，请运行: " unins)
        )
        axlUIWPrint(nil "[ASTB] 卸载完成，重启 Allegro 后生效")
        axlUIConfirm(msg)
        return(t)
    )
)

ASTB_RegisterCommand("ASTB_Uninstall" "ASTB_Uninstall" ?cmdType "general" ?undo nil)

printf("[ASTB] util_uninstall.il v1.1 loaded, command: ASTB_Uninstall\n")
