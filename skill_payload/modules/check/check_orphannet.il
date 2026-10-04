;========================================================================
; 文件名    : check_orphannet.il
; 作者      : defir.dong
; 创建日期  : 2009-11-25
; 版本      : 1.1
; 功能描述  : 查找孤儿网络(Orphan Net)：无ratsnest且非电源的网络，
;             输出网络名与一个pin定位坐标到报告
; 依赖模块  : axlSetFindFilter, axlAddSelectAll, axlSelectByProperty
; 修改记录  :
;   2009-11-25 v1.0 defir.dong 初始创建
;   2026-07 v1.1 ASTB let局部化；删除调试printf；
;             axlGetSelSet(axlAddSelectAll())拆两行；报告写临时目录；
;             可见性退出前恢复；pin无net时判空
;========================================================================

;; ============================================================
;; File: check_orphannet.il
;; Purpose: Find orphan net
;; Encoding: GBK
;; ============================================================

;=====================================================================
;OrphanNet.il
;this routine report the Orphan net which do not belong to a ratsnest.
;Date:2009-11-25
;author:defir.dong
;=====================================================================

;------------------------------------------------------------------------
; 函数名  : ASTB_Check_OrphanNet
; 功能    : 查找孤儿网络（无ratsnest的网络，排除带RATSNEST_SCHEDULE/
;           VOLTAGE属性的电源网），生成报告并弹窗显示
; 参数    : 无
; 返回值  : nil
; 副作用  : 修改层可见性（退出前恢复）；在临时目录生成报告文件
;------------------------------------------------------------------------
procedure( ASTB_Check_OrphanNet()
    prog((visSave logPath repFile nets ntd rats ratv l1 pins px)
        logPath = axlTempFile()
        visSave = axlVisibleGet()
        axlClearSelSet()
        axlVisibleDesign(nil)
        axlVisibleLayer("PIN/TOP" t)
        axlVisibleLayer("PIN/BOTTOM" t)
        axlVisibleLayer("PACKAGE GEOMETRY/SILKSCREEN_TOP" t)
        axlVisibleLayer("PACKAGE GEOMETRY/SILKSCREEN_BOTTOM" t)
        axlVisibleLayer("BOARD GEOMETRY/OUTLINE" t)
        axlVisibleUpdate(t)

        axlSetFindFilter(?enabled '("NOALL" "NETS") ?onButtons '("NETS"))
        axlAddSelectAll()
        nets = axlGetSelSet()

        repFile = outfile(logPath)
        unless( repFile
            axlVisibleSet(visSave)
            axlUIConfirm("\316\336\267\250\264\264\275\250\301\331\312\261\261\250\270\346\316\304\274\376")
            return(nil)
        )
        fprintf(repFile "\t Orphan Nets Report\n\n Net Name\t\tLocation\n\n")

        ; --- 无ratsnest的网络即为孤儿网候选 ---
        ntd = nil
        foreach( nt nets
            if( nt->name != "" && nt->ratsnest == nil then
                ntd = cons(nt ntd)
            )
        )

        ; --- 排除电源网：带RATSNEST_SCHEDULE或VOLTAGE属性的net不参与判断 ---
        rats = axlSelectByProperty("net" "RATSNEST_SCHEDULE")
        ratv = axlSelectByProperty("net" "VOLTAGE")
        l1 = append(rats ratv)
        foreach( nam l1
            ntd = remove(nam ntd)
        )

        ; --- 为每个孤儿网找一个pin坐标用于定位 ---
        axlClearSelSet()
        axlSetFindFilter(?enabled '("NOALL" "PINS") ?onButtons '("PINS"))
        axlAddSelectAll()
        pins = axlGetSelSet()
        foreach( pn pins
            foreach( nt ntd
                if( pn->net && pn->net->name == nt->name then
                    px = pn->xy
                    fprintf(repFile "%L\t\t%L\n" nt->name px)
                )
            )
        )

        axlClearSelSet()
        close(repFile)
        axlVisibleSet(visSave)
        axlUIWExpose(axlUIViewFileCreate(logPath "Orphan Nets Log" nil))
        nil
    )
)

; 纯查询命令：不修改数据库，不挂undo
ASTB_RegisterCommand("ASTB_Check_OrphanNet" "ASTB_Check_OrphanNet" ?cmdType "interactive" ?undo nil)

printf("[ASTB] check_orphannet.il loaded.\n")
