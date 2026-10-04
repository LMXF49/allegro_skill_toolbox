;========================================================================
; 文件名    : util_layerview.il
; 作者      : SkillGroup / ASTB 项目组(整合)
; 创建日期  : 2026-07-17
; 版本      : 2.3
; 功能描述  : 切层与视图管理模块, 提供活动层切换和预设视图功能
;             切层支持: 输入单个层号切层, 输入多个层号(如"1 2 3")显示多层,
;             输入"a"打开所有走线层, 输入"b"切换到底层
;             相邻层切换: qu 上一层, qd 下一层(循环, 顶层的上一层是底层,
;             底层的下一层是顶层)
;             预设视图: 丝印顶层/丝印底层/装配顶层/装配底层
;             命令: ql 切层, qu 上一层, qd 下一层,
;                  vst 丝印顶, vsb 丝印底, vat 装配顶, vab 装配底
; 依赖模块  : core/trans.il (ASTB_RegisterCommand, 可选; 独立加载时退化为
;             axlCmdRegister)
; 来源      : 整合自 G:/allegro/layer_view (v1.1), 纳入 ASTB 工具箱
; 修改记录  :
;   2026-07-17 v1.0 SkillGroup 初始创建
;   2026-07-17 v1.1 SkillGroup 切层支持多层号输入和"a"显示全部层
;   2026-07-18 v2.0 ASTB 项目组 整合入工具箱: 命令经 ASTB_RegisterCommand
;                注册并带冲突降级, 新增 ASTB_Util_* 菜单包装函数
;   2026-07-19 v2.1 ASTB 项目组 实机修复: 臆造 API axlGetLayerList 改为
;                axlGetParam("paramLayerGroup:Etch")->groupMembers,
;                axlSetCurrentLayer 改为 axlDBControl('activeLayer ...)
;                (实证见 pkg_createovalflash.il), axlVisibleLayer 参数
;                顺序修正为(层名 开关), axlUIRedraw 改 axlVisibleUpdate,
;                保留字 t 形参改名 tok
;   2026-07-19 v2.2 ASTB 项目组 实机修复: 层名 class 部分改用数据库内部
;                带空格形式(BOARD GEOMETRY/PACKAGE GEOMETRY/REF DES/
;                VIA CLASS), 修复丝印/装配视图仅 PIN 层生效的问题
;   2026-07-19 v2.3 ASTB 项目组 功能增强: 新增 qu/qd 上下层循环切换;
;                ql 的"a"改为只打开所有走线层(ETCH+PIN+VIA CLASS+板框),
;                新增"b"直接切到底层; 抽取 _LayerView_ShowSingleEtchLayer
; 编码      : GBK (含中文注释)
;========================================================================

;------------------------------------------------------------------------
; 全局变量初始化
;------------------------------------------------------------------------
unless(boundp('g_layerViewVersion)
    g_layerViewVersion = "2.3"
)

unless(boundp('g_layerViewEnabled)
    g_layerViewEnabled = t
)

;------------------------------------------------------------------------
; 模块常量
;------------------------------------------------------------------------
C_LAYER_VIEW_MODULE = "LayerView"

;------------------------------------------------------------------------
; 函数名  : _LayerView_RegisterCmd
; 功能    : 命令注册包装: 优先走 ASTB 框架注册, 框架不存在时退化为
;           axlCmdRegister(独立加载场景), 注册失败仅告警不中断
; 参数    :
;   @param cmdName - 命令名字符串
;   @param procSym - 目标函数 symbol
; 返回值  : t/nil
;------------------------------------------------------------------------
procedure( _LayerView_RegisterCmd(cmdName procSym)
    let((ret)
        if( fboundp('ASTB_RegisterCommand) then
            ; 框架内部已对注册失败做 LogWarn, 此处直接透传返回值
            ret = ASTB_RegisterCommand(cmdName procSym
                      ?cmdType "general" ?undo nil)
        else
            ret = errset(axlCmdRegister(cmdName procSym
                      ?cmdType "general") t)
            unless( ret
                printf("[%s][WARN] \303\374\301\356\327\242\262\341\312\247\260\334(\277\311\304\334\322\321\261\273\325\274\323\303): %s\n"
                       C_LAYER_VIEW_MODULE cmdName)
            )
        )
        ret
    )
)

;------------------------------------------------------------------------
; 函数名  : Init_LayerView
; 功能    : 模块初始化入口, 注册命令
; 参数    : 无
; 返回值  : t - 初始化成功
;------------------------------------------------------------------------
procedure( Init_LayerView()
    ; 注册命令快捷键(显示/查询类, 不修改数据库, cmdType 用 general)
    _LayerView_RegisterCmd("ql"  'LayerView_SwitchLayer)
    _LayerView_RegisterCmd("qu"  'LayerView_LayerUp)
    _LayerView_RegisterCmd("qd"  'LayerView_LayerDown)
    _LayerView_RegisterCmd("vst" 'LayerView_ViewSilkTop)
    _LayerView_RegisterCmd("vsb" 'LayerView_ViewSilkBottom)
    _LayerView_RegisterCmd("vat" 'LayerView_ViewAssyTop)
    _LayerView_RegisterCmd("vab" 'LayerView_ViewAssyBottom)

    printf("[%s] \304\243\277\351\263\365\312\274\273\257\315\352\263\311\243\254\260\346\261\276 %s\n"
           C_LAYER_VIEW_MODULE g_layerViewVersion)
    t
)

;------------------------------------------------------------------------
; 函数名  : LayerView_GetEtchLayers
; 功能    : 获取所有ETCH层名称列表("ETCH/TOP" ... "ETCH/BOTTOM"),
;           顺序即叠层物理顺序(groupMembers 自 TOP 至 BOTTOM)
; 参数    : 无
; 返回值  : list - ETCH层全名("CLASS/SUBCLASS")字符串列表
;           nil  - 当前设计无ETCH层
; 备注    : v2.1 用 axlGetParam 实现(手册实证方式, 同 02_etch_layerview)
;------------------------------------------------------------------------
procedure( LayerView_GetEtchLayers()
    let((param members)
        param = axlGetParam("paramLayerGroup:Etch")
        members = param->groupMembers
        if( null(members) then
            nil
        else
            mapcar(lambda((sc) sprintf(nil "ETCH/%s" sc)) members)
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : LayerView_GetSubclass
; 功能    : 从"CLASS/SUBCLASS"格式中提取SUBCLASS部分
; 参数    :
;   @param layerName - 层名称字符串，格式为"CLASS/SUBCLASS"
; 返回值  : string - SUBCLASS名称
;------------------------------------------------------------------------
procedure( LayerView_GetSubclass( layerName )
    cadr(parseString(layerName "/"))
)

;------------------------------------------------------------------------
; 函数名  : LayerView_ShowAllLayers
; 功能    : 显示所有图层并刷新显示
; 参数    : 无
; 返回值  : t - 操作成功
; 备注    : v2.1 改用 axlVisibleDesign(t) 整体显示 + axlVisibleUpdate
;------------------------------------------------------------------------
procedure( LayerView_ShowAllLayers()
    axlVisibleDesign(t)
    axlVisibleUpdate(t)
    t
)

;------------------------------------------------------------------------
; 函数名  : _LayerView_SetActiveLayer
; 功能    : 设置当前活动层(ministatus 显示), 失败仅告警不中断
;           (活动层设置是装饰性操作, 不影响视图切换主功能)
; 参数    :
;   @param layerName - 层全名, 格式"CLASS/SUBCLASS"(大小写不敏感)
; 返回值  : t/nil
; 备注    : v2.1 新增, 替代臆造的 axlSetCurrentLayer; 手册标注
;           axlSetActiveLayer 已废弃, 推荐 axlDBControl(实证写法见
;           pkg_createovalflash.il: axlDBControl('activeLayer "etch/top"))
;------------------------------------------------------------------------
procedure( _LayerView_SetActiveLayer( layerName )
    let((ret)
        ret = errset(axlDBControl('activeLayer layerName) t)
        unless( ret
            printf("[%s][WARN] \311\350\326\303\273\356\266\257\262\343\312\247\260\334(\272\366\302\324, \262\273\323\260\317\354\312\323\315\274): %s\n"
                   C_LAYER_VIEW_MODULE layerName)
        )
        ret
    )
)

;------------------------------------------------------------------------
; 函数名  : _LayerView_ShowSingleEtchLayer
; 功能    : 单层显示指定 ETCH 层: 隐藏全部后显示 板框+ETCH+PIN+VIA CLASS,
;           并把该层设为活动层
; 参数    :
;   @param targetLayer - ETCH 层全名(如 "ETCH/TOP")
; 返回值  : t
; 备注    : v2.3 抽取(ql 的 b 分支与 qu/qd 共用)
;------------------------------------------------------------------------
procedure( _LayerView_ShowSingleEtchLayer( targetLayer )
    let((showLayers subclassName)
        LayerView_HideAllLayers()
        subclassName = LayerView_GetSubclass(targetLayer)
        showLayers = list("BOARD GEOMETRY/OUTLINE"
                          targetLayer
                          sprintf(nil "PIN/%s" subclassName)
                          sprintf(nil "VIA CLASS/%s" subclassName))
        LayerView_ShowLayers(showLayers)
        _LayerView_SetActiveLayer(targetLayer)
        t
    )
)

;------------------------------------------------------------------------
; 函数名  : _LayerView_FindLayerIndex
; 功能    : 在 ETCH 层列表中按 subclass 名定位(大小写不敏感)
; 参数    :
;   @param etchLayers - ETCH 层全名列表
;   @param subclass   - 要查找的 subclass 名(如 "TOP")
; 返回值  : int  - 1-based 位置
;           nil  - 未找到
; 备注    : v2.3 新增
;------------------------------------------------------------------------
procedure( _LayerView_FindLayerIndex( etchLayers subclass )
    let((idx result upper)
        idx = 1
        result = nil
        upper = upperCase(subclass)
        foreach(l etchLayers
            when( null(result) &&
                  upperCase(LayerView_GetSubclass(l)) == upper
                result = idx
            )
            idx++
        )
        result
    )
)

;------------------------------------------------------------------------
; 函数名  : LayerView_CycleLayer
; 功能    : 相邻走线层循环切换(上一层/下一层):
;           顶层的上一层是底层, 底层的下一层是顶层;
;           切换后单层显示该层并设为活动层
; 参数    :
;   @param dir - 1 = 下一层(TOP->BOTTOM 方向), -1 = 上一层
; 返回值  : t/nil
; 备注    : v2.3 新增; 当前活动层不在 ETCH 时, qd 落到 TOP, qu 落到 BOTTOM
;------------------------------------------------------------------------
procedure( LayerView_CycleLayer( dir )
    prog((etchLayers curActive curSubclass idx total newIdx targetLayer)
        etchLayers = LayerView_GetEtchLayers()
        if( null(etchLayers) then
            axlUIConfirm("\265\261\307\260\311\350\274\306\326\320\303\273\323\320ETCH\262\343")
            return(nil)
        )
        total = length(etchLayers)

        ; 读取当前活动层(单参=读取, errset 保底)
        curActive = errset(axlDBControl('activeLayer) t)
        curSubclass = if( curActive && car(curActive)
                          then cadr(parseString(car(curActive) "/"))
                          else nil )

        ; 定位当前层在叠层中的位置(1-based)
        idx = if( curSubclass
                  then _LayerView_FindLayerIndex(etchLayers curSubclass)
                  else nil )
        unless( idx
            ; 活动层不在 ETCH: 让 +/-1 后分别落到 TOP/BOTTOM
            idx = if( dir == 1 then 0 else 1 )
        )

        ; 1-based 循环索引
        newIdx = mod(idx - 1 + dir + total total) + 1
        targetLayer = nth(newIdx - 1 etchLayers)

        _LayerView_ShowSingleEtchLayer(targetLayer)
        printf("[%s] \273\356\266\257\262\343: %s (%d/%d)\n"
               C_LAYER_VIEW_MODULE targetLayer newIdx total)
        t
    )
)

;------------------------------------------------------------------------
; 函数名  : LayerView_LayerUp / LayerView_LayerDown
; 功能    : qu/qd 命令入口: 切换到上一层/下一层走线层(循环)
; 参数    : 无
; 返回值  : t/nil
;------------------------------------------------------------------------
procedure( LayerView_LayerUp()
    LayerView_CycleLayer(-1)
)

procedure( LayerView_LayerDown()
    LayerView_CycleLayer(1)
)

;------------------------------------------------------------------------
; 函数名  : LayerView_SwitchLayer
; 功能    : 切换活动层与显示层 - 支持多种输入格式:
;           输入单个层号(如"1"): 切到该层为活动层，仅显示该层及关联层
;           输入多个层号(如"1 2 3"): 显示指定多层及关联层，活动层为首个
;           输入"a": 打开所有走线层(ETCH+PIN+VIA CLASS+板框)
;           输入"b": 切换到底层
; 参数    : 无(通过axlUIPrompt对话框获取用户输入)
; 返回值  : t   - 操作成功
;           nil - 操作失败或用户取消
;------------------------------------------------------------------------
procedure( LayerView_SwitchLayer()
    prog((input tokens etchLayers totalLayers layerNums
         validNums targetLayer showLayers subclassName
         activeLayer msgStr)
        ; 获取ETCH层列表
        etchLayers = LayerView_GetEtchLayers()
        totalLayers = length(etchLayers)

        if( null(etchLayers) then
            axlUIConfirm("\265\261\307\260\311\350\274\306\326\320\303\273\323\320ETCH\262\343")
            return(nil)
        )

        ; 弹出输入对话框
        input = axlUIPrompt(
            sprintf(nil "\312\344\310\353\262\343\272\305(1~%d, \277\325\270\361\267\326\270\364\266\340\262\343, a=\313\371\323\320\327\337\317\337\262\343, b=\265\327\262\343):"
                    totalLayers)
            "1"
        )

        ; 用户取消输入
        if( null(input) || input == "" then
            return(nil)
        )

        ; 去除前后空格
        input = buildString(parseString(input " "), " ")

        ; ========== 处理"a"输入: 打开所有走线层(v2.3 起不再全图显示) ==========
        if( lowerCase(input) == "a" then
            LayerView_HideAllLayers()
            showLayers = list("BOARD GEOMETRY/OUTLINE")
            foreach(l etchLayers
                subclassName = LayerView_GetSubclass(l)
                showLayers = append1(showLayers l)
                showLayers = append1(showLayers
                    sprintf(nil "PIN/%s" subclassName))
                showLayers = append1(showLayers
                    sprintf(nil "VIA CLASS/%s" subclassName))
            )
            LayerView_ShowLayers(showLayers)
            axlUIConfirm("\322\321\317\324\312\276\313\371\323\320\327\337\317\337\262\343")
            printf("[%s] \317\324\312\276\313\371\323\320\327\337\317\337\262\343\n" C_LAYER_VIEW_MODULE)
            return(t)
        )

        ; ========== 处理"b"输入: 切换到底层(v2.3 新增) ==========
        if( lowerCase(input) == "b" then
            targetLayer = car(last(etchLayers))
            _LayerView_ShowSingleEtchLayer(targetLayer)
            msgStr = sprintf(nil "\273\356\266\257\262\343: %s (\265\327\262\343)" targetLayer)
            axlUIConfirm(msgStr)
            printf("[%s] %s\n" C_LAYER_VIEW_MODULE msgStr)
            return(t)
        )

        ; ========== 处理数字输入: 解析层号 ==========
        ; (v2.1: 形参保留字 t 改名 tok)
        tokens = parseString(input " ")
        layerNums = mapcar(lambda((tok) atoi(tok)) tokens)

        ; 验证每个层号
        validNums = setof(n layerNums n > 0 && n <= totalLayers)

        if( null(validNums) then
            axlUIConfirm(
                sprintf(nil "\316\336\320\247\262\343\272\305\243\254\307\353\312\344\310\3531~%d\326\256\274\344\265\304\325\375\325\373\312\375"
                        totalLayers)
            )
            return(nil)
        )

        ; 检查是否有超出范围的层号
        if( length(validNums) != length(layerNums) then
            axlUIConfirm(
                sprintf(nil "\262\277\267\326\262\343\272\305\263\254\263\3661~%d\267\266\316\247\243\254\275\366\317\324\312\276\323\320\320\247\262\343\272\305"
                        totalLayers)
            )
        )

        ; ========== 构建需要显示的层列表 ==========
        ; 隐藏所有层
        LayerView_HideAllLayers()

        ; 基础层: 板框轮廓(始终显示)
        ; (v2.2: class 名用数据库内部带空格形式)
        showLayers = list("BOARD GEOMETRY/OUTLINE")

        ; 为每个有效层号添加ETCH/PIN/VIA CLASS层
        foreach(n validNums
            subclassName = LayerView_GetSubclass(nth(n - 1 etchLayers))
            showLayers = append1(showLayers
                sprintf(nil "ETCH/%s" subclassName))
            showLayers = append1(showLayers
                sprintf(nil "PIN/%s" subclassName))
            showLayers = append1(showLayers
                sprintf(nil "VIA CLASS/%s" subclassName))
        )

        ; 显示指定层
        LayerView_ShowLayers(showLayers)

        ; 设置活动层为第一个有效层号对应的ETCH层
        activeLayer = nth(car(validNums) - 1 etchLayers)
        _LayerView_SetActiveLayer(activeLayer)

        ; 构建结果提示消息
        if( length(validNums) == 1 then
            msgStr = sprintf(nil "\273\356\266\257\262\343: %s (\265\332%d\262\343)"
                             activeLayer car(validNums))
        else
            msgStr = sprintf(nil "\273\356\266\257\262\343: %s\243\254\317\324\312\276\262\343\272\305: %s"
                             activeLayer
                             buildString(
                                 mapcar(lambda((n)
                                     sprintf(nil "%d" n)) validNums)
                                 " "))
        )

        axlUIConfirm(msgStr)
        printf("[%s] %s\n" C_LAYER_VIEW_MODULE msgStr)
        t
    )
)

;------------------------------------------------------------------------
; 函数名  : LayerView_HideAllLayers
; 功能    : 隐藏所有图层，为视图切换做准备(不刷新, 由调用方统一刷新)
; 参数    : 无
; 返回值  : t - 操作成功
; 备注    : v2.1 改用 axlVisibleDesign(nil) 整体隐藏
;------------------------------------------------------------------------
procedure( LayerView_HideAllLayers()
    axlVisibleDesign(nil)
    t
)

;------------------------------------------------------------------------
; 函数名  : LayerView_ShowLayers
; 功能    : 显示指定层列表中的所有图层并刷新显示
; 参数    :
;   @param layerList - 要显示的层名称列表 (list of strings)
; 返回值  : t - 操作成功
; 备注    : v2.1 修正 axlVisibleLayer 参数顺序为(层名 开关),
;           axlUIRedraw 改 axlVisibleUpdate(t)
;------------------------------------------------------------------------
procedure( LayerView_ShowLayers( layerList )
    foreach(layerName layerList
        axlVisibleLayer(layerName t)
    )
    axlVisibleUpdate(t)
    t
)

;------------------------------------------------------------------------
; 函数名  : LayerView_ViewSilkTop
; 功能    : 切换到丝印顶层视图 - 仅显示顶层丝印相关图层
;           显示: 板框, 顶层丝印外形, 顶层位号丝印, 顶层焊盘, 顶层过孔
; 参数    : 无
; 返回值  : t - 操作成功
; 备注    : v2.2 class 名改带空格形式(BOARD/PACKAGE/REF DES/VIA CLASS)
;------------------------------------------------------------------------
procedure( LayerView_ViewSilkTop()
    let((silkTopLayers)
        silkTopLayers = list(
            "BOARD GEOMETRY/OUTLINE"
            "PACKAGE GEOMETRY/SILKSCREEN_TOP"
            "REF DES/SILKSCREEN_TOP"
            "PIN/TOP"
            "VIA CLASS/TOP"
        )
        LayerView_HideAllLayers()
        LayerView_ShowLayers(silkTopLayers)
        printf("[%s] \322\321\307\320\273\273\265\275\313\277\323\241\266\245\262\343\312\323\315\274\n" C_LAYER_VIEW_MODULE)
        t
    )
)

;------------------------------------------------------------------------
; 函数名  : LayerView_ViewSilkBottom
; 功能    : 切换到丝印底层视图 - 仅显示底层丝印相关图层
;           显示: 板框, 底层丝印外形, 底层位号丝印, 底层焊盘, 底层过孔
; 参数    : 无
; 返回值  : t - 操作成功
;------------------------------------------------------------------------
procedure( LayerView_ViewSilkBottom()
    let((silkBotLayers)
        silkBotLayers = list(
            "BOARD GEOMETRY/OUTLINE"
            "PACKAGE GEOMETRY/SILKSCREEN_BOTTOM"
            "REF DES/SILKSCREEN_BOTTOM"
            "PIN/BOTTOM"
            "VIA CLASS/BOTTOM"
        )
        LayerView_HideAllLayers()
        LayerView_ShowLayers(silkBotLayers)
        printf("[%s] \322\321\307\320\273\273\265\275\313\277\323\241\265\327\262\343\312\323\315\274\n" C_LAYER_VIEW_MODULE)
        t
    )
)

;------------------------------------------------------------------------
; 函数名  : LayerView_ViewAssyTop
; 功能    : 切换到装配顶层视图 - 仅显示顶层装配相关图层
;           显示: 板框, 顶层装配外形, 顶层装配位号, 顶层焊盘, 顶层过孔
; 参数    : 无
; 返回值  : t - 操作成功
;------------------------------------------------------------------------
procedure( LayerView_ViewAssyTop()
    let((assyTopLayers)
        assyTopLayers = list(
            "BOARD GEOMETRY/OUTLINE"
            "PACKAGE GEOMETRY/ASSEMBLY_TOP"
            "REF DES/ASSEMBLY_TOP"
            "PIN/TOP"
            "VIA CLASS/TOP"
        )
        LayerView_HideAllLayers()
        LayerView_ShowLayers(assyTopLayers)
        printf("[%s] \322\321\307\320\273\273\265\275\327\260\305\344\266\245\262\343\312\323\315\274\n" C_LAYER_VIEW_MODULE)
        t
    )
)

;------------------------------------------------------------------------
; 函数名  : LayerView_ViewAssyBottom
; 功能    : 切换到装配底层视图 - 仅显示底层装配相关图层
;           显示: 板框, 底层装配外形, 底层装配位号, 底层焊盘, 底层过孔
; 参数    : 无
; 返回值  : t - 操作成功
;------------------------------------------------------------------------
procedure( LayerView_ViewAssyBottom()
    let((assyBotLayers)
        assyBotLayers = list(
            "BOARD GEOMETRY/OUTLINE"
            "PACKAGE GEOMETRY/ASSEMBLY_BOTTOM"
            "REF DES/ASSEMBLY_BOTTOM"
            "PIN/BOTTOM"
            "VIA CLASS/BOTTOM"
        )
        LayerView_HideAllLayers()
        LayerView_ShowLayers(assyBotLayers)
        printf("[%s] \322\321\307\320\273\273\265\275\327\260\305\344\265\327\262\343\312\323\315\274\n" C_LAYER_VIEW_MODULE)
        t
    )
)

;------------------------------------------------------------------------
; ASTB 菜单包装函数(供 core/menu.il Utilities 菜单调用)
;------------------------------------------------------------------------

;------------------------------------------------------------------------
; 函数名  : ASTB_Util_LayerSwitch
; 功能    : 菜单包装 - 切层(输入层号切层/多选/全部走线层/底层)
; 参数    : 无
; 返回值  : t/nil - 同 LayerView_SwitchLayer
;------------------------------------------------------------------------
procedure( ASTB_Util_LayerSwitch()
    LayerView_SwitchLayer()
)

;------------------------------------------------------------------------
; 函数名  : ASTB_Util_LayerUp
; 功能    : 菜单包装 - 上一层走线层(循环)
; 参数    : 无
; 返回值  : t/nil
;------------------------------------------------------------------------
procedure( ASTB_Util_LayerUp()
    LayerView_LayerUp()
)

;------------------------------------------------------------------------
; 函数名  : ASTB_Util_LayerDown
; 功能    : 菜单包装 - 下一层走线层(循环)
; 参数    : 无
; 返回值  : t/nil
;------------------------------------------------------------------------
procedure( ASTB_Util_LayerDown()
    LayerView_LayerDown()
)

;------------------------------------------------------------------------
; 函数名  : ASTB_Util_ViewSilkTop
; 功能    : 菜单包装 - 丝印顶层视图
; 参数    : 无
; 返回值  : t
;------------------------------------------------------------------------
procedure( ASTB_Util_ViewSilkTop()
    LayerView_ViewSilkTop()
)

;------------------------------------------------------------------------
; 函数名  : ASTB_Util_ViewSilkBottom
; 功能    : 菜单包装 - 丝印底层视图
; 参数    : 无
; 返回值  : t
;------------------------------------------------------------------------
procedure( ASTB_Util_ViewSilkBottom()
    LayerView_ViewSilkBottom()
)

;------------------------------------------------------------------------
; 函数名  : ASTB_Util_ViewAssyTop
; 功能    : 菜单包装 - 装配顶层视图
; 参数    : 无
; 返回值  : t
;------------------------------------------------------------------------
procedure( ASTB_Util_ViewAssyTop()
    LayerView_ViewAssyTop()
)

;------------------------------------------------------------------------
; 函数名  : ASTB_Util_ViewAssyBottom
; 功能    : 菜单包装 - 装配底层视图
; 参数    : 无
; 返回值  : t
;------------------------------------------------------------------------
procedure( ASTB_Util_ViewAssyBottom()
    LayerView_ViewAssyBottom()
)

;------------------------------------------------------------------------
; 模块初始化调用
;------------------------------------------------------------------------
Init_LayerView()
