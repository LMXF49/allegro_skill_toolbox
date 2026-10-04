# 第 29 章 语言扩展 (Language Extensions)

> **来源**：`27langexten.html`  
> **产品版本**：Allegro SKILL Reference 17.4-2019, October 2019

---

## 概述 (Overview)

**说明**：本章描述 SKILL 语言扩展函数。

**Original**: This chapter describes the SKILL Language Extensions functions.

---

### axldo / axldoStar

**说明**：一个 do 函数，以 CL（Common Lisp）的 do 为模型。

**Original**: A do function, modeled after the CL (Common Lisp) do.

公共接口：

**Original**: Public:

```skill
(defmacro do ((var [init [step]]) ...) (end-test result result ...) @body)
(defmacro doStar ((var [init [step]]) ...) (end-test result result ...) @body)
```

`do` 宏提供了一种通用的迭代机制，带有任意数量的**索引变量**（index variables）。这些变量在迭代内部被绑定，并以指定的方式步进。它们既可以用于生成连续的有用值，也可以用于累积结果。当满足结束条件（由 end-test 指定）时，迭代终止，结果表达式（result sexps）被依次求值，然后返回最后一个结果表达式的值。

**Original**: The do macro provides a generalized iteration facility, with an arbitrary number of index variables. These variables are bound within the iteration and stepped in specified ways. They may be used both to generate successive values of interest or to accumulate results. When an end condition is met (as specified by end-test), the iteration terminates, the result sexps are successive evaluated, and the value of the last result sexp is returned.

表单中的第一项是 0 个或多个索引变量说明符的列表。每个索引变量说明符是一个列表，包含变量名 `var`、初始值 `init` 和步进形式 `step`。

**Original**: The first item in the form is a list of 0 or more index-variable specifiers. Each index-variable specifier is a list of the name of the variable, var; an initial value, init; and a stepping form, step.

如果省略 `init`，则默认为 `nil`。如果省略 `step`，则 `do` 构造在重复之间不会更改该变量（尽管 do 内的代码可以使用 `setq` 自由更改该变量的值）。

**Original**: If init is omitted, it defaults to nil. If step is omitted, the var is not changed by the do construct between repetitions (though code within the do is free to alter the value of the variable by using setq).

索引变量说明符也可以只是变量名。在这种情况下，变量的初始值为 `nil`，在重复之间不会更改。这很像 `let` 语句中局部作用域变量的用法。

**Original**: An index-variable specified can also be just the name of a variable. In this case, the variable has an initial value of nil and is not changed between repetitions. This would be used much as a locally scoped variable in a let statement would be.

在第一次迭代之前，所有 init 形式都被求值，每个 `var` 被绑定到其相应 init 的值。由于这是绑定而非赋值，当循环终止时，变量的旧值会被恢复。所有 init 形式在任何变量绑定之前都被求值；因此所有 init 形式都可以引用所有变量的旧绑定（即，在开始执行 do 之前可见的值）。

**Original**: Before the first iteration, all the init forms are evaluated, and each var is bound to the value of its respective init. Because this is a binding, and not an assignment, when the loop terminates the old values of the variables is restored. All of the init forms are evaluated before any var is bound; hence all the init forms may refer to the old bindins of all the variables (that is, to the values visible BEFORE beginning execution of the do).

对于 `axldo`，所有 init 绑定是**并行**进行的；对于 `axldoStar`，是**串行**进行的。

**Original**: All init bindings are done in parallel for axldo, and serially for axldoStar.

循环的第二个元素是一个列表，包含结束测试谓词形式 end-test 和零个或多个结果形式。这类似于 `cond` 子句。在每次迭代的开始，处理变量后，对 end-test 进行求值。如果结果为 `nil`，则执行表单的主体。如果结果为非 `nil`，则结果形式按顺序作为隐式 `progn` 求值，然后 do 返回最后一个求值结果。

**Original**: The second element of the loop is a list of an end-testing predicate form end-test, and zero or more result forms. This resembles a 'cond' clause. At the beginning of each iteration, after processing the variables, the end-test is evaluated. If the result is nil, execution proceeds with the body of the form. If the result is non-nil, the result forms are evaluated in order as an implicit 'progn', and then the do returns the value of the last evaluated result.

在每次迭代的开始，索引变量按以下方式更新：

**Original**: At the beginning of each iteration, the index variables are updated as follows.

所有步进形式从左到右求值，结果值被赋给相应的索引变量。任何没有步进值的变量不会被赋值。

**Original**: All the step forms are evaluated, from left to right, and the resulting values are assigned to the respective index variables. Any variable that has no step value is not assigned.

**语法**：
```skill
axldo(
  g_initList
  g_terminateList
  [g_body]
) -> g_result

axldoStar(
  g_initList
  g_terminateList
  [g_body]
) -> g_result
```

**参数**：

- `g_initList`: 0 个或多个索引变量说明符。

**Original**: 0 or more index variable specifiers

- `g_termiateList`: 结束测试谓词。

**Original**: end test predicate

- `g_body`: 过程主体。

**Original**: body of procedure

**返回值**：

- 求值最后一个结果表达式所得的值。

**Original**: Value resulting from evaluating last result sexp.

**另请参阅 (See Also)**：`letStar`

**Original**: See Also `letStar`

---

### copyDeep

**说明**：此函数递归地复制一个列表。`copy` 函数创建一个新列表，包含源列表中所有顶层元素的副本。但每个新元素包含对源列表中相同子列表元素的引用。因此，如果在源列表中修改子列表项，副本中也会修改，反之亦然。`copyDeep` 函数从头到尾完整地复制列表。因此，在一个列表中的更改不会影响另一个列表。当然，这会分配更多的内存。

**Original**: This function recursively copy a list. The copy function makes a new list containing copies of all top level elements in the source list. But each new element contains references to the same sublist elements as the source list. Thus, if sublist items are modified in the source list they are also modified in the copy, and vice-versa. The copyDeep function makes a complete copy of the list, top to bottom. So changes in one list do not affect the other. This allocates more memory, of course.

**语法**：
```skill
copyDeep(
  l_object
) -> l_newObject
```

**参数**：

- `l_object`: 要复制的列表。

**Original**: The list to be copied

**返回值**：

- 一个与原始列表相同但不共享内存的新列表。

**Original**: A new list identical to the original but sharing no memory.

---

### isBoxp

**说明**：检查参数是否为有效的包围盒（bounding box）。有效的包围盒应为 `((a b) (c d))` 的形式，其中 `a`、`b`、`c` 和 `d` 均为数字，且 `a != c` 和 `b != d`，以确保包围盒包围了一定的面积。

**Original**: Checks argument to see if it is a valid bounding box. A valid bounding box should be of the form of ((a b) (c d)) where a, b, c, and d are all numbers and a!= c and b!= d, to ensure that the bounding box encloses some area.

**语法**：
```skill
isBoxp(
  g_bBox
)
==> t/nil
```

**参数**：

- `g_bBox`: 要测试的输入参数。

**Original**: input argument to be tested.

**返回值**：

- `t`: 如果 `g_bBox` 是有效的包围盒。

**Original**: t : If g_bBox is a valid bounding box.

- `nil`: 如果 `g_bBox` 不是有效的包围盒。

**Original**: nil : If g_bBox is not a valid bounding box.

---

### lastelem

**说明**：`last()` 函数返回列表中的最后一个 LIST 对象，但 `lastelem()` 取该对象的 car 以获取最后一个 ATOM。

**Original**: The last() function returns the last LIST object in a list, but lastelem() takes the car of that to get the last ATOM.

**语法**：
```skill
lastelem(
  l_list
) -> g_elem
```

**参数**：

- `l_list`: 一个列表。

**Original**: a list

**返回值**：

- 列表的最后一个原子元素。

**Original**: The last atom element of a list.

**示例**：

```skill
l = list(1 2 3)
last(l) -> (3)
lastelem(l) -> 3
```

---

### letStar

**说明**：这是 CL（Common Lisp）的 `let*` 实现。这是一个过程函数。

**Original**: This is a let* implementation of CL (Common Lisp).This is a procedure function.

**语法**：
```skill
letStar(
  l_bindings
  [@body]
) -> g_lastValue
```

**参数**：

- `l_bindings`: `l_varbind` 列表。

**Original**: list of l_varbind

- `l_varbind`: 为 `(<name> <value>)`。
  - `name`: 作为词法作用域符号进行 intern。
  - `value`: 求值以得到值。

**Original**: is (<name> <value>) / name: interned as lexically-scoped symbol / value: evaluated to arrive at value

- `@body`: 要求值的一个或多个表达式。

**Original**: one or more expressions to be evaluated.

**返回值**：

- `@body` 的最后一个值。

**Original**: last value of @body

**另请参阅 (See Also)**：`axldo`

**Original**: See Also `axldo`

---

### listnindex

**说明**：查找元素在列表中的位置。其工作方式与 `nindex` 类似，但在列表中查找元素的位置，而不是在字符串中查找字符。返回一个整数，表示第一个匹配元素的序号。

**Original**: Finds the position of an item in a list. Works just like nindex, but finds the position of an element in a list instead of a character in a string. An integer denoting the sequence number of the first matching element is determined.

**语法**：
```skill
listnindex(
  l_theList
  g_item
) -> x_found/nil
```

**参数**：

- `l_theList`: 包含要查找元素的列表。

**Original**: A list containing the element to be found

- `g_item`: 要查找的元素。

**Original**: The element to be found

**返回值**：

- 元素首次找到的位置，如果未找到则为 `nil`。

**Original**: The position in the list where the element was first found, or nil if it is not found.

`x_found` 从 0 开始，因此您可以使用其他 SKILL 函数如 `nth`。

**Original**: x_found is 0 based so you use other SKILL functions like nth

**示例**：

```skill
listnindex( '("three" "dog" 'night) "dog") -> 1
```

---

### movedown

**说明**：查找列表中元素的所有出现位置，并将它们向列表尾部移动一个位置。对其他项和列表的最后一个元素不执行任何操作。

**Original**: Find all occurrences of element within a list and moves them one item closer to the list tail. No action for other items and the last element of the list.

此函数会破坏性地修改列表。

**Original**: This destructively modifies the list.

**语法**：
```skill
movedown(
  g_elem
  l_list
) --> l_newlist
```

**参数**：

- `g_elem`: 要移动的元素，使用 `equal` 匹配。

**Original**: The element to be moved, matched using (equal)

- `l_list`: 包含要移动元素的列表。

**Original**: The list containing the element to be moved.

**返回值**：

- 修改后的列表。

**Original**: The modified list.

---

### moveup

**说明**：将元素向列表头部移动一个位置。查找列表中元素的所有出现位置，并将它们向列表头部移动一个位置。对其他项和列表的第一个元素不执行任何操作。

**Original**: Moves an element one item closer to the head of a list. Finds all occurrences of the element within a list and moves them one item closer to the list head. No action for other items and the first element of the list.

此函数会破坏性地修改列表。

**Original**: This destructively modifies the list.

**语法**：
```skill
moveup(
  g_elem
  l_list
) --> l_newlist
```

**参数**：

- `g_elem`: 要移动的元素，使用 `equal` 匹配。

**Original**: The element to be moved, matched using (equal)

- `l_list`: 包含要移动元素的列表。

**Original**: The list containing the element to be moved.

**返回值**：

- 修改后的列表。

**Original**: The modified list.

---

### parseFile

**说明**：解析文件的所有行。打开输入文件并逐行读取。每行使用 `parseQuotedString` 进行解析。`parseQuotedString` 的结果被传递给应用程序定义的处理器 `s_handler`。处理器定义返回值。

**Original**: Parse all lines of a file. Opens input file and reads it line by line. Each line is parsed using parseQuotedString. The result of parseQuotedString is passed to the application defined handler s_handler. The handler defines the return value.

**语法**：
```skill
parseFile (
  t_fileName
  s_handler
  [t_breakChars]
)
==> g_result
```

**参数**：

- `t_fileName`: 要读取的文件名。

**Original**: Name of file to be read.

- `s_handler`: 应用程序回调函数，用于处理解析后的参数。

```skill
s_handler (
  l_curLineInfo
  l_lineArgs
  g_result
)
==> g_result
```

**Original**: Application callback function to process parsed arguments

- `l_curLineInfo`: 描述当前正在处理的行的信息列表。定义为：`(t_fileName g_lineNo t_curString)`
  - `t_fileName`: 正在读取的文件名
  - `g_lineNo`: 当前行号
  - `t_curString`: 未解析的文件行

**Original**: List of info which describes the current line being processed. Defined as: (t_fileName g_lineNo t_curString) / t_fileName: Name of file being read / g_lineNo: Current line number / t_curString: Unparsed file line

- `l_lineArgs`: 解析行后得到的字符串列表。

**Original**: List of strings that result from parsing the line.

- `g_result`: 应用程序回调结果。这个结果会持续传递给 `s_handler`，以便可以从所有文件行的处理中构建结果。第一次调用时此值为 `nil`，后续调用时为 `s_handler` 上次返回的值。

**Original**: The application callback result. This is continually passed to s_handler so that a result can be built up from the processing of all file lines. This will be nil the first time and will be whatever s_handler last returned for subsequent calls.

- `t_breakChars`: 可选的字符串，包含用作分隔字符的字符。默认值为 `"'\" "`（引号字符和空格字符）。

**Original**: Optional string containing characters that are used as break characters. The default is "'\" " (quote chars and space char).

**返回值**：

- `g_result`: 最后一次调用 `s_handler` 的应用程序回调结果。

**Original**: The application callback result from the last call to s_handler.

---

### parseQuotedString

**说明**：将字符串拆分为单词列表。多个用引号括起来的单词被视为单个单词。

**Original**: Breaks a string into a list of words. Multiple words enclosed within quotation marks are treated as single words.

**语法**：
```skill
parseQuotedString(
  t_string
  [t_breakCharacters]
)
==> l_strings
```

**参数**：

- `t_string`: 要解析的字符串。

**Original**: String to be parsed.

- `t_breakCharacters`: 可选的字符串，包含用作分隔字符的字符。默认值为 `"'\" "`（引号字符和空格字符）。

**Original**: Optional string containing characters to be used as break characters. The default is "'\" " (quote chars and space char).

**返回值**：

- `l_strings`: 从 `t_string` 参数解析出的字符串列表。

**Original**: A list of strings parsed from the t_string argument.

除非引号字符是分隔字符，否则在引号开头不会创建单词分隔。

**Original**: A word break is not created at the start of a quote unless the quote character is a break character.

**示例**：

```skill
parseQuotedString( "111 222'333 444'" " ")
=> ("111" "222333 444")

parseQuotedString( "111 222'333 444'" "' ")
=> ("111" "222" "333 444")
```

---

### pprintln

**说明**：在行的末尾打印一个换行字符。

**Original**: Prints a newline character at the end of the line.

**语法**：
```skill
pprint(
  g_item
  [p_port]
) -> t/nil
```

**参数**：

- `g_item`: 要打印的项。

**Original**: The item to be printed.

- `p_port`: 可选参数，指定要写入的端口。默认值为 stdout。

**Original**: The optional parameter that specifies the port to write to. Default value is stdout.

**返回值**：

- 返回漂亮打印的项加上一个换行字符。

**Original**: Returns item pretty printed plus a newline character.

---

### propNames

**说明**：使用此命令获取游离属性列表（disembodied property list）中的属性名称。遍历游离属性列表中的每个属性，构建每个属性名称的列表。

**Original**: Use this command to get the names of properties in a disembodied property list. Walk each property in disembodied property list, building a list of the names of each property.

返回的属性名称顺序未指定。

**Original**: Order of returned property names is unspecified.

**语法**：
```skill
propNames(
  g_propList
) -> lS_names/nil
```

**参数**：

- `g_propList`: 一个游离属性列表。

**Original**: A disembodied property list.

**返回值**：

- `lS_names`: 对应于列表中找到的每个属性名称的符号列表。

**Original**: A list of symbols corresponding to the names of each property found in the list.

**示例**：

```skill
n = ncons(nil)
n->one = 1
n->two = 2
propNames(n) -> (one two)
```

---

