# 第 22 章 报告与提取 (Reports and Extract)

## 报告与提取函数 (Reports and Extract Functions)

**产品文档**: Allegro SKILL Reference  
**产品版本**: 17.4-2019, October 2019

---

## AXL-SKILL 数据提取函数 (AXL-SKILL Data Extract Functions)

**说明**：本章描述从 Allegro 布局中提取数据并将其写入 ASCII 文件以供外部处理的 AXL-SKILL 函数。

**Original**: The chapter describes the AXL-SKILL functions that extract data from an Allegro layout and write it to an ASCII file for external processing.

---

### axlExtractToFile

**说明**：将当前设计中的数据提取到 ASCII 文件中。执行与 Allegro 批处理命令 `a_extract` 相同的过程。

**Original**: Extracts data from the current design into an ASCII file. Performs the same process as the Allegro batch command a_extract.

**语法**：
```skill
axlExtractToFile(t_viewFile lt_resultFiles [lt_options])
```

**参数**：
- `t_viewFile` — 提取命令文件（view file）的名称。
- `lt_resultFiles` — 提取输出文件名的列表。如果指定一个文件，则输出为字符串而不是列表。最多支持 24 个文件。如果需要超过 24 个视图，请使用多个视图文件。
- `lt_options` — 各种选项的关键字字符串列表：
  - `"crosshatch"` — 提取交叉阴影形状时生成交叉阴影线。
  - `"ok"` — 未知字段名称是可以的。当提取命令文件包含未为正在提取的设计定义的属性名称时很有用。
  - `"short"` — 以短格式提取数据。
  - `"quiet"` — 不在 `stdout` 上打印进度消息。
  - `"mcm"` — 输出 MCM 术语。

**返回值**：
- `t` — 提取完成。
- `nil` — 无法完成提取。请参阅文件 `extract.log` 获取解释性错误消息。

**示例**：
```skill
axlExtractToFile("cmp_rep_view" "my_comp_data")
=> t
```
从当前布局中提取组件数据。将数据写入文件 `my_comp_data.txt`。

---

### axlExtractMap

**说明**：获取使用 Allegro 提取命令文件选择的一组 Allegro 数据库对象，并对每个对象应用您选择的 SKILL 函数。提取命令文件（view）选择对象并设置任何过滤器。由于它不创建输出文件，因此忽略提取命令文件中列出的输出数据字段。

对每个通过 `t_viewFile` 中的选择和过滤条件的对象应用 `s_applyFunc`，即您提供的 SKILL 函数。SKILL 使用两个参数调用 `s_applyFunc` — 对象的 `dbid` 和您作为参数提供的变量 `g_userData`。`g_userData` 可以为 `nil`。如果不是，它通常是一个 `defstruct` 或 `disembodied property list`，以便被调用的例程可以对其进行破坏性更新。

如果 `s_applyFunc` 返回 `nil`，则 `axlExtractMap` 停止执行，将消息 `User CANCEL received` 写入提取日志文件，并返回 `nil`。如果回调函数返回非 `nil`，则执行继续。

如果 `s_applyFunc` 为 `nil`，则 `axlExtractMap` 简单地返回 `l_dbid`，即通过过滤条件的对象的 `dbid` 列表。使用 `l_dbid` 执行 `foreach` 以对每个对象进行操作。（请参阅下面的示例。）

与标准提取到文件的行为略有不同。为 `s_applyFunc` 提供父（旋转）矩形或形状的 `dbid`，而不是单独的线/弧段。在 `FULL GEOMETRY` 视图中返回附加的文本。

Allegro "伪视图"（DRC、ECL、ECS、ECL_NETWORK、PAD_DEF 等）不能与 `axlExtractMap` 一起使用。回调函数永远不会被调用。

`axlExtractMap` 仅提取 AXL-SKILL 可以建模的对象。例如，它不提取功能实例和未放置的组件。

**Original**: Takes a set of Allegro database objects you select using the Allegro extract command file and applies to each object a SKILL function you have chosen. The extract command file (the view) selects the objects and also sets any filters. Ignores the output data fields listed in the extract command file, since it does not create an output file. Applies to each object that passes the selection and filter criteria in s_applyFunc, the SKILL function you supplied. SKILL calls s_applyFunc with two arguments—the dbid of the object and the variable g_userData that you supply as an argument. g_userData may be nil. If not, it normally is a defstruct or disembodied property list so that the called routine can update it destructively. If s_applyFunc returns nil, then axlExtractMap stops execution, writes the message, User CANCEL received to the extract log file, and returns nil. If the callback function returns non nil then execution continues. If s_applyFunc is nil, then axlExtractMap simply returns l_dbid, a list of dbids of the objects that pass the filter criteria. Use l_dbid to perform a foreach to operate on each object. Behaves slightly differently from a standard extract to a file. Provides s_applyFunc with the dbid of the parent (rotated) rectangle or shape, and not individual line/arc segments. Returns the attached text in the FULL GEOMETRY view. Allegro "pseudoviews" may not be used with axlExtractMap. The callback function is never called. axlExtractMap extracts only objects AXL-SKILL can model. For example, it does not extract function instances and unplaced components.

**语法**：
```skill
axlExtractMap(t_viewFile [s_applyFunc] [g_userData])
```

**参数**：
- `t_viewFile` — 提取命令文件（view file）的名称。
- `s_applyFunc` — 为每个选定对象调用的 SKILL 函数。
- `g_userData` — 传递给 `s_applyFunc` 的数据。可以为 `nil`。如果 `s_applyFunc` 为 `nil`，则忽略 `g_userData`。

**返回值**：
- `t` — `s_applyFunc` 为非 `nil`。已将 SKILL 函数应用于指定对象。
- `l_dbid` — 指定对象的 `dbid` 列表。
- `nil` — 无法将 SKILL 函数应用于指定对象。请参阅文件 `extract.log` 获取解释性错误消息。

**示例**：
```skill
; 提供了用户回调 - 使用 (lambda) 函数声明
; 返回所有网络名称的列表
(defun get_netnames()
  ; byReference 是 disembodied prop list
  ; 带有属性 'nets 用于存储网络名称
  (let((byReference (list nil 'nets nil)))
    (axlExtractMap "net_baseview"
      ; 在此处创建的函数
      (lambda(dbid netRef)
        ; 将此网络的名称添加到名称列表
        (putprop netRef
          (cons (get dbid 'name)
                (get netRef 'nets)) 'nets)
        t)      ; 成功返回
      byReference)
    (get byReference 'nets))) ; 返回名称列表
```

---

### axlReportGenerate

**说明**：从 Allegro 可用报告之一生成报告。出于开发目的，如果报告名称为 `'list`，则创建一个文件 `reports_list.txt`，其中包含所有支持的报告的名称。

许多（但不是全部）这些报告都可以通过 OS 级别的 `report` 命令获得。

**注意**：此接口仅支持可通过 `reports` 命令访问的报告。Allegro 有应用程序生成的报告无法通过此接口访问。报告可能会添加或删除，其名称可能会随版本变化。报告格式可能会更改。您可能需要更新代码以适应报告增强功能。

**Original**: This generates a report from one of the Allegro available reports. For development purposes, if the report name is 'list a file, reports_list.txt, is created with the names of all supported reports. Many, but not all, of these reports are available at the OS level via the report command. Cautions: This only supports the reports available via the reports command. Allegro has application generated reports that cannot be accessed via this interface. Reports may be added or deleted and their names may change across releases. Report formats may change. You may need to update the code for report enhancements.

**语法**：
```skill
axlReportGenerate(t_reportName g_showReport [t_fileName])
axlReportGenerate('list nil) -> t
```

**参数**：
- `t_reportName` — 报告名称，或 `'list` 如果您想要报告列表。
- `g_showReport` — 如果为 `t`，向用户显示报告。
- `t_fileName` — 保存报告到指定名称。

**返回值**：
- `t` — 成功。
- `nil` — 参数有问题，接口不知道报告生成是否成功。

**另请参阅**：`axlReportRegister`

**示例**：
```skill
axlReportGenerate("Bill of Material Report" nil "bom.txt")
axlReportGenerate('list nil)
```

---

### axlReportList

**说明**：列出所有注册到 Allegro PCB Editor 报告接口的 SKILL 报告。即使您没有注册任何报告，Allegro PCB Editor 也会注册默认的 SKILL 编写的报告。

**Original**: Lists all the SKILL reports registered to the Allegro PCB Editor report interface. Even if you do not register any reports, Allegro PCB Editor registers default reports written in SKILL.

**语法**：
```skill
axlReportList()
```

**参数**：无。

**返回值**：
- `ll_reportList` — 报告注册列表的列表。每个子列表具有以下格式：`(g_reportCallback t_description t_title)`
- `nil` — 没有注册报告。

**另请参阅**：`axlReportRegister`

---

### axlReportRegister

**说明**：允许使用 Allegro PCB Editor Reports 对话框注册用户报告。您提供报告名称（在对话框中显示）、标题（显示报告时在标题栏中显示）和报告生成回调函数。

回调格式为：传递一个文件名，您应该打开、写入报告并关闭。回调函数格式为：`g_reportCallback(t_outfile)`。

回调函数如果生成报告，应从函数返回 `t`。如果没有生成报告，则返回 `nil`。

如果您提供 `nil` 作为 `t_description`，则当前报告将被注销。您可以在注销模式下忽略 `t_title`。每个回调函数（`g_reportCallback`）只能注册一个报告。

要删除现有报告，请传递分配给报告的回调函数、`nil` 作为 `t_description`，以及空字符串作为 `_title`。

仅当您启用 **HTML-style reports** 时适用。

您可以以两种格式生成报告文件：文本或 HTML。

- **Text**（文本）：文件基于文本。转换包括在以下关键字时插入链接：
  - `(http://)` — 添加 HTML 链接
  - `(num <,> num)`（XY 坐标）— 添加交叉探测链接以缩放到该坐标中心

- **HTML**（超文本标记语言）：文件以 `<HTML>` 开头。要启用 xy 缩放中心，请按以下方式装饰所有 xy 坐标：
  ```html
  <a href="xprobe:xy:<x>,<y>">(x y)</a>
  ```
  示例：xy 坐标为 (310 140)
  ```html
  <a href="xprobe:xy:310.0,140.0">(310.0 140.0)</a>
  ```

**提示和限制**：
- 您的报告描述字符串应以您的公司名称或其他标准开头，以将所有报告一起显示在报告对话框中。保持描述简短，以适应对话框中提供的空间。
- 报告对话框是阻塞的。您不能要求从 Allegro 画布中选择。请勿使用以下：
  - 任何用户选择或选择 API
  - `axlSelect`
  - `axlEnter`
  - `axlShell`
  - 保存或打开绘图
- 您可以在报告回调中调用自己的表单，但确保它是阻塞的（使用 `axlUIWBlock(<formhandle>)`）。
- 提供的 SKILL 回调函数必须返回 `t` 如果您希望报告显示。如果没有任何报告要显示，则返回 `nil`。
- 如果构建一个存储报告函数的上下文，则不能在上下文内部进行 `axlReportRegister`。`axlReportRegister` 必须放在 `allegro.ilinit` 或自动加载文件（`.al`）中（如果构建自动加载上下文）。这与适用于 `axlCmdRegister` 的规则相同。

**Original**: Allows registration of user reports using the Allegro PCB Editor Reports dialog box. You provide a report name (displayed in the dialog), title (displayed in the title bar when the report is shown), and a report-generating callback function. Callback is of format where a filename is passed that you should open, write your report and close. Callback function format is: g_reportCallback(t_outfile). The callback should, if it generates a report, return a t from the function. If it does not generate a report return a nil. If you provide a nil t_description then the current report is unregistered. You can disregard the t_title in the unregister mode. You can register only one report per callback function (g_reportCallback). To delete an existing report, pass the callback function assigned to the report, a nil for the t_description, and an empty string for the _title. Only applicable if you enable the HTML-style reports. You can generate the report file in two formats: text or HTML.

**语法**：
```skill
axlReportRegister(g_reportCallback t_description t_title)
```

**参数**：
- `g_reportCallback` — SKILL 函数的符号或字符串。
- `t_name` — 报告名称（在报告对话框中显示）；如果为 `nil`，将删除与 `g_reportCallback` 关联的报告。
- `t_title` — 显示报告时标题栏中的名称。

**返回值**：
- `t` — 参数正确。报告已注册。
- `nil` — 非法参数。

**示例**：

以下注册报告 "My Hello"。MyReport 中的可选关键字允许直接调用 MyReport 生成固定名称文件 `helloWorld.rpt` 的报告。否则，它从报告对话框中获取名称。

```skill
axlReportRegister('MyReport, "XYZ Inc. Hello" "Hello World")

; 可选关键字允许您使用 nil 调用 MyReport，
; 生成的报告文件将是 helloWorld.rpt。
; 否则，如果从报告对话框调用，将传递一个临时文件名。
procedure(MyReport(@optional (reportName "helloWorld"))
  let((fp)
    fp = axlDMOpenFile("ALLEGRO_REPORT" reportName "w")
    axlLogHeader(fp "This is my report")
    fprintf(fp, "\nHello World\n")
    close(fp)
    t
  ))

; 注销上述报告：
axlReportRegister('MyReport, nil nil)
```

**另请参阅**：`axlReportList`, `axlLogHeader`

---

*返回顶部 (Return to top)*
