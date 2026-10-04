;========================================================================
; 文件名    : zz_wrappers.il
; 作者      : ASTB Team
; 创建日期  : 2024
; 版本      : 1.4
; 功能描述  : Manufacturing 模块统一包装器，提供标准化命令入口
; 依赖模块  : mfg_filmreorder.il, mfg_gerbersetup.il
; 修改记录  :
;   2026-10-01 v1.4 ASTB Team 删除 ASTB_Mfg_FilmReorder 包装器
;                     （mfg_filmreorder.il 随 Film重排序功能下线）
;   2024 v1.0 ASTB Team 初始创建
;   2026-07-18 v1.1 ASTB Team 整改：CAMZip 改调 _LJJ_camzip（20/25 撞名
;             已修复，原 CAM Zip 菜单误执行清空操作）、各入口加 fboundp
;             防护、修正加载日志文件名、统一 4 空格缩进
;   2026-07-19 v1.2 ASTB Team 新增 ASTB_Mfg_GerberSetup（配套 mfg_gerbersetup.il，命令 gbs）
;   2026-08-01 v1.3 ASTB Team 菜单裁剪（用户要求）：Manufacturing 只保留
;             Film Reorder / Gerber Setup，删除 AutoBalance2 / BRD2PADS /
;             CAMOut / CAMZip / QuickExportARK / CAMClear2 六个包装
;             （对应模块文件同日删除）
;========================================================================

;; ============================================================
;; Manufacturing wrappers for 精选功能集
;; ============================================================

;------------------------------------------------------------------------
; 函数名  : _ASTB_Mfg_CheckLoaded
; 功能    : 检查目标函数是否已定义；loader 对加载失败的模块只记日志
;           不中止，无防护时会直接报 unbound function
; 参数    : funcSym - 目标函数符号
; 返回值  : t - 已加载；nil - 未加载（已弹窗提示）
;------------------------------------------------------------------------
procedure( _ASTB_Mfg_CheckLoaded(funcSym)
    if( fboundp(funcSym) then
        t
    else
        ASTB_MsgBox(sprintf(nil
            "Module function %s not loaded, check Allegro log" funcSym))
        nil
    )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_Mfg_GerberSetup
; 功能    : Gerber 加工文件一键输出（入口 mfg_gerbersetup.il 的 GBS_Run）
;------------------------------------------------------------------------
procedure( ASTB_Mfg_GerberSetup()
    when( _ASTB_Mfg_CheckLoaded('GBS_Run)
        GBS_Run()
    )
)

printf("[ASTB] manufacturing/zz_wrappers.il loaded.\n")
