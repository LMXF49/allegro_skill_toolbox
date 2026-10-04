# Allegro SKILL 实机踩坑手册（Practical Pitfalls）

> 来源：2026-07 ASTB 工具箱整合 layer_view / utf8_skill_loader / 按页摆放，
> 及 2026-07-19/20 gbs（Gerber 一键输出）与 ach（添加中文）攻坚期间的
> Allegro 17.4 实机联调记录。每条都是"实机报错 → 手册查证 → 修复验证"的闭环，
> 并附工具箱内可对照的实证文件。生成/审查交互式命令、层视图、文本/图形创建、
> 外部进程调用、制造输出代码时**必读**。

---

## 1. 层与视图

### 1.1 层名 class 部分必须用"数据库内部带空格形式"（最高频坑）

**症状**：`axlVisibleLayer` 调用不报错，但层就是不显示；同一列表里只有 PIN 层生效。

**根因**：class 名写成下划线形式（`BOARD_GEOMETRY`、`VIA_CLASS` …）。Allegro
数据库内部 class 名**带空格**，写错时 `axlVisibleLayer` **静默失效**（返回 nil，无报错）。

| 错误（下划线） | 正确（数据库内部名） |
|----------------|----------------------|
| `BOARD_GEOMETRY/OUTLINE` | `BOARD GEOMETRY/OUTLINE` |
| `PACKAGE_GEOMETRY/SILKSCREEN_TOP` | `PACKAGE GEOMETRY/SILKSCREEN_TOP` |
| `REFDES/SILKSCREEN_TOP` | `REF DES/SILKSCREEN_TOP` |
| `VIA_CLASS/TOP` | `VIA CLASS/TOP` |
| `ETCH/TOP`、`PIN/TOP` | 无空格，两种写法里都对 |

**实证**：`text_checkreforient.il`、`via_stitching.il`（`strcat("VIA CLASS/" layer)`）、
`21_Quick_ExportARK.il`、`via_stackvias.il`。

**排查口诀**：某个层"设置了可见却没显示"，先查 class 名是否该带空格；对象
`dbid->layer` 返回的永远是带空格形式，直接对照即可。

### 1.2 axlVisibleLayer 参数顺序：层名在前，开关在后

```skill
axlVisibleLayer("ETCH/TOP" t)        ; 正确
axlVisibleLayer(t "ETCH/TOP")        ; 错误（AI 生成代码常见）
```

### 1.3 臆造 API 三件套（AI 生成层视图代码高频出现）

| 臆造（不存在/已废弃） | 正确替代 | 实证 |
|------------------------|----------|------|
| `axlGetLayerList()` | `axlGetParam("paramLayerGroup:Etch")->groupMembers` 返回 subclass 列表（顺序 TOP→BOTTOM），拼 `sprintf(nil "ETCH/%s" sc)` | `02_etch_layerview.il` |
| `axlSetCurrentLayer(...)` | `axlDBControl('activeLayer "etch/top")`（Set?: Yes，大小写不敏感） | `pkg_createovalflash.il` |
| `axlUIRedraw()` | `axlVisibleUpdate(t)` | `02_etch_layerview.il` |

补充：`axlSetActiveLayer` / `axlGetActiveLayer` **手册标注已废弃**（虽暂可用），
新代码一律用 `axlDBControl('activeLayer ...)`；读取活动层：
`cadr(parseString(axlDBControl('activeLayer) "/"))`。

整体显隐用 `axlVisibleDesign(t/nil)`，改完统一 `axlVisibleUpdate(t)` 刷新，
比逐层循环 `axlVisibleLayer` 干净。

**铁律**：写层/视图代码前，先查 `allegro-skill-reference-zh` 的
`99_Alphabetical_List.md` 确认函数存在，再查对应章节确认参数顺序——AI 生成的
上游层视图代码（如 layer_view）曾一次踩中本表全部三条。

---

## 2. 交互命令（enterFun / popup / 右键菜单）

### 2.1 右键 Done/Cancel 退不出命令：doneCmd/cancelCmd 与 ?undo 警示

**症状**：交互命令（while + axlSingleSelectPoint/axlEnterPoint 循环）右键点
Done/Cancel 毫无反应，命令死在里面退不出。

**根因链**：
1. `axlCmdRegister(... ?cmdType "interactive")` 但没传 `?doneCmd`/`?cancelCmd`；
2. interactive 命令右键弹出的是 **Allegro 内建菜单**（Done/Cancel/Oops 顺序），
   不一定是你 `axlUIPopupSet` 的自定义菜单；
3. 手册（20_Command_Control）：`doneCmd/cancelCmd` 为 nil 时内建项默认只调
   `axlFinishEnterFun`/`axlCancelEnterFun`——解除拾取阻塞，但**不设置你的退出
   标志**，while 条件永远为真 → 死循环。

**正确写法**（规范 style_command-registration.md 5.2.2-1 的实证依据）：

```skill
axlCmdRegister("mycmd" 'MyCmd ?cmdType "interactive"
    ?doneCmd 'MyCmdDone ?cancelCmd 'MyCmdCancel)
```

- `?doneCmd/?cancelCmd` **仅对 interactive 有效**，general/sub_cmd 被忽略；
- **`axlCmdRegister` 没有 `?undo` 参数**（手册 p.954 签名仅
  `?cmdType/?doneCmd/?cancelCmd`）——多传 `?undo nil` 属非法关键字，
  加载期直接报错、文件加载中止（ach v2.9 实机踩坑：症状表现为旧版行为，
  因新版根本没加载上）；
- 注意：工具箱 9 个实证 popup 模块（place_align / via_stitching 等）
  **均未使用 doneCmd/cancelCmd**，主流做法是在 popup 字符串回调里调
  `axlFinishEnterFun()/axlCancelEnterFun()`（见 2.4）；doneCmd/cancelCmd
  手册虽支持（p.956 Example 1），但本机尚无实证，优先用 popup 回调模式；
- Done 回调模式：`_finish = t` → `errset(axlDBTransactionCommit(mark) t)` →
  `axlFinishEnterFun()`；Cancel 同理（Rollback + axlCancelEnterFun）。

### 2.2 popup 菜单标签禁用 GBK 中文："Invalid character"

**症状**：右键点"完成"，控制台报 `Invalid character`。

**根因**：`axlUIPopupDefine` 的菜单标签用了 GBK 中文（如 `("完成" myDone)`），
菜单选择处理路径触发 SKILL reader 读取，双字节字符报 reader 错误。

**正确写法**：标签一律英文，回调用 symbol（place_align 模式）或 ASCII 字符串
表达式（via_stitching 模式）：

```skill
mypopup = axlUIPopupDefine(nil
    (list (list "Done"   'myDone)
          (list "Oops"   'myOops)
          (list "Cancel" 'myCancel)))
```

**实证**：全工具箱 9 个 popup 模块（place_align / via_stitching /
route_cutlineshape / route_linetoshape / shape_changenet / pkg_exportpad /
place_movetogrid / 10_Rename_Ref_Des / route_auto10deg）标签 100% 英文。

### 2.3 axlEnterPoint 返回值必须 listp 防御

**症状**：`*Error* difference: can't handle (0.877 - nil)` 或 `car` 报错。

**根因**：enterFun 被 `axlFinishEnterFun`/`axlCancelEnterFun` 解除后返回 nil/t
而非坐标点，直接 `car(pt)` 崩溃。

```skill
when(listp(pt = axlEnterPoint(?prompts '("...")))
    ; 只有拿到真坐标点才进分支
)
```

### 2.4 popup 回调里的事务调用包 errset

回调若在 `axlDBTransactionCommit/Rollback` 抛错处中断，后面的
`axlFinishEnterFun()` 执行不到 → 命令照样退不出。包裹后即使事务异常也能退出：

```skill
procedure( myDone()
    _finish = t
    errset(axlDBTransactionCommit(_mark) t)   ; errset 第二参 t = 出错也打印
    axlFinishEnterFun()
)
```

---

### 2.5 popup 实证模板（via_stitching 模式，form 回调上下文可用）

```skill
mypopup = axlUIPopupDefine(nil
    list(
        list("Done" "_done = t axlUIPopupSet(nil) axlFinishEnterFun()")
        list("Undo" "MyUndoLast()")     ; 不解除拾取，选完继续等下一点
    ))
axlUIPopupSet(mypopup)
org = axlEnterPoint(...)
while( org && !_done
    when( listp(org)  ...放置/处理... )
    axlUIPopupSet(mypopup)              ; 每次 enter 返回后重设（防菜单被吃掉）
    org = axlEnterPoint(...)
)
axlUIPopupSet(nil)
```

要点（全部实机验证）：
- 回调用 **ASCII 字符串表达式**（via_stitching 实证，form 回调上下文可用）；
  symbol 回调（place_align 实证）只在主过程上下文验证过，form 回调里优先字符串；
- Done 必须 `axlFinishEnterFun()` 解除拾取阻塞；Undo 等中间动作**不要**调
  Finish/Cancel——不调则 enter 保持等待，菜单选完自然继续循环；
- 每次 enter 返回后**重设 popup**；
- 循环条件 `org && !_done` 双保险（解除后 enter 可能返回 nil 或 t）；
- 菜单选择后若不是 Finish/Cancel 类回调，axlEnterPoint **不会返回**，
  不存在"菜单动作的 nil"需要区分。

实证：`text_addchinese.il` v3.0（ach 放置循环）。

### 2.6 撤销：事务不能跨命令，模块自维护 dbid 批次栈

- `axlDBTransaction*` 只在单次 SKILL 执行内有效（手册 p.854：SKILL 终止时
  活动事务被取消，明确说不能用来跨命令支持 undo）；Allegro 标准 Ctrl+Z 也
  不覆盖 AXL 创建的对象；
- 模式：各创建函数把新建 dbid cons 进全局 `_xxxLastBatch`，每次用户动作
  （一次点击/一次框选）作为一批压入 `_xxxPlaced` 栈；撤销 = 弹栈逐个
  `axlDeleteObject`（`errset(... nil)` 静默，失效 dbid 跳过）；另注册一个
  `xxxu` 命令，退出后仍可逐批撤销；
- dbid 收集点：`axlDBCreatePath` 返回值的 `(car)` 是 dbid **列表**；
  `axlDBCreateCloseShape` 返回值的 `(car)` 是单个 dbid。

实证：`text_addchinese.il` v2.8（achu 命令）。

**扩展（2026-07-26，rvia.il v1.7-v1.9 三轮实机）**：

- **跨命令存储的 dbid 会失效**（`dbid:removed`）：撤销时按存储 dbid
  `axlDeleteObject` 静默失败，出现"旧对象重建了、新对象没删掉"的重叠
  现场。**批次栈不要存 dbid，改存"定位信息"（位置 + 关键属性如焊盘名），
  撤销时现场 `axlSingleSelectPoint` + 属性比对拿到新鲜 dbid 再删**。
  **同样适用于表单回调**：拾取时存的 dbid 到表单回调上下文已失效
  （`axlPolyFromDB` 报 `dbid:removed`）——几何类需求在拾取完成时
  预取 r_poly/bBox（SKILL 侧数据不失效），回调只用它。
  实证：`route_padvoid.il` v1.1→v1.2。
- **重建类操作必须显式传网络名**：手册明确 `axlDBCreateVia` 不传
  `t_netName` 时创建的是**无网络独立孔**——撤销/重建路径先删后建，
  原位置已空，网络无从继承；删之前从存活对象取 `->net->name` 传入。
  （正向"先建后删"替换无此问题，新孔从重叠旧孔继承网络。）
- **本机 Ctrl+Z 实锤不覆盖 AXL 建/删对象**（17.4 S039）：与
  `core/trans.il` 的 `ASTB_DBTransactionMark` 注释预期相反——该封装
  在本机**不能**带来 Edit→Undo 能力，撤销只能靠模块自维护批次栈
  （`xxxu` 命令）。Ctrl+Z 语义后续若有版本差异再修正本条。

实证：`modules/via/rvia.il` v1.9（RVIA_Undo / RVIA_ReplaceBatch）。

### 2.7 动态光标预览（对象吸附鼠标）

手册 p.350 实证模式：`axlClearDynamics()` → 逐图元 `axlPathStart(相对坐标
点列)` → `axlAddSimpleMoveDynamics(原点 path "path" ?ref_point 原点)`。
动态缓冲**在显式 `axlClearDynamics` 前一直有效**，跨多次 `axlEnterPoint`
无需重载；Done/退出时必须 `axlClearDynamics()` 收尾。点仍用 `(x y)` 二维
表（本机拒 x:y 点对），原点单点用 `list(0.0 0.0)` 即可。加载调用包
`errset(... nil)` 并统计成功数——0 条只损失预览，不影响放置主流程。
实证：`text_addchinese.il` v3.2（ACH_LoadDynamics）。

### 2.8 右键 Done"点了不退出"的排查路径

**症状**：右键菜单里的 Done 点了没反应，命令行输 `done` 却能退出。

**机制**：命令行 `done` 走 enter 函数内建通道，与 popup 无关；而右键弹的
可能是 **Allegro 默认 popup**（我们的 `axlUIPopupSet` 被对话框/状态切换
顶掉时）——默认 Done 依赖当前活动命令注册的 `?doneCmd`，表单类命令在
放置循环期间**没有活动命令**，默认 Done 就是死按钮。

**对策**：popup 回调字符串改调**命名函数**（如 `"ACH_DoneMark()"`），
函数内 `printf` 留痕 + `axlClearDynamics()` + 置标志 +
`axlFinishEnterFun()`。复测时凭留痕行即可分辨：有留痕 = 弹的是本工具
菜单（查 FinishEnterFun 链路），无留痕 = 弹的是默认菜单（查 popup 保持）。
实证：`text_addchinese.il` v3.2。

---

### 2.9 `axlUIPrompt` 是输入对话框，不是被动消息提示

**症状**：想给用户一行"现在请框选对象 / 处理完成"之类的状态提示，
用了 `axlUIPrompt`，结果屏幕中央弹出一个**带输入框的对话框**，
用户必须键入点什么（或取消）流程才能继续——明明只是想要一行字，
却变成一个挡路的弹窗。

**根因**：`axlUIPrompt(t_message [t_default]/'password)` 的语义是
**输入对话框**（手册 skill-guide 明确标注"输入对话框"）：它弹出带
输入框的对话框并**阻塞等待用户键入**，返回值是用户输入的字符串
（取消返回 nil）。它不是消息显示器。把它当状态提示用，就是把每个
提示都变成一次强制交互。

**正解对照表**（按"要不要用户回答"选）：

| 需求 | 正确 API | 弹窗？ | 阻塞？ | 返回 |
|------|----------|--------|--------|------|
| 被动状态提示（消息行） | `axlMsgPut(msg)` | 无 | 不阻塞 | — |
| 状态栏/窗口消息 | `axlUIWPrint(nil msg)` | 无 | 不阻塞 | — |
| 命令行滚动区文字 | `printf(...)` | 无 | 不阻塞 | — |
| 需要用户键入文本（如输入数值/名字） | `axlUIPrompt(msg [default])` | 输入对话框 | 阻塞等键入 | 字符串/nil |
| 需要用户确认一件事 | `axlUIConfirm(msg)` | 模态确认框 | 阻塞 | t |
| 需要是/否选择 | `axlUIYesNo(msg)` | 模态选择框 | 阻塞 | t/nil |

**参数个数陷阱**：`axlUIYesNo` **最多 3 参**（msg + 2 个可选），带变量
的格式串必须先 `sprintf` 预拼——直传 `axlUIYesNo(fmt a b c)` 报
`*Error* axlUIYesNo: too many arguments (at most 3 expected, 4 given)`，
确认框出不来、流程中断。`axlUIConfirm` 同理只收单条消息串。
实证：`via_samevia.il` v2.1（1922 个过孔替换确认框崩溃修复）。

**实证**：`place_packnet.il` v3.3→v3.4 全量 `axlUIPrompt`→`axlMsgPut`
（之前两步操作指引全弹成了输入框）；`x_move_screen.il` 用
`axlMsgPut("Arrow keys restored to default.")` 是无弹窗消息的范本；
`place_movetogrid.il`、`spchk.il` 里 `axlUIPrompt("请输入...")` 才是它的
正解用法（就是要用户输入）。

**排查口诀**：功能里"莫名多出一个弹窗/输入框"，先全局搜 `axlUIPrompt`；
反之，要用户输入时别拿 `axlMsgPut`（它是单向显示，拿不到输入）。

---

### 2.10 `axlUIWPrint` 传 `'error` 消息类符号 → 弹错误对话框

**症状**：提示消息照表单规范写成 `axlUIWPrint(nil 'error "焊盘加载失败")`，
实机却**弹出模态错误对话框**，用户要求"提示走命令行"怎么也压不住。

**根因**：`axlUIWPrint(r_window t_format ...)` 官方签名**没有消息类参数**，
消息类嵌在字符串前缀里（`\e` 错误 / `\t` 文本，见 `axlMsgPut`）。官方示例
`axlUIWPrint(fw 'error "%s" err)` 里的 `'error` 确实被当类符号接受，但
**error 类消息 Allegro 会以弹窗形式显示**，不是写到消息行。

**正确写法**：要不弹窗就不传类符号、纯文本（默认 `\t` 类，进命令行
消息区），级别用文字前缀表达：

```skill
axlUIWPrint(nil "ERROR: 焊盘加载失败")     ; 消息行纯文本，不弹窗
axlUIWPrint(nil "替换完成: 成功 3 / 共 3 个过孔")
```

**实证**：`modules/via/rvia.il` v1.1→v1.2（12 处 `'error`/`'info` 全删，
实机弹窗消失）。同一模块 v1.5 还踩了 2.9 的 `axlUIPrompt`——三个消息
API 的边界：`axlUIConfirm`=模态确认框、`axlUIPrompt`=输入对话框、
`axlUIWPrint(nil 纯文本)`=消息行，**要"提示走命令行"只用最后一个**。

### 2.11 大段帮助文本弹窗：`axlUIViewFileCreate`（临时文件 + 文件查看器）

**场景**：帮助/报表这类**多行长文本**要弹对话框显示（用户明确不要刷
命令行）。`axlUIConfirm`/`axlUIMsgBox` 无滚动、撑不下几十行；自建 .form
又太重。

**正确范式**（route_automatchgroup.il `_AMG_ShowHelp` 实证模板）：
内容写进 `axlTempFile()` 临时文件 → `axlUIViewFileCreate(file "标题" t)`
弹 Allegro 文件查看器 → 返回后即可 `deleteFile`（查看器已装载内容）：

```skill
f = axlTempFile()
p = outfile(f "w")
fprintf(p "帮助标题\n1. ...\n2. ...\n")
close(p)
ret = errset(axlUIViewFileCreate(f "窗口标题" t) t)
unless( and(ret car(ret))
  ;; 查看器不可用时回退：把同一文件逐行 axlUIWPrint 到命令行
)
deleteFile(f)
```

**配套做法**：帮助内容别硬编码进 .il——外置 GBK 数据文件（本项目
`core/help_map.dat`，`键|字段1|字段2|...` 每行一条，`;`/`#` 注释，
`ASTB_StringSplit` 解析），与 `labels_map.dat` 同一维护套路：加命令只
追加一行数据，不动代码。运行时按 `ASTB_GetMenuStructure` 顺序拼文本，
菜单增删帮助自动跟随。

**实证**：`modules/utilities/util_help.il` v1.0（命令行输出）→ v1.1
（按本范式改弹窗），`errset` 包裹查看器调用并留命令行回退路径。
16.6 部署注意：含中文的 fprintf 字符串随同步流程八进制转义即可
（ascillize 补丁覆盖本文件，90 处转义实机正常）。

### 2.12 统一撤销 astbundo + 系统撤销 ?undo 的版本分治

**架构**（core/trans.il v1.4+，废弃一功能一 `xxxu` 命令的散养模式）：

- 模块侧两处接线：加载时 `ASTB_RegisterUndo("tag" 'XXX_Undo)`；
  Done 批次成功入栈处 `ASTB_UndoJournalPush("tag")`。
- `astbundo` 命令（`ASTB_Undo`）按日志 **LIFO** 分发到对应模块的撤销
  函数；**先弹日志再执行**——撤销函数异常也不会卡死队列。
- **注册表用 `makeTable`，禁用 assoc**：assoc 对字符串键是身份比较，
  注册后永远查不到（报"模块 xxx 未注册撤销函数"，v1.5 实锤；menu.il
  标签表同模式）。

**系统撤销（Ctrl+Z / 编辑→撤销）的版本分治**
（`ASTB_CmdRegisterSafe`，core/version_adapter.il）：

- 17.4+：`axlCmdRegister(... ?undo t)` 全参数注册，AXL 建/删对象进系统
  撤销栈；16.6 不认 `?undo/?doneCmd/?cancelCmd` 关键字（每个命令刷一条
  `*Error* unrecognized keyword`）。**能力探测每会话只做一次**
  （`ASTB_FULLREG_OK`）：首次 errset 静默探测，失败置标志统一 WARN，
  后续全部裸注册。
- 24.1 实测：`?doneCmd nil`/`?cancelCmd nil` 带 nil 关键字会被拒——
  **nil 就不传对应关键字**，否则全参数注册失败连 `?undo` 一起丢。
- **撤销命令本身注册 `?undo nil`**（trans.il v1.6）：防系统撤销把
  撤销动作本身入栈（Ctrl+Z 撤销"撤销"成死循环）。

**撤销完整性两条实机教训**：

- 恢复必须还原**全部**被改属性：改线宽模块初版撤销只删新线，原线宽
  没改回来——批次记录的"旧状态"要覆盖操作触碰的每一个属性。
- 替换类撤销要**先删新建、再重建旧件**：rviau 初版只重建旧孔，新孔
  残留成重叠现场（配合 §2.6"批次存定位信息不存 dbid"修复）。

**实证**：core/trans.il v1.4-v1.6、version_adapter ASTB_CmdRegisterSafe、
rvia.il v1.10+、route_changelinewidth.il / route_linetoshape.il 撤销修复
（2026-08-20 前后三轮实机）。

### 2.13 菜单防重载：清场式去重（purge-then-insert），不要"存在就跳过"

**参照**：D:/FanySkill `FYEnhanceMenu.il` 的 `DH_FYUpdateMenu`——注入前
`axlUIMenuDump` 找出自己菜单的所有副本位置，逐个 `axlUIMenuFind(nil pos)`
+ `axlUIMenuDelete` 删干净，再整树插入；重复执行 N 次结果都是恰好一份。

**反面模式**："dump 检测到已注入 → skip"。半注入/旧结构残留永远修不好，
Reload 改菜单结构后旧项还赖着。

**落地**（core/menu.il v3.5，`ASTB_PurgeToolboxMenu`）：

- 注入快速通道只看会话内标志 `ASTB_MENU_INJECTED`（稳态零开销）；
- 标志为 nil（首次注入/自愈复位/Reload 复位）→ 先 purge 再插入：
  循环 { dump 判存 → 定位顶层 popup 位置 → Find+Delete }，**每轮重新
  dump 定位**（位置随删除漂移），上限 5 轮防死循环，删不干净就放弃
  注入保留现状（绝不制造重复）；
- `ASTB_Reload` 重置标志（main.il v2.2.9），Reload 才能真正结构化重建菜单；
- 定位判据用**菜单里独有的命令字符串**（ASTB_Reload/ASTB_About），
  别用顶层 popup 标题——标题可 i18n 切换，命令字符串恒定；
- `axlUIMenuDelete` 不认 `axlUIMenuInsert` 返回的嵌套 id（v2.1 实锤），
  必须走 `axlUIMenuFind(nil pos)` 拿的位置 id。

**实证**：24.1 桥内连注三次 1 份；人造重复副本 2→purge+inject→1
（2026-08-24）。

---


## 3. 文本对象（axlDBCreateText）

### 3.1 文本原点不要回读，直接用创建点

**症状**：移动刚创建的文本时报 `(x - nil)`，或原点拿到 nil。

**根因**：
- `axlDBAltOrigin('center)` 对文本 dbid 返回 nil；
- `car(axlDBCreateText(...))` 的 dbid 经 `axlEraseObject` 进 dynamics 后，
  实机 `ret->xy` 读回 nil（17.4 实测）。

**正确写法**：文本本来就创建在入参 `pt` 上（`axlDBCreateText(str pt orient
layer nil)`），原点直接用 `pt`，零回读、零失效路径：

```skill
ret = car(axlDBCreateText(netName pt myorient layer nil))
axlEraseObject(ret)
axlDynamicsObject(ret pt)              ; 原点 = 创建点 pt
when(listp(ptPlace = axlEnterPoint(?prompts '("请点击选择文本放置点")))
    if( axlTransformObject(ret ?move
            list(car(ptPlace) - car(pt)  cadr(ptPlace) - cadr(pt)))
    then
        errset(axlDrawObject(ret) t)   ; 关键！见 3.2，否则文本隐形
    else
        errset(axlDrawObject(ret) t)   ; 移动失败(目标非法)：原位恢复显示
    )
)
```

另：delta 用显式 `list(car - car, cadr - cadr)`，别依赖 `axlMXYSub`（对 nil
输入只会 WARNING 后继续，错误被掩盖到下游才爆）。

### 3.2 被 axlEraseObject 擦除的对象，变换后 Allegro 不重画——必须 axlDrawObject

**症状**：erase→dynamics→axlEnterPoint→axlTransformObject 的拖拽放置链路，
移动放置后文本不可见；"偶尔能放"（其实是 SKILL 程序退出时被系统恢复可见），
快速原地双击则正常。

**根因**（17.4 桥内实锤，2026-08-24）：
- `axlTransformObject` 对被 `axlEraseObject` 擦除的对象**变换成功但不重画**
  （返回值 t，随后 `axlDrawObject` 返回 t 证明仍处于擦除态）；
- 擦除态对象要等"SKILL 程序终止/回 AXL shell"才被系统恢复可见
  （axlEraseObject 文档原话），于是用户以为"没放下"，库里却攒了一堆隐形文本；
- 快速双击 delta≈0 时观感正常，是因为退出命令时文本恰好显示在拾取点上。

**修法**：变换成功后立即 `errset(axlDrawObject(ret) t)` 显式重画；
变换失败（目标点非法，返回 nil）和放弃放置（axlEnterPoint 返回 nil）
两条分支也各补一次 axlDrawObject 恢复显示+命令行告警。
参照 text_addnetname.il v1.11。

---

## 4. 语言层面

### 4.1 `t` 是保留字，不能作形参

```skill
mapcar(lambda((t) atoi(t)) tokens)      ; *Error* lambda: t is reserved
mapcar(lambda((tok) atoi(tok)) tokens)  ; 正确
```

### 4.2 car(axlDBCreateText(...)) 的返回结构

`axlDBCreateText` 返回 `(t_dbid)` 或 nil，取 dbid 用 `car(...)` 并**判空**后再用；
创建失败（层不可见、block 号非法等）返回 nil，直接 `->` 会静默传 nil 到下游。

### 4.3 cons 不能构造 x:y 点对（浮点第二参报错）

`cons(14.34 120.5)` → `*Error* cons: argument #2 should be a list`。手册示例
`9150:4450` 是**读入期字面量**，不经 cons。确实需要点对时用 `rplacd`：

```skill
cell = list(x nil)
rplacd(cell y)    ; => (x . y)，即 x:y
```

但先查 5.1：本机几何函数要的是 `(x y)` 二维表，通常根本不需要构造点对。
实证：`text_addchinese.il` v2.4/v2.5。

### 4.4 prog/errset 返回大结构随机丢失 → 全局通道

实机现象：被调函数内 `length(glyphs)=1`，调用方经 `prog`/`errset` 收到的
却是 nil；同一结构换一跳又碰巧存活（GC 风格随机）。**凡跨函数传递大列表，
一律写全局变量通道（`_xxxResult = data`），调用方读全局**，不依赖
prog/errset 返回值。实证：`text_addchinese.il` v1.9/v2.0/v2.2。

### 4.5 case 对 parseString 现切字符串不匹配 → if/equal

`case( recType ("G" ...) ("S" ...) )` 对 `car(parseString(line))` 的产物
不命中（疑似 case 的 eq 比较 vs 字符串身份）；改 `if( equal(recType "G") ... )`。
注意表单回调里 `case( fw->curField ... )` 却正常——仅对 parseString 产物换。
实证：`text_addchinese.il` v1.8。

### 4.6 特殊形式括号必须紧跟关键字

`cond` 与左括号分行书写 → `*Error* eval: unbound variable - cond`（被当变量
引用）。`cond(`、`if(`、`when(`、`case(` 等一律连写。实证：`text_addchinese.il` v2.1。

### 4.7 `return` 只能在 `prog` 内使用

`*Error* return: return can only be used within a prog`——procedure/let/foreach
里直接 `return(...)` 报错；函数需要中途返回时整体包
`prog((...) ... return(x) ...)`，或改用 if/else 链。
实证：`mfg_gerbersetup.il` v2.0（5 个函数中途返回全部收敛进 prog）。

**扩展（2026-08-01，静默半截死型）**：无 `prog` 的 `return` **不阻碍加载**，
函数甚至能正常执行到 `return` 那一行才抛错——典型症状是**前置探针有输出、
后置探针失踪，调用者的后续动作整体不发生**（本次表现为表单回调里
`_AMG_BusName` 打印后死亡，于是 `_AMG_AutoName` 的打印和外围的
`axlFormSetField` 全都不执行，组名永不更新，Create 也死在取名字这步；
`*Error*` 混在调试输出里极易被忽略）。排查定式："前面的 printf 出现、
后面的 printf 消失" → 先查函数体内 `return` 是否缺 `prog`。
全文件审计两条 grep 行号比对即可：`grep -n "return(" f.il` 对照
`grep -n "^procedure(\|prog((" f.il`，凡含 `return` 而函数体无 `prog`
者即病灶。
实证：`route_automatchgroup.il`（`_AMG_BusName` 是全文件唯一无 `prog` 的
`return`，去掉 `return` 改末值返回后 AutoName 拼名与 Create 全部恢复）。

### 4.8 `==` / `!=` 是身份比较，字符串必须 `equal`

`==` 比较的是对象身份（指针），两个内容相同的字符串未必 `==`；字符串/列表
内容比较一律 `equal`（数字比较可用 `==`）。
实证：`mfg_gerbersetup.il` v2.0 一次修 9 处（IPC 版本判断、place_txt 归类等
全部因 `==` 失灵）。

**扩展（2026-07-26，高危潜伏型）**：`==` 对**单字符**字符串同样按同一性
判假——`ASTB_StringTrim` 用 `ch == " "` 判断空白，导致 trim 自项目创建起
**从未剥离任何字符**，CRLF 配置行的 `\r` 残留进 value 引发连锁污染
（`SetConfig` 把 `\r` 替换为空格 → 槽值变 `"en "` → `strcmp("en " "en")`
永假 → 菜单语言判定永远走默认分支）。trim/解析/比较类**基础工具函数**是
`==` 重灾区——它们失效时不报错，只是静默不工作，可潜伏数年。
实证：`utils.il` v1.3（StringTrim 8 处 `==` → `equal`）。

### 4.9 内联 `if` 表达式必须带 `then`

`if( c x else y )` → `*Error* if: too many arguments (missing then?)`；
正确写法 `if( c then x else y )`（then 不可省，即使单行表达式也一样）。
实证：`text_addchinese.il` v3.6（printf 实参里内联 if 漏 then，v3.6.1 修复）。

### 4.9 `let(())` 空绑定表是语法+运行双坑

`let(())` 触发 `PARSER WARNING: extra ')' ignored`，运行再报
`*Error* let: too few arguments`；绑定表至少要有一个变量，无局部变量时写
`let(nil ...)` 或去掉 let。
实证：`mfg_gerbersetup.il` v1.1（4 处）；`21_Quick_ExportARK.il` L800 同病（未修）。

### 4.10 无 `getenv`：环境变量用 `getShellEnvVar`

`*Error* eval: undefined function - getenv`——AXL SKILL 没有 C 式 getenv，
读环境变量用 `getShellEnvVar("NAME")`（不存在返回 nil）。
实证：`text_addchinese.il` ACH_GetPython 读取 ASTB_ACH_PYTHON。

### 4.10b 无 `break`/`continue`：循环退出用标志位或 prog+return

**症状**：`*Error* eval: unbound variable - break`，功能整体不可用。

**根因**：C 思维写循环——SKILL 没有 `break`/`continue`。内层循环提前
退出用**标志位**（`while( and(scanning ...) ...)`）或包 `prog` 用
`return` 直接出函数。AI 生成代码高发，`tools/astb_smoke.py` 检查 5
已加静态扫描（break/continue/getenv）。
实证：`util_colorpowernets.il` v1.1→v1.2（电压解析函数 break 修复）。

### 4.11 `errsetstring` 第一参是"表达式字符串"，不是表达式

**症状**：`*Error* errsetstring: argument #1 should be a string
(type template = "tgs") - t`，且因发生在外层 `errset` 内被二次误报为
其他错误（如每模块一条 LoadDir error），极具迷惑性。

**根因**：`errsetstring(load(path) t)`——实参先求值，`load` 执行完返回
`t`，等于调 `errsetstring(t t)`。**要加载/求值的目标必须拼成字符串**：

```skill
; 错误：表达式被先求值，返回值 t 被当成第一参
errsetstring(load(loadPath) t)
; 正确：第一参是表达式字符串，错误原文由第二参 t 打印
errsetstring(sprintf(nil "load(\"%s\")" loadPath) t)
```

返回值按 errset 语义是 `(结果)` 列表，成功判定用
`and(r listp(r) eq(car(r) t))` 并加 `listp` 防御。
实证：`core/loader.il` v1.4→v1.5（启动日志 76 条 *Error* 全部消失）。

### 4.12 `axlDesignType` 返回值大小写以实机为准（本机大写 "FLASH"）

**症状**：设计类型守卫 `member(axlDesignType(t) '("flash" "mechanical"))`
在 Flash 图面里也拒绝运行，报"非法图面类型"。

**根因**：手册/前人整改记录称返回小写（v1.2 曾按此把 `"MECHANICAL"`
改成 `"mechanical"`），但 17.4 S039 实机 `skill axlDesignType(t)` 返回
**大写 `"FLASH"`**；`member`/`equal` 大小写敏感，名单全小写必拒。

**正确写法**：守卫名单大小写两种形式都列（`"flash" "FLASH"
"mechanical" "MECHANICAL"`），或先统一大小写再比较。**凡手册声称的
字符串返回值大小写，先实机 `skill 函数()` 验证再写进比较逻辑。**
实证：`pkg_createovalflash.il` v1.4.2（FYCOT/mkth 设计类型守卫）。

### 4.13 prog 体内有 `return(...)` 时，隐式落尾返回值丢失（16.6 实证）

**症状**：函数逻辑全部执行成功（副作用、全局缓存都对），调用方拿到的
返回值却是 **nil**——表现为"功能没反应"。

**根因**：`prog` 体内一旦写了 `return(...)`，16.6 实机上 prog 的隐式
落尾值（最后一个 form 的求值）就丢了，落尾返回 nil。对照实验（桥远程，
同函数体逐字 only 差结尾）：bare tail `form` 结尾 → 返回 nil；
显式 `return(form)` 结尾 → 返回句柄。换言之 prog 与 return 要么不用
return、要么**全程显式 return**，不能混用"中途 return + 落尾值"。

**杀伤力**：`unless( 失败 axlUIConfirm(...) return(nil) )` 错误分支 +
成功路径 bare tail 是表单/工具函数的常见写法——这种函数在 16.6 上
**永远返回 nil**。`util_unitconvert.il` 的计算器因此"点了没反应"
潜伏多年：表单每次都创建成功，返回值 nil 让调用方跳过 axlFormDisplay，
且失败残留还把表单变量名污染（§8.5 根因二的僵尸由此而来）。

**正确写法**：

```skill
procedure( XXX()
  prog((...)
    unless( ok axlUIWPrint(nil "失败原因") return(nil) )
    ...
    return(result)      ; 显式 return 收尾，别靠落尾值
  )
)
```

**实证**：`util_unitconvert.il` v2.1（2026-08-23，16.6 S115 桥对照实验
014202 vs 014414）。排查同类存量：grep `return(` 且结尾非 return 的
prog 函数。

### 4.14 三个语言层小坑：`%`、`if-else` 单表达式、`ascii()` 不吃字符串

**`%` 不是 SKILL 运算符**：`hi % 2` 加载期就报
`illegal character '%' ignored` + `if: too many arguments`。
取模用 `mod(hi 2)` 或 `evenp(hi)`（均存在，17.4 实测 fboundp 有值）。

**`if` 的 else 分支只许一个表达式**：then 可多个、else 只能一个，
多写就报 `*Error* if: too many arguments (missing then?)`：

```skill
if( i < nrows then
    row = i  colA = 1          ; then 分支多表达式 OK
else
    progn( row = i-nrows  colA = 47 )   ; else 多表达式必须 progn
)
```
（`_CVN_pickCancel 'cancel else 'done` 当年同款报错；util_hotkeysetup
v1.3 编辑器 BuildForm 又踩一次。）

**`ascii()` 不接受字符串**：`ascii("a")` 直接 eval error。
取第 i 个字符的码用 **`charToInt(getchar(s i))`**（1-based，17.4 实测
返回 97）；`getchar(s i)` 返回的是字符对象不是数，不能直接 `> 127`
比较（util_hotkeysetup _HKE_Truncate 实证）。

### 4.15 字符串字面量两连坑：裸 CJK 出串、真换行入串（16.6 reader）

**坑一：字符串提前被未转义的引号截断，裸 CJK 落到串外**。
`fprintf(port "TEXT "键 命令 说明"\n")` 在 `"TEXT "` 处就终止，
后面的汉字变成"裸符号"——17.4 读得过，**16.6 reader 直接报
Invalid character，整个文件加载在该 form 处中断**（后面的 defun/
注册全部静默丢失：BindAll 在、Edit 不在）。正确写法：内层引号一律
`\"` 转义（util_hotkeysetup v1.6 TEXT 两行，2026-08-24 实锤）。

**坑二：.il 字符串里夹真换行（multi-line string）**。
python 补丁 `\n` 没二次转义就会把这种东西写进 .il：
`fprintf(port "FIELD hke_key_%d<真换行>" r)`。**16.6 reader 把串内真
换行折叠成空格**（17.4 保留 LF）——结果 fprintf 输出的 FIELD/FLOC/
STRFILLIN 全挤在一行，生成的 .form 非法，`axlFormCreate` 返回 nil。
正确写法：串内换行只用 `\n` 两字符转义。

**教训**：给 SKILL 文件打 python 补丁时，`\\\"` 和 `\\n` 的层级必须
过一遍脑子（目标 .il 里要看到 `\"` 和 `\n` 字面）；验证加载用真机
16.6，17.4 对这两种都宽容，测不出来。

### 4.16 `append1` 进 foreach = O(n²)：数据一大就是"死循环"

**症状**（2026-08-24 实机惊魂）：Allegro 启动后 Not Responding、CPU
单核跑满、数小时不醒，表象像"死循环"；bridge 心跳全停、外置软件显示
离线——其实是**伪死**：`HotkeySetup_RemoveOldSection` 用
`foreach(line lines result = append1(result line))` 处理 47.1 万行的
env 文件，`append1` 每次把列表从头走到尾，总量 O(n²) ≈ 2×10¹¹ 次操作。

**根因**：`append1` 是尾插，复杂度 O(列表长)；放进对 n 个元素的循环
就是 O(n²)。n=30 无感，n=47 万就是小时级。UI 线程被占死 → UI 定时器
（bridge 心跳）一起饿死——**任何在加载期/回调里跑的重计算都会拖死
全部 UI 定时器**，排查桥"离线"先查宿主是不是假死。

**正确写法**：循环里一律 `cons` 头插（O(1)），出循环一次 `reverse`：

```skill
result = nil
foreach( line lines
    when( 保留条件 result = cons(line result) )
)
reverse(result)
```

存量排查口诀：grep `append1(.*foreach` 同函数共现的写法，评估数据规模
上限；凡是处理"用户可无限增长的文件/列表"的代码路径，禁用 `append1`。

实证：`util_hotkeysetup.il` v1.8（探针 `bindall:funckeys-done` 后无
`writeenv-done`，一句锁定 WriteEnvFile 内的 O(n²)）。

### 4.17 配置文件"读-改-写"往返：CRLF 空行翻倍 + `\r` 残留毁比较

**症状**：`$HOME/pcbenv/env` 从 623 字节涨到 942 KB / 47.1 万行（其中
47.1 万是空行），只用了一个下午（十几次 Allegro 启动）。

**根因双拼**：

1. **CRLF 翻倍**：文件被外部碰成 CRLF 后，`gets` 把 `\r\n` 当两个断行
   （或保留 `\r`），每"读进来再 `fprintf(port "%s\n")` 写回"一轮，
   空行数翻倍——2¹⁴ 次方级膨胀，十几次写入就 47 万行。
2. **`\r` 残留毁比较**：`"source $TELENV\r"` 经 `parseString` 后 token
   带 `\r`，`== "$telenv"` 永假 → 去重失效，每写一次多插一行
   `source $TELENV`（文件里 16 行 = 16 次写入全漏判）。比较前没剥 `\r`
   的 `==`/`equal`/`member` 全都不可信。

**正确写法**（读改写三件套）：

```skill
;; 1) 读入即剥尾 \r
when( and( stringp(line) strlen(line) > 0
           equal(substring(line strlen(line) 1) "\r") )
    line = substring(line 1 strlen(line) - 1)
)
;; 2) 重写时丢弃纯空行（配置文件空行只是装饰，断了翻倍链）
unless( equal(line "") result = cons(line result) )
;; 3) 内容比较一律 equal（== 是身份比较，见 §4 通例）
```

**更大的纪律**：**启动路径别重写用户文件**。v1.7 每次启动自动
WriteEnvFile，把小 bug 放大成启动冻结；v1.8 改为启动只绑键
（`BindAll(nil)`），写文件只发生在用户显式"应用/恢复默认"。启动期
自动动作 = 读多写少，写操作留给显式触发。

实证：`util_hotkeysetup.il` v1.8；膨胀文件修复脚本
`_patches/env_repair_20260824.py`（47.1 万行 → 19 行，内容零丢失）。

---



## 5. 图形对象创建（path / shape）

### 5.1 本机 axlPathStart/axlDBCreatePath 只接受 (x y) 二维表点

- 手册示例点写作 `9150:4450`（x:y 点对），但 17.4 S039 实机：点对被拒，
  内部报 `*WARNING* (axlDBCreatePath): Not a floating point number! - range`，
  创建 0 对象；换 `(x y)` 二维表（`list(x y)`）立即成功；
- `axlDBCreateLine` 包装器同病——Line 模式改走手册三步：
  `axlPathStart(全点列 0.0)` + `axlDBCreatePath(path layer)`（p.311/p.736/p.753）；
- `axlEnterPoint` 返回的也是 `(x y)` 表（car=x、cadr=y），直接传递，
  勿 `car(org)`（v2.4 踩坑：只传 x 坐标，下游 car 浮点报错）。

实证：`text_addchinese.il` v2.5-v2.7。

### 5.2 shape 挖孔（void）仅 ETCH 等层允许

`axlDBCreateVoid` 手册注明 "Only certain layers, such as ETCH layer, allow
voids"——丝印层等挖孔会静默失败，务必检查返回值并提示；shape/void 边界
路径必须**首尾同点闭合**（OpenShape 检查 equal startPoint endPoint），
且边界段不得自交（bow tie 拒建）。

### 5.3 动态铜皮的生成品不可编辑：挖空走 `shapeBoundary` 重定向

**症状**：对 ETCH 层铜皮 `axlDBOpenShape` 报
`*WARNING* Cannot edit a generated shape`，挖空全部失败。

**根因**：`axlDBGetShapes("ETCH/xx")` 拿到的是动态铜皮的**生成品**
（generated shape），手册明确不可编辑；用户挖空必须建在动态铜皮的
**边界**（BOUNDARY 类）上。生成品 dbid 的 `sh->shapeBoundary` 属性
即指向其动态边界。

**正确写法**：

```skill
target = sh
when( sh->shapeBoundary          ; 生成品 -> 动态边界
    target = sh->shapeBoundary
)
osh = axlDBOpenShape(target)     ; 开边界 -> 建 void -> 关闭
; 全部挖完后刷新动态填充，生成品才重建出空洞：
axlShapeDynamicUpdate(nil nil)
```

注意 `sh->dynamic` 是**臆造属性**（属性表里没有，曾用它判断动态铜皮
导致漏判），判生成品一律用 `sh->shapeBoundary != nil`（或
`sh->shapeIsBoundary` 判边界）。
实证：`route_padvoid.il` v1.2→v1.3。

**后续定论（v1.6，实机通过）**：整条 void 链路在 17.4 S039 上坑太多
（`axlDBCreateVoid` 不收 r_poly、临时铜皮 `->vertices` 读不出、
开关 shape 的 dbid 失效链），**"隔层挖空"类需求改用 ROUTE KEEPOUT
更稳**：对象轮廓 `axlPolyFromDB`（cline 加 `?endCapType "ROUND"`）
直接 `axlDBCreateShape(poly t "ROUTE KEEPOUT/<层>")`（route_linetoshape.il
实证通路），动态铜皮避让即成洞，轮廓天然贴合、外扩可为 0。
局限：keepout 不消静态铜（只报 DRC）。
实证：`route_padvoid.il` / `route_clinevoid.il` v1.6。

### 5.4 `axlPolyFromDB` 对 pin/via/pad 全版本返回 nil；焊盘轮廓走 `pad->figure`

**症状**：拾取 pin/via 后 `axlPolyFromDB(obj)` 不报错但返回 nil，
轮廓提取整批落空（padvoid"全部对象轮廓获取失败"）。

**根因**：`axlPolyFromDB` 只覆盖 shape/cline/void 类 dbid；pin/via/pad
不在其列（16.6 S115、17.4 S039 桥探针同现 `(nil)`，与版本无关）。
焊盘的边界轮廓藏在 **`axlDBGetPad(obj 'composite "REGULAR")->figure`**
——`figure` 是定义焊盘边界的 r_path（至多一条），**相对坐标**
（相对焊盘中心；绝对位置 = `pin->xy + pad->offset`）。

**正确写法**（route_padvoid v2.0 实证链路）：

```skill
pad = axlDBGetPad(obj 'composite "REGULAR")   ; composite=各层最差集，与层无关
fig = car(pad->figure)                        ; r_path，相对坐标
ko  = car(axlDBCreateShape(fig t "ROUTE KEEPOUT/<层>"))  ; 先建在相对位置
axlTransformObject(ko ?move list(pin->xy + pad->offset)) ; 再平移到绝对位置
;; 需外扩时（keepout 是铜皮 dbid，PolyFromDB 可用——ashOne 文档通路）：
newp = car(axlPolyExpand(car(axlPolyFromDB(ko)) expand 'NONE))
ko   = axlDBOpenShape(ko newp t)              ; 返回新 dbid，旧的失效
```

注意 `'composite` 忽略 t_type 且取各层并集（最差情况），做 keepout
偏保守但安全；要精确到单层用 `"ETCH/<层名>"` + `"REGULAR"`，
该层无焊盘时返回 nil（正确跳过）。

### 5.5 设计级统计别信 design dbid 的集合属性；过孔 padstack 名走 `->name`

**症状**（24.1 桥探针实锤，2026-08-24）：`axlDBGetDesign()->vias /
->clines /->shapes /->drcs` **不报错但返回空列表**——2425 个过孔的
板子数出 0；`via->padstack` / `via->padstack->name` 也是 nil。
`->nets` / `->symbols` 倒是正常（603/516），真假混排最坑人。

**正确写法**：

- 计数走**选择集**：`axlSetFindFilter(?enabled '("NOALL" "VIAS")
  ?onButtons '("VIAS"))` → `length(axlGetSelSet(axlAddSelectAll()))`，
  用完 `axlClearSelSet()`；DRC 走属性选择
  `axlSelectByProperty("DRC" "EXTERNAL_VIOLATION_DESCRIPTION")`
  （与 autosilkutils 同一套路）。
- 过孔的 padstack 名：`via->name`（或 `via->definition->name` 兜底），
  不要 `via->padstack->name`。

**实证**：ASTB Studio 板子体检探针（backend.board_health），
0402:1922 + 0503:503 = 2425 与选择集计数吻合。

---

## 6. 外部程序调用（Python / bat / ipc）

### 6.1 `system()` 在 17.4 是不可靠黑盒 → 优先 `ipcBeginProcess`

- `system()` 内联命令的引号构造**永远无法同时正确**：cmd `/c` 的引号剥离
  规则与 bat 行解析不同（双重包裹曾出 rc=123/9009）；
- 更糟的是 `system()` 可返回 0 但 bat 实际未执行（无输出、无产物）；
- 正解（Cadence IPC 手册标准四件套，路径含空格也没问题——直起进程不经
  cmd 解析）：

```skill
cid = ipcBeginProcess(cmd "" nil nil nil logFile)
ipcWait(cid 3600 120)
rc  = ipcGetExitStatus(cid)
ipcReadProcess(cid 1)     ; 排空子进程输出防阻塞
```

  bat+system 仅作回退。实证：`text_addchinese.il` v1.6/v1.7。

### 6.2 中文/特殊字符经文件传递，不走命令行

命令行传中文必乱码：SKILL 侧写 **GBK job 文件**（参数逐行），子程序读文件
解析；Python 端日志对中文用 `\uXXXX` 转义打印（纯 ASCII 无损，可直接核对
Allegro 表单传入的文字编码是否正确）。

### 6.3 成败判定与取证

- 以**数据文件解析成功**为唯一成功标准，不信 system/批处理返回值；
- **仅解析成功才清理临时文件**；失败保留全部 job/dat/log，并打印行数 +
  前 5 行 + 子进程日志（一次复测即可定位）；
- `gets` 读行保留 `\n` 需自行剥除（否则 magic 头误判）；GBK 中文 1 字 =
  2 字节，`strlen` 按字节计。

---

## 7. 制造输出（film / 钻孔 / 坐标）

### 7.1 nc_parameters 精度：dec 必须 ≥ accuracy+1

钻孔"整数位:小数位"若低于设计精度（如默认 2:4），`nc_parameters` 的 done
会被拒。默认给 5:5，生成前按设计 accuracy 自动上调小数位
（dec ≥ accuracy+1）；老会话参数要自动迁移。

**v2.4 修正**：实机复测发现 5:5 下 `.drl` **照常生成**（表单回显虽可能
停在上次值 2:4，但写入的精度生效）；此前"done 被拒→.drl 不生成"的推断
不成立，真根因是分类器漏判（见 7.5）。参考脚本 `21_Quick_ExportARK.il`
实测默认 int=2/dec=5（其 5:5 写法被注释弃用），精度以小数位为准。
实证：`mfg_gerbersetup.il` v2.2 / v2.4。

### 7.2 FORM 宏序列以实机实测为准

film_control / nc_parameters / nc_drill / plctxt 的 FORM 宏字符串取自
`21_Quick_ExportARK.il` / `19_ljj_camout.il` 在 17.4 的实测序列，跨版本可能
失效需按当前版本重录；`ncdrill param` 后记得补 `generaledit` 收尾。

### 7.3 既有底片部分字段只读

artwork film 控制里**既有底片的部分字段不可写**（`axlSetParam` 仅部分生效，
改不动时不报错）——要改格式/undefined line width 等需删除重建；新底片用
`axlfcreate`（Cadence 样例底层接口，`18_film_reorder`/`21_Quick_ExportARK`
均用）一次性写入全部参数。

### 7.4 分层钻孔底片：扫描 padstack startEnd

每个钻孔跨层一张 `DRILL_i_j`：遍历 padstack 的 startEnd 收集跨度对，按
NCLEGEND-* 图例层拆分；图例层缺失时拆分无据，打印提示让用户先生成钻孔
图例。（交换变量名避开保留字 `t`——gbs v2.3 用 t 做交换变量，parser 拒绝
赋值，跨度对恒为 `(a t)`，拆分整体失效。）

### 7.5 输出文件分类：别只靠"前后快照差集"

**症状**：`.drl` 明明生成了，却永远不进 CAM 目录；`.rou`/`.art` 正常。

**根因**：分类器用"生成前后 `getDirFiles` 差集"找新文件
（`member(x beforeFiles)` 排除）。同名旧文件一旦滞留目录（某次漏分类、
或手工 nctape 产物），文件名就进入 beforeFiles；之后每次运行只是**覆盖
生成**，名字不再是"新增" → 永远漏判。而已分类文件会被删除原件，所以
`.rou` 从不滞留、`.drl` 一旦漏一次就永久漏——稳定复现的自锁失败。

**正确写法**：CAM 产物扩展名（`art/drl/rou/ipc/tap`）不依赖快照差集，
目录里出现即纳入分类（分类后删原件，自清）；`log/txt` 仍只收本次新增。
实证：`mfg_gerbersetup.il` v2.4（GBS_Classify 的 sweepExt）。

---

## 8. 表单控件与层属性（axlFormColorize / axlLayerGet）

### 8.1 层颜色色块 + 可见性开关（v3.6 实机定稿语义）

在 Subclass 旁做"显示所选层颜色、点击开关该层"的色块。实机踩过三轮坑后的
定稿写法：

- **CHECKLIST 同组互斥（收音机/radio 语义）**：.form 里同一 GROUP 的
  CHECKLIST 互斥单选（做 Drawing Type 单选就靠它）；**只有一个成员的组，
  选中后用户点不动**——读控件勾选态决定开关目标会导致"只能开不能关"。
- 因此色块当**无状态按钮**用：
  - 刷新时**勾选态恒置 nil**（`axlFormSetField(fw "fvis" nil)`）——每次
    点击都是 关→开 翻转，必触发回调；层状态只以背景色表达；
  - 点击回调**不读控件值**，以 `axlIsVisibleLayer(layer)`（手册 p.167，
    返回 t/nil）读真实状态取反：`axlVisibleLayer(layer !cur)` +
    `axlVisibleUpdate(t)`，然后重刷色块。
- 刷新：`q = axlLayerGet("CLASS/SUBCLASS")`（errset 防护）取 `q->color`
  填背景：`axlFormColorize(fw "fvis" 'background q->color)`；层关则填
  `'black`（errset 失败退回 `'background nil`）。**颜色用 q->color 实证
  可行；但可见性不要读 `q->visibility`**——17.4 S039 实锤：层明明
  可见时 `axlIsVisibleLayer` 返回 t，`q->visibility` 却读回 nil
  （v3.4/v3.5 症状：色块永不变化），可见性一律以
  `axlIsVisibleLayer` 为准，q->visibility 只作读取失败兜底。
- **不要走 `axlLayerSet` 改 visibility 的路**（v3.2 写法，实机开关无效）；
  开关层统一用 `axlVisibleLayer + axlVisibleUpdate(t)`（layer_view 实证）。
- 同步系统层显隐：表单收不到 Allegro 颜色对话框/选项面板的事件，做被动
  同步——打开表单、fclass/fsub 变化、以及主回调分发后（doneState==0）
  各重刷一次（用户在系统面板改完，回表单点任意处即同步）。
- 注意：`axlFormColorize` 只支持 STRFILLIN/READFILLIN/LONGFILLIN/
  INTSLIDEBAR/ENUMSET/CHECKLIST/TEXT，且**带 POP 的控件不显色**——
  色块要用无 popup 的独立控件；标签用空格撑宽（`CHECKLIST "    " "LVIS"`）。

实证：`text_addchinese.il` v3.6（ACH_RefreshColor / ACH_OnVisToggle）；
v3.2 axlLayerSet 路径、v3.4 读勾选态路径均被实机否决。

---

### 8.2 `LIST` 字段必须写 `LIST "" w h`，否则 axlFormCreate 返回 nil

**症状**：.form 文件存在、路径正确，`axlFormCreate` 却返回 nil，
表单死活弹不出来，无任何报错。

**根因**：手写 .form 时把列表字段写成 `LIST 24 16`（直觉的"宽 高"），
这是已知的解析失败写法——**第一个参数必须是空字符串**：

```text
FIELD padlist
FLOC 1 3
LIST "" 24 16          ; 正确：LIST "" 宽 高
ENDFIELD
```

同族易错：`ENUMSET 15 1`（多一个参数）也解析失败，正确是 `ENUMSET 15`；
TEXT 定位项目内统一 `TLOC`（FLOC 在部分版本可用，随工作表单用 TLOC 更稳）。
**POP 引用的 POPUP 必须先在表单文件声明**——运行时动态构建的下拉
（`axlFormBuildPopup`）也要先写一行空声明 `POPUP <layers> "" ""`，
否则 `axlFormCreate` 同样返回 nil（amg 动态表单实证模式；
`route_layervoid.form` 2026-08-01 实机踩坑）。

**`axlFormBuildPopup` 的列表格式以实机为准**：规范分则（style/form-ui.md
9.2）要求嵌套 `'(("label"))` / `'(("label" "value"))`，但 17.4 S039 实机
嵌套格式报 `Illegal popup list format`，**扁平字符串列表**
`axlFormBuildPopup(fw "field" '("TOP" "GND" ...))` 才是实证可用格式
（`route_automatchgroup.il` 同款；`route_padvoid.il` v1.1 踩坑修复）。

**排查口诀**：`axlFormCreate` 返回 nil 且文件确定存在，先逐字段对 BNF
（allegro-form-builder 技能的痛点表），LIST/ENUMSET 是高发区。

**实证**：`forms/rvia.form`（2026-07-26，`LIST 24 16` → `LIST "" 24 16`
后表单正常弹出）。

---

### 8.3 按钮字段名 `ok`/`done` 是保留字，点击不进 case 分发

**症状**：表单渲染正常、列表/复选框回调都进 `case`，唯独点"确定"按钮
**什么反应都没有**——无消息、无报错、表单也不关。

**根因**：手册 Table 11-4 注明保留按钮字段标签：`done or OK`（执行动作
并关闭表单）、`cancel`、`print`、`help`。字段名 `ok` 撞上保留字后，点击走
`doneState` 关闭通道，**不分发给回调的 `case(fw->curField ...)`**——
`case` 里写了 `("ok" ...)` 分支也永远不会命中。

**正确写法**：动作按钮字段名避开保留字（如 `apply`），显示标签随便：

```text
FIELD apply
FLOC 27 4
MENUBUTTON "确定" 9 2
ENDFIELD
```

`cancel` 保留字的语义恰好是"取消并关闭"，与多数需求一致，可保留使用；
`help` 被注明"do not use"（调 cdsdoc），自写帮助按钮也要改名（如 `rvhelp`）。

**实证**：`modules/via/rvia.il` v1.5→v1.6（`ok` → `apply`，按钮立即生效；
此前 v1.2-v1.5 的"替换没反应"系列报告根因都在此）。

---

### 8.4 已填充的 LIST 字段直接 SetField 不刷新显示，必须先 DeleteAll

**症状**：过滤/切换后日志证明新列表已算出，但屏幕上的列表纹丝不动。

**根因**：LIST 字段首次 `axlFormSetField(fw "list" items)` 填充正常，
**再次**整体替换内容时不刷新显示——必须先
`axlFormListDeleteAll(fw "list")` 再 `axlFormSetField`
（官方 axlform.il 的 `alias fdelete axlFormListDeleteAll` 即为此准备）。

**实证**：`util_search.il` v2.3（[SRCH] 探针实证 shown=15 但屏幕不变）；
`rvia.il` v2.0 同坑同修（焊盘列表筛选/来源切换不刷新）。
另：STRFILLIN 的回车才派发事件（无逐键实时），筛选类输入按"回车触发"
设计并在表单上写明提示。

### 8.5 16.6 表单：`#` 注释行 + CRLF 行尾组合致命；失败创建留僵尸注册名

**症状**：.form 存在、`axlFormTest` 通过、字段类型全部合法，
`axlFormCreate` 却在 16.6 上**静默返回 nil**（17.4+ 正常）。

**根因一（实机二分定位，2026-08-23）**：`.form` 文件**同时**含 `#` 注释行
和 **CRLF 行尾**时，16.6 表单解析器解析失败。三个变量两两组合实机验证：
纯 CRLF 无碍、LF+注释无碍、**CRLF+注释必败**；`axlFormTest` 四种情况全
通过，不能当判据。修复 = 转 LF（或删注释行），推荐转 LF 保留注释。
被害文件：`forms/gtopen_calculator.form`（单位换算"不能用"）、
`forms/align.form`（对齐功能同症状）、`forms/gtopen_AddDynShape.form`。

**根因二（同场挖出，25+ 探针零例外）**：`axlFormCreate('name ...)` 的表单
变量名**只要被绑定过**（失败创建留下的僵尸句柄、其他 Skill 包占用的
同名全局、甚至绑定 nil），再创建恒返回 nil——且失败创建本身就会绑定
一个半建成句柄，形成"失败→同名永败"的自锁，**只能重启 Allegro 清场**；
从未被绑定的全新名字则必成功（关掉再建也没事）。机制未完全确定
（疑似 16.6/24.1 表单注册表按内部名去重），但规避方案简单可靠：
（注：本案相当比例的"失败创建"实为 §4.13 裸尾 bug 的副作用——表单
创建成功但函数返回 nil，调用方误判失败重试，把名字污染成僵尸。）

```skill
;; 每次调用生成全新变量名（concat 产生符号），绕开一切绑定名诅咒
_GT_UCF_SEQ = _GT_UCF_SEQ + 1
form = axlFormCreate(concat("astb_ucf_" _GT_UCF_SEQ) file nil 'CB t)
;; 关旧表单走缓存的句柄全局（_GT_UCF_LAST），不依赖固定变量名
```

**配套防御**：`axlFormCreate` 返回 nil 的失败分支**禁用 `axlUIConfirm`**
（模态弹窗在桥/定时器回调上下文会卡死 SKILL 线程，心跳停摆），用
`axlUIWPrint(nil ...)` 走命令行。

**实证**：`util_unitconvert.il` v1.6→v2.0（2026-08-23，桥远程二分：
7 组对照表单 + 25 余组变量名对照，16.6 S115 / 24.1 S006 实机）。

### 8.6 表单布局度量：中文 Windows 下 1 汉字 = 2 格；PORT = 内容外沿 +2

**根因认识**：.form 的 `PORT`/`FLOC`/`TLOC`/字段宽**全部以"字符格"为
单位，不是像素**；一格的像素尺寸 = Windows 系统语言的对话框字体
（Allegro 用系统对话框字体，不随 Allegro 语言包）。中文 Windows 下
**一个汉字占 2 格**，且 16.6（老小字体）与 17.4+（大字体、DPI 感知）
格子像素不同——同一个表单两版本"打开范围不一样"是必然，不是 bug。

**布局规则**（v1.9 定稿）：

- **PORT = 内容外沿 + 2 格**，两轴都是。余量 0 的表单在 17.4 出滚动条/
  裁切、16.6 刚好放下（两版不一致的重灾区）；余量过大则 17.4 上大片
  空白。存量审计脚本 `_patches/form_extent_audit_20260824.py`：解析
  FLOC/TLOC + 字段 w/h 算内容外沿 vs PORT，贴边的一律 +2。
- **表头按列独立 TEXT、TLOC 对准字段 x**——禁用空格凑对齐
  （`"键      命令  说明"` 这种串按西文宽度算空格数，中文下必歪）。
- **中文标签宽度按 2 格/字算**：按钮 `MENUBUTTON w 2` 的 w ≥
  汉字数×2+2（"恢复默认" = 4×2+2 = 10）。
- 行距 2 格起步；按钮行与表格间空一行；同排按钮统一间距。
- 按 17.4 的格子设计、16.6 验证（17.4 格子大，17.4 能放下 16.6 必能）。

实证：`util_hotkeysetup.il` v1.9 编辑器表单重排（PORT 78×31→76×32，
表头三列独立 TEXT）；审计贴边 4 表单（gtopen_AddDynShape /
gtopen_Export_Symbol / gtopen_Logo / search）PORT 全部 +2。

---

## 9. 菜单系统（axlUIMenu*）

### 9.1 axlUIMenuDelete 的 id 必须来自 axlUIMenuFind——Insert 返回的嵌套 id 不通用

**症状**：保存 `axlUIMenuInsert(nil 'popup label)` 的返回值当"菜单 id"，
语言切换时 `axlUIMenuDelete(该id)` 删不掉，重注入后菜单栏**叠出第二个菜单**。

**根因**：手册明确 Delete/Change 的 `x_menuId` **来自 `axlUIMenuFind`**；
Insert 对 popup 返回的是"新子菜单的嵌套 id"（仅供继续向其中插入子项），
两套 id 体系不通用。Delete 遇到体系外 id **静默失败（返回 nil，不抛错）**。

**正确写法**：删除前用 `axlUIMenuFind` 定位。注意**顶层菜单栏 popup 不能
按名称 Find**（名称模式找不到菜单栏项），只能按位置 `axlUIMenuFind(nil pos)`；
pos 可由 `axlUIMenuDump` 解析推算（见 9.3）。

实证：`core/menu.il` v2.2→v2.4（2026-07-26 语言热切换叠菜单攻坚战）。

### 9.2 errset 只判"没抛错"，不判"返回成功"

**症状**：`deleted = errset(axlUIMenuDelete(id) t)` + `unless(deleted ...)`，
失败分支永远走不到。

**根因**：Delete 失败是**返回 nil**（不抛错），errset 把它包成 `(nil)`——
非 nil 列表，`unless` 判定为"成功"。

**正确写法**：`r = errset(f() t)` 后用 `and(r car(r))` 取真实返回值；
对静默失败型 API（Delete / 部分层操作）还必须**做事后验证**（见 9.3 的
dump 闸门），不能只看返回值。

### 9.3 菜单"删除-重建"必须加 dump 验证闸门，杜绝叠菜单

**模式**（ASTB v2.4 定稿）：

1. 先试旧 id Delete（无害，某些版本可能碰巧有效）；
2. `axlUIMenuDump` 到临时文件，搜特征命令名（恒 ASCII，中英文菜单均可靠）
   确认旧菜单是否消失；
3. 未消失 → 位置法：解析 dump 推算顶层位置 → `axlUIMenuFind(nil pos)` →
   Delete → 再 dump 验证；
4. **只有确认旧菜单消失才重注入**；任何环节失败或不可判定 → 保持旧菜单
   原样，提示"重启生效"，绝不重注入。

**17.4 S039 dump 实证格式**（POPUP/MENUITEM/BEGIN/END 纯文本，缩进表层级）：

```
BEGIN                                          ← 缩进 0（菜单栏容器骨架）
    POPUP "File"                               ← 缩进 4（菜单栏顶层项）
    BEGIN
        MENUITEM "&New",            "new"      ← 缩进 12
    END
    POPUP "工具箱"                              ← 缩进 4（顶层）
    BEGIN
        POPUP "系统"                           ← 缩进 8（二级）
        BEGIN
            MENUITEM "&关于",			"ASTB_About"
        END
    END
END
```

- 顶层定位算法：从工具箱命令标记行（如含 `ASTB_Reload` 的 MENUITEM 行）
  向上回溯，**缩进最小的 POPUP 行**即工具箱顶层项；菜单栏位置 = 全文中
  同级（同缩进）POPUP 行里它的序号（0 起）；
- MENUITEM 标签带 `&` 前缀与双引号，命令名双引号；
- 验证函数找不到任何标记/dump 失败时按"仍在"处理（保守方向，宁可提示
  重启不可叠菜单）。

实证：`menu.il` `ASTB_ToolboxTopMenuPos` / `ASTB_ToolboxMenuPresentInDump`。

### 9.4 axlUIMenuFind / axlUIMenuChange 要点

- 名称模式 `Find(nil "cmd")`：找命令菜单项（`t_cmdName` 可为命令行前缀），
  **找不到菜单栏顶层 popup**；
- 位置模式 `Find(nil pos)`：pos 0 起=菜单栏最左；负数从右数（-1=最右，
  通常 Help）；
- `g_menuOption` 取 `'top`/`'bottom`：定位子菜单顶部/底部（Insert 用）；
- 菜单搜索由菜单栈控制，首参传 nil 重置栈；嵌套搜索才传既有 id；
- `axlUIMenuChange(id 'display 新文本)` 可**原地改标签**，手册明确"可在
  菜单触发回调之外安全执行"——这是热切换语言的另一条路（不改结构只换
  文本，天然免疫叠菜单；但 popup 标签仍需位置法定位）；
- `axlUIMenuChange` 选项表：`'enable` t/nil、`'check` t/nil、`'display` 文本、
  `'command` 命令串；分隔符不可改、子菜单不可赋命令。

---

## 10. 全局表（makeTable）与配置系统

### 10.1 makeTable 缺键的 unbound 哨兵会"传染"：`eq` 判断即中招

**症状**：`v = table[缺键]` 之后 `eq(v 'unbound)` →
`*Error* eval: unbound variable - v`。

**根因**：缺键返回的哨兵不是普通值——赋给变量后**对该变量求值本身**就
抛错。任何"读出来再判断"的写法（`eq`/`strcmp`/打印/传参）都在判断之前
先炸。

**正确模板（errset 强制求值法，ASTB v1.5 定稿）**：

```skill
procedure( ASTB_GetConfig(key defaultVal)
  prog((r)
    ;; 把"读取+求值"整体放进 errset：缺键哨兵在对 v 求值的这一刻
    ;; 抛错，被 errset 静默捕获返回 nil，回退默认值
    r = errset(
      prog((v)
        v = ASTB_CONFIG[key]
        return(v)
      )
    )
    if( null(r) then
      return(defaultVal)
    )
    return(car(r))
  )
)
```

要点：errset **不带第二参**（缺键是正常路径，要静默）；**禁止**
`eq(v 'unbound)` 判哨兵；makeTable 没有 has-key API，需要"键集合"时
自维护 KEYS 列表或用本模板绕过。

实证：`config.il` v1.4（eq 判断版，启动期 `utf8_autoconv` 缺键查询必炸）
→ v1.5（本模板）。

### 10.2 配置文件读写三坑

- Allegro outfile 的 `fprintf(port "%s=%s\n")` 在 Windows 也写 **LF**
  （不转 CRLF）；`gets` 读回无 `\r`。但若文件曾被外部编辑器（CRLF）碰过，
  value 尾部会带 `\r` 残留——trim 必须**真生效**（见 4.8 扩展：`==` 版
  trim 是摆设）。
- 值"剔换行"用 `rexReplace(s "\r" " ")` 会**留下尾空格**（`"en "`），
  后续 `strcmp("en " "en")` 永假——语言/模式类取值比较前务必 trim，
  或把换行**删除**而非替换为空格。
- 键集合（KEYS 列表）与表槽分离维护时，**键查重必须用 `equal`**：
  `member`/`==` 按同一性，内容相同的不同对象判不上 → KEYS 无限 cons、
  cfg 重复行堆积（ASTB 实证堆到 194 行）。

实证：astb.cfg 重复堆积事件、`IsLanguageEnglish` 因 `"en "` 尾空格永假
（2026-07-26）。

---

## 11. 调试与诊断方法论

### 11.1 "磁盘代码已改、行为依旧"：先怀疑会话滞留与加载链，再怀疑逻辑

- Allegro 会话长开不重启，core 不会被 Reload 之外的任何操作重载；
  `defvar` 无 `boundp` 保护的全局状态会长期累积（KEYS 183 项实证）。
- **STAMP 探针**：在 core 文件尾部放 `printf("XXX-STAMP-日期\n")`，
  启动/Reload 日志没出现 = 磁盘新版根本没进内存——先解决加载链，
  别再改逻辑。
- **`getd('func)`**：直接打印内存中的函数体，与磁盘对照，一步分辨
  "函数被覆盖/仍是旧版"。
- 同名函数**后加载者覆盖先加载者**：core 先加载、modules 后加载，
  modules（含 `_stubs.il`）里的同名定义才是运行时版本。
- `%L`/`%s` 打印字符串时 `\r`/尾空格**不可见**——长度存疑用 `strlen`
  验证；列表元素逐个 `printf("[%s]:%d " k strlen(k))`。
- 交互式 `skill strcmp("a" "a")` 正常**不代表**运行时函数没被覆盖——
  要在目标上下文里测（`getd` 最可靠）。

### 11.2 诊断探针的写入与清理纪律

- 探针 printf 用**独立行**，**不要把功能调用包进探针**
  （`printf("ret=%L" errset(关键调用()))` ——清理探针时会误删功能调用。
  ASTB 实证：Delete 被包进探针，删探针留下空 `when` →
  `*Error* when: too few arguments`，热切换中断）；
- `when(cond)` 只有条件没有 body，**执行到时**才报错（special form 在
  eval 期查参数个数）——未被条件触发的空 `when` 不炸，结构破坏可能
  延迟暴露，别被"刚才还能跑"迷惑。

### 11.3 Allegro 假死（Not Responding + 高 CPU）的外部定位法

**判型**：任务管理器里 Allegro `Responding=False` 且 **CPU 持续上涨**
= 计算死转（SKILL 重循环，见 §4.16）；CPU 不动才是 I/O 阻塞（管道写满、
网络盘）。两者药方完全不同，先看 CPU 再动手。

**定位手段：加载步骤落盘追踪**。journal（allegro.jrl）是缓冲写的，
假死时最后落盘行远落后于真实进度，**不可信**。改用探针直写：

1. loader 级：每个模块 `load()` 前往 `<TEMP>/astb_bridge/load_trace.log`
   追加一行 `LOADING <path>`——假死后最后一行 = 卡死的模块；
2. 模块内细粒度：在嫌疑模块的加载路径关键节点（文件头 / 各顶层调用
   前后）插同款落盘行——本案 6 行探针直接锁定 `WriteEnvFile` 内部；
3. 探针函数自带全局计数上限（如 200 行）防日志爆量；**定位完必须
   全部拆除**（含 loader 里的）。

**配套事实**：UI 定时器（axlUIWTimerAdd 注册的 bridge 心跳）只在 UI
事件循环空闲时触发——加载假死时心跳必然停摆，"桥离线"是果不是因；
`run --wait` 报 "session alive but busy" = 目标会话有模态框或交互命令
占用，job 会排队，别当桥故障重发轰炸。

实证：2026-08-24 桥"离线"事件全链路（31 个 stale 会话误导 → 实为
hotkeysetup 加载 O(n²) 假死；探针脚本留档 `_patches/`）。

### 11.4 Python 补丁脚本的转义层级与写盘纪律

**`\r`/`\n` 在补丁串里是真控制字符**：给 .il 注释写"剥 \r 特字符"，
Python 串里的 `\r` 落盘就是真回车；后续任何"全文剥 `\r`"的清洗会把
该注释劈成两行、第二行丢 `;` → Allegro SYNTAX ERROR。补丁文本里出现
反斜杠序列时，先想清楚目标文件要的是字面两字符（写 `\\r`）还是控制
字符。**shell `-c` 一键补丁有多层反转义（工具传输层 + bash 双引号层），
反斜杠必坏——补丁一律写 .py 文件执行，不用 -c。**

**`io.open` 写失败 = 目标文件被清空**：`io.open(p,'w',...)` 打开即截断，
`fp.write(src)` 中途抛错（如 GBK 编码不了 `²`）后文件只剩 0 字节。
本次靠 D 盘部署副本救回。纪律：

- 编码/替换全部在内存做完并 `src.encode('gbk')` **预检通过后再开写**；
- 或先写临时文件再 rename 替换；
- 版本头修订注释里的特殊字符（²、×、→ 等）先过 GBK 可编码性
  （`str.encode('gbk')` 试一遍），不可编码就换 ASCII 写法（`O(n^2)`）。

实证：2026-08-24 util_hotkeysetup.il 0 字节事故（D 盘副本恢复）+
注释劈行 syntax error 事故，同日出炉两条。

---

## 12. 实机联调 Checklist（交互命令类模块交付前过一遍）

- [ ] 所有 axl 函数在 `99_Alphabetical_List.md` 可查（无臆造 API）
- [ ] 层名 class 部分带空格形式（BOARD GEOMETRY / PACKAGE GEOMETRY /
      REF DES / VIA CLASS）
- [ ] `axlVisibleLayer(层名 t/nil)` 参数顺序
- [ ] interactive 命令优先用 popup 字符串回调 + `axlFinishEnterFun`/`axlCancelEnterFun`
      （via_stitching 实证模式）；若注册 `?doneCmd/?cancelCmd`，**禁止多传 `?undo`**
      （axlCmdRegister 无此参数，加载期报错、文件加载中止）
- [ ] popup 标签全英文
- [ ] enterFun 返回值 `listp` 防御后才取 car/cadr
- [ ] popup 回调内事务调用包 `errset(... t)`
- [ ] lambda/procedure 形参不用保留字（t、nil 等）
- [ ] 含中文注释的 .il 以 GBK 保存；但**菜单/popup 标签**字符串必须英文
- [ ] 16.6 部署必须过八进制转义补丁：16.6 reader **拒绝字符串中的 GBK
      高位字节**（`string terminated by illegal char \xxx` + SYNTAX ERROR，
      加载中止；注释可过）。16.6 副本 = 主仓库拷贝 + 字符串 GBK 中文转
      `\ooo` 八进制转义 + 剥离裸 axlCmdRegister 的 `?undo`
      （ASTB 一键脚本 `_patches/sync_to_166_20260816.py`）；
      ilinit 在安装树 share/local/pcb/skill 也挂一份（防 HOME 漂移），
      加载块放最前（未捕获 load 错误中止 ilinit 剩余部分）
- [ ] 16.6 的表单查找只认**启动期 env 文件的 FORMPATH**：运行期
      `setShellEnvVar("FORMPATH=...")` 对 axlFormCreate/axlMiniStatusLoad
      无效（实测 FORMPATH 值正确仍 `Can't find form`，全路径
      axlFormTest 却成功）。**首选不改 env**：运行期 `axlSetVariable`
      写 Allegro env 注册表（与 env 文件同源，表单/位图查找器都认），
      路径由 FormPath 现场拼（可迁移）；THUMBNAIL 位图走
      BITMAPPATH/BMPPATH 同法注册。改 env 文件的坑：pcbenv/env 退出时
      被重写（手加行丢失）；site.env 依赖 ALLEGRO_SITE（未设不读）
- [ ] 文本/图形原点用创建入参，不回读 dbid 属性
- [ ] `axlPathStart`/`axlDBCreatePath` 点用 `(x y)` 二维表（本机拒 x:y 点对，
      报 `range`）；Line 模式绕开 `axlDBCreateLine` 包装器走手册三步
- [ ] 不用 `cons` 构造点对（浮点第二参报错）；确需点对用 `rplacd`
- [ ] 跨函数大结构走全局变量通道，不依赖 prog/errset 返回值
- [ ] `parseString` 产物比较用 `equal`，不用 `case`
- [ ] `cond(`/`if(`/`when(`/`case(` 括号紧跟关键字，不分行
- [ ] popup 每次 enter 返回后重设；Undo 类回调不调 Finish/CancelEnterFun
- [ ] 撤销自维护（批次栈存**定位信息**而非 dbid——跨命令 dbid 失效；
      撤销时现场查找新鲜 dbid 再删；重建类操作显式传网络名），
      不靠 `axlDBTransaction*` 跨命令，也别指望 Ctrl+Z（本机实锤不覆盖）
- [ ] shape/void 边界首尾同点闭合；挖孔层先确认允许 void（ETCH 等）
- [ ] 挂网络建 cline（axlDBCreateLine 带 netName）时约束管理器会覆盖
      宽度入参——撤销/重建类操作建成后再 `axlChangeWidth` 显式压回
      记录的原宽（线转铜皮撤销线宽未恢复实锤）；`cline->width` 直读
      失败退到首段 `seg->width`
- [ ] `return` 只出现在 `prog` 内；字符串比较用 `equal` 不用 `==`
- [ ] `let` 绑定表至少一个变量，禁 `let(())`
- [ ] 环境变量用 `getShellEnvVar`（无 `getenv`）
- [ ] 外部进程优先 `ipcBeginProcess` 四件套；中文经 GBK job 文件传递
- [ ] 临时文件仅解析成功才清理，失败保留取证并打印前 5 行
- [ ] 钻孔/数控精度 dec ≥ accuracy+1（默认 5:5，老会话自动迁移）
- [ ] 输出文件分类：CAM 产物扩展名（art/drl/rou/ipc/tap）不依赖前后快照
      差集，出现即纳入（同名旧文件覆盖生成时差集必漏）
- [ ] 吸附预览用 `axlClearDynamics` + `axlAddSimpleMoveDynamics`，
      加载包 errset 计成功数，退出必须 `axlClearDynamics()`
- [ ] 右键 Done 回调用命名函数串 + printf 留痕（分辨本工具菜单 vs 默认菜单）
- [ ] 表单色块：`axlFormColorize(... 'background 颜色号)` 只用于无 popup
      控件；层可见性走 `axlLayerGet/Set` + `axlVisibleUpdate(t)`
- [ ] 消息提示分级：被动提示只用 `axlUIWPrint(nil 纯文本)`（传 `'error`
      类符号会弹错误对话框）；`axlUIPrompt`=输入对话框、`axlUIConfirm`=
      模态确认框，都不当状态提示用
- [ ] 大段帮助/报表文本要弹窗：`axlTempFile` 写内容 +
      `axlUIViewFileCreate(file "标题" t)` 弹文件查看器，errset 包裹并
      留命令行回退；帮助内容外置 GBK 数据文件，别硬编码进 .il
- [ ] .form 语法：`LIST "" w h`（空串首参，否则 axlFormCreate 返回 nil）；
      `ENUMSET w` 单参数；按钮字段名避开保留字 ok/done/print/help
      （撞保留字点击不进 case 分发）
- [ ] .form 部署 16.6 前查行尾：`#` 注释行 + CRLF 组合必败
      （axlFormCreate 静默 nil，axlFormTest 照过）；表单变量名用
      每次全新生成（`concat("astb_xxx_" 序号)`）——绑定过的名字
      再建恒 nil（失败创建自锁，只能重启 Allegro）；Create 失败分支
      禁用 axlUIConfirm（模态框卡死桥/定时器线程），改 axlUIWPrint
- [ ] `axlUIMenuDelete/Change` 的 id 一律来自 `axlUIMenuFind`，不用
      `axlUIMenuInsert` 返回值（体系不通用，Delete 静默失败）
- [ ] 菜单存在性查重无跨版本银弹：`axlUIMenuDump` 文本匹配在 24.1
      失效（叠菜单）；`axlUIMenuFind(nil "cmd")` name 直查在 16.6 对
      不存在的命令返回非 nil（误判已注入、不注入）。可信做法：先用
      肯定不存在的探针命令校准 name-find，可信则用、不可信落 dump
      兜底；自愈定时器只保留一个（'open+'menu 双触发先取消旧定时器）
- [ ] 启动初始化别只押 `axlUIWTimerAdd` 一次性定时器：16.6 实测启动
      过早（UI 事件循环未就绪）时定时器静默失效，Init 从未执行——
      表象是"MAIN_LOADED=t 但功能函数全未定义"（易误判幽灵绑定）。
      双通道武装：定时器 + `'open` 触发器兜底，Init 内置防重标志；
      排障先在文件入口埋无条件 printf 探针确认文件是否被读取
- [ ] `errset` 结果用 `and(r car(r))` 取真值；静默失败型 API 做事后验证
- [ ] 撤销接线两条：加载时 `ASTB_RegisterUndo("tag" 'XXX_Undo)` + Done
      批次入栈处 `ASTB_UndoJournalPush("tag")`；注册表只认 makeTable；
      批次存定位信息不存 dbid；恢复覆盖全部被改属性；替换类先删新建
      再重建旧件；撤销命令本身注册 `?undo nil`
- [ ] 菜单"删除-重建"走 dump 验证闸门：确认旧菜单消失才重注入，否则
      提示重启（杜绝叠菜单）
- [ ] `makeTable` 读值用 errset 强制求值模板，禁 `eq(v 'unbound)` 判哨兵
- [ ] 配置值比较前 trim；键查重用 `equal` 不用 `member`/`==`；
      **字符串键的关联表禁用 assoc**（身份比较，注册后查不到），
      用 `makeTable`（`t[k]=v` 写、`t[k]` 读，缺键返回建表默认值）
- [ ] 磁盘改动未生效先查 STAMP 探针 / `getd('func)`，再怀疑逻辑
- [ ] 诊断探针独立行，功能调用不包进探针 printf
- [ ] 循环构列表禁 `append1` 尾插（O(n²)，大数据即假死）：`cons` 头插 +
      出循环 `reverse`；处理用户可无限增长文件的路径必须评估规模上限
- [ ] 配置文件"读-改-写"：读入剥尾 `\r`、重写丢空行（断 CRLF 翻倍链）、
      内容比较用 `equal`；启动期自动动作只读少写，写文件留给显式触发
- [ ] .form 布局：`PORT` = 内容外沿 +2 格（两轴）；中文按 2 格/字计宽；
      表头独立 TEXT 对准列 x，禁用空格凑对齐；按 17.4 格子设计、16.6 验证
- [ ] Python 补丁：反斜杠序列（`\r`/`\n`）按"目标文件要字面还是控制符"
      逐处确认；补丁一律 .py 文件执行（shell -c 多层反转义必坏）；
      内存预检 `encode('gbk')` 通过再开写，防 `io.open` 截断清空
