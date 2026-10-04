;========================================================================
; 文件名    : _stubs.il
; 作者      : Toolbox / ASTB Team 整改
; 创建日期  : 2026-07-16
; 版本      : 2.1
; 功能描述  : 精选功能集的函数桩（stub）：为尚无真实实现的菜单项提供
;             "开发中" 占位，避免菜单调用未定义函数
; 依赖模块  : core/utils.il（ASTB_MsgBox）
; 修改记录  :
;   2026-07-16 v1.0 Toolbox 初始创建
;   2026-07-18 v2.0 ASTB Team 整改：
;             1. 删除全部已被真实实现覆盖的桩（含 7 个 ASTB_Mfg_*，真实
;                实现见各模块子目录及 manufacturing/zz_wrappers.il），
;                消除依赖加载顺序的同名重定义警告；
;             2. 合并 _stubs_new.il（其独有的 ASTB_Pkg_CreatePad2 与
;                ASTB_Place_PlaceBySch 两个桩迁入本文件，_stubs_new.il
;                已归档删除），消除双事实源；
;             3. 统一 4 空格缩进，去掉无格式参数的冗余 sprintf。
;   2026-08-01 v2.1 ASTB Team 菜单裁剪（用户要求）：Manufacturing 只保留
;             Film Reorder / Gerber Setup，删除 ExportGerber / ExportCoords /
;             ExportJSON / Panelize / DrillLegend 五个占位桩
;========================================================================
;
; 保留判定（2026-07-18 全模块扫描）：以下函数在整个 modules/ 中均无真实
; 实现，菜单项仍需占位。若某功能日后实现，请从本文件删除对应桩。

;; --- Package 组 ---
procedure( ASTB_Pkg_RenamePins()
    ASTB_MsgBox("Feature [ASTB_Pkg_RenamePins] is under development.")
    t
)

procedure( ASTB_Pkg_SymbolCheck()
    ASTB_MsgBox("Feature [ASTB_Pkg_SymbolCheck] is under development.")
    t
)

procedure( ASTB_Pkg_UpdateSymbol()
    ASTB_MsgBox("Feature [ASTB_Pkg_UpdateSymbol] is under development.")
    t
)

;; --- Placement 组 ---
procedure( ASTB_Place_EqualSpacing()
    ASTB_MsgBox("Feature [ASTB_Place_EqualSpacing] is under development.")
    t
)

procedure( ASTB_Place_MirrorGroup()
    ASTB_MsgBox("Feature [ASTB_Place_MirrorGroup] is under development.")
    t
)

procedure( ASTB_Place_SetGrid()
    ASTB_MsgBox("Feature [ASTB_Place_SetGrid] is under development.")
    t
)

procedure( ASTB_Place_ChangeOrigin()
    ASTB_MsgBox("Feature [ASTB_Place_ChangeOrigin] is under development.")
    t
)

;; --- Routing 组 ---
procedure( ASTB_Route_FindStub()
    ASTB_MsgBox("Feature [ASTB_Route_FindStub] is under development.")
    t
)

;; --- Via 组 ---
procedure( ASTB_Via_ReplaceVia()
    ASTB_MsgBox("Feature [ASTB_Via_ReplaceVia] is under development.")
    t
)

procedure( ASTB_Via_DeleteGND()
    ASTB_MsgBox("Feature [ASTB_Via_DeleteGND] is under development.")
    t
)

;; --- Shape 组 ---
procedure( ASTB_Shape_CreateThermal()
    ASTB_MsgBox("Feature [ASTB_Shape_CreateThermal] is under development.")
    t
)

procedure( ASTB_Shape_Split()
    ASTB_MsgBox("Feature [ASTB_Shape_Split] is under development.")
    t
)

;; --- Text 组 ---
procedure( ASTB_Text_SetTextAttr()
    ASTB_MsgBox("Feature [ASTB_Text_SetTextAttr] is under development.")
    t
)


procedure( ASTB_Text_AdjustRefDes()
    ASTB_MsgBox("Feature [ASTB_Text_AdjustRefDes] is under development.")
    t
)

;; --- Check 组 ---
procedure( ASTB_Check_RefDirection()
    ASTB_MsgBox("Feature [ASTB_Check_RefDirection] is under development.")
    t
)

;; --- Manufacturing 组：菜单已裁剪，占位桩已全部移除（v2.1） ---

;; --- Utilities 组 ---
procedure( ASTB_Util_SetShortcut()
    ASTB_MsgBox("Feature [ASTB_Util_SetShortcut] is under development.")
    t
)

procedure( ASTB_Util_Calculator()
    ASTB_MsgBox("Feature [ASTB_Util_Calculator] is under development.")
    t
)

;; --- 自 _stubs_new.il 迁入（该文件已归档删除） ---
procedure( ASTB_Pkg_CreatePad2()
    ASTB_MsgBox("Feature [ASTB_Pkg_CreatePad2] is under development.")
    t
)

procedure( ASTB_Place_PlaceBySch()
    ASTB_MsgBox("Feature [ASTB_Place_PlaceBySch] is under development.")
    t
)

printf("[ASTB] modules/_stubs.il loaded.\n")
