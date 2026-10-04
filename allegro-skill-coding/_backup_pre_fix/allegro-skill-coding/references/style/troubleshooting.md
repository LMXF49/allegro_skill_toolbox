---
name: allegro-skill-troubleshooting
description: |
  Allegro SKILL (AXL) 常见运行时错误排查手册。当用户在加载、运行或集成第三方 SKILL 脚本时遇到报错（如语法错误、参数不匹配、未定义变量、编码乱码、加密文件、菜单注入失败、批量修改事故等），按本手册快速定位根因并修复。适用于审阅、重构或整合多来源 `.il` 文件的场景。
---

# Allegro SKILL 常见运行时错误排查

> 版本：v1.1 | 基于实际集成 800+ 第三方 `.il` 文件的调试经验 | 编码：GBK（中文注释）

## 使用场景

- 加载 `.il` 文件时 Allegro Command 窗口报错
- 调用自定义命令时提示参数错误或函数未定义
- 中文菜单/提示显示乱码
- 从网络/论坛下载的 `.il` 无法运行
- 整合多个来源的 SKILL 脚本后出现冲突
- 用脚本/正则批量修改 `.il` 文件后出现大面积加载错误

---

## 一、语法类错误

### 1.1 `*Error* eval: unbound variable - else`

**根因**：SKILL 的 `when` 是单分支宏，不支持 `else` 子句。代码中写了 `when(condition ... else ...)` 或嵌套了 `else`。

**修复**：
```skill
;; 错误
(when(condition
  action1
  else action2))   ;; ← 非法

;; 正确：双分支用 if/then/else
(if(condition then action1 else action2))

;; 正确：多分支用 cond
(cond
  (condition1 action1)
  (condition2 action2)
  (t defaultAction))
```

**排查技巧**：用 `grep -n "else" file.il` 快速定位所有 `else` 出现的位置，确认其是否处于 `if`/`cond`/`prog` 的合法上下文中。

---

### 1.2 `SYNTAX ERROR found at line X column Y`

**常见根因**：
| 现象 | 根因 | 修复 |
|------|------|------|
| 引号不匹配 | 字符串中的 `"` 未转义，或 `'` 与 `` ` `` 混用 | 字符串内 `"` → `\"`；符号引用用 `'` 或 `` ` `` |
| 括号不匹配 | 多余或缺失的 `)` | 用编辑器括号匹配检查；SKILL 不支持 `}`/`]` |
| 非法字符 | 中文字符出现在代码关键字位置 | 中文只能出现在注释和字符串中 |
| 列表定义错误 | 列表项之间缺少空格或分隔符 | `'(a b c)` 而非 `'(a,b,c)` |

**排查技巧**：Allegro 报错会指出具体行列。若行列号指向空行，通常是上一行的括号未闭合导致解析器错位。

---

### 1.3 `*Error* load: password required for reading file`

**根因**：该 `.il` 文件被加密或编译为二进制格式（`.il` 扩展名但内容不是明文 SKILL 代码）。常见于从商业工具包或论坛下载的受保护脚本。

**处理方案**：
1. 若拥有密码：在 Allegro 中执行 `load("file.il" "password")`
2. 若无密码：联系文件提供方获取解密版本
3. 若用于整合：跳过该文件，在 `_stubs.il` 中保留空壳函数避免菜单引用报错

```skill
;; 占位 stub，避免菜单引用缺失函数
procedure( EncryptedFunc()
  axlUIWPrint(nil "WARNING: EncryptedFunc() is not available (file requires password).")
)
```

---

### 1.4 `*Error* procedure: illegal formal list - <name>`

**根因**：`procedure`/`defun` 的形式参数列表非法。最常见的是旧式**带外层括号**的写法。

```skill
;; ❌ 错误：旧式写法，procedure 被外层括号包裹（Allegro 17.x 报 illegal formal list）
(procedure check_text_overlap ()
  ...)

;; ✅ 正确：procedure( name() ... )，无外层括号
procedure( check_text_overlap ()
  ...)
```

**排查技巧**：该错误常与 `parseString: argument #1 ... "SSg" - (nil)` **成对出现**——此时根因就是 `procedure` 语法本身，不要去查 `parseString` 的调用点。修复 formal list 后两个错误一起消失。

---

### 1.5 `*WARNING* (reader): a '(' at line X was still unclosed on EOF, ')' added`

**根因**：文件括号不平衡——第 X 行的 `(` 到文件末尾仍未闭合，Allegro 读取器自动补全。文件看似"能加载"，但结构已损坏，后续函数定义可能被吞进前一个函数体，引发难以追踪的 `undefined function` 或逻辑错误。

**修复**：
1. 跳到行号 X，向下做括号配平（用编辑器括号匹配功能）
2. 常见诱因：批量正则替换误删/误增 `)`；全角括号 `（）` 干扰人工计数
3. 修复后重新加载，确认警告消失

---

## 二、命令注册与调用错误

### 2.1 `*Error* Etch_LayerView: too few arguments (1 expected, 0 given)`

**根因**：命令注册为 `?cmdType "general"`（或直接省略），但函数定义需要参数。用户在 Allegro 命令行直接输入命令名时不带参数。

**修复方案**：

**方案 A** — 改为交互式命令，内部通过 `axlEnterString`/`axlSelect` 获取参数：
```skill
axlCmdRegister("L" 'Etch_LayerView ?cmdType "interactive")
procedure(Etch_LayerView()
  let((layerNum)
    layerNum = axlEnterString("Enter layer number(s): ")
    ;; ... 处理 layerNum
  ))
```

**方案 B** — 保留 general 类型，提供 wrapper 无参函数：
```skill
;; 原始函数保留参数
procedure(Etch_LayerView(layerNum)
  ;; ...
)

;; 注册无参 wrapper 供菜单调用
procedure(ASTB_Etch_LayerView()
  let((input)
    input = axlEnterString("Enter layer number(s): ")
    Etch_LayerView(input)
  ))
axlCmdRegister("L" 'ASTB_Etch_LayerView)
```

---

### 2.2 `Command not found: XXX`

**根因**：命令已注册但函数未定义，或函数定义在命令注册之后且加载顺序错误。

**排查清单**：
1. 检查 `axlCmdRegister` 中的函数名是否与 `procedure`/`defun` 定义完全一致（大小写敏感）
2. 确认函数定义在 `axlCmdRegister` 调用之前，或已提前 `declare`/`load` 依赖文件
3. 检查 `.il` 文件是否实际被 `load`（路径错误、文件名拼写、文件不存在）

```skill
;; 正确顺序：先定义，后注册
procedure(MyCommand() ...)
axlCmdRegister("mycmd" 'MyCommand)

;; 错误顺序：注册时 MyCommand 尚未定义
axlCmdRegister("mycmd" 'MyCommand)  ;; ← 可能找不到
procedure(MyCommand() ...)
```

---

### 2.3 `*Error* eval: undefined function - XXX`

**根因**：函数被调用但未定义，或定义在其他文件中未加载。

**常见场景**：
- 第三方脚本依赖了作者本地的工具函数（如 `stringTrim`）
- 整合时遗漏了依赖文件
- 函数名拼写不一致

**修复**：
1. 搜索所有 `.il` 文件确认函数定义位置：`grep -r "procedure( stringTrim" G:/allegro/`
2. 若函数确实不存在，补充实现或替换为标准 SKILL 函数

```skill
;; stringTrim 不存在时的替代实现
procedure(stringTrim(str)
  let((start end)
    start = 0
    end = strlen(str)
    while(and(lessp start end) member(nth(start str) '(\s \t \n \r))
      start++
    )
    while(and(lessp start end) member(nth(sub1(end) str) '(\s \t \n \r))
      end--
    )
    substring(str add1(start) end)
  ))
```

---

### 2.4 `*Error* eval: unbound variable - \'FuncName`（反斜杠引号污染）

**典型报错**：
```
*Error* eval: unbound variable - \'Check_No_Refdes
*Error* load: error while loading file - "...05_FanySkill_check_no_refdes.il" at line 13
```

**根因**：`axlCmdRegister` 行中的 quote 被污染——文件里实际写的是 `\'FuncName`（反斜杠+单引号）甚至 `\\'FuncName`，而不是 `'FuncName`。Allegro 把 `\'FuncName` 整体当成一个变量名求值，于是报 unbound variable。**最常见诱因是用 Python/sed 正则批量修改 `axlCmdRegister` 行（如批量补 `?undo t`）时转义处理错误。**

**排查**：
1. 用字节级查看确认：`od -c file.il | grep "\\\\"` 或在 VS Code 中搜索 `\'`
2. 肉眼在正常文本编辑器里常分不清 `'FuncName` 与 `\'FuncName`，必须看字节

**修复**：
```skill
;; ❌ 错误（批量替换事故产物）
axlCmdRegister("Check_No_Refdes" \'Check_No_Refdes ?undo t)
axlCmdRegister("Check_No_Refdes" \\'Check_No_Refdes ?undo t)

;; ✅ 正确
axlCmdRegister("Check_No_Refdes" 'Check_No_Refdes ?undo t)
```

批量修复后务必在 Allegro 中重新加载验证，并检查是否还有连带的多余 `)`（见 1.5）。

---

### 2.5 `*Error* eval: undefined function - axlSetFunKey`（快捷键绑定 API）

**根因**：函数名拼写或版本可用性问题。`axlSetFunKey` 在 Allegro 17.4 中不存在。

**处理**：
1. 先在目标版本的 AXL 参考中确认正确的函数名（注意大小写，如 `axlSetFunckey`），不要凭记忆拼写
2. 若 AXL 函数不可用，改用 env 机制：
   ```skill
   ;; 方案 A：通过 axlShell 执行 funckey 命令
   axlShell("funckey d delete")
   ;; 方案 B：写入用户 env 文件（alias / funckey 行），重启或 source 后生效
   ```
3. 键序列（如 `jv` 两段式）通常只能写 env 文件，AXL 函数不一定支持

---

## 三、参数与类型错误

### 3.1 `*Error* parseString: argument #1 should be either a string or a symbol (type template = "SSg") - (nil)`

**根因**：向 `parseString` 传入了 `nil` 而非字符串。常见于用户输入取消、文件读取失败、或表单字段未初始化时直接使用。

**修复**：
```skill
;; 错误：未检查输入是否有效
input = axlEnterString("Prompt: ")
parsed = parseString(input)  ;; ← 若用户按 Esc，input = nil

;; 正确：先检查非空
input = axlEnterString("Prompt: ")
when(input
  parsed = parseString(input)
  ;; ... 处理 parsed
)
```

**注意**：若该错误与 `illegal formal list` 同时出现，根因是 `procedure` 语法（见 1.4），与 `parseString` 调用点无关。

---

### 3.2 `*Error* fprintf/sprintf: format spec. incompatible with data`

**根因**：`sprintf`/`fprintf` 的格式字符串与传入参数类型不匹配。常见于 `%s` 对应 `nil`、`%d` 对应字符串、或参数数量不足。

**修复**：
```skill
;; 错误：layerName 可能为 nil
sprintf(nil "Layer: %s" layerName)

;; 正确：提供默认值或使用条件格式化
sprintf(nil "Layer: %s" (or layerName "UNKNOWN"))
;; 或
when(layerName
  sprintf(nil "Layer: %s" layerName)
)
```

**常见格式对照**：
| 格式符 | 适用类型 | 注意 |
|--------|---------|------|
| `%s` | 字符串、符号 | `nil` 会报错，需先用 `or` 转 `"nil"` |
| `%d` | 整数 | 浮点数需用 `%f` |
| `%f` | 浮点数 | 可用 `%.2f` 控制精度 |
| `%L` | 列表 | 打印整个列表内容 |
| `%n` | 换行 |  Allegro 消息中常用 |

---

### 3.3 `*Error* makeTable: argument #1 should be either a string or a symbol (type template = "Sgx") - nil`（报错位置具有误导性）

**典型场景**：报错的 `makeTable` 行本身写法完全正确（且与能正常加载的参考文件逐字节一致），但 Allegro 仍报 argument #1 为 nil。

**根因**：**真正的问题在该行之前**——文件前面的代码存在括号/引号不平衡（常见于批量正则修改事故），导致解析器状态错乱，把 `makeTable` 的第一个参数解析成了 `nil`。报错行号是无辜的。

**排查步骤**：
1. 不要反复修改 `makeTable` 这一行本身
2. 从文件头开始检查括号配平和 quote 字符（重点：`axlCmdRegister` 行、文件头注释之后的第一段代码）
3. 与能正常加载的原始文件做 diff，定位被改坏的位置
4. 修复前面的语法问题后，`makeTable` 错误自动消失

---

## 四、编码与显示错误

### 4.1 中文乱码

**根因**：`.il` 文件以 UTF-8 编码保存，但 Allegro SKILL 解释器（Windows 中文版）默认使用 GBK 编码解析。

**修复**：
1. 用文本编辑器（VS Code / Notepad++）将文件编码改为 **GBK**（或 GB2312）后保存
2. 确保 `labels_raw.dat` 等外部中文资源文件同样使用 GBK
3. 若必须保留 UTF-8，则中文内容只能放在外部文件中通过 `infile` 读取，且读取时 Allegro 环境需支持 UTF-8（不推荐）

**批量转换脚本**（PowerShell）：
```powershell
Get-ChildItem *.il -Recurse | ForEach-Object {
    $content = Get-Content $_.FullName -Raw -Encoding UTF8
    Set-Content $_.FullName -Value $content -Encoding Default  # Default = ANSI/GBK on Chinese Windows
}
```

---

### 4.2 `*Error* load: error while loading file - "XXX.il" at line N`

**根因**：文件存在语法错误，Allegro 解析器在指定行失败。

**排查步骤**：
1. 用 Allegro 报错的行列号定位问题
2. 检查该行及前 3 行的括号平衡、引号闭合
3. 若前一行末尾缺少 `)`，报错行列号可能指向下一行的第一个字符
4. 用最小化测试：单独 `load("file.il")` 确认，排除其他文件的干扰

---

## 五、菜单与 UI 错误

### 5.1 `*Error* eval: undefined function - ASTB_RegisterAllMenuCommands`

**根因**：菜单注册函数的调用时机早于函数定义，或 `menu.il` 加载失败导致函数未定义。

**修复**：
```skill
;; 在 allegro.ilinit 中确保加载顺序正确
load("core/menu.il")           ;; 先加载菜单定义
load("core/_stubs.il")         ;; 再加载命令桩
axlTriggerSet('menu 'MyMenuTrigger)  ;; 最后注册触发器

;; menu.il 中应包含
procedure(ASTB_RegisterAllMenuCommands()
  ;; ... 菜单注册逻辑
)
```

---

### 5.2 菜单项不显示或命令无响应

**排查清单**：
1. `axlUIMenuInsert`/`axlUIMenuRegister` 的锚点是否找到？检查返回值
2. 命令字符串中若含双引号，是否正确转义 `"` → `\"`
3. 菜单触发器 `axlTriggerSet` 是否在 `allegro.ilinit` 中调用，而非直接在 `.il` 文件加载时
4. 菜单标签的中文是否使用 GBK 编码

```skill
;; 调试：打印菜单注册结果
res = axlUIMenuRegister("reports" menuList 'bottom)
printf("Menu register result: %L\n" res)
when(null(res)
  axlUIWPrint(nil "ERROR: Menu registration failed!")
)
```

---

## 六、整合第三方脚本的通用检查清单

当将多个来源的 `.il` 文件整合到统一工具箱时，按以下清单逐项检查：

| 检查项 | 方法 | 工具 |
|--------|------|------|
| 加密文件 | 用文本编辑器打开，查看是否为乱码/二进制 | VS Code, Notepad++ |
| GBK 编码 | 查看文件编码，含中文必须 GBK | VS Code 状态栏 |
| 函数重名 | `grep -r "procedure( XXX"` 搜索重复定义 | grep / ripgrep |
| 缺失依赖 | 搜索未定义函数名是否在其他文件中 | grep |
| `when`+`else` | `grep -n "else" file.il` 检查上下文 | grep |
| 命令注册冲突 | 检查多个文件是否注册同名命令 | grep "axlCmdRegister" |
| 参数不匹配 | 对比 `axlCmdRegister` 与 `procedure` 签名 | 人工审查 |

---

## 七、批量正则修改 `.il` 文件的安全守则

实际事故复盘：用 Python/正则批量给几十上百个 `.il` 文件的 `axlCmdRegister` 补 `?undo t`，结果产生了三类大面积损坏——

| 事故类型 | 现象 | 对应报错 |
|----------|------|----------|
| quote 被转义污染 | `'` 变成 `\'` 或 `\\'` | `unbound variable - \'FuncName`（见 2.4） |
| 括号增删错位 | 行尾多/少 `)` | `SYNTAX ERROR`（见 1.2）、`unclosed '('`（见 1.5） |
| 行结构被破坏 | 注册行被截断或合并 | `makeTable ... - nil` 等误导性报错（见 3.3） |

**安全守则**：

1. **先备份再批量改**：批量修改前 `cp -r modules modules_backup_YYYYMMDD`，或确保 Git 可回滚
2. **正则不碰 quote**：匹配 `axlCmdRegister` 行时，替换串中不得引入 `\` 紧邻 `'`；Python 中用原始字符串并先在 2-3 个文件上试跑
3. **逐文件验证**：批量改完后立即
   - `grep -rn "\\\\'" modules/` 检查反斜杠引号残留
   - 逐文件括号配平抽查（重点是被改行）
   - 在 Allegro 中重新全量加载，收集报错清单再逐一修复
4. **优先框架封装**：要批量加 `?undo t` 这类横切能力，更好的做法是改 `ASTB_RegisterCommand` 这一处封装（默认 `undo=t`），而不是改几百个调用点
5. **报错行≠问题行**：批量事故后的报错位置经常是误导的（见 3.3），从最早报错的文件和文件头开始查

---

## 八、快速诊断流程

```
用户贴出报错
    │
    ├─ 含 "syntax error" / "unbound variable" / "too few arguments"
    │   → 读取本文件「一、语法类错误」和「二、命令注册错误」
    │   → 若 unbound variable 的变量名以 \' 开头 → 直接看「2.4 反斜杠引号污染」
    │
    ├─ 含 "illegal formal list"（常伴 parseString "SSg"）
    │   → 「1.4」procedure 旧式括号语法
    │
    ├─ 含 "undefined function"
    │   → 「2.3」搜索依赖 → 补 stub 或替换
    │   → 若是 axl 开头的官方函数 → 「2.5」函数名/版本可用性
    │
    ├─ 含 "format spec" / "parseString" / "incompatible" / "makeTable"
    │   → 「三、参数与类型错误」；makeTable 报错先查文件前面的括号/引号（3.3）
    │
    ├─ 含 "password required" / "load: error"
    │   → 「1.3 加密文件」和「四、编码错误」
    │
    ├─ 含 "乱码" / 中文显示异常
    │   → 「4.1 中文乱码」→ 转换 GBK
    │
    ├─ 批量修改后大面积报错
    │   → 「七、批量正则修改安全守则」按事故类型逐一排查
    │
    └─ 菜单不显示 / 命令无响应
        → 「五、菜单与 UI 错误」
```

---

> **相关参考**：`references/error-handling.md`（防御性编码）、`references/command-registration.md`（命令注册规范）、`SKILL.md` 第 9 节「撤销支持规范」（`?undo t` 与事务封装）
