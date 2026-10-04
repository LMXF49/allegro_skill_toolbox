# -*- coding: utf-8 -*-
"""
patch_20261004_downrev_v37_nofailprompt.py — util_downrev17.il v3.6 -> v3.7
背景: 用户决策: 降版本失败不弹确认框提示。
改动:
  1. 文件头: 版本 3.7, 功能描述/修改记录各加一行
  2. _DR17_RunExe 失败分支: 删 axlUIConfirm 笼统确认框, 改 axlMsgPut
     命令行留痕; 原因日志查看器(axlUIViewFileCreate)照弹
GBK 显式往返写盘(AGENTS.md §2.1), 留档 _patches/。
用法: python _patches/patch_20261004_downrev_v37_nofailprompt.py
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
    E("; 版本      : 3.6\n"),
    E("; 版本      : 3.7\n"),
))

# ---- 2. 功能描述加 v3.7 两行 ----
edits.append((
    E(";             可直接降，该限制不成立；失败提示已同步移除(v3.4)。\n"),
    E(";             可直接降，该限制不成立；失败提示已同步移除(v3.4)。\n"
      ";             v3.7 失败不再弹笼统确认框：仅命令行留痕，原因日志\n"
      ";             窗口照弹。\n"),
))

# ---- 3. 修改记录加 v3.7 ----
edits.append((
    E(";                     失败提示恢复 v3.4 措辞；删 _DR17_LogReason\n"),
    E(";                     失败提示恢复 v3.4 措辞；删 _DR17_LogReason\n"
      ";   2026-10-04 v3.7 ASTB Team 按用户决策失败不弹确认框：删失败\n"
      ";                     axlUIConfirm, 改 axlMsgPut 命令行留痕；原因日\n"
      ";                     志窗口照弹\n"),
))

# ---- 4. 失败确认框 -> 命令行留痕 ----
edits.append((
    E("            axlUIConfirm(\"降版本失败: 设计含 16.6 不支持的特性(详见弹出日志)。\\n多叠层/多 Zone/新焊盘形状/POLY_VIA/BACKDRILL 等\\n需先在 17.4 中移除后再试。\")\n"),
    E("            axlMsgPut(\"降版本失败: 设计含 16.6 不支持的特性, 原因见弹出的日志窗口。\")\n"),
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
