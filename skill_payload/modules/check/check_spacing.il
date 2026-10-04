;========================================================================
; 文件名    : check_spacing.il
; 作者      : ASTB
; 创建日期  : 未知
; 版本      : 1.1
; 功能描述  : 间距检查：对比SMD pin的PasteMask/SolderMask/OSP(FILMMASK)
;             焊盘是否缺失或不一致，并检查非Mobile封装，结果写日志并高亮
; 依赖模块  : axlSetFindFilter, axlAddSelectAll, axlDBGetPad
; 修改记录  :
;   未知 v1.0 ASTB 初始创建
;   2026-07 v1.1 ASTB 命令名"~2"废弃，统一入口ASTB_Check_Spacing；
;             修复无pad pin的nil->figureName崩溃；可见性退出前恢复；
;             let局部化；日志写临时目录；KSW前缀常量化
;========================================================================

;; ============================================================
;; File: check_spacing.il
;; Purpose: Spacing Check
;; Encoding: GBK
;; Source: 10-检查与DRC/check_spacing.il
;; ============================================================

; --- 模块常量：特定客户(KSW)封装前缀不参与检查 ---
C_SPCHK_SKIP_PREFIX = "KSW"

;------------------------------------------------------------------------
; 函数名  : ASTB_Check_Spacing
; 功能    : 对比TOP/BOT两层SMD pin的pastemask/soldermask/filmmask焊盘，
;           找出缺失或不匹配者；并列出非Mobile封装（封装名末字符不为M，
;           启发式规则），结果写日志、弹窗并高亮
; 参数    : 无
; 返回值  : nil
; 副作用  : 修改层可见性（退出前恢复）；在临时目录生成日志
;------------------------------------------------------------------------
procedure( ASTB_Check_Spacing()
    prog((visList logPath logFile Date
         ppTopList ppBotList ospTopList ospBotList
         realTopList realBotList realOspTopList realOspBotList
         pmPad smPad pmFig smFig refDes
         cntTop cntBot cntOspTop cntOspBot
         diffTop diffBot diffOspTop diffOspBot
         notMobTop notMobBot cntMobTop cntMobBot symName)
        ; --- 保存可见性（全程只保存一次，退出前统一恢复） ---
        visList = axlVisibleGet()
        Date = getCurrentTime()

        logPath = axlTempFile()
        logFile = outfile(logPath "w")
        unless( logFile
            axlVisibleSet(visList)
            axlUIConfirm("\316\336\267\250\264\264\275\250\301\331\312\261\310\325\326\276\316\304\274\376")
            return(nil)
        )
        fprintf(logFile "\n\n\n\t%s\n\n" Date)
        fprintf(logFile "\t\tdiff Logfile\n")

        cntTop = 0 cntBot = 0 cntOspTop = 0 cntOspBot = 0
        diffTop = nil diffBot = nil diffOspTop = nil diffOspBot = nil

        ;########################################################
        ; 第1段：TOP层 pastemask vs soldermask
        ;########################################################
        axlClearSelSet()
        axlVisibleDesign(nil)
        axlVisibleLayer("PIN/PASTEMASK_TOP" t)
        axlVisibleLayer("PIN/SOLDERMASK_TOP" t)
        axlSetFindFilter(?enabled list("noall" "pins") ?onButtons list("noall" "pins"))
        axlAddSelectAll()
        ppTopList = axlGetSelSet()

        fprintf(logFile "Without pastemask at top\n")

        ; --- 过滤：仅SMD pin（非通孔）、有refdes、非KSW前缀 ---
        realTopList = nil
        foreach( pinDb ppTopList
            refDes = pinDb->parent->refdes
            if( refDes != nil && pinDb->isThrough == nil &&
                substring(refDes 1 3) != C_SPCHK_SKIP_PREFIX then
                realTopList = cons(pinDb realTopList)
            )
        )

        foreach( pinDb realTopList
            ; 无pad的pin：axlDBGetPad返回nil，视为缺失计入报告，禁止直接->figureName
            pmPad = axlDBGetPad(pinDb "PIN/PASTEMASK_TOP" "regular")
            smPad = axlDBGetPad(pinDb "PIN/SOLDERMASK_TOP" "regular")
            pmFig = when( pmPad pmPad->figureName )
            smFig = when( smPad smPad->figureName )
            unless( equal(pmFig smFig)
                cntTop++
                diffTop = cons(pinDb diffTop)
                fprintf(logFile "\t%n %s %L\n" cntTop pinDb->parent->refdes pinDb->xy)
            )
        )
        when( diffTop == nil
            fprintf(logFile "\t No difference Found\n")
        )

        ;########################################################
        ; 第2段：BOT层 pastemask vs soldermask
        ;########################################################
        axlClearSelSet()
        axlVisibleDesign(nil)
        axlVisibleLayer("PIN/PASTEMASK_BOTTOM" t)
        axlVisibleLayer("PIN/SOLDERMASK_BOTTOM" t)
        axlSetFindFilter(?enabled list("noall" "pins") ?onButtons list("noall" "pins"))
        axlAddSelectAll()
        ppBotList = axlGetSelSet()

        fprintf(logFile "\n\nWithout pastemask at BOT\n")

        realBotList = nil
        foreach( pinDb ppBotList
            refDes = pinDb->parent->refdes
            if( refDes != nil && pinDb->isThrough == nil &&
                substring(refDes 1 3) != C_SPCHK_SKIP_PREFIX then
                realBotList = cons(pinDb realBotList)
            )
        )

        foreach( pinDb realBotList
            pmPad = axlDBGetPad(pinDb "PIN/PASTEMASK_BOTTOM" "regular")
            smPad = axlDBGetPad(pinDb "PIN/SOLDERMASK_BOTTOM" "regular")
            pmFig = when( pmPad pmPad->figureName )
            smFig = when( smPad smPad->figureName )
            unless( equal(pmFig smFig)
                cntBot++
                diffBot = cons(pinDb diffBot)
                fprintf(logFile "\t%n %s %L\n" cntBot pinDb->parent->refdes pinDb->xy)
            )
        )
        when( diffBot == nil
            fprintf(logFile "\t No difference Found\n")
        )

        ;########################################################
        ; 第3段：TOP层 OSP(filmmask) vs soldermask
        ;########################################################
        axlClearSelSet()
        axlVisibleDesign(nil)
        axlVisibleLayer("PIN/FILMMASKTOP" t)
        axlVisibleLayer("PIN/SOLDERMASK_TOP" t)
        axlSetFindFilter(?enabled list("noall" "pins") ?onButtons list("noall" "pins"))
        axlAddSelectAll()
        ospTopList = axlGetSelSet()

        fprintf(logFile "\n\nWithout OSP at top\n")

        realOspTopList = nil
        foreach( pinDb ospTopList
            refDes = pinDb->parent->refdes
            if( refDes != nil && pinDb->isThrough == nil &&
                substring(refDes 1 3) != C_SPCHK_SKIP_PREFIX then
                realOspTopList = cons(pinDb realOspTopList)
            )
        )

        foreach( pinDb realOspTopList
            pmPad = axlDBGetPad(pinDb "PIN/FILMMASKTOP" "regular")
            smPad = axlDBGetPad(pinDb "PIN/SOLDERMASK_TOP" "regular")
            pmFig = when( pmPad pmPad->figureName )
            smFig = when( smPad smPad->figureName )
            unless( equal(pmFig smFig)
                cntOspTop++
                diffOspTop = cons(pinDb diffOspTop)
                fprintf(logFile "\t%n %s %L\n" cntOspTop pinDb->parent->refdes pinDb->xy)
            )
        )
        when( diffOspTop == nil
            fprintf(logFile "\t No difference Found\n")
        )

        ;########################################################
        ; 第4段：BOT层 OSP(filmmask) vs soldermask
        ;########################################################
        axlClearSelSet()
        axlVisibleDesign(nil)
        axlVisibleLayer("PIN/FILMMASKBOTTOM" t)
        axlVisibleLayer("PIN/SOLDERMASK_BOTTOM" t)
        axlSetFindFilter(?enabled list("noall" "pins") ?onButtons list("noall" "pins"))
        axlAddSelectAll()
        ospBotList = axlGetSelSet()

        fprintf(logFile "\n\nWithout OSP at BOT\n")

        realOspBotList = nil
        foreach( pinDb ospBotList
            refDes = pinDb->parent->refdes
            if( refDes != nil && pinDb->isThrough == nil &&
                substring(refDes 1 3) != C_SPCHK_SKIP_PREFIX then
                realOspBotList = cons(pinDb realOspBotList)
            )
        )

        foreach( pinDb realOspBotList
            pmPad = axlDBGetPad(pinDb "PIN/FILMMASKBOTTOM" "regular")
            smPad = axlDBGetPad(pinDb "PIN/SOLDERMASK_BOTTOM" "regular")
            pmFig = when( pmPad pmPad->figureName )
            smFig = when( smPad smPad->figureName )
            unless( equal(pmFig smFig)
                cntOspBot++
                diffOspBot = cons(pinDb diffOspBot)
                fprintf(logFile "\t%n %s %L\n" cntOspBot pinDb->parent->refdes pinDb->xy)
            )
        )
        when( diffOspBot == nil
            fprintf(logFile "\t No difference Found\n")
        )

        ;########################################################
        ; 第5段：非Mobile封装检查（启发式：封装名末字符为M视为Mobile元件）
        ;########################################################
        fprintf(logFile "\n\nNOT MOBILE SYMBOL AT TOP\n")
        notMobTop = nil cntMobTop = 0
        foreach( pinDb ppTopList
            symName = pinDb->parent->name
            if( substring(symName strlen(symName) 1) != "M" then
                cntMobTop++
                notMobTop = cons(pinDb notMobTop)
                fprintf(logFile "\t%n %s %L\n" cntMobTop pinDb->parent->refdes pinDb->xy)
            )
        )
        when( notMobTop == nil
            fprintf(logFile "\tNothing Found\n")
        )

        axlClearSelSet()

        fprintf(logFile "\n\nNOT MOBILE SYMBOL at BOT\n")
        notMobBot = nil cntMobBot = 0
        foreach( pinDb ppBotList
            symName = pinDb->parent->name
            if( substring(symName strlen(symName) 1) != "M" then
                cntMobBot++
                notMobBot = cons(pinDb notMobBot)
                fprintf(logFile "\t%n %s %L\n" cntMobBot pinDb->parent->refdes pinDb->xy)
            )
        )
        when( notMobBot == nil
            fprintf(logFile "\tNothing Found\n")
        )

        ;########################################################
        ; 收尾：高亮差异pin，关闭日志，恢复可见性，弹窗报告
        ;########################################################
        axlClearSelSet()
        axlHighlightObject(diffTop)
        axlHighlightObject(diffBot)
        axlHighlightObject(diffOspTop)
        axlHighlightObject(diffOspBot)
        axlHighlightObject(notMobTop)
        axlHighlightObject(notMobBot)

        close(logFile)
        axlVisibleSet(visList)
        axlVisibleUpdate(t)

        axlUIWExpose(axlUIViewFileCreate(logPath "diff Log" nil))
        nil
    )
)

; 纯查询/高亮命令：不修改数据库，不挂undo
ASTB_RegisterCommand("ASTB_Check_Spacing" "ASTB_Check_Spacing" ?cmdType "interactive" ?undo nil)

printf("[ASTB] check_spacing.il loaded.\n")
