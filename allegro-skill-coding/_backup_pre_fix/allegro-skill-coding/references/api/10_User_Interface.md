# 10. 用户界面 (User Interface)

**Product Documentation**: Allegro SKILL Reference  
**Product Version**: 17.4-2019, October 2019  

---

## 10.1 用户界面函数概述 (User Interface Functions Overview)

**说明**：本章描述用于确认操作意图、提示文本输入、显示ASCII文本文件以及刷新显示缓冲区中挂起更改的AXL/SKILL函数。

**Original**: This chapter describes the AXL/SKILL functions you use to confirm intent for an action, prompt for text input, display ASCII text files, and flush pending changes in the display buffer.

---

## 10.2 窗口定位 (Window Placement)

**说明**：Allegro PCB Editor鼓励您以抽象方式放置窗口。例如，当您打开一个表单时，不是指定(x,y)坐标，而是给出一组放置选项。然后Allegro PCB Editor计算放置位置。此方法的优势在于所有窗口会自动相对于主Allegro PCB Editor窗口定位。即使违反您的放置参数，窗口也始终完全显示在屏幕上。

**Original**: Allegro PCB Editor encourages you to place windows in an abstract manner. For example, when you open a form, instead of specifying (x,y) coordinates you give a list of placement options. Allegro PCB Editor then calculates the placement location. An advantage of this method is that all windows automatically position themselves relative to the main Allegro PCB Editor window. Windows always position entirely onscreen even in violation of your placement parameters.

可用的表单放置选项（括号内为接受的缩写）：

```
north(n)     northeast(ne)    east(e)    southeast(se)
south(s)     southwest(sw)    west(w)    northwest(nw)
center(c)
```

此外，您还可以使用以下参数修改放置选项：

- **Inner** 或 **Outer**：将放置矩形置于主窗口的内部或外部。默认值为 `inner`。
- **Canvas** 或 **Window**：使用画布（绘图）区域或整个窗口作为放置矩形。默认值为 `Window`。
- **Border** 或 **NoBorder**（默认 `Border`）：在放置窗口周围留一小段边框。如果设置为 `noborder`，窗口将直接紧贴放置矩形。
- **MsgLines**（默认 1）：设置放置窗口底部消息行的数量为0或1。仅 **forms** 支持此参数。语法：`msglines #`

---

## 10.3 使用菜单文件 (Using Menu Files)

**说明**：您可以在Allegro PCB Editor中使用绘图菜单、符号菜单和形状菜单。Allegro工具通常支持三种菜单：绘图、符号和形状。Allegro命令集在这三种设计编辑器之间有很大不同。此外，不同工具（如APD+和SI（信号完整性）产品）也存在菜单集。

**Original**: You can use drawing menus, symbol menus, and shape menus in Allegro PCB Editor. Allegro tools typically support three menus; drawing, symbol and shape. The Allegro command set is very different between these three design editors. Also menu sets exist for different tools such as APD+ and the SI (Signal Integrity) products.

所有分层（产品级别）通过单个菜单文件中的`#ifdef`语句进行管理。通常，控制分层的环境变量设置记录在文件顶部。

**Original**: All of the tiering (product levels) within a product are managed via the "#ifdef" statements within a single menu file. Typically, the settings of environment variables controlling the tiering are documented at the top of file.

您不能剥离`#ifdef`语句以获取缺失的命令。

**Original**: You cannot strip out the #ifdef statements to gain access to the missing commands.

Allegro通过其`MENUPATH`环境变量查找菜单。您可以在以下位置找到默认的Allegro PCB Editor菜单文件：

**Original**: Allegro finds the menus with its MENUPATH environment variable. You can find the default Allegro PCB Editor menu files in:

```
<cdsroot>/share/pcb/text/cuimenus
```

> **注意**：随着新版本产品的添加，可能会添加新的菜单文件。Cadence可能会在任何版本中更改任何菜单文件的名称。此目录中的菜单文件如下（由于您加载的工具和软件版本不同，某些菜单可能不存在于您的安装中）。您不应修改此目录中的任何其他文件类型，因为仅支持菜单文件供用户修改。

### 表 10-1 Allegro PCB Editor 菜单文件 (Allegro PCB Editor Menu Files)

| 文件名 | 说明 |
|--------|------|
| `allegro.men` | Allegro PCB Editor 菜单（用于所有 Allegro PCB Editor `.brd` 设计） |
| `pcb_symbol.men` | PCB 产品的符号菜单 |
| `partition.men` | PCB 产品的分区菜单 |
| `specctraquest.men` | PCB SI 菜单 |
| `apd.men` | APD+ 菜单 |
| `icp_symbol.men` | APD+ 符号编辑器菜单 |
| `apd_partition.men` | APD+ 分区编辑器菜单 |
| `apd_si.men` | APD+ SI 菜单 |
| `padlayout.men` | 板图形编辑器中的焊盘设计器 |
| `padlaystn.men` | 焊盘设计器（独立版） |
| `allegro_free_viewer.men` | Allegro 免费查看器 |
| `viewlayout.men` | Allegro Viewer Plus |

### 菜单术语 (Menu Terms)

- **Menu bar（菜单栏）**：窗口顶部可见的菜单项。
- **Menu item（菜单项）**：一行菜单；可以是命令、分隔符或子菜单。
- **Separator（分隔符）**：用于视觉上分组菜单项的水平线。
- **Submenu（子菜单）**：从菜单栏下拉或从另一个子菜单拉出的菜单。子菜单只能有显示，不支持命令关联。

### 菜单设计考虑 (Menu Design Considerations)

- 某些动态项可能存在。这些当前是MRU（最近使用的文件）和快速报告。不要尝试修改这些项。
- 不要在菜单栏的显示中使用空格。
- 菜单栏上的所有项应该是子菜单。不要在此级别添加命令菜单项。
- 不要在菜单栏上添加过多项。如果菜单栏在典型窗口宽度下显示为两行，则您可能有太多项。
- 保持显示文本相对较短，特别是在菜单栏上。

### 菜单自定义方法 (MENU CUSTOMIZATION METHODS)

1. **通过CDS_SITE提供您自己的自定义菜单**：替换Cadence提供的菜单（.men文件）为您自己的。
   - 优点：相对容易，不需要SKILL编程。
   - 缺点：对于新版本，需要将菜单更改与新的Cadence菜单合并。可能需要修改多个菜单。

2. **通过SKILL `axlUIMenuRegister`将自定义菜单重载到Cadence菜单上**：
   - 优点：相对容易，只需少量SKILL编程。根据您的添加内容，可能对许多Cadence菜单更改免疫。
   - 缺点：无法删除Cadence菜单项或限制更改仅限于一个Cadence菜单。

3. **通过`axlTriggerSet`注册AXL菜单触发通知**：
   - 优点：几乎具有与覆盖默认菜单文件相同的灵活性，包括针对特定菜单。
   - 缺点：需要在新Cadence版本中检查SKILL代码。需要更多的SKILL编程知识。

---

## 10.4 动态加载菜单 (Dynamically Loading Menus)

**说明**：所有工具都支持通过将菜单文件放在默认Cadence菜单文件之前（通过`MENUPATH`）来覆盖其默认菜单。支持AXL-SKILL的程序允许在程序运行时动态更改菜单。您可以使用`axlUIMenuLoad` SKILL函数执行此操作。这不支持在`allegro_pcb`和`allegro_viewer`中使用。

**Original**: All tools support overriding their default menus by putting your menu file before the default Cadence menu file via the MENUPATH. Programs that support AXL-SKILL allow menus to be dynamically changed while the program is running. You do this using the axlUIMenuLoad SKILL function. This is not supported in allegro_pcb and allegro_viewer.

工具支持动态（通过SKILL）修改菜单。有关信息，请参阅 `axlUIMenuFind`。

**Original**: Tools support dynamically (via SKILL) modifying menus. For information, see axlUIMenuFind.

---

## 10.5 理解菜单文件格式 (Understanding the Menu File Format)

**说明**：每个文件只能有一个菜单定义。以下以BNF格式显示菜单语法。缩进的使用反映了.men文件中的层次结构。

**Original**: You can have only one menu definition per file. The following shows the menu syntax in BNF format. The use of indentation reflects hierarchy in the .men file.

菜单文件语法约定：

**Original**: Menu file grammar reflects the following conventions:

| 约定 | 说明 |
|------|------|
| `[ ]` | 可选 |
| `{ }` | 可以重复一次或多次 |
| `< >` | 由用户提供 |
| `\|` | 选择其中一个 |
| `:` | 标记的定义 |
| `CAPS` | 大写项是关键字 |

菜单文件格式定义：

**Original**: The following defines the menu file format:

```
FILE:
  [comment]
  [ifdef]
  <name>MENU DISCARDABLE
  BEGIN
  {popup}
  END

popup:
  POPUP "<display>"
  BEGIN
  {MENUITEM "<display>" "<command>"}
  [{separator}]
  {[popup]}
  END
  {[//]}    - 注释行

separator:
  MENUITEM SEPARATOR
  - 在菜单中此位置插入分隔线。顶级菜单栏不支持此功能。

name:    此文本被忽略。使用不带扩展名的文件名。
comment: 双斜杠(//)可用于开始注释。
display: 显示给用户的文本。
  & - 用于启用对菜单的键盘访问。为此，每个菜单级别必须分配一个唯一键。使用双与号(&&)显示"&"。
  ... - 三个点约定表示此命令显示一个表单。
command: 任何Allegro命令、Allegro命令序列或SKILL语句。Allegro命令解析器作用于此语句，因此它提供了相当大的灵活性。命令应放在一组双引号(")内。此命令字符串中不支持双引号。
ifdef:   使用#ifdef/#endif和#ifndef/#endif使项目根据是否设置了指定的环境变量而有条件地出现在菜单中。
```

`#ifdef` 使菜单项被忽略，除非设置了环境变量。`#ifndef` 使菜单项被忽略，如果环境变量未设置。每个`#ifdef`或`#ifndef`必须有一个`#endif`来结束条件菜单项块。此外，`#ifdef`、`#ifndef`和`#endif`必须在菜单文件中的行首第一列开始。

`#ifndef` 是 `#ifdef` 的否定。

条件语法支持多个变量使用OR '||'或AND '&&'条件。也支持变量的否定字符'!'：

```
#ifdef <env variable name>
[menu items which appear if the env variable is set]
#endif

#ifndef <env variable name>
[menu items which appear if the env variable is not set]
#endif

# 使用否定字符逻辑等价于上述
#ifdef !<env variable name>
[menu items which appear if the env variable is NOT set]
#endif

# 逻辑语句
1) 如果 variable1 和 variable2 都设置，执行包含语句
#ifdef <var1> && <var2>
[menu items which appear if both variables are set]
#endif

2) 如果 variable1 或 variable2 任一设置，执行包含语句
#ifdef <var1> || <var2>
[menu items which appear if either variable is set]
#endif
```

`#if[n]def/#endif` 之间的项可以是一个或多个 `MENUITEMS`，也可以是一个 `POPUP`。

**示例 1**：
```
#ifdef menu_enable_export
POPUP "&Export"
BEGIN
MENUITEM "&Logic...", "feedback"
END
#endif
```
只有当设置了`menu_enable_export`环境变量时，`Export`弹出菜单才会出现在菜单中。

**示例 2**：
```
#ifndef menu_disable_product_notes
MENUITEM "&Product Notes", "help -file algpn"
#endif
```
只有当`menu_disable_product_notes`环境变量**未**设置时，`Product Notes`菜单项才会出现在菜单中。

**示例 3 - 简单菜单示例**：

DISPLAY（缩进反映各种下拉级别）
```
File      Help
  Open      Contents
  Export    Product Notes
  Logic     Known Problems and Solutions
  Exit      ----------------------------
            About Allegro...
```

FILE:
```
simple MENU DISCARDABLE
BEGIN
POPUP "&File"
BEGIN
MENUITEM "&Open", "open"
POPUP "&Export"
BEGIN
MENUITEM "&Logic...", "feedback"
END
MENUITEM "&Exit", "exit"
END
POPUP "&Help"
BEGIN
MENUITEM "&Contents", "help"
MENUITEM "&Product Notes", "help -file algpn"
MENUITEM "&Known Problems and Solutions", "help -file alkpns"
MENUITEM SEPARATOR
MENUITEM "&About Allegro...", "about"
END
END
```

---

## 10.6 AXL-SKILL 用户界面函数 (AXL-SKILL User Interface Functions)

本节列出用户界面函数。

**Original**: This section lists the user interface functions.

---

### axlCancelOff

**说明**：禁用当用户点击"取消"时的检查。请参阅 `axlCancelOn`。

**Original**: Disables checking when a user clicks Cancel. See axlCancelOn.

**语法**：
```skill
axlCancelOff()
```

**返回值**：
- 始终返回 `t`。

**示例**：
```skill
axlCancelOn()
while(count < 50000 && !axlCancelTest()
  ;; 在此处执行工作。如果用户请求取消，我们将跳出循环。
  count++
)
axlCancelOff()
```

---

### axlCancelOn

**说明**：允许SKILL代码检测用户何时点击"取消"。当启动需要长时间的操作时，启用取消允许用户通过点击Allegro信号灯或按`Esc`键来中断操作。当调用`axlCancelTest`函数时执行取消检查，允许SKILL代码确定中止操作的最佳时机。启用取消时，信号灯为黄色。

**Original**: Allows SKILL code to test for when a user clicks Cancel. When an operation is started that takes a long amount of time, enabling cancel allows a user to interrupt the operation by clicking on the Allegro traffic light or pressing the Esc key. The cancel checks are performed when the axlCancelTest function is called, allowing the SKILL code to determine the best time to abort an operation. When cancel is enabled, the traffic light is yellow.

虽然您可以嵌套取消调用，但应该使取消关闭调用的数量与取消开启调用的数量相等。为避免问题，始终将取消开启/关闭调用对放在同一函数中。这些调用在SKILL或Allegro PCB Editor命令行中不起作用，因为Allegro PCB Editor在退出SKILL环境时立即禁用取消，以防止系统挂起。

**注意**：仅在确定没有用户交互时启用取消处理。在用户必须输入信息时启用取消不受支持，会导致系统挂起。调用`axlCancelTest`可能会对程序性能产生不利影响。

**语法**：
```skill
axlCancelOn()
```

**返回值**：
- 始终返回 `t`。

**相关函数**：`axlCancelSetFormClosable`, `axlCancelClearFormClosable`

---

### axlCancelTest

**说明**：请参阅 `axlCancelOn`。

**Original**: See axlCancelOn.

**语法**：
```skill
axlCancelTest()
```

**返回值**：
- `t`：用户点击了取消。
- `nil`：用户未点击取消。

**相关函数**：`axlCancelOn`, `axlCancelOff`

---

### axlCancelClearFormClosable

**说明**：请参阅 `axlCancelSetFormClosable`。

**Original**: See axlCancelSetFormClosable.

**语法**：
```skill
axlCancelClearFormClosable(o_form)
```

**参数**：
- `o_form`：表单 dbid

**返回值**：
- `t`：如果表单在取消操作处理期间不可关闭。
- `nil`：如果不是。

**相关函数**：`axlCancelOn`, `axlCancelOff`, `axlCancelTest`, `axlCancelSetFormClosable`

---

### axlCancelSetFormClosable

**说明**：允许在取消检查期间关闭表单。当通过`axlCancelOn`启用取消处理时，大多数UI事件被忽略。因此，在取消检查期间尝试关闭表单的任何操作也会被忽略。这些函数允许调用者指定在取消处理期间可以关闭给定的表单。在启用取消时关闭表单将被视为用户发起的取消请求。应在关闭表单之前调用`axlCancelClearFormClosable`。

**Original**: Allows a form to be closable during cancel checking. When cancel processing is enabled by axlCancelOn, most UI events are ignored. As a result any attempts to close a form during a cancel check are also ignored. These functions allow the caller to specify that the given form can be closed during cancel processing. Closing the form when cancel is enabled will be treated as a user-initiated cancel request. The axlCancelClearFormClosable call should be made before the form is closed.

**语法**：
```skill
axlCancelSetFormClosable(o_form)
```

**参数**：
- `o_form`：表单 dbid

**返回值**：
- `t`：如果表单在取消操作处理期间可关闭。
- `nil`：如果不是。

**示例**：
```skill
;; 创建表单，将表单设置为在取消期间激活，然后启用取消。
form = axlFormCreate((gensym) "my.form" '("C" "INNER") '_myFormCallback t)
axlCancelSetFormClosable(form)
axlCancelOn()
;; 执行工作，在迭代之间检查取消。
count = 0;
while(count < 50000 && !axlCancelTest()
  ;; 在此处执行操作
  count++
)
;; 取消将表单设置为在取消期间非激活，禁用取消，关闭表单。
axlCancelClearFormClosable(form)
axlCancelOff()
axlFormClose(form)
```

---

### axlClipboardGetText

**说明**：获取系统剪贴板中的当前文本。剪贴板可以包含非ASCII文本的数据，在这种情况下返回`nil`。

**Original**: This gets the current text in the system clipboard. Clipboard can contain data other than ASCII text in which case nil is returned.

**语法**：
```skill
axlClipboardGetText()
```

**返回值**：
- `t_text`：剪贴板中的文本
- `nil`：剪贴板中没有文本

**示例**：
```skill
axlClipboardSetText("hello world")
text = axlClipboardGet()
```

**相关函数**：`axlClipboardSetText`

---

### axlClipboardSetText

**说明**：将指定文本发送到系统剪贴板。仅支持ASCII文本。

**Original**: Sends indicated text to system clipboard. Only ASCII text is supported.

**语法**：
```skill
axlClipboardSetText(t_text/nil)
```

**参数**：
- `t_text`：文本字符串。如果指定`nil`或空字符串，则清空剪贴板。

**返回值**：
- `t`：已更新剪贴板
- `nil`：失败

**相关函数**：`axlClipboardGetText`

---

### axlCursorGet

**说明**：此命令用于获取当前光标位置，可以以像素（屏幕单位）为单位，或转换为当前设计单位。从像素到设计单位的映射考虑了设计的当前窗口视图和缩放因子。在非图形模式下访问此功能的结果未定义。

**Original**: This command is used to obtain the current cursor position either in pixels (screen units) or converted into current design units. The mapping from pixels to design units takes into account the current window view and zoom factor of the design. Accessing this in non-graphic mode is undefined.

**语法**：
```skill
axlCursorGet(g_pixel)
```

**参数**：
- `g_pixel`：如果值设置为`t`，则xy坐标以像素指定。如果值设置为`nil`，则返回当前光标在当前设计中的位置。

**返回值**：
- 光标位置，以像素（整数）或设计单位（浮点数）为单位。

**相关函数**：`axlCursorWarp`, `axlUIControl`

---

### axlCursorWarp

**说明**：使用此命令设置光标位置。可以通过像素或设计单位设置光标。如果通过设计单位设置，新值必须在当前可视窗口内（`axlWindowBoxGet`）。有关像素和设计单位之间讨论，请参阅`axlCursorGet`。

**Original**: Use this command to set the cursor position. May set the cursor either by pixel or design units. If setting by design units the new value must be within the current viewable window (axlWindowBoxGet). See axlCursorGet for a discussion between pixel and design units.

**语法**：
```skill
axlCursorWarp(g_pixel l_xy)
```

**参数**：
- `g_pixel`：如果为`t`则返回xy以像素为单位，否则返回光标在当前设计中的位置。
- `l_xy`：xy值可以以像素（g_pixel=t）或设计单位（g_pixel=nil）指定。

**返回值**：
- `t`：如果移动了光标
- `nil`：如果参数错误或光标移出了主窗口

**相关函数**：`axlCursorGet`, `axlWindowBoxGet`

---

### axlMeterCreate

**说明**：启动带有可选取消功能的进度条。完成后始终调用`axlMeterDestroy`。

**Original**: Starts progress meter with optional cancel feature. Always call axlMeterDestroy when done with meter.

**语法**：
```skill
axlMeterCreate(t_title t_infoString g_enableCancel [t_formname] [t_infoString2] [g_formCallback])
```

**参数**：
- `t_title`：进度条标题栏。
- `t_infoString`：一行28个字符，用于您想要的任何内容（可以在进度条更新时更新）。
- `g_enableCancel`：`t` 在图形UI应用程序上启用"停止"按钮。启用后，当用户选择"停止"按钮时，`axlMeterIsCancelled()`返回true。
- `t_formname`：（可选）可以与此函数一起使用的备用表单名称，该表单具有名为`progressText`的信息字段和名为`bar`的进度字段。
- `t_infoString2`：（可选）默认为空字符串""。
- `g_formCallback`：（可选）您希望为表单上的任何按钮或填充等调用的回调函数名称。其工作方式与`axlFormCreate`中的`g_formAction`相同。

**返回值**：
- `t`：成功；否则 `nil`。

**示例**：
```skill
axlMeterCreate("SigNoise Design Audit", "", t)
total = <total nets>
done = 0
while(<still next net> && (!axlMeterIsCancelled())
  < do work >
  axlMeterUpdate( (100 * ++done)/total
    sprintf(nil "Check %d of %d nets" done total))
)
axlMeterDestroy()
```

**相关函数**：`axlMeterCreate`, `axlMeterIsCancelled`, `axlMeterDestroy`, `axlFormCreate`

---

### axlMeterDestroy

**说明**：关闭进度条表单，如果启用了取消模式，则关闭取消模式。

**Original**: Closes the progress meter form and shuts off Cancel mode if enabled.

**语法**：
```skill
axlMeterDestroy()
```

**参数**：无

**返回值**：
- `t`：如果进度条已销毁；否则 `nil`。

**相关函数**：`axlMeterCreate`

---

### axlMeterIsCancelled

**说明**：如果在创建进度条时启用了取消，则返回取消的状态（如果已取消则返回`t`；否则返回`nil`）。如果命中了名为`Cancel`的字段，则视为已取消。

**Original**: If cancel was enabled at meter creation, the status of cancel is returned (t if cancelled; otherwise nil). If a field named Cancel was hit, it is cancelled.

**语法**：
```skill
axlMeterIsCancelled()
```

**参数**：无

**返回值**：
- `t`：如果进度条已取消；否则 `nil`。

**相关函数**：`axlMeterCreate`

---

### axlMeterUpdate

**说明**：更新进度条和/或信息文本。可以更新完成百分比和/或信息字符串。

**Original**: Updates progress meter bar and/or info text. The percent done and/or the info string may be updated.

**语法**：
```skill
axlMeterUpdate(x_percentDone t_infoString [t_infoStr2])
```

**参数**：
- `x_percentDone`：整数任务完成百分比（0-100）。
- `t_infoString`：更新进度条信息文本行的文本。值为以下之一：
  - `nil`：保持信息文本不变。
  - `""`：清除信息字符串字段。
  - `newText`：用新文本更新字段。
- `t_infoStr2`：（可选）第二行文本。

**返回值**：
- `t`：成功；否则 `nil`。

**相关函数**：`axlMeterCreate`

---

### axlUIAppMode

**说明**：与Allegro的应用程序模式界面交互。操作由第一个参数驱动：
- `'inAppMode`：如果在应用程序模式中返回`t`，在空闲模式中返回`nil`。
- `'mode`：返回应用程序模式字符串，如果在空闲模式中返回`nil`。
- `'commands`：返回当前支持的应用程序模式集。这取决于基础产品，有时还取决于所选的产品选项。
- `'none`：关闭应用程序模式，Allegro进入空闲模式。任何已检出的dbid保持活动状态。始终返回`t`。
- `'set`：将应用程序模式设置为参数1中提供的字符串。任何dbid被回收（例如，dbid:removed）。如果应用程序模式设置成功返回`t`，如果失败返回`nil`。

**Original**: Interacts with Allegro's application mode interface. Operation is driven by the first argument: 'inAppMode returns t if in application mode, nil in Idle mode; 'mode returns application mode as a string, nil if in Idle mode; 'commands returns the set of currently supported application modes; 'none turns off application mode; 'set sets the application mode to string provided.

**语法**：
```skill
axlUIAppMode(S_mode [t_appCommand])
```

**参数**：
- `S_mode`：见上文。
- `t_appCommand`：仅适用于`'set`。

**返回值**：
- `g_return`：取决于`S_mode`，见上文。

**示例**：
```skill
;; 获取应用程序模式命令
cmds = axlUIAppMode('commands)
;; 检查应用程序模式是否处于活动状态
amApp = axlUIAppMode('inAppMode)
;; 将应用程序模式设置为无（例如，空闲）
axlUIAppMode('none)
;; 将应用程序模式设置为常规编辑
axlUIAppMode('set "generaledit")
```

---

### axlUIMenuLoad

**说明**：从文件`t_menuFile`加载主窗口菜单。如果`t_menuFile`没有扩展名，则添加默认菜单文件名扩展名。如果`t_menuFile`不包含从根驱动器的完整路径，则使用`MENUPATH`环境变量来定位文件。此过程的目的是允许加载自定义菜单以用于调试目的。

**Original**: Loads the main window menu from the file t_menuFile. Adds a default menu file name extension if t_menuFile has none. The MENUPATH environment variable is used to locate the file if t_menuFile does not include the entire path from the root drive. The intent of this procedure is to allow a custom menu to be loaded for debugging purposes.

**语法**：
```skill
axlUIMenuLoad(t_menufile)
```

**参数**：
- `t_menuFile`：菜单转储到的文件名。如果`t_menuFile`为`nil`，则文件名基于程序的默认菜单名称，这可能因程序的当前状态而异。

**返回值**：
- `t_previousMenuName`：上一个菜单的名称。
- `nil`：未找到菜单。

**相关函数**：`axlUIMenuFind`

---

### axlUIMenuDump

**说明**：将主窗口的当前菜单转储到`t_menuFile`文件。如果`t_menuFile`没有扩展名，则添加默认菜单文件名扩展名。

**Original**: Dumps the current menu of the main window to the t_menuFile file. Adds default menu file name extension if t_menuFile has none.

> **注意**：覆盖现有文件时没有用户交互。此函数仅适用于基于Windows的GUI。

**语法**：
```skill
axlUIMenuDump(t_MenuFile [g_debug])
```

**参数**：
- `t_menuFile`：菜单转储到的文件名。如果`t_menuFile`为`nil`，则文件名基于程序的默认菜单名称。
- `[g_debug]`：如果为`'print`，则仅转储菜单文件中包含的命令。允许更容易地比较旧和新菜单文件。

**返回值**：
- `t_previousMenuName`：写入的文件的完整名称。
- `nil`：未写入文件。

**相关函数**：`axlUIMenuLoad`

---

### axlUIColorDialog

**说明**：调用标准颜色选择对话框。您必须提供一个父窗口，Allegro PCB Editor默认为应用程序的主窗口。`l_rgb`是红、绿、蓝调色板列表。每个项是0到255之间的整数值。0表示颜色关闭，255表示颜色完全打开。例如，`255 255 255`表示白色。

**Original**: Invokes standard color selection dialog box. You must provide a parent window, Allegro PCB Editor defaults to the main window of the application. The l_rgb is a red, green, or blue palette list. Each item is an integer between the values of 0 and 255. 0 indicates color is off, and a value of 255 indicates color is completely on. For example, 255 255 255 indicates white.

**语法**：
```skill
axlUIColorDialog(r_window/nil l_rgb)
```

**参数**：
- `r_window`：父窗口。如果为`nil`，则使用主程序窗口。`axlFormCreate`返回的句柄为`r_window`类型。
- `l_rgb`：初始化的红、绿或蓝值。

**返回值**：
- `l_rgb`：用户选择的值。
- `nil`：用户取消了对话框。

**示例**：
```skill
;; 获取颜色1并更改它：
rgb = axlColorGet(1)
rgb = axlUIColorDialog(nil rgb)
when(rgb
  axlColorSet(1 rgb)
  axlVisibleUpdate(t))
```

**相关函数**：`axlColorSet`, `axlColorGet`

---

### axlUIConfirm

**说明**：在确认窗口中显示字符串`t_message`。用户必须在进一步与Allegro PCB Editor交互之前做出响应。主要用于在退出程序之前向用户通知严重的致命错误。非常罕见地使用此阻塞函数。
如果设置了环境变量`noconfirm`，则立即返回。

**Original**: Displays the string t_message in a confirmer window. The user must respond before any further interaction with Allegro PCB Editor. Useful mainly for informing the user about a severe fatal error before exiting your program. Use this blocker function very rarely. If environment variable noconfirm is set, we immediately return.

**语法**：
```skill
axlUIConfirm(t_message [s_level])
```

**参数**：
- `t_message`：消息字符串。
- `s_level`：选项级别符号；默认是info级别，其他级别为`warn`和`error`。

**返回值**：
- `t`：始终返回 `t`。

**示例**：
```skill
;; 当进行重大转换时通知用户：
axlUIConfirm( "Returning to Allegro. Please confirm." )
;; 向用户发出错误警报：
axlUIConfirm( "Selected object has FIXED property." 'error )
```

**相关函数**：`axlUIPrompt`, `axlUIYesNo`, `axlUIYesNoCancel`, `axlUIConfirmEx`

---

### axlUIConfirmEx

**说明**：在确认窗口中显示字符串`t_message`，并带有一个可选的复选框，用于不再显示此框。功能与`axlUIConfirm`相同，但允许有一个复选框以不再显示确认框。系统会记住此选择，因此如果用户表示他们不想显示该框，则调用立即返回。需要唯一的`t_key`字符串来记住选择。可选的`s_level`参数更改显示给用户的信息。在程序启动/退出时，会写入一个文件到`<HOME>/pcbenv/remember_<program>.txt`。

**Original**: Displays the string t_message in a confirmer window with an optional check box to never show the box again. Functions same as axlUIConfirm except allows a check box to never show confirmer again. System remembers this selection so if user has indicated they do not want the box the call immediately returns. Requires a unique t_key string which is used to remember the selection. The optional s_level argument changes the info displayed to the user.

**语法**：
```skill
axlUIConfirmEx(t_message t_key/nil [s_level])
```

**参数**：
- `t_message`：消息字符串。
- `t_key`：用于记住用户选择的唯一键。如果此参数值为`nil`，则命令的工作方式类似于`axlUIConfirm`。
- `s_level`：选项级别符号；默认是`info`级别，其他级别为`'warn`和`'error`。

**返回值**：
- `t`：始终返回 `t`。

**示例**：
```skill
axlUIConfirmEx( "Use this command at your own risk." "mynewcommand")
```

**相关函数**：`axlUIConfirm`

---

### axlUIControl

**说明**：查询图形画布。查询和设置图形值。如果设置值，则返回控件的旧值。这些控件的大多数副作用是，如果显示当前设置的表单处于活动状态，则它可能不会更新。各个控件的其他副作用如下所列。项目会随时间添加。当前支持的项：

**Original**: Inquire about graphics canvas. Inquires and sets the value of graphics. If setting a value, the return is the old value of the control. A side effect of most of these controls is if a form is active that is displaying the current setting it may not be updated. Additional side effects of individual controls are listed.

**语法**：
```skill
axlUIControl(s_name [g_value])
```

**当前支持的控件名称**：

| 名称 | 值 | 可设置？ | 说明 | 等效 | 副作用 |
|------|-----|---------|------|------|--------|
| `screen` | `(x_width x_height)` | 否 | 检索屏幕的宽度和高度（像素） | 无 | 无 |
| `vscreen` | `(x_width x_height)` | 否 | 检索屏幕的虚拟宽度和高度（像素）。如果运行Windows XP并启用了监视器跨越选项，则与'screen不同。 | 无 | 在UNIX上始终返回与screen相同的大小。 |
| `vedge` | `(x_x x_y)` | 否 | 检索屏幕的虚拟左上角（像素） | 无 | 在UNIX上始终返回(0 0) |
| `monitors` | `x_number` | 否 | 检索可用监视器的数量。 | 无 | 在UNIX上始终返回1 |
| `pixel2UserUnits` | `f_number` | 否 | 返回每像素用户单位数，考虑当前画布大小和缩放因子。随当前缩放因子变化。 | 无 | 无 |

**参数**：
- `s_name`：控件符号名称。`nil`返回所有可能的名称。
- `g_value`：可选符号值设置。通常是`t`或`nil`。

**返回值**：
- `ls_names`：如果name为`nil`，则返回所有控件的列表。

**示例**：
```skill
;; 获取屏幕大小：
size = axlUIControl('screen)
-> (1280 1024)
;; 获取像素到用户单位：
axlUIControl('pixel2UserUnits)
-> 17.2
```

**相关函数**：`axlOSControl`

---

### axlUIMenuChange

**说明**：更改一个或多个现有菜单项的参数。与其他菜单命令不同，如果菜单命令与您的SKILL代码关联，则此函数可以安全地在菜单触发回调之外执行。允许的更改是一组新值对：

**Original**: This changes one or more parameters of an existing menu item. Unlike other menu commands this function can be safely done outside of the menu trigger callback if the menu command is associated with your SKILL code.

**表 10-2 菜单更改选项**：

| s_option | g_mode | 说明 |
|----------|--------|------|
| `'enable` | `t/nil` | 启用/禁用菜单 |
| `'check` | `t/nil` | 设置/取消复选标记 |
| `'display` | `<new text display>` | 更改显示文本 |
| `'command` | `<new command string>` | 更改命令文本 |

您不应尝试更改任何分隔符菜单项。也不要尝试将命令文本分配给子菜单。

**语法**：
```skill
axlUIMenuChange(x_menuId s_option g_mode ... <pairs of s_option/g_mode>)
```

**参数**：
- `x_menuId`：来自`axlUIMenuFind`的menuId
- `s_option/g_mode`对：见表 10-2

**返回值**：
- `t`：如果菜单项已更改；`nil`：如果命令未能更改菜单项。

**示例**：
```skill
;; 设置菜单为禁用
q = axlUIMenuFind( nil "add rect")
axlUIMenuChange(q 'enable nil)
;; 从前面的示例启用并设置复选标记
axlUIMenuChange(q 'enable t 'check t)
```

**相关函数**：`axlUIMenuFind`

---

### axlUIMenuDebug

**说明**：`axlUIMenuRegister`的调试函数。这有助于调试`axlUIMenuRegister`的问题。

**Original**: A debug function for axl Menu Trigger. This helps debug issues with axlUIMenuRegister.

**语法**：
```skill
axlUIMenuDebug([g_option])
```

**参数**：
- `g_option`：要查询/清除的数据：
  - `'clear`：清除要加载的菜单列表
  - `'list`：返回要加载的菜单列表（nil表示没有菜单）
  - `'trigger`：清除菜单触发回调和已加载的菜单

**返回值**：
- `t`：调用成功；`nil`：失败或如果清除则没有菜单存在
- `ll_menu`：当前排队的菜单列表

**相关函数**：`axlUIMenuRegister`

---

### axlUIMenuDelete

**说明**：根据当前查找菜单项删除单个菜单项或子菜单。有关菜单更改的讨论，请参阅`axlUIMenuFind`。

**Original**: This deletes a single menu item or submenu based upon what is the current find menu item. See discussion in axlUIMenuFind about menu changes.

**语法**：
```skill
axlUIMenuDelete(x_menuId)
```

**参数**：
- `x_menuId`：来自`axlUIMenuFind`的menuId

**返回值**：
- `t`：如果菜单项已删除；否则 `nil`。

**示例**：
```skill
;; 删除 add rect 命令菜单（add rect 命令仍可从命令行使用）
q = axlUIMenuFind( nil "add rect")
axlUIMenuDelete(q)
;; 删除整个编辑菜单（假设菜单栏的第2个菜单项）
q = axlUIMenuFind( nil 1)
axlUIMenuDelete(q)
```

**相关函数**：`axlUIMenuFind`

---

### axlUIMenuFind

**说明**：通过位置或命令查找菜单项。位置（`x_location`）从0开始。0位置是左侧或最顶部的菜单项。（通常，这是菜单栏上的`File`菜单项）。可以使用负数从右侧指定菜单，其中-1表示最左侧或最底部的菜单。

两种模式可能：
- **按名称查找**：通过命令名称查找菜单项。此方法无法查找菜单栏项，如`File`。按名称查找时，应将`nil`作为第一个参数传递。
- **按位置查找**：从菜单栏（`menuId = nil`）或子菜单标识菜单项。

菜单搜索通过菜单栈控制。第一个参数`x_menuId`控制栈。对于大多数操作，应传递`nil`给此参数。通常，通过菜单栈搜索会使用`x_location`作为第二个参数，因为`t_cmdName`方法足以在菜单层次结构中多级查找命令。如果有嵌套搜索活动，则传递`nil`将重置栈。如果提供的`menuId`早于最后一个id，则栈也会弹出。

`g_menuOption`在位置模式下使用时返回索引子菜单的顶部或底部（见下文）。

**注意（版本到版本的可移植性）**：菜单项和位置可能因版本而异。

**Original**: Finds a menu item by location or a command. The location (x_location) is 0 based. The 0 location is the left or top most menu item. Two modes are possible: Find by name or Find by location. Menu searching is controlled via a menu stack.

**语法**：
```skill
axlUIMenuFind(x_menuId/nil t_cmdName/x_location [g_menuOption])
```

**参数**：
- `x_menuId`：先前调用的menuId返回，或`nil`从菜单根搜索。
- `x_location`：按位置查找项。位置从0开始。因此，"File"菜单位置为0。可以使用负数，其中-1是最右侧（或最底部）的菜单项。
- `t_cmdName`：按命令名称查找项。这可能不仅仅是一个命令，而是一个命令行。
- `g_menuOption`：允许的值是`top`或`bottom`。

**返回值**：
- 如果成功返回菜单编号，否则失败表示为`nil`。

**示例**：
```skill
;; 添加到"Add"菜单末尾（以下任一方式等效，假设add line在菜单栏的第3项）：
l = axlUIMenuFind(nil 3 'bottom)
l = axlUIMenuFind(nil "add line" 'bottom)
;; 查找Help菜单，用于在Help菜单之前添加新子菜单
l = axlUIMenuFind(nil -1 nil)
;; 查找Help菜单顶部，用于添加新帮助菜单项
l = axlUIMenuFind(nil -1 'top)
;; 查找文件菜单
l = axlUIMenuFind(nil 0 nil)
;; 查找 File - Import 菜单底部
l = axlUIMenuFind(nil "load plot" 'bottom)
```

**相关函数**：`axlUIMenuInsert`, `axlUIMenuChange`, `axlUIMenuDelete`, `axlUIMenuDump`, `axlUIMenuLoad`, `axlUIMenuRegister`, `axlTriggerSet`

---

### axlUIMenuInsert

**说明**：将菜单项插入到现有菜单。支持多种模式：
- 添加一个命令菜单项，当用户选择时调度命令。
- 添加新的视觉分隔符到菜单。
- 添加新的子菜单项。假设将通过额外的菜单插入调用填充它。
- 结束子菜单（可选，请参阅菜单栈讨论）。
- 添加多个菜单项。

这是使用菜单栈实现的。`axlUIMenuFind`重置栈，创建的每个子菜单都会递增栈。`'end`模式（子菜单）递减栈。菜单栈允许以非常少的编码开销构建菜单树。栈深度限制为8。

菜单项不应在菜单触发器之外创建。有关讨论请参阅`axlUIMenuFind`。出于开发目的，可以在菜单触发器之外创建菜单项。

**Original**: Inserts menu items to an existing menu. Several modes are supported. This is implemented using a menu stack. Menu items should not be created outside a menu trigger.

**语法**：
```skill
;; 添加菜单项命令
axlUIMenuInsert(x_menuId t_display t_command) -> t/nil
;; 添加分隔符命令
axlUIMenuInsert(x_menuId 'separator) -> t/nil
;; 添加子菜单命令
axlUIMenuInsert(x_menuId 'popup t_display) -> x_subMenuId/nil
;; 添加子菜单结束（可选）
axlUIMenuInsert(x_menuId 'end) -> t/nil
;; 添加多个项
axlUIMenuInsert(x_menuId ll_items) -> t/nil
```

**参数**：
- `x_menuId`：可以从axlUIMenuFind或创建子菜单获得。如果为nil，则使用菜单栈上的当前菜单。
- `t_display`：菜单中显示的文本。可能值：separator - 添加分隔符（水平线）；popup - 创建新子菜单；t_command - 要运行的命令。
- `t_command`：对于'separator忽略此参数；对于'popup是显示字符串；'end选项弹出菜单栈（如果创建菜单树）。
- `ll_items`：这是`t_display`/`t_command`值对的列表，指示此接口在单个调用中添加多个菜单项和子菜单。

**返回值**：
- `t`：成功
- `nil`：失败
- `x_menuId`：如果创建新子菜单，则为新子菜单的嵌套id

**示例**：
```skill
;; 在 add rect 命令之前添加分隔符
q = axlUIMenuFind( nil "add rect")
z = axlUIMenuInsert(q 'separator )
;; 在帮助菜单顶部添加网页链接
q = axlUIMenuFind( nil -1 'top)
z = axlUIMenuInsert(q "Google" "http http://google.com" )
;; 在帮助菜单右侧添加新子菜单，包含两个命令
q = axlUIMenuFind( nil -1)
z = axlUIMenuInsert(q 'popup "MyMenu")
z = axlUIMenuInsert(z "1" "echo hello 1" )
z = axlUIMenuInsert(z "2" "echo hello 2" )
```

**相关函数**：`axlUIMenuFind`

---

### axlUIMenuRegister

**说明**：允许您注册当Allegro加载新菜单时要加载的菜单项。它是`axlUIMenuFind`和`axlUIMenuInsert`的组合。如果需要更复杂的菜单配置，请考虑直接调用`axlTriggerSet`。

对于基于产品注册菜单项，您需要使用此API加上`axlTriggerSet`方法以及一个或多个以下API。要确定符号编辑器是否处于活动状态，使用`axlIsSymbolEditor`函数。`axlDesignType`可用于区分PCB或APD+或SIP。最后，`axlVersion`的`'programName`选项——另一种区分PCB、APD+或SIP的方法；`'displayName`——区分产品（PCB Designer vs Allegro Sigrity vs OrCAD PCB Designer Standard）。这往往在不同版本之间变化很大，可能通过ISR更改。

**注意**：请参阅`axlUIMenuFind`中关于版本到版本可移植性的注意事项。当执行多个菜单注册时，可能存在依赖关系。此API绝不能从`axlTriggerSet`回调函数中调用。

**Original**: This allows you to register menu items to be loaded when Allegro loads a new menu. It is a combination of axlUIMenuFind and axlUIMenuInsert. Caution: See axlUIMenuFind for cautions about portability across releases. This API must never be called from within a axlTriggerSet callback function.

**语法**：
```skill
axlUIMenuRegister(t_command/x_location ll_menu [g_menuOption])
```

**参数**：
- `t_command`：在插入菜单之前的命令（请参阅`axlUIMenuFind`）
- `x_location`：在插入菜单之前的位置（请参阅`axlUIMenuFind`）
- `ll_menu`：要加载的菜单项列表（请参阅`axlUIMenuInsert`的格式3选项）
- `g_menuOption`：添加到菜单顶部或底部的指示（请参阅`axlUIMenuInsert`）

**返回值**：
- `t`：如果为指示的回调注册函数；`nil`：如果命令未能注册触发器。

**相关函数**：`axlUIMenuFind`, `axlUIMenuInsert`, `axlTriggerSet`, `axlUIMenuDebug`, `axlIsSymbolEditor`

---

### axlUIPopupDump

**说明**：将主窗口的当前菜单转储到文件`t_menuFile`。如果`t_menuFile`没有扩展名，则添加默认菜单文件名扩展名。覆盖现有文件时没有用户交互。

**Original**: Dumps the current menus of the main window to the file t_menuFile. The default menu filename extension will be added if t_menuFile has none. There is no user interaction when an existing file is over-written.

**语法**：
```skill
axlUIPopupDump(t_menuFile [g_debug]/t_menuState t_menuType)
```

**参数**：
- `t_menuFile`：菜单要转储到的文件名。如果`t_menuFile`为`nil`，则文件名基于程序的默认菜单名称。
- `g_debug`：如果为`'print`，则仅转储菜单文件中包含的命令。
- `t_menuState`：菜单的状态（如启用或禁用、已选中或未选中），将与名称和命令名一起转储到文件中。
- `t_menuType`：菜单的类型（如父菜单内容或上下文菜单内容），将与名称和命令名一起转储到文件中。

**返回值**：
- 返回写入的文件全名。如果未写入文件，则返回`nil`。

---

### axlUIPrompt

**说明**：在表单中显示字符串`t_message`。用户必须在字段中键入响应。将参数`t_default`显示在字段左侧的括号中。用户按`Return`键或点击窗口中的`OK`按钮以接受`t_default`的值作为函数返回值。如果用户选择`Cancel`按钮，则函数返回`nil`。
此函数是阻塞器。用户必须在进一步与Allegro PCB Editor交互之前做出响应。

**Original**: Displays the string t_message in a form. The user must type a response into the field. Displays the argument t_default in brackets to the left of the field. The user presses the Return key or clicks the OK button in the window to accept the value of t_default as the function return value. If the user selects the Cancel button, the function returns nil. This function is a blocker.

**语法**：
```skill
axlUIPrompt(t_message [t_default]/'password)
```

**参数**：
- `t_message`：显示的消息字符串。
- `t_default`：显示给用户的默认值，如果用户仅按`Return`键或点击`OK`则返回。
- `'password`：模糊处理，不记录用户输入。

**返回值**：
- `t_response`：用户响应或默认值。
- `nil`：用户选择了`取消`。

**示例**：
```skill
axlUIPrompt( "Enter module name" "demo" )
⇒ "mymcm"
```
提示输入模块名，默认值为`demo`。输入`mymcm`覆盖默认值。文本字段显示默认值"demo"。要接受默认值，您可以按`Return`或选择`OK`。否则，在文本字段中键入新值并按`Return`或点击`OK`。在此示例中，在文本字段中输入"mymcm"并按`Return`。axlprompt返回："mymcm"。

> ⚠️ **实机警示（2026-07 ASTB 实战）**：`axlUIPrompt` 是**输入对话框**
> （带输入框、阻塞等待键入），**不是**被动消息提示。想显示状态/操作
> 指引请用 `axlMsgPut(msg)`（消息行，无对话框不阻塞）、
> `axlUIWPrint(nil msg)`（状态栏）或 `printf`（命令行滚动区）。
> 误用症状：每个"提示"都弹成带输入框的对话框挡路。
> 详见 `references/practical-pitfalls.md` 第 2.9 节（含正解对照表）。

密码提示：
```skill
ret = axlUIPrompt( "Enter password" 'password )
```

**相关函数**：`axlUIConfirm`

---

### axlUIWCloseAll

**说明**：关闭所有临时窗口（对话框和文本查看窗口）。临时窗口是在打开另一个设计（例如.brd）时关闭的对话框。通过SKILL，此窗口属性由`axlUIWPerm` API设置。约束管理器当前被视为永久窗口，但这可能在将来的版本中更改。阻止窗口（例如，文件浏览器对话框）无法通过此调用关闭。

**Original**: This closes all temporary windows (dialogs and text view windows). A temporary window is a dialog that closes if you open another design (for example, . brd). Via SKILL this window attribute is set by the axlUIWPerm API. The constraint manager is currently considered a permanent window but this may change in future releases. A blocking window (for example, File Browser dialogs) cannot be closed via this call.

**语法**：
```skill
axlUIWCloseAll()
```

**参数**：无

**返回值**：
- `t`：始终

**相关函数**：`axlUIWPerm`

---

### axlUIWIconify

**说明**：此命令为窗口创建图标或从图标打开窗口。这与`axlUIWExpose`不同，后者也从图标打开窗口，但暴露隐藏窗口并允许将窗口提升到堆栈顶部。请注意，所有子窗口也会打开或关闭到图标。因此，如果使主Allegro PCB Editor窗口成为图标，则其所有子窗口也将关闭。
`t_window`名称可能因版本而异，尽管这不正常。`nil`可用于主窗口。当前，约束管理器接口不支持此SKILL命令。

**Original**: This command either creates an icon for a window or open a window from an icon. This is different from axlUIWExpose, which also opens a window from an icon but exposes hidden windows and permits raising a window to the top of the stack. Note all sub-windows also open or closed to an icon. t_window name may change from release to release although this is not normal. nil may be used for the main window. Currently, Constraint Manager interface is not supported by this SKILL command.

**语法**：
```skill
axlUIWIconify(r_window/t_window t/nil)
```

**参数**：
- `r_window`：窗口ID。
- `t_window`：窗口名称。这是在PCB Editor脚本中使用的名称——使用`setwindow`命令调用的名称。
- `t`：窗口图标化；`nil`：从图标打开。

**返回值**：
- `t`：成功；`nil`：失败（找不到指定的窗口）

**示例**：
```skill
;; 图标化Allegro PCB Editor的命令
axlUIWIconify("pcb")
```

**相关函数**：`axlUIWIsWindow`, `axlUIWIsIconic`, `axlUIWExpose`

---

### axlUIWIsIconic

**说明**：窗口是否处于图标状态。`nil`可用于主窗口。`t_window`名称可能因版本而异，尽管这不正常。约束管理器尚不支持此SKILL命令。

**Original**: Is the window in an icon state. nil may be used for the main window. t_window name may change from release to release although this is not normal. Constraint Manager is not yet supported by this SKILL command.

**语法**：
```skill
axlUIWIsIconic(r_window/t_window)
```

**参数**：
- `r_window`：窗口ID。
- `t_window`：窗口名称。这是在Allegro脚本窗口中出现的名称——使用`setwindow`命令。

**返回值**：
- `t`：成功；`nil`：失败（找不到指定的窗口）

**示例**：
```skill
;; 检查主窗口是否处于图标状态
axlUIWIsIconic("pcb")
```

**相关函数**：`axlUIWIsWindow`, `axlUIWIconify`

---

### axlUIWIsWindow

**说明**：如果命名窗口已打开，则返回`t`。`t_window`名称可能因版本而异，尽管这不正常。

**Original**: Returns t if named window is open. t_window name may change from release to release although this is not normal.

**语法**：
```skill
axlUIWIsWindow(t_window)
```

**参数**：
- `t_window`：窗口名称。这是在Allegro PCB Editor中出现的名称——使用`setwindow`命令。

**返回值**：
- `t`：成功；`nil`：没有打开该名称的窗口

**示例**：
```skill
;; 约束管理器是否打开
axlUIWIsWindow("cmgr")
```

**相关函数**：`axlUIWClose`

---

### axlUIWMove

**说明**：移动窗口。新位置（`l_xy`）即左上角，以像素指定。`nil`可用于主窗口。`t_window`名称可能因版本而异，尽管这不正常。尚不支持约束管理器。

**Original**: Moves a window. New location (l_xy) which is upper left corner, is specified in pixels. nil may be used for the main window. t_window name may change from release to release although this is not normal. Constraint Manager is not yet supported.

**语法**：
```skill
axlUIWMove(r_window/nil t_window l_xy)
```

**参数**：
- `r_window`：窗口ID，或如果为nil则为主窗口。
- `t_window`：窗口名称。这是在脚本中来自`setwindow`命令的名称。
- `l_xy`：`(x_X x_y)`

**返回值**：
- `t`：窗口已移动；`nil`：错误，句柄不是窗口

**示例**：
```skill
;; 将主窗口移动到显示的左上角
axlUIWMove(nil 0:0)
```

**相关函数**：`axlUIWSize`

---

### axlUIWRedraw

**说明**：重绘指示的窗口。如果窗口ID为`nil`，则重绘主窗口。

**Original**: Redraws indicated window. If window ID is nil redraws the main window.

**语法**：
```skill
axlUIWRedraw(r_window/nil)
```

**参数**：
- `r_window`：窗口ID，或如果为`nil`，则为主窗口。

**返回值**：
- `t`：成功；`nil`：窗口已关闭或不是窗口

---

### axlUIWSize

**说明**：返回窗口的外部大小。大小以像素为单位。x和y坐标是窗口的左上角。在UNIX/Linux上，`y`值通常包含由于标题栏高度导致的偏移。

**Original**: Returns outer size of a window. Size is in pixels. x and y coordinates are upper left corner of window. On UNIX/Linux, the y value will typically include an offset due to title bar height.

**语法**：
```skill
axlUIWSize(r_window/nil)
```

**参数**：
- `r_window`：窗口id，或如果为`nil`则为主窗口。

**返回值**：
- `ll_rect`：`((x_X x_Y) (x_Width x_Height))`
- `nil`：错误，句柄不是窗口

**相关函数**：`axlUIWMove`

---

### axlIsViewFileType

**说明**：测试`g_userType`是否为长消息窗口类型。

**Original**: Tests whether g_userType is a long message window type.

**语法**：
```skill
axlIsViewFileType(g_userType)
```

**参数**：
- `g_userType`：要测试的参数。

**返回值**：
- `t`：`g_userType`是`r_windowMsg`类型。
- `nil`：`g_userType`不是`r_windowMsg`类型。

**示例**：
```skill
logWindow = axlUIViewFileCreate("batch_drc.log" "Batch DRC Log" t)
axlIsViewFileType(logWindow)
⇒ t
```

**相关函数**：`axlUIViewFileCreate`

---

### axlUIViewFileCreate

**说明**：打开文件查看窗口以显示文件（`t_file`）。如果文件不存在则是错误。窗口应该有一个标题（`t_title`）。如果`g_deleteFile`设置为`t`，则当查看窗口退出或重用时删除文件。建议应用程序不要自行删除查看文件，因为保存和打印按钮将无法工作。
查看窗口的大小由`lx_size`控制。默认大小为24x80。对于大行/列值可能会产生不可预测的结果。
窗口的放置由`lt_placement`列表处理。如果此值为`nil`，则窗口在编辑器上居中。
窗口可以通过程序控制通过`axlUIWClose`函数删除。如果同类型的窗口已经存在且未固定，则函数尝试自动重用它。

**Original**: Opens a file view window to display a file (t_file), it is an error for file not to exist. Window should be given a title (t_title). If g_deleteFile is set to t, the file is deleted when view window is quit or reused. Size of viewable window is controlled by lx_size. Default size is 24x80. Placement of window is handled by lt_placement list.

**语法**：
```skill
axlUIViewFileCreate(t_file t_title g_deleteFile [lx_size] [lt_placement] [g_formToExpose])
```

**参数**：
- `t_file`：要显示的ASCII文件名。如果值为""则显示最后注册的日志文件。
- `t_title`：要在窗口标题栏中显示的标题。
- `g_deleteFile`：当用户退出窗口或另一个任务重用窗口时删除文件。
- `lx_size`：窗口的初始大小（字符行和列）。默认为24x80。设置较大的窗口大小可能会导致不可预测的结果。
- `lt_placement`：窗口放置提示。请参阅**窗口定位**部分。
- `g_formToExpose`：另一个窗口的可选句柄。如果指定，则当查看文件窗口关闭时，此窗口将带到桌面顶部，并且也是此窗口的父窗口。如果未指定，则主程序窗口是父窗口。

**返回值**：
- `r_windowMsg`：窗口`r_windowMsg`。
- `nil`：`r_windowMsg`未显示。

**示例**：
```skill
;; 显示批处理DRC日志文件，保存窗口id。
;; 当用户退出窗口时删除文件drc.log。
logWindow = axlUIViewFileCreate("batch_drc.log" "Batch DRC Log" nil)
```
日志文件显示在窗口中。当用户选择关闭时，删除文件`batch_drc.log`。

---

### axlUIViewFileReuse

**说明**：重用查看窗口以显示文件（`t_file`）。如果文件不存在则抛出错误。窗口获得标题（`t_title`）。期望`r_windowMsg`为查看窗口类型。如果用户退出窗口，它将在旧大小/位置重新打开。
如果`g_deleteFile`为`t`，则当查看窗口退出或重用时删除文件。建议应用程序不要自行删除查看文件，因为保存和打印按钮将无法工作。

**Original**: Reuses the view window to display a file (t_file). Error is thrown if the file does not exist. Window is given a title (t_title). Expects r_windowMsg to be type of view window. If user quit the window it will re-open it at the old size/position.

**语法**：
```skill
axlUIViewFileReuse(r_windowMsg t_file t_title g_deleteFile [g_formToExpose])
```

**参数**：
- `r_windowMsg`：之前使用`axlUIViewFileCreate`创建的现有查看窗口的dbid。
- `t_file`：要显示的ASCII文件名。
- `t_title`：要在窗口标题栏中显示的标题。
- `g_deleteFile`：当用户退出窗口或另一个任务重用窗口时删除文件。
- `g_formToExpose`：可选参数，定义文本文件窗口关闭时要暴露的窗口句柄。默认是`axlUIViewFileCreate`设置的父窗口。通常不应使用此参数。

**返回值**：
- `t`：文件已显示。
- `nil`：文件未显示。

**示例**：
```skill
(axlUIViewFileReuse logWindow "ncdrill.log" "NC Drill Log" nil)
```
显示文件`ncdrill.log`，重用显示`batch_drc.log`时创建的窗口`logWindow`。退出窗口时自动删除文件`ncdrill.log`。

---

### axlUIYesNo

**说明**：提供一个显示消息`t_message`的对话框。如果选择`是`则返回`t`，如果选择`否`则返回`nil`。此函数是阻塞器。您必须在进一步与Allegro PCB Editor交互之前做出响应。
如果设置了环境变量`noconfirm`，则对于"是"立即返回`t`，对于"否"立即返回`nil`。

**Original**: Provides a dialog box displaying the message t_message. Returns t if you choose Yes and nil for No. This function is a blocker. You must respond before any further interaction with Allegro PCB Editor. Note: If environment variable noconfirm is set, we immediately return t for yes and nil for no.

**语法**：
```skill
axlUIYesNo(t_message [t_title] [s_default])
```

**参数**：
- `t_message`：要显示的消息字符串。

**返回值**：
- `t`：用户响应了"是"。
- `nil`：用户响应了"否"。

**示例**：
```skill
axlUIYesNo( "Overwrite module?" )
axlUIYesNo( "Overwrite module?" nil 'no )
axlUIYesNo( "Overwrite module?" "My Skill Program" )
```
显示确认窗口。如果用户选择"是"，函数返回t，否则返回nil。

**相关函数**：`axlUIConfirm`

---

### axlUIWExpose

**说明**：打开并重新显示隐藏或受限的窗口，将其带到显示器上所有其他当前窗口的前面。如果为`nil`，则显示主窗口。

**Original**: Opens and redisplays a hidden or confined window, bringing it to the front of all other current windows on the display. If nil, the main window is displayed.

**语法**：
```skill
axlUIWExpose(r_window/nil)
```

**参数**：
- `r_window`：窗口dbid。

**返回值**：
- `t`：窗口已打开并带到前面。
- `nil`：dbid不是窗口。

**示例**：
```skill
logWindow = axlUIViewFileCreate("batch_drc.log" "Batch DRC Log" t)
;; 其他交互式代码，可能导致Batch DRC Log窗口被覆盖
;; 取消覆盖日志窗口：
axlUIWExpose(logWindow)
⇒ t
```

---

### axlUIWClose

**说明**：关闭窗口（如果它是打开的）。窗口也可以由用户关闭。请参阅本章开头的特定窗口类型部分。

**Original**: Closes a window, if it is open. Window may also be closed by user. See initial sections of the chapter for specific window types.

**语法**：
```skill
axlUIWClose(r_window/t_window)
```

**参数**：
- `r_window`：窗口dbid。
- `t_window`：窗口名称。这是在Allegro脚本中来自`setwindow`命令的名称。`t_window`名称可能因版本而异，尽管这不正常。

**返回值**：
- `t`：窗口已关闭。
- `nil`：窗口已关闭，或dbid不是窗口。

**示例**：
```skill
logWindow = axlUIViewFileCreate("batch_drc.log" "Batch DRC Log" t)
;;; 其他交互式代码
axlUIWClose(logWindow)
;; 关闭约束管理器
axlUIWClose("cmgr")
```

**相关函数**：`axlUIWIsWindow`

---

### axlUIWHelpRegister

**说明**：为用户编写的SKILL命令或表单（对话框）注册帮助文档。这通常与`axlCmdRegister`结合使用。您应该在执行`axlCmdRegister`时进行此调用，而不是等到与命令关联的SKILL代码执行时。您还可以通过`help_config.txt`文件（请参阅`<cdsroot>/share/pcb/help/help_config.txt`）放置在站点或pcbenv目录中来添加注册。

所有平台支持的文档类型（通过文件扩展名确定）：
- `.txt` - 通过Allegro内部长消息窗口显示的纯文本文件
- `.html` - 通过Web浏览器显示的HTML浏览器
- `.pdf` - 通过Acrobat阅读器显示的Acrobat文件

在Windows上，通常支持其他扩展名，这取决于计算机上安装的程序（例如，Word的doc和PowerPoint的ppt）。

**Original**: This registers a help document for a user written SKILL command or form (dialog). This is typically used in conjunction with axlCmdRegister. You should make this call at the time you do a axlCmdRegister instead of waiting until the SKILL code associated with the command executes. The document types supported on all platforms are: .txt, .html, .pdf.

**语法**：
```skill
;; 注册新帮助文件命令
axlUIWHelpRegister(t_cmd t_helpFile) -> t/nil
;; 查询是否为命令注册了帮助文件
axlUIWHelpRegister(t_cmd) -> t_file
;; 删除为命令注册的帮助文件
axlUIWHelpRegister(t_cmd "") -> t/nil
;; 列出所有注册帮助文件的命令
axlUIWHelpRegister(nil) -> lt_cmds
```

**参数**：
- `t_cmd`：命令名称或form.<formname>，用于注册表单按钮的帮助
- `t_helpFile`：要显示的文档。支持变量扩展，因此您可以嵌入Allegro环境变量，使文件安装位置相对于变量设置。

**返回值**：
- `t`：成功；`nil`：失败（参数无效）

**示例**：
```skill
;; 使用Allegro环境文件的内容覆盖add line帮助
axlCmdRegister("add line" "$TELENV")
```

**相关函数**：`axlCmdRegister`

---

### axlUIWPrint

**说明**：将消息打印到主窗口以外的窗口。如果`r_window`没有消息行，则消息转到主窗口。此函数不缓冲消息，而是立即显示它们。如果消息字符串不以消息类（例如`\e`）开头，则将其视为文本（`\t`）消息。（请参阅`axlMsgPut`）如果为`nil`，则显示主窗口。

**Original**: Prints a message to a window other than the main window. If r_window does not have a message line, the message goes to the main window. This function does not buffer messages, but displays them immediately. If the message string does not start with a message class (for example \e), it is treated as a text (\t) message. (See axlMsgPut) If nil, displays the main window.

**语法**：
```skill
axlUIWPrint(r_window/nil t_formatString [g_arg1 ...])
```

**参数**：
- `r_window`：窗口dbid。
- `t_formatString`：上下文消息（printf类）格式字符串。
- `g_arg1...`：使用`t_formatString`打印的任意数量的替换参数。像C语言`printf`语句一样使用。

**返回值**：
- `t`：消息打印到窗口。
- `nil`：dbid不是窗口。

**示例**：
```skill
axlUIWPrint(nil "Please enter a value:")
Please enter a value:
⇒ t
```

---

### axlUIWBlock

**说明**：此函数与`axlFormCreate`的`g_nonBlock = nil`选项不兼容。如果将此函数与`axlFormCreate`一起使用，必须在`g_formAction`上设置回调。这将阻止指示的窗口，直到它被销毁。所有其他窗口都被禁用。与`axlFormCreate`中的阻止选项不同，它可以递归调用。一旦进入阻止模式，就不应弹出非阻止窗口。此行为未定义且不受支持。如果阻止，应在创建窗口的函数中使用`lt_placement`选项列表中的`block`属性，以便标题栏显示它是阻止窗口。如果您注册了窗口回调，则必须允许窗口关闭，因为取消阻止功能在关闭时取消阻止其他窗口，以便阻止窗口销毁后正确的窗口获得焦点。

**Original**: This function is not compatible with the g_nonBlock = nil option to axlFormCreate. If using this function with axlFormCreate you must set a callback on the g_formAction. This places a block on the indicated window until it is destroyed. All other windows are disabled. It may be called recursively, unlike the block option in axlFormCreate. Once you enter a blocking mode you should not bring up a window that is non-blocking. If you block, you should set the block attribute in the Window Placement list so that the title bar shows it is a blocking window.

**语法**：
```skill
axlUIWBlock(r_window)
```

**参数**：
- `r_window`：窗口dbid。

**返回值**：
- `t`：成功
- `nil`：失败（例如，窗口已关闭或dbid不是窗口）

---

### axlUIEditFile

**说明**：允许用户以独立于操作系统的方式编辑文件（在UNIX和Windows下均可工作）。用户可以通过设置`VISUAL`或`EDITOR`环境变量来覆盖默认编辑器。

Windows注意事项：默认编辑器是`Notepad`。不支持标题栏设置。

Unix注意事项：默认编辑器是`vi`。额外的环境变量`WINDOW_EDITOR`允许用户指定基于X的编辑器，如`xedit`。此模式下不支持标题栏。
在阻止模式下，主程序的窗口在文件编辑器窗口退出之前不会重绘。

仅`axlUIWClose`支持此函数返回的`r_window`句柄。

**Original**: Allows the user to edit a file in an OS independent manner (works under both UNIX and Windows.) User may override the default editor by setting either the VISUAL or EDITOR environment variables. Windows notes: The default editor is Notepad. The title bar setting is not supported. Unix notes: The default editor is vi. An additional environment variable, WINDOW_EDITOR, allows the user to specify an X-based editor such as xedit. The title bar is not supported in this mode.

**语法**：
```skill
axlUIEditFile(t_filename t_title/nil g_block)
```

**参数**：
- `t_filename`：要编辑的文件名。
- `t_title`：标题栏名称，或`nil`表示默认标题栏。
- `g_block`：指定阻止模式（`t`）或非阻止模式（`nil`）的标志。

**返回值（非阻止模式）**：
- `r_window`：成功
- `nil`：失败

**返回值（阻止模式）**：
- `t`：成功
- `nil`：失败

---

### axlUIMultipleChoice

**说明**：显示一个包含问题和两个或多个答案列表的对话框。必须选择其中一个答案才能继续。返回所选答案。

**Original**: Displays a dialog box containing a question with a set of two or more answers in a list. You must choose one of the answers to continue. Returns the chosen answer.

**语法**：
```skill
axlUIMultipleChoice(t_question lt_answers [t_title])
```

**参数**：
- `t_question`：要显示的问题文本。
- `lt_answers`：表示可能答案的文本字符串列表。
- `t_title`：可选标题。如果不存在，则提供通用标题。

**返回值**：
- `x_answer`：表示所选答案的整数。此值从零开始，即零表示第一个答案，一表示第二个答案，依此类推。
- `nil`：检测到错误。

**示例**：
```skill
ret = axlUIMultipleChoice("Pick a choice"
  '("Pick me" "No Pick me" "I'm here!") "Cmd title")
```

---

### axlUIViewFileScrollTo

**说明**：滚动到文件查看器中的指定行。值`-1`转到查看器末尾。查看窗口中的行号可能与文件中的行号不匹配，因为查看器中存在换行。对于基于html的查看器，命令无法返回滚动窗口中的项目数。返回值仅对传统文本窗口有效。

**Original**: Scrolls to a specified line in the file viewer. A value of -1 goes to the end of the viewer. The number of the line in the view window may not match the number of lines in the file due to line wrapping in the viewer. With the html-based viewer the command is unable to return the number of items in scroll window.

**语法**：
```skill
axlUIViewFileScrollTo(r_windowMsg x_line/nil)
```

**参数**：
- `r_windowMsg`：现有查看窗口。
- `x_line`：要滚动到的行：0是文件顶部，-1是文件底部，-2返回查看器中的行数。

**返回值**：
- `x_lines`：查看窗口中的行数。
- `nil`：没有查看文件窗口。

**示例**：
```skill
pm = axlUIViewFileCreate("topology.log" "Topology" nil)
axlUIViewFileScrollTo(pm -1)
```
显示文件`topology.log`，滚动到文件末尾。

---

### axlUIWBeep

**说明**：向用户发送警报，通常是蜂鸣声。

**Original**: Sends an alert to the user, usually a beep.

**语法**：
```skill
axlUIWBeep()
```

**参数**：无

**返回值**：无

---

### axlUIWDisableQuit

**说明**：禁用系统菜单"退出"选项，使用户无法选择它来关闭窗口。

**Original**: Disables the system menu Quit option so the user cannot choose it to close the window.

**语法**：
```skill
axlUIWDisableQuit(o_window)
```

**参数**：
- `o_window`：窗口句柄。

**返回值**：
- `t`：窗口句柄有效。
- `nil`：窗口句柄无效。

---

### axlUIWExposeByName

**说明**：按名称查找窗口并将其暴露（将其提升到窗口堆栈顶部，如果它是图标，则将其恢复到窗口状态）。您可以使用`setwindow`命令参数通过脚本获取Allegro PCB Editor窗口名称。如果窗口是表单，则通过从名称中删除`form.`前缀来获取名称。窗口名称可能因版本而异。要提升控制面板中的项（例如，`Options`），请使用`axlControlRaise()`函数。

**Original**: Finds a window by name and exposes it (raises it to the top of the window stack and restores it to a window state it if it is an icon). You can use the setwindow command argument to get Allegro PCB Editor window names via scripting. Names of windows may change from release to release. To raise an item in the control panel, use the axlControlRaise() function.

**语法**：
```skill
axlUIWExposeByName(t_windowName)
```

**参数**：
- `t_windowName`：窗口名称。

**返回值**：
- `t`：找到窗口。
- `nil`：未找到窗口。

---

### axlUIWPerm

**说明**：通常，表单和其他窗口在打开另一个数据库时自动关闭。此函数允许覆盖该默认行为。

**注意**：使用此函数时，请考虑窗口在打开新数据库时自动关闭，因为窗口显示的数据可能不再适用于新数据库。如果不提供第二个参数，则返回窗口的当前状态。

**Original**: Normally forms and other windows close automatically when another database opens. This function allows that default behavior to be overridden. Notes: When you use this function, consider that windows automatically close when a new database opens because the data the windows display may no longer apply to the new database. If you do not provide a second argument, returns the current state of the window.

**语法**：
```skill
axlUIWPerm(r_window [t/nil])
```

**参数**：
- `r_window`：窗口id。
- `t`/`nil`：`t` - 设置永久；`nil` - 重置永久。

**返回值**：
- `t`：窗口存在。
- `nil`：窗口不存在。

**示例**：
```skill
handle = axlFormCreate('testForm "axlform" nil 'testFormCb, t nil)
axlUIWPerm(handle t)
;; 打开测试表单并使其永久
ret = axlUIWPerm(handle)
;; 测试窗口是否永久
```

---

### axlUIWSetHelpTag

**说明**：这已大部分被`axlUIWHelpRegister`取代，后者适用于命令和表单。将给定帮助标签附加到具有端口的预存在对话框。此函数支持帮助标签的子类化，即如果帮助标签已与对话框关联，则不会替换它。添加新的帮助标签是通过用点连接两个标签来完成的。例如：现有帮助标签：`myOldTag`，新帮助标签：`myNewTag`，结果帮助标签：`myOldTag.myNewTag`。

**Original**: This has been mostly replaced by axlUIWHelpRegister that works for commands and forms. Attaches the given help tag to a pre-existing dialog with a port. This function supports subclassing of the help tags.

**语法**：
```skill
axlUIWSetHelpTag(r_window t_tag)
```

**参数**：
- `r_window`：窗口id。
- `t_tag`：帮助字符串的子类。

**返回值**：
- `t`：帮助标签已附加。
- `nil`：参数无效。

**相关函数**：`axlUIWHelpRegister`

---

### axlUIWSetParent

**说明**：设置窗口的父窗口。创建窗口时，其父窗口是应用程序的主窗口，这对大多数实现来说已足够。要对从另一个表单启动的表单运行阻止模式，请将子表单的父窗口设置为启动的表单。
设置父窗口提供以下好处：
- 允许阻止模式正确运行。
- 如果父窗口关闭，则子窗口也关闭。
- 如果父窗口图标化，则子窗口隐藏。
- 子窗口在窗口堆叠顺序中保持在其父窗口之上。

**Original**: Sets the parent of a window. When a window is created, its parent is the main window of the application, which is sufficient for most implementations. To run blocking mode on a form launched from another form, set the child form's parent window to be the launched form. Setting the parent provides these benefits: Allows blocking mode to behave correctly. If the parent is closed, then the child is also closed. If the parent is iconified, then the child is hidden. The child stays on top of its parent in the window stacking order.

**语法**：
```skill
axlUIWSetParent(o_childWindow o_parentWindow/nil)
```

**参数**：
- `o_childWindow`：子窗口句柄。
- `o_parentWindow`：父窗口（如果为`nil`，则为应用程序的主窗口，这通常是默认父窗口。）父窗口和子窗口不能是同一窗口。

**返回值**：
- `t`：父窗口已成功设置。
- `nil`：由于非法窗口句柄而无法设置父窗口。

---

### axlUIWShow

**说明**：根据传递的选项显示或隐藏窗口。如果传递的窗口id为`nil`，则该函数适用于主窗口。

**注意**：在窗口上使用`showna`选项可能会使窗口处于活动状态。在已经可见的窗口上使用`show`选项可能不会使其处于活动状态。

**Original**: Shows or hides a window depending on the option passed. If the window id passed is nil, the function applies to the main window. Notes: Using the showna option on a window may make the window active. Using the show option on a window that is already visible may not make it active.

**语法**：
```skill
axlUIWShow(r_window/nil s_option)
```

**参数**：
- `r_window`：窗口id。如果为`nil`，表示主窗口。
- `s_option`：以下之一：
  - `'show`：显示并激活窗口
  - `'showna`：显示但不激活窗口。
  - `'hide`：隐藏窗口。
  - `nil`：显示可用选项。

**返回值**：
- `t`：窗口已显示或隐藏。
- `nil`：窗口id不正确或给定选项无效。

---

### axlUIWTimerAdd

**说明**：为间隔计时器添加或删除回调。这不是实时计时器。它与基于窗口的消息处理同步。实际回调间隔可能有所不同。除非处理计时器窗口（`o_window`）的窗口事件，否则计时器不会触发（并调用您）。您必须在UI相关调用中等待（例如，`axlEnter*`、阻止`axlFormDisplay`、`axlUIWBlock`等）。要接收回调，返回到主程序消息处理。但是，另一个处于阻止模式的窗口可能会延迟您返回到主程序。

您可以向返回的`timerId`添加属性，以存储您自己的数据以便在计时器回调中访问。

使用提供的回调函数时需要注意：
- 回调中的处理应相对简短
- 不要打开或保存设计
- 不要打开或关闭表单或窗口
- dbid可能变得陈旧
- 不应使用`axlAddSimpleRbandDynamics`
- 太多活动触发器会影响性能
- Allegro dbid仅在回调中有效。您不能将dbid传入或传出此回调函数。始终需要从数据库重新获取它们。

**Original**: Adds or removes a callback for an interval timer. This is not a real-time timer. It is synchronous with the processing of window based messages. The actual callback interval may vary. The timer does not go off (and call you back) unless window events for the timer window (o_window) are being processed.

**语法**：
```skill
axlUIWTimerAdd(o_window x_timeout g_oneshot u_callback)
```

**参数**：
- `o_window`：计时器关联的窗口。如果`o_window`为`nil`，则计时器关联主窗口。
- `x_timeout`：计时器触发并调用回调过程之前的超时时间（毫秒）。超时不是精确的，因为它依赖于处理窗口消息。
- `g_oneshot`：控制计时器触发次数。使用以下值之一：
  - `t`：计时器触发一次并自动移除。
  - `nil`：计时器在设定的时间间隔持续触发，直到由`axlUIWTimerRemove`移除。
- `u_callback`：计时器触发时调用的过程。使用以下参数调用，其返回值被忽略：
  ```skill
  u_callback(o_window o_timerId x_elapsedTime)
  ```
  - `o_window`：您提供给`axlUIWTimerAdd`的窗口
  - `o_timerId`：`axlUIWTimerAdd`返回的计时器id
  - `x_elapsedTime`：自添加计时器以来的近似经过时间（毫秒）

**返回值**：
- `o_timerId`：计时器的标识符。用于移除计时器。此返回值在超出范围时受垃圾回收影响。当垃圾被回收时，计时器被移除。但是，不要指望垃圾回收来移除计时器，因为您不知道垃圾回收何时启动。如果需要永久计时器，请将其分配给全局变量。
- `nil`：未添加计时器。

**示例**：
```skill
procedure( YourSkillProcedure()
  ; 使用主窗口设置连续计时器
  timerId = axlUIWTimerAdd(nil 2000 nil 'YourTimerCallback)
  timerId->yourData = yourdata
)
procedure( YourTimerCallback( window timerId elapsedTime)
  ; 您的时间段已过。执行某些操作。
)
```

**相关函数**：`axlUIWTimerRemove`

---

### axlUIWTimerRemove

**说明**：移除由`axlUIWTimerAdd`添加的计时器。

**Original**: Removes a timer added by axlUIWTimerAdd.

**语法**：
```skill
axlUIWTimerRemove(o_timerId)
```

**参数**：
- `o_timerId`：`axlUIWTimerAdd`返回的id。

**返回值**：
- `t`：计时器已移除。
- `nil`：计时器id无效。

---

### axlUIWUpdate

**说明**：强制更新窗口。如果您对窗口进行了多次更改，并且不打算返回主循环或执行需要用户交互的SKILL调用，则使用此调用更新窗口。例如，如果您正在执行耗时的处理而不将控制权返回给UI消息泵。
要使用，请进行所有窗口更改，然后进行此调用。如果窗口ID为`nil`，则暴露主窗口。

**Original**: Forces an update of a window. If you made several changes to a window and are not planning on going back to the main loop or doing a SKILL call that requires user interaction, use this call to update a window. To use, make all your window changes and then make this call. If window ID is nil, exposes the main window.

**语法**：
```skill
axlUIWUpdate(r_window/nil)
```

**参数**：
- `r_window`：窗口id或`nil`（如果是主窗口）。

**返回值**：
- `t`：窗口已更新。
- `nil`：窗口已关闭或窗口ID无效。

---

### axlUIYesNoCancel

**说明**：显示一个阻塞的"是"/"否"/"取消"对话框，并显示提供的提示消息。

**Original**: Displays a blocking Yes/No/Cancel dialog box with the prompt message provided.

**语法**：
```skill
axlUIYesNoCancel(t_message [t_title] [s_default])
```

**参数**：
- `t_message`：要显示的消息。
- `t_title`：可选。在确认标题栏中放置的内容。默认是程序显示名称。
- `s_default`：可选。可以是`yes`、`no`或`cancel`，以指定默认响应。默认是`yes`。

**返回值**：
- `x_result`：基于用户选择的数字：
  - `0`：表示"否"
  - `1`：表示"是"
  - `2`：表示"取消"

---

### axlUIDataBrowse

**说明**：分析调用者函数请求的所有对象，将每个对象通过调用者的回调函数传递。然后将对象放入单选列表中。此列表会阻塞，直到用户做出选择。一旦用户选择对象，它将以包含两个对象的列表返回给调用者：所选名称和（对于数据库对象）对象的AXL dbid。

**Original**: Analyzes all objects requested by the caller function, passing each through the caller's callback function. Then puts the objects in a single-selection list. This list blocks until a user makes a selection. Once the user selects an object, it is passed back to the caller in a list containing two objects: the selected name and, for a database object, the AXL dbid of the object.

**语法**：
```skill
axlUIDataBrowse(s_dataType ls_options t_title g_sorted [t_helpTag] [l_callback] [g_args])
```

**参数**：
- `s_dataType`：以下之一：
  - `'NET`, `'PADSTACK`, `'PACKAGE_SYMBOL`, `'DEVICE`, `'PARTNUMBER`, `'REFDES`, `'BOARD_SYMBOL`, `'FORMAT_SYMBOL`, `'SHAPE_SYMBOL`, `'FLASH_SYMBOL`, `'BRD_TEMPLATE`, `'SYM_TEMPLATE`, `'TECH_FILE`
- `ls_options`：包含至少一个以下项的列表：
  - `'RETRIEVE_OBJECT`：所选对象返回其dbid
  - `'RETRIEVE_NAME`：所选对象返回其名称
  - `'EXAMINE_DATABASE`：最初在数据库中查找对象列表
  - `'EXAMINE_LIBRARY`：最初在查找对象列表时使用环境PATH变量
  - `'DATABASE_FIXED`：数据库的只读复选框
  - `'LIBRARY_FIXED`：文件（库）的只读复选框
- `t_title`：对话框标题的提示
- `g_sorted`：指示是否应对列表进行排序的开关
- `t_helpTag`：浏览器的帮助标签
- `l_callback`：回调筛选函数，它接受参数name、object和`g_arg`作为第三个参数。根据对象是否符合浏览条件返回t或nil。
- `g_arg`：传递给`l_callback`作为第三个参数的通用参数。

**返回值**：
- `t_name o_dbid`：已做出选择并使用了RETRIEVE_OBJECT。
- `t_name nil`：已做出选择并使用了RETRIEVE_NAME。

**示例**：
```skill
axlUIDataBrowse('NET '(RETRIEVE_NAME) "hi" t)
axlUIDataBrowse('PADSTACK '(RETRIEVE_NAME) "hi" t)
axlUIDataBrowse('PACKAGE_SYMBOL '(EXAMINE_DATABASE EXAMINE_LIBRARY RETRIEVE_NAME) "hi" t)
axlUIDataBrowse('PACKAGE_SYMBOL '(EXAMINE_LIBRARY RETRIEVE_OBJECT) "hi" t)
axlUIDataBrowse('PARTNUMBER '(RETRIEVE_OBJECT) "Part Number" t)
```

---

*文档翻译完成 — 返回顶部*
