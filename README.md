# ASTB — Allegro SKILL 工具箱 + ASTB Studio 外置软件

本仓库是 ASTB 的**单一源码仓**：Cadence Allegro 板内 SKILL 工具箱、
外置桌面软件 ASTB Studio（Java 版）、以及 Windows 安装包（exe）打包
所需的全部源码与脚本。

- SKILL 侧支持版本：Allegro **16.6 / 17.2 / 17.4 / 23.1 / 24.1 / 25.1**
  （同一份 skill_payload 全版本通用）
- 外置软件：Windows 桌面窗口，经"桥接"与 Allegro 会话联动（命令面板、
  项目/最近文件、快捷键表、帮助、体检、降版本、热键等）
- 安装包：Inno Setup 单 exe，可选安装目录，自动配置 ilinit/环境

> 本仓为 2026-10-03 从旧工作仓 `D:\ASTB_BuildEnv` 迁移而来的干净起点；
> 此前的逐日修改历史与 `_patches/` 补丁档案留在旧仓，不再随迁。

---

## 1. 目录结构

```
G:\ASTB\
├─ skill_src\            SKILL 可读源（GBK 编码，编辑在这里改）
│   ├─ main.il           加载入口（防重载守卫）
│   ├─ allegro.ilinit    Allegro 启动加载脚本
│   ├─ core\             loader/utils/config/menu/trans/utf8_loader/
│   │                    version_adapter/zz_smoke 等
│   ├─ modules\<分类>\   功能模块（pkg_/place_/route_/via_/shape_/
│   │                    text_/check_/mfg_/util_ 前缀）
│   ├─ forms\            全部 .form（与模块同名配套）
│   ├─ config\astb.cfg   配置
│   └─ tools\            AstbSmoke.java / smoke.bat / AstbBridgeClient.java /
│                         bridge.bat（sync 会原样拷入 payload）
│
├─ skill_payload\        SKILL 部署形态（Allegro 实际加载的目录；
│                        由 skill_src 经同步工具生成，勿直接编辑）
│
├─ java\
│   ├─ src\astb\studio\  ASTB Studio Java 源码
│   │   ├─ core\         纯逻辑层（桥接协议/解析/模型，不依赖 UI）
│   │   └─ ui\           Swing 界面层
│   ├─ build.bat         一键编译出 jar（产出 java\build\、java\dist\）
│   ├─ manifest.mf
│   └─ sources.txt       编译清单
│
├─ tools\
│   ├─ SkillSrcSync.java skill_src -> skill_payload 同步/校验工具
│   ├─ sync.bat          上者的包装（自动找 JDK 21，单文件源码直跑）
│   ├─ installer\
│   │   ├─ BuildAll.java     打包总控（jlink 最小运行时 + jpackage +
│   │   │                    Inno 编译，产出 ASTB_Setup_x.y.z.exe）
│   │   ├─ build_all.bat     上者的包装
│   │   ├─ astb_setup.iss    Inno Setup 脚本（安装路径可选、ilinit
│   │   │                    写入、卸载清理）
│   │   └─ astb.ico/.png     安装包与程序图标
│   └─ innosetup\        Inno Setup 本体（免安装，直接参与打包）
│
├─ allegro-skill-coding\ 开发手册（AXL API 对照 + 实机踩坑集
│                        practical-pitfalls.md，AI/人工共用）
├─ ASTB功能说明.md        功能清单文档
└─ README.md             本文件
```

## 2. SKILL 侧开发工作流（重要）

`skill_src` 是**唯一编辑源**；`skill_payload` 由同步生成并随仓库跟踪。

1. 改代码：`skill_src\` 下的文件。含中文的 `.il/.form/.dat` 一律
   **GBK 编码**——**禁止用 UTF-8 编辑器直接保存**；批量修改用托管脚本
   显式 GBK 往返读写（仓库工具链已全 Java 化，Java 侧必须处处显式
   `Charset.forName("GBK")`，JDK 18+ 默认编码是 UTF-8），补丁脚本留档
   `_patches/`。
2. 同步 + 校验（改完必跑三关）：
   ```
   tools\sync.bat sync     :: skill_src -> skill_payload
   tools\sync.bat check    :: 往返逐字节必须 PASS
   skill_payload\tools\smoke.bat          :: 5 项静态检查（也可传别的根）
   ```
   （等价直跑：`java tools\SkillSrcSync.java sync` 等，需 JDK 11+，
   本机 JDK 21 在 `C:\Program Files\Amazon Corretto\jdk21.0.10_7`。）
   sync 只写不删：删除模块后需手动删 payload 对应文件。
3. 16.6 兼容：SKILL reader 拒绝字符串字面量里的 GBK 高位字节，含中文
   的字符串 sync 时会自动转 `\ooo` 八进制（源码里写原始中文即可，
   不要再手写八进制）。转换状态机为**转义感知**（`\` 吞下一字符，
   同 astb_smoke 的 mask_code 约定），`\"` 不会截断字符串。
4. 文件头六字段（文件名/作者/创建日期/版本/功能描述/修改记录）齐全，
   每次实机验证通过的修改升版本号并补一行修订记录。
5. Allegro 侧加载：`%HOME%\pcbenv\allegro.ilinit` 指向 skill_payload
   （安装包会自动配置）；`ASTB_Reload` 热重载。

## 3. ASTB Studio（Java 外置软件）

- 构建：先杀掉占用进程，再执行
  ```
  java\build.bat
  ```
  产出 `java\dist\ASTBStudio.jar`。
- 自检：`java -Dfile.encoding=UTF-8 -jar java\dist\ASTBStudio.jar --selftest`
  须 `failures=0`。
- 运行依赖：打包版自带 jlink 最小运行时；源码运行需本机 JDK 17+。
- 已知机器级坑：个别机器 Java2D D3D 管线异常导致窗口全白，安装包已
  内置 `-Dsun.java2d.d3d=false` 免疫；源码直跑若遇白窗加同款参数。

## 4. 打包安装包（exe）

```
tools\installer\build_all.bat
```

流程：编译 jar -> jlink 生成最小运行时（java.base/java.desktop/
jdk.charsets/jdk.localedata，**不开 --compress**）-> jpackage 应用镜像
-> Inno Setup 编译 `astb_setup.iss` -> `tools\installer\Output\
ASTB_Setup_x.y.z.exe`（约 37MB）。全程无需 Python 环境。

安装包行为：可选安装目录；写入 `%HOME%\pcbenv\allegro.ilinit` 指向
安装版 skill；放置 Studio 快捷方式；卸载时清理上述改动。

## 5. 桥接（Studio <-> Allegro）

Studio 与 Allegro 通过文件桥 `D:\Temp\astb_bridge\` 通信：SKILL 侧
`astbbridge` 命令启停；会话注册在 `sessions\`，任务在 `jobs\`。
skill_payload\tools\AstbBridgeClient.java 是调试客户端（`sessions` /
`run --target <pid> --wait 60 "<expr>"`；`bridge.bat` 已包好）。

## 6. 开发注意事项（血泪摘要，详见手册 practical-pitfalls.md）

- 改 GBK 文件只用托管脚本显式 GBK 往返（Java 侧处处 `Charset.forName("GBK")`）；
  写 SKILL 字符串的 `\n` 在补丁里要写成 `\\n`（否则落成 0x0A 原始字节，
  reader 当空格）。
- `axlFilmCreate` 等 AXL 关键字参数值必须传原子（变量/字面量），
  不能是嵌套列表表达式。
- `axlGetParam("artwork:不存在的名")` 返回组记录而非 nil，删除底片
  前必须校验 `rec->name`。
- 静默 nil 型 API（删除/写参）先补试事务包裹再下"不支持"结论。
- 菜单标签内嵌双语（menu.il v4.3 起）：结构行（英文 中文 命令）单一
  数据源；menubar 中文标签由 sync 八进制转义兜底 16.6 reader，
  `axlUIPopupDefine` 右键 popup 标签仍禁 GBK 中文。

## 7. 版本管理约定

- 本仓 git 独立初始化（2026-10-03），提交粒度=一次整改一笔；
- 跟踪 `skill_payload` 与源码同提交（保证部署态与源一致）；
- 构建产物（`java\build`、`java\dist`、`tools\runtime-min`、
  `tools\dist`、`installer\Output`）一律不入库（见 .gitignore）。
