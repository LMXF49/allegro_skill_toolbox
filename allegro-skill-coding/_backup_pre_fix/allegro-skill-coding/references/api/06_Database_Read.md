# 6. 数据库读取 (Database Read)

> **来源**: Allegro SKILL Reference, Product Version 17.4-2019, October 2019

---


**说明**：本章描述读取 Allegro PCB Editor 数据库的 AXL-SKILL 函数。

**Original**: The chapter describes the AXL-SKILL functions that read the Allegro PCB Editor database.


### axlAltSymbolList

```skill
axlAltSymbolList(
```
t_name/o_dbid
g_layer
```skill
) lt_symbols/nil
```

**描述** (Description):

**说明**：查询所提供的对象并返回替代符号名称列表。

**Original**: This queries the provided object and returns a list of alternative symbol names.


**参数** (Arguments):

t_name
Component definition or a refdes name
o_dbid
a symbol instance, component instance or compdef dbid
g_layer
‘top, 'bottom, or 'internal

**返回值** (Value Returns):

list of alternate symbols for the layer provided
nil, in case of error or if the symbol does not have a alternate symbol set

**示例** (Examples):

strings = axlAltSymbolList("U1" top)

**参见** (See Also):

axlAltSymbolReplace
,
axlAltSymbolOK
, ALT_SYMBOL property

---


### axlAltSymbolOK

```skill
axlAltSymbolOK(
```
t_name/o_dbid
g_layer
t_symbol
l_dbpoint
```skill
) => t/nil
```

**描述** (Description):

**说明**：验证符号对于元件是否合法。必须在 ALT_SYMBOL 列表中，且具有正确的层。

**Original**: This verifies that symbol is legal for component. Must be in the ALT_SYMBOL list with the correct layer.


**参数** (Arguments):

t_name
may be compdef or a refdes name
o_dbid
a symbol instance, component instance or component definition dbid
g_layer
‘top, 'bottom, or 'internal
t_symbol
name of symbol
l_dbpoint
```skill
'(x y) location on the board (optional)
```

**返回值** (Value Returns):

t
is legal
nil
error or symbol is not legal for component

**示例** (Examples):

result = axlAltSymbolOK("R1" 'top "res400")
result = axlAltSymbolOK("R1" 'top "res400" '(6400 3300))

**参见** (See Also):

axlAltSymbolList
,
axlAltSymbolReplace

---


### axlAltSymbolReplace

```skill
axlAltSymbolReplace(
```
t_name/o_dbid
t_symbol
```skill
) => t/nil
```

**描述** (Description):

**说明**：用一个允许替换的符号(ALT_SYMBOL)替换已放置的元件。要成功执行，必须满足以下条件：

**Original**: This replaces a PLACED component with one of its allowed replacements (ALT_SYMBOL). To be successful the following must be true:

**说明**：符号必须已被放置

**Original**: The symbol must already be placed

**说明**：所提供的符号对于符号所在的层必须是合法的替代选项

**Original**: The provided symbol must be a legal alternative for the layer where the symbol is placed

**说明**：替换符号、其任何焊盘堆叠以及焊盘堆叠引用的任何 Shape 或 Flash 符号必须被找到并加载到设计中，此 API 将尝试执行此操作。

**Original**: The replacement symbol, any of its padstacks and any shape or flash symbols referenced by the padstacks must be found and loaded into the design, which this API will attempt to do.

**说明**：符号实例上的文本属性以及附加文本的重新定位将被保留。

**Original**: Text properties on the symbol instance, and attached text re-positioning are preserved.


**参数** (Arguments):

t_name
may be compdef or a refdes name
o_dbid
a symbol instance, component instance or component definition dbid
t_symbol
name of replacement symbol

**返回值** (Value Returns):

t
replacement done successfully
nil
error or cannot replace

**示例** (Examples):

result = axlAltSymbolReplace("R1" "res400")

**参见** (See Also):

axlAltSymbolList
,
axlAltSymbolOK

---


### axlBackdrillGet

```skill
axlBackdrillGet(
```
o_dbidPinOrVia
```skill
) -> lt_backdrillData/nil
axlBackdrillGet(
'status
) -> g_status
```

**描述** (Description):

In one mode, it returns status of design’s backdrilling. In other mode, when a pin or a via is provided, the command returns the backdrilling result on that pin or via.
**说明**：符号不支持背钻。

**Original**: Symbols do not support backdrilling.


**参数** (Arguments):

o_dbidPinOrVia
query for backdrill on pin or via
status'
status of backdrill on design

**返回值** (Value Returns):

nil
error or pin/via is not backdrilled
g_status
returns status about design’s backdrill
nil
error
```skill
'notStarted
```
backdrill not performed on design
```skill
't
```
backdrill done and is up to date
```skill
'odd
```
backdrill done but changes make it out-of-date
lt_backdrillData
A disembodied property list having (all non strings are in user units). Refer to
Property List
Property List
holeSize
finished hole size
backdrillSize
backdrill hole size
electricalStub
max electrical stub (from the
BACKDRILL_MAX_PTH_STUB
property on net)
mfgStub
manufacturing stub from backdrill parameter dialog
If pin or via is backdrilled from top, topStartLayer is non-nil and the following attributes are set:
topStartLayer
start layer of drill (string)
topMustCutLayer
must cut layer (string)
topMustNotCutLayer
must NOT cut layer (string)
topDrillDepth
depth of backdrill from topStartLayer to immediately before topMustNotCutLayer
topRemainingStub
remaining stub after backdrill. This is from topRemainingStub to first layer with a connection (min value is manufacturing stub length)
if pin/via is backdrilled from bottom, botStartLayer is non-nil and the following attributes are set.
botStartLayer
start layer of drill (string)
botMustCutLayer
must cut layer (string)
botMustNotCutLayer
must NOT cut layer (string)
botDrillDepth
depth of backdrill from botStartLayer to immediately before botMustNotCutLayer
botRemainingStub
remaining stub after backdrill. This is from botRemainingStub to first layer with a connection (min value is manufacturing stub length)

**示例** (Examples):

Get status

---


### axlViaZLength


**语法** (Syntax):
```skill
axlViaZLength('status)
Get info on a pin or via
; ashOne is a selection utility found at
;   <cdsroot>/pcb/examples/skill/ash-fxf/ashone.il
; select a pin or via
pinvia = ashOne('("PINS" "VIAS"))
backdrill = axlBackdrillGet(pinvia)
```


**参见** (See Also):

axlViaZLength

---


### axlDBGetDesign

```skill
axlDBGetDesign()
```
⇒
o_design
/nil

**描述** (Description):

Returns the root design
```skill
dbid
```
. Use this
```skill
dbid
```
to get the design properties and to add properties to the design.
You cannot edit the root design object. AXL-SKILL edit commands ignore this
```skill
dbid
```
.
**说明**：这也允许访问设计中多种类型的 dbid 列表，如网络、元件等。

**Original**: This also allows access to lists of many types of dbid in the design, such as nets, components, and so on.

If you need to access all dbids if the same type (all nets or all components), it is more efficient to use the appropriate attribute of this dbid than to use the Selection APIs to query all elements.
To flatten attributes in lists, use the "~>" reference. For example, to get names of all nets in the design do:
netNames = axlDBGetDesign()->nets~>name

**参数** (Arguments):

None.

**返回值** (Value Returned):

o_design
Root design
```skill
dbid
```
.
nil
Error occurred.

**示例** (Example):

mydesign = axlDBGetDesign()

---


### axlDBAddProp


**语法** (Syntax):
```skill
axlDBAddProp( mydesign, list("board_thickness", 0.350))
Gets the root design and sets the
BOARD_THICKNESS
property to
0.350
inches.
To verify the property has the value specified:
From the Allegro PCB Editor menu, select
Display – Element
.
From the Find Filter, select
Drawing Select
.
The
Show
window appears, listing the current properties attached to the design.
axlDBGetDrillPlating
axlDBGetDrillPlating
t_padstackname
)
⇒ "PLATED"/"NON PLATED"/nil
```


**描述** (Description):

**说明**：检索作为参数传入的焊盘堆叠的电镀类型。

**Original**: Retrieves the plating type of the padstack passed as an argument to this function.


**参数** (Arguments):

t_padstackname
Name of padstack.

**返回值** (Value Returned):

“Plated” or “Nonplated”
Drillplating name.
nil
Incorrect padstack name, or other error occurred.

---


### axlIsDBIDType

```skill
axlIsDBIDType(
```
g_dbid
```skill
)
```
⇒ t/nil

**描述** (Description):

Determines if
g_dbid
is an Allegro PCB Editor database
```skill
dbid
```
. Returns
t
if so and
nil
otherwise.

**参数** (Arguments):

g_dbid
Variable to be checked whether a
```skill
dbid
```
or not.

**返回值** (Value Returned):

t
g_dbid
is a true Allegro PCB Editor
```skill
dbid
```
.
nil
g_dbid
is not a true Allegro PCB Editor
```skill
dbid
```
.

**示例** (Example):

Defines a function based on
axlIsDBIDType
to tell whether a symbol is an Allegro PCB Editor
```skill
dbid
```
or not. Then creates an
r_path
```skill
(which is not an Allegro PCB Editor
dbid
```
, because
paths
are only temporary building structures) and uses the
r_path
to create an Allegro PCB Editor line (which is an Allegro PCB Editor
```skill
dbid
). Shows whether each is a true
dbid
```
.
```skill
defun( isItDBID (testDBID)
"Print whether testDBID is a true Allegro dbid"
```
if( axlIsDBIDType( testDBID)
then
println( "This is an Allegro DBID.")
else
println( "This is NOT an Allegro DBID.") ) )
mypath = axlPathStart( list(100:500))

---


### axlPathLine


**语法** (Syntax):
```skill
axlPathLine( mypath, 0.0, 200:250)
myline = axlDBCreatePath( mypath, "etch/top" nil)
isItDBID(mypath)
isItDBID(caar(myline))
The function prints the following:
"This is NOT an Allegro DBID."
"This is an Allegro DBID."
```


---


### axlDBGetAttachedText

```skill
axlDBGetAttachedText(
```
o_dbid
```skill
)
```
⇒
l_dbid
/nil

**描述** (Description):

Returns the list of
```skill
dbids
```
of text objects attached to the object whose
```skill
dbid
```
is
o_dbid
. If
axlDBGetDesign
is used to retrieve the dbid, the function returns all text attached to root design.

**参数** (Arguments):

o_dbid
```skill
dbid
```
of object from which attached text
```skill
dbids
```
are retrieved.

**返回值** (Value Returned):

l_dbid
List of the text objects attached to
o_dbid
.
nil
**说明**：没有附加的文本对象。

**Original**: No attached text objects.


**示例** (Example):

```skill
(defun showText ()
"Print text of selected objects"
```
mypopup = axlUIPopupDefine( nil

---


### axlUIPopupSet


**语法** (Syntax):
```skill
axlUIPopupSet( mypopup)
axlSetFindFilter( ?enabled list("noall")
?onButtons "noall")
axlSetFindFilter( ?enabled list("symbols")
?onButtons "symbols")
axlOpenFindFilter()
(while (axlSelect)
progn(
alltext =
axlDBGetAttachedText(car(axlGetSelSet()))
foreach(thistext alltext
printf( "Text on this symbol is : '%s'\n",
thistext->text))))
axlCloseFindFilter())
Lets the user pick a symbol, then prints the text attributes of each text object attached to that symbol.
Run
showText()
and pick a symbol of device type
"74F74",
assigned as
refdes
"T23".
The function prints the following:
Text on this symbol is : 'T23'
Text on this symbol is : '74F74'
```


---


### axlDBGetPad

```skill
(list (list "Done" 'axlFinishEnterFun)
(list "Cancel" 'axlCancelEnterFun)))
axlDBGetPad(
```
o_dbid
t_layer
t_type
```skill
)
```
⇒
o_pad
/nil

**描述** (Description):

For the pin or via specified by
o_dbid
, gets the pad of type
t_type
associated with layer
t_layer
.
**说明**：SMD 焊盘没有默认的内部层。

**Original**: smd pads do not have a default internal layer.

**说明**：获取相邻层 keepout 焊盘：

**Original**: To obtain the adjacent layer keepout pad:

```skill
axlDBGetPad(dbid 'adjacent "KEEPOUT")
```

**参数** (Arguments):

o_dbid
```skill
dbid
```
of the pin, via, or a padstack definition.
t_layer
String or symbol of a layer desired.
Format for regular layers:
```skill
"ETCH/TOP"
"TOP"
```
Mask layers must use class of pin or via class:
```skill
"PIN/SOLDERMASK_TOP"
```
Coverlay pads specify by
```skill
"COVERLAY_TOP"
```
or
```skill
"COVERLAY_BOTTOM"
```
Special layers:
```skill
'internal
```
- default internal layer (not present on SMD padstacks)
```skill
'composite
```
- sum of all the layers (worse case) this option ignores the t_type argument
```skill
'adjacent
```
– adjacent layer keepout option
```skill
'backdrillStart
```
type="REGULAR"  – larger pad for drill start layer (positive)
type="ANTI"  – larger pad for drill start layer (negative layers)
```skill
'backdrillClearance
```
type="ANTI" – pad size for internal backdrill layers for negative layers
type="KEEPOUT" – generate a KEEPOUT for positive layers for backdrill layers.
```skill
'backdrillSoldermask
```
– soldermask pad to substitute for drill start layer
t_type
Type of pad to retrieve:
```skill
"REGULAR",
"ANTI",
"THERMAL"
```
, or
```skill
"KEEPOUT".
```

**返回值** (Value Returned):

o_pad
```skill
dbid
```
of the pad of the type associated with
o_dbid
on the layer specified.
nil
Cannot get the pad
```skill
dbid
```
.

**示例** (Example):

Lets the user pick any pin or via and shows the figureName attribute of the selected pad.
```skill
(defun showPad ()
```
mypopup = axlUIPopupDefine( nil (list (list "Done" 'axlFinishEnterFun)                                 (list "Cancel" 'axlCancelEnterFun)))

---


### axlUIPopupSet


**语法** (Syntax):
```skill
axlUIPopupSet( mypopup)
axlSetFindFilter( ?enabled list("noall") ?onButtons "noall")                 axlSetFindFilter( ?enabled list("pins" "vias")?onButtons list("pins" "vias"))
(while  axlSelect()
progn(mypad = axlDBGetPad(car(axlGetSelSet()) "etch/top" "regular")
printf( "Pad figure type : %s\n", mypad->figureName)))
To fetch default internal regular pad:
r = axlDBGetPad(car(axlGetSelSet() 'internal "REGULAR")
Run showPad() and pick a pin with a square pad on "etch/top", then a circular pad. The function prints the following:
Pad figure type : SQUARE
Pad figure type : CIRCLE
```


---


### axlDBGetPropDict

```skill
axlDBGetPropDict(
```
S_filter/nil
```skill
) -> lt_propNames
```

**描述** (Description):

Returns a list of property definitions in the current design. Several trivial filters are defined:
nil
– visible Allegro and user-defined properties
allegro
– visible Allegro properties. Product tiering results in filtering of these properties.
user
– visible user-defined properties.
invisible
– Invisible Allegro properties, these are application internal properties.

**参数** (Arguments):

S_filter
Symbol or string requesting a list of property types

**返回值** (Value Returned):

lt_propNames
List of names (unsorted) or
nil

**示例** (Examples):

```skill
axlDBGetPropDict('user) -> list of names
```

**参见** (See Also):

axlDBGetPropDictEntry

---


### axlDBGetPropDictEntry

```skill
axlDBGetPropDictEntry(
```
t_name
```skill
)
```
⇒
o_propDictEntry
/nil
```skill
axlDBGetPropDictEntry(
```
nil
```skill
)
```
==> lt_validObjects

**描述** (Description):

Gets the property dictionary entry for the property name given by the string
t_name
. Use
axlDBGetPropDictEntry
to get the information about a property dictionary entry. If name is
nil
, the command returns a list of legal objects that can be used to create property dictionary entries. This is the
objects
attribute of the
o_propDictEntry
data type. You cannot create a property with the same name as an existing Allegro property.

**参数** (Arguments):

t_name
String specifying the name of the property whose dictionary entry is to be retrieved.

**返回值** (Value Returned):

o_propDictEntry
```skill
dbid
```
of the property dictionary entry for the property whose name is given by
t_name
. If could not get the entry, it returns nil.
lt_validObjects
List of valid objects to associate with a property
nil
Could not get the entry.

**参见** (See Also):

axlDBAddProp

**示例** (Example):

The following example gets the
```skill
"SIGNAL MODEL"
```
property, and dumps its attributes.
myprop = axlDBGetPropDictEntry("SIGNAL_MODEL")
myprop->??
```skill
(write nil useCount 0 units nil
```
range nil objType "PropDict"
name "SIGNAL_MODEL"
dataType "STRING"
readOnly t

---


### axlDBGetProperties

```skill
)
axlDBGetProperties(
```
o_dbid
[
lt_type
]
```skill
)
```
⇒
l_result
/nil

**描述** (Description):

Gets the properties attached to a specified object. Returns the properties in an assoc list, that is, a list of lists, each of which contains a name and a value. The SKILL
assoc
function can operate using this list.

**参数** (Arguments):

o_dbid
```skill
dbid
```
of the object from which to get the properties.
lt_type
List of strings qualifying the types of properties to be retrieved from
o_dbid
.
```skill
"user"
```
means retrieve user-defined properties only.
```skill
"allegro"
```
means retrieve Allegro PCB Editor defined properties only.
nil
means retrieve both user and Allegro PCB Editor.

**返回值** (Value Returned):

l_result
List of name-value pairs. For each name-value pair:
```skill
(
```
car
```skill
) is the property name
(
```
cadr
```skill
) is the property value, including units.
```
nil
**说明**：未找到属性。

**Original**: No properties found.


**示例** (Example):

The following example selects the component with refdes "U1," gets its properties using the axlDBGetProperties command, and prints the associated property list it returns. The properties are:
ROOM with value D
DFA_DEV_CLASS with value DIP
LEAD_DIAMETER with value 23 mil.

---


### axlClearSelSet


**语法** (Syntax):
```skill
axlClearSelSet()
axlSetFindFilter(?enabled '("noall" "alltypes") ?onButtons "alltypes")
axlSingleSelectName("component" "U1")
myprops = axlDBGetProperties(car(axlGetSelSet()) '("user" "allegro"))
print myprops
==> ((ROOM "D")
(DFA_DEV_CLASS "DIP")
(LEAD_DIAMETER "23 MIL"))
```


---


### axlDBGetDesignUnits

```skill
axlDBGetDesignUnits()
```
⇒
l_value
/nil

**描述** (Description):

**说明**：返回当前设计的单位字符串、精度数值和 dbuperuu。

**Original**: Returns the design units string, accuracy number, and dbuperuu of the active design.


**参数** (Arguments):

None.

**返回值** (Value Returned):

l_value
List containing the design units as a string, the accuracy number as an integer, and dbuperuu as an integer
nil
**说明**：无法返回当前设计的单位、精度和 dbuperuu。

**Original**: Failed to return the design units, accuracy number, and dbuperuu of the active design.


**示例** (Example):

The design Drawing Parameter form shows
User Units
as
Millimeter
and
Accuracy
as
.
```skill
axlDBGetDesignUnits() ==> ("millimeters" 3 1000)
```
The design is setup in
Microns
to use DBUperUU of
2000.

---


### axlDBRefreshId

```skill
axlDBGetDesignUnits() ==> ("microns" 4 2000)
axlDBRefreshId(
```
o_dbid
/nil
```skill
)
```
⇒
o_dbid
/nil

**描述** (Description):

Updates the attributes of the object specified by
o_dbid
. Subsequent attribute retrieval requests access the updated information.
This does NOT update the Allegro database. It updates the cached dbid view of objects in SKILL.
Because of performance considerations, refreshes only the object itself. If the object being refreshed has
```skill
dbids
```
in any of its attributes, those
```skill
dbids
```
are not refreshed. For example, a net branch has
children
, a list of paths, tees, vias, pins, and shapes. If another path is added to that list of paths due to connectivity change,
axlDBRefreshId
of the branch does not update the
children
. If you move a via that is a child of the branch, then doing
axlDBRefreshId
of the branch and accessing the via as child of branch may yield incorrect attributes of that child (via in this case).

**参数** (Arguments):

o_dbid
SKILL list of
```skill
dbids
```
of the objects whose attributes are to be refreshed.
nil
All ids are refreshed.
Refreshing all ids may cause performance problems if done indiscriminately.

**返回值** (Value Returned):

o_dbid
Refreshed
```skill
dbid
```
.
nil
**说明**：无法刷新。

**Original**: Could not refresh.


**示例** (Example):


---


### axlSetFindFilter


**语法** (Syntax):
```skill
axlSetFindFilter( ?enabled
'("noall" "alltypes"))
axlSingleSelectName("net" "sclkl")
mynet = car(axlGetSelSet())
mybranch = car(mynet->branches)
mychildren = mybranch->children
foreach( thismember mychildren
if( (thismember->objType == "via")
then
axlDeleteObject(thismember)))
axlDBRefreshId(mybranch)
⇒ t
Finds
net
"sclkl",
walks all members of its first branch, deleting any vias. Then refreshes the branch.
If the refresh was not done,
mybranch
would still report having vias following the operation that deleted its vias.
```


---


### axlDBGetLonelyBranches

```skill
axlDBGetLonelyBranches()
```
⇒
l_dbid
/nil

**描述** (Description):

Returns a list of the
standalone branch
```skill
dbids
```
in the design. A
standalone branch
is a branch not associated with any net.

**参数** (Arguments):

None.

**返回值** (Value Returned):

l_dbid
**说明**：独立分支列表。

**Original**: List of standalone branches.

nil
**说明**：未找到独立分支。

**Original**: No standalone branches found.


**示例** (Example):

```skill
(axlDBGetLonelyBranches)
```
⇒(dbid:12051156 dbid:11994768 dbid:12002292 dbid:12000892 dbid:11999396
dbid:11996652 dbid:11996048 dbid:11994476 dbid:11992964 dbid:11991564
dbid:11989672 dbid:11989344 dbid:12072172 dbid:11895392 dbid:11892048
dbid:11888704 dbid:11888744 dbid:11888804 dbid:11888844 dbid:11888884
dbid:12074948 dbid:11888984 dbid:11889064 dbid:11889204 dbid:11889224
dbid:11889856 dbid:11890036 dbid:11890056 dbid:11890236 dbid:11890256
dbid:11886180 dbid:12011360 dbid:11886760 dbid:11887140 dbid:11887916 )
Gets list of standalone branch
```skill
dbids
```
.

---


### axlDBGetConnect

```skill
axlDBGetConnect(
```
o_dbid
[t_full]
```skill
)
```
⇒
l_result/
nil

**描述** (Description):

Finds all the elements, including pads and shapes, that are connected to a given
```skill
dbid
```
. Input can be a PIN, VIA, T, CLINE/CARC or CLINE/CARC SEGMENT, and shapes.
If the second argument is
nil
or is not present:
For pins, vias or Ts, the function returns a list of connected clines.
For path (clines) or line/arc (segments) returns list of objects connected to either end.
For shapes same as t_full=t
If the second argument is set to
t
,:
For pins, vias and T, the command returns full connectivity which includes clines, shapes, pins, vias or T's.
For path (clines) or line/arc (segments) return value is same as
t_full=nil
For shapes list of connected objects which may be clines, shapes, pins, vias or T's.
You should set
t_fill
to
t
. The
nil
option operates in its mode due to legacy considerations and is used by Allegro Package Designer applications.
If a segment is passed as an argument, the command does not report inter-path connectivity. Thus only the first and last segment of a path report any connectivity. Internal segments of a path always return nil. This is because the Allegro database connectivity model guarantees that internal segments are always connected to their adjacent segments. The list of segments reported in a path (cline) dbid is how the individual segments are connected.

**参数** (Arguments):

o_dbid
A
```skill
dbid
```
, path (cline), line/arc (segment), shape, pin, via or T.
t_full
t
: For full connectivity of pins, vias, or Ts.
nil
: Returns connectivity including any connected SHAPES. Also supports segments.

**返回值** (Value Returned):

l_result
List of
```skill
dbids
```
connected to
o_dbid
.
If o_dbid is a CLINE or SEGMENT, then
l_result = (list list1 list2)
where list1 = nil or elements connected to the first end list2 = nil or elements connected to the second end.
For all other objects, returns a list of connections.
nil
Nothing connected to
o_dbid
.

---


### axlDBIsBondpad

```skill
axlDBIsBondpad(
```
o_dbid
```skill
)
```
⇒ t/nil

**描述** (Description):

Verifies whether or not the given element is a
bondpad
.
A
bondpad
```skill
(or
```
bondfinger
```skill
) is a
```
“via”
with the
BOND_PAD
property.

**参数** (Arguments):

o_dbid
```skill
dbid
```
of the element to be checked.

**返回值** (Value Returned):

t
o_dbid
is a bondpad.
nil
o_dbid
is not a bondpad.

---


### axlDBIsBondwire

```skill
axlDBIsBondwire(
```
o_dbid
```skill
)
```
⇒ t/nil

**描述** (Description):

Verifies whether or not the given element is a
bonding wire
.
**说明**：键合线是一种 3D 线对象，将芯片焊盘连接到手指、电源环或另一个芯片焊盘。

**Original**: A bonding wire is a 3D wire object connecting a die pad to either a finger, power ring, or another die pad.


**参数** (Arguments):

o_dbid
```skill
dbid
```
of the element to check.

**返回值** (Value Returned):

t
o_dbid
is a bonding wire.
nil
o_dbid
is not a bonding wire.

---


### axlDBIsFixed

```skill
axlDBIsFixed(
```
o_dbid
[
g_showMessage
]
```skill
)
```
⇒ nil or [
```skill
dbid
```
of 1st element that makes the item fixed]

**描述** (Description):

Verifies whether or not the specified database object is fixed. When the FIXED property is present if can either be directly on the object, on a parent (for example, a CLINE is fixed if the NET is fixed) or on a child (for example, a symbol is fixed if its place bounds is fixed).
**说明**：对象可以通过以下方式固定：

**Original**: An object can be fixed by the following:

Object has the
FIXED
property or its parent or child objects have the
FIXED
property. For example, group symbol.
**说明**：对象（父或子）具有私有数据库固定属性。

**Original**: The object (parent or child) has a private database fixed attribute.

**说明**：对象为只读（通常由于启用了分区）。

**Original**: Object is Read-only (typically due to partition enabled).

Object is a symbol with test points and the
FIXED
test point flag is set.
Object is a pin or via with a test point and
FIXED
test point flag is set.
Object is a symbol and has one or more children with the
FIXED
property.
Returns the first item found that causes the element to be fixed (could be more then one).
Using
axlDBCloak
with its
```skill
'ignoreFixed
```
option is recommended.

**参数** (Arguments):

o_dbid
```skill
dbid
```
of the element to check.
g_showMessage
Use
t
to have Allegro PCB Editor display the message if the item is fixed or
nil
to have no message displayed.

**返回值** (Value Returned):

```skill
dbid
dbid
```
of the element causing the object to be fixed.
nil
**说明**：对象未固定。

**Original**: Object is not fixed.


**示例** (Example):

p = axlSelectByname("SYMBOL" "U1")
ret = axlDBIsFixed(p)

**参见** (See Also):

axlDBIgnoreFixed
, axlDBIsReadOnly,
axlDBCloak

---


### axlDBIsPackagePin

```skill
axlDBIsPackagePin(
```
rd_dbid
```skill
)
```
⇒ t/nil

**描述** (Description):

Verifies whether or not the given element is a
package pin
.
A
package pin
is a pin with a component class of
IO
.

**参数** (Arguments):

rd_dbid
```skill
dbid
```
of element to check.

**返回值** (Value Returned):

t
rd_dbid
is a package pin.
nil
rd_dbid
is not a package pin.

---


### axlDBViaStack

```skill
axlDBViaStack(
```
o_dbidVia
```skill
)
```
⇒ l_result

**描述** (Description):

Returns stacked vias that are located at the location of the provided via. Vias are ordered from top to bottom and includes the provided via.

**注意** (Notes):

Allegro does not store stacked vias but determines it based on a calculation. Future versions of Allegro may store stacked vias in the database or the algorithm may change.

**参数** (Arguments):

o_dbidVia
A via

**返回值** (Value Returned):

nil
**说明**：无堆叠或非过孔

**Original**: No stack or not a via

l_dbidVias
**说明**：堆叠中的过孔列表

**Original**: List of vias in the stack


---


### axlGetModuleInstanceDefinition

```skill
axlGetModuleInstanceDefinition(
```
o_modinst
```skill
)
```
⇒
t_moddef
/nil

**描述** (Description):

**说明**：AXL 到 C 函数的接口，返回用于创建模块实例的模块定义名称。

**Original**: AXL interface to the C function that returns the name of the module definition used to create the module instance.


**参数** (Arguments):

o_modinst
AXL
```skill
dbid
```
of the module instance (the
```skill
dbid
```
returned by
axlDBCreateModuleInstance
.)

**返回值** (Value Returned):

t_moddef
**说明**：包含模块定义名称的字符串。

**Original**: String containing the name of the module definition.

nil
**说明**：无法访问该信息。

**Original**: Could not access the information.


**示例** (Example):


---


### axlSetFindFilter


**语法** (Syntax):
```skill
axlSetFindFilter(?enabled '("noall" "groups") ?onButtons '("noall" "groups" ))
axlSingleSelectName("GROUP" "inst")
modinst = car(axlGetSelSet())
axlGetModuleInstanceDefinition(modinst)
= "mod"
Gets the definition of a module instance named
inst
.
```


---


### axlGetModuleInstanceLocation

```skill
axlGetModuleInstanceLocation(
```
o_modinst
```skill
)
```
⇒
l_loc
/nil

**描述** (Description):

**说明**：AXL 到 C 函数的接口，获取模块实例在设计中的当前位置。

**Original**: AXL interface to the C function that gets the current location of the module instance in the design.


**参数** (Arguments):

o_modinst
AXL
```skill
dbid
```
of the module instance (the
```skill
dbid
```
returned by
axlDBCreateModuleInstance
.)

**返回值** (Value Returned):

l_loc
List of data describing the location of the module instance. The list syntax is as follows.
list(l_origin, x_rotation [g_mirror])
where
l_origin: origin of module
x_rotation: rotation in degress * 1000
[g_mirror]: Is a n optional parameter, which is set to
t
when mirrored

**示例** (Example):


---


### axlSetFindFilter


**语法** (Syntax):
```skill
axlSetFindFilter(?enabled '("noall" "groups") ?onButtons '("noall" "groups" ))
axlSingleSelectName("GROUP" "inst")
modinst = car(axlGetSelSet())
axlGetModuleInstanceLocation(modinst)
--> ((500 1500) 0)
Gets the location of a module instance named
inst
.
```


---


### axlGetModuleInstanceLogicMethod


---


### axlGetModuleInstanceMethod


**语法** (Syntax):
```skill
axlGetModuleInstanceMethod(
o_modinst
)
⇒
i_logic
/nil
```


**描述** (Description):

**说明**：AXL 到 C 函数的接口，确定模块实例使用的逻辑方法。

**Original**: AXL interface to the C function that determines the logic method used by the module instance.


**参数** (Arguments):

o_modinst
AXL
```skill
dbid
```
of the module instance (the
```skill
dbid
```
returned by
axlDBCreateModuleInstance
.)

**返回值** (Value Returned):

i_logic
Value of the logic method flag for the module instance. Legal values are:
- no logic
- logic from schematic
- logic from module definition
nil
**说明**：无法访问该信息。

**Original**: Could not access the information.


**示例** (Example):


---


### axlSetFindFilter


**语法** (Syntax):
```skill
axlSetFindFilter(?enabled '("noall" "groups") ?onButtons '("noall" "groups" ))
axlSingleSelectName("GROUP" "inst")
modinst = car(axlGetSelSet())
axlGetModuleInstanceLogicMethod(modinst)
= 2
Gets the logic method of a module instance named
inst
.
```


---


### axlGetModuleInstanceNetExceptions

```skill
axlGetModuleInstanceNetExceptions(
```
o_modinst
```skill
)
```
⇒
l_nets
/nil

**描述** (Description):

**说明**：AXL 到 C 函数的接口，获取设计中模块实例的网络例外。

**Original**: AXL interface to the C function that gets the net exception of the module instance in the design.


**参数** (Arguments):

o_modinst
AXL
```skill
dbid
```
of the module instance (the
```skill
dbid
```
returned by
axlDBCreateModuleInstance
.)

**返回值** (Value Returned):

l_nets
**说明**：在模块实例中被视为例外的网络名称列表。

**Original**: List of names of the nets that are treated as exceptions in the module instance.

nil
**说明**：无法访问该信息。

**Original**: Could not access the information.


**示例** (Example):


---


### axlSetFindFilter


**语法** (Syntax):
```skill
axlSetFindFilter(?enabled '("noall" "groups") ?onButtons '("noall" "groups" ))
axlSingleSelectName("GROUP" "inst")
modinst = car(axlGetSelSet())
axlGetModuleInstanceNetExceptions(modinst)
= ("GND" "+5")
Gets the list of net exceptions of a module instance named
inst
.
```


---


### axlIsDummyNet

```skill
axlIsDummyNet(
```
net_dbid
```skill
)
```
⇒ t/nil

**描述** (Description):

Determines if a given net is a Dummy net. Name of net is an empty string ("").

**参数** (Arguments):

net_dbid
Net database object.

**返回值** (Value Returned):

t
net_dbid
is a Dummy Net.
nil
net_dbid
is not a Dummy Net.

**参见** (See Also):

axlIsPinUnused

---


### axlIsLayerNegative

```skill
axlIsLayerNegative(
```
t_layerName
```skill
)
```
⇒ t/nil

**描述** (Description):

**说明**：确定给定平面层是否为负片。

**Original**: Determines whether or not the given plane layer is negative.


**参数** (Arguments):

t_layerName
Name of the conductor layer to check.

**返回值** (Value Returned):

t
**说明**：活动层为负片。

**Original**: Active layer is negative.

nil
Active layer is not negative or is not an
ETCH
layer.

**参见** (See Also):

axlXSectionGet

**示例** (Examples):

Tests if layer named GND is negative

---


### axlIsPinUnused

```skill
axlIsLayerNegative("GND")
axlIsPinUnused(
```
pin_dbid
```skill
)
```
⇒ t/nil

**描述** (Description):

**说明**：确定给定引脚是否未使用，表示它在 dummy net 上。

**Original**: Determines if the given pin is unused, indicating that it is on a dummy net.


**参数** (Arguments):

pin_dbid
Pin database object.

**返回值** (Value Returned):

t
**说明**：引脚未使用。

**Original**: Pin is unused.

nil
**说明**：引脚已使用。

**Original**: Pin is used.


**参见** (See Also):

axlIsDummyNet

---


### axlIsitFill

```skill
axlIsitFill(
```
t_layer
```skill
)
```
⇒ t/nil

**描述** (Description):

**说明**：确定给定 class/subclass 是否允许填充 Shape。

**Original**: Determines if fill shape is allowed for a given class subclass.


**参数** (Arguments):

t_layer
Layer name, for example,
ETCH/TOP
.

**返回值** (Value Returned):

t
**说明**：允许填充 Shape。

**Original**: Fill shape is allowed.

nil
**说明**：不允许填充 Shape。

**Original**: Fill shape is not allowed.


---


### axlOK2Void

```skill
axlOK2Void(
```
t_layer
```skill
)
```
⇒ t/nil

**描述** (Description):

Determines if voids are allowed for a given
class/subclass
. Determines if a layer supports voids for shapes.

**参数** (Arguments):

t_layer
Layer name, for example,
ETCH/TOP
.
or
just class name ("ETCH")

**返回值** (Value Returned):

t
**说明**：允许 voids。

**Original**: Voids are allowed.

nil
**说明**：不允许 voids。

**Original**: Voids are not allowed.


**示例** (Example):


---


### axlDBDynamicShapes

```skill
axlOK2Void("ETH/TOP")
axlDBDynamicShapes(
```
g_value
```skill
)
```
⇒ x_count

**描述** (Description):

Queries and updates dynamic shapes. When
g_value
is
t,
updates all out of date dynamic shapes on the board regardless of the dynamic shape updating setting in the
Drawing Options
dialog. When
g_value
is
nil
, returns a count of out of date shapes.

**参数** (Arguments):

g_value
t
= update dynamic shapes
nil
= return count of out of date shapes

**返回值** (Value Returned):

x_count
Count of out of date shapes. If updating shapes,
x_count
is the number of out of date shapes before the update.

---


### axlDBGetShapes

```skill
axlDBGetShapes(
```
t_layer
```skill
)
```
⇒ l_dbid/nil

**描述** (Description):

**说明**：提供对 Shape 的快速访问，无需访问可见性或查找设置。

**Original**: Provides quick access to shapes without access to visibility or find settings.


**参数** (Arguments):

t_layer
Layer name
nil
= all layers
<
class
> = all subclasses of the class
<
class
>/<
subclass
> = specified layer
shape_islands_rpt
To output the same list as the Shape Islands Report. Optional.

**返回值** (Value Returned):

l_dbid
List of shapes.
nil
**说明**：参数不正确。

**Original**: Incorrect argument.

Examples:
Returns all shapes on the design.
```skill
axlDBGetShapes(nil)
```
Returns all shapes on the BOUNDARY layer.
```skill
axlDBGetShapes("BOUNDARY")
```
Returns all shapes on ETCH GND.
```skill
axlDBGetShapes("ETCH/GND")
```
Returns all shapes on ROUTE KEEPOUT.

---


### axlDBTextBlockCompact

```skill
axlDBGetShapes("ROUTE KEEPOUT")
axlDBTextBlockCompact(
```
t/nil
```skill
)
```
⇒ x_unusedBlocks

**描述** (Description):

Reports and/or compresses unused database text blocks. If compacting text blocks, it always updates database text to reflect the new text block numbers.
The database, even if new, must have at least one text block.
You must force a
```skill
dbid
```
refresh on any text parameters and text type
```skill
dbids
```
in order for them to reflect the new numbering.

**参数** (Arguments):

t
Compact the text blocks.
nil
Report the number of text blocks that can be eliminated from the database.

**返回值** (Value Returned):

x_unusedBlocks
Count of text blocks that are unused.

**示例** (Example):

unused = axlDBTextBlockCompact(nil)
printf("This database has %d unused text blocks\n" unused)

---


### axlShapeArea

```skill
axlShapeArea(
```
g_mode
o_shapeId
```skill
)
```
⇒ nil/f_area

**描述** (Description):

Area of a shape. Subtracts voids and treats xhatch and unfilled shapes as solid.
If using the axl Polygon APIs, the area of the polygons are already part of the polygon structures.

**参数** (Arguments):

g_mode
Must be nil
o_shapeId
Dbid of a shape, rectangle or void

**返回值** (Value Returned):

nil
**说明**：不是 Shape

**Original**: Not a shape

f_area
**说明**：以设计单位平方表示的 Shape 面积

**Original**: Area of shape in square design units


---


### axlShapeExistDegasOutOfDate

```skill
axlShapeExistDegasOutOfDate(
)
```
⇒ t/nil

**描述** (Description):

**说明**：检查设计中任何非延迟 degassed Shape 是否已过期。

**Original**: Checks if any of the nondeferred degassed shapes in the design are out of date.


**返回值** (Value Returned):

t/nil

**参见** (See Also):

axlShapeIsDegasOutOfDate
,
axlShapeGetDegasOutOfDateCount

---


### axlShapeGetDegasOutOfDateCount

```skill
axlShapeGetDegasOutOfDateCount(
)
```
⇒ n_count

**描述** (Description):

**说明**：返回已过期的非延迟 degassed Shape 的数量。

**Original**: Returns the count of nondeferred degassed shapes that are out of date.


**返回值** (Value Returned):

n_count

**参见** (See Also):

axlShapeIsDegasOutOfDate
,
axlShapeExistDegasOutOfDate

---


### axlShapeIsDegasOutOfDateCheckDisabled

```skill
axlShapeIsDegasOutOfDateCheckDisabled(
)
```
⇒ t/nil

**描述** (Description):

Returns
t (TRUE)
if out-of-date check for degassed shapes is disabled.

**返回值** (Value Returned):

t/nil

---


### axlShapeIsDegasOutOfDate

```skill
axlShapeIsDegasOutOfDate(
```
o_shape
```skill
)
```
⇒ t/nil

**描述** (Description):

**说明**：检查指定的非延迟 degassed Shape 是否已过期。

**Original**: Checks if the specified nondeferred degassed shape is out of date.


**参数** (Arguments):

o_shape
```skill
dbid of the specified shape.
```

**返回值** (Value Returned):

t/nil

**参见** (See Also):

axlShapeUpdateDegas

---


### axlStepGet

```skill
axlStepGet(
```
g_operation
g_mapType
t_name/o_dbid
```skill
) -> g_return/nil
```

**描述** (Description):

**说明**：获取对象上的 STEP 映射数据。

**Original**: Obtains STEP mapping data on an object.

STEP Attributes
Attributes with Modify of "Yes" are recognized by
axlStepSet
.
NAME
TYPE
Modify
DESCRIPTION
objectType
string
No
```skill
"step”
```
offset_x
double
Yes
Mapping offset in X direction (in design units)
offset_y
double
Yes
Mapping offset in Y direction (in design units)
offset_z
double
Yes
Mapping offset in Z direction (in design units)
rotation_x
double
Yes
Rotation in degrees in X direction
rotation_y
double
Yes
Rotation in degrees in Y direction
rotation_z
double
Yes
Rotation in degrees in z direction
color
int
Yes
This is the override color for the step model.
A value of 0 indicates, the color(s) are taken from the STEP file but not all STEP models have color. Otherwise this is an index into Allegro's color table (see axlColorGet). This value is ignored if the STEP model has color.
step_name
string
No
Step model (relative path)
type
symbol
No
can be 'primary or 'alt

**参数** (Arguments):

g_operation
nil - fetch mapping data
```skill
'map - return type of mapping (ignores the g_type argument)
```
g_mapType
should be 'primary or 'alt (a nil is equiv to 'primary)
t_name
may be compdef or a symdef name
o_dbid
a symdef or compdef. For a .
dra
file this should be nil

**返回值** (Value Returned):

nil
Error or object has no STEP association
if g_operation=='map
If object has a STEP association return a list of its current mappings.This list will have 'primary and/or 'alt symbols.
nil no STEP associated with object
if g_operation == nil
Returns nil if no STEP associated with object and mapType
Otherwise returns a disembodied property list of mapping attributes (see
STEP Attributes
```skill
)
```

**参见** (See Also):

axlStepSet, axlStepDelete, axlColorGet

**示例** (Examples):

If a .
dra
design STEP assignment for primary
result = axlStepGet(nil 'primary nil)
Get primary assignment in a .
brd
for a symbol definition name
result = axlStepGet(nil 'primary "CAP10X16MM-RAD")
Report STEP assignments types for same symdef
result = axlStepGet('map nil "CAP10X16MM-RAD")
Report STEP assignments types for same component definition
result = axlStepGet('map nil "CAP")
Report STEP assignments types for same component definition
result = axlStepGet('map nil "CAP")
Report STEP assignments types for same component definition using a dbid of a compdef
refdes = axlDBFindByName('refdes "C1")
result = axlStepGet('map nil refdes->compdef)
Report STEP assignments types for same component definition using a dbid of a symdef
refdes = axlDBFindByName('refdes "C1")
```skill
; make sure refdes is placed
```
when(refdes->symbol
result = axlStepGet('map nil refdes->symbol->definition))

---


### axlStepMappedInstance

```skill
axlStepMappedInstance(
```
t_name/o_dbid
```skill
) -> t/nil
```

**描述** (Description):

**说明**：返回符号或元件实例是否具有 STEP 关联。

**Original**: This returns if a symbol or a component instance has a STEP association.


**参数** (Arguments):

t_name
Is a refdes
o_dbid
A symbol or component instance

**返回值** (Value Returned):

t
**说明**：具有 STEP 模型

**Original**: Has a STEP model

nil
**说明**：没有模型（或错误）

**Original**: Does not have a model (or error)


**参见** (See Also):

axlStepGet

**示例** (Example):

See if refdes C1 has a STEP model
result = axlStepMappedInstance("C1")

---


### axlZoneAccess

```skill
axlZoneAccess(
```
g_option
g_arg
```skill
) -> lt_types
```

**描述** (Description):

**说明**：提供多个用于区域的杂项访问功能：

**Original**: This provides several miscellaneous access functions for zones:

```skill
'name
```
Find zone by name, requires a string for the zone name.
Return is o_zoneDbid.
`point
Given a point as the second argument returns the zone enclosing this point, return is xy.
```skill
'trim
```
Given a zone name or dbid as the second argument trim the zone outline to other zones and the design outline.

**参数** (Arguments):

g_option
A symbol (see above)
g_arg
This argument is depends upon the option

**返回值** (Value Returned):

t
If successful
nil
If failed
others
Returns depends upon option (see above)

**参见** (See Also):

axlZoneCreate
,
axlGeoPointInShape

**示例** (Examples):

Find zone with name ZONE_1
zone = axlZoneAccess('name "ZONE_1")
Find zone at a point
zone = axlZoneAccess('point 3485:-1295.0)
Trim the zone outline (using first example)
result = axlZoneAccess('trim zone)

**Return to top** (Return to top):

⠀
X