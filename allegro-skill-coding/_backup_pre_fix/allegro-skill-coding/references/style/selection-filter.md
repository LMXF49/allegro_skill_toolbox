# 选择集与过滤器（Selection Set & Find Filter）

> 本章规范基于 Cadence SPB 17.4 官方示例代码分析提炼，适用于 Allegro SKILL (AXL) 开发中所有涉及对象选择、查找过滤的交互式命令与自动化脚本。
> 
> **编码要求**：包含中文注释的 `.il` 文件应使用 **GBK 编码**保存，以确保 Allegro 中文环境正确加载。

---

## 1. 总体原则

### 1.1 选择集操作的原子性

**必须**在执行选择操作前，通过 `axlClearSelSet` 显式清空当前选择集，避免上一次命令或用户操作的残留对象干扰当前逻辑。

> 来自 `change_net_on_vias.il` 的写法：

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/change_net_on_vias.il
procedure( rplc_netvia()
  (let ( mypopup vias net )
    
    axlClearSelSet()
    axlSetFindFilter(?enabled `("NOALL" "VIAS")
                     ?onButtons `("VIAS"))
    
    ; ... 后续选择逻辑
```

> 来自 `axlswap_comp.il` 的写法：

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/axlswap_comp.il
(defun axlSwapComponent ()
    (axlClearSelSet)
    (axlSetFindFilter ?enabled `("NOALL" "NAMEFORM" "SYMBOLS") 
              ?onButtons `("SYMBOLS"))
    ; ...
```

### 1.2 过滤器设置的显式性

**应当**始终显式指定 `?enabled` 和 `?onButtons` 两个参数，禁止依赖 Allegro 的默认过滤器状态。`?enabled` 控制 Find 窗口中哪些对象类型可以被查找，`?onButtons` 控制哪些类型的按钮被按下（即实际可被选中的类型）。

> 来自 `ashfindall.il` 的写法：

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/select/ashfindall.il
(defun findAllOfType (findType "t")
    (let (selSet oldSetData)
        (setq oldSetData (_saveSelSet))
        (axlClearSelSet)
        (axlSetFindFilter ?enabled  (list "noall" findType "invisible") 
                          ?onButtons  (list "noall" findType))
        (axlAddSelectAll)
        (setq selSet (axlGetSelSet))
        (_restoreSelSet oldSetData)
        selSet))
```

> 来自 `cline2shape.il` 的写法：

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/cline2shape.il
procedure(LCB_Setup()
let( (popup)
  axlSetFindFilter(?enabled list("noall" "clines") 
                  ?onButtons list("noall" "clines"))
  ; ...
))
```

### 1.3 选择集状态的可恢复性

**应当**在需要临时修改 Find Filter 或选择集的场景中，实现保存与恢复机制，确保操作结束后将 Allegro 的交互状态还原至用户预期。

> 来自 `ashfindall.il` 的写法（选择集保存/恢复封装）：

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/select/ashfindall.il
(defun _saveSelSet ()
    (list (axlGetSelSet) (axlGetFindFilter nil) (axlGetFindFilter t)))

(defun _restoreSelSet (oldSelSet "l")
    (axlSetFindFilter ?enabled (cons "noall" (nth 1 oldSelSet))
                      ?onButtons (cons "noall" (nth 2 oldSelSet)))
    (axlSingleSelectObject (car oldSelSet))
    t)
```

---

## 2. Find Filter 设置规范

### 2.1 `?enabled` 参数格式

**必须**使用列表（`list`）形式传递 `?enabled` 参数，且首元素为 `"NOALL"`（或 `"noall"`，大小写不敏感但推荐大写）。后续元素按需要追加对象类型字符串。若需包含不可见对象，**应当**追加 `"invisible"`。

> 来自 `ashfindall.il` 的写法：

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/select/ashfindall.il
(axlSetFindFilter ?enabled  (list "noall" findType "invisible") 
                  ?onButtons  (list "noall" findType))
```

> 来自 `ashselect.il` 的写法：

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/select/ashselect.il
(axlSetFindFilter ?enabled '("NOALL" "ALLTYPES" "AUTOFORM" "NAMEFORM") 
                  ?onButtons "ALLTYPES")
```

### 2.2 `?onButtons` 参数格式

**必须**使用列表或字符串形式传递 `?onButtons` 参数。当仅启用单一类型时，可直接使用字符串；启用多类型时，**应当**使用列表以保证可读性和可扩展性。

> 来自 `show_element.il` 的写法（字符串简写）：

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/show_element.il
axlSetFindFilter(?enabled, '("NOALL", "ALLTYPES", "NAMEFORM")
                 ?onButtons "ALLTYPES")
```

> 来自 `tselall.il` 的写法（列表形式）：

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/select/tselall.il
(axlSetFindFilter ?onButtons (list "NOALL" findType))
```

> 来自 `axlswap_comp.il` 的写法（符号列表）：

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/axlswap_comp.il
(axlSetFindFilter ?enabled `("NOALL" "NAMEFORM" "SYMBOLS") 
                  ?onButtons `("SYMBOLS"))
```

### 2.3 大小写一致性

**推荐**在过滤器字符串中使用全大写（如 `"NOALL"`、`"ALLTYPES"`、`"VIAS"`），以与 Allegro 官方文档及示例保持一致。SKILL 字符串比较大小写不敏感，但统一大写有助于提高代码可读性。

---

## 3. 交互式选择模式

### 3.1 基础选择循环 `axlSelect`

**应当**在交互式命令的主循环中使用 `axlSelect` 作为用户输入入口，并在循环体内处理 `axlGetSelSet` 获取到的对象。当命令结束或用户取消时，**必须**调用 `axlFinishEnterFun` 或 `axlCancelEnterFun`。

> 来自 `show_element.il` 的写法：

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
```

> 来自 `axlswap_comp.il` 的写法（禁用多选弹窗）：

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
            (printf "%L\n" (axlGetSelSet))
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
```

### 3.2 `axlSelect` 的提示参数

**推荐**在 `axlSelect` 中使用 `?prompt` 参数向用户显示当前操作指令，提升交互体验。

> 来自 `cline2shape.il` 的写法：

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/cline2shape.il
while( LCBnotDone
    lclines = axlGetSelSet(axlSelect(?prompt "Select Clines to convert to a shape."))
    ; ...
)
```

> 来自 `change_net_on_vias.il` 的写法：

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/change_net_on_vias.il
axlSelect(?prompt "Select vias by pick or window.");
```

### 3.3 选择状态与 `doneState` 检查

**应当**在需要区分用户"完成"与"取消"操作的复杂交互中，检查 `axlUIGetUserData()->doneState` 的值，以执行不同的清理逻辑。

> 来自 `tselaxlselect.il` 的写法：

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/select/tselaxlselect.il
(while (null testDone)
    (cond
        ((axlSelect)
            (printf "tselaxlSelect: Found %L Objects\n" 
                    (axlGetSelSetCount))
            (mapc 'ashPrintObjData (axlGetSelSet)))

        ((eq (axlUIGetUserData)->doneState 'done)
            (printf "tselaxlSelect:  \"Done\" Aborted axlSelect\n"))

        ((eq (axlUIGetUserData)->doneState 'cancel)
            (printf "tselaxlSelect:  \"Cancel\" Aborted axlSelect\n")
            (setq testDone t))

        (t 
            (printf "tselaxlSelect:  Unknown axlSelect abort\n")
            (setq testPass nil)
            (setq testDone t))))
```

---

## 4. 按对象类型批量查找

### 4.1 使用 `axlAddSelectAll` 进行全图查找

**应当**使用 `axlAddSelectAll` 查找当前设计中符合 Find Filter 的全部对象，而非遍历数据库逐个比对。`axlAddSelectAll` 不会清空已选对象，因此执行前**必须**调用 `axlClearSelSet`。

> 来自 `ashfindall.il` 的写法：

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/select/ashfindall.il
(defun findAllOfType (findType "t")
    (let (selSet oldSetData)
        (setq oldSetData (_saveSelSet))
        (axlClearSelSet)
        (axlSetFindFilter ?enabled  (list "noall" findType "invisible") 
                          ?onButtons  (list "noall" findType))
        (axlAddSelectAll)
        (setq selSet (axlGetSelSet))
        (_restoreSelSet oldSetData)
        selSet))
```

> 来自 `tselall.il` 的写法：

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/select/tselall.il
(defun tselSelectAllOf (objTypeData)
    (let (testPass foundItems leftOver findType objTypeList)
        (setq findType (car objTypeData))
        (setq objTypeList (cadr objTypeData))

        (axlClearSelSet)
        (axlSetFindFilter ?onButtons (list "NOALL" findType))

        (cond
            ; select all of the type
            ((null (axlAddSelectAll))
                (printf "tselSelectAllOf: No \"%s\" to select\n" findType)
                nil)
            ((null (setq foundItems (axlGetSelSet)))
                (printf "tselSelectAllOf: (axlGetSelSet) failed\n")
                nil)
            ; ... 后续验证逻辑
```

### 4.2 按类型封装查找函数

**推荐**为常用对象类型（如 `PINS`、`VIAS`、`CLINES`、`SHAPES` 等）提供封装函数，使上层代码简洁且语义清晰。

> 来自 `ashfindall.il` 的写法：

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/select/ashfindall.il
(defun ashFindAllPins ()
    (findAllOfType "PINS"))

(defun ashFindAllVias ()
    (findAllOfType "VIAS"))

(defun ashFindAllClines ()
    (findAllOfType "CLINES"))

(defun ashFindAllShapes ()
    (findAllOfType "SHAPES"))

(defun ashFindAllComponents ()
    (findAllOfType "COMPONENTS"))

(defun ashFindAllNets ()
    (findAllOfType "NETS"))
```

---

## 5. 按 DBID 选择对象

### 5.1 `axlSingleSelectObject` / `axlAddSelectObject` / `axlSubSelectObject`

**应当**使用 `axlSingleSelectObject`、`axlAddSelectObject` 和 `axlSubSelectObject` 对已知 `dbid` 的对象进行精确选择操作，而非通过坐标交互选择。这些函数按 DBID 选择时，**不**受 `?enabled` 过滤器的限制（仅受 `?onButtons` 影响）。

> 来自 `tselobject.il` 的写法：

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/select/tselobject.il
; tselSubObject - Sub select an object and verify that it was deselected
(defun tselSubObject (item)
    (cond
        ((null (axlSubSelectObject item))
            (printf "tselSubObject: Failed to Deselect %L\n%L" 
                    item item->??)
            nil)
        ((member item (axlGetSelSet))
            (printf "tselSubObject: Item [%L] in Selset after Deselection\n"
                    item)
            nil)
        (t t)))

; tselSingleObject - Single select an object and verify that it is the only
;   object in selection set
(defun tselSingleObject (item)
    (let (count foundItem)
        (cond
            ((null (axlSingleSelectObject item))
                (printf "tselSingleObject: Failed to Select %L\n%L" 
                        item item->??)
                nil)
            ((nequal (setq count (axlGetSelSetCount)) 1)
                (printf "tselSingleObject: Select count [%d] != 1\n" count)
                nil)
            ((nequal item (setq foundItem (car (axlGetSelSet))))
                (printf "tselSingleObject: Selected Item [%L] != exp'd [%L]\n"
                        foundItem item)
                nil)
            (t t))))

; tselAddObject - Add Select an object an verify that count increased by 1
(defun tselAddObject (item)
    (let (count foundItem oldCount)
        (setq oldCount (axlGetSelSetCount))
        (cond
            ((null (axlAddSelectObject item))
                (printf "tselAddObject: Failed to Select %L\n%L" 
                        item item->??)
                nil)
            ((nequal (setq count (axlGetSelSetCount)) (plus oldCount 1))
                (printf "tselAddObject: Sel count [%d] != oldCount [%d] + 1\n" 
                        count oldCount)
                nil)
            (t t))))
```

### 5.2 DBID 选择前的过滤器清理

**应当**在按 DBID 选择前，将 `?onButtons` 设置为 `"ALL"` 或目标类型，确保选择操作不受过滤器按钮状态限制。按 DBID 选择时 `?enabled` 不影响结果，但 `?onButtons` 仍然有效。

> 来自 `tselobject.il` 的写法：

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/select/tselobject.il
(defun tselAllOfObjectDBID (findType)
    (let (testPass foundItems leftOver newItems)
        (axlClearSelSet)
        (axlSetFindFilter ?enabled (list "NOALL" findType)
                          ?onButtons "ALL")
        ; ...

        ; clear onButtons because they should not affect select by dbid
        ((null (axlSetFindFilter ?onButtons "NOALL"))
            (printf "tselAllOfObjectDBID: Failed to clear onButtons\n")
            nil)

        ; sub select individual items of a type by DBID
        ((null (apply 'and (mapcar 'tselSubObject foundItems)))
            ; ...
```

### 5.3 对无效 DBID 的防御性检查

**必须**在使用 `axlAddSelectObject` 等函数时，确保传入的参数为有效的 `dbid` 对象或列表。传入 `nil`、非 `dbid` 类型的符号或嵌套列表将导致不可预期的行为或警告。

> 来自 `tselobject.il` 的写法（Bad DBID 测试）：

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/select/tselobject.il
(defun tselBadDBIDTest ()
    (axlClearSelSet)
    (printf "Select with Bad DBID's should Result in Warnings\n")

    (cond
        ; Test that we do not get a selection with nil list
        ((axlSingleSelectObject nil)
            (printf "tselBadDBIDTest: Got Selection from Nil Object List\n")
            nil)

        ; Test that we do not get a selection with nil in list
        ((axlAddSelectObject '(nil))
            (printf "tselBadDBIDTest: Got Selection from Nil Object in List\n")
            nil)

        ; Test that we do not get a selection with a symbol in list
        ((axlAddSelectObject '(5))
            (printf "tselBadDBIDTest: Got Selection from 5 in List\n")
            nil)

        ; Test that we do not get a selection with list in list
        ((axlAddSelectObject '((junk)))
            (printf "tselBadDBIDTest: Got Selection from List in List\n")
            nil)

        ; Make sure that we can select the design
        ((axlAddSelectObject (axlDBGetDesign))
            (printf "tselBadDBIDTest: Selected the Design\n")
            nil)

        ((axlGetSelSet)
            (printf "tselBadDBIDTest: Ended with Selections\n")
            nil)
        (t t)))
```

---

## 6. 区域选择（Area Selection）

### 6.1 点选与框选的区别

**应当**根据交互需求选择恰当的选择函数：
- 单选点：`axlSingleSelectPoint`
- 加点：`axlAddSelectPoint`
- 减点：`axlSubSelectPoint`
- 单选框：`axlSingleSelectBox`
- 加框：`axlAddSelectBox`
- 减框：`axlSubSelectBox`

> 来自 `tselarea.il` 的写法：

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/select/tselarea.il
(defun tselAreaTestType (objTypeData)
    (let (testPass findType objTypeList)
        (setq findType (car objTypeData))
        (setq objTypeList (cadr objTypeData))

        (axlClearSelSet)
        (axlSetFindFilter ?onButtons (list "NOALL" findType))

        (cond
            ((null (tselSingleSelectPoint objTypeData))
                nil)
            ((null (tselAddSelectPoint objTypeData))
                nil)
            ((null (tselSubSelectPoint objTypeData))
                nil)
            ((null (tselSingleSelectBox objTypeData))
                nil)
            ((null (tselAddSelectBox objTypeData))
                nil)
            ((null (tselSubSelectBox objTypeData))
                nil)
            (t (setq testPass t)))
        testPass))
```

### 6.2 区域选择前的 Find Filter 管理

**应当**在区域选择测试或批量操作前，使用 `axlOpenFindFilter` 打开 Find 过滤器对话框，使用户可见当前过滤器状态；操作完成后**必须**使用 `axlCloseFindFilter` 关闭，并配合 `axlClearSelSet` 清理选择集。

> 来自 `tselarea.il` 的写法：

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/select/tselarea.il
(defun tselAreaSelect ()
    (let (testPass)
        (axlSetFindFilter ?enabled '("NOALL" "ALLTYPES") ?onButtons "NOALL")
        (axlOpenFindFilter)

        (cond
            ((null (apply 'and (mapcar 'tselAreaTestType 
                                       (tselGetObjectTypeData))))
                nil)
            (t (setq testPass t)))

        (axlCloseFindFilter)
        (axlClearSelSet)
        (tselEchoResults "Selset Interactive Area Test" testPass)))
```

---

## 7. 选择集数量与状态验证

### 7.1 使用 `axlGetSelSetCount` 验证选择结果

**应当**在获取选择集后，使用 `axlGetSelSetCount` 验证选择数量是否符合预期，而非仅依赖 `axlGetSelSet` 返回的列表非空判断。

> 来自 `tselarea.il` 的写法（单选点验证数量严格等于 1）：

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/select/tselarea.il
(defun tselSingleSelectPoint (objTypeData)
    (let ((testPass t) count selSet)
        (axlClearSelSet)
        (printf "\"%s\" Single Select Point Interactive Test" (car objTypeData))

        (while (axlSingleSelectPoint)
            (cond
                ((neq (setq count (axlGetSelSetCount)) 1)
                    (printf "tselSingleSelectPoint: Select count [%d]  != 1\n"
                            count)
                    (setq testPass nil))
                ((null (setq selSet (axlGetSelSet)))
                    (printf "tselSingleSelectPoint: Nil Sel Set\n")
                    (setq testPass nil))
                ((null (tselTestObjType "tselSingleSelectPoint"
                                        selSet
                                        objTypeData))
                    (setq testPass nil))
                (t t))

            (mapc 'ashPrintObjData (axlGetSelSet)))

        testPass))
```

> 来自 `tselarea.il` 的写法（加点验证数量递增）：

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/select/tselarea.il
(defun tselAddSelectPoint (objTypeData)
   (let ((testPass t) count (oldCount 0) selSet)
        (axlClearSelSet)
        
        (printf "\"%s\" Add Select Point Interactive Test" (car objTypeData))

        (while (axlAddSelectPoint)
            (when (neq (setq count (axlGetSelSetCount)) (plus oldCount 1))
                (printf "tselAddSelectPoint: count [%d] != oldCount [%d] + 1\n"
                        count oldCount)
                (setq testPass nil))
            (setq oldCount count))
            
        ; ...
        testPass))
```

### 7.2 减选后验证选择集为空

**应当**在执行减选操作后，验证 `axlGetSelSet` 返回 `nil` 且 `axlGetSelSetCount` 返回 `0`，确保目标对象确实已从选择集中移除。

> 来自 `tselarea.il` 的写法（减点验证）：

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/select/tselarea.il
(defun tselSubSelectPoint (objTypeData)
   (let ((testPass t) count (oldCount (axlGetSelSetCount)) selSet)
        
        (printf "\"%s\" Sub Select Point Interactive Test" (car objTypeData))

        (while (axlSubSelectPoint)
            (when (neq oldCount (plus (setq count (axlGetSelSetCount)) 1))
                (printf "tselSubSelectPoint: count [%d] != oldCount [%d] - 1\n"
                        count oldCount)
                (setq testPass nil))
            (setq oldCount count))
            
        (cond
            ((setq selSet (axlGetSelSet))
                (printf "tselSubSelectPoint: Selection Set Not Nil\n")
                (mapc 'ashPrintObjData selSet)
                (setq testPass nil))
            ((neq (setq count (axlGetSelSetCount)) 0)
                (printf "tselSubSelectPoint: Sel Set Count [%d] != 0\n" count)))

        testPass))
```

---

## 8. Find Filter 的开启与关闭

### 8.1 `axlOpenFindFilter` / `axlCloseFindFilter` 的使用场景

**应当**在需要用户实时查看或修改 Find Filter 的交互式命令中，调用 `axlOpenFindFilter` 在命令开始时打开过滤器窗口，并在命令结束或取消时调用 `axlCloseFindFilter` 关闭。不需要用户交互的自动化脚本中，**禁止**打开 Find Filter 窗口。

> 来自 `axlswap_comp.il` 的写法：

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/axlswap_comp.il
(defun axlSwapComponent ()
    (axlClearSelSet)
    (axlSetFindFilter ?enabled `("NOALL" "NAMEFORM" "SYMBOLS") 
                      ?onButtons `("SYMBOLS"))
    (axlOpenFindFilter)

    (let ((prevSelSet nil))
        ; ... 交互循环 ...
        (axlCloseFindFilter)
        (axlClearSelSet)))
```

> 来自 `tselarea.il` 的写法：

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/select/tselarea.il
(defun tselAreaSelect ()
    (let (testPass)
        (axlSetFindFilter ?enabled '("NOALL" "ALLTYPES") ?onButtons "NOALL")
        (axlOpenFindFilter)

        ; ... 测试逻辑 ...

        (axlCloseFindFilter)
        (axlClearSelSet)
        (tselEchoResults "Selset Interactive Area Test" testPass)))
```

---

## 9. 选择集获取与遍历

### 9.1 `axlGetSelSet` 的返回值处理

**应当**将 `axlGetSelSet` 的返回值绑定到局部变量，再执行遍历或批量操作。当选择集为空时，函数返回 `nil`，**必须**对此进行空值检查以避免 `foreach` 报错。

> 来自 `change_net_on_vias.il` 的写法：

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/change_net_on_vias.il
axlSelect(?prompt "Select vias by pick or window.");

vias = axlGetSelSet()
when(vias
    ; 仅在用户选择了 vias 时执行后续逻辑
    net = cadr(axlUIDataBrowse('NET '(RETRIEVE_OBJECT) "New Net Name" t))
    when(net
        axlDBCloak('_RPVdoNetReplacement( vias net ) 'shape)
    )
)
```

> 来自 `cline2shape.il` 的写法：

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/cline2shape.il
while( LCBnotDone
    lclines = axlGetSelSet(axlSelect(?prompt "Select Clines to convert to a shape."))

    foreach( clinedbid lclines
        layer = clinedbid->layer
        polydbid = axlPolyFromDB(clinedbid ?endCapType "ROUND")
        axlDeleteObject(clinedbid)
        ; ...
    )
    ; ...
)
```

### 9.2 大数据量选择集的分批处理

**推荐**当选择集可能超过 20 个对象时，对 `axlGetSelSet` 返回的列表进行截断或分批处理，避免单次操作消耗过多内存或导致 Allegro 响应缓慢。

> 来自 `tselobject.il` 的写法：

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/select/tselobject.il
(defun _tselTruncateList (inputList curCount)
    (cond
        ((or (null inputList) (greaterp curCount 20))
            nil)
        (t
            (cons (car inputList) (_tselTruncateList (cdr inputList) 
                                                      (plus curCount 1))))))

(defun tselGetSelectedObjects ()
    (let (foundItems (itemCount 0))
        (when (and (setq foundItems (axlGetSelSet)) 
                   (greaterp (axlGetSelSetCount) 20))
            (setq foundItems (_tselTruncateList foundItems 1))
            (axlSingleSelectObject foundItems))
        foundItems))
```

---

## 10. 选择集与回调函数（Popup）

### 10.1 选择命令的右键菜单设置

**应当**在交互式选择命令中，通过 `axlUIPopupDefine` 和 `axlUIPopupSet` 设置右键菜单，提供 "Done"、"Cancel"、"Oops" 等标准操作选项，使用户可通过右键结束命令。

> 来自 `show_element.il` 的写法：

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
```

> 来自 `axlswap_comp.il` 的写法（自定义 Swap 回调）：

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/axlswap_comp.il
(defun _build_popup ()
    (let (user_data swap_pop)
        (setq userdata (axlUIGetUserData))
        (setq swap_pop (axlUIPopupDefine userdata->popupId
                (list (list "Swap" '_swapCB))))
        (axlUIPopupSet swap_pop)
    )
)
```

> 来自 `cline2shape.il` 的写法（含 Oops 的完整菜单）：

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/cline2shape.il
procedure(LCB_Setup()
let( (popup)
  axlSetFindFilter(?enabled list("noall" "clines") 
                  ?onButtons list("noall" "clines"))

  popup = axlUIPopupDefine( nil (list
    (list "Done" 'LCB_Done)
    (list "Oop" 'LCB_Oops)
    (list "Cancel" 'LCB_Cancel)
     ))

  ; Snapping is not required by this command but this shows the ability
  ; to add the snap sub-menu to the Right Mouse Popup menu
  axlSnapEnableAtRMB()

  axlUIPopupSet(popup)
  LCB_mark = nil
))
```

---

## 11. 选择集与数据库事务

### 11.1 选择集操作与事务撤销的分离

**应当**明确区分选择集操作（UI 层面）与数据库事务（数据层面）。选择集操作本身不产生数据库变更，因此**不需要**包裹在事务中。但由选择驱动的数据库修改（如删除、创建、修改属性）**必须**使用 `axlDBTransactionStart`/`axlDBTransactionCommit`/`axlDBTransactionRollback` 管理。

> 来自 `cline2shape.il` 的写法（选择集独立于事务）：

```skill
; D:/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/cline2shape.il
procedure(LCB_cline_to_shape()
let( (lclines layer polydbid )

  LCB_Setup()

  ; 事务标记用于数据库变更的撤销，而非选择集
  LCB_mark = axlDBTransactionStart()

  LCBnotDone = t
  while( LCBnotDone
      ; 选择集操作独立于事务
      lclines = axlGetSelSet(axlSelect(?prompt "Select Clines to convert to a shape."))

      foreach( clinedbid lclines
            layer = clinedbid->layer
            polydbid = axlPolyFromDB(clinedbid ?endCapType "ROUND")
            axlDeleteObject(clinedbid)  ; 数据库变更，受事务保护

            unless( axlDBCreateShape(car(polydbid) t layer)  
                axlUIWPrint(nil "ERROR: Failed to create Shape from Cline.")
            )
            when( cadr(polydbid) 
                axlDBCreateShape(cadr(polydbid) t layer) 
            )
     )

     when(LCB_mark axlDBTransactionMark(LCB_mark))
  )
  LCB_Done() ; just in case
))
```

---

## 12. 示例代码汇总

### 12.1 典型交互式选择命令模板

```skill
; 典型交互式选择命令模板
; 适用于：需要用户交互选择对象后执行批量操作的命令

procedure( MyInteractiveCommand ()
    let( (popup selectedObjects)
        
        ; 1. 清空选择集，防止残留
        axlClearSelSet()
        
        ; 2. 设置 Find Filter
        axlSetFindFilter(?enabled '("NOALL" "TARGET_TYPE") 
                          ?onButtons '("TARGET_TYPE"))
        
        ; 3. 设置右键菜单（可选，推荐）
        popup = axlUIPopupDefine( nil 
            (list
                (list "Done" 'MyDoneFunc)
                (list "Cancel" 'MyCancelFunc)
            ))
        axlUIPopupSet(popup)
        
        ; 4. 打开 Find Filter 窗口（可选，视交互需求）
        axlOpenFindFilter()
        
        ; 5. 选择循环
        while( axlSelect(?prompt "Select target objects:") )
            selectedObjects = axlGetSelSet()
            
            when( selectedObjects
                ; 6. 处理选中的对象
                foreach( obj selectedObjects
                    ; ... 对 obj 执行操作 ...
                )
            )
        
        ; 7. 清理：关闭 Find Filter、清空选择集
        axlCloseFindFilter()
        axlClearSelSet()
        axlFinishEnterFun()
        t
    )
)

axlCmdRegister("mycommand" 'MyInteractiveCommand ?cmdType "interactive")
```

### 12.2 批量查找指定类型对象模板

```skill
; 批量查找指定类型对象模板
; 适用于：自动化脚本中查找全部符合类型的对象

(defun findAllOfType (findType "t")
    let( (selSet oldSetData)
        ; 保存当前选择集和过滤器状态
        (setq oldSetData 
              (list (axlGetSelSet) 
                    (axlGetFindFilter nil) 
                    (axlGetFindFilter t)))
        
        ; 清空选择集并设置过滤器
        (axlClearSelSet)
        (axlSetFindFilter ?enabled  (list "NOALL" findType "invisible") 
                          ?onButtons  (list "NOALL" findType))
        
        ; 全选该类型的所有对象
        (axlAddSelectAll)
        (setq selSet (axlGetSelSet))
        
        ; 恢复原始状态
        (axlSetFindFilter ?enabled (cons "NOALL" (nth 1 oldSetData))
                          ?onButtons (cons "NOALL" (nth 2 oldSetData)))
        (axlSingleSelectObject (car oldSetData))
        
        selSet))

; 使用示例
(defun findAllVias ()
    (findAllOfType "VIAS"))

(defun findAllShapes ()
    (findAllOfType "SHAPES"))
```

### 12.3 按 DBID 精确选择模板

```skill
; 按 DBID 精确选择模板
; 适用于：已知对象 dbid，需要将其加入/移出选择集

(defun selectObjectsByDbid (dbidList "l")
    let( (count)
        (axlClearSelSet)
        
        ; 设置过滤器允许所有类型（按 DBID 选择时 enabled 不影响结果）
        (axlSetFindFilter ?onButtons "ALL")
        
        ; 验证并选择
        (when( dbidList
            (setq count (axlGetSelSetCount))
            
            ; 逐条加入选择集
            foreach( item dbidList
                when( item  ; 防御 nil dbid
                    (axlAddSelectObject item)
                )
            )
            
            ; 验证结果
            (when( nequal (axlGetSelSetCount) 
                         (plus count (length dbidList)) )
                (printf "Warning: Not all objects were selected\n")
            )
        )
        
        (axlGetSelSet)
    ))
```

---

## 附录：相关示例文件索引

| 文件路径 | 涉及规范点 |
|---------|----------|
| `D:/Cadence/SPB_17.4/share/pcb/examples/skill/select/ashfindall.il` | 选择集保存/恢复、批量查找、过滤器设置 |
| `D:/Cadence/SPB_17.4/share/pcb/examples/skill/select/ashselect.il` | 交互选择循环、Popup 菜单、回调函数 |
| `D:/Cadence/SPB_17.4/share/pcb/examples/skill/select/tselall.il` | `axlAddSelectAll` / `axlSubSelectAll`、全选验证 |
| `D:/Cadence/SPB_17.4/share/pcb/examples/skill/select/tselarea.il` | 区域选择（点选/框选）、数量验证、Find Filter 开关 |
| `D:/Cadence/SPB_17.4/share/pcb/examples/skill/select/tselaxlselect.il` | `axlSelect` 状态检查、`doneState` 处理 |
| `D:/Cadence/SPB_17.4/share/pcb/examples/skill/select/tselobject.il` | DBID 选择、无效 DBID 防御、大数据量截断 |
| `D:/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/show_element.il` | 简洁交互选择、基础 Find Filter 设置 |
| `D:/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/change_net_on_vias.il` | 选择集与后续操作、数据浏览器联动 |
| `D:/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/axlswap_comp.il` | 多选禁用、Find Filter 窗口、自定义 Popup |
| `D:/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/cline2shape.il` | 选择集与事务分离、Undo 支持、提示参数 |
| `D:/Cadence/SPB_17.4/share/pcb/examples/skill/edit/axl_delete.il` | 调用 `ashFindAll` 系列函数进行批量查找 |
| `D:/Cadence/SPB_17.4/share/pcb/examples/skill/enter/entertest.il` | 命令注册与 Enter 函数基础（非选择集核心） |

---

*本章规范基于 Cadence SPB 17.4 官方 SKILL 示例代码分析编写，示例代码路径以 `D:/Cadence/SPB_17.4/share/pcb/examples/skill/` 为基准。实际项目中请根据具体 Allegro 版本与业务需求调整。包含中文注释的文件应使用 **GBK 编码**保存。*
