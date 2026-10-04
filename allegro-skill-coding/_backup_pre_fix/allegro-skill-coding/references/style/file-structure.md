# Allegro SKILL (AXL) 代码规范 — 文件结构与头部规范

> 本章规范基于 Cadence SPB 17.4 官方示例代码（`D:/Cadence/SPB_17.4/share/pcb/examples/skill/`）的代码风格分析提炼而成。所有示例代码片段均保留原始文件路径。

---

## 1. 总体原则

**1.1** 文件应当具备清晰的结构层次，便于阅读者快速定位命令注册、主程序逻辑与支撑 API。  
*依据：官方示例中 `cline2shape.il`、`cns-design.il`、`axldbctvia.il` 等文件均遵循"头部分 → 命令注册/入口 → 主逻辑 → 支撑 API"的纵向排列。*

**1.2** 文件头部必须包含版权声明或功能说明注释，不得以裸代码开始。  
*依据：`axl_delete.il`、`axldbctvia.il`、`axlswap_comp.il`、`entertest.il` 等所有官方示例文件均以头部注释开始；仅 `show_element.il`、`menu.il`、`ashmeter.il` 等极短演示文件使用极简功能头，但仍保留功能说明。*

**1.3** 同一项目内的文件头部风格应当统一，避免在同一工具箱中混用多种版权头格式。  
*依据：官方示例目录中，`disclaimer.il` 提供了一套标准版权头模板，多个文件（`axldbctvia.il`、`read.il`、`axl_delete.il`、`axlswap_comp.il`、`entertest.il`）直接复用该模板或与其高度一致。*

---

## 2. 文件命名与扩展名

**2.1** SKILL 源代码文件必须使用 `.il` 扩展名；Allegro 表单定义文件必须使用 `.form` 扩展名。  
*依据：官方示例中所有 SKILL 代码文件均为 `.il`（如 `cline2shape.il`、`cns-design.il`、`axldbctvia.il`、`read.il`），表单文件为 `.form`（如 `acns_design.form`、`ashmeter.form`）。*

**2.2** 文件名应当使用小写字母，单词之间以下划线 `_` 连接；避免使用大写字母或连字符 `-` 作为单词分隔符。  
*依据：`change_net_on_vias.il`、`cline2shape.il`、`axlswap_comp.il`、`axldbctvia.il`、`axl_delete.il` 均使用小写+下划线格式；`cns-design.il` 使用连字符，但在 SKILL 社区中更推荐下划线以避免与运算符混淆。*

**2.3** 命令入口文件名应当与命令名保持语义对应，便于通过文件名快速识别功能。  
*依据：`cline2shape.il` 对应命令 `cline2shape`；`change_net_on_vias.il` 对应命令 `change_vianet`；`show_element.il` 对应命令 `myshow`。*

---

## 3. 文件头部注释规范

### 3.1 版权头（标准模板）

**3.1.1** 对于正式发布的 SKILL 代码，文件头部应当包含标准版权头，使用分号横线框定上下边界。  
*依据：来自 `D:/Cadence/SPB_17.4/share/pcb/examples/skill/disclaimer.il` 的模板写法，被 `axldbctvia.il`、`read.il`、`axl_delete.il` 等多个文件直接采用。*

```skill
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ; file.cc --
 ;
 ; Author --
 ;	Cadence Design Systems
 ;
 ; Function --
 ;	
 ; Copyright, 2007, Cadence Design Systems, Inc.
 ; No part of this file may be reproduced, stored in a retrieval system,
 ; or transmitted in any form or by any means --- electronic, mechanical,
 ; photocopying, recording, or otherwise --- without prior written permission
 ; of Cadence Design Systems, Inc.
 ;
 ; WARRANTY:
 ; NONE. NONE. NONE.
 ; Use all material in this code at your own risk.  Cadence Design Systems 
 ; makes no claims about any material in this archive.  These examples may
 ; not function or may only function in specific instances. We'd like to hear 
 ; what you think of our approach to this, and how we can improve it.
 ;
 ; RESTRICTIONS:
 ; All software contained within this archive is in the public domain or
 ; the author has given us permission for redistribution.  Some packages
 ; have explicit copyrights and notices concerning their redistribution.
 ; Please carefully read all documentation with any package on this tape.
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
```

**3.1.2** 版权头中的 `Author` 字段必须填写开发者或组织名称；`Function` 字段应当简述文件的主要用途。禁止留空 `Function` 字段。  
*依据：官方示例中 `Function` 字段在模板中为空，但实际工程文件应当填写，如 `axldbctvia.il` 在版权头后紧跟 `;; axldbctvia.il - axlDBCreateVia test driver` 作为功能补充。*

### 3.2 功能头（命令/工具文件）

**3.2.1** 对于命令型文件（注册 `axlCmdRegister` 的文件），头部应当包含命令名称、文件名、执行方式及免责声明。  
*依据：来自 `D:/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/cline2shape.il` 的写法。*

```skill
;###############################################################################
;                                                                              #
;                      Command: cline2shape                                    #
;                   Skill File: cline2shape.il                                 #
;               How To Execute: Command> cline2shape                           #
;                                                                              #
;  DISCLAIMER:                                                                 #
;       The user of this command assumes all responsibility and does not       #
;       hold Cadence Design Systems nor the author of this code for any        #
;       unwarranted results or problems due to the use of this code.           #
;                                                                              #
;       This is non-supported code and the user may modify it as needed.       #
;                                                                              #
;###############################################################################
```

**3.2.2** 功能头之后应当紧跟功能摘要说明，使用 `;` 行注释列出文件演示或实现的主要技术点。  
*依据：来自 `cline2shape.il` 的写法。*

```skill
; demostrates
;	1) style for an interactive command
;	2) use of the database tranasction APIs
;	3) two styles of undo/redo support
; Added undo support

;  Know Bug: Sometimes the program will not convert all cline segments but it 
;            will DELETE all segments.  Use at your OWN discretion!
;            Select Cancel or Undo before exiting the command to restore  
;            to original Clines.
```

### 3.3 极简功能头（短小程序/演示文件）

**3.3.1** 对于不足 50 行的演示或工具文件，允许使用极简功能头，但仍必须说明文件用途和任何外部依赖。  
*依据：来自 `D:/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/show_element.il` 与 `D:/Cadence/SPB_17.4/share/pcb/examples/skill/ui/ashmeter.il` 的写法。*

```skill
; This demostrates the following:
;	 - use of right mouse popups (RMB)
;	 - simple selection
;	 - use of the findfilter
```

```skill
; Demonstration of axlMeterCreate with callback function plus
;	user specified form file to add addition button
; also requires form file ashmeter.form in same directory
```

### 3.4 Doxygen 风格文档注释（可选）

**3.4.1** 对于需要提供 API 文档的大型模块，允许在版权头之后使用 `/* ... */` 块注释包裹 `NAME`、`SYNOPSIS` 等文档标签。  
*依据：来自 `D:/Cadence/SPB_17.4/share/pcb/examples/skill/cmds/cns-design.il` 的写法。*

```skill
/*---------------------------------------------------------------------*/
/*-
#ifdef DOC_C
 NAME
	AcnsDesignDoc - design constraint UI form and AXL Interface
 SYNOPSIS
	This is the interface for the design constraint UI form. To
	add new items do the following:

	As of PSD15.1 this offers the same functionality as the
	Allegro cns design command
#endif
**/
```

---

## 4. 文件结构组织顺序

**4.1** 文件应当按照以下顺序组织内容，不得随意打乱：

1. 版权头 / 功能头注释
2. 外部依赖声明（如有）
3. 命令注册（`axlCmdRegister`）——仅限交互式命令文件
4. 主程序（入口函数）
5. 辅助函数 / 支撑 API（按调用顺序或逻辑分组排列）

*依据：`cline2shape.il` 严格遵循此顺序：功能头 → `axlCmdRegister` → 主 procedure `LCB_cline_to_shape` → 支撑 API `LCB_Setup`、`LCB_Oops`、`LCB_Cancel`、`LCB_Done`；`entertest.il` 遵循：版权头 → 函数定义 → 底部 `axlCmdRegister`。*

**4.2** 命令注册语句（`axlCmdRegister`）应当放置在文件前部（功能头之后、主程序之前），或放置在主程序定义之后、文件尾部；同一文件内的多条命令注册应当集中放置。  
*依据：`cline2shape.il` 将两条 `axlCmdRegister` 集中放在第 30~33 行，位于功能头之后、主程序之前；`entertest.il` 将 `axlCmdRegister` 放在文件底部第 41~43 行，位于所有函数定义之后。两种风格均被官方示例接受，但应当统一。*

**4.3** 主程序与支撑 API 之间应当使用明显的区块分隔注释。  
*依据：来自 `cline2shape.il` 的写法，使用 `;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;` 分隔主程序与支撑 API。*

```skill
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; support APIs

procedure(LCB_Setup()
...
```

**4.4** 支撑 API 应当按照调用顺序或功能模块分组排列，避免将主程序逻辑淹没在大量辅助函数中。  
*依据：`cline2shape.il` 将 `LCB_Setup`、`LCB_Oops`、`LCB_Cancel`、`LCB_Done` 等支撑 API 集中在主程序之后；`cns-design.il` 将表单回调、刷新、验证、提交等函数按功能分组排列。*

---

## 5. 注释与空行规范

**5.1** 行注释必须使用单个分号 `;`，缩进行注释可使用双分号 `;;` 以区别于代码尾部注释。  
*依据：`cns-design.il` 中大量使用 `;;` 作为缩进的说明注释（如 `;; GENERAL FORM PROGRAMMING METHOD`、`;; Good pratice`），而代码行右侧的简短注释使用单分号 `;`（如 `fw->_change = t	; force apply to be disabled`）。*

**5.2** 函数之间应当至少保留一个空行；逻辑区块之间推荐保留两个空行或使用横线注释分隔。  
*依据：`cline2shape.il` 中 `procedure` 之间均有空行；`read.il` 中每个 `defun` 之间使用空行分隔，并在函数前使用 `;;` 标题注释。*

**5.3** 在 `defun` 或 `procedure` 的闭合括号 `)` 之后，允许添加尾注释标注函数名，以增强长函数的可读性。  
*依据：来自 `D:/Cadence/SPB_17.4/share/pcb/examples/skill/dbread/read.il` 的写法。*

```skill
(defun print_title (string port)
    (fprintf port "\n\n%s\n\n" string)
) ; defun print_title

(defun test_a_symdef (p)
    (let (dsn sdf child)
        ...
    ) ; test_a_symdef
) ; defun test_a_symdef
```

**5.4** 禁止在行尾添加无意义的尾随空格；注释内容应当简洁，避免冗长。  
*依据：官方示例中注释长度适中，以说明"做什么"和"为什么"为主，而非"怎么做"。*

---

## 6. 文件依赖声明

**6.1** 如果文件依赖其他 SKILL 文件或外部资源（如 `.form` 文件、图片、数据文件），必须在版权头之后、代码逻辑之前使用显式注释声明依赖关系。  
*依据：来自 `D:/Cadence/SPB_17.4/share/pcb/examples/skill/dbread/read.il` 的写法。*

```skill
;NOTE: requires files ../select/ashfindall.il and ../ash/ashprint.il
```

**6.2** 依赖声明应当包含相对路径或加载路径提示，便于使用者正确配置加载顺序。  
*依据：`read.il` 使用 `../select/ashfindall.il` 相对路径指明依赖文件位置；`ashmeter.il` 在功能头中注明 `also requires form file ashmeter.form in same directory`。*

---

## 7. 编码规范

**7.1** 含有中文注释的 `.il` 文件必须使用 **GBK 编码**保存，以确保在 Allegro PCB Editor 的 SKILL 解释器及文本界面中正确显示中文字符。  
*说明：Allegro 的 SKILL 环境在 Windows 平台上通常以系统本地编码（GBK/GB2312）处理字符串和注释。使用 UTF-8 无 BOM 编码可能导致中文注释在 Allegro 命令行或弹窗中显示为乱码。开发时应在编辑器中显式指定 GBK 编码保存。*

**7.2** 若文件纯为英文注释和代码，可使用 ASCII 编码或 UTF-8 无 BOM 编码，但禁止在文件开头添加 UTF-8 BOM 标记，以免 SKILL 解释器将 BOM 视为语法错误。  
*依据：官方示例文件（`disclaimer.il`、`cline2shape.il`、`read.il` 等）均为纯 ASCII 编码，无 BOM。*

**7.3** 字符串字面量中的中文内容同样受编码影响，应当确保与文件保存编码一致。  
*说明：在 `axlUIWPrint`、`axlMsgPut`、`sprintf` 等函数中输出中文字符串时，若文件编码与 Allegro 运行环境的编码不一致，将导致运行时乱码。*

---

## 附录：官方示例文件结构参考汇总

### A.1 标准版权头模板（`disclaimer.il`）

```skill
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ; Skill File
 ;
 ; Author --
 ;	Cadence Design Systems
 ;
 ; Function --
 ;
 ;	
 ; Copyright, 2007, Cadence Design Systems, Inc.
 ; No part of this file may be reproduced, stored in a retrieval system,
 ; or transmitted in any form or by any means --- electronic, mechanical,
 ; photocopying, recording, or otherwise --- without prior written permission
 ; of Cadence Design Systems, Inc.
 ;
 ; WARRANTY:
 ; NONE. NONE. NONE.
 ; Use all material in this code at your own risk.  Cadence Design Systems 
 ; makes no claims about any material in this archive.  These examples may
 ; not function or may only function in specific instances. We'd like to hear 
 ; what you think of our approach to this, and how we can improve it.
 ;
 ; RESTRICTIONS:
 ; All software contained within this archive is in the public domain or
 ; the author has given us permission for redistribution.  Some packages
 ; have explicit copyrights and notices concerning their redistribution.
 ; Please carefully read all documentation with any package on this tape.
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
```

### A.2 命令文件功能头 + 结构（`cline2shape.il`）

```skill
;###############################################################################
;                                                                              #
;                      Command: cline2shape                                    #
;                   Skill File: cline2shape.il                                 #
;               How To Execute: Command> cline2shape                           #
;                                                                              #
;  DISCLAIMER: ...                                                             #
;                                                                              #
;###############################################################################

; demostrates
;	1) style for an interactive command
;	2) use of the database tranasction APIs
;	3) two styles of undo/redo support
; Added undo support

;  Know Bug: ...

axlCmdRegister("cline2shape" 'LCB_cline_to_shape ?cmdType "interactive"
 ?doneCmd 'LCB_Done ?cancelCmd 'LCB_Cancel ?undo t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This shows undo where all of the conversions...

procedure(LCB_cline_to_shape()
let( (lclines layer polydbid )
  ...
))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; support APIs

procedure(LCB_Setup()
...
```

### A.3 依赖声明 + 尾注释（`read.il`）

```skill
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ; ...copyright header...
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;NOTE: requires files ../select/ashfindall.il and ../ash/ashprint.il

;;
;; print_title - function to print any string to the specified port
;;
(defun print_title (string port)
    (fprintf port "\n\n%s\n\n" string)
) ; defun print_title
```

### A.4 极简头部 + 尾部命令注册（`entertest.il`）

```skill
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ; ...copyright header...
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun enterTest ()
    (axlEnterPoint))

(defun enterTestDone ()
    (axlFinishEnterFun)
    (axlEnterPoint))

(defun enterTestCancel ()
    (axlCancelEnterFun))

(axlCmdRegister "entertest" 'enterTest ?cmdType "interactive"
				  ?doneCmd 'enterTestDone
				  ?cancelCmd 'enterTestCancel)
```

### A.5 Doxygen 风格文档头（`cns-design.il`）

```skill
;; Acnsdesign.il
;;	Form interface for design constraints
;;

/*---------------------------------------------------------------------*/
/*-
#ifdef DOC_C
 NAME
	AcnsDesignDoc - design constraint UI form and AXL Interface
 SYNOPSIS
	...
#endif
**/

; doing this prevents multiple instances of form from opening
unless(boundp('_AcDesignFw) _AcDesignFw = nil)

;----------------------------------------------------------------
;; GENERAL FORM PROGRAMMING METHOD
;; 		async form mode
;;
;; This is a good example on how to program a form.
;; 
procedure( AcnsDesignForm()
...
```

---

> **本章适用范围**：Allegro SKILL (AXL) 源码文件（`.il`）及表单定义文件（`.form`）。对于非 Cadence 官方发布的第三方 SKILL 库，建议在此基础上根据项目实际情况调整版权头内容，但应保持结构一致。
