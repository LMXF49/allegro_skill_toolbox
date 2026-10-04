# 11. 表单接口 (Form Interface)

## 概述 (Overview)

本章描述用于创建 Allegro PCB Editor 表单（对话框）并通过它们与用户交互的控件类型和函数。

### axlFormCreate

**说明**：基于表单描述文件 `t_formfile` 创建对话框。此调用仅支持 `"fixed"` 类型的表单，如果 `t_formfile` 包含任何可变图块，则失败。此函数不显示表单。使用 `axlFormDisplay` 显示表单。支持替代接口，允许将表单文件内容嵌入 SKILL 代码中。与提供外部表单文件名称不同，请提供名称（`t_formName`）用于脚本编写，并将表单文件内容（`t_contents`）作为字符串提供。打包的 SKILL 代码中有一个示例，位于 `<cdsroot>/share/pcb/examples/form/finline.il` 文件末尾。此方法的优势在于仅分发一个文件。

**Original**: Creates a dialog based on the form descriptive file
t_formfile
. This call only supports forms of type
“fixed”
and fails if
t_formfile
contains any variable tiles. This function does not display the form. Use
axlFormDisplay
to display a form.
An alternative interface is supported that allows embedding the contents of the form file in the SKILL code. Instead of passing the external form file name provide the name (t_formName) for scripting purposes and form file contents (t_contents) as string. The packaged SKILL code has a example of this method at the end of the
<cdsroot>
/share/pcb/examples/form/finline.il
file. This method has the advantage of only distributing one file.
Rules to remember when creating this form content string:
Every non-blank line must have a tab character
Example:
FILE_TYPE=FORM_DEFN VERSION=2
Any embedded quotes must be escaped (use backslash ’\’)
Example:
MENUBUTTON \"Ok\" 10 3\n
Any parenthesis '()' must be escaped '\'
If
s_formHandle
is an existing
r_form
, then
axlFormCreate
does not create a new form, but simply exposes and displays the existing form,
s_formHandle
, and returns
nil
.

**语法**：
```skill
axlFormCreate
does not create a new form, but simply exposes and displays the existing form,
s_formHandle
, and returns
nil
.
```

**参数** (Arguments)：

s_formHandle
- **Global** — SKILL symbol used to reference form.
Note:
- **Do** — not use the same symbol to reference different form instances.
t_formfile
- **Filename** — of the form file to be used to define this form.
axlFormCreate
- **uses** — the Allegro PCB Editor environment variable,
FORMPATH
, to find the file, if
t_formfile
- **is** — not a full path. The filename, by convention, should use the
.form
extension.Alternative interface to embed form file into SKILL code:
t_formName
: Name of form (used for scripting)
(t_contents)
: Contents of form file. This may be a string or a list containing or a string. The string format is obsolete and you should use
t_contents
t_contents
: the list with string format
lt_placement
- **Form** — placement. Allegro PCB Editor uses its default placement if this argument is
nil
. See
- **Window** — Placement
g_formAction
- **Specifies** — the SKILL commands (callbacks) to be executed after every field change (Note that this is very different from Cadence IC forms). You can set this to one of the formats shown.
g_form
Action
Options
Option

**返回值** (Value Returned)：

r_form
dbid
of form created.
nil
No form created.

**示例** (Examples)：

See
<cdsroot>/share/pcb/examples/form
basic: demonstrates basic form capabilities
finline.il shows correct inline method
grid: demonstrates grid control capabilities
wizard: form when used in a Wizard mode
finline: demonstrates inline option to avoid having a .form file
See
AXL Forms: Example 1
.

**参见** (See Also)：

axlFormIntroDoc: Introduction to the Allegro Form Package.
axlFormBNFDoc: Form file language description
axlFormCallback: Methods and structures for interacting with user.

### axlFormClearMouseActive

**说明**：清除表单上调度 MouseActive 事件的选项。

**Original**: Clears the option to dispatch the MouseActive event on a form.

**参数** (Arguments)：

r_form
- **Handle** — for the form

**返回值** (Value Returned)：

t
Option was cleared
nil
r_form does not reference a valid form

### axlFormClose

**说明**：关闭表单 `r_form`。除非表单在没有回调处理程序的情况下运行，否则必须进行此调用以关闭表单。没有注册的调度处理程序，Allegro PCB Editor 在从 `axlFormDisplay` 返回应用程序之前自动关闭表单。`axlUIWClose` 也执行相同功能。

**Original**: Closes the form
r_form
. Unless the form is running without a callback handler, you must make this call to close the form. Without a registered dispatch handler, Allegro PCB Editor closes the form automatically before returning to the application from
axlFormDisplay
.
axlUIWClose
also performs the same function.

**参数** (Arguments)：

r_form
Form
dbid
.

**返回值** (Value Returned)：

t
Closed the form.
nil
Form was already closed.

**示例** (Examples)：

See
AXL Forms: Example 1
:
(case form->curField
("done"
(axlFormClose form)
(axlCancelEnterFun)
(_extract)
t)

### axlFormDisplay

**说明**：显示已由 `axlFormCreate` 创建的表单 `r_form`。为了获得更好的显示外观，请在调用此函数之前设置表单的所有字段值。阻塞模式下的表单会阻塞，直到用户关闭表单。如果表单已显示，则此函数仅将其显示出来。

**Original**: Displays the form
r_form
already created by
axlFormCreate
. For superior display appearance, set all the field values of the form before calling this function. A form in blocking mode blocks until the user closes the form.
If a form is already displayed, this function simply exposes it.

**语法**：
```skill
axlFormDisplay( form)
```

**参数** (Arguments)：

r_form
Form
dbid
.

**返回值** (Value Returned)：

t
Successfully opened or exposed the form.
nil
Failed to open or expose the form.

**示例** (Examples)：

See
AXL Forms: Example 1
.
axlFormDisplay( form)

### axlFormBuildPopup

**说明**：提供动态更改具有弹出菜单的字段的弹出菜单的功能。这些字段是 enum（或弹出菜单）和其他具有弹出菜单图标的字段。按钮也可以选择性地具有弹出菜单，如果它们有右箭头。在字段没有弹出菜单的情况下尝试此调用是错误的。

**Original**: This provides the ability to dynamically change popups of fields that have them. These fields are enum (or pop-up) and other fields that have a popup icon. Buttons, optionally, may also have a popup if they have a right arrow. Attempting this call on a field without a popup is an error.

**参数** (Arguments)：

r_form
- **a** — form handle
t_field
- **Name** — of form field.
l_pairs
- **May** — be one of four formats where each element is a single popup entry. A maximum of 256 popup entries are allowed.
normal
( (t_display t_dispatch) ... )
- **alternative** — normal
( t_displayNdispatch ... )
- **for** — enum field types
( (t_display x_dispatch) ... )
( (t_display t_dispatch/x_dispatch options) ... )
- **Options** — can be 1 or 2 additional list options that are
S_color/x_color
- **for** — enum field types with color; bold or underline for bold or underlined items.
- **All** — entries in an
l_pairs
- **argument** — must be the same type of format. That is, you cannot have a list containing, for example, both display/dispatch strings and display/enum types, or display/dispatch and single-string entries. Must be one of the formats described. Each list object defines a single popup entry.
- **Table** — 11-3
- **l_pairs** — Format Options
Option

**返回值** (Value Returned)：

t
Field set.
nil
Field not set.

**示例** (Examples)：

List of lists of string pairs
The first member of each string pair list is the display value–the string displayed in the pop-up. The second member of each string pair is the dispatch value-the string value returned as
form->curValue
when the user selects that pop-up entry.
(list (list "MyPop A" "myvalue_a")
list("MyPop B" "myvalue_b"))
List of lists of pairs
List of lists of pairs where the first member of each pair is a string giving the display value, and the second member is an integer that is the dispatch value, returned as
form – curValue
when the user selects that pop-up entry.
You can use the return value as an index into an array.
(list (list "MyPop A" 5)
list("MyPop B" 7))
List of strings
Uses each string both for display value and the return value.
(list "MyPop A" "MyPop B")
Optional field
Specifies a color swatch. This is currently only supported by ENUM field types (it is ignored by other field types). With an ENUM you need to add
OPTIONS ownerdrawn
in the form file for the FIELD in question to see the color swatch in the popup. You can use either pre-defined color names (see
axlColorDoc
) or Allegro board colors (see
axlLayerGet
).
You can't mix this color type in a single popup.
'(("Green" 1 green) ("Red" 2 red) ("Yellow" 3 yellow))
'(("Top" "top" 2) ("Gnd "gnd" 4) ("Bottom" "btm" 18))
If instead of a color or Allegro color number, you provide a
nil,
then that popup entry will not have a color swatch.
'("(None" 0 nil) ("Green" 1 green) ("Red" 2 red)
("Yellow" 3 yellow))
Font type of bold or underline can be specified via:
'(("Top" "top" bold) ("Gnd "gnd" underline) ("Bottom" "btm"))
When font type is combined with color it looks like:
'(("Top" "top" "Green" bold)  ("Gnd "gnd" "Red" underline)
Notes:
Allows a maximum of 1000 pop-up entries in one pop-up.
If creating a dynamic popup (entries created under program control) a dummy entry must exist in the form file or build popup will fail. Example:
<popupname> """".
The field name is actually a search mechanism. We first search the fields for the field name with a popup and then search the popup names. Since the only way to change grid column or cell based popups is by popup name you may run into failures if that popup name has the same name as another field in the form.

### axlFormGetField

**说明**：获取打开表单 `r_form` 中 `t_field` 的值。如果 `axlFormCreate` 中设置了 `g_stringOption`，则值为字符串。否则，值是表单文件中声明的字段类型。

**Original**: Gets the value of
t_field
in the open form
r_form
. The value is a string if
g_stringOption
was set in
axlFormCreate
. Otherwise the value is in the field type declared in the form file.

**语法**：
```skill
axlFormGetField( form "view_file")
⇒ "allegro2rlb_view.txt"
Examines the value of "
view_file
" .
axlFormGetFieldRange
axlFormGetFieldRange (
r_form
t_field
)
⇒ l_fieldRange/nil
```

**参数** (Arguments)：

r_form
Form
dbid
.
t_field
- **Name** — of field.

**返回值** (Value Returned)：

g_value
Current value of the field.
nil
Field does not exist, or false if boolean field such as check box or radio button.

**示例** (Examples)：

Load the example code given in
AXL Forms: Example 1
.
Enter the command
myExtract()
on the SKILL command line.
The command displays the
Extract Selector
form, listing all available extract view files.
Select any file in the list, or type a name into the
View File
field.
allegro2rlb_view.txt
is entered.
axlFormGetField( form "view_file")
⇒ "allegro2rlb_view.txt"
Examines the value of "
view_file
" .
axlFormGetFieldRange
axlFormGetFieldRange (
r_form
t_field
)
⇒ l_fieldRange/nil

### axlFormGetOptionValue

**说明**：检索指定表单中字段的值。如果表单未打开、字段不存在或任何其他错误，则返回 `nil`。此函数不会为您进行任何映射。如果 Cadence 更改了表单或字段名称，则必须更新代码以使用新值。

**Original**: Retrieve the value of the field in the specified form.
If the form is not open, the field doesn't exist, or any other error,
nil
is returned.
This function will not do any mapping for you. If Cadence changes a form or field name, you must update your code to the new values.

**参数** (Arguments)：

t_formName
- **Name** — of form to query (see
jrl
- **contents** — for names)
t_fieldName
- **Name** — of field on form (see
jrl
- **contents** — for name)

**返回值** (Value Returned)：

value or
nil

### axlFormGridGetSize

**说明**：返回网格大小，即包含两个元素的列表：行数和列数（如果网格已初始化）。如果网格尚未初始化，或字段不是网格，则返回 `nil` 表示错误。

**Original**: Returns the size of the grid as a list of two elements, the rows and the columns, if grid is initialized. If grid has not been initialized, or field is not a grid, returns nil to indicate error.

**参数** (Arguments)：

r_form
- **Standard** — form handle
t_field
- **Standard** — field name

**返回值** (Value Returned)：

list (rows columns)
If successful
nil
On error

### axlFormListGetCount

**说明**：返回指定列表框中的项目数。

**Original**: Returns a count of number of items in the specified list box.

**参数** (Arguments)：

r_form
- **Form** — control
t_field
- **Name** — of the field

**返回值** (Value Returned)：

x_count
Number of items in the list
nil
If not a list box

**示例** (Examples)：

See
axlform.il
example.

**参见** (See Also)：

axlFormListGetSelCount

### axlFormGridSelected

**说明**：返回多选网格控件中的选中项。仅当网格运行多选行选项时才应使用此功能。

**Original**: This returns the selected item in a multi-select grid control. This should only be used if grid is running with the multi-select row option.

**参数** (Arguments)：

r_form
- **standard** — form handle
t_field
- **standard** — field name

**返回值** (Value Returned)：

Returns list of selected items in a multi-select grid or nil if not the correct control.

**示例** (Examples)：

See
fgrid.il
in
<CDSROOT>
/share/pcb/examples/skill/form/grid
Pseudo code:
axlFormGridEvents(fg "grid" 'mrowselect)
;; select items
selected = axlFormGridSelected(fg "grid")
; if form select rows 5,6,7 (click on 5, then Shift click on 7)
;; select items
selected = axlFormGridSelected(fg "grid")
-> (5 6 7)

**参见** (See Also)：

axlFormGridNewCell

### axlFormGridSelectedCnt

**说明**：返回多选网格控件中选中的行数。仅当网格运行多选行选项时才应使用此功能。

**Original**: This returns the count of rows selected in a multi-select grid control. This should only be used if grid is running with the multi-select row option.

**参数** (Arguments)：

r_form
- **standard** — form handle
t_field
- **standard** — field name

**返回值** (Value Returned)：

Returns count of selected items or
nil
if wrong type of control

**示例** (Examples)：

See
fgrid.il
in
<CDSROOT>
/share/pcb/examples/skill/form/grid
Pseudo code:
axlFormGridEvents(fg "grid" 'mrowselect)
; if form select rows all rows (Ctrl-A in grid)
;; select items
selected = axlFormGridSelectedCnt(fg "grid")
-> 16

**参见** (See Also)：

axlFormGridNewCell

### axlFormGridSetSelectRows

**说明**：允许在多选行模式下设置、清除或切换网格的选择状态。

**Original**: This allows setting, clearing or toggling of selection state for a grid in multi-select row mode.

**语法**：
```skill
axlFormGridSetSelectRows(fg "grid" 4 4 t)
clear rows 4 thru 8 being selected
axlFormGridSetSelectRows(fg "grid" 4 8 t)
clear all rows
axlFormGridSetSelectRows(fg "grid" -1 -1 nil)
toggle state of row 1
axlFormGridSetSelectRows(fg "grid" 1 1 'toggle)
```

**参数** (Arguments)：

r_form
- **standard** — form handle
t_field
- **standard** — field name
x_min
- **min** — row number
x_max
- **max** — row number
g_option
- **what** — to do
t
– set row as selected
nil
– clear row as selected
'toggle
– toggle selected state of row

**返回值** (Value Returned)：

t
if succeeded,
nil
if not a grid field or not in multi-row select mode

**示例** (Examples)：

See
fgrid.il
in
<CDSROOT>
/share/pcb/examples/skill/form/grid
Pseudo code:
axlFormGridEvents(fg "grid" 'mrowselect)
set row 4 as selected
axlFormGridSetSelectRows(fg "grid" 4 4 t)
clear rows 4 thru 8 being selected
axlFormGridSetSelectRows(fg "grid" 4 8 t)
clear all rows
axlFormGridSetSelectRows(fg "grid" -1 -1 nil)
toggle state of row 1
axlFormGridSetSelectRows(fg "grid" 1 1 'toggle)

**参见** (See Also)：

axlFormGridNewCell

### axlFormListDeleteAll

**说明**：删除表单列表字段 `t_field` 中的所有项目。使用 `axlFormListDeleteAll` 清除整个列表字段以使用 `axlFormSetField` 更新它，然后使用 `nil` 字段值在字段上显示 `axlFormSetField`。

**Original**: Deletes all the items from the form list field,
t_field
.
Use
axlFormListDeleteAll
to clear an entire list field to update it using
axlFormSetField
, then display it using
axlFormSetField
on the field with a
nil
field value.

**语法**：
```skill
axlFormListDeleteAll
to clear an entire list field to update it using
axlFormSetField
, then display it using
axlFormSetField
on the field with a
nil
field value.
```

**参数** (Arguments)：

r_form
Form
dbid
.
t_field
- **Name** — of field.

**返回值** (Value Returned)：

t
All items deleted properly.
nil
All items not deleted.

**示例** (Examples)：

In this example you do the following:
Use the
axlFormCreate
examples to create and display the Extract Selector dialog box shown in
Figure 11-1
.
On the SKILL command line, enter:
axlFormListDeleteAll(form "file_list")
==> nil
The list is removed from the dialog box as shown in
Figure 11-2
.
On the SKILL command line, enter:
axlFormSetField(form "file_list" "fu")
axlFormSetField(form "file_list" "bar")
axlFormSetField(form "file_list" nil)
==> t
The Extract Selector dialog box is displayed with new list as shown in
Figure 11-3
.
Figure 11-1
Extract Selector Dialog Box
Figure 11-2
Extract Selector Dialog Box - List removed
Figure 11-3
The Extract Selector dialog box - Displayed with a new list

### axlFormListSelect

**说明**：高亮显示指定项目，如果不在列表中可见，则显示它。由于 Allegro PCB Editor 表单仅允许一个项目可见，因此它会取消选择任何先前选择的项目。如果为 `t_listItem` 传递 `nil`，则列表重置为顶部，并取消选择所选列表项。

**Original**: Highlights, and if not visible in the list, shows the designated item. Since Allegro PCB Editor forms permit only one item to be visible, it deselects any previously selected item. If
nil
is passed for
t_listItem
the list is reset to top and the selected list item is deselected.

**参数** (Arguments)：

r_form
- **Form** — id
t_field
- **Name** — of field.
t_listItem
/nil
- **String** — of item in the list. Send
nil
- **to** — deselect any selected item and set list back to top.

**返回值** (Value Returned)：

t
Highlights item. Arguments are valid.
nil
Arguments are invalid.

### axlFormSetEventAction

**说明**：允许用户注册回调函数，每当用户更改为表单中的新活动单元格时调用该函数。在 `axlFormCreate` 期间注册的回调仅在用户修改表单上的字段值时（退出字段时）调度事件。此函数允许调用者在字段首次被输入时接收事件。

**Original**: This function allows the user to register a callback function to be called whenever the user changes to a new active cell in the form. The callback registered during axlFormCreate dispatches events only when the user modifies a field value on the form (on exit from the field). This function allows the caller to receive an event when a field is first entered.

**语法**：
```skill
axlFormSetEventAction( form '_formEventAction)
```

**参数** (Arguments)：

r_form
Form
dbid
g_callback
- **Specifies** — the SKILL command(s) (callback(s)) to be executed whenever a new field is activated. The setting can be one of two formats:
t_callback
: the string representation of the SKILL command(s) to be executed
s_callback
: the symbol of the SKILL function to be called (the function is passed the
r_form
- **returned** — from
axlFormCreate
- **as** — its only parameter).

**返回值** (Value Returned)：

t
Field set to desired value.
nil
Field not set to the desired value due to invalid arguments.

**示例** (Examples)：

form = axlFormCreate( MyForm
"extract_selector.form" '("E" "OUTER")
'_formAction t)
axlFormSetEventAction( form '_formEventAction)

**参见** (See Also)：

axlFormBNFDoc
and
axlFormCreate

### axlFormSetField

**说明**：设置单个表单字段的值。这些值可能不同，取决于字段类型。对于特定控件的完整讨论，请参阅本节前面的讨论。

**Original**: Sets values of individual form fields. These values may differ and depend on type of the field. For a complete discussion of field types, see the discussion at the front of this section.
Special notes for certain controls:
LIST TYPE
Value may be a string, integer or real. Items are converted to strings before being displayed. A
nil
is needed to display the list.
Alternatively, value may be a list of strings. This results in better performance when you have many items to display.
COLOR TYPE
g_value
parameter may have several types:
s_colorSymbol
Set field to predefined color
x_number
Set field to product color
t
or
nil
Depress or raise field
l_both
A list allows setting both check and value; pass a list of the  color set
s_colorSymbol
May be black, white, red, green, yellow, multivalue, button or default.
x_number
is an integer between 1 and 24 with 0 being background.
CHECKBOX
The values that unset the checkbox are:
nil
,
0
,
"nil"
,
"false"
and
"no"
. All other values set the checkbox.
TRACKBAR
If the field is a trackbar, two modes are supported.
g_value = t
Moves the slider to the next position.
g_value = integer
Absolutely sets trackbar to the indicated position.

**语法**：
```skill
axlFormSetField(fw, "list", "a")
axlFormSetField(fw, "list", "b")
axlFormSetField(fw, "list", "c")
; nil required first time list is displayed
axlFormSetField(fw, "list", nil)
;; display 3 items in list - alternative
axlFormSetField(fw, "list", '("a" "b" "c"))
Color field (field is named
"color"
)
;; sets the color field to pre-defined color "red"
axlFormSetField(fw, "color", `red)
;; sets the color field to product color 1
axlFormSetField(fw, "color", 1)
;; visually depresses the color field if not greyed
axlFormSetField(fw, "color", t)
;; visually depresses the color field and set to
;;      pre-defined green color
axlFormSetField(fw, "color", '(green t))
Tab field (field is named
"tab"
)
;; puts the tab on top
axlformSetField(fw, "tab", nil)
```

**参数** (Arguments)：

r_form
Form
dbid
.
t_field
- **Name** — of field. Field name is a string or symbol.
g_value
- **Desired** — value of field. May be a string, boolean, integer or floating point number or a list; function of field type.

**返回值** (Value Returned)：

t
If Successful
nil
Failed

**示例** (Examples)：

List Field (field is named
"list"
)
;; display 3 items in list
axlFormSetField(fw, "list", "a")
axlFormSetField(fw, "list", "b")
axlFormSetField(fw, "list", "c")
; nil required first time list is displayed
axlFormSetField(fw, "list", nil)
;; display 3 items in list - alternative
axlFormSetField(fw, "list", '("a" "b" "c"))
Color field (field is named
"color"
)
;; sets the color field to pre-defined color "red"
axlFormSetField(fw, "color", `red)
;; sets the color field to product color 1
axlFormSetField(fw, "color", 1)
;; visually depresses the color field if not greyed
axlFormSetField(fw, "color", t)
;; visually depresses the color field and set to
;;      pre-defined green color
axlFormSetField(fw, "color", '(green t))
Tab field (field is named
"tab"
)
;; puts the tab on top
axlformSetField(fw, "tab", nil)

### axlFormSetFieldHelpTip

**说明**：设置与指示字段关联的帮助提示。值可以是简单字符串或具有正确结构的 HTML。请注意，仅当表单上设置了 TOOLTIPHELP 标签以启用鼠标悬停帮助而不是 INFO 字段文本显示字段帮助时，才建议使用 HTML。

**Original**: Sets the help tip associated with the indicated field. The value may be either a simple string or an HTML with a proper structure. Note that HTML is only recommended when the TOOLTIPHELP tag is set on your form to enable mouse-over help instead of INFO field text to display field help.

**语法**：
```skill
axlFormSetFieldHelpTip(form "my_field" "This field is for entering data")
See the use of axlFormSetField in axlFormCreate examples.
```

**参数** (Arguments)：

r_form
Form
dbid
.
t_field
- **Name** — of field.
t_value
- **Help** — tip string to associate with the field,
nil
- **to** — clear existing

**返回值** (Value Returned)：

t
Returns
t
if the help tip was set to desired value.
nil
Otherwise

**示例** (Examples)：

axlFormSetFieldHelpTip(form "my_field" "This field is for entering data")
See the use of axlFormSetField in axlFormCreate examples.

### axlFormSetInfo

**说明**：在打开表单 `r_form` 中将 info `t_field` 设置为值 `t_value`。与 `axlFormSet` 不同，用户无法更改 info 字段。您也可以使用 `axlFormSetField` 实现此功能。

**Original**: Sets info
t_field
to value
t_value
in open form
r_form
. Unlike
axlFormSet
, user cannot change an info field.
You can also use
axlFormSetField
for this function.

**语法**：
```skill
axlFormSetInfo( form "file_list" fileName)
```

**参数** (Arguments)：

r_form
Form
dbid
.
t_field
- **Name** — of field.
t_value
- **Desired** — value of field.

**返回值** (Value Returned)：

t
Field was set to desired value.
nil
Field not set to desired value due to invalid arguments.

**示例** (Examples)：

See the use of
axlFormSetField
in the
“AXL Forms: Example 1”
.
axlFormSetInfo( form "file_list" fileName)

### axlFormSetMouseActive

**说明**：设置表单上调度 MouseActive 事件的选项。虽然这可用于按字段显示动态帮助（这是示例代码的作用），但存在更好的方法，称为 `helptip`，它由表单文件驱动。

**Original**: Sets the option to dispatch the MouseActive event on a form.
While this can be use to display dynamic help on a per field basis (this is what the example code does) a better method exists called the "helptip" which is driven from the form file. See the axlFormBNFDoc (note 12).

**参数** (Arguments)：

r_form
- **Handle** — for the form

**返回值** (Value Returned)：

t
Option was set
nil
r_form
does not reference a valid form

**示例** (Examples)：

See
<cdsroot>/share/pcb/examples/form/basic

### axlFormTest

**说明**：这是一个用于测试目的的开发函数。给定表单文件名称，它会打开表单文件以检查控件的放置位置。如果表单使用标准按钮名称（如 ok、done、close、cancel），则可以通过单击按钮关闭它。否则，请使用窗口控件。如果表单当前打开，则显示表单并返回。

**Original**: This is a development function for test purposes. Given a form file name this opens a form file to check for placement of controls. If form uses standard button names (for example,
ok, done, close, cancel
), you can close it be clicking the button. Otherwise, use the window control. If form is currently open, exposes form and returns.

**语法**：
```skill
axlFormTest("status")
```

**参数** (Arguments)：

t_formName
- **Name** — of form.

**返回值** (Value Returned)：

Form handle if successfully opens.

**示例** (Examples)：

Open Allegro PCB Editor drawing parameter form:
axlFormTest("status")

### axlFormRestoreField

**说明**：将打开表单 `r_form` 中的 `t_field` 恢复为其先前值。先前值仅来自上次用户更改，而不是来自表单设置字段函数。这仅在 `form callback` 函数中有用。在 `form callback` 中使用，以检测用户输入非法值时恢复先前值。

**Original**: Restores the
t_field
in the open form
r_form
to its previous value. The previous value is only from the last user change and not from the form set field functions. This is only useful in the
form callback
function.
Use in the
form callback
to restore the previous value when you detect the user has entered an illegal value in the field.

**语法**：
```skill
axlFormRestoreField
to restore the field to its previous value.
(case form->curField
("view_file"
(if form->curValue
(progn
; Accept user input only if on list
if(member( form->curValue fileList)
then axlFormSetField( form
"view_file" form->curValue)
else axlFormRestoreField(
form "view_file"))))
t)
```

**参数** (Arguments)：

r_form
Form
dbid
.
t_field
- **Name** — of field.

**返回值** (Value Returned)：

t
Field restored.
nil
Field not restored and may not exist.

**示例** (Examples)：

See
“AXL Forms: Example 1”
where the callback function checks that the user has entered a filename that is on the list of available extract view filenames. If the user-entered value is not on the list, then the program calls
axlFormRestoreField
to restore the field to its previous value.
(case form->curField
("view_file"
(if form->curValue
(progn
; Accept user input only if on list
if(member( form->curValue fileList)
then axlFormSetField( form
"view_file" form->curValue)
else axlFormRestoreField(
form "view_file"))))
t)

### axlFormTitle

**说明**：覆盖表单标题。

**Original**: Overrides title of the form.

**语法**：
```skill
axlFormTitle( form "Extract Selector")
```

**参数** (Arguments)：

r_form
Form
dbid
.
t_title
- **String** — to be used for new form title

**返回值** (Value Returned)：

t
Changed form title.
nil
No form title changed.

**示例** (Examples)：

See
“AXL Forms: Example 1”
.
axlFormTitle( form "Extract Selector")

### axlIsFormType

**说明**：测试参数 `g_form` 是否为表单 `dbid`。

**Original**: Tests if argument
g_form
is a form
dbid
.

**参数** (Arguments)：

g_form
dbid
- **of** — object to test.

**返回值** (Value Returned)：

t
r_form
is the
dbid
of a form.
nil
r_form
is not the
dbid
of a form.

**示例** (Examples)：

form = axlFormCreate( (gensym)
"extract_selector.form" '("E" "OUTER")
'_formAction t)
if( axlIsFormType(form)
then (print "Created form successfully.")
else (print "Error! Could not create form."))
Checks that the form you create is truly a form.

### axlFormSetFieldVisible

**说明**：设置表单字段为可见或不可见。

**Original**: Sets a form field to visible or invisible.

**参数** (Arguments)：

r_form
- **Form** — id.
t_field
- **Form** — field name (string).
x_value
1 - set field visible or 0 - Set field invisible

**返回值** (Value Returned)：

t
Form field set visible.
nil
Form field set invisible.

### axlFormIsFieldVisible

**说明**：确定表单字段是否可见。

**Original**: Determines whether a form field is visible.

**参数** (Arguments)：

r_form
- **Form** — id.
t_field
- **Form** — field name (string).

**返回值** (Value Returned)：

t
Form field is visible.
nil
Form field is not visible.
Callback Procedure:

### formCallback

**说明**：这不是函数，而是记录用户与 SKILL 代码之间表单交互的回调接口。SKILL 程序员提供此函数。

**Original**: This is not a function but documents the callback interface for form interaction between a user and SKILL code. The SKILL programmer provides this function.
When the user changes a field in a form, the Allegro PCB Editor form processor calls the procedure you specified as the
g_formAction
argument in
axlFormCreate
when you created that form. The form attribute
curField
specifies the name of the field that changed. The form attribute
curValue
specifies the current value of the field (after the user changed it). If you set
g_stringOption
to
t
in your call to
axlFormCreate
when you created that form, then
curValue
is a string. If
g_stringOption
was
nil
(the default), then
curValue
is the type you specified for that field in the form file.
The term
formCallback
used in the title of this callback procedure description is a dummy name. The callback function name must match the name or symbol name you used as the
g_formAction
argument in
axlFormCreate
when you created the form.
If you specify the callback name (
g_formAction
) as a string in your call to
axlFormCreate
, SKILL calls that function with no arguments. If you specify
g_formAction
as a symbol, then SKILL calls that function with the form handle
as its single argument.
The callback must call
axlFormClose
to close the form and to continue in the main application code if form mode is blocking.
All form information is provided by the
r_form
argument which is a form data type. Applications can extend the data stored on this type by adding their own attributes. Please capitalize the first letter of the attribute name to avoid conflicts with future additions by Cadence to this structure.
Table 11-4
and
Table 11-5
show the available field types and how they impact the
r_form
data type.
Table 11-4
describes Form Field Types using the following:
Type
What the user calls the field
Keyword
What the form file calls the field
curValue
Data type seen in the form dispatch and axlFormGetField. See Callback for more information.
curValueInt
Additional information for certain field types that can be mapped to integers.
Table 11-4
Form Field Types
Type
Keyword
curValue
curValueInt
Button
MENUBUTTON
dispatch action only (t)
1
Check Box
CHECKLIST
t/nil
0 or 1
Radio Button
CHECKLIST
t/nil
0 or 1
Long (integer)
INTFILLIN
integer number
Integer
Real (float)
REALFILLIN
float number
n/a
String
STRFILLIN
string
n/a
Enum (popup)
ENUMSET
string
Possible integer
1
List
LIST
string
Offset from start of list
(
0
= first entry).
Color well
COLOR
t/nil
1
or
0
Tab
TABSET/TAB
string or
t
n/a or
1
/
0
Tree
TREEVIEW
string
see
axlFormTreeViewSet
Text
INFO
n/a
n/a
Graphics
THUMBNAIL
n/a
n/a
GRID
GRID
see
Using Grids
Notes:
What distinguishes between a radio button and a check box is that radio buttons are a group of boxes where only one can be set. To relate several check boxes as radio buttons, supply the same label name as the third field (groupLabel) in the form file description:
CHECKLIST <fieldLabel> <groupLabel>
When a user sets a radio button, the button being unset will dispatch to the application’s callback with a value of nil.
Enum will only set curValueInt on dispatch when their dispatch value of their popup uses an integer. Otherwise this field is
nil
.
Tabs can dispatch in two methods:
Default when a tab is selected, your dispatcher receives the tab name in the curField and curValue is t.
If "OPTIONS tabsetDispatch" is set in the TABSET of the form file, then when a tab is selected your application dispatcher receives the TABSET as the curField and the curValue being the name of the TAB that was selected.
INFO fields can be static where the text is declared in the form file or dynamic where you can set the text via the application at run-time. To achieve dynamic access, enter the following in the form file:
TEXT "<optional initial text>"
INFO <fieldLabel>
... reset of TEXT section ...
Thumbnails support the following methods:
static bitmap declared via the form file
bitmaps that can be changed by the application at run-time
basic drawing canvas -- see
Chapter 12, “Simple Graphics Drawing Functions”
Buttons are stateless. The application cannot set the button to the depressed state. You can only use axlFormSetField to change the text in the button. Several button fieldLabels are reserved. Use them only as described:
done or OK
Do action and close the form.
cancel
Cancel changes and close the form.
print
Print the form -- do not use.
help
Call cdsdoc for help about the form -- do not use.
Table 11-5
Form Attributes
Attribute Name
Set?
Type*
curField
no
string
Name of form field just changed
curValue
no
See -->
Depends on value of
curField
(
string
,
int
,
float
,
boolean
)
curValueInt
no
See -->
Depends on value of
curField
field
doneState
no
int
0
= action;
1
= done;
2
= cancel;
3
= abort
form
no
string
Name of this form
isChanged
no
t/nil
t
= user has changed one or more fields in form.
isValueString
no
t/nil
t
= all field values are strings
nil
= one or more fields are not strings
objType
no
string
Type of object, in this case
"form"
type
no
string
Form type, always
"fixed"
fields
no
list of strings
All fields in the form.
infos
no
list of strings
All info fields in the form.
event
no
symbol
Grid control only -- see
Using Grids
row
no
integer
Grid control only
col
no
integer
Grid control only
treeViewSelState
no
integer
Tree control only
* You can add your own attribute types to the form type. It is recommended you capitalize the first letter of the name to avoid conflict with future Allegro PCB Editor releases.
Notes:
The doneState shows 0 for most actions. Selecting a
Done
or
OK
button sets the done state. Selecting a
Cancel
button sets the cancel state. With the done or cancel state set, you use
axlFormClose
to close the form. Setting the abort state closes the form, even if you do not issue an
axlFormClose
command.
Data type is dependent on the field type. See
Table 11-4
for more information on Form Field Types.
The infos list is different from the fields list. The infos list comprises static text strings that the program can change at run-time. The fields list comprises all other labels which can be changed by the user including even those on buttons and tabs, grayed and hidden fields.

**语法**：
```skill
formCallback
used in the title of this callback procedure description is a dummy name. The callback function name must match the name or symbol name you used as the
g_formAction
argument in
axlFormCreate
when you created the form.
If you specify the callback name (
g_formAction
) as a string in your call to
axlFormCreate
, SKILL calls that function with no arguments. If you specify
g_formAction
as a symbol, then SKILL calls that function with the form handle
as its single argument.
The callback must call
axlFormClose
to close the form and to continue in the main application code if form mode is blocking.
All form information is provided by the
r_form
argument which is a form data type. Applications can extend the data stored on this type by adding their own attributes. Please capitalize the first letter of the attribute name to avoid conflicts with future additions by Cadence to this structure.
Table 11-4
and
Table 11-5
show the available field types and how they impact the
r_form
data type.
Table 11-4
describes Form Field Types using the following:
Type
What the user calls the field
Keyword
What the form file calls the field
curValue
Data type seen in the form dispatch and axlFormGetField. See Callback for more information.
curValueInt
Additional information for certain field types that can be mapped to integers.
Table 11-4
Form Field Types
Type
Keyword
curValue
curValueInt
Button
MENUBUTTON
dispatch action only (t)
1
Check Box
CHECKLIST
t/nil
0 or 1
Radio Button
CHECKLIST
t/nil
0 or 1
Long (integer)
INTFILLIN
integer number
Integer
Real (float)
REALFILLIN
float number
n/a
String
STRFILLIN
string
n/a
Enum (popup)
ENUMSET
string
Possible integer
1
List
LIST
string
Offset from start of list
(
0
= first entry).
Color well
COLOR
t/nil
1
or
0
Tab
TABSET/TAB
string or
t
n/a or
1
/
0
Tree
TREEVIEW
string
see
axlFormTreeViewSet
Text
INFO
n/a
n/a
Graphics
THUMBNAIL
n/a
n/a
GRID
GRID
see
Using Grids
Notes:
What distinguishes between a radio button and a check box is that radio buttons are a group of boxes where only one can be set. To relate several check boxes as radio buttons, supply the same label name as the third field (groupLabel) in the form file description:
CHECKLIST <fieldLabel> <groupLabel>
When a user sets a radio button, the button being unset will dispatch to the application’s callback with a value of nil.
Enum will only set curValueInt on dispatch when their dispatch value of their popup uses an integer. Otherwise this field is
nil
.
Tabs can dispatch in two methods:
Default when a tab is selected, your dispatcher receives the tab name in the curField and curValue is t.
If "OPTIONS tabsetDispatch" is set in the TABSET of the form file, then when a tab is selected your application dispatcher receives the TABSET as the curField and the curValue being the name of the TAB that was selected.
INFO fields can be static where the text is declared in the form file or dynamic where you can set the text via the application at run-time. To achieve dynamic access, enter the following in the form file:
TEXT "<optional initial text>"
INFO <fieldLabel>
... reset of TEXT section ...
Thumbnails support the following methods:
static bitmap declared via the form file
bitmaps that can be changed by the application at run-time
basic drawing canvas -- see
Chapter 12, “Simple Graphics Drawing Functions”
Buttons are stateless. The application cannot set the button to the depressed state. You can only use axlFormSetField to change the text in the button. Several button fieldLabels are reserved. Use them only as described:
done or OK
Do action and close the form.
cancel
Cancel changes and close the form.
print
Print the form -- do not use.
help
Call cdsdoc for help about the form -- do not use.
Table 11-5
Form Attributes
Attribute Name
Set?
Type*
```

**参数** (Arguments)：

r_form
Form
dbid
.

**返回值** (Value Returned)：

t
Always returns
t
.

**示例** (Examples)：

See
axlFormCreate
and
axlFormBuildPopup
for examples.

### axlFormAutoResize

**说明**：调整表单大小以适应其控件。重新计算所需宽度和高度，并根据表单字段的当前可见性调整表单大小。

**Original**: Resizes a form to fit its controls. Recalculates the required width and height and resizes the form based on the current visibility of the form’s fields.

**参数** (Arguments)：

r_form
- **Form** — handle.
t_field
- **Form** — field name (string).

**返回值** (Value Returned)：

t
Form resized.
nil
r_form
does not reference a valid form.

### axlFormColorize

**说明**：允许覆盖控件的背景和/或文本颜色。仅支持以下控件：STRFILLIN、READFILLIN、LONGFILLIN、INTSLIDEBAR、ENUMSET、CHECKLIST、TEXT 或 INFO。这些名称出现在表单 BNF 文件语法中。这些控件使用默认系统颜色：`'background` 设置控件背景；`'text` 设置控件文本。`g_color` 参数是颜色符号（对于非 DB 选项）、数字（对于 DB 颜色选项）或 `nil`（恢复为系统默认值）。

**Original**: Allows the override of background and/or text color of a control. Only the following controls are supported:
STRFILLIN
READFILLIN
LONGFILLIN
INTSLIDEBAR
ENUMSET
CHECKLIST
TEXT
or
INFO
These names appear in the form BNF file syntax.
These controls use the default system colors:
'background
Set background of control
'text
Set text of control
The
g_color
argument is either a color symbol (for non DB options), a number for DB color options, or
nil
(for restoring to system default). See
Accessing Allegro PCB Editor Colors with AXL-SKILL
for the allowed values.
Other form controls support color as a fundamental part of their interface. These are
COLOR
(See
Accessing Allegro PCB Editor Colors with AXL-SKILL
) and
GRID
(See
Using Grids
) controls.
Restrictions
:
Note the following restrictions:
Setting the same or close text and background colors can cause readability issues.
Setting the background of
CHECKLIST
controls is not supported on UNIX.
Dialog boxes with popups do not correctly show color.
If setting the background of a ENUM field on Windows, you must set the OPTION color in the form file as in the following example.
FIELD enum_control
FLOC 16 12
ENUMSET 41
OPTIONS color
POP "enum_popup"
ENDFIELD
This is the same option as the '
ownerdrawn
'. The color option is ignored on UNIX which does not support themes. For theming purposes, Microsoft takes the background color so setting this option disables Microsoft themes for this control.

**语法**：
```skill
axlFormColorize(f1s "string" 'text 'red)
Sets text of string control to red.
Example 2
axlFormColorize(f1s "string" 'background 'green)
Sets background of string control to green.
Example 3
axlFormColorize(f1s "string" 'text nil)
axlFormColorize(f1s "string" 'background nil)
Sets control back to default.
Example 4
axlFormColorize(f1s "string" 'background 1)
Sets control background to Allegro PCB Editor database color 1
```

**参数** (Arguments)：

o_form
- **Form** — handle
.
t_field
- **Field** — name.
g_option
- **Option** — (see above)
g_color
- **Color** — (see
axlColorDoc
) or
nil

**返回值** (Value Returned)：

t
Color changed.
nil
Error due to an incorrect argument.
Example 1
You can find an example in
axlform.il
.
axlFormColorize(f1s "string" 'text 'red)
Sets text of string control to red.
Example 2
axlFormColorize(f1s "string" 'background 'green)
Sets background of string control to green.
Example 3
axlFormColorize(f1s "string" 'text nil)
axlFormColorize(f1s "string" 'background nil)
Sets control back to default.
Example 4
axlFormColorize(f1s "string" 'background 1)
Sets control background to Allegro PCB Editor database color 1

### axlFormGetActiveField

**说明**：获取表单的活动字段。

**Original**: Gets the form’s active field.

**参数** (Arguments)：

r_form
Form’s
dbid
.
t_field
- **Form** — field name (string).

**返回值** (Value Returned)：

t_field
Active field name.
nil
No active field.

### axlFormGridBatch

**说明**：始终与 `axlFormGridSetBatch` 一起使用。高效设置许多网格单元格。

**Original**: Always used with
axlFormGridSetBatch
. Sets many grid cells efficiently.

**参数** (Arguments)：

r_cell
- **Obtained** — from
axlFormGridNewCell
.

**返回值** (Value Returned)：

t
Grid cells set.
nil
No grid cells set.

### axlFormGridCancelPopup

**说明**：在对网格内容进行任何更改后，应用程序必须告诉网格更改已完成。然后网格会向用户更新自身。更改包括：添加或删除列以及更改单元格。

**Original**: After any change to grid content, the application must tell the grid that the changes are complete. The grid then updates itself to the user. Changes include: adding or deleting columns and changing cells.

**参数** (Arguments)：

r_form
- **Form** — handle.
t_field
- **Field** — name.

**返回值** (Value Returned)：

t
Success.
nil
Failure due to incorrect arguments.

### axlFormGridDeleteRows

**说明**：在 `x_row` 编号处删除 `x_number` 行。`x_row = n, x_number = -1` 删除整个网格。`x_row = -1, x_number = -1` 可用于删除网格中的最后一行。

**Original**: Deletes
x_number
rows at
x_row
number.
x_row
=
,
n
>,
x_number
=-1
deletes the entire grid.
x_row
=-1
,
x_number
-1
may be used to delete the last row in the grid.

**参数** (Arguments)：

r_form
- **Form** — handle.
t_field
- **Field** — name.
x_row
- **Row** — number to start delete.
x_number
- **Number** — of rows to delete.

**返回值** (Value Returned)：

t
Rows deleted.
nil
No rows deleted.

### axlFormGridEvents

**说明**：设置用户感兴趣的事件。对于应用程序来说，仅设置实际处理的事件至关重要，因为启用的事件会被脚本化。网格事件包括：`'rowselect`（将网格置于行选择模式。与 `cellselect` 互斥。）、`'mrowselect`（将网格置于多行选择模式。与 `cellselect` 互斥。使用 `axlFormGridSelected` 确定选择了哪些行。）、`'cellselect`（将网格置于单元格选择模式。与 `rowselect` 和 `mrowselect` 互斥。）、`'change`（启用单元格更改事件。如果具有复选框和文本框类型单元格，请使用此选项。）、`'rightpopup`（启用右键弹出菜单。必须在表单文件中指定弹出菜单。）、`'rightpopupPre`（在显示右键弹出菜单之前启用对应用程序的回调。允许用户修改显示的弹出菜单。还需要设置 `'rightpopup`。）、`'leftpopupPre`（在显示左键弹出菜单之前启用对应用程序的回调。允许用户修改显示的弹出菜单。左键弹出菜单仅存在于下拉单元格类型中。）。默认情况下，网格主体启用 `rowselect`，而标题不启用任何功能。

**Original**: Sets user events of interest. It is critical for your application to only set the events that you actually process since enabled events are scripted.
Grid events include the following:
'rowselect
Puts grid into row select mode. This is mutually exclusive with
cellselect
.
'mrowselect
Puts grid into multi-row select mode. This is mutually exclusive with
cellselect
. Use
axlFormGridSelected
to determine what rows are selected.
'cellselect
Puts grid into cell select mode. This is mutually exclusive with
rowselect
and
mrowselect
.
'change
Enables cell change events. Use this option if you have check box and text box type cells.
'rightpopup
Enables right mouse button popup. A popup must have been specified in the form file.
'
rightpopupPre
Enables callback to application before a right mouse popup is displayed. This allows the user to modify the popup shown. Also requires
'rightpopup
be set.
'leftpopupPre
Enables callback to application before a left mouse popup is displayed. This allows the user to modify the popup shown. Left mouse popups are only present in the drop down cell type.
By default, the grid body has
rowselect
enabled while the headers have nothing enabled.
The form callback structure (
r_form
) has the following new attributes that are only applicable for grid field types:
Event
Row
Col
<Data Fields>
rowselect
<
row
>
1
No
cellselect
<
row
>
<
col
>
Yes (1)
change
<
row
>
<
col
>
Yes (1)
rightpopup
<
row
>
<
col
>
Yes
rightpopupPre
<
row
>
<
col
>
No (2) (3)
leftpopupPre
<
row
>
<
col
>
No (2) (3)
where:
<
row
>
Row number (1 based)
<
col
>
Column number (1 based)
<
Data fields
>
Setting of the
r_form
attributes
curValue
,
curValueInt
and
isValueString
.
Communicates the value of the data
before
the field is changed. The change event sends the value
after
the field is changed.
Events are sent immediately before a popup is displayed so the application has the opportunity to modify it. See
axlFormGridEvents
to set this and other event options.
If using events
rightpopupPre
or
leftpopupPre
, the popup may be cancelled by calling
axlFormGridCancelPopup
when you receive one of these events.
See
Using Grids
for a grid overview.
Assigning events to a grid overrides the previous assignment. Therefore, following do not work:
axlFormGridEvents(fw "grid 'change)
axlFormGridEvents(fw "grid 'cellselect)
Instead, use the following command.
axlFormGridEvents(fw "grid '(cellselect change) )

**语法**：
```skill
axlFormGridEvents
to set this and other event options.
If using events
rightpopupPre
or
leftpopupPre
, the popup may be cancelled by calling
axlFormGridCancelPopup
when you receive one of these events.
See
Using Grids
for a grid overview.
Assigning events to a grid overrides the previous assignment. Therefore, following do not work:
axlFormGridEvents(fw "grid 'change)
axlFormGridEvents(fw "grid 'cellselect)
Instead, use the following command.
axlFormGridEvents(fw "grid '(cellselect change) )
```

**参数** (Arguments)：

r_form
- **Form** — handle.
t_field
- **Field** — name.
s_events
- **See** — above.

**返回值** (Value Returned)：

t
User event set.
nil
No user event set.

**参见** (See Also)：

axlFormGridNewCell

### axlFormGridGetCell

**说明**：返回给定行和列的网格单元格数据。返回单元格的所有关联数据。单元格值始终作为字符串返回，REAL 和 LONG 数据类型除外，它们以其本机格式返回。如果使用行或单元格号 0，则返回顶部或侧面标题数据（如果存在。）为了获得最佳性能，在访问多个单元格时重用单元格。

**Original**: Returns grid cell data for a given row and column. All associated data for the cell is returned.
The cell value is always returned as a string except for REAL and LONG data types which are returned in their native format.
If row or cell number of 0 is used then top or side heading data is returned (if present.)
For best performance, reuse the cell if accessing multiple cells.

**参数** (Arguments)：

r_form
- **Form** — handle.
t_field
- **Field** — name.
r_cell
- **Grid** — cell from
axlFormGridNewCell()
.

**返回值** (Value Returned)：

r_cell
Cell data.
nil
Invalid form id, field label or cell doesn’t exist in the grid.

**示例** (Examples)：

cell = axlFormGridNewCell()
cell->row = 3
cell->col = 1
axlFormGridInsertRows(form, "grid" cell)
printf("cell value = %L\n", cell)
Returns the value of cell - (1,3).

### axlFormGridInsertCol

**说明**：使用指示选项将列添加到网格字段。`g_options` 参数基于类型 `formGridCol`。`formGridCol` 结构具有所有设置的默认行为。有关使用此函数的更多信息，请参阅使用网格以获取概述。

**Original**: Adds a column with the indicated options (
g_options
) to a grid field. The
g_options
parameter is based on the type
formGridCol
. The
formGridCol
structure has default behavior for all settings.
For more information on using this function, see
Using Grids
for an overview.
Table 11-6
describes the
FormGridCol
attributes.
Table 11-6
FormGridCol Attributes
Attribute
Type
Default
fieldType
symbol
TEXT
Field types include: TEXT, STRING, LONG, REAL, ENUMSET, and CHECKITEM.
fieldLength
integer
16
Maximum data length.
colWidth
integer
0
Width of column.
headText
n/a
n/a
If the grid has a top heading, sets the heading text. Can also set using
axlFormGridSet
.
Alignment Types (left, right, and center):
align
symbol
Left
Column alignment.
topAlign
symbol
Center
Column header alignment.
scriptLabel
string
<
row number
>
Column scripting name. If the column entry can be edited, you can provide a name which is recorded to the script file. For fieldTypes of TEXT, this option is ignored. Case is ignored and text should not have white space or the symbol ’
!
’.
helpTip
string
n/a
Text to display when user hovers over the column header
popup
string
n/a
Name of the associated popup. May be applied to columns or cells of types ENUMSET, STRING, LONG, or REAL.
Accuracy support is only applicable for LONG and REAL column types. If used, you must set both min and max values.
decimals
integer
n/a
Number of decimal places.
max
integer or float
n/a
Maximum value.
min
integer or float
n/a
Minimum value.
You can add columns to a grid field only at creation time. Once rows have been added to a grid, no new columns may be added. This is true, even if you delete all rows in the grid.

**语法**：
```skill
axlFormGridInsertCol(r_form "grid" options)
Adds the first column of type
TEXT
(non-editable) with center alignment.
Example 2
options->fieldType = 'ENUMSET
options->popup = "grid2nd"
options->colWidth = 10
options->scriptLabel = "class"
axlFormGridInsertCol (r_form "grid" options)
Adds the second column of type
ENUM
(non-editable) with column width of 10 and center alignment, assuming that the form file has a popup definition of
grid2nd
.
```

**参数** (Arguments)：

r_form
- **Form** — handle.
t_field
- **Field** — name.
r_formGridCol
- **Instance** — of type
formGridCol
.

**返回值** (Value Returned)：

t
Column added.
nil
Failure due to a nonexistent form or field, field not of type
GRID
, errors in the
g_options
defstruct, or grid already had a row added.

**示例** (Examples)：

For a complete grid programming example, see:
<
cdsroot
>/share/pcb/examples/skill/form/grid
.
Example 1
options = make_formGridCol
options->fieldType = 'TEXT
options->align = 'center
axlFormGridInsertCol(r_form "grid" options)
Adds the first column of type
TEXT
(non-editable) with center alignment.
Example 2
options->fieldType = 'ENUMSET
options->popup = "grid2nd"
options->colWidth = 10
options->scriptLabel = "class"
axlFormGridInsertCol (r_form "grid" options)
Adds the second column of type
ENUM
(non-editable) with column width of 10 and center alignment, assuming that the form file has a popup definition of
grid2nd
.

### axlIsGridCellType

**说明**：Tests the passed symbol to see if its user type is of the form
"grid cell".

**参数** (Arguments)：

r_cell
Symbol

**返回值** (Value Returned)：

t
Symbol is of the type form grid cell.
nil
Symbol is not of the type form grid cell.

### axlFormGridInsertRows

**说明**：在 `x_row` 编号位置插入 `x_number` 行。行插入为空。`-1` 可用作 `x_row` 以添加到网格末尾。由于网格基于 1，因此 1 插入网格顶部。

**Original**: Inserts
x_number
rows at
x_row
number location. Rows are inserted empty. A -1 may be used as
x_row
to add to end of the grid. Since grids are 1 based, a 1 inserts at the top of the grid.

**参数** (Arguments)：

r_form
- **Form** — handle.
t_field
- **Field** — name.
x_row
- **Row** — number of insertion point.
x_number
- **Quantity** — of rows to add.

**返回值** (Value Returned)：

t
One or more rows inserted.
nil
No rows inserted.

### axlFormGridNewCell

**说明**：创建 `r_cell` 的新实例，这是 `axlFormGridBatch` 或 `axlFormSetField` 用于表单网格控件输入所必需的。为方便起见，使用 API 不会修改单元格属性。在 API 调用之间无需重置所有属性。

**Original**: Creates a new instance of
r_cell
which is required as input to
axlFormGridBatch
or
axlFormSetField
for form grid controls. As a convenience, the consuming APIs do not modify the cell attributes. You need not reset all attributes between API calls.
See axlFormGridDoc for grid overview.
See
axlFormGridSetBatch
for a complete description of cell attributes.

**参数** (Arguments)：

None.

**返回值** (Value Returned)：

r_cell
New list gridcell handle.

**参见** (See Also)：

axlIsGridCellType
,
axlFormGridInsertRows
,
axlFormGridDeleteRows
,
axlFormGridCancelPopup
,
axlFormGridEvents
,
axlFormGridOptions
,
axlFormGridSetBatch
,
axlFormGridBatch
,
axlFormGridGetCell
,
axlFormGridReset
,
axlFormGridSelected
,
axlFormGridSelectedCnt
,
axlFormGridSetSelectRows

### axlFormGridReset

**说明**：将网格重置为其未加载状态。然后应用程序应设置列，然后设置行，以与最初加载窗口时的状态相同。

**Original**: Resets grid to its unloaded state. Application should then set the columns, then rows, to the same state as when they initially loaded the windows.
Changes the number of columns after the grid has already been initialized.

**语法**：
```skill
axlFormGridReset(fg "grid")
initCols()
initRows()
axlFormGridUpdate(fg "grid")
```

**参数** (Arguments)：

r_form
- **Form** — handle.
t_field
- **Field** — name.

**返回值** (Value Returned)：

t
Grid reset.
nil
Grid not reset.

**示例** (Examples)：

For a programming example, see
fgrid.il
in
<
cdsroot
>/share/pcb/examples/skill/
Pseudo code:
axlFormGridReset(fg "grid")
initCols()
initRows()
axlFormGridUpdate(fg "grid")

### axlFormGridSetBatch

**说明**：比 `axlFormSetField` 更快地更改多个网格单元格。两个 API 都需要网格单元格数据类型（`axlFormGridNewCell`）。网格使用 `s_callback` 执行单个回调以填充网格。您必须在回调中调用 `axlFormGridBatch` 才能更新网格单元格。在回调中，仅使用 `axlFormNewCell` 和 `axlFormGridBatch` 来自 `axlForm` API。更改单元格后，在回调外部使用 `axlFormGridUpdate` 更新显示。

**Original**: Changes grid cells much faster than
axlFormSetField
when changing multiple cells. Both APIs require a grid cell data type (
axlFormGridNewCell
.)
Grid performs single callback using
s_callback
to populate the grid. You must call
axlFormGridBatch
in the callback in order to update grid cells.
See the programming example,
fgrid.il
at
<
cdsroot
>/share/pcb/examples/skill/form/grid
. Create rows and columns before calling this batch API.
Within the callback, use only
axlFormNewCell
and
axlFormGridBatch
from the
axlForm
API.
After changing cells, update the display using
axlFormGridUpdate
outside of the callback.
Grid Cell Data Type (r_cell) Attributes
x_row
Row to update.
x_col
Column to update.
g_value
Value (may be string, integer, or float) if
nil
, preserve current grid setting for the cell.
s_backColor
Optional background color.
s_textColor
Optional text color.
s_check
Set or clear check mark for
CHECKITEM
cells. Ignored for non-check cells. Value may be
t
or
nil
.
s_noEdit
If cell is editable, disables edit. Ignored for
TEXT
columns since they are not editable. Current settings are preserved.
s_invisible
Make cell invisible. Current cell settings are preserved by the grid.
s_popup
Use popup name in the form file to set this, or "" to unset. If enum, string, long, or real cell, then overrides column popup, else restores back to popup of the column. Ignored for all other cell types.
t_objType
Object name
"r_cell"
(read-only)
Previous grid cell settings are overridden by values in
s_noEdit
and
s_invisible
.
Column and Row access:
Rows and columns are 1 based. To set the cell in the first column and row, you set the row and col number to 1.
You can control header and script text with reserved row and column values as follows:
(<
row
>, 0)
Set side header display text.
(<
row
>, -1)
Set side header scripting text.
Case is ignored, and text must not contain spaces or the ’
!
’
(0, <
col
>)
Set top header display text. You may also set the top header at column creation time using
axlFormGridInsertCol
.
(0, 0)
Setting not supported.
For headers and script text,
g_value
is the only valid attribute other than
row
and
col
.
Colors available for
s_backColor
and
s_textColor
:
nil - use system defaults for color, typically white for background and black for text
black
white
red
green
yellow
button - use the current button background color

**参数** (Arguments)：

r_form
- **Form** — handle.
t_field
- **Field** — name.
t_callback
- **Function** — to callback. Takes a single argument:
g_pvtData
g_pvtData
- **Private** — data (Pass
nil
- **if** — not applicable.)

**返回值** (Value Returned)：

t
Grid cell changed.
nil
No grid cell changed, or application callback returned
nil
.

### axlFormGridUpdate

**说明**：与表单列表控件不同，您必须手动通知网格控件它必须更新自身。您应在以下情况下使用此调用：插入一行或多行、删除一行或多行、更改单元格。您应在所有网格更改结束时进行此调用。请勿在用于 `axlFormGridSetBatch` 的函数内部进行此调用。在 `axlFormGridSetBatch` 返回后进行。

**Original**: Unlike the form lists control you must manually notify the grid control that it must update itself. You should use this call in the following situations:
Inserting a row or rows
Deleting a row or rows
Changing cell(s)
You should make the call at the end of all of changes to the grid.
Do not make this call inside the function you use with axlFormGridSetBatch. Make it after axlFormGridSetBatch returns.

**参数** (Arguments)：

r_form
- **Standard** — form handle.
t_field
- **Standard** — field name.

**返回值** (Value Returned)：

Returns
t
for success,
nil
for failure.

**参见** (See Also)：

axlFormGridNewCell

### axlFormInvalidateField

**说明**：使表单字段无效。允许 Windows 向字段的重绘过程发送重绘消息。仅用于缩略图字段。

**Original**: Invalidates the form’s field. Allows Windows to send a redraw message to the field’s redraw procedure.
Use only for thumbnail fields.

**参数** (Arguments)：

r_form
- **Form** — handle.
t_field
- **Field** — name.

**返回值** (Value Returned)：

t
Field invalidated.
nil
No field invalidated.

### axlFormIsFieldEditable

**说明**：检查给定表单字段是否可编辑。如果字段可编辑，则返回 `t`。如果字段为灰色，则返回 `nil`。

**Original**: Checks whether the given form field is editable. If the field is editable,
t
is returned. If the field is greyed, then
nil
is returned.

**参数** (Arguments)：

r_form
- **Form** — id.
t_field
- **Field** — name.

**返回值** (Value Returned)：

t
Field is editable.
nil
Field is grayed, or not editable.

### axlFormListAddItem

**说明**：在位置 `x` 向列表添加项目。要高效添加许多项目，请将项目作为列表传递。

**Original**: Adds an item to a list at position
x
. To add many items efficiently, pass the items as a list.

**语法**：
```skill
axlFormListAddItem(f1, "list" "a" -1)
axlFormListAddItem(f1, "list" "b" -1)
axlFormListAddItem(f1, "list" "c" -1)
; since first time, send a nil to display the list
axlFormListAddItem(f1, "list" nil, -1)
Adds three items to the end of a list.
Example 2
axlFormListAddItem(f1, "list" ’("a" "b" "c"), -1)
Adds three items to the end of a list (alternate method).
```

**参数** (Arguments)：

r_form
- **Form** — id.
t_field
- **Field** — name.
t_listItem
- **String** — of items in the list. If adding to list for the first time, you must send a
nil
- **to** — display the list.
lt_listItems
- **List** — of strings to add.
g_index
0 = First item in the list. -1 = Last item in the list.

**返回值** (Value Returned)：

t
One or more items added to list.
nil
No items added to list due to incorrect arguments.
Example 1
axlFormListAddItem(f1, "list" "a" -1)
axlFormListAddItem(f1, "list" "b" -1)
axlFormListAddItem(f1, "list" "c" -1)
; since first time, send a nil to display the list
axlFormListAddItem(f1, "list" nil, -1)
Adds three items to the end of a list.
Example 2
axlFormListAddItem(f1, "list" ’("a" "b" "c"), -1)
Adds three items to the end of a list (alternate method).

### axlFormListDeleteItem

**说明**：删除列表中的指示项目。您可以按字符串或按位置删除。按字符串删除效果最好，如果所有项目都是唯一的。如果列表对您添加的项目进行排序，则位置可能会有问题。要快速删除多个项目，请使用列表调用此接口。按列表删除仅支持字符串列表。

**Original**: Deletes indicated item in the list. You can delete by a string or by position. Deleting by string works best if all items are unique. Position can be problematic if you have the list sort the items that you add to it.
To quickly delete multiple items, call this interface with a list of items.
Delete by list only supports a list of
strings
.

**参数** (Arguments)：

r_form
- **Form** — id.
t_field
- **Field** — name.
x_index
- **Position** — of the item to be deleted. 0 is the first item in the list, -1 is the last item in the list.
t_listItem
- **String** — of item to delete.
lt_listItems
- **List** — of items to delete.
nil
- **Deletes** — the last item.

**返回值** (Value Returned)：

x_index
If using strings (
t_listItem
) to delete items, returns the index of strings deleted. Useful for allowing the code to automatically select the next item in the list.
t
If deleting by index (
x_index
), it returns
t
if successful in deleting the item.
nil
Failed to delete the item.

### axlFormListGetItem

**说明**：返回索引 `x_index` 处列表中的项目。列表从索引 0 开始。如果 `-1` 作为索引传递，则返回列表中的最后一个项目。

**Original**: Returns the item in the list at index (
x_index
.) Lists start at index 0. If -1 is passed as an index, returns the last item in the list.

**参数** (Arguments)：

r_form
- **Form** — id.
t_field
- **Field** — name.
x_index
- **Offset** — into the list. 0 = First item in the list. -1 =Last item in the list.

**返回值** (Value Returned)：

t_listItem
String of item in the list.
nil
Index not valid, or no item at that index.

### axlFormListGetSelCount

**说明**：仅适用于多选列表框（表单文件中的 OPTIONS multiselect）。返回多选列表框中选定项目的数量。

**Original**: This only applies to a multi-select list box (OPTIONS multiselect in form file).
Returns a count of number of items selected in a multi-select list box.

**参数** (Arguments)：

r_form
- **Form** — control.
t_field
- **Name** — of the field.
- **Values** — Returned
nil
- **If** — not a multi-list box.
x_count
- **Number** — of items selected.

**示例** (Examples)：

See
axlform.il
example.

**参见** (See Also)：

axlFormListGetSelItems
,
axlFormListGetCount

### axlFormListGetSelItems

**说明**：仅适用于多选列表框（表单文件中的 OPTIONS multiselect）。对于多选列表框，返回选定项目的字符串列表。如果未选择项目或此不适用于控件，则返回 `nil`。

**Original**: This only applies to a multi-select list box (OPTIONS multiselect in form file).
For a multi-select list box returns list of strings for items selected. If no items selected or this is not appropriate for control returns
nil
.

**参数** (Arguments)：

r_form
- **Form** — control.
t_field
- **Name** — of the field.

**返回值** (Value Returned)：

lt_selected
List of strings for items selected.
nil
Error or nothing selected.

**示例** (Examples)：

See
axlform.il
example.

**参见** (See Also)：

axlFormListGetSelCount
,
axlFormListSelAll

### axlFormListOptions

**说明**：设置列表控件的选项。支持以下选项：`'doubleClick`（启用双击选择。为选项传递 `nil` 设置默认列表行为。默认是单击。双击事件处理如下：接收第一次单击作为事件，项目被选中，结果为 `doubleClick = nil`。接收第二次单击作为事件，项目被选中，结果为 `doubleClick = t`。建议使用模型：在第一次单击时，如果用户仅单击一次，则执行通常会发生的情况。第二次单击是自然的扩展。例如，在浏览器上，第一次单击选择文件。第二次单击执行 `OK` 按钮会执行的操作：将文件发送到应用程序并关闭表单。）。

**Original**: Sets options for a list control. The following options are supported:
’
doubleClick
Enable double-click selection. Passing a
nil
for an option sets default list behavior. Default is single click.
Double-click events are handled as follows:
Receive the first click as an event with the item selected and the result is:
doubleClick = nil
.
Receive the second click as an event with the item selected and the result is:
doubleClick = t
.
Suggested use model:
On first click do what would normally happen if the user clicks only once. The second click is a natural extension. For example, on a browser the first click selects the file. The second click does what the
OK
button would do: send the file to the application and close the form.

**语法**：
```skill
axlFormListOptions(form "list" 'doubleClick)
Enables double-click for a list.
Example 2
axlFormListOptions(form "list" nil)
Disables double-click for a list.
```

**参数** (Arguments)：

r_form
- **Form** — id.
t_field
- **Field** — name.
s_option
- **Sets** — option for list control.
nil
- **resets** — to default.

**返回值** (Value Returned)：

t
Options set.
nil
No options set due to incorrect arguments.
Example 1
axlFormListOptions(form "list" 'doubleClick)
Enables double-click for a list.
Example 2
axlFormListOptions(form "list" nil)
Disables double-click for a list.

### axlFormListSelAll

**说明**：仅适用于多选列表框（表单文件中的 OPTIONS multiselect）。选择或取消选择列表框中的所有项目。

**Original**: This only applies to a multi-select list box (OPTIONS multiselect in form file).
This either selects or deselects all items in list box.

**语法**：
```skill
axlFormListSelAll(fw "mlistfield" t)
De-Select all items in multi-list control;
mlistfield
.
axlFormListSelAll(fw "mlistfield" nil)
```

**参数** (Arguments)：

r_form
- **Form** — control.
t_field
- **Name** — of the field.
g_set
t
- **to** — select all;
nil
- **to** — deselect all.

**返回值** (Value Returned)：

t
if successful,
nil
field is not a mutli-select list box

**示例** (Examples)：

Select all items in multi-list control;
mlistfield
.
axlFormListSelAll(fw "mlistfield" t)
De-Select all items in multi-list control;
mlistfield
.
axlFormListSelAll(fw "mlistfield" nil)

**参见** (See Also)：

axlFormListGetSelItems

### axlFormMsg

**说明**：检索并打印表单文件中由消息标签定义的消息。表单文件允许使用 `MESSAGE` 关键字定义消息。使用此功能让用户可以访问消息文本，但无法访问您的 SKILL 代码。消息仅打印在拥有消息（`r_form`）的表单的状态区域中。您无法从一个表单文件访问消息 ID 并打印到另一个表单文件。没有状态行的表单使用主窗口。您对消息使用标准格式和参数替换。

**Original**: Retrieves and prints a message defined in the form file by message label (
t_messageLabel
.) Form file allows definitions of messages using the "
MESSAGE
" keyword (see
Using Forms Specification Language
.) Use this to give a user access to message text, but no access to your SKILL code.
Messages are only printed in the status area of the form owning the message (
r_form
.) You cannot access message ids from one form file and print to another. The main window is used for forms with no status lines.
You use standard formatting and argument substitution (see
printf
) for the message.

**语法**：
```skill
axlFormMsg(fw "drccount" 10 "spacing")
axlFormMsg(fw "drcerrors")
```

**参数** (Arguments)：

r_form
Form
dbid
.
t_messageLabel
- **Message** — label defined in form file by the MESSAGE keyword.
g_arg1
...
- **Substitution** — parameters (see
printf
)

**返回值** (Value Returned)：

t_msg
Message that prints.
nil
No message with the given name found in this form file.

**示例** (Examples)：

Form file (level: 0 is info, 1 is info with no journal entry, 2 is warning, 3 is error, and 4 is fatal.);
MESSAGE drccount 0 "Drc Count of %d for %s"
MESSAGE drcerrors 2 "Drc Errors"
axlFormMsg(fw "drccount" 10 "spacing")
axlFormMsg(fw "drcerrors")

### axlFormGetFieldRange

**说明**：返回为 INTFILLIN 或 REALFILLIN 指定的最小/最大值。对于其他字段类型，或如果这些值未在字段上设置，则返回 `nil`。

**Original**: Returns the min/max values specified for an INTFILLIN or REALFILLIN value. For other field types, or if these values are not set on the field,
nil
is returned.

**参数** (Arguments)：

r_form
Form
dbid
.
t_field
- **Name** — of the field.

**返回值** (Value Returned)：

l_fieldRange/nil
nil
if field doesn't exist
nil
if field isn't INTFILLIN or REALFILLIN
nil
if the field doesn't have range set
list(min max)
if field has legal range set

### axlFormGetFieldType

**说明**：返回表单字段的控件类型。有关支持的字段类型列表，请参阅 `Callback Procedure: formCallback` 中的关键字。

**Original**: Returns the control type for a form field. See the keywords in
Callback Procedure: formCallback
for a list of supported field types.

**参数** (Arguments)：

r_form
Form
dbid
.
t_field
- **Field** — name.

**返回值** (Value Returned)：

g_fieldType
One of the control types.
nil
Field does not exist or is not one of the types supported.

### axlFormDefaultButton

**说明**：表单通常自动设置表单中的默认按钮，使用表单文件中的 `DEFAULT` 部分或 `OK` 和 `DONE` 标签。当用户按下回车键时，执行默认按钮。表单最多可以有一个默认按钮。只有 `BUTTON` 类型的字段才能具有默认按钮属性。如果表单中禁用了默认按钮，则尝试建立新默认按钮的操作将被忽略。只有在表单中启用了该功能时，才能更改默认按钮。

**Original**: Forms normally automatically set a
default
button
in a form with the
DEFAULT
section in the form file or with the
OK
and
DONE
labels. When the user hits a carriage return, the
default
button
is executed.
A form can have, at most, one default button. Only a field of type
BUTTON
can have the default button attribute.
If default buttons are disabled in a form, then attempts to establish a new default button are ignored. You can only change the default button if the capability in the form is enabled.

**语法**：
```skill
axlFormDefaultButton(form nil)
Sets no default button in form.
Example 2
axlFormDefaultButton(form "cancel")
Sets the default button to be
Cancel
instead of the default
OK
.
```

**参数** (Arguments)：

r_form
Form
dbid
.
t_field
- **Field** — name to establish as new button default.
g_mode
t
- **to** — enable the default button in the form,
nil
- **to** — disable it.

**返回值** (Value Returned)：

t
Default button set.
nil
Field does not exist.
Example 1
axlFormDefaultButton(form nil)
Sets no default button in form.
Example 2
axlFormDefaultButton(form "cancel")
Sets the default button to be
Cancel
instead of the default
OK
.

### axlFormGridOptions

**说明**：杂项网格选项。请参阅使用网格以获取网格概述。

**Original**: Miscellaneous grid options. See
Using Grids
for a grid overview.

**参数** (Arguments)：

r_form
- **Form** — handle.
t_field
- **Field** — name.
s_name
/
g_value
- **Supported** — options shown.
s_name/g_value Supported Options
[
'goto
x_row
]
- **Puts** — the indicated row on display, scrolling the grid if necessary.
-1 signifies the last row.
[
'goto
x_row
:
x_col
]
- **Sends** — grid to indicated row and column.
-1 signifies the last row or column.
[
'select
x_row
]
- **Selects** — (highlights) indicated row.
[
'select
x_row
:
x_col
]
- **Selects** — (highlights) indicated cell. Grid must be in cell select mode else row is selected instead of cell. See
axlFormGridEvents
- **for** — more information.
['
deselectAll
]
- **Deselect** — any selected grid cells or rows.

**返回值** (Value Returned)：

t
Selected grid option performed.
nil
Selected grid option not performed.
Example 1
axlFormGridOption(fw, "mygrid" 'goto 10)
Makes row 10 visible.
Example 2
axlFormGridOption(fw, "mygrid" 'goto 5:2)
Makes row 5 column 2 visible.
Example 3
axlFormGridOption(fw, "mygrid" 'deselectAll)
Deselects anything highlighted in the grid.

### axlFormSetActiveField

**说明**：使指示字段成为活动表单字段。如果在调度处理程序中对传递给处理程序的字段执行 `axlFormRestoreField`，则该字段保持活动状态。

**Original**: Makes the indicated field the active form field.
If you do an
axlFormRestoreField
in your dispatch handler on the field passed to your handler, then that field remains active.

**参数** (Arguments)：

r_form
Form
dbid
.
t_field
- **Field** — name.

**返回值** (Value Returned)：

t
Field set active.
nil
Failed to set the field active.

### axlFormSetDecimal

**说明**：设置表单中实数填充字段的小数精度。如果 `g_field` 为 `nil`，则设置表单中所有实数填充字段的精度。

**Original**: Sets the decimal precision for real fill-in fields in the form. If
g_field
is
nil
, sets the precision for all real fill-in fields in the form.

**参数** (Arguments)：

o_form
- **Form** — handle.
g_field
- **Field** — label, or
nil
- **for** — all fields.
x_decimalPlaces
- **Number** — of decimal places - must be a positive integer.

**返回值** (Value Returned)：

t
Successfully set new decimal precision.
nil
Error due to invalid arguments.

### axlFormSetFieldEditable

**说明**：将单个表单字段设置为可编辑（`t`）或灰色（`nil`）。

**Original**: Sets individual form fields to editable (
t)
or grayed (
nil
).

**参数** (Arguments)：

r_form
Form
dbid
.
t_field
- **Field** — name.
g_editable
- **Editable** — (
t
) or grayed (
nil
).

**返回值** (Value Returned)：

t
Set form field to editable or grayed.
nil
Failed to set form field to editable or grayed.

### axlFormSetFieldLimits

**说明**：设置用户可以在整数或实数填充字段中输入的最小或最大值。如果提供了 `nil` 值，则该限制保持不变。对于 `REAL` 字段，`g_min` 和 `g_max` 的类型可以是 `int`、`float` 或 `nil`。对于 `INT` 或 `LONG`，类型必须是 `int` 或 `nil`。TRACKBAR：用于 trackbar 字段类型时。如果任一参数为 `0`，则保持该选项的当前设置。`g_min` 和 `g_max` 必须是整数。`g_min` 是刻度标记的间隔（默认值为 1）。刻度标记可能不会在所有用户界面中显示。这是通过 `axlFormSetField` 将 trackbar 移动到下一个刻度标记时的间隔大小。`g_max` 是 trackbar 中的步数（默认值为 100）。

**Original**: Sets the minimum or maximum values a user can enter in an integer or real fill-in field. If a
nil
value is provided, that limit is left unchanged.
For a
REAL
field, the type for
g_min
and
g_max
may be
int
,
float
, or
nil
. For an
INT
or
LONG
, the type must be
int
or
nil
.
TRACKBAR: When used for a trackbar field type. If either of the argument is
0,
then the current setting for that option is maintained. Both
g_min
and
g_max
must be integer numbers.
g_min
is the interval of the tickmarks (default is 1). Tickmarks may not be shown in all user interfaces. This is the interval size when moving the trackbar to the next tick mark via axlFormSetField.
g_max
is the number of steps in the trackbar (default is 100).

**参数** (Arguments)：

o_form
- **Form** — handle.
t_field
- **Field** — label.
g_min
- **Minimum** — value for field.
g_max
- **Maximum** — value for field.

**返回值** (Value Returned)：

t
Set max or min.
nil
Error, indicating a problem with one of the input parameters.

### axlFormTreeViewAddItem

**说明**：在父项下和插入同级项之后向树视图添加项目。如果同级项为 `nil`，则该项目作为父项的最后一个子项添加。如果父项为 `nil`，则该项目作为树的根创建。这是向树添加项目的唯一接口。Tree 控件禁用 `axlFormSetField`。应用程序必须保留返回的句柄 `l_hItem`，因为当从树视图中选择项目时，句柄将作为 `form->curValueInt` 传递。与所选项目关联的字符串也作为 `form->curValue` 传递，但字符串值可能不唯一，不能用作所选树视图项目的可靠标识符。树视图默认为单选模式。树视图中的项目没有关联的复选框以进行多选。要使树视图项目多选，请传递以下值之一：`'TVSELECT_SINGLE`（无选择状态复选框）、`'TVSELECT_2STATE`（2 状态复选框）或 `'TVSELECT_3STATE`（3 状态复选框）。

**Original**: Adds an item to a treeview under
parent
and after
insertAfter
sibling. If sibling is
nil
, the item is added as the last child of a parent. If parent is
nil
, item is created as the root of the tree.
This is the only interface for adding an item to a tree.
axlFormSetField
is disabled for Tree controls.
Applications must keep the returned handle
l_hItem
since a handle will be passed as
form->curValueInt
when the item is selected from tree view. The string associated with the selected item is also passed as
form->curValue
, however the string value may not be unique and cannot be used as a reliable identifier for the selected treeview item.
The tree view defaults to single selection mode. There is no checkbox associated with items in the tree view to make multiple selections. To make a tree view item multi select, pass one of the following values for
t_multiSelectF
:
nil
or
'TVSELECT_SINGLE
for no selection state checkbox
t
or '
TVSELECT_2STATE
for 2 state checkbox
'TVSELECT_3STATE
for 3 state checkbox
If an item is defined as multi select, a check box appears as part of the item. The user can check/uncheck (2 state) this box to indicate selection or select checked/unchecked/disabled modes for a 3 state checkbox. When the user makes any selection in the checkbox, its value is passed to application code in
form->treeViewSelState
. In this case,
form->curValue
is
nil
.
Callback Values
In the callback function for the form, the first argument form, has the following properties relevant to treeviews:
form->curValue
Contains the label of a treeview item. This is set in single select mode and in multi select mode when the user selects the item. In this case, the
result->tree.selectState
is -1.
form->curValueInt
Contains id of the selected treeview item.
form->selectState
In multi select mode, when the user picks the selection checkbox, this field will contain:
0 if selection checkbox is not checked
1 if selection checkbox is checked
2 if selection checkbox is disabled ((3 state mode only)
In this case the
result->string
is empty.
In all other cases the value is -1.
form->event
If event property is set to
"rightpopup"
, treeview control has a popup and the user has selected an item in the popup. In this case,
form->curValue
is set to the popup index selected, and
form->selectState
is set to
-1
.
form->curValueInt
is set to the treeview item id.You add popups to treeview fields in a form like you add any other field in a form.
For all non-popup operations, event is set to
"normal."

**参数** (Arguments)：

r_form
Form
dbid
.
t_field
- **Field** — name.
t_label
- **String** — of item in the treeview.
g_hParent
- **Handle** — of the parent. If
null
, item created as the root of the tree.
g_hInsertAfter
- **Handle** — of the sibling to add the item after. If
null
, item added at the end of siblings of the parent.
t_multiSelectF
If
t
, the item has a checkbox for multi selection.
g_hLeafImage
- **Handle** — of the image to use whenever this item is a leaf node in the tree view. If
nil
- **or** — not supplied, the default pink diamond image is used.
g_hOpenImage
- **Handle** — of image to be used whenever this item is an expanded parent node in the tree view. If
nil
- **or** — not supplied, the default open folder image is used.
g_hClosedImage
- **Handle** — of image to use whenever the item is an unexpanded parent node in the tree view. If
nil
- **or** — not supplied, the default closed folder image is used.

**返回值** (Value Returned)：

g_hItem
Item is added to the tree view control.
nil
No item is added to the tree view control due to an error.

**示例** (Examples)：

see
<cdsroot>
/share/pcb/examples/skill/form/basic/axlform.il

### axlFormTreeViewChangeImages

**说明**：修改与给定树视图项目关联的各种位图图像。

**Original**: Modifies various bitmap images associated with a given tree view item.

**参数** (Arguments)：

r_form
- **Form** — id.
t_field
- **Field** — name.
g_hItem
- **Handle** — of item in tree view. Handle was returned as a result of the call to
axlFormTreeViewAddItem
- **when** — item was initially added.
g_hLeafImage
- **Handle** — of the image to use whenever item is a leaf node in the tree view. If
nil
- **or** — not supplied, the default pink diamond image is used.
g_hOpenImage
- **Handle** — of image to use whenever item is an expanded parent node in the tree view. If
nil
- **or** — not supplied, the default open folder image is used.
g_hClosedImage
- **Handle** — of image to use whenever item is an unexpanded parent node in the tree view. If
nil
- **or** — not supplied, the default closed folder image is used.

**返回值** (Value Returned)：

t
Tree view item’s images are modified.
nil
Failed to modify tree view item’s images.

**参见** (See Also)：

axlFormTreeViewLoadBitmaps

### axlFormTreeViewChangeLabel

**说明**：修改给定树视图项目的文本。

**Original**: Modifies text of a given treeview item.

**参数** (Arguments)：

r_form
- **Form** — id.
t_field
- **Field** — name.
g_hItem
- **Handle** — of item in the tree view. This handle was returned as a result of the call to
axlFormTreeViewAddItem
.
t_label
- **New** — label.

**返回值** (Value Returned)：

t
Tree view item’s label is modified.
nil
Failed to modify tree view item’s label.

### axlFormTreeViewGetImages

**说明**：返回各种位图图像句柄，这些句柄引用树视图中指定项目使用的图像。

**Original**: various bitmap image handles that refer to images used by a specified item in the tree view.

**参数** (Arguments)：

r_form
- **Form** — id.
t_field
- **Field** — name.
g_hItem
- **Handle** — of item in the tree view. This handle was returned as a result of the call to
axlFormTreeViewAddItem
- **when** — this item was initially added.

**返回值** (Value Returned)：

l_hImage
List of three image handles. The first is the handle of the image used when this item is a leaf node. The second is the handle of the image used when this item is an expanded parent node. The third is the handle of the image used when this item is an unexpanded parent node.
nil
Error due to invalid arguments.

### axlFormTreeViewGetLabel

**说明**：返回给定树视图项目的文本。

**Original**: Returns text of a given treeview item.

**参数** (Arguments)：

r_form
- **Form** — id.
t_field
- **Field** — name.
g_hItem
- **Handle** — of item in the tree view. This handle was returned as a result of the call to
axlFormTreeViewAddItem
- **when** — this item was initially added.

**返回值** (Value Returned)：

t_label
Text of given tree view item.
nil
Failed to get text of given tree view item due to invalid arguments.

### axlFormTreeViewGetParents

**说明**：返回树视图控件项目的所有祖先列表，从树的根开始。有助于在 SKILL 中进行搜索操作。应用程序可以遍历其树列表，按照父列表到给定项目，而不是在整个树中搜索项目。

**Original**: Returns a list of all the ancestors of a treeview control item, starting from the root of the tree. Helps in search operations in SKILL. Applications can traverse their tree list following parent lists to a given item instead of searching the whole tree for an item.

**参数** (Arguments)：

r_form
- **Form** — id.
t_field
- **Field** — name.
g_hItem
- **Handle** — of item in the tree view. This handle was returned as a result of the call to
axlFormTreeViewAddItem
- **when** — this item was initially added.

**返回值** (Value Returned)：

lg_hItem
List containing all parents, starting from the root.
nil
Failed to obtain list due to invalid arguments.

### axlFormTreeViewGetSelectState

**说明**：在多选模式下，返回树视图项目的选择状态。这与单选树视图中的当前选择项目不同。在多选模式下，用户可以通过单击与每个项目关联的选择复选框来更改选择状态。

**Original**: In multi select mode, returns the select state of a treeview item. This is different than the current selected item in single select tree views. In multi select mode, users can change the select state by clicking on the select checkbox associated with each item.

**参数** (Arguments)：

r_form
- **Form** — id.
t_field
- **Field** — name.
g_hItem
- **Handle** — of item in the tree view. This handle was returned as a result of the call to
axlFormTreeViewAddItem
- **when** — this item was initially added.

**返回值** (Value Returned)：

In multi select mode:
0
Checkbox is unchecked.
1
Checkbox is checked.
2
Checkbox is disabled.
-1
Single select mode or failure due to invalid arguments.

### axlFormTreeViewLoadBitmaps

**说明**：允许应用程序将一个或多个位图加载到 Allegro PCB Editor 中，以供指定树视图使用。位图使用 BMPPATH 变量查找。使用 `.bmp` 文件扩展名。位图图像必须为 16 x 16 像素。位图文件可以包含多个图像，前提是它们水平附加（即包含 n 个图像的位图文件将为 (16*n) x 16 像素）。颜色 RGB(255,0,0) 保留为透明色。具有此颜色的任何像素都使用背景色显示。

**Original**: Allows an application to load one or more bitmaps into Allegro PCB Editor for use in specified tree view.

**参数** (Arguments)：

r_form
- **Form** — id.
t_field
- **Field** — name.
lt_bitmaps
- **Either** — a string containing the name of the bitmap file to load, or a list of strings, each of which is the name of a bitmap file to load.
Notes:
- **Bitmap** — is found using BMPPATH variable.
- **Uses** — file extension
.bmp
- **Bitmap** — images must be 16 x 16 pixels.
- **A** — bitmap file can contain more than one image provided they are appended horizontally (i.e. a bitmap file containing n images will be (16*n) x 16 pixels).
- **The** — color RGB(255,0,0) is reserved for the transparent color.
- **Any** — pixel with this color is displayed using the background color.

**返回值** (Value Returned)：

l_hImage
List of image handles that the caller will use to reference the images in subsequent
axlFormTreeViewAddItem
calls. The list is ordered to correspond with the order that the images were listed in the
lt_bitmaps
parameter.
nil
One or more of the bitmap files could not be found, or an error was encountered while adding images.

**示例** (Examples)：

File
myBmp1.bmp
is a 16 x 16 bitmap and
myBmp2.bmp
is a 32 x 16 bitmap:
tree = axlFormTreeViewAddItem(fw "tree" "one" nil nil 'TVSELECT_3STATE)
l = axlFormTreeViewLoadBitmaps(fw "tree" list("myBmp1" "myBmp2"))
axlFormTreeViewChangeImages(fw "tree" tree car(l) cadr(l) nil)
axlFormTreeViewLoadBitmaps may return (6 7 8) into variable l.
This mean that the image handle 6 would refer to the bitmap contained in myBmp1.bmp, the image handle 7 would refer to the left half of myBmp2.bmp, and the image handle 8 would refer to the right half of myBmp2.bmp.

**参见** (See Also)：

axlFormTreeViewChangeImages
,
axlFormTreeViewAddItem

### axlFormTreeViewSet

**说明**：允许应用程序更改树视图控件中的全局和单个项目。

**Original**: Allows an application to change global and individual items in a tree view control.

**语法**：
```skill
axlFormTreeViewSet(form "tree" 'TV_EXPAND nil)
Collapses all expanded top levels:
axlFormTreeViewSet(form "tree" 'TV_COLLAPSE_TOP nil)
For more examples see
<
cdsroot
>/share/pcb/examples/skill/form/basic
```

**参数** (Arguments)：

r_form
- **Form** — id.
t_field
- **Field** — name as a string
s_option
s_option
- **is** — one of the symbols listed.
g_hItem
- **Tree** — view user data type.
[s_data]
- **optional** — symbol
Each
s_option
- **is** — paired with
g_hItem
, the handle of an item in the tree view control. If the option you are setting is global, you use
nil
- **in** — place of
g_hItem
. The pairs of different values of
s_option
with
g_hItem
- **is** — in the following manner.
s_option
g_hItem
TV_REMOVEALL
nil
TV_DELETEITEM
g_hItem
TV_ENSUREVISIBLE
g_hItem
TV_EXPAND
g_hItem(4)
TV_EXPAND_TOP
- **nil** — (5)
TV_COLLAPSE
g_hItem(4)
TV_COLLAPSE_TOP
- **nil** — (5)
TV_SELECTITEM
- **g_hItem** — (2) (3)
TV_SORTCHILDREN
g_hItem
TV_NOEDITLABEL
nil
- disables in place label editing
TV_NOSELSTATEDISPATCH
nil
-check box selection not dispatched
TV_ENABLEEDITLABEL
nil
- enable in place label editing
TV_MULTISELTYPE
- **g_hItem** — (1)
TV_NOSHOWSELALWAYS
nil
TV_SHOWSELALWAYS
nil
Notes:
For
TV_MULTISELTYPE
, you can also use the option
g_data
- **which** — is one of the following:
TVSELECT_SINGLE
,
TVSELECT_2STATE
,
TVSELECT_3STATE
. Default is
TVSELECT_SINGLE
.
g_hItem
- **is** — the Handle of item in the tree view control. Its value can be received in the following ways:
Call
axlFormTreeViewAddItem
.
- **You** — can pass
nil
for
g_hItem
- **in** — some cases. Pass
nil
for
TV_SELECTITEM
- **option** — to deselect the item that is currently selected.
- **If** — nil is passed for TV_EXPAND or TV_COLLAPSE then all levels (including) children are expanded or collapse.
- **The** — two _TOP options, TV_EXPAND_TOP and TV_COLLAPSE_TOP, respectively, expand and collapse all top level tree items. Children tree item states are preserved.

**返回值** (Value Returned)：

t
Changed one or more items in tree view control.
nil
Failed to change items in tree view control.

**示例** (Examples)：

Delete selected treeview item in a form.
(axlFormTreeViewSet form
form
->
curField
’TV_DELETEITEM
form->curValue
)
Expand all levels including children:
axlFormTreeViewSet(form "tree" 'TV_EXPAND nil)
Collapses all expanded top levels:
axlFormTreeViewSet(form "tree" 'TV_COLLAPSE_TOP nil)
For more examples see
<
cdsroot
>/share/pcb/examples/skill/form/basic

### axlFormTreeViewSetSelectState

**说明**：在多选模式下，设置选择状态。这与单选树视图中的当前选择项目不同。在多选模式下，用户可以通过单击与每个项目关联的选择复选框来更改选择状态。

**Original**: In multi select mode, sets the select state. This is different than the current selected item in single select tree views. In multi select mode, users can change the select state by clicking on the select checkbox associated with each item.

**参数** (Arguments)：

r_form
- **Form** — id.
t_field
- **The** — name of the field.
g_hItem
- **Handle** — of the item in the tree view. This handle was returned as a result of the call to
axlFormTreeViewAddItem
- **when** — this item was initially added.
g_state
- **Select** — state to set.
- **Select** — state is unchecked if
g_state
is
nil
or
'TVSTATE_UNCHECKED
- **Select** — state is checked if
g_state
is
t
or
'TVSTATE_CHECKED
- **Select** — state is disabled if
g_state
is
'TVSTATE_DISABLED

**返回值** (Value Returned)：

t
Set select state.
nil
Failed to set select state.
Integer if the dispatch value of the pop-up is an integer.
