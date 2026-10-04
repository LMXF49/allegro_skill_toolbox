# -*- coding: utf-8 -*-
"""
patch_20261004_remove_downrev.py — 降版本功能整体下线
背景: 用户决策删除"降版本"功能。参照 menu.il v3.9 删 &Film Reorder 的
先例: 菜单项/模块/标签/帮助同步删除, 另清运行时目录与安装包/文档引用。
改动(本脚本只管 GBK 文本三件套, 其余文件外部处理):
  1. core/menu.il:    版本 3.9 -> 4.0, 修改记录加 v4.0, 删 Downrev 菜单行
  2. core/labels_map.dat: 删 "Downrev to 1&6.6=..." 行 (161 -> 160)
  3. core/help_map.dat:   删 ASTB_Util_Downrev166 帮助行
GBK 显式往返写盘(AGENTS.md §2.1), 留档 _patches/。
用法: python _patches/patch_20261004_remove_downrev.py
"""
import codecs
import sys

MENU = "G:/ASTB/skill_src/core/menu.il"
LABELS = "G:/ASTB/skill_src/core/labels_map.dat"
HELP = "G:/ASTB/skill_src/core/help_map.dat"


def read_gbk(path):
    return codecs.open(path, "r", "gbk").read()


def write_gbk(path, text):
    codecs.open(path, "w", "gbk").write(text)
    assert codecs.open(path, "r", "gbk").read() == text


def check_paren(src):
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
                return False
    return depth == 0 and not in_str


# ---- 1. menu.il ----
src = read_gbk(MENU)
crlf = "\r\n" in src


def E(text):
    t = text.replace("\r\n", "\n")
    if crlf:
        t = t.replace("\n", "\r\n")
    return t


edits = []

edits.append((
    E("; 版本      : 3.9\n"),
    E("; 版本      : 4.0\n"),
))

edits.append((
    E("; 编码      : GBK（含中文注释）\n; 修改记录  :\n"),
    E("; 编码      : GBK（含中文注释）\n; 修改记录  :\n"
      ";   2026-10-04 v4.0 ASTB Team 删除 Downrev to 16.6 菜单项\n"
      ";                     （PCB 降版本功能整体下线，模块/运行时/标签/\n"
      ";                     帮助/安装包/文档同步删除）\n"),
))

for i, (old, new) in enumerate(edits, 1):
    n = src.count(old)
    if n != 1:
        print("MENU EDIT %d: anchor found %d times, ABORT" % (i, n))
        sys.exit(1)
    src = src.replace(old, new, 1)

lines = src.split("\n")
hit = [l for l in lines if "ASTB_Util_Downrev166" in l]
if len(hit) != 1 or not hit[0].lstrip().startswith('list("Downrev to 1&6.6"'):
    print("MENU EDIT 3: Downrev menu line not found exactly once, ABORT: %r" % hit)
    sys.exit(1)
lines = [l for l in lines if "ASTB_Util_Downrev166" not in l]
src = "\n".join(lines)

if not check_paren(src):
    print("MENU paren UNBALANCED, ABORT")
    sys.exit(1)
write_gbk(MENU, src)
print("OK: menu.il 4.0, menu line removed, paren OK, GBK roundtrip OK")

# ---- 2. labels_map.dat ----
src = read_gbk(LABELS)
lines = src.split("\n")
hit = [l for l in lines if l.startswith("Downrev to 1&6.6=")]
if len(hit) != 1:
    print("LABELS: Downrev entry found %d times, ABORT" % len(hit))
    sys.exit(1)
lines = [l for l in lines if not l.startswith("Downrev to 1&6.6=")]
src = "\n".join(lines)
n_entries = len([l for l in lines if "=" in l and l.strip()])
write_gbk(LABELS, src)
print("OK: labels_map.dat entry removed, remaining entries = %d" % n_entries)

# ---- 3. help_map.dat ----
src = read_gbk(HELP)
lines = src.split("\n")
hit = [l for l in lines if "ASTB_Util_Downrev166" in l]
if len(hit) != 1:
    print("HELP: Downrev help line found %d times, ABORT" % len(hit))
    sys.exit(1)
lines = [l for l in lines if "ASTB_Util_Downrev166" not in l]
src = "\n".join(lines)
write_gbk(HELP, src)
print("OK: help_map.dat Downrev line removed")

print("ALL OK")
