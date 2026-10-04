;========================================================================
; 文件名    : modules/utilities/util_downrev166.il
; 作者      : ASTB Team
; 创建日期  : 2026-10-04
; 版本      : 1.6
; 功能描述  : PCB 降版本保存为 16.6（全新重写版，取代 util_downrev17）。
;             主路（17.2/17.4 会话）：调用工具箱自带免补丁运行时
;             tools/downrev166_rt（allegro_downrev_library.exe +
;             自有 DLL，转换时该目录置顶 PATH；DOWNREV_17_TO_16=1
;             放开 brd/dra），复制 <板名>_166.brd 副本后原地转
;             16.6，原文件不动。
;             24.x/25.x 会话：两跳——新实例批处理（当前版本
;             allegro.exe -s 回放脚本开临时副本，原生 Downrev
;             对话框选 "Save design to 17.4" 存中间文件，再由主路
;             exe 直转 16.6。注意：24.x 写出的 17.4 是 dbstat 仍
;             显示 17.4 的新修订，2019 时代的免补丁 exe 可能打不
;             开（32000016, 实测）。
;             v1.5 起双转换器（主备互换）：主转换器为官方 17.4 adl
;             补丁版 adl_patched（11 字节补丁可复现, 配方见
;             _DR166_FindADLPatched 注释；24.x 新修订可读, 底面焊盘
;             层已实证正确）；adl 失败自动回落电路精灵/阿狸狗免补丁
;             构建。ASTB_DOWNREV_EXE 环境变量指定仍最优先。
;             v1.6: adl_patched 迁入 rt bin 与自带 DLL 同目录,
;             解除 SPB_17.4 安装依赖(免装 17.4 的机器可用, 已实证)。
;             与旧版(util_downrev17 v3.x)差异：
;             1) 拆除会话内宏回放兜底，不再占用用户会话弹对话框
;             2) 失败不弹窗：仅命令行留痕，原因留在输出目录同名 .log
;             3) 16.6 会话内直接提示无需转换
; 依赖模块  : core/utils.il、core/trans.il；
;             tools/downrev166_rt/（免补丁转换运行时 exe+DLL）
;             tools/downrev166_rt/tools/bin/adl_patched.exe（主升转换器,
;             与该目录 DLL 自包含, 免装 SPB_17.4）
; 编码      : GBK（含中文注释）
; 修改记录  :
;   2026-10-04 v1.0 ASTB Team 全新重写上线：保留旧版验证过的三个核心
;             机制（免补丁运行时+PATH 置顶、临时副本避开 .lck 与空格
;             路径、新实例批处理第一跳），拆除会话内回放兜底与数据
;             桥死代码；失败路径全部改为命令行留痕不弹窗
;   2026-10-04 v1.1 ASTB Team 24.x/25.x 链路加 S019 中间跳（用户
;             实机反馈 24.1 另存后第二跳失败：24.x 对话框存的 17.4
;             为 24.x 写出的 17.4 新修订, 免补丁 exe 拒转 32000016,
;             实测仅认 17.4 对话框 save6 的 S019 修订）；未装
;             SPB_17.4 时降级为直转并命令行告警
;   2026-10-04 v1.2 ASTB Team 术语与实证修正：用户指出 "17.4 (22.1)"
;             指 22.1 可打开的 17.4、不是 22.1 版本——dbstat 实测
;             对话框产物确为 17.4, 与 exe 日志抬头 "Downrev rev
;             17.4 to rev 16.6" 一致；32000016 真因是 24.x 写入
;             修订新于 17.4-2019(S019), 非版本不符。全文用语同步
;             改述, 功能逻辑不变
;   2026-10-04 v1.3 ASTB Team 按用户决策撤掉 S019 中间跳，24.x 恢复
;             两跳直通；删 _DR166_FindMid174Allegro/_DR166_MidHop174;
;             第二跳失败时自动识别日志 32000016(24.x 新修订拒转)并
;             给手工重存指引，其余失败保持通用提示
;   2026-10-04 v1.4 ASTB Team 双转换器接线：主转换器 32000016 拒转
;             时自动回落 tools/adl_patched.exe 重转（需 SPB_17.4
;             DLL 环境, 警告底面焊盘风险）；破解配方实证可复现：
;             官方 17.4 allegro_downrev_library.exe 的 file offset
;             315270 起 5 字节 + 315278 起 6 字节改 0x90(NOP 掉
;             SYExit 闸门), 产物 md5=90867801dcefb88cdc1de7bf73a1e07e
;             ——2026-10-04 实机验证通过（用户确认：24.1 板两跳
;             +adl 回落重转成功出 _166.brd, 底面贴片焊盘层核对正确）
;   2026-10-04 v1.5 ASTB Team 按用户决策主备互换：主转换器改为官方
;             17.4 adl 补丁版（读写面宽），电路精灵/阿狸狗免补丁构
;             建降为 adl 失败兜底；ASTB_DOWNREV_EXE 环境变量指定仍
;             最优先；adl 每次会话首用命令行提示抽查底面焊盘
;   2026-10-04 v1.6 ASTB Team 解除 SPB_17.4 依赖：实证 adl_patched
;             只吃 downrev166_rt 自带 DLL 即可转换新修订文件
;             (D:\Temp\dr_test, total converted 1); adl 迁入
;             tools/downrev166_rt/tools/bin/ 同目录解析抗 PATH 污染;
;             删 _DR166_FindSPB174Bin(SPB_17.4 不再是任何前置)
; 实机待验证:
;   1) 24.1/25.1 新实例批处理第一跳（downrev 对话框 save7 + fillin
;      喂路径）：旧版 24.1 S006 验证过，25.1 未回归
;   2) 17.4-2019 实例中间跳（save6 重存 S019）：旧版 v3.2 实测过,
;      本重写版未回归（v1.3 起中间跳已撤, 此条仅存档）
;   3) adl_patched 回落路径：2026-10-04 实机通过, 底面贴片焊盘层
;      用户已于 16.6 核对正确（RK3588 旧版曾实测翻转, 转后抽查
;      底面保留为建议习惯）
;   4) v1.5 主备互换（adl 主升 + rt 兜底）: 2026-10-04 起待实机,
;      重点看 adl 直接跑 17.x 原生板与 rt 兜底触发场景
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
; 函数名  : _DR166_FindADLPatched
; 功能    : 定位官方 17.4 adl 补丁版（tools/adl_patched.exe, 兜底
;           转换器）
; 返回值  : exe 路径 / nil
; 备注    : 主转换器（电路精灵/阿狸狗构建）认不得 24.x 新修订
;           (32000016) 时回落用；已知风险：底面贴片引脚层可能搬到
;           顶部（旧版 v3.1 RK3588 实测）, 故只作兜底并强制警告。
;           破解配方可复现：官方 17.4 allegro_downrev_library.exe
;           的 file offset 315270 起 5 字节与 315278 起 6 字节改
;           0x90（NOP 掉 SYExit 闸门调用）, 产物 md5=
;           90867801dcefb88cdc1de7bf73a1e07e
;------------------------------------------------------------------------
procedure( _DR166_FindADLPatched()
    prog((cand)
        cand = strcat(ASTB_GLOBAL->ToolboxPath
                "/tools/downrev166_rt/tools/bin/adl_patched.exe")
        when( isFile(cand)
            ASTB_DebugLog(strcat("Downrev166: adl_patched from toolbox " cand))
            return(cand)
        )
        ASTB_DebugLog("Downrev166: adl_patched NOT found")
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
; 函数名  : _DR166_LogHasCode
; 功能    : 扫描日志文件是否含指定错误码子串
; 参数    : logPath - 日志路径; code - 错误码子串(如 "32000016")
; 返回值  : t / nil
;------------------------------------------------------------------------
procedure( _DR166_LogHasCode(logPath code)
    prog((port line hit)
        hit = nil
        port = infile(logPath)
        when( port
            while( gets(line port)
                when( rexMatchp(code line)
                    hit = t
                )
            )
            close(port)
        )
        return(hit)
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
procedure( _DR166_RunExe(exe dir name brd @optional (pathPrepend nil))
    prog((outPath batPath logPath port ok sideLog pp)
        outPath = _DR166_OutputPath(dir name "166")
        ;; 先复制副本，exe 原地转换副本，源文件零风险
        ok = errset(axlOSFileCopy(brd outPath nil) t)
        unless( and(ok car(ok))
            axlMsgPut(strcat("Downrev166: \264\264\275\250\312\344\263\366\270\261\261\276\312\247\260\334: " outPath))
            return(nil)
        )
        batPath = strcat(axlTempDirectory() "/dr166_run.bat")
        logPath = strcat(axlTempDirectory() "/dr166_log.txt")
        port = outfile(batPath "w")
        unless( port
            axlMsgPut("Downrev166: \316\336\267\250\264\264\275\250\301\331\312\261 bat \316\304\274\376")
            return(nil)
        )
        fprintf(port "@echo off\r\n")
        fprintf(port "set \"DOWNREV_17_TO_16=1\"\r\n")
        ;; 自带运行时必须配自有 DLL 目录置顶 PATH(实测混用 17.4 会话
        ;; DLL 时 exe 静默退出, 零日志); pathPrepend 显式指定优先
        pp = pathPrepend
        unless( pp
          when( rexMatchp("downrev166_rt" exe)
            pp = strcat(ASTB_GLOBAL->ToolboxPath
                         "/tools/downrev166_rt/tools/bin")
          )
        )
        when( pp
          fprintf(port "set \"PATH=%s;%%PATH%%\"\r\n" pp)
        )
        fprintf(port "\"%s\" \"%s\" > \"%s\" 2>&1\r\n" exe outPath logPath)
        close(port)
        axlMsgPut("\325\375\324\332\275\265\260\346\261\276\327\252\273\273, \264\363\311\350\274\306\277\311\304\334\320\350\322\252\312\375\267\326\326\323, \307\353\265\310\264\375...")
        ASTB_DebugLog(strcat("Downrev166: run bat out=" outPath))
        system(strcat("cmd /c \"" batPath "\""))
        ASTB_DebugLog("Downrev166: bat done")
        if( and(isFile(logPath) _DR166_LogConverted(logPath))
        then
            axlUIConfirm(strcat("\275\265\260\346\261\276\263\311\271\246!\n\n16.6 \316\304\274\376:\n" outPath "\n\n(\327\252\273\273\273\341\266\252\312\247 17.x \320\302\314\330\320\324\312\375\276\335, \307\353\324\332 16.6 \326\320\264\362\277\252\274\354\262\351)"))
            return(t)
        else
            ;; 具体原因在输出同名 .log，失败只命令行留痕不弹窗
            sideLog = strcat(substring(outPath 1 strlen(outPath)-4) ".log")
            ;; 删除未转换的副本（它只是源文件的复制品，非转换产物）
            when( isFile(outPath)
                errset(deleteFile(outPath) t)
            )
            if( and(isFile(sideLog) _DR166_LogHasCode(sideLog "32000016")) then
                ;; 24.x 新修订拒转: 交由 _DR166_RunExeSmart 决定回落重转
                return('revfail)
            else
                axlMsgPut(strcat("\275\265\260\346\261\276\312\247\260\334: \311\350\274\306\272\254 16.6 \262\273\326\247\263\326\265\304\314\330\320\324, \317\352\274\373 " sideLog))
                return(nil)
            )
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
      axlMsgPut("Downrev166: \316\264\325\322\265\275\265\261\307\260\260\346\261\276\265\304 allegro.exe, \316\336\267\250\327\324\266\257\264\346 17.4 \326\320\274\344\316\304\274\376")
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
      axlMsgPut(strcat("Downrev166: \324\264\260\345\301\331\312\261\270\264\326\306\312\247\260\334: " tmpIn))
      return(nil)
    )
    ;; 回放脚本: 对话框存 17.4, fillin 喂输出路径, exit 自动退出
    scrPath = strcat(axlTempDirectory() "/dr174_hop.scr")
    port = outfile(scrPath "w")
    unless( port
      axlMsgPut("Downrev166: \316\336\267\250\264\264\275\250\301\331\312\261\275\305\261\276\316\304\274\376")
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
      axlMsgPut("Downrev166: \316\336\267\250\264\264\275\250\301\331\312\261 bat \316\304\274\376")
      return(nil)
    )
    fprintf(port "@echo off\r\n")
    fprintf(port "\"%s\" -s \"%s\" \"%s\"\r\n" exe scrPath tmpIn)
    close(port)
    axlMsgPut("\265\332\322\273\314\370: \320\302\312\265\300\375\305\372\264\246\300\355\264\346 17.4(\324\274 1 \267\326\326\323, \307\353\311\324\272\362)...")
    ASTB_DebugLog(strcat("Downrev166: batch hop exe=" exe " in=" tmpIn))
    ;; 非阻塞启动(start 立即返回), 轮询最多 120s 等中间文件
    system(strcat("cmd /c start \"\" \"" batPath "\""))
    n = 0
    while( and(null(isFile(tmp174)) n < 120)
      sleep(1)
      n = n+1
    )
    unless( isFile(tmp174)
      axlMsgPut("Downrev166: \265\332\322\273\314\370\305\372\264\246\300\355\263\254\312\261(120s \316\264\263\366 17.4 \316\304\274\376), \322\321\307\345\300\355\301\331\312\261\274\376")
      axlMsgPut("Downrev166: \307\353\312\326\266\257\323\303 File > Export > Downrev design \264\346 17.4 \272\363, \265\275 17.4 \300\357\324\331\326\264\320\320\261\276\303\374\301\356")
      foreach( f list(tmpIn scrPath batPath)
        errset(deleteFile(f) t)
      )
      return(nil)
    )
    ;; 拷回目标目录并清理临时件
    ok = errset(axlOSFileCopy(tmp174 path174 nil) t)
    unless( and(ok car(ok))
      axlMsgPut(strcat("Downrev166: \326\320\274\344\316\304\274\376\277\275\273\330\312\247\260\334: " path174))
      return(nil)
    )
    foreach( f list(tmpIn tmp174 scrPath batPath)
      errset(deleteFile(f) t)
    )
    axlMsgPut("\265\332\322\273\314\370\315\352\263\311(\320\302\312\265\300\375\305\372\264\246\300\355)\241\243")
    return(path174)
  )
)

;------------------------------------------------------------------------
; 函数名  : _DR166_RunExeSmart
; 功能    : RunExe 智能包装：主转换器 32000016 拒转(24.x 新修订)
;           时自动回落官方 17.4 adl 补丁版重转(SPB_17.4 DLL 环境),
;           并警告其底面焊盘翻转风险; 兜底不可用时给手工指引
; 参数    : 同 _DR166_RunExe
; 返回值  : t 成功 / nil 失败
;------------------------------------------------------------------------
procedure( _DR166_RunExeSmart(exe dir name brd)
    prog((r adl rtbin env)
        ;; 1) 环境变量显式指定: 最优先, 只用它
        env = getShellEnvVar("ASTB_DOWNREV_EXE")
        when( and(env isFile(env))
            return( _DR166_RunExe(exe dir name brd) )
        )
        ;; 2) 主转换器: 官方 17.4 adl 补丁版(配自带 rt DLL, 免装 SPB_17.4)
        adl = _DR166_FindADLPatched()
        if( adl then
            unless( boundp('ASTB_DOWNREV166_ADLWARN) defvar(ASTB_DOWNREV166_ADLWARN nil) )
            unless( ASTB_DOWNREV166_ADLWARN
                axlMsgPut("\314\341\312\276: \326\367\327\252\273\273\306\367\316\252\271\331\267\275 17.4 adl \262\271\266\241\260\346, \265\327\303\346\314\371\306\254\272\270\305\314\262\343\327\252\272\363\275\250\322\351\324\332 16.6 \263\351\262\351")
                ASTB_DOWNREV166_ADLWARN = t
            )
            rtbin = strcat(ASTB_GLOBAL->ToolboxPath
                    "/tools/downrev166_rt/tools/bin")
            r = _DR166_RunExe(adl dir name brd rtbin)
            when( equal(r t) return(t) )
            axlMsgPut("Downrev166: adl \262\271\266\241\260\346\327\252\273\273\312\247\260\334, \263\242\312\324\303\342\262\271\266\241\324\313\320\320\312\261\266\265\265\327...")
        else
            axlMsgPut("Downrev166: \316\264\325\322\265\275 adl_patched.exe, \326\261\275\323\323\303\303\342\262\271\266\241\324\313\320\320\312\261")
        )
        ;; 3) 兜底: 电路精灵/阿狸狗免补丁构建
        r = _DR166_RunExe(exe dir name brd)
        when( equal(r t) return(t) )
        when( r == 'revfail
            axlMsgPut(strcat("\312\326\271\244\264\246\300\355: \323\303 17.4 \264\362\277\252 " brd " \276\255 File>Export>Downrev design \321\241 17.4(17.4-2019) \326\330\264\346, \324\331\323\332 17.4 \273\341\273\260\326\330\305\334\261\276\303\374\301\356")) )
        nil
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
            axlUIConfirm("\265\261\307\260\311\350\274\306\311\320\316\264\261\243\264\346\316\252 .brd \316\304\274\376, \307\353\317\310\261\243\264\346")
            return(nil)
        )
        ;; 16.6 会话无需转换
        ver = _DR166_TVersion()
        when( rexMatchp("16\\.6" ver)
            axlMsgPut("Downrev166: \265\261\307\260\322\321\312\307 16.6 \273\341\273\260, \316\336\320\350\275\265\260\346\261\276")
            return(nil)
        )
        exe = _DR166_FindExe()
        ASTB_DebugLog(strcat("Downrev166: brd=" brd " exe=" if( exe then exe else "nil")))
        unless( exe
            axlUIConfirm("\316\264\325\322\265\275\275\265\260\346\261\276\324\313\320\320\312\261 tools/downrev166_rt\241\243\n\307\353\326\330\320\302\260\262\327\260\271\244\276\337\317\344, \273\362\260\321\260\262\327\260\304\277\302\274 skill/tools/downrev166_rt\n\325\373\270\366\270\264\326\306\265\275\261\276\271\244\276\337\317\344 tools/ \317\302\324\331\312\324\241\243")
            return(nil)
        )
        unless( axlUIYesNo(strcat("\275\253\317\310\261\243\264\346\265\261\307\260\311\350\274\306, \324\331\265\274\263\366 16.6 \270\261\261\276\265\275:\n" dir "\n\n\274\314\320\370?"))
            return(nil)
        )
        unless( errset(axlSaveDesign() t)
            axlUIConfirm("\261\243\264\346\311\350\274\306\312\247\260\334, \275\265\260\346\261\276\326\320\326\271")
            return(nil)
        )
        ASTB_DebugLog(strcat("Downrev166: ver=" ver " exe=" exe))
        if( and(ver != "" rexMatchp("17" ver)) then
            ;; 17.2/17.4 会话：免补丁 exe 直转
            return( _DR166_RunExeSmart(exe dir name brd) )
        else
            ;; 23.1/24.1/25.1 等会话：新实例批处理存 17.4 中间文件再转（两跳）
            ;; 24.x 写出的 17.4 是新修订, 第二跳可能 32000016, 失败按命令行指引手工处理
            path174 = _DR166_HopTo174(dir name brd)
            unless( path174 return(nil) )
            axlMsgPut("\265\332\266\376\314\370: 17.4 -> 16.6 \327\252\273\273\326\320...")
            return( _DR166_RunExeSmart(exe dir name path174) )
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
            axlUIConfirm("\275\265\260\346\261\276\271\246\304\334\304\332\262\277\264\355\316\363(\322\321\320\264\265\367\312\324\310\325\326\276)\241\243\n\307\353\275\253 config/astb_debug.log \304\251\316\262\304\332\310\335\267\264\300\241\316\254\273\244\327\351")
        )
        return(ret)
    )
)

ASTB_RegisterCommand("ASTB_Util_Downrev166" "ASTB_Util_Downrev166" ?cmdType "interactive")

printf("[ASTB] util_downrev166.il loaded.\n")
