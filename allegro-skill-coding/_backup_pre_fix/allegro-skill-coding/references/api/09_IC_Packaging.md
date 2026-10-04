# 9. IC 封装 (IC Packaging)

**产品文档**：Allegro SKILL Reference  
**产品版本**：17.4-2019, October 2019

本章列出的函数仅在 Allegro Package Designer+ (APD+) 中可用。

**Original**: The functions listed in this chapter are available only in Allegro® Package Designer+ (APD+).

---

### axlBGATextIn

**说明**：使用包含 BGA 信息的 ASCII 文本文件导入 BGA。这是 BGA 文本导入向导的 SKILL 包装器。仅提供文件名等同于选择包含 BGA 信息的 ASCII 文本文件，然后在 BGA 文本导入向导的剩余步骤中单击 "Next"。不执行导入后步骤，如清除未使用的网络。

**Original**: Imports a BGA using an ASCII text file containing the BGA information. This is a SKILL wrapper for the BGA Text-In Wizard. Providing only a filename is equivalent to selecting an ASCII text file containing the BGA information and then clicking Next for the remaining steps in the BGA Text-In Wizard. Post-import steps like purging unused nets are not done.

**语法**：
```skill
axlBGATextIn(
t_filename
?delim t_delim
?delimConsec b_consec
?delimTrail b_trail
?header g_header
?unMirrorY b_mirror
?symName t_symname
?refDes t_refdes
?origin g_origin
?extents g_extents
?rotation d_rotation
?layer t_layer
)
==> t/ErrorMsg/nil
```

**参数**：
- `t_filename`：指定要导入的文件名。
- `t_delim`：指定最多六个分隔符来分隔数据列。
- `b_consec`：设置忽略连续分隔符。
- `b_trail`：设置忽略尾随分隔符。
- `g_header`：指定要导入的标题名称列表。必须与导入文件中的列数匹配。
- `b_mirror`：设置取消镜像 BGA 的 Y 引脚。
- `t_symname`：指定要使用的符号名称。
- `t_refdes`：指定 BGA 符号的参考位号。
- `g_origin`：指定符号原点。
- `g_extents`：指定符号范围。
- `d_rotation`：指定 BGA 的旋转。
- `t_layer`：指定焊盘层。

**返回值**：
- `t`：BGA 导入成功。
- `ERROR` 消息：如果选项无效。
- `nil`：如果导入因无效选项以外的任何原因不成功。

**示例**：
```skill
axlBGATextIn("BGA_data.txt")
axlBGATextIn("BGA_data.txt" ?delim "\t" ?rotation 20.0 ?refDes "ABC")
axlBGATextIn("BGA_data.txt" ?delim "\t" ?delimConsec nil ?delimTrail t
  ?header '("Pin Number", "Padstack", "X Coord", "Y Coord", "Rotation", "Pin Use", "Net Name")
  ?unMirrorY nil ?symName "BGA_N" ?refDes "BGA_S" ?origin '(1000 -2000)
  ?extents '(-10000 -10000 10000 10000) ?rotation 20.0 ?layer "BOTTOM" )
```

**另请参见**：`axlDieTextIn`，`axlNetlistTextIn`

---

### axlChangeLayer

**说明**：更改线条、蚀刻线或线段、铜皮和文本的层。在全局级别提供的功能与 Allegro PCB Editor `change` 命令匹配，但在某些领域可能有所不同。

如果跨层移动蚀刻线或蚀刻线段，应提供一个过孔用于保持连接。过孔必须符合约束规则。要使过孔被接受，它必须：
- 在起始层和目标层上有焊盘
- 在 net 和 location 的约束过孔列表中

如果提供的焊盘不被接受，系统将基于 net 和 location 的过孔列表选择一个可接受的焊盘。

如果需要更改多个蚀刻对象的层，将 `dbid` 列表传递给此函数比为每个 `dbid` 单独调用效率更高。

**Original**: Changes layer for lines, clines or segments, shapes, and text. Functionality offered, at the global level, matches the Allegro PCB Editor `change` command, but can differ in certain areas. If moving clines or cline segments across layers, you should provide a via to be used to maintain connections. Via must meet constraint rules. For via to be accepted it must have: pads on start and destination layers; be in the constraint via list for the net and location. If the provided padstack is not acceptable, system will select an acceptable padstack based upon the via list for net and location. If you need to change the layer of multiple etch objects, it is more efficient to pass them as a list of dbids then to call this function for each dbid.

**语法**：
```skill
axlChangeLayer(
lo_dbid/o_dbid
t_newLayer
[o_padStackDbid]/[t_padstackname]
)
==> t/nil
```

**参数**：
- `lo_dbid/o_dbid`：单个 `dbid` 或 `dbid` 列表。
- `t_newLayer`：`dbid` 的新放置层。
- `o_padStackDbid`：如果跨层移动蚀刻线，Allegro 将添加一个过孔以保持连接。这是该过孔。如果未提供此参数，则使用系统默认过孔。
- `t_padStackName`：要使用的焊盘名称。

**返回值**：
- `t`：成功。
- `nil`：失败。

**失败原因**（调试时设置 `axlDebug(t)` 可查看额外信息）：
- `dbid` 是不支持的类型。
- 非法选项类型。
- 目标层与对象当前层匹配。

**示例**：
```skill
;; 将对象移动到 ETCH/BOTTOM
;; ashOne 是位于 <cdsroot>/pcb/examples/skill/ash-fxf/ashone.il 的选择工具
dbid = ashOne()
;; 选择一个对象（设置查找过滤器）
result = axlChangeLayer(dbid "ETCH/BOTTOM")
;; 或者如果移动蚀刻线
result = axlChangeLayer(dbid "ETCH/BOTTOM" "PAD60SQ36D")
```

**另请参见**：`axlTransformObject`，`axlDBChangeText`，`axlChangeWidth`

---

### axlCNSAssemblyModeGet

**说明**：检索当前装配 DRC 模式。模式确定特定约束是否开启或关闭。这些 DRC 模式适用于整个设计。使用 `axlCNSAssemblyModeGet(nil)` 确定当前支持的装配模式。`'print` 模式提供报告中显示的名称（如 show element）。未来版本可能会添加或删除约束检查。axl 接口不保证此接口返回的检査在版本之间保持不变。

**Original**: This retrieves the current assembly DRC mode(s). Modes determine if a particular constraint is on or off. These DRC modes apply to the entire design. Use `axlCNSAssemblyModeGet(nil)` to determine the set currently supported assembly modes. The 'print mode offers the name shown in reports like show element. Future releases may add or subtract constraint checks. The axl interface does guarantee the checks returned by this interface will remain constant from release to release.

**语法**：
```skill
axlCNSAssemblyModeGet(
nil
) => ls_constraints
axlCNSAssemblyModeGet(
'all
) => lls_constraintNModes
axlCNSAssemblyModeGet(
s_name/t_name
) => s_mode/nil
axlCNSAssemblyModeGet(
s_name/t_name
'print
) => t_name/nil
```

**参数**：
- `nil`：返回间距域中的所有模式。
- `'all`：返回所有检查和当前模式。
- `s_name`：检查的符号名称。
- `t_name`：检查的字符串名称。
- `'print`：可打印约束名称选项。

**返回值**：
- `ls_names`：检查列表 `(s_name ...)`。
- `lls_names`：检查及其模式列表 `((s_name s_mode) ...)`。
- `s_mode`：模式 `'on` 或 `'off`。
- `t_name`：可打印约束名称。

**示例**：
```skill
;; 获取当前装配约束列表
axlCNSAssemblyModeGet(nil)
;; 获取所有装配约束的设置列表
axlCNSAssemblyModeGet('all)
;; 获取 Die to Finger Spacing 检查的当前模式
axlCNSAssemblyModeGet('die_to_finger)
```

**另请参见**：`axlCNSAssemblyModeSet`，`axlCNSGetAssembly`

---

### axlCNSAssemblyModeSet

**说明**：此命令设置装配约束区域中检查的当前 DRC 模式（开启/关闭）。这些模式是全局的。要确定当前支持的约束模式，请使用 `axlCNSAssemblyModeGet(nil)`。

此命令支持多种接口：所有检查（`'all`）、单个检查（`t_name`）、模式内的检查列表（`'(s_name ...) t_mode/s_mode`）、通过列表设置的检查集合（`'((s_name/t_name s_mode/t_mode) ....)`）。约束名称可以作为符号或字符串传递。出于性能原因，要么在单个调用中完成所有更新，要么将单个更改包装在 map API 中（参见 `axlCNSMapUpdate`）。

未来版本可能会添加或删除约束检查。axl 接口不保证此接口返回的检査在版本之间保持不变。

**Original**: This command sets the current DRC modes (on/off) for checks in the area of assembly constraints. These modes are global. To determine the constraints modes currently supported, use `axlCNSAssemblyModeGet(nil)`. Several interfaces are supported for this command, all checks ('all), individual checks (t_name), list of checks within a mode, and sets of checks via a list. The constraints names may be passed as a symbol or a string. For performance reasons, either do all your updates in a single call or wrap individual changes in the map API (see `axlCNSMapUpdate`). Future releases may add or subtract constraint checks. The axl interface does guarantee the checks returned by this interface will remain constant from release to release.

**语法**：
```skill
axlCNSAssemblyModeSet(
t_name/s_name
t_mode/s_mode
)
=> t/nil
axlCNSAssemblyModeSet(
'all
t_mode/smode
)
=> t/nil
axlCNSAssemblyModeSet(
l_constraintNModes
t_mode/smode
)
=> t/nil
axlCNSAssemblyModeSet(
ll_constraintNModes
)
=> t/nil
```

**参数**：
- `s_name`：检查的符号名称。
- `t_name`：检查的字符串名称。
- `s_mode`：模式设置；可以是 `'on` 或 `'off`。
- `t_mode`：字符串模式设置 "on" 或 "off"。
- `'all`：设置所有装配设计规则检查（包括在线走线规则）的所有检查。

**返回值**：
- `t`：成功。
- `nil`：失败。

**示例**：
```skill
;; 关闭所有约束
axlCNSAssemblyModeSet('all 'off)
;; 开启 Die to Finger Spacing 检查
axlCNSAssemblyModeSet('die_to_finger 'on)
;; 开启两个约束
axlCNSAssemblyModeSet('(via_to_package_edge die_to_finger) 'on)
;; 将各种约束设置为不同模式
axlCNSAssemblyModeSet( '((die_to_finger off) (via_to_package_edge 'on)) )
```

**另请参见**：`axlCNSAssemblyModeGet`，`axlCNSGetAssembly`，`axlCNSMapUpdate`

---

### axlCNSGetAssembly

**说明**：获取装配约束集（cset）值。在第一种操作模式下，命令获取给定 cset 和层的装配约束值。在第二种操作模式下，它获取 cset 在层上的所有装配约束作为名称-值对。在最后一个模式下，通过向接口传递三个 `nil` 值来获取所有支持的装配约束列表：`axlCNSGetAssembly(nil nil nil)`。

**数据类型**：除非另有说明，约束以当前设计单位表示。

**Original**: Obtains an Assembly cset values. In the first operational mode, the command obtains the value of an assembly constraint given a cset and a layer. In second mode of operation, it obtains all assembly constraint as name-value pairs for a cset on a layer. For the last mode, a list of all supported assembly constraints is obtained by passing three nil values to the interface: `axlCNSGetAssembly(nil nil nil)`. DATA TYPES — Unless otherwise specified constraints are in current design units.

**语法**：
```skill
axlCNSGetAssembly(
t_cset
t_layer
s_constraint
[g_string]
)
=> g_value/nil
axlCNSGetAssembly(
t_cset
t_layer
nil
[g_string]
)
=> ll_nameValue/nil
axlCNSGetAssembly(
nil
nil
nil
)
=> ls_cnsTypes
```

**参数**：
- `t_cset`：装配 cset 的名称。使用 `""` 表示设计级约束。
- `t_layer`：ETCH 层名称（例如 "ETCH/TOP" 或 "TOP"）。如果指定 `nil`，则获取所有层上的约束。
- `s_constraint`：约束名称。如果为 `nil`，返回所有约束的符号/值对集合。
- `g_string`：默认情况下，以约束的原生单位返回值。如果 `g_string` 设置为 `t`，则数据作为字符串返回。

**返回值**：
- `g_value`：约束值，设计单位。
- `ll_nameValue`：装配约束符号和约束值的名称-值对。`'((wire_len_min 10.0) (wire_len_max 50.0) ...)`
- `ls_cnsTypes`：支持的装配约束名称列表。
- `nil`：表示错误。

**示例**：
```skill
;; 获取设计 cset 中的最小走线长度
axlCNSGetAssembly("" nil 'wire_len_min)
;; 获取 "V" cset 的所有装配约束，底层
axlCNSGetAssembly("V" "BOTTOM" nil)
;; 获取 "V" cset 的最小铜皮约束，顶层
axlCNSGetAssembly("V" "TOP" 'min_shape_check)
;; 获取支持的装配约束符号
axlCNSGetAssembly(nil nil nil)
;; 获取装配 cset V 的所有层和约束
cset = "V"       ;; D
foreach(subclass axlSubclassRoute()
  layer = axlCNSGetAssembly(cset subclass nil)
  printf("\nLAYER=%s\n\tconstraints=%L\n" subclass, layer)
)
```

**另请参见**：`axlCNSSetAssembly`

---

### axlCNSSetAssembly

**说明**：更新装配 cset、走线轮廓或符号约束值。通过在适当的参数传递 `nil`，可以更改所有 cset 和所有层的值。默认情况下，对象类型是 cset。要更新走线轮廓上的值，请使用走线轮廓作为对象名称，并将第五个参数传递为 `'PROFILE`。要更新符号（芯片、垫片或中介层）上的值，请使用 refdes 作为对象名称，并将第五个参数指定为 `'SYMBOL`。

**数据类型**：请参见 `axlCNSGetAssembly` 了解每个约束的数据类型。
- 设计单位：整数或浮点数，单位为当前设计单位。不得超过设计的精度。
- 无单位字符串：精度不能超过数据库精度。
- 带单位的字符串：数据转换为当前设计单位。
- 布尔值：使用 `t/nil` 或 "true"/"false"。

有关装配约束列表，请参见 `axlCNSGetAssembly`。

这不会更改覆盖值。例如，您可以在所有 cset 中设置 `wire_len_min` 值，但如果用户已将其作为覆盖应用于走线轮廓，则仍会为这些项使用。

**Original**: Updates assembly cset, wire profile or symbol constraint values. By passing `nil` at the appropriate argument, values for all csets and all layers may be changed. By default, object type is a cset. To update values on wire profile, use wire profile as an object name and pass fifth argument as 'PROFILE. To update values on symbols (dies, spacers or interposers) use refdes as an object name, and specify the fifth argument as 'SYMBOL. DATA TYPES — See `axlCNSGetAssembly` for the data type of each constraint. Design Units: A number (integer or floating point) where units is current design units. Must not exceed accuracy of the design. Unit less string where accuracy cannot exceed db accuracy. String with units, data converted to current design units. Boolean: Use `t/nil` or "true"/"false". For list of Assembly constraints see `axlCNSGetAssembly`. This does NOT change override values. For example, you can set wire_len_min value in all csets but if the user has applied it to a wire profile as an override, it will still be used for those items.

**语法**：
```skill
axlCNSSetAssembly(
t_object/nil
t_layer/nil
s_constraint
g_value
[s_object_type]
)
==> t/nil
axlCNSSetAssembly(
t_object/nil
t_layer/nil
ll_constraintValues
nil
[s_object_type]
)
==> t/nil
```

**参数**：
- `t_object`：cset 名称，使用 `""` 表示设计级约束。使用 `nil` 将更改应用于所有 cset。走线轮廓名称或 die refdes。
- `t_layer`：ETCH 层名称（例如 "ETCH/TOP" 或 "TOP"）。如果为 `nil`，则将更改应用于所有层——仅适用于按层约束。对于不能按层设置的约束，使用 `nil`。
- `s_contraint`：要更改的约束符号。使用 `axlCNSGetAssembly(nil nil nil)` 获取允许值的列表。
- `g_value`：要更新的值。有关数据类型，请参见上文 "数据类型"。
- `ll_constraintValues`：可以通过向第三个参数传递列表的列表来更新多个值。`'((s_contraint g_value) ... )`
- `s_object_type`：默认情况下，对象类型是 cset。使用 `'SYMBOL` 表示 die，`'PROFILE` 表示走线轮廓。

**返回值**：
- `t`：成功。
- `nil`：错误。如果：
  - cset 名称不存在
  - 层不存在
  - 约束不存在
  - 约束值非法

**示例**：
```skill
;; 在所有约束集和层上设置最小铜皮检查
axlCNSSetAssembly(nil nil 'min_shape_check 50)
;; 在设计级所有层上设置最小挖空检查
axlCNSSetAssembly("" nil 'min_void_check 60)
;; 在走线轮廓 PROFILE1 上设置最小走线长度
axlCNSSetAssembly("PROFILE1" nil 'wire_len_min 75 'profile)
;; 在 die U1 上设置 die 悬垂 x
axlCNSSetAssembly("U1" nil 'die_overhang_x 50 'symbol)
```

**另请参见**：`axlCNSGetAssembly`

---

### axlCreateDeviceFileTemplate

**说明**：创建模板器件文件，提供与符号编辑器中创建器件命令相同的功能。通常，如果在电路板中，您会使用 `axlDBCreateComponent` 创建器件文件。

**Original**: This creates a template device file providing same functionality as the create device command in the symbol editor. Normally you would use `axlDBCreateComponent` to create a device file if in the board.

**语法**：
```skill
axlCreateDeviceFileTemplate(
t_deviceName
t_CLASS
l_pinList
)
-> t/nil
```

**参数**：
- `t_deviceName`：器件文件名（无文件扩展名或路径）。
- `t_CLASS`：器件类别（例如，IC、IO 等）。
- `l_pinList`：引脚列表。可以是引脚 `dbid` 或引脚编号的任意组合。如果是引脚 `dbid`，将过滤掉机械引脚。

**返回值**：
- `t`：文件已创建。
- `nil`：有问题。

**另请参见**：`axlDBCreateComponent`

---

### axlCompAddPin

**说明**：此函数向指定元件添加一个或多个引脚。引脚添加到相应的元件和符号定义中，更改会反映在这些定义的所有实例中。

**Original**: This function adds one or more pins to the specified component. Pins are added to the corresponding component and symbol definition, with changes being reflected in all instances of those definitions.

**语法**：
```skill
axlCompAddPin(
o_comp
g_absLoc
o_pin/lo_pins
)
=> t/nil
```

**参数**：
- `o_comp`：要添加引脚的元件实例的 `dbid`。
- `g_absLoc`：如果为 `true`，引脚的位置和旋转是设计空间中的绝对值。如果为 `nil`，这些值是相对于未镜像、未旋转的符号定义原点的。
- `o_pin/lo_pins`：定义要添加引脚的结构或结构列表。这些对象是下面定义的 `defstruct`。

**用于定义引脚的 Defstruct**：使用 `make_axlCompPinRecord`。

**必需元素**：
- `s_pinUse`：此引脚的引脚用途代码。必须是以下符号之一：`UNSPEC`
- `n_swapCode`：此引脚的交换组代码。交换代码为 `0` 表示此引脚不可交换。否则，所有具有相同交换代码的引脚都是可交换的。此值不用于协同设计元件，因为所有协同设计元件引脚都被认为是可交换的。
- `l_location`：引脚的 X/Y 坐标位置。绝对或相对于符号定义原点，由 `g_absLoc` 指定。
- `n_rotation`：此引脚的角旋转。绝对或相对于符号定义原点，由 `g_absLoc` 指定。

**可选元素**：
- `pinNumber`：分配给此引脚的物理引脚编号。必须在元件的所有引脚中唯一。如果未提供引脚编号，引脚编号将根据元件的引脚编号方案计算。如果编号方案为 'Customized'（协同设计对象的默认方案），则工具将分配第一个未使用的整数作为引脚编号（1, 2...）。
- `pinName`：引脚的逻辑引脚名称。不用于电源/地引脚。如果未提供，信号引脚的引脚名称将与物理引脚编号相同。
- `verilogPort`：引脚的 Verilog 端口名称。不用于电源/地引脚。如果未提供，引脚没有 Verilog 端口名称，函数引脚名称将被使用。
- `net`：创建时分配给此引脚的网络名称或 `dbid`。如果为 `nil`，引脚将在虚拟网络上创建，可以稍后分配。
- `padstack`：用于此引脚的焊盘名称或 `dbid`。如果未提供焊盘，则此元件引脚已使用的焊盘也将用于此引脚。

**协同设计元素**：
- `codesignNet`：此引脚在辅助设计空间中的网络名称。例如：对于封装中的协同设计芯片，这是 IC 设计中引脚的网络。
- `codesignPad`：此引脚在辅助设计空间中的焊盘/单元名称。例如：对于封装中的协同设计芯片，这是引脚的 LEF 凸点宏。

**返回值**：
- `t`：如果引脚已添加。
- `nil`：如果添加任何引脚时出错，例如，如果引脚将放置在符号或图纸范围之外。

如果要添加许多引脚，将整个列表传递给此函数以一次性处理它们比使用 `axlCompAddPin` 处理每个单独引脚效率更高。

**另请参见**：`axlCompDeletePin`，`axlCompMovePin`

---

### axlCompDeletePin

**说明**：此函数从父元件和符号定义中删除指定的引脚。因此，该引脚也将从这些定义的所有实例中删除，而不仅仅是传递的引脚所属的实例。

**Original**: This function deletes the specified pin(s) from the parent component and symbol definition. As a result, the pin will also be deleted from all instances of these definitions and not just the instance the pin passed in belongs to.

**语法**：
```skill
axlCompDeletePin(
o_pin/lo_pins
)
=> t/nil
```

**参数**：
- `o_pin/lo_pins`：要删除的引脚的 SKILL `dbid`，或要删除的引脚列表。

**返回值**：
- `t`：如果引脚已删除。
- `nil`：如果删除任何引脚时出错，例如，如果引脚具有固定属性。

如果要删除许多引脚，将整个列表传递给此函数以一次性处理它们比使用 `axlCompDeletePin` 处理每个单独引脚效率更高。

**另请参见**：`axlCompAddPin`，`axlCompMovePin`

---

### axlCompMovePin

**说明**：此函数按指定的 delta x/y、旋转和镜像移动指定的引脚。如果提供了旋转和镜像，则围绕 `rotatePoint` 应用（如果未提供，默认为 0,0）。也可以提供应用于每个单独引脚的旋转。

**Original**: This function moves the specified pin(s) by the specified delta x/y, rotation, and mirror. Rotation and mirror, if provided, are applied around the `rotatePoint` (defaults to 0,0 if not provided). A rotation to apply to each individual pin may also be provided.

**语法**：
```skill
axlCompMovePin(
o_pin/lo_pins
?move            l_deltaPoint
?groupMirror     t/nil
?groupRotation   f_angle
?rotOrigin       l_rotatePoint
?pinRotation     f_deltaAngle
)
=> t/nil
```

**参数**：
- `o_pin/lo_pins`：要移动的引脚的 SKILL `dbid`，或要移动的引脚列表。
- `move`：每组引脚要移动的 X/Y delta。
- `groupMirror`：如果为 `t`，则组中每个引脚的位置应围绕提供的 `rotOrigin` 镜像。
- `groupRotation`：应用于组中每个引脚以确定其新最终位置的角度。围绕 `rotOrigin` 应用。
- `rotOrigin`：组镜像和旋转应用的 X/Y 原点。
- `pinRotation`：放置在新位置后应用于单个引脚的旋转。例如，如果要从北侧移动到西侧的引脚，且引脚是矩形的，则可能希望指定 90 度旋转以保持引脚矩形相对于最近芯片边缘的相同方向。

**返回值**：
- `t`：如果引脚已移动。
- `nil`：如果移动任何引脚时出错，例如，如果引脚具有固定属性或将被放置在范围之外。

**注意**：
- 如果要移动许多引脚，将整个列表传递给此函数以一次性处理它们比使用 `axlCompMovePin` 处理每个单独引脚效率更高。
- 对一组引脚同时应用多个变换时，按以下顺序执行操作：
  1. 关于指定的 `rotOrigin` 对组执行组镜像。
  2. 然后应用组旋转，也围绕 `rotOrigin`。
  3. 然后应用移动 delta。

这很重要，以便为所有被移动的引脚实现所需的最终位置，并且使用正确的 `rotOrigin` 点。

**另请参见**：`axlCompAddPin`，`axlCompDeletePin`

---

### axlComponentChangeClass

**说明**：此命令更改元件定义的元件类别。不要更改元件类别为 MECHANICAL、PLATING_BAR 或 DRIVER_CELL 的元件定义的类别。也不能将对象更改为这些类别。要获取元件定义的 `dbid`：
- 对于符号实例，`cd = syminst->component->compdef`
- 符号可能没有元件实例（例如，机械元件）。
- 对于元件实例，`cd = component->compdef`

运行 Cadence 或第三方 ECO 会恢复原始元件类别。

**Original**: This command changes the component class of a component definition. Do not change class for the component definitions with component class as MECHANICAL, PLATING_BAR or DRIVER_CELL. Also you may not change an object to those classes. To get the dbid of a component definition: For symbol instance, cd = syminst->component->compdef. A symbol may not have a component instance (for example, mechanical). For component instance, cd = component->compdef. Running a Cadence or 3rd party ECO restores the original component class.

**语法**：
```skill
axlComponentChangeClass(
s_devType/o_compDef
s_class
)
-> t_oldClass/nil
```

**参数**：
- `s_devType`：器件名称。
- `o_compDef`：元件定义的 `dbid`。
- `s_class`：新元件类别的名称。可能值为 `IC`、`IO` 或 `DISCRETE`。

**返回值**：
- `t_oldClass`：成功时返回旧元件类别。
- `nil`：出错时返回。

**示例**：
```skill
axlComponentChangeClass("DIP14" "DISCRETE")
```

**另请参见**：`axlDBCreateComponent`

---

### axlCompSetPinAttributes

**说明**：此函数在符号和元件定义级别修改指定引脚的属性。例如焊盘、引脚编号和交换代码（参见下面支持的完整属性列表）。如果未设置，所有更新项将保留在引脚的现有值。

**Original**: This function modifies attributes of the specified pin(s) at the symbol and component definition level. Things like the padstack, pin number, and swap code (see below for full list of supported attributes). All update items, if not set, will be left at the pin's existing value.

**语法**：
```skill
axlCompSetPinAttributes(
o_pin/lo_pins
?number     t_pinNumber
?name       t_pinName
?use        t_pinUse
?padstack   t_padstack/g_padstack
?rotation   f_rotation
?swapCode   n_swapCode
)
=> t/nil
```

**参数**：
- `o_pin/lo_pins`：要修改的引脚的 SKILL `dbid`，或要修改的引脚列表。
- `number`：引脚的新引脚编号。建议此参数仅用于单个传入的引脚，因为引脚编号必须唯一。
- `name`：引脚的功能引脚名称。由于实际数据库函数 `pinname` 是功能引脚定义的键，这必须在功能定义中唯一。但是，如果提供了非唯一值，或字符串对功能引脚名称无效（例如包含小写字符），则此处提供的名称将作为引脚的 Verilog_Port_Name 存储，并从该名称派生合法的唯ite PinName 以生成数据库的唯一键。
- `use`：引脚的新引脚用途。如果将引脚用途从电源/地更改为信号引脚，则会创建功能引脚。在相反的情况下——将引脚用途从信号更改为电源/地——功能引脚将被移除。
- `padstack`：用于指定引脚的新焊盘。
- `rotation`：引脚的新旋转（在设计中当前放置的特定符号实例上）。符号定义引脚被更新以补偿最终实例旋转。
- `swapCode`：引脚的新交换代码组索引。

**返回值**：
- `t`：至少修改一个引脚时返回。
- `nil`：修改任何引脚时出错时返回。

**另请参见**：`axlCompAddPin`，`axlCompDeletePin`，`axlCompMovePin`

---

### axlDBGetDesignStats

**说明**：此函数返回包含活动图纸设计统计信息的结构，例如布线完成度等。这些信息大部分也可以通过 UI 中的 `Display - Status` 对话框找到。

**Original**: This function returns a structure containing information about the design statistics of active drawing such as, routing completion, and so on. Most of this information is also found in the UI through the `Display - Status` dialog box.

**语法**：
```skill
axlDBGetDesignStats()
-> structured list/nil
```

**返回值**：
返回结构化信息列表：
- `completeConnections`：完全布线的连接数。
- `incompleteConnections`：需要布线的开放/不完整连接数。
- `totalConnections`：设计中的总连接数（complete + incomplete）。
- `placedComponents`：已放置的元件数量。
- `unplacedComponents`：未放置的元件数量。
- `totalComponents`：设计中的总元件数（placed + unplaced）。
- `nil`：如果出错。

**示例**：
```skill
axlDBGetDesignStats() ->
(totalComponents       355
 placedComponents      355
 unplacedComponents    0
 completeConnections   1926
 incompleteConnections 0
 totalConnections      1926
 noRatNets             0
 signalNets            374
 totalNets             374
)
```

**另请参见**：`axlDesignType`

---

### axlDBIsBondingWireLayer – 已过时

此函数已过时。邦定线层已被芯片堆叠层取代。请使用 `axlDBIsDieStackLayer` 检查层是否为芯片堆叠层。

**Original**: This is an obsolete function. Bonding wire layers have been replaced by die stack layers. Use `axlDBIsDieStackLayer` to check whether a layer is a die stack layer.

---

### axlDBIsDiePad

**说明**：验证给定元素是否为芯片焊盘（die pad）。芯片焊盘是元件类别为 `IC` 的引脚。

**Original**: Verifies whether or not the given element is a `die pad`. A `die pad` is a pin with a component class of `IC`.

**语法**：
```skill
axlDBIsDiePad(
rd_dbid
)
=> t/nil
```

**参数**：
- `rd_dbid`：要检查元素的 `dbid`。

**返回值**：
- `t`：`rd_dbid` 是芯片焊盘。
- `nil`：`rd_dbid` 不是芯片焊盘。

---

### axlDBIsPlatingbarPin

**说明**：验证给定元素是否为电镀条引脚（plating bar pin）。电镀条引脚是元件类别为 `DISCRETE` 或 `PLATING_BAR` 的引脚。

**Original**: Verifies whether or not the given element is a `plating bar pin`. A `plating bar pin` is a pin with a component class of `DISCRETE` or `PLATING_BAR`.

**语法**：
```skill
axlDBIsPlatingbarPin(
rd_dbid
)
=> t/nil
```

**参数**：
- `rd_dbid`：要检查元素的 `dbid`。

**返回值**：
- `t`：`rd_dbid` 是电镀条引脚。
- `nil`：`rd_dbid` 不是电镀条引脚。

---

### axlDieTextIn

**说明**：使用文本文件导入芯片。这是芯片文本导入向导的 SKILL 包装器。仅提供文件名等同于选择包含 BGA 信息的芯片文本文件，然后在芯片文本导入向导的剩余步骤中单击 "Next"。不执行导入后步骤，如清除未使用的网络。

**Original**: Imports a die using a text file. This is a SKILL wrapper for the Die Text-In Wizard. Providing only a filename is equivalent to selecting a die text file containing the BGA information and then clicking Next for the remaining steps in the Die Text-In Wizard. Post-import steps like purging unused nets are not done.

**语法**：
```skill
axlDieTextIn(
t_filename
?delim t_delim
?delimConsec b_consec
?delimTrail b_trail
?header g_header
?unMirrorY b_mirror
?symName t_symname
?refDes t_refdes
?origin g_origin
?extents g_extents
?rotation d_rotation
?layer t_layer
?shrink d_shrink
?scribe g_scribe
)
==> t/ErrorMsg/nil
```

**参数**：
- `t_filename`：指定要导入的文件名。
- `t_delim`：指定最多六个分隔符来分隔数据列。
- `b_consec`：设置忽略连续分隔符。
- `b_trail`：设置忽略尾随分隔符。
- `g_header`：指定要导入的标题名称列表。必须与导入文件中的列数匹配。
- `b_mirror`：设置取消镜像 BGA 的 Y 引脚。
- `t_symname`：指定要使用的符号名称。
- `t_refdes`：指定符号的参考位号。
- `g_origin`：指定符号原点。
- `g_extents`：指定符号范围。
- `d_rotation`：指定符号的旋转。
- `t_layer`：指定焊盘层。
- `d_shrink`：指定芯片的收缩因子，介于 0 和 100 之间。
- `g_scribe`：按 `'(North East South West)` 顺序指定划片尺寸。

**返回值**：
- `t`：芯片导入成功。
- `ERROR` 消息：如果选项无效。
- `nil`：如果导入因无效选项以外的任何原因不成功。

**示例**：
```skill
axlDieTextIn("Die_data.txt")
axlDieTextIn("Die_data.txt" ?delim "\t" ?rotation 20.0 ?refDes "ABC")
axlDieTextIn("Die_data.txt" ?delim "\t" ?delim_consec nil ?delim_trail t
  ?header '("Pin Number", "Padstack", "X Coord", "Y Coord", "Rotation", "Pin Use", "Net Name")
  ?unmirrory nil ?symName "Die_N" ?refDes "Die_S" ?origin '(1000 -2000)
  ?extents '(-10000 -10000 10000 10000)
  ?rotation 20.0 ?layer "TOP" ?shrink 5.0 ?scribe '(500 1000 1500 2000))
```

**另请参见**：`axlBGATextIn`，`axlNetlistTextIn`

---

### axlGetDieType

**说明**：在 Cadence 封装工具（APD+）中返回给定芯片元件的芯片连接类型。芯片在数据库中被视为 IC 类别的元件。目前支持的连接类型包括：
- `WIREBOND`
- `FLIP CHIP`

**Original**: Returns the die attachment type for a given die component in a Cadence packaging tool (APD+). A die is considered to be an IC class component in the database. Currently, the supported attachment types include the following: WIREBOND; FLIP CHIP.

**语法**：
```skill
axlGetDieType(
o_componentDBID
)
==> t_dieType
```

**参数**：
- `o_componentDBID`：要查询的芯片元件的 `dbid` 句柄。

**返回值**：
- `t_dieType`：如果成功。
- `nil`：如果失败（传递了非芯片对象或不是封装产品）。

**示例**：
```skill
axlGetDieType(myComp)
==> "FLIP CHIP"
```

---

### axlGetMetalUsageForLayer

**说明**：计算 `l_layer(s)` 中指定层上（列出的所有层的组合）指定区域 `l_extents` 中的金属覆盖百分比。如果未提供范围，则使用设计的几何轮廓范围。

可以通过传递 `nil` 给 `g_positive` 来计算负片层金属覆盖，如果处理负片层（如阻焊层）。

**Original**: Computes the percentage metal coverage on the layers specified in l_layer(s) (combination of all layers listed) in the area specified in `l_extents`. If no extents are provided, then the geometry outline extents of the design are used. Negative layer metal coverage can be computed by passing nil for g_positive, if processing negative artwork layers such as solder mask layers.

**语法**：
```skill
axlGetMetalUsageForLayer(
l_layers
[l_extents]
[g_positive]
[exclude_pins_vias]
)
==> resultStruct/nil
```

**参数**：
- `l_layers`：单个层或层列表，用于计算（组合的）金属使用率。例如，传递 `list("CONDUCTOR/TOP" "PIN/TOP")` 将计算顶层上所有导体 + 引脚对象的覆盖率。它不会单独计算两个层。
- `l_extents`：计算金属覆盖的 BBox 区域。如果未提供，工具将基于基板几何轮廓的范围计算，如果没有轮廓，则基于数据库范围。
- `g_positive`：正在处理的层是否为正片或负片层。默认为 `true`。
- `exclude_pins_vias`：排除 ETCH 类的引脚和过孔；返回不包括引脚和过孔的铜皮面积。默认值为 `nil`。

**返回值**：
- `resultStruct/nil`：
  - `resultStruct` 是包含四个元素的 `defstruct`：
    - `areaUnits`：计算和返回面积的单位。
    - `regionArea`：工具使用的范围区域的面积（用户提供或图纸范围）。
    - `metalArea`：指示层上检查区域内的总金属面积。
    - `percentMetalCoverage`：范围区域被金属覆盖的百分比。计算为 `((metalArea / regionArea) * 100.0)`
  - `nil`：如果出错，错误打印到命令行。

---

### axlGetWireProfileDefinition

**说明**：给定邦定线轮廓名称，返回其定义信息。

**Original**: Given a bonding wire profile name, this will returns its definition information.

**语法**：
```skill
axlGetWireProfileDefinition(
profileName
)
```

**参数**：
- `profileName`：要查询的轮廓定义名称。如果此参数为 `nil`，则检索设计中所有轮廓的定义。

**返回值**：
- 描述轮廓定义（材料、3D 点列表等）的信息结构。
- 如果失败，返回错误字符串。

---

### axlAddAutoAssignNetAlgorithm

**说明**：此函数允许用户将自定义自动网络分配算法添加到 APD+ 中 Logic -> Auto Assign Net 命令的算法列表中。此列表始终包含 Cadence 标准算法（Router-Based、Nearest Match 和 Constraint-Driven）。这些名称不能重复或被客户覆盖。指定具有重复算法或显示名称的对将导致当前存在的（用户）条目被替换。

**Original**: This function allows the user to add custom auto net assignment algorithms to the list in the Logic -> Auto Assign Net command's algorithms list in APD+. This list will always contain the Cadence standard algorithms (Router-Based, Nearest Match, and Constraint-Driven). These names cannot be duplicate or overwritten by the customer. Specifying a pair with either a duplicate algorithm or display name will cause the currently-existing (user) entry to be replaced.

**语法**：
```skill
axlAddAutoAssignNetAlgorithm(
t_algorithm
t_displayName
)
==> t/nil
```

**参数**：
- `t_algorithm`：文本字符串（区分大小写），包含要为此算法调用的 SKILL 函数名称。该函数必须接受两个参数：第一个参数：源引脚列表。第二个参数：目标引脚列表。该函数应返回 "FAIL"，如果由于某种代码故障而无法完成，否则应返回仍未分配的源引脚列表。
- `t_displayName`：文本字符串（也区分大小写），将用作自动分配网络命令的下拉菜单中此算法的名称，用于选择要使用的算法。

**返回值**：
- `t`：如果算法成功注册。
- `nil`：如果注册失败（函数未定义、名称正在使用等）。

---

### axlGetWireProfileDirection

**说明**：此函数返回数据库中定义的邦定线轮廓定义的方向。轮廓可以是正向或反向。如果提供的轮廓定义名称在设计中不存在，则返回值将为 `nil`。

**Original**: This function returns the direction of a wire profile definition defined in the database. Profiles may be either forward or reverse. If the profile definition name provided does not exist in the design, the return value will be `nil`.

**语法**：
```skill
axlGetWireProfileDirection(
profileName
)
==> "FORWARD"/"REVERSE"/nil
```

**参数**：
- `profileName`：要查询方向的走线轮廓名称。

**返回值**：
- `"FORWARD"`：正向邦定线轮廓定义。
- `"REVERSE"`：反向邦定线轮廓定义。
- `nil`：如果数据库中不存在走线轮廓定义。

---

### axlGetAllVisibleProfiles

**说明**：返回设计中当前可见的所有邦定线轮廓列表。

**Original**: Returns a list of all the bond wire profiles currently visible in the design.

**语法**：
```skill
axlGetAllVisibleProfiles()
==> list of profiles / nil
```

**参数**：无。

**返回值**：
- 轮廓名称列表。
- `nil`：如果出错或没有可见轮廓。

---

### axlSetAllProfilesVisible

**说明**：打开或关闭设计中的所有走线轮廓。

**Original**: Turns all wire profiles in the design on or off.

**语法**：
```skill
axlSetAllProfilesVisible(
visible
)
==> t / nil
```

**参数**：
- `visible`：`t` 打开所有轮廓，`nil` 关闭所有轮廓。

**返回值**：
- `t / nil`：表示成功或失败。

---

### axlGetBondWireLength / axlSetBondWireLength

**说明**：给定邦定线对象，此函数返回邦定线的长度，可以是其 2D 矢量或真实 3D 路径。

**Original**: Given a bonding wire object, this function returns the length of the wire, either as its 2D vector or its true 3D path.

**语法**：
```skill
axlSetBondWireLength(
wire
method
)
==> length/nil
```

**参数**：
- `wire`：邦定线的 `dbid`。
- `method`：长度计算方法。值可以是 `3D` 或 `2D`。

**返回值**：
- `length`：数据库单位中的长度。
- `nil`：如果不是邦定线或方法不是有效值。

---

### axlLoadViaStructure

**说明**：在 `PADPATH` 中搜索过孔结构 XML/EXML 文件并将其加载到数据库中。要删除未使用的 `symdefs`，请使用 `axlDeleteObject`。

**Original**: Searches for via structure XML/EXML files in `PADPATH` and load the symbol into the database. To delete unused symdefs use `axlDeleteObject`.

**语法**：
```skill
axlLoadViaStructure(
t_vsName
t_filePath
)
==> o_vsDbid/nil
```

**参数**：
- `t_vsName`：过孔结构符号名称（小写）。
- `t_filePath`：XML/EXML 文件的完整路径。

**返回值**：
- `dbid`：符号定义的 `dbid`。
- `nil`：找不到文件、文件语法不当、许可证级别不适用、具有所提供名称的符号已存在。

**示例**：
```skill
symdef = axlLoadViaStructure("VS_1" "./vs_1.exml")
```

---

### axlNetlistTextIn

**说明**：使用网络信息的 ASCII 电子表格导入网络表。这是网络表导入向导的 SKILL 包装器。仅提供文件名等同于选择网络信息的 ASCII 电子表格，然后在网络表导入向导的剩余步骤中单击 "Next"。不执行导入后步骤，如清除未使用的网络。

**Original**: Imports a netlist using an ASCII spreadsheet of net information. This is a SKILL wrapper for the Netlist-In Wizard. Providing only a filename is equivalent to selecting an ASCII spreadsheet of net information and then clicking Next for the remaining steps in the Netlist-In Wizard. Post-import steps like purging unused nets are not done.

**语法**：
```skill
axlNetlistTextIn(
t_filename
?delim t_delim
?delimConsec b_consec
?delimTrail b_trail
?header g_header
?emptynet i_emptynet
?shape b_shape
?pins b_pins
)
==> t/ErrorMsg/nil
```

**参数**：
- `t_filename`：指定要导入的文件名。
- `t_delim`：指定最多六个分隔符来分隔数据列。
- `b_consec`：设置忽略连续分隔符。
- `b_trail`：设置忽略尾随分隔符。
- `g_header`：指定要导入的标题名称列表。必须与导入文件中的列数匹配。
- `i_emptynet`：指定如何处理空网络名称。`0` 使用前一个网络，`1` 设置虚拟网络，`2` 显示错误。
- `b_shape`：设置更新连接的铜皮。
- `b_pins`：设置更新电镀引脚。

**返回值**：
- `t`：网络表导入成功。
- `ERROR` 消息：如果选项无效。
- `nil`：如果导入因无效选项以外的任何原因不成功。

**示例**：
```skill
axlNetlistTextIn("Netlist_data.txt")
axlNetlistTextIn("Netlist_data.txt" ?delim "\t" ?emptynet 0)
axlNetlistTextIn("Netlist_data.txt" ?delim "\t" ?delimConsec nil ?delimTrail t
  ?header '("Pin Number", "Net Name", "Ref Des")
  ?emptynet 0 ?shape nil ?pins nil)
```

**另请参见**：`axlBGATextIn`，`axlDieTextIn`

---

### axlSetBondWireProfile

**说明**：此命令允许更改设计中一个或多个邦定线的邦定线轮廓。邦定线轮廓定义必须已存在于设计中。更改走线的轮廓不仅会更改轮廓名称，还会更改走线的材料及其直径或宽度以匹配新的轮廓定义。一次调用中将邦定线轮廓分配给所有应设置为该轮廓的邦定线，比为每个单独的邦定线调用此函数效率更高。

**Original**: This command allows you to change the bond wire profile on one or more bond wires in the design. The bond wire profile definition must already exist in the design. Changing a wire's profile changes not just the profile name, but also the wire's material and its diameter or width to match the new profile definition. It is much more efficient to assign a wire profile to all bond wires, which should be set to that profile, in a single call to this function, than to call the function on each individual bond wire.

**语法**：
```skill
axlSetBondWireProfile(
bondWires
profileName
)
==> t/nil
```

**参数**：
- `bondWires`：一个 `dbid` 或表示要修改的邦定线的 `dbid` 列表。
- `profileName`：要分配给邦定线的新邦定线轮廓名称。

**返回值**：
- `t`：如果已定义轮廓且修改了一个或多个邦定线。
- `nil`：如果发生错误或没有修改邦定线。

---

### axlImportWireProfileDefinitions

**说明**：此函数将导入指定 XML 文件中定义的邦定线轮廓。如果 XML 文件和当前设计中都定义了轮廓，则设计的定义将更新以匹配正在导入的新定义。

**Original**: This function will import the bond wire profiles defined in the xml file specified. If a profile is defined both in the XML file and in the current design, the design's definition will be updated to match the new definition being imported.

**语法**：
```skill
axlImportWireProfileDefinitions(
xmlFileName
setAsMaster
)
==> x/nil
```

**参数**：
- `xmlFileName`：磁盘上包含要读取的邦定线轮廓定义的 XML 文件的名称。如果不在当前工作目录中，则应包含 XML 文件的绝对路径或相对路径。
- `setAsMaster`：如果为 `true`，此 XML 文件将被设置为该数据库的主轮廓定义文件。主文件是用户可以在更改后刷新轮廓定义的文件。只允许一个文件作为主文件。

**返回值**：
- `x`：成功导入的轮廓定义数量。
- `nil`：如果发生错误（消息打印到状态窗口）。

---

### axlSetDieStackData

**说明**：此函数设置指定芯片的给定数据。此命令仅在 APD+ 中可用。

**Original**: This function sets the given data for the specified die. The command is available only in APD+.

**语法**：
```skill
axlSetDieStackData (
g_stackId
s_dataType
g_newValue
)
==> t/nil
```

**参数**：
- `g_stackId`：要获取数据的芯片堆叠的名称或 `dbid`。
- `s_dataType`：给定值的数据类型，以下之一：
  - `'DSA_CAVITY_DEPTH`
  - `'DSA_CAVITY_LAYER`
  - `'DSA_CAVITY_DIMENSION`
- `g_newValue`：指定数据类型的新值。

**返回值**：
- `t`：成功，否则 `nil`。

---

### axlDBIsDieStackLayer

**说明**：验证层是否为芯片堆叠层。这意味着 `paramLayer` 参数 `dbid` 的 `type` 属性值为 `"DIESTACK"`。这通常用于 APD 产品。

**Original**: Verifies if layer is a die stack layer. This means that the attribute of the `paramLayer` parameter `dbid` called `type` has a value of `DIESTACK`. This is normally used in the APD product.

**语法**：
```skill
axlDBIsDieStackLayer (
t_layerName
)
==> t or nil
```

**参数**：
- `t_layerName`：层名称 `"CONDUCTOR/<subclass>"`。CONDUCTOR 在 Allegro PCB Editor 中是 ETCH。

**返回值**：
- `t`：芯片堆叠层。
- `nil`：如果不是。

**另请参见**：`axlDBIsDiePad`

**示例**：
```skill
axlDBIsDieStackLayer("CONDUCTOR/TOP_COND") -> nil
```

---

### axlGetDieData

**说明**：获取给定芯片的数据并将其加载到 `defstruct` 中。仅在 APD+ 中可用。

**Original**: Gets the data for the given die and loads it into the a defstruct. Only available in APD+.

**语法**：
```skill
axlGetDieData (
g_dieId
)
==> die-data defstruct/nil
```

**参数**：
- `g_dieName`：给定芯片的 refdes 或 `dbid`。

**返回值**：
- `dieData`：给定芯片数据的 `defstruct`。
- `nil`：芯片不存在或出错。

**Defstruct 字段**：
| 字段 | 说明 |
|------|------|
| `dbid` | 芯片的 `dbid` |
| `refId` | 芯片 refdes |
| `memberType` | `DSA_DIE` |
| `stackName` | 父芯片堆叠名称 |
| `stackPosition` | 堆叠中成员的位置（整数） |
| `layerName` | 芯片焊盘层 |
| `dieThickness` | 芯片厚度（不包括倒装芯片凸点） |
| `totalThickness` | 芯片厚度（包括倒装芯片凸点） |
| `stackHeightMin` | 堆叠内的起始高度 |
| `stackHeightMax` | 堆叠内的结束高度 |
| `origin` | 芯片符号 x/y 位置 |
| `rotation` | 旋转角度（度） |
| `extents` | 堆叠中所有成员的联合范围 |
| `type` | `DSA_DIE_STANDARD` 或 `DSA_DIE_CODESIGN` |
| `attachType` | `DSA_DIE_FLIPCHIP` 或 `DSA_DIE_WIREBOND` |
| `orientation` | `DSA_DIE_CHIPUP` 或 `DSA_DIE_CHIPDOWN` |
| `bumpDiamAtPkg` | 封装处倒装芯片凸点直径 |
| `bumpDiamAtDie` | 芯片处倒装芯片凸点直径 |
| `bumpDiamMax` | 倒装芯片凸点最大直径 |
| `bumpHeight` | 倒装芯片凸点高度 |
| `bumpEcond` | 倒装芯片电导率（带单位） |

**示例**：
```skill
data = axlGetDieData("FLIPCHIP_1")
printf("stack-pos = %L, layer-name = %L, attach-type = %L\n"
  data->stackPosition  data->layerName data->attachType)
==> stack-pos = 1, layer-name = "TOP_COND", attach-type = DSA_DIE_FLIPCHIP
```

---

### axlGetDieStackData

**说明**：获取给定芯片堆叠的数据并将其加载到 `defstruct` 中。仅在 APD+ 中可用。

**Original**: Gets the data for the given die-stack and loads it into a defstruct. Only available in APD+.

**语法**：
```skill
axlGetDieStackData (
g_stackArg
)
==> stack-data defstruct/nil
```

**参数**：
- `g_stackArg`：给定芯片堆叠的名称或 `dbid`。

**返回值**：
- `stackData`：给定芯片堆叠数据的 `defstruct`。
- `nil`：芯片堆叠不存在或出错。

**Defstruct 字段**：
| 字段 | 说明 |
|------|------|
| `dbid` | 成员的 `dbid` |
| `refId` | 成员名称 |
| `surface` | `DSA_SUBSTRATE_CAVITY_TOP`、`DSA_SUBSTRATE_CAVITY_BOTTOM`、`DSA_SUBSTRATE_TOP`、`DSA_SUBSTRATE_BOTTOM` |
| `depth` | 对于放置在腔体中的芯片，给出堆叠放置在表面以下的层数 |
| `cavityClearance` | 对于放置在腔体中的堆叠，堆叠范围到最低层腔体边缘的间隙 |
| `cavityExpansion` | 对于放置在腔体中的堆叠，腔体在每一后续层上增长的量（"stadium step" 的 "宽度"） |
| `stackHeightMin` | 堆叠内的起始高度 |
| `stackHeightMax` | 堆叠内的结束高度 |
| `rotation` | 旋转角度（度） |
| `extents` | 堆叠中所有成员的联合范围 |

**示例**：
```skill
data = axlGetDieStackData("DIESTACK1")
printf("name = %L, minHeight = %L, maxheight = %L\n"
  data->name data->stackHeightMin data->stackHeightMax)
==> name = "DIESTACK1", minHeight = 0.0, maxheight = 496.0
```

---

### axlGetDieStackMemberSet

**说明**：返回 `defstruct` 列表——给定芯片堆叠的每个成员一个。仅在 APD+ 中可用。

**Original**: Returns a list of defstructs - one for each member of the given die stack. Only available in APD+.

**语法**：
```skill
axlGetDieStackMemberSet(
g_stackArg
)
==> list of die-stack member defstructs/nil
```

**参数**：
- `g_stackArg`：芯片堆叠的名称或 `dbid`。

**返回值**：
- `l_data`：芯片堆叠成员数据 `defstruct` 列表。
- `nil`：如果出错。

**Defstruct 字段**：
| 字段 | 说明 |
|------|------|
| `dbid` | 成员的 `dbid` |
| `refId` | 成员名称 |
| `memberType` | `DSA_DIE`、`DSA_SPACER`、`DSA_INTERPOSER` |
| `stackPosition` | 堆叠中成员的位置（整数） |
| `layerName` | 成员的蚀刻对象子类 |
| `nextMemberOnSameLayer` | 指示下一成员是否在同一层的标志 |
| `prevMemberOnSameLayer` | 指示前一成员是否在同一层的标志 |

**示例**：
```skill
data = axlGetDieStackMemberSet("DIESTACK1")
foreach(member data
  printf("refId = %L, memberType = %L\n" member->refId
    member->memberType)
)
==> refId = "FC1", memberType = DSA_DIE
    refId = "IPOSER_1", memberType = DSA_INTERPOSER
    refId = "WB1", memberType = DSA_DIE
    refId = "SPACER_1", memberType = DSA_SPACER
    refId = "WB2", memberType = DSA_DIE
```

---

### axlGetDieStackNames

**说明**：返回当前设计中所有芯片堆叠的名称列表。仅在 APD+ 中可用。

**Original**: Returns a list of the names of all die stacks in the current design. Only available in APD+.

**语法**：
```skill
axlGetDieStackNames()
==> list of die-stack names/nil
```

**参数**：无。

**返回值**：芯片堆叠名称列表，或如果不存在则为 `nil`。

---

### axlGetIposerData

**说明**：此函数获取给定中介层（iposer）的数据并将其加载到 `defstruct` 中。仅在 APD+ 中可用。

**Original**: This function fetches the data for the given iposer and loads it into a defstruct. Only available in APD+.

**语法**：
```skill
axlGetIposerData(
g_iposerId
)
==> iposer-data defstruct/nil
```

**参数**：
- `g_iposerName`：给定中介层的名称或 `dbid`。

**返回值**：
- `iposerData`：给定中介层数据的 `defstruct`。
- `nil`：中介层不存在或出错。

**Defstruct 字段**：
| 字段 | 说明 |
|------|------|
| `dbid` | 中介层的 `dbid` |
| `refId` | 中介层 ref-id |
| `memberType` | `DSA_INTERPOSER` |
| `stackName` | 父芯片堆叠名称 |
| `stackPosition` | 堆叠中成员的位置（整数） |
| `layerName` | 蚀刻对象层（过孔/蚀刻线/铜皮） |
| `totalThickness` | 介电 + 导体厚度 |
| `stackHeightMin` | 堆叠内的起始高度 |
| `stackHeightMax` | 堆叠内的结束高度 |
| `origin` | 中介层符号 x/y 位置 |
| `rotation` | 旋转角度（度） |
| `extents` | 堆叠中所有成员的联合范围 |
| `dielMatl` | 用于基板的介电材料名称 |
| `dielThickness` | 介电材料厚度 |
| `condMatl` | 用于蚀刻对象的导体材料名称 |
| `condThickness` | 导体材料厚度 |

**示例**：
```skill
data = axlGetDieData("IPOSER_1")
printf("stack-pos = %L, layer-name = %L, thickness = %L\n"
  data->stackPosition  data->layerName data->totalThickness)
==> stack-pos = 4, layer-name = "IP1", thickness = 106.0
```

---

### axlGetSpacerData

**说明**：获取给定垫片（spacer）的数据并将其加载到 `defstruct` 中。仅在 APD+ 中可用。

**Original**: Gets the data for the given spacer and loads it into a defstruct. Only available in APD+.

**语法**：
```skill
axlGetSpacerData(
g_spacerId
)
==> spacer-data defstruct/nil
```

**参数**：
- `g_spacerName`：给定垫片的名称或 `dbid`。

**返回值**：
- `spacerData`：给定垫片数据的 `defstruct`。
- `nil`：垫片不存在或出错。

**Defstruct 字段**：
| 字段 | 说明 |
|------|------|
| `dbid` | 垫片的 `dbid` |
| `refId` | 垫片 ref-id |
| `memberType` | `DSA_INTERPOSER` |
| `stackName` | 父芯片堆叠名称 |
| `stackPosition` | 堆叠中成员的位置（整数） |
| `layerName` | 蚀刻对象层（过孔/蚀刻线/铜皮） |
| `totalThickness` | 介电 + 导体厚度 |
| `stackHeightMin` | 堆叠内的起始高度 |
| `stackHeightMax` | 堆叠内的结束高度 |
| `origin` | 垫片符号 x/y 位置 |
| `rotation` | 旋转角度（度） |
| `extents` | 堆叠中所有成员的联合范围 |
| `dielMatl` | 用于基板的介电材料名称 |
| `dielThickness` | 介电材料厚度 |

**示例**：
```skill
data = axlGetDieData("SPACER_1")
printf("stack-pos = %L, layer-name = %L, diel-matl = %L\n"
  data->stackPosition data->layerName data->dielMatl)
==> stack-pos = 4, layer-name = "SP1", diel-matl = "PHENOLIC"
```

---

### axlGetWireProfileColor

**说明**：此函数将检索与邦定线轮廓关联的颜色索引。如果未找到提供的名称匹配的轮廓，则返回 `nil`。

**Original**: This function will retrieve the color index associated with a bond wire profile. If no profile matching the name supplied is found in the database, nil is returned.

**语法**：
```skill
axlGetWireProfileColor(
t_profile
)
==> color index / nil
```

**参数**：
- `t_profile`：要检索颜色的轮廓名称。

**返回值**：
- 如果找到轮廓，则返回分配给轮廓的颜色编号。
- `nil`：如果发生错误或找不到轮廓。

---

### axlGetWireProfileVisible

**说明**：此函数将检索邦定线轮廓的可见状态。如果未找到提供的名称匹配的轮廓，则返回 `nil`。

**Original**: This function will retrieve the visibility status of a bond wire profile. If no profile matching the name supplied is found in the database, nil is returned.

**语法**：
```skill
axlGetWireProfileVisible(
t_profile
)
==> t / nil
```

**参数**：
- `t_profile`：要检索颜色的轮廓名称。

**返回值**：
- `t`：如果走线轮廓存在且可见。
- `nil`：如果轮廓不可见或不存在。

---

### axlPackageDesignCheckAddCategory

**说明**：此函数将在 APD+ 的 `package integrity` 命令检查树中注册一个新类别。在向其中添加检查之前，必须定义一个类别。因此，此函数应始终在 `axlPackageDesignCheckAddCheck` 之前调用。新添加的类别将按字母顺序插入树中。因此，您无需自己管理类别添加的顺序。如果类别名称已存在，则不会重新定义。

**Original**: This function will register a new category inside the `package integrity` command check tree of APD+. You must define a category before adding checks to it. So, this function should always be called prior to `axlPackageDesignCheckAddCheck`. A newly added category will be inserted into the tree in alphabetically sorted order. Therefore, you do not need to manage the order categories are added by yourself. If the category name already exists, it will not be redefined.

**语法**：
```skill
axlPackageDesignCheckAddCategory(
t_name
t_bitmap
t_description
)
==> g_category / nil
```

**参数**：
- `t_name`：检查类别在用户界面中应显示的类别名称。此名称应在调用 `axlPackageDesignCheckAddCheck` 添加特定检查时使用。
- `t_bitmap`：当此类别在用户界面中激活时应显示的位图文件名。这应该是位图的完整路径，否则位图必须通过 `BMPPATH` 解析。
- `t_description`：当此类别在用户界面中高亮时显示的描述。

**返回值**：
- `g_category`：定义类别的 SKILL `defstruct`。

**另请参见**：`axlPackageDesignCheckAddCheck`

**示例**：
```skill
;; 以下示例为后续添加用户定义规则添加一个新的完整性检查类别：
axlPackageDesignCheckAddCategory(
  "User-Defined Rules" "user_defined.bmp" "Descriptive Text"
)
==> g_category
;; 下次运行 Package Integrity Check 工具时，将显示一个名为 "User-Defined Rules" 的新类别。
```

---

### axlPackageDesignCheckAddCheck

**说明**：此函数将在 APD+ 的 `package integrity` 命令检查树的指定类别中注册一个新检查。在向其中添加检查之前，必须定义一个类别。因此，此函数应始终在 `axlPackageDesignCheckAddCategory` 之后调用。新添加的检查将按字母顺序插入树中。因此，您无需自己管理检查添加的顺序。

`s_runCommand` 是如果选择运行此检查应调用的 SKILL 函数。此函数必须遵循以下准则：
- 它必须接受一个参数，即是否修复它遇到的错误。
- 它必须返回一个整数值，表示在数据库中发现的错误数量。
- 它必须调用以下函数：`axlPackageDesignCheckLogError(<error string> <fixed>)` 和 `axlPackageDesignCheckDrcError(<error location> <dbids>)` 来报告它发现的任何错误。

这些限制是为了确保所有由此命令运行的检查的输出一致。

**Original**: This function will register a new check in the specified category of the `package integrity` command check tree of APD+. You must define a category before adding checks to it. So, this function should always be called after `axlPackageDesignCheckAddCategory`. A newly added check will be inserted into the tree in alphabetically sorted order. Therefore, you do not need to manage the order checks are added by yourself. s_runCommand is the SKILL function which should be called if this check is selected to run. This function MUST adhere to the following guidelines: It must take exactly one argument, which is whether to fix errors it encounters or not. It must return an integer value for how many errors were found in the database. It must call the following functions: `axlPackageDesignCheckLogError(<error string> <fixed>)` and `axlPackageDesignCheckDrcError(<error location> <dbids>)` to report any errors it finds. These restrictions are imposed to ensure that output is consistent across all checks run by this command.

**语法**：
```skill
axlPackageDesignCheckAddCheck(
t_category t_name t_bitmap t_description
s_runCommand g_fixable
)
==> defstruct defining check.
```

**参数**：
- `t_category`：此检查应在用户界面树中放置的类别名称。这应该与发送到 `axlPackageDesignCheckAddCategory` 的名称相同。
- `t_name`：检查在用户界面中应显示的名称。这将是结果日志文件中给定的名称，也是创建的任何外部 DRC 的描述。
- `t_bitmap`：当此检查在用户界面中激活时应显示的位图文件名。这应该是位图的完整路径，否则位图必须通过 `BMPPATH` 解析。
- `t_description`：当此检查在用户界面中高亮时显示的描述。此描述也会在任何违规之前打印到日志文件中。因此，描述应尽可能描述性，以最大化其有用性。
- `s_runCommand`：表示要调用以检查此规则的函数的符号。有关此函数的所需格式和返回值的详细信息，请参见 FUNCTION 描述。
- `g_fixable`：布尔标志，告诉用户界面此检查发现的问题是否可以自动修复。

**返回值**：
- `g_check`：定义检查的 SKILL `defstruct`。

**示例**：
```skill
;; 以下示例在 Package Integrity Check 用户界面的 "User-Defined Rules" 类别中添加一个新的完整性检查。
axlPackageDesignCheckAddCheck(
  "User-Defined Rules" "My First Rule" "user_defined.bmp"
  "Descriptive Text" 'myCheckFunction t)
)
==> g_check
;; 下次运行 Package Integrity Check 工具时，"My First Rule" 将在 "User-Defined Rules" 类别下可用。
```

**另请参见**：`axlPackageDesignCheckAddCategory`，`axlPackageDesignCheckLogError`，`axlPackageDesignCheckDrcError`

---

### axlPackageDesignCheckDrcError

**说明**：此函数将为当前运行的封装完整性检查发现的错误创建外部 DRC 标记。工具本身将跟踪正在运行的检查，以便知道用于规则违规的名称。

**Original**: This function will create an external DRC marker for an error found by the currently running package integrity check. The tool itself will track the check being run so that it knows the name to use for the rule violation.

**语法**：
```skill
axlPackageDesignCheckDrcError(
l_location
o_dbids
)
==> nil
```

**参数**：
- `l_location`：放置 DRC 标记的位置。
- `o_dbids`：可选的数据库对象 ID 列表，与此错误关联。通常 0-2 个对象受影响。

**返回值**：`nil`。

**示例**：
```skill
;; 以下示例创建一个关于虚构规则发现的缺失过孔的 DRC 标记。在这种情况下，由于过孔缺失，没有传递对象 dbid：
axlPackageDesignCheckDrcError((0.0 0.0) nil)
==> nil
;; 在画布中，在 (0.0 0.0) 处创建了一个外部 DRC 标记，名称为生成错误的用户定义规则。
```

**另请参见**：`axlPackageDesignCheckAddCheck`，`axlPackageDesignCheckLogError`

---

### axlPackageDesignCheckLogError

**说明**：此函数将记录此函数发现的错误（如果日志文件已启用）。通过使用此接口，您确保 API 将以一致的格式格式化您的消息。

**Original**: This function will log an error found by this function to the log file if the log file is enabled. By using this interface, you are ensuring that the API will format your message consistently.

**语法**：
```skill
axlPackageDesignCheckLogError(
t_errorString
g_fixed
g_location
)
==> nil
```

**参数**：
- `t_errorString`：要打印到日志文件的字符串。这应该已完成所有变量替换，并且是一个简单的字符串。此函数将处理任何必要的格式化。
- `g_fixed`：布尔值，指示工具是否修复了错误。
- `g_location`：错误发生的位置（如果适用）。这会为您附加到日志条目，并用于让用户缩放到设计中的错误位置。如果位置未知或不适用，请传递 `nil`。

**返回值**：`nil`。

**示例**：
```skill
;; 以下示例记录一个虚构规则发现的缺失过孔的错误。错误未被调用者修复：
axlPackageDesignCheckLogError("Missing via" nil (0.0 0.0))
==> nil
;; 在日志文件中，以下内容打印在用户定义规则发现它的标题下：
;; "- Missing via at (0.0 0.0)"
```

**另请参见**：`axlPackageDesignCheckAddCheck`，`axlPackageDesignCheckDrcError`

---

### axlSetDieData

**说明**：设置给定芯片的给定数据。仅在 APD+ 中可用。

**Original**: Sets the given data for the given die. Only available in APD+.

**语法**：
```skill
axlSetDieData(
g_dieId
s_dataType
g_newValue
)
==> t/nil
```

**参数**：
- `g_dieName`：要获取数据的芯片的名称或 `dbid`。
- `s_dataType`：给定值的数据类型，以下之一：
  - `DSA_BUMP_PACKAGE_DIAM_DBREP`
  - `DSA_BUMP_PACKAGE_DIAM_STRING`
  - `DSA_BUMP_DIE_DIAM_DBREP`
  - `DSA_BUMP_DIE_DIAM_STRING`
  - `DSA_BUMP_MAX_DIAM_DBREP`
  - `DSA_BUMP_MAX_DIAM_STRING`
  - `DSA_BUMP_HEIGHT_DBREP`
  - `DSA_BUMP_HEIGHT_STRING`
  - `DSA_BUMP_ECOND_STRING`
  - `DSA_DIE_THICKNESS_DBREP`
  - `DSA_DIE_THICKNESS_STRING`
  - `DSA_LAYER`
- `g_newValue`：指定数据类型的新值。

**返回值**：
- `t`：成功，否则 `nil`。

---

### axlSetDieType

**说明**：此函数将芯片元件的连接类型设置为可用类型之一。目前支持的连接类型为：
- `WIREBOND`
- `FLIP CHIP`

**Original**: This function sets the attachment type for a die component to one of the available types. Currently, the supported attachment types are: WIREBOND; FLIP CHIP.

**语法**：
```skill
axlSetDieType(
o_componentDBID
t_dieType
)
==> t/nil
```

**参数**：
- `o_componentDBID`：要配置的芯片元件的 `dbid` 句柄。
- `t_dieType`：要配置此元件的连接类型。支持值为 `"WIREBOND"` 和 `"FLIP CHIP"`。

**返回值**：
- `t`：如果成功。
- `nil`：如果失败（传递了非芯片对象或不是封装产品）。

**示例**：
```skill
axlSetDieType(myComp "WIREBOND")
==> t
```

---

### axlSetIposerData

**说明**：设置给定中介层的给定数据。仅在 APD+ 中可用。

**Original**: Sets the given data for the given iposer. Only available in APD+.

**语法**：
```skill
axlSetIposerData(
g_iposerId
s_dataType
g_newValue
)
==> t/nil
```

**参数**：
- `g_iposerName`：给定中介层的名称或 `dbid`。
- `s_dataType`：给定值的数据类型，以下之一：
  - `DSA_CONDUCTOR_MATERIAL`
  - `DSA_CONDUCTOR_THICKNESS_DBREP`
  - `DSA_CONDUCTOR_THICKNESS_STRING`
  - `DSA_DIELECTRIC_MATERIAL`
  - `DSA_DIELECTRIC_THICKNESS_DBREP`
  - `DSA_DIELECTRIC_THICKNESS_STRING`
  - `DSA_PART_NUMBER`
- `g_newValue`：指定数据类型的新值。

**返回值**：
- `t`：成功，否则 `nil`。

---

### axlSetSpacerData

**说明**：设置给定垫片的给定数据。仅在 APD+ 中可用。

**Original**: This function sets the given data for the given spacer. Only available in APD+.

**语法**：
```skill
axlSetSpacerData(
g_spacerId
s_dataType
g_newValue
)
==> t/nil
```

**参数**：
- `g_spacerName`：要获取数据的垫片的名称或 `dbid`。
- `s_dataType`：给定值的数据类型，以下之一：
  - `DSA_DIELECTRIC_MATERIAL`
  - `DSA_DIELECTRIC_THICKNESS_DBREP`
  - `DSA_DIELECTRIC_THICKNESS_STRING`
  - `DSA_PART_NUMBER`
- `g_newValue`：指定数据类型的新值。

**返回值**：
- `t`：成功，否则 `nil`。

---

### axlSetWireProfileColor

**说明**：此函数将走线轮廓的颜色设置为给定值。

**Original**: This function will set the color of a wire profile to the given value.

**语法**：
```skill
axlSetWireProfileColor(
t_profile
n_color
)
==> t / nil
```

**参数**：
- `t_profile`：要检索颜色的轮廓名称。
- `n_color`：要分配给轮廓的颜色索引。

**返回值**：
- `t`：如果成功。
- `nil`：如果错误（轮廓不存在）。

---

### axlSetWireProfileVisible

**说明**：此函数将使标识的走线轮廓可见或不可见。

**Original**: This function will make the identified wire profile visible or invisible.

**语法**：
```skill
axlSetWireProfileVisible(
t_profile
g_visible
)
==> t / nil
```

**参数**：
- `t_profile`：要检索颜色的轮廓名称。
- `g_visible`：`t` 表示可见，`nil` 表示不可见。

**返回值**：
- `t`：如果成功。
- `nil`：如果错误（轮廓不存在）。

---

### axlCDLNetlistSetValue

**说明**：配置 `cdl out` 命令的 CDL Netlist Out 命令中的值，用于导出 CDL（电路描述语言）。使用此函数自动化 CDL Netlist Out 表单，通常还通过 `axlTriggerSet()` 命令为 `'open` 事件注册触发器。使用此函数和触发器，可以根据您的要求、活动设计的内容等预先配置 CDL Netlist Out 表单。

**Original**: Configures a value in the CDL Netlist Out command of the `cdl out` command used to export CDL (Circuit Description Language). Use this function to automate the CDL Netlist Out form usually by also registering a trigger with the `axlTriggerSet()` command for the 'open event. Using this function along with the trigger, you can pre-configure the CDL Netlist Out form based on your requirements, the contents of the active design, and so on.

**语法**：
```skill
axlCDLNetlistSetValue(
s_field
[g_value]
[b_locked]
[t_padStack]
)
=> nil
```

**参数**：
- `s_field`：要配置的字段名称。如果为 `nil`，返回支持的所有字段列表。
- `g_value`：要在字段中设置的值。该值应与指定字段中存储的值类型匹配。例如，对于电阻，这是数值。对于电阻复选框列，这是布尔值。
- `b_locked`：如果传递，布尔值指示字段值是否可以修改。如果为 `true`，则字段被锁定，无法进行任何交互编辑。
- `t_padStack`：如果配置表单中的表行，用于修改焊盘条目。`nil` 设置 `All` 行。

**返回值**：
- `t`：如果成功，配置值时。
- `nil`：如果为 `s_field` 传递 `nil`，返回可以设置的字段列表。

**示例**：
```skill
;; 设置要写入的 CDL 网络表文件名，并防止用户修改它：
;; 文件名应与当前数据库名称匹配，扩展名为 cdl。
fileName = strcat(axlCurrentDesign() ".cdl")
;; 防止用户交互编辑自动化设置的值。
axlCDLNetlist('outputFileName fileName t)
```
