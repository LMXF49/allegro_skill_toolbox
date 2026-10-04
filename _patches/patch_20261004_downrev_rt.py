# -*- coding: utf-8 -*-
"""
patch_20261004_downrev_rt.py — util_downrev17.il v3.0 -> v3.1
背景: 官方 17.4 adl 打补丁版(adl_patched.exe)转换 17.4->16.6 时会把
底面贴片引脚的 PIN/阻焊/钢网/ETCH 数据整体翻到顶层(RK3588 实桥接实测:
BOTTOM~BOTTOM span 370->0, ETCH/BOTTOM 图形 1507->585, 阻焊/钢网 -364)。
阿狸狗降版本 v0.0.5 / 电路精灵分发的免补丁 allegro_downrev_library.exe
无此 bug(同 md5 8876705d), 且必须配自有 DLL 目录置顶 PATH(混用 17.4
会话 DLL 时静默退出零日志, 实测)。
改动:
  1. 文件头: 版本 3.1, 功能描述/依赖改写, 修改记录加 v3.1
  2. _DR17_FindExe: 优先级改为 ASTB_DOWNREV_EXE > 工具箱
     tools/downrev166_rt > 大声失败(nil); 删除自动部署/旧补丁 exe 兜底
  3. _DR17_RunExe: bat 内 downrev166_rt 运行时置顶 PATH
  4. _DR17_Main: exe 缺失指引改为重装备份/复制 downrev166_rt
GBK 显式往返写盘(AGENTS.md §2.1), 留档 _patches/。
用法: python _patches/patch_20261004_downrev_rt.py
"""
import codecs
import sys

PATH = "G:/ASTB/skill_src/modules/utilities/util_downrev17.il"

src = codecs.open(PATH, "r", "gbk").read()
orig = src
crlf = "\r\n" in src


def E(text):
    """normalize line endings of an edit snippet to the file's own style"""
    t = text.replace("\r\n", "\n")
    if crlf:
        t = t.replace("\n", "\r\n")
    return t


edits = []

# ---- 1. 版本号 ----
edits.append((
    E("; 版本      : 3.0\n"),
    E("; 版本      : 3.1\n"),
))

# ---- 2. 功能描述主路段 ----
edits.append((
    E("; 功能描述  : PCB 降版本到 16.6。\n"
      ";             主路（17.x 会话）：调用官方补丁版批处理 adl_patched.exe\n"
      ";             （本机 17.4 CDSROOT/tools/bin 下；解除 Cadence SYExit\n"
      ";             闸门 + DOWNREV_17_TO_16=1 放开 brd/dra），复制\n"
      ";             <板名>_166.brd 副本后原地转 16.6，原文件不动。\n"),
    E("; 功能描述  : PCB 降版本到 16.6。\n"
      ";             主路（17.x 会话）：调用工具箱自带免补丁运行时\n"
      ";             tools/downrev166_rt（allegro_downrev_library.exe +\n"
      ";             自有 DLL，转换时该目录置顶 PATH；DOWNREV_17_TO_16=1\n"
      ";             放开 brd/dra），复制 <板名>_166.brd 副本后原地转\n"
      ";             16.6，原文件不动。v3.1 换运行时原因：官方 17.4 adl\n"
      ";             补丁版会把底面贴片引脚层数据翻到顶层（RK3588 实测\n"
      ";             BOTTOM~BOTTOM 370->0），阿狸狗/电路精灵分发的免补丁\n"
      ";             构建无此 bug（同 md5 8876705d）。\n"),
))

# ---- 3. 依赖模块 ----
edits.append((
    E(";             tools/downrev17/x_downrev17.il（deargds 加密脚本，备援）\n"),
    E(";             tools/downrev166_rt/（免补丁转换运行时 exe+DLL）\n"),
))

# ---- 4. 修改记录加 v3.1（锚: v3.0 记录末行）----
edits.append((
    E(";                     时回退 v2.9 会话内回放\n"),
    E(";                     时回退 v2.9 会话内回放\n"
      ";   2026-10-04 v3.1 ASTB Team 修复底面贴片引脚翻转：弃用 adl_patched\n"
      ";                     .exe（官方 17.4 adl 补丁版转换后底面引脚层数据\n"
      ";                     整体搬家顶层，桥接实测），自带 downrev166_rt 免\n"
      ";                     补丁运行时（与阿狸狗/电路精灵同构建 md5\n"
      ";                     8876705d）；bat 内 rt/bin 置顶 PATH（混用 17.4\n"
      ";                     DLL 静默退出，实测）；exe 缺失指引同步更新\n"),
))

# ---- 5. FindExe 注释块 ----
edits.append((
    E("; 函数名  : _DR17_FindExe\n"
      "; 功能    : 定位官方降级工具 exe(v2.8 三级定位)\n"
      "; 返回值  : exe 路径 / nil\n"
      "; 优先级  : ASTB_DOWNREV_EXE > 已装 exe(CDSROOT/兄弟目录/常见安装位)\n"
      ";           > 工具箱自带 tools/adl_patched.exe 自动部署到 <root>/tools/bin\n"
      ";           > 工具箱原位兜底\n"),
    E("; 函数名  : _DR17_FindExe\n"
      "; 功能    : 定位降版本转换 exe(v3.1 起为自带免补丁运行时)\n"
      "; 返回值  : exe 路径 / nil\n"
      "; 优先级  : ASTB_DOWNREV_EXE > 工具箱 tools/downrev166_rt >\n"
      ";           无(大声失败，绝不回退会翻转数据的旧补丁 exe)\n"),
))

# ---- 6. FindExe 过程体整体替换 ----
old_start = src.index("procedure( _DR17_FindExe()")
old_end = src.index(";------------------------------------------------------------------------\nprocedure( _DR17_OutputPath")
if crlf:
    marker = ";------------------------------------------------------------------------\r\nprocedure( _DR17_OutputPath"
    old_end = src.index(marker)
old_block = src[old_start:old_end]
edits.append((
    old_block,
    E("procedure( _DR17_FindExe()\n"
      "  prog((cand rt)\n"
      "    ;; 1) 环境变量显式指定优先(用户自备转换器时使用)\n"
      "    cand = getShellEnvVar(\"ASTB_DOWNREV_EXE\")\n"
      "    when( and(cand isFile(cand))\n"
      "      ASTB_DebugLog(strcat(\"Downrev166: exe from env \" cand))\n"
      "      return(cand)\n"
      "    )\n"
      "    ;; 2) 工具箱自带免补丁运行时(v3.1 起唯一默认路径; 旧 adl_patched\n"
      "    ;;    已弃用——官方17.4 adl 补丁版会把底面贴片引脚翻到顶层)\n"
      "    rt = strcat(ASTB_GLOBAL->ToolboxPath\n"
      "                \"/tools/downrev166_rt/tools/bin/allegro_downrev_library.exe\")\n"
      "    when( isFile(rt)\n"
      "      ASTB_DebugLog(strcat(\"Downrev166: exe from toolbox rt \" rt))\n"
      "      return(rt)\n"
      "    )\n"
      "    ;; 3) 无运行时: 大声失败, 绝不回退到已知会翻转数据的旧补丁 exe\n"
      "    ASTB_DebugLog(\"Downrev166: downrev166_rt runtime NOT found\")\n"
      "    return(nil)\n"
      "  )\n"
      ")\n"
      "\n"),
))

# ---- 7. RunExe bat 置顶 PATH ----
edits.append((
    E("        fprintf(port \"set \\\"DOWNREV_17_TO_16=1\\\"\\r\\n\")\n"),
    E("        fprintf(port \"set \\\"DOWNREV_17_TO_16=1\\\"\\r\\n\")\n"
      "        ;; v3.1: 自带运行时必须配自有 DLL 目录置顶 PATH(实测混用\n"
      "        ;; 17.4 会话 DLL 时 exe 静默退出, 零日志); 外部 exe 环境自管\n"
      "        when( rexMatchp(\"downrev166_rt\" exe)\n"
      "          fprintf(port \"set \\\"PATH=%s;%%PATH%%\\\"\\r\\n\"\n"
      "                   strcat(ASTB_GLOBAL->ToolboxPath\n"
      "                           \"/tools/downrev166_rt/tools/bin\"))\n"
      "        )\n"),
))

# ---- 8. exe 缺失指引 ----
edits.append((
    E("            axlUIConfirm(\"未找到降级工具 adl_patched.exe, 自动部署也失败。\\n请手工把 <工具箱>/tools/adl_patched.exe 复制到\\n17.4 安装目录 tools/bin 下再试(需已装 17.4);\\n或用 tools/downrev17/patch_downrev_exe.py 对\\nallegro_downrev_library.exe 重新打补丁。\")\n"),
    E("            axlUIConfirm(\"未找到降版本运行时 tools/downrev166_rt。\\n请重新安装工具箱, 或把安装目录 skill/tools/downrev166_rt\\n整个复制到本工具箱 tools/ 下再试。\")\n"),
))

# 应用
for i, (old, new) in enumerate(edits, 1):
    n = src.count(old)
    if n != 1:
        print("EDIT %d: anchor found %d times, ABORT" % (i, n))
        sys.exit(1)
    src = src.replace(old, new, 1)

# 括号平衡(字符串/注释状态机, 粗校验)
depth = 0
in_str = False
in_comment = False
esc = False
for ch in src:
    if in_comment:
        if ch == "\n":
            in_comment = False
        continue
    if in_str:
        if esc:
            esc = False
        elif ch == "\\":
            esc = True
        elif ch == '"':
            in_str = False
        continue
    if ch == '"':
        in_str = True
    elif ch == ";":
        in_comment = True
    elif ch == "(":
        depth += 1
    elif ch == ")":
        depth -= 1
        if depth < 0:
            print("PAREN NEGATIVE, ABORT")
            sys.exit(1)
if depth != 0 or in_str:
    print("UNBALANCED (depth=%d in_str=%s), ABORT" % (depth, in_str))
    sys.exit(1)

codecs.open(PATH, "w", "gbk").write(src)
# 可逆抽查
back = codecs.open(PATH, "r", "gbk").read()
assert back == src, "GBK roundtrip mismatch"
print("OK: %d edits applied, paren balance OK, GBK roundtrip OK" % len(edits))
