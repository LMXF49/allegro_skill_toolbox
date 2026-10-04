;========================================================================
; 文件名    : check_norefdes.il
; 作者      : ASTB
; 创建日期  : 未知
; 版本      : 1.1
; 功能描述  : 检查无RefDes的元件（丝印层缺失REF DES文本的symbol），
;             结果写入日志并高亮显示
; 依赖模块  : axlDBGetAttachedText, axlHighlightObject, axlDMOpenLog
; 修改记录  :
;   未知 v1.0 ASTB 初始创建
;   2026-07 v1.1 ASTB 删除文件内自我重复段（原68-111行）；
;             procedure化+let局部化；去除裸axlCmdRegister与?undo t；
;             可见性退出前恢复；日志改写到临时目录
;========================================================================

;; ============================================================
;; File: check_norefdes.il
;; Purpose: Check no RefDes
;; Encoding: GBK
;; ============================================================

;------------------------------------------------------------------------
; 函数名  : Check_No_Refdes
; 功能    : 遍历设计中全部symbol，找出丝印层无REF DES文本者，
;           写入日志文件并高亮
; 参数    : 无
; 返回值  : norefcnt - 无RefDes的元件数量
; 副作用  : 修改层可见性（退出前恢复）；在临时目录生成日志
;------------------------------------------------------------------------
procedure( Check_No_Refdes()
    let((visSave logPath logfile allsym text txt norefcnt)
        ; --- 保存当前可见性，设置检查所需层 ---
        visSave = axlVisibleGet()
        axlVisibleDesign(nil)
        axlVisibleLayer("BOARD GEOMETRY/OUTLINE" t)
        axlVisibleLayer("PIN/TOP" t)
        axlVisibleLayer("PIN/BOTTOM" t)
        axlVisibleLayer("REF DES/SILKSCREEN_TOP" t)
        axlVisibleLayer("REF DES/SILKSCREEN_BOTTOM" t)
        axlVisibleLayer("PACKAGE GEOMETRY/SILKSCREEN_TOP" t)
        axlVisibleLayer("PACKAGE GEOMETRY/SILKSCREEN_BOTTOM" t)

        ; --- 日志写入临时目录，禁止写CWD ---
        logPath = axlTempFile()
        logfile = axlDMOpenLog(logPath)
        norefcnt = 0
        if( logfile then
            fprintf(logfile "#Check the component without refdes . \n\n")
            fprintf(logfile "REF_DES  COORDIRATION\n")

            allsym = axlDBGetDesign()->symbols
            axlDehighlightObject(allsym)
            foreach( symbol allsym
                text = axlDBGetAttachedText(symbol)
                txt = nil
                foreach( find text
                    if( find->layer == "REF DES/SILKSCREEN_TOP" ||
                        find->layer == "REF DES/SILKSCREEN_BOTTOM" then
                        txt = find
                    )
                )
                if( txt == nil && symbol->refdes != nil then
                    axlHighlightObject(symbol)
                    fprintf(logfile "%-8s %L\n" symbol->refdes symbol->xy)
                    ++norefcnt
                )
            )

            fprintf(logfile "\nTotal of no refdes: %d\n" norefcnt)
            axlDMClose(logfile)
        else
            axlMsgPut("Cannot open log file.")
        )

        ; --- 恢复可见性 ---
        axlVisibleSet(visSave)

        axlMsgPut("Total component without refdes: %d" norefcnt)
        printf("No-refdes log file: %s\n" logPath)
        norefcnt
    )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_Check_NoRefDes
; 功能    : 工具箱菜单入口——检查无RefDes元件
; 参数    : 无
; 返回值  : 同 Check_No_Refdes
;------------------------------------------------------------------------
procedure( ASTB_Check_NoRefDes()
    Check_No_Refdes()
)

; 纯查询/高亮命令：不修改数据库，不挂undo
ASTB_RegisterCommand("ASTB_Check_NoRefDes" "ASTB_Check_NoRefDes" ?cmdType "interactive" ?undo nil)

printf("[ASTB] check_norefdes.il loaded.\n")
