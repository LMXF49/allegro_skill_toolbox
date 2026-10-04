# Allegro SKILL (AXL) 代码规范 — 数据库操作与事务撤销

> 本章节规范基于 Cadence SPB 17.4 官方示例代码提炼，适用于 Allegro PCB Editor SKILL (AXL) 数据库编程场景。
> 文件保存编码：**GBK**，以支持中文注释。

---

## 一、总体原则

**规范 1.1** 【必须】所有涉及数据库修改（Create / Delete / Update）的代码，必须置于 `let` 局部绑定或 `procedure` 程序体内，禁止在顶层作用域直接调用数据库操作函数。

> 来源依据：来自 `axldbctshp.il`（第 37 行）、`axl_delete.il`（第 32 行）、`cline2shape.il`（第 42 行）的写法，所有数据库操作均封装在 `let` 或 `procedure` 中。

```skill
;; 正确写法（来自 axldbctshp.il）
(defun dbc_shp_t1 ()
    (let (shape)
        (axlMsgPut "**Starting dbc_shp_t1")
        (setq shape (axlDBCreateOpenShape
            (axlPathStart (list 3:5.5 3:6.5 3.5:6.7 4:6.5 4:5.5 3:5.5))
                                nil "BOARD GEOMETRY/DIMENSION"))
        (setq shape (car (axlDBCreateCloseShape shape)))))

;; 禁止：在文件顶层直接调用
;; (axlDBCreateVia "via" 2.0:7.0)  ; 错误！
```

**规范 1.2** 【必须】数据库操作函数的返回值必须显式处理；创建类函数返回 `dbid` 或 `nil`，调用方必须检查其有效性后再进行后续操作。

> 来源依据：来自 `axldbctvia.il` 的 `dbc_via_print` 辅助函数（第 35–38 行），以及 `cline2shape.il` 中使用 `unless` 检查创建结果（第 59–61 行）。

```skill
;; 正确写法（来自 cline2shape.il）
unless( axlDBCreateShape(car(polydbid) t layer)  
    axlUIWPrint(nil "ERROR: Failed to create Shape from Cline.")
)
```

**规范 1.3** 【应当】数据库操作相关的临时变量命名应当具有语义，形状相关使用 `shape`/`path`，事务标记使用 `mark`/`LCB_mark`，避免单字母或无意义命名。

> 来源依据：来自 `axldbctshp.il`（`shape`、`aVoid`）、`cline2shape.il`（`LCB_mark`、`polydbid`）、`axl_delete.il`（`clineList`）的命名习惯。

---

## 二、数据库创建操作

**规范 2.1** 【必须】使用 `axlDBCreate*` 系列函数创建对象时，必须按官方文档顺序提供参数；对于可选参数，若使用关键字参数（`?param` 语法）则必须显式指定关键字。

> 来源依据：来自 `axldbctpin.il`（第 43–49 行）使用 `make_axlPinText` 关键字参数，以及 `axldbctshp.il` 使用 `make_axlFill` 关键字参数（第 68–71 行）。

```skill
;; 正确写法（来自 axldbctpin.il）
(axlDBCreatePin "pad60sq36d" 0:600
    (make_axlPinText ?number "1FFE" ?offset -100:0
        ?text (make_axlTextOrientation ?textBlock "2"
            ?rotation 90 ?mirrored t ?justify "right")))
```

**规范 2.2** 【应当】创建复杂对象（如 Pin、Shape）时，建议先构造辅助结构（`make_axlPinText`、`make_axlTextOrientation`、`make_axlFill`），再传入创建函数，避免嵌套过深。

> 来源依据：来自 `axldbctpin.il`（第 43–46 行）和 `axldbctshp.il`（第 67–71 行）的写法。

```skill
;; 正确写法（来自 axldbctshp.il）
(setq shape (axlDBCreateOpenShape
    (axlPathStart (list 4:4.5 4:6 5:6.2 6:6 6:4.5 4:4.5))
                        t "ETCH/TOP" "GND"))
```

**规范 2.3** 【必须】创建对象后如需获取其 `dbid`，必须使用 `car` 提取返回值列表的首元素；禁止假设返回值为单个 `dbid`。

> 来源依据：来自 `axldbctvia.il`（第 42–43 行）、`axldbctshp.il`（第 43 行、第 57 行）的写法。

```skill
;; 正确写法（来自 axldbctshp.il）
(setq shape (car (axlDBCreateCloseShape shape)))
;; 正确写法（来自 axldbctvia.il）
(dbc_via_print
    (axlDBCreateVia "via" 2.0:7.0))
```

**规范 2.4** 【禁止】禁止将非法类型的数据（如非字符串的 padstack 名、非 `r_path` 的路径）直接传入 `axlDBCreate*` 函数；若需测试边界条件，必须在外层包裹 `errset`。

> 来源依据：来自 `axldbctvia.il`（第 114 行）使用 `errset` 捕获异常，以及 `axldbctshp.il`（第 146–147 行）展示非法参数的处理方式。

```skill
;; 正确写法（来自 axldbctvia.il）
(errset (axlDBCreateVia 777 1.0:5.0) t)
```

---

## 三、数据库读取操作

**规范 3.1** 【必须】使用 `axlDBGetDesign` 获取设计对象后，若需长期持有该 `dbid`，应当在关键操作前调用 `axlDBRefreshId` 刷新，避免因数据库变更导致 `dbid` 失效。

> 来源依据：来自 `read.il`（第 67、69 行）的写法。

```skill
;; 正确写法（来自 read.il）
(setq x (axlDBGetDesign))
; test the refresh function
(axlDBRefreshId x)
```

**规范 3.2** 【应当】遍历设计对象（如 `symdefs`、`padstacks`、`nets`）时，使用 `foreach` 循环，并在 `let` 绑定中声明循环变量，避免污染全局命名空间。

> 来源依据：来自 `read.il`（第 98–118 行）遍历 `symdefs` 和 `padstacks` 的写法。

```skill
;; 正确写法（来自 read.il）
(defun test_design (p)
    (let ((dsn (axlDBGetDesign))
          (branches (axlDBGetLonelyBranches))
          padstack pad symdef)
        (print_title "Design:" p)
        (my_print dsn->?? p)
        (print_title "Symbol Definitions:" p)
        (foreach symdef dsn->symdefs
            (print_title "symdef:" p)
            (my_print symdef->?? p)
        ) ; foreach symdef
        (print_title "Padstacks:" p)
        (foreach padstack dsn->padstacks
            (print_title "padstack:" p)
            (my_print padstack->?? p)
            (print_title "Pads:" p)
            (foreach pad padstack->pads
                (print_title "pad:" p)
                (ash_print_pad pad p)
            ) ; foreach pad
        ) ; foreach padstack
    ) ; let
) ; defun test_design
```

**规范 3.3** 【应当】使用 `->?` 和 `->??` 获取对象属性时，应当在调试或日志输出中使用，禁止在生产逻辑中依赖 `->??` 的完整列表进行硬编码判断。

> 来源依据：来自 `read.il`（第 80–82 行）和 `pads.il`（第 72–74 行）使用 `->??` 和 `->?` 进行属性打印的写法。

```skill
;; 正确写法（来自 read.il）
; test the singlequestion attr retrieval
(my_print x->? p)
; test illegal attr retrieval
(my_print x->dummy p)
```

**规范 3.4** 【必须】使用 `axlDBGetPad` 获取焊盘信息时，必须同时指定层名（如 `"ETCH/TOP"`）和类型（如 `"REGULAR"`），禁止省略参数。

> 来源依据：来自 `pads.il`（第 70、82 行）的写法。

```skill
;; 正确写法（来自 pads.il）
(setq x (axlDBGetPad y "ETCH/TOP" "REGULAR"))
(setq z (axlDBGetPad y "ETCH/BOTTOM" "ANTI"))
```

---

## 四、数据库删除操作

**规范 4.1** 【必须】调用 `axlDeleteObject` 前，必须确认待删除对象已关闭（对于 Shape）且不具有只读属性（如 `FIXED` 属性），否则删除将失败。

> 来源依据：来自 `axl_delete.il`（第 117–137 行）中对 Shape 删除顺序和状态的测试说明。

```skill
;; 正确写法（来自 axl_delete.il）
;; Delete a void from an open shape.  Should work.
(defun deleteOpenShapeVoid (shape)
   (deleteAndPrint shape->voids "Open Shape Voids"))

;; Delete a void from an non-open shape.  Delete should report error.
(defun deleteShapeVoids (shape)
   (null (deleteAndPrint shape->voids "Closed Shape Voids")))
```

**规范 4.2** 【应当】批量删除对象时，建议先将对象收集到列表中，再统一调用 `axlDeleteObject`，避免在循环中反复调用导致性能下降或 `dbid` 失效。

> 来源依据：来自 `axl_delete.il`（第 55–73 行）`mergeClines` 和 `deleteClines` 函数中先构建列表再批量删除的写法。

```skill
;; 正确写法（来自 axl_delete.il）
(defun deleteClines ()
    (let (clineList testPass)
        (setq clineList (cons (_makeCline 6.4:2.6 8.4:2.6) nil))
        (setq clineList (cons (_makeCline 2.4:2.6 4.4:2.6) clineList))
        (setq clineList (cons (_makeCline 4.4:2.6 6.4:2.6) clineList))
        (deleteAndPrint clineList "Clines")
        testPass))
```

**规范 4.3** 【禁止】禁止直接删除 Allegro 系统生成的 DRC 错误对象；仅允许删除由 AXL 通过 `axlDBCreateExternalDRC` 创建的外部 DRC。

> 来源依据：来自 `axl_delete.il`（第 186–193 行）的 `deleteAllegroDRC` 与 `deleteExternalDRC` 对比测试。

```skill
;; 正确写法（来自 axl_delete.il）
;; delete of DRC that was added by AXL - OK
(defun deleteExternalDRC ()
   (let (drc_error)
        (setq drc_error 
              (car (axlDBCreateExternalDRC "myconstraint" 2.0:2.0 "drc/all")))
        (deleteAndPrint (list drc_error) "AXL defined DRCs")
        t))

;; delete of DRC that was added by Allegro Constraints - should fail
(defun deleteAllegroDRC ()
    (let (drcs)
        (setq drcs (ashFindAllDrcs))
        (deleteAndPrint drcs "Allegro defined DRCs")
        t))
```

---

## 五、事务与撤销（Undo / Redo / Oops）

**规范 5.1** 【必须】实现交互式命令的数据库事务支持时，必须在命令入口调用 `axlDBTransactionStart` 启动事务，在命令完成时调用 `axlDBTransactionCommit` 提交，在取消时调用 `axlDBTransactionRollback` 回滚。

> 来源依据：来自 `cline2shape.il`（第 47、70、160、170 行）的事务管理写法。

```skill
;; 正确写法（来自 cline2shape.il）
procedure(LCB_cline_to_shape()
let( (lclines layer polydbid )
  LCB_Setup()
  LCB_mark = axlDBTransactionStart()
  LCBnotDone = t
  while( LCBnotDone
      ;; ... 数据库操作 ...
      when(LCB_mark axlDBTransactionMark(LCB_mark))
  )
  LCB_Done() ; just in case
))

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

**规范 5.2** 【必须】若需要支持逐操作撤销（Oops），必须将 `axlDBTransactionStart` 的标记参数设为 `'undoMark`，并在每次操作后调用 `axlDBTransactionCommit`；若需要整命令撤销，则使用默认标记并在循环中调用 `axlDBTransactionMark`。

> 来源依据：来自 `cline2shape.il`（第 36–73 行，整命令撤销）与第 81–123 行（逐操作撤销）的两种实现对比。

```skill
;; 方式一：整命令撤销（来自 cline2shape.il）
LCB_mark = axlDBTransactionStart()
while( LCBnotDone
    ;; ... 每次转换 ...
    when(LCB_mark axlDBTransactionMark(LCB_mark))
)

;; 方式二：逐操作撤销（来自 cline2shape.il）
doMark = 'undoMark
while(LCBnotDone
    when(lclines 
        LCB_mark = axlDBTransactionStart(doMark)
    )
    ;; ... 数据库操作 ...
    when(LCB_mark axlDBTransactionCommit(LCB_mark))
    LCB_mark = nil
)
```

**规范 5.3** 【必须】`axlDBTransactionOops` 调用前必须检查事务标记 `LCB_mark` 是否为非 `nil`，且必须处理其返回值（`nil` 表示无操作可撤销）。

> 来源依据：来自 `cline2shape.il`（第 148–157 行）的 `LCB_Oops` 函数。

```skill
;; 正确写法（来自 cline2shape.il）
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

**规范 5.4** 【禁止】禁止在事务未提交或回滚前，直接退出命令函数或调用 `axlCancelEnterFun` 而不清理事务状态。

> 来源依据：来自 `cline2shape.il`（第 159–166 行、第 169–174 行）中 `LCB_Cancel` 和 `LCB_Done` 均显式处理 `LCB_mark` 的写法。

```skill
;; 正确写法（来自 cline2shape.il）
procedure(LCB_Cancel()
  axlUIWPrint(nil "** Cancelled Program. **")
  when( LCB_mark axlDBTransactionRollback(LCB_mark))  ; 必须回滚！
  LCB_mark = nil
  LCBnotDone = nil
  axlClearSelSet()
  axlCancelEnterFun()
)
```

---

## 六、形状（Shape）与路径（Path）操作

**规范 6.1** 【必须】使用 `axlDBCreateOpenShape` 创建形状后，必须配对调用 `axlDBCreateCloseShape` 关闭形状；禁止在形状未关闭时对其进行依赖闭合状态的操作。

> 来源依据：来自 `axldbctshp.il`（第 40–50 行）和 `axl_delete.il`（第 105–112 行）的 Open/Close 配对写法。

```skill
;; 正确写法（来自 axldbctshp.il）
(defun dbc_shp_t1 ()
    (let (shape)
        (setq shape (axlDBCreateOpenShape
            (axlPathStart (list 3:5.5 3:6.5 3.5:6.7 4:6.5 4:5.5 3:5.5))
                                nil "BOARD GEOMETRY/DIMENSION"))
        (setq shape (car (axlDBCreateCloseShape shape)))))

;; 正确写法（来自 axl_delete.il）
(defun addShapeOutline ()
    (let (path)
        (setq path (axlPathStart (list 1:1)))
        (axlPathLine path 0 1:8)
        (axlPathLine path 0 5:4)
        (axlPathArcCenter path 0 5:1 t 5:2.5)
        (axlPathLine path 0 1:1)
        (axlDBCreateOpenShape path t "ETCH/TOP" nil)))

(defun closeTestShape (shape)
    (axlDBCreateCloseShape shape))
```

**规范 6.2** 【应当】向已创建的形状添加 void 时，应当在形状仍处于 Open 状态时调用 `axlDBCreateVoid` 或 `axlDBCreateVoidCircle`，且 void 路径必须闭合。

> 来源依据：来自 `axldbctshp.il`（第 65–78 行）和 `axl_delete.il`（第 96–103 行）的写法。

```skill
;; 正确写法（来自 axldbctshp.il）
(setq shape (axlDBCreateOpenShape
    (axlPathStart (list 4:1.5 4:4 6:4 6:1.5 4:1.5))
                (list
                    (make_axlFill ?origin 0:0
                        ?angle 45.0 ?width .01 ?spacing .05)
                    (make_axlFill ?origin 0:0
                        ?angle 135.0 ?width .01 ?spacing .05))
                "ETCH/TOP" "GND"))
(axlDBCreateVoid shape
    (axlPathStart (list 5:2 5.2:2.2 5.4:2 5.2:1.8 5:2) 0.01))
(axlDBCreateVoidCircle shape (list 4.2:3.8 0.5) .01)
(axlDBCreateCloseShape shape)
```

**规范 6.3** 【禁止】禁止对已关闭（Closed）的形状添加 void；若需修改已关闭形状，必须先调用 `axlDBOpenShape` 重新打开。

> 来源依据：来自 `axldbctshp.il`（第 432–462 行）的 `dbc_shp_t10` 函数演示了重新打开 shape 并添加 void 的流程。

```skill
;; 正确写法（来自 axldbctshp.il）
(defun dbc_shp_t10 ()
    (let (shape aVoid)
        shape = axlDBCreateOpenShape(
            axlPathStart( list(4000:1000 4000:4000 5000:4500 6000:4000 
                    6000:1000 4000:1000))
                    t "ETCH/TOP" "GND")
        ; 添加 void 后关闭
        aVoid = axlDBCreateVoid(shape
            axlPathStart( list(4050:1050 4050:1150 5000:1150 5000:1050 4050:1050 )))
        axlDBCreateCloseShape(shape)

        ; 重新打开 shape 并添加 void
        axlDBOpenShape(shape)
        axlDBCreateVoidCircle(nil list( 5000:3000 100))
        axlDBCreateVoidCircle(shape list( 5000:3300 100))
        axlDBCreateCloseShape(shape)
        shape))
```

**规范 6.4** 【应当】构造路径（`r_path`）时，应当使用 `axlPathStart` 初始化，然后使用 `axlPathLine`、`axlPathArcCenter` 等函数逐步添加线段，避免直接构造复杂列表。

> 来源依据：来自 `axldbctpath.il`（第 48–74 行）和 `axl_delete.il`（第 87–93 行）的写法。

```skill
;; 正确写法（来自 axldbctpath.il）
(defun dbc_path_t2 ()
    (axlMsgPut "**Starting dbc_path_t2")
    (dbc_path_print
        (axlDBCreatePath 
            (axlPathLine 
                (axlPathLine 
                    (axlPathLine 
                        (axlPathArcCenter 
                            (axlPathArcCenter 
                                (axlPathArcCenter 
                                    (axlPathStart (list 6.4:4.7))
                                    .012 6.7:4.5 t 6.4:4.375)
                                .02 7.025:4.3 nil 7.001:4.625)
                            .012 7.2:4.137 t 7.037:4.137)
                        nil 7.2:3.7)
                    .020 7.4:3.5)
                .012 7.4:3.0)
            "ETCH/TOP")))
```

---

## 七、属性（Property）操作

**规范 7.1** 【应当】使用 `axlDBAddProp` 为对象添加属性时，属性应当以 `list` 形式传入，格式为 `(list "property_name" "property_value")`。

> 来源依据：来自 `axldbctshp.il`（第 125–127 行）的写法。

```skill
;; 正确写法（来自 axldbctshp.il）
(axlDBAddProp shape (list "signal_model" "signal_model_value"))
(axlDBCreateText "Attached Text\nAnd a second line" 7:4.5 "3"
        "BOARD GEOMETRY/DIMENSION" shape)
```

**规范 7.2** 【应当】读取属性字典（Property Dictionary）时，应当使用 `axlDBGetPropDictEntry` 获取定义信息，并检查 `->dataType` 以确认属性类型。

> 来源依据：来自 `props.il`（第 105–108 行、第 182–183 行）的写法。

```skill
;; 正确写法（来自 props.il）
(foreach item dict_list
    (setq dict (axlDBGetPropDictEntry item))
    (pprint dict->? p)
    (pprint dict->?? p)
    (pprint dict->dataType p)
)
```

---

## 八、错误处理与边界条件

**规范 8.1** 【必须】数据库操作函数若可能因参数错误引发运行时异常，必须在外层使用 `errset` 包裹，或在调用后检查返回值。

> 来源依据：来自 `axldbctvia.il`（第 114 行）使用 `errset` 捕获类型错误参数。

```skill
;; 正确写法（来自 axldbctvia.il）
(defun dbc_via_te_args2 ()
    (axlMsgPut "**Starting dbc_via_te_args2")
    ;; padstack not a string - caught by Skill
    (errset (axlDBCreateVia 777 1.0:5.0) t))
```

**规范 8.2** 【应当】在调试或测试代码中，使用 `axlMsgPut` 输出阶段信息，使用 `sprintf` 格式化输出复杂数据结构，便于追踪数据库操作状态。

> 来源依据：来自 `axl_delete.il`（第 38–51 行）的 `deleteAndPrint` 辅助函数，以及 `read.il`（第 34 行）的 `print_title` 函数。

```skill
;; 正确写法（来自 axl_delete.il）
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

**规范 8.3** 【禁止】禁止在数据库操作期间调用 `axlShell` 执行可能触发大规模数据库变更的 `replay` 脚本，除非该脚本已通过充分测试，且在操作后重新验证数据库状态。

> 来源依据：来自 `axl_delete.il`（第 163–171 行）中 `addFixedProp` 使用 `axlShell` 的写法，该示例仅为测试固定属性场景，非生产推荐做法。

```skill
;; 来自 axl_delete.il（测试专用，非生产推荐）
(defun addFixedProp (shape)
    (axlFlushDisplay)
    (axlMsgPut "Adding FIXED Prop To Shape")
    (axlFlushDisplay)
    (axlShell (sprintf nil 
                       "replay %s/scripts/prop_on" (axlGetVariable "TEST_DIR")))
    t)
```

---

## 九、示例代码汇总

以下汇总本节规范所引用的官方示例文件及其核心代码片段，供查阅对照。

### 9.1 事务撤销完整示例（`cline2shape.il`）

> 文件路径：`/d/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/cline2shape.il`

```skill
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
  LCB_Done() ; just in case
))

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

### 9.2 数据库创建与读取示例（`axldbctshp.il` + `read.il`）

> 文件路径：`/d/Cadence/SPB_17.4/share/pcb/examples/skill/dbcreate/axldbctshp.il`
> 文件路径：`/d/Cadence/SPB_17.4/share/pcb/examples/skill/dbread/read.il`

```skill
;; 创建 Shape（Open/Close 模式）
(defun dbc_shp_t1 ()
    (let (shape)
        (axlMsgPut "**Starting dbc_shp_t1")
        (setq shape (axlDBCreateOpenShape
            (axlPathStart (list 3:5.5 3:6.5 3.5:6.7 4:6.5 4:5.5 3:5.5))
                                nil "BOARD GEOMETRY/DIMENSION"))
        (setq shape (car (axlDBCreateCloseShape shape)))))

;; 读取 Design 属性
(defun test_design (p)
    (let ((dsn (axlDBGetDesign))
          padstack pad symdef)
        (print_title "Design:" p)
        (my_print dsn->?? p)
        (foreach symdef dsn->symdefs
            (print_title "symdef:" p)
            (my_print symdef->?? p)
        ) ; foreach symdef
        (print_title "Padstacks:" p)
        (foreach padstack dsn->padstacks
            (print_title "padstack:" p)
            (my_print padstack->?? p)
            (print_title "Pads:" p)
            (foreach pad padstack->pads
                (print_title "pad:" p)
                (ash_print_pad pad p)
            ) ; foreach pad
        ) ; foreach padstack
    ) ; let
) ; defun test_design
```

### 9.3 删除操作与 DRC 区分示例（`axl_delete.il`）

> 文件路径：`/d/Cadence/SPB_17.4/share/pcb/examples/skill/edit/axl_delete.il`

```skill
;; 删除 Allegro 系统 DRC（应失败）
(defun deleteAllegroDRC ()
    (let (drcs)
        (closeTestShape (openTestShape))
        (closeTestShape (openTestShape))
        (setq drcs (ashFindAllDrcs))
        (deleteAndPrint drcs "Allegro defined DRCs")
        (axlDeleteObject (ashFindAllShapes))
        t))

;; 删除 AXL 外部 DRC（应成功）
(defun deleteExternalDRC ()
   (let (drc_error)
        (setq drc_error 
              (car (axlDBCreateExternalDRC "myconstraint" 2.0:2.0 "drc/all")))
        (deleteAndPrint (list drc_error) "AXL defined DRCs")
        t))

;; 批量删除 Clines
(defun deleteClines ()
    (let (clineList testPass)
        (setq clineList (cons (_makeCline 6.4:2.6 8.4:2.6) nil))
        (setq clineList (cons (_makeCline 2.4:2.6 4.4:2.6) clineList))
        (setq clineList (cons (_makeCline 4.4:2.6 6.4:2.6) clineList))
        (deleteAndPrint clineList "Clines")
        testPass))
```

### 9.4 属性与 Pad 读取示例（`pads.il` + `props.il`）

> 文件路径：`/d/Cadence/SPB_17.4/share/pcb/examples/skill/dbread/pads.il`
> 文件路径：`/d/Cadence/SPB_17.4/share/pcb/examples/skill/dbread/props.il`

```skill
;; 读取 Pad 信息
(defun general_test (file)
    (setq y (car (ashFindAllPins)))
    (setq x (axlDBGetPad y "ETCH/TOP" "REGULAR"))
    (setq z (axlDBGetPad y "ETCH/BOTTOM" "ANTI"))
    (fprintf file "Eq x z?: ")
    (pprint (eq x z) file)
    (fprintf file "\n"))

;; 读取 Property Dictionary
(defun dict_test (p)
    (fprintf p "Dict Test:\n\n")
    (pprint dict_list p)
    (foreach item dict_list
        (setq dict (axlDBGetPropDictEntry item))
        (pprint dict->? p)
        (pprint dict->?? p)
        (fprintf p "\n\n")
    ) ; foreach
) ; dict_test
```

---

## 十、文件保存规范

**规范 10.1** 【必须】包含中文注释的 `.il` 文件必须使用 **GBK 编码**保存，以确保 Allegro SKILL 解释器在中文 Windows 环境下正确解析注释内容，避免乱码。

> 来源依据：Allegro SKILL 开发实践（Cadence SPB 17.4/24.1 在中文 Windows 环境下的字符集适配）。

```
;; 示例：GBK 编码的中文注释
;; 本函数用于创建测试用 via，并返回其 dbid
(defun dbc_via_t1 ()
    ...)
```

---

*本章节规范由官方示例代码提炼而成，适用于 Cadence SPB 17.4 及兼容版本的 Allegro SKILL (AXL) 开发。*
