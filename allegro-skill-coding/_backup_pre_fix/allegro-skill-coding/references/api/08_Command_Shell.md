# 第 8 章 命令 Shell (Command Shell)

## Allegro PCB Editor 命令 Shell 函数 (Allegro PCB Editor Command Shell Functions)

**产品文档**: Allegro SKILL Reference  
**产品版本**: 17.4-2019, October 2019

---

## 命令 Shell 函数 (Command Shell Functions)

**说明**：本章描述访问 Allegro PCB Editor 环境和命令 Shell 的 AXL-SKILL 函数。

**Original**: This chapter describes the AXL-SKILL functions that access the Allegro PCB Editor environment and command shell.

---

### axlGetAlias

**说明**：请求指定 Allegro PCB Editor 别名 `t_alias` 的值。如果给定 `nil`，则返回当前已设置的别名列表。为了兼容，`axlGetAlias` 也返回 funckey 设置。

**Original**: Requests the value of the specified Allegro PCB Editor alias, t_alias. If given a nil, returns a list of aliases currently set. For compatibility purposes, axlGetAlias returns funckey settings.

**语法**：
```skill
axlGetAlias(t_alias/nil)
```

**参数**：
- `t_alias` — Allegro PCB Editor 环境别名的名称。

**返回值**：
- `t_value` — Allegro PCB Editor 环境别名的字符串值。
- `lt_names` — 别名名称列表。
- `nil` — 别名未设置。

**另请参阅**：`axlSetAlias`, `axlGetFunckey`

**示例 1**：
```skill
alias = axlGetAlias("SF2")
=> "grid"
```
获取分配给 Shift 功能键 F2 的别名的值。

**示例 2**：
```skill
list_alias = axlGetAlias(nil)
=> ("F2" "F3" "F4" ...)
```
返回所有已设置的别名。

---

### axlGetFunckey

**说明**：请求指定 funckey `t_alias` 的值。如果给定 `nil`，则返回当前已设置的 funckey 列表。

**Original**: Requests the value of the specified funckey, t_alias. If given nil, returns a list of currently set funckeys.

**语法**：
```skill
axlGetFunckey(t_alias/nil)
```

**参数**：
- `t_alias` — 环境 funckey 的名称。如果为 `nil`，返回所有当前 funckey 的列表。

**返回值**：
- `t_value`/`nil` — 环境 funckey 的字符串值。如果 funckey 未设置则返回 `nil`。
- `lt_names` — 如果传入 `nil`，返回 funckey 名称列表。

**另请参阅**：`axlSetFunckey`, `axlGetAlias`

**示例**：
```skill
alias = axlGetFunckey("m")
==> "grid"
```
获取分配给 Shift 功能键 m 的 funckey 的值。

```skill
list_alias = axlGetFunckey(nil)
==> ("-" "+" "m")
```
返回所有已设置的 funckey。

---

### axlGetVariable

**说明**：请求指定 Allegro PCB Editor 环境变量 `t_variable` 的值。返回包含分配给该变量的字符串的列表，如果变量当前未设置则返回 `nil`。如果变量存储的是项目列表（例如 PATH 变量），使用 `axlGetVariableList` 以保留每个项目中的空格。

**Original**: Requests the value of the specified Allegro PCB Editor environment variable, t_variable. Returns a list containing the string assigned to the variable or nil if the variable is currently not set in Allegro PCB Editor. Use axlGetVariableList where the variable stores a list of items (such as a PATH variable) to preserve any spaces in each item.

变量名不区分大小写。变量名和值可能会随版本变化。

**语法**：
```skill
axlGetVariable(t_variable)
```

**参数**：
- `t_variable` — 给出 Allegro PCB Editor 环境变量名称的字符串。如果为 `nil`，返回 Allegro PCB Editor 中所有已设置变量的列表。

**返回值**：
- `t_value` — 包含 Allegro PCB Editor 环境变量字符串值的列表。
- `nil` — 变量未设置。
- `lt_names` — 变量名称列表（当传入 `nil` 时返回）。

**另请参阅**：`axlUnsetVariable`, `axlSetVariable`, `axlGetVariableList`, `axlReadOnlyVariable`, `axlSetVariableFile`, `axlUnsetVariableFile`

**示例**：
```skill
menu = axlGetVariable("menuload")
==> "geometry"
```
获取当前加载的菜单的值。

```skill
psmpath = axlGetVariable("psmpath")
==> ". symbols"
```
获取库搜索路径 `libpath` 的值。

---

### axlGetVariableList

**说明**：请求指定 Allegro PCB Editor 环境变量 `t_variable` 的值。与 `axlGetVariable` 不同，如果变量是数组（例如 Allegro PCB Editor 的路径变量），此函数返回一个字符串列表。如果变量是单个项目，则返回与 `axlGetVariable` 相同。

**Original**: Requests the value of the specified Allegro PCB Editor environment variable, t_variable. Unlike axlGetVariable this returns a list of strings, if the variable is an array, such as one of Allegro PCB Editor's path variables. If variable is a single item, the return is the same as axlGetVariable.

由于路径变量可能包含空格，使用 `axlGetVariable` 接口然后使用 SKILL 的 `parseString` 命令将其拆分回组件片段将不会给出正确结果。

变量名不区分大小写。变量名和值可能会随版本变化。

**语法**：
```skill
axlGetVariableList(t_variable/nil)
```

**参数**：
- `t_variable` — Allegro PCB Editor 环境变量的名称。如果为 `nil`，返回 Allegro PCB Editor 中所有已设置变量的列表。

**返回值**：
- `t_value` — Allegro PCB Editor 环境变量的字符串值。
- `nil` — 如果变量未设置则返回 `nil`。
- `lt_names` — 变量名称列表，当传入 `nil` 作为参数时返回。

**另请参阅**：`axlGetVariable`

**示例**：
```skill
path = axlGetVariableList("psmpath")
==> ("." "symbols" "/cds/root/share/pcb/allegrolib/symbols")
```
获取 Package Symbol 搜索路径的值。

---

### axlJournal

**说明**：此函数管理程序的日志文件。它有几种操作模式：
- `g_option = 'close` — 关闭当前日志文件；返回关闭文件的名称。
- `g_option = <t_filename>` — 关闭当前日志文件并打开新文件，如果成功返回 `t`，如果不能打开文件则返回 `nil`。失败的副作用是当前日志文件被关闭。
- `g_option = 'name` — 返回当前日志文件的完整路径名，如果没有活动的日志文件则返回 `nil`。

通常日志文件是缓冲的。在文件打开时读取它可能是不可预测的。在 Windows 上，一个打开用于写入的文件不能被读取。您必须先关闭它。

**Original**: This function manages the program's journal file. It has several modes of operation: g_option = 'close closes current journal file; returns name of closed file; g_option = <t_filename> close current journal file and opens no file, returns t if successful, nil if can't open file. Side effect of failure is current journal file is closed. g_option = 'name returns fullpath name of current journal file, nil if no active journal file. Typically the journal file is buffered. Reading the file while it is open may be unpredictable. On Windows, an open file for writing cannot be read. You must close it first.

**语法**：
```skill
axlJournal(g_option)
```

**参数**：
- `g_mode` — 见上述说明。

**返回值**：见上述说明。

**示例**：
```skill
axlJournal('name)          ; 获取文件名
axlJournal("my_journal")   ; 在当前目录的 tmp 中打开新文件
```

---

### axlProtectAlias

**说明**：控制别名的只读属性。

**注意**：不要取消保护 F1，因为它被操作系统固定为 `Help`。您必须先定义别名才能保护它。

**Original**: Controls the read-only attribute of an alias. Notes: Do not unprotect F1 as this is fixed to Help by the operating system. You must define the alias before you can protect it.

**语法**：
```skill
axlProtectAlias(t_alias t/nil)
```

**参数**：
- `t_alias` — Allegro PCB Editor 环境别名的名称。
- `t/nil` — `t` 保护别名，`nil` 取消保护别名。

**返回值**：
- `t` — 成功保护或取消保护别名。
- `nil` — 别名未设置，或函数接收到无效数据。

**示例**：
```skill
axlProtectAlias("F2" t)
```
保护 F2 功能键。

---

### axlIsProtectAlias

**说明**：测试别名是否为只读（或可写）。这也可能与 funckeys 一起使用。

**Original**: Tests if the alias is read-only (or writable). This may also be used with funckeys.

**语法**：
```skill
axlIsProtectAlias(t_alias)
```

**参数**：
- `t_alias` — Allegro PCB Editor 环境别名的名称。

**返回值**：
- `t` — 别名受保护。
- `nil` — 别名未受保护或未设置。

**另请参阅**：`axlIsProtectAlias`, `axlReadOnlyVariable`

---

### axlReadOnlyVariable

**说明**：设置、取消设置或查询 Allegro PCB Editor 环境变量的只读状态。一旦变量设置为只读，就不能更改。当您将未设置的变量设置为只读时，用户将无法设置它。

变量名不区分大小写。

**Original**: This sets, unsets or queries the read-only state of an Allegro PCB Editor environment variable. Once a variable is set read only it cannot be changed. When you set a variable that is unset to read only, the user then cannot set it. Variable names are case insensitive.

**语法**：
```skill
axlReadOnlyVariable(t_variable [g_Enable])
```

**参数**：
- `t_variable` — Allegro PCB Editor 环境变量的名称。
- `g_Enable` — `t` 设置为只读；`nil` 设置为可写；如果不提供则用于测试变量只读状态。

**返回值**：
- `t`/`nil` — 在查询模式下（无 `g_Enable` 选项）如果变量是只读则返回 `t`，否则返回 `nil`。如果更改只读模式，成功则返回 `t`，如果变量当前未设置则返回 `nil`。

**另请参阅**：`axlGetVariable`, `axlGetVariableList`

**示例**：
```skill
axlReadOnlyVariable("psmpath" t)
axlReadOnlyVariable("psmpath")
==> t
axlReadOnlyVariable("psmpath" nil)
axlReadOnlyVariable("psmpath")
==> nil
```

查询所有只读变量：
```skill
axlReadOnlyVariable("fxf" t)
axlReadOnlyVariable("psmpath" t)
axlReadOnlyVariable(nil)
==> ("psmpath" "fxf")
```

---

### axlSetAlias

**说明**：您可以使用 `axlSetAlias` 函数将 Allegro PCB Editor 环境别名设置为名称 `t_alias` 和值 `g_value`。`g_value` 可以是字符串、整数、`t` 或 `nil`。返回分配给别名的字符串，如果别名无法在 Allegro PCB Editor 中设置则返回 `nil`。

您可以使用功能键 F2-F12、大多数带 control 修饰符的字母数字键（虽然 Control-C、V 和 X 保留用于复制、粘贴和剪切）以及导航键（Home、上箭头、Esc 等）。您可以按以下方式修改这些项：

**Original**: You can set the Allegro PCB Editor environment alias with the name given by the string t_alias to the value g_value using the axlSetAlias function. g_value can be a string, int, t, or nil. Returns the string assigned to the alias or nil if the alias cannot be set in Allegro PCB Editor.

| 修饰符 (Modifier) | 指示符 (Indicator) | 示例 (Example) |
|---|---|---|
| Shift | S | SF2 |
| Control | C（功能键） | CF2 |
| Control | ~（字母数字） | ~N |
| Meta | A | AF2 |

修饰符可以组合使用，例如：
- `CSF2` — Control-Shift F2
- `ASF2` — Meta-Shift F2
- `CAF2` — Control-Meta F2
- `CASF2` — Control-Meta-Shift F2
- `~SZ` — Control-Shift Z
- `SUp` — Shift-Up Arrow
- `CUp` — Control-Up Arrow

`axlSetFunckey` 和 `axlSetAlias` 共享相同的数据存储。

**注意**：
- 别名设置仅适用于当前会话。它们不会保存到用户的本地 env 文件中。
- 别名更改不会影响从 Allegro PCB Editor 启动的程序，例如 import logic、refresh_symbol。
- 要设置 funckeys，请参阅 `axlSetFunckey`、`axlGetAlias`、`axlProtectAlias`、`axlIsProtectAlias`、`axlSetAlias`、`axlGetAlias`、`axlProtectAlias` 和 `axlIsProtectAlias`。

**语法**：
```skill
axlSetAlias(t_alias g_value)
```

**参数**：
- `t_alias` — Allegro PCB Editor 环境别名的名称。
- `g_value` — 环境别名要设置的值。可以是字符串或 `nil`。

**返回值**：
- `t` — 别名已设置。
- `nil` — 无效数据或别名被标记为只读。

**示例 1**：
```skill
axlSetAlias("F2" "save")
```
将 F2 功能键设置为 `save` 命令。

**示例 2**：
```skill
axlSetAlias("~S" nil)
```
取消设置 `Ctrl-S` 别名。

---

### axlSetFunckey

**说明**：与 `axlSetAlias` 类似，但允许字母数字键像功能键一样工作（不需要按 Enter 键）。有关完整文档请参阅 `axlSetAlias`。

Funckey 设置仅适用于当前会话。它们不会保存到用户的本地 env 文件中。Funckey 更改不影响从 Allegro PCB Editor 启动的程序：例如 `import logic` 或 `refresh_symbol`。

**Original**: Works similar to axlSetAlias except allows alpha-number keys to work like function keys (no Enter key required). See axlSetAlias for complete documentation.

**语法**：
```skill
axlSetFunckey(t_alias g_value)
```

**参数**：
- `t_alias` — Allegro 环境别名的名称。
- `g_value` — 环境别名要设置的值。可以是字符串或 `nil`。

**返回值**：
- `t` — 如果成功则返回 `t`。
- `nil` — 如果数据类型无效或别名被标记为只读则返回 `nil`。

**另请参阅**：`axlGetFunckey`, `axlIsProtectAlias`, `axlSetAlias`

**示例**：
```skill
axlSetFunckey("m" "move" t)
axlSetFunckey("m" nil)
```
设置/取消设置 move 的 funckey 别名。

---

### axlSetVariable

**说明**：将 Allegro PCB Editor 环境变量设置为名称 `t_variable` 和值 `g_value`。`g_value` 可以是字符串、整数、`t` 或 `nil`。返回分配给变量的字符串，如果变量无法在 Allegro PCB Editor 中设置则返回 `nil`。

`511` 是最大列表长度（`lt_variable`）。

**注意**：
- 变量名和值可能会随版本变化。
- 变量设置仅适用于当前会话。它们不会保存到用户的本地 env 文件中。
- 变量更改不影响从 Allegro PCB Editor 启动的程序。例如 import logic、refresh_symbol。
- 许多 Allegro 操作是通过批处理操作完成的，例如文件导入/导出、artwork、`axlRunBatchDBProgram` 等。这些操作看不到此调用或 Allegro set 命令更改的变量（如 PSMPATH）。

**Original**: Sets the Allegro PCB Editor environment variable with name given by the string t_variable to the value g_value. The g_value can be a string, int, t, or nil. Returns the string assigned to the variable or nil if the variable cannot be set in Allegro PCB Editor. 511 is the maximum list long (lt_variable). Notes: Variable names and values can change from release to release. Variable settings only apply to current session. They are not saved to local env file for the user. Variable changes do not effect programs launched from Allegro PCB Editor. Many Allegro operations are done via batch operations such as items in File Import/Export, artwork, axlRunBatchDBProgram, and so on. These operations do NOT see variables changed by this call or by the Allegro set command.

**语法**：
```skill
axlSetVariable(t_variable g_value)
```

**参数**：
- `t_variable` — 给出 Allegro PCB Editor 环境变量名称的字符串。
- `g_value` — 环境变量要设置的值。可以是字符串、整数、`t` 或 `nil`。

**返回值**：
- `t` — 如果成功。
- `nil` — 如果数据类型无效或变量被标记为只读。

**另请参阅**：`axlGetVariable`, `axlReadOnlyVariable`, `axlSetVariableFile`, `axlUnsetVariable`, `axlUnsetVariableFile`

**示例**：
```skill
(axlSetVariable "libpath" "/mytools/library")
=> t
libraryPath = axlGetVariable("libpath")
=> "/mytools/library"
```

使用列表模式：
```skill
axlSetVariable("psmpath" '("." "symbols"))
==> t
axlGetVariableList("psmpath")
==> ("." "symbols")
```

---

### axlSetVariableFile

**说明**：设置并保存 Allegro 环境变量到文件。这与 `axlSetVariable` 操作相同，但它还将设置保存到用户的本地环境文件中。

变量在 env 文件的 preference 部分添加。在 Windows 上，如果在磁盘上频繁更新环境文件，可能会导致性能问题。

**Original**: Sets and saves to file Allegro environment variable. This operates the same as axlSetVariable except it also saves the setting to the user's local environment file. Variable is added in the preference section of the env file. On Windows, updating the environment file on disk can cause performance issues if this interface is used heavily.

**语法**：
```skill
axlSetVariableFile(t_variable g_value)
```

**参数**：
- `t_variable` — Allegro 环境变量的名称。
- `g_value` — 环境变量要设置的值。可以是字符串、整数、`t` 或 `nil`。

**返回值**：
- `t`/`nil` — 如果成功返回 `t`。如果数据类型无效或变量被标记为只读则返回 `nil`。

**另请参阅**：`axlSetVariable`, `axlUnsetVariableFile`

---

### axlShell

**说明**：向连接的编辑器发出 Allegro PCB Editor 命令字符串 `t_commands`。您可以链式调用命令。此调用是同步的。此函数可能无法跨 Allegro PCB Editor 版本移植。

**Original**: Issues the Allegro PCB Editor command string t_commands to the connected editor. You can chain commands. This call is synchronous. This function might not be portable across Allegro PCB Editor releases.

**语法**：
```skill
axlShell(t_command)
```

**参数**：
- `t_command` — Allegro PCB Editor shell 命令或命令。

**返回值**：
- `t` — 始终返回 `t`。

**另请参阅**：`axlShellPost`

**示例 1**：
```skill
(axlShell "status")
=> t
```
从 AXL-SKILL 显示 Allegro PCB Editor 状态表单。

**示例 2**：
```skill
axlShell("zoom points; pick 0 0; pick 100 100")
```
链式命令示例。

---

### axlShellPost

**说明**：与 `axlShell` 类似，但它首先要求从 SKILL 解释器返回，然后再执行命令。只有在您想在 SKILL 中执行一些处理、执行 Allegro PCB Editor 交互式命令并让用户继续使用该命令的特殊情况下才使用。如果在 post 命令中嵌入了多个命令，则后续命令应以 underscore 为前缀以抑制脚本。例如：

```skill
axlShellPost("zoom points; _pick 10 20")
```

不要尝试使用此方法用 SKILL 代码覆盖现有的 Allegro PCB Editor 命令然后调用原始命令。这将导致无限循环。此函数可能无法跨 Allegro PCB Editor 版本移植。

**Original**: This works similar to axlShell except it first requires a return from the SKILL interpreter before executing the command(s). It should only be used in the special circumstance where you want to do some processing in SKILL, execute an Allegro PCB Editor interactive command and have that command be left active for the user. If more the one command is embedded in post command then subsequent commands should be prefixed with an underscore to inhibit scripting. Do not attempt to use this as a method to override an existing Allegro PCB Editor command with SKILL code and then call the original command. An infinite loop will result. This function may not be portable across Allegro PCB Editor releases.

**语法**：
```skill
axlShellPost(t_command)
```

**参数**：
- `t_command` — Allegro PCB Editor shell 命令或命令。

**返回值**：
- `t` — 始终返回 `t`。

**另请参阅**：`axlShell`

**示例**：
```skill
axlCmdRegister("mymove" 'testSkill ?cmdType "interactive")
procedure(testSkill()
  printf("Hello mymove\n")
  axlShellPost("echo hello from post; _move")
  printf("Hello after-mymove\n")
)
```

输出 — 显示延迟执行：
```
Hello mymove
Hello aftermove
hello from post
Select element(s) to move.
```

---

### axlUnsetVariable

**说明**：取消设置由字符串 `t_variable` 命名的 Allegro PCB Editor 环境变量。命名变量的值变为 `nil`。

变量名和值可能会随版本变化。

**Original**: Unsets the Allegro PCB Editor environment variable with the name given by the string t_variable. The value of the named variable becomes nil. Variable names and values can change from release to release.

**语法**：
```skill
axlUnsetVariable(t_variable)
```

**参数**：
- `t_variable` — 给出 Allegro PCB Editor 环境变量名称的字符串。

**返回值**：
- `t` — 始终返回 `t`。

**另请参阅**：`axlSetVariable`

**示例**：
```skill
(axlUnsetVariable "libpath")
=> "/mytools/library"
libraryPath = (axlGetVariable "libpath")
=> nil
```
当其当前值为 `/mytools/library` 时清除库路径 `libpath`。

---

### axlUnsetVariableFile

**说明**：取消设置指定 Allegro 环境变量的值。与 `axlUnsetVariable` 功能相同，同时还会用更改更新用户的本地环境文件。

在 Windows 上，如果在磁盘上频繁更新环境文件，可能会导致性能问题。

**Original**: Unsets the value of specified Allegro environment variable. Works the same as axlUnsetVariable plus it also updates the local environment file of the user with the change. On Windows, updating the environment file on disk can cause performance issues if this interface is used heavily.

**语法**：
```skill
axlUnsetVariableFile(t_variable)
```

**参数**：
- `t_variable` — 给出 Allegro 环境变量名称的字符串。

**返回值**：
- `t` — 始终返回 `t`。

**另请参阅**：`axlSetVariableFile`, `axlSetVariable`

---

*返回顶部 (Return to top)*
