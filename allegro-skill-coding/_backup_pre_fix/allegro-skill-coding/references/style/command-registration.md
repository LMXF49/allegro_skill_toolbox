# 5. 命令注册与交互模式

## 5.1 总体原则

1. **命令注册是 Allegro SKILL 扩展与 Allegro PCB Editor 交互的唯一入口**。所有用户可通过命令行调用的自定义功能，必须通过 `axlCmdRegister` 完成注册。未注册的函数无法作为独立命令执行。
2. **交互式命令必须遵循"初始化 → 选择 → 处理 → 清理"的生命周期**。命令入口负责初始化环境（清空选择集、设置过滤器、定义弹出菜单），主循环负责获取用户输入，回调函数负责提交或回滚操作并释放资源。
3. **涉及数据库修改的交互命令必须启用撤销支持**。通过 `?undo t` 参数注册，并结合 `axlDBTransactionStart()` / `Commit()` / `Rollback()` 管理事务边界，确保用户可通过 Allegro 的 Undo/Redo 机制恢复操作。
4. **用户交互提示必须清晰明确**。`axlSelect` 的 `?prompt` 参数、弹出菜单标签、表单字段等均应使用无歧义的中文或英文描述，引导用户正确完成操作。
5. **选择集操作必须严格限定对象类型**。任何交互式选择前，必须通过 `axlSetFindFilter()` 显式设置 `?enabled` 和 `?onButtons`，禁止在全局开放选择状态下执行命令，避免误操作非目标对象。
6. **若文件注释或交互提示中包含中文字符，文件必须以 GBK 编码保存**。Allegro SKILL 解释器在中文环境下默认采用 GBK 编码解析源文件，UTF-8 编码的中文注释将导致乱码或加载失败。

---

## 5.2 命令注册（`axlCmdRegister`）

### 5.2.1 基本语法与函数引用

**规范 5.2.1-1**：命令注册时，函数名参数必须使用 `'`（quote）或 `` ` ``（backquote）前缀，传递函数符号而非调用函数。禁止在注册语句中直接写裸函数名或带括号的形式。

> **依据**：来自 `show_element.il`（`defun` 风格）和 `change_net_on_vias.il`（`procedure` 风格）的写法。Cadence 官方示例中两种引用方式均有使用，但均明确使用了符号引用前缀。

```skill
;; 推荐：使用 quote 前缀
axlCmdRegister("myshow" 'ShowElement ?cmdType "interactive")

;; 推荐：使用 backquote 前缀（与 quote 等价，在 Skill 中均可接受）
axlCmdRegister("change_vianet" `rplc_netvia)

;; 禁止：裸函数名或带括号的调用形式
axlCmdRegister("badcmd" MyFunction)      ;; 错误：传递的是变量值而非符号
axlCmdRegister("badcmd" (MyFunction))    ;; 错误：试图调用函数并传递返回值
```

**规范 5.2.1-2**：交互式命令（需要用户通过鼠标或键盘在画布上交互）必须显式指定 `?cmdType "interactive"`。通用命令（如直接执行脚本、批量处理）可省略 `?cmdType`，但交互式命令不得省略。

> **依据**：来自 `cline2shape.il` 的写法：
> ```skill
> axlCmdRegister("cline2shape" 'LCB_cline_to_shape ?cmdType "interactive"
>  ?doneCmd 'LCB_Done ?cancelCmd 'LCB_Cancel ?undo t)
> ```
> 以及 `show_element.il`：
> ```skill
> axlCmdRegister("myshow" 'ShowElement ?cmdType "interactive")
> ```

**规范 5.2.1-3**：同一命令提供多种实现方式（如两种撤销风格）时，允许为不同命令名注册同一主函数，但必须在文件头部通过注释说明各命令的区别与适用场景。

> **依据**：来自 `cline2shape.il` 的写法：
> ```skill
> axlCmdRegister("cline2shape" 'LCB_cline_to_shape ?cmdType "interactive"
>  ?doneCmd 'LCB_Done ?cancelCmd 'LCB_Cancel ?undo t)
> axlCmdRegister("cline2shape2" 'LCB_cline_to_shape2 ?cmdType "interactive"
>  ?doneCmd 'LCB_Done ?cancelCmd 'LCB_Cancel ?undo t)
> ```
> 文件注释明确说明：`cline2shape` 将所有转换作为单次撤销操作，`cline2shape2` 将每次转换作为独立撤销操作。

### 5.2.2 回调函数注册（`?doneCmd` / `?cancelCmd`）

**规范 5.2.2-1**：需要用户通过 Done/Cancel 结束交互循环的命令，应当在 `axlCmdRegister` 中显式注册 `?doneCmd` 和 `?cancelCmd` 回调函数。禁止在交互循环内部通过轮询键盘或鼠标状态自行判断退出条件。

> **依据**：来自 `cline2shape.il`：
> ```skill
> axlCmdRegister("cline2shape" 'LCB_cline_to_shape ?cmdType "interactive"
>  ?doneCmd 'LCB_Done ?cancelCmd 'LCB_Cancel ?undo t)
> ```
> 以及 `entertest.il`：
> ```skill
> (axlCmdRegister "entertest" 'enterTest ?cmdType "interactive"
> 					  ?doneCmd 'enterTestDone
> 					  ?cancelCmd 'enterTestCancel)
> ```

**规范 5.2.2-2**：`?doneCmd` 和 `?cancelCmd` 的回调函数签名应为无参数（或接受由 Allegro 传入的上下文参数），并通过调用 `axlFinishEnterFun()` 或 `axlCancelEnterFun()` 正式结束交互状态。禁止在回调中使用 `exit` 或 `return` 强行终止命令。

> **依据**：来自 `entertest.il` 的标准写法：
> ```skill
> (defun enterTestDone ()
>     (axlFinishEnterFun)
>     (axlEnterPoint))
> 
> (defun enterTestCancel ()
>     (axlCancelEnterFun))
> ```
> 以及 `cline2shape.il` 的事务型写法：
> ```skill
> procedure(LCB_Done()
>   when( LCB_mark axlDBTransactionCommit(LCB_mark))
>   LCB_mark = nil
>   LCBnotDone = nil
>   axlCancelEnterFun())
> 
> procedure(LCB_Cancel()
>   axlUIWPrint(nil "** Cancelled Program. **")
>   when( LCB_mark axlDBTransactionRollback(LCB_mark))
>   LCB_mark = nil
>   LCBnotDone = nil
>   axlClearSelSet()
>   axlCancelEnterFun())
> ```

### 5.2.3 撤销支持（`?undo`）

**规范 5.2.3-1**：任何会修改数据库（创建、删除、更改对象属性）的交互命令，必须在注册时启用 `?undo t`。禁止在未启用撤销支持的情况下执行破坏性数据库操作。

> **依据**：来自 `cline2shape.il` 的写法：
> ```skill
> axlCmdRegister("cline2shape" 'LCB_cline_to_shape ?cmdType "interactive"
>  ?doneCmd 'LCB_Done ?cancelCmd 'LCB_Cancel ?undo t)
> ```
> 该命令将 Cline 转换为 Shape，涉及删除原对象和创建新对象，属于典型的破坏性操作，官方示例强制启用 `?undo t`。

---

## 5.3 交互式命令生命周期

### 5.3.1 选择集初始化

**规范 5.3.1-1**：交互式命令的主入口函数（`procedure`/`defun`）必须在第一行调用 `axlClearSelSet()`，清空历史选择集，避免前序命令或用户预选对象干扰当前命令逻辑。

> **依据**：来自 `change_net_on_vias.il`：
> ```skill
> procedure( rplc_netvia()
>   (let ( mypopup vias net )
>     
>     axlClearSelSet()
>     axlSetFindFilter(?enabled `("NOALL" "VIAS")
> 			     ?onButtons `("VIAS"))
>     ...
> ```
> 以及 `axlswap_comp.il`：
> ```skill
> (defun axlSwapComponent ()
>     (axlClearSelSet)
>     (axlSetFindFilter ?enabled `("NOALL" "NAMEFORM" "SYMBOLS") 
> 		      ?onButtons `("SYMBOLS"))
>     ...
> ```

### 5.3.2 FindFilter 设置

**规范 5.3.2-1**：调用 `axlSelect()` 之前，必须通过 `axlSetFindFilter()` 显式设置 `?enabled` 和 `?onButtons` 参数。`?enabled` 用于定义可选对象类型，`?onButtons` 用于控制 Find 过滤器窗口中默认按下的按钮。禁止省略 `?onButtons` 导致用户需要手动切换过滤器。

> **依据**：来自 `show_element.il`：
> ```skill
> axlSetFindFilter(?enabled, '("NOALL", "ALLTYPES", "NAMEFORM")
> ?onButtons "ALLTYPES")
> ```
> 来自 `change_net_on_vias.il`：
> ```skill
> axlSetFindFilter(?enabled `("NOALL" "VIAS")
> 			     ?onButtons `("VIAS"))
> ```
> 来自 `cline2shape.il`：
> ```skill
> axlSetFindFilter(?enabled list("noall" "clines") 
>                 ?onButtons list("noall" "clines"))
> ```
> 来自 `axlswap_comp.il`：
> ```skill
> (axlSetFindFilter ?enabled `("NOALL" "NAMEFORM" "SYMBOLS") 
> 		  ?onButtons `("SYMBOLS"))
> (axlOpenFindFilter)  ;; 打开 Find 过滤器窗口，方便用户查看当前过滤条件
> ```

**规范 5.3.2-2**：对于需要用户频繁选择不同类型对象的命令，应当在 `axlSetFindFilter` 之后调用 `axlOpenFindFilter()`，显示 Find 过滤器窗口，帮助用户理解当前可选对象范围。命令结束前应当调用 `axlCloseFindFilter()` 恢复界面。

> **依据**：来自 `axlswap_comp.il` 的写法：
> ```skill
> (axlOpenFindFilter)
> ...
> (axlCloseFindFilter)
> ```

### 5.3.3 选择提示（`?prompt`）

**规范 5.3.3-1**：使用 `axlSelect()` 获取用户选择时，应当通过 `?prompt` 参数提供明确的操作提示，说明用户需要选择什么对象、以何种方式（点选或框选）。提示文本末尾应当使用句号（`.`）或冒号（`:`）结束。

> **依据**：来自 `change_net_on_vias.il`：
> ```skill
> axlSelect(?prompt "Select vias by pick or window.");
> ```
> 来自 `cline2shape.il`：
> ```skill
> lclines = axlGetSelSet(axlSelect(?prompt "Select Clines to convert to a shape."))
> ```

**规范 5.3.3-2**：选择提示中若包含中文，必须使用 GBK 编码保存文件，否则 Allegro 命令行提示区域将显示乱码。

> **依据**：`cline2shape.il` 文件头部包含中文注释说明使用风险，表明 Cadence 官方示例支持中文注释，但需使用与 Allegro 环境匹配的编码（Windows 版通常为 GBK）。

### 5.3.4 选择结果处理

**规范 5.3.4-1**：获取选择结果后，必须通过 `axlGetSelSet()` 读取，并使用 `when()` 或 `if()` 判断选择集是否为空。禁止对空选择集执行迭代或数据库操作，避免产生无效事务或运行时错误。

> **依据**：来自 `change_net_on_vias.il`：
> ```skill
> vias = axlGetSelSet()
> when(vias
>     ...
>     net = cadr(axlUIDataBrowse('NET '(RETRIEVE_OBJECT) "New Net Name" t))
>     when(net
>         axlDBCloak('_RPVdoNetReplacement( vias net ) 'shape)
>     )
> )
> ```
> 以及 `axlswap_comp.il` 中对选择集数量的判断：
> ```skill
> (cond
>     ((lessp (axlGetSelSetCount) 2)
>         (printf "Must select two components before swapping"))
>     (t (_do_swap (axlGetSelSet))))
> ```

---

## 5.4 右键弹出菜单（Popup Menu）

### 5.4.1 弹出菜单定义与激活

**规范 5.4.1-1**：交互式命令应当定义右键弹出菜单（RMB Popup），并在命令初始化阶段通过 `axlUIPopupSet()` 激活。未设置弹出菜单的命令将使用 Allegro 默认菜单，可能导致用户无法正确触发 Done/Cancel。

> **依据**：来自 `show_element.il`：
> ```skill
> defun( ShowElement ()
>    mypopup = axlUIPopupDefine(nil, list(list("Done" 'axlFinishEnterFun)
> list("Cancel" 'axlCancelEnterFun)))
>    axlUIPopupSet(mypopup)
>    ...
> ```
> 以及 `change_net_on_vias.il`：
> ```skill
> mypopup = axlUIPopupDefine( nil
>              (list (list "Done" 'axlFinishEnterFun)
>              (list "Cancel" 'axlCancelEnterFun)))
> axlUIPopupSet( mypopup)
> ```

**规范 5.4.1-2**：弹出菜单的回调函数名必须使用 `'` 前缀传递符号。对于 Allegro 内置的退出函数（`axlFinishEnterFun`、`axlCancelEnterFun`），同样使用符号引用。

> **依据**：所有官方示例一致使用 `'axlFinishEnterFun` 和 `'axlCancelEnterFun`。来自 `show_element.il`、`change_net_on_vias.il`、`cline2shape.il`。

### 5.4.2 标准菜单项构成

**规范 5.4.2-1**：标准交互命令的弹出菜单必须至少包含 "Done" 和 "Cancel" 两个选项。对于支持数据库修改且启用 `?undo t` 的命令，应当额外添加 "Oops" 选项，绑定到自定义的撤销回调函数。

> **依据**：来自 `cline2shape.il` 的完整菜单定义：
> ```skill
> popup = axlUIPopupDefine( nil (list
>   (list "Done" 'LCB_Done)
>   (list "Oop" 'LCB_Oops)
>   (list "Cancel" 'LCB_Cancel)
>    ))
> ```
> 来自 `axlswap_comp.il` 的自定义菜单：
> ```skill
> (setq swap_pop (axlUIPopupDefine userdata->popupId
> 		(list (list "Swap" '_swapCB))))
> (axlUIPopupSet swap_pop)
> ```

**规范 5.4.2-2**：弹出菜单的自定义回调（如 Swap、Oops）应当单独定义为独立函数，禁止在 `axlUIPopupDefine` 中直接写内联 lambda 或表达式，以保证代码可读性和可维护性。

> **依据**：来自 `axlswap_comp.il`：
> ```skill
> (defun _swapCB ()
>     (cond
>         ((lessp (axlGetSelSetCount) 2)
>             (printf "Must select two components before swapping"))
>         (t (_do_swap (axlGetSelSet)))))
> ```
> 以及 `cline2shape.il`：
> ```skill
> procedure(LCB_Oops()
>   when(LCB_mark
>     if(! axlDBTransactionOops(LCB_mark) then
>       axlUIWPrint(nil "-- Nothing Left To oops. --")
>     else
>       axlUIWPrint(nil "-- Replacing Clines. --")
>     )
>   )
>   axlClearSelSet())
> ```

### 5.4.3 捕捉增强菜单

**规范 5.4.3-1**：需要捕捉辅助功能的命令，可在弹出菜单激活后调用 `axlSnapEnableAtRMB()`，将 Snap 子菜单附加到右键弹出菜单中。该调用必须在 `axlUIPopupSet()` 之后进行。

> **依据**：来自 `cline2shape.il`：
> ```skill
> axlUIPopupSet(popup)
> axlSnapEnableAtRMB()
> ```
> 注释明确说明："Snapping is not required by this command but this shows the ability to add the snap sub-menu to the Right Mouse Popup menu"。

---

## 5.5 数据库事务与撤销/重做

### 5.5.1 事务生命周期

**规范 5.5.1-1**：涉及数据库修改的交互命令，应当在命令主循环外部（或每次独立操作前）通过 `axlDBTransactionStart()` 开启事务。命令正常结束时通过 `axlDBTransactionCommit()` 提交，命令取消时通过 `axlDBTransactionRollback()` 回滚。

> **依据**：来自 `cline2shape.il` 的两种撤销风格：
> **风格一（单次撤销）**：
> ```skill
> procedure(LCB_cline_to_shape()
> let( (lclines layer polydbid )
>   LCB_Setup()
>   LCB_mark = axlDBTransactionStart()  ;; 命令开始时开启事务
>   LCBnotDone = t
>   while( LCBnotDone
>       ...
>       when(LCB_mark axlDBTransactionMark(LCB_mark))  ;; 每次操作打标记
>   )
>   LCB_Done() ; just in case
> ))
> ```
> **风格二（逐次撤销）**：
> ```skill
> when(lclines 
>     LCB_mark = axlDBTransactionStart(doMark)  ;; 每次有工作时开启事务
> )
> ...
> when(LCB_mark axlDBTransactionCommit(LCB_mark))  ;; 每次操作后提交
> LCB_mark = nil
> ```

**规范 5.5.1-2**：事务标记变量（如 `LCB_mark`）应当在命令初始化阶段（`LCB_Setup`）重置为 `nil`，确保命令重新进入时事务状态干净。

> **依据**：来自 `cline2shape.il`：
> ```skill
> procedure(LCB_Setup()
> let( (popup)
>   ...
>   axlUIPopupSet(popup)
>   LCB_mark = nil  ;; 重置事务标记
> ))
> ```

### 5.5.2 Oops 回调实现

**规范 5.5.2-1**：支持 Oops 的交互命令，其 "Oops" 回调应当调用 `axlDBTransactionOops()` 执行回滚，并通过返回值判断是否存在可撤销的操作。若无可撤销内容，应当向用户输出提示信息。

> **依据**：来自 `cline2shape.il`：
> ```skill
> procedure(LCB_Oops()
>   when(LCB_mark
>     if(! axlDBTransactionOops(LCB_mark) then
>       axlUIWPrint(nil "-- Nothing Left To oops. --")
>     else
>       axlUIWPrint(nil "-- Replacing Clines. --")
>     )
>   )
>   axlClearSelSet()
> )
> ```

### 5.5.3 性能优化（Cloak）

**规范 5.5.3-1**：批量数据库操作（如遍历大量对象修改属性）应当使用 `axlDBCloak()` 包裹执行，以屏蔽中间刷新和 DRC 检查，提升执行性能。Cloak 内部仍应遵循正常的事务管理。

> **依据**：来自 `change_net_on_vias.il`：
> ```skill
> axlDBCloak('_RPVdoNetReplacement( vias net ) 'shape)
> ```
> 注释明确说明："Cloak improves performance when multiple vias are involved"。

---

## 5.6 动态光标（Dynamics）

### 5.6.1 动态元素清理

**规范 5.6.1-1**：在加载自定义动态光标元素前，必须调用 `axlClearDynamics()` 清除所有已存在的动态元素，避免前序命令的动态图形残留导致视觉混淆。

> **依据**：来自 `demo_dynamics.il`：
> ```skill
> (defun RBandDemo ( t_rbandType)
>     axlClearDynamics()
>     ...
> ```

### 5.6.2 动态元素加载

**规范 5.6.2-1**：动态光标元素应当通过 `axlAddSimpleMoveDynamics()`（移动型）或 `axlAddSimpleRbandDynamics()`（橡皮筋型）加载。调用时必须指定正确的参考点 `?ref_point` 或原点 `?origin`，以及变点 `?var_point`，确保动态图形跟随光标正确变换。

> **依据**：来自 `demo_dynamics.il`：
> ```skill
> ;; 加载移动型动态元素（焊盘图形）
> axlAddSimpleMoveDynamics(0:0 mypath "path" ?ref_point 0:0)
> 
> ;; 加载橡皮筋型动态元素（连线预览）
> axlAddSimpleRbandDynamics(0:0 t_rbandType
>         ?origin 9100:4500 ?var_point 300:0)
> ```

---

## 5.7 菜单注册（Menu Registration）

### 5.7.1 菜单插入与编辑

**规范 5.7.1-1**：通过 `axlUIMenuInsert()` 或 `axlUIMenuRegister()` 注册菜单时，菜单项列表应当使用 `'` 前缀的列表字面量定义，保持结构清晰。禁止在注册调用中直接写冗长的嵌套列表，应提前将菜单结构绑定到变量。

> **依据**：来自 `menu.il`：
> ```skill
> menuList = '(
>      (popup "MenuBar")
> 	("hello" "echo hello")
> 	(popup "Pull") 
> 	   ("hello1" "echo hello1") 
> 	   ("hello2" "echo hello2")
> 	   (popup "Pull 2") 
> 	      ("hello3" "echo hello3") 
> 	   (end)
> 	end
> 	(separator)
> 	("hello4" "echo hello4")
>      )
> 
> res = axlUIMenuRegister("reports" menuList 'bottom)
> ```

**规范 5.7.1-2**：菜单项的命令字符串中若需要嵌入双引号，必须使用 SKILL 字符串转义语法 `"`（反斜杠 + 双引号）。

> **依据**：来自 `menu.il`：
> ```skill
> ;; 在字符串中嵌入双引号，需使用转义
> z = axlUIMenuInsert(q "Google" "http \"http://google.com\"")
> ```

**规范 5.7.1-3**：菜单插入应当使用 `axlUIMenuFind()` 定位锚点位置，并明确指定插入方向（`'top` 或 `'bottom`）。禁止在不定位锚点的情况下直接插入菜单，避免菜单结构错乱。

> **依据**：来自 `menu.il`：
> ```skill
> ;; 在 add rect 之前插入分隔线
> q = axlUIMenuFind( nil "add rect")
> z = axlUIMenuInsert(q 'separator )
> 
> ;; 在 add 菜单底部插入新命令
> q = axlUIMenuFind(nil 3 'bottom)
> z = axlUIMenuInsert(q "add hello" "echo hello add" )
> 
> ;; 在 Help 菜单顶部插入外部链接
> q = axlUIMenuFind( nil -1 'top)
> z = axlUIMenuInsert(q "Google" "http \"http://google.com\"")
> ```

### 5.7.2 菜单触发器（Trigger）

**规范 5.7.2-1**：若需要在 Allegro 启动时自动加载自定义菜单，应当通过 `axlTriggerSet('menu 'menuTrig2)` 注册菜单触发器，而非在文件加载时直接执行菜单注册函数。这可以避免菜单在 Allegro 完全初始化前被错误插入。

> **依据**：来自 `menu.il` 的注释说明：
> ```skill
> ;; 以下两行演示通过菜单触发器在 Allegro 启动后加载菜单
> ;; 仅在 allegro.ilinit 中加载此文件时有效
> ;axlTriggerSet('menu  'menuTrig2)
> ```
> 以及直接调用的对比：
> ```skill
> ; To see axlUIMenuRegister uncomment the following line
> ;menuTrig1()  ;; 直接调用，仅在 load 时生效
> ```

---

## 5.8 表单与事件循环（Form & Event Loop）

### 5.8.1 表单单例控制

**规范 5.8.1-1**：采用表单作为交互界面的命令，应当通过全局变量检查防止表单多实例打开。若表单已存在，应当将其置前（`axlUIWExpose`）而非重复创建。

> **依据**：来自 `cns-design.il`：
> ```skill
> unless(boundp('_AcDesignFw) _AcDesignFw = nil)
> 
> procedure( AcnsDesignForm()
>     prog( (fw position)
>     fw = _AcDesignFw
>     when( fw 
>         axlUIWExpose(fw) 
>         return(t)
>     )
>     ...
>     fw = axlFormCreate('_AcDesignFw "acns_design" position '_AcDesignCB t nil )
>     ...
> ```

### 5.8.2 事件循环处理

**规范 5.8.2-1**：表单驱动的交互命令（非画布选择型）若需要与 Allegro 主命令循环协同，应当使用 `axlEnterEvent()` 建立事件循环，监听 `DONE` 和 `CANCEL` 事件，并在收到事件后正确关闭表单和结束交互状态。

> **依据**：来自 `cns-design.il`：
> ```skill
> procedure( _AcDesignEvent()
>     (let (event loop )
>     loop = t
>     while( loop
>         event = axlEnterEvent('(PICK) "" nil)
>         caseq(event->type
>         (DONE
>                 _AcDesignDone(_AcDesignFw)
>                 loop = nil)
>         (CANCEL
>                 _AcDesignCancel(_AcDesignFw)
>                 loop = nil)
>         )
>     )
> ))
> ```
> 注释说明："Autodone will always send in a done so check if done or cancel form should be called to save overhead of drc checking"。

### 5.8.3 表单回调与命令结束

**规范 5.8.3-1**：表单回调（`case`/`caseq` 处理 `curField`）中的 "done" 和 "cancel" 分支，应当在完成数据处理后调用 `axlFinishEnterFun()` 或 `axlCancelEnterFun()`，确保 Allegro 交互状态正确释放。

> **依据**：来自 `cns-design.il`：
> ```skill
> procedure( _AcDesignCB(fw)
>     case(fw->curField
>     ("done"
>         _AcDesignDone(fw)
>         axlFinishEnterFun()
>     )
>     ("cancel"
>         _AcDesignCancel(fw)
>         axlCancelEnterFun()
>     )
>     ...
> ))
> ```

---

## 5.9 进度条（Meter）

### 5.9.1 Meter 创建

**规范 5.9.1-1**：需要长时间执行的批量操作，应当使用 `axlMeterCreate()` 创建进度条界面，向用户反馈执行进度。`axlMeterCreate` 支持通过自定义表单文件扩展界面，并可绑定回调函数处理用户中断请求。

> **依据**：来自 `ashmeter.il`：
> ```skill
> axlCmdRegister("metertest" 'ash_meterform)
> 
> procedure(ash_meterform()
>   let( (meterfile)
>    meterfile = "ashmeter"
>    axlMeterCreate("Test Meter Form" "Info1 line" t meterfile "" '_ashMeterCallback )
> ))
> 
> procedure(_ashMeterCallback(mhandle)
>   let( ()
>     (case mhandle->curField
>     ("info"
>         axlMsgPut("-- User selected the Info button.")
>     )
>     )
> ))
> ```

---

## 5.10 示例代码汇总

以下为各官方示例文件在命令注册与交互模式方面的核心代码片段，供参考比对：

### 5.10.1 简单交互命令（`show_element.il`）

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/show_element.il

defun( ShowElement ()
   mypopup = axlUIPopupDefine(nil, list(list("Done" 'axlFinishEnterFun)
list("Cancel" 'axlCancelEnterFun)))
   axlUIPopupSet(mypopup)
   axlSetFindFilter(?enabled, '("NOALL", "ALLTYPES", "NAMEFORM")
?onButtons "ALLTYPES")
   while(axlSelect(), axlShowObject(axlGetSelSet()))
)

axlCmdRegister("myshow" 'ShowElement ?cmdType "interactive")
```

### 5.10.2 带数据浏览的交互命令（`change_net_on_vias.il`）

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/change_net_on_vias.il

axlCmdRegister("change_vianet" `rplc_netvia)

procedure( rplc_netvia()
  (let ( mypopup vias net )
    
    axlClearSelSet()
    axlSetFindFilter(?enabled `("NOALL" "VIAS")
			     ?onButtons `("VIAS"))
   
    mypopup = axlUIPopupDefine( nil
                 (list (list "Done" 'axlFinishEnterFun)
                 (list "Cancel" 'axlCancelEnterFun)))
    axlUIPopupSet( mypopup)

    axlSelect(?prompt "Select vias by pick or window.");
    
    vias = axlGetSelSet()
    when(vias
       net = cadr(axlUIDataBrowse('NET '(RETRIEVE_OBJECT) "New Net Name" t))
	when(net
	    axlDBCloak('_RPVdoNetReplacement( vias net ) 'shape)
	)
    )
    
    axlClearSelSet()
    axlFinishEnterFun()
    t
))
```

### 5.10.3 完整交互命令含事务与撤销（`cline2shape.il`）

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/cline2shape.il

axlCmdRegister("cline2shape" 'LCB_cline_to_shape ?cmdType "interactive"
 ?doneCmd 'LCB_Done ?cancelCmd 'LCB_Cancel ?undo t)

procedure(LCB_cline_to_shape()
let( (lclines layer polydbid )
  LCB_Setup()
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
     when(LCB_mark axlDBTransactionMark(LCB_mark))
  )
  LCB_Done()
))

procedure(LCB_Setup()
let( (popup)
  axlSetFindFilter(?enabled list("noall" "clines") 
                  ?onButtons list("noall" "clines"))
  popup = axlUIPopupDefine( nil (list
    (list "Done" 'LCB_Done)
    (list "Oop" 'LCB_Oops)
    (list "Cancel" 'LCB_Cancel)
     ))
  axlSnapEnableAtRMB()
  axlUIPopupSet(popup)
  LCB_mark = nil
))

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

procedure(LCB_Cancel()
  axlUIWPrint(nil "** Cancelled Program. **")
  when( LCB_mark axlDBTransactionRollback(LCB_mark))
  LCB_mark = nil
  LCBnotDone = nil
  axlClearSelSet()
  axlCancelEnterFun()
)

procedure(LCB_Done()
  when( LCB_mark axlDBTransactionCommit(LCB_mark))
  LCB_mark = nil
  LCBnotDone = nil
  axlCancelEnterFun()
)
```

### 5.10.4 选择集循环与多对象处理（`axlswap_comp.il`）

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/axlswap_comp.il

(defun axlSwapComponent ()
    (axlClearSelSet)
    (axlSetFindFilter ?enabled `("NOALL" "NAMEFORM" "SYMBOLS") 
		      ?onButtons `("SYMBOLS"))
    (axlOpenFindFilter)
    (let ((prevSelSet nil))
        (_build_popup)
        (while (axlSelect ?multiDisable t)
            (cond
		((null prevSelSet)
		    nil)
		((greaterp (length prevSelSet) 1)
		    (_do_swap prevSelSet))
		(t
		    (axlAddSelectObject prevSelSet)))
            (setq prevSelSet (axlGetSelSet)))
        (axlCloseFindFilter)
	(axlClearSelSet)))

(defun _build_popup ()
    (let (user_data swap_pop)
    	(setq userdata (axlUIGetUserData))
	(setq swap_pop (axlUIPopupDefine userdata->popupId
			(list (list "Swap" '_swapCB))))
	(axlUIPopupSet swap_pop)
    )
)

(defun _swapCB ()
    (cond
	((lessp (axlGetSelSetCount) 2)
	    (printf "Must select two components before swapping"))
	(t (_do_swap (axlGetSelSet))))
)
```

### 5.10.5 基本 Enter Point 命令（`entertest.il`）

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/enter/entertest.il

(defun enterTest ()
    (axlEnterPoint))

(defun enterTestDone ()
    (axlFinishEnterFun)
    (axlEnterPoint))

(defun enterTestCancel ()
    (axlCancelEnterFun))

(axlCmdRegister "entertest" 'enterTest ?cmdType "interactive"
					  ?doneCmd 'enterTestDone
					  ?cancelCmd 'enterTestCancel)
```

### 5.10.6 动态光标演示（`demo_dynamics.il`）

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/enter/demo_dynamics.il

(defun RBandDemo ( t_rbandType)
    axlClearDynamics()
    mypath = axlPathStart(list( -350:0))
    axlPathArcCenter(mypath, 0., -350:0, nil, -300:0)
    axlAddSimpleMoveDynamics(0:0 mypath "path" ?ref_point 0:0)
    mypath = axlPathStart(list( 350:0))
    axlPathArcCenter(mypath, 0., 350:0, nil, 300:0)
    axlAddSimpleMoveDynamics(0:0 mypath "path" ?ref_point 0:0)
    mypath = axlPathStart(
            list( -200:-100 200:-100 200:100 -200:100 -200:-100))
    axlAddSimpleMoveDynamics(0:0 mypath "path" ?ref_point 0:0)
    axlAddSimpleRbandDynamics(0:0 t_rbandType
            ?origin 9100:4500 ?var_point 300:0)
)
```

### 5.10.7 菜单注册（`menu.il`）

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/ui/menu.il

menuList = '(
     (popup "MenuBar")
	("hello" "echo hello")
	(popup "Pull") 
	   ("hello1" "echo hello1") 
	   ("hello2" "echo hello2")
	   (popup "Pull 2") 
	      ("hello3" "echo hello3") 
	   (end)
	end
	(separator)
	("hello4" "echo hello4")
     )

procedure( menuTrig1()
    res = axlUIMenuRegister("reports" menuList 'bottom)
    res = axlUIMenuRegister(-1 ml2)
)

procedure( menuTrig2(t_menufile)
    let( (q)
    printf("MENU FILE= %s\n" t_menufile)
    q = axlUIMenuFind(nil -1)
    res = axlUIMenuInsert(q menuList)
))

;; 通过触发器在 Allegro 启动时加载
;axlTriggerSet('menu  'menuTrig2)
```

### 5.10.8 表单与事件循环（`cns-design.il`）

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/cns-design.il

unless(boundp('_AcDesignFw) _AcDesignFw = nil)

procedure( AcnsDesignForm()
    prog( (fw position)
    fw = _AcDesignFw
    when( fw 
        axlUIWExpose(fw) 
        return(t)
    )
    position = '("NE" "msglines" 1)
    fw = axlFormCreate('_AcDesignFw "acns_design" position '_AcDesignCB t nil )
    axlFormDisplay(fw)
    _AcDesignEvent()
    )
)

procedure( _AcDesignEvent()
    (let (event loop )
    loop = t
    while( loop
        event = axlEnterEvent('(PICK) "" nil)
        caseq(event->type
        (DONE
                _AcDesignDone(_AcDesignFw)
                loop = nil)
        (CANCEL
                _AcDesignCancel(_AcDesignFw)
                loop = nil)
        )
    )
))

procedure( _AcDesignCB(fw)
    case(fw->curField
    ("done"
	_AcDesignDone(fw)
	axlFinishEnterFun()
    )
    ("cancel"
	_AcDesignCancel(fw)
	axlCancelEnterFun()
    )
    ...
))
```

### 5.10.9 Meter 与回调（`ashmeter.il`）

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/ui/ashmeter.il

axlCmdRegister("metertest" 'ash_meterform)

procedure(ash_meterform()
  let( (meterfile)
   meterfile = "ashmeter"
   axlMeterCreate("Test Meter Form" "Info1 line" t meterfile "" '_ashMeterCallback )
))

procedure(_ashMeterCallback(mhandle)
  let( ()
    (case mhandle->curField
    ("info"
        axlMsgPut("-- User selected the Info button.")
    )
    )
))
```

---

## 5.11 附录：命令注册与交互模式速查表

| 规范编号 | 核心要点 | 关键 API |
|---------|---------|---------|
| 5.2.1-1 | 函数名使用 `'` 或 `` ` `` 前缀 | `axlCmdRegister` |
| 5.2.1-2 | 交互命令必须指定 `?cmdType "interactive"` | `axlCmdRegister` |
| 5.2.3-1 | 修改数据库的命令必须启用 `?undo t` | `axlCmdRegister` |
| 5.2.2-1 | 注册 `?doneCmd` / `?cancelCmd` | `axlCmdRegister` |
| 5.3.1-1 | 入口首先调用 `axlClearSelSet()` | `axlClearSelSet` |
| 5.3.2-1 | 显式设置 `?enabled` 和 `?onButtons` | `axlSetFindFilter` |
| 5.3.3-1 | `axlSelect` 提供 `?prompt` 提示 | `axlSelect` |
| 5.3.4-1 | 判断选择集非空后再处理 | `axlGetSelSet` + `when` |
| 5.4.1-1 | 定义并激活弹出菜单 | `axlUIPopupDefine` + `axlUIPopupSet` |
| 5.4.2-1 | 菜单至少包含 Done/Cancel，可选 Oops | `axlUIPopupDefine` |
| 5.5.1-1 | 事务 Start/Commit/Rollback 生命周期 | `axlDBTransactionStart` 等 |
| 5.5.2-1 | Oops 回调调用 `axlDBTransactionOops` | `axlDBTransactionOops` |
| 5.5.3-1 | 批量操作使用 `axlDBCloak` 提升性能 | `axlDBCloak` |
| 5.6.1-1 | 动态光标前调用 `axlClearDynamics` | `axlClearDynamics` |
| 5.7.1-1 | 菜单结构使用 `'` 列表字面量 | `axlUIMenuRegister` |
| 5.8.2-1 | 表单命令使用 `axlEnterEvent` 监听事件 | `axlEnterEvent` |
| 5.9.1-1 | 长操作使用 `axlMeterCreate` 显示进度 | `axlMeterCreate` |
| 总体原则 | 中文注释使用 GBK 编码保存 | 文件编码 |

---

> **文件编码声明**：本规范文件（`style_section_命令注册与交互模式.md`）中引用的官方示例代码片段保留了原始文件中的英文注释。若开发者基于本规范编写包含中文注释（如选择提示、菜单标签、状态消息）的 SKILL 源文件，**必须将 `.il` 文件以 GBK 编码保存**，以确保 Allegro PCB Editor 正确加载和显示中文内容。UTF-8 编码将导致中文乱码。

> **示例文件路径**：本章节所有示例代码均来自 `D:/Cadence/SPB_17.4/share/pcb/examples/skill/` 下的官方示例文件，路径已在各代码块顶部标注。引用时请核对本地安装路径是否一致。
