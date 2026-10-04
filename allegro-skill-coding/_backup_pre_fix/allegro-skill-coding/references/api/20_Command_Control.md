# 第 20 章 命令控制 (Command Control)

## 命令控制函数 (Command Control Functions)

**产品文档**: Allegro SKILL Reference  
**产品版本**: 17.4-2019, October 2019

---

## AXL-SKILL 命令控制函数 (AXL-SKILL Command Control Functions)

**说明**：本章描述在 Allegro PCB Editor 中注册和注销 AXL-SKILL 函数，并在用户界面中设置各种模式的 AXL-SKILL 函数。

**Original**: The chapter describes the AXL-SKILL functions that register and unregister AXL-SKILL functions with Allegro PCB Editor and set various modes in the user interface.

---

### axlCmdGetAppMode

**说明**：检索当前应用程序模式的名称。

**Original**: Retrieves name of the current application mode.

**语法**：
```skill
axlCmdGetAppMode()
```

**参数**：无

**返回值**：
- `nil` — 如果没有当前应用程序模式（选择了 "none"）。
- `t_appMode` — 如果已设置，返回应用程序模式名称。

**示例**：
```skill
axlCmdGetAppMode() ==> "generaledit"
```

---

### axlCmdIsRegistered

**说明**：检查命令名称是否已在运行中的应用程序中注册。命令可以是系统命令或用户定义的 SKILL 命令。如果命令已注册，并且您尝试使用相同的名称通过 `axlCmdRegister` 注册它，您的命令将替换原始命令。原始命令在您的命令通过 `axlCmdUnregister` 注销之前将不再在系统中可访问。

**Original**: Checks whether a command name is registered in the running application. Commands may be system commands or user-defined SKILL commands. If a command is already registered and you try to register it with axlCmdRegister using the same name, your command will replace the original. The original command will no longer be accessible in the system until your command has been unregistered again with axlCmdUnregister.

**语法**：
```skill
axlCmdIsRegistered(t_allegroCmd)
```

**参数**：
- `t_allegroCmd` — 要查询的命令名称。

**返回值**：
- `'user` — 命令注册为用户定义的 SKILL 命令。
- `'system` — 命令注册为标准 Allegro 产品命令。
- `nil` — 命令未注册。

**示例**：
```skill
(axlCmdIsRegistered "move")
```

**另请参阅**：`axlCmdRegister`, `axlCmdUnregister`

---

### axlCmdRegister

**说明**：将名为 `t_allegroCmd` 的命令注册到 Allegro PCB Editor shell 系统。如果命令已存在，因为它是一个基本的 Allegro PCB Editor 命令或因为之前通过此函数注册过，它将被隐藏。Allegro 命令行上的附加参数将未经解析传递给 AXL 程序。

您可以随时调用 `axlCmdRegister()` 函数。一旦命令被注册，您可以在 Allegro PCB Editor 命令行键入它，也可以将其纳入菜单和弹出菜单中。

- **Interactive mode**（交互模式）：如果您正在更改数据库，应该使用此模式。它会在启动您的命令之前 "done" 一个活动的交互命令。
- **General mode**（通用模式）：用于查看数据库或提供某些非数据库功能。它允许与其他通用和交互命令共存。如果仅使用表单命令更改数据库（例如，不从画布请求用户选择），则您应该提供一个虚拟事件处理程序以防止您的 SKILL 代码返回到 Allegro。

请参阅 `<cdsroot>/share/pcb/examples/skill/cns-design.il` 中的 `_AcDesignEvent()` 函数示例。

您可以从 Allegro 命令行将参数传递给您注册的 SKILL 函数。请参阅 `<cdsroot>/share/pcb/examples/skill/examples/axlcore/arg.il`。

支持撤销或重做的命令必须遵循编程概念。编程清单包括：
- 在数据库更改周围使用 `axlDBTransaction` API
- 不要保存或打开数据库
- 不要调用带有重新加载数据库选项的 `axlRunBatchDBProgram`
- 不要使用 `axlShell`
- 如果您的程序通常执行大量数据库更改，不要将其注册为可撤销，因为内存消耗要求

以下项目不遵循撤销或重做：
- 保存在磁盘上或更新的文件
- 数据库附件更改（请参阅 `axlCreateAttachment`）
- 与外部程序或用户界面的通信
- 某些设计状态更改，例如活动层
- 如果您的程序在调用之间保持状态，则重做可能无法正常工作

交互命令可以使用两种模型更新或编写以支持撤销（请参阅 `cline2shape.il`）：
- 撤销命令从开始到完成所做的所有 Allegro 数据库更改。如果您在现有 SKILL 命令中使用数据库事务，则只需向 `axlCmdRegister` 添加撤销选项即可转换为支持撤销。
- 要使其像 place manual 一样工作，其中每个单独的放置操作都是一个撤销，则您需要修改代码的事务模型。您需要在每个用户更改设计周围启动和提交数据库事务。`cline2shape.il` 展示了两种模式之间事务处理略有不同的代码。

避免使用 undoMark 符号启动事务并在未执行数据库操作的情况下提交。如果操作不正确，工具栏的撤销图标上会列出额外的撤销项目。代码仍然可以正常工作，但某些撤销操作不会执行任何操作。

如果您将 SKILL 代码注册为交互式，则无法使用 `axlShell` 访问交互式 Allegro PCB Editor 命令，因为不支持交互式命令的嵌套。这包括使用 `axlShell` 生成包含交互式命令的 Allegro PCB Editor 脚本，这些命令显示在 Allegro PCB Editor 窗口的左下角（`Idle` 字符串出现的位置）。对于交互式命令，状态区域显示命令名称。如果失败，如果您在调用 `axlShell` 时注意到异常行为，请尝试将命令类型更改为 General。如上所述，在通用命令类型中不应调用 `axlEnter` 或 `axlSelect` 族中的任何 API。

**Original**: Registers a command named t_allegroCmd with the Allegro PCB Editor shell system. If the command already exists, either because it is a base Allegro PCB Editor command or because it has been registered by this function at an earlier time, it will be hidden. Additional arguments on the Allegro command line are passed unparsed to the AXL program. You can call the axlCmdRegister() function at any time. Once a command is registered, you can type it at the Allegro PCB Editor command line and also incorporate it into menus and pop-ups. Interactive mode should be used if you are changing the database. It will "done" an active interactive command before starting your command. General mode should be used to view the database or to provide some non-database capabilities. It is allowed to co-exist with other general and interactive commands. If changing the database using a form only command, for example, not requesting user picks from the canvas, then you should provide a dummy event handler to prevent your SKILL code from returning to Allegro. See example in <cdsroot>/share/pcb/examples/skill/cns-design.il function _AcDesignEvent(). You can pass arguments from the Allegro command line to your registered SKILL function. See <cdsroot>/share/pcb/examples/skill/examples/axlcore/arg.il. Commands that support undo or redo must follow the programming concepts.

**语法**：
```skill
axlCmdRegister(t_allegroCmd ts_callback ?cmdType t_cmdType ?doneCmd ts_doneCmd ?cancelCmd ts_cancelCmd ?undo t)
```

**参数**：
- `t_allegroCmd` — 要注册的命令名称。
- `ts_callback` — 从 Allegro PCB Editor 窗口激活命令时调用的 SKILL 回调例程名称。
- `t_cmdType` — 表示此命令类型的字符串：
  - `"interactive"` — 在这种情况下，所有自动交互规则都适用于此命令。这是默认值。
  - `"general"` — 立即命令，即使正在执行另一个命令，一旦调用也会立即执行。用于显示刷新命令等。
  - `"sub_cmd"` — 必须在交互命令内部调用。将此类型用于弹出命令。
- `ts_doneCmd` — 当用户键入 `done` 或从弹出菜单选择 `Done` 时 Allegro PCB Editor 调用的完成回调函数。可以是符号或字符串。如果为 `nil`，Allegro PCB Editor 默认调用 `axlFinishEnterFun`。`Done` 回调函数仅针对 `"interactive"` 命令类型注册。这些参数对于任何其他命令类型将被忽略。
- `ts_cancelCmd` — 当用户键入 `cancel` 或从弹出菜单选择 `Cancel` 时 Allegro PCB Editor 调用的取消回调函数。此参数可以是符号或字符串。如果为 `nil`，Allegro PCB Editor 默认调用 `axlCancelEnterFun`。`Cancel` 回调函数仅针对 `"interactive"` 命令类型注册。这些参数对于任何其他命令类型将被忽略。
- `undo` — 如果为 `t`，命令可以撤销。仅适用于 `t_cmdType` 为 `"interactive"`。有关撤销命令的编程要求，请参阅提示部分。

**返回值**：
- `t` — 命令注册成功。
- `nil` — 命令未注册。

**另请参阅**：`axlCmdUnregister`, `axlCmdList`, `axlUIWHelpRegister`, `axlDBTransactionStart`, `axlCmdIsRegistered`

**示例**：
```skill
axlCmdRegister("interboxcmd" 'axlEnterBox "interactive"
  ?doneCmd 'axlBoxDone ?cancelCmd 'axlBoxCancel)

axlCmdRegister("my swap gates" 'axlMySwapGates
  ?cmdType "interactive" ?doneCmd 'axlMySwapDone
  ?cancelCmd 'axlMySwapCancel)
```

对于接受字符串作为参数的 `s_allegroCmd` 值，SKILL 函数将参数转换为符号。以下是接受参数的注册函数的示例：

```skill
axlCmdRegister("do it" 'do_print)
do it myFile Text AshFindAllText
```

```skill
(defun do_print(arg1 description find_func)
  myport = evalstring(arg1)
  do_print2(myport description find_func)
)

(defun do_print2(p description find_func)
  (let(list)
    (fprintf p "Properties on %s:\n" description)
    (setq list (apply find_func nil))
    (print_list_props list p)
    (fprintf p "\n\n")
  )
)
```

请参阅 `<cdsroot>/share/pcb/examples/skill/examples/axlcore/cline2shape.il` 了解撤销示例。

---

### axlCmdUnregister

**说明**：从 Allegro PCB Editor shell 系统中注销先前注册的名为 `t_allegroCmd` 的命令。如果命令已存在，因为它是基本的 Allegro PCB Editor 命令，则原始命令再次可用。如果现有命令是使用 `axlCmdRegister` 注册的，则它将丢失。

**Original**: Unregisters from the Allegro PCB Editor shell system, a previously registered command named t_allegroCmd. If the command already exists because it is a base Allegro PCB Editor command, the original command is available again. If the existing command was registered using axlCmdRegister, it will be lost.

**语法**：
```skill
axlCmdUnregister(t_allegroCmd)
```

**参数**：
- `t_allegroCmd` — 要注销的命令名称。

**返回值**：
- `t` — 命令注销成功。
- `nil` — 无法注销指定命令。

**示例**：
```skill
axlCmdUnregister("interboxcmd")
```

**另请参阅**：`axlCmdRegister`, `axlCmdIsRegistered`

---

### axlEndSkillMode

**说明**：从 SKILL 命令模式返回到程序的命令行。SKILL `exit` 函数映射到此函数。在 SKILL 程序中，此命令无效。

**Original**: Returns from the SKILL command mode to the program's command line. The SKILL exit function is mapped to this function. In a SKILL program this command has no effect.

**语法**：
```skill
axlEndSkillMode()
```

**参数**：无

**返回值**：
- `t` — 始终返回 `t`。

**示例**：
```skill
axlEndSkillMode()
=> t
```
退出 AXL-SKILL。

---

### axlFlushDisplay

**说明**：将所有数据从显示缓冲区刷新到显示屏幕本身。显示本应显示但尚未显示的项目，因为没有事件触发显示缓冲区的刷新。

您可以显示以下项目：
- 添加到数据库的可见对象
- 消息
- 所选对象的高亮和取消高亮
- 待处理的显示修复

通常，AXL 会延迟屏幕更新，直到提示用户输入或 AXL 程序完成，例如 `axlEnterPoint`。某些程序，例如在屏幕更新之间花费很长时间进行计算的程序，可能希望在每批屏幕更新后调用 `axlFlushDisplay` 以指示命令的进度。过度使用此调用可能会影响性能。

**Original**: Flushes all data from the display buffer to the display screen itself. Displays items intended to be displayed, but not yet displayed because no event has triggered a flush of the display buffer. You can display the following Items: Visible objects added to the database, Messages, Highlighting and dehighlighting of selected objects, Pending display repairs. Generally, AXL delays screen updates until a prompt for user input occurs or an AXL program completes, such as axlEnterPoint. Certain programs, such as those that spend long times doing calculations between screen updates, might want to call axlFlushDisplay after each batch of screen updates to indicate the progress of the command. Overuse of this call may hurt performance.

**语法**：
```skill
axlFlushDisplay()
```

**参数**：无

**返回值**：
- `t` — 始终返回 `t`。

**示例**：
```skill
mypath = axlPathStart(list(8900:4400))
axlPathArcRadius(mypath, 12., 8700:5300, nil, nil, 500)
myline = axlDBCreatePath(mypath, "etch/top" nil)
; Arc is not yet visible
axlFlushDisplay()
; Now arc is visible
```
创建路径并立即显示它，无论用户是否导致显示事件，例如将光标移入 Allegro PCB Editor 窗口。

---

### axlOKToProceed

**说明**：检查 Allegro PCB Editor 是否正在处理另一个交互命令或参与可能干扰 SKILL 命令的某些进程。在启动 `dbcreate`、用户交互和选择集操作等函数之前使用此检查。如果 Allegro PCB Editor 准备好正确执行 SKILL 命令，则返回 `t`，如果不是则返回 `nil`。

**Original**: Checks whether Allegro PCB Editor is processing another interactive command or engaged in some process that might interfere with a SKILL command. Use this to check before starting functions such as dbcreate, user interactions, and select set operations. Returns t if Allegro PCB Editor is ready to properly execute a SKILL command, and returns nil if it is not.

**语法**：
```skill
axlOKToProceed()
```

**参数**：
- `t` — 抑制在不适合继续时产生的错误消息。

**返回值**：
- `t` — Allegro PCB Editor 可以允许 AXL-SKILL 数据库、选择和交互函数执行。
- `nil` — Allegro PCB Editor 无法允许 AXL-SKILL 数据库、选择和交互函数执行。

**示例**：
```skill
(when axlOKToProceed
  ;; do AXL interactive command
)
```

---

### axlSetLineLock

**说明**：设置一个或多个线锁定（line lock）参数。这些参数与 Allegro PCB Editor Status 表单中的 Line Lock 部分可访问的参数相同。

在调用 `axlSetLineLock` 中未明确设置的所有参数保持其当前设置。

**Original**: Sets one or more of the line lock parameters. The parameters are the same as those accessible in the Line Lock section of the Allegro PCB Editor Status form. All parameters not explicitly set in a call to axlSetLineLock keep their current settings.

**语法**：
```skill
axlSetLineLock(?arcEnable g_arcEnable ?lockAngle f_lockAngle ?minRadius f_minRadius ?length45 f_length45 ?fixed45 g_fixed45 ?lengthRadius f_lengthRadius ?fixedRadius g_fixedRadius ?lockTangent g_lockTangent)
```

**参数**：
- `g_arcEnable` — 如果为 `t`，将锁定模式设置为 `Arc`。否则锁定模式为 `Line`。默认值为 `Line`。
- `f_lockAngle` — 设置锁定方向。允许值为：45（度）、90（度）或 0（关闭，或无锁定）。
- `f_minRadius` — 设置最小半径，以用户单位表示。
- `f_length45` — 以用户单位设置固定 45 长度值。
- `g_fixed45` — 如果为 `t`，设置固定 45 长度模式。除非 `f_lockAngle` 为 45 且 `g_arcEnable` 为 `nil`，否则不能设置此参数。
- `f_lengthRadius` — 以用户单位设置固定半径值。
- `g_fixedRadius` — 如果为 `t`，设置固定半径模式。除非 `f_lockAngle` 为 45 或 90 且 `g_arcEnable` 为 `t`，否则不能设置此参数。
- `g_lockTangent` — 如果为 `t`，将切线模式设置为 `on`。

**返回值**：
- `t` — 成功设置给定的线锁定参数。
- `nil` — 无法设置给定的线锁定参数。

**示例**：
```skill
axlSetLineLock(?arcEnable t ?lockAngle 90 ?fixedRadius t ?lengthRadius 50)
```
设置线锁定参数为锁定方向：90，锁定模式：Arc，固定半径：on，在 30 mils 处。

---

### axlSetRotateIncrement

**说明**：以度（`f_angular`）或弧度（`f_radial`）设置动态旋转角度增量。设置动态缓冲区中对象旋转的旋转增量。

**Original**: Sets the dynamic rotate angle increment in degrees (f_angular) or radians (f_radial). Sets the rotate increment for rotation of objects in the dynamic buffer.

**语法**：
```skill
axlSetRotateIncrement(?angular f_angular ?radial f_radial)
```

**参数**：
- `f_angular` — 以度设置角度锁定增量。
- `f_radial` — 以弧度设置径向锁定增量。

**返回值**：
- `t` — 成功设置给定的旋转增量参数。

**示例**：
```skill
(axlSetRotateIncrement ?angular 15)
=> t
```
将动态旋转角度设置为 15 度。

---

### axlUIGetUserData

**说明**：从 Allegro PCB Editor 获取当前用户数据结构。用户数据结构存储有关用户界面状态的基本信息。默认情况下，它包含以下属性：

- `doneState` — 用户如何将控制权返回给应用程序。可能的值为：`done` 或 `cancel`。
- `popupId` — 当前弹出菜单值的列表。字符串对列表，如下所示：
  ```skill
  (("Done" "axlFinishEnterFun") ("Cancel" "axlCancelEnterFun"))
  ```
- `ministatForm` — 始终为 `nil`。（为将来的版本保留。）

您可以在用户数据结构中设置自己的属性以与回调通信，如示例所示。您不能覆盖三个基本属性：`doneState`、`popupId` 或 `ministatForm`。

**Original**: Gets the current user data structure from Allegro PCB Editor. The user data structure stores basic information about the state of the user interface. By default it contains the properties: doneState, popupId, ministatForm. You can set your own attributes in the user data structure to communicate with callbacks, as shown in the example. You cannot overwrite the three basic attributes: doneState, popupId, or ministatForm.

**语法**：
```skill
axlUIGetUserData()
```

**参数**：无

**返回值**：
- `r_userData` — Allegro PCB Editor 的用户数据结构。
- `nil` — 无法从 Allegro PCB Editor 获取用户数据结构。

**示例**：
```skill
userdata = axlUIGetUserData()
userdata->??
=> (doneState cancel
    popupId (("Cancel" "axlCancelEnterFun"))
    ministatForm nil
   )
```

---

### axlUIPopupDefine

**说明**：从名称值对列表 `ts_pairs` 创建弹出菜单。如果 `r_popup` 已存在，它将名称值对追加到 `r_popup` 中现有对的末尾。使用返回的 `r_popup` id 作为 `axlUIPopupSet` 的参数，使其成为活动弹出菜单。

**Original**: Creates a pop-up from the name value pair list ts_pairs. If r_popup already exists, it appends the name value pairs at the end of the existing pairs in r_popup. Use the returned r_popup id as the argument to axlUIPopupSet to make it the active pop-up.

**语法**：
```skill
axlUIPopupDefine(r_popup ts_pairs)
```

**参数**：
- `r_popup` — 要追加新条目的预定义弹出菜单句柄。可以为 `nil` 以创建新的弹出菜单。
- `ts_pairs` — 包含对（`(t_display t_callback)`）的列表，定义每个弹出菜单条目的显示名称及其 AXL 函数回调。

**返回值**：
- `r_popup` — 创建或更新的弹出菜单 ID。
- `nil` — 未创建或更新弹出菜单。

**示例**：
```skill
popid = axlUIPopupDefine(nil
  (list (list "Complete" 'axlMyComplete)
        (list "Rotate" 'axlMyRotate)
        (list "Something" 'axlMySomething)
        (list "Cancel" 'axlCancelEnterFun)))
=> (("Complete" 'axlMyComplete)
    ("Rotate" 'axlMyRotate)
    ("Something" 'axlMySomething)
    ("Cancel" 'axlCancelEnterFun))
```
创建具有以下选项的弹出菜单：
- `Complete` — 与您的函数 `axlMyComplete` 关联
- `Rotate` — 与 `axlMyRotate` 关联
- `Something` — 与 `axlMySomething` 关联
- `Cancel` — 与 `axlCancelEnterFun` 关联

---

### axlUIPopupSet

**说明**：在 Allegro PCB Editor 中设置活动弹出菜单。如果 `r_popup` 为 `nil`，则取消设置当前活动的弹出菜单。

如果此调用之前有对 `axlUICmdPopupSet` 的调用且 `r_popup` 非 nil，则此弹出菜单的内容用于控制 `axlUICmdPopupSet` 调用中定义的弹出菜单项的灰显。否则，`r_popup` 用于替换弹出菜单条目。在这两种情况下，弹出菜单回调都会被替换。

通过按下鼠标弹出按钮（通常是右键）来调用弹出菜单。

您可以通过在表单回调外部调用以下命令来清除活动弹出菜单：
```skill
axlUIPopup(nil)
```

**Original**: Sets the active pop-up in Allegro PCB Editor. If r_popup is nil, unsets the currently active pop-up. If this call is preceded by a call to axlUICmdPopupSet with a non-nil r_popup, the contents of this popup are used to control graying of the popup items defined in the call to axlUICmdPopupSet. Otherwise r_popup is used to replace the popup entries. In both cases, the popup callbacks will be replaced. The popup is invoked by pressing mouse popup button, this is normally the right mouse button. You can clear the active pop-up by calling outside of the form callback, as follows: axlUIPopup(nil)

**语法**：
```skill
axlUIPopupSet(r_popup)
```

**参数**：
- `r_popup` — 由 `axlUIPopupDefine` 创建的预定义弹出菜单句柄。

**返回值**：
- `t` — 将 `r_popup` 设置为活动弹出菜单。
- `nil` — 无法将 `r_popup` 设置为活动弹出菜单。

**示例**：
```skill
popid = axlUIPopupDefine(nil
  (list (list "Complete" 'axlMyComplete)
        (list "Rotate" 'axlMyRotate)
        (list "Something" 'axlMySomething)
        (list "Cancel" 'axlCancelEnterFun)))
axlUIPopupSet(popid)
=> t
```
设置弹出菜单。

---

### axlBuildClassPopup

**说明**：支持构建包含类列表的表单弹出菜单。

**Original**: Supports building a form pop-up with a list of classes.

**语法**：
```skill
axlBuildClassPopup(r_form t_field)
```

**参数**：
- `r_form` — 表单句柄。
- `t_field` — 表单或弹出菜单中的字段名称。

**返回值**：
- `t` — 弹出菜单已构建。
- `nil` — 由于参数不正确，无法构建弹出菜单。

**示例**：
```skill
axlBuildClassPopup(fw, "CLASS")
axlFormSetField(fw, "CLASS" axlMapClassName("ETCH"))
```

---

### axlBuildSubclassPopup

**说明**：支持从指定类构建包含子类列表的表单弹出菜单。

**Original**: Supports building a form pop-up with a list of subclasses from the indicated class.

**语法**：
```skill
axlBuildSubclassPopup(r_form t_field t_class)
```

**参数**：
- `r_form` — 表单句柄。
- `t_field` — 字段名称。
- `t_class` — 类名称。

**返回值**：
- `t` — 构建表单子类弹出菜单。
- `nil` — 由于参数不正确，无法构建表单子类弹出菜单。

**示例**：
```skill
# place holder since popup will be overridden by the code
POPUP <subclass>"subclass" "subclass".
...
# field name should match t_field
FIELD subclass
FLOC 9 3
ENUMSET 19
OPTIONS prettyprint ownerdrawn
POP "subclass"
ENDFIELD

axlBuildSubclassPopup(fw, "subclass" axlMapClassName("ETCH"))
axlFormSetField(fw, "subclass" "GND")
```
表单文件条目提供支持颜色样本的子类弹出菜单。`axlMapClassName` 支持 Allegro Package Designer L 和 Allegro Package SI XL，它们重命名某些类。

---

### axlSubclassFormPopup

**说明**：使用 `axlSubclassFormPopup` 函数为 `r_form` 的给定字段构建给定 Allegro PCB Editor 类的表单弹出菜单。此函数是 `axlGetParam` 和 `axlFormBuildPopup` 与颜色样本的组合。

如果第四个参数为 `nil`，弹出菜单基于给定类的所有子类。您可以轻松构建包含当前颜色作为样本的子类弹出菜单。为此，在表单文件中为该字段添加以下内容：`OPTIONS ownerdrawn`。以这种方式构建的弹出菜单将作为字符串分发回应用程序。

如果传入子类列表，非法的子类名称将被静默忽略。

要利用子类下拉菜单（ENUMSET）中的颜色样本，请使用此接口和表单文件中的 owner drawn 选项。表单文件中您的控件条目应如下所示：

```skill
FIELD <field name>
FLOC <x y location>
ENUMSET <width of field>
OPTIONS prettyprint ownerdrawn
POP <popup name>
ENDFIELD
```

`prettyprint` 选项将用户看到的弹出菜单名称大写/小写。

**Original**: Builds a form pop-up for a given Allegro PCB Editor class for a given field of r_form using the axlSubclassFormPopup function. This function is a combination of axlGetParam and axlFormBuildPopup with color swatching. If the fourth argument is nil, the pop-up is based on all subclasses of the given class. You can easily build a subclass pop-up containing current colors as swatches. To do this, add the following in the form file for that field: OPTIONS ownerdrawn. Pop-ups built this way are dispatched back to the application as strings. if list of subclasses are passed, illegal subclass names are silently ignored. To take advantage of color swatches in your subclass pulldown (ENUMSET) use this interface and the owner drawn option in the form file.

**语法**：
```skill
axlSubclassFormPopup(r_form t_field t_class nil/lt_subclass)
```

**参数**：
- `r_form` — 标准表单句柄（请参阅 `axlFormCreate`）。
- `t_field` — 表单或弹出菜单中的字段名称。
- `t_class` — 类名称。
- `nil` / `lt_subclass` — 使用 `nil` 表示类的所有成员，否则指定列表。

**返回值**：
- `t` — 表单弹出菜单已构建。
- `nil` — 无法构建表单弹出菜单。

**示例**：
```skill
axlSubclassFormPopup(form "subclass_name" "ETCH" nil)
```

---

### axlVisibleUpdate

**说明**：`axlVisible` 族及其基本构建块允许更改层颜色和可见性。`axlSetParam("paramLayerGroup:...")` 您还可以将这些函数与查找过滤器交互结合使用，以允许通过更改可见性来按层过滤对象。

当用户更改可见性时，SKILL 应用程序必须通过 `axlVisibleUpdate` 指示显示更新。更新向用户显示颜色或可见性的任何表单。

对于大多数情况，请向此函数传递 `nil`。这将延迟更新主图形画布，直到控制权返回给用户，从而将多个画布更新合并为一次更新。

**Original**: The axlVisible family and its base building block permit changing layer color and visibility. axlSetParam("paramLayerGroup:...")) You can also use these functions in conjunction with Find Filter interaction to permit filtering objects by layer via changing visibility. The SKILL application must indicate display update via axlVisibleUpdate when changing visibility on the user. Updates any forms that display color or visibility to the user. For most situations, pass nil to this function. This defers updating the main graphics canvas until control is returned to the user, allowing a combination of several canvas updates into one update.

**语法**：
```skill
axlVisibleUpdate(t_now)
```

**参数**：
- `t` — 立即更新。
- `nil` — 当控制权返回给用户时更新。

**返回值**：
- `t` — 始终返回 `t`。

**示例 1**：
```skill
;; 当可见性已修改时，您不应与用户交互
;; 获取当前可见性
p = axlVisibleGet()
axlVisibleDesign(nil) ; 关闭所有层
;; ... 更改所选层的可见性 ...
;; ... 无需用户交互选择对象 ...
;; 恢复可见性
axlVisibleSet(p)
```
使用可见性选择项目而不更新显示。

**示例 2**：
```skill
;; 仅保留顶层蚀刻层
axlVisibleLayer("etch" nil)
axlVisibleLayer("etch/top" t)
;; 当控制权返回给用户时更新显示
axlVisibleUpdate(nil)
```
更改可见性后更新显示。

**示例 3**：
```skill
p = axlLayerGet("etch/top")
;; 合法数字为 1 到 24
p->color = 10
axlSetParam(p)
;; 在更改所有颜色和可见性后调用此函数
axlVisibleUpdate(t)
```
更改顶层蚀刻层的颜色。

---

*返回顶部 (Return to top)*
