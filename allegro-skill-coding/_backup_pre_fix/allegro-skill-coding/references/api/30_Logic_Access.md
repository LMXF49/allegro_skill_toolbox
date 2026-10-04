# 30. 逻辑访问 (Logic Access)

**Product Documentation**: Allegro SKILL Reference  
**Product Version**: 17.4-2019, October 2019  

---

## 30.1 逻辑访问函数概述 (Logic Access Functions Overview)

**说明**：本章描述与原理图捕获或设计的逻辑定义相关的AXL-SKILL函数。

**Original**: This chapter describes the AXL-SKILL functions related to schematic capture or the logical definition of the design.

---

## 30.2 逻辑访问函数 (Logic Access Functions)

---

### axlDBAssignNet

**说明**：将对象或对象列表分配给新网络。支持引脚、过孔和形状。如果过孔未连接到新网络上的对象，则过孔可能不会保留在分配的网络中。如果新网络具有RETAIN_NET_ON_VIAS属性，则不适用。

**Original**: Assigns an object or a list of objects to a new net. Supports pins, vias, and shapes. Vias may not stay on net assigned if they do not connect to an object on the new net. This is not applicable if the new net has RETAIN_NET_ON_VIAS property.

**语法**：
```skill
axlDBAssignNet(o_object/lo_object o_net/t_net [g_ripup] [g_ignoreFixed])
```

**参数**：
- `o_object`：要更改网络的对象的dbid或dbid列表。
- `o_net`：目标网络的dbid，或`nil`如果分配到虚拟网络。
- `t_net`：网络名称可作为网络dbid的替代。
- `g_ripup`：可选标志，用于撕裂连接到修改对象的布线和过孔。可能值：`t` = 撕裂连接到修改对象的布线；`nil` = 不撕裂连接到修改对象的布线。默认是`nil`。
- `g_ignoreFixed`：默认情况下，如果对象上存在FIXED属性，则不允许网络分配。将此参数设置为`t`忽略FIXED属性。如果`g_ripup`为`t`，且连接的布线具有FIXED属性，则布线将保留并抛出错误消息。

**返回值**：
- `t`：至少一个对象更改了网络。
- `nil`：没有对象更改网络。

**相关函数**：`axlDBCreateNet`, `axlDBIgnoreFixed`

**示例**：
```skill
;; 简单重新分配
pin_id->net->name => ""
net_id->name => "GND"
axlDBAssignNet(pin_id net_id t) => t
pin_id->net->name => "GND"

;; 交互式探索；使用cdsroot示例区域中提供的ashOne共享软件
item = ashOne()
net = "net1"
axlDBAssignNet(item net t t)
```

---

### axlDBCreateConceptComponent

**说明**：给定描述Allegro PCB Editor设备所需的Concept信息，创建Allegro PCB Editor元件并返回其dbid。如果元件定义已存在，则使用现有定义创建新元件。如果元件定义不存在，则创建新定义，然后创建元件实例。Concept信息来自`chips_prt`文件和物理部件表（PPT）。使用`cptList`XXX函数族确定此信息的位置，这些函数允许浏览Concept库。

**Original**: Given the Concept information needed to describe an Allegro PCB Editor device, create the Allegro PCB Editor component and return its dbid. If the component definition already exists, use the existing definition to create the new component. If the component definition does not exist, create a new definition and then create the component instance. Concept information comes from a chips_prt file and from a physical parts table (PPT). Determine the location of this information using the cptList family of routines.

**语法**：
```skill
axlDBCreateConceptComponent(s_refdes s_partPath s_logName s_primName [s_pptRowName])
```

**参数**：
- `s_refDes`：新元件的参考位号。
- `s_partPath`：包含所需逻辑部件描述的`chips_ptr`文件的完整路径。使用`cptListComponentLibraries`函数确定。
- `s_logName`：所需逻辑部件的名称。您可以使用`cptListComponentPrimitives`函数确定。
- `s_primName`：所需基元的名称。您可以使用`cptListComponentPrimitives`函数确定。
- `s_pptRowName`：所需PPT部件的名称。Concept数据可能不包含PPT中包含的特定设备信息。指示PPT中的特定行，从中创建设备。您可以使用`cptListComponentDevices()`函数确定。

**返回值**：
- `r_dbid`：新Allegro PCB Editor元件实例的dbid。
- `nil`：无法创建元件实例。

**注意**：Allegro PCB Editor设备的实际名称是自动生成的。如果使用`cptListComponentDevices()`函数，则名称应该已经创建，并包含在该函数的返回值中。名称由用于创建部件的Concept库数据确定。此函数旨在从SKILL调用。

---

### axlDBCreateComponent

**说明**：给定描述Allegro PCB Editor设备所需的信息，创建Allegro PCB Editor元件并返回其dbid。如果元件定义已存在，则使用现有定义创建新元件。如果元件定义不存在，则使用设备文件创建新定义，然后创建新元件。

**Original**: Given the information needed to describe a Allegro PCB Editor device, create the Allegro PCB Editor component and return its dbid. If the component definition already exists, use the existing definition to create the new component. If the component definition does not exist, create a new definition using the device file and create the new component.

**语法**：
```skill
axlDBCreateComponent(s_refDes s_deviceName [s_package] [s_value] [s_tolerance])
```

**参数**：
- `s_refDes`：新元件的参考位号。
- `s_deviceName`：Allegro PCB Editor设备文件名。
- `s_package`：用于元件的封装名称。这将覆盖设备文件中找到的值（可以为nil）。
- `s_value`："Value"属性值。这将覆盖设备文件中找到的值（可以为nil）。
- `s_tolerance`："Tolerance"属性值。这将覆盖设备文件中找到的值（可以为nil）。

**返回值**：
- `r_dbid`：新Allegro PCB Editor元件的dbid。
- `nil`：如果无法创建元件。

**注意**：如果通过指定新的封装、值或容差值来更改现有元件定义，则需要一个设备文件。

**示例**：
```skill
;; 从现有元件创建新的空元件，ashOne可以在以下位置找到：
;; <cdsroot>/share/pcb/examples/skill/examples/ash-fxf/ashone.il
syminst = ashOne()
ci = syminst->component
nci = axlDBCreateComponent("C1_NEW" ci->deviceType ci->package
  ci->compdef->prop->VALUE ci->compdef->prop->TOL)
```
如果您的元件不是分立元件，则不需要第四和第五个参数，但上述示例适用于所有元件。

**相关函数**：`axlComponentChangeClass`

---

### axlDBCreateManyModuleInstances

**说明**：在设计中创建多个模块实例。通过减少打开模块定义文件的次数，在创建同一模块的多个实例时优化性能。

**Original**: Creates multiple module instances in the design. By reducing the number of times the module definition file opens, this function optimizes performance when creating several instances of the same module.

**语法**：
```skill
axlDBCreateManyModuleInstances(t_name t_moddefName x_tileStartNum l_origin l_offset x_num_tiles f_rotation x_logicMethod [l_netExcept] [g_mirror])
```

**参数**：
- `t_name`：模块实例名称的前缀。
- `t_moddefName`：模块定义的名称。
- `x_tileStartNum`：瓦片编号起始编号，每个瓦片递增1。
- `l_origin`：第一个模块的第一个位置。
- `l_offset`：包含模块原点之间所需偏移的列表。
- `x_numTiles`：要放置的模块实例数。
- `f_rotation`：模块实例的旋转角度。
- `x_logicMethod`：指示模块逻辑来源的标志：
  - `0`：无逻辑
  - `1`：来自原理图的逻辑
  - `2`：来自模块定义的逻辑
- `l_netExcept`：要添加到网络例外列表的网络名称的可选列表。
- `g_mirror`：可选，模块是否应镜像

**返回值**：
- `lo_result`：如果成功，返回属于创建的模块实例的数据库对象列表。
- `nil`：模块实例的创建无法完成。

**相关函数**：`axlDBCreateModuleDef`, `axlDBCreateModuleInstance`

**示例**：
```skill
;; 基于模块定义文件mod.mdd，添加五个模块实例，从点(10,10)开始，每次偏移(5,0)：
modinsts = axlDBCreateManyModuleInstances(
  "Num" "mod" 2 10:10 '(5 0) 5 0 2 '("GND" "+5"))
```
创建五个名为Num2、Num3、Num4、Num5、Num6的模块实例。

---

### axlDBCreateModuleDef

**说明**：基于现有数据库对象创建模块。

**Original**: Creates a module based on existing database objects.

**语法**：
```skill
axlDBCreateModuleDef(t_name l_origin l_objects)
```

**参数**：
- `t_name`：提供模块定义名称的字符串。文件名是模块定义名称附加`.mdd`。
- `l_origin`：用作模块定义原点的坐标。
- `l_objects`：要添加到模块的对象列表。

**返回值**：
- `t`：模块定义已成功创建。
- `nil`：未创建模块定义。

**示例**：
```skill
axlSetFindFilter(?enabled '("noall" "components") ?onButtons '("noall" "components"))
axlSingleSelectName("COMPONENT" "U1")
comp1 = car(axlGetSelSet())
axlSingleSelectName("COMPONENT" "U2")
comp2 = car(axlGetSelSet())
axlDBCreateModuleDef("comps" '(0 0) '(comp1 comp2))
⇒ A module definition file named comps.mdd is created.
```

---

### axlDBCreateModuleInstance

**说明**：允许您使用或放置先前定义的模块。

**Original**: Allows you to use or place a previously defined module.

**语法**：
```skill
axlDBCreateModuleInstance(t_name t_moddef_name l_origin r_rotation i_logic_method l_net_except)
```

**参数**：
- `t_name`：提供模块实例名称的字符串。
- `t_moddef_name`：提供模块定义名称的字符串，实例基于此定义。
- `l_origin`：放置模块定义原点的坐标位置。
- `r_rotation`：模块实例的旋转角度。
- `i_logic_method`：指示模块逻辑来源的标志：
  - `0` - 无逻辑
  - `1` - 来自原理图的逻辑
  - `2` - 来自模块定义的逻辑。
- `l_net_except`：要添加到网络例外列表的网络名称的可选列表。

**返回值**：
- `o_result`：表示模块实例的组的数据库对象。
- `nil`：模块实例未创建。

**示例**：
```skill
modinst = axlDBCreateModuleInstance("inst" "mod" '(500 1500) 2 '("GND" "+5"))
```
添加基于模块定义文件`mod.mdd`的模块实例。

---

### axlDBCreateNet

**说明**：如果数据库中不存在，则创建网络，或如果存在则返回网络的dbid。

**Original**: Creates a net in database if does not exist or returns dbid of net if it exists.

**语法**：
```skill
axlDBCreateNet(t_netName)
```

**参数**：
- `t_netName`：要创建或查找的网络名称。

**返回值**：
- `nil`：如果未创建，或网络axl dbid

**相关函数**：`axlDBAssignNet`

**示例**：
```skill
net = axlDBNetCreate("gnd")
=> dbid:123456
net->name
=> "GND"
```

---

### axlDBCreateSymDefSkeleton

**说明**：创建一个"最小"的符号定义。虽然必须提供符号名称和类型，但实例仅使用引脚创建。一旦创建了这个"骨架"定义，就可以使用额外的`axlDBCreate`调用添加符号的其余几何形状。这提供了创建库中不存在的符号的能力。

形状符号：
- 只能将单个形状附加到形状符号，无空洞。
- 所需层为"ETCH/TOP"。
- 扩展应大于形状，但大幅扩展也没有不利影响。

焊盘符号：
- 可以附加多个形状，但都不能包含空洞。
- 所需层为"ETCH/TOP"。
- 扩展应大于形状，但大幅扩展也没有不利影响。

**Original**: Creates a "minimal" symbol definition. While the symbol name and type must be provided, the instance is created only with pins. Once this "skeleton" definition has been created, you add the rest of the symbol geometry with additional axlDBCreate calls. This provides the ability to create symbols that do not exist in the library.

**语法**：
```skill
axlDBCreateSymDefSkeleton(l_symbolData l_extents [l_pinData])
```

**参数**：
- `l_symbolData`：`(t_symbolName [t_symbolType])`的列表。
  - `t_symbolName`：符号名称。
  - `t_symbolType`：Package（默认）、mechanical或format。
- `l_extents`：符号定义扩展的左下角和右上角。
- `l_pinData`：引脚的`axlPinData` defstructs列表。

**返回值**：
- `axlDBCreateSymDefSkeleton`：如果未创建则返回`nil`，或返回符号定义的`axlDBID`。

**示例**：
```skill
;; 创建形状符号：
symdef = axlDBCreateSymDefSkeleton('("shape_pad" "shape") list(-100:-100 100:100))
p = axlPathStart( list(-4:10 4:10 8:0 4:-10 -4:-10 -4:10))
s = axlDBCreateShape(p t "ETCH/TOP" nil symdef)
;; 创建焊盘符号：
symdef = axlDBCreateSymDefSkeleton('("flash_pad" "flash") list(-100:-100 100:100))
p = axlPathStart( list(-4:10 4:10 8:0 4:-10 -4:-10 -4:10))
ps = axlPathStart( list(-4:10 4:10 4:-10 -4:-10 -4:10))
s = axlDBCreateShape(p t "ETCH/TOP" nil symdef)
s = axlDBCreateShape(ps t "ETCH/TOP" nil symdef)
```

---

### axlDBDummyNet

**说明**：此命令返回设计中的所有虚拟网络。提供两个礼貌选项：
- `'pin`：对于任何具有引脚的虚拟网络，返回虚拟网络的第一个引脚
- `'shape`：对于任何具有形状的虚拟网络，返回虚拟网络的第一个形状

通常，设计中的每个虚拟网络只有一个引脚或形状，但情况可能并非总是如此。虚拟网络本身不能仅由布线和过孔存在。符号（dra）没有虚拟网络。

**Original**: This command returns all dummy nets in design. Two courtesy options provided are: 'pin for any dummy net that has a pin return the first pin of the dummy net; 'shape for any dummy net that has a shape return the first shape of the dummy net. Typically each dummy net in design will only have a single pin or shape but this may not always be the case. Clines or vias cannot, by themselves exist on a dummy. Symbols (dra) do not have dummy nets.

**语法**：
```skill
axlDBDummyNet(g_mode)
```

**参数**：
- `g_mode`：可以具有以下两个值：
  - `'pin`：返回虚拟网络上第一个引脚的列表
  - `'shape`：返回虚拟网络上第一个形状的列表

**返回值**：
- `t`：表示成功
- `nil`：由于参数不正确而失败

**相关函数**：`axlIsDummyNet`, `axlDbidName`

**示例**：
```skill
;; 打印所有虚拟网络上的第一个引脚
foreach(mapc x axlDBDummyNet('pin) printf("%s\n" axlDbidName(x)))
;; 获取设计上的所有虚拟网络
p = axlDBDummyNet(nil)
```

---

### axlDbidName

**说明**：提供数据库对象的标准Allegro PCB Editor名称。许多命名的Allegro PCB Editor对象（例如，网络）在名称属性中定义了名称（例如，`dbid->name`），但其他对象（例如，布线和引脚）要么没有所需的报告名称，要么未命名。

**Original**: Provides the standard Allegro PCB Editor name of a database object. Many of the named Allegro PCB Editor objects (for example, nets) have names defined in the name attribute (for example, dbid->name) but other objects (for example, clines and pins) either do not have the desired reporting name or are unnamed.

**语法**：
```skill
axlDbidName(o_dbid)
```

**参数**：
- `o_dbid`：Allegro PCB Editor数据库id。某些Allegro PCB Editor数据库id是伪id（例如，`axlDBGetDesign`和焊盘），并生成`nil`返回。

**返回值**：
- 对象的Allegro PCB Editor名称，或如果不是dbid或真正的Allegro PCB Editor数据库对象则返回`nil`。

**示例**：
```skill
;; 使用在以下位置找到的ashOne选择函数：
;; <cdsroot>/share/pcb/examples/skill/examples/ash-fxf/ashone.il
;; 引脚名称：
pin = ashOne()
axlDbidName(pin)
-> "U1.1"
;; 布线名称：
cline = ashOne()
axlDbidName(cline)
-> "Net3, Etch/Top"
```

---

### axlDiffPair

**说明**：创建、修改或删除差分对。在所有情况下，您可以传递名称或dbid。

如果差分对是由于Signoise模型创建的，则不能修改或删除它。因此，如果以下情况为真，则不能修改或删除差分对：`diffpair_dbid->prop->DIFFP_ELECTRICAL == t`。

如果两个网络属于同一XNet，则不能创建差分对。

**Original**: Creates, modifies, or deletes a differential pair. In all cases you can pass names or a dbid. If the differential pair was created due to Signoise models, you cannot modify or delete it. You cannot create a differential pair if two nets belong to the same XNet.

**语法**：
```skill
;; 添加差分对
axlDiffPair(t_diffpair o_net1/t_net1 o_net2/t_net2) ⇒ o_diffpair/nil
;; 修改差分对
axlDiffPair(o_diffpair/t_diffpair o_net1/t_net1 o_net2/t_net2) ⇒ o_diffpair/nil
;; 删除差分对
axlDiffPair(o_diffpair/t_diffpair/lo_diffpair) ⇒ t/nil
```

**参数**：
- `o_diffpair`：差分对dbid
- `lo_diffpair`：差分对dbid列表（仅删除模式）
- `t_diffpair`：差分对名称（字符串）
- `o_net1/o_net2`：网络dbid
- `t_net1/t_net2`：网络名称（字符串）
- `g_mode`：添加测试点到顶部或底部或清除一个

**返回值**：
- 返回值取决于添加、修改或删除：
  - `o_diffpair`：新或修改的差分对的dbid
  - `t`：删除成功
  - `nil`：参数不正确导致错误。

**示例**：
```skill
dbid = axlDiffPair("DP" "NET1+" "NET2-")        ;; 创建差分对并命名为DP1
dbid = axlDiffPair(dbid "NET1+" "NET1-")        ;; 修改差分对
axlDiffPair(dbid)                                ;; 删除差分对
axlDiffPair(axlDBGetDesign()->diffpair)          ;; 删除设计中的所有差分对
```

---

### axlDiffPairAuto

**说明**：允许自动生成差分对。基于提供的正（`t_posNetSuffix`）和负（`t_negNetSuffix`）后缀生成差分对集，这些后缀用于您的网络命名方案。

您可以可选地提供前缀（`t_diffPairPrefix`），用于生成差分对名称，格式为：`<t_diffPairPrefix>` + `netname` - `suffix`。

如果网络是总线的一部分并以位字段语法（`<1>`）结尾，则在执行后缀匹配时忽略位字段部分。如果创建差分对，则将位号添加到用于形成差分对的基本网络名称。例如，给定两个网络`DATA_P<1>`和`DATA_N<1>`，将产生名为`DP_DATA1`的差分对，调用如下：
`axlDiffPairAuto("DP_" "_P" "_N")`

**Original**: Allows automatic generation of the differential pair. Generates the set of differential pairs based on the provided positive (t_posNetSuffix) and negative (t_negNetSuffix) suffixes used in your net naming scheme.

**语法**：
```skill
axlDiffPairAuto(t_diffPairPrefix t_posNetSuffix t_negNetSuffix [g_returnDiffPairList])
```

**参数**：
- `t_diffPairPrefix`：差分对名称前缀字符串。如果不需要前缀，请使用""
- `t_posNetSuffix`：用于识别+差分对成员的后缀。
- `t_negNetSuffix`：用于识别-差分对成员的后缀。
- `g_returnDiffPairList`：控制返回。

**返回值**：

| `g_returnDiffPairList` | 返回值 | 说明 |
|------------------------|--------|------|
| `nil` | `x_cnt` | 创建的差分对数量（默认） |
| `t` | `(x_cnt lo_diffpair)` | 创建的差分对列表 |

**示例**：

示例网络：名为NET1+和NET1-的两个网络传递给此函数。

```skill
axlDiffPairAuto("DP_" "+" "-")    ;; 显示差分对创建和名称生成。结果是一个名为DP_NET1的差分对，成员为NET1+和NET1-
axlDiffPairAuto("" "+" "-")        ;; 给定与前一个示例相同的输入，将产生具有相同成员的差分对，但将差分对命名为NET1
```

---

### axlDiffPairDBID

**说明**：如果数据库中存在名为`t_name`的差分对，则返回其dbid。

**Original**: Returns the dbid of the named differential pair (t_name), if it exists in the database.

**语法**：
```skill
axlDiffPairDBID(t_name)
```

**参数**：
- `t_name`：差分对名称。

**返回值**：
- `o_dbid`：如果存在，则为差分对的dbid。
- `nil`：差分对不存在。

**示例**：
```skill
axlDBGetDesign()->diffpair
```

---

### axlMatchGroupAdd

**说明**：将成员添加到匹配组。合格成员有：网络（如果网络是xnet的一部分，则将xnet添加到组）、xnet、引脚对。请参阅`axlDBMatchGroupCreate`中的讨论。

在不支持电气约束或符号编辑器的产品级别中，命令失败。使用dbids比使用名称更快。

**Original**: Adds members to a matched group. Eligible members are: nets (if a net is part of an xnet the xnet is added to the group), xnets, pinpairs. Command fails in product tiers that do not support electrical constraints or the symbol editor. Using dbids is faster than using names.

**语法**：
```skill
axlMatchGroupAdd(o_mgdbid/t_mgName o_dbid/lo_dbid)
```

**参数**：
- `o_mgdbid`：匹配组的dbid。
- `t_mgName`：匹配组的名称。
- `o_dbid`：要添加到匹配组的合法数据库dbid。
- `lo_dbid`：要添加到匹配组的合法数据库dbids列表。

**返回值**：
- `t`：已添加元素。
- `nil`：一个或多个元素添加失败。

**示例**：
```skill
;; 将两个网络添加到在axlMatchGroupCreate中创建的匹配组：
mg = car(axlSelectByName("MATCH_GROUP" "MG1"))
nets = axlSelectByName("NET" '("B1_OUT" "B2_OUT"))
axlMatchGroupAdd(mg nets)
```

**相关函数**：`axlMatchGroupCreate`

---

### axlMatchGroupCreate

**说明**：创建新的匹配组。如果已存在具有相同名称的匹配组，则返回`nil`。匹配组需要填充，否则在保存时将被删除。使用`axlMatchGroupAdd`命令填充匹配组。

`axlMatchGroupCreate`命令在不支持电气约束或符号编辑器的产品级别中失败。如果匹配组是部分或完全从ECset创建的，则可以删除它，但当由于设计中的修改需要ECset展平时，它会重新出现。SKILL函数不指示ECset派生的匹配组。

您可以通过以下方式访问数据库中的匹配组列表：`axlDBGetDesign()->matchgroup`

RELATIVE_PROPAGATION_DELAY：RELATIVE_PROPAGATION_DELAY属性可以添加到匹配组、xnet和引脚对。如果将其添加到匹配组，则任何不具有该属性的匹配组成员将从匹配组继承它。

匹配组包含以下元素：xnet、网络和引脚对。如果网络是xnet的一部分，则将xnet添加到匹配组。Xnet和引脚对可以属于多个匹配组，因此RPD属性存在于网络、xnet和引脚对的dbid上。此属性是列表的列表，其中每个子列表包含匹配组dbid和RELATIVE_PROPAGATION_DELAY值：
`rpd = ((o_mgDbid t_rpdValue) ....)`

因此，如果引脚对属于2个匹配组，您会看到两个列表被继承。单个匹配组中的引脚对具有单个列表的列表。例如，MG3中的引脚对，具有全局范围和覆盖delta/容差`10ns:5%`报告：
`rpd = ((dbid:61315360 "MG3:G:::10 ns:5 %"))`

同一引脚对没有覆盖将报告默认匹配组值为：
`rpd = ((dbid:61315360 "MG3:G:AD:AR:0 ns:5 %"))`

在两个示例中，dbid引用匹配组id（MG3）。

RELATIVE_PROPAGATION_DELAY语法在《Allegro Property Reference Manual》中讨论。通常语法是：`<Match group name>:<scope>:<pinpair>:<value>`

您可以使用`axlMatchGroupProp`添加和删除匹配组成员或引脚对dbid的属性。创建属性值时，必须包含匹配组名称，但不能包含显式引脚对。例如，以下将RPD属性添加到名为MG2的匹配组：
`axlMatchGroupProp(mg n1 "MG1:G:::100 ns:5 %")`

此属性的附加限制：
- 引脚对应将引脚对部分留空（"::"）。示例：`"MG2:G:::0 ns:5 %"`
- 匹配组不应引用显式引脚对，但如果非空，应使用引脚对类型（例如，"AD:AR"、"D:R"等）
- 对于网络和xnet，如果访问RELATIVE_PROPAGATION_DELAY属性，您可能会看到展平版本。这意味着如果网络和xnet是多个匹配组的一部分，它们都会以连接形式出现在RELATIVE_PROPAGATION_DELAY属性中。作为网络或xnet级别属性一部分的任何引脚对都显示为网络或xnet的属性。这用于支持传统应用程序，如网表工具。使用`axlDBAddProp`和`axlDBDeleteProp`命令修改属性可能会影响所有匹配组和引脚对。建议使用`axlMatchGroupProp`来修改所有对象的RELATIVE_PROPAGATION_DELAY属性。

**Original**: Creates a new match group. If a match group already exists with the same name, nil is returned. Match groups need to be populated, or they are deleted when saving. Use the axlMatchGroupAdd command to populate the match groups. The axlMatchGroupCreate command fails in product tiers that do not support electrical constraints or the symbol editor.

**语法**：
```skill
axlMatchGroupCreate(t_name)
```

**参数**：
- `t_name`：匹配组名称（转换为大写）。

**返回值**：
- `nil`：错误或具有相同名称的匹配组已存在。
- `o_mgdbid`：匹配组的dbid。

**示例**：
```skill
mg = axlMatchGroupCreate("mg1")
```

**相关函数**：`axlPinPairSeek`, `axlPinsOfNet`, `axlMatchGroupCreate`, `axlMatchGroupDelete`, `axlMatchGroupAdd`, `axlMatchGroupRemove`, `axlMatchGroupProp`

---

### axlMatchGroupDelete

**说明**：删除匹配组。在不支持电气约束或符号编辑器的产品级别中，命令失败。使用dbids比使用名称更快。

**Original**: This deletes a match group. The command fails in product tiers that do not support electrical constraints or the symbol editor. Using dbids is faster than using names.

**语法**：
```skill
axlMatchGroupDelete(o_mgdbid/t_mgName)
```

**参数**：
- `o_mgdbid`：匹配组的dbid。
- `t_mgName`：匹配组的名称。

**返回值**：
- `t`：匹配组已删除。
- `nil`：失败。

**示例**：
```skill
mg = car(axlSelectByName("MATCH_GROUP" "MG1"))
axlMatchGroupDelete(mg)
;; 或
axlMatchGroupDelete("MG1")
```

**相关函数**：`axlMatchGroupCreate`

---

### axlMatchGroupProp

**说明**：从匹配组成员添加或删除RELATIVE_PROPAGATION_DELAY属性。属性必须是包含RPD名称的合法RPD语法。在不支持电气约束或符号编辑器的产品级别中，命令失败。使用dbids比使用名称更快。

**Original**: Adds or removes the RELATIVE_PROPAGATION_DELAY property from a member of a match group. Property must be a legal RPD syntax that includes the RPD name. The command fails in product tiers that do not support electrical constraints or the symbol editor. Using dbids is faster than using names.

**语法**：
```skill
axlMatchGroupProp(o_mgdbid/t_mgName o_dbid t_value/nil)
```

**参数**：
- `o_mgdbid`：匹配组的dbid
- `t_mgName`：匹配组的名称
- `o_dbid`：匹配组成员的合法数据库dbid
- `t_value`：合法语法中的RELATIVE_PROPAGATION_DELAY值。如果值为`nil`，则删除属性。

**返回值**：
- `t`：已添加元素。
- `nil`：一个或多个元素添加失败。

**示例**：
```skill
mg = car(axlSelectByName("MATCH_GROUP" "MG1"))
nets = axlSelectByName("NET" '("B1_OUT" "B2_OUT"))
n1 = car(nets)
n2 = cadr(nets)
axlMatchGroupAdd(mg nets)
axlMatchGroupProp(mg n1 "MG1:G:::100 ns:5 %")
axlMatchGroupProp(mg n2 "MG1:G:AD:AR:0 ns:5 %")
axlMatchGroupProp(mg n2 nil)      ;; 从n2删除属性
```

**相关函数**：`axlMatchGroupCreate`

---

### axlMatchGroupRemove

**说明**：从现有匹配组中移除元素。元素必须是匹配组的成员（属性groupMembers）。在不支持电气约束或符号编辑器的产品级别中，命令失败。使用dbids比使用名称更快。

**Original**: Removes elements from an existing match group. Elements must be members (attribute groupMembers) of the match group. The command fails in product tiers that do not support electrical constraints or the symbol editor. Using dbids is faster than using names.

**语法**：
```skill
axlMatchGroupRemove(o_mgdbid/t_mgName o_dbid/lo_dbid)
```

**参数**：
- `o_mgdbid`：匹配组的dbid。
- `t_mgName`：匹配组的名称。
- `o_dbid`：要从匹配组中移除的合法数据库dbid。
- `lo_dbid`：要从匹配组中移除的合法数据库dbids列表。

**返回值**：
- `t`：已移除元素。
- `nil`：一个或多个元素移除失败。

**示例**：
```skill
axlMatchGroupRemove(mg car(nets))
```

**相关函数**：`axlMatchGroupCreate`

---

### axlNetSched

**说明**：这是命令处理器为网络布线顺序命令调用的主例程。

**Original**: This is the main routine that the command processor calls for the net schedule command.

**语法**：
```skill
axlNetSched()
```

**参数**：无

**返回值**：
- `t`

---

### axlPinPair

**说明**：创建或删除引脚对。引脚对由同一网络上的两个无序引脚或ratT组成。例如，引脚对`u1.2:r1.2`与引脚对`r1.2:u1.2`相同。如果引脚对已存在，则返回现有引脚对。在不支持电气约束或符号编辑器的产品级别中，命令失败。

如果两个引脚（或ratT）不属于同一XNet，则不能创建引脚对。如果引脚对在ECSet中创建，则ECsetDerived属性将为`t`，您不能删除它。您必须在关联的ECset中查找与网络、XNet、差分对或总线关联的ECset并修改引脚对。

在数据库保存时，引脚对必须是匹配组的一部分，或分配有合法的电气约束属性，否则将被删除。合法电气属性为：PROPAGATION_DELAY、MIN_FIRST_SWITCH、MAX_FINAL_SETTLE、IMPEDANCE_RULE、TIMING_DELAY_OVERRIDE、RELATIVE_SKEW。

RELATIVE_PROPAGATION_DELAY作为列表的列表存储在RPD属性上。这是因为引脚对可以是多个匹配组的成员。请参阅`axlMatchGroupCreate`了解更多信息。

使用dbids比使用名称更快。

**Original**: This creates or deletes a pinpair. A pinpair consists of two unordered pins or ratTs on the same net. If the pinpair already exists then the existing pinpair is returned. The command fails in product tiers that do not support electrical constraints or the symbol editor. You cannot create a pinpair if both pins (or ratTs) do not belong to the same XNet. Using dbids is faster than using names.

**语法**：
```skill
;; 添加引脚对
axlPinPair(o_pin1/t_pin1 o_pin2/t_pin2) ==> o_pinpair
;; 删除引脚对
axlPinPair(o_pinpair/lo_pinpair) ==> t/nil
```

**参数**：
- `o_pin1/o_pin2`：引脚或ratT的dbid
- `t_pin1/t_pin2`：引脚名称（`<refdes>.<pin#>`）；不支持ratT名称。
- `o_pinpair`：引脚对dbid。
- `lo_pinpair`：引脚对dbids列表（仅删除模式）。

**返回值**：
- 取决于模式：
  - `nil`：错误
  - `t`：删除成功。
  - `o_pinpair`：添加或修改的差分对的dbid。

**相关函数**：`axlPinPairSeek`, `axlPinsOfNet`, `axlMatchGroupCreate`

**示例**：

示例1：XNet有两个网络；NET1和NET1A。这演示了引脚对存储在XNet上。
```skill
;; 使用名称创建引脚对：
pp = axlPinPair("U2.13" "R1.2")
;; 使用网络NET1A的ratT创建引脚对：
ratTs = axlPinsOfNet("NET1A" 'ratT)
pp = axlPinPair("U2.13" car(ratTs))
;; 验证引脚对都在NET1A上：
n = car(axlSelectByName("NET" "NET1A"))
n->pinpair RETURNS nil
;; 检查XNet（NET1）：
xn = car(axlSelectByName("XNET" "NET1"))
xn->pinpair RETURNS (dbid:21697512 dbid:21697232)
```

示例2：删除示例1中的所有引脚对：
```skill
axlPinPair(xn->pinpair)
```

---

### axlPinPairSeek

**说明**：给定两个引脚或ratT，报告它们是否是引脚对的一部分。

**Original**: Given two pins or ratTs reports if they are part of a pinpair.

**语法**：
```skill
axlPinPairSeek(o_pin1 o_pin2)
```

**参数**：
- `o_pin1/o_pin2`：引脚或ratT的dbid。
- `t_pin1/t_pin2`：引脚名称（`<refdes>.<pin#>`）；不支持ratT名称。

**返回值**：
- `o_pinpair`：引脚对dbid。
- `nil`：给定引脚的引脚对不存在。

**相关函数**：`axlPinPair`

**示例**：
```skill
pp = axlPinPair("U2.13" "R1.2")
axlPinPairSeek("U2.13" "R1.2")
```

---

### axlPinsOfNet

**说明**：返回网络或xnet上的引脚和ratTs列表。第一个参数可以是网络、xnet dbid或网络名称（不支持xnet名称）。第二个选项`g_mode`可以是`'pin`仅返回引脚，`'ratT`返回ratTs列表，或`nil`返回引脚和ratTs。返回的项目列表中没有传达含义。

**Original**: Returns list of pins and ratTs on a net or xnet. First argument can be either a net, xnet dbid or a net name (xnet names are not supported). Second option, g_mode, can be 'pin to return only the pins, 'ratT to return list of ratTs or nil to return both pins and ratTs. There is no meaning conveyed in the list of items returned.

**语法**：
```skill
axlPinsOfNet(o_net/t_net g_mode)
```

**参数**：
- `o_net`：网络或xnet的dbid。
- `t_net`：网络名称（不支持xnet名称）。
- `g_mode`：
  - `nil`：返回网络的所有引脚和ratTs。
  - `'pin`：仅返回引脚。
  - `'ratT`：仅返回ratT。

**返回值**：
- `lo_pins`：网络或xnet上的引脚和/或ratTs列表。
- `nil`：没有符合标准的（或错误，dbid不是网络或xnet）。

**示例**：
```skill
;; GND上的所有引脚：
net = car(axlSelectByName("NET" "GND"))
lpins = axlPinsOfNet(net, 'pins)
;; 设计根目录上第一个xnet的所有引脚和ratTs（可能是网络）：
xnet = car(axlDBGetDesign()->xnet)
lpins = axlPinsOfNet(xnet, nil)
```

---

### axlRemoveNet

**说明**：删除网络。可以提供要删除的网络名称字符串，或该网络上对象的dbid。网络名称可能用于属性。此函数不更新这些值。

**Original**: Removes a net. May either give a string with the net name to be renamed or dbid of an object on that net. The net name may be used in properties. This function does not update these values.

**语法**：
```skill
axlRemoveNet(t_name/o_dbid [g_ripup])
```

**参数**：
- `t_name`：网络名称。
- `o_dbid`：网络的dbid。
- `g_ripup`：可选参数。删除网络时撕裂关联的蚀刻。

**返回值**：
- `t`：网络已成功删除。
- `nil`：没有网络被删除。

**示例**：
```skill
axlRemoveNet("GND")
```

---

### axlRenameNet

**说明**：重命名网络。对于旧对象，可以提供要重命名的网络名称字符串，或该网络上对象的dbid。如果新网络名称已存在于数据库中，则失败。此函数不刷新任何`axl` dbids以反映新网络名称。网络名称可能用于属性。此函数不更新属性值中的网络名称。

**Original**: Renames a net. For the old object, may either give a string with the net name to be renamed, or dbid of an object on that net. Fails if the new net name already exists in the database. This function does not refresh any axl dbids to reflect the new net name. The net name may be used in properties. This function does not update net names in property values.

**语法**：
```skill
axlRenameNet(t_old_name t_new_name)  ⇒ t/nil
axlRenameNet(o_dbid t_new_name)      ⇒ t/nil
```

**参数**：
- `t_old_name`：现有网络名称。
- `o_dbid`：网络上对象的dbid。
- `t_new_name`：新网络名称（不应存在于数据库中。）

**返回值**：
- `t`：网络已成功重命名。
- `nil`：网络名称已存在于数据库中。

**示例**：
```skill
axlRenameNet("GND" "NEWGND")
;; 首先验证新网络名称不存在
axlSetFindFilter(?enabled '("noall" "nets"))
if(axlSingleSelectName("NET" '("NEWGND") ) then
  axlRenameNet(dbid "NEWGND")
```

---

### axlRenameRefdes

**说明**：重命名参考位号。对于任一参数，可以使用参考位号名称或元件实例。如果两个参考位号都存在，则执行交换。

**Original**: Renames a refdes. For either argument, may use a refdes name or a component instance. If both refdes exist, a swap is done.

**语法**：
```skill
axlRenameRefdes(t_old_name/o_oldCompDbid t_new_name/o_newCompDbid)
```

**参数**：
- `t_oldName`：现有参考位号名称。
- `o_oldCompDbid`：元件dbid。
- `t_newName`：新参考位号名称。
- `o_newCompDbid`：元件dbid。

**返回值**：
- `t`：参考位号已成功重命名或交换。
- `nil`：由于参数不正确，未重命名或交换参考位号。

**示例**：
```skill
axlRenameRefdes("U1" "X1")           ;; 按名称更改参考位号
;; 使用两个元件dbid交换：
axlSetFindFilter(?enabled '("noall" "components") ?onButtons '(all))
axlSingleSelectName("COMPONENT" "U1")
firstComp = car(axlGetSelSet())
axlSingleSelectName("COMPONENT" "U2")
secondComp = car(axlGetSelSet())
axlRenameRefdes(firstComp secondComp)
```

---

### axlSchedule

**说明**：获取网络布线顺序。当`g_userSchedule`为`t`时，从网络获取用户布线顺序或部分用户布线顺序。如果网络完全是算法布线的，则返回nil。建议使用`t`。当`g_userSchedule`为nil时，返回完整网络的布线顺序，即使网络完全是算法布线的。

`t_schedule`的格式是$SCHEDULE netin（第三方）格式的字符串。有关语法的更多信息，请参阅netin文档。

**Original**: Gets net schedule. When g_userSchedule is t, this fetches the user schedule or a partial user schedule from a net. Returns nil if the net is completely algorithm scheduled. Using t is recommended.

**语法**：
```skill
axlSchedule(o_net/t_net [g_userSchedule])
```

**参数**：
- `o_net`：网络的dbid
- `t_net`：网络名称
- `g_userSchedule`：（可选）如果为`t`，则返回网络是用户布线或部分用户布线时的布线顺序。如果为nil，则网络的其他nets以netin格式移除

**返回值**：
- `t_schedule`：布线顺序或部分用户布线顺序。
- `nil`：失败或网络不是用户布线或部分用户布线。使用`axlDebug`获取更多信息。

**示例**：
Net2具有以下引脚和rat-Ts：P1.7 U1.4 U1.10 U2.6 T.1
它是部分用户布线的，例如P1.7、U1.4和U1.10应连接到rat-T T.1。引脚U2.6是算法布线的，但子布线顺序（部分）指示它应连接到U1.10（在布线顺序字符串中由星号'*'指示）。

```skill
;; 获取部分布线顺序（注意没有U2.6）
q = axlSchedule("NET2" t)
==> "P1.7 T.1 U1.4 ; T.1 *U1.10 "
;; 同一网络的完整布线顺序
q = axlSchedule("NET2" t)
==> "P1.7 T.1 U1.4 ; T.1 *U1.10 U2.6 "
```

**相关函数**：`axlScheduleNet`

---

### axlScheduleNet

**说明**：将用户布线顺序或部分用户布线顺序应用于网络。`t_schedule`的格式是$SCHEDULE netin（第三方）格式的字符串。有关语法的更多信息，请参阅netin文档。

当`t_schedule`为`nil`时，它从网络中移除任何用户布线顺序或部分用户布线顺序，并恢复其默认布线顺序算法（NET_SCHEDULE属性）。

**Original**: This applies a user schedule or a partial user schedule to a net. Format of t_schedule is a string in the $SCHEDULE netin (3rd party) format. See netin documentation for more info about the syntax. When t_schedule is nil it removes any user schedule or partial user schedule from the net and restores its default schedule algorithm.

**语法**：
```skill
axlScheduleNet(o_net/t_net t_schedule/nil)
```

**参数**：
- `o_net`：网络的dbid
- `t_net`：网络名称
- `t_schedule`：使用$SCHEDULE netin格式的布线顺序或部分布线顺序；如果为`nil`，则移除

**返回值**：
- `t`：布线顺序已应用。
- `nil`：失败或参数不正确（使用`axlDebug`获取更多信息）。

**相关函数**：`axlSchedule`

---

### axlWriteDeviceFile

**说明**：给定元件定义，写出第三方设备文件。写入指定的目录，或如果没有给定目录或`nil`，则写入当前目录。文件名是compDef->deviceType的小写，扩展名为.txt。例如，如果元件定义（compDef）设备类型为CAP1，则设备文件名为cap1.txt。

还创建一个`devices.map`文件，如果设备名称包含非法字符作为文件名，则该文件为空。有关设备文件语法，请参阅netin文档。如果您使用Cadence前端原理图包，请勿使用此函数。此函数会覆盖目录中现有的<device>和`devices.map`文件。

**Original**: Given a component definition, writes out a third party device file. Writes to the directory specified, or if no directory or nil is given, writes to the current directory. Also creates a devices.map file. See netin documentation for device file syntax. Do not use this function if you use Cadence Front-End Schematic packages. This function overwrites existing <device> and devices.map files in the directory.

**语法**：
```skill
axlWriteDeviceFile(o_compDefDbid [t_output_dir])
```

**参数**：
- `o_compDefDbid`：要写出设备文件的元件定义。
- `t_output_dir`：要写入文件的目录。如果未提供，则使用当前目录。

**返回值**：
- `t`：设备文件已成功写入。
- `nil`：由于不正确的dbid或目录而未能写入设备文件。

**示例**：
```skill
axlWriteDeviceFile(car(axlDBGetDesign()->components)->compdef)
```
写入设计根目录下第一个元件实例的定义的设备文件。

---

### axlWritePackageFile

**说明**：给定符号定义，写出符号`.dra`、`.psm`和关联的焊盘文件。功能类似于单个符号定义的`dump_libraries`。文件根名称是符号定义名称。例如，如果符号定义（symDef）名称为CAPCK05，则输出文件名为capck05.psm和capck05.dra，加上符号一部分的任何焊盘（小写）。此函数会覆盖目标目录中的现有文件。

**Original**: Given a symbol definition, writes out symbol .dra, .psm and associated padstack files. Works like dump_libraries on a single symbol definition. The file name root is the symbol definition name. This function overwrites existing files in the target directory.

**语法**：
```skill
axlWritePackageFile(o_symDefDbid [t_output_dir])
```

**参数**：
- `o_symDefDbid`：要存储在磁盘上的符号定义。
- `t_output_dir`：要存储文件的目录。如果未提供，则使用当前目录。

**返回值**：
- `t`：文件已成功写入。
- `nil`：由于不正确的dbid或目录而未能写入文件。

**示例**：
```skill
symDef = car(axlDBGetDesign()->components)->symbol->definition
axlWritePackageFile(symDef)
```
写入设计根目录下第一个元件实例的符号定义文件。

---

*文档翻译完成 — 返回顶部*
