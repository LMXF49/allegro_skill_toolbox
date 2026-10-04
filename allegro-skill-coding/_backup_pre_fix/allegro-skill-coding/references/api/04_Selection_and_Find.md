# 第4章 选择与查找 (Selection and Find)

> **Original**: Selection and Find Functions
> 
> Product Documentation | Allegro SKILL Reference | Product Version 17.4-2019, October 2019

## 4.1 概述 (Overview)

**说明**：AXL 编辑函数（如 move 或 delete）操作选择集中包含的数据库对象 dbid。选择集是您先前选择的一个或多个对象 dbid 的列表。您使用本章介绍的 axlSelect 函数将 dbid 添加到选择集。您可以在任何编辑函数调用中将选择集作为参数。这与交互式 Allegro PCB Editor 编辑命令不同，在后者中，您先启动命令，然后选择要编辑的对象。

**Original**: AXL edit functions such as move or delete operate on database object dbids contained in the select set. The select set is a list of one or more object dbids you have previously selected. You add dbids to the select set with the axlSelect functions described in this chapter. You use the select set as an argument in any edit function calls. This differs from interactive Allegro PCB Editor edit commands, where you first start a command, then select the objects to be edited.

**说明**：选择集的一个优点是，选定的对象 dbid 会保留在选择集中，直到您显式更改它。您可以对同一组对象执行多次编辑，而无需重新选择。但是请记住，编辑函数可能会导致 dbid 超出范围。本章还描述了管理选择集和控制选择过滤器的函数。

**Original**: One advantage of a select set is that selected object dbids stay in the select set from function to function until you explicitly change it. You can perform multiple edits on the same set of objects without reselecting. Remember, however, that edit functions might cause dbids to go out of scope. This chapter also describes functions for managing the select set and controlling the selection filter.

**说明**：AXL 支持一个活动选择集。选择集的内容在您退出 Allegro PCB Editor 时失效。交互式选择函数仅在可见层上查找对象。

**Original**: AXL supports one active select set. The contents of the select set becomes invalid when you exit Allegro PCB Editor. The interactive select functions find objects only on visible layers.

**说明**：使用选择函数可以执行以下操作：
- 设置查找过滤器以控制选择的对象类型
- 在单点、区域或按名称选择对象
- 选择对象的部分，例如封装符号的单个引脚
- 从选择集中添加或移除 dbid

**Original**: You can do the following with the selection functions: Set the Find Filter to control the types of objects selected; Select objects at a single point, over an area, or by name; Select parts of objects, such as individual pins of a package symbol; Add or remove dbids from the select set.

**说明**：选择集可以包含图形部分的 dbid，而不包含图形本身。例如，您可以选择符号的一个或多个引脚，或路径图形的单个线段。选择集可以交互式地通过鼠标单击图形（点选择）或绘制包含图形的框（框选择）来添加图形 dbid。查找过滤器控制特定对象类型的过滤。

**Original**: A select set can contain dbids of parts of a figure without containing the figure itself. For example, you can select one or more pins of a symbol or individual segments of a path figure. You can add figure dbids to the select set interactively with a mouse click on the figure (point selection) or by drawing a box that includes the figure (box selection). The Find Filter controls filtering for specific object types.

**说明**：除非另有说明，所有坐标均使用用户单位。

**Original**: All coordinates are in user units unless otherwise noted.

### 选择集高亮 (Select Set Highlighting)

**说明**：当控制权从 SKILL 传递给您进行交互式输入（用于选择）或 SKILL 将控制权返回给 Allegro PCB Editor shell 时，选择集中的对象会显示为高亮。您可以使用 AXL-SKILL 函数选择和修改对象。若要使这些对象不显示为高亮，请在将控制权返回给您进行交互式输入或返回给 Allegro PCB Editor shell 之前，将它们从选择集中移除。

**Original**: Objects in the select set are displayed as highlighted when control passes from SKILL to you for interactive input (for selection) or when SKILL returns control to the Allegro PCB Editor shell. You can select and modify objects using AXL-SKILL functions. To keep these objects from displaying as highlighted, remove them from the select set before returning SKILL control to you for interactive input or to the Allegro PCB Editor shell.

### 选择模式 (Select Modes)

**说明**：AXL 提供两种选择模式：

**Original**: AXL provides two select modes:

- **single（单一模式）**：选择符合选择条件的一个或一组对象。在此模式下选择对象时，AXL 会取消选择选择集中先前存在的任何对象。

  **Original**: Selects one or a group of objects that match the selection criteria. When you select an object in this mode, AXL deselects any objects previously in the select set.

- **cumulated（累积模式）**：向选择集添加或从选择集减去符合选择条件的一个或一组对象。添加累积模式不会添加已存在于选择集中的对象，因此如果您误选同一对象两次，不会出现重复条目。同一对象的后续选择将被忽略。

  **Original**: Adds to or subtracts from the select set one or a group of objects that match the selection criteria. Add cumulated mode never adds an object already in the set, so you do not have duplicate entries if you mistakenly select the same object twice. Subsequent selects of the same object are ignored.

### 按名称查找对象 (Finding Objects by Name)

**说明**：axlSingleSelectName、axlAddSelectName 和 axlSubSelectName 函数通过名称查找对象。您可以通过名称搜索以下 Allegro PCB Editor 对象类型：

**Original**: The axlSingleSelectName, axlAddSelectName, and axlSubSelectName functions find objects by using their names. You can search for the following Allegro PCB Editor object types by name:

The
axlSingleSelectName
,
axlAddSelectName
, and
axlSubSelectName
functions find objects by using their names. You can search for the following Allegro PCB Editor object types by name:
NET
List of net names for net selection.
COMPONENT
List of reference designators for component instance selection.
SYMBOL
List of reference designators for symbol instance selection.
FUNCTION
List of function designators for function instance selection.
DEVTYPE
List of device type for component or symbol instance selection. **
SYMTYPE
List of symbol types for symbol instance selection.
REFDES
List of reference designators for component or symbol instance selection. **
DEVSYM
List of device type for symbol instance selection.
GROUP
List of group names for group or group member selection.
PROPERTY
List of property names or property value) lists for selection of database object that have the property/value. If no value is provided, the value will be ignored for the database property comparison. The find filter enabled and onButtons control the type of elements that will be selection.
** For DEVTYPE and REFDES, a component instance is selected if COMPONENTS are in the find filter ?enabled list. Otherwise, if SYMBOLS are enabled, a symbol instance is selected.
See the descriptions of the
SelectName
functions for how to set up the arguments.
### 点选 (Point Selection)

**说明**：这些函数在单个几何点处选择对象。如果函数调用中缺少该参数，它们会提示您输入点。

**Original**: These functions select objects at a single geometric point. They prompt you for the point if that argument is missing from the function call.

### 框选 (Area Selection)

**说明**：这些函数在一个区域内选择对象。如果函数调用中缺少该参数，它们会提示您输入区域（Bbox）。

**Original**: These functions select objects over an area. They prompt you for the area (Bbox) if that argument is missing from the function call.

### 其他选择函数 (Miscellaneous Select Functions)

**说明**：这些函数通过其他方式进行选择，如本章后面每个函数描述所示：

**Original**: These functions select by other means as shown in each function description later in this chapter:

These functions select by other means as shown in each function description later in this chapter:
axlAddSelectAll
axlSubSelectAll
axlSingleSelectName
axlAddSelectName
axlSubSelectName
axlSingleSelectObject
axlAddSelectObject
axlSubSelectObject
### axlSelect — 通用选择函数

**说明**：axlSelect 函数结合了 axlAddSelect 函数的功能。编写交互式命令时，使用 axlSelect 可为用户提供与 Allegro PCB Editor 命令（如 move 或 delete）相同的选择功能。

**Original**: One function, axlSelect, combines the capabilities of the axlAddSelect functions. Use axlSelect as you write interactive commands to give the user the same select capabilities available in Allegro PCB Editor commands move or delete.

### 选择集管理 (Select Set Management)

**说明**：这些函数管理选择集：

**Original**: These functions manage the select set:

### 查找过滤器控制 (Find Filter Control)

**说明**：这些函数控制选择过滤器：

**Original**: These functions control the selection filter:

### 查找过滤器选项 (Find Filter Options)

**说明**：您可以使用 Find Filter 或本章介绍的 FindFilter 函数将给定窗口中的选择限制为所有可能图形类型的子集。FindFilter 函数还控制 Find Filter 是否对您立即可见。

**Original**: You can restrict selection in a given window to a subset of all possible figure types by using the Find Filter or the FindFilter functions described in this chapter. FindFilter functions also control whether the Find Filter is immediately visible to you.

You can restrict selection in a given window to a subset of all possible figure types by using the
Find Filter
or the
FindFilter
functions described in this chapter.
FindFilter
functions also control whether the
Find Filter
is immediately visible to you.
The permissible keywords for the
lt_options
list are shown. These keywords are a subset of the Allegro PCB Editor Find Filter. You can prefix any of these keywords with
NO
to reverse the effect. See the description of
for details on how to use these keywords:
Global
ALL
,
ALLTYPES
,
EQUIVLOGIC
Figures
PINS
,
VIAS
,
CLINES
,
CLINESEGS
,
LINES
,
LINESEGS
,
DRCS
,
TEXT
,
SHAPES
(includes rectangles),
SHAPESEGS
,
VOIDS
,
VOIDSEGS
,
TEXT
.
The
xxx
SEG
keywords also select arc and circle segments
Logic
COMPONENTS
,
SYMBOLS
,
NETS
Except for
EQUIVLOGIC
, the
Find Filter
functions take the keywords in the order found. For example, the list
(ALL NOPIN)
results in all objects except pins being selectable.
EQUIVLOGIC
is a global find state. It instructs
find
to select the physically equivalent parts, as specified in the filter of the found logic object. For example, if the user picks any physical part of a net, the selection returns any physical parts of the (logical) net selected by the
find filter
. Both the logical and the physical objects must be enabled. For example, to select all pins of a net, both
NETS
and
PINS
must be enabled and set with
?onButton
.
## 4.2 选择与查找函数 (Selection and Find Functions)

**说明**：本节列出选择和查找函数。

**Original**: This section lists selection and find functions.

This section lists selection and find functions.
### axlSingleSelectPoint

**说明**：在输入点附近查找符合查找过滤器条件的对象，并将其添加到选择集中，同时清除所有先前的选择。如果未提供点，则会在查找操作前提示选择点。除非 EQUIVLOGIC 开启，否则只选择单个对象。如果开启，可能会选择多个对象，例如，如果找到属于网络的合格图形（如引脚、连接线或过孔）。axlSingleSelectPoint 将属于网络的所有合格图形添加到选择集。

**语法**：
```skill
axlSingleSelectPoint
axlSingleSelectPoint(
[
l_point
]
[trapEnable]
)
⇒ t/nil
```

**Original**: Description

```
Finds an object that is close to the input point and meets the
Find
filter criteria and adds that object to the selection set after clearing all previous selections. If no point is provided, prompts to select a point prior to the find operation.
axlSingleSelectPoint
selects a single object and adds it to the select set, unless
EQUIVLOGIC
is on. In that case, it may select multiple objects, for example, if it finds a qualified figure (such as a pin, connect line, or via) that is part of a net.
axlSingleSelectPoint
adds all the qualified figures that belong to the net to the select set. (See the
Find Filter Options
.)
This finds objects within the current trapsize (
axlGetTrapBox
), which varies based upon the zoom factor.
```

**参数**：

l_point
Coordinate pair for xy location where objects are to be found.
trapEnable
By default, enables a a trap box, which is based on the zoom level of the canvas. Objects that are found can be effected based on the current zoom level. When this option is set to
nil
the trap size gets disabled.

**返回值**：

t
One or more
dbids
put in the select set.
nil
No
dbids
put in the select set.
An object which is currently in the selection set may be reselected if there are no unselected objects that qualify for selection at the given point and find filter.

**示例**：

```skill
Adds a previously defined user property
MYPROP
to a pin at X6325 Y3575.
axlSetFindFilter(?enabled "pins" ?onButtons "pins")
axlSingleSelectPoint( 6325:3575 )
axlDBAddProp(axlGetSelSet() list( "MYPROP" 23.5))
⇒
t
To check
From Allegro PCB Editor, choose
Display – Element
.
Select the pin to display its properties.
The
Show Element
window displays
MYPROP
with value
23.500000 level
```

**另见**：

### axlAddSelectPoint

**说明**：在输入点附近查找未选择的对象，如果符合查找过滤器条件，则将其添加到选择集。如果未提供点，则会在查找操作前提示选择点。除非 EQUIVLOGIC 开启，否则只选择单个对象。

**语法**：
```skill
axlAddSelectPoint
axlAddSelectPoint
axlAddSelectPoint(
[
l_point
]
[
trapEnable
]
)
⇒ t/nil
```

**Original**: Description

```
Finds a non-selected object that is close to the input point and meets the
Find
filter criteria and adds that object to the selection set. If no point is provided, prompts to select a point prior to the find operation.
Selects a single object and adds it to the select set, unless
EQUIVLOGIC
is on. In that case, it may select multiple objects, for example, if it finds a qualified figure (such as a pin, connect line, or via) that is part of a net. Adds all the qualified figures that belong to the net to the select set. (See the
Find Filter Options
.)
This function finds objects within the current trapsize (
axlGetTrapBox
), which varies based upon the zoom factor.
```

**参数**：

l_point
Coordinate pair for xy location where objects are to be found.
trapEnable
Set to
nil
to restrict found elements to exactly matching location, instead of close to the location.

**返回值**：

t
One or more
dbids
put in the select set.
nil
No
dbids
put in the select set.

**示例**：

```skill
See
axlSingleSelectPoint
for an example.
axlSingleSelectPoint
has the same behavior except that it selects only one object.
```

**另见**：

### axlSingleSelectPoint

**说明**：在输入点附近查找符合查找过滤器条件的对象，并将其添加到选择集中，同时清除所有先前的选择。如果未提供点，则会在查找操作前提示选择点。除非 EQUIVLOGIC 开启，否则只选择单个对象。如果开启，可能会选择多个对象，例如，如果找到属于网络的合格图形（如引脚、连接线或过孔）。axlSingleSelectPoint 将属于网络的所有合格图形添加到选择集。

**语法**：
```skill
axlSingleSelectPoint
,
axlSubSelectBox
,
axlSingleSelectBox
,
axlAddSelectBox
,
axlSubSelectPoint
axlSubSelectPoint
axlSubSelectPoint(
[
l_point
]
[trapEnable]
)
⇒ t/nil
```

**Original**: Description

```
Finds a selected object that is close to the input point and meets the find filter criteria and removes that object from the selection set. If no point is provided, prompts to select a point prior to the find operation.
Removes a
single
object from the select set, unless
EQUIVLOGIC
is on. In that case, itmay find multiple objects, for example, if it finds a qualified figure (such as a pin, connect line, or via) that is part of a net. Deletes all the qualified figures that belong to the net from the select set. (See the
Find Filter Options
.)
This function finds objects within the current trapsize (
axlGetTrapBox
), which varies based upon the zoom factor.
```

**参数**：

l_point
Coordinate pair for xy location where objects are to be found.
trapEnable
Set to
nil
to restrict found elements to exactly matching location, instead of close to the location.

**返回值**：

t
One or more
dbids
removed from the select set
nil
No
dbids
removed from the select set.

**示例**：

```skill
Adds a previously defined user property,
MYPROP
Selects four pins in a box in order.
Before adding the property, subtracts the pin at
6325:3575
from the list, then adds as shown in the following example:
axlSetFindFilter(?enabled "pins" ?onButtons "pins")
axlSingleSelectBox( list(6200:3700 6500:3300))
axlSubSelectPoint( 6325:3575 )
axlDBAddProp(axlGetSelSet() list("MYPROP" 23.5))
⇒ t
To check
Select
Edit – Properties
.
Select a window around all four pins.
Select
MYPROP
from the Available Properties list in the
Edit Property
window.
The command displays the pins that have properties in the
Show Properties
window. Only the three pins not subtracted from the select set have the property,
MYPROP
.
```

**另见**：

### axlAddSelectPoint

**说明**：在输入点附近查找未选择的对象，如果符合查找过滤器条件，则将其添加到选择集。如果未提供点，则会在查找操作前提示选择点。除非 EQUIVLOGIC 开启，否则只选择单个对象。

**语法**：
```skill
axlAddSelectPoint
axlSingleSelectBox
axlSingleSelectBox(
[
l_bBox
]
[
trapEnable
]
)
⇒ t/nil
```

**Original**: Description

```
Finds all objects that intersect with the input box and meet the find filter criteria and adds those objects to the selection set after clearing all previous selections. If no box (or an incomplete box) is provided, prompts to select a box (or to complete the box) prior to the find operation.
```

**参数**：

l_bBox
List containing one or two coordinates defining the bounding box to be used to select the figures. If
l_bBox
is
nil
, requests two picks from the user. If
l_bBox
has only one point, asks for a second point from the user.
trapEnable
Set to
nil
to restrict found elements to exactly matching location, instead of close to the location.

**返回值**：

t
One or more objects added to the select set.
nil
No objects added to the select set.

**示例**：

```skill
Adds a previously defined user property
MYPROP
to four pins by selecting a box around them with corners (
6200:3700 6500:3300
).
axlSetFindFilter(?enabled "pins" ?onButtons "pins")
axlSingleSelectBox( list(6200:3700 6500:3300))
axlDBAddProp(axlGetSelSet() list( "MYPROP" 23.5))
⇒ t
To check
Select
Edit – Properties
.
Select the four pins.
Select
MYPROP
from the Available Properties list in the
Edit Property
window.
The command displays the four pins in the
Show Properties
window as having
MYPROP
with value
23.500000 level
```

**另见**：

### axlAddSelectPoint

**说明**：在输入点附近查找未选择的对象，如果符合查找过滤器条件，则将其添加到选择集。如果未提供点，则会在查找操作前提示选择点。除非 EQUIVLOGIC 开启，否则只选择单个对象。

**语法**：
```skill
axlAddSelectPoint
,
axlAddSelectBox
axlAddSelectBox
axlAddSelectBox(
[
l_bBox
]
[
trapEnable
]
)
⇒ t/nil
```

**Original**: Description

```
Finds all non-selected objects that intersect with the input box and meet the find filter criteria and adds those objects to the selection set. If no box (or an incomplete box) is provided, prompts to select a box (or to complete the box) prior to the find operation.
```

**参数**：

l_bBox
List containing one or two coordinates defining the bounding box to be used to the select figures. If
l_bBox
is
nil
, requests two picks from the user. If
l_bBox
has only one point, asks for a second point from the user.
trapEnable
Set to
nil
to restrict found elements to exactly matching location, instead of close to the location.

**返回值**：

t
One or more objects added to the select set.
nil
No objects added to the select set.

**示例**：

```skill
See the example for
axlSingleSelectBox
. That function behaves exactly as
axlAddSelectBox
, except that
axlSingleSelectBox
does not clear the select set.
```

**另见**：

### axlAddSelectPoint

**说明**：在输入点附近查找未选择的对象，如果符合查找过滤器条件，则将其添加到选择集。如果未提供点，则会在查找操作前提示选择点。除非 EQUIVLOGIC 开启，否则只选择单个对象。

**语法**：
```skill
axlAddSelectPoint
,
axlSingleSelectBox
axlSubSelectBox
axlSubSelectBox(
[
l_bBox
]
[
trapEnable
]
)
⇒ t/nil
```

**Original**: Description

```
Finds all selected objects that intersect with the input box and meet the find filter criteria and removes those objects from the selection set. If no box (or an incomplete box) is provided, prompts to select a box (or to complete the box) prior to the find operation.
```

**参数**：

l_bBox
List containing one or two coordinates defining the bounding box to be used to the select figures. If
l_bBox
is
nil
, requests two picks from the user. If
l_bBox
has only one point, asks for a second point from the user.
trapEnable
Set to
nil
to restrict found elements to exactly matching location, instead of close to the location.

**返回值**：

t
One or more objects deleted from select set.
nil
No objects deleted from select set.

**示例**：

```skill
See
axlSubSelectPoint
for an example of subtracting from the select set, and
axlAddSelectPoint
for an example of using a box for selection.
```

**另见**：

### axlAddSelectPoint

**说明**：在输入点附近查找未选择的对象，如果符合查找过滤器条件，则将其添加到选择集。如果未提供点，则会在查找操作前提示选择点。除非 EQUIVLOGIC 开启，否则只选择单个对象。

**语法**：
```skill
axlAddSelectPoint
axlAddSelectAll
axlAddSelectAll()
⇒ t/nil
```

**Original**: Description

```
Finds all the figures in the database that pass the current Find Filter and adds their
dbids
to the select set.
```

**参数**：

None.

**返回值**：

t
One or more object
dbids
added to the select set.
nil
No object
dbids
added to the select set.

**示例**：

```skill
axlSetFindFilter(?enabled list( "noall" "vias")
?onButtons list( "noall" "vias"))
axlAddSelectAll()
axlDeleteObject(axlGetSelSet())
⇒ t
Selects all vias in a layout and deletes them.
axlSubSelectAll
axlSubSelectAll()
⇒ t/nil
Description
Finds all figures in the database that pass the current Find Filter and deletes their
dbids
from the select set. Use
axlSubSelectAll
to subtract all of a given type of figure from a larger set of selected objects.
Use
axlClearSelSet
to deselect all figures in the current select set, regardless of the current Find Filter.
Arguments
None.
Value Returned
t
One or more
dbids
deleted from select set.
nil
No
dbids
deleted from select set.
Dependent on find filter ?enabled settings.
Example 1
The following example selects the nets GND and VCC by their names.
axlClearSelSet()
axlSetFindFilter(?enabled
list( "noall" "equivlogic" "nets" "clines" "vias")
?onButtons list( "all"))
axlSingleSelectName( "NET" list( "GND" "VCC"))
==> (dbid:234436 dbid:98723)
axlSingleSelectName("PROPERTY" list( list("BUS_NAME" "MEM") "FIXED"
)⇒ t
Interactively selects all connect lines (clines) and vias on a net, subtracts the via
dbids
from the select set, and deletes the remaining
dbids
in the select set.
The prompt
Enter
selection
point
, is displayed. Only the connect lines on the net you select are deleted—not the vias of the net.
Example 2
The following example selects a set of nets--one set by the property name ELECTRICAL_CONSTRAINT_SET with value DEFAULT, and another set that has the name ROUTE_PRIORITY.
axlClearSelSet()
axlSetFindFilter( ?enabled list( "noall" "nets")
?onButtons list( "all"))
axlSingleSelectName("PROPERTY"
list( list( "ELECTRICAL_CONSTRAINT_SET" "DEFAULT")
"ROUTE_PRIORITY"))
==> (dbid:234436 dbid:98723 dbid:234437 dbid:98727
dbid:234438 dbid:98725 dbid:234439 dbid:98726)
axlSingleSelectName
axlSingleSelectName(
t_nameType
l_names
[g_wildcard]
)
⇒ t/nil
Description
Finds figures by their names. Clears the current contents of the select set and adds named figure
dbids
to the select set in single mode using the arguments as described below. The function selects any figures completely, regardless of the selection mode. If the function selects a figure already partially selected, the figure becomes fully selected.
The
on
buttons are used for selecting
Properties
by name only. Both
axlSubSelectName
and
axlAddSelectName
always operate in wildcard mode. Both take the optional wildcard argument but ignore it. In the future, if passed
nil
, they may obey the argument.
Arguments
t_nameType
Indicates the type of name string being provided. Also implies the type of object to be selected. (see
Finding Objects by Name
).
l_names
List of item name names or for properties a name value. This varies with the nameType. Supports a single name item outside of a list. Therefore, supported values can be:
– a name
– a list of names
– a list of name/value pairs
g_wildcard
A
t
means that
*
or
?
performs regular expression matching. Default is
nil
where
*
and
?
are treated as normal characters.
Value Returned
t
One or more objects added to the select set.
nil
No objects added to the select set.
Example 1
axlClearSelSet()
axlSetFindFilter(
?enabled list( "noall" "nets")
?onButtons list( "all"))
axlSingleSelectName ("NET" (list ("GND" "VCC"))
⇒ (dbid:234436 dbid:98723)
axlSingleSelectName ("PROPERTY" (list (list "BUS_NAME" "MEM") "FIXED")
Selects the nets
GND
and
VCC
by their names.
Example 2
axlClearSelSet()
axlSetFindFilter(
?enabled list( "noall" "nets")
?onButtons list( "all"))
axlSingleSelectName ("PROPERTY"
list(
list( "ELECTRICAL_CONSTRAINT_SET" "ECL_DEFAULT")
"ROUTE_PRIORITY"))
⇒ (dbid:234436 dbid:98723 dbid:234437 dbid:98727
dbid:234438 dbid:98725 dbid:234439 dbid:98726)
Selects a set of nets—one set by the property name
ELECTRICAL_CONSTRAINT_SET
with value
ECL_DEFAULT
, and another set that has the name
ROUTE_PRIORITY
.
axlAddSelectName
axlAddSelectName(
t_nameType
l_names
)
⇒ t/nil
Description
Adds the named figure
dbids
to the select set in cumulated mode according to the arguments described below. Adds the found figures to the select set if not already there. Selects figures completely regardless of the selection mode. If the function selects a figure already partially selected, the figure becomes fully selected.
Arguments
t_nameType
String denoting the name type to be selected (see
Finding Objects by Name
). Also implies the type of object to be selected.
l_names
List of item name names or for properties a name value. This varies with the nameType. Supports a single name item outside of a list. Therefore, supported values can be:
– a name
– a list of names
– a list of name/value pairs
Value Returned
t
One or more objects added to the select set.
nil
No objects added to the select set.
The on buttons matter for select Properties by name, but don't for other name types. Both
axlSubSelectName
and
axlAddSelectName
always operate in wildcard mode. Both take the optional wildcard argument, but ignore it. In the future, if passed
nil
they may obey the argument.
Example
See examples for
axlSingleSelectName
. The only difference is that
axlSingleSelectName
clears the select set, while
axlAddSelectName
adds the selected
dbids
into the select set without removing any already in it. The arguments for
axlAddSelectName
are the same as for
axlSingleSelectName
.
axlSubSelectName
axlSubSelectName(
t_nameType
l_names
)⇒ t/nil
Description
Removes
dbids
of the named figure from the select set using the arguments described. Removes figures completely regardless of the selection mode. If the function finds a figure already partially selected, it removes all of its
dbids
from the select set.
Arguments
t_nameType
String denoting name type to be selected (see
Finding Objects by Name
). Also implies the type of object to be selected.
l_names
List of item name names or for properties a name value. This varies with the nameType. Supports a single name item outside of a list. Therefore, supported values can be:
– a name
– a list of names
– a list of name/value pairs
Value Returned
t
One or more objects deleted from select set.
nil
No objects deleted from select set.
The on buttons matter for select Properties by name, but not for other name types. Both
axlSubSelectName
and
axlAddSelectName
always operate in wildcard mode. Both take the optional wildcard argument, but ignore it. In the future, if passed
nil,
they may obey the argument.
Example
See examples for
axlSingleSelectName
. The only difference is that
axlSingleSelectName
clears the select set and then puts the
dbids
it finds into the select set, while
axlSubSelectName
removes the
dbids
of the elements it selects from the select set. The arguments are the same as
axlSingleSelectName
.
axlSingleSelectObject
axlSingleSelectObject(
lo_dbid
)
⇒ t/nil
Description
Clears contents of the select set and adds the dbids in
lo_dbid
to the select set in single mode.
lo_dbid
is either a single dbid or a list of dbids. Selects figures completely regardless of the selection mode. If the dbid of any part of a figure is in
lo_dbid
, the function adds the entire figure.
You need to "BOUNDARY_SHAPES" to the axlSetFindFilter "?enabled" option if you wish to select a dynamic shape. Generated shape from dynamics shapes cannot be selected via the SelectObject APIs since it cannot be edited.
Arguments
lo_dbid
dbid, or list of dbids to be added to the select set.
Value Returned
t
One or more objects added to the select set.
nil
No objects added to the select set.
Example
axlClearSelSet()
axlSetFindFilter(
?enabled list( "all" "equivlogic")
?onButtons list( "all"))
mysym = axlDBCreateSymbol(
list( "dip14" "package"), 5600:4600)
axlSingleSelectObject(car(mysym))
⇒ t
Creates a symbol and add its dbid to the select set.
axlAddSelectObject
axlAddSelectObject(
lo_dbid
)
⇒ t/nil
Description
Adds the
dbids
in
lo_dbid
to the select set in cumulated mode, that is, without removing already selected objects.
lo_dbid
is either a single
dbid
or a list of
dbids
. Adds
dbids
in the select set only if they are not already there. Selects figures completely regardless of the selection mode. If the
dbid
of any part of a figure is in
lo_dbid
, adds the entire figure.
Arguments
lo_dbid
dbid
, or list of
dbids
to be added to the select set.
Value Returned
t
One or more objects added to the select set.
nil
No objects added to the select set.
Example
axlSetFindFilter(
?enabled list( "all")
?onButtons list( "all"))
mysym = axlDBCreateSymbol(
list("dip14" "package") 2600:2600 ) axlAddSelectObject(car(mysym))
⇒ t
Creates a symbol instance and adds its
dbid
to the select set.
axlSubSelectObject
axlSubSelectObject(
lo_dbid
)
⇒ t/nil
Description
Removes the
dbids
in
lo_dbid
from the select set in cumulated mode.
lo_dbid
is either a single
dbid
or a list of
dbids
. Removes figures completely regardless of the selection mode.
Arguments
lo_dbid
dbid
, or list of
dbids
to be removed from select set.
Value Returned
t
One or more objects deleted from select set.
nil
No objects deleted from select set.
Example
axlClearSelSet()
axlSetFindFilter(?enabled list("noall" "vias")
?onButtons list( "vias"))
myvia = axlDBCreateVia( "pad1", 3025:3450)
axlAddSelectBox( list( 3000:3100 3200:3600))
axlSubSelectObject( car( myvia))
⇒ t
Creates a via, then selects all the vias in a surrounding region for deletion, but saves the one just created by subtracting its
dbid
from the selection set.
The resulting select set contains the
dbids
of all vias in the box except
myvia
, the one just created.
axlSelect
axlSelect(
?firstEventCallback
s_callback
?groupMode t/nil
?prompt
t_prompt
)
⇒ t/nil
Description
General tool for AXL programs to solicit interactive object selections from the user.
axlSelect
automatically sets up the pop-up to provide any of the possible Allegro PCB Editor selection methods:
Single point select
Window select
Group select
You can set up the pop-up to display other options such as
Done
and
Cancel
, but the function also displays the find options. See the example.
Before
axlSelect
returns, it puts in the select set a list of the
dbids
of the objects the user selected.
Use
axlSelect
when you create interactive commands that allow the user to select objects in the same way as existing Allegro PCB Editor interactive commands such as
move
or
delete
.
axlSelect
allows the user to select objects using the standard methods of mouse pick, window, and group. It returns when the user has selected one or more objects or picks
Done
or
Cancel
, depending on the pop-up selections you set up. The default mode for
axlSelect
is selecting a single object by point—equivalent to
axlSingleSelectPoint
.
axlSelect
removes any previously selected
dbids
in the selection set when the user first selects one or more objects.
You must set up the find filter to meet your requirements before calling
axlSelect
.
Arguments
firstEventCallback
Procedure to be called once the first user event occurs. The callback takes no arguments.
groupMode
Default is for
axlSelect
to return when the user makes a selection. If groupMode is
't
,
axlSelect
won’t return until you do an
axlCancelEnterFun
or
axlFinishEnterFun
. You perform all of your activity in popup callbacks instead of when
axlSelect
returns. In
groupMode
,
axlSelect
does not clear existing selections. To clear existing selections after the first event, clear them in your
firstEventCallback
.
prompt
Prompt to the user. The default prompt is:
"
Enter selection point
"
Value Returned
t
One or more object
dbids
put into the select set during the call. The select set is a list of the
dbids
of the objects the user selected.
nil
No object
dbids
put into the select set.
Example
(defun showElement ()
mypopup = axlUIPopupDefine( nil
(list (list "Done" 'axlFinishEnterFun)
(list "Cancel" 'axlCancelEnterFun)))
axlUIPopupSet( mypopup)
axlSetFindFilter( ?enabled list( "NOALL" "ALLTYPES" "NAMEFORM")
?onButtons "ALLTYPES")
while( axlSelect()
axlShowObject( axlGetSelSet()))
Function loops, performing the
Show Element
command on each object selected by the user.
Although you explicitly set
Done
and
Cancel
for this command, AXL also adds
Group
,
Window
Select
,
and
FindFilter
to the pop-up.
axlGetSelSet
axlGetSelSet()
⇒
lo_dbid
/nil
Description
Gets the list of object
dbids
in the select set.
Arguments
None.
Value Returned
lo_dbid
List of figure
dbids
.
nil
Select set is empty.
Example
axlClearSelSet()
axlSetFindFilter(?enabled list("noall" "vias")
?onButtons list("vias"))
axlAddSelectBox(list(3000:3100 3200:3600))
axlShowObject(axlGetSelSet())
⇒ t
Selects all vias in a box area and shows the contents of the select set.
The
Show Element
window is displayed, with the via selected.
axlGetSelSetCount
axlGetSelSetCount()
⇒
x_selCount
Description
Returns the number of figure
dbids
in the select set.
Arguments
None.
Value Returned
x_selCount
Number of objects selected. Returns
0
if nothing is selected.
Example
axlClearSelSet()
axlSetFindFilter(?enabled list("noall"))
axlSetFindFilter(?enabled list("pins")
?onButtons list("pins"))
axlAddSelectBox()
axlGetSelSetCount()
⇒ 14
Sets the Find Filter to find pins, selects a box around a 14 pin dip and prints the number of
dbids
in the select set. It is 14, as expected.
axlClearSelSet
axlClearSelSet()
⇒ t/nil
Description
Removes all
dbids
from select set.
Arguments
None.
Value Returned
t
One or more
dbids
removed in order to empty the select set.
nil
Select set already empty.
Example
axlClearSelSet()
axlSetFindFilter(?enabled list("noall"))
axlSetFindFilter(?enabled list("pins")
?onButtons list("pins"))
axlAddSelectBox()
axlGetSelSetCount()
⇒ 14
Ensures the select set does not have any leftover
dbids
in it, as in the example for
axlGetSelSetCount
.
axlGetFindFilter
axlGetFindFilter(
[
onEnabledF
]
)
⇒
lt_filters
/nil
Description
Returns the current Find Filter settings as a list
pf
keyword strings. The return find filters settings (onButton or enabled) is controlled by the boolean
onEnabledF.
Note that SKILL has its own local Find Filter settings. The axlGetFindFilter()/axlSetFindFilter() API is for getting and setting the local Find Filter settings. This does not get the global Find Filter settings, which can only be modified by the user. SKILL programs are not allowed to modify the global Find Filter settings.
Arguments
onEnabledF
If
onEnabledF
is
t
, returns the enabled list.
If
onEnabledF
is
nil
, returns the
onButton
list.
Default is nil.
Value Returned
lt_filters
List of element types in the Find Filter
OR
list of current onButton settings.
nil
If list would be empty.
Example
axlSetFindFilter ?enabled (list "vias" "pins" "nets" "clinesegs" "nameform") ?onButtons (list "vias" "pins" "clinesegs"))
ret =axlGetFindFilter()
Returns the following:
("NAMEFORM" "NETS" "CLINESEGS" "VIAS" "PINS"
<plus default items that may change from release to release> )
ret = axlGetFindFilter(t)
Returns:
("CLINESEGS" "VIAS" "PINS")
axlSetFindFilter
axlSetFindFilter(
?enabled
lt_enabled
?onButtons
lt_filterOn
)
t/nil
Description
Sets up both the object types to be displayed in the Find Filter, and which types among those are set to
on
in the
Find Filter
.
Note that SKILL has its own local Find Filter settings. The axlGetFindFilter()/axlSetFindFilter() API is for getting and setting the local Find Filter settings. This does not get the global Find Filter settings, which can only be modified by the user. SKILL programs are not allowed to modify the global Find Filter settings.
The first argument,
lt_enabled
, is a list of the object types to be displayed in the Find Filter and of the select options described. The second argument,
lt_onButons
, lists the object types whose buttons are to be
on
(and therefore selectable) when the filter displays. The table lists the keywords that can be included in the enabled and
onButtons
lists for setting up the Find Filter. The diagrams show the keywords and the buttons they cause
axlSetFindFilter
to display.
Each change is additive and processed in the order that they appear in the list. For example, you type the following to enable all object types except for pins.
'("ALLTYPES" "NOPINS")
Each of the following keywords may be preceded with a
"NO"
to disable the particular option or object type. For example,
"NOPINS"
. The initial default is
"NOALL"
.
axlSetFindFilter
Keywords
Keyword
Description
"PINS"
Enable pins
"VIAS"
Enable vias
"CLINES"
Enable clines
"CLINESEGS"
Enable cline (arc or line) segs
"LINES"
Enable lines
"LINESEGS"
Enable line (arc or line) segs
"DRCS"
Enable DRC errors
"TEXT"
Enable text
"SHAPES"
Enable shapes, rects and frects
"SHAPESEGS"
Enable shape segments
"BOUNDARY_SHAPES"
Enable promotion to boundary shape if auto-shape is selected (see dynamic shape discussion)
"VOIDS"
Enable shape voids
"VOIDSEGS"
Enable shape void segments
"SYMBOLS"
Enable symbol instances
"FIGURES"
Enable figures
"COMPONENTS"
Enable component instances
"FUNCTIONS"
Enable function instances
"NETS"
Enable nets
"BONDWIRES"
Enable bondwires (APD/SIP only).
For more information, see
Bond Objects
.
"FINGERS"
Enable fingers (APD/SIP only).
For more information, see
Bond Objects
.
"GROUPS"
"GROUPMEMBERS"
"GROUPS"
and
"GROUPMEMBERS"
operate together to produce four possible selection states:
State 1: Legacy.
This supports code that predates the group implementation. This is the same as State 3.
State 2: Group only.
By only setting the group bitfield, any selected group is returned to the application as a group.
State 3: Members only.
By only setting the group_members bitfield, group members are returned to the application when a group is selected.
State 4: Hierarchical.
By setting both the group and group_members bitfields, a group is returned for any hierarchical group that is selected (such as a Module instance), and group members are returned for all other selected group types.
"AUTOFORM"
OBSOLETE
"EQUIVLOGIC"
Option - For logic object types (nets and components), causes the physical equivalent to be selected. Physical objects must be enabled in both "enabled" an "onButton" lists.
"INVISIBLE"
Option - Allows selection of objects that are not visible due to color class/subclass form setting.
"NAMEFORM"
Option - enables the find by name/property fields in the find filter form.
"DYNTHEMALS"
Option - Enable selection of thermal reliefs generated by dynamic shapes. Only applicable to ?enabled. By default, you should not select these if you plan on modifying the objects since the dynamic shape will just re-generate them. You should only access them from read-only purposes.
If in the partition editor or the design has partitions active then this option is used to selections of read-only objects.
This option should also be used to select shape base fillets. The system will not allow shape based fillets to be modified it the dynamic fillet option is enabled.
"BONDSMART"
Option - Application has been updated to differentiate bond wires and/or fingers (APD/SIP).
For more information, see
Bond Objects
.
"ALLTYPES"
Enable all object types ("PINS" ... "NETS").
"ALL"
Enable all object types and options.
axlSetFindFilter
processes the keywords in each argument list in order and only makes the changes occurring in the list. Changes are incremental for each call to the function. To remove a selection, attach the string
“NO”
to the front of the keyword. For example, the list
("ALLTYPES" "NOPINS")
enables all object types except pins. The initial default setting of the Find Filter is
"NOALL"
,
or, nothing enabled. Use
"NOALL"
, as shown, to clear the
Find Filter before enabling particular types.
Dynamic Shapes
When writing an application and it needs to handle shapes, you need to decide how you want to handle dynamic shapes. Additional information is useful only if your SKILL program   access shapes.
A shape on
ETCH
may be either static or dynamic. A static shape is similar to what existed in Allegro PCB Editor prior to SPB15.0. You add a shape to an etch layer and manually void objects that impact the shape. A dynamic shape is placed on the
BOUNDARY CLASS
and generates zero or more shapes on the
ETCH
layer based upon auto-voiding.
If you want to modify a dynamic shape, then you should set
BOUNDARY_SHAPES
. This allows the user to select the generated shape, but selection will return its dynamic shape (for example, to move
the shape). If you want to access information on the shape, then do not set the
BOUNDARY_SHAPES
option (for example, to do show element on the shape).
If you pass
"ALL"
or
"ALLTYPES"
to
setOptions
, then
BOUNDARY_SHAPES
will be enabled and user’s selecting a
ETCH
layer generated shape will result in the selection returning its dynamic shape on the
"BOUNDARY CLASS"
. If you wish to select the generated shape, but want to use the
all
option, use "
(ALLTYPES" "NOBOUNDARY_SHAPES".
You need only pass
BOUNDARY_SHAPES
to the enabled list. It will be ignored if passed to the
onButtons
list.
Figure 4-1
Find Filter and Related Keywords
The differences in effects of different combinations of keywords can be subtle.
Figure 4-2
shows the relationship between the keywords.
Figure 4-2
Relationship Among axlSetFindFilter Keywords (
See examples also
)
Bond Objects
Bond objects (bond wires and fingers) are enabled only in APD/SIP. These options are ignored in the PCB products.
In APD/SIP, to maintain backward compatibility, an application is not considered to be "bond smart". This means if the SKILL application enables VIAs then FINGERS are enabled and if CLINES is enabled, the BOND WIRES are automatically enabled.
To make an application bond smart, you either set the BONDSMART option or use the BONDWIRES, NOBONDWIRES, FINGERS or NOFINGERS options. An application that is bond smart can separately control the selection of bond objects (fingers or bond wires) from their base objects (vias or clines).
You only need to make you SKILL application bond smart if you wish to differentiate the disabling of one of these objects. By default, users in APD/SIP will be able to independently select: VIAS or FINGERS if the SKILL application enables VIAS or CLINES and WIRES if CLINES are enabled. Ideally most applications will not need to be updated to be bond smart.
Arguments
lt_enabled
List of keyword strings that describe object types that are to be selectable. Enabled object types will appear in the
Find Filter
form. Object types need the
onButton
set as well to fully enable selection. List may also include selection options.
Also supports a single keyword string instead of a list of strings.
lt_onButtons
List of keyword strings that describe object types that are to be enabled for selection. Enabled types will appear with the
onButton
depressed in the Find Filter form.
onButton
settings provide the default for controls which can be modified by the user when the Find Filter form is opened. An object type must be
on
in both the enabled and the
onButton
lists to be fully enabled for selection. Options are ignored when provided in the
onButton
list.
Also supports a single keyword string instead of a list of strings.
axlSetFindFilter
does not display or select any types that are not enabled. That means that
?onButtons
keywords only effect enabled types. For example, to have all enabled buttons be
on
, use
?onButtons list("alltypes")
. In general, you need only set specific buttons
on
if you want those on and others off.
Value Returned
t
One or more Find Filter changes were made.
nil
No valid keywords were provided.
Application Programming Note
When you use
axlSetFindFilter()
to implement an interactive command, make your
AXL-SKILL program restore the user’s FindFilter settings from the previous time he same command was used. Find Filter settings are incremental. Clear any previous settings as you start, then set the ones you want. Call
axlSetFindFilter
with
"noall"
as the first member of the list for both the
?enabled
and
?onButtons
arguments the first time you call it.
To maintain the user’s Find Filter settings between invocations of your command
The first time the user invokes your program (when it loads), preset global variables to the list of
?enabled
and
?onButtons
settings you want as the initial default, as follows:
myglobal_enabled = list("noall" "xxx" "yyy" ... "zzz")
myglobal_onButtons = list("xxx" ..."zzz")
Each time the user invokes your command, call
axlSetFindFilter
with the current global values of
?enabled
and
?onButtons
.
axlGetFindfilter( ?enabled myglobal_enabled
?onButtons myglobal_onButtons)
Since users can set or clear any of the buttons on the Find Filter, you need to save the button settings as you exit the command.
As you end the command, save the user’s Find Filter
onButton
settings as shown:
myglobal_onButtons = cons( "noall" axlGetFindFilter(t))
The
cons - "noall"
ensures that when you call
axlSetFindFilter
again you clear any settings left over from any previous command, and set only the buttons set at the time you call
axlGetFindFilter
.
Example 1
(axlSetFindFilter ?enabled (list "vias" "pins" "nets")
?onButtons (list "vias" "pins"))
Displays the Find Filter with a list of Nets, Pins, and Vias. The Pins and Vias boxes are turned on as shown:
Example 2
(axlSetFindFilter ?enabled (list "noall" "vias" "pins"
"nets" "clinesegs" "nameform")
?onButtons (list "vias" "pins" "clinesegs"))
Displays the Find Filter with Pins, Vias, and Cline segs turned on.
Example 3
axlSetFindFilter(
?enabled list("noall" "equivlogic" "nets" "pins" "vias")
?onButtons list("all"))
Sets to find all the pins and vias on a net when the user selects any part of the net.
axlAutoOpenFindFilter
axlAutoOpenFindFilter()
⇒ t
Description
This function is no longer required, but is kept for backward compatibility.
Arguments
None.
Value Returned
t
Returns
t
always.
axlOpenFindFilter
axlOpenFindFilter()
⇒ t
Description
This function is no longer required, but is kept for backward compatibility.
Arguments
None.
Value Returned
t
Returns
t
always.
axlCloseFindFilter
axlCloseFindFilter()
⇒ t
Description
This function is no longer required, but is kept for backward compatibility.
Arguments
None.
Value Returned
t
Returns
t
always.
axlDBFindByName
axlDBFindByName(
s_type
t_name
) ⇒ o_dbid/nil
Description
Finds
dbid
of an object by name without involving the selection set. This means you can run this command any time without affecting what exists in the selection set. The following object lookup types are supported:
type
t_name
return type
'net
net name
dbid
of a net
'refdes
refdes
dbid
of a component instance
'padstack
padstack name
dbid
of a padstack
This is restricted to a single object. To find objects using wildcards, use
axlSelectByName
.
Arguments
s_type
Type symbol; see above.
t_name
Object's name (this is case insensitive).
Value Returned
o_dbid
dbid
of object or
nil.
```

**另见**：

axlSelectByName
Examples
db = axlDBFindByName('net "GND")
db = axlDBFindByName('padstack "VIA")
db = axlDBFindByName('refdes "U1")
### axlFindFilterIsOpen

**说明**：此函数不再需要，但为向后兼容而保留。

**语法**：
```skill
axlFindFilterIsOpen
axlFindFilterIsOpen()
⇒ t
```

**Original**: Description

```
This function is no longer required, but is kept for backward compatibility.
```

**参数**：

None.

**返回值**：

t
Returns
t
always.
axlSelectByName
axlSelectByName (
t_objectType
t_name
/
lt_name
[g_wildcard]
)
⇒
lo_dbid
/nil
Description
Selects database objects by name.
Interface allows more than one name to be passed, but only one object type per call. For certain object types, a single name may return multiple objects. The supported object types and related items follow:
Object Type
Item the function finds
"NET"
net name
"COMPONENT"
component name
"FUNCTION"
function name
"DEVTYPE"
device type name
"SYMTYPE"
symbol type name
"PIN"
refdes.pinname
"REFDES"
find symbol by refdes name
"COMPREFDES"
find component by refdes name
"GROUP"
find group by name
"BUS"
find bus by name
"DIFF_PAIR"
find differential pair by name
"NETCLASS"
find netclass by name
"NET_GROUP"
find a net group by name
"REGION"
find region by name
"XNET"
find xnet by name; Will return a Net if xnet is a single net xnet. See
<cdsroot>/share/pcb/examples/skill/select/ashfindxnet.il
"MATCH_GROUP"
find match group by name
"MODULE"
find module by name
You can use wildcards with this function:
“*”
matches any sequence of zero or more characters.
“?”
matches any single character.
“\”
is used to send a special character, for example,
\x
.
Provided third argument
[g_wildcard]
is set to
TRUE
.
This saves and restores the current find filter settings, but resets the selection set.
Arguments
t_objectType
Type of database name.
t_name
Object to find.
lt_name
List of names to find.
[g_wildcard]
If
*
or
?
appear in name, use regular expression matching
Value Returned
t
List of objects found.
nil
No matching name or illegal
objectType
name.
Example 1
Skill > p = axlSelectByName("NET" '("GND" "NET1"))
(dbid:28622576 dbid:28639844)
Finds two nets.
Example 2
Skill > p = axlSelectByName("NET" '("GND" "FOO"))
(dbid:28622576)
Finds two nets, but board only has
GND
.
Example 3
Skill > p = axlSelectByName("COMPONENT" "C1")
(dbid:28590388)
Skill > car(p)->objType
"component"
Finds Component
C1
.
Example 4
Skill > p = axlSelectByName("FUNCTION" "TF-326")
(dbid:28661572)
Skill > car(p)->objType
"function"
Finds function
TF-326.
Example 5
Skill > p = axlSelectByName("DEVTYPE" "CAP1")
(dbid:28591032 dbid:28590700 dbid:28590388)
Skill > car(p)->objType
"component"
Finds devices of type
CAP1
.
Example 6
Skill > p = axlSelectByName("SYMTYPE" "dip14_3")
(dbid:28688416 dbid:28686192)
Skill > car(p)->objType
"symbol"
Finds symbols of type
DIP14_3
.
Example 7
Skill > p = axlSelectByName("PIN" "U1.1")
(dbid:28630692)
Skill > car(p)->objType
"pin"
Finds pin
U2.1
.
Example 8
Skill > p = axlSelectByName("REFDES" "U3")
(dbid:28688416)
Skill > car(p)->objType
"symbol"
Finds symbol by refdes
U3
.
Example 9
Skill > p = axlSelectByName(“COMPREFDES” “U3”)
(dbid:28621208)
Skill > car(p)->objType
“component”
Finds component by refdes
U3
.
Example 10
Skill > p = axlSelectByName("GROUP" "BAR")
(dbid:28593776)
Skill > car(p)->objType
Finds a group
BAR
by name.
Example 11
Skill > p = axlSelectByName("PIN" "U1.*" t)
(dbid:28630856 dbid:28630784 dbid:28630692 dbid:28630572 dbid:28630400 dbid:28630228 dbid:28630076 dbid:28630004 dbid:28629912 dbid:28629800 dbid:28629728 dbid:28629656 dbid:28629484 dbid:28629372 dbid:28629280 dbid:28629208
)
Finds all pins on
refdes U1
.
Example 12
Skill > p = axlSelectByName("PIN" "U1.?" t)
(dbid:28630856 dbid:28630692 dbid:28630572 dbid:28630400 dbid:28630228 dbid:28630076 dbid:28630004 dbid:28629912 dbid:28629800
)
Finds pins with single digit number on
U1
.
Example 13
Skill >  p = axlSelectByName("NET" "N*" t)
(dbid:28630044 dbid:28634000 dbid:28638750)
Finds nets starting with
N
.
axlSelectByProperty
axlSelectByProperty(
t_objectType
t_property
[
t_value
]
[
g_regularExpression
]
)
⇒
lo_dbid
/nil
Description
Selects the
dbid
set of a particular Allegro PCB Editor database object with the indicated property.
Property can be a name or a name/value pair. Value may contain a regular expression (
*
or
?
), since certain select by name functions support wildcards. You can test for the presence of wildcards before you call this function.
Regular expressions used by Allegro PCB Editor differ from the SKILL regular expressions. Allegro PCB Editor handles regular expressions such that they are more compatible with the character set allowed in Allegro PCB Editor object names. Do not use this function to test patterns sent to the SKILL
regexp
family of functions.
For value, match the database formats into the value string to contain the units preference if applicable for the property. If the data type of the attribute is BOOLEAN, and if it exists on the element, the string is empty. If the data type is
INTEGER
or
REAL
, the user units string, if any, is appended to the value. If the data type is one of the
"units category"
types, for example,
ALTITUDE
,
PROP_DELAY
, the MKS package converts the value.
Properties must be upper case. The value is case insensitive if wildmatch match is
nil
while case sensitive for wildcard matching.
Property names may change from release to release, or may be rendered obsolete. SKILL programs using property names may require modifications in future releases.
Arguments
t_objectType
String for Allegro PCB Editor database object type. Must be:
compdef
,
component
,
drc
,
net
,
symdef
,
symbol
, or
group
.
t_property
Name of property.
t_value
Optional property value.
g_regularExpression
t
if property value is to be treated as a regular expression, or
nil
, which is the default, to treat property value as a simple match.
Value Returned
t
One or more
dbids
added to the select set.
nil
No
dbids
added to the select set.
Example 1
p = axlSelectByProperty("net" "ELECTRICAL_CONSTRAINT_SET")
axlAddSelectObject(p)
Selects all nets with an
ECset
property, then adds them to the current select set.
Example 2
p = axlSelectByProperty("net" "ELECTRICAL_CONSTRAINT_SET", "SPITFIRE_ADDRESS")
Selects all nets with ECset property of value
SPITFIRE_ADDRESS
.
Example 3
p = axlSelectByProperty("net" "ELECTRICAL_CONSTRAINT_SET", "SPITFIRE*" t)
Selects all nets with ECset property with any value matching
spitfire
.
axlSnapDisableAtRMB
axlSnapDisableAtRMB(
)
⇒ t
Description
Disable the display of "snap to" submenu at right-click popup.
Use in conjunction with
axlSnapEnableAtRMB
to remove the "Snap To" from the right-click popup.
Arguments
None

**另见**：

axlSnapEnableAtRMB
Value Returned
t
Always returns
t
### axlSnapEnableAtRMB

**说明**：启用右键弹出菜单中 "snap to" 子菜单的显示。用于启用右键弹出菜单中 "snap to" 子菜单的显示。此函数应与 axlSnapDisableAtRMB 配合使用，以实现交互式命令的所有弹出菜单中都可用的 "snap to" 子菜单。要在执行期间的特定步骤启用或禁用 "snap to" 子菜单，可以将此函数与 axlSnapDisableAtRMB 配合使用。这是所有带有右键的 axlEvent API 的默认模式。

**语法**：
```skill
axlSnapEnableAtRMB
axlSnapEnableAtRMB(
)
⇒ t
```

**Original**: Description

```
Enable the display of "snap to" submenu at right mouse button popup.
It is used to enable the display of "snap to" submenu at right-click popup. The function should be used with
axlSnapDisableAtRMB
to achieve "snap to" submenu which is available with all the popups of an interactive command. To enable or disable "snap to" submenu at particular steps during execution, this function can be used with axlSnapDisableAtRMB.
This is the default mode with all axlEvent APIs with a right mouse button.
```

**参数**：

None.

**返回值**：

t
Always returns
t

**另见**：

axlSnapDisableAtRMB
, axlEnterEvent
Example
See
<cdsroot>/share/pcb/examples/axlcore/enterevent.il
### axlSnapToObject

**说明**：支持吸附到逻辑对象的连接点。逻辑对象包括：Cline、Cline 段（线段或圆弧）、Via、Pin。对于 cline 对象，两个端点被视为连接点。对于焊盘对象，连接点在焊盘栈中定义。吸附基于陷阱大小，该大小根据缩放因子而变化。如果未找到对象，则返回原始 xy 位置。

**语法**：
```skill
axlSnapToObject
axlSnapToObject(
g_mode
xy
)
⇒ xy/nil
```

**Original**: Description

```
Supports snapping to a logic object’s connect point. A logic object is a:
Cline
Clines segments (lines or arcs)
Via
Pin
For cline objects, the two end points are considered the connect points. For pad objects, the connect point is defined in the padstack. Snapping is based upon the trap size, which varies based upon the zoom factor (see
axlGetTrapBox
). The smaller the trap size, the higher the zoom. If no object is found within the original xy location is returned.
Avoid using the grid snapping option with
axlEnterPoint
as it might move the user pick outside the trap size.
```

**参数**：

g_mode
nil
: Use active sel set to determine snapping.
t
: Snap based upon the visible layers in the database.
xy
Location in design units to snap (list of design units x:y).

**返回值**：

xy
Object snapped point (list of design units x:y).
nil
If not object exists for snapping returns nil.
Also nil if arguments are incorrect

**另见**：

axlGetSelSet
,
axlGetTrapBox
,
axlGetLastEnterPoint
Examples
Pseudo code to move objects.
; select object(s); do not do a axlClearSelSet
_clpSelect
; first snap to an object that is the selection list
gridSnap = axlEnterPoint(?prompts list("Pick origin point")
? gridSnap t)
; for better results use the unsnapped pick
origin = axlSnapToObject(nil axlLastPick(nil))
; if no object found fallback to the grid snapped pick
unless( origin origin = gridSnap)
; ok to do clear now
### axlClearSelSet

**说明**：从选择集中移除所有 dbid。

**语法**：
```skill
axlClearSelSet()
; now ask user for a destination
gridSnap = axlEnterPoint(?prompts list("Pick origin point")
? gridSnap t)
; Now snap the destination point based upon what can be found at that
; location
; for better results use the unsnapped pick
dest = axlSnapToObject(nil axlLastPick(nil))
; fallback to grid snapped location if nothing found
unless( origin dest = gridSnap)
; modify coordinates  with dest location
axlTransformObject(....)
axlLastPickIsSnapped
axlLastPickIsSnapped()
-> t/nil
```

**Original**: Description

```
Normally called after an
axlEnter
call to determine if the pick was snapped or unsnapped.
```

**参数**：

none

**返回值**：

t
if last picked was snapped,
nil
if unsnapped

**示例**：

```skill
snappedPoint = axlEnterPoint(?prompts list("Pick origin point")
?gridSnap t)
state = axlLastPickIsSnapped()
Return to top
⠀
X
```
