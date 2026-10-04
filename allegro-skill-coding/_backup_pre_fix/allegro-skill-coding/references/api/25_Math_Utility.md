# 25. 数学工具 (Math Utility)

> **来源**: Allegro SKILL Reference, Product Version 17.4-2019, October 2019

---



**概述** (Overview):

**说明**：本章描述 AXL-SKILL 数学工具函数。

**Original**: This chapter describes the AXL-SKILL Math Utility functions.


### axlDegToRad

```skill
axlDegToRad(
```
n_angle
```skill
) => f_angle
```

**描述** (Description):

**说明**：将角度从度转换为弧度。

**Original**: Converts an angle in degrees to radians.


**参数** (Arguments):

n_angle
Angle in degrees

**返回值** (Value Returned):

f_angle
Angle in radians

**参见** (See Also):

axlRadToDeg
, axlMathConstants

**示例** (Example):

```skill
axlDegToRad(45.0)
```
=> 0.7853982

---


### axlDistance

```skill
axlDistance(
```
l_point1
l_point2
```skill
)
```
⇒
f_distance

**描述** (Description):

Returns the distance between two points. You may use floating point.

**参数** (Arguments):

l_point
A point.
ll_line
Two points at the ends of a line.

**返回值** (Value Returned):

f_distance
Distance between two points in floating point form.

**示例** (Example):


---


### axlGeo2Str

```skill
axlDistance(10:20 5:20) = 5.0
axlGeo2Str(
```
f_dbrep/point
```skill
) -> t_result/nil
```

**描述** (Description):

When converting floating point numbers to strings you may find the number printed is slightly differently then the value Allegro reports. This is difference is due to how floating point numbers are represented in the computer. The following article is an excellent paper on the subject:
What Every Computer Scientist Should Know About Floating-Point Arithmetic
by David Goldberg.
http://docs.sun.com/source/806-3568/ncg_goldberg.html
This article also explains why sometimes the comparison of two floating numbers that appear the same results in a non-equal result. The results only differ from printf when a "5" exists at the location one place more then the database accuracy. The behavior is as follows for rounding:
if digit at db accuracy is odd and then 5 round up
if digit at db accuracy is even and then 5 round down
See examples below. This supports two modes, a single floating point number and a point (a list of two floating point numbers).

**参数** (Arguments):

dbrep
a floating point number
point
a xy point

**返回值** (Value Returned):

Returns a string with Allegro rounding. If a point is passed then the return format is:
```skill
"<x> <xy>"
```
nil:
not a legal argument

**参见** (See Also):

axlGeoEqual

**示例** (Examples):

Assume database is two decimal places
procedure( testit( f)
printf("printf=%.2f\taxlGeo2Str=%s \toriginal value %.3f\n"
f axlGeo2Str(f) f)
```skill
)
```
testit(1.115)
testit(1.125)
testit(-1.115)
testit(-1.125)
Results:
printf=1.11     axlGeo2Str=1.12         original value 1.115
printf=1.12     axlGeo2Str=1.12         original value 1.125
printf=-1.11    axlGeo2Str=-1.12        original value -1.115
printf=-1.12    axlGeo2Str=-1.12        original value -1.125
Using a point

---


### axlGeoAngleBetweenLines

```skill
axlGeo2Str(100.124:123.345)
axlGeoAngleBetweenLines(
```
l_line1
l_line2
```skill
)
```
⇒ f_angle

**描述** (Description):

Finds angle between two lines, in radians. If the lines are parallel or coincident,
is returned. The angle is the acute angle from
l_line1
to
l_line2
, and is positive if clockwise, negative if counter clockwise.

**参数** (Arguments):

l_line1
List of two points defining line 1
l_line2
List of two points defining line 2

**返回值** (Value Returned):

f_angle
The angle between lines in RADIANS

---


### axlGeoArcCenterAngle

```skill
axlGeoArcCenterAngle(
```
l_startPoint
l_endPoint
f_angle
[
g_clockwise
]
```skill
)
```
⇒
l_center
/nil

**描述** (Description):

Calculates the center of an arc given the angle between its endpoints. Uses the arguments depending on
g_clockwise
as shown in
Figure 25-1
.
Figure 25-1
Center of Arc Calculation

**参数** (Arguments):

l_startPoint
Start point of the arc
l_endPoint
End point of the arc
f_angle
Included angle of the arc
g_clockwise
Rotational sense of the arc:
t
is clockwise.
nil
is counterclockwise (the default).

**返回值** (Value Returned):

l_center
Center of the arc as a list: (
X
Y
```skill
).
```
nil
Cannot calculate the center from the given arguments.

**示例** (Example):

print axlGeoArcCenterAngle( 7500:5600 8000:4700 68.5 t)
mypath = axlPathStart(list( 7500:5600))

---


### axlPathArcAngle


**语法** (Syntax):
```skill
axlPathArcAngle(mypath, 0., 8000:4700, t, 68.5)
axlDBCreatePath( mypath, "etch/bottom")
⇒ (7089.086 4782.826)
Prints the center for the clockwise arc going through the points (7500:5600) and (8000:4700) using
axlGetArcCenterAngle
, then adds the arc through those points using
axlPathArcAngle
, and compares their centers.
The arc is shown in the following figure.
Do
Show Element
on the arc to show its center coordinate. The arc lists:
"center-xy (7089,4783)"
which agrees with the
(7089.086 4782.826)
printed by
axlGeoArcCenterRadius
.
```


---


### axlGeoArcCenterRadius

```skill
axlGeoArcCenterRadius(
```
l_startPoint
l_endPoint
f_radius
[
g_clockwise
]
[
g_bigArc
]
```skill
)
```
⇒
l_center
/nil

**描述** (Description):

Calculates center of an arc given its radius. Calculates
l_center
either for one arc or another depending on the arguments, as shown.

**参数** (Arguments):

l_startPoint
Start point of the arc
l_endPoint
End point of the arc
f_radius
Radius of the arc
g_clockwise
Rotational sense of the arc:
t
is clockwise.
nil
```skill
(default) is counterclockwise.
```
g_bigArc
Flag telling whether the arc extends as the larger or the smaller of the two arcs possible between the start and endpoints.

**返回值** (Value Returned):

l_center
Center of the arc as a list: (
X
Y
```skill
).
```
nil
Cannot calculate the center from the given arguments.

**示例** (Example):

print axlGeoArcCenterRadius( 7500:5600 8000:4700 1000)
⇒ (8499.434 5566.352)
mypath = axlPathStart(list( 7500:5600))

---


### axlPathArcRadius


**语法** (Syntax):
```skill
axlPathArcRadius(mypath, 0., 8000:4700, t, nil, 1000)
axlDBCreatePath( mypath, "etch/bottom")
print axlGeoArcCenterRadius( 7500:5600 8000:4700 1000 t)
⇒ (7000.566 4733.648)
mypath = axlPathStart(list( 7500:5600))
axlPathArcRadius(mypath, 0., 8000:4700, nil, nil, 1000)
axlDBCreatePath( mypath, "etch/top")
Prints the two possible centers for the arcs going through the points (7500:5600) and (8000:4700), then adds arcs through those points using
axlPathArcRadius
, and compares the centers.
The arcs are shown in the following figure.
Do
Show Element
on each arc to show its center coordinate.The solid arc on the left lists:
"center-xy (8499,5566)"
which agrees with the
(8499.434 5566.352)
printed by
axlGeoArcCenterRadius
. The dotted arc on the right lists:
"center-xy (7001, 4734)"
, which agrees within rounding with
(7000.566 4733.648)
printed for the other arc.
Arguments 3
axlMKSConvert(
nil
[
t_outUnits
]
)
⇒ t/nil
Pre-registers
t_outUnits
, the input units string, so that subsequent calls to
axlMKSConvert
need not specify units.
t_outUnits
String giving the units to convert to for subsequent calls to
axlMKSConvert
. If there is no active drawing, function fails with this combination of arguments.
Value Returned 3
t
Conversion string acceptable.
nil
Conversion string not acceptable.
Example 3
See Example 4 below.
Arguments 4
axlMKSConvert(
n_input
)
⇒
f_output
/nil
Use this combination of arguments only after a call to
axlMKSConvert
as in Arguments 3. Converts the number
n_input
specifying a value using the
t_outUnits
supplied by a previous call to
axlMKSConvert
, and returns as
f_output
.
n_input
Number giving the input value to convert
Value Returned 4
f_output
Converted value of
n_input
.
Example 4
(axlMKSConvert .5) -> nil ;;error,if no preregistered units
(axlMKSConvert nil "MILS) -> t
(axlMKSConvert .5) -> 0.0005 ; remembers MILS
The following
Show Element
form shows the net with
MYPROP
attached:
```


---


### axlGeoArcMidpoint

```skill
axlGeoArcMidpoint(
```
l_arcPoint1
l_arcPoint2
l_arcCenter
f_radius
g_clockwize
```skill
)
```
⇒ l_midPoint/nil

**描述** (Description):

**说明**：查找圆弧的中点。

**Original**: Finds midpoint of an arc.


**参数** (Arguments):

l_arcPoint1
Start point of arc
l_arcPoint2
End point of arc
l_arcCenter
Center of circle
f_radius
Radius
g_clockwize
Clockwise flag

**返回值** (Value Returned):

l_midPoint
The midpoint
nil

---


### axlGeoCircleCircleInt

```skill
axlGeoCircleCircleInt(
```
l_point1
f_radius1
l_point2
f_radius2
```skill
)
```
⇒ ll_intersections/nil

**描述** (Description):

**说明**：查找两个圆之间的交点。

**Original**: Finds the intersection(s) between two circles.


**参数** (Arguments):

l_point1
Center point of circle 1
f_radius1
Radius of circle 1
l_point2
Center point of circle 2
f_radius2
Radius of circle 2

**返回值** (Value Returned):

ll_intersections
A list of the intersection points
nil
No intersection

---


### axlGeoCircleLineInt

```skill
axlGeoCircleLineInt(
```
l_point1
l_point2
o_arcDbid
```skill
)
```
⇒ ll_intersections/nil

**描述** (Description):

**说明**：查找直线与圆之间的交点。

**Original**: Finds the intersection(s) between a line and a circle.


**参数** (Arguments):

l_point1
A point on the line
l_point2
Another point on the line
o_arcDbid
Dbid of an arc

**返回值** (Value Returned):

ll_intersections
A list of the intersection points
nil
No intersection

**参见** (See Also):

axlGeoCircleLineInt2

---


### axlGeoCircleLineInt2

```skill
axlGeoCircleLineInt2(
```
l_point1
l_point2
l_center
f_radius
```skill
)
```
⇒ ll_intersections/nil

**描述** (Description):

This function finds the intersection(s) between a line and a circle.

**参数** (Arguments):

l_point1
A point on the line
l_point2
Another point on the line
l_center
Center of an arc
f_radius
Radius of arc

**返回值** (Value Returned):

ll_intersections
A list of the intersection points
nil
No intersection

**参见** (See Also):

axlGeoCircleLineInt

---


### axlGeoEqual

```skill
axlGeoEqual(
```
f_one
f_two
```skill
)
```
⇒ t/nil

**描述** (Description):

**说明**：对两个浮点数执行相等比较，确定它们是否在正负当前数据库精度范围内相等。

**Original**: Performs an equal comparison between two floating point numbers and determines if they are equal within plus or minus the current database accuracy.

Useful for comparing floating point numbers converted from strings (example - using
atof
function) with those obtained from an AXL database id. Since the conversion of these numbers takes different paths (string to float versus integer to float, in the case of the database) you can have different numbers.
To understand the basis of why a simple equal (==) comparison cannot always be used with floating point numbers see David Goldberg's paper on "
What Every Computer Scientist Should Know About Floating-Point Arithmetic
."
Wikipedia also has a good article: http://en.wikipedia.org/wiki/Floating_point
Floating point numbers can be internally represented by using two different formats;
float
```skill
(4 bytes) and
```
double
```skill
(8 bytes). All AXL interfaces use 8 bytes. SKILL interfaces depend upon the use so:
```
sscanf( "0.2" "%g" n)           ; skill float
sscanf( "0.2" "%lg" nd)         ; skill double
Wherever possible, use the double representation as it has more accuracy.

**参数** (Arguments):

Two floating point numbers.

**返回值** (Value Returned):

t
Given numbers are equal within the current database accuracy.
nil
Given numbers are not equal within the current database accuracy.

**示例** (Example):

```skill
axlGeoEqual(2.0 2.0)
```

**参见** (See Also):

axlGeo2Str
,
axlGeoPointsEqual

---


### axlGeoFindAngle

```skill
axlGeoFindAngle(
```
l_vector
l_origin
```skill
)
```
⇒ f_angle/nil

**描述** (Description):

**说明**：查找给定向量的角度。

**Original**: Finds the angle of a given vector.


**参数** (Arguments):

l_vector
The end point from the origin
l_origin
The origin

**返回值** (Value Returned):

f_angle
The angle of the vector in RADIANS
nil
Vector or origin are invalid points

**示例** (Example):

```skill
axlGeoFindAngle(list(1 1) list(0 0))
```
=> 0.7853982

---


### axlGeoGetBBox

```skill
axlGeoGetBBox(
```
l_points
```skill
)
```
⇒ l_bbox/nil

**描述** (Description):

**说明**：查找给定点集的边界框。

**Original**: Finds the bounding box of the given set of points.


**参数** (Arguments):

l_points
The set of points

**返回值** (Value Returned):

l_bbox
The bounding box of the set of points
nil
Empty list

---


### axlGeoIsBoxOverlap


---


### axlGeolsBoxOverlap


**语法** (Syntax):
```skill
axlGeolsBoxOverlap(
l_first_bbox
l_second_bbox
[t_orientation]
)
⇒ t/nil
```


**描述** (Description):

**说明**：确定一个框是否与另一个框重叠。

**Original**: Determines whether a box overlaps another box.


**参数** (Arguments):

l_first_bbox
The bounding box of the first box
l_second_bbox
The bounding box of the second box
t_orientation
```skill
"x": check for horizontal overlap only
"y": check for vertical overlap only
```
nil: check for physical overlap (default)

**返回值** (Value Returned):

t
The two boxes overlap
nil
The two boxes do not overlap

---


### axlGeoLineMidpoint

```skill
axlGeoLineMidpoint(
```
l_point1
l_point2
```skill
)
```
⇒ l_point/nil

**描述** (Description):

**说明**：查找线段的中点。

**Original**: Finds midpoint of a line.


**参数** (Arguments):

l_point1
First point
l_point2
Another point

**返回值** (Value Returned):

l_point
The midpoint
nil
Illegal arguments

---


### axlGeoRotatePt

```skill
axlGeoRotatePt(
```
f_angle
l_xy
l_origin/nil
[mirror]
```skill
) -> l_xyResult/nil
```

**描述** (Description):

Rotates
xy
about an origin by angle. Optionally applies mirror on the
x
axis.

**参数** (Arguments):

f_angle
Angle 0 to 360 degrees (support for 1/1000 of a degree); rotation is counter-clockwise for positive numbers.
l_xy
xy point to rotate in user units.
l_origin
Origin to rotate about; if
nil
uses (0, 0)
mirror
optional mirror flag.
Normally either
nil
```skill
(no mirror) or
```
t
for front-to-back mirror, also accepts
```skill
'GEOMETRY
```
and
```skill
'LAYERS
```
values, which may be set on database objects as their mirror type. You do not need to convert
```skill
'GEOMETRY
```
to t and
```skill
'LAYERS
```
to
nil
.

**返回值** (Value Returned):

l_xyResult
Rotated result.
nil
Error in arguments or rotation would result in return being outside of the database extents.

**示例** (Examples):

Rotate:
```skill
axlGeoRotatePt(45.0 10:200 5:2) ->   (-131.4716 145.5427)
```
Rotate and mirror:
```skill
axlGeoRotatePt(45.0 10:200 5:2 t) -> (-138.5427 138.4716)
```
Rotate about 0,0:

---


### axlGeoPointsEqual

```skill
axlGeoRotatePt(90.0, 100:0 nil) ->  (0.0 100.0)
axlGeoPointsEqual(
```
l_point1
l_point2
```skill
) -> t/nil
```

**描述** (Description):

This performs an equal comparison between two xy points and determines if they are equal within db accuracy.

**参数** (Arguments):

two xy points

**返回值** (Value Returned):

t
if they are equal within current database accuracy.
nil
not equal

**参见** (See Also):

axlGeoEqual

**示例** (Examples):

pt1 = '(2.0 1.1)
pt2 = '(2.0 1.1)

---


### axlGeoPickShorterArc

```skill
axlGeoPointsEqual(pt1 pt2)
axlGeoPickShorterArc(
```
l_start
l_end1
l_end2
l_center
f_radius
g_clockwize
```skill
)
```
⇒ l_point/nil

**描述** (Description):

**说明**：从两种可能性中选择较短的圆弧。

**Original**: Picks the shorter arc from two possibilities.


**参数** (Arguments):

l_start
Start point
l_end1
One possible endpoint
l_end2
Other possible endpoint
l_center
Center of arc
f_radius
Radius of arc
g_clockwize
Clockwise flag of arc

**返回值** (Value Returned):

l_point
The point that gives the shorter arc
nil
Bad arguments

---


### axlGeoIsShorterArcClockwise


---


### axlGeolsShorterArcClockwise


**语法** (Syntax):
```skill
axlGeolsShorterArcClockwise(
l_start
l_end
l_centerPoint
)
⇒ t/nil
```


**描述** (Description):

Given a start point, end point and center of an arc, determines whether the clockwise or counter-clockwise arc from start to end is the shorter arc. If the arc end points are on a diameter, it returns
t
```skill
(clockwise).
```

**参数** (Arguments):

l_start
Start point of the arc
l_end
End point of the arc
l_centre
Centre point of the arc

**返回值** (Value Returned):

f_angle
The angle between lines in RADIANS

---


### axlMathSolveQuadratic

```skill
axlMathSolveQuadratic(
```
n_a
n_b
n_c
```skill
)
```
⇒ l_roots/nil

**描述** (Description):

**说明**：求解形式为 ax^2+bx+c=0 的二次方程。不求解具有复数根的方程。

**Original**: Solves a quadratic equation in the form ax^2+bx+c=0. Does not solve equations with complex roots.


**参数** (Arguments):

n_a
a in ax^2+bx+c=0
n_b
b in ax^2+bx+c=0
n_c
c in ax^2+bx+c=0

**返回值** (Value Returned):

l_roots
A list of the roots
nil
Complex roots

**示例** (Example):

```skill
axlMathSolveQuadratic(1 2 1)
```
=> (-1.0)

---


### axlIsBetween

```skill
axlIsBetween(
```
g_testNum
g_x1, g_x2
```skill
) -> t/nil
```

**描述** (Description):

Checks if a number lies between two other given numbers. Returns
t
if a number is in a given range specified by two numbers. For example, for number n and range specified by x1 and x2,
t
will be returned if either of x1<= n <= x2 or x1<= n >= x2 is true.

**参数** (Arguments):

g_testNum
Number to test
g_x1, g_x2
Number range to test

**返回值** (Value Returned):

t
if number is in range including the end values, otherwise
nil

**参见** (See Also):

axlIsPointInsideBox

---


### axlIsPointInsideBox

```skill
axlIsPointInsideBox(
```
l_point
l_box
```skill
)
```
⇒ t/nil

**描述** (Description):

Checks if a point is inside a bounding box. Returns
t
if a point is inside or on the edge of a bounding box. Also see
axlGeoPointInShape
for
```skill
dbid
```
-based tests. You may use floating point.

**参数** (Arguments):

l_point
A point.
l_box
A bounding box.

**返回值** (Value Returned):

t
Point is inside or on the edge of box
nil
Point is outside of box.

**示例** (Example):


---


### axlIsPointOnLine

```skill
axlIsPointInsideBox(10:20 list(5:20 15:30)) = t
axlIsPointInsideBox(0:20 list(5:20 15:30)) = nil
axlIsPointInsideBox(15:20 list(5:20 15:30)) = t
axlIsPointOnLine(
```
l_point
ll_line
[f_nearNess]
```skill
)
```
⇒ t/nil

**描述** (Description):

Returns
t
if point is on a given line or
nil
if not on the line.
If f_nearNess value is provided, it is used as a tolerance so if a point is within the tolerance value.
In either case, an epsilon of axlEpsilonFloat (see axlMathConstants) is applied.

**参数** (Arguments):

l_point
A point.
ll_line
Two end points.
[f_nearNess]
```skill
(optional) A tolerance value
```

**返回值** (Value Returned):

t
Point is on the specified line.
nil
Point is not on the specified line.

**示例** (Example):

```skill
axlIsPointOnLine(10:20 list(5:20 15:30)) = nil
axlIsPointOnLine(10:30 list(5:20 15:30)) = t
axlIsPointOnLine(10:20 list(5:20 15:30) 2.5) = t
```

**参见** (See Also):

axlIsBetween

---


### axlLineSlope

```skill
axlLineSlope(
```
ll_line
```skill
)
```
⇒
f_slope

**描述** (Description):

Returns the slope of a line. You may use floating point.

**参数** (Arguments):

ll_line
Two end points.

**返回值** (Value Returned):

f_slope
Slope of the line.
nil
Line is vertical.

**示例** (Example):

```skill
axlLineSlope(list(5.0:20.10 15.4:30.2)) = 0.9711538
axlLineSlope(list(5:20 5:40)) = nil
axlLineXLine – Obsolete
```
**说明**：此函数不再需要，但为向后兼容而保留。

**Original**: This function is no longer required, but is kept for backward compatibility.

axlMathConstants
Provides predefined set of high accuracy math constants. They are:
axlPI
– PI
axlPI_2
– PI/2.0
axlPI_4
– PI/4.0
axlSQRT2
– sqrt(2)
axlSQRT1_2
– 1/sqrt(2)
axlEpsilonFloat
– epsilon for floating point numbers (32 bit)
axlEpsilonDouble
– epsilon for doubles (64 bit)
axlDegPerRad
– Degrees per radian
axlRadPerDeg
– Radians per degree
axlRad0, axlRad45, axlRad90, axlRad135, axlRad180, axlRad225, axlRad270, axlRad315, axlRad360 – radians values for popular degrees values
SKILL, by default, limits the number of decimal places printed but these constants are still stored and used at the full precision. To see the full precision of the constant you can do:
sstatus(fullPrecision t)
or

---


### axlMathDotProduct

```skill
printf("%5.18f\n" axlPI)
axlMathDotProduct(
```
l_ptA1
l_ptA2
l_ptB1
l_ptB2
```skill
) -> f_dotProduct
```

**描述** (Description):

**说明**：计算点积或标量积。

**Original**: This calculates the dot or scaler product.

Dot Product:
```skill
(ptB1.y - ptA1.y)*(ptB2.y - ptA2.y) + (ptB1.x - ptA1.x)*(ptB2.x - ptA2.x)
```
Line are perpendicular when return is 0.0

**参数** (Arguments):

Four coordinates describing 2 lines.

**返回值** (Value Returned):

Dot product result.

**示例** (Example):


---


### axlMidPointLine


**语法** (Syntax):
```skill
axlMidPointLine(list(5:20 15:30)) = (10.0 25.0)
```


**参见** (See Also):

axlDistance

---


### axlMidPointArc

```skill
axlMidPointArc(
```
ll_endPoints
l_center
f_radius
g_clockwise
```skill
) -> l_midPoint
```

**描述** (Description):

Returns mid-point on a arc. Note mid-point may not be on a database coordinate. All parameters may be obtained from a arc dbid.

**参数** (Arguments):

ll_line
arc end points
l_center
center of arc
f_radius
arc radius
g_clockwise
Is arc in clockwise (
t
```skill
) or counter clockwise direction (
```
nil
```skill
)
```

**返回值** (Value Returned):

l_midPoint
mid-point of line
nil
error in arguments

**参见** (See Also):

axlMidPointLine

**示例** (Example):

try clockwise
```skill
axlMidPointArc(list(20:0 0:20) 0:0 20 t) = (-14.14214 -14.14214)
```
try counter-clockwise

---


### axlMidPointLine

```skill
axlMidPointArc(list(20:0 0:20) 0:0 20 nil) = (14.14214 14.14214)
axlMidPointLine(
```
ll_line
```skill
) -> l_midPoint
```

**描述** (Description):

Returns mid-point of line. Note mid-point might not be a database coordinate.

**参数** (Arguments):

ll_line
Two end points

**返回值** (Value Returned):

l_midPoint
mid-point of line
nil
error in arguments

**示例** (Example):

```skill
axlMidPointLine(list(5:20 15:30)) = (10.0 25.0)
```

**参见** (See Also):

axlMidPointArc

---


### axlMPythag

```skill
axlMPythag(
```
l_pt1
l_pt2
```skill
) -> f_distance/nil
```

**描述** (Description):

Calculates distance between two points using Pythagoras. This is faster then building this code in SKILL.
The
l_ptN
is an x:y coordinate.

**参数** (Arguments):

l_pt1, l_pt2
Two xy points.

**返回值** (Value Returned):

f_distance
Distance between points.
nil
Arguments were not xy points.

**参见** (See Also):

axlMXYAdd

**示例** (Example):


---


### axlMUniVector

```skill
axlMPythag(1263.0:1062.0 1338.0:1137.0) -> 106.066
axlMUniVector(
```
l_pt1
l_pt2
[f_length]
```skill
) -> l_uniPt1
```

**描述** (Description):

This calculates a unit-vector. A unit vector allows one to calculate points additional points along that line.
It has two modes of operation:
Without a length returns a unit vector to use in other operations like
axlMXYMult
. Use this mode if you need to calculate several points from the same unit vector.
With a length, calculates a new
xy
location f_length from l_pt1 along the vector specified by
pt1
and
pt2
.
This provides optimized solution over the traditional trigonometric approach.

**参数** (Arguments):

l_pt1, l_pt2:
2 xy points
f_length:
optional length to project

**返回值** (Value Returned):

Returns a unit-vector, xy point
nil:
arguments were not xy points

**示例** (Examples):

Found a point 5 units along a line from 1263.0:1062.0 to 1338.0:1137.0
origin = 1263.0:1062.0
uniVec = axlMUniVector(origin 1338.0:1137.0)
res = axlMXYMult(uniVec, 5.0 origin)
Same as example 1 except have
uni vec
do all the work
res = axlMUniVector(origin 1338.0:1137.0 5.0)

---


### axlMXYAdd

```skill
axlMXYAdd(
```
l_pt1
l_pt2
```skill
) -> l_pt/nil
```

**描述** (Description):

This does a
l_pt1 + lpt2
and returns the result.
The
l_ptN
is an x:y coordinate.

**参数** (Arguments):

l_pt1, l_pt2
Two xy points.

**返回值** (Value Returned):

l_pt
Returns coordinate that is result of addition.
nil
Arguments are not coordinates.

**参见** (See Also):

axlMXYSub

**示例** (Example):


---


### axlMXYMult

```skill
axlMXYAdd(1263.0:1063.0 1338.0:1137.0) -> (2601.0 2200.0)
axlMXYMult(
```
l_uniVec
f_factor
[l_origin]
```skill
) -> l_pt/nil
```

**描述** (Description):

This is a convenience function that does a
l_pt.x * f_factor
and
lpt.y * factor
and returns the result. If provided an origin, it adds the origin.
```skill
(l_uniVec * f_factor) + l_origin
```
It is normally used in conjunction with
axlMUniVector
to project a point along a vector.

**参数** (Arguments):

l_uniVec
xy point
f_factor
multiplication factor
l_origin
additive point

**返回值** (Value Returned):

l_pt
Returns resultant coordinate
nil
Arguments are not coordinates

**示例** (Examples):

```skill
axlMXYMult(1263.0:1063.0 2.0) -> (2526.0 2126.0)
```

**参见** (See Also):

axlMUniVector

---


### axlMXYSub

```skill
axlMXYSub(
```
l_pt1
l_pt2
```skill
) -> l_pt/nil
```

**描述** (Description):

This does a
l_pt1 - lpt2
and returns the result.
The
l_ptN
is an x:y coordinate.

**参数** (Arguments):

l_pt1, l_pt2
Two xy points.

**返回值** (Value Returned):

l_pt
Returns coordinate that is result of subtraction.
nil
Arguments are not coordinates.

**参见** (See Also):

axlMXYAdd

**示例** (Example):


---


### axlRadToDeg

```skill
axlMXYSub('(1263.0 1063.0) '(1338.0 1137.0)) -> (-75.0 -74.0)
axlRadToDeg(
```
n_angle
```skill
) => f_angle
```

**描述** (Description):

**说明**：将角度从弧度转换为度。

**Original**: Converts an angle in radians to degrees.


**参数** (Arguments):

n_angle
The angle in radians

**返回值** (Value Returned):

f_angle
The angle in degrees

**参见** (See Also):

axlDegToRad
, axlMathConstants

**示例** (Example):

```skill
axlRadToDeg(0.7853982)
```
=> 45.0

---


### axl_ol_ol2

```skill
axl_ol_ol2(
```
l_seg1
l_seg2
```skill
)
```
⇒
l_result

**描述** (Description):

Finds the intersection point of two lines. If the lines intersect, returns the intersection point with a distance of 0. If the lines do not intersect, the distance is not zero and the function returns
t
.

**参数** (Arguments):

l_seg1
1st line segment (list
x1
:
y1
x2
:
y2
```skill
)
```
l_seg2
2nd line segment (list
x1
:
y1
x2
:
y2
```skill
)
```

**返回值** (Value Returned):

nil
Error due to incorrect argument.
```skill
(
```
car
l_result
```skill
)
```
Intersect or nearest point on seg1
```skill
(
```
cadr
l_result
```skill
)
```
Intersect or nearest point on seg2
```skill
(
```
caddr
l_result
```skill
)
```
Distance between the two intersect points.

**示例** (Examples):

Data for examples
a=list(1:5 5:5)
b=list(2:5 4:2)
c=list(0:0 5:0)
d=list(4:5 7:5)
Example 1
```skill
axl_ol_ol2(a b)
```
⇒ ((2.0 5.0) (2.0 5.0) 0.0)
Intersects line, returns intersection point, note distance of 0.
Example 2
```skill
axl_ol_ol2(a c)
```
⇒ ((3.0 5.0) (3.0 0.0) 5.0)
Lines don’t intersect, returns closest point on each line and distance.
Example 3
```skill
axl_ol_ol2(a d)
```
⇒ ((4.5 5.0) (4.5 5.0) 0.0)
Lines overlap, distance of 0 and selects mid-point of the overlap.

---


### bBoxAdd

```skill
bBoxAdd(
```
l_bBox1
l_bBox2
```skill
) -> l_bBox_result
```

**描述** (Description):

**说明**：将两个边界框相加并返回结果。

**Original**: Adds two bounding boxes together and returns the result.


**参数** (Arguments):

2 bBox values

**返回值** (Value Returned):

Resulting bounding box.

**示例** (Example):

Expand bounding box by 100.
orig = '((200 100) (400 500))
res = bBoxAdd(orig '((-100 -100) (100 100)))
-> ((100 0) (500 600))
Example 2
res = bBoxAdd('((200 100) (400 500)) '((0 0) (200 100)))
-> ((200 100) (600 600))

**Return to top** (Return to top):

⠀
X