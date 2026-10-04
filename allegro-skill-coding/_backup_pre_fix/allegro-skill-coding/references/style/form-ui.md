# Allegro SKILL 代码规范 — 表单与 UI 编程

> 本章规范基于 Cadence SPB 17.4 官方示例代码提炼，适用于 Allegro PCB Editor SKILL (AXL) 的表单（Form）、菜单（Menu）、弹出框（Popup）及各类 UI 控件的开发与维护。

---

## 1. 总体原则

**1.1** 表单与 UI 编程应当遵循 "创建 → 初始化 → 显示 → 回调处理 → 关闭" 的明确生命周期，禁止在单一函数中混叠生命周期的不同阶段。

> **依据**：`axlform.il` 中的 `IFormTest` 函数将创建（`axlFormCreate`）、初始化（`IFormRefresh`）和显示（`axlFormDisplay`）分离为独立步骤，并返回表单句柄。
>
> ```skill
; D:\Cadence\SPB_17.4\share\pcb\examples\skill\form\basic\axlform.il
procedure( IFormTest(fw)
    prog( (position bitmap_handle graphic_handle)

    (cond (fw
        (axlUIWExpose fw)
        (return fw)
        )
    )

    position = '("NE" "msglines" 1)
    fw = axlFormCreate('f1s "axlform" position '_afCallback t nil )

    axlFormSetMouseActive(fw)
    bitmap_handle = axlGRPDrwInit(fw "bitmap" 'FlipIt)
    ...
    fw->Bitmap_handle = bitmap_handle
    fw->Graphic_handle = graphic_handle

    axlFormTitle(fw "--F1-- Skill Test Form" )
    axlFormBuildPopup(fw "enum" '(("item1") ("item2") ("item3")) )

    IFormRefresh(fw)
    axlFormDisplay(fw)
    return(fw)
    )
)
```

**1.2** 表单文件（`.form`）与对应的 SKILL 文件（`.il`）必须位于同一工作目录，且主 SKILL 文件有责任通过注释说明其对 `.form` 文件的依赖关系。

> **依据**：`axlform.il` 头部注释明确要求 `axlform.form` 位于当前目录；`README.txt` 亦指出 "Copy all of the files from one of the directories to a local directory."。
>
> ```skill
; D:\Cadence\SPB_17.4\share\pcb\examples\skill\form\basic\axlform.il
;; AXL FORM DEMO
;;	requires axlform.form file to in current directory.
;;	optional bitmap files (*.bmp)
```

**1.3** 所有涉及中文注释的 `.il` 与 `.form` 文件必须使用 **GBK 编码** 保存，以避免在 Allegro 命令行和 SKILL 解释器中出现乱码。纯 ASCII 文件可使用系统默认编码，但建议统一为 GBK 以保持一致性。

---

## 2. 文件头部规范

**2.1** 表单相关的 SKILL 文件头部必须包含：文件功能描述、`.form` 依赖声明、加载与启动方式、可选的前置条件说明。文件头注释应当使用 `;;` 或 `;` 引导，且分隔线清晰。

> **依据**：`axlform.il` 头部（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\form\basic\axlform.il`）。
>
> ```skill
;; AXL FORM DEMO
;;	requires axlform.form file to in current directory.
;;	optional bitmap files (*.bmp)
;;
;; This demostrates form controls, options and programming. Exception
;; is the grid control which is demostrated in fgrid.il
;;
;;  To access demo, in Skill
;;	load "axlform.il"
;;	formtest
;;  Embedded test
;; 	EmbededForm
```

**2.2** 表单文件（`.form`）头部必须包含 `FILE_TYPE=FORM_DEFN VERSION=2` 声明，紧跟 `FORM` 关键字，随后定义窗口属性（`FIXED` 或 `PORT`）、标题（`HEADER`）和可选的全局弹出菜单（`POPUP`）与消息（`MESSAGE`）。

> **依据**：`axlform.form` 与 `acns_design.form` 的统一头部格式（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\form\basic\axlform.form`）。
>
> ```text
# D:\Cadence\SPB_17.4\share\pcb\examples\skill\form\basic\axlform.form
FILE_TYPE=FORM_DEFN VERSION=2
FORM AUTOGREYTEXT
FIXED
PORT 44 14
HEADER "Form Field Type Demo"

POPUP <STRING>"Fee""0","Fi""1","Foo""2","Fum""3", "Disabled""4".
POPUP <ENUM>"ITEM1""0","ITEM2""1","ITEM3""2","LAST ONE""3".
MESSAGE nedit 2 "Not editable while in interactive command."
```

**2.3** 如果代码属于非官方示例或二次开发，应当在文件头部添加 `DISCLAIMER` 声明，说明代码性质为 "non-supported" 并提示使用风险。官方示例中若包含复杂逻辑，亦应当附带已知缺陷（Known Bug）说明。

> **依据**：`cline2shape.il` 的头部声明（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\cmds\cline2shape.il`）。
>
> ```skill
;###############################################################################
;                      Command: cline2shape                                    #
;                   Skill File: cline2shape.il                                 #
;               How To Execute: Command> cline2shape                           #
;                                                                              #
;  DISCLAIMER:                                                                 #
;       The user of this command assumes all responsibility and does not       #
;       hold Cadence Design Systems nor the author of this code for any        #
;       unwarranted results or problems due to the use of this code.           #
;                                                                              #
;       This is non-supported code and the user may modify it as needed.       #
;###############################################################################
```

---

## 3. 表单文件（.form）语法规范

**3.1** 表单文件必须使用 `#` 作为注释符号，注释行应当简明扼要。禁止使用 SKILL 风格的 `;` 注释，因为 `.form` 文件由独立的表单解析器处理。

> **依据**：`acns_design.form` 中的注释（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\cmds\acns_design.form`）。
>
> ```text
# D:\Cadence\SPB_17.4\share\pcb\examples\skill\cmds\acns_design.form
#----------------------------------------------------------
# PACKAGE 2 PACKAGE
TEXT "Package to package:"
FLOC 2 6
ENDTEXT
```

**3.2** 表单字段（`FIELD`）必须成对使用 `FIELD` 和 `ENDFIELD` 包裹；文本标签（`TEXT`）必须成对使用 `TEXT` 和 `ENDTEXT` 包裹；标签页（`TAB`）和标签页集（`TABSET`）必须正确嵌套并以 `ENDTAB` / `ENDTABSET` 结束。`TILE` 和 `ENDTILE` 之间为完整的布局区域。

> **依据**：`axlform.form` 的字段与标签页结构（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\form\basic\axlform.form`）。
>
> ```text
TILE

TABSET "tab"
OPTIONS tabsetDispatch
FLOC 2 1
FSIZE 42 27

TAB "Fillins"

TEXT "Enum single/drop:"
FLOC 2 2
ENDTEXT

FIELD enum
FLOC 16 2
ENUMSET 7
POP "ENUM"
ENDFIELD

...
ENDTAB

ENDTABSET

ENDTILE

ENDFORM
```

**3.3** 字段命名应当使用小写英文字母、数字和下划线，保持语义清晰。如果字段需要表达层级关系（如约束条件与模式值的组合），可以使用点号（`.`）作为分隔符，但点号前后的命名应当遵循统一的命名空间约定。

> **依据**：`acns_design.form` 中约束条件字段的命名方式（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\cmds\acns_design.form`）。
>
> ```text
FIELD Package_to_Package_Spacing.on
FLOC 28 6
CHECKLIST "" "1"
ENDFIELD
FIELD Package_to_Package_Spacing.off
FLOC 32 6
CHECKLIST "" "1"
ENDFIELD
FIELD Package_to_Package_Spacing.value
FLOC 17 16
STRFILLIN 9 14
ENDFIELD
```

**3.4** 使用 `FLOC x y` 定义字段左上角坐标，`FSIZE w h` 定义字段尺寸。`FLOC` 和 `FSIZE` 的单位为字符或表单定义单位，必须显式指定，禁止省略导致布局歧义。

> **依据**：`axlform.form` 中所有字段均显式指定 `FLOC`，部分字段补充 `FSIZE`（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\form\basic\axlform.form`）。
>
> ```text
FIELD mline
FLOC 16 6
STRFILLIN 16 1024
FSIZE 16 10
ENDFIELD
```

**3.5** 表单文件中可使用 `OPTIONS` 关键字为字段设置样式（如 `bold`、`underline`、`right`、`center`、`border`、`prettyprint`、`ownerdrawn`、`stretch`、`multiselect` 等）。多个选项之间以空格分隔。禁止使用官方文档未列明的选项值。

> **依据**：`axlform.form` 中 `enumcolor` 字段和文本字段的 `OPTIONS` 使用（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\form\basic\axlform.form`）。
>
> ```text
FIELD enumcolor
FLOC 16 4
ENUMSET 8
OPTIONS ownerdrawn prettyprint
POP "ENUMCOLOR"
ENDFIELD

TEXT "Bold"
FLOC 4 8
OPTIONS bold
ENDTEXT

TEXT "Center + Border"
FLOC 17 10
OPTIONS center border
ENDTEXT
```

**3.6** 对于需要自适应窗口大小的表单，应当在 `ENDTILE` 之前使用 `FLEXMODE` 和 `FLEX` 定义控件的伸缩行为。`FLEX` 的参数格式为 `FLEX field x1 y1 x2 y2`，表示控件在水平和垂直方向上的锚定与拉伸比例。

> **依据**：`axlform.form` 的 `FLEXMODE` 定义（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\form\basic\axlform.form`）。
>
> ```text
FLEXMODE edgegravity
FLEX tab 0 0 1 1
FLEX listfield 0 0 1 1
FLEX tree 0 0 1 1
FLEX progress 0 0 1 0
FLEX enum 0 0 1 0
FLEX string 0 0 1 0
FLEX bmp1 0 0 1 1
FLEX stc 0.5 0 0 0
```

**3.7** 表单文件中支持条件编译：使用 `#ifndef _macro` 和 `#endif` 包裹仅在特定产品版本或平台中可用的字段。条件编译宏应当使用大写字母和下划线命名。

> **依据**：`acns_design.form` 中使用 `#ifndef _allegro_studio` 排除特定字段（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\cmds\acns_design.form`）。
>
> ```text
#ifndef _allegro_studio

TEXT "Testpoint pad to component:" Testpoint_Pad_to_Component_Spacing.textm
FLOC 2 26
ENDTEXT
...

#endif 		_ALLERGO_STUDIO
```

---

## 4. 表单句柄与全局状态管理

**4.1** 表单句柄（form handle）必须声明为全局变量，并在文件加载时使用 `unless(boundp('handleVar) handleVar = nil)` 进行惰性初始化，以防止句柄被重复赋值或 `redef` 警告。

> **依据**：`axlform.il` 中 `f1s` 与 `f1s_lastTab` 的初始化（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\form\basic\axlform.il`）。
>
> ```skill
unless(boundp('f1s) f1s = nil)
unless(boundp('f1s_lastTab) f1s_lastTab = "Fillins")
```

> **依据**：`cns-design.il` 中 `_AcDesignFw` 的初始化（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\cmds\cns-design.il`）。
>
> ```skill
unless(boundp('_AcDesignFw) _AcDesignFw = nil)
```

**4.2** 表单句柄变量名应当使用有意义的标识，私有表单的句柄变量名必须以 `_` 前缀开头，以表明其作用域为模块内部。公共表单句柄可以使用无前缀命名，但必须在注释中说明其用途。

> **依据**：`_AcDesignFw`（私有）与 `f1s`（公共示例）的命名对比（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\cmds\cns-design.il` 与 `D:\Cadence\SPB_17.4\share\pcb\examples\skill\form\basic\axlform.il`）。

**4.3** 若表单需要在 Allegro 会话期间保持单例（Singleton），在创建表单之前必须先检查句柄是否非空，若非空则调用 `axlUIWExpose` 将已有表单置前并立即返回，禁止重复创建。

> **依据**：`cns-design.il` 的 `AcnsDesignForm` 函数（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\cmds\cns-design.il`）。
>
> ```skill
procedure( AcnsDesignForm()
    prog( (fw position)

    fw = _AcDesignFw
    when( fw
        axlUIWExpose(fw)
        return(t)
    )

    position = '("NE" "msglines" 1)
    fw = axlFormCreate('_AcDesignFw "acns_design" position '_AcDesignCB t nil )
    ...
    axlFormDisplay(fw)
    _AcDesignEvent()
    )
)
```

---

## 5. 表单创建与显示规范

**5.1** 表单必须使用 `axlFormCreate` 创建，且回调函数参数（callback）必须提供有效函数符号。对于需要异步交互的表单，回调函数是必需的；同步模式（`nil` callback）仅用于简单对话框或一次性数据收集，且必须在代码注释中说明同步模式的使用理由。

> **依据**：`axlform.il` 中同时展示了异步（推荐）和同步（不推荐）两种模式（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\form\basic\axlform.il`）。
>
> ```skill
;; GENERAL FORM PROGRAMMING METHOD
;; 		async form mode
;;
;; This is a good example on how to program a form.
fw = axlFormCreate('f1s "axlform" position '_afCallback t nil )

;; sync form mode -- no callback
;; no message lines
;; string only option to axlFormCreate
(defun f2 ()
( setq f2s (axlFormCreate 'f2s "axlform" '( "E" "outer" "msglines" ) nil nil t ))
(  axlFormTitle f2s "--F2-- Skill Test Form" )
(  axlFormDisplay f2s )
(printf "i am here\n")
(axlFormClose f2s)
)
```

**5.2** `axlFormCreate` 的第三个参数（position）应当使用列表形式显式指定窗口位置（如 `'("NE")`、`'("CENTER")`、`'("E" "OUTER")`）和消息行数（`"msglines" n`）。禁止省略位置参数导致窗口位置不可预测。

> **依据**：`axlform.il` 中 `position` 变量的显式构造（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\form\basic\axlform.il`）。
>
> ```skill
position = '("NE" "msglines" 1)
fw = axlFormCreate('f1s "axlform" position '_afCallback t nil )
```

> **依据**：`timer.il` 中 `timerForm` 的位置定义（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\ui\timer.il`）。
>
> ```skill
fw = axlFormCreate( 'timerFw "timer_example" '("C" "INNER" "MSGLINES" 0) 'timerFormCB
                nil)
```

**5.3** 表单标题（`axlFormTitle`）的设定应当在 `axlFormDisplay` 之前完成。表单字段的初始化、动态弹出菜单的构建、颜色/字体等属性的设置，均必须在 `axlFormDisplay` 之前完成。

> **依据**：`axlform.il` 中 `IFormTest` 的执行顺序（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\form\basic\axlform.il`）。
>
> ```skill
axlFormTitle(fw "--F1-- Skill Test Form" )
axlFormBuildPopup(fw "enum" '(("item1") ("item2") ("item3")) )
IFormRefresh(fw)
axlFormDisplay(fw)
```

**5.4** 表单显示后，主函数应当返回表单句柄给调用者，以便外部代码可以继续操作或检查表单状态。禁止在创建函数内部直接阻塞等待表单关闭（除非使用 `axlUIWBlock` 的显式阻塞模式，且需在注释中说明）。

> **依据**：`axlform.il` 中 `IFormTest` 的返回值（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\form\basic\axlform.il`）。
>
> ```skill
return(fw)	; return form handle to caller
```

---

## 6. 回调函数规范

**6.1** 表单回调函数（callback）必须使用 `defun` 或 `procedure` 定义，且函数签名应当接受唯一的表单句柄参数（官方约定名为 `fw` 或 `theform`）。回调函数负责处理所有字段变更事件、按钮点击事件和关闭事件。

> **依据**：`axlform.il` 中 `_afCallback` 的定义（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\form\basic\axlform.il`）。
>
> ```skill
(defun _afCallback (fw)
     (prog (t1 item field cnt)
        ...
        case(fw->curField
        ("tab"
            f1s_lastTab = fw->curValue)
        ("redraw"
            axlGRPDrwUpdate(fw->Bitmap_handle)
            axlGRPDrwUpdate(fw->Graphic_handle)
        )
        ...
        )

        if((nequal fw->doneState 0)  then
            axlFormClose(fw)
        )
        return()
))
```

**6.2** 回调函数内部应当使用 `case`（或 `caseq`）根据 `fw->curField` 分发字段事件，禁止在回调函数中使用大量 `if/else` 嵌套来处理不同字段。对于 `done` 和 `cancel` 等标准按钮，应当在 `case` 分支中显式处理。

> **依据**：`cns-design.il` 中 `_AcDesignCB` 的字段分发（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\cmds\cns-design.il`）。
>
> ```skill
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
    ("apply"
        _AcDesignDoit(fw)
        _AcDesignApplyGray(fw nil)
    )
    (t
        _AcDesignValidate(fw)
    )
    )
)
```

**6.3** 回调函数必须检查 `fw->doneState` 的值。当 `doneState` 非零时，表示用户请求关闭表单，应当调用 `axlFormClose(fw)` 进行清理。禁止在 `doneState` 非零时忽略关闭请求，导致表单残留或内存泄漏。

> **依据**：`helptip.il` 中 `heltip_CB` 的关闭处理（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\form\basic\helptip.il`）。
>
> ```skill
procedure( heltip_CB(fw)
    prog(()
     unless((fw->doneState == 0)
         axlFormClose(fw)
         return(t)
     )
))
```

**6.4** 回调函数中若需要处理表单句柄的自定义属性（如 `fw->_change`、`fw->_timerId`），这些属性名必须以 `_` 前缀开头，以避免与 Allegro 内部字段冲突。属性的赋值和读取应当集中在一处，便于维护。

> **依据**：`cns-design.il` 与 `timer.il` 中自定义属性的使用（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\cmds\cns-design.il` 与 `D:\Cadence\SPB_17.4\share\pcb\examples\skill\ui\timer.il`）。
>
> ```skill
; cns-design.il
fw->_change = t
fw->_cnsDsnSep = "."
fw->_cnsDsnValue = "value"

; timer.il
timerId->_fw = fw
timerId->_cnt = 0
fw->_timerId = timerId
```

---

## 7. 字段操作规范

**7.1** 设置表单字段值应当使用 `axlFormSetField`，获取字段值应当使用 `axlFormGetField`。禁止直接通过句柄属性（如 `fw->fieldName`）读写字段值，除非官方文档明确支持。

> **依据**：`cns-design.il` 中 `_AcDesignRefresh` 函数对字段的批量设置（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\cmds\cns-design.il`）。
>
> ```skill
procedure( _AcDesignRefresh(fw)
    (let (items modes field editable )
    items = axlCNSDesignModeGet('all)
    foreach( item items
        field = _cnsCreateModeField(fw item)
        axlFormSetField(fw field t )
    )
    ...
    items = axlCNSDesignValueGet('all t)
    foreach( item items
        field = strcat( get_pname(car(item)) fw->_cnsDsnSep fw->_cnsDsnValue)
        axlFormSetField(fw field cadr(item) )
    )
    ...
))
```

**7.2** 当用户输入的字段值非法或需要回滚时，应当使用 `axlFormRestoreField(fw fieldName)` 恢复字段到上一次有效值，而不是手动重新赋值。

> **依据**：`cns-design.il` 中 `_AcDesignValidate` 对非法输入的恢复（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\cmds\cns-design.il`）。
>
> ```skill
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
            ...
            (t
                axlUIWPrint(fw 'error "%s" err)
                axlFormRestoreField(fw fw->curField)
            )
        ...
))
```

**7.3** 使用 `axlFormSetFieldEditable` 控制字段的可编辑状态，使用 `axlFormSetFieldVisible` 控制字段的可见状态。对于成组的关联字段（如标签和输入框），应当同时设置其 `Editable` 或 `Visible` 状态，保持 UI 一致性。

> **依据**：`axlform.il` 中 `TestGrey` 函数和 `IFormRefresh` 中对灰色字段的处理（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\form\basic\axlform.il`）。
>
> ```skill
procedure( TestGrey( on )
    (axlFormSetFieldEditable f1s "grey_enum" on)
    (axlFormSetFieldEditable f1s "grey_string" on)
)

; IFormRefresh 中
(axlFormSetFieldEditable fw "mline" nil )
(axlFormSetFieldEditable fw "disabled_text" nil)
```

> **依据**：`cns-design.il` 中根据产品层级隐藏字段（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\cmds\cns-design.il`）。
>
> ```skill
foreach( item hide
    foreach( suffix fSuffixes
        field = sprintf(nil "%s%s%s" item sep suffix)
        axlFormSetFieldVisible(fw field 0)
    )
)
```

**7.4** 对于需要设置颜色的字段，应当使用 `axlFormColorize` 而非 `axlFormSetField` 的非法扩展。颜色参数可以是预定义符号（如 `'red`、`'green`、`'blue`）或数据库颜色索引。

> **依据**：`axlform.il` 中 `TestColor` 与 `ChangeColor` 函数（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\form\basic\axlform.il`）。
>
> ```skill
procedure( TestColor( mode color )
    prog((option )
    caseq(mode
    (background
        option = 'background)
    (text
        option = 'text)
    (nil
        TestColor('background nil)
        TestColor('text nil)
        return()
    ))
    axlFormColorize(f1s f1s_field option color)
))
```

---

## 8. 列表框（List）与树形控件（TreeView）规范

**8.1** 初始化列表框（`LIST`）时，若数据量较大，应当一次性传入整个字符串列表到 `axlFormSetField`，禁止在循环中逐条调用 `axlFormSetField` 添加列表项，以避免严重的性能问题。

> **依据**：`axlform.il` 中 `plisttest` 函数的基准测试对比（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\form\basic\axlform.il`）。
>
> ```skill
; 低效方式：逐条添加
foreach( mapc x many
    axlFormSetField(f1s, "listfield" x)
)

; 正确方式：一次性传入列表
axlFormSetField(f1s, "listfield" many)
```

**8.2** 列表框的双击事件和选择事件应当通过 `fw->doubleClick` 和 `fw->event` 进行区分。多选列表（`OPTIONS multiselect`）的回调函数中，应当使用 `axlFormListGetSelCount` 和 `axlFormListGetSelItems` 获取当前选中项。

> **依据**：`axlform.il` 中列表框回调处理（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\form\basic\axlform.il`）。
>
> ```skill
("listfield"
    fw->_listIndex = fw->curValueInt
    axlFormSetField(fw "listtext" fw->curValue)
    when( fw->doubleClick printf("Double Click listfield!\n\n"))
)
("mlistfield"
    fw->_listIndex = fw->curValueInt
    printf("multi-list isSelect %L\n" fw->event)
    axlFormSetField(fw "listtext" fw->curValue)
    when( fw->doubleClick printf("Double Click mlistfield!\n\n"))
)
```

> **依据**：`TestMultiSelect` 函数（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\form\basic\axlform.il`）。
>
> ```skill
procedure( TestMultiSelect( )
    let((items cnt)
    cnt = axlFormListGetSelCount(f1s "mlistfield")
    items = axlFormListGetSelItems(f1s "mlistfield")
    printf("Selected items (cnt=%d) %L\n" cnt items)
))
```

**8.3** 树形控件（`TREEVIEW`）的节点添加应当使用 `axlFormTreeViewAddItem`，节点操作（展开、折叠、排序）应当使用 `axlFormTreeViewSet`。树节点的句柄应当妥善保存以便后续操作。树节点的右键弹出菜单应当在回调函数中检查 `fw->event == 'rightpopup`。

> **依据**：`axlform.il` 中树形控件的初始化与事件处理（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\form\basic\axlform.il`）。
>
> ```skill
; 初始化树节点
tree = axlFormTreeViewAddItem(fw "tree" "one" nil nil 'TVSELECT_3STATE)
    f1sTreeRoot = tree
    axlFormTreeViewAddItem(fw "tree" "one" tree nil 'TVSELECT_SINGLE)
    tree1 = axlFormTreeViewAddItem(fw "tree" "two" tree nil 'TVSELECT_2STATE)
        axlFormTreeViewAddItem(fw "tree" "one" tree1 nil t)
        axlFormTreeViewAddItem(fw "tree" "two" tree1 nil t)
        axlFormTreeViewAddItem(fw "tree" "three" tree1 nil t)
    axlFormTreeViewAddItem(fw "tree" "three" tree nil)
    axlFormTreeViewAddItem(fw "tree" "four" tree nil)

; 右键弹出菜单处理
("tree"
    when( (fw->event == 'rightpopup)
        case(fw->curValue
        ("expand_all"
            axlFormTreeViewSet(fw "tree" 'TV_EXPAND nil))
        ("collapse_top"
            axlFormTreeViewSet(fw "tree" 'TV_COLLAPSE_TOP nil))
        )
    )
)
```

---

## 9. 弹出菜单（Popup）与动态内容规范

**9.1** 静态弹出菜单应当在 `.form` 文件中通过 `POPUP <name>` 定义，动态弹出菜单应当在 SKILL 代码中通过 `axlFormBuildPopup` 构建。禁止在 `.form` 文件中硬编码可能因运行时状态变化的菜单项。

> **依据**：`axlform.form` 中静态 `POPUP` 定义与 `axlform.il` 中动态构建的对比（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\form\basic\axlform.form` 与 `D:\Cadence\SPB_17.4\share\pcb\examples\skill\form\basic\axlform.il`）。
>
> ```text
; axlform.form
POPUP <STRING>"Fee""0","Fi""1","Foo""2","Fum""3", "Disabled""4".
POPUP <ENUM>"ITEM1""0","ITEM2""1","ITEM3""2","LAST ONE""3".
```
>
> ```skill
; axlform.il
axlFormBuildPopup(fw "enum" '(("item1") ("item2") ("item3")) )

; colorTest.il 中动态构建带颜色选项的弹出菜单
axlFormBuildPopup(form "COLOR_LIST" colorList);
```

**9.2** 使用 `axlFormBuildPopup` 构建动态弹出菜单时，菜单项列表的格式应当为 `'(("label1" "value1") ("label2" "value2") ...)` 或 `'(("label1") ("label2"))`。当使用颜色字体选项时，格式为 `'(("label" value color font))`。禁止传入扁平列表导致解析失败。

> **依据**：`axlform.il` 中 `axlFormBuildPopup` 的合法调用（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\form\basic\axlform.il`）。
>
> ```skill
axlFormBuildPopup(fw "enum" '(("item1") ("item2") ("item3")) )

axlFormBuildPopup(fw "enumcolor"
      '(("green" 1 green)
        ("yellow" 2 yellow bold)
        ("red" 3 red underline)
        ("blue" 4 blue )
        ("button" 5 button )
        ("black" 6 black )
        ("white" 7 white )
        ("Bold" 8 bold )
        ("Underline" 9 underline )
        ) )
```

> **依据**：`axlform.il` 中的非法示例注释（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\form\basic\axlform.il`）。
>
> ```skill
(defun badPopTest ()
 axlFormBuildPopup( f1s "enum" '(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16))
)
```

**9.3** 在交互式命令中，右键弹出菜单（RMB Popup）应当使用 `axlUIPopupDefine` 定义，并通过 `axlUIPopupSet` 激活。弹出菜单的回调函数应当遵循命令回调命名规范，并在 `axlCmdRegister` 中注册对应的 `doneCmd`、`cancelCmd` 和 `undo` 选项。

> **依据**：`cline2shape.il` 中 RMB 弹出菜单的定义（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\cmds\cline2shape.il`）。
>
> ```skill
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
```

---

## 10. 进度与计时器规范

**10.1** 表单中的进度条（`PROGRESS`）应当使用 `axlFormSetField` 并传入三元列表 `(current max step)` 进行初始化，后续更新可通过传入 `nil` 让步进递增。

> **依据**：`timer.il` 与 `axlform.il` 中进度条的使用（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\ui\timer.il` 与 `D:\Cadence\SPB_17.4\share\pcb\examples\skill\form\basic\axlform.il`）。
>
> ```skill
; axlform.il - 初始化
(axlFormSetField fw "progress" '(5 100 15) )

; timer.il - 在计时器回调中步进
timerId->_cnt = timerId->_cnt +1
axlFormSetField(timerId->_fw "count" timerId->_cnt)
axlFormSetField(timerId->_fw "progress" nil)
```

**10.2** 使用 `axlUIWTimerAdd` 添加计时器时，必须保存返回的计时器 ID，并在表单关闭或命令结束时通过 `axlUIWTimerRemove` 移除计时器，防止计时器回调在句柄释放后访问无效内存。

> **依据**：`timer.il` 中计时器的创建与销毁（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\ui\timer.il`）。
>
> ```skill
procedure( timerFormCB(fw)
   case(fw->curField
        ("close"
            axlUIWTimerRemove(fw->_timerId)
            axlFormClose(fw))
   )
)

procedure( timerForm()
    let((fw)
     fw = axlFormCreate( 'timerFw "timer_example" ... )
     timerId = axlUIWTimerAdd(nil 2000 nil 'timerCBForForm)
     timerId->_fw = fw
     timerId->_cnt = 0
     fw->_timerId = timerId

     axlFormSetField(fw "progress" '(5 100 1))
     axlFormDisplay(fw)
))
```

**10.3** 对于独立的进度指示（非表单内嵌），应当使用 `axlMeterCreate` 创建进度表，并可通过自定义 `.form` 文件扩展其按钮和交互能力。`axlMeterCreate` 的回调函数签名与表单回调一致。

> **依据**：`ashmeter.il` 中 `axlMeterCreate` 的使用（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\ui\ashmeter.il`）。
>
> ```skill
axlCmdRegister("metertest" 'ash_meterform)

procedure(ash_meterform()
  let( (meterfile)
   meterfile = "ashmeter"
   axlMeterCreate("Test Meter Form" "Info1 line" t meterfile "" '_ashMeterCallback )
))

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

---

## 11. 菜单（Menu）操作规范

**11.1** 菜单的动态修改应当使用 `axlUIMenuFind` 定位目标菜单节点，然后使用 `axlUIMenuInsert`、`axlUIMenuChange` 或 `axlUIMenuDelete` 进行操作。禁止直接修改菜单配置文件，除非在 `allegro.ilinit` 加载阶段通过 `axlUIMenuRegister` 或 `axlTriggerSet` 注册触发器。

> **依据**：`menu.il` 中菜单的查找与修改（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\ui\menu.il`）。
>
> ```skill
q = axlUIMenuFind( nil "add rect")
z = axlUIMenuInsert(q 'separator )

q = axlUIMenuFind(nil 3 'bottom)
z = axlUIMenuInsert(q "add hello" "echo hello add" )

q = axlUIMenuFind( nil -1 'top)
z = axlUIMenuInsert(q "Google" "http \"http://google.com\"")

q = axlUIMenuFind( nil -1)
l = '((popup "Drop1") ("hello1" "echo hello1") ("hello2" "echo hello2"))
z = axlUIMenuInsert(q l)
```

**11.2** 使用 `axlUIMenuRegister` 注册菜单时，菜单列表应当使用标准的嵌套列表结构：`(popup "Name")` 表示子菜单，`(end)` 表示子菜单结束，`'separator` 表示分隔线。命令字符串中若需要包含双引号，应当使用 SKILL 的转义规则（`"`）。

> **依据**：`menu.il` 中 `menuTrig1` 与 `ml2` 的定义（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\ui\menu.il`）。
>
> ```skill
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

ml2 = '(
     (popup "QuickKeys")
           ("EndCaps" "scriptmode +i; prmed; FORM prmedit display_enhance toggle; FORM prmedit done ")
           ("Ratsnest" "scriptmode +i; prmed; form_next prmedit ratsnest_display; FORM prmedit done ")
        )
```

---

## 12. 消息与提示规范

**12.1** 向用户显示错误信息时，应当使用 `axlUIWPrint` 并指定消息类型为 `'error`；显示普通信息时，指定 `'info`。禁止在表单程序中直接使用 `printf` 输出到标准输出流，因为用户可能无法看到控制台输出。

> **依据**：`cns-design.il` 中 `axlUIWPrint` 的使用（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\cmds\cns-design.il`）。
>
> ```skill
axlUIWPrint(nil 'info axlFormMsg(fw "drcstart"))
axlUIWPrint(nil 'info axlFormMsg(fw "drcdone"))

axlUIWPrint(fw 'error "%s" err)
```

> **依据**：`cline2shape.il` 中错误提示（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\cmds\cline2shape.il`）。
>
> ```skill
unless( axlDBCreateShape(car(polydbid) t layer)
    axlUIWPrint(nil "ERROR: Failed to create Shape from Cline.")
)
```

**12.2** 表单中引用的消息文本应当定义在 `.form` 文件的 `MESSAGE` 段中，并通过 `axlFormMsg` 引用。消息编号（severity）应当遵循官方约定：0=信息，1=警告，2=错误，3=致命错误。消息文本中若需要格式占位符，应当使用 `%s` 等标准格式，并在 SKILL 代码中通过 `axlUIWPrint` 的额外参数传入。

> **依据**：`acns_design.form` 中消息定义与 `cns-design.il` 中引用（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\cmds\acns_design.form` 与 `D:\Cadence\SPB_17.4\share\pcb\examples\skill\cmds\cns-design.il`）。
>
> ```text
MESSAGE drcstart 1 "DRC update, please wait..."
MESSAGE drcdone 0 "DRC done."
MESSAGE nodrcrun 2 "DRC Update can not be run while command active."
MESSAGE badnum 3 "%s, is not a valid format, syntax is: num [units]"
MESSAGE less0 3 "%s cannot be negative."
```
>
> ```skill
axlUIWPrint(nil 'info axlFormMsg(fw "drcstart"))
axlUIWPrint(nil 'info axlFormMsg(fw "drcdone"))
```

**12.3** 简单字符串提示可使用 `axlUIPrompt`，数据浏览提示应当使用 `axlUIDataBrowse`。`axlUIPrompt` 的返回值需要验证，避免用户取消后传入 `nil` 导致后续逻辑崩溃。

> **依据**：`change_net_on_vias.il` 中 `axlUIDataBrowse` 的使用（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\cmds\change_net_on_vias.il`）。
>
> ```skill
net = cadr(axlUIDataBrowse('NET '(RETRIEVE_OBJECT) "New Net Name" t))
when(net
    axlDBCloak('_RPVdoNetReplacement( vias net ) 'shape)
)
```

---

## 13. 图形与自定义绘制规范

**13.1** 表单中的自定义绘制区域（`THUMBNAIL` 或图形控件）应当使用 `axlGRPDrwInit` 初始化绘制句柄，并通过回调函数进行绘制。绘制属性（`fill`、`color`、`width`）应当使用 `putprop` 设置到句柄上，而非直接传入绘制函数。

> **依据**：`axlform.il` 中 `bitmap_callback` 和 `graphic_callback` 的实现（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\form\basic\axlform.il`）。
>
> ```skill
bitmap_handle = axlGRPDrwInit(fw "bitmap" 'FlipIt)
bitmap_handle->Flip = 0
...

(defun bitmap_callback (handle)
    (axlGRPDrwMapWindow handle 232 60)
    (putprop handle "unfilled" 'fill)
    (putprop handle "black" 'color)
    (putprop handle 2 'width)

    (axlGRPDrwRectangle handle '(1 1) '(249 54))
    (axlGRPDrwBitmap handle "test.bmp")
)

(defun graphic_callback (handle)
    (axlGRPDrwMapWindow handle 1200 1800)
    (putprop handle "unfilled" 'fill)
    (putprop handle "red" 'color)
    (putprop handle 3 'width)
    (axlGRPDrwRectangle handle '(1 1) '(1200 1800))
    ...
)
```

**13.2** 绘制区域的更新应当使用 `axlGRPDrwUpdate`，通常在表单字段事件（如 `"redraw"` 按钮）中触发。禁止在绘制回调中直接调用 `axlGRPDrwUpdate` 造成递归。

> **依据**：`axlform.il` 中重绘按钮的处理（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\form\basic\axlform.il`）。
>
> ```skill
("redraw"
    axlGRPDrwUpdate(fw->Bitmap_handle)
    axlGRPDrwUpdate(fw->Graphic_handle)
)
```

---

## 14. 最佳实践与性能优化

**14.1** 表单相关的 SKILL 代码中，若频繁调用同一组 API，可以使用 `alias` 定义简写，但 `alias` 应当定义在文件顶部或局部作用域中，并附带注释说明。禁止在公共函数内部定义 `alias` 导致作用域污染。

> **依据**：`axlform.il` 顶部的 `alias` 定义（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\form\basic\axlform.il`）。
>
> ```skill
; These make playing wirh form capabilities easier
alias fset axlFormSetField
alias fdelete axlFormListDeleteAll
alias fget axlFormGetField
alias finfo axlFormSetInfo
alias fsel  axlFormListSelect
alias wecho axlUIWPrint
```

> **依据**：`axlviewfile.il` 顶部的 `alias` 定义（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\ui\axlviewfile.il`）。
>
> ```skill
alias ex axlUIWExpose
alias cl axlUIWClose
```

**14.2** 在表单需要与 Allegro 数据库交互时，应当遵循 "先验证、后提交" 原则。在 `apply` 或 `done` 事件中统一执行数据库写操作，禁止在单个字段的 `change` 事件中直接修改数据库，以避免不一致状态。

> **依据**：`cns-design.il` 中 `_AcDesignValidate` 与 `_AcDesignDoit` 的分离设计（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\cmds\cns-design.il`）。
>
> ```skill
; 字段变更时仅验证并启用 Apply 按钮
procedure( _AcDesignValidate(fw)
    ...
    _AcDesignApplyGray(fw t)
)

; Apply / Done 时统一提交到数据库
procedure( _AcDesignDoit(fw)
    axlCNSMapClear()
    items = axlCNSDesignValueGet('all t)
    foreach( item items
        prop = car(item)
        field = strcat( get_pname(prop) fw->_cnsDsnSep fw->_cnsDsnValue)
        value = axlFormGetField(fw field)
        unless( (value == cadr(item))
            axlCNSDesignValueSet(prop value)
        )
    )
    axlCNSMapUpdate()
)
```

**14.3** 当表单在交互命令中使用时（如约束设计界面），应当使用 `axlEnterEvent` 监听外部事件（`DONE`、`CANCEL`），并在事件发生时自动关闭表单或保存状态，确保 Allegro 命令栈的正确切换。

> **依据**：`cns-design.il` 中 `_AcDesignEvent` 的事件循环（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\cmds\cns-design.il`）。
>
> ```skill
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
```

**14.4** 对于表单文件中的字段布局，应当优先使用 `TILE` 和 `FLEX` 实现自适应布局，避免在 SKILL 代码中硬编码坐标进行动态调整。若表单需要支持多分辨率或窗口缩放，必须在 `.form` 文件中定义 `FLEXMODE` 和 `FLEX` 规则。

> **依据**：`axlform.form` 中 `FLEXMODE` 和 `FLEX` 的定义（`D:\Cadence\SPB_17.4\share\pcb\examples\skill\form\basic\axlform.form`）。
>
> ```text
FLEXMODE edgegravity
FLEX tab 0 0 1 1
FLEX listfield 0 0 1 1
FLEX tree 0 0 1 1
FLEX progress 0 0 1 0
FLEX bmp1 0 0 1 1
FLEX stc 0.5 0 0 0
```

---

## 15. 附录：示例代码汇总

### 15.1 最小完整表单示例（`helptip.il` + `helptip.form`）

```skill
; D:\Cadence\SPB_17.4\share\pcb\examples\skill\form\basic\helptip.il
unless(boundp('_heltip_fw) _heltip_fw = nil)

procedure( helptip()
    let( (fw)
    fw = axlFormCreate('_heltip_fw "helptip"
            '("msgLines" 0) 'heltip_CB t nil)
    axlFormDisplay(fw)
))

procedure( heltip_CB(fw)
    prog(()
     unless((fw->doneState == 0)
         axlFormClose(fw)
         return(t)
     )
))
```

```text
# D:\Cadence\SPB_17.4\share\pcb\examples\skill\form\basic\helptip.form
FILE_TYPE=FORM_DEFN VERSION=2
FORM
FIXED
PORT 24 6
HEADER "Help Tip Example"

TILE

TEXT "Count:"
TLOC 2 2
ENDTEXT
TEXT
TLOC 7 2
INFO count 8
ENDTEXT

FIELD close
FLOC 8 8
MENUBUTTON "Close" 10 4
ENDFIELD

ENDTILE

ENDFORM
```

### 15.2 复杂表单 + 数据库交互示例（`cns-design.il` 核心结构）

```skill
; D:\Cadence\SPB_17.4\share\pcb\examples\skill\cmds\cns-design.il
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

    fw->_change = t
    fw->_cnsDsnSep = "."
    fw->_cnsDsnValue = "value"

    _AcDesignTier(fw)
    _AcDesignRefresh(fw)

    axlFormDisplay(fw)
    _AcDesignEvent()
    )
)

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
    ("apply"
        _AcDesignDoit(fw)
        _AcDesignApplyGray(fw nil)
    )
    (t
        _AcDesignValidate(fw)
    )
    )
)
```

### 15.3 动态颜色弹出菜单示例（`colorTest.il`）

```skill
; D:\Cadence\SPB_17.4\share\pcb\examples\skill\form\color\colorTest.il
unless(boundp('ct) ct = nil)

defun( colorTest ()
    let( (form colorList colorString color)
    form = axlFormCreate('ct "colorTest" nil 'colorTestDispatch t)
    ct = form

    for(i 1 axlColorGet('count)
        color = axlColorGet(i);
        colorString = sprintf(nil "i=%L, r=%L, g=%L, b=%L" i car(color) cadr(color) caddr(color))
        colorList = cons(list(colorString i i) colorList)
    );
    colorList = reverse(colorList);
    axlFormBuildPopup(form "COLOR_LIST" colorList);
    axlFormDisplay(form);
))

defun( colorTestDispatch (fw)
    printf("field/value %L = %L (int %L\n)"
        fw->curField fw->curValue, fw->curValueInt )
    if((nequal fw->doneState 0) axlFormClose(fw))
    nil
)
```

### 15.4 菜单注册示例（`menu.il`）

```skill
; D:\Cadence\SPB_17.4\share\pcb\examples\skill\ui\menu.il
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
```

### 15.5 计时器 + 进度条示例（`timer.il` + `timer_example.form`）

```skill
; D:\Cadence\SPB_17.4\share\pcb\examples\skill\ui\timer.il
unless(boundp('timerFw) timerFw = nil)

procedure( timerFormCB(fw)
   case(fw->curField
        ("close"
            axlUIWTimerRemove(fw->_timerId)
            axlFormClose(fw))
   )
)

procedure( timerCBForForm( window timerId elapsedTime)
      timerId->_cnt = timerId->_cnt +1
      axlFormSetField(timerId->_fw "count" timerId->_cnt)
      axlFormSetField(timerId->_fw "progress" nil)
)

procedure( timerForm()
    let((fw)
     fw = axlFormCreate( 'timerFw "timer_example" '("C" "INNER" "MSGLINES" 0) 'timerFormCB
                nil)
     timerId = axlUIWTimerAdd(nil 2000 nil 'timerCBForForm)
     timerId->_fw = fw
     timerId->_cnt = 0
     fw->_timerId = timerId

     axlFormSetField(fw "progress" '(5 100 1))
     axlFormDisplay(fw)
))
```

```text
# D:\Cadence\SPB_17.4\share\pcb\examples\skill\ui\timer_example.form
FILE_TYPE=FORM_DEFN VERSION=2
FORM
FIXED
PORT 24 6
HEADER "Timer Progress Example"

TILE

TEXT "Count:"
TLOC 2 2
ENDTEXT
TEXT
TLOC 7 2
INFO count 8
ENDTEXT

TEXT "Meter:"
TLOC 2 4
ENDTEXT

FIELD progress
FLOC 7 4
PROGRESS 16 3
ENDFIELD

FIELD close
FLOC 8 8
MENUBUTTON "Stop" 10 4
ENDFIELD

ENDTILE

ENDFORM
```

---

> **文件路径索引**
>
> 本章规范引用的所有示例代码均来自以下官方路径：
> - `D:\Cadence\SPB_17.4\share\pcb\examples\skill\form\basic\axlform.il`
> - `D:\Cadence\SPB_17.4\share\pcb\examples\skill\form\basic\axlform.form`
> - `D:\Cadence\SPB_17.4\share\pcb\examples\skill\form\basic\helptip.il`
> - `D:\Cadence\SPB_17.4\share\pcb\examples\skill\form\color\colorTest.il`
> - `D:\Cadence\SPB_17.4\share\pcb\examples\skill\cmds\cns-design.il`
> - `D:\Cadence\SPB_17.4\share\pcb\examples\skill\cmds\acns_design.form`
> - `D:\Cadence\SPB_17.4\share\pcb\examples\skill\ui\menu.il`
> - `D:\Cadence\SPB_17.4\share\pcb\examples\skill\ui\timer.il`
> - `D:\Cadence\SPB_17.4\share\pcb\examples\skill\ui\timer_example.form`
> - `D:\Cadence\SPB_17.4\share\pcb\examples\skill\ui\axlviewfile.il`
> - `D:\Cadence\SPB_17.4\share\pcb\examples\skill\ui\ashmeter.il`
> - `D:\Cadence\SPB_17.4\share\pcb\examples\skill\ui\ashmeter.form`
> - `D:\Cadence\SPB_17.4\share\pcb\examples\skill\README.txt`
> - `D:\Cadence\SPB_17.4\share\pcb\examples\skill\disclaimer.il`
> - `D:\Cadence\SPB_17.4\share\pcb\examples\skill\cmds\cline2shape.il`
> - `D:\Cadence\SPB_17.4\share\pcb\examples\skill\cmds\change_net_on_vias.il`
