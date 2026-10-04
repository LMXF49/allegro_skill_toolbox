# -*- coding: utf-8 -*-
"""
patch_20261004_downrev_v34_nomirror.py — util_downrev17.il v3.3 -> v3.4
背景: v3.3 在失败提示里补了"mirrored_layers/32000016 = 含底面镜像器件,
免补丁转换器不支持"的说明。用户实测更正: 含镜像器件的板可以直接降,
该限制不成立。
改动:
  1. 文件头: 版本 3.4, 功能描述"已知限制"段改写为更正说明, 修改记录加 v3.4
  2. 失败提示: 删除 mirrored_layers/32000016 补充句, 恢复 v3.1 措辞
GBK 显式往返写盘(AGENTS.md §2.1), 留档 _patches/。
用法: python _patches/patch_20261004_downrev_v34_nomirror.py
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
    E("; 版本      : 3.3\n"),
    E("; 版本      : 3.4\n"),
))

# ---- 2. 功能描述: 已知限制 -> 更正说明 ----
edits.append((
    E(";             已知限制(2026-10-04 实测)：含底面镜像器件\n"
      ";             (mirrored_layers)的板，24.x 对话框产物 exe 直读报\n"
      ";             32000016；干净板(无底面镜像器件)可直通。S019 中间跳\n"
      ";             方案(v3.2)对话框同样拒 mirrored_layers，已回退。\n"),
    E(";             更正(2026-10-04 用户实测)：早期以为含底面镜像器件\n"
      ";             (mirrored_layers)会阻断转换(32000016)，实测镜像板\n"
      ";             可直接降，该限制不成立；失败提示已同步移除(v3.4)。\n"),
))

# ---- 3. 修改记录加 v3.4 ----
edits.append((
    E(";   2026-10-04 v3.3 ASTB Team 按用户决策回退 v3.2 中间跳，恢复两跳\n"
      ";                     (24.x 对话框存 17.4 -> 免补丁 exe 直转)；删\n"
      ";                     中间跳两函数；失败提示补 mirrored_layers/\n"
      ";                     32000016 场景说明\n"),
    E(";   2026-10-04 v3.3 ASTB Team 按用户决策回退 v3.2 中间跳，恢复两跳\n"
      ";                     (24.x 对话框存 17.4 -> 免补丁 exe 直转)；删\n"
      ";                     中间跳两函数；失败提示补 mirrored_layers/\n"
      ";                     32000016 场景说明\n"
      ";   2026-10-04 v3.4 ASTB Team 用户实测更正：镜像板可直接降，撤失败\n"
      ";                     提示中的 mirrored_layers/32000016 限制说明，\n"
      ";                     提示恢复 v3.1 措辞；文件头已知限制同步改写\n"),
))

# ---- 4. 失败提示恢复 v3.1 措辞 ----
edits.append((
    E("            axlUIConfirm(\"降版本失败: 设计含 16.6 不支持的特性(详见弹出日志)。\\n多叠层/多 Zone/新焊盘形状/POLY_VIA/BACKDRILL 等\\n需先在 17.4 中移除后再试。\\n\\n若日志报 mirrored_layers/32000016: 该板含底面镜像\\n器件, 免补丁转换器暂不支持自动转换(中间跳方案已回退)。\")\n"),
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
