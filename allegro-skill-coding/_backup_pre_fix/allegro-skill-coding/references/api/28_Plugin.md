# 第 28 章 插件 (Plugin)

## 插件函数 (Plugin Functions)

**产品文档**: Allegro SKILL Reference  
**产品版本**: 17.4-2019, October 2019

---

## 概述 (Overview)

**说明**：本章描述与插件 API 相关的 AXL-SKILL 函数。

`axlDll` 函数族提供了将编译的 DLL（共享库）包绑定到支持 "axl" SKILL API 的程序中的能力。可以导入 DLL 中的任何公开导出函数。唯一的限制是导出的 DLL 函数必须支持下面指定的 API。

任何对 'DLL' 的引用对于 UNIX 和 Linux 程序员来说等同于共享库。所有 UNIX 引用均适用于 Linux。

创建插件需要两个组件：
- 导入和包装 DLL 提供功能的 SKILL 代码。
- 实现插件功能的 DLL/共享库。

**Original**: This chapter describes the AXL-SKILL functions related to plugin APIs. The axlDll family of APIs provides the ability to bind compiled DLL (shared library) packages into programs supporting the "axl" SKILL APIs. Any publicly exported functions from a DLL can be imported. The only restriction is that exported DLL functions must support the API specified below. Any reference to 'DLL' is the equivalent to a shared library for UNIX and Linux programmers. All UNIX references apply to Linux. Creating a plugin requires two components: SKILL code to import and wrap the functionality provided by the DLL. The DLL/shared library implementing the plugin functionality.

---

## SKILL 编程 (SKILL Programming)

**说明**：插件的 SKILL 编程模型如下：

1. 通过 `axlDllOpen` 定位并打开插件。我们建议将返回的句柄分配给全局 SKILL 符号。在后续调用到您的 SKILL 应用程序时，该符号将为非 nil，因此可以跳过对 `axlDllOpen` 的调用。（请参阅 `axlDllOpen`。）
2. 通过 `axlDLLSym` 从插件导入所需的符号。与 `axlDllOpen` 返回的句柄一样，这些句柄应分配给全局符号。
3. 使用 `axlDllCall` 或 `axlDllCallList` 访问插件中的功能。

`axlDllCall` 记录了支持的 I/O 数据类型。

**Original**: The SKILL programming model for plugins is: Locate and open a plugin via axlDllOpen. We suggest assigning a returned handle to a global SKILL symbol. On subsequent calls into your SKILL application, the symbol will be non-nil, so the call to axlDllOpen can be skipped. (See axlDllOpen.) Import the required symbols from the plugin via axlDLLSym. Like the handle returned by axlDllOpen, these handles should be assigned to global symbols. Use either axlDllCall or axlDllCallList to access the capability from the plugin. The I/O data types that are supported are documented in axlDllCall.

---

## DLL 编程 (DLL Programming)

**说明**：DLL 编程允许外部开发人员利用现有的 C/C++ 代码或在 C/C++ 中开发新的功能，作为 SPB 软件的插件扩展。支持此功能的 SPB 软件是那些包含 "axl" 扩展包到 SKILL 的软件。

插件 DLL 的实现：

- 在 Windows 和 Linux 上，所有 SPB 应用程序都是 64 位应用程序，这意味着任何 DLL（Linux 上的共享库）都必须构建为 64 位可加载库。如果 DLL 构建为 32 位库，则无法成功加载。在 Windows 上，您必须使用 x64 架构构建。还建议在 Windows 上使用发布配置而不是调试配置。此外，在 Windows 的 Visual Studio 中，项目属性、链接器部分的高级选项卡中，必须将目标计算机选项设置为 MachineX64（/MACHINE:X64 选项）。
- 获取 Cadence 所需的编译器环境。（请参阅 Allegro 平台文档。）
- 使用现有的 Cadence Makefile（UNIX）或项目文件（Microsoft），其中包含所需的编译/链接选项。您可以使用这些文件来构建插件，以适应自己的软件配置环境。（请参阅 `<cdsroot>/share/pcb/examples/skill/plugin`。）
- 确保导出的 DLL 函数满足 API 要求。（请参阅下面的 API 插件函数。）包含文件 `<cdsroot>/share/pcb/include/axlplugin.h` 具有所需的结构定义和定义。
- 构建您的插件。
- 测试它。

**Original**: DLL programming allows the use of external developers to utilize existing C/C++ code or develop new capabilities in C/C++ to plugin as extensions to SPB software. SPB software supporting this capability are those that incorporate the "axl" extension package to SKILL. Implementation of a plugin DLL: On both Windows and Linux, all SPB applications are 64-bit applications, which means that any DLL (shared library on Linux) must be built as a 64-bit loadable library. If the DLL is built as a 32-bit library, it will not load successfully. On Windows you must build with the x64 architecture. It is also recommended to build with the release configuration on Windows, rather than the debug configuration. Also, in Visual Studio on Windows in the Project Properties, Linker section's Advanced tab, you must set the option Target Machine to MachineX64 (/MACHINE:X64 option). Obtain the compiler environment required by Cadence. (See the Allegro platform documentation.) Use the existing Cadence Makefile (UNIX) or Project file (Microsoft) which contains the required compile/link options. You can use these files to build your plugin to adapt your own software configuration environment. (See <cdsroot>/share/pcb/examples/skill/plugin.) Ensure that the exported DLL functions meet the API requirements. (See API plugin functions below). The include file, <cdsroot>/share/pcb/include/axlplugin.h, has the required structure definitions and defines. Build your plugin. Test it.

---

## 插件编程所需的 Cadence 文件 (Required Cadence files for plugin programming)

- `<cdsroot>/share/pcb/include/axlplugin.h`

---

## API 插件函数 (API Plugin Functions)

**说明**：任何插件函数的 C API 如下：

```c
long <function>(AXLPluginArgs *output, AXLPluginArgs *input)
```

API 对其输入和输出参数使用相同的结构。调用的 Cadence 软件使用调用 SKILL 代码传递的数据更新输入结构。它还初始化输出结构。

插件函数必须返回一个值，并可选择使用返回数据（`argv` 和 `count`）更新输出结构。插件返回值传递回调用的 SKILL 代码，如下所示：

- `return == 0` — 返回计数值以下的输出数据结构列表。列表的长度由 'count' 给出。如果输出结构中的 'count' 为 0，则返回的列表为空。
- `return != 0` — 返回值作为整数返回给 SKILL。

**Original**: The C API for any plugin function is as follows: long <function>(AXLPluginArgs *output, AXLPluginArgs *input). The API takes identical structures for both its input and output arguments. The calling Cadence software updates the input structure with the data passed by the calling SKILL code. It also initializes the output structure. The Plugin function must return a value and optionally update the output structure with return data (argv and count). The plugin return value is passed back to the calling SKILL code as follows: return == 0 Returns a list of output data structure up to the count value. The length of the list is given by 'count'.If 'count' in output structure is 0, the returned list is empty. return != 0 Return value is returned to SKILL as an integer.

---

## AXLPluginArgs 输入/输出结构成员 (AXLPluginArgs Input/Output Structure Members)

- `version = AXLPLUGIN_VERS_IN` — 输入结构的版本。如果将来添加更多功能，此版本号将会增加。它通知插件结构中支持的功能。
- `flag = 0` — 将来使用。
- `maxEntries = AXLPLUGIN_MAX` — 输入时可以忽略。输出时，不能超过此值作为返回参数。
- `count = <number of argv entries>` — `argv` 中的条目数。基本上，提供给 `axlDLLCall` API 的参数数量。永远不会超过 `maxEntries`。
- `argv[]` — `AXLPluginEntry` 参数数组。

**AXLPluginEntry (argv) 结构成员**（请参阅输入/输出数据原语。）
- `type` — 指示数据类型
- `data` — 支持的原语类型的联合

对于被调用的 DLL 函数向调用 SKILL 代码返回数据，应在输出数据结构中设置 `count` 和 `argv` 条目。对于每个返回的 `argv` 条目，您还应将数据类型设置为下面显示的其中之一。在任何情况下，都不应尝试返回超过 `maxEntries` 的数据。

如果您的导出 DLL 函数将在您的编程环境之外使用，那么您应该在 SKILL 包装器或 DLL 函数中验证检查输入参数。例如，如果您期望一个字符串参数，而调用 SKILL 代码传递了一个整数，如果数据未检查，则会发生程序异常。

**Original**: version = AXLPLUGIN_VERS_IN Version of input structure. If additional capability is added in the future, this version number will be bumped. It informs the plugin of the capability supported in the structure. flag = 0 Future use maxEntries = AXLPLUGIN_MAX Can be ignored on input. On output, you cannot exceed this value for return arguments. count = <number of argv entries> Number of entries in argv. Basically, the number of arguments provided to the axlDLLCall APIs. Will never be more the maxEntries. argv[] Array of AXLPluginEntry arguments AXLPluginEntry (argv) Structure Members (See Input/Output Data Primitives.) type Indicates type of data data Union of primitive types supported For the called DLL function to return data to calling SKILL code, both the count and argv entries should be set in the output data structure. For each argv entry returned, you should also set the data type to one of the primitives shown below. Under no situation should you attempt to return more then maxEntries. If your exported DLL functions will be used outside your programming environment, then you should valid check the input arguments either in the SKILL wrapper or in your DLL function. For example, if you expect a string argument and the calling SKILL code passes an integer, a program exception will occur if the data is not checked.

---

## 输入/输出数据原语 (Input/Output Data Primitives)

**说明**：支持一组 I/O 数据原语。`AXLPluginArgs` 的 `argv` 条目是这些结构的数组。每个数组成员都有指示的数据类型和数据本身。输入和输出数据都使用 `AXLPluginArgs` 结构。

支持的数据原语：

| Type（类型） | SKILL type（SKILL 类型） | C type（C 类型） | C struct member（C 结构成员） |
|---|---|---|---|
| AP_BOOL | t/nil | int | b_value |
| AP_LONG | x_value | long | l_value |
| AP_DOUBLE | f_value | double | d_value |
| AP_CONST_STRING | t_value/s_value | char * | cs_value |
| AP_STRING | t_value | char * | s_value (output only) |
| AP_XY | f_value:f_value | AXLXY | xy_value |

`AP_STRING` 类型在输入时不会出现。从 Allegro 传递到插件的所有字符串都是 `AP_CONST_STRING`。要返回字符串，插件可以使用 `AP_CONST_STRING` 或 `AP_STRING`。如果使用 `AP_STRING`，则 Allegro 将使用标准 C "free" API 释放与字符串关联的内存，这意味着您必须通过 `malloc` 分配它。

其他数据类型限制：
- 插件不得修改任何输入的 `AP_CONST_STRING`；否则会导致 SKILL 损坏。
- 为了跨函数调用保持 `AP_CONST_STRING` 输入数据，您应该复制它们。SKILL 可能会在您的 DLL 函数返回后垃圾回收内存。
- 如果您使用自己的内存管理器，不要使用 `AP_STRING` 类型作为返回。这些需要使用标准 `malloc` 内存管理器。
- 输入参数可以是 SKILL 符号（`'<symbol>`），但它们会转换为 `AP_CONST_STRING` 类型。
- `STRING` 类型不支持宽字符集；仅使用 ASCII 字符集中的字符。
- `AP_XY` 表示 (x y) 位置，实现为两个 double 的结构。
- 如果使用 `AP_BOOL` 类型，在 `axlplugin.h` 中提供了两个定义：`AXLPLUGIN_TRUE = 1`，`AXLPLUGIN_FALSE = 0`。

从插件返回 SKILL 的返回值：
- 如果 `output->count` 为 `0`，则查看插件函数的返回值，并将 `x_value` 返回给符号。
- 否则（非零计数），我们将此值作为 SKILL 整数类型返回。

**Original**: A set of I/O data primitives is supported. The argv entry of AXLPluginArgs is an array of these structures. Each array member has its data type indicated and the data itself. Both the input and output data use the AXLPluginArgs structure. The data primitives that are supported are: Type SKILL type C type C struct member. AP_STRING types will not be seen on input. All strings passed from Allegro to the plugin are AP_CONST_STRING. To return a string, the plugin may use either AP_CONST_STRING or AP_STRING. If AP_STRING is used, then Allegro will free the memory associated with the string using the standard C "free" API, which means you must allocate it via malloc. Other data type restrictions are: The plugin must not modify in place any input AP_CONST_STRING; corruption of SKILL will occur. To maintain AP_CONST_STRING input data across function calls, you should make a copy of them. SKILL may garbage collect the memory after your DLL function returns. If you use your own memory manager, do not use AP_STRING types for return. These require the use the standard malloc memory manager. Input arguments can be SKILL symbols ('<symbol>) but these are converted to AP_CONST_STRING types. The STRING types do not support wide character sets; use only characters in the ASCII character set. AP_XY represents a (x y) location and is implemented as a structure of two doubles. If AP_BOOL type is used, two defines are provided in axlplugin.h: AXLPLUGIN_TRUE = 1, AXLPLUGIN_FALSE = 0. Return value from plugin exported back to SKILL: If output->count is 0, then the we look at the return value from the plugin function and return x_value to symbol. Else (non-zero count), we return this value to SKILL as a SKILL integer type.

---

## 编程限制、注意事项和提示 (Programming Restrictions, Cautions and Hints)

- Cadence 仅支持 SPB 平台文档中列出的编译器。还需要任何列出的编译器和 DLL 链接器选项。
- 如果您的 DLL 依赖于其他 DLL，请确保这些 DLL 与 Cadence 使用的 DLL 不冲突。通常，它们需要是相同的版本，并且不能用调试选项构建。
- 要确定 Cadence 使用的 DLL：
  - Windows：`depends` 或 `procexp` (www.sysinternals.com)
  - Linux：`ldd <program name>`
- 在 Windows 上，您可以在插件中包含 UI 组件。Linux 上不支持此功能。
- 插件到 Allegro 接口不支持宽字符类型。
- 在 Linux 上，如果使用线程，则应使用 POSIX 线程（`pthreads`）。
- STL 编程应使用 Cadence 所需编译器提供的默认 STL。不要使用第三方 STL。
- 在 Windows 上，如果 DLL 是基于 MFC 的，则不要以调试模式编译。如果代码以调试模式构建，MFC 类的大小会发生变化，并且与非调试 MFC 代码不兼容。Web 上描述了如何在不使用 MFC 调试共享库的情况下构建 MFC 可调试的方法。通常，在 Windows 上，调试 DLL 与非调试 DLL 不兼容。此外，许多不同版本的 MFC 彼此不兼容。使用上述二进制查询工具之一来确定 Cadence 当前所需的 MFC 版本。
- 目前没有办法从插件回拨到 Allegro。
- 您的 DLL 可以在多个 Cadence 版本中使用，无需重新编译插件。仅在 Cadence 更改版本中的编译器时才需要重新编译。
- 插件中的编程错误可能会使宿主程序崩溃。在极少数情况下，这些错误可能会损坏 Allegro 数据库。（请参阅下面的客户支持。）
- 在 Windows 上，要访问 `stdout/stderr`，请在 OS 级别设置 `TELCONSOLE=1`。此变量不能通过 Allegro 的 `env` 文件设置。这也被视为调试环境，因此不应在电路板设计期间使用。

**Original**: Cadence only supports the compiler listed in the SPB Platform documentation. Also required are any compiler and DLL linker options listed. If your DLL has dependencies upon other DLLs, make sure those do not conflict with DLLs used by Cadence. Typically, they need to be the same version and not built with debug options. To determine the DLLs used by Cadence use: Windows: depends or procexp (www.sysinternals.com) Linux: ldd <program name> On Windows, you can include UI components in your plugin. This capability is not supported on Linux. Wide character types are not supported in the plugin to the Allegro interface. On Linux, if threading is used, then you should use POSIX threads (pthreads). STL programming should use the default STL provided by the Cadence required compiler. Do not use a third party STL. On Windows, if DLL is MFC based, then do not compile it debug. MFC Classes change in size if code is built debug and are not compatible with non-debug MFC code. There are methods described on the Web on how to build MFC debuggable without requiring the MFC debug shared library. Typically on Windows, Debug DLLs are not compatible with non-Debug DLLs. Also many different versions of MFC exist which are incompatible with one another. Use one of the binary query tools (see above) to determine the version of MFC currently required by Cadence. There are currently no methods to make function calls back to Allegro from the plugin. Your DLL can be used across multiple Cadence releases without recompiling your plugin. Re-compiling is only required if Cadence changes the compiler in the release. Programming errors in your plugin can crash the host program. In rare cases, these bugs can corrupt an Allegro database. (See customer support below.) On Windows, to access stdout/stderr, set the TELCONSOLE=1 as the OS level. This variable cannot be set via Allegro's env file. This is also considered a debug environment, so it should not be used during board design.

---

## 性能考虑 (Performance Considerations)

**说明**：如果需要高性能，应考虑以下问题：

- 定位和加载插件。每个激活应执行一次。将 `axlDllOpen` 返回的句柄分配给全局符号，以防止 SKILL 垃圾回收。不要关闭插件。
- 仅导入一次插件的符号。`axlDll` 接口在内部缓存符号导入，因此后续查找将比初始调用更快。
- 插件函数应执行有意义的工作，因为将输入数据从 SKILL 转换为原生 C 类型以及为返回数据执行相反操作存在一些开销。

**Original**: The following issues should be considered if high performance is required: Locating and loading a plugin. This should be done once per activation. Assign the handle return by axlDllOpen to a global symbol to prevent SKILL garbage collection. Do not close the plugin. Import symbols of a plugin once. The axlDll interface internally caches symbol import so subsequent lookups will be faster than the initial call. A plugin function should do meaningful work since there is some overhead converting input data from SKILL to native C types and doing the opposite for return data.

---

## Cadence 客户支持 (Cadence Customer Support)

**说明**：Cadence 不提供调试客户开发的插件的支持。

环境变量 `allegro_noextension_plugin` 可用于禁用插件功能。如果 Allegro 开始崩溃或数据库损坏，您应设置此变量以确定插件是否是原因。

**Original**: Cadence does not provide support for debugging customer-developed plugins. An environment variable, allegro_noextension_plugin, is available to disable plugin capability. If Allegro starts crashing or databases become corrupt, you should set this variable to determine if a plugin is the cause.

---

## 示例 (Examples)

**说明**：包含 SKILL、插件 C 代码、Gnu Makefile（Linux）和项目文件（Visual Studio）的示例位于 `<cdsroot>/share/pcb/examples/plugin`。此外，Cadence 安装层次结构中包含一个预构建的插件模块，因此您无需编译和链接插件源代码即可运行 SKILL 代码。

提供的示例插件有三个导出符号：
- 一个 echo API，返回给定的任何输入。
- 一个 `x_value` API，返回输入参数的数量。
- 一个距离实现，用于计算两点之间的距离。

**Original**: An example containing SKILL, the plugin C code, Gnu Makefile (Linux) and project file (Visual Studio) is contained at <cdsroot>/share/pcb/examples/plugin. In addition, a pre-built plugin module is contained in the Cadence install hierarchy so you do not need to compile and link the plugin source code to run the SKILL code. The example plugin provided has three exported symbols: An echo API, which returns as output any input given. A x_value API, which returns the number of input arguments. A distance implementation to calculate the distance between two points.

---

### axlDllCall

**说明**：此函数调用已从插件导入的符号。作为第一个参数，它需要 `o_pluginFunc`，这是通过调用 `axlDllSym` 返回的。其余参数是实现插件 API 定义的内容。

调用的返回值如下：
- `nil`：处理数据时出错
- `x_value`：插件函数返回非零结果
- `lg_data`：插件函数返回零，其输出值在列表中返回

**Original**: This function calls a symbol that has been imported from a plugin. As the first argument, it requires o_pluginFunc, which was returned via a call to axlDllSym. The rest of the arguments are what the implement plugin API has defined. The return from the call is one of the following: nil: error processing data; x_value: plugin function returned a non-zero result; lg_data: plugin function returned a zero and its output values are returned in a list. In turn it calls the import function from the plugin.

**语法**：
```skill
axlDllCall(o_pluginFunc [g_arg1] ... [g_arg10])
```

**参数**：
- `o_pluginFunc` — 插件符号句柄。
- `[g_arg1..10]` — 最多 10 个参数。

**返回值**：
- `nil` — 处理参数或查找函数时出错。
- `x_value` — 如果插件函数返回非零，则返回此值。
- `lg_data` — 如果插件函数返回零，则处理其输出参数并作为列表返回。如果插件的输出参数列表有 0 个条目，则返回空列表。

**另请参阅**：`axlDllOpen`

**示例**：
```skill
axlDllCall(_ashDistance 10:0 25.1:0) -> 15.1
```

---

### axlDllCallList

**说明**：此函数与 `axlDllCall` 相同，但它接受一个参数列表以传递给插件函数。与 `axlDllCall` 不同，后者最多限制为 10 个参数，此接口最多可接受 512 个参数。

请参阅 `axlDllCall` 获取进一步说明。

**Original**: This function is identical to axlDllCall except it takes a list of arguments to pass to the plugin function. Unlike axlDllCall, which is limited to 10 arguments, this interface can take up to 512 arguments. See axlDllCall for a further explanation.

**语法**：
```skill
axlDllCallList(o_pluginFunc l_args/nil)
```

**参数**：
- `o_pluginFunc` — 插件符号句柄。
- `l_args` — 最多 512 个参数的列表。

**返回值**：
- `nil` — 处理参数或查找函数时出错。
- `x_value` — 如果插件函数返回非零，则返回此值。
- `lg_data` — 如果插件函数返回零，则处理其输出参数并作为列表返回。如果插件的输出参数列表有 0 个条目，则返回空列表。

**另请参阅**：`axlDllCall`, `axlDllOpen`

**示例**：
```skill
_ashEcho = axlDllSym(_ashTestDll "ashEcho")
axlDllCallList(_ashEcho list(-1 -2.0 nil "another string" -10.1:-2 0.2))
```

---

### axlDllClose

**说明**：关闭一个打开的插件句柄。一旦句柄被关闭，您就无法再调用从插件获取的函数。此外，当没有通过 SKILL 垃圾回收的活动引用时，插件会自动关闭。

由于性能考虑，不建议关闭插件。

**Original**: This closes an open plugin handle. Once a handle is closed, you can no longer call functions obtained from the plugin. Also, a plugin is automatically closed when there are no active references to it via SKILL's garbage collection. It is not advisable to close a plugin due to performance considerations.

**语法**：
```skill
axlDllClose(o_plugin)
```

**参数**：
- `o_plugin` — 从 `axlDllOpen` 获取的插件句柄。

**返回值**：
- `t` — 如果成功关闭。
- `nil` — 如果句柄不是合法的句柄。

**另请参阅**：`axlDllOpen`

**示例**：请参阅 `axlDllOpen` 引用的示例。

---

### axlDllDump

**说明**：这是一个调试函数，报告 SKILL 加载的所有插件。

**Original**: This is a debug function that reports all plugins loaded by SKILL.

**语法**：
```skill
axlDllDump()
```

**参数**：无。

**返回值**：
- `l_dllLoad` — 插件句柄列表，如果没有加载的插件则返回 `nil`。

**另请参阅**：`axlDllOpen`

**示例**：
```skill
axlDllDump()
```

---

### axlDllOpen

**说明**：将 DLL/共享库绑定到当前程序。虽然这可以加载任何 DLL，但只有那些构建为与 axl 插件模型兼容的 DLL 才能通过 SKILL 使用（请参阅 **DLL 编程** 了解如何构建兼容的 DLL）。

如果 DLL 名称没有目录路径组件，则使用 `AXLPLUGINPATH` 环境变量搜索 DLL。

DLL 成功加载后，您需要导入一个或多个符号（`axlDllSym`）。

**插件属性**：

| Name（名称） | Type（类型） | Description（描述） |
|---|---|---|
| name | string | 插件文件名（DLL 名称） |
| functions | l_dbid | 导入符号的游离属性列表名称/值对（`t_name o_pluginFunc`） |
| objType | string | "plugin" |

要访问导入的插件函数类型，请执行 `<o_plugin>->functions-><pluginFuncName>`。

**Original**: This binds a DLL/shared library to the current program. While this can load any DLL, only those built to be compatible with the axl Plugin model can be utilized via SKILL (see DLL Programming for information on building compatible DLLs). If the DLL name does not have a directory path component, then AXLPLUGINPATH environment variable is used to search for the DLL. After a DLL is successfully loaded, you need to import one or more symbols (axlDllSym).

**语法**：
```skill
axlDllOpen(t_dllname)
```

**参数**：
- `t_dllname` — DLL 的名称。为了平台独立性，强烈建议不要包含文件扩展名或目录路径组件。

**返回值**：
- `o_plugin` — 插件句柄。
- `nil` — 无法定位库或不是 DLL。

**另请参阅**：**DLL 编程**, `axlDllSym`, `axlDllCall`, `axlDllCallList`, `axlDllClose`, `axlDllDump`

**示例**：
```skill
_ashTestDll = axlDllOpen("axlecho_plugin")
```

---

### axlDllSym

**说明**：从已加载的 dll 导入符号。一个 dll 可以有一个或多个导出符号。该符号必须在编译和链接 dll 时从 dll 导出（请参阅 `axlDllDoc`）。

**PluginFunc 属性**：

| Name（名称） | Type（类型） | Description（描述） |
|---|---|---|
| name | string | 导入符号文件的名称 |
| functions | nil | 始终为 `nil` |
| objType | string | "pluginFunc" |

**Original**: This imports a symbol from a loaded dll. A dll can have one or more exported symbols. The symbol must have been exported from the dll when the dll was compiled and linked (See axlDllDoc).

**语法**：
```skill
axlDllSym(o_plugin t_symbolName)
```

**参数**：
- `o_plugin` — 来自 `axlDllOpen` 的 dll 句柄。
- `t_symbolName` — dll 中导出函数的名称。

**返回值**：
- `o_pluginFunc` — 符号句柄。
- `nil` — 错误；符号不在 dll 中。

**另请参阅**：`axlDllOpen`

**示例**：
```skill
_ashDistance = axlDllSym(_ashTestDll "ashDistance")
```
从 axl 插件测试 dll 加载距离符号。

---

*返回顶部 (Return to top)*
