# 16. 数据库分组 (Database Group)

> **来源**: Allegro SKILL Reference, Product Version 17.4-2019, October 2019

---



**概述** (Overview):

**说明**：本章描述 AXL-SKILL 数据库分组函数。

**Original**: This chapter describes the AXL-SKILL Database Group functions.


### axlDBAddGroupObjects

```skill
axlDBAddGroupObjects(
```
o_group
lo_members
```skill
)
```
⇒ t/nil

**描述** (Description):

Adds the database objects specified in the new members list to a group. All restrictions and disclaimers specified in
axlDBCreateGroup
also apply for this procedure.

**参数** (Arguments):

o_group
```skill
dbid
```
of the group to receive new members.
lo_members
List of
```skill
dbid
```
’s specifying the new group members. Database objects already in the group are silently ignored (giving a return value of
t
.) A single
```skill
dbid
```
can be substituted for a list.

**返回值** (Value Returned):

t
**说明**：对象已添加到组。

**Original**: Objects added to the group.

nil
Objects could not be added to the group because the resulting group does not meet the restrictions specified in
axlDBCreateGroup
.

**参见** (See Also):

axlDBCreateGroup

---


### axlDBCreateGroup

```skill
axlDBCreateGroup(
```
t_name
t_type
lo_groupMembers
```skill
)
```
⇒
o_dbid
/nil

**描述** (Description):

Creates a new group database object with members specified by
lo_groupMembers
.

**参数** (Arguments):

t_name
String providing the group name. If name is in use by an existing group, this function fails and returns
nil
.
t_type
String defining the group type. Legal values are:
```skill
"
```
generic
```skill
"   - Allegro user groups
```
members: anything except other non-generic group objects
```skill
"
```
bus
```skill
"
```
members: net and xnets
```skill
"
```
net_group
```skill
"
```
members: xnet, net, diffpair, bus and net_group
```skill
"
```
nets_rko
```skill
" - a net keepout group
```
members: xnet, net, diffpair bus, net_group shape and fill rectangles (via and route keepout)
```skill
"
```
die_stack
```skill
" - APD+ only
```
members: compinst, syminst, rectangle, shape
```skill
"
```
ratbundle
```skill
"
```
members: pinpair
```skill
"
```
wire_profile
```skill
" - APD+ only
```
members: a wire (cline or wire subclass)
```skill
"
```
module
```skill
" - suggest to use
```
axlDBCreateModuleDef
**说明**：可访问但不推荐。

**Original**: Accessible but not recommended.

```skill
"
```
db_drill_legend
```skill
" - drill legend tables
"
```
rf_nets
```skill
" - RF "super" nets
```
lo_members
List of AXL
```skill
dbids
```
defining the group members. Duplicate
```skill
dbid
```
entries are silently ignored. An object is added to a group only once. A single
```skill
dbid
```
can be substituted for a list.
If certain restrictions on the group members are violated, this function fails and returns
nil
.
For each group type has only certain objects that are allowed. For example generic groups only permits:
group
**说明**：无法形成循环组关系。

**Original**: A circular group relationship cannot be formed.

**说明**：例如，如果组 B 直接或间接是组 A 的成员，则组 A 不能作为组 B 的成员添加。

**Original**: For example, group A cannot be added as a member of group B if group B is directly or indirectly a member of group A.


**返回值** (Value Returned):

o_dbid
```skill
dbid
```
of the newly formed group.
nil
**说明**：如果无法创建组。

**Original**: If the group could not be created.


**参见** (See Also):

axlDBAddGroupObjects
,
axlDBDisbandGroup
,
axlDBRemoveGroupObjects

**示例** (Example):

Generic group
groupMembers = axlGetSelSet()
group_dbid = axlDBCreateGroup("my_group" "generic" groupMembers)
Net group
groupMembers = axlSelectByName("NET" "NET*" t)
group_dbid = axlDBCreateGroup("NG1" "net_group" groupMembers)
The order of the group members provided when you access the
groupMembers
property may vary from the order provided in
lo_groupMembers
.

---


### axlDBDisbandGroup

```skill
axlDBDisbandGroup(
```
o_group
```skill
)
```
⇒ t/nil

**描述** (Description):

Disbands the database group you specify with the
o_group
argument, thereby immediately removing the group. Members of the group are not deleted.

**参数** (Arguments):

o_group
```skill
dbid
```
of the group to be deleted.

**返回值** (Value Returned):

t
**说明**：组已解散。

**Original**: Group disbanded.

nil
Group could not be disbanded due to an invalid argument, for example, the
```skill
dbid
```
not being for a valid group.

**参见** (See Also):

axlDBCreateGroup

---


### axlDBGetGroupFromItem

```skill
axlDBGetGroupFromItem(
```
o_dbid
t_groupType
[g_promoteToNet]
```skill
) -> lo_groupDbid/nil
```

**描述** (Description):

Filter object's group membership by a group type. You can normally fetch the list of groups that an object is a member of by using the groups attribute of its dbid (etc. o_dbid->groups). This function provides additional filtering where you can request if an belongs to a particular group type. Depending upon the group characteristics an object can either belong to single group of a type or can be a member multiple groups of a single type. For example, an object can belong to multiple generic groups can belong to only one differential pair group.
The g_promoteToNet option for groups for which membership is limited to nets/xnets. It promotes the object provided to its owning xnet, and is targeted for use with diffpair and bus groups, where membership is limited to the net's xnet. It provides an easy way for those groups if given the dbid of a net to promote the id to its xnet.

**参数** (Arguments):

o_dbid
```skill
dbid to be examined
```
t_groupType
group type name. This is the group type name NOT the name of the group. In dbid terms this is group->type.
g_mode
If this value is
t
, it promotes the object to its net/xnet and performs test on that object.
If the value is set to
```skill
'all
```
then it traverses group hierarchy and returns both direct and indirect group membership of dbid.
For example, if net is a member of a xnet which is a member of a diffpair, and you specify group type of "DIFF_PAIR", this returns diffpair group for object.

**返回值** (Value Returned):

lo_groupDbid
**说明**：组 dbid，如果不是所请求组类型的成员则为 nil

**Original**: Group dbids or nil if not a member of requested group type


**参见** (See Also):

:
axlDBCreateGroup

**示例** (Examples):

In both case ashOne is a shareware utility that allows user to select one object (see
<CDSROOT>
/share/pcb/examples/skill/ash-fxf/ashone.il
differential pair; set
g_promoteToNet
to
t
in case net is part of a xnet
p = ashOne()    ;
select a net that is a diffpair member
l = axlDBGetGroupFromItem(p "DIFF_PAIR" t)
generic group
p = ashOne()    ;
create a group and select an object that is part of group
l = axlDBGetGroupFromItem(p "GENERIC")

---


### axlDBGroupRename

```skill
axlDBGroupRename(
```
o_groupDbid
t_newName
```skill
)
```
==> t/nil

**描述** (Description):

Renames a group. Groups supported are GENERIC, BUS, DIFF_PAIR, NETCLASS, NET_GROUP and MATCH_GROUP. Do not attempt to rename group types not listed.
All restrictions and disclaimers specified in
axlDBCreateGroup
also apply for this API.

**参数** (Arguments):

o_groupDbid
The dbid of the group to be renamed
t_newName
New name of the group. Group name must be unique for the group type.

**返回值** (Value Returned):

t
**说明**：重命名成功。

**Original**: Successful in rename.

nil
**说明**：重命名失败；dbid 不是组，组无法重命名，新名称对组类型不合法或该类型中已存在同名。

**Original**: Failed in rename; dbid not a group, group can't be renamed, new name is not legal for group type or name already exists in that group type.


**参见** (See Also):

axlDBCreateGroup

---


### axlDBRemoveGroupObjects

```skill
axlDBRemoveGroupObjects(
```
o_group
lo_members
```skill
)
```
⇒ t/nil

**描述** (Description):

Removes the database objects from the specified group. Group members, though removed, are not deleted.

**参数** (Arguments):

o_group
Group
```skill
dbid
```
.
lo_members
List of database objects to be removed from the group. A single
```skill
dbid
```
can be substituted for a list.

**返回值** (Value Returned):

t
**说明**：一个或多个对象已从组中移除。

**Original**: One or more objects removed from the group.

nil
lo_members
contained no
```skill
dbids
```
of objects that could be removed from the group.
Notes:
**说明**：如果组没有成员，则该组被标记为删除，但不会立即移除。

**Original**: If a group is left with no members, the group is tagged for deletion, but is not removed immediately.

You do not need to explicitly remove objects from a group before deleting the object with
axlDeleteObject
. Deleting an object removes it from all groups to which it belongs.

**参见** (See Also):

axlDBCreateGroup

---


### axlNetClassAdd

```skill
axlNetClassAdd(
```
o_netclassdbid/t_netclassName
o_dbid/lo_dbid
```skill
)==> t/nil
```

**描述** (Description):

**说明**：向 netclass 组添加成员。符合条件的成员有：

**Original**: Adds members to a netclass group. Eligible members are:

nets
XNnets
differential pairs
busses
See netclass discussion in
axlNetClassCreate
. This will mark DRC out of date. It is up to the application to update the DRC system.
Using dbids is faster then using names.

**参数** (Arguments):

o_netclassdbid
```skill
dbid of a netclass group
```
t_netclassName
name of a netclass group
o_dbid
legal database dbid to add to netclass
lo_dbid
list of legal database dbids to add to netclass

**返回值** (Value Returned):

t
**说明**：已添加元素

**Original**: added elements

nil
**说明**：一个或多个元素添加失败；对象可能已经是该域中 netclass 的成员，或不是可添加到 netclass 的合法 dbid

**Original**: failed one or more element adds; object might already be a member of a netclass in that domain or not legal dbid to add to a netclass


**示例** (Examples):

To netclass group created in axlNetClassCreate add two nets
nc = car(axlSelectByName("NETCLASS" "5_MIL"))nets = axlSelectByName("NET" '("NET8" "NET9")
```skill
axlNetClassAdd(nc nets)
```

**参见** (See Also):

axlNetClassCreate

---


### axlNetClassCreate

```skill
axlNetClassCreate(
```
t_name
g_domain/lg_domain
```skill
)==> o_dbid
```

**描述** (Description):

This creates a new netclass group. If a netclass exists with this name then
nil
is returned. Net Classes need to be populated via
axlNetClassAdd
. Empty net classes may be deleted on database save. A netclass must be part of one or more domains. These domains are shown below. The Same Net Constraint domain uses the netclass spacing domain. An object (bus, diffpair, xnet or net) may be a member of single netclass in a domain. For example, if net VCC exists in the POWER netclass in the physical domain then you cannot add it to another netclass in the physical domain. You can still add this net of a netclass in the spacing or electrical domain. You can obtain the current set of net classes in the database via:

---


### axlDBGetDesign


**语法** (Syntax):
```skill
axlDBGetDesign()->netclass
. axlNetClassGet reports if an object is a member of a netclass either directly or via the logic hierarchy.
To assign a cset to a netclass assign the PHYSICAL_CONSTRAINT_SET, SPACING_CONSTRAINT_SET, SAME_NET_SPACING_CONSTRAINT_SET or ELECTRICAL_CONSTRAINT_SET property to the netclass where the value of the property is the cset name.
Same Net constraints shares the same domain with the SPACING_CONSTRAINT_SET.
```


**参数** (Arguments):

t_name
**说明**：netclass 组名称（转换为大写）

**Original**: name of netclass group (changed to upper case)

g_domain
**说明**：netclass 域可以是 'spacing、'physical、'electrical 或 'all

**Original**: netclass domain can be 'spacing, 'physical, 'electrical or 'all

lg_domain
```skill
list of netclass domains
```

**返回值** (Value Returns):

nil:
**说明**：错误或已存在该名称的 netclass

**Original**: error or netclass with that name exists

o_dbid:
```skill
dbid of group
```

**参见** (See Also):

axlNetClassDelete
,
axlNetClassAdd
,
axlNetClassRemove
,
axlNetClassGet
,
axlDBAddProp
,
axlCNSCreate

**示例** (Examples):

Create a netclass in physical domain called "
5_MIL
```skill
"
```
nc = axlNetClassCreate("5_mil" 'physical)

---


### axlNetClassDelete

```skill
axlNetClassDelete(
```
o_netclassdbid/t_netclassName/lg_netclassdbid
```skill
) -> t/nil
```

**描述** (Description):

This deletes a net class group. It does not delete the objects belonging to the group. It is up to the application code to update DRC.
Using dbids is faster then using names.

**参数** (Arguments):

o_netclassdbid
```skill
dbid of a net class group
```
t_netclassName
name of a net class group
lg_netclassdbid
list of net class groups (dbids or names)

**返回值** (Value Returned):

t
**说明**：net class 组已删除

**Original**: net class group deleted

nil
**说明**：失败

**Original**: failed


**参见** (See Also):

axlNetClassCreate

**示例** (Examples):

Delete net class group created in axlNetClassCreate
nc = car(axlSelectByName("NETCLASS" "5_MIL"))
```skill
axlNetClassDelete(nc)
```
or

---


### axlNetClassGet

```skill
axlNetClassDelete("5_MIL")
axlNetClassGet(
```
o_dbid
s_domain
g_hierarchal
```skill
)==> o_netclass
```

**描述** (Description):

Given a dbid (net, xnet, diffpair or bus) and a domain (spacing, physical or electrical) return its netclass. If g_hierarchical is nil, returns object's netclass if a direct member. If g_hierarchal=t returns first netclass encountered in logical hierarchy. For example, if a net is a member of a bus and the bus is assigned to netclass, BUSCLASS, and you pass a net of the bus to this API:
will return nil if g_hierarchy=nil
will return netclass dbid, BUSCLASS, if g_hierarchy=t

**参数** (Arguments):

o_dbid
dbid may be net, xnet, diffpair or bus
s_domain
netclass domain; spacing, physical or electrical
g_hierarchal

**返回值** (Value Returned):

o_netclass
```skill
dbid of netclass
```
nil
**说明**：对象不是该域中 netclass 的一部分，或无效对象

**Original**: object not part of a netclass in the domain or an invalid object


**参见** (See Also):

axlNetClassCreate

**示例** (Examples):

Use example in
axlNetClassAdd
From example in (should return netclass in both cases)
net = car(axlSelectByName("NET" "NET8"))

---


### axlNetClassRemove

```skill
axlNetClassGet(nets 'physical nil)
axlNetClassGet(nets 'physical t)
axlNetClassRemove(
```
o_netclassdbid/t_netclassName
o_dbid/lo_dbid
```skill
)==> t/nil
```

**描述** (Description):

Removes elements from an existing net class group. Element must currently be a direct member of the group. This will mark DRC out of date. It is up to the application to update the DRC system.
Using dbids is faster then using names.

**参数** (Arguments):

o_netclassdbid
```skill
dbid of a netclass group
```
t_netclassName
name of a netclass group
o_dbid
legal database dbid to remove from group
lo_dbid
list of legal database dbids to remove from group

**返回值** (Value Returned):

t
**说明**：已移除元素

**Original**: removed elements

nil
**说明**：无法移除一个或多个元素。对象可能不是 cset 成员（成员必须是直接成员）。

**Original**: failed to remove one or more elements. Object may not be a cset member (member must be a direct member).


**示例** (Examples):

Using the example from axlNetClassAdd remove one of the nets:
```skill
axlNetClassRemove(nc car(nets))
```

**参见** (See Also):

axlNetClassCreate

---


### axlRegionAdd

```skill
axlRegionAdd(
```
o_regiondbid/t_regionName
o_dbid/lo_dbid
```skill
)==> t/nil
```

**描述** (Description):

Adds members to a region group. Eligible members are:
shapes
rectangles
Only objects on the CONS_REGION class may be added to a region. See region discussion in axlRegionCreate. This will mark DRC out of date. It is up to the application to update the DRC system
Using dbids is faster then using names.

**参数** (Arguments):

o_regiondbid
```skill
dbid of a region group
```
t_regionName
name of a region group
o_dbid
legal database dbid to add to region
lo_dbid
list of legal database dbids to add to region

**返回值** (Value Returned):

t
**说明**：已添加元素

**Original**: added elements

nil
**说明**：一个或多个元素添加失败；对象可能已经是区域的成员，或不是可添加到区域的合法 dbid

**Original**: failed one or more element adds; object might already be a member of a region or not legal dbid to add to a region


**参见** (See Also):

axlRegionAdd

**示例** (Examples):

To region group created in axlRegionCreate add a shape
nc = car(axlSelectByName("REGION" "BGA"))
lyr = "CONSTRAINT REGION/OUTER_LAYERS"
shape = axlDBCreateRectangle( list(100:100 200:200) nil lyr)
shape = car(shape)

---


### axlRegionCreate

```skill
axlRegionAdd(nc shape)
axlRegionCreate(
```
t_name
```skill
)==> o_dbid
```

**描述** (Description):

Creates a new region group. If a region exists with this name then
nil
is returned. Regions may contain shapes on CONS_REGION class. Shapes are added to the region group via the
axlRegionAdd
. Empty regions may be deleted on database save. You can obtain the current set of regions in the database via:

---


### axlDBGetDesign


**语法** (Syntax):
```skill
axlDBGetDesign()->region
. None of the region APIs are enabled in the PCB L product.
For better performance, when modifying regions you may wish to wrap all the calls with the
axlDBCloak
command.
```


**参数** (Arguments):

t_name
**说明**：region 组名称（转换为大写）

**Original**: name of region group (changed to upper case)


**返回值** (Value Returned):

nil:
**说明**：错误或已存在该名称的区域

**Original**: error or region with that name exists

o_dbid:
```skill
dbid of group
```
**说明**：如果 Shape 是区域的成员，则其 dbid region 属性将引用区域 dbid

**Original**: If shapes are a member of a region then their dbid region attribute will refer to the region dbid


**示例** (Examples):

Create a region called "BGA"
nc = axlRegionCreate("BGA")

**参见** (See Also):

axlRegionDelete
,
axlRegionAdd
,
axlRegionRemove
,
axlDBCreateShape
,
axlDBCreateRectangle

---


### axlRegionDelete

```skill
axlRegionDelete(
```
o_regiondbid/t_regionName/lg_regiondbid
```skill
) -> t/nil
```

**描述** (Description):

This deletes a region group. It does not delete the objects belonging to the group.
Using dbids is faster then using names.

**参数** (Arguments):

o_regiondbid
```skill
dbid of a region group
```
t_regionName
name of a region group
lg_regiondbid
list of region groups (dbids or names)

**返回值** (Value Returned):

t
**说明**：net class 组已删除

**Original**: net class group deleted

nil
**说明**：失败

**Original**: failed


**参见** (See Also):

axlRegionCreate

**示例** (Examples):

Delete region group created in axlRegionCreate
nc = car(axlSelectByName("REGION" "BGA"))
```skill
axlRegionDelete(nc)
```
or

---


### axlRegionRemove

```skill
axlRegionDelete("BGA")
axlRegionRemove(
```
o_regiondbid/t_regionName
o_dbid/lo_dbid
```skill
)==> t/nil
```

**描述** (Description):

Removes shapes from an existing region group. Element must currently be a direct member of the group. This will mark DRC out of date. It is up to the application to update the DRC system.
Using dbids is faster then using names.

**参数** (Arguments):

o_regiondbid
```skill
dbid of a region group
```
t_regionName
name of a region group
o_dbid
legal database shapes to remove from group
lo_dbid
list of legal database shapes to remove from group

**返回值** (Value Returned):

t
**说明**：已移除元素

**Original**: removed elements

nil
**说明**：无法移除一个或多个元素。对象可能不是区域成员（成员必须是直接成员）。

**Original**: failed to remove one or more elements. Object may not be a region member (member must be a direct member).


**参见** (See Also):

axlRegionCreate

**示例** (Examples):

Using the example from
axlRegionAdd
remove the shape:
```skill
axlRegionRemove(region  shape)
```

**Return to top** (Return to top):

⠀
X