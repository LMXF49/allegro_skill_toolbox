;========================================================================
; 文件名    : core/menu.il
; 作者      : allegro_skill 项目组
; 创建日期  : 2026-06-06
; 版本      : 4.6
; 功能描述  : 菜单构建与注入（i18n 中英文支持、运行时语言切换、
;             菜单命令统一注册）
; 依赖模块  : core/utils.il、core/config.il、core/version_adapter.il、
;             core/trans.il
; 编码      : GBK（含中文注释）
; 修改记录  :
;   2026-10-11 v4.4 ASTB Team 语言切换联动 Allegro 本体界面语言
;                     （配套 modules/utilities/util_allegrolang.il：
;                     Allegro X 写 env 偏好 allegro_enable_localization/
;                     allegro_english_menu，17.x 写 intl_enabled 用户
;                     环境变量，均需重启 Allegro 生效；16.6 无机制）
;   2026-10-11 v4.6 ASTB Team System 新增 Menu CN/Menu EN（配套
;                     modules/utilities/util_menucn.il：Allegro
;                     菜单栏运行期汉化/恢复，主要面向 16.6）
;   2026-10-11 v4.5 ASTB Team 语言切换拆分：工具箱菜单语言与
;                     Allegro 本体界面语言解耦（移除 v4.4 联动钩子）；
;                     Allegro 界面语言改由 System->Allegro UI 子菜单
;                     独立设置（util_allegrolang.il v1.1 命令入口）
;   2026-10-11 v4.3 ASTB Team 菜单标签改内嵌双语（结构行
;                     （英文标签 中文标签 命令名），popup 行
;                     （popup 英文 中文））；中文由 sync 八进制
;                     转义兜底 16.6 reader，运行时字节与原
;                     labels_map.dat 路径一致，显示效果不变；
;                     删除 ASTB_LoadChineseLabels/ASTB_ZH_GET/
;                     ASTB_ZH_LABELS 与 labels_map.dat 外置数据源
;   2026-10-11 v4.2 ASTB Team System 新增 Uninstall 菜单项
;                     （配套 modules/utilities/util_uninstall.il 卸载
;                     命令）；新增 ASTB_UNINSTALLED 会话标志，卸载后
;                     OnDesignOpen 自愈不再重注入菜单
;   2026-10-04 v4.1 ASTB Team 恢复 Downrev to 16.6 菜单项
;                     （用户要求重新上线；模块全新重写为
;                     util_downrev166.il v1.0 取代 util_downrev17，
;                     同步恢复标签/帮助/安装包/文档引用）
;   2026-10-04 v4.0 ASTB Team 删除 Downrev to 16.6 菜单项
;                     （PCB 降版本功能整体下线，模块/运行时/标签/
;                     帮助/安装包/文档同步删除）
;   2026-10-01 v3.9 ASTB Team 删除 &Film Reorder 菜单项
;                     （Film重排序，模块/包装器/标签/帮助同步删除）
;   2026-10-01 v3.8 ASTB Team 删除 S&ame Via Highlight 菜单项
;                     （同类型过孔替换，模块 via_samevia.il 同步删除）
;   2026-10-01 v3.7 ASTB Team 恢复 S&ame Via Highlight 菜单项
;                     （同类型过孔替换）；删除 &Place by Page
;                     （符号浏览摆放器，模块同步删除）
;   2026-06-06 v1.0 allegro_skill 项目组 初始创建
;   2026-07-17 v1.1 修复组_框架核心 修复菜单错连：Check Text Overlap
;                   改回 v1 命令 ASTB_Text_CheckOverlap；?cmdType 符号
;                   改字符串；i18n 键表补 Hotkey Setup/Reset/Help 三项
;                  （对齐 labels_raw.dat 第 175-177 行）；'end 弹栈加
;                   空栈保护；注入检测同时匹配中英文标签；命令项不再
;                   把 t 当菜单 id 存入 ASTB_MENU_IDS；删除调试残留打印
;                   与死函数 ASTB_GetMenuCommands
;   2026-07-17 v1.2 整合工程师 跨组联动清理：
;                   a) 删除 3 个指向已删 wrapper 的菜单项
;                      (ASTB_Check_NoRefDes2/NoRef2/Loop902，check 组已删)；
;                   b) 删除 "Create &Oval Flash" 菜单项（pkg_createovalflash.il
;                      缺 f_* 表单库依赖，注册已摘除，功能不可用）；
;                   c) 删除重复项 "Change Via Net v2"（保留 "&Change Via Net"，
;                      ASTB_Via_ChangeViaNet2 别名在 via/zz_wrappers.il 保留）；
;                   d) keys 列表同步删除上述 5 键，与 labels_raw.dat
;                      保持位置对齐（178 -> 173）
;                   e) 终验追加：删除 "Super Net Finder" v1 菜单项
;                      （ASTB_Util_SuperNetFinder 随 lgs_super_net_finder_v1_0.il
;                      删除而悬空；v2 保留），keys/dat 173 -> 172
;   2026-07-18 ASTB 项目组 Utilities 新增 Layer Switch 及 4 个预设视图菜单项(配套 util_layerview.il)
;   2026-07-19 ASTB 项目组 Utilities 新增 Layer Up / Layer Down 菜单项(配套 util_layerview.il qu/qd 切层命令)；keys/dat 171 -> 173；修正 Hotkey 三项注释行号为 164-166
;   2026-07-19 ASTB 项目组 Manufacturing 新增 Gerber Setup 菜单项(配套 mfg_gerbersetup.il，命令 gbs)；keys/dat 173 -> 174
;   2026-07-19 ASTB 项目组 Text/Silk 新增 Add Chinese 菜单项
;                   (配套 text_addchinese.il，命令 ach)；keys/dat 第 65 键位
;                   已有，仅补绑定
;   2026-07-21 v1.6 ASTB 项目组 Placement 新增 Arrow Copy 菜单项
;                   (配套 place_arrowcopy.il，方向键等距复制)；keys/dat 174 -> 175
;   2026-07-25 v1.7 ASTB 项目组 Utilities 新增 Downrev to 16.6 菜单项
;                   (配套 util_downrev17.il 包装的 x_downrev17 数据桥)；keys/dat 175 -> 176
;   2026-07-25 v1.7.1 ASTB 项目组 Placement 新增 Pack by Net 菜单项
;                   (配套 place_packnet.il，按网络聚拢摆放)；keys/dat 176 -> 177
;   2026-07-25 v1.8 ASTB 项目组 菜单注入三处修复：a) 查重改
;                   axlUIMenuFind 直查 + dump 匹配补 ".*" 前缀（原
;                   rexMatchp 锚定行首恒不匹配，Reload 必重复注入）；
;                   b) 新增 'open/'menu 触发器 + 延时重注入，修复打开
;                   另一设计/多窗口时菜单被 Allegro 重建菜单栏清除；
;                   c) 触发器注册带 ASTB_TRIGGERS_SET 防重
;   2026-07-25 v1.9 ASTB 项目组 撤回 v1.8 的 axlUIMenuFind 直查
;                   快路径（该函数至少需 2 个参数，误用报错），
;                   查重统一走 dump 包含匹配
;   2026-07-25 v2.0 ASTB 项目组 ASTB_MENU_INJECTED 改 boundp
;                   保护：Reload 重载本文件不再重置注入标志，
;                   从机制上杜绝 Reload 叠菜单（菜单被清由触发器
;                   显式清标志后重注入兜底）
;   2026-07-25 v2.1 ASTB 项目组 语言切换两处修复：a) ApplyMenu-
;                   Language 读 ASTB_MENU_IDS 缺键得 'unbound 哨兵导致
;                   *Error* unbound variable topId（加 boundp/哨兵防御）；
;                   b) utils.il ASTB_EnsureDir 兼容 isDir 尾斜杠误判
;   2026-07-26 v2.2 ASTB 项目组 语言热切换叠菜单修复：旧版把
;                   axlUIMenuInsert 返回的嵌套 id 直接喂给
;                   axlUIMenuDelete（手册要求 axlUIMenuFind 体系 id），
;                   删除静默失败仍重注入导致叠菜单；改为 dump 验证
;                   闸门（ASTB_ToolboxMenuPresentInDump）+ 位置法删除
;                   （ASTB_ToolboxTopMenuPos 解析 dump 推算菜单栏位
;                   置后 axlUIMenuFind/Delete），确认旧菜单消失才重
;                   注入，否则提示重启
;   2026-07-26 v2.3 ASTB 项目组 ToolboxTopMenuPos 按实证 dump 格式
;                   重写：容器 BEGIN/END 缩进 0、菜单栏 POPUP 缩进 4、
;                   二级 POPUP 8、MENUITEM 12；改为从工具箱标记行向上
;                   回溯取缩进最小的 POPUP 行为顶层项（v2.2 的'最小缩
;                   进且含引号'规则在真实格式下找不到候选，pos=nil）
;   2026-07-26 v2.4 ASTB 项目组 恢复 v2.3 清理探针时误删的
;                   axlUIMenuDelete 调用（残留空 when 报 too few
;                   arguments，热切换因此中断）
;   2026-07-26 v2.5 ASTB 项目组 Via 新增 Replace Via Form 菜单项
;                   （配套 via/rvia.il 表单替换过孔，命令 rvia，
;                   表单 forms/rvia.form）；keys/dat 177 -> 178
;   2026-07-26 v2.6 ASTB 项目组 下线 Replace Via v2 菜单项（14a
;                   模块删除，职能由 Replace Via Form / rvia 接管），
;                   keys/dat 178 -> 177（同步删除 dat 第 52 行
;                   "替换Via v2"）
;   2026-08-01 v2.7 ASTB 项目组 中文标签改单一数据源 core/labels_map.dat
;                   （英文键=中文标签 同行维护，取代 keys 列表与
;                   labels_raw.dat 行号双写对齐）；ASTB_LoadChineseLabels
;                   重写并顺带修复 let 内 return 无 prog 隐患
;   2026-08-01 v2.8 ASTB Team Package 恢复 Create Oval Flash 菜单项
;                   （pkg_createovalflash.il v1.4 依赖已补齐：静态表单
;                   forms/pkg_createoval.form + _clpRotatePt 补实现）；
;                   labels_map.dat 同步追加标签；版本字段补 bump
;   2026-08-01 v2.9 ASTB Team 菜单裁剪（用户要求）：
;                   Manufacturing 只保留 Film Reorder / Gerber Setup，
;                   删除 11 项（含 5 个 _stubs 占位项与 6 个实体模块，
;                   模块文件与包装同步删除）；Utilities 删除
;                   Etch Layer View（占位提示项，L 命令模块一并删除）；
;                   labels_map.dat 同步删除对应标签
;   2026-08-01 v3.0 ASTB Team Routing 新增 Pad Layer Void /
;                   Cline Layer Void 菜单项（配套 route_padvoid.il /
;                   route_clinevoid.il 隔层挖空模块）；
;                   labels_map.dat 同步追加标签
;   2026-08-16 v3.1 ASTB Team Text/Silk 新增 RefDes Center 菜单项
;                   （配套 text_refdescenter.il 位号居中模块）；
;                   labels_map.dat 同步追加标签
;   2026-08-16 v3.2 ASTB Team 菜单自愈链路加诊断日志：SetupMenuTriggers
;                   打印 axlTriggerSet(nil nil) 支持触发器列表及 'open/'menu
;                   注册结果；OnDesignOpen 打印触发命中与计时器创建结果；
;                   InjectMenuLater 打印计时器回调命中（排查 16.6 打开设计后
;                   菜单不自愈）
;   2026-08-24 v3.5 ASTB Team 菜单防重载改清场式去重(参照 D:/FanySkill
;                   FYEnhanceMenu.il DH_FYUpdateMenu): 新增 ASTB_Purge-
;                   ToolboxMenu, 注入前循环 dump 定位删除全部既有副本
;                   (重复/残留/半注入)再插新菜单; InjectMenu 快速通道
;                   收窄为仅看 ASTB_MENU_INJECTED 标志; main.il Reload
;                   重置标志使 Reload 真正结构化重建菜单
;   2026-09-29 v3.6 ASTB Team System 新增 Open Studio 菜单项
;                   （打开外置软件 ASTB Studio，配套
;                   modules/utilities/util_openstudio.il）
;   2026-08-22 v3.4 ASTB Team 用户要求：Text/Silk 删除 Check Text
;                   Overlap v2 / AutoSilk Utils v2 两个菜单项（zz_wrappers
;                   包装同步删除，v1 功能保留）；System 新增 Help 菜单项
;                   （配套 util_help.il，命令行打印全命令帮助）
;   2026-08-16 v3.3 ASTB Team 叠菜单修复：'open+'menu 双触发时两个 500ms
;                   定时器各注入一次，dump 查重窗口期内叠出双菜单；新增
;                   ASTB_MENU_TIMER_ID 句柄，OnDesignOpen 先取消未触发的
;                   旧定时器再排新定时器，折叠为单次重注入；
;                   InjectMenuLater 触发后清句柄
;========================================================================

unless(boundp('ASTB_MENU_INJECTED) defvar(ASTB_MENU_INJECTED nil))
defvar(ASTB_MENU_IDS makeTable('ASTB_MENU_IDS))
unless(boundp('ASTB_TRIGGERS_SET) defvar(ASTB_TRIGGERS_SET nil))
unless(boundp('ASTB_TOP_MENU_ID) defvar(ASTB_TOP_MENU_ID nil))
;; 自愈定时器句柄：'open+'menu 双触发时先取消未触发的旧定时器，
;; 折叠为单次重注入，防叠菜单
unless(boundp('ASTB_MENU_TIMER_ID) defvar(ASTB_MENU_TIMER_ID nil))
;; 卸载会话标志：util_uninstall.il 置位后，本会话菜单自愈不再重注入
unless(boundp('ASTB_UNINSTALLED) defvar(ASTB_UNINSTALLED nil))

;; ============================================================
;; i18n: Language switch & label lookup
;; ============================================================

;------------------------------------------------------------------------
; 函数名  : ASTB_IsLanguageEnglish
; 功能    : 判断当前配置语言是否为英文
; 返回值  : t / nil
;------------------------------------------------------------------------
procedure( ASTB_IsLanguageEnglish()
  prog((lang)
    lang = ASTB_GetConfig("language" "zh-CN")
    when( or(null(lang) eq(lang 'unbound))
      lang = "zh-CN"
    )
    return( or(strcmp(lang "en") == 0 strcmp(lang "en-US") == 0 strcmp(lang "english") == 0 strcmp(lang "en-us") == 0) )
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_GetMenuStructure
; 功能    : 返回菜单结构定义（popup/end/separator/命令项）
; 返回值  : 菜单结构列表
; 备注    : 命令项格式 (英文标签 中文标签 命令名)，popup 项
;           (popup 英文标签 中文标签)；v4.3 起中文标签内嵌
;           本结构（取代 labels_map.dat 外置数据源）
;------------------------------------------------------------------------
procedure( ASTB_GetMenuStructure()
  list(

    ;; ====== Top-level toolbox menu ======
    list('popup "allegro_s&kill_toolbox" "Allegro Skill工具箱(&K)")

    ;; ====== Package ======
    list('popup "&Package" "封装(&P)")
    list("&Change Origin" "修改原点(&C)"       "ASTB_Pkg_ChangeOrigin")
    list("&Export Footprint" "导出封装(&E)"    "ASTB_Pkg_ExportFootprint")
    list("E&xport Pad" "导出焊盘(&x)"          "ASTB_Pkg_ExportPad")
    list("Create &Device File" "创建器件文件(&D)"  "ASTB_Pkg_CreateDevFile")
    list("Create &Oval Flash" "创建椭圆焊盘(&O)"   "ASTB_Pkg_CreateOvalFlash")
    '(end)
    '(separator)

    ;; ====== Placement ======
    list('popup "P&lacement" "布局(&l)")
    list("GatherPlace" "聚拢摆放(&J)"          "ASTB_Place_GatherPlace")
    list("&Align" "对齐(&A)"               "ASTB_Place_Align")
    list("&Move to Grid" "移到栅格(&M)"        "ASTB_Place_MoveToGrid")
    list("Move &Screen" "移动屏幕(&S)"         "ASTB_Place_MoveScreen")
    list("Arro&w Copy" "方向键等距复制(&w)"          "ASTB_Place_ArrowCopy")
    list("Pack by &Net" "按网络聚拢摆放(&N)"         "ASTB_Place_PackNet")
    '(end)
    '(separator)

    ;; ====== Routing ======
    list('popup "&Routing" "布线(&R)")
    list("&Cut Line/Shape" "切线/Shape(&C)"      "ASTB_Route_CutLineShape")
    list("C&hange Line Width" "修改线宽(&h)"   "ASTB_Route_ChangeLineWidth")
    list("&Delete Dangling" "删除悬垂线(&D)"     "ASTB_Route_DeleteDangling")
    list("&Short Segments" "短线段(&S)"      "ASTB_Route_ShortSeg")
    list("Chec&k Cross Split" "检查交叉分割(&K)"   "ASTB_Route_CheckSplit")
    list("&Line to Shape" "线转Shape(&L)"       "ASTB_Route_LineToShape")
    list("&Auto 10deg Trace" "自动10度走线(&A)"    "ASTB_Route_Auto10deg")
    list("Auto &Match Group" "自动创建等长组(&M)"    "ASTB_Route_AutoMatchGroup")
    list("&Pad Layer Void" "焊盘选层挖空(&P)"      "ASTB_Route_PadVoid")
    list("Cline Layer &Void" "走线选层挖空(&V)"    "ASTB_Route_ClineVoid")
    '(end)
    '(separator)

    ;; ====== Via ======
    list('popup "&Via" "过孔(&V)")
    list("&Change Via Net" "修改Via网络(&C)"      "ASTB_Via_ChangeViaNet")
    '(end)
    '(separator)

    ;; ====== Shape ======
    list('popup "&Shape" "铜皮(&S)")
    list("&Update Dynamic Shape" "更新动态Shape(&U)" "ASTB_Shape_UpdateDynamic")
    list("&Change Shape Net" "修改Shape网络(&C)"     "ASTB_Shape_ChangeNet")
    '(end)
    '(separator)

    ;; ====== Text/Silk ======
    list('popup "Te&xt/Silk" "文字/丝印(&x)")
    list("&Import Logo" "导入Logo(&I)"         "ASTB_Text_ImportLogo")
    list("&Add Chinese" "添加中文(&A)"         "ASTB_Text_AddChinese")
    list("Check Ref &Orient" "检查位号方向(&O)"    "ASTB_Text_CheckRefOrient")
    list("Add N&et Name" "添加网络名(&e)"        "ASTB_Text_AddNetName")
    ;; v1 菜单项必须连 v1 命令 ASTB_Text_CheckOverlap（原错连 v2）
    list("Check Text O&verlap" "检查文字重叠(&v)"  "ASTB_Text_CheckOverlap")
    list("RefDes &Center" "字符位置调整(&C)"       "ASTB_Text_RefDesCenter")
    list("&RefDes Rotate" "位号旋转(&R)"       "ASTB_Text_RefDesRotate")
    list("Re&name RefDes v2" "重命名位号v2(&n)"    "ASTB_Text_RenameRefDes2")
    list("&Text Center Rout" "文字中心路由(&T)"    "ASTB_Text_TextCenterRout")
    '(end)
    '(separator)

    ;; ====== Check ======
    list('popup "&Check" "检查(&C)")
    list("Check &No RefDes" "检查无位号(&N)"     "ASTB_Check_NoRefDes")
    list("&DRC Walk" "DRC浏览(&D)"            "ASTB_Check_DRCWalk")
    list("&Find Orphan Net" "查找孤立网络(&F)"     "ASTB_Check_OrphanNet")
    list("Check &90deg Line" "检查90度线(&9)"    "ASTB_Check_90degLine")
    list("Run D&bDoctor" "运行DbDoctor(&b)"        "ASTB_Check_DbDoctor")
    list("&Pad Count" "焊盘计数(&P)"           "ASTB_Check_PadCount")
    list("&Spacing Check" "间距检查(&S)"       "ASTB_Check_Spacing")
    list("&Highlight No Fanout" "高亮无扇出(&H)" "ASTB_Check_HilightNoFanout")
    list("So&lder to Line Check" "焊盘到线检查(&L)" "ASTB_Check_Solder2Line")
    '(end)
    '(separator)

    ;; ====== Manufacturing ======
    list('popup "&Manufacturing" "制造(&M)")
    list("&Gerber Setup" "光绘输出设置(&G)"       "ASTB_Mfg_GerberSetup")
    '(end)
    '(separator)

    ;; ====== Utilities ======
    list('popup "&Utilities" "工具(&U)")
    list("U&nit Convert" "单位换算(&n)"        "ASTB_Util_UnitConvert")
    list("Color &Power Nets" "电源网络刷色(&P)"    "ASTB_Util_ColorPowerNets")
    list("Super Net &Finder v2" "超级网络查找v2(&F)" "ASTB_Util_SuperNetFinder2")
    list("Choose &Grid" "选择栅格(&G)"         "ASTB_Util_ChooseGrid")
    list("Layer Sw&itch" "切层(多层/全部)(&i)"       "ASTB_Util_LayerSwitch")
    list("Layer &Up" "切换上一层(&U)"           "ASTB_Util_LayerUp")
    list("Layer &Down" "切换下一层(&D)"         "ASTB_Util_LayerDown")
    list("View Silk &Top" "丝印顶层视图(&T)"      "ASTB_Util_ViewSilkTop")
    list("View Silk &Bottom" "丝印底层视图(&B)"   "ASTB_Util_ViewSilkBottom")
    list("View &Assy Top" "装配顶层视图(&A)"      "ASTB_Util_ViewAssyTop")
    list("View Ass&y Bottom" "装配底层视图(&y)"   "ASTB_Util_ViewAssyBottom")
    list("&Color Setting v2" "颜色设置v2(&C)"    "ASTB_Util_ColorSetting2")
    list("&Etch Cross Plane" "蚀刻交叉平面(&E)"    "ASTB_Util_EtchCrossPlane")
    list("Assembly v&2" "装配图v2(&2)"         "ASTB_Util_Assembly2")
    list("&Search Star" "搜索星标(&S)"         "ASTB_Util_SearchStar")
    list("&Quick Save by Time" "按时间快速保存(&Q)"  "ASTB_Util_QuickSaveByTime")
    list("&Hotkey Setup" "快捷键设置(&H)"        "ASTB_Util_HotkeySetup")
    list("Hotkey &Reset" "快捷键重置(&R)"        "ASTB_Util_HotkeyReset")
    list("Hotkey He&lp" "快捷键帮助(&l)"         "ASTB_Util_HotkeyHelp")
    list("H&otkey Editor" "快捷键编辑器(&o)"       "ASTB_Util_HotkeyEditor")
    list("Downrev to 1&6.6" "降版本到16.6(&6)"     "ASTB_Util_Downrev166")
    '(end)
    '(separator)

    ;; ====== System ======
    list('popup "S&ystem" "系统(&y)")
    list("&Help" "帮助(&H)"    "ASTB_Help")
    list("&About" "关于(&A)"   "ASTB_About")
    list("&Reload" "重新加载(&R)"  "ASTB_Reload")
    list("&Open Studio" "打开外置软件(&O)" "ASTB_OpenStudio")
    list("&Uninstall" "卸载(&U)"   "ASTB_Uninstall")
    '(separator)
    list('popup "&Language" "语言(&L)")
    list("&English" "English(&E)"  "ASTB_SetLanguageEnglish")
    list("&Chinese" "中文(&C)"  "ASTB_SetLanguageChinese")
    '(end)
    list('popup "Alle&gro UI" "Allegro界面(&G)")
    list("&English" "English(&E)"  "ASTB_SetAllegroLangEnglish")
    list("&Chinese" "中文(&C)"  "ASTB_SetAllegroLangChinese")
    '(end)
    '(separator)
    list("&Menu CN" "菜单汉化(&M)"  "ASTB_MenuCN")
    list("Menu E&N" "恢复英文菜单(&N)"  "ASTB_MenuEN")
    '(end)
    '(end)
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_MenuIsPopup / ASTB_MenuIsEnd / ASTB_MenuIsSeparator
; 功能    : 菜单结构项类型判定
; 返回值  : t / nil
;------------------------------------------------------------------------
procedure( ASTB_MenuIsPopup(item)
  and(listp(item) car(item) == 'popup)
)

procedure( ASTB_MenuIsEnd(item)
  and(listp(item) car(item) == 'end)
)

procedure( ASTB_MenuIsSeparator(item)
  and(listp(item) car(item) == 'separator)
)

;------------------------------------------------------------------------
; 函数名  : ASTB_MenuIsCommand
; 功能    : 判定菜单项是否为命令项 (label label cmd)
; 返回值  : t / nil
;------------------------------------------------------------------------
procedure( ASTB_MenuIsCommand(item)
  and(listp(item) length(item) >= 3 stringp(car(item)) stringp(cadr(item)) stringp(caddr(item)))
)

;------------------------------------------------------------------------
; 函数名  : ASTB_MenuGetPopupLabel / ASTB_MenuGetCommandLabel
; 功能    : 按当前语言取 popup / 命令项的显示标签
; 返回值  : 标签字符串
;------------------------------------------------------------------------
procedure( ASTB_MenuGetPopupLabel(item)
  if( ASTB_IsLanguageEnglish() then cadr(item) else caddr(item) )
)

procedure( ASTB_MenuGetCommandLabel(item)
  if( ASTB_IsLanguageEnglish() then car(item) else cadr(item) )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_MenuGetCommand
; 功能    : 取命令项的命令名
; 返回值  : 命令名字符串
;------------------------------------------------------------------------
procedure( ASTB_MenuGetCommand(item)
  caddr(item)
)

;------------------------------------------------------------------------
; 函数名  : ASTB_MenuAlreadyInjected
; 功能    : 检测工具箱菜单是否已注入（先查内存标志，再 dump 菜单比对）
; 返回值  : t / nil
; 备注    : dump 比对同时匹配英文键与当前中文标签，避免中文语言下
;           检测失效导致重复注入
;------------------------------------------------------------------------
procedure( ASTB_MenuAlreadyInjected()
  prog((tmpFile port line found ret zhLabel)
    when( ASTB_MENU_INJECTED
      return(t)
    )
    found = nil
    ;; v4.3：中文标签取自内嵌结构顶层 popup 第三字段
    zhLabel = caddr(car(ASTB_GetMenuStructure()))
    ;; 注意：不可用 axlUIMenuFind 单参直查（该函数至少需 2 个参数），
    ;; 查重依赖下方 dump 包含匹配（已补 ".*" 前缀）
    ret = errset(
      prog(()
        tmpFile = axlTempFile()
        when( tmpFile
          axlUIMenuDump(tmpFile)
          port = infile(tmpFile)
          when( port
            while( gets(line port)
              ;; 中英文标签同时匹配
              ;; 首选编码无关标记：dump 中 MENUITEM 行的 ASTB_ 命令名
              ;;（中文标签在不同 dump 编码下可能匹配不到，命令名恒为 ASCII）
              when( or(rexMatchp(".*ASTB_Reload" line)
                       rexMatchp(".*ASTB_About" line)
                       rexMatchp(".*allegro_skill_toolbox" line)
                       and(zhLabel != "allegro_s&kill_toolbox" rexMatchp(strcat(".*" zhLabel) line)))
                found = t
              )
            )
            close(port)
          )
          deleteFile(tmpFile)
        )
      )
      t
    )
    unless( ret
      return(nil)
    )
    found
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_InjectMenu
; 功能    : 按 ASTB_GetMenuStructure 把工具箱菜单注入 Allegro 菜单栏
; 返回值  : t - 成功或已注入；nil - 失败
; 备注    : 'end 弹栈带空栈保护；命令项的 axlUIMenuInsert 返回 t/nil
;          （非菜单 id），因此不写入 ASTB_MENU_IDS
;------------------------------------------------------------------------
procedure( ASTB_InjectMenu()
  prog((menuList stack parentId item ret label cmd subId firstPopup enKey)
    when( ASTB_MENU_INJECTED
      ASTB_LogInfo("Menu already injected, skipping.")
      ASTB_DebugLog("ASTB_InjectMenu: flag set, skip")
      return(t)
    )
    ;; v3.5 清场式去重(参照 FanySkill DH_FYUpdateMenu): 注入前把 dump 里
    ;; 所有工具箱菜单副本(重复注入/历史残留/半注入)删干净再插新菜单
    unless( ASTB_PurgeToolboxMenu()
      ASTB_LogError("Toolbox menu purge failed; keep existing menu, abort injection")
      ASTB_DebugLog("ASTB_InjectMenu: purge failed, abort")
      ;; 保留现状避免重复插入; 自愈触发器会复位标志后重试
      ASTB_MENU_INJECTED = t
      return(nil)
    )
    ASTB_MENU_IDS = makeTable('ASTB_MENU_IDS)
    menuList = ASTB_GetMenuStructure()
    when( null(menuList)
      ASTB_LogError("Menu structure is empty")
      ASTB_DebugLog("ASTB_InjectMenu: FAIL empty structure")
      return(nil)
    )
    firstPopup = car(menuList)
    unless( ASTB_MenuIsPopup(firstPopup)
      ASTB_LogError("Invalid top-level menu structure")
      ASTB_DebugLog("ASTB_InjectMenu: FAIL bad top structure")
      return(nil)
    )
    parentId = ASTB_MenuFindSafe(nil -1)
    label = ASTB_MenuGetPopupLabel(firstPopup)
    enKey = cadr(firstPopup)
    ASTB_DebugLog(sprintf(nil "ASTB_InjectMenu: parentId=%L label=%s" parentId label))
    ret = errset(parentId = axlUIMenuInsert(parentId 'popup label) t)
    unless( ret
      ASTB_LogError("Failed to create top-level popup")
      ASTB_DebugLog("ASTB_InjectMenu: FAIL insert top popup")
      return(nil)
    )
    parentId = car(ret)
    ASTB_MENU_IDS[enKey] = parentId
    ASTB_TOP_MENU_ID = parentId
    stack = list(parentId)
    foreach( item cdr(menuList)
      when( listp(item)
        cond(
          ( ASTB_MenuIsPopup(item)
            label = ASTB_MenuGetPopupLabel(item)
            enKey = cadr(item)
            ret = errset(subId = axlUIMenuInsert(parentId 'popup label) t)
            when( ret
              stack = cons(car(ret) stack)
              parentId = car(ret)
              ASTB_MENU_IDS[enKey] = parentId
            )
          )
          ( ASTB_MenuIsEnd(item)
            ;; 空栈保护：结构不平衡时立即报错退出，防止后续项插入位置错乱
            when( null(stack)
              ASTB_LogError("Menu structure unbalanced: 'end' with empty stack; injection aborted")
              return(nil)
            )
            stack = cdr(stack)
            parentId = car(stack)
          )
          ( ASTB_MenuIsSeparator(item)
            errset(axlUIMenuInsert(parentId 'separator) t)
          )
          ( ASTB_MenuIsCommand(item)
            label = ASTB_MenuGetCommandLabel(item)
            cmd = ASTB_MenuGetCommand(item)
            ret = errset(subId = axlUIMenuInsert(parentId label cmd) t)
            unless( ret
              ASTB_LogWarn(sprintf(nil "Failed to insert menu item: %s" label))
            )
            ;; 注意：命令项的 axlUIMenuInsert 返回 t/nil（不是菜单 id），
            ;; 不得写入 ASTB_MENU_IDS；命令项无需按 id 回溯
          )
        )
      )
    )
    ASTB_MENU_INJECTED = t
    ASTB_LogInfo("Menu injected successfully.")
    ASTB_DebugLog("ASTB_InjectMenu: done, return t")
    ASTB_SetupMenuTriggers()
    ;; 菜单已变化: 使 dump 缓存失效, 否则下次切换读到注入前的旧快照,
    ;; 误以为菜单不在而跳过删除直接重注入 -> 叠菜单
    ASTB_MenuSnapshotInvalidate()
    return(t)
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_InjectMenuLater
; 功能    : 延时重注入包装（定时器回调）：清注入标志使查重走真实
;           查找，再调 ASTB_InjectMenu（其内部自带查重，重复调用
;           无副作用）
; 参数    : window/timerId/elapsedTime - 定时器占位参数（可选）
; 返回值  : t
;------------------------------------------------------------------------
procedure( ASTB_InjectMenuLater(@optional window timerId elapsedTime)
  ASTB_MENU_TIMER_ID = nil
  ASTB_LogInfo("Menu self-heal timer fired, re-injecting menu")
  ASTB_MENU_INJECTED = nil
  errset(ASTB_InjectMenu() t)
  t
)

;------------------------------------------------------------------------
; 函数名  : ASTB_OnDesignOpen
; 功能    : 菜单自愈触发回调：Allegro 在打开设计、切换图面类型或
;           重载自身菜单时会重建菜单栏，清除已注入的工具箱菜单；
;           本回调延时 500ms（避开 Allegro 重建窗口期）重新注入
; 参数    : 触发器参数（忽略）
; 返回值  : t
;------------------------------------------------------------------------
procedure( ASTB_OnDesignOpen(@rest args)
  prog((tid)
    ;; 卸载会话内禁止自愈重注入（util_uninstall.il 置位 ASTB_UNINSTALLED）
    when( ASTB_UNINSTALLED
      ASTB_LogInfo("Menu self-heal skipped: uninstalled this session")
      return(t)
    )
    ASTB_LogInfo("Menu self-heal trigger fired, re-injecting in 500ms")
    ;; 折叠同一事件的 'open+'menu 双触发：取消未触发的旧定时器，
    ;; 否则两个定时器各注入一次，dump 查重窗口期内会叠出双菜单
    when( ASTB_MENU_TIMER_ID
      errset(axlUIWTimerRemove(ASTB_MENU_TIMER_ID) t)
      ASTB_MENU_TIMER_ID = nil
      ASTB_DebugLog("ASTB_OnDesignOpen: pending timer cancelled (collapse)")
    )
    tid = errset(axlUIWTimerAdd(nil 500 t 'ASTB_InjectMenuLater) t)
    if( tid then
      ASTB_MENU_TIMER_ID = car(tid)
    else
      ASTB_LogWarn("axlUIWTimerAdd failed; menu self-heal unavailable this time")
    )
    return(t)
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_SetupMenuTriggers
; 功能    : 注册菜单自愈触发器（'open 设计打开、'menu 菜单加载），
;           每会话一次（ASTB_TRIGGERS_SET 防 Reload 重复注册）
; 返回值  : t
;------------------------------------------------------------------------
procedure( ASTB_SetupMenuTriggers()
  unless( and(boundp('ASTB_TRIGGERS_SET) ASTB_TRIGGERS_SET)
    ;; 诊断：打印本版本支持的触发器列表（排查老版本缺 'open/'menu 用）
    supported = errset(axlTriggerSet(nil nil) t)
    if( supported then
      ASTB_LogInfo(sprintf(nil "Supported triggers: %L" car(supported)))
    else
      ASTB_LogWarn("axlTriggerSet query failed; menu self-heal may not work")
    )
    r1 = errset(axlTriggerSet('open 'ASTB_OnDesignOpen) t)
    r2 = errset(axlTriggerSet('menu 'ASTB_OnDesignOpen) t)
    unless( r1 ASTB_LogWarn("axlTriggerSet 'open registration failed") )
    unless( r2 ASTB_LogWarn("axlTriggerSet 'menu registration failed") )
    ASTB_TRIGGERS_SET = t
  )
  t
)

;------------------------------------------------------------------------
; 函数名  : ASTB_RegisterAllMenuCommands
; 功能    : 统一注册菜单结构中的全部命令 + 语言切换命令
; 返回值  : 无
; 备注    : cmdType 必须为字符串（手册：t_cmdType 是字符串类型）
;------------------------------------------------------------------------
procedure( ASTB_RegisterAllMenuCommands()
  prog((menuList item cmd count)
    menuList = ASTB_GetMenuStructure()
    count = 0
    foreach( item menuList
      when( ASTB_MenuIsCommand(item)
        cmd = ASTB_MenuGetCommand(item)
        ASTB_RegisterCommand(cmd cmd ?cmdType "interactive")
        count = count + 1
      )
    )
    ;; Register system language commands
    ASTB_RegisterCommand("ASTB_SetLanguageEnglish" "ASTB_SetLanguageEnglish" ?cmdType "interactive")
    ASTB_RegisterCommand("ASTB_SetLanguageChinese" "ASTB_SetLanguageChinese" ?cmdType "interactive")
    count = count + 2
    ASTB_LogInfo(sprintf(nil "Registered %d menu commands" count))
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_DumpLeadingSpaces
; 功能    : 返回菜单 dump 行的前导空白宽度（空格与 Tab 各计 1）
; 参数    : line - dump 文件中的一行
; 返回值  : 非负整数
;------------------------------------------------------------------------
procedure( ASTB_DumpLeadingSpaces(line)
  prog((n total)
    n = 0
    total = strlen(line)
    while( and( n < total
                or( equal(substring(line n+1 1) " ")
                    equal(substring(line n+1 1) "\t") ))
      n = n+1
    )
    return(n)
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_ToolboxMenuPresentInDump
; 功能    : 纯 dump 检测工具箱菜单是否仍在菜单栏（不查内存标志，
;           专供删除后验证）；dump 失败按"仍在"处理（保守防叠菜单）
; 返回值  : t - 存在或无法判定；nil - 确认不存在
;------------------------------------------------------------------------
;;------------------------------------------------------------------
;; 单次 dump 缓存: axlUIMenuDump 在中文菜单下是秒级慢操作, 而语言
;; 热切换原本要 dump 5~10 次(PresentInDump/TopMenuPos/Purge 各自
;; 重复 dump), 导致单核跑满卡数分钟。这里把一次 dump 的行解析成
;; (present pos) 缓存起来, 一次切换只 dump 1~2 次。
;;   ASTB_MENU_SNAPSHOT = nil            无缓存(下次读取会重 dump)
;;                     = (lines present pos)  一份 dump 的解析结果
;;------------------------------------------------------------------
unless( boundp('ASTB_MENU_SNAPSHOT) ASTB_MENU_SNAPSHOT = nil )

; 使缓存失效(任何删除/注入菜单的操作后必须调用)
procedure( ASTB_MenuSnapshotInvalidate()
  ASTB_MENU_SNAPSHOT = nil
)

; 取一份 dump 的行列表(有缓存直接用, 没有则 dump 一次并缓存)
; 返回: 行列表(顺序与 dump 一致); dump/读文件失败返回 nil
procedure( ASTB_MenuSnapshotLines()
  prog((tmpFile port line lines)
    when( and(boundp('ASTB_MENU_SNAPSHOT) ASTB_MENU_SNAPSHOT)
      return(car(ASTB_MENU_SNAPSHOT))
    )
    tmpFile = axlTempFile()
    unless( tmpFile return(nil) )
    errset(axlUIMenuDump(tmpFile) t)
    port = errset(infile(tmpFile) t)
    unless( port
      errset(deleteFile(tmpFile) t)
      return(nil)
    )
    port = car(port)
    lines = nil
    while( gets(line port)
      lines = cons(line lines)
    )
    close(port)
    errset(deleteFile(tmpFile) t)
    lines = reverse(lines)
    ;; 顺手把 present/pos 一并算出缓存(见下两函数共享)
    ASTB_MENU_SNAPSHOT = list(lines
        ASTB_MenuSnapshotPresent(lines)
        ASTB_MenuSnapshotPos(lines))
    return(lines)
  )
)

; 在已给的行列表上判断工具箱菜单是否在场(不再 dump)
procedure( ASTB_MenuSnapshotPresent(lines)
  prog((found line)
    found = nil
    foreach( line lines
      when( or( rexMatchp(".*ASTB_Reload" line)
                rexMatchp(".*ASTB_About" line)
                rexMatchp(".*allegro_skill_toolbox" line) )
        found = t
      )
    )
    return(found)
  )
)

; 在已给的行列表上推算工具箱顶层 popup 的位置序号(不再 dump)
; 失败返回 nil(调用方降级, 绝不盲删)
procedure( ASTB_MenuSnapshotPos(lines)
  prog((line tbIdx idx curInd topLineIdx topInd pos)
    tbIdx = nil
    idx = 0
    foreach( line lines
      when( and( null(tbIdx)
                 or( rexMatchp(".*ASTB_Reload" line)
                     rexMatchp(".*ASTB_About" line) ))
        tbIdx = idx
      )
      idx = idx+1
    )
    unless( tbIdx return(nil) )
    topLineIdx = nil
    topInd = 99999
    idx = tbIdx
    while( idx >= 0
      line = nth(idx lines)
      when( rexMatchp("POPUP" line)
        curInd = ASTB_DumpLeadingSpaces(line)
        when( curInd < topInd
          topInd = curInd
          topLineIdx = idx
        )
      )
      idx = idx-1
    )
    unless( topLineIdx return(nil) )
    pos = 0
    idx = 0
    while( idx < topLineIdx
      line = nth(idx lines)
      when( and( rexMatchp("POPUP" line)
                 equal(ASTB_DumpLeadingSpaces(line) topInd) )
        pos = pos+1
      )
      idx = idx+1
    )
    return(pos)
  )
)

procedure( ASTB_ToolboxMenuPresentInDump()
  prog((lines)
    lines = ASTB_MenuSnapshotLines()
    ;; dump/读取失败时保守视为仍在(防叠菜单)
    unless( lines return(t) )
    return(ASTB_MenuSnapshotPresent(lines))
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_ToolboxTopMenuPos
; 功能    : 解析 axlUIMenuDump 输出，推算工具箱顶层 popup 在菜单栏
;           的位置序号（0 起，供 axlUIMenuFind 按位置定位后删除）
; 返回值  : 位置整数；解析失败返回 nil
; 备注    : 0726 dump 实证格式：容器 BEGIN/END 缩进 0、菜单栏
;           POPUP 缩进 4、二级 POPUP 8、MENUITEM 12；从标记行向上
;           回溯取缩进最小的 POPUP 行为顶层项；失败返回 nil（调用
;           方降级为重启提示，绝不盲删）
;------------------------------------------------------------------------
procedure( ASTB_ToolboxTopMenuPos()
  prog((lines tbIdx idx curInd topLineIdx topInd pos line)
    lines = ASTB_MenuSnapshotLines()
    unless( lines return(nil) )
    ;; 工具箱命令标记所在行（命令名恒为 ASCII，中英文菜单均可靠）
    tbIdx = nil
    idx = 0
    foreach( line lines
      when( and( null(tbIdx)
                 or( rexMatchp(".*ASTB_Reload" line)
                     rexMatchp(".*ASTB_About" line) ))
        tbIdx = idx
      )
      idx = idx+1
    )
    unless( tbIdx return(nil) )
    ;; 从标记行向上回溯：缩进最小的 POPUP 行即工具箱顶层 popup
    ;; （0726 dump 实证格式：菜单栏容器 BEGIN/END 缩进 0，菜单栏
    ;;   POPUP 缩进 4，工具箱内二级 POPUP 缩进 8，MENUITEM 12）
    topLineIdx = nil
    topInd = 99999
    idx = tbIdx
    while( idx >= 0
      line = nth(idx lines)
      when( rexMatchp("POPUP" line)
        curInd = ASTB_DumpLeadingSpaces(line)
        when( curInd < topInd
          topInd = curInd
          topLineIdx = idx
        )
      )
      idx = idx-1
    )
    unless( topLineIdx return(nil) )
    ;; 位置 = 全文中缩进 == topInd 的 POPUP 行里该行的序号（0 起）
    pos = 0
    idx = 0
    while( idx < topLineIdx
      line = nth(idx lines)
      when( and( rexMatchp("POPUP" line)
                 equal(ASTB_DumpLeadingSpaces(line) topInd) )
        pos = pos+1
      )
      idx = idx+1
    )
    return(pos)
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_ApplyMenuLanguage
; 功能    : 对已注入菜单做运行时语言切换：删除旧顶层 popup -> 重置
;           注入状态 -> 按新语言重新注入
; 返回值  : t - 成功；nil - 删除未确认（保持旧菜单，提示重启生效）
; 备注    : axlUIMenuDelete 手册要求 axlUIMenuFind 体系 id，与
;           Insert 返回的嵌套 id 不通用；采用 dump 验证闸门 +
;           位置法删除，杜绝误删他人菜单与叠菜单
;------------------------------------------------------------------------
; 函数名  : ASTB_PurgeToolboxMenu
; 功能    : 清场式去重(参照 D:/FanySkill FYEnhanceMenu.il DH_FYUpdateMenu):
;           循环 dump 菜单, 把工具箱顶层 popup 的所有副本逐个定位删除,
;           直到 dump 干净为止
; 返回值  : t - dump 中已无工具箱菜单; nil - 达上限仍有残留/定位失败
; 备注    : 每轮重新 dump+定位(ASTB_ToolboxTopMenuPos), 位置不随删除漂移;
;           上限 5 轮防死循环; 删除动作 errset 包裹, 失败即中止不盲删
;------------------------------------------------------------------------
procedure( ASTB_PurgeToolboxMenu()
  prog((n pos q)
    n = 0
    ;; 上限 2: 正常情况下工具箱菜单只有一份; 每次检测/定位都复用同一
    ;; 份 dump 缓存, 只有真正删掉一份后才使缓存失效重 dump, 避免中文
    ;; 菜单下反复秒级 dump 卡死
    while( and(ASTB_ToolboxMenuPresentInDump() n < 2)
      pos = ASTB_ToolboxTopMenuPos()
      unless( pos
        return(nil)
      )
      q = errset(axlUIMenuFind(nil pos) t)
      unless( and(q car(q))
        return(nil)
      )
      errset(axlUIMenuDelete(car(q)) t)
      ASTB_MenuSnapshotInvalidate()
      n = n + 1
    )
    when( ASTB_ToolboxMenuPresentInDump()
      return(nil)
    )
    when( n > 0
      ASTB_LogInfo(sprintf(nil "Purged %d stale toolbox menu copy/copies" n))
    )
    return(t)
  )
)

;------------------------------------------------------------------------
procedure( ASTB_ApplyMenuLanguage()
  prog((topId langStr pos q)
    ;; 手册（axlUIMenuDelete）：Delete 的 id 必须来自 axlUIMenuFind；
    ;; ASTB_TOP_MENU_ID 存的是 axlUIMenuInsert 返回的嵌套 id——体系
    ;; 不同，直接 Delete 会静默失败（不抛错、返回 nil），errset 又
    ;; 把 (nil) 当成功，重注入即叠菜单（v2.1 实测现象）。
    ;; 策略：先试旧 id（无害）→ dump 验证 → 位置法删除 → 再验证；
    ;; 只有确认旧菜单消失才重注入，否则提示重启（语言已存 cfg）。
    topId = nil
    when( and(boundp('ASTB_TOP_MENU_ID) ASTB_TOP_MENU_ID)
      topId = ASTB_TOP_MENU_ID
    )
    ;; 每次切换从一份全新 dump 开始(清掉上次切换/注入残留的跨调用缓存)
    ASTB_MenuSnapshotInvalidate()
    when( topId
      errset(axlUIMenuDelete(topId) t)
      ASTB_MenuSnapshotInvalidate()
    )
    when( ASTB_ToolboxMenuPresentInDump()
      pos = ASTB_ToolboxTopMenuPos()
      when( pos
        q = errset(axlUIMenuFind(nil pos) t)
        when( and(q car(q))
          errset(axlUIMenuDelete(car(q)) t)
          ASTB_MenuSnapshotInvalidate()
        )
      )
    )
    if( ASTB_ToolboxMenuPresentInDump() then
      ;; 删除未成功：保持旧菜单原样，绝不重注入（杜绝叠菜单）；
      ;; 语言偏好已写入 astb.cfg，重启 Allegro 后生效
      ASTB_MENU_INJECTED = t
      return(nil)
    else
      ;; Reset injection state so ASTB_InjectMenu can run again
      ASTB_MENU_INJECTED = nil
      ASTB_MENU_IDS = makeTable('ASTB_MENU_IDS)
      ;; Re-inject with new language labels
      unless( ASTB_InjectMenu()
        ASTB_LogError("Failed to re-inject menu after language switch")
        return(nil)
      )
      langStr = if(ASTB_IsLanguageEnglish() then "&English" else "&Chinese")
      printf("[ASTB] Menu language switched to %s.\n" langStr)
      return(t)
    )
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_SetLanguage
; 功能    : 设置菜单语言并持久化，随后尝试运行时热切换
; 参数    : lang - "en" 或 "zh-CN"
; 返回值  : t
;------------------------------------------------------------------------
procedure( ASTB_SetLanguage(lang)
  prog((oldLang cfgVal isEn ok msg)
    oldLang = ASTB_GetConfig("language" "zh-CN")
    ASTB_LogInfo(sprintf(nil "SetLanguage: oldLang=%L lang=%L" oldLang lang))
    when( or(null(oldLang) eq(oldLang 'unbound))
      oldLang = "zh-CN"
    )
    ;; 不做 oldLang==lang 早退：配置与当前菜单语言可能不一致
    ;;（如配置为 en 但菜单仍是中文），此时更需要走重注入纠正
    ASTB_DebugLog(sprintf(nil "SetLanguage: lang=%s old=%L inList=%L cfgNow=%L"
        lang oldLang (ASTB_StrListHas ASTB_CONFIG_KEYS "language")
        ASTB_GetConfig("language" "zh-CN")))
    ;; Save preference first (so it persists across restarts)
    ASTB_SetConfig("language" lang)
    ASTB_SaveConfig()
    cfgVal = ASTB_GetConfig("language" "zh-CN")
    ASTB_LogInfo(sprintf(nil "SetLanguage: saved value=%L" cfgVal))
    ;; hot_switch=off(astb.cfg)时只写配置提示重启, 零 dump 不卡;
    ;; 默认 on 走合并 dump 的热切换(1~2 次 dump)
    ;; Try runtime switch（errset 包裹：内部任何异常都落回重启提示）
    hotSwitch = ASTB_GetConfig("hot_switch" "on")
    if( equal(hotSwitch "off")
    then ok = nil
    else ok = errset(ASTB_ApplyMenuLanguage() t)
    )
    isEn = ASTB_IsLanguageEnglish()
    if( ok
    then
      msg = if(isEn then "Switched to English." else "Switched to Chinese.")
    else
      msg = if(isEn
             then "Language set to English.\nRestart Allegro to apply menu changes."
             else "Language set to Chinese.\nRestart Allegro to apply menu changes.")
    )
    axlUIConfirm(msg)
    return(t)
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_SetLanguageEnglish / ASTB_SetLanguageChinese
; 功能    : 语言切换命令入口
; 返回值  : t
;------------------------------------------------------------------------
procedure( ASTB_SetLanguageEnglish()
  ASTB_SetLanguage("en")
)

procedure( ASTB_SetLanguageChinese()
  ASTB_SetLanguage("zh-CN")
)

errset(ASTB_SetupMenuTriggers() t)

printf("[ASTB] core/menu.il loaded.\n")
