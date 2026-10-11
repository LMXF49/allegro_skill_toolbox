;========================================================================
; 文件名    : modules/utilities/util_allegrolang.il
; 作者      : ASTB Team
; 创建日期  : 2026-10-11
; 版本      : 1.9
; 功能描述  : Allegro 本体界面语言设置（System->Allegro UI 子菜单
;             独立入口，与工具箱菜单语言切换解耦）：
;             Allegro X（22.1/23.1/24.1/25.1）写 pcbenv env 偏好
;             allegro_enable_localization（开）/ allegro_english_menu
;             （关，其默认 on 会把菜单锁英文）；17.2/17.4 写用户环境
;             变量改经 pcbenv env 手改区文本增删 set intl_enabled = yes
;             （Qt 面板部分汉化）；16.6 无官方机制仅提示。
;             两条机制按持久化设置各写各的（多版本共用一套 HOME/
;             用户环境变量，一次联动全部版本生效）；均需重启 Allegro
; 依赖模块  : core/version_adapter.il（ASTB_VersionContains）
; 编码      : GBK（含中文字符串）
; 修改记录  :
;   2026-10-11 v1.9 ASTB Team 17.x 机制实机简化（用户实机验证）：
;                intl_enabled 经 pcbenv env 手改区文本增删即生效，
;                拆除 system()/setx/reg/广播整条注册表路线
;   2026-10-11 v1.8 ASTB Team 切英文不生效修复：reg delete 不广播
;                WM_SETTINGCHANGE，explorer 缓存仍带旧值（新启
;                Allegro 继承残留）；删除后 outfile 写 ps1 + system
;                全路径 powershell 补发环境变更广播
;   2026-10-11 v1.7 ASTB Team 实机定案：本机 17.4 ipcBeginProcess
;                只建通道不执行进程（裸名/全路径同，注册表无变化），
;                改 system() 全路径直调 setx/reg（rc=0 实查注册表
;                确认落盘）；v1.2~v1.6 各写盘方案均已回退
;   2026-10-11 v1.1 ASTB Team 与工具箱菜单语言切换解耦：新增独立
;                命令入口 ASTB_SetAllegroLangEnglish/Chinese
;                （menu.il v4.5 起 ASTB_SetLanguage 不再调用本模块）
;   2026-10-11 v1.0 ASTB Team 初始创建（用户要求：语言切换联动
;                Allegro 本体界面；机制来源：24.1 prfedit/ui.prf 的
;                allegro_enable_localization/allegro_english_menu
;                偏好项，17.4 社区方案 intl_enabled=yes）
;========================================================================

;------------------------------------------------------------------------
; 函数名  : _ALG_EnvFile / _ALG_EnvSetIntl
; 功能    : 17.x 界面语言设置：%HOME%/pcbenv/env 手改区文本增删
;           set intl_enabled = yes（用户实机验证此路生效），纯文件
;           读写，重启 Allegro 生效
; 备注    : 替代注册表 setx/reg 路线（本机 ipcBeginProcess 不执行
;           进程、reg delete 不广播环境变更，v1.7/v1.8 已弃）；
;           gets 读行保留 \n，原样写回
;------------------------------------------------------------------------
procedure( _ALG_EnvFile()
    prog((home)
        home = getShellEnvVar("HOME")
        unless( home return(nil) )
        return( strcat(home "/pcbenv/env") )
    )
)

procedure( _ALG_EnvSetIntl(on)
    prog((path port line kept out inserted)
        path = _ALG_EnvFile()
        unless( and(path isFile(path))
            ASTB_LogWarn("allegrolang: env file not found")
            return(nil)
        )
        ;; 读全行并过滤掉已有 intl_enabled 行（幂等）
        port = infile(path)
        unless( port return(nil) )
        while( gets(line port)
            unless( rexMatchp("^[ \t]*set[ \t]+intl_enabled[ \t=]" line)
                kept = nconc(kept list(line))
            )
        )
        close(port)
        ;; 切中文时在 source $TELENV 后补回该行（手改区）
        out = kept
        when( on
            out = nil
            foreach( line kept
                out = nconc(out list(line))
                when( and(not(inserted) rexMatchp("^[ \t]*source[ \t]+" line))
                    out = nconc(out list("set intl_enabled = yes\n"))
                    inserted = t
                )
            )
            unless( inserted
                out = nconc(list("set intl_enabled = yes\n") kept)
            )
        )
        port = outfile(path)
        unless( port
            ASTB_LogWarn("allegrolang: cannot write env")
            return(nil)
        )
        foreach( line out fprintf(port "%s" line) )
        close(port)
        ASTB_LogInfo(sprintf(nil "allegrolang: env intl_enabled on=%L" on))
        return(t)
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
            ;; 17.2/17.4：env 手改区写 set intl_enabled = yes（Qt 面板部分汉化）
            _ALG_EnvSetIntl(t)
            msg = "Allegro 界面语言 -> 中文（24.1+ 本地化偏好，17.x intl_enabled），重启 Allegro 生效"
        else
            errset(axlUnsetVariableFile("allegro_enable_localization") t)
            errset(axlUnsetVariableFile("allegro_english_menu") t)
            ;; 17.2/17.4：从 env 手改区删除 intl_enabled 行
            _ALG_EnvSetIntl(nil)
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

printf("[ASTB] util_allegrolang.il v1.9 loaded\n")
