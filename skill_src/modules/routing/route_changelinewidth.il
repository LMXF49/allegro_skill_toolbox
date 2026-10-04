;   2026-08-20 v1.4 ASTB Team 撤销命令注册补 ?undo nil（防系统撤销把
;                   撤销命令本身入栈，17.4+）
;========================================================================
; 文件名    : route_changelinewidth.il
; 作者      : Allegro SKILL Toolbox
; 创建日期  : 2026-07-16
; 版本      : 1.4
; 功能描述  : 修改走线线宽：按层（树视图多选）与线宽条件（</=/>）筛选
;             走线，支持高亮预览与批量改宽
; 依赖模块  : core/menu.il, core/utils.il, core/trans.il
; 修改记录  :
;   2026-07-16 v1.0 Allegro SKILL Toolbox 初始创建
;   2026-07-17 v1.1 Allegro SKILL Toolbox 整改：
;                   1) 下线旧版 cw 工具（与 wid 功能重叠、cw 重复注册两次、
;                      事务全注释却挂 ?undo t，源码归档 _backup_pre_fix）
;                   2) 删除裸 axlCmdRegister("wid")，统一 ASTB_RegisterCommand
;                   3) foreach+remove 破坏性过滤改为 setof 重建（防跳元素）
;                   4) 改宽动作接入 ASTB_DBTransactionMark，恢复 axlDBIgnoreFixed
;                   5) 临时 wid.form 改写 axlTempDirectory()；层树改用真实层名
;   2026-07-18 v1.2 Allegro SKILL Toolbox 界面汉化
;   2026-08-20 v1.3 ASTB Team 新增撤销（接入 astbundo）：改宽前记录
;                   (层 网络 旧宽 新宽 起点) 定位信息压栈；WID_Undo 现场
;                   查找并校验当前宽==新宽后改回旧宽
;========================================================================

;------------------------------------------------------------------------
; 有意全局：层树视图项列表与表单句柄（表单回调异步访问）
;------------------------------------------------------------------------
unless( boundp('lo_layerTree)
    lo_layerTree = nil
)
unless( boundp('g_widForm)
    g_widForm = nil
)

;------------------------------------------------------------------------
; 函数名  : wid_main
; 功能    : 生成临时表单并显示“线宽设置”界面
;------------------------------------------------------------------------
procedure( wid_main()
    prog( (s_formAddr)
        s_formAddr = wid_form()
        unless( s_formAddr
            axlUIConfirm("无法创建临时表单文件，请检查临时目录权限")
            return(nil)
        )
        g_widForm = axlFormCreate((gensym) s_formAddr nil 'wid_formAct nil nil)
        unless( g_widForm
            axlUIConfirm("创建线宽设置表单失败")
            deleteFile(s_formAddr)
            return(nil)
        )
        wid_formInit()
        axlFormDisplay(g_widForm)
        when( isFile(s_formAddr)
            deleteFile(s_formAddr)
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : wid_formAct
; 功能    : 表单回调：层全选/全不选、高亮预览、批量改宽
; 说明    : 改宽动作为数据库修改，经 ASTB_DBTransactionMark 包装
;------------------------------------------------------------------------
procedure( wid_formAct(o_form)
    g_widForm = o_form
    case( o_form->curField
        ("allOn"     wid_layerSel(t))
        ("allOff"    wid_layerSel(nil))
        ("hilight"   axlHighlightObject(wid_filterCline()))
        ("dehilight" axlDehighlightObject(wid_filterCline()))
        ("change"
            ASTB_DBTransactionMark('wid_changeCline list(axlFormGetField(o_form "noFix")))
        )
        (t t)
    )
    case( o_form->doneState
        (3                                  ; 表单关闭：去高亮并恢复全板显示
            axlDehighlightObject(wid_filterCline())
            axlVisibleDesign(t)
            axlVisibleUpdate(t)
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : wid_formInit
; 功能    : 按当前设计真实 ETCH 层名初始化层树视图与默认值
;------------------------------------------------------------------------
procedure( wid_formInit()
    let( (l_layers)
        lo_layerTree = list()
        l_layers = axlGetParam("paramLayerGroup:ETCH")->groupMembers
        foreach( lay l_layers
            lo_layerTree = cons(
                axlFormTreeViewAddItem(g_widForm "layer" lay nil nil t)
                lo_layerTree)
        )
        lo_layerTree = reverse(lo_layerTree)
        axlFormSetField(g_widForm "filter" "0")
        axlFormSetField(g_widForm "refWidth" 5.0)
        axlFormSetField(g_widForm "tgtWidth" 5.0)
    )
)

;------------------------------------------------------------------------
; 函数名  : wid_layerSel
; 功能    : 层树视图全选/全不选
; 参数    : g_sel - t 全选；nil 全不选
;------------------------------------------------------------------------
procedure( wid_layerSel(g_sel)
    foreach( i lo_layerTree
        axlFormTreeViewSetSelectState(g_widForm "layer" i g_sel)
    )
)

;------------------------------------------------------------------------
; 函数名  : wid_filterCline
; 功能    : 按勾选层与线宽条件筛选走线段
; 返回值  : 命中的 clineseg dbid 列表；无命中返回 nil
; 说明    : 利用“选择/改宽只作用于可见对象”的机制按层过滤；
;           setof 重建列表替代 foreach+remove；退出前恢复全板显示
;------------------------------------------------------------------------
procedure( wid_filterCline()
    prog( (s_layer lo_cline f_width)
        axlVisibleLayer("ETCH" nil)
        foreach( i lo_layerTree
            if( axlFormTreeViewGetSelectState(g_widForm "layer" i) == 1 then
                s_layer = axlFormTreeViewGetLabel(g_widForm "layer" i)
                axlVisibleLayer(strcat("ETCH/" s_layer) t)
            )
        )
        axlVisibleUpdate(t)

        axlSetFindFilter(?enabled list("noall" "clinesegs") ?onButtons list("noall" "clinesegs"))
        axlAddSelectAll()
        lo_cline = axlGetSelSet()
        axlClearSelSet()
        unless( lo_cline
            axlVisibleDesign(t)
            axlVisibleUpdate(t)
            return(nil)
        )

        f_width = axlFormGetField(g_widForm "refWidth")
        ; --- setof 重建过滤结果；等值比较带容差，避免浮点 == 漏匹配 ---
        case( axlFormGetField(g_widForm "filter")
            ("0" lo_cline = setof(i lo_cline (i->width < f_width)))
            ("1" lo_cline = setof(i lo_cline (abs(i->width - f_width) < 0.0001)))
            ("2" lo_cline = setof(i lo_cline (i->width > f_width)))
        )

        axlVisibleDesign(t)                 ; 恢复全板显示，不劫持用户显隐
        axlVisibleUpdate(t)
        return(lo_cline)
    )
)

;------------------------------------------------------------------------
; 函数名  : wid_changeCline
; 功能    : 对筛选结果批量修改线宽（经 ASTB_DBTransactionMark 调用）
; 参数    : g_noFix - t 时忽略 FIXED 属性强制修改
; 副作用  : 修改当前设计数据库
;------------------------------------------------------------------------
procedure( wid_changeCline(g_noFix)
    let( (lo_cline newW batch seg segs pt netE netName)
        axlDBIgnoreFixed(g_noFix)
        axlDBControl('dynamicFillMode nil)          ; 批量改宽期间暂停动态填充刷新
        lo_cline = wid_filterCline()
        if( lo_cline then
            newW = axlFormGetField(g_widForm "tgtWidth")
            ;; v1.3: 改宽前记录定位信息+旧线宽（不存 dbid，跨命令失效），
            ;; 供 ASTB_Route_ChangeLineWidthu / astbundo 撤销
            batch = nil
            foreach( seg lo_cline
                segs = errset(seg->segments nil)
                pt = if( and(segs car(segs))
                     then car(car(segs))->startEnd
                     else seg->startEnd )
                pt = car(pt)                        ; 起点做定位点
                netE = errset(seg->net->name nil)
                netName = and(netE car(netE))
                batch = cons(list(seg->layer netName seg->width newW pt) batch)
            )
            axlChangeWidth(lo_cline newW)
            _WID_undoStack = cons(reverse(batch) _WID_undoStack)
            ASTB_UndoJournalPush("route_changelinewidth")
            axlUIWPrint(nil "完成。输入 astbundo 可撤销本次修改")
        else
            axlUIWPrint(g_widForm "没有走线命中筛选条件。")
        )
        axlDBIgnoreFixed(nil)                       ; 恢复 FIXED 属性检查
        axlDBControl('dynamicFillMode 'wysiwyg)     ; 恢复动态填充模式
        axlShapeDynamicUpdate(nil nil)
    )
)

;------------------------------------------------------------------------
; 函数名  : wid_form
; 功能    : 在系统临时目录生成 wid.form 表单定义
; 返回值  : 表单文件完整路径；失败返回 nil
;------------------------------------------------------------------------
procedure( wid_form()
    prog( (s_addr file)
        s_addr = strcat(axlTempDirectory() "/wid.form")
        file = outfile(s_addr "w")
        unless( file
            return(nil)
        )
        fprintf(file "FILE_TYPE=FORM_DEFN VERSION=2\n")
        fprintf(file "FORM\n")
        fprintf(file "FIXED\n")
        fprintf(file "PORT 40 50\n")
        fprintf(file "HEADER \"\317\337\277\355\311\350\326\303\"\n")
        fprintf(file "\n")
        fprintf(file "POPUP <ENUM>\"<\"\"0\",\"=\"\"1\",\">\"\"2\".\n")
        fprintf(file "TILE\n")
        fprintf(file "\n")

        fprintf(file "FIELD layer\n")                 ; 层树视图（多选）
        fprintf(file "FLOC 1 1\n")
        fprintf(file "TREEVIEW 18 9\n")
        fprintf(file "ENDFIELD\n")

        fprintf(file "FIELD allOn\n")
        fprintf(file "FLOC 20 1\n")
        fprintf(file "MENUBUTTON \"\310\253\321\241\" 8 2\n")
        fprintf(file "ENDFIELD\n")

        fprintf(file "FIELD allOff\n")
        fprintf(file "FLOC 30 1\n")
        fprintf(file "MENUBUTTON \"\310\253\262\273\321\241\" 8 2\n")
        fprintf(file "ENDFIELD\n")

        fprintf(file "TEXT \"\317\337\277\355 \"\n")             ; 线宽筛选条件
        fprintf(file "TLOC 20 5\n")
        fprintf(file "ENDTEXT\n")

        fprintf(file "FIELD filter\n")
        fprintf(file "FLOC 25 5\n")
        fprintf(file "ENUMSET 3\n")
        fprintf(file "POP \"ENUM\"\n")
        fprintf(file "ENDFIELD\n")

        fprintf(file "FIELD refWidth\n")              ; 参考线宽
        fprintf(file "FLOC 31 5\n")
        fprintf(file "REALFILLIN 6 99\n")
        fprintf(file "ENDFIELD\n")

        fprintf(file "FIELD hilight\n")
        fprintf(file "FLOC 20 8\n")
        fprintf(file "MENUBUTTON \"\270\337\301\301\" 8 3\n")
        fprintf(file "ENDFIELD\n")

        fprintf(file "FIELD dehilight\n")
        fprintf(file "FLOC 30 8\n")
        fprintf(file "MENUBUTTON \"\310\245\270\337\301\301\" 8 3\n")
        fprintf(file "ENDFIELD\n")

        fprintf(file "TEXT \"\320\336\270\304\316\252 \"\n")         ; 目标线宽
        fprintf(file "TLOC 20 11\n")
        fprintf(file "ENDTEXT\n")

        fprintf(file "FIELD tgtWidth\n")
        fprintf(file "FLOC 29 11\n")
        fprintf(file "REALFILLIN 6 99\n")
        fprintf(file "ENDFIELD\n")

        fprintf(file "FIELD noFix\n")                 ; 忽略 FIXED 属性
        fprintf(file "FLOC 20 14\n")
        fprintf(file "CHECKLIST \"\272\366\302\324 Fix \312\364\320\324\"\n")
        fprintf(file "ENDFIELD\n")

        fprintf(file "FIELD change\n")
        fprintf(file "FLOC 20 16\n")
        fprintf(file "MENUBUTTON \"\320\336\270\304\" 8 3\n")
        fprintf(file "ENDFIELD\n")

        fprintf(file "\n")
        fprintf(file "ENDTILE\n")
        fprintf(file "ENDFORM\n")

        close(file)
        return(s_addr)
    )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_Route_ChangeLineWidth
; 功能    : 命令入口
;------------------------------------------------------------------------
procedure( ASTB_Route_ChangeLineWidth()
    wid_main()
)

;------------------------------------------------------------------------
; 函数名  : WID_Undo
; 功能    : 撤销最近一次批量改宽：弹栈顶批次，按 (层 定位点) 现场查找
;           走线段，校验当前线宽==本批新线宽（防覆盖事后手动改动），
;           改回旧线宽。定位信息不存 dbid（跨命令失效成 dbid:removed）
; 返回值  : t
;------------------------------------------------------------------------
unless( boundp('_WID_undoStack) defvar(_WID_undoStack nil) )

procedure( WID_Undo()
    prog( (batch item lay oldW newW pt netName found cand n m)
        unless( _WID_undoStack
            axlUIWPrint(nil "没有可撤销的记录")
            return(nil)
        )
        batch = car(_WID_undoStack)
        _WID_undoStack = cdr(_WID_undoStack)
        axlSetFindFilter(?enabled list("noall" "clinesegs") ?onButtons list("noall" "clinesegs"))
        n = 0
        m = 0
        foreach( item batch
            lay     = nth(0 item)
            netName = nth(1 item)
            oldW    = nth(2 item)
            newW    = nth(3 item)
            pt      = nth(4 item)
            found = nil
            axlClearSelSet()
            when( axlSingleSelectPoint(pt)
                foreach( cand axlGetSelSet()
                    when( and(equal(cand->layer lay)
                              abs(cand->width - newW) < 0.0001)
                        found = cand
                    )
                )
            )
            axlClearSelSet()
            if( found then
                errset(axlChangeWidth(list(found) oldW) t)
                n = n + 1
            else
                m = m + 1
                axlUIWPrint(nil sprintf(nil "  跳过: 层 %s 点 %L 未找到匹配走线(或线宽已被改)" lay pt))
            )
        )
        axlUIWPrint(nil sprintf(nil "撤销完成: 恢复 %d 条走线线宽, %d 条跳过" n m))
        return(t)
    )
)

ASTB_RegisterCommand("ASTB_Route_ChangeLineWidthu" "WID_Undo" ?cmdType "general" ?undo nil)
ASTB_RegisterUndo("route_changelinewidth" 'WID_Undo)

ASTB_RegisterCommand("ASTB_Route_ChangeLineWidth" "ASTB_Route_ChangeLineWidth"
    ?cmdType "interactive")

printf("[ASTB] route_changelinewidth.il loaded.\n")
