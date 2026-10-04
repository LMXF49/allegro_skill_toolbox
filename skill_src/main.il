;========================================================================
; 文件名    : main.il
; 作者      : allegro_skill 项目组
; 创建日期  : 2026-06-06
; 版本      : 2.2.9
; 功能描述  : allegro_skill 主入口：定位安装路径、加载核心库与模块、
;             注册命令并注入菜单
; 依赖模块  : core/loader.il 及 core/ 下全部核心库
; 编码      : GBK（含中文注释）
; 修改记录  :
;   2026-06-06 v2.2   allegro_skill 项目组 初始创建
;   2026-07-17 v2.2.1 修复组_框架核心 修复防重复加载 guard（改为 if/else
;                     包裹文件全部主体）；FORMPATH 的 errset 返回值取 car；
;                     ASTB_INITIALIZED 改为全部步骤成功后置位且每步检查
;                     errset 返回值；调试日志硬编码路径改为相对
;                     ConfigPath（未初始化时退回系统临时目录）；
;                     axlUIWTimerAdd 第三参改 t（单次触发）
;   2026-07-25 v2.2.2 ASTB 项目组 步骤9注入失败时延时重试（最多
;                     3 次，应对菜单栏未就绪时序问题）；注入各返回点
;                     增加调试留痕（core/menu.il 同步）
;   2026-08-01 v2.2.3 ASTB 项目组 调试日志轮转：astb_debug.log 超 512KB
;                     归档为 astb_debug_prev.log（每会话首次写日志前
;                     检查一次，API 异常静默跳过）
;   2026-08-17 v2.2.4 ASTB Team 防重载守卫改函数存在性检查：16.6 实测
;                     启动时 ASTB_MAIN_LOADED 被未知来源预绑定为 t
;                     （全盘整搜无果），boundp 守卫恒真导致 main.il
;                     主体永不执行（函数全未定义、菜单不出现）；
;                     守卫追加 getd('ASTB_InitEnv) 条件——只有函数真的
;                     定义过（本文件主体确实执行过）才跳过；
;                     顺带把文件头版本字段从 2.2.1 补齐对齐
;   2026-08-17 v2.2.5 ASTB Team 加入口探针（无条件打印 MAIN_LOADED
;                     绑定态与 InitEnv 定义态，看不到此行=文件未被
;                     读取）；守卫 getd 调用包 errset 防老版本无
;                     getd 时整个 load 中止
;   2026-08-17 v2.2.6 ASTB Team AutoInit 双通道武装：16.6 实测启动过早
;                     时 1000ms UI 定时器静默失效，ASTB_Init 从未执行
;                     （MAIN_LOADED=t 系主体正常置位，此前误判为幽灵
;                     绑定）；新增 'open 触发器兜底（打开设计时 UI
;                     必然就绪，Init 内部 ASTB_INITIALIZED 防重），
;                     定时器/触发器武装结果改为命令行可见
;   2026-08-17 v2.2.7 ASTB Team InitEnv 追加 axlSetVariable 注册
;                     FORMPATH/BITMAPPATH/BMPPATH：16.6 的表单/位图
;                     查找只认 Allegro env 注册表，setShellEnvVar 的
;                     进程变量不被识别；路径由 FormPath 现场拼，免改
;                     env 文件、免硬编码绝对路径、随项目目录可迁移
;   2026-08-20 v2.2.8 ASTB Team 修 16.6 member 报错：axlGetVariableList
;                     在 16.6 返回裸字符串，归一化为列表后再 member
;   2026-08-24 v2.2.9 ASTB Team Reload 前重置 ASTB_MENU_INJECTED 标志,
;                   配合 menu.il v3.5 清场式去重, 使 ASTB_Reload 真正
;                   结构化重建菜单(参照 FanySkill 菜单编辑后重注入)
;========================================================================

;; ------------------------------------------------------------------
;; 入口探针：无条件打印守卫输入（定位 16.6 幽灵绑定/文件未读取问题）
;; 此行只要文件被读取就一定会输出；看不到此行 = main.il 根本没被 load
;; ------------------------------------------------------------------
errset(printf("[ASTB] main.il entered: MAIN_LOADED bound=%L InitEnv defined=%L\n"
  boundp('ASTB_MAIN_LOADED)
  let((r) r = errset(getd('ASTB_InitEnv) t) and(r car(r)))) t)

;; ------------------------------------------------------------------
;; 防重复加载 guard：重复 load 本文件时跳过全部主体，避免 defvar 重置、
;; procedure 重定义与命令重复注册（原 when+return 写法无法阻止 load
;; 继续执行后续顶层表单）；getd 包 errset 防老版本无此函数时中止加载
;; ------------------------------------------------------------------
if( and(boundp('ASTB_MAIN_LOADED) let((r) r = errset(getd('ASTB_InitEnv) t) and(r car(r))))
then
  printf("[ASTB] main.il already loaded, skipping (use ASTB_Reload() to reload modules).\n")
else

;; 全局初始化完成标志（仅在 ASTB_Init 全部步骤成功后置位）
defvar(ASTB_INITIALIZED nil)

;; 调试日志轮转标志：每会话只做一次尺寸检查（见 ASTB_RotateDebugLog）
defvar(ASTB_LOG_ROTATED nil)

;------------------------------------------------------------------------
; 函数名  : ASTB_DebugLog
; 功能    : 向调试日志追加一行消息（内部错误静默忽略，不影响主流程）
; 参数    : msg - 日志文本
; 返回值  : nil
; 备注    : 日志路径优先取 ASTB_GLOBAL->ConfigPath/astb_debug.log；
;           环境未初始化时退回系统临时目录，禁止硬编码绝对路径
;------------------------------------------------------------------------
;------------------------------------------------------------------------
; 函数名  : ASTB_RotateDebugLog
; 功能    : 调试日志轮转：astb_debug.log 超过 512KB 时归档为
;           astb_debug_prev.log（覆盖旧归档），每会话仅检查一次。
;           环境未就绪或文件 API 异常时静默跳过，不影响日志主流程。
; 参数    : 无
; 返回值  : nil
;------------------------------------------------------------------------
procedure( ASTB_RotateDebugLog()
  prog((path prev port line sz)
    ;; 仅在能定位日志目录时才置位标志：ASTB_DebugLog 可能早于环境
    ;; 初始化被调用，过早置位会让本会话永远失去轮转机会
    when( and(boundp('ASTB_GLOBAL) ASTB_GLOBAL ASTB_GLOBAL->ConfigPath)
      ASTB_LOG_ROTATED = t
      errset(
        prog(()
          path = strcat(ASTB_GLOBAL->ConfigPath "/astb_debug.log")
          unless( isFile(path)
            return(nil)
          )
          ;; 无可靠 fileSize API：按行累计估算字节数（每会话一次）
          port = infile(path)
          unless( port
            return(nil)
          )
          sz = 0
          while( gets(line port)
            sz = sz + strlen(line) + 1
          )
          close(port)
          when( sz > 524288
            prev = strcat(ASTB_GLOBAL->ConfigPath "/astb_debug_prev.log")
            when( isFile(prev)
              deleteFile(prev)
            )
            renameFile(path prev)
          )
        )
        t
      )
    )
    nil
  )
)

procedure( ASTB_DebugLog(msg)
  prog((port path)
    ;; 每会话首次写日志前做轮转检查（>512KB 归档为 _prev）
    unless( ASTB_LOG_ROTATED
      ASTB_RotateDebugLog()
    )
    errset(
      prog(()
        path = if( and(boundp('ASTB_GLOBAL) ASTB_GLOBAL ASTB_GLOBAL->ConfigPath)
               then strcat(ASTB_GLOBAL->ConfigPath "/astb_debug.log")
               else strcat(axlTempDirectory() "/astb_debug.log") )
        port = outfile(path "a")
        when( port
          fprintf(port "ASTB %s\n" msg)
          close(port)
        )
      )
      t
    )
    nil
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_LastIndexOf
; 功能    : 查找字符在字符串中最后出现的位置
; 参数    : str - 目标字符串；ch - 单字符字符串
; 返回值  : 位置（1 起始）；未找到返回 nil
;------------------------------------------------------------------------
procedure( ASTB_LastIndexOf(str ch)
  prog((len i)
    len = strlen(str)
    i = len
    while( i >= 1
      when( substring(str i 1) == ch
        return(i)
      )
      i = i - 1
    )
    return(nil)
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_InitEnv
; 功能    : 定位安装目录并初始化 ASTB_GLOBAL 路径属性；注入 FORMPATH
; 参数    : 无
; 返回值  : 无显式返回（定位失败时 error 中断）
; 备注    : 路径查找优先级：ASTB_INSTALL_DIR -> 本文件路径 ->
;           getSkillPath -> 工作目录。get_filename(piport) 依赖 load
;           上下文，仅在本文件经 load 加载时可用，独立粘贴运行时无效
;------------------------------------------------------------------------
procedure( ASTB_InitEnv()
  prog((installPath paths p found mainFile pos tbPath)
    ASTB_DebugLog("ASTB_InitEnv: start")
    unless( boundp('ASTB_GLOBAL)
      defvar(ASTB_GLOBAL ncons(nil))
    )
    found = nil

    ;; Priority 1: ASTB_INSTALL_DIR (direct layout)
    if( and(boundp('ASTB_INSTALL_DIR) ASTB_INSTALL_DIR)
    then
      installPath = ASTB_INSTALL_DIR
      when( isFile(strcat(installPath "/main.il"))
        found = t
      )
    )

    ;; Priority 2: ASTB_INSTALL_DIR with subdir (backward compat)
    unless( found
      when( and(boundp('ASTB_INSTALL_DIR) ASTB_INSTALL_DIR)
        installPath = ASTB_INSTALL_DIR
        when( isFile(strcat(installPath "/allegro_skill_toolbox_v2/main.il"))
          installPath = strcat(installPath "/allegro_skill_toolbox_v2")
          found = t
        )
      )
    )

    ;; Priority 3: derive from this file's path (direct layout)
    ;; 依赖 load 上下文，见函数头备注
    unless( found
      errset(
        prog(()
          mainFile = simplifyFilename(get_filename(piport))
          when( mainFile
            pos = ASTB_LastIndexOf(mainFile "/")
            when( pos > 0
              tbPath = substring(mainFile 1 pos - 1)
              when( isFile(strcat(tbPath "/main.il"))
                installPath = tbPath
                found = t
              )
            )
          )
        )
        t
      )
    )

    ;; Priority 4: getSkillPath() (direct layout)
    unless( found
      paths = getSkillPath()
      foreach( p paths
        when( isFile(strcat(p "/main.il"))
          installPath = p
          found = t
        )
      )
    )

    ;; Priority 5: getSkillPath() with subdir (backward compat)
    unless( found
      paths = getSkillPath()
      foreach( p paths
        when( isFile(strcat(p "/allegro_skill_toolbox_v2/main.il"))
          installPath = strcat(p "/allegro_skill_toolbox_v2")
          found = t
        )
      )
    )

    ;; Priority 6: working directory (direct layout)
    unless( found
      p = getWorkingDir()
      when( isFile(strcat(p "/main.il"))
        installPath = p
        found = t
      )
    )

    unless( found
      printf("[ASTB][ERROR] Cannot locate allegro_skill\n")
      error("Cannot locate allegro_skill installation directory")
    )

    ASTB_GLOBAL->InstallPath = axlOSSlash(installPath)
    ASTB_GLOBAL->ToolboxPath = ASTB_GLOBAL->InstallPath
    ASTB_GLOBAL->CorePath    = strcat(ASTB_GLOBAL->ToolboxPath "/core")
    ASTB_GLOBAL->ModulePath  = strcat(ASTB_GLOBAL->ToolboxPath "/modules")
    ASTB_GLOBAL->FormPath    = strcat(ASTB_GLOBAL->ToolboxPath "/forms")
    ASTB_GLOBAL->ConfigPath  = strcat(ASTB_GLOBAL->ToolboxPath "/config")
    ASTB_GLOBAL->DocsPath    = strcat(ASTB_GLOBAL->ToolboxPath "/docs")

    when( isDir(ASTB_GLOBAL->FormPath)
      unless( member(ASTB_GLOBAL->FormPath getSkillPath())
        setSkillPath(cons(ASTB_GLOBAL->FormPath getSkillPath()))
      )
      let((ret formPathEnv)
        ;; errset 成功时返回单元素列表，必须取 car；
        ;; 非字符串结果（如 t）按未设置处理，默认 "."
        ret = errset(getShellEnvVar("FORMPATH") t)
        formPathEnv = if( ret && car(ret) && stringp(car(ret))
                      then car(ret)
                      else "." )
        unless( member(ASTB_GLOBAL->FormPath parseString(formPathEnv ";"))
          errset(setShellEnvVar(strcat("FORMPATH=" ASTB_GLOBAL->FormPath ";" formPathEnv)) t)
        )
      )
      ;; 16.6 的表单/位图查找只认 Allegro env 注册表（env 文件那套），
      ;; setShellEnvVar 的进程变量不被识别；运行期 axlSetVariable 写
      ;; 注册表，路径由 FormPath 现场拼（免改 env 文件、免绝对路径、
      ;; 可随项目目录整体迁移）
      errset(
        prog((cur v)
          foreach( v list("FORMPATH" "BITMAPPATH" "BMPPATH")
            cur = axlGetVariableList(v)
            ;; 16.6 可能返回裸字符串而非列表，归一化后再 member
            when( stringp(cur)
              cur = list(cur)
            )
            unless( and(cur member(ASTB_GLOBAL->FormPath cur))
              axlSetVariable(v cons(ASTB_GLOBAL->FormPath cur))
            )
          )
        )
        t
      )
    )

    printf("[ASTB] Install path: %s\n" ASTB_GLOBAL->InstallPath)
    printf("[ASTB] Toolbox path: %s\n" ASTB_GLOBAL->ToolboxPath)
    ASTB_DebugLog(strcat("ASTB_InitEnv: done, ToolboxPath = " ASTB_GLOBAL->ToolboxPath))
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_About
; 功能    : 弹出 About 对话框
; 参数    : 无
; 返回值  : t
;------------------------------------------------------------------------
procedure( ASTB_About()
  prog((msg)
    msg = strcat("allegro_skill v2.2\n"
                 "Allegro PCB SKILL Toolbox\n\n"
                 "Path: " ASTB_GLOBAL->ToolboxPath "\n")
    axlUIConfirm(msg)
    return(t)
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_Reload
; 功能    : 重新加载核心库与模块，重新注册命令并注入菜单
; 参数    : 无
; 返回值  : t
; 备注    : 命令重复登记由 ASTB_RegisterCommand 内部去重；
;           菜单重复注入由 ASTB_MENU_INJECTED / dump 比对防重
;------------------------------------------------------------------------
procedure( ASTB_Reload()
  prog(()
    ASTB_LoadCore()
    ;; Reload 后内存配置需重建（core/config.il 的 defvar 已改 boundp
    ;; 保护不再清空，但此处主动重读以保证与磁盘一致）
    errset(ASTB_LoadConfig() t)
    ASTB_LoadModules()
    ASTB_RegisterAllMenuCommands()
    ;; v2.2.9: 重置注入标志, 配合 menu.il v3.5 清场式去重真正重建菜单
    when( boundp('ASTB_MENU_INJECTED)
      ASTB_MENU_INJECTED = nil
    )
    ASTB_InjectMenu()
    axlUIConfirm("allegro_skill reloaded.")
    return(t)
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_Init
; 功能    : 主初始化流程（环境 -> 加载器 -> 核心库 -> 配置 -> 版本
;           -> 模块 -> 命令注册 -> 菜单注入）
; 参数    : window/timerId/elapsedTime - 定时器回调占位参数（可选）
; 返回值  : t - 全部步骤成功；nil - 存在失败步骤
; 备注    : 每步均检查 errset 返回值；任一步骤失败则不置位
;           ASTB_INITIALIZED，汇总报错并允许修复后重新调用
;------------------------------------------------------------------------
procedure( ASTB_Init(@optional window timerId elapsedTime)
  prog((failed ret)
    unless( ASTB_INITIALIZED
      failed = nil
      ASTB_DebugLog("ASTB_Init: start")

      ;; 步骤 1: 环境初始化
      unless( errset(ASTB_InitEnv() t)
        failed = cons("ASTB_InitEnv" failed)
        printf("[ASTB][ERROR] Init step failed: ASTB_InitEnv\n")
      )
      ASTB_DebugLog("ASTB_Init: env done")

      ;; 步骤 2: 加载加载器（依赖步骤 1 的 CorePath，失败则跳过后续步骤）
      unless( failed
        unless( errset(load(strcat(ASTB_GLOBAL->CorePath "/loader.il")) t)
          failed = cons("load loader.il" failed)
          printf("[ASTB][ERROR] Init step failed: load loader.il\n")
        )
      )
      ASTB_DebugLog("ASTB_Init: loader done")

      ;; 步骤 3: 加载核心库
      unless( failed
        unless( errset(ASTB_LoadCore() t)
          failed = cons("ASTB_LoadCore" failed)
          printf("[ASTB][ERROR] Init step failed: ASTB_LoadCore\n")
        )
      )
      ASTB_DebugLog("ASTB_Init: core done")

      ;; 步骤 4: 加载配置（配置文件不存在属正常情况，函数内已处理）
      unless( failed
        unless( errset(ASTB_LoadConfig() t)
          failed = cons("ASTB_LoadConfig" failed)
          printf("[ASTB][ERROR] Init step failed: ASTB_LoadConfig\n")
        )
      )
      ASTB_DebugLog("ASTB_Init: config done")

      ;; 步骤 5: 写入默认配置
      unless( failed
        unless( errset(ASTB_InitDefaultConfig() t)
          failed = cons("ASTB_InitDefaultConfig" failed)
          printf("[ASTB][ERROR] Init step failed: ASTB_InitDefaultConfig\n")
        )
      )
      ASTB_DebugLog("ASTB_Init: default config done")

      ;; 步骤 6: 版本检测（崩溃算失败；返回 nil 仅告警，不阻断初始化）
      unless( failed
        ret = errset(ASTB_VersionInit() t)
        unless( ret
          failed = cons("ASTB_VersionInit" failed)
          printf("[ASTB][ERROR] Init step failed: ASTB_VersionInit\n")
        )
        when( ret && null(car(ret))
          printf("[ASTB][WARN] ASTB_VersionInit returned nil; version detection unavailable\n")
        )
      )
      ASTB_DebugLog("ASTB_Init: version done")

      ;; 步骤 7: 加载模块
      unless( failed
        unless( errset(ASTB_LoadModules() t)
          failed = cons("ASTB_LoadModules" failed)
          printf("[ASTB][ERROR] Init step failed: ASTB_LoadModules\n")
        )
      )
      ASTB_DebugLog("ASTB_Init: modules done")

      ;; 步骤 8: 注册菜单命令
      unless( failed
        unless( errset(ASTB_RegisterAllMenuCommands() t)
          failed = cons("ASTB_RegisterAllMenuCommands" failed)
          printf("[ASTB][ERROR] Init step failed: ASTB_RegisterAllMenuCommands\n")
        )
      )
      ASTB_DebugLog("ASTB_Init: commands done")

      ;; 步骤 9: 注入菜单（函数返回 nil 同样视为失败）
      unless( failed
        ret = errset(ASTB_InjectMenu() t)
        when( or(null(ret) null(car(ret)))
          failed = cons("ASTB_InjectMenu" failed)
          printf("[ASTB][ERROR] Init step failed: ASTB_InjectMenu\n")
          ASTB_DebugLog(sprintf(nil "ASTB_Init: inject ret=%L, schedule retry" ret))
          unless( boundp('ASTB_INIT_RETRY)
            defvar(ASTB_INIT_RETRY 0)
          )
          when( ASTB_INIT_RETRY < 3
            ASTB_INIT_RETRY = ASTB_INIT_RETRY + 1
            errset(axlUIWTimerAdd(nil 1500 t 'ASTB_Init) t)
          )
        )
      )
      ASTB_DebugLog("ASTB_Init: menu injected")

      ;; 全部步骤成功后才置位初始化标志；失败时汇总报错并允许重试
      if( failed
      then
        printf("[ASTB][ERROR] Initialization failed at step(s): %L\n" reverse(failed))
        printf("[ASTB] ASTB_INITIALIZED NOT set; fix the issue and run ASTB_Init() to retry.\n")
        ASTB_DebugLog("ASTB_Init: FAILED")
      else
        ASTB_INITIALIZED = t
        printf("[ASTB] allegro_skill initialized successfully.\n")
        ASTB_DebugLog("ASTB_Init: success")
      )
    )
    ;; 单次触发定时器到期后句柄自动失效，此处的 Remove 仅为兜底
    when( timerId
      errset(axlUIWTimerRemove(timerId) t)
    )
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_AutoInit
; 功能    : 延迟触发 ASTB_Init（等待界面就绪）。双通道武装：
;           1) 一次性 UI 定时器 1000ms；2) 'open 触发器兜底——16.6
;           实测启动过早时 UI 定时器静默失效（ASTB_Init 从未执行，
;           无初始化输出、无菜单），打开设计时 UI 必然就绪
; 参数    : 无
; 返回值  : t
; 备注    : ASTB_Init 内部有 ASTB_INITIALIZED 防重，双通道先到先执行；
;           axlUIWTimerAdd 第三参 oneshot 置 t，单次触发后自动移除
;------------------------------------------------------------------------
procedure( ASTB_AutoInit()
  prog((tid ret trig)
    when( ASTB_INITIALIZED
      return(t)
    )
    ret = errset(tid = axlUIWTimerAdd(nil 1000 t 'ASTB_Init) t)
    if( ret && tid
    then
      printf("[ASTB] AutoInit: init scheduled via 1000ms timer\n")
      ASTB_DebugLog("ASTB_AutoInit: scheduled via timer")
    else
      printf("[ASTB][WARN] AutoInit: timer add failed, relying on 'open trigger\n")
      ASTB_DebugLog("ASTB_AutoInit: timer failed, use manual ASTB_Init")
    )
    ;; 兜底通道：打开设计时 ASTB_Init 必被执行一次（防重见 Init 内部）
    trig = errset(axlTriggerSet('open 'ASTB_Init) t)
    if( trig
    then
      printf("[ASTB] AutoInit: 'open trigger armed as fallback\n")
    else
      ASTB_DebugLog("ASTB_AutoInit: 'open trigger unavailable")
    )
    t
  )
)

;; 注册手动初始化命令（errset 兜底，防止注册失败中断加载）
errset(axlCmdRegister("ASTB_Init" 'ASTB_Init ?cmdType "general") t)
ASTB_AutoInit()

;; 全部定义完成后标记本文件已加载（顶部 guard 依此跳过重复加载）
defvar(ASTB_MAIN_LOADED t)

) ;; end if boundp('ASTB_MAIN_LOADED)
