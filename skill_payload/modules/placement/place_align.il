;   2026-08-20 v1.7 ASTB Team 撤销命令注册补 ?undo nil（防系统撤销把
;                   撤销命令本身入栈，17.4+）
;   2026-08-25 v1.8 ASTB Team 防僵尸命令守卫：
;              操作崩溃曾杀死选择循环而表单/全局残留(按钮能点、
;              无人执行=点选/居中全失灵, Reload 清不掉);
;              handler 执行包 errset 循环不死 + 循环入口刷新过滤
;              失效 dbid + 列表重选改 Clear+AddSelect
;   2026-08-25 v1.9 ASTB Team alnRefreshIDs 丢弃 dbid:removed：
;              该过滤曾随 Shift+ 回退被一并撤掉, 导致 v1.8 的
;              循环入口刷新形同虚设(removed 直通->警告+崩溃)
;   2026-08-25 v1.11 ASTB Team 连点/框选/居中修复(治本):
;              axlSelect groupMode nil->t——nil 模式每次新选把旧选
;              dbid 作废(17.4 S039 探针实锤), v1.2 裸 dbid 合并 hack
;              攒不起选择, 操作撞 removed 崩 max(nil); groupMode t
;              原生累积且 dbid 不失效(项目先例 rvia v1.7);
;              同时拆除 v1.10 临时探针
;   2026-08-25 v1.12 ASTB Team 按钮 No object(s) found 修复:
;              groupMode t 下拾取全在一次 axlSelect 内完成, 首轮
;              持有集必 nil, 旧"两者非空才合并"使新选集到不了
;              执行列表; 改为无条件并集写回 _alnSelectedObjects
;   2026-08-25 v1.14 ASTB Team 操作后清空选择集(治 op2 本):
;              探针实锤保留路径的新 dbid 下一轮 axlSelect 即死,
;              是 op2 撞 removed 的唯一来源; 用户本就每轮重选,
;              操作后统一 Clear; 拆 v1.13 探针
;   2026-08-25 v1.15 ASTB Team 分布修复: On 回调里排序时选择集
;              未物化(groupMode t 流程), Calc 用到 car/last 的
;              是无序表; 排序移到四个 Calc handler 入口
;   2026-08-25 v1.16 ASTB Team 身份法保留选择集:
;              v1.14 清空断了"同集多操作/边选边加"工作流;
;              操作前快照身份, 操作后按 refdes/name/text+xyAfter
;              现场重找新鲜 dbid 重选(alnUndoFindObject 通路),
;              裸 dbid 永不跨轮携带(跨轮必死, 探针实锤)
;   2026-08-25 v1.17 ASTB Team 修身份快照双重包装(重选落空
;              致二次操作 No object(s) found, 实机探针实锤)
;   2026-08-25 v1.18 ASTB Team 身份为唯一跨轮状态(架构定稿):
;              变换对象的任何 dbid 下一轮 axlSelect 必死(两轮
;              探针实锤), 裸 dbid 携带方案全部推翻; 身份集
;              _alnCarriedIds 跨轮持久, 每轮现场解析新鲜 dbid
;              即用即弃, 操作后仅用撤销记录更新身份坐标
;   2026-08-25 v1.19 ASTB Team 每操作独立事务即时提交(dbid 用完
;              不扔, 对象落定求 dbid 跨轮存活; v1.18 身份架构兜底);
;              Oops/Cancel 改记录回滚(alnUndoMoveBack), Oops 同步
;              回滚身份坐标
;========================================================================
; 文件名    : place_align.il
; 作者      : Wanghh (https://github.com/whh5118/GTOpen) / Toolbox（整合）
; 创建日期  : 2026-07-16
; 版本      : 1.19
; 功能描述  : 元器件对齐与等间距分布工具，支持上下左右对齐、水平垂直居中、等间距分布、Pick点对齐
; 依赖模块  : forms/align.form, core/trans.il（ASTB_RegisterCommand）
;             （原 align_do.il / align_utils.il 已合并进本文件；
;               align-*.bmp / distribute*.bmp / pick*.bmp 需放入 %bmppath%）
; 修改记录  :
;   2026-07-16 v1.0 Toolbox 初始创建
;   2026-07-17 v1.1 Toolbox 热键改绑 Ctrl 组合键并补回 alnXxx 命令注册（原绑定目标
;              不存在且劫持 a/s/w/d 等打字键）；网格吸附公式先减原点再取整；
;              修复 alnMoveObject/alnGetPinLocation 全局变量泄漏；表单数据序列化改显式
;              字段存储（原 %L 只存 (t) 骨架，二次启动必崩）；移除 axlUIMenuRegister
;              双轨菜单与开发期硬编码路径
;   2026-07-19 v1.2 Toolbox 点选累加: axlSelect 返回后本轮新选与
;              上轮选择求并集并重选(实现按住 Ctrl 点选多个器件);
;              空返回时恢复累积选择; 右键菜单新增 Clear(alnClear)
;   2026-08-01 v1.3 ASTB Team 热键表 _alnKeyMap 数据驱动化：
;              部分 Ctrl 组合（~S/~Z 等）与系统默认冲突绑定失败
;              且静默失效——改为遍历键位表绑定，失败收集并打印
;              清单提示换绑；解绑同样走键位表（换键后还原对称）
;   2026-08-17 v1.4 ASTB Team 表单改全路径加载：16.6 按裸名
;              "align.form" 搜索失败（FORMPATH 只认启动期 env），
;              axlMiniStatusLoad 改 strcat(ASTB_GLOBAL->FormPath ...)，
;              与 rvia/refdescenter/gerbersetup 同款写法
;   2026-08-20 v1.5 ASTB Team 新增撤销命令 ASTB_Place_Alignu（ALN_Undo）：
;              系统 Ctrl+Z 不覆盖 AXL 改动，撤销由模块自维护——Done 提交
;              时把本次会话修改压入全局批次栈 _ALN_undoBatches（只存
;              refdes/焊盘名+坐标/线段端点+层+网络等定位信息，不存
;              dbid）；撤销时现场查找新鲜 dbid：移动按 -delta 移回，
;              拉伸新建线段按端点匹配删除，被删线段按端点/宽度/层/
;              网络重建；alnOops 同步截断对应记录
;   2026-08-20 v1.6 ASTB Team 接入统一撤销中枢 astbundo（core/trans.il
;              v1.4）：ASTB_RegisterUndo 注册 ALN_Undo，批次入栈同步
;              ASTB_UndoJournalPush；Done 提示改指 astbundo
;              （ASTB_Place_Alignu 保留为别名）
;========================================================================

;
;    原始命令: FYAL（Wanghh），现统一为框架命令 ASTB_Place_Align
;    bitmap 文件需放入 %bmppath%：align-bottom/centerH/centerV/left/right/top.bmp、
;    distributeH.bmp、distributeV.bmp、pickH.bmp、pickV.bmp
;

; --- 附件存储密钥（模块常量，勿随意修改，否则历史附件无法读取） ---
unless(boundp('C_ALN_ATTACH_KEY)
    C_ALN_ATTACH_KEY = "QWE123qwe"
)

; --- Done 撤销批次栈（全局跨命令存活；只存定位信息，绝不存 dbid——
;     dbid 跨命令失效成 dbid:removed，撤销时按定位信息现场查找） ---
unless( boundp('_ALN_undoBatches)
    _ALN_undoBatches = nil
)

procedure( aln()
(prog (_alnNewSel _alnMerged _alnObj)
    when( axlOKToProceed()
        axlDebug(nil)
;        axlDebug(t)
        axlClearSelSet()
        alnInitGlobalVariable()
        alnInitForm()
        alnInitHotKeys()

        _alnPopupA = axlUIPopupDefine( nil
                (list
                    (list "Done" 'alnDone)
                    (list "Oops" 'alnOops)
                    (list "Clear" 'alnClear)
                    (list "Cancel" 'alnCancel)
                ))
        axlUIPopupSet( _alnPopupA )

        axlSetFindFilter(?enabled '(GROUPS SYMBOLS PINS VIAS TEXT NAMEFORM ) ?onButtons _alnCheckedFilterBoxes) ; setup filter
        axlMsgPut("Select object(s)")
        _alnTransactionMark = nil    ; v1.19: 每次操作独立事务(见 handler 块)
        while( _alnFinish == nil
            ; v1.18: 身份为唯一跨轮状态, dbid 每轮现场解析即用即弃——
            ; 17.4 S039 实锤变换对象的任何 dbid 下一轮 axlSelect 必死,
            ; 一切裸 dbid 携带/保留方案在本机均不成立
            axlSelect(?groupMode t ?prompt nil)
            _alnNewSel = axlGetSelSet()
            ; 新选对象身份并入持有身份集(同对象新鲜覆盖)
            when( _alnNewSel
                _alnCarriedIds = _ALN_MergeIds(_alnCarriedIds
                    _ALN_CaptureIds(_alnNewSel))
            )
            ; 当轮解析身份 -> 新鲜 dbid(仅本轮有效)
            _alnSelectedObjects = _ALN_ResolveIds(_alnCarriedIds)
            when( _alnSelectedObjects
                axlClearSelSet()
                axlAddSelectObject(_alnSelectedObjects)
                axlMsgPut("Choose action")
            )
            ; alnUndoFindObject 内部改过过滤器, 恢复对齐选取过滤
            axlSetFindFilter(?enabled '(GROUPS SYMBOLS PINS VIAS TEXT NAMEFORM)
                ?onButtons _alnCheckedFilterBoxes)
            ; remove fixed objects from selection
            _alnSelectedObjects = alnCheckForFixedObjects(_alnSelectedObjects)

            ; execute operation chosen in form
            if( _alnHandler then
                if( _alnSelectedObjects
                    then
                        ; v1.19: 每次操作独立事务, 执行完立即提交——对象落定,
                        ; dbid 跨轮有望存活("用完不扔"); 身份架构(v1.18)兜底
                        _alnTransactionMark = axlDBTransactionStart()
                        ; v1.5: 记录操作执行前的撤销栈位置，供 alnOops 截断
                        _alnUndoMarks = cons(_alnUndoBatch _alnUndoMarks)
                        ; v1.8: handler 崩溃只影响本次操作, 循环必须存活
                        unless( errset(funcall(_alnHandler) t)
                            axlUIWPrint(nil "\261\276\264\316\266\324\306\353\262\331\327\367\312\247\260\334, \303\374\301\356\310\324\324\332\324\313\320\320, \277\311\326\330\320\302\321\241\324\361\326\330\312\324")
                        )
                        errset(axlDBTransactionCommit(_alnTransactionMark) t)
                        _alnTransactionMark = nil
                        ; v1.18: 操作后只更新身份坐标(xyAfter), dbid 弃置
                        _alnCarriedIds = _ALN_UpdateIdsXy(_alnCarriedIds car(_alnUndoMarks))
                        axlClearSelSet()
                        axlSetFindFilter(?enabled '(GROUPS SYMBOLS PINS VIAS TEXT NAMEFORM)
                            ?onButtons _alnCheckedFilterBoxes)
                    else
                        axlMsgPut("No object(s) found")
                )
                _alnHandler = nil
            )
        );end-while
    );endwhen
);end-prog
);endprocedure

;----------------- Menu Call--------------------------------
defun( alnDone ()
    ; v1.19: 各操作已即时提交, 无待提交事务(防御性保留)
    when( _alnTransactionMark
        errset(axlDBTransactionCommit( _alnTransactionMark ) t)
        _alnTransactionMark = nil
    )
    ; v1.5: 提交成功，本次会话修改作为一批压入撤销栈（多次 Done 形成多批）
    when( _alnUndoBatch
        _ALN_undoBatches = cons(_alnUndoBatch _ALN_undoBatches)
        ASTB_UndoJournalPush("place_align")
        axlMsgPut("\315\352\263\311\241\243\312\344\310\353 astbundo \277\311\263\267\317\372\261\276\264\316\320\336\270\304")
    )
    _alnUndoBatch = nil
    _alnUndoMarks = nil
    alnExit()
);end-fun
defun( alnOops ()
    if(_alnHandler then axlFinishEnterFun()) ;for exit from 'doPickH or 'doPickV
    ; v1.19: 每操作已即时提交, Oops 改走记录回滚(与 ALN_Undo 同通路),
    ; 身份坐标同步回滚, 再按身份解析恢复选择
    let( (rest thisOps rec)
        thisOps = nil
        rest = _alnUndoBatch
        while( and( rest not(equal(rest car(_alnUndoMarks))) )
            thisOps = cons(car(rest) thisOps)
            rest = cdr(rest)
        )
        foreach( rec thisOps
            errset(alnUndoMoveBack(rec) t)
        )
        _alnCarriedIds = _ALN_RollbackIdsXy(_alnCarriedIds thisOps)
    )
    when( _alnUndoMarks
        _alnUndoBatch = car(_alnUndoMarks)
        _alnUndoMarks = cdr(_alnUndoMarks)
    )
    ; restore selection
    _alnSelectedObjects = _ALN_ResolveIds(_alnCarriedIds)
    axlClearSelSet()
    axlAddSelectObject(_alnSelectedObjects)
);end-fun
defun( alnCancel ()
    axlDBControl('drcEnable nil)
    ; v1.19: 各操作已即时提交, Cancel 改走全量记录回滚(_alnUndoBatch
    ; 新记录在前, 天然 LIFO 序), 撤销记录一并丢弃
    let( (rec)
        foreach( rec _alnUndoBatch
            errset(alnUndoMoveBack(rec) t)
        )
    )
    _alnUndoBatch = nil
    _alnUndoMarks = nil
    errset(alnExit())
    axlDBControl('drcEnable t)
);end-fun
; v1.2: 清空累积选择(右键 Clear)
defun( alnClear ()
    _alnSelectedObjects = nil
    _alnCarriedIds = nil    ; v1.18: 身份集一并清空
    axlClearSelSet()
    axlMsgPut("Selection cleared")
    axlCancelEnterFun()
);end-fun
defun( alnExit ()
    _alnFinish = t
    axlFormClose(_alnFormPtr)
    axlDehighlightObject(_alnSelectedObjects)
    axlCancelEnterFun()
    axlClearSelSet()
    axlUIPopupSet( nil )
    _alnPopupA = nil
    _alnCheckedFilterBoxes = axlGetFindFilter(t)
    alnStoreFilter(_alnCheckedFilterBoxes)
    _alnTransactionMark = nil
    alnRestoreHotKeys()
    axlDBControl('drcEnable t)
    alnStoreFormData()
    
);end-defun

;-------------------Parameter form data ------------------
defun( alnInitForm () ;
let( (units multiplier)
when( (axlIsDebug) axlMsgPut("alnInitForm"))
    ; v1.4: 16.6 按名字搜表单失败（FORMPATH 只认启动期 env），改全路径加载
    _alnFormPtr = axlMiniStatusLoad( (gensym) strcat(ASTB_GLOBAL->FormPath "/align.form") '_parmCallBack)
    ;_alnFormPtr = axlFormCreate( (gensym) "align.form" '(ne canvas msglines 0) '_parmCallBack t)
    units = axlDBGetDesignUnits()
    case( car(units)
        ("mils" multiplier = 1)
        ("inches" multiplier = 0.001)
        ("microns" multiplier = 25.4)
        ("millimeters" multiplier = 0.0254)
        ("centimeters" multiplier = 0.00254)
    )
    when( ( _alnFormData == nil )
        ; first script launch in current session, trying restore settings
        _alnFormData = alnRestoreFormData()
    )
    if( ( _alnFormData == nil ) 
        then ; first script launch
            _alnFormData = ncons(t)
            
            _alnFormData->units = units
            axlFormSetField(_alnFormPtr "bxPickH" nil)
            _alnFormData->usePickH = nil
            axlFormSetField(_alnFormPtr "bxStepH" nil)
            _alnFormData->useStepH = nil
            axlFormSetField(_alnFormPtr "bxPickV" nil)
            _alnFormData->usePickV = nil
            axlFormSetField(_alnFormPtr "bxStepV" nil)
            _alnFormData->useStepV = nil
            axlFormSetField(_alnFormPtr "fPickH" 0.0)
            _alnFormData->pickH = 0.0
            axlFormSetField(_alnFormPtr "fStepH" (100.0 * multiplier))
            _alnFormData->stepH = 100.0 * multiplier
            axlFormSetField(_alnFormPtr "fPickV" 0.0)
            _alnFormData->pickV = 0.0
            axlFormSetField(_alnFormPtr "fStepV" (100.0 * multiplier))
            _alnFormData->stepV = 100.0 * multiplier
            axlFormSetField(_alnFormPtr "bxGap" nil)
            _alnFormData->useGap = nil
            axlFormSetField(_alnFormPtr "bxStretch" t)
            _alnFormData->useStretch = t
            axlFormSetField(_alnFormPtr "bxRipup" nil)
            _alnFormData->useRipup = nil
            axlFormSetField(_alnFormPtr "bxSnapToGrid" t)
            _alnFormData->snapToGrid = t
            axlFormSetField(_alnFormPtr "cmbSnapPoint" "center")
            _alnFormData->snapPoint = "center"
            axlFormSetField(_alnFormPtr "sPinNumber" "1")
            _alnFormData->snapPinNumber = "1"
        else ; settings present in session or restored from design
            when( car(_alnFormData->units) != car(units) 
                ; units were changed, correct multiplier
                case( car(_alnFormData->units)
    ;                ("mils" multiplier = multiplier / 1)
                    ("inches" multiplier = multiplier / 0.001)
                    ("microns" multiplier = multiplier / 25.4)
                    ("millimeters" multiplier = multiplier / 0.0254)
                    ("centimeters" multiplier = multiplier / 0.00254)
                )
                _alnFormData->pickH    = _alnFormData->pickH * multiplier
                _alnFormData->stepH    = _alnFormData->stepH * multiplier
                _alnFormData->pickV = _alnFormData->pickV * multiplier
                _alnFormData->stepV    = _alnFormData->stepV * multiplier
                _alnFormData->units = units
            )
            axlFormSetField(_alnFormPtr "bxPickH" _alnFormData->usePickH)
            axlFormSetField(_alnFormPtr "bxStepH" _alnFormData->useStepH)
            axlFormSetField(_alnFormPtr "bxPickV" _alnFormData->usePickV)
            axlFormSetField(_alnFormPtr "bxStepV" _alnFormData->useStepV)
            axlFormSetDecimal(_alnFormPtr "fPickH" cadr(units))
            axlFormSetDecimal(_alnFormPtr "fStepH" cadr(units))
            axlFormSetDecimal(_alnFormPtr "fPickV" cadr(units))
            axlFormSetDecimal(_alnFormPtr "fStepV" cadr(units))
            axlFormSetField(_alnFormPtr "fPickH" _alnFormData->pickH)
            axlFormSetField(_alnFormPtr "fStepH" _alnFormData->stepH)
            axlFormSetField(_alnFormPtr "fPickV" _alnFormData->pickV)
            axlFormSetField(_alnFormPtr "fStepV" _alnFormData->stepV)
            axlFormSetField(_alnFormPtr "bxGap" _alnFormData->useGap)
            axlFormSetField(_alnFormPtr "bxStretch" _alnFormData->useStretch)
            axlFormSetField(_alnFormPtr "bxRipup" _alnFormData->useRipup)
            axlFormSetField(_alnFormPtr "bxSnapToGrid" _alnFormData->snapToGrid)
            axlFormSetField(_alnFormPtr "cmbSnapPoint" _alnFormData->snapPoint)
            axlFormSetField(_alnFormPtr "sPinNumber" _alnFormData->snapPinNumber)
    )

    if(_alnFormData->usePickH
        then axlFormSetFieldEditable(_alnFormPtr "fPickH" t)
        else axlFormSetFieldEditable(_alnFormPtr "fPickH" nil)
    )
    if(_alnFormData->usePickV
        then axlFormSetFieldEditable(_alnFormPtr "fPickV" t)
        else axlFormSetFieldEditable(_alnFormPtr "fPickV" nil)
    )

    if(_alnFormData->useStepH
        then axlFormSetFieldEditable(_alnFormPtr "fStepH" t)
        else axlFormSetFieldEditable(_alnFormPtr "fStepH" nil)
    )
    if(_alnFormData->useStepV
        then axlFormSetFieldEditable(_alnFormPtr "fStepV" t)
        else axlFormSetFieldEditable(_alnFormPtr "fStepV" nil)
    )

    if(_alnFormData->useStretch
    then
        axlFormSetField(_alnFormPtr "bxRipup" nil)
        _alnFormData->useRipup = nil
    )
    if(_alnFormData->useRipup then
        axlFormSetField(_alnFormPtr "bxStretch" nil)
        _alnFormData->useStretch = nil
    )
    
    if( (_alnFormData->snapPoint == "pin")
        then axlFormSetFieldVisible( _alnFormPtr "sPinNumber" 1)
        else axlFormSetFieldVisible( _alnFormPtr "sPinNumber" 0)
    )
    when( (axlVersion('version) < 15.7) ; since 15.7
        axlFormSetFieldEditable(_alnFormPtr "bxSnapToGrid" nil)
    )
;    axlFormDisplay(_alnFormPtr)
) ;end let
);end-defun

;---------------Form Call Back-----------------------------------------------
defun( _parmCallBack (form)
when( (axlIsDebug) axlMsgPut("_parmCallBack"))
    case( get(form 'curField)
        ( "bnTop" alnOnTop() )
        ( "bnCenterH" alnOnCenterH() )
        ( "bnBottom" alnOnBottom() )
        ( "bnLeft" alnOnLeft() )
        ( "bnCenterV"  alnOnCenterV() )
        ( "bnRight" alnOnRight() )

        ( "bxPickH" _alnFormData->usePickH = form->curValue
            if(_alnFormData->usePickH
                then axlFormSetFieldEditable(form "fPickH" t)
                else axlFormSetFieldEditable(form "fPickH" nil)
            )
        )
        ( "fPickH" _alnFormData->pickH = form->curValue )
        ( "bnPickH" alnOnPickH() )

        ( "bxPickV" _alnFormData->usePickV = form->curValue
            if(_alnFormData->usePickV
                then axlFormSetFieldEditable(form "fPickV" t)
                else axlFormSetFieldEditable(form "fPickV" nil)
            )
        )
        ( "fPickV" _alnFormData->pickV = form->curValue )
        ( "bnPickV" alnOnPickV() )

        ( "bxStepH"
            _alnFormData->useStepH = form->curValue
            if(_alnFormData->useStepH
                then axlFormSetFieldEditable(form "fStepH" t)
                else axlFormSetFieldEditable(form "fStepH" nil)
            )
        )
        ( "fStepH" _alnFormData->stepH = form->curValue )
        ( "bnDistributeH" alnOnDistributeH() )

        ( "bxStepV"
            _alnFormData->useStepV = form->curValue
            if(_alnFormData->useStepV
                then axlFormSetFieldEditable(form "fStepV" t)
                else axlFormSetFieldEditable(form "fStepV" nil)
            )
        )
        ( "fStepV" _alnFormData->stepV = form->curValue )
        ( "bnDistributeV" alnOnDistributeV() )

        ( "bxGap" _alnFormData->useGap = form->curValue)
        ( "bxStretch"
            _alnFormData->useStretch = form->curValue
            if(_alnFormData->useStretch
            then
                axlFormSetField(form "bxRipup" nil)
                _alnFormData->useRipup = nil
            )
        )
        ( "bxRipup"
            _alnFormData->useRipup = form->curValue
            if(_alnFormData->useRipup then
                axlFormSetField(form "bxStretch" nil)
                _alnFormData->useStretch = nil
            )
        )
        ( "bxSnapToGrid" _alnFormData->snapToGrid = form->curValue    )
        ( "cmbSnapPoint" 
            _alnFormData->snapPoint = form->curValue
            if( (_alnFormData->snapPoint == "pin")
                then axlFormSetFieldVisible( form "sPinNumber" 1)
                else axlFormSetFieldVisible( form "sPinNumber" 0)
            )
        )
        ( "sPinNumber" _alnFormData->snapPinNumber = form->curValue)
    );case
);end-defun

defun( alnInitGlobalVariable ()
    _alnFinish = nil
    when( !boundp('_alnFormData) _alnFormData = nil)
    _alnFormPtr = nil
    _alnHandler = nil
    _alnSelectedObjects = nil
    _alnCarriedIds = nil    ; v1.18: 持久身份集(唯一跨轮选择状态)
    _alnUndoBatch = nil     ; v1.5: 本次会话撤销原语记录（cons 逆序，新记录在前）
    _alnUndoMarks = nil     ; v1.5: 各操作执行前的栈位置（alnOops 截断用）
    when( !boundp('_alnCheckedFilterBoxes) 
        _alnCheckedFilterBoxes = alnRestoreFilter()
        when( !_alnCheckedFilterBoxes _alnCheckedFilterBoxes = '(SYMBOLS VIAS TEXT)        
        )
    )
);end-defun

;------------------------------------------------------------------------
; 对齐热键映射表（v1.3 起可配置）
;   格式：(键位 目标命令 中文说明)，键位语法见手册 08 章
;   （~ = Ctrl，S = Shift，C+功能键 = Ctrl+F 键）。
;   注意：~C/~N/~O/~P/~S/~V/~X/~Y/~Z 等与系统默认冲突的键位
;   绑定会失败（axlSetFunckey 返回 nil），启动时会打印失败清单，
;   直接改下表键位即可换绑（改后重启或重新进入对齐命令生效）。
;------------------------------------------------------------------------
unless( boundp('_alnKeyMap)
    _alnKeyMap = '(
        ("~A" "alnLeft"        "\327\363\266\324\306\353")
        ("~S" "alnBottom"      "\265\327\266\324\306\353")
        ("~W" "alnTop"         "\266\245\266\324\306\353")
        ("~D" "alnRight"       "\323\322\266\324\306\353")
        ("~Q" "alnCenterH"     "\313\256\306\275\276\323\326\320")
        ("~Z" "alnCenterV"     "\264\271\326\261\276\323\326\320")
        ("~E" "alnDistributeH" "\313\256\306\275\267\326\262\274")
        ("~G" "alnDistributeV" "\264\271\326\261\267\326\262\274")
        ("~R" "alnPickH"       "\313\256\306\275\327\245\310\241")
        ("~T" "alnPickV"       "\264\271\326\261\327\245\310\241")
    )
)

defun( alnInitHotKeys ()
    let( (aliases alias aliasFunc funckeys funckey funckeyFunc km)
        ; store all hotkeys    and find hotkey for oops command    
        ; funckeys
        when( (axlVersion('version) >= 16.3) ; since 16.3
            funckeys = axlGetFunckey(nil)
            _alnOriginalFunckeys = nil
            foreach( funckey funckeys
                funckeyFunc = axlGetFunckey(funckey)
                _alnOriginalFunckeys = cons(list(funckey funckeyFunc) _alnOriginalFunckeys)
                when( funckeyFunc == "oops" 
                    _oopsAlias = funckey
                )
            )
        )
        ; aliases
        aliases = axlGetAlias(nil)
        _alnOriginalAliases = nil
        foreach( alias aliases
            aliasFunc = axlGetAlias(alias)
            _alnOriginalAliases = cons(list(alias aliasFunc) _alnOriginalAliases)
            when( aliasFunc == "oops" 
                _oopsAlias = alias
            )
        )

        ; define new actions（注册热键目标命令，alnRestoreHotKeys 中配对注销）
        axlCmdRegister("alnOops"        'alnOops)
        axlCmdRegister("alnLeft"        'alnOnLeft)
        axlCmdRegister("alnBottom"      'alnOnBottom)
        axlCmdRegister("alnTop"         'alnOnTop)
        axlCmdRegister("alnRight"       'alnOnRight)
        axlCmdRegister("alnCenterH"     'alnOnCenterH)
        axlCmdRegister("alnCenterV"     'alnOnCenterV)
        axlCmdRegister("alnDistributeH" 'alnOnDistributeH)
        axlCmdRegister("alnDistributeV" 'alnOnDistributeV)
        axlCmdRegister("alnPickH"       'alnOnPickH)
        axlCmdRegister("alnPickV"       'alnOnPickV)

        ; define new hotkeys（v1.3：键位表 _alnKeyMap 数据驱动，
        ; 绑定失败（系统占用）收集并打印，不再静默失效）
        if( boundp('_oopsAlias) && _oopsAlias
            then axlSetAlias( _oopsAlias "alnOops")
            else axlSetAlias( "F3" "alnOops") ; if hotkey for oops command not assigned
        )
        when( (axlVersion('version) >= 16.3) ; since 16.3
            _alnFailedKeys = nil
            foreach( km _alnKeyMap
                unless( axlSetFunckey(car(km) cadr(km))
                    _alnFailedKeys = cons(strcat(car(km) "(" caddr(km) ")")
                        _alnFailedKeys)
                )
            )
            when( _alnFailedKeys
                axlUIWPrint(nil "\266\324\306\353\310\310\274\374\260\363\266\250\312\247\260\334(\323\353\317\265\315\263\304\254\310\317\263\345\315\273): %L"
                    reverse(_alnFailedKeys))
                axlUIWPrint(nil "\277\311\261\340\274\255 place_align.il \265\304 _alnKeyMap \273\273\260\363\306\344\313\373\274\374\316\273")
            )
        )
    ) ; let
);end-defun

defun( alnRestoreHotKeys ()
    let( (funckey alias km)
                
        axlCmdUnregister("alnOops")
        axlCmdUnregister("alnLeft")
        axlCmdUnregister("alnBottom")
        axlCmdUnregister("alnTop")
        axlCmdUnregister("alnRight")
        axlCmdUnregister("alnCenterH")
        axlCmdUnregister("alnCenterV")
        axlCmdUnregister("alnDistributeH")
        axlCmdUnregister("alnDistributeV")
        axlCmdUnregister("alnPickH")
        axlCmdUnregister("alnPickV")
        when( !boundp('_oopsAlias) || !_oopsAlias
            axlSetAlias( "F3" nil)
        )
        when( (axlVersion('version) >= 16.3) ; since 16.3
            ; v1.3：按键位表解绑（与绑定对称，换键后也能正确还原）
            foreach( km _alnKeyMap
                axlSetFunckey(car(km) nil)
            )

            ; restore funckeys
            foreach( funckey _alnOriginalFunckeys
                when( !axlIsProtectAlias(car(funckey)) ; skip readonly
                    axlSetFunckey(car(funckey) cadr(funckey))
                )
            )
        _alnOriginalFunckeys = nil
        )
        ; restore aliases
        foreach( alias _alnOriginalAliases
            when( !axlIsProtectAlias(car(alias)) ; skip readonly
                axlSetAlias(car(alias) cadr(alias))
            )
        )
        _alnOriginalAliases = nil
    ) ; let
);end-defun

;
; Store form settings to attachment.
; 显式序列化为关联列表——sprintf %L 打印属性表只会落盘 (t) 骨架，
; 恢复后字段全为 nil，第二次启动执行 nil*multiplier 必崩。
;
defun( alnStoreFormData ()
    let( (sFormData attachment fd kvPairs)
        fd = _alnFormData
        when( fd
            kvPairs = list(
                list('units         fd->units)
                list('usePickH      fd->usePickH)
                list('useStepH      fd->useStepH)
                list('usePickV      fd->usePickV)
                list('useStepV      fd->useStepV)
                list('pickH         fd->pickH)
                list('stepH         fd->stepH)
                list('pickV         fd->pickV)
                list('stepV         fd->stepV)
                list('useGap        fd->useGap)
                list('useStretch    fd->useStretch)
                list('useRipup      fd->useRipup)
                list('snapToGrid    fd->snapToGrid)
                list('snapPoint     fd->snapPoint)
                list('snapPinNumber fd->snapPinNumber)
            )
            sFormData = sprintf(nil "%L" kvPairs)
            attachment = axlGetAttachment("AlignFormData" 'string)
            if( attachment
            then
                attachment->data = sFormData
                axlSetAttachment(attachment C_ALN_ATTACH_KEY)
            else
                attachment = axlCreateAttachment("AlignFormData" C_ALN_ATTACH_KEY 0 'string sFormData)
            );if
        )
    ) ; let
);end-defun

;
; Restore form settings from attachment.
; 无法解析或缺少关键字段（历史损坏数据）时返回 nil，按首次启动使用默认值。
;
defun( alnRestoreFormData ()
    prog( (formData attachment sFormData kvPairs pair)
        formData = nil
        attachment = axlGetAttachment("AlignFormData" 'string)
        sFormData = attachment->data
        when( sFormData
            kvPairs = car(errsetstring(strcat("'" sFormData)))
            when( kvPairs
                formData = ncons(t)
                foreach( pair kvPairs
                    when( listp(pair) && length(pair) == 2
                        putprop(formData cadr(pair) car(pair))
                    )
                )
                ; 关键字段缺失则按首次启动处理
                when( formData->units == nil formData = nil )
            )
        )
        return(formData)
    ) ; let
);end-defun


;
; Store selected Find filter checkboxes.
; 
defun( alnStoreFilter (checked) 
    let( (attachment sChecked)
        sChecked = sprintf(nil "%L" checked)
        attachment = axlGetAttachment("AlignSelectFilter" 'string)
        if( attachment
        then
            attachment->data = sChecked
            axlSetAttachment(attachment C_ALN_ATTACH_KEY)
        else
            attachment = axlCreateAttachment("AlignSelectFilter" C_ALN_ATTACH_KEY 0 'string sChecked)
        );if
    ) ; let
);end-defun

;
; Restore selected Find filter checkboxes.
;
defun( alnRestoreFilter ()
    prog( (checked attachment sChecked )
        checked = nil
        attachment = axlGetAttachment("AlignSelectFilter" 'string)
        sChecked = attachment->data
        when( sChecked
            checked = car(errsetstring(strcat("'" sChecked)))
        )
        return(checked)
    ) ; let
);end-defun

; -------------------- 对齐操作（原 align_do.il 内容，已合并） --------------------

defun( alnOnTop ()
    axlMsgPut("Align by TOP boundary")
    _alnHandler = 'alnDoTop
    axlCancelEnterFun()
);end-fun
defun( alnDoTop ()
        axlDBCloak( 'alnDoMoveTop() 'shape )
);end-fun
defun( alnDoMoveTop ()
    let( (lBBoxes maxY i objectItem boxItem boxY objectY griddedY deltaY deltaPoint grids)
        lBBoxes = alnGetBBoxes(_alnSelectedObjects)
        maxY = alnGetMaxBBoxY(lBBoxes)
        grids = alnGetCurrentGrid(_alnSelectedObjects)
        ; move objects
        for( i 1 length(_alnSelectedObjects)
            objectItem = nthelem(i _alnSelectedObjects)
            boxItem = nthelem(i lBBoxes)
            boxY = yCoord(cadr(boxItem))
            deltaY = maxY - boxY

            objectY = yCoord(alnGetObjectLocation(objectItem))    ; irginal point
            griddedY = yCoord(alnGriddedPoint(list( 0 (objectY + deltaY) ) grids)) ; moved and snapped point

            deltaY = griddedY - objectY
            deltaPoint = list( 0 deltaY)
            alnMoveObject( objectItem deltaPoint)

        )
    );end-let
);end-fun

defun( alnOnBottom ()
    axlMsgPut("Align by BOTTOM boundary")
    axlFinishEnterFun()
    _alnHandler = 'alnDoBottom
);end-fun
defun( alnDoBottom ()
    axlDBCloak( 'alnDoMoveBottom() 'shape )
);end-fun
defun( alnDoMoveBottom ()
    let( (lBBoxes minY i objectItem boxItem boxY objectY griddedY deltaY deltaPoint grids)
        lBBoxes = alnGetBBoxes(_alnSelectedObjects)
        minY = alnGetMinBBoxY(lBBoxes)
        grids = alnGetCurrentGrid(_alnSelectedObjects)
        ; move objects
        for( i 1 length(_alnSelectedObjects)
            objectItem = nthelem(i _alnSelectedObjects)
            boxItem = nthelem(i lBBoxes)
            boxY = yCoord(car(boxItem))
            deltaY = minY - boxY

            objectY = yCoord(alnGetObjectLocation(objectItem))
            griddedY = yCoord(alnGriddedPoint(list( 0 (objectY + deltaY) ) grids))

            deltaY = griddedY - objectY
            deltaPoint = list( 0 deltaY )
            alnMoveObject( objectItem deltaPoint)
        )
    );end-let
);end-fun

defun( alnOnLeft ()
    axlMsgPut("Align by LEFT boundary")
    axlFinishEnterFun()
    _alnHandler = 'alnDoLeft
);end-fun
defun( alnDoLeft ()
    axlDBCloak( 'alnDoMoveLeft() 'shape )
);end-fun
defun( alnDoMoveLeft ()
    let( (lBBoxes minX i objectItem boxItem boxX objectX griddedX deltaX deltaPoint grids)
        lBBoxes = alnGetBBoxes(_alnSelectedObjects)
        minX = alnGetMinBBoxX(lBBoxes)
        grids = alnGetCurrentGrid(_alnSelectedObjects)
        ; move objects
        for( i 1 length(_alnSelectedObjects)
            objectItem = nthelem(i _alnSelectedObjects)
            boxItem = nthelem(i lBBoxes)
            boxX = xCoord(car(boxItem))
            deltaX = minX - boxX

            objectX = xCoord(alnGetObjectLocation(objectItem))
            griddedX = xCoord(alnGriddedPoint(list( (objectX + deltaX) 0 ) grids))

            deltaX = griddedX - objectX
            deltaPoint = list( deltaX 0 )
            alnMoveObject( objectItem deltaPoint)
        )
    );end-let
);end-fun

defun( alnOnRight ()
    axlMsgPut("Align by RIGHT boundary")
    axlFinishEnterFun()
    _alnHandler = 'alnDoRight
);end-fun
defun( alnDoRight ()
    axlDBCloak( 'alnDoMoveRight() 'shape )
);end-fun
defun( alnDoMoveRight ()
    let( (lBBoxes maxX i objectItem boxItem boxX objectX griddedX gridCorrection deltaX deltaPoint grids)
        lBBoxes = alnGetBBoxes(_alnSelectedObjects)
        maxX = alnGetMaxBBoxX(lBBoxes)
        grids = alnGetCurrentGrid(_alnSelectedObjects)
        ; move objects
        for( i 1 length(_alnSelectedObjects)
            objectItem = nthelem(i _alnSelectedObjects)
            boxItem = nthelem(i lBBoxes)
            boxX = xCoord(cadr(boxItem))
            deltaX = maxX - boxX

            objectX = xCoord(alnGetObjectLocation(objectItem))
            griddedX = xCoord( alnGriddedPoint( list( (objectX + deltaX) 0 ) grids ) )

            deltaX = griddedX - objectX
            deltaPoint = list( deltaX 0 )
            alnMoveObject( objectItem deltaPoint)
        )
    );end-let
);end-fun

defun( alnOnCenterH ()
    axlMsgPut("Align horizontally")
    ; assign handler function
    ; call handler after exit from axlSelect()
    ; otherwise snap to grid not properly work in axlEnterPoint() function
    _alnHandler = 'alnDoCenterH
    ; exite from axlSelect()
    axlFinishEnterFun()
);end-fun
defun( alnDoCenterH ()
    let( (maxY minY fixedPointY pointY)
        maxY = alnMaxY(_alnSelectedObjects)
        minY = alnMinY(_alnSelectedObjects)
        fixedPointY = (maxY-minY)/2 + minY ; 水平中心线 Y 坐标（上下边界中点）
        ; move objects
        axlDBCloak( 'alnMoveToHorizontal(fixedPointY) 'shape )
    );end-let
);end-fun
defun( alnMoveToHorizontal (fixedPointY)
    let( (deltaY deltaPoint pointY grids)
        ; snap to grid (depend on _alnFormData->snapToGrid)
        grids = alnGetCurrentGrid(_alnSelectedObjects)
        fixedPointY = yCoord(alnGriddedPoint( list( 0 fixedPointY) grids))
        foreach( oItem _alnSelectedObjects
            pointY = yCoord(alnGetObjectLocation(oItem))
            deltaY = fixedPointY - pointY
            deltaPoint = list( 0 deltaY)
            alnMoveObject( oItem deltaPoint)
        )
    );end-let
);end-fun

defun( alnOnCenterV ()
    axlMsgPut("Align vertically")
    axlFinishEnterFun()
    _alnHandler = 'alnDoCenterV
);end-fun
defun( alnDoCenterV ()
    let( (maxX minX fixedPointX)
        maxX = alnMaxX(_alnSelectedObjects)
        minX = alnMinX(_alnSelectedObjects)
        fixedPointX = (maxX-minX)/2 + minX
        axlDBCloak( 'alnMoveToVertical(fixedPointX) 'shape )
    );end-let
);end-fun
defun( alnMoveToVertical (fixedPointX)
    let( (deltaX deltaPoint pointX grids)
        ; snap to grid (depend on _alnFormData->snapToGrid)
        grids = alnGetCurrentGrid(_alnSelectedObjects)
        fixedPointX = xCoord(alnGriddedPoint( list( fixedPointX 0) grids))
        foreach( oItem _alnSelectedObjects
            pointX = xCoord(alnGetObjectLocation(oItem))
            deltaX = fixedPointX - pointX
            deltaPoint = list( deltaX 0 )
            alnMoveObject( oItem deltaPoint)
        )
    );end-let
);end-fun

; -------------------- Distribute -------------------------------------
defun( alnOnDistributeH ()
    axlMsgPut("Distribute horizontally")
    ; get propely ordered list of selected ojects
    ; v1.15: 不再此处排序——On 回调时 loop 仍卡在 axlSelect 内,
    ; _alnSelectedObjects 未物化(nil/stale), 排序移到 Calc 执行时
    ; check mode
    if( _alnFormData->useGap
        then _alnHandler = 'alnDoCalcStepBetweenBoundaryH
        else _alnHandler = 'alnDoCalcStepH
    )
    axlFinishEnterFun()
);end-fun
defun( alnDoCalcStepH ()
    let( (leftX rightX step grids)
when( (axlIsDebug) axlMsgPut("alnDoCalcStepH"))
        ; check for step provided in form
        _alnSelectedObjects = alnOrderByX(_alnSelectedObjects)    ; v1.15: 执行时排序
        if( !_alnFormData->useStepH then
            ; calculate step
            leftX = xCoord(alnGetObjectLocation(car(_alnSelectedObjects)))
            rightX = xCoord(alnGetObjectLocation(car(last(_alnSelectedObjects))))
            step = (rightX-leftX)/(length(_alnSelectedObjects)-1)
            ; snap step to grid (depending from _alnFormData->snapToGrid)
            grids = alnGetCurrentGrid(_alnSelectedObjects)
            step = xCoord(alnGriddedPoint( list( step 0) grids))
            ; update form
            _alnFormData->stepH = step
            (axlFormSetField _alnFormPtr "fStepH" step)
        )
;        axlShell("cputime start")
;        axlShell("cputime reset")
        axlDBCloak( 'alnDoDistributeH() 'shape )
;        alnDoDistributeH()
;        axlShell("cputime stop")
    );end-let
);end-fun
defun( alnDoDistributeH ()
    let( (i step pointX deltaX deltaPoint grids)
when( (axlIsDebug) axlMsgPut("alnDoDistributeH"))
        grids = alnGetCurrentGrid(_alnSelectedObjects)
        i = xCoord(alnGriddedPoint(alnGetObjectLocation(car(_alnSelectedObjects)) grids))
        step = _alnFormData->stepH
        foreach( oItem _alnSelectedObjects
            pointX = xCoord(alnGetObjectLocation(oItem))
            deltaX = i - pointX
            deltaPoint = list( deltaX 0 )
            alnMoveObject( oItem deltaPoint)
            i = i + step
        )
    );end-let
);end-fun

defun( alnDoCalcStepBetweenBoundaryH ()
    let( (leftX prevX box lBox gap step grids)
when( (axlIsDebug) axlMsgPut("alnDoCalcStepBetweenBoundaryH"))
        ; check for step provided in form
        _alnSelectedObjects = alnOrderByX(_alnSelectedObjects)    ; v1.15: 执行时排序
        if( !_alnFormData->useStepH then
            gap = 0.0
            ; get left boundary for first object
            prevX = xCoord(car(alnGetObjectBBox(car(_alnSelectedObjects))))
            ; calculate common gap
            lBox = alnGetBBoxes(_alnSelectedObjects)
            foreach( box lBox
                ; get left boundary
                leftX = xCoord(car(box))
                gap = gap + leftX - prevX
                ; get right boundary for next iteration
                prevX = xCoord(cadr(box))
            )
            ; calculate step
            step = gap/(length(_alnSelectedObjects)-1)
            ; snap step to grid
            grids = alnGetCurrentGrid(_alnSelectedObjects)
            step = xCoord(alnGriddedPoint( list( step 0 ) grids))
            _alnFormData->stepH = step
            ; update form
            axlFormSetField(_alnFormPtr "fStepH" step)
        )
;        axlShell("cputime start")
;        axlShell("cputime reset")
        axlDBCloak( 'alnDoDistributeGapBetweenBoundaryH() 'shape )
;        alnDoDistributeGapBetweenBoundaryH()
;        axlShell("cputime stop")
    );end-let
);end-fun
defun( alnDoDistributeGapBetweenBoundaryH ()
    let( (step prevX oItem box leftX rightX deltaX currX destX deltaPoint grids)
when( (axlIsDebug) axlMsgPut("alnDoDistributeGapBetweenBoundaryH"))
        step = _alnFormData->stepH
        ; get left boundary for first object
        prevX = xCoord(car(alnGetObjectBBox(car(_alnSelectedObjects)))) - step
        grids = alnGetCurrentGrid(_alnSelectedObjects)
        foreach( oItem _alnSelectedObjects
            ; current boundary
            box = alnGetObjectBBox(oItem)
            leftX = xCoord(car(box))
            rightX = xCoord(cadr(box))
            deltaX = leftX - prevX - step

            ; curent location
            currX = xCoord(oItem->xy)
            ; destination location (grided)
            destX = xCoord(alnGriddedPoint(list( (currX - deltaX) 0 ) grids))
            deltaPoint = list( (destX - currX) 0 )
            alnMoveObject(oItem deltaPoint)
            prevX = prevX + step + (rightX - leftX)
        )
    );end-let
);end-fun

defun( alnOnDistributeV ()
    axlMsgPut("Distribute vertically")
    ; v1.15: 同上, 排序移到 Calc 执行时
    if( _alnFormData->useGap
        then _alnHandler = 'alnDoCalcStepBetweenBoundaryV
        else _alnHandler = 'alnDoCalcStepV
    )
    axlFinishEnterFun()
);end-fun
defun( alnDoCalcStepV ()
    let( (botY topY step grids)
when( (axlIsDebug) axlMsgPut("alnDoCalcStepV"))
        _alnSelectedObjects = alnOrderByY(_alnSelectedObjects)    ; v1.15: 执行时排序
        if( !_alnFormData->useStepV then
            ; calculate step
            botY = yCoord(alnGetObjectLocation(car(_alnSelectedObjects)))
            topY = yCoord(alnGetObjectLocation(car(last(_alnSelectedObjects))))
            step = (topY-botY)/(length(_alnSelectedObjects)-1)
            ; snap step to grid (depending from _alnFormData->snapToGrid)
            grids = alnGetCurrentGrid(_alnSelectedObjects)
            step = yCoord(alnGriddedPoint( list( 0 step) grids))
            ; update form
            _alnFormData->stepV = step
            (axlFormSetField _alnFormPtr "fStepV" step)
        )
        axlDBCloak( 'alnDoDistributeV() 'shape )
    );end-let
);end-fun
defun( alnDoDistributeV ()
    let( (i step pointY deltaY deltaPoint grids)
when( (axlIsDebug) axlMsgPut("alnDoDistributeV"))
        grids = alnGetCurrentGrid(_alnSelectedObjects)
        i = yCoord(alnGriddedPoint(alnGetObjectLocation(car(_alnSelectedObjects)) grids))
        step = _alnFormData->stepV
        foreach( oItem _alnSelectedObjects
            pointY = yCoord(alnGetObjectLocation(oItem))
            deltaY = i - pointY
            deltaPoint = list( 0 deltaY )
            alnMoveObject( oItem deltaPoint)
            i = i + step
        )
    );end-let
);end-fun

defun( alnDoCalcStepBetweenBoundaryV ()
    let( (bottomY prevY box lBox gap step grids)
when( (axlIsDebug) axlMsgPut("alnDoCalcStepBetweenBoundaryV"))
        _alnSelectedObjects = alnOrderByY(_alnSelectedObjects)    ; v1.15: 执行时排序
        if( !_alnFormData->useStepV then
            gap = 0.0
            ; get left boundary for first object
            prevY = yCoord(car(alnGetObjectBBox(car(_alnSelectedObjects))))
            ; calculate common gap
            lBox = alnGetBBoxes(_alnSelectedObjects)
            foreach( box lBox
                ; get left boundary
                bottomY = yCoord(car(box))
                gap = gap + bottomY - prevY
                ; get right boundary for next iteration
                prevY = yCoord(cadr(box))
            )
            ; calculate step
            step = gap/(length(_alnSelectedObjects)-1)
            ; snap step to grid
            grids = alnGetCurrentGrid(_alnSelectedObjects)
            step = yCoord(alnGriddedPoint( list( 0 step) grids))
            _alnFormData->stepV = step
            ; update form
            (axlFormSetField _alnFormPtr "fStepV" step)
        )
        axlDBCloak( 'alnDoDistributeGapBetweenBoundaryV() 'shape )
    );end-let
);end-fun
defun( alnDoDistributeGapBetweenBoundaryV ()
    let( (step prevY oItem box bottomY topY deltaY currY destY deltaPoint grids)
when( (axlIsDebug) axlMsgPut("alnDoDistributeGapBetweenBoundaryH"))
        step = _alnFormData->stepV
        ; get bottom boundary for first object
        prevY = yCoord(car(alnGetObjectBBox(car(_alnSelectedObjects)))) - step
        grids = alnGetCurrentGrid(_alnSelectedObjects)
        foreach( oItem _alnSelectedObjects
            ; current boundary
            box = alnGetObjectBBox(oItem)
            bottomY = yCoord(car(box))
            topY = yCoord(cadr(box))
            deltaY = bottomY - prevY - step

            ; curent location
            currY = yCoord(oItem->xy)
            ; destination location (grided)
            destY = yCoord(alnGriddedPoint(list( 0 (currY - deltaY) ) grids))
            deltaPoint = list( 0 (destY - currY) )
            alnMoveObject( oItem deltaPoint )
            prevY = prevY + step + (topY - bottomY)
        )
    );end-let
);end-fun

; -------------------- Pick -------------------------------------
defun( alnOnPickH ()
    axlMsgPut("Pick horizontally")
    axlFinishEnterFun()
    _alnHandler = 'alnDoPickH
);end-fun
defun( alnDoPickH ()
    let( (fixedObject fixedPoint fixedPointY grids)
        fixedPoint = nil
        if( _alnFormData->usePickH
        then
            fixedPointY = _alnFormData->pickH
        else
            fixedPoint = axlEnterPoint(?prompts "Select an object or point")
            if( fixedPoint then ;nil if pressed Oops
                axlSingleSelectPoint(fixedPoint)
                fixedObject = axlGetSelSet()
                if( fixedObject
                then
                    fixedPointY = yCoord(alnGetObjectLocation(car(fixedObject)))
                else
                    fixedPointY = yCoord(fixedPoint)
                )
            )
        )
        if( fixedPointY then ; nil if pressed Oops
            ; snap to grid (depend on _alnFormData->snapToGrid)
            grids = alnGetCurrentGrid(_alnSelectedObjects)
            fixedPointY = yCoord(alnGriddedPoint( list( 0 fixedPointY) grids))
            _alnFormData->pickH = fixedPointY
            axlFormSetField(_alnFormPtr "fPickH" fixedPointY)
            ; move objects
            axlDBCloak( 'alnMoveToHorizontal(fixedPointY) 'shape )
        )
    );end-let
);end-fun

defun( alnOnPickV ()
    axlMsgPut("Pick horizontally")
    axlFinishEnterFun()
    _alnHandler = 'alnDoPickV
);end-fun
defun( alnDoPickV ()
    let( (fixedObject fixedPoint fixedPointX grids)
        fixedPoint = nil
        if( _alnFormData->usePickV
        then
            fixedPointX = _alnFormData->pickV
        else
            fixedPoint = axlEnterPoint(?prompts "Select an object or point")
            if( fixedPoint then ;nil if pressed Oops
                axlSingleSelectPoint(fixedPoint)
                fixedObject = axlGetSelSet()
                if( fixedObject
                then
                    fixedPointX = xCoord(alnGetObjectLocation(car(fixedObject)))
                else
                    fixedPointX = xCoord(fixedPoint)
                )
            )
        )
        if( fixedPointX then ; nil if pressed Oops
            grids = alnGetCurrentGrid(_alnSelectedObjects)
            fixedPointX = xCoord(alnGriddedPoint( list( fixedPointX 0) grids))
            _alnFormData->pickV = fixedPointX
            axlFormSetField(_alnFormPtr "fPickV" fixedPointX)
            axlDBCloak( 'alnMoveToVertical(fixedPointX) 'shape )
        )
    );end-let
);end-fun



; -------------------- 工具函数（原 align_utils.il 内容，已合并） --------------------

;
; Get the point snapped to the nearest grid (if snapToGrid mode is true).
;
defun( alnGriddedPoint (point grids)
    let( (xOrigin yOrigin xMajor yMajor pointX pointY)
when( (axlIsDebug) printf("alnGriddedPoint\n"))
        pointX = xCoord(point)
        pointY = yCoord(point)
        when( (axlVersion('version) >= 15.7) ; since 15.7
            if( _alnFormData->snapToGrid then
                xMajor = grids->xMajor
                yMajor = grids->yMajor
                xOrigin = grids->xOrigin
                yOrigin = grids->yOrigin

                ; 先减栅格原点再取整，原点非 0 时才不会系统性偏移
                pointX = round((pointX-xOrigin)/xMajor)*xMajor + xOrigin
                pointY = round((pointY-yOrigin)/yMajor)*yMajor + yOrigin
            )
        )
        list(pointX pointY) ;return
    )
);defun

;
; Get the current grid.
;
defun( alnGetCurrentGrid (selectedObjects)
    prog( (grids isMirrored)
        when( (axlVersion('version) >= 15.7) ; since 15.7
            case( car(selectedObjects)->objType
                ( ("group" "symbol" "pin" "via") ; use etch grid
                    isMirrored = car(selectedObjects)->isMirrored
                    foreach( item _alnSelectedObjects
                        if( isMirrored == item->isMirrored
                        then isMirrored = item->isMirrored
                        else return(axlDBGridGet(axlConductorTopLayer())) ;both layers, use TOP
                        )
                    )
                    if( isMirrored
                    then return(axlDBGridGet(axlConductorBottomLayer())) ; mirrored, use BOT
                    else return(axlDBGridGet(axlConductorTopLayer()))    ; non mirrores, use TOP
                    )
                )
                ( "text"    ;use non-etch grid
                    grids = axlDBGridGet("non-etch")
                )
            )
        )
        return(grids)
    )
);defun

;
; Get maximum X coordinate from list of objects
;
defun( alnMaxX (lObjects)
    let( (obj pointX result)
        result = -1000000.0
        foreach( obj lObjects
            pointX = xCoord(alnGetObjectLocation(obj))
            result = max(pointX result)
        )
        result
    )
);defun

;
; Get minimum X coordinate from list of objects
;
defun( alnMinX (lObjects)
    let( (obj pointX result)
        result = 1000000.0
        foreach( obj lObjects
            pointX = xCoord(alnGetObjectLocation(obj))
            result = min(pointX result)
        )
        result
    )
);defun

;
; Get maximum Y coordinate from list of objects
;
defun( alnMaxY (lObjects)
    let( (obj pointY result)
        result = -1000000.0
        foreach( obj lObjects
            pointY = yCoord(alnGetObjectLocation(obj))
            result = max(pointY result)
        )
        result
    )
);defun

;
; Get minimum Y coordinate from list of objects
;
defun( alnMinY (lObjects)
    let( (obj pointY result)
        result = 1000000.0
        foreach( obj lObjects
            pointY = yCoord(alnGetObjectLocation(obj))
            result = min(pointY result)
        )
        result
    )
);defun

;
; Sort list of objects by X coordinate, ascending order.
;
defun( alnOrderByX (objectList)
    sort( objectList 'alnComparePositionX )
);defun
defun( alnComparePositionX ( obj1 obj2 )
    let( ( pt1x pt2x pt1y pt2y pt1 pt2 result)
        pt1 = alnGetObjectLocation(obj1)
        pt2 = alnGetObjectLocation(obj2)
        pt1x = xCoord( pt1 )
        pt2x = xCoord( pt2 )
        if( (pt1x < pt2x)
            then result = t
            else
                if( (pt1x == pt2x)
                    then
                        ; aditionaly compare by Y
                        pt1y = yCoord( pt1 )
                        pt2y = yCoord( pt2 )
                        if( (pt1y < pt2y)
                            then result = t
                            else result = nil
                        )
                    else result = nil
                )
        )
        result
    ) ; let
) ; defun

;
; Sort list of objects by Y coordinate, ascending order.
;
defun( alnOrderByY (objectList)
    sort( objectList 'alnComparePositionY )
) ;defun
defun( alnComparePositionY ( obj1 obj2 )
    let( ( pt1x pt2x pt1y pt2y pt1 pt2 result)
        pt1 = alnGetObjectLocation(obj1)
        pt2 = alnGetObjectLocation(obj2)
        pt1y = yCoord( pt1 )
        pt2y = yCoord( pt2 )
        if( (pt1y < pt2y)
            then result = t
            else
                if( (pt1y == pt2y)
                    then
                        ; aditionaly compare by X
                        pt1x = xCoord( pt1 )
                        pt2x = xCoord( pt2 )
                        if( (pt1x < pt2x)
                            then result = t
                            else result = nil
                        )
                    else result = nil
                )
        )
        result
    ) ; let
) ; defun

;
; Get object location point according to selected mode (Origin, Body Center, Pin)
;
defun( alnGetObjectLocation (object)
    let( (result message)
        case( _alnFormData->snapPoint
            ( "origin" result = axlDBAltOrigin('origin object) )
            ( "center" result = axlDBAltOrigin('center object) )
            ( "pin" 
                result = alnGetPinLocation(object _alnFormData->snapPinNumber)
                when( !result 
                    message = strcat("WARNING: Pin '", _alnFormData->snapPinNumber, "' not found")
                    if( object->refdes 
                        then message = strcat(message, " for symbol '", object->refdes, "', got body center.")
                        else message = strcat(message, ", got body center.")
                    )
                    axlMsgPut(message)
                    result = axlDBAltOrigin('center object)
                )
            )
        );case
        result
    ) ; let
) ; defun+

;
; Get location for given object's pin
; Return nil if pin not found.
defun( alnGetPinLocation (object pinNumber)
    let( (result number pinList)
        pinNumber = upperCase(pinNumber)
        pinList = object->pins
        foreach( pin pinList
            number = pin->number
            number = upperCase(number)
            when( pinNumber == number result = pin->xy)            
        )
        result
    ) ; let
) ; defun

;
; Get object boundary box.
; First trying get Dfa_Bound_Top(Bottom)
; if Dfa not present trying Place_Bound_Top(Bottom)
; if Place not present get bBox property.
;
defun( alnGetObjectBBox (object)
    let( ( objectChildren child dfaLayer placeLayer result)
        if(object->isMirrored
            then dfaLayer = "PACKAGE GEOMETRY/DFA_BOUND_BOTTOM" placeLayer = "PACKAGE GEOMETRY/PLACE_BOUND_BOTTOM"
            else dfaLayer = "PACKAGE GEOMETRY/DFA_BOUND_TOP" placeLayer = "PACKAGE GEOMETRY/PLACE_BOUND_TOP"
        )
        objectChildren = object->children
        ; only Symbols have objectChildren
        if(objectChildren then
            ; find Dfa_Bound_ shape
            foreach( child objectChildren
                if((child->objType == "shape" && child->layer == dfaLayer) then
                    result = child->bBox
                )
            )
            ; find Place_Bound_ shape
            if(!result then
                foreach( child objectChildren
                    if((child->objType == "shape" && child->layer == placeLayer) then
                        result = child->bBox
                    )
                )
            )
        )
        if(!result then result = object->bBox)
        result
    ) ; let
) ; defun

;
; Get objects boundary boxes.
; Return list of boxes.
;
defun( alnGetBBoxes (objectList)
    let( ( object result)
        foreach( object objectList
            result = tconc(result alnGetObjectBBox(object))
        )
        car(result) ; get list from "tconc" list
    ) ; let
) ; defun

;
; Get minimal X boundary box coordinate for given BBoxes.
;
defun( alnGetMinBBoxX (boxList)
    let( ( pointX box result)
        result = 1000000.0
        foreach( box boxList
            pointX = xCoord(car(box))
            result = min(pointX result)
        )
        result
    ) ; let
) ; defun

;
; Get maximal X boundary box coordinate for given BBoxes.
;
defun( alnGetMaxBBoxX (boxList)
    let( ( pointX box result)
        result = -1000000.0
        foreach( box boxList
            pointX = xCoord(cadr(box))
            result = max(pointX result)
        )
        result
    ) ; let
) ; defun

;
; Get minimal Y boundary box coordinate for given BBoxes.
;
defun( alnGetMinBBoxY (boxList)
    let( ( pointY box result)
        result = 1000000.0
        foreach( box boxList
            pointY = yCoord(car(box))
            result = min(pointY result)
        )
        result
    ) ; let
) ; defun

;
; Get maximal Y boundary box coordinate for given BBoxes.
;
defun( alnGetMaxBBoxY (boxList)
    let( ( pointY box result)
        result = -1000000.0
        foreach( box boxList
            pointY = yCoord(cadr(box))
            result = max(pointY result)
        )
        result
    ) ; let
) ; defun

defun( alnRefreshIDs (objectList)
    let( ( object newId resultList)
        foreach( object objectList
            newId = axlDBRefreshId(object)
            ; v1.9: 回滚/变换后被删对象刷新出 dbid:removed, 必须丢弃,
            ; 否则下游 AddSelect 报警告、min/max 链崩溃
            when( and( newId
                       not(rexMatchp("removed" sprintf(nil "%L" newId))) )
                resultList = tconc(resultList newId)
            )
        )
        car(resultList) ; get list from "tconc" list
    ) ; let
) ; defun

;
; Check for object have "Fixed" property. If it's true, remove this object from selection.
; Return list without fixed objects.
;
defun( alnCheckForFixedObjects (objectList)
    let( ( x prop object resultList)
        foreach( object objectList
            if( axlDBIsFixed(object nil)
                ; remove from selection
                then axlSubSelectObject(object)
                ; place to returned list
                else resultList = tconc(resultList object)
            )
        )
        car(resultList) ; get list from "tconc" list
    ) ; let
) ; defun

;
; Move object to provided distance.
; Analise useStretch and useRipup settings and respectively move/ripup connected to object CLines.
;
defun( alnMoveObject (object deltaPoint) ; object = car(_alnSelectedObjects) deltaPoint = list(10.0 -10.0) alnMoveObject(object deltaPoint)
    let( (segmentsToCreate segmentsToRemove pinList pin pinXY paths isVia
            path segments segment startEnd newStartEnd segmentToCreate x1 y1 x2 y2 net
            width layer netname rr ubObjType ubRefdes ubName ubText ubXY)
        if( (car(deltaPoint) != 0.0 || cadr(deltaPoint) != 0.0) then
            if( (_alnFormData->useStretch || _alnFormData->useRipup) then
                ;get list of pins
                pinList = object->pins
                if( object->objType == "via" then 
                    isVia = t
                    pinList = list(object) ; hack for vias
                ) 
                ; get CLines for each pin
                foreach( pin pinList
                    pinXY = pin->xy
                    ; get paths connected to pin
                    paths = axlDBGetConnect(pin nil)
                    ; get segments for each path
                    foreach( path paths
                        segments = path->segments
                        ; find segment which connected to pin (points are equal)
                        foreach( segment segments
                            startEnd = segment->startEnd
                            newStartEnd = nil
                            if( car(startEnd) == pinXY
                            then
                                ; calculate new segment points
                                x1 = xCoord(car(startEnd)) + xCoord(deltaPoint)
                                y1 = yCoord(car(startEnd)) + yCoord(deltaPoint)
                                x2 = xCoord(cadr(startEnd))
                                y2 = yCoord(cadr(startEnd))
                                newStartEnd = list( x1:y1 x2:y2 )
                            else
                                if( cadr(startEnd) == pinXY
                                then
                                    ; calculate new segment points
                                    x1 = xCoord(car(startEnd))
                                    y1 = yCoord(car(startEnd))
                                    x2 = xCoord(cadr(startEnd)) + xCoord(deltaPoint)
                                    y2 = yCoord(cadr(startEnd)) + yCoord(deltaPoint)
                                    newStartEnd = list( x1:y1 x2:y2 )
                                )
                            );if
                            if(newStartEnd then
                                segmentsToRemove = cons(segment segmentsToRemove)
                                segmentToCreate = ncons(t)
                                segmentToCreate->startEnd = newStartEnd
                                segmentToCreate->width = segment->width
                                segmentToCreate->layer = segment->layer
                                segmentToCreate->netname = (segment->net)->name
                                segmentsToCreate = cons(segmentToCreate segmentsToCreate)
                                ; v1.5: 记录被删线段定位信息（撤销=按端点/宽度/层/网络重建）
                                alnUndoRecord(list("segdel" segment->startEnd
                                    segment->width segment->layer
                                    segmentToCreate->netname))
                            );if(newStartEnd
                        );foreach( segment segments
                    );foreach( path paths
                );foreach( pin pinList
                ; remove old segments
                if( segmentsToRemove then
                    foreach(segment segmentsToRemove
                        axlDeleteObject(segment)
                    )
                )
            );if(_alnFormData->useStretch
            ; v1.5: 移动前抓取对象标识（transform 后 dbid 可能失效，提前取好）
            ubObjType = object->objType
            rr = errset( object->refdes nil )
            ubRefdes = and(rr car(rr))
            rr = errset( object->name nil )
            ubName = and(rr car(rr))
            rr = errset( object->text nil )
            ubText = and(rr car(rr))
            rr = errset( object->xy nil )
            ubXY = and(rr car(rr))
            ;move object
            axlTransformObject( object ?move deltaPoint )
            ; v1.5: 记录移动原语（xyAfter 为算术推算，撤销时按 -delta 移回）
            alnUndoRecordMove(ubObjType ubRefdes ubName ubText ubXY deltaPoint)
            when( isVia
                ; restore net（无走线连接时 segmentsToCreate 为 nil，需判空）
                when( segmentsToCreate
                    net = car(segmentsToCreate)->netname
                )
                when( net axlDBAssignNet(object net) )

            )
            ; create new segments
            if( (segmentsToCreate && _alnFormData->useStretch) then
                foreach(segment segmentsToCreate
                    startEnd = segment->startEnd
                    width = segment->width
                    layer = segment->layer
                    netname = segment->netname
                    axlDBCreateLine( startEnd width layer netname nil)
                    ; v1.5: 记录新建线段定位信息（撤销=按端点匹配查找并删除）
                    alnUndoRecord(list("segnew" startEnd width layer netname))
                )
            )
        );if( (car(deltaPoint)
        t ;return
    ) ; let
) ; defun

procedure( ASTB_Place_Align()
  aln()
)

; -------------------- Done 撤销（v1.5 新增） --------------------
; 批次栈 _ALN_undoBatches：每次 Done 压一批，逐批撤销；批内为 cons 逆序
; 的原语记录（最新在前），撤销时顺序遍历即天然按操作逆序执行：
;   删拉伸新线 -> 对象移回 -> 重建被删线段
; 原语只存定位信息，不存 dbid（跨命令失效成 dbid:removed）：
;   ("move"   objType refdes name text xyAfter delta)  移动：symbol 按
;           refdes 全库找，其余按 xyAfter 点选，找到后按 -delta 移回
;   ("segnew" startEnd width layer netname)            拉伸新建线段：撤销=
;           按中点点选 + 端点匹配找到该段并删除
;   ("segdel" startEnd width layer netname)            拉伸/挖掉移除的线段：
;           撤销=按原参数重建

defun( alnUndoRecord (rec)
    when( boundp('_alnUndoBatch)
        _alnUndoBatch = cons(rec _alnUndoBatch)
    )
);end-defun

defun( alnUndoRecordMove (objType refdes name txt xyBefore deltaPoint)
    prog( (xyAfter)
        xyAfter = nil
        when( xyBefore
            ; dbid 移动后可能失效，xyAfter 用算术推算（旧原点 + 位移）
            xyAfter = list( xCoord(xyBefore) + xCoord(deltaPoint)
                            yCoord(xyBefore) + yCoord(deltaPoint) )
        )
        alnUndoRecord(list("move" objType refdes name txt xyAfter deltaPoint))
        return(t)
    )
);end-defun

;
; 坐标匹配容差：取 2 个数据库精度单位（线段写库时会吸附到精度网格）
;
defun( alnUndoTol ()
    prog( (rr)
        rr = errset( cadr(axlDBGetDesignUnits()) nil )
        if( and(rr car(rr))
            then return( 2.0 / expt(10 car(rr)) )
            else return( 0.01 )
        )
    )
);end-defun

;
; 两段是否同一条（端点分别近似相等，允许端点顺序颠倒）
;
defun( alnUndoSameSeg (se1 se2 tol)
    prog( (d1 d2)
        d1 = abs(xCoord(car(se1)) - xCoord(car(se2))) + abs(yCoord(car(se1)) - yCoord(car(se2)))
        d2 = abs(xCoord(cadr(se1)) - xCoord(cadr(se2))) + abs(yCoord(cadr(se1)) - yCoord(cadr(se2)))
        if( and(d1 < tol d2 < tol) then
            return(t)
        else
            d1 = abs(xCoord(car(se1)) - xCoord(cadr(se2))) + abs(yCoord(car(se1)) - yCoord(cadr(se2)))
            d2 = abs(xCoord(cadr(se1)) - xCoord(car(se2))) + abs(yCoord(cadr(se1)) - yCoord(car(se2)))
            return( and(d1 < tol d2 < tol) )
        )
    )
);end-defun

;
; 撤销时按定位信息现场查找移动对象（新鲜 dbid，不依赖存储 dbid）
;
defun( alnUndoFindObject (objType refdes name txt xyAfter)
    prog( (obj s rr)
        obj = nil
        if( refdes then
            ; symbol：按 refdes 全库查找（不依赖坐标）
            foreach( s axlDBGetDesign()->symbols
                when( and(null(obj) equal(s->refdes refdes))
                    obj = s
                )
            )
        else
            ; 其余类型：按记录坐标现场点选，再按类型/名称过滤
            when( xyAfter
                axlClearSelSet()
                axlSetFindFilter(?enabled '("noall" "symbols" "vias" "text" "pins" "groups")
                    ?onButtons '("noall" "symbols" "vias" "text" "pins" "groups"))
                rr = errset( axlSingleSelectPoint(xyAfter) nil )
                when( and(rr car(rr))
                    foreach( s axlGetSelSet()
                        when( and(null(obj) equal(s->objType objType))
                            if( equal(objType "via") then
                                rr = errset( s->name nil )
                                when( and(rr car(rr) name equal(car(rr) name))
                                    obj = s
                                )
                            else
                                if( equal(objType "text") then
                                    rr = errset( s->text nil )
                                    when( and(rr car(rr) txt equal(car(rr) txt))
                                        obj = s
                                    )
                                else
                                    obj = s
                                )
                            )
                        )
                    )
                )
            )
        )
        return(obj)
    )
);end-defun

; v1.16: 选择集身份快照——(objType refdes name text xy), 全部 errset 防护
defun( _ALN_CaptureIds (objList)
    let( (o rr typ refdes name txt xy out)
        out = nil
        foreach( o objList
            rr = errset(typ = o->objType)  unless( and(rr typ) typ = nil )
            refdes = nil name = nil txt = nil xy = nil
            rr = errset(refdes = o->refdes) unless( and(rr refdes) refdes = nil )
            rr = errset(name = o->name)     unless( and(rr name) name = nil )
            rr = errset(txt = o->text)      unless( and(rr txt) txt = nil )
            rr = errset(xy = o->xy)         unless( and(rr xy) xy = nil )
            when( typ
                ; v1.17: 修双重包装(原 list(list(...)) 使 nth(0 id) 拿到整表)
                out = append1(out list(typ refdes name txt xy))
            )
        )
        out
    )
);end-defun

; v1.16: 身份与本操作撤销记录匹配(symbol 按 refdes; via/text 按
; 类型+名称+记录反推的移动前坐标容差匹配)
defun( _ALN_IdMatchRec (id rec tol)
    let( (preX preY dx dy)
        if( nth(1 id) then
            equal(nth(2 rec) nth(1 id))
        else
            and( equal(nth(1 rec) nth(0 id))
                 equal(nth(3 rec) nth(2 id))
                 nth(4 id) nth(5 rec) nth(6 rec)
                 progn(
                     dx = xCoord(nth(6 rec)) dy = yCoord(nth(6 rec))
                     preX = xCoord(nth(5 rec)) - dx
                     preY = yCoord(nth(5 rec)) - dy
                     and( abs(preX - xCoord(nth(4 id))) < tol
                          abs(preY - yCoord(nth(4 id))) < tol )
                 )
            )
        )
    )
);end-defun

; v1.16: 按身份重找新鲜 dbid(本操作记录提供移动后坐标 xyAfter)
defun( _ALN_ReselectByIds (ids preBatch)
    let( (rest thisOps id rec xyFind obj out tol)
        tol = alnUndoTol()
        thisOps = nil
        rest = _alnUndoBatch
        while( and( rest not(equal(rest preBatch)) )
            thisOps = cons(car(rest) thisOps)
            rest = cdr(rest)
        )
        out = nil
        foreach( id ids
            xyFind = nth(4 id)
            foreach( rec thisOps
                when( _ALN_IdMatchRec(id rec tol)
                    xyFind = nth(5 rec)
                )
            )
            obj = alnUndoFindObject(nth(0 id) nth(1 id) nth(2 id) nth(3 id) xyFind)
            when( obj out = append1(out obj) )
        )
        out
    )
);end-defun

; v1.18: 两身份是否同对象(symbol 按 refdes; 其余按 类型+名称+文本+坐标容差)
defun( _ALN_IdSame (a b tol)
    if( nth(1 a) then
        and( nth(1 b) equal(nth(1 a) nth(1 b)) )
    else
        and( equal(nth(0 a) nth(0 b))
             equal(nth(2 a) nth(2 b))
             equal(nth(3 a) nth(3 b))
             nth(4 a) nth(4 b)
             abs(xCoord(nth(4 a)) - xCoord(nth(4 b))) < tol
             abs(yCoord(nth(4 a)) - yCoord(nth(4 b))) < tol
        )
    )
);end-defun

; v1.18: 并入新身份(同对象以新鲜项覆盖旧项, 保持顺序)
defun( _ALN_MergeIds (oldIds newIds)
    let( (n o keep tol)
        tol = alnUndoTol()
        foreach( n newIds
            keep = nil
            foreach( o oldIds
                unless( _ALN_IdSame(o n tol)
                    keep = append1(keep o)
                )
            )
            oldIds = append1(keep n)
        )
        oldIds
    )
);end-defun

; v1.18: 身份集现场解析为新鲜 dbid(仅供当轮使用, 跨轮必死)
defun( _ALN_ResolveIds (ids)
    let( (id obj out)
        out = nil
        foreach( id ids
            obj = alnUndoFindObject(nth(0 id) nth(1 id) nth(2 id) nth(3 id) nth(4 id))
            when( obj out = append1(out obj) )
        )
        out
    )
);end-defun

; v1.19: Oops 后身份坐标同步回滚(xy = xyAfter - delta)
defun( _ALN_RollbackIdsXy (ids recs)
    let( (id rec tol out xyNew)
        tol = alnUndoTol()
        out = nil
        foreach( id ids
            xyNew = nth(4 id)
            foreach( rec recs
                when( and( _ALN_IdMatchRec(id rec tol) nth(5 rec) nth(6 rec) )
                    xyNew = list( xCoord(nth(5 rec)) - xCoord(nth(6 rec))
                                  yCoord(nth(5 rec)) - yCoord(nth(6 rec)) )
                )
            )
            out = append1(out list(nth(0 id) nth(1 id) nth(2 id) nth(3 id) xyNew))
        )
        out
    )
);end-defun

; v1.18: 操作后用撤销记录(xyAfter)更新身份坐标
defun( _ALN_UpdateIdsXy (ids preBatch)
    let( (rest thisOps id rec tol out xyNew)
        tol = alnUndoTol()
        thisOps = nil
        rest = _alnUndoBatch
        while( and( rest not(equal(rest preBatch)) )
            thisOps = cons(car(rest) thisOps)
            rest = cdr(rest)
        )
        out = nil
        foreach( id ids
            xyNew = nth(4 id)
            foreach( rec thisOps
                when( _ALN_IdMatchRec(id rec tol)
                    xyNew = nth(5 rec)
                )
            )
            out = append1(out list(nth(0 id) nth(1 id) nth(2 id) nth(3 id) xyNew))
        )
        out
    )
);end-defun

defun( alnUndoMoveBack (rec)
    prog( (obj negDelta rr)
        obj = alnUndoFindObject(cadr(rec) caddr(rec) cadddr(rec) nth(4 rec) nth(5 rec))
        unless( obj
            axlUIWPrint(nil "  \276\257\270\346: \316\264\325\322\265\275\322\306\266\257\266\324\317\363(type=%s), \314\370\271\375\322\306\273\330" cadr(rec))
            return(nil)
        )
        negDelta = list( minus(xCoord(nth(6 rec))) minus(yCoord(nth(6 rec))) )
        rr = errset( axlTransformObject(obj ?move negDelta) t )
        return( and(rr car(rr)) )
    )
);end-defun

;
; 撤销 segnew：按中点点选 cline，段内端点近似匹配后删除该段
; （找不到视为已被后续操作删除/合并，目标已达，返回 t）
;
defun( alnUndoDeleteSeg (rec)
    prog( (startEnd layer mid tol rr found cl seg)
        startEnd = cadr(rec)
        layer    = cadddr(rec)
        mid = list( (xCoord(car(startEnd)) + xCoord(cadr(startEnd))) / 2.0
                    (yCoord(car(startEnd)) + yCoord(cadr(startEnd))) / 2.0 )
        tol = alnUndoTol()
        axlClearSelSet()
        axlSetFindFilter(?enabled '("noall" "clines") ?onButtons '("noall" "clines"))
        found = nil
        rr = errset( axlSingleSelectPoint(mid) nil )
        when( and(rr car(rr))
            foreach( cl axlGetSelSet()
                unless( found
                    foreach( seg cl->segments
                        when( and(null(found) equal(seg->layer layer)
                                  alnUndoSameSeg(seg->startEnd startEnd tol))
                            found = seg
                        )
                    )
                )
            )
        )
        if( found then
            rr = errset( axlDeleteObject(found) t )
            return( and(rr car(rr)) )
        else
            return(t)
        )
    )
);end-defun

;
; 撤销 segdel：按记录的端点/宽度/层/网络重建被删线段
;
defun( alnUndoRecreateSeg (rec)
    prog( (rr)
        ; axlDBCreateLine 返回 ((dbid...) drc)，caar 取到 dbid 才算成功
        rr = errset( axlDBCreateLine(cadr(rec) caddr(rec) cadddr(rec) nth(4 rec) nil) t )
        return( and(rr car(rr) caar(rr)) )
    )
);end-defun

;------------------------------------------------------------------------
; 函数    : ALN_Undo
; 功能    : 撤销最近一次 Done 提交的那一批对齐/分布修改（命令
;           ASTB_Place_Alignu）。模式与 RVIA_Undo 相同：批次栈只存
;           定位信息，撤销时现场 axlSingleSelectPoint/全库查找拿到
;           新鲜 dbid 再操作；栈为空时提示。
;------------------------------------------------------------------------
procedure( ALN_Undo()
    prog( (batch rec ok nMove nSeg nFail)
        unless( boundp('_ALN_undoBatches) && _ALN_undoBatches
            axlUIWPrint(nil "\303\273\323\320\277\311\263\267\317\372\265\304\274\307\302\274")
            return(nil)
        )
        batch = car(_ALN_undoBatches)
        _ALN_undoBatches = cdr(_ALN_undoBatches)
        nMove = 0
        nSeg = 0
        nFail = 0
        foreach( rec batch
            ok = nil
            case( car(rec)
                ( "move"   ok = alnUndoMoveBack(rec) )
                ( "segnew" ok = alnUndoDeleteSeg(rec) )
                ( "segdel" ok = alnUndoRecreateSeg(rec) )
            )
            if( ok then
                if( equal(car(rec) "move")
                    then nMove = nMove + 1
                    else nSeg = nSeg + 1
                )
            else
                nFail = nFail + 1
            )
        )
        axlClearSelSet()
        axlFlushDisplay()
        axlUIWPrint(nil "\263\267\317\372\315\352\263\311: \322\306\273\330 %d \270\366\266\324\317\363, \273\326\270\264 %d \266\316\327\337\317\337, %d \317\356\312\247\260\334"
            nMove nSeg nFail)
        return(t)
    )
)

ASTB_RegisterCommand("ASTB_Place_Align" "ASTB_Place_Align" ?cmdType "interactive")
; v1.5: Done 后撤销命令（主命令名+u；general 类型，随时可用）
ASTB_RegisterCommand("ASTB_Place_Alignu" "ALN_Undo" ?cmdType "general" ?undo nil)
; 统一撤销中枢注册（core/trans.il v1.4）：astbundo 按 LIFO 分发到本函数
ASTB_RegisterUndo("place_align" 'ALN_Undo)

printf("[ASTB] place_align.il loaded.\n")
