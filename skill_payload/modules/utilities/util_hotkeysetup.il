;========================================================================
; 文件名    : util_hotkeysetup.il
; 作者      : SkillGroup
; 创建日期  : 2026-07-16
; 版本      : 2.2
; 功能描述  : Allegro PCB Editor 快捷键批量设置模块，
;             将常用命令绑定到功能键、字母键和键序列，
;             提升日常设计效率。
; 依赖模块  : core/trans.il (ASTB_RegisterCommand)
; 修改记录  :
;   2026-07-16 v1.0 SkillGroup 初始创建
;   2026-07-17 v1.1 SkillGroup 修复 env 写入链路：
;             1) env 指令由非法的 "set funkey" 改为合法 "funckey"
;             2) env 路径由 ~/.allegro/env 改为 $HOME/pcbenv/env
;             3) 重写用户 env 前自动备份 env.bak
;             4) 键序列白名单判定，功能键/特殊单键不写入 env
;             5) 标记行改纯 ASCII，删除重复注册路径
;   2026-07-17 v1.2 SkillGroup 修复 env 结构导致启动弹窗：
;             1) 新建/重写 env 时确保首行存在 source $TELENV，
;                缺失会导致 Allegro 报 allegro_smi_modules.txt 错误
;             2) funckey 命令串统一加双引号，避免多词命令解析歧义
;   2026-08-24 v1.3 ASTB Team 快捷键表单编辑器: 表格表单自由改键
;                     (键/命令两列+勾选删除+添加行), 应用即生效
;                     (funckey+env), 用户配置存 config/hotkeys_user.dat
;                     启动自动覆盖默认值, 可一键恢复出厂
;   2026-08-24 v1.4 ASTB Team 编辑器返修: STRFILLIN 第二参数是容量
;                     (原"20 1"只装1字符, 实锤cmd变"z"), 键/命令/说明
;                     全改可编辑宽域; 说明也可改; 单栏18行分页(上一页/
;                     下一页), Allegro表单无原生滚动条的通用解法
;   2026-08-24 v1.5 ASTB Team 应用即时报错/恢复默认无效/行距返修:
;                     lowercase 不存在换 stringToLower(17.4实锤);
;                     多键序列也能 axlSetFunckey 即时绑定(zz99实测=t),
;                     BindAll 全量即时绑定+序列留 env 持久; 恢复默认
;                     补“恢复并应用”; 行距改 2 行距/12 行每页
;   2026-08-24 v1.6 ASTB Team 删勾选列: 删除=清空该行的“键”后点应用
;                     (MergePage 本就丢全空行), 表头加提示; 省出的
;                     宽度给说明列; 页数无上限(添加行自动跳末页)
;   2026-08-24 v1.7 ASTB Team 持久化闭环: 启动检测 hotkeys_user.dat
;                     存在则加载并自动 BindAll, 单键绑定跨会话不失效
;   2026-08-24 v1.8 ASTB Team 启动冻结修复:
;                     1) RemoveOldSection append1->cons+reverse (O(n^2)->O(n)),
;                        env 膨胀到 47 万行时启动刷新它即 UI 冻结
;                     2) 读 env 每行剥 \r 特字符, 丢弃空行
;                        (原 CRLF 往返每写空行翻倍, 这是膨胀源头)
;                     3) TELENV 去重/其它字符串比较 ==->equal
;                     4) 启动自适应只 BindAll(nil) 绑键,
;                        不再每次启动重写 env
;                        (env 只在编辑器 应用/恢复默认时写)
;   2026-08-24 v1.9 ASTB Team 编辑器表单视觉重排:
;                     表头按列 x 对齐(键1/命令7/说明32), 按钮行均匀间距,
;                     PORT=内容外沿+2格(76x32); 中文按 2 格计宽,
;                     适配中文 Windows 系统字体下 16.6/17.4 格子差异
;   2026-08-26 v2.0 ASTB Team 恢复默认真正解绑:
;                     旧路径只 BindAll 重绑出厂键, 出厂表之外的用户
;                     自定义键当前会话内保持绑定（“重置没用”根因）;
;                     新增 _HotkeyEditor_FactoryReset() 先解绑多余键
;                     再恢复出厂/存 dat/重绑, 编辑器 hke_reset 与
;                     Studio 桥接统一调它; 恢复默认改为保存出厂表到
;                     dat(原删 dat), 重启后键位与当前会话一致
;   2026-08-26 v2.1 ASTB Team 快捷键全路径不再写 env:
;                     应用/恢复默认/Hotkey Reset/启动重绑均只做
;                     axlSetFunckey 内存绑定; 持久化由 hotkeys_user.dat
;                     +启动自动重绑负责(dat 本就能持久键序列,
;                     env 写入是冗余); 删除 WriteEnvFile/RemoveOldSection
;                     (FromEnv)/HasTelenvSource/GetEnvPath/BackupFile/
;                     StartsWith/IsKeySequence/IsValidKeyName 及
;                     C_HOTKEY_ENV_*/C_HOTKEY_SPECIAL_KEYS;
;                     根因: 用户 env 被 CRLF 往返膨胀到 9200 万行,
;                     任何整文件读写都会冻结 UI 线程
;   2026-08-29 v2.2 ASTB Team 修复启动不重绑: v2.1 启动只 LoadUser
;                     不 BindAll, 导致重启后快捷键失效; 恢复 v1.7
;                     启动自动 BindAll 行为, 实现真正跨会话持久化
;   2026-09-30 v2.2 ASTB Team 内置默认表整体替换为用户确认的 49 条:
;                     删 z|astb_via_changevianet(与 z 的 prepopup 重复
;                     冲突); c 由 oops 改 ASTB_Route_CutLineShape;
;                     js/jt/jb/jl 空命令补正式命令; zoom 由 +/- 改
;                     F11/F12; factory/user.dat 同步同表
;   2026-09-30 v2.3 ASTB Team 空格键被表单往返吃掉修复:
;                     ParseDat 行尾剥 \r 且键/命令为空的行跳过;
;                     MergePage 键字段空而命令未变时沿用原键
;                     (axlFormGetField 会 trim 纯空格键)
;========================================================================

;------------------------------------------------------------------------
; 全局变量初始化
;------------------------------------------------------------------------
unless(boundp('g_hotkeySetupVersion)
    g_hotkeySetupVersion = "2.3"
)

unless(boundp('g_hotkeySetupApplied)
    g_hotkeySetupApplied = nil
)

;------------------------------------------------------------------------
; 模块常量
;------------------------------------------------------------------------
C_HOTKEY_MODULE = "HotkeySetup"



;------------------------------------------------------------------------
; 快捷键配置表
; 格式  : list(键名 命令 说明)
; 键名  : 单字符 = 直接按该键触发（funckey 方式，无需回车）；
;         大写字母 = Shift+字母键；F1~F12 = 功能键；
;         键序列(如 jv) = 依次按 j、v 两个键。
; 注意  : axlSetFunckey 不支持键序列，键序列只能以 funckey 指令
;         写入用户 env 文件（$HOME/pcbenv/env），重启 Allegro 后生效。
;         本模块对单键/功能键调用 axlSetFunckey，对键序列写 env。
;         "+" 缩小 / "-" 放大 为沿用的习惯配置，与直觉相反，如需
;         交换请修改下方前两行配置。
;------------------------------------------------------------------------
unless(boundp('g_hotkeyConfig)
    g_hotkeyConfig = list(
        ; === 视图操作 ===
        list("F11"  "zoom out"                   "\266\324PCB\275\347\303\346\275\370\320\320\267\305\320\241")
        list("F12"  "zoom in"                    "\266\324PCB\275\347\303\346\275\370\320\320\267\305\264\363")
        list("Esc"  "done"                       "\275\341\312\370\265\261\307\260\303\374\301\356")

        ; === 编辑操作 ===
        list(" "    "iangle 90"                  "\320\375\327\25290\266\310")
        list("d"    "delete"                     "\311\276\263\375\303\374\301\356")
        list("s"    "move"                       "\322\306\266\257\303\374\301\356")
        list("f"    "slide"                      "\320\336\317\337\303\374\301\356")
        list("b"    "rotate"                     "\320\375\327\252\303\374\301\356")
        list("n"    "mirror"                     "\276\265\317\361\303\374\301\356")
        list("3"    "copy"                       "\270\264\326\306\303\374\301\356")
        list("4"    "change"                     "\270\304\261\344\303\374\301\356")
        list("g"    "toggle"                     "\270\304\261\344\262\274\317\337\267\275\317\362")
        list("m"    "custom smooth"              "\306\275\273\254\303\374\301\356")

        ; === 走线与布线 ===
        list("w"    "add connect"                "\265\347\306\370\327\337\317\337\303\374\301\356")
        list("h"    "add line"                   "\273\255\267\307\265\347\306\370\312\364\320\324\265\304\317\337")
        list("a"    "delay tune"                 "\311\337\320\316\327\337\317\337\265\310\263\244\303\374\301\356")

        ; === 铜皮操作 ===
        list("t"    "shape add"                  "\306\314\315\255\303\374\301\356")
        list("r"    "shape select"               "\321\241\326\320\304\263\270\366\315\255\306\244")
        list("v"    "pop net list"               "\321\241\326\320\315\255\306\244\270\304\261\344\315\255\306\244\315\370\302\347")
        list("e"    "shape edit boundary"        "\261\340\274\255\315\255\306\244\261\337\275\347")
        list("u"    "island_delete"              "\311\276\263\375\271\302\265\272\315\255\306\244")
        list("p"    "shape void polygon"         "\310\316\322\342\320\316\327\264\315\332\277\325")

        ; === 飞线与网络 ===
        list("q"    "rats net"                   "\317\324\312\276\304\263\270\366\315\370\302\347\265\304\267\311\317\337")
        list("1"    "unrats net"                 "\271\330\261\325\304\263\270\366\315\370\302\347\265\304\267\311\317\337")
        list("k"    "net logic"                  "\315\370\302\347\302\337\274\255\267\326\305\344")

        ; === 查看与查询 ===
        list("0"    "status"                     "PCB\311\350\274\306\327\264\314\254\262\351\277\264")
        list("8"    "show measure"               "\262\342\301\277\303\374\301\356")
        list("F4"   "show element"               "\262\351\321\257\303\374\301\356")

        ; === 高亮与颜色 ===
        list("2"    "assign color"               "\270\337\301\301\303\374\301\356")
        list("5"    "dehilight"                  "\265\315\301\301\303\374\301\356")
        list("7"    "color192"                   "\321\325\311\253\271\334\300\355\306\367\277\252\271\330")

        ; === 布局操作 ===
        list("6"    "swap components"            "\275\273\273\273\306\367\274\376")
        list("M"    "ASTB_Route_AutoMatchGroup"  "\264\264\275\250matchgroup")

        ; === 层切换 ===
        list("l"    "ql"                         "\307\320\273\273\265\275\326\270\266\250\262\343")
        list(","    "qu"                         "\307\320\273\273\265\275\317\302\322\273\262\343")
        list("."    "qd"                         "\307\320\273\273\265\275\311\317\322\273\262\343")

        ; === 丝印调整 ===
        list("js"   "ASTB_Text_RefDesCenter"     "\311\350\326\303\327\326\267\373\316\273\326\303\276\323\326\320")
        list("jt"   "ASTB_Util_ViewSilkTop"      "\307\320\273\273\265\275\265\367\325\373\313\277\323\241\266\245\262\343")
        list("jb"   "ASTB_Util_ViewSilkBottom"   "\307\320\273\273\265\275\265\367\325\373\313\277\323\241\265\327\262\343")

        ; === SKILL 调用 ===
        list("jl"   "ASTB_Text_ImportLogo"       "\265\367\323\303Logo Skill")
        list("/"    "ASTB_Util_ChooseGrid"       "\321\241\324\361\325\244\270\361")
        list("?"    "ASTB_Place_ArrowCopy"       "\265\310\276\340\267\275\317\362\274\374\265\310\276\340\270\264\326\306")
        list("jv"   "tvision"                    "\312\261\320\362\312\323\276\365")

        ; === 功能键 ===
        list("F3"   "drc update"                 "\270\374\320\302DRC")
        list("F6"   "ASTB_Place_Align"           "\264\362\277\252\266\324\306\353\306\367\274\376")
        list("F7"   "alnCenterH"                 "\313\256\306\275\276\323\326\320\266\324\306\353")
        list("F8"   "alnCenterV"                 "\264\271\326\261\276\323\326\320\266\324\306\353")

        ; === 切割与对齐 ===
        list("c"    "ASTB_Route_CutLineShape"    "\307\320\317\337\272\315\315\255\306\244")
        list("z"    "prepopup; pop dyn_option_select 'Snap pick to@:@Segment Vertex'" "\266\324\306\353\266\316\266\245\265\343")
    )
)

;------------------------------------------------------------------------
; 函数名  : Init_HotkeySetup
; 功能    : 模块初始化入口（仅打印信息）
; 参数    : 无
; 返回值  : t - 成功
; 说明    : 命令注册统一由文件末尾的 ASTB_RegisterCommand 完成，
;           本函数不再直接调用 axlCmdRegister，避免重复注册。
;------------------------------------------------------------------------
procedure( Init_HotkeySetup()
    printf("[%s] \304\243\277\351\263\365\312\274\273\257\315\352\263\311\243\254\260\346\261\276 %s\n" C_HOTKEY_MODULE g_hotkeySetupVersion)
    printf("[%s] \277\311\323\303\303\374\301\356\243\272hotkey_bind / hotkey_reset / hotkey_help\n" C_HOTKEY_MODULE)
    t
)

;------------------------------------------------------------------------
; 函数名  : HotkeySetup_BindAll
; 功能    : 批量绑定所有快捷键
; 参数    : 无
; 返回值  : t - 绑定完成
; 说明    : 全部键位（含多键序列）经 axlSetFunckey 即时绑定；
;           v2.1 起不写 env，跨会话持久化由 config/hotkeys_user.dat
;           + 启动自动重绑负责。
;------------------------------------------------------------------------
procedure( HotkeySetup_BindAll()
    let((bindCount failCount failList keyName cmdName item f)
        bindCount = 0
        failCount = 0
        failList  = nil

        foreach(item g_hotkeyConfig
            keyName = car(item)
            cmdName = cadr(item)
            if( axlSetFunckey(keyName cmdName) then
                bindCount = bindCount + 1
            else
                failCount = failCount + 1
                failList = cons(sprintf(nil "%s -> %s" keyName cmdName) failList)
            )
        )

        g_hotkeySetupApplied = t
        printf("[%s] \260\363\266\250\315\352\263\311\243\272\146\165\156\143\153\145\171\40\263\311\271\246\40%d\243\254\312\247\260\334\40%d\n"
            C_HOTKEY_MODULE bindCount failCount)
        when( failList
            printf("[%s] \312\247\260\334\303\367\317\270\243\272\n" C_HOTKEY_MODULE)
            foreach(f reverse(failList)
                printf("    %s\n" f)
            )
        )
        t
    )
)

;------------------------------------------------------------------------
; 函数名  : HotkeySetup_ResetAll
; 功能    : 重置所有快捷键绑定（恢复 Allegro 默认）
; 参数    : 无
; 返回值  : t - 重置完成
; 说明    : 清除本模块绑定的所有快捷键（仅当前会话内存解绑；
;           v2.1 起不改 env 文件）。
;------------------------------------------------------------------------
procedure( HotkeySetup_ResetAll()
    let((keyName item)
        foreach(item g_hotkeyConfig
            keyName = car(item)
            axlSetFunckey(keyName nil)
        )
        g_hotkeySetupApplied = nil
        printf("[%s] \313\371\323\320\277\354\275\335\274\374\322\321\326\330\326\303\243\254\307\353\326\330\306\364 Allegro \315\352\310\253\311\372\320\247\n" C_HOTKEY_MODULE)
        t
    )
)

;------------------------------------------------------------------------
; 函数名  : HotkeySetup_PrintHelp
; 功能    : 打印当前快捷键配置表，供用户查阅
; 参数    : 无
; 返回值  : t
;------------------------------------------------------------------------
procedure( HotkeySetup_PrintHelp()
    let((keyName cmdName desc item count)
        printf("\n=== HotkeySetup \277\354\275\335\274\374\305\344\326\303\261\355 v%s ===\n" g_hotkeySetupVersion)
        printf("\274\374\303\373         \303\374\301\356                     \313\265\303\367\n")
        printf("---------------------------------------------------------\n")
        count = 0
        foreach(item g_hotkeyConfig
            keyName = car(item)
            cmdName = cadr(item)
            desc    = caddr(item)
            printf("%-12s %-24s %s\n" keyName cmdName desc)
            count = count + 1
        )
        printf("---------------------------------------------------------\n")
        printf("\271\262 %d \314\365\277\354\275\335\274\374\260\363\266\250\n" count)
        if( g_hotkeySetupApplied then
            printf("\327\264\314\254\243\272\322\321\260\363\266\250\243\250hotkey_bind \322\321\326\264\320\320\243\251\n")
        else
            printf("\327\264\314\254\243\272\316\264\260\363\266\250\243\250\307\353\326\264\320\320 hotkey_bind \303\374\301\356\243\251\n")
        )
        printf("\n\303\374\301\356\313\265\303\367\243\272\n")
        printf("  hotkey_bind  - \260\363\266\250\313\371\323\320\277\354\275\335\274\374\n")
        printf("  hotkey_reset - \326\330\326\303\313\371\323\320\277\354\275\335\274\374\n")
        printf("  hotkey_help  - \317\324\312\276\264\313\260\357\326\372\n")
        t
    )
)

;------------------------------------------------------------------------
; 命令注册（通过工具箱框架延迟注册；纯环境操作，不挂 undo）
;------------------------------------------------------------------------

;========================================================================
; v1.3 快捷键表单编辑器: 表格化编辑 + 应用生效 + 用户配置持久化
;========================================================================
unless(boundp('g_hotkeyConfigFactory)
    g_hotkeyConfigFactory = g_hotkeyConfig    ; 出厂默认表(代码内置)
)
unless(boundp('_hkeForm)    _hkeForm = nil)
unless(boundp('_hkeEntries) _hkeEntries = nil)
unless(boundp('_hkeLastBound) _hkeLastBound = nil)
unless(boundp('_hkePage)    _hkePage = 0)

;------------------------------------------------------------------------
; 函数名  : _HotkeyEditor_DatPath
; 功能    : 用户快捷键配置文件路径 config/hotkeys_user.dat
;------------------------------------------------------------------------
procedure( _HotkeyEditor_DatPath()
    strcat(ASTB_GLOBAL->ConfigPath "/hotkeys_user.dat")
)

;------------------------------------------------------------------------
; 函数名  : _HotkeyEditor_FactoryDatPath
; 功能    : 出厂初始值文件 config/hotkeys_factory.dat
;           (安装 onlyifdoesntexist 不覆盖; “恢复默认”只读它, 不写 Allegro)
;------------------------------------------------------------------------
procedure( _HotkeyEditor_FactoryDatPath()
    strcat(ASTB_GLOBAL->ConfigPath "/hotkeys_factory.dat")
)

;------------------------------------------------------------------------
; 函数名  : _HotkeyEditor_ParseDat
; 功能    : 读一份 dat(键|命令|说明 每行一条) -> list; 无文件/空 -> nil
;------------------------------------------------------------------------
procedure( _HotkeyEditor_ParseDat(path)
    prog((port line parts out)
        unless( isFile(path)
            return(nil)
        )
        port = infile(path)
        unless( port
            return(nil)
        )
        out = nil
        while( gets(line port)
            ; v2.3: 行尾剥 \r(§4.17 CRLF 病), 键/命令为空的行跳过
            when( and( stringp(line) strlen(line) > 0
                       equal(substring(line strlen(line) 1) "\r") )
                line = substring(line 1 strlen(line) - 1)
            )
            parts = parseString(line "|")
            when( and( length(parts) >= 2
                       car(parts) != "" cadr(parts) != "" )
                out = append1(out list(car(parts) cadr(parts)
                    if( length(parts) >= 3 then caddr(parts) else "")))
            )
        )
        close(port)
        return(out)
    )
)

;------------------------------------------------------------------------
; 函数名  : _HotkeyEditor_LoadUser
; 功能    : 启动时加载用户配置覆盖默认表(键|命令|说明 每行一条)
;------------------------------------------------------------------------
procedure( _HotkeyEditor_LoadUser()
    prog((out)
        out = _HotkeyEditor_ParseDat(_HotkeyEditor_DatPath())
        when( out
            g_hotkeyConfig = out
            return(t)
        )
        return(nil)
    )
)

;------------------------------------------------------------------------
; 函数名  : _HotkeyEditor_SaveUser
; 功能    : 保存当前键位表到用户配置文件
;------------------------------------------------------------------------
procedure( _HotkeyEditor_SaveUser()
    prog((path port item)
        path = _HotkeyEditor_DatPath()
        port = outfile(path "w")
        unless( port
            axlUIConfirm("\277\354\275\335\274\374\305\344\326\303\320\264\310\353\312\247\260\334: " path)
            return(nil)
        )
        foreach( item g_hotkeyConfig
            fprintf(port "%s|%s|%s\n" car(item) cadr(item)
                if( length(item) >= 3 then caddr(item) else ""))
        )
        close(port)
        return(t)
    )
)

;------------------------------------------------------------------------
; 函数名  : _HotkeyEditor_BuildForm
; 功能    : 生成编辑器表单: 单栏 18 行/页(删/键/命令/说明全可编辑)
;           + 上一页/下一页/应用/添加行/恢复默认/关闭
; 返回值  : 临时 .form 路径 / nil
; 备注    : STRFILLIN w h = 显示宽 w, 容量 h(v1.3 "20 1" 只装 1 字符的坑);
;           Allegro 表单无原生滚动条, 分页是通用解法
;------------------------------------------------------------------------
procedure( _HotkeyEditor_BuildForm()
  prog((path port r y)
    path = strcat(axlTempFile() ".form")
    port = outfile(path "w")
    unless( port
      return(nil)
    )
    fprintf(port "FILE_TYPE=FORM_DEFN VERSION=2\n")
    fprintf(port "FORM\n")
    fprintf(port "FIXED\n")
    fprintf(port "PORT 76 32\n")
    fprintf(port "HEADER \"\277\354\275\335\274\374\261\340\274\255\306\367 (\270\304\315\352\265\343[\323\246\323\303]\311\372\320\247\262\242\261\243\264\346)\"\n")
    fprintf(port "TILE\n")
    fprintf(port "TEXT \"\274\374\"\n")
    fprintf(port "TLOC 1 1\n")
    fprintf(port "ENDTEXT\n")
    fprintf(port "TEXT \"\303\374\301\356\"\n")
    fprintf(port "TLOC 7 1\n")
    fprintf(port "ENDTEXT\n")
    fprintf(port "TEXT \"\313\265\303\367\"\n")
    fprintf(port "TLOC 32 1\n")
    fprintf(port "ENDTEXT\n")
    fprintf(port "TEXT \"(\307\345\277\325\304\263\320\320\265\304\274\374 = \311\276\263\375\270\303\320\320, \265\343\323\246\323\303\311\372\320\247)\"\n")
    fprintf(port "TLOC 1 2\n")
    fprintf(port "ENDTEXT\n")
    for( r 1 12
      y = 2 + r + r
      fprintf(port "FIELD hke_key_%d\n" r)
      fprintf(port "FLOC 1 %d\n" y)
      fprintf(port "STRFILLIN 5 8\n")
      fprintf(port "ENDFIELD\n")
      fprintf(port "FIELD hke_cmd_%d\n" r)
      fprintf(port "FLOC 7 %d\n" y)
      fprintf(port "STRFILLIN 23 60\n")
      fprintf(port "ENDFIELD\n")
      fprintf(port "FIELD hke_desc_%d\n" r)
      fprintf(port "FLOC 32 %d\n" y)
      fprintf(port "STRFILLIN 42 90\n")
      fprintf(port "ENDFIELD\n")
    )
    y = 28
    fprintf(port "FIELD hke_prev\n")
    fprintf(port "FLOC 1 %d\n" y)
    fprintf(port "MENUBUTTON \"\311\317\322\273\322\263\" 8 2\n")
    fprintf(port "ENDFIELD\n")
    fprintf(port "FIELD hke_page\n")
    fprintf(port "FLOC 10 %d\n" y)
    fprintf(port "STRFILLIN 5 6\n")
    fprintf(port "ENDFIELD\n")
    fprintf(port "FIELD hke_next\n")
    fprintf(port "FLOC 16 %d\n" y)
    fprintf(port "MENUBUTTON \"\317\302\322\273\322\263\" 8 2\n")
    fprintf(port "ENDFIELD\n")
    fprintf(port "FIELD hke_apply\n")
    fprintf(port "FLOC 27 %d\n" y)
    fprintf(port "MENUBUTTON \"\323\246\323\303\" 8 2\n")
    fprintf(port "ENDFIELD\n")
    fprintf(port "FIELD hke_add\n")
    fprintf(port "FLOC 36 %d\n" y)
    fprintf(port "MENUBUTTON \"\314\355\274\323\320\320\" 8 2\n")
    fprintf(port "ENDFIELD\n")
    fprintf(port "FIELD hke_reset\n")
    fprintf(port "FLOC 45 %d\n" y)
    fprintf(port "MENUBUTTON \"\273\326\270\264\304\254\310\317\" 10 2\n")
    fprintf(port "ENDFIELD\n")
    fprintf(port "FIELD hke_close\n")
    fprintf(port "FLOC 56 %d\n" y)
    fprintf(port "MENUBUTTON \"\271\330\261\325\" 8 2\n")
    fprintf(port "ENDFIELD\n")
    fprintf(port "ENDTILE\n")
    fprintf(port "ENDFORM\n")
    close(port)
    return(path)
  )
)
;------------------------------------------------------------------------
; 函数名  : _HotkeyEditor_FillPage
; 功能    : 把 _hkeEntries 当前页(_hkePage)的键位填进 12 行字段
;------------------------------------------------------------------------
procedure( _HotkeyEditor_FillPage()
  prog((r idx item)
    for( r 1 18
      idx = _hkePage * 12 + r
      if( idx <= length(_hkeEntries) then
        item = nth(idx-1 _hkeEntries)
        axlFormSetField(_hkeForm sprintf(nil "hke_key_%d" r) car(item))
        axlFormSetField(_hkeForm sprintf(nil "hke_cmd_%d" r) cadr(item))
        axlFormSetField(_hkeForm sprintf(nil "hke_desc_%d" r)
            if( length(item) >= 3 then caddr(item) else "" ))
      else
        axlFormSetField(_hkeForm sprintf(nil "hke_key_%d" r) "")
        axlFormSetField(_hkeForm sprintf(nil "hke_cmd_%d" r) "")
        axlFormSetField(_hkeForm sprintf(nil "hke_desc_%d" r) "")
      )
    )
    axlFormSetField(_hkeForm "hke_page"
        sprintf(nil "%d/%d" _hkePage+1 (length(_hkeEntries)+11)/12))
    return(t)
  )
)

;------------------------------------------------------------------------
; 函数名  : _HotkeyEditor_MergePage
; 功能    : 合并出完整键位表: 当前页取表单字段值(丢勾删/全空行),
;           其余页原样保留
;------------------------------------------------------------------------
procedure( _HotkeyEditor_MergePage()
  prog((out idx r key cmd desc item)
    out = nil
    for( idx 1 length(_hkeEntries)
      item = nth(idx-1 _hkeEntries)
      r = idx - _hkePage*12
      if( and(r >= 1 r <= 12) then
        key = axlFormGetField(_hkeForm sprintf(nil "hke_key_%d" r)) || ""
        cmd = axlFormGetField(_hkeForm sprintf(nil "hke_cmd_%d" r)) || ""
        desc = axlFormGetField(_hkeForm sprintf(nil "hke_desc_%d" r)) || ""
        ; v2.3: 键字段被表单 trim 空(纯空格键)但命令未改 -> 沿用原键
        when( and( equal(key "") equal(cmd cadr(item)) )
            key = car(item)
        )
        when( or(key != "" cmd != "" desc != "")
          out = append1(out list(key cmd desc))
        )
      else
        out = append1(out item)
      )
    )
    return(out)
  )
)

;------------------------------------------------------------------------
; 函数名  : _HotkeyEditor_Show
; 功能    : 创建并显示编辑器表单(一次创建, 翻页只重填不重建)
;------------------------------------------------------------------------
procedure( _HotkeyEditor_Show()
  prog((path fm)
    when( and(_hkeForm errset(axlIsFormType(_hkeForm) nil))
      errset(axlFormClose(_hkeForm) t)
      _hkeForm = nil
    )
    _hkeEntries = g_hotkeyConfig
    _hkePage = 0
    path = _HotkeyEditor_BuildForm()
    unless( path
      axlUIConfirm("\277\354\275\335\274\374\261\340\274\255\306\367\261\355\265\245\311\372\263\311\312\247\260\334")
      return(nil)
    )
    fm = axlFormCreate((gensym) path '("NE" "msglines" 0)
        '_HotkeyEditor_Callback t)
    unless( fm
      axlUIConfirm("\277\354\275\335\274\374\261\340\274\255\306\367\261\355\265\245\264\264\275\250\312\247\260\334")
      errset(deleteFile(path) t)
      return(nil)
    )
    _hkeForm = fm
    _HotkeyEditor_FillPage()
    axlFormDisplay(fm)
    errset(deleteFile(path) t)
    return(t)
  )
)

;------------------------------------------------------------------------
; 函数名  : _HotkeyEditor_FactoryReset
; 功能    : 恢复出厂键位（编辑器“恢复默认”与 Studio 桥接共用入口）
; 说明    : v2.0 新增。旧路径只 BindAll 重绑出厂键，用户在出厂表之外
;           新增的键当前会话内不解绑（“重置没用”的根因）。此处先对
;           旧配置中存在、出厂表中不存在的键做 axlSetFunckey(key nil)
;           解绑，再恢复出厂表、保存 dat、重绑（v2.1 起不写 env，
;           持久化全靠 hotkeys_user.dat + 启动自动重绑）。
;------------------------------------------------------------------------
; 恢复初始值到内存表: 只载入 hotkeys_factory.dat(无则用内置出厂表),
; 不写 user.dat、不 BindAll -- Allegro 侧键位保持不动, 由“应用”统一下发
procedure( _HotkeyEditor_RestoreDefaults()
    prog((fac)
        fac = _HotkeyEditor_ParseDat(_HotkeyEditor_FactoryDatPath())
        if( fac
        then g_hotkeyConfig = fac
        else g_hotkeyConfig = g_hotkeyConfigFactory
        )
        return(t)
    )
)

; 应用: 持久化当前表到 user.dat 并重新绑定 Allegro(先解绑多余键)
procedure( _HotkeyEditor_Apply()
    let((item)
        foreach(item _hkeLastBound
            unless( exists(f g_hotkeyConfig equal(car(f) car(item)))
                axlSetFunckey(car(item) nil)
            )
        )
        _HotkeyEditor_SaveUser()
        HotkeySetup_BindAll()
        _hkeLastBound = g_hotkeyConfig
        t
    )
)

; 编辑器“恢复默认”按钮: 恢复初始值并立即应用(写+绑), 一步到位
procedure( _HotkeyEditor_FactoryReset()
    _HotkeyEditor_RestoreDefaults()
    _HotkeyEditor_Apply()
)

;------------------------------------------------------------------------
; 函数名  : _HotkeyEditor_Callback
; 功能    : 翻页/应用/添加行/恢复默认/关闭 的分派
;------------------------------------------------------------------------
(defun _HotkeyEditor_Callback (fm)
(prog (maxPage)
    maxPage = (length(_hkeEntries)+11)/12 - 1
    case( fm->curField
        ("hke_prev"
            _hkeEntries = _HotkeyEditor_MergePage()
            _hkePage = max(0 _hkePage-1)
            _HotkeyEditor_FillPage()
        )
        ("hke_next"
            _hkeEntries = _HotkeyEditor_MergePage()
            maxPage = (length(_hkeEntries)+11)/12 - 1
            _hkePage = min(maxPage _hkePage+1)
            _HotkeyEditor_FillPage()
        )
        ("hke_apply"
            g_hotkeyConfig = _HotkeyEditor_MergePage()
            _hkeEntries = g_hotkeyConfig
            _HotkeyEditor_Apply()
            _HotkeyEditor_FillPage()
            axlUIWPrint(nil sprintf(nil "\277\354\275\335\274\374\322\321\323\246\323\303\262\242\261\243\264\346 (%d \314\365)"
                length(g_hotkeyConfig)))
        )
        ("hke_add"
            _hkeEntries = _HotkeyEditor_MergePage()
            _hkeEntries = append1(_hkeEntries list("" "" ""))
            g_hotkeyConfig = _hkeEntries
            _hkePage = (length(_hkeEntries)+11)/12 - 1
            _HotkeyEditor_FillPage()
        )
        ("hke_reset"
            _HotkeyEditor_RestoreDefaults()
            _hkeEntries = g_hotkeyConfig
            _hkePage = 0
            _HotkeyEditor_FillPage()
            axlUIWPrint(nil "\322\321\273\326\270\264\304\254\310\317\274\374\316\273\262\242\326\330\320\302\323\246\323\303")
        )
        ("hke_close"
            axlFormClose(fm)
            _hkeForm = nil
        )
    )
    return()
))

;------------------------------------------------------------------------
; 函数名  : HotkeySetup_Edit
; 功能    : 菜单/命令入口: 打开快捷键表单编辑器
;------------------------------------------------------------------------
procedure( HotkeySetup_Edit()
    _HotkeyEditor_Show()
)

;; 启动时: 加载用户配置并自动绑定, 实现跨会话持久化(v2.2 修复)
errset(
    when( _HotkeyEditor_LoadUser()
        HotkeySetup_BindAll()
    )
nil)

ASTB_RegisterCommand("hotkey_bind"  "HotkeySetup_BindAll"
    ?cmdType "general" ?undo nil)
ASTB_RegisterCommand("hotkey_reset" "HotkeySetup_ResetAll"
    ?cmdType "general" ?undo nil)
ASTB_RegisterCommand("hotkey_restore" "_HotkeyEditor_RestoreDefaults"
    ?cmdType "general" ?undo nil)
ASTB_RegisterCommand("hotkey_apply" "_HotkeyEditor_Apply"
    ?cmdType "general" ?undo nil)
ASTB_RegisterCommand("hotkey_help"  "HotkeySetup_PrintHelp"
    ?cmdType "general" ?undo nil)
ASTB_RegisterCommand("hotkey_edit"  "HotkeySetup_Edit"
    ?cmdType "general" ?undo nil)

printf("[ASTB] util_hotkeysetup.il loaded.\n")
