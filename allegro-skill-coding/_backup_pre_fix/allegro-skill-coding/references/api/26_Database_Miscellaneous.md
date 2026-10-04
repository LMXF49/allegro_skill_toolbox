# 26. 数据库杂项 (Database Miscellaneous)

## 概述 (Overview)

本章描述不属于其他章节的 AXL-SKILL 函数。

### axlAirGap

**说明**：查找两个给定对象之间的空气间隙（Air Gap）和位置。间隙值与 `show measure` 命令报告的结果相同。支持任何几何对象；不支持逻辑对象、组或符号（与 `show measure` 相同）。未填充的 Shape 当前被视为填充的，但未来可能改变。

仅在测量两个引脚（Pin）或过孔（Via）之间的间距（也称为焊盘比较）时才需要提供层选项。如果不提供层进行焊盘比较，则使用当前活动层。层语法应为 `"ETCH/<subclass>"` 或 `"<subclass>"`。

对于到特殊 Via 或 Pin 子类的间距，请提供 `"PIN"` 或 `"VIA CLASS"` 作为类名。

这两个类名对 Pin 和 Via 同样有效。如果要获取 Pin 和 Via 之间的阻焊层顶层间距，请使用 `"PIN/SOLDERMASK_TOP"`。

第二个参数可以是位置（以设计单位）。间隙报告从第一个对象到此位置的最小距离。在增强模式下，该位置被报告为 `"ETCH/TOP"` 层。

根据 `s_mode` 选项，输出数据以以下格式之一返回：

默认模式 `s_mode`（`s_mode==nil`）返回 `l_airGapData`，如果有错误则返回 `nil`。如果 `s_mode` 为 `t`，则数据返回为 `(s_error l_airGapData)`，其中 `s_error` 为以下之一：`t`（成功）、`'NOMATCH`（无子类匹配）、`'RANGE`（范围错误）或 `'INVALID`（无效参数）。

增强输出 `s_mode = 'enhanced` 提供 anyLayer 空气间隙，并返回一个无实体属性列表（disembodied property list），包含 airGap、location1、location2、layer1、layer2 和 isEtch 等属性。

对于两个焊盘之间的距离，如果 `t_layer` 为 `nil`，则根据活动蚀刻子类返回间隙。否则使用 `t_layer` 确定间隙。如果一个或两个焊盘在该层上不存在，在 anyLayer 模式下返回最近焊盘层之间的距离，在 `s_mode=nil` 或 `s_mode=t` 时为错误。

对于焊盘和非焊盘元素之间的距离，如果不提供层，则使用焊盘所在层或焊盘堆叠（Padstack）的顶层。如果性能是一个问题，请使用 `anyLayer` 模式而不是增强输出。如果对象不在同一层，距离不考虑板厚度。

**Original**: Finds the air gap and location between two given items. Gap is the same as reported by the
show measure
command. Any geometric objects; logical, group or symbols are not supported (same as show measure). Unfilled shapes are currently treated as filled but this may change in the future.
You only need to provide a layer option when measuring between to pin or vias (also called pad comparison). When doing pad comparison without the layer,   the current active layer is used. The layer syntax should either be "ETCH/<subclass>" or "<subclass>".
For spacing to the special via or pin subclasses below, either provide "PIN or "VIA CLASS" as the class name.
SOLDERMASK_TOP
SOLDERMASK_BOTTOM
PASTEMASK_TOP
PASTEMASK_BOTTOM
FILMMASKTOP
FILMMASKBOTTOM
Both of these class names work equally well with pins and vias. If you want the soldermask top spacing between a pin and via, then use "PIN/SOLDERMASK_TOP".
The second argument may be a location (in design units). Gap reports the minimum distance from the first object to this location. In enhanced mode, the location is reported as the "ETCH/TOP" layer.
Output data is returned in one of the following formats depending on the
s_mode
option:
Default is
s_mode (s_mode==nil)
returns the
l_airGapData
or a
nil
if there is an error. If
s_mode
is
t
then data is returned as
(s_error l_airGapData)
where
s_error
is one of the following:
t
Success (t (l_airGapData))
'NOMATCH
No subclass matches between pin or via and object. Returns object's layer. (
NOMATCH (t_layer)
)
'RANGE
No subclass match between two etch elements (one or both must be a pad element (pin or via). If common layers exist, Allegro PCB Editor returns the top and bottom layer where matches exist otherwise returns
nil
: (
ETCH (t_topMatch t_bottomMatch)
)
'INVALID
One or both elements are invalid. Data return format: (
INVALID nil
).
Enhanced out,
s_mode = 'enhanced
offers anyLayer air gap and returns a disembodied property list of:
airGap = <spacing between objects> (floating point)
location1 = xy location first item where air gap measured
location2 = xy location of second item where air gap measured
layer1 = layer (class subclass) of where first object measured (string)
layer2 = layer (class subclass) of where second object measured (string)
isEtch = both objects of type ETCH (boolean)
For distance between two pads, return gap based upon the active etch subclass, if
t_layer
is
nil
. Otherwise use
t_layer
to determine gap. If one or both pads do not exist on that layer:
in anyLayer mode we will return the distance between the closest pad layers.
it is an error in s_mode=nil or s_mode=t
For distance between a pad and non-pad element; use the layer of the pad that you want the measurement if layer is not provided we use the active layer or the top layer of the padstack.
If performance is a concern, use
anyLayer
mode over enhanced output.
The distance if objects do not share the same layer do NOT take into account board thickness.
For legacy purposes, this interface does not return an air gap if the two objects do not share the same layer. If you want the air gap any layer use
s_mode = 'anyLayer
or
s_mode ='enhanced
.

**参数** (Arguments)：

o_item1DBID
dbid
- **of** — the first item.
o_item2DBID
dbid
- **of** — the second item.
l_xy
- **The** — second item can be a xy location in design units and must be in the design extents.
t_layer
- **Optional** — layer used to resolve gap comparison between two pin or via elements.
- **If** — in 'anyLayer or 'enhanced mode this targets a particular layer for comparison. It is most useful in measuring mask layer gaps.
s_mode
- **Return** — additional info to clarify error. This may be:
nil:
- **Default** — mode (objects must be on the same layer)
t
:
("full mode")
return
l_airGapData
- **or** — if not share see above (objects must be on the same layer)
anyLayer
: support any layer measure return just gap
enhanced
: return disembodied property list of additional air gap criteria (see above)

**返回值** (Value Returned)：

l_airGapData
List containing the following items:
(l_airGapPt1 l_airGapPt2 f_airGapDistance)
where
l_airGapPt1:
(X,Y) point on the 1
st
item where the gap is measured.
l_airGapPt2
: (X,Y) point on the 2
nd
item where the gap is measured.
f_airGapDistance:
Distance between the two points.
nil
Input data error; element 1 and 2 are the same or no air gap can be computed between the two items. If
t_layer
is used but does not specify an etch layer.
s_error
See error symbols listed above.

**示例** (Examples)：

Basic input
axlAirGap(el1 el2)
-> ((1337.5 1100.0) (1362.5 1100.0) 25.0)
Basic input layer
axlAirGap(el1 el2 "TOP")
-> ((1337.5 1100.0) (1362.5 1100.0) 25.0)
Full output success
axlAirGap(el1 el2 nil t)
-> (t ((1337.5 1100.0) (1362.5 1100.0) 25.0))
Any layer airgap
q = axlAirGap(el1 el2 nil 'anyLayer)
Enhanced output
q = axlAirGap(el1 el2 nil 'enhanced)
Obtain soldermask spacing
axlAirGap(el1 el2 ""PIN/SOLDERMASK_TOP" )
-> (((1337.5 1100.0) (1362.5 1100.0) 40.0))
Obtain spacing to design origin
q = axlAirGap(el1 0:0 nil 'enhanced)
Full output failure
axlAirGap(el3 el2 nil t)
-> (RANGE ("TOP" "GND"))
axlBackDrill – Obsolete
This interface is obsolete. Use
axlBackdrillGet
to retrieve actual backdrilling of pins and vias. Data returned by this interface may not match the actual backdrill results in the design.

### axlDBGetLength

**说明**：计算给定对象的长度，对象可以是 NET、CLINE、SEGMENT 或 RATSNEST。如果是 RATSNEST，返回曼哈顿长度。如果网络部分布线，包含所有鼠线曼哈顿长度之和。当前计算不包括 VIA-Z 或 PIN_DELAY。

**Original**: Calculates the length of the given object which may be a NET, CLINE, SEGMENT, or RATSNEST. If RATSNEST returns the Manhattan length. If a net is partially routed, includes sum of all ratsnest Manhattan lengths.
Currently does not include VIA-Z or PIN_DELAY in its calculation.

**参数** (Arguments)：

o_dbid
dbid

**返回值** (Value Returned)：

nil
Not a legal object
f_etchLength
Length of object

**示例** (Examples)：

Skill> p = ashOne()
Skill> axlDBGetLength(p)
-> 2676.777

**参见** (See Also)：

axlDBGetManhattan
,
axlDBPinPairLength

### axlDBGetManhattan

**说明**：给定一个网络，计算蚀刻（Etch）、路径（Path）和曼哈顿（Manhattan）长度。结果与列表元素使用的相同。

Etch — 当前蚀刻长度。没有蚀刻时长度为 0。
Path — 蚀刻加剩余长度。当网络完全连接时，没有剩余长度，路径等于蚀刻。
Manhattan — 估计布线长度。当网络没有蚀刻时，路径等于曼哈顿。

**Original**: Given a net, calculates an etch, path, and Manhattan length. The result is the same as that used by list element.
Etch - The current length of etch. The length is 0 when there is no etch.
Path - The etch plus remaining length. When the net is fully connected, there is no remaining, and path is equal to etch.
Manhattan - The estimated routing length.
Path is equal to Manhattan when the net has no etch.

**参数** (Arguments)：

o_dbid
Net
dbid
.

**返回值** (Value Returned)：

l_result
(
etchLength path manhattan
)
nil
Not a net
dbid
.
Net is out of date.
No ratsnest.

**示例** (Examples)：

p = ashOne()
axlDBGetManhattan(p)
(2676.777 3300.0)

**参见** (See Also)：

axlDBGetLength

### axlDBGetSymbolBodyExtent

**说明**：返回符号的主体范围（Body Extent）。与 dbid 关联的 bBox 不同，主体范围是以下之一：

- 由 PACKAGE_GEOMETRY（PLACE_BOUND_TOP、PLACE_BOUND_BOTTOM、DFA_BOUND_TOP、DFA_BOUND_BOTTOM）和 EMBEDDED_GEOMETRY（PLACE_BOUND 和 DFA_BOUND）层上所有 Shape 的并集创建的范围框。
- 符号的 bBox，即符号中所有项目的并集。

符号实例的范围框基于设计原点，而 symdef 框基于符号原点。

**Original**: This returns the body extent of a symbol. Unlike the bBox associated with a dbid, a body extents is either one of the following.
the extent box created by the union of all shapes on layers PACKAGE_GEOMETRY (PLACE_BOUND_TOP, PLACE_BOUND_BOTTOM, DFA_BOUND_TOP, DFA_BOUND_BOTTOM) and EMBEDDED_GEOMETRY (PLACE_BOUND and DFA_BOUND)
the symbol bbox, a union of all items in symbol
The symbol instance extent box is based upon the design origin while the symdef box is based upon the symbol origin.

**参数** (Arguments)：

o_dbid
- **A** — symbol instance or definition

**返回值** (Value Returned)：

bBox
body box of symbol
(minX:minY maxX:maxY)
nil
dbid is not a symbol instance (symbol) or definition (symdef)

**参见** (See Also)：

axlDBAltOrigin

### axlDBPinPairLength

**说明**：计算两个引脚之间的最短长度。引脚必须在同一个 xnet 上。引脚也可以是 VIA 或 RAT_T。如果距离未完全布线，则包含未布线部分的曼哈顿估计。如果启用了这些选项并且许可证允许，计算中包括 VIA-Z 或 PIN_DELAY。

**Original**: Calculate the shortest length between 2 pins. Pins must be on the same xnet. The pin can also be a VIA or RAT_T. If the distance is not fully routed, it includes a Manhattan estimate of the unrouted portion.
Includes VIA-Z or PIN_DELAY in its calculation if these options are enabled and if your license permits this capability.

**参数** (Arguments)：

o_pin1
- **A** — pin, via or rat_t
o_pin2
- **A** — pin, via or rat_t on same xnet as o_pin1

**返回值** (Value Returned)：

nil
– Not a legal object; unsupported dbid or items not on same xnet
f_etchLength
– length of object

**示例** (Examples)：

Skill> pin1 = ashOne()
Skill> pin2 = ashOne()
Skill> axlDBPinPairLength(pin1 pin2)
-> 2676.777

**参见** (See Also)：

axlDBGetLength

### axlDeleteByLayer

**说明**：删除一个或多个提供层上的所有数据。注意以下几点：

- 不删除引脚或过孔。
- 删除与符号关联的引脚逃逸和其他符号数据。
- 不删除符号定义上的对象。如果将此接口用作删除层的前提条件，符号定义上的对象可能会阻止您删除该层。
- 要删除动态 Shape，还需要删除等效 BOUNDARY 类上的数据。
- 某些类（如 DRC_ERROR_CLASS、PIN、VIA_CLASS、ROUTER_PLAN 和 CAVITY）将被忽略。

**Original**: Deletes all data on one or more provided layers. The following should be noted:
Does not delete pins or vias.
Deletes pins escapes and other symbol data associated with symbols.
Does not delete objects on a symbol definition. If you are using this interface as a prerequisite to deleting a layer, objects on a symbol definition may prevent you from deleting the layer.
To delete dynamic shapes, you also need to delete data on the equivalent BOUNDARY class.
Certain classes, such as, DRC_ERROR_CLASS, PIN, VIA_CLASS, ROUTER_PLAN and CAVITY, are ignored.

**参数** (Arguments)：

t_layerName
- **layer** — name <class>/<subclass>
lt_layerName
- **list** — of layer names
'fixed
Optional, ignore FIXED property

**返回值** (Value Returned)：

x_cnt
number of items deleted
nil
any error

**示例** (Examples)：

Delete all data on ETCH/TOP except for fixed data
axlDeleteByLayer("ETCH/TOP")
Delete all data on ETCH/BOTTOM plus OUTLINE layers including fixed
axlDeleteByLayer(list("ETCH/TOP" "BOARD GEOMETRY/OUTLINE") 'fixed)

### axlExtentDB

**说明**：确定设计类型并返回 bBox 范围。

对于布局，此函数计算布局范围并返回用于窗口适配的最小边界框。仅在以下顺序的选定层上搜索 line、lineseg 和 shape：BOARD GEOMETRY/OUTLINE、PACKAGE KEEPIN/ALL、ROUTE KEEPIN/ALL。使用第一个具有任何元素的层来确定布局范围。如果这些层上未找到元素，则返回设计范围。

对于符号图纸（.dra 文件），此函数计算图纸中所有可见对象的边界框。

**Original**: Determines a design type and returns the
bBox
extent.
For a layout this function computes the layout extents and returns the smallest bounding box to be used for window-fit. Only
lines
,
linesegs
, and
shapes
are searched on selected layers in the following order:
BOARD GEOMETRY/OUTLINE
PACKAGE KEEPIN/ALL
ROUTE KEEPIN/ALL
The first layer with any elements is used to determine the layout extents. If no elements are found on these layers, the design extents are returned.
For a symbol drawing (a
.dra
file), this function computes the bounding box enclosing all objects visible for a drawing.

**参数** (Arguments)：

None
- **Valued** — Returned
l_bBox
Returns
bBox
extent.
nil
- **Unknown** — drawing type.
- **axlExtentLayout** — – Obsolete
- **This** — function is obsolete. Use
axlExtentDB
. Kept for backward compatibility.
- **axlExtentSymbol** — – Obsolete
- **This** — function is obsolete. Use
axlExtentDB
. Kept for backward compatibility.

### axlFindPath

**说明**：查找从一个对象到另一个对象的蚀刻路径。项目必须在同一网络上，且必须是连接类型，如引脚、过孔、cline 或 shape 以及 tee。

限制：
- 两个对象之间的部分连接（仍存在鼠线）导致返回 `nil`。
- 线段被提升为其拥有的 cline（路径）。
- 返回列表按以下顺序排列：o_oneDbid, ... <connected items>, o_twoDbid
- 要使用此功能查找网络上的环路，必须将每个节点与每个其他节点进行比较。对于引脚数多的大型网络，这可能非常耗时。
- 如果两个对象之间存在多条路径，返回将遵循单条路径，但使用哪条路径未定义（可能是短的或长的）。
- 由于互连数量众多，VOLTAGE 网络可能无法返回正确结果，因为算法是递归的，如果嵌套太深会终止。

**Original**: Finds an etch path from one object to another. Items must be on the same net and must be connect type, such as, pins, vias, clines or shapes, and tee.
Restrictions:
A partial connection between the 2 objects (ratsnest still exists) results in a nil return.
Segments are promoted to their owning cline (path)
Return list is ordered by:
o_oneDbid, ... <connected items>, o_twoDbid
To use this for finding loops on a net, you must compare every node to every other node. This can be very time consuming for large pin count nets.
– If multiple paths exist between the two objects, returns will follow a single path but the one it uses is not defined (by this it may decide on the shortest or longest.
– Because of the high number of interconnects, VOLTAGE nets may not return correct results since the algorithm is recursive and terminates if it nests too deeply.

**参数** (Arguments)：

o_oneDbid
- **first** — net item
o_twoDbid
- **second** — net item
[g_altPath]
- **enable** — alternate path

**返回值** (Value Returned)：

nil
no path exists between objects or an error
lo_dbid
path list if
g_altPath
is
nil
llo_dbid
path list if
g_altPath
is
t
. First item is one path and second item is nil or the alternative path. (
lo_1dbid
lo1dbid
)

**示例** (Examples)：

Find a path between two items
; ashOne is a selection utility found at <cdsroot>/pcb/examples/skill/ash-fxf/ashone.il
one = ashOne()
two = ashOne()
; pick a line, cline or segment (set find filter)
path = axlFindPath(one two)
axlShowObject(path)
See if the two objects is a start/end point of a loop
path = axlFindPath(one two t)

### axlGeoClosestPointOnArc

**说明**：查找从给定弧到给定点的最近点。

**Original**: Finds the closest point from the given arc to the given point.

**参数** (Arguments)：

l_point
- **A** — point
o_arcDbid
- **Dbid** — of an arc

**返回值** (Value Returned)：

l_closest_point
The closest point on the arc to the given point
nil
Invalid parameters

### axlGeoClosestPointOnCircle

**说明**：查找从给定圆到给定点的最近点。

**Original**: Finds the closest point from the given circle to the given point.

**参数** (Arguments)：

l_point
- **A** — point
l_center
- **Center** — point of circle
l_radius
- **Radius** — of circle

**返回值** (Value Returned)：

l_closest_point
The closest point on the arc to the given point
nil
Invalid parameters

**参见** (See Also)：

axlGeoClosestPointOnArc

### axlGeoPointInShape

**说明**：给定点和 Shape 的 dbid，确定该点是在 Shape 内部还是外部。对于有空洞的 Shape，如果点在空洞内，则认为在给定 Shape 外部。如果 Shape 有空洞且 `g_include_voids` 为 `t`，则如果点在空洞内，则认为在 Shape 外部。此命令不允许将孔多边形作为输入。当传入多边形孔时，显示以下警告：Invalid polygon id argument -<argument>

**Original**: Given a point and a shape
dbid
, determines whether that point is inside or outside the shape or a polygon. For a shape with voids, a point is considered
outside
the given shape if inside a void. If shape has voids and g_include_voids is t then point is outside if inside a void.
The command does not allow hole polygons as input. When polygon holes is passed the following warning is displayed:
Invalid polygon id argument -<argument>

**参数** (Arguments)：

l_point
- **Point** — to check.
o_dbid/o_polygon
- **dbid** — of the shape / o_polygon
[g_include_voids]
- **Applicable** — only in case the second parameter is a shape otherwise it's ignored.
- **In** — case of shapes, if the parameter value is nil, voids are excluded. The default value is
t
.
[
t
/
nil
]
t
- **means** — include voids,
nil
- **means** — use the shape outline only.
- **Default** — is
t
.

**返回值** (Value Returned)：

t
Point is inside the shape.
nil
Point is outside the shape, or incorrect arguments were given.

**参见** (See Also)：

:
axlGeoPointShapeInfo

### axlGeoPointShapeInfo

**说明**：给定点和 Shape 的 dbid，返回点与 Shape 的关系。状态可以是 outside、inside 或 on。在第二个参数中返回额外的 dbid，以指示涉及空洞还是 Shape。

返回矩阵：
- outside：如果在 Shape 外部则为 `nil`，如果在空洞内部则为空洞的 dbid。
- inside：`nil`。
- on：如果在 Shape 上则为 Shape 的 dbid，否则为空洞的 dbid。

注意：假设交叉填充（cross-hatch）Shape 是实心填充的。将点舍入到数据库单位。如果数据库精度为 2，而您传递了 3 位小数的点，则会在测试前将其舍入为 2 位。

**Original**: Given a point and a shape dbid returns relation of point to shape. State may be outside, inside or on. Additional dbid is returned in the second argument to indicate if void or shape is involved.
Return matrix:
G_STATE
O_DBID
outside
nil if outside shape, void dbid if inside void
inside
nil
on
shape dbid if on shape else void dbid
Caution:
Assumes that cross-hatch shapes are solid filled.
Rounds point to database units. If database accuracy is 2 and you pass a 3 decimal place point, we will round it to 2 places before doing the test.

**参数** (Arguments)：

l_point
- **the** — point
o_dbid
- **dbid** — of the shape

**返回值** (Value Returned)：

nil
- if an error since as an invalid argument
g_state/o_dbid
- see

### axlGetImpedance

**说明**：返回给定项目的最小和最大阻抗（Impedance）。项目可以是 cline、cline 段、网络或 xnet。默认阻抗单位为欧姆。

**Original**: Returns minimum and maximum impedance for given item. Item can be either cline, cline segment, net or xnet. Impedance is in ohms by default.

**参数** (Arguments)：

o_dbid
- **Segment** — cline

**返回值** (Value Returned)：

f_min f_max
Impedance in current MKS units.
nil
Segment is not a cline segment.

**参见** (See Also)：

axlSegDelayAndZ0

### axlGeoMirrorLayer

**说明**：镜像子类以获取目标层。给定层和镜像代码之一，函数根据镜像返回映射的层。

**Original**: Mirrors a subclass to get the target layer. Given a layer and one of the mirror codes, the function returns the layer, which maps based on the mirroring.

**参数** (Arguments)：

t_layer
- **Name** — of the starting layer
t_mirror
- **Mirror** — code to apply (
'GEOMETRY
,
'LAYERS
,
t
,
nil
).

**返回值** (Value Returned)：

t_result
Layer to put objects on after mirroring.
nil
Error in arguments or layer doesn't exist

**示例** (Examples)：

axlGeoMirrorLayer("ETCH/TOP" t) -> "ETCH/BOTTOM";

### axlImpdedanceGetLayerBroadsideDPImp

**说明**：计算具有给定线宽和在两个指定层上布线信号的宽边耦合差分对的差分阻抗（Impedance）。如果参数不适合计算，可能会给出警告消息。

**Original**: Computes the differential impedance of a broadside-coupled diffpair with the given line width and two specified layers on which the signal lines will be routed. A warning message may be given if the parameters are inappropriate for the calculation.

**参数** (Arguments)：

t_layer1
- **Layer** — name (example "ETCH/TOP" or "TOP")
x_layerNum1
- **Number** — of the etch subclass. Layers are numbered starting with 0 for  the Top layer.
t_layer2
- **Layer** — name (example "ETCH/TOP" or "TOP")
x_layerNum2
- **Number** — of the etch subclass. Layers are numbered starting with 0 for  the Top layer.
f_width
- **The** — line width in user units.

**返回值** (Value Returned)：

The line differential impedance in ohms (float) or
nil
on error.

**参见** (See Also)：

axlImpedance2Width

### axlImpdedanceGetLayerBroadsideDPWidth

**说明**：计算具有给定差分阻抗和在两个指定层上布线信号的宽边耦合差分对的线宽。如果参数不适合计算，可能会给出警告消息。

**Original**: Computes the differential impedance of a broadside-coupled diffpair with the given line width and two specified layers on which the signal lines will be routed. A warning message may be given if the parameters are inappropriate for the calculation.

**参数** (Arguments)：

t_layer1
- **Layer** — name (example "ETCH/TOP" or "TOP")
x_layerNum1
- **Number** — of the etch subclass. Layers are numbered starting with 0 for   the Top layer.
t_layer2
- **Layer** — name (example "ETCH/TOP" or "TOP")
x_layerNum2
- **Number** — of the etch subclass. Layers are numbered starting with 0 for  the Top layer.
diffImp
- **The** — target differential impedance in ohms.
- **Values** — Returned
- **The** — line width in user units or
nil
- **on** — error.

**参见** (See Also)：

axlImpedance2Width

### axlImpdedanceGetLayerEdgeDPImp

**说明**：计算具有给定线宽和间距在指定层上布线的边缘耦合差分对的差分阻抗。如果参数不适合计算，可能会给出警告消息。

**Original**: Computes the differential impedance of a edge-coupled diffpair with the given line width and spacing on a specified layer. A warning message may be given if the parameters are inappropriate for the calculation.

**参数** (Arguments)：

t_layer
- **Layer** — name (example "ETCH/TOP" or "TOP").
x_layerNum
- **Number** — of the etch subclass. Layers are numbered starting with 0 for  the Top layer.
f_spacing
- **Spacing** — between the two signal lines in use units.
f_width
- **The** — line width in user units.

**返回值** (Value Returned)：

The differential impedance value in ohms (float) or
nil
on error.

**参见** (See Also)：

axlImpedance2Width

### axlImpdedanceGetLayerEdgeDPSpacing

**说明**：给定在指定层上布线的边缘耦合差分对的两条信号线的线宽，找到使差分阻抗最接近目标值的间距。如果参数不适合计算，可能会给出警告消息。

**Original**: Given the line width of the two signal lines of an edge-coupled diffpair on the specified layer, finds the spacing such that the differential impedance is closest to the target value. A warning message may be given if the parameters are inappropriate for the calculation.

**参数** (Arguments)：

t_layer
- **Layer** — name (example "ETCH/TOP" or "TOP").
x_layerNum
- **Number** — of the etch subclass. Layers are numbered starting with 0 for  the Top layer.
f_width
- **The** — given line width, in user units.
f_diffImp
- **The** — target differential impedance in ohms.

**返回值** (Value Returned)：

The target spacing in user units or
nil
on error.

**参见** (See Also)：

axlImpedance2Width

### axlImpdedanceGetLayerEdgeDPWidth

**说明**：给定在指定层上布线的边缘耦合差分对的两条信号线的间距，找到使差分阻抗最接近目标值的线宽。如果参数不适合计算，可能会给出警告消息。

**Original**: Given the spacing of the two signal lines of an edge-coupled diffpair on the specified layer, finds the line width such that the differential impedance is closest to the target value. A warning message may be given if the parameters are inappropriate for the calculation.

**参数** (Arguments)：

t_layer
- **Layer** — name (example "ETCH/TOP" or "TOP").
x_layerNum
- **Number** — of the etch subclass. Layers are numbered starting with 0 for     the Top layer.
f_spacing
- **The** — spacing between the two signal lines in user units.
f_diffImp
- **The** — target differential impedance in ohms.

**返回值** (Value Returned)：

The line width in database units (float) or
nil
on error.

**参见** (See Also)：

axlImpedance2Width

### axlImpedance2Width

**说明**：将指定层上给定阻抗转换为线宽。这些 `axlImpedance` API 在 Allegro PCB L 中不可用。

**Original**: Converts the given impedance on a specified layer to a line width.
None of the
axlImpedance
APIs are available in Allegro PCB L.

**参数** (Arguments)：

t_layer
- **Layer** — name (example "ETCH/TOP" or "TOP").
x_layerNum
- **Number** — of the etch subclass. Layers are numbered starting with 0 for  the Top layer.
f_impedance
- **The** — impedance value, in ohms, that is to be converted to a line width.

**返回值** (Value Returned)：

f_lineWidth
The converted line width in drawing units.
nil
Conversion was not successful.

**参见** (See Also)：

axlImpedance2Width
axlImpdedanceGetLayerEdgeDPImp
axlImpdedanceGetLayerEdgeDPWidth
axlImpdedanceGetLayerEdgeDPSpacing
axlImpdedanceGetLayerBroadsideDPImp
axlImpdedanceGetLayerBroadsideDPWidth

### axlPadOnLayer

**说明**：测试蚀刻层上是否存在焊盘（Pad）。如果焊盘堆叠（Padstack）具有常规焊盘、反焊盘或散热焊盘，并且未被焊盘抑制（Pad Suppression）规则抑制，则焊盘存在于该层上。虽然此接口支持焊盘堆叠 dbid，但为了获得最佳效果，请传递 VIA 或 PIN 对象。

**Original**: Tests if a pad is present on an etch layer. A pad is present on the layer if the padstack has a regular, anti or thermal pad and it is not suppressed by the rules of Pad Suppression.
While this does support a padstack dbid, for best operation, pass the VIA or PIN object.

**参数** (Arguments)：

o_dbid
- **A** — via, pin or padstack
t_layer
- **Name** — of layer (for example, "TOP")
x_layerNumber
- **layer** — number (starts at 0)
g_noPadSuppress
- **t** — if ignore pad suppression, nil (default) use pad suppression

**返回值** (Value Returned)：

t
if a pad is on layer;
nil
no pad on layer

**示例** (Examples)：

Using ashOne shareware in
<cdsroot>/share/pcb/examples/skill/ash-fxf/ashone.il
Assuming a design where pad suppression is enabled on etch layer GND
pad = ashOne(list("vias" "pins"))
res1 = axlPadOnLayer(pad "GND")
res2 = axlPadOnLayer(pad "GND" t)

**参见** (See Also)：

axlPadSuppressGet

### axlPinExport

**说明**：以 CSV 格式导出符号编辑器中的所有引脚。CSV 文件格式在 `axlPinImport` 中描述。此函数仅在符号编辑器中启用。

**Original**: This exports all pins in the symbol editor in csv format. The format of the csv file is described in
axlPinImport
.
Function is only enabled in symbol editor.

**参数** (Arguments)：

g_includeTextLocation
if
t
, include pin text location (offset, rotation and mirror);
nil
- **omits** — data which means pin text when loaded into a symbol will be located at pin origin.
t_csvfile
- **Name** — of csv file; default is symbol name. Assumes a csv extension.

**返回值** (Value Returned)：

t
csv file created
nil
failed to create csv file

**示例** (Examples)：

See example in
axlPinImport
.

**参见** (See Also)：

axlPinImport

### axlPinImport

**说明**：将引脚 CSV（逗号分隔值）文件导入符号编辑器。使用此文件，您可以描述一组引脚（包括机械引脚）的位置和其他特征，这些引脚构成一个符号。此函数仅在符号编辑器中启用。为了最好地理解此文件的格式，您应该通过 `axlPinExport` 导出一个文件。支持两种格式：仅引脚（引脚文本位于引脚原点）和带文本的引脚。

**Original**: This imports pin csv (comma separated values) file into the symbol editor. With this file you can describe the location and other characteristics of a set of pins (including mechanical) that comprise a symbol.
This function is only enabled in symbol editor.
To best understand the format of this file, you should export one via axlPinExport.
Two formats are supported:
pin only, pin text is located at pin origin
pin with text
File format:
A '#' indicates a comment
(Optional) Units,
<units strings>
table describing pins
Pin Table (column number indicated)
PinNumber - Pin number, if blank then a mechanical pin.
Padstack - name of padstack
x - x location of pin (no units)
y - y location of pin (no units)
rotation - pin rotations, if blank has no rotations
If the pin text option is used then the following columns should be present.
x offset location from pin origin
y offset location from pin origin
rotation of text (absolute), if blank no rotation
textMirror; blank no mirror, "m" text should be mirrored
Text block used for pin text is the design active text block.
Setting axlDebug() may give additional info on why pins fail to load.

**参数** (Arguments)：

t_csvFile
- **csv** — file, assumes a .csv extension.

**返回值** (Value Returned)：

nil
Unable to open file or no pins loaded
l_cnt
A list of
(x_pinsLoaded x_pinFailed)

**示例** (Examples)：

In the symbol editor with a
dra
file loaded. Export pins with text location, date, delete all pins and then import them:
axlPinExport(nil "foo")
axlDeleteObject(axlDBGetDesign()->pins nil
axlPinImport(foo")

**参见** (See Also)：

axlPinExport

### axlReratNet

**说明**：重新生成网络的鼠线（Rerats a net）。通常不需要这样做，因为 Allegro PCB Editor 会根据需要自动更新鼠线。

**Original**: Rerats a net. Normally this is not required since Allegro PCB Editor automatically updates ratsnesting as required.

**参数** (Arguments)：

t_old_name
- **the** — existing net name.
o_dbid
- **Alternative** — is a dbid that is on a net

**返回值** (Value Returned)：

t
the net is successfully reratted.
nil
fails.

**示例** (Examples)：

axlReratNet("NET1")

### axlText2Lines

**说明**：将文本 dbid 向量化为一列表的 `r_path` 对象列表。返回值为每个字符的一列表 `r_paths` 列表。每个字符可以有一条或多条线绘制，每条线绘制可以有一个或多个线段。

注意：
- 向量化返回线段（无弧），但未来可能改变。
- 单个字符可能返回多个 r_path，一个 r_path 可能有多个线段。
- 宽度对于构成单个 `textDbid` 的所有线是相同的。
- 字符从左到右返回。
- 空白被跳过。
- Allegro 将所有文本绘制为描边文本。此函数将文本 dbid 转换为使用 `r_path` 结构的一系列线绘制。
- 您可以使用 `axlPolyFromDB` 的 `"?line2poly t"` 选项将 `r_path` 转换为 `o_polygon`。

**Original**: This vectorizes a text dbid into a list of lists of
r_path
objects.
The return is a list of list
r_paths
for each character:
llr_path = (l_rpathChar1, l_rpathChar2 ... l_lrpath_CharLast)
Each character can have one or more line draws and each line draw can have one or more segments. For example, an 'A' has 2 line draws; one have 2 segments and the second 1 segment.
l_rpathChar1 = (l_rpathLine1, ... lrpathLineN)
where:
l_rpathLineX->_width  -> thickness of line
l_rpathLineX->__pathList -> list of segments making up a line
Things to note:
Vectorization returns line segments (no arcs) although this may change in the future.
A single character may return multiple r_paths and one r_path may have multiple segments.
The width is the same for all lines making up a single
textDbid
. This means that the width for all segments undefined since the r_path has the width.
Characters are returned left to right.
Whitespace is skipped.
Allegro draws all text as stroke text. This converts a text dbid into a series of line draws using
r_path
structures.
You can convert a
r_path
to an
o_polygon
by using axlPolyFromDB using its "
?line2poly t
" option.

**参数** (Arguments)：

o_textDbid
- **A** — text dbid

**返回值** (Value Returned)：

llr_path
A list of list of r_paths (see above)
nil
An error (not a text dbid) or text dbid is an empty string (shown in Allegro with a small triangle).

**示例** (Examples)：

Function ashOne is a shareware utility that allows user to select one object (see
<cdsroot>/share/pcb/examples/skill/ash-fxf/ashone.il
).
Pick a text and add converted lines on BOARD GEOMETRY/OUTLINE layer
text = ashOne("TEXT")
lines = axlText2Lines(text)
layer = "BOARD GEOMETRY/OUTLINE"
; flatten list
flattened = foreach( mapcan x lines x)
; create objects in database
foreach(path flattened i = axlDBCreatePath(path layer nil nil nil))
Pick a text and add converted to shapes on "BOARD GEOMETRY/ASSEMBLY_DETAIL
text = ashOne("TEXT")
lines = axlText2Lines(text)
layer = "BOARD GEOMETRY/ASSEMBLY_DETAIL"
; flatten list
flattened = foreach( mapcan x lines x)
foreach(path flattened
; may return multiple polys
polys = axlPolyFromDB(path ?endCapType 'ROUND ?line2poly t)
; create shapes in database
foreach(poly polys i = axlDBCreateShape(poly t layer nil nil))
)

**参见** (See Also)：

axlPolyFromDB
,
Path Functions

### axlUnfixAll

**说明**：这是一个便利 API。它从设计中的所有元素移除 FIXED 属性。

**Original**: This is a convenience API.
If removes the FIXED property from all elements in the design.

**参数** (Arguments)：

none

**返回值** (Value Returned)：

x_count
Number of fixed properties removed.

**示例** (Examples)：

axlUnfixAll()

### axlWidth2Impedance

**说明**：将指定层上给定线宽转换为阻抗。使用场求解器计算阻抗。

**Original**: Converts the given line width on a specified layer to an impedance. This uses the field solver to compute the impedance

**参数** (Arguments)：

t_layer
- **Layer** — name (example "ETCH/TOP" or "TOP").
x_layerNum
- **Number** — of the etch subclass. Layers are numbered starting with 0 for  the Top layer.
f_lineWidth
- **The** — line width to be converted to an impedance.

**返回值** (Value Returned)：

f_impedance
The converted impedance value.
nil
Conversion was not successful.

**参见** (See Also)：

axlImpedance2Width

### axlIsHighlighted

**说明**：如果对象被永久高亮显示，则返回高亮颜色；否则返回 `nil`。可以高亮显示引脚。只有符号、网络、引脚和 DRC 错误可以被高亮显示。Cadence 建议不要高亮显示 DRC 对象，除非它们是外部 DRC，因为 Allegro PCB Editor 的 DRC 经常被重新创建。

**Original**: If the object is permanently highlighted returns the highlight color; otherwise
nil
.
Pins can be highlighted.
Only symbols, nets, pins and DRC errors can be highlighted. Cadence suggests that you do not highlight DRC objects unless they are external DRCs, since Allegro PCB Editor DRCs are frequently recreated.

**参数** (Arguments)：

o_dbid
A
dbid
- **for** — which highlighting information is desired.

**返回值** (Value Returned)：

x_highlightColor
Highlight color;
nil
if not highlighted, or object does not support highlighting.

**示例** (Examples)：

See
axlHighlightObject
axlTestPoint
axlTestPoint
o_dbid
top
|bottom|nil
)
⇒ t/nil/
s_error

**参见** (See Also)：

axlHighlightObject

### axlChangeNet

**说明**：更改对象当前所在的网络。仅限于 Shape、填充矩形（frectangles）、引脚和过孔。成功时返回 `t`。不会撕裂 cline 或过孔。

失败可能由于以下原因：对象不受支持；网络名称不存在。

以下限制适用于此函数：引脚必须已分配。引脚必须有关联的元件。机械引脚未分配。建议为过孔分配网络。过孔必须能够连接到提供的网络上的某个东西，才能保留在该网络上。否则，它将回退到原始网络或可能另一个网络。如果过孔在开放空间中，它将在虚拟网络上。此 API 不能用于强制将其放在网络上。此 API 对于过孔很有用，如果它接触多个 Shape 但被分配到了错误的 Shape 网络。

**Original**: Changes the net an object is currently on. Restricted to shapes, filled rectangles (frectangles), pins and vias. Returns
t
when successful. Will not rip up clines or vias.
Failure can occur for the following reasons:
Object is not supported.
netName does not exist.
The following restrictions apply to this function:
Pins must be assigned. Pins must have an associated component. Mechanical pins are un-assigned.
Via net assignment is advised. The via must be able to connect to something on the provided net to remain on that net. Otherwise, it will fall back to the original net or possibly another net.
If a via is in open space, it will be on a dummy net. This API cannot be used to force it onto a net.
This API is useful for a via, if it touches multiple shapes but it is assigned to the wrong shape’s net.
Potential side effects of this function:
It may not properly reconnect two touching cline segments that were previously connected by the shape.
Clines only attached to the shape will inherit the new net of the shape.
Vias attached to the shape will not inherit the new net. This is different from the Allegro change net command.

**参数** (Arguments)：

o_dbid
Shape
dbid
t_netName/o_netdbid
- **Name** — of a net or a netdbid (for dummy nets)

**返回值** (Value Returned)：

t
Object changed.
nil
No object changed.

### axlSegDelayAndZ0

**说明**：返回 cline 段的延迟（Delay）和阻抗（Z0）。如果段不是 cline 段，则返回 `nil`。通常，延迟以纳秒为单位，阻抗以欧姆为单位。如果传入非 cline 段，此函数会产生大量输出。

**Original**: Returns the delay and impedance of a cline segment. Returns
nil
if a segment isn’t a cline segment. Normally, delay is in nanoseconds and impedance is in ohms.
This function is noisy if you pass in non-cline segments.

**参数** (Arguments)：

o_clineSegDbid
- **Segment** — cline

**返回值** (Value Returned)：

f_delay
f_z0
Delay and impedance in current MKS units.
nil
Segment is not a cline segment.

**参见** (See Also)：

axlGetImpedance

### axlSetDefaultDieInformation

**说明**：为元件设置默认的芯片（Die）信息。此函数将新放置的 IC 类元件配置为 MCM 设计中的芯片。根据放置的元件信息，芯片将被标记为线键合（wire bond）或倒装芯片（flip-chip）。

**Original**: Sets the default die information for a component.
This function will configure a newly-placed IC-class component as a die in an MCM design. Based on the placed component's information the die will be flagged as either wire bond or flip-chip.

**参数** (Arguments)：

comp
- **dbid** — of the component / symbol to set default information for.

**返回值** (Value Returned)：

t
if successful,
nil
otherwise.
