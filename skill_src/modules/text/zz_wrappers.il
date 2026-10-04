;========================================================================
; 文件名    : zz_wrappers.il
; 作者      : ASTB
; 创建日期  : 2026-07-16
; 版本      : 1.3
; 功能描述  : Text模块命令包装器，为工具箱提供统一的命令接口
; 依赖模块  : text_checkoverlap.il, text_refdeslocation.il, text_refdesrotate.il,
;             text_renamerefdes.il, text_autosilkutils.il,
;             text_textcenterout.il, text_addchinese.il
; 修改记录  :
;   2026-07-16 v1.0 ASTB 初始创建
;   2026-07-18 v1.1 ASTB 修复四个错误包装目标：
;             RefDesLocation  jfhGetAllCompsDBid()  -> jfhRefdesLocate()
;             RefDesRotate    jfhGetRefIDComDir()   -> jfhR_rotateref()（09 文件加 jfhR_ 前缀后的真命令）
;             AutoSilkUtils2  silkutils()           -> ASU_start()
;             TextCenterRout  text_center_rout()    -> ref()（12 号文件 val_c 命令入口）
;             统一 4 空格缩进、补函数注释、修正 printf 文件名笔误
;   2026-07-19 v1.2 ASTB 新增 ASTB_Text_AddChinese（配套 text_addchinese.il，命令 ach）
;   2026-08-22 v1.3 ASTB 删除 ASTB_Text_CheckOverlap2 / ASTB_Text_AutoSilkUtils2
;             两个菜单包装（用户要求下线 v2 入口；v1 菜单项保留，
;             底层模块 text_checkoverlap.il / text_autosilkutils.il 不动）
;========================================================================

;; ============================================================
;; Text wrappers for 精选功能集
;; ============================================================

;------------------------------------------------------------------------
; 函数名  : ASTB_Text_RefDesLocation
; 功能    : 位号重排位置（调用 text_refdeslocation.il 的 jfhRefdesLocate）
;------------------------------------------------------------------------
procedure( ASTB_Text_RefDesLocation()
    jfhRefdesLocate()
)

;------------------------------------------------------------------------
; 函数名  : ASTB_Text_RefDesRotate
; 功能    : 位号方向旋转（调用 text_refdesrotate.il 的 jfhR_rotateref）
;------------------------------------------------------------------------
procedure( ASTB_Text_RefDesRotate()
    jfhR_rotateref()
)

;------------------------------------------------------------------------
; 函数名  : ASTB_Text_RenameRefDes2
; 功能    : 批量重命名位号（调用 text_renamerefdes.il 的 Rename_Ref_Des_Routine）
;------------------------------------------------------------------------
procedure( ASTB_Text_RenameRefDes2()
    Rename_Ref_Des_Routine()
)

;------------------------------------------------------------------------
; 函数名  : ASTB_Text_TextCenterRout
; 功能    : 元件值文本快速重排（调用 text_textcenterout.il 的 ref）
;------------------------------------------------------------------------
procedure( ASTB_Text_TextCenterRout()
    ref()
)

;------------------------------------------------------------------------
; 函数名  : ASTB_Text_AddChinese
; 功能    : 添加中文字符（调用 text_addchinese.il 的 ACH_Run，命令 ach）
;------------------------------------------------------------------------
procedure( ASTB_Text_AddChinese()
    ACH_Run()
)

printf("[ASTB] text/zz_wrappers.il loaded.\n")
