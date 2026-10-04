# 第24章 工具/实用函数 (Utility)

> **Original**: Utility Functions
> 
> Product Documentation | Allegro SKILL Reference | Product Version 17.4-2019, October 2019

## 24.1 概述 (Overview)

**说明**：本章描述 AXL-SKILL 实用函数。这些包括用于推导圆弧中心角度和半径的函数，以及将数值转换为不同单位的函数。

**Original**: The chapter describes the AXL-SKILL utility functions. These include functions to derive arc center angle and radius, and to convert numeric values to different units.

### axlCheckString

**说明**：检查提供的字符串是否包含合法字符和长度。您还必须提供数据类型。如果希望查看支持的数据类型列表，请给此 API 传递两个 nil。对于除 PROPVALUE 之外的所有数据类型，它可能会修改提供的字符串并返回更新后的字符串以满足 Allegro 数据库规则。包括：去除前后空白、转换为大写。

**语法**：
```skill
axlCheckString
axlCheckString(
t_type
t_string
) -> t_modString/nil
axlCheckString(
nil
nil
) -> lt_types
axlCheckString(
'error
nil
) -> t_errorMsg/nil
```

**Original**: Description

```
Checks the provided string for legal characters and length. You must also provide the data type. Give this API two nils if you want to see the list of supported data types.
It performs the following checks for the data type provided:
length check
legal characters
For all data types except PROPVALUE, it may also modify the provided string and return the updated string to meet Allegro database rules.
stripping leading and trailing white space
upper case
Unique considerations by data type:
PROPVALUE checks for common property value restrictions. Typically, a property may have more severe restrictions.
GROUP checks for common group naming restrictions. A particular group may enforce additional restrictions.
You should use the return string since it may have been modified.
Errors messages may evolve over time. Last error is only maintained until next call to axlCheckString.
```

**参数**：

t_type
data type (nil to return all supported data types)
t_string
input string
'error
fetch last error message

**返回值**：

t_modString
Modified output string if check is successful
lt_types
List of data types supported
nil
Failed check

**另见**：

axlDBControl
- max name length
Examples
return all supported types
### axlCheckString

**说明**：检查提供的字符串是否包含合法字符和长度。您还必须提供数据类型。如果希望查看支持的数据类型列表，请给此 API 传递两个 nil。对于除 PROPVALUE 之外的所有数据类型，它可能会修改提供的字符串并返回更新后的字符串以满足 Allegro 数据库规则。包括：去除前后空白、转换为大写。

**语法**：
```skill
axlCheckString(nil nil)
typical check
axlCheckString("REFDES" "u1") -> "U1"
error
axlCheckString("NET" "!GND") -> nil
axlCheckString('error nil)
-> "ERROR(SPMHUT-1): Illegal character(s) present in the name or value."
axlCmdList
axlCmdList(
)
⇒
ll_strings
/nil
```

**Original**: Description

```
Lists commands registered by
axlCmdRegister
. The list consists of paired strings.
( (<
allegro command
> <
skill function
>)...)
```

**参数**：

None.

**返回值**：

ll_strings
List of registered Allegro PCB Editor commands paired with the related SKILL functions.
nil
No commands registered.

**示例**：

```skill
axlCmdRegister("interboxcmd" 'axlEnterBox)
axlCmdList()
will return the following:
(
("interboxcmd" "axlEnterBox")
)
axlDebug
axlDebug(
t/nil
) t/nil
Description
This enables/disables AXL debug mode. See
axlIsDebug
for description of what this entails.
Enable debug also enables error messages for invalid attributes of Allegro
dbids
. This enables detecting typos when fetching data from
dbids
. This entails a slight performance hit. For example, if you have a pin
dbid
and you do a
pin->bbox
(instead of
pin->bBox
), then an error will be issued.
Arguments
Values Returned
t
To enable AXL SKILL debug mode.
nil
To disable.
Returns last setting
```

**另见**：

### axlIsDebug

**说明**：检查 AXL 调试模式是否启用。这与 Allegro 环境变量 axldebug 相关联。当设置此模式时，AXL 可能会在 AXL 函数的参数不正确时打印额外的 AXL API 参数警告。

**语法**：
```skill
axlIsDebug
axlDetailLoad
axlDetailLoad(
t_filename
point
f_scale
x_rotation
g_mirror)
==> t/nil
```

**Original**: Description

```
This loads a the designated
ipf
file
(t_filename
) into the current design at location (point), with scaling (
f_scale
), rotation (
f_rotation
) and mirror (
g_mirror
). Items are clipped to rectangle provided a save file time. It will load the detail to the active layer.
scale values much less then 1.0 may have unpredictable results.
```

**参数**：

t_filename
the name of the plot file which contains the detail.
point
the location to place the detail.
f_scale
the scaling factor of the details as a floating point number (1.0 is no scaling). Most be greater then 0.1
x_rotation
the rotating angle in degrees. Rotation is restricted to integers.
g_mirror
whether the detail should be mirrored (t/nil.

**返回值**：

t
was able to load
nil
otherwise

**示例**：

```skill
Select a group of objects and load at 0,0 with double scaling.
- use
ashSelect
function in SKILL examples area
file = "myplt.plt"
objs = ashSelect(nil)
lyr = "MANUFACTURING/DETAIL"
win = axlDBGetDesign()->bBox
when(objs
axlDetailSave(file win objs)
axlLayerCreateNonConductor(layer)
axlVisibleLayer(layer t)
axlSetActiveLayer(layer)
axlDetailLoad(file 0:0 2.0 0 nil)
)
```

**另见**：

### axlDetailSave

**说明**：将裁剪框 (l_bBox) 和传递的几何集 (lo_dbid) 保存到 Allegro ipf 文件 (t_filename)。任何附加到 dbids 的文本都会被保存。忽略逻辑 dbids，如网络、元件等。

**语法**：
```skill
axlDetailSave
,
axlSetActiveLayer – Obsolete
axlDetailSave
axlDetailSave(
t_filename
l_bBox
o_dbid/lo_dbid
[g_filledPads]
)
==> t/nil
```

**Original**: Description

```
This saves a clipping box (l_bBox) and the passed set of geometries (lo_dbid) to a Allegro ipf file (t_filename).
```

**注意**：

:
Any attached text to the dbids is saved.
Ignores logical dbids such as nets, components, etc.

**参数**：

t_filename
the name of the file into which the detail is saved
l_bBox
list of two xy coordinates defining selection box
lo_dbid
list of AXL DBID's or single DBID
g_filledPads
output filled pads as filled (t) or unfilled (nil). Default is filled. Certain other filled figures may be effected by this option

**返回值**：

t
was able to save into the file
nil
otherwise

**另见**：

### axlDetailLoad

**说明**：将指定的 ipf 文件 (t_filename) 加载到当前设计中，位于指定位置 (point)，带有缩放 (f_scale)、旋转 (x_rotation) 和镜像 (g_mirror)。项目被裁剪到保存文件时提供的矩形。它将加载细节到活动层。

**语法**：
```skill
axlDetailLoad
axlEmail
axlEmail(
t_to
t_cc/nil
t_subject
t_body
)
==> t/nil
```

**Original**: Description

```
Sends an e-mail. If multiple
To
or
Cc
addresses are required; separate their names with a semicolon (;). On Windows, a warning confirmer may generate. To disable the warning, add the following to the registry:
HKEY_CURRENT_USER/Identities/[ident code]/Software/
Microsoft/Outlook Express/5.0/Mail/Warn on Mapi Send
Set the data value to
0
.
On UNIX, it is not possible for the interface to return an e-mail delivery failure.
```

**参数**：

t_to
E-mail address.
t_cc
Any carbon copy persons to send;
nil
if none.
t_subject
What to put on the subject line.
t_body
Body of message.

**返回值**：

t
If successful.
nil
Failure.

**示例**：

```skill
axlEmail("aperson" nil "A test message" "anybody home?")
axlHistory
Report history buffer (first to last)
axlHistory(
[x_num]
) -> t
Read or write history to a file
axlHistory(
s_operation
t_filename
) -> t/nil
Description
This is a developers aid only. Do NOT use it in a SKILL program.
Provides command recall capability to the SKILL development window.
Functionality also applies to the Allegro PCB Editor command line except the command is:
"history <n>"
where n is the print the last N commands.
The command line has no ability to read or write history files. They are automatically read on program startup and saved on exit.
History environment variables:
allegro_history = <n>
(default is 200 commands)
Command recall buffer length.
allegro_savehist = <n>
(default off)
Save history file to be saved on program exit. Will be read next time on startup. File is saved at
<HOME>
/pcbenv/history_
<name>
.txt
where
<name>
is SKILL for the SKILL command area
program name for Allegro command area
History support:
!!
– last command (same as
!-1
)
!<num>
– redo command number (ex
!5
)
!-<num>
– redo relative to last cmd (ex
!-2
)
!<str>
– redo cmd starting with string last to first search (ex
!echo
)
!?<str>
– redo cmd matching with string last to first search. For example,
!?unnamed
Arguments
x_num
print last
<num>
commands,
0
or no argument prints entire recall buffer
s_operation
'read
– read history buffer from provided file and append to history
'write
– write history buffer to provided file
t_filename
A history file (default extension is
.txt
)
Value Returned
t
Operation succeeded
nil
Failed
Also prints history buffer if running with option 1.
Example
Report history buffer
a = 1
b = 2
axlHistory()
Save history
axlHistory('write "skillhist")
Read history
axlHistory()
axlHistory('read "skillhist")
axlHistory()
axlHttp
axlHttp(
t_url
)
⇒ t
Description
Displays a URL from Allegro PCB Editor in an external web browser. First attempts to use the last active window of a running web browser, raising the browser window to the top if required. If no browser is running, tries to start one.
On UNIX, supports only the browser, Netscape. If Netscape is not running, tries to start it. May not detect failure if the web page fails to load.
Netscape must be in your search path.
You can override the program name using the environment variable:
set http_netscape = <
program name
>
For example:
set http_netscape = netscape405
On UNIX, this function has been tested with Netscape only and may not function properly with another web browser.
On Windows, this function uses the default web browser listed in the Windows registry. If no browser is registered, this function fails. Both Netscape and Windows Explorer work with this function. You can open any file type with a Windows registry entry.
Arguments
t_url
URL to display.
Value Returned
t
URL displayed in web browser.
nil
Failure due to web browser not being found (on UNIX), not being registered (on Windows), or being unable to load the URL.
The function may not detect when a URL has not loaded on UNIX.
Examples
axlHttp("http://www.cadence.com")
axlIsDebug
axlIsDebug(
) ==> t/nil
Description
This checks if AXL debug mode is enabled. This is associated with the
axldebug
Allegro environment variable.
When this mode is set, AXL may print additional AXL API argument warnings when arguments to AXL functions are incorrect. Many warnings do not obey this variable because they are considered serious or edge conditions. Warnings supported are less serious and are known from user feedback to be troublesome to program around.
Typically, when an AXL API function encounters an argument error, it will print a warning and return
nil
.
When unset, the code runs in development mode and eliminates many of these warnings. You should have this mode enabled when developing SKILL code.
This functionality was introduced in 15.2. Currently, few AXL functions take advantage of this option.
Arguments
None
Value Returned
t
if mode is enabled,
nil
otherwise.
```

**另见**：

axlDebug
Example
when( axlIsDebug() printf("Error\n"))
### axlIsProductLineActive

**说明**：确定给定产品线中的产品是否已启动。

**语法**：
```skill
axlIsProductLineActive
axlIsProductLineActive(t_productLine) -> t/nil
```

**Original**: Description

```
This routine determines if a product in a given product line has been started.
```

**参数**：

productLine
The product line that you want to check.
The legal values are:
SI
PCB
CONCEPT
ORCAD
APD

**返回值**：

t
: There is a license checked out for the given product line.
nil
: There is no license checked out for the given product line.
axlISProductStarted
axlIsPointInsideBox(
t_productName
) -> t/nil
Description
This should not be used, use
axlLicIsProductEnabled
.
axlLicDefaultVersion
axlLicDefaultVersion(
)-> f_version
Description
This returns the default version number used in licensing. Most applications in a release will use this version number when checking out licenses.
Arguments
None
Value Returned
f_version
- floating point number (forexample,16.6)
axlLicFeatureExists
axlLicFeatureExists(
t_license
[f_version]
)-> t/nil
Description
Checks if license feature exists. Does not verify that the license is available. If no version is provided, the tool default version (see
axlLicDefaultVersion
) is used.
Argument
t_license
license name
f_version
floating point number (forexample,16.3)
Value Returned
t
if checkout,
nil
in case of failure

**另见**：

### axlLicIsProductEnabled

**说明**：检查许可证是否已被工具检出。第一种形式：如果给定许可证字符串，当许可证已检出时返回 t，否则返回 nil。第二种形式：如果使用符号 all 调用，则返回工具当前检出的许可证列表。

**语法**：
```skill
axlLicIsProductEnabled
axlLicIsProductEnabled
axlLicIsProductEnabled(
t_license
) -> t/nil
axlLicIsProductEnabled(
`all
) -> lt_licenses
```

**Original**: Description

```
Checks if license is checked-out by tool.
In first form, if given a license string returns
t
when license is checked-out and
nil
if it isn't. The test is based on the result obtained by running tool. There is no SKILL method to determine licenses.
In the second form, if called with the symbol
all
returns a list of licenses currently checked out by the tool.
```

**参数**：

t_license
Name of license (case sensitive)
'all
Get all licenses currently checked-out by the program.

**返回值**：

t
- license checked out
nil
- license not checked out
lt_licenses
- list of licenses checked-out by program (all mode)

**另见**：

axlLicFeatureExists
,
axlLicDefaultVersion
Examples
See if SKILL developer license (product 900) is checked out:
### axlLicIsProductEnabled

**说明**：检查许可证是否已被工具检出。第一种形式：如果给定许可证字符串，当许可证已检出时返回 t，否则返回 nil。第二种形式：如果使用符号 all 调用，则返回工具当前检出的许可证列表。

**语法**：
```skill
axlLicIsProductEnabled("skillDev")
axlLogHeader
axlLogHeader(
p_port
t_titleString
[t_prefix]
)
⇒ t/nil
```

**Original**: Description

```
Writes the standard Allegro PCB Editor log file header to the passed open file. The header record includes:
Title String
Drawing Name
Software Release
Date and Time
```

**参数**：

p_port
SKILL port for the open file.
t_titleString
Title string in the log file header.
t_prefix
Optional prefix string to header for easier parsing (recommend "#")

**返回值**：

t
Wrote log file header to open file.
nil
Failed to write log file header to open file due to incorrect arguments.
axlMKS2UU
axlMKS2UU(
t_mksString
)
⇒
f_value
/nil
Description
Converts between an MKS string to the current database user units. String can be any length name plus many common abbreviations (see
units.dat
file in the Allegro PCB Editor share/text hierarchy for supported names.)
Conversion can fail for the following reasons:
Input string not a legal MKS format.
Conversion will overflow the maximum allowed database size.
Notes:
Conversion between metric and english units may result in rounding.
Return number is rounded to the database precision.
Arguments
t_mksString
Input unit’s string with MKS units.
Value Returned
f_value
Floating point number.
nil
Conversion failed. See previous description for possible reasons.
Example 1
axlMKS2UU("100.1") -> 100.0
Default conversion with database in mils.
Example 2
axlMKS2UU("100 mils") -> 100.0
Database is in mils.
Example 3
axlMKS2UU("100 inches") -> 100000.0
Database is in mils.
Example 4
axlMKS2UU("100 METER") -> 3937008.0
Database is in mils.
axlMKSAlias
axlMKSalias(
t_MKSAlias
)
⇒
t_alias
/nil
Description
Searches the MKS unit database for the current definition associated with
unitName
. Unlike
axlMKSConvert
, this function does not convert.
You load the MKS database from the following file:
<
cds_root
>/share/pcb/text/units.dat
Argument
t_mksAlias
Name of the alias string.
Value Returned
t_def
Definition name as a string.
nil
Definition name could not be found.

**示例**：

```skill
axlMKSAlias("VOLTAGE") -> "V" (Intended usage)
axlMKSAliaas("M") -> "METER"
axlMKSAlias("KG") -> NIL (The function supports only the use of basic units.)
axlMKSConvert
Operates in several ways, depending on the arguments passed.
To convert a number from an input units type to an output unit type, general case:
axlMKSConvert (
n_input
t_inUnits
[t_outUnits]
)
=> f_output/nil
To convert a number from an input units type to MKS units:
axlMKSConvert (
n_input
t_inUnits
nil
)
=> f_output/nil
To convert a number from MKS units to an output unit type:
axlMKSConvert (
n_input
nil
t_outUnits
)
=> f_output/nil
To convert an MKS string to an output units, i.e. ".5 MILS" to "INCHES":
axlMKSConvert (
t_input
[t_outUnits]
)
=> f_output/nil
To pre-register an input units, so that subsequent calls need not specify units:
axlMKSConvert (
nil
t_inUnits
)
=> t/nil
To convert a unit from a pre-registered input units:
axlMKSConvert (
n_input
)
=> f_output/nil
Description
Converts any allowable unit to any other allowable unit. It operates in several ways, depending on the arguments.
In all instances with
t_outUnits
as an argument, if that argument is omitted, the function converts to active design units.
If the first argument is a number and the second argument is evaluated as the units of that number, the number is converted to the units specified by the third argument.
A special case is if first argument is a number, the second is "design" and the third is a length unit then the input number is converted from current design units to specified length units.
In the case where the first argument is a string, that string must be a fully instantiated units string, i.e. "15 MILS". In this case the second string is interpreted as the output units, and the value of the first string is converted to these units.
If the first argument is nil, then the input units specified by the second argument is remembered for the future calls. The output units will default to the active design, and the function will fail as above if no design is active. Note that pre-registration will not work if there is no active design.
When only a number is specified, the function will confirm that an input unit has been pre-registered, and will convert that number, in the pre- registered units, to the design units. Function will issue a warning and return nil if no pre-registered input units, or no active design
When the second and third arguments are present but one is nil, it represents MKS standard units for the input or output units, respectively.
Arguments
n_input
Number to convert
t_inUnits
String giving the units of the input number. If first argument is not specified, this string should specify the input number to convert and its units.
t_outUnits
String giving the new units for
f_output
. If
t_outUnits
is
nil
, converts the number to the current units of the layout.
Value Returned
f_output
Converted value of
n_input
.
nil
Failed to convert value due to incorrect arguments.
Examples
Typical use, convert from design units to another type (design is in mils)
axlMKSConvert(.5 "design" "INCHES") => 0.0005
axlMKSConvert(".5 MILS" "INCHES") => 0.0005
Pre-register a unit type then use if on future conversions
axlMKSConvert(nil "MILS") => t
axlMKSConvert(.5) => 0.0005
Go to default output conversion (METERS)
axlMKSConvert(.5 "MILS" nil) => 2.54e-05
Not just length is supported (go to farads)
axlMKSConvert(1e-09 nil "pF") => 1000.0
axlMKSStr2UU
axlMKSStr2UU(
t_String
)
⇒
t_mksString
/nil
Description
Converts an input string to a MKS string in current database units. If the input string is in MKS units, that is used as the basis for the conversion. If the string has no units, the function uses the default database units for the string.
Conversion may fail for the following reasons:
Input string is not a legal MKS format.
Conversion overflows the maximum database size allowed.
Notes:
Conversion between metric and english units may result in rounding.
Number returned is rounded to the database precision.
Argument
t_String
Input string.
Value Returned
t_mksString
MKS string in current database units.
nil
Failed to convert input string. See earlier Description for possible reasons.
Example
axlMKSStr2UU("100.1") -> "100.0 MILS"
Default conversion with the database in mils.
axlMapClassName
axlMapClassName(
t_oldName/lt_oldName
[g_mapToPCB]
)
⇒
t_newName/lt_newName
Description
Use this function to write a SKILL program that runs in Allegro PCB Editor and APD. You can map from class names to the name appropriate to the program running your SKILL program. For example, you can write a program using Allegro PCB Editor class names and have the program run in APD.
The table shows the name mapping between Allegro PCB Editor and APD.
Table 24-1
Class Name Mapping
Allegro PCB Editor Class Name
APD Class Name
BOARD GEOMETRY
SUBSTRATE GEOMETRY
ETCH
CONDUCTOR
ANTI ETCH
ANTI CONDUCTOR
PACKAGE GEOMETRY
COMPONENT GEOMETRY
PACKAGE KEEPIN
COMPONENT KEEPIN
PACKAGE KEEPOUT
COMPONENT KEEPOUT
BOARD
SUBSTRATE
When using the list of names mode, names that are not recognized are returned "as is".
Argument
t_oldName
Allegro PCB Editor class name.
lt_oldName
List of Allegro PCB Editor class name.
g_mapToPCB
Optional.
t
maps from the APD name to the PCB names. Default is
nil
(PCB to APD conversion).
Value Returned
t_newName
Appropriate class name based on product type.
lt_newName
List of class names renamed.
Examples
Get APD class name when in APD.
axlMapClassName("ETCH") -> "CONDUCTOR"
Gets Allegro PCB Editor class name when in Allegro PCB Editor.
axlMapClassName("ETCH") -> "ETCH"
List in APD
axlMapClassName('("ETCH" "ANALYSIS")) -> ("CONDUCTOR" "ANALYSIS")
axlMemSize
axlMemSize(
)
⇒
x_size
Description
Returns an estimate of memory use. Returns not what the program is
using
, rather what it is
requesting
from the operating system.
Argument
nothing
Value Returned
x_size
Estimate of memory use in bytes.
axlOSBackSlash
axlOSBackSlash(
t_directory
)
==> t_directory/nil
Description
This changes UNIX style forward slashes to DOS style backslashes. While most applications support either style, certain older Windows applications only support DOS style path.
The UNIX style is more amenable to SKILL programming.
On UNIX this just returns the incoming string.
Arguments
t_directory
String containing directory path with forward slashes
Value Returned
t_directory/nil
```

**另见**：

axlOSSlash
Example
p = axlOSBackSlash("/tmp/foo")
-> "\\tmp\\foo"
### axlOSControl

**说明**：查询和/或设置与图形相关的值。如果设置值，返回的是该控件的旧值。

**语法**：
```skill
axlOSControl
axlOSControl(
s_name
[g_value]
)
==> g_currentValue/ls_names
```

**Original**: Description

```
Inquires and/or sets the value dealing with the graphics. If setting a value, the return is the old value of the control.
A side effect of most of these controls is if a form is active that is displaying the current setting it may not be updated. Additional side effects of individual controls, currently supported, are listed in the following table.
Name
Value
Set?
Description
Equivalent
Side Effects
cpu
x_number
No
Returns number of available CPUs. Included in the number are multi-cpu multi-core, and hyper threading.
none
none
is64exe
t/nil
No
Returns t if this executable is 64bit
none
none
is64os
t/nil
No
Returns t if this is a 64bit based OS.
none
none
isWindows
t/nil
No
Returns t if a Windows OS and nil if UNIX or Linux.
none
none
hostname
string
No
Returns hostname of computer this programming is running on.
none
none
physicalMemory
x_number
No
Returns in units of 1Mbyte the amount of physical memory. This is not to be confused with virtual memory.
32bit OS can at most address 4GB (4000MB) of memory. 32bit Windows is restricted to 3GB. So even if you have more installed on your PC this will still report 3GB.
none
none
```

**参数**：

s_name
Symbol name of control. If this value is
nil
, all possible names are returned.
g_value
Optional symbol value to set. Usually a
t
or a
nil
.

**返回值**：

See above
ls_names
If name is
nil
then returns a list of all controls.

**示例**：

```skill
Get CPUs
size = axlOSControl('cpu)
-> 2
Get if 64bit program
axlOSControl('is64exe)
-> nil
```

**另见**：

### axlUIControl

**语法**：
```skill
axlUIControl
,
axlMemSize
axlOSNtp
axlOSNtp(
s_mode
t_serverName/nil
)
==> x_nwtime/t_nwtime/t_server/nil
```

**Original**: Description

```
Reports time from a NTP server.
If the value of
s_mode
is set to
'name
, then Allegro PCB Editor reports the default NTP server, obtained using the environment variable NTPSERVER. Default is
0.pool.ntp.org
.
Currently, the
axlOSNtp
command uses a timeout of 50 milliseconds.
On Linux, you can query NTP time using the following command.
/usr/sbin/ntpdate -q
<hostname>
IPv6 networks not supported.
Must be connected to Internet and, if a firewall is enable, it must be configured to allow port 123.
```

**参数**：

s_mode
The possible values are:
‘name
: Returns default NTP server name for Allegro PCB Editor.
t
: Returns network time and date as string (current time zone)
nil
: Returns time ID (seconds since 00:00:00 UTC, January 1, 1970)
t_serverName
Use NTP server or if the value specified in
nil
, default Allegro NTP server is used.

**返回值**：

x_nwtime
: A time ID. This value is returned when the value of
s_mode
is set to
nil
.
t_nwtime
: Time and date in ASCII using current time zone. This value is returned when the value of
s_mode
is set to
t
.
t_server
: Name of the default time server. Returned when the value of
s_mode
is set to
‘name
.
nil
: Returned in case of an error.

**示例**：

```skill
time = axlOSNtp(t nil)
axlOSExit
axlOSExit(
x_return
)
⇒ no return
Description
This exits the program to the OS with the return value provided. The database is not saved. Typically for Allegro programs:
0
Success
1
Warnings
2
Error
Arguments
x_return
Value Returned
This does not return to the calling SKILL procedure.
Example
axlOSExit(0)
axlPPrint
axlPPrint(
t_name
)
⇒
t_pname
Description
Converts a string with Allegro PCB Editor’s pretty print text function as follows:
Ensures that the first character after a white space, _ (underscore) or / (forward slash) is capitalized.
Ensures the rest of the text in the given string is lower case.
Argument
t_name
A string.
Value Returned
t_pname
The converted string.
Example
axlPPrint("ETCH/TOP") -> "Etch/Top"
axlPdfView
axlPdfView(
t_pdfFile
)
⇒ t
Description
Displays a PDF file from Allegro PCB Editor. If just the filename is given, attempts to find the PDF file using Allegro PCB Editor’s
PDFPATH
variable. Displays the PDF file in an external PDF viewer.
On UNIX, the only supported PDF viewer is Acroread. The program, Acroread, must be in your
PATH
.
On Windows, uses the default PDF viewer registered with the Windows registry. If there is no registered PDF viewer, the call fails.
Argument
t_pdfFile
Name of PDF file to display.
Value Returned
t
PDF file displayed.
nil
Failed to display PDF file due one of the following:
- No Acroread PDF viewer found on UNIX.
- No PDF viewer registered on Windows.
Example
axlPdfView("allegro.pdf")
axlPrintDbid
axlPrintDbid(
o_dbid/lo_dbid
[o_port]
) -> t
Description
This is a debug function to print one or a list of dbids. Output format is terse and parsable. This will not print all attribute data in a dbid but is customized to aid in understanding the dbid data.
Format: <key> <attribute> <value>
where key can be
c
common value of attribute (objType, name, xy)
a
other attributes
l
printable detail on list of dbids associated with element Not all list of dbids are reported.
g
what groups have the object.
Format:
g group <type> name= <name>
Output is either directed to the SKILL window or if port is provided written to a file.
Note using the environment variable,
pv_showelem
you can get the same data in the s
how element
command.
Arguments
o_dbid/lo_dbid
dbid or a list of dbids
o_port
option port object (from outfile)
Value Returned
t
```

**另见**：

axlShowObject
Example
l = axlGetDesign()
### axlPrintDbid

**说明**：这是一个调试函数，用于打印一个或一组 dbids。输出格式简洁且可解析。这不会打印 dbid 中的所有属性数据，而是自定义以帮助理解 dbid 数据。

**语法**：
```skill
axlPrintDbid(l)
axlRegexpIs
axlRegexpIs(
t_exp
)
⇒ t/nil
```

**Original**: Description

```
Determines whether an environment variable expression contains Allegro PCB Editor compatible wildcard characters. Certain select-by-name functions support wildcard characters. You can test for the presence of wildcards before calling the select-by-name type of functions.
Regular expressions used by Allegro PCB Editor are more compatible with the character set allowed in the Allegro PCB Editor object names than SKILL regular expressions. Do not use to test patterns being sent to the SKILL
regexp
family of functions.
```

**参数**：

t_exp
SKILL symbol for the environment variable name.

**返回值**：

t
Expression contains Allegro PCB Editor compatible wildcards.
nil
Expression does not contain Allegro PCB Editor compatible wildcards.
axlRunBatchDBProgram
axlRunBatchDBProgram(
t_prog
t_cmdFmt
[?logfile
t_logfile
]
[?startMsg
t_startMsg
]
[?reloadDB t/nil]
[?noUnload t/nil]
[?silent t/nil]
[?noProgress   t/nil]
[?warnProgram  t/nil]
)
⇒ t/
x_error
Description
Spawns batch jobs that require an open database via an abstract model. When the job completes, it prints a message and optionally reloads (
?reloadDB
) the database if successful. If the database is saved from the current active database, it uses a temporary name to avoid overwriting the database on disk.
The following options are always required (UIBatchSpawn):
t_prog
Name of the program to run.
t_cmdFmt
Command string.
The following options are optional.
t_logFile
Name of log file that the program creates. Registers this with the log file viewlog facility if the program ends in an error. If no log file is required, do not set this option. If no extension is given, adds
.log
as the extension.
startMsg
Enables a start message to display when the program starts. Defaults to the program name. If you override by providing this string, the message begins with
“Starting...”
reloadDB
If you set this to
t
, the database reloads after a successful run of the program. If the batch program does not save the database (for example, reports) then there is no reason to reload database. dbids are refreshed.
noUnload
If you set this to
t
, you don’t save the database to disk. You use this for a program that creates a new database or doesn’t require an Allegro PCB Editor database. Default is
nil
.
silent
If you set this to
t
, no messages are displayed. Use when the user does not need to know that a program is spawned. Default is
nil
.
noProgress
If
t
, the progress meter does not display. Default is
nil
.
noLogview
When set, it prevents display if log file on program exit.
noWarnOnExit
When set, suppresses some exit warning messages.
warnProgram
Program supports warning status (returns 0, if success; 1, if warnings; and 2, if errors).
noExitMsgs
When set, suppresses messages about program success or failure.
For
t_cmdFmt
, the formatting should include everything except the design filename. Place a
%s
where the design should appear. To get a
%s
while doing a
sprintf
, use a “
%%s
” as shown in following examples:
cmdFmt = "netrev -$ -q -r %s"
sprintf(cmdFmt, "%s -$ %s %s %%s", prog, argq argr)
Tip:
For debug, set the env variable,
wait_debug
, on the Allegro command line:
set wait_debug
or in SKILL
axlSetVariable("wait_debug" nil)
This echos the spawning arguments of your program. You can also use this variable to see how Allegro spawns programs from its dialogs. The
"#T<num>.tmp"
name seen in this output is the temporary save of the current design to disk and the use of the
"%s"
argument in your
t_cmdFmt
statement.
For a list of Allegro programs and their command line arguments see the directory:
<cdsroot>/share/pcb/batchhelp
or run the batch program with the
"-help"
argument.
Example: idf_in -help
Many Allegro batch programs support
'-$'
as a standard argument. This prevents prompting for missing input arguments.
Argument
t_prog
string containing program name
t_cmdFmt
string containing starting arguments (including program)
t_logfile
optional string showing logfile
t_startMsg
optional string having start message
?reloadDB
Optional t/nil having database be reloaded after job completes
?noUnload
Optional t/nil stating database shouldn't be saved
?silent
Optional t/nil controlling info messages
?noProgress
Optional t/nil controlling progress meter
Value Returned
t
Batch job ran.
x_error
Error number that is program dependent on failure.

**示例**：

```skill
Spawn genfeedformat which requires design to be saved to a temp file
Program Args:
-$
- silent
-b
- name of design (required)
%%s
- because we
sprintf
the format before calling batch we need to escape the
%s
by perpending an extra %
SKILL:
sprintf(format "genfeedformat -$ %s %%s", "-b")
;format=  "genfeedformat -$ -b %s"
axlRunBatchDBProgram("genfeedformat" format
?logfile "genfeed")
Without
sprintf
axlRunBatchDBProgram("genfeedformat" "genfeedformat -$ -b %s" ?logfile "genfeed")
Spawn 3rd party program, notepad, on an existing file
"allegro.jrl".
In this case we do not want to save design (
?noUnload t
) and no progress meter is required (
?noProgress t
)
axlRunBatchDBProgram("notepad" "notepad allegro.jrl"
?noUnload t ?noProgress t)
Spawn 3rd party import login, a program that requires read/write database wrapping. Read existing 3rd party netlist file called "netlist.txt". Since design needs to be reloaded if import is successful use the "?reloadDB t" option.
Program Args:
-$
- silent
-g
- run gate assign
-y 1
- Always Place changed component
netlist
- name of netlist file (for example, netlist.txt)
%s
- use current design
SKILL:
axlRunBatchDBProgram("netin"
"netin -$ -g -y 1 netlist %s"
?startMsg "Logic Import"
?logfile "netin"
?reloadDB t)
Export IDF
Program Args:
-d IDF  - File name type
-V 3.0  - IDF version
-h 2000 - default package height
-s ...  - Source id (note \"...\" allows spaces in name)
-o myidf - output idf files (with bdf and ldf extensions)
%s - axl will enter name of temp database saved to disk
SKILL:
axlRunBatchDBProgram("idf_out"
"idf_out %s -d IDF -o myidf -s \"allegro_16.3\" -b 1 -h 2000 -V 3.0")
Import IDF, assumes an existing bdf file, unnamed.bdf. If successful load updated design back into memory via the reload option (
?reloadDB t
).
Program Args:
-o %s - name of current design (%s - substitute in current design)
unnamed - name of bdf file on disk
SKILL:
axlRunBatchDBProgram("idf_in" "idf_in -o %s unnamed" ?reloadDB t)
axlShowObject
axlShowObject(
lud_dbid
)
⇒ t/nil
Description
Displays the object data for each
dbid
in
lud_dbid
in a
Show Element
window. Does the same function as the interactive command
list element.
lud_dbid
can be either a single
dbid
or a list of
dbids
.
Arguments
lud_dbid
dbid
, or list of
dbids
.
Value Returned
t
Displayed the
Show Element
window for any objects.
nil
Failed to display the Show Element window for any objects.
Example
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
⇒ t
Defines the string-valued property
MYPROP
.
Adds it to the net
ENA2
.
Displays the result to the user with
axlShowObject
.
axlSleep
axlSleep(
x_time
)
==> t/nil
Description
Sleeps specified time.
This is a replacement for SKILL's sleep which is actually provided by the IPC SKILL package. On Windows the IPC sleep crashes if you call
axlEnterEvent
.
If you are using the IPC interfaces then you should call
axlSleep
instead of using
sleep
.
Arguments
x_time
Time in seconds.
Value Returned
t
All of the time.
axlSort
axlSort(
t_infile
t_outfile
[
t_sortfields
]
[
t_sort_options
]
)
⇒ t/nil
Description
Sorts contents of a given input file and places results in the output file. No warning is given if the output file overwrites an existing file - any checking must be done by the caller of this function.
Default sort is a left to right, ASCII ascending sort of the input file, with duplicate lines left in. You can control the sort behavior using the optional parameters.
Argument
t_infile
Name of the input file to sort.
t_outfile
Name of the file containing results of the sort.
t_sortfields
String specifying which fields to use as sort keys, the sort order of those fields, and how to interpret the data type of the field for sorting. String contains a series of triplets:
field_number sortOrder fieldType
String can contain multiple triplets separated by commas. Triplets can contain valid elements as shown:
Triplet Element
Description
field_number
Number representing the position of the field on the line, from left to right. Numbering starts at 1.
sortOrder
A - Ascending sort order
D - Descending sort order
fieldType
A - Alpha
I - Integer
F - Float
An example of a
t_sortfields
triplet:
"3 A A, 5 D I, 1 A F"
This triplet sorts based on the following:
The third field, ascending, field type ASCII.
The fifth field, descending, field type Integer.
The first field, ascending, field type Float.
t_sort_options
String containing directives controlling the global sort parameters. Sort options can appear in any order, and must be separated by commas. These options are available:
Option
Description
Field Delimiter
Supported delimiters include any character in punctuation character class except comma.
U
Remove duplicate lines. Default is keep duplicate lines.
D
Descending order. Default is ascending order.
An example of the
t_sort_options
string:
"!,U"
This means to use the ‘
!
’ character as the field delimiter and to remove any duplicate lines.
Value Returned
t
Sort successful.
nil
Sort unsuccessful due to incorrect arguments.
Examples
Input file
2!3!4!5!6
2!3!4!5!6
5!6!7!8!9
5!1!7!8!9
2!2!3!4!5
1!2!3!4!5
3!4!5!6!7
4!5!6!7!8
Example 1
(axlSort "input.txt" "output.txt" nil "!,U")
Results 1
1!2!3!4!5
2!2!3!4!5
2!3!4!5!6
3!4!5!6!7
4!5!6!7!8
5!1!7!8!9
5!6!7!8!9
Example 2
(axlSort "input.txt" "output.txt" "2 A I, 1 D I" "!")
Results 2
5!1!7!8!9
2!2!3!4!5
1!2!3!4!5
2!3!4!5!6
2!3!4!5!6
3!4!5!6!7
4!5!6!7!8
5!6!7!8!9
axlStrcmpAlpNum
axlStrcmpAlpNum(
t_str1
t_str2
)
⇒ t/nil
Description
Provides an alpha-numeric sort similar to
alphalessp
with one important distinction. If both strings end in the number, the number portion is separated and the two stripped strings are first compared. If they are equal, then the number sections are compared as numbers, rather than strings.
alphalessp
sort
U1 U10 U2
axlStrcmpAlpNum
sort
U1 U2 U10
Arguments
t_str1
A string
t_str2
A string
Value Returned
0
The two strings are equal.
+num
If
t_str1
is greater than
t_str2
(1 goes after 2)
nil
If
t_str1
is less than
t_str2
(1 goes before 2)
Example
l = '("U5" "U10" "U1" "U5" "U2")
sort(l 'axlStrcmpAlpNum)
===> ("U1" "U2" "U5" "U5" "U10")
axlStringCSVParse
axlStringCSVParse(
t_string
[g_stripWhite]
[t_separator]
) -> lt_string/nil
Description
Parses a comma delimited line (typical from Excel). This differs from the SKILL parseString function in several areas which make it compatible with Excel csv file format:
parseString ignores two adjacent commas.
if a separator is contained within a cell, Excel quotes the cell.
parseString
treats this as two cells.
Correctly processes double quotes in a cell.
Arguments
t_string
A csv string
g_stripWhite
Option to strip leading and trailing white space from each output string. Default is to leave whitespace. Do not advise using this option with separator set to " ".
t_separator
Optional separator character, default is a comma (,).
Value Returned
lt_string
list of strings parsed based on comma separator.
nil
error (unlikely to happen)
```

**另见**：

parseString in Cadence SKILL Language Reference Examples White space strip example ret = axlStringCSVParse(" a ,b" t) -> ( "a" "b") Properly parse a csv file ret = axlStringCSVParse("a,,c,\"d,e\"" ) -> ( "a" "" "c" "d,e") Properly parse a csv file ret = axlStringCSVParse("a||c|\"d|e\"" nil "|" )

### axlStringRemoveSpaces

**说明**：去除字符串的前后空白（标准 C 的 isspace() 宏）。有两种模式：单个字符串和字符串列表。

**语法**：
```skill
axlStringRemoveSpaces
axlStringRemoveSpaces(
t_string
) -> t_modString/nil
axlStringRemoveSpaces(
lt_string
) -> lt_modString/nil
```

**Original**: Description

```
This will strip leading or trailing whitespace from a string (standard C
ilspace()
macro). Has two modes:
one string
list of strings
In list of strings, items in list that are not a string are filtered out of the return.
```

**参数**：

t_string
A string.
lt_string
list of strings

**返回值**：

t_modString
Modified string
lt_modString
Modified strings
nil
Not a string

**另见**：

axlCheckString
Example
ret = axlStringRemoveSpaces(" a ")
ret = axlStringRemoveSpaces( '(" a " " b "))
### axlVersion

**说明**：返回 Allegro PCB Editor 或操作系统相关的数据。

**语法**：
```skill
axlVersion
axlVersion(
s_option
)
⇒
g_value
/nil
```

**Original**: Description

```
Returns Allegro PCB Editor or OS dependent data.
```

**参数**：

s_option
SKILL symbol for the environment variable name.

**返回值**：

Return depends upon option given.
Option
Value
Returns
none
ls_values
List of available options.
version
f_value
Allegro PCB Editor program version, for example, 15.7.
tVersion
t_value
Allegro PCB Editor program version as a string, for example, 16.3.
fullVersion
t_value
Allegro PCB Editor program version and patch as a string (for example, 15.7 s01).
buildDate
t_value
Date program was built at Cadence (month/day/year), for example, 7/19/2006.
release
t_value
Allegro PCB Editor release value. Consists of a prefix and a number (
<p><nn>
), where prefixes are as shown:
A - Alpha
B - Beta
P - Production
S - Patch
For example, S23 indicates the 23
rd
patch release.
internalVersion
t_value
Internal program version, for example,
v13-5-26a.
programName
t_value
Executable being run, for example,
allegro
.
displayName
t_value
Short display name of program (may contain spaces.) Certain programs may change this during run-time depending on the license level. This may be the same or shorter then the formal name. It may change from release to release.
Example:
"Allegro PCB Designer"
formalName
t_value
Long display name of program (may contain spaces). This is the full formal name of program and may change during run-time since it depends upon the license level. The name can be the same or longer than '
displayName
, and may change from release to release.
isWindows
g_value
t
if Windows operating system.
nil
if UNIX operating system.
isAPDSi
g_value
t
if Allegro Package Designer SI L ,
nil
otherwise
isAPDSiL
g_value
t
if Allegro Package Designer SI L,
nil
otherwise
isAllegroExpert
g_value
t
if Allegro Expert product,
nil
otherwise.
isAllegroDesigner
g_value
t
if Allegro Designer product,
nil
otherwise.
isAllegroOrcad
g_value
t
if Allegro OrCAD product,
nil
otherwise.
isAllegroPCB
g_value
t
if Allegro PCB product,
nil
otherwise.
isAPD
g_value
t
if Allegro Package Designer product,
nil
otherwise.
isAPDL
g_value
t
if Allegro Package Designer L,
nil
otherwise
isAPDXL
g_value
t
if Allegro Package Designer XL,
nil
otherwise
isAPDLegacy
g_value
t
if Allegro Package Designer VT2300,
nil
otherwise
isChipIOPlanner
g_value
t
if any Chip I/O Planner product,
nil
otherwise
isICP
g_value
t
if any ICP based product (apd, sip),
nil
otherwise
isSIP
g_value
t
if any SIP product,
nil
otherwise
isSIPDigital
g_value
t
if any SIP Digital product,
nil
otherwise
isSIPDigArch_L
g_value
t
if any SIP Digital Architect L product,
nil
otherwise
isSIPRF
g_value
t
if any SIP RF product,
nil
otherwise
isSIPRFArch_L
g_value
t
if any SIP RF Architect L product,
nil
otherwise
isSigxp
g_value
t
if any version of SigXP product,
nil
otherwise.
isSxExpert
g_value
t
if SigXP Expert product,
nil
otherwise.
isSxExplorer
g_value
t
if SigXP Explorer product,
nil
otherwise.
isEmbedded
g_value
t
if Embedded placement allowed.
isBackdrill
g_value
t
if Backdrill functionality allowed.
isToolbox
g_value
nil
no toolbox,
'orcad
–
OrCAD toolbox active,
'allegro
–
Allegro toolbox
axlIsToolbox()
: API is provided for legacy purposes and returns the same results.
isSymphony
g_value
t
if running in Symphony (multi-user) mode.

**示例**：

```skill
axlVersion()
axlVersionIdGet
axlVersionIdGet(
)
⇒
x_time
Description
Returns an id stamp based upon computer time.
Argument
none
Value Returned
x_time
Returns an id stamp based on computer time.
axlVersionIdPrint
axlVersionIdPrintd(
x_time
/
t_time
)
⇒
t_printTime
/nil
Description
Prints version_id.
VERSION_ID is stored as a property on the database root and on the symbol definitions as shown:
axlDBGetDesign()->prop->VERSION_ID
Use to determine if a symbol should be refreshed. VERSION_ID is updated every time the database is saved, except if done as part of an uprev.
Argument
x_time
/
t_time
VERSION_ID obtained from the database property or returned from
axlVersionIdGet()
.
Value Returned
t_printTime
Printable string in standard Allegro PCB Editor date/time format.
nil
Failed to print VERSION_ID due to incorrect argument.
Example
axlVersionIdPrint(axlDBGetDesign()->prop->VERSION_ID
-> "Mon Dec 16 12:45:16 2004"
Return to top
⠀
X
```
