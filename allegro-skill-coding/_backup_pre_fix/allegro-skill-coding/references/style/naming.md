# Allegro SKILL (AXL) 代码规范 — 命名规范

> 本章基于 Cadence SPB 17.4 官方示例代码提炼，适用于 Allegro PCB Editor SKILL (AXL) 扩展开发。
> 涉及中文注释的 `.il` 文件应当使用 **GBK 编码**保存，以确保 Allegro 中文环境正确显示。

---

## 一、总体原则

**1.1 命名应当具备自描述性（self-documenting）**

标识符名称必须准确反映其用途、功能或所属模块，避免使用无意义缩写或单字母命名（循环变量除外）。

> 来自 `read.il` 的写法：`test_design`、`test_nets`、`test_symbols` 等函数名直接表明其测试目标；`print_title`、`my_print` 等辅助函数名称亦清晰说明用途。

**1.2 命名风格应当与 Allegro AXL 官方 API 保持一致**

AXL 原生函数采用 `axl` + `PascalCase` 风格（如 `axlDBCreateVia`、`axlGetSelSet`），用户自定义代码应当参照此惯例，以确保 Allegro 生态内的一致性。

> 来自 `axlswap_comp.il` 的写法：对外命令函数 `axlSwapComponent` 采用 `axl` + 大驼峰（PascalCase）风格，与官方 API 命名一致。

**1.3 命名中禁止 SKILL 保留字符的冲突使用**

标识符中禁止包含 `!`、`@`、`#`、`$`、`%`、`^`、`&`、`*` 等特殊符号（`-` 在变量名中会被解析为减号运算符）。文件名中可使用连字符 `-` 或下划线 `_`，但函数名与变量名中应当统一使用下划线 `_` 作为分隔符。

---

## 二、文件命名规范

**2.1 SKILL 源文件必须使用 `.il` 作为扩展名**

Allegro SKILL 源代码文件的标准扩展名为 `.il`，表单定义文件使用 `.form`。禁止省略扩展名或使用其他扩展名。

> 来自 `D:/Cadence/SPB_17.4/share/pcb/examples/skill/` 目录：所有示例 SKILL 文件均使用 `.il` 扩展名，如 `cline2shape.il`、`change_net_on_vias.il`、`axl_delete.il`。

**2.2 文件名应当使用小写字母，单词间以下划线 `_` 或连字符 `-` 分隔**

文件名推荐采用纯小写字母，单词间使用下划线 `_` 或连字符 `-` 分隔。应当避免大小写混排，以兼容跨平台文件系统。

> 来自 `cmds/` 目录：`change_net_on_vias.il`、`cline2shape.il`、`axlswap_comp.il`、`cns-design.il` 均采用小写命名。
>
> 来自 `dbcreate/` 目录：`axldbctvia.il`、`axldbctpin.il` 采用小写，无分隔符（为官方 API 名称的紧凑缩写形式）。
>
> 来自 `edit/` 目录：`axl_delete.il` 采用小写+下划线分隔。

**2.3 文件名长度应当适中，兼顾可读性与紧凑性**

文件名不应当超过 40 个字符。若文件为特定命令实现，文件名可与命令名保持一致；若为工具类或测试类，文件名应当体现模块功能。

> 来自 `ui/` 目录：`ashmeter.il`（ash + meter，表意明确）、`timer.il`（简洁明了）。
>
> 来自 `dbcreate/` 目录：`axldbctvia.il` 为 `axlDBCreateVia` 的缩写，体现其测试驱动功能。

---

## 三、函数与过程命名规范

**3.1 对外公开的命令函数/主入口函数应当使用 `axl` + 大驼峰（PascalCase）命名**

若函数作为 Allegro 命令被注册（通过 `axlCmdRegister`），或为对外公开的 API 接口，函数名应当使用 `axl` 前缀 + 大驼峰，与官方 AXL API 命名风格一致。这有助于用户识别该函数为 Allegro 扩展命令。

> 来自 `axlswap_comp.il`：
> ```skill
> (defun axlSwapComponent ()
> ```
> 该函数作为 `axlswap_comp.il` 的主入口，对外提供元件交换功能，使用 `axl` + `SwapComponent` 的大驼峰风格。

> 来自 `axl_delete.il`：
> ```skill
> (defun axlDeleteTest ()
> ```
> 该函数作为删除功能测试的入口函数，使用 `axl` + `DeleteTest` 的大驼峰风格。

**3.2 命令名（`axlCmdRegister` 第一个参数）应当使用小写，单词间可使用下划线分隔**

`axlCmdRegister` 注册的命令名是 Allegro 命令行中用户输入的字符串，应当使用全小写，便于用户输入。若命令名由多个单词组成，可用下划线 `_` 连接，也可直接连写。

> 来自 `cline2shape.il`：
> ```skill
> axlCmdRegister("cline2shape" 'LCB_cline_to_shape ?cmdType "interactive"
>  ?doneCmd 'LCB_Done ?cancelCmd 'LCB_Cancel ?undo t)
> axlCmdRegister("cline2shape2" 'LCB_cline_to_shape2 ?cmdType "interactive"
>  ?doneCmd 'LCB_Done ?cancelCmd 'LCB_Cancel ?undo t)
> ```

> 来自 `change_net_on_vias.il`：
> ```skill
> axlCmdRegister("change_vianet"  `rplc_netvia)
> ```

> 来自 `ashmeter.il`：
> ```skill
> axlCmdRegister("metertest" 'ash_meterform)
> ```

> 来自 `show_element.il`：
> ```skill
> axlCmdRegister("myshow" 'ShowElement ?cmdType "interactive")
> ```

**3.3 内部私有函数/辅助函数必须使用下划线 `_` 作为前缀**

仅在文件内部调用、不对外暴露的辅助函数、回调函数或工具函数，其名称必须以单下划线 `_` 开头。这是 SKILL 中约定俗成的"私有"标识，表明该函数为内部实现细节，不应被外部调用。

> 来自 `axlswap_comp.il`：
> ```skill
> (defun _build_popup ()
> (defun _swapCB ()
> (defun _cancel_cmd ()
> (defun _done_cmd ()
> (defun _compName (sym_inst "o")
> (defun _do_swap (swap_list)
> ```
> 以上函数均为 `axlSwapComponent` 的内部辅助函数，以下划线开头。

> 来自 `change_net_on_vias.il`：
> ```skill
> procedure( _RPVdoNetReplacement( vias net )
> ```
> 该函数为 `rplc_netvia` 命令的内部实现，以下划线 + 模块缩写 `RPV` 开头。

> 来自 `cns-design.il`：
> ```skill
> procedure( _AcDesignTier(fw)
> procedure( _AcDesignMember(item sep fType)
> procedure( _AcDesignDone(fw)
> procedure( _AcDesignCancel(fw)
> procedure( _AcDesignEvent()
> procedure( _AcDesignRefresh(fw)
> ```
> 所有表单内部支持函数均以 `_AcDesign` 为前缀并以下划线开头。

> 来自 `ashmeter.il`：
> ```skill
> procedure(_ashMeterCallback(mhandle)
> ```
> 表单回调函数以下划线 + 模块名 `ashMeter` 开头。

**3.4 模块级私有函数/过程可使用命名空间前缀 + 下划线 + 大驼峰或小写下划线**

对于较复杂的模块，可在内部函数前使用模块命名空间前缀（如作者缩写或模块缩写），后接具体功能描述，以避免不同文件间的函数名冲突。前缀后既可使用大驼峰，也可使用小写+下划线风格。

> 来自 `cline2shape.il`：
> ```skill
> procedure(LCB_cline_to_shape()
> procedure(LCB_cline_to_shape2()
> procedure(LCB_Setup()
> procedure(LCB_Oops()
> procedure(LCB_Cancel()
> procedure(LCB_Done()
> ```
> `LCB` 为作者/模块前缀（可能代表作者姓名缩写），所有函数均以 `LCB_` 为前缀，后续采用大驼峰或下划线分隔（如 `LCB_cline_to_shape` 为小写下划线，`LCB_Setup` 为大驼峰）。这种命名方式在命令内部建立了自己的命名空间，有效防止了全局命名冲突。

> 来自 `change_net_on_vias.il`：
> ```skill
> procedure( _RPVdoNetReplacement( vias net )
> ```
> `RPV` 为 `Replace Via` 的缩写，表示该函数属于 `change_net_on_vias` 命令的内部实现。

> 来自 `cns-design.il`：
> ```skill
> procedure( _AcDesignTier(fw)
> procedure( _AcDesignDoit(fw)
> procedure( _cnsCreateModeField(fw _arg)
> ```
> `AcDesign` 和 `cns` 均为模块前缀，用于区分不同功能模块。

**3.5 现代 SKILL 代码推荐使用 `procedure` 而非 `defun` 定义函数**

`procedure` 是 SKILL 的现代化函数定义方式，支持参数类型检查等特性。在 AXL 开发中，`procedure` 已成为主流风格，但在简单场景下 `defun` 仍然兼容。

> 来自 `change_net_on_vias.il`：
> ```skill
> procedure( rplc_netvia()
> procedure( _RPVdoNetReplacement( vias net )
> ```

> 来自 `cline2shape.il`：
> ```skill
> procedure(LCB_cline_to_shape()
> procedure(LCB_Setup()
> ```

> 来自 `axlswap_comp.il`（较老风格）：
> ```skill
> (defun _build_popup ()
> (defun axlSwapComponent ()
> ```
> 注意：`axlswap_comp.il` 仍使用 `defun`，这代表了早期 AXL 示例的风格。现代开发中应当优先使用 `procedure`。

---

## 四、变量与参数命名规范

**4.1 局部变量应当使用小写或小驼峰（camelCase）命名**

在 `let`、`prog` 等局部作用域中声明的变量，应当使用小写字母，单词间可直接连写或使用小驼峰风格。变量名应当简洁但表意明确。

> 来自 `axlswap_comp.il`：
> ```skill
> (let (user_data swap_pop)
> ```
> `user_data` 和 `swap_pop` 使用小写+下划线分隔。

> 来自 `change_net_on_vias.il`：
> ```skill
> (let ( mypopup vias net )
> ```
> `mypopup`、`vias`、`net` 均为小写单词，直接描述变量内容。

> 来自 `cline2shape.il`：
> ```skill
> let( (lclines layer polydbid )
> ```
> `lclines`（local clines）、`layer`、`polydbid` 使用小写或小驼峰缩写。

> 来自 `cns-design.il`：
> ```skill
> (let (items field )
> ```
> `items`、`field` 等变量使用简洁小写。

> 来自 `ashmeter.il`：
> ```skill
> let( (meterfile)
> ```
> `meterfile` 使用小驼峰。

**4.2 全局变量/持久化变量应当使用下划线 `_` 前缀**

若变量需要在 Allegro 会话中持久保存（跨命令调用），或作为表单句柄等全局状态存储，变量名应当使用下划线 `_` 前缀，以区别于局部变量。同时应当使用 `boundp` 检查是否已绑定，防止重复定义。

> 来自 `cns-design.il`：
> ```skill
> unless(boundp('_AcDesignFw) _AcDesignFw = nil)
> ```
> `_AcDesignFw` 是表单句柄全局变量，以下划线开头。

> 来自 `timer.il`：
> ```skill
> unless(boundp('timerFw) timerFw = nil)
> ```
> 注意：`timerFw` 虽无前缀，但在 `timer.il` 中作为全局变量使用。严格来说，应当使用 `_timerFw` 以符合规范。`_AcDesignFw` 是更规范的示例。

> 来自 `cline2shape.il`：
> ```skill
> LCB_mark = axlDBTransactionStart()
> LCBnotDone = t
> ```
> 这两个全局变量使用 `LCB_` 前缀（模块命名空间），但无前导下划线。在较新的代码中，推荐为全局变量增加前导下划线以明确标识其全局属性。

**4.3 回调函数（callback）参数应当使用描述性名称**

回调函数的参数应当反映其接收对象的类型，如表单句柄、窗口标识等。

> 来自 `ashmeter.il`：
> ```skill
> procedure(_ashMeterCallback(mhandle)
> ```
> `mhandle` 表示 "meter/form handle"，清晰表明参数为表单句柄。

> 来自 `timer.il`：
> ```skill
> procedure( timerCB( window timerId elapsedTime)
> procedure( timerCBForForm( window timerId elapsedTime)
> ```
> `window`、`timerId`、`elapsedTime` 均为小写+小驼峰，直接描述参数含义。

> 来自 `cns-design.il`：
> ```skill
> procedure( _AcDesignCB(fw)
> ```
> `fw` 是 "form window" 的缩写，作为表单回调函数的参数在 AXL 示例中广泛使用。

**4.4 参数名应当简洁，避免与全局变量同名**

函数参数应当使用简短但表意的名称。若参数类型为数据库对象（dbid），可在名称中体现；若参数为列表，可使用复数形式。

> 来自 `axlswap_comp.il`：
> ```skill
> (defun _compName (sym_inst "o")
> (defun _do_swap (swap_list)
> ```
> `sym_inst`（symbol instance）、`swap_list` 均为小写+下划线，描述参数类型。

> 来自 `axl_delete.il`：
> ```skill
> (defun deleteAndPrint (items message)
> ```
> `items`（待删除对象列表）、`message`（输出消息）均为小写。

> 来自 `cns-design.il`：
> ```skill
> procedure( _AcDesignAllSame(fw mode)
> ```
> `fw`（form window）、`mode`（模式）简洁明了。

---

## 五、测试函数与工具函数命名规范

**5.1 测试函数应当使用模块前缀 + 测试类型后缀的命名方式**

对于测试驱动文件（如 `dbcreate/` 目录下的测试驱动），测试函数应当使用 `dbc_`（database create）或类似前缀 + 模块名 + 测试编号/测试类型的后缀，以便于识别和管理。

> 来自 `axldbctvia.il`：
> ```skill
> (defun dbc_via_print (return)
> (defun dbc_via_t1 ()
> (defun dbc_via_t2 ()
> (defun dbc_via_te_args ()
> (defun dbc_via_te_args2 ()
> (defun dbc_via_tparent ()
> (defun dbc_via_te_parent ()
> (defun dbc_via_test ()
> ```
> 命名模式：`dbc_`（database create 前缀）+ `via_`（模块名）+ 功能描述：
> - `t1`、`t2`：表示测试用例 1、测试用例 2
> - `te_args`：表示 "test error arguments"（参数错误测试）
> - `te_parent`：表示 "test error parent"（父对象错误测试）
> - `test`：总入口函数

> 来自 `axldbctpin.il`：
> ```skill
> (defun dbc_pin_print (return)
> (defun dbc_pin_t1 ()
> (defun dbc_pin_t2 ()
> (defun dbc_pin_te_args ()
> (defun dbc_pin_te_text ()
> (defun dbc_pin_test ()
> ```
> 同样遵循 `dbc_pin_` + 功能描述的命名模式。

**5.2 数据库读取测试函数应当使用 `test_` + 对象类型 + `_` 后缀的命名方式**

对于数据库读取（dbread）测试函数，应当使用 `test_` + 对象类型（如 `nets`、`comps`、`vias`）的命名方式。

> 来自 `read.il`：
> ```skill
> (defun test_design (p)
> (defun test_nets (p)
> (defun test_comps (p)
> (defun test_paths (p)
> (defun test_segments (p)
> (defun test_symbols (p)
> (defun test_vias (p)
> (defun test_drcs (p)
> (defun test_pins (p)
> (defun test_shapes (p)
> (defun test_text (p)
> (defun test_branches (p)
> (defun axldbread_test ()
> ```
> 所有测试函数均以 `test_` 为前缀，后接被测试的数据库对象类型。总入口函数 `axldbread_test` 使用 `axl` 前缀 + 大驼峰。

---

## 六、特殊命名约定

**6.1 回调函数名应当使用 `CB` 后缀或 `Callback` 后缀，或以下划线 + 描述性名称命名**

回调函数（如表单回调、按钮回调、弹出菜单回调）应当在名称中体现其回调性质，可使用 `CB` 缩写、完整 `Callback` 单词，或以下划线 + 动作描述的方式命名。

> 来自 `axlswap_comp.il`：
> ```skill
> (defun _swapCB ()
> ```
> `CB` 为 callback 的缩写。

> 来自 `ashmeter.il`：
> ```skill
> procedure(_ashMeterCallback(mhandle)
> ```
> 使用完整 `Callback` 后缀。

> 来自 `cns-design.il`：
> ```skill
> procedure( _AcDesignCB(fw)
> ```
> 使用 `CB` 缩写。

> 来自 `timer.il`：
> ```skill
> procedure( timerCB( window timerId elapsedTime)
> procedure( timerFormCB(fw)
> procedure( timerCBForForm( window timerId elapsedTime)
> ```
> 使用 `CB` 缩写，如 `timerCB`、`timerFormCB`、`timerCBForForm`。

**6.2 表单文件中的字段名（field name）应当使用小写，与 SKILL 代码中的变量名保持一致**

在 `.form` 表单定义文件中定义的字段名，以及在 SKILL 代码中通过 `axlFormSetField`、`axlFormGetField` 访问的字段名，应当使用小写。表单代码中，字段名通常以字符串形式传入。

> 来自 `cns-design.il`：
> ```skill
> axlFormSetField(fw field t )
> axlFormSetField(fw "apply" enable )
> axlFormSetField(fw "modemsg" "  DRC mode control not available in this product.")
> case(fw->curField
> ("done"     _AcDesignDone(fw))
> ("cancel"   _AcDesignCancel(fw))
> ("apply"    _AcDesignDoit(fw))
> ("on"       _AcDesignAllSame(fw 'on))
> ("off"      _AcDesignAllSame(fw 'off))
> ("batch"    _AcDesignAllSame(fw 'batch))
> )
> ```
> 表单字段名如 `"done"`、`"cancel"`、`"apply"`、`"on"`、`"off"`、`"batch"` 均为小写。

**6.3 事务标记（transaction mark）变量应当使用有意义的前缀 + `mark` 的命名**

在使用数据库事务 API（`axlDBTransactionStart`、`axlDBTransactionMark`、`axlDBTransactionCommit`）时，事务标记变量应当使用 `mark` 或 `_mark` 作为名称的一部分，以表明其事务标记属性。

> 来自 `cline2shape.il`：
> ```skill
> LCB_mark = axlDBTransactionStart()
> when(LCB_mark axlDBTransactionMark(LCB_mark))
> when( LCB_mark axlDBTransactionRollback(LCB_mark))
> when( LCB_mark axlDBTransactionCommit(LCB_mark))
> ```
> `LCB_mark` 为模块前缀 + `mark`，表示事务标记。

**6.4 布尔状态变量应当使用表意明确的前缀或后缀**

布尔类型的变量（如循环标志、完成标志）应当使用 `is`、`has`、`done`、`notDone` 等表意前缀或后缀，避免使用 `flag` 等无意义名称。

> 来自 `cline2shape.il`：
> ```skill
> LCBnotDone = t
> while( LCBnotDone
> ```
> `LCBnotDone` 明确表示 "LCB 模块尚未完成" 的状态。更规范的写法应为 `LCB_notDone`（下划线分隔）或 `LCB_isDone`（肯定式语义）。

---

## 七、命名空间与冲突避免

**7.1 在大型项目中应当使用模块前缀避免全局命名冲突**

当项目包含多个 SKILL 文件时，不同文件中的函数和全局变量可能发生冲突。应当在命名中使用模块前缀（如作者缩写、功能模块缩写）建立命名空间。

> 来自 `cline2shape.il`：`LCB_` 前缀为所有该文件的函数和变量建立命名空间。
>
> 来自 `cns-design.il`：`_AcDesign` 和 `_cns` 前缀为设计约束表单模块建立命名空间。
>
> 来自 `change_net_on_vias.il`：`_RPV` 前缀为替换过孔命令的内部函数建立命名空间。
>
> 来自 `axl_delete.il`：函数名使用 `deleteAndPrint`、`deleteClines`、`deleteShape` 等动词+名词描述，由于函数本身表意明确且文件独立，未使用严格前缀，但仍通过 `delete` 动词统一了命名空间。

**7.2 禁止在全局命名空间中定义无前缀的短名称函数**

避免在全局作用域中定义名称过短（如 `a`、`b`、`test`）或无前缀的通用名称函数（如 `setup`、`cleanup`），这些名称极易与其他 SKILL 代码或 Allegro 内置函数冲突。

> 来自 `read.il`：虽然函数名 `test_design`、`test_nets` 等以 `test_` 为前缀，但 `print_title` 和 `my_print` 相对通用，在大型项目中应当使用 `axl_read_print_title` 等更具体的前缀。

---

## 八、示例代码汇总

以下汇总各官方示例文件中的命名风格，供参考对照。

### 8.1 文件名示例

| 文件路径 | 命名风格 | 说明 |
|---------|---------|------|
| `D:/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/cline2shape.il` | 小写，无分隔符 | 命令名直接映射 |
| `D:/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/change_net_on_vias.il` | 小写，下划线分隔 | 描述命令功能 |
| `D:/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/axlswap_comp.il` | 小写，下划线分隔 | `axl` + 功能缩写 |
| `D:/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/cns-design.il` | 小写，连字符分隔 | 模块名缩写 |
| `D:/Cadence/SPB_17.4/share/pcb/examples/skill/dbcreate/axldbctvia.il` | 小写，无分隔符 | 官方 API 缩写 |
| `D:/Cadence/SPB_17.4/share/pcb/examples/skill/edit/axl_delete.il` | 小写，下划线分隔 | `axl` + 功能 |
| `D:/Cadence/SPB_17.4/share/pcb/examples/skill/ui/ashmeter.il` | 小写，无分隔符 | 简洁名称 |
| `D:/Cadence/SPB_17.4/share/pcb/examples/skill/ui/timer.il` | 小写，无分隔符 | 简洁名称 |

### 8.2 函数名示例

| 来源文件 | 函数名 | 类型 | 说明 |
|---------|-------|------|------|
| `axlswap_comp.il` | `axlSwapComponent` | 对外命令 | `axl` + 大驼峰 |
| `axlswap_comp.il` | `_build_popup` | 内部辅助 | 下划线 + 小写下划线 |
| `axlswap_comp.il` | `_swapCB` | 回调 | 下划线 + 动作 + `CB` |
| `axlswap_comp.il` | `_do_swap` | 内部辅助 | 下划线 + 小写下划线 |
| `change_net_on_vias.il` | `rplc_netvia` | 对外命令 | 小写缩写（较早风格） |
| `change_net_on_vias.il` | `_RPVdoNetReplacement` | 内部辅助 | 下划线 + 前缀 + 大驼峰 |
| `cline2shape.il` | `LCB_cline_to_shape` | 对外命令 | 前缀 + 小写下划线 |
| `cline2shape.il` | `LCB_Setup` | 内部辅助 | 前缀 + 大驼峰 |
| `cline2shape.il` | `LCB_Done` | 内部辅助 | 前缀 + 大驼峰 |
| `axldbctvia.il` | `dbc_via_test` | 测试入口 | `dbc_` + 模块 + 功能 |
| `axldbctvia.il` | `dbc_via_te_args` | 错误测试 | `dbc_` + 模块 + `te_` + 功能 |
| `axldbctpin.il` | `dbc_pin_test` | 测试入口 | `dbc_` + 模块 + 功能 |
| `cns-design.il` | `AcnsDesignForm` | 对外表单 | 大驼峰 |
| `cns-design.il` | `_AcDesignCB` | 表单回调 | 下划线 + 前缀 + `CB` |
| `cns-design.il` | `_AcDesignDoit` | 内部辅助 | 下划线 + 前缀 + 大驼峰 |
| `cns-design.il` | `_cnsCreateModeField` | 内部辅助 | 下划线 + 前缀 + 大驼峰 |
| `axl_delete.il` | `axlDeleteTest` | 对外测试 | `axl` + 大驼峰 |
| `axl_delete.il` | `deleteAndPrint` | 内部辅助 | 小驼峰 |
| `axl_delete.il` | `deleteShapeVoids` | 内部辅助 | 小驼峰 |
| `ashmeter.il` | `ash_meterform` | 对外命令 | 小写 + 下划线 |
| `ashmeter.il` | `_ashMeterCallback` | 表单回调 | 下划线 + 小驼峰 + `Callback` |
| `timer.il` | `timerForm` | 对外表单 | 小驼峰 |
| `timer.il` | `timerCBForForm` | 回调 | 小驼峰 + `CB` |
| `read.il` | `test_design` | 测试 | `test_` + 对象 |
| `read.il` | `test_nets` | 测试 | `test_` + 对象 |
| `read.il` | `axldbread_test` | 总入口 | `axl` + 大驼峰 + `test` |
| `show_element.il` | `ShowElement` | 对外命令 | 大驼峰（较早风格） |

### 8.3 变量名示例

| 来源文件 | 变量名 | 作用域 | 说明 |
|---------|-------|--------|------|
| `axlswap_comp.il` | `user_data` | 局部 | 下划线分隔 |
| `axlswap_comp.il` | `swap_pop` | 局部 | 下划线分隔 |
| `change_net_on_vias.il` | `mypopup` | 局部 | 小写组合 |
| `change_net_on_vias.il` | `vias` | 局部 | 复数名词 |
| `cline2shape.il` | `LCB_mark` | 全局 | 模块前缀 + `mark` |
| `cline2shape.il` | `LCBnotDone` | 全局 | 模块前缀 + 状态 |
| `cns-design.il` | `_AcDesignFw` | 全局 | 下划线 + 前缀 + 用途 |
| `cns-design.il` | `fw` | 参数/局部 | 表单句柄缩写 |
| `cns-design.il` | `field` | 局部 | 简洁小写 |
| `ashmeter.il` | `meterfile` | 局部 | 小驼峰 |
| `timer.il` | `timerFw` | 全局 | 小驼峰 |
| `timer.il` | `timerId` | 全局 | 小驼峰 |
| `timer.il` | `elapsedTime` | 参数 | 小驼峰 |
| `axl_delete.il` | `items` | 参数 | 复数名词 |
| `axl_delete.il` | `message` | 参数 | 小写名词 |

---

## 九、附：Allegro SKILL 编码声明

**9.1 包含中文注释的 `.il` 文件必须使用 GBK 编码保存**

Allegro PCB Editor 在中文 Windows 环境下默认使用 GBK 编码解析 SKILL 源文件。若文件包含中文注释，必须以 **GBK 编码**保存；若使用 UTF-8 编码保存，中文注释在 Allegro 命令行和日志中可能出现乱码。

> 建议：在代码编辑器的保存选项中明确选择 "GBK" 或 "ANSI" 编码。对于纯 ASCII 内容的文件，UTF-8 无 BOM 格式亦可兼容，但为统一规范，建议所有 `.il` 文件均使用 GBK 编码。

---

*本章规范依据 Cadence SPB 17.4 官方示例代码（`D:/Cadence/SPB_17.4/share/pcb/examples/skill/` 目录）提炼，涵盖 `cmds/`、`dbcreate/`、`dbread/`、`edit/`、`ui/` 等子目录中的典型文件。*
