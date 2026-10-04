;========================================================================
; 文件名    : modules/utilities/util_downrev166.il
; 作者      : ASTB Team
; 创建日期  : 2026-10-04
; 版本      : 1.0
; 功能描述  : PCB 降版本保存为 16.6（全新重写版，取代 util_downrev17）。
;             主路（17.2/17.4 会话）：调用工具箱自带免补丁运行时
;             tools/downrev166_rt（allegro_downrev_library.exe +
;             自有 DLL，转换时该目录置顶 PATH；DOWNREV_17_TO_16=1
;             放开 brd/dra），复制 <板名>_166.brd 副本后原地转
;             16.6，原文件不动。
;             24.x/25.x 会话：两跳——新实例批处理（当前版本
;             allegro.exe -s 回放脚本开临时副本，原生 Downrev
;             对话框选 "Save design to 17.4" 存中间文件）再走主路。
;             与旧版(util_downrev17 v3.x)差异：
;             1) 拆除会话内宏回放兜底，不再占用用户会话弹对话框
;             2) 失败不弹窗：仅命令行留痕，原因留在输出目录同名 .log
;             3) 16.6 会话内直接提示无需转换
; 依赖模块  : core/utils.il、core/trans.il；
;             tools/downrev166_rt/（免补丁转换运行时 exe+DLL）
; 编码      : GBK（含中文注释）
; 修改记录  :
;   2026-10-04 v1.0 ASTB Team 全新重写上线：保留旧版验证过的三个核心
;             机制（免补丁运行时+PATH 置顶、临时副本避开 .lck 与空格
;             路径、新实例批处理第一跳），拆除会话内回放兜底与数据
;             桥死代码；失败路径全部改为命令行留痕不弹窗
; 实机待验证:
;   1) 24.1/25.1 新实例批处理第一跳（downrev 对话框 save7 + fillin
;      喂路径）：旧版 24.1 S006 验证过，25.1 未回归
;========================================================================

;------------------------------------------------------------------------
; 函数名  : _DR166_TVersion
; 功能    : 取当前会话版本字符串（fullVersion 优先，tVersion 兜底）
; 返回值  : 版本字符串 / ""
;------------------------------------------------------------------------
procedure( _DR166_TVersion()
    prog((r v)
        ;; fullVersion 为 version_adapter 实证可用选择子，优先使用
        r = errset(v = axlVersion('fullVersion) t)
        if( and(r car(r) stringp(car(r))) then
            return( car(r) )
        )
        r = errset(v = axlVersion('tVersion) t)
        if( and(r v stringp(v)) then return(v) else return("") )
    )
)

;------------------------------------------------------------------------
; 函数名  : _DR166_FindExe
; 功能    : 定位降版本转换 exe（自带免补丁运行时）
; 返回值  : exe 路径 / nil
; 优先级  : ASTB_DOWNREV_EXE 环境变量 > 工具箱 tools/downrev166_rt
;------------------------------------------------------------------------
procedure( _DR166_FindExe()
  prog((cand rt)
    ;; 1) 环境变量显式指定优先(用户自备转换器时使用)
    cand = getShellEnvVar("ASTB_DOWNREV_EXE")
    when( and(cand isFile(cand))
      ASTB_DebugLog(strcat("Downrev166: exe from env " cand))
      return(cand)
    )
    ;; 2) 工具箱自带免补丁运行时(唯一默认路径; 旧 adl_patched 已弃用
    ;;    ——官方17.4 adl 补丁版会把底面贴片引脚翻到顶层)
    rt = strcat(ASTB_GLOBAL->ToolboxPath
                "/tools/downrev166_rt/tools/bin/allegro_downrev_library.exe")
    when( isFile(rt)
      ASTB_DebugLog(strcat("Downrev166: exe from toolbox rt " rt))
      return(rt)
    )
    ASTB_DebugLog("Downrev166: downrev166_rt runtime NOT found")
    return(nil)
  )
)

;------------------------------------------------------------------------
; 函数名  : _DR166_OutputPath
; 功能    : 生成 <名>_<后缀>.brd 输出路径，重名自动加 _2.._9 序号
; 参数    : dir - 目录; name - 板名; suffix - 后缀(默认 "166")
; 返回值  : 输出路径
;------------------------------------------------------------------------
procedure( _DR166_OutputPath(dir name @optional (suffix "166"))
    prog((outPath n)
        outPath = strcat(dir "/" name "_" suffix ".brd")
        n = 1
        while( and(isFile(outPath) n < 9)
            n = n+1
            outPath = strcat(dir "/" name "_" suffix "_" sprintf(nil "%d" n) ".brd")
        )
        return(outPath)
    )
)

;------------------------------------------------------------------------
; 函数名  : _DR166_LogConverted
; 功能    : 解析 exe 日志，判断 total converted 是否非零
; 返回值  : t / nil
;------------------------------------------------------------------------
procedure( _DR166_LogConverted(logPath)
    prog((port line ok)
        ok = nil
        port = infile(logPath)
        when( port
            while( gets(line port)
                when( rexMatchp("total converted: *[1-9]" line)
                    ok = t
                )
            )
            close(port)
        )
        return(ok)
    )
)

;------------------------------------------------------------------------
; 函数名  : _DR166_RunExe
; 功能    : 主路：复制副本 -> bat 调 exe（DOWNREV_17_TO_16=1）-> 校验
; 参数    : exe - 转换 exe 路径; dir - 设计目录; name - 板名;
;           brd - 源 brd 路径（17.x 格式）
; 返回值  : t 成功 / nil 失败
; 备注    : 失败不弹窗：仅命令行留痕；exe 的具体原因写在输出目录
;           同名 .log（stdout 只有结论），需人工查看
;------------------------------------------------------------------------
procedure( _DR166_RunExe(exe dir name brd)
    prog((outPath batPath logPath port ok sideLog)
        outPath = _DR166_OutputPath(dir name "166")
        ;; 先复制副本，exe 原地转换副本，源文件零风险
        ok = errset(axlOSFileCopy(brd outPath nil) t)
        unless( and(ok car(ok))
            axlMsgPut(strcat("Downrev166: 创建输出副本失败: " outPath))
            return(nil)
        )
        batPath = strcat(axlTempDirectory() "/dr166_run.bat")
        logPath = strcat(axlTempDirectory() "/dr166_log.txt")
        port = outfile(batPath "w")
        unless( port
            axlMsgPut("Downrev166: 无法创建临时 bat 文件")
            return(nil)
        )
        fprintf(port "@echo off\r\n")
        fprintf(port "set \"DOWNREV_17_TO_16=1\"\r\n")
        ;; 自带运行时必须配自有 DLL 目录置顶 PATH(实测混用 17.4 会话
        ;; DLL 时 exe 静默退出, 零日志); 外部 exe 环境自管
        when( rexMatchp("downrev166_rt" exe)
          fprintf(port "set \"PATH=%s;%%PATH%%\"\r\n"
                   strcat(ASTB_GLOBAL->ToolboxPath
                           "/tools/downrev166_rt/tools/bin"))
        )
        fprintf(port "\"%s\" \"%s\" > \"%s\" 2>&1\r\n" exe outPath logPath)
        close(port)
        axlMsgPut("正在降版本转换, 大设计可能需要数分钟, 请等待...")
        ASTB_DebugLog(strcat("Downrev166: run bat out=" outPath))
        system(strcat("cmd /c \"" batPath "\""))
        ASTB_DebugLog("Downrev166: bat done")
        if( and(isFile(logPath) _DR166_LogConverted(logPath))
        then
            axlUIConfirm(strcat("降版本成功!\n\n16.6 文件:\n" outPath "\n\n(转换会丢失 17.x 新特性数据, 请在 16.6 中打开检查)"))
            return(t)
        else
            ;; 具体原因在输出同名 .log，失败只命令行留痕不弹窗
            sideLog = strcat(substring(outPath 1 strlen(outPath)-4) ".log")
            axlMsgPut(strcat("降版本失败: 设计含 16.6 不支持的特性, 详见 " sideLog))
            ;; 删除未转换的副本（它只是源文件的复制品，非转换产物）
            when( isFile(outPath)
                errset(deleteFile(outPath) t)
            )
            return(nil)
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : _DR166_FindAllegroExe
; 功能    : 定位当前会话版本自带的 allegro.exe（新实例批处理用）
; 返回值  : exe 路径 / nil
; 备注    : 按运行版本号找 SPB_<ver>（17.4/24.1 目录布局不同两处都
;           试），再退回 CDSROOT；会话 CDSROOT 可能指到别的版本安装
;           (本机 CDSROOT=SPB_16.6 实证)，故按版本号优先
;------------------------------------------------------------------------
procedure( _DR166_FindAllegroExe()
  prog((tv ver roots cdsroot r cand)
    tv = _DR166_TVersion()
    ver = nil
    foreach( v '("25.1" "24.1" "23.1" "22.1" "17.4" "17.2")
      when( and(null(ver) rexMatchp(v tv))
        ver = v
      )
    )
    roots = nil
    when( ver
      foreach( d '("D:/Cadence" "C:/Cadence")
        roots = cons(strcat(d "/SPB_" ver) roots)
      )
    )
    cdsroot = getShellEnvVar("CDSROOT")
    when( and(cdsroot null(member(axlOSSlash(cdsroot) roots)))
      roots = append1(roots axlOSSlash(cdsroot))
    )
    foreach( r roots
      foreach( cand list(
          strcat(r "/tools/bin/allegro.exe")
          strcat(r "/tools/pcb/bin/allegro.exe"))
        when( isFile(cand)
          return(cand)
        )
      )
    )
    return(nil)
  )
)

;------------------------------------------------------------------------
; 函数名  : _DR166_HopTo174
; 功能    : 第一跳新实例批处理：起当前版本 allegro.exe -s 回放脚本，
;           开源板的临时副本，原生 Downrev 对话框存 17.4 中间文件，
;           实例自动退出；全程不占用户会话
; 参数    : dir/name/brd - 工作目录/设计名/源 brd 路径(当前版本格式)
; 返回值  : 17.4 中间文件路径 / nil(失败)
; 备注    : 临时目录纯 ASCII 无空格(规避文件对话框对空格/中文路径
;           截断)；输入先拷临时副本避开用户会话 .lck 锁；非阻塞启动
;           + 轮询 120s 防实例挂起；超时/失败只命令行留痕并清理，
;           不再回退会话内回放
;------------------------------------------------------------------------
procedure( _DR166_HopTo174(dir name brd)
  prog((exe path174 tmpIn tmp174 scrPath batPath port n ok)
    exe = _DR166_FindAllegroExe()
    unless( exe
      ASTB_DebugLog("Downrev166: allegro.exe not found, hop unavailable")
      axlMsgPut("Downrev166: 未找到当前版本的 allegro.exe, 无法自动存 17.4 中间文件")
      return(nil)
    )
    path174 = _DR166_OutputPath(dir name "174")
    ;; 输入先拷临时副本: 避开用户会话 .lck 锁 + 空格/中文路径
    tmpIn = strcat(axlTempDirectory() "/" name "_hopin.brd")
    tmp174 = strcat(axlTempDirectory() "/" name "_174.brd")
    foreach( f list(tmpIn tmp174)
      when( isFile(f) errset(deleteFile(f) t) )
    )
    ok = errset(axlOSFileCopy(brd tmpIn nil) t)
    unless( and(ok car(ok))
      axlMsgPut(strcat("Downrev166: 源板临时复制失败: " tmpIn))
      return(nil)
    )
    ;; 回放脚本: 对话框存 17.4, fillin 喂输出路径, exit 自动退出
    scrPath = strcat(axlTempDirectory() "/dr174_hop.scr")
    port = outfile(scrPath "w")
    unless( port
      axlMsgPut("Downrev166: 无法创建临时脚本文件")
      return(nil)
    )
    fprintf(port "scriptmode +i\n")
    fprintf(port "downrev\n")
    fprintf(port "setwindow form.downrev\n")
    fprintf(port "FORM downrev save7\n")
    fprintf(port "FORM downrev save\n")
    fprintf(port "fillin \"%s\"\n" tmp174)
    fprintf(port "exit\n")
    close(port)
    batPath = strcat(axlTempDirectory() "/dr174_hop.bat")
    port = outfile(batPath "w")
    unless( port
      axlMsgPut("Downrev166: 无法创建临时 bat 文件")
      return(nil)
    )
    fprintf(port "@echo off\r\n")
    fprintf(port "\"%s\" -s \"%s\" \"%s\"\r\n" exe scrPath tmpIn)
    close(port)
    axlMsgPut("第一跳: 新实例批处理存 17.4(约 1 分钟, 请稍候)...")
    ASTB_DebugLog(strcat("Downrev166: batch hop exe=" exe " in=" tmpIn))
    ;; 非阻塞启动(start 立即返回), 轮询最多 120s 等中间文件
    system(strcat("cmd /c start \"\" \"" batPath "\""))
    n = 0
    while( and(null(isFile(tmp174)) n < 120)
      sleep(1)
      n = n+1
    )
    unless( isFile(tmp174)
      axlMsgPut("Downrev166: 第一跳批处理超时(120s 未出 17.4 文件), 已清理临时件")
      axlMsgPut("Downrev166: 请手动用 File > Export > Downrev design 存 17.4 后, 到 17.4 里再执行本命令")
      foreach( f list(tmpIn scrPath batPath)
        errset(deleteFile(f) t)
      )
      return(nil)
    )
    ;; 拷回目标目录并清理临时件
    ok = errset(axlOSFileCopy(tmp174 path174 nil) t)
    unless( and(ok car(ok))
      axlMsgPut(strcat("Downrev166: 中间文件拷回失败: " path174))
      return(nil)
    )
    foreach( f list(tmpIn tmp174 scrPath batPath)
      errset(deleteFile(f) t)
    )
    axlMsgPut("第一跳完成(新实例批处理)。")
    return(path174)
  )
)

;------------------------------------------------------------------------
; 函数名  : _DR166_Main
; 功能    : 降版本主流程：校验 -> 确认 -> 保存 -> 17.x 直转 / 24.x 两跳
; 返回值  : t 成功 / nil 失败或取消
;------------------------------------------------------------------------
procedure( _DR166_Main()
    prog((dir name brd exe ver path174)
        name = axlCurrentDesign()
        dir  = getWorkingDir()
        brd  = strcat(dir "/" name ".brd")
        unless( isFile(brd)
            axlUIConfirm("当前设计尚未保存为 .brd 文件, 请先保存")
            return(nil)
        )
        ;; 16.6 会话无需转换
        ver = _DR166_TVersion()
        when( rexMatchp("16\\.6" ver)
            axlMsgPut("Downrev166: 当前已是 16.6 会话, 无需降版本")
            return(nil)
        )
        exe = _DR166_FindExe()
        ASTB_DebugLog(strcat("Downrev166: brd=" brd " exe=" if( exe then exe else "nil")))
        unless( exe
            axlUIConfirm("未找到降版本运行时 tools/downrev166_rt。\n请重新安装工具箱, 或把安装目录 skill/tools/downrev166_rt\n整个复制到本工具箱 tools/ 下再试。")
            return(nil)
        )
        unless( axlUIYesNo(strcat("将先保存当前设计, 再导出 16.6 副本到:\n" dir "\n\n继续?"))
            return(nil)
        )
        unless( errset(axlSaveDesign() t)
            axlUIConfirm("保存设计失败, 降版本中止")
            return(nil)
        )
        ASTB_DebugLog(strcat("Downrev166: ver=" ver " exe=" exe))
        if( and(ver != "" rexMatchp("17" ver)) then
            ;; 17.2/17.4 会话：免补丁 exe 直转
            return( _DR166_RunExe(exe dir name brd) )
        else
            ;; 23.1/24.1/25.1 等会话：新实例批处理存 17.4 中间文件再转
            path174 = _DR166_HopTo174(dir name brd)
            unless( path174 return(nil) )
            axlMsgPut("第二跳: 17.4 -> 16.6 转换中...")
            return( _DR166_RunExe(exe dir name path174) )
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_Util_Downrev166
; 功能    : 菜单入口（errset 外壳）：任何内部错误弹窗提示看日志，
;           不再静默死亡
;------------------------------------------------------------------------
procedure( ASTB_Util_Downrev166()
    prog((ret)
        ASTB_DebugLog("Downrev166: entry")
        ret = errset(_DR166_Main() t)
        unless( ret
            axlUIConfirm("降版本功能内部错误(已写调试日志)。\n请将 config/astb_debug.log 末尾内容反馈维护组")
        )
        return(ret)
    )
)

ASTB_RegisterCommand("ASTB_Util_Downrev166" "ASTB_Util_Downrev166" ?cmdType "interactive")

printf("[ASTB] util_downrev166.il loaded.\n")
