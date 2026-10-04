;========================================================================
; 文件名    : util_colorsetting.il
; 作者      : FanySkill (Modify by longxf)
; 创建日期  : 2020-01-01
; 版本      : 1.1
; 功能描述  : 配色方案工具：一键切换整套 PCB 层颜色（Etch/Pin/Via/
;             DRC/边界/Anti Etch/约束区/Keepout 等），提供
;             FYCOL / FYCOL1 / FYCOL2 三套方案。
; 依赖模块  : 无
; 警告      : 本模块通过 axlColorSet 直接改写全局调色板索引
;             5/41/45/63 的 RGB 定义，会影响当前版图所有使用这些
;             索引号的对象。首次执行前自动备份原调色板，可执行
;             FYCOLR 命令恢复。
; 修改记录  :
;   2020-01-01 v1.0 (Modify by longxf) 初始创建
;   2026 v1.1 修复组 重写作业头与乱码注释、8 个裸全局颜色变量加
;             g_fcs_ 前缀与 boundp 保护、三套方案合并为数据表驱动
;             （etchcolorslist 改显式传参）、Etch 层超过色板长度时
;             取模保护、BOTTOM 按名字定位（兼容背钻/非标叠层）、
;             层对象判空、循环内 axlVisibleUpdate 合并为一次、新增
;             调色板备份与 FYCOLR 恢复命令、删除无效 ?undo t
;========================================================================

/*
#############################################################################
#  历史信息（原始 FanySkill 头，仅作来源说明保留）
#  Command    : FYCOL / FYCOL1 / FYCOL2
#  Skill File : FanySkill_Color_Setting.il
#  Modify by  : longxf 2020-1-1   Download: https://pcbbar.com/
#############################################################################
*/

; --- 调色板 RGB 定义（g_fcs_ 前缀 + boundp 保护，避免与其他模块同名冲突） ---
unless(boundp('g_fcs_white)    g_fcs_white    = '(255 255 255))
unless(boundp('g_fcs_blank)    g_fcs_blank    = '(0 0 0))
unless(boundp('g_fcs_darkred)  g_fcs_darkred  = '(169 5 18))
unless(boundp('g_fcs_lightred) g_fcs_lightred = '(255 0 0))
unless(boundp('g_fcs_green)    g_fcs_green    = '(0 221 0))
unless(boundp('g_fcs_blue)     g_fcs_blue     = '(18 18 225))
unless(boundp('g_fcs_qingse)   g_fcs_qingse   = '(0 255 255))
unless(boundp('g_fcs_zise)     g_fcs_zise     = '(255 0 255))

; --- 三套方案的 Etch 层色板（BOTTOM 固定用第 1 个颜色，其余按叠层顺序） ---
unless(boundp('g_fcs_scheme0) g_fcs_scheme0 = '(12 5 40 43 36 53 41 65 73 80 111 119 6 10 18 24))
unless(boundp('g_fcs_scheme1) g_fcs_scheme1 = '(64 5 43 36 53 45 65 73 80 111 119 6 10 18 24 40))
unless(boundp('g_fcs_scheme2) g_fcs_scheme2 = '(5 41 43 36 53 45 65 73 80 111 119 6 10 18 24 40))

; --- 调色板备份（首次应用方案时保存，供 FYCOLR 恢复） ---
unless(boundp('g_fcs_palette_backup) g_fcs_palette_backup = nil)

;------------------------------------------------------------------------
; 函数名  : _fcs_set_layer_color
; 功能    : 设置单个 类/子类 的颜色；层不存在时静默跳过（判空保护）
;------------------------------------------------------------------------
procedure( _fcs_set_layer_color(layerName color)
    prog((lay)
        lay = axlLayerGet(layerName)
        when( lay
            lay->color = color
            axlLayerSet(lay)
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : _fcs_apply_palette
; 功能    : 首次执行前备份调色板 5/41/45/63，然后写入方案调色板定义
; 参数    : color63 - 该方案的 63 号索引 RGB
; 副作用  : 改写全局调色板（见文件头警告）
;------------------------------------------------------------------------
procedure( _fcs_apply_palette(color63)
    prog((idx)
        unless( g_fcs_palette_backup
            foreach( idx '(5 41 45 63)
                g_fcs_palette_backup = cons(cons(idx axlColorGet(idx)) g_fcs_palette_backup)
            )
        )
        axlColorSet(5 g_fcs_darkred)
        axlColorSet(41 '(0 221 0))
        axlColorSet(45 '(100 100 255))   ; 浅蓝色
        axlColorSet(63 color63)
    )
)

;------------------------------------------------------------------------
; 函数名  : FanySkill_Color_Restore
; 功能    : 恢复执行配色方案前的原始调色板（命令 FYCOLR）
;------------------------------------------------------------------------
procedure( FanySkill_Color_Restore()
    prog((entry)
        if( g_fcs_palette_backup then
            foreach( entry g_fcs_palette_backup
                axlColorSet(car(entry) cdr(entry))
            )
            axlVisibleUpdate(t)
            printf("[FYCOLR] Palette restored.\n")
        else
            printf("[FYCOLR] No palette backup found.\n")
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : _fcs_quick_colorset
; 功能    : 按方案色板设置全部相关层颜色（三套方案共用的核心逻辑）
; 参数    : etchcolorslist - Etch 层色板；color63 - 调色板 63 号 RGB
; 副作用  : 修改各层颜色与全局调色板，结束后统一刷新显示一次
;------------------------------------------------------------------------
procedure( _fcs_quick_colorset(etchcolorslist color63)
    prog((etchl etchlayers etchlnum drclayers vialayers boundarylayers
          antietchlayers regionlayers viaoutlayers rtoutlayers
          i cursetlayer setcolor one)
        _fcs_apply_palette(color63)

        ; BOTTOM 固定取色板第 1 个颜色（按名字定位，而非假设在叠层表尾）
        etchl = axlGetParam("paramLayerGroup:ETCH")->groupMembers
        if( setof(x etchl x == "BOTTOM") then
            etchlayers = cons("BOTTOM" setof(x etchl x != "BOTTOM"))
        else
            etchlayers = etchl
        )
        etchlnum = length(etchlayers)

        drclayers      = axlGetParam("paramLayerGroup:Drc Error Class")->groupMembers
        vialayers      = axlGetParam("paramLayerGroup:Via Class")->groupMembers
        boundarylayers = axlGetParam("paramLayerGroup:Boundary")->groupMembers
        antietchlayers = axlGetParam("paramLayerGroup:Anti Etch")->groupMembers
        regionlayers   = axlGetParam("paramLayerGroup:Constraint Region")->groupMembers
        viaoutlayers   = axlGetParam("paramLayerGroup:Via Keepout")->groupMembers
        rtoutlayers    = axlGetParam("paramLayerGroup:Route Keepout")->groupMembers

        ; --- Etch / Pin 层按色板逐层着色（层数超过色板长度时取模循环） ---
        i = 0
        while( i < etchlnum
            cursetlayer = nth(i etchlayers)
            setcolor = nth(mod(i length(etchcolorslist)) etchcolorslist)
            _fcs_set_layer_color(sprintf(nil "PIN/%s" cursetlayer) setcolor)
            _fcs_set_layer_color(sprintf(nil "ETCH/%s" cursetlayer) setcolor)
            i++
        )

        ; --- 其余类固定配色 ---
        foreach( one drclayers
            _fcs_set_layer_color(sprintf(nil "Drc Error Class/%s" one) 150)
        )
        foreach( one vialayers
            _fcs_set_layer_color(sprintf(nil "Via Class/%s" one) 28)
        )
        foreach( one boundarylayers
            _fcs_set_layer_color(sprintf(nil "Boundary/%s" one) 9)
        )
        foreach( one antietchlayers
            _fcs_set_layer_color(sprintf(nil "Anti Etch/%s" one) 22)
        )
        foreach( one regionlayers
            _fcs_set_layer_color(sprintf(nil "Constraint Region/%s" one) 24)
        )
        foreach( one viaoutlayers
            _fcs_set_layer_color(sprintf(nil "Via Keepout/%s" one) 40)
        )
        foreach( one rtoutlayers
            _fcs_set_layer_color(sprintf(nil "Route Keepout/%s" one) 200)
        )

        ; --- 其他固定层 ---
        _fcs_set_layer_color("PACKAGE GEOMETRY/SILKSCREEN_TOP" 34)
        _fcs_set_layer_color("PACKAGE GEOMETRY/SILKSCREEN_BOTTOM" 28)
        _fcs_set_layer_color("BOARD GEOMETRY/SILKSCREEN_TOP" 24)
        _fcs_set_layer_color("BOARD GEOMETRY/SILKSCREEN_BOTTOM" 28)
        _fcs_set_layer_color("BOARD GEOMETRY/OUTLINE" 120)
        _fcs_set_layer_color("REF DES/SILKSCREEN_TOP" 24)
        _fcs_set_layer_color("REF DES/SILKSCREEN_BOTTOM" 28)
        _fcs_set_layer_color("ROUTE KEEPIN/ALL" 200)

        ; 全部设置完成后统一刷新一次（避免循环内反复重绘卡顿）
        axlVisibleUpdate(t)
    )
)

;------------------------------------------------------------------------
; 三套配色方案入口（命令 FYCOL / FYCOL1 / FYCOL2）
;------------------------------------------------------------------------
procedure( FanySkill_Color_Setting()
    _fcs_quick_colorset(g_fcs_scheme0 '(255 111 255))
)

procedure( FanySkill_Color_Setting1()
    _fcs_quick_colorset(g_fcs_scheme1 g_fcs_white)
)

procedure( FanySkill_Color_Setting2()
    _fcs_quick_colorset(g_fcs_scheme2 g_fcs_white)
)

; 命令注册（仅修改显示颜色，不走数据库事务，不挂 ?undo）
axlCmdRegister( "FYCOL"  'FanySkill_Color_Setting)
axlCmdRegister( "FYCOL1" 'FanySkill_Color_Setting1)
axlCmdRegister( "FYCOL2" 'FanySkill_Color_Setting2)
axlCmdRegister( "FYCOLR" 'FanySkill_Color_Restore)
