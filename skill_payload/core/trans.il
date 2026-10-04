;   2026-08-20 v1.6 ASTB Team 撤销命令注册补 ?undo nil（防系统撤销把
;                   撤销命令本身入栈，17.4+）
;========================================================================
; 文件名    : core/trans.il
; 作者      : allegro_skill 项目组
; 创建日期  : 2026-06-06
; 版本      : 1.6
; 功能描述  : 事务控制与命令注册（安全执行包装、数据库事务包装、
;             命令注册与登记表维护）
; 依赖模块  : core/utils.il（日志函数）、core/version_adapter.il
;            （ASTB_Txn* 与 ASTB_CmdRegisterSafe）
; 编码      : GBK（含中文注释）
; 修改记录  :
;   2026-06-06 v1.0 allegro_skill 项目组 初始创建
;   2026-07-17 v1.1 修复组_框架核心 txId=nil 时 ASTB_DBTransaction 阻断
;                   数据库修改并明确报错（原为无事务保护继续裸奔）；
;                   ASTB_RegisterCommand 增加 cmdType 符号到字符串的
;                   归一化防御（兼容存量调用）；登记表 Reload 前去重；
;                   errMsgOut 写入加 errset 保护；ASTB_DBTransactionMark
;                   注释明示不回滚语义；删除死函数 ASTB_CreateStub；
;                   文件编码由 UTF-8 转为项目标准 GBK
;   2026-07-19 v1.2 ASTB_RegisterCommand 新增 ?doneCmd/?cancelCmd 透传
;                   (默认 nil, 不影响既有调用)
;   2026-08-01 v1.3 ASTB 项目组 登记表去重 == 改 equal（== 是身份比较
;                   恒假，旧去重从未生效，Reload 后条目/日志双堆积）；
;                   同名同实现幂等命中不再重复登记与刷日志
;   2026-08-20 v1.4 ASTB Team 新增统一撤销命令 astbundo（ASTB_Undo）：
;                   模块批次入栈时 ASTB_UndoJournalPush 打标签日志，
;                   astbundo 按 LIFO 分发到 ASTB_RegisterUndo 注册的
;                   模块撤销函数；先弹日志再执行防异常卡死；
;                   顺带把文件头版本字段从 1.2 补齐对齐（1.3 落过）
;   2026-08-20 v1.5 ASTB Team 修撤销注册表查不到：assoc 对字符串键是
;                   身份比较（项目老坑），改 makeTable（menu.il 实证模式）
;========================================================================

defvar(ASTB_REGISTERED_COMMANDS nil)

;------------------------------------------------------------------------
; 函数名  : ASTB_SafeExec
; 功能    : 带 errset 错误保护的函数执行包装（不开启数据库事务）
; 参数    : proc - 函数符号；args - 参数列表；
;           errMsgOut - 可选，带 value 属性的对象用于回传错误信息
; 返回值  : proc 的返回值；出错返回 nil
;------------------------------------------------------------------------
procedure( ASTB_SafeExec(proc args @optional (errMsgOut nil))
  prog((result errMsg ret)
    when( null(proc)
      ASTB_LogError("ASTB_SafeExec: proc is nil")
      return(nil)
    )
    ret = errset(result = apply(proc args) t)
    if( ret
    then
      return(car(ret))
    else
      errMsg = "Execution error"
      ASTB_LogError(errMsg)
      when( errMsgOut
        ;; errMsgOut 须为带 value 属性的 defstruct/plist，加 errset
        ;; 防止错误处理路径自身再抛错
        errset(errMsgOut->value = errMsg t)
      )
      return(nil)
    )
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_DBTransaction
; 功能    : 在数据库事务保护下执行函数：成功提交、失败回滚
; 参数    : proc - 函数符号；args - 参数列表；errMsgOut - 同 SafeExec
; 返回值  : proc 的返回值；出错或事务无法开启时返回 nil
; 备注    : 事务开启失败（txId=nil）时必须阻断后续数据库修改并明确
;           报错，严禁在无事务保护下继续执行（否则调用方误以为有
;           保护，实际裸奔）
;------------------------------------------------------------------------
procedure( ASTB_DBTransaction(proc args @optional (errMsgOut nil))
  prog((result errMsg ret txId)
    when( null(proc)
      ASTB_LogError("ASTB_DBTransaction: proc is nil")
      return(nil)
    )
    ; 事务底层调用为 axlDBTransactionStart / axlDBTransactionCommit /
    ; axlDBTransactionRollback，封装于 version_adapter.il 的 ASTB_Txn*
    txId = ASTB_TxnStart("ASTB")
    ;; 事务开启失败：阻断数据库修改，明确报错
    unless( txId
      errMsg = "ASTB_DBTransaction: cannot start DB transaction; DB modification BLOCKED"
      ASTB_LogError(errMsg)
      when( errMsgOut
        errset(errMsgOut->value = errMsg t)
      )
      axlUIConfirm("ERROR: Cannot start DB transaction.\nOperation aborted to protect design data.")
      return(nil)
    )
    ret = errset(result = apply(proc args) t)
    if( ret
    then
      unless( ASTB_TxnCommit(txId)
        ASTB_LogError("ASTB_DBTransaction: commit failed")
      )
      return(car(ret))
    else
      errMsg = "DB transaction failed, rolled back"
      ASTB_TxnRollback(txId)
      ASTB_LogError(errMsg)
      when( errMsgOut
        errset(errMsgOut->value = errMsg t)
      )
      return(nil)
    )
  )
)

;========================================================================
; 函数名  : ASTB_DBTransactionMark
; 功能    : 支持撤销 (Ctrl+Z) 的错误保护包装器
; 参数    : proc - 函数符号；args - 参数列表；errMsgOut - 同 SafeExec
; 返回值  : proc 的返回值；出错返回 nil
;
; 重要设计说明（务必阅读）：
;   1. 本函数【不开启事务、出错不回滚】，仅使用 errset 捕获运行时错误。
;   2. 原因：axlDBTransactionStart 开始后所有操作被包裹在事务中，不进入
;      Allegro 标准 Undo 历史。为了让数据库修改支持 Edit -> Undo (Ctrl+Z)，
;      本函数有意不使用 axlDBTransaction*。
;   3. 后果：proc 中途出错时，已执行的数据库修改【保留】，数据库可能处于
;      半修改状态，无自动回滚能力。调用方必须知悉并接受该语义；这是相对
;      规范"数据库修改必须事务包裹"的正式例外，特此记录。
;========================================================================
procedure( ASTB_DBTransactionMark(proc args @optional (errMsgOut nil))
  prog((result errMsg ret)
    when( null(proc)
      ASTB_LogError("ASTB_DBTransactionMark: proc is nil")
      return(nil)
    )
    ; 不使用 axlDBTransactionStart（避免干扰撤销历史）；仅 errset 捕获错误，
    ; 出错【不回滚】，见上方设计说明
    ret = errset(result = apply(proc args) t)
    if( ret
    then
      return(car(ret))
    else
      errMsg = "Execution error (changes NOT rolled back; undo manually if needed)"
      ASTB_LogError(errMsg)
      when( errMsgOut
        errset(errMsgOut->value = errMsg t)
      )
      return(nil)
    )
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_ToSymbol
; 功能    : 将输入归一化为符号（字符串转符号；符号原样返回）
; 参数    : x - 字符串或符号
; 返回值  : 符号；其他类型返回 nil
;------------------------------------------------------------------------
procedure( ASTB_ToSymbol(x)
  cond(
    ( symbolp(x) x )
    ( stringp(x) stringToSymbol(x) )
    ( t nil )
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_RegisterCommand
; 功能    : 注册命令到 Allegro shell 并登记到 ASTB_REGISTERED_COMMANDS
; 参数    : cmdName - 命令名；procName - 回调（符号或字符串）；
;           cmdType - "interactive"/"general"/"sub_cmd"（兼容符号传参，
;           内部归一化为字符串）；undo - 是否声明支持撤销
; 返回值  : t - 成功；nil - 失败
; 备注    : 1. undo 默认 t 为有意保留：存量模块调用均未显式传 ?undo，
;           改默认值会让全部已注册命令静默丢失 undo 声明（向后兼容）。
;           纯查询类命令应由调用方显式传 ?undo nil。
;           2. 重复注册同名命令时先移除旧登记条目，防止 Reload 后
;           登记表累积重复。
;------------------------------------------------------------------------
procedure( ASTB_RegisterCommand(cmdName procName @key (cmdType "general") (undo t) (doneCmd nil) (cancelCmd nil))
  prog((procSym ret cmdStr cmdTypeStr kept already)
    procSym = ASTB_ToSymbol(procName)
    cmdStr = if( stringp(cmdName) then cmdName else sprintf(nil "%s" cmdName) )
    ;; 防御：兼容存量调用方把 cmdType 传成符号（如 'interactive），
    ;; 手册要求 t_cmdType 为字符串，此处统一归一化
    cmdTypeStr = cond(
      ( stringp(cmdType) cmdType )
      ( symbolp(cmdType) sprintf(nil "%s" cmdType) )
      ( t "general" )
    )
    unless( procSym
      ASTB_LogWarn(sprintf(nil "Command %s target is invalid" cmdStr))
      return(nil)
    )
    unless( fboundp(procSym)
      ASTB_LogWarn(sprintf(nil "Command %s target %s not defined" cmdStr procName))
      return(nil)
    )
    ret = ASTB_CmdRegisterSafe(cmdStr procSym ?cmdType cmdTypeStr ?undo undo ?doneCmd doneCmd ?cancelCmd cancelCmd)
    unless( ret
      ASTB_LogWarn(sprintf(nil "Failed to register command %s" cmdStr))
      return(nil)
    )
    ;; 登记表去重：equal 内容比较（== 是身份比较恒假，旧写法去重
    ;; 从未生效，Reload 后条目与日志双重堆积）；同名同实现视为幂等
    ;; 命中：Allegro 侧注册已执行（其本身幂等），登记表与日志不重复
    already = nil
    kept = nil
    foreach( entry ASTB_REGISTERED_COMMANDS
      if( equal(car(entry) cmdStr) then
        when( equal(cadr(entry) procName)
          already = t
        )
      else
        kept = cons(entry kept)
      )
    )
    unless( already
      ASTB_REGISTERED_COMMANDS = cons(list(cmdStr procName cmdTypeStr) reverse(kept))
      ASTB_LogInfo(sprintf(nil "Registered command: %s -> %s" cmdStr procName))
    )
    return(t)
  )
)

printf("[ASTB] core/trans.il loaded.\n")

;------------------------------------------------------------------------
; 函数名  : ASTB_SystemUndo
; 功能    : 调 Allegro 系统级撤销（Edit->Undo，等价 Ctrl+Z），
;           供各交互命令右键菜单 Undo 项统一调用。
; 备注    : 原生撤销对内建操作（move 等）有效；对本机 AXL 建/删对象
;           不覆盖（pitfalls 2.6 实锤）——带批次栈的模块（rvia/ach）
;           右键 Undo 仍走模块自维护撤销
;------------------------------------------------------------------------
procedure( ASTB_SystemUndo()
    errset( axlShell("undo") nil )
    t
)

;; ======================= 统一撤销命令（astbundo） =======================
;; 各模块 Done 批次入自己栈的同时 ASTB_UndoJournalPush 一条模块标签，
;; astbundo 按日志顺序（LIFO）分发到对应模块的撤销函数。
;; 模块侧接线：加载时 ASTB_RegisterUndo("tag" 'XXX_Undo)；
;;             Done 批次成功入栈处 ASTB_UndoJournalPush("tag")。
;; ------------------------------------------------------------------
unless( boundp('_ASTB_undoJournal)  defvar(_ASTB_undoJournal  nil)) ; 批次日志（tag LIFO）
;; 注册表用 makeTable（字符串键相等匹配）；不可用 assoc 列表——
;; assoc 对字符串键是身份比较，注册后永远查不到（16.6 实锤）
unless( boundp('_ASTB_undoRegistry) defvar(_ASTB_undoRegistry makeTable('ASTB_undoRegistry nil)))

procedure( ASTB_RegisterUndo(tag fnSym)
    _ASTB_undoRegistry[tag] = fnSym
    t
)

procedure( ASTB_UndoJournalPush(tag)
    _ASTB_undoJournal = cons(tag _ASTB_undoJournal)
    t
)

procedure( ASTB_Undo()
    prog((tag fn)
        unless( _ASTB_undoJournal
            axlUIWPrint(nil "[ASTB] \303\273\323\320\277\311\263\267\317\372\265\304\274\307\302\274")
            return(nil)
        )
        tag = car(_ASTB_undoJournal)
        fn = _ASTB_undoRegistry[tag]
        ;; 先弹出日志再执行：撤销函数异常也不会卡死队列
        _ASTB_undoJournal = cdr(_ASTB_undoJournal)
        if( and(fn symbolp(fn) getd(fn)) then
            axlUIWPrint(nil sprintf(nil "[ASTB] \263\267\317\372: %s" tag))
            errset(funcall(fn) t)
        else
            axlUIWPrint(nil sprintf(nil "[ASTB] \263\267\317\372\312\247\260\334: \304\243\277\351 %s \316\264\327\242\262\341\263\267\317\372\272\257\312\375" tag))
        )
        return(t)
    )
)

ASTB_RegisterCommand("astbundo" "ASTB_Undo" ?cmdType "general" ?undo nil)

;------------------------------------------------------------------------
; 函数名  : ASTB_Beep / ASTB_BeepToggle
; 功能    : 提示音开关。ASTB_Beep 包 axlUIWBeep，读 astb.cfg 的
;           beep 键（默认 on）；astbbeep 命令切换 on/off 并写盘
;------------------------------------------------------------------------
procedure( ASTB_Beep()
    if( equal(ASTB_GetConfig("beep" "on") "on") then
        axlUIWBeep()
    )
    t
)

procedure( ASTB_BeepToggle()
    prog((cur new)
        cur = ASTB_GetConfig("beep" "on")
        if( equal(cur "on") then
            new = "off"
        else
            new = "on"
        )
        ASTB_SetConfig("beep" new)
        errset( ASTB_SaveConfig() nil )
        axlUIWPrint(nil "\314\341\312\276\322\364\322\321%s\243\250astb.cfg beep=%s\243\251"
            if( equal(new "on") then "\277\252\306\364" else "\271\330\261\325") new)
        return(t)
    )
)
ASTB_RegisterCommand("astbbeep" 'ASTB_BeepToggle ?cmdType "general" ?undo nil)
