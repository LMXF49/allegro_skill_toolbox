;========================================================================
; 文件名    : shape_changenet.il
; 作者      : FanySkill / ASTB 整改组
; 创建日期  : 2026-07-16
; 版本      : 1.3
; 功能描述  : 交互式修改 Shape 网络：先选择一个或多个 Shape，再选择目标网络对象
; 依赖模块  : core
; 修改记录  :
;   2026-07-16 v1.0 FanySkill 初始创建
;   2026-07-17 v1.1 ASTB 整改：重写损坏文件头；删除裸 axlCmdRegister 重复注册；
;                    修复目标网络取值（net dbid 直接取 ->name）；支持多选 Shape；
;                    局部变量补 let 绑定；删除调试 println 与死代码；补事务保护
;   2026-08-20 v1.2 新增模块自维护撤销：批次栈 _SCN_undoStack 记录每个 Shape 的
;                    定位信息（层名+边界/bbox 定位点）与改前/改后网络名（不存
;                    dbid，跨命令失效），Done 后输入 ASTB_Shape_ChangeNetu 逐批
;                    撤销（改回原网络）
;   2026-08-20 v1.3 ASTB Team 接入统一撤销中枢 astbundo（core/trans.il
;                    v1.4）：ASTB_RegisterUndo 注册 Shape_ChangeNet_Undo，
;                    批次入栈同步 ASTB_UndoJournalPush；Done 提示改指
;                    astbundo（ASTB_Shape_ChangeNetu 保留为别名）
;========================================================================

;------------------------------------------------------------------------
; 全局变量: _SCN_undoStack 撤销批次栈（模块自维护，pitfalls 2.6：本机
;           系统撤销不覆盖 AXL 改属性；批次只存定位信息+旧值，不存 dbid）
;------------------------------------------------------------------------
unless( boundp('_SCN_undoStack) _SCN_undoStack = nil )

;------------------------------------------------------------------------
; 函数名  : Shape_ChangeNet_GetPts
; 功能    : 采集 Shape 的定位点列表（供撤销时现场查找）：边界首段起点
;           + bbox 中心 + 四个四分点。动态 Shape 改网后边界可能重算，
;           多点冗余提高命中率。不存 dbid（跨命令失效成 dbid:removed）。
; 参数    : shp - Shape dbid
; 返回值  : 点列表（可能为空表）
;------------------------------------------------------------------------
procedure( Shape_ChangeNet_GetPts(shp)
    prog((rr bb x1 y1 x2 y2 cx cy dx dy pts)
        pts = nil
        ; 边界首段起点（必在 Shape 上）；动态 Shape 无 ->segments 时静默跳过
        rr = errset(car(car(shp->segments)->startEnd) nil)
        when( and(rr car(rr))
            pts = cons(car(rr) pts)
        )
        ; bbox 中心 + 四个四分点
        rr = errset(shp->bBox nil)
        when( and(rr car(rr))
            bb = car(rr)
            x1 = caar(bb)   y1 = cadar(bb)
            x2 = caadr(bb)  y2 = cadadr(bb)
            cx = (x1+x2)/2.0  cy = (y1+y2)/2.0
            dx = (x2-x1)/4.0  dy = (y2-y1)/4.0
            pts = cons(list(cx cy) pts)
            pts = cons(list(cx-dx cy-dy) pts)
            pts = cons(list(cx+dx cy-dy) pts)
            pts = cons(list(cx-dx cy+dy) pts)
            pts = cons(list(cx+dx cy+dy) pts)
        )
        return(reverse(pts))
    )
)

;------------------------------------------------------------------------
; 函数名  : Shape_ChangeNet
; 功能    : 交互选择 Shape 并改挂到用户指定的网络
; 参数    : 无
; 返回值  : 无
; 副作用  : 修改当前设计数据库（由 ASTB 入口经 ASTB_DBTransactionMark 保护）；
;           每个成功改网的 Shape 记录 (层名 旧网络 新网络 定位点表) 入批次，
;           命令结束时整批压入 _SCN_undoStack（ASTB_Shape_ChangeNetu 可撤销）
;------------------------------------------------------------------------
procedure( Shape_ChangeNet()
    let((shapes all netName mypopup batch shp oldNet lay pts rr)
        mypopup = axlUIPopupDefine(nil (list
            (list "Done" 'axlFinishEnterFun)
            (list "Undo" 'ASTB_SystemUndo)
            (list "Cancel" 'axlCancelEnterFun)
        ))
        axlUIPopupSet(mypopup)
        axlClearSelSet()
        axlSetFindFilter(?enabled '("noall" "shapes") ?onButtons '("shapes"))
        while( axlSelect(?prompt "请选择要改网络的 Shape，Done 结束")
            shapes = axlGetSelSet()
            when( shapes
                ; --- 选择目标网络对象 ---
                axlSetFindFilter(?enabled '("noall" "nets") ?onButtons '("nets"))
                if( axlSelect(?prompt "请选择目标网络（cline/shape/pin/via）")
                then
                    all = axlGetSelSet()
                    netName = nil
                    when( car(all) && car(all)->objType == "net"
                        netName = car(all)->name
                    )
                    if( netName
                    then
                        foreach( shp shapes
                            ; 改前取旧网络名与定位信息（不存 dbid，跨命令失效）
                            oldNet = errset(shp->net->name nil)
                            oldNet = and(oldNet car(oldNet))
                            lay = shp->layer
                            pts = Shape_ChangeNet_GetPts(shp)
                            rr = errset(axlChangeNet(shp netName) t)
                            ; errset 成功返回单元素列表；无错才记录入批次
                            when( rr
                                batch = cons(list(lay oldNet netName pts) batch)
                            )
                        )
                        axlVisibleUpdate(t)
                    else
                        axlUIConfirm("未获取到有效网络，请重新选择")
                    )
                )
                axlClearSelSet()
                axlSetFindFilter(?enabled '("noall" "shapes") ?onButtons '("shapes"))
            )
        )
        ; Done/Cancel 结束：本次运行全部改网记录作为一批入撤销栈
        when( batch
            _SCN_undoStack = cons(reverse(batch) _SCN_undoStack)
            ASTB_UndoJournalPush("shape_changenet")
            axlUIWPrint(nil "完成。输入 astbundo 可撤销本次修改")
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_Shape_ChangeNet
; 功能    : ASTB 框架入口，带错误捕获保护
;------------------------------------------------------------------------
procedure( ASTB_Shape_ChangeNet()
    ASTB_DBTransactionMark('Shape_ChangeNet nil)
)

;------------------------------------------------------------------------
; 函数名  : Shape_ChangeNet_Undo
; 功能    : 撤销最近一次 Done 的那批改网（ASTB_Shape_ChangeNetu 命令）：
;           按批次记录的层名+定位点现场查找 Shape（选择集返回新鲜 dbid，
;           不依赖存储 dbid——跨命令失效成 dbid:removed），校验当前网络
;           仍是本批改成的新网络后，axlChangeNet 改回旧网络。
; 返回值  : t - 执行了撤销；nil - 没有可撤销的记录
;------------------------------------------------------------------------
procedure( Shape_ChangeNet_Undo()
    prog((batch item lay oldNet newNet pts found shp rr cur n m)
        unless( _SCN_undoStack
            axlUIWPrint(nil "没有可撤销的记录")
            return(nil)
        )
        batch = car(_SCN_undoStack)
        _SCN_undoStack = cdr(_SCN_undoStack)
        axlSetFindFilter(?enabled '("noall" "shapes") ?onButtons '("shapes"))
        n = 0
        m = 0
        foreach( item batch
            lay    = car(item)
            oldNet = cadr(item)
            newNet = caddr(item)
            pts    = cadddr(item)
            ; 按定位点+层名现场查找 Shape（新鲜 dbid），逐点尝试直至命中
            found = nil
            foreach( pt pts
                unless( found
                    axlClearSelSet()
                    when( axlSingleSelectPoint(pt)
                        foreach( shp axlGetSelSet()
                            when( and(null(found) equal(shp->layer lay))
                                found = shp
                            )
                        )
                    )
                )
            )
            if( found then
                ; 校验：当前网络应仍是本批改成的新网络，否则视为已被后续改动
                rr = errset(found->net->name nil)
                cur = and(rr car(rr))
                if( equal(cur newNet) then
                    rr = errset(axlChangeNet(found oldNet) t)
                    if( rr then
                        n = n + 1
                    else
                        m = m + 1
                        axlUIWPrint(nil "  警告: %s 层定位点 %L 处 Shape 恢复网络 %L 失败"
                            lay pts oldNet)
                    )
                else
                    m = m + 1
                    axlUIWPrint(nil "  跳过: %s 层定位点 %L 处 Shape 当前网络 %L 与本批记录 %L 不符（可能已被再次修改）"
                        lay pts cur newNet)
                )
            else
                m = m + 1
                axlUIWPrint(nil "  警告: %s 层定位点 %L 附近未找到 Shape（可能已被删除）"
                    lay pts)
            )
        )
        axlClearSelSet()
        axlVisibleUpdate(t)
        axlUIWPrint(nil "撤销完成: 恢复 %d 个 Shape, %d 个失败/跳过" n m)
        return(t)
    )
)

ASTB_RegisterCommand("ASTB_Shape_ChangeNet" "ASTB_Shape_ChangeNet" ?cmdType "interactive")
ASTB_RegisterCommand("ASTB_Shape_ChangeNetu" 'Shape_ChangeNet_Undo ?cmdType "general" ?undo nil)
; 统一撤销中枢注册（core/trans.il v1.4）：astbundo 按 LIFO 分发到本函数
ASTB_RegisterUndo("shape_changenet" 'Shape_ChangeNet_Undo)

printf("[ASTB] shape_changenet.il loaded.\n")
