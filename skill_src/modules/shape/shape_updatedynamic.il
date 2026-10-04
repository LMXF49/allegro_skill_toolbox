;   2026-08-20 v1.2 ASTB Team 主命令注册补 ?undo t（17.4+ 支持系统
;                   撤销 Ctrl+Z；16.6 同步时由补丁脚本剥除）
;========================================================================
; 文件名    : shape_updatedynamic.il
; 作者      : short_skill / ASTB 整改组
; 创建日期  : 2026-07-16
; 版本      : 1.2
; 功能描述  : Dynamic Shape 更新工具：强制更新全部动态铜皮并恢复 wysiwyg 填充显示
; 依赖模块  : core
; 备注      : suf/su 为遗留快捷命令（裸 axlCmdRegister，不入 ASTB 菜单）；
;             mkncpin/dbd 命令统一归 check 模块管理（modules/check/check_dbdoctor.il），
;             本文件不再注册，避免重复注册
; 修改记录  :
;   2026-07-16 v1.0 初始创建
;   2026-07-17 v1.1 ASTB 整改：重写损坏文件头；移除与 check_dbdoctor.il
;                    重复注册的 mkncpin/dbd 两个命令；统一 cmdType 为字符串
;========================================================================

; --- 遗留快捷命令：强制更新所有动态铜皮 ---
axlCmdRegister("suf" 'shape_update_force ?cmdType "interactive")
procedure( shape_update_force()
    axlShapeDynamicUpdate(nil t)
    axlDBControl('dynamicFillMode 'wysiwyg)
)

; --- 遗留快捷命令：平滑更新动态铜皮 ---
axlCmdRegister("su" 'shape_update_sh ?cmdType "interactive")
procedure( shape_update_sh()
    ; 连续调用两次为旧版本兼容 hack：首次调用后部分铜皮状态未刷新，
    ; 再次调用确保全部更新到位
    shape_update()
    shape_update()
)

procedure( shape_update()
    axlShapeDynamicUpdate(nil nil)
    axlDBControl('dynamicFillMode 'wysiwyg)
)

;------------------------------------------------------------------------
; 函数名  : ASTB_Shape_UpdateDynamic
; 功能    : ASTB 框架入口：强制更新动态铜皮
;------------------------------------------------------------------------
procedure( ASTB_Shape_UpdateDynamic()
    shape_update_force()
)

ASTB_RegisterCommand("ASTB_Shape_UpdateDynamic" "ASTB_Shape_UpdateDynamic" ?cmdType "interactive")

printf("[ASTB] shape_updatedynamic.il loaded.\n")
