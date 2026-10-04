;   2026-08-20 v1.5 ASTB Team 撤销命令注册补 ?undo nil（防系统撤销把
;                   撤销命令本身入栈，17.4+）
;========================================================================
; 文件名    : place_movetogrid.il
; 作者      : JIAKE/15924（原始，jiake@huawei.com，2001-11-30）/ Toolbox（整合）
; 创建日期  : 2026-07-16
; 版本      : 1.6
; 功能描述  : 将元器件按用户设定的栅格移动吸附，支持全部器件/点选/框选/按管脚数筛选四种模式，
;             参考点可选器件原点（Origin）或 1 号管脚（Pin1）；FIXED 属性的元件自动跳过。
; 依赖模块  : core/trans.il（ASTB_RegisterCommand、ASTB_DBTransactionMark）
; 修改记录  :
;   2001-11-30 v0   JIAKE 初始创建（jkmove_comps_to_grid.il）
;   2026-07-16 v1.0 Toolbox 整合进 ASTB 工具箱
;   2026-07-17 v1.1 Toolbox 删除重建策略改为 axlTransformObject 原位移动（保留元件属性）；
;              动态表单改写到 axlTempDirectory()；done 按钮 label 由 "Down" 改为 "Done"；
;              修复 fini == t 误比较、FindFilter 小写 symbol；文件头原已损毁，按功能重写
;   2026-07-18 v1.2 ASTB 修复组 表单界面汉化：标题/分组/按钮/弹窗提示改中文
;   2026-08-20 v1.3 Toolbox 新增 Done 批次撤销：移动时按 refdes+旧坐标记录到
;              _jkMTG_pendingMoves，Done/Cancel 成批压入 _jkMTG_movedBatches；
;              新命令 ASTB_Place_MoveToGridu 逐批撤销（存定位信息不存 dbid）
;   2026-08-20 v1.4 Toolbox 接入统一撤销中枢 astbundo（core/trans.il
;              v1.4）：ASTB_RegisterUndo 注册 ASTB_Place_MoveToGrid_Undo，
;              批次入栈同步 ASTB_UndoJournalPush；Done 提示改指 astbundo
;              （ASTB_Place_MoveToGridu 保留为别名）
;   2026-09-09 v1.6 ASTB 修 17.4 跨交互轮 dbid 失效（S039：新一轮
;              axlSelect/axlEnter* 交互后旧 dbid 全部变 dbid:removed）：
;              点选 cmpgrp/框选 wintable 攒选当轮立刻改存 refdes 字符串，
;              高亮只对当轮新鲜对象调；Apply 前按 refdes 现场
;              axlSelectByName 重解析新鲜 symbol dbid（新增 _jkRefdesToSyms），
;              _jkoops/_jkwinoops/_jkDone 的 dehighlight 同样先重解析
;========================================================================

;************************************************************************************
; Move components to the setting grid（原始来源：02-布局与对齐/jkmove_comps_to_grid.il）
;
; 使用说明：
;   1. 执行菜单命令 ASTB_Place_MoveToGrid 打开 "Moving components to grid" 表单；
;   2. 选择参考点（Origin / Pin1）与吸附栅格（Grid of Placement）；
;   3. 选择移动模式：All（全部）/ By select（点选）/ By window（框选）/ By pin count（按管脚数）；
;   4. 点选/框选模式下点击 Apply 后在版图窗口选择元件，右键 Complete 结束选择；
;   5. 元件参考点被吸附到最近栅格，整体平移，attached text（refdes）随元件一起移动。
;   6. 点 Done 关闭表单后，输入 ASTB_Place_MoveToGridu 可撤销最近一次 Done 的
;      那一批移动；多次 Done 形成多批，逐批撤销。
;************************************************************************************

; --- 跨回调共享的表单会话状态（boundp 保护，避免重复加载时覆盖） ---
foreach( _v '(Moveform form _jkFormPtr ref_point move_grid by_All by_Select
               by_Window by_PinCount pin_min pin_max cmpgrp grsel winsel
               wintable gelem num fini popupA popupB
               _jkMTG_pendingMoves _jkMTG_movedBatches)
    unless( boundp(_v) set(_v nil))
)

;____________________Display form ______________________________________



(defun DisMoveForm ()

    

    _jkInitVar()



        ; 动态表单写系统临时目录，避免 CWD 依赖与多实例冲突
        setq( Moveform strcat(axlTempDirectory() "/move_component.form"))

        BuildForm()

        

        setq( form (axlFormCreate (gensym) Moveform `("E" "OUTER") `repCallback_movecomps t))

        _jkFormPtr = form

        axlFormSetField( form "ref_point" ref_point)

        axlFormSetField( form "move_grid" move_grid)

        axlFormSetField( form "all" by_All)

        axlFormSetField( form "bySelect" by_Select)

        axlFormSetField( form "byPinCount" by_PinCount)

        

        axlFormDisplay( form)

); defun myForm




;==================================================================
;            Move Components Function
;            原位移动实现：参考点吸附到最近栅格，整体平移 symbol，
;            attached text（refdes）及全部用户属性随元件保留。
;==================================================================

defun( _jkMoveComponent (symbol)

prog( (CXY CX CY pins CXYoff CXoff CYoff Xoff Yoff comps)

    foreach(sym symbol

        ; 只处理 symbol：排除无 refdes 对象；FIXED 元件跳过（属性链逐级判空）
        if( sym->objType == "symbol" && sym->refdes != nil
            && (sym->component == nil || sym->component->prop == nil
                || sym->component->prop->FIXED != t) then

            axlMsgPut("正在移动 %s" sym->refdes)

        ;___________get component imformation______________________________________

        CXY     = sym->xy

        CX = nthelem(1 CXY)

        CY = nthelem(2 CXY)

    ;___________convert the parameter________________________________________

          CXYoff = nil

          case(ref_point

              ("Origin"

                  CXYoff = sym->xy

                  t

            )

                  ("Pin1"

                      pins = sym->pins

                      foreach(pin1 pins if(upperCase(pin1->number) == "1" CXYoff = pin1->xy))

                      t

                  )

              )

              if(CXYoff == nil then    CXYoff = CXY)

        CXoff = nthelem(1 CXYoff)

        CYoff = nthelem(2 CXYoff)

        Xoff  = CXoff - round(CXoff/move_grid)*move_grid

        Yoff  = CYoff - round(CYoff/move_grid)*move_grid

    ;___________change component position___________________________________
    ; 原位移动：新坐标 = 原坐标 - 偏移量。
    ; 不再使用 axlDeleteObject + axlDBCreateSymbol 删除重建，
    ; 避免丢失元件用户属性；refdes 等 attached text 随 symbol 一起平移。

        when( Xoff != 0 || Yoff != 0

            ; 撤销记录：定位信息 (refdes 旧X 旧Y)，不存 dbid（跨命令失效）
            ; CX/CY 即 sym->xy 旧值，撤销时按 refdes 找回新鲜 dbid 再移回
            _jkMTG_pendingMoves = cons(list(sym->refdes CX CY) _jkMTG_pendingMoves)

            axlTransformObject(sym ?move (-Xoff):(-Yoff))

        )

        );if(sym->

    );foreach

    comps = axlDBGetDesign()->components

    foreach(comp comps  axlDBRefreshId(comp))

))



;==================================================================
;            Move Components Function（框架 errset 包装）
;==================================================================

defun( _jkMoveComponent_Wrapper (symbol)
  ;; 使用 Toolbox 框架包装数据库修改操作，出错时 errset 拦截，
  ;; 避免单个元件移动失败中断整个表单会话
  ASTB_DBTransactionMark('_jkMoveComponent list(symbol))
)

;-------------------select components by group-----------------------



(defun _jkSelectGrp ()

(prog ()

if( cmpgrp == nil then

    grsel = nil

    i = 0 

    _jkPopUpB()

          axlSetFindFilter( ?enabled '("noall" "components" ) ?onButtons '("noall" "components" ))

          axlOpenFindFilter()

    while( (grsel == nil)

               if( axlSingleSelectPoint( ) == t then

                       gelem = axlGetSelSet()

                       axlMsgPut( "已选中元件 %L 。" car(gelem)->name)

                       i=0

            ; v1.6: 17.4 跨轮 dbid 必失效——元件判断/攒选/高亮全部挪进

            ; 当轮（gelem 新鲜）：cmpgrp 改存 refdes 字符串不存 dbid，

            ; 高亮只对当轮新鲜对象调（跨轮累积高亮靠旧高亮保持）

            if( (car gelem)->objType == "component" then

                cmpgrp=cons( (car gelem)->name cmpgrp)

                axlHighlightObject( gelem)

                i=0

            else

                axlMsgPut( "该元件不是 PACKAGE 类型")

                axlDehighlightObject( gelem)

                i++ if(i > 20 return nil)

            );end-if

               else

                   if( grsel == nil then axlMsgPut( "未找到元件，请重新选择。"))

            i++ if(i > 20 return nil)

               );end-if

        axlClearSelSet()

    );end-while

    return( cmpgrp)

);end-if

axlCancelEnterFun()

);end-prog

);end-defun





(defun _jkSelectWindow ()

(prog ()

if( wintable[1] == nil then

    _jkPopUpA()

    winsel = nil

    num = 1    

    while( winsel == nil 

        wingrp = nil

        winfresh = nil

        axlSetFindFilter(?enabled '("noall" "components") ?onButtons '("noall" "components"))

        axlOpenFindFilter()

        axlSingleSelectBox()

        allcom = axlGetSelSet()

;        if( allcom == nil then axlMsgPut( "No Elements Found. Try again!"))

        foreach( com allcom

;i=0 ++i  com = nthelem(i allcom)

            if( com->objType == "component" then

                ; v1.6: 当轮立刻改存 refdes 字符串（dbid 跨轮必失效）；

                ; winfresh 收集当轮新鲜 dbid 仅供本轮高亮使用

                wingrp = cons(com->name wingrp)

                winfresh = cons(com winfresh)

;                axlMsgPut( "Component %L Window Selected . " com->name)

            );end-if

    

        );end-foreach

        if(wingrp != nil then

            wintable[num]=wingrp

            num++

        )

        axlClearSelSet()

        axlHighlightObject( winfresh)

    );end-while    

    return( wintable)

);end-if    

axlCancelEnterFun()

);end-prog

);end-defun





;______________" Process User entries in popup menu"_________________________



(defun repCallback_movecomps (form)

    case( form->curField

        ("done"

            axlFormClose( form)

            axlCancelEnterFun()



            deleteFile( Moveform)

            if( _jkMTG_CommitBatch() then

                axlMsgPut("完成。输入 astbundo 可撤销本次修改")

            else

                axlMsgPut("完成")

            )

            t)

        ("apply"           

        if(by_All == t then        

        symbol = _jkSym_in_Com(axlDBGetDesign()->components)        

        _jkMoveComponent_Wrapper(symbol)

        )        

        if(by_Select == t then

            if(grsel == t then

                cmpgrp = nil

            symbol = _jkRefdesToSyms(_jkSelectGrp())

            _jkMoveComponent_Wrapper(symbol)

        else

            axlMsgPut("jE- 请先结束当前命令。")

        )

        )

        if(by_Window == t then

            if(winsel == t then

                wintable = makeTable("atable1" nil)

            symbol = _jkRefdesToSyms(_jktab_to_list(_jkSelectWindow()))

            _jkMoveComponent_Wrapper(symbol)

        else

            axlMsgPut("jE- 请先结束当前命令。")

        )

        )

        if(by_PinCount == t then

            allsym = _jkSym_in_Com(axlDBGetDesign()->components)

            symbol = nil

            foreach(asym allsym

                if( length(asym->pins) >= pin_min && length(asym->pins) <= pin_max then

                    symbol = cons( asym symbol)                    

                )

            )

            _jkMoveComponent_Wrapper(symbol)

        )                

            t)

        ("cancel"

            axlFormClose( form)

            axlCancelEnterFun()

            deleteFile( Moveform)

            _jkMTG_CommitBatch()

            nil)

            

        ("ref_point"    

            axlMsgPut("请选择参考点。")

            ref_point = form->curValue

            t)

        ("move_grid"    

            axlMsgPut("请输入摆放栅格。")

            move_grid = form->curValue

            t)

        ("pinmin"    

            axlMsgPut("请输入最小引脚数。")

            pin_min = form->curValue

            t)

        ("pinmax"    

            axlMsgPut("请输入最大引脚数。")

            pin_max = form->curValue

            t)             

        ("all"    

            axlMsgPut("移动全部元件。")

            by_All = form->curValue

            t)

     ("bySelect"

            axlMsgPut("点选移动元件。")

            by_Select = form->curValue            

            t)

     ("byWindow"

            axlMsgPut("框选移动元件。")

            by_Window = form->curValue            

            t)

     ("byPinCount"

            axlMsgPut("按引脚数移动元件。")

            by_PinCount = form->curValue

            axlFormSetField( form "pinmin" pin_min)

            axlFormSetField( form "pinmax" pin_max)

            t)

    ); case

    

); defun jk_repCallback_movecomps





;____________ build up the form dynamically_______________________



(defun BuildForm ()



    (deleteFile Moveform)

    (setq FORMFILE (outfile Moveform))

    (unless FORMFILE (axlUIConfirm "无法创建临时表单文件，请检查临时目录权限") (error "BuildForm: cannot open temp form file"))

    (fprintf FORMFILE "FILE_TYPE=FORM_DEFN VERSION=2\n")



    (fprintf FORMFILE "FORM\n")

    (fprintf FORMFILE "FIXED\n")

    (fprintf FORMFILE "PORT 35 10\n")

    (fprintf FORMFILE "HEADER \"\322\306\266\257\324\252\274\376\265\275\325\244\270\361\"\n")

    (fprintf FORMFILE "\n")    

    fprintf(FORMFILE "POPUP <Layer_Names>")

       fprintf(FORMFILE "\"Origin\" \"Origin\",\"Pin1\" \"Pin1\".\n")

       

    fprintf(FORMFILE "POPUP <Packages>")

       fprintf(FORMFILE "\"P1\" \"P1\",\"P2\" \"P2\".\n")

       



    (fprintf FORMFILE "TILE\n")

    

       fprintf(FORMFILE "TEXT \"\262\316\277\274\265\343:\"\n")

    fprintf(FORMFILE "TLOC 4 1\n")

       fprintf(FORMFILE "ENDTEXT\n")

       fprintf(FORMFILE "FIELD ref_point\n")

       fprintf(FORMFILE "FLOC 18 1\n")

       fprintf(FORMFILE "ENUMSET 11\n")

       fprintf(FORMFILE "POP \"Layer_Names\"\n")

       fprintf(FORMFILE "ENDFIELD\n")



        fprintf(FORMFILE "TEXT \"\260\332\267\305\325\244\270\361:\"\n")

        fprintf(FORMFILE "TLOC 4 4\n")

        fprintf(FORMFILE "ENDTEXT\n")

        fprintf(FORMFILE "FIELD move_grid\n")

        fprintf(FORMFILE "FLOC 22 4\n")

        fprintf(FORMFILE "REALFILLIN 8 8\n")

        fprintf(FORMFILE "REALMIN 1.0\n")

       fprintf(FORMFILE "REALMAX 1000.0\n")

        fprintf(FORMFILE "ENDFIELD\n")

   

        fprintf(FORMFILE "FIELD all\n")

        fprintf(FORMFILE "FLOC 4 10\n")

        fprintf(FORMFILE "FGROUP \"MoveCom\"\n")

        fprintf(FORMFILE "CHECKLIST \"\310\253\262\277(\271\314\266\250\324\252\274\376\263\375\315\342)\" \"MoveCom\"\n")

        fprintf(FORMFILE "ENDFIELD\n")

   

        fprintf(FORMFILE "FIELD byPinCount\n")

        fprintf(FORMFILE "FLOC 4 12\n")

        fprintf(FORMFILE "FGROUP \"MoveCom\"\n")

        fprintf(FORMFILE "CHECKLIST \"\260\264\322\375\275\305\312\375\264\323\" \"MoveCom\"\n")

        fprintf(FORMFILE "ENDFIELD\n")

        

        fprintf(FORMFILE "TEXT \"\265\275\"\n")

        fprintf(FORMFILE "TLOC 25 12\n")

        fprintf(FORMFILE "ENDTEXT\n")

        

        fprintf(FORMFILE "FIELD pinmin\n")

        fprintf(FORMFILE "FLOC 20 12\n")

        fprintf(FORMFILE "INTFILLIN 3 3\n")

        fprintf(FORMFILE "ENDFIELD\n")

        fprintf(FORMFILE "FIELD pinmax\n")

        fprintf(FORMFILE "FLOC 27 12\n")

        fprintf(FORMFILE "INTFILLIN 4 4\n")

        fprintf(FORMFILE "ENDFIELD\n")

        

        fprintf(FORMFILE "FIELD bySelect\n")

        fprintf(FORMFILE "FLOC 4 14\n")

        fprintf(FORMFILE "FGROUP \"MoveCom\"\n")

        fprintf(FORMFILE "CHECKLIST \"\265\343\321\241\" \"MoveCom\"\n")

        fprintf(FORMFILE "ENDFIELD\n")

       

        fprintf(FORMFILE "FIELD byWindow\n")

        fprintf(FORMFILE "FLOC 4 16\n")

        fprintf(FORMFILE "FGROUP \"MoveCom\"\n")

        fprintf(FORMFILE "CHECKLIST \"\277\362\321\241\" \"MoveCom\"\n")

        fprintf(FORMFILE "ENDFIELD\n")

/*

        fprintf(FORMFILE "FIELD byPackage\n")

        fprintf(FORMFILE "FLOC 4 16\n")

        fprintf(FORMFILE "FGROUP \"MoveCom\"\n")

        fprintf(FORMFILE "CHECKLIST \"By package\" \"MoveCom\"\n")

        fprintf(FORMFILE "ENDFIELD\n")

                

       fprintf(FORMFILE "FIELD package\n")

       fprintf(FORMFILE "FLOC 20 16\n")

       fprintf(FORMFILE "ENUMSET 11\n")

       fprintf(FORMFILE "POP \"Packages\"\n")

       fprintf(FORMFILE "ENDFIELD\n")

       

        fprintf(FORMFILE "FIELD byList\n")

        fprintf(FORMFILE "FLOC 4 18\n")

        fprintf(FORMFILE "FGROUP \"MoveCom\"\n")

        fprintf(FORMFILE "CHECKLIST \"By list\" \"MoveCom\"\n")

        fprintf(FORMFILE "ENDFIELD\n")

        

    (fprintf FORMFILE "FIELD by_list\n")

    (fprintf FORMFILE "FLOC 6 20\n")

    (fprintf FORMFILE "LIST \"\" 24 6\n")

    (fprintf FORMFILE "ENDFIELD\n")

    (fprintf FORMFILE "\n")

*/

    fprintf(FORMFILE "GROUP \"\322\306\266\257\324\252\274\376\"\nGLOC 2 7\nGSIZE 32 12\nENDGROUP\n\n")

        

    (fprintf FORMFILE "FIELD done\n")

    (fprintf FORMFILE "FLOC 6 21\n")

    (fprintf FORMFILE "MENUBUTTON \"\315\352\263\311\" 9 3\n")

    (fprintf FORMFILE "ENDFIELD\n")

    (fprintf FORMFILE "\n")

    

    (fprintf FORMFILE "FIELD apply\n")

    (fprintf FORMFILE "FLOC 20 21\n")

    (fprintf FORMFILE "MENUBUTTON \"\323\246\323\303\" 9 3\n")

    (fprintf FORMFILE "ENDFIELD\n")

    (fprintf FORMFILE "\n")



    (fprintf FORMFILE "ENDTILE\n")

    (fprintf FORMFILE "\n")

    (fprintf FORMFILE "ENDFORM\n")

    (close FORMFILE)

) ; end _jkBuildForm



;--------------- Pop up for window selection --------------------------------

defun( _jkPopUpA ()

    popupA = axlUIPopupDefine( nil

        (list (list "完成" '_jkcomplete)

            (list "撤销" '_jkwinoops)

            (list "取消" '_jkCancel)))

    axlUIPopupSet( popupA )

);end-defun





;--------------- Pop up for group selection --------------------------------

defun( _jkPopUpB ()

    popupB = axlUIPopupDefine( nil

        (list (list "完成" '_jkcomplete)

            (list "撤销" '_jkoops)

            (list "取消" '_jkCancel)))

    axlUIPopupSet( popupB )

);end-defun



;--------------- Cancel Call--------------------------------

defun( _jkCancel ()

(prog ()

    _jkDone()

    axlMsgPut("取消")

);end-prog

);endfun



;----------------- DONE Call--------------------------------

defun( _jkDone ()

(prog (_jkrd _jkrdid)

    setq( grsel t)

    fini = t

    ; v1.6: cmpgrp 存 refdes 字符串，dehighlight 前逐条现场重解析

    ; 新鲜 dbid（旧 dbid 跨轮已失效为 dbid:removed）

    if( cmpgrp != nil then

        foreach( _jkrd cmpgrp

            axlClearSelSet()

            _jkrdid = car(axlSelectByName("REFDES" _jkrd))

            if( _jkrdid != nil then axlDehighlightObject( _jkrdid))

        )

        axlClearSelSet()

    )

    setq( cmpgrp nil)

    axlCancelEnterFun()

    axlClearSelSet()

    axlCloseFindFilter()

    axlUIPopupSet( nil)

)

);end-fun



;--------------- Complete Picks ----------------------------

defun( _jkcomplete ()

(prog ()

    grsel = t

    winsel = t

    axlCancelEnterFun()

    axlUIPopupSet( nil)

)

);end-defun



;--------------- Oops command-------------------------------

defun( _jkoops ()

(prog (_jkop)

    if( cmpgrp != nil then

        ; v1.6: cmpgrp 存 refdes 字符串，先现场重解析新鲜 dbid 再

        ; dehighlight（旧 dbid 跨轮已失效为 dbid:removed）

        axlClearSelSet()

        _jkop = car(axlSelectByName("REFDES" car(cmpgrp)))

        if( _jkop != nil then axlDehighlightObject( _jkop))

        axlClearSelSet()

        cmpgrp = cdr(cmpgrp)

        gelem = nil

    

        axlMsgPut("撤销")    

    );end-if

    axlCancelEnterFun()

    return( cmpgrp)

);endprog

);end-defun        



defun( _jkwinoops ()

(prog (_jkwr _jkwid)

    num--

    if( wintable[num] != nil then

        ; v1.6: wintable 存 refdes 字符串列表，dehighlight 前逐条现场

        ; 重解析新鲜 dbid（旧 dbid 跨轮已失效为 dbid:removed）

        foreach( _jkwr wintable[num]

            axlClearSelSet()

            _jkwid = car(axlSelectByName("REFDES" _jkwr))

            if( _jkwid != nil then axlDehighlightObject( _jkwid))

        )

        axlClearSelSet()

        axlMsgPut("撤销")    

        if(num < 1 then

             num = 1 

             wintable = makeTable("atable1" nil)

        else 

             wintable[num] = nil

        )

        

        

    );end-if

    axlCancelEnterFun()

    return( cmpgrp)

);endprog

);end-defun        

;--------------- Initialize value -------------------------------

defun( _jkInitVar ()

(prog ()

    gelem = nil

    grsel = t    

    winsel = t

    by_All = t

    by_Select = nil

    by_Window = nil

    by_PinCount = nil

    ref_point = "Origin"

    move_grid = 50.0

    pin_min = 1

    pin_max = 1000

    _jkFormPtr = nil

    axlUIPopupSet( nil)

    cmpgrp = nil

    fini = nil

    num = 0

    wintable = makeTable("atable1" nil) 

);end-prog

);end-defun



defun( _jkSym_in_Com (comp)

(prog ()

(let (tsym)

    tsym = nil

    foreach(com comp

        if(com->symbol != nil then

            tsym = cons( com->symbol tsym)    

        )

    )

    return(tsym)

);end-let

);end-prog

);end-defun



;--------------- v1.6: refdes 列表重解析新鲜 symbol dbid 列表 ---------------

; 17.4 S039：攒选阶段只存 refdes 字符串（dbid 跨交互轮必失效），使用前

; 逐条现场 axlSelectByName 重解析新鲜 dbid、当轮即用即弃

; （place_gathercomps.il v1.7 实证模式）；找不到的 refdes 警告并跳过。

defun( _jkRefdesToSyms (refdeses)

(prog (_jksyms _jkrd _jksid)

    _jksyms = nil

    axlSetFindFilter( ?enabled '("noall" "symbols") ?onButtons '("noall" "symbols"))

    foreach( _jkrd refdeses

        axlClearSelSet()

        _jksid = car(axlSelectByName("REFDES" _jkrd))

        if( _jksid != nil then

            _jksyms = cons( _jksid _jksyms)

        else

            axlUIWPrint(nil "  警告: 找不到元件 %s，跳过" _jkrd)

        )

    )

    axlClearSelSet()

    return( _jksyms)

);end-prog

);end-defun


defun( _jktab_to_list (table)

(prog ()

(let (tablist )

    tablist = nil    

    foreach(key table

         if(table[key] != nil then

            lst = table[key]        

            foreach(com lst

                tablist = cons(com tablist)

            )

        )

    )

    return(tablist)

);end-let

);end-prog

);end-defun






;==================================================================
;   Done 批次撤销支持（v1.3）
;   本机系统撤销（Ctrl+Z / axlShell("undo")）不覆盖 AXL 移动的对象，
;   故模块自维护批次栈（参照 rvia.il 实证模式）：
;     _jkMTG_pendingMoves  —— 本次表单会话内各次 Apply 累积的移动记录
;     _jkMTG_movedBatches  —— 每次 Done/Cancel 将 pending 成批压栈
;   记录内容为定位信息 (refdes 旧X 旧Y)，绝不存 dbid（跨命令失效，
;   变 dbid:removed）；撤销时按 refdes 现场遍历 design->symbols 拿
;   新鲜 dbid，再按 旧坐标-当前坐标 差值 axlTransformObject 移回。
;==================================================================

defun( _jkMTG_CommitBatch ()
    ; 将本次会话累积的移动记录作为一批压入撤销栈。
    ; pending 由 cons 累积（最新移动在最前），撤销时按此顺序逐条移回，
    ; 同一元件被多次移动时可正确回到最早位置——切勿 reverse。
    ; 返回 t=压入一批；nil=无可提交记录
    if( _jkMTG_pendingMoves != nil then
        _jkMTG_movedBatches = cons(_jkMTG_pendingMoves _jkMTG_movedBatches)
        ASTB_UndoJournalPush("place_movetogrid")
        _jkMTG_pendingMoves = nil
        t
    else
        nil
    )
)

defun( ASTB_Place_MoveToGrid_Undo ()
prog( (batch rec rdx oldX oldY sym found dx dy rr n m comps comp)
    if( _jkMTG_movedBatches == nil then
        axlUIWPrint(nil "没有可撤销的记录")
        axlMsgPut("没有可撤销的记录")
        return(nil)
    )
    batch = car(_jkMTG_movedBatches)
    _jkMTG_movedBatches = cdr(_jkMTG_movedBatches)
    n = 0
    m = 0
    foreach( rec batch
        rdx  = car(rec)
        oldX = cadr(rec)
        oldY = caddr(rec)
        ; 按 refdes 现场查找 symbol（新鲜 dbid，不用存储 dbid）
        found = nil
        foreach( sym axlDBGetDesign()->symbols
            when( found == nil && sym->refdes != nil && equal(sym->refdes rdx)
                found = sym
            )
        )
        if( found != nil then
            dx = oldX - car(found->xy)
            dy = oldY - cadr(found->xy)
            if( dx != 0 || dy != 0 then
                rr = errset( axlTransformObject(found ?move dx:dy) t )
                if( and(rr car(rr)) then
                    n = n + 1
                else
                    m = m + 1
                    axlUIWPrint(nil "  警告: 元件 %s 移回失败" rdx)
                )
            else
                n = n + 1
            )
        else
            m = m + 1
            axlUIWPrint(nil "  警告: 找不到元件 %s，跳过" rdx)
        )
    )
    comps = axlDBGetDesign()->components
    foreach( comp comps axlDBRefreshId(comp))
    axlFlushDisplay()
    axlUIWPrint(nil "撤销完成: 恢复 %d 个元件, %d 个失败/未找到" n m)
    axlMsgPut("撤销完成")
    return(t)
))



;; ============================================================
;; Toolbox wrapper
;; ============================================================

procedure( ASTB_Place_MoveToGrid()
  DisMoveForm()
)

ASTB_RegisterCommand("ASTB_Place_MoveToGrid" "ASTB_Place_MoveToGrid" ?cmdType "interactive")

ASTB_RegisterCommand("ASTB_Place_MoveToGridu" "ASTB_Place_MoveToGrid_Undo" ?cmdType "general" ?undo nil)
; 统一撤销中枢注册（core/trans.il v1.4）：astbundo 按 LIFO 分发到本函数
ASTB_RegisterUndo("place_movetogrid" 'ASTB_Place_MoveToGrid_Undo)

printf("[ASTB] place_movetogrid.il loaded.\n")
