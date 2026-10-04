# ASTB（allegro_skill_toolbox）项目实战手册

> 本手册沉淀 allegro_skill_toolbox 在 SPB 16.6 / 17.4 / 24.1 实机上验证过的架构约定、代码模板与工程纪律。
> 项目根目录：`G:\allegro\allegro_skill`（17.4 实机验证版本：17.4-2019 S039）。
> 凡在本项目内新增模块、修改 core/、调试加载/菜单/配置问题，先读本手册；通用踩坑见 `practical-pitfalls.md`。

---

## 1. 工具箱架构

```
G:\allegro\allegro_skill\
├── main.il                  ; 入口：防重载守卫 + ASTB_Init 步骤序列
├── allegro.ilinit           ; Allegro 启动钩子（设 ASTB_INSTALL_DIR、setSkillPath、load main.il）
├── config\
│   └── astb.cfg             ; key=value 配置文件
├── core\                    ; 核心库，loader 按序加载
│   ├── loader.il            ; 加载器（core 顺序加载 + modules 自动扫描）
│   ├── utils.il             ; 字符串/列表工具（StringTrim、StrListHas 等）
│   ├── version_adapter.il   ; 16.6/17.4/24.1 版本适配
│   ├── config.il            ; astb.cfg 读写（GetConfig/SetConfig/SaveConfig）
│   ├── menu.il              ; 菜单注入、删除、语言热切换
│   ├── trans.il             ; 命令注册封装 ASTB_RegisterCommand / 事务封装 ASTB_DBTransactionMark
│   ├── utf8_loader.il       ; GBK 标签文件读取
│   └── labels_raw.dat       ; 中文标签表（行号与 keys 列表对齐）
├── modules\                 ; 功能模块，按目录自动扫描加载
│   ├── _stubs.il            ; 未实现功能的占位命令（最先加载）
│   └── <category>\          ; check / package / placement / routing / shape / text / utilities / via ...
│       ├── xxx.il
│       └── zz_wrappers.il   ; 每个目录的包装命令（最后加载，zz 前缀保证序）
└── _backup_pre_fix\         ; 所有历史备份与归档（整改前先备份到这里）
```

**核心约定**：

- `modules/` 下任何 `.il` 文件会被 loader 自动扫描加载，**不需要手工登记**；`_stubs.il` 最先、`zz_wrappers.il` 最后（靠文件名排序保证）。
- 新增模块 = 把 `.il` 丢进对应分类目录 + 在菜单文件里加菜单项，无需改 loader。
- core 加载顺序：`utils` 优先（其他库依赖它），其余按字母序；每个文件单独 `errset`，单文件失败不中断整体。

---

## 2. 加载链

### 2.1 allegro.ilinit → main.il

```skill
; allegro.ilinit 职责：定位安装目录 → 扩 skill 路径 → load main.il
setShellEnvVar("ASTB_INSTALL_DIR" "G:/allegro/allegro_skill")
setSkillPath(append1(getSkillPath() "G:/allegro/allegro_skill"))
load("main.il")
```

### 2.2 main.il 防重载守卫（文件顶部，return 必须在 prog 内）

```skill
when( boundp('ASTB_MAIN_LOADED)
  printf("[ASTB] main.il already loaded, skipping (use ASTB_Reload() to reload modules).\n")
  prog(() return(nil))
)
defvar(ASTB_MAIN_LOADED t)
```

### 2.3 ASTB_Init 步骤序列

- 初始化拆成命名步骤（LoadCore → LoadConfig → LoadModules → RegisterAllMenuCommands → InjectMenu ...）。
- **每步单独 `errset`**，失败步骤记入列表，全部通过才 `defvar(ASTB_INITIALIZED t)`。
- 失败时打印失败步骤名，提示修复后手工 `ASTB_Init()` 重试——不要中途崩溃留半成品状态。
- `ASTB_Reload()` 重载模块用：清 `ASTB_MAIN_LOADED` 后重新走加载流程；菜单侧靠 boundp 守卫防叠加（见 §4）。

```skill
; 步骤执行模板
steps = list(
  '("ASTB_LoadCore"                ASTB_LoadCore)
  '("ASTB_LoadConfig"              ASTB_LoadConfig)
  '("ASTB_LoadModules"             ASTB_LoadModules)
  '("ASTB_RegisterAllMenuCommands" ASTB_RegisterAllMenuCommands)
)
failed = nil
foreach( step steps
  unless( errset( apply(cadr(step) nil) t )
    failed = append1(failed car(step))
    printf("[ASTB][ERROR] Init step failed: %s\n" car(step))
  )
)
if( failed
  then
    printf("[ASTB][ERROR] Initialization failed at step(s): %L\n" failed)
    printf("[ASTB] ASTB_INITIALIZED NOT set; fix the issue and run ASTB_Init() to retry.\n")
  else
    defvar(ASTB_INITIALIZED t)
    printf("[ASTB][INFO] Core libraries loaded.\n")
)
```

---

## 3. 配置系统（config.il，定稿 v1.5）

### 3.1 astb.cfg 格式

- 纯文本 `key=value`，一行一个；写盘前必须剔除 key 内的 `\r`、`\n`、尾空格（曾发生 `\r` 混入 key 导致 strcmp 失败、配置重复追加的事故）。
- 读入时同样 trim 每行两端空白再 split。

### 3.2 GetConfig：errset 强制求值模板（关键）

`makeTable` 缺键返回的 **unbound 哨兵有传染性**：直接比较、传参会抛 `unbound variable`。必须 errset 包裹并强制求值：

```skill
defun( ASTB_GetConfig (key @optional default)
  let( (v)
    v = errset( ASTB_CFG_TABLE[key] t )     ; errset 只判"没抛错"，真值要 car
    if( v && car(v) != nil && boundp('v)    ; 三重防御
      then car(v)
      else
        when( default == "DEFAULT_NIL" default = nil )  ; 哨兵字符串约定
        default
    )
  )
)
```

### 3.3 SetConfig / SaveConfig 纪律

- `SetConfig`：写入前 `ASTB_StringTrim` 剔换行；新 key 登记进 `ASTB_CFG_KEYS` 列表。
- `SaveConfig`：用 `uniqKeys`（**`equal` 比较，不用 `==`**——`==` 是身份比较，字符串字面量会漏重）去重后按 keys 顺序写盘。
- `InitDefaultConfig`：只补缺失键，**不覆盖已有值**。
- 所有全局变量（表、keys 列表）一律 `unless(boundp('x) defvar(x ...))` 保护，防 Reload 重复 defvar 告警。

### 3.4 已知遗留

- `astb.cfg` 可能出现同一 key 多行（KEYS 列表重复增长的根因未定位）；功能无影响，读法以首行为准，写盘会收敛。排查入口：实机 `skill getd('ASTB_StrListHas)` 确认内存函数体是否为 equal 版。

---

## 4. 菜单与 i18n（menu.il，定稿 v2.4）

### 4.1 防叠加守卫

```skill
unless( boundp('ASTB_MENU_INJECTED) defvar(ASTB_MENU_INJECTED nil) )
unless( boundp('ASTB_TOP_MENU_ID)   defvar(ASTB_TOP_MENU_ID   nil) )
```

Reload / 语言切换前先删旧菜单再注入，靠这两个守卫记录状态，**绝不盲目重复 inject**（否则菜单栏每切一次多一个顶层菜单）。

### 4.2 标签表 labels_raw.dat

- GBK 编码，一行一个中文标签，**行号与 keys 列表严格对齐**；新增菜单项时 key 和标签行必须同步追加。
- 英文标签在代码内写死（popup 标签**禁用中文**，防 `Invalid character`）；中文标签运行时从 dat 读。
- 读取走 `utf8_loader.il`（按 GBK 读入行列表）。

### 4.3 语言热切换：删除 → dump 验证闸门 → 重注入

定稿流程（17.4 实机验证）：

1. `axlUIMenuFind` 按**位置**拿旧顶层菜单 id（菜单栏 popup 只能按位置 Find，名字 Find 不可靠）。
2. `axlUIMenuDelete(id)`——**id 必须来自 axlUIMenuFind 的返回值**，臆造 id 静默失败。
3. **dump 验证闸门**：删除后 dump 菜单文件，扫描确认旧项确实消失；未消失则中止重注入并告警（宁缺毋叠）。
4. 重新 inject 新语言菜单，再 dump 一次确认新项存在、数量正确。
5. 全程写 `astb.cfg` 的 `language` 键，重启后生效持久。

### 4.4 17.4 dump 实证格式

- 菜单 dump 到文件后按行扫描：`POPUP "标签"` 定顶层、`MENUITEM "名", "命令"` 定叶子。
- 顶层菜单位置算法：数菜单栏已有 popup 数量定位插入点；`minInd=0 cand=nil` 表示按名查找落空，必须退化到位置法。

---

## 5. 版本适配（version_adapter.il）

- 启动时探测版本字符串（如 `17.4-2019 S039`），映射到能力标志位。
- 16.6 / 17.4 / 24.1 共存差异点集中在：菜单 API 行为、表单控件支持、中文编码处理（16.6 不支持 UTF-8 中文注释，中文必须抽到 `labels_raw.dat` 动态加载）。
- 模块代码**不写死版本判断**，一律调 version_adapter 提供的能力查询函数。

---

## 6. 工程纪律（血的教训，强制执行）

### 6.1 编码与写盘

- `.il` / `.form` / `.dat` 含中文一律 **GBK** 保存；技能 .md 文档用 UTF-8，二者不混。
- Allegro `outfile` + `fprintf("%s\n")` 写出的是 **LF**（Windows 下不会自动转 CRLF）；生成 job/log 文件给外部工具用之前先确认对方能否吃 LF。
- 查看 GBK 文件用 `iconv -f GBK -t UTF-8`；**修改一律用托管 Python**（`codecs.open(path, 'r', 'gbk')`），禁止用 UTF-8 编辑器直接保存。

托管 Python 路径：

```
C:/Users/Lenovo/AppData/Roaming/kimi-desktop/daimon-share/daimon/runtime/python/.venv/Scripts/python.exe
```

### 6.2 补丁与备份

- 补丁脚本统一放 `_patches/`，命名带日期（如 `fix_menu_v24_0726.py`），跑完留档不删。
- **写盘前三项校验**（补丁脚本内自动执行）：
  1. 括号平衡扫描（逐字符计深，字符串/注释状态机）；
  2. 残留 `\r` 扫描（GBK 文件混入 CR 是 strcmp/配置事故高发源）；
  3. iconv 抽查若干中文行，确认 GBK 可逆。
- 任何整改前先把原文件复制到 `_backup_pre_fix\`；批量整改建带日期的子目录。

### 6.3 文件头版本号 + 修订记录

```skill
;========================================================================
; 文件名    : core/menu.il
; 版本      : v2.4
; 修订记录  : v2.4 语言热切换改 dump 验证闸门 + 位置法 Delete
;           v2.3 ...
;========================================================================
```

每次实机验证通过的修改，必须升版本号并补一行修订记录——出问题时靠它快速定位"上次好使的是哪版"。

### 6.4 STAMP 探针验证磁盘代码真进内存

修改不生效时，先怀疑"Allegro 加载的不是磁盘上这份文件"（多副本、缓存、cxt 预编译）。在目标函数入口埋独立行探针：

```skill
printf("[UTL-STAMP-0726B] entered\n")   ; 探针必须独立行，功能调用不得包进 printf
```

实机执行后看有没有 STAMP 输出：没有 → 加载链/路径问题；有 → 再查逻辑。验证完立即清除探针。

---

## 7. 表单实战

- **CHECKLIST**：同组多成员天然互斥；**单成员组点不动**（17.4 实机实证）——单选项改用单独 checkbox 字段或 radio。
- 已验证字段类型：`REALFILLIN`（实数输入，回车触发回调；回调里拿到的是 float，**先 `sprintf("%.4g")` 转字符串再做 strlen/parse**，直接 strlen(float) 报 `argument #1 should be a string`）、`ENUM`（下拉）、`TABSET`（页签）、`CHECKLIST`。
- **axlFormColorize 色块**：字段上不能有 popup 控件才显色；层可见性判断以 `axlIsVisibleLayer` 为准，不要信自己的缓存。
- 表单字段回调里做任何字符串处理前，先确认值的实际类型（float / string / symbol），REALFILLIN 是重灾区。
- 模块汉化流程：`.form` 的 HEADER/FIELD label 改中文（GBK 保存）→ `.il` 里 printf/axlUIWPrint 同步中文化 → 实机加载验证 → 版本号+1。

---

## 8. 调试工作流（实机排障标准动作）

1. **看内存不看磁盘**：`skill getd('函数名)` 打印内存中的函数体，与磁盘文件比对——不一致就是加载链问题（多副本/缓存/加载失败被 errset 吞掉）。
2. **strlen 戳穿隐形字符**：字符串比较诡异失败时，`strlen` + 逐字符看，`\r`、尾空格、全角字符立刻现形。
3. **探针独立行纪律**：诊断 printf 独立成行，功能调用不包进 printf 参数里（包进去出错时连探针一起死）。
4. **SLFTEST 自测命令模式**：为可疑函数写 `XXX_SLFTEST` 命令，实机命令行直接调，打印输入/中间值/比较结果（`==` vs `equal` vs `strcmp` 三路对照），不依赖 GUI 路径。
5. **errset 吞错排查**：加载日志里 `Failed to load xxx.il` 但不知原因时，去掉 errset 裸 load 一次，让真实错误（行号+原因）暴露。
6. **undefined function 批量出现**（如 `nreverse`）：先查是不是 core 工具库没加载/加载顺序错，再查函数名是不是 Common Lisp 臆造品（SKILL 里是 `reverse`）。

---

## 9. 与本技能其他文档的关系

| 场景 | 读什么 |
|------|--------|
| 本项目架构/加载/配置/菜单/语言切换 | 本文档 |
| 外置软件 Studio / 文件队列桥 / 16.6 定时器坑 | 本文档 §10 |
| 通用实机踩坑（API 参数顺序、== 身份比较、getenv 等） | `practical-pitfalls.md` |
| extracta 提取报错（SPMHDX-10、解析坑） | `extracta-debugging.md` |
| 写新模块的规范模板 | `coding-standard.md` + `style/` 分则 + `assets/demo_cleanup.il` |
| 查 axl 函数签名 | `api/` 32 章（先 `99_Alphabetical_List.md` 定位） |

---

## 10. 外置软件 ASTB Studio 与文件队列桥（2026-08-22 定稿）

把工具箱 80 个命令搬到 Allegro 之外：PySide6 桌面窗口 + 系统托盘，
项目列表双击开 Allegro+板子，命令面板点按钮远程触发，全版本
（16.6/17.4/24.1）通吃。

### 10.1 架构：文件队列桥（协议 v1）

```
Studio (python/studio/)                      Allegro
  astb_bridge_client.py  --jobs/*.job-->     util_bridge.il（重复定时器轮询）
                         <--results/*.json--  eval 每条表达式写回结果
  sessions/*.session 心跳（10s 内刷新=在线）  menu_tree.json 菜单树导出
```

- 队列目录 `%TEMP%/astb_bridge/`（本机即 `D:/Temp/astb_bridge`），
  三个子目录 jobs / results / sessions。
- job 文件 = SKILL 源码（`ASTB_JOB_ID/TARGET/CMDS list`），先写
  `.tmp` 再 `os.replace` 原子发布，桥永远读不到半截文件。
- 桥按 job 的 TARGET pid 定向执行，天然支持多 Allegro 实例。
- 结果文件读取成功即删（队列卫生）；桥启动时清理陈旧 jobs/results/
  sessions。

### 10.2 编码契约：全版本 GBK + 八进制转义

- Allegro 运行时字符串在中文 Windows 就是 GBK 字节串，**所有版本**
  统一 GBK，不要给 17.4+ 单独切 UTF-8。
- job 文件只含 ASCII：中文一律 `\ooo` 八进制转义 GBK 字节（16.6
  reader 拒绝字符串里的高位字节）。
- 结果/session JSON 按 GBK 读（命令返回值可能带 GBK 字节）。

### 10.3 桥服务端（util_bridge.il）的 16.6 定时器三连坑

1. **Tick 回调必须三参**：`@optional window timerId elapsedTime`——
   少写了实机报 `too many arguments (0 expected, 3 given)`。
2. **oneshot 定时器在回调内重武装会静默失效**（16.6 实机抓到心跳
   停走、job 积压）——用**重复定时器**（`axlUIWTimerAdd` 第三参
   nil），不要在回调里重新武装。
3. **Reload 后定时器必丢**：文件尾部 `when( ASTB_BRIDGE_ON ... )`
   先 Stop 再 Start，保证 `ASTB_Reload` 后新定时器一定挂上。
4. 版本串用 `ASTB_GetVersion()`——`axlVersion('version)` 返回的是
   浮点数不是字符串。
5. 交互命令激活期间 tick 可能滞后几秒：客户端在线阈值放宽到 10s，
   心跳暂停 ≠ 桥死。

### 10.4 Studio 侧（python/studio/）

- `backend.py`：项目库/版本注册表/启动器/桥任务封装/menu_tree
  缓存/自定义 Skill 库。数据全在 `~/.astb_studio/*.json`。
  版本注册表自动扫描 `C~G:/Cadence/SPB_*/`——**16.6 的 allegro.exe
  在 `tools/pcb/bin/`，17.4/24.1 在 `tools/bin/`**，布局不同两处都要试。
- `studio_gui.py`：命令面板 = 分类 Tab + 按钮网格（数据来自桥导出
  的 menu_tree.json，离线用缓存）；自定义 Skill 标签页（点按钮 =
  桥发 `load("路径")` + 可选 `axlShell("启动命令")`）；版本注册表
  编辑对话框；帮助对话框读同目录 HELP.md；关窗口退托盘不退出。
- 交互命令点按钮返回 ok=true 只表示"已触发"，选取操作在画布完成。

### 10.5 GUI/桥联调的工程纪律

- 离屏测试：`QT_QPA_PLATFORM=offscreen` + `QTimer.singleShot(ms,
  app.quit)`；**会弹模态对话框的路径先在测试里断开信号**（离屏下
  模态框卡死事件循环，表现为进程无输出挂死）。
- 后台跑测试把输出重定向落盘，超时也读得到进度；别 `| tail`
  （管道要进程结束才出字）。
- Git Bash heredoc 会把 `\` 坍缩成 `\`、中文经 stdin 进 Python
  会按 GBK 解码成乱码——含转义/中文的测试脚本一律 Write 成文件再跑。
- `/tmp` 在 Git Bash 和 Windows Python 间不互通（Python 看成
  `D:\Temp`），临时脚本放项目 `_staging/`，用后归档 `_patches/` 或删。
