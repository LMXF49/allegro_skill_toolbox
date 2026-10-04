# 第 13 章 消息处理 (Message Handler)

> **来源**：`13msghnd.html`  
> **产品版本**：Allegro SKILL Reference 17.4-2019, October 2019

---

## 概述 (Overview)

**说明**：本章描述 AXL-SKILL 消息处理系统及其函数。消息处理系统允许您编写 AXL-SKILL 代码，无需在每次调用底层例程后显式处理错误，而只需在一个或两个检查点处进行检查。这与没有缓冲和异常处理消息设施的应用程序形成对比，在那些程序中，您必须在代码中每个可能出错的位置进行测试和响应。使用本章描述的函数，您可以执行以下操作：

**Original**: This chapter describes the AXL-SKILL message handler system and functions. The message handler system allows you to write AXL-SKILL code that does not have to deal explicitly with errors after each call to a lower level routine, but rather checks at only one or two points. This contrasts with application programs that do not have a buffering and exception-handling message facility, where you must test for and respond to errors and exceptions at each point of possible occurrence in your code. Using the functions described in this chapter, you can do the following:

- 为应用程序消息建立**上下文**（context）。

**Original**: Establish a context for your application messages.

上下文是应用程序中的一个逻辑段，在此期间您希望缓冲和测试底层代码中已提供的潜在错误和警告。

**Original**: A context is a logical section of your application during which you want to buffer and test for the potential errors and warnings you provided for in the lower levels of your application code.

- 使用五种**严重级别**（severity）之一向用户写入消息：

**Original**: Write messages to the user with one of five levels of severity:

### 严重级别表

| 严重级别 (Severity Level) | 类型 (Type) | 类型说明与 AXL 消息处理器的响应 (Type Description and Response by AXL Message Handler) |
|---|---|---|
| 0 | Text | 由应用程序创建的数据，如日志或报告。写入日志和用户界面，不进行缓冲。 |
| 1 | Info | 如 "10% 完成"、"20% 完成"... 仅写入用户界面，不写入上下文消息缓冲区或日志。 |
| 2 | Warning | 如 "连接线的宽度比允许的宽 5 mils。" 写入上下文消息缓冲区和日志，并带有 "W" 警告标记。 |
| 3 | Error | 如 "在库中找不到符号 DIP24_200。" 发出蜂鸣声并写入上下文消息缓冲区和日志，并带有 "E" 错误标记。 |
| 4 | Fatal | 如 "磁盘读取错误。无法继续。" 发出双蜂鸣声并写入上下文消息缓冲区和日志，并带有 "F" 致命标记。 |

**Original**: Severity Level / Type / Type Description and Response by AXL Message Handler table

- 测试和更改在上下文中创建和缓冲的消息的严重级别。

**Original**: Test and change the severity level of the messages created and buffered in a context.

- 在消息缓冲区中检查特定消息，并对由底层函数检测到的预期条件做出适当响应。

**Original**: Check for specific messages in the message buffer, and respond appropriately to anticipated conditions detected by lower-level functions.

- 关闭上下文。

**Original**: Close a context.

以下图示展示了 `axlMsg` 函数如何在上下文消息缓冲区和 SKILL 用户界面之间移动消息。

**Original**: The following illustration shows how axlMsg functions move messages to and from a context message buffer and the SKILL user interface.

---

### 消息处理示例 (Message Handler Example)

```skill
context = axlMsgContextStart("My own context.")
axlMsgPut(list("My warning" 2))
axlMsgPut(list("My error" 3))
printf("Message severity %d",axlMsgContextTest(context))
axlMsgPut(list("My fatal error %s" 4) "BAD ERROR")
if( axlMsgContextInBuf(context "My error")
printf("%s\n" "my error is there"))
printf("Message severity %d",axlMsgContextTest(context))
axlMsgContextPrint(context)
axlMsgContextFinish(context)
⇒ t
```

- 使用 `axlMsgContextStart` 启动上下文
- 使用 `axlMsgPut` 放置警告、错误和致命错误消息
- 使用 `axlMsgContextInBuf` 检查错误消息
- 使用 `axlMsgContextTest` 测试上下文严重级别
- 使用 `axlMsgContextPrint` 打印上下文缓冲区
- 使用 `axlMsgContextFinish` 结束

**Original**: Starts a context with axlMsgContextStart, Puts a warning, an error, and a fatal error message using axlMsgPut, Checks for the error message with axlMsgContextInBuf, Tests for the context severity level with axlMsgContextTest, Prints the context buffer with axlMsgContextPrint, Ends with axlMsgContextFinish

加载上述 SKILL 程序时，SKILL 命令行输出如下：

**Original**: When you load the SKILL program shown above, the SKILL command line outputs the following:

```
W- My warning
E- My error
F- My fatal error BAD ERROR
Message severity 3
my error is there
Message severity 4
t
```

---

### axlMsg 系统的一般用法 (General usage of the axlMsg System)

消息首先进入上下文缓冲区。`axlMsgContextPrint` 将它们打印到 SKILL 命令行。

**Original**: Messages first go to the context buffer. axlMsgContextPrint prints them to the SKILL command line.

任何 `print` 和 `printf` 数据输出缓冲区的内容在控制返回命令行时写入命令行。这就是为什么消息 "Message severity 3"、"my error is there" 和 "Message severity 4" 出现在缓冲消息（"W- My warning"...）之后的原因。

**Original**: The contents of the output buffer from any print and printf data write to the command line when control returns to the command line. That is why the messages "Message severity 3," "my error is there" and "Message severity 4" follow the buffered messages ("W- My warning" ...)

---

## 消息处理函数 (Message Handler Functions)

本节列出消息处理函数。

**Original**: This section lists message handler functions.

### axlMsgPut

**说明**：将消息放入日志文件。使用此函数来 "打印" 消息。它会缓冲任何错误或警告，但会立即处理其他消息类别。

**Original**: Puts a message in the journal file. Use this function to "print" messages. It buffers any errors or warnings, but processes other message classes immediately.

**语法**：
```skill
axlMsgPut(
  g_message_format
  [g_arg1 ...]
)
```

**参数**：

- `g_message_format`: 上下文消息（类 printf）格式字符串。请参阅 "概述" 了解消息和有效参数的说明。**Original**: Context message (printf like) format string. See "Overview" for a description of messages and valid arguments.

- `g_arg1 ...`: 格式字符串的替换参数值。**Original**: Values for substitution arguments for the format string.

**返回值**：

- `t`: 始终返回 `t`。

**示例**：

```skill
axlMsgPut(list("Cannot find via %s" 3) "VIA10")
⇒ t
```

---

### axlMsgContextPrint

**说明**：打印缓冲的消息并将其从消息缓冲区中移除。

**Original**: Prints the buffered messages and removes them from the message buffer.

**语法**：
```skill
axlMsgContextPrint(
  r_context
)
```

**参数**：

- `r_context`: 来自 `axlMsgContextStart` 的上下文句柄。仅打印此上下文（或任何子上下文）的消息。参数为 `nil` 时，`axlMsgContextPrint` 将查找所有上下文。**Original**: Context handle from axlMsgContextStart. Prints messages only for this context (or any children). An argument of nil causes axlMsgContextPrint to look through all contexts.

**返回值**：

- `t`: 始终返回 `t`。

**示例**：

```skill
axlMsgContextPrint(context)
⇒ t
Prints the buffered messages in that context to SKILL command line:
W- My warning
E- My error
F- My fatal error BAD ERROR
```

---

### axlMsgContextGetString

**说明**：获取消息缓冲区中的消息并将其从缓冲区中移除。随后调用 `axlMsgContextGetString` 可将这些消息传递给用户（例如，写入日志文件）。

**Original**: Gets the messages in the message buffer and removes them from the buffer. Call axlMsgContextGetString subsequently to communicate those messages to the user (for example, in a log file).

**语法**：
```skill
axlMsgContextGetString(
  r_context
)
⇒ lt_messages / nil
```

**参数**：

- `r_context`: 来自 `axlMsgContextStart` 的上下文句柄。仅获取此上下文（或任何子上下文）的消息。参数为 `nil` 时，`axlMsgContextGetString` 将查找所有上下文。**Original**: Context handle from axlMsgContextStart. Gets messages only for this context (or any children). An argument of nil causes axlMsgContextGetString to look through all contexts.

**返回值**：

- `lt_messages`: 缓冲消息的文本字符串列表。

- `nil`: 未找到缓冲消息。

**示例**：

```skill
axlMsgContextGetString(context)
⇒ ("My warning" "My error" "My fatal error BAD ERROR")
```

---

### axlMsgContextGet

**说明**：获取缓冲消息的格式字符串。（不是消息本身。请比较此处的示例与 `axlMsgContextGetString` 中显示的示例。）不会将消息从消息缓冲区中移除，而是为调用者提供一种替代方案，避免进行多次 `axlMsgContextInBuf` 调用。

**Original**: Gets the format strings of the buffered messages. (Not the messages themselves. Compare the example here and the one shown for axlMsgContextGetString.) Does not remove the messages from the message buffer, rather it simply provides the caller an alternative to making a number of axlMsgContextInBuf calls.

**语法**：
```skill
axlMsgContextGet(
  r_context
)
⇒ lt_format_strings / nil
```

**参数**：

- `r_context`: 来自 `axlMsgContextStart` 的上下文句柄。仅获取此上下文（或任何子上下文）的消息。参数为 `nil` 时，`axlMsgContextGet` 将查找所有上下文。**Original**: Context handle from axlMsgContextStart. Gets messages only for this context (or any children). An argument of nil causes axlMsgContextGet to look through all contexts.

**返回值**：

- `lt_format_strings`: 缓冲消息的格式字符串列表。

- `nil`: 未找到缓冲消息。

**示例**：

```skill
mylist = axlMsgContextGet(context)
⇒ ("My warning" "My error" "My fatal error %s")
```

---

### axlMsgContextTest

**说明**：返回上下文消息缓冲区中消息的最严重消息类别。请参阅 `axlMsgContextInBuf` 以检查特定消息类别。

**Original**: Returns the most severe message class of the messages in the context message buffer. See axlMsgContextInBuf to check for a particular message class.

**语法**：
```skill
axlMsgContextTest(
  r_context
)
⇒ x_class
```

**参数**：

- `r_context`: 来自 `axlMsgContextStart` 的上下文句柄。仅查找此上下文的消息。如果 `r_context` 为 `nil`，`axlMsgContextTest` 将查找所有上下文。**Original**: Context handle from axlMsgContextStart. Looks only for messages for this context. If r_context is nil, axlMsgContextTest looks through all contexts.

**返回值**：

- `x_class`: 给定上下文消息缓冲区中消息的最严重消息类别。

**示例**：

```skill
printf("Message severity %d\n" axlMsgContextTest(context))
⇒ Message severity 4
```

---

### axlMsgContextInBuf

**说明**：检查消息 `t_format_string` 是否在上下文 `r_context` 的消息缓冲区中。使应用程序能够根据被调用函数报告的特定消息来控制代码流程。检查基于原始格式字符串，而非完全替换后的消息。

**Original**: Checks whether message t_format_string is in the message buffer of context r_context. Gives the application the ability to control code flow based on a particular message reported by a called function. The check is based on the original format string, not the fully substituted message.

**语法**：
```skill
axlMsgContextInBuf(
  r_context
  t_format_string
)
⇒ t
```

**参数**：

- `r_context`: 来自 `axlMsgContextStart` 的上下文句柄。仅查找此上下文（或任何子上下文）中的消息。如果 `r_context` 为 `nil`，`axlMsgContextInBuf` 将查找所有上下文。**Original**: Context handle from axlMsgContextStart. Looks only for messages in this context (or any children). If r_context is nil, axlMsgContextInBuf looks through all contexts.

- `t_format_string`: 消息的格式字符串。**Original**: Format string of the message.

**返回值**：

- `t`: 指定消息在缓冲区中。

- `nil`: 指定消息不在缓冲区中。

**示例**：

```skill
if( axlMsgContextInBuf(context "My error")
printf(%s\n" "My error is there"))
```

---

### axlMsgContextRemove

**说明**：从缓冲消息中移除一条（或多条）消息。允许您从缓冲区中移除您在后续过程中决定不希望用户看到的消息（通常是警告）。

**Original**: Removes a message (or messages) from the buffered messages. Lets you remove messages (usually warnings) from the buffer that you decide, later in a procedure, that you do not want the user to see.

**语法**：
```skill
axlMsgContextRemove(
  r_context
  t_format_string
)
⇒ t
```

**参数**：

- `r_context`: 来自 `axlMsgContextStart` 的上下文句柄。仅移除此上下文（或任何子上下文）的消息。如果 `r_context` 为 `nil`，`axlMsgContextRemove` 将查找所有上下文。**Original**: Context handle from axlMsgContextStart. Removes messages for only this context (or any children). If r_context is nil, axlMsgContextRemove looks through all contexts.

- `t_format_string`: 消息的格式字符串。缓冲区中消息的匹配会忽略用于生成消息完整文本的替换参数。**Original**: Format string of the message. The match for the message in the buffer ignores the substitution parameters used to generate the full text of the message.

**返回值**：

- `t`: 始终返回 `t`。

**示例**：

```skill
axlMsgContextRemove(context, "My fatal error %s")
⇒ t
```

---

### axlMsgContextStart

**说明**：指示消息上下文的开始。打印该上下文的任何缓冲消息。

**Original**: Indicates the start of a message context. Prints any buffered messages for the context.

**语法**：
```skill
axlMsgContextStart(
  g_format_string
  [g_arg1 ...]
)
⇒ r_context
```

**参数**：

- `g_format_string`: 上下文消息（类 printf）格式字符串。**Original**: Context message (printf like) message format string.

- `g_arg1 ...`: 格式字符串替换参数的值。如果函数返回的值不足，请使用 `axlMsgClear`（以及 `Test`/`Set`）函数来控制代码流程。**Original**: Values for the substitution arguments for the format string. Use axlMsgClear (and Test / Set) functions to control code flow if the function returns insufficient values.

**返回值**：

- `r_context`: 用于后续 `axlMsgContext` 调用的上下文句柄。

**示例**：

```skill
context = axlMsgContextStart("Messages for %s" "add line")
Messages for add line
5
```

---

### axlMsgContextFinish

**说明**：指示消息上下文的结束。打印上下文中的任何缓冲消息并清除上下文缓冲区。

**Original**: Indicates the finish of a message context. Prints any buffered messages in the context and clears the context buffer.

**语法**：
```skill
axlMsgContextFinish(
  r_context
)
⇒ t
```

**参数**：

- `r_context`: 来自 `axlMsgContextStart` 的上下文句柄。**Original**: Context handle from axlMsgContextStart.

**返回值**：

- `t`: 始终返回 `t`。

**示例**：

```skill
context = axlMsgContextStart()
... do some things ...
axlMsgContextFinish(context)
```

---

### axlMsgContextClear

**说明**：清除上下文的缓冲消息。通常不应使用此函数。请使用打印（`axlMsgContextPrint`）或检索（`axlMsgContextGetString`）消息然后清除它们的函数，或使用强制打印消息的上下文结束（`axlMsgContextFinish`）。

**Original**: Clears the buffered messages for a context. You should not normally use this function. Use functions that print (axlMsgContextPrint) or retrieve (axlMsgContextGetString) messages and then clear them, or use a context finish (axlMsgContextFinish) that forces the messages to be printed.

**语法**：
```skill
axlMsgContextClear(
  r_context
)
⇒ t
```

**参数**：

- `r_context`: 来自 `axlMsgContextStart` 的上下文句柄。如果 `r_context` 为 `nil`，则清除所有上下文中的所有消息。**Original**: Context handle from axlMsgContextStart. If r_context is nil, clears all messages in all contexts.

**返回值**：

- `t`: 始终返回 `t`。

**示例**：

```skill
context = axlMsgContextStart()
... do some things ...
axlMsgContextClear(context)
```

---

### axlMsgCancelPrint

**说明**：打印一条消息，告知用户他请求了取消（cancel）。由于此消息的严重性为 Error (3)，AXL 会将其与其他警告、错误和致命消息一样写入上下文缓冲区。请仅从请求用户输入的例程中调用此函数。

**Original**: Prints a message informing the user that he requested cancel. Since the severity of this message is Error (3), AXL writes it to the context buffer as it does other warning, error, and fatal messages. Call this function only from a routine that requests user input.

**语法**：
```skill
axlMsgCancelPrint()
⇒ t
```

**返回值**：

- `t`: 始终返回 `t`。

**示例**：

```skill
axlMsgCancelPrint()
Sets severity level to 2 (warning) and puts the following into the message buffer (if axlMsgSys messages are in English):
User CANCEL received
```

---

### axlMsgCancelSeen

**说明**：检查 `axlMsgCancelPrint` 消息是否已打印。不轮询输入流中的 CANCEL 键。检查当前消息缓冲区中是否出现了 `axlSsgSys.cancelRequest` 消息。

**Original**: Checks to see if the axlMsgCancelPrint message was printed. Does not poll the input stream for a CANCEL key. Checks the buffer of current messages for the occurrence of the axlSsgSys.cancelRequest message.

**语法**：
```skill
axlMsgCancelSeen()
⇒ t / nil
```

**返回值**：

- `t`: 已看到请求的取消。

- `nil`: 未看到请求的取消。

**示例**：

```skill
if( axlMsgCancelSeen()
; clear input and return
...
```

---

### axlMsgClear

**说明**：清除当前错误严重级别。您可以先使用 `axlMsgTest` 保存严重级别，然后使用 `axlMsgSet` 重新设置。

**Original**: Clears the current error severity level. You can reset the severity by first saving it using axlMsgTest, then setting it using axlMsgSet.

**语法**：
```skill
axlMsgClear()
⇒ t
```

**返回值**：

- `t`: 始终返回 `t`。

**示例**：

```skill
axlMsgClear()
```

---

### axlMsgSet

**说明**：设置当前错误严重级别。仅用于重置使用 `axlMsgClear` 清除的严重级别。

**Original**: Sets the current error severity level. Use only to reset the severity cleared using axlMsgClear.

**语法**：
```skill
axlMsgSet(
  x_class
)
⇒ t
```

**参数**：

- `x_class`: 严重级别。**Original**: Severity level.

**返回值**：

- `t`: 始终返回 `t`。

**示例**：

```skill
level = axlMsgTest()
; Do something
...
axlMsgSet(level)
```

---

### axlMsgTest

**说明**：确定当前错误严重级别。返回一个数字，表示自上次 `axlMsgClear` 或 `axlMsgContextClear`/`Print`/`GetMsg` 调用以来打印的所有消息中最严重消息的级别。

**Original**: Determines the current error severity level. Returns a single number giving the severity level of the most severe message that has been printed since the last axlMsgClear or axlMsgContextClear / Print / GetMsg call.

**语法**：
```skill
axlMsgTest()
⇒ x_class
```

**返回值**：

- `x_class`: 当前消息缓冲区中所有消息的最高严重级别。

**示例**：

```skill
level = axlMsgTest()
⇒ 4
```

---

