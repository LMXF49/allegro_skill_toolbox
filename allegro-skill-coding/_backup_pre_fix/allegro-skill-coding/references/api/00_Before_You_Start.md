# 第 00 章 开始之前 (Before You Start)

> **来源**：`preface.html`  
> **产品版本**：Allegro SKILL Reference 17.4-2019, October 2019

---

## 关于本手册 (About This Manual)

**说明**：本手册面向使用 Allegro PCB Editor SKILL 函数来定制现有 Allegro PCB Editor 交互命令或创建新命令的设计人员和工程师。它描述了 AXL（Allegro eXtension Language）用户模型、如何启动 AXL，以及如何使用每个 AXL 函数。

**Original**: This manual is for designers and engineers who use the Allegro PCB Editor SKILL functions to customize existing Allegro PCB Editor interactive commands or create new ones. It describes the AXL (Allegro eXtension Language) user model, how to start AXL, and how to use each AXL function.

本手册假设您熟悉印刷电路板（PCB）的开发和设计。它还假设您熟悉用于 PCB 物理设计和可靠性、可测试性、可重构性分析的 **Allegro PCB Editor**。

**Original**: This manual assumes that you are familiar with the development and design of printed circuit boards (PCBs). It also assumes you are familiar with Allegro PCB Editor for the physical design of PCBs and analysis of reliability, testability, and restructurability.

如果您阅读本手册是为了大致了解 AXL 的功能，但并未打算实际使用 AXL 编程，请阅读 **Chapter 1, "Introduction to Allegro PCB Editor SKILL Functions"**。

**Original**: If you are reading this manual for a general understanding of AXL capabilities, but do not actually intend to program in AXL, read Chapter 1, "Introduction to Allegro PCB Editor SKILL Functions."

您还应熟悉 Cadence SKILL 语言。以下手册描述了 SKILL：

**Original**: You should also be familiar with the Cadence SKILL language. The following manuals describe SKILL:

- `SKILL Language User Guide`
- `SKILL Language Reference`
- `Cadence SKILL Functions Quick Reference`

---

## 前置知识 (Prerequisites)

**说明**：在开始使用 Allegro PCB Editor 设计电路板之前，您应熟悉 Allegro PCB Editor 环境。

**Original**: Before you begin using Allegro PCB Editor to design boards, you should be familiar with the Allegro PCB Editor environment.

**Allegro PCB Editor User Guide: Getting Started with Physical Design** 介绍如何：

**Original**: The Allegro PCB Editor User Guide: Getting Started with Physical Design explains how to:

- 启动 Allegro PCB Editor
- 在 Allegro PCB Editor 软件中导航
- 获取命令帮助
- 使用鼠标、菜单和表单
- 启动设计会话

**Original**: Start Allegro PCB Editor, Navigate in the Allegro PCB Editor software, Get help on a command, Use the mouse, menus and forms, Start a design session

---

## 命令语法约定 (Command Syntax Conventions)

AXL–SKILL 描述遵循 **SKILL Language Basics** 中描述的约定。此外，本手册还使用以下约定。

**Original**: AXL–SKILL descriptions adhere to the conventions described in the SKILL Language Basics. In addition, this manual uses the conventions described below.

### 数据类型与符号约定

| 约定 | 说明 | Original |
|---|---|---|
| `italics` | 数据类型名称。 | Data type name. |
| `nil` | SKILL 标准空列表；作为返回值时，可能表示失败。 | Standard SKILL for empty list; as a return value, may indicate failure. |
| `t` | SKILL 标准真值；作为返回值时表示成功。 | Standard SKILL for "true;" return value for success. |
| `[name]` | 可选参数 "name"。 | Optional argument "name." |
| `<name>` | 必需参数，类型为 "name"。 | Argument of type "name" required. |
| `dbid` | Allegro PCB Editor 数据库对象实例（意为 "database id"）。 | Instance of an Allegro PCB Editor database object (means "database id") |
| `figure` | Allegro PCB Editor 几何数据库对象——例如，line、shape、symbol 均为 Allegro PCB Editor 的 figure。请勿与 Allegro PCB Editor 的数据库对象 "figure" 混淆，后者是表示 DRC 标记和钻孔的特殊图形。为确保本手册中表述清晰，"Allegro PCB Editor figure" 特指该特殊对象。 | Geometric Allegro PCB Editor database object—for example, line, shape, or symbol are all Allegro PCB Editor figures. This is not to be confused with the Allegro PCB Editor's database object "figure", a special graphic denoting DRC markers and drill holes. To ensure clear distinction in this manual, "Allegro PCB Editor figure" denotes this special object. |
| `l_bBox` | 包围盒坐标列表。坐标对依次为左下角和右上角。例如： | A list of the coordinates of a bounding box. Coordinate pairs are lower left and upper right. For example, |
| `t_layer` | 由斜杠 "/" 分隔的名称对，表示 Allegro PCB Editor 的 class-subclass 名称。例如，"PACKAGE GEOMETRY/SILKSCREEN_TOP"。 | A pair of names separated by a slash "/" denoting the name of an Allegro PCB Editor class-subclass. For example, "PACKAGE GEOMETRY/SILKSCREEN_TOP." |
| `lo_dbid` | 接受或返回 dbid 或 dbid 列表的函数。 | Function that takes or returns a dbid or list of dbids. |
| `o_dbid` | 接受或返回单个 dbid 的函数。 | Function that takes or returns a single dbid. |

```skill
(list( 100:100 200:200 ))
```

---

## 引用方式 (Referencing)

### 按名称引用对象 (Objects by Name)

**说明**：在编写 AXL 程序时，您可以通过对象唯一名称来选择或引用命名对象。下表展示了 Allegro PCB Editor 对象类型及其关联名称：

**Original**: When programming AXL, you can select or refer to a named object by using the unique name of that object. The table shows Allegro PCB Editor object types and their associated names:

**表 4-1**：Allegro PCB Editor 对象类型与名称

**Original**: Table 4-1 Allegro PCB Editor Object Types and Names

| Allegro PCB Editor 对象类型 (Object Type) | 名称 (Name) |
|---|---|
| NET | netname |
| COMPONENT | refdes |
| SYMBOL | refdes or symbol pin: <refdes>.<pin number> |
| FUNCTION | function designator |
| DEVTYPE | device type |
| SYMTYPE | symbol type, for example, "DIP 14" |
| PROPERTY | property name, for example, "MAX_OVERSHOOT" |

您可以使用 **Chapter 4, "Selection and Find Functions"** 中的 `axlName` 函数来选择对象。

**Original**: You can select objects using the axlName functions in Chapter 4, "Selection and Find Functions".

---

## 在手册中查找信息 (Finding Information in This Manual)

下表汇总了本手册描述的主题。

**Original**: The following table summarizes the topics described in this manual.

| 关于... (For Information About...) | 请阅读... (Read...) |
|---|---|
| AXL 操作以及 Allegro PCB Editor 数据库与 AXL 函数之间的关系：<br>AXL 函数、AXL 初始化与环境、启动和停止 AXL、调试 AXL 程序、dbid 与对象持久性、选择 Allegro PCB Editor 数据库对象、AXL–SKILL 数据库对象类型 | **Chapter 1, "Introduction to Allegro PCB Editor SKILL Functions"** |
| Allegro PCB Editor AXL 数据库对象的结构及其相互关系。列出每种对象类型的属性。<br>数据库规则、属性类型、几何数据库类型、逻辑数据库类型、属性数据库类型、所有 Allegro PCB Editor 数据库对象的完整属性列表 | **Chapter 2, "The Allegro PCB Editor Database User Model"** |
| 路径结构以及将路径对象和其他图形对象添加到 Allegro PCB Editor 数据库的 AXL 函数。<br>路径创建函数、创建形状和矩形函数、创建线、引脚、符号、文本和过孔的函数 | **Chapter 15, "Database Create Functions"** |
| 对 Allegro PCB Editor 数据库参数对象的读写访问。 | **Chapter 3, "Parameter Management Functions"** |
| 选择集以及管理选择集和选择单个及多个数据库对象的 AXL 函数。<br>点选择、框选择、按名称和对象选择、dbid、查找过滤器管理、选择集管理 | **Chapter 4, "Selection and Find Functions"** |
| 以与交互式 Allegro PCB Editor 命令相同的方式操作数据库对象的 AXL 函数，包括：<br>删除对象、显示对象 | **Chapter 5, "Interactive Edit Functions"** |
| 读取数据库对象：<br>打开 Allegro PCB Editor 设计、访问独立分支图形、属性、焊盘和文本 | **Chapter 6, "Database Read Functions"** |
| 高亮和显示数据库对象、加载光标缓冲区和交互式命令的动态橡皮筋显示、接受单个和多个用户坐标拾取、完成和取消命令的回调函数的 AXL 函数 | **Chapter 7, "Allegro PCB Editor Interface Functions"** |
| 设置 Allegro PCB Editor shell 变量、向 Allegro PCB Editor shell 发送命令字符串的 AXL 函数 | **Chapter 8, "Allegro PCB Editor Command Shell Functions"** |
| 提示和获取用户确认、显示文本文件、显示和打印 ASCII 文件的 AXL 函数 | **Chapter 10, "User Interface Functions"** |
| 创建表单（包括各种类型的表单字段）、设置对单个字段输入响应的回调的 AXL 表单和函数 | **Chapter 11, "Form Interface Functions"** |
| 与简单图形绘制相关的 AXL 函数 | **Chapter 12, "Simple Graphics Drawing Functions"** |
| 为用户消息进行设置、向用户显示消息的 AXL 函数 | **Chapter 13, "Message Handler Functions"** |
| 打开设计、编译、运行编辑检查和保存当前（符号）设计、获取活动设计类型、设置 Allegro PCB Editor 符号类型、获取或设置指定数据库控制、区域和障碍的值、更改设计的范围、原点、单位和精度、设置、删除和获取数据库锁信息、设置、清除和打印有关触发器的信息（注册对 Allegro PCB Editor 中发生事件的兴趣）、获取活动类和子类、活动文本块、正在使用的设计技术类型和图纸的完整路径、保存设计、将电路板焊盘栈保存到库、通过复制现有焊盘栈创建新焊盘栈、在当前数据库上运行 dbdoctor 的 AXL 函数 | **Chapter 14, "Design Control Functions"** |
| 创建和移除数据库组、向数据库组添加和移除数据库对象的 AXL 函数 | **Chapter 16, "Database Group Functions"** |
| 创建、更改和删除数据库附件、检查对象是否为数据库附件、获取所有数据库附件的 ID、获取数据库附件的 AXL 函数 | **Chapter 17, "Database Attachment Functions"** |
| 在批量模式下更新许多蚀刻或封装符号时提高性能和程序内存使用、标记数据库事务的开始并将标记返回给调用函数、在数据库中写入标记以允许将来回滚或提交、提交和撤销数据库事务的 AXL 函数 | **Chapter 18, "Database Transaction Functions"** |
| 获取和设置当前 DRC 模式和设计约束及 ECset 成员的值、创建、删除和获取 ECset 的 dbid、检查给定值是否符合给定约束的允许语法、批量处理和调优使用 axlCNS<xxx> 函数进行约束更改导致的 DRC 更新的 AXL 函数 | **Chapter 19, "Constraint Management Functions"** |
| 向命令解释器注册和注销 SKILL 命令、获取和设置线锁和活动层的控制、定义弹出菜单、获取用户数据的 AXL 函数 | **Chapter 20, "Command Control Functions"** |
| 多边形操作函数、属性和使用模型。 | **Chapter 21, "Polygon Operation Functions"** |
| 获取 Allegro PCB Editor 文件名以及打开和关闭文件 | **Chapter 22, "Allegro PCB Editor File Access Functions"** |
| 对 extract 命令的 SKILL 访问、选择数据库对象集作为视图的成员并对每个对象应用 AXL 函数 | **Chapter 23, "AXL-SKILL Data Extract Functions"** |
| 给定各种数据计算圆弧中心、将数量转换为各种单位的 AXL 函数 | **Chapter 24, "Utility Functions"** |
| 使用数学工具函数 | **Chapter 25, "Math Utility Functions"** |
| 杂项 | **Chapter 26, "Database Miscellaneous Functions"** |
| 使用逻辑访问函数 | **Chapter 30, "Logic Access Functions"** |

---

## 其他信息来源 (Other Sources of Information)

**说明**：有关 Allegro PCB Editor 和其他相关产品的更多信息，请参阅以下来源。

**Original**: For more information about Allegro PCB Editor and other related products, consult the sources listed below.

### 产品安装 (Product Installation)

**Cadence Installation Guide** 介绍如何安装 Cadence 产品。

**Original**: The Cadence Installation Guide tells you how to install Cadence products.

### 相关手册 (Related Manuals)

以下手册构成了 PCB 设计工具工作台中 Allegro PCB Editor 的文档集：

**Original**: The following manuals comprise the Allegro PCB Editor documentation set for your workbench of PCB design tools:

| 关于... (For Information About...) | 请阅读... (Read...) |
|---|---|
| Allegro PCB Editor 用户界面。使用 Allegro PCB Editor 进行设计过程的概述，包括启动和退出、控制图形显示、图形和文本元素、设计信息和系统信息。 | **Allegro PCB Editor User Guide: Getting Started with Physical Design** |
| 构建和管理库，包括定义焊盘栈、自定义焊盘、封装、电气属性和格式。 | **Allegro PCB Editor User Guide: Defining and Developing Libraries** |
| 加载逻辑设计数据和转换第三方机械数据，包括从 Concept™、网表和电路板机械数据加载数据。 | **Allegro PCB Editor User Guide: Transferring Logic Design Data** |
| 设置设计和指定设计规则与控制，包括指定属性和约束的说明。 | **Allegro PCB Editor User Guide: Preparing the Layout** |
| 使用 Allegro PCB Editor 放置元件，包括自动和交互式放置。 | **Allegro PCB Editor User Guide: Placing the Elements** |
| 使用 Allegro PCB Editor 布线，包括交互式和自动布线。 | **Allegro PCB Editor User Guide: Routing the Design** |
| 设计输出，包括重命名参考位号、创建钻孔和丝印数据以及生成绘图。 | **Allegro PCB Editor User Guide: Preparing Manufacturing Data** |
| 可选的 Allegro PCB Editor 接口，包括 Cadnetix-E、CBDS、Racal Visula、IGES、Greenfield、Computervision CADDS、SDRC I-DEAS、AutoCAD DXF、PTC、CATIA、IPC-D_350C、GDSII、Fluke Defect Analyzer 和 HP3070 Tester。 | **Converting Third Party Designs and Mechanical Data** |
| 按字母顺序列出的 Allegro PCB Editor 命令。 | **Allegro PCB and Package Physical Layout Command Reference** |
| Allegro PCB Editor 属性、提取（示例）和报告。 | **Allegro PCB Editor User Guide: Design Rules**, **Extract Data Dictionary**, and **Viewing Reports On Screen in HTML Format** |
| Allegro PCB Editor 用户指南和参考手册的综合术语表。 | **Allegro PCB Editor User Guide Glossary** |

### 客户支持 (Customer Support)

Cadence 提供许多客户教育服务。请向您的销售代表咨询更多信息。

**Original**: Cadence offers many customer education services. Ask your sales representative for more information.

**Cadence Online Support (COS)** 适用于与 Cadence 签有维护协议的客户。在这里，您还可以找到技术信息，包括 SKILL 文档和共享软件代码。COS 提供最新的季度增量版本（QIRs）、案例和产品变更发布（CCR）信息、技术文档、解决方案、软件更新等。

**Original**: Cadence Online Support (COS) is available for customers who have a maintenance agreement with Cadence. Here, you can also find technical information, including SKILL documentation and shareware code, online. COS provides the latest in Quarterly Incremental Releases (QIRs), case and product change release (CCR) information, technical documentation, solutions, software updates and more.

### Allegro PCB Editor 用户邮件列表订阅 (Allegro PCB Editor Users Mailing List Subscription)

您可以使用电子邮件（email）订阅 Allegro PCB Editor 用户邮件列表。您将定期收到包含 Allegro PCB Editor 产品系列最新信息的通讯。

**Original**: You can use electronic mail (email) to subscribe to the Allegro PCB Editor users mailing list. You will receive periodic newsletters containing up-to-date information on the Allegro PCB Editor product family.

**订阅 Allegro PCB Editor 邮件列表**：向 `majordomo@cadence.com` 发送电子邮件，并在邮件正文中包含短语 "subscribe allegro_users"。您将收到一封确认通知。

**Original**: To subscribe to the Allegro PCB Editor mailing list: Send an email message to majordomo@cadence.com, and include the phrase "subscribe allegro_users" in the body of the message. You will receive an acceptance notification.

### AXL-SKILL 示例文件 (AXL-SKILL Example Files)

您可以在以下位置找到 AXL-SKILL 示例文件：

**Original**: You can find AXL-SKILL example files in this location:

```
<install_dir>/share/pcb/examples/skill
```

### 用户讨论论坛 (User Discussion Forums)

您可以在 **Cadence Community** 网站找到 Cadence 产品的用户讨论组。

**Original**: You can find discussion groups for users of Cadence products at Cadence Community site.

---

> **返回顶部 (Return to top)**
