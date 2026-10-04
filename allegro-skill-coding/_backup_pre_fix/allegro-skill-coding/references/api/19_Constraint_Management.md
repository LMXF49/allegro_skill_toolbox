# 19. 约束管理 (Constraint Management)

**Product Documentation**: Allegro SKILL Reference  
**Product Version**: 17.4-2019, October 2019  

---

## 19.1 约束管理函数概述 (Constraint Management Functions Overview)

**说明**：本章描述与约束管理相关的AXL-SKILL函数。有关约束列表，请参阅《Allegro Constraint Manager用户指南》的附录B。

**Original**: This chapter describes the AXL-SKILL functions related to constraint management. For a list of constraints, see Appendix B in the Allegro Constraint Manager User Guide.

---

## 19.2 约束管理函数 (Constraint Management Functions)

---

### axlCnsAddVia

**说明**：将焊盘添加到物理约束集（cset）的约束过孔列表中。过孔添加到列表末尾（请参阅`axlCnsGetViaList`了解蚀刻编辑中的过孔排序功能）。焊盘不需要存在即可添加到约束过孔列表中。如果`t_csetName`为`nil`，则将焊盘添加到所有物理约束集中。如果过孔已存在于过孔列表中，则返回`t`。锁定的约束集返回`nil`。

**Original**: Adds padstack to the constraint via list of a physical cset. Via is added to end of list (see axlCnsGetViaList of via ordering functionality in etch editing). Padstack does not need to exist to be added to a constraint via list. If t_csetName is nil, add padstack to all physical csets. If a via already exists in the via list, a t is returned. Locked csets return a nil.

**语法**：
```skill
axlCnsAddVia(t_csetName t_padstackName)
```

**参数**：
- `t_csetName`：物理约束集名称，或`nil`表示所有约束集。
- `t_padstackName`：过孔焊盘名称。

**返回值**：
- `t`：如果已添加。
- `nil`：参数错误；约束集不存在或焊盘名称非法。

**示例**：
```skill
;; 将 ALLPAD 添加到所有约束集
axlCnsAddVia(nil "ALLPAD")
;; 将 ONEPAD 添加到 DEFAULT 约束集
axlCnsAddVia("DEFAULT" "ONEPAD")
```

---

### axlCnsAssignPurge

**说明**：此函数已过时。保留用于向后兼容。

**Original**: This function is obsolete. Kept for backward compatibility.

---

### axlCnsClassTableChange

**说明**：此命令更改与现有网络类表条目关联的约束集（Csets）。请参阅`axlCnsClassTableCreate`了解完整的函数族。在Allegro PCB Designer或更低版本中，不能更改包含区域条目的任何表条目。

**Original**: This command changes the Csets associated with an existing net class table entry. See axlCnsClassTableCreate for complete family of functions. You cannot change any table entries containing a region entry in Allegro PCB Designer or lower tiers.

**语法**：
```skill
axlCnsClassTableChange(o_dbidClassTable s_csetType/ll_typeAndName [t_csetName])
```

**参数**：
- `o_dbidClassTable`：现有类表条目的dbid。
- `s_csetType`：约束集类型的符号。`spacing`, `'physical` 或 `'sameNet`
- `ll_typeAndName`：列表 `s_csetType` 和 `t_csetName`
- `t_csetName`：约束集名称字符串

**返回值**：
- 更新的classTable dbid，或失败时返回`nil`

**示例**：
```skill
prop = '((spacing "1") (physical "2") (sameNet "3"))
tbl = axlCnsClassTableChange(tbl prop)
```

**相关函数**：`axlCnsClassTableCreate`

---

### axlCnsClassTableCreate

**说明**：此命令创建类表条目，可包含以下任何内容：
- 类到类（仅间距）
- 区域到类（间距、同网和物理）
- 区域到类到类（仅间距）

可选地，该命令还可以将间距约束集、物理约束集和同网约束集与表条目关联。如果类表条目已存在，则使用提供的约束集进行修改。

区域在Allegro PCB Designer及更低产品中不可用。如果在这些产品中尝试创建基于区域的表条目，命令将失败。不能在符号编辑器中创建类表。

**要点记住**：
- `class1`和`class2`的顺序无关紧要。
- 如果条目已存在，则返回现有条目。
- 网络类可以按域（间距和/或物理）分类。如果网络类限制为一个域，则可能创建跨越域的网络类到任何条目。此表条目将被DRC忽略。
- DRC设置为过期，您必须手动更新DRC。
- 与Constraint Manager不同，您可以添加数据库中尚不存在的约束集名称。在这些情况下，将自动创建约束集。如果您不想创建新的约束集，请通过`axlCnsList`检查您的约束集是否存在。
- 类表条目还可以通过属性覆盖附加约束覆盖（`axlDBAddProp`）。

**Original**: This command creates a class table entry that consists of any of the following: class to class (spacing only), region to class (spacing, same net and physical), region to class to class (spacing only). Optionally, the command also associates a spacing cset, a physical cset, and same net cset with the table entry.

**语法**：
```skill
axlCnsClassTableCreate(g_class1 g_class2 g_region s_csetType/ll_typeAndName [t_csetName])
```

**参数**：
- `g_class1`：NETCLASS dbid或网络类名称
- `g_class2`：NETCLASS dbid、网络类名称或nil
- `g_region`：REGION dbid、区域名称或nil
- `s_csetType`：约束集类型符号，之一：`'spacing`, `'physical` 或 `'samenet`
- `t_csetName`：给定类型的约束集名称字符串
- `ll_typeAndName`：可选值列表，格式为：`((s_csetType t_csetName) (s_csetType t_csetName) ...)`

**返回值**：
- 返回类型为`classTable`的dbid，表示新或现有约束集；错误时返回`nil`

**示例**：
```skill
;; 在设计中创建适当的条目
region = axlRegionCreate("ANALOG")
ncls = axlNetClassCreate("VOLTAGE" '(spacing physical))
;; 添加新的间距区域-类表条目并赋予其间距约束集 "25MILS"
tbl = axlCnsClassTableCreate("VOLTAGE" nil "ANALOG" 'spacing "25MILS")
;; 替代方法，同时添加物理电压约束集
props = '((spacing "25MILS") (physical "VOLTAGE"))
tbl = axlCnsClassTableCreate(ncls nil region props)
```

**相关函数**：`axlCnsClassTableFind`, `axlCnsClassTableSeek`, `axlCnsClassTableChange`, `axlCnsClassTableDelete`, `axlCnsList`

---

### axlCnsClassTableDelete

**说明**：删除类表中的一个或多个条目。DRC标记为过期。

**Original**: Deletes one or more entries in the class table. DRC is marked out of date.

**语法**：
```skill
axlCnsClassTableDelete(o_dbidClassTable/lo_dbidClassTable)
```

**参数**：
- `o_dbidClassTable`：现有类表条目的dbid。
- `lo_dbidClassTable`：删除类表条目列表。

**返回值**：
- `t`：如果成功；`nil`：如果出错

**示例**：
```skill
axlCnsClassTableDelete(tbl)
```

**相关函数**：`axlCnsClassTableCreate`, `axlCnsDeleteRegionClassClassObjects`, `axlCnsDeleteClassClassObjects`

---

### axlCnsClassTableFind

**说明**：此命令根据搜索条件搜索类表中的类表条目。

**Original**: This command searches the class table for class table entries matching the search criteria.

**语法**：
```skill
axlCnsClassTableFind(s_type [o_dbid])
```

**参数**：
- `s_type`：指定要执行的搜索类型。可用选项：
  - `'netclass`：返回所有类条目（除线和元件外的所有条目）
  - `'classClass`：返回所有类到类条目
  - `'classRegion`：返回所有类到区域条目
  - `'classClassRegion`：返回所有类到类到区域条目
  - `'wireProf`：返回所有线轮廓条目（仅限APD+）
  - `'component`：返回所有元件条目（仅限APD+）
  - `'match`：返回包含提供的区域或类dbid（`o_dbid`）的所有条目
- `o_dbid`：仅适用于match选项，将返回包含dbid的所有类表条目。

**返回值**：
- 匹配搜索条件的类表dbid列表；如果未找到匹配项，则返回`nil`。

**示例**：
```skill
;; 返回影响物理、间距或同网DRC的所有类条目
tbl = axlCnsClassTableFind('netclass)
;; 返回包含区域"ANALOG"的所有条目（假设设计有一个名为"ANALOG"的区域）
region = car(axlSelectByName("REGION" "ANALOG"))
tbl = axlCnsClassTableFind('match region)
```

**相关函数**：`axlCnsClassTableCreate`, `axlCnsClassTableSeek`, `axlSelectByName`

---

### axlCnsClassTableSeek

**说明**：此命令查找与提供的dbids完全匹配的特定类表条目。class1和class2的顺序无关紧要，因为C1/C2与C2/C1相同，且表中仅存在一个条目。

**Original**: This command seeks a specific class table entry matching exactly the provided dbids. Order of class1 and class2 does not matter since C1/C2 is the same as C2/C1 and only one entry exists in the table.

**语法**：
```skill
axlCnsClassTableSeek(g_class1 g_class2 g_region)
```

**参数**：
- `g_class1`：NETCLASS dbid、网络类名称或nil
- `g_class2`：NETCLASS dbid、网络类名称或nil
- `g_region`：REGION dbid、区域名称或nil

**返回值**：
- 匹配搜索条件的类表条目；如果未找到则返回`nil`。

**示例**：
```skill
;; 返回名为VOLTAGE的网络类和名为ANALOG的区域的类表条目
tbl = axlCnsClassTableSeek("VOLTAGE" nil "ANALOG")
;; 使用dbids的替代方法
region = car(axlSelectByName("REGION" "ANALOG"))
netclass = car(axlSelectByName("NETCLASS" "VOLTAGE"))
tbl = axlCnsClassTableSeek(netclass nil region)
```

**相关函数**：`axlCnsClassTableCreate`

---

### axlCNSCreate

**说明**：在指定域中创建新的约束集。对于间距和物理约束集，必须提供现有约束集作为复制约束集。如果`copyName`为nil，则使用DEFAULT约束集。对于nil `copyName`，电气约束集（ECsets）创建为空。默认情况下，创建的ECset为空。如果提供第二个参数，则复制ECset内容。

要将约束集分配给逻辑对象（如网络、总线或网络类），请将PHYSICAL_CONSTRAINT_SET、SPACING_CONSTRAINT_SET、SAME_NET_SPACING_CONSTRAINT_SET或ELECTRICAL_CONSTRAINT_SET属性分配给逻辑对象，其中属性值为约束集名称。

电气约束集不能在Allegro PCB Designer中创建。

**Original**: Creates a new constraint set in the specified domain. For spacing and physical csets, you must supply an existing cset as the copy cset. If the copyName is nil, the DEFAULT cset is used. Electrical csets (ECsets) are created empty for a nil copyName. Electrical csets cannot be created in Allegro PCB Designer.

**语法**：
```skill
axlCNSCreate(g_domain t_name t_copyName)
```

**参数**：
- `g_domain`：指定约束集的域。可能值：Physical, spacing, electrical, 或 `'sameNet`。
- `t_name`：新约束集名称。（转换为大写）字符串必须通过允许的字符集。
- `t_copyName`：用作模板的约束集名称。如果为`nil`，则间距和物理域使用DEFAULT作为模板，而对于电气域，创建一个空的ECset。

**返回值**：
- `t`：约束集已创建。
- `nil`：失败原因：域名非法；约束集名称非法；约束集已存在；或`copyName`约束集不存在。

**示例**：
```skill
;; 创建名为foo的新物理约束集
axlCNSCreate('physical "foo" nil)
```

**相关函数**：`axlCNSEcsetCreate`, `axlCNSDelete`, `axlCnsList`, `axlDBAddProp`, `axlNetClassCreate`

---

### axlCNSCsetLock

**说明**：锁定或解锁给定域中的约束集。请参阅`axlCNSIsLockedDomain`中的讨论。通常应该锁定或解锁整个域，因为这匹配DRC用户模型。提供此接口是为了临时解锁锁定的约束集，进行更改，然后重新应用锁定。

更改约束集上的锁定可能需要相当长的时间，因为DRC需要更新。在间距域中，动态形状也需要更新。如果进行其他更改，请考虑使用`axlDBCloak`隐藏整个过程。此API已为单个约束集使用隐藏。

**Original**: This locks or unlocks a constraint set in the given domain. You should usually lock or unlock the entire domain since this matches the DRC user model. Changing the lock on a cset can take a considerable amount of time since DRC needs to be updated. This API already uses cloaking for the individual cset.

**语法**：
```skill
axlCNSCsetLock(g_domain t_csetName g_mode)
```

**参数**：
- `g_domain`：约束集域；`'physical`, `'spacing`, `'sameNet`, `'electrical`
- `t_csetName`：约束集名称
- `g_mode`：可以是`t`（锁定）或`nil`（解锁）

**返回值**：
- 返回`t`如果锁定状态已更新；`nil`表示错误。

**示例**：
```skill
;; 锁定间距约束集DEFAULT，其副作用是锁定间距和同网域
axlCNSCsetLock('spacing "DEFAULT" t)
```

**相关函数**：`axlCNSIsLockedDomain`

---

### axlCNSDelete

**说明**：删除约束集及其对任何对象（如网络、网络类等）的引用。必须先解锁锁定的约束集，然后才能删除它们。如果是间距或物理域，则不能删除DEFAULT约束集。在Allegro PCB Design L中不能删除电气约束集。

**Original**: Deletes a cset and its references to any objects such as nets, net classes, etc. Locked csets must first be unlocked before you delete them. If it is a spacing or physical domain, you cannot delete the DEFAULT cset. You cannot delete electrical csets in Allegro PCB Design L.

**语法**：
```skill
axlCNSDelete(g_domain t_name/o_dbidEcset)
```

**参数**：
- `g_domain`：指定约束集的域。有效值：`'physical`, `'spacing`, `'sameNet`, `'electrical`
- `t_name`：约束集名称。
- `o_dbidEcset`：如果是ECset，其dbid。

**返回值**：
- `t`：约束集已删除。
- `nil`：约束集未删除，因为约束集不存在或约束集已锁定，或约束集为`t`。

**示例**：
```skill
axlCNSDelete('electrical "UPREV_DEFAULT")
```

**相关函数**：`axlCNSCreate`

---

### axlCnsDeleteClassClassObjects

**说明**：删除所有类-类条目。

**Original**: Delete all Class-Class entries.

**语法**：
```skill
axlCnsDeleteClassClassObjects()
```

**参数**：无

**返回值**：
- 删除的对象计数。

**相关函数**：`axlCnsPurgeCsets`, `axlCnsDeleteRegionClassClassObjects`

---

### axlCnsDeleteRegionClassClassObjects

**说明**：删除所有区域-类-类条目。

**Original**: Deletes all Region-Class-Class entries.

**语法**：
```skill
axlCnsDeleteRegionClassClassObjects()
```

**参数**：无

**返回值**：
- 删除的对象计数。

**相关函数**：`axlCnsPurgeCsets`

---

### axlCnsDeleteRegionClassObjects

**说明**：删除所有区域-类条目。

**Original**: Delete all Region-Class entries.

**语法**：
```skill
axlCnsDeleteRegionClassObjects()
```

**参数**：无

**返回值**：
- 删除的对象计数。

**相关函数**：`axlCnsPurgeCsets`

---

### axlCnsDeleteVia

**说明**：从物理过孔约束列表`t_csetName`中删除焊盘。如果`t_csetName`为`nil`，则从所有物理约束集中删除提供的焊盘。

**注意**：如果要求删除过孔列表中不存在的过孔，将返回`t`。锁定的约束集将返回`nil`。

**Original**: Deletes padstack from the physical via constraint list, t_csetName. If t_csetName is nil, delete provided padstack from all physical constraint sets. Notes: Will return t if asked to delete a via that does not exist in the via list. Locked csets will return a nil.

**语法**：
```skill
axlCnsDeleteVia(t_csetName t_padstackName)
```

**参数**：
- `t_csetName`：物理约束集名称或nil表示所有约束集。
- `t_padstackName`：过孔焊盘名称。

**返回值**：
- `t`：如果已删除。
- `nil`：参数错误；约束集不存在或焊盘名称非法。

**示例**：
```skill
;; 删除默认约束集的过孔
axlCnsDeleteVia("DEFAULT" "VIA")
;; 删除所有约束集的过孔
axlCnsDeleteVia(nil "VIA")
```

**相关函数**：`axlCnsGetViaList`, `axlPurgePadstacks`

---

### axlCNSDesignModeGet

**说明**：获取属于设计约束集检查集的当前DRC模式。这些约束涉及整个电路板。要确定当前支持的设计约束检查，请使用`axlCNSDesignModeGet()`命令。`'print`模式提供在报告中显示的名称，如show element。这具有`axlDebug`支持。可用约束检查可能因版本而异。

**Original**: Gets the current DRC modes for checks that fall into the set of design constraints. These constraints pertain to the entire board. To determine the design constraint checks currently supported, use the axlCNSDesignModeGet() command.

**语法**：
```skill
axlCNSDesignModeGet(nil)                     ⇒ ls_constraints
axlCNSDesignModeGet('all)                    ⇒ lls_constraintNModes
axlCNSDesignModeGet('editable)               ⇒ t/nil
axlCNSDesignModeGet(s_name/t_name)           ⇒ s_mode/nil
axlCNSDesignModeGet(s_name/t_name 'print)    ⇒ t_name/nil
```

**参数**：
- `nil`：返回设计类型DRC中的所有检查。
- `'all`：返回所有检查和当前模式。
- `'editable`：如果模式可以更改则返回`t`，如果模式未更改且处于Allegro PCB Editor studio中（不提供此选项）则返回`nil`。
- `s_name`：检查的符号名称。
- `t_name`：检查的字符串名称。
- `'print`：可打印约束名称选项。

**返回值**：
- `ls_names`：检查列表（`s_name` ...）
- `lls_names`：检查及其模式列表（(`s_name s_mode`) ...）
- `s_mode`：模式 `'on`, `'off` 或 `'batch`
- `t_name`：可打印约束名称

**示例**：
```skill
axlCNSDesignModeGet(nil)                ;; 获取当前设计约束列表
axlCNSDesignModeGet('all)               ;; 获取所有设计约束的设置列表
axlCNSDesignModeGet('Package_to_Package_Spacing)  ;; 获取package to package的当前设置
axlCNSDesignModeGet("Negative_Plane_Islands")      ;; 使用字符串获取负平面岛的当前设置
```

---

### axlCNSDesignModeSet

**说明**：设置设计约束的当前DRC模式。模式控制整个电路板上该设计约束检查的DRC。要确定支持的检查，请使用：`axlCNSDesignModeGet()`

您可以使用参数`'all`设置所有检查，使用`t_name`设置单个检查，或将检查列表设置为相同模式，如下所示：

出于性能原因，更改模式或值不会调用DRC。您必须手动调用DRC。您可以标记更改以执行较少的DRC更新，具体取决于您的更改（请参阅`axlCNSMapUpdate`。）可用约束检查可能因版本而异。

**Original**: Sets the current DRC modes for design constraints. The modes control the DRC for that design constraint check on the entire board. For performance reasons, changing modes or values does not invoke DRC. You must manually invoke DRC. You can mark changes in order to perform fewer DRC updates, depending on your changes (see axlCNSMapUpdate.)

**语法**：
```skill
axlCNSDesignModeSet(t_name/s_name t_mode/s_mode)             ⇒ t/nil
axlCNSDesignModeSet('all t_mode/smode)                         ⇒ t/nil
axlCNSDesignModeSet(l_constraintNModes t_mode/smode)            ⇒ t/nil
axlCNSDesignModeSet(ll_constraintNModes)                      ⇒ t/nil
```

**参数**：
- `s_name`：检查的符号名称。
- `t_name`：检查的字符串名称。
- `s_mode`：模式设置可以是`'on`, `'off`, 或 `'batch`。
- `t_mode`：字符串模式设置可以是`"on"`, `"off"` 或 `"batch"`。
- `'all`：返回给定Allegro PCB Editor级别的所有检查。

**返回值**：
- `t`：成功
- `nil`：失败。

**示例**：
```skill
axlCNSDesignModeSet('Package_to_Place_Keepin_Spacing 'on)   ;; 开启package to package keepin检查
axlCNSDesignModeSet('all 'batch)                             ;; 使所有设计约束仅批处理
axlCNSDesignModeSet('(Negative_Plane_Islands Pad_Soldermask_Alignment) 'off)  ;; 关闭两个约束
axlCNSDesignModeSet('((Package_to_Place_Keepout_Spacing 'on)) )    ;; 将各种约束设置为不同模式
```

**编程示例**：请参阅`cns-design.il`，位于：`<cdsroot>/share/pcb/examples/skill/cmds`

---

### axlCNSDesignValueCheck

**说明**：检查给定值的语法是否符合给定约束的允许语法。使用函数`axlCNSDesignGetValue(nil)`获取约束名称。允许语法可能因版本而异。

**Original**: Checks the syntax of the given value against the allowed syntax for the given constraint. You use the function axlCNSDesignGetValue(nil) to get the constraint names. Allowed syntax may change from release to release.

**语法**：
```skill
axlCNSDesignValueCheck(s_name/t_name g_value)
  ⇒ (t_string/nil, nil/t_errorMsg)/nil
```

**参数**：
- `s_name`：约束的符号名称。
- `t_name`：约束的字符串名称。
- `g_value`：要验证的值

**返回值**：
- `(t_string/nil)`：值正确。`t_string`显示当前用户单位首选项。例如，如果提供"10"，则如果MILS是当前数据库单位，返回可能是`"10.0 MILS"`。
- `(nil/t_errorMsg)`：值不正确。`t_errorMsg`反映错误。
- `nil`：参数不正确。

**示例**：
```skill
axlCNSDesignValueCheck('Negative_Plane_Islands "10 mils")
```

---

### axlCNSDesignValueGet

**说明**：从支持值的设计约束中获取值。使用`axlCNSDesignValueGet(nil)`确定这些约束的集合。约束检查可能因版本而异。

**Original**: Fetches the values from those design constraints that support values. Use axlCNSDesignValueGet(nil) to determine the set of these constraints. Constraint checks may change from release to release.

**语法**：
```skill
axlCNSDesignValueGet(nil [g_returnNameString])              ⇒ ls_constraints
axlCNSDesignValueGet('all [g_returnString])                ⇒ lls_constraintNValues
axlCNSDesignValueGet(s_name [g_returnString])               ⇒ f_value/t_value/nil
```

**参数**：
- `nil`：返回所有支持值的检查。
- `'all`：返回所有带值的检查及其当前值。
- `s_name`：值的符号名称。
- `t_name`：值的字符串名称。
- `g_returnNameString`：将约束名称作为字符串返回（默认是符号返回。）
- `g_returnString`：默认情况下，以用户单位（浮点数）返回原生类型。如果为`t`，则返回MKS字符串，其中`nil`返回原生类型。

**返回值**：
- `ls_names`：所有支持值的控件列表（符号。）
- `lls_constraintNValues`：所有控件及其值的列表
- `f_value` = 用户单位值，`t_value` = MKS字符串值。

**示例**：
```skill
axlCNSDesignValueGet(nil)                       ;; 获取支持值的设计约束列表
axlCNSDesignValueGet('all 't)                  ;; 获取所有设计约束的设置列表，值以MKS字符串返回
axlCNSDesignValueGet('Negative_Plane_Islands)  ;; 获取Negative_Plane_Islands的当前设置（用户单位）
axlCNSDesignValueGet("Pad_Soldermask_Alignment" t)  ;; 获取Pad_Soldermask_Alignment的当前设置为MKS字符串
```

---

### axlCNSDesignValueSet

**说明**：设置设计约束的值。要确定支持的值列表，请使用：`axlCNSDesignValueGet(nil)`

您可以设置单个值或值列表：

出于性能原因，更改值不会调用DRC。您必须手动调用DRC。请参阅`axlCNSMapUpdate`了解可用于标记更改的接口集，以便执行较少的DRC更新。约束检查可能因版本而异。

**Original**: This sets the value of the design constraint. To determine the list of supported values, use: axlCNSDesignValueGet(nil). For performance reasons, changing a value does not invoke DRC. You must manually invoke DRC. See axlCNSMapUpdate for a set of interfaces you can use to mark changes in order to perform fewer DRC updates.

**语法**：
```skill
axlCNSDesignValueSet(t_name/s_name f_value/t_value)          ⇒ t/nil
axlCNSDesignValueSet(ll_constraintNValues)                    ⇒ t/nil
```

**参数**：
- `s_name`：检查的符号名称。
- `t_name`：检查的字符串名称。
- `f_value`：提供的浮点值假定为约束的默认用户单位。值可能舍入。
- `t_value`：如果作为带MKS类型的字符串给定，则值转换为约束的当前用户单位。可能会产生舍入。

**返回值**：
- `t`：设计约束值已设置。
- `nil`：未能设置设计约束值。

**示例**：
```skill
axlCNSDesignValueSet('Negative_Plane_Islands 10.0)         ;; 设置负平面容差为当前数据库单位中的10
axlCNSDesignValueSet('Negative_Plane_Islands "10.0 mils")   ;; 设置负平面容差为10 mils
axlCNSDesignValueSet('((Negative_Plane_Islands "20 inches") (Pad_Soldermask_to_Pad_Soldermask_Spacing 15.9)))  ;; 将各种约束设置为不同值
```

**编程示例**：请参阅`cns-design.il`，位于：`<cdsroot>/share/pcb/examples/skill/cmds`

---

### axlCNSDFAExport

**说明**：保存当前附件文件。

**Original**: Saves current attachment file.

**语法**：
```skill
axlCNSDFAExport(t_fileName)
```

**返回值**：
- `t_dfaFile`：如果成功
- `nil`：失败

**示例**：
```skill
ret = axlCNSDFAExport()
```

**相关函数**：`axlCNSDFAImport`

---

### axlCNSDFAImport

**说明**：将新的DFA表分配给设计或重新分配。使用DFACNSPATH查找文件，并假设`.dfa`扩展名。

**Original**: This assigns or re-assigns a new DFA table to the design. Finds the file using DFACNSPATH and assumes a .dfa extension.

**语法**：
```skill
axlCNSDFAImport(t_dfaFileName/nil)
```

**参数**：
- `t_name`：DFA文件名。如果为`nil`，则从设计中删除DFA表。

**返回值**：
- `t`：如果成功
- `nil`：失败或如果删除附件则不存在

**示例**：
```skill
axlCNSDFAImport("mfg")
```

**相关函数**：`axlCNSDFAExport`, `axlCNSDFAMode`

---

### axlCNSDFAMode

**说明**：设置或查询DFA模式。访问DFA选项。`s_option`设置：
- `'table`：返回DFA表名称（例如，filename）
- `'mode`：返回当前DRC模式
- `'mode` 带参数 `'on`, `'off` 或 `'batch`：设置DFA DRC模式

如果启用DRC模式，则DRC设置为过期。使用`axlCNSDFAMode('table)`测试设计中是否存在DFA表。

**Original**: The function sets or queries the DFA mode. This accesses DFA options. If DRC mode is enabled DRC is set to out of date. Use axlCNSDFAMode('table) to test if a DFA table exists in design.

**语法**：
```skill
axlCNSDFAMode(s_option [s_DRCMode])
```

**参数**：
- `s_option`：见上文
- `s_DRCMode`：模式的可选参数（见上文）

**返回值**：
- `t`：如果成功；`nil`：失败
- 对于`'mode`可以返回`'on`, `'off` 或 `'batch`。对于`'table`返回DFA表名称（这是DFA_TABLE_NAME属性，包含在dfa文件中。它可能不总是匹配原始文件名）。

**示例**：
```skill
ret = axlCNSDFAMode('table)     ;; 查询设计中是否存在DFA表
ret = axlCNSDFAMode('mode)      ;; 获取DFA的当前DRC模式
ret = axlCNSDFAMode('mode 'on)  ;; 将DFA的当前DRC模式设置为on
```

**相关函数**：`axlCNSDFAImport`

---

### axlCNSEcsetCreate

**说明**：创建新的ECset。电气约束集（ECset）是一种将一组电气约束打包成组并应用于一组网络的机制。名称必须合法且小于允许的最大长度。如果ECset已存在，则函数失败。默认情况下，ECset创建为空。可以提供第二个参数以将另一个ECset的内容复制到新ECset中。

**Original**: Creates a new ECset. Electrical Constraint Set (ECset) is a mechanism for packaging up a set of electrical constraints into a group and applying them to a set of nets. The name must be legal and less than the maximum length allowed. Function fails if the ECset already exists. By default, the ECset is created empty. You can provide a second argument to copy the contents of another ECset into the new ECset.

**语法**：
```skill
axlCNSEcsetCreate(t_name [t_copyName/o_dbidCopyEcset])
```

**参数**：
- `t_name`：新ECset的名称（转换为大写）。字符串必须通过允许的字符集。
- `t_copyName`：要从中复制的可选名称。

**返回值**：
- `o_dbidEcset`：新ECset的dbid
- `nil`：由于以下原因之一失败：名称非法，或ECset已存在。

**示例**：
```skill
axlCNSEcsetCreate("MyEmptyEcset")        ;; 创建新的空ECset
p = car(axlDBGetDesign()->ecsets)
axlCNSEcsetCreate("MyNewEcset" p)       ;; 复制第一个ECset的内容
```

**相关函数**：`axlCNSDesignModeSet`, `axlCNSCreate`

---

### axlCNSEcsetDelete

**说明**：从Allegro PCB Editor数据库中删除ECset，并删除分配了此ECset值的任何网络的ELECTRICAL_CONSTRAINT_SET属性。如果ECset已锁定，则必须先解锁它才能删除。

**Original**: Deletes an ECset from the Allegro PCB Editor database and also deletes the ELECTRICAL_CONSTRAINT_SET property from any nets assigned this ECset value. If the ECset is locked, you must unlock it before you can delete it.

**语法**：
```skill
axlCNSEcsetDelete(t_name/o_dbidEcset)
```

**参数**：
- `t_name`：ECset名称
- `o_dbidEcset`：ECset dbid

**返回值**：
- `t`：ECset已成功删除。
- `nil`：ECset未删除，原因：名称不正确，或ECset已锁定。

**示例**：
```skill
axlCNSEcsetDelete("UPREV_DEFAULT")     ;; 按名称删除ECset
p = car(axlDBGetDesign()->ecsets)
axlCNSEcsetDelete(p)                   ;; 删除ECset列表中的第一个ECset
```

---

### axlCNSEcsetGet

**说明**：当您通过ECset名称请求时，返回电气约束集的dbid。电气约束集（ECset）是一种将一组电气约束分组并应用于一组网络的机制。

**Original**: Returns the dbid of the electrical cset when you request it by the ECset name. Electrical Constraint Set (ECset) is a mechanism for grouping a set of electrical constraints and applying them to a set of nets.

**语法**：
```skill
axlCNSEcsetGet(t_name)
```

**参数**：
- `t_name`：ECset名称。

**返回值**：
- `o_dbidEcset`：请求的ECset的dbid。
- `nil`：由于非法名称导致函数失败。

**示例**：
```skill
axlCNSEcsetGet("foo")
```

**相关函数**：`axlCNSEcsetValueGet`, `axlCnsList`

---

### axlCNSEcsetModeGet

**说明**：返回作为电气约束成员的检查的当前DRC模式。这些模式涉及整个电路板。`'print`模式提供在报告中显示的名称，类似于show element命令。这具有`axlDebug`支持。并非所有检查都在所有级别的Allegro PCB Editor中可用。要确定支持的检查集，请使用命令：`axlCNSEcsetModeGet()`。约束检查可能因版本而异。

**Original**: Returns the current DRC modes for checks that are members of electrical constraints. These modes pertain to the entire board. The 'print mode offers the name shown in reports, similar to the show element command. This has axlDebug support.

**语法**：
```skill
axlCNSEcsetModeGet(nil)                   ⇒ ls_constraints
axlCNSEcsetModeGet('all)                   ⇒ lls_constraintNModes
axlCNSEcsetModeGet(s_name/t_name)         ⇒ s_mode/nil
axlCNSEcsetModeGet(s_name/t_name 'print)   ⇒ t_name/nil
```

**参数**：
- `nil`：返回设计类型DRC中的所有检查。
- `'all`：返回所有检查和当前模式。
- `s_name`：检查的符号名称。
- `t_name`：检查的字符串名称。
- `'print`：可打印约束名称选项。

**返回值**：
- `ls_names`：检查列表（`s_name` ...）。
- `lls_names`：检查及其相关模式的列表（(`s_name s_mode`) ...）
- `s_mode`：返回模式 `'on`, `'off`, 或 `'batch`
- `t_name`：可打印约束名称。

**示例**：
```skill
axlCNSEcsetModeGet(nil)                    ;; 列出当前可用的电气约束
axlCNSEcsetModeGet('all)                    ;; 列出所有电气约束的设置
axlCNSEcsetModeGet('Maximum_Stub_Length)    ;; 显示stub长度的当前设置
axlCNSEcsetModeGet("Maximum_Via_Count")     ;; 显示过孔数的当前设置
```

**相关函数**：`axlCNSEcsetModeSet`, `axlCNSEcsetValueGet`

---

### axlCNSEcsetModeSet

**说明**：设置作为电气约束集成员的检查的DRC模式。这些模式控制整个电路板。并非所有检查都在所有级别的Allegro PCB Editor中可用。要确定支持的检查集，请使用命令：`axlCNSEcsetModeGet()`。

出于性能原因，更改模式或值不会调用DRC。您必须手动调用DRC。请参阅`axlCNSMapUpdate`了解可用于标记更改的接口集，以便执行较少的DRC更新。未来版本可能会添加或删除约束检查。axl接口确实保证此接口返回的检查将在版本之间保持恒定。

**Original**: Sets the DRC modes for checks that are members of the electrical constraints set. These modes control the entire board. For performance reasons, changing modes or values does not invoke DRC. You must manually invoke DRC. See axlCNSMapUpdate for a set of interfaces you can use to mark changes in order to perform fewer DRC updates.

**语法**：
```skill
axlCNSEcsetModeSet(t_name/s_name t_mode/s_mode)            ⇒ t/nil
axlCNSEcsetModeSet('all t_mode/s_mode)                       ⇒ t/nil
axlCNSEcsetModeSet(l_constraintNModes t_mode/s_mode)         ⇒ t/nil
axlCNSEcsetModeSet(ll_constraintNModes)                     ⇒ t/nil
```

**参数**：
- `s_name`：检查的符号名称。
- `t_name`：检查的字符串名称。
- `s_mode`：模式设置；可以是`'on`, `'off`, 或 `'batch`。
- `t_mode`：字符串模式设置；可以是`"on"`, `"off"`, 或 `"batch"`。
- `'all`：为给定级别的Allegro PCB Editor设置所有检查。

**返回值**：
- `t`：DRC模式已设置。
- `nil`：DRC模式未设置。

**示例**：
```skill
axlCNSEcsetModeSet('Maximum_Via_Count 'off)         ;; 关闭最大过孔检查
axlCNSEcsetModeSet('all 'batch)                      ;; 使所有电气约束仅批处理
axlCNSEcsetModeSet('(Maximum_Crosstalk Route_Delay) 'off)  ;; 关闭两个约束
axlCNSEcsetModeSet('((Maximum_Crosstalk off) (Propagation_Delay on) (Route_Delay 'on) (Impedance 'batch)) )  ;; 将各种约束设置为不同模式
```

---

### axlCNSEcsetValueCheck

**说明**：检查给定值的语法是否符合给定约束的允许语法。使用函数`axlCNSEcsetValueGet(nil)`获取约束名称。允许语法可能因版本而异。

**Original**: Checks the syntax of the given value against the allowed syntax for the given constraint. You use the function axlCNSEcsetValueGet (nil) to get the constraint names. Allowed syntax may change from release to release.

**语法**：
```skill
axlCNSEcsetValueCheck(s_name/t_name g_value)
  ⇒ (t/t_errorMsg)/nil
```

**参数**：
- `s_name`：约束的符号名称。
- `t_name`：约束的字符串名称。
- `g_value`：要验证的值。

**返回值**：
- `t`：语法正确。
- `t_errorMsg`：语法不正确。消息指示原因。
- `nil`：约束名称不受支持。

**示例**：
```skill
axlCNSEcsetValueCheck('Net_Schedule_Topology "STAR")
```

---

### axlCNSEcsetValueGet

**说明**：获取给定ECset的约束值。使用`axlCNSEcsetValueGet(nil)`确定允许的约束集。每个ECset可以具有所有或不允许的约束。您可以通过ECset名称或其dbid检索ECset值。可以通过以下命令之一获取ECset的dbid：`axlDBGetDesign()->ecsets` 或 `axlCNSEcsetCreate()`

约束检查可能因版本而异。并非所有检查都在所有级别的Allegro PCB Editor中可用。

**Original**: Fetches the constraint values for a given ECset. Use axlCNSEcsetValueGet(nil) to determine the set of allowable constraints. Each ECset may have all or none of the allowed constraints. You can retrieve the ECset values by the ECset name or by its dbid.

**语法**：
```skill
axlCNSEcsetValueGet(nil [g_returnNameString])              ⇒ ls_constraints
axlCNSEcsetValueGet('all [g_returnString])                ⇒ lls_constraintNValues
axlCNSEcsetValueGet(o_ecsetDbid/t_ecsetName s_name [g_returnString])  ⇒ f_value/t_value/nil
```

**参数**：
- `o_ecsetDbid`：ECset dbid。
- `t_ecsetName`：ECset名称。
- `nil`：返回所有支持值的检查。
- `'all`：返回所有带值及其当前值的检查。
- `s_name`：值的符号名称。
- `t_name`：值的字符串名称。
- `g_returnNameString`：将约束名称作为字符串返回（默认是符号返回）。
- `g_returnString`：默认情况下，以用户单位（浮点数）返回原生类型。如果为`t`，则返回MKS字符串，其中`nil`返回原生类型。

**返回值**：
- `ls_names`：所有支持值的控件列表（符号）。
- `lls_constraintNValues`：所有控件及其值的列表，格式为：
  ```
  '((s_name f_value/t_value) ...)
  ```
  `f_value` = 用户单位值，`t_value` = MKS字符串值。

**示例**：
```skill
axlCNSEcsetValueGet(nil)                          ;; 获取支持值的约束列表
ecsets = axlDBGetDesign()->ecsets
ecset = car(ecsets)
axlCNSEcsetValueGet(ecset 'all t)                 ;; 获取所有约束设置，值以MKS字符串返回
axlCNSEcsetValueGet("UPREVED_DEFAULT" 'Maximum_Via_Count)     ;; 获取Maximum_Via_Count的当前设置
axlCNSEcsetValueGet("UPREVED_DEFAULT" "Pad_Soldermask_Alignment" t)  ;; 获取设置作为MKS字符串
```

---

### axlCNSGetDefaultMinLineWidth

**说明**：检索特定子类的最小默认线宽值。

**Original**: Retrieves the minimum default line width value for the specific subclass.

**语法**：
```skill
axlCNSGetDefaultMinLineWidth(t_sublassName)
```

**参数**：
- `t_subclassname`：ETCH或CONDUCTOR类的子类名称。

**返回值**：
- `f_minLineWidthValue`：子类上的最小线宽值（设计单位）。

**示例**：
```skill
axlCNSGetDefaultMinLineWidth("TOP")
=> 0.004
```

---

### axlCNSGetPhysical

**说明**：在其第一种操作模式下，获取给定约束集和层的物理约束值。在第二种操作模式下，它获取层上约束集的所有物理约束作为名称/值对。这反过来可以传递给`axlCNSSetPhysical`。在最终模式下，可以通过向接口传递三个`nil`值来获取所有支持的物理约束列表：`axlCNSGetPhysical(nil nil nil)`

数据类型：除非另有说明，约束以当前设计单位为单位。
- `allow_etch`（布尔值）`t/nil`
- `allow_ts`（符号）NOT_ALLOWED, ANYWHERE, PINS_ONLY, PIN_VIAS_ONLY
- `allow_padconnect`（符号）ALL_ALLOWED, VIAS_PINS_ONLY, VIAS_VIAS_ONLY, NOT_ALLOWED
- `vias`（字符串）冒号分隔的过孔名称列表。过孔不依赖于层，因此仅为TOP返回。顺序对蚀刻编辑工作层模型很重要。使用`axlCnsGetViaList`获取字符串列表形式的过孔列表。
- 当`width_max`, `dp_neck_gap`, `dp_primary_gap`, 和 `necklength_max` 设置为0时，表示不使用此值。

**Original**: In its first operational mode, obtains the value of a physical constraint given a cset and layer. In the second mode of operation, it obtains all physical constraint as name/value pairs for a cset on a layer. In the final mode, a list of all supported physical constraints may be obtained.

**语法**：
```skill
axlCNSGetPhysical(t_cset t_layer s_constraint [g_string])   ⇒ g_value/nil
axlCNSGetPhysical(t_cset t_layer nil [g_string])            ⇒ ll_nameValue/nil
axlCNSGetPhysical(nil nil nil)                             ⇒ ls_cnsTypes
```

**参数**：
- `t_cset`：物理约束集名称。可以使用""表示"DEFAULT"。
- `t_layer`：ETCH层名称（例如，"ETCH/TOP"或"TOP"）。如果为nil，则更改应用于所有层。
- `s_constraint`：约束名称。如果为nil，则返回所有约束的符号/值对集。
- `g_string`：默认情况下，以约束的原生单位返回值。如果`g_string`为`t`，则始终将数据作为字符串返回。

**返回值**：
- `g_value`：约束值（设计单位），`same_net`除外，返回为`t/nil`。
- `ll_nameValue`：物理约束符号和约束值的所有物理名称值对（`s_constraint g_value`）。
- `ls_cnsTypes`：支持的物理约束名称列表。
- `nil`：错误时返回nil（或`allow_etch`）。

**示例**：
```skill
axlCNSGetPhysical("" "TOP" 'width_min)           ;; 获取默认约束集、TOP层的最小线宽
axlCNSGetPhysical("VOLTAGE" "BOTTOM" nil)        ;; 获取VOLTAGE、BOTTOM层的所有物理约束
axlCNSGetPhysical("" "TOP" 'vias)                 ;; 获取默认约束集的过孔列表
axlCNSGetPhysical(nil nil nil)                    ;; 获取支持的物理约束符号
```

**相关函数**：`axlCNSSetPhysical`, `axlCnsList`, `axlSubclassRoute`, `axlCnsGetViaList`

---

### axlCNSGetPinDelayEnabled

**说明**：返回是否启用了引脚延迟。

**Original**: Returns if pin delay is enabled.

**语法**：
```skill
axlCNSGetPinDelayEnabled()
```

**参数**：无

**返回值**：
- `t`：引脚延迟已启用。
- `nil`：引脚延迟未启用。

---

### axlCNSGetPinDelayPVF

**说明**：返回引脚延迟传播速度因子。

**Original**: Returns the pin delay propagation velocity factor.

**语法**：
```skill
axlCNSGetPinDelayPVF()
```

**参数**：无

**返回值**：
- `t_pinDelayPVF`：如果定义了引脚延迟传播速度因子，则作为字符串返回。如果未定义，则返回空字符串。

---

### axlCNSGetSameNet

**说明**：获取同网间距约束集值。文档与`axlCNSGetSpacing`相同。

**Original**: Obtains a same net spacing cset values. Documentation same as axlCNSGetSpacing.

**语法**：
```skill
axlCNSGetSameNet(t_cset t_layer s_constraint [g_string])   ⇒ g_value/nil
axlCNSGetSameNet(t_cset t_layer nil [g_string])            ⇒ ll_nameValue/nil
axlCNSGetSameNet(nil nil nil)                               ⇒ ls_cnsTypes
```

**参数**：
- `t_cset`：同网间距约束集名称。可以使用""表示"DEFAULT"。如果为`nil`，返回所有支持的同网约束符号列表。
- `t_layer`：ETCH层名称（"ETCH/TOP"或"TOP"）。`t_layer`不能为nil或空白字符串。
- `s_constraint`：约束名称。如果为nil，返回指定`t_layer`的所有约束的符号/值对。
- `g_string`：默认情况下以约束的原生单位返回值。如果`g_string`为`t`，则始终将数据作为字符串返回。

**返回值**：
- `g_value`：设计单位中的约束值。
- `ll_nameValue`：间距约束符号和约束值的名称值对（`s_constraint g_value`）。
- `ls_cnsTypes`：支持的同网间距约束名称列表。
- `nil`：错误时返回nil（或`same_net`）。

**示例**：
```skill
axlCNSGetSameNet("" "TOP" 'shape_shape)           ;; 获取默认约束集、TOP层的形状到形状同网间距
axlCNSGetSameNet("25_MIL_SPACE" "BOTTOM" nil)    ;; 获取25_MIL_SPACE、BOTTOM层的所有同网约束
axlCNSGetSameNet("" "BOTTOM" nil t)               ;; 获取默认BOTTOM层的所有同网约束作为字符串
axlCNSGetSameNet(nil nil nil)                     ;; 获取支持的同网约束符号
```

**相关函数**：`axlCNSSetSameNet`, `axlCnsList`, `axlCNSGetSpacing`

---

### axlCNSGetSameNetXtalkEnabled

**说明**：返回是否启用了同网串扰。

**Original**: Returns if Same Net Xtalk is enabled.

**语法**：
```skill
axlCNSGetSameNetXtalkEnabled()
```

**参数**：无

**返回值**：
- `t`：同网串扰已启用。
- `nil`：同网串扰未启用。

---

### axlCNSGetSpacing

**说明**：在其第一种操作模式下，获取给定约束集和层的间距约束值。所有值均以设计单位返回，`same_net`除外，它是布尔值（`t/nil`）。在第二种操作模式下，它获取层上约束集的所有间距约束作为名称/值对。这反过来可以传递给`axlCNSSetSpacing`。在最终模式下，可以通过向此接口传递三个`nil`值来获取支持的间距约束列表：`axlCNSGetSpacing(nil nil nil)`

数据类型：除非另有说明，约束以当前设计单位为单位。`same_net`（布尔值）`t/nil`。`bbvia_gap`不依赖于层。必须使用TOP层名称作为`t_layer`值来获取或设置此值。

**Original**: In its first operational mode, obtains the value of a spacing constraint given a cset and layer. All values are returned in design units, except same_net, which is a boolean (t/nil). In a second mode of operation, it obtains all spacing constraints as name/value pairs for a cset on a layer.

**语法**：
```skill
axlCNSGetSpacing(t_cset t_layer s_constraint [g_string])    ⇒ g_value/nil
axlCNSGetSpacing(t_cset t_layer nil [g_string])             ⇒ ll_nameValue/nil
axlCNSGetSpacing(nil nil nil)                               ⇒ ls_cnsTypes
```

**参数**：
- `t_cset`：间距约束集名称。可以使用""表示"DEFAULT"。
- `t_layer`：ETCH层名称（例如，"ETCH/TOP"或"TOP"）。如果为nil，则更改应用于所有层。
- `s_constraint`：约束名称。如果为nil，则返回所有约束的符号/值对集。
- `g_string`：默认情况下，以约束的原生单位返回值。如果`g_string`为`t`，则始终将数据作为字符串返回。

**返回值**：
- `g_value`：设计单位中的约束值，`same_net`除外，返回为`t/nil`。
- `ll_nameValue`：间距约束符号和约束值的名称值对（`s_constraint g_value`）。
- `ls_cnsTypes`：支持的间距约束名称列表。
- `nil`：错误时返回nil（或`same_net`）。

**示例**：
```skill
axlCNSGetSpacing("" "TOP" 'shape_shape)           ;; 获取默认约束集、TOP层的形状到形状间距
axlCNSGetSpacing("25_MIL_SPACE" "BOTTOM" nil)      ;; 获取25_MIL_SPACE、BOTTOM层的所有间距约束
axlCNSGetSpacing("" "BOTTOM" nil t)                 ;; 获取默认BOTTOM层的所有间距约束作为字符串
axlCNSGetSpacing(nil nil nil)                     ;; 获取支持的间距约束符号
```

**相关函数**：`axlCNSSetSpacing`, `axlCnsList`, `axlSubclassRoute`

---

### axlCNSGetViaZEnabled

**说明**：返回是否启用了Via Z。

**Original**: Returns if Via Z is enabled.

**语法**：
```skill
axlCNSGetViaZEnabled()
```

**参数**：无

**返回值**：
- `t`：Via Z已启用。
- `nil`：Via Z未启用。

---

### axlCNSGetViaZPVF

**说明**：返回Via Z传播速度因子。

**Original**: Returns the via Z propagation velocity factor.

**语法**：
```skill
axlCNSGetViaZPVF()
```

**参数**：无

**返回值**：
- `t_viaZPVF`：如果定义了Via Z传播速度因子，则作为字符串返回。如果未定义，则返回空字符串。

---

### axlCNSPhysicalModeGet

**说明**：获取当前物理DRC模式。模式确定特定约束是开启还是关闭。这些模式适用于整个电路板。要确定当前支持的物理模式，请执行`axlCNSPhysicalModeGet(nil)`。物理模式集可能是物理值值的子集，因为实现可能将某些值关联到主模式下。例如，`via_list`不是约束，差分对模式在ecset域下。

未来版本可能会添加或删除约束检查。axl接口确实保证此接口返回的检查将在版本之间保持恒定。

**Original**: This fetches the current physical DRC mode(s). Modes determine if a particular constraint is on or off. These modes apply to the entire board. The physical mode set may be a subset of physical values since the implementation may associate certain values under a master mode.

**语法**：
```skill
axlCNSPhysicalModeGet(nil)                    ⇒ ls_constraints
axlCNSPhysicalModeGet('all)                    ⇒ lls_constraintNModes
axlCNSPhysicalModeGet(s_name/t_name)          ⇒ s_mode/nil
axlCNSPhysicalModeGet(s_name/t_name 'print)   ⇒ t_name/nil
```

**参数**：
- `nil`：返回间距域中的所有模式
- `'all`：返回所有检查和当前模式
- `s_name`：检查的符号名称。
- `t_name`：检查的字符串名称。
- `'print`：可打印约束名称选项。

**返回值**：
- `ls_names`：检查列表（`s_name` ...）
- `lls_names`：检查及其模式列表（(`s_name s_mode`) ...）
- `s_mode`：模式 `'on` 或 `'off`
- `t_name`：可打印约束名称

**示例**：
```skill
axlCNSPhysicalModeGet(nil)              ;; 获取物理约束的当前列表
axlCNSPhysicalModeGet('all)              ;; 获取所有物理约束的设置列表
axlCNSPhysicalModeGet('width_max)        ;; 获取最大线宽的模式
axlCNSPhysicalModeGet("allow_ts")        ;; 使用字符串获取allow Ts的当前设置
```

**相关函数**：`axlCNSPhysicalModeSet`, `axlCNSGetPhysical`

---

### axlCNSIsCsetLocked

**说明**：返回约束集是否被锁定。请参阅`axlCNSIsLockedDomain`中的讨论。锁定的约束集具有以下特征：不能编辑；具有锁定整个域的效果。

**Original**: This returns if a cset is locked. A locked cset has the following characteristics: Cannot be edited; Has the effect of locking the entire domain.

**语法**：
```skill
axlCNSIsCsetLocked(g_domain t_csetName)
```

**参数**：
- `g_domain`：约束集域；`'physical`, `'spacing`, `'sameNet`, `'electrical`
- `t_csetName`：约束集名称

**返回值**：
- `t`：如果约束集已删除；`nil`：如果约束集未删除，因为被锁定或不是约束集

**示例**：
```skill
axlCNSIsCsetLocked('electrical "DEFAULT")
```

**相关函数**：`axlCNSDesignModeSet`, `axlCNSIsLockedDomain`

---

### axlCNSIsLockedDomain

**说明**：用于检查约束域是否被锁定。锁定的约束域具有以下特征：约束集不能编辑，但可以添加新的约束集；任何对象（例如，网络）级别的属性覆盖都被忽略。

**注意**：间距和同网域作为单个域锁定。锁定通常通过techfile完成。在techfile中，您可以锁定单个约束集。如果一个约束集被锁定，Allegro PCB Editor从DRC角度将整个域视为锁定。当域被锁定时，任何对象级别的约束属性覆盖都被忽略。如果约束集被锁定，则不能修改或删除。使用`axlCnsList(nil)`获取所有域列表。

**Original**: Used to check if the constraint domain is locked. A locked constraint domain has the following characteristics: csets cannot be edited, although new csets can be added; any object level property overrides are ignored. The spacing and sameNet domains are locked as a single domain.

**语法**：
```skill
axlCNSIsLockedDomain(g_domain)
```

**参数**：
- `g_domain`：约束集域；`'physical`, `'spacing`, `'sameNet`, `'electrical`

**返回值**：
- `t`：如果约束域被锁定。
- `nil`：域未锁定。

**示例**：
```skill
axlCNSIsLockedDomain('electrical)     ;; 检查电气域是否锁定
lockedDomains = setof(x axlCnsList(nil) axlCNSIsLockedDomain(x))  ;; 查找锁定的域列表
```

**相关函数**：`axlCNSCsetLock`, `axlCNSIsCsetLocked`, `axlCNSLockDomain`, `axlCNSDesignModeSet`, `axlCnsList`

---

### axlCNSLockDomain

**说明**：锁定或解锁约束域。请参阅`axlCNSIsLockedDomain`中的讨论。更改域上的锁定可能需要相当长的时间，因为该域的DRC状态需要更新。在间距域中，动态形状也需要更新。如果进行其他更改，应考虑使用`axlDBCloak`隐藏整个过程。此API已使用隐藏。

**Original**: This command locks or unlocks a constraint domain. Changing the lock on a domain can take a considerable amount of time since DRC status for that domain needs to be updated. In the spacing domain dynamic shapes also need to be updated. This API already uses cloaking.

**语法**：
```skill
axlCNSLockDomain(g_domain g_mode)
```

**参数**：
- `g_domain`：约束集域；`'physical`, `'spacing`, `'sameNet`, `'electrical`
- `g_mode`：可以是`t`（锁定）或`nil`（解锁）

**返回值**：
- 返回`t`如果锁定状态已更新；`nil`表示错误。

**示例**：
```skill
axlCNSLockDomain('spacing t)     ;; 锁定间距和同网间距域
```

**相关函数**：`axlCNSIsLockedDomain`

---

### axlCNSOptions

**说明**：查询和/或设置约束选项的值。通常，设置选项会将DRC标记为过期。由调用代码更新DRC。当前支持的项：

| 名称 | 值 | 可设置？ | 说明 | 等效 | 副作用 |
|------|-----|---------|------|------|--------|
| `holeAlways` | `t` 到 `nil` | 是 | 报告是否应始终进行孔检查。默认是仅在抑制焊盘时进行孔检查。 | 分析模式 - 间距选项 | 无 |

**Original**: Inquires and/or sets the value for constraint options. Typically, setting options will mark DRC out of date. It is calling code to update DRC. Items currently supported: Name holeAlways, Value t to nil, Set? Yes, Description Reports if hole check should always be done.

**语法**：
```skill
axlCNSOptions(s_name [g_value])
```

**参数**：
- `s_name`：控件符号名称。`nil`返回所有可能的名称。
- `g_value`：可选符号值设置。通常是`t`或`nil`。

**返回值**：见上文。

**示例**：
```skill
old = axlDBControl('holeAlways, nil)
```

**相关函数**：`axlCNSDesignModeSet`, `axlDBControl`

---

### axlCNSPhysicalModeSet

**说明**：设置物理约束区域中检查的当前DRC模式（开启/关闭）。这些模式是全局的。要确定当前支持的约束模式，请执行`axlCNSPhysicalModeGet(nil)`。支持多个接口。可以设置所有检查（`'all`）、单个检查（`t_name`）、将检查列表设置为相同模式，以及通过列表设置检查集：

出于性能原因，应将所有更新放在单个调用中，或者使用map API包装单个更改（请参阅`axlCNSMapUpdate`）。未来版本可能会添加或删除约束检查。axl接口确实保证此接口返回的检查将在版本之间保持恒定。

**Original**: This sets the current DRC modes (on/off) for checks in the area of physical constraints. These modes are global. For performance reasons, you should either do all your updates in a single call or wrap individual changes in the map API (see axlCNSMapUpdate).

**语法**：
```skill
axlCNSPhysicalModeSet(t_name/s_name t_mode/s_mode)           ⇒ t/nil
axlCNSPhysicalModeSet('all t_mode/smode)                     ⇒ t/nil
axlCNSPhysicalModeSet(l_constraintNModes t_mode/smode)      ⇒ t/nil
axlCNSPhysicalModeSet(ll_constraintNModes)                  ⇒ t/nil
```

**参数**：
- `s_name`：检查的符号名称。
- `t_name`：检查的字符串名称。
- `s_mode`：模式设置；可以是`'on` 或 `'off`。
- `t_mode`：字符串模式设置 `"on` 或 `"off"`。
- `'all`：为给定级别的Allegro设置所有检查。

**返回值**：
- 如果成功返回`t`，失败返回`nil`。

**示例**：
```skill
axlCNSPhysicalModeSet('all 'off)                    ;; 关闭所有约束
axlCNSPhysicalModeSet('width_max 'on)               ;; 开启最大线宽
axlCNSPhysicalModeSet('(bbvia_stagger_max bbvia_stagger_min) 'on)  ;; 开启两个约束
axlCNSPhysicalModeSet('((width_max off) (allow_etch 'on)) )        ;; 将各种约束设置为不同模式
```

**相关函数**：`axlCNSPhysicalModeGet`, `axlCNSGetPhysical`, `axlCNSMapUpdate`

---

### axlCNSSameNetModeGet

**说明**：与`axlCNSSpacingModeGet`相同。

**Original**: Same as axlCNSSpacingModeGet.

**语法**：
```skill
axlCNSSameNetModeGet(nil)                    ⇒ ls_constraints
axlCNSSameNetModeGet('all)                   ⇒ lls_constraintNModes
axlCNSSameNetModeGet(s_name/t_name)          ⇒ s_mode/nil
axlCNSSameNetModeGet(s_name/t_name 'print)  ⇒ t_name/nil
```

**参数**：
- `nil`：返回同网间距域中的所有模式
- `'all`：返回所有检查和当前模式
- `s_name`：检查的符号名称。
- `t_name`：检查的字符串名称。
- `'print`：可打印约束名称选项

**返回值**：
- `ls_names`：检查列表（`s_name` ...）
- `lls_names`：检查及其模式列表（(`s_name s_mode`) ...）
- `s_mode`：模式 `'on` 或 `'off`
- `t_name`：可打印约束名称

**示例**：
```skill
axlCNSSameNetModeGet(nil)              ;; 获取同网间距约束的当前列表
axlCNSSameNetModeGet('all)              ;; 获取所有同网间距约束的设置列表
axlCNSSameNetModeGet('line_line)        ;; 获取线到线的当前设置
axlCNSSameNetModeGet("line_shape")      ;; 使用字符串获取线到形状的当前设置
```

**相关函数**：`axlCNSSameNetModeSet`, `axlCNSGetSameNet`, `axlCNSSpacingModeGet`

---

### axlCNSSameNetModeSet

**说明**：与`axlCNSSpacingModeSet`相同。

**Original**: Same as axlCNSSpacingModeSet.

**语法**：
```skill
axlCNSSameNetModeSet(t_name/s_name t_mode/s_mode)           ⇒ t/nil
axlCNSSameNetModeSet('all t_mode/smode)                      ⇒ t/nil
axlCNSSameNetModeSet(l_constraintNModes t_mode/smode)        ⇒ t/nil
axlCNSSameNetModeSet(ll_constraintNModes)                   ⇒ t/nil
```

**参数**：
- `s_name`：检查的符号名称。
- `t_name`：检查的字符串名称。
- `s_mode`：模式设置；可以是`'on` 或 `'off`。
- `t_mode`：字符串模式设置 `"on"` 或 `"off"`。
- `'all`：为给定级别的Allegro设置所有检查。

**返回值**：
- 如果成功返回`t`，失败返回`nil`。

**示例**：
```skill
axlCNSSameNetModeSet('all 'off)              ;; 关闭所有同网间距约束
axlCNSSameNetModeSet('line_line 'on)         ;; 开启线到线检查
axlCNSSameNetModeSet('(line_shape thrupin_line) 'on)  ;; 开启两个约束
axlCNSSameNetModeSet('((line_line off) (thrupin_shape on)) )  ;; 将多个约束设置为不同模式
```

**相关函数**：`axlCNSSameNetModeGet`, `axlCNSGetSameNet`, `axlCNSSpacingModeSet`

---

### axlCNSSetPhysical

**说明**：允许更新物理约束值。通过在适当参数传递`nil`，可以更改所有约束集和所有层的值。

数据类型：请参阅`axlCNSGetPhysical`了解每个约束的数据类型。

允许的设计单位：
- 数字（整数或浮点数），单位为当前设计单位。不得超过设计的精度。
- 无单位字符串，精度不能超过数据库精度。
- 带单位的字符串，数据转换为当前设计单位。

允许的数据值：
- 布尔值：使用`t/nil`或`"true"`/`"false"`。
- 符号：使用符号名称或其字符串。

为获得最佳性能，在调用多个axlCNS接口更新约束值时，请将它们包装在`axlCnsMap`接口中，如下所示：

```skill
axlCNSMapClear()
axlCNSSetPhysical(nil nil 'width_min 5)
axlCNSSetPhysical("" nil 'allow_padconnect 'VIAS_PINS_ONLY)
...
axlCNSMapUpdate()
```

单个更改调用不需要此操作。有关物理约束列表，请参阅`axlCNSGetPhysical`。如果添加/删除单个过孔，可能会发现使用`axlCnsAddVia`和`axlCnsDeleteVia`更容易。

`Same_net`行为将在16.2中更改。这不会更改覆盖值。例如，您可以在所有约束集中设置width_min值，但如果您将其作为覆盖应用于网络或约束区域，则仍将对这些项使用它。

**Original**: Allows updating physical constraint values. By passing nil at the appropriate argument, values for all csets and all layers may be changed. For best performance, when calling multiple axlCNS interfaces to update constraint values, wrap them in the axlCnsMap interfaces.

**语法**：
```skill
axlCNSSetPhysical(t_cset/nil t_layer/nil s_constraint g_value)          ⇒ t/nil
axlCNSSetPhysical(t_cset/nil t_layer/nil ll_constraintValues nil)       ⇒ t/nil
```

**参数**：
- `t_cset`：约束集名称。可以使用""表示DEFAULT约束集。使用`nil`将更改应用于所有约束集。
- `t_layer`：ETCH层名称（例如，"ETCH/TOP"或"TOP"）。如果为nil，则更改应用于所有层。
- `s_constraint`：要更改的约束符号。使用`axlCNSGetPhysical(nil nil nil)`获取允许值列表。
- `g_value`：要更新的值。有关数据类型，请参阅上面的数据类型。
- `ll_constraintValues`：可以通过将列表的列表作为第三个参数传递来更新多个值。`'((s_constraint g_value) ... )`

**返回值**：
- `t`：成功。
- `nil`：发生错误时。错误原因：ECset名称不存在；层不存在；约束不存在；约束值非法；或约束集已锁定。

**示例**：
```skill
axlCNSSetPhysical(nil nil 'width_min 5)                 ;; 设置所有约束和层的最小线宽
axlCNSSetPhysical("" nil 'allow_etch t)                 ;; 在默认约束集的所有层上设置allow_etch
axlCNSSetPhysical("VOLTAGE" "top" 'allow_ts 'NOT_ALLOWED)  ;; 在VOLTAGE约束集的顶层不允许T型连接
axlCNSSetPhysical("VOLTAGE" "top" 'allow_ts "NOT_ALLOWED")   ;; 使用相同的值
```

**相关函数**：`axlCNSGetPhysical`, `axlCNSMapClear`, `axlCNSMapUpdate`, `axlCnsAddVia`, `axlCnsDeleteVia`

---

### axlCNSSetSpacing

**说明**：允许更新间距约束值。通过在适当参数传递`nil`，可以更改所有约束集和所有层的值。

数据类型：请参阅`axlCNSGetSpacing`了解每个约束的数据类型。

允许的设计单位：
- 数字（整数或浮点数），单位为当前设计单位。不得超过设计的精度。
- 无单位字符串，精度不能超过数据库精度。
- 带单位的字符串，数据转换为当前设计单位。

允许的数据值：
- 布尔值：使用`t/nil`或`"true"`/`"false"`。

为获得最佳性能，在调用多个`axlCNS`接口更新约束值时，请将它们包装在`axlCnsMap`接口中，如下所示：

```skill
axlCNSMapClear()
axlCNSSetSpacing(nil nil 'line_shape 10.0)
axlCNSSetSpacing("" nil 'line_line 5)
...
axlCNSMapUpdate()
```

单个更改调用不需要此操作。有关当前间距约束列表，请参阅`axlCNSGetSpacing`。`Same_net`约束已移动到同网间距域。作为字符串发送的值时，小数位数不能超过当前数据库精度，否则更改将被拒绝。这**不会**更改覆盖值。例如，您可以更改所有约束集中的线到线值，但如果您已将网络或约束区域覆盖应用于它，则仍将对这些项使用它。

**Original**: Allows updating spacing constraint values. For best performance, when calling multiple axlCNS interfaces to update constraint values, wrap them in the axlCnsMap interfaces. This does NOT change override values.

**语法**：
```skill
axlCNSSetSpacing(t_cset/nil t_layer/nil s_constraint g_value)          ⇒ t/nil
axlCNSSetSpacing(t_cset/nil t_layer/nil ll_constraintValues nil)       ⇒ t/nil
```

**参数**：
- `t_cset`：约束集名称。可以使用""表示DEFAULT约束集。使用`nil`将更改应用于所有约束集。
- `t_layer`：ETCH层名称（例如，"ETCH/TOP"或"TOP"）。如果为nil，则更改应用于所有层。
- `s_constraint`：要更改的约束符号。使用`axlCNSGetPhysical(nil nil nil)`获取允许值列表。
- `g_value`：要更新的值。有关数据类型，请参阅上面的数据类型。
- `ll_constraintValues`：可以通过将列表的列表作为第三个参数传递来更新多个值。`'((s_constraint g_value) ... )`

**返回值**：
- `t`：成功。
- `nil`：指示错误。错误原因：ECset名称不存在；层不存在；约束不存在；约束值非法；或约束集已锁定。

**示例**：
```skill
axlCNSSetSpacing(nil nil 'line_shape 5)                  ;; 设置所有约束集、所有层的线到形状间距
axlCNSSetSpacing("" nil 'line_line 5)                    ;; 在DEFAULT约束集、所有层设置线到线间距为5
axlCNSSetSpacing("25_MIL_SPACE" "top" 'line_line 5)      ;; 在25_MIL_SPACE约束集、顶层设置线到线间距
```

**相关函数**：`axlCNSGetSpacing`, `axlCNSMapClear`, `axlCNSMapUpdate`

---

### axlCNSSetPinDelayEnabled

**说明**：启用或禁用引脚延迟。

**Original**: Enables or disables Pin Delay.

**语法**：
```skill
axlCNSSetPinDelayEnabled(g_value)
```

**参数**：
- `g_value`：`t`或`nil`指示引脚延迟是否开启或关闭。

**返回值**：
- `t`

---

### axlCNSSetPinDelayPVF

**说明**：设置引脚延迟传播速度的值。

**Original**: Sets a value for pin delay propagation velocity.

**语法**：
```skill
axlCNSSetPinDelayPVF(g_value)
```

**参数**：
- `g_value`：定义新引脚延迟传播速度因子的字符串。`nil`值表示要删除该值。

**返回值**：
- `t`：无错误
- `nil`：检测到错误

---

### axlCNSSetSameNet

**说明**：更新同网间距约束集值。文档与`axlCNSSetSpacing`相同。

**Original**: Updates the same net spacing cset value. Documentation same as axlCNSSetSpacing.

**语法**：
```skill
axlCNSSetSameNet(t_cset/nil t_layer/nil s_constraint g_value)          ⇒ t/nil
axlCNSSetSameNet(t_cset/nil t_layer/nil ll_constraintValues nil)     ⇒ t/nil
```

**参数**：
- `t_cset`：约束集名称。可以使用""表示DEFAULT约束集。使用`nil`将更改应用于所有约束集。
- `t_layer`：ETCH层名称（"ETCH/TOP"或"TOP"）。如果为nil，则更改应用于所有层。
- `s_constraint`：要更改的约束符号。使用`axlCNSGetSameNet(nil nil nil)`获取允许值列表。
- `g_value`：要更新的值。有关数据类型，请参阅上面的"数据类型"。
- `ll_constraintValues`：可以通过将列表的列表作为第三个参数传递来更新多个值。`'((s_constraint g_value) ... )`

**返回值**：
- `t`：如果成功
- `nil`：如果发生以下任何错误：ecset名称不存在；层不存在；约束不存在；约束值非法；约束集已锁定。

**示例**：
```skill
axlCNSSetSameNet(nil nil 'line_shape 5)             ;; 设置所有约束集、所有层的线到形状同网间距
axlCNSSetSameNet("" nil 'line_line 5)               ;; 在DEFAULT约束集、所有层设置线到线同网间距为5
axlCNSSetSameNet("25_MIL_SPACE" "top" 'line_line 5)  ;; 在25_MIL_SPACE约束集、顶层设置线到线同网间距
```

**相关函数**：`axlCNSGetSameNet`, `axlCNSSetSpacing`

---

### axlCNSSetSameNetXtalkEnabled

**说明**：启用或禁用同网串扰。

**Original**: Enables or disables Same Net Xtalk.

**语法**：
```skill
axlCNSSetSameNetXtalkEnabled(g_value)
```

**参数**：
- `g_value`：`t`或`nil`指示同网串扰是否开启或关闭。

**返回值**：
- `t`

---

### axlCNSSetViaZEnabled

**说明**：启用或禁用Via Z。

**Original**: Enables or disables Via Z.

**语法**：
```skill
axlCNSSetViaZEnabled(g_value)
```

**参数**：
- `g_value`：`t`或`nil`指示Via Z是否开启或关闭。

**返回值**：
- `t`

---

### axlCNSSetViaZPVF

**说明**：设置Via Z传播速度因子的值。

**Original**: Sets a value for Via Z propagation velocity factor.

**语法**：
```skill
axlCNSSetViaZPVF(g_value)
```

**参数**：
- `g_value`：定义新Via Z传播速度因子的字符串。`nil`值表示要删除该值。

**返回值**：
- `t`：无错误
- `nil`：检测到错误

---

### axlCNSSpacingMax

**说明**：返回设计中的最大间距。这可以是整个设计的最坏情况间距，或基于对象过滤的间距。最大间距从间距、同网和装配（APD+）域中的所有间距计算。检查的状态（开启/关闭）被忽略（这与最小间距API不同）。

**Original**: Returns maximum spacing in design. This can be worst case spacing of entire design or base upon the object filtering. Maximum spacing is calculated from all spacings in the domains of spacing, same net, and assembly (APD+). The state of the check (on/off) is ignored.

**语法**：
```skill
axlCNSSpacingMax([s_spacingType] [t_layer])
```

**参数**：
- `s_spacingType`：表示间距约束类型的符号。支持的值：`'line`, `'shape`, `'via`, `'pin`
- `t_subclassname`：ETCH或CONDUCTOR类的子类名称，或`nil`表示所有层

**返回值**：
- `f_maxSpacing`：整个设计或子过滤设置的最大间距。

**示例**：
```skill
axlCNSSpacingMax(nil)              ;; 获取整个设计的最大间距
axlCNSSpacingMax('line "TOP")       ;; 获取TOP层线的最大间距
axlCNSSpacingMax('line nil)        ;; 获取所有层线的最大间距
```

**相关函数**：`axlCNSSpacingMin`

---

### axlCNSSpacingMin

**说明**：返回设计中的最小间距值。这可以是整个设计的最小间距，或基于对象过滤的间距。最大间距从间距、同网和装配（APD+）域中的间距计算。间距检查必须启用（开启）才能可能作为最小值包含。

**Original**: Returns minimum spacing value in the design. This can be the minimum spacing of entire design or based upon the object filtering. Maximum spacing is calculated from spacings in the domains of spacing, same net, and assembly (APD+). The spacing check must be enabled (on) to be possibly included as a minimum.

**语法**：
```skill
axlCNSSpacingMin([s_spacingType] [t_layer])
```

**参数**：
- `s_spacingType`：表示间距约束类型的符号。支持的值：`'line`, `'shape`, `'via`, `'pin`
- `t_subclassname`：ETCH或CONDUCTOR类的子类名称，或`nil`表示所有层

**返回值**：
- `f_minSpacing`：整个设计或子过滤设置的最小间距。

**示例**：请参阅`axlCNSSpacingMax`的示例部分。

**相关函数**：`axlCNSSpacingMax`

---

### axlCNSSpacingModeGet

**说明**：获取当前间距DRC模式。模式确定特定约束是开启还是关闭。这些模式适用于整个电路板。要确定当前支持的间距模式，请执行`axlCNSSpacingModeGet(nil)`。间距模式集可能是间距值的子集，因为实现可能将某些值关联到主模式下。

未来版本可能会添加或删除约束检查。axl接口确实保证此接口返回的检查将在版本之间保持恒定。

**Original**: This fetches the current spacing DRC mode(s). Modes determine if a particular constraint is on or off. These modes apply to the entire board. Future releases may add or subtract constraint checks. The axl interface does guarantee the checks returned by this interface will remain constant from release to release.

**语法**：
```skill
axlCNSSpacingModeGet(nil)                    ⇒ ls_constraints
axlCNSSpacingModeGet('all)                   ⇒ lls_constraintNModes
axlCNSSpacingModeGet(s_name/t_name)          ⇒ s_mode/nil
```

**参数**：
- `nil`：返回间距域中的所有模式
- `'all`：返回所有检查和当前模式
- `s_name`：检查的符号名称。
- `t_name`：检查的字符串名称。

**返回值**：
- `ls_names`：检查列表（`s_name` ...）
- `lls_names`：检查及其模式列表（(`s_name s_mode`) ...）
- `s_mode`：模式 `'on` 或 `'off`

**示例**：
```skill
axlCNSSpacingModeGet(nil)              ;; 获取设计约束的当前列表
axlCNSSpacingModeGet('all)              ;; 获取所有设计约束的设置列表
axlCNSSpacingModeGet('line_line)        ;; 获取线到线的当前设置
axlCNSSpacingModeGet("line_shape")     ;; 使用字符串获取线到形状的当前设置
```

**相关函数**：`axlCNSSpacingModeSet`, `axlCNSGetSpacing`

---

### axlCNSSpacingModeSet

**说明**：设置间距约束区域中检查的当前DRC模式（开启/关闭）。这些模式是全局的。要确定当前支持的约束模式，请执行`axlCNSSpacingModeGet(nil)`。支持多个接口。可以设置所有检查（`'all`）、单个检查（`t_name`）、将检查列表设置为相同模式，以及通过列表设置检查集：

出于性能原因，应将所有更新放在单个调用中，或者使用map API包装单个更改（请参阅`axlCNSMapUpdate`）。未来版本可能会添加或删除约束检查。axl接口确实保证此接口返回的检查将在版本之间保持恒定。

**Original**: This sets the current DRC modes (on/off) for checks in the area of spacing constraints. These modes are global. For performance reasons, you should either do all your updates in a single call or wrap individual changes in the map API (see axlCNSMapUpdate).

**语法**：
```skill
axlCNSSpacingModeSet(t_name/s_name t_mode/s_mode)           ⇒ t/nil
axlCNSSpacingModeSet('all t_mode/smode)                     ⇒ t/nil
axlCNSSpacingModeSet(l_constraintNModes t_mode/smode)      ⇒ t/nil
axlCNSSpacingModeSet(ll_constraintNModes)                 ⇒ t/nil
```

**参数**：
- `s_name`：检查的符号名称。
- `t_name`：检查的字符串名称。
- `s_mode`：模式设置；可以是`'on` 或 `'off`。
- `t_mode`：字符串模式设置 `"on"` 或 `"off"`。
- `'all`：为给定级别的Allegro设置所有检查。

**返回值**：
- 如果成功返回`t`，失败返回`nil`。

**示例**：
```skill
axlCNSSpacingModeSet('all 'off)                    ;; 关闭所有间距约束
axlCNSSpacingModeSet('line_line 'on)               ;; 开启线到线检查
axlCNSSpacingModeSet('(line_shape thrupin_line) 'on)  ;; 开启两个约束
axlCNSSpacingModeSet('((line_line off) (thrupin_shape on)) )  ;; 将多个约束设置为不同模式
```

**相关函数**：`axlCNSSpacingModeGet`, `axlCNSMapUpdate`

---

### axlCnsPurgeAll

**说明**：删除所有未使用的约束对象和约束集。处理所有网络类、区域、物理约束集和间距约束集。删除所有空网络类和区域。

**Original**: Removes all unused constraint objects and constraint sets. Process all netclasses, regions, physical constraint sets and spacing constraint sets. Deletes all empty netclasses and regions.

**语法**：
```skill
axlCnsPurgeAll()
```

**参数**：无

**返回值**：
- 删除的项目计数。

**相关函数**：`axlCnsPurgeCsets`

---

### axlCnsPurgeCsets

**说明**：处理指定域的所有约束集，并删除没有引用的约束集。这些函数旨在帮助迁移设计以利用16.0约束模型。迁移设计时不必使用这些函数。在使用这些函数之前，需要评估您的约束使用情况。

**Original**: Process all constraint sets of the specified domain and delete those without references. This class of functions is design to help migrate designs to take advantage of the 16.0 constraint model.

**语法**：
```skill
axlCnsPurgeCsets(list l_type)
```

**参数**：
- `l_type`：感兴趣的域 `'physical` 或 `'spacing`

**返回值**：
- 删除的约束集计数。

**示例**：
```skill
axlCnsPurgeCsets('physical)
axlCnsPurgeCsets('spacing)
```

**相关函数**：`axlCnsPurgeObjects`, `axlCnsPurgeAll`, `axlCnsDeleteClassClassObjects`, `axlCnsDeleteRegionClassClassObjects`, `axlCnsDeleteRegionClassObjects`

---

### axlCnsPurgeObjects

**说明**：处理数据库并删除所有没有成员的成员组类型对象；没有网络的网络类，或没有形状的区域。

**Original**: Process the database and delete all group_type objects that have no members; a netclass with no nets, or a region with no shapes.

**语法**：
```skill
axlCnsPurgeObjects(list l_type)
```

**参数**：
- `l_type`：感兴趣的域 `'physical` 或 `'spacing`。实际上是`'netclass` 或 `'region`。

**返回值**：
- 删除的对象计数。

**示例**：
```skill
axlCnsPurgeObjects('netclass)
axlCnsPurgeObjects('region)
```

**相关函数**：`axlCnsPurgeCsets`

---

### axlViaZLength

**说明**：返回从layer1到layer2的过孔长度。层名称可以作为ETCH子类名称（TOP）或正式的SKILL层名称（"ETCH/TOP"）给出。这是ViaZ选项用于多个DRC检查的长度。默认情况下，在计算中不使用layer1或layer2的厚度。

**Original**: Returns the via length from layer1 to layer2. The layer names can either be given as the ETCH subclass name (TOP) or given as the formal SKILL layer name ("ETCH/TOP"). This is the length used in the ViaZ option to several DRC checks. By default, does not use the thickness of the layer1 or layer2 in its calculation.

**语法**：
```skill
axlViaZLength(t_layer1 t_layer2 [g_inclusion])
```

**参数**：
- `t_layer1`：起始层名称
- `t_layer2`：结束层名称
- `g_inclusion`：计算中的可选包含：
  - `'first`：包含t_layer1的厚度
  - `'second`：包含t_layer2的厚度
  - `'both`：包含两个层
  - `nil`：不包含任何一个

**返回值**：
- `f_length`：设计单位中的过孔长度

**示例**：
```skill
axlViaZLength("TOP" "BOTTOM")     ;; 获取从顶层到底层的长度（不包括顶层和底层厚度）
```

**相关函数**：`axlCNSGetViaZPVF`

---

### axlNetEcsetValueGet

**说明**：返回已分配给给定网络的特定电气约束的值。可以访问固定约束和用户定义的约束。这不会返回分配给引脚对的约束的"展平"网络视图。使用`axlCnsNetFlattened`获取此约束视图。

如果要从同一网络请求多个约束，使用网络的dbid作为第一个参数而不是使用网络名称会更快。

**Original**: Returns the value of a specific electrical constraint that has been assigned to a given net. Both fixed and user defined constraints may be accessed. This will not return a "flattened" net view of constraints applied to pinpairs. Use axlCnsNetFlattened to obtain this constraint view.

**语法**：
```skill
axlNetEcsetValueGet(o_itemDbid/t_netName t_cnsName/s_name)
```

**参数**：
- `o_itemDbid`：分配给网络或Xnet的任何项的dbid。
- `t_cnsName`：要获取的约束的属性名称。这可以是固定约束或用户定义的约束。
- `s_name`：DRC检查的符号名称（`axlCNSEcsetModeGet(nil)`返回的值）。这些名称可能与属性名称不完全匹配。ECset中用户定义属性的名称不存在。

**返回值**：
- `t_cnsValue`：作为字符串返回的值。
- `nil`：网络未定义值。

**示例**：
```skill
;; 网络是ECset（电气约束集）的一部分，具有MAX_EXPOSED_LENGTH约束：
net = car(axlSelectByName("NET" "NET2"))
rule = axlNetEcsetValueGet(net "MAX_EXPOSED_LENGTH")
;; 网络对MAX_VIA_COUNT有覆盖约束：
rule = axlNetEcsetValueGet("NET2" "MAX_VIA_COUNT")
;; 与上述示例相同，但使用DRC检查名称：
rule = axlNetEcsetValueGet("NET2" 'Maximum_Via_Count)
```

**相关函数**：`axlCnsNetFlattened`

---

### axlCNSEcsetValueSet

**说明**：设置ECset DRC的值。要确定支持的值列表，请使用：`axlCNSEcsetValueGet(nil)`

您可以设置单个值或值列表。传递`nil`或空字符串" "作为值会从ECset中删除约束。

出于性能原因，更改值不会调用DRC。您必须手动调用DRC。请参阅`axlCNSMapUpdate`了解可用于标记更改的接口集，以便执行较少的DRC更新。约束检查可能因版本而异。

**Original**: Sets the value of the ECset DRC. To determine the list of supported values, use: axlCNSEcsetValueGet(nil). Passing a nil or empty string " " as a value deletes the constraint from the ECset. For performance reasons, changing a value does not invoke DRC. You must manually invoke DRC.

**语法**：
```skill
axlCNSEcsetValueSet(o_ecsetDbid/t_ecsetName t_name/s_name f_value/t_value)  ⇒ t/nil
axlCNSEcsetValueSet(o_ecsetDbid/t_ecsetName ll_constraintNValues)            ⇒ t/nil
```

**参数**：
- `o_ecsetDbid`：ECset的dbid。
- `t_ecsetName`：ECset的名称。
- `s_name`：约束的符号名称。
- `t_name`：约束的字符串名称。
- `f_value`：提供的浮点值假定为约束的默认用户单位。值可能舍入。
- `t_value`：如果作为带MKS类型的字符串给定，则值转换为约束的当前用户单位。可能会产生舍入。

**返回值**：
- `t`：设置ECset DRC的值。
- `nil`：由于参数不正确而未能设置ECset DRC的值。

**示例**：
```skill
axlCNSEcsetValueSet("UPREVED_DEFAULT" 'Impedance "ALL:ALL:100.0:2")
axlCNSEcsetValueSet("UPREVED_DEFAULT" '((Impedance "ALL:ALL:100.0:2") (Maximum_Via_Count 5)))
```

---

### axlCnsGetViaList

**说明**：返回物理约束集中定义的焊盘。如果提供了约束集名称，则仅返回该约束集分配的过孔。否则，函数返回所有约束集的过孔。当使用`nil`选项时，相同的过孔可能会出现多次。如果给定约束集名称，列表中的过孔顺序会影响蚀刻编辑工作层模型的过孔选择行为（有关详细信息，请参阅此文档）。

注意，过孔列表中的焊盘可能当前未加载到数据库中，或可能不存在于磁盘上（无法找到的过孔在cns物理集对话框中由"*"指示器显示）。

**Original**: Returns padstacks defined in a physical constraint set. If the cset name is provided then returns only vias assigned for that cset. Otherwise the function returns vias for all csets. The same vias may appear more than once when using the nil option. Note that padstacks in via list may not currently be loaded in database or may not exist on disk.

**语法**：
```skill
axlCnsGetViaList(t_csetName)
```

**参数**：
- `t_csetName`：物理约束集名称。`nil`处理所有约束集。

**返回值**：
- `lt_padstacks`：约束集或所有约束集中定义的焊盘列表。
- `nil`：如果未找到焊盘或约束集未找到。

**示例**：
```skill
axlCnsGetViaList("DEFAULT")     ;; 报告默认物理约束集中的过孔
axlCnsGetViaList(nil)           ;; 报告所有物理约束集中的过孔
```

**相关函数**：`axlCnsAddVia`, `axlCnsDeleteVia`, `axlCNSGetPhysical`

---

### axlGetAllViaList

**说明**：返回设计中包含在过孔列表中的所有焊盘列表。这是所有约束集的所有过孔列表的汇编。可选地，它提供来自网络VIA_LIST属性的焊盘。焊盘dbid的顺序取决于约束集、VIA_LIST属性和关联过孔列表的顺序。此接口将导致过孔焊盘被加载到设计中（如果尚未加载）。

**Original**: Returns a list of all padstacks included in via lists in the design. This is a compilation of all via lists from all constraint sets. The order of padstack dbids depends on the order of constraint sets, VIA_LIST properties and the associated via lists. This interface will result in the via padstacks being loaded into the design if they are not already loaded.

**语法**：
```skill
axlGetAllViaList([g_attrVias])
```

**参数**：
- `[g_attrVias]`：可选参数，添加未包含在约束集中但某些网络VIA_LIST属性中提供的焊盘。

**返回值**：
- `lo_padstack_dbid`：焊盘dbid列表。
- `nil`：设计有过空列表。

---

### axlDRCUpdate

**说明**：对整个设计执行DRC检查。有两种返回选项，由`g_mode`选项控制：
- `nil`：交互式（开启）检查；类似于`drcupdate`命令
- `t`：开启和批处理检查；类似于`dbdoctor drc`选项

如果禁用，将启用在线DRC。遵守当前DRC模式设置。批处理模式正在逐步淘汰。

**Original**: Performs a DRC check on entire design. Has two return options controlled via g_mode option: nil: interactive (on) checks; t: on and batch checks. Will enable On-Line DRC if it is disabled. Obeys current DRC mode settings. Batch mode is being phased out.

**语法**：
```skill
axlDRCUpdate(g_mode)
```

**参数**：
- `g_mode`：`t`执行所有检查加仅批处理检查；`nil`仅执行交互式检查。

**返回值**：
- `x_cnt`：返回错误数

**相关函数**：`axlDRCGetCount`, `axlDBControl`, `axlDRCWaive`, `axlDBCheck`

**示例**：
```skill
db = axlDBFindByName('net "GND")
cnt = axlDRCItem(nil p)
```

---

### axlDRCWaive

**说明**：管理豁免DRC状态并访问豁免DRC功能。它支持豁免和恢复（取消豁免）DRC标记。该接口支持单个和DRC dbid列表。如果恢复DRC标记，它将重新出现，但可能不再反映实际的DRC错误。这可能是由于：
- 约束预期值的变化
- 导致DRC的对象的变化
- 不同的DRC模式设置

确定DRC是否仍应存在的唯一方法是对DRC的`dbid` violation属性中的第一个项目执行`axlDRCItem`。此规则的例外是外部DRC，其中创建DRC的工具必须重新运行。注释也可以通过将注释属性添加到DRC来添加：`axlDBAddProp(drcDbid '("COMMENT" "This drc is OK"))`

**Original**: Manages waive DRC state and access to the waive DRC functionality. It supports both waiving and restoring (unwaive) DRC markers. The interface supports both a single and a list of DRC dbids. If restoring a DRC marker, it will reappear but it may no longer reflect an actual DRC error.

**语法**：
```skill
axlDRCWaive(g_mode o_DrcDbid/lo_DrcDbid [t_comment])
```

**参数**：
- `g_mode`：`t`：豁免DRC；`nil`：取消豁免DRC。
- `o_DrcDbid`：单个DRC标记。
- `lo_DrcDbid`：DRC标记列表。
- `t_comment`：可选，为豁免的DRC添加注释。仅适用于豁免模式。

**返回值**：
- `t`：成功。
- `nil`：由于参数不正确而失败。

**示例**：
```skill
p = axlDBGetDesign()->drcs
axlDRCWaive(t car(p) "This DRC is OK")    ;; 豁免DRC列表中的第一个DRC
p = axlDBGetDesign()->drcs
axlDBGetWaive(t p)                         ;; 豁免设计中的所有DRC
p = axlDBGetDesign()->waived
axlDBGetWaive(nil p)                        ;; 恢复所有豁免的DRC
```

**相关函数**：`axlDBControl`, `axlDRCWaiveGetCount`

---

### axlDRCGetCount

**说明**：返回设计中的DRC总数。注意设计DRC可能已过期。

**Original**: Returns the total number of DRCs in the design. Note the design DRC may be out of date.

**语法**：
```skill
axlDRCGetCount()
```

**参数**：无。

**返回值**：
- `x_count`：DRC计数。

---

### axlDRCItem

**说明**：对指示的项目执行DRC检查。`dbid`可以是任何dbid类型（设计除外）。如果同一项目在列表中多次出现，则返回相同的DRC错误，计数是每个dbid创建的错误之和。`g_mode`选项控制两种返回选项：
- `nil`：返回DRC错误计数。
- `t`：返回DRC错误列表。

这遵守当前DRC模式设置，包括主DRC开启/关闭开关。由于豁免和重复DRC抑制处理，使用`g_mode=t`返回的DRC列表可能少于`g_mode=nil`返回的计数。

这不是运行批处理DRC或"假设"检查的有效方法。

**Original**: Performs a DRC check on the indicated item(s). The dbid may be any dbid type (except the design). If the same item appears multiple times in the list, then the same DRC error(s) are returned. This obeys current DRC mode settings.

**语法**：
```skill
axlDRCItem(g_mode o_dbid/lo_dbid)
```

**参数**：
- `g_mode`：`nil`：返回DRC错误计数；`t`：返回DRC错误列表。
- `o_dbid`：单个。

**返回值**：
- `x_cnt`：返回与项目列表关联的错误数。
- `lo_drcDBid`：DRC dbid列表。
- `nil`：没有dbid（如果`g_mode` = `t`）或参数错误。

**相关函数**：`axlDRCGetCount`, `axlDBControl`, `axlDRCWaive`, `axlDRCUpdate`

**示例**：
```skill
db = axlDBFindByName('net "GND")
cnt = axlDRCItem(nil p)
```

---

### axlDRCWaiveGetCount

**说明**：返回设计中豁免的DRC总数。

**Original**: Returns total number of waived DRCs in the design.

**语法**：
```skill
axlDRCWaiveGetCount()
```

**参数**：无。

**返回值**：
- `x_count`：返回豁免的DRC计数。

---

### axlLayerSet

**说明**：更新层参数的更改。您只能更新参数的颜色和可见性属性。这是`axlSetParam`的包装器。完成颜色或可见性更改后，调用`axlVisibleUpdate`更新显示。

**Original**: Updates changes to layer parameters. You can only update the color and visibility attributes of a parameter. This is a wrapper for axlSetParam. After completing color or visibility changes, call axlVisibleUpdate to update the display.

**语法**：
```skill
axlLayerSet(o_dbid)
```

**参数**：
- `o_dbid`：层参数dbid。

**返回值**：
- `o_dbid`：层参数dbid。
- `nil`：如果错误。

**示例**：
```skill
;; 更改顶层蚀刻层的颜色：
q = axlLayerGet("ETCH/TOP")
q->color = 7
q->pattern = 0          ; 实线图案
q->visibility = nil
axlLayerSet(q)
;; 如果设置多个层颜色/可见性，仅在最后一次更改后调用可见性更新
axlVisibleUpdate(t)
;; 将类上的所有项设置为相同颜色：
q = axlGetParam("paramLayerGroup:ETCH")
q->color = 7
axlSetParam(q)
axlVisibleUpdate(t)
```

**相关函数**：`axlSetParam`, `axlLayerGet`

---

### axlCnsList

**说明**：返回指定域的约束集名称列表。请参阅`axlDBGetDesign()->ecsets`获取电气约束集列表。

**Original**: Returns the list of cset names of the domain specified. See axlDBGetDesign()->ecsets for a list of electrical csets.

**语法**：
```skill
axlCnsList(s_csetDomain/nil)
```

**参数**：
- `s_csetDomain`：支持的域：spacing、physical、sameNet和electrical。`nil`列出所有支持的域。

**返回值**：
- `lt_csetNames`：指定域中的约束集列表。
- `ls_csetDomains`：支持的域列表。

**示例**：
```skill
axlCnsList('spacing)     ;; 返回所有间距约束集名称
axlCnsList(nil)           ;; 返回支持的域
```

**相关函数**：`axlCNSCreate`

---

### axlCNSMapClear

**说明**：请参阅`axlCNSMapUpdate`。

**Original**: See axlCNSMapUpdate.

**语法**：
```skill
axlCNSMapClear()
```

**参数**：无

**返回值**：
- `t`：始终返回 `t`。

**示例**：请参阅`axlCNSMapUpdate`中的示例。

**相关函数**：`axlCNSMapUpdate`

---

### axlCNSMapUpdate

**说明**：此函数和`axlCNSMapClear`（不支持嵌套）批处理和调整由`axlCNS<xxx>`函数进行的约束更改的DRC更新。没有`axlCNS<xxx>`函数执行DRC更新。相反，它们将DRC系统设置为过期。

您可以对一组约束更改运行一次DRC系统，这比作为每次更改的一部分运行效率更高。在大型电路板上，您可能会注意到效率的提高。

**Original**: This function and axlCNSMapClear, which do not support nesting, batch and tune DRC updates from constraint changes made by axlCNS<xxx> functions. No axlCNS<xxx> functions perform a DRC update. Rather, they set the DRC system out-of-date. You can run DRC system once on a set of constraint changes, which is more efficient than running it as part of each change.

**语法**：
```skill
axlCNSMapUpdate()
```

**参数**：无

**返回值**：
- `nil`：没有匹配的`axlCNSMapClear`。
- `x_drcCount`：批处理更改导致的DRC数量。

**示例**：
```skill
;; 关闭电气最大过孔检查，开启所有设计检查，并将岛容差设置为10。
;; Clear/Update调用批处理和优化这些更改所需的DRC更新。
axlCNSMapClear()
axlCNSEcsetModeSet('Maximum_Via_Count 'off)
axlCNSDesignModeSet('all 'on)
axlCNSDesignValueSet('Negative_Plane_Islands 10.0)
axlCNSMapUpdate()

;; 执行一次更改：
axlCNSMapClear()
axlCNSEcsetModeSet('Maximum_Via_Count 'on)
axlCNSMapUpdate()
```

其他实际示例，请参阅`<cdsroot>/share/pcb/examples/cmds`文件 `cns-design.il` 和 `acns_design.form`。

---

### axlCnsNetFlattened

**说明**：允许查看显式引脚对规则被提升到网络的约束视图。函数报告的信息与show element下Properties attached to net标题中的信息相同。它也用于第三方网表（netin）和netrev使用的`pstxnet.dat`文件中的格式。

如果引脚对受电气规则约束（例如，PROPAGATION_DELAY），Allegro PCB Editor将约束存储在引脚对上，而不是网络上。存储在网络上的电气约束是应用于动态引脚对（使用AD:AR、L:S语法）或规则应用于网络（例如，MAX_VIAS）的约束。

这不会返回应用于网络的所有约束值，如果约束是通过电气约束集（ECset）获得的，或在总线或差分对级别存在覆盖。此信息在show element下，Electrical constraints assigned to net标题中报告。Allegro PCB Editor通过将电气属性提升或展平到网络，从xnet、匹配组和引脚对映射电气约束，以呈现传统的网络约束视图并提供与原理图网表工具的兼容性。由于分配给网络的ECset、Xnet、差分对或总线级别的其他约束可能会影响网络。其他覆盖属性可能存在于差分对或总线级别。您可以使用`axlNetECsetValueGet`，但它不会展平约束。

当从同一网络请求多个约束时，使用网络的dbid作为第一个参数而不是网络名称。

**Original**: Permits a view of constraints where explicit pinpair rules are promoted to the net. The information reported by the function is the same as in show element under the Properties attached to net heading. It is also in a format used by the third party netlist (netin) and in the pstxnet.dat file used by netrev.

**语法**：
```skill
axlCnsNetFlattened(o_netDbid/t_netName t_cnsName/s_name)
```

**参数**：
- `o_netDbid/t_netName`：网络的dbid或名称（字符串）。
- `t_cnsName`：约束的属性名称。
- `s_name`：DRC检查的符号名称（`axlCNSEcsetModeGet(nil)`返回的值）。这些名称可能与属性名称不完全匹配。

**返回值**：
- `t_cnsValue`：作为字符串返回的精确值。
- `nil`：网络未定义值。

**示例**：
```skill
rule = axlCnsNetFlattened("NET1" "IMPEDANCE_RULE")     ;; 按名称获取net1的阻抗规则
rule = axlCnsNetFlattened("NET1" 'Impedance)            ;; 按DRC检查名称获取net1的阻抗规则
net = car(axlSelectByName("NET" "MEM_DATA8"))
rule = axlCnsNetFlattened(net "PROPAGATION_DELAY")      ;; 使用网络dbid获取MEM_DATA8的PROPAGATION_DELAY
```

---

## 19.3 DFM DRC 模式函数 (DFM DRC Modes Functions)

---

### axlCNSModeSet

**说明**：设置属于域的约束集检查的当前DRC模式。这些模式控制整个电路板上该检查的DRC。要确定当前支持的集合，请执行`axlCNSModeGet()`。支持多个接口。可以设置所有检查（`'all`）、单个检查（`t_name`）、将检查列表设置为相同模式，以及通过列表设置检查集：

出于性能原因，更改模式或值不会自动调用DRC。您需要手动运行DRC。一组接口支持标记更改，以根据您的更改执行最小集的DRC更新（请参阅`axlCNSMapUpdate`）。未来版本可能会添加或删除约束检查。axl接口确实保证此接口返回的检查将在版本之间保持恒定。

**Original**: This function sets the current DRC modes for checks that fall into set of constraints belonging to a domain. For performance reasons, changing modes or values does not invoke DRC automatically. You need to run the DRC manually. A set of interfaces supports marking changes to perform an minimal set of DRC updates depending upon your changes (see axlCNSMapUpdate).

**语法**：
```skill
axlCNSModeSet(t_domain/s_domain t_name/s_name t_mode/s_mode)     ⇒ t/nil
axlCNSModeSet(t_domain/s_domain 'all t_mode/s_mode)              ⇒ t/nil
axlCNSModeSet(t_domain/s_domain l_constraintNModes t_mode/s_mode)  ⇒ t/nil
axlCNSModeSet(ll_domain ll_constraintNModes)                      ⇒ t/nil
```

**参数**：
- `t_domain`：域的字符串名称；可以是"electrical"、"design"、"dff"、"dfa"、"dft"、"spacing"、"physical"
- `s_domain`：域的符号名称；可以是`'electrical`、`'design`、`'dff`、`'dfa`、`'dft`、`'spacing`、`'physical`
- `s_name`：检查的符号名称
- `t_name`：检查的字符串名称
- `s_mode`：模式设置；可以是`'on`, `'off`, 或 `'batch`
- `t_mode`：字符串模式设置 `"on"`、 `"off"` 或 `"batch"`
- `'all`：为给定级别的Allegro设置指定域中的所有检查。

**返回值**：
- `t`：如果成功
- `nil`：如果失败

**示例**：
```skill
axlCNSModeSet('design 'Package_to_Place_Keepin_Spacing 'on)     ;; 开启pkg to pkg keepin检查
axlCNSModeSet('design 'all 'batch)                              ;; 使所有设计约束仅批处理
axlCNSModeSet('design '(Negative_Plane_Islands Pad_Soldermask_Alignment) 'off)  ;; 关闭两个约束
axlCNSModeSet('design '((Package_to_Place_Keepin_Spacing off) (Package_to_Place_Keepout_Spacing 'on)))  ;; 将各种约束设置为不同模式
axlCNSModeSet('dff 'all 'on)                                    ;; 开启所有DFF约束
axlCNSModeSet('dft 'all 'off)                                   ;; 关闭所有DFT约束
```

**相关函数**：`axlCNSDesignModeGet`, `axlCNSDesignValueGet`, `axlCNSMapUpdate`

---

### axlCNSModeGet

**说明**：获取指定域下约束集检查的当前DRC模式。这些约束涉及整个电路板。`'print`模式提供在报告中显示的名称，如show element。这具有`axlDebug`支持。未来版本可能会添加或删除约束检查。axl接口确实保证此接口返回的检查将在版本之间保持恒定。

**Original**: This function fetches the current DRC modes for checks that fall into set of constraints under the specified domain. These constraints pertain to the entire board. The 'print mode offers the name shown in reports like show element. This has axlDebug support. Future releases may add or subtract constraint checks. The axl interface does guarantee the checks returned by this interface will remain constant from release to release.

**语法**：
```skill
axlCNSModeGet(t_domain/s_domain nil)                   ⇒ ls_constraints
axlCNSModeGet(t_domain/s_domain 'all)                  ⇒ lls_constraintNModes
axlCNSModeGet(t_domain/s_domain 'editable)             ⇒ t/nil
axlCNSModeGet(t_domain/s_domain s_name/t_name)        ⇒ s_mode/nil
axlCNSModeGet(t_domain/s_domain s_name/t_name 'print) ⇒ t_name/nil
```

**参数**：
- `t_domain`：域的字符串名称；可以是"electrical"、"design"、"dff"、"dfa"、"dft"、"spacing"、"physical"
- `s_domain`：域的符号名称；可以是`'electrical`、`'design`、`'dff`、`'dfa`、`'dft`、`'spacing`、`'physical`
- `nil`：返回指定DRC域中的所有检查
- `'all`：返回所有检查和当前模式
- `'editable`：如果模式可以更改则返回`t`，否则返回`nil`。在Allegro studio中返回`nil`，该选项不提供此选项。
- `s_name`：检查的符号名称
- `t_name`：检查的字符串名称
- `'print`：可打印约束名称选项

**返回值**：
- `ls_names`：检查列表（`s_name` ...）
- `lls_names`：检查及其模式列表（(`s_name s_mode`) ...）
- `s_mode`：模式 `'on`, `'off` 或 `'batch`
- `t_name`：可打印约束名称

**示例**：
```skill
axlCNSModeGet('design nil)                    ;; 获取设计约束的当前列表
axlCNSModeGet('design 'all)                    ;; 获取所有设计约束的设置列表
axlCNSModeGet('design 'Package_to_Package_Spacing)     ;; 获取pkg to pkg的当前设置
axlCNSModeGet("design" "Negative_Plane_Islands")        ;; 使用字符串获取负平面岛的当前设置
axlCNSModeGet('dff 'all)                       ;; 获取DFF约束的当前设置
```

**相关函数**：`axlCNSDesignModeSet`, `axlCNSDesignValueGet`

---

*文档翻译完成 — 返回顶部*
