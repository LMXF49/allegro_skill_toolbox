;========================================================================
; 文件名    : route_checksplit.il
; 作者      : Allegro SKILL Toolbox
; 创建日期  : 2026-07-16
; 版本      : 1.2
; 功能描述  : 跨分割检查（Etch Cross Plane）：对所选走线层上的线段，
;             若其两端点未同时落在所选平面层的某块铜皮内则保持高亮，
;             用于检查走线跨分割问题（纯高亮工具，不修改数据库）
; 依赖模块  : core/menu.il, core/utils.il
; 修改记录  :
;   2026-07-16 v1.0 Allegro SKILL Toolbox 初始创建（源自 WG2005 ecp）
;   2026-07-17 v1.1 Allegro SKILL Toolbox 整改：
;                   1) 核心判定按 GUI 所选层过滤（cline 层==etch 层、
;                      shape 层==plane 层），修复忽略界面选择的误报
;                   2) 表单 PORT 高度 30->38，修复 Check/Exit 按钮被裁剪
;                   3) 临时 .form 改写到 axlTempDirectory() 并检查返回值
;                   4) 删除与 ASTB_RegisterCommand 重复的 axlCmdRegister
;                   5) 退出时恢复全板显示；补全变量绑定与中文注释
;   2026-07-18 v1.2 Allegro SKILL Toolbox 界面汉化
;========================================================================

;------------------------------------------------------------------------
; 跨函数共享的界面选择结果（表单回调异步触发，必须为全局）
;------------------------------------------------------------------------
unless( boundp('g_etchlist)
    g_etchlist = nil
)
unless( boundp('g_planelist)
    g_planelist = nil
)

;------------------------------------------------------------------------
; 函数名  : create_etch_cross_form
; 功能    : 生成临时表单文件并显示“跨分割检查”界面
; 返回值  : 表单句柄；失败返回 nil
;------------------------------------------------------------------------
procedure( create_etch_cross_form()
    prog( (formPath FORMFILE form)
        ; --- 临时表单文件写入系统临时目录，避免污染 Allegro 当前工作目录 ---
        formPath = strcat(axlTempDirectory() "/c_e_c.form")
        FORMFILE = outfile(formPath "w")
        unless( FORMFILE
            axlUIConfirm("无法创建临时表单文件，请检查临时目录权限")
            return(nil)
        )

        fprintf( FORMFILE "FILE_TYPE=FORM_DEFN VERSION=2\n")  ; 表单定义文件头
        fprintf( FORMFILE "FORM\n")
        fprintf( FORMFILE "FIXED\n")
        fprintf( FORMFILE "PORT 55 38\n")                      ; 高度需容纳第32行的按钮
        fprintf( FORMFILE "HEADER \"\277\347\267\326\270\356\274\354\262\351\"\n")
        fprintf( FORMFILE "\n")
        fprintf( FORMFILE "TILE\n")

        fprintf( FORMFILE "TEXT \"\321\241\324\361\327\337\317\337\262\343:\"blue_a \n")  ; 走线层选择标签
        fprintf( FORMFILE "TLOC  2 1\n")
        fprintf( FORMFILE "ENDTEXT\n\n")

        fprintf( FORMFILE "FIELD etch_list\n")               ; 走线层列表字段
        fprintf( FORMFILE "FLOC 2 3\n")
        fprintf( FORMFILE "LIST \"\" 20 8\n")
        fprintf( FORMFILE "ENDFIELD\n\n")

        fprintf( FORMFILE "TEXT \"\321\241\324\361\306\275\303\346\262\343:\"blue_b \n") ; 平面层选择标签
        fprintf( FORMFILE "TLOC  28 1\n")
        fprintf( FORMFILE "ENDTEXT\n\n")

        fprintf( FORMFILE "FIELD Plane_list\n")              ; 平面层列表字段
        fprintf( FORMFILE "FLOC 28 3\n")
        fprintf( FORMFILE "LIST \"\" 20 8\n")
        fprintf( FORMFILE "ENDFIELD\n\n")

        fprintf( FORMFILE "GROUP \"\265\261\307\260\321\241\324\361\265\304\262\343\"  \n")  ; 当前选择回显分组
        fprintf( FORMFILE "GLOC 2 20\n")
        fprintf( FORMFILE "GSIZE 45 8\n")
        fprintf( FORMFILE "ENDGROUP\n")

        fprintf( FORMFILE "TEXT \"\327\337\317\337\262\343 ->:\"blue_c \n")
        fprintf( FORMFILE "TLOC  4 22\n")
        fprintf( FORMFILE "ENDTEXT\n\n")

        fprintf( FORMFILE "TEXT\n")                          ; 回显当前 Etch 层
        fprintf( FORMFILE "TLOC 15 22\n")
        fprintf( FORMFILE "INFO s_e_layer 30\n")
        fprintf( FORMFILE "FSIZE 30 2\n")
        fprintf( FORMFILE "ENDTEXT\n")

        fprintf( FORMFILE "TEXT \"\306\275\303\346\262\343 ->:\"blue_d \n")
        fprintf( FORMFILE "TLOC  4 25\n")
        fprintf( FORMFILE "ENDTEXT\n\n")

        fprintf( FORMFILE "TEXT\n")                          ; 回显当前 Plane 层
        fprintf( FORMFILE "TLOC 15 25\n")
        fprintf( FORMFILE "INFO s_p_layey 30\n")
        fprintf( FORMFILE "FSIZE 30 2\n")
        fprintf( FORMFILE "ENDTEXT\n")

        fprintf( FORMFILE "FIELD sel_check\n")               ; Check 按钮
        fprintf( FORMFILE "FLOC 10 32\n")
        fprintf( FORMFILE "MENUBUTTON \"\274\354\262\351\" 9 3\n")
        fprintf( FORMFILE "ENDFIELD\n")

        fprintf( FORMFILE "FIELD exit\n")                    ; Exit 按钮
        fprintf( FORMFILE "FLOC 32 32\n")
        fprintf( FORMFILE "MENUBUTTON \"\315\313\263\366\" 9 3\n")
        fprintf( FORMFILE "ENDFIELD\n")

        fprintf( FORMFILE "\n")
        fprintf( FORMFILE "ENDTILE\n")
        fprintf( FORMFILE "\n")
        fprintf( FORMFILE "ENDFORM\n")
        close( FORMFILE)

        ; --- 创建并显示表单 ---
        form = axlFormCreate( (gensym) formPath `("E" "OUTER") 'c_etch_Callback t)
        unless( form
            axlUIConfirm("创建检查表单失败")
            deleteFile(formPath)
            return(nil)
        )
        axlFormDisplay( form)

        ; --- 从当前 PCB 读取层列表并填充表单 ---
        select_layername(form)

        axlFormColorize( form "blue_a" 'text 'blue)          ; 标签着色
        axlFormColorize( form "blue_b" 'text 'blue)
        axlFormColorize( form "blue_c" 'text 'blue)
        axlFormColorize( form "blue_d" 'text 'blue)
        axlFormColorize( form "s_e_layer" 'text 'red)        ; 回显着色
        axlFormColorize( form "s_p_layey" 'text 'red)

        ; --- 默认选中各自层列表的第一层（不再硬编码 TOP/BOTTOM） ---
        when( g_etchlist
            g_etchlist = car(g_etchlist)
            axlFormSetField( form "s_e_layer" g_etchlist)
        )
        when( g_planelist
            g_planelist = car(g_planelist)
            axlFormSetField( form "s_p_layey" g_planelist)
        )

        axlUIWPrint(form "编写 : WG2005      修订 : REV2.0     日期 : 2009-12-26")

        unless( deleteFile(formPath)                         ; 表单已解析，删除临时文件
            printf("[WARN] 删除临时表单文件失败: %s\n" formPath)
        )
        form
    )
)

;------------------------------------------------------------------------
; 函数名  : c_etch_Callback
; 功能    : 表单字段回调：记录层选择、刷新显隐、执行检查、退出恢复
;------------------------------------------------------------------------
procedure( c_etch_Callback(form)
    prog( ()
        case( form->curField
            ("etch_list"                                     ; 选择走线层
                g_etchlist = form->curValue
                axlFormSetField( form "s_e_layer" g_etchlist)
                when( g_etchlist && g_planelist              ; 只显示所选两层
                    axlVisibleDesign(nil)
                    axlVisibleLayer( g_planelist t )
                    axlVisibleLayer( g_etchlist t )
                    axlVisibleUpdate(t)
                )
                t
            )
            ("Plane_list"                                    ; 选择平面层
                g_planelist = form->curValue
                axlFormSetField( form "s_p_layey" g_planelist)
                when( g_etchlist && g_planelist
                    axlVisibleDesign(nil)
                    axlVisibleLayer( g_planelist t )
                    axlVisibleLayer( g_etchlist t )
                    axlVisibleUpdate(t)
                )
                t
            )
            ("sel_check"                                     ; 执行跨分割检查
                e_c_plane()
                t
            )
            ("exit"                                          ; 恢复全板显示并关闭
                axlVisibleDesign(t)
                axlVisibleUpdate(t)
                axlFormClose( form)
                t
            )
            (t
                nil
            )
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : select_layername
; 功能    : 读取当前设计的 ETCH 层，按 CONDUCTOR/PLANE 分类填入表单
; 参数    : form - 表单句柄
;------------------------------------------------------------------------
procedure( select_layername(form)
    prog( (etchparam l_layers layerlista)
        etchparam = axlGetParam("paramLayerGroup:ETCH")
        l_layers = etchparam->groupMembers        ; 如 ("TOP" "GND02" "POWER03" "BOTTOM")

        g_etchlist = nil
        g_planelist = nil

        foreach( nlayer l_layers
            layerlista = strcat("ETCH/" nlayer)   ; 拼成完整层名 "ETCH/TOP"
            when( axlDBGetLayerType(layerlista) == "PLANE"
                g_planelist = cons(layerlista g_planelist)
            )
            when( axlDBGetLayerType(layerlista) == "CONDUCTOR"
                g_etchlist = cons(layerlista g_etchlist)
            )
        )

        g_etchlist = reverse(g_etchlist)          ; 恢复层叠顺序
        g_planelist = reverse(g_planelist)

        axlFormSetField( form "etch_list" g_etchlist)
        axlFormSetField( form "Plane_list" g_planelist)
    )
)

;------------------------------------------------------------------------
; 函数名  : e_c_plane
; 功能    : 跨分割检查核心：对所选走线层上的线段，若其两端点未同时
;           落在所选平面层的同一块铜皮内，则保持高亮（视为跨分割）
; 副作用  : 仅高亮/去高亮，不修改数据库
;------------------------------------------------------------------------
procedure( e_c_plane()
    prog( (clines_a shape_a Clinc_xy c_xy_a c_xy_b)
        axlSetFindFilter(?enabled '(noall clinesegs) ?onButtons '(noall clinesegs))
        axlClearSelSet()
        axlAddSelectAll()
        clines_a = axlGetSelSet()                 ; 全板走线段

        axlSetFindFilter(?enabled '(noall shapes) ?onButtons '(noall shapes))
        axlClearSelSet()
        axlAddSelectAll()
        shape_a = axlGetSelSet()                  ; 全板铜皮

        axlClearSelSet()

        ; --- 关键修复：按 GUI 所选层过滤，其他层不参与判定 ---
        clines_a = setof(x clines_a (x->layer == g_etchlist))
        shape_a  = setof(x shape_a  (x->layer == g_planelist))

        axlDehighlightObject(nil)                 ; 清旧高亮，避免多次运行叠加
        axlHighlightObject(clines_a)              ; 先全部高亮

        foreach( Cline clines_a
            Clinc_xy = Cline->startEnd            ; 线段两端点
            c_xy_a = car(Clinc_xy)
            c_xy_b = cadr(Clinc_xy)
            foreach( shape shape_a
                when( axlGeoPointInShape(c_xy_b shape) && axlGeoPointInShape(c_xy_a shape)
                    axlDehighlightObject(Cline)   ; 两端都在铜皮内 -> 未跨分割
                )
            )
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_Route_CheckSplit
; 功能    : 命令入口（纯查询/高亮工具，不修改数据库，不挂 undo）
;------------------------------------------------------------------------
procedure( ASTB_Route_CheckSplit()
    create_etch_cross_form()
)

ASTB_RegisterCommand("ASTB_Route_CheckSplit" "ASTB_Route_CheckSplit"
    ?cmdType "interactive" ?undo nil)

printf("[ASTB] route_checksplit.il loaded.\n")
