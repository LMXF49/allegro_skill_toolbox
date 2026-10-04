# 14. 设计控制 (Design Control)

**Original**: Design Control Functions

**产品文档**: Allegro SKILL Reference
**产品版本**: 17.4-2019, October 2019

## AXL-SKILL 设计控制函数 (AXL-SKILL Design Control Functions)

**说明**：本章介绍可用于获取当前设计名称和类型的 AXL-SKILL 函数。

**Original**: The chapter describes the AXL-SKILL functions you can use to get the name and type of the current design.

### axlCurrentDesign

**语法**：
```skill
axlCurrentDesign(
)
⇒
t_design
```

**说明**：返回当前活动版图的名称。这是主窗口标题栏中的图名。

**Original**: Returns the name of the currently active layout. This is the drawing name in the main window’s title bar.

**参数**：

**Original**: Arguments

None.

**返回值**：

**Original**: Value Returned

axlCurrentDesign
Returns the current design name as a string. There is always a current name, even if it is “unnamed” (
unnamed.brd
).

**参见**：

**Original**: See Also

axlGetDrawingName
,
axlOpenDesign

**示例**：

**Original**: Examples

axlCurrentDesign()⇒ "mem32meg"
Gets the name of the currently active layout.


### axlDesignType

**语法**：
```skill
axlDesignType(
g_option
)
⇒
t_type/lt_type
```

**说明**：以字符串形式返回设计类型。

**Original**: Returns the type of design as a string.

**参数**：

**Original**: Arguments

g_option
Possible values are:
nil
Return design type domain.
Examples are:
LAYOUT for .brd or .mcm
SYMBOL for .dra
t
fully qualified design type. Examples are:
For layout: "board", "mcm", "mdd" (module)
For symbol:    "package", "mechanical", "format" "shape" or "flash"
'domain — return universe of domains (strings may be repeated). This is all possible values that nil may return.
'members — return list of fundamental design types.
'symbols — return list of symbol types. If a "SYMBOL" this is sub-type of the dra.
The combination of 'members and 'symbols is the universe of the 't' option.

**返回值**：

**Original**: Value Returned

t_type
string describing design type.
lt_type
list of strings in a universe.

**参见**：

**Original**: See Also

axlIsSymbolEditor

**示例**：

**Original**: Examples

Gets the high-level design type of the current active layout.
axlDesignType(nil)
⇒ "LAYOUT"
Gets the detailed design type.
axlDesignType(t)
⇒ "BOARD"


### axlCompileSymbol

**语法**：
```skill
axlCompileSymbol(
?symbol
t_name
?type
t_type
)
⇒
t_symbolName
/nil
```

**说明**：编译并编辑检查当前（符号）设计，并将编译后的版本以指定名称保存到磁盘。
t_name
. If
t_name
is not provided, then
t_name
is the current drawing name. If
t_name
is provided as
nil
, you are prompted for the name. Uses the symbol type in determining some of the edit checks.

**Original**: Compiles and edit checks the current (symbol) design and saves the compiled version on disk under the name
t_name
. If
t_name
is not provided, then
t_name
is the current drawing name. If
t_name
is provided as
nil
, you are prompted for the name. Uses the symbol type in determining some of the edit checks.

**参数**：

**Original**: Arguments

t_name
Name of the compiled symbol.
t_type
Type of symbol, the default is the current symbol type (see
axlDesignType
).

**返回值**：

**Original**: Value Returned

t_symbolName
Name of the symbol.
nil
Error due to incorrect arguments.
This function is only available in the symbol editor. This is a SKILL interface to the Allegro PCB Editor
“create symbol”
command and thus has the same behavior.


### axlSetSymbolType

**语法**：
```skill
axlSetSymbolType(
t_symbolType
)
⇒
t_symbolType
/nil
```

**说明**：设置 Allegro PCB Editor 符号类型。对可用命令以及在符号"编译"时执行的编辑检查有一些轻微影响（
axlCompileSymbol
).
Use
axlDesignType
to determine current symbol type.

**Original**: Sets the Allegro PCB Editor symbol type. Has some minor effect on the commands available and the edit checks performed when the symbol is “compiled” (
axlCompileSymbol
).
Use
axlDesignType
to determine current symbol type.

**参数**：

**Original**: Arguments

t_symbolType
"package"
,
"mechanical"
,
"format"
,
"shape"
or
"flash"

**返回值**：

**Original**: Value Returned

t_symbolType
Symbol exists.
nil
Error due to incorrect argument.
This function is only available in the symbol editor. This is a SKILL interface into the change symbol type in the Drawing Parameters dialog box in
allegro_symbol
.

**参见**：

**Original**: See Also

axlCompileSymbol
,
axlDesignType


### axlDBControl

**语法**：
```skill
axlDBControl(
s_name
[
g_value
]
)
g_currentValue
/
ls_names
```

**说明**：查询和/或设置特殊数据库控制的值。如果设置的是一个值，则返回该控制的旧值。
A side effect of most of these controls is that, if an active dialog box displays the current setting, the setting may not be updated. Additional side effects of individual controls are listed.
Several display options have been moved to axlDBDisplayControl but for backward compatibility are still supported using this interface.
Items currently supported for
s_name
include the following:
名称:
busRats
值:
t
or
nil
设置?:   Yes
Description: 查询和更改总线飞线选项
等效: Prmed Display group
副作用: If changing should do ratsnestDistance first
Symphony Supported: Yes
名称:
drcEnable
值:
t
or
nil
设置?: Yes
Description: 启用或禁用 DRC/CBD 系统。
等效: Same as status dialog box DRC on/off buttons.
副作用: Does not perform batch DRC.
Symphony Supported: Yes
名称: fixedPattern
值:
nil
(disabled),
1
max pattern index (enabled)
设置?: Yes
Description: 设置固定对象的模式索引。
等效: Same as color192 form Display tab fixed pattern field.
副作用: Display updates.
Symphony Supported: Yes
名称:
ratnestDistance
值:
t
or
nil
设置?: Yes
Description: 访问飞线显示模式。
t
- 引脚到引脚
nil
- 最近的悬空网络 cline/via
等效: Same as status dialog box Ratsnest Dist control.
副作用: 更改时重新计算显示。
Symphony Supported: Yes
名称:
activeTextBlock
值:
1
to
maxTextBlock
设置?: Yes
Description: 访问活动文本块编号。
等效: Same as status dialog box text block.
副作用: None
Symphony Supported: Yes
名称:
maxTextBlock
值: 16 to 64
设置?: No
Description: 报告最大文本块编号。
等效: None
副作用: None
Symphony Supported: Yes
名称:
activeLayer
值: <
class
> / <
subclass
>
设置?: Yes
Description: 访问当前类/子类。要获取子类，请执行
cadr(parseString(axlDBControl('activeLayer "/")) )
等效: Same as ministatus display.
副作用: None
Symphony Supported: Yes
名称:
activeAltLayer
值:
<subclass>
设置?:   Yes
Description: 访问当前替代蚀刻层
等效: Same as ministatus display when in add connect.
副作用: None
Symphony Supported: Yes
名称:
defaultSymbolHeight
值: float
设置?: Yes
Description: 设置数据库中的默认符号高度。
等效: Prmed from DRC Symbol Height.
副作用: 将使 DRC 过期，并且如果存在状态对话框，则不更新它。
Symphony Supported: No
名称:
editingTime
值: int
设置?: Reset
Description: 以分钟为单位报告设计的编辑时间。
等效: status from
副作用: 可以通过传递
g_value == t
Symphony Supported: Yes
名称:
symbolRotation
值: float
设置?:   Yes
Description: 设置初始符号旋转角度
等效: Prmed form's symbol angle
副作用: None
Symphony Supported: No
名称:
symbolMirror
值:
t
/
nil
设置?:   Yes
Description: 设置初始符号镜像。
等效: Prmed form's Symbol mirror.
副作用: None
Symphony Supported: No
名称:
schematicBrand
值: none, concepthdl, capture
设置?: Yes
Description: 查询当前数据库原理图品牌。您只能通过 SKILL 将品牌设置为 'none。
等效: See netin in the Allegro PCB Editor dialog.
副作用: None.
Symphony Supported: No
名称:
cmgrEnabledFlow
值:
t
or
nil
设置?: Yes (only if flag is set)
Description: 报告电路板是否处于约束管理器启用流中。仅在 HDL Concept Flow 中有效。
t
- Cadence 原理图约束管理器流已启用（需要 5 个 .pst 文件）
nil
- 传统 Cadence 原理图流（3 个 .pst 文件）
等效: Import Logic Branding shows "Constraint Manager Enabled Flow"
副作用: 不建议清除此标志。此接口是为那些启用了流并希望恢复传统流的客户提供的。您需要在原理图端执行额外的工作来清除该选项。
Symphony Supported: No
名称:
cdszFile
值:
t
or
nil
设置?:
t
or
nil
Description: 报告是否单个
.cdsz
文件被 netrev 使用，而不是多个
.pst
文件。如果
t
, then
genfeed
格式将输出一个
.cdsz
文件。
Symphony Supported: No
名称:
schematicDir
值: directory path
设置?:   Yes
Description: 查询/更改 Cadence 原理图目录路径。这是 Cadence 的目录位置
pst
文件。这不支持第三方网表位置。如果数据库未打品牌（见上文），则目录位置不存储。不验证位置的存在。
等效: Import Logic Branding Cadence Tab
副作用: none
Symphony Supported: No
名称:
testPointFixed
值:
t
or
nil
设置?: Yes
Description: 设置全局标志以锁定测试点。
t
- 测试点已固定
nil
- 测试点未固定
等效: Same as testprep param
"Fixed test points"
副作用: None
Symphony Supported: No
名称:
ecsetApplyRipupEtch
值:
t
or
nil
设置?: Yes
Description: If enabled, and the schedule is anything other than min tree, ripup any etch that disagrees with the schedule. Etch may be ripped up when a refdes is renamed due to this option. Only applicable with  "expert" level tools. Applies setting at system level to all open designs.
t
- 撕除蚀刻
nil
- 保留蚀刻
等效: Same as Constraint Manager
Tools - Options - "Rip up etch..."
副作用: None
Symphony Supported: No
名称:
maxEtchLayers
值: number
设置?: No
Description: 返回蚀刻子类的最大数量。
等效: none
副作用: none
Symphony Supported: Yes
名称:
dynamicFillMode
值:
'wysiwyg, 'rough
,
nil
(Disabled) (must be a symbol not a string)
设置?: Yes
Description: 控制动态形状的填充。
等效: shape global param
副作用: 在符号编辑器中禁用。
Symphony Supported: No
名称:
max名称Length
值: number
设置?:   Yes
Description: 设置最大名称长度。最小值为 31，最大值为 255。对于设计，您不能将其设置为低于当前长度。对于新设计，初始值由环境变量中的值设置
allegro_long_name_size
.
Equiv: Design Parameter Editor, Long 名称 Size
Symphony Supported: No
名称:
dynamicFilletsOn
值: t nil
设置?:   Yes
Description: 控制动态形状的填充
Equiv: Gloss param fillet - dynamic fillets option
副作用: Disabled in symbol editor and lower level PCB tools. When enabled
will update design with fillets.
Symphony Supported: No
名称:
newFlashMode
值: t/nil
设置?:   Yes
Description: 返回电路板是否正在运行旧样式（nil）或新样式（t）闪存模式（使用 fsm 文件的 WYSIWYG 负片 artwork）。注意 WYSIWYG 现在在显示中称为 Smooth。
Equiv: none
副作用: 如果在不更新闪存符号的情况下将模式更改为 t，则可能会出现错误的 artwork。您应该仅在设计创建时、在加载任何带闪存的焊盘堆叠到设计之前更改模式。
Symphony Supported: No
名称:
maxAttachmentSize
值: integer value in bytes
设置?: No
Description: 返回最大附件大小（
axlCreateAttachment
) 可以附加到数据库。
等效: None.
副作用: None.
Symphony Supported: Yes
名称:
dbSize
值: int
设置?: No
Description: 返回当前数据库大小（内存占用）
Equiv:none
副作用: none
Symphony Supported: Yes
名称:
retainElecCnsOnNets
值: t or nil
设置?:   Yes
Description: 查询和更改网络上保留的电气约束
Equiv: netrev based option
副作用: 这仅应在设计上设置。对于已填充的设计，现有电气约束将保持在 xnet 级别。设置该选项不会将现有设置提升到 xnet。
Symphony Supported: No
名称:
mirrorUserMask
值: t or nil
设置?:   t or nil
Description: 大多数具有焊盘堆叠用户掩膜层的设计提供 Allegro 镜像功能（后缀为 _TOP 的层将镜像到后缀为 _BOTTOM 的层，反之亦然）。当焊盘堆叠用户掩膜层在 16.2 中引入时，它们不提供此功能。新设计将提供此功能，但包含在 16.2 或 16.3 中创建的用户掩膜层的设计将禁用此镜像选项。一个 cdsz 文件。
Symphony Supported: No
名称:
xnetState
值: dml, gates, or off
设置?:   No
Description: 查询当前数据库 xnet 状态
Equiv: none
副作用: none
Symphony Supported: Yes
The first argument is a symbol ('drcEnable) and not a string ("drcEnable"). See
axlBackdrillGet
to get backdrill status.

**Original**: Inquires and/or sets the value of a special database control. If the setting is a value, the return is the old value of the control.
A side effect of most of these controls is that, if an active dialog box displays the current setting, the setting may not be updated. Additional side effects of individual controls are listed.
Several display options have been moved to axlDBDisplayControl but for backward compatibility are still supported using this interface.
Items currently supported for
s_name
include the following:
Name:
busRats
Value:
t
or
nil
Set?:   Yes
Description: Queries and changes the bus rats option
Equivalent: Prmed Display group
Side Effects: If changing should do ratsnestDistance first
Symphony Supported: Yes
Name:
drcEnable
Value:
t
or
nil
Set?: Yes
Description: Enables or Disables DRC/CBD system.
Equivalent: Same as status dialog box DRC on/off buttons.
Side Effects: Does not perform batch DRC.
Symphony Supported: Yes
Name: fixedPattern
Value:
nil
(disabled),
1
max pattern index (enabled)
Set?: Yes
Description: Sets the pattern index for fixed objects.
Equivalent: Same as color192 form Display tab fixed pattern field.
Side Effects: Display updates.
Symphony Supported: Yes
Name:
ratnestDistance
Value:
t
or
nil
Set?: Yes
Description: Accesses the ratsnest display mode.
t
- pin to pin
nil
- closest dangling net cline/via
Equivalent: Same as status dialog box Ratsnest Dist control.
Side Effects: Will recalculate the display when this is changed.
Symphony Supported: Yes
Name:
activeTextBlock
Value:
1
to
maxTextBlock
Set?: Yes
Description: Accesses the active text block number.
Equivalent: Same as status dialog box text block.
Side Effects: None
Symphony Supported: Yes
Name:
maxTextBlock
Value: 16 to 64
Set?: No
Description: Reports the maximum text block number.
Equivalent: None
Side Effects: None
Symphony Supported: Yes
Name:
activeLayer
Value: <
class
> / <
subclass
>
Set?: Yes
Description: Accesses the current class/subclass. To obtain subclass do
cadr(parseString(axlDBControl('activeLayer "/")) )
Equivalent: Same as ministatus display.
Side Effects: None
Symphony Supported: Yes
Name:
activeAltLayer
Value:
<subclass>
Set?:   Yes
Description: Accesses the current alternative etch layer
Equivalent: Same as ministatus display when in add connect.
Side Effects: None
Symphony Supported: Yes
Name:
defaultSymbolHeight
Value: float
Set?: Yes
Description: Sets the default symbol height in the database.
Equivalent: Prmed from DRC Symbol Height.
Side Effects: Will set DRC out of date, and does not update status dialog box if it is present.
Symphony Supported: No
Name:
editingTime
Value: int
Set?: Reset
Description: Reports editing time of design in minutes.
Equivalent: status from
Side Effects: Can reset time by passing
g_value == t
Symphony Supported: Yes
Name:
symbolRotation
Value: float
Set?:   Yes
Description: Sets the initial symbol rotation
Equivalent: Prmed form's symbol angle
Side Effects: None
Symphony Supported: No
Name:
symbolMirror
Value:
t
/
nil
Set?:   Yes
Description: Sets the initial symbol mirror.
Equivalent: Prmed form's Symbol mirror.
Side Effects: None
Symphony Supported: No
Name:
schematicBrand
Value: none, concepthdl, capture
Set?: Yes
Description: Queries current database schematic branding. You can set the branding only to 'none via SKILL.
Equivalent: See netin in the Allegro PCB Editor dialog.
Side Effects: None.
Symphony Supported: No
Name:
cmgrEnabledFlow
Value:
t
or
nil
Set?: Yes (only if flag is set)
Description: Reports if board is in constraint manager enabled flow. Only valid in HDL Concept Flow.
t
- Cadence schematic Constraint Manager flow enabled (5 .pst files required)
nil
- traditional Cadence schematic flow (3 .pst files)
Equivalent: Import Logic Branding shows “Constraint Manager Enabled Flow”
Side Effects: It is not advisable to clear this flag. This interface is provided for those customers who enabled the flow and want to restore the traditional flow. You need to do additional work on the schematic side to clear the option.
Symphony Supported: No
Name:
cdszFile
Value:
t
or
nil
Set?:
t
or
nil
Description: Reports if a single
.cdsz
file was used by netrev instead of multiple
.pst
files. If
t
, then
genfeed
format will output a
.cdsz
file.
Symphony Supported: No
Name:
schematicDir
Value: directory path
Set?:   Yes
Description: Queries/changes the Cadence schematic directory path. This is the directory location for the Cadence
pst
files. This does not support 3rd party netlist location. If database is unbranded (see above), then the directory location is not stored. Existence of location is not verified.
Equivalent: Import Logic Branding Cadence Tab
Side Effects: none
Symphony Supported: No
Name:
testPointFixed
Value:
t
or
nil
Set?: Yes
Description: Sets global flag to lock test points.
t
- test points fixed
nil
- test points not fixed
Equivalent: Same as testprep param
"Fixed test points"
Side Effects: None
Symphony Supported: No
Name:
ecsetApplyRipupEtch
Value:
t
or
nil
Set?: Yes
Description: If enabled, and the schedule is anything other than min tree, ripup any etch that disagrees with the schedule. Etch may be ripped up when a refdes is renamed due to this option. Only applicable with  "expert" level tools. Applies setting at system level to all open designs.
t
- ripup etch
nil
- preserve etch
Equivalent: Same as Constraint Manager
Tools — Options — “Rip up etch...”
Side Effects: None
Symphony Supported: No
Name:
maxEtchLayers
Value: number
Set?: No
Description: Returns maximum number of etch subclasses.
Equivalent: none
Side Effects: none
Symphony Supported: Yes
Name:
dynamicFillMode
Value:
'wysiwyg, 'rough
,
nil
(Disabled) (must be a symbol not a string)
Set?: Yes
Description: Controls filling of dynamic shapes.
Equivalent: shape global param
Side Effects: Disabled in symbol editor.
Symphony Supported: No
Name:
maxNameLength
Value: number
Set?:   Yes
Description: Sets maximum name length. Minimum is 31 and maximum is 255. For designs, you cannot set it lower then the current length. For new designs, the initial value is set by the value in the env variable
allegro_long_name_size
.
Equiv: Design Parameter Editor, Long Name Size
Symphony Supported: No
Name:
dynamicFilletsOn
Value: t nil
Set?:   Yes
Description: Controls filling of dynamic shapes
Equiv: Gloss param fillet - dynamic fillets option
Side Effects: Disabled in symbol editor and lower level PCB tools. When enabled
will update design with fillets.
Symphony Supported: No
Name:
newFlashMode
Value: t/nil
Set?:   Yes
Description: Returns if board is running old style (nil) or new style (t) flash mode (WYSIWYG negative artwork using fsm files) Note WYSIWYG is now Smooth in the display.
Equiv: none
Side Effects: If you change the mode to t without updating flash symbols, wrong artwork may occur. You should only change the mode at design creation time before any padstacks with flashes are loaded into the design.
Symphony Supported: No
Name:
maxAttachmentSize
Value: integer value in bytes
Set?: No
Description: Returns the largest attachment size (
axlCreateAttachment
) that may attach to the database.
Equivalent: None.
Side Effects: None.
Symphony Supported: Yes
Name:
dbSize
Value: int
Set?: No
Description: returns current database size (memory footprint)
Equiv:none
Side Effects: none
Symphony Supported: Yes
Name:
retainElecCnsOnNets
Value: t or nil
Set?:   Yes
Description: Queries and changes the retain electrical constraints on nets
Equiv: netrev based option
Side Effects: This should only be set on new designs. With populated designs existing Electrical constraints will remain at xnet level. Setting the option will not promote existing settings to the xnet.
Symphony Supported: No
Name:
mirrorUserMask
Value: t or nil
Set?:   t or nil
Description: Most designs with padstack user mask layers offer Allegro mirror capability (layers with suffix _TOP will mirror to layer suffix _BOTTOM and vice versa). When padstack user mask layers was introduced in 16.2, they did not offer this capability. New designs will offer this capability but designs containing user mask layers that were created in 16.2 or 16.3 will have this mirror option disabled. a cdsz file.
Symphony Supported: No
Name:
xnetState
Value: dml, gates, or off
Set?:   No
Description: Queries current database xnet state
Equiv: none
Side Effects: none
Symphony Supported: Yes
The first argument is a symbol ('drcEnable) and not a string ("drcEnable"). See
axlBackdrillGet
to get backdrill status.

**参数**：

**Original**: Arguments

s_name
Symbol name of control.
nil
returns all possible names.
g_value
Optional symbol value to set. Usually a
t
or a
nil
.

**返回值**：

**Original**: Value Returned

See above.
ls_names
If name is
nil
, then returns a list of all controls.

**示例**：

**Original**: Examples

Sets DRC system off
old = axlDBControl('drcEnable, nil)
Gets current value of pin-2-pin ratsnest
current = axlDBControl('ratsnestDistance)
Gets all names supported by this interface
listOfNames = axlDBControl(nil)
Set dynamic shape mode to smooth
old = axloDBControl('dynamicFillMode, 'wysiwyg)

**参见**：

**Original**: See Also

axlDBDisplayControl


### axlDBGetExtents

**语法**：
```skill
axlDBGetExtents(o_dbid
g_visibleOnly
)
==> bBox/nil
```

**说明**：提供物理数据库对象的范围（extents）。您可以选择获取整个对象的范围（即使当前不可见），或仅获取当前可见对象的范围。
With the visible option the extents may be smaller then the
bBox
attribute of the element
dbid bBox
.
If a list of
dbids
is provided, the union of the extents is returned.
Unsupported dbids are ignored. Dbids that contribute to the extent are SEGMENT, CLINE, LINE, RECTANGLE, FRECTANGLE, FIGURE, TEXT, SHAPE, VOID, VIA, PIN, and SYMBOL_INSTANCE.

**Original**: Provides the extents of a physical database object. You choose between getting the extents of the entire object (even if it is currently not visible) or just the current visible objects.
With the visible option the extents may be smaller then the
bBox
attribute of the element
dbid bBox
.
If a list of
dbids
is provided, the union of the extents is returned.
Unsupported dbids are ignored. Dbids that contribute to the extent are SEGMENT, CLINE, LINE, RECTANGLE, FRECTANGLE, FIGURE, TEXT, SHAPE, VOID, VIA, PIN, and SYMBOL_INSTANCE.

**参数**：

**Original**: Arguments

o_dbid
dbid
of an element.
lo_dbid
list of
dbids
visible_only
t
return the extents of visible parts of the element.
nil
return the extents of the entire element.

**返回值**：

**Original**: Value Returned

bBox
The extents of the element. This might be zero extents, if the object has no extents visible or does not have extents (for example, nets).
nil
Error; bad arguments


### axlDBIgnoreFixed

**语法**：
```skill
axlDBIgnoreFixed(
[g_ignore]
) -> t/nil
```

**说明**：提供与许多 Allegro 批处理程序类似的功能，允许忽略 FIXED 和 LOCKED 属性（例如：
netrev -z
).
If
g_ignore
is
t,
FIXED testing is ignored;
nil
restores FIXED testing. No argument reports the current state of FIXED testing.
This does not disable READ-ONLY states. A parent can be locked, which means the children cannot be modified (symbols locked to prevent editing of its components). READ-ONLY objects are typically seen when you are in the partition editor.
It is important that FIXED property testing be restored. Allegro automatically restores FIXED testing if your SKILL program returns to Allegro. This includes calling
axlShell
.
Recommend using
axlDBCloak
since that API catches any SKILL errors and restores the mode.

**Original**: Provides similar functionality to that offered by many Allegro batch programs which allow FIXED and LOCKED properties to be ignored (for example:
netrev -z
).
If
g_ignore
is
t,
FIXED testing is ignored;
nil
restores FIXED testing. No argument reports the current state of FIXED testing.
This does not disable READ-ONLY states. A parent can be locked, which means the children cannot be modified (symbols locked to prevent editing of its components). READ-ONLY objects are typically seen when you are in the partition editor.
It is important that FIXED property testing be restored. Allegro automatically restores FIXED testing if your SKILL program returns to Allegro. This includes calling
axlShell
.
Recommend using
axlDBCloak
since that API catches any SKILL errors and restores the mode.

**参数**：

**Original**: Arguments

g_ignore
If
t,
turn off FIXED testing;
nil
restore.
no argument    Return current state of FIXED testing.

**返回值**：

**Original**: Value Returned

old fixed (
nil
FIXED is enable,
t
is enabled)

**参见**：

**Original**: See Also

axlDBIsFixed
,
axlDBCloak

**示例**：

**Original**: Examples

; Select an object
p = ashOne()
; Add fixed property
axlDBAddProp(p, '("FIXED" t))
; Attempt to delete it
axlDeleteObject(p)
; now delete it
axlDBIgnoreFixed(t)
axlDeleteObject(p)
axlDBIgnoreFixed(nil)


### axlDBIsReadOnly

**语法**：
```skill
axlDBIsReadOnly(
o_dbid
) -> t/nil
```

**说明**：此 API 命令检查指定的数据库对象是否为只读。
对象因分区处于活动状态而被标记为只读的一个示例。

**Original**: This API command checks if indicated database object is read-only.
An example of why an object is marked read-only due to a partition being active.

**参数**：

**Original**: Arguments

o_dbid
dbid of the element to be checked.

**返回值**：

**Original**: Value Returned

t
– object is read-only
nil
– not read-only or not a dbid

**参见**：

**Original**: See Also

axlDBIsFixed

**示例**：

**Original**: Examples

p = axlSelectByname("SYMBOL" "U1")
ret = axlDBIsReadOnly(p)


### axlDBSectorSize

**说明**：此函数已废弃。

**Original**: This function is obsolete.

此函数已废弃。保留用于向后兼容。它现在调用
axlDBTuneSectorSize
. Tuning sectors is now built into dbdoctor.

### axlGetDrawingName

**语法**：
```skill
axlGetDrawingName(
)
⇒
t_drawingPathName
```

**说明**：检索图形的完整路径。

**Original**: Retrieves the full path of the drawing.

**参数**：

**Original**: Arguments

None

**返回值**：

**Original**: Value Returned

t_drawingPathName
Full path of the drawing.

**参见**：

**Original**: See Also

axlCurrentDesign

**示例**：

**Original**: Examples

axlGetDrawingName() => "/net/nile/home/neeti/testboards/test1.brd"
axlIgnoreFixed
See
axlDBIgnoreFixed
.


### axlInTrigger

**语法**：
```skill
axlInTrigger(
) ==> t/nil
```

**说明**：测试应用程序或实用程序是否处于 axlTrigger 回调中。返回
t
如果当前处于触发器调用中。此函数仅在极少数情况下需要，当您有一个实用程序，如果作为 axlTrigger 回调的一部分被调用，希望以不同方式运行时。

**Original**: Tests if the application or the utility in a axlTrigger callback. Returns
t
if currently in a trigger call. This function is only required in rare cases when you might have a utility that you want to run differently if called as part of a axlTrigger callback.

**参数**：

**Original**: Arguments

None

**返回值**：

**Original**: Value Returned

t
if in a trigger callback,
nil
otherwise

**参见**：

**Original**: See Also

axlTriggerSet
,
axlInTriggerFunc


### axlInTriggerFunc

**语法**：
```skill
axlInTriggerFunc() -> s_triggerFunc/nil
```

**说明**：如果处于触发器回调中，报告触发器函数符号。
nil
, 如果不在触发器回调中。

**Original**: If in a trigger callback, reports trigger function symbol.
nil
, if not in a trigger callback.

**参数**：

**Original**: Arguments

No argument required

**返回值**：

**Original**: Value Returned

s_triggerFunc
Current function name if in a trigger or
nil
if not in a trigger

**参见**：

**Original**: See Also

axlTriggerSet
,
axlInTrigger


### axlIsSymbolEditor

**语法**：
```skill
axlIsSymbolEditor() -> t/nil
```

**说明**：返回
t
如果在符号编辑器中，
nil
对于所有其他编辑器。
加载自定义菜单时，您可能希望区分符号编辑器和设计编辑器。

**Original**: Returns
t
if in symbol editor,
nil
for all other editors.
When loading custom menus you might want to differentiate between the symbol editor and design editor.

**参数**：

**Original**: Arguments

None.

**返回值**：

**Original**: Value Returned

Returns
t
if symbol editor.

**参见**：

**Original**: See Also

axlDesignType

**示例**：

**Original**: Examples

axlIsSymbolEditor()


### axlKillDesign

**语法**：
```skill
axlKillDesign()
⇒ t/nil
```

**说明**：等同于（
axlOpenDesign
<
unnamed
> "wf"
), where <
unnamed
>
是 Allegro PCB Editor 为未命名设计提供的标准名称。如果特定名称很重要，您可以使用
axlCurrentDesign
command.

**Original**: Same as (
axlOpenDesign
<
unnamed
> "wf"
), where <
unnamed
>
is the standard Allegro PCB Editor name provided for an unnamed design. If the specific name is important, you can determine it using the
axlCurrentDesign
command.

**参数**：

**Original**: Arguments

None

**返回值**：

**Original**: Value Returned

t
New design opened, replacing current design.
nil
No new design opened.

**注释**：

**Original**: Notes

This will void all
axl dbid
handles and clear the selection set.

**参见**：

**Original**: See Also

axlOpenDesign


### axlOpenDesign

**语法**：
```skill
axlOpenDesign(
?design
t_design
?mode
t_mode
?noMru
g_noMru
?ignoreLock g_noMru
)
⇒
t_design
/
nil
```

**说明**：打开设计。新设计将替换当前设计。如果当前设计有未保存的编辑，则需要确认是否放弃编辑，除非当前设计是以 "
r
" 模式打开的（此版本不支持）或
t_mode
is "
wf" or "nf"
. 如果取消，函数返回
nil
并且当前设计保持打开状态。
If
t_mode
is "
n
", 打开一个新设计，并指定该设计在磁盘上的名称和位置，而不读取该位置同名的任何现有设计。
警告：该位置任何同名的现有设计在保存时将被覆盖。
If
t_design
未提供，系统将提示您输入要打开的设计名称。
If
t_design
已提供但磁盘上不存在，则会打开标准的 Allegro PCB Editor 绘图参数表单。
新设计的 designType 设置为与当前设计相同。可以使用 axl设置DesignType 进行更改。

**Original**: Opens a design. The new design replaces the current design. If the current design has unsaved edits, confirmation is needed for discarding the edits, unless the current design was opened in "
r
" mode (not supported in this release) or
t_mode
is "
wf" or "nf"
. If cancelled, the function returns
nil
and the current design is left remains open.
If
t_mode
is "
n
", opens a new design and specify the name and location on disk for that design without having it read any existing design of that name at that location.
Warning: Any existing design of that name at that location will be overwritten when the design is saved.
If
t_design
is not provided, you are prompted for the name of the design to open.
If
t_design
is provided but does not exist on disk, the standard Allegro PCB Editor Drawing Parameters form opens.
The designType of the new design is set as the same as the current design. It can be changed using axlSetDesignType.

**参数**：

**Original**: Arguments

t_design
The name of the new design to edit
t_mode
Can be any one of
"w", "wf",
or
“n”
. Add "l" to disable Allegro file locking.
The
“w”
mode opens a design in the write mode,
“wf”
in the forced write mode, and
“wl”
in no lock mode.
g_noMru
If set to
t
, the design is not included in the most recently used file list. (Default is to update.)
ignoreLock
If set to
t
, design lock file is ignored if present.
The is not recommended by Cadence.

**返回值**：

**Original**: Value Returned

t_design
If design opens
nil
If error.
This function is similar to the Allegro PCB Editor
open
command, except that the
t_mode
can be set to "
wf"
in order to discard the current edits without confirmation. However, when
t_mode
is 'n', it behaves the same as the Allegro PCB Editor
new
command.
Since confirmation uses the standard Allegro PCB Editor confirmer, using the
"wf"
mode is essentially the same as setting the
NOCONFIRM
environment variable.
This will void all
axl dbid
handles and clear the selection set.

**参见**：

**Original**: See Also

axlCurrentDesign
,
axlKillDesign
,
axlRenameDesign
,
axlSaveDesign
,
axlSetSymbolType
,
axlRunBatchDBProgram
,
axlSaveEnable
,
axlCompileSymbol


### axlOpenDesignForBatch

**语法**：
```skill
axlOpenDesignForBatch(
t_design
t_mode
)==> t_design/nil
```

**说明**：打开设计。新设计将替换当前设计。由于这是用于批处理，命令和菜单不会更改。如果当前设计有未保存的编辑，则系统会要求您确认是否放弃，除非当前设计是以
"r"
模式打开的（此版本不支持）或
g_mode
is
"wf"
. 如果您取消确认器，则函数返回
nil
并且当前设计保持打开。
If
t_design
is not provided, then you are prompted for the name of the design to open.
If
t_design
在磁盘上不存在，则会出现标准的 Allegro 绘图参数表单。
The
designType
of the new design is set the same as the current design. It can be changed using
axl设置DesignType
.

**Original**: Opens a design. The new design replaces the current design. Since this is for batch usage, commands and menus are not changed. If the current design has unsaved edits, then you are asked to confirm the discard unless the current design was opened in
"r"
mode (not supported in this release) or
g_mode
is
"wf"
. If you cancel the confirmer, then the function returns
nil
and the current design is left open.
If
t_design
is not provided, then you are prompted for the name of the design to open.
If
t_design
does not exist on the disk, then the standard Allegro Drawing Parameters form appears.
The
designType
of the new design is set the same as the current design. It can be changed using
axlSetDesignType
.

**参数**：

**Original**: Arguments

t_design
The name of the new design to edit
g_mode
"w"
or
"wf"
(see above)
add a "l" to disable Allegro file locking
example: "wl" for no locking

**返回值**：

**Original**: Value Returned

t_design
if opened, or
nil
if error
This command functions the same as the Allegro
edit
command, except that the
t_mode
can be set to
"wf"
in order to discard the current edits without confirmation. Since confirmation uses the standard Allegro confirmer, the
"wf"
mode is the same as setting the
NOCONFIRM
environment variable.
This removes all axl dbid handles and clears the selection set.

**示例**：

**Original**: Examples

Open
u.dra
in current directory with noconfirm option
axlOpenDesignForBatch("u.dra"  "wf")


### axlRenameDesign

**语法**：
```skill
axlRenameDesign(
t_design
)
⇒
t_design
/nil
```

**说明**：更改当前设计名称。不影响当前设计的现有磁盘版本。新的当前设计名称将显示在窗口边框中，并成为
axlSaveDesign
.

**Original**: Changes the current design name. Has no effect on the existing disk version of the current design. The new current design name will be displayed in the window border and becomes the default name for
axlSaveDesign
.

**参数**：

**Original**: Arguments

t_design
New current design name (without file extension).

**返回值**：

**Original**: Value Returned

t_design
New current design name.
nil
Error due to incorrect argument.

**参见**：

**Original**: See Also

axlOpenDesign

**示例**：

**Original**: Examples

axlRenameDesign("foobar")


### axlSaveDesign

**语法**：
```skill
axlSaveDesign(
?design
t_design
?mode
t_option
?noMru
g_noMru
?noConfirm g_noConfirm
?writeModel g_write
)
⇒
t_design
/nil
```

**说明**：以指定名称保存设计（
t_design
)。如果
t_design
未指定，则使用当前设计名称。如果
t_design
已提供但值为
nil
，系统将提示您输入名称。如果
t_option
is
"nocheck"
, the database "quick check" is not provided. Use this option only when there is a very compelling reason.
NOTES
这本质上就是 Allegro 的"保存"命令。
This will clear all axl dbid handles and the selection set.
如果目的是保存设计以运行另一个程序，请使用 axlRunBatchDBProgram。

**Original**: Saves the design with the name specified (
t_design
). If
t_design
is not specified, the current design name is used. If
t_design
is provided but the value is
nil
, you are prompted for the name. If
t_option
is
"nocheck"
, the database “quick check” is not provided. Use this option only when there is a very compelling reason.
NOTES
This is essentially the Allegro "save" command.
This will clear all axl dbid handles and the selection set.
Use axlRunBatchDBProgram, if the intent is to save the design to run another program.

**参数**：

**Original**: Arguments

t_design
Name for the saved design.
t_option
"nocheck
" - No database check performed.
g_noMru
If
t
does not update the Most Recently Used file list. (Default is to update.)
g_noConfirm
If
t
does not present a confirmer if overwriting an existing design. File is overwritten.
g_write
If
t
uses allegro write file model. This means file is written to disk with provided name but current drawing name is not updated.

**返回值**：

**Original**: Value Returned

t_design
Name for the saved design.
nil
Error due to incorrect argument(s).
Essentially the Allegro PCB Editor
save
command. The current design name is not changed. Use
axlRenameDesign
to change the current design name.
This will void all
axl dbid
handles and clear the selection set.

**参见**：

**Original**: See Also

axlOpenDesign
,
axlRenameDesign
,
axlRunBatchDBProgram


### axlSaveEnable

**语法**：
```skill
axlSaveEnable(
[g_saveEnable]
) -> t/nil
```

**说明**：此函数查询或设置设计的保存状态。当
t,
the
File - Save design
菜单命令启用。如果
nil,
则禁用。
如果未提供参数，则返回当前状态。如果
g_saveEnable
is
t,
则启用保存菜单（下次数据库保存时重置）。如果
g_saveEnable
is
nil,
则禁用保存菜单。
不建议取消设置保存启用。

**Original**: This queries or sets the design to save design. When
t,
the
File – Save design
menu command is enabled. If
nil,
it is disabled.
If no arguments are provided, then returns the current status. If
g_saveEnable
is
t,
then enables save menu (reset of next database save). If
g_saveEnable
is
nil,
disables the save menu.
It is not recommended that you unset the save enable.

**参数**：

**Original**: Arguments

g_saveEnable
t
If not provided, just does query.

**返回值**：

**Original**: Value Returned

Returns current save setting if query and previous setting if changing the value.

**参见**：

**Original**: See Also

axlSaveDesign

**示例**：

**Original**: Examples

1) Query state of save
state = axlSaveEnable()
2) Set state of save to
t
(enable save menu)
oldState = axlSaveEnable(t)


### axlDBChangeDesignExtents

**语法**：
```skill
axlDBChangeDesignExtents(
l_bBox
)
⇒ t/nil
```

**说明**：更改设计范围（extents）。如果对象超出新范围，或范围超出数据库限制，则可能会失败。

**Original**: Changes design extents. This may fail if an object falls outside the new extents or if the extents exceed the database range.

**参数**：

**Original**: Arguments

l_bBox
New design extents.

**返回值**：

**Original**: Value Returned

t
Size changed.
nil
Failed to change size.
This function may take extra time on large designs.
Example 1
extents =
axlExtentDB
('obstacle)
axlDBChangeDesignExtents(extents)
Reduces the database to its smaller extent.
Example 2
extents = axlExtentDB('obstacle)
extents = bBoxAdd(extents '((-100 -100) (100 100))
axlDBChangeDesignExtents(extents)
To reduces the database to its minimum size plus 100 mils all around.


### axlDBChangeDesignOrigin

**语法**：
```skill
axlDBChangeDesignOrigin(
l_point
)
⇒ t/nil
```

**说明**：更改设计的原点。如果新设计原点超出最大整数范围，则可能会失败。
这是一个偏移量。负数将数据库向左或向下移动，正数将数据库向右或向上移动。
这在大型设计上可能需要额外时间。

**Original**: Changes the origin of the design. This may fail if the new design origin falls outside the maximum integer range.
This is an offset. A negative number moves the database left or down and a positive number moves the database to the right or up.
This may take extra time on large designs.

**参数**：

**Original**: Arguments

l_point
/
Y
offset.

**返回值**：

**Original**: Value Returned

t
Changed the origin of the design.
nil
Failed to change the origin of the design due to an incorrect argument.

**示例**：

**Original**: Examples

axlDBChangeDesignOrigin(900:900)
Moves the origin.


### axlDBChangeDesignUnits

**语法**：
```skill
axlDBChangeDesignUnits(
t_units
/nil
x_accuracy
/nil
[x_dbuperuu
/nil]
x_drcCount
/nil
)
⇒
x_drcCount
/nil
```

**说明**：Changes the units,  accuracy,or dbuperuu of the design. Either accuracy or dbuperuu can be set. Both cannot be set at the same time.To maintain the current design value, use
nil
for
t_units
or
x_accuracy
.
更改单位时，还应更改精度以在数据库中保持足够的精度。参考下表以确定适当的精度。
单位
最小精度
最大精度
增量
密耳
0
4
0 (more then 2 not advised due Gerber)
英寸
2
4
3
微米
0
4
0
毫米
1
4
3
厘米
2
4
4
不建议降低精度。
由于不可避免的舍入问题，不建议在公制和英制之间切换单位。
使用新的
DELTA
来决定更改单位时应使用什么精度。
new acc = orig acc + (new delta - old delta)
此示例显示将密耳转换为毫米，当前精度为 1。
new acc  = orig acc + (millim delta - 密耳 delta)
4  = 1   +  3  - 0
在从一种英制单位转换为另一种英制单位，或从一种公制单位转换为另一种公制单位时，默认精度必须与先前单位相匹配。例如，如果您的设计使用
MILS
0 并且您更改为
INCHES
, 精度必须设置为 3。
如果您从英制单位更改为公制单位，或从公制单位更改为英制单位，则精度必须设置为至少与当前数据库一样精确的数字。例如，如果设计使用
MILS
0 并且您更改为
MILLIMETERS
, 则精度必须设置为 2。然后如果更改为
INCHES
, 精度必须设置为 3（英寸和 3 = 密耳和 0。）
如果由于特定单位允许的小数位数限制而不允许所需的精度，或者如果您降低精度级别，则错误消息
"
E-Accuracy will be decreased, database round-offs may occur
," 将显示。例如，如果您的设计在
MICRONS
且精度为 1，并且您更改为
CENTIMETERS
, 您将收到错误，因为
CENTIMETERS
不允许精度为 5。
DBUperUU Notes
仅使用 DBUperUU 来匹配另一个支持 DBUperUU 的设计工具（例如 Virtuoso、来自 OA 的设计等）。
更改单位时，应更改精度或 DBUperUU 以在数据库中保持足够的精度。
选择的 DBUperUU 值将决定内部精度。

**Original**: Changes the units,  accuracy,or dbuperuu of the design. Either accuracy or dbuperuu can be set. Both cannot be set at the same time.To maintain the current design value, use
nil
for
t_units
or
x_accuracy
.
When you change units, also change accuracy to maintain adequate precision within the database. Reference the following table to determine the appropriate accuracy.
Units
Min Accuracy
Max Accuracy
Delta
mils
0
4
0 (more then 2 not advised due Gerber)
inches
2
4
3
microns
0
4
0
millimeters
1
4
3
centimeters
2
4
4
Decreasing accuracy is not recommended.
Switching units between Metric and English is not recommended due to inevitable rounding issues.
Use the new
DELTA
to decide what the accuracy should be when changing units.
new acc = orig acc + (new delta - old delta)
This example shows mils to millimeters with a current accuracy of 1.
new acc  = orig acc + (millim delta - mils delta)
4  = 1   +  3  - 0
When changing from one English unit to another or from one Metric unit to another, the default accuracy must match that of the previous unit. For example, if your design uses
MILS
0 and you change to
INCHES
, the accuracy must be set to 3.
If you change from an English unit to a Metric unit or from a Metric unit to an English unit, then the accuracy must be set to a number that is at least as accurate as the current database. For example, if the design is in
MILS
0 and you change to
MILLIMETERS
, then the accuracy must be set to 2. Then if you change to
INCHES
, the accuracy must be set to 3 (inches and 3 = mils and 0.)
If the accuracy needed is not allowed due to a limitation on the number of decimal places allowed for a particular unit, or if you reduce the level of accuracy, the error message,
“
E-Accuracy will be decreased, database round-offs may occur
,” displays. For example, if your design is in
MICRONS
and an accuracy of 1 and you change to
CENTIMETERS
, you get an error since
CENTIMETERS
are not allowed with an accuracy of 5.
DBUperUU Notes
Only use DBUperUU to match another design tool, which supports DBUperUU (such as Virtuoso, designs coming from OA, and so on).
When changing units, you should change either accuracy or DBUperUU to maintain adequate precision within the database.
The value of DBUperUU chosen will dictate the internal accuracy.

**示例**：

**Original**: Examples

DBUperUU
Accuracy
200
3
2000
4
4000
5
Legal values for dbuperuu are:
160, 200, 400, 800, 1600, 2000, 4000, 8000

**参数**：

**Original**: Arguments

t_units
Mils, inches, millimeters, centimeters, or microns.
x_accuracy
Range is 0 to 4, according to the table shown.
x_dbuperuu
160, 200, 400, 800, 1600, 2000, 4000, 8000

**返回值**：

**Original**: Value Returned

x_drcCount
DRC count
nil
Failed to change design units
nil nil nil
String of legal dbuperuu values
Notes:
This function may take extra time on large designs.
This function reruns DRC if enabled.
Example 1
axlDBChangeDesignUnits("millimeters" 4)
Changes a design from mils/0 to millimeter/4 (accuracy maintains database precision).
Example 2
axlDBChangeDesignUnits(nil 2)
Increases accuracy from 0 to 2 and keeps the same units.
Example 3
axlDBChangeDesignUnits(nil nil 4000)
Set dbuperuu 4000 to match Virtuoso and keep the same units.


### axlDBCheck

**语法**：
```skill
axlDBCheck(
g_option
/
lg_options
[
p_file
]
)
⇒ (
x_errors
x_warnings
)/nil
```

**说明**：运行
dbdoctor
在当前数据库上。默认情况下，不生成日志文件。您可以指定
'log
选项，该选项写入标准
dbdoctor.log
文件。端口描述符可以作为第二个参数，用于写入
dbdoctor
输出到外部文件。

**Original**: Runs
dbdoctor
on the current database. By default, no log file is produced. You can specify the
'log
option which writes the standard
dbdoctor.log
file. A port descriptor can be the second argument to write the
dbdoctor
output to an external file.

**参数**：

**Original**: Arguments

g_option
/
lg_options
Option
Function
'general
Performs a full database check.
'links
Performs a full database check.
'branch
Performs a full database check.
'shapes
Checks shapes (autovoid)
May be slow for complicated shapes.
Normally fast.
Slow on large databases.
'all
Performs a full check and fix. Does not perform a shape check.
'drc
Performs a batch DRC.
'log
Uses the standard
dbdoctor.log
file for output.
p_file
Port to write dbcheck logging.

**返回值**：

**Original**: Value Returned

(x_errors x_warnings)
Results of the check.

**示例**：

**Original**: Examples

res = axlDBCheck (‘all)
printf ("errors = %d; warnings = %d", car (res), cadr (res);
p = outfile ("mylogfile")
res = axlDBCheck('(links shapes) p)
close(p)


### axlDBCopyPadstack

**语法**：
```skill
axlDBCopyPadstack(
o_dbid/t_padstackName
lt_startEnd
[
g_dontTrim
]
)
⇒
o_dbid/nil
```

**说明**：通过复制现有焊盘堆叠来创建新焊盘堆叠，并可选择移除层。新焊盘堆叠的名称通过向现有名称添加唯一后缀自动生成。该焊盘堆叠在设计中标记为源自其起始焊盘堆叠。
必须提供起点/终点，并且必须是合法的 ETCH 层。
如果焊盘堆叠未被使用，则下次运行 dbdoctor 时会被删除。

**Original**: Creates a new padstack by copying an existing padstack, with optional removal of layers. The name for the new padstack automatically derives from the existing name by adding a unique post fix. The padstack is marked in the design as derived from its starting padstack.
Start/end must be provided and must be legal ETCH layers.
If the padstack is not used, it is deleted by the next dbdoctor run.

**参数**：

**Original**: Arguments

o_dbid
dbid
of the padstack to copy from.
t_padstackName
Name of the padstack to copy from.
lt_startEnd
List of start (
class
/
subclass
) and stop (
class
/
subclass
) layers.If class is used, it must be ETCH (PCB) or CONDUCTOR (APD+)
g_dontTrim
Obsolete, ignored.

**返回值**：

**Original**: Value Returned

dbid
dbid
of the new padstack.
nil
Failed to create new padstack.

**示例**：

**Original**: Examples

1) To derive an exact copy:
newPadId = axlDBCopyPadstack(padId, '("ETCH/TOP" "ETCH/BOTTOM"))
2) To derive and trim to only connect from top layer to 2
newPadId = axlDBCopyPadstack(padId, '("TOP" "2") nil)
or
newPadId = axlDBCopyPadstack("VIA", '("TOP" "GND") nil)


### axlDBDelLock

**语法**：
```skill
axlDBDellLock(
[
t_password
]
)
⇒ t/nil
```

**说明**：删除数据库上的锁定。如果数据库使用密码锁定，则必须提供正确的密码才能解锁。
视图锁定无法解锁。

**Original**: Deletes a lock on the database. If the database is locked with a password, you must supply the correct password to unlock it.
View locks cannot be unlocked.

**参数**：

**Original**: Arguments

t_password
Optional password string.
String length should be 6 to 20 characters.
Period (.), space, forward slash (\) and some character patterns are not legal.

**返回值**：

**Original**: Value Returned

t
Lock is removed or there is no lock to remove.
nil
Failed to remove lock due to an incorrect password.

**参见**：

**Original**: See Also

axlDBSetLock
,
axlDBGetLock

**示例**：

**Original**: Examples

Delete lock with no password.
axlDBDelLock()
Delete lock with the password, "foobar".
axlDBDelLock("foobar")


### axlDBGetLock

**语法**：
```skill
axlDBGetLock()
⇒ nil/
l_info
```

**说明**：返回有关数据库锁定的信息。您可以检索以下信息：
t_user名称
锁定数据库的用户登录名（自动生成）
t_lockDate
数据库被锁定的日期（自动生成）
t_system名称
数据库被锁定的系统（自动生成）
t_locklevel
锁定级别：视图、导出或写入
t_expiration
从锁定日期起与锁定关联的过期持续时间
t_comments
锁定数据库的用户设置的注释
g_useNtp
t
如果使用 NTP 作为计时器，
nil
使用系统时间
t_ntpServer
NTP 服务器名称或空值
您还可以确定数据库是否被锁定，因为此函数返回
nil
当数据库未锁定时，以及当数据库被锁定时返回信息列表。

**Original**: Returns information about a lock on the database. You retrieve the following information:
t_userName
User login who locked the database (auto-generated)
t_lockDate
Date the database was locked (auto-generated)
t_systemName
System on which the database was locked (auto-generated)
t_locklevel
Level of the lock: view, export or write
t_expiration
Expiration duration associated with the lock from the lock date
t_comments
Comments set by user who locked database
g_useNtp
t
if using a NTP for timer,
nil
uses system time
t_ntpServer
NTP server name or null
You can also determine whether or not a database is locked as this function returns
nil
when the database is unlocked, and returns a list of information when the database is locked.

**参数**：

**Original**: Arguments

none

**返回值**：

**Original**: Value Returned

nil
Database is unlocked.
l_info
List (
t_userName
t_lockDate
t_systemName
t_locklevel
t_expiration
t_comments
g_useNtp
t_ntpServer
)
Database is locked.

**参见**：

**Original**: See Also

axlDBSetLock
,
axlDBDelLock


### axlDBMemoryReclaim

**语法**：
```skill
axlDBMemoryReclaim( )
-> x_sizeReclaimed
```

**说明**：回收数据库内存以供 Allegro 数据库重用。通常，已删除数据库对象的 SKILL 内存不会被重用，直到 SKILL 代码返回到主处理循环。
仅应在特殊情况下使用，因为默认编程模型适用于几乎所有 SKILL 程序。对于编写良好的 SKILL 程序，通常不需要此功能。
在使用此 API 之前，请先尝试以下技术：
如果添加/删除基于蚀刻的对象（过孔、cline、蚀刻形状、ping（例如，像移动符号）），请使用 axlDBCloak。
确保您没有任何长时间运行的数据库事务（axlDBTransactionStart）。例如，提交所有活动事务。事务可以嵌套，因此您应该一直提交到初始事务。
使用此 API 的一个已知编程模型是"尝试"模型。这是程序将对象添加到数据库，执行测试然后删除它的地方（例如，利用 axlAirGap 获取与其他数据库对象的距离）。
为使 API 最有效，请确保：
不在 axlDBCloak 内部。
如果没有活动的数据库事务，则可以回收最多的内存。
回收的内存返回到数据库以供重用。它不会返回到程序的内存池，也不会返回到操作系统。程序在操作系统级别的内存使用量不会减少。
作为副作用，某些已签出的 dbid 可能会被回收，因为它们实际上链接到已删除的数据库对象。它们报告为"dbid:remove"。
不要替代 axl 触发器回调使用。

**Original**: Reclaims database memory for reuse by the Allegro database. Normally in SKILL memory of deleted database objects is not reused until SKILL code returns to the main processing loop.
Should only be used in special cases since the default programming model works for most all SKILL programs. For a well written SKILL program this is typically not required.
Before utilizing this API, first try the following techniques:
use axlDBCloak if are adding/deleting objects that are etch based (vias, clines, etch shapes, pings (for example, like moving a symbol).
insure that you do not have any long running db transactions (axlDBTransactionStart). For example, commit all transactions you have active.Transactions can be nested so you should commit all the way to the initial transaction.
The one known programming model that uses this API is the "try-it" model. This is where a program adds an object to the database, performs a test and then deletes it (for example, utilizes axlAirGap to get distances to other db objects).
For the API to be most effective make sure:
Are not inside an axlDBCloak.
The most memory can be reclaimed if you have no active db transactions.
Memory reclaimed is returned to the database for reuse. It is not be returned to the program's memory pool nor returned to the OS. The program’s memory usage at the OS level is NOT reduced.
As a side effect some of the dbids that are checked-out may be reclaimed since they actually link to deleted db objects. They are reported as "dbid:remove".
Do NOT use instead axl trigger callbacks.

**参数**：

**Original**: Arguments

none

**返回值**：

**Original**: Value Returned

Amount of memory reclaimed (bytes).

**参见**：

**Original**: See Also

axlDBCloak
,
axlDBTransactionStart


### axlDBSetLock

**语法**：
```skill
axlDBSetLock(
['password
t_password
]
['locklevel             t_locklevel]
['expiration            t_expiration/x_expiration]
['comments
t_comments
]
['useNtp                t/nil]
['ntpServer             t_server]
)
⇒ t/nil
```

**说明**：提供一种机制来锁定数据库以防止将来的更改。如果您锁定数据库，它会在内存中被锁定，要保存锁定，您需要将数据库保存到磁盘。因此，在锁定数据库后，您可以在所有进一步尝试保存数据库被拒绝之前保存一次数据库。
当用户打开锁定的数据库时，会抛出警告，指示数据库已被锁定。尝试保存数据库将失败，并出现上述异常和 uprev（参见以下文本）。

**Original**: Provides a mechanism to lock the database against future changes. If you lock the database it is locked in memory, to save the lock, you need to save the database to disk. Therefore, after locking the database, you can save the database once before all further attempts to save the database are rejected.
When a user opens a locked database, a warning, indicating that the database is locked, is thrown. An attempt to save the database fails with the above exception of above and uprev (see following text).

**参数**：

**Original**: Arguments

password
If provided, this must be provided to unlock the database. If you forget the password you will not be able to unlock the database.
Password must be greater then 5 or less then 20.
Following characters are not allowed in the password.
\ whitespace
locklevel
Three levels of locking are provided with the lock — view, export, and write. If user does not provide any locklevel, or provides the wrong argument, or provides it without any password, default level of write would be used.
expiration
With the lock, user can set the expiration duration for the design. The arguments passed must in number of days with a minimum of 1. If wrong expiration is provided, then default (no duration limit) is used.
comments
Free form comments. You may embed carriage returns ("\r") in the string to force a new-line in the locking user interface.
useNtp
Use NTP server to verify time when a expiration value is provided
ntpServer
NTP Server to use for verify an expiration lock. If not provided uses NTPSERVER environment variable which defaults to
0.pool.ntp.org
.
If using NPT based expiration locks then you must ensure that the user opening the design can access the NTP server specified. Frequently, firewalls block the NTP serve/port. The port is 123 UDP.
Upreving the database from to a new version ignores the lock flag. For a simple lock provide no arguments. If a nil is provided, it returns list of options to this function.

**返回值**：

**Original**: Value Returned

t
Locked database.
nil
Failed to lock database due to argument errors or database already locked

**示例**：

**Original**: Examples

Most basic lock (no password, no locklevel, no expiration, no comments)
axlDBSetLock()
Lock with comments and disable data export
axlDBSetLock('password "passwd" 'locklevel "view" 'expiration 6 'comments "Test")
axlSaveDesign(?design "locked_data")
printf("Locked info %L\n" axlDBGetLock())

**参见**：

**Original**: See Also

axlDBGetLock
,
axlDBDelLock
,
axlSaveDesign


### axlDBTuneSectorSize

**语法**：
```skill
axlDBTuneSectorSize( )
==> nil/l_result
```

**说明**：调整 Allegro 的扇区大小以获得更好的性能。通常，这通过 dbdoctor 或性能顾问自动进行。此外，它在设计打开期间定期执行。
Allegro 的最佳扇区大小在设计周期中会发生变化。随着设计完成，较小的扇区大小通常会带来更好的性能，但需要稍高的内存需求。
对于当前版本，扇区大小以 dbunits 为单位，未来版本可能会将其更改为设计单位。

**Original**: This tune’s Allegro’s sector size for better performance. Normally, this occurs automatically via dbdoctor or performance advisor. In addition, it is done periodically during design open.
Allegro’s optimal sector size changes over the course of a design cycle. As the design becomes complete a smaller sector size typically results in better performance at a cost of a slightly higher memory requirement.
For the current release, the sector size is in dbunits, future releases may change this to design units.

**参数**：

**Original**: Arguments

None

**返回值**：

**Original**: Value Returned

nil
: If no tuning is required
a disembody property list: If tuning was required. The a disembody property list contains:
old sectors


### axlTechnologyType

**语法**：
```skill
axlTechnologyType()
⇒
t_technology
```

**说明**：返回正在使用的设计技术类型。

**Original**: Returns the type of design technology in use.

**参数**：

**Original**: Arguments

none

**返回值**：

**Original**: Value Returned

t_technology
Technology type as shown:
Technology Type
Product
"mcm"
Allegro Package Designer L or Allegro Package SI XL
"pcb"
Allegro PCB Editor


### axlTriggerClear

**语法**：
```skill
axlTriggerClear(
s_trigger
s_function
)
⇒ t/nil
```

**说明**：移除已注册的回调触发器。您传递的参数与注册触发器时传递的参数相同。

**Original**: Removes a registered callback trigger. You pass the same arguments you passed as you registered the trigger.

**参数**：

**Original**: Arguments

s_trigger
Trigger type. See
axlTriggerSet.
s_function
Trigger function to remove - the same as you passed to
axlTriggerSet
.

**返回值**：

**Original**: Value Returned

t
Trigger removed.
nil
Failed to find a trigger by the specified name.

**示例**：

**Original**: Examples

See
axlTriggerSet
for an example.


### axlTriggerPrint

**语法**：
```skill
axlTriggerPrint()
⇒ t
```

**说明**：调试函数，打印为触发器注册的内容。

**Original**: Debug function that prints what is registered for triggers.

**参数**：

**Original**: Arguments

none

**返回值**：

**Original**: Value Returned

t
Always returns
t
.


### axlTriggerSet

**语法**：
```skill
axlTriggerSet(
s_trigger
s_function
)
⇒ t/nil
axlTriggerSet(
nil
nil
)
⇒ (
ls_listOfSupportTriggers
)
```

**说明**：允许应用程序注册对 Allegro PCB Editor 中发生的事件的兴趣。支持的事件由
s_trigger
选项显示。当两个参数都调用为
nil
, 时，返回支持的触发器列表。

**Original**: Allows an application to register interest in events that occur in Allegro PCB Editor. Supported events are shown by the
s_trigger
option. When called with both arguments as
nil
, returns a list of supported triggers.

**限制**：

**Original**: Restrictions

Unless otherwise indicated, in you SKILL callback trigger you cannot:
open, save or close the current database.
call axlShell.
call any of the axlEnter functions or any of the Select object functions to request a user pick.
You should restrict any user interaction to blocking dialogs (forms).

**注释**：

**Original**: Notes

All trigger functions take a single argument. If you provide a function that does not match this standard, your trigger is
not
called.
Any processing you do in triggers increases the time to open or save a database. So it is recommended that you must keep these short. If it must be longer, inform the user regarding the processing delay using
axlUIWPrint
.
You can register multiple functions for a single trigger, but each registration must have a different function. The order that these functions are called when the trigger occurs is undefined.
Allegro PCB Editor sends a close trigger when Allegro PCB Editor exits normally. Abnormal exits such as crash, user kill, etc. result in this trigger not being generated.
You can do user interface work in triggers. You must have the user enter all information before returning from the trigger. Opening a dialog box may involve returning before getting data from the user. To avoid this problem, call
axlUIWBlock
after
axlFormDisplay
. This ensures you do all processing inside the trigger. For correct dialog box display, use the block option in
axlFormCreate
, the
lt_placement
parameter.
You should use caution when using axlShell API within a trigger function. Cadence advises against this and does not support it. For example, calling Allegro commands or running scripts is not supported. Using axlShell API within a trigger function can cause the following:
Allegro layout editor may block in the script resulting in trigger failures.
The triggers for opening and saving the database are generally not called when the database needs to do temporary saves, for example,
axlRunBatchDBProgram
, reports, or
netrev
.
You can disable triggering by setting the environment variable
dbg_noskilltriggers
. If you suspect that applications running on triggers are causing problems, set this environment variable to help you debug.

**参数**：

**Original**: Arguments

s_trigger
Trigger type as follows:
s_trigger Option

**说明**：'open (
t_database
g_existing
)
在数据库打开后立即调用。传递一个包含两个项目的列表：数据库的名称和
t
如果存在，或
nil
如果是新数据库。
限制：您不应打开、保存和关闭当前数据库。
'save (
t_old名称
t_new名称
)
在数据库保存到磁盘之前调用。传递一个包含两个项目的列表：数据库的旧名称和新名称。如果相同，则数据库被覆盖。自动保存时不会调用此触发器。
'close
t_name
在打开另一个数据库之前调用。单个项目是正在丢弃的数据库的名称。
'exit   x_status
在程序退出时调用，除非是异常终止。
x_status
是一个数字，其中
0
表示干净退出，
1
表示警告，以及
2
由于错误而退出。
GUI 程序目前不会以警告退出，但这将来可能会改变。
提供触发器供应用程序清理环境。对于数据库特定的工作，请使用保存或关闭触发器。
Restrictions:
不要读取或更改数据库。
不要显示对话框或阻塞确认器。
'menu   t_menu名称
在主工具窗口中加载新菜单时调用。
针对应用程序代码以修改菜单。
Restrictions:
当数据库处于活动状态时，不要更改数据库。
不要显示对话框或阻塞确认器。
不要调用 axlUIMenuLoad。
'xprobe   (s_mode lo_dbid)
在对象高亮或取消高亮时调用
s_mode
是一个符号，可以是高亮或取消高亮，以及
lo_dbid
是 dbid 列表。这是用于交叉探测到 ConceptHDL/Capture 的相同接口。
这是针对允许向外部工具发送消息的。
Restrictions:
不要更改数据库
不要调用对话框或阻塞确认器
将处理保持在最低限度，因为这会影响用户交互性能。
'window   l_windowBox
在画布显示窗口更改显示区域时调用。这可能是由缩放、任意方向的平移或画布窗口的调整大小引起的。
l_windowBox
是一个 bBox，给出数据库的当前显示区域。
这在漫游（鼠标平移）操作期间不会触发。当用户移动鼠标时，屏幕会不断重新定位，这将用事件淹没您的触发器。
Restrictions:
不要在此触发器中更改窗口显示区域。
这可能导致无限循环。
s_function
事件的回调函数。每个触发器应有自己的函数。如果您对多个触发器使用相同的函数，则无法确定哪个函数导致了触发器。

**Original**: 'open (
t_database
g_existing
)
Called immediately after a database is opened. Passed a list of two items: the name of the database and
t
if existing or
nil
if a new database.
Restrictions: You should not open, save, and close the current database.
'save (
t_oldName
t_newName
)
Called before a database is saved to disk. Passed a list of two items: the old name of the database and the new name of the database. If these are the same, then the database was overwritten. This is not called when autosaving.
'close
t_name
Called before another database is opened. The single item is the name of the database being discarded.
'exit   x_status
Called when program is exiting except if it is an abnormal termination.
x_status
is a number where
0
indicates a clean exit,
1
indicates warnings, and
2
is exiting due to an error.
GUI programs do not currently exit with warnings but this may change in the future.
Trigger is provided for applications to clean-up the environment. For database specific work, use save or close trigger.
Restrictions:
Do not read or change the database.
Do not display dialogs or blocking confirmers.
'menu   t_menuName
Called when a new menu is loaded in the main tool window.
Targeted at application code to modify the menu.
Restrictions:
While a database is active do not change the database.
Do not display dialogs or blocking confirmers.
Do not call axlUIMenuLoad.
'xprobe   (s_mode lo_dbid)
Called when object(s) is highlighted or dehighlight
s_mode
is a symbol which may be highlight or dehighlight and
lo_dbid
is a list of dbids. This is the same interface used to cross-probe to ConceptHDL/Capture.
This is targeted to allow sending messages to external tools.
Restrictions:
Do not change the database
Do not invoke a dialog or blocking confirmer
Keep processing at a minimum since this will impact user interactive performance.
'window   l_windowBox
Called when the canvas display window changes the display area. This may be caused by a zoom, a pan in any direction, or a resize of the canvas window.
l_windowBox
is a bBox giving the current display area of the database.
This is not triggered during a roam (mouse panning) action. This would flood your trigger with events as the screen is being constantly repositioned as your user moves the mouse.
Restrictions:
Do not change the window display region in this trigger.
This can cause infinite loops .
s_function
Callback function for the event. Each trigger should have its own function. If you use the same function for multiple triggers you can not determine what function caused the trigger.

**返回值**：

**Original**: Value Returned

t
Trigger is registered for the indicated callback.
nil
Trigger is not registered for the indicated callback.

**参见**：

**Original**: See Also

axlTriggerClear
,
axlTriggerPrint
,
axlInTrigger
,
axlInTriggerFunc

**示例**：

**Original**: Examples

See
<
cdsroot
>/share/pcb/examples/skill/trigger
for an example.
Example 1
In
ilinit
, add:
procedure( MyTriggerOpen( t_open)
let( (brd old)
brd = car(t_open)
old = cadr(t_open)
if (old then
old = "Existing"
else
old = "New"
)
printf("SKILLCB Open %s database %s\n" old brd)
t
))
axlTriggerSet('open 'MyTriggerOpen)
Shows how to use this with
~/pcbenv/allegro.ilinit
to be notified when your user opens a new board. Echoes a print every time a user opens a new database.
Example 2
when( isCallable('axlTriggerSet) axlTriggerSet('open 'MyTriggerOpen))
To be compatible with pre-14.1 software, substitute for
axlTriggerSet
in
allegro.ilinit
.


### axlGetActiveLayer

**说明**：此函数已废弃。

**Original**: This function is obsolete.

此函数已废弃，保留用于兼容性。使用
axlDBControl
.

### axlGetActiveTextBlock

**说明**：此函数已废弃。

**Original**: This function is obsolete.

此函数已废弃。

### axlSetActiveLayer

**说明**：此函数已废弃。

**Original**: This function is obsolete.

此函数已废弃，保留用于兼容性。使用
axlDBControl
.

### axlWFMAnyExported

**语法**：
```skill
axlWFMAnyExported()
==> t/nil
```

**说明**：报告是否有任何导出的分区。
使用 axlDesignType 查看设计当前是否为分区。

**Original**: Reports if there are any exported partitions.
Use axlDesignType to see if the design is currently a partition.

**参数**：

**Original**: Arguments

None

**返回值**：

**Original**: Value Returned

t
, if one or more partitions are currently exported
nil
, if no partitions exported

**参见**：

**Original**: See Also

axlDesignType

**示例**：

**Original**: Examples

axlWFMAnyExported()


### axlDBDisplayControl

**语法**：
```skill
axlDBDisplayControl(
s_name
[g_value]
)
==> g_currentValue/ls_names
```

**说明**：此命令用于查询和设置显示数据库控制。当用于设置值时，命令返回控制的旧值。
对于大多数这些控制，如果显示当前设置的表单处于活动状态，则可能不会更新。列出了各个控制的额外副作用。
Use the
axlColorGet
and
axlColor设置
命令更改背景颜色。
当前支持的项目列在
Table 14-1
.
Table 14-1
支持的控制
名称
值
设置

**Original**: This command is used to inquire and set the display database controls. When used for setting a value, the command returns the old value of the control.
For most of these controls, if the form that is displaying the current setting is active, it may not be updated. Additional side effects of individual controls are listed.
Use the
axlColorGet
and
axlColorSet
commands to change the background color.
Items currently supported are listed in
Table 14-1
.
Table 14-1
Supported Controls
Name
Value
Set

**说明**：等效
副作用
connectPointSize
dbrep
Yes
Changes the size of connect points (diamond figures)
prmed Display group
Call
axlVisibleUpdate
to update display.
connectPointEnabled
t/nil
Yes
Changes visibility of connect points (diamond figures)
prmed Display group
Call
axlVisibleUpdate
to update display.
customColorEnabled
t/nil
Yes
Changes the display of custom colors
color192 dialog ("Enable Custom Colors")
Call
axlVisibleUpdate
to update display.
displayNet名称s
t/nil
Yes
Enables the display of net names on etch. OpenGL must be enabled.
prmed Display group
Call
axlVisibleUpdate
to update display.
designOrigin
t/nil
Yes
Enables the display of design origin
prmed Display group
Call
axlVisibleUpdate
to update display.
drcMakerSize
dbrep
Yes
Changes the size of DRC markers
prmed Display group
Call
axlVisibleUpdate
to update display.
endcapsEnable
t or nil
Yes
Controls display of line endcaps
prmed Display group
Call
axlVisibleUpdate
to update display.
filledPadsEnable
t or nil
Yes
Pads are displayed filled or hollow
prmed Display group
Call
axlVisibleUpdate
to update display.
gridColor
1
to
<maxcolor>
Yes
Changes the grid color
You can find the <
maxColor
> by running the command,
maxColor = axlColorGet(`count)
color dialog Display group
Call
axlVisibleUpdate
to update display.
gridEnable
t
or
nil
Yes
Queries and changes the grid visibility
Color form, Display Group, Grids
Call
axlVisibleUpdate
to update display.
highlightColor
1
to
<maxcolor>
Yes
Queries/changes the permanent highlight color.
Can be used with axlHighlightObject
Color form, Display Group, Permanent highlight
Also changes the perm highlight color in the
hilite
command.
Call
axlVisibleUpdate
to update display.
holeColor
1
to
<maxcolor>
Yes
Queries/changes the drill hole color.
Color form, Display Group
Call
axlVisibleUpdate
to update display.
backdrillHoleColor
1
to
<maxcolor>
Yes
Queries/changes the backdrill hole color.
Color form, Display Group
Call
axlVisibleUpdate
to update display.
lastSaveUser
string
No
Reports last user login who saved design. This may be an empty string, if the design was never saved.
Status form
None
nonPlatedHolesEnable
t
or
nil
Yes
Queries and changes the non-plated holes visibility.
Unlike in the prmed dialog, setting this option to
t
does not set
padlessHolesEnable
to t.
Color form, Display Group, Grids
Call
axlVisibleUpdate
to update display.
backdrillHolesEnable
t
or
nil
Yes
Queries and changes the backdrill holes visibility.
Must have performed the backdrill process to see the holes.
Color form, Display Group, Grids
Call
axlVisibleUpdate
to update display.
padlessHolesEnable
t or nil
Yes
Queries and changes the padless holes visibility
Color form, Display Group, Grids
Call
axlVisibleUpdate
to update display.
platedHolesEnable
t or nil
Yes
Queries and changes the plated visibility.
Unlike in the prmed dialog, setting this option to
t
does not set
padlessHolesEnable
to t.
Color form, Display Group, Grids
Call
axlVisibleUpdate
to update display.
tempColor
1
to
<maxcolor>
Yes
Queries/changes the temporary highlight color.
Can be used with axlHighlightObject
Color form, Display Group, Temporary highlight
Call
axlVisibleUpdate
to update display.
ratsnestColor
1
to
<maxcolor>
Yes
Queries/changes the ratsnest color for top to bottom ratsnest. In pre-16.2 releases, this set the color for all ratsnest.
Color form, Display Group, Ratsnest Color
Call
axlVisibleUpdate
to update display.
ratsnestBBColor
1
to
<maxcolor>
Yes
Queries/changes the ratsnest color for bottom to bottom ratsnest.
Color form, Display Group, Ratsnest Color
Call
axlVisibleUpdate
to update display.
ratsnestTTColor
1
to
<maxcolor>
Yes
Queries/changes the ratsnest color for top to top ratsnest.
Color form, Display Group, Ratsnest Color
Call
axlVisibleUpdate
to update display.
ratsnestJog
t/nil
Yes
Queries/changes the ratsnest jog option.
prmed form, Display Group, Ratsnest Jog
None
ratTSize
dbrep
Yes
Changes the size of RatT markers
prmed Display group
Call
axlVisibleUpdate
to update display.
thermalPadEnable
t/nil
Yes
Queries and changes the thermal pads. Only applicable for negative planes.
prmed Display group
Call
axlVisibleUpdate
to update display.
transparencyGlobal
1 to 255
Yes
Changes the OpenGL global transparency where 1 is completely translucent and 255 is solid.
prmed Display group
Call
axlVisibleUpdate
to update display.
transparencyShape
1 to 255
Yes
Changes the OpenGL shape transparency where 1 is completely translucent and 255 is solid.
prmed Display group
Call
axlVisibleUpdate
to update display.
viaLabel
t/nil
Yes
Queries and changes the via label display.
prmed Display group
Now called "Drill labels" in dialog
Call
axlVisibleUpdate
to update display.
viaLabelColor
1
to
<maxcolor>
Yes
Queries and changes the via label color.
Color form, Display Group
Now called "Drill labels" in dialog
Call
axlVisibleUpdate
to update display.
stackedViaLabelColor
1
to
<maxcolor>
Yes
Queries and changes the stacked via label color.
Color form, Display Group
Call
axlVisibleUpdate
to update display.
waiveDRCColor
1
to
<maxcolor>
Yes
Queries and changes the waived DRC color.
Color form, Display Group, Waived DRC
Call
axlVisibleUpdate
to update display.
waiveDRCEnable
t/nil
Yes
Queries and changes the waived DRC display state
Color form, Display Group, Waived DRC
Call
axlVisibleUpdate
to update display.

**Original**: Equivalent
Side Effects
connectPointSize
dbrep
Yes
Changes the size of connect points (diamond figures)
prmed Display group
Call
axlVisibleUpdate
to update display.
connectPointEnabled
t/nil
Yes
Changes visibility of connect points (diamond figures)
prmed Display group
Call
axlVisibleUpdate
to update display.
customColorEnabled
t/nil
Yes
Changes the display of custom colors
color192 dialog ("Enable Custom Colors")
Call
axlVisibleUpdate
to update display.
displayNetNames
t/nil
Yes
Enables the display of net names on etch. OpenGL must be enabled.
prmed Display group
Call
axlVisibleUpdate
to update display.
designOrigin
t/nil
Yes
Enables the display of design origin
prmed Display group
Call
axlVisibleUpdate
to update display.
drcMakerSize
dbrep
Yes
Changes the size of DRC markers
prmed Display group
Call
axlVisibleUpdate
to update display.
endcapsEnable
t or nil
Yes
Controls display of line endcaps
prmed Display group
Call
axlVisibleUpdate
to update display.
filledPadsEnable
t or nil
Yes
Pads are displayed filled or hollow
prmed Display group
Call
axlVisibleUpdate
to update display.
gridColor
1
to
<maxcolor>
Yes
Changes the grid color
You can find the <
maxColor
> by running the command,
maxColor = axlColorGet(`count)
color dialog Display group
Call
axlVisibleUpdate
to update display.
gridEnable
t
or
nil
Yes
Queries and changes the grid visibility
Color form, Display Group, Grids
Call
axlVisibleUpdate
to update display.
highlightColor
1
to
<maxcolor>
Yes
Queries/changes the permanent highlight color.
Can be used with axlHighlightObject
Color form, Display Group, Permanent highlight
Also changes the perm highlight color in the
hilite
command.
Call
axlVisibleUpdate
to update display.
holeColor
1
to
<maxcolor>
Yes
Queries/changes the drill hole color.
Color form, Display Group
Call
axlVisibleUpdate
to update display.
backdrillHoleColor
1
to
<maxcolor>
Yes
Queries/changes the backdrill hole color.
Color form, Display Group
Call
axlVisibleUpdate
to update display.
lastSaveUser
string
No
Reports last user login who saved design. This may be an empty string, if the design was never saved.
Status form
None
nonPlatedHolesEnable
t
or
nil
Yes
Queries and changes the non-plated holes visibility.
Unlike in the prmed dialog, setting this option to
t
does not set
padlessHolesEnable
to t.
Color form, Display Group, Grids
Call
axlVisibleUpdate
to update display.
backdrillHolesEnable
t
or
nil
Yes
Queries and changes the backdrill holes visibility.
Must have performed the backdrill process to see the holes.
Color form, Display Group, Grids
Call
axlVisibleUpdate
to update display.
padlessHolesEnable
t or nil
Yes
Queries and changes the padless holes visibility
Color form, Display Group, Grids
Call
axlVisibleUpdate
to update display.
platedHolesEnable
t or nil
Yes
Queries and changes the plated visibility.
Unlike in the prmed dialog, setting this option to
t
does not set
padlessHolesEnable
to t.
Color form, Display Group, Grids
Call
axlVisibleUpdate
to update display.
tempColor
1
to
<maxcolor>
Yes
Queries/changes the temporary highlight color.
Can be used with axlHighlightObject
Color form, Display Group, Temporary highlight
Call
axlVisibleUpdate
to update display.
ratsnestColor
1
to
<maxcolor>
Yes
Queries/changes the ratsnest color for top to bottom ratsnest. In pre-16.2 releases, this set the color for all ratsnest.
Color form, Display Group, Ratsnest Color
Call
axlVisibleUpdate
to update display.
ratsnestBBColor
1
to
<maxcolor>
Yes
Queries/changes the ratsnest color for bottom to bottom ratsnest.
Color form, Display Group, Ratsnest Color
Call
axlVisibleUpdate
to update display.
ratsnestTTColor
1
to
<maxcolor>
Yes
Queries/changes the ratsnest color for top to top ratsnest.
Color form, Display Group, Ratsnest Color
Call
axlVisibleUpdate
to update display.
ratsnestJog
t/nil
Yes
Queries/changes the ratsnest jog option.
prmed form, Display Group, Ratsnest Jog
None
ratTSize
dbrep
Yes
Changes the size of RatT markers
prmed Display group
Call
axlVisibleUpdate
to update display.
thermalPadEnable
t/nil
Yes
Queries and changes the thermal pads. Only applicable for negative planes.
prmed Display group
Call
axlVisibleUpdate
to update display.
transparencyGlobal
1 to 255
Yes
Changes the OpenGL global transparency where 1 is completely translucent and 255 is solid.
prmed Display group
Call
axlVisibleUpdate
to update display.
transparencyShape
1 to 255
Yes
Changes the OpenGL shape transparency where 1 is completely translucent and 255 is solid.
prmed Display group
Call
axlVisibleUpdate
to update display.
viaLabel
t/nil
Yes
Queries and changes the via label display.
prmed Display group
Now called "Drill labels" in dialog
Call
axlVisibleUpdate
to update display.
viaLabelColor
1
to
<maxcolor>
Yes
Queries and changes the via label color.
Color form, Display Group
Now called "Drill labels" in dialog
Call
axlVisibleUpdate
to update display.
stackedViaLabelColor
1
to
<maxcolor>
Yes
Queries and changes the stacked via label color.
Color form, Display Group
Call
axlVisibleUpdate
to update display.
waiveDRCColor
1
to
<maxcolor>
Yes
Queries and changes the waived DRC color.
Color form, Display Group, Waived DRC
Call
axlVisibleUpdate
to update display.
waiveDRCEnable
t/nil
Yes
Queries and changes the waived DRC display state
Color form, Display Group, Waived DRC
Call
axlVisibleUpdate
to update display.

**参数**：

**Original**: Arguments

s_name
symbol name of control. nil returns all possible names
s_value
optional symbol value to set. Usually a
t
or a
nil
.

**返回值**：

**Original**: Value Returned

See above
ls_names
: If name is
nil
then returns a list of all controls.

**参见**：

**Original**: See Also

axlDBControl
,
axlColorGet
,
axlColorShadowGet

**示例**：

**Original**: Examples

Find out grid color
color = axlDBDisplayControl('gridColor, nil)
Turn on grids
old = axlDBDisplayControl('gridEnable t)
Get all names supported by this interface
listOfNames = axlDBDisplayControl(nil)

