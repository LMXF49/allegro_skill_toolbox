# 第 12 章 简单图形绘制 (Simple Graphics Drawing)

> **来源**：`12draw.html`  
> **产品版本**：Allegro SKILL Reference 17.4-2019, October 2019

---

## 概述 (Overview)

**说明**：本章描述与简单图形绘制（Simple Graphics Drawing）相关的 AXL-SKILL 函数。这些绘图工具用于在 UIF 表单包的缩略图（thumbnail）等位图区域中绘制图形。（有关缩略图的更多信息，请参阅 axl 表单 BNF 文档，查找包含 THUMBNAIL 的条目。）

**Original**: This chapter describes the AXL-SKILL functions related to Simple Graphics Drawing. You use these drawing utilities for drawing into bitmap areas such as thumbnails within the UIF forms package. (For more information on thumbnails, see the axl form BNF document, look for the entries with THUMBNAIL).

`axlGRP` 是简单图形绘制工具的 AXL 接口。

**Original**: `axlGRP` is the AXL interface to a Simple Graphics Drawing utility.

您可以通过以下方式简化在表单缩略图中的应用绘制：

**Original**: You can simplify application drawing into thumbnails within forms as follows:

- 在表单文件中指定缩略图字段。不应为其关联位图。

**Original**: Specify the thumbnail field within the form file. This should not have a bitmap associated with it.

- 调用 `axlGRPDrwInit` 函数，传入表单、字段名和回调函数。保留此函数返回的句柄，以便后续处理中使用。

**Original**: Call the `axlGRPDrwInit` function with the form, field name, and a callback function. Keep the handle returned by this function so you can use it in later processing.

- 使用提供的函数重绘图像。回调函数被调用时以图形句柄作为参数。

**Original**: Using the functions provided, redraw the image. The callback function is invoked with the graphics handle as the parameter.

- 使用 `axlGRPDrwUpdate` 函数触发回调函数。

**Original**: Use the `axlGRPDrwUpdate` function to trigger the callback function.

应用程序在使用此包的同时，不能使用缩略图文档中概述的设施来设置位图或图形回调。

**Original**: The application cannot set bitmaps or graphics callbacks using the facilities outlined in the Thumbnail documentation while using this package.

### 支持的图形类型

简单图形绘制包支持以下内容：

**Original**: Simple Graphics Drawing package supports the following:

- 矩形（填充和未填充）

**Original**: Rectangles (Filled and unfilled)

- 多边形（填充和未填充）

**Original**: Polygons (Filled and unfilled)

- 圆形（填充和未填充）

**Original**: Circles (Filled and unfilled)

- 简单线条

**Original**: Simple Lines

- 多段线

**Original**: Poly Lines

- 位图

**Original**: Bitmaps

- 文本

**Original**: Text

### 坐标系统

此包支持可映射的坐标系统。使用 `GRPDrwMapWindow` 函数，您可以指定一个矩形，该矩形被映射到实际的绘图区域。保持 1:1 的纵横比。

**Original**: This package supports a mappable coordinate system. With the `GRPDrwMapWindow` function, you can specify a rectangle that gets mapped to the actual drawing area. An aspect ratio of 1 to 1 is maintained.

绘图区域的零点是绘图区域的左上角：

**Original**: The zero point of the drawing area is the upper left point of the drawing:

- 先绘制的对象会被后绘制的对象覆盖。应用程序必须自行管理此问题。

**Original**: Objects drawn earlier are overlapped by objects drawn later. The application must manage this.

---

## 在 r_graphics 句柄上设置选项属性 (Setting Option Properties on the r_graphics Handle)

**说明**：在调用绘图函数之前，您可以在 `r_graphics` 句柄上设置选项属性。这些属性（如适用）将由绘图属性使用。

**Original**: You can set option properties on the `r_graphics` handle before calling the drawing functions. These properties, if applicable, are used by the drawing properties.

### 表 12-1 r_graphics 选项属性

**Original**: Table 12-1 r_graphics Option Properties

| 选项 (Option) | 默认值 (Default) | 说明 (Description) | 可用设置 (Available Settings) |
|---|---|---|---|
| `color` | `black` | 适用于所有元素（表示当前按钮颜色） | 颜色可以是 WWW 联盟提供的 SVG 颜色名称。`#RGB`（每个 R、G、B 为单个十六进制数字）`#RRGGBB` `#AARRGGBB` `#RRRGGGBBB` `#RRRRGGGGBBBB` 标准颜色：black, white, red, green, yellow, blue, light blue, rose, purple, teal, dark pink, dark magenta, aqua, gray, olive, orange, pink, beige, navy, violet, silver, rust, lime, brown, mauve, magenta, light pink, cyan, salmon, peach, dark gray, button |
| `fill` | `unfilled` | 仅适用于矩形和多边形 | `filled`, `filled_solid`, `unfilled` |
| `width` | `0` | 仅在几何元素未填充时适用 | — |
| `text_align` | `left` | 文本对齐方式。仅适用于文本。 | `left`, `center`, `right` |
| `text_bkmode` | `transparent` | 文本背景显示模式。仅适用于文本。 | `transparent`, `opaque` |

---

### 不支持的元素

以下几何元素不受支持：

**Original**: The following geometric elements are not supported:

- 圆弧（Arcs）
- 形状（例如，带圆弧的多边形）
- 来自资源的位图
- 椭圆（Ellipses）

**Original**: Arcs, Shapes (for example, polygon's with arcs), Bitmaps from resources, Ellipses

此外，以下功能也不受支持：

**Original**: Additionally, the following capabilities are not supported:

- 几何变换（旋转、平移、缩放）
- 透明度
- 从资源文件加载位图
- 不支持 3D 或 2.5D

**Original**: Geometric transformations (rotation, translation, scaling), Transparency, Loading bitmaps from the resource file, No 3 or 2.5 D

---

### 示例

请参阅 `<cdsroot>/share/pcb/examples/skill/form/basic/axlform.il` 获取完整示例。

**Original**: See `<cdsroot>/share/pcb/examples/skill/form/basic/axlform.il` for a complete example.

---

## 函数列表 (Functions)

### axlGRPDrwBitmap

**说明**：将位图加载到表单绘制窗口（图形字段中的绘图区域）。可以在位图之上进行更多绘制。

**Original**: Loads a bitmap into a form draw window (drawing area in the graphics field). More drawing can take place on top of the bitmap.

**语法**：
```skill
axlGRPDrwBitmap(
  r_graphics
  t_bitmap
)
```

**参数**：

- `r_graphics`: 图形句柄。

- `t_bitmap`: 位图文件名。文件必须位于 `BMPPATH` 中，扩展名为 `.bmp`。**Original**: Name of bitmap file. File must be on the BMPPATH, with .bmp as the extension.

**返回值**：

- `t`: 位图已加载到图形字段的绘图区域。

- `nil`: 由于参数无效，未将位图加载到绘图区域。

---

### axlGRPDrwCircle

**说明**：在由 `r_graphics` 句柄标识的区域中，以指定原点为圆心、指定半径绘制一个圆。绘制时应用附加到 `r_graphics` 句柄的选项属性。

**Original**: Draws a circle into the area identified by the r_graphics handle, at the origin specified, and with the specified radius. Option properties attached to the r_graphics handle are applied when drawing the circle.

**语法**：
```skill
axlGRPDrwCircle(
  r_graphics
  l_origin
  x_radius
)
```

**参数**：

- `r_graphics`: 图形句柄。

- `l_origin`: 表示原点 x 和 y 坐标的列表。**Original**: List noting the x and y coordinates of the origin.

- `x_radius`: 表示圆半径的整数。**Original**: Integer noting the radius of the circle.

**返回值**：

- `t`: 圆已绘制。

- `nil`: 由于参数无效，未绘制圆。

---

### axlGRPDrwInit

**说明**：使用此命令在表单字段中设置图形回调。它设置必要的数据结构，以触发图形字段中的图形回调。

**Original**: Use this command to set graphics callback in a form field. It sets up necessary data structures for triggering the graphics callback into the graphics field.

**语法**：
```skill
axlGRPDrwInit(
  r_form
  t_field
  t_func
)
```

**参数**：

- `r_form`: 表单句柄。

- `t_field`: 包应绘制到的字段名称。（仅支持 `THUMBNAIL` 字段。）**Original**: Name of field into which the package should draw. (Only THUMBNAIL fields are supported.)

- `t_func`: 绘图回调函数的名称。调用回调函数时以图形句柄作为参数。**Original**: Name of the drawing callback function. Callback function is invoked with the graphics handle as the parameter.

**返回值**：

- `r_graphics`: 图形包句柄。

- `nil`: 由于参数无效，未能设置触发图形回调所需的数据结构。

---

### axlGRPDrwLine

**说明**：在由 `r_graphics` 句柄和坐标列表标识的区域中绘制一条线。绘制时应用附加到 `r_graphics` 句柄的选项属性。

**Original**: Draws a line into the area identified by the r_graphics handle and the list of coordinates. Option properties attached to the r_graphics handle are applied when drawing the line.

**语法**：
```skill
axlGRPDrwLine(
  r_graphics
  l_vertices
)
```

**参数**：

- `r_graphics`: 图形句柄。

- `l_vertices`: 描述该线的坐标列表。**Original**: List of coordinates describing the line.

**返回值**：

- `t`: 线已绘制。

- `nil`: 由于参数无效，未绘制线。

---

### axlGRPDrwMapWindow

**说明**：强制在映射窗口中绘制。允许应用程序指定映射到图形字段绘图区域的坐标系统。

**Original**: Forces a draw in a mapped window. Allows the application to denote the coordinate system that is mapped into the drawing area of the graphics field.

**语法**：
```skill
axlGRPDrwMapWindow(
  r_graphics
  x_Xextent
  x_Yextent
)
```

**参数**：

- `r_graphics`: 图形句柄。

- `x_Xextent`: 绘图窗口的 X 范围。**Original**: X-extent of the drawing window.

- `x_Yextent`: 绘图窗口的 Y 范围。**Original**: Y-extent of the drawing window.

**返回值**：

- `t`: 成功。

- `nil`: 由于参数无效而发生错误。

---

### axlGRPDrwPoly

**说明**：在由 `r_graphics` 句柄和坐标列表标识的区域中绘制一个多边形（多段线）。绘制时应用附加到 `r_graphics` 句柄的选项属性。如果坐标未形成闭合多边形，则列表中的第一个和最后一个坐标将由一条直线连接。

**Original**: Draws a polygon (multi-segment line) into the area identified by the r_graphics handle and the list of coordinates. Option properties attached to the r_graphics handle are applied when drawing the polygon. If the coordinates do not form a closed polygon, the first and last coordinates in the list are connected by a straight line.

**语法**：
```skill
axlGRPDrwPoly(
  r_graphics
  l_vertices
)
```

**参数**：

- `r_graphics`: 图形句柄。

- `l_vertices`: 描述该线的坐标列表。**Original**: List of coordinates describing the line.

**返回值**：

- `t`: 多边形或线已绘制。

- `nil`: 由于参数无效，未绘制多边形或线。

---

### axlGRPDrwRectangle

**说明**：在由 `r_graphics` 句柄和 `upper_left` 与 `lower_right` 坐标标识的区域中绘制一个矩形。绘制时应用附加到 `r_graphics` 句柄的选项属性。

**Original**: Draws a rectangle into the area identified by the r_graphics handle and the upper_left and lower_right coordinates. Option properties attached to the r_graphics handle are applied when drawing the rectangle.

**语法**：
```skill
axlGRPDrwRectangle(
  r_graphics
  l_upper_left
  l_lower_right
)
```

**参数**：

- `r_graphics`: 图形句柄。

- `l_upper_left`: 表示矩形左上角点坐标的列表。**Original**: List noting the coordinate of the upper left point of the rectangle.

- `l_lower_right`: 表示矩形右下角点坐标的列表。**Original**: List noting the coordinate of the lower right point of the rectangle.

**返回值**：

- `t`: 矩形已绘制。

- `nil`: 由于参数不正确，未绘制矩形。

---

### axlGRPDrwText

**说明**：在由 `r_graphics` 句柄在指定原点处绘制文本。绘制时应用附加到 `r_graphics` 句柄的选项属性。

**Original**: Draws text into the area identified by the r_graphics handle at the origin specified. Option properties attached to the r_graphics handle are applied when drawing the text.

**语法**：
```skill
axlGRPDrwText(
  r_graphics
  l_origin
  t_text
)
```

**参数**：

- `r_graphics`: 图形句柄。

- `l_origin`: 表示原点 x 和 y 坐标的列表。**Original**: List noting the x and y coordinate of the origin.

- `t_text`: 要绘制的文本字符串。**Original**: Text string to be drawn.

**返回值**：

- `t`: 文本已绘制。

- `nil`: 由于参数不正确，未绘制文本。

---

### axlGRPDrwUpdate

**说明**：强制调用已注册的绘图窗口回调函数。触发调用应用程序提供的回调函数。

**Original**: Force call to register callback function for a draw window. Triggers calling of the application supplied callback function.

**语法**：
```skill
axlGRPDrwUpdate(
  r_graphics
)
```

**参数**：

- `r_graphics`: 图形句柄。

**返回值**：

- `t`: 应用程序提供的回调函数已被调用。

- `nil`: 由于参数不正确，未调用回调函数。

---


**另请参阅 (See Also)**：`axlGRPDoc`

**Original**: See Also `axlGRPDoc`
