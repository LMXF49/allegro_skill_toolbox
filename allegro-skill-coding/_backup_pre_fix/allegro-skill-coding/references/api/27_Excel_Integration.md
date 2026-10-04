# 第 27 章 Excel 集成 (Excel Integration)

## Microsoft Excel 集成函数 (Microsoft Excel Integration Functions)

**产品文档**: Allegro SKILL Reference  
**产品版本**: 17.4-2019, October 2019

---

## axlSpreadsheetClose

**说明**：释放内存中的电子表格文档。所有信息都被释放。每当您完成处理活动电子表格文档时，都应调用此函数。

一旦电子表格信息被释放，您就无法访问有关它的任何数据。这包括检索样式信息、单元格内容、工作表列表等。您需要在调用此函数之前检索任何需要在电子表格释放后引用的信息。

如果没有活动电子表格，此函数不执行任何操作。

**Original**: Releases the spreadsheet document in memory. All information is freed. This function should be called whenever you have completed working with the active spreadsheet document. Once the spreadsheet information is released, you cannot access any data about it. This includes retrieving style information, cell contents, lists of worksheets, etc. Any such information that you need to reference after the spreadsheet is freed should be retrieved prior to this call. If there is no active spreadsheet, this function does nothing.

**语法**：
```skill
axlSpreadsheetClose()
```

**参数**：无

**返回值**：
- `t` — 电子表格信息已成功释放。

**示例**：
```skill
axlSpreadsheetInit()
==> t
axlSpreadsheetSetWorksheet("First")
==> t
axlSpreadsheetDefineCell(1 1 "Default" "String" "Hello")
==> t
axlSpreadsheetWrite("example.xml")
==> t
axlSpreadsheetClose()
==> t
```

**另请参阅**：`axlSpreadsheetInit`, `axlSpreadsheetRead`, `axlSpreadsheetWrite`

---

## axlSpreadsheetDefineCell

**说明**：完全定义活动工作表中的单个单元格。此函数比调用 `axlSpreadsheetSetCell` 后接多个 `axlSpreadsheetSetCellProp` 调用更高效。

**Original**: Completely defines a single cell in the active worksheet. This function is more efficient than calling axlSpreadsheetSetCell with multiple axlSpreadsheetSetCellProp calls afterwards.

**语法**：
```skill
axlSpreadsheetDefineCell(x_row x_col t_style t_type t_value)
```

**参数**：
- `x_row` — 所需单元格的行索引（基于 1）。
- `x_col` — 所需单元格的列索引（基于 1）。
- `t_style` — 应用于此单元格的样式名称 / `nil` 表示默认值。
- `t_type` — 此单元格的类型定义 / `nil` 表示默认值（字符串）。
- `t_value` — 单元格值 / `nil` 表示空。

**返回值**：
- `t` — 单元格已成功定义。
- `nil` — 单元格未定义。请参阅控制台了解原因。

**示例**：
```skill
axlSpreadsheetDefineCell(1 1 "Default" "String" "Hello")
==> t
```

**另请参阅**：`axlSpreadsheetGetCell`, `axlSpreadsheetSetCell`, `axlSpreadsheetSetCellProp`

---

## axlSpreadsheetDoc

**说明**：`axlSpreadsheet` 函数族允许您从 SKILL 中读取和写入 Microsoft 的基于开放式 XML 的电子表格格式。您可以从活动 Allegro 工具中的数据创建电子表格，也可以读取电子表格并从中提取信息以更新您的数据库。

单个函数的文档单独提供。此条目提供概述，以及如何使用 API 例程的小示例。

**Original**: The axlSpreadsheet family of functions allow you to read and write Microsoft's open XML-based spreadsheet format from within SKILL. You can create a spreadsheet from data within your active Allegro tool, or you can read a spreadsheet and extract information from it to update your database. Documentation for individual functions is separately available. This entry provides an overview, as well as a small example of how to use the API routines together.

**示例**：
以下是一个简单示例，它创建一个小的、双工作表的电子表格，带有一些格式样式定义和单元格，这些单元格在使用 Microsoft Excel 等工具查看电子表格时使用这些样式来格式化其内容。

```skill
procedure(spreadsheetExample()
  ; 初始化一个空电子表格。
  ; 注意，在您希望将电子表格写入磁盘之前，
  ; 不需要提供名称。
  axlSpreadsheetInit()
  
  ; 定义初始默认样式。
  ; 样式可以在电子表格构造期间的任何点定义，
  ; 但必须在被任何行、列或单元格引用之前定义。
  axlSpreadsheetSetStyle("Default" nil)
  axlSpreadsheetSetStyleProp("Alignment" "Vertical" "Top")
  axlSpreadsheetSetStyleProp("Alignment" "Horizontal" "Left")
  axlSpreadsheetSetStyleProp("Alignment" "WrapText" "1")
  
  ; 定义第二个样式，继承自 Default 样式，
  ; 包含细边框轮廓并指定红色背景填充。
  axlSpreadsheetSetStyle("Red" "Red Cell")
  axlSpreadsheetSetStyleParent("Default")
  axlSpreadsheetSetStyleBorder("Left" nil "Continuous" "2")
  axlSpreadsheetSetStyleBorder("Right" nil "Continuous" "2")
  axlSpreadsheetSetStyleBorder("Top" nil "Continuous" "2")
  axlSpreadsheetSetStyleBorder("Bottom" nil "Continuous" "2")
  axlSpreadsheetSetStyleProp("Fill" "Color" axlSpreadsheetGetRGBColorString(255 0 0))
  axlSpreadsheetSetStyleProp("Fill" "Pattern" "Solid")
  
  ; 定义电子表格中的第一个工作表。
  axlSpreadsheetSetWorksheet("First")
  
  ; 第一列更宽
  axlSpreadsheetSetColumnProp(1 "Width" "500")
  axlSpreadsheetDefineCell(1 1 "Default" "String" "Default formatted cell")
  axlSpreadsheetDefineCell(1 2 "Red" "String" "Red background cell")
  
  ; 将编译后的电子表格写入磁盘上的 XML 文件。
  axlSpreadsheetWrite("spreadsheet.xml")
  
  ; 关闭并释放编译后的电子表格数据。
  axlSpreadsheetClose()
)
```

---

## axlSpreadsheetGetCell

**说明**：从指定单元格检索数据。

**Original**: Retrieves the data from the specified cell.

**语法**：
```skill
axlSpreadsheetGetCell(x_row x_col)
```

**参数**：
- `x_row` — 要查找的单元格的行索引（基于 1）。
- `x_col` — 要查找的单元格的列索引（基于 1）。

**返回值**：
- `g_cellData` — 定义单元格内容的结构。
- `nil` — 单元格内容当前为空或未定义。

**示例**：
```skill
axlSpreadsheetRead("example.xml")
==> t
axlSpreadsheetSetWorksheet("First")
==> t
g_cell = axlSpreadsheetGetCell(1 1)
g_cell->??
==> (column 4
     row    1
     data   "a"
     type   "String"
     style  "Default"
    )
axlSpreadsheetClose()
==> t
```

**另请参阅**：`axlSpreadsheetSetCell`, `axlSpreadsheetSetCellProp`, `axlSpreadsheetDefineCell`

---

## axlSpreadsheetGetRGBColorString

**说明**：给定红、绿、蓝颜色值，返回 RGB 字符串，用于 Microsoft 开放式电子表格格式所需的电子表格样式定义。

**Original**: Given red, green, and blue color values, return an RGB string for use in spreadsheet style definitions in format required for Microsoft open spreadsheet format.

**语法**：
```skill
axlSpreadsheetGetRGBColorString(x_red x_green x_blue)
```

**参数**：
- `x_red` — 红色整数值（0-255）。
- `x_green` — 绿色整数值（0-255）。
- `x_blue` — 蓝色整数值（0-255）。

**返回值**：
- `t_rgb` — 表示传入 RGB 值的颜色值的字符串。
- `nil` — 传入非法值（超出合法范围）。

**示例**：
```skill
axlSpreadsheetGetRGBColorString(255 0 0)
==> "#ff0000"
```

**另请参阅**：`axlSpreadsheetGetRGBColorString`, `axlSpreadsheetGetRGBForNamedColor`

---

## axlSpreadsheetGetRGBForNamedColor

**说明**：电子表格有一小组已知的预定义颜色值。要检索特定命名颜色的 RGB 值，请将该颜色名称传递给此函数。

**Original**: Spreadsheets have a small set of known, pre-defined color values. To retrieve the RGB value for a specific named color, pass that color name to this function.

**语法**：
```skill
axlSpreadsheetGetRGBForNamedColor(t_name)
```

**参数**：
- `t_name` — 要检索 RGB 值的颜色名称。

**返回值**：
- `t_rgb` — 表示传入颜色值的 RGB 值的字符串。
- `nil` — 在标准颜色列表中未找到颜色名称。

**示例**：
```skill
axlSpreadsheetGetRGBForNamedColor("cyan")
==> "#00FFFF"
```

**另请参阅**：`axlSpreadsheetGetRGBColorString`

---

## axlSpreadsheetGetStyles

**说明**：检索为活动电子表格定义的所有样式的列表。如果当前没有工作表，则返回 `nil`。

**Original**: Retrieves a list of all the styles defined for the active spreadsheet. If no worksheets currently exist, nil is returned.

**语法**：
```skill
axlSpreadsheetGetStyles()
```

**参数**：无

**返回值**：
- `l_styles` — 样式名称和 ID 的列表，成对（ID, name）。
- `nil` — 当前未定义工作表 / 没有活动电子表格。

**示例**：
```skill
axlSpreadsheetRead("example.xml")
==> t
axlSpreadsheetGetStyles()
==> (("Default" "DEFAULT") ("Title" "TITLE") ("Data" "DATA"))
axlSpreadsheetClose()
==> t
```

**另请参阅**：`axlSpreadsheetSetWorksheet`, `axlSpreadsheetGetWorksheets`

---

## axlSpreadsheetGetWorksheets

**说明**：检索活动电子表格中定义的所有工作表的列表。如果当前没有工作表，则返回 `nil`。

**Original**: Retrieves a list of all the worksheets defined in the active spreadsheet. If no worksheets currently exists, nil is returned.

**语法**：
```skill
axlSpreadsheetGetWorksheets()
```

**参数**：无

**返回值**：
- `l_worksheets` — 工作表名称列表（按电子表格中的顺序）。
- `nil` — 当前未定义工作表 / 没有活动电子表格。

**示例**：
```skill
axlSpreadsheetRead("example.xml")
==> t
axlSpreadsheetGetWorksheets()
==> ("First" "Second")
axlSpreadsheetClose()
==> t
```

**另请参阅**：`axlSpreadsheetSetWorksheet`

---

## axlSpreadsheetGetWorksheetSize

**说明**：返回当前工作表的"大小"，即具有数据的最高行和列。

**Original**: Return the "size" of the current worksheet, in terms of the highest row and column which have data.

**语法**：
```skill
axlSpreadsheetGetWorksheetSize()
```

**参数**：无

**返回值**：
- `l_rowsColumns` — `(maxRow, maxColumn)`。
- `nil` — 当前未定义工作表 / 没有活动电子表格。

**示例**：
```skill
axlSpreadsheetRead("example.xml")
==> t
axlSpreadsheetSetWorksheet("First")
==> t
axlSpreadsheetGetWorksheetSize()
==> (5 5)
axlSpreadsheetClose()
==> t
```

**另请参阅**：`axlSpreadsheetSetWorksheet`

---

## axlSpreadsheetInit

**说明**：初始化一个空电子表格文档，以开始用工作表、样式和单元格数据填充它。新电子表格首次初始化时，不包含任何此类信息。它是完全空的。

如果内存中已有活动电子表格，它将被关闭。一次只能有一个活动电子表格。

**Original**: Initializes an empty spreadsheet document to begin filling it with worksheets, styles, and cell data. A new spreadsheet, when first initialized, does not include any of this information. It is completely empty. If there is a spreadsheet already active in memory, it will be closed. Only one spreadsheet may be active at a time.

**语法**：
```skill
axlSpreadsheetInit()
```

**参数**：无

**返回值**：
- `t` — 电子表格已成功初始化。
- `nil` — 无法初始化空电子表格。原因打印到控制台。

**示例**：
```skill
axlSpreadsheetInit()
==> t
axlSpreadsheetSetWorksheet("First")
==> t
axlSpreadsheetDefineCell(1 1 "Default" "String" "Hello")
==> t
axlSpreadsheetWrite("example.xml")
==> t
axlSpreadsheetClose()
==> t
```

**另请参阅**：`axlSpreadsheetClose`, `axlSpreadsheetRead`, `axlSpreadsheetWrite`

---

## axlSpreadsheetRead

**说明**：将磁盘上的电子表格文件读入内存以进行数据访问和操作。文件应为 Microsoft XML 开放式电子表格格式。对于文本分隔文件，请使用 `axlSpreadsheetReadDelimited`。

**Original**: Read a spreadsheet file on disk into memory for data access and manipulation. File is expected to be in Microsoft XML open spreadsheet format. For text-delimited files, use axlSpreadsheetReadDelimited.

**语法**：
```skill
axlSpreadsheetRead(t_fileName)
```

**参数**：
- `t_fileName` — 要读取的磁盘上电子表格文件的名称。

**返回值**：
- `t` — 电子表格已成功读取；可以查询。
- `nil` — 无法读取电子表格文件。

**示例**：
```skill
axlSpreadsheetRead("example.xml")
==> t
...
axlSpreadsheetGetCell(1 1)
...
axlSpreadsheetClose()
==> t
```

**另请参阅**：`axlSpreadsheetClose`, `axlSpreadsheetInit`, `axlSpreadsheetWrite`, `axlSpreadsheetReadDelimited`

---

## axlSpreadsheetReadDelimited

**说明**：将磁盘上的文本文件读入内存以作为电子表格进行数据访问和操作。文件应为分隔文本文件，单元格分隔符在 `t_delimiter` 参数中指定。对于 XML 电子表格，请使用 `axlSpreadsheetRead`。

**Original**: Read a text file on disk into memory for data access and manipulation as a spreadsheet. File is expected to be a delimited text file, with cell delimiters as specified in the t_delimiter argument. For XML spreadsheets, use axlSpreadsheetRead.

**语法**：
```skill
axlSpreadsheetReadDelimited(t_fileName, t_delimiter)
```

**参数**：
- `t_fileName` — 要读取的磁盘上文本文件的名称。
- `t_delimited` — 用于分隔文本文件中"单元格"的分隔符字符。

**返回值**：
- `t` — 文件已成功读取；可以查询。
- `nil` — 无法读取电子表格文件。

**示例**：
```skill
axlSpreadsheetRead("example.txt", ",")
==> t
...
axlSpreadsheetGetCell(1 1)
...
axlSpreadsheetClose()
==> t
```

**另请参阅**：`axlSpreadsheetRead`

---

## axlSpreadsheetSetCell

**说明**：将当前工作表的当前行/列设为活动状态。

**Original**: Make the active row/column of the current worksheet active.

**语法**：
```skill
axlSpreadsheetSetCell(x_row x_col)
```

**参数**：
- `x_row` — 要激活的单元格的行索引（基于 1）。
- `x_col` — 要激活的单元格的列索引（基于 1）。

**返回值**：
- `t` — 单元格已成功激活。
- `nil` — 单元格未激活。请参阅控制台了解原因。

**示例**：
```skill
axlSpreadsheetSetCell(1 1)
==> t
```

**另请参阅**：`axlSpreadsheetGetCell`, `axlSpreadsheetSetCellProp`, `axlSpreadsheetDefineCell`

---

## axlSpreadsheetSetCellProp

**说明**：在电子表格的活动单元格上设置属性。

**Original**: Sets a property on the active cell in the spreadsheet.

**语法**：
```skill
axlSpreadsheetSetCellProp(t_propName t_propVal)
```

**参数**：
- `t_propName` — 要设置的属性。允许值为：STYLE、TYPE、FORMULA 或 VALUE。
- `t_propVal` — 要将此属性设置的值。

**返回值**：
- `t` — 单元格属性已成功设置。
- `nil` — 属性未设置（没有活动单元格或无效属性）。请参阅控制台了解详细信息。

**支持的值**：
- `STYLE` — 字符串值，给出已在活动电子表格中定义的样式 ID。
- `TYPE` — Number、DateTime、Boolean、String 或 Error。
- `FORMULA` — 任何表示正确格式化的电子表格公式的字符串，用于评估。公式未由此接口验证正确性。
- `VALUE` — 提供单元格内容的任何字符串。

**示例**：
```skill
axlSpreadsheetSetCell(1 1)
==> t
axlSpreadsheetSetCellProp("VALUE" "New Value")
==> t
```

**另请参阅**：`axlSpreadsheetSetCell`, `axlSpreadsheetGetCell`, `axlSpreadsheetDefineCell`

---

## axlSpreadsheetSetColumnProp

**说明**：为活动工作表的给定列设置属性。

**Original**: Sets a property for the given column of the active worksheet.

**语法**：
```skill
axlSpreadsheetSetColumnProp(x_column t_propName t_propVal)
```

**参数**：
- `x_column` — 要设置属性的列索引。
- `t_propName` — 要设置的属性。允许值为：AUTO_WIDTH、WIDTH 和 STYLE。
- `t_propVal` — 要将此属性设置的值。

**支持的值**：
- `AUTO_WIDTH` — 布尔值（0 或 1）。
- `WIDTH` — 字体点中的正整数值。
- `STYLE` — 当前在活动文档中定义的样式 ID 名称。

这些语句以及任何其他语句，不会被 SKILL API 评估。它们将由打开文档的电子表格工具评估。该工具可以自行决定 AUTO_WIDTH 或 WIDTH 标签的评估优先级。例如，SKILL API 不会评估 AUTO_WIDTH 或其他指令。

**返回值**：
- `t` — 属性已设置在列上。
- `nil` — 属性未设置。原因打印到控制台。

**示例**：
```skill
axlSpreadsheetSetRowProp(1 "AUTO_WIDTH" "1")
```

**另请参阅**：`axlSpreadsheetSetRowProp`

---

## axlSpreadsheetSetDocProp

**说明**：在文档（电子表格）本身上设置属性。

**Original**: Sets a property on the document (spreadsheet) itself.

**语法**：
```skill
axlSpreadsheetSetDocProp(t_propName t_propVal)
```

**参数**：
- `t_propName` — 要设置的属性。允许值为：AUTHOR、LAST_AUTHOR、DATE、COMPANY 或 VERSION。
- `t_propVal` — 要将此属性设置的值。

**返回值**：
- `t` — 文档属性已成功设置。
- `nil` — 属性未设置（没有活动电子表格或无效属性）。请参阅控制台了解详细信息。

**示例**：
```skill
axlSpreadsheetInit()
==> t
axlSpreadsheetSetDocProp("AUTHOR" "John")
==> t
axlSpreadsheetSetDocProp("AUTHOR" "Doe")
==> t
axlSpreadsheetWrite("example.xml")
==> t
axlSpreadsheetClose()
==> t
```

---

## axlSpreadsheetSetRowProp

**说明**：为活动工作表的给定行设置属性。

**Original**: Sets a property for the given row of the active worksheet.

**语法**：
```skill
axlSpreadsheetSetRowProp(x_row t_propName t_propVal)
```

**参数**：
- `x_row` — 要设置属性的行索引。
- `t_propName` — 要设置的属性。允许属性为 AUTO_HEIGHT、HEIGHT 和 STYLE。
- `t_propVal` — 要将此属性设置的值。

**支持的值**：
- `AUTO_HEIGHT` — 布尔值（0 或 1）。
- `HEIGHT` — 字体点中的正整数值。
- `STYLE` — 当前在活动文档中定义的样式 ID 名称。

这些语句以及任何其他语句，不会被 SKILL API 评估。它们将由打开文档的电子表格工具评估。该工具可以自行决定 AUTO_HEIGHT 或 HEIGHT 标签的评估优先级。例如，SKILL API 不会评估 AUTO_HEIGHT 或其他指令。

**返回值**：
- `t` — 属性已设置在行上。
- `nil` — 属性未设置。原因打印到控制台。

**示例**：
```skill
axlSpreadsheetSetRowProp(1 "AUTO_HEIGHT" "1")
```

**另请参阅**：`axlSpreadsheetSetColumnProp`

---

## axlSpreadsheetSetStyle

**说明**：在活动电子表格中定义或激活指定样式。样式可以在电子表格的任何工作表中引用。您无需为创建的每个新工作表重新定义样式。

**Original**: Defines or activates the specified style in the active spreadsheet. Styles may be referenced in any worksheet of the spreadsheet. You do not need to redefine the style for each new worksheet you create.

**语法**：
```skill
axlSpreadsheetSetStyle(t_id t_name)
```

**参数**：
- `t_id` — 此样式的电子表格 ID。
- `t_name` — 此样式的用户"名称" / `nil`。这是在 Excel 样式编辑器和选择下拉菜单中为此样式显示的名称。

**返回值**：
- `t` — 样式已成功激活 / 定义。
- `nil` — 样式未激活。原因写入控制台。

**示例**：
```skill
axlSpreadsheetSetStyle("Default" nil)
==> t
axlSpreadsheetSetStyleProp("Alignment" "Vertical" "Top")
==> t
```

**另请参阅**：`axlSpreadsheetSetCell`, `axlSpreadsheetSetWorksheet`

---

## axlSpreadsheetSetStyleBorder

**说明**：为活动样式定义设置单元格边框属性。

**Original**: Sets the cell border properties for a active style definition.

**语法**：
```skill
axlSpreadsheetSetStyleBorder(t_position t_color t_lineStyle t_weight)
```

**参数**：
- `t_position` — 位置必须是接受的 Microsoft 位置之一（Left、Right、Top、Bottom 等）。
- `t_color` — Microsoft 颜色名称或 RGB 值（例如，"BLACK" 或 #FF00AA）。
- `t_lineStyle` — 要使用的线样式（通常为 "Continuous" 表示实线）。
- `t_weight` — 线的粗细，以字体点为单位。必须是正整数。

**不同参数支持的值**：

| Argument（参数） | Supported Values（支持的值） |
|---|---|
| POSITION | Left, Top, Right, Bottom, DiagonalLeft, or DiagonalRight |
| COLOR | RGB 值格式 "#RRGGBB" 或预定义名称表中的颜色名称 |
| LINE_STYLE | None, Continuous, Dash, Dot, DashDot, DashDotDot, SlashDashDot, or Double |
| WEIGHT | 字体点中的正整数值 |

**返回值**：
- `t` — 边框样式已成功设置。
- `nil` — 边框样式未设置（没有活动样式或无效参数）。请参阅控制台了解详细信息。

**示例**：
```skill
axlSpreadsheetSetStyle("Second" "Second Style")
==> t
axlSpreadsheetSetStyleParent("Default")
==> t
axlSpreadsheetSetStyleBorder("Left" nil "Continuous" "2")
==> t
axlSpreadsheetSetStyleBorder("Right" nil "Continuous" "2")
==> t
axlSpreadsheetSetStyleBorder("Top" nil "Continuous" "2")
==> t
axlSpreadsheetSetStyleBorder("Bottom" nil "Continuous" "2")
==> t
```

**另请参阅**：`axlSpreadsheetSetStyle`, `axlSpreadsheetSetStyleProp`, `axlSpreadsheetSetStyleParent`, `axlSpreadsheetGetRGBColorString`

---

## axlSpreadsheetSetStyleParent

**说明**：设置活动样式的父样式。样式将从其父样式继承默认属性，因此只需在子样式中指定更改。父样式必须已在电子表格中定义。

**Original**: Sets the active style's parent. Style will inherit default properties from its parent style, therefore only changes need to be specified in the child style. Parent must already be defined for spreadsheet.

**语法**：
```skill
axlSpreadsheetSetStyleParent(t_parent)
```

**参数**：
- `t_parent` — 要链接到的父样式 ID。请注意，父样式必须先定义，然后才能被其子样式引用。

**返回值**：
- `t` — 样式父样式已成功设置。
- `nil` — 父样式未设置（没有活动样式或父样式不存在）。请参阅控制台了解详细信息。PARENT 值必须是活动电子表格文档中定义的样式 ID。

**示例**：
```skill
axlSpreadsheetSetStyle("Second" "Second Style")
==> t
axlSpreadsheetSetStyleParent("Default")
==> t
axlSpreadsheetSetStyleProp("Alignment" "Horizontal" "Center")
==> t
```

**另请参阅**：`axlSpreadsheetSetStyle`, `axlSpreadsheetSetStyleBorder`, `axlSpreadsheetSetStyleProp`

---

## axlSpreadsheetSetStyleProp

**说明**：在活动样式定义中设置特定样式属性。

**Original**: Sets a specific style property in the active style definition.

**语法**：
```skill
axlSpreadsheetSetStyleProp(t_type t_propName t_propVal)
```

**参数**：
- `t_type` — 要设置的属性类型。必须是以下之一：ALIGNMENT、FONT、FILL、NUMBER_FORMAT、PROTECTION。
- `t_propName` — 要设置的属性名称（因类型而异）。
- `t_propVal` — 要将属性设置的值。

**返回值**：
- `t` — 样式属性已成功设置。
- `nil` — 属性未设置（没有活动样式或无效参数）。请参阅控制台了解详细信息。

**ALIGNMENT 属性支持的值**：

| Property（属性） | Values Supported...（支持的值） |
|---|---|
| Horizontal | Automatic, Left, Center, Right, Fill, Justify, CenterAcrossSelection, JustifyDistributed, or Distributed |
| Indent | 字符宽度中要缩进的正整数值 |
| ReadingOrder | RightToLeft, LeftToRight, or Context |
| Rotate | 旋转角度（度） |
| ShrinkToFit | 布尔值（0 或 1） |
| Vertical | Automatic, Top, Bottom, Center, Justify, JustifyDistributed, or Distributed |
| VerticalText | 布尔值（0 或 1） |
| WrapText | 布尔值（0 或 1） |

**FONT 属性支持的值**：

| Property（属性） | Values Supported...（支持的值） |
|---|---|
| Bold | 布尔值（0 或 1） |
| CharSet | 整数值 |
| Color | RGB 值格式 "#RRGGBB" 或预定义名称表中的颜色名称 |
| Family | Automatic, Decorative, Modern, Roman, Swiss, or Script |
| Italic | 布尔值（0 或 1） |
| Outline | 布尔值（0 或 1） |
| Shadow | 布尔值（0 或 1） |
| Size | 字体大小点中的正整数值 |
| StrikeThrough | 布尔值（0 或 1） |
| Underline | None, Single, Double, SingleAccounting, or DoubleAccounting |
| VerticalAlign | None, Subscript, or SuperScript |

**FILL 属性支持的值**：

| Property（属性） | Values Supported...（支持的值） |
|---|---|
| Color | RGB 值格式 "#RRGGBB" 或预定义名称表中的颜色名称 |
| Pattern | None, Solid, Gray75, Gray50, Gray25, Gray125, Gray0625, HorzStripe, VertStripe, ReverseDiagStripe, DiagStripe, DiagCross, ThickDiagCross, ThinHorzStripe, ThinVertStripe, ThinReverseDiagStripe, ThinDiagStripe, ThinHorzCross, or ThinDiagCross |
| PatternColor | RGB 值格式 "#RRGGBB" 或预定义名称表中的颜色名称 |

**NUMBER_FORMAT 属性支持的值**：

| Property（属性） | Values Supported...（支持的值） |
|---|---|
| Format | 定义单元格中数字格式的字符串 |

**PROTECTION 属性支持的值**：

| Property（属性） | Values Supported...（支持的值） |
|---|---|
| Protected | 布尔值（0 或 1） |
| HideFormula | 布尔值（0 或 1） |

**示例**：
```skill
axlSpreadsheetSetStyle("Second" "Second Style")
==> t
axlSpreadsheetSetStyleParent("Default")
==> t
axlSpreadsheetSetStyleProp("Alignment" "Horizontal" "Center")
==> t
```

**另请参阅**：`axlSpreadsheetSetStyle`, `axlSpreadsheetSetStyleBorder`, `axlSpreadsheetSetStyleParent`, `axlSpreadsheetGetRGBColorString`

---

## axlSpreadsheetSetWorksheet

**说明**：将指定工作表设为将来单元格引用的活动工作表。如果工作表不存在，则将其作为文档中的新最后一个工作表创建。

**Original**: Makes the specified worksheet the active one for future cell references. If the worksheet does not exist, it is created as the new last worksheet in the document.

**语法**：
```skill
axlSpreadsheetSetWorksheet(t_name)
```

**参数**：
- `t_name` — 要激活的工作表名称。

**返回值**：
- `t` — 工作表已成功激活 / 定义。
- `nil` — 工作表未激活。原因写入控制台。

**示例**：
```skill
axlSpreadsheetSetWorksheet("First")
==> t
axlSpreadsheetSetColumnProp(1 "Width" "500")
==> t
```

**另请参阅**：`axlSpreadsheetSetCell`, `axlSpreadsheetSetStyle`

---

## axlSpreadsheetWrite

**说明**：将内存中的电子表格写入磁盘文件。文件将以符合 Microsoft 开放式电子表格 XML 格式的方式写入。

**Original**: Write the spreadsheet in memory to file on disk. File will be written compliant with Microsoft's open spreadsheet XML format.

**语法**：
```skill
axlSpreadsheetWrite(t_fileName)
```

**参数**：
- `t_fileName` — 要写入的文件名称，包括路径（如果不写入当前工作目录）。

**返回值**：
- `t` — 文件已成功写入。

**示例**：
```skill
axlSpreadsheetInit()
==> t
axlSpreadsheetSetWorksheet("First")
==> t
axlSpreadsheetDefineCell(1 1 "Default" "String" "Hello")
==> t
axlSpreadsheetWrite("example.xml")
==> t
axlSpreadsheetClose()
==> t
```

指定 `*.xml` 以外的文件扩展名会创建文件，但其格式仍为 Microsoft 开放式电子表格 XML。

**另请参阅**：`axlSpreadsheetClose`, `axlSpreadsheetInit`, `axlSpreadsheetRead`

---

*返回顶部 (Return to top)*
