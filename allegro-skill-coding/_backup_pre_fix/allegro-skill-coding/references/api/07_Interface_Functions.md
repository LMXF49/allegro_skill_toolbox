# 7. 界面函数 (Interface Functions)

> **来源**: Allegro SKILL Reference, Product Version 17.4-2019, October 2019

---


Allegro PCB Editor Interface Functions

**概述** (Overview):

This chapter describes the AXL/SKILL functions that give access to the Allegro PCB Editor interface. These include display control, cursor setup, and soliciting user input, such as text and mouse picks.
AXL-SKILL Interface Function Examples
**说明**：本节给出以下示例：

**Original**: This section gives examples of the following:

Dynamic cursor functions used with the
axlEnter
functions
axlCancelEnterFun
and
axlFinishEnterFun
used with the popup functions in a command looping on the
axlEnterPath
command
axlHighlightObject
and
axlDehighlightObject
**说明**：动态光标示例

**Original**: Dynamic Cursor Examples

You use the AXL-SKILL dynamic cursor functions to build up and display Allegro PCB Editor database objects during interactive commands. Using dynamic cursor shows the effects of a command in use. For example, you can display a symbol and the etch lines connected to it, constantly showing where they would be in the drawing if the user clicked at their current position.
**说明**：以下两个示例展示如何设置动态光标：

**Original**: The two examples that follow show how to set up the dynamic cursor:

**说明**：封装符号图像，其引脚连接到其他蚀刻，从其连接引脚到原始连接点的橡皮筋线

**Original**: A package symbol image with pins connected to other etch, with rubberband lines from its connected pins to the points where they had originally connected

**说明**：动态旋转的封装符号图像，使您可以选择旋转角度

**Original**: A package symbol image dynamically rotating enabling you to select an angle of rotation

Both examples use the
axlPath
functions described in
Chapter 15, “Database Create Functions,”
and the
axlAddSimpleXXXDynamics
functions described in this chapter.
**说明**：示例 1：动态橡皮筋

**Original**: Example 1: Dynamic Rubberband

**说明**：此示例加载两个圆形焊盘、电阻器轮廓以及其引脚的橡皮筋连接，一个使用 "path" 橡皮筋，另一个使用 "directline" 橡皮筋到动态光标缓冲区。

**Original**: This example loads two circular pads and, the outline of a resistor, and rubberband connections from its pins, one with a "path" rubberband, the other a "directline" rubberband into the dynamic cursor buffer.


### axlClearDynamics


**语法** (Syntax):
```skill
axlClearDynamics()
; Create cross markers to show rubberband origins:
axlDBCreateLine(list(9150:4450 9050:4550) 0.
"board geometry/dimension")
axlDBCreateLine(list(9150:4550 9050:4450) 0.
"board geometry/dimension")
axlDBCreateLine(list(8550:4450 8450:4550) 0.
"board geometry/dimension")
axlDBCreateLine(list(8550:4550 8450:4450) 0.
"board geometry/dimension")
mypath = axlPathStart(list( -350:0)) ; Start circular pad
axlPathArcCenter(mypath, 0., -350:0, nil, -300:0)
; Load the first pad into the dynamic cursor buffer
axlAddSimpleMoveDynamics(0:0 mypath "path" ?ref_point 0:0)
mypath = axlPathStart(list( 350:0)) ; Start circular pad
axlPathArcCenter(mypath, 0., 350:0, nil, 300:0)
; Load the other pad into the dynamic cursor buffer
axlAddSimpleMoveDynamics(0:0 mypath "path" ?ref_point 0:0)
mypath = axlPathStart( ; Start resistor body outline
list( -200:-100 200:-100 200:100 -200:100 -200:-100))
; Load the resistor body outline in the dynamic cursor buf
axlAddSimpleMoveDynamics(0:0 mypath "path" ?ref_point 0:0)
; Load a "path" rubberband to the first pad
axlAddSimpleRbandDynamics(8500:4500 "path"
?origin 8500:4500 ?var_point -300:0)
; Load a "directline" rubberband to the second pad
axlAddSimpleRbandDynamics(9100:4500 "directline"
?origin 9100:4500 ?var_point 300:0)
;
mypoint = axlEnterPoint() ; Ask user for point
Loads two circular pads, the outline of a resistor, and rubberband connections from its pins
(one with a
"path"
rubberband, the other a
"directline"
rubberband) into the dynamic cursor buffer.
The following illustration shows the cursor in a typical position as
axlEnterPoint
waits for selection of a point.
Example 2: Dynamic Cursor Rotation
axlClearDynamics() ; Clean out any existing cursor data
mypath = axlPathStart(list( -350:0)) ; Start circular pad
axlPathArcCenter(mypath, 0., -350:0, nil, -300:0)
; Load the first pad into the dynamic cursor buffer
axlAddSimpleMoveDynamics(0:0 mypath "path" ?ref_point 0:0)
mypath = axlPathStart(list( 350:0)) ; Start circular pad
axlPathArcCenter(mypath, 0., 350:0, nil, 300:0)
; Load the other pad into the dynamic cursor buffer
axlAddSimpleMoveDynamics(0:0 mypath "path" ?ref_point 0:0)
mypath = axlPathStart( ; Start resistor body outline
list( -200:-100 200:-100 200:100 -200:100 -200:-100))
; Load the resistor body outline in the dynamic cursor buf
axlAddSimpleMoveDynamics(0:0 mypath "path" ?ref_point 0:0)
; Ask user to pick angle of rotation about (8500:4500):
axlEnterAngle(8500:4500)
Loads two circular pads, the outline of a resistor, and rubberband connections from its pins, one with a "path" rubberband, the other a "directline" rubberband into the dynamic cursor buffer.
The following illustration shows the dynamically rotating cursor in a typical position as
axlEnterAngle
waits for a user-selected point.
Enter Function Example
You use the AXL-SKILL
axlCancelEnterFun
and
axlFinishEnterFun
functions when you create an interactive command that loops on input, providing the option to end the command.
(defun axlMyCancel ()
axlClearDynamics()
axlCancelEnterFun()
axlUIPopupSet(nil))
(defun axlMyDone ()
axlClearDynamics()
axlFinishEnterFun()
axlUIPopupSet(nil))
mypopup = axlUIPopupDefine( nil
(list (list "MyCancel" 'axlMyCancel)
(list "MyDone" 'axlMyDone)))
axlUIPopupSet( mypopup)
; Clear the dynamic buffer
axlClearDynamics()
; Clear mypath to nil, then loop gathering user picks:
mypath = nil
while( (mypath = axlEnterPath(?lastPath mypath))
progn(
axlDBCreatePath(mypath, "etch/top")))
The Enter Function example does the following:
Defines the functions
axlMyCancel
and
axlMyDone
.
Defines a pop-up with those functions as the callbacks for user selections
Cancel
and
Done
from the pop-up.
Loops on the function
axlEnterPath
gathering user input to create a multi-segment line on
"etch/top".
Selecting
Cancel
or
Done
from the pop-up ends the command.
You gather one user-selected point and extend the database path by that selection each time through the while loop. Selecting Done from the pop-up terminates the loop. Selecting Cancel at any time cancels. Segments added become permanent in the database when the loop ends.
axlHighlightObject and axlDehighlightObject Examples
You use the AXL-SKILL
axlHighlightObject
and
axlDehighlightObject
functions to highlight database elements during interactive commands.
Example 1
(defun highlightLoop ()
mypopup = axlUIPopupDefine( nil
(list (list "Done" 'axlFinishEnterFun)
(list "Cancel" 'axlCancelEnterFun)))
axlUIPopupSet( mypopup)
axlSetFindFilter( ?enabled '("noall" "alltypes" "nameform")
?onButtons "alltypes")
(while (axlSelect)
progn(
axlHighlightObject( axlGetSelSet())
; Just a dummy delay to see what happens
sum = 0
for( i 1 10000 sum = sum + i)
axlDehighlightObject( axlGetSelSet())))
Example 1 does the following:
Defines the function
highlightLoop
.
Defines a popup with
axlFinishEnterFun
and
axlCancelEnterFun
as the callbacks for user selections
Done
and
Cancel
from the pop-up.
Loops on the function
axlSelect
gathering user selections to highlight.
Waits in a simple delay loop, then dehighlights.
Selecting
Cancel
or
Done
from the pop-up ends the command.
Example 2
axlDBControl('highlightColor 4)
axlHighlightObject(axlGetSelSet() t)
Permanently highlights an object using color
4
.
Allegro PCB Editor Interface Functions
This section lists Allegro PCB Editor interface functions.
```


---


### axlClearDynamics

```skill
axlClearDynamics(
)
```
⇒ t

**描述** (Description):

Clears the dynamic cursor buffer. Call this function each time before you start setting up rubberband and dynamic cursor graphics.

**参数** (Arguments):

None.

**返回值** (Value Returned):

t
Always returns
t
.

**示例** (Example):

See dynamic cursor examples in the section
AXL-SKILL Interface Function Examples
.

---


### axlAddSimpleRbandDynamics

```skill
axlAddSimpleRbandDynamics(
```
l_fixed_point
t_type
?origin
l_origin
?var_point
l_var_point
?lastPath
l_lastPath
?width
f_width
?color   g_color
```skill
)
```
⇒ t/nil

**描述** (Description):

Loads rubber band dynamics buffer with an element. If dynamics buffer is already loaded, the new element is simply added to the existing buffer. Dynamics buffer is not cleared until
axlClearDynamics
is called.
**说明**：橡皮筋动态意味着从称为 fixed_point 的锚点将元素拉伸到光标。

**Original**: Rubber band dynamics means stretching of elements to the cursor from an anchor point called the fixed_point.

This works in conjunction with the axl<Event> APIs. In particular, no grid snapping, only works when these APIs are called. Do not use this in the axlUIWTimerAdd or with axlTriggerSet callbacks.

**参数** (Arguments):

l_fixed_point
Fixed point of rubber band. Anchor point from which the dynamic rubberband stretches. The rubberband cursor stretches dynamically from
fixed_point
to current position of the cursor, as moved by the user. The next argument,
type
, specifies the shape of the rubberband—part of a path, direct, z-line (a combination of horizontal and vertical), arc, circle, or box.
t_type
String specifying type of dynamic rubberband to be drawn. Can be one of the following:
path, directline, horizline, vertline, arc, circle, or box
.
directline
: add a single line to buffer between
fixed_point
and
var_point
.
**说明**：var_point 的原点和变量点

**Original**: origin and variable point of var_point

horizline
: A single horizontal line.
vertline
: A single vertical line
arc
:       Arc between fixed_point and var_point. Radius varies as cursor moves
```skill
"circle":    Circle, fixed_point is center and var_point is initial radius.
"box": Add a box, fixed point is one corner and the var_point is the opposite corner.
"path": Add two segments whose behavior is controlled by the line lock attributes (axlSetLineLock).
"fixedline": Adds a constant line to cursor buffer, fixed_point and var_point are the two endpoints.
```
l_origin
Cursor origin. Useful only if you plan on rotating the object, this is the center of its rotation. Also on arcs to control tangency. In most cases this should be nil.
l_var_point
**说明**：橡皮筋的变量点。

**Original**: Variable point for rubberbanding.

l_lastPath
Previous path structure. Needed to calculate tangent point if rubberbanding starts at the end of an existing path.
f_width
Optional database width of the rband. Default is 0.0.
g_color
Optional arguments for defining the dynamics' color. Possible choices are:
**说明**：用于推导颜色的层字符串（即 class/subclass）。

**Original**: A layer string (i.e. class/subclass) for the layer to be used for deriving the color.

```skill
'ratsnestColor - the color used for ratsnest lines will be used.
'activeSubclassColor - the color for the active class/subclass is used. If this changes, the color for this rband also changes.
```

**返回值** (Value Returned):

t
**说明**：成功添加数据。

**Original**: Successfully added data.

nil
**说明**：未添加数据。

**Original**: No data added.


**示例** (Example):

A file, demo_dynamics.il, in
<cdsroot>
/share/pcb/examples/skill
demonstrates the various t_type options.
**说明**：此示例加载两个圆形焊盘和电阻器轮廓，以及其引脚的橡皮筋连接，一个使用 "path" 橡皮筋，另一个使用 "directline" 橡皮筋到动态光标缓冲区：

**Original**: This example loads two circular pad and, the outline of a resistor, and rubberband connections from its pins, one with a "path" rubberband, the other a "directline" rubberband into the dynamic cursor buffer:


---


### axlClearDynamics


**语法** (Syntax):
```skill
axlClearDynamics() ; Clean out any existing cursor data
mypath = axlPathStart(list( -350:0)) ; Start circular pad
axlPathArcCenter(mypath, 0., -350:0, nil, -300:0)
; Load the first pad into the dynamic cursor buffer
axlAddSimpleMoveDynamics(0:0 mypath "path" ?ref_point 0:0)
mypath = axlPathStart(list( 350:0)) ; Start circular pad
axlPathArcCenter(mypath, 0., 350:0, nil, 300:0)
; Load the other pad into the dynamic cursor buffer
axlAddSimpleMoveDynamics(0:0 mypath "path" ?ref_point 0:0)
mypath = axlPathStart( ; Start resistor body outline
list( -200:-100 200:-100 200:100 -200:100 -200:-100))
; Loads the resistor body outline in the dynamic cursor buffer
axlAddSimpleMoveDynamics(0:0 mypath "path" ?ref_point 0:0)
; Ask user to pick angle of rotation about (8500:4500):
axlEnterAngle(8500:4500)
See dynamic cursor examples in the section
AXL-SKILL Interface Function Examples
.
```


**参见** (See Also):

axlEnterPoint
,
axlEnterEvent

---


### axlAddSimpleMoveDynamics

```skill
axlAddSimpleMoveDynamics(
```
l_origin
r_path
t_type
?ref_point
l_ref_point
?color g_color
```skill
)
```
⇒ t/nil

**描述** (Description):

Loads cursor buffer dynamics buffer with an element. If dynamics buffer is already loaded, the new element is simply added to the existing buffer. Dynamics buffer is not cleared until
axlClearDynamics
is called.
Cursor buffer dynamics means no stretching of elements. The loaded is attached to the cursor and moves with it.

**参数** (Arguments):

l_origin
Cursor origin. (see
axlAddSimpleRbandDynamics
```skill
)
```
r_path
**说明**：包含显示对象的路径结构。

**Original**: Path structure containing display objects.

t_type
String specifying type of path: either
path
or
box
. Note that lines and arcs are represented as path. Circle is a special case of arc where the start, end points are the same.
l_ref_point
**说明**：元素旋转参考点。

**Original**: Element rotation reference point.

g_color
Optional argument for defining the dynamics' color. Possible choices are:
**说明**：用于推导颜色的层字符串（class/subclass）。

**Original**: A layer string (class/subclass) for the layer to be used for deriving the color.

```skill
'ratsnestColor
```
- the color used for ratsnest lines will be used.
```skill
'activeLayerColor
```
- the color for the active class/subclass is used. If this changes, the color for this rband also changes.

**返回值** (Value Returned):

t
**说明**：数据成功添加时返回。

**Original**: Returned if the data is successfully added.

nil
**说明**：未添加数据。

**Original**: No data added.


**示例** (Example):

See dynamic cursor examples,
**说明**：示例 1：动态橡皮筋

**Original**: Example 1: Dynamic Rubberband

and
**说明**：示例 2：动态光标旋转

**Original**: Example 2: Dynamic Cursor Rotation

, in the section
AXL-SKILL Interface Function Examples
.

---


### axlDesignFlip

```skill
axlDesignFlip(
```
g_flip
```skill
) t/nil
```

**描述** (Description):

Visually flips the design in the 'y' axis. Maintains current xy view.
**说明**：如果 OpenGL 被禁用，此命令不可用。

**Original**: This command not available if OpenGL is disabled.


**参数** (Arguments):

t
**说明**：沿 y 轴翻转

**Original**: flipped on y axis

nil
**说明**：取消翻转

**Original**: unflip


**返回值** (Value Returned):

**说明**：旧翻转状态。如果 t 则沿 y 翻转，如果 nil 则正常顶视图状态

**Original**: Old flip state. If t flipped (y) if nil normal top view state


**参见** (See Also):

axlWindowFit

**示例** (Example):

**说明**：实现切换翻转的语法

**Original**: Syntax to implement toggle flipping


---


### axlEnterPoint

```skill
axlDesignFlip( !axlDesignFlip())
axlEnterPoint(
```
?prompts
l_prompts
?points
l_points
?gridSnap
g_gridSnap
```skill
)
```
⇒
l_point
/nil

**描述** (Description):

Prompts for and receives user-selected point. Returns the point data to the calling function.

**参数** (Arguments):

l_prompts
**说明**：包含一个要显示的提示消息的列表。

**Original**: List containing one prompt message to display.

l_points
List of points. Returns one of these as the return value.
l_point’s
only use is, if passed a point, to immediately return with the point snapped to the nearest grid.
g_gridSnap
**说明**：功能标志：

**Original**: Flag to function:

t
means snap the point according to the current grid.

**返回值** (Value Returned):

l_point
List of coordinates, if entered. If selected, this is a list of one point.
nil
**说明**：用户未选择点。

**Original**: User did not select a point.


**示例** (Example):

See Example 1 in the section
AXL-SKILL Interface Function Examples
.

**参见** (See Also):

axlGetLastEnterPoint
,
axlEnterEvent

---


### axlEnterString

```skill
axlEnterString(
```
?prompts
l_prompts
```skill
)
```
⇒
t_string
/nil

**描述** (Description):

Displays a dialog box that requires first entering a string, and then pressing
Return
on the keyboard or clicking
OK
or
Cancel.
Default prompt in the dialog box is
“Enter String.”
You can supply a prompt string with the
?prompts
keyword. The function returns the string entered, if any. Otherwise it returns
nil
.
This function is a blocker. Allegro PCB Editor will not respond to any user input until the data requested by the dialog box is provided.

**参数** (Arguments):

l_prompts
List containing one prompt message. Displays only the first string if the list contains more than one string.

**返回值** (Value Returned):

t_string
**说明**：输入的字符串。

**Original**: String entered.

nil
No string entered, dialog box dismissed by clicking
Cancel
, or the command failed.

**示例** (Example):

user_name = axlEnterString(
?prompts list("Please enter your name:"))
⇒
“user name”
Prompts for name and collects the response in
user_name
.
Typing the name, then pressing the
Return
key returns the string entered:

---


### axlEnterAngle

```skill
axlEnterAngle(
```
origin
?prompts
l_prompts
?refPoint
l_refPoint
?angle
f_angle
?lockAngle
g_lockAngle
```skill
)
```
⇒
f_angle
/nil

**描述** (Description):

**说明**：可选提示用户。返回输入的角度值。

**Original**: Optionally prompts the user. Returns the angle value entered.


**参数** (Arguments):

origin
**说明**：组成角的两条线相交的固定点。

**Original**: Fixed point where two lines making up the angle meet.

l_prompts
**说明**：包含一个提示消息的列表。

**Original**: List containing one prompt message.

l_refPoint
End point of a line from the
origin
that acts as the fixed line of the angle.
f_angle
Angle value in. If non-
nil
, does not prompt for a user-selected point.
g_lockAngle
**说明**：动态旋转的初始锁定角度。

**Original**: Initial lock angle for dynamic rotation.


**返回值** (Value Returned):

f_angle
**说明**：以度表示的选择角度。

**Original**: Selected angle expressed in degrees.

nil
**说明**：未选择角度。

**Original**: No angle selected.


**示例** (Example):

See Example 1 in the section
AXL-SKILL Interface Function Examples
.

---


### axlCancelEnterFun

```skill
axlCancelEnterFun()
```
⇒ t/nil

**描述** (Description):

Terminates the wait for a user-selected point. Waiting function returns no data.

**参数** (Arguments):

None.

**返回值** (Value Returned):

t
Terminates wait for user-selected point. Cancel succeeds.
nil
Fails to terminate wait for user-selected point.

**示例** (Example):

See the
**说明**：Enter 函数示例

**Original**: Enter Function Example

.

---


### axlFinishEnterFun

```skill
axlFinishEnterFun()
```
⇒ t/nil

**描述** (Description):

Terminates the wait for a user-selected point. Waiting function returns no data. For a
one-point function (for example,
axlEnterPoint
```skill
) behaves the same as
```
axlCancelEnterFun
.

**参数** (Arguments):

None.

**返回值** (Value Returned):

t
**说明**：终止对用户选择点的等待。

**Original**: Terminates wait for a user-selected point.

nil
**说明**：无法终止对用户选择点的等待。

**Original**: Fails to terminate wait for a user-selected point.


**示例** (Example):

See the
**说明**：Enter 函数示例

**Original**: Enter Function Example

.

---


### axlGetDynamicsSegs

```skill
axlGetDynamicsSegs(
```
l_point1
l_point2
r_lastPath/nil
```skill
) ->
```

**描述** (Description):

Normally used with dynamics to calculate arc tangency of two picks to a current
r_path
. Passed coordinates may be modified to preserve tangency. Depends on the current line lock state that you set or
axlSetLineLock
.

**参数** (Arguments):

point1
**说明**：动态开始前的第一次拾取。

**Original**: First pick before dynamics started.

point2
**说明**：动态完成后的第二次拾取。

**Original**: Second pick, after dynamics completes.

lastPath
Previous path to use for tangency calculations. Can pass
nil
if not applicable.

**返回值** (Value Returned):

l_pointList
nil

**参见** (See Also):

axlAddSimpleRbandDynamics
,
axlMakeDynamicsPath
,
axlSetLineLock

**示例** (Example):

q = axlGetDynamicsSegs(10:10 100:100 nil)
-> (((10.0 10.0) (100.0 100.0) nil))

---


### axlGetLineLock

```skill
axlGetLineLock(
```
s_name
[g_value]
```skill
)
```
==> g_currentValue/ls_names

**描述** (Description):

Gets the current settings of the line lock or dynamic control options. Equivalent items is the option control panel for "add" commands. Items currently supported:
Name:   arcEnable
Value:  t/nil
Description: If t Lock Mode is arc, nil is line.
Name:   lockAngle
Value:  0, 45, 90
Description: In degrees where 0 is off (no lock).
Name:   minRadius
Value:  float
Description: Minimum Radius in user units.
Name:   length45
Value:  float
Description: Fixed 45 Length value in user units.
Name:   fixed45
Value:  t/nil
Description: If t Fixed 45 length is enabled.
Name:   lengthRadius
Value:  float
Description: Fixed radius value in user units.
Name:   fixedRadius
Value:  t/nil
Description: If t in Fixed Radius mode
Name:   lockTangent
Value:  t/nil
Description: If t tangent mode is on.

**参数** (Arguments):

s_name
symbol name of control.
nil
returns all possible names

**返回值** (Value Returned):

See above.
ls_names
, If name is
nil
then returns a list of all controls.

**参见** (See Also):

axlSetLineLock

**示例** (Example):

Return current lock tangent setting
```skill
axlGetLineLock('lockTangent)
```
Get all names supported by this interface
listOfNames = axlGetLineLock(nil)

---


### axlEnterBox

```skill
axlEnterBox(
```
?prompts
l_prompts
?points
l_points
```skill
)
```
⇒
l_box
/nil

**描述** (Description):

Takes two points that define a box and returns them in
l_box
. Optionally prompts the user, if
l_prompts
contains no more than two strings. If
l_points
is
nil
, prompts for two points. If
l_points
contains one point, prompts only for the second point. If
l_points
contains both points, simply returns them as
l_box
.

**参数** (Arguments):

l_prompts
List that should contain two prompt messages. If list is
nil
, uses default Allegro PCB Editor prompts for soliciting a box. (
“Enter first point of box”
and
“Enter second point of box”
```skill
) If list contains two strings, the first string prompts for the first point, and the second string prompts for the second point. If the list has only one string, the string prompts for both the first and the second points.
```
l_points
List of none, one, or two points. Solicits missing points interactively using the prompts given in
l_prompts
in order.

**返回值** (Value Returned):

l_box
**说明**：框的左下角和右上角坐标列表。

**Original**: List of the lower left and upper right coordinates of the box.

nil
**说明**：无法获取框数据。

**Original**: Failed to get box data.


**示例** (Example):


---


### axlDBCreateRectangle


**语法** (Syntax):
```skill
axlDBCreateRectangle(
axlEnterBox(?prompts
list("First rectangle point, please..."
"Second rectangle point, please..."))
t “etch/top”)
⇒ (dbid:12134523 nil)
Asks for box input to create a filled rectangle on layer
"etch/top".
```


**参见** (See Also):

axlEnterEvent
,
axlEnterPoint

---


### axlEnterPath

```skill
axlEnterPath(
```
?prompts
l_prompts
?points
l_points
?lastPath
r_path
```skill
)
```
⇒
r_path
/nil

**描述** (Description):

Gets the start point and subsequent points for a path, interactively with optional prompting, or from the optional argument
l_points
. Sets the start point to the first value of
l_points
, if any, and the second point to the second value, if any. If
r_path
is given, connects the dynamic rubberband to its most recent segment. Use
axlEnterPath
recursively to build up the coordinates of a path interactively.

**参数** (Arguments):

l_prompts
**说明**：包含一个要显示的提示消息的列表。

**Original**: List containing one prompt message to display.

l_points
List of none, one, or two coordinates to be used as input to
axlEnterPath
.
r_path
The previously gathered part of the path. Used to calculate the tangent point for the dynamic cursor.

**返回值** (Value Returned):

r_path
Path containing segments constructed from the combined points in
l_points
and the interactive input to
axlEnterPath
.
nil
**说明**：无法获取点。

**Original**: Failed to get points.


**示例** (Example):

See the
**说明**：Enter 函数示例

**Original**: Enter Function Example

.

---


### axlHighlightObject

```skill
axlHighlightObject(
```
[
lo_dbid
]
[
g_permHighlight
]
```skill
)
```
⇒ t/nil

**描述** (Description):

Highlights the figures whose
```skill
dbids
```
are in
lo_dbid
.
**说明**：支持永久高亮的对象比支持临时高亮的对象少。

**Original**: Fewer objects support permanent highlighting than support temporary highlighting.

Setting

---


### axlDebug


**语法** (Syntax):
```skill
axlDebug(t)
enables additional informational messages.
```


**参数** (Arguments):

od_dbid
List of the
```skill
dbids
```
of figures to be highlighted.
g_permHighlight
**说明**：使用颜色区分临时高亮和永久高亮。

**Original**: Distinguishes temporary highlighting from permanent highlighting using color.

t
- use PERM highlight color
nil
- use TEMP highlight color
The default is
nil
.

**返回值** (Value Returned):

t
**说明**：至少高亮了一个图形。

**Original**: Highlighted at least one figure.

nil
Highlighted no figures due to invalid
```skill
dbids
```
or objects already being highlighted.

**示例** (Examples):

You can use the AXL-SKILL
axlHighlightObject
and
axlDehighlightObject
functions to highlight database elements during interactive commands.
**说明**：此示例执行以下操作：

**Original**: This example does the following:

Defines the function
highlightLoop
.
**说明**：循环使用 axlSelect 函数收集用户选择以高亮。

**Original**: Loops on the function axlSelect gathering user selections to highlight.

**说明**：在简单延迟循环中等待，然后取消高亮。

**Original**: Waits in a simple delay loop, then dehighlights.

You can stop the command at any time by selecting
Cancel
or
Done
from the pop-up.
```skill
(defun highlightLoop ()
```
mypopup = axlUIPopupDefine( nil

---


### axlUIPopupSet


**语法** (Syntax):
```skill
axlUIPopupSet( mypopup)
axlSetFindFilter( ?enabled '("noall" "alltypes" "nameform")
?onButtons "alltypes")
(while (axlSelect)
progn(
axlHighlightObject( axlGetSelSet())
; Just a dummy delay to see what happens
sum = 0
for( i 1 10000 sum = sum + i)
axlDehighlightObject( axlGetSelSet())))
This example permanently highlights an object using color 4:
axlDBControl('highlightColor 4)
axlHighlightObject(axlGetSelSet() t)
Also see the
axlHighlightObject and axlDehighlightObject Examples
.
```


---


### axlDehighlightObject

```skill
(list (list "Done" 'axlFinishEnterFun)
(list "Cancel" 'axlCancelEnterFun)))
axlDehighlightObject(
```
lo_dbid
/g_mode
[
g_permHighlight
]
```skill
)
```
⇒ t/nil

**描述** (Description):

Use this command to turn off highlighting on an object. Dehighlights the objects whose
```skill
dbids
```
are in
lo_dbid
. If 'all option is used then g_permHighlight is treated as t (true).

**参数** (Arguments):

lo_dbid
List of
```skill
dbids
```
of figures to be dehighlighted.
g_mode
```skill
'all
```
to dehighlight entire design
```skill
'nets
```
dehighlight all nets.
g_permHighlight
**说明**：使用颜色区分临时高亮和永久高亮。

**Original**: Distinguishes temporary highlighting from permanent highlighting using color.

t
- use PERM highlight color
nil
- use TEMP highlight color (The default value is
nil
.)

**返回值** (Value Returned):

t
**说明**：至少取消高亮了一个图形。

**Original**: Dehighlighted at least one figure.

nil
**说明**：无法取消高亮任何图形。

**Original**: Failed to dehighlight any figures.


**示例** (Example):

See
axlHighlightObject
for examples.

**参见** (See Also):

axlHighlightObject

---


### axlMiniStatusLoad

```skill
axlMiniStatusLoad (
```
s_formHandle
t_formFile/(t_formName t_contents)
g_formAction
[
g_StringOption
]
[t_restrict]
[b_reload]
```skill
)
```
⇒
r_form
/nil

**描述** (Description):

Loads the Ministatus form with the form file provided in this call. Replaces the current Ministatus form contents. This function is a special case of
axlForms
. See
Chapter 11, “Form Interface Functions,”
for details on how AXL forms work.
When the command is finished, Allegro PCB Editor restores the Ministatus contents to the default values. Once the form is opened, you use normal
axlForm
functions to set or retrieve fields.
You typically use this to write a command requiring user interaction such as “swap component.”
Two reserved field names are available:
class    -- enumerated list of CLASS layers
subclass -- enumerated list of SUBCLASS layers for the current active class.
If you make use of these fields use support changing the active class and subclass you also get (for free) color swatch support. The Form file fragment shown below can be added to you ministatus form file to get that support. The "subcolor" field is optional. You should adjust the position (FLOC) of the fields to suite your form layout.
For scripting and performance always use the same t_formfile name for an application.
Using these reserved names also causes axlGetActiveLayer to update when user changes the layer.
TEXT "Active Class and Subclass:"
FLOC 1 1
ENDTEXT
FIELD class
FLOC 5 4
ENUMSET 19
OPTIONS prettyprint
POP "class"
ENDFIELD
# option
FIELD subcolor
FLOC 2 7
COLOR 2 1
ENDFIELD
FIELD subclass
FLOC 5 7
ENUMSET 19
OPTIONS prettyprint ownerdrawn
POP "subclass"
ENDFIELD

**参数** (Arguments):

**说明**：有关内联 [(t_formName t_contents)] 的描述，请参阅 axlFormCreate 函数。

**Original**: A description of the in-line [(t_formName t_contents)] is contained in the function axlFormCreate.

t_restrict
This optional argument is a string that indicates class and subclass restrictions if the form contains "class" and "subclass" popup fields that have not been overridden with calls to axlFormBuildPopup. Possible values are:
```skill
"NONE"    - no restrictions
"TEXT"     - only layers that allow text
"SHAPES"    - only layers that allow shapes
"RECTS"     - only layers that allow rectangles
"ETCH"    - only etch layers
"ETCH_PIN_VIA"    - only etch, pin, and via layers
"ETCH_NO_WIREBOND"    - only non-wirebond etch layers
```
b_reload
If true, form file will not be cached for faster performance. By default, all ministatus options forms are cached as it is expected they will be used repeatedly. A value of true here will prevent this behavior and allow the form to reload from disk.

**返回值** (Value Returned):

r_form
Upon success,
r_form
is returned.
nil
**说明**：由于以下原因之一失败：

**Original**: Failure due to one of the following:

**说明**：没有活动的交互式命令或活动命令不是 AXL 注册的交互式类型。

**Original**: No interactive command is active or the active command is not of the type AXL registered interactive.

**说明**：AXL 表单代码遇到错误。

**Original**: AXL Forms code encounters an error.


**示例** (Example):

**说明**：请参阅交换元件示例：

**Original**: See swap component example:

<install_dir>/share/pcb/etc/skill/examples/swap

**参见** (See Also):

axlFormCreate
for further details.

---


### axlMiniStatusClose

```skill
axlMiniStatusClose(
```
lo_dbid
```skill
)-> t
```

**描述** (Description):

**说明**：此函数关闭活动的 Options 面板，并将其恢复到活动应用模式的空闲/默认选项面板。

**Original**: This function closes the active Options panel and returns things to the idle/default options panel for the active application mode.


**参数** (Arguments):

None

**返回值** (Value Returned):

t

**示例** (Example):

axlMiniStatusClose

---


### axlDrawObject

```skill
axlDrawObject(
```
lo_dbid
```skill
)
```
⇒ t/nil

**描述** (Description):

Processes a list of
```skill
dbids
```
.
Redraws any objects that were erased by
axlEraseObject
.

**参数** (Arguments):

lo_dbid
List of
```skill
dbids
```
or one
```skill
dbid
```
.

**返回值** (Value Returned):

t
One or more objects drawn.
nil
No valid
```skill
dbids
```
or all objects already at desired display state.

---


### axlDynamicsObject

```skill
axlDynamicsObject (
```
lo_dbid
[
l_ref_point
]
```skill
)
```
⇒ t/nil

**描述** (Description):

Adds list of objects to the cursor buffer. These objects are attached to the cursor in xor mode. Origin point establishes cursor position relative to objects in the dynamics buffer.
**说明**：向光标缓冲区添加太多对象会严重影响性能。

**Original**: Adding too many objects to the cursor buffer dramatically affects performance.

If you load a symbol definition via
axlLoadSymbol
but does not place the symbol, the definition will, at some time, be deleted from the database.

**参数** (Arguments):

lo_dbid
List of AXL
```skill
dbids
```
or single
```skill
dbid
```
.
l_ref_point
**说明**：可选原点（如果未提供则取光标位置）。

**Original**: Optional origin point (takes cursor position if not provided).


**返回值** (Value Returned):

t
**说明**：一个或多个对象已添加到光标缓冲区。

**Original**: One or more objects added to the cursor buffer.

nil
**说明**：没有对象添加到光标缓冲区。

**Original**: No objects added to the cursor buffer.


**示例** (Example):

**说明**：将符号添加到光标缓冲区，以符号原点作为参考点：

**Original**: Adds a symbol to the cursor buffer with the symbol origin as a reference point:

```skill
axlDynamicsObject(symbol_id, symbol_id->xy)
```
**说明**：将符号定义添加到光标缓冲区：

**Original**: Add a symbol definition to cursor buffer:

```skill
axlDynamicsObject(symbol_id->defintion, symbol_id->xy)
```
**说明**：加载符号并添加到光标缓冲区到当前光标位置：

**Original**: Load a symbol and add to cursor buffer to the current cursor location:

def = axlLoadSymbol("PACKAGE" "dip14")
when(def axlDynamicsObject(def))

---


### axlEraseObject

```skill
axlEraseObject(
```
lo_dbid
```skill
)
```
⇒ t/nil

**描述** (Description):

Processes a list of
```skill
dbids
```
and erases them. Typically used with
axlDynamicsObject
to erase objects before attaching them to the cursor. Any objects erased are restored to their visibility when calling AXL shell or terminating the SKILL program.

**参数** (Arguments):

lo_dbid
List of
```skill
dbids
```
or one
```skill
dbid
```
.

**返回值** (Value Returned):

t
**说明**：一个或多个对象已擦除。

**Original**: One or more objects erased.

nil
No valid
```skill
dbids
```
or all objects already at desired display state.

---


### axlControlRaise

```skill
axlControlRaise(
```
g_option
```skill
)
```
⇒ t/nil

**描述** (Description):

Raises a tab in the control panel to the top. If you use this at the start of an interactive command, you override the environment variable,
control_auto_raise
.

**参数** (Arguments):

g_option
**说明**：支持的符号有：

**Original**: Supported symbols are:

```skill
'options
```
,
```skill
'find
```
,
```skill
'visibility
```
, and
nil
.
nil
returns a list of supported symbols.

**返回值** (Value Returned):

t
**说明**：选项卡提升到控制面板顶部。

**Original**: Tab raised to top in control panel.

nil
**说明**：未知符号。

**Original**: Unknown symbol.


**示例** (Example):

```skill
axlControlRaise('options)
```
**说明**：将选项面板提升到顶部。

**Original**: Raises the option panel to the top.


---


### axlEnterEvent

```skill
axlEnterEvent(
```
l_eventMask
t_prompt
g_snap
```skill
)
```
⇒
r_eventId

**描述** (Description):

A lower level event manager than other
axlEnter
functions. Provides a SKILL program with more user event details. See
Table 7-2
for a list of events with descriptions.
Returns event structure containing the attributes described in
Table 7-1
. Event occurrence controls what attributes are set by all event types, and sets the
objType,
event and
time
attributes.
Table 7-1
Event Attributes
Attribute Name
Type

**描述** (Description):

objType
string
Type of object, in this case
event
type
symbol
Event occurrence
xy
point
Location of mouse
xySnap
point
Location of mouse snapped to grid.
command
int/symbol
Returns the callback item of
axlUIPopupDefine
time
float
time stamp (seconds.milliseconds)
**说明**：不要在 case 语句中放置默认处理程序，因为事件模型将在未来版本中更改。

**Original**: Do not put a default handler in your case statement since the event model will change in future releases.

Table 7-2
Events
Event

**描述** (Description):

Attributes/Mask
PICK
User has selected a point (equal to
axlEnterPoint
```skill
)
```
PICK_EXTEND
Same as
PICK
except has
extend
keyboard modifier.
PICK_TOGGLE
Same as
PICK
except has
toggle
keyboard modifier.
**说明**：xy, xySnap

**Original**: xy, xySnap

DBLPICK
**说明**：用户在某个位置双击。

**Original**: User has double picked at a location.

DBLPICK_EXTEND
Same as
DBLPICK
except has
extend
keyboard modifier.
DBLPICK_TOGGLE
Same as
DBLPICK
except has
toggle
keyboard modifier.
**说明**：xy, xySnap

**Original**: xy, xySnap

MOVE
Mouse is moving. Depending upon the amount of time spent in your callback, the system may sum mouse movements to minimize falling behind in processing mouse events.
STARTDRAG
**说明**：用户开始拖动操作。

**Original**: User starts a drag operation.

STARTDRAG_EXTEND
Same as
STARTDRAG
except has
extend
keyboard modifier.
STARTDRAG_TOGGLE
Same as
STARTDRAG
except has
toggle
keyboard modifier.
**说明**：xy, xySnap

**Original**: xy, xySnap

STOPDRAG
**说明**：用户终止拖动操作。

**Original**: User terminates the drag operation.

STOPDRAG_EXTEND
Same as
STOPDRAG
except has
extend
keyboard modifier.
STOPDRAG_TOGGLE
Same as
STOPDRAG
except has
toggle
keyboard modifier.
**说明**：xy, xySnap, command

**Original**: xy, xySnap, command

DONE
**说明**：用户请求命令完成。

**Original**: User requests the command to complete.

**说明**：此事件无法被屏蔽。

**Original**: This event cannot be masked.

CANCEL
Respond to this event by terminating your SKILL program (don’t call any more
axlEnter
functions.)
**说明**：此事件无法被屏蔽。

**Original**: This event cannot be masked.


**注意** (Notes):

You will get
PICK
before
DBLPICK
events. To differentiate between a
PICK
and
DBLPICK
, highlight the selected object. Do not output informational messages or perform time consuming processing.
Never prompt user for a double click. Instead, format prompts for the next expected event.
Events dispatched from
axlEnterEvent
are scripted by the system if scripts are enabled.
The
done
and
cancel
callbacks optionally defined in
axlCmdRegister
are called before the
DONE
and
CANCEL
events are returned.
The
extend
keyboard modifier is obtained by holding the
Shift
key while performing the mouse operation.
The
toggle
keyboard modifier is obtained by holding the
Control
key while performing the mouse operation.

**编程提示** (Programming Hints):

**说明**：通过为命令提供单个掩码集并且不在每个事件后尝试更改掩码集，可以更轻松地编程。

**Original**: You can program more easily by providing a single mask set for your command and by not attempting to change the mask set after each event.

When
Snap to Object
right mouse button menus are present and the user selects a snap operation:
**说明**：xy 和 xySnap 都返回吸附结果

**Original**: both the xy and xySnap return the snap result

**说明**：snap 参数被忽略

**Original**: the snap argument is ignored

**说明**：正常的 pick 事件正常运行

**Original**: normal pick events function normally

Use
axlSnapDisableAtRMB
if you do not want to snap the menu items.

**参数** (Arguments):

l_eventMask
/
nil
**说明**：预期事件列表。

**Original**: List of events to expect.

t_prompt
/
nil
User prompt. If
nil
, the default prompt is used.
g_snapGrid
If
t
, grid snapping is enabled while the function is active. Otherwise no grid snapping is allowed. This affects the
xySnap
value that is returned as well as dynamics and the
xy
readout. If
nil
,
xySnap
is not snapped to the grid and is the same as
xy
.

**返回值** (Value Returned):

r_eventId
**说明**：包含属性的事件结构。

**Original**: Event structure containing attributes.


**参见** (See Also):

axlEnterPoint
and axlSnapEnableAtRMB

**示例** (Example):

**说明**：完整示例包含在：

**Original**: A complete example is contained in:

<cdsroot>/share/pcb/examples/skill/axlcore/EnterEvent.il
let( (eventMask event, loop)
eventMask = '( PICK DBLPICK )
loop = t
while( loop
event = axlEnterEvent(eventMask, nil t)
case(event->type
```skill
('PICK
```
... )
```skill
('DBLPICK
```
... )
```skill
('DONE
; cleanup
```
loop = nil)

---


### axlEventSetStartPopup

```skill
)
)
)
axlEventSetStartPopup(
```
[
s_callback
]
```skill
)
```
⇒ t/nil

**描述** (Description):

Sets a SKILL callback function called prior to a popup being displayed on the screen. Allows AXL applications to reset the popup (see
axlUIPOPUPSetsee
```skill
), thus providing context sensitive popups support.
```
The callback function is passed a list structure the same as the return list in
axlEnterEvent
. Use this function with
axlEnterEvent
.
The callback function is removed when an AXL application is finished. Set this at the application start, if needed.

**参数** (Arguments):

s_callback
**说明**：AXL 回调函数。

**Original**: AXL callback function.

none
**说明**：取消设置回调函数，禁用回调机制。

**Original**: Unsets the callback function which disables the callback mechanism.


**返回值** (Value Returned):

t
**说明**：设置 SKILL 回调函数。

**Original**: Set SKILL callback function.

nil
**说明**：无法设置 SKILL 回调函数。

**Original**: Failed to set SKILL callback function.


**示例** (Example):

```skill
(defun startpopupcallback (event)
```
...
newpopup = get a new popup based on event x,y values

---


### axlUIPopupSet


**语法** (Syntax):
```skill
axlUIPopupSet(newpopup)
)
axlEventSetStartPopup('startpopupcallback)
...
let( (eventMask event, loop)
eventMask = list( 'PICK 'DBLPICK )
loop = t
while( loop
event = axlEnterEvent(eventMask, nil)
case(event->type
('PICK
... )
('DBLPICK
... )
('DONE
loop = nil)
('CANCEL
loop = nil)
)
)
...
axlEventSetStartPopup()
Typically used in conjunction with
axlEnterEvent
.
```


---


### axlGetTrapBox

```skill
axlGetTrapBox(
```
l_point
```skill
)
```
⇒
l_window
/nil

**描述** (Description):

Returns coordinates of the
Find
window.

**参数** (Arguments):

l_point
Listing of the
x
and
y
coordinates

**返回值** (Value Returned):

l_window
```skill
((x_l y_l) (x_u y_u))
```
- List of corner coordinates of the
Find
window.
```skill
(x_l y_l)
```
- List containing
x
and
y
coordinates of the lower left corner.
```skill
(x_u y_u)
```
- List of the
x
and
y
coordinates of the upper right corner.
nil
l_point
is
null
or in an incorrect format.

---


### axlRatsnestBlank

```skill
axlRatsnestBlank(
```
rd_net
```skill
)
```
⇒ t/nil

**描述** (Description):

**说明**：隐藏网络中的所有 ratsnest 线。

**Original**: Blanks all ratsnest lines in a net.


**参数** (Arguments):

rd_net
```skill
dbid
```
of a net

**返回值** (Value Returned):

t
**说明**：Ratsnest 线已隐藏。

**Original**: Ratsnest lines are blanked.

nil
**说明**：Ratsnest 线未隐藏。

**Original**: Ratsnest lines are not blanked.


---


### axlRatsnestDisplay

```skill
axlRatsnestDisplay(
```
rd_net
```skill
)
```
⇒ t/nil

**描述** (Description):

**说明**：显示网络中的所有 ratsnest 线。

**Original**: Displays all ratsnest lines in a net.


**参数** (Arguments):

rd_net
```skill
dbid
```
of a net

**返回值** (Value Returned):

t
**说明**：Ratsnest 线已显示。

**Original**: Ratsnest lines are displayed.

nil
**说明**：Ratsnest 线未显示。

**Original**: Ratsnest lines are not displayed.

axlSetDynamicsMirror
**说明**：设置动态镜像选项

**Original**: sets mirror option for dynamics


---


### axlSetDynamicsMirror


**语法** (Syntax):
```skill
axlSetDynamicsMirror(
g_mirror
) ==> g_oldmirror
```


**描述** (Description):

**说明**：设置动态镜像。

**Original**: Sets the Dynamics mirroring.


**参数** (Arguments):

g_mirror
**说明**：g_mirror 类型。可能的值有：

**Original**: g_mirror type.Possible Values are:

GEOMETRY:
mirror geometry only (same layer)
nil:
mirror none
t:
mirror

**返回值** (Value Returned):

**说明**：旧镜像值

**Original**: old mirror value


**参见** (See Also):

axlAddSimpleMoveDynamics

**示例** (Example):


---


### axlSetDynamicsRotation

```skill
axlSetDynamicsMirror(t
)
axlSetDynamicsRotation(
```
f_angle/nil
```skill
) ==> f_oldangle
```

**描述** (Description):

**说明**：设置动态旋转。如果角度为 nil，则返回当前旋转。

**Original**: Sets the Dynamics rotation. If angle is nil then returns current rotation.


**参数** (Arguments):

f_angle
**说明**：浮点数

**Original**: Floating point number


**返回值** (Value Returned):

**说明**：旧角度

**Original**: old angle


**参见** (See Also):

axlAddSimpleMoveDynamics

**示例** (Example):


---


### axlShowObjectToFile

```skill
axlSetDynamicsRotation(45.0)
axlShowObjectToFile(
```
lo_dbid
[
t_file_name
]
```skill
)
```
⇒ (
t_file_name x_width x_line_count
```skill
)
```

**描述** (Description):

Creates a temporary file with show element information on
```skill
dbids
```
specified in
lo_dbid
.

**参数** (Arguments):

lo_dbid
List of
```skill
dbids
```
or a single
```skill
dbid
```
.
t_file_name
**说明**：要使用的文件名，而不是临时文件。

**Original**: File name to use instead of a temporary file.


**返回值** (Value Returned):

List of items describing the file created
```skill
(
```
t_file_name x_width x_line_count
```skill
)
```
:
t_file_name
**说明**：临时文件的名称。

**Original**: Name of the temporary file.

x_width
**说明**：最宽文本行的宽度（字符）。

**Original**: Width, in characters, of the widest text line.

x_line_count
**说明**：文件中的行数。

**Original**: Number of lines in the file.

nil
**说明**：无法创建文件。

**Original**: Could not create file.


---


### axlUICmdPopupSet

```skill
axlUICmdPopupSet(
```
r_popup
```skill
)
```
⇒
r_prevPopup

**描述** (Description):

Sets up a popup menu with all menu items required throughout the execution of the command. Call during the command’s initialization process. Use of this procedure modifies the behavior of
axlUIPopupSet
so that it makes unavailable all popup items not in the defined popup.
Adds a
cmdPopupId
property to AXL user data which restores popup entries whenever the AXL command state is restored. The command popup is cleared when the SKILL command ends.

**参数** (Arguments):

r_popup
Popup handle, obtained by calling
axlUIPopupDefine
. A
nil
value turns off this popup.

**返回值** (Value Returned):

r_prevPopup
**说明**：先前定义的弹出窗口集。

**Original**: Popup set previously defined.

This procedure does the same as
axlCmdPopupSet
for non-WXL UI’s.

---


### axlWindowFit

```skill
axlWindowFit(
)
```
⇒ l_bBox

**描述** (Description):

Zooms in to (or out of) a design fitting it fully on the window. For the Allegro PCB Editor in layout mode, performs a fit on the outline. For the Allegro PCB Editor symbol mode, performs a fit such that all visible objects occupy maximum window area. Returns the bounding box of the window after the fit has been performed.

**参数** (Arguments):

none

**返回值** (Value Returned):

l_bBox
**说明**：缩放后窗口的边界框（以用户单位）。

**Original**: The bounding box of the window after zooming (in user units).

This is available as the Allegro PCB Editor command
window fit
.

---


### axlZoomBbox

```skill
axlZoomBbox (
```
x_window
```skill
) => bBox
```

**描述** (Description):

**说明**：x_window：窗口 ID 或 nil 表示当前活动窗口。nil 是活动窗口，0 是主画布。Allegro 目前仅支持一个额外画布，因此值 1 表示该画布。

**Original**: x_window: window id or nil to currently active window. nil is the active window and 0 is the primary canvas. Allegro currently only supports one additional canvas so the value 1 indicates that canvas.


**参数** (Arguments):

**说明**：返回窗口的边界框 (bBox)。

**Original**: Returns bounding box (bBox) of window.


**返回值** (Value Returned):

bBox
**说明**：两个 xy 坐标列表，指示右上角和左下角。这些以设计单位表示。

**Original**: a list of two xy coordinates indicating upper right and lower left. These are in design units.


**参见** (See Also):

axlZoomControl

**示例** (Examples):

**说明**：活动窗口的 BBox

**Original**: BBox of active window

```skill
axlZoomBbox(nil)
```
=> ((100 120) (300 320))

---


### axlZoomCenter

```skill
axlZoomCenter (
```
x_window
xy
```skill
)
```
-=> t/nil

**描述** (Description):

Zoom centers on the provided coordinate. It may adjust the point if centering results in the display bounding extents are outside the design extents.
**说明**：如果希望缩放并居中，请使用 axlZoomInOut。

**Original**: If you wish to zoom and center use axlZoomInOut.


**参数** (Arguments):

x_window
window id or nil to currently active window (see
axlZoomBbox
```skill
)
```
xy
**说明**：以设计单位表示的居中坐标

**Original**: Coordinate in design units for centering


**返回值** (Value Returns):

t
if successful
nil
an error

**参见** (See Also):

axlZoomControl

**示例** (Examples):

**说明**：创建辅助窗口并居中

**Original**: Create a secondary window and center it


---


### axlZoomControl


**语法** (Syntax):
```skill
axlZoomControl('create)
axlZoomCenter(1 4000:4000)
```


---


### axlZoomControl

```skill
axlZoomControl (
```
s_option
[g_arg]
```skill
)
```
-=> g_return

**描述** (Description):

Manages the multi-canvas feature. Requires OpenGL to be enabled.Id 0 is the main Allegro canvas.
**说明**：支持的选项有：

**Original**: Supported options are:

```skill
'create
```
**说明**：创建新画布。目前仅支持 1 个。

**Original**: creates a new canvas. Currently only 1 supported.

**说明**：返回 - 成功时返回画布 id，如果已达到最大画布数或不支持多窗口则返回 nil

**Original**: Return – If success returns canvas id, if max canvases already exist or multi-window not supported returns nil

```skill
'remove
```
**说明**：移除辅助画布。无法移除主画布 (id=0)。需要 g_arg 的画布 id。

**Original**: removes secondary canvas. Cannot remove primary canvas (id=0). Requires a canvas id for g_arg.

Return –
t
if canvas removed,
nil
if error
```skill
'supported
```
**说明**：是否支持多窗口。

**Original**: Is multi-window supported.

Return –
t
if supported, nil not supported
```skill
'list
```
**说明**：可用画布

**Original**: available canvases

```skill
'active
```
returns the active window id. This impacts the Allegro menu Zoom commands and if you pass nil to the axlZoom APIs
Return: integer indicating active window
```skill
'swap
```
**说明**：交换主窗口和辅助窗口内容。

**Original**: swaps the primary and secondary window contents.

Return: t did the swap, nil failed

**参数** (Arguments):

s_option
**说明**：见上文

**Original**: see above

g_arg
**说明**：某些选项需要的额外参数，见上文

**Original**: addition argument some options require, see above


**返回值** (Value Returned):

g_return
**说明**：取决于选项，见上文

**Original**: depends upon the option, See above


**参见** (See Also):

axlZoomBbox
axlZoomPoints
axlZoomCenter
axlZoomWorld

**示例** (Examples):

Create secondary canvas
```skill
axlZoomControl('create)
```
Remove secondary canvas

---


### axlZoomFit

```skill
axlZoomControl('remove 1)
axlZoomFit (
```
x_window
s_option
```skill
) => t/nil
```

**描述** (Description):

Zoom fits the window. Depending upon the design type fit is define as:
**说明**：逻辑设计（brd、mcm、mdd 等）

**Original**: logic design (brd, mcm, mdd, etc)


**参数** (Arguments):

x_window
window id or nil to currently active window (see
axlZoomBbox
```skill
)
```
s_option(visible)
**说明**：如果是逻辑或分区设计，适应可见对象

**Original**: if logic or partition design fit to visible objects


**返回值** (Value Returned):

t
if successful
nil
an error

**参见** (See Also):

axlZoomControl

**示例** (Examples):

Fit primary window to visible objects

---


### axlZoomInOut

```skill
axlZoomFit(0 visible)'
axlZoomInOut (
```
x_window
x_factor
[xy]
```skill
) => t/nil
```

**描述** (Description):

**说明**：围绕可选坐标按提供的因子缩放窗口。

**Original**: Zooms window in or out by provided factor around optional coordinate.


**参数** (Arguments):

x_window
window id or nil to currently active window (see
axlZoomBbox
```skill
)
```
x_factor
**说明**：缩放因子，正数放大，负数缩小。1 是 2x，2 是 4x，3 是 8x 等。

**Original**: factor to zoom, a positive number zooms in while negative zooms out. 1 is 2x, 2 is 4x, 3 is 8x etc.

xy
**说明**：围绕缩放的可选坐标。如果未提供，使用当前窗口中心

**Original**: optional coordinates to zoom around. If not provided uses center of current window


**返回值** (Value Returns):

t
if successful
nil
an error

**参见** (See Also):

axlZoomControl

**示例** (Examples):

zoom in by 2x primary window

---


### axlZoomPoints

```skill
axlZoomInOut(0 1)
axlZoomPoints (
```
x_window
upperLeft_xy
lowerRight_xy
```skill
) => t/nil
```

**描述** (Description):

Zoom windows by points. The zoom maintains a 1:1 aspect ratio, the coordinates provided will be fitted into the active window size.

**参数** (Arguments):

x_window
window id or nil to currently active window (see axlZoomBbox)
upperLeft_xy
**说明**：左上角坐标

**Original**: upper left coordinate

lowerRight_xy
**说明**：右下角坐标

**Original**: lower right coordinate


**返回值** (Value Returns):

t
if successful
nil
an error

**参见** (See Also):

axlZoomControl

**示例** (Examples):

zoom by points on the primary window

---


### axlZoomToDbid

```skill
axlZoomPoints(0 100:120 4000:4000)
axlZoomToDbid(
```
o_dbid
/
lo_dbid
g_always
[x_window]
```skill
)
```
⇒ t/nil

**描述** (Description):

Processes a list of
```skill
dbids
```
and centers and zooms the display around them. Zoom is done so objects extents fill about 20% of the display. You should highlight the objects.
**说明**：如果传递超过 20 个对象，则不执行缩放。

**Original**: If more than 20 objects are passed no zoom is done.


**参数** (Arguments):

o_dbid
List of
```skill
dbids
```
or one
```skill
dbid
```
.
g_always
If
t,
then ignores
NO_ZOOM_TO_OBJECT
environment variable.
x_window
Optional window ID or
nil
to currently active window (see
axlZoomBbox
```skill
). If no value is provided active window is used.
```

**返回值** (Value Returned):

t
**说明**：一个或多个对象已缩放。

**Original**: One or more objects zoomed.

nil
No valid
```skill
dbids
```
or all objects are already at desired display state.

**示例** (Example):

**说明**：缩放到 U1

**Original**: Zoom to U1

sym = axlDBFindByName('refdes "U1")
```skill
axlZoomToDbid(sym t)
```

**参见** (See Also):

axlZoomManage

---


### axlZoomWorld

```skill
axlZoomWorld (
```
x_window
```skill
) => t/nil
```

**描述** (Description):

**说明**：将绘图窗口缩放到世界范围。

**Original**: Zoom world a drawing window


**参数** (Arguments):

x_window
window id or nil to currently active window (see
axlZoomBbox
```skill
)
```

**返回值** (Value Returns):

t
if successful
nil
an error

**参见** (See Also):

axlZoomControl

**示例** (Examples):

**说明**：将活动窗口缩放到世界范围

**Original**: world the active window


---


### axlMakeDynamicsPath

```skill
axlZoomWorld (nil)
axlMakeDynamicsPath(
```
l_formatedList
```skill
)
```
⇒ r_path/nil

**描述** (Description):

This is a convenience function to construct an
r_path
from a formatted list.
axlDBCreate
and
axlPoly
require an
r_path.
A circle is an arc segment with same end points.
Passing an illegal format may result in a bad return.

**参数** (Arguments):

```skill
( l_seg1 l_seg2 ...) g_clockwise
```
Each
l_seg
is:
```skill
(
```
l_startPoint l_endPoint [f_width] [l_center] [f_radius])
l_startPoint:
Start point of path.
l_endPoint:
End point of path.
f_width:
Optional width (default of 0).
l_center:
Optional center point if
r_path
is an arc.
f_radius:
Optional radius if
r_path
is an arc.
If an arc
r_path,
both
l_center
and
f_radius
must be provided.
g_clockwise
Direction to create arc:
t ⇒ create arc clockwise from start to endpoint.
nil ⇒ create counterclockwise. Default is counterclockwise.

**返回值** (Value Returned):

r_path
```skill
dbid
```
of
r_path
.
nil
No
r_path
constructed due to incorrect arguments.

**示例** (Example):

Simple
r_path
segment with a width of 20.
a = axlMakeDynamicsPath(list(list( 10:10 100:100 20)))

**Return to top** (Return to top):

⠀
X