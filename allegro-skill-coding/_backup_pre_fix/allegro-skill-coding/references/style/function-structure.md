# Allegro SKILL (AXL) 代码规范 — 函数与程序结构

> 基于 Cadence SPB 17.4 官方示例代码提炼，适用于 Allegro PCB Editor SKILL (AXL) 开发。
> 文件应使用 **GBK 编码**保存，以确保中文注释在 Allegro 环境中正确显示。

---

## 1. 总体原则

### 1.1 函数职责单一

每个函数应当只完成一个明确的任务。复杂操作应当拆分为多个小函数，通过组合实现整体功能。

```skill
;; 来自 axl_delete.il 的写法：
;; 将 "创建测试线段"、"删除并打印"、"合并测试" 拆分为独立函数

(defun _makeCline (p1 p2)
    (let (cline)
        (setq cline 
              (axlDBCreatePath (axlPathStart (list p1 p2) .012)
                               "ETCH/TOP" nil))
        (car (car cline))))

(defun deleteAndPrint (items message)
    (let (result)
        (unless (listp items) (setq items (list items)))
        (axlFlushDisplay)
        (axlMsgPut (sprintf nil "Deleting %L" message))
        (setq result (axlDeleteObject items))
        (mapc 'ashPrintObjData items)
        result))

(defun mergeClines ()
    (let (clineList testPass)
        (setq clineList (cons (_makeCline 6.4:2.6 8.4:2.6) nil))
        (setq clineList (cons (_makeCline 2.4:2.6 4.4:2.6) clineList))
        (setq clineList (cons (_makeCline 4.4:2.6 6.4:2.6) clineList))
        (mapc 'ashPrintObjData clineList)
        (foreach cline clineList
            (when cline->objType (axlDeleteObject cline)))
        testPass))
```

> 来源依据：`axl_delete.il` 将创建线段、删除操作、打印输出分别封装，职责边界清晰。

---

### 1.2 函数长度控制

函数体应当保持简洁。若函数超过 50 行，应当考虑拆分为辅助函数。过长的函数会降低可读性和可维护性。

```skill
;; 来自 read.il 的写法：
;; 每个 test_xxx 函数长度控制在 10~20 行，通过组合完成完整测试

(defun test_general (p)
    (let (x y)
        (setq x (axlDBGetDesign))
        (axlDBRefreshId x)
        (fprintf p "Is design dbid? %s\n" (axlIsDBIDType x))
        (fprintf p "Eval of x: %s\n" (eval x))
        (setq y (car x->symdefs))
        (fprintf p "Eq x y?: %s\n" (cond ((equal x y) ("t")) ("nil")))
        (my_print x->? p)
        (my_print x->dummy p)
    ) ; let
) ; defun test_general
```

> 来源依据：`read.il` 中 20 余个测试函数各自独立，每个函数不超过 20 行。

---

## 2. 函数定义与命名

### 2.1 优先使用 `defun` 定义函数

`defun` 是 Allegro SKILL 中定义函数的标准形式。除非需要提前 `return`，否则应当使用 `defun`。

```skill
;; 来自 read.il 的写法：
(defun print_title (string port)
    (fprintf port "\n\n%s\n\n" string)
) ; defun print_title

;; 来自 axldbctvia.il 的写法：
(defun dbc_via_t1 ()
    (axlMsgPut "**Starting dbc_via_t1")
    (dbc_via_print
        (axlDBCreateVia "via" 2.0:7.0)))
```

> 来源依据：`read.il`、`axldbctvia.il`、`axl_delete.il` 等大量示例均以 `defun` 作为首选定义方式。

---

### 2.2 需要提前 `return` 时使用 `procedure` + `prog`

当函数需要在中间位置提前退出并返回特定值时，应当使用 `procedure` 配合 `prog` 语句块，利用 `prog` 的 `return` 能力实现流程控制。

```skill
;; 来自 cns-design.il 的写法：
procedure( AcnsDesignForm()
    prog( (fw position)  ; prog 支持 return

    ;; 若表单已打开，则直接显示并返回
    fw = _AcDesignFw
    when( fw 
        axlUIWExpose(fw) 
        return(t)
    )

    position = '("CENTER")
    position = '("NE" "msglines" 1)
    fw = axlFormCreate('_AcDesignFw "acns_design" position '_AcDesignCB t nil )

    _AcDesignTier(fw)
    _AcDesignRefresh(fw)
    axlFormDisplay(fw)
    _AcDesignEvent()
    )
)
```

> 来源依据：`cns-design.il` 的 `AcnsDesignForm()` 在表单已打开时直接 `return(t)` 退出。

---

### 2.3 私有函数必须以 `_`（下划线）前缀命名

仅供内部调用的辅助函数、回调函数和实现细节函数，必须在名称前加 `_` 前缀，与公开 API 区分。命令回调函数（如 Done、Cancel）也适用此规则。

```skill
;; 来自 axlswap_comp.il 的写法：
(defun _build_popup ()        ; 私有：构建右键菜单
(defun _swapCB ()             ; 私有：交换按钮回调
(defun _cancel_cmd ()         ; 私有：取消命令回调
(defun _done_cmd ()           ; 私有：完成命令回调
(defun _compName (sym_inst "o")  ; 私有：辅助函数
(defun _do_swap (swap_list)   ; 私有：执行交换的核心逻辑

;; 公开入口函数：
(defun axlSwapComponent ()    ; 公开：命令入口

;; 来自 change_net_on_vias.il 的写法：
procedure( _RPVdoNetReplacement( vias net )  ; 私有：实际执行替换
```

> 来源依据：`axlswap_comp.il` 中所有内部函数均以 `_` 开头；`change_net_on_vias.il` 中内部替换逻辑函数名为 `_RPVdoNetReplacement`。

---

### 2.4 回调函数命名应当带 `CB` 后缀或使用 `_` 前缀

UI 控件、表单、命令、定时器等回调函数，命名应当明确标识其回调性质。常见做法：
- 使用 `_` 前缀 + 功能描述 + `CB` 后缀（如 `_AcDesignCB`）
- 或仅使用 `_` 前缀 + 功能描述（如 `_ashMeterCallback`）

```skill
;; 来自 cns-design.il 的写法：
procedure( _AcDesignCB(fw)   ; 表单回调函数
    case(fw->curField
    ("done"   _AcDesignDone(fw)  axlFinishEnterFun())
    ("cancel" _AcDesignCancel(fw) axlCancelEnterFun())
    ("apply"  _AcDesignDoit(fw)  _AcDesignApplyGray(fw nil))
    ...
    ))

;; 来自 ashmeter.il 的写法：
procedure(_ashMeterCallback(mhandle)
    let( ()
        axlMsgPut("-- formhandle is %L" mhandle->??)
        (case mhandle->curField
        ("info"
            axlMsgPut("-- User selected the Info button.")
        )
        )
    ))
```

> 来源依据：`cns-design.il` 使用 `_AcDesignCB`；`ashmeter.il` 使用 `_ashMeterCallback`。

---

### 2.5 命令入口函数命名采用小驼峰或全小写

通过 `axlCmdRegister` 注册给用户调用的命令入口函数，名称应当清晰描述功能，使用小驼峰（lowerCamelCase）或全小写（如 `rplc_netvia`）。

```skill
;; 来自 axlswap_comp.il 的写法：
(defun axlSwapComponent ()    ; 小驼峰

;; 来自 change_net_on_vias.il 的写法：
procedure( rplc_netvia()      ; 全小写，命令入口

;; 来自 cline2shape.il 的写法：
procedure( LCB_cline_to_shape()   ; 项目前缀 + 下划线

;; 来自 entertest.il 的写法：
(defun enterTest ()           ; 小驼峰
```

> 来源依据：官方示例中命令入口函数命名多样，但均以功能为导向，避免无意义缩写。

---

## 3. 局部变量与作用域

### 3.1 局部变量必须使用 `let` 声明

所有函数内部使用的临时变量，必须在 `let` 的绑定列表中声明，禁止在函数体中直接使用未声明的 `setq` 创建全局变量。

```skill
;; 来自 axlswap_comp.il 的写法：
(defun _build_popup ()
    (let (user_data swap_pop)        ; 在 let 中声明局部变量
        (setq userdata (axlUIGetUserData))
        (setq swap_pop (axlUIPopupDefine userdata->popupId
                (list (list "Swap" '_swapCB))))
        (axlUIPopupSet swap_pop)
    )
)

;; 来自 change_net_on_vias.il 的写法：
procedure( rplc_netvia()
  (let ( mypopup vias net )         ; 全部局部变量在 let 中声明
    axlClearSelSet()
    axlSetFindFilter(?enabled `("NOALL" "VIAS")
                     ?onButtons `("VIAS"))
    mypopup = axlUIPopupDefine( nil
                 (list (list "Done" 'axlFinishEnterFun)
                 (list "Cancel" 'axlCancelEnterFun)))
    axlUIPopupSet( mypopup)
    ...
))
```

> 来源依据：`axlswap_comp.il` 和 `change_net_on_vias.il` 中所有局部变量均在 `let` 中声明。

---

### 3.2 `let` 绑定列表中允许初始化赋值

`let` 的变量列表中可以直接给变量赋初值，这是最简洁的声明方式。

```skill
;; 来自 read.il 的写法：
(defun test_design (p)
    (let ((dsn (axlDBGetDesign))          ; 初始化赋值
          (branches (axlDBGetLonelyBranches))
          padstack pad symdef)
        (print_title "Design:" p)
        (my_print dsn->?? p)
        ...
    ) ; let
) ; defun test_design

;; 来自 cline2shape.il 的写法：
procedure(LCB_cline_to_shape()
let( (lclines layer polydbid )            ; 声明但不初始化
  LCB_Setup()
  LCB_mark = axlDBTransactionStart()
  LCBnotDone = t
  while( LCBnotDone
      lclines = axlGetSelSet(axlSelect(?prompt "Select Clines to convert to a shape."))
      ...
  )
  LCB_Done()
))
```

> 来源依据：`read.il` 的 `test_design` 在 `let` 中直接初始化 `dsn` 和 `branches`；`cline2shape.il` 的 `LCB_cline_to_shape` 在 `let` 中声明多个变量后逐个赋值。

---

### 3.3 嵌套作用域应当使用缩进清晰标识

当存在多层 `let`、`foreach`、`cond` 等嵌套时，代码缩进应当清晰地反映作用域层次。每一层嵌套增加 2~4 个空格。

```skill
;; 来自 read.il 的写法：
(defun test_nets (p)
    (let ((nets (ashFindAllNets))
           net branch branch_item)
        (foreach net
            nets
            (my_print net->?? p)
            (foreach branch
                net->branches
                (foreach branch_item
                    branch->children
                    (cond ((eq branch_item->objType "tee")
                         (fprintf p "\n\n!! Found a T: !!\n\n")
                         (my_print branch_item->?? p))
                    ) ; cond
                ) ; foreach branch_item
            ) ; foreach branch
        ) ; foreach net
    ) ; let
) ; defun test_nets
```

> 来源依据：`read.il` 中 `test_nets` 展示了 3 层 `foreach` 嵌套，每层缩进清晰，并附尾注释标识结束位置。

---

## 4. 函数参数与返回值

### 4.1 参数列表中的类型声明应当保留

SKILL 支持在参数列表中添加类型声明字符串（如 `"o"` 表示 dbid object）。当参数预期接收特定类型时，应当保留类型声明，以提高代码可读性和运行时类型检查能力。

```skill
;; 来自 axlswap_comp.il 的写法：
(defun _compName (sym_inst "o")   ; "o" 表示 object (dbid) 类型
    (cond
        (sym_inst->refdes sym_inst->refdes)
        (t (buildString (list "SYM:" sym_inst->name) " "))))
```

> 来源依据：`axlswap_comp.il` 的 `_compName` 函数参数声明了 `"o"` 类型。

---

### 4.2 函数应当返回明确的布尔值或状态码

用于表示操作成功与否的函数，应当返回 `t`（成功）或 `nil`（失败/无操作）。命令入口函数通常返回 `t` 以表示正常完成。

```skill
;; 来自 change_net_on_vias.il 的写法：
procedure( _RPVdoNetReplacement( vias net )
 (let (count )
    count = 0
    foreach( via vias
      axlChangeNet( via net)
      count++
    )
    if( count > 1 then
        axlMsgPut("%d vias were changed to net %s." count net->name)
    )
    t                                ; 明确返回 t 表示成功
))

;; 来自 axl_delete.il 的写法：
(defun deleteOpenShapeTests ()
    (let (shape)
        (setq shape (openTestShape))
        (deleteShapeSegment shape)
        (deleteShapeVoidSeg shape)
        (deleteOpenShape shape)
        (deleteOpenShapeVoid shape)
        (closeTestShape shape)
        (deleteShape shape)
        t                                ; 明确返回 t
    ))
```

> 来源依据：`change_net_on_vias.il` 和 `axl_delete.il` 中测试函数和命令函数均返回 `t` 表示成功。

---

### 4.3 复杂返回值应当优先使用列表或 `defstruct` 结构

当函数需要返回多个值时，应当返回 `list` 或自定义 `defstruct` 结构，避免使用全局变量传递结果。

```skill
;; 来自 axldbctvia.il 的写法：
;; 返回新创建对象的 dbid 列表
(defun dbc_via_print (return)
    return)

(defun dbc_via_t1 ()
    (dbc_via_print
        (axlDBCreateVia "via" 2.0:7.0)))   ; 返回 via 的 dbid 列表

;; 来自 axlform.il 的写法：
;; 使用 defstruct 封装复杂数据
(defstruct TestTreeItem string id)
(defun TestTreeItems ()
    (list
        (make_TestTreeItem ?string "For Sale" ?id nil)
        (list (make_TestTreeItem ?string "Redmond" ?id nil)
            (list (make_TestTreeItem ?string "100 B. Lnb" ?id nil))
            ...
        )))
```

> 来源依据：`axldbctvia.il` 中 `dbc_via_print` 直接返回 `axlDBCreateVia` 的结果列表；`axlform.il` 使用 `defstruct` 组织树节点数据。

---

## 5. 条件与分支控制

### 5.1 多分支条件优先使用 `cond`

当存在两个以上的互斥分支时，应当使用 `cond` 而非嵌套 `if` 或 `when`/`unless`，以提高代码可读性。

```skill
;; 来自 axlswap_comp.il 的写法：
(defun _swapCB ()
    (cond
        ((lessp (axlGetSelSetCount) 2)
            (printf "Must select two components before swapping"))
        (t (_do_swap (axlGetSelSet)))))

;; 来自 axlswap_comp.il 的写法：
(defun axlSwapComponent ()
    ...
    (while (axlSelect ?multiDisable t)
        (cond
            ((null prevSelSet)
                nil)
            ((greaterp (length prevSelSet) 1)
                (_do_swap prevSelSet))
            (t
                (axlAddSelectObject prevSelSet))))
    ...)
```

> 来源依据：`axlswap_comp.il` 中 `_swapCB` 和 `axlSwapComponent` 均使用 `cond` 处理多分支选择。

---

### 5.2 单分支条件使用 `when` 或 `unless`

当只需要在条件为真（`when`）或假（`unless`）时执行一个分支，不执行 else 分支，应当使用 `when` 或 `unless`，而不是 `if ... then ... else nil`。

```skill
;; 来自 cline2shape.il 的写法：
(unless( axlDBCreateShape(car(polydbid) t layer)  
    axlUIWPrint(nil "ERROR: Failed to create Shape from Cline.")
)

(when( cadr(polydbid) 
    axlDBCreateShape(cadr(polydbid) t layer) 
)

;; 来自 axlswap_comp.il 的写法：
(defun _do_swap (swap_list)
    (when (greaterp (length swap_list) 1)
        (printf "I- Performing swap of %s and %s\n" 
                (_compName (car swap_list)) 
                (_compName (cadr swap_list)))
        (axlSwapSymbols swap_list)))
```

> 来源依据：`cline2shape.il` 和 `axlswap_comp.il` 广泛使用 `when`/`unless` 处理单分支条件。

---

### 5.3 分支逻辑较长时应当提取为独立函数

当 `cond` 或 `case` 中的某个分支逻辑超过 5 行，应当将其提取为独立函数，保持主流程的简洁性。

```skill
;; 来自 cns-design.il 的写法：
procedure( _AcDesignCB(fw)
    case(fw->curField
    ("done"      _AcDesignDone(fw)       axlFinishEnterFun())
    ("cancel"    _AcDesignCancel(fw)     axlCancelEnterFun())
    ("apply"     _AcDesignDoit(fw)       _AcDesignApplyGray(fw nil))
    ("on"        _AcDesignAllSame(fw 'on))
    ("off"       _AcDesignAllSame(fw 'off) _AcDesignApplyGray(fw t))
    ("batch"     _AcDesignAllSame(fw 'batch))
    (t           _AcDesignValidate(fw))   ; 长逻辑提取为 _AcDesignValidate
    ))
```

> 来源依据：`cns-design.il` 的 `_AcDesignCB` 将每个分支的具体处理委托给独立函数，回调本身仅做路由分发。

---

## 6. 循环与迭代

### 6.1 遍历列表优先使用 `foreach`

遍历列表元素时，应当优先使用 `foreach`，其语义清晰，且会自动处理 `nil` 列表的情况。

```skill
;; 来自 change_net_on_vias.il 的写法：
procedure( _RPVdoNetReplacement( vias net )
 (let (count )
    count = 0
    foreach( via vias                     ; 遍历 via 列表
      axlChangeNet( via net)
      count++
    )
    ...
))

;; 来自 read.il 的写法：
(defun test_design (p)
    (let ( ... )
        (foreach symdef dsn->symdefs
            (print_title "symdef:" p)
            (my_print symdef->?? p)
        ) ; foreach symdef
        (foreach padstack dsn->padstacks
            (print_title "padstack:" p)
            (my_print padstack->?? p)
            (foreach pad padstack->pads
                (print_title "pad:" p)
                (ash_print_pad pad p)
            ) ; foreach pad
        ) ; foreach padstack
    ))
```

> 来源依据：`change_net_on_vias.il` 和 `read.il` 中广泛使用 `foreach` 遍历集合。

---

### 6.2 带条件的循环使用 `while`

当循环条件依赖运行时的状态变化（如用户交互、命令状态等），应当使用 `while`。

```skill
;; 来自 cline2shape.il 的写法：
procedure(LCB_cline_to_shape()
let( (lclines layer polydbid )
  LCB_Setup()
  LCB_mark = axlDBTransactionStart()
  LCBnotDone = t
  while( LCBnotDone                           ; 交互命令循环
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
```

> 来源依据：`cline2shape.il` 的 `LCB_cline_to_shape` 使用 `while` 控制交互命令的选点循环。

---

### 6.3 遍历并执行副作用使用 `mapc`

当需要对列表中每个元素执行某个函数（不返回新列表），且该函数已存在时，使用 `mapc` 最为简洁。

```skill
;; 来自 axl_delete.il 的写法：
(defun deleteAndPrint (items message)
    (let (result)
        ...
        (mapc 'ashPrintObjData items)      ; 对每个 item 调用 ashPrintObjData
        ...
        result))
```

> 来源依据：`axl_delete.il` 的 `deleteAndPrint` 使用 `mapc` 遍历打印对象属性。

---

## 7. 代码块与结构结束标识

### 7.1 复杂代码块应当使用尾注释标识结束

当 `defun`、`let`、`prog`、`foreach`、`cond` 等代码块跨越多行（超过 5 行），应当在结束括号后添加注释，标识该块对应结构。

```skill
;; 来自 read.il 的写法：
(defun test_a_symdef (p)
    (let (dsn sdf child)
        (print_title "Symdef Test:" p)
        (foreach sdf (axlDBGetDesign)->symdefs
            (fprintf p "\n\n Symdef: %s Children:\n\n", sdf->name)
            (foreach child
                sdf->children
                (my_print child->?? p)
            ) ; foreach sdf child
        ) ; foreach sdf
    ) ; test_a_symdef
) ; defun test_a_symdef

;; 来自 axlform.il 的写法：
(defun TestAddTreeItemsRecursive (form field l_list)
  (let ((parent (car l_list)))
    (when parent
          (mapc
            (lambda (item)
               (TestAddTreeItem form field parent (car item))
               (TestAddTreeItemsRecursive form field item))
            (cdr l_list))))
)
```

> 来源依据：`read.il` 中几乎所有函数都在结束括号后添加尾注释；`axlform.il` 中部分复杂函数也保留此习惯。

---

### 7.2 函数之间应当用空行分隔

函数与函数之间应当至少保留一个空行，以提高代码的可读性。相关功能函数可聚集在一起，但与不同功能组之间应当加空行。

```skill
;; 来自 axlswap_comp.il 的写法：
(defun _swapCB ()
    ...)

(defun _cancel_cmd ()
    ...)

(defun _done_cmd ()
    ...)

(defun _compName (sym_inst "o")
    ...)

(defun _do_swap (swap_list)
    ...)

; main routine for swap component
;
(defun axlSwapComponent ()
    ...)
```

> 来源依据：`axlswap_comp.il` 中每个函数之间都有空行分隔，且主要入口函数前有注释分隔。

---

## 8. 全局变量与状态管理

### 8.1 全局变量使用前必须用 `boundp` 检查

在 `ilinit` 或命令初始化中，全局变量首次赋值前必须使用 `boundp` 检查，避免重复加载时重新定义导致状态丢失。

```skill
;; 来自 cns-design.il 的写法：
; doing this prevents multiple instances of form from opening
unless(boundp('_AcDesignFw) _AcDesignFw = nil)

;; 来自 axlform.il 的写法：
;; init global form handle to nil
unless(boundp('f1s) f1s = nil)
unless(boundp('f1s_lastTab) f1s_lastTab = "Fillins")

;; 来自 timer.il 的写法：
unless(boundp('timerFw) timerFw = nil)
```

> 来源依据：`cns-design.il`、`axlform.il`、`timer.il` 中均使用 `unless(boundp(...))` 保护全局变量初始化。

---

### 8.2 禁止在函数内部直接使用 `setq` 创建未声明的变量

函数内部若需要使用局部变量，必须在 `let` 或 `prog` 中声明。直接使用 `setq` 而未在 `let` 中声明的变量将成为全局变量，导致命名空间污染和不可预期的副作用。

```skill
;; 不推荐：
(defun bad_example ()
    (setq tempVar 123)    ; 若未在 let 中声明，tempVar 将成为全局变量！
    ...)

;; 推荐：来自 axlswap_comp.il 的写法：
(defun _build_popup ()
    (let (user_data swap_pop)          ; 在 let 中声明
        (setq userdata (axlUIGetUserData))
        (setq swap_pop (axlUIPopupDefine ...))
        (axlUIPopupSet swap_pop)
    ))
```

> 来源依据：`axlswap_comp.il` 等所有官方示例中，函数内部变量均在 `let` 中声明。

---

## 9. 辅助函数与代码复用

### 9.1 重复逻辑必须提取为辅助函数

同一段逻辑在多处出现时，应当提取为独立的辅助函数，以遵循 DRY（Don't Repeat Yourself）原则。

```skill
;; 来自 axl_delete.il 的写法：
;; _makeCline 被多个测试函数复用
(defun _makeCline (p1 p2)
    (let (cline)
        (setq cline 
              (axlDBCreatePath (axlPathStart (list p1 p2) .012)
                               "ETCH/TOP" nil))
        (car (car cline))))

(defun mergeClines ()
    (let (clineList testPass)
        (setq clineList (cons (_makeCline 6.4:2.6 8.4:2.6) nil))
        (setq clineList (cons (_makeCline 2.4:2.6 4.4:2.6) clineList))
        (setq clineList (cons (_makeCline 4.4:2.6 6.4:2.6) clineList))
        ...))

(defun deleteClines ()
    (let (clineList testPass)
        (setq clineList (cons (_makeCline 6.4:2.6 8.4:2.6) nil))
        (setq clineList (cons (_makeCline 2.4:2.6 4.4:2.6) clineList))
        (setq clineList (cons (_makeCline 4.4:2.6 6.4:2.6) clineList))
        ...))
```

> 来源依据：`axl_delete.il` 中 `_makeCline` 被 `mergeClines` 和 `deleteClines` 复用。

---

### 9.2 辅助函数应当放在调用者之前定义

SKILL 解释器按顺序加载代码，被调用的函数应当在调用者之前定义（或至少在同一文件顶部），以避免运行时函数未定义错误。

```skill
;; 来自 axlswap_comp.il 的写法：
;; _build_popup、_swapCB、_do_swap 等辅助函数均在 axlSwapComponent 之前定义
(defun _build_popup () ...)
(defun _swapCB () ...)
(defun _cancel_cmd () ...)
(defun _done_cmd () ...)
(defun _compName (sym_inst "o") ...)
(defun _do_swap (swap_list) ...)

; main routine for swap component
;
(defun axlSwapComponent () ...)
```

> 来源依据：`axlswap_comp.il` 中所有 `_` 前缀的辅助函数均放在公开入口函数 `axlSwapComponent` 之前。

---

## 10. 注释与文档

### 10.1 函数前必须有描述性注释

每个函数定义前应当添加注释，说明其功能、参数和返回值。对于复杂逻辑，注释中应当包含算法步骤或设计意图。

```skill
;; 来自 axlswap_comp.il 的写法：
;
; build the popup menu
;
(defun _build_popup () ...)

;
; callback for swap button; only attempt swap if at least two components
; have been selected
;
(defun _swapCB () ...)

;
; routine to perform swap of components - calls axlSwapSymbols
; to actually swap the physical symbols
;
(defun _do_swap (swap_list) ...)

;; 来自 read.il 的写法：
;;
;; test_design - check out design attributes
;;
; retrieve the design    /* axlDBGetDesign */
;    print out all attributes of the design
;    for each symbol definition
;    print out the attributes of each symbol definition
;    for each padstack definition
;    print out all attributes of the padstack
;    for each padstack pad
;    print out all attributes of the pad
(defun test_design (p) ...)
```

> 来源依据：`axlswap_comp.il` 和 `read.il` 中每个函数前都有描述性注释；`read.il` 中 `test_design` 的注释甚至包含了伪代码步骤。

---

### 10.2 复杂逻辑内部应当添加行注释

函数内部的复杂逻辑或关键步骤，应当添加行内注释说明意图，而非仅描述代码做了什么。

```skill
;; 来自 cline2shape.il 的写法：
procedure(LCB_cline_to_shape()
let( (lclines layer polydbid )
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

> 来源依据：`cline2shape.il` 中详细注释了 undo 机制的设计意图和事务边界。

---

## 11. 示例代码汇总

以下汇总本章引用的官方示例文件路径，供交叉验证：

| 示例文件 | 路径 |
|---------|------|
| `axlswap_comp.il` | `D:/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/axlswap_comp.il` |
| `change_net_on_vias.il` | `D:/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/change_net_on_vias.il` |
| `cline2shape.il` | `D:/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/cline2shape.il` |
| `cns-design.il` | `D:/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/cns-design.il` |
| `axl_delete.il` | `D:/Cadence/SPB_17.4/share/pcb/examples/skill/edit/axl_delete.il` |
| `read.il` | `D:/Cadence/SPB_17.4/share/pcb/examples/skill/dbread/read.il` |
| `axldbctvia.il` | `D:/Cadence/SPB_17.4/share/pcb/examples/skill/dbcreate/axldbctvia.il` |
| `axldbctpin.il` | `D:/Cadence/SPB_17.4/share/pcb/examples/skill/dbcreate/axldbctpin.il` |
| `axldbctshp.il` | `D:/Cadence/SPB_17.4/share/pcb/examples/skill/dbcreate/axldbctshp.il` |
| `entertest.il` | `D:/Cadence/SPB_17.4/share/pcb/examples/skill/enter/entertest.il` |
| `ashmeter.il` | `D:/Cadence/SPB_17.4/share/pcb/examples/skill/ui/ashmeter.il` |
| `timer.il` | `D:/Cadence/SPB_17.4/share/pcb/examples/skill/ui/timer.il` |
| `axlform.il` | `D:/Cadence/SPB_17.4/share/pcb/examples/skill/form/basic/axlform.il` |
| `menu.il` | `D:/Cadence/SPB_17.4/share/pcb/examples/skill/ui/menu.il` |
| `disclaimer.il` | `D:/Cadence/SPB_17.4/share/pcb/examples/skill/disclaimer.il` |
| `README.txt` | `D:/Cadence/SPB_17.4/share/pcb/examples/skill/README.txt` |

---

> **编码提示**：本规范文件及所有引用官方示例的中文注释，均建议使用 **GBK 编码**保存，以确保在 Allegro PCB Editor 的 SKILL 解释环境中中文显示正确。使用 UTF-8 编码可能导致中文注释在 Allegro 中显示为乱码。
