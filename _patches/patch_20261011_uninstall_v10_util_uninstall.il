;========================================================================
; 文件名    : modules/utilities/util_uninstall.il
; 作者      : ASTB Team
; 创建日期  : 2026-10-11
; 版本      : 1.0
; 功能描述  : 从 Allegro 内卸载 ASTB 工具箱：剥离 allegro.ilinit 中的
;             ASTB 加载块（%HOME%\pcbenv 与 Cadence site 两处，写前
;             备份为 .astb_bak）、从 FORMPATH/BITMAPPATH/BMPPATH
;             摘除本工具箱 forms 路径、移除当前会话已注入的菜单并
;             禁止本会话自愈重注入。重启 Allegro 后彻底不加载；
;             程序文件保留在安装目录，需删文件时运行安装版
;             unins000.exe 或手动删除目录
; 依赖模块  : core/trans.il（ASTB_RegisterCommand）、
;             core/menu.il（ASTB_PurgeToolboxMenu / ASTB_UNINSTALLED）
; 编码      : GBK（含中文字符串）
; 修改记录  :
;   2026-10-11 v1.0 ASTB Team 初始创建（用户要求：菜单加卸载功能）
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
; 函数名  : _UNI_StripIlinit
; 功能    : 剥离指定 allegro.ilinit 中的 ASTB 标记加载块
;           （;; >>> ASTB TOOLBOX BEGIN >>> 至
;             ;; <<< ASTB TOOLBOX END <<< 整段，与安装器同款标记）
; 参数    : path - ilinit 全路径
; 返回值  : stripped - 已剥离写回；noblock - 无标记块未改动；
;           nofile - 文件不存在；error - 读写异常
; 备注    : 写回前把原内容备份为 <file>.astb_bak；行尾统一写 LF
;           （SKILL reader 兼容，且项目纪律禁止残留 \r）；
;           缺 END 标记时丢弃 BEGIN 之后全部内容（损坏块按整块处理）
;------------------------------------------------------------------------
procedure( _UNI_StripIlinit(path)
    prog((port line lines out inBlock n bak br wr l2)
        unless( isFile(path)
            return('nofile)
        )
        port = errset(infile(path) t)
        unless( and(port car(port))
            return('error)
        )
        port = car(port)
        lines = nil
        while( gets(line port)
            lines = cons(line lines)
        )
        close(port)
        lines = reverse(lines)

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

        ;; 备份原件（失败仅告警不阻断，写回仍进行）
        bak = strcat(path ".astb_bak")
        br = errset(
            prog((bp)
                bp = outfile(bak "w")
                unless( bp return(nil) )
                foreach( l2 lines
                    fprintf(bp "%s\n" l2)
                )
                close(bp)
                return(t)
            )
            t
        )
        unless( and(br car(br))
            axlUIWPrint(nil strcat("[ASTB] WARN: ilinit 备份失败: " bak))
        )

        wr = errset(
            prog((wp)
                wp = outfile(path "w")
                unless( wp return(nil) )
                foreach( l2 out
                    fprintf(wp "%s\n" l2)
                )
                close(wp)
                return(t)
            )
            t
        )
        if( and(wr car(wr))
        then
            return('stripped)
        else
            return('error)
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : _UNI_StText
; 功能    : ilinit 剥离结果符号转中文说明（汇总提示用）
;------------------------------------------------------------------------
procedure( _UNI_StText(st)
    cond(
        ( eq(st 'stripped) "已剥离加载块（原件备份为 .astb_bak）" )
        ( eq(st 'noblock)  "无 ASTB 加载块，未改动" )
        ( eq(st 'nofile)   "文件不存在，跳过" )
        ( t                "处理失败（详见命令行）" )
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
    prog((home ilinit cdsroot site st1 st2 cleaned msg root unins)
        ;; 1) 二次确认（默认按钮=否，防误点）
        unless( axlUIYesNo(
            "确定卸载 ASTB 工具箱？\n\n将从 allegro.ilinit 移除启动加载块、清理 env 路径并移除当前菜单。\n程序文件保留在磁盘上，重启 Allegro 后彻底卸载。"
            "ASTB Uninstall" 'no)
            axlUIWPrint(nil "[ASTB] 卸载已取消")
            return(t)
        )

        ;; 2) 剥离 ilinit 加载块：%HOME%\pcbenv（主）+ site skill（辅）
        home = _UNI_GetEnv("HOME")
        unless( home
            home = _UNI_GetEnv("USERPROFILE")
        )
        st1 = 'nofile
        ilinit = nil
        when( home
            ilinit = strcat(home "/pcbenv/allegro.ilinit")
            st1 = _UNI_StripIlinit(ilinit)
        )
        st2 = 'nofile
        cdsroot = _UNI_GetEnv("CDSROOT")
        when( cdsroot
            site = strcat(cdsroot "/share/local/pcb/skill/allegro.ilinit")
            st2 = _UNI_StripIlinit(site)
        )

        ;; 3) 清理 env 中的 forms 路径（best-effort）
        cleaned = _UNI_CleanEnvPaths()

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
        msg = "卸载结果：\n"
        if( ilinit
        then
            msg = strcat(msg "  " ilinit " : " _UNI_StText(st1) "\n")
        else
            msg = strcat(msg "  HOME 环境变量未找到，pcbenv allegro.ilinit 未处理\n")
        )
        when( cdsroot
            msg = strcat(msg "  " cdsroot "/share/local/pcb/skill/allegro.ilinit : "
                _UNI_StText(st2) "\n")
        )
        msg = strcat(msg sprintf(nil "  env 路径清理: %d 处\n" cleaned))
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

printf("[ASTB] util_uninstall.il v1.0 loaded, command: ASTB_Uninstall\n")
