# AGENTS.md — allegro_skill_toolbox 项目公约（AI 会话必读）

> 本文件面向所有在本项目内工作的 AI 会话/协作者。开工前先读完；
> 通用实机踩坑见技能手册 `allegro-skill-coding/references/practical-pitfalls.md`
> （其 §12 为交付前 checklist），ASTB 架构手册见同目录 `project-playbook.md`。

## 1. 项目结构（活目录）

- `main.il` + `allegro.ilinit`：加载入口（防重载守卫 + 步骤序列）
- `core/`：核心库（loader/utils/config/menu/trans/utf8_loader/version_adapter/zz_smoke）
- `modules/<分类>/`：功能模块，loader 自动扫描；新增 = 丢进分类目录 + 菜单加项
- `forms/`：全部 `.form`；`config/astb.cfg`；`tools/`；`python/`
- 档案目录（`_attic_*`、`_backup`、`_upstream_ref`、`review_*`）**只读勿改**

### 模块 .il 命名约定（2026-08-01 起，存量已统一）

1. 新模块一律 **`<分类前缀>_<动宾功能>.il`，全小写**，前缀与目录一致：
   `pkg_ / place_ / route_ / via_ / shape_ / text_ / check_ / mfg_ / util_`
2. **不用数字前缀**（`01_`/`14a_` 等）——当年为控加载顺序，现 loader
   字母序 + `_stubs`（最先）/ `zz_wrappers`（最后）位次约定已够用
3. 单功能小模块允许**命令名即文件名**（`rvia.il`↔命令 `rvia`）；
   多功能模块必须用分类前缀式
4. 配套表单与模块同名：`rvia.il` ↔ `forms/rvia.form`
5. `zz_wrappers.il`（目录菜单包装）与 `modules/_stubs.il`（占位桩）
   是 loader 位次硬约定，禁止改名
6. 改名用 `git mv` 保历史，并全仓检索旧名同步引用（`_patches/`
   留档映射脚本；历史留档文件 lint_baseline/review_report 不改）

## 2. 工程纪律（血的教训，强制执行）

1. **编码**：含中文的 `.il/.form/.dat` 一律 **GBK**；技能 `.md` 文档、
   Java 工具源码用 UTF-8。
   修改 GBK 文件用托管脚本显式 GBK 往返读写或 iconv（Java 侧必须处处
   显式 `Charset.forName("GBK")`——JDK 18+ 默认编码是 UTF-8，隐式读写
   会把文件改成 UTF-8），**禁止 UTF-8 编辑器直接保存**。
   仓库工具链已全 Java 化：`tools\SkillSrcSync.java`（sync/check）、
   `skill_src\tools\AstbSmoke.java`（冒烟）、`skill_src\tools\AstbBridgeClient.java`、
   `tools\installer\BuildAll.java`；均 JDK 11+ 单文件源码直跑，
   `.bat` 包装见各目录（自动找 JDK 21）。
2. **16.6 字符串转义**：16.6 SKILL reader 拒绝字符串字面量中的 GBK
   高位字节（报 `string terminated by illegal char`）。含中文的字符串
   必须用 `\ooo` 八进制转义（GBK 字节），注释里的中文不受影响。
   转换逻辑已内置 `tools\SkillSrcSync.java` 的 ascillize（字符串内
   高位字节自动转 `\ooo`，注释不动，状态机转义感知）。17.4/24.1 无此限制。
3. **写盘前三项校验**：括号平衡（字符串/注释状态机）、残留 `\r` 扫描、
   GBK 可逆抽查。脚本留档 `_patches/`（命名带日期）。
4. **文件头**：文件名/作者/创建日期/版本/功能描述/修改记录六字段齐全；
   每次实机验证通过的修改**升版本号 + 补一行修订记录**。
5. **Git**：本项目已纳入 Git（`* -text`，不转行尾）。开工先 `git status`
   看其他会话的改动；提交粒度 = 一次整改，信息写清模块与版本。
6. **质量闸门**：改完跑 `tools\sync.bat check`（往返）+
   `skill_src\tools\smoke.bat`（静态）+ Allegro 内 `ASTB_SmokeTest`
   （运行时），全绿再交付。

## 3. 菜单与 i18n（单一数据源）

- 中文标签唯一数据源：`core/labels_map.dat`（`英文键=中文标签` 每行一条）。
- 新增菜单项三步：`ASTB_GetMenuStructure` 加行 → keys 列表加键 →
  `labels_map.dat` 加同行标签，三者同步。
- 菜单/popup 标签**禁用 GBK 中文**（reader `Invalid character`），
  中文只进 labels_map.dat。
- 菜单"删除-重建"走 dump 验证闸门（防叠菜单），id 一律来自 `axlUIMenuFind`。

## 4. 高频踩坑速查（详见 pitfalls 手册对应条目）

- 消息：`axlUIWPrint(nil 纯文本)` 走命令行；传 `'error` 类符号会**弹窗**；
  `axlUIPrompt`=输入对话框、`axlUIConfirm`=模态确认框，别当状态提示用（§2.9/2.10）
- 表单：`LIST "" w h`（空串首参）；`ENUMSET w` 单参数；按钮字段名避开
  保留字 ok/done/print/help；CHECKLIST 独立选项**不写** groupLabel（§8.1-8.3）
- 选择：`axlSelect` 默认模式每次清空前次选择；要累积用 `?groupMode t`（rvia v1.7）
- 撤销：`axlDBTransaction*` 不能跨命令；本机 Ctrl+Z 不覆盖 AXL 建/删对象；
  批次栈存**定位信息**不存 dbid（跨命令失效）；重建显式传网络名（§2.6 扩展）
- 事务：项目明文例外——数据库修改包 `ASTB_DBTransactionMark`（errset 保护，
  不用 `axlDBTransaction*`），linter 已识别为合规
- 语言：`==` 是身份比较，字符串用 `equal`；`return` 只在 `prog` 内；
  `errset` 结果用 `and(r car(r))` 取真值；`errsetstring` 第一参是表达式
  字符串（§4.8/4.7/9.2/4.11）
- 层名：class 部分用数据库内部带空格形式（`BOARD GEOMETRY` 等）（§1.1）

## 5. 实机调试标准动作

1. "磁盘改了行为依旧" → `skill getd('函数名)` 对内存，或埋 STAMP 探针
2. 加载失败原因不明 → 裸 `load` 一次去掉 errset，让真实行号暴露
3. 字符串诡异比较失败 → `strlen` 戳隐形字符（`\r`/尾空格/全角）
