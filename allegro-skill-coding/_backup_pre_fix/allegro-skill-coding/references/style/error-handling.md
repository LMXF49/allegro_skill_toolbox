# 错误处理与最佳实践

> 本章基于 Cadence SPB 17.4 官方示例代码提炼，涵盖事务管理、API 返回值检查、异常捕获、表单验证、参数校验及性能优化等核心场景。所有示例代码均保留原始文件路径引用。

---

## 总体原则

**1. 任何与数据库状态相关的操作必须考虑事务一致性。** 官方示例 `cline2shape.il` 和 `axl_delete.il` 均通过 `axlDBTransaction*` 系列 API 实现命令级 undo/redo 支持。

**2. 所有 AXL API 返回值必须显式检查。** 不可假定操作一定成功。`axlDBCreate*`、`axlDeleteObject`、`axlChangeNet` 等函数在失败时返回 `nil` 或空列表，代码中应当通过 `when`/`unless`/`if` 分支处理。

**3. 错误信息必须通过 Allegro 标准消息通道输出。** 优先使用 `axlUIWPrint` 输出到 Command 窗口，使用 `axlMsgPut` 输出到 log 文件，禁止静默失败或直接使用 `printf` 向标准输出打印错误。

**4. 涉及用户交互的命令必须具备完善的 Cancel / Done / Oops 回调。** 回调函数中必须清理选择集、回滚事务、重置全局状态，防止命令退出后遗留脏状态。

**5. 全局变量必须初始化后再使用。** 通过 `boundp` 检查变量是否存在，避免 `unbound variable` 运行时错误。表单句柄、事务标记等全局变量尤为关键。

**6. 文件含中文注释时，必须以 GBK 编码保存。** 这是 Cadence SPB 17.4 在 Windows 平台下的默认编码要求，UTF-8 编码会导致 Allegro 中加载 SKILL 文件时中文注释乱码。

---

## 一、事务管理与 Undo/Redo 支持

### 1.1 交互式命令必须支持事务撤销

应当为所有会修改数据库的交互式命令注册 `?undo t`，并通过 `axlDBTransaction*` 系列 API 管理事务边界。事务标记（mark）必须保存在局部变量中，禁止在命令中途丢失。

来自 `cline2shape.il` 的写法（全局事务回滚模式）：

```skill
; file: /d/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/cline2shape.il

axlCmdRegister("cline2shape" 'LCB_cline_to_shape ?cmdType "interactive"
 ?doneCmd 'LCB_Done ?cancelCmd 'LCB_Cancel ?undo t)

procedure(LCB_cline_to_shape()
let( (lclines layer polydbid)

  LCB_Setup()

  ; cannot have a global transaction if we want undo to roll back each operation
  LCB_mark = axlDBTransactionStart()

  LCBnotDone = t
  while( LCBnotDone
      lclines = axlGetSelSet(axlSelect(?prompt "Select Clines to convert to a shape."))

      foreach( clinedbid lclines
            layer = clinedbid->layer
            polydbid = axlPolyFromDB(clinedbid ?endCapType "ROUND")

            axlDeleteObject(clinedbid)

            unless( axlDBCreateShape(car(polydbid) t layer)  
                axlUIWPrint(nil "ERROR: Failed to create Shape from Cline.")
            )
            when( cadr(polydbid) 
                axlDBCreateShape(cadr(polydbid) t layer) 
            )
     )

     ; marks are only required if undo is using rolling back all database changes
     ; when command is active. When undoing each conversion this is not needed
     ; nor is Oops functional.
     when(LCB_mark axlDBTransactionMark(LCB_mark))
  )
  LCB_Done() ; just in case
))
```

**条文：** 命令注册时 **必须** 指定 `?undo t`，否则用户无法通过 Allegro 的 Undo 菜单撤销该命令造成的数据库变更。

### 1.2 取消操作必须回滚事务

当用户触发 Cancel 回调时，必须调用 `axlDBTransactionRollback` 撤销自 `axlDBTransactionStart` 以来的全部数据库修改，随后将事务标记置为 `nil`，并调用 `axlClearSelSet` 和 `axlCancelEnterFun` 完成清理。

来自 `cline2shape.il` 的写法：

```skill
; file: /d/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/cline2shape.il

procedure(LCB_Cancel()
  axlUIWPrint(nil "** Cancelled Program. **")
  when( LCB_mark axlDBTransactionRollback(LCB_mark))
  LCB_mark = nil
  LCBnotDone = nil
  axlClearSelSet()
  axlCancelEnterFun()
)
```

**条文：** Cancel 回调中 **必须** 按以下顺序执行：1) 回滚事务；2) 将事务标记和循环标志置 `nil`；3) 清空选择集；4) 调用 `axlCancelEnterFun`。禁止遗漏任一步骤。

### 1.3 完成操作必须提交事务

Done 回调中必须提交事务，同样将事务标记置 `nil`。

来自 `cline2shape.il` 的写法：

```skill
procedure(LCB_Done()
  when( LCB_mark axlDBTransactionCommit(LCB_mark))
  LCB_mark = nil
  LCBnotDone = nil
  axlCancelEnterFun()
)
```

### 1.4 Oops 操作必须正确处理事务标记

Oops 回调中应当检查 `axlDBTransactionOops` 的返回值，如果返回 `nil`（已无操作可撤销），则向用户提示信息。

来自 `cline2shape.il` 的写法：

```skill
procedure(LCB_Oops()
  when(LCB_mark
    if(! axlDBTransactionOops(LCB_mark) then
      axlUIWPrint(nil "-- Nothing Left To oops. --")
    else
      axlUIWPrint(nil "-- Replacing Clines. --")
    )
  )
  axlClearSelSet()
)
```

**条文：** Oops 回调中 **应当** 检查 `axlDBTransactionOops` 的返回值，失败时给出友好提示，避免用户困惑。

### 1.5 逐次操作 undo 模式应当使用 start/commit 配对

如果需要将每次操作作为独立的 undo 步骤，必须在每次操作前调用 `axlDBTransactionStart`，操作后调用 `axlDBTransactionCommit`，并传递 `doMark = 'undoMark`。

来自 `cline2shape.il` 的写法（逐次操作 undo 模式）：

```skill
procedure(LCB_cline_to_shape2()
let( (lclines layer polydbid doMark)

  LCB_Setup()
  LCBnotDone = t
  doMark = 'undoMark

  while(LCBnotDone
      lclines = axlGetSelSet(axlSelect(?prompt "Select Clines to convert to a shape."))

      ; don't want to start a transaction unless we have work to do or it will
      ; do a unneeded undoMark.
      when(lclines 
          LCB_mark = axlDBTransactionStart(doMark)
      )

      foreach( clinedbid lclines
            layer = clinedbid->layer
            polydbid = axlPolyFromDB(clinedbid ?endCapType "ROUND")
            axlDeleteObject(clinedbid)
            unless( axlDBCreateShape(car(polydbid) t layer) 
                axlUIWPrint(nil "ERROR: Failed to create Shape from Cline.")
            )
            when( cadr(polydbid) 
                axlDBCreateShape(cadr(polydbid) t layer) 
            )
     )

     when(LCB_mark axlDBTransactionCommit(LCB_mark))
     LCB_mark = nil
  )
  LCB_Done() ; just in case
))
```

**条文：** 逐次 undo 模式下，**应当** 先检查是否有实际工作（`when(lclines ...)`）再启动事务，避免生成无意义的 undo 标记点。

---

## 二、API 返回值检查与错误报告

### 2.1 数据库创建类 API 的返回值必须检查

`axlDBCreateShape`、`axlDBCreateVia`、`axlDBCreatePath` 等函数返回 `dbid` 列表或 `nil`。失败时应当通过 `axlUIWPrint` 向用户报告错误。

来自 `cline2shape.il` 的写法：

```skill
unless( axlDBCreateShape(car(polydbid) t layer)  
    axlUIWPrint(nil "ERROR: Failed to create Shape from Cline.")
)
```

**条文：** 所有 `axlDBCreate*` 调用 **必须** 检查返回值。失败时 **应当** 使用 `axlUIWPrint(nil "ERROR: ...")` 输出明确错误信息，禁止静默丢弃失败结果。

### 2.2 选择操作的结果应当检查是否为空

`axlGetSelSet` 返回选择集列表。如果用户未选择任何对象，列表为空。应当通过 `when` 或 `if` 检查，避免对空列表执行后续操作。

来自 `change_net_on_vias.il` 的写法：

```skill
; file: /d/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/change_net_on_vias.il

vias = axlGetSelSet()
when(vias
    net = cadr(axlUIDataBrowse('NET '(RETRIEVE_OBJECT) "New Net Name" t))
    when(net
        axlDBCloak('_RPVdoNetReplacement( vias net ) 'shape)
    )
)
```

**条文：** 获取用户选择结果后 **应当** 使用 `when` 检查是否为空，避免在空集上执行批量操作。

### 2.3 数据浏览等交互返回值必须校验

`axlUIDataBrowse` 返回 `(result_code dbid)` 形式的列表。必须通过 `cadr` 提取对象，并通过 `when` 检查是否有效。

来自 `change_net_on_vias.il` 的写法：

```skill
net = cadr(axlUIDataBrowse('NET '(RETRIEVE_OBJECT) "New Net Name" t))
when(net
    axlDBCloak('_RPVdoNetReplacement( vias net ) 'shape)
)
```

**条文：** 调用 `axlUIDataBrowse` 后 **必须** 检查 `cadr` 返回值。用户点击 Cancel 时返回 `nil`，禁止在未校验的情况下直接传递结果。

### 2.4 删除操作应当检查返回值并刷新显示

`axlDeleteObject` 返回被删除的对象列表。复杂删除操作（如 shape void、DRC 等）可能因约束或状态限制而失败。应当检查返回值并通过 `axlFlushDisplay` 刷新显示。

来自 `axl_delete.il` 的写法：

```skill
; file: /d/Cadence/SPB_17.4/share/pcb/examples/skill/edit/axl_delete.il

(defun deleteAndPrint (items message)
    (let (result)
	(unless (listp items) (setq items (list items)))
	(axlFlushDisplay)
	(axlMsgPut "")
	(axlMsgPut (sprintf nil "Deleting %L" message))
	(axlMsgPut "---------------------------------------")
	(axlFlushDisplay)
	(setq result (axlDeleteObject items))
	(axlFlushDisplay)
	(mapc 'ashPrintObjData items)
	(axlFlushDisplay)
	(axlMsgPut "")
	result))
```

**条文：** 批量删除操作 **应当** 在删除前后调用 `axlFlushDisplay` 刷新显示，并使用 `axlMsgPut` 输出操作摘要，便于用户通过 `.jrl` 日志回溯问题。

---

## 三、异常捕获与参数校验

### 3.1 预期可能抛出 SKILL 异常的场景应当使用 errset 包裹

当调用参数可能由外部输入决定、且可能触发 SKILL 类型错误时，应当使用 `errset` 捕获异常，防止整个程序中断。

来自 `axldbctvia.il` 的写法：

```skill
; file: /d/Cadence/SPB_17.4/share/pcb/examples/skill/dbcreate/axldbctvia.il

(defun dbc_via_te_args2 ()
	(axlMsgPut "**Starting dbc_via_te_args2")
	;; padstack not a string - caught by Skill
	(errset (axlDBCreateVia 777 1.0:5.0) t)
)
```

**条文：** 当参数合法性无法完全由调用方保证时（如用户输入、外部数据），**应当** 使用 `errset` 包裹可能抛出异常的表达式，第二个参数 `t` 表示在捕获错误后返回 `t` 而非错误对象。

### 3.2 函数入口应当统一参数类型

对于接受列表或单个对象的函数，应当在入口处将单个对象统一转换为列表，避免后续 `foreach` 或 `mapc` 报错。

来自 `axl_delete.il` 的写法：

```skill
(defun deleteAndPrint (items message)
    (let (result)
	(unless (listp items) (setq items (list items)))
	...
	(setq result (axlDeleteObject items))
	...
	result))
```

**条文：** 接受对象或对象列表的函数 **应当** 在入口使用 `unless (listp items) (setq items (list items))` 统一为列表，提高接口的健壮性。

### 3.3 对象有效性应当通过属性访问间接检查

对于可能已被删除或无效的数据库对象，应当检查其 `objType` 属性是否存在，而不是直接假设对象有效。

来自 `axl_delete.il` 的写法：

```skill
(foreach cline clineList
    (when cline->objType (axlDeleteObject cline)))
```

**条文：** 在批量处理数据库对象时，**应当** 先检查 `objType` 属性是否存在，再执行数据库操作。该属性缺失通常意味着对象已失效或已被删除。

---

## 四、表单与 UI 错误处理

### 4.1 表单实例必须防止重复打开

全局表单句柄必须通过 `boundp` 初始化，并在打开表单前检查是否已存在。若已存在，应当调用 `axlUIWExpose` 将其前置，而不是创建新实例。

来自 `cns-design.il` 的写法：

```skill
; file: /d/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/cns-design.il

unless(boundp('_AcDesignFw) _AcDesignFw = nil)

procedure( AcnsDesignForm()
    prog( (fw position)

    ;; Good pratice
    ;; If form is open expose it and return
    fw = _AcDesignFw
    when( fw 
	axlUIWExpose(fw) 
	return(t)
    )
    ...
))
```

来自 `axlform.il` 的写法：

```skill
; file: /d/Cadence/SPB_17.4/share/pcb/examples/skill/form/basic/axlform.il

unless(boundp('f1s) f1s = nil)

procedure( IFormTest(fw)
    prog( (position bitmap_handle graphic_handle)

    ;; Good pratice
    ;; If form is open expose it and return
    (cond (fw 
        (axlUIWExpose fw)
        (return fw)
        )
    )
    ...
))
```

**条文：** 表单全局句柄 **必须** 通过 `unless(boundp('handle) handle = nil)` 初始化。打开表单前 **必须** 检查句柄是否已存在，已存在时 **应当** 调用 `axlUIWExpose` 前置而非重复创建。

### 4.2 表单输入值必须校验后再写入数据库

表单字段变更时，应当在回调中校验用户输入的合法性。如果校验失败，应当调用 `axlFormRestoreField` 恢复字段原值，并通过 `axlUIWPrint` 输出错误提示。

来自 `cns-design.il` 的写法：

```skill
procedure( _AcDesignValidate(fw)
    (prog (result err newValue, constraint parsed)
	parsed = parseString(fw->curField fw->_cnsDsnSep)
	constraint = car(parsed)
	if(( cadr(parsed) == fw->_cnsDsnValue) then
	    result = axlCNSDesignValueCheck(constraint fw->curValue)
	    unless( result
                axlFormRestoreField(fw fw->curField)
		return()
	    )
	    newValue = car(result)	
	    err = cadr(result)
	    
            cond(
            (err == t
		axlFormSetField(fw fw->curField newValue)
		_AcDesignApplyGray(fw t)
                )
            (t
                ; because the error string may have "%" signs need
                ;       to do a default format
                axlUIWPrint(fw 'error "%s" err)
                axlFormRestoreField(fw fw->curField)
                )
            )
	else
	    _AcDesignApplyGray(fw t)
	)
))
```

**条文：** 表单字段验证失败时 **必须** 调用 `axlFormRestoreField` 恢复字段原值，**应当** 通过 `axlUIWPrint` 输出具体错误信息。若错误字符串包含 `%` 等特殊字符，**应当** 使用 `"%s"` 格式避免格式化异常。

### 4.3 表单回调中应当检查 doneState 以判断关闭时机

异步表单模式下，回调函数应当检查 `fw->doneState` 以确定用户是否触发了 Done 或 Cancel 操作。

来自 `axlform.il` 的写法：

```skill
procedure( _afCallback (fw)
     (prog (t1 item field cnt)
	...
	if((nequal fw->doneState 0)  then
	    axlFormClose(fw)
	)
	return()
))
```

**条文：** 异步表单回调中 **应当** 检查 `fw->doneState` 判断是否应当关闭表单。`doneState` 非零表示用户已触发 Done/Cancel/Apply 等关闭操作。

---

## 五、性能优化与批量操作

### 5.1 批量数据库操作应当使用 Cloak 包裹

当涉及大量对象的修改时，应当使用 `axlDBCloak` 包裹操作体，以屏蔽 DRC 检查等副作用，显著提升性能。

来自 `change_net_on_vias.il` 的写法：

```skill
; file: /d/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/change_net_on_vias.il

when(net
    ; Cloak improves performance when multiple vias are involved
    axlDBCloak('_RPVdoNetReplacement( vias net ) 'shape)
)
```

**条文：** 批量修改超过一个数据库对象时 **应当** 使用 `axlDBCloak` 包裹操作体，并指定需要屏蔽的更新类型（如 `'shape`、`'drc` 等）。操作完成后 Cloak 自动解除。

### 5.2 列表操作应当优先使用批量 API

向表单 List 控件填充大量数据时，应当一次性传递列表而非逐条调用 `axlFormSetField`。

来自 `axlform.il` 的写法：

```skill
; file: /d/Cadence/SPB_17.4/share/pcb/examples/skill/form/basic/axlform.il

(defun plisttest ()
     (let (many)
	many = listMany()

	println("Test 1 -- new list -- individual SetFields")
	axlFormListDeleteAll(f1s, "listfield")
	axlShell("stopwatch reset")
	foreach( mapc x many
	    axlFormSetField(f1s, "listfield" x)
	)
	axlFormSetField(f1s, "listfield" nil)
	axlShell("stopwatch stop")

	; This is the optimal method for large lists
	println("Test 2 -- new list -- One call")
	axlFormListDeleteAll(f1s, "listfield")
	axlShell("stopwatch reset")
	axlFormSetField(f1s, "listfield" many)
	axlShell("stopwatch stop")
	...
))
```

**条文：** 填充列表控件时，**应当** 一次性传递完整列表而非逐条 `axlFormSetField`。`axlFormListAddItem` 同样支持一次性传入列表。

---

## 六、全局状态与初始化

### 6.1 全局变量必须防御未定义错误

所有作为全局状态使用的变量（如表单句柄、事务标记、上次用户输入等）在首次加载时可能未定义，必须通过 `boundp` 或 `unless(boundp('var) var = default)` 初始化。

来自 `change_net_on_vias.il` 的写法：

```skill
; file: /d/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/change_net_on_vias.il

; unless( boundp('_rpcLastNet)
    ;_rpcLastNet = ""
;)
```

来自 `cns-design.il` 的写法：

```skill
unless(boundp('_AcDesignFw) _AcDesignFw = nil)
```

来自 `axlform.il` 的写法：

```skill
unless(boundp('f1s) f1s = nil)
unless(boundp('f1s_lastTab) f1s_lastTab = "Fillins")
```

**条文：** 所有全局变量 **必须** 在文件顶部通过 `unless(boundp('var) var = default)` 初始化，防止 `unbound variable` 运行时错误。注释掉的初始化代码仍保留原样，说明该写法是官方推荐的防御模式。

### 6.2 命令退出后必须清理全局状态

Done 和 Cancel 回调中必须将全局循环标志、事务标记等置为 `nil`，防止后续命令复用脏状态。

来自 `cline2shape.il` 的写法：

```skill
procedure(LCB_Done()
  when( LCB_mark axlDBTransactionCommit(LCB_mark))
  LCB_mark = nil
  LCBnotDone = nil
  axlCancelEnterFun()
)

procedure(LCB_Cancel()
  axlUIWPrint(nil "** Cancelled Program. **")
  when( LCB_mark axlDBTransactionRollback(LCB_mark))
  LCB_mark = nil
  LCBnotDone = nil
  axlClearSelSet()
  axlCancelEnterFun()
)
```

**条文：** 命令退出回调中 **必须** 将所有全局临时状态（事务标记、循环标志、选择集）清理完毕。禁止在命令退出后残留未提交的事务或未清空的选择集。

---

## 七、编码与文件规范

### 7.1 文件头必须包含免责声明

官方示例文件均包含版权声明和免责声明。自定义 SKILL 文件应当遵循相同格式，明确声明代码风险。

来自 `disclaimer.il` 的写法：

```skill
; file: /d/Cadence/SPB_17.4/share/pcb/examples/skill/disclaimer.il

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ; Skill File
 ;
 ; Author --
 ;	Cadence Design Systems
 ;
 ; Function --
 ;
 ;	
 ; Copyright, 2007, Cadence Design Systems, Inc.
 ; No part of this file may be reproduced, stored in a retrieval system,
 ; or transmitted in any form or by any means --- electronic, mechanical,
 ; photocopying, recording, or otherwise --- without prior written permission
 ; of Cadence Design Systems, Inc.
 ;
 ; WARRANTY:
 ; NONE. NONE. NONE.
 ; Use all material in this code at your own risk.  Cadence Design Systems 
 ; makes no claims about any material in this archive.  These examples may
 ; not function or may only function in specific instances. We'd like to hear 
 ; what you think of our approach to this, and how we can improve it.
 ;
 ; RESTRICTIONS:
 ; All software contained within this archive is in the public domain or
 ; the author has given us permission for redistribution.  Some packages
 ; have explicit copyrights and notices concerning their redistribution.
 ; Please carefully read all documentation with any package on this tape.
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
```

**条文：** 发布的 SKILL 文件 **应当** 在头部包含 DISCLAIMER，明确声明 "WARRANTY: NONE" 和使用风险，避免法律纠纷。

### 7.2 中文注释必须使用 GBK 编码保存

Cadence SPB 17.4 在 Windows 平台下默认使用 GBK 编码解析 SKILL 源文件。含中文注释的文件若以 UTF-8 保存，会导致 Allegro 中加载时出现乱码。

**条文：** 任何包含中文字符（注释、字符串）的 `.il` 文件 **必须** 以 **GBK 编码** 保存。在 VS Code 中，可通过状态栏点击编码选项选择 "通过编码保存" → "GBK"。禁止以 UTF-8 编码保存含中文的 SKILL 文件。

---

## 八、示例代码汇总

### 8.1 完整的交互式命令错误处理模板

```skill
; 完整的命令注册 + 事务 + 错误处理模板
; 来源：综合 cline2shape.il + change_net_on_vias.il

axlCmdRegister("mycommand" 'MyCommand ?cmdType "interactive"
 ?doneCmd 'MyDone ?cancelCmd 'MyCancel ?undo t)

unless(boundp('MyCmdMark) MyCmdMark = nil)
unless(boundp('MyCmdLoop) MyCmdLoop = nil)

procedure(MyCommand()
let( (objs result)
  MyCmdLoop = t
  MyCmdMark = axlDBTransactionStart()

  while(MyCmdLoop
    objs = axlGetSelSet(axlSelect(?prompt "Select objects:"))
    when(objs
      result = MyProcessObjects(objs)
      unless(result
        axlUIWPrint(nil "ERROR: Processing failed for selected objects.")
      )
    )
    when(MyCmdMark axlDBTransactionMark(MyCmdMark))
  )
  MyDone()
))

procedure(MyDone()
  when(MyCmdMark axlDBTransactionCommit(MyCmdMark))
  MyCmdMark = nil
  MyCmdLoop = nil
  axlClearSelSet()
  axlCancelEnterFun()
)

procedure(MyCancel()
  axlUIWPrint(nil "** Command Cancelled. **")
  when(MyCmdMark axlDBTransactionRollback(MyCmdMark))
  MyCmdMark = nil
  MyCmdLoop = nil
  axlClearSelSet()
  axlCancelEnterFun()
)
```

### 8.2 表单验证与错误处理模板

```skill
; 来源：综合 cns-design.il + axlform.il

unless(boundp('MyFormHandle) MyFormHandle = nil)

procedure(MyFormOpen()
  prog( (fw)
    when(MyFormHandle
      axlUIWExpose(MyFormHandle)
      return(t)
    )
    fw = axlFormCreate('MyFormHandle "myform" '("NE" "msglines" 1) '_MyFormCB t nil)
    axlFormDisplay(fw)
  )
)

procedure(_MyFormCB(fw)
  case(fw->curField
    ("done"
      _MyFormDone(fw)
      axlFinishEnterFun()
    )
    ("cancel"
      axlFormClose(fw)
      MyFormHandle = nil
      axlCancelEnterFun()
    )
    (t
      _MyFormValidate(fw)
    )
  )
  if((nequal fw->doneState 0) then
    axlFormClose(fw)
    MyFormHandle = nil
  )
)

procedure(_MyFormValidate(fw)
  let((valid result)
    valid = MyCheckValue(fw->curField fw->curValue)
    unless(valid
      axlUIWPrint(fw 'error "Invalid value for field %s" fw->curField)
      axlFormRestoreField(fw fw->curField)
    )
  )
)
```

### 8.3 批量操作与 Cloak 使用模板

```skill
; 来源：change_net_on_vias.il

procedure(MyBatchOp(objs newValue)
  let((count)
    count = 0
    when(objs
      ; 屏蔽 shape 更新以提升性能
      axlDBCloak('_MyDoWork(objs newValue) 'shape)
    )
    axlMsgPut("Processed %d objects." count)
  )
)

procedure(_MyDoWork(objs newValue)
  foreach(obj objs
    when(obj->objType
      axlMyOperation(obj newValue)
    )
  )
)
```

---

> **参考文件索引**
> - `cline2shape.il` — 事务管理、undo/redo、错误输出
> - `axldbctvia.il` — 参数错误测试、`errset` 异常捕获
> - `change_net_on_vias.il` — 选择集检查、`axlDBCloak` 批量操作
> - `cns-design.il` — 表单验证、字段恢复、防重复打开
> - `axlform.il` — 异步表单模式、`doneState` 检查、列表批量填充
> - `menu.il` — 菜单操作返回值检查
> - `read.il` — 文件 I/O（含 `outfile`/`close` 但不完整错误处理）
> - `disclaimer.il` — 文件头免责声明模板
> - `axl_delete.il` — 参数类型统一、对象有效性检查、删除操作返回值
