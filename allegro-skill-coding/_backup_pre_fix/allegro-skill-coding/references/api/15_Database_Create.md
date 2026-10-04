# 15. 数据库创建 (Database Create)

**产品文档**：Allegro SKILL Reference  
**产品版本**：17.4-2019, October 2019

## 概述 (Overview)

本章描述将对象添加到 Allegro PCB Editor 数据库的 AXL 函数。某些函数需要使用可用的辅助函数设置输入，这些辅助函数也在本章中描述。例如，Allegro PCB Editor 路径由任意数量的连续线和弧段组成。要将此多结构添加到 Allegro PCB Editor 数据库，首先创建一个临时路径，使用单独的函数调用添加每条线或弧段。临时路径包含所有必需的线段后，通过调用适当的数据库创建函数创建 Allegro PCB Editor 线条对象、铜皮或挖空，将路径结构作为参数传入。本章展示了该过程的几个示例。

**Original**: This chapter describes the AXL functions that add objects to the Allegro PCB Editor database. Some functions require input that you set up using available auxiliary functions, which are also described in this chapter. For example, Allegro PCB Editor paths consist of any number of contiguous line and arc segments. To add this multi-structure to the Allegro PCB Editor database, first create a temporary path, adding each line or arc segment using separate function calls. Once the temporary path contains all required segments, create the Allegro PCB Editor line-object, shape or void by calling the appropriate database create function, giving the path structure as an argument. The chapter shows several examples of the process.

数据库创建（DBCreate）函数修改虚拟内存中的活动 Allegro PCB Editor 数据库，需要保存数据库才能使更改在文件中永久生效。

除非另有说明，否则向这些函数提供的所有坐标均使用用户单位。

此处描述的函数在创建对象时不会立即显示它们。要显示所有更改，请调用交互式函数、退出 SKILL 或将控制权返回给 Allegro PCB Editor 命令解释器。要立即显示刚刚创建的对象，请执行以下操作之一：
- 调用函数 `axlDisplayFlush` —或—
- 调用交互式函数

如果创建对象然后删除它而不调用 `axlDisplayFlush` 或调用交互式函数，则对象永远不会出现在显示中。

DBCreate 函数创建的几何对象类别称为图形（figures）。DBCreate 函数以列表形式返回它们创建的任何图形的 `dbids`，以及一个布尔值 `t`，如果创建导致任何 DRC。如果无法创建任何图形，函数返回 `nil`。各命令返回的数据的确切结构不同。请参见各命令的详细描述。

可以通过调用 `axlSetCurrentLayer` 函数设置活动层（Allegro PCB Editor 类/子类）。如果尝试设置无效层或尝试在不允许该图形类型的层上创建图形，此函数将返回 `nil`。

AXL-SKILL 仅在图形位于蚀刻层上时才将图形创建为网络的成员。如果函数有网络名称作为参数，且活动层是蚀刻层，函数将图形附加到该网络名称指定的网络。如果网络不存在，则发生错误。如果为网络名称指定 `nil`，函数通过图形接触的其他图形来确定图形的网络。如果图形是独立的，即不接触任何东西，则图形成为虚拟网络（无网络）的成员。

函数对您未提供的所有参数使用默认值。如果未提供必需的参数（没有默认值的参数，例如 `pointList`），函数将调用视为错误并返回 `nil`。

数据库创建函数不会将图形添加到选择集。它们保持选择集不变。

**Original**: Database create (DBCreate) functions modify the active Allegro PCB Editor database in virtual memory and require a database save to make changes permanent in the file. Supply all coordinates to these functions in user units, unless otherwise noted. The functions described here do not display the objects immediately as they create them. To display all changes, call an interactive function, exit SKILL, or return control to the Allegro PCB Editor command interpreter. To immediately display an object you have just created, do one of the following: Call the function `axlDisplayFlush` –or– Call an interactive function. If you create an object and then delete it without calling `axlDisplayFlush` or calling an interactive function, the object never appears in the display. The class of geometric objects that DBCreate functions create are called figures. DBCreate functions return, in a list, the dbids of any figures they create and a Boolean value `t` if the creation caused any DRCs. The functions return `nil` if they could not create any figures. You can set the active layer (Allegro PCB Editor class/subclass) by calling the `axlSetCurrentLayer` function. AXL-SKILL creates a figure as a member of a net only if the figure is on an etch layer. The functions use defaults for all parameters you do not supply. If you do not supply a required parameter (one without a default, for example, pointList) the function considers the call an error and returns `nil`. The database create functions do not add figures to the select set. They leave the select set unchanged.

---

## 路径函数 (Path Functions)

Allegro PCB Editor 的 `line`（线条）是一个图形，由首尾相连的直线和圆弧段组成，每个线段具有可单独定义的宽度。Allegro PCB Editor 的 `shapes`（铜皮）和 `polygons`（多边形）是定义区域的图形。铜皮拥有一个定义铜皮周边的闭合线条图形。铜皮具有关联的填充图案，还可以拥有内部的 `voids`（挖空）。每个挖空又拥有一个定义其边界的多边形。

`path`（路径）是一组连续的圆弧和单条直线段。在 AXL 中，首先通过使用单独的 AXL 函数添加每条线和圆弧段来创建路径，然后使用适当的 `axlDBCreate` 函数创建实际图形，将路径作为参数之一。使用本章后面描述的 AXL 便捷函数，可以创建矩形、圆形和仅由直线段组成的线条。

路径函数的所有坐标参数均以用户单位表示，且相对于布局原点绝对坐标。

**Original**: An Allegro PCB Editor line is a figure consisting of end-to-end straight line and arc segments, each segment having a width you can define separately. Allegro PCB Editor shapes and polygons are figures that define an area. A shape owns a closed line figure that defines the perimeter of the shape. The shape has an associated fill pattern and can also own internal voids. Each void in turn owns a polygon that defines its boundary. A path is a set of contiguous arc and single straight line segments. In AXL, you first create a path consisting of the line and arc segments by adding each segment with a separate AXL function, then creating the actual figure using the appropriate axlDBCreate function, with the path as one of the arguments. All coordinate arguments to the path functions are in user units and are absolute to the layout origin.

**示例**：
此通用示例展示了如何创建路径，然后将其作为参数用于 `axlDBCreate` 函数。示例创建一个路径，包含一条直线段，然后添加一个圆弧和另一条直线段，并使用它作为参数创建属于网络 `"net1"` 的路径，在蚀刻子类 `"top"` 上：

```skill
path = axlPathStart( (list 100:250))
axlPathLine( path, 0.0, 200:250 )
axlPathArcCenter( path, 0.0, 300:350, nil, 200:350 )
axlPathLine( path, 0.0, 300:450 )
axlDBCreatePath( path, "etch/top", "net1")
```

---

### axlPathStart

**说明**：创建一个新的路径，起点和一个或多个线段由 `l_points` 列表指定，并返回路径 `dbid`。可以使用本节中描述的 `axlPathArc` 和 `axlPathLine` 函数向返回的 `r_path` 添加更多直线和圆弧段。一旦 `r_path` 包含所有必需的线段，请使用适当的 `axlDBCreate` 函数创建实际的数据库图形，将 `r_path` 作为参数之一。

**Original**: Creates a new path with a startpoint and one or more segments as specified by the list `l_points` and returns the path `dbid`. You can add more straight-line and arc segments to the returned `r_path` using the `axlPathArc` and `axlPathLine` functions described in this section. Once `r_path` has all the segments you require, create the actual database figure using the appropriate `axlDBCreate` function, with `r_path` as one of the arguments.

**语法**：
```skill
axlPathStart(
l_points
[
f_width
]
)
=> r_path/nil
```

**参数**：
- `l_points`：顶点列表，其中 `n > 1`。如果 `n = 1`，`r_path` 返回时该单个顶点作为起点，但没有线段。必须随后添加至少一个线段才能将其添加到数据库。如果 `n > 1`，`r_path` 返回时具有 `n-1` 条直线段。
- `f_width`：如果创建任何线段，所有线段之间的宽度。`f_width` 是使用 `axlPath` 函数添加到 `r_path` 的所有附加线段的默认宽度。每次使用 `axlPath` 函数添加线段时，都可以通过使用 `f_width` 参数来覆盖此默认宽度。

**返回值**：
- `r_path`：返回路径句柄。这是一个句柄对象，但不是 Allegro PCB Editor `dbid`。
- `nil`：路径未创建。

**示例**：
请参见路径函数部分的开头。

---

### axlPathArcRadius / axlPathArcAngle / axlPathArcCenter

**说明**：这些函数中的每一个都提供了一种从 `r_path` 的当前端点到给定的 `l_end_point` 构造圆弧段的方法，方向由布尔值 `g_clockwise` 指定，如下所述并在图 15-1 中显示。尝试使用许多小数点精度创建小圆弧可能会因舍入误差而失败。

**Original**: Each of these functions provides a way to construct an arc segment from the current endpoint of `r_path` to the given `l_end_point` in the direction specified by the Boolean `g_clockwise`, as described below and shown in Figure 15-1. Attempts to create small arcs using many decimal points of accuracy may fail due to rounding errors.

**语法**：
```skill
axlPathArcRadius(
r_path
f_width
l_end_point
g_clockwise
g_bigarc
f_radius
)
=> r_path/nil

axlPathArcAngle(
r_path
f_width
l_end_point
g_clockwise
f_angle
)
=> r_path/nil

axlPathArcCenter(
r_path
f_width
l_end_point
g_clockwise
l_center
)
=> r_path/nil
```

**参数**：
- `r_path`：接收圆弧段的现有 `r_path` 的句柄。
- `f_width`：圆弧段的宽度（用户单位）。仅覆盖此线段在 `axlPathStart` 中最初给出的任何宽度；`nil` = 使用当前宽度。
- `l_end_point`：圆弧要构造到的终点。起点是 `r_path` 中当前最后的点（绝对坐标）。
- `g_clockwise`：创建圆弧的方向：
  - `t` → 从起点到终点顺时针创建圆弧
  - `nil` → 逆时针。默认值为逆时针（参见图 15-1）。
- `g_bigarc`（`axlPathArcRadius`）：创建大于或等于 180 度的圆弧（参见图 15-1）。
- `f_radius`（`axlPathArcRadius`）：圆弧半径（用户单位）。
- `f_angle`（`axlPathArcAngle`）：圆弧所对的角度（度）（参见图 15-1）。
- `l_center`（`axlPathArcCenter`）：圆弧中心点（绝对坐标）。

**返回值**：
- `r_path`：当前路径句柄。
- `nil`：未创建圆弧路径。

**示例 1**：
```skill
mypath = axlPathStart( list( 8900:4400))
axlPathArcRadius( mypath, 12., 8700:5300, nil, nil, 500)
axlDBCreatePath( mypath, "etch/top")
;; 通过半径添加小于 180 度的逆时针圆弧。
;; 创建较小的可能圆弧：
```

**示例 2**：
```skill
mypath = axlPathStart( list( 8900:4400))
axlPathArcAngle( mypath, 12., 8700:5300, nil, 330)
axlDBCreatePath( mypath, "etch/top")
;; 添加对 330 度的逆时针圆弧。
```

---

### axlPathLine

**说明**：向现有 `r_path` 结构的末尾添加单条直线段，起点为 `r_path` 中的最后一个点。

**Original**: Adds a single straight line segment to the end of an existing `r_path` structure as specified by the arguments. Start point of the line is the last point in `r_path`.

**语法**：
```skill
axlPathLine(
r_path
f_width
l_end_point
)
=> r_path/nil
```

**参数**：
- `r_path`：现有路径的句柄。
- `f_width`：线段的宽度。`nil` = 线段采用创建 `r_path` 时给出的宽度。
- `l_end_point`：直线段的终点（绝对坐标）。

**返回值**：
- `r_path`：在 `r_path` 结构末尾添加单条直线段后的路径结构。
- `nil`：未向 `r_path` 结构添加线段。

**示例**：
请参见路径函数部分的开头。

---

### axlPathGetWidth

**说明**：获取现有路径结构的默认宽度。

**Original**: Gets the default width of an existing path structure.

**语法**：
```skill
axlPathGetWidth(
r_path
)
=> f_width/nil
```

**参数**：
- `r_path`：现有路径结构的句柄。

**返回值**：
- `f_width`：路径结构的默认宽度。
- `nil`：`r_path` 不是路径，或为空。

**示例**：
```skill
axlPathGetWidth 返回默认路径宽度 173 mils。
path = axlPathStart( (list 1000:1250), 173)
axlPathLine( path, 29, 2000:1250)
axlPathLine( path, 33, 3000:3450)
axlDBCreatePath( path, "etch/top")
axlPathGetWidth( path)
=> 173.0
```

---

### axlPathSegGetWidth

**说明**：获取路径结构中单段的宽度。

**Original**: Gets the width of a single segment in a path structure.

**语法**：
```skill
axlPathSegGetWidth(
r_pathSeg
)
=> f_width/nil
```

**参数**：
- `r_pathSeg`：路径结构段的句柄。

**返回值**：
- `f_width`：返回线段的宽度。
- `nil`：`r_pathSeg` 不是线段。

**示例**：
```skill
axlPathSegGetWidth 返回该段的宽度，仅 33 mils。
path = axlPathStart( (list 1000:1250), 173)
axlPathLine( path, 29, 2000:1250)
axlPathLine( path, 33, 3000:3450)
lastSeg = axlPathGetLastPathSeg(path)
axlPathSegGetWidth( lastSeg)
=> 33.0
```

---

### axlPathGetPathSegs

**说明**：获取路径结构的线段列表，按它们在线径中出现的顺序排列。

**Original**: Gets a list of the segments of a path structure, in the order they appear in the path.

**语法**：
```skill
axlPathGetPathSegs(
r_path
)
=> r_pathList/nil
```

**参数**：
- `r_path`：现有路径结构的句柄。

**返回值**：
- `r_pathList`：返回路径的线段列表。
- `nil`：`r_path` 不是路径。

**示例**：
```skill
mypath = axlPathStart( (list 1000:1250), 173)
axlPathLine( mypath, 29, 2000:1250)
axlPathArcCenter( mypath, 12, 3000:2250, t, 3000:2250)
mysegs = axlPathGetPathSegs( mypath)
print mysegs
=>(array[6]:1057440 array[6]:1057416 array[6]:1057392)
```

---

### axlPathGetLastPathSeg

**说明**：获取路径结构的最后一段。

**Original**: Gets the last segment of a path structure.

**语法**：
```skill
axlPathGetLastPathSeg(
r_path
)
=> r_pathList/nil
```

**参数**：
- `r_path`：现有路径结构的句柄。

**返回值**：
- `r_pathList`：返回路径的最后一段。
- `nil`：`r_path` 不是路径。

**示例**：
```skill
path = axlPathStart( (list 1000:1250), 173)
axlPathLine( path, 29, 2000:1250)
axlPathLine( path, 33, 3000:3450)
lastSeg = axlPathGetLastPathSeg(path)
axlPathSegGetWidth( lastSeg)
=>33.0
```

---

### axlPathSegGetEndPoint

**说明**：获取现有路径结构的终点。

**Original**: Gets the end point of an existing path structure.

**语法**：
```skill
axlPathSegGetEndPoint(
r_pathSeg
)
=> l_endPoint/nil
```

**参数**：
- `r_pathSeg`：路径段的句柄。

**返回值**：
- `l_endPoint`：包含路径结构终点的列表。
- `nil`：`r_pathSeg` 不是路径段的 `dbid`，或结构为空。

**示例**：
```skill
path = axlPathStart( (list 1000:1250), 173)
axlPathLine( path, 29, 2000:1250)
axlPathLine( path, 33, 3000:3450)
lastSeg = axlPathGetLastPathSeg(path)
axlPathSegGetEndPoint( lastSeg)
=>(3000 3450)
```

---

### axlPathSegGetArcCenter

**说明**：获取路径圆弧段的中心点。

**Original**: Gets the center point of a path arc segment.

**语法**：
```skill
axlPathSegGetArcCenter(
r_pathSeg
)
=> l_point/nil
```

**参数**：
- `r_pathSeg`：路径圆弧段的句柄。

**返回值**：
- `l_point`：包含圆弧段中心坐标的列表。
- `nil`：线段不是圆弧。

**示例**：
```skill
axlPathSegGetArcCenter 获取最后圆弧段的中心。
path = axlPathStart( (list 1000:1250), 173)
axlPathLine( path, 29, 2000:1250)
axlPathArcCenter( path, 12., 3000:2250, nil, 2000:2250)
lastSeg = axlPathGetLastPathSeg(path)
axlPathSegGetArcCenter( lastSeg)
=>(2000 2250)
```

---

### axlPathSegGetArcClockwise

**说明**：获取路径线段的顺时针标志（`t` 或 `nil`）。

**Original**: Gets the clockwise flag (t or nil) of a path segment.

**语法**：
```skill
axlPathSegGetArcClockwise(
r_pathSeg
)
=> t/nil
```

**参数**：
- `r_pathSeg`：路径段的句柄。

**返回值**：
- `t`：线段是顺时针的。
- `nil`：线段是逆时针的。

**示例**：
```skill
axlPathSegGetArcCenter 返回 t，表示圆弧段是顺时针的。
path = axlPathStart( (list 1000:1250), 173)
axlPathLine( path, 29, 2000:1250)
axlPathArcCenter( path, 12., 3000:2250, t, 2000:2250)
lastSeg = axlPathGetLastPathSeg(path)
axlPathSegGetArcClockwise( lastSeg)
=> t
```

---

### axlPathStartCircle

**说明**：为圆创建 `axlPath` 结构（`r_path`）。

**Original**: Creates an `axlPath` structure (`r_path`) for a circle.

**语法**：
```skill
axlPathStartCircle(
l_location
f_width
)
=> r_path/nil
```

**参数**：
- `l_location`：中心和半径为 `((X Y) R)`。
- `f_width`：圆的边缘宽度。

**返回值**：
- `r_path`：包含圆作为唯一线段的 `r_path`。
- `nil`：`axlPath` 结构未创建。必须为此接口指定宽度（可以为 0.0），并且由于它使用标准 SKILL 参数检查，因此必须是浮点数。

**示例**：
```skill
(axlPathStartCircle (list 100:200 20),0)  ; 未指定宽度。
```

---

### axlPathOffset / axlDB2Path

**说明**：向 `r_path` 中的所有点添加偏移量 `xy`。

**Original**: Adds an offset, `xy`, to all points within a `r_path`.

**语法**：
```skill
axlDB2Path(
r_path
xy
)
==> r_path
```

**参数**：
- `r_path`：偏移。
- `xy`：偏移 `xy`。

**返回值**：新的 `r_path`。

**另请参见**：`axlPathStart`，`axlDB2Path`

**示例**：
```skill
;; 获取铜皮轮廓作为 r_path，然后将其移动 10:20。
p = ashOne("shapes")
path = axlDB2Path(p)
path1 = axlPathOffset(path 10:20)
```

---

### axlDB2Path

**说明**：获取数据库 ID（`od_dbId`）并将其转换为 `r_path`。此函数支持所有具有 `segment` 属性的 `dbid`。例如，铜皮、挖空、路径和线条。在 AXL-SKILL 术语中，path 和 line 分别指 cline/line 和线段。

**Original**: This takes a database id (`od_dbId`) and converts it to an r_path. This function supports all dbids with a segment attribute. For example, shape, void, path, and line. In AXL-SKILL terminology, path and line, refers to cline/line and segments, respectively.

**语法**：
```skill
axlDB2Path(
od_dbId
)
==> r_path
```

**参数**：
- `od_dbId`：线条的 `dbid`。

**返回值**：
- `r_path`：如果对象可以转换。
- `nil`：对象无法转换。

**另请参见**：`axlPathStart`

**示例**：
```skill
;; 要获取铜皮轮廓作为 r_path，请使用以下命令：
p = ashOne("shapes")
path = axlDB2Path(p)
```

---

### axlDBCreatePath

**说明**：创建指定的路径图形（线条或蚀刻线）。如果蚀刻未连接到引脚、过孔或铜皮，则不会向蚀刻添加网络名称。如果添加蚀刻，它会连接到第一个接触的网络，否则根据下面描述的参数保持 "不在网络上"。蚀刻线可能会与其他蚀刻线合并，因此结果坐标可能是所提供坐标的上集。目前对于线条类型不是这样。通常，如果要将属性附加到新创建的对象，请在创建对象后调用 `axlDBAddProp()`。CLINE 可能会与现有 CLINE 合并，因此您最终添加属性的对象可能与您创建的对象不匹配。`lo_props` 选项解决了此问题。您可以在创建 CLINE 时添加属性，如果 CLINE 上的属性列表与任何合并目标 CLINE 不同，则您的 CLINE 不会合并。此接口支持 LINES，尽管线条不会合并。Allegro 限制允许字体（`s_font`）的层。ETCH 层永远不能有字体线条。

**Original**: Creates a path figure (line or cline) as specified. Does not add a net name to etch when the etch is not connected to a pin, via, or shape. If etch is added, it ties to the first net it touches, otherwise it remains "not on a net" as specified by the arguments described below. Clines may merge with other clines so that the resulting coordinates may be a superset of the provided coordinates. This is not currently true for line types. Normally, if you want to attach properties to a newly-created object, call `axlDBAddProp()` after creating the object. CLINEs may merge with existing CLINEs, so the object you end up adding properties to may not match the one you created. The `lo_props` option deals with this issue. You can add properties when you create the CLINE and if the property list on your CLINE differs from any merged target CLINES, your CLINE will not merge. LINES with the interface are supported even though lines do not merge. Allegro restricts the layers that allow fonts (`s_font`). ETCH layers may never have fonted lines.

**语法**：
```skill
axlDBCreatePath(
r_path
[
t_layer
]
[
t_netName
]/['line]
[
o_parent
]
[
lo_props
]
[s_font]
)
=> l_result/nil
```

**参数**：
- `r_path`：由 `axlPath` 函数先前创建的直线和圆弧段组成的现有路径。
- `t_layer`：创建路径图形的层。默认是活动层。
- `t_netName`：路径图形所属的网络名称。如果网络 `t_netName` 不存在，`axlDBCreatePath` 不会创建任何路径，并返回 `nil`。
- `'line`：默认情况下，在 Etch 层上创建的路径会创建蚀刻线，除非为此参数传递 `'line`。
- `o_parent`：路径图形父对象的 `dbid`。使用符号实例或使用 `nil` 指定设计。如果将蚀刻图形附加到符号父对象，图形不与符号关联，也不随其移动。
- `[lo_props]`：可选属性名称/值对列表。（请参见 `axlDBAddProp()` 的格式。）
- `[s_font]`：可选线条字体，可能值为 `'SOLID`、`'HIDDEN`、`'PHANTOM`、`'DOTTED`、`'CENTER`。`nil` 与 `'SOLID` 相同。

**返回值**：
- `l_result`：返回列表：
  - `(car)`：创建或修改的所有路径图形的 `dbids` 列表。
  - `(cadr)`：如果创建了 DRC 则为 `t`，否则为 `nil`。
- `nil`：未创建任何内容。

**另请参见**：`axlDBAddProp`

**示例**：
```skill
path = axlPathStart( list 100:0 100:500))
;; 在当前默认层上创建路径
axlDBCreatePath(path)
;; 在顶层蚀刻层上创建蚀刻线路径并分配给 GND
axlDBCreatePath(path "ETCH/TOP" "gnd")
;; 在顶层蚀刻层上创建线条路径
axlDBCreatePath(path "ETCH/TOP" 'line)
;; 让用户在板几何轮廓上创建两个拾取路径
axlDBCreatePath( axlEnterPath() "BOARD GEOMETRY/OUTLINE")
;; 在顶层蚀刻层上创建带有属性的蚀刻线路径
propList = list( '(FIXED t) )
axlDBCreatePath(path "ETCH/TOP" "gnd" nil propList)
```

---

### axlDBCreateLine

**说明**：创建固定宽度直段的路径，一条具有提供点序列的线条。如果线条在 ETCH 层上，则会创建蚀刻线，除非用 `'line` 符号覆盖。所有点都是用户单位中的绝对坐标。对于提供的 `<n>` 个点，函数创建 `<n-1>` 段。Allegro 限制允许字体的层。ETCH 层永远不能有字体线条。`t_netname` 选项在蚀刻线可能想要连接到多个对象的情况下用作决胜局。蚀刻线不能自行维持网络。这种连接行为意味着如果添加多条蚀刻线和过孔，您必须按顺序排列它们，以便每条蚀刻线或过孔添加时连接到数据库中已有期望网络的对象。例如，您添加 3 条蚀刻线来驱动 2 个引脚之间的连接；其中蚀刻线 1 和 3 终止于引脚，蚀刻线 2 在中间。您应该按 1、2、3 的顺序添加它们。按 2、1、3 添加它们可能会导致蚀刻线 2 连接到不同的网络。

**Original**: Create a path of fixed width straight segments, a line with series of provided points. If line is on an ETCH layer a cline will be created unless overridden with the 'line symbol. All points are absolute in user units. For <n> points provided, the function creates <n-1> segments. Allegro restricts the layers that allow fonts. ETCH layers may never have fonted lines. The t_netname option is used as a tie breaker in cases where the cline may want to connect to multiple objects. A cline cannot maintain a net by itself. This connectivity behavioral means if adding multiple clines and vias you must sequence them so that each cline or via is added such that it connects to an object with the desired net already in the database. For example, you add 3 clines to drive a connection between 2 pins; where cline 1 and 3 terminate on a pin and cline 2 is in the middle. You should add them as 1 2 then 3. Adding them as 2, 1 and 3 may result in cline 2 being connected to a difference net.

**语法**：
```skill
axlDBCreateLine(
l_points
[
f_width
]
[
t_layer
]
[
t_netname
]/['line]
[
rd_parent
]
[s_font]
)
=> l_result/nil
```

**参数**：
- `l_points`：此路径的顶点列表（至少两个）。
- `f_width`：路径中所有线段的宽度。默认值为 0。
- `t_layer`：添加路径的层。默认是当前活动层。
- `t_netname`：网络名称或 `nil`。
- `rd_parent`：线条添加到的对象的 `dbid`。使用符号实例 `dbid` 或使用 `nil` 指定设计本身。
- `s_font`：可选线条字体，可能值为 `'SOLID`、`'HIDDEN`、`'PHANTOM`、`'DOTTED`、`'CENTER`。`nil` 与 `'SOLID` 相同。

**返回值**：
- `l_result`：列表：
  - `(car)`：创建或修改的所有路径的 `dbids` 列表。
  - `(cadr)`：如果创建了 DRC 则为 `t`。否则函数返回 `nil`。
- `nil`：未创建任何内容。

**另请参见**：`axlDBCreatePath`

**示例**：
```skill
axlDBCreateLine( (list 1000:1250 2000:2250), 15, "etch/top")
=> ((dbid:122784) t)
;; 此示例在 "etch/top" 上从 (1000, 1250) 到 (2000, 2250) 创建宽度为 15 mils 的线条。
;; 命令返回线条的 dbid 和 t，表示它创建了 DRC。
```

---

### axlDBCreateCircle

**说明**：在指定位置创建具有指定直径的圆。

**Original**: Create a circle at indicated location and with indicated diameter.

**语法**：
```skill
axlDBCreateCircle(
l_location
[
f_width
]
[
t_layer
]
[
rd_parent
]
)
=> l_result/nil
```

**参数**：
- `l_location`：中心和半径为 `(X:Y R)`。
- `f_width`：圆边缘宽度。
- `t_layer`：层。默认是当前活动层。
- `rd_parent`：添加圆的父对象的 `dbid`（符号实例或 `nil` 表示设计）。

**返回值**：
- `l_result`：列表包含：
  - `(car)`：圆 `dbids` 列表。列表中始终有一个 `dbid`。
  - `(cadr)`：如果创建了任何 DRC 则为 `t`，否则为 `nil`。
- `nil`：未创建任何内容。

**另请参见**：`axlDBCreatePath`

---

## 创建铜皮接口 (Create Shape Interface)

您可以使用以下 AXL 函数创建铜皮：

要创建简单的铜皮，填充或未填充，没有任何挖空，首先使用前面描述的 `axlPath` 函数创建其边界路径。接下来，调用 `axlDBCreateShape`，使用路径作为参数。`axlDBCreateShape` 在数据库中创建铜皮并返回，完成该过程。

要创建带挖空的铜皮，首先使用 `axlDBCreateOpenShape` 以"打开状态"创建铜皮。接下来，根据需要使用 `axlDBCreateVoid` 和 `axlDBCreateVoidCircle` 向铜皮添加挖空。最后，使用 `axlDBCreateCloseShape` 将铜皮永久放入数据库中。此最终函数将铜皮的状态从"打开"更改为"关闭"，使其成为数据库的永久部分。一次只能有一个铜皮处于"打开"状态。

铜皮和挖空边界都使用 `r_path` 参数指定，就像创建线条和连接线条一样。`axlDBCreateShape` 和 `axlDBCreateOpenShape` 还检查以下内容：
- 所有边界路径参数（铜皮或挖空）都是闭合的（起点等于终点）
- 没有边界路径线段接触或交叉（没有"蝴蝶结"）
- 所有挖空边界完全在其父铜皮的边界内

如果未能满足其中一个或多个条件，函数不会创建铜皮或挖空，并返回 `nil`。

**Original**: You can create shapes using AXL functions as follows: To create a simple shape, filled or unfilled, without any voids, first create its boundary path using the `axlPath` functions described earlier. Next, call `axlDBCreateShape` using the path as an argument. `axlDBCreateShape` creates the shape in the database and returns, completing the process. To create a shape with voids, first create a shape in "open state" using `axlDBCreateOpenShape`. Next, add voids to the shape as needed using `axlDBCreateVoid` and `axlDBCreateVoidCircle`. Finally, put the shape permanently into the database with `axlDBCreateCloseShape`. This final function changes the state of the shape from "open" to "closed," making it a permanent part of the database. Only one shape can be in the "open" state at one time. You specify both shape and void boundaries with the `r_path` argument, just as you do creating lines and connect lines. `axlDBCreateShape` and `axlDBCreateOpenShape` also check that the following are true: All boundary path arguments—shape or void—are closed (equal startPoint endPoint); No boundary path segments touch or cross (no "bow ties"); All void boundaries are completely within the boundary of their parent shape. If you fail to meet one or more of these conditions, the functions do not create the shape or void, and return `nil`.

**示例**：
```skill
;; 创建闭合路径
mypath = axlPathStart( list(1000:1250))
mypath = axlPathLine( mypath, 0.0, 2000:1250)
mypath = axlPathArcCenter(
  mypath, 0.0, 2000:3250, nil, 2000:2250)
mypath = axlPathLine( mypath, 0.0, 1500:3250)
mypath = axlPathLine( mypath, 0.0, 1000:1250)

;; 创建填充结构，指定交叉填充参数
myfill1 = make_axlFill( ?angle 45.0, ?origin 10:20,
  ?width 50, ?spacing 80)
myfill2 = make_axlFill( ?angle 135.0, ?origin 10:20,
  ?width 5, ?spacing 100)
myfill = list( myfill1 myfill2)

;; 在 "etch/top" 上创建开放铜皮，关联网络 "sclkl"
myshape = axlDBCreateOpenShape( mypath, myfill,
  "etch/top", "sclkl")
if( myshape == axlDBActiveShape()
  println( "myshape is the active shape"))

;; 创建圆形挖空并附加到铜皮
axlDBCreateVoidCircle( myshape, list(1600:1700 300))

;; 创建挖空形状并附加到铜皮
myvoidpath = axlPathStart( list(1600:2300))
myvoidpath = axlPathLine( myvoidpath, 0.0, 2400:2100)
myvoidpath = axlPathLine( myvoidpath, 0.0, 2600:2700)
myvoidpath = axlPathLine( myvoidpath, 0.0, 2100:3000)
myvoidpath = axlPathLine( myvoidpath, 0.0, 1600:2300)
axlDBCreateVoid(myshape, myvoidpath)

;; 关闭铜皮
axlDBCreateCloseShape( myshape)
```

---

### axlDBComposeShapesFromLines

**说明**：使用此函数将从 DXF 或 Gerber 输入创建的一组线条和圆弧转换为铜皮。该函数封装了 `compose shape` 命令。它允许您收集相同的对象并以编程方式将其转换为目标层上的铜皮。

使用此函数从线条创建的任何铜皮等同于使用 `axlDBCreateOpenShape` 和 `axlDBCreateShape` 函数创建的铜皮。此函数提供了对便捷功能的访问，如桥接线段中的间隙（这些间隙是从外部文件引入的）。它还可以像交互式 compose shape 工具一样圆角或修剪角。

**Original**: Use this function to convert a group of lines and arcs created from a DXF or Gerber input into a shape. The function encapsulates the `compose shape` command. It allows you to gather the same objects and programmatically convert those into shapes on the target layers. Any shape created from lines using this function is equivalent to the shape created from the `axlDBCreateOpenShape` and `axlDBCreateShape` functions. This function provides convenient access to features like bridging gaps in lines, which are brought in from external files. It can also round or trim corners the same way as the interactive compose shape tool does.

**语法**：
```skill
axlDBComposeShapesFromLines(
o_dbid/lo_dbids
n_maxGap
n_cornerRadius
t_layer
b_shapeFill
[t_netName]
[b_deleteLines]
)
=> o_dbid/lo_dbids/error string
```

**参数**：
- `o_dbid/lo_dbids`：用于转换的数据库中线条段、线条和铜皮的任意组合。铜皮可能成为其他铜皮中的挖空，等等，基于创建的结果铜皮的嵌套。
- `n_maxGap`：顶点之间的最大气隙，应足够接近以创建闭合铜皮轮廓。此参数对应于 `compose shape` 命令的 `Maximum gap` 选项。如果为 `nil`，则从提供的线段计算值。
- `n_cornerRadius`：如果要圆角，则指定角半径。此参数对应于 `compose shape` 命令的 `Radius` 选项。如果为 `nil`，则不对角进行圆角。
- `t_layer`：要创建铜皮的目标层。
- `b_shapeFill`：`t` 或 `nil`：
  - `t`：创建实心填充铜皮
  - `nil`：创建未填充铜皮
  某些层只允许一种类型的铜皮。如果指定的目标层仅允许一种铜皮填充状态，则忽略此参数，并使用层所需的铜皮类型。
- `[t_netName]`：分配给铜皮的网络。仅在横截面层上创建铜皮时适用。
- `[b_deleteLines]`：`t/nil` 指示是否应删除用于构建铜皮的线条。未纳入铜皮的线条永远不会被删除。

**返回值**：可能返回三种结果之一：
- `o_dbid`：如果仅创建一个铜皮（有或没有挖空），则为单个铜皮 `dbid`。
- `lo_dbids`：如果从提供的线条创建多个铜皮，则为所有铜皮 `dbid` 列表。
- `string`：出错或非法参数时，指示问题的字符串。

**注意**：
某些层对允许的对象有限制。`axlDBComposeShapesFromLines` 函数在从线条创建铜皮时遵守这些限制。例如，未填充的铜皮不能在 PLACE_BOUND_TOP/BOTTOM 层中创建。

DESIGN_OUTLINE 层是唯一的。此层可能只有一个（未填充）铜皮轮廓。如果操作导致多个铜皮，或如果此层上已存在铜皮，则所有其他铜皮都被假定为设计轮廓中的切口，并在 CUTOUT 层上创建。

有关过程的详细信息可在 `axl_compose_shape_from_lines.log` 文件中找到。此文件在开发期间提供调试功能。该文件将被下一次 API 调用覆盖。

**示例**：
```skill
;; 定义路径并作为线条在数据库中创建
path = axlPathStart( list(0:0 0:500 500:500 500:0 0:0))
line = car(axlDBCreatePath(path "DRAWING FORMAT/OUTLINE" 'line))
;; 将线条转换为设计轮廓层上的矩形设计轮廓。
;; 保留原始路径线条在 DRAWING FORMAT 层上以供参考。
outline = axlDBComposeShapesFromLines(line nil nil
  "BOARD GEOMETRY/DESIGN_OUTLINE" nil nil nil)
```

---

### axlDBCreateBoundingShape

**说明**：在一组对象周围创建凸包，也称为边界铜皮。支持凸包的对象是引脚、过孔、邦定指和蚀刻线段。传递给函数的其他对象将从 `lo_dbids` 中过滤掉。

**Original**: Creates a convex hull, also called a bounding shape, around a set of objects. Objects supporting a convex hull are pins, vias, bond fingers, and cline segments. Other objects passed to the function are filtered from the `lo_dbids`.

**语法**：
```skill
axlDBCreateBoundingShape(
lo_dbids
t_padLayer
n_expansion
t_shapeLayer
[t_netName]
[b_deleteExisting]
)
=> list(o_dbid b_drcs)
```

**参数**：
- `lo_dbids`：函数计算和创建凸包的蚀刻线段、过孔、引脚和邦定指。所有其他项从列表中移除。创建凸包至少需要两个项。
- `t_padLayer`：过孔、引脚和邦定指的焊盘层。所有焊盘必须使用相同的层。蚀刻线段可以存在于任何层上。使用指定的常规金属焊盘。
- `n_expansion`：计算凸包时应用到所有对象的扩展量。正值提供焊盘边缘的额外间隙，负值使铜皮保持在焊盘边缘内部。
- `t_shapeLayer`：要创建铜皮的层。
- `[t_netName]`：分配给铜皮的网络。仅在横截面层上创建铜皮时适用。
- `[b_deleteExisting]`：`t/nil`。如果为 `true`，则删除指定目标层上与新边界铜皮重叠的任何铜皮。

**返回值**：
- `list(o_dbid b_drcs)`：铜皮的 `dbid` 和指示是否导致 DRC 的布尔值。
- `nil`：发送给函数的参数错误。

**注意**：凸包表示通过在对象集周围拉伸橡皮筋获得的铜皮轮廓。它的边界不会有入口或凹入部分。它是一个严格正铜皮轮廓。

**示例**：
```skill
;; 选择可见窗口 -500:-500 500:500 中的所有过孔。
axlSetFindFilter(?onButtons list("NOALL" "VIAS") ?enabled list("NOALL" "VIAS"))
axlAddSelectBox(list(-500:-500 500:500));
vias = axlGetSelSet();
;; 在 SOLDERMASK_TOP 层上围绕这些过孔创建边界铜皮，删除任何旧的
;; 阻焊铜皮。
shape = axlDBCreateBoundingShape(vias "ETCH/TOP" 50.0 "BOARD GEOMETRY/SOLDERMASK_TOP" nil t)
```

---

### axlDBCreateOpenShape

**说明**：基于 `o_polygon` 或 `r_path` 的特性创建铜皮。使用 `r_path` 时，填充您指定的参数、层、网络名称和父对象。返回处于打开状态的铜皮的 `dbid`。打开状态意味着您可以添加和删除铜皮的挖空。使用 `o_polygon` 时，创建边界由多边形边界定义的铜皮。多边形中的孔作为挖空添加到铜皮。（请参见 `axlPolyFromDB`。）

铜皮模型使用打开/关闭模型以提高性能。添加不带挖空的铜皮时，可以使用 `axlDBCreateShape`，它隐藏了打开和关闭。添加挖空时，您应该执行以下操作：
```skill
shape = axlDBCreateOpenShape(...)
;; ... 添加挖空 ...
axlDBCreateCloseShape(shape).
```

您可以使用 `axlDBOpenShape` 修改现有铜皮，如下所示：
```skill
axlDBOpenShape(shape <new boundary>)
;; ... 添加或删除挖空 ...
axlDBCreateCloseShape(shape).
```

不允许将带孔的多边形作为输入。当孔作为输入传递时，显示以下警告：`Invalid polygon id argument -<argument>`。

请参见 `axlDBCreateSymDefSkeleton` 关于作为符号定义一部分的铜皮的限制说明。

如果在 ETCH 类上创建铜皮，则创建静态铜皮；如果类是 BOUNDARY，则创建动态铜皮。例如，要在 TOP 层上创建静态铜皮，请设置 `t_layer=ETCH/TOP`。要创建动态铜皮，请设置 `t_layer=BOUNDARY/TOP`。同样的规则也适用于 `axlDBCreateShape`。

**Original**: Creates a shape based on the characteristic of either `o_polygon` or `r_path`. With `r_path`, fills parameters, layer, netname, and parent you specify. Returns the `dbid` of the shape in open state. Open state means you can add and delete voids of the shape. With `o_polygon`, creates a shape with the boundary defined by the boundary of the polygon. The holes in the polygon are added as voids to the shape. (See `axlPolyFromDB`.) The shape model uses the open/close model for performance reasons. While adding a shape without voids, you can use axlDBCreateShape, which hides the open and close. While adding voids you should do the following: shape = axlDBCreateOpenShape(...) ... add voids ... axlDBCreateCloseShape(shape). You can modify an existing shape by using the axlDBOpenShape, as follows: axlDBOpenShape(shape <new boundary>) ... add or delete voids ... axlDBCreateCloseShape(shape). Will not allow hole polygons as input. A static shape is created if you create shape on class ETCH; dynamic shapes are created if class is BOUNDARY. For example, to create a static shape on the TOP layer, make t_layer=ETCH/TOP. To make a dynamic shape, make t_layer=BOUNDARY/TOP. The same rule also applies to `axlDBCreateShape`.

**交叉填充铜皮的填充结构**：
- `l_fill1`：填充类型。
- `[l_fill2]`：（可选）填充类型。当需要超过第二个交叉填充图案时提供。
- `[f_outlineWidth]`：（可选）轮廓宽度必须大于或等于填充宽度。以设计单位指定。默认是当前板交叉填充宽度。仅支持 `o_polygon`，因为 `r_path` 的轮廓宽度应通过 `r_path` defstruct 提供。

其中 `fill_type` 是具有以下成员的 `defstruct`：
- `f_spacing`：交叉填充之间的间距（设计单位）
- `f_width`：交叉填充的宽度（设计单位）
- `l_origin`：交叉填充的原点（相对于板的绝对坐标）
- `f_angle`：交叉填充的角度

**语法**：
```skill
axlDBCreateOpenShape(
o_polygon/r_path
[
l_r_fill
]
[
t_layer
]
[
t_netName
/
o_netdbid
]
[
o_parent
]
)
=> o_shape/nil
```

**参数**：
- `o_polygon/r_path`：来自 `axlPathXXX` 数据结构的 `r_path` 轮廓或来自 `axlPolyXXX` 接口的 `o_polygon`。
- `l_r_fill`：非实心填充铜皮的填充结构（`r_fill`）列表，或：
  - `t` → 实心填充
  - `nil` → 未填充
- `t_layer`：层名称。`nil` 使用默认活动层。
- `t_netname`：网络名称。仅允许添加到蚀刻层的铜皮。
- `o_netdbid`：可以使用网络的 `DBID` 代替网络名称。适用与 `t_netname` 相同的限制。
- `o_parent`：要添加铜皮的对象的 `axl DBID`。使用符号实例，或使用 `nil` 指定设计本身。

**返回值**：
- `o_shape`：铜皮的 `axl DBID`。
- `nil`：未创建铜皮。

**注意**：
- 打开的铜皮可以添加挖空。在调用 `axlDBCreateCloseShape` 之前，不会进行 DRC 检查或填充。
- 路径从 `startPoint` 开始，为 `pathList` 中的每个线段创建线段。如果路径未在 `startPoint` 结束，则视为错误。
- `o_polygons` 列表不被视为有效输入。仅单个 `o_polygon` 是正确的输入。
- 所有路径线段坐标都是绝对的。
- 一次只能有一个铜皮处于打开状态。

**另请参见**：`axlDBActiveShape`，`axlDBOpenShape`，`axlDBCreateVoid`，`axlShapeDeleteVoids`，`axlDBCreateCloseShape`，`axlDBCreateRectangle`，`axlDBCreateShape`，`axlDBCreateVoidCircle`，`axlShapeAutoVoid`，`axlDBCreateFillet`

**示例**：
```skill
;; 使用 rpath 创建铜皮
path = axlPathStart( list( 0:0 400:000 600:400 400:600 0:0))
shp = axlDBCreateOpenShape(path); 默认为实心填充铜皮
;; 除非层仅允许未填充
;; 这是可选的，除非您正在向蚀刻添加铜皮
;; 如果执行 axlDBCreateShape，它会自动为您关闭
axlDBCreateCloseShape(car(shp))

;; 使用 poly 创建铜皮
p1 = axlPolyFromDB(inElem)
;; 将其作为未填充铜皮添加到 BOARD GEOMETRY/OUTLINE
res = axlDBCreateShape( car(p1) nil "BOARD GEOMETRY/OUTLINE")
;; 请参见示例 axldbctshp.il
```

---

### axlDBCreateCloseShape

**说明**：关闭当前打开的铜皮，并应用 `axlDBCreateOpenShape` 中指定的填充图案。然后执行 DRC。如果填充失败，函数返回 `nil`。

**Original**: Closes the current open shape and applies the fill pattern specified in `axlDBCreateOpenShape`. Then performs DRC. If the fill fails, the function returns `nil`.

**语法**：
```skill
axlDBCreateCloseShape(
o_shape
[g_forceShape]
)
=> l_result/nil
```

**参数**：
- `o_shape`：由 `axlDBCreateOpenShape` 创建的打开铜皮的 `dbid`。
- `g_forceShape`：默认情况下，Allegro 在轮廓是矩形时会在其数据库中创建矩形。这是出于性能和空间原因。要覆盖此行为，请在关闭铜皮时传递参数值 `t`。
- `r_fill`：铜皮的填充方式可以与挖空不同。这应该仅用于交叉填充铜皮，并且应使用 2 的幂次方的间距/宽度。我们强烈反对此选项。用于替代 `g_forceShape`。

**返回值**：
- `l_result`：列表：
  - `(car)`：创建的铜皮的 `dbid`。
  - `(cadr)`：如果创建了 DRC 则为 `t`，否则为 `nil`。
- `nil`：未创建任何内容。

**示例**：
请参见创建铜皮接口部分的示例。

---

### axlDBActiveShape

**说明**：返回打开铜皮的 `dbid`（如果有）。

**Original**: Returns the `dbid` of the open shape, if any.

**语法**：
```skill
axlDBActiveShape()
=> o_shape/nil
```

**参数**：无。

**返回值**：
- `o_shape`：由 `axlDBCreateOpenShape` 创建的活动中铜皮的 `dbid`。
- `nil`：没有活动铜皮。

**示例**：
请参见创建铜皮接口部分的示例。

---

### axlDBCreateVoidCircle

**说明**：在打开铜皮 `o_shape` 中创建圆形挖空。在没有打开铜皮的情况下调用此函数会导致错误。

**Original**: Creates a circular void in the open shape `o_shape`. Calling this function without an open shape causes an error.

**语法**：
```skill
axlDBCreateVoidCircle(
o_shape
l_location
[
f_width
]
)
=> o_polygon/nil
```

**参数**：
- `o_shape`：由 `axlDBCreateOpenShape` 创建的打开铜皮的 `dbid`。
- `l_location`：要创建的圆形挖空的中心和半径。参数结构为：`(X:Y R)`。
- `f_width`：交叉填充使用的挖空边缘宽度。默认值为 0。

**返回值**：
- `o_polygon`：创建的圆形挖空的 `dbid`。
- `nil`：由于在没有打开铜皮的情况下调用函数而导致错误。未创建挖空。

**示例**：
请参见创建铜皮接口部分的示例。

---

### axlDBCreateVoid

**说明**：向铜皮添加挖空。要添加多个挖空，建议在创建铜皮时（`axlDBCreateShape`）添加挖空，或重新打开铜皮（`axlDBOpenShape`）再创建挖空。只有某些层（如 ETCH 层）允许铜皮中有挖空。使用 `axlOK2Void` 确定铜皮是否支持挖空。向蚀刻铜皮添加多个挖空时，为了获得最佳性能，首先调用 `axlDBOpenShape`，添加挖空，然后关闭铜皮（`axlDBCreateCloseShape`）。除非希望挖空是永久性的，否则不要向动态铜皮添加挖空。用户添加到动态铜皮的挖空必须放在动态铜皮上，class=BOUNDARY，而不是生成的铜皮，class=ETCH。

**Original**: Adds a void to a shape. To add multiple voids, it is recommended that you either add the voids when creating the shape (`axlDBCreateShape`) or re-open the shape (`axlDBOpenShape`) before creating the voids. Only certain layers, such as ETCH layer, allow voids in a shape. Use `axlOK2Void` to determine if shape supports voids. While adding multiple voids to an etch shape, for best performance, first call `axlDBOpenShape`, add the voids, and then close the shape (`axlDBCreateCloseShape`). Unless you want the void to be permanent, do not add voids to dynamic shapes. User added voids on dynamic shapes must be put on the dynamic shape, with class=BOUNDARY, not on the generated shape, class=ETCH.

**语法**：
```skill
axlDBCreateVoid(
o_shape/nil
r_path/o_polygon
)
=> o_polygon/nil
```

**参数**：
- `o_shape`：打开铜皮的 `dbid`。如果此值为 `nil`，命令使用打开铜皮。
- `r_path`：由 `axlPath` 函数创建的现有路径结构。

**返回值**：
- `o_polygon`：创建的挖空的 `dbid`。
- `nil`：由于在没有打开铜皮的情况下调用函数而导致错误。

**另请参见**：`axlDBCreateShape`，`axlDBOpenShape`，`axlOK2Void`，`axlDBCreateVoidCircle`

**示例**：
请参见创建铜皮接口部分的示例。要向现有铜皮添加，请参见 `axldbctshp.il` 示例代码中的 `dbc_shp_t10` 函数。

---

### axlDBCreateShape

**说明**：接受与 `axlDBCreateOpenShape` 相同的参数，并将 `r_path` 铜皮添加到数据库。区别在于此函数创建铜皮并立即将其放入关闭状态，而不是保持打开以进行修改。使用 `axlDBCreateShape` 添加不带挖空的铜皮。`axlDBCreateShape` 具有与 `axlDBCreateOpenShape` 相同的参数限制。

**Original**: Takes the same arguments as `axlDBCreateOpenShape` and adds the `r_path` shape to the database. The difference is that this function creates the shape and puts it into the closed state immediately, rather than leaving it open for modification. Use `axlDBCreateShape` to add shapes without voids. `axlDBCreateShape` has the same argument restrictions as `axlDBCreateOpenShape`.

**语法**：
```skill
axlDBCreateShape(
o_polygon/r_path
[
l_r_fill
]
[
t_layer
]
[
t_netName
]
[
o_parent
]
)
=> l_result/nil
```

**参数**：
- `o_polygon/r_path`：由 `axlPath` 函数创建的现有路径结构。
- `l_r_fill`：三种可能值之一：
  - `t` → 创建实心填充铜皮
  - `nil` → 创建未填充铜皮
  - 指定创建铜皮的交叉填充参数的结构列表：`defstruct axlFill`（`r_fill`）- 铜皮交叉填充数据；`origin`：任何交叉填充线上的任意点；`width`：浮点数用户单位中的宽度；`spacing`：浮点数用户单位中的间距；`angle`：平行线的角度。与所有 SKILL 的 `defstruct` 一样，使用构造函数 `make_axlFill` 创建 `axlFill` 的实例。使用复制函数 `copy_axlFill` 复制 `axlFill` 的实例。
- `t_layer`：要创建铜皮的层。
- `t_netName`：铜皮要所属的网络名称。
- `o_parent`：铜皮父对象的 `dbid`。父对象是符号实例或设计本身（`nil`）。

**返回值**：
- `l_result`：列表：
  - `(car)`：创建的铜皮的 `dbid`。
  - `(cadr)`：如果创建了 DRC 则为 `t`，否则为 `nil`。
- `nil`：未创建任何内容。

**示例**：
请参见创建铜皮接口部分的示例。

---

### axlDBCreateRectangle

**说明**：创建由 `l_bBox` 指定坐标的矩形。如果未创建矩形，函数返回 `nil`。如果 `t_netname` 非空，则矩形成为该网络的成员。如果矩形未填充，则忽略 `t_netname`。在以下情况下不创建矩形并返回 `nil`（错误）：网络不存在；尝试在需要未填充矩形的 Allegro PCB Editor 层上创建填充矩形；尝试在需要填充矩形的 Allegro PCB Editor 层上创建未填充矩形。请参见 `axlDBCreateSymbolSkeleton` 关于作为符号定义一部分的形状的限制说明。

**Original**: Creates a rectangle with coordinates specified by `l_bBox`. If the rectangle is not created, the function returns `nil`. If `t_netname` is non-null, the rectangle becomes a member of that net. Ignores `t_netname` if the rectangle is unfilled. Does not create the rectangle and returns `nil` (error) in these instances: Net does not exist; Attempt to create a filled rectangle on an Allegro PCB Editor layer requiring an unfilled rectangle; Attempt to create an unfilled rectangle on an Allegro PCB Editor layer requiring a filled rectangle. See `axlDBCreateSymbolSkeleton` for notes about restrictions on shapes that are part of symbol definitions.

**语法**：
```skill
axlDBCreateRectangle(
l_bBox
[
g_fill
]
[
t_layer
]
[
t_netname
]
[
o_parent
]
)
=> l_result/nil
```

**参数**：
- `l_bBox`：矩形的边界框：矩形的左下角和右上角。
- `g_fill`：如果为 `t`，则填充为实心。如果为 `nil`（默认），则矩形未填充。它可能具有可选的线条字体，可能值为 `'SOLID`、`'HIDDEN`、`'PHANTOM`、`'DOTTED`、`'CENTER`。线条字体只能与未填充的形状一起使用。只有某些 Allegro 层支持带字体的未填充铜皮。
- `t_layer`：添加矩形的层。默认是当前活动层。
- `t_netname`：矩形要所属的网络名称。仅当在 Etch 层上添加矩形时，此参数才有意义。
- `o_parent`：矩形要所属的对象的 `dbid`。使用符号实例的 `dbid` 或使用 `nil` 指定设计本身。

**返回值**：
- `l_result`：列表：
  - `(car)`：矩形 `dbid`。
  - `(cadr)`：如果创建了 DRC 则为 `t`，否则为 `nil`。
- `nil`：未创建任何内容。

**示例**：
```skill
;; 未填充的形状，指定层
axlDBCreateRectangle(list(100:100 200:200) nil "BOARD GEOMETRY/OUTLINE")
;; 活动层上的填充形状
axlDBCreateRectangle(list(200:200 400:300) t)
;; ETCH/TOP 上分配给 NET_1 的填充形状，使用用户提供的拾取
axlDBCreateRectangle( axlEnterBox() t "ETCH/TOP" "GND")
;; 指定层上的虚线字体形状
axlDBCreateRectangle(list(400:100 500:300) 'DOTTED "BOARD GEOMETRY/OUTLINE" )
```

---

### axlDBCreateVectorizedEllipse

**说明**：在指定位置创建具有给定参数和椭圆段数的矢量化椭圆。如果未创建椭圆，函数返回 `nil`。如果 `t_netname` 非空，则椭圆成为该网络的成员。`axlDBCreateVectorizedEllipse` 忽略未填充椭圆的 `t_netname`。在以下情况下，函数不创建椭圆并返回 `nil`（错误）：网络不存在；尝试在需要未填充椭圆的 Allegro PCB Editor 层上创建填充椭圆；尝试在需要填充椭圆的 Allegro PCB Editor 层上创建未填充椭圆。请参见 `axlDBCreateSymbolSkeleton` 关于作为符号定义一部分的形状的限制说明。

**Original**: Creates a vectorized ellipse at the specified location, with given parameters and number of ellipse segments. If the ellipse is not created, the function returns `nil`. If `t_netname` is non-null, then the ellipse becomes a member of that net. `axlDBCreateVectorizedEllipse` ignores `t_netname` if the ellipse is unfilled. The function does not create the ellipse and returns `nil` (error) in the following instances: The net does not exist; Attempt to create a filled ellipse on an Allegro PCB Editor layer requiring an unfilled ellipse; Attempt to create an unfilled ellipse on an Allegro PCB Editor layer requiring a filled ellipse. See `axlDBCreateSymbolSkeleton` on notes about restrictions on shapes that are part of symbol definitions.

**语法**：
```skill
axlDBCreateVectorizedEllipse(
l_center
n_radiusA
n_radiusB
n_ccwRotationAngleOfEllipse
n_numSegs
[
g_fill
]
[
t_layer
]
[
t_netname
]
[
o_parent
]
)
=> l_result/nil
```

**参数**：
- `l_center`：椭圆中心的位置。
- `n_radiusA/d_radiusB`：椭圆轴的一半。
- `n_ccwRotationAngleOfEllipse`：椭圆逆时针旋转的角度。
- `n_numSegs`：创建椭圆时使用的线段数。
- `g_fill`：如果为 `t`，则填充为实心。如果为 `nil`（默认），则椭圆未填充。它可能具有可选的线条字体，可能值为 `'SOLID`、`'HIDDEN`、`'PHANTOM`、`'DOTTED`、`'CENTER`。线条字体只能与未填充的形状一起使用。只有某些布局编辑器层支持带字体的未填充形状。
- `t_layer`：添加椭圆的层。默认是当前活动层。
- `t_netname`：此椭圆要所属的网络名称。仅当在 Etch 层上添加椭圆时，此参数才有意义。
- `o_parent`：椭圆要所属的对象的 `dbid`。可以是符号实例的 `dbid` 或设计本身的 `nil`。

**返回值**：
- `l_result/nil`：如果未创建任何内容，则返回 `nil`。否则返回 `l_result` 列表。
- 列表：
  - `(car)`：椭圆 `dbid`
  - `(cadr)` 如果创建了 DRC 则为 `t`，否则返回 `nil`

**示例**：
```skill
;; 未填充的形状，指定层
axlDBCreateVectorizedEllipse(100:100, 100, 55, 0, 22, nil "BOARD GEOMETRY/OUTLINE")
;; 活动层上的填充形状
axlDBCreateVectorizedEllipse(100:100, 100, 55, 0, 14, t)
;; ETCH/TOP 上分配给 NET_1 的填充形状，使用用户提供的拾取
axlDBCreateVectorizedEllipse( 100:100 100.0 55.0 0.0 14 t "ETCH/TOP")
```

---

## 非路径数据库创建函数 (Nonpath DBCreate Functions)

本节描述将非路径图形添加到 Allegro PCB Editor 数据库的 DBCreate 函数。

**Original**: This section describes the DBCreate functions that add nonpath figures to the Allegro PCB Editor database.

---

### axlCreateBondFinger

**说明**：此函数向数据库添加一个有效的、完全实例化的邦定指。通过此接口创建的邦定指可以安全地由线绑定工具集操作，并且也会被数据库的所有方面正确识别（DRC、信号完整性、3D 查看器等）。

**Original**: This function adds a valid, fully-instantiated bond finger to the database. Bond fingers created through this interface can be safely manipulated by the wirebond toolset and will also be properly recognized by all aspects of the database (DRC, signal integrity, 3D viewer, and so on).

**语法**：
```skill
axlCreateBondFinger(
parentSymbol
fingerName
list(fingerLocation fingerRotation fingerPadstack)
list(placementStyle ewlLength fingerSnap fingerAlign)
)
==> dbid/nil
```

**参数**：
- `parentSymbol`：符号的 `dbid`（通常是芯片），在执行移动或删除等操作时，此邦定指应与之关联。
- `fingerName`：可选参数，指定邦定指的名称，存储在 `BOND_PAD` 属性中。
- `fingerLocation/Rotation/Padstack`：正在创建的邦定指的物理信息，位置是数据库坐标点，旋转和角度以度为单位，焊盘是要使用的焊盘的 `dbid`。
- `placementStyle/ewlLength/fingerSnap/fingerAlign`：正在创建的邦定指的放置数据，如下：
  - `placementStyle`：字符串值，以下列表之一：
    - `Orthogonal`
    - `Equal Wire Length`
    - `On Path`
    - `Free Placement`
  - `ewlLength`：Equal Wire Length 样式的长度值，表示走线的期望长度。
  - `fingerSnap`：字符串值，以下列表之一：
    - `Center of Finger`
    - `Finger Origin`
    - `Near End`
    - `Far End`
    - `Nearest Point`
    - `Farthest Point`
  - `fingerAlign`：字符串值，以下列表之一：
    - `Aligned with Wire`
    - `Orthogonal to Die Side`
    - `Orthogonal to Guide`
    - `Pivoting Ortho to Guide`
    - `Average Wire Angle`
    - `Constant Angle`
    - `Match CW Neighbor`
    - `Match CCW Neighbor`

**返回值**：
- `dbid`：如果成功，则返回新创建的邦定指的 `dbid`。
- `nil`：如果发生错误（消息打印到状态窗口）。

---

### axlCreateBondWire

**说明**：此函数向数据库添加一个有效的、完全实例化的邦定线。通过此接口创建的邦定线可以安全地由线绑定工具集操作，并且也会被数据库的所有方面正确识别（DRC、信号完整性、3D 查看器等）。

**Original**: This function adds a valid, fully-instantiated bond wire to the database. Bond wires created through this interface can be safely manipulated by the wirebond toolset and will also be properly recognized by all aspects of the database (DRC, signal integrity, 3D viewer, etc).

**语法**：
```skill
axlCreateBondWire(
parentSymbol
list(wireStartOwner wireStartLocation)
list(wireEndOwner wireEndLocation)
list(wireDiameter wireProfile)
)
==>dbidt/nil
```

**参数**：
- `parentSymbol`：符号的 `dbid`（通常是芯片），在执行移动或删除等操作时，此走线应与之关联。
- `wireStartOwner/Location`：可选。这是一个列表，第一项是走线起点连接到的对象的 `dbid`。如果此对象是引脚或邦定指，位置将从对象的原点派生。如果对象是铜皮，则还必须传递连接的位置。
- `wireEndOwner/Location`：这是一个列表，第一项是走线终点连接到的对象的 `dbid`。如果此对象是引脚或邦定指，位置将从对象的原点派生。如果对象是铜皮，则还必须传递连接的位置。
- `wireDiameter/Profile`：此两个项目的列表描述了走线的 3D 轮廓（字符串）和走线直径（数字）的物理放置。

**返回值**：
- `dbid`：如果成功，则返回新创建的邦定线的 `dbid`。
- `nil`：如果发生错误（消息打印到状态窗口）。

---

### axlDBCreateExternalDRC

**说明**：创建包含参数中给定值的由用户定义的外部 DRC。外部定义的 DRC 标记始终包含两个字符 "X D"。

可以将约束作为传统参数（`t_constraint`）传递，其中它包含约束和预期值在一个字符串中。此方法的缺点是 `show element` 和 `reports` 命令报告预期值为 0。或者，可以将其作为包含两个字符串的列表传递：约束名称和预期值。此格式在 `show element` 和 `reports` 命令中正确报告。

`t_actualValue` 参数是可选的，提供设计单位中的外部定义实际值与 DRC 一起。

在 show element 中：
| SKILL 项 | Show Element | 注释 |
|----------|-------------|------|
| `l_anchorPoint` | Origin xy | 必需值 |
| `t_constraint` | Constraint set | 必需值 |
| `t_type` | Constraint Type | 默认 "EXTERNAL REFERENCE" |
| `t_expectValue` | Constraint value | 默认 "None" |
| `t_actualValue` | Actual Value | 默认 "None" |

属性映射：`t_expectValue` → `EXTERNAL_DRC_VALUE`。

尝试在非 DRC 类上创建 DRC 对象是错误的。您可以在布局编辑器中使用此函数，但不能在符号编辑器中使用。

`t_type` 可用于对相似的 DRC 进行分组。您可以为所有公司编写的 DRC 检查赋予您的公司名称。

**Original**: Creates an externally-defined (by user) DRC containing the values given in the arguments. An externally defined DRC marker always has the two characters "X D" in it. You may pass the constraint as the traditional argument (`t_constraint`) where this contains both the constraint and expected value in a one string. The downside of this method is that the `show element` and `reports` commands report 0 for the expected value. Alternatively, you can pass it as a list containing two strings: constraint name and expected value. This format reports properly in both the `show element` and `reports` commands. The `t_actualValue` argument is optional and provides an externally-defined actual value with the DRC in design units. Attempting to create a DRC object on a non-DRC class is an error. You can use this function in the layout editor, but not in the symbol editor. `t_type` can be used to group similar DRCs. You might give all of your company written DRC checks your company name.

**语法**：
```skill
axlDBCreateExternalDRC(
t_constraint/lt_constraint
l_anchor_point
t_layer
[
lo_dbid
]
[
l_secondPoint
]
[
t_actualValue
]
)
=> l_result/nil
```

**参数**：
- `t_constraint`：违反约束的名称。字符串包含约束类型和所需值及比较。
- `lt_constraint`：替代方法。它是 `(t_constraint t_expectValue)` 的列表。
- `l_anchor_point`：DRC 标记的坐标。
- `t_layer`：DRC 标记的层。这必须包含 DRC 错误类或仅子类名称。
- `lo_dbid`：导致 DRC 的对象的可选列表（最多两个）。
- `l_secondPoint`：第二个参考点。这是 DRC 对中没有 DRC 标记的对象上的坐标。使用此点，您可以通过在后续过程中读取 DRC 数据来识别导致 DRC 的第二个对象。
- `t_actualValue`：导致 DRC 的实际值。

**返回值**：
- `l_result`：列表：
  - `(car)`：创建的 DRC 的 `dbid`（始终只有一个）
  - `(cadr)`：始终为 `t`（将来，如果 DRC 是新的则为 `t`，如果 DRC 已存在则为 `nil`）
- `nil`：未创建任何内容。

**示例**：
```skill
;; 在 x,y (1500, 1800) 处创建用户定义的 DRC 标记，标记违反用户规则：
;; "Line to Pin--MY SPACING RULE"
;; 所需值为 12，实际值为 10。

;; 原始方法：
axlDBCreateExternalDRC( "MY Spacing Line to Pin/req:12" 1500:1800 "drc error calss/top", nil, nil, "10 MILS")

;; 新的方法，更好的 show element 和 reports 命令行为：
axlDBCreateExternalDRC('("My Spacing Line to Pin" "12")
  1500:1900 "top", nil nil "10 MILS")

;; 名称分类
axlDBCreateExternalDRC(
  '("My Spacing Line to Pin" "12" "Cadence")
  1500:2000 "top", nil nil "10 MILS")

;; 在 (1500 1800) 和 (1500 1900) 处添加 "X D" DRC 标记。
;; DRC 标记使用 show element 命令显示以下信息：
;; LISTING: 1 element(s)
;; < DRC ERROR >
;; Class: DRC ERROR CLASS
;; Subclass: ALL
;; Origin xy: (1500,1800)
;; CONSTRAINT: Externally Determined Violation
;; CONSTRAINT SET: NONE
;; CONSTRAINT TYPE: LAYOUT
;; Constraint value: 0 MIL
;; Actual value: 10 MILS
;; Properties attached to drc error
;; EXTERNAL_VIOLATION_DESCRIPTION = Line to Pin--MY SPACING
;; RULE/req:12; actual:10
```

---

### axlDBCreateFillet

**说明**：向对象添加焊盘填充形状。请参见 `axlDBCreateOpenShape` 对第一个参数的描述。提供的铜皮必须接触父对象的连接点。不能直接选择 T 形连接。必须选择连接的蚀刻线并使用 `axlDBGetConnect`（基本模式）找到感兴趣的 T 形连接。蚀刻线可能在任一端有 T 形连接。创建焊盘填充失败的典型原因：对象必须存在于层上（对于过孔或引脚，它必须跨越对象）；它必须接触或重叠对象的连接点；蚀刻线不能是热焊盘。

**Original**: Adds a fillet shape to the object. See `axlDBCreateOpenShape` for description of the first argument. The provided shape must touch the connect point of the parent object. Tees cannot be directly selected. You must select a cline that it is connected and use `axlDBGetConnect` (basic mode) to find the Tee of interest. The cline may have a Tee on either end. Typical reasons for failure to create a fillet are: The object must exist on the layer (in case of vias or pins it must span the object); It must touch or overlap the connect point of the object; The cline must not be a thermal.

**注意**：
- 要删除焊盘填充，请使用 `axlDeleteFillet`。
- 如果修改了焊盘填充对象，焊盘填充将自动移除。
- 如果添加多个焊盘填充，请使用 `axlDBCloak`。
- 使用此 API 创建的焊盘填充将在 Allegro 中报告为焊盘填充。
- 焊盘填充可能导致 DRC。
- 不支持部分焊盘填充类型。
- 不能在符号编辑器中添加焊盘填充。
- 可以通过设置 `axlDebug(t)` 返回有关失败的额外信息。

**语法**：
```skill
axlDBCreateFillet(
o_polygon/r_path
t_layer
o_filletObject
)
=> l_result/nil
```

**参数**：
- `o_polygon/r_path`：来自 `axlPathXXX` 数据结构的 `r_path` 轮廓或来自 `axlPolyXXX` 接口的 `o_polygon`。
- `t_layer`：层名称。必须是蚀刻层，且父对象必须存在于该层上。
- `o_filletObject`：要添加焊盘填充的对象的 `axl DBID`。必须是过孔、引脚或 T 形连接。

**返回值**：
- `l_result/nil`：如果未创建，或包含以下内容的列表：
  - `(car)`：焊盘填充形状的 `axl DBID`
  - `(cadr)` 如果创建了 DRC 则为 `t`，否则为 `nil`。

**另请参见**：`axlDBCreateOpenShape`，`axlDBGetConnect`，`axlDeleteFillet`

---

### axlDBCreatePin

**说明**：在位置 `l_anchorPoint` 添加具有焊盘 `t_padstack` 和引脚名称 `r_pinText` 的引脚，并旋转 `f_rotation` 度。

**注意**：
1. 此接口只能在符号编辑器中使用。
2. 仅在封装和机械符号图纸中使用 `axlDBCreatePin`。在任何其他类型的图纸中创建引脚会导致错误。
3. 使用 `nil` 作为 `r_pinText` 以创建机械引脚。

**Original**: Adds a pin with padstack `t_padstack`, pin name `r_pinText` at location `l_anchorPoint`, and rotated by `f_rotation` degrees. Notes: 1) This interface may only be used in the Symbol Editor. 2) Use `axlDBCreatePin` only in package and mechanical symbol drawings. Creating a pin in any other type of drawing causes errors. 3) Use `nil` for `r_pinText` to create a mechanical pin.

**语法**：
```skill
axlDBCreatePin(
t_padstack/o_padstackDbid
l_anchorPoint
r_pinText/nil
[
f_rotation
]
)
=> l_result/nil
```

**参数**：
- `t_padstack`：过孔的焊盘名称。如果布局中不存在具有此名称的焊盘定义，函数将按 `PADPATH` 指定的库顺序搜索并将其加载到数据库中。
- `o_padstackDbid`：焊盘 `dbid`。
- `l_anchorPoint`：添加引脚的布局坐标。
- `r_pinText`：引脚编号文本结构：
  ```skill
  defstruct axlPinText ;(r_pinText) - pin number text data
    number ;pin number as a text string
    offset ;offset (X:Y) for pin number text
    text) ;textOrientation - ;for positioning text
  ```
  这需要 `axlTextOrientation` 结构：
  ```skill
  defstruct axlTextOrientation
    ;;(r_textOrientation) - description of the orientation of text
    textBlock ;string - text block name
    rotation ;rotation in floatnum degrees
    mirrored ;t-->mirrored, nil --> not mirrored,
             ;'GEOMETRY --> only geometry is mirrored
    justify) ;"left", "center", "right"
  ```
  与所有 SKILL 的 `defstruct` 一样，使用构造函数 `make_axlPinText` 创建 `axlPinText` 的实例，使用 `make_axlTextOrientation` 创建 `axlTextOrientation` 的实例。请参见创建铜皮接口部分的示例。使用 `copy_axlPinText` 复制 `axlPinText` 的实例，使用 `copy_axlTextOrientation` 复制 `axlTextOrientation` 的实例。
- `f_rotation`：引脚旋转（度）。

**返回值**：
- `l_result`：列表：
  - `(car)`：引脚的 `dbid`。
  - `(cadr)`：如果创建了 DRC 则为 `t`，否则为 `nil`。
- `nil`：未创建任何内容。

**示例**：
```skill
;; 以下示例将引脚 "1"、"2"、"3" 和一个机械引脚添加到封装符号图纸。
;; 引脚 "1" 具有方形焊盘，旋转 45 度，
;; 引脚 "2" 和 "3" 具有圆形焊盘，引脚 "3" 的引脚文本镜像。
mytext = make_axlTextOrientation(
  ?textBlock 6, ?rotation 60.0
  ?mirrored nil ?justify "center")
mypin = make_axlPinText(?number "1",
  ?offset 0:75, ?text mytext)
axlDBCreatePin( "pad1" 0:0 mypin 45.0)
mytext->justify = "left"
mytext->rotation = 0.0
mypin->number = 2
mypin->offset = -125:0
axlDBCreatePin( "pad0" -100:-100 mypin)
mytext->rotation = -45.0
mytext->justify = "right"
mytext->mirror = t
mypin->number = 3
mypin->offset = 50:0
axlDBCreatePin( "pad0" 100:-100 mypin)

;; 2) 使用循环创建 8 个引脚
x=1000.0
y=1000.0
myText = make_axlTextOrientation(?textBlock 6
  ?justify "center")
myPin= make_axlPinText(?offset 0:0 ?text myText)
for(i 1 8
  y=y-100
  sprintf(buf "a%d" i)
  myPin->number = buf
  axlDBCreatePin("VIA" x:y myPin)
)
```

---

### axlDBCreateSymbol

**说明**：在设计中放置符号实例。在给定的镜像和旋转下，在位置 `l_anchor_point` 创建符号实例。检查其第一个参数以确定要添加的符号，如下所述。接下来，在符号定义中搜索符号，首先在布局中，然后在 `PSMPATH` 中。如果布局中不存在定义，则加载定义。如果找不到符号定义，则返回 `nil`。不要在符号编辑器中使用此函数。

**Original**: Places a symbol instance in the design. Creates a symbol instance at location `l_anchor_point` with the given mirror and rotation. Examines its first argument to determine what symbol to add, as explained later. Next, searches for the symbol in the symbol definitions, first in the layout, then in the `PSMPATH`. Loads the definition if it is not already in the layout and creates the symbol instance. Returns `nil` a symbol definition is not found. Do not use this function in the symbol editor.

**语法**：
```skill
axlDBCreateSymbol(
t_refdes
l_anchorPoint
[
g_mirror
]
[
f_rotation
]
[t_embeddedLayer]
)
=> l_result/nil

axlDBCreateSymbol(
l_symbolData
l_anchorPoint
[
g_mirror
]
[
f_rotation
]
[t_embeddedLayer]
)
=> l_result/nil
```

**参数**：
第一个参数可以是 `t_refdes` 或 `l_symbolData`，如下所述：

- `t_refdes`：元件的参考位号。如果这是第一个参数，函数在布局中查找具有该 refdes 的元件，查找其元件器件类型所需的封装符号，添加元件定义规定的符号名称的封装符号，并将该 refdes 分配给符号（例如，refdes U1 需要 `DIP14` 封装符号）。如果找不到给定的 refdes，则返回 `nil`。
- `l_symbolData`：如果这是第一个参数，函数查找此结构指定的符号、符号类型和 refdes。`l_symbolData` 是一个列表 `(t_symbolName [[t_symbolType [t_refdes]]])`，其中：
  - `t_symbolName` 是符号的名称（例如 `DIP14`）
  - `t_symbolType` 是符号类型：`"PACKAGE"`（默认）、`"MECHANICAL"` 或 `"FORMAT"`
  - `t_refdes` 是可选的 refdes；如果 `t_refdes` 存在，`t_symbolType` 必须是 `"PACKAGE"`。
  
  示例是列表：`("DIP16" "package" "U6")`
  
  要创建具有替代符号的元件（即与元件库中指定的符号不同的符号），请使用 `l_symbolData` 结构。例如，refdes `C7` 可能是一个需要顶层安装封装 `"CAP1206F"` 的电容器。但是，您的设计需要在布局底部使用替代封装 `"CAP1206B"`。要创建镜像的元件，请使用带有 `l_symbolData` 参数的 `axlDBCreateSymbol`：`("CAP1206B" "package" "C7")`。

- `l_anchorPoint`：指定创建符号位置的布局坐标。
- `g_mirror`：
  - `nil`：创建未镜像。（默认）
  - `t`：创建镜像符号。
  - `'GEOMETRY`：几何镜像。
- `f_rotation`：符号旋转（度）。（默认值为 0）
- `t_embeddedLayer`：放置在嵌入式层上。层必须启用嵌入式。镜像选项被忽略。层可以是完全限定的（`"ETCH/GND"`）或仅子类（`"GND"`）。不能使用顶层或底层。

**返回值**：
- `nil`：未创建任何内容。
- `l_result`：包含以下内容的列表：
  - `(car)`：创建的符号的 `axl DBID`
  - `(cadr)`：如果创建了 DRC 则为 `t`，否则为 `nil`。
- 使用图纸中的符号定义。如果图纸中不存在，则搜索符号库并加载定义。

**示例**：
```skill
axlDBCreateSymbol("y29", 5600:4600)
=>(dbid:423143 nil)
;; 创建具有分配 refdes 的符号。
axlDBCreateSymbol( list( "dip14" "package"), 5600:4600)
=>(dbid:423144 nil)
;; 创建具有未分配 refdes 的符号，仅通用 U*：

;; 典型的元件驱动符号放置：
p = axlDBCreateSymbol("U1" 2175:1000)
;; 放置嵌入式元件。假设层 SIGNAL_2 已启用嵌入式。
p = axlDBCreateSymbol("R1" 2175:1000 nil nil "SIGNAL_2")
;; 放置非逻辑封装符号，旋转 90 度
p = axlDBCreateSymbol('("R_0402" "PACKAGE") 2000:800.1 nil 90.0)
```

---

### axlDBCreateSymbolSkeleton

**说明**：在 `l_anchorPoint` 放置骨架或最小符号实例，给定镜像和旋转，但实例中没有数据，除了 `l_pinData` 给定的引脚数据。这是定义所有引脚数据的 `axlPinData` `defstruct` 列表。引脚数量和引脚编号必须与库符号定义匹配。符号定义必须存在于数据库或 `LIBPATH` 上。

与 `axlDBCreateSymbol` 类似，但除了实例中的符号引脚外，不添加任何符号数据。用于创建符号的"基础"。然后使用 `axlDBCreate` 函数根据需要添加线条、铜皮、多边形和文本。

例如，用于从其他以不同方式定义符号实例的 CAD 系统转换的符号构建 Allegro PCB Editor 中的符号。

AXL-SKILL 仅在 `l_pinData` 中的 `axlPinData` 实例应用于其 `number` 指定的引脚。（请参见下面的 `l_pinData` 参数描述。）`l_pinData` 的 `nil` 值表示 `axlDBCreateSkeleton` 按照库定义中的方式添加引脚。您可以有选择地自定义不自定义、一个或任意数量的创建的符号实例的引脚。

不要在符号编辑器中使用此函数。

此函数面向对 Allegro PCB Editor 数据库模型具有高级知识的程序员。它提供了在 Allegro PCB Editor 中创建符号的强大方法。虽然您可以使用此命令创建非传统符号，但 Allegro PCB Editor 的其余部分可能不会像您期望的那样运行。为确保符号像传统符号一样运行，您必须确保您创建的内容遵守符号规则。例如，您可以创建一个没有附加图形的符号。Allegro PCB Editor 的 Find 工具将无法找到它。另一位程序员可能使用此功能创建临时符号实例作为占位符。通过交互，用户将此符号转换为传统的 Allegro PCB Editor 符号。

**Original**: Places a skeleton or a minimal symbol instance at `l_anchorPoint` with mirror and rotation given but no data in the instance, except the pin data given by `l_pinData`. This is a list of `axlPinData` defstructs defining the data for all pins. The pin count and pin numbers must match that of the library symbol definition. The symbol definition must exist in the database or on `LIBPATH`. Behaves like `axlDBCreateSymbol`, except that it adds no symbol data except the symbol pins in the instance. Use to create the "foundation" of a symbol. Then build, using `axlDBCreate` functions to add lines, shapes, polygons, and text as required. Use, for example, to construct symbols when translated from other CAD systems that define symbol instances in different ways than Allegro PCB Editor. AXL-SKILL applies each `axlPinData` instance in `l_pinData` only to the pin specified by its `number`. (See the description of the `l_pinData` argument below.) A `nil` value for `l_pinData` means `axlDBCreateSkeleton` adds the pins as they are in the library definition of the symbol. You can selectively customize none, one, or any number of the pins of the symbol instance you create. Do not use this function in the symbol editor. This function is intended for programmers with a high level of knowledge of the Allegro PCB Editor database model. It provides a powerful method for creating symbols within Allegro PCB Editor. Although you can use this command to create non-conventional symbols, the rest of Allegro PCB Editor may not behave as you expect. To ensure a symbol behaves as a conventional symbol, you must ensure that what you create abides by symbol rules. For example, you can create a symbol with no attached graphics. Allegro PCB Editor's Find utility will not be able to find it. Another programmer may use this feature to create a temporary symbol instance as a placeholder. Through interaction, the user changes this symbol into a conventional Allegro PCB Editor symbol.

**语法**：
```skill
axlDBCreateSymbolSkeleton(
t_refdes
l_anchorPoint
g_mirror
f_rotation
l_pinData
[t_embeddedLayer]
)
=> l_result/nil

axlDBCreateSymbolSkeleton(
l_symbolData
l_anchorPoint
g_mirror
f_rotation
l_pinData
[t_embeddedLayer]
)
=> l_result/nil
```

**参数**：
第一个参数可以是 `t_refdes` 或 `l_symbolData`，如下所述：
- `t_refdes`：如果这是第一个参数，函数在布局中查找具有该 refdes 的元件，查找其元件器件类型所需的封装符号，添加元件定义规定的符号名称的封装符号，并将该 refdes 分配给符号（例如，refdes U1 需要 `DIP14` 封装符号）。如果找不到给定的 refdes，则返回 `nil`。
- `l_symbolData`：如果这是第一个参数，函数查找此结构指定的符号、符号类型和 refdes。`l_symbolData` 是一个列表 `(t_symbolName [[t_symbolType [t_refdes]]])`，其中：
  - `t_symbolName` 是符号的名称（例如 `DIP14`）
  - `t_symbolType` 是符号类型：`"PACKAGE"`（默认）、`"MECHANICAL"` 或 `"FORMAT"`
  - `t_refdes` 是 refdes；如果 `t_refdes` 存在，`t_symbolType` 必须是 `"package"`
  
  列表示例：`("DIP16" "package" "U6")`
  
  要创建具有替代符号的元件（即与元件库中指定的符号不同的符号），请使用 `l_symbolData` 结构。例如，refdes `C7` 是一个需要顶层安装封装 `"CAP1206F"` 的电容器。您的设计需要在布局底部使用替代封装 `"CAP1206B"`。要创建镜像的元件，请使用带有 `l_symbolData` 参数的 `axlDBCreateSymbol`：`("CAP1206B" "package" "C7")`。

- `l_anchorPoint`：创建符号位置的布局坐标。这将是符号的原点。
- `g_mirror`：
  - `nil`：创建未镜像（默认）。
  - `t`：创建镜像符号。
  - `'GEOMETRY`：几何镜像。
- `f_rotation`：符号旋转角度（度）。`nil` = 0.0。
- `l_pinData`：任何需要从库定义不同的引脚的 `axlPinData` `defstruct` 列表，如下所示：
  ```skill
  defstruct axlPinData;(r_pinData) - pin data
    number ;pin number as a text string
    padstack ;padstack for the pin (text string)
    origin ;relative location (X Y) of the pin
    rotation) ;relative rotation of pin in degrees
  ```
  注意：与所有 SKILL 的 `defstruct` 一样，使用构造函数 `make_axlPinData` 创建 `axlPinData` 的实例。使用复制函数 `copy_axlPinData` 复制 `axlPinData` 的实例。
- `t_embeddedLayer`：放置在嵌入式层上。层必须启用嵌入式。镜像选项被忽略。层可以是完全限定的（`"ETCH/GND"`）或仅子类（`"GND"`）。不能使用顶层或底层。

**返回值**：
- `l_result`：
  - `nil`：未创建任何内容。
  - 包含以下内容的列表：
    - `(car)`：创建的符号的 `axl DBID`
    - `(cadr)`：如果创建了 DRC 则为 `t`，否则为 `nil`。

**示例**：
```skill
mypins = list( make_axlPinData( ?number "2",
  ?padstack "pad1", ?origin -100:-100 ?rotation 45)
  make_axlPinData( ?number "4", ?padstack "pad1",
  ?origin -100:-300 ?rotation 45)
  make_axlPinData( ?number "6", ?padstack "pad1",
  ?origin -100:-500 ?rotation 45)
  make_axlPinData( ?number "9", ?padstack "pad1",
  ?origin 200:-500 ?rotation 45)
  make_axlPinData( ?number "11", ?padstack "pad1",
  ?origin 200:-300 ?rotation 45)
  make_axlPinData( ?number "13", ?padstack "pad1",
  ?origin 200:-100 ?rotation 45))
axlDBCreateSymbolSkeleton( list("dip14"),
  5600:4600, nil, 0, mypins)
=>(dbid:426743 nil)
;; 添加一个 DIP14 符号，所有偶数引脚具有与引脚 1 相同的焊盘，旋转 45 度，偏移 -100 mils。
```

---

### axlDBCreateText

**说明**：使用描述中的参数在布局中创建文本字符串。

**Original**: Creates a text string in the layout using the arguments described.

**语法**：
```skill
axlDBCreateText(
t_text
l_anchorPoint
r_textOrientation
[
t_layer
]
[
o_attach
]
)
=> l_result/nil
```

**参数**：
- `t_text`：要添加的文本字符串。`axlDBCreateText` 接受嵌入文本中的换行符。每个换行符导致函数创建新文本行作为单独的数据库对象。函数返回它创建的所有文本行的 `dbids`。`axlTextOrientation` 结构中指定的 `textBlock` 参数块指定多行文本之间的间距。
- `l_anchorPoint`：添加文本的位置布局坐标。
- `r_textOrientation`：`axlTextOrientation` 结构：
  ```skill
  defstruct axlTextOrientation
    ;;(r_textOrientation) - description of
    ;; the orientation of text
    textBlock ;string - text block name
    rotation ;rotation in floatnum degrees
    mirrored ;t-->mirrored, nil --> not mirrored,
             ;'GEOMETRY --> only geometry is mirrored
    justify) ;"left", "center", "right"
  ```
  注意：与所有 SKILL 的 `defstruct` 一样，使用构造函数 `make_axlTextOrientation` 创建 `axlTextOrientation` 的实例。使用复制函数 `copy_axlTextOrientation` 复制 `axlTextOrientation` 的实例。
- `t_layer`：要添加文本的层名称。
- `o_attach`：文本必须附加到的对象的 `DBID`，或使用 `nil` 表示设计。

**返回值**：
- `l_result`：否则函数返回列表：
  - `(car)`：创建的文本 `DBIDs` 列表，每个输入文本行一个
  - `(cadr)`：如果创建了 DRC 则为 `t`，否则函数返回 `nil`。
- `nil`：未创建任何内容。

**注意**：
- 如果 `o_attach` 是符号实例，则文本是"独立的"，但它是符号实例的子对象。
- 如果 `t_text` 字符串包含换行符，则将创建多个文本记录（并返回多个 `DBIDs`）。

**另请参见**：`axlTextOrientationCopy`，`axlDBChangeText`

**示例**：
```skill
;; 以下示例添加文本字符串 "Chamfer both sides"，居中、镜像并旋转 60 度。
myorient = make_axlTextOrientation(?textBlock "8", ?rotation 60.0,
  ?mirrored t, ?justify "center")
ret = axlDBCreateText( "Chamfer both sides", 7600:4600,
  myorient, "board geometry/plating_bar", nil)
==> (dbid:526743 nil)
;; 添加文本字符串 "Chamfer both sides" 居中、镜像并旋转 60°。
```

---

### axlDBCreateVia

**说明**：按照下面描述的参数在布局中创建过孔。

**Original**: Creates a via in the layout as specified by the arguments described below.

**语法**：
```skill
axlDBCreateVia(
t_padstack/o_padstackDbid
l_anchorPoint
[
t_netName
]
[
g_mirror
]
[
f_rotation
]
[
o_parent
]
)
=> l_result/nil
```

**参数**：
- `t_padstack`：过孔的焊盘名称。如果布局中不存在具有此名称的焊盘定义，函数将按 `PADPATH` 指定的库顺序搜索并将其加载到数据库中。
- `o_padstackDbid`：焊盘 `dbid`。
- `l_anchorPoint`：创建过孔的位置布局坐标。
- `t_netName`：过孔要所属的网络名称；`nil` → 过孔是独立的。
- `g_mirror`：
  - `t` → 创建镜像过孔。
  - `nil` → 创建未镜像过孔。
  - `'GEOMETRY` → 仅过孔几何镜像。过孔层不镜像。
  - `'LAYERS` → 仅过孔层镜像。过孔几何不镜像。
- `f_rotation`：过孔旋转角度（度）。
- `o_parent`：要附加过孔的对象的 `axl DBID`。使用符号实例或使用 `nil` 指定设计本身。

**返回值**：
- `l_result`：列表：
  - `(car)`：创建的过孔的 `axl DBID`。
  - `(cadr)`：如果创建了 DRC 则为 `t`，否则为 `nil`。
- `nil`：未创建任何内容。

**注意**：`axlDBCreateVia` 不能创建测试点。您必须使用 `axlTestPoint` 函数创建测试点。

**示例**：
```skill
myvia = axlDBCreateVia( "pad1", 5600:4200,
  "sclkl", t, 45.0, nil)
=> (dbid:526745 nil)
;; 在 x5600 y4200 处使用焊盘 "pad1" 添加独立过孔，在 "sclkl" 网络上，镜像并旋转。
;; 添加旋转 45 度的过孔：
```

---

### axlDBCreateSymbolAutosilk

**说明**：为指定符号创建或更新 `AUTOSILK` 信息（根据需要）。还根据需要更新符号附近的任何其他 `AUTOSILK` 信息。

**Original**: Creates or updates the `AUTOSILK` information for the specified symbol, as required. Also updates, as required, any other `AUTOSILK` information near the symbol.

**语法**：
```skill
axlDBCreateSymbolAutosilk(
o_symbol
)
=> t/nil
```

**参数**：
- `o_symbol`：符号的 `dbid`。

**返回值**：
- `t`：提供了有效的符号 `dbid`。
- `nil`：提供的 `dbid` 不是有效符号。

---

### axlDBCreateViaStructure

**说明**：验证参数并使用设计中的指定参数添加结构实例。检出 Allegro 数据库 ID。

**Original**: Verify arguments and add the structure instance with specified parameters in the design. Check out the Allegro database id.

**语法**：
```skill
axlDBCreateViaStructure(
t_refdes/o_vsDbid
l_anchorPoint
[t_netName/o_netDbid]
[g_mirror]
[f_rotation]
[g_snapFlag]
)
==> l_result/nil
```

**参数**：
- `t_refdes`：结构符号名称。
- `o_vsDbid`：结构符号参考。
- `t_netName`：返回路径网络名称。
- `o_netDbid`：返回路径网络参考。
- `l_anchorPoint`：结构的位置。
- `g_mirror`：
  - `nil`：未镜像（默认）
  - `t`：结构镜像
- `f_rotation`：旋转角度（度）（默认值为 0 度）。
- `g_snapToLocation`：指定结构是否需要捕捉到该位置的对象，假设它共享公共层（捕捉到引脚、过孔、悬空蚀刻线）。如果捕捉到结构，则继承从捕捉对象的连接性。
  - `nil`：结构未捕捉（默认）
  - `t`：结构已捕捉

**返回值**：
- `l_result`：列表：
  - `(car)`：创建的所有符号的 `DBID` 列表。
  - `(cadr)`：如果创建了 DRC 则为 `t`，否则为 `nil`。
- `nil`：如果未创建。

**示例**：
```skill
;; 典型的结构放置：
p = axlDBCreateViaStructure("VS1" 2175:1000)
;; 放置具有返回路径的高速过孔结构
p = axlDBCreateViaStructure("VS2" 2175:1000 "Vss")
;; 放置具有 90 度旋转和捕捉的标准过孔结构
p = axlDBCreateViaStructure("VS3" 2000:800 nil nil 90.0 t)
```

---

### axlCreateWirebondGuide

**说明**：此函数向设计添加线绑定引导路径，然后可用于通过线绑定工具将邦定指对齐。

**Original**: This function adds a wirebond guide path into the design, which can then be used to snap fingers through the wirebond tools.

**语法**：
```skill
axlCreateWirebondGuide(
r_path
)
==> dbid/nil
```

**参数**：
- `r_path`：由 `axlPath` 函数先前创建的直线和圆弧段组成的现有路径。

**返回值**：
- `dbid`：如果成功，则返回新创建的引导路径的 `dbid`。
- `nil`：如果发生错误（消息打印到状态窗口）。

---

### axlZoneCreate

**说明**：使用名称 `t_name` 和 `o_dbidOutline` 创建区域。应使用 `axlZoneAccess` API 将区域轮廓和关联铜皮修剪到设计和区域轮廓。如果区域铜皮与设计轮廓或其他区域铜皮重叠，Allegro PCB Editor 的行为是未定义的。

建议创建区域的步骤：
1. 在 RIGID_FLEX/ZONE_OUTLINE 类和子类上创建区域轮廓铜皮
2. 使用 `axlZoneCreate` 创建区域
3. 使用 `axlZoneAccess` 设置特性，包括关联的叠层
4. 使用 `axlZoneAccess` 修剪区域铜皮

**副作用**：DRC 标记为过期；创建附加区域名称的文本；轮廓不能修改或删除；区域允许完整放置。

**Original**: Creates a zone with the name `t_name` and with `o_dbidOutline`. Should use the `axlZoneAccess` API to trim the zone outline and associated shapes to the design and zone outlines. The behavior of Allegro PCB Editor is undefined if zone shapes overlap the design outline or other zone shapes. Recommended steps to create a zone: Create zone outline shape on RIGID_FLEX/ZONE_OUTLINE class and subclass; Create a zone using `axlZoneCreate`; Set the characteristics including the associated stackup using `axlZoneAccess`; Trim the zone shapes using `axlZoneAccess`. Side effects: DRC is marked out of date; Creates attached text with zone name; Outline cannot be modified or deleted; Zone allows full placement.

**语法**：
```skill
axlZoneCreate(
t_name
o_dbidOutline
)
==> o_zoneDbid/nil
```

**参数**：
- `t_name`：区域名称。
- `o_dbidOutline`：轮廓（铜皮），class==RIGID_FLEX 且 subclass==ZONE_OUTLINE。

**返回值**：
- `t`：如果成功。
- `nil`：如果失败。

**另请参见**：`axlZoneSet`，`axlZoneDelete`，`axlZoneAccess`

`axlDBGetDesign()->zone` 返回设计的所有区域列表。

**示例**：
```skill
;; 创建区域（假设在 class==RIGID_FLEX 和 subclass==ZONE_OUTLINE 上存在铜皮（dbid））
axlDBCreateZone("MY_ZONE" shape)
```

---

## 属性函数 (Property Functions)

本节描述用于创建您自己的（用户定义的）属性定义以及向数据库对象添加属性的 DBCreate 函数。

**Original**: This section describes the DBCreate functions you use to create your own (user-defined) property definitions, and add properties to database objects.

---

### axlDBCreatePropDictEntry

**说明**：使用给定属性创建 Allegro 用户定义属性字典条目。创建字典条目后，可以将属性附加到对象。

STRING 属性值限制为 1024。STRING_ID 允许属性值最大为 4096。STRING_ID 目前在 Allegro PCB Editor 的 "define property" 对话框中不受支持。

如果需要在数据库中存储更大的数据，请使用附件（`axlCreateAttachment`）。

**Original**: Creates an Allegro user-defined property dictionary entry with given attributes. Once a dictionary entry is created, the property can then be attached to objects. STRING property values are limited to 1024. STRING_ID allows property values up to 4096. STRING_ID is not currently supported in "define property" dialog of Allegro PCB Editor. If you need to store larger data within the database, use attachments (`axlCreateAttachment`).

**语法**：
```skill
axlDBCreatePropDictEntry(
t_name
t_type
lt_objects/t
[
ln_range
]
[
t_units
]
[
g_hidden
]
)
)
=> od_propDictEntry/nil
axlDBCreatePropDictEntry(
nil
)
==> lt_availbeObject
```

**参数**：
- `t_name`：属性名称。必须与设计中所有其他属性名称不同，包括 Allegro PCB Editor 预定义和用户定义的属性名称。
- `t_type`：属性值的数据类型。合法值为：
  - 典型：`BOOLEAN`、`INTEGER`、`REAL`、`STRING`、`DESIGN_UNITS`。
  - 其他支持类型：`ALTITUDE`、`CAPACITANCE`、`DISTANCE`、`ELEC_CONDUCTIVITY`、`FAILURE_RATE`、`IMPEDANCE`、`INDUCTANCE`、`LAYER_THICKNESS`、`NAME`、`NOISE_VOLTAGE`、`PERCENTAGE`、`PROP_DELAY`、`RESISTANCE`、`TEMPERATURE`、`THERM_CONDUCTANCE`、`THERM_CONDUCTIVITY`、`THERM_RESISTANCE`、`VOLTAGE`、`VELOCITY`、`STRING_ID`。
- `lt_objects`：表示此属性可以添加到的对象类型的字符串列表。（使用 `axlDBGetPropDictEntry(nil)` 获取有效对象列表）。如果仅允许单个对象类型，则可以将其指定为字符串，而不是包含一个字符串的列表。如果此值为 `t`，则允许所有属性。
- `ln_range`：属性（数值）的最低和最高合法值列表。如果第一个值为 `nil`，则表示负无穷。如果第二个值为 `nil`，则表示正无穷。
- `t_units`：要与数据类型（`t_type`）一起使用的文本字符串，如 `STRING`、`INTEGER` 或 `REAL`。
- `g_hidden`：`t` 属性对用户隐藏。隐藏属性不会显示在任何 Allegro UI 中，如约束管理器、Show Element 或属性编辑。隐藏属性可以通过 SKILL 访问。通常，如果属性仅意味着在 SKILL 程序之外更改，则隐藏属性。隐藏属性也可以通过 `extracta` 可见。

**返回值**：
- `o_propDictEntry`：创建的属性字典条目的 `DBID`。
- `nil`：属性未创建。

**另请参见**：`axlDBAddProp`，`axlCreateAttachment`

**示例**：
```skill
;; 添加类型为字符串的新属性，支持所有数据库对象
propDoct = axlDBCreatePropDictEntry("ACME" "STRING" t)
;; 创建 MYPROP 作为实数属性，范围 -50 到 100，单位为 "level"，
;; 可附加到引脚、网络和符号。
axlDBCreatePropDictEntry( "myprop", "real", list( "pins" "nets" "symbols"),
  list( -50. 100), "level")
=> propDict:2421543
;; 要检查：
;; 从 Allegro PCB Editor 中，选择 Setup - Property Definitions。
;; Define User Properties 窗口出现。
;; 从 Available Properties 列表中选择 MYPROP。
```

---

### axlDBAddProp

**说明**：将 `ll_name_value` 中列出的属性/值对添加到 `lo_attach` 中列出的对象数据库 `DBID` 中。如果对象不接受 `ll_name_value` 中的属性名称，`axlDBAddProp` 将忽略该组合并继续。如果对象已附加了特定属性，`axlDBAddProp` 将用 `ll_name_value` 中指定的值替换其原始值。如果发生任何错误或 `axlDBAddProp` 未添加或更改任何属性，函数返回 `nil`。

**Original**: Adds the property/value pairs listed in `ll_name_value` to the object database DBIDs listed in `lo_attach`. If an object does not accept a property name in `ll_name_value`, `axlDBAddProp` ignores that combination, and continues. If an object already has the specific property attached, `axlDBAddProp` replaces its original value with the one specified in `ll_name_value`. If any errors occur or if `axlDBAddProp` has not added or changed any properties, the function returns `nil`.

**语法**：
```skill
axlDBAddProp(
lo_attach
ll_name_value
)
=> l_result/nil
```

**参数**：
- `lo_attach`：要添加 `ll_name_value` 中列出的属性/值组合的 Allegro PCB Editor 对象 `dbid` 列表。`nil` 列表表示附加到设计（`(list nil)`）。但是，如果 `lo_attach` 为 `nil`，则没有附加对象，`axlDBAddProp` 不执行任何操作，返回 `nil`。
- `ll_name_value`：属性名称/属性值对列表。如果列表的第一个元素不是列表，`axlDBAddProp` 将 `ll_name_value` 视为单个名称-值列表，并将值分配给该名称的属性。每个名称-值对的第一个元素是属性名称（字符串）。每个名称-值列表的第二个元素是属性值。属性值是包含或不包含单位的字符串，或简单值（固定或浮点数）。无论哪种情况，如果未显式包含单位，`axlDBAddProp` 将使用系统 `units.dat` 文件中指定的单位。布尔属性没有值，属性要么存在于对象上，要么不存在。`axlDBAddProp` 忽略布尔属性的值，只需将属性添加到对象。如果查询布尔属性的值，如果属性存在则返回 `t`。您可以为布尔属性调用 `axlDBAddProp`，仅传递属性名称；例如，`(list "fixed")`。为布尔属性调用 `axlDBAddProp` 并传递值 `nil` 仍会将属性添加到对象。例如，`axlDBAddProp('(dbid) '("fixed" nil))` 将固定属性添加到对象。如果稍后查询该对象上的 "fixed" 值，即使最初指定的值是 `nil`，它也会返回值 `t` 以指示属性存在。要使布尔属性查询返回 `nil`，请使用 `axlDBDeleteProp` 从对象中删除属性。STRING 类型属性允许将值设置为 `t` 或 `nil`，即使这些不是字符串值。`t` 是字符串 "TRUE" 的别名，而 `nil` 是字符串 "FALSE" 的别名。例如，`axlDBAddProp((list nil) (list "COMMENT" t))` 将为设计对象添加值为 "TRUE" 的 COMMENT 属性。尝试将任何其他属性类型设置为 `t` 或 `nil` 将产生错误。即使 STRING 属性支持将值设置为 "TRUE" 或 "FALSE"，Cadence 强烈建议不要使用 STRING 属性来表示布尔值。STRING 类型属性的访问和测试速度比 BOOLEAN 属性慢，并且在数据库中需要更多存储空间。因此，使用 STRING 属性存储布尔值可能会导致性能问题。

**返回值**：
- `l_result`：列表：
  - （第一个元素）至少成功添加一个属性的对象的 `dbids` 列表。
  - （第二个元素）始终为 `nil`。
- `nil`：未添加属性。

**另请参见**：`axlDBDeleteProp`，`axlDBCreatePropDictEntry`，`axlDBGetPropDictEntry`，`axlDBGetProperties`，`axlDBDeletePropAll`，`axlDBDeletePropDictEntry`，`axlDBGetPropDict`

**示例**：
请参见 `axlDBDeleteProp`。

---

## 加载和保存函数 (Load and Save Functions)

本节描述将外部对象添加到 Allegro PCB Editor 数据库的加载函数。

**Original**: This section describes the Load functions that add external objects to the Allegro PCB Editor database.

---

### axlLoadPadstack

**说明**：通过尝试在现有数据库中按名称查找焊盘来加载焊盘。如果失败，Allegro PCB Editor 会查看磁盘上的焊盘库。

**Original**: Loads a padstack by attempting to find the padstack by name in the existing database. Failing that, Allegro PCB Editor looks in the pad library on the disk.

**语法**：
```skill
axlLoadPadstack (
t_padname
)
=> o_dbid
```

**参数**：
- `t_padname`：焊盘名称。如果从磁盘加载，Allegro PCB Editor 使用 `PADLIB` 路径变量查找焊盘。焊盘名称限制为 20 个字符。

**返回值**：
- `o_dbid`：加载的焊盘的 `dbid`。
- `nil`：未找到任何内容。

**示例**：
```skill
pad = axlLoadPadstack (VIA)
;; 加载 VIA 焊盘。
```

---

### axlLoadSymbol

**说明**：在数据库中搜索指示的符号。如果不存在，则搜索 `PSMPATH` 并将其加载到数据库中。在符号编辑器中，这只能用于与焊盘一起使用的形状和机械符号。

如果符号定义未使用（`dbid->instance` 为 `nil`），则删除该定义。这种未使用符号的删除发生在保存图纸、刷新符号、手动放置等过程中。这意味着如果数据库作为 `axlRunBatchDBProgram` 的一部分保存，则未使用的 `symdefs` 将被删除。

`FLASH` 和 `SHAPE` 符号在使用这些符号的焊盘加载时自动加载。此接口允许加载这些符号类型以分析这些符号类型的内容，因为您不能使用 `extracta` 程序。

**注意**：`axlDBCreateSymbol` 也会在需要时加载符号定义。您不需要此 API 来放置符号。您可以通过 `axlDeleteObject` 删除未使用的 `symdefs`。

**Original**: Searches for indicated symbol in database. If not present, searches PSMPATH and loads the symbol into the database. In the symbol editor, this can only be used for shape and mechanical symbols for use with padstacks. If a symbol definition is not in use (`dbid->instance` is nil) then the definition is deleted. This deletion of unused symbols occurs during save drawing, refresh symbol, place manual among other places. This means the database is saved as part of axlRunBatchDBProgram then the unused symdefs will be deleted. FLASH and SHAPE symbols are loaded automatically when a padstack using those symbols is loaded. This interface allows loading of these symbol types to allow analysis of the contents of these symbols types since you cannot use the extracta program. Notes: `axlDBCreateSymbol` also loads the symbol definition if required. You do not need this API to place symbols. You can delete unused symdefs via `axlDeleteObject`.

**语法**：
```skill
axlLoadSymbol(
t_symKind
t_symName
)
-> o_dbidSymDef/nil
```

**参数**：
- `t_symkind`：`"PACKAGE"`、`"MECHANICAL"`、`"FORMAT"`、`"SHAPE"` 或 `"FLASH"`（不区分大小写）。
- `t_symName`：符号名称（小写）。这是符号的根名称，不要包含扩展名（例如 `.psm`）或目录路径。

**返回值**：
- `dbid`：符号定义。
- `nil`：找不到符号，未知符号类型，符号类型与符号不匹配，找不到符号引脚所需的焊盘，或符号版本太旧。

**另请参见**：`axlDBCreateSymbol`

**示例**：
```skill
symdef = axlLoadSymbol("package" "dip14")
```

---

### axlPadstackToDisk

**说明**：将板焊盘保存到库中。

**Original**: Saves a board padstack out to a library.

**语法**：
```skill
axlPadstackToDisk(
[
t_padName
]
[
t_outPadName
]
)
=> t/nil
```

**参数**：
- `t_padName`：要保存到库的焊盘名称。
- `t_outPadName`：输出焊盘名称。

**返回值**：
- `t`：焊盘已创建。
- `nil`：创建焊盘失败。

**示例**：
```skill
;; 转储布局中的所有焊盘。
axlPadstackToDisk()
;; 将布局中的焊盘 "pad60cir36d" 转储为 "pad60cir36d.pad"。
axlPadstackToDisk("pad60cir36d")
;; 将布局中的焊盘 "pad60cir36d" 转储为 "mypadstack.pad"。
axlPadstackToDisk("pad60cir36d" "mypadstack")
```

---

### axlRefreshSymbol

**说明**：从磁盘上的文件刷新符号，该文件由当前 `PSMPATH` 定位。工作方式与 `refresh_symbol` 功能相同，但更新一个符号定义。与 `refresh_symbol` 不同，这不支持重置自定义钻孔选项，因为这是在焊盘级别而不是符号级别完成的。
1. 如果更新多个符号，请使用 `axlDBCloak` 以获得最佳性能和最小内存使用。
2. 要忽略 `FIXED` 属性，请参见 `axlDBIgnoreFixed`。

**Original**: Refreshes a symbol from file on disk which is located by current PSMPATH. Works the same as the refresh_symbol functionality except updates one symbol definition. Unlike refresh_symbol this does not support the reset custom drill option since this is done at the padstack level not the symbol level. 1) If updating multiple symbols use `axlDBCloak` for best performance and minimal memory use. 2) To ignore the FIXED property see `axlDBIgnoreFixed`.

**语法**：
```skill
axlRefreshSymbol(
t_symName/o_SymDef
[g_options]
)
==> t/nil
```

**参数**：
- `t_symName`：现有符号名称。
- `o_SymDef`：符号定义 `dbid`。
- `g_options`：可用选项：
  - `'text`：重置文本位置。
  - `'fanout`：重置扇出（如果设计有扇出，则删除它们）。默认是仅当磁盘符号有扇出时才删除扇出。
  - `'keepPadstack`：保留实例编辑的焊盘。

**返回值**：
- `o_SymDef`：刷新后的 `symdef`。
- `nil`：失败；通常如果无法在磁盘上找到符号或存在 `FIXED` 属性。

**示例**：
```skill
;; 更新 DIP14 并重置文本位置
axlRefreshSymbol("DIP14" 'text)
;; 更新数据库根目录下的第一个符号定义，并设置文本和引脚逃逸选项
symdef = axlDBGetDesign()->symdefs
axlRefreshSymbol(car(symdef) '(text fanout))
```

**另请参见**：`axlDBCloak`，`axlDBIgnoreFixed`，`axlReplacePadstack`
