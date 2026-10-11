;========================================================================
; 文件名    : modules/utilities/util_allegrolang.il
; 作者      : ASTB Team
; 创建日期  : 2026-10-11
; 版本      : 1.8
; 功能描述  : Allegro 本体界面语言设置（System->Allegro UI 子菜单
;             独立入口，与工具箱菜单语言切换解耦）：
;             Allegro X（22.1/23.1/24.1/25.1）写 pcbenv env 偏好
;             allegro_enable_localization（开）/ allegro_english_menu
;             （关，其默认 on 会把菜单锁英文）；17.2/17.4 写用户环境
;             变量 intl_enabled=yes（Qt 面板部分汉化），
;             切回英文时 reg delete 清除；16.6 无官方机制仅提示。
;             两条机制按持久化设置各写各的（多版本共用一套 HOME/
;             用户环境变量，一次联动全部版本生效）；均需重启 Allegro
; 依赖模块  : core/version_adapter.il（ASTB_VersionContains）
; 编码      : GBK（含中文字符串）
; 修改记录  :
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
; 函数名  : _ALG_WinExe / _ALG_Setx / _ALG_RegDelete
; 功能    : 经 system() 全路径直调 setx/reg 写/删用户级环境变量
;           （HKCU\Environment），非零返回码记日志
; 备注    : 进程级 setShellEnvVar 不持久化且对当前进程已晚，故走
;           setx/reg；本机 17.4 实机定案：ipcBeginProcess 只建通道
;           不执行进程，system() 全路径可落盘；命令无引号嵌套、
;           路径无空格，避开 pitfalls §6.1 两个 system() 坑
;------------------------------------------------------------------------
procedure( _ALG_WinExe(name)
    prog((root)
        root = getShellEnvVar("SystemRoot")
        unless( root root = "C:\\Windows" )
        return( strcat(root "\\System32\\" name) )
    )
)

procedure( _ALG_Setx(name value)
    prog((rc)
        rc = system(strcat(_ALG_WinExe("setx.exe") " " name " " value))
        when( rc != 0
            ASTB_LogWarn(sprintf(nil "allegrolang: setx %s rc=%d" name rc))
        )
        return( rc == 0 )
    )
)

procedure( _ALG_RegDelete(name)
    prog((rc)
        rc = system(strcat(_ALG_WinExe("reg.exe")
            " delete HKCU\\Environment /v " name " /f"))
        when( rc != 0
            ASTB_LogWarn(sprintf(nil "allegrolang: reg delete %s rc=%d" name rc))
        )
        return( rc == 0 )
    )
)

;------------------------------------------------------------------------
; 函数名  : _ALG_BroadcastEnv
; 功能    : 补发 WM_SETTINGCHANGE 环境变更广播（reg delete 不广播，
;           否则 explorer 缓存环境仍带旧值，新启 Allegro 继承残留）
; 备注    : outfile 写 ps1 再 system 全路径 powershell 执行，
;           命令行无引号嵌套（ps1 内容走文件不经命令行）
;------------------------------------------------------------------------
procedure( _ALG_BroadcastEnv()
    prog((tmp ps1 port rc)
        tmp = getShellEnvVar("TEMP")
        unless( tmp tmp = "C:\\Windows\\Temp" )
        ps1 = strcat(tmp "\\astb_alg_bcast.ps1")
        port = outfile(ps1)
        unless( port
            ASTB_LogWarn("allegrolang: cannot write broadcast ps1")
            return(nil)
        )
        fprintf(port "%s\n" "Add-Type -Namespace Win32 -Name NativeMethods -MemberDefinition '[DllImport(\"user32.dll\", SetLastError=true, CharSet=CharSet.Auto)] public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);'")
        fprintf(port "%s\n" "$HWND_BROADCAST = [IntPtr]0xffff")
        fprintf(port "%s\n" "$WM_SETTINGCHANGE = 0x1A")
        fprintf(port "%s\n" "$result = [UIntPtr]::Zero")
        fprintf(port "%s\n" "[void][Win32.NativeMethods]::SendMessageTimeout($HWND_BROADCAST, $WM_SETTINGCHANGE, [UIntPtr]::Zero, \"Environment\", 2, 5000, [ref]$result)")
        close(port)
        rc = system(strcat(_ALG_WinExe("WindowsPowerShell\\v1.0\\powershell.exe")
            " -NoProfile -ExecutionPolicy Bypass -File " ps1))
        when( rc != 0
            ASTB_LogWarn(sprintf(nil "allegrolang: broadcast rc=%d" rc))
        )
        return( rc == 0 )
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
            msg = "Allegro 界面语言 -> 中文（24.1+ 本地化偏好，17.x intl_enabled），重启 Allegro 生效"
        else
            errset(axlUnsetVariableFile("allegro_enable_localization") t)
            errset(axlUnsetVariableFile("allegro_english_menu") t)
            _ALG_RegDelete("intl_enabled")
            _ALG_RegDelete("intl_show_bilingual")
            ;; reg delete 不广播环境变更，补广播刷新 explorer 缓存
            _ALG_BroadcastEnv()
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

printf("[ASTB] util_allegrolang.il v1.8 loaded\n")
