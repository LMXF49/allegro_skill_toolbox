;========================================================================
; 文件名    : core/version_adapter.il
; 作者      : allegro_skill 项目组
; 创建日期  : 2026-06-06
; 版本      : 1.5
; 功能描述  : 版本兼容适配（16.6 / 17.4 / 24.1）：版本检测、数据库事务
;             包装、菜单查找与命令注册的安全包装
; 依赖模块  : core/utils.il（日志函数）
; 编码      : GBK（含中文注释）
; 修改记录  :
;   2026-06-06 v1.0 allegro_skill 项目组 初始创建
;   2026-07-17 v1.1 修复组_框架核心 ASTB_VersionInit 改用
;                   axlVersion('fullVersion) 直接取版本串；tVersion 替代
;                   返回浮点数的 'version；ASTB_VersionContains 正则转义；
;                   删除臆造的 axlBeginTransaction / axlEndTransaction
;                   fallback，事务函数改为合法 API 并返回真实成败；
;                   删除无效的 axlUIMenuFind("Help") fallback；
;                   ASTB_CmdRegisterSafe 增加 cmdType 符号归一化防御并
;                   对 fallback 路径显式告警；删除死函数
;                   ASTB_TimerAdd / ASTB_TimerRemove
;   2026-07-19 v1.2 ASTB_CmdRegisterSafe 新增 ?doneCmd/?cancelCmd 透传,
;                   支撑交互命令右键 Done/Cancel 回调注册(默认 nil 兼容)
;   2026-08-17 v1.3 ASTB Team CmdRegisterSafe 全参数注册改每会话探测：
;                   首次失败置 ASTB_FULLREG_OK=nil，后续命令直接裸注册，
;                   消除 16.6 启动时 80+ 条 ?undo *Error* 刷屏与逐命令
;                   fallback 告警；v1.4 探测注册的 errset 改静默（第二参
;                   nil），否则 16.6 启动仍残留一条 ?undo *Error*
;   2026-08-20 v1.5 ASTB Team 全参数注册在 doneCmd/cancelCmd 为 nil
;                   时不传对应关键字（24.1 拒带 nil 关键字的调用，降级
;                   后 ?undo 声明丢失，系统撤销覆盖不到）
;========================================================================

defvar(ASTB_VERSION_INFO nil)

;------------------------------------------------------------------------
; 函数名  : ASTB_ExtractVersionString
; 功能    : 从版本信息中提取版本字符串
; 参数    : ver - 版本信息（字符串直接返回；其他类型重新查询）
; 返回值  : 版本字符串；全部查询失败返回空串 ""
; 备注    : 'fullVersion 返回字符串；'version 返回浮点数（不可用于
;           字符串匹配），fallback 必须用返回字符串的 'tVersion
;------------------------------------------------------------------------
procedure( ASTB_ExtractVersionString(ver)
  prog((ret)
    when( stringp(ver)
      return(ver)
    )
    ret = errset(axlVersion('fullVersion) t)
    when( ret && car(ret) && stringp(car(ret))
      return(car(ret))
    )
    ;; tVersion 返回字符串；勿用 'version（返回浮点数，下游 rexMatchp
    ;; 会类型报错）
    ret = errset(axlVersion('tVersion) t)
    when( ret && car(ret) && stringp(car(ret))
      return(car(ret))
    )
    return("")
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_VersionInit
; 功能    : 初始化版本信息（直接查询 fullVersion 字符串）
; 返回值  : 版本字符串 - 成功；nil - 失败
;------------------------------------------------------------------------
procedure( ASTB_VersionInit()
  prog((verStr ret)
    ret = errset(axlVersion('fullVersion) t)
    if( ret && car(ret) && stringp(car(ret))
    then
      verStr = car(ret)
      ASTB_VERSION_INFO = verStr
      ASTB_LogInfo(sprintf(nil "Allegro version: %s" verStr))
      return(verStr)
    else
      ASTB_LogWarn("axlVersion('fullVersion) failed.")
      ASTB_VERSION_INFO = ""
      return(nil)
    )
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_GetVersion
; 功能    : 返回当前 Allegro 版本字符串
; 返回值  : 版本字符串（未初始化时实时提取）
;------------------------------------------------------------------------
procedure( ASTB_GetVersion()
  ASTB_ExtractVersionString(ASTB_VERSION_INFO)
)

;------------------------------------------------------------------------
; 函数名  : ASTB_VersionContains
; 功能    : 判断版本字符串是否包含指定子串
; 参数    : sub - 子串（如 "16.6"）
; 返回值  : t / nil
; 备注    : 用 \Q...\E 转义正则元字符（"." 等），防止误匹配
;------------------------------------------------------------------------
procedure( ASTB_VersionContains(sub)
  prog((verStr)
    verStr = ASTB_GetVersion()
    when( verStr && verStr != ""
      rexMatchp(strcat("\\Q" sub "\\E") verStr)
    )
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_IsVersion166 / ASTB_IsVersion174 / ASTB_IsVersion241
; 功能    : 版本判定快捷函数
; 返回值  : t / nil
;------------------------------------------------------------------------
procedure( ASTB_IsVersion166()
  ASTB_VersionContains("16.6")
)

procedure( ASTB_IsVersion174()
  ASTB_VersionContains("17.4")
)

procedure( ASTB_IsVersion241()
  ASTB_VersionContains("24.1")
)

;------------------------------------------------------------------------
; 函数名  : ASTB_ModernUI
; 功能    : 判断是否为现代 UI（非 16.6）
; 返回值  : t / nil
;------------------------------------------------------------------------
procedure( ASTB_ModernUI()
  not(ASTB_IsVersion166())
)

;------------------------------------------------------------------------
; 函数名  : ASTB_TxnStart
; 功能    : 开始数据库事务，返回事务标记
; 参数    : name - 保留参数（历史签名，仅为向后兼容而保留；
;           axlDBTransactionStart 只接受 'undoMark 或省略，字符串
;           参数无语义，本函数内部固定按无参调用）
; 返回值  : 事务标记 - 成功；nil - 失败（调用方必须据此阻断后续
;           数据库修改）
;------------------------------------------------------------------------
procedure( ASTB_TxnStart(@optional (name "ASTB"))
  prog((txId ret)
    ret = errset(txId = axlDBTransactionStart() t)
    if( ret && txId
    then
      return(txId)
    else
      ASTB_LogError("ASTB_TxnStart: axlDBTransactionStart failed")
      return(nil)
    )
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_TxnCommit
; 功能    : 提交数据库事务
; 参数    : txId - ASTB_TxnStart 返回的事务标记
; 返回值  : t - 提交成功；nil - 失败或 txId 无效
;------------------------------------------------------------------------
procedure( ASTB_TxnCommit(txId)
  prog((ret)
    unless( txId
      ASTB_LogError("ASTB_TxnCommit: txId is nil")
      return(nil)
    )
    ret = errset(axlDBTransactionCommit(txId) t)
    if( ret && car(ret)
    then
      t
    else
      ASTB_LogError("ASTB_TxnCommit: axlDBTransactionCommit failed")
      nil
    )
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_TxnRollback
; 功能    : 回滚数据库事务
; 参数    : txId - ASTB_TxnStart 返回的事务标记
; 返回值  : t - 回滚成功；nil - 失败（含当前版本不支持）或 txId 无效
;------------------------------------------------------------------------
procedure( ASTB_TxnRollback(txId)
  prog((ret)
    unless( txId
      ASTB_LogWarn("ASTB_TxnRollback: txId is nil, nothing to roll back")
      return(nil)
    )
    ret = errset(axlDBTransactionRollback(txId) t)
    if( ret && car(ret)
    then
      t
    else
      ASTB_LogWarn("ASTB_TxnRollback: rollback failed or not supported in this version")
      nil
    )
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_MenuFindSafe
; 功能    : axlUIMenuFind 的 errset 安全包装
; 参数    : label - 菜单标签（可选）；pos - 位置（可选，-1 表示菜单栏
;           最后一项之后）
; 返回值  : 菜单 id；失败返回 nil
; 备注    : 已删除原 axlUIMenuFind("Help") fallback：其参数位置错误
;          （标签被当作 x_menuId），fallback 实际无效
;------------------------------------------------------------------------
procedure( ASTB_MenuFindSafe(@optional (label nil) (pos nil))
  prog((ret)
    if( pos == -1
    then
      ret = errset(axlUIMenuFind(label pos) t)
    else
      ret = errset(axlUIMenuFind(label) t)
    )
    if( ret && car(ret)
    then
      car(ret)
    else
      nil
    )
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_CmdRegisterSafe
; 功能    : axlCmdRegister 的安全包装：带完整参数注册，失败时降级为
;           裸注册并显式告警（降级后 ?undo 声明丢失）
; 参数    : cmdName - 命令名；procSym - 回调符号；
;           cmdType - 命令类型，字符串 "interactive"/"general"/"sub_cmd"
;          （兼容传符号的存量调用，内部归一化为字符串）；
;           undo - 是否声明支持撤销
; 返回值  : t - 注册成功；nil - 失败
;------------------------------------------------------------------------
procedure( ASTB_CmdRegisterSafe(cmdName procSym @key (cmdType "general") (undo t) (doneCmd nil) (cancelCmd nil))
  prog((ret cmdTypeStr)
    ;; 防御：手册要求 t_cmdType 为字符串；存量调用方可能传符号
    ;;（如 'interactive），此处统一归一化，避免严格类型检查下注册失败
    cmdTypeStr = cond(
      ( stringp(cmdType) cmdType )
      ( symbolp(cmdType) sprintf(nil "%s" cmdType) )
      ( t "general" )
    )
    ;; 全参数注册能力探测（每会话一次）：16.6 不认 ?undo/?doneCmd/?cancelCmd，
    ;; 每个命令都试就刷一片 *Error*；首次失败后置标志，后续直接裸注册
    ;; v1.5: doneCmd/cancelCmd 为 nil 时不传对应关键字（24.1 实测带 nil
    ;; 关键字的全参数注册被拒，降级后 ?undo 声明一并丢失）
    unless( boundp('ASTB_FULLREG_OK) defvar(ASTB_FULLREG_OK 'unknown) )
    when( ASTB_FULLREG_OK != nil
      ;; 探测性注册不打印错误（errset 第二参 nil 静默），WARN 统一报告
      if( or(doneCmd cancelCmd) then
        ret = errset(axlCmdRegister(cmdName procSym ?cmdType cmdTypeStr ?doneCmd doneCmd ?cancelCmd cancelCmd ?undo undo) nil)
      else
        ret = errset(axlCmdRegister(cmdName procSym ?cmdType cmdTypeStr ?undo undo) nil)
      )
      when( ret && car(ret)
        ASTB_FULLREG_OK = t
        return(t)
      )
      ASTB_FULLREG_OK = nil
      ASTB_LogWarn("Full axlCmdRegister unsupported on this version; all commands use basic registration (?undo lost)")
    )
    ;; 裸注册（16.6 等老版本路径；?undo 声明在此路径丢失）
    ret = errset(axlCmdRegister(cmdName procSym) t)
    when( ret && car(ret)
      return(t)
    )
    ASTB_LogWarn(sprintf(nil "Failed to register command %s" cmdName))
    nil
  )
)

printf("[ASTB] core/version_adapter.il loaded.\n")
