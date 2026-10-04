;========================================================================
; 文件名    : modules/routing/route_clinevoid.il
; 作者      : ASTB Team
; 创建日期  : 2026-08-01
; 版本      : 2.2
; 功能描述  : 走线选层挖空：拾取走线（点选/框选），按外扩值在
;             指定 ETCH 层的铜皮上创建挖空（void）：静态铜皮直接
;             axlDBCreateVoid 挖空（v2.1 起），动态铜皮走 ROUTE
;             KEEPOUT 避让。
; 依赖模块  : forms/route_layervoid.form（与 route_padvoid 共用）、
;             core/trans.il (ASTB_RegisterCommand/ASTB_DBTransactionMark)
; 启动命令  : clinevoid（或菜单 Routing -> Cline Layer Void）
; 编码      : GBK（含中文，必须 GBK 保存）
; 风险提示  : 修改数据库（铜皮挖空），执行前请先备份 .brd
; 修改记录  :
;   2026-10-01 v2.2 ASTB Team 静态挖空补 poly->path 转换：v1.4 实机
;                     记录本机 axlDBCreateVoid 拒收 r_poly，新增
;                     CV_PolyToPath（首尾闭合、二维点表）；r_path
;                     直传，listp 判别
;   2026-10-01 v2.1 ASTB Team 静态铜皮直接挖空（keepout 不消静态铜）：
;                     与 route_padvoid v2.2 同机制——RunCore 追加静态
;                     挖空：枚举目标 ETCH 层铜皮，bbox 相交预判后
;                     errset(axlDBOpenShape) 打开（动态生成品抛
;                     Cannot edit a generated shape 被兜住跳过），
;                     静态打开者 axlDBCreateVoid(外扩轮廓) 后必
;                     CloseShape；撤销批次新增三元素 ("svoid" 层
;                     中心点) 项，CV_Undo 按 voids/shapes 过滤器
;                     逐项切换删除；完成提示改三段式
;   2026-10-01 v2.0 ASTB Team 名称调整：走线隔层挖空 -> 走线选层挖空
;                     （表单标题/菜单标签/帮助同步）
;   2026-08-01 v1.0 ASTB Team 初始创建
;   2026-08-01 v1.1 ASTB Team 实机修复：axlFormBuildPopup 改扁平
;                     字符串列表（嵌套格式本机报 Illegal popup
;                     list format，下拉为空导致目标层读到 "0"）
;   2026-08-01 v1.2 ASTB Team 实机修复：表单回调里对象 dbid 已失效
;                     （dbid:removed）——拾取完成即预取轮廓多边形
;                     与包围盒存 _CV_data，回调只用 SKILL 侧数据
;   2026-08-01 v1.3 ASTB Team 实机修复：动态铜皮生成品不可编辑
;                     （Cannot edit a generated shape）——sh->shapeBoundary
;                     重定向到动态边界挖空，挖完 axlShapeDynamicUpdate
;                     刷新；v1.2 的 sh->dynamic 是臆造属性已移除
;   2026-08-01 v1.4 ASTB Team 实机修复：本机 axlDBCreateVoid 不收
;                     r_poly（Not an r_path defstruct）——改外扩包围盒
;                     矩形 r_path 挖空（CV_BBoxVoidPath，首尾闭合）
;   2026-08-01 v1.5 ASTB Team 轮廓贴合挖空（用户要求）：外扩 r_poly
;                     经临时铜皮 ->vertices 转 r_path（CV_PolyToPath，
;                     r_poly 为直线段多边形，arc 已 tessellate），
;                     失败退回包围盒矩形并计数
;   2026-08-01 v1.5.1 ASTB Team 实机修复：临时铜皮未关就删
;                     （Cannot delete the active shape）残留打开态，
;                     后续 axlDBOpenShape 全被拒（A Shape is already
;                     open）——CV_PolyToPath 先 CloseShape 再删
;   2026-08-01 v1.5.2 ASTB Team 实机修复：a) CloseShape 后原 dbid
;                     失效（dbid:removed），改用其返回的新 dbid 删除；
;                     b) 存在无 bBox 的铜皮致 leqp (x <= nil) 中断
;                     整批——CV_BBoxHit 全量 nil 防御
;   2026-08-01 v1.5.3 ASTB Team 诊断版（临时）：轮廓未贴合且距离
;                     与设置不符——CV_PolyToPath 加顶点原始格式
;                     探针 + 结果打印外扩值与设计单位
;   2026-08-01 v1.6 ASTB Team 改 keepout 机制（用户指定方案）：
;                     诊断证实 ->vertices 读取失败；弃用
;                     OpenShape/void/shapeBoundary 链路，轮廓 r_poly
;                     直接 axlDBCreateShape 到 ROUTE KEEPOUT/<层>
;                     （route_linetoshape.il 实证通路），动态铜皮
;                     自动避让成洞；外扩允许 0；移除死代码
;   2026-08-13 v1.7 ASTB Team 新增 pvu 撤销命令（Done 后可用）：
;                     keepout 批次栈存 (层 中心点) 不存 dbid，
;                     现场查找删除后刷新回填（rviau 实证模式）
;   2026-08-20 v1.8 ASTB Team 拾取右键菜单 Done 置顶（用户约定：
;                     Done 始终第一项）
;   2026-08-20 v1.9 ASTB Team 接入统一撤销中枢 astbundo（core/trans.il
;                     v1.4）：ASTB_RegisterUndo 注册 CV_Undo，批次入栈
;                     同步 ASTB_UndoJournalPush；Done 提示改指 astbundo
;                     （cvu 命令保留为别名）
;========================================================================

unless( boundp('_CV_fw)     _CV_fw     = nil )
unless( boundp('_CV_data)   _CV_data   = nil )
unless( boundp('_CV_done)   _CV_done   = nil )
unless( boundp('_CV_cancel) _CV_cancel = nil )
unless( boundp('_CV_undoStack) _CV_undoStack = nil )
unless( boundp('_CV_svoidRecs) _CV_svoidRecs = nil )





;------------------------------------------------------------------------
; 函数    : CV_RunCore
; 功能    : 批量挖空执行体（ASTB_DBTransactionMark 包裹调用）：
;           遍历 _CV_data 中预取的 (轮廓多边形 包围盒 位置)，轮廓
;           外扩（可为 0）后在目标层创建 ROUTE KEEPOUT 铜皮——
;           动态铜皮自动避让即形成挖空；v2.1 起追加静态铜皮直接
;           挖空（keepout 不消静态铜）：枚举目标 ETCH 层铜皮，
;           相交预判后逐块 OpenShape/CreateVoid/CloseShape
; 参数    : t_layer - 目标子层名（如 "L2-GND1"）；expand - 外扩值
; 备注    : v1.6 起改 keepout 机制（用户指定）：r_poly 直接给
;           axlDBCreateShape 建 keepout（route_linetoshape.il 实证
;           通路），弃用 OpenShape/void/shapeBoundary 链路；
;           v2.1 静态挖空仅对静态铜皮生效（动态铜皮仍走 keepout）
; 返回    : 成功创建的 keepout 数
;------------------------------------------------------------------------
procedure( CV_RunCore(t_layer expand)
    prog( (item rr usePoly cnt skip xy koLayer batch
           etchLayer vr sr allShapes sh todos voidOk okS skipS rec)
        cnt = 0
        skip = 0
        okS = 0
        skipS = 0
        batch = nil
        todos = nil
        koLayer = strcat("ROUTE KEEPOUT/" t_layer)
        etchLayer = strcat("ETCH/" t_layer)
        axlUIWPrint(nil "挖空参数: 目标层 %s, 外扩 %L %s"
            koLayer expand car(axlDBGetDesignUnits()))
        ; ---- v2.1 静态挖空准备：层可挖判据 + 目标层铜皮枚举 ----
        ; 仅 ETCH 等层允许 void（pitfalls 5.2），不可挖层只建 keepout
        vr = errset( axlOK2Void(etchLayer) nil )
        voidOk = and(vr car(vr))
        allShapes = nil
        if( voidOk then
            ; 主路：设计级 shapes 枚举。注意 24.1 桥探针曾报
            ; axlDBGetDesign()->shapes 返回空表（pitfalls 5.5）
            ; ——本通路待实机确认，落空时回退 axlDBGetShapes
            ; （padvoid v1.3 实机验证通路）
            sr = errset( axlDBGetDesign()->shapes nil )
            if( and(sr car(sr)) then
                foreach( sh car(sr)
                    when( equal(sh->layer etchLayer)
                        allShapes = cons(sh allShapes)
                    )
                )
            else
                sr = errset( axlDBGetShapes(etchLayer) nil )
                allShapes = and(sr car(sr))
            )
        else
            axlUIWPrint(nil "提示: %s 不允许 void, 仅创建 keepout(动态避让)" etchLayer)
        )
        foreach( item _CV_data
            xy = caddr(item)
            if( expand > 0 then
                rr = errset( axlPolyExpand(car(item) expand 'NONE) t )
                usePoly = and(rr car(rr) car(car(rr)))
            else
                usePoly = car(item)
            )
            if( null(usePoly) then
                skip = skip + 1
                axlUIWPrint(nil "  警告: 对象 %L 外扩失败, 跳过" xy)
            else
                rr = errset( axlDBCreateShape(usePoly t koLayer) t )
                if( and(rr car(rr) car(car(rr))) then
                    cnt = cnt + 1
                    ; 撤销批次记录 (keepout层 中心点)——不存 dbid
                    ; （跨命令失效 dbid:removed，pitfalls 2.6 扩展）
                    batch = cons(list(koLayer xy) batch)
                else
                    skip = skip + 1
                    axlUIWPrint(nil "  警告: 对象 %L 处 keepout 创建失败" xy)
                )
                ; v2.1：收集静态挖空待办 (外扩轮廓 包围盒 中心点)
                when( and(voidOk allShapes)
                    todos = cons(list(usePoly cadr(item) xy) todos)
                )
            )
        )
        ; ---- v2.1 静态铜皮直接挖空（动态生成品打不开被 errset 跳过）----
        when( and(voidOk allShapes todos)
            sr = CV_VoidStatics(allShapes etchLayer todos expand)
            okS = car(sr)
            skipS = cadr(sr)
            ; 静态挖空撤销记录（三元素项）并入本批次
            foreach( rec _CV_svoidRecs
                batch = cons(rec batch)
            )
        )
        when( batch
            _CV_undoStack = cons(reverse(batch) _CV_undoStack)
            ASTB_UndoJournalPush("route_clinevoid")
        )
        ; keepout 就位后刷新动态填充，动态铜皮避让出空洞
        errset( axlShapeDynamicUpdate(nil nil) nil )
        axlUIWPrint(nil "挖空完成: keepout %d 个(动态避让), 静态铜皮挖空 %d 个, 跳过 %d 个"
            cnt okS skip + skipS)
        when( or(cnt > 0 okS > 0)
            axlUIWPrint(nil "提示: 输入 astbundo 可撤销本次修改")
        )
        return(cnt)
    )
)

;------------------------------------------------------------------------
; 函数    : CV_BBoxHit
; 功能    : 包围盒相交预判（v2.1）：ib 按 expand 外扩四边后与 sb
;           重叠返回 t。任何坐标 nil 直接返回 nil（v1.5.2 教训：
;           无 bBox 铜皮的 nil 算术会中断整批）；调用侧再包 errset
; 参数    : ib/sb - ((xlo ylo) (xhi yhi)) 结构包围盒
; 返回    : t/nil
;------------------------------------------------------------------------
procedure( CV_BBoxHit(ib sb expand)
    prog( (xlo ylo xhi yhi)
        unless( and(ib car(ib) cadr(ib) sb car(sb) cadr(sb)
                    car(car(ib)) cadr(car(ib)) car(cadr(ib)) cadr(cadr(ib))
                    car(car(sb)) cadr(car(sb)) car(cadr(sb)) cadr(cadr(sb)))
            return(nil)
        )
        xlo = car(car(ib)) - expand
        ylo = cadr(car(ib)) - expand
        xhi = car(cadr(ib)) + expand
        yhi = cadr(cadr(ib)) + expand
        return( not( or(xhi < car(car(sb))
                        xlo > car(cadr(sb))
                        yhi < cadr(car(sb))
                        ylo > cadr(cadr(sb)))) )
    )
)

;------------------------------------------------------------------------
; 函数    : CV_PolyToPath
; 功能    : r_poly 转 r_path（v2.2）：v1.4 实机记录本机 axlDBCreateVoid
;           拒收 r_poly（Not an r_path defstruct），静态挖空前必须转换；
;           取外环点表（car），首尾闭合（v1.4 矩形挖空实证纪律）。
;           点统一规整为 (x y) 二维表——本机 axlPathStart 拒 x:y 点对
;           （报 range，pitfalls §12），r_poly 点可能是点对形式。
;           弧段按折线弦近似（PolyExpand 'NONE 产出已直线化）。
; 参数    : poly - r_poly（list 结构；r_path 请勿传入）
; 返回    : r_path / nil
;------------------------------------------------------------------------
procedure( CV_PolyToPath(poly)
    prog( (pts p np pr)
        unless( and(listp(poly) car(poly) cdr(car(poly)))
            return(nil)
        )
        ; 点规整：(x . y) 点对 / (x y) 表 统一成 (x y) 二维表
        np = nil
        foreach( p car(poly)
            if( listp(cdr(p)) then
                np = cons(list(car(p) cadr(p)) np)
            else
                np = cons(list(car(p) cdr(p)) np)
            )
        )
        pts = reverse(np)
        ; 首尾闭合
        pr = errset( axlPathStart(append(pts list(car(pts)))) nil )
        return( and(pr car(pr)) )
    )
)

;------------------------------------------------------------------------
; 函数    : CV_VoidStatics
; 功能    : 静态铜皮直接挖空（v2.1）：对目标 ETCH 层每块相交铜皮
;           OpenShape 一次、逐个挖入待办轮廓、CloseShape 一次（手册
;           推荐的多挖空写法，也规避 v1.5.2 开关后 dbid 失效问题——
;           每块铜皮只开关一次，dbid 不跨项复用）。
;           动态铜皮生成品打不开（Cannot edit a generated shape），
;           由 errset 兜住跳过——静/动态天然分工，不检测动态属性
;           （该属性是臆造的、不存在，pitfalls 5.3）；
;           打开成功但挖空失败也照常关闭，不留打开态（v1.5.1
;           "A Shape is already open" 连锁拒绝教训）。
; 参数    : allShapes - 目标层铜皮 dbid 列表；etchLayer - "ETCH/<层>"；
;           todos - ((轮廓r_poly/r_path 包围盒 中心点) ...) 待办表；
;           expand - 外扩值（相交预判用）
; 备注    : 撤销记录 ("svoid" etchLayer 中心点) 经全局 _CV_svoidRecs
;           通道回传（pitfalls 4.4 全局通道惯例）
; 返回    : (挖空成功数 挖空失败数)
;------------------------------------------------------------------------
procedure( CV_VoidStatics(allShapes etchLayer todos expand)
    prog( (sh todo vp ib vxy sb osh vr cr hr okCnt skipCnt hit anyHit vpath)
        okCnt = 0
        skipCnt = 0
        _CV_svoidRecs = nil
        foreach( sh allShapes
            ; 整包相交预判：没有任何待办与铜皮 bBox 相交则不打开
            ; （减少无谓开关；无 bBox 铜皮不打开，v1.5.2 nil 防御）
            sb = errset( sh->bBox nil )
            sb = and(sb car(sb))
            anyHit = nil
            when( sb
                foreach( todo todos
                    ib = cadr(todo)
                    when( null(anyHit)
                        if( and(ib car(ib) cadr(ib)) then
                            hr = errset( CV_BBoxHit(ib sb expand) nil )
                            when( and(hr car(hr))
                                anyHit = t
                            )
                        else
                            ; 待办无包围盒：保守视为相交（挖空有 errset 兜底）
                            anyHit = t
                        )
                    )
                )
            )
            when( anyHit
                ; 动态铜皮生成品打不开（Cannot edit a generated shape），
                ; errset 兜住跳过，不计入跳过数——动态铜皮的挖空已由
                ; keepout 避让覆盖
                osh = errset( axlDBOpenShape(sh nil nil) t )
                when( and(osh car(osh))
                    osh = car(osh)
                    foreach( todo todos
                        vp  = car(todo)
                        ib  = cadr(todo)
                        vxy = caddr(todo)
                        hit = t
                        when( and(ib car(ib) cadr(ib))
                            hr = errset( CV_BBoxHit(ib sb expand) nil )
                            hit = and(hr car(hr))
                        )
                        when( hit
                            ; v1.4 实机：本机 axlDBCreateVoid 拒收 r_poly
                            ; (Not an r_path defstruct)——r_poly 先转 r_path；
                            ; 焊盘 figure 本是 r_path 直接用；listp 判别两型
                            if( listp(vp) then
                                vpath = CV_PolyToPath(vp)
                            else
                                vpath = vp
                            )
                            vr = and( vpath
                                      errset( axlDBCreateVoid(osh vpath) t ) )
                            if( and(vr car(vr)) then
                                okCnt = okCnt + 1
                                _CV_svoidRecs = cons(list("svoid" etchLayer vxy)
                                                     _CV_svoidRecs)
                            else
                                skipCnt = skipCnt + 1
                                axlUIWPrint(nil "  警告: %L 处静态铜皮挖空失败" vxy)
                            )
                        )
                    )
                    ; 打开成功但挖空失败也照常关闭，不留打开态
                    cr = errset( axlDBCreateCloseShape(osh) t )
                    unless( and(cr car(cr))
                        axlUIWPrint(nil "  警告: 静态铜皮关闭失败, 请检查铜皮状态")
                    )
                )
            )
        )
        return(list(okCnt skipCnt))
    )
)

;------------------------------------------------------------------------
; 函数    : CV_Undo
; 功能    : 撤销最近一次挖空（astbundo / cvu 命令，Done 后仍可用）：
;           按批次记录现场查找删除（选择集返回新鲜 dbid），再刷新
;           动态填充回填铜皮。批次项两种：两元素 (keepout层 中心点)
;           删 keepout 铜皮；三元素 ("svoid" ETCH层 中心点)（v2.1）
;           删静态铜皮上的 void。两类 find filter 不同（shapes /
;           voids），逐项切换，结束恢复 shapes（本函数历史结束态）
;------------------------------------------------------------------------
procedure( CV_Undo()
    prog( (batch item koLayer xy n m vn sh vd hit)
        unless( _CV_undoStack
            axlUIWPrint(nil "没有可撤销的挖空记录")
            return(nil)
        )
        batch = car(_CV_undoStack)
        _CV_undoStack = cdr(_CV_undoStack)
        n = 0
        m = 0
        vn = 0
        foreach( item batch
            if( equal(car(item) "svoid") then
                ; ---- 静态挖空撤销（v2.1 三元素项 ("svoid" 层 中心点)）----
                koLayer = cadr(item)
                xy      = caddr(item)
                axlSetFindFilter(?enabled '("noall" "voids")
                                 ?onButtons '("noall" "voids"))
                axlClearSelSet()
                hit = nil
                ; 点选 void 是否命中 void 内部点待实机确认；不命中时
                ; 退化为失败计数提示（不中断其余项）
                when( axlSingleSelectPoint(xy)
                    foreach( vd axlGetSelSet()
                        when( and(null(hit) equal(vd->layer koLayer))
                            hit = vd
                        )
                    )
                )
                if( and(hit errset( axlDeleteObject(hit) t )) then
                    vn = vn + 1
                else
                    m = m + 1
                    axlUIWPrint(nil "  警告: %L 处 %s 的 void 未找到或删除失败" xy koLayer)
                )
            else
                ; ---- keepout 撤销（两元素项，原逻辑）----
                koLayer = car(item)
                xy      = cadr(item)
                axlSetFindFilter(?enabled '("noall" "shapes")
                                 ?onButtons '("noall" "shapes"))
                axlClearSelSet()
                hit = nil
                when( axlSingleSelectPoint(xy)
                    foreach( sh axlGetSelSet()
                        when( and(null(hit) equal(sh->layer koLayer))
                            hit = sh
                        )
                    )
                )
                if( and(hit errset( axlDeleteObject(hit) t )) then
                    n = n + 1
                else
                    m = m + 1
                    axlUIWPrint(nil "  警告: %L 处 %s keepout 未找到或删除失败" xy koLayer)
                )
            )
        )
        axlClearSelSet()
        ; 恢复 shapes 过滤器（v2.1 前本函数的结束态）
        axlSetFindFilter(?enabled '("noall" "shapes") ?onButtons '("noall" "shapes"))
        errset( axlShapeDynamicUpdate(nil nil) nil )
        axlUIWPrint(nil "撤销完成: 删除 %d 个 keepout, %d 个静态 void, %d 个失败" n vn m)
        return(t)
    )
)

;------------------------------------------------------------------------
; 函数    : CV_FormCB
; 功能    : 参数表单回调
;------------------------------------------------------------------------
procedure( CV_FormCB(fw)
    prog( (expandStr)
        if( nequal(fw->doneState 0) then
            axlFormClose(fw)
            return(nil)
        )
        case( fw->curField
            ("apply"
                expandStr = axlFormGetField(fw "expand")
                if( or(null(expandStr) equal(expandStr "")) then
                    axlUIWPrint(nil "ERROR: 请输入外扩值")
                else
                    prog( (expand t_layer)
                        expand = atof(expandStr)
                        t_layer = axlFormGetField(fw "layer")
                        if( and(expand >= 0 t_layer) then
                            ; 先读后关（表单关闭后句柄失效）
                            axlFormClose(fw)
                            ASTB_DBTransactionMark('CV_RunCore
                                list(t_layer expand))
                        else
                            axlUIWPrint(nil "ERROR: 外扩值不能为负")
                        )
                        return(nil)
                    )
                )
            )
            ("quit"
                axlFormClose(fw)
            )
            (t nil)
        )
        return(t)
    )
)

;------------------------------------------------------------------------
; 函数    : CV_PickDone / CV_PickCancel
; 功能    : 拾取循环右键菜单回调（命名函数串，pitfalls 2.8 模式）
;------------------------------------------------------------------------
procedure( CV_PickDone()
    _CV_done = t
    axlUIPopupSet(nil)
    axlFinishEnterFun()
)

procedure( CV_PickCancel()
    _CV_cancel = t
    axlClearSelSet()
    axlUIPopupSet(nil)
    axlCancelEnterFun()
)

;------------------------------------------------------------------------
; 函数    : CV_OpenForm
; 功能    : 打开参数表单（目标层下拉动态构建）
;------------------------------------------------------------------------
procedure( CV_OpenForm()
    prog( (fw formFile layers popupItems lay)
        formFile = strcat(ASTB_GLOBAL->FormPath "/route_layervoid.form")
        fw = axlFormCreate('_CV_fw formFile '("NE" "msglines" 1) 'CV_FormCB t nil)
        unless( fw
            axlUIWPrint(nil "ERROR: 表单创建失败, 请检查 forms/route_layervoid.form")
            return(nil)
        )
        axlFormTitle(fw "走线选层挖空")
        layers = axlGetParam("paramLayerGroup:Etch")->groupMembers
        ; 本机 axlFormBuildPopup 实证接受"扁平字符串列表"
        ; （route_automatchgroup.il 同款），嵌套 (("label")) 格式
        ; 报 Illegal popup list format
        popupItems = nil
        foreach( lay layers
            popupItems = cons(lay popupItems)
        )
        axlFormBuildPopup(fw "layer" reverse(popupItems))
        axlFormSetField(fw "layer" car(layers))
        axlFormSetField(fw "expand" "10")
        axlFormDisplay(fw)
        return(fw)
    )
)

;------------------------------------------------------------------------
; 函数    : CV_Main
; 功能    : 命令入口：拾取走线 -> 参数表单 -> 批量挖空
;           （拾取用 axlSelect ?groupMode t，点选/框选直接生效）
;------------------------------------------------------------------------
procedure( CV_Main()
    prog( (popup objs obj rr poly)
        unless( axlOKToProceed()
            axlUIWPrint(nil "ERROR: 当前环境不允许执行该操作")
            return(nil)
        )
        _CV_done   = nil
        _CV_cancel = nil
        axlSetFindFilter(?enabled '("noall" "clines")
                         ?onButtons '("noall" "clines"))
        axlClearSelSet()
        ; 右键菜单标签必须英文（GBK 中文标签触发 reader Invalid character）
        popup = axlUIPopupDefine(nil
            list(
                list("Done"   "CV_PickDone()")
                list("Undo"   "ASTB_SystemUndo()")
                list("Cancel" "CV_PickCancel()")
            ))
        axlUIPopupSet(popup)
        axlSelect(?groupMode t
                  ?prompt "点选或框选要挖空的走线, 右键 Done 完成")
        axlUIPopupSet(nil)
        objs = axlGetSelSet()
        if( or(_CV_cancel null(objs)) then
            axlClearSelSet()
            axlUIWPrint(nil "未选择任何走线, 命令结束")
            return(nil)
        )
        ; 立即预取轮廓与包围盒（dbid 在表单回调上下文会失效
        ; 报 dbid:removed，v1.1 实机踩坑；r_poly 不失效）
        _CV_data = nil
        foreach( obj objs
            rr = errset( axlPolyFromDB(obj ?endCapType "ROUND") nil )
            poly = and(rr car(rr) car(car(rr)))
            when( poly
                _CV_data = cons(list(poly obj->bBox obj->xy) _CV_data)
            )
        )
        unless( _CV_data
            axlUIWPrint(nil "ERROR: 全部对象轮廓获取失败, 命令结束")
            return(nil)
        )
        axlUIWPrint(nil "共选择 %d 个对象(成功取轮廓 %d 个), 请设置挖空参数"
            length(objs) length(_CV_data))
        CV_OpenForm()
        return(t)
    )
)

ASTB_RegisterCommand("clinevoid" 'CV_Main ?cmdType "interactive")
ASTB_RegisterCommand("cvu" 'CV_Undo ?cmdType "general" ?undo nil)
; 统一撤销中枢注册（core/trans.il v1.4）：astbundo 按 LIFO 分发到本函数
ASTB_RegisterUndo("route_clinevoid" 'CV_Undo)

;------------------------------------------------------------------------
; 函数名  : ASTB_Route_ClineVoid
; 功能    : Toolbox 菜单包装：走线选层挖空（CV_Main 入口）
;------------------------------------------------------------------------
procedure( ASTB_Route_ClineVoid()
    CV_Main()
)

ASTB_RegisterCommand("ASTB_Route_ClineVoid" "ASTB_Route_ClineVoid" ?cmdType "interactive")

printf("[ASTB] route_clinevoid.il loaded, command: clinevoid\n")
