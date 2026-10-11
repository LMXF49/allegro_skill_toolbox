;========================================================================
; 文件名    : modules/utilities/util_allegrolang.il
; 作者      : ASTB Team
; 创建日期  : 2026-10-11
; 版本      : 1.6
; 功能描述  : Allegro 本体界面语言设置（System->Allegro UI 子菜单
;             独立入口，与工具箱菜单语言切换解耦）：
;             Allegro X（22.1/23.1/24.1/25.1）写 pcbenv env 偏好
;             allegro_enable_localization（开）/ allegro_english_menu
;             （关，其默认 on 会把菜单锁英文）；17.2/17.4 写用户环境
;             变量 intl_enabled=yes（Qt 界面部分汉化，字典为
;             share/i18n/dict/allegrodict_zh.qm；经典菜单栏保持英文），
;             切回英文时 reg delete 清除；16.6 无官方机制仅提示。
;             两条机制按持久化设置各写各的（多版本共用一套 HOME/
;             用户环境变量，一次联动全部版本生效）；均需重启 Allegro
; 依赖模块  : core/version_adapter.il（ASTB_VersionContains）
; 编码      : GBK（含中文字符串）
; 修改记录  :
;   2026-10-11 v1.6 ASTB Team 用户决策：写盘回退 v1.0 形式
;                （ipcBeginProcess 异步直起，不等待不验证，失败仅
;                记日志）；保留全路径 exe 修正（裸命令名实机不起
;                进程）；提示附手动兜底命令
;   2026-10-11 v1.5 ASTB Team 实机不生效修复：裸命令名不起进程
;                （reg query 连 log 都没生成），改全路径 System32 exe
;                + cmd.exe /c bat 回退；回读三态杜绝假成功
;   2026-10-11 v1.4 ASTB Team 实机卡死修复：ipcWait/ipcGetExitStatus
;                本机挂住 Allegro（切英文卡死）；改直起进程不等待，
;                sleep 后 reg query 落 log 回读验证，成败如实返回
;   2026-10-11 v1.3 ASTB Team 实机报错修复：errset 返回值是 list，
;                cid/rc 先 car 再喂 ipcWait/ipcGetExitStatus（v1.2
;                直接传 list 报 type template "oxx"）
;   2026-10-11 v1.2 ASTB Team 修复 17.x 切换无效：setx/reg 改 ipc
;                四件套（ipcWait+退出码校验，v1.1 异步起进程实机
;                不落盘）；提示逐条如实反映写入成败；汉化范围勘正
;                为 Qt 界面部分汉化（share/i18n/dict/allegrodict_zh.qm）
;   2026-10-11 v1.1 ASTB Team 与工具箱菜单语言切换解耦：新增独立
;                命令入口 ASTB_SetAllegroLangEnglish/Chinese
;                （menu.il v4.5 起 ASTB_SetLanguage 不再调用本模块）
;   2026-10-11 v1.0 ASTB Team 初始创建（用户要求：语言切换联动
;                Allegro 本体界面；机制来源：24.1 prfedit/ui.prf 的
;                allegro_enable_localization/allegro_english_menu
;                偏好项，17.4 社区方案 intl_enabled=yes）
;========================================================================

;------------------------------------------------------------------------
; 函数名  : _ALG_WinExe / _ALG_Setx / _ALG_RegDelete
; 功能    : 经 ipcBeginProcess 写/删用户级环境变量（HKCU\Environment），
;           异步不阻塞不等待（v1.0 形式，用户决策回退）；errset
;           包裹，失败仅记日志
; 备注    : 进程级 setShellEnvVar 不持久化且对当前进程已晚，故走
;           setx/reg；exe 用全路径（裸命令名实机不起进程——v1.5
;           取证：reg query 连 log 文件都没生成）
;------------------------------------------------------------------------
procedure( _ALG_WinExe(name)
    prog((root)
        root = getShellEnvVar("SystemRoot")
        unless( root root = "C:\\Windows" )
        return( strcat(root "\\System32\\" name) )
    )
)

procedure( _ALG_Setx(name value)
    prog((cid)
        cid = errset(ipcBeginProcess(_ALG_WinExe("setx.exe")
            strcat(name " " value) nil nil nil "") t)
        unless( cid
            ASTB_LogWarn(strcat("allegrolang: setx failed for " name))
        )
        return( and(cid t) )
    )
)

procedure( _ALG_RegDelete(name)
    prog((cid)
        cid = errset(ipcBeginProcess(_ALG_WinExe("reg.exe")
            strcat("delete HKCU\\Environment /v " name " /f") nil nil nil "") t)
        unless( cid
            ASTB_LogWarn(strcat("allegrolang: reg delete failed for " name))
        )
        return( and(cid t) )
    )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_AllegroLangApply
; 功能    : 设置 Allegro 本体界面语言（持久化设置，重启 Allegro
;           生效；当前会话界面不变）
; 参数    : lang - "zh-CN" / "en"
; 返回值  : 结果说明（供命令入口弹确认框）
; 备注    : env 偏好与 intl_enabled 两条机制都写（多版本共用 HOME
;           与用户环境变量，各自读各自的）；errset 包裹单项失败
;           不阻断其余
;------------------------------------------------------------------------
procedure( ASTB_AllegroLangApply(lang)
    prog((zh msg)
        zh = equal(lang "zh-CN")
        if( zh then
            ;; Allegro X 系列：env 偏好（EFF_ONRESTART）
            ;; allegro_english_menu 默认 on 会把菜单锁英文，必须一并摘除
            errset(axlSetVariableFile("allegro_enable_localization" t) t)
            errset(axlUnsetVariableFile("allegro_english_menu") t)
            ;; 17.2/17.4：用户环境变量（Qt 界面部分汉化）
            _ALG_Setx("intl_enabled" "yes")
            msg = "Allegro 界面语言 -> 中文（24.1+ 本地化偏好，17.x intl_enabled），重启 Allegro 生效"
            msg = strcat(msg "\n若重启后 17.x 未生效，请手动执行: setx intl_enabled yes")
        else
            errset(axlUnsetVariableFile("allegro_enable_localization") t)
            errset(axlUnsetVariableFile("allegro_english_menu") t)
            _ALG_RegDelete("intl_enabled")
            _ALG_RegDelete("intl_show_bilingual")
            msg = "Allegro 界面语言 -> English（本地化偏好与 intl_enabled 已清除），重启 Allegro 生效"
        )
        ASTB_LogInfo(strcat("allegrolang: applied " lang))
        ;; 16.6 无官方汉化机制，附注说明
        when( ASTB_IsVersion166()
            msg = strcat(msg "；当前 16.6 无官方汉化机制，界面保持英文")
        )
        return(msg)
    )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_SetAllegroLanguage
; 功能    : Allegro 界面语言设置命令入口（System->Allegro UI 子菜单）
; 参数    : lang - "zh-CN" / "en"
; 返回值  : t
;------------------------------------------------------------------------
procedure( ASTB_SetAllegroLanguage(lang)
    prog((msg)
        msg = ASTB_AllegroLangApply(lang)
        axlUIConfirm(msg)
        return(t)
    )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_SetAllegroLangEnglish / ASTB_SetAllegroLangChinese
; 功能    : Allegro 界面语言切换命令入口
; 返回值  : t
;------------------------------------------------------------------------
procedure( ASTB_SetAllegroLangEnglish()
    ASTB_SetAllegroLanguage("en")
)

procedure( ASTB_SetAllegroLangChinese()
    ASTB_SetAllegroLanguage("zh-CN")
)

printf("[ASTB] util_allegrolang.il v1.6 loaded\n")
