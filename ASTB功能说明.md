# ASTB（allegro_skill_toolbox）功能说明

- 版本：1.0.2（安装包）/ Studio 2.1
- 适用平台：Cadence SPB 17.4（大部分功能兼容 16.6，部分适配 24.1）
- 交付形态：`ASTB_Setup_x.x.x.exe` 安装包（Inno Setup），内含 SKILL 技能树 + 免安装外置软件 ASTB Studio
- 文档日期：2026-09-04

## 一、产品概述

ASTB 是面向 Allegro PCB Editor 的效率工具箱，由两部分组成：

1. **SKILL 技能侧**：注入 Allegro 的技能树，提供顶层菜单与 65 项功能命令，
   覆盖布局、布线、过孔、丝印文字、检查、制造输出等日常设计环节。
2. **ASTB Studio（外置软件）**：Windows 桌面常驻程序（PySide6，托盘运行），
   通过桥接通道驱动一个或多个 Allegro 会话执行技能命令。

安装包运行时自动检测本机 Allegro 版本、挂接 `allegro.ilinit` 加载块
（BEGIN/END 标记原地合并，重复安装不叠加），卸载时完整清理。

## 二、功能清单（按菜单分类）

### Via 过孔（5 项）

| 功能 | 命令 | 说明 |
|------|------|------|
| 表单替换过孔 | `rvia` | 拾取过孔后弹出仿 Allegro 焊盘浏览器，从数据库/PSMPATH 库选新焊盘批量替换 |
| 修改过孔网络 | changevianet | 先建新孔再删原孔，带错误保护可 Undo（17.4 跨选择轮 dbid 失效已根治） |
| 同类过孔批量替换 | samevia | 将某种焊盘的全部过孔替换为另一种焊盘 |
| 堆叠过孔检查 | stackvias | 检查并报告堆叠过孔（只读，不改库） |
| 过孔 Stitching | stitching | 缝合过孔自动放置及辅助工具集 |

### Routing 布线（10 项）

| 功能 | 说明 |
|------|------|
| 自动 10 度走线 | 对选中 cline 做 10 度蛇形走线 |
| 自动创建等长组 | 表单仿凡亿布局：Bus 弹选、From/To 器件双列表、建组写 RPD 容差 |
| 修改走线线宽 | 按层（树视图多选）+ 线宽条件（</=/>）筛选，高亮预览后批量改宽 |
| 跨分割检查 | 两端点未同落一块铜皮的走线保持高亮（纯高亮不改库） |
| 走线隔层挖空 `clinevoid` | 按外扩值在指定 ETCH 层铜皮上对走线挖 void |
| 焊盘隔层挖空 `padvoid` | 同上，作用于焊盘/过孔 |
| 切割走线/铜皮 | 框选区域切割 cline/line/shape/via |
| 删除悬垂对象 | 悬垂走线/悬垂过孔/孤岛铜皮，GUI 批量操作 |
| 走线转铜皮 | cline/line 转同层 shape，Done/Undo/Cancel 三态，可逐批撤销 |
| 短线段检查 | 高亮长度小于阈值的孤立 cline segment 并出报告 |

### Placement 布局（8 项）

| 功能 | 说明 |
|------|------|
| 元件对齐/等间距 | 上下左右对齐、水平垂直居中、等间距分布、Pick 点对齐 |
| 方向键等距复制 | 方向键绑定 `ipick ±D`，仿凡亿 Direction Key，可一键恢复方向键 |
| 收集摆放 | 高亮元件按三列自动排列后跟随光标一次性摆放 |
| 屏幕视图移动 | 方向移动 + 步长设置 |
| 栅格吸附 | 全部/点选/框选/按管脚数四模式，参考点可选原点或 Pin1，FIXED 自动跳过 |
| 按网络聚拢 Pack by Net | 共享网络并连通组，组内密排组间换行，撤销命令逐批移回 |
| 按原理图页摆放 | 按 PAGE/PAGE_NUMBER 等属性自动分组，已放件网格重排、未放件列清单 |
| Place Inside | 选中 symbol 在指定矩形内从左到右自动排列 |

### Text / Silk 文字丝印（11 项）

| 功能 | 命令 | 说明 |
|------|------|------|
| 添加中文字 | `achu` | fontTools 提 TTF 轮廓，Line/Shape/AntiShape 三种绘制，连续点击放置 |
| 添加网络名文本 | — | 拾取管脚/过孔/图形后拖动放置 |
| AutoSilk 丝印自动处理 | — | 间距检查、丝印 Shape 复制到 AutoSilk 层、文本转 Shape、DRC 浏览 |
| 丝印重叠检查 | — | 位号/文本与焊盘、过孔、测试点、其他文本的间距冲突定位 |
| 位号方向检查 | — | 顶层 0/90、底层 0/270、镜像属性与父元件一致，写 dir_error.log |
| 导入 BMP Logo | — | 图片转 Shape 放到指定层 |
| 位号居中/读向归一 | `refc` | 按器件原点居中，读向随旋转角，可统一字号，支持撤销 `refcu` |
| 位号位置重排 | — | 位号回到封装边界附近 |
| 位号方向批量旋转 | `ch_ref`/`ch_refskip` | 顶层/底层位号方向与元件方向一致 |
| 批量重命名位号 | — | 前缀匹配高亮、起始编号、Oops 单步回退、批次可撤销 |
| 元件值文本重排 | `val_c`/`val_o` | 按元件方向重算 COMPONENT VALUE 文本方向与位置 |

### Check 检查（9 项）

检查 90 度走线、DbDoctor 运行（附 NC pin 高亮）、DRC Walk 遍历、
无 Fanout SMD 焊盘高亮、无 RefDes 元件检查、孤儿网络查找、
焊盘/钻孔数量统计、SolderMask 到 Line 间距检查、
PasteMask/SolderMask/OSP 焊盘一致性间距检查。

### Shape 铜皮（2 项）

Shape 网络交互修改；动态铜皮强制更新并恢复 wysiwyg 填充（suf/su/shape_update 系列）。

### Package 封装（4 项）

两 Pin 中点改封装原点；批量生成 device 文件；椭圆/圆形 Thermal Flash 创建；
封装批量导出（合并 ExportPad/ExportFootprint 双入口）。

### Manufacturing 制造输出（2 项）

- **底片排序**：UI 调整 Artwork 各 film 输出顺序，保留层与选项设置。
- **Gerber 一键输出**（仿凡亿文件输出表单）：自动建 CAM/ASM/SMT/PCB 四类子目录；
  光绘（默认 RS274X、精度 5.5）/钻孔/坐标复选；按叠层自动创建/更新标准底片清单；
  生成后经 film_control / nctape_full / plctxt 宏通路输出并按底片名自动分类归档。

### Utilities 工具（15 项）

| 功能 | 说明 |
|------|------|
| Assembly 装配图位号 | Refdes 自动加到 Package Geometry/Display_Top |
| 栅格选择 | 常用栅格值表单，replay 脚本改 non-etch/all-etch 栅格 |
| 电源地网络配色 | 自动为电源/地网络分配颜色 |
| 配色方案 | FYCOL/FYCOL1/FYCOL2 三套整层颜色一键切换 |
| PCB 降版本 16.6 | 主转换器 adl_patched（官方 17.4 adl 补丁版）原地转 16.6，失败回落免补丁运行时；24.x 两跳（存 17.4 中间文件再转）；失败原因见输出目录同名 .log |
| 走线跨平面分割检查 | 两端点不在同一铜皮的 cline 保持高亮 |
| System/Help 帮助 | 读 help_map.dat 弹文件查看器，按菜单分类显示功能/步骤/实现 |
| System/Uninstall 卸载 | 剥离 allegro.ilinit 的 ASTB 安装器标记块（备份 .astb_bak）、清理 env forms 路径、移除当前菜单；重启彻底生效 |
| 快捷键批量设置 | 常用命令绑定功能键/字母键/键序列 |
| 切层与视图 `ql/qu/qd` | 层号切层、多层同显、相邻层循环、丝印/装配预设视图 |
| 定时另存 | 日期/时间两种后缀模式自动另存设计 |
| 搜索定位 Search Star | 模糊过滤器件/网络，单击缩放定位高亮 |
| 超级网络查找 | 按长度、曼哈顿距离百分比、过孔数筛选网络 |
| 工艺规则管理 | 加载/设置 PCB 工艺技术文件参数 |
| 单位转换 | mils/mm 互转计算器 |

## 三、外置软件 ASTB Studio

- 桌面窗口 + 系统托盘常驻，免安装（PyInstaller 打包，随安装包部署）。
- **命令树面板**：镜像 ASTB 菜单结构，实时刷新（桥接 job），离线缓存兜底；
  点击按钮即在目标 Allegro 会话执行对应命令。
- **多会话管理**：会话卡片、目标会话下拉、广播执行、看门狗（存活阈值 10s）。
- **任务预设**：主窗口预设下拉（features.py `load_presets/add_preset`）。
- **自定义技能页**：把本地 .il 添加为面板按钮。
- **迁移向导 / 版本注册表编辑器 / 帮助对话框**（HELP.md）。

## 四、基础能力（core/）

- **加载链**：main.il 防重载守卫 + loader 字母序自动扫描 modules 分类目录，
  `_stubs`（最前）/ `zz_wrappers`（最后）位次硬约定。
- **菜单与 i18n**：菜单结构内嵌双语标签（英文/中文同列一行，menu.il
  v4.3 起取代 labels_map.dat）；右键 popup 标签禁 GBK 中文；
  删除-重建走 dump 验证闸门；Allegro 本体界面语言独立设置
  （System->Allegro UI：Allegro X 写 env 本地化偏好、17.x 在 env
  手改区增删 intl_enabled 行（Qt 界面部分汉化），重启生效；解耦见 menu.il v4.5）。
- **版本适配**：version_adapter 兼容 16.6/17.4/24.1 API 差异。
- **撤销中枢**：数据库修改统一包 `ASTB_DBTransactionMark`（errset 保护），
  批次栈存定位信息不存 dbid，配套逐批撤销命令。
- **桥接**：SKILL 侧 tick 300ms ↔ Python 侧轮询 100ms、会话存活 10s，三者配套。
- **质量闸门**：`AstbSmoke.java` 静态检查（`tools\sync.bat check` 往返闸门）+ Allegro 内 `ASTB_SmokeTest` 运行时自检。

## 五、安装与卸载

安装包运行期行为：检测 Cadence 版本 → 部署技能树与 Studio → 向用户
`allegro.ilinit` 挂接加载块（`@INSTALL_DIR@` 占位替换）→ 首次部署出厂快捷键
表 `hotkeys_user.dat`（重装不覆盖用户已有键位）。卸载时移除挂接块与文件。
