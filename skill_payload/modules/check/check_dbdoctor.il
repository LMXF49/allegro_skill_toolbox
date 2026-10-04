;========================================================================
; 文件名    : check_dbdoctor.il
; 作者      : ASTB
; 创建日期  : 未知
; 版本      : 1.1
; 功能描述  : 运行DbDoctor检查；附带mkncpin（高亮dummy net的NC pin）小工具。
;             说明：suf/su/shape_update系列铜皮更新命令归
;             modules/shape/shape_updatedynamic.il所有，本文件不再重复注册。
; 依赖模块  : axlDBControl, axlShell, axlHighlightObject
; 修改记录  :
;   未知 v1.0 ASTB 初始创建
;   2026-07 v1.1 ASTB 修复ASTB_Check_DbDoctor名实不符（原误调
;             shape_update_force，改调db_check）；移除与
;             shape_updatedynamic.il重复的suf/su命令；dbd/mkncpin
;             去?undo t（axlShell/纯高亮不支持undo）；参数去逗号
;========================================================================

;; ============================================================
;; File: check_dbdoctor.il
;; Purpose: Run DbDoctor
;; Encoding: GBK
;; ============================================================

;------------------------------------------------------------------------
; 函数名  : mark_ncpin
; 功能    : 高亮所有挂在dummy net上的pin（NC pin），便于排查未连接管脚
; 参数    : 无
; 返回值  : nil
; 副作用  : 修改高亮色设置；纯高亮，不改库
;------------------------------------------------------------------------
procedure( mark_ncpin()
    axlDBControl('highlightColor 4)
    axlHighlightObject(axlDBDummyNet(nil) t)
)
axlCmdRegister("mkncpin" 'mark_ncpin)

;------------------------------------------------------------------------
; 函数名  : db_check
; 功能    : 通过界面脚本运行dbdoctor（勾选drc/shapes/xnets后执行并打开日志）
; 参数    : 无
; 返回值  : nil
; 副作用  : axlShell驱动dbdoctor表单，依赖表单字段名，版本间脆弱；
;           dbdoctor会修复数据库，运行前请务必先保存设计
;------------------------------------------------------------------------
procedure( db_check()
    axlShell("dbdoctor")
    axlShell("FORM dbdoctor_allegro drc YES")
    axlShell("FORM dbdoctor_allegro shapes YES")
    axlShell("FORM dbdoctor_allegro xnets YES")
    axlShell("FORM dbdoctor_allegro execute")
    axlShell("FORM dbdoctor_allegro vlog")
)
; axlShell命令不能挂?undo，且只能注册为general类型
axlCmdRegister("dbd" 'db_check ?cmdType "general")

;------------------------------------------------------------------------
; 函数名  : ASTB_Check_DbDoctor
; 功能    : 工具箱菜单入口——运行DbDoctor
;           （v1.1修正：原实现误调铜皮更新函数shape_update_force）
; 参数    : 无
; 返回值  : nil
;------------------------------------------------------------------------
procedure( ASTB_Check_DbDoctor()
    db_check()
)

; db_check内部使用axlShell，只能注册为general且不支持undo
ASTB_RegisterCommand("ASTB_Check_DbDoctor" "ASTB_Check_DbDoctor" ?cmdType "general" ?undo nil)

printf("[ASTB] check_dbdoctor.il loaded.\n")
