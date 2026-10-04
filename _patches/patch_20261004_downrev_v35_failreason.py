# -*- coding: utf-8 -*-
"""
patch_20261004_downrev_v35_failreason.py — util_downrev17.il v3.4 -> v3.5
背景: 降版本失败时确认框只给笼统话术("含 16.6 不支持的特性..."),
具体原因要用户自己去弹出的日志窗口里找。用户要求: 失败应直给具体原因。
改动:
  1. 文件头: 版本 3.5, 功能描述/修改记录各加一行
  2. 新增 _DR17_LogReason(sideLog logPath): 从输出同名 .log(优先)或
     临时 stdout 日志摘录错误/不支持/无效类行(去重, 每行截 160 字符,
     最多 10 行, 扫描上限 5000 行), 无匹配给兜底说明
  3. _DR17_RunExe: prog 局部变量加 reason; 失败分支先摘原因,
     确认框直给"降版本失败, 具体原因(摘自转换日志): <摘录>"
GBK 显式往返写盘(AGENTS.md §2.1), 留档 _patches/。
用法: python _patches/patch_20261004_downrev_v35_failreason.py
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
    E("; 版本      : 3.4\n"),
    E("; 版本      : 3.5\n"),
))

# ---- 2. 功能描述加 v3.5 一行 ----
edits.append((
    E(";             可直接降，该限制不成立；失败提示已同步移除(v3.4)。\n"),
    E(";             可直接降，该限制不成立；失败提示已同步移除(v3.4)。\n"
      ";             v3.5 失败弹窗直给原因：自动摘录转换日志中的错误行。\n"),
))

# ---- 3. 修改记录加 v3.5 ----
edits.append((
    E(";                     提示恢复 v3.1 措辞；文件头已知限制同步改写\n"),
    E(";                     提示恢复 v3.1 措辞；文件头已知限制同步改写\n"
      ";   2026-10-04 v3.5 ASTB Team 失败弹窗直给具体原因：新增\n"
      ";                     _DR17_LogReason 从转换日志摘录错误/不支持类行\n"
      ";                     (去重截断, 最多 10 行)嵌入失败提示，不再只给\n"
      ";                     笼统话术\n"),
))

# ---- 4. 新增 _DR17_LogReason(插在 _DR17_RunExe 定义前) ----
NEWFUNC = E(
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

edits.append((
    E(";------------------------------------------------------------------------\n"
      "; 函数名  : _DR17_RunExe\n"
      "; 功能    : 主路：复制副本 -> bat 调 exe（DOWNREV_17_TO_16=1）-> 校验\n"),
    E(";------------------------------------------------------------------------\n") + NEWFUNC +
    E("; 函数名  : _DR17_RunExe\n"
      "; 功能    : 主路：复制副本 -> bat 调 exe（DOWNREV_17_TO_16=1）-> 校验\n"),
))

# ---- 5. _DR17_RunExe prog 局部变量加 reason ----
edits.append((
    E("    prog((outPath batPath logPath port ok sideLog viewed)\n"),
    E("    prog((outPath batPath logPath port ok sideLog viewed reason)\n"),
))

# ---- 6. 失败确认框直给具体原因 ----
edits.append((
    E("            axlUIConfirm(\"降版本失败: 设计含 16.6 不支持的特性(详见弹出日志)。\\n多叠层/多 Zone/新焊盘形状/POLY_VIA/BACKDRILL 等\\n需先在 17.4 中移除后再试。\")\n"),
    E("            reason = _DR17_LogReason(sideLog logPath)\n"
      "            axlUIConfirm(strcat(\"降版本失败，具体原因(摘自转换日志):\\n\" reason \"\\n\\n多叠层/多 Zone/新焊盘形状/POLY_VIA/BACKDRILL 等\\n需先在 17.4 中移除后再试。完整日志已弹出。\"))\n"),
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
