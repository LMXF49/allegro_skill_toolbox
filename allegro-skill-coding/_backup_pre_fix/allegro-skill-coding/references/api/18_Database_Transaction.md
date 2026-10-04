# 第 18 章 数据库事务 (Database Transaction)

> **来源**：`17dbtran.html`  
> **产品版本**：Allegro SKILL Reference 17.4-2019, October 2019

---

## 概述 (Overview)

**说明**：本章描述 AXL-SKILL 数据库事务函数。

**Original**: This chapter describes the AXL-SKILL Database Transaction functions.

---

### axlDBCloak

**说明**：在修改数据库中的许多项目时提高性能并减少程序内存使用。您使用 `axlDBCloak` 以批处理模式更新许多蚀刻（etch）或封装符号（package symbol）。其工作方式类似于 SKILL 的 `eval` 函数。您使用以下格式向它传递函数及其参数：

**Original**: Improves performance and program memory use while modifying many items in the database. You use axlDBCloak to update many etch or package symbols in batch mode. Works like SKILL's eval function. You pass it a function and its arguments using the following format:

```skill
axlDBCloak( 'MyFunc (myargs) )
```

您可以使用 `axlDBCloak` 执行以下操作：

**Original**: You can use axlDBCloak to do the following:

- 批量处理任何基于网络的 DRC 更新。

**Original**: Batch any net based DRC updates.

- 批量处理连接性更新。

**Original**: Batch connectivity update.

- 可选地，如果 `s_mode` 为 `'shape`，则批量处理动态形状更新。

**Original**: Optionally, batch dynamic shape updates if s_mode is 'shape.

- 可选地，如果 `s_mode` 为 `'ignoreFixed`，则忽略 FIXED 属性。

**Original**: Optionally, ignores the FIXED property if s_mode is 'ignoreFixed.

- 可选地，如果 `s_mode` 为 `'disableDisplay`，则延迟画布重绘。

**Original**: Optionally, delays canvas redraws if s_mode is 'disableDisplay.

- 在函数周围加入 `errset`，以便任何抛出的 SKILL 错误都会被 `axlDBCloak` 捕获。

**Original**: Incorporate an errset around your function so any SKILL errors thrown are caught by axlDBCloak.

如果需要以批处理模式更新许多蚀刻或封装符号，则必须使用此函数。

**Original**: This function must be used if you need to update many etch or package symbols in a batch fashion.

**请勿**在以下情况下使用 `axlDBCloak`：

**Original**: Do not use axlDBCloak in these circumstances:

- 如果您正在添加或删除非连接性数据库项（例如，将许多线加载到制造层）。

**Original**: If you are adding or deleting non-connectivity database items (for example, loading many lines to a manufacturing layer)

- 如果您需要与用户交互。由于连接性未更新，请勿使用 `axlEnterXXX` 函数。相反，先从用户获取信息，然后执行 cloak 更新。

**Original**: If you need to interact with the user. Since connectivity is not updated, do not use the axlEnterXXX functions. Instead, get the information from the user first, then do the cloak update.

- 如果您正在读取数据库，使用 cloak 没有帮助，实际上可能会降低性能。

**Original**: If you are reading the database, using cloak does not help and may actually slow performance.

- 如果仅进行一次更改，使用 Cloak 会降低性能。

**Original**: If making a single change, using Cloak slows performance.

使用 Cloak 会将任何数据库 ID 设置为 `nil`。

**Original**: Using Cloak sets any database ids to nil.

**gmode 选项**（如果需要多个选项，请传递选项列表）：

**Original**: gmode options (if multiple required pass a list of options)

- `'shape`: 如果所做的更改影响设计中的任何动态形状，则提高性能。通常，如果更改影响 ETCH 层，则应设置此选项。

**Original**: 'shape — Improves performance if changes being made effect any dynamic shapes on the design. Generally you should set this if effecting ETCH layers with your changes.

- `'ignoreFixed`: 使系统忽略 FIXED 属性（请参阅 `axlDBIgnoreFixed`）。

**Original**: 'ignoreFixed — Have the system ignore the FIXED property (see axlDBIgnoreFixed)

- `'disableDisplay`: 在处理过程中不更新主画布显示。

**Original**: 'disableDisplay — Do not update the main canvas display during processing.

**警告 (CAUTIONS)**：

一个常见的编程错误是遗漏了允许 `axlDBCloak` 评估函数的撇号（`'`）。

**Original**: A frequent programming error is to leave of the tick (') mark that allows axlDBCloak to evaluate the function.

**正确模型 (CORRECT MODEL)**：
```skill
axlDBCloak( 'MyFunc(myArgs) '(shape ignoreFixed))
```

**错误模型 (INCORRECT MODEL)**：
```skill
axlDBCloak( MyFunc(myArgs) '(shape ignoreFixed))
```

两者都能工作，但在错误的情况下，cloaking 函数不会为 `MyFunc` 提供性能提升。

**Original**: Both work but in the incorrect case now performance benefit offered by the cloaking function will by applied to MyFunc.

**数据库事务和 cloaking（`axlDBTransactionStart`）**：

**Original**: Database transactions and cloaking (axlDBTransactionStart):

请勿在 cloak 内启动事务，然后在 cloak 外终止它。终止意味着调用 `axlDBTransactionRollback`、`axlDBTransactionCommit` 或 `axlDBTransactionOops` 中的任何一个。

**Original**: Do NOT start and transaction inside a cloak and then terminate it outside the cloak. Terminate means calling either axlDBTransactionRollback, axlDBTransactionCommit axlDBTransactionOops.

**语法**：
```skill
axlDBCloak(
  g_func
  [s_mode]/[ls_mode]
)
```

**参数**：

- `g_func`: 带有任何参数的函数。

**Original**: Function with any of its arguments.

- `s_mode`: 选项。

**Original**: option

- `ls_mode`: 选项列表。

**Original**: list of options

**返回值**：

- 返回 `g_func` 返回的内容。

**Original**: Returns what g_func returns.

**示例**：

```skill
procedure( DeleteSymbols()
  let( (listOfSymbols)
    listOfSymbols = axlDBGetDesign()->symbols
    when( listOfSymbols
      axlDBCloak( 'DeleteDoit(listOfSymbols) 'shape ))
    axlShell("cputime stop")
))

procedure( DeleteDoit(listOfDatabaseObjects )
  foreach(c_item listOfDatabaseObjects
    printf("REFDES %s\n", c_item->refdes)
    axlDeleteObject(c_item)
  )
  nil
)
```

删除数据库中所有已放置的符号。

**Original**: Deletes all placed symbols in the database.

**另请参阅 (See Also)**：`axlDBTransactionStart`

**Original**: See Also `axlDBTransactionStart`

---

### axlDBTransactionCommit

**说明**：从上次事务标记处提交数据库事务。

**Original**: Commits a database transaction from the last transaction mark.

**语法**：
```skill
axlDBTransactionCommit(
  x_mark
)
```

**参数**：

- `x_mark`: 从 `axlDBTransactionStart` 返回的数据库事务标记。

**Original**: Database transaction mark returned from axlDBTransactionStart.

**返回值**：

- `t`: 数据库事务已提交。

**Original**: Database transaction committed.

- `nil`: 数据库事务未提交。

**Original**: Database transaction not committed.

**示例**：

请参阅 `axlDBTransactionStart()` 获取示例。

**Original**: See axlDBTransactionStart() for an example.

---

### axlDBTransactionMark

**说明**：在数据库中写入一个标记，您可以使用 `axlDBTransactionOops` 回滚到该标记处的数据库更改。

**Original**: Writes a mark in the database that you can use with axlDBTransactionOops to rollback database changes to this mark.

当事务标记被提交或回滚时，与该标记关联的所有 `axlDBTransactionMarks` 都会被丢弃。

**Original**: When a transaction mark is committed or rolled back, all axlDBTransactionMarks associated with that mark are discarded.

**语法**：
```skill
axlDBTransactionMark(
  x_mark
)
```

**参数**：

- `x_mark`: 从 `axlDBTransactionStart` 返回的数据库事务标记。

**Original**: Database transaction mark returned from axlDBTransactionStart.

**返回值**：

- `t`: 标记已写入数据库。

**Original**: Mark written in the database.

- `nil`: 未在数据库中写入标记。

**Original**: No mark written in the database.

**示例**：

请参阅 `axlDBTransactionStart()` 获取示例。

**Original**: See axlDBTransactionStart() for an example.

---

### axlDBTransactionOops

**说明**：撤销事务到最后一个标记，或如果没有标记则撤销到开始。支持 Allegro 的 oops 数据库事务模型。

**Original**: Undoes a transaction back to the last mark, or to start if there are no marks. Supports the Allegro oops model for database transactions.

当事务标记被提交或全部回滚时，该标记不再适用于 oops 操作。

**Original**: When a transaction mark is committed or rolled back all, then that mark is no longer valid for oops action.

**语法**：
```skill
axlDBTransactionOops(
  x_mark
)
```

**参数**：

- `x_mark`: 从 `axlDBTransactionStart` 返回的数据库事务标记。

**Original**: Database transaction mark returned from axlDBTransactionStart.

**返回值**：

- `t`: 事务撤销完成。

**Original**: Transaction undo completed.

- `nil`: 事务已经回退到起始标记，没有剩余内容可 oops。

**Original**: Transaction is already back to the starting mark and there is nothing left to oops.

**示例**：

请参阅 `axlDBTransactionStart` 获取示例。

**Original**: See axlDBTransactionStart for an example.

---

### axlDBTransactionRollback

**说明**：数据库事务的撤销函数。

**Original**: Undo function for a database transaction.

**语法**：
```skill
axlDBTransactionRollback(
  x_mark
)
```

**参数**：

- `x_mark`: 从 `axlDBTransactionStart` 返回的数据库事务标记。

**Original**: Database transaction mark returned from axlDBTransactionStart.

**返回值**：

- `t`: 事务撤销完成。

**Original**: Transaction undo completed.

- `nil`: 事务撤销未完成。

**Original**: Transaction undo not completed.

**示例**：

请参阅 `axlDBTransactionStart` 获取示例。

**Original**: See axlDBTransactionStart for an example.

---

### axlDBTransactionStart

**说明**：标记数据库事务的开始。向调用者返回一个标记，该标记被传递回提交、标记、oops 或回滚函数以支持嵌套事务。只有此函数的最外层调用者（第一个调用者）才有权提交或回滚整个事务。

**Original**: Marks the start of a transaction to the database. Returns a mark to the caller which is passed back to commit, mark, oops or rollback for nested transactions. Only the outermost caller of this function (the first caller) has control to commit or rollback the entire transaction.

您将此函数与其他 `axlDBTransaction` 函数一起使用。

**Original**: You use this function with other axlDBTransaction functions.

当您的 SKILL 代码终止时，Allegro 会取消任何仍处于活动状态的事务。您不能启动一个事务并使其在 Allegro 命令之间保持活动状态，以试图支持 undo。

**Original**: Allegro cancels any transactions left active when your SKILL code terminates. You cannot start a transaction and keep it active across Allegro commands as an attempt to support undo.

保存或打开数据库会取消事务。

**Original**: Saving or opening a database cancels transactions.

**语法**：
```skill
axlDBTransactionStart(
  [g_undoMark]
)
```

**参数**：

- `g_undoMark`: 应设置为 `'undoMark`，用于希望有多个 undo 事件的命令。例如，在放置多个独立符号时，您可能希望每次放置都是一个独立的 undo 事件。

**Original**: This should be set to 'undoMark that are for commands that want multiple undo events. For example, when placing multiple individual symbols, you may want each placement to be an individual undo event.

默认情况下，使用 undo 交互时，命令内的所有操作产生单个 undo 事件。请参阅 `axlCmdRegister` 了解如何编写支持 Allegro undo 的 SKILL 命令。

**Original**: By default, with a undo interactive all operations within the command results in a single undo even. See in axlCmdRegister on how write a SKILL command that supports Allegro undo.

**返回值**：

- `x_mark`: 指示事务开始的整数标记。

**Original**: Integer mark indicating transaction start.

- `nil`: 标记事务开始失败。

**Original**: Failed to mark transaction start.

**示例 1**：

模拟 Allegro 的 oops 模型。

**Original**: Emulates the Allegro oops model.

```skill
mark = axlDBTransactionStart()
...#1 do stuff ...
axlDBTransactionMark(mark)
...#2 do stuff ...
axlDBTransactionMark(mark)
...#3 do stuff ...
;; do an oops of the last two changes
axlDBTransactionOops( mark ) ; oops out #3
axlDBTransactionOops( mark ) ; oops out #2
axlDBTransactionOops( topList); commit only #1
```

**示例 2**：

多个 Start 标记。

**Original**: Multiple Start marks

```skill
i = axlDBTransactionStart()
... do stuff ...
j = axlDBTransactionStart()
... stuff ...
axlDBTransactionCommit(j) ;; this is not really commited
;;till the outer commit
j = axlDBTransactionStart()
... do more stuff ...
axlDBTransactionRollback(j) ;; oops out "do more stuff"
axlDBTransactionCommit(i) ;; commit changes to database
```

数据库事务函数**不会**标记选择集。应用程序负责选择集管理。

**Original**: Database transaction functions do NOT mark select sets. The application handles select set management.

**另请参阅 (See Also)**：`axlDBTransactionMark`、`axlDBTransactionOops`、`axlDBTransactionCommit`、`axlDBTransactionRollback`、`axlCmdRegister`

**Original**: See Also axlDBTransactionMark, axlDBTransactionOops, axlDBTransactionCommit, axlDBTransactionRollback, axlCmdRegister

---

