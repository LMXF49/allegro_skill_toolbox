# 5. 交互编辑 (Interactive Edit)

**产品文档**：Allegro SKILL Reference  
**产品版本**：17.4-2019, October 2019

## 概述 (Overview)

本章描述基本的数据库编辑函数 `axlDeleteObject` 和 `axlDBDeleteProp`。还介绍了 `axlShowObject`，可用于显示对象的数据信息。

**Original**: This chapter describes the basic database edit functions `axlDeleteObject` and `axlDBDeleteProp`. It also describes `axlShowObject`, which you can use to display the data about an object.

`axlDeleteObject` 不允许删除 Allegro PCB Editor 的逻辑或参数对象。此外，某些图形或属性对象可能被标记为 `readOnly`。`axlDeleteObject` 会忽略具有该属性的对象。Allegro PCB Editor 创建的 DRC 标记是 `readOnly` 图形对象的示例。AXL 程序不能直接修改 DRC 对象。

**Original**: `axlDeleteObject` does not allow you to delete Allegro PCB Editor logical or parameter objects. Also, certain figure or property objects may be marked `readOnly`. `axlDeleteObject` ignores objects with that property. DRC markers created by Allegro PCB Editor are an example of `readOnly` Allegro PCB Editor figure objects. An AXL program cannot modify DRC objects directly.

---

## AXL/SKILL 交互编辑函数 (AXL/SKILL Interactive Edit Functions)

本节列出交互编辑函数。

**Original**: This section lists interactive edit functions.

### axlAllShapesMerge

**说明**：合并所有铜皮，合并前将所有动态铜皮修改为静态铜皮。

**Original**: Merge all shapes, modify all dynamic shapes to static before merge.

**语法**：
```skill
axlAllShapesMerge(
l_mode
l_layer
)
==> nil
```

**参数**：
- `l_mode`：
  - `0`：合并所有铜皮
  - `1`：合并所有动态铜皮（合并前转换为静态铜皮）
  - `2`：合并所有静态铜皮
- `l_layer`：
  - `-1`：合并所有层上的所有铜皮
  - `n`：合并层 "n" 上的所有铜皮（n >= 0）

**返回值**：`nil`

**示例**：
```skill
;; 合并所有铜皮
axlAllShapesMerge(0 nil)
;; 合并所有动态铜皮
axlAllShapesMerge(1 nil)
```

---

### axlBondFingerDelete

**说明**：删除传入的（列表）邦定指。可选择同时删除连接的邦定线元素。

**Original**: Deletes the (list of) bond fingers passed in. Optionally, it will delete the connect bond wire elements as well.

**语法**：
```skill
axlBondFingerDelete(
bondFingers
deleteWires
)
==> t/nil
```

**参数**：
- `bondFingers`：一个 `dbid` 或 `dbid` 列表，表示要删除的邦定指。
- `deleteWires`：`t/nil`，告知系统是否应删除连接到邦定指的邦定线。

**返回值**：
- `t`：已删除一个或多个对象。
- `nil`：未删除对象。

**Original**: Value is `t` returned, if one or more objects are deleted; otherwise the return value is `nil`.

---

### axlBondWireDelete

**说明**：删除传入的（列表）邦定线。可选择同时删除连接的邦定指元素。

**Original**: Deletes the (list of) bond wires passed in. Optionally, it will delete the connect bond finger elements as well.

**语法**：
```skill
axlBondWireDelete(
bondWires
deleteFingers
)
==> t/nil
```

**参数**：
- `bondWires`：`dbid` 或 `dbid` 列表，表示要删除的邦定线。
- `deleteFingers`：
  - `t`：删除连接到邦定线的邦定指。
  - `nil`：不删除连接的邦定指。

**返回值**：
- `t`：已删除一个或多个对象。
- `nil`：未删除对象。

**Original**: Value is `t` returned, if one or more objects are deleted; otherwise the return value is `nil`.

---

### axlChangeLine2Cline

**说明**：将提供的线条（line）转换为蚀刻线（cline）。不在蚀刻层上的线条将被忽略。如果线条被转换为蚀刻线，则它可能被分配到一个网络；否则它将留在独立分支上。

**Original**: Changes provided lines to clines. Lines not on an etch layer are ignored. If a line is converted to a cline then it may be assigned to a net, otherwise it will be left on a the standalone branch.

**语法**：
```skill
axlChangeLine2Cline(
lo_dbid/o_dbid
)
==> x_cnt/nil
```

**参数**：
- `lo_dbid/o_dbid`：单个 `dbid` 或线条 `dbid` 列表。

**返回值**：
- `t`：成功。
- `nil`：失败。

**失败原因**（调试时设置 `axlDebug(t)` 可查看额外信息）：
- `dbid` 不是线条或不在 ETCH 类的线条。
- 线条被锁定（LOCKED）或固定（FIXED）。

**示例**：
```skill
;; 转换一条线条
res = axlDBCreateLine('(0:0 100:100) 5 "ETCH/TOP")
res = car(res)
cnt = axlChangeLine2Cline(res)
```

**另请参见**：`axlTransformObject`

---

### axlChangeLineFont

**说明**：更改线条或线段的字体。

**Original**: Changes font on a line or segment.

**语法**：
```skill
axlChangeLineFont(
o_dbid
x_newFont
)
==> lo_dbid/nil
```

**参数**：
- `o_dbid`：一个线条 `dbid`。
- `x_newFont`：新字体。有效值为：
  - `'SOLID`
  - `'HIDDEN`
  - `'PHANTOM`
  - `'DOTTED`
  - `'CENTER`
  - `nil` 与 `SOLID` 相同。

**失败原因**：
- `dbid` 不是蚀刻线、线条或线条/蚀刻线的线段。
- 非法选项类型。
- 变换后的对象超出数据库范围。

**示例**：
```skill
;; 将线条字体更改为隐藏（hidden）
;; ashOne 是位于 <cdsroot>/share/pcb/examples/skill/ash-fxf/ashone.il 的选择工具
dbid = ashOne()
;; 选择一条线条、蚀刻线或线段（设置查找过滤器）
updatedDbid = axlChangeLineFont(dbid 'hidden)
```

**另请参见**：`axlTransformObject`，`axlChangeLayer`，`axlChangeWidth`

---

### axlChangeWidth

**说明**：更改线条、蚀刻线和线段（圆弧和直线）的宽度。默认情况下，仅更改可见线条。这允许通过临时更改可见层来进行层过滤。如果需要覆盖此行为，请将可选变量 `g_invisible` 设置为 `t`。如果需要更改多条线条的宽度，将 `dbid` 列表传递给此函数比为每个 `dbid` 单独调用效率更高。此函数不支持更改铜皮边框的宽度。

**Original**: Changes width of lines, clines and segments (arc and line). By default, only visible lines are changed. This allows layer filtering by temporary changing the visible layers (see example in `axlVisibleUpdate`). If you wish to override this behavior then set the value of the optional variable `g_invisible` to `t`. If you need to change the width of multiple lines, it is more efficient to pass them as a list of `dbids` than to call this function for each `dbid`. This function does not support change in the width of shape borders.

**语法**：
```skill
axlChangeWidth(
lo_dbid/o_dbid
f_newWidth
[g_invisible]
)
==> lo_dbid/nil
```

**参数**：
- `lo_dbid/o_dbid`：单个 `dbid` 或 `dbid` 列表。
- `f_newWidth`：线条的新宽度。
- `g_invisible`：如果为 `t`，对象不需要在显示上可见即可更改宽度。

**返回值**：宽度对象列表，或失败时返回 `nil`。

**失败原因**：
- `dbid` 不是蚀刻线、线条或线条/圆弧线段。
- 非法选项类型。
- 变换后的对象超出数据库范围。

**示例**：
```skill
;; 将蚀刻线宽度更改为当前数据库单位下的 20
;; ashOne 是位于 <cdsroot>/pcb/examples/skill/ash-fxf/ashone.il 的选择工具
dbid = ashOne()
;; 选择一条线条、蚀刻线或线段（设置查找过滤器）
updatedDbid = axlChangeWidth(dbid, 20.0)
```

**另请参见**：`axlTransformObject`，`axlChangeLayer`

---

### axlCopyProperties

**说明**：从一个对象复制属性到另一个对象。它会过滤某些属性。如果需要复制属性，建议使用此接口而不是自行实现。复制属性时可能会产生副作用。

**Original**: This copies properties from one object to another. It filters certain properties. If you need to copy properties suggest you utilize this interface instead doing it yourself. Side effects may happen when properties are copied.

**过滤的属性包括**：
- `IDX` 系列
- `IDF_OWNER`
- `CLIP_DRAWING`
- `FIXED`
- `FIXED_PRIVATE`
- `DYN_SHAPE_PRIORITY`
- `SUBNET_NAME`（仅当铜皮不在 ETCH 上时）

此外，如果属性不符合目标元素的规则（例如对元素类型不合法），则可能不会复制。
目标对象上的现有属性将被保留，但可能会被源对象的属性覆盖。

**语法**：
```skill
axlCopyProperties(
o_destDbid
o_srcDbid
)==> t/nil
```

**参数**：
- `o_destDbid`：属性的目标对象。
- `o_srcDbid`：属性的源对象。

**返回值**：
- `t`：对象为 `dbid`。
- `nil`：一个或多个对象不是 `dbid`。

**另请参见**：`axlCopyObject`

---

### axlCopyObject

**说明**：使用此函数复制数据库对象。支持的功能与 `axlTransformObject` 相同，但它可以复制和变换一个或多个对象。一个额外支持的选项是 `retainNet`。此选项仅适用于过孔。如果该选项的值设置为 `t`，复制时保留过孔的网络；`nil` 允许过孔在新位置连接到其接触的任何对象。在电路板中，不支持引脚。数据库对象的属性和文本也会被复制。另请参阅 `axlTransformObject` 的注意事项。

**Original**: Use this function to copy the database object(s). This supports the same functionality as `axlTransformObject` except it copies and transforms one or more objects. One additional option supported is retainNet. This only applies to vias. If the value of this option is set to `t`, the net of the via is retained on copy, `nil` allows the via to connect to whatever it touches at the new location. In the board, pins are not supported. Properties and text attached to the database object are also copied. Also see `axlTransformObject` cautions.

**语法**：
```skill
axlCopyObject(
lo_dbid/o_dbid
?move           l_deltaPoint
?mirror         t/nil
?angle          f_angle
?origin         l_rotatePoint
?allOrNone      t/nil
?retainNet      t/nil
)
==> t/nil
```

**参数**：
- `lo_dbid/o_dbid`：单个 `dbid` 或 `dbid` 列表。
- `l_deltaPoint`：可选移动距离。
- `mirror`：可选镜像对象。
- `f_angle`：可选旋转角度。
- `l_rotatePoint`：可选旋转点。
- `allOrNone`：如果为 `t` 且是一组对象，则变换必须对所有对象成功，否则失败。
- `retainNet`：`t/nil`（仅适用于过孔）。

**返回值**：变换后的对象列表，或失败时返回 `nil`。

如果需要复制一组对象，使用对象组调用此函数比单独传递每个 `dbid` 性能要好得多。

**示例**：
```skill
ldbid = list of database objects
dbid = one database object

;; 情况 1：复制一组对象，垂直移动 1000 数据库单位
r = axlCopyObject(ldbid, ?move '1000.0:0.0)

;; 情况 2：复制并旋转对象 45 度
r = axlCopyObject(dbid, ?angle 45)

;; 情况 3：绕旋转点复制并旋转对象
r = axlCopyObject(dbid, ?angle 45 ?origin 100:100)
```

**另请参见**：`axlTransformObject`，`axlDBCloak`，`axlCopyProperties`

---

### axlDBAltOrigin

**说明**：返回 `dbid` 的替代中心点。这提供了对 `move` 命令中选项选项卡原点选项的 SKILL 访问。它主要用于符号实例（会将元件实例转换为其符号）。符号的体原点规则如下，按顺序满足第一个规则：
- `PACKAGE_GEOMETRY/BODY_CENTER` 层上文本的原点
- `PACKAGE_GEOMETRY`（PLACE_BOUND_TOP、PLACE_BOUND_BOTTOM、DFA_BOUND_TOP、DFA_BOUND_BOTTOM）和 `EMBEDDED_GEOMETRY`（PLACE_BOUND 和 DFA_BOUND）层上所有铜皮的联合范围框的中心
- 符号边界框的中心

可以传入其他 Allegro 图形 `dbid`，但可能不支持所有选项。例如，CLINE 支持 `center` 选项，但不支持 `'origin` 或 `'pin1`。

**Original**: Returns alternative center for a `dbid`. This provides SKILL access to the `move` command's origin point option in the Options tab. It is intended for symbols instances (it will convert a component instance to its symbol). Body origin rules for symbols, origin is the first rule that is met: the origin of text on the PACKAGE_GEOMETRY/BODY_CENTER layer; the center of an extent box created by the union of all shapes on layers PACKAGE_GEOMETRY (PLACE_BOUND_TOP, PLACE_BOUND_BOTTOM, DFA_BOUND_TOP, DFA_BOUND_BOTTOM) and EMBEDDED_GEOMETRY (PLACE_BOUND and DFA_BOUND); center of the symbol bbox. Other Allegro figure `dbids` can be supplied, but all options may not be supported. For example, a CLINE supports the center option, but not `'origin` or `'pin1`.

**语法**：
```skill
axlDBAltOrigin(
g_mode
o_dbid
)=> xy/nil
```

**参数**：
- `g_mode`：
  - `'center` 选项返回对象的体中心。
  - `'origin` 选项返回对象的原点（通常如果 `dbid` 有 `xy` 属性，这是相同的坐标）。对于符号，板原点可以通过 `PACKAGE_GEOMETRY/BODY_CENTER` 层上文本的原点设置。
  - `'pin1` 选项返回 pin1 作为中心。
- `o_dbid`：一个图形（几何对象）`dbid`。

**返回值**：
- `xy`：请求的位置。
- `nil`：不是 `dbid`，`dbid` 不是图形 `dbid`，或模式不支持该对象。

**另请参见**：`axlDBGetSymbolBodyExtent`

**示例**：
```skill
;; ashOne 工具在示例 SKILL 代码中提供
sym = ashOne()
;; 在 Find 过滤器中选择符号并选择一个符号
sym->xy
;; 打印 (3503.0 1058.0)
axlDBAltOrigin('origin sym)
;; 打印 (3503.0 1058.0) -- 符号原点与 xy 相同
axlDBAltOrigin('center sym)
;; 打印 (3250.0 1737.0)
axlDBAltOrigin('pin1 sym)
;; 打印 (3503.0 1058.0) -- pin1 与 x 相同
```

---

### axlDBChangeText

**说明**：修改布局中文本字符串的特性。要保留文本的当前设置，将参数 `t_text` 和 `r_textOrientation` 设置为 `nil`。要移动文本，请使用 `axlTransformObject`。

对于重命名参考位号（refdes），这与编辑文本的工作方式相同，它会检查 `HARD_LOCATION` 属性，如果存在该属性，则不会重命名 refdes。如果要忽略此属性，请使用 `axlRenameRefdes`。

**Original**: Modifies the characteristics of a text string in the layout. To keep current settings on the text, set the arguments, `t_text` and `r_textOrientation`, to `nil`. To move text use the `axlTransformObject` object. For renaming refdes this works the same as edit text in that it checks for the HARD_LOCATION property and will not rename refdes if this property is present. If you want to ignore this property, use `axlRenameRefdes`.

**语法**：
```skill
axlDBChangeText(
o_dbid
t_text
[r_textOrientation/x_textBlock]
)
==> l_result/nil
```

**参数**：
- `o_dbid`：文本的数据库 ID。
- `t_text`：文本字符串。如果设置为 `nil`，则保留文本的当前设置。
- `r_textOrientation`：文本方向。`nil` 值表示保留当前设置。请参见结构说明。
- `x_textBlock`：如果仅更改文本块，则指定此参数。

**结构说明**：
`axlTextOrientation` 结构如下：
```skill
defstruct axlTextOrientation
r_textOrientation ; 文本方向
textBlock; 字符串，指定文本块名称
rotation; 浮点数变量，指定旋转角度（度）
mirrored; 可能值：
  t: 镜像
  nil: 未镜像
  GEOMETRY: 仅几何镜像
justify; 支持值：left, center, right
```

如果修改了其中任何参数，则需要为所有参数提供值。未更改的参数，请从现有文本 `dbid` 复制值。

与所有 SKILL 的 `defstruct` 一样，使用构造函数 `make_axlTextOrientation` 创建 `axlTextOrientation` 的实例。要复制实例，请使用 `copy_axlTextOrientation`。

**返回值**：
- `nil`：未创建。
- `l_result`：列表包含：
  - `(car)`：文本的 `dbid` 列表
  - `(cadr)`：如果创建了 DRC 则为 `t`，否则为 `nil`。

请勿传递带有换行符的文本字符串作为参数。

**另请参见**：`axlTransformObject`，`axlChangeLayer`，`axlRenameRefdes`，`axlTextOrientationCopy`

**示例**：
```skill
;; 示例文本在 axlDBCreateText 中添加
text = car(ret)

;; 更改文本
cret = axlDBChangeText(text "Chamfer neither sides")

;; 更改文本块
cret = axlDBChangeText(text nil 4)

;; 更改旋转和文本
axlTextOrientationCopy(text myorient)
myorient->rotation = 0.0
cret = axlDBChangeText(text "New text" myorient)
```

---

### axlDBConnectItem

**说明**：将未连接的蚀刻线末端（路径）连接到附近的引脚或过孔。它基本上执行器件连接，将蚀刻线连接到过孔。默认情况下，如果陷阱（trap）不存在或为 `nil`，则使用蚀刻线宽度构造一个 2 * 宽度的搜索框。如果蚀刻线末端位于焊盘上或焊盘内，这通常足以建立连接。如果搜索框内有多个焊盘，它将使用距离未连接末端最近的焊盘，基于焊盘的原点。要建立连接，它可能：
- 延伸线段
- 添加新线段
- 缩短线段（如果线段穿过焊盘的连接点但未建立连接，则发生此情况）。这种情况较少见。

**Original**: Connects an unconnected cline end (path) to close by pins or vias. It basically does a device connectivity to connect clines to vias. By default, if trap is absent or nil use the cline width to construct a search box of 2 * width. This is normally sufficient if the cline ends on the pad or within the pad to make a connection. If there are multiple pads within the search box it will use the closest pad to the unconnect end based on the origin of the pad. To achieve a connection it may: extends a segment; adds a new segment; shortens a segment (occurs if the segment crosses the pad's connect point and does not make a connection). This is atypical.

**注意**：
- 当前不考虑网络。未来版本可能会考虑网络。
- 如果更改许多蚀刻线，请将操作放在 `axlDBCloak` 中。
- 建议使用默认的 `trapSize`。较大的值可能会降低性能。

**语法**：
```skill
axlDBconnectItem(
o_dbid
[x-trapSize]
)
=> x_count/nil
```

**参数**：
- `o_dbid`：`dbid`，路径（蚀刻线）。
- `x_trapSize`：可选大小，以设计单位查找。默认使用蚀刻线宽度构造一个宽度 * 2 的框。陷阱大小限制为线宽的 4 倍。

**返回值**：
- `nil`：非法参数。
- `x_count`：建立的连接数。可以是 `0`（无额外连接）或 `1` 或 `2` 个新连接。

**另请参见**：`axlDBGetConnect`

**示例**：
```skill
;; 使用示例层次结构中的 "ash" 示例软件
cline = ashOne('("NOALL" "CLINES"))
ret = axlDBConnectItem(cline)
```

---

### axlDeleteObject

**说明**：从数据库中删除单个或数据库对象列表。删除元件也会删除其符号所有者。删除网络仅删除逻辑，保留物理对象。命令允许通过 ripup 选项撕裂关联的蚀刻。

除网络外，对象将在删除前被擦除。仅网络的鼠尾线（Ratsnests）被擦除。网络的其他部分不会被擦除，因为没有 ripup。如果网络处于高亮状态，它将被取消高亮。

还允许删除以下参数记录：
- 底片（artwork films）：可以删除单个底片和所有底片。如果删除所有底片，则下次打开底片对话框时将自动填充默认底片。
- 子类（subclasses）：子类必须为空且可合法删除（不能删除 PIN 子类）。

在删除参数记录的情况下，当前限制是仅传递该单个对象。请勿尝试传递多个参数对象或将它们与非参数对象混合。

**Original**: Deletes single or list of database objects from database. Deletion of components deletes the symbol owner as well. Deletion of nets is LOGIC only, and leaves the physical objects. Command allows for rip-up of associated etch via the ripup option. Except for Nets, objects will be erased before they are deleted. Only the Net's Ratsnests is erased. Other parts of a Net will not be erased because there is no ripup. If a Net is in a highlighted state, it will be dehighlighted. Also allows deletion of the following parameter records: artwork (films); subclasses.

**语法**：
```skill
axlDeleteObject(
o_dbid/lo_dbid
[g_mode]
)
=> t/nil
```

**参数**：
- `o_dbid/lo_dbid`：`dbid` 或要删除的 `dbid` 列表。
- `g_mode`：可选删除选项：
  - `ripup`：启用蚀刻撕裂选项（与 Allegro 删除命令的 ripup 选项相同）。

**返回值**：
- `t`：从布局中删除一个或多个对象。
- `nil`：未从布局中删除对象。

如果传递了元件或网络 `dbid`，将删除逻辑。这与 Allegro `delete` 命令不同，后者会删除与逻辑关联的物理对象（网络的金线/过孔和元件的符号）。要模拟 Allegro `delete` 命令的行为，请使用 `axlSetFindFilter` 选择并设置对象选择，并将 `equivlogic` 参数传递给 `?enabled` 选项。

**示例**：
```skill
;; 以下示例循环 axlSelect 和 axlDeleteObject，删除用户交互选择的对象。
(defun DelElement ()
  let ((mypopup)
    "Delete selected Objects"
    mypopup = axlUIPopupDefine(nil
      '(("Done" axlFinishEnterFun)
        ("Cancel" axlCancelEnterFun)))
    axlUIPopupSet(mypopup)
    axlSetFindFilter(?enabled '("ALL" "EQUIVLOGIC") ?onButtons '("ALL"))
    while( axlSelect() axlDeleteObject(axlGetSelSet()))
    axlUIPopupSet( axlUIPopupDefine(nil nil))
  ))

;; 以下删除 TOP 底片记录
p = axlGetParam("artwork:TOP")
axlDeleteObject(p)

;; 以下删除所有底片
axlDeleteObject(axlGetParam("artwork"))
```

---

### axlDeleteByRectangle

**说明**：此函数相对于提供的矩形框（`g_windowDelete`）从设计中移除元素。该框由框对边上的两个点定义，框的边缘将与 x 和 y 轴平行。`g_windowSelect` 是另一个用于选择要删除项的框。它是工具中 `Manufacture - Drafting - Delete by Rectangle` 命令的 SKILL 访问接口。

该接口通过删除提供矩形内部或外部的所有对象来操作。对于穿过所提供窗口边缘的元素，对象在该处被切割。这意味着仅覆盖矩形顶部的铜皮部分将被移除，蚀刻线将在其与矩形相交的 XY 位置被切割（中心线将在框边界处被切割，但修剪后的蚀刻线端帽可能仍会延伸过边界）。

**Original**: This function removes elements from a design relative to a rectangular box provided (`g_windowDelete`). The box is defined by a two points on opposite sides of the box and the edges of the box will be parallel to the x and y axes. `g_windowSelect` is another box which is used to select items for removing. It is a SKILL access to the `Manufacture - Drafting - Delete by Rectangle` command in the tool. The interface operates by removing all objects either inside or outside of the provided rectangle. For those elements which cross the edge of the window provided, the object is cut there. This means only part of a shape over top of the rectangle will be removed, and a cline will be cut at the XY location where it meets the rectangle (the center line will be cut at the box boundary, but the end caps of the trimmed cline may still extend over the boundary).

**语法**：
```skill
axlDeleteByRectangle(
g_windowSelect
g_windowDelete
g_insideOutside
[b_ignoreFixed]
[l_objectTypes]
)
-> t/nil
```

**参数**：
- `l_windowSelect`：参数类型为定义选择要剪切项的框的 2 个点列表，例如 `list(-500:-500 500:500)`。
- `l_windowDelete`：要相对于其剪切的边界框。例如 `list(-500:-500 500:500)`。
- `s_insideOutside`：
  - `'inside`：删除框内的元素，保留框外的元素。
  - `'outside`：删除框外的元素，保留框内的元素。
- `[b_ignoreFixed]`：
  - `t`：忽略元素上的固定属性，允许删除它们。
  - `nil`：尊重固定属性，因此固定元素不会被删除，即使它们位于非固定元素被删除的区域。如果未提供，默认值为 `nil`。
- `[ls_objectTypes]`：参数类型为字符串列表，或如果只有一个对象类型，则为单个字符串。列表可以包括以下任何集合：`"VIAS"`、`"FINGERS"`、`"CLINES"`、`"LINES"`、`"BONDWIRES"`、`"SHAPES"`、`"CLINESEGS"`、`"OTHERSEGS"`。如果未提供，将处理所有对象类型。

**返回值**：
- `t`：操作成功。
- `nil`：操作失败。

**示例**：
```skill
axlDeleteByRectangle(list(-500:-500 500:500) list(-500:-500 500:500) 'inside t '("VIAS" "CLINES"))
```

**另请参见**：`axlDeleteObject`

---

### axlDeleteTaper

**说明**：删除锥形（taper）。

**Original**: Deletes tapers.

**语法**：
```skill
axlDeleteTaper(
o_dbid
)
==> t/nil
```

**参数**：
- `o_dbid`：铜皮或路径的 `dbid`。

**返回值**：
- `t`：表示成功。
- `nil`：命令失败。

---

### axlDBDeleteProp

**说明**：从 `lo_attach` 中对象的 `dbids` 删除 `lt_name` 中列出的名称的属性。

**Original**: Deletes the properties listed by name, in `lt_name`, from the objects whose `dbids` are in `lo_attach`.

**语法**：
```skill
axlDBDeleteProp(
lo_attach
lt_name
)
=> l_result/nil
```

**参数**：
- `lo_attach`：要从中删除属性的对象的 `dbids` 列表。`lo_attach` 可以是单个 `dbid`。如果 `lo_attach` 为 `nil`，则从设计本身删除属性。
- `lt_name`：要删除的属性名称列表。`lt_name` 可以是多个属性的字符串列表，或如果仅删除一个属性，则为单个字符串。

**返回值**：
- `l_result`：列表。
  - `(car)`：成功删除至少一个属性的 `lo_attach` 成员的 `dbids` 列表。
  - `(cadr)`：始终为 `nil`。
- `nil`：未删除属性。

**另请参见**：`axlDBAddProp`，`axlDBDeletePropAll`

**示例**：
```skill
axlDBCreatePropDictEntry(
  "myprop", "real", list( "pins" "nets" "symbols"),
  list( -50. 100), "level")
axlClearSelSet()
axlSetFindFilter(
  ?enabled '("NOALL" "ALLTYPES" "NAMEFORM")
  ?onButtons "ALLTYPES")
axlSingleSelectName( "NET" "ENA2")
axlDBAddProp(axlGetSelSet(), list("MYPROP" 23.5))
axlShowObject(axlGetSelSet())
```

首先定义字符串值属性 `"myprop"`，然后将其添加到网络 `"ena2"`，再从网络中删除该属性。

**Original**: First defines the string-valued property "myprop", then adds it to the net "ena2", then deletes the property from the net.

```skill
axlDBDeleteProp(axlGetSelSet() list("myprop"))
axlShowObject(axlGetSelSet())
```

使用 `axlDBDeleteProp` 删除附加属性。以下 Show Element 表单显示网络已删除 `MYPROP`。

---

### axlDBDeletePropAll

**说明**：删除数据库中属性 `t_name` 的所有实例。这包括存在于 `symDef` 和 `compDef` 上无法通过属性编辑命令访问的属性。如果删除影响 DRC 系统的属性，可能希望使用 `axlDBCloak` 包装此调用以获得更好的性能。

**Original**: Deletes all instances of the property `t_name` in the database. This includes properties that exist on the symDef and compDef that cannot be access via the property edit command. If you delete a property that effects the DRC system, you may wish to wrap this call with a `axlDBCloak` for better performance.

**语法**：
```skill
axlDBDeletePropAll(
t_name
)
==> x_count/nil
```

**参数**：
- `t_name`：要删除其所有实例的属性名称。

**返回值**：
- `x_count`：返回删除的属性数量。
- `nil`：错误，属性定义不存在。

**另请参见**：`axlDBAddProp`，`axlDBDeleteProp`，`axlDBCloak`

**示例**：
```skill
;; 删除数据库中所有固定属性
axlDBDeletePropAll("FIXED")
```

---

### axlDBDeletePropDictEntry

**说明**：删除未使用的用户属性定义。属性条目必须未使用。属性定义必须是用户属性，且其 `useCount`（`axlDBGetPropDictEntry`）必须为零才能删除。如果属性正在使用中，请使用 `axlDBDeletePropAll`。

**Original**: Deletes an unused user property definition. Property entry must be unused. The property definition must be a user property and its useCount (`axlDBGetPropDictEntry`) must be zero for you to delete it. Use `axlDBDeletePropAll` if property is in use.

**语法**：
```skill
axlDBDeletePropDictEntry(
t_name
)
==> t/nil
```

**参数**：
- `t_name`：字符串，指定要删除的用户属性字典条目的名称。

**返回值**：
- `t`：已删除属性定义。
- `nil`：属性正在使用中，是 Allegro 属性，属性不存在，或名称不合法。

**另请参见**：`axlDBAddProp`，`axlDBDeleteProp`，`axlDBCreatePropDictEntry`

**示例**：
```skill
;; 删除由 axlDBCreatePropDictEntry 创建的属性 myprop
axlDBDeletePropDictEntry("myprop")
```

---

### axlDBOpenShape

**说明**：打开现有铜皮以替换其边界或修改其挖空。铜皮可以保持打开状态，以便更新铜皮内的挖空。如果仅需要替换轮廓，可以作为此调用的一部分关闭铜皮。新轮廓不能与现有挖空重叠，也不允许现有挖空存在于轮廓之外。

打开现有铜皮的副作用是铜皮将显示为未填充，直到关闭。

**Original**: Opens an existing shape to replace its boundary or to modify its voids. Shape can be left open so you can update the voids within the shape. If only the outline needs to be replaced, you can close the shape as part of this call. The new outline cannot overlap existing voids or allow existing voids to exist outside the outline. A side-effect of opening an existing shape is the shape will be displayed as unfilled until it is closed.

**语法**：
```skill
axlDBOpenShape(
o_shapeDbid/nil
[o_polygon/r_path/nil]
[g_close]
)
==> o_dbid/nil
```

**参数**：
- `o_shapeDbid`：要修改的铜皮的 `dbid`。如果 `dbid` 为 `nil`，则使用现有打开的铜皮。
- `o_polygon`：多边形格式的新铜皮轮廓。
- `r_path`：`r_path` 格式的新铜皮轮廓。
- `g_close`：可选选项以关闭铜皮（`t`）边界修改。

**返回值**：
- `o_dbid`：提供的铜皮的 `dbid` 或错误时为 `nil`。

**另请参见**：`axlDBCreateCloseShape`，`axlDBCreateOpenShape`，`axlDBCreateVoid`，`axlShapeDeleteVoids`，`axlShapeAutoVoid`

**示例**：
```skill
;; ashOne 是共享软件工具，允许用户选择对象
;; (参见 <CDSROOT>/share/pcb/examples/skill/ash-fxf/ashone.il)

;; 选择一个铜皮并将其扩展 100
shp = ashOne("shapes")
edge = car( axlPolyFromDB(shp) )
newedge = car( axlPolyExpand(edge 100.0 'NONE) )
newshp = axlDBOpenShape(shp newedge t)

;; 选择一个挖空并删除它
shp = ashOne("voids")
edge = axlPolyFromDB(shp)
newedge = car( axlPolyExpand(edge 100.0 'NONE) )
newshp = axlDBOpenShape(shp newedge)
q = axlDBCreateCloseShape(newshp)

;; 选择一个铜皮，删除所有挖空，并将边界收缩 100
shp = ashOne("shapes")
edge = car( axlPolyFromDB(shp) )
newedge = car( axlPolyExpand(edge -100.0 'NONE) )
newshp = axlDBOpenShape(shp nil)
axlShapeDeleteVoids(shp)
q = axlDBCreateCloseShape(newshp)
```

---

### axlDeleteFillet

**说明**：删除与 PIN、VIA、T 或 CLINE 关联的焊盘填充（fillet）。如果 `o_dbid` 是焊盘填充形状，该命令也会删除单个焊盘填充。通过蚀刻线删除时，Allegro PCB Editor 会搜索过孔/引脚连接并从该引脚或过孔删除焊盘填充。它仅删除 CLINE 层上的焊盘填充。如果要从 PIN 或 VIA 删除焊盘填充，它将删除所有层上的焊盘填充。

**Original**: Deletes fillet associated with a PIN, VIA, T, or CLINE. The command also deletes a single fillet if `o_dbid` is a fillet shape. When deleting via a cline, Allegro PCB Editor searches for the via/pin connections and deletes the fillets from that pin or via. It only deletes FILLETS on the layer of the CLINE. If deleting FILLETS from a PIN or VIA, it deletes FILLETS on all layers.

**语法**：
```skill
axlDeleteFillet(
o_dbid
)
=> t/nil
```

**参数**：
- `o_dbid`：PIN、VIA、PATH 或 T 的 `dbid`。

**返回值**：
- `t`：已删除焊盘填充。
- `nil`：未删除焊盘填充。

---

### axlFillet

**说明**：在蚀刻线和引脚/过孔之间添加焊盘填充，以及在 T 形连接处添加。移除并重新生成现有焊盘填充。焊盘填充参数由 Glossing `Pad and T Parameter` 表单控制。

**Original**: Adds fillet between cline and pin/via, and at T. Removes and re-generates existing fillets. Fillet parameters are controlled from the Glossing `Pad and T Parameter` form.

**语法**：
```skill
axlFillet (
o_dbid/lo_dbid
)
=> t/nil
```

**参数**：
- `o_dbid`：`dbid` 可以是 NET、Path（CLINE）或 line（segment）。

**返回值**：
- `t`：已添加焊盘填充。
- `nil`：错误或未添加焊盘填充。

**注意**：
- 不支持引脚、过孔和 T 形连接；请在这些对象上使用 `axlDBGetConnect` 以获取连接的蚀刻线列表。
- 为了获得最佳性能，特别是如果焊盘填充影响动态铜皮，请使用要填充的对象列表进行单次调用。

**示例**：
```skill
;; 对新的 MEMDATA8 网络进行焊盘填充
axlFillet(car(axlSelectByName("NET" "MEM_DATA8")))
```

---

### axlFilletConvert

**说明**：将焊盘填充或锥形转换为静态铜皮。仅应在将设计转换为其他形式时使用此命令，例如，如果您正在制作拼板解决方案。使用此命令时应禁用动态焊盘填充。

使用此命令的一些副作用包括：
- 转换后的焊盘填充在蚀刻被删除/修改时仍然存在
- 如果启用了动态焊盘填充，则会出现重复的焊盘填充。
- 由于转换后的焊盘填充或锥形使用铜皮间距，可能会发生 DRC。
- 其他铜皮的挖空可能会改变。
- 蚀刻长度计算可能会受到影响。
- 这些走线上的蚀刻编辑可能工作方式不同。

**Original**: Converts a fillet or taper to a static shape. This command should only be used if converting a design to another form such as if you are crafting a panelization solution. Dynamic fillets should be disabled when using this command. Some of the side effects of using this command are: The converted fillets remain if etch is deleted/modified; If dynamic fillets are enabled, a duplicate fillet appears; DRCs may occur because the converted fillet or taper uses shape spacing; Voiding other shapes may change; Etch length calculations may be effected; Etch editing may work differently on these traces.

**语法**：
```skill
axlFilletConvert(
o_dbid
)
-> t/nil
```

**参数**：
- `o_dbid`：焊盘填充形状 `dbid`。

**返回值**：
- `t`：焊盘填充成功转换为静态铜皮。
- `nil`：`dbid` 不是焊盘填充形状。

**另请参见**：`axlDeleteFillet`

---

### axlGetLastEnterPoint

**说明**：获取上次使用 `axlEnterPoint` 的拾取位置。

**Original**: Gets the last pick location from `axlEnterPoint`.

**语法**：
```skill
axlGetLastEnterPoint ()
=> l_point/nil
```

**参数**：无。

**返回值**：
- `axlGetLastEnterPoint`：用户从上次调用 `axlEnterPoint()` 的拾取位置。

**示例**：
返回的拾取列表：`(1000.000 2000.000)`。

---

### axlLastPick

**说明**：返回上次处理的光标拾取位置。可以捕捉到当前网格（`l_mode` => `t`）或保持未捕捉状态。位置以设计单位返回。使用的网格取决于活动层。拾取事件会导致上次拾取。在 SKILL 中，对 `axlEnterPoint`、`axlEnterEvent` 等的调用可能会生成此事件。它允许从捕捉事件切换到未捕捉事件。如果用户自启动 Allegro PCB Editor 以来没有进行拾取，则返回 `(0 0)`。

**Original**: This returns the last processed cursor pick. You can snap to current grid (`l_mode` => `t`) or leave it unsnapped. Position is returned in design units. The grid used depends on the active layer. A pick event causes the last pick. In SKILL, a call to axlEnterPoint, axlEnterEvent, and so on may generate this. It allows switching from a snapped to an unsnapped event. If a user has made no pick since launching Allegro PCB Editor, then it returns `(0 0`).

**语法**：
```skill
axlLastPick(
l_mode
)
=> xy
```

**参数**：
- `l_mode`：`t` 表示捕捉，`nil` 表示未捕捉。

**返回值**：最后拾取位置作为 `xy` 列表。

**示例**：
```skill
snappedPoint = axlEnterPoint(?prompts list("Pick origin point") ?gridSnap t)
unsnapped = axlLastPick(nil)
```

---

### axlWindowBoxGet

**说明**：返回当前对用户可见的 Allegro PCB Editor 窗口的边界框，以设计单位表示。

**Original**: Returns the bounding box of the Allegro PCB Editor window currently visible to the user, in design units.

**语法**：
```skill
axlWindowBoxGet(
)
=> l_bBox
```

**参数**：无。

**返回值**：
- `l_bBox`：当前 Allegro PCB Editor 窗口的 `bBox`。

---

### axlWindowBoxSet

**说明**：将 Allegro PCB Editor 显示设置为给定的 `bBox`。根据宽高比进行调整并返回调整后的 `bBox`。

**Original**: Sets Allegro PCB Editor display to given bBox. Adjusts it according to the aspect ratio and returns the adjusted bBox.

**语法**：
```skill
axlWindowBoxSet(
l_bBox
)
=> l_bBox/nil
```

**参数**：
- `l_bBox`：用于显示更改的 `bBox`。

**返回值**：
- `l_bBox`：调整后的 `bBox`。
- `nil`：非法参数。

---

### axlReplacePadstack

**说明**：替换引脚或过孔（或列表）上的焊盘。除非有参数错误，否则不会打印任何错误消息。引脚/过孔可以是列表或单个 `dbid`。忽略列表中不是引脚或过孔的项。焊盘可以通过名称或 `dbid` 引用，并且必须存在于 Allegro PCB Editor 数据库中。使用 `axlDBCreatePadStack` 获取 `dbid`。返回已更改焊盘的引脚/过孔列表。这可能与您的初始列表不同，因为软件会移除不是引脚或过孔的 `dbid` 以及更改焊盘会导致数据库错误的项。此函数不会更改符号定义引脚。在绘图编辑器中更改引脚上的焊盘会导致爆炸引脚，这会增加数据库大小并影响 `refresh_symbol`。使用此函数可能会导致断开和新的 DRC 违规。

**Original**: Replaces the padstack on a pin or via (or a list of them). Will not print any error messages unless you have argument errors. The pin/via can be a list or a single `dbid`. Ignores items in the list that are not pins or vias. The padstack can be referenced by name or a `dbid` and must be present in the Allegro PCB Editor database. Use `axlDBCreatePadStack` to obtain a `dbid`. Returns a list of pins/vias that have had their padstacks changed. This may not be the same as your initial list as the software removes `dbids` that are not pins or vias and those items where changing the padstack would create a database error. This function will not change symbol definition pins. Changing the padstack on a pin in the drawing editor results in an exploded pin which increases your database size and impacts refresh_symbol. Using this function can result in disconnects and new DRC violations.

**语法**：
```skill
axlReplacePadstack (
o_dbid
o_padstackdbid
/
t_padname
)
=> lo_dbid
```

**参数**：
- `o_dbid`：引脚或过孔 `dbid`（或列表）。
- `o_padstackdbid/t_padname`：焊盘 `dbid` 或名称。

**返回值**：已更改焊盘的引脚/过孔列表。

**性能提示**：
- 要更改特定焊盘的所有实例，更改焊盘本身更快。
- 如果要将许多引脚和过孔更改为相同的焊盘，使用引脚/过孔列表调用此函数比为每个引脚或过孔单独调用节省时间。

---

### axlPurgePadstacks

**说明**：从数据库中清除未使用的焊盘。`S_mode` 符号控制区域。

**Original**: Purges unused padstacks from the database in the area controlled by `S_mode` symbol.

**语法**：
```skill
axlPurgePadstack (
S_mode
t/nil
)
=> x-cnt
```

**参数**：
- `S_mode`：`'padstacks` 或 `'via`。
- 选项：
  - `t`：仅清除未使用的派生焊盘（对于 `'padstacks`）；清除所有未使用的过孔列表约束中的过孔（对于 `'via`）。
  - `nil`：清除所有未使用的焊盘（对于 `'padstacks`）；清除未加载到数据库中但在磁盘上通过 `PSMPATH` 环境变量找到的过孔（对于 `'via`）。

`nil` 选项在 Allegro PCB Editor 用户界面中不可用。为获得最佳结果，首先从数据库中删除未使用的焊盘，然后清除过孔列表。

**返回值**：
- `x_cnt`：清除的焊盘数量。

**示例**：
```skill
axlPurgePadstacks('padstacks nil)
axlPurgePadstacks('via t)
;; 模拟默认的 Allegro PCB Editor 用户界面行为
```

---

### axlPurge3DModelMapDataInDesign

**说明**：从整个设计中删除 3D 模型映射数据。

**Original**: Removes 3D model mapping data from the entire design.

**语法**：
```skill
axlPurge3DModelMapDataInDesign()
-> t/nil
```

**参数**：无。

**返回值**：
- `t`：清除完成。
- `nil`：未完成。

**示例**：
```skill
result = axlPurge3DModelMapDataInDesign()
```

---

### axlShapeAutoVoid

**说明**：使用当前静态铜皮参数控制挖空来自动挖空静态铜皮，除非选项提供覆盖。不支持挖空动态铜皮或动态生成的铜皮。此函数会产生一个副作用文件 `shape.log`。

选项：
- `'noRipThermals`：默认情况下，自动挖空会撕裂铜皮中的所有现有热焊盘连接并创建一组新的热焊盘连接，保持现有热焊盘。使用此选项则保持现有热焊盘连接。
- `'fragment`：默认情况下，如果铜皮碎裂成多个铜皮，会在继续之前提示您。如果继续，Allegro PCB Editor 允许静默碎裂。覆盖静态铜皮参数记录中的设置。
- `'noFragment`：与 `fragment` 相反。如果铜皮需要碎裂，则 API 失败。

请勿使用此函数在负片层上挖空铜皮。底片不代表内部挖空。

**Original**: Autovoids a static shape using current static shape parameters to control voiding except where options provide an override. Voiding dynamic shapes or dynamically-generated shapes is not supported. This function produces a file, `shape.log`, as a side effect of the autovoid. Options: `'noRipThermals` - by default autovoid rips up all existing thermal ties in the shape and creates a new set, maintaining existing thermals. `'fragment` - by default, if shape fragments into multiple shapes, prompts you before proceeding. If you proceed, Allegro PCB Editor allows a silent fragment. Overrides setting in static shape parameter record. `'noFragment` - opposite of fragment. API fails if shape needs to be fragmented. Do not use this function to void shapes on negative planes. Artwork does not represent inside voiding.

**语法**：
```skill
axlShapeAutoVoid(
o_shapeId
[s_options/ls_options]
)
==> lo_shapeIds/nil
```

**参数**：
- `o_shapeId`：可挖空的铜皮。
- `s_options`：单个选项符号（见上文）。
- `ls_options`：选项列表（见上文）。

**返回值**：
- `lo_shapeId`：挖空后的铜皮列表。通常是一个铜皮，除非铜皮被碎裂成多个部分。
- `nil`：挖空失败或非法参数。

**另请参见**：`axlShapeDeleteVoids`

**示例**：
```skill
;; 参见 <cdsroot>/share/pcb/examples/skill/ash/ashshape.il
axlShapeAutoVoid(shapeDbid '(noRipThermals fragment))
```

---

### axlShapeChangeDynamicType

**说明**：将连接铜皮从静态交换为动态或反向。提供与 Allegro PCB Editor 命令 `shape change type` 相同的功能。

**注意**：
- 静态铜皮转换为动态时，挖空将被删除。
- 将动态铜皮转换为静态可能会导致丢失原始边界，因为 Allegro PCB Editor 将生成的铜皮（在 ETCH 上）转换为静态铜皮，而不是边界铜皮。
- 转换为静态的铜皮保持挖空。
- ETCH 上支持填充矩形，转换为铜皮。
- 如果更改多个铜皮的类型或对单个铜皮执行多个操作（例如，转换然后提升优先级），请考虑将代码包装在 `axlDBCloak` 中以批量更新。

**Original**: Swaps a connectivity shape from static to dynamic or the reverse. This offers the same functionality as the Allegro PCB Editor command `shape change type`. Notes: Voids in static are deleted when shape is converted to dynamic. Converting a dynamic shape to static can result in the loss of the original boundary since Allegro PCB Editor converts the generated shapes (on ETCH) to static shapes not boundary shapes. Shapes converted to static maintain voids. Filled rectangles are supported on ETCH, converted to a shape. If changing the type of multiple shapes or doing multiple operations on a single shape (for example, convert then raise priority) consider wrapping the code in `axlDBCloak` to batch updates.

**语法**：
```skill
axlShapeChangeDynamicType(
o_shapeId
g_dynamic
g_msgs
)
-> o_dynShapeId/l_staticShapeId/nil
```

**参数**：
- `o_shapeId`：动态铜皮 ID 或静态 ID。
- `g_dynamic`：`t` 使铜皮动态，`nil` 使铜皮静态。
- `g_msgs`：`t` 在转换失败时发出错误消息；否则静默。

**返回值**：
- `nil`：失败。
- `o_dynShapeId`：从静态转换的动态铜皮的 `dbid`。
- `l_staticShapeId`：从动态铜皮转换的静态铜皮列表。

**另请参见**：`axlShapeChangeDynamicType`

**示例**：
```skill
;; 参见 <cdsroot>/share/pcb/examples/skill/axlcore/ashshape.il
;; 更改为动态铜皮并显示消息：
ret = axlShapeChangeDynamicType(shape t t)
;; 更改为静态铜皮，无消息：
ret = axlShapeChangeDynamicType(shape nil nil)
```

---

### axlShapeDeleteVoids

**说明**：删除铜皮中的挖空。支持以下三种参数形式：
- 给定铜皮，删除该铜皮中的所有挖空
- 删除单个挖空
- 删除挖空列表

挖空列表选项中的非挖空将被静默忽略。不能删除属于自动生成铜皮的挖空。如果对铜皮进行一系列修改（例如删除和添加挖空或更改铜皮边界），为了获得最佳性能，建议将调用包装在 `axlDBOpenShape` 和 `axlDBCreateCloseShape` 中。

**Original**: Lets you delete voids in a shape. Supports the following three forms of arguments: Shape that deletes all voids in that shape; Delete single void; Delete list of voids. Non-voids in list of voids options are silently ignored. You cannot delete the voids that are a part of auto-generated shapes. If you are making a series of modifications to a shape, such as, deleting and adding voids or changing the shape boundary, then for best performance, it is recommended that you wrap your calls in `axlDBOpenShape` and `axlDBCreateCloseShape`.

**语法**：
```skill
axlShapeDeleteVoids(
o_shapeId/o_voidId/lo_voidid
)
-> t/nil
```

**参数**：
- `o_shapeId`：给定铜皮；删除与该铜皮关联的所有挖空。
- `o_voidId`：删除给定的挖空。
- `lo_voidid`：删除挖空列表。

**返回值**：
- `t`：删除挖空。
- `nil`：错误。

**另请参见**：`axlShapeAutoVoid`，`axlDBOpenShape`，`axlDBCreateCloseShape`

**示例**：
```skill
;; 参见 <cdsroot>/share/pcb/examples/skill/axlcore/ashshape.il
;; 假设您有铜皮 dbid (shapeId)：
;; 删除单个挖空
axlShapeDeleteVoids(car(p->voids))
;; 删除铜皮中除第一个外的所有挖空
axlShapeDeleteVoids(cdr(p->voids))
;; 删除铜皮中的所有挖空
axlShapeDeleteVoids(p)
```

---

### axlShapeDynamicUpdate

**说明**：更新动态铜皮，或如果为 `nil`，则更新所有动态铜皮。这将忽略设计的当前动态铜皮模式设置。默认情况下，仅当铜皮过期时才更新，除非 `g_force` 为 `t`。在这种情况下，它会更新铜皮。如果 `g_force` 为 `nil`，则仅当 `dbid->fillOOD` 为 `t` 时才更新铜皮。此函数支持 `dbid->shapeIsBoundary` 为 `t` 的铜皮。更新动态铜皮包括挖空、底片平滑和热焊盘生成。

**Original**: Updates a dynamic shape, or if `nil`, all dynamic shapes are updated. This ignores the current dynamic shape mode setting of the design. By default, only updates the shape if it is out of date unless `g_force` is `t`. In this case, it updates the shape. If `g_force` is `nil` the shape is only updated if `dbid->fillOOD` is `t`. This function supports shapes whose `dbid->shapeIsBoundary` is `t`. Updating a dynamic shape includes voiding, artwork smoothing, and thermal relief generation.

**语法**：
```skill
axlShapeDynamicUpdate(
o_shapeDbid/nil
g_force
)
-> x_ood/nil
```

**参数**：
- `o_shapeDbid`：动态铜皮的 `dbid`。
- `g_force`：强制更新铜皮，即使它已是最新。

**返回值**：
- `x_ood`：如果更新所有，则返回更新失败的所有铜皮计数。如果是单个铜皮，返回 `0` 表示更新成功，`1` 表示失败。
- `nil`：返回错误；`dbid` 不是动态铜皮。

**示例**：
```skill
;; 强制更新动态铜皮
axlShapeDynamicUpdate(shapeId, t) -> 0
;; 更新所有铜皮
axlShapeDynamicUpdate(nil nil) -> 0
```

---

### axlShapeRaisePriority

**说明**：提升动态铜皮（`o_shapeId`）的挖空优先级，使其在所选层上为最高。如果此铜皮与该层上的其他动态铜皮重叠，其他铜皮将从此铜皮挖空。

优先级号是相对的。Allegro PCB Editor 会根据需要调整这些数字。您应该仅将优先级号用于与其他动态铜皮优先级号的比较。对于动态铜皮（CLASS=BOUNDARY 上的铜皮），`priority` 属性反映当前优先级（例如 `dbid->priority`）。如果提升多个铜皮的优先级或对单个铜皮执行多个操作（例如转换然后提升优先级），请考虑将代码包装在 `axlDBCloak` 中以批量更新。

**Original**: Raises the voiding priority of a dynamic shape (`o_shapeId`) to the highest on the chosen layer. If this shape overlaps other dynamic shapes on the layer, the other shapes void away from this shape. The priority number is relative. Allegro PCB Editor adjusts the numbers, as necessary. You should only use the priority number for comparison with other dynamic shape priority numbers. For a dynamic shape (those on CLASS=BOUNDARY) the attribute priority reflects the current priority (for example, `dbid->priority`). If raising priority on multiple shapes or doing multiple operations on a single shape (for example, convert; then raise priority) consider wrapping the code in `axlDBCloak` to batch updates.

**语法**：
```skill
axlShapeRaisePriority(
o_shapeId
)
-> x_priority/nil
```

**参数**：
- `o_shapeId`：动态铜皮 ID。

**返回值**：
- `x_priority > 0`：铜皮的新优先级。
- `-1`：已在最高优先级。
- `nil`：不是动态铜皮。

**另请参见**：`axlShapeChangeDynamicType`

**示例**：
```skill
;; 参见 <cdsroot>/share/pcb/examples/skill/axlcore/ashshape.il
axlShapeRaisePriority(shape)
```

---

### axlShapeMerge

**说明**：合并铜皮。合并的铜皮必须重叠且没有固定属性。所有合并的铜皮（`lo_shapes`）必须与主铜皮（`o_shapeId`）重叠。支持合并的数据库类型：铜皮、矩形和填充矩形。结果铜皮将采用第一个铜皮的特性。这包括铜皮类型和属性。次要铜皮上的任何属性都将丢失。如果更改多个铜皮的类型或对单个铜皮执行多个操作（例如转换然后提升优先级），请考虑将代码包装在 `axlDBCloak` 中以批量更新。

**Original**: This merges shapes. Shapes must be overlapped without the fixed property to merge. All merging shapes (`lo_shapes`) must overlap the primary shape (`o_shapeId`). Supports merging db types; shapes, rectangle and filled rectangles. The resulting shape will take on the characteristics of the first shape. This includes shape type and properties. Any properties on the secondary shapes are lost. If changing type of multiple shapes or doing multiple operations on a single shape (for example, convert then raise priority) consider wrapping the code in `axlDBCloak` to batch updates.

**语法**：
```skill
axlShapeMerge(
o_shapeId
lo_shapes
g_options/lg_options
)
-> o_dynShapeId/l_staticShapeId/nil
```

**参数**：
- `o_shapeId`：动态铜皮 ID 或静态 ID。
- `g_dynamic`：`t` 使铜皮动态，`nil` 使静态。
- `g_options`：可用选项：
  - `'check`：不合并，仅执行合并检查。
  - `'quiet`：不输出任何消息。

**返回值**：
- `nil`：表示失败。
- `o_dynShapeId`：从静态转换的动态铜皮的 `dbid`。
- `l_staticShapeId`：从动态铜皮转换的静态铜皮列表。

**另请参见**：`axlShapeChangeDynamicType`

**示例**：
```skill
;; ashOne 是共享软件工具，允许用户选择对象
;; (参见 <cdsroot>/share/pcb/examples/skill/ash/ashshape.il)
;; 合并两个铜皮；交互式选择两个重叠的铜皮
s1 = ashOne("shapes")
s2 = ashOne("shapes")
shapeResult = axlShapeMerge(s1 s2 'quiet)
```

---

### axlShapeUpdateDegas

**说明**：如果指定了铜皮，则更新该铜皮的过期脱气模式；如果未传递参数，则更新每个过期的脱气铜皮。

**Original**: Updates the out-of-date degassing pattern of a shape if specified or every degassed shape that is out-of-date if no argument is passed.

**语法**：
```skill
axlShapeUpdateDegas(
o_shape
)
=> n_count
```

**参数**：
- `o_shape`：指定铜皮的 `dbid`。

**返回值**：
- `n_count`：更新的铜皮计数。

**示例**：
```skill
;; 更新特定过期脱气铜皮
axlShapeUpdateDegas(o_shape)
;; 更新所有过期脱气铜皮
axlShapeUpdateDegas(nil)
```

**另请参见**：`axlShapeIsDegasOutOfDate`

---

### axlShoveItems

**说明**：获取 `dbid` 列表并根据使用 `axlShoveSetParams` 设置的参数推挤它们。

**Original**: Takes a list of `dbids` and shoves them according to the parameters set using `axlShoveSetParams`.

**语法**：
```skill
axlShoveItems(
l_itemList
)
=> t/nil
```

**参数**：
- `l_itemList`：要推挤的 `dbid` 列表（蚀刻线、引脚或过孔）。

**返回值**：
- `t`：推挤了一个或多个项。
- `nil`：未推挤任何项。

引脚和过孔不会被推挤，但会推挤其周围的蚀刻线，以试图消除引脚/过孔与蚀刻线之间的任何 DRC。传入的 `dbid` 列表不反映推挤的结果，因为原始项可能被删除和/或替换。

**示例**：
```skill
(defun ShoveElement ()
  axlSetFindFilter (?enabled '("CLINES" "VIAS")
    ?onButtons '("CLINES" "VIAS"))
  axlSelect()
  axlShoveItems (axlGetSelSet())
)
;; 推挤用户交互选择的项（或多个项）
```

---

### axlShoveSetParams

**说明**：设置 `axlShoveItems` 使用的推挤参数。如果未提供所有值，则使用指示的默认值。

**Original**: Sets the parameters used for shoving by the `axlShoveItems`. If you do not provide all values, the indicated default is used.

**语法**：
```skill
axlShoveSetParams(
l_params
)
=> t/nil
```

**参数**：
- `l_params`：参数列表，格式为：`(shoveMode cornerType gridded smooth oop samenet)`

**ShoveMode**（推挤模式）为整数：
| 值 | 说明 |
|----|------|
| 0 | hug preferred - 传入的项尝试围绕与其违规的项塑形（默认） |
| 1 | shove preferred - 传入的项尝试推挤与其违规的项 |

**CornerType**（拐角类型）为整数：
| 值 | 说明 |
|----|------|
| 90 | 90 度拐角 |
| 45 | 45 度拐角 |
| 0 | 任意角度拐角 |

**Gridded**（网格）为整数：
| 值 | 说明 |
|----|------|
| 0 | 忽略网格（默认） |
| 1 | 在网格上执行推挤 |

**Smooth**（平滑）允许平滑推挤的走线，为整数：
| 值 | 说明 |
|----|------|
| 0 | 不平滑（默认） |
| 1 | 最小平滑 |
| 2 | 更多平滑 |
| 3 | 进一步平滑 |
| 4 | 完全平滑 |

**Oops**（撤销）允许在 DRC 结果时中止推挤，为整数：
| 值 | 说明 |
|----|------|
| 0 | Oops 关闭（默认） |
| 1 | 如果残留 DRC 则 Oops |

**Samenet**（同网络）测试同网络违规：
| 值 | 说明 |
|----|------|
| 0 | 无同网络测试（默认） |
| 1 | 启用同网络 DRC 检查 |

此结果是一个后推挤 DRC 检查，仅当将 oops 设置为 "oops if drcs" 值时才有意义。

**返回值**：
- `t`：已设置推挤参数。
- `nil`：未设置推挤参数。

**示例**：
```skill
(defun SetParams ()
  (let (params (shoveMode 1) (cornerType 45) (gridded 1))
    params = list(shoveMode cornerType gridded)
    axlShoveSetParams(params)
  ))
;; 设置推挤参数为推挤优先、45 度模式并捕捉到网格
```

---

### axlSmoothDesign

**说明**：平滑整个设计。对于复杂设计，需要多次遍历才能获得良好效果。因为一次遍历中的更改可能会在下一次遍历中开辟可用空间。建议 3 是典型次数，尽管非常复杂的设计可以从更多遍历中受益。但遍历次数越多，耗时越长。

**Original**: Smooths the entire design. For good results on complicated designs, multiple passes are necessary. Since changes in one pass may open space that can be used in the next pass. Suggest 3 is a typical number although very complex designs can benefit from a higher number of passes. But the more passes the longer it will take.

**语法**：
```skill
axlSmoothDesign(
lx_numPasses
)
-> x_change
```

**参数**：
- `lx_numPasses`：要执行的遍历次数列表。

**返回值**：
- `x_change`：更改的项数。

**示例**：
```skill
;; 使用 3 次遍历平滑设计
axlSmoothSetParams(list("45" -1.0 "0" 10.0 0))
res = axlSmoothDesign(list(3))
```

**另请参见**：`axlSmoothSetParams`

---

### axlSmoothItems

**说明**：获取表示蚀刻线和/或蚀刻线段的 `dbid` 列表，并根据使用 `axlSmoothSetParams()` 函数设置的参数进行平滑。

**Original**: Takes a list of dbids representing clines and/or cline segments and smooths them according to the parameters set using the `axlSmoothSetParams` () function.

**语法**：
```skill
axlSmoothItems (
lo_clineList
)
==> (x_list
```

**参数**：
- `lo_clineList`：表示要平滑的蚀刻线和/或蚀刻线段的 `dbid` 列表。

**返回值**：
此函数返回一个列表，包含平滑过程中更改的蚀刻线数量和更改项列表。格式如下：
`(x_change (o_dbid1 o_dbid2 o_dbid3))`
其中 `x_change` 表示更改的项数，如果发生用户中断则为 `-1`。如果发生错误，函数将返回 `nil`。

**Original**: This function returns a list containing the number of clines that were changed by the smoothing process and the list of changed items. The format is as follows: `(x_change (o_dbid1 o_dbid2 o_dbid3))` Where `x_change` indicates the number of items changed, or `-1` if a user interrupt occurred. If an error occurs, the function will return `nil`.

**示例**：
```skill
;; 平滑一组蚀刻线
clines = <list of ...>
axlSmoothSetParams(list("45" -1.0 "0" 10.0 0))
res = axlSmoothItems(clines)
```

**另请参见**：`axlSmoothSetParams`

---

### axlSmoothSetParams

**说明**：设置用于平滑走线的参数。必须提供所有参数，但 `nil` 作为参数选项将保留现有设置。

平滑功能按"原样"提供。它在许多设计上都表现良好，但具有以下限制：
- 不支持差分对感知。
- 可能对有电气约束的网络有问题。

如果要临时禁用 FIXED 测试，请参见 `axlDBIgnoreFixed`。

**Original**: Sets the parameters used for smoothing the routes. All parameters must be supplied but a nil as a parameter option will leave the existing setting. The smooth functionality is provided on an "as-is" basis. It works well on many designs but has the following restrictions: not differential pair aware; may have issues with electrically constrained nets. See `axlDBIgnoreFixed` if you want to temporary disable FIXED testing.

**语法**：
```skill
axlSmoothSetParams(
l_params
)
==> t/nil
```

**参数**：
- `l_params`：包含参数的列表，格式如下：`(cornerType maxCornerLength padEntryRestriction minPadEntryLength sortDirection)`

**cornerType**（拐角类型）可以是以下字符串值之一：
| 值 | 说明 |
|----|------|
| "90" | 90 度拐角 |
| "45" | 45 度拐角 |
| "0" | 任意角度拐角 |
| "1" | 圆弧拐角 |

**maxCornerLength**（最大拐角长度）：一个整数值，表示数据库单位中气泡或弯折的最大长度。负值表示无限。

**padEntryRestriction**（焊盘进入限制）可以是以下字符串值之一：
| 值 | 说明 |
|----|------|
| "2" | 表示无限制 |
| "1" | 表示所有焊盘进入线段固定 |
| "0" | 表示所有矩形焊盘的进入线段固定 |

**minPadEntryLength**（最小焊盘进入长度）：一个双精度值，表示用户单位中固定焊盘进入线段的最小长度。如果焊盘进入线段长于此长度，它将在该点或附近断开，以便平滑可以在该线段上进行。负值表示无限。如果 `padEntryRestriction` 为 "2"，则此值不适用。

**sortDirection**（排序方向）表示在开始平滑之前如何对蚀刻线进行排序。可以是以下整数值之一：
| 值 | 说明 |
|----|------|
| 0 | 不排序 |
| 1 | 从北排序 |
| 2 | 从东北排序 |
| 3 | 从东排序 |
| 4 | 从东南排序 |
| 5 | 从南排序 |
| 6 | 从西南排序 |
| 7 | 从西南排序 |
| 8 | 从西北排序 |

**返回值**：
- `t`：成功。
- `nil`：失败。

**示例**：
```skill
;; 设置参数
axlSmoothSetParams(list("45" -1.0 "0" 10.0 0))
;; 更新拐角类型为 90
axlSmoothSetParams(list("90" nil nil nil nil))
```

**另请参见**：`axlSmoothItems`，`axlSmoothDesign`，`axlDBIgnoreFixed`

---

### axlStepDelete

**说明**：删除对符号或元件定义的 STEP 分配。

**Original**: This removes a STEP assignment to a symbol or component definition.

**语法**：
```skill
axlStepDelete(
g_type
t_name/o_dbid
)
==> t/nil
```

**参数**：
- `g_type`：应为 `'primary` 或 `'alt`（`nil` 等同于 `'primary`）。
- `t_name`：可以是 `compdef` 或 `symdef` 名称。对于 `.dra` 文件，应为 `nil`。
- `o_dbid`：`symdef` 或 `compdef`。

**返回值**：
- `t`：已删除。
- `nil`：未删除。

**另请参见**：`axlStepGet`

**示例**：
```skill
;; 删除符号定义上的 STEP 分配
result = axlStepDelete(nil "LED_Y")
;; 删除元件定义上的 STEP 分配
result = axlStepDelete(nil "CAP")
```

---

### axlStepSet

**说明**：将 STEP 文件与映射分配或更改现有 STEP 映射到符号或元件定义。偏移量以当前设计单位指定。如果 STEP 文件使用不同的单位，Allegro 最终将偏移值转换为 STEP 文件的单位。支持 `.stp` 和 `.step` 文件扩展名。

**Original**: Assigns a STEP file with a mapping or change to an existing STEP mapping to a symbol or component definition. Offsets are specified in current design units. If STEP file uses different units, Allegro will eventually convert the offset values to the units of the STEP file. Supports both `.stp` and `.step` file extensions.

**语法**：
```skill
axlStepSet(
g_mapType
t_name/o_dbid
t_stepFile
ll_mappingData
)
==> t/nil
```

**参数**：
- `g_mapType`：应为 `'primary` 或 `'alt`（`nil` 等同于 `'primary`）。
- `t_name`：可以是 `compdef` 或 `symdef` 名称。
- `o_dbid`：`symdef` 或 `compdef`。对于 `.dra` 文件，应为 `nil`。
- `t_StepFile`：STEP 文件的名称。如果没有目录组件。如果为 `nil` 且对象具有现有的 STEP 文件，则更新提供的映射数据。
- `ll_mappingData`：如果为默认映射，则可以为 `nil`，或符号名称/值对列表。

**返回值**：
- `t`：映射发生。
- `nil`：错误。

**另请参见**：`axlStepGet`

**示例**：
```skill
;; 将 STEP 模型分配给 .dra 设计（无映射）
result = axlStepSet('primary nil "led-L813_Y" nil)
;; 将 STEP 模型分配给 .dra 设计（无映射）
map = '(rotation_z 3.1 rotation_y 2.0 rotation_x 1.0 offset_z
  6.3 offset_y 5.3 offset_x 4.2 color 9)
result = axlStepSet('primary nil "led-L813_Y" map)
;; 修改上次示例的映射
map = '(rotation_z 30.1 rotation_y 20.0 rotation_x 10.0 offset_z
  6.3 offset_y 5.3 offset_x 4.2)
result = axlStepSet('primary nil nil map)
;; 将替代 STEP 模型分配给 symdef
map = '(rotation_z 10.1 rotation_y 20.0 )
result = axlStepSet('alt "CAP10X16MM-RAD" "CAPC3225" map)
```

---

### axlSymbolAttach

**说明**：将对象或对象列表附加到符号实例。对于蚀刻对象，提供了将引脚逃逸与符号关联的能力。

附加/分离规则：
- 对于分离，对象必须链接到提供的符号实例。对于附加，对象不能链接到任何其他符号。
- 如果文本出现在 REFDES 类上，则无法链接或取消链接。
- 链接或取消链接非蚀刻对象会导致它们在运行 `refresh_symbol` 时被删除或复制。蚀刻对象更受 `refresh_symbol` 支持。
- 支持 CLINES、LINES、SHAPES、RECTS、FRECTS 和 TEXT，层限制如下：
- BOUNDARY 类上的项不受支持。

**Original**: Attaches an object or list of objects to symbol instance. For etch objects, provides the ability to associate pin escapes with a symbol. Attach/detach rules: For detaching, object must be linked to the symbol instance provided. For attaching, the object can not be linked to any other symbol. If text appears of a REFDES class, it can't be linked or unlinked. Linking or unlinking non-etch objects cause them to be deleted or duplicated if refresh symbol is run. Etch objects is more fully supported by refresh symbol. CLINES, LINES, SHAPES, RECTS, FRECTS and TEXT are supported with the layer limits noted below: Items on BOUNDARY class items are NOT supported.

**语法**：
```skill
axlSymbolAttach(
o_symInstDbid
o_dbid/lo_dbid
)
==> t/nil
```

**参数**：
- `o_symInstDbid`：符号实例。
- `o_dbid`：要分配给符号的 `dbid`。
- `lo_dbid`：要分配给符号的 `dbid` 列表。

**返回值**：
- `t`：能够更改对象。
- `nil`：否则。

**另请参见**：`axlSymbolDetach`

**示例**：
```skill
;; 示例使用 ashOne，它是一个共享软件工具，允许用户选择对象
;; (参见 <cdsroot>/share/pcb/examples/skill/ash-fxf/ashone.il)
;; 将对象附加到符号：
symdbid = ashOne("SYMBOLS")
dbid = ashOne("NOALL")
ret = axlSymbolAttach(symdbid dbid)
```

---

### axlSymbolDetach

**说明**：从符号实例中移除对象。此函数从给定符号实例取消链接对象。对于引脚逃逸，提供了两种特殊模式来从给定符号实例分离所有或大多数符号蚀刻。仅当对象与提供的符号实例匹配时，它才会从符号取消链接对象。

运行 `refresh_symbol` 会导致重复对象，因为分离的对象会再次加载。

**Original**: Remove an object from a symbol instance. This function unlinks objects from the given symbol instance. For pin escapes, two special modes are provided to detach all or most symbol etch from a given symbol instance. It only unlinks an object from a symbol if it matches the provided symbol instance. Running refresh_symbol result results in duplicate objects as the detached objects are loaded again.

**语法**：
```skill
axlSymbolDetach(
o_symInstDbid
o_dbid/lo_dbid/g_mode
)
==> t/nil
```

**参数**：
- `o_symInstDbid`：要修改的符号实例。
- `o_dbid`：要从符号取消链接的 `dbid`。
- `lo_dbid`：要从符号取消链接的 `dbid` 列表。
- `g_mode`：取消链接所有 "etch" 的特殊模式：
  - `'allEtch`：取消分配所有蚀刻。
  - `'allClineVia`：取消分配除铜皮外的所有蚀刻。

**返回值**：
- `t`：能够更改符号。
- `nil`：否则。

**另请参见**：`axlSymbolAttach`

**示例**：
```skill
;; 典型方法：从对象获取 symdbid：
;; -- 如果是蚀刻
symdbid = dbid->symbolEtch
;; -- 如果是非蚀刻
symdbid = dbid->parent
symdbid = ashOne("SYMBOLS")
dbid = ashOne("NOALL")
ret = axlSymbolDetach(symdbid, dbid)
;; 从符号取消分配除铜皮外的所有蚀刻
symdbid = ashOne("SYMBOLS")
ret = axlSymbolDetach(symdbid, 'allClineVia)
```

---

### axlAddTaper

**说明**：添加锥形走线。锥形走线参数由 Glossing "Pad and T" 参数表单控制。

**Original**: Adds tapered trace. Tapered trace parameters are controlled from the Glossing "Pad and T" Parameter form.

**语法**：
```skill
axlAddTaper(
o_dbid/lo_dbid
)
==> t/nil
```

**参数**：
- `o_dbid`：`dbid` 可以是 Path（CLINE）或 line（segment）。

**返回值**：
- `t`：函数调用成功时返回。
- `nil`：表示失败。

---

### axlTextOrientationCopy

**说明**：这是一个便捷函数，可根据文本 `dbid` 更新 `TextOrientation` defstruct。通常与 `axlDBCreateText` 或 `axlDBChangeText` 一起使用。

**Original**: This is a convenience function that updates a TextOrientation defstruct based upon a text dbid. This is typically used with axlDBCreateText or `axlDBChangeText`.

**语法**：
```skill
axlTextOrientationCopy(
o_textDbid
[orient]
)
-> orient/nil
```

**参数**：
- `o_textDbid`：文本 `dbid`。
- `orient`：可选的现有 `defstruct`，如果为 `nil` 将创建新的 `defstruct`。

**返回值**：
- `orient`：更新后的 `TextOrientation` defstruct。
- `nil`：参数中有错误。

**另请参见**：`axlDBChangeText`

---

### axlTransformObject

**说明**：移动、旋转和/或旋转一个对象或对象列表。每个 Allegro PCB Editor 数据库对象都有一组合法的变换（参见表 5-1）。如果对象不接受变换，则该变换将被静默忽略。

如果应用多个变换，使用的顺序为：move → mirror → rotate。

如果设置了 `allOrNone` 标志，则当一个对象的变换失败时，整个变换将失败。默认情况下，一个对象的失败不会阻止其他对象的变换。失败是数据库失败。例如，将对象移动到数据库范围之外是数据库失败。尝试非法变换不是失败。如果一个或多个对象未被变换，则没有失败。

**Original**: Moves, rotates, and/or spins one object or a list of objects. Each Allegro PCB Editor database object has a legal set of transforms (see Table 5-1). If the object does not accept a transform, then that transform is silently ignored. If multiple transformations are applied, the order used is: move; mirror; rotate. If `allOrNone` flag is set, then the entire transformation fails when one object's transformation fails. By default, one object's failure does not stop the transformation on the other objects. A failure is a database failure. For example, a move that puts an object outside of the database extents is a database failure. Attempting an illegal transform is NOT a failure. If one or more objects are not transformed, there is no failure.

**表 5-1：支持的变换**

| 对象 | MOVE | MIRROR | GEOMETRY | ROTATE | SPIN | ORIGIN | 备注 |
|------|------|--------|----------|--------|------|--------|------|
| segments | X | X | X | X | | box | |
| cline | X | X | X | X | | box | |
| line | X | X | X | X | | box | |
| symbol | X | X | X | | xy | | |
| shape | X | X | X | X | | box | |
| text | X | X | X | X | | xy | |
| pin | X | | | | xy | | 3,4 |
| via | X | X | X | X | | xy | |
| rat_t | X | | | | xy | | |
| group | X | X | X | X | | xy | 7 |

**备注**：
1. 如果对象未列出，则不支持。
2. 如果对象有附加文本，它也会应用变换。
3. 镜像在同一类内发生。请参见镜像规则。
4. 符号被分解，`refresh_symbol` 不会保持变换。
5. 对于板上的引脚要进行变换，必须在图纸上或拥有引脚的符号上存在 `UNFIXED_PINS`。
6. ORIGIN 列显示在对单个对象进行旋转/镜像操作而没有原点选项时使用的内容。对于框，`dbid` 没有原点，使用其边界框的中心（`dbid->bBox`）。对于具有原点（`dbid->xy`）的 `xy` 对象，它围绕原点旋转。更多讨论请参见角度注释 9。
7. 此 API 拒绝其所有者是符号定义的对象。
8. 唯一支持变换的组是用户和模块组类型。
9. 如果镜像是 `t`，则我们在 x 方向上镜像并跨子类。例如，如果对象在 ETCH/TOP 上，它将在 x 方向上镜像并到层 ETCH/BOTTOM。如果镜像是 `GEOMETRY`，则仅进行 x 方向操作，对象保留在其层上。

**旋转（angle 选项）的工作方式如下**：
- 正角度导致逆时针旋转。
- 如果仅提供角度，则对象围绕其原点旋转。如果 `dbid` 没有原点，则使用其边界框的中心。如果提供了 `dbid` 列表，则旋转始终围绕对象集的中心进行。
- 可以提供旋转原点（`?origin l_rotatePoint`）。此点将用作旋转点。

**注意事项**：
- 未来可能会添加更多对象。例如，挖空。
- 返回列表可能会更改以显示实际变换的对象集。
- 不支持旋转（将对象列表围绕每个对象的中心旋转）。请分别对列表中的每个对象使用 `axlTransformObject`。
- 如果传递包含符号和符号引脚的列表，会得到意外结果。
- 如果变换多个对象，请将此操作包装在 `axlDBCloak` 调用中。
- 如果变换线段，它将具有新的所属路径 `dbid`。

**语法**：
```skill
axlTransformObject(
lo_dbid
/
o_dbid
?move       l_deltaPoint
?mirror     t/nil/'GEOMETRY
?angle      f_angle
?origin     l_rotatePoint
?allOrNone  t/nil
)
=> lo_dbid/nil
```

**参数**：
- `lo_dbid/o_dbid`：单个 `dbid` 或 `dbid` 列表。
- `l_deltaPoint`：移动距离。
- `mirror`：镜像对象（见表）。
- `f_angle`：旋转角度。
- `l_rotatePoint`：旋转点。
- `allOrNone`：如果为 `t` 且是一组对象，则变换必须对所有对象成功，否则失败。

**返回值**：
- `lo_dbid`：变换后的对象列表。
- `nil`：失败，原因包括：
  - 对象无法变换（例如，网络）。
  - 对象被固定或引脚没有 `UNFIX_PINS` 属性。
  - 使用了非法选项类型。
  - 变换后的对象超出数据库范围。

为获得更好的性能，变换一组对象时，使用对象组调用此函数，而不是单独传递每个 `dbid`。

**另请参见**：`axlDBCloak`，`axlCopyObject`

**示例**：
```skill
dbid 表示一个数据库对象。
ldbid 表示数据库对象列表。

;; 示例 1：移动一组对象 100 数据库单位垂直方向
axlTransformObject(ldbid, ?move '(100.0 0.0))

;; 示例 2：绕其原点旋转对象 45 度
axlTransformObject(dbid, ?angle 45)

;; 示例 3：绕旋转点旋转对象
axlTransformObject(dbid, ?angle 45, ?origin 100:100)
```

---

### axlZoneDelete

**说明**：删除区域及其轮廓和关联的铜皮。如果符号放置在区域的表面层上，则该区域不会被删除。

**Original**: Deletes a zone and its outline and associated shapes. If symbols are placed on the surface layers of the zone, the zone is not deleted.

**语法**：
```skill
axlZoneDelete(
t_zone/o_dbidZone
)
-> t/nil
```

**参数**：
- `t_zone`：区域名称。
- `o_dbidZone`：区域的 `dbid`。

**返回值**：
- `t`：成功。
- `nil`：失败。

**另请参见**：`axlZoneCreate`

**示例**：
```skill
;; 按名称删除区域
result = axlZoneDelete("ZONE_1")
;; 按 dbid 删除区域
zone = axlZoneAccess('name "ZONE_1")
when(zone axlZoneDelete(zone))
```

---

### axlZoneSet

**说明**：修改区域的特性。可以提供多组选项/参数。它们是：
- `'name t_newName`：重命名区域
- `'notes t_notes`：添加或更新注释；如果 `t_notes` 为 `nil` 则删除注释
- `'stackup t_stackup`：更新与区域关联的叠层；如果表面符号放置在区域中，则拒绝
- `'room t_roomName`：为区域分配房间名称。设计中不能存在同名房间。为 BOTH_ROOMS 创建房间形状。如果 `t_roomName` 为 `nil` 则删除房间名称。
- `'constraint t_constraintName`：分配约束区域。区域必须已存在于设计中，并在子类 "ALL" 上创建形状。如果 `t_constraintName` 为 `nil` 则删除约束区域。

**Original**: Modifies characteristics of a zone. More than one set of option/arguments can be provided. They are: 'name t_newName - Rename a zone; 'notes t_notes - Add or update the note; if t_notes is nil deletes the note; 'stackup t_stackup - Updates the stackup associated with zone stackup must currently exist and is rejected if surface symbols placed in the zone; 'room t_roomName - Assign room name to zone. Room with same name must not exist in the design. Creates a room shape for BOTH_ROOMS. If t_roomName is nil deletes room name; 'constraint t_constraintName - Assign constraint region. Region must already exist in design and creates a shape on subclass "ALL". If t_constraintName is nil deletes constraint area.

**语法**：
```skill
axlZoneSet(
t_name
/
o_dbidZone
s_option
g_argument
...
)
-> t/nil
```

**参数**：
- `t_name`：区域名称。
- `o_dbidOutline`：轮廓（形状），class==RIGID_FLEX 且 subclass==RIGFLEX_ZONE_OUTLINE。

**返回值**：
- `t`：成功。
- `nil`：失败。

**另请参见**：`axlZoneCreate`，`axlXSectionCreate`

**示例**：
```skill
;; 设置区域包括重命名；关联叠层和房间
ret = axlZoneCreate("ZONE_1" 'stackup "FLEX_1" 'room "ROOM_1")
```

---

## 焊盘访问函数 (Padstack Access Functions)

本节列出焊盘访问函数。

**Original**: This section lists padstack access functions.

### axlDBCreatePadStack

**说明**：添加焊盘 `t_name`，使用钻孔 `r_drill` 和焊盘定义 `l_pad`。

**Original**: Adds a padstack `t_name`, using drill hole `r_drill` and pad definition `l_pad`.

**用于创建焊盘的 Defstructs**：

**Drill (r_drill)**：使用 `make_axlPadStackDrill`。元素包括：
- `usage`：（字符串）焊盘用途。请参见 `axlPadstackUsageTypes()`。如果未提供此参数，代码将根据焊盘特性确定类型。
- `fixed`：（`t/nil`）内部固定标志。
- `spanLockCount`：（`t/nil`）默认值为 `nil`。如果为 `t`，添加或删除层时焊盘不会扩展或收缩。默认情况下它会扩展/收缩。
- `uvia`：（`t/nil`）如果焊盘类型为 `bbvia`，则设置为子类型微孔（micro-via）。已被 `usage` 类型取代。
- `keepout`：（`t/nil`）17.0 及以上版本已过时。使用新的 `KEEPOUT` 焊盘层类型。
- `pluralVia`：（`t/nil`）创建焊盘作为复数过孔（多网络）。仅通孔焊盘可以具有此设置。
- `holeType`：（符号）孔类型。允许符号：`CIRCLE_DRILL`、`SQUARE_DRILL`、`OVAL_SLOT`、`RECTANGLE_SLOT`。如果提供钻孔直径，则默认为 `CIRCLE_DRILL`。
- `plating`：（符号）钻孔的电镀状态。符号：`PLATED`、`NON_PLATED` 或 `nil`。
- `drillDiameter`：（浮点数）钻孔成品直径。
- `drillToolSize`：（字符串）钻孔工具尺寸，用作标识符。默认为空。
- `slotSize`：`((f_width f_height))` 槽孔尺寸。对于 SLOT 类型，请使用此参数代替 `drillDiameter`。`f_width` 或 "Y 尺寸" 是钻孔尺寸。`f_height` 或 "X 尺寸" 或钻孔行程。
- `holeTolerance`：`((f_pos f_neg))` +/- 孔公差。当槽定义 X 公差或走线公差时。
- `holeToleranceY`：`((f_pos f_neg))` +/- 孔公差。仅适用于槽，定义钻孔尺寸公差（Y 公差）。这是槽宽度。
- `offset`：`((f_x f_y))` 钻孔偏移。
- `multiDrillData`：多钻孔数据列表：`((x_num_rows x_um_columns f_clearance_x [f_clearance_y ["staggered"]]))`。数据类型为 `(int int float [float])`。
- `drillNonStandard`：（符号）非标准钻孔。支持符号：`LASER_DRILL`、`PLASMA_DRILL`、`PUNCH_DRILL`、`PHOTO_DRILL`、`COND_INK_DRILL`、`WET_DRY_DRILL`、`OTHER_DRILL`。
- `figure`：（符号）钻孔图形。允许符号：`NULL`、`CIRCLE`、`SQUARE`、`HEXAGON`、`HEXAGON_X`、`HEXAGON_Y`、`OCTAGON`、`CROSS`、`DIAMOND`、`TRIANGLE`、`OBLONG_X`、`OBLONG_Y`、`RECTANGLE`。注意 `nil` 被视为 `NULL`。
- `figureSize`：`((f_width f_height))` 钻孔图形尺寸。
- `drillChar`：（字符串）钻孔字符。最多 3 个字符。
- `holeCounterType`：（字符串）埋头孔类型："bore"、"sink" 或 `nil`。
- `holeCounterAngle`：（整数）适用于沉头孔，表示 1 到 90 度之间的角度。
- `holeCounterDiameter`：（浮点数）埋头孔直径，设计单位。
- `holeCounterDepth`：（浮点数）适用于锪孔，表示锪孔深度。精度保持在高于当前设计的水平。
- `holeCounterTolerance`：`((f_pos f_neg))` +/- 埋头孔公差。
- `backdrillDiameter`：（浮点数）背钻成品孔直径，设计单位。
- `backdrillFigureName`：（符号）背钻图形（参见 figure 的允许类型）。
- `backdrillFigureChar`：（字符串）背钻字符（最多 3 个）。
- `backdrillFigureWidth`：（浮点数）背钻图形宽度，设计单位。
- `backdrillFigureHeight`：（浮点数）背钻图形高度，设计单位。

**Pad (l_pad)**：结构（每个层最多 4 个，由属性类型指示）：
- `layer`：（字符串）蚀刻层名称（例如 "TOP"）或如果希望一个焊盘层映射到焊盘顶部和底部之间的所有内部层，则为 `DEFAULT_INTERNAL`。
- `type`：（符号）焊盘类型。允许符号：`KEEPOUT`、`ANTIPAD`、`THERMAL` 或 `REGULAR`。`nil` 被视为 `REGULAR`。
- `figure`：（符号）焊盘图形。对于允许符号，请参见 `axlPadFigureTypes` API。如果为 `NULL`，则检查 `figureSize` 并自动分配图形类型。如果分配了类型，则 `figureSize` 必须匹配该类型。例如，SQUARE 的宽度和高度必须相同。对于形状符号，使用 ssm 的名称（不含扩展名和路径）作为图形。例如，如果有一个名为 "myshape" 的形状符号，则应为 `'?figure "myshape"`。对于 Anti-pad 形状（fsm），将符号分配为 `FLASH` 并将 fsm 文件（不含扩展名和路径）分配给 flash 名称。例如，符号 "myflash" 应为：`'?figure 'FLASH ?flash "myflash"`。对于形状或 flash，符号必须通过 `PADPATH` 定位。此外，`figureSize` 属性必须是符号的范围或更大。
- `flash`：（字符串）焊盘孔径 flash 名称。引用 flash 形状符号名称或 `nil` 表示无 flash（fsm 文件）。
- `figureSize`：`((f_width f_height))` 图形的高度和宽度。对于圆形，只需将直径分配给高度/宽度之一，另一个可以为 0。
- `offset`：`((f_x f_y))` 相对于焊盘原点的偏移。
- `sides`：八角形焊盘专用：边数。范围为 6 到 64 之间的偶数。
- `inside`：圆环焊盘专用：内部尺寸，浮点数用户单位。
- `radius`：ROUNDED_RECTANGLE 和 CHAMFERED_RECTANGLE 焊盘专用：角半径，浮点数用户单位。
- `corners`：ROUNDED_RECTANGLE 和 CHAMFERED_RECTANGLE 焊盘专用：破折号分隔的字符串，表示倒角的角：`UR`（右上）、`UL`（左上）、`LR`（右下）、`LL`（左下）。如果焊盘类型不支持，则为 `nil`。例如："UR-LR" 表示倒角右上和左下角。
- `koAllowed`：KEEPOUT_AREA 焊盘专用。破折号分隔（大写）的字符串，表示允许在 keepout 区域内的对象。允许的对象：`VIAS`、`CLINES`、`SHAPES`、`PINS`。例如：`?koAllowed "VIAS-CLINES-PINS"` 表示允许在 keepout 内放置过孔、蚀刻线和引脚。

**编程说明**：
- `N_SIDED_POLY`：`figureSize` 使用宽度和高度中的较小值，并将其映射为直径。需要 `sides`，如果不存在，则焊盘变为圆形。`sides` 必须是 6 到 64 之间的偶数。如果 `sides` 为 0，则创建圆形焊盘。
- `ROUNDED_RECTANGLE / CHAMFERED_RECTANGLE`：需要 `radius` 和 `corners` 字符串。`radius` 不能大于高度或宽度中较小值的一半。如果 `radius` 为 0 或 `corners` 字符串不匹配任何角，则创建 `RECTANGLE` 焊盘。
- `DONUT`：`figureSize` 使用宽度和高度中的较小值，并将其映射为外径。需要内径，且必须小于外径。如果内径为零，则创建圆形焊盘。
- 要创建相邻层走线 keep-out 焊盘，请对 `make_axlPadStackPad` 使用以下选项：`?layer 'adjacent`，`?type 'KEEPOUT`。
- 要创建 Coverlay 焊盘层，请对 `?layer` 使用字符串 `"COVERLAY_TOP"` 或 `"COVERLAY_BOTTOM"`。`?type` 被忽略。
- 要创建背钻焊盘层，请使用：`?layer 'backdrillStart`，`?type "REGULAR"`（更大的焊盘用于钻起始层，正片层）；`?type "ANTI"`（更大的焊盘用于钻起始层，负片层）。`?layer 'backdrillClearance`，`?type "ANTI"`（内部背钻层的焊盘尺寸，负片层）。`?type "KEEPOUT"`（为正片层的背钻层生成 KEEPOUT）。`?layer 'backdrillSoldermask`——替代钻的阻焊层焊盘。
- 形状和 flash 分配符号规则：`REGULAR`——形状符号（可以设置 flash 符号名称以支持旧版 Gerber）；`THERMAL`——flash 符号；`ANTIPAD`——形状符号（可以设置 flash 符号名称以支持旧版 Gerber）；`KEEPOUT`——形状符号。
- 掩模层——flash 或形状符号。
- 形状符号可以包含一个无挖空的铜皮。
- flash 符号支持多个带挖空的铜皮。
- 用户掩模层支持需要调用 `axlPadUserMaskLayers` 并带 `'create` 选项以确保用户掩模层存在于设计中。如果您知道用户掩模层已存在，则无需进行此调用。
- 背钻数据可以由全局设计参数提供。以这种方式获取背钻数据的焊盘会显示这些值，但它们不会保存到磁盘焊盘文件（.pad）。

**语法**：
```skill
axlDBCreatePadStack(
t_name
r_drill
l_pad
[g_nocheck]
)
=> l_result/nil
```

**参数**：
- `t_name`：焊盘名称。
- `r_drill`：焊盘的钻孔数据。注意：与所有 SKILL 的 `defstruct` 一样，使用构造函数 `make_axlPadStackDrill` 创建 `axlPadStackDrill` 的实例。请参见示例。
- `l_pad`：焊盘的焊盘定义数据。注意：与所有 SKILL 的 `defstruct` 一样，使用构造函数 `make_axlPadStackPad` 创建 `axlPadStackPad` 的实例。请参见示例。
- `g_nocheck`：可选。`t` 禁用焊盘定义检查。`nil` 执行以下焊盘定义检查：
  - 连续的焊盘定义
  - Anti-pad/thermal-relief 焊盘定义
  - 钻孔存在两个焊盘
  - 钻孔存在两个焊盘

**返回值**：
- `l_result`：创建的焊盘的 `dbid`。
- `nil`：未创建任何内容。

**另请参见**：`axlPadstackEdit`，`axlLoadPadstack`，`axlDBCopyPadstack`，`axlPadstackToDisk`，`axlDBGetPad`，`axlPadUserMaskLayers`，`axlPadFigureTypes`，`axlPadstackUsageTypes`，`axlPadDbidDoc`

**示例**：
```skill
;; 表面贴装焊盘示例
;; 添加一个 25x60 矩形焊盘的表面贴装焊盘
pad_list = cons(make_axlPadStackPad(?layer "TOP", ?type 'REGULAR,
  ?figure 'RECTANGLE, ?figureSize 25:60) nil)
ps_id = axlDBCreatePadStack("smt_pad", nil, pad_list t)

;; 其他示例位于：
;; <cdsroot>/share/pcb/examples/skill/dbcreate/pad.il
```

---

### axlPadFigureTypes

**说明**：返回支持的焊盘图形类型的字符串列表。并非所有焊盘类型和层都可能支持某种图形类型。这是一个文档支持函数。

**Original**: Returns list of strings of supported pad figure types. Not all pad types and layers may support a figure type. This is a documentation support function.

**语法**：
```skill
axlPadFigureTypes()
=> lt_names
```

**参数**：无。

**返回值**：
- `lt_names`：允许的焊盘图形类型列表。

**示例**：
```skill
axlPadFigureTypes()
```

---

### axlPadstackEdit

**说明**：查询和设置显示选项。编辑现有焊盘的全局设置。这会编辑焊盘定义，这意味着所做的任何更改都适用于设计中焊盘的所有实例（引脚和过孔）。

支持以下模式：
- 如果前两个参数为 `nil`，命令返回所有可编辑属性的列表。
- 如果提供了焊盘、属性和新值，则更改焊盘的一个属性。
- 如果提供了焊盘和属性及其新值列表，则更改焊盘上指定的所有项。这是更改单个焊盘上多个项的最有效方法。
- 顺序很重要，因此如果要将圆形钻孔更改为槽，则必须先提供 `holeType`，然后提供 `drillSizeWidth` 和 `drillSizeHeight`。
- 为获得最佳性能，如果要在单个焊盘上更改多个项，请使用列表模式一次性更改所有项。

当前仅支持全局焊盘设置。不允许编辑焊盘层特性。某些更改会使 DRC 过期，并使动态铜皮失效。当前支持的属性（所有等效项都是 `pad_designer` 中的字段名称）：

**Original**: Inquire and set display options. Edits global settings of an existing padstack. This edits the padstack definition, this means that any changes made applies to all instances of the padstacks (pins and vias) in the design. Supports the following modes: If first two arguments are nil, command returns a list of all editable attributes. If padstack, attribute, and new value are provided, changes one attribute of padstack. If padstack, and a list of attributes with new values are provided change all the items specified in the padstack. This is the most efficient method for changing multiple items on a single padstack. Order is important, so if you are changing a CIRCULAR drill to a slot then you must provide the holeType followed by drillSizeWidth and drillSizeHeight. For best performance if changing multiple items in a single padstack use the list mode to change all items in one call. Currently only global padstack settings are supported. Editing pad layer characteristics in not allowed. Certain changes set DRC out of date and dynamic shapes out of date.

**表 5-2：支持的控件**

| 名称 | 值 | 说明 | 等效项 | 副作用 |
|------|------|------|--------|--------|
| usage | 符号或字符串，可能值：'Smd、'Through、'Through_pin、'Surface_pin、'Bbvia、'Through_via、'uvia、'Bond_finger、'Die_pad、'Fiducial、'Mechanical_hole、'Mounting_hole、'Slot | 更改焊盘分类。在某些情况下，焊盘的使用可能会覆盖实际焊盘用途类型。Smd 和 Surface_pin 相同，但未来版本将检查 Surface_pin 仅用于引脚。类似地，Through、Through_via 和 Through_pin 相同，但未来版本将支持检查。 | Padstack Usage type 或 'usage 属性 | DRC 过期且动态铜皮被禁用 |
| drillDiameter | dbrep | 更改钻孔直径。值必须为正数，且 holeType 不能为槽。对于多钻孔，适用于所有钻孔。 | Drill diameter field | DRC 过期且动态铜皮被禁用 |
| drillSizeWidth | dbrep | 更改槽尺寸宽度（X 方向）。值必须为正数，且 holeType 必须为槽类型。通常与 drillSizeHeight 一起完成。 | Slot size X | DRC 过期且动态铜皮被禁用 |
| drillSizeHeight | dbrep | 更改槽尺寸高度（Y 方向）。值必须为正数，且 holeType 必须为槽类型。通常与 drillSizeWidth 一起完成。 | Slot size Y | DRC 过期且动态铜皮被禁用 |
| drillToolSize | string | 设置钻孔工具尺寸名称。如果焊盘没有钻孔，则不适用。 | Drill tool size | 无 |
| holeType | string | "CIRCLE_DRILL"、"SQUARE_DRILL"、"OVAL_SLOT" 或 "RECTANGLE_SLOT" 之一。更改焊盘孔类型。如果更改基本类型：槽到钻孔；drillDiameter 继承 drillSizeWidth。钻孔到槽；drillSizeWidth 和 drillSizeHeight 都继承 drillDiameter。对于槽，drillFigureName 采用所选槽类型的图形，其宽度和高度与槽宽度和高度相同。 | Hole type | DRC 过期且动态铜皮被禁用 |
| drillNonStandard | string | 更改非标准钻孔类型。孔类型必须是圆形钻孔。类型："LASER_DRILL"、"PLASMA_DRILL"、"PUNCH_DRILL"、"PHOTO_DRILL"、"COND_INK_DRILL"、"WET-DRY_DRILL"、"OTHER_DRILL"。使用 `nil` 如果要取消设置此字段。 | Non-standard drill | 无 |
| drillOffset | point/dbrep | 更改钻孔偏移。必须是 xy 点或单个 dbrep，适用于 x 和 y。 | Offset X and Y | DRC 过期且动态铜皮被禁用 |
| holeTolerance | point/dbrep | 更改孔公差。点值被视为 `(+tolerance -tolerance)` 列表或单个 dbrep，适用于 + 和 -。两者都必须是正数。 | Tolerance + and - | 无 |
| holeToleranceY | point/dbrep | 更改槽 Y 公差。点值被视为 `(+tolerance -tolerance)` 列表或单个 dbrep，适用于 + 和 -。两者都必须是正数。 | Y Tolerance + and - for slots | 无 |
| plating | string | 设置电镀类型，必须是 "NON_PLATED"、"OPTIONAL" 或 "PLATED" 之一。 | Plating | 无 |
| pluralVia | t/nil | 设置焊盘为复数过孔。仅通孔焊盘可以设置此选项。焊盘不能在设计中使用。 | Plural Via | 仅通孔焊盘可以设置此选项。焊盘不能在设计中使用。 |
| drillChar | string | 设置钻孔字符。最多支持 3 个字符的字符串。较长的字符串将被截断。使用 `nil` 删除字符串。 | Characters | 无 |
| drillFigureName | string | 设置钻孔图形类型。槽不支持。值必须是与 `pad_designer` 中 "Figure" 字段的下拉项之一匹配的字符串。 | Figure | 无 |
| drillFigureHeight | dbrep | 更改图形高度，值必须为正数。槽不可用。与 drillFigureWidth 一起使用。 | Height (under Drill/Slot symbol) | 无 |
| drillFigureWidth | dbrep | 更改图形宽度，值必须为正数。槽不可用。与 drillFigureHeight 一起使用。 | Width (under Drill/Slot symbol) | 无 |
| backdrillDiameter | float | 更改背钻直径。值必须为正数，且 holeType 必须是常规孔。 | Secondary Drill tab | 无 |
| backdrillFigureChar | string | 设置钻孔字符。最多支持 3 个字符的字符串。较长的字符串将被截断。使用 `nil` 删除字符串。 | Secondary Drill tab | 无 |
| backdrillFigureName | string | 设置背钻图形类型。值必须是与 `pad_designer` 中 "Figure" 字段的下拉项之一匹配的字符串。 | Secondary Drill tab | 无 |
| backdrillFigureHeight | dbrep | 更改背钻图形高度，值必须为正数。与 backdrillFigureWidth 一起使用。 | Secondary Drill tab | 无 |
| backdrillFigureWidth | dbrep | 更改背钻图形宽度，值必须为正数。与 backdrillFigureHeight 一起使用。 | Secondary Drill tab | 无 |
| spanLockCount | t/nil | 防止非通孔焊盘在添加（或删除）层时扩展（或收缩）。默认情况下，这些焊盘保持其原始起始/停止层。 | Lock layer span | 具有此选项的焊盘在添加新层时可能会产生断开。 |
| uvia | t/nil | 设置过孔类型为 bbvia（nil）或微孔（t）。焊盘必须是 bbvia。 | 保持向后兼容性。使用 'type 选项。 | DRC 过期且动态铜皮被禁用 |
| keepout | nil | 17.0 中已过时。使用新的 route keepout 焊盘层类型。 | none | 无 |

**语法**：
```skill
axlPadstackEdit(
nil
nil
)
==> l_attributes
axlPadstackEdit(
o_dbidPadstack/t_Padstack
s_name
g_value
)
==> t/nil
axlPadstackEdit(
o_dbidPadstack/t_Padstack
[[s_name g_value] .... ]
)
==> t/nil
```

**参数**：
- `o_dbidPadstack`：焊盘的 `dbid`（注意不支持 VIA 和 PIN `dbid`）。
- `t_Padstack`：焊盘名称。
- `s_name`：要更改的属性符号名称。
- `g_value`：新值。
- `[[s_name g_value] .. ]`：名称/值对列表。

**返回值**：
- `ls_names`：如果名称为 `nil`，则返回所有控件的列表。
- `t/nil`：如果成功更新焊盘则为 `t`，错误则为 `nil`。

**示例**：
```skill
;; 使用 ashOne 共享软件 SKILL 查找焊盘。注意选择将返回引脚或过孔，您必须从 definition 属性获取焊盘。
p = ashOne()
padstack = p->definiton
;; 设置钻孔字符
ret = axlPadstackEdit(padstack 'drillChar "abc")
```

**另请参见**：`axlDBCreatePadStack`，`axlLoadPadstack`，`axlDBCopyPadstack`，`axlReplacePadstack`

---

### axlPadstackSetType

**说明**：更改焊盘类型。在两参数模式下与以下相同：`axlPadstackSetType(padstack 'type g_uviaBbvia)`。允许更改过孔类型。`'type`：将 bbvia 焊盘更改为微孔，反之亦然。Uvia 类型可以在约束系统中单独管理。如果焊盘用于引脚，则无效。值为 `'bbvia` 或 `'uvia`。`'keepout`：17.2 中已过时。创建 `KEEPOUT` 类型的 keepout 焊盘层。如果成功，标记 DRC 过期。

**Original**: Changes a padstack type. In its 2 argument mode is the same as: `axlPadstackSetType(padstack 'type g_uviaBbvia)`. Permits changing the type of via. 'type Changes a bbvia padstack to a micro via and vice versa. Uvia types can be managed separately in the constraints system. This has no effect if the padstack is used with Pins. Values are 'bbvia or 'uvia. 'keepout Obsolete in 17.2. Create a keepout pad layer type of KEEPOUT. Marks DRC out-of-date if successful.

**语法**：
```skill
axlPadstackSetType(
o_padstack/t_padstack
g_uviaBbvia
)
-> t/nil
axlPadstackSetType(
o_padstack/t_padstack
g_type
g_value
)
-> t/nil
```

**参数**：
- `o_padstack`：焊盘 `dbid`。
- `t_padstack`：焊盘名称。
- `g_type`：模式（`'type` 或 `'keepout`）。
- `g_value`：适当的设置（见上文）。

**返回值**：
- `t`：更改成功。
- `nil`：失败。不是焊盘，焊盘不在数据库中，类型未识别或焊盘不是 bbvia 或 uvia。

**示例**：
```skill
;; 将名为 VIA 的焊盘更改为微孔
axlPadstackSetType("VIA" 'type 'uvia)
```

**另请参见**：`axlDBCreatePadStack`，`axlPadstackEdit`

---

### axlPadstackUsageTypes

**说明**：返回支持的焊盘用途类型的字符串列表。这是一个文档支持函数。

**Original**: Returns list of strings of supported padstack usage types. This is a documentation support function.

**语法**：
```skill
axlPadstackUsageTypes()
=> lt_names
```

**参数**：无。

**返回值**：字符串列表。

**示例**：
```skill
axlPadstackUsageTypes()
```

---

### axlPadUserMaskLayers

**说明**：支持以下模式：如果参数返回设计中的用户掩模层列表；`'max` 符号选项报告我们支持的最大数量；`'create` 添加新的用户掩模层；需要名称。

用户掩模命名：如果使用 `_TOP` 和 `_BOTTOM` 后缀，则会获得镜像支持。这意味着如果镜像定义在 xxx_TOP 上的用户掩模的过孔，它将被镜像到底部。请参见 `axlDBControl('mirrorUserMask)`。启用镜像掩模选项后，将自动创建对面的掩模。

**Original**: Supports following modes: if argument returns list of user mask layers in design; 'max symbol option reports the maximum number that we support. 'create adds a new user mask layer; requires a name. User mask naming: If you use _TOP and _BOTTOM suffixes, then you will get mirror support. This means if you mirror a VIA with a user mask defined on xxx_TOP then it will be mirrored to the bottom. See axlDBControl('mirrorUserMask). With the mirror mask option enabled, the opposite side mask is auto-created.

**语法**：
```skill
axlPadUserMaskLayers(
['max]
)
=>lt_names/x_cnt
axlPadUserMaskLayers(
'create
t_user_mask_layer
)
=>t/nil
```

**参数**：
- `'max`：可选。如果提供，返回支持的最大用户掩模层数量。
- `'create`：创建新的用户掩模层，需要 `t_user_mask_layer`。
- `t_user_mask_layer`：用户掩模层名称。

**返回值**：
- `lt_names`：用户掩模名称列表。
- `x_cnt`：允许定义的最大数量。
- `t/nil`：在创建模式下，如果层已创建或存在则返回 `t`，如果创建失败则返回 `nil`。失败可能由于：可用用户掩模层数量耗尽；名称非法。

**另请参见**：`axlDBCreatePadStack`，`axlDBControl`

**示例**：
```skill
;; 典型用途：获取所有定义的层
axlPadUserMaskLayers()
;; 返回可定义的最大数量
axlPadUserMaskLayers('max) -> 32
```
