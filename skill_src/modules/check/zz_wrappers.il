;========================================================================
; 文件名    : zz_wrappers.il
; 作者      : ASTB
; 创建日期  : 2026-07
; 版本      : 1.1
; 功能描述  : Check模块的统一封装包装器，为工具箱菜单提供标准接口。
;             已收敛重复入口：NoRefDes/90degLine的菜单入口分别在
;             check_norefdes.il/check_90degline.il内注册，本文件不再重复包装。
; 依赖模块  : check_hilightnofanout.il, check_solder2line.il
; 修改记录  :
;   2026-07 v1.0 ASTB 初始创建
;   2026-07 v1.1 ASTB 删除ASTB_Check_NoRefDes2/ASTB_Check_NoRef2/
;             ASTB_Check_Loop902三个重复入口；补getd存在性检查；
;             修正加载日志文件名；统一4空格缩进
;========================================================================

;; ============================================================
;; Check wrappers for 精选功能集
;; ============================================================

;------------------------------------------------------------------------
; 函数名  : ASTB_Check_HilightNoFanout
; 功能    : 菜单入口——高亮无Fanout的SMD焊盘（29号模块）
; 参数    : 无
; 返回值  : t/nil
;------------------------------------------------------------------------
procedure( ASTB_Check_HilightNoFanout()
    if( getd('_lgs_hilight_smd_main) then
        _lgs_hilight_smd_main()
    else
        axlUIConfirm("模块 check_hilightnofanout.il 未加载")
        nil
    )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_Check_Solder2Line
; 功能    : 菜单入口——检查Solder Mask到Line间距（31号模块）
; 参数    : 无
; 返回值  : t/nil
;------------------------------------------------------------------------
procedure( ASTB_Check_Solder2Line()
    if( getd('_lgs_check_solder_to_line) then
        _lgs_check_solder_to_line()
    else
        axlUIConfirm("模块 check_solder2line.il 未加载")
        nil
    )
)

printf("[ASTB] zz_wrappers.il loaded.\n")
