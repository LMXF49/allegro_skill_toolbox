# -*- coding: utf-8 -*-
"""
patch_20261004_downrev_v36_nofailreason.py — util_downrev17.il v3.5 -> v3.6
背景: v3.5 新增 _DR17_LogReason 把转换日志错误行摘进失败弹窗。
用户决策: 文字描述原因不要了, 回退该功能, 失败提示恢复 v3.4 措辞。
改动:
  1. 文件头: 版本 3.6, 功能描述删 v3.5 一行, 修改记录加 v3.6
  2. 删 _DR17_LogReason(整段, 与 v3.5 插入文本逐字对应)
  3. _DR17_RunExe: prog 局部变量去 reason; 失败分支恢复 v3.4 确认框
GBK 显式往返写盘(AGENTS.md §2.1), 留档 _patches/。
用法: python _patches/patch_20261004_downrev_v36_nofailreason.py
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
    E("; 版本      : 3.5\n"),
    E("; 版本      : 3.6\n"),
))

# ---- 2. 功能描述删 v3.5 一行 ----
edits.append((
    E(";             v3.5 失败弹窗直给原因：自动摘录转换日志中的错误行。\n"),
    E(""),
))

# ---- 3. 修改记录加 v3.6 ----
edits.append((
    E(";   2026-10-04 v3.5 ASTB Team 失败弹窗直给具体原因：新增\n"
      ";                     _DR17_LogReason 从转换日志摘录错误/不支持类行\n"
      ";                     (去重截断, 最多 10 行)嵌入失败提示，不再只给\n"
      ";                     笼统话术\n"),
    E(";   2026-10-04 v3.5 ASTB Team 失败弹窗直给具体原因：新增\n"
      ";                     _DR17_LogReason 从转换日志摘录错误/不支持类行\n"
      ";                     (去重截断, 最多 10 行)嵌入失败提示，不再只给\n"
      ";                     笼统话术\n"
      ";   2026-10-04 v3.6 ASTB Team 按用户决策回退 v3.5：撤日志摘录原因，\n"
      ";                     失败提示恢复 v3.4 措辞；删 _DR17_LogReason\n"),
))

# ---- 4. 删 _DR17_LogReason(整段, 与 v3.5 插入文本逐字对应) ----
FUNC_BLOCK = E(
    ";------------------------------------------------------------------------\n"
    "; 函数名  : _DR17_LogReason\n"
    "; 功能    : 从转换日志摘录具体失败原因（错误/不支持/无效类行）\n"
    "; 参数    : sideLog - 输出同名 .log（优先，exe 的具体原因写这里）；\n"
    ";           logPath - 临时 stdout/stderr 日志（兜底）\n"
    "; 返回值  : 摘要字符串（去重、每行截 160 字符、最多 10 行；无匹配给\n"
    ";           兜底说明）\n"
    ";------------------------------------------------------------------------\n"
    "procedure( _DR17_LogReason(sideLog logPath)\n"
    "  prog((port line lines path n l s)\n"
    "    lines = nil\n"
    "    path = nil\n"
    "    when( and(sideLog isFile(sideLog)) path = sideLog )\n"
    "    unless( path\n"
    "      when( and(logPath isFile(logPath)) path = logPath )\n"
    "    )\n"
    "    when( path\n"
    "      port = infile(path)\n"
    "      when( port\n"
    "        n = 0\n"
    "        while( and(gets(line port) n < 5000)\n"
    "          n = n+1\n"
    "          line = ASTB_StringTrim(line)\n"
    "          when( and(strlen(line) > 3\n"
    "                  length(lines) < 10\n"
    "                  not(member(line lines))\n"
    "                  || rexMatchp(\"[Ee][Rr][Rr][Oo][Rr]\" line)\n"
    "                  || rexMatchp(\"[Ff][Aa][Tt][Aa][Ll]\" line)\n"
    "                  || rexMatchp(\"[Uu][Nn][Ss][Uu][Pp]\" line)\n"
    "                  || rexMatchp(\"[Ff][Aa][Ii][Ll][Ee][Dd]\" line)\n"
    "                  || rexMatchp(\"[Ii][Nn][Vv][Aa][Ll][Ii][Dd]\" line) )\n"
    "            when( strlen(line) > 160 line = substring(line 1 160) )\n"
    "            lines = append1(lines line)\n"
    "          )\n"
    "        )\n"
    "        close(port)\n"
    "      )\n"
    "    )\n"
    "    unless( lines return(\"(日志中未找到明确错误行, 请查看弹出的完整日志)\") )\n"
    "    s = car(lines)\n"
    "    foreach( l cdr(lines) s = strcat(s \"\\n\" l) )\n"
    "    ASTB_DebugLog(strcat(\"Downrev166: fail reason=\" s))\n"
    "    return(s)\n"
    "  )\n"
    ")\n"
    "\n"
)
edits.append((FUNC_BLOCK, E("")))

# ---- 5. _DR17_RunExe prog 局部变量去 reason ----
edits.append((
    E("    prog((outPath batPath logPath port ok sideLog viewed reason)\n"),
    E("    prog((outPath batPath logPath port ok sideLog viewed)\n"),
))

# ---- 6. 失败确认框恢复 v3.4 措辞 ----
edits.append((
    E("            reason = _DR17_LogReason(sideLog logPath)\n"
      "            axlUIConfirm(strcat(\"降版本失败，具体原因(摘自转换日志):\\n\" reason \"\\n\\n多叠层/多 Zone/新焊盘形状/POLY_VIA/BACKDRILL 等\\n需先在 17.4 中移除后再试。完整日志已弹出。\"))\n"),
    E("            axlUIConfirm(\"降版本失败: 设计含 16.6 不支持的特性(详见弹出日志)。\\n多叠层/多 Zone/新焊盘形状/POLY_VIA/BACKDRILL 等\\n需先在 17.4 中移除后再试。\")\n"),
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
