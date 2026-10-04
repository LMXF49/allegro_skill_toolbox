;========================================================================
; 文件名    : util_etchcrossplane.il
; 作者      : WG2005
; 创建日期  : 2009-12-26
; 版本      : 2.2
; 功能描述  : 走线跨平面分割检查：高亮两端点不在同一铜皮内的 cline
;             （即跨分割走线）。原理：取每段走线的两端点，若存在某块
;             铜皮同时包含两端点，则认为该走线未跨分割并取消高亮，
;             剩余高亮部分即为疑似跨分割走线。
; 依赖模块  : 无
; 修改记录  :
;   2026-07-18 v2.2 ASTB 修复组 表单界面汉化：标题/提示文字/分组/按钮/状态栏信息改中文
;   2009-12-26 v1.0 WG2005 初始创建
;   2009-12-26 v2.0 WG2005 表单版（REV2.0）
;   2026 v2.1 修复组 重写作业头与乱码注释（原中文双重编码损毁）、
;             表单文件由 CWD(./c_e_c.form) 改 axlTempFile()、PORT
;             高度 30→36 修复按钮(y=32)越界、INFO 字段 s_p_layey
;             改名 s_p_layer、裸全局变量收敛为 g_ecp_ 前缀 + boundp
;             保护、axlGetSelSet(axlAddSelectAll()) 拆两行并补
;             axlClearSelSet()、选择集判空、删除无效 ?undo t
;========================================================================

; --- 模块级全局状态（表单回调跨调用使用，boundp 保护） ---
; 注： select_layername 阶段暂存层名列表用于填充表单；用户选择后
;     变为当前选中的层字符串（与原版逻辑一致）。
unless(boundp('g_ecp_etchlist)  g_ecp_etchlist  = nil)
unless(boundp('g_ecp_planelist) g_ecp_planelist = nil)

;------------------------------------------------------------------------
; 函数名  : create_etch_cross_form
; 功能    : 生成并显示跨分割检查表单（命令 ecp）
; 返回值  : t 成功 / nil 失败
; 副作用  : 在临时目录创建/删除 .form 文件；弹出表单
;------------------------------------------------------------------------
procedure( create_etch_cross_form()
    prog((formfilePath FORMFILE form)
        formfilePath = axlTempFile()
        FORMFILE = outfile(formfilePath "w")
        unless( FORMFILE
            axlUIConfirm(strcat("无法创建临时表单文件: " formfilePath))
            return(nil)
        )

        fprintf( FORMFILE "FILE_TYPE=FORM_DEFN VERSION=2\n")
        fprintf( FORMFILE "FORM\n")
        fprintf( FORMFILE "FIXED\n")
        fprintf( FORMFILE "PORT 55 36\n")                        ; 窗口大小（按钮 y=32，高度需 ≥36）
        fprintf( FORMFILE "HEADER \"\327\337\317\337\277\347\306\275\303\346\267\326\270\356\274\354\262\351\"\n") ; 窗口标题
        fprintf( FORMFILE "\n")
        fprintf( FORMFILE "TILE\n")

        fprintf( FORMFILE "TEXT \"\321\241\324\361\327\337\317\337\262\343\243\272\"blue_a \n") ; 提示文字 Select Etch Layer
        fprintf( FORMFILE "TLOC  2 1\n")
        fprintf( FORMFILE "ENDTEXT\n\n")

        fprintf( FORMFILE "FIELD etch_list\n")         ; Etch 层列表，选中后在回调中处理
        fprintf( FORMFILE "FLOC 2 3\n")
        fprintf( FORMFILE "LIST \"\" 20 8\n")
        fprintf( FORMFILE "ENDFIELD\n\n")

        fprintf( FORMFILE "TEXT \"\321\241\324\361\306\275\303\346\262\343\243\272\"blue_b \n") ; 提示文字 Select Plane Layer
        fprintf( FORMFILE "TLOC  28 1\n")
        fprintf( FORMFILE "ENDTEXT\n\n")

        fprintf( FORMFILE "FIELD Plane_list\n")        ; Plane 层列表
        fprintf( FORMFILE "FLOC 28 3\n")
        fprintf( FORMFILE "LIST \"\" 20 8\n")
        fprintf( FORMFILE "ENDFIELD\n\n")

        fprintf( FORMFILE "GROUP \"\317\324\312\276\321\241\326\320\262\343\"  \n")    ; 分组：显示当前选中层
        fprintf( FORMFILE "GLOC 2 20\n")
        fprintf( FORMFILE "GSIZE 45 8\n")
        fprintf( FORMFILE "ENDGROUP\n")

        fprintf( FORMFILE "TEXT \"\327\337\317\337\262\343 ->:\"blue_c \n")
        fprintf( FORMFILE "TLOC  4 22\n")
        fprintf( FORMFILE "ENDTEXT\n\n")

        fprintf( FORMFILE "TEXT\n")                    ; 显示选中的 ETCH 层
        fprintf( FORMFILE "TLOC 15 22\n")
        fprintf( FORMFILE "INFO s_e_layer 30\n")
        fprintf( FORMFILE "FSIZE 30 2\n")
        fprintf( FORMFILE "ENDTEXT\n")

        fprintf( FORMFILE "TEXT \"\306\275\303\346\262\343 ->:\"blue_d \n")
        fprintf( FORMFILE "TLOC  4 25\n")
        fprintf( FORMFILE "ENDTEXT\n\n")

        fprintf( FORMFILE "TEXT\n")                    ; 显示选中的 Plane 层
        fprintf( FORMFILE "TLOC 15 25\n")
        fprintf( FORMFILE "INFO s_p_layer 30\n")
        fprintf( FORMFILE "FSIZE 30 2\n")
        fprintf( FORMFILE "ENDTEXT\n")

        fprintf( FORMFILE "FIELD sel_check\n")         ; Check 按钮
        fprintf( FORMFILE "FLOC 10 32\n")
        fprintf( FORMFILE "MENUBUTTON \"\274\354\262\351\" 9 3\n")
        fprintf( FORMFILE "ENDFIELD\n")

        fprintf( FORMFILE "FIELD exit\n")              ; Exit 按钮
        fprintf( FORMFILE "FLOC 32 32\n")
        fprintf( FORMFILE "MENUBUTTON \"\315\313\263\366\" 9 3\n")
        fprintf( FORMFILE "ENDFIELD\n")

        fprintf( FORMFILE "\n")
        fprintf( FORMFILE "ENDTILE\n")
        fprintf( FORMFILE "\n")
        fprintf( FORMFILE "ENDFORM\n")
        close( FORMFILE)

        form = axlFormCreate( (gensym) formfilePath '("E" "OUTER") 'c_etch_Callback t)
        unless( form
            axlUIConfirm("表单创建失败。")
            deleteFile(formfilePath)
            return(nil)
        )
        axlFormDisplay( form)

        _ecp_select_layername(form)     ; 读取 PCB 现有叠层并填充表单

        axlFormColorize( form "blue_a" 'text 'blue)
        axlFormColorize( form "blue_b" 'text 'blue)
        axlFormColorize( form "blue_c" 'text 'blue)
        axlFormColorize( form "blue_d" 'text 'blue)

        axlFormColorize( form "s_e_layer" 'text 'red)   ; 选中的 ETCH 用红色显示
        axlFormColorize( form "s_p_layer" 'text 'red)   ; 选中的 PLANE 用红色显示

        g_ecp_etchlist  = "ETCH/TOP"     ; 初始选中 ETCH/TOP
        g_ecp_planelist = "ETCH/BOTTOM"  ; 初始选中 ETCH/BOTTOM

        axlUIWPrint(form "作者 : WG2005      版本 : REV2.0     日期 : 2009-12-26")

        deleteFile(formfilePath)
        return(t)
    )
)

;------------------------------------------------------------------------
; 函数名  : c_etch_Callback
; 功能    : 表单回调：响应层列表选择 / Check / Exit 按钮
; 参数    : form - 表单句柄（axlFormCreate 指定本回调）
;------------------------------------------------------------------------
procedure( c_etch_Callback(form)
    prog(()
        case( form->curField
            ("etch_list"        ; 选择 Etch 层
                g_ecp_etchlist = form->curValue
                axlFormSetField( form "s_e_layer" g_ecp_etchlist)
                axlVisibleDesign(nil)           ; 关闭所有显示
                axlVisibleLayer( g_ecp_planelist t)
                axlVisibleLayer( g_ecp_etchlist t)
                axlVisibleUpdate(t)
                t
            )
            ("Plane_list"       ; 选择 Plane 层
                g_ecp_planelist = form->curValue
                axlFormSetField( form "s_p_layer" g_ecp_planelist)
                axlVisibleDesign(nil)
                axlVisibleLayer( g_ecp_planelist t)
                axlVisibleLayer( g_ecp_etchlist t)
                axlVisibleUpdate(t)
                t
            )
            ("sel_check"        ; Check 按钮：执行跨分割检查
                _ecp_e_c_plane()
                t
            )
            ("exit"             ; Exit 按钮
                axlFormClose( form)
                t
            )
            (t t)
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : _ecp_select_layername
; 功能    : 读取当前设计叠层，按 CONDUCTOR/PLANE 分类并填充表单列表
; 参数    : form - 表单句柄（显式传参，原版通过裸全局耦合）
;------------------------------------------------------------------------
procedure( _ecp_select_layername(form)
    prog((etchparam l_layers layerlista nlayer)
        etchparam = axlGetParam("paramLayerGroup:ETCH")
        unless( etchparam
            return(nil)
        )
        l_layers = etchparam->groupMembers   ; 如 ("TOP" "GND02" "POWER03" "BOTTOM")

        g_ecp_etchlist = nil
        g_ecp_planelist = nil

        foreach( nlayer l_layers
            layerlista = strcat("ETCH/" nlayer)
            when( axlDBGetLayerType(layerlista) == "PLANE"
                g_ecp_planelist = cons(layerlista g_ecp_planelist)
            )
            when( axlDBGetLayerType(layerlista) == "CONDUCTOR"
                g_ecp_etchlist = cons(layerlista g_ecp_etchlist)
            )
        )

        g_ecp_etchlist  = reverse(g_ecp_etchlist)
        g_ecp_planelist = reverse(g_ecp_planelist)

        axlFormSetField( form "etch_list" g_ecp_etchlist)
        axlFormSetField( form "Plane_list" g_ecp_planelist)
    )
)

;------------------------------------------------------------------------
; 函数名  : _ecp_e_c_plane
; 功能    : 执行跨分割检查：高亮全部 cline 后，凡两端点落在同一
;           铜皮内的取消高亮，剩余高亮即为疑似跨分割走线
; 副作用  : 修改对象高亮状态（不改数据库）；可见性预览是用户预期结果
;------------------------------------------------------------------------
procedure( _ecp_e_c_plane()
    prog((clines_a shape_a Clinc_xy c_xy_a c_xy_b)
        ; 先清空旧选择集，避免用户既有选择混入导致高亮错误
        axlClearSelSet()
        axlSetFindFilter(?enabled '(noall clinesegs) ?onButtons '(noall clinesegs))
        axlAddSelectAll()
        clines_a = axlGetSelSet()

        axlClearSelSet()
        axlSetFindFilter(?enabled '(noall shapes) ?onButtons '(noall shapes))
        axlAddSelectAll()
        shape_a = axlGetSelSet()

        axlClearSelSet()

        unless( and(clines_a shape_a)
            axlUIConfirm("未获取到走线或铜皮，请确认设计内存在 cline 和 shape。")
            return(nil)
        )

        axlHighlightObject(clines_a)    ; 先全部高亮

        foreach( Cline clines_a
            Clinc_xy = Cline->startEnd  ; 该 cline 的起止点
            c_xy_a = car(Clinc_xy)      ; 起点
            c_xy_b = cadr(Clinc_xy)     ; 终点
            foreach( shape shape_a
                if( and(axlGeoPointInShape(c_xy_b shape) axlGeoPointInShape(c_xy_a shape)) then
                    ; 两端点落在同一铜皮内：未跨分割，取消高亮
                    axlDehighlightObject(Cline)
                )
            )
        )
        return(t)
    )
)

; 命令注册（纯高亮/预览操作，不改数据库，不挂 ?undo）
axlCmdRegister( "ecp" 'create_etch_cross_form)
