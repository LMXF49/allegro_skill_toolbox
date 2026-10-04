# 第 1 章 概述 (Introduction)

## Allegro PCB Editor SKILL 函数简介 (Introduction to Allegro PCB Editor SKILL Functions)

**原始标题**: Introduction to Allegro PCB Editor SKILL Functions

**产品文档**: Allegro SKILL Reference  
**产品版本**: 17.4-2019, October 2019

---

## 1. 概述 (Overview)

**说明**：本章是对以下内容的一个简要概述：

**Original**: This chapter is a brief overview of the following:

- Allegro PCB Editor AXL-SKILL
- AXL-SKILL 函数
- 如何初始化和运行 AXL-SKILL
- AXL Allegro PCB Editor 数据库

后续章节将详细描述 AXL 数据库对象以及所有的 AXL-SKILL 函数。

---

## 2. Allegro PCB Editor 中的 AXL-SKILL (AXL-SKILL in Allegro PCB Editor)

**说明**：AXL-SKILL 是包含在 Allegro PCB Editor 中的一个语言处理器，如下图所示。AXL-SKILL 包含并扩展了核心 Cadence SKILL 语言。您可以使用 AXL-SKILL 函数来访问 Allegro PCB Editor 数据库及其显示和用户界面。一旦访问了 Allegro PCB Editor 数据库，就可以使用核心 SKILL 函数来处理数据。《SKILL Language Functions Reference》描述了核心 SKILL 及其可用函数。

**Original**: AXL-SKILL is a language processor contained in Allegro PCB Editor, as shown in the following figure. AXL-SKILL contains and is an extension of the core Cadence SKILL language. You use AXL-SKILL functions to access the Allegro PCB Editor database and its display and user interfaces. Once you have accessed the Allegro PCB Editor database, you can process the data using the core SKILL functions. The SKILL Language Functions Reference describes core SKILL and its available functions.

通过在 Allegro PCB Editor 命令行输入 `skill` 命令来访问 AXL-SKILL。

AXL-SKILL 在启动 Allegro PCB Editor 时自动初始化。Allegro PCB Editor 启动时，依次读取 Allegro PCB Editor `env` 文件、AXL `ilinit` 文件（如下所述），以及在启动 Allegro PCB Editor 的 UNIX 命令中通过 `-s` 选项指定的任何脚本。

Allegro PCB Editor 按以下方式查找 `ilinit` 文件：

对于以下指定的位置，Allegro PCB Editor 读取以下文件之一：
- `<program_name>.ilinit`
- `allegro.ilinit`

从以下位置：
- `<cdsroot>/share/pcb/etc/skill`
- `<cdssite>/pcb/skill`
- `<cdssite>` 默认为 `<cdsroot>/share/local/pcb/skill`，否则可以设置 `CDS_SITE` 变量指向其他位置，即程序启动的目录：
- `$HOME/pcbenv`

如果在上述位置有多个 `ilinit` 文件，则每个 `ilinit` 文件都会被读取。如果只希望读取第一个找到的 `ilinit` 文件（14.2 版本之前采用的方法），请设置环境变量 `skill_old_ilinit`。

**注意**：您不能在 `env` 文件中插入 SKILL 命令。

---

## 3. 从命令行运行 AXL-SKILL (Running AXL-SKILL from the Command Line)

**说明**：通过在 Allegro PCB Editor 命令行键入 `skill` 来运行 AXL-SKILL。AXL-SKILL 解释器会出现，并以 `skill>` 提示符替代 Allegro PCB Editor 命令行。

**Original**: You run AXL-SKILL by typing skill on the Allegro PCB Editor command line. The AXL-SKILL interpreter appears with the skill> prompt in place of the Allegro PCB Editor command line.

您还可以使用以下语法从 Allegro PCB Editor 命令行运行 AXL-SKILL 函数：

```skill
skill (<function> <arguments>)
```

键入 `exit` 关闭 AXL-SKILL 解释器并返回到 Allegro PCB Editor 命令行。

---

## 4. 在批处理模式下运行 AXL-SKILL (Running AXL-SKILL in Batch Mode)

**说明**：您可以在不显示 Allegro PCB Editor 界面的 X 终端窗口中使用批处理模式运行 AXL-SKILL，方法如下：

**Original**: You can run AXL-SKILL in batch mode using an X terminal window without displaying Allegro PCB Editor, by typing the following command:

```bash
allegro -nographic
```

如果您的系统未运行 X 窗口系统，请确认其 DISPLAY 环境变量已设置为运行 X 服务器的系统。

`-nographic` 开关适用于所有 Allegro PCB Editor 图形可执行文件，例如 `allegro_layout`、`allegro_engineer`、`allegro_prep`、`allegro_interactive` 和 `allegro_layout`。

您还可以在 shell 脚本中编写 Allegro PCB Editor 和 AXL-SKILL 的启动和命令输入程序，从而实现完整的批处理能力。

---

## 5. 调试 AXL-SKILL 程序 (Debugging AXL-SKILL Programs)

**说明**：如果您拥有 SKILL ACCESS 开发许可证，则可以使用与其他 Cadence SKILL 程序相同的工具在 Allegro PCB Editor 中调试 AXL-SKILL 程序。有关这些工具的说明，请参阅《SKILL Language Functions Reference》，这些工具主要在 Unix 上可用。

**Original**: If you have a SKILL ACCESS development license, you can debug AXL-SKILL programs in Allegro PCB Editor using the same tools offered by other Cadence SKILL programs. See SKILL Language Functions Reference for a description of those tools, which are primarily available on Unix.

---

## 6. AXL-SKILL 语法 (AXL-SKILL Grammar)

**说明**：AXL-SKILL 函数遵循 SKILL 语法规则。此外，以下特征适用于大多数 AXL-SKILL 函数：

**Original**: AXL-SKILL functions follow SKILL grammar rules. In addition, the following characteristics apply to most AXL-SKILL functions:

- 所有 Allegro PCB Editor AXL 函数名都以 `axl` 开头。
- AXL 函数被分类为族（families），通常具有相似的调用序列并共享名称的公共部分，例如 `axlDBCreate` 族，包含 `axlDBCreateShape` 和 `axlDBCreateSymbol` 等成员。

---

## 7. SKILL 开发窗口 (SKILL Development Window)

**说明**：通过设置 Allegro PCB Editor 环境变量 `TELSKILL`，您可以获得一个更大的 SKILL 专用窗口。当设置了 `TELSKILL` 变量时，所有 Allegro PCB Editor 的控制台输出都会定向到 SKILL 窗口。

**Original**: You can get a larger SKILL-only window by setting the Allegro PCB Editor environment variable, TELSKILL. All Allegro PCB Editor console output is directed to the SKILL window when the TELSKILL variable is set.

---

## 8. AXL-SKILL 数据库 (AXL-SKILL Database)

**说明**：Allegro PCB Editor 以各种类型的对象形式将设计数据存储在专有数据库格式中。这些对象类型可以完整表示电子布局。您可以使用 AXL-SKILL 程序来创建、操作和提取此数据库中的信息。

**Original**: Allegro PCB Editor stores design data as various types of objects in a proprietary database format. These object types can create a complete representation of an electronic layout. You can create, operate on, and extract information from this database using AXL-SKILL programs.

AXL-SKILL 数据库存储设计的物理信息和逻辑信息。物理信息是诸如几何形状（例如连接蚀刻）之类的对象。逻辑信息是诸如网络和逻辑组件之类的对象。

---

## 9. 对象 dbid（数据库标识符）(Object dbids)

**说明**：每个 Allegro PCB Editor 数据库对象都有一个与之关联的唯一 `dbid`（数据库标识符）。当您调用函数对数据库对象进行操作时，需要通过提供该对象的 `dbid` 作为参数来标识该对象。

**Original**: Every Allegro PCB Editor database object has a unique dbid (database identifier) associated with it. When you call a function to operate on a database object, you identify the object to the function by giving the object's dbid as an argument.

只有 AXL 例程可以创建 `dbid`。您不能直接更改 `dbid`，但参数记录 id 除外。

---

## 10. 超出范围的 dbid (Out of Scope dbids)

**说明**：当 dbid 与其对象分离时，该 dbid 被视为超出范围。dbid 可能因以下任何原因而与其对象分离：

**Original**: When a dbid is separated from its object, the dbid is considered out-of-scope. A dbid can become separated from its object for any of the following reasons:

- 删除一个对象。
- 添加一条连接线与现有连接线接触。这会导致现有线断裂为两个对象，每个对象都有单独的 dbid，因此该线的原始 dbid 不再表示同一对象。
- 从 AXL 返回到 Allegro PCB Editor。
- 在 SKILL 中使用 AXL shell 函数运行 Allegro PCB Editor 命令。为了最小化 AXL shell 的超出范围问题，请隔离 AXL shell 函数，并在必要时使用 `axlDBRefreshID` 函数在 AXL shell 调用后刷新 dbid。
- 打开一个新的布局。

超出范围的 `dbid` 没有属性，因此没有对象类型。如果您尝试评估一个超出范围的 `dbid`，SKILL 会显示消息：`dbid: removed`。在函数中使用超出范围的 `dbid` 会导致意外的结果。

---

## 11. 对象类型 (Object Types)

**说明**：每个 Allegro PCB Editor 对象都有一个关联的 `type` 和一组描述该对象的 `attributes`（属性）。例如，所有 `symbol` 对象都是 `symbol` 类型。所有 `symbol` 都有 `isMirrored` 属性等，如果 symbol 被镜像，则该属性值为 `t`，否则为 `nil`。您可以使用 AXL-SKILL 函数配合 `"->"`（访问运算符）来访问任何对象属性。如果该属性对该对象不存在，则函数返回 `nil`。

**Original**: Each Allegro PCB Editor object has an associated type and a set of attributes that describe the object. For example, all symbol objects are of type symbol. All symbols have the isMirrored attribute, among others, and this attribute has the value t if the symbol is mirrored or nil if it is not. You can use an AXL-SKILL function with "->" (the access operator) to access any object attribute. If the attribute does not exist for that object the function returns nil.

您可以使用 SKILL 的特殊属性 `?`（问号）和 `??` 来查看对象的所有属性以及所有属性/值对。有关对象类型的更多信息，请参阅第 2 章"Allegro PCB Editor 数据库用户模型"。

---

## 12. 对象类 (Object Classes)

**说明**：对象类（object class）是一种数据类型抽象，用于对相关对象类型进行分组。当多个不同的对象类型共享足够的属性时，您可以将它们作为一个单一的类来讨论。描述对象类型类的每个部分的开头列出了该类所有公共的属性。

**Original**: An object class is a data-type abstraction used to group related object types. When a number of distinct object types share enough attributes, you can discuss them as a single class. The start of each section describing a class of object types lists all attributes common to that class.

不同的类型和类形成类层次结构。在层次结构的顶部是一个包含所有类型的类。在层次结构的底部，每个叶节点（终端节点）代表一个可以在磁盘上创建、删除和保存的对象类型。层次结构中的每个中间节点都有与其所有子节点共同的属性。例如，AXL-SKILL 图形（figures）具有共同的属性 `layer` 和 `bBox`（边界框）。这些较高级别的类不作为对象存在。

---

## 13. 选择集和查找函数 (Select Sets and Find Functions)

**说明**：AXL-SKILL 编辑函数从一个称为选择集（select set）的 `dbid` 列表中获取它们操作的对象的身份。您通过使用 AXL 选择函数选择一个或多个对象来累积选择集中的 `dbid`。然后，通过将选择集作为参数传递给编辑函数来对这些对象应用编辑操作。

**Original**: AXL-SKILL edit functions obtain the identities of the objects on which they operate from a list of dbids called the select set. You accumulate dbids in the select set by selecting one or several objects using AXL select functions. You then apply edit functions to the objects by passing the select set as an argument to the functions.

AXL-SKILL 具有以下功能：
- 设置查找过滤器（Find Filter）以控制选择的对象类型和选择选项
- 在单点、区域或按名称选择对象
- 选择对象的部分（例如，引脚，它们是符号的一部分）
- 从选择集中添加或删除对象（所选对象的集合）
- 获取选择集中的 `dbid` 并返回 `dbid` 的数量
- 在使用选择集之前将 `dbid` 添加到选择集或从选择集中移除它们

有关选择集函数的信息，请参阅第 4 章"选择和查找函数"。Allegro PCB Editor 在每次刷新显示时都会高亮显示所选对象。

---

## 14. 设计文件 (Design Files)

**说明**：设计文件（Design files）是 Allegro PCB Editor 数据库对象的容器。AXL-SKILL 有两种主要的设计文件类型：

**Original**: Design files are containers for Allegro PCB Editor database objects. AXL-SKILL has two major design file types:

- **Layout**（布局）：包含印刷电路或 MCM 布局数据。
- **Symbol**（符号）：包含符号的定义图。符号文件的编译输出可以添加到布局中。符号文件可以定义封装、机械、格式和形状符号。

---

## 15. 逻辑对象 (Logical Objects)

**说明**：逻辑对象是 Allegro PCB Editor 从原理图或第三方网表文件加载的网表中的对象：

**Original**: Logical objects are the objects in the netlist that Allegro PCB Editor loads from a schematic or third-party netlist file:

- **Component**（组件）：包含电气功能，例如与非门，以及定义对象电气行为的引脚。组件的参考位号（reference designator）就是其名称。
- **Net**（网络）：是与特定信号名称关联的所有蚀刻对象的集合——ppins、蚀刻路径、形状和过孔。每个网络都有一个名称，即其信号名称。一个网络包含一个或多个分支（branch）。每个分支是物理上相互连接的蚀刻对象的列表。一个分支可以包含 ppins、蚀刻路径、形状和过孔。当 Allegro PCB Editor 连接或断开网络的某些部分时，网络中的分支数量会变化。一个完全连接的网络由且仅由一个分支组成。

---

## 16. 层属性 (Layer Attributes)

**说明**：每个 Allegro PCB Editor 图形都存在于数据库中的一个类/子类（class/subclass）上。例如，一条 c-line 可能在 ETCH 类、TOP 子类上。AXL-SKILL 使用层属性（layer attribute）来表示这种类/子类组合。每个 AXL-SKILL 层与 Allegro PCB Editor 的类/子类组合一一对应。后续部分将详细描述此结构。

**Original**: Each Allegro PCB Editor figure exists on a class/subclass in the database. For example, a c-line might be on class ETCH, subclass TOP. AXL-SKILL represents this class/subclass combination with a layer attribute. Each AXL-SKILL layer is in one-to-one correspondence with an Allegro PCB Editor class/subclass combination. A later section describes this structure in detail.

---

## 17. Allegro PCB Editor 属性 (Allegro PCB Editor Properties)

**说明**：尽管它们是 Allegro PCB Editor 对象的一个类，但您不能直接创建或访问 Allegro PCB Editor 属性。相反，您使用 AXL-SKILL 命令来附加、删除和读取 Allegro PCB Editor 数据库对象上的属性值。您还可以使用 AXL-SKILL 命令来读取、创建和删除您自己定义的属性。

**Original**: Although they are a class of Allegro PCB Editor objects, you do not create or access Allegro PCB Editor properties directly. Rather, you use AXL-SKILL commands to attach, delete, and read the values of properties on Allegro PCB Editor database objects. You can also use AXL-SKILL commands to read, create and delete definitions of your own properties.

---

## 18. 属性定义 (Property Definitions)

**说明**：AXL-SKILL 将每个对象的属性定义间接地存储在与该对象关联的位置。您可以访问对象上的任何属性定义以查找其值，并且可以使用 AXL-SKILL 函数创建新的用户定义属性。

**Original**: AXL-SKILL stores each property definition for an object indirectly associated with that object. You can access any property definition on an object to find its value and you can create new, user-defined properties using AXL-SKILL functions.

如果对象接受该属性类型，您可以使用 AXL-SKILL 函数将属性附加到对象。该属性必须在数据库的属性字典中定义。属性定义是一个对象，包含属性名称、值类型以及指定可以附加到哪些对象类型的列表。

---

## 19. 图形 (Figures)

**说明**：以下 AXL-SKILL 图形是 Allegro PCB Editor 的几何类型。

**Original**: The following AXL-SKILL figures are Allegro PCB Editor geometry types.

### Arc（弧线）

**说明**：弧线或圆的图形。您可以通过起点和终点以及半径或圆心来指定弧线。（Allegro PCB Editor 图形：arc segment）

**Original**: Is a figure that is either an arc or a circle. You can specify arcs to AXL-SKILL with start and end points, and either radius or center point. (Allegro PCB Editor figure: arc segment).

### Branch（分支）

**说明**：组成网络的一个物理连接部分的蚀刻图形的集合。网络由分支组成，分支由引脚、过孔、 tees 和蚀刻图形组成，如本章后面所述。

**Original**: Is a collection of etch figures that make up one physically connected part of a net. Nets are made up of branches, and branches are made up of pins, vias, tees and etch figures, as described later in this chapter.

### DRC（设计规则检查）

**说明**：设计规则违规标记，带有一个或多个对象标识以及违规类型和位置。

**Original**: Is a design rule violation marker with one or more object identities and a violation type and location.

### Line（线）

**说明**：由其中线的坐标和宽度定义的对象。（Allegro PCB Editor 图形：line segment）

**Original**: An object defined by the coordinates of its center line and a width (Allegro PCB Editor figure: line segment).

### Path（路径）

**说明**：在同一层上端对端连接的线和弧的序列。每个段可以有不同的宽度。（Allegro PCB Editor 图形：lines and clines）

**Original**: Is a sequence of end-to-end lines and arcs on the same layer. Each segment can have a different width (Allegro PCB Editor figures: lines and clines).

### PPin（物理引脚）

**说明**：具有关联焊盘堆叠（padstack）的引脚的物理实例。

**Original**: Is a physical instance of a pin with associated padstack.

### Polygon（多边形）

**说明**：未填充的闭合路径。（Allegro PCB Editor 图形：unfilled shape）

**Original**: Is an unfilled, closed path (Allegro PCB Editor figure: unfilled shape).

### Shape（形状）

**说明**：填充的形状。它可以可选地包含空洞（voids）。

**Original**: Is a filled shape. It can optionally contain voids.

### Pad（焊盘）

**说明**：定义一种类型焊盘在一层上的形状的几何形状（圆、椭圆、矩形）。焊盘始终由焊盘堆叠（padstacks）拥有。

**Original**: Is a geometric shape (circle, oblong, rectangle) defining the shape of one type of pad on one layer. Pads are always owned by padstacks.

### Symbol（符号）

**说明**：带有类型名称、位置、旋转和镜像的几何和文本的集合。

**Original**: Is a collection of geometries and text with a type name, location, rotation and mirroring.

### Tee（T 型连接点）

**说明**：三个或更多蚀刻路径的端点连接的单一点。

**Original**: Is the single point where the endpoints of three or more etch paths connect.

### Text（文本）

**说明**：带有相关大小、镜像、旋转和位置的字符串。

**Original**: Is a string of characters with associated size, mirror, rotation, and location.

### Via（过孔）

**说明**：具有关联焊盘堆叠（padstack）的层间连接钻孔路径。

**Original**: Is a connecting drill path between layers with associated padstack.

以下类型不是图形，但包含定义图形实例的几何：

### Padstack（焊盘堆叠 / 引脚/过孔定义）

**说明**：包含命名类型的所有 ppins 或过孔的定义数据。

**Original**: (Pin/Via Definition) Contains the definition data for all ppins or vias of a named type.

### Symdef（符号定义）

**说明**：包含命名类型的所有符号的定义数据。

**Original**: Contains the definition data for all symbols of a named type.

---

## 20. 使用 AXL-SKILL 访问 Allegro PCB Editor 颜色 (Accessing Allegro PCB Editor Colors with AXL-SKILL)

**说明**：您可以使用 AXL-SKILL 访问预定义颜色和 Allegro PCB Editor 数据库颜色。只有图形编辑器支持访问 Allegro PCB Editor 数据库颜色。

**Original**: You can access predefined colors and Allegro PCB Editor database colors using AXL-SKILL. Only graphics editors support access to Allegro PCB Editor database colors.

---

### 窗体 (Forms)

**说明**：通过符号设置和访问预定义颜色。预定义颜色包括：

**Original**: You set and access pre-defined colors by their symbols. The pre-defined colors include the following:

- `'black`
- `'white`
- `'red`
- `'green`
- `'yellow`
- `'blue`
- `'button`

`Button` 表示灰色，即应用程序中按钮的颜色。

您只能在 Allegro PCB Editor 窗体中使用预定义颜色。

---

### 设计对象 (Design Object)

**说明**：图形编辑器支持访问用于 Allegro PCB Editor 层的颜色。这些颜色用整数表示。

**Original**: Graphics editors support access to the colors used for Allegro PCB Editor layers. These are represented by integers.

AXL API 调用，包括 `axlLayerGet("class/subclass")` 或其原始形式 `axlGetParm(paramLayerGroup:<class/paramLayer:<subclass>)`，通过 color 属性调用返回层的当前颜色设置，如下所示：

```skill
p = axlLayerGet("etch/top")
p->color -> 2
```

这些颜色设置范围在 1 到 24 之间，0 保留为背景颜色。

支持颜色的基于窗体的接口包括：

- `axlFormDoc`
- `axlFormColorize`
- `axlFormGridDoc`
- `axlGRPDoc`

**注意**：
- AXL 不允许您更改 Allegro PCB Editor 数据库颜色的红/绿/蓝（RGB）值。
- 预定义颜色受到限制，以最小化 UNIX 上 8 位颜色图形的问题。

---

## 21. 数据库对象 (Database Objects)

**说明**：设计由各种数据库对象组成，您可以将它们组合以创建其他数据库对象。本节描述数据库对象之间的关系。

**Original**: A design is made of various database objects that you can combine to make other database objects. This section describes the relationships among database objects.

---

### 设计的组成部分 (Parts of a Design)

**说明**：设计可以包含以下任何数据库对象：

**Original**: A design can include any of the following database objects:

- Property Dictionary（属性字典）
- Lines（线）
- Text（文本）
- Polygons（多边形）
- Shapes（形状）
- Property Definitions（属性定义）
- DRCs（设计规则检查）
- Vias that are Padstack object types（作为 Padstack 对象类型的过孔）
- Symbols that are Symdef object types（作为 Symdef 对象类型的符号）
- Components（组件）
- Nets（网络）

---

### 符号的组成部分 (Parts of a Symbol)

**说明**：作为 Symdef 对象类型的符号可以包含以下任何数据库对象：

**Original**: Symbols that are Symdef objects types can include any of the following database objects:

- PPins that are Padstack object types（作为 Padstack 对象类型的 PPins）
- Vias that are Padstack object types（作为 Padstack 对象类型的过孔）
- Lines（线）
- Arcs（弧）
- Text（文本）
- Polygons（多边形）
- Shapes（形状）

---

### 分支的组成部分 (Parts of a Branch)

**说明**：分支可以包含以下任何数据库对象：

**Original**: Branches can include any of the following database objects:

- Tees（T 型连接点）
- Vias that are Padstack object types（作为 Padstack 对象类型的过孔）
- PPins that are Padstack object types（作为 Padstack 对象类型的 PPins）
- Paths（路径）
- Shapes（形状）

---

### 路径的组成部分 (Parts of a Path)

**说明**：路径可以包含以下任何数据库对象：

**Original**: A path can include any of the following database objects:

- Lines（线）
- Arcs（弧）

---

### 符号定义的组成部分 (Parts of a Symdef)

**说明**：symdef 可以包含以下任何数据库对象：

**Original**: A symdef can include any of the following database objects:

- PPins that are Padstack object types（作为 Padstack 对象类型的 PPins）
- Vias that are Padstack object types（作为 Padstack 对象类型的过孔）
- Lines（线）
- Arcs（弧）
- Text（文本）
- Polygons（多边形）
- Shapes（形状）

---

## 22. 参数类型 (Types of Parameters)

**说明**：Allegro PCB Editor 参数将特性或板级选项存储到 Allegro PCB Editor 数据库中。您可以使用 SKILL 程序修改参数。参数类型包括：

**Original**: Allegro PCB Editor parameters store feature or board level options to the Allegro PCB Editor database. You can modify parameters using a SKILL program. The parameter types include the following:

- Design（设计）
- Display（显示）
- Layer Group（层组）
- Textblock Group（文本块组）

---

## 表 1-1 其他数据库对象关系 (Table 1-1 Other Database Object Relationships)

| Object Name（对象名称） | Object Parts（对象组成部分） |
|---|---|
| Property Dictionary | Property Entries（属性条目） |
| Net | Branches（分支） |
| Padstack | Pads（焊盘） |
| Polygon | Paths（路径） |
| Shape | Paths（路径） |
| Void | Polygons（多边形） |
| Polygon | Paths（路径） |
| PPin | Pin Number Text（引脚编号文本） |
| Layer Group | Layers（层） |
| Textblock Group | Textblocks（文本块） |

---

*返回顶部 (Return to top)*
