;========================================================================
; 文件名    : check_padcount.il
; 作者      : ASTB
; 创建日期  : 未知
; 版本      : 1.1
; 功能描述  : 统计焊盘(Pad)与钻孔(Drill)数量并弹窗报告。
; 统计口径  : pad   = 全部pin中除去机械孔pin（SMD+插装焊盘）；
;             drill = 通孔pin数量 + via数量
; 依赖模块  : axlSetFindFilter, axlAddSelectAll, axlTempFile
; 修改记录  :
;   未知 v1.0 ASTB 初始创建
;   2026-07 v1.1 ASTB 命令名test更名为ASTB_Check_PadCount（防冲突）；
;             let局部化；去除双倍空行与?undo t；可见性退出前恢复
;========================================================================

;; ============================================================
;; File: check_padcount.il
;; Purpose: Pad Count
;; Encoding: GBK
;; Source: 10-检查与DRC/pad count.il
;; ============================================================

;------------------------------------------------------------------------
; 函数名  : ASTB_Check_PadCount
; 功能    : 统计设计中的焊盘与钻孔数量，生成报告并弹窗显示
; 参数    : 无
; 返回值  : nil
; 副作用  : 修改层可见性（退出前恢复）；在临时目录生成报告文件
;------------------------------------------------------------------------
procedure( ASTB_Check_PadCount()
    prog((visSave file port all pad drl padCount drlCount)
        file = axlTempFile()
        port = outfile(file)
        unless( port
            axlUIConfirm("\316\336\267\250\264\264\275\250\301\331\312\261\261\250\270\346\316\304\274\376")
            return(nil)
        )

        ; --- 保存并设置可见性 ---
        visSave = axlVisibleGet()
        axlVisibleDesign(nil)
        axlVisibleLayer("PIN/SOLDERMASK_TOP" t)
        axlVisibleLayer("PIN/SOLDERMASK_BOTTOM" t)
        axlVisibleLayer("PACKAGE GEOMETRY/SOLDERMASK_TOP" t)
        axlVisibleLayer("PACKAGE GEOMETRY/SOLDERMASK_BOTTOM" t)
        axlVisibleLayer("VIA CLASS" t)

        ; --- 统计pin：机械孔pin不计入pad；通孔pin计入drill ---
        axlSetFindFilter(
            ?enabled  list("noall" "pins")
            ?onButtons list("noall" "pins")
        )
        axlAddSelectAll()
        all = axlGetSelSet()
        pad = all
        drl = all
        axlClearSelSet()

        foreach( pin all
            if( pin->isMech then pad = remove(pin pad) )   ; 机械孔pin不是焊盘
            unless( pin->isThrough drl = remove(pin drl) ) ; 非通孔pin不计钻孔
        )
        padCount = length(pad)

        ; --- 统计via：via计入钻孔数 ---
        axlSetFindFilter(
            ?enabled  list("noall" "vias")
            ?onButtons list("noall" "vias")
        )
        axlAddSelectAll()
        all = axlGetSelSet()
        axlClearSelSet()

        drlCount = length(drl) + length(all)

        fprintf(port "Pads amount is %d\nDrill amount is %d\n" padCount drlCount)
        close(port)

        ; --- 恢复可见性 ---
        axlVisibleSet(visSave)

        axlUIWExpose(axlUIViewFileCreate(file "Report" nil))
        nil
    )
)

; 纯统计命令：不修改数据库，不挂undo
ASTB_RegisterCommand("ASTB_Check_PadCount" "ASTB_Check_PadCount" ?cmdType "interactive" ?undo nil)

printf("[ASTB] check_padcount.il loaded.\n")
