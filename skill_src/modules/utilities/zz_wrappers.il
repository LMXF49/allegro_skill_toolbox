;========================================================================
; 文件名    : zz_wrappers.il
; 作者      : ASTB 项目组
; 创建日期  : 2026-07-16
; 版本      : 1.3
; 功能描述  : Utilities模块统一封装，为菜单系统提供标准接口
; 依赖模块  : core/utils.il (ASTB_MsgBox),
;             utilities/util_colorsetting.il (FanySkill_Color_Setting),
;             utilities/util_etchcrossplane.il (create_etch_cross_form),
;             utilities/util_assembly.il,
;             utilities/util_search.il (_SearchStar),
;             utilities/util_quicksavebytime.il (wxSaveFileBT),
;             utilities/util_supernetfinder.il (_lgs_super_net_find),
;             utilities/util_hotkeysetup.il (HotkeySetup_*)
; 修改记录  :
;   2026-07-16 v1.0 ASTB 项目组 初始创建
;   2026-07-17 v1.1 ASTB 修复组 整改：
;             1) 文件编码 UTF-8 转 GBK
;             2) 删除重复入口 ASTB_Util_QuickSearch2（与 SearchStar 相同，
;                对应冗余模块 32_Quick_search.il 已删除）
;             3) 移除 ASTB_Util_TechManager2（27 号模块已 DEPRECATED）
;             4) 各 wrapper 增加被调函数存在性检查，模块未加载时
;                给出提示而非报 unbound function
;   2026-07-17 v1.2 整合工程师：ASTB_Util_Assembly2 由"请用原命令"占位
;             改为经 _ASTB_Util_CallIfLoaded 调用 util_assembly.il 已提供的
;             正式入口 ASTB_AssemblyCmd()，保留 fboundp 防护
;   2026-08-01 v1.3 ASTB Team 菜单裁剪（用户要求）：删除
;             ASTB_Util_EtchLayerView 占位包装（菜单 Etch Layer View 与
;             util_etchlayerview.il 模块同日删除）
;========================================================================

;------------------------------------------------------------------------
; 函数名  : _ASTB_Util_CallIfLoaded
; 功能    : 统一包装：被调函数存在则调用，否则提示模块未加载
; 参数    :
;   @param funcSym   - 被调函数符号
;   @param moduleTip - 模块提示名（用于错误消息）
; 返回值  : t/nil
;------------------------------------------------------------------------
procedure( _ASTB_Util_CallIfLoaded(funcSym moduleTip)
    if( fboundp(funcSym) then
        apply(funcSym nil)
        t
    else
        axlUIConfirm(sprintf(nil "模块未加载或函数缺失: %s\n请检查对应 .il 是否加载成功"
            moduleTip))
        nil
    )
)

;------------------------------------------------------------------------
; ASTB_Util_ColorSetting2 - FanySkill 颜色设置
;------------------------------------------------------------------------
procedure( ASTB_Util_ColorSetting2()
    _ASTB_Util_CallIfLoaded('FanySkill_Color_Setting "util_colorsetting.il")
)

;------------------------------------------------------------------------
; ASTB_Util_EtchCrossPlane - Etch 十字花焊盘设置
;------------------------------------------------------------------------
procedure( ASTB_Util_EtchCrossPlane()
    _ASTB_Util_CallIfLoaded('create_etch_cross_form "util_etchcrossplane.il")
)

;------------------------------------------------------------------------
; ASTB_Util_Assembly2 - Assembly v2（util_assembly.il 正式入口 ASTB_AssemblyCmd）
;------------------------------------------------------------------------
procedure( ASTB_Util_Assembly2()
    _ASTB_Util_CallIfLoaded('ASTB_AssemblyCmd "util_assembly.il")
)

;------------------------------------------------------------------------
; ASTB_Util_SearchStar - 器件/网络搜索定位（util_search.il）
;------------------------------------------------------------------------
procedure( ASTB_Util_SearchStar()
    _ASTB_Util_CallIfLoaded('_SearchStar "util_search.il")
)

;------------------------------------------------------------------------
; ASTB_Util_QuickSaveByTime - 按时间快速另存（util_quicksavebytime.il）
;------------------------------------------------------------------------
procedure( ASTB_Util_QuickSaveByTime()
    _ASTB_Util_CallIfLoaded('wxSaveFileBT "util_quicksavebytime.il")
)

;------------------------------------------------------------------------
; ASTB_Util_SuperNetFinder2 - 超级网络查找器（util_supernetfinder.il）
;------------------------------------------------------------------------
procedure( ASTB_Util_SuperNetFinder2()
    _ASTB_Util_CallIfLoaded('_lgs_super_net_find "util_supernetfinder.il")
)

;------------------------------------------------------------------------
; ASTB_Util_HotkeySetup / HotkeyReset / HotkeyHelp - 快捷键模块入口
;------------------------------------------------------------------------
procedure( ASTB_Util_HotkeySetup()
    _ASTB_Util_CallIfLoaded('HotkeySetup_BindAll "util_hotkeysetup.il")
)

procedure( ASTB_Util_HotkeyReset()
    _ASTB_Util_CallIfLoaded('HotkeySetup_ResetAll "util_hotkeysetup.il")
)

procedure( ASTB_Util_HotkeyHelp()
    _ASTB_Util_CallIfLoaded('HotkeySetup_PrintHelp "util_hotkeysetup.il")
)

; ASTB_Util_HotkeyEditor - 快捷键表单编辑器入口(v1.3)
procedure( ASTB_Util_HotkeyEditor()
    _ASTB_Util_CallIfLoaded('HotkeySetup_Edit "util_hotkeysetup.il")
)

printf("[ASTB] utilities/zz_wrappers.il loaded.\n")
