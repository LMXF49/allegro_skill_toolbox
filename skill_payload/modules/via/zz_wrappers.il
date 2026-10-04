;========================================================================
; 文件名    : zz_wrappers.il
; 作者      : ASTB Team
; 创建日期  : 2026-07-16
; 版本      : 1.4
; 功能描述  : Via 模块命令包装器（精选功能集菜单入口）
; 依赖模块  : via_changevianet.il,
;             core/trans.il (ASTB_DBTransactionMark, ASTB_RegisterCommand)
; 修改记录  :
;   2026-07-16 v1.0 ASTB Team 初始创建
;   2026-07-17 v1.1 ASTB Team 整改：via_changevianet.il 已删除（与
;                     via_changevianet.il 重复注册 cvia 命令并覆盖
;                     同名函数），新增 ASTB_Via_ChangeViaNet 正式命名
;                     包装，覆盖 _stubs.il 占位桩，保证菜单
;                     "Change Via Net" 指向带事务保护的实现；
;                     修正加载日志文件名
;   2026-07-26 v1.2 ASTB Team 新增 ASTB_Via_ReplaceViaForm 包装
;                     （菜单 "Replace Via Form"，指向 rvia.il 的
;                     RVIA_Main 表单替换过孔）
;   2026-07-26 v1.3 ASTB Team 删除 ASTB_Via_ReplaceVia2 包装
;                     （Replace Via v2 菜单与 14a 模块下线，职能
;                     由 rvia.il 接管）
;   2026-09-29 v1.4 ASTB Team 删除 ASTB_Via_ReplaceViaForm 包装
;                     （rvia.il 随 Via 类目精简下线，仅保留
;                     ChangeViaNet 系列）
;========================================================================

;; ============================================================
;; Via wrappers for 精选功能集
;; ============================================================

;------------------------------------------------------------------------
; 函数名  : ASTB_Via_ChangeViaNet
; 功能    : Toolbox 菜单包装：修改选中过孔的网络（15_x x_change_via_net）
; 说明    : via_changevianet.il 删除后由本包装提供正式命名入口，
;           实际执行带 ASTB_DBTransactionMark 保护的 15_x 实现
;------------------------------------------------------------------------
procedure( ASTB_Via_ChangeViaNet()
    x_change_via_net()
)

;------------------------------------------------------------------------
; 函数名  : ASTB_Via_ChangeViaNet2
; 功能    : 兼容别名（菜单 "Change Via Net v2"），与 ASTB_Via_ChangeViaNet 相同
;------------------------------------------------------------------------
procedure( ASTB_Via_ChangeViaNet2()
    x_change_via_net()
)

printf("[ASTB] via/zz_wrappers.il loaded.\n")
