# 31. DFM API (DFM APIs)

## 概述 (Overview)

本章描述与可制造性设计（DFM）相关的 AXL-SKILL 函数。

## 组件引脚函数 (Component Lead Functions)

### axlCreateLeadContact

**说明**：为属于符号定义的引脚创建引脚接触形状（Lead Contact Shape）。

**Original**: This function creates lead contact shape for the pins belonging to a symbol definition.

**参数** (Arguments)：

t_leadType
- **Type** — of leads to be created. The valid types are:
"No lead", "Ball", "Ball-Collapsing", "Ball-Non collapsing", "Bump", "Column", "Pillar", "Rectangular end cap", "Cylindrical end cap", "Flat lead", "Flat lug", "Flat no-lead bottom", "Flat no-lead edge", "Flat thermal", "Gull wing", "Ribbon L-Inward","Ribbon L-Outward", "Under body outward L", "J-Lead", "Side lead convex","Side lead concave","Side lead flat", "Butt lead","Corner concave","Other surface","Through round","Through rectangular","Through other", "No connect", "Press fit"
t_symbol
- **Name** — of the symbol
l_pins
- **List** — of dbids of the pins for which the contact shapes are to be created. If this is passed as
nil
- **all** — the numbered pin will be considered for lead.
r_leadParams
- **Use** — make_axlLeadParam. Elements are:
leadFigure: (text) Allowed names are "CIRCLE", "RECTANGLE", "DONUT", "N_SIDED_POLY" "OBLONG", "OCTAGON", "ROUNDED_RECT", "CHEMFERED_RECT", "SQUARE", "SHAPE"
leadShape
(text) name of the shape (valid only if 'SHAPE is specified as leadFigure)
figureSize: (list) (f_width:f_height) width and height of the figure
offset: (list) (x_offset:y_offset) offset of the lead contact shape with respect to pad center
length: length of the actual lead
width: width of the lead
height: height of the lead
n_sides: no of sides (valid for N_SIDED_POLY)
outer_inner_dia: (outerDia innerDia) valid for Donut shape
cornerRadOrChanf: specific to rounded or chamfered rectangle. They specify corner radius or corner chamfer.
corner: specifies the list of corners that need to be rounded/chamfered. Valid values of an element are:
"UPPER_LEFT", "UPPER_RIGHT", "LOWER_LEFT", "LOWER_RIGHT"

**返回值** (Value Returned)：

t
If successful
nil
If failed

**示例** (Examples)：

leadParams = cons( make_axlLeadParam( ?leadFigure 'N_SIDED_POLY ?figureSize 10:10 ?offset
-1:-2 ?length 50 ?width 10 ?height 10 ?n_sides 8 ) nil )
axlCreateLeadContact("Ball" "RES" nil leadParams ) ; apply ball type lead for all the pins in the symbol

**参见** (See Also)：

axlDeleteLeadContact

### axlDeleteLeadContact

**说明**：删除属于符号定义的引脚的引脚接触形状。

**Original**: This function deletes lead contact shape for the pins belonging to a symbol definition.

**参数** (Arguments)：

t_symbol
- **Name** — of the symbol
l_pins
- **List** — of dbids of the pins for which the contact shapes are to be deleted. If this is passed as
nil
- **all** — the numbered pin will be considered.

**返回值** (Value Returned)：

t
If successful
nil
If failed

**示例** (Examples)：

axlDeleteLeadContact("RES" nil ) ; delete all the lead contact for the symbol

**参见** (See Also)：

axlCreateLeadContact

### axlGetSupportedLeadTypes

**说明**：返回所有支持的引脚类型列表。列表中的每个元素都是引脚编辑器和引脚检查支持的引脚类型名称。

**Original**: This function returns all the supported lead types in the form of a list. Each element of the list is a name of the lead types supported by the lead editor and lead checks.

**参数** (Arguments)：

g_category
- **Category** — of the lead. Valid values are:
ALL: Get all type of leads
SMD: Get lead types that are valid for surface mount devices
THRU: Get lead types that are valid for through hole pins
BALL: Get lead types that are applicable to balls

**返回值** (Value Returned)：

list of valid lead types
If successful
nil
If failed

**示例** (Examples)：

ll = axlGetSupportedLeadTypes(“ALL”) ; Get all supported lead types
DFM CSet Operations
Worksheet Names
The following table lists supported worksheet names.
Table 31-1
Worksheet names
"DFF_OUTLINE"
Indicates that cset is going to hold constraints pertaining to OUTLINE worksheet
"DFF_MASK"
Indicates that cset is going to hold constraints pertaining to MASK worksheet
"DFF_HOLE"
Indicates that cset is going to hold constraints pertaining to HOLE worksheet
"DFF_SILKSCREEN"
Indicates that cset is going to hold constraints pertaining to SILKSCREEN worksheet
"DFF_ANNULAR_RING"
Indicates that cset is going to hold constraints pertaining to ANNULAR RING worksheet
"DFF_COPPER_FEATURE"
Indicates that cset is going to hold constraints pertaining to COPPER FEATURE worksheet
"DFF_COPPER_SPACING"
Indicates that cset is going to hold constraints pertaining to COPPER SPACING worksheet
"DFA_OUTLINE"
Indicates that cset is DFA cset pertaining to DFA outline worksheet
"DFA_PKGPKG"
Indicates that cset is DFA cset pertaining to DFA package to package worksheet
"DFA_SPACING"
Indicates that cset is a DFA cset pertaining to DFA spacing worksheet
"DFA_COMPLEAD"
Indicates that cset is a DFA cset pertaining to DFA component lead worksheet
"DFA_MASK"
Indicates that cset is a DFA cset pertaining to DFA mask worksheet
"DFA_FIDUCIAL"
Indicates that cset is a DFA cset pertaining to DFA fiducial worksheet
"DFT_OUTLINE"
Indicates that cset is a DFT cset pertaining to DFT outline worksheet
"DFT_MASK"
Indicates that cset is a DFT cset pertaining to DFT mask worksheet
"DFT_SPACING"
Indicates that cset is a DFT cset pertaining to DFT spacing worksheet
"DFT_PROBE"
Indicates that cset is a DFT cset pertaining to DFT probe worksheet
Subtype CSet Names
The following table lists names of supported subtype CSets.
Table 31-2
List of Subtype CSets
"DFF_OUTLINE"
Indicates that cset is going to hold constraints pertaining to OUTLINE worksheet
"DFF_MASK"
Indicates that cset is going to hold constraints pertaining to MASK worksheet
"DFF_HOLE"
Indicates that cset is going to hold constraints pertaining to HOLE worksheet
"DFF_SILKSCREEN"
Indicates that cset is going to hold constraints pertaining to SILKSCREEN worksheet
"DFF_ANNULAR_RING"
Indicates that cset is going to hold constraints pertaining to ANNULAR RING worksheet
"DFF_COPPER_FEATURE"
Indicates that cset is going to hold constraints pertaining to COPPER FEATURE worksheet
"DFF_COPPER_SPACING"
Indicates that cset is going to hold constraints pertaining to COPPER SPACING worksheet
"DFA_OUTLINE"
Indicates that cset is DFA cset pertaining to DFA outline worksheet
"DFA_PKGPKG"
Indicates that cset is DFA cset pertaining to DFA package to package worksheet
"DFA_SPACING"
Indicates that cset is a DFA cset pertaining to DFA spacing worksheet
"DFA_COMPLEAD"
Indicates that cset is a DFA cset pertaining to DFA component lead worksheet
"DFA_MASK"
Indicates that cset is a DFA cset pertaining to DFA mask worksheet
"DFA_FIDUCIAL"
Indicates that cset is a DFA cset pertaining to DFA fiducial worksheet
"DFT_OUTLINE"
Indicates that cset is a DFT cset pertaining to DFT outline worksheet
"DFT_MASK"
Indicates that cset is a DFT cset pertaining to DFT mask worksheet
"DFT_SPACING"
Indicates that cset is a DFT cset pertaining to DFT spacing worksheet
"DFT_PROBE"
Indicates that cset is a DFT cset pertaining to DFT probe worksheet

**参见** (See Also)：

axlCreateLeadContact
,
axlDeleteLeadContact

### axlCreateDfmAssignment

**说明**：将 DFM 约束集（CSet）分配给层、层组或子类组。通过此操作，与 CSet 关联的所有约束都被分配给该对象。DRC 引擎使用 CSet 分配与对象来确定需要评估的约束。

**Original**: This function assigns a DFM CSet to a layer, layer group, or a subclass group. With this all the constraints associated with the CSet gets assigned to the object. The DRC engine uses the CSet assignments with the objects to determine the constraints that needs to be evaluated.

**参数** (Arguments)：

className
- **Name** — of the classes on which the constraint is applicable. This is applicable only form non etch type of rules specified through subclass group.
worksheetName
- **Name** — of the worksheet where the rule is applicable. Refer to
- **Worksheet** — names
- **for** — valid worksheet names
dfmentryType
- **Specifies** — the entry type in the assignment table. The valid values are:
'LAYER_BASED: Indicates that assignment is layer based and is assigned to a layer.
'CLASS_SUBCLASS: Indicates that the assignment is class subclass based. It needs the subclass group name to be filled.
'GLT_BASED: Indicates that the assignment is applicable to a generic layer type. The subclass group name argument should have a valid GLT name if this type is selected.
- **Valid** — GLT names are:
"TESTING LAYERS": for DFT
"ASSEMBLY LAYERS": for DFA
"CONDUCTOR": For DFF
"PLANE"
- **Any** — GLT name defined in cross-section editor
'STACKUP_BASED: Indicates that the rule is assigned to the stackup. That means that the rule will be assigned to the entire stackup (For example, Outline to Cutout rule).
stackupName
- **Specifies** — the name of the stackup on which the rule is applicable. The primary stackup is named as "PRIMARY"
subclassGrouporGLTName
- **Specifies** — that the name field in the table corresponds to a bucket name which is essentially a group of class and subclass combination. This interpretation is valid only if the entry type is CLASS_SUBCLASS. If value of entry type is GLT_BASED, this field refers to GLT name.
cset_name
- **Specifies** — the name of the DFF CSet that corresponds to the mapping based on other fields.
subClassName
- **Specifies** — the subclass name. This holds the name of the layer or subclass in the table.

**返回值** (Value Returned)：

t
If successful
nil
If failed

**示例** (Examples)：

ll = axlCreateDFMCset("test_cset33" "DFF_OUTLINE" "ETCH")
axlCreateDfmAssignment( "ETCH" "DFF_OUTLINE" "LAYER_BASED"  "PRIMARY" "dummy" "test_cset33" "TOP")

**参见** (See Also)：

axlCreateDffCset, axlDeleteDffCset

### axlDFMIsCsetLocked

**说明**：检查 DFM 约束集是否被锁定。

**Original**: This function Checks if a DFM cset is locked or not.

**参数** (Arguments)：

worksheet_name
- **Name** — of the worksheet where the rule is applicable. Refer to
- **Worksheet** — names
- **for** — valid worksheet names
cset_name
- **Specifies** — the name of the DFM CSet that corresponds to the mapping based on other fields.

**返回值** (Value Returned)：

t
If locked
nil
If not locked

**示例** (Examples)：

lockStatus = axlDFMIsCsetLocked( "DFF_OUTLINE"  "test_cset33" )

**参见** (See Also)：

axlDFMCsetLock

### axlDFMCsetLock

**说明**：锁定或解锁 DFM 约束集。

**Original**: This function locks/unlocks a DFM cset.

**参数** (Arguments)：

worksheet_name
- **Name** — of the worksheet where the rule is applicable. Refer to
- **Worksheet** — names
- **for** — valid worksheet names
cset_name
- **Specifies** — the name of the DFM cset that corresponds to the mapping based on other fields.
g_mode
- **May** — either be
t
(to lock) or
nil
- **to** — unlock

**返回值** (Value Returned)：

t
If updated lock status
nil
If an error

**示例** (Examples)：

axlDFMCsetLock( "DFF_OUTLINE"  "test_cset33" t)

**参见** (See Also)：

axlDFMIsCsetLocked

### axlDeleteDfmAssignment

**说明**：删除可制造性设计（DFM）约束集分配。

**Original**: This function deletes Design For manufacturing cset assignment.

**参数** (Arguments)：

worksheet_name
- **Name** — of the worksheet where the rule is applicable. Refer to
- **Worksheet** — names
- **for** — valid worksheet names
cset_name
- **Specifies** — the name of the DFM cset that corresponds to the mapping based on other fields.

**返回值** (Value Returned)：

t
If successful
nil
If failed

**示例** (Examples)：

axlDeleteDfmAssignment( "DFF_OUTLINE"  "test_cset33" )

**参见** (See Also)：

axlCreateDFMCset

### axlGetDFMAssignedCsets

**说明**：获取设计中已分配的制造设计（DFM）约束集。

**Original**: This function gets the Assigned Design For Manufacturing (DFM) CSets in a design.

**参数** (Arguments)：

subtype
- **Specifies** — the sub type of the CSet. The valid values are:
DFF_OUTLINE: Indicates that CSet is going to hold constraints pertaining to OUTLINE worksheet.
DFF_MASK: Indicates that CSet is going to hold constraints pertaining to MASK worksheet.
DFF_HOLE: Indicates that CSet is going to hold constraints pertaining to HOLE worksheet.
DFF_SILKSCREEN: Indicates that CSet is going to hold constraints pertaining to SILKSCREEN worksheet.
DFF_ANNULAR_RING: Indicates that CSet is going to hold constraints pertaining to ANNULAR RING worksheet.
DFF_COPPER_FEATURE: Indicates that CSet is going to hold constraints pertaining to COPPER FEATURE worksheet.
DFF_COPPER_SPACING: Indicates that CSet is going to hold constraints pertaining to COPPER SPACING worksheet.
DFA_OUTLINE: Indicates that CSet is a DFA CSet pertaining to DFA outline worksheet.
DFA_PKGPKG: Indicates that CSet is a DFA CSet pertaining to DFA package to package worksheet.
DFA_SPACING: Indicates that CSet is a DFA CSet pertaining to DFA spacing worksheet.
DFA_COMPLEAD: Indicates that CSet is a DFA CSet pertaining to DFA component lead worksheet.
DFA_MASK: Indicates that CSet is a DFA CSet pertaining to DFA mask worksheet.
DFA_FIDUCIAL: Indicates that CSet is a DFA CSet pertaining to DFA fiducial worksheet.
DFT_OUTLINE: Indicates that CSet is a DFT CSet pertaining to DFT outline worksheet.
DFT_MASK: Indicates that CSet is a DFT CSet pertaining to DFT mask worksheet.
DFT_SPACING: Indicates that CSet is a DFT CSet pertaining to DFT spacing worksheet.
DFT_PROBE: Indicates that CSet is a DFT CSet pertaining to DFT probe worksheet.

**返回值** (Value Returned)：

List of CSets and types along with the assignment details, if there is at least one assigned CSet. If there are more than one CSet on that category, it will be a list of lists.
Each list will contain the following:
Name of the cset
Subtype of the cset. The valid values are mentioned under arguments.
DFM entry type. The valid values are as follows:
LAYER_BASED: Indicates that assignment is layer based and is assigned to a layer.
CLASS_SUBCLASS: Indicates that the assignment is class and subclass based. It needs the subclass group name to be filled.
GLT_BASED: Indicates that the assignment is applied to a generic layer type.Valid GLT names are:
TESTING LAYERS: for DFT
ASSEMBLY LAYERS: for DFA
CONDUCTOR: For DFF
PLANE
Any GLT name defined in Cross-section Editor.
STACKUP_BASED: Indicates that the rule is assigned to the stackup. For example,. Outline to Cutout rule.
stackupName: Specifies the name of the stackup on which the rule is applied. The primary stackup is named as PRIMARY.
subclassGrouporGLTName: Specifies that the name field in the table corresponds to a subclass group name which is essentially a group of class subclass combination. This interpretation is valid only if the entry type is CLASS_SUBCLASS. If the value of entry type is GLT_BASED, this field refers to GLT name. Otherwise subclass name is returned.
subclass_name: Specifies the subclass name. This field holds the name of the layer or subclass in the table.
className: Specifies the name of the class on which the constraint is applicable. This field is allowed only for non-etch type of rules specified through subclass group. By default, it returns BOARD_GEOMETRY.
nil
is returned if failed or if there is no CSet assigned.

**示例** (Examples)：

For example, in a design that has 2 CSets with types Annular ring and 1 CSet with type Mask in DFF sub-domain:
The function call axlGetDFMAssignedCsets("DFF_ANNULAR_RING" ) return the following:
( ("ABC1" "DFF_ANNULAR_RING" "LAYER_BASED" "PRIMARY" "SOLMPH_TOP"  "SOLMPH_TOP" "BOARD_GEOMETRY") ("TEST2" "DFF_ANNULAR_RING" "LAYER_BASED" "PRIMARY" "SOLMPH_TOP"  "SOLMPH_BOT" "BOARD_GEOMETRY") )
Function call axlGetDFMAssignedCsets("DFF_MASK" ) return the following:
("ABC2" "DFF_MASK" "CLASS_SUBCLASS" "PRIMARY" "SILK2PAD_TOP" "PLATING_BAR" "BOARD_GEOMETRY"))

**参见** (See Also)：

axlCreateDFMCset
,
axlCreateDfmAssignment
, axlDeleteDffCset

### axlGetDFMCsetAssignmentStatus

**说明**：检查给定的制造（DFM）约束集是否在设计中已分配。

**Original**: This function checks if a given Manufacturing (DFM) CSet is assigned in a design.

**参数** (Arguments)：

cset_name
- **Name** — of the CSet
subtype
- **Specifies** — the sub type of the CSet. The valid values are:
DFF_OUTLINE: Indicates that CSet is going to hold constraints pertaining to OUTLINE worksheet.
DFF_MASK: Indicates that CSet is going to hold constraints pertaining to MASK worksheet.
DFF_HOLE: Indicates that CSet is going to hold constraints pertaining to HOLE worksheet.
DFF_SILKSCREEN: Indicates that CSet is going to hold constraints pertaining to SILKSCREEN worksheet.
DFF_ANNULAR_RING: Indicates that CSet is going to hold constraints pertaining to ANNULAR RING worksheet.
DFF_COPPER_FEATURE: Indicates that CSet is going to hold constraints pertaining to COPPER FEATURE worksheet.
DFF_COPPER_SPACING: Indicates that CSet is going to hold constraints pertaining to COPPER SPACING worksheet.
DFA_OUTLINE: Indicates that CSet is a DFA CSet pertaining to DFA outline worksheet.
DFA_PKGPKG: Indicates that CSet is a DFA CSet pertaining to DFA package to package worksheet.
DFA_SPACING: Indicates that CSet is a DFA CSet pertaining to DFA spacing worksheet.
DFA_COMPLEAD: Indicates that CSet is a DFA CSet pertaining to DFA component lead worksheet.
DFA_MASK: Indicates that CSet is a DFA CSet pertaining to DFA mask worksheet.
DFA_FIDUCIAL: Indicates that CSet is a DFA CSet pertaining to DFA fiducial worksheet.
DFT_OUTLINE: Indicates that CSet is a DFT CSet pertaining to DFT outline worksheet.
DFT_MASK: Indicates that CSet is a DFT CSet pertaining to DFT mask worksheet.
DFT_SPACING: Indicates that CSet is a DFT CSet pertaining to DFT spacing worksheet.
DFT_PROBE: Indicates that CSet is a DFT CSet pertaining to DFT probe worksheet.

**返回值** (Value Returned)：

t
If CSet is assigned
nil
Otherwise

**示例** (Examples)：

retVal = axlGetDFMCsetAssignmentStatus( "ABC" "DFF_MASK")

**参见** (See Also)：

axlCreateDFMCset
,
axlCreateDfmAssignment
, axlDeleteDffCset,
axlGetDFMAssignedCsets

### axlRenameDFFCset

**说明**：使用新名称重命名现有的 DFF 约束集。

**Original**: This function renames an existing DFF CSet with a new name.

**参数** (Arguments)：

oldCsetName
- **Name** — of the existing cset
newCsetName
- **New** — name of the cset
csetType
- **Type** — of the existing cset.
- **Refer** — to
- **List** — of Subtype CSets
- **for** — valid values.

**返回值** (Value Returned)：

l_csetObj
New id of cset
nil
If failed

**示例** (Examples)：

axlRenameDFFCset(“test” “test_new” "DFF_OUTLINE")
==> "12,1,2,0,test_bucket1,TOP,test_cset1"

**参见** (See Also)：

axlCreateDffCset, axlCreateDffAttr

### axlCreateDFMCset

**说明**：创建可制造性设计（DFF）约束集。DFM 约束集保存要在设计上执行的各种检查约束值。

**Original**: This function creates a Design For Manufacturing (DFF) Cset. The DFM cset holds the constraint values for various checks to be performed on the design.

**参数** (Arguments)：

name
- **Name** — of the cset to create
subtype
- **Sub** — type of the cset.
- **Refer** — to
- **List** — of Subtype CSets
- **for** — valid values.
usage
- **Specifies** — the cset intent. The valid values are:
"ETCH": Indicates that cset is to be used for constraints in conducting layer. This is valid for DFF, DFA and DFT subdomain
"NON_ETCH": Indicates that the cset is for constraints on non-etch subclasses. Valid for all the DFM subdomains
"STACKUP": Indicates that the cset captures constraints for stackup based rules. Valid for DFF
"SPACING": Indicates that cset captures package to package rules. This is valid for DFA_PKGPKG worksheets.
"HEIGHT": Indicates that cset captures constraints for AOI rules. This is valid for DFA_PKGPKG worksheet.

**返回值** (Value Returned)：

l_dfm_cset
db id of the DFM cset object, if successful
nil
If failed

**示例** (Examples)：

axlCreateDFMCset("test_cset33" "OUTLINE")
axlDeleteDFMCset
axlDeleteDffCset(
name
subtype
)
⇒ t/nil

**参见** (See Also)：

axlDeleteDffCset

### axlGetDFMCsets

**说明**：获取设计中的可制造性设计（DFM）约束集。

**Original**: This function gets the Design For Manufacturing (DFM) Csets in the design.

**参数** (Arguments)：

subtype
- **Sub** — type of the cset.
- **Refer** — to
- **List** — of Subtype CSets
- **for** — valid values.

**返回值** (Value Returned)：

l_dfm_csetlist
List of DB ids for the DFM csets of the specified types
nil
Failed or if there is none

**示例** (Examples)：

axlCreateDFMCset("DFT_PROBE" )

**参见** (See Also)：

axlCreateDFMCset
, axlDeleteDffCset

### axlGetDFMCset

**说明**：获取设计中的可制造性设计（DFM）约束集。

**Original**: This function gets the Design For Manufacturing (DFM) Csets in the design.

**参数** (Arguments)：

name
- **Name** — of the cset
subtype
- **Sub** — type of the cset.
- **Refer** — to
- **List** — of Subtype CSets
- **for** — valid values.

**返回值** (Value Returned)：

l_dff_cset
dbid of the cset
nil
Failed or if the cset does not exist

**示例** (Examples)：

axlGetDFMCset("Test_cset" "DFT_PROBE" )

**参见** (See Also)：

axlCreateDFMCset
,
axlGetDFMCsets
