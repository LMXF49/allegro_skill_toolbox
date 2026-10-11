;========================================================================
; 文件名    : modules/utilities/util_allegrolang.il
; 作者      : ASTB Team
; 创建日期  : 2026-10-11
; 版本      : 1.4
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
; 函数名  : _ALG_Spawn / _ALG_RegHas / _ALG_Setx / _ALG_RegDelete
; 功能    : 写/删用户级环境变量（HKCU\Environment）：ipcBeginProcess
;           直起进程不等待（v1.3 的 ipcWait/ipcGetExitStatus 实机把
;           Allegro 卡死），sleep 后用 reg query 落 log 文件回读
;           验证，成败如实返回
; 备注    : 进程级 setShellEnvVar 不持久化且对当前进程已晚，故走
;           setx/reg；errset 返回值是 list，cid 要 car（v1.2 教训）
;------------------------------------------------------------------------
procedure( _ALG_Spawn(cmd args logF)
    prog((r)
        r = errset(ipcBeginProcess(cmd args nil nil nil logF) t)
        unless( and(r car(r))
            ASTB_LogWarn(strcat("allegrolang: spawn failed: " cmd " " args))
            return(nil)
        )
        return(t)
    )
)

procedure( _ALG_RegHas(name)
    prog((tmp logF port line found)
        tmp = getShellEnvVar("TEMP")
        unless( tmp tmp = "C:\\Windows\\Temp" )
        logF = strcat(tmp "\\astb_alg_regquery.log")
        when( isFile(logF) deleteFile(logF) )
        unless( _ALG_Spawn("reg" strcat("query HKCU\\Environment /v " name) logF)
            return(nil)
        )
        sleep(2)
        found = nil
        when( isFile(logF)
            port = infile(logF)
            when( port
                while( gets(line port)
                    when( rexMatchp("REG_SZ" line) found = t )
                )
                close(port)
            )
        )
        return(found)
    )
)

procedure( _ALG_Setx(name value)
    prog((ok)
        ok = _ALG_Spawn("setx" strcat(name " " value) "")
        unless( ok return(nil) )
        sleep(1)
        return( _ALG_RegHas(name) )
    )
)

procedure( _ALG_RegDelete(name)
    prog((ok)
        ok = _ALG_Spawn("reg" strcat("delete HKCU\\Environment /v " name " /f") "")
        unless( ok return(nil) )
        sleep(1)
        return( not(_ALG_RegHas(name)) )
    )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_AllegroLangApply
; 功能    : 设置 Allegro 本体界面语言（持久化设置，
;           重启 Allegro 生效；当前会话界面不变）
; 参数    : lang - "zh-CN" / "en"
; 返回值  : 多行中文结果说明（逐条如实反映各机制写入成败）
; 备注    :  env 偏好与 intl_enabled 两条机制都写（多版本共用 HOME
;           与用户环境变量，各自读各自的）；全部 errset 包裹，
;           单项失败不阻断其余
;------------------------------------------------------------------------
procedure( ASTB_AllegroLangApply(lang)
    prog((zh okX ok17 msg)
        zh = equal(lang "zh-CN")
        if( zh then
            ;; Allegro X 系列：env 偏好（EFF_ONRESTART）
            ;; allegro_english_menu 默认 on 会把菜单锁英文，必须一并摘除
            okX = and( errset(axlSetVariableFile("allegro_enable_localization" t) t)
                       errset(axlUnsetVariableFile("allegro_english_menu") t) )
            ;; 17.2/17.4：用户环境变量（Qt 界面部分汉化）
            ok17 = _ALG_Setx("intl_enabled" "yes")
            msg = "Allegro \275\347\303\346\323\357\321\324 -> \326\320\316\304\243\250\326\330\306\364 Allegro \272\363\311\372\320\247\243\251\n"
            if( okX
            then msg = strcat(msg "  24.1+: \261\276\265\330\273\257\306\253\272\303\322\321\320\264\310\353 env\n")
            else msg = strcat(msg "  24.1+: \306\253\272\303\320\264\310\353\312\247\260\334\243\254\307\353\312\326\266\257 Setup->Preferences \271\264\321\241 Use local language\n")
            )
            if( ok17
            then msg = strcat(msg "  17.2/17.4: intl_enabled=yes \322\321\320\264\310\353\243\250Qt \275\347\303\346\262\277\267\326\272\272\273\257\243\251\n")
            else msg = strcat(msg "  17.x: \320\264\310\353\312\247\260\334\243\254\307\353\312\326\266\257\326\264\320\320 setx intl_enabled yes\n")
            )
        else
            okX = and( errset(axlUnsetVariableFile("allegro_enable_localization") t)
                       errset(axlUnsetVariableFile("allegro_english_menu") t) )
            ok17 = and( _ALG_RegDelete("intl_enabled")
                        _ALG_RegDelete("intl_show_bilingual") )
            msg = "Allegro \275\347\303\346\323\357\321\324 -> English\243\250\326\330\306\364 Allegro \272\363\311\372\320\247\243\251\n"
            if( okX
            then msg = strcat(msg "  24.1+: \261\276\265\330\273\257\306\253\272\303\322\321\307\345\263\375\n")
            else msg = strcat(msg "  24.1+: \306\253\272\303\307\345\263\375\312\247\260\334\243\254\307\353\312\326\266\257 Setup->Preferences \310\241\317\373 Use local language\n")
            )
            msg = strcat(msg "  17.x: intl_enabled \322\321\307\345\263\375\n")
        )
        ASTB_LogInfo(sprintf(nil "allegrolang: applied %s okX=%L ok17=%L" lang okX ok17))
        ;; 16.6 无官方汉化机制，附注说明
        when( ASTB_IsVersion166()
            msg = strcat(msg "  \265\261\307\260 16.6 \316\336\271\331\267\275\272\272\273\257\273\372\326\306\243\254\275\347\303\346\261\243\263\326\323\242\316\304\n")
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

printf("[ASTB] util_allegrolang.il v1.4 loaded\n")
