# 03. 参数管理 (Parameter Management)

## 概述 (Overview)

本章描述检索和设置 Allegro 数据库参数的 AXL-SKILL 函数。您可以使用这些函数访问某些 Allegro 参数。其他函数构建在 `axlGetParam/axlSetParam` 之上，以使编程更容易。有关可用参数属性的描述，请参阅第 1 章。

使用模型如下：
1. 使用 `axlGetParam` 获取参数。
2. 使用 `axlSetParam` 修改值。
3. 使用 `axlSetParam` 更新参数。

AXL-SKILL 限制您创建新参数或子类。

### axlDBGetTextBlockCount

**说明**：返回定义的文本块（Text Block）数量。

**Original**: Returns a count of the number of text blocks defined.

**参数** (Arguments)：

NA

**返回值** (Value Returned)：

x_textBlockCount
A count of the number of text blocks defined.

**示例** (Examples)：

numTextBlocks = axlDBGetTextBlockCount()
printf("This database has %d text blocks\n" numTextBlocks)

### axlDBGridGet

**说明**：此命令返回当前网格（Grid）值。函数有两种模式：如果网格名称为 `nil`，则返回名称列表；如果给定网格名称，则返回其网格特性（见下文）。保留的网格名称是 `"non-etch"`，否则网格名称遵循 Allegro ETCH 子类名称。使用 `axlDBDisplayControl` 控制网格颜色和可见性。网格具有以下属性：

**Original**: This command returns current grid values. Function has two modes:
if grid name is nil returns list of names
If given a grid name return its grid characteristics (see below)
Reserved grid name is "non-etch" otherwise grid names follow Allegro ETCH subclass names.
Use
axlDBDisplayControl
to control grid color and visibility.
Grids have the following attributes:
Name
Type
objType
string
Name of the object - grids
readOnly
nil
can modify object
name
string
Name of grid
xOrigin
dbrep
X origin of grid
yOrigin
dbrep
Y origin of grid
xMajor
dbrep
Major X spacing of grid (read-only)
yMajor
dbrep
Major Y spacing of grid (read-only)
xGrids
l_dbrep
Spacings X of grid (always a list of dbreps)
yGrids
l_dbrep
Spacings Y of grid (always a list of dbreps)

**语法**：
```skill
axlDBGridGet(
t_gridName)
==> og_grid
```

**参数** (Arguments)：

t_gridName
- **name** — of grid or
nil
- **to** — get all grid names

**返回值** (Value Returned)：

lt_gridds
– list of grids
og_grid
– disembodied property list containing grid settings

**示例** (Examples)：

Run the following code to get all grids and print them.
grids = axlDBGridGet(nil)
foreach(g grids
grd = axlDBGridGet(g)
printf("GRID name=%s  values=%L\n", grd->name, grd))

**参见** (See Also)：

axlDBGridSet

### axlDBGridSet

**说明**：此命令修改设计中的网格设置。除了网格名称（参见 `axlDBGridGet`）之外，还有两个符号网格名称可用：`'all` — 设置所有网格值；`'etch` — 设置所有 ETCH 网格值。为方便起见，在设置单个 `xGrids` 或 `yGrids` 属性时，可以使用浮点数。`xMajor` 和 `yMajor` 值分别由 `xGrids` 和 `yGrids` 中的间距之和自动确定。注意：非蚀刻网格不能具有多个间距，仅使用第一个网格。设置网格不可撤销（将来可能改变）。蚀刻网格名称与 ETCH 层名称相同（将来可能改变）。原点值必须在图形范围内或为 0。如果网格对话框打开，使用此 API 更改网格设置时不会更新。

**Original**: This command modifies the grid settings in the design.
In addition to the grid names (see
axlDBGridGet
), two symbolic grid names are available:
'all
– sets all grid values
'etch
– sets all ETCH grid values
As a convenience when setting a single the xGrids or yGrids attribute, you can use a float.
Both xMajor and yMajor values are automatically determined by the sum of the spacings in xGrids and yGrids respectively.
Notes:
Non etch grids may not have multiple spacings. We only use the first grid seen.
Setting grids is not undo-able (this may change in the future).
Etch grids names are the same as ETCH layer names. This may change in the future.
Origin values must be within drawing extents or 0.
If Grid dialog is open it will not be updated when you change the grid settings using this API command.

**语法**：
```skill
axlDBGridSet(grid)
Modify all etch grids
grid = axlDBGridGet("TOP")
grid->name = 'etch
grid->xGrids = '(5.0 7.0)
grid->yGrids = '(5.0 6.0)
axlDBGridSet(grid)
```

**参数** (Arguments)：

og_grid
- **a** — grid disembodied property list from
axlDBGridGet

**返回值** (Value Returned)：

t
if the command is successful and the grid is changed,
nil
in case of failure.

**示例** (Examples)：

Modify TOP grid settings
grid = axlDBGridGet("TOP")
grid = axlDBG
Modify all grids (note allow xGrids and yGrids to NOT be list)
grid = axlDBGridGet("TOP")
grid->name = 'all
grid->xGrids = 5.0
grid->yGrids = 5.0
axlDBGridSet(grid)
Modify all etch grids
grid = axlDBGridGet("TOP")
grid->name = 'etch
grid->xGrids = '(5.0 7.0)
grid->yGrids = '(5.0 6.0)
axlDBGridSet(grid)

**参见** (See Also)：

axlDBGridGet
,
axlDBDisplayControl

### axlDBTextBlockCreate

**说明**：从提供的模板块编号创建新的文本块。通过提供可选的文本块特性，可以获取可用文本块：`lst = axlGetParam("paramTextBlock")`。

**Original**: Creates a new text block from the template block number provided. By providing optional text block characteristics, you can get available text blocks by:
lst = axlGetParam("paramTextBlock")

**参数** (Arguments)：

x_blockTemplate
- **Text** — block number (an integer) to use as template.
0
(zero) can be used to start with a new empty text block
f_width
- **Width** — of an individual character in design units
f_height
- **Height** — of an individual character in design units
f_lineSpace
- **Spacing** — between lines of text in design units
f_charSpace
- **Spacing** — between consecutive characters in design units
f_photoWidth
- **Width** — in design units of the strokes used to draw characters

**返回值** (Value Returned)：

x_textBlock
New text block
nil
Returned if the command fails. Typically, this happens when you have exhausted the number block Allegro provides, or one of the parameters is not of the correct data type.

**示例** (Examples)：

Create a new text block based upon text block 1 but change width and height
blockNum = axlDBTextBlockCreate(1 ?width 15.0 ?height 16.0)
Create a new text block without using a template. All parameters must be specified
block2 = axlDBTextBlockCreate(0 ?width 25.0 ?height 35.0 ?lineSpace 40.0 ?photoWidth 5.0 ?charSpace 4.0)

**参见** (See Also)：

axlGetParam
,
axlSetParam
,
axlDBTextBlockCompact

### axlDBTextBlockFindName

**说明**：根据其名称查找文本块。

**Original**: Finds a text block based on its name.

**参数** (Arguments)：

t_textBlockName
- **The** — name of the text block to be found.

**返回值** (Value Returned)：

x_textBlockNumber
Number of the text block found.
nil
No text block found with the given name.

**示例** (Examples)：

Find the text block with the name "Refdes".
textBlockNumber = axlDBTextBlockFindName("Refdes")
if(textBlockNumber then
printf("Text block Refdes is number %d\n" textBlockNumber)
else
printf("There is no text block named Refdes\n")
)

### axlDBTextBlockGetName

**说明**：返回与给定文本块关联的名称。与 `axlGetParam("paramTextBlock:<number>")` 中的 `userName` 属性相同。

**Original**: Returns the name associated with the given text block. Same as attribute
userName
in
axlGetParam("paramTextBlock:<number>")
.

**参数** (Arguments)：

x_textBlockNumber
- **The** — index of the text block whose name it to be returned. Text blocks use a 1-based indexing.

**返回值** (Value Returned)：

t_name
The text block name
nil
This text block has no name

**示例** (Examples)：

textBlockName = axlDBTextBlockGetName(textBlockNumber)

### axlDBTextBlockSetName

**说明**：为给定文本块定义名称。

**Original**: Defines a name for a given text block.

**语法**：
```skill
axlDBTextBlockSetName(3 "Refdes")
```

**参数** (Arguments)：

x_textBlockNumber
- **The** — index of the text block whose name is to be defined. Text blocks use a 1 based indexing.
t_name
- **The** — name being defined for the text block. A
nil
- **indicates** — that there is no name.

**返回值** (Value Returned)：

t
Success
nil

**示例** (Examples)：

Define a name of "Refdes" for text block #3.
axlDBTextBlockSetName(3 "Refdes")

### axlExportXmlDBRecords

**说明**：从当前设计导出 Allegro 参数文件。提供与（文件 — 导入 — 参数）相同的功能。副作用是创建 `param_write.log` 文件。

**Original**: This exports an Allegro Parameter file from the current design. It offers the same capability as (
File – Import – Parameter
). Side effect is creation of a
param_write.log
file.

**语法**：
```skill
axlExportXmlDBRecords(
nil
) -> lt_parmGroups
```

**参数** (Arguments)：

t_fileName
- **Name** — of parameter file. Default extension is
.prm
- **and** — if not given a path component will locate the file via PARAMPATH. If filename is
nil
- **report** — back as a list the supported parameter groups.
lt_parmGroups
- **List** — of parameter groups to export or nil to export all.

**返回值** (Value Returned)：

t
if command is successfully executed,
nil
in case of an error

**示例** (Examples)：

In an existing dump, save all its settings and load into a new design
axlExportXmlDBRecords("myparam" nil)
axlOpenDesign(?design "newDesign")
axlImportXmlDBRecords("myparam")
Dump current parameter groups
axlExportXmlDBRecords(nil)

**参见** (See Also)：

axlImportXmlDBRecords

### axlFilmCreate

**说明**：创建新的工艺菲林（Artwork Film）或替换现有工艺菲林。使用的术语与工艺菲林对话框匹配。有关每个字段的使用方式，请参阅对话框帮助。所有布尔实体的默认值为 `nil`。由于 Valor 问题，使用 Gerber 4x 或 6x 时 `suppressShapeFill` 始终为 `nil`。如果 `drawHolesOnly` 参数设置为 `t`，则将为菲林上定义的 VIA 和 PIN CLASS 的所有焊盘绘制钻孔。启用 `axlDebug` 以获取额外的错误消息。

**Original**: Creates a new artwork film or replaces an existing artwork film.
The terminology used matches the artwork dialog box. For more information on how each field is used, see the dialog box help.
Defaults for all boolean entities is
nil
.
Due to Valor issue suppressShapeFill is always
nil
when using Gerber 4x or 6x.
If the value of the
drawHolesOnly
parameter is set to
t
, drill holes are drawn for all pads defined on the VIA and PIN CLASS for the film.
Enable
axlDebug
for additional error messages.

**参数** (Arguments)：

t_filmname
- **Film** — name
f_width
- **Undefined** — line width, default is 0.
x_sequence
- **For** — PDF output ordering. Default is 1, range is 1 to 255. If films have the same number, their database order will determine output.
x_angle
- **Film** — rotations, values are 0, 90, 180 or 270, Default is 0.
f_x, f_y
- **Film** — offset in design units, Default is 0,0
f_shapeBoundingBox
- **Shape** — bounding box in design units. Default is 0.
lt_layers
- **List** — of Allegro layers to apply to film. Default is none.
- **Layer** — names are fully qualified (include both class and subclass)
Example: "ETCH/TOP"
- **A** — mode exists where if you specify the class name all subclasses of that class are listed in the film.
Example: "MANUFACTURING"
lt_domains
- **List** — of domains where film should be visible. Values are ipc2581, pdf, artwork and visibility. Default is all.
lt_ipcDomains
- **List** — of domains where film should be used in IPC2581. Valid values are
inner
,
outer
,
misc
,
doc
, and
soldermask
.

**返回值** (Value Returned)：

t
if film is created,
nil
in case of an error.

**示例** (Examples)：

Add/Change
To understand how to add films, right-click on the artwork dialog to save a film to film (FILM_SETUP.txt)
Get all films:
p = axlGetParam("artwork")
p->groupMembers
Get a single film (where format is "artwork:<film name>"):
s = axlGetParam("artwork:top")
s->??
Delete a film (in this case top):
axlDeleteObject(s)

**参见** (See Also)：

axlGetParam
,
axlDeleteObject
,
axlDebug

### axlImportXmlDBRecords

**说明**：将 Allegro 参数文件导入当前设计。提供与（文件 — 导入 — 参数）相同的功能。副作用是创建 `param_read.log` 文件。对于新版本，prm 文件可能需要更新以支持新的参数记录或当前记录的添加。

**Original**: This command imports an Allegro Parameter file into the current design. It offers the same capability as (
File – Import – Parameter
). A side effect is creation of
param_read.log
file.
For new releases, the
prm
files may require updating to support new parameter records or additions to current records.
You can create your own custom parameter files and load them with this interface. While the export interface typically groups several Allegro parameters together, you can custom craft a
prm
file with a single parameter record or just a single parameter from one record (see the following example). The only
prm
file requirements are: prm file xml header, parameter header and trailer, and revision number per parameter (currently these are all 1)

**参数** (Arguments)：

t_fileName
- **Name** — of parameter file. Default extension is
.prm
. If filename is not provided component will located the file via PARAMPATH.

**返回值** (Value Returned)：

t
if success,
nil
an error

**示例** (Examples)：

See
axlExportXmlDBRecords
Example of a parameter file with setting just the dynamic shape min area to 75.0:
<?xml version="1.0" encoding="UTF-8" standalone="no" ?>
<CadenceAllegroParameter xmlns="">
<dynfill_parm_type>
<rev>1</rev>
<min_area>75.0 MIL</min_area>
</dynfill_parm_type>
</CadenceAllegroParameter>

**参见** (See Also)：

axlExportXmlDBRecords

### axlMiniStatusReset

**说明**：将选项面板设置和查找过滤器设置重置为新设计的默认值。除非 Cadence 建议，否则不要运行此命令。

**Original**: This resets the Option panel settings and find filter settings to a new design’s default.
Do not run this unless advise by Cadence.

**语法**：
```skill
axlMiniStatusReset()
```

**参数** (Arguments)：

None

**返回值** (Value Returned)：

nil
a command is active
t
panel is reset settings

**示例** (Examples)：

axlMiniStatusReset()

### axlPadSuppressGet

**说明**：返回层或设计的焊盘抑制（Pad Suppression）层特性。焊盘抑制在符号编辑器中不可用。命名介电层将出现在列表中，与焊盘抑制对话框不同。

**Original**: Returns pad suppress layer characteristic for a layer or design. Pad suppression is not available in symbol editor.
Name dielectric layers will appear in the list unlike the pad suppress dialog.

**语法**：
```skill
axlPadSuppressGet(
'all
)
==> ll_LayerPadSuppress
axlDBGridGet(
t_layer/x_layerNumber
)
==> l_LayerPadSuppress
```

**参数** (Arguments)：

nil
- **Returns** — global status for dynamic pad suppression
all
- **Returns** — all layers with settings
t_layer
- **Get** — suppress characteristics of named layer
x_layerNumber
- **Layer** — number (1st layer is 0).

**返回值** (Value Returned)：

ll_LayerPadSuppress
- list of
l_LayerPadSuppress
for all etch layers. Layers are ordered from top to bottom.
l_LayerPadSuppress
- suppress characteristics of named layer. The symbols pin and via are optional and if present indicate pin and/or vias will be suppressed on that layer.
(<t_layer> [<s_pin>] [<s_via>])

**示例** (Examples)：

Get the global dynamic pad suppression status
suppress = axlPadSuppressGet(nil)
Get and print suppress state of all layers
suppress = axlPadSuppressGet('all)
foreach(item suppress
printf("Layer=%s  what= %L\n", car(item) cdr(item))
Get settings for layer "GND"
suppress = axlPadSuppressGet("GND")
Get settings for layer 1
suppress = axlPadSuppressGet(1)

**参见** (See Also)：

axlPadSuppressSet
,
axlPadSuppressOkLayer
,
axlDBControl
,
axlSubclassRoute
,
axlPadOnLayer

### axlPadSuppressOkLayer

**说明**：指示层是否可以设置为焊盘抑制。只有未设置为负片图稿的内部导体层和 Shape 层才支持焊盘抑制。

**Original**: Indicates if layer can be set for pad suppression. Only internal conductor and shape layers that are not set for negative artwork, support pad suppression.

**语法**：
```skill
axlPadSuppressOkLayer("TOP")
axlPadSuppressOkLayer(0)
```

**参数** (Arguments)：

t_layer
- **name** — of layer (for example, "TOP")
x_layerNumber
- **layer** — number (starts at 0);

**返回值** (Value Returned)：

t
if layer can allows pad suppress;
nil
otherwise

**示例** (Examples)：

The following are the same in the PCB tool but may not be in APD+:
axlPadSuppressOkLayer("TOP")
axlPadSuppressOkLayer(0)

**参见** (See Also)：

axlPadSuppressGet

### axlPadSuppressSet

**说明**：修改设计中的焊盘抑制设置。允许控制动态抑制设置（`g_mode`）和单个层选项（后续参数）。注意：如果传递抑制层列表，则列表中的任何错误都将被忽略。将标记动态 Shape 和 DRC 过期。如果启用动态模式但没有启用抑制层，则动态模式将被禁用。与动态不同，它不会自动启用无焊盘孔的显示。使用此 API 时不应打开焊盘抑制对话框。

**Original**: This modifies the pad suppression settings in the design. Allows control of both dynamic suppression setting (
g_mode
) and the individual layer options (subsequent arguments).
Notes:
If passing a list of suppression layers then any errors in the list are ignored.
Will mark dynamic shapes and DRC out of date.
If enabling dynamic mode and no suppression layers are enabled the dynamic mode will be left disabled.
Unlike the dynamic it will not automatically enable the display of padless holes.
Pad suppression dialog should not be open when using this API.

**语法**：
```skill
axlPadSuppressSet(
g_mode
t_layer/x_layerNumber
ls_options
)
==> t/nil
```

**参数** (Arguments)：

g_mode
- **The** — possible values are:
nil
- maintain current pad suppression mode
'on
- turn pad suppression on
'off
- turn pad suppression off
- **In** — the first format, second argument can have one of the following values.
'all
- **Enable** — suppress on all supported layers
'none
- **Clear** — suppression on all supported layers
nil
- **Leave** — suppression layers alone (typically used to toggle global mode)
ll_LayerPadSuppress
- **List** — of layers using the same form as
axlPadSuppressGet
.
Alternatively, use the second format to set suppression on single layers.
t_layer
- **Layer** — name
or
x_layerNumber
- **Layer** — number when first layer is 0
ls_options
- **May** — be
nil
- **or** — a list of
'via
and/or
'pin

**返回值** (Value Returned)：

t
if success,
nil
a failure

**示例** (Examples)：

Enable dynamic suppression setting
axlPadSuppressSet('on nil)
Enable all layers and dynamic mode
axlPadSuppressSet('on 'all)
Delete suppression layer settings and turn off dynamic mode
axlPadSuppressSet('off 'none)
Turn on via suppression on layer GND
axlPadSuppressSet(nil "GND" '(via))
Turn on via & pin suppression on layer GND
axlPadSuppressSet(nil "GND" '(via pin))
Turn off suppression on a layer GND
axlPadSuppressSet(nil "GND" nil)
Turn on suppression for GND and VCC layers
axlPadSuppressSet(nil '(("GND" via pin) ("VCC" via pin)))
axlParamFilletDoc
p = axlGetParam("fillet")
axlSetParam(p)

**参见** (See Also)：

axlDBGridGet
,
axlDRCUpdate
,
axlDBDynamicShapes

### axltdfIsEnabled

**说明**：此函数检查技术相关封装映射文件（.tdfx）是否附加到设计。此函数还检查 TDF 文件中定义的技术相关封装映射是否包含将封装符号映射到替代封装的映射。

**Original**: This function checks whether a technology-dependent footprint mapping file (
.tdfx)
is attached to a design. This function also checks whether the technology-dependent footprint mapping, defined in the TDF file, contains mapping of the footprint symbols to alternative footprints.

**语法**：
```skill
axltdfIsEnabled
```

**参数** (Arguments)：

None
.

**返回值** (Value Returned)：

t
if TDF information is attached
nil
no attachment

**示例** (Examples)：

if(axltdfIsEnabled()
println("TDF mapping found")
println("No TDF mapping in this drawing")
)
=> "TDF mapping found"
axltdfLoad
axltdfLoad
[t_tdffile]
) -> t/nil

**参见** (See Also)：

axltdfSave
,
axltdfLoad

### axlColorGet

**说明**：获取颜色调色板。支持以下模式：如果传递的索引小于颜色计数，则返回包含该颜色索引的红、绿、蓝调色板值的列表。这些是介于 0（无颜色）和 255（最大颜色）之间的整数值。如果传递 `'count`，则返回当前数据库调色板的大小（目前始终为 24）。如果传递 `'all`，则返回整个数据库调色板（除了背景）的红、绿、蓝列表。返回支持的图案数量（包括默认实心）。

**Original**: Get color palette. Supports the following modes:
If passed, an index less the color count returns a list containing the red, green, blue palette values for that color index. These are integer values between
0
(no color and
255
(maximum color). For example, a value of
255 255 255
is white. Or if passed, '
background
returns the palette for the background.
If given
'count
returns the current size of the database palette (currently always 24).
If passed 'all returns a list of list (red, green, blue) for all entire database palette EXCEPT the background.
Returns number of patterns supported (includes default solid).
The color index is the number assigned to each layer in Allegro PCB Editor. (see
axlVisibleGet
).

**语法**：
```skill
axlColorGet(
'count)
-> x_count
axlColorGet(
'all)
-> llx_rgb
axlColorGet(
'pattern
) -> x_count
```

**参数** (Arguments)：

x_number
- **Color** — number.
'background
- **Get** — background color.
‘count
- **Query** — current database color palette size.
‘all
- **Get** — entire database color palette (except background).

**返回值** (Value Returned)：

x_count
Size of database palette.
nil
Error.
lx_rgb
A palette.
llx_rgb
The entire database palette.

**示例** (Examples)：

Get red/green/blue of color 2:
clr = axlColorGet(2)
Get background color:
bground = axlColorGet(`background)
Get number of colors:
cnt = axlColorGet(`count)
Get all red/green/blue color settings except background:
all = axlColorGet(`all)
Get number of display patterns supported
cnt = axlColorGet(`pattern)

**参见** (See Also)：

axlColorSet
,
axlVisibleGet

### axlColorShadowGet

**说明**：提供阴影模式（Shadow Mode）选项。

**Original**: Provides the options of shadow mode.

**语法**：
```skill
axlColorShadowGet('mode)
Is shadow mode percent:
axlColorShadowGet('percent)
```

**参数** (Arguments)：

g_option
'mode
- **Shadow** — mode status (
t
- **is** — on,
nil
- **is** — off).
'activeLayer
- **Active** — layer dimming enabled (
t
). This is called "Dim active layer in Options panel.
'highlight
- **This** — is called "Dim color assignments" in the Options panel
'percent
- **Current** — brightness percentage (0 to 100).
'custom
- **Custom** — colors, these are not shadowed.

**返回值** (Value Returned)：

t/nil
Shadow or active layer mode on or off.
x_percent
Brightness percentage.

**示例** (Examples)：

Is shadow mode on:
axlColorShadowGet('mode)
Is shadow mode percent:
axlColorShadowGet('percent)

**参见** (See Also)：

axlColorSet
,
axlColorShadowSet

### axlColorShadowSet

**说明**：设置阴影模式选项。这些等同于显示组下阴影模式框中的颜色命令。模式选项为 `t` 或 `nil`，以打开或关闭阴影模式。`activeLayer` 选项为 `t` 或 `nil`，以自动调暗活动层。`highlight` 选项为 `t` 或 `nil`，以调暗高亮对象。`percent` 选项设置从暗（0）到亮（100）的百分比。完成所有颜色更改后，调用 `axlVisibleUpdate` 以更新显示。如果设置了 `display_noshadow` 环境变量，则禁用此接口。

**Original**: Sets the shadow mode options. These are equivalent to the color commands in the shadow mode box under the Display group.
The Mode Options are:
The mode option is either
t
or
nil
to turn shadow mode on or off.
The activeLayer option is either
t
or
nil
to automatically dim the active layer. This is called "Dim active layer in Options panel.
The highlight can be
t
or
nil
to dim highlighted objects. This is called
Dim color assignments
in the Options panel.
The percent option sets the dimness (
0
) to brightness (
100
) percentage.
On graphics or display combinations, shadow values of less than 40 percent disappear into the background. For example, you have what appears to be black on black.
After you finish all the color changes, call
axlVisibleUpdate
to update the display.
This interface is disabled if you set the
display_noshadow
environment variable.

**语法**：
```skill
axlColorShadowSet(
'percent
x_percentage
) -> t/nil
```

**参数** (Arguments)：

g_mode
- **The** — possible values are:
'mode
– Enable or disable shadow mode.
'highlighted
– Enable or disable shadow mode for highlighted objects.
'activeLayer
– Enable or disable active layer dimming.
'percent
– Set shadow mode percentage (0 to 100)

**返回值** (Value Returned)：

t
If successful.
nil
An argument error.

**示例** (Examples)：

Is shadow mode on:
axlColorShadowSet('mode t)
Is shadow mode percent:
axlColorShadowSet('percent 20)

**参见** (See Also)：

axlColorSet
,
axlColorShadowSet
,
axlVisibleUpdate

### axlColorLoad

**说明**：加载 Allegro PCB Editor 颜色文件（默认 .col 文件）。主颜色文件位于 `<cdsroot>/share/pcb/text/lallegro.col`。文件格式：第一列的 `#` 表示注释；`#N` 表示颜色数量；`#B` 表示背景色；`#I` 表示颜色设置。调用 `axlVisibleUpdate` 以在完成颜色操作后更新显示。

**Original**: Loads an Allegro PCB Editor color file (default .
col
file). Master color file is located at
<cdsroot>/share/pcb/text/lallegro.col
.
File format is:
#
Comment if in first column.
#N
Next line with a number is number of colors (currently only 24 is supported). This should appear first in the file.
Number format
#Number
24
#B - next line with a number is background color. This should appear after color number. Format of color line must be:
(name is currently ignored):
0 <red> <green> <blue> [<name>]
EXAMPLE of background format setting it to black
#Background Color
0      0       0       0
#I - next set of lines sets the colors. These should always appear last in the file. We will read until the first color number that exceeds the color number (currently hardcoded as 24) or the end of file is reached. The order the colors appear in the file determines the initial color [priority (highest (first) to lowest (last)].
Format is:
<color number> <pen number> <red> <green> <blue> [<name>]
EXAMPLE:
1      1       255     255     255     White
2      2       14      210     255     LtBlue
<color number>: entry in color table. This is the color number referenced by the allegro subclass (axlLayerGet)
<pen number>: Used by Allegro plot (UNIX) to control what pen to use during plotting. Not applicable on Windows.
<red> intensity of red to blend into color 0 to 255
<green> intensity of green to blend into color 0 to 255
<blue> intensity of blue to blend into color 0 to 255
<name> (optional) name of color, currently not used by Allegro but sigxp takes advantage of the name to auto-assign colors.
Call
axlVisibleUpdate
to update the display after you finish manipulating the colors.
In Allegro PCB Editor, you need the color file to start a new design. Opening existing databases uses the color table stored in that database. A new database created, when Allegro PCB Editor is already running, copies the color table from the previous database.

**语法**：
```skill
axlColorLoad(nil)
axlVisibleUpdate(t)
```

**参数** (Arguments)：

s_file
- **Color** — file name to load.
nil
Uses
lallegro.col
. If no directory path, Allegro PCB Editor uses the LOCALPATH environment variable to find the file.

**返回值** (Value Returned)：

t
If loaded file.
nil
File not found or error in loading file.

**示例** (Examples)：

Load user-defined default color. Overriding and setting current board values:
axlColorLoad(nil)
axlVisibleUpdate(t)

**参见** (See Also)：

axlColorSave
,
axlColorSet
.
axlColorOnGet – Obsolete
This function is obsolete. Due to change in display model, switching off colors is no longer supported.
axlColorOnSet – Obsolete
This is an obsolete command. Due to changes in the viewing model, now you cannot turn off a color in Allegro PCB Editor.
axlColorPriorityGet – Obsolete
Due to the changes in color model of Allegro PCB Editor, this command is now obsolete. Instead of this command, use
axlLayerPriorityGet
.
axlColorPrioritySet – Obsolete
Due to the changes in color model of Allegro PCB Editor, this command is now obsolete. Instead of this command, use
axlLayerPrioritySet
.

### axlColorSave

**说明**：将当前设计颜色保存到指定文件。

**Original**: Saves current design colors to specified file.

**语法**：
```skill
axlColorSave("mycolor")
```

**参数** (Arguments)：

t_file
- **File** — name. If
nil
; saves to
<HOME>/pcbenv/lallegro.col.
- **If** — no extension, uses .
col
extension.

**返回值** (Value Returned)：

t
Successful.
nil
Failed to save.
EXAMPLES
Save current design color settings:
axlColorSave("mycolor")

**参见** (See Also)：

axlColorSave
,
axlColorSet

### axlColorSet

**说明**：设置颜色编号或背景的红、绿、蓝调色板。支持的模式：颜色编号（`x_number`）和红/绿/蓝列表。`x_number` 必须介于 1 和 `axlColorGet('count)` 之间，或 `'background` 设置背景颜色。`'all` 接受红/绿/蓝值列表，并将颜色从 1 设置到列表末尾。红/绿/蓝颜色值介于 0（最低强度）和 255（最大强度）之间。完成颜色更改后，调用 `axlVisibleUpdate` 以更新显示。

**Original**: Sets red, green, blue palette for a color number or background.
Modes supported:
Color number (
x_number
) and red/green/blue list.
x_number
must be between one and
axlColorGet('count)
, or '
background
sets red/green/blue as the background color.
'all
takes a list of red/green/blue values and sets colors starting at one to the end of the list. Intended to use with
axlColorGet('all)
to save or restore color values.
Red/green/blue colors are values between
0
(least intensity) to
255
(maximum intensity).
After color changes are made, call
axlVisibleUpdate
to update the display.
Color model:
A color (or colorNumber) in Allegro PCB Editor has the following attributes:
A palette of red, green and blue values between
0
and
255
.
0
adds none of the primary color to the mixture while
255
adds the maximum. For example,
0,0,0
is black and
255,255,255
is white. The color mixture is controlled using the palette section of the color command.
Each color number can be assigned to a layer. Multiple layers will have the same color number, because there are more layers than colors.
Allegro PCB Editor supports setting a background palette value. Grids, ratsnest, temporary highlight can have a color number assigned via
axlDBControl
.
Color services:
axlColorSet
This routine.
axlColorGet
Get red, green, or blue of one or more color numbers.
axlColorShadowGet
Shadow mode options.
axlColorShadowSet
Set shadow mode options.
axlLayerPrioritySet
set a layer to a display priority
axlLayerPriorityGet
get a layer's current priority
axlLayerPriorityClearAll
clear all layer priorities (restore to default)
axlLayerPrioritySaveAll
save existing priority table
axlLayerPriorityRestoreAll
restore saved priority table
axlColorSave
Save color values to file.
axlColorLoad
Load color values from file.
axlUIColorDialog
Standard color chooser dialog box.
axlDBControl
Miscellaneous color number assignments (for example, highlight).
axlLayerGet
Get layer (class/subclass) attributes (control color) number and visibility for individual layers.
axlLayerSet
Set color number or visibility for a layer.
axlVisibleLayer
Set visibility of layer.
axlIsVisibleLayer
Provides the layer visibility.
axlVisibleGet
Get visibility set for design.
axlVisibleSet
Set visibility set for design.
axlVisibleDesign
Global design visibility control.
axlVisibleUpdate
Update windows with color changes.

**语法**：
```skill
axlColorSet(
'all
ll_rgb
) ->t/nil
```

**参数** (Arguments)：

x_number
- **Color** — index.
'background
- **Set** — background color.
'all
- **Set** — colors based upon a list starting at color number one.
l_rgb
Red/green/blue lists; three integers.
ll_rgb
- **Lists** — of red/green/blue values.

**返回值** (Value Returned)：

t
Successful.
nil
An error; wrong arguments: color number is less then one or greater than maximum.
EXAMPLES
Set color number three same as color two:
clr = axlColorGet(2)
axlColorSet(3 clr)
axlVisibleUpdate(nil)
Set first three colors:
axlColorSet('all '((10 10 10) (40 40 40) (100 100 100)))

### axlCVFColorChooserDlg

**说明**：显示颜色调色板模态对话框。颜色井反映当前设计颜色。

**Original**: Displays color palette modal dialog. Color wells reflect current design colors.

**参数** (Arguments)：

x_color_index
- **Color** — index to initialize palette dialog. Values 0 to 191.
g_show_hilite
- **Specifies** — whether or not the highlight check box is to be displayed. If the value is set to:
- **t** — – displays the highlight check box.
nil/default
– highlight check box is not displayed.
x_hilite_flag
- **Highlight** — state to initialize highlight check box (if displayed). Pass 1 or 0.
x_bitmap_index
- **Bitmap** — index to initialize palette dialog. Values 0 to 15.

**返回值** (Value Returned)：

list
containing one or two int values for user color palette selection and highlight check box selection. if
g_show_hilite
is not
nil
, list contains the two values, or else list contains color index only.
nil
if user cancels the form or error occurred.

### axlClearObjectCustomColor

**说明**：清除提供的数据库 ID 或数据库 ID 列表上的任何自定义颜色。支持的对象包括组、网络、符号实例、功能实例、引脚、过孔、邦定指和外部 DRC。对象（组、网络、符号或功能）及其所有继承对象的颜色被清除。如果清除对象的颜色，其中部分对象（如网络中的引脚）具有不同的自定义颜色，则该子对象将保留其不同的颜色。如果要为父对象及其所有子对象清除自定义颜色，请在父对象以及具有不同自定义颜色的所有子对象上调用 `axlClearObjectCustomColor`。

**Original**: Clears any custom color set on the provided database ID or list of database IDs. Objects supported are groups, nets, symbol instances, function instances, pins, vias, bond fingers, and external DRCs. The color of an object (group, net, symbol, or function) and all inheriting objects are cleared. If you clear the color of an object, where part of that object, such as a pin in a net, has a different custom color, that child object will retain its different color. If you want the custom color to be cleared for the parent and all child objects of the parent, call
axlClearObjectCustomColor
on the parent object and on all child objects that have different custom colors.
Segments may not be custom colored or cleared by these interfaces. Segments are colored directly and only for temporary use in specific commands like the highlight segment over via tool. They should be unhighlighted with the same command.
Custom colors must be enabled (see
axlDBDisplayControl
) to be viewed.

**语法**：
```skill
axlClearObjectCustomColor
on the parent object and on all child objects that have different custom colors.
Segments may not be custom colored or cleared by these interfaces. Segments are colored directly and only for temporary use in specific commands like the highlight segment over via tool. They should be unhighlighted with the same command.
Custom colors must be enabled (see
axlDBDisplayControl
) to be viewed.
```

**参数** (Arguments)：

lo_dbid
- **List** — of database IDs or a single database ID to clear custom color.

**返回值** (Value Returned)：

t/nil
Returns
t
if at least one object custom color was cleared.
Returns
nil
otherwise.

**示例** (Examples)：

See
axlCustomColorObject
for examples.

**参见** (See Also)：

axlCustomColorObject

### axlCustomColorObject

**说明**：为单个或数据库 ID 列表设置自定义颜色。支持的对象包括组、网络、符号实例、功能实例、引脚、过孔、邦定指、cline、线、文本、图形、shape 和外部 DRC。作为组、网络、符号或功能一部分但没有分配特定自定义颜色的对象，继承分配给父对象的自定义颜色。例如，如果网络 `A` 上的引脚没有分配不同的自定义颜色，则继承网络 `A` 的自定义颜色。另一方面，如果为网络分配了自定义颜色，但网络上的某些引脚分配了不同的自定义颜色，则这些引脚的颜色将与网络颜色不匹配。

**Original**: Set custom color for a single or list of database IDs. Objects supported are groups, nets, symbol instances, function instances, pins, vias, bond fingers, clines, lines, text, figures, shapes, and external DRCs. An object that is part of a group, net, symbol, or function but that does not have a specific custom color assigned, inherits the custom color assigned to the parent object. For instance, a pin on net "A" inherits the custom color assigned to net "A" if the pin does not have a different custom color assigned to it. On the other hand, if a custom color is assigned to a net but some pins on the net have a different custom color assigned, the color of these pins will not match the net color.
Segments may not be custom colored or cleared by these interfaces. Segments are colored directly and only for temporary use in specific commands like the highlight segment over via tool. They should be unhighlighted with the same command.
The color index is between 1 and
axlColorGet(`count)
. The index references a RGB value in the Allegro Color table. The RGB values can be viewed or modified via
axlColorGet
or
axlColorSet
.
Custom colors need to be enabled (see
axlDBDisplayControl
) to be viewed.

**语法**：
```skill
axlCustomColorObject
and
axlClearObjectCustomColor
functions respectively to set and clear custom color of database elements during interactive commands.
The following example does the following:
Defines the function highlightLoop.
Loops on the function axlSelect gathering user selections to set/clear custom color.
Custom colors objects using color 4.
Waits then clears custom color.
The command can be stopped at any time by selecting Cancel or Done from the pop-up menu.
(defun customColorLoop ()
axlSetFindFilter( ?enabled '("noall" "alltypes" "nameform")
?onButtons "alltypes")
while( axlSelect()
axlCustomColorObject( axlGetSelSet() 4)
checkColor = axlIsCustomColored( car(axlGetSelSet()) )
axlSleep(1)
axlClearObjectCustomColor( axlGetSelSet())
)
)
```

**参数** (Arguments)：

od_dbid
- **a** — single or a list of DBIDS
g_custom_color
- **Color** — index to be used to set custom color. If the value is
nil
, perm highlight will be used.

**返回值** (Value Returned)：

t
An object was custom colored.
nil
No valid DBIDS.

**示例** (Examples)：

The example covered in this section uses
axlCustomColorObject
and
axlClearObjectCustomColor
functions respectively to set and clear custom color of database elements during interactive commands.
The following example does the following:
Defines the function highlightLoop.
Loops on the function axlSelect gathering user selections to set/clear custom color.
Custom colors objects using color 4.
Waits then clears custom color.
The command can be stopped at any time by selecting Cancel or Done from the pop-up menu.
(defun customColorLoop ()
axlSetFindFilter( ?enabled '("noall" "alltypes" "nameform")
?onButtons "alltypes")
while( axlSelect()
axlCustomColorObject( axlGetSelSet() 4)
checkColor = axlIsCustomColored( car(axlGetSelSet()) )
axlSleep(1)
axlClearObjectCustomColor( axlGetSelSet())
)
)

**参见** (See Also)：

axlClearObjectCustomColor
,
axlDBDisplayControl
,
axlIsCustomColored
,
axlColorGet

### axlLayerPriorityClearAll

**说明**：清除 Allegro 数据库中的所有层优先级信息。

**Original**: Clears all layer priority information in Allegro database. Use
axlLayerPrioritySet
for usage.

**参数** (Arguments)：

None

**返回值** (Value Returned)：

t:
success

**示例** (Examples)：

Get and fetch priority
axlLayerPrioritySet("BOARD GEOMETRY/OUTLINE" 1)
prior = axlLayerPriorityGet("BOARD GEOMETRY/OUTLINE")
Get group class mapping of class Ref Des
axlLayerPrioritySet("REF DES") -> "COMPONENT VALUE"

**参见** (See Also)：

axlLayerPrioritySaveAll
,
axlLayerPriorityRestoreAll
axlLayerPriorityGet
get layer's priority
axlLayerPriorityGet(
t_layer
) -> x_priority/t_mapClass/nil

### axlLayerPriorityRestoreAll

**说明**：恢复先前保存的层优先级信息。此函数仅在已调用 `axlLayerPrioritySaveAll` 后才有效。

**Original**: Restores previously saved layer priority information. This function only works if a call to
axlLayerPrioritySaveAll
has been done already.

**参数** (Arguments)：

None

**返回值** (Value Returned)：

t:
success
nil:
nothing to restore.

**参见** (See Also)：

axlLayerPrioritySaveAll
,
axlLayerPriorityClearAll

### axlLayerPrioritySaveAll

**说明**：保存所有层优先级信息以供以后恢复。在调用 `axlLayerPriorityRestoreAll` 之前，对此函数的后续调用均为无操作。

**Original**: Saves all layer priority information to be restored later. Until a
axlLayerPriorityRestoreAll
is called, any subsequent calls to this function are no-op.

**参数** (Arguments)：

None

**返回值** (Value Returned)：

t:
success
nil:
this function has been called already but axlLayerPriorityRestoreAll has not been called yet.

**参见** (See Also)：

axlLayerPriorityClearAll
,
axlLayerPriorityRestoreAll

### axlLayerPrioritySet

**说明**：更改给定层的绘制优先级。优先级从 1（最高）到 255（最低）。没有优先级的层在标准绘制顺序中位于所有优先级层之下。活动层始终首先绘制。每个优先级级别只能有一个层，因此在优先级添加新层将替换该优先级的现有层。从优先级级别 1 开始，必须设置每个级别才能启用较低的优先级级别。类可以分组到一个类组中，一个类作为该组的引导。例如，所有蚀刻层（ETCH、PIN 等）一起映射到堆叠组中，类 ETCH 作为引导。您可以使用类名设置优先级，但不能单独为不同的堆叠层设置优先级。此接口自动将类名映射到其类组。更改层优先级后，应调用 `axlVisibleUpdate` 以更新显示。优先级值 0 表示移除层的优先级。

**Original**: This changes the drawing priority of given layer. Priority is from 1 (highest) to 255 (lowest). Layers without priority in standard drawing order below all priority layers. The active layer is always drawn first.
Only one layer may be at a priority level, thus adding a new layer at a priority replaces the existing layer at that priority. For example, executing following line of code results in just the ASSEMBLY_TOP being drawn at priority 1 and OUTLINE returning to normal drawing order.
axlLayerPrioritySet( "BOARD GEOMETRY/OUTLINE" 1)
axlLayerPrioritySet( "PACKAGE GEOMETRY/ASSEMBLY_TOP" 1)
From priority level 1 each level must be set for lower priority levels to be enabled. For example, if you set a layer to priority level 2 but leave level 1 empty then level 2 is disabled until level 1 is assigned.
Classes may be grouped together in a class group with one class being the lead of that group. For example, all etch layers (ETCH, PIN, etc.) are mapped together into the stack-up group with class ETCH the lead. You can set the priority using class names but you cannot prioritized the different stack-up layers individually. This interface automatically maps a class name to its class group (see
axlLayerPriorityGet
to determine groupings).
You should do a
axlVisibleUpdate
after changing layer priority to have the display updated.
Priority value of 0 means remove layer priority of the layer.

**语法**：
```skill
axlLayerPrioritySet( "BOARD GEOMETRY/OUTLINE" 1)
axlLayerPrioritySet( "PACKAGE GEOMETRY/ASSEMBLY_TOP" 1)
From priority level 1 each level must be set for lower priority levels to be enabled. For example, if you set a layer to priority level 2 but leave level 1 empty then level 2 is disabled until level 1 is assigned.
Classes may be grouped together in a class group with one class being the lead of that group. For example, all etch layers (ETCH, PIN, etc.) are mapped together into the stack-up group with class ETCH the lead. You can set the priority using class names but you cannot prioritized the different stack-up layers individually. This interface automatically maps a class name to its class group (see
axlLayerPriorityGet
to determine groupings).
You should do a
axlVisibleUpdate
after changing layer priority to have the display updated.
Priority value of 0 means remove layer priority of the layer.
```

**参数** (Arguments)：

x_layer
- **layer** — name (i.e. "ETCH/TOP")
x_priority
- **priority** — value in the range of 1-255 and 0 means remove.

**返回值** (Value Returned)：

t
success
nil
error in one of the arguments

**示例** (Examples)：

Set priority for class BOARD GEOMETRY and subclass OUTLINE:
axlLayerPrioritySet("BOARD GEOMETRY/OUTLINE" 1)
To temporarily force a set of layers to display on top, you should take the following steps:
save existing layer table,
clear existing layer priorities
set your layer priorities
draw objects
restore old layer priority:
axlLayerPrioritySaveAll()
axlLayerPriorityClearAll()
axlLayerPrioritySet() -- multiple times if needed
axlLayerPriorityRestoreAll()

**参见** (See Also)：

axlLayerPriorityClearAll
,
axlLayerPrioritySaveAll
,
axlLayerPriorityRestoreAll
,
axlLayerPriorityGet
,
axlMapClassName
,
axlVisibleUpdate
axlIsCustomColored
axlIsCustomColored (
o_dbid
)
==> x_customColor/nil

### axlClasses

**说明**：返回类列表。实际上只是：`axlGetParam("paramLayerGroup")->groupMembers`。

**Original**: Return list of classes.The is actually just:
axlGetParam("paramLayerGroup")->groupMembers

**语法**：
```skill
axlClasses()
```

**参数** (Arguments)：

Nothing

**返回值** (Value Returned)：

list of class strings

**示例** (Examples)：

axlClasses()

**参见** (See Also)：

axlSubclasses
,
axlGetParam
,
axlMapClassName

### axlCompareLayers

**说明**：在活动设计中比较两个层或两组层。此 SKILL 函数提供直接 API，用于从代码生成层比较输出，而不是通过交互式和批处理层比较工具。

**Original**: Performs a comparison between two layers or sets of layers in the active design.This SKILL function provides a direct API to generate layer compare outputs from the code instead of through the interactive and batch layer compare tools.

**语法**：
```skill
axlCompareLayers("ETCH/TOP" "ETCH/BOTTOM" "DRAWING FORMAT/COMPARE_LAYERS"
?action 'AND ?clearOutputLayer t)
axlDBGetLayerType
axlDBGetLayerType
t_layerName
)
⇒
t_layertype
/nil
```

**参数** (Arguments)：

l_referenceLayers
- **Source** — layer(s) to be compared. This may be either a single layer, such as "ETCH/TOP", or a list of layers '("ETCH/TOP" "PIN/TOP"). If multiple layers are provided, layers are first combined together (logical OR) before the comparison to the second layer set is performed.
l_compareLayers
- **Comparison** — layer(s) to be compared. This may be either a single layer, such as "ETCH/TOP", or a list of layers '("ETCH/TOP" "PIN/TOP"). If multiple layers are provided, these are first combined together (logical OR) before the comparison to the reference layer set is performed.
t_outputLayer
- **Target** — layer, where the results of the boolean operation should be generated to. If the layer does not exist, it will be created.
ts_action
- **Comparison** — action. Operations are same as those supported by the
axlPolyOperation
API: 'AND, 'OR, 'ANDNOT, and 'XOR. Default is 'OR.
b_clearOutputLayer
If
t
, remove any shapes from the output layer before populating with the results of the layer compare operation. Default is
t
.
l_extents
- **If** — set, represents the window area where the comparison is to be restricted to. Default is to compare the entire database region.
g_shape
- **If** — set, provides a DBID of a shape. The shape will be used to set the restricted comparison region. Only one of
l_extents
or
g_shape
- **may** — be used at a time.

**返回值** (Value Returned)：

t
Comparison successful
nil
An error occurred. Check arguments passed to the function and ensure that if the output layer does not exist, there is room to add it to the database.

**示例** (Examples)：

axlCompareLayers("ETCH/TOP" "ETCH/BOTTOM" "DRAWING FORMAT/COMPARE_LAYERS"
?action 'AND ?clearOutputLayer t)
axlDBGetLayerType
axlDBGetLayerType
t_layerName
)
⇒
t_layertype
/nil

**参见** (See Also)：

axlXSectionGet

### axlGetExternalLayers

**说明**：返回外部层名称。

**Original**: Returns the names external layers.

**语法**：
```skill
axlGetExternalLayers()
("TOP" "BOTTOM")
axlGetXSection – Obsolete
axlGetXSection(
)
==> ll_layers/nil
```

**参数** (Arguments)：

Nothing

**返回值** (Value Returned)：

(<top name> <bottom name>)

**示例** (Examples)：

On a PCB design
axlGetExternalLayers()
("TOP" "BOTTOM")
axlGetXSection – Obsolete
axlGetXSection(
)
==> ll_layers/nil

**参见** (See Also)：

axlXSectionGet
,
axlLayerExternal

### axlIsEtchLayer

**说明**：确定层是否与 ETCH 层关联。如果层与任何 ETCH 层关联，则返回 `t` — ETCH、PIN、VIA、DRC、VIA_KEEPOUT、ROUTE_KEEPOUT、ANTI_ETCH、BOUNDARY、CONSTRAINT_REGION、ROUTER_PLAN 和 CAVITY。

**Original**: Determines if a layer is associated with the ETCH layers. Returns
t
if layer is associated with any of the ETCH layers —
ETCH
,
PIN
,
VIA
,
DRC
,
VIA_KEEPOUT
,
ROUTE_KEEPOUT
,
ANTI_ETCH
,
BOUNDARY
,
CONSTRAINT_REGION
,
ROUTER_PLAN
, and
CAVITY

**语法**：
```skill
axlIsEtchLayer("PIN/TOP")
axlIsEtchLayer("ETCH")
```

**参数** (Arguments)：

t_layer
- **Layer** — name (for example, "ETCH/TOP") or just class name ("ETCH")

**返回值** (Value Returned)：

nil
Not an etch associated layer
t
Is an etch associated layer

**示例** (Examples)：

axlIsEtchLayer("PIN/TOP")
axlIsEtchLayer("ETCH")

### axlIsLayer

**说明**：确定 `t_layer` 是否存在。`t_layer` 是完全限定的层名称。

**Original**: Determines if the
t_layer
exists.
t_layer
is a fully qualified layer name.

**参数** (Arguments)：

t_layer
- **Name** — of layer in format “
<class>/<subclass>
.”

**返回值** (Value Returned)：

t
Layer exists.
nil
Layer does not exist.

### axlIsVisibleLayer

**说明**：返回完全限定层的可见性（`t/nil`）。

**Original**: Returns the visibility (
t/nil
) of a fully qualified layer.

**语法**：
```skill
axlIsVisibleLayer("pin/top") ⇒ t
axlLayerCreateCrossSection – Obsolete
This function is obsolete, use
axlXSectionCreate
.
```

**参数** (Arguments)：

t_layer
- **Name** — of layer in format "<
class
>/<
subclass
>".

**返回值** (Value Returned)：

t
Layer is visible.
nil
Layer is invisible or not present.

**示例** (Examples)：

axlIsVisibleLayer("pin/top") ⇒ t
axlLayerCreateCrossSection – Obsolete
This function is obsolete, use
axlXSectionCreate
.

### axlLayerCreateNonConductor

**说明**：为非蚀刻子类创建新的子类。AXL-SKILL 限制您创建蚀刻子类。

**Original**: Creates a new subclass for non-etch subclasses. AXL-SKILL restricts you from creating etch subclasses.

**语法**：
```skill
axlLayerCreateNonConductor("BOARD GEOMETRY/MYSUBCLASS")
Creates a new subclass named
MYSUBCLASS
.
```

**参数** (Arguments)：

t_layerName
<
class
>
/
<
subclass
>

**返回值** (Value Returned)：

t
New subclass is created or, subclass already exists.
nil
New subclass is not created.

**示例** (Examples)：

axlLayerCreateNonConductor("BOARD GEOMETRY/MYSUBCLASS")
Creates a new subclass named
MYSUBCLASS
.

### axlLayerDelete

**说明**：删除横截面层。虽然 `axlDeleteObject` 可用于删除空命名层，但此 API 可以删除命名和未命名的横截面层。横截面具有 ETCH 层和未命名的介电层。横截面的顺序由 `axlGetXSection` 返回。`x_layerNumber` 是横截面中的顺序，第一个索引号（例如 AIR）从 0 开始。删除包含几何图形（不包括引脚或过孔）的命名层、删除顶层或底层介电层或顶层或底层蚀刻层、层名称不存在、层号小于 0 或大于等于 `length(axlGetXSection('count))` 时命令可能失败。

**Original**: This command deletes a cross section layer. While
axlDeleteObject
can be used to delete empty named layers, this API can delete both named and unnamed cross-section layers.The cross section has both ETCH layers and unnamed dielectric layers.The order of the cross section is returned by
axlGetXSection – Obsolete
. The
x_layerNumber
is the order within the cross-section with the first index number (e.g AIR) starting at 0.
The command can fail in the following scenarios.
Deleting a named layer containing geometries (excluding pins or vias)
Deleting top or bottom dielectric or TOP or BOTTOM etch layers
Layer name does not exist
Layer number is less then 0 or greater or equal to
length(axlGetXSection(’count))

**语法**：
```skill
axlLayerDelete("EMTPY")
Delete the third cross section layer. On most designs this is an unnamed dielectric layer between TOP and the next etch layer.
axlLayerDelete(3)
```

**参数** (Arguments)：

- **ETCH** — layer string or cross section index

**返回值** (Value Returned)：

t
if layer is deleted,
nil
if failure

**示例** (Examples)：

The command to delete a layer named empty is:
axlLayerDelete("EMTPY")
Delete the third cross section layer. On most designs this is an unnamed dielectric layer between TOP and the next etch layer.
axlLayerDelete(3)

**参见** (See Also)：

axlLayerCreateNonConductor
,
axlDeleteByLayer
,
axlDeleteObject
,
axlGetXSection – Obsolete
,
axlXSectionDelete

### axlLayerExternal

**说明**：返回层是否为外部层。

**Original**: Returns if layer is external.

**参数** (Arguments)：

t_subclass
- **Subclass** — name
x_subclassNumber
- **The** — subclass number (Does not mean the cross-section number)

**返回值** (Value Returned)：

t
External
nil
Not external

**示例** (Examples)：

On a design
axlGetExternalLayers("TOP") -> t
On a design
axlGetExternalLayers(0) -> t

**参见** (See Also)：

axlXSectionGet
,
axlGetExternalLayers

### axlLayerGet

**说明**：获取给定快捷符号 `<class>/<subclass>` 的层参数。这是一个易用函数，执行：`axlGetParam("paramLayerGroup:<class>/paramLayer:<subclass>)`。此函数不允许访问横截面数据（例如材料或厚度）。它允许更容易地访问层的颜色和可见性。

**Original**: Gets the layer parameter given the shortcut notation of
<
class
>
/
<
subclass
>
. This is an ease of use function that does:
axlGetParam("paramLayerGroup:<class>/paramLayer:<subclass>)
This function does NOT allow access to the cross-section data (for example, material or thickness). It allows easier access to color and visibility of a layer.
You can use the groupMembers attribute of result —
result=axlGetParam("paramLayerGroup:<class>")
— to iterate over all subclass of a class.

**语法**：
```skill
axlLayerGet
```

**参数** (Arguments)：

t_layer
- **Name** — of layer in format "<
class
>/<
subclass
>".

**返回值** (Value Returned)：

o_dbid
Layer parameter
dbid
.
nil
Layer is not present.

**示例** (Examples)：

Changes color of top etch layer.
q = axlLayerGet("ETCH/TOP")
q->color = 7
axlLayerSet(q)
axlVisibleUpdate(t)

**参见** (See Also)：

axlGetParam
axlLayerRenameNonConductor
axlLayerRenameNonConductor (
t_oldLayerName
t_newLayerName
)
⇒ t/nil

### axlLayerViaLabel

**说明**：报告层的过孔标签（Via Label）。过孔标签默认是层号，或者可以通过横截面由用户分配。

**Original**: Reports via label for a layer. A via label either defaults to the layer number, or can be assigned by the user through the cross-section. You can query the cross-section for an override.

**语法**：
```skill
axlLayerViaLabel("TOP")-> 1
```

**参数** (Arguments)：

- **ETCH** — layer string or cross-section index

**返回值** (Value Returned)：

Via label name; or
nil
, in case of an error

**示例** (Examples)：

To return the via label of a layer called TOP
axlLayerViaLabel("TOP")-> 1

**参见** (See Also)：

axlXSectionGet

### axlMaterialGet

**说明**：返回有关材料文件的各种信息。根据传递的参数，命令以不同模式工作以检索：材料列表、材料文件条目数、正在使用的材料文件名称（PCB 和 IC 封装产品之间不同）、材料文件路径、材料文件条目的实际属性。

**Original**: Returns various information about materials file. Depending on the argument passed, command works in different modes to retrieve the following.
List of materials
Number of material file entries
Name of material file being used; this differ between PCB and IC Packaging products
Path to material file
actual attributes of a material file entry
Material attributes as a disembodied property list:
NAME
TYPE
DESCRIPTION
dielectric
double
Dielectric Constant
freqDepFile
string
Name of frequency  dependent file or ""
electricalConductivity
string
Electrical Conductivity in mho/cm
lossTangent
double
Loss Tangent
name
string
Name of material
objType
string
"material"
readOnly
t
Cannot modify object
thermalConductivity
string
Thermal Conductivity in w/cm-degC
thickness
string
Layer thickness with design units
tolPlus
string
Layer thickness tolerance plus with design units
tolMinus
string
Layer thickness tolerance minus with design units
On Windows, performance may be slow, when accessing individual material entries in material file is stored on the network.

**语法**：
```skill
axlMaterialGet(
t_materialName
)
==> og_material
axlMaterialGet(
'all
)
==> log_materials
axlMaterialGet(
'file
)
==> t_file
axlMaterialGet(
'path
)
==> t_pathToFile
```

**参数** (Arguments)：

nil
- **List** — of material names
t_materialName
- **Name** — of material
'all
- **Get** — all material data
'filename
- **Get** — name of material file (Allegro uses ’material’ and IC Packaging products uses ’mcmmat’
'path
- **Return** — location of file on disk

**返回值** (Value Returned)：

nil
An error was detected
lt_materialNames
A list of the material names
og_materials
Disembodied property list of material characteristics (see above)
log_materials
A list of disembodied property lists
t_file
Name of material file in use
t_pathToFile
Path to material file in use

**示例** (Examples)：

Get info about FR-4
mat = axlMaterialGet("FR-4")
printf("Thicknesss %L\n" mat->thickness)
Get all materials defined in the materials file
names = axlMaterialGet(nil)
Get path of file
path = axlMaterialGet('path)

### axlVisibleDesign

**说明**：使整个设计可见或不可见。此命令在视觉上不会更改显示，因为它也可以与 `axlSelect` 命令系列一起使用，以在选择集查找数据库对象时提供额外的过滤功能。如果希望视觉上更新显示，请在更改可见性后调用 `axlUIWUpdate(nil)`。此例程与 `axlVisibleGet` 和 `axlVisibleSet` 允许您临时更改设计的可见性，以在选择集通过查找对象时提供额外的过滤功能。编程模型为：保存可见性、设置所有不可见、设置所需层可见、设置查找过滤器、使用 Select API 查找对象、恢复可见性。

**Original**: Makes entire design visible or invisible. This command does not visually change the display, since it can also be used in conjunction with the
axlSelect
command family to provide additional filtering of the database objects. If you wish to visually update the display, call
axlUIWUpdate(nil)
after changing the visibility.
This routine along with
axlVisibleGet
and
axlVisibleSet
allows you to temporarily change the visibility of the design to provide additional filtering capability when finding objects via the selection set. The programming model is:
saveVis = axlVisibleGet()
axlVisibleDesign(nil)
; set desired layers visible via one or more calls to
axlVisibleLayer(...)
; set find filter for objects to find
axlSetFindFilter(...)
; find objects by using one of the Select APIs .. example
axlAddSelectAll()
objs = axlGetSelSet()
; restore visiblility
axlVisibileSet(saveVis)
; note no need to make a call to axlVisibileUpdate because
; the visisbility changes are a wash

**语法**：
```skill
axlVisibleDesign(nil)
; set desired layers visible via one or more calls to
axlVisibleLayer(...)
; set find filter for objects to find
axlSetFindFilter(...)
; find objects by using one of the Select APIs .. example
axlAddSelectAll()
objs = axlGetSelSet()
; restore visiblility
axlVisibileSet(saveVis)
; note no need to make a call to axlVisibileUpdate because
; the visisbility changes are a wash
```

**参数** (Arguments)：

g_makeVis
Either
t
or
nil
.
t
= make entire design visible
nil
= make entire design invisible

**返回值** (Value Returned)：

t
Design made visible or invisible as specified.
nil
Should never be seen.

**参见** (See Also)：

axlVisibleUpdate
and
axlIsVisibleLayer
This command does not visually change the display. To visually update the display, call
axlUIWUpdate (nil)
after changing the visibility.

### axlVisibleGet

**说明**：返回整个设计的可见性 — 哪些层可见/不可见。返回值为列表的列表。对于每个类，格式为：(nil class <t_className> visible t/nil/-1 subclassinfo <l_subclass> ...)... 其中 `l_subclass` 格式为：((<t_subclass> t/nil) ...)... `t` - 可见，`nil` - 不可见，`-1` - 类同时具有可见和不可见的组件。

**Original**: Returns the visibility of the entire design - which layers are visible/invisible.

**参数** (Arguments)：

None.

**返回值** (Value Returned)：

l_visList
List of lists. The format is for each class:
(nil class <
t_className
> visible t/nil/-1
subclassinfo <
l_subclass
>)
....)
l_subclass
format:
((<
t_subclass
> t/nil) ....)
where t/nil/-1
t - visible
nil - invisible
-1 - class has both visible and invisible components.
Any change in the structure of
l_vislist
affects
axlVisibleSet
, this function’s complementary function.

**示例** (Examples)：

visList = axlVisibleGet()
(
(nil class "BOARD GEOMETRY" visible nil subclassinfo nil)
(nil class "COMPONENT VALUE" visible nil subclassinfo nil)
(nil class "DEVICE TYPE" visible nil subclassinfo nil)
(nil class "DRAWING FORMAT" visible nil subclassinfo nil)
(nil class "DRC ERROR CLASS" visible t subclassinfo nil)
(nil class "ETCH" visible -1
subclassinfo
(("TOP" t)
("TRACE_2" nil)
("TRACE_3" nil)
("BOTTOM" t)
))
(nil class "MANUFACTURING" visible nil subclassinfo nil)
(nil class "ANALYSIS" visible nil subclassinfo nil)
(nil class "PACKAGE GEOMETRY" visible nil subclassinfo nil)
(nil class "PACKAGE KEEPIN" visible t subclassinfo nil)
(nil class "PACKAGE KEEPOUT" visible nil subclassinfo nil)
(nil class "PIN" visible t subclassinfo nil)
(nil class "REF DES" visible nil subclassinfo nil)
(nil class "ROUTE KEEPIN" visible t subclassinfo nil)
(nil class "ROUTE KEEPOUT" visible nil subclassinfo nil)
(nil class "TOLERANCE" visible nil subclassinfo nil)
(nil class "USER PART NUMBER" visible nil subclassinfo nil)
(nil class "VIA CLASS" visible nil subclassinfo nil)
(nil class "VIA KEEPOUT" visible nil subclassinfo nil)
)
Returns the visibility of the entire design.

### axlVisibleLayer

**说明**：将给定层设置为可见或不可见。如果仅给定类名，则将整个层设置为可见或不可见。如果希望更新显示，请在完成层可见性更新后调用 `axlVisibleUpdate`。

**Original**: Sets a given layer to visible or invisible. If given only a class name, sets the entire layer to visible or invisible. If you want to update the display, call
axlVisibleUpdate
when finished with your layer visibility updates.

**参数** (Arguments)：

t_layer
- **Name** — of the layer. Either a fully qualified layer name in the format
<
class
>
/
<
subclass
>
- **or** — a class name in the format
<
class
>
.
g_makeVis
Either
t
or
nil
.
t
= make visible
nil
= make invisible.

**返回值** (Value Returned)：

t
Layer set to visible or invisible as specified.
nil
Layer does not exist.

**参见** (See Also)：

axlVisibleUpdate
This command does not visually change the display. To visually update the display, call
axlUIWUpdate (nil)
after changing the visibility.

### axlVisibleSet

**说明**：设置整个设计的可见性。此命令在视觉上不会更改显示。要视觉上更新显示，请在更改可见性后调用 `axlUIWUpdate(nil)`。

**Original**: Sets the visibility of the entire design.

**参数** (Arguments)：

l_visList
- **List** — with visibility attributes.

**返回值** (Value Returned)：

t
Set the visibility of the design as specified.
nil
Incorrect format for
l_visList
.

**参见** (See Also)：

axlVisibleUpdate
and
axlVisibleLayer
This command does not visually change the display. To visually update the display, call
axlUIWUpdate (nil)
after changing the visibility.

### axlConductorBottomLayer

**说明**：返回底层导体层的名称。

**Original**: Returns the name of the bottom conductor layer.

**语法**：
```skill
axlConductorBottomLayer()
⇒ "BOTTOM"
```

**参数** (Arguments)：

none

**返回值** (Value Returned)：

t_name
Name of the bottom conductor layer.

**示例** (Examples)：

axlConductorBottomLayer()
⇒ "BOTTOM"

### axlConductorTopLayer

**说明**：返回顶层导体层的名称。

**Original**: Returns the name of the top conductor layer.

**语法**：
```skill
axlConductorTopLayer()
⇒ "TOP"
axlDBCreateFilmRec – Obsolete
This interface is obsolete. It is kept to support existing SKILL code.
Instead, use
axlFilmCreate
```

**参数** (Arguments)：

none

**返回值** (Value Returned)：

t_name
Name of the top conductor layer.

**示例** (Examples)：

axlConductorTopLayer()
⇒ "TOP"
axlDBCreateFilmRec – Obsolete
This interface is obsolete. It is kept to support existing SKILL code.
Instead, use
axlFilmCreate

### axlSetPlaneType

**说明**：将导体层或平面类型层的光绘类型在正片或负片图稿之间更改。更改已包含数据的层将需要重新对现有 Shape 进行挖空并更新 DRC。

**Original**: This changes the photoplot type of a conductor or plane type layer between positive or negative artwork. Changing a layer already containing data will require re-voiding existing shapes and updating DRC.

**参数** (Arguments)：

t_subclassName
- **Subclass** — name whose plane type is to be changed.
t_planeType
- **Plane** — type (“Positive”, “Negative”)

**返回值** (Value Returned)：

t
Plane type changed.
nil
Plane type is not changed.

**参见** (See Also)：

axlGetParam
,
axlSetParam

### axlSubclasses

**说明**：列出组成类的子类。此函数在 APD 和 Allegro 名称空间中都受支持。`field` 和 `value` 选项根据层特性提供额外的过滤。

**Original**: Lists subclasses that make up a class. This function is supported in both, APD and Allegro name space. The field and value options provide additional filtering based upon the characteristics of the layer.
The information about the attributes and values permitted on a layer, can be obtained using the following function.
axlLayerGet("MANUFACTURING/PROBE_TOP")->??
You should map the class name via axlMapClassName if you are writing code for both PCB and APD+ as certain class names are different in these products.
The base call is actually just:
axlGetParam("paramLayerGroup:ETCH")->groupMembers

**语法**：
```skill
axlSubclasses( axlMapClassName("MANUFACTURING"))
get user defined subclasses
axlSubclasses("MANUFACTURING" ?field 'userDefined)
all allegro defined
axlSubclasses("MANUFACTURING" ?field 'userDefined ?value nil)
```

**参数** (Arguments)：

t_class
- **Class** — name.
field
- **Optional** — field for filtering. If value option is not present filters on basis of a non-nil value.
value
- **Optional** — value of field to use for filtering. Requires field option to be passed.
- **Values** — Returned
lt_subclasses
- **A** — list of subclass strings.

**示例** (Examples)：

get all subclasses on class
axlSubclasses( axlMapClassName("MANUFACTURING"))
get user defined subclasses
axlSubclasses("MANUFACTURING" ?field 'userDefined)
all allegro defined
axlSubclasses("MANUFACTURING" ?field 'userDefined ?value nil)

**参见** (See Also)：

axlSubclassRoute
,
axlGetParam
,
axlMapClassName
,
axlClasses

### axlSubclassRoute

**说明**：列出组成 ETCH 类的子类。如果未向函数传递参数，则返回 ETCH 类中的子类列表，或在非 PCB 产品的情况下返回 CONDUCTOR 类中的子类列表。`field` 和 `value` 选项根据层特性提供额外的过滤。

**Original**: Lists subclasses that make up class ETCH.
If no arguments are passed to the function, it returns a list of subclasses in the ETCH class, or CONDUCTOR class, in case of non-PCB product.
The field and value options provide additional filtering based upon the characteristics of the layer. For information on layer parameters, see the section Layer Parameter Attributes (Allegro Subclasses).
The information about the attributes and values permitted on a layer can be obtained using the following command.
axlLayerGet("ETCH/TOP")->??
The base call is actually just:
axlGetParam("paramLayerGroup:ETCH")->groupMembers

**语法**：
```skill
axlSubclassRoute() -> ("TOP" "GND" "VCC" "BOTTOM")
all subclasses that are of type etch
axlSubclassRoute(?field 'isEtch)
all subclasses that are not etch (e.g dielectric)
axlSubclassRoute(?field 'isEtch ?value nil)
all subclasses with material FR-4
axlSubclassRoute(?field 'material ?value "FR-4")
```

**参数** (Arguments)：

field
- **Optional** — field for filtering. Uses the value specified by the
value
- **argument** — to filter subclasses.
value
- **Optional** — value of field to use for filtering. Requires field option to be passed.
- **Values** — Returned
- **List** — of subclass as strings.

**示例** (Examples)：

all etch subclasses
axlSubclassRoute() -> ("TOP" "GND" "VCC" "BOTTOM")
all subclasses that are of type etch
axlSubclassRoute(?field 'isEtch)
all subclasses that are not etch (e.g dielectric)
axlSubclassRoute(?field 'isEtch ?value nil)
all subclasses with material FR-4
axlSubclassRoute(?field 'material ?value "FR-4")

**参见** (See Also)：

axlSubclasses
,
axlGetParam

### axlXSectionAssign

**说明**：将现有层分配给横截面。在推荐的模型中，它用于从主横截面构建额外的横截面。使用 `axlXSectionCreate` 创建横截面层。此 API 应用于管理多个横截面。如果不进行刚挠设计，则不应使用。符号编辑器中不支持。

**Original**: Assigns an existing layer to a cross-section. In the recommended model, it is used in building additional cross-sections from the primary cross-section.
Use
axlXSectionCreate
to a create a cross-section layer.
This API should be used to manage multiple cross-sections. Should not be used if you are not doing rigid-flex design. It is not supported in the symbol editor.

**参数** (Arguments)：

t_crossSection
- **Name** — of cross-section
nil
- **is** — the primary cross-section
g_layer
- **Can** — be:
- **o_xsectionDBid** — - Cross-section dbid
- **t_layerName** — - name of etch layer
- **x_number** — - position of entry in "All Stackups"
og_layer
- **List** — of layers to assign

**返回值** (Value Returned)：

t
Layer assigned (if layer is already part stackup returns
t
)
nil
Failed, illegal name, editor does not support this interface or assignment not permitted

**示例** (Examples)：

see
<cdsroot>/share/pcb/examples/skill/dbcreate/xsection.il

**参见** (See Also)：

axlXSectionCreate

### axlXSectionCopy

**说明**：将 dbid 横截面复制到 xsection SKILL defstruct。它可用于将现有横截面层的特性复制到新层，以供 `axlXSectionCreate` 使用。或者，它可用于通过 `axlXSectionSet` 修改现有层，尽管 `axlXSectionModify` 可能更适合更改层。此函数使用 `make_axlXSection()` 创建新的 defstruct。`name` 属性永远不会被复制。

**Original**: This copies dbid xsection to an xsection SKILL defstruct. It can be used to duplicate the characteristics of an existing xsection layer to a new layer for use with axlXSectionCreate. Alternatively, it can be used to modify an existing layer via axlXSectionSet, although axlXSectionModify might be a better fit for changing a layer.
This creates a new defstruct using
make_axlXSection()
.The name attribute is never copied.
If using this to copy named layers, you need to set the name attribute in the defstruct returned by this function.

**参数** (Arguments)：

o_xsectionDBID
- **a** — xsection dbid

**返回值** (Value Returned)：

g_xsectionDefstruct
a defstruct with its attribute data copied from dbid

**示例** (Examples)：

See
<cdsroot>/share/pcb/examples/skill/dbcreate/xsection.il

**参见** (See Also)：

axlXSectionCreate
,
axlXSectionModify

### axlXSectionCreate

**说明**：创建新的横截面条目。`g_xsectionDefStruct` 中三个关键的创建项是：name（层名称的字符串）、layerType（描述层类型的字符串，如 CONDUCTOR、PLANE、DIELECTRIC 或 MASK）、material（描述横截面层物质的字符串，如介电层的 FR-4 或导体/平面层的 COPPER）。如果未提供属性，则创建未命名的横截面条目，类型为 DIELECTRIC，材料为 FR-4。对于命名横截面层，它在蚀刻层上创建类/子类，但不会为这些层设置颜色和可见性。您需要使用 `axlLayerSet` 设置这些属性。Allegro PCB Editor 不允许在 TOP 上方或 BOTTOM 下方命名层。支持创建多个横截面的两种模型：分配和直接创建。推荐模型是分配。

**Original**: Creates a new cross-section entry.
The three critical create items in
g_xsectionDefStruct
are:
name – a string which is a name of the layer
layerType – a string (see
axlXSectionLayerTypes()
for supported of types) that describes the type of layer.
Popular types are CONDUCTOR, PLANE, DIELECTRIC or MASK. If no value is specified, DIELECTRIC is used as the default value.
material – a string that describes substance making up the cross-section layer. If no value is specified, FR-4 is used as the default value for dielectrics and COPPER for conductor or plane layers.
If no attributes are provided, an unnamed cross-section entry of type DIELECTRIC, with material FR-4 is created.
You can set other cross-section entries, see
axlXSectionGet
for a description of the other available attributes. If material is provided it will auto-fill additional attributes based upon the material file entry.
For named cross-section layers, it creates a class/subclass on the etch layers, it does not set the color and visibility for those layers. You need to use
axlLayerSet
for those attributes.
Allegro PCB Editor does not allow name layers above TOP or below BOTTOM layers.
CREATING AND POPULATING MULTIPLE CROSS-SECTIONS
Two models are supported for creating multiple cross-section; assign and create directly. The recommend model is assign.
The ASSIGN model:
Create all the stackups (
axlXSectionCreateStackup
).
Optionally, rename the Primary stackup (
axlXSectionRename
).
Populate the "All Stackups" (use nil as the first argument to
axlXSectionCreate
) with the layers. All internal (etch and dielectric) layers are assigned to all stackups.
Create required mask layers (axlXSectionCreate).
Assign (
axlXSectionAssign
) the non-mask layers to the non-primary stackups
Remove (
axlXSectionRemove
) any mask layer which is not required in the primary stackup.
By default, all layers created in this model are initially assigned to the primary stackup. The downside with this model is that unwanted layers from the primary stackup are to be removed.
The CREATE DIRECTLY mode
Create all the stackups (
axlXSectionCreateStackup
).
Optionally, rename the primary stackup (
axlXSectionRename
).
Provide a stackup name to
axlXSectionCreate
when creating a layer. If the layer is an ETCH layer, it is also assigned to the primary stackup.
Must assign dielectric layers to primary since only ETCH layers are automatically assigned to this stackup.
Assign (axlXSectionAssign) layers to any additional stackups.
The downside of this model is to assign (axlXSectionAssign) mask or internal layers if required in multiple stackups. This is also true for any dielectric layers that must be in the primary stackup.
PROGRAMMING TIPS
For populating multiple internal layers, use the
'bottom
option and build the stackup from bottom to top.
Use
'afterBottom
option to assign MASK layers below BOTTOM.
Ensure that there is at least one dielectric layer between each CONDUCTOR or PLANE layer type. Adjacent routing layers are allowed, but this results in incorrect signal analysis.
Do not name dielectric layers unless you want to physically add and edit objects to those layers. In Allegro PCB Editor, every named layers creates an entry in the class/subclass table on ETCH related classes.
Material names that are not contained in the materials  file, can also be specified. Setting environment variable “
xsection_material_warning
” prints a warning. When unknown materials are specified the thickness and other associated data are not populated.
Changing the material also updates its associated data. This is only an issue with the
axlXSectionSet
API.
layerId defaults to the layer number.
When creating MASK layers, you must provide the
?name
option. If you provide both, a
?name
and
?maskLayer
option, then
?maskLayer
name wins.
MASK layers added between TOP and BOTTOM do not effect connectivity.
Constraint Manager removes the '_' in pretty printing layerFunction.This interface requires them (see types returned by
axlXSectionLayerFunctions
API). Mask and dielectric have different allowed function types.
Use
axlXSectionModify
or
axlXSectionCopy
to create the
axlXSection
defstruct. Do not directly call
make_axlXSection
.
DRC is marked out of date with cross-section changes.

**语法**：
```skill
axlXSectionCreate
) with the layers. All internal (etch and dielectric) layers are assigned to all stackups.
Create required mask layers (axlXSectionCreate).
Assign (
axlXSectionAssign
) the non-mask layers to the non-primary stackups
Remove (
axlXSectionRemove
) any mask layer which is not required in the primary stackup.
By default, all layers created in this model are initially assigned to the primary stackup. The downside with this model is that unwanted layers from the primary stackup are to be removed.
The CREATE DIRECTLY mode
Create all the stackups (
axlXSectionCreateStackup
).
Optionally, rename the primary stackup (
axlXSectionRename
).
Provide a stackup name to
axlXSectionCreate
when creating a layer. If the layer is an ETCH layer, it is also assigned to the primary stackup.
Must assign dielectric layers to primary since only ETCH layers are automatically assigned to this stackup.
Assign (axlXSectionAssign) layers to any additional stackups.
The downside of this model is to assign (axlXSectionAssign) mask or internal layers if required in multiple stackups. This is also true for any dielectric layers that must be in the primary stackup.
PROGRAMMING TIPS
For populating multiple internal layers, use the
'bottom
option and build the stackup from bottom to top.
Use
'afterBottom
option to assign MASK layers below BOTTOM.
Ensure that there is at least one dielectric layer between each CONDUCTOR or PLANE layer type. Adjacent routing layers are allowed, but this results in incorrect signal analysis.
Do not name dielectric layers unless you want to physically add and edit objects to those layers. In Allegro PCB Editor, every named layers creates an entry in the class/subclass table on ETCH related classes.
Material names that are not contained in the materials  file, can also be specified. Setting environment variable “
xsection_material_warning
” prints a warning. When unknown materials are specified the thickness and other associated data are not populated.
Changing the material also updates its associated data. This is only an issue with the
axlXSectionSet
API.
layerId defaults to the layer number.
When creating MASK layers, you must provide the
?name
option. If you provide both, a
?name
and
?maskLayer
option, then
?maskLayer
name wins.
MASK layers added between TOP and BOTTOM do not effect connectivity.
Constraint Manager removes the '_' in pretty printing layerFunction.This interface requires them (see types returned by
axlXSectionLayerFunctions
API). Mask and dielectric have different allowed function types.
Use
axlXSectionModify
or
axlXSectionCopy
to create the
axlXSection
defstruct. Do not directly call
make_axlXSection
.
DRC is marked out of date with cross-section changes.
```

**参数** (Arguments)：

nil
- **default** — stackup (primary or All stackups)
t_
stack
up
- **in** — a multi-stackup design the name of the stackup
g_option
'top
- **insert** — layer above TOP. For PCB designs this can only be a unnamed dielectric or MASK layers.
'bottom
- **insert** — layer above BOTTOM
'afterBottom
- **insert** — layer after BOTTOM. For PCB Designs this can only be unnamed dielectrics or MASK layers.
t_etchSubclass
- **subclass** — name, insert layer above this name
x_position
- **insert** — above cross-section position.This is the number field in the cross-section dbid. In designs with one cross-section, you can also use the position attribute. You cannot insert above 0 (Surface).
g_xsectionDefStruct
or
nil
- **A** — SKILL defstruct with all possible attributes for cross-section entry
make_axlXSection
- **creates** — a new entry
copy_axlXSection
- **copies** — an existing entry
axlXSectionCopy
- **copies** — contents of an existing cross-section dbid to a new defstruct.

**返回值** (Value Returned)：

o_xsectionDBID
if successful
nil
failed.

**示例** (Examples)：

See
<cdsroot>/share/pcb/examples/skill/dbcreate/xsection.il

**参见** (See Also)：

axlXSectionGet
,
axlXSectionSet
,
axlXSectionDelete
,
axlXSectionLayerTypes
,
axlXSectionCopy
,
axlXSectionModify
,
axlXSectionLayerFunctions
,
axlXSectionCreateStackup
,
axlXSectionDeleteStackup
,
axlXSectionRename
,
axlXSectionAssign
,
axlXSectionRemove
, axlZoneCreate

### axlXSectionCreateStackup

**说明**：创建具有名称 `t_name` 的新空堆叠。如果不进行刚挠设计，则不应使用。符号编辑器中不支持。

**Original**: This creates a new empty stackup with name,
t_name
.
Should not be used if you are not doing rigid-flex design. It is not supported in the symbol editor.

**参数** (Arguments)：

t_crossSection
- **Name** — of stackup (case insensitive)

**返回值** (Value Returned)：

t
Stackup created
nil
Failed, stackup exists, illegal name, editor does not support this interface or exhausted the maximum number of stackups

**示例** (Examples)：

See
<cdsroot>/share/pcb/examples/skill/dbcreate/xsection.il

**参见** (See Also)：

axlXSectionCreate

### axlXSectionDelete

**说明**：删除横截面层。如果层与 ETCH 层关联，则关联层也会被删除。关联的 ETCH 层必须没有对象。有关失败的其他原因，请参阅 `axlLayerDelete`。

**Original**: Deletes a cross section layer. If layer is associated with an ETCH layer, the associated layer is also deleted. Associated ETCH layers must not have objects. See
axlLayerDelete
for other reasons for failure.

**参数** (Arguments)：

g_option
o_xsectionDBID
- **delete** — layer by XSection dbid
t_etchSubclass
- **delete** — layer by this name
x_position
- **delete** — layer by position. This is the position attribute in the xsection dbid.

**返回值** (Value Returned)：

t
if successful
nil
failed.

**示例** (Examples)：

See
<cdsroot>/share/pcb/examples/skill/dbcreate/xsection.il

**参见** (See Also)：

axlXSectionCreate
, axlLayerCreate,
axlDeleteByLayer

### axlXSectionDeleteStackup

**说明**：删除名称为 `t_name` 的堆叠。无法删除已分配给区域的堆叠。

**Original**: Deletes a stackup with name
t_name
. Cannot delete a stackup assigned to a zone.

**语法**：
```skill
axlXSectionDeleteStackup("flex1")
```

**参数** (Arguments)：

t_crossSection
- **Name** — of stackup (case insensitive)

**返回值** (Value Returned)：

t
Stackup is deleted
nil
Stackup is in use or not found

**示例** (Examples)：

Delete a "flex1" created by RigidFlexCreate()
in
<cdsroot>/share/pcb/examples/skill/dbcreate/xsection.il
see
axlXSectionCreateStackup
axlXSectionDeleteStackup("flex1")

**参见** (See Also)：

axlXSectionCreate

### axlXSectionGet

**说明**：返回有关设计横截面条目的数据。支持多种访问选项（见参数）。Allegro 设计颜色和可见性查询需求由 `axlLayerGet` API 满足。

**Original**: Returns data about the cross-section entry for a design.
Supports multiple access options (see Arguments).
Allegro design color and visibility query needs are satisfied by the
axlLayerGet
API.

**语法**：
```skill
axlXSectionGet(nil 'stackups)
g_option
'stackups
return a list of stacks. g_xsection is ignored and should be nil
'count
return number of cross-section entries for provided stackup. g_data is x_entries
'number
return maximum number of individual stackups database supports
'thickness
return provided stackup thickness in user units g_data is f_thickness design units, accuracy is not restricted to current design accuracy. This is the total thickness with masks.
'top
return cross-section entry for top layer of design
'bottom
return cross-section entry for bottom layer of design
x_position
return cross-section entry for given position in "All stackups". This is the number field in a cross-section dbid. (0 is the 1st layer -- air)
t_etchSubclass
name of etch subclass. g_data is a o_xsectionDBID
'all
return entire stackup. g_data must be a lo_xsectionDBID
'locked
lock status
nil - not locked
list of lock status. This is a user interface lock only. SKILL and techfile can make changes.
'
value
: cannot edit values
'
layer
: add or delete layers
The name of the stackup can be obtained from the zone dbid by zoneDbid->stackup
If using a single stackup in a design pass
nil
as the first argument.
If a multi-stackup design, a nil returns all of the cross-section dbids (for example, "All Stackups"). If you need the main stackup, typically called “primary”, use its name.
Except for
'stackups
and
'locked
all other options take into account the stackup argument.
For
'thickness
if
g_xsection
is nil, the stackup thickness is returned, which can be overridden by the TEXT_BOARD_THICKNESS property assigned at the design level. Otherwise, if a stackup (
g_xsection
) name is provided, the calculated thickness of the indicated stackup is returned.
XSection Attributes:
Attributes that have Yes under Modify column can be set with APIs
axlXSectionCreate
and
axlXSectionSet
.
NAME
TYPE
Modify
DESCRIPTION
objType
string
No
"xsection"
readOnly
t
No
Cannot directly modify entry
constraint
string
Yes
(Optional) Techfile generic layer support (max 1023 chars).
conductor
t/nil
Yes
Is layer of conductor or plane?
layerType
string
Yes
Type of xsection layer.
layerFunction
string
Yes
Layer function of a layer. This is a superset of layer types for dielectric and mask layers. Conductor, plane and surface layers cannot have their layerFunction changed. When creating a layer, Allegro automatically assigns a default function based on the layer type. Can be nil (surface layers).
layerId
string
Yes
Override of via label id (max 3 characters)
material
string
Yes
Layer material (max 250 chars)
maskLayer
string
Yes
Mask layer associated with this cross-section entry.
This is
nil
unless the layerType is type MASK. If a string is present it will have the same name as the name field.
mfg
string
Yes
(Optional) Stackup layer grouping for IPC2581 (max 255 chars)
name
string/nil
Yes
Name of xsection/etch layer (max 47 chars).
negativeArtwork
t/nil
Yes
Layout is a negative image.
polyCutLayer
t/nil
Yes
Layer is a cut layer for poly vias. Only dielectric layers between the surface layers may be cut layers. You cannot unset a cut layer that is being used by a poly via.
position
integer
No
Position of xsection layer in stackup. This is relative to the stackup. (starts at 0 for SURFACE).
numb
er
integer
No
Absolute position which is the position in "All Stackups". In non-multi cross-section designs this has the same value as position.
prop
l_dbid
Yes
List of properties on object.
thickness
float
Yes
layer thickness in design units, stored with more accuracy then design
tolMinus
float
Yes
thickness tolerance - in design units, stored with more accuracy then design
tolPlus
float
Yes
thickness tolerance + in design units, stored with more accuracy then design
Pad suppression:
unusedPin
t/nil
Yes
suppress unused pads of pins on this layer
unusedVia
t/nil
Yes
suppress unused pads of vias on this layer
Embedded support:
embedded
string
Yes
Type of embedded layer (default NOT_EMBEDDED)
Values:
nil, NOT_EMBEDDED, BODY_UP, BODY_DOWN PROTRUDING_ALLOWED
embeddedAttach
string
Yes
Type of attachment if embedded layer.
Values:
nil, DIRECT_ATTACH, INDIRECT_ATTACH
Electrical parameters:
diffCouplingType
string
Yes
Diffpair routing on layer (Values: nil or EDGE)
diffSpacing
float
Yes
Typical diffpair spacing on this layer in design units (only if coupling type is set)
conductivity
string
Yes
Layer conductivity (MKS in mho/cm)
dielectricConst
string
Yes
Dielectric constant
etchFactor
integer
Yes
Vertical geometry of etch (angle 45-135 or 225-315 degrees)
freqDepFile
string
Yes
(optional) Frequency dependent file for this layer (max 255 chars)
lossTangent
string
Yes
Loss tangent value
shield
t/nil
Yes
Is this a shield layer
width
float
Yes
Typical layer width for Impedance what-ifs in design units
siIgnore
t/nil
Yes
SI should ignore this layer
```

**参数** (Arguments)：

g_stackup
nil
- **for** — cross-sections with a single stackup this returns the standard stackup. For Rigid-Flex designs this returns All Stackups.
str
- **name** — of stackup. From zone groups it is the name in zoneDbid -> stackup or available stackups are returned by
axlXSectionGet(nil 'stackups)
g_option
'stackups
- **return** — a list of stacks. g_xsection is ignored and should be nil
'count
- **return** — number of cross-section entries for provided stackup. g_data is x_entries
'number
- **return** — maximum number of individual stackups database supports
'thickness
- **return** — provided stackup thickness in user units g_data is f_thickness design units, accuracy is not restricted to current design accuracy. This is the total thickness with masks.
'top
- **return** — cross-section entry for top layer of design
'bottom
- **return** — cross-section entry for bottom layer of design
x_position
- **return** — cross-section entry for given position in "All stackups". This is the number field in a cross-section dbid. (0 is the 1st layer -- air)
t_etchSubclass
- **name** — of etch subclass. g_data is a o_xsectionDBID
'all
- **return** — entire stackup. g_data must be a lo_xsectionDBID
'locked
- **lock** — status
- **nil** — - not locked
- **list** — of lock status. This is a user interface lock only. SKILL and techfile can make changes.
'
value
: cannot edit values
'
layer
: add or delete layers
- **The** — name of the stackup can be obtained from the zone dbid by zoneDbid->stackup
- **If** — using a single stackup in a design pass
nil
- **as** — the first argument.
- **If** — a multi-stackup design, a nil returns all of the cross-section dbids (for example, "All Stackups"). If you need the main stackup, typically called “primary”, use its name.
- **Except** — for
'stackups
and
'locked
- **all** — other options take into account the stackup argument.
For
'thickness
if
g_xsection
- **is** — nil, the stackup thickness is returned, which can be overridden by the TEXT_BOARD_THICKNESS property assigned at the design level. Otherwise, if a stackup (
g_xsection
) name is provided, the calculated thickness of the indicated stackup is returned.
- **XSection** — Attributes:
- **Attributes** — that have Yes under Modify column can be set with APIs
axlXSectionCreate
and
axlXSectionSet
.
NAME
TYPE
Modify
DESCRIPTION
objType
string
No
"xsection"
readOnly
t
No
- **Cannot** — directly modify entry
constraint
string
Yes
(Optional) Techfile generic layer support (max 1023 chars).
conductor
t/nil
Yes
- **Is** — layer of conductor or plane?
layerType
string
Yes
- **Type** — of xsection layer.
layerFunction
string
Yes
- **Layer** — function of a layer. This is a superset of layer types for dielectric and mask layers. Conductor, plane and surface layers cannot have their layerFunction changed. When creating a layer, Allegro automatically assigns a default function based on the layer type. Can be nil (surface layers).
layerId
string
Yes
- **Override** — of via label id (max 3 characters)
material
string
Yes
- **Layer** — material (max 250 chars)
maskLayer
string
Yes
- **Mask** — layer associated with this cross-section entry.
- **This** — is
nil
- **unless** — the layerType is type MASK. If a string is present it will have the same name as the name field.
mfg
string
Yes
(Optional) Stackup layer grouping for IPC2581 (max 255 chars)
name
string/nil
Yes
- **Name** — of xsection/etch layer (max 47 chars).
negativeArtwork
t/nil
Yes
- **Layout** — is a negative image.
polyCutLayer
t/nil
Yes
- **Layer** — is a cut layer for poly vias. Only dielectric layers between the surface layers may be cut layers. You cannot unset a cut layer that is being used by a poly via.
position
integer
No
- **Position** — of xsection layer in stackup. This is relative to the stackup. (starts at 0 for SURFACE).
numb
er
integer
No
- **Absolute** — position which is the position in "All Stackups". In non-multi cross-section designs this has the same value as position.
prop
l_dbid
Yes
- **List** — of properties on object.
thickness
float
Yes
- **layer** — thickness in design units, stored with more accuracy then design
tolMinus
float
Yes
- **thickness** — tolerance - in design units, stored with more accuracy then design
tolPlus
float
Yes
- **thickness** — tolerance + in design units, stored with more accuracy then design
- **Pad** — suppression:
unusedPin
t/nil
Yes
- **suppress** — unused pads of pins on this layer
unusedVia
t/nil
Yes
- **suppress** — unused pads of vias on this layer
- **Embedded** — support:
embedded
string
Yes
- **Type** — of embedded layer (default NOT_EMBEDDED)
Values:
nil, NOT_EMBEDDED, BODY_UP, BODY_DOWN PROTRUDING_ALLOWED
embeddedAttach
string
Yes
- **Type** — of attachment if embedded layer.
Values:
nil, DIRECT_ATTACH, INDIRECT_ATTACH
- **Electrical** — parameters:
diffCouplingType
string
Yes
- **Diffpair** — routing on layer (Values: nil or EDGE)
diffSpacing
float
Yes
- **Typical** — diffpair spacing on this layer in design units (only if coupling type is set)
conductivity
string
Yes
- **Layer** — conductivity (MKS in mho/cm)
dielectricConst
string
Yes
- **Dielectric** — constant
etchFactor
integer
Yes
- **Vertical** — geometry of etch (angle 45-135 or 225-315 degrees)
freqDepFile
string
Yes
(optional) Frequency dependent file for this layer (max 255 chars)
lossTangent
string
Yes
- **Loss** — tangent value
shield
t/nil
Yes
- **Is** — this a shield layer
width
float
Yes
- **Typical** — layer width for Impedance what-ifs in design units
siIgnore
t/nil
Yes
- **SI** — should ignore this layer

**返回值** (Value Returned)：

nil
an error
g_data
depends on g_option, see

**示例** (Examples)：

Get design thickness
thick = axlXSectionGet(nil 'thickness)
Fetch entire cross-section
stackup = axlXSectionGet(nil 'all)
Fetch just the TOP layer
xs = axlXSectionGet(nil 'top)
Fetch dielectric below top-most layer
xs = axlXSectionGet(nil 'top)
dielectric = axlXSectionGet(nil xs->number +1)
axlPrintDbid(dielectric)
Get all stackups (even with one stackup will return PRIMARY)
stackups = axlXSectionGet(nil 'stackups)
Get stackup called FLEX2
zoneStackup = axlXSectionGet("FLEX2" 'all)
Get number of layers in FLEX2 (includes etc, dielectric and layers above surface)
zoneStackup = axlXSectionGet("FLEX2" 'count)
See
<cdsroot>
/share/pcb/examples/skill/dbcreate/xsection.il

### axlXSectionLayerFunctions

**说明**：返回支持的层功能类型列表。层功能是层类型的超集。

**Original**: Return list of supported layer function types. Layer functions are a super set of layer types.

**参数** (Arguments)：

None

**返回值** (Value Returned)：

List of strings of supported layer types.

**示例** (Examples)：

Get the list of layer functions:
types = axlXSectionLayerFunctions()

**参见** (See Also)：

axlXSectionCreate

### axlXSectionLayerTypes

**说明**：返回支持的层类型列表。这与添加或修改横截面层时使用的 `layerType` 属性一起使用。

**Original**: Return list of supported layer types. This is used with layerType attribute when adding or modifying xsection layers.

**参数** (Arguments)：

None

**返回值** (Value Returned)：

List of strings of supported layer types.

**示例** (Examples)：

only use types = axlXSectionLayerTypes()

**参见** (See Also)：

axlXSectionCreate

### axlXSectionModify

**说明**：这是 `make_axlXSection()` 函数的包装器，用于创建新的 defstruct。对于某些字段（例如布尔值和一些字符串字段），使用 `'none` 符号表示不应更改该字段，其他字段可以使用默认的 `nil` 符号。

**Original**: This is a wrapper for
make_axlXSection()
function to create a new defstruct. For certain fields (for example, boolean and some string fields) a
'none
symbol is used to indicate that the field should not be changed, other fields can use the default
nil
symbol.

**参数** (Arguments)：

- **Same** — as
make_axlXSection()
.

**返回值** (Value Returned)：

g_xsectionDefstruct
a defstruct with its attribute data copied from provided arguments

**示例** (Examples)：

Modify a layer to be negative artwork assume a layer named GND exists. All other layer characteristics will remain the same
xs = axlXSectionGet(nil "GND")
negative = axlXSectionModify(?negativeArtwork t)
ret = axlXSectionSet(xs negative)
See <cdsroot>
/share/pcb/examples/skill/dbcreate/xsection.il

**参见** (See Also)：

axlXSectionCreate

### axlXSectionRemove

**说明**：从指示的堆叠中移除层。层不会被删除，而是从堆叠中取消分配。有规则（请参阅横截面文档）用于层在堆叠中的成员资格。如果执行不允许的操作，则返回 `nil`。其典型用途是在构建多横截面设计时，从主横截面中移除掩模层。

**Original**: Removes a layer from indicated stackup. The layer is not deleted, it is de-assigned from a stackup. There are rules (see cross-section documentation) for layer membership in stackups. If you do something not permitted a nil is returned.
Its typical use is when building a multi-cross section design. It removes mask layers from the primary cross-section.
This is used to manage multiple cross-sections. It is not applicable to a single cross-section design. It is not supported in the symbol editor.
Use
axlXSectionDelete
if a layer should be deleted.

**参数** (Arguments)：

t_name
- **Name** — of stackup (case insensitive)
if
nil,
- **it** — uses the Primary stackup
g_layer
- **Can** — be:
o_xsectionDBid: Cross-section dbid
t_layerName: Name of etch layer
x_number: Position of entry in "All Stackups"
og_layer
- **List** — of layers to remove

**返回值** (Value Returned)：

t
Layer removed from stackup (if layer is already not part of the stackup it returns
t
)
nil
Failed, illegal name, editor does support interface, layer cannot be removed

**示例** (Examples)：

See
<cdsroot>/share/pcb/examples/skill/dbcreate/xsection.il

**参见** (See Also)：

axlXSectionCreate

### axlXSectionRename

**说明**：重命名堆叠。如果第一个参数为 `nil`，则重命名主堆叠。如果不进行刚挠设计，则不应使用。符号编辑器中不支持。

**Original**: Renames a stackup. If first argument is nil, renames the primary stackup.
Should not be used if you are not doing rigid-flex design.It is not supported in the symbol editor.

**语法**：
```skill
axlXSectionRename(nil "rigid")
```

**参数** (Arguments)：

t_crossSection
- **Existing** — name of stackup
t_newName
- **New** — name of stackup (case insensitive)

**返回值** (Value Returned)：

t
Stackup renamed
nil
Failed

**示例** (Examples)：

Assume a multi-stackup design rename the default primary name
axlXSectionRename(nil "rigid")

**参见** (See Also)：

axlXSectionCreate

### axlXSectionSet

**说明**：修改现有横截面条目。使用 `axlXSectionModify` 创建具有要修改属性的 xsection defstruct。如果更改材料，它还会更新新材料的材料特性。Allegro PCB Editor 不允许在顶层上方或底层下方命名层。DRC 被标记为过期。

**Original**: Modifies an existing cross-section entry. Use
axlXSectionModify
to create a xsection defstruct with the attributes you wish to modify.
See
axlXSectionGet
for a description of the other available attributes. If changing material, it also updates the material characteristics to values of the new material.
Allegro PCB editor does not allow name layers above top or below bottom.
PROGRAMM TIPS
:
See tips in
axlXSectionCreate
.
In Allegro PCB Editor, you cannot rename TOP or BOTTOM.
Cannot unname a layer with data on the ETCH layers.
DRC is marked out of date.

**语法**：
```skill
axlXSectionSet(
'locked
nil/l_lockType
) -> t/nil
```

**参数** (Arguments)：

nil
- **first** — argument must always be
nil
g_option
o_xsectionDBID
- **delete** — layer by cross-section dbid
t_etchSubclass
- **modify** — by subclass name
x_position
- **modify** — by cross-section position. This is the number attribute in the cross-section dbid.
'locked
- **update** — user interface layer locking
g_xsectionDefStruct
- **A** — SKILL defstruct with all possible attributes for cross-section entry
make_axlXSection
- **creates** — a new entry
copy_axlXSection
- **copies** — an existing entry
axlXSectionCopy
- **copies** — contents of an existing cross-section dbid to a new defstruct.
l_lockType
- **change** — user interface locking
- **nil** — -  unlock
'layer
- prevent layer addition or deletion
'value
- prevent changing values
- **list** — of both 'layer and 'value

**返回值** (Value Returned)：

t
if successful
nil
failed.

**示例** (Examples)：

See
<cdsroot>/share/pcb/examples/skill/dbcreate/xsection.il
lock layer values
axlXSectionSet('locked 'layer)

**参见** (See Also)：

axlXSectionCreate
,
axlXSectionCopy
