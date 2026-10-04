# -*- coding: utf-8 -*-
"""
patch_20261004_downrev_v38_nologviewer.py — util_downrev17.il v3.7 -> v3.8
背景: 用户决策: 删掉失败时弹原因日志窗口的功能, 失败彻底静默(仅命令行)。
改动:
  1. 文件头: 版本 3.8, 功能描述 v3.7 两行改写为 v3.8 现状, 修改记录加 v3.8
  2. _DR17_RunExe: prog 局部变量去 sideLog/viewed; 失败分支删
     axlUIViewFileCreate 两段(含 viewed 兜底), axlMsgPut 措辞改为指向
     输出目录同名 .log
GBK 显式往返写盘(AGENTS.md §2.1), 留档 _patches/。
用法: python _patches/patch_20261004_downrev_v38_nologviewer.py
"""
import codecs
import sys

PATH = "G:/ASTB/skill_src/modules/utilities/util_downrev17.il"

src = codecs.open(PATH, "r", "gbk").read()
crlf = "\r\n" in src


def E(text):
    t = text.replace("\r\n", "\n")
    if crlf:
        t = t.replace("\n", "\r\n")
    return t


edits = []

# ---- 1. 版本号 ----
edits.append((
    E("; 版本      : 3.7\n"),
    E("; 版本      : 3.8\n"),
))

# ---- 2. 功能描述: v3.7 两行 -> v3.8 现状 ----
edits.append((
    E(";             v3.7 失败不再弹笼统确认框：仅命令行留痕，原因日志\n"
      ";             窗口照弹。\n"),
    E(";             v3.8 失败不再弹任何窗口：仅命令行留痕，原因留在输\n"
      ";             出目录同名 .log 自行查看。\n"),
))

# ---- 3. 修改记录加 v3.8 ----
edits.append((
    E(";                     axlUIConfirm, 改 axlMsgPut 命令行留痕；原因日\n"
      ";                     志窗口照弹\n"),
    E(";                     axlUIConfirm, 改 axlMsgPut 命令行留痕；原因日\n"
      ";                     志窗口照弹\n"
      ";   2026-10-04 v3.8 ASTB Team 按用户决策删失败日志查看器：撤\n"
      ";                     axlUIViewFileCreate 两段与 viewed/sideLog, 失\n"
      ";                     败仅命令行一句, 原因看输出目录同名 .log\n"),
))

# ---- 4. _DR17_RunExe prog 局部变量去 sideLog/viewed ----
edits.append((
    E("    prog((outPath batPath logPath port ok sideLog viewed)\n"),
    E("    prog((outPath batPath logPath port ok)\n"),
))

# ---- 5. 失败分支删日志查看器, 改命令行措辞 ----
edits.append((
    E("            ;; exe 的具体原因写在输出同名 .log（stdout 只有结论），优先展示\n"
      "            viewed = nil\n"
      "            sideLog = strcat(substring(outPath 1 strlen(outPath)-4) \".log\")\n"
      "            when( isFile(sideLog)\n"
      "                axlUIViewFileCreate(sideLog \"Downrev 16.6 Log\" t)\n"
      "                viewed = t\n"
      "            )\n"
      "            unless( viewed\n"
      "                when( isFile(logPath)\n"
      "                    axlUIViewFileCreate(logPath \"Downrev 16.6 Log\" t)\n"
      "                )\n"
      "            )\n"),
    E(""),
))
edits.append((
    E("            axlMsgPut(\"降版本失败: 设计含 16.6 不支持的特性, 原因见弹出的日志窗口。\")\n"),
    E("            axlMsgPut(\"降版本失败: 设计含 16.6 不支持的特性, 详见输出目录同名 .log。\")\n"),
))

for i, (old, new) in enumerate(edits, 1):
    n = src.count(old)
    if n != 1:
        print("EDIT %d: anchor found %d times, ABORT" % (i, n))
        sys.exit(1)
    src = src.replace(old, new, 1)

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
back = codecs.open(PATH, "r", "gbk").read()
assert back == src
print("OK: %d edits applied, paren OK, GBK roundtrip OK" % len(edits))
