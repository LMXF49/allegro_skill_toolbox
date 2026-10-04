;========================================================================
; 文件名    : core/config.il
; 作者      : allegro_skill 项目组
; 创建日期  : 2026-06-06
; 版本      : 1.5
; 功能描述  : 全局配置管理（astb.cfg 的读写、默认值初始化、配置查询）
; 依赖模块  : core/utils.il（ASTB_StringInList / ASTB_ParseCfgLine / 日志函数）
; 编码      : GBK（含中文注释）
; 修改记录  :
;   2026-06-06 v1.0 allegro_skill 项目组 初始创建
;   2026-07-17 v1.1 修复组_框架核心 删除与 utils.il 重复的 ASTB_StringInList；
;                   删除 ASTB_GetConfig 中永不可达的 'unbound 死分支；
;                   ASTB_SetConfig 写入前剔除换行符防止破坏 cfg 格式；
;                   ASTB_SaveConfig 检查 ASTB_EnsureDir 返回值
;   2026-07-25 v1.2 ASTB 项目组 ASTB_SaveConfig 去掉 isDir 闸门
;                   （其对已存在目录误判导致配置保存不上），改
;                   为先写后建目录重试
;   2026-07-25 v1.3 ASTB 项目组 ASTB_CONFIG/KEYS 的 defvar 改 boundp
;                   保护（此前 Reload 重载本文件即清空内存配置，
;                   语言等设置 Reload 后丢失）；GetConfig 去 val 化
;   2026-07-26 v1.4 ASTB 项目组 ASTB_GetConfig 改为直读槽位（errset +
;                   'unbound 哨兵判断），不再依赖 StrListHas 闸门——
;                   旧会话闸门原语失效曾致 GetConfig 恒返默认值、
;                   中英文切换无效；CFG-STAMP 升级 0726
;   2026-07-26 v1.5 ASTB 项目组 修复 v1.4 缺键回归：unbound 标记在
;                   eq 求值时即抛错（启动期 utf8_autoconv 缺键查询
;                   报 unbound variable - v）；改为 errset 内强制
;                   求值整体捕获，缺键静默回退默认值
;========================================================================

unless(boundp('ASTB_CONFIG) defvar(ASTB_CONFIG makeTable('ASTB_CONFIG)))
unless(boundp('ASTB_CONFIG_KEYS) defvar(ASTB_CONFIG_KEYS nil))

;; 注意：ASTB_StringInList 的唯一实现位于 core/utils.il（由加载器最先
;; 加载），本文件不得再定义同名函数，避免函数重定义告警。

;------------------------------------------------------------------------
; 函数名  : ASTB_TableHasKey
; 功能    : 判断配置键是否已存在
; 参数    : table - 保留参数（历史签名，当前实现恒查全局 ASTB_CONFIG_KEYS，
;           为保持对外 API 向后兼容而保留，调用方传 ASTB_CONFIG 即可）
;           key   - 配置键字符串
; 返回值  : t / nil
;------------------------------------------------------------------------
procedure( ASTB_TableHasKey(table key)
  ASTB_StrListHas(ASTB_CONFIG_KEYS key)
)

;------------------------------------------------------------------------
; 函数名  : ASTB_ConfigFile
; 功能    : 返回配置文件完整路径
; 返回值  : 路径字符串
;------------------------------------------------------------------------
procedure( ASTB_ConfigFile()
  strcat(ASTB_GLOBAL->ConfigPath "/astb.cfg")
)

;------------------------------------------------------------------------
; 函数名  : ASTB_LoadConfig
; 功能    : 从 astb.cfg 读取配置到全局表；文件不存在时使用默认值
; 返回值  : t - 读取成功；nil - 文件不存在或无法打开
;------------------------------------------------------------------------
procedure( ASTB_LoadConfig()
  prog((cfgFile port line kv)
    cfgFile = ASTB_ConfigFile()
    ASTB_LogInfo(sprintf(nil "ASTB_LoadConfig: file=%s exists=%L" cfgFile isFile(cfgFile)))
    unless( isFile(cfgFile)
      ASTB_LogInfo("Config file not found, using defaults.")
      return(nil)
    )
    port = infile(cfgFile)
    when( null(port)
      ASTB_LogWarn(sprintf(nil "Cannot open config file: %s" cfgFile))
      return(nil)
    )
    while( gets(line port)
      kv = ASTB_ParseCfgLine(line)
      when( kv
        ASTB_SetConfig(car(kv) cadr(kv))
      )
    )
    close(port)
    ASTB_LogInfo(sprintf(nil "Config loaded from %s" cfgFile))
    t
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_SaveConfig
; 功能    : 将当前配置写入 astb.cfg（配置目录缺失时自动创建）
; 返回值  : t - 写入成功；nil - 目录创建失败或文件无法打开
;------------------------------------------------------------------------
procedure( ASTB_SaveConfig()
  prog((cfgFile port key uniqKeys)
    cfgFile = ASTB_ConfigFile()
    ;; 先试直接写（目录通常已存在）；失败再建目录重试。
    ;; 不再经 isDir 判断（其对已存在目录可能误判为假，曾导致
    ;; 配置永远保存不上）
    port = errset(outfile(cfgFile) t)
    unless( port
      errset(createDir(ASTB_GLOBAL->ConfigPath) t)
      port = errset(outfile(cfgFile) t)
    )
    if( null(port) || null(car(port)) then
      ASTB_LogError(sprintf(nil "Cannot write config file: %s" cfgFile))
      return(nil)
    )
    port = car(port)
    fprintf(port "# allegro_skill configuration\n")
    fprintf(port "# Auto-generated, do NOT edit with UTF-8 editor\n")
    ;; 写盘前去重（KEYS 历史积累过重复项，astb.cfg 曾被写成多份）
    uniqKeys = nil
    foreach( key ASTB_CONFIG_KEYS
      unless( ASTB_StrListHas(uniqKeys key)
        uniqKeys = cons(key uniqKeys)
      )
    )
    foreach( key reverse(uniqKeys)
      fprintf(port "%s=%s\n" key ASTB_CONFIG[key])
    )
    close(port)
    ASTB_LogInfo(sprintf(nil "Config saved to %s" cfgFile))
    t
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_GetConfig
; 功能    : 读取配置值，键不存在时返回默认值
; 参数    : key - 配置键；defaultVal - 默认值
; 返回值  : 配置值字符串或 defaultVal
;------------------------------------------------------------------------
procedure( ASTB_GetConfig(key defaultVal)
  prog((r)
    ;; 直读槽位，不经 StrListHas 闸门（0726 根因：旧会话中闸门
    ;; 原语失效导致本函数恒返默认值，中英文切换看似无效）。
    ;; 注意 makeTable 缺键返回的 unbound 标记有传染性：赋值可
    ;; 转移，但对持有它的变量求值即抛 unbound variable——故把
    ;; "读取+求值"整体放进 errset：缺键时求值抛错被静默捕获，
    ;; errset 返回 nil，回退默认值（v1.4 曾在 eq 比较处中招）。
    r = errset(
      prog((v)
        v = ASTB_CONFIG[key]
        return(v)   ; 缺键标记在对 v 求值的这一刻抛错
      )
    )
    if( null(r) then
      return(defaultVal)
    )
    return(car(r))
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_SetConfig
; 功能    : 设置配置值（非字符串自动格式化；换行符会被剔除以保护
;           cfg 文件 "key=value" 单行格式）
; 参数    : key - 配置键；value - 配置值
; 返回值  : 实际写入的字符串
;------------------------------------------------------------------------
procedure( ASTB_SetConfig(key value)
  prog((s)
    s = if( stringp(value) value sprintf(nil "%s" value) )
    ;; 剔除换行 / 回车，防止破坏 cfg 单行 key=value 格式
    when( or(rexMatchp("\n" s) rexMatchp("\r" s))
      ASTB_LogWarn(sprintf(nil "Config value for %s contained newlines; stripped" key))
      s = rexReplace(s "\n" " ")
      s = rexReplace(s "\r" " ")
    )
    ASTB_CONFIG[key] = s
    unless( ASTB_StrListHas(ASTB_CONFIG_KEYS key)
      ASTB_CONFIG_KEYS = cons(key ASTB_CONFIG_KEYS)
    )
    return(s)
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_InitDefaultConfig
; 功能    : 写入缺失的默认配置项（不覆盖已有值）
; 返回值  : 无
;------------------------------------------------------------------------
procedure( ASTB_InitDefaultConfig()
  prog(()
    unless( ASTB_TableHasKey(ASTB_CONFIG "version")
      ASTB_SetConfig("version" "2.0")
    )
    unless( ASTB_TableHasKey(ASTB_CONFIG "language")
      ASTB_SetConfig("language" "zh-CN")
    )
    unless( ASTB_TableHasKey(ASTB_CONFIG "logLevel")
      ASTB_SetConfig("logLevel" "INFO")
    )
    unless( ASTB_TableHasKey(ASTB_CONFIG "autoReload")
      ASTB_SetConfig("autoReload" "true")
    )
    ;; 语言热切换开关: on=删旧菜单按新语言重注入(17.4/24.1 毫秒级);
    ;; 16.6 的 axlUIMenuDump 是分钟级, 建议改 off(只写配置提示重启,
    ;; 零 dump 零卡顿)。缺省 on, 由安装器/用户按版本调整
    unless( ASTB_TableHasKey(ASTB_CONFIG "hot_switch")
      ASTB_SetConfig("hot_switch" "on")
    )
  )
)

printf("[ASTB] core/config.il loaded.\n")

;------------------------------------------------------------------------
; 函数名  : ASTB_ConfigSelfTest
; 功能    : 配置链路自测探针（临时诊断）：实测 == / equal / strcmp
;           三种字符串比较在本环境的有效性，并显示首键长度（查隐藏
;           字符）与 language 槽位值
; 用法    : 命令行输入 ASTB_ConfigSelfTest
;------------------------------------------------------------------------
procedure( ASTB_ConfigSelfTest()
    prog((k0 probe)
        k0 = car(ASTB_CONFIG_KEYS)
        probe = "language"
        printf("[SLFTEST] k0=%L strlen(k0)=%L\n" k0 and(k0 strlen(k0)))
        printf("[SLFTEST] == => %L  equal => %L  strcmp => %L\n"
            and(k0 k0 == probe)
            and(k0 equal(k0 probe))
            and(k0 strcmp(k0 probe)) )
        printf("[SLFTEST] oldInList=%L  newInList=%L  slot=%L  getCfg=%L\n"
            ASTB_StringInList(probe ASTB_CONFIG_KEYS)
            ASTB_StrListHas(ASTB_CONFIG_KEYS probe)
            ASTB_CONFIG[probe]
            ASTB_GetConfig(probe "DEFAULT_NIL") )
        return(t)
    )
)

axlCmdRegister("ASTB_ConfigSelfTest" 'ASTB_ConfigSelfTest)

printf("CFG-STAMP-0726B\n")
