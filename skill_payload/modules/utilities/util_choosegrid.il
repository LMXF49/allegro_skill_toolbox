;========================================================================
; 文件名    : util_choosegrid.il
; 作者      : Richard L / Toolbox
; 创建日期  : 2025
; 版本      : 1.3
; 功能描述  : 栅格选择工具：弹出表单列出常用栅格值，点击后通过 replay
;             脚本修改当前设计的 non-etch / all-etch 栅格
; 依赖模块  : core/trans.il (ASTB_RegisterCommand)
; 修改记录  :
;   2026-07-18 v1.2 ASTB 修复组 表单界面汉化：窗口标题改中文
;   2026-08-24 v1.3 ASTB 修改: 表单增加"关闭"按钮(TOOLWINDOW 无系统关闭控件),
;             回调 _cg_GridsAction 增加 close_grid 分支 axlFormClose;
;             prog 内补全程 return(4.13 坑)
;   2025 v1.0 Toolbox 整合到工具箱
;   2026 v1.1 修复组 重写作业头（原中文头双重编码损毁）、裸全局变量
;             收敛为 g_cg_ 前缀 + boundp 保护、本地补齐项目内缺失的
;             f_FormBegin/f_CheckList/f_FormEnd、axlFormCreate 实参
;             由 6 个修正为 5 个、字段匹配由 evalstring 浮点比较改为
;             字符串比较、删除无效的 ?undo t、?cmdType 符号改字符串
;========================================================================

/*
#############################################################################
#  历史信息（原始 FanySkill 头，仅作来源说明保留）
#  Command    : FYCW
#  Skill File : FanySkill_ChooseGrid.il
#  Write by   : Richard L
#############################################################################
*/

; --- 模块级全局状态（表单回调跨调用使用，boundp 保护） ---
unless(boundp('g_cg_GridsZoomList)
    g_cg_GridsZoomList = '(200 100 50 39.37 31.5 25 10 5 1 0.1)
)
unless(boundp('g_cg_cnv_factor)
    g_cg_cnv_factor = 1.0
)

;------------------------------------------------------------------------
; 表单文件辅助函数（源自原 FanySkill 库）
; 注意：本工具箱项目内原本没有这三个函数的定义，调用即崩溃，此处本地
; 补齐。加 fboundp 防御：若其他模块已定义同名函数则不覆盖。
; options 参数目前忽略（原调用传 "TOOLWINDOW"，手册中无该语法依据，
; 按标准 FIXED 表单生成）。
;------------------------------------------------------------------------
unless(fboundp('f_FormBegin)
    procedure( f_FormBegin(p width height title @optional (options nil))
        fprintf(p "FILE_TYPE=FORM_DEFN VERSION=2\n")
        fprintf(p "FORM\n")
        fprintf(p "FIXED\n")
        fprintf(p "PORT %d %d\n" width max(height 6))
        fprintf(p "HEADER \"%s\"\n" title)
        fprintf(p "TILE\n")
    )
)

unless(fboundp('f_CheckList)
    procedure( f_CheckList(p fieldName x y text group)
        fprintf(p "FIELD %s\n" fieldName)
        fprintf(p "FLOC %d %d\n" x y)
        fprintf(p "CHECKLIST \"%s\" \"%s\"\n" text group)
        fprintf(p "ENDFIELD\n")
    )
)

unless(fboundp('f_FormEnd)
    procedure( f_FormEnd(p)
        fprintf(p "ENDTILE\n")
        fprintf(p "ENDFORM\n")
    )
)

;------------------------------------------------------------------------
; 函数名  : _cg_CreateFormForGrids
; 功能    : 按当前单位动态生成栅格选择表单文件（写入临时目录）
; 参数    : units - 当前数据库单位字符串
; 返回值  : 表单文件路径（成功） / nil（失败）
; 副作用  : 在 axlTempFile() 指定的临时目录创建 .form 文件
;------------------------------------------------------------------------
procedure( _cg_CreateFormForGrids(units)
    prog((MainFormFile p GridsZoomName filename totalWidth title xpos i)
        MainFormFile = axlTempFile()
        p = outfile(MainFormFile "w")
        unless( p
            axlUIConfirm(strcat("\316\336\267\250\264\264\275\250\301\331\312\261\261\355\265\245\316\304\274\376: " MainFormFile))
            return(nil)
        )

        ; 各档位按当前单位换算为显示字符串
        GridsZoomName = nil
        for( i 0 length(g_cg_GridsZoomList)-1
            sprintf(filename "%g" g_cg_cnv_factor*nth(i g_cg_GridsZoomList))
            GridsZoomName = cons(filename GridsZoomName)
        )

        totalWidth = 0
        for( i 0 length(GridsZoomName)-1
            totalWidth = totalWidth+strlen(nth(i GridsZoomName))+3
        )
        totalWidth = totalWidth+10    ;--- v1.3: 预留关闭按钮宽度 ---

        sprintf(title "\325\244\270\361\271\244\276\337 - \265\245\316\273 : %s" units)
        f_FormBegin(p totalWidth 0 title "TOOLWINDOW")
        xpos = 1
        for( i 0 length(GridsZoomName)-1
            f_CheckList(p nth(i GridsZoomName) xpos 0 nth(i GridsZoomName) "gg")
            xpos = xpos+strlen(nth(i GridsZoomName))+3
        )
        ;--- v1.3: 关闭按钮(TOOLWINDOW 无系统关闭控件) ---
        fprintf(p "FIELD close_grid\n")
        fprintf(p "FLOC %d 0\n" xpos)
        fprintf(p "MENUBUTTON \"\271\330\261\325\" 6 3\n")
        fprintf(p "ENDFIELD\n")
        f_FormEnd(p)
        close(p)
        return(MainFormFile)
    )
)

;------------------------------------------------------------------------
; 函数名  : FanySkill_ChooseGrid
; 功能    : 栅格选择工具主入口（命令 FYCW / ASTB_Util_ChooseGrid）
; 返回值  : t 成功 / nil 失败
; 副作用  : 弹出表单；写/删临时表单文件
;------------------------------------------------------------------------
procedure( FanySkill_ChooseGrid()
    prog((units gform_file gridsform)
        ; 不同数据库单位的显示换算系数
        units = car(axlDBGetDesignUnits())
        cond(
            (equal(units "microns")     (g_cg_cnv_factor = 1000.00))
            (equal(units "mils")        (g_cg_cnv_factor = 1.00))
            (equal(units "inches")      (g_cg_cnv_factor = 0.10))
            (equal(units "millimeters") (g_cg_cnv_factor = 1.0))
            (equal(units "centimeters") (g_cg_cnv_factor = 0.254))
            (t                          (g_cg_cnv_factor = 1.0))
        )

        drain()
        gform_file = _cg_CreateFormForGrids(units)
        unless( gform_file
            return(nil)
        )
        ; 手册签名 axlFormCreate(g_var t_file l_placement g_callback t_mapButton)，共 5 个实参
        gridsform = axlFormCreate((gensym) gform_file '("NE" "msglines" 0) '_cg_GridsAction t)
        unless( gridsform
            axlUIConfirm("\325\244\270\361\261\355\265\245\264\264\275\250\312\247\260\334\241\243")
            deleteFile(gform_file)
            return(nil)
        )
        axlUIWPerm(gridsform t)
        axlFormDisplay(gridsform)
        deleteFile(gform_file)
        return(t)
    )
)

;------------------------------------------------------------------------
; 函数名  : _cg_GridsAction
; 功能    : 栅格表单回调：按字段名反查对应栅格值并应用
; 参数    : gridsform - 表单句柄
; 说明    : 字段名即显示值字符串（sprintf "%g" 生成），直接字符串
;           比较，避免 evalstring 浮点精确比较与异常输入崩溃
;------------------------------------------------------------------------
procedure( _cg_GridsAction(gridsform)
    prog((i name val)
        if( gridsform->curField == "close_grid" then
            axlFormClose(gridsform)    ;--- v1.3: 关闭按钮 ---
            return(t)
        )
        for( i 0 length(g_cg_GridsZoomList)-1
            val = g_cg_cnv_factor*nth(i g_cg_GridsZoomList)
            sprintf(name "%g" val)
            when( gridsform->curField == name
                _cg_UC_grids_script_create(val gridsform)
            )
        )
        return(t)
    )
)

;------------------------------------------------------------------------
; 函数名  : _cg_UC_grids_script_create
; 功能    : 生成临时 scr 脚本并 replay，修改 non-etch 与 all-etch 栅格
; 参数    : cur_grid  - 目标栅格值（当前单位）
;           gridsform - 表单句柄（用于回显消息）
; 说明    : axlShell 会使既有 dbid 失效；本函数不持有任何 dbid，安全。
;           后续维护者若在本函数之后引入 dbid，必须重新获取。
;------------------------------------------------------------------------
procedure( _cg_UC_grids_script_create(cur_grid gridsform)
    prog((ScriptFileName Script_File runScript)
        ScriptFileName = axlTempFile()
        Script_File = outfile(ScriptFileName "w")
        unless( Script_File
            axlUIConfirm(strcat("\316\336\267\250\264\264\275\250\301\331\312\261\275\305\261\276\316\304\274\376: " ScriptFileName))
            return(nil)
        )
        fprintf(Script_File "scriptmode +i\n")
        fprintf(Script_File "define grid \nsetwindow form.grid\n")
        fprintf(Script_File "FORM grid non_etch non_etch_x_grids %n \n" cur_grid)
        fprintf(Script_File "FORM grid non_etch non_etch_y_grids %n \n" cur_grid)
        fprintf(Script_File "FORM grid all_etch all_etch_x_grids %n %n %n %n %n \n"
            cur_grid/5 cur_grid/5 cur_grid/5 cur_grid/5 cur_grid/5)
        fprintf(Script_File "FORM grid all_etch all_etch_y_grids %n %n %n %n %n \n"
            cur_grid/5 cur_grid/5 cur_grid/5 cur_grid/5 cur_grid/5)
        fprintf(Script_File "FORM grid done\n")
        close(Script_File)

        sprintf(runScript "replay %s" ScriptFileName)
        axlShell(runScript)
        when( and(gridsform axlIsFormType(gridsform))
            axlUIWPrint(gridsform axlPPrint(car(axlDBGetDesignUnits())))
        )
        deleteFile(ScriptFileName)
        return(t)
    )
)

; 兼容旧命令别名（纯显示/环境操作，不挂 ?undo）
axlCmdRegister("FYCW" 'FanySkill_ChooseGrid)

;; ============================================================
;; Toolbox wrapper
;; ============================================================
procedure( ASTB_Util_ChooseGrid()
    FanySkill_ChooseGrid()
)

ASTB_RegisterCommand("ASTB_Util_ChooseGrid" "ASTB_Util_ChooseGrid" ?cmdType "interactive")

printf("[ASTB] util_choosegrid.il loaded.\n")
