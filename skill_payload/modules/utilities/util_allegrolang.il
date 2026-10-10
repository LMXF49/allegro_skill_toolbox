;========================================================================
; 文件名    : modules/utilities/util_allegrolang.il
; 作者      : ASTB Team
; 创建日期  : 2026-10-11
; 版本      : 1.0
; 功能描述  : 语言切换联动 Allegro 本体界面语言（System->Language
;             切工具箱语言时由 core/menu.il ASTB_SetLanguage 调用）：
;             Allegro X（22.1/23.1/24.1/25.1）写 pcbenv env 偏好
;             allegro_enable_localization（开）/ allegro_english_menu
;             （关，其默认 on 会把菜单锁英文）；17.2/17.4 写用户环境
;             变量 intl_enabled=yes（部分汉化，17.4 需 019+ 补丁），
;             切回英文时 reg delete 清除；16.6 无官方机制仅提示。
;             两条机制按持久化设置各写各的（多版本共用一套 HOME/
;             用户环境变量，一次联动全部版本生效）；均需重启 Allegro
; 依赖模块  : core/version_adapter.il（ASTB_VersionContains）
; 编码      : GBK（含中文字符串）
; 修改记录  :
;   2026-10-11 v1.0 ASTB Team 初始创建（用户要求：语言切换联动
;                Allegro 本体界面；机制来源：24.1 prfedit/ui.prf 的
;                allegro_enable_localization/allegro_english_menu
;                偏好项，17.4 社区方案 intl_enabled=yes）
;========================================================================

;------------------------------------------------------------------------
; 函数名  : _ALG_Setx / _ALG_RegDelete
; 功能    : 经 ipcBeginProcess 写/删用户级环境变量（HKCU\Environment），
;           异步不阻塞不等待；errset 包裹，失败仅记日志
; 备注    : 进程级 setShellEnvVar 不持久化且对当前进程已晚，故走
;           setx/reg（与 util_openstudio.il 同款的进程拉起方式）
;------------------------------------------------------------------------
procedure( _ALG_Setx(name value)
    prog((cid)
        cid = errset(ipcBeginProcess("setx" strcat(name " " value) nil nil nil "") t)
        unless( cid
            ASTB_LogWarn(strcat("allegrolang: setx failed for " name))
        )
        return( and(cid t) )
    )
)

procedure( _ALG_RegDelete(name)
    prog((cid)
        cid = errset(ipcBeginProcess("reg"
            strcat("delete HKCU\\Environment /v " name " /f") nil nil nil "") t)
        unless( cid
            ASTB_LogWarn(strcat("allegrolang: reg delete failed for " name))
        )
        return( and(cid t) )
    )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_AllegroLangApply
; 功能    : 按目标语言联动 Allegro 本体界面语言（持久化设置，
;           重启 Allegro 生效；当前会话界面不变）
; 参数    : lang - "zh-CN" / "en"
; 返回值  : 一行中文结果说明（供 ASTB_SetLanguage 汇总进确认框）
; 备注    :  env 偏好与 intl_enabled 两条机制都写（多版本共用 HOME
;           与用户环境变量，各自读各自的）；全部 errset 包裹，
;           单项失败不阻断其余
;------------------------------------------------------------------------
procedure( ASTB_AllegroLangApply(lang)
    prog((zh msg)
        zh = equal(lang "zh-CN")
        if( zh then
            ;; Allegro X 系列：env 偏好（EFF_ONRESTART）
            ;; allegro_english_menu 默认 on 会把菜单锁英文，必须一并摘除
            errset(axlSetVariableFile("allegro_enable_localization" t) t)
            errset(axlUnsetVariableFile("allegro_english_menu") t)
            ;; 17.2/17.4：用户环境变量（部分汉化；17.4 需 019+ 补丁）
            _ALG_Setx("intl_enabled" "yes")
            msg = "Allegro \275\347\303\346: \322\321\301\252\266\257\316\252\326\320\316\304\243\25024.1+ \327\337\261\276\265\330\273\257\306\253\272\303\243\25417.x \327\337 intl_enabled\243\251\243\254\326\330\306\364 Allegro \311\372\320\247"
        else
            errset(axlUnsetVariableFile("allegro_enable_localization") t)
            errset(axlUnsetVariableFile("allegro_english_menu") t)
            _ALG_RegDelete("intl_enabled")
            _ALG_RegDelete("intl_show_bilingual")
            msg = "Allegro \275\347\303\346: \322\321\301\252\266\257\316\252\323\242\316\304\243\250\261\276\265\330\273\257\306\253\272\303\323\353 intl_enabled \322\321\307\345\263\375\243\251\243\254\326\330\306\364 Allegro \311\372\320\247"
        )
        ASTB_LogInfo(strcat("allegrolang: applied " lang))
        ;; 16.6 无官方汉化机制，附注说明
        when( ASTB_IsVersion166()
            msg = strcat(msg "\243\273\265\261\307\260 16.6 \316\336\271\331\267\275\272\272\273\257\273\372\326\306\243\254\275\347\303\346\261\243\263\326\323\242\316\304")
        )
        return(msg)
    )
)

printf("[ASTB] util_allegrolang.il v1.0 loaded\n")
